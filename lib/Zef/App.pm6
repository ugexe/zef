unit class Zef::App;

use Zef::Authority::P6C;
use Zef::Builder;
use Zef::Config;
use Zef::Installer;
use Zef::CLI::StatusBar;
use Zef::CLI::STDMux;
use Zef::ProcessManager;
use Zef::Test;
use Zef::Uninstaller;
use Zef::Utils::PathTools;
use Zef::Utils::SystemInfo;



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
multi MAIN('test', *@repos, Bool :$async, Bool :$v, Bool :$boring, Bool :$shuffle, Bool :$force) is export {
    @repos .= push($*CWD) unless @repos;

    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $tested = CLI-WAITING-BAR {
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


    my $test-result = verbose('Testing', $tested.list>>.pm>>.processes.map({ 
        ok => all($_.ok), module => $_.id.IO.basename
    }));


    if $test-result<nok> && !$force {
        print "Failed tests. Aborting.\n";
        exit $test-result<nok>;
    }


    return $tested;
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
multi MAIN('install', *@modules, :@ignore, IO::Path :$save-to = $*TMPDIR, Bool :$force, Bool :$depends = True,
    Bool :$async, Bool :$report, Bool :$v, Bool :$dry, Bool :$boring, Bool :$shuffle) is export {


    my $fetched = &MAIN('get', @modules, :@ignore, :$save-to, :$boring, :$async, :$depends);


    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m = $fetched.list.grep({ $_.<ok>.so }).map({ $_.<ok> = ?$_.<path>.IO.child('META.info').IO.e; $_ });
    verbose('META.info availability', @m);
    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep({ $_.<ok>.so }).map({ $_.<path> });
    my @metas = @repos.map({ $_.IO.child('META.info').IO.path }).grep(*.IO.e);


    # Precompile all modules and dependencies
    my $built = &MAIN('build', @repos, :$v, :$save-to, :$boring, :$async);


    # force the tests so we can report them. *then* we will bail out
    my $tested = &MAIN('test', @repos, :$v, :$boring, :$async, :$shuffle, :force);


    # Send a build/test report
    if ?$report {
        my $reported = CLI-WAITING-BAR {
            Zef::Authority::P6C.new.report(
                @metas,
                test-results  => $tested, 
                build-results => $built,
            );
        }, "Reporting", :$boring;

        verbose('Reporting', $reported.list);
        my @ok = $reported.list.grep(*.<id>.so);
        print "===> Report{'s' if $reported.list.elems > 1} can be seen shortly at:\n" if @ok;
        print "\thttp://testers.perl6.org/reports/$_.html\n" for @ok.map({ $_.<id> });
    }


    my @failed = $tested>>.failures;
    my @passed = $tested>>.passes;
    if @failed {
        $force
            ?? do { print "Failed tests. Aborting.}\n" and exit @failed.elems }
            !! do { print "Failed tests. Using \$force\n"                     };
    }
    elsif !@passed {
        print "No tests.\n";
    }


    my $install = do {
        my $i = CLI-WAITING-BAR { Zef::Installer.new.install(@metas) }, "Installing", :$boring;
        my @installed = $i.list.grep({ !$_.<skipped> });
        my @skipped   = $i.list.grep({ ?$_.<skipped> });
        verbose('Install', @installed)                 if @installed;
        verbose('Skip (already installed!)', @skipped) if @skipped;
        $i;
    } unless ?$dry;


    exit ?$dry ?? 0 !! (@modules.elems - $install.list.grep({ !$_<ok> }).elems);
}


#| Install local freshness
multi MAIN('local-install', *@modules) is export {
    say "NYI";
}


#! Download a single module and change into its directory
multi MAIN('look', $module, Bool :$depends, Bool :$v, :$save-to = $*CWD.IO.child(time)) { 
    my $auth = Zef::Authority::P6C.new;
    my @g    = $auth.get: $module, :$save-to, :$depends;
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
multi MAIN('get', *@modules, :@ignore, :$save-to = $*TMPDIR, Bool :$depends = True,
    Bool :$v, Bool :$async, Bool :$boring, Bool :$skip-depends) is export {
    
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
    my $fetched = CLI-WAITING-BAR { $auth.get(@modules, :$save-to, :$depends) }, "Fetching", :$boring;
    verbose('Fetching', $fetched.list);

    unless $fetched.list {
        say "!!!> No matches found.";
        exit 1;
    }

    return $fetched;
}


#| Build modules in cwd
multi MAIN('build', Bool :$v) is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directory
multi MAIN('build', *@repos, :@ignore, Bool :$v, :$save-to = $*TMPDIR,
    Bool :$async, Bool :$boring, Bool :$skip-depends) is export {

    # Precompile all modules and dependencies
    my $built = CLI-WAITING-BAR { Zef::Builder.new.precomp(@repos) }, "Building", :$boring;
    verbose('Build', $built.list);

    return $built;
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
