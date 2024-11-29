use Zef:ver($?DISTRIBUTION.meta<version> // $?DISTRIBUTION.meta<ver>// '*'):api($?DISTRIBUTION.meta<api> // '*'):auth($?DISTRIBUTION.meta<auth> // '');
use Zef::Distribution:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Distribution::Local:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Distribution::DependencySpecification:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Repository:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Utils::FileSystem:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Fetch:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Extract:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Build:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Test:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Install:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Report:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);

class Zef::Client {

    =begin pod

    =title class Zef::Client

    =subtitle Task coordinator for raku distribution installation workflows

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
    (i.e. we want the distribution at the specific commit/tag, not the HEAD immediately after fetching).

    =head1 Methods

    =head2 method find-candidates

        method find-candidates(*@identities ($, *@) --> Array[Candidate])

    Searches all repositories via C<Zef::Repository> and returns a matching C<Candidate> / distribution for each supplied
    identity. Generally this is used to find the top level distributions requested, such as C<Foo> in C<zef install Foo>.

    =head2 method find-candidates

        method find-prereq-candidates(Bool :$skip-installed = True, *@candis ($, *@) --> Array[Candidate])

    Similar to C<method find-candidates> but returns matching a matching C<Candidate> for each dependency of the supplied
    identities. Generally this is used to recursively discover and determine the dependencies of the identities requested.
    If C<$skip-installed> is set to C<False> it will potentially install a newer version of an already installed matching
    dependency (without uninstalling the previous version). It also skips any identity matching of C<@.ignore>, which allows
    getting past an unresolvable dependency ala `zef install Inline::Perl5 --ignore="perl"`.

    Returns an C<Array> of C<Candidate> that fulfill the dependency requirements of C<@identities>.

    =head2 method search

        method search(*@identities ($, *@), *%fields, Bool :$strict = False --> Array[Candidate])

    Resolves each identity in C<@identities> to all of its matching C<Candidates> from all backends via C<Zef::Repository> (with C<$max-results>
    applying to each individual backend). If C<$strict> is C<False> then it will consider partial matches on module short-names (i.e. 'zef search HTTP'
    will get results for e.g. C<HTTP::UserAgent>).

    =head2 method fetch

        method fetch(*@candidates ($, *@) --> Array[Candidate])

    Fetches a distribution from some location, and unpacks/extracts it to a temporary location to be used be cached, tested,
    installed, etc. It effective combines the functionality of C<Zef::Fetch.fetch> and C<Zef::Extract.extract> into a single
    method as there isn't yet a useful reason to have workflows that work with compressed archives/packages. Fetches up to
    C<$.fetch-degree> different C<@candidates> in parallel.

    Anytime a distribution is fetched it will call C<.store(@distributions)> on any C<Zef::Repository> that supports it (usually
    just C<Zef::Repository::LocalCache>).

    File are saved to the C<TempDir> setting in C<resources/config.json>, and extracted to the C<$.cache> directory (the C<StoreDir>
    setting in C<resources/config.json>).

    Returns an C<Array> of C<Candidate> containing the successfully fetched results.

    =head2 method build

        method build(*@candidates ($, *@) --> Array[Candidate])

    Runs the build process on each C<@candidates> that the backends for C<Zef::Build> know how to process. Builds up to C<$.build-degree>
    different C<@candidates> in parallel.

    Returns an C<Array> of C<Candidate> with each C<.build-results> set appropriately.

    =head2 method test

        method test(*@candidates ($, *@) --> Array[Candidate])

    Runs the test process on each C<@candidates> via the backends of C<Zef::Test>. Tests up to C<$.test-degree> different
    C<@candidates> in parallel.

    Returns an C<Array> of C<Candidate> with each C<.test-results> set appropriately.

    =head2 method uninstall

        method uninstall(CompUnit::Repository :@from!, *@identities --> Array[Candidate])

    Searches each C<CompUnit::Repository> in C<@from> for each C<@identities> and uninstalls any matching distributions.
    For instance uninstalling C<zef> could potentially uninstall multiple versions, whereas uninstall C<zef:ver("0.9.4")> would
    only uninstall that specific version.

    Returns an C<Array> containing each uninstalled C<Candidate>.

    =head2 method install

        method install(:@curs, *@candidates ($, *@) --> Array[Candidate])

    Install a C<Candidate> containing a C<Distribution> to each C<CompUnit::Repository> in C<@curs>.

    Returns an C<Array> containing each successfully installed C<Candidate>.

    =head2 method make-install

        method make-install(CompUnit::Repository :@to!, Bool :$fetch = True, Bool :$build = True, Bool :$test  = True, Bool :$dry, Bool :$serial, *@candidates ($, *@), *%_)

    The 'do everything but resolve dependencies' method. You essentially figure out all the C<Candidate> you need to install
    (dependencies, etc) and pass them to this method. Its similar to C<method install> except it also handles calling C<method fetch>
    (if C<$fetch> is C<True>), C<method build> (if C<$build> is C<True>), and C<method test> (if <$test> is C<True>). If C<$dry> is
    C<True> then the final step of calling C<method install> (which moves the modules to where C<raku> will see them) will be skipped.
    If <$serial> is C<True> then each C<Candidate> will be installed after it passes its own tests (instead of the default behavior of
    only installing if all C<Candidate>, including dependencies, pass their tests).

    =head2 method list-rev-depends

        method list-rev-depends($identity, Bool :$indirect --> Array[Candidate])

    Return an C<Array> of C<Candidate> of all distribution that directly depend on C<$identity>. If C<$indirect> is C<True> then it
    additionally returns distributions that indirectly / transitively depend on C<$identity>

    =head2 method list-available

        method list-available(*@recommendation-manager-names --> Array[Candidate])

    Returns an C<Array> of C<Candidate> for every distribution from every repository / recommendation-manager with a name (as
    set in C<resources/config.json>) matching any of those in C<@recommendation-manager-names> (or all repositories if no names
    are supplied). Note some non-standard repositories may not support listing all available distributions.

    =head2 method list-installed

        method list-installed(*@curis --> Array[Candidate])

    Returns an C<Array> of C<Candidate> for each Raku distribution installed to each C<CompUnit::Repository::Installation> C<@curis>
    (or all known C<CompUnit::Repository::Installation> if no C<@curis> are supplied).

    =head2 method list-leaves

        method list-leaves(--> Array[Candidate])

    Returns an C<Array> of C<Candidate> for each installed distributions that nothing else appears to depend on. 

    =head2 method list-dependencies

        method list-dependencies(*@candis --> Array[DependencySpecification])

    Returns an C<Array> of C<Zef::Distribution::DependencySpecification> and // or C<Zef::Distribution::DependencySpecification::Any>
    for each C<@candis> distributions various dependency requirements.

    If C<$.depends> is set to C<False> then runtime dependencies will be ignored.
    If C<$.test-depends> is set to C<False> then test dependencies will be ignored.
    If C<$.build-depends> is set to C<False> then build dependencies will be ignored.

    =head2 method resolve

        method resolve($spec, CompUnit::Repository :@at --> Array[Candidate])

    Returns the best matching distributions from installed sources for the given C<$spec>, in preferred order (highest api
    version and highest version) from each C<CompUnit::Repository> in C<@at> (or all known C<CompUnit::Repository> if C<@at>
    is not set). C<$spec> should be either a C<Zef::Distribution::DependencySpecification> or C<Zef::Distribution::DependencySpecification::Any>.

    =head2 method is-installed

        multi method is-installed(Str $spec, |c --> Bool:D)
        multi method is-installed(Zef::Distribution::DependencySpecification::Any $spec, |c --> Bool:D)
        multi method is-installed(Zef::Distribution::DependencySpecification $spec, |c --> Bool:D)

    Returns C<True> if the requested C<$spec> is installed. The logic it uses to decide if something is installed is based on
    the C<$spec.from-matcher>: C<foo:from<bin>> will search C<$PATH> for C<foo>, C<foo:from<native>> will check if C<NativeCall>
    can see an e.g. C<libfoo.so> or C<foo.dll>, and everything else will be looked up as a C<foo> raku module.

    =head2 method sort-candidates

        method sort-candidates(@candis --> Array[Candidate])

    Does a topological sort of C<@candis> based on their various dependency fields and C<$.depends>/C<$.test-depends>/C<$.build-depends>.

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

    #| If precompilation should occur during the installation stage
    has Bool $.precompile-install is rw = True;

    submethod TWEAK(
        :$!cache                  = %!config<StoreDir>.IO,
        :$!fetcher                = Zef::Fetch.new(:backends(|%!config<Fetch>)),
        :$!extractor              = Zef::Extract.new(:backends(|%!config<Extract>)),
        :$!builder                = Zef::Build.new(:backends(|%!config<Build>)),
        :$!installer              = Zef::Install.new(:backends(|%!config<Install>)),
        :$!tester                 = Zef::Test.new(:backends(|%!config<Test>)),
        :$!reporter               = Zef::Report.new(:backends(|%!config<Report>)),
        :$!recommendation-manager = Zef::Repository.new(:backends(%!config<Repository>.tree({$_}, *.map({ $_<options><cache> //= $!cache; $_<options><fetcher> = $!fetcher; $_ })).Array)),
    ) {
        mkdir $!cache unless $!cache.IO.e;
        # Ignore CORE modules to speed up searches and to avoid dual-life issues until CORE is more strictly versioned
        @!ignore = CompUnit::RepositoryRegistry
                    .repository-for-name('core')
                    .candidates('CORE')
                    .map(*.meta<provides>.keys)
                    .flat
                    .unique
                    .map({ Zef::Distribution::DependencySpecification.new($_) })
        ;
    }

    #| Return a matching candidate/distribution for each supplied identity
    method find-candidates(Bool :$upgrade, *@identities ($, *@) --> Array[Candidate]) {
        self.logger.emit({
            level   => INFO,
            stage   => RESOLVE,
            phase   => BEFORE,
            message => "Searching for: {@identities.join(', ')}",
        });

        my Candidate @candidates = self!find-candidates(:$upgrade, @identities);

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
    method !find-candidates(Bool :$upgrade, *@identities ($, *@) --> Array[Candidate]) {
        my Candidate @candidates = $!recommendation-manager.candidates(@identities, :$upgrade)\
            .grep(-> $candi { not @!exclude.first({$candi.dist.contains-spec($_)}) })\
            .grep(-> $candi { not @!ignore.first({$candi.dist.contains-spec($_)}) })\
            .unique(:as(*.dist.identity));
        return @candidates;
    }

    #| Return matching candidates that fulfill the dependencies (including transitive) for each supplied candidate/distribution
    method find-prereq-candidates(Bool :$skip-installed = True, Bool :$upgrade, *@candis ($, *@) --> Array[Candidate]) {
        my Candidate @results = self!find-prereq-candidates(:$skip-installed, :$upgrade, |@candis);
        return @results;
    }

    #| Similar .find-prereq-candidates this has an additional non-public api parameter :@certain used during recursion
    method !find-prereq-candidates(Bool :$skip-installed = True, Bool :$upgrade, :@certain, *@candis ($, *@) --> Array[Candidate]) {
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

                my @alt-identities = gather for %needed<alternative>.list -> $needed {
                    next if any(|@certain, |@prereq-candidates).dist.contains-spec($needed);

                    my @candidates;
                    if $needed.specs.first({
                            CATCH {
                                when X::Zef::UnsatisfiableDependency { @candidates = (); }
                            }
                            @candidates = self!find-candidates(:$upgrade, $_.identity);
                            if @candidates {
                                my Candidate @new-candidates = self!find-prereq-candidates(
                                    :$upgrade,
                                    :certain(|@certain, |@prereq-candidates),
                                    @candidates,
                                );
                                @candidates.append: @new-candidates;
                            }
                            @candidates
                        })
                    -> $ {
                        @prereq-candidates.append(@candidates);
                    }
                    else {
                        take $needed.identity;
                    }
                } if %needed<alternative>;
                @prereq-candidates.append: self!find-candidates(:$upgrade, @alt-identities) if @alt-identities;

                my @not-found = @needed.grep({ not @prereq-candidates.first(*.dist.contains-spec($_)) });

                # The failing part of this should ideally be handled in Zef::CLI I think
                if +@prereq-candidates == +@needed || @not-found.cache.elems == 0 {
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
                        message => "Failed to find dependencies: {@not-found.map(*.identity).join(', ')}",
                    });

                    if $!force-resolve {
                        $!logger.emit({
                            level   => ERROR,
                            stage   => RESOLVE,
                            phase   => LIVE,
                            message => 'Failed to resolve missing dependencies, but continuing with --force-resolve',
                        });

                        # When using force-resolve we still want to treat the missing dependency as if it exists.
                        # This is intended to allow `zef depends XXX` to show dependencies for e.g. native dependencies
                        # where we don't have to worry about not finding their transitive dependencies.
                        @prereq-candidates.append(
                            @not-found.map({
                                Candidate.new(
                                    as => $_.identity,
                                    dist => Zef::Distribution.new(
                                        name => $_.name,
                                        auth => $_.auth-matcher,
                                        ver  => $_.version-matcher,
                                        api  => $_.api-matcher,
                                    ),
                                )
                            })
                        )
                    }
                    else {
                        die X::Zef::UnsatisfiableDependency.new but role :: {
                            method message {
                                X::Zef::UnsatisfiableDependency.message ~ qq| (use e.g. --exclude="{@not-found.head.name}" to skip)|;
                            }
                        };
                    }
                }

                @skip.append: @prereq-candidates.map(*.dist);
                @specs = self.list-dependencies(@prereq-candidates);
                for @prereq-candidates -> $prereq {
                    take $prereq;
                }
            }
        }

        # check $prereqs to see if we have any unneeded depends
        my Candidate @results = $prereqs.unique(:as(*.dist.identity));
        return @results;
    }


    method fetch(*@candidates ($, *@) --> Array[Candidate]) {
        my @fetched   = self!fetch(@candidates);
        my @extracted = self!extract(@fetched);

        my Candidate @local-candis = @extracted.map: -> $candi {
            my $dist = Zef::Distribution::Local.new(~$candi.uri);
            $candi.clone(:$dist);
        }

        $!recommendation-manager.store(@local-candis.map(*.dist));

        return @local-candis;
    }
    method !fetch(*@candidates ($, *@) --> Array[Candidate]) {
        my Candidate @fetched = @candidates.hyper(:batch(1), :degree($!fetch-degree || 5)).map: -> $candi {
            self.logger.emit({
                level   => DEBUG,
                stage   => FETCH,
                phase   => BEFORE,
                candi   => $candi,
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

            if !$save-to {
                self.logger.emit({
                    level   => ERROR,
                    stage   => FETCH,
                    phase   => AFTER,
                    candi   => $candi,
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
                    candi   => $candi,
                    message => "Fetching [OK]: {$candi.dist.?identity // $candi.as} to $save-to",
                });
            }

            $candi.uri = $save-to;

            $candi;
        };

        return @fetched;
    }
    method !extract(*@candidates ($, *@) --> Array[Candidate]) {
        my Candidate @extracted = eager gather for @candidates -> $candi {
            self.logger.emit({
                level   => DEBUG,
                stage   => EXTRACT,
                phase   => BEFORE,
                candi   => $candi,
                message => "Extracting: {$candi.as}",
            });

            my $tmp        = $candi.uri.IO.parent;
            my $stage-at   = $candi.uri.IO;
            my $relpath    = $stage-at.relative($tmp);
            my $extract-to = %!config<TempDir>.IO.child($relpath);
            die "failed to create directory: {$tmp.absolute}"
                unless ($tmp.IO.e || mkdir($tmp));

            my $meta6-prefix = '' R// $!extractor.ls-files($candi, :$!logger).sort.first({ .IO.basename eq 'META6.json' });

            self.logger.emit({
                level   => WARN,
                stage   => EXTRACT,
                phase   => BEFORE,
                candi   => $candi,
                message => "Extraction: Failed to find a META6.json file for {$candi.dist.?identity // $candi.as} -- failure is likely",
            }) unless $meta6-prefix;

            my $extracted-to = $!extractor.extract($candi, $extract-to, :$!logger, :timeout($!extract-timeout));

            if !$extracted-to {
                self.logger.emit({
                    level   => ERROR,
                    stage   => EXTRACT,
                    phase   => AFTER,
                    candi   => $candi,
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

                self.logger.emit({
                    level   => VERBOSE,
                    stage   => EXTRACT,
                    phase   => AFTER,
                    candi   => $candi,
                    message => "Extraction [OK]: {$candi.as} to {$extract-to}",
                });
            }

            $candi.uri = $extracted-to.child($meta6-prefix);
            take $candi;
        }
        return @extracted;
    }


    # xxx: needs some love. also an entire specification
    method build(*@candidates ($, *@) --> Array[Candidate]) {
        my Candidate @built = eager gather for @candidates -> $candi {
            my $dist := $candi.dist;

            unless $!builder.build-matcher($dist) {
                self.logger.emit({
                    level   => DEBUG,
                    stage   => BUILD,
                    phase   => BEFORE,
                    candi   => $candi,
                    message => "# SKIP: No need to build {$candi.dist.?identity // $candi.as}",
                });
                take $candi;
                next();
            }

            $!logger.emit({
                level   => INFO,
                stage   => BUILD,
                phase   => BEFORE,
                candi   => $candi,
                message => "Building: {$candi.dist.?identity // $candi.as}",
            });

            my $result := $!builder.build($candi, :includes($candi.dist.metainfo<includes> // []), :$!logger, :timeout($!build-timeout)).cache;

            $candi.build-results = $result;

            if $result.grep(*.not).elems {
                self.logger.emit({
                    level   => ERROR,
                    stage   => BUILD,
                    phase   => AFTER,
                    candi   => $candi,
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
                    candi   => $candi,
                    message => "Building [OK] for {$candi.dist.?identity // $candi.as}",
                });
            }

            take $candi;
        }

        @built
    }

    # xxx: needs some love
    method test(*@candidates ($, *@) --> Array[Candidate]) {
        my Candidate @tested = @candidates.hyper(:batch(1), :degree($!test-degree || 1)).map: -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => TEST,
                phase   => BEFORE,
                candi   => $candi,
                message => "Testing: {$candi.dist.?identity // $candi.as}",
            });

            my $result := $!tester.test($candi, :includes($candi.dist.metainfo<includes> // []), :$!logger, :timeout($!test-timeout)).cache;

            $candi.test-results = $result;

            if $result.grep(*.not).elems {
                self.logger.emit({
                    level   => ERROR,
                    stage   => TEST,
                    phase   => AFTER,
                    candi   => $candi,
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
                    candi   => $candi,
                    message => "Testing [OK] for {$candi.dist.?identity // $candi.as}",
                });
            }

            $candi;
        }

        return @tested
    }

    #| Search for identities from the various repository backends and returns the matching distributions
    method search(*@identities ($, *@), *%fields, Bool :$strict = False --> Array[Candidate]) {
        my Candidate @results = $!recommendation-manager.search(@identities, :$strict, |%fields);
        return @results;
    }

    #| Uninstall a distribution from a given repository
    method uninstall(CompUnit::Repository :@from!, *@identities --> Array[Candidate]) {
        my @specs = @identities.map: { Zef::Distribution::DependencySpecification.new($_) }
        my Candidate @results = eager gather for self.list-installed(@from) -> $candi {
            my $dist = $candi.dist;
            if @specs.first({ $dist.spec-matcher($_) }) {
                my $cur = CompUnit::RepositoryRegistry.repository-for-spec($candi.from, :next-repo($*REPO));
                $cur.uninstall($dist);
                take $candi;
            }
        }
        return @results;
    }

    #| Install a distribution to a given repository
    method install(:@curs, *@candidates ($, *@) --> Array[Candidate]) {
        my Candidate @installed = eager gather for @candidates -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => INSTALL,
                phase   => BEFORE,
                candi   => $candi,
                message => "Installing: {$candi.dist.?identity // $candi.as}",
            });

            for @curs -> $cur {
                KEEP self.logger.emit({
                    level   => VERBOSE,
                    stage   => INSTALL,
                    phase   => AFTER,
                    candi   => $candi,
                    message => "Install [OK] for {$candi.dist.?identity // $candi.as}",
                });

                CATCH {
                    when /'already installed'/ {
                        self.logger.emit({
                            level   => INFO,
                            stage   => INSTALL,
                            phase   => AFTER,
                            candi   => $candi,
                            message => "Install [SKIP] for {$candi.dist.?identity // $candi.as}: {$_}",
                        });
                    }
                    default {
                        self.logger.emit({
                            level   => ERROR,
                            stage   => INSTALL,
                            phase   => AFTER,
                            candi   => $candi,
                            message => "Install [FAIL] for {$candi.dist.?identity // $candi.as}: {$_}",
                        });
                        $_.rethrow;
                    }
                }

                take $candi if $!installer.install($candi, :$cur, :force($!force-install), :precompile($!precompile-install), :$!logger, :timeout($!install-timeout));
            }
        }

        return @installed;
    }

    # Note that since adding CURS support some of the functions and apis feel
    # a little odd now. For now we try to maintain the original output and
    # design expectations as best we can, but in the next version of zef
    # we'll design more around CURFS and less around CURI. For instance
    # this 'deploy' method takes @candidates although we only use it for
    # displaying what will be installed - since we copy $curs to the install
    # target we don't need to know the individual candidates (and indeed we
    # can get them from the repository itself).
    #| Deploy all distributions installed to staging to a given repository
    method deploy(:$curs, *@candidates ($, *@) --> Array[Candidate]) is implementation-detail {
        for @candidates -> $candi {
            self.logger.emit({
                level   => INFO,
                stage   => INSTALL,
                phase   => BEFORE,
                candi   => $candi,
                message => "Installing: {$candi.dist.?identity // $candi.as}",
            });
        }

        {
            CATCH {
                default {
                    for @candidates -> $candi {
                        self.logger.emit({
                            level   => ERROR,
                            stage   => INSTALL,
                            phase   => AFTER,
                            candi   => $candi,
                            message => "Install [FAIL] for {$candi.dist.?identity // $candi.as}: {$_}",
                        });
                    }
                    $_.rethrow;
                }
            }
            $curs.deploy();
        }

        for @candidates -> $candi {
            self.logger.emit({
                level   => VERBOSE,
                stage   => INSTALL,
                phase   => AFTER,
                candi   => $candi,
                message => "Install [OK] for {$candi.dist.?identity // $candi.as}",
            });
        }

        return Array[Candidate].new(@candidates);
    }

    #| This organizes and executes multiples phases for multiples candidates (test/build/install/etc)
    method make-install(
        CompUnit::Repository :@to!, # target CompUnit::Repository
        Bool :$fetch = True,        # try fetching whats missing
        Bool :$build = True,        # run Build.rakumod (DEPRECATED..?)
        Bool :$test  = True,        # run tests
        Bool :$dry,                 # do everything *but* actually install
        Bool :$serial,
        *@candidates ($, *@),
        *%_
    ) {
        # Allowing multiple install targets complicates things too much.
        # TODO: remove this ability from the code everywhere.
        if @to.elems > 1 {
            die "Installing to multiple repos is no longer supported."
        }

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

        my $stage-for-repo = CompUnit::RepositoryRegistry.repository-for-name(@curs.head.?name // '');

        # XXX: Each loop block below essentially represents a phase, so they will probably
        # be moved into their own method/module related directly to their phase. For now
        # lumping them here allows us to easily move functionality between phases until we
        # find the perfect balance/structure.
        die "Must specify something to install" unless +@candidates;

        # Fetch Stage:
        # Use the results from searching each available Repository and download/fetch the distributions they point at
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
                candi   => $candi,
                message => "Filtering: {$candi.dist.identity}",
            });
            KEEP $!logger.emit({
                level   => DEBUG,
                stage   => FILTER,
                phase   => AFTER,
                candi   => $candi,
                message => "Filtering [OK] for {$candi.dist.?identity // $candi.as}",
            });
            UNDO $!logger.emit({
                level   => ERROR,
                stage   => FILTER,
                phase   => AFTER,
                candi   => $candi,
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


        # Non staging workflow
        my $curi-installer = sub (*@_) {
            # Build Phase:
            my @built-candidates = ?$build ?? self.build(@_) !! @_;
            die "No installable candidates remain after `build` failures" unless +@built-candidates;

            # We aren't using the CURS workflow, so we need to add the distribution path / CURFS repo
            # to each distribution includes listing.
            for @sorted-candidates {
                $_.dist.metainfo<includes>.prepend($_.dist.path);
            }

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
                # Get the name of the bin scripts
                my sub bin-names($dist) { $dist.meta<files>.hash.keys.grep(*.starts-with("bin/")).map(*.substr(4)) };

                if @installed-candidates.map(*.dist).map(*.&bin-names).flat.unique -> @bins {
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
        }

        # This convoluted code should just be able to `use CompUnit::Repository::Staging; CompUnit::Repository::Staging.new(...)`
        # but that creates precompilation issues, presumably because the repository chain includes e.g. -I. when zef is installing
        # itself.
        # See: https://github.com/rakudo/rakudo/issues/5199
        my $staging-repo = !$stage-for-repo ?? Nil !! do {
            # We do this here instead of inside the $curs-installer sub because we
            # only want to create this repository once, even when using --serial
            my $staging-at = %!config<TempDir>.IO.child("{time}.{$*PID}.{(^10000).rand}");
            die "failed to create directory: {$staging-at.absolute}"
                unless ($staging-at.IO.e || mkdir($staging-at));

            # The first condition is preemptively trying to avoid any issue if/when CURS is moved to
            # the core (where it wouldn't be found via $*REPO.resolve(...)). The second condition finds
            # the CURFS module and then loads it's code CURAP because that won't precompile it.
            # I've tried a lot of various work arounds using EVAL, no precompilation, etc and none of
            # them have worked 100% (something might work for bin/zef and fail for `raku -e 'use Zef::CLI install .`
            # for instance).
            my %curfs-new-args = :prefix($staging-at), :name($stage-for-repo.name), :next-repo($stage-for-repo);
            my $curfs-short-name = 'CompUnit::Repository::Staging';
            (try ::($curfs-short-name))
                ?? ::($curfs-short-name).new(|%curfs-new-args)
                !! do {
                    # Find CURS from the core repository so we can load it by path later
                    my $core-repo = CompUnit::RepositoryRegistry.repository-for-name('core');
                    my $curs-dist = $core-repo.resolve(CompUnit::DependencySpecification.new(:short-name($curfs-short-name))).distribution;

                    # Load CURS by using CURAP (which doesn't precompile)
                    my $curs-provides-entry = $curs-dist.meta<provides>{$curfs-short-name};
                    my $curs-name-path = $curs-provides-entry.?keys.?head // $curs-provides-entry;
                    my $curs-handle = $curs-dist.content($curs-name-path);
                    $curs-handle.close(); # I think these handles shouldn't be opened already from ::InstalledDistribution :(
                    $*REPO.load($curs-handle.path);
                    ::($curfs-short-name).new(|%curfs-new-args);
                }
        }

        # Staging workflow
        my $curs-installer = sub (*@_) {
            # Build Phase:
            my @built-candidates = ?$build ?? self.build(@_) !! @_;
            die "No installable candidates remain after `build` failures" unless +@built-candidates;

            my @staged-candidates = @built-candidates.map({
                self.logger.emit({
                    level   => INFO,
                    stage   => STAGING,
                    phase   => BEFORE,
                    message => "Staging {$_.dist.identity}",
                });
                my Str @includes = $staging-repo.path-spec;
                $_.dist.metainfo<includes> = @includes;
                $staging-repo.install($_.dist, :precompile($!precompile-install));
                self.logger.emit({
                    level   => INFO,
                    stage   => STAGING,
                    phase   => AFTER,
                    message => "Staging [OK] for {$_.dist.identity}",
                });

                $_;
            });

            $staging-repo.remove-artifacts;

            # Test Phase:
            my @tested-candidates = !$test
                ?? @built-candidates
                !! self.test(@built-candidates).grep({ $!force-test || .test-results.grep(!*.so).elems == 0 });

            # actually we *do* want to proceed here later so that the Report phase can know about the failed tests/build
            die "All candidates failed building and/or testing. No reason to proceed" unless +@tested-candidates;

            # Install Phase:
            # Ideally `--dry` uses a special unique CompUnit::Repository that is meant to be deleted entirely
            # and contain only the modules needed for this specific run/plan
            my @installed-candidates = ?$dry ?? @tested-candidates !! do {
                self.logger.emit({
                    level   => VERBOSE,
                    stage   => INSTALL,
                    phase   => BEFORE,
                    message => "Installing staged code",
                });
                self.deploy(|@tested-candidates, :curs($staging-repo));
                self.logger.emit({
                    level   => VERBOSE,
                    stage   => INSTALL,
                    phase   => AFTER,
                    message => "Installation [OK]",
                });

                @tested-candidates;
            }

            # Report phase:
            # Handle exit codes for various option permutations like --force
            # Inform user of what was tested/built/installed and what failed
            # Optionally report to any cpan testers type service (testers.perl6.org)
            unless $dry {
                # Get the name of the bin scripts
                my sub bin-names($dist) { $dist.meta<files>.hash.keys.grep(*.starts-with("bin/")).map(*.substr(4)) };

                if @installed-candidates.map(*.dist).map(*.&bin-names).flat.unique -> @bins {
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
        }

        my $installer = $stage-for-repo.so ?? $curs-installer !! $curi-installer;
        my Candidate @installed = ?$serial ?? @linked-candidates.map({ |$installer($_) }) !! $installer(@linked-candidates);
        return @installed;
    }

    #| Return distributions that depend on the given identity
    method list-rev-depends($identity, Bool :indirect($) --> Array[Candidate]) {
        my $spec = Zef::Distribution::DependencySpecification.new($identity);
        my $dist = self.list-available.first(*.dist.contains-spec($spec)).?dist
                || self.list-installed.first(*.dist.contains-spec($spec)).?dist;
        return Array[Candidate].new unless $dist;

        my $rev-deps := gather for self.list-available -> $candi {
            my $specs := self.list-dependencies($candi);

            take $candi if $specs.first({ $dist.contains-spec($_, :strict) });
        }
        my Candidate @results = $rev-deps.unique(:as(*.dist.identity));
        return @results;
    }

    #| Return all distributions from all configured repositories
    method list-available(*@recommendation-manager-names --> Array[Candidate]) {
        my Candidate @available = $!recommendation-manager.available(@recommendation-manager-names);
        return @available;
    }

    #| Return all distributions in known CompUnit::Repository::Installation repositories
    method list-installed(*@repos --> Array[Candidate]) {
        my @curs  = +@repos ?? @repos !! $*REPO.repo-chain;
        my @curis = @curs.grep(CompUnit::Repository::Installation);
        my @curi-dists = @curis.map(-> $curi { Hash.new({ :$curi, :dists($curi.installed) }) }).grep({ $_<dists>.defined });
        my Candidate @dists = gather for @curi-dists -> % [:$curi, :@dists] {
            for @dists -> $curi-dist {
                if try { Zef::Distribution.new( |%($curi-dist.meta) ) } -> $dist {
                    take Candidate.new( :$dist, :from($curi.path-spec), :uri($curi.path-spec) );
                }
            }
        }
        return @dists;
    }

    method list-leaves(--> Array[Candidate]) {
        my @installed = self.list-installed;
        my @dep-specs = self.list-dependencies(@installed);

        my Candidate @leaves = gather for @installed -> $candi {
            my $dist := $candi.dist;
            take $candi unless @dep-specs.first: { $dist.contains-spec($_) }
        }
        return @leaves;
    }

    #| Return distributions that are direct dependencies of the supplied distributions
    method list-dependencies(*@candis --> Array[DependencySpecification]) {
        my $deps := gather for @candis -> $candi {
            take $_ for grep *.defined, flat
                ($candi.dist.depends-specs       if ?$!depends),
                ($candi.dist.test-depends-specs  if ?$!test-depends),
                ($candi.dist.build-depends-specs if ?$!build-depends);
        }

        # This returns both Zef::Distribution::DependencySpecification and Zef::Distribution::DependencySpecification::Any
        #my Zef::Distribution::DependencySpecification @results = $deps.unique(:as(*.identity));
        my DependencySpecification @results = $deps.unique(:as(*.identity));
        return @results;
    }

    #| Returns the best matching distributions from installed sources, in preferred order, similar to $*REPO.resolve
    method resolve($spec, CompUnit::Repository :@at --> Array[Candidate]) {
        my $candis := self.list-installed(@at).grep(*.dist.contains-spec($spec));
        my Candidate @results = $candis.sort(*.dist.ver).sort(*.dist.api).reverse;
        return @results;
    }

    #| Return true if the requested dependency is already installed
    multi method is-installed(Str $spec, |c --> Bool:D) {
        return self.is-installed(Zef::Distribution::DependencySpecification.new($spec));
    }

    #| Return true of one-or-more of the requested dependencies are already installed
    multi method is-installed(Zef::Distribution::DependencySpecification::Any $spec, |c --> Bool:D) {
        return so $spec.specs.first({ self.is-installed($_, |c) });
    }

    #| Return true if the requested dependency is already installed
    multi method is-installed(Zef::Distribution::DependencySpecification $spec, |c --> Bool:D) {
        return do given $spec.?from-matcher {
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

    #| Topological sort used to determine which dependency can be processed next in a given phase
    method sort-candidates(@candis --> Array[Candidate]) {
        my Candidate @tree;
        my $visit = sub ($candi) {
            return if ($candi.dist.metainfo<marked> // 0) == 1;
            if ($candi.dist.metainfo<marked> // 0) == 0 {
                $candi.dist.metainfo<marked> = 1;

                my @deps = |self.list-dependencies($candi);

                for @deps -> $m {
                    for @candis.grep(*.dist.contains-spec($m)) -> $m2 {
                        $visit($m2);
                    }
                }
                @tree.append($candi);
            }
        };

        for @candis -> $candi {
            $visit($candi) if ($candi.dist.metainfo<marked> // 0) == 0;
        }

        .dist.metainfo<marked> = Nil for @tree;
        return @tree;
    }

    #| Adds appropriate include (-I / PERL6LIB) paths for dependencies
    proto method link-candidates(|) {*}
    multi method link-candidates(Bool :recursive($)! where *.so, *@candidates) {
        # :recursive
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        #   - Bar::YYY -> -I/Bar/YYY -I/Baz/ZZZ
        #   - Baz::ZZZ -> -I/Baz/ZZZ

        # XXX: Need to change this so it only add indirect dependencies
        # instead of just using recursion on the array in order. Otherwise there
        # can be distributions that are part of a different dependency
        # chain will end up with some extra includes

        my @linked = self.link-candidates(@candidates);
        @ = @linked.map: -> $candi { # can probably use rotor instead of doing the `@a[$index + 1..*]` dance
            my @direct-includes    = $candi.dist.metainfo<includes>.grep(*.so);
            my @recursive-includes = try @linked[(++$)..*]\
                .map(*.dist.metainfo<includes>).map(*.flat);
            my @unique-includes    = unique(@direct-includes, @recursive-includes);
            my Str @results        = @unique-includes.grep(*.so);
            $candi.dist.metainfo<includes> = @results;
            $candi;
        }
    }
    multi method link-candidates(Bool :inclusive($)! where *.so, *@candidates) {
        # :inclusive
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        #   - Bar::YYY -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        #   - Baz::ZZZ -> -I/Foo/XXX -I/Bar/YYY -I/Baz/ZZZ
        my @linked = self.link-candidates(@candidates);
        @ = @linked.map(*.dist.metainfo<includes>).map(*.flat).unique;
    }
    multi method link-candidates(*@candidates) {
        # Default
        # Given Foo::XXX that depends on Bar::YYY that depends on Baz::ZZZ
        #   - Foo::XXX -> -I/Foo/XXX -I/Bar/YYY
        #   - Bar::YYY -> -I/Bar/YYY -I/Baz/ZZZ
        #   - Baz::ZZZ -> -I/Baz/ZZZ
        @ = @candidates.map: -> $candi {
            my @dep-specs = |self.list-dependencies($candi);

            # this could probably be done in the topological-sort itself
            my $includes := eager gather for @dep-specs -> $spec {
                CANDIDATE: for @candidates -> $fcandi {
                    my $fdist := $fcandi.dist;
                    if $fdist.contains-spec($spec) {
                        take $fdist.IO.absolute;
                        take $_ for |$fdist.metainfo<includes>.grep(*.so);
                        last CANDIDATE;
                    }
                }
            }

            my Str @results = $includes.unique;
            $candi.dist.metainfo<includes> = @results;

            $candi;
        }
    }
}

