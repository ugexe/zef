use Zef::Config;
use Zef::Distribution;
use Zef::Distribution::Local;
use Zef::Fetch;
use Zef::ContentStorage;
use Zef::Extract;
use Zef::Test;

our %CONFIG;

class Zef::App {
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
        my @path-search = @wants.grep({.starts-with('.' | '/')}, :p);
        @wants.splice($_) for @path-search.map(*.key).sort.reverse;
        @needs.push($_) for @path-search.map(*.value).map: { Candidate.new(:uri(~$_.IO.absolute), :requested-as(~$_)) }

        my @uri-search  = |@wants.grep(* ~~ none(|@path-search>>.value)).grep({
            my $uri = Zef::Utils::URI($_);
            ?$uri ?? !$uri.is-relative ?? True !! False !! False
        }, :p);
        @wants.splice($_) for @uri-search.map(*.key).sort.reverse;
        @needs.push($_) for @uri-search.map(*.value).map: { Candidate.new(:uri(~$_), :requested-as(~$_)) }

        for self.fetch(|@needs) -> $candi {
            @candidates.push($candi);
            @wants.append(|unique(grep *.chars, grep *.defined,
                ($candi.dist.depends       if ?$!depends).Slip,
                ($candi.dist.test-depends  if ?$!test-depends).Slip,
                ($candi.dist.build-depends if ?$!build-depends).Slip));
        }

        # ContentStorage.candidate search loop
        # The above chunk of code is for "finding" a distribution that we know the exact location of. This is for
        # finding identities (like you would type on the command line, `use` in your code, or put in your `depends`)
        while ( +@wants ) {
            my @wanted = @wants.splice(0);
            my @todo   = @wanted.grep(* ~~ none(|@!ignore)).grep(-> $id { 
                my $spec = Zef::Distribution::DependencySpecification.new($id);
                so !@candidates.first(*.dist.contains-spec($spec))
            }).unique;
            @needs     = (|@needs, |@todo).grep(* ~~ none(|@!exclude)).unique;

            say "Searching for {'dependencies ' if state $once++}{@todo.join(', ')}" if ?$!verbose;

            for $!storage.candidates(|@todo, :$upgrade) -> $candis {
                for $candis.grep({ .dist.identity ~~ none(|@candidates.map(*.dist.identity)) }) -> $candi {
                    # conditional is to handle --depsonly (installing only deps)
                    if $candi.requested-as ~~ none(@!exclude) {
                        @candidates.push($candi);
                        say "[{$candi.recommended-by}] found {$candi.dist.name}" if ?$!verbose;
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

        # For now we use unique on the `requested-as` field so if someone has both p6c and cpan
        # enabled that they only get 1 result for a specific requested instead of 1 from each.
        # In the future this won't be neccesary because they *should* match on identities, but
        # right now metacpan has some of the versions/auths screwy. This means a dist on both
        # may be exactly the same, but metacpan reports the auth or version slightly different
        # causing it to be treated as a unique result.
        my @chosen = @candidates.unique(:as(*.requested-as));
        if +@needs !== +@chosen {
            # if @needs has more elements than @missing its probably a bug related to:
            my @missing = @needs.grep(* !~~ any(@candidates>>.requested-as));
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
            my $from         = $candi.recommended-by;
            my $requested-as = $candi.requested-as;
            my $uri          = $candi.uri;
            my $tmp         := %CONFIG<TempDir>.IO;
            my $stage-at    := $tmp.child($uri.IO.basename);
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

            say "$uri saved to $save-to";

            # should probably break this out into its out method
            say "[{$!extractor.^name}] Extracting: {$save-to} to {$extract-to}" if ?$!verbose;
            my $dist-dir = $!extractor.extract($save-to, $extract-to);
            say "Extracted to: {$dist-dir}" if ?$!verbose;

            # $candi.dist may already contain a distribution object, but we reassign it as a
            # Zef::Distribution::Local so that it has .path/.IO methods. These could be
            # applied via a role, but this way also allows us to use the distribution's
            # meta data instead of the (possibly out-of-date) meta data content storage found
            $candi.dist = Zef::Distribution::Local.new(~$dist-dir);

            say "{$candi.dist.identity} fulfills the request for {$candi.requested-as}";

            take $candi;
        }

        # Calls optional `.store` method on all ContentStorage plugins so they may
        # choose to cache the dist or simply cache the meta data of what is installed.
        # Should go in its own phase/lifecycle event
        $!storage.store(|@saved.map(*.dist));

        @saved;
    }


    # xxx: needs some love
    method test(:@includes, *@paths) {
        % = @paths.classify: -> $path {
            say "Start test phase for: $path";

            my &stdout = ?$!verbose ?? -> $o {$o.say} !! -> $ { };

            my $result = $!tester.test($path, :includes(@includes.grep(*.so)), :&stdout);

            if !$result {
                die "Aborting due to test failure at: {$path} (use :force to override)" unless ?$!force;
                say "Test failure at: {$path}. Continuing anyway with :force"
            }
            else {
                say "Testing passed for {$path}";
            }

            # should really return a hash of passes and failures
            ?$result
        }
    }


    # xxx: needs some love
    method search(*@identities, *%fields) {
        $!storage.search(|@identities, |%fields);
    }


    method install(:$install-to = ['site'], Bool :$fetch, Bool :$test, Bool :$dry, Bool :$upgrade, *@wants, *%_) {
        my &notice = ?$!force ?? &say !! &die;

        state @can-install-ids = $*REPO.repo-chain.unique( :as(*.id) )\
            .grep(*.?can-install)\
            .map({.id});

        my @target-curs = $install-to\
            .map({ ($_ ~~ CompUnit::Repository) ?? $_ !! CompUnit::RepositoryRegistry.repository-for-name($_) })\
            .grep(*.defined)\
            .grep({ .id ~~ any(@can-install-ids) });

        # XXX: Each loop block below essentially represents a phase, so they will probably
        # be moved into their own method/module related directly to their phase. For now
        # lumping them here allows us to easily move functionality between phases until we
        # find the perfect balance/structure.

        # Search Phase:
        # Search ContentStorages to locate each Candidate needed to fulfill the requested identities
        my @found-candidates = |self.candidates(|@wants, :$upgrade, |%_).unique;


        # Fetch Stage:
        # Use the results from searching ContentStorages and download/fetch the distributions they point at
        my @fetched-candidates = eager gather for @found-candidates -> $store {
            # xxx: paths and uris we already fetched (saves us from copying 1 extra time)
            take $store and next if $store.dist.^name.contains('Zef::Distribution::Local');
            # todo: send |@candidates to fetch instead of each $store one at a time
            take $_ for |self.fetch($store, |%_);
        }

        # todo: continue passing the Candidate object instead of grabbing the distribution in the above code

        # Filter Stage:
        # Handle stuff like removing distributions that are already installed, that don't have
        # an allowable license, etc. It faces the same "fetch an alternative if available on failure"
        # problem outlined below under `Sort Phase` (a depends on [A, B] where A gets filtered out
        # below because it has the wrong license means we don't need anything that depends on A but
        # *do* need to replace those items with things depended on by B [which replaces A])
        my @filtered-candidates = eager gather DIST: for @fetched-candidates -> $candi {
            my $dist := $candi.dist;
            say "[DEBUG] Filtering {$dist.name}" if ?$!verbose;
            if ?$dist.is-installed {
                unless ?$!force {
                    say "{$!verbose??'['~$candi.requested-as~'] '!!''}{$dist.identity} "
                    ~   "is already installed. Skipping... (use :force to override)";
                    next;
                }

                say "{$!verbose??'['~$candi.requested-as~'] '!!''}{$dist.identity} is already installed. "
                ~   "Continuing anyway with :force";
            }

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


        # Sort Phase:
        # This ideally also handles creating alternate build orders when a `depends` includes
        # alternative dependencies. Then if the first build order fails it can try to fall back
        # to the next possible build order. However such functionality may not be useful this late
        # as at this point we expect to have already fetched/filtered the distributions... so either
        # we fetch all alternatives (most of which would probably would not use) or do this in a way
        # that allows us to return to a previous state in our plan (xxx: Zef::Plan is planned)
        my @sorted-candidates = self.sort-candidates(@filtered-candidates, |%_);

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

            take $candi if ?$test ?? self.test($dist.path, :includes(|$dist.metainfo<includes>)) !! True;
        }

        # Install Phase:
        # Ideally `--dry` uses a special unique CompUnit::Repository that is meant to be deleted entirely
        # and contain only the modules needed for this specific run/plan
        for @installable-candidates -> $candi {
            my $dist := $candi.dist;
            for @target-curs -> $cur {
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
            if @installable-candidates.map(*.dist).flatmap(*.scripts.keys).unique -> @bins {
                say "\n{+@bins} bin/ script{+@bins>1??'s'!!''}{+@bins&&?$!verbose??' ['~@bins~']'!!''} installed to:"
                ~   "\n\t" ~ @target-curs.map(*.prefix.child('bin')).join("\n");
            }
        }
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
    my $builder-path = $dist.IO.child('Build.pm');

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    unless $dist.depends.first(/'panda' | 'Panda::'/)
        || $dist.build-depends.first(/'panda' | 'Panda::'/)
        || $dist.test-depends.first(/'panda' | 'Panda::'/)
        || IS-INSTALLED('Panda::Builder') {

        my $legacy-fixer-code = q:to/END_LEGACY_FIX/;
            class Build {
                method isa($what) {
                    return True if $what.^name eq 'Panda::Builder';
                    callsame;
                }
            END_LEGACY_FIX

        my $legacy-code = $builder-path.IO.slurp;
        $legacy-code.subst-mutate(/'use Panda::' \w+ ';'/, '', :g);
        $legacy-code.subst-mutate('class Build is Panda::Builder {', "{$legacy-fixer-code}\n");
        $builder-path = "{$builder-path.absolute}.zef".IO;
        try { $builder-path.spurt($legacy-code) } || $builder-path.subst-mutate(/'.zef'$/, '');
    }

    my $cmd = "require <{$builder-path.basename}>; "
            ~ "try ::('Build').new.build('{$dist.IO.absolute}'); "
            ~ '$!.defined ?? exit(1) !! exit(0)';

    my $result;
    try {
        use Zef::Shell;
        CATCH { default { $result = False; } }
        my @includes = $dist.metainfo<includes>.map: { "-I{$_}" }
        my $proc = zrun($*EXECUTABLE, '-Ilib/.precomp', '-I.', '-Ilib', |@includes, '-e', "$cmd", :cwd($dist.path), :out, :err);
        my @out = $proc.out.lines;
        my @err = $proc.err.lines;
        $ = $proc.out.close;
        $ = $proc.err.close;
        $result = ?$proc;
    }
    $builder-path.IO.unlink if $builder-path.ends-with('.zef') && "{$builder-path}".IO.e;
    $ = $result;
}
