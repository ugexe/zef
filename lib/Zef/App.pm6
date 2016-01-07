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
        # Once metacpan can return results again this will need to be modified so as not to
        # duplicate an identity that shows up from multiple ContentStorages
        #
        # todo: need to search provides.keys not just dist.name, so Zef::Distribution probably needs
        # to create DependencySpecifications for each of the `provides` fields (so a dependency on
        # URI::Escape fetches distribution URI as there is no URI::Escape distribution)
        #
        # todo: Update ContentStorage::CPAN to use Distribution.name/etc instead of %meta<name>/<etc>
        sub get-dists-metas(*@_) {
            state @found;
            for @_.grep({ $_ !~~ @!ignore.any }).flat -> $wanted {
                # todo: :ignore(%seen.keys);
                my %store = $!storage.candidates(Zef::Distribution::DependencySpecification.new($wanted));
                for %store.kv -> $from, $candi {
                    my $dist = $candi[0];
                    unless $dist.name ~~ @found.map({.name}).any {
                        my @wanted-deps = map *.flat, grep *.defined,
                            (|$dist.depends       if ?$depends).Slip,
                            (|$dist.test-depends  if ?$test-depends).Slip,
                            (|$dist.build-depends if ?$build-depends).Slip;
                        get-dists-metas(@wanted-deps.map(*.flat).flat);
                        @found .= append($dist);
                    }
                }
            }
            return @found;
        }

        my @discovered = get-dists-metas(|@wants).values;

        my @paths = @discovered.map: -> $dist {
            # todo: temp files
            my $sanitized-name = $dist.name.subst(':', '-', :g);
            my $uri = $dist.source-url;
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
            # temporary: legacy build hook. may have to package own version of Panda::Builder,
            # even if releasing that name into the ecosystem messes up other installers as
            # there is no other sane way of handling this junk
            die "Build.pm hook failed" if $dist.path.child('Build.pm').e && !legacy-hook($dist) && !$force;

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

# A giant fuck all to fix the sad state of build hooks because the lack of a documentated core interface
# has left many writing code that only works for a single package manager when its not needed. Why
# a package manager would force themselves as a dependency when it only wants to know if an interface
# is fulfilled is beyond me so I have no qualms with modifying code to make it work proper.
# What *SHOULD* happen is CompUnit::Repository::Installation and friends should define the damned
# interfaces themselves so not only does it leave the ecosystem in a better state (less fragile dependency
# chains) but reinstallation can also re-execute the hooks instead of (once again) demanding you have
# a dependency on an external package manager. This is not to be construed as a jab against the author,
# as Build.pm did what was needed *at the time*, but its 2016 and perl6 is released so lets do this shit right.
sub legacy-hook($dist) {
    my $builder-path = $dist.path.child('Build.pm');

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    unless $dist.depends-specs.first(/'panda' | 'Panda::'/)
        || $dist.build-depends-specs.first(/'panda' | 'Panda::'/)
        || $dist.test-depends-specs.first(/'panda' | 'Panda::'/) {

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

    my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$dist.path.IO.absolute}') ?? exit(0) !! exit(1);";

    my $result;
    try {
        CATCH { default { $result = False; } }
        my $proc = run($*EXECUTABLE, '-I.', '-Ilib', '-e', "$cmd", :cwd($dist.path));
        .say for $proc.out.lines;
        $proc.out.close;
        $result = ?$proc;
    }
    $builder-path.IO.unlink if $builder-path.ends-with('.zef') && "{$builder-path}".IO.e;
    $ = $result;
}
