use Zef::Config;
use Zef::Distribution::Local;
use Zef::Fetch;
use Zef::ContentStorage;
use Zef::Extract;
use Zef::Test;

# concept: most of what you would expect in bin/zef, except we will emit
# results out. Then bin/zef can use react on Zef::App events, and a GUI
# will be much easier to write

class Zef::App {
    has $.cache;
    has $.indexer;
    has $.fetcher;
    has $.storage;
    has $.extractor;
    has $.tester;
    has @!ignore = <Test NativeCall lib MONKEY-TYPING>;
    has $!lock = Lock.new;

    submethod BUILD(
        :$!cache     = "{ZEF-CONFIG()<store>}/store",
        :@fetchers   = |(ZEF-CONFIG()<Zef::Fetch>),
        :@storages   = |(ZEF-CONFIG()<Zef::ContentStorage>),
        :@extractors = |(ZEF-CONFIG()<Zef::Extract>),
        :@testers    = |(ZEF-CONFIG()<Zef::Test>),
    ) {
        mkdir $!cache unless $!cache.IO.e;
        $!fetcher   = Zef::Fetch.new( :backends(@fetchers) );
        $!storage   = Zef::ContentStorage.new( :backends(@storages), :$!fetcher, :$!cache );
        $!extractor = Zef::Extract.new( :backends(@extractors) );
        $!tester    = Zef::Test.new( :backends(@testers) );
    }

    method fetch(Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True, *@wants) {
        # temporary
        # This is just a naive topological sort until I can figure out how to best
        # parallelize everything with all the locking that goes on now.
        #
        # todo: Need to create a dependency class
        # that does the sort as well as linking the distributions together to allow
        # parallelization between various phases as well as properly handling
        # alternatives.
        # ex: Distro Foo depends on: Distro Bar *or* Distro Baz as well as Distro XXX. 
        # `install Foo` would download Foo, Bar, and XXX then move on to the test phase.
        # Foo tests ok, but Bar fails so the dependency object would iterate to the
        # next alternative and start downloading it. If XXX has no unresolved dependencies
        # it would be able to start testing while Baz is getting downloaded. If any chain
        # reaches the end all linked processes can either be aborted or continue instantly.
        #
        # Once metacpan can return results again this will need to be modified so as not to
        # duplicate an identity that shows up from multiple ContentStorages
        sub get-dists-metas(*@_) {
            state @found;
            for @_.grep(*.defined).grep({ $_ !~~ @!ignore.any }) -> $wanted {
                # todo: :ignore(%seen.keys);
                my %store = $!storage.candidates($wanted);
                for %store.kv -> $from, $candi {
                    my $dist = $candi[0];
                    unless $dist<name> ~~ @found.map({.<name>}).any {
                        my @wanted-deps = slip grep *.defined,
                            (|$dist<depends>       if ?$depends).Slip,
                            (|$dist<test-depends>  if ?$test-depends).Slip,
                            (|$dist<build-depends> if ?$build-depends).Slip;
                        get-dists-metas(|@wanted-deps);
                        @found .= append($dist);
                    }
                }
            }
            return @found;
        }

        my @discovered = get-dists-metas(|@wants).values;

        my @paths = @discovered.map: -> $seen {
            # todo: temp files
            my $sanitized-name = $seen<name>.subst(':', '-', :g);
            my $uri = $seen<source-url>;
            my $extract-to = $!cache.IO.child($sanitized-name);
            my $save-as    = $!cache.IO.child($uri.IO.basename);

            say "[DEBUG] Fetching {$uri} to {$save-as}";
            $!fetcher.fetch($uri, $save-as);
            
            if $save-as.lc.ends-with('.tar.gz' | '.zip') {
                say "[DEBUG] Extracting: {$save-as} to {$extract-to}";
                $save-as = $!extractor.extract($save-as, $extract-to);
            }
            $save-as;
        }
    }

    method test(Bool :$force, *@paths) {
        % = @paths.classify: -> $path {
            say "[DEBUG] Testing: $path";
            my $result = $!tester.test($path);
            unless ?$result {
                die "Aborting due to test failure at: {$path} (use :force to override)" unless ?$force;
                say "Test failure at: {$path}. Continuing anyway with :force"
            }
            ?$result ?? "pass" !! "fail";
        }
    }

    method search(*@identities, *%fields) {
        $!storage.search(|@identities, |%fields);
    }

    # todo: install methods should run fetch/test/etc methods itself so we can skip testing dists that are already installed
    method install(:@install-to = ['site'], *@wanted, *%_) {
        state @can-install-ids = $*REPO.repo-chain.unique( :as(*.id) )\
            .grep(*.?can-install)\
            .map({.id});

        my @target-curs = @install-to\
            .map({ ($_ ~~ CompUnit::Repository) ?? $_ !! CompUnit::RepositoryRegistry.repository-for-name($_) })\
            .grep(*.defined)\
            .grep({ $_.id ~~ any(@can-install-ids) });

        self!install(|@wanted, :@target-curs, |%_);
    }
    method !install(:@target-curs, Bool :$force, *@wanted, Bool :$fetch, Bool :$test, *%_) {
        my @dists = @wanted.map: -> $want {
            # todo: manifest/lookup for ContentStorage.cache + Fetcher for local paths (for .fetch("some-path", :depends))
            # 1) Will allow checking path for meta info to see if we can skip fetching it
            # 2) @wants may contain an identity but also a path string. However, if dependencies
            # are needed they will always be identities so this would let us translate those
            # identities into local paths (if they exist) to take any required actions on
            my @got = ($want.starts-with('.' | '/') && ?$want.IO.e ?? $want.IO
                    !! ?$fetch ?? |self.fetch($want, |%_)
                    !! die "Don't know how to locate $want locally. Did you mean to pass :fetch?");
            @got.map({ Zef::Distribution::Local.new($_) }).Slip;
        }

        for topological-sort(@dists, |%_) -> $dist {
            my %tested = ?$test ?? self.test($dist.path, :force(?$force)) !! { };

            # until CU::R.resolve is merged we need to force on '.' so rakudobrew's install
            # does not think it is already installed when EVAL'd due to the -Ilib finding it
            if ?$dist.is-installed && $dist.path.abspath ne $*CWD.abspath {
                say "[DEBUG] {$dist.name} is already installed. Skipping... (use :force to override)" and next unless ?$force;
                say "[DEBUG] {$dist.name} is already installed. Continuing anyway with :force";
            }

            for @target-curs -> $cur {
                $!lock.protect({
                    say "[DEBUG] Installing {$dist.name}:{$dist.path} to {$cur.short-id}#{~$cur}";
                    $cur.install($dist, $dist.sources(:absolute), $dist.scripts, $dist.resources, :force(?$force));
                    # $dist.cache{~$dist}:delete # clear cache?
                });
            }
        }
    }
}

# XXX: Simplistic topological sort
# todo: build-depends, test-depends
sub topological-sort(@dists, Bool :$depends = True, Bool :$build-depends = True, Bool :$test-depends = True, *%_) {
    my @tree;
    my $visit = sub ($dist, $from? = '') {
        return if ($dist.metainfo<marked> // 0) == 1;
        if ($dist.metainfo<marked> // 0) == 0 {
            $dist.metainfo<marked> = 1;

            my @deps = slip grep *.defined,
                ($dist.depends-specs       if ?$depends).Slip,
                ($dist.test-depends-specs  if ?$test-depends).Slip,
                ($dist.build-depends-specs if ?$build-depends).Slip;

            for @deps.unique( :as(*.Str) ) -> $m {
                for @dists.grep(* ~~ $m) -> $m2 {
                    $visit($m2, $dist.identity);
                }
            }
            $dist.metainfo<marked>++;
            @tree.append($dist);
        }
    };

    for @dists -> $dist {
        $visit($dist, 'olaf') if ($dist.metainfo<marked> // 0) == 0;
    }

    return @tree;
}
