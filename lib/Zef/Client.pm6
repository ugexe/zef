use Zef::Config;
use Zef::Distribution;
use Zef::Distribution::Local;
use Zef::Fetch;
use Zef::ContentStorage;
use Zef::Extract;
use Zef::Test;

our %CONFIG;

class Zef::Client {
    has $.cache;
    has $.indexer;
    has $.fetcher;
    has $.storage;
    has $.extractor;
    has $.tester;

    has @.exclude;
    has @!ignore = <Test NativeCall lib MONKEY-TYPING nqp>;

    has Bool $.verbose       = False;
    has Bool $.force         = False;
    has Bool $.depends       = True;
    has Bool $.build-depends = True;
    has Bool $.test-depends  = True;

    proto method new(|) {*}

    # This bit will probably change, but it provides access to a optional config hash
    # but it can't be used as an attribute (in this current form) because it needs to
    # be used to set some default values (so need to ditch the multi dispatch and handle
    # more cases with a conditional)
    multi method new(:$config where !*.defined, |c) {
        samewith( :config(ZEF-CONFIG()), |c );
    }
    multi method new(:$config where {$_.defined && %CONFIG.keys.elems == 0}, |c) {
        %CONFIG = |$config;
        callsame;
    }

    multi method new(:$extractor where !*.defined, :@extractors = |%CONFIG<Extract>, |c) {
        samewith( :extractor(Zef::Extract.new( :backends(|@extractors) )), |c );
    }

    multi method new(:$tester where !*.defined, :@testers = |%CONFIG<Test>, |c) {
        samewith( :tester(Zef::Test.new( :backends(|@testers) )), |c );
    }

    multi method new(:$cache where !*.defined, |c) {
        samewith( :cache(%CONFIG<StoreDir>), |c);
    }

    multi method new(:$fetcher where !*.defined, :@fetchers = |%CONFIG<Fetch>, |c) {
        samewith( :fetcher(Zef::Fetch.new( :backends(|@fetchers) )), |c );
    }

    multi method new(:$storage where !*.defined, :@storages = |%CONFIG<ContentStorage>, |c) {
        samewith( :storage(Zef::ContentStorage.new( :backends(|@storages) )), |c );
    }

    multi method new(:$cache!, :$fetcher!, :$storage!, :$extractor!, :$tester!, *%_) {
        mkdir $cache unless $cache.IO.e;

        $storage.cache   //= $cache;
        $storage.fetcher //= $fetcher;

        self.bless(:$cache, :$fetcher, :$storage, :$extractor, :$tester, |%_);
    }

    method candidates(Bool :$upgrade, *@identities) {
        my &stdout = ?$!verbose ?? -> $o {$o.say} !! -> $ { };
        # This entire structure sucks as much as the previous recursive one. really want something like
        # a single assignment (like a gather loop) where the body of the block can access whats already been taken
        # which would make it easier to find identities that may have already been found. It also needs to not just
        # match against the name or identity, but check $dist.contains-spec so if 2 modules depend on say:
        # URI::Escape and another on URI (but both refer to URI distribution) then they get treated as a single request
        # (currently only works if they are requested on different iterations of the `while` loop, so requesting
        # `install URI::Escape URI` will still see them both)
        #
        # TODO: just redo this thing such that .candidates returns empty matches for identities it did not find
        # so we don't have to iterate @candidates>>.dist.contains-spec every iteration of while(@wants)
        my @wants = |@identities; # @wants contains the current iteration of identities
        my @needs;                # keeps trac
        my @candidates;

        # First we resolve local paths and URIs, because these refer to a specific distribution, but we won't know
        # what that distribution's identity is until we fetch it and examine the META6. By knowing the identity of
        # these distributions before the ContentStorage.candidate search loop (after this block of code) we can
        # skip fetching any dependencies by name that these paths or URIs fulfill

        # - LOCAL PATHS
        for @wants.grep({.starts-with('.' | '/')}, :p).reverse {
            @needs.push: Candidate.new(:uri(.value.IO.absolute), :as(.value));
            @wants[.key]:delete;
        }

        # - URNs
        # Note that URNs like Foo-Bar:ver('1.2.3') also matches as a URI.
        # So if something is a URN, assume its not a URI (for our purposes)
        for @wants.grep({!Zef::Identity($_)}, :p).reverse -> $kv {
            if my $uri = Zef::Utils::URI($kv.value) andthen !$uri.is-relative {
                @needs.push: Candidate.new(:uri($kv.value), :as($kv.value));
                @wants[$kv.key]:delete;
            }
        }

        # fetch dependencies for URIs and Paths (which will be identities)
        for self.fetch(|@needs) -> $candi {
            @candidates.push($candi);
            @wants.append(|unique(grep *.chars, grep *.defined,
                ($candi.dist.depends       if ?$!depends).Slip,
                ($candi.dist.test-depends  if ?$!test-depends).Slip,
                ($candi.dist.build-depends if ?$!build-depends).Slip));
        }

        # - IDENTITIES
        # ContentStorage.candidate search loop
        # The above chunk of code is for "finding" a distribution that we know the exact location of. This is for
        # finding identities (like you would type on the command line, `use` in your code, or put in your `depends`)
        my $exclude = any(|@!exclude);
        my $is-dependency = 0;
        while @wants.splice.grep(*.defined) -> @wanted {
            my @todo = @wanted.grep(* ~~ none(|@!ignore)).grep(-> $id {
                my $spec = Zef::Distribution::DependencySpecification.new($id);
                so !@candidates.first(*.dist.contains-spec($spec))
            }).unique;

            @needs = (|@needs, |@todo).grep(* !~~ $exclude).unique;

            say "Searching for {'dependencies ' if $is-dependency++}{@todo.join(', ')}";

            for $!storage.candidates(|@todo, :$upgrade) -> $candis {
                for $candis.grep({ .dist.identity ~~ none(|@candidates.map(*.dist.identity)) }) -> $candi {
                    # conditional is to handle --depsonly (installing only deps)
                    if $candi.as !~~ $exclude {
                        @candidates.push($candi);
                        say "[{$candi.from}] found {$candi.dist.name}" if ?$!verbose;
                    }

                    # todo: alternatives, i.e. not a Str but [Str, Str]
                    # todo: abstract the depends/build-depends/test-depends shit
                    @wants.append(|unique(grep *.chars, grep *.defined,
                        ($candi.dist.depends       if ?$!depends).Slip,
                        ($candi.dist.test-depends  if ?$!test-depends).Slip,
                        ($candi.dist.build-depends if ?$!build-depends).Slip));
                }
            }
        }

        # For now we use unique on the `as` field so if someone has both p6c and cpan
        # enabled that they only get 1 result for a specific requested instead of 1 from each.
        # In the future this won't be neccesary because they *should* match on identities, but
        # right now metacpan has some of the versions/auths screwy. This means a dist on both
        # may be exactly the same, but metacpan reports the auth or version slightly different
        # causing it to be treated as a unique result.
        # XXX: this check (and anything that dies really) should be moved to `.install`
        my @chosen = @candidates.unique(:as(*.as));
        if +@needs !== +@chosen {
            # if @needs has more elements than @missing its probably a bug related to:
            my @missing = @needs.grep(* !~~ any(@candidates>>.as));
            +@missing >= +@needs
                ?? say("Could not find distributions for the following requests:\n{@missing.sort.join(', ')}")
                !! say(   "Found too many results :(\n\nGot:\n{@candidates.map(*.dist.name).sort.join(', ')}\n"
                        ~ "Expected: {@needs.sort.join(', ')}");
            die "use --force to continue" unless ?$!force;
        }

        $ = @chosen;
    }


    method fetch(*@candidates) {
        my &stdout = ?$!verbose ?? -> $o {$o.say} !! -> $ { };
        my @saved = eager gather for @candidates -> $candi {
            my $from      = $candi.from;
            my $as        = $candi.as;
            my $uri       = $candi.uri;
            my $tmp      := %CONFIG<TempDir>.IO;
            my $stage-at := $tmp.child($uri.IO.basename);
            die "failed to create directory: {$tmp.absolute}"
                unless ($tmp.IO.e || mkdir($tmp));

            # $candi.uri will always point to where $candi.dist should be copied from.
            # It could be a file or url; $dist.source-url contains where the source was
            # originally located but we may want to use a local copy (while retaining
            # the original source-url for some other purpose like updating)

            say "{?$from??qq|[$from] |!!''}{$uri} staging at: $stage-at" if ?$!verbose;

            my $save-to    = $!fetcher.fetch($uri, $stage-at, :&stdout);
            my $relpath    = $stage-at.relative($tmp);
            my $extract-to = $!cache.IO.child($relpath);

            say "$uri saved to $save-to" if ?$!verbose;

            # should probably break this out into its out method
            say "[{$!extractor.^name}] Extracting: {$save-to} to {$extract-to}" if ?$!verbose;
            my $dist-dir = $!extractor.extract($save-to, $extract-to);
            say "Extracted to: {$dist-dir}" if ?$!verbose;

            # $candi.dist may already contain a distribution object, but we reassign it as a
            # Zef::Distribution::Local so that it has .path/.IO methods. These could be
            # applied via a role, but this way also allows us to use the distribution's
            # meta data instead of the (possibly out-of-date) meta data content storage found
            my $dist        = Zef::Distribution::Local.new(~$dist-dir);
            my $local-candi = $candi.clone(:$dist);
            # XXX: the above used to just be `$candi.dist = $dist` where dist is rw

            say "{$local-candi.dist.identity} fulfills the request for {$local-candi.as}";

            take $local-candi;
        }

        # Calls optional `.store` method on all ContentStorage plugins so they may
        # choose to cache the dist or simply cache the meta data of what is installed.
        # Should go in its own phase/lifecycle event
        $!storage.store(|@saved.map(*.dist));

        @saved;
    }


    # xxx: needs some love
    method test(:@includes, *@paths) {
        % = @paths.map: -> $path {
            say "Start test phase for: $path";

            my &stdout = ?$!verbose ?? -> $o {$o.say} !! -> $ { };

            my $result = try $!tester.test($path, :includes(@includes.grep(*.so)), :&stdout);

            if !$result {
                die "Aborting due to test failure at: {$path} (use :force to override)" unless ?$!force;
                say "Test failure at: {$path}. Continuing anyway with :force"
            }
            else {
                say "Testing passed for {$path}";
            }

            $path => ?$result
        }
    }


    # xxx: needs some love
    method search(*@identities, *%fields) {
        $!storage.search(|@identities, |%fields);
    }


    method install(
        CompUnit::Repository :@to!, # target CompUnit::Repository
        Bool :$fetch = True,        # try fetching whats missing
        Bool :$test  = True,        # run tests
        Bool :$dry,                 # do everything *but* actually install
        Bool :$upgrade,             # NYI
        *@wants,
        *%_
        ) {
        my &notice = ?$!force ?? &say !! &die;
        my (@curs, @cant-install);
        @to.map: { my $group := $_.?can-install ?? @curs !! @cant-install; $group.push($_) }
        say "You specified the following CompUnit::Repository install targets that don't appear writeable/installable:\n"
            ~ "\t{@cant-install.join(', ')}" if +@cant-install;
        die "Need a valid installation target to continue" unless ?$dry || (+@curs - +@cant-install);

        # XXX: Each loop block below essentially represents a phase, so they will probably
        # be moved into their own method/module related directly to their phase. For now
        # lumping them here allows us to easily move functionality between phases until we
        # find the perfect balance/structure.

        die "Must specify something to install" unless +@wants;

        # Search Phase:
        # Search ContentStorages to locate each Candidate needed to fulfill the requested identities
        my @found-candidates = |self.candidates(|@wants, :$upgrade, |%_).unique;
        die "Failed to resolve any candidates. No reason to proceed" unless +@found-candidates;

        # Fetch Stage:
        # Use the results from searching ContentStorages and download/fetch the distributions they point at
        my @fetched-candidates = eager gather for @found-candidates -> $store {
            # xxx: paths and uris we already fetched (saves us from copying 1 extra time)
            take $store and next if $store.dist.^name.contains('Zef::Distribution::Local');
            # todo: send |@candidates to fetch instead of each $store one at a time
            take $_ for |self.fetch($store, |%_);
        }
        die "Failed to fetch any candidates. No reason to proceed" unless +@fetched-candidates;


        # This could really go in the filter stage (thats where it got moved from!) but
        # this lets us give a better error message if all candidates are installed. We can
        # also put logic related to checking if its installed in *specific* CURs
        my @needed-candidates = eager gather for @fetched-candidates -> $candi {
            my $dist := $candi.dist;
            say "[DEBUG] Probing for {$dist.name}" if ?$!verbose;
            #die ?self.is-installed($candi.dist);
            if ?self.is-installed($candi.dist) {
                unless ?$!force {
                    say "{$!verbose??'['~$candi.as~'] '!!''}{$dist.identity} "
                    ~   "is already installed. Skipping... (use :force to override)";
                    next;
                }
                say "{$!verbose??'['~$candi.as~'] '!!''}{$dist.identity} is already installed. "
                ~   "Continuing anyway with :force";
            }
            take $candi;
        }
        die "All candidates appear to be installed already. Aborting!" unless $!force || +@needed-candidates;


        # Filter Stage:
        # Handle stuff like removing distributions that are already installed, that don't have
        # an allowable license, etc. It faces the same "fetch an alternative if available on failure"
        # problem outlined below under `Sort Phase` (a depends on [A, B] where A gets filtered out
        # below because it has the wrong license means we don't need anything that depends on A but
        # *do* need to replace those items with things depended on by B [which replaces A])
        my @filtered-candidates = eager gather for @needed-candidates -> $candi {
            my $dist := $candi.dist;
            say "[DEBUG] Filtering {$dist.name}" if ?$!verbose;
            # todo: Change config.json to `"Filter" : { "License" : "xxx" }`)
            given %CONFIG<License> {
                CATCH { default {
                    say $_.message;
                    die "Allowed licenses: {%CONFIG<License>.<whitelist>.join(',')    || 'n/a'}\n"
                    ~   "Disallowed licenses: {%CONFIG<License>.<blacklist>.join(',') || 'n/a'}";
                } }
                when .<blacklist>.?chars && any(|.<blacklist>) ~~ any('*', $dist.license // '') {
                    notice "License blacklist configuration exists and matches {$dist.license // 'n/a'} for {$dist.name}";
                }
                when .<whitelist>.?chars && any(|.<whitelist>) ~~ none('*', $dist.license // '') {
                    notice "License whitelist configuration exists and does not match {$dist.license // 'n/a'} for {$dist.name}";
                }
            }

            take $candi;
        }
        die "All candidates have been filtered out. No reason to proceed" unless +@filtered-candidates;

        # Sort Phase:
        # This ideally also handles creating alternate build orders when a `depends` includes
        # alternative dependencies. Then if the first build order fails it can try to fall back
        # to the next possible build order. However such functionality may not be useful this late
        # as at this point we expect to have already fetched/filtered the distributions... so either
        # we fetch all alternatives (most of which would probably would not use) or do this in a way
        # that allows us to return to a previous state in our plan (xxx: Zef::Plan is planned)
        my @sorted-candidates = self.sort-candidates(@filtered-candidates, |%_);
        die "Something went terribly wrong determining the build order" unless +@sorted-candidates;

        # Build Phase:
        # Attach appropriate metadata so we can do --dry runs using -I/some/dep/path
        # and can install after we know they pass any required tests
        my @installable-candidates = eager gather for @sorted-candidates -> $candi {
            my $dist := $candi.dist;
            say "[DEBUG] Processing {$dist.name}" if ?$!verbose;

            my @dep-specs = unique(grep *.defined,
                ($dist.depends-specs       if ?$!depends).Slip,
                ($dist.test-depends-specs  if ?$!test-depends).Slip,
                ($dist.build-depends-specs if ?$!build-depends).Slip);

            # this could probably be done in the topological-sort itself
            $dist.metainfo<includes> = eager gather DEPSPEC: for @dep-specs -> $spec {
                for @filtered-candidates -> $fcandi {
                    my $fdist := $fcandi.dist;
                    if $fdist.contains-spec($spec) {
                        take $fdist.IO.child('lib').absolute;
                        take $_ for |$fdist.metainfo<includes>;
                        next DEPSPEC;
                    }
                }
            }

            notice "Build.pm hook failed" if $dist.IO.child('Build.pm').e && !legacy-hook($dist);

            take $candi if ?$test
                ?? !self.test($dist.path, :includes(|$dist.metainfo<includes>)).values.flatmap(*.flat).grep(*.not)
                !! True;
        }
        # actually we *do* want to proceed here later so that the Report phase can know about the failed tests/build
        die "All candidates failed building and/or testing. No reason to proceed" unless +@installable-candidates;

        # Install Phase:
        # Ideally `--dry` uses a special unique CompUnit::Repository that is meant to be deleted entirely
        # and contain only the modules needed for this specific run/plan
        my @installed-candidates = gather for @installable-candidates -> $candi {
            take $candi if @curs.grep: -> $cur {
                my $dist = $candi.dist;
                # CURI.install is bugged; $dist.provides/files will both get modified and fuck up
                # any subsequent .install as the fuck up involves changing the data structures
                temp $dist.provides = $dist.provides;
                temp $dist.files    = $dist.files;

                if ?$dry {
                    say "{$dist.identity}{$!verbose??q|#|~$dist.path!!''} processed successfully";
                }
                else {
                    #$!lock.protect({
                    say "Installing {$dist.identity}{$!verbose??q|#|~$dist.path!!''}"
                    ~   " to {$!verbose??$cur.short-id~q|#|!!''}{~$cur}";
                    $cur.install($dist, $dist.sources(:absolute), $dist.scripts, $dist.resources, :$!force);
                    #});
                }
            }
        }

        # Report phase:
        # Handle exit codes for various option permutations like --force
        # Inform user of what was tested/built/installed and what failed
        # Optionally report to any cpan testers type service (testers.perl6.org)
        unless $dry {
            if @installed-candidates.map(*.dist).flatmap(*.scripts.keys).unique -> @bins {
                say "\n{+@bins} bin/ script{+@bins>1??'s'!!''}{+@bins&&?$!verbose??' ['~@bins~']'!!''} installed to:"
                ~   "\n\t" ~ @curs.map(*.prefix.child('bin')).join("\n");
            }
        }

        @installed-candidates;
    }

    method uninstall(CompUnit::Repository :@from!, *@identities) {
        my @specs = @identities.map: { Zef::Distribution::DependencySpecification.new($_) }
        eager gather for self.list-installed(|@from) -> $candi {
            my $dist = $candi.dist;
            if @specs.first({ $dist.spec-matcher($_) }) {
                my $cur  = $*REPO.repo-chain.first(*.Str eq $candi.from);
                $cur.uninstall($dist);
                take $candi;
            }
        }
    }

    method list-rev-depends($identity, Bool :$indirect) {
        my $spec  = Zef::Distribution::DependencySpecification.new($identity);
        my $dist  = self.list-available.first(*.dist.contains-spec($spec)).?dist || return [];

        my $rev-deps := gather for self.list-available -> $candidate {
            my $specs = $candidate.dist.depends-specs,
                        $candidate.dist.build-depends-specs,
                        $candidate.dist.test-depends-specs;
            take $candidate if $specs.first({ $dist.contains-spec($_) });
        }
    }

    method list-available(*@storage-names) {
        my $available := $!storage.available(|@storage-names);
    }

    # XXX: an idea is to make CURI install locations a ContentStorage as well. then this method
    # would be grouped into the above `list-available` method
    method list-installed(*@curis) {
        my @curs       = +@curis ?? @curis !! $*REPO.repo-chain.grep(*.?prefix.?e);
        my @repo-dirs  = @curs>>.prefix;
        my @dist-dirs  = |@repo-dirs.map(*.child('dist')).grep(*.e);
        my @dist-files = |@dist-dirs.map(*.IO.dir.grep(*.IO.f).Slip);

        my $dists := gather for @dist-files -> $file {
            if try { Zef::Distribution.new( |%(from-json($file.IO.slurp)) ) } -> $dist {
                my $cur = @curs.first: {.prefix eq $file.parent.parent}
                take Candidate.new( :$dist, :from($cur), :uri($file) );
            }
        }
    }

    method list-leaves {
        my @installed = self.list-installed;
        my @dep-specs = gather for @installed {
            take $_ for .dist.depends-specs;
            take $_ for .dist.build-depends-specs;
            take $_ for .dist.test-depends-specs;
        }

        my $leaves := gather for @installed -> $candi {
            my $dist := $candi.dist;
            take $candi unless @dep-specs.first: { $dist.contains-spec($_) }
        }
    }

    method is-installed($dist) {
        $ = ?self.list-installed.first(*.dist.contains-spec($dist))
    }

    method sort-candidates(@candis, *%_) {
        my @tree;
        my $visit = sub ($candi, $from? = '') {
            return if ($candi.dist.metainfo<marked> // 0) == 1;
            if ($candi.dist.metainfo<marked> // 0) == 0 {
                $candi.dist.metainfo<marked> = 1;

                my @deps = unique(grep *.defined,
                    ($candi.dist.depends-specs       if ?$!depends).Slip,
                    ($candi.dist.test-depends-specs  if ?$!test-depends).Slip,
                    ($candi.dist.build-depends-specs if ?$!build-depends).Slip);

                for @deps -> $m {
                    for @candis.grep(*.dist.spec-matcher($m)) -> $m2 {
                        $visit($m2, $candi);
                    }
                }
                @tree.append($candi);
            }
        };

        for @candis -> $candi {
            $visit($candi, 'olaf') if ($candi.dist.metainfo<marked> // 0) == 0;
        }

        $ = @tree.map(*.dist)>>.metainfo<marked>:delete;
        return @tree;
    }
}


# todo: write a real hooking implementation to CU::R::I instead of the current practice
# of writing an installer specific (literally) Build.pm
sub legacy-hook($dist) {
    my $DEBUG = ?%*ENV<ZEF_BUILDPM_DEBUG>;

    my $builder-path = $dist.IO.child('Build.pm');
    my $legacy-code  = $builder-path.IO.slurp;
    say "[Build] Attempting to build via {$builder-path}" if ?$DEBUG;

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    if ?$legacy-code.contains('use Panda')
        && !$dist.depends\      .first(/'panda' | 'Panda::'/)
        && !$dist.build-depends\.first(/'panda' | 'Panda::'/)
        && !$dist.test-depends\ .first(/'panda' | 'Panda::'/) {

        say "[Build] `build-depends` is missing entries. Attemping to mimick missing dependencies..." if ?$DEBUG;

        my $legacy-fixer-code = q:to/END_LEGACY_FIX/;
            class Build {
                method isa($what) {
                    return True if $what.^name eq 'Panda::Builder';
                    callsame;
                }
            END_LEGACY_FIX

        $legacy-code.subst-mutate(/'use Panda::' \w+ ';'/, '', :g);
        $legacy-code.subst-mutate('class Build is Panda::Builder {', "{$legacy-fixer-code}\n");
        $builder-path = "{$builder-path.absolute}.zef".IO;
        try { $builder-path.spurt($legacy-code) } || $builder-path.subst-mutate(/'.zef'$/, '');
    }


    my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$dist.IO.absolute}'); exit(0);";
    say "[Build] Command: `$cmd`" if ?$DEBUG;

    my $result;
    try {
        use Zef::Shell;
        CATCH { default { say "[Build] Something went wrong: $_" if ?$DEBUG; $result = False; } }
        my @includes = $dist.metainfo<includes>.map: { "-I{$_}" }
        my @exec = |($*EXECUTABLE, '-Ilib/.precomp', '-I.', '-Ilib', |@includes, '-e', "$cmd");
        say "[Build] cwd: {$dist.IO.absolute}" if ?$DEBUG;
        say "[Build] exec: {@exec.join(' ')}"  if ?$DEBUG;
        my $proc = zrun(|@exec, :cwd($dist.path), :out, :err);
        my @err = $proc.err.lines;
        my @out = $proc.out.lines;
        if ?$DEBUG {
            say "[Build] > $_" for @out;
            say "[Build] ! $_" for @err;
        }
        $ = $proc.out.close unless +@err;
        $ = $proc.err.close;
        $result = ?$proc;
    }
    $builder-path.IO.unlink if $builder-path.ends-with('.zef') && "{$builder-path}".IO.e;
    say "[Build] Result: {?$result??'Success'!!'Failure'}" if ?$DEBUG;
    $ = $result;
}
