use Zef;
use Zef::Distribution;
use Zef::Distribution::Local;
use Zef::Distribution::DependencySpecification;
use Zef::Repository;
use Zef::Utils::FileSystem;

use Zef::Fetch;
use Zef::Extract;
use Zef::Build;
use Zef::Test;
use Zef::Install;
use Zef::Report;

class Zef::Client {

    =begin pod

    =title Zef::Client - Task coordinator for raku distribution installation workflows

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef::Client;
        use Zef::Config;

        # Get default config (see resources/config.json for more details on config options)
        my $config-file = Zef::Config::guess-path();
        my $config      = Zef::Config::parse-file($config-file);

        # Create a client
        my $client = Zef::Client.new(:$config);

        # Add some basic logging so there is output to see
        my $logger = $client.logger.Supply;
        $logger.tap: -> $m { say $m.<message> }

        # Use the client to resolve the requested candidates
        my @requested-candidates    = $client.find-candidates('Distribution::Common::Remote');
        my @dependencies-candidates = $client.find-prereq-candidates(|@requested-candidates);
        my @candidates              = |@requested-candidates, |@dependencies-candidates;
        say "Found " ~ @candidates.elems ~ " candidates...";

        # Use the client to fetch/build/test/install candidates to the default raku repository
        my CompUnit::Repository @install-to = CompUnit::RepositoryRegistry.repository-for-name('site');
        $client.make-install(|@candidates, :to(@install-to));
        say "Installed candidates!";

    =end code

    =head1 Description

    A class that coordinates the various stages of a raku distribution installation workflow based on
    various configuration parameters.

    Additionally it provides slightly higher level facilities for fetching, extracting, etc, than the
    e.g. C<Zef::Fetch>, C<Zef::Extract>, etc modules it uses underneath. For example C<Zef::Client.fetch> 
    may run an extraction step unlike C<Zef::Fetch.fetch>, since the former is in the context of a distribution
    (i.e. we want the distribution at the specific commit/tag, not the HEAD immediately after fetching)

    =end pod

    #| Where zef will cache index databases (p6c.json, etc) and distributions
    has IO::Path $.cache;

    #| Repository abstraction used to query for distributions
    has Zef::Repository $.recommendation-manager; # todo: rename this?

    #| Fetcher abstraction used to fetch distributions, ecosystem databases, etc
    has Zef::Fetch $.fetcher;

    #| Extractor abstraction used to e.g. extract or checkout data sources
    has Zef::Extract $.extractor;

    #| Builder abstraction used to handle running the build phase of a distribution
    has Zef::Build $.builder;

    #| Tester abstraction used to handle running the test phase of a distribution
    has Zef::Test $.tester;

    #| Installer abstraction used to handle the install phase of a distribution
    #| (we theoretically could install Perl modules with an adapter for instance)
    has Zef::Install $.installer;

    #| Reporter abstraction to to handle the report phase of a distribution
    has Zef::Report $.reporter;

    #| The config data (see resources/config.json)
    has %.config;

    #| Supplier where logging events originate
    #| For example to get 'test' related event you might use:
    #|    $client.logger.Supply.grep({ .<phase> eq "TEST" })
    has Supplier $.logger = Supplier.new;

    #| Internal use store for keeping track of module names to skip
    has @!ignore;

    #
    # NOTE: All attributes below this point have CLI equivalents 
    #

    #| User supplied module names that will be skipped
    #| For example to skip a native perl dependency like perl:from<bin>:
    #|    :exclude("perl");
    #| or from the command line:
    #|    --exclude=perl
    has @.exclude;

    #| Continue resolving dependencies even if there is an error in doing so
    has Bool $.force-resolve is rw = False;

    #| Continue fetching dependencies even if there is an error in doing so
    #| (I don't think there isn't a good reason to ever set this to True)
    has Bool $.force-fetch is rw = False;

    #| Continue extracting dependencies even if there is an error in doing so
    #| (I don't think there isn't a good reason to ever set this to True)
    has Bool $.force-extract is rw = False;

    #| Continue building dependencies even if there is an error in doing so
    has Bool $.force-build is rw = False;

    #| Continue testing dependencies even if there is an error in doing so
    has Bool $.force-test is rw = False;

    #| Continue installing dependencies even if there is an error in doing so
    has Bool $.force-install is rw = False;

    #| The max number of items to fetch concurrently
    has Int $.fetch-degree   is rw = 1;

    #| The max number of distributions to test concurrently
    has Int $.test-degree    is rw = 1;

    #| The number of seconds to wait before aborting a fetching task
    has Int $.fetch-timeout   is rw = 600;

    #| The number of seconds to wait before aborting a extracting task
    has Int $.extract-timeout is rw = 3600;

    #| The number of seconds to wait before aborting a building task
    has Int $.build-timeout   is rw = 3600;

    #| The number of seconds to wait before aborting a testing task
    has Int $.test-timeout    is rw = 3600;

    #| The number of seconds to wait before aborting a installing task
    has Int $.install-timeout is rw = 3600;

    #| If run time dependencies should be considered when processing distributions
    has Bool $.depends is rw = True;

    #| If build time dependencies should be considered when building distributions
    has Bool $.build-depends is rw = True;

    #| If test time dependencies should be considered when building distributions
    has Bool $.test-depends is rw = True;

    submethod TWEAK(
        :$!cache                  = %!config<StoreDir>.IO,
        :$!fetcher                = Zef::Fetch.new(:backends(|%!config<Fetch>)),
        :$!extractor              = Zef::Extract.new(:backends(|%!config<Extract>)),
        :$!builder                = Zef::Build.new(:backends(|%!config<Build>)),
        :$!installer              = Zef::Install.new(:backends(|%!config<Install>)),
        :$!tester                 = Zef::Test.new(:backends(|%!config<Test>)),
        :$!reporter               = Zef::Report.new(:backends(|%!config<Report>)),
        :$!recommendation-manager = Zef::Repository.new(:backends(%!config<Repository>.map({ $_<options><cache> //= $!cache; $_<options><fetcher> = $!fetcher; $_ }).Slip)),
    ) {
        mkdir $!cache unless $!cache.IO.e;

        # Ignore CORE modules to speed up searches and to avoid dual-life issues until CORE is more strictly versioned
        @!ignore = CompUnit::RepositoryRegistry
                    .repository-for-name('core')
                    .candidates('CORE')
                    .map(*.meta<provides>.keys.Slip)
                    .unique
                    .map({ Zef::Distribution::DependencySpecification.new($_) })
        ;
    }

    #| Return a matching candidate/distributino for each supplied identity
    method find-candidates(Bool :$upgrade, *@identities ($, *@)) {
        self.logger.emit({
            level   => INFO,
            stage   => RESOLVE,
            phase   => BEFORE,
            message => "Searching for: {@identities.join(', ')}",
        });

        my @candidates = self!find-candidates(:$upgrade, @identities);

        for @candidates.classify({.from}).kv -> $from, $found {
            self.logger.emit({
                level   => VERBOSE,
                stage   => RESOLVE,
                phase   => AFTER,
                message => "Found: {$found.map(*.dist.identity).join(', ')} [via {$from}]",
            })
        }

        return @candidates;
    }

    #| Similar to self.find-candidates, but this can be called recursively. Notably
    #| it allows the message for the call to .find-candidates(...) to differentiate
    #| between later calls to .find-prereq-candidates(...) (which calls !find-candidates
    #| so it doesn't send the aforementioned logging message for a top level request).
    method !find-candidates(Bool :$upgrade, *@identities ($, *@)) {
        my $candidates := $!recommendation-manager.candidates(@identities, :$upgrade)\
            .grep(-> $candi { not @!exclude.first({$candi.dist.contains-spec($_)}) })\
            .grep(-> $candi { not @!ignore.first({$candi.dist.contains-spec($_)}) })\
            .unique(:as(*.dist.identity));
    }

    #| Return matching candidates that fulfill the dependencies (including transitive) for each supplied candidate/distribution
    method find-prereq-candidates(Bool :$skip-installed = True, Bool :$upgrade, :@certain, *@candis ($, *@)) {
        my @skip = @candis.map(*.dist);

        my $prereqs := gather {
            my @specs = self.list-dependencies(@candis);

            while @specs.splice -> @specs-batch {
                self.logger.emit({
                    level   => DEBUG,
                    stage   => RESOLVE,
                    phase   => BEFORE,
                    message => "Dependencies: {@specs-batch.map(*.name).unique.join(', ')}",
                });

                next unless my @needed = @specs-batch\               # The current set of specs
                    .grep({ not @skip.first(*.contains-spec($_)) })\ # Dists in @skip are not needed
                    .grep(-> $spec { not @!exclude.first({ $_.spec-matcher($spec) }) })\
                    .grep(-> $spec { not @!ignore.first({ $_.spec-matcher($spec) }) })\
                    .grep({ $skip-installed ?? self.is-installed($_).not !! True });

                my %needed = @needed.classify: {
                    $_.isa(Zef::Distribution::DependencySpecification::Any)
                        ?? "alternative"
                        !! "certain"
                };

                my @identities = %needed<certain>.map(*.identity) if %needed<certain>;
                self.logger.emit({
                    level   => INFO,
                    stage   => RESOLVE,
                    phase   => BEFORE,
                    message => "Searching for missing dependencies: {@needed.map(*.identity).join(', ')}",
                });
                my @prereq-candidates = self!find-candidates(:$upgrade, @identities) if @identities;

                @identities = gather for %needed<alternative>.list -> $needed {
                    next if any(|@certain, |@prereq-candidates).dist.contains-spec($needed);

                    my @candidates;
                    if $needed.specs.first({
                            @candidates = self!find-candidates(:$upgrade, $_.identity);
                            @candidates.append: self.find-prereq-candidates(
                                :$upgrade,
                                :certain(|@certain, |@prereq-candidates),
                                @candidates,
                            ) if @candidates;
                            CATCH {
                                when X::Zef::UnsatisfiableDependency { @candidates = (); }
                            }
                            @candidates
                        })
                    -> $spec {
                        @prereq-candidates.append(@candidates);
                    }
                    else {
                        take $needed.identity;
                    }
                } if %needed<alternative>;
                @prereq-candidates.append: self!find-candidates(:$upgrade, @identities) if @identities;

                my $not-found := @needed.grep({ not @prereq-candidates.first(*.dist.contains-spec($_)) }).map(*.identity);

                # The failing part of this should ideally be handled in Zef::CLI I think
                if +@prereq-candidates == +@needed || $not-found.cache.elems == 0 {
                    for @prereq-candidates.classify({.from}).kv -> $from, $found {
                        self.logger.emit({
                            level   => VERBOSE,
                            stage   => RESOLVE,
                            phase   => AFTER,
                            message => "Found dependencies: {$found.map(*.dist.identity).join(', ')} [via {$from}]",
                        })
                    }
                }
                else {
                    self.logger.emit({
                        level   => ERROR,
                        stage   => RESOLVE,
                        phase   => AFTER,
                        message => "Failed to find dependencies: {$not-found.join(', ')}",
                    });

                    $!force-resolve
                        ??  $!logger.emit({
                                level   => ERROR,
                                stage   => RESOLVE,
                                phase   => LIVE,
                                message => 'Failed to resolve missing dependencies, but continuing with --force-resolve',
                            })
                        !! die X::Zef::UnsatisfiableDependency.new;
                };

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
        my @fetched   = self!fetch(@candidates);
        my @extracted = self!extract(@candidates);

        my @local-candis = @extracted.map: -> $candi {
            my $dist = Zef::Distribution::Local.new(~$candi.uri);
            $candi.clone(:$dist);
        }

        $!recommendation-manager.store(@local-candis.map(*.dist));

        @local-candis;
    }
    method !fetch(*@candidates ($, *@)) {
        my $dispatcher := $*PERL.compiler.version < v2018.08
            ?? @candidates
            !! @candidates.hyper(:batch(1), :degree($!fetch-degree || 5));

        my @fetched = $dispatcher.map: -> $candi {
            self.logger.emit({
                level   => DEBUG,
                stage   => FETCH,
                phase   => BEFORE,
                message => "Fetching: {$candi.as}",
            });
            die "Cannot determine a uri to fetch {$candi.as} from. Perhaps it's META6.json is missing an e.g. source-url"
                unless $candi.uri;

            my $tmp      = %!config<TempDir>.IO.child("{time}.{$*PID}.{(^10000).rand}");
            my $stage-at = $tmp.child($candi.uri.IO.basename);
            die "failed to create directory: {$tmp.absolute}"
                unless ($tmp.IO.e || mkdir($tmp));

            # $candi.uri will always point to where $candi.dist should be copied from.
            # It could be a file or url; $dist.source-url contains where the source was
            # originally located but we may want to use a local copy (while retaining
            # the original source-url for some other purpose like updating)
            my $save-to    = $!fetcher.fetch($candi, $stage-at, :$!logger, :timeout($!fetch-timeout));
            my $relpath    = $stage-at.relative($tmp);
            my $extract-to = $!cache.IO.child($relpath);

            if !$save-to {
                self.logger.emit({
                    level   => ERROR,
                    stage   => FETCH,
                    phase   => AFTER,
                    message => "Fetching [FAIL]: {$candi.dist.?identity // $candi.as} from {$candi.uri}",
                });

                $!force-fetch
                    ??  $!logger.emit({
                            level   => ERROR,
                            stage   => FETCH,
                            phase   => LIVE,
                            candi   => $candi,
                            message => 'Failed to fetch, but continuing with --force-fetch',
                        })
                    !! die("Aborting due to fetch failure: {$candi.dist.?identity // $candi.uri} (use --force-fetch to override)");
            }
            else {
                self.logger.emit({
                    level   => VERBOSE,
                    stage   => FETCH,
                    phase   => AFTER,
                    message => "Fetching [OK]: {$candi.dist.?identity // $candi.as} to $save-to",
                });
            }

            $candi.uri = $save-to;

            $candi;
        };

        return @fetched;
    }
    method !extract(*@candidates ($, *@)) {
        my @extracted = eager gather for @candidates -> $candi {
            self.logger.emit({
                level   => DEBUG,
                stage   => EXTRACT,
                phase   => BEFORE,
                message => "Extracting: {$candi.as}",
            });

            my $tmp        = $candi.uri.parent;
            my $stage-at   = $candi.uri;
            my $relpath    = $stage-at.relative($tmp);
            my $extract-to = $!cache.IO.child($relpath);
            die "failed to create directory: {$tmp.absolute}"
                unless ($tmp.IO.e || mkdir($tmp));

            my $meta6-prefix = '' R// $!extractor.ls-files($candi).sort.first({ .IO.basename eq 'META6.json' });

            self.logger.emit({
                level   => WARN,
                stage   => EXTRACT,
                phase   => BEFORE,
                message => "Extraction: Failed to find a META6.json file for {$candi.dist.?identity // $candi.as} -- failure is likely",
            }) unless $meta6-prefix;

            my $extracted-to = $!extractor.extract($candi, $extract-to, :$!logger, :timeout($!extract-timeout));

            if !$extracted-to {
                self.logger.emit({
                    level   => ERROR,
                    stage   => EXTRACT,
                    phase   => AFTER,
                    message => "Extraction [FAIL]: {$candi.dist.?identity // $candi.as} from {$candi.uri}",
                });

                $!force-extract
                    ??  $!logger.emit({
                            level   => ERROR,
                            stage   => EXTRACT,
                            phase   => LIVE,
                            candi   => $candi,
                            message => 'Failed to extract, but continuing with --force-extract',
                        })
                    !! die("Aborting due to extract failure: {$candi.dist.?identity // $candi.uri} (use --force-extract to override)");
            }
            else {
                try { delete-paths($tmp) }

                # Remove this when META.info support can finally be removed
                if !$meta6-prefix and my $meta-info = $extracted-to.IO.add('META.info') and $meta-info.e {
                    self.logger.emit({
                        level   => WARN,
                        stage   => EXTRACT,
                        phase   => AFTER,
                        message => "Extraction: Failed to find a META6.json file for {$candi.dist.?identity // $candi.as} -- creating it from deprecated META.info file",
                    });

                    try { $meta-info.copy($meta-info.parent.add('META6.json')) }
                }

                self.logger.emit({
                    level   => VERBOSE,
                    stage   => EXTRACT,
                    phase   => AFTER,
                    message => "Extraction [OK]: {$candi.as} to {$extract-to}",
                });
            }

            $candi.uri = $extracted-to.child($meta6-prefix);
            take $candi;
        }
    }


    # xxx: needs some love. also an entire specification
    method build(*@candidates ($, *@)) {
        my @built = eager gather for @candidates -> $candi {
            my $dist := $candi.dist;

            unless $!builder.build-matcher($dist) {
                self.logger.emit({
                    level   => DEBUG,
                    stage   => BUILD,
                    phase   => BEFORE,
                    message => "# SKIP: No need to build {$candi.dist.?identity // $candi.as}",
                });
                take $candi;
                next();
            }

            $!logger.emit({
                level   => INFO,
                stage   => BUILD,
                phase   => BEFORE,
                message => "Building: {$candi.dist.?identity // $candi.as}",
            });

            my $result := $!builder.build($candi, :includes($candi.dist.metainfo<includes> // []), :$!logger, :timeout($!build-timeout)).cache;

            $candi.build-results = $result;

            if $result.grep(*.not).elems {
                self.logger.emit({
                    level   => ERROR,
                    stage   => BUILD,
                    phase   => AFTER,
                    message => "Building [FAIL]: {$candi.dist.?identity // $candi.as}",
                });

                $!force-build
                    ??  $!logger.emit({
                            level   => ERROR,
                            stage   => BUILD,
                            phase   => LIVE,
                            candi   => $candi,
                            message => 'Failed to build, but continuing with --force-build',
                        })
                    !! die("Aborting due to build failure: {$candi.dist.?identity // $candi.uri} (use --force-build to override)");
            }
            else {
                self.logger.emit({
                    level   => INFO,
                    stage   => BUILD,
                    phase   => AFTER,
                    message => "Building [OK] for {$candi.dist.?identity // $candi.as}",
                });
            }

            take $candi;
        }

        @built
    }

    # xxx: needs some love
    method test(:@includes, *@candidates ($, *@)) {
        my $dispatcher := $*PERL.compiler.version < v2018.08
            ?? @candidates
            !! @candidates.hyper(:batch(1), :degree($!test-degree || 1));

        my @tested = $dispatcher.map: -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => TEST,
                phase   => BEFORE,
                message => "Testing: {$candi.dist.?identity // $candi.as}",
            });

            my $result := $!tester.test($candi, :includes($candi.dist.metainfo<includes> // []), :$!logger, :timeout($!test-timeout)).cache;

            $candi.test-results = $result;

            if $result.grep(*.not).elems {
                self.logger.emit({
                    level   => ERROR,
                    stage   => TEST,
                    phase   => AFTER,
                    message => "Testing [FAIL]: {$candi.dist.?identity // $candi.as}",
                });

                $!force-test
                    ??  $!logger.emit({
                            level   => ERROR,
                            stage   => TEST,
                            phase   => LIVE,
                            candi   => $candi,
                            message => 'Failed to get passing tests, but continuing with --force-test',
                        })
                    !! die("Aborting due to test failure: {$candi.dist.?identity // $candi.uri} (use --force-test to override)");
            }
            else {
                self.logger.emit({
                    level   => INFO,
                    stage   => TEST,
                    phase   => AFTER,
                    message => "Testing [OK] for {$candi.dist.?identity // $candi.as}",
                });
            }

            $candi;
        }

        return @tested
    }

    #| Search for identities from the various repository backends and returns the matching distributions
    method search(*@identities ($, *@), *%fields, Bool :$strict = False) {
        $!recommendation-manager.search(@identities, :$strict, |%fields);
    }

    #| Uninstall a distribution from a given repository
    method uninstall(CompUnit::Repository :@from!, *@identities) {
        my @specs = @identities.map: { Zef::Distribution::DependencySpecification.new($_) }
        eager gather for self.list-installed(@from) -> $candi {
            my $dist = $candi.dist;
            if @specs.first({ $dist.spec-matcher($_) }) {
                my $cur = CompUnit::RepositoryRegistry.repository-for-spec("inst#{$candi.from}", :next-repo($*REPO));
                $cur.uninstall($dist.compat);
                take $candi;
            }
        }
    }

    #| Install a distribution to a given repository
    method install(:@curs, *@candidates ($, *@)) {
        my @installed = eager gather for @candidates -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => INSTALL,
                phase   => BEFORE,
                message => "Installing: {$candi.dist.?identity // $candi.as}",
            });

            for @curs -> $cur {
                KEEP self.logger.emit({
                    level   => VERBOSE,
                    stage   => INSTALL,
                    phase   => AFTER,
                    message => "Install [OK] for {$candi.dist.?identity // $candi.as}",
                });

                CATCH {
                    when /'already installed'/ {
                        self.logger.emit({
                            level   => INFO,
                            stage   => INSTALL,
                            phase   => AFTER,
                            message => "Install [SKIP] for {$candi.dist.?identity // $candi.as}: {$_}",
                        });
                    }
                    default {
                        self.logger.emit({
                            level   => ERROR,
                            stage   => INSTALL,
                            phase   => AFTER,
                            message => "Install [FAIL] for {$candi.dist.?identity // $candi.as}: {$_}",
                        });
                        $_.rethrow;
                    }
                }

                # Previously we put this through the deprecation CURI.install shim no matter what,
                # but that doesn't play nicely with relative paths. We want to keep the original meta
                # paths for newer rakudos so we must avoid using :absolute for the source paths by
                # using the newer CURI.install if available
                take $candi if $!installer.install($candi, :$cur, :force($!force-install), :timeout($!install-timeout));
            }
        }

        return @installed;
    }

    #| This organizes and executes multiples phases for multiples candidates (test/build/install/etc)
    method make-install(
        CompUnit::Repository :@to!, # target CompUnit::Repository
        Bool :$fetch = True,        # try fetching whats missing
        Bool :$build = True,        # run Build.pm (DEPRECATED..?)
        Bool :$test  = True,        # run tests
        Bool :$dry,                 # do everything *but* actually install
        Bool :$upgrade,             # NYI
        Bool :$serial,
        *@candidates ($, *@),
        *%_
    ) {
        my @curs = @to.grep: -> $cur {
            UNDO {
                self.logger.emit({
                    level   => WARN,
                    stage   => INSTALL,
                    phase   => BEFORE,
                    message => "CompUnit::Repository install target is not writeable/installable: {$cur}"
                });
            }
            KEEP {
                self.logger.emit({
                    level   => TRACE,
                    stage   => INSTALL,
                    phase   => BEFORE,
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
        # Use the results from searching Repositorys and download/fetch the distributions they point at
        my @fetched-candidates = eager gather for @candidates -> $store {
            # Note that this method of not fetching Zef::Distribution::Local means we cannot
            # show fetching messages that would be fired in self.fetch(|) ( such as the download uri ).
            # The reason it doesn't just fetch regardless is because it avoids caching local dev dists
            # ala `zef install .` from polluting the name/auth/api/ver namespace of the local cache.
            # TODO: Find a solution for the issues noted above which will resolve GH#261 "zef install should tell user where the install was from"
            take $_ for ($store.dist.^name.contains('Zef::Distribution::Local') || !$fetch) ?? $store !! self.fetch($store, |%_);
        }
        die "Failed to fetch any candidates. No reason to proceed" unless +@fetched-candidates;

        # Filter Stage:
        # Handle stuff like removing distributions that are already installed, that don't have
        # an allowable license, etc. It faces the same "fetch an alternative if available on failure"
        # problem outlined below under `Sort Phase` (a depends on [A, B] where A gets filtered out
        # below because it has the wrong license means we don't need anything that depends on A but
        # *do* need to replace those items with things depended on by B [which replaces A])
        my @filtered-candidates = @fetched-candidates.grep: -> $candi {
            my $*error;
            self.logger.emit({
                level   => DEBUG,
                stage   => FILTER,
                phase   => BEFORE,
                message => "Filtering: {$candi.dist.identity}",
            });
            KEEP $!logger.emit({
                level   => DEBUG,
                stage   => FILTER,
                phase   => AFTER,
                message => "Filtering [OK] for {$candi.dist.?identity // $candi.as}",
            });
            UNDO $!logger.emit({
                level   => ERROR,
                stage   => FILTER,
                phase   => AFTER,
                message => "Filtering [FAIL] for {$candi.dist.?identity // $candi.as}: {$*error}",
            });

            $*error = do given %!config<License> {
                when .<blacklist>.?chars && any(|.<blacklist>) ~~ any('*', $candi.dist.meta<license> // '') {
                    "License blacklist configuration exists and matches {$candi.dist.meta<license> // 'n/a'} for {$candi.dist.name}";
                }
                when .<whitelist>.?chars && any(|.<whitelist>) ~~ none('*', $candi.dist.meta<license> // '') {
                    "License whitelist configuration exists and does not match {$candi.dist.meta<license> // 'n/a'} for {$candi.dist.name}";
                }
            }

            $*error.?chars;
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
        my @linked-candidates = self.link-candidates(@sorted-candidates);
        die "Something went terribly wrong linking the distributions" unless +@linked-candidates;


        my $installer = sub (*@_) {
            # Build Phase:
            my @built-candidates = ?$build ?? self.build(@_) !! @_;
            die "No installable candidates remain after `build` failures" unless +@built-candidates;


            # Test Phase:
            my @tested-candidates = !$test
                ?? @built-candidates
                !! self.test(@built-candidates).grep({ $!force-test || .test-results.grep(!*.so).elems == 0 });

            # actually we *do* want to proceed here later so that the Report phase can know about the failed tests/build
            die "All candidates failed building and/or testing. No reason to proceed" unless +@tested-candidates;

            # Install Phase:
            # Ideally `--dry` uses a special unique CompUnit::Repository that is meant to be deleted entirely
            # and contain only the modules needed for this specific run/plan
            my @installed-candidates = ?$dry ?? @tested-candidates !! self.install(:@curs, @tested-candidates);

            # Report phase:
            # Handle exit codes for various option permutations like --force
            # Inform user of what was tested/built/installed and what failed
            # Optionally report to any cpan testers type service (testers.perl6.org)
            unless $dry {
                if @installed-candidates.map(*.dist).flatmap(*.scripts.keys).unique -> @bins {
                    my $msg = "\n{+@bins} bin/ script{+@bins>1??'s'!!''}{+@bins??' ['~@bins~']'!!''} installed to:"
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
        } # sub installer

        my @installed = ?$serial ?? @linked-candidates.map({ |$installer($_) }) !! $installer(@linked-candidates);
    }

    #| Return distributions that depend on the given identity
    method list-rev-depends($identity, Bool :$indirect) {
        my $spec  = Zef::Distribution::DependencySpecification.new($identity);
        my $dist  = self.list-available.first(*.dist.contains-spec($spec)).?dist || return [];

        my $rev-deps := gather for self.list-available -> $candi {
            my $specs := self.list-dependencies($candi);

            take $candi if $specs.first({ $dist.contains-spec($_, :strict) });
        }
        $rev-deps.unique(:as(*.dist.identity));
    }

    #| Return all distributions from all repositories
    method list-available(*@recommendation-manager-names) {
        my $available := $!recommendation-manager.available(@recommendation-manager-names);
    }

    #| Return all distributions in known CompUnit::Repository::Installation repositories
    method list-installed(*@curis) {
        my @curs       = +@curis ?? @curis !! $*REPO.repo-chain.grep(*.?prefix.?e);
        my @repo-dirs  = @curs.map({.?prefix // .path-spec.?path}).map(*.IO); #.path-spec.?path is for CUR::Unknown
        my @dist-dirs  = @repo-dirs.map(*.child('dist')).grep(*.e);
        my @dist-files = @dist-dirs.map(*.IO.dir.grep(*.IO.f).Slip);

        my $dists := gather for @dist-files -> $file {
            if try { Zef::Distribution.new( |%(from-json($file.IO.slurp)) ) } -> $dist {
                my $cur = @curs.first: {.prefix eq $file.parent.parent}
                take Candidate.new( :$dist, :from($cur), :uri($file) );
            }
        }
    }

    method list-leaves {
        my @installed = self.list-installed;
        my @dep-specs = self.list-dependencies(@installed);

        my $leaves := gather for @installed -> $candi {
            my $dist := $candi.dist;
            take $candi unless @dep-specs.first: { $dist.contains-spec($_) }
        }
    }

    #| Return distributions that are direct dependencies of the supplied distributions
    method list-dependencies(*@candis, :$from) {
        my $deps := gather for @candis -> $candi {
            take $_ for grep *.defined,
                ($candi.dist.depends-specs       if ?$!depends).Slip,
                ($candi.dist.test-depends-specs  if ?$!test-depends).Slip,
                ($candi.dist.build-depends-specs if ?$!build-depends).Slip;
        }

        # if .name is not defined then its invalid but probably a deeply nested
        # depends hash so just ignore it since it might be valid in the near future.
        $deps.unique(:as(*.identity));
    }

    #| Returns the best matching distributions from installed sources, in preferred order, similar to $*REPO.resolve
    method resolve($spec, :@at) {
        my $candis := self.list-installed(@at).grep(*.dist.contains-spec($spec));
        $candis.sort(*.dist.ver).sort(*.dist.api).reverse;
    }

    #| Return true of one-or-more of the requested dependencies are already installed
    multi method is-installed(Zef::Distribution::DependencySpecification::Any $spec, |c) {
        self.is-installed(any($spec.specs, |c))
    }

    #| Return true if the requested dependency is already installed
    multi method is-installed($spec, |c) {
        do given $spec.?from-matcher {
            when 'bin'    { so Zef::Utils::FileSystem::which($spec.name) }
            when 'native' { so self!native-library-is-installed($spec) }
            default       { so self.resolve($spec, |c).so }
        }
    }

    #| Return true of a native library can be seen by NativeCall
    method !native-library-is-installed($spec --> Bool) {
        use MONKEY-SEE-NO-EVAL;
        my $lib = "'$spec.name()'";
        $lib = "$lib, v$spec.ver()" if $spec.ver;
        try {
            EVAL qq[use NativeCall; sub native_library_is_installed is native($lib) \{ !!! \}; native_library_is_installed(); ];
            CATCH { default { return False if .payload.starts-with("Cannot locate native library") } }
        }
        return True;
    }

    #| Toplogical sort used to determine which dependency can be processed next in a given phase
    method sort-candidates(@candis, *%_) {
        my @tree;
        my $visit = sub ($candi, $from? = '') {
            return if ($candi.dist.metainfo<marked> // 0) == 1;
            if ($candi.dist.metainfo<marked> // 0) == 0 {
                $candi.dist.metainfo<marked> = 1;

                my @deps = |self.list-dependencies($candi);

                for @deps -> $m {
                    for @candis.grep(*.dist.contains-spec($m)) -> $m2 {
                        $visit($m2, $candi);
                    }
                }
                @tree.append($candi);
            }
        };

        for @candis -> $candi {
            $visit($candi, 'olaf') if ($candi.dist.metainfo<marked> // 0) == 0;
        }

        .dist.metainfo<marked> = Nil for @tree;
        return @tree;
    }

    #| Adds appropriate include (-I / PERL6LIB) paths for dependencies
    proto method link-candidates(|) {*}
    multi method link-candidates(Bool :$recursive! where *.so, *@candidates) {
        # :recursive
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        #   - Bar::YYY -> -I/Bar/YYY -I/Baz/ZZZ
        #   - Baz::ZZZ -> -I/Baz/ZZZ

        # XXX: Need to change this so it only add indirect dependencies
        # instead of just recursing the array in order. Otherwise there
        # can be distributions that are part of a different dependency
        # chain will end up with some extra includes

        my @linked = self.link-candidates(@candidates);
        @ = @linked.map: -> $candi { # can probably use rotor instead of doing the `@a[$index + 1..*]` dance
            my @direct-includes    = $candi.dist.metainfo<includes>.grep(*.so);
            my @recursive-includes = try @linked[(state $i += 1)..*]\
                .map(*.dist.metainfo<includes>).flatmap(*.flat);
            my @unique-includes    = unique(@direct-includes, @recursive-includes);
            my Str @results        = @unique-includes.grep(*.so);
            $candi.dist.metainfo<includes> = @results;
            $candi;
        }
    }
    multi method link-candidates(Bool :$inclusive! where *.so, *@candidates) {
        # :inclusive
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        #   - Bar::YYY -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        #   - Baz::ZZZ -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        my @linked = self.link-candidates(@candidates);
        @ = @linked.map(*.dist.metainfo<includes>).flatmap(*.flat).unique;
    }
    multi method link-candidates(*@candidates) {
        # Default
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX -I/Bar/YYY
        #   - Bar::YYY -> -I/Bar/YYY -I/Baz/ZZZ
        #   - Baz::ZZZ -> -I/Baz/ZZZ
        @ = @candidates.map: -> $candi {
            my $dist := $candi.dist;

            my @dep-specs = |self.list-dependencies($candi);

            # this could probably be done in the topological-sort itself
            my $includes := eager gather DEPSPEC: for @dep-specs -> $spec {
                for @candidates -> $fcandi {
                    my $fdist := $fcandi.dist;
                    if $fdist.contains-spec($spec) {
                        take $fdist.IO.absolute;
                        take $_ for |$fdist.metainfo<includes>.grep(*.so);
                        next DEPSPEC;
                    }
                }
            }

            my Str @results = $includes.unique;
            $candi.dist.metainfo<includes> = @results;

            $candi;
        }
    }
}

