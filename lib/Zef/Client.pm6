use Zef;
use Zef::Distribution;
use Zef::Distribution::Local;
use Zef::Fetch;
use Zef::ContentStorage;
use Zef::Extract;
use Zef::Test;

class Zef::Client {
    has $.cache;
    has $.indexer;
    has $.fetcher;
    has $.storage;
    has $.extractor;
    has $.tester;
    has $.config;

    has $.logger = Supplier.new;

    has @.exclude;
    has @!ignore = <Test NativeCall lib MONKEY-TYPING nqp>;

    has Bool $.verbose       is rw = False;
    has Bool $.force         is rw = False;
    has Bool $.depends       is rw = True;
    has Bool $.build-depends is rw = True;
    has Bool $.test-depends  is rw = True;


    method new(
        :cache(:$zcache),
        :fetcher(:$zfetcher),
        :storage(:$zstorage),
        :extractor(:$zextractor),
        :tester(:$ztester),
        :$config,
        *%_
        ) {
        my $cache := ?$zcache ?? $zcache !! ?$config<StoreDir>
            ?? $config<StoreDir>
            !! die "Zef::Client requires a cache parameter";
        my $fetcher := ?$zfetcher ?? $zfetcher !! ?$config<Fetch>
            ?? Zef::Fetch.new(:backends(|$config<Fetch>))
            !! die "Zef::Client requires a fetcher parameter";
        my $extractor := ?$zextractor ?? $zextractor !! ?$config<Extract>
            ?? Zef::Extract.new(:backends(|$config<Extract>))
            !! die "Zef::Client requires an extractor parameter";
        my $tester := ?$ztester ?? $ztester !! ?$config<Test>
            ?? Zef::Test.new(:backends(|$config<Test>))
            !! die "Zef::Client requires a tester parameter";
        my $storage := ?$zstorage ?? $zstorage !! ?$config<ContentStorage>
            ?? Zef::ContentStorage.new(:backends(|$config<ContentStorage>))
            !! die "Zef::Client requires a storage parameter";

        mkdir $cache unless $cache.IO.e;

        $storage.cache   //= $cache;
        $storage.fetcher //= $fetcher;

        self.bless(:$cache, :$fetcher, :$storage, :$extractor, :$tester, :$config, |%_);
    }

    method find-candidates(Bool :$upgrade, *@identities ($, *@)) {
        self.logger.emit({
            level   => INFO,
            stage   => RESOLVE,
            phase   => BEFORE,
            payload => @identities,
            message => "Searching for: {@identities.join(', ')}",
        });
        my @candidates = self!find-candidates(:$upgrade, |@identities);
        self.logger.emit({
            level   => VERBOSE,
            stage   => RESOLVE,
            phase   => AFTER,
            payload => @candidates.map(*.dist.identity),
            message => "Found: {@candidates.map(*.dist.identity).join(', ')}",
        }) if +@candidates;
        @candidates;

    }
    method !find-candidates(Bool :$upgrade, *@identities ($, *@)) {
        my $candidates := $!storage.candidates(|@identities, :$upgrade)\
            .grep(-> $dist { not @!exclude.first(-> $spec {$dist.dist.contains-spec($spec)}) })\
            .unique(:as(*.dist.identity));
    }

    method find-prereq-candidates(Bool :$upgrade, *@candis ($, *@)) {
        my @skip = @candis.map(*.dist);

        my $prereqs := gather {
            my @specs = self.list-dependencies(@candis);

            while @specs.splice -> @specs-batch {
                self.logger.emit({
                    level   => DEBUG,
                    stage   => RESOLVE,
                    phase   => BEFORE,
                    payload => @specs-batch,
                    message => "Dependencies: {@specs-batch.map(*.name).unique.join(', ')}",
                });

                next unless my @needed = @specs-batch\               # The current set of specs
                    .grep({ not @skip.first(*.contains-spec($_)) })\ # Dists in @skip are not needed
                    .grep({ not self.is-installed($_)            }); # Installed dists are not needed
                my @identities = @needed.map(*.identity);
                self.logger.emit({
                    level   => INFO,
                    stage   => RESOLVE,
                    phase   => BEFORE,
                    payload => @needed,
                    message => "Searching for missing dependencies: {@identities.join(', ')}",
                });

                next unless my @prereq-candidates = self!find-candidates(:$upgrade, |@identities);
                my @prereq-identities = @prereq-candidates.map(*.dist.identity);
                self.logger.emit({
                    level   => VERBOSE,
                    stage   => RESOLVE,
                    phase   => AFTER,
                    payload => @prereq-candidates,
                    message => "Found dependencies: {@prereq-identities.join(', ')}",
                });

                @skip.append: @prereq-candidates.map(*.dist);
                @specs = self.list-dependencies(@prereq-candidates);
                for @prereq-candidates -> $prereq {
                    $prereq.is-dependency = True;
                    take $prereq;
                }
            }
        }

        $prereqs.unique(:as(*.dist.identity));
    }

    method fetch(*@candidates ($, *@)) {
        my @saved = eager gather for @candidates -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => FETCH,
                phase   => BEFORE,
                payload => $candi,
                message => "Fetching: {$candi.as}",
            });

            my $from     = $candi.from;
            my $as       = $candi.as;
            my $uri      = $candi.uri;
            my $tmp      = $!config<TempDir>.IO;
            my $stage-at = $tmp.child($uri.IO.basename);
            die "failed to create directory: {$tmp.absolute}"
                unless ($tmp.IO.e || mkdir($tmp));

            # $candi.uri will always point to where $candi.dist should be copied from.
            # It could be a file or url; $dist.source-url contains where the source was
            # originally located but we may want to use a local copy (while retaining
            # the original source-url for some other purpose like updating)
            my $save-to    = $!fetcher.fetch($uri, $stage-at, :$!logger);
            my $relpath    = $stage-at.relative($tmp);
            my $extract-to = $!cache.IO.child($relpath);
            self.logger.emit({
                level   => VERBOSE,
                stage   => FETCH,
                phase   => AFTER,
                payload => $candi,
                message => "Fetched: {$candi.as} to $save-to",
            });
            die "Failure fetching to: {$save-to}" unless $save-to.IO.e;

            # should probably break this out into its out method
            self.logger.emit({
                level   => DEBUG,
                stage   => EXTRACT,
                phase   => BEFORE,
                payload => $candi,
                message => "Extracting: {$candi.as}",
            });

            my $dist-dir = $!extractor.extract($save-to, $extract-to, :$!logger);
            self.logger.emit({
                level   => DEBUG,
                stage   => EXTRACT,
                phase   => AFTER,
                payload => $candi,
                message => "Extracted: {$candi.as} to {$dist-dir}",
            });

            # $candi.dist may already contain a distribution object, but we reassign it as a
            # Zef::Distribution::Local so that it has .path/.IO methods. These could be
            # applied via a role, but this way also allows us to use the distribution's
            # meta data instead of the (possibly out-of-date) meta data content storage found
            my $dist        = Zef::Distribution::Local.new(~$dist-dir);
            my $local-candi = $candi.clone(:$dist);
            # XXX: the above used to just be `$candi.dist = $dist` where dist is rw

            take $local-candi;
        }

        # Calls optional `.store` method on all ContentStorage plugins so they may
        # choose to cache the dist or simply cache the meta data of what is installed.
        # Should go in its own phase/lifecycle event
        $!storage.store(|@saved.map(*.dist));

        @saved;
    }

    # xxx: needs some love. also an entire specification
    method build(*@candidates ($, *@)) {
        my @built = eager gather for @candidates -> $candi {
            my $dist := $candi.dist;
            unless ?$dist.IO.child('Build.pm').e {
                self.logger.emit({
                    level   => DEBUG,
                    stage   => BUILD,
                    phase   => BEFORE,
                    payload => $candi,
                    message => "# SKIP: No Build.pm for {$candi.dist.?identity // $candi.as}",
                });
                take $candi;
                next();
            }

            $!logger.emit({
                level   => INFO,
                stage   => BUILD,
                phase   => BEFORE,
                payload => $candi,
                message => "Building: {$candi.dist.?identity // $candi.as}",
            });

            my $result = legacy-hook($candi, :$!logger);

            $candi does role :: { has $.build-results = ?$result };

            if !$result {
                self.logger.emit({
                    level   => ERROR,
                    stage   => BUILD,
                    phase   => AFTER,
                    payload => $candi,
                    message => "Building [FAIL]: {$candi.dist.?identity // $candi.as}",
                });
                die "Aborting due to build failure: {$candi.dist.?identity // $candi.uri}"
                ~   "(use --force to override)" unless ?$!force;
            }
            else {
                self.logger.emit({
                    level   => INFO,
                    stage   => BUILD,
                    phase   => AFTER,
                    payload => $candi,
                    message => "Building [OK] for {$candi.dist.?identity // $candi.as}",
                });
            }

            take $candi;
        }
    }

    # xxx: needs some love
    method test(:@includes, *@candidates ($, *@)) {
        my @tested = eager gather for @candidates -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => TEST,
                phase   => BEFORE,
                payload => $candi,
                message => "Testing: {$candi.dist.?identity // $candi.as}",
            });

            my @result = $!tester.test($candi.dist.path, :includes($candi.dist.metainfo<includes> // []), :$!logger);

            $candi does role :: { has $.test-results = |@result };

            if @result.grep(*.not).elems {
                self.logger.emit({
                    level   => ERROR,
                    stage   => TEST,
                    phase   => AFTER,
                    payload => $candi,
                    message => "Testing [FAIL]: {$candi.dist.?identity // $candi.as}",
                });
                die "Aborting due to test failure: {$candi.dist.?identity // $candi.as} "
                ~   "(use --force to override)" unless ?$!force;
            }
            else {
                self.logger.emit({
                    level   => INFO,
                    stage   => TEST,
                    phase   => AFTER,
                    payload => $candi,
                    message => "Testing [OK] for {$candi.dist.?identity // $candi.as}",
                });
            }

            take $candi;
        }

        @tested
    }


    # xxx: needs some love
    method search(*@identities ($, *@), *%fields) {
        $!storage.search(|@identities, |%fields);
    }


    method install(
        CompUnit::Repository :@to!, # target CompUnit::Repository
        Bool :$fetch = True,        # try fetching whats missing
        Bool :$test  = True,        # run tests
        Bool :$dry,                 # do everything *but* actually install
        Bool :$upgrade,             # NYI
        *@candidates ($, *@),
        *%_
        ) {
        my @curs = @to.grep: -> $cur {
            UNDO {
                self.logger.emit({
                    level   => WARN,
                    stage   => INSTALL,
                    phase   => BEFORE,
                    payload => $cur,
                    message => "CompUnit::Repository install target is not writeable/installable: {$cur}"
                });
            }
            KEEP {
                self.logger.emit({
                    level   => TRACE,
                    stage   => INSTALL,
                    phase   => BEFORE,
                    payload => $cur,
                    message => "CompUnit::Repository install target is valid: {$cur}"
                });
            }
            $cur.?can-install || next();
        }
        die "Need a valid installation target to continue" unless ?$dry || +@curs;

        # XXX: Each loop block below essentially represents a phase, so they will probably
        # be moved into their own method/module related directly to their phase. For now
        # lumping them here allows us to easily move functionality between phases until we
        # find the perfect balance/structure.
        die "Must specify something to install" unless +@candidates;

        # Fetch Stage:
        # Use the results from searching ContentStorages and download/fetch the distributions they point at
        my @fetched-candidates = eager gather for @candidates -> $store {
            take $_ for $store.dist.^name.contains('Zef::Distribution::Local') ?? $store !! |self.fetch($store, |%_);
        }
        die "Failed to fetch any candidates. No reason to proceed" unless +@fetched-candidates;

        # Filter Stage:
        # Handle stuff like removing distributions that are already installed, that don't have
        # an allowable license, etc. It faces the same "fetch an alternative if available on failure"
        # problem outlined below under `Sort Phase` (a depends on [A, B] where A gets filtered out
        # below because it has the wrong license means we don't need anything that depends on A but
        # *do* need to replace those items with things depended on by B [which replaces A])
        my @filtered-candidates = eager gather for @fetched-candidates -> $candi {
            my $dist := $candi.dist;
            self.logger.emit({
                level   => DEBUG,
                stage   => FILTER,
                phase   => BEFORE,
                payload => $candi,
                message => "Filtering: {$dist.identity}",
            });

            # todo: Change config.json to `"Filter" : { "License" : "xxx" }`)
            my $msg = do given $!config<License> {
                CATCH { default {
                    die "{$_.message}\n"
                    ~   "Allowed licenses: {$!config<License>.<whitelist>.join(',')    || 'n/a'}\n"
                    ~   "Disallowed licenses: {$!config<License>.<blacklist>.join(',') || 'n/a'}";
                } }
                when .<blacklist>.?chars && any(|.<blacklist>) ~~ any('*', $dist.license // '') {
                    $ = "License blacklist configuration exists and matches {$dist.license // 'n/a'} for {$dist.name}";
                }
                when .<whitelist>.?chars && any(|.<whitelist>) ~~ none('*', $dist.license // '') {
                    $ = "License whitelist configuration exists and does not match {$dist.license // 'n/a'} for {$dist.name}";
                }
            }

            ?$msg ?? $!logger.emit({
                level   => ERROR,
                stage   => FILTER,
                phase   => AFTER,
                payload => $candi,
                message => "Filtering [FAIL] for {$candi.dist.?identity // $candi.as}: $msg",
            }) !! $!logger.emit({
                level   => DEBUG,
                stage   => FILTER,
                phase   => AFTER,
                payload => $candi,
                message => "Filtering [OK] for {$candi.dist.?identity // $candi.as}",
            });

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


        # Setup(?) Phase:
        # Attach appropriate metadata so we can do --dry runs using -I/some/dep/path
        # and can install after we know they pass any required tests
        my @linked-candidates = self.link-candidates(|@sorted-candidates);
        die "Something went terribly wrong linking the distributions" unless +@linked-candidates;


        # Build Phase:
        my @built-candidates = self.build(|@linked-candidates);
        die "No installable candidates remain after `build` failures" unless +@built-candidates;


        # Test Phase:
        my @tested-candidates = gather for @built-candidates -> $candi {
            next() R, take($candi) unless ?$test;

            my $tested = self.test($candi);
            my $failed = $tested.map(*.test-results.grep(!*.so).elems).sum;

            take $candi unless ?$failed && !$!force;
        }
        # actually we *do* want to proceed here later so that the Report phase can know about the failed tests/build
        die "All candidates failed building and/or testing. No reason to proceed" unless +@tested-candidates;

        # Install Phase:
        # Ideally `--dry` uses a special unique CompUnit::Repository that is meant to be deleted entirely
        # and contain only the modules needed for this specific run/plan
        my @installed-candidates = eager gather for @tested-candidates -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => INSTALL,
                phase   => BEFORE,
                payload => $candi,
                message => "Installing: {$candi.dist.?identity // $candi.as}",
            });

            my @installed-at = |@curs.grep: -> $cur {
                # CURI.install is bugged; $dist.provides/files will both get modified and fuck up
                # any subsequent .install as the fuck up involves changing the data structures
                my $dist = $candi.dist.clone(provides => $candi.dist.provides, files => $candi.dist.files);

                if ?$dry {
                    self.logger.emit({
                        level   => VERBOSE,
                        stage   => INSTALL,
                        phase   => AFTER,
                        payload => $candi,
                        message => "(dry) Installed: {$candi.dist.?identity // $candi.as}",
                    });
                }
                else {
                    #$!lock.protect({
                    try {
                        CATCH { default {
                            self.logger.emit({
                                level   => ERROR,
                                stage   => INSTALL,
                                phase   => AFTER,
                                payload => $candi,
                                message => "Install [FAIL] for {$candi.dist.?identity // $candi.as}: {$_}",
                            });
                            $_.rethrow;
                        } }
                        my $install = $cur.install($dist.compat, $dist.sources(:absolute), $dist.scripts, $dist.resources, :$!force);
                        self.logger.emit({
                            level   => VERBOSE,
                            stage   => INSTALL,
                            phase   => AFTER,
                            payload => $candi,
                            message => "Install [OK] for {$candi.dist.?identity // $candi.as}",
                        }) if ?$install;
                        $ = ?$install;
                    }
                    #});
                }
            }

            take $candi if +@installed-at;
        }

        # Report phase:
        # Handle exit codes for various option permutations like --force
        # Inform user of what was tested/built/installed and what failed
        # Optionally report to any cpan testers type service (testers.perl6.org)
        unless $dry {
            if @installed-candidates.map(*.dist).flatmap(*.scripts.keys).unique -> @bins {
                my $msg = "\n{+@bins} bin/ script{+@bins>1??'s'!!''}{+@bins&&?$!verbose??' ['~@bins~']'!!''} installed to:"
                ~ "\n" ~ @curs.map(*.prefix.child('bin')).join("\n");
                self.logger.emit({
                    level   => INFO,
                    stage   => REPORT,
                    phase   => LIVE,
                    message => $msg,
                });
            }
        }

        @installed-candidates;
    }

    method uninstall(CompUnit::Repository :@from!, *@identities) {
        my @specs = @identities.map: { Zef::Distribution::DependencySpecification.new($_) }
        eager gather for self.list-installed(|@from) -> $candi {
            my $dist = $candi.dist;
            if @specs.first({ $dist.spec-matcher($_) }) {
                my $cur = CompUnit::RepositoryRegistry.repository-for-spec("inst#{$candi.from}", :next-repo($*REPO));
                $cur.uninstall($dist.compat);
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

    method list-dependencies(*@candis) {
        my $deps := gather for @candis -> $candi {
            take $_ for grep *.defined,
                ($candi.dist.depends-specs       if ?$!depends).Slip,
                ($candi.dist.test-depends-specs  if ?$!test-depends).Slip,
                ($candi.dist.build-depends-specs if ?$!build-depends).Slip;
        }
        $deps.unique(:as(*.identity));
    }

    method is-installed($spec, :@at) {
        $ = ?self.list-installed(|@at).first(*.dist.contains-spec($spec))
    }

    method sort-candidates(@candis, *%_) {
        my @tree;
        my $visit = sub ($candi, $from? = '') {
            return if ($candi.dist.metainfo<marked> // 0) == 1;
            if ($candi.dist.metainfo<marked> // 0) == 0 {
                $candi.dist.metainfo<marked> = 1;

                my @deps = |self.list-dependencies($candi);

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

    # Adds appropriate include (-I / PERL6LIB) paths for dependencies
    # This should probably be handled by the Candidate class... one day...
    proto method link-candidates(|) {*}
    multi method link-candidates(Bool :$recursive! where *.so, *@candidates) {
        # :recursive
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX/lib -I/Bar/YYY/lib -I/Baz/ZZZ/lib
        #   - Bar::YYY -> -I/Bar/YYY/lib -I/Baz/ZZZ/lib
        #   - Baz::ZZZ -> -I/Baz/ZZZ/lib

        # XXX: Need to change this so it only add indirect dependencies
        # instead of just recursing the array in order. Otherwise there
        # can be distributions that are part of a different dependency
        # chain will end up with some extra includes

        my @linked = self.link-candidates(|@candidates);
        @ = @linked.map: -> $candi { # can probably use rotor instead of doing the `@a[$index + 1..*]` dance
            my @direct-includes    = |$candi.dist.metainfo<includes>.grep(*.so);
            my @recursive-includes = try |@linked[(state $i += 1)..*]\
                .map(*.dist.metainfo<includes>).flatmap(*.flat);
            my @unique-includes    = |unique(|@direct-includes, |@recursive-includes);
            $candi.dist.metainfo<includes> = |@unique-includes.grep(*.so);
            $candi;
        }
    }
    multi method link-candidates(Bool :$inclusive! where *.so, *@candidates) {
        # :inclusive
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX/lib -I/Bar/YYY/lib -I/Baz/ZZZ/lib
        #   - Bar::YYY -> -I/Foo/XXX/lib -I/Bar/YYY/lib -I/Baz/ZZZ/lib
        #   - Baz::ZZZ -> -I/Foo/XXX/lib -I/Bar/YYY/lib -I/Baz/ZZZ/lib
        my @linked = self.link-candidates(|@candidates);
        @ = @linked.map(*.dist.metainfo<includes>).flatmap(*.flat).unique;
    }
    multi method link-candidates(*@candidates) {
        # Default
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX/lib -I/Bar/YYY/lib
        #   - Bar::YYY -> -I/Bar/YYY/lib -I/Baz/ZZZ/lib
        #   - Baz::ZZZ -> -I/Baz/ZZZ/lib
        @ = @candidates.map: -> $candi {
            my $dist := $candi.dist;

            my @dep-specs = |self.list-dependencies($candi);

            # this could probably be done in the topological-sort itself
            my $includes := eager gather DEPSPEC: for @dep-specs -> $spec {
                for @candidates -> $fcandi {
                    my $fdist := $fcandi.dist;
                    if $fdist.contains-spec($spec) {
                        take $fdist.IO.child('lib').absolute;
                        take $_ for |$fdist.metainfo<includes>.grep(*.so);
                        next DEPSPEC;
                    }
                }
            }
            $dist.metainfo<includes> = $includes.unique.cache;

            $candi;
        }
    }
}

# todo: write a real hooking implementation to CU::R::I
# this is a giant ball of shit btw. workaround on workarounds
sub legacy-hook($candi, :$logger) {
    my $dist := $candi.dist;
    my $DEBUG = ?%*ENV<ZEF_BUILDPM_DEBUG>;

    my $json-ext = $dist.IO.child('META6.json').e;
    my Str $comp-version = ~$*PERL.compiler.version;
    my $meta-name-workaround = $comp-version.substr(5..6) <= 5
                            && $comp-version.substr(0..3) <= 2016
                            && $dist.IO.child('META6.json').e;

    my $orig-result = try-legacy-hook($candi, :$logger);
    my $redo-result = do {
        # Workaround rakudo CUR::FS bug when distribution has a
        # Build.pm file, is using META6.json (not META.info), and
        # the rakudo version is < 2016.05
        # Retries try-legacy-hook after adding 'Build' => 'Build.pm' to provides
        my $meta6-path     = $dist.IO.child('META6.json');
        my $meta6-bak      = $meta6-path.absolute ~ '.bak';
        my $meta6-contents = $meta6-path.IO.slurp;
        try move $meta6-path, $meta6-bak;
        my %meta6 = from-json($meta6-contents);
        %meta6<provides><Build> = 'Build.pm';
        "{$meta6-path}".IO.spurt( to-json(%meta6) );
        my $result = try-legacy-hook($candi, :$logger);
        try unlink $meta6-path;
        try move $meta6-bak, $meta6-path;
        $result;
    } if !$orig-result && $meta-name-workaround;

    return ?$orig-result || ?$redo-result;
}

sub try-legacy-hook($candi, :$logger) {
    my $dist := $candi.dist;
    my $DEBUG = ?%*ENV<ZEF_BUILDPM_DEBUG>;

    my $builder-path = $dist.IO.child('Build.pm');
    my $legacy-code  = $builder-path.IO.slurp;

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    my $needs-panda = ?$legacy-code.contains('use Panda');
    my $reqs-panda  = ?$dist.depends.first(/^[:i 'panda']/)
                    || ?$dist.build-depends.first(/^[:i 'panda']/)
                    || ?$dist.test-depends.first(/^[:i 'panda']/);

    if ?$needs-panda && !$reqs-panda {
        $logger.emit({
            level   => WARN,
            stage   => BUILD,
            phase   => LIVE,
            payload => $candi,
            message => "`build-depends` is missing entries. Attemping to mimick missing dependencies...",
        });

        my $legacy-fixer-code = q:to/END_LEGACY_FIX/;
            class Build {
                method isa($what) {
                    return True if $what.^name eq 'Panda::Builder';
                    callsame;
                }
            END_LEGACY_FIX

        $legacy-code.subst-mutate(/'use Panda::' \w+ ';'/, '', :g);
        $legacy-code.subst-mutate('class Build is Panda::Builder {', "{$legacy-fixer-code}\n");

        try {
            move "{$builder-path}", "{$builder-path}.bak";
            spurt "{$builder-path}", $legacy-code;
        }
    }

    # Rakudo bug related to using path instead of module name
    # my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$dist.IO.absolute}'); exit(0);";
    my $cmd = "::('Build').new.build('{$dist.IO.absolute}'); exit(0);";

    my $result;
    try {
        use Zef::Shell;
        CATCH { default { $result = False; } }
        my @includes = $dist.metainfo<includes>.grep(*.defined).map: { "-I{$_}" }

        # see: https://github.com/ugexe/zef/issues/93
        # my @exec = |($*EXECUTABLE, '-Ilib', '-I.', |@includes, '-e', "$cmd");
        my @exec = |($*EXECUTABLE, '-Ilib', '-I.', '-MBuild', |@includes, '-e', "$cmd");

        $logger.emit({
            level   => DEBUG,
            stage   => BUILD,
            phase   => LIVE,
            payload => $candi,
            message => "Command: {@exec.join(' ')}",
        });

        my $proc = zrun(|@exec, :cwd($dist.path), :out, :err);

        # Build phase can freeze up based on the order of these 2 assignments
        # This is a rakudo bug with an unknown cause, so may still occur based on the process's output
        my @out = $proc.out.lines;
        my @err = $proc.err.lines;

        $ = $proc.out.close unless +@err;
        $ = $proc.err.close;
        $result = ?$proc;

        $logger.emit({
            level   => DEBUG,
            stage   => BUILD,
            phase   => LIVE,
            payload => $candi,
            message => @out.join("\n"),
        }) if +@out;

        $logger.emit({
            level   => ERROR,
            stage   => BUILD,
            phase   => LIVE,
            payload => $candi,
            message => @err.join("\n"),
        }) if +@err;
    }

    if my $bak = "{$builder-path}.bak" and $bak.IO.e {
        try {
            unlink $builder-path;
            move $bak, $builder-path;
        } if $bak.IO.f;
    }

    $ = ?$result;
}
