use Zef::Client;
use Zef::Config;
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
    our $config;
    BEGIN {
        $config = ZEF-CONFIG();
        for @*ARGS -> $conf {
            if $conf.starts-with('-C') && $conf.contains('=') {
                my ($key, $value) = $conf.substr(2).split(/'='/, 2);
                my ($plugin-name, $plugin-option) = $value.split(/'.'/, 2);
                my ($plugin-key, $plugin-value) = $plugin-option.split(/'='/, 2);
                for $config{$key}.grep(*.<name> eq $plugin-name) -> $conf is rw {
                    $conf{$plugin-key} = $plugin-value;
                }
            }
        }
        @*ARGS = @*ARGS.grep(* !~~ /^'-C' .+/);
    }

    #| Download specific distributions
    multi MAIN('fetch', Bool :$depends, Bool :$test-depends, Bool :$build-depends, Bool :v(:$verbose), *@identities) is export {
        my $client = Zef::Client.new(:$config, :$verbose, :$depends, :$test-depends, :$build-depends);
        my @candidates = |$client.candidates(|@identities>>.&str2identity);
        $client.fetch(|@candidates);
    }

    #| Run tests
    multi MAIN('test', Bool :$force, Bool :v(:$verbose), *@paths) {
        my $client = Zef::Client.new(:$config, :$verbose, :$force);
        my %results = $client.test(|@paths);
        %results<fail>.elems ?? exit(1) !! exit(0);
    }

    #| Install
    multi MAIN('install', Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True,
                Bool :v(:$verbose), Bool :$force, Bool :$test = True, Bool :$fetch = True, :$exclude,
                Bool :$dry, Bool :$update, Bool :$upgrade, Bool :$depsonly, :$install-to = ['site'], *@identities) is export {

        my $client = Zef::Client.new(:$config, :$force, :$verbose, :$depends, :$test-depends, :$build-depends
            :exclude(grep *.defined, ?$depsonly ?? (|@identities>>.&str2identity, |$exclude) !! $exclude)
        );

        $client.install( :$fetch, :$install-to, :$test, :$update, :$upgrade, :$dry, |@identities>>.&str2identity );
    }

    #| Get a list of possible distribution candidates for the given terms
    multi MAIN('search', Bool :v(:$verbose), *@terms) is export {
        my $client = Zef::Client.new(:$config, :$verbose);
        my @results = $client.search(|@terms);

        say "===> Found " ~ +@results ~ " results";

        my @rows = eager gather for @results -> $candi {
            once { take [<ID From Package Description>] }
            my $row = [ "{state $id += 1}", $candi.recommended-by, $candi.dist.identity, ($candi.dist.hash<description> // '') ];
            take $row;
        }
        print-table(@rows);
    }

    #| A list of available modules from enabled content storages
    multi MAIN('list', Bool :v(:$verbose), Bool :i(:$installed)) is export {
        my $client = Zef::Client.new(:$config, :$verbose);

        my %found = ?$installed ?? $client.installed !! $client.available;

        for %found.kv -> $from, $ids {
            say "===> Found via {$from}";
            for $ids.kv -> $identity, $meta {
                say "{$identity}";
                say "#\t{$_}" for @($meta<modules>.sort if ?$verbose);
            }
        }
    }

    #| Detailed distribution information
    multi MAIN('info', $identity, Bool :v(:$verbose)) is export {

        my $client = Zef::Client.new(:$config, :$verbose);
        my $candi  = $client.search($identity, :max-results(1))[0]\
            or die "Found no candidates matching identity: {$identity}";
        my $dist  := $candi.dist;

        say "- Info for: $identity";
        say "- Identity: {$dist.identity}";
        say "- Recommended By: {$candi.recommended-by}";
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

        my @deps = (|$dist.depends, |$dist.test-depends, |$dist.build-depends).grep(*.defined).unique;
        say "Depends: {@deps.elems} items";
        if $verbose {
            my @rows = eager gather for @deps -> $dep {
                once { take [<ID Identity Installed?>] }
                my $row = [ "{state $id += 1}", $dep, (IS-USEABLE($dep) ?? '✓' !! '')];
                take $row;
            }
            print-table(@rows);
        }
    }

    #| Download a single module and change into its directory
    multi MAIN('look', $identity, Bool :v(:$verbose), Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True) is export {
        my $client     = Zef::Client.new(:$config, :$verbose, :$depends, :$test-depends, :$build-depends);
        my @candidates = |$client.candidates( str2identity($identity) );
        die "Failed to find any candidates to fetch for: $identity" unless +@candidates;
        my @candis     = $client.fetch(|@candidates);
        my $requested  = @candis[0];

        my $env = %*ENV;
        $env<PERL6LIB> = (|@candis.map(*.uri.IO.child('lib')), $env<PERL6LIB>).join($*DISTRO.cur-sep);

        say "===> Shell-ing into directory: {$requested.uri}";
        say "Note: Dependencies that were fetched are in env at: `PERL6LIB`" if +@candis > 1;
        # todo: handle dependencies; only shell into the requested distribution's directory, but
        # fetch all dependencies and add their paths to %*ENV<PERL6LIB> for the shell below
        so shell(%*ENV<SHELL> // %*ENV<ComSpec>, :$env, :cwd($requested.uri));
    }

    #| Smoke test
    multi MAIN('smoke', Bool :v(:$verbose), Bool :$force, Bool :$test = True, Bool :$fetch = True, :$exclude, :$install-to = ['site']) is export {
        my $client = Zef::Client.new(:$config, :$force, :$verbose);
        my @identities = $client.available.values.flatmap(*.keys).unique;
        say "===> Smoke testing with {+@identities} distributions...";

        my @installed;
        for @identities -> $identity {
            next if $identity ~~ any(@installed);
            my @all = try { $client.install( :$fetch, :$install-to, :$test, $identity ) } || next;
            @installed = unique(|@all |@installed);
        }
    }

    #| Update package indexes
    multi MAIN('update', *@names) is export {
        my $client = Zef::Client.new(:$config);
        $client.storage.update(|@names);
    }

    multi MAIN(Bool :$help?) {
        note qq:to/END_USAGE/
            Zef - Perl6 Module Management

            USAGE

                zef [flags|options] command [package]


            COMMANDS

                install                 Install specific dependencies by name or path
                test                    Run tests on a given module's path
                fetch                   Fetch and extract module's source
                look                    `fetch` followed by shelling into the module's path (dependencies in \%*ENV<PERL6LIB>)
                update                  Update package indexes for content storages
                search                  Show a list of possible distribution candidates for the given terms
                info                    Show detailed distribution information
                list                    Show known available distributions, or installed distributions with `--installed`
                smoke                   Run smoke testing on available modules

            OPTIONS

                --install-to=[name]     Short name of CompUnit::Repository to install to

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

    sub print-table(@rows) {
        my @widths     = _get_column_widths(@rows);
        my @fixed-rows = @rows.map({ _row2str(@widths, @$_, max-width => $MAX-TERM-COLS) });
        if +@fixed-rows {
            my $width      = [+] _get_column_widths(@fixed-rows);
            my $sep        = '-' x $width;
            say "{$sep}\n{@fixed-rows[0]}\n{$sep}";
            .say for @fixed-rows[1..*];
            say $sep;
        }
    }

    sub _widther($str, :$max-width) is export {
        return $str unless ?$max-width && $str.chars > $max-width;
        my $cutoff = $str.substr(0, $max-width);
        return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-3,3) ~~ /\S\S\S/;
        return ($cutoff.substr(0,*-2) ~ '..')  if $cutoff.substr(*-2,2) ~~ /\S\S/;
        return ($cutoff.substr(0,*-1) ~ '.')   if $cutoff.substr(*-1,1) ~~ /\S/;
        return $cutoff;
    }

    # returns formatted row
    sub _row2str (@widths, @cells, Int :$max-width) {
        my $format = @widths.map({"%-{$_}s"}).join('|');
        return _widther(sprintf( $format, @cells.map({ $_ // '' }) ), :$max-width);
    }

    # Iterate over ([1,2,3],[2,3,4,5],[33,4,3,2]) to find the longest string in each column
    sub _get_column_widths ( *@rows ) is export {
        return @rows[0].keys.map: { @rows>>[$_]>>.chars.max }
    }
}