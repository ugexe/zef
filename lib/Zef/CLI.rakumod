use Zef:ver($?DISTRIBUTION.meta<version>):api($?DISTRIBUTION.meta<api>):auth($?DISTRIBUTION.meta<auth>);
use Zef::Client:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Config:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Utils::FileSystem:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Identity:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Distribution:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);
use Zef::Utils::URI:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth) :internals;
use nqp;

package Zef::CLI {

    =begin pod

    =title package Zef::CLI

    =subtitle The zef command line interface

    =head1 Synopsis

    =begin code :lang<sh>

        zef --help

        raku -e 'use Zef::CLI' install ./my-dist

    =end code

    =head1 Description

    Acts as a script-in-module-form (for precompilation reasons). As such the following two commands are the same:
    C<zef install Foo>, C<raku -e 'use Zef::CLI' install Foo>. See `zef --help` or `raku -I. bin/zef --help` for
    high level information on the various commands and options.

    =head1 Subroutines

    =head2 sub MAIN(:$version)

        multi sub MAIN(Bool :version($) where .so) {

    Show the version of zef being used.

    =head2 sub MAIN(:$help)

        multi sub MAIN(Bool :h(:help($)))

    Show the usage message.

    =head2 sub MAIN('fetch', ...)

        sub MAIN(
            'fetch',
            Bool :force(:$force-fetch),
            Int  :timeout(:$fetch-timeout) = %*ENV<ZEF_FETCH_TIMEOUT> // 600,
            Int  :degree(:$fetch-degree)   = %*ENV<ZEF_FETCH_DEGREE> || 5, # default different from Zef::Client,
            :$update, # Not Yet Implemented
            *@identities ($, *@)
        )

    Download and extract the best matching distribution found for each C<@identities>. Will exit 0 on success.

    If C<$force-fetch> is C<True> then a failure to fetch something won't throw an exception.

    If C<$fetch-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when fetching something before attempting to try the next matching fetching adapter.

    If C<$fetch-degree> is set zef will download up to that many distributions in parallel.

    =head2 sub MAIN('test', ...)

        sub MAIN(
            'test',
            Bool :force(:$force-test),
            Int  :timeout(:$test-timeout) = %*ENV<ZEF_TEST_TIMEOUT> || 3600,
            Int  :degree(:$test-degree) = %*ENV<ZEF_TEST_DEGREE> || 1,
            *@paths ($, *@)
        )

    Test the distributions from the provided C<@paths>. Will exit 0 on success.

    If C<$force-test> is C<True> then a test failure won't throw an exception.

    If C<$test-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when testing a distribution before aborting.

    If C<$test-degree> is set zef will test up to that many distributions in parallel.

    =head2 sub MAIN('build', ...)

        sub MAIN(
            'build',
            Bool :force(:$force-build),
            Int  :timeout(:$build-timeout) = %*ENV<ZEF_BUILD_TIMEOUT> || 3600,
            *@paths ($, *@)
        )

    Build the distributions from the provided C<@paths>. Will exit 0 on success.

    If C<$force-build> is C<True> then a test failure won't throw an exception.

    If C<$build-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when building a distribution before aborting.

    =head2 sub MAIN('install', ...)

        sub MAIN(
            'install',
            Bool :$fetch         = True,
            Bool :$build         = True,
            Bool :$test          = True,
            Bool :$depends       = True,
            Bool :$build-depends = $build,
            Bool :$test-depends  = $test,
            Bool :$force,
            Bool :$force-resolve = $force,
            Bool :$force-fetch   = $force,
            Bool :$force-extract = $force,
            Bool :$force-build   = $force,
            Bool :$force-test    = $force,
            Bool :$force-install = $force,
            Int  :$timeout,
            Int  :$fetch-timeout   = %*ENV<ZEF_FETCH_TIMEOUT>   // $timeout // 600,
            Int  :$extract-timeout = %*ENV<ZEF_EXTRACT_TIMEOUT> // $timeout // 3600,
            Int  :$build-timeout   = %*ENV<ZEF_BUILD_TIMEOUT>   // $timeout // 3600,
            Int  :$test-timeout    = %*ENV<ZEF_TEST_TIMEOUT>    // $timeout // 3600,
            Int  :$install-timeout = %*ENV<ZEF_INSTALL_TIMEOUT> // $timeout // 3600,
            Int  :$degree,
            Int  :$fetch-degree   = %*ENV<ZEF_FETCH_DEGREE> || $degree || 5, # default different from Zef::Client
            Int  :$test-degree    = %*ENV<ZEF_TEST_DEGREE>  || $degree || 1,
            Bool :$dry,
            Bool :$upgrade,# Not Yet Implemented
            Bool :$deps-only,
            Bool :$serial,
            Bool :$contained,
            :$update,
            :$exclude,
            :to(:$install-to) = %*ENV<ZEF_INSTALL_TO> // $CONFIG<DefaultCUR>,
            *@wants ($, *@)
        )

    Fetch, extract, build, test, and install C<@wanted> distributions and their prerequisites.

    If C<$fetch> is set to C<False> then the fetch phase will be skipped.

    If C<$build> is set to C<False> then the build phase will be skipped.

    If C<$test> is set to C<False> then the test phase will be skipped.

    If C<$depends> is set to C<False> then runtime dependencies will be ignored.

    If C<$build-depends> is set to C<False> then build dependencies will be ignored.

    If C<$test-depends> is set to C<False> then test dependencies will be ignored.

    If C<$force> is set to C<True> then zef will treat any failures as successes, potentially allowing progress to continue on failure.

    If C<$force-resolve> is set to C<True> then zef will treat any name resolution failures as successes, potentially allowing progress to continue on failure.

    If C<$force-fetch> is set to C<True> then zef will treat any fetch failures as successes, potentially allowing progress to continue on failure.

    If C<$force-extract> is set to C<True> then zef will treat any extract failures as successes, potentially allowing progress to continue on failure.

    If C<$force-build> is set to C<True> then zef will treat any build failures as successes, potentially allowing progress to continue on failure.

    If C<$force-test> is set to C<True> then zef will treat any test failures as successes, potentially allowing progress to continue on failure.

    If C<$force-install> is set to C<True> then zef will treat any install failures as successes, potentially allowing progress to continue on failure.

    If C<$timeout> is set to a non-zero c<Int> zef will wait for that many seconds when executing a given action for a specific distribution before aborting.

    If C<$fetch-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when fetching something before attempting to try the next matching fetching adapter.

    If C<$build-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when building a distribution before aborting.

    If C<$test-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when testing a distribution before aborting.

    If C<$install-timeout> is set to a non-zero c<Int> zef will wait for that many seconds when installing a distribution before aborting.

    If C<$fetch-degree> is set zef will download up to that many distributions in parallel.

    If C<$test-degree> is set zef will test up to that many distributions in parallel.

    If C<$dry> is set to C<True> then the final step of actually installing the distribution will be skipped and considered a success.

    If C<$deps-only> is set to C<True> then only the dependencies of the requested identities will be processed.

    If C<$serial> is set to C<True> then zef will install each distribution after it passes its own tests. By default this is C<False> and means nothing will be installed unless all distributions passed their tests.

    If C<$contained> is set to C<True> (and combined with C<:$install-to>) zef will install all distributions to a location, including those that might otherwise already be installed and visible in another location (BETA)

    If C<$update> is set to C<True> it will force an update of all ecosystem / repository indexes. If C<$update> is set to a C<Str> or C<Array[Str]> it will only update the repositories that match the given names.

    If C<$exclude> If C<$exclude> is set to a C<Str> or C<Array[Str]> then any matching dependency will be ignored.

    If C<$to>/C<:$install-to> is set to a C<Str> or C<Array[Str]> then distributions will be installed to all of those C<CompUnit::Repository>. The short names C<site> C<home> C<vendor> can be used to reference their associated repository, otherwise a file path can be given to use a custom location. By default this is set to the zef-specific value C<auto> which makes zef use the C<site> repository if the user has write access and the C<home> otherwise.

    =head2 sub MAIN('uninstall', ...)

        sub MAIN(
            'uninstall',
            :from(:$uninstall-from),
            *@identities ($, *@)
        )

    Uninstall distributions matching C<@identities> from any visible repository.

    If C<$uninstall-from> is set to a C<Str> or C<Array[Str]> then the uninstall will apply to those repositories instead of all visible ones.

    =head2 sub MAIN('search', ...)

        multi sub MAIN('search', Int :$wrap = False, :$update, *@terms ($, *@))

    Does a basic substring search for any of C<@terms> and returns any matching distributions.

    If C<$wrap> is set to C<True> then the generated table won't wrap (nyi -- need to detect terminal width again), and if set to an C<Int> limit the generated table to that many characters wide.

    If C<$update> is set to C<True> it will force an update of all ecosystem / repository indexes. If C<$update> is set to a C<Str> or C<Array[Str]> it will only update the repository that matches the given names.

    =head2 sub MAIN('list', ...)

        multi sub MAIN('list', Int :$max?, :$update, Bool :i(:$installed), *@at)

    List all distributions from all known repositories.

    If C<$max> is set then only that many results will be returned from each repository.

    If C<$update> is set to C<True> it will force an update of all ecosystem / repository indexes. If C<$update> is set to a C<Str> or C<Array[Str]> it will only update the repositories that match the given names.

    If C<$i>/C<$installed> is set to C<True> then only installed distributions will be listed.

    If C<@at> is set to a C<Array[Str]> it will only list distributions from the repositories that match the given names.

    =head2 sub MAIN('depends', ...)

        multi sub MAIN(
            'depends',
            $identity,
            Bool :$depends       = True,
            Bool :$test-depends  = True,
            Bool :$build-depends = True,
        )


    List the dependencies of the given C<$identity>.

    If C<$depends> is set to C<False> then runtime dependencies will be ignored.

    If C<$build-depends> is set to C<False> then build dependencies will be ignored.

    If C<$test-depends> is set to C<False> then test dependencies will be ignored.

    =head2 sub MAIN('rdepends', ...)

        multi sub MAIN(
            'rdepends',
            $identity,
            Bool :$depends       = True,
            Bool :$test-depends  = True,
            Bool :$build-depends = True,
        )

    List the reverse dependencies of the given C<$identity>.

    If C<$depends> is set to C<False> then runtime dependencies will be ignored.

    If C<$build-depends> is set to C<False> then build dependencies will be ignored.

    If C<$test-depends> is set to C<False> then test dependencies will be ignored.

    =head2 sub MAIN('info', ...)

        multi sub MAIN('info', $identity, :$update, Int :$wrap = False)

    List detailed information about the best match for C<$identity>.

    If C<$wrap> is set to C<True> then the generated table won't wrap (nyi -- need to detect terminal width again), and if set to an C<Int> limit the generated table to that many characters wide.

    If C<$update> is set to C<True> it will force an update of all ecosystem / repository indexes. If C<$update> is set to a C<Str> or C<Array[Str]> it will only update the repositories that match the given names.

    =head2 sub MAIN('browse', ...)

        multi sub MAIN('browse', $identity, $url-type where * ~~ any(<homepage bugtracker source>), Bool :$open = True)

    Open a browser to the C<$url-type> resource of the best matching distribution for C<$identity>.

    If C<$open> is set to C<False> then a browser window won't be opened, instead just outputting the url to the terminal.

    =head2 sub MAIN('update', ...)

        multi sub MAIN('update', *@names)

    Update all ecosystem / repository indexes.

    If C<@names> is set to a C<Str> or C<Array[Str]> it will only update the repositories that match the given names.

    =head2 sub MAIN('nuke', ...)

        multi sub MAIN('nuke', Bool :$confirm, *@names ($, *@))

    Delete everything for C<@names>, where C<@names> can be a core repository name (C<site> C<home> C<vendor>), or a config directory reference (C<StoreDir> C<TempDir>).

    If C<$confirm> is set to C<False> then zef will not prompt to confirm deletion.

    =end pod


    my $verbosity = preprocess-args-verbosity-mutate(@*ARGS);
    %*ENV<ZEF_BUILDPM_DEBUG> = $verbosity >= DEBUG;
    %*ENV<HARNESS_VERBOSE> = $verbosity >= DEBUG;
    my $CONFIG    = preprocess-args-config-mutate(@*ARGS);
    my $VERSION   = BEGIN $?DISTRIBUTION.meta<version>;

    @*ARGS = eager gather for @*ARGS -> $arg {
        if $arg eq '--depsonly' {
            note 'DEPRECATED: --depsonly is deprecated, please use --deps-only instead';
            take '--deps-only'
        }
        else {
            take $arg
        }
    }

    proto MAIN(|) is export {
        # Suppress backtrace
        CATCH { default { try { ::("Rakudo::Internals").?LL-EXCEPTION } ?? .rethrow !! .message.&note; &*EXIT(1) } }
        {*}
    }

    #| Download specific distributions
    multi sub MAIN(
        'fetch',
        Bool :force(:$force-fetch),
        Int  :timeout(:$fetch-timeout) = %*ENV<ZEF_FETCH_TIMEOUT> // 600,
        Int  :degree(:$fetch-degree)   = %*ENV<ZEF_FETCH_DEGREE> || 5, # default different from Zef::Client,
        :$update,
        *@identities ($, *@)
    ) {
        my $client     = get-client(:config($CONFIG), :$force-fetch, :$update, :$fetch-timeout, :$fetch-degree);
        my @candidates = $client.find-candidates(@identities.map(*.&str2identity));
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my @fetched    = $client.fetch(@candidates);
        my @fail       = @candidates.grep: {.as !~~ any(@fetched>>.as)}

        say "!!!> Fetch failed: {.as}{?($verbosity >= VERBOSE)??' at '~.dist.path!!''}" for @fail;

        exit +@fetched && +@fetched == +@candidates && +@fail == 0 ?? 0 !! 1;
    }

    #| Run tests
    multi sub MAIN(
        'test',
        Bool :force(:$force-test),
        Int  :timeout(:$test-timeout) = %*ENV<ZEF_TEST_TIMEOUT> || 3600,
        Int  :degree(:$test-degree) = %*ENV<ZEF_TEST_DEGREE> || 1,
        *@paths ($, *@)
    ) {
        my $client     = get-client(:config($CONFIG), :$force-test, :$test-timeout, :$test-degree);
        my @candidates = $client.link-candidates( @paths.map(*.&path2candidate) );
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;

        # We don't use CURS for `zef test .` yet, so add the CURFS path of the dist to the includes.
        for @candidates {
            $_.dist.metainfo<includes>.prepend($_.dist.path);
        }

        my @tested = $client.test(@candidates);
        my (:@test-pass, :@test-fail) := @tested.classify: {.test-results.grep(*.so) ?? <test-pass> !! <test-fail> }

        say "!!!> Testing failed: {.as}{?($verbosity >= VERBOSE)??' at '~.dist.path!!''}" for @test-fail;

        exit ?@test-fail ?? 1 !! ?@test-pass ?? 0 !! 255;
    }

    #| Run the build process
    multi sub MAIN(
        'build',
        Bool :force(:$force-build),
        Int  :timeout(:$build-timeout) = %*ENV<ZEF_BUILD_TIMEOUT> || 3600,
        *@paths ($, *@)
    ) {
        my $client = get-client(:config($CONFIG), :$force-build, |(:$build-timeout with $build-timeout),);
        my @candidates = $client.link-candidates( @paths.map(*.&path2candidate) );
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;

        my @built = $client.build(@candidates);
        my (:@pass, :@fail) := @built.classify: {.?build-results.grep(*.so).elems ?? <pass> !! <fail> }

        say "!!!> Build failure: {.as}{?($verbosity >= VERBOSE)??' at '~.dist.path!!''}" for @fail;

        exit ?@fail ?? 1 !! ?@pass ?? 0 !! 255;
    }

    #| Fetch, extract, build, test and install distributions
    multi sub MAIN(
        'install',
        Bool :$fetch         = True,
        Bool :$build         = True,
        Bool :$test          = True,
        Bool :$depends       = True,
        Bool :$build-depends = $build,
        Bool :$test-depends  = $test,
        Bool :$force,
        Bool :$force-resolve = $force,
        Bool :$force-fetch   = $force,
        Bool :$force-extract = $force,
        Bool :$force-build   = $force,
        Bool :$force-test    = $force,
        Bool :$force-install = $force,
        Int  :$timeout,
        Int  :$fetch-timeout   = %*ENV<ZEF_FETCH_TIMEOUT>   // $timeout // 600,
        Int  :$extract-timeout = %*ENV<ZEF_EXTRACT_TIMEOUT> // $timeout // 3600,
        Int  :$build-timeout   = %*ENV<ZEF_BUILD_TIMEOUT>   // $timeout // 3600,
        Int  :$test-timeout    = %*ENV<ZEF_TEST_TIMEOUT>    // $timeout // 3600,
        Int  :$install-timeout = %*ENV<ZEF_INSTALL_TIMEOUT> // $timeout // 3600,
        Int  :$degree,
        Int  :$fetch-degree   = %*ENV<ZEF_FETCH_DEGREE> || $degree || 5, # default different from Zef::Client
        Int  :$test-degree    = %*ENV<ZEF_TEST_DEGREE>  || $degree || 1,
        Bool :$dry,
        Bool :$upgrade,
        Bool :$deps-only,
        Bool :$serial,
        Bool :$contained,
        :$update,
        :$exclude,
        :to(:$install-to) = %*ENV<ZEF_INSTALL_TO> // $CONFIG<DefaultCUR>,
        *@wants ($, *@)
    ) {

        @wants .= map: *.&str2identity;
        my (:@paths, :@uris, :@identities) := @wants.classify: -> $wanted {
            $wanted ~~ /^[\. | \/]/                               ?? <paths>
                !! ($wanted ~~ /^\w+:/ && $wanted.IO.is-absolute) ?? <paths>      # for the rare e.g. C:\foo type paths
                !! ?Zef::Identity.new($wanted)                    ?? <identities>
                !! (my $uri = uri($wanted) and !$uri.is-relative) ?? <uris>
                !! abort("Don't understand identity: {$wanted}");
        }

        my $client = get-client(
            :config($CONFIG), :$update,          :exclude($exclude.grep(*.defined).map({ Zef::Distribution::DependencySpecification.new($_) })),
            :$depends,        :$test-depends,    :$build-depends,
            :$force-resolve,  :$force-fetch,     :$force-extract,
            :$force-build,    :$force-test,      :$force-install,
            :$fetch-timeout,  :$extract-timeout, :$build-timeout,
            :$test-timeout,   :$install-timeout, :$fetch-degree,
            :$test-degree,
        );

        my CompUnit::Repository @at = $install-to.map(*.&str2cur);

        # LOCAL PATHS
        abort "The following were recognized as file paths but don't exist as such - {@paths.grep(!*.IO.e)}"
            if +@paths.grep(!*.IO.e);
        abort "The following were recognized as directory paths but don't contain a META6.json file - {@paths.grep(*.IO.d).grep(!*.IO.add('META6.json').e)}"
            if +@paths.grep(*.IO.d).grep(!*.IO.add('META6.json').e);
        my (:@paths-to-files, :@paths-to-dirs) := @paths.classify: { $_.IO.d ?? <paths-to-dirs> !! <paths-to-files> }
        my @dir-candidates = @paths-to-dirs.map({ Candidate.new(:as($_), :uri($_), :dist(Zef::Distribution::Local.new($_))) }) if @paths-to-dirs;
        my @file-candidates = $client.fetch( @paths-to-files.map({ Candidate.new(:as($_), :uri($_)) }) ) if +@paths-to-files;
        my @path-candidates-to-check = |@dir-candidates, |@file-candidates;
        my (:@wanted-path-candidates, :@skip-path-candidates) := @path-candidates-to-check\
            .classify: {$client.is-installed($_.dist.identity, :@at) ?? <skip-path-candidates> !! <wanted-path-candidates>}
        say "The following local path candidates are already installed: {@skip-path-candidates.map(*.uri).join(', ')}"\
            if ($verbosity >= VERBOSE) && +@skip-path-candidates;
        my @path-candidates = ?$force-install ?? @path-candidates-to-check !! @wanted-path-candidates;


        # URIS
        my @uri-candidates-to-check = $client.fetch( @uris.map({ Candidate.new(:as($_), :uri($_)) }) ) if +@uris;
        abort "No candidates found matching uri: {@uri-candidates-to-check.join(', ')}" if +@uris && +@uri-candidates-to-check == 0;
        my (:@wanted-uris, :@skip-uris) := @uri-candidates-to-check\
            .classify: {$client.is-installed($_.dist.identity, :@at) ?? <skip-uris> !! <wanted-uris>}
        say "The following uri candidates are already installed: {@skip-uris.map(*.as).join(', ')}"\
            if ($verbosity >= VERBOSE) && +@skip-uris;
        my @requested-uris = (?$force-install ?? @uri-candidates-to-check !! @wanted-uris)\
            .grep: { $_ ~~ none(@path-candidates.map(*.dist.identity)) }
        my @uri-candidates = @requested-uris;


        # IDENTITIES
        my (:@wanted-identities, :@skip-identities) := @identities\
            .classify: {$client.is-installed($_, :@at) ?? <skip-identities> !! <wanted-identities>}
        say "The following candidates are already installed: {@skip-identities.join(', ')}"\
            if ($verbosity >= VERBOSE) && +@skip-identities;
        my @requested-identities = (?$force-install ?? @identities !! @wanted-identities)\
            .grep: { $_ ~~ none(@uri-candidates.map(*.dist.identity)) }
        my @requested  = $client.find-candidates(:$upgrade, @requested-identities) if +@requested-identities;
        abort "No candidates found matching identity: {@requested-identities.join(', ')}"\
            if +@requested-identities && +@requested == 0;


        my @prereqs    = $client.find-prereq-candidates(:skip-installed(not $contained), |@path-candidates, |@uri-candidates, |@requested)\
            if +@path-candidates || +@uri-candidates || +@requested;
        my @candidates = grep *.defined, ?$deps-only
            ?? @prereqs !! (|@path-candidates, |@uri-candidates, |@requested, |@prereqs);

        unless +@candidates {
            note("All candidates are currently installed");
            exit(0) if $deps-only;
            abort("No reason to proceed. Use --force-install to continue anyway", 0) unless $force-install;
        }

        my (:@local, :@remote) := @candidates.classify: {.dist ~~ Zef::Distribution::Local ?? <local> !! <remote>}
        my @fetched = grep *.so, |@local, ($client.fetch(@remote).Slip if +@remote && $fetch);

        my CompUnit::Repository @to = $install-to.map(*.&str2cur);
        my @installed  = $client.make-install( :@to, :$fetch, :$test, :$build, :$upgrade, :$update, :$dry, :$serial, @fetched );
        my @fail       = @candidates.grep: {.as !~~ any(@installed>>.as)}

        say "!!!> Install failures: {@fail.map(*.dist.identity).join(', ')}" if +@fail;
        exit +@installed && +@installed == +@candidates && +@fail == 0 ?? 0 !! 1;
    }

    #| Uninstall distributions
    multi sub MAIN(
        'uninstall',
        :from(:$uninstall-from),
        *@identities ($, *@)
    ) {
        my $client = get-client(:config($CONFIG));
        my CompUnit::Repository @from = $uninstall-from.grep(*.defined).map(*.&str2cur);

        my @uninstalled = $client.uninstall( :@from, @identities.map(*.&str2identity) );
        my @fail        = @identities.grep(* !~~ any(@uninstalled.map(*.as)));
        if +@uninstalled == 0 && +@fail {
            note("!!!> Found no matching candidates to uninstall");
            exit 1;
        }

        for @uninstalled.classify(*.from).kv -> $from, $candidates {
            say "===> Uninstalled from $from";
            say "$_" for |$candidates>>.dist>>.identity;
        }

        say "!!!> Failed to uninstall distributions: {@fail.join('. ')}" if +@fail;
        exit +@fail ?? 1 !! 0;
    }

    #| Get a list of possible distribution candidates for the given terms
    multi sub MAIN('search', Int :$wrap = False, :$update, *@terms ($, *@)) {
        my $client = get-client(:config($CONFIG), :$update);
        my @results = $client.search(@terms).unique(:as({ .from ~ ' ' ~ .dist.identity }));

        say "===> Found " ~ +@results ~ " results";

        my @rows = eager gather for @results -> $candi {
            FIRST { take [<ID From Package Description>] }
            take [ $++, $candi.from, $candi.dist.identity, ($candi.dist.meta<description> // '') ];
        }
        print-table(@rows, :$wrap);

        exit 0;
    }

    #| A list of available modules from enabled repositories
    multi sub MAIN('list', Int :$max, :$update, Bool :i(:$installed), *@at) {
        my $client = get-client(:config($CONFIG), :$update);

        my $found := ?$installed
            ?? $client.list-installed(@at.map(*.&str2cur))
            !! $client.list-available(@at);

        my $range := defined($max) ?? 0..+$max !! *;
        my %locations = $found[$range].classify: -> $candi { $candi.from }
        for %locations.kv -> $from, $candis {
            note "===> Found via {$from}";
            for $candis.sort(*.dist.identity) -> $candi {
                say "{$candi.dist.identity}";
                say "#\t{$_}" for @($candi.dist.provides.keys.sort if ?($verbosity >= VERBOSE));
            }
        }

        exit 0;
    }

    #| Upgrade installed distributions (BETA)
    multi sub MAIN(
        'upgrade',
        Bool :$fetch         = True,
        Bool :$build         = True,
        Bool :$test          = True,
        Bool :$depends       = True,
        Bool :$test-depends  = $test,
        Bool :$build-depends = $build,
        Bool :$force,
        Bool :$force-resolve = $force,
        Bool :$force-fetch   = $force,
        Bool :$force-extract = $force,
        Bool :$force-build   = $force,
        Bool :$force-test    = $force,
        Bool :$force-install = $force,
        Int  :$timeout,
        Int  :$fetch-timeout   = %*ENV<ZEF_FETCH_TIMEOUT>   // $timeout // 600,
        Int  :$extract-timeout = %*ENV<ZEF_EXTRACT_TIMEOUT> // $timeout // 3600,
        Int  :$build-timeout   = %*ENV<ZEF_BUILD_TIMEOUT>   // $timeout // 3600,
        Int  :$test-timeout    = %*ENV<ZEF_TEST_TIMEOUT>    // $timeout // 3600,
        Int  :$install-timeout = %*ENV<ZEF_INSTALL_TIMEOUT> // $timeout // 3600,
        Int  :$degree,
        Int  :$fetch-degree   = %*ENV<ZEF_FETCH_DEGREE> || $degree || 5, # default different from Zef::Client,
        Int  :$test-degree    = %*ENV<ZEF_TEST_DEGREE>  || $degree || 1,
        Bool :$dry,
        Bool :$update,
        Bool :$serial,
        :$exclude,
        :to(:$install-to) = %*ENV<ZEF_INSTALL_TO> // $CONFIG<DefaultCUR>,
        *@identities
    ) {
        # XXX: This is a very inefficient prototype. Not sure how to handle an 'upgrade' when
        # multiple versions are already installed, so for now an 'upgrade' always means we
        # leave the previous version installed.

        my $client = get-client(
            :config($CONFIG), :exclude($exclude.grep(*.defined).map({ Zef::Distribution::DependencySpecification.new($_) })),
            :$depends,        :$test-depends,    :$build-depends,
            :$force-resolve,  :$force-fetch,     :$force-extract,
            :$force-build,    :$force-test,      :$force-install,
            :$fetch-timeout,  :$extract-timeout, :$build-timeout,
            :$test-timeout,   :$install-timeout, :$fetch-degree,
            :$test-degree
        );

        my @missing = @identities.grep: { not $client.is-installed($_) };
        abort "Can't upgrade identities that aren't installed: {@missing.join(', ')}" if +@missing;

        my @installed = $client.list-installed($install-to.map(*.&str2cur))\
            .sort(*.dist.ver).sort(*.dist.api).reverse\
            .unique(:as({"{.dist.name}:auth<{.dist.auth-matcher}>"}));
        my @requested = +@identities
            ?? $client.find-candidates(@identities.map(*.&str2identity))
            !! $client.find-candidates(@installed.map(*.dist.clone(ver => "*")).map(*.identity).unique);

        my (:@upgradable, :@current, :@unknown) := @requested.classify: -> $candi {
            my $latest-installed = @installed.grep({ .dist.name eq $candi.dist.name })\
                .sort({ .dist.auth-matcher ne $candi.dist.auth-matcher }).head; # this is to handle auths that changed. need to find a better way...
            !$latest-installed ?? <unknown> !! (($latest-installed.dist.ver <=> $candi.dist.ver) === Order::Less) ?? <upgradable> !! <current>;
        }
        note "Unsure of how to handle the following distributions: {@unknown.map(*.dist.identity),join(',')}" if +@unknown;
        abort("All requested distributions are already at their latest versions", 0) unless +@upgradable;
        say "The following distributions will be upgraded: {@upgradable.map(*.dist.identity).join(', ')}";

        my &installer = &MAIN.assuming(
            :$depends,
            :$test-depends,
            :$build-depends,
            :$test,
            :$fetch,
            :$build,
            :$update,
            :$exclude,
            :$install-to,
            :$force-resolve,
            :$force-fetch,
            :$force-build,
            :$force-test,
            :$force-install,
            :$fetch-timeout,
            :$extract-timeout,
            :$build-timeout,
            :$test-timeout,
            :$fetch-degree,
            :$test-degree,
            :$dry,
            :$serial,
        );

        # Sort these ahead of time so they can be installed individually by passing
        # the .uri instead of the identities (which would require another search)
        my @sorted-candidates = $client.sort-candidates(@upgradable);
        say "===> Updating: " ~ @sorted-candidates.map(*.dist.identity).join(', ');
        my (:@upgraded, :@failed) := @sorted-candidates.map(*.uri).classify: -> $uri {
            my &*EXIT = sub ($code) { return $code == 0 ?? True !! False };
            try { &installer('install', $uri) } ?? <upgraded> !! <failed>;
        }
        abort "!!!> Failed upgrading *all* modules" unless +@upgraded;

        say "!!!> Some modules failed to update: {@failed.map(*.dist.identity).join(', ')}" if +@failed;
        exit +@upgraded < +@upgradable ?? 1 !! 0;
    }

    #| View dependencies of a distribution
    multi sub MAIN(
        'depends',
        $identity,
        Bool :$depends       = True,
        Bool :$test-depends  = True,
        Bool :$build-depends = True,
    ) {
        # TODO: refactor this stuff which was copied from 'install'
        # So really we just need a function to handle separating the different identity types
        # and optionally delivering a message for each section.
        my @wants = ($identity,).map: *.&str2identity;
        my (:@paths, :@uris, :@identities) := @wants.classify: -> $wanted {
            $wanted ~~ /^[\. | \/]/                               ?? <paths>
                !! ?Zef::Identity.new($wanted)                    ?? <identities>
                !! (my $uri = uri($wanted) and !$uri.is-relative) ?? <uris>
                !! abort("Don't understand identity: {$wanted}");
        }
        my $client = Zef::Client.new(:config($CONFIG), :$depends, :$test-depends, :$build-depends,);

        abort "The following were recognized as file paths but don't exist as such - {@paths.grep(!*.IO.e)}"
            if +@paths.grep(!*.IO.e);
        abort "The following were recognized as directory paths but don't contain a META6.json file - {@paths.grep(*.IO.d).grep(!*.IO.add('META6.json').e)}"
            if +@paths.grep(*.IO.d).grep(!*.IO.add('META6.json').e);
        my @path-candidates = @paths.map(*.&path2candidate);

        my @uri-candidates-to-check = $client.fetch( @uris.map({ Candidate.new(:as($_), :uri($_)) }) ) if +@uris;
        abort "No candidates found matching uri: {@uri-candidates-to-check.join(', ')}" if +@uris && +@uri-candidates-to-check == 0;
        my @uri-candidates = @uri-candidates-to-check.grep: { $_ ~~ none(@path-candidates.map(*.dist.identity)) }

        my @requested-identities = @identities.grep: { $_ ~~ none(@uri-candidates.map(*.dist.identity)) }
        my @requested = $client.find-candidates(@requested-identities) if +@requested-identities;
        abort "No candidates found matching identity: {@requested-identities.join(', ')}"\
            if +@requested-identities && +@requested == 0;

        my @prereqs = $client.find-prereq-candidates(:!skip-installed, |@path-candidates, |@uri-candidates, |@requested)\
            if +@path-candidates || +@uri-candidates || +@requested;

        .say for @prereqs.map(*.dist.identity);
    }

    #| View direct reverse dependencies of a distribution
    multi sub MAIN(
        'rdepends',
        $identity,
        Bool :$depends       = True,
        Bool :$test-depends  = True,
        Bool :$build-depends = True,
    ) {
        my $client = get-client(:config($CONFIG), :$depends, :$test-depends, :$build-depends);
        .dist.identity.say for $client.list-rev-depends($identity);
        exit 0;
    }

    #| Lookup locally installed distributions by short-name, name-path, or sha1 id
    multi sub MAIN('locate', $identity, Bool :$sha1) {
        my $client = get-client(:config($CONFIG));
        if !$sha1 {
            if $identity.ends-with('.rakumod' | '.pm6' | '.pm') {
                my @candis = $client.list-installed.grep({
                    .dist.meta<provides>.values.grep({parse-value($_) eq $identity}).so;
                });

                for @candis -> $candi {
                    LAST exit 0;
                    NEXT say '';

                    if $candi {
                        # This is relying on implementation details for compatibility purposes. It will
                        # use something more appropriate sometime in 2019.
                        my %meta = $candi.dist.meta;
                        %meta<provides> = %meta<provides>.map({ $_.key => parse-value($_.value) }).hash;
                        my $lib = %meta<provides>.hash.antipairs.hash.{$identity};
                        my $lib-sha1 = nqp::sha1($lib ~ CompUnit::Repository::Distribution.new($candi.dist).id);
                        my $curi = CompUnit::RepositoryRegistry.repository-for-spec($candi.from);

                        say "===> From Distribution: {~$candi.dist}";
                        say "{$lib} => {$curi.prefix.child('sources').child($lib-sha1)}";
                    }
                }
            }
            elsif $identity.starts-with('bin/' | 'resources/') {
                my @candis = $client.list-installed.grep({
                    .dist.meta<files>.first({.key eq $identity}).so
                });

                for @candis -> $candi {
                    LAST exit 0;
                    NEXT say '';

                    if $candi {
                        my $libs = $candi.dist.meta<files>;
                        my $lib  = $libs.first({.key eq $identity});
                        my $curi = CompUnit::RepositoryRegistry.repository-for-spec($candi.from);

                        say "===> From Distribution: {~$candi.dist}";
                        say "{$identity} => {$curi.prefix.child('resources').child($lib.value)}";
                    }
                }
            }
            elsif $client.resolve($identity) -> @candis {
                for @candis -> $candi {
                    LAST exit 0;
                    NEXT say '';

                    my $curi = CompUnit::RepositoryRegistry.repository-for-spec($candi.from);

                    say "===> From Distribution: {~$candi.dist}";
                    my $source-prefix = $curi.prefix.child('sources');
                    my $source-path   = $source-prefix.child(nqp::sha1($identity ~ CompUnit::Repository::Distribution.new($candi.dist).id));
                    say "{$identity} => {$source-path}" if $source-path.IO.f;
                }
            }
        }
        else {
            my @candis = $client.list-installed.grep(-> $candi {
                # This is relying on implementation details for compatibility purposes. It will
                # use something more appropriate sometime in 2019.
                my %meta = $candi.dist.meta;
                %meta<provides> = %meta<provides>.map({ $_.key => parse-value($_.value) }).hash;
                my @source_files   = %meta<provides>.map({ nqp::sha1($_.key ~ CompUnit::Repository::Distribution.new($candi.dist).id) });
                my @resource_files = %meta<files>.values.first({$_ eq $identity});
                $identity ~~ any(grep *.defined, flat @source_files, @resource_files);
            });

            for @candis -> $candi {
                LAST exit 0;
                NEXT say '';

                if $candi {
                    my %meta = $candi.dist.meta;
                    %meta<provides> = %meta<provides>.map({ $_.key => parse-value($_.value) }).hash;
                    my %sources = %meta<provides>.map({ $_.key => nqp::sha1($_.key ~ CompUnit::Repository::Distribution.new($candi.dist).id) }).hash;
                    my $curi = CompUnit::RepositoryRegistry.repository-for-spec($candi.from);

                    say "===> From Distribution: {~$candi.dist}";
                    $identity ~~ any(%sources.values)
                        ?? (say "{$_} => {$curi.prefix.child('sources').child($identity)}" for %sources.antipairs.hash{$identity})
                        !! (say "{.key} => {.value}" for $candi.dist.meta<files>.first({.value eq $identity}));

                }
            }
        }

        say "!!!> Nothing located";

        exit 1;
    }

    #| Detailed distribution information
    multi sub MAIN('info', $identity, :$update, Int :$wrap = False) {
        my $client = get-client(:config($CONFIG), :$update);
        my $latest-installed-candi = $client.resolve($identity).head;
        my @remote-candis = $client.find-candidates($identity, :strict);
        abort "!!!> Found no candidates matching identity: {$identity}"
            unless $latest-installed-candi || +@remote-candis;

        my $candi := ($latest-installed-candi, |@remote-candis).grep(*.defined).sort(*.dist.ver).sort(*.dist.api).tail;
        my $dist  := $candi.dist;

        say "- Info for: $identity";
        say "- Identity: {$dist.identity}";
        say "- Recommended By: {$candi.from}";
        say "- Installed: {$latest-installed-candi??$latest-installed-candi.dist.identity eq $dist.identity??qq|Yes|!!qq|Yes, as $latest-installed-candi.dist.identity()|!!'No'}";
        say "Author:\t {$dist.author}"                if $dist.author;
        say "Description:\t {$dist.description}"      if $dist.description;
        say "License:\t {$dist.meta<license>}"        if $dist.meta<license>;
        say "Source-url:\t {$dist.source-url}"        if $dist.source-url;

        my @provides = $dist.provides.sort(*.key.chars);
        say "Provides: {@provides.elems} modules";
        if ?($verbosity >= VERBOSE) {
            my @rows = eager gather for @provides -> $lib {
                FIRST {
                    take [<Module Path-Name>]
                }
                my $module-name = $lib.key;
                my $name-path   = parse-value($lib.value);
                take [ $module-name, $name-path ];
            }
            print-table(@rows, :$wrap);
        }

        if $dist.meta<support> {
            say "Support:";
            for $dist.meta<support>.kv -> $k, $v {
                say "#   $k:\t$v";
            }
        }

        my @deps = (|$dist.depends-specs, |$dist.test-depends-specs, |$dist.build-depends-specs).grep(*.defined).unique;
        say "Depends: {@deps.elems} items";
        if ?($verbosity >= VERBOSE) {
            my @rows = eager gather for @deps -> $spec {
                FIRST { take [<ID Identity Installed?>] }
                my $row = [ ++$, $spec.name, ($client.is-installed($spec) ?? '✓' !! '')];
                take $row;
            }
            print-table(@rows, :$wrap);
        }

        exit 0;
    }

    #| Browse a distribution's available support urls (homepage, bugtracker, source)
    multi sub MAIN('browse', $identity, $url-type where * ~~ any(<homepage bugtracker source>), Bool :$open = True) {
        my $client = get-client(:config($CONFIG));
        my $candi  = $client.resolve($identity).head
                ||   $client.search($identity, :strict, :max-results(1))[0]\
                ||   abort "!!!> Found no candidates matching identity: {$identity}";
        my %support  = $candi.dist.meta<support>;
        my $url      = %support{$url-type};
        my @has-urls = grep { %support{$_} }, <homepage bugtracker source>;
        unless $url && $url.starts-with('http://' | 'https://') {
            say "'browse' urls supported by $identity: {+@has-urls??@has-urls.join(',')!!'none'}";
            exit 255;
        }
        say $url;

        my @cmd = $*DISTRO.is-win          ?? <cmd /c start>
                !! $*VM.osname eq 'darwin' ?? <open>
                                           !! <xdg-open>;
        run( |@cmd, $url ) if $open;
    }

    #| Download a single module and change into its directory
    multi sub MAIN('look', $identity) {
        my $client     = get-client(:config($CONFIG));
        my @candidates = $client.find-candidates( str2identity($identity) );
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my (:@remote, :@local) := @candidates.classify: {.dist !~~ Zef::Distribution::Local ?? <remote> !! <local>}
        my $fetched = @local[0] || $client.fetch(@remote[0])[0] || abort "Failed to fetch candidate: $identity";
        my $dist-path = $fetched.dist.path;
        say "===> Shelling into directory: {$dist-path}";
        exit so shell(%*ENV<SHELL> // %*ENV<ComSpec> // %*ENV<COMSPEC>, :cwd($dist-path)) ?? 0 !! 1;
    }

    #| Smoke test
    multi sub MAIN(
        'smoke',
        Bool :$fetch         = True,
        Bool :$build         = True,
        Bool :$test          = True,
        Bool :$depends       = True,
        Bool :$test-depends  = $test,
        Bool :$build-depends = $build,
        Bool :$force,
        Bool :$force-resolve = $force,
        Bool :$force-fetch   = $force,
        Bool :$force-extract = $force,
        Bool :$force-build   = $force,
        Bool :$force-test    = $force,
        Bool :$force-install = $force,
        Int  :$timeout,
        Int  :$fetch-timeout   = %*ENV<ZEF_FETCH_TIMEOUT>   // $timeout // 600,
        Int  :$extract-timeout = %*ENV<ZEF_EXTRACT_TIMEOUT> // $timeout // 3600,
        Int  :$build-timeout   = %*ENV<ZEF_BUILD_TIMEOUT>   // $timeout // 3600,
        Int  :$test-timeout    = %*ENV<ZEF_TEST_TIMEOUT>    // $timeout // 3600,
        Int  :$install-timeout = %*ENV<ZEF_INSTALL_TIMEOUT> // $timeout // 3600,
        Int  :$degree,
        Int  :$fetch-degree   = %*ENV<ZEF_FETCH_DEGREE> || $degree || 5, # default different from Zef::Client,
        Int  :$test-degree    = %*ENV<ZEF_TEST_DEGREE>  || $degree || 1,
        Bool :$update,
        Bool :$upgrade,
        Bool :$dry,
        Bool :$serial,
        :$exclude,
        :to(:$install-to) = %*ENV<ZEF_INSTALL_TO> // $CONFIG<DefaultCUR>,
    ) {
        my $client = get-client(
            :config($CONFIG), :exclude($exclude.grep(*.defined).map({ Zef::Distribution::DependencySpecification.new($_) })),
            :$depends,        :$test-depends,    :$build-depends,
            :$force-resolve,  :$force-fetch,     :$force-extract,
            :$force-build,    :$force-test,      :$force-install,
            :$fetch-timeout,  :$extract-timeout, :$build-timeout,
            :$test-timeout,   :$install-timeout, :$fetch-degree,
            :$test-degree,
        );

        my @identities = $client.list-available.map(*.dist.identity).unique;
        say "===> Smoke testing with {+@identities} distributions...";

        my &installer = &MAIN.assuming(
            'install',
            :$depends,
            :$test-depends,
            :$build-depends,
            :$test,
            :$fetch,
            :$build,
            :$update,
            :$upgrade,
            :$exclude,
            :$install-to,
            :$force-resolve,
            :$force-fetch,
            :$force-build,
            :$force-test,
            :$force-install,
            :$fetch-timeout,
            :$extract-timeout,
            :$build-timeout,
            :$test-timeout,
            :$fetch-degree,
            :$test-degree,
            :$dry,
            :$serial,
        );

        for @identities -> $identity {
            my &*EXIT = sub ($code) { return $code == 0 ?? True !! False };
            my $result = try installer($identity);
            say "===> Smoke result for {$identity}: {?$result??'OK'!!'NOT OK'}";
        }

        exit 0;
    }

    #| Update package indexes
    multi sub MAIN('update', *@names) {
        my $client  = get-client(:config($CONFIG), :update(@names || Bool::True));

        if $verbosity >= VERBOSE {
            my $plugins := $client.recommendation-manager.plugins(|@names).map(*.List).flat.grep(*.defined);
            my $rows    := $plugins.map({ [.id, .available.elems] });
            print-table( [["Content Storage", "Distribution Count"], |$rows], wrap => True );
        }

        exit 0;
    }

    #| Nuke module installations (site, home) and repositories from config (StoreDir, TempDir)
    multi sub MAIN('nuke', Bool :$confirm, *@names ($, *@)) {
        my sub dir-delete($dir) {
            my @deleted = grep *.defined, try delete-paths($dir, :f, :d, :r);
            say "Deleted " ~ +@deleted ~ " paths from $dir/*";
        }
        my sub confirm-delete(*@dirs) {
            for @dirs -> $dir {
                next() R, say "$dir does not exist. Skipping..." unless $dir.IO.e;
                given prompt("Delete {$dir.IO.absolute}/* [y/n]: ") {
                    when any(<y Y>) { dir-delete($dir)   }
                    when any(<n N>) { say "Skipping..." }
                    default { say "Invalid entry (enter Y or N)"; redo }
                }
            }
        }

        my @config-keys = <StoreDir TempDir>;
        my @config-dirs = $CONFIG<<{@names (&) @config-keys}>>.map(*.IO.absolute).sort;

        my @curli-dirs = @names\
            .grep(* !~~ any(@config-keys))\
            .map(*.&str2cur)\
            .grep(*.?can-install)\
            .map(*.prefix.absolute);

        my @delete = |@curli-dirs, |@config-dirs;
        $confirm === False ?? @delete.map(*.&dir-delete) !! confirm-delete( @delete );

        exit 0;
    }

    #| Detailed version information
    multi sub MAIN(Bool :version($) where .so) {
        say $VERSION // 'unknown';

        exit 0;
    }

    multi sub MAIN(Bool :h(:help($))) {
        note qq:to/END_USAGE/
            Zef - Raku Module Management

            USAGE

                zef [flags|options] command [args]

                zef --version

            COMMANDS

                install                 Install specific dependencies by name or path
                uninstall               Uninstall specified distributions
                test                    Run tests on a given distribution path
                fetch                   Fetch and extract distribution source
                build                   Run the builder for given distribution path
                look                    Fetch followed by shelling into the distribution path
                update                  Update package indexes for repositories
                upgrade (BETA)          Upgrade specific distributions (or all if no arguments)
                search                  Show a list of possible distribution candidates for the given terms
                info                    Show detailed distribution information
                browse                  Open browser to various support urls (homepage, bugtracker, source)
                list                    List known available distributions, or installed distributions with `--installed`
                depends                 List all direct and transitive dependencies for a given identity
                rdepends                List all distributions directly depending on a given identity
                locate                  Lookup installed module information by short-name, name-path, or sha1 (with --sha1 flag)
                smoke                   Run smoke testing on available modules
                nuke                    Delete directory/prefix containing matching configuration path or CURLI name

            OPTIONS

                --install-to=[name]     Short name or spec of CompUnit::Repository to install to
                --config-path=[path]    Load a specific Zef config file
                --[phase]-timeout=[int] Set a timeout (in seconds) for the corresponding phase ( phase: fetch, extract, build, test, install )
                --[phase]-degree=[int]  Number of simultaneous distributions/jobs to process for the corresponding phase ( phase : fetch, test )

                --update                Force a refresh for all module indexes
                --update=[ecosystem]    Force a refresh for a specific ecosystem module index

                --/update               Skip refreshing all module indexes
                --/update=[ecosystem]   Skip refreshing for a specific ecosystem module index

            ENV OPTIONS

                ZEF_[phase]_TIMEOUT     See --[phase]-timeout ( phases: FETCH, BUILD, TEST, INSTALL )
                ZEF_[phase]_DEGREE      See --[phase]-degree ( phases: FETCH, TEST )
                ZEF_INSTALL_TO          See --install-to
                ZEF_CONFIG_PATH         Set the path to the config file zef should use
                ZEF_CONFIG_DEFAULTCUR   Override DefaultCUR from the config file
                ZEF_CONFIG_STOREDIR     Override StoreDir from the config file
                ZEF_CONFIG_TEMPDIR      Override TempDir from the config file

            VERBOSITY LEVEL (from least to most verbose)
                --error, --warn, --info (default), --verbose, --debug

            FLAGS
                --deps-only             Install only the dependency chains of the requested distributions
                --dry                   Run all phases except the actual installations
                --serial                Install each dependency after passing testing and before building/testing the next dependency
                --contained (BETA)      Install all transitive and direct dependencies regardless if they are already installed globally

                --/test                 Skip the testing phase
                --/build                Skip the building phase

                --/depends              Do not fetch runtime dependencies
                --/test-depends         Do not fetch test dependencies
                --/build-depends        Do not fetch build dependencies

            FORCE FLAGS
                Ignore errors occuring during the corresponding phase:
                --force-resolve --force-fetch --force-extract --force-build --force-test --force-install

            CONFIGURATION {$CONFIG.IO.absolute}
                Enable or disable plugins that match the configuration that has field `short-name` that matches <short-name>

                --<short-name>  # `--fez`  Enable plugin with short-name `fez`
                --/<short-name> # `--/fez` Disable plugin with short-name `fez`

            END_USAGE
    }

    proto sub abort(|) {*}
    multi sub abort(Int $exit-code, Str $str) { samewith($str, $exit-code) }
    multi sub abort(Str $str, Int $exit-code = 255) { say $str; exit $exit-code }

    # Filter/mutate out verbosity flags from @*ARGS and return a verbosity level
    my sub preprocess-args-verbosity-mutate(*@_) {
        my (:@log-level, :@filtered-args) := @_.classify: {
            $_ ~~ any(<--fatal --error --warn --info -v --verbose --debug --trace>)
                ?? <log-level>
                !! <filtered-args>;
        }
        @*ARGS = @filtered-args;
        do given any(@log-level) {
            when '--fatal'   { FATAL   }
            when '--error'   { ERROR   }
            when '--warn'    { WARN    }
            when '--info'    { INFO    }
            when '--verbose' { VERBOSE }
            when '-v'        { VERBOSE }
            when '--debug'   { DEBUG   }
            when '--trace'   { TRACE   }
            default          { INFO    }
        }
    }

    # Second crack at cli config modification
    # Currently only uses Bools `--name` and `--/name` to enable and disable a plugin
    # Note that `name` can match the config plugin key `short-name` or `module`
    # * Now also removes --config-path $path parameters
    # TODO: Turn this into a more general getopts
    my sub preprocess-args-config-mutate(*@args) {
        # get/remove --config-path=xxx
        # MUTATES @*ARGS
        my Str $config-path-from-args;
        for |@args.map(*.split(/\=/, 2)).flat.rotor(2 => -1, :partial) {
            $config-path-from-args = ~$_[1] if $_[0] eq '--config-path' && $_[1];
            LAST {
                @*ARGS = eager gather for |@args.kv -> $key, $value {
                    take($value) unless $value.starts-with('--config-path')
                        || ($key > 0 && @args[$key - 1] eq '--config-path')
                }
            }
        }
        my $chosen-config-file = $config-path-from-args // %*ENV<ZEF_CONFIG_PATH> // Zef::Config::guess-path();

        # Keep track of the original path so we can show it on the --help usage :-/
        my $config = do {
            # The .Str.IO thing is due to a weird rakudo bug I can't figure out .
            # A bare .IO will complain that its being called on a type Any (not true)
            my $IO   = $chosen-config-file.Str.IO;
            my %hash = Zef::Config::parse-file($chosen-config-file).hash;
            class :: {
                has $.IO;
                has %.hash handles <AT-KEY EXISTS-KEY DELETE-KEY push append iterator list kv keys values>;
            }.new(:%hash, :$IO);
        }

        # - Move named options to start of @*ARGS so the git familiar style of options after positional parameters works
        # - get/remove --$short-name and --/$short-name where $short-name is a value in the config file
        my $plugin-lookup := Zef::Config::plugin-lookup($config.hash);
        for @*ARGS -> $arg {
            state @positional;
            state @named;
            LAST { @*ARGS = flat @named, @positional; }

            my $arg-as  = $arg.subst(/^["--" | "--\/"]/, '');
            my $enabled = $arg.starts-with('--/') ?? 0 !! 1;
            $arg.starts-with('-')
                ?? $arg-as ~~ any($plugin-lookup.keys)
                    ?? (for |$plugin-lookup{$arg-as} -> $p { $p<enabled> = $enabled })
                    !! @named.append($arg)
                !! @positional.append($arg);
        }
        $config;
    }

    my sub get-client(*%_) {
        my $client   = Zef::Client.new(|%_);
        my $logger   = $client.logger;
        my $stdout   = $logger.Supply.grep({ .<level> <= $verbosity });
        my $reporter = $logger.Supply.grep({
                (.<stage> == TEST  && .<phase> == AFTER)
            ||  (.<level> == ERROR && .<phase> == AFTER)
            ||  (.<level> == FATAL && .<phase> == AFTER)
        });
        $stdout.tap: -> $m {
            given $m.<phase> {
                when BEFORE { say "===> {$m.<message>}" }
                when AFTER  { say "===> {$m.<message>}" }
                default     {
                    # Prefix output with a name that references its source since
                    # lines may be coming from many sources at once.
                    my $line-prefix = ((.dist??.dist.meta<name>!!Nil) // .as) with $m.<candi>;
                    say($line-prefix ?? "[$line-prefix] $_" !! $_) for $m.<message>.lines;
                }
            }
        }
        $reporter.grep({ .<candi> }).tap: {
            $client.reporter.report(.<candi>, :$logger);
        };

        with %_<update> {
            my @plugins = $client.recommendation-manager.plugins.map(*.Slip).grep(*.defined);

            if %_<update> === Bool::False {
                @plugins.map({ try .auto-update = False });
            }
            elsif %_<update> === Bool::True {
                @plugins.race(:batch(1)).map(*.?update);
            }
            else {
                @plugins.grep({.short-name ~~ any(%_<update>.grep(*.not))}).map({ try .auto-update = False });
                @plugins.grep({.short-name ~~ any(%_<update>.grep(*.so))}).race(:batch(1)).map(*.?update);
            }
        }

        $client;
    }

    # maybe its a name, maybe its a spec/path. either way  Zef::App methods take a CURs, not strings
    my sub str2cur($target) {
        my $named-repo = CompUnit::RepositoryRegistry.repository-for-name($target);
        return $named-repo if $named-repo;

        # first try 'site', then try 'home'
        if $target eq 'auto' {
            state $cur =
                first { .can-install() },
                map   { CompUnit::RepositoryRegistry.repository-for-name($_) },
                <site home>;
            return $cur if $cur;
        }

        # Technically a path without any short-id# is a CURFS, but now it needs to be explicitly declared file#
        # so that the more common case can be used without the prefix (inst#). This only applies when the path
        # exists, so that short-names (site, home) that don't exist still throw errors instead of creating a directory.
        my $spec-target = $target ~~ m/^\w+\#.*?[\. | \/]/
            ?? $target
            !! $target.IO.e
                ?? "inst#{$target}"
                !! $target;

        return CompUnit::RepositoryRegistry.repository-for-spec(~$spec-target, :next-repo($*REPO));
    }

    my sub path2candidate($path) {
        Candidate.new(
            as   => $path,
            uri  => $path.IO.absolute,
            dist => Zef::Distribution::Local.new($path),
        )
    }

    # prints a table with rows and columns. expects a header row.
    # automatically adjusts column widths, as well as `yada`ing
    # any characters on a line past $max-width
    my sub print-table(@rows, Int :$wrap = 120) {
        # this ugly thing is so users can pass in Bool or Int as a MAIN argument
        my $max-width = $wrap === Bool::True ?? 0 !! $wrap;

        # returns formatted row
        my sub _row2str (@widths, @cells, Int :$max) {
            my $format = @widths.map({"%-{$_}s"}).join('|');
            my $str    = sprintf( $format, @cells.map({ $_ // '' }) );
            return $str unless ?$max && $str.chars > $max;

            my $cutoff = $str.substr(0, $max || $str.chars);
            return $cutoff unless $cutoff.chars > 3;
            return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-3,3) ~~ /\S\S\S/;
            return ($cutoff.substr(0,*-2) ~ '..')  if $cutoff.substr(*-2,2) ~~ /\S\S/;
            return ($cutoff.substr(0,*-1) ~ '.')   if $cutoff.substr(*-1,1) ~~ /\S/;
            return $cutoff;

        }

        # Iterate over ([1,2,3],[2,3,4,5],[33,4,3,2]) to find the longest string in each column
        my sub _get_column_widths ( *@rows ) {
            return @rows[0].keys.map: { @rows>>[$_]>>.chars.max }
        }

        my @widths     = _get_column_widths(@rows);
        my @fixed-rows = @rows.map: { _row2str(@widths, @$_, :max($max-width)) }
        if +@fixed-rows {
            my $width = [+] _get_column_widths(@fixed-rows);
            my $sep   = '-' x $width;
            say "{$sep}\n{@fixed-rows[0]}\n{$sep}";
            .say for @fixed-rows[1..*];
            say $sep;
        }
    }

    my sub parse-value($str-or-kv) {
        do given $str-or-kv {
            when Str  { $_ }
            when Hash { $_.keys[0] }
            when Pair { $_.key     }
        }
    }
}
