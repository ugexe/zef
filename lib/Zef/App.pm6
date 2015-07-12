unit class Zef::App;

use Zef::Authority::P6C;
use Zef::Builder;
use Zef::Config;
use Zef::Installer;
use Zef::CLI::StatusBar;
use Zef::ProcessManager;
use Zef::Test;
use Zef::Uninstaller;
use Zef::Utils::PathTools;
use Zef::Utils::SystemInfo;
use Zef::CLI::STDMux;


BEGIN our @smoke-blacklist = <DateTime::TimeZone mandelbrot BioInfo Text::CSV BioPerl Flower>;


# todo: check if a terminal is even being used
# The reason for the strange signal handling code is due to JVM
# failing at the compile stage for checks we need to be at runtime.
# (No symbols for 'signal' or 'Signal::*') So we have to get the 
# symbols into world ourselves.
our $MAX-TERM-COLS = GET-TERM-COLUMNS();
sub signal-jvm($) { Supply.new }
my $signal-handler = &::("signal") ~~ Failure ?? &::("signal-jvm") !! &::("signal");
my $sig-resize = ::("Signal::SIGWINCH");
$signal-handler.($sig-resize).act: { $MAX-TERM-COLS = GET-TERM-COLUMNS() }


#| Test modules in the specified directories
multi MAIN('test', *@paths, Bool :$async, Bool :$v, Bool :$boring, Bool :$shuffle) is export {
    my @repos = @paths ?? @paths !! $*CWD;

    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $test-groups = CLI-WAITING-BAR {
        my @includes = gather for @repos -> $path {
            take $path.IO.child('blib');
            take $path.IO.child('lib');
        }

        my @t = @repos.map: -> $path { Zef::Test.new(:$path, :@includes, :$async, :$shuffle) }

        if @t {
            # verbose sends test output to stdout
            procs2stdout(@t>>.pm>>.processes) if $v;
            await Promise.allof(@t.map({ $_.start }));
        }

        @t;
    }, "Testing", :$boring;


    my $test-result = verbose('Testing', $test-groups.list>>.pm>>.processes.map({ 
        ok => all($_.ok), module => $_.id.IO.basename
    }));


    print "Failed tests. Aborting.\n" and exit $test-result<nok> if $test-result<nok>;


    exit 0;
}


multi MAIN('smoke', :@ignore = @smoke-blacklist, Bool :$report, Bool :$v, Bool :$boring, Bool :$shuffle) {
    say "===> Smoke testing started [{time}]";

    my $auth  = CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c.projects = $p6c.projects\
            .grep({ $_.<name>:exists })\
            .grep({ $_.<name>    ~~ none(@ignore) })\
            .grep({ $_.<depends> ~~ none(@ignore) })\
            .pick(*); # randomize order for smoke runs
        $p6c;
    }, "Getting ecosystem data", :$boring;

    say "===> Module count: {$auth.projects.list.elems}";

    for $auth.projects.list -> $result {
        # todo: make this work with the CLI::StatusBar
        my @args = '-Ilib', 'bin/zef', '--dry', '--boring', @ignore.map({ "--ignore={$_}" });
        @args.push('-v')        if $v;
        @args.push('--report')  if $report;
        @args.push('--shuffle') if $shuffle;

        my $proc = run($*EXECUTABLE, @args, 'install', $result.<name>, :out);
        say $_ for $proc.out.lines;
    }

    say "===> Smoke testing ended [{time}]";
}


#| Install with business logic
multi MAIN('install', *@modules, :@ignore, IO::Path :$save-to = $*TMPDIR,
    Bool :$async, Bool :$report, Bool :$v, Bool :$dry, Bool :$boring, Bool :$shuffle) is export {

    my $auth  = CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c.projects = $p6c.projects\
            .grep({ $_.<name>:exists })\
            .grep({ $_.<name>    ~~ none(@ignore) })\
            .grep({ $_.<depends> ~~ none(@ignore) });
        $p6c;
    }, "Querying Authority", :$boring;


    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my $fetched = CLI-WAITING-BAR { $auth.get(@modules, :$save-to) }, "Fetching", :$boring;
    verbose('Fetching', $fetched.list);

    unless $fetched.list {
        say "!!!> No matches found.";
        exit 1;
    }


    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m = $fetched.list.grep({ $_.<ok>.so }).map({ $_.<ok> = ?$_.<path>.IO.child('META.info').IO.e; $_ });
    verbose('META.info availability', @m);
    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep({ $_.<ok>.so }).map({ $_.<path> });
    my @metas = @repos.map({ $_.IO.child('META.info').IO.path }).grep(*.IO.e);

    # Precompile all modules and dependencies
    my $b = CLI-WAITING-BAR { Zef::Builder.new.pre-compile(@repos) }, "Building", :$boring;
    verbose('Build', $b.list);


    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $test-groups = CLI-WAITING-BAR {
        my @includes = gather for @repos -> $path {
            take $path.IO.child('lib');
            take $path.IO.child('blib');
        }

        my @t = @repos.map: -> $path { Zef::Test.new(:$path, :@includes, :$async, :$shuffle) }

        if @t {
            # verbose sends test output to stdout
            procs2stdout(@t>>.pm>>.processes) if $v;
            await Promise.allof: @t.map({ $_.start });
        }

        @t;
    }, "Testing", :$boring;


    my $test-result = verbose('Testing', $test-groups.list>>.pm>>.processes.map({ 
        ok => all($_.ok), module => $_.id.IO.basename
    }));


    # Send a build/test report
    if ?$report {
        my $r = CLI-WAITING-BAR {
            $auth.report(
                @metas,
                test-results  => $test-groups, 
                build-results => $b,
            );
        }, "Reporting", :$boring;

        verbose('Reporting', $r.list);
        my @ok = $r.list.grep(*.<id>.so);
        print "===> Report{'s' if $r.list.elems > 1} can be seen shortly at:\n" if @ok;
        print "\thttp://testers.perl6.org/reports/$_.html\n" for @ok.map({ $_.<id> });
    }


    print "Failed tests. Aborting.\n" and exit $test-result<nok> if $test-result<nok>;


    my $install = do {
        my $i = CLI-WAITING-BAR { Zef::Installer.new.install(@metas) }, "Installing", :$boring;
        my @installed = $i.list.grep({ !$_.<skipped> });
        my @skipped   = $i.list.grep({ ?$_.<skipped> });
        verbose('Install', @installed)                 if @installed;
        verbose('Skip (already installed!)', @skipped) if @skipped;
        $i;
    } unless ?$dry;


    exit $dry ?? $test-result<nok>.elems !! (@modules.elems - $install.list.grep({ !$_<ok> }).elems);
}


#| Install local freshness
multi MAIN('local-install', *@modules) is export {
    say "NYI";
}


#! Download a single module and change into its directory
multi MAIN('look', $module, Bool :$v, :$save-to = $*CWD.IO.child(time)) { 
    my $auth = Zef::Authority::P6C.new;
    my @g    = $auth.get: $module, :$save-to, :skip-depends;
    verbose('Fetching', @g);


    if @g.[0].<ok>.so {
        say "===> Shell-ing into directory: {@g.[0].<path>}";
        chdir @g.[0].<path>;
        shell(%*ENV<SHELL> // %*ENV<ComSpec>);
        exit 0 if $*CWD.IO.path eq @g.[0].<path>;
    }


    # Failed to get the module or change directories
    say "!!!> Failed to fetch module or change into the target directory...";
    exit 1;
}


#| Get the freshness
multi MAIN('get', *@modules, Bool :$v, :$save-to = $*TMPDIR, Bool :$skip-depends) is export {
    my $auth = Zef::Authority::P6C.new;
    my @g    = $auth.get: @modules, :$save-to, :$skip-depends;
    verbose('Fetching', @g);
    say $_.<path> for @g.grep({ $_.<ok>.so });
    exit @g.grep({ not $_.<ok> }).elems;
}


#| Build modules in cwd
multi MAIN('build', Bool :$v) is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directory
multi MAIN('build', $path, Bool :$v, :$save-to) {
    my $builder = Zef::Builder.new;
    $builder.pre-compile($path, :$save-to);
}


# todo: non-exact matches on non-version fields
multi MAIN('search', Bool :$v, *@names, *%fields) {
    # Get the projects.json file
    my $auth = CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c;
    }, "Querying Server";


    # Filter the projects.json file
    my $results = CLI-WAITING-BAR { 
        my @p6c = $auth.search(|@names, |%fields);
        @p6c;
    }, "Filtering Results";

    say "===> Found " ~ $results.list.elems ~ " results";
    my @rows = $results.list.grep(*).map({ [
        "{state $id += 1}",
         $_.<name>, 
        ($_.<ver> // $_.<version> // '*'), 
        ($_.<description> // '')
    ] });
    @rows.unshift([<ID Package Version Description>]);

    my @widths     = _get_column_widths(@rows);
    my @fixed-rows = @rows.map({ _row2str(@widths, @$_, max-width => $MAX-TERM-COLS) });
    my $width      = [+] _get_column_widths(@fixed-rows);
    my $sep        = '-' x $width;

    if @fixed-rows.end {
        say "{$sep}\n{@fixed-rows[0]}\n{$sep}";
        .say for @fixed-rows[1..*];
        say $sep;
    }

    exit ?@rows ?? 0 !! 1;
}


# will be replaced soon
sub verbose($phase, @_) {
    say "!!!> $phase stage is empty" and return unless @_;
    my %r = @_.classify({ $_.hash.<ok> ?? 'ok' !! 'nok' });
    print "!!!> $phase failed for: {%r<nok>.list.map({ $_.hash.<module> })}\n" if %r<nok>;
    print "===> $phase OK for: {%r<ok>.list.map({ $_.hash.<module> })}\n"      if %r<ok>;
    return { ok => %r<ok>.elems, nok => %r<nok> }
}


# returns formatted row
sub _row2str (@widths, @cells, Int :$max-width) {
    # sprintf format
    my $format   = join(" | ", @widths.map({"%-{$_}s"}) );
    my $init-row = sprintf( $format, @cells.map({ $_ // '' }) ).substr(0, $max-width);
    my $row      = $init-row.chars >= $max-width ?? _widther($init-row) !! $init-row;

    return $row;
}


# Iterate over ([1,2,3],[2,3,4,5],[33,4,3,2]) to find the longest string in each column
sub _get_column_widths ( *@rows ) is export {
    return (0..@rows[0].elems-1).map( -> $col { reduce { max($^a, $^b)}, map { .chars }, @rows[*;$col]; } );
}


sub _widther($str is copy) {
    return ($str.substr(0,*-3) ~ '...') if $str.substr(*-1,1) ~~ /\S/;
    return ($str.substr(0,*-3) ~ '...') if $str.substr(*-2,1) ~~ /\S/;
    return ($str.substr(0,*-3) ~ '...') if $str.substr(*-3,1) ~~ /\S/;
    return $str;
}
