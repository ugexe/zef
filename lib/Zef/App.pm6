use Zef::Config;
use Zef::Distribution::Local;
use Zef::Fetch;
use Zef::ContentStorage;
use Zef::Extract;
use Zef::Test;

our %CONFIG = ZEF-CONFIG();

class Zef::App {
    has $.cache;
    has $.indexer;
    has $.fetcher;
    has $.storage;
    has $.extractor;
    has $.tester;
    has @!ignore = <Test NativeCall lib MONKEY-TYPING nqp>;
    has $!lock = Lock.new;

    submethod BUILD(
        :$!cache     = "{%CONFIG<Store>}/store",
        :@fetchers   = |(%CONFIG<Fetch>),
        :@storages   = |(%CONFIG<ContentStorage>),
        :@extractors = |(%CONFIG<Extract>),
        :@testers    = |(%CONFIG<Test>),
    ) {
        mkdir $!cache unless $!cache.IO.e;
        $!fetcher   = Zef::Fetch.new( :backends(@fetchers) );
        $!storage   = Zef::ContentStorage.new( :backends(@storages), :$!fetcher, :$!cache );
        $!extractor = Zef::Extract.new( :backends(@extractors) );
        $!tester    = Zef::Test.new( :backends(@testers) );
    }

    method candidates(Bool :$depends, Bool :$test-depends, Bool :$build-depends,
                 Bool :$force, Bool :$verbose, Bool :$upgrade, *@wants) {

        my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };

        # Once metacpan can return results again this will need to be modified so as not to
        # duplicate an identity that shows up from multiple ContentStorages.
        #
        # XXX: :$update means to *not* take the first matching candidate encountered, but
        # the highest version that matches from all available storages (break out of ::LocalCache)
        sub get-dists(*@_) {
            state %found;
            my @allowed = |@_.grep(* ~~ none(|@!ignore, |%found.keys)).unique || return;
            say "Searching for {'dependencies ' if state $once++}{@allowed.join(', ')}" if ?$verbose;
            ALLOWED:
            for @allowed -> $wanted {

                # todo: allow sorting `candidates` by version
                CONTENT:
                for $!storage.candidates($wanted, :$upgrade) -> $cs {
                    my $storage := $cs.key;
                    my $dist    := $cs.value[0];

                    unless %found{$wanted}:exists {
                        say "[$storage] found {$dist.name}" if ?$verbose;
                        %found{$wanted} := $cs;

                        # so the user can see if $wanted was discovered as dist or a module
                        $dist.metainfo<requested-as> = $wanted;

                        # todo: alternatives, i.e. not a Str but [Str, Str]
                        my @wanted-deps = unique(grep *.chars, grep *.defined,
                            ($dist.depends       if ?$depends).Slip,
                            ($dist.test-depends  if ?$test-depends).Slip,
                            ($dist.build-depends if ?$build-depends).Slip);
                        get-dists(|@wanted-deps) if @wanted-deps.elems;
                        next ALLOWED;
                    }
                }
            }
            %found
        }

        # %found ends up with a structure like:
        # - %found{$requested-identity} = { $content-storage-name => $matching-dist }
        # - %found{"URI::Escape"} = { "Zef::ContentStorage::P6C" => Distribution.new($.name = "URI") }
        # This is probably terrible. If a better structure presents itself through a drug induced
        # epiphany (or other means) it can be replaced.
        my %found = get-dists(|@wants);

        # This is like `.install`s "Filter" phase, so maybe when the "Filter" phase is separated
        # from `.install` this can be moved there.
        if @wants.grep(* !~~ any(@!ignore)).grep({ not %found{$_}:exists }) -> @wanted {
            say "Could not find distributions matching {@wanted.join(',')}";
            die unless ?$force;
        }

        %found;
    }


    # .fetch takes identities for @wants ('CSV::Parser', 'DBIish')
    # !fetch takes storages like 'DBIish::MySQL' => { "Zef::ContentStorage::P6C" => $dist-obj }
    # This allows `.install` to `.candidates` to get results, filter those results, and
    # *then* call !fetch on those. Otherwise it would have to call `.fetch` which may end up
    # fetching items that would otherwise have been filtered out.
    # For example:
    #   - `zef fetch CSV::Parser Acme::Goatse` would call `.fetch` (as we are supplying
    #      identities that have not been identified in a content storage yet) since it
    #      still needs to `search` for those identities.
    #   - `zef install CSV::Parser Acme::Goatse` ends up calling !fetch, because internally
    #     it does its own search so it can apply its own filters (thus supplying !fetch with
    #     *exactly* what it wants, not a fuzzy idea / search term)
    method fetch(Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True,
                 Bool :$force, Bool :$verbose, *@wants) {

        my %found = self.candidates(:$depends, :$test-depends, :$build-depends, :$force, :$verbose, |@wants);
        self!fetch(%found, :$depends, :$test-depends, :$build-depends, :$force, :$verbose)
    }
    method !fetch($storage, :$depends, :$test-depends, :$build-depends, Bool :$force, Bool :$verbose) {
        my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };

        gather for $storage.kv -> $requested-as, $cs {
            my $from = $cs.key;
            my $dist = $cs.value[0];
            my $sanitized-name = $dist.name.subst(':', '-', :g);
            my $uri = $dist.source-url;
            my $extract-to = $!cache.IO.child($sanitized-name);
            my $save-as    = $!cache.IO.child($uri.IO.basename);

            say "Fetching `{$requested-as}` as {$dist.identity}";

            # todo: abstract this away properly with either a specific file uri
            # fetcher, modifying the source-url field to a path, or create a cacher role
            if $from eq 'Zef::ContentStorage::LocalCache' {
                say "[$from] Found in local cache" if ?$verbose;
            }
            else {
                $!fetcher.fetch($uri, $save-as, :&stdout);
                say "[$from] {$uri} --> $save-as" if ?$verbose;

                # should probably break this out into its out method
                if $save-as.lc.ends-with('.tar.gz' | '.zip') {
                    say "Extracting: {$save-as} to {$extract-to}" if ?$verbose;
                    $save-as = $!extractor.extract($save-as, $extract-to);
                }

                # Our `Zef::Distribution $dist` can be upraded to a `Zef::Distribution::Local`
                # as .fetch/.extract has copied the Distribution to a local path somewhere.
                # The "upgraded" functionality is generally related to turning relative paths
                # to the absolute paths on the current file system (in `provides`/`resources` for example)
                $dist does Zef::Distribution::Local($save-as);

                # Calls optional `.store` method on all ContentStorage plugins so they may
                # choose to cache the dist or simply cache the meta data of what is installed
                $!storage.store($dist);
            }

            take $dist;
        }
    }


    # xxx: needs some love
    method test(Bool :$force, Bool :$verbose, :@includes, *@paths) {
        % = @paths.classify: -> $path {
            say "Start test phase for: $path";

            my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };

            my $result = try $!tester.test($path, :includes(@includes.grep(*.so)), :&stdout);

            if !$result {
                die "Aborting due to test failure at: {$path} (use :force to override)" unless ?$force;
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


    method install(:$install-to = ['site'], *@wants, *%_) {
        state @can-install-ids = $*REPO.repo-chain.unique( :as(*.id) )\
            .grep(*.?can-install)\
            .map({.id});

        my @target-curs = $install-to\
            .map({ ($_ ~~ CompUnit::Repository) ?? $_ !! CompUnit::RepositoryRegistry.repository-for-name($_) })\
            .grep(*.defined)\
            .grep({ .id ~~ any(@can-install-ids) });

        self!install(:@target-curs, |%_, |@wants);
    }
    method !install(:@target-curs, Bool :$force, Bool :$fetch, Bool :$test, Bool :$dry, Bool :$verbose,
                    Bool :$depends, Bool :$build-depends, Bool :$test-depends, Bool :$upgrade, *@wants, *%_) {

        # temporary
        my &notice = ?$force ?? &say !! &die;

        # XXX: Each loop block below essentially represents a phase, so they will probably
        # be moved into their own method/module related directly to their phase. For now
        # lumping them here allows us to easily move functionality between phases until we
        # find the perfect balance/structure.

        # Search Phase:
        # Search ContentStorages to locate/build everything needed to fulfill the
        # requested identity ($want)
        my @discovered = eager gather for @wants -> $want {
            if $want.starts-with('.' | '/') && $want.IO.e {
                my $dist = Zef::Distribution::Local.new($want.IO.absolute);

                my @deps = unique(grep *.defined,
                    ($dist.depends       if ?$depends).Slip,
                    ($dist.test-depends  if ?$test-depends).Slip,
                    ($dist.build-depends if ?$build-depends).Slip);

                if +@deps {
                    take $_ for |self.candidates(|@deps, :$depends, :$build-depends, :$test-depends, :$verbose, :$force, :$upgrade, |%_);
                }

                # local paths should probably just use LocalCache
                take ($want => ('IO::Path' => $dist));
            }
            else {
                take $_ for |self.candidates($want, :$depends, :$build-depends, :$test-depends, :$verbose, :$force, :$upgrade, |%_);
            }
        }


        # Fetch Stage:
        # Use the results from searching ContentStorages and download/fetch the distributions they point at
        my @dists = eager gather for @discovered -> $store {
            take $_ for |self!fetch($store, :$depends, :$build-depends, :$test-depends, :$verbose, :$force, |%_);
        }


        # Filter Stage:
        # Handle stuff like removing distributions that are already installed, that don't have
        # an allowable license, etc. It faces the same "fetch an alternative if available on failure"
        # problem outlined below under `Sort Phase` (a depends on [A, B] where A gets filtered out
        # below because it has the wrong license means we don't need anything that depends on A but
        # *do* need to replace those items with things depended on by B [which replaces A])
        my @filtered-dists = eager gather DIST: for @dists -> $dist {
            say "[DEBUG] Filtering {$dist.name}" if ?$verbose;
            if ?$dist.is-installed {
                my $reported-id = ?$verbose ?? $dist.identity !! $dist.name;
                unless ?$force {
                    say "{$reported-id} is already installed. Skipping... (use :force to override)";
                    next;
                }

                say "{$reported-id} is already installed. Continuing anyway with :force";
            }

            # todo: Change config.json to `"Filter" : { "License" : "xxx" }`)
            given %CONFIG<License> {
                CATCH { default {
                    say $_.message;
                    die    "Allowed licenses: {%CONFIG<License>.<whitelist>.join(',')    || 'n/a'}\n"
                        ~  "Disallowed licenses: {%CONFIG<License>.<blacklist>.join(',') || 'n/a'}";
                } }
                when .<blacklist>.?chars && any(|.<blacklist>) ~~ any('*', $dist.license // '') {
                    notice "License blacklist configuration exists and matches {$dist.license // 'n/a'} for {$dist.name}";
                }
                when .<whitelist>.?chars && any(|.<whitelist>) ~~ none('*', $dist.license // '') {
                    notice "License whitelist configuration exists and does not match {$dist.license // 'n/a'} for {$dist.name}";
                }
            }

            take $dist;
        }


        # Sort Phase:
        # This ideally also handles creating alternate build orders when a `depends` includes
        # alternative dependencies. Then if the first build order fails it can try to fall back
        # to the next possible build order. However such functionality may not be useful this late
        # as at this point we expect to have already fetched/filtered the distributions... so either
        # we fetch all alternatives (most of which would probably would not use) or do this in a way
        # that allows us to return to a previous state in our plan (xxx: Zef::Plan is planned)
        my @sorted-dists = topological-sort(@filtered-dists, :$depends, :$build-depends, :$test-depends, |%_);


        # Build Phase:
        # Attach appropriate metadata so we can do --dry runs using -I/some/dep/path
        # and can install after we know they pass any required tests
        my @installable-dists = eager gather for @sorted-dists -> $dist {
            say "[DEBUG] Processing {$dist.name}" if ?$verbose;

            my @dep-specs = unique(grep *.defined,
                ($dist.depends-specs       if ?$depends).Slip,
                ($dist.test-depends-specs  if ?$test-depends).Slip,
                ($dist.build-depends-specs if ?$build-depends).Slip);

            # this could probably be done in the topological-sort itself
            $dist.metainfo<includes> = eager gather DEPSPEC: for @dep-specs -> $spec {
                for @filtered-dists -> $fd {
                    if $fd.contains-spec($spec) {
                        take $fd.IO.child('lib').absolute;
                        take $_ for |$fd.metainfo<includes>;
                        next DEPSPEC;
                    }
                }
            }

            notice "Build.pm hook failed" if $dist.IO.child('Build.pm').e && !legacy-hook($dist);

            take $dist if ?$test ?? self.test($dist.path, :includes(|$dist.metainfo<includes>), :$verbose, :force(?$force)) !! True;
        }

        # Install Phase:
        # Ideally `--dry` uses a special unique CompUnit::Repository that is meant to be deleted entirely
        # and contain only the modules needed for this specific run/plan
        for @installable-dists -> $dist {
            for @target-curs -> $cur {
                if ?$dry {
                    say "{$dist.name}#{$dist.path} processed successfully";
                }
                else {
                    #$!lock.protect({
                    say "Installing {$dist.name}#{$dist.path} to {$cur.short-id}#{~$cur}";
                    $cur.install($dist, $dist.sources(:absolute), $dist.scripts, $dist.resources, :force(?$force));
                    #});
                }
            }
        }

        # Report phase:
        # Handle exit codes for various option permutations like --force
        # Inform user of what was tested/built/installed and what failed
        # Optionally report to any cpan testers type service (testers.perl6.org)
        unless $dry {
            if @installable-dists.flatmap(*.scripts.keys).unique -> @bins {
                say "\n{+@bins} bin/ script{+@bins>1??'s'!!''}{+@bins&&?$verbose??' ['~@bins~']'!!''} installed to:"
                ~   "\n\t" ~ @target-curs.map(*.prefix.child('bin')).join("\n");
            }
        }
    }
}


# simple topological sort
# todo: bring back the more advanced sort zef previously used, but use with Distribution objects
sub topological-sort(@dists, Bool :$depends = True, Bool :$build-depends = True, Bool :$test-depends = True, *%_) {
    my @tree;
    my $visit = sub ($dist, $from? = '') {
        return if ($dist.metainfo<marked> // 0) == 1;
        if ($dist.metainfo<marked> // 0) == 0 {
            $dist.metainfo<marked> = 1;

            my @deps = unique(grep *.defined,
                ($dist.depends-specs       if ?$depends).Slip,
                ($dist.test-depends-specs  if ?$test-depends).Slip,
                ($dist.build-depends-specs if ?$build-depends).Slip);

            for @deps -> $m {
                for @dists.grep(*.spec-matcher($m)) -> $m2 {
                    $visit($m2, $dist);
                }
            }
            @tree.append($dist);
        }
    };

    for @dists -> $dist {
        $visit($dist, 'olaf') if ($dist.metainfo<marked> // 0) == 0;
    }

    return @tree;
}


# todo: write a real hooking implementation to CU::R::I instead of the current practice
# of writing an installer specific (literally) Build.pm
sub legacy-hook($dist) {
    my $builder-path = $dist.IO.child('Build.pm');

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    unless $dist.depends.first(/'panda' | 'Panda::'/)
        || $dist.build-depends.first(/'panda' | 'Panda::'/)
        || $dist.test-depends.first(/'panda' | 'Panda::'/) {

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

    my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$dist.IO.absolute}') ?? exit(0) !! exit(1);";

    my $result;
    try {
        use Zef::Shell;
        CATCH { default { $result = False; } }
        my @includes = $dist.metainfo<includes>.map: { "-I{$_}" }
        my $proc = zrun($*EXECUTABLE, '-I.', '-Ilib', |@includes, '-e', "$cmd", :cwd($dist.path), :out, :err);
        .say for $proc.out.lines;
        .say for $proc.err.lines;
        $proc.out.close;
        $proc.err.close;
        $result = ?$proc;
    }
    $builder-path.IO.unlink if $builder-path.ends-with('.zef') && "{$builder-path}".IO.e;
    $ = $result;
}
