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
    # First crack at cli config modification
    # -C<config key>="<name of item>.<field>=<new value>"
    # example: -CContentStorage="cpan.enabled=1"
    # Notice this only works with the plugin configuration structure: `"key" : [{"name":"foo", ...},{"name":"bar", ...}]`
    # For now its really just a way to enable cpan so people can play with it easier.
    our $config = ZEF-CONFIG();
    for @*ARGS -> $conf {
        if $conf.starts-with('-C') && $conf.contains('=') {
            my ($key, $value)                 = $conf.substr(2).split(/'='/, 2);
            my ($plugin-name, $plugin-option) = $value.split(/'.'/, 2);
            my ($plugin-key, $plugin-value)   = $plugin-option.split(/'='/, 2);
            for $config{$key}.grep(*.<name> eq $plugin-name) -> $conf is rw {
                $conf{$plugin-key} = $plugin-value;
            }
        }
    }
    @*ARGS = @*ARGS.grep(* !~~ /^'-C' .+/);

    #| Download specific distributions
    multi MAIN('fetch', Bool :$depends, Bool :$test-depends, Bool :$build-depends, Bool :v(:$verbose), *@identities) is export {
        my $client     = Zef::Client.new(:$config, :$verbose, :$depends, :$test-depends, :$build-depends);
        my @candidates = |$client.candidates(|@identities>>.&str2identity);
        my @fetched-candidates = $client.fetch(|@candidates);
        say "===> Fetched: {.as}\n{.uri.IO.absolute}" for @fetched-candidates;
        exit +@candidates && +@fetched-candidates == +@candidates ?? 0 !! 1;
    }

    #| Run tests
    multi MAIN('test', Bool :$force, Bool :v(:$verbose), *@paths) {
        my $client  = Zef::Client.new(:$config, :$verbose, :$force);
        my %results = $client.test(|@paths);
        exit %results.values.flatmap(*.flat).grep(*.not).elems;
    }

    #| Install
    multi MAIN('install', Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True,
                Bool :v(:$verbose), Bool :$force, Bool :$test = True, Bool :$fetch = True, :$exclude is copy,
                Bool :$dry, Bool :$update, Bool :$upgrade, Bool :$depsonly, :to(:$install-to) = ['site'], *@identities) is export {

        $exclude = grep *.defined, ?$depsonly ?? (|@identities>>.&str2identity, |$exclude) !! $exclude;
        my $client = Zef::Client.new(:$config, :$exclude, :$force, :$verbose, :$depends, :$test-depends, :$build-depends);
        my CompUnit::Repository @to = $install-to.map(*.&str2cur);
        exit ?$client.install( :@to, :$fetch, :$test, :$upgrade, :$update, :$dry, |@identities>>.&str2identity ) ?? 0 !! 1;
    }

    #| Uninstall
    multi MAIN('uninstall', Bool :v(:$verbose), Bool :$force, :from(:$uninstall-from) = ['site'], *@identities) is export {
        my $client = Zef::Client.new(:$config, :$force, :$verbose);
        my CompUnit::Repository @from = $uninstall-from.map(*.&str2cur);
        die "`uninstall` command currently requires a bleeding edge version of rakudo" unless any(@from>>.can('uninstall'));

        my %uninstalled = $client.uninstall( :@from, |@identities>>.&str2identity ).classify(*.from);
        for %uninstalled.kv -> $from, $candidates {
            say "===> Uninstalled from $from";
            say "$_" for |$candidates>>.dist>>.identity;
        }

        exit %uninstalled.keys ?? 0 !! 1;
    }

    #| Get a list of possible distribution candidates for the given terms
    multi MAIN('search', Int :$wrap = False, Bool :v(:$verbose), *@terms) is export {
        my $client  = Zef::Client.new(:$config, :$verbose);
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
    multi MAIN('list', Bool :v(:$verbose), Bool :i(:$installed), *@at) is export {
        my $client = Zef::Client.new(:$config, :$verbose);

        my $found = ?$installed
            ?? $client.list-installed(|@at.map(*.&str2cur))
            !! $client.list-available(|@at);

        my %locations = $found.classify: -> $candi { $candi.from }
        for %locations.kv -> $from, $candis {
            say "===> Found via {$from}";
            for |$candis -> $candi {
                say "{$candi.dist.identity}";
                say "#\t{$_}" for @($candi.dist.provides.keys.sort if ?$verbose);
            }
        }

        exit 0;
    }

    multi MAIN('rdepends', $identity) {
        my $client = Zef::Client.new(:$config);
        .dist.identity.say for $client.list-rev-depends($identity);
        exit 0;
    }

    #| Detailed distribution information
    multi MAIN('info', $identity, Int :$wrap = False, Bool :v(:$verbose)) is export {
        my $client = Zef::Client.new(:$config, :$verbose);
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
        if $verbose { say "#\t$_" for $dist.provides.keys.sort(*.chars).sort }

        if $dist.hash<support> {
            say "Support:";
            for $dist.hash<support>.kv -> $k, $v {
                say "#   $k:\t$v";
            }
        }

        my @deps = (|$dist.depends-specs, |$dist.test-depends-specs, |$dist.build-depends-specs).grep(*.defined).unique;
        say "Depends: {@deps.elems} items";
        if $verbose {
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
    multi MAIN('look', $identity, Bool :v(:$verbose), Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True) is export {
        my $client     = Zef::Client.new(:$config, :$verbose, :$depends, :$test-depends, :$build-depends);
        my @candidates = |$client.candidates( str2identity($identity) );
        die "Failed to find any candidates to fetch for: $identity" unless +@candidates;
        my @local-candidates = $client.fetch(|@candidates);
        my $requested        = @local-candidates[0] || die "Failed to fetch candidate: $identity";

        # We don't install the dependencies first. Instead we set all their paths in
        # the PERL6LIB ENV of the shell that gets spawned, allowing tests to find the
        # libs of any ***declared*** dependencies
        my $env = %*ENV andthen $env<PERL6LIB> = join $*DISTRO.cur-sep, grep *.?chars,
            |@local-candidates.map(*.uri.IO.child('lib')), $env<PERL6LIB>;

        say "===> Shell-ing into directory: {$requested.uri}";
        say "Note: Dependencies that were fetched are in env at: `PERL6LIB`" if +@local-candidates > 1;
        # todo: handle dependencies; only shell into the requested distribution's directory, but
        # fetch all dependencies and add their paths to %*ENV<PERL6LIB> for the shell below
        exit so shell(%*ENV<SHELL> // %*ENV<ComSpec>, :$env, :cwd($requested.uri)) ?? 0 !! 1;
    }

    #| Smoke test
    multi MAIN('smoke', Bool :v(:$verbose), Bool :$force, Bool :$test = True,Bool :$fetch = True, :$exclude, :to(:$install-to) = ['site']) is export {
        my $client                  = Zef::Client.new(:$config, :$force, :$verbose);
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
        my $client = Zef::Client.new(:$config);
        $client.storage.update(|@names);
    }

    #| Delete all modules for a specific CompUnit::Repository name (site, home, etc)
    multi MAIN('nuke', *@curli-names) {
        my CompUnit::Repository @curlis = @curli-names\
            .map(*.&str2cur)\
            .grep(*.can('can-install'))\
            .grep(*.can-install);
        delete-paths($_) for @curlis.map(*.prefix.absolute);

        exit 0;
    }
    #| Delete RootDir from config
    multi MAIN('nuke', 'RootDir')   { delete-paths($config<RootDir>)  && exit(0) }
    #| Delete StoreDir from config
    multi MAIN('nuke', 'StoreDir')  { delete-paths($config<StoreDir>) && exit(0) }
    #| Delete TempDir from config
    multi MAIN('nuke', 'TempDir')   { delete-paths($config<TempDir>)  && exit(0) }

    multi MAIN(Bool :$help?) {
        note qq:to/END_USAGE/
            Zef - Perl6 Module Management

            USAGE

                zef [flags|options] command [args]


            COMMANDS

                install                 Install specific dependencies by name or path
                uninstall               Uninstall specified distributions
                test                    Run tests on a given module's path
                fetch                   Fetch and extract module's source
                look                    `fetch` followed by shelling into the module's path (dependencies in \%*ENV<PERL6LIB>)
                update                  Update package indexes for content storages
                search                  Show a list of possible distribution candidates for the given terms
                info                    Show detailed distribution information
                list                    List known available distributions, or installed distributions with `--installed`
                rdepends                List all distributions directly depending on a given identity
                smoke                   Run smoke testing on available modules
                nuke                    Delete directory/prefix containing matching configuration path or CURLI name

            OPTIONS

                --install-to=[name]     Short name or spec of CompUnit::Repository to install to

            FLAGS

                --verbose               More detailed output from all commands

                --depsonly              Install only the dependency chains of the requested distributions
                --force                 Continue each phase regardless of failures
                --dry                   Run all phases except the actual installations

                --/tests                Skip the testing phase
                --/depends              Do not fetch runtime dependencies
                --/test-depends         Do not fetch test dependencies
                --/build-depends        Do not fetch build dependencies

            CONFIGURATION {find-config().IO.absolute}

                -C[Phase]="[name].[field]=[value]"  # Example: -CContentStorage="cpan.enabled=1"
            END_USAGE
    }

    # maybe its a name, maybe its a spec/path. either way  Zef::App methods take a CURs, not strings
    sub str2cur($target) {
        $ = CompUnit::RepositoryRegistry.repository-for-name($target)
        || CompUnit::RepositoryRegistry.repository-for-spec(~$target, :next-repo($*REPO));
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

    # handle max width + yada
    sub _widther($str, int :$max) is export {
        return $str unless ?$max && $str.chars > $max;
        my $cutoff = $str.substr(0, $max || $str.chars);
        return $cutoff unless $cutoff.chars > 3;
        return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-3,3) ~~ /\S\S\S/;
        return ($cutoff.substr(0,*-2) ~ '..')  if $cutoff.substr(*-2,2) ~~ /\S\S/;
        return ($cutoff.substr(0,*-1) ~ '.')   if $cutoff.substr(*-1,1) ~~ /\S/;
        return $cutoff;
    }

    # returns formatted row
    sub _row2str (@widths, @cells, Int :$max) {
        my $format = @widths.map({"%-{$_}s"}).join('|');
        return _widther(sprintf( $format, @cells.map({ $_ // '' }) ), :$max);
    }

    # Iterate over ([1,2,3],[2,3,4,5],[33,4,3,2]) to find the longest string in each column
    sub _get_column_widths ( *@rows ) is export {
        return @rows[0].keys.map: { @rows>>[$_]>>.chars.max }
    }
}