unit class Zef::App;

use Zef::Distribution;
#use Zef::Roles::Installing;
use Zef::Roles::Precompiling;
use Zef::Roles::Processing;
use Zef::Roles::Testing;
use Zef::Authority::P6C;
use Zef::Config;
use Zef::Installer;
use Zef::CLI::StatusBar;
use Zef::CLI::STDMux;
use Zef::Uninstaller;
use Zef::Utils::PathTools;
use Zef::Utils::SystemInfo;

# todo: start skipping nativecall/Build.pm modules until we implement a compatability layer


# Modules that break smoke testing even though each test is launched in its own process
# todo: bugfix / use timeouts to just abort
# DateTime::TimeZone - run time. maybe auto ignore the redundant, script generated, tests and treat them as author tests instead?
# BioInfo - package naming does not allow proper META.info association
# Text::CSV - random hangs on win32 or jvms
# Flower - not maintained and fails. so just saving time.
# Audio:: - needs the todo: native call compatability
# Inline::Perl5 - see above
BEGIN our @smoke-blacklist = <NativeCall DateTime::TimeZone BioInfo Text::CSV Flower Audio::Sndfile Audio::Libshout Inline::Perl5 Compress::Zlib::Raw Compress::Zlib Git::PurePerl LibraryMake Inline::Python LibraryCheck>;

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
multi MAIN('test', *@repos, :$lib, Bool :$async, Bool :$v, 
    Bool :$boring, Bool :$shuffle, Bool :$force) is export {
    
    @repos .= push($*CWD) unless @repos;
    @repos  = @repos.map({ $_.IO.is-absolute ?? $_ !! $_.IO.abspath });


    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $tested-dists = CLI-WAITING-BAR {
        my @includes = gather for @repos -> $path {
            take $path.IO.child('blib');
            take $path.IO.child('lib');
        }

        my @dists = gather for @repos -> $path {
            my $dist = Zef::Distribution.new(path => $path.IO, includes => $lib.list.unique);
            $dist does Zef::Roles::Processing[:$async];
            $dist does Zef::Roles::Testing;

            my @test-commands = [$dist.test-cmds];

            for @test-commands -> $grouped {
                my @args = $grouped.list;
                $dist.queue-processes( [@args] );
            }

            procs2stdout( $dist.processes>>.map({ $_ }) ) if $v;
            await $dist.start-processes;

            take $dist;
        }
    }, "Testing", :$boring;


    my @test-results = gather for $tested-dists.list -> $tested-dist {
        my $results = $tested-dist.processes>>.map({ ok => all($_.ok), module => $_.id.IO.basename });
        my $results-final = verbose('Testing', $results.list);
        take $results-final;
    }

    if @test-results>>.hash.<nok> && !$force {
        print "!!!> Failed tests. Aborting.\n";
        exit 255;
    }


    return $tested-dists;
}


multi MAIN('smoke', :@ignore = @smoke-blacklist, Bool :$report, Bool :$v, Bool :$boring, Bool :$shuffle) {
    say "===> Smoke testing started [{time}]";

    my $auth  = CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c.projects = $p6c.projects\
            .grep({ $_.<name>:exists })\
            .grep({ $_.<name> ~~ none(@ignore) })\
            .grep({ any($_.<depends>.list) ~~ none(@ignore) });
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
multi MAIN('install', *@modules, :$lib, :@ignore, :$save-to = $*TMPDIR, Bool :$force, Bool :$depends = True,
    Bool :$async, Bool :$report, Bool :$v, Bool :$dry, Bool :$boring, Bool :$shuffle) is export {

    my $fetched = &MAIN('get', @modules, :@ignore, :$save-to, :$boring, :$async, :$depends);


    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m = $fetched.list.grep({ $_.<ok>.so }).map({ $_.<ok> = ?$_.<path>.IO.child('META.info').IO.e; $_ });
    verbose('META.info availability', @m);
    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep({ $_.<ok>.so }).map({ $_.<path>.IO.is-absolute ?? $_.<path> !! $_.<path>.IO.abspath });
    my @metas = @repos.map({ $_.IO.child('META.info').IO.path }).grep(*.IO.e);


    # Precompile all modules and dependencies
    # $save-to is already in the absolute paths of @repos
    my $built = &MAIN('build', @repos, :$lib, :save-to('blib'), :$v, :$boring, :$async);
    unless $built.list.elems {
        print "???> Nothing to build.\n";
    }

    # force the tests so we can report them. *then* we will bail out
    my $tested = &MAIN('test', @repos, :$lib, :$v, :$boring, :$async, :$shuffle, :force);


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
            ?? do { print "!!!> Failed tests. Aborting.\n" and exit @failed.elems }
            !! do { print "???> Failed tests. Using \$force\n"                    };
    }
    elsif !@passed {
        print "???> No tests.\n";
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
            .grep({ $_.<name> ~~ none(@ignore) })\
            .grep({ any($_.<depends>.list) ~~ none(@ignore) });
        $p6c;
    }, "Querying Authority", :$boring;


    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my $fetched = CLI-WAITING-BAR { 
        $auth.get(@modules, :@ignore, :$save-to, :$depends);
    }, "Fetching", :$boring;

    verbose('Fetching', $fetched.list);

    unless $fetched.list {
        say "!!!> No matches found.";
        exit 1;
    }

    return $fetched;
}


#| Build modules in the specified directory
multi MAIN('build', *@repos, :$lib, :@ignore, :$save-to = 'blib', Bool :$v,
    Bool :$async, Bool :$boring, Bool :$skip-depends, Bool :$force = True) is export {
    @repos .= push($*CWD) unless @repos;
    @repos  = @repos.map({ $_.IO.is-absolute ?? $_ !! $_.IO.abspath });

    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $precompiled-dists = CLI-WAITING-BAR {
        my @dists = gather for @repos -> $path {
            my $dist = Zef::Distribution.new(
                path         => $path.IO, 
                precomp-path => (?$save-to.IO.is-relative 
                    ?? $save-to.IO.absolute($path).IO 
                    !! $save-to.IO.abspath.IO
                ),
                includes     => $lib.list,
            );
            $dist does Zef::Roles::Processing[:$async];
            $dist does Zef::Roles::Precompiling;

            $dist.queue-processes($_) for $dist.precomp-cmds;
            procs2stdout($dist.processes>>.map({ $_ })) if $v;
            await $dist.start-processes;

            take $dist;
        }
    }, "Precompiling", :$boring;


    my @precompiled-results = gather for $precompiled-dists.list -> $precompiled-dist {
        my $results = $precompiled-dist.processes>>.map({ ok => all($_.ok), module => $_.id.IO.basename });
        my $results-final = verbose('Precompiling', $results.list);
        take $results-final;
    }

    if @precompiled-results>>.hash.<nok> && !$force {
        print "!!!> Precompilation failure. Aborting.\n";
        exit 255;
    }

    return $precompiled-dists;
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



# todo: use the auto-sizing table formatting
multi MAIN('info', *@modules, Bool :$v, Bool :$boring) {
    my $auth = CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c;
    }, "Querying Server", :$boring;


    # Filter the projects.json file
    my $results = CLI-WAITING-BAR { 
        my @p6c = $auth.search(|@modules);
        @p6c;
    }, "Filtering Results", :$boring;

    say "===> Found " ~ $results.list.elems ~ " results";

    for $results.list -> $meta {
        print "[{$meta.<name>}]\n";

        print "# Version: {$meta.<version> // $meta.<vers> // '*'}\n";

        print "# Auth:\t {$meta.<auth>}\n" if $meta.<auth>;
        print "# Authority:\t {$meta.<auth>}\n" if $meta.<auth>;
        print "# Author:\t {$meta.<author>}\n" if $meta.<author>;
        print "# Authors:\t {$meta.<authors>.list.join(', ')}\n" if $meta.<authors>.list.elems;

        print "# Description:\t {$meta.<description>}\n" if $meta.<description>;

        print "# Source-url:\t {$meta.<source-url>}\n" if $meta.<source-url>;
        print "# Source:\t {$meta.<source>}\n" if $meta.<source>;

        if $meta.<provides> {
            print "# Provides: {$meta.<provides>.list.elems} items\n";
            if $v { print "#\t$_\n" for $meta.<provides>.keys }
        }

        if $meta.<support> {
            print "# Support:\n";
            for $meta.<support>.kv -> $k, $v {
                print "#   $k:\t$v\n";
            }
        }

        if $meta.<depends> {
            print "# Depends: {$meta.<depends>.list.elems} items\n";
            for $meta.<depends>.kv -> $k, $v { 
                print "#   $k)\t$v\n";
            }
        }

        if $meta.<depends> && $v {
            my $deps = Zef::Utils::Depends.new(projects => $auth.projects)\
                .topological-sort($meta);

            for $deps.list.kv -> $i1, $level {
                FIRST { print "# Depends-chain:\n" }
                for $level.list.kv -> $i2, $dep {
                    print "#   $i1\.$i2) $dep\n";
                }
            }
        }
    }
}



# will be replaced soon
sub verbose($phase, @_) {
    say "???> $phase stage is empty" and return unless @_;
    my %r = @_.classify({ ?$_.hash.<ok> ?? 'ok' !! 'nok' });
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
