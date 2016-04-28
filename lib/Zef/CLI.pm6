use Zef::Client;
use Zef::Config;
use Zef::Utils::FileSystem;
use Zef::Identity;
use Zef::Distribution;
use Zef::Utils::SystemInfo;

# Content was cut+pasted from bin/zef, leaving bin/zef's contents as just: `use Zef::CLI;`
# This allows the bin/zef original code to be precompiled, halving bare start up time.
# Ideally this all ends up back in bin/zef once/if precompilation of scripts is handled in CURI
package Zef::CLI {
    # Basically a top level of option that every CLI option would use, so centralize it here
    my $VERBOSITY = do given any(@*ARGS) {
        when /'--fatal'/
            { FATAL }
        when /'--error'/
            { ERROR }
        when /'--warn'/
            { WARN }
        when /'--info'/
            { INFO }
        when /'-v' | '--verbose'/
            { VERBOSE }
        when /'--debug'/
            { DEBUG }
        when /'--trace'/
            { TRACE }

        default
            { INFO }
    }
    @*ARGS = @*ARGS.grep: {$_ !~~ /"--fatal" | "--error" | "--warn" | "--info" | "-v" | "--verbose" | "--debug" | "--trace"/ }

    # Second crack at cli config modification
    # Currently only uses Bools `--name` and `--/name` to enable and disable a plugin
    # Note that `name` can match the config plugin key `short-name` or `module`
    # TODO: accept --name="key.subkey=xxx" format for setting explicit parameters
    my $config = ZEF-CONFIG() andthen do {
        my $plugin-lookup := config-plugin-lookup($config);
        @*ARGS = eager gather for @*ARGS -> $arg {
            my $arg-as  = $arg.subst(/^ ["--" | "--\/"]/, '');
            my $enabled = $arg.starts-with('--/') ?? 0 !! 1;
            $arg-as ~~ any($plugin-lookup.keys)
                ?? (for |$plugin-lookup{$arg-as} -> $p { $p<enabled> = $enabled })
                !! take($arg);
        }
    }

    #| Download specific distributions
    multi MAIN('fetch', Bool :$force, *@identities ($, *@)) is export {
        my $client = get-client(:$config, :$force);
        my @candidates = |$client.find-candidates(|@identities>>.&str2identity);
        die "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my @fetched    = |$client.fetch(|@candidates);
        my @fail       = |@candidates.grep: {.as !~~ any(@fetched>>.as)}

        say "!!!> Fetch failed: {.as}{?($VERBOSITY >= VERBOSE)??' at '~.dist.path!!''}" for @fail;

        exit +@fetched && +@fetched == +@candidates && +@fail == 0 ?? 0 !! 1;
    }

    #| Run tests
    multi MAIN('test', Bool :$force, *@paths ($, *@)) is export {
        my $client     = get-client(:$config, :$force);
        my @candidates = |$client.link-candidates( @paths.map(*.&path2candidate) );
        die "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my @tested = |$client.test(|@candidates);
        my (:@test-pass, :@test-fail) := @tested.classify: {.test-results.grep(*.so) ?? <test-pass> !! <test-fail> }

        say "!!!> Testing failed: {.as}{?($VERBOSITY >= VERBOSE)??' at '~.dist.path!!''}" for @test-fail;

        exit ?@test-fail ?? 1 !! ?@test-pass ?? 0 !! 255;
    }

    #| Run Build.pm
    multi MAIN('build', Bool :$force, *@paths ($, *@)) is export {
        my $client = get-client(:$config, :$force);
        my @candidates = |$client.link-candidates( @paths.map(*.&path2candidate) );
        die "Failed to resolve any candidates. No reason to proceed" unless +@candidates;

        my @built = |$client.build(|@candidates);
        my (:@pass, :@fail) := @built.classify: {$_.?build-results !=== False ?? <pass> !! <fail> }

        say "!!!> Build failure: {.as}{?($VERBOSITY >= VERBOSE)??' at '~.dist.path!!''}" for @fail;

        exit ?@fail ?? 1 !! ?@pass ?? 0 !! 255;
    }

    #| Install
    multi MAIN(
        'install',
        Bool :$depends       = True,
        Bool :$test-depends  = True,
        Bool :$build-depends = True,
        Bool :$test          = True,
        Bool :$fetch         = True,
        Bool :$force,
        Bool :$dry,
        Bool :$update,
        Bool :$upgrade,
        Bool :$depsonly,
        :$exclude is copy,
        :to(:$install-to) = ['site'],
        *@wants ($, *@)
    ) is export {

        @wants .= map: *.&str2identity;
        my (:@paths, :@urls, :@identities) := @wants.classify: -> $wanted {
            $wanted ~~ /^[\. | \/]/                                           ?? <paths>
                !! ?Zef::Identity($wanted)                                    ?? <identities>
                !! (my $uri = Zef::Utils::URI($wanted) and !$uri.is-relative) ?? <urls>
                !! die("Don't understand identity: {$wanted}");
        }

        my @excluded =  $exclude.map(*.&identity2spec);

        my $client   = get-client(:$config, :exclude(|@excluded), :$force, :$depends, :$test-depends, :$build-depends);

        my (:@wanted-identities, :@skip-identities) := @identities\
            .classify: {$client.is-installed($_) ?? <skip-identities> !! <wanted-identities>}
        say "The following candidates are already installed: {@skip-identities.join(', ')}"\
            if ($VERBOSITY >= VERBOSE) && +@skip-identities;

        my @path-candidates = @paths.map(*.&path2candidate);
        die "No candidates found matching: {@paths.join(', ')}" if +@paths && +@path-candidates == 0;

        my @url-candidates  = $client.fetch( |@urls.map({ Candidate.new(:as($_), :uri($_)) }) ) if +@urls;
        die "No candidates found matching: {@url-candidates.join(', ')}" if +@urls && +@url-candidates == 0;

        my @requested-identities = (?$force ?? @identities !! @wanted-identities)\
            .grep: { $_ ~~ none(@url-candidates.map(*.dist.identity)) }
        my @requested  = |$client.find-candidates(:$upgrade, |@requested-identities) if +@requested-identities;
        die "No candidates found matching: {@requested-identities.join(', ')}"\
            if +@requested-identities && +@requested == 0;

        my @prereqs    = |$client.find-prereq-candidates(|@path-candidates, |@url-candidates, |@requested)\
            if +@path-candidates || +@url-candidates || +@requested;

        my @candidates = grep *.defined, ?$depsonly
            ??|@prereqs !! (|@path-candidates, |@url-candidates, |@requested, |@prereqs);
        unless +@candidates {
            note("All candidates are currently installed");
            (?$depsonly || ?$force) ?? exit(0) !! die("No reason to proceed. Use --force to continue anyway");
        }

        my (:@local, :@remote) := @candidates.classify: {.dist ~~ Zef::Distribution::Local ?? <local> !! <remote>}
        my @fetched = grep *.so, |@local, ($client.fetch(|@remote).Slip if +@remote);

        my CompUnit::Repository @to = $install-to.map(*.&str2cur);
        my @installed  = |$client.install( :@to, :$test, :$upgrade, :$update, :$dry, |@fetched );
        my @fail       = |@candidates.grep: {.as !~~ any(@installed>>.as)}

        say "!!!> Install failures: {@fail.map(*.dist.identity).join(', ')}" if +@fail;
        exit +@installed && +@installed == +@candidates && +@fail == 0 ?? 0 !! 1;
    }

    #| Uninstall
    multi MAIN('uninstall', Bool :$force, :from(:$uninstall-from) = ['site'], *@identities ($, *@)) is export {
        my $client = get-client(:$config, :$force);
        my CompUnit::Repository @from = $uninstall-from.map(*.&str2cur);
        die "`uninstall` command currently requires a bleeding edge version of rakudo"\
            unless any(@from>>.can('uninstall'));

        my %uninstalled = $client.uninstall( :@from, |@identities>>.&str2identity ).classify(*.from);
        for %uninstalled.kv -> $from, $candidates {
            say "===> Uninstalled from $from";
            say "$_" for |$candidates>>.dist>>.identity;
        }

        exit %uninstalled.keys ?? 0 !! 1;
    }

    #| Get a list of possible distribution candidates for the given terms
    multi MAIN('search', Int :$wrap = False, *@terms ($, *@)) is export {
        my $client = get-client(:$config);
        my @results = $client.search(|@terms);

        say "===> Found " ~ +@results ~ " results";

        my @rows = eager gather for @results -> $candi {
            FIRST { take [<ID From Package Description>] }
            take [ "{state $id += 1}", $candi.from, $candi.dist.identity, ($candi.dist.hash<description> // '') ];
        }
        print-table(@rows, :$wrap);

        exit 0;
    }

    #| A list of available modules from enabled content storages
    multi MAIN('list', Int :$max?, Bool :i(:$installed), *@at) is export {
        my $client = get-client(:$config);

        my $found := ?$installed
            ?? $client.list-installed(|@at.map(*.&str2cur))
            !! $client.list-available(|@at);

        my $range := defined($max) ?? 0..+$max !! *;
        my %locations = $found[$range].classify: -> $candi { $candi.from }
        for %locations.kv -> $from, $candis {
            say "===> Found via {$from}";
            for |$candis -> $candi {
                say "{$candi.dist.identity}";
                say "#\t{$_}" for @($candi.dist.provides.keys.sort if ?($VERBOSITY >= VERBOSE));
            }
        }

        exit 0;
    }

    #| View reverse dependencies of a distribution
    multi MAIN('rdepends', $identity) {
        my $client = get-client(:$config);
        .dist.identity.say for $client.list-rev-depends($identity);
        exit 0;
    }

    #| Detailed distribution information
    multi MAIN('info', $identity, Int :$wrap = False) is export {
        my $client = get-client(:$config);
        my $candi  = $client.search($identity, :max-results(1))[0]\
            or die "Found no candidates matching identity: {$identity}";
        my $dist  := $candi.dist;

        say "- Info for: $identity";
        say "- Identity: {$dist.identity}";
        say "- Recommended By: {$candi.from}";
        say "Author:\t {$dist.author}"           if $dist.author;
        say "Description:\t {$dist.description}" if $dist.description;
        say "Source-url:\t {$dist.source-url}"   if $dist.source-url;

        my @provides = $dist.provides.keys.sort(*.chars);
        say "Provides: {@provides.elems} modules";
        if ?($VERBOSITY >= VERBOSE) { say "#\t$_" for $dist.provides.keys.sort(*.chars).sort }

        if $dist.hash<support> {
            say "Support:";
            for $dist.hash<support>.kv -> $k, $v {
                say "#   $k:\t$v";
            }
        }

        my @deps = (|$dist.depends-specs, |$dist.test-depends-specs, |$dist.build-depends-specs).grep(*.defined).unique;
        say "Depends: {@deps.elems} items";
        if ?($VERBOSITY >= VERBOSE) {
            my @rows = eager gather for @deps -> $spec {
                FIRST { take [<ID Identity Installed?>] }
                my $row = [ "{state $id += 1}", $spec.name, ($client.is-installed($spec) ?? '✓' !! '')];
                take $row;
            }
            print-table(@rows, :$wrap);
        }

        exit 0;
    }

    #| Download a single module and change into its directory
    multi MAIN('look', $identity, Bool :$force) is export {
        my $client     = get-client(:$config, :$force);
        my @candidates = |$client.find-candidates( str2identity($identity) );
        die "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my (:@remote, :@local) := @candidates.classify: {.dist !~~ Zef::Distribution::Local ?? <remote> !! <local>}
        my $fetched = @local[0] || |$client.fetch(@remote[0])[0] || die "Failed to fetch candidate: $identity";
        my $dist-path = $fetched.dist.path;
        say "===> Shelling into directory: {$dist-path}";
        exit so shell(%*ENV<SHELL> // %*ENV<ComSpec> // %*ENV<COMSPEC>, :cwd($dist-path)) ?? 0 !! 1;
    }

    #| Smoke test
    multi MAIN(
        'smoke',
        Bool :$depends       = True,
        Bool :$test-depends  = True,
        Bool :$build-depends = True,
        Bool :$test          = True,
        Bool :$fetch         = True,
        Bool :$force,
        Bool :$update,
        Bool :$upgrade,
        Bool :$depsonly,
        :$exclude is copy,
        :to(:$install-to) = ['site'],
    ) is export {
        my @excluded =  $exclude.map(*.&identity2spec);
        my $client   = get-client(:$config, :exclude(|@excluded), :$force, :$depends, :$test-depends, :$build-depends);
        my @identities              = $client.available.values.flatmap(*.keys).unique;
        my CompUnit::Repository @to = $install-to.map(*.&str2cur);
        say "===> Smoke testing with {+@identities} distributions...";

        # We only need to test a specific identity once. `.install` returns the installed
        # candidates so each iteration we can add any new dists to %skip for when we encounter
        # them through the for loop. XXX: should probably pass in :exclude(%skip>>.values)
        for @identities -> $identity {
            state %skip;
            next if %skip{$identity}++;
            my @installed = try $client.install( :@to, :$fetch, :$test, $identity );
            %skip{$_.dist.identity}++ for @installed;
        }

        exit 0;
    }

    #| Update package indexes
    multi MAIN('update', *@names) is export {
        my $client  = get-client(:$config);
        my %results = $client.storage.update(|@names);
        my $rows    = |%results.map: {[.key, .value]};
        die "An unknown plugin name used" if +@names && (+@names > +$rows);

        print-table( [["Content Storage", "Distribution Count"], |$rows], wrap => True );

        exit 0;
    }

    #| Nuke module installations (site, home) and storages from config (RootDir, StoreDir, TempDir)
    multi MAIN('nuke', Bool :$confirm, *@names ($, *@)) {
        my sub dir-delete($dir) {
            my @deleted = grep *.defined, try delete-paths($dir, :f, :d, :r);
            say "Deleted " ~ +@deleted ~ " paths from $dir/*";
        }
        my sub confirm-delete(*@dirs) {
            for @dirs -> $dir {
                next() R, say "$dir does not exist. Skipping..." unless $dir.IO.e;
                given prompt("Delete {$dir.path}/* [y/n]: ") {
                    when any(<y Y>) { dir-delete($dir)   }
                    when any(<n N>) { say "Skipping..." }
                    default { say "Invalid entry (enter Y or N)"; redo }
                }
            }
        }

        my @config-keys = <RootDir StoreDir TempDir>;
        my @config-dirs = $config<<{@names (&) @config-keys}>>.map(*.IO.absolute).sort;

        my @curli-dirs = @names\
            .grep(* !~~ any(@config-keys))\
            .map(*.&str2cur)\
            .grep(*.?can-install)\
            .map(*.prefix.absolute);

        my @delete = |@curli-dirs, |@config-dirs;
        $confirm === False ?? @delete.map(*.&dir-delete) !! confirm-delete( |@delete );

        exit 0;
    }

    multi MAIN(Bool :h(:$help)?) {
        note qq:to/END_USAGE/
            Zef - Perl6 Module Management

            USAGE

                zef [flags|options] command [args]


            COMMANDS

                install                 Install specific dependencies by name or path
                uninstall               Uninstall specified distributions
                test                    Run tests on a given module's path
                fetch                   Fetch and extract module's source
                build                   Run the Build.pm in a given module's path
                look                    `fetch` followed by shelling into the module's path
                update                  Update package indexes for content storages
                search                  Show a list of possible distribution candidates for the given terms
                info                    Show detailed distribution information
                list                    List known available distributions, or installed distributions with `--installed`
                rdepends                List all distributions directly depending on a given identity
                smoke                   Run smoke testing on available modules
                nuke                    Delete directory/prefix containing matching configuration path or CURLI name

            OPTIONS

                --install-to=[name]     Short name or spec of CompUnit::Repository to install to

            VERBOSITY LEVEL (from least to most verbose)
                --error, --warn, --info (default), --verbose, --debug

            FLAGS
                --depsonly              Install only the dependency chains of the requested distributions
                --force                 Continue each phase regardless of failures
                --dry                   Run all phases except the actual installations

                --/tests                Skip the testing phase
                --/depends              Do not fetch runtime dependencies
                --/test-depends         Do not fetch test dependencies
                --/build-depends        Do not fetch build dependencies

            CONFIGURATION {find-config().IO.absolute}
                Enable or disable plugins that match the configuration that has field `short-name` that matches <short-name>

                --<short-name>  # `--cpan`  Enable plugin with short-name `cpan`
                --/<short-name> # `--/cpan` Disable plugin with short-name `cpan`

            END_USAGE
    }

    sub get-client(*%_) {
        my $client = Zef::Client.new(|%_);
        my $logger = $client.logger;
        my $log    = $logger.Supply.grep({ .<level> <= $VERBOSITY });
        $log.tap: -> $m {
            given $m.<phase> {
                when BEFORE { say "===> {$m.<message>}" }
                when AFTER  { say "===> {$m.<message>}" }
                default     { say $m.<message> }
            }
        }
        $client;
    }

    # maybe its a name, maybe its a spec/path. either way  Zef::App methods take a CURs, not strings
    sub str2cur($target) {
        $ = CompUnit::RepositoryRegistry.repository-for-name($target)
        || CompUnit::RepositoryRegistry.repository-for-spec(~$target, :next-repo($*REPO));
    }

    sub path2candidate($path) {
        Candidate.new(
                as   => $path,
                uri  => $path.IO.absolute,
                dist => Zef::Distribution::Local.new($path),
        )
    }

    sub identity2spec($identity) {
        Zef::Distribution::DependencySpecification.new($identity);
    }

    # prints a table with rows and columns. expects a header row.
    # automatically adjusts column widths, as well as `yada`ing
    # any characters on a line past $max-width
    sub print-table(@rows, Int :$wrap) {
        # this ugly thing is so users can pass in Bool or Int as a MAIN argument
        my $max-width = ($*OUT.t && $wrap.perl eq 'Bool::False')
            ?? GET-TERM-COLUMNS()
            !! $wrap.perl eq 'Bool::True'
                ?? 0 
                !! $wrap;

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
        my sub _get_column_widths ( *@rows ) is export {
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
}
