unit class Zef::App;

use Zef::Distribution;

use Zef::Roles::Installing;
use Zef::Roles::Precompiling;
use Zef::Roles::Processing;
use Zef::Roles::Testing;
use Zef::Roles::Hooking;

use Zef::Authority::P6C;
use Zef::Config;
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
our sub signal-jvm($) { Supply.new }
our $signal-handler := &::("signal") ~~ Failure ?? &::("signal-jvm") !! &::("signal");
our $sig-resize     := ::("Signal::SIGWINCH");
$signal-handler.($sig-resize).act: { $MAX-TERM-COLS = GET-TERM-COLUMNS() }


#| Test modules in the specified directories
multi MAIN('test', *@repos, :$lib, Bool :$async, Bool :$v, 
    Bool :$boring, Bool :$shuffle, Bool :$force, Bool :$no-wrap) is export(:test, :install) {
    

    @repos .= push($*CWD) unless @repos;
    @repos := @repos.map({ $_.IO.is-absolute ?? $_ !! $_.IO.abspath });


    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my @dists := gather for @repos -> $path {
        state @perl6lib;
        my $dist := Zef::Distribution.new(
            path     => $path.IO, 
            includes => $lib.list.unique,
            perl6lib => @perl6lib.unique,
        );
        $dist does Zef::Roles::Processing[:$async];
        $dist does Zef::Roles::Testing;
        $dist does Zef::Roles::Hooking;

        $dist.queue-processes: [$dist.hook-cmds(TEST, :before)];
        $dist.queue-processes( [$_.list] ) for [$dist.test-cmds];
        $dist.queue-processes: [$dist.hook-cmds(TEST, :after)];

        @perl6lib.push: $dist.precomp-path.absolute;

        take $dist;
    }


    my $tested-dists = CLI-WAITING-BAR {
        eager gather for @dists -> $dist-todo {
            my $max-width = $MAX-TERM-COLS if ?$no-wrap;
            procs2stdout(:$max-width, $dist-todo.processes) if $v;
            my $promise = $dist-todo.start-processes;
            $promise.result; # osx bug
            await $promise;

            take $dist-todo;
        }
    }, "Testing", :$boring;


    for $tested-dists.list -> $tested-dist {
        for $tested-dist.processes -> $proc {
            my $results = $proc.map({ ok => all($_.ok), module => $_.id.IO.basename });
            my $results-final = verbose('Testing', $results.list);
            if $results-final.hash.<nok> && !$force {
                print "!!!> Failed tests. Aborting.\n";
                exit 255;
            }
        }
    }


    return $tested-dists;
}


multi MAIN('smoke', :@ignore = @smoke-blacklist, Bool :$no-wrap, :$projects-file,
    Bool :$report, Bool :$v, Bool :$boring, Bool :$shuffle, Bool :$async) is export(:smoke) {
    
    my $start = time;
    say "===> Smoke testing started: [{$start}]";

    my $auth := CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new(:$projects-file);
        $p6c.update-projects unless $projects-file;
        say "===> Module count: {$p6c.projects.list.elems}";
        $p6c.projects = $p6c.projects\
            .grep({ $_.<name>:exists })\
            .grep({ $_.<name> ~~ none(@ignore) })\
            .grep({ !$_.<depends>       || any($_.<depends>.list) ~~ none(@ignore) })\
            .grep({ !$_.<test-depends>  || any($_.<depends>.list) ~~ none(@ignore) })\
            .grep({ !$_.<build-depends> || any($_.<depends>.list) ~~ none(@ignore) })\
            .pick(*);
        $p6c;
    }, "Getting ecosystem data", :$boring;

    say "===> Filtered module count: {$auth.projects.list.elems}";

    my $smoke-projects-file := $*TMPDIR.child("projects.json.smoke.{$start}").IO;
    CLI-WAITING-BAR {
        say "===> Notice: The next step may take a few minutes";
        $smoke-projects-file.spurt: to-json($auth.projects);
    }, "Generating smoke test projects file: '{$smoke-projects-file.basename}'", :$boring;

    for $auth.projects.list -> $result {
        # todo: make this work with the CLI::StatusBar
        my @args = '-Ilib', 'bin/zef', '--dry', '--boring', 
            "--projects-file={$smoke-projects-file}", @ignore.map({ "--ignore={$_}" });
        @args.push('-v')        if $v;
        @args.push('--report')  if $report;
        @args.push('--shuffle') if $shuffle;
        @args.push('--no-wrap') if $no-wrap;
        @args.push('--async')   if $async;

        say "===> Smoking next: {$result.<name>}";
        my $proc = run($*EXECUTABLE, @args, 'install', $result.<name>, :out);
        say $_ for $proc.out.lines;
    }

    say "===> Smoke testing ended [{time}]";
}


#| Install with business logic
multi MAIN('install', *@modules, :$lib, :@ignore, :$save-to = $*TMPDIR, :$projects-file, 
    Bool :$notest, Bool :$force, Bool :$async, Bool :$report, Bool :$v, Bool :$dry, 
    Bool :$skip-depends, Bool :$skip-build-depends, Bool :$skip-test-depends,
    Bool :$shuffle, Bool :$no-wrap, Bool :$boring) is export(:install) {


    # todo:
    # check $dist.is-installed and $force before building/testing instead of waiting until
    # the install process to abort the needless install.

    # FETCHING
    my $fetched := &MAIN('get', @modules, :@ignore,
        :$save-to, :$projects-file,
        :$boring, :$async,
        :$skip-depends, :$skip-build-depends
        :skip-test-depends(($notest || $skip-test-depends) ?? True !! False),
    );



    # VALIDATION
    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m := $fetched.list.grep({ $_.<ok>.so });

    verbose('META.info availability', @m);

    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos := @m.grep({ $_.<ok>.so })\
        .map({ $_.<path>.IO.is-absolute ?? $_.<path> !! $_.<path>.IO.abspath });

    my @metas := @repos.map({ $_.IO.child('META.info').IO.path }).grep(*.IO.e);




    # BUIDLING
    my $built := &MAIN('build', @repos, :save-to('blib/lib'), :$lib, :$v, :$boring, :$async, :$no-wrap);
    unless $built.list.elems {
        print "???> Nothing to build.\n";
    }




    # TESTING
    unless $notest {
        # force the tests so we can report them. *then* we will bail out
        my $tested := &MAIN('test', @repos, :lib('blib/lib'), :$lib, 
            :$v, :$boring, :$async, :$shuffle, :force, :$no-wrap
        );


        # Send a build/test report
        if ?$report {
            my $reported := CLI-WAITING-BAR {
                Zef::Authority::P6C.new.report(
                    @metas,
                    test-results  => $tested, 
                    build-results => $built,
                );
            }, "Reporting", :$boring;

            verbose('Reporting', $reported.list);
            my @ok := $reported.list.grep(*.<id>.so);
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
    }


    my $install = do {
        my $i := CLI-WAITING-BAR { 
            eager gather for $built.list -> $dist {
                # todo: check against $tested to make sure tests were passed
                # currently we call &MAIN for each phase, thus creating a new
                # Zef::Distribution object for each phase. This means the roles
                # do not carry over. The fix should work around is.
                $dist does Zef::Roles::Processing;
                $dist does Zef::Roles::Installing;
                $dist does Zef::Roles::Hooking;
 
                my $max-width = $MAX-TERM-COLS if ?$no-wrap;

                my @before-procs = $dist.queue-processes: [$dist.hook-cmds(INSTALL, :before)];
                procs2stdout(:$max-width, @before-procs) if $v;
                my $promise1 = $dist.start-processes;
                $promise1.result; # osx bug
                await $promise1;
                
                take $dist.install(:$force);
                
                my @after-procs = $dist.queue-processes: [$dist.hook-cmds(INSTALL, :after)];
                procs2stdout(:$max-width, @after-procs) if $v;
                my $promise2 = $dist.start-processes;
                $promise2.result; # osx bug
                await $promise2;

            }
        }, "Installing", :$boring;

        my @installed := $i.list.grep({ !$_.<skipped> });
        my @skipped   := $i.list.grep({ ?$_.<skipped> });

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
multi MAIN('look', $module, Bool :$v, :$save-to = $*CWD.IO.child(time)) is export(:look) { 
    my $auth := Zef::Authority::P6C.new;
    my @g := $auth.get: $module, :$save-to;
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
multi MAIN('get', *@modules, :@ignore, :$save-to = $*TMPDIR, :$projects-file, 
    Bool :$async, Bool :$v, Bool :$boring, Bool :$skip-depends, 
    Bool :$skip-test-depends, Bool :$skip-build-depends
    ) is export(:get :install) {

    my $auth := CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new(:$projects-file);
        $p6c.update-projects unless $projects-file;
        $p6c;
    }, "Querying Authority", :$boring;


    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my $fetched := CLI-WAITING-BAR {
        $auth.get(@modules, :@ignore, :$save-to, :depends(!$skip-depends), 
            :test-depends(!$skip-test-depends), :build-depends(!$skip-test-depends),
        );
    }, "Fetching", :$boring;

    verbose('Fetching', $fetched.list);

    unless $fetched.list {
        say "!!!> No matches found.";
        exit 1;
    }

    return $fetched;
}


#| Build modules in the specified directory
multi MAIN('build', *@repos, :$lib, :@ignore, :$save-to = 'blib/lib', Bool :$v, Bool :$no-wrap,
    Bool :$async, Bool :$boring, Bool :$force = True) is export(:build :install) {
    @repos .= push($*CWD) unless @repos;
    @repos := @repos.map({ $_.IO.is-absolute ?? $_ !! $_.IO.abspath });


    my @dists := gather for @repos -> $path {
        state @perl6lib; # store paths to be used in -I in subsequent `depends` processes
        my $dist := Zef::Distribution.new(
            path         => $path.IO, 
            precomp-path => (?$save-to.IO.is-relative
                ?? $save-to.IO.absolute($path).IO
                !! $save-to.IO.abspath.IO
            ),
            includes     => $lib.list.unique,
            perl6lib     => @perl6lib.unique,
        );
        $dist does Zef::Roles::Processing[:$async];
        $dist does Zef::Roles::Precompiling;
        $dist does Zef::Roles::Hooking;

        $dist.queue-processes: [$dist.hook-cmds(BUILD, :before)];
        $dist.queue-processes($_) for $dist.precomp-cmds;
        $dist.queue-processes: [$dist.hook-cmds(BUILD, :after)];

        @perl6lib.push: $dist.precomp-path.absolute;

        take $dist;
    };

    my $precompiled-dists := CLI-WAITING-BAR {
        eager gather for @dists.list -> $dist-todo {
            my $max-width = $MAX-TERM-COLS if ?$no-wrap;
            procs2stdout(:$max-width, $dist-todo.processes) if $v;
            my $promise = $dist-todo.start-processes;
            $promise.result; # osx bug
            await $promise;
            take $dist-todo;
        }
    }, "Precompiling", :$boring;

    my @precompiled-results := gather for $precompiled-dists.list -> $precomp-dist {
        my $results = $precomp-dist.processes>>.map({ ok => all($_.ok), module => $_.id.IO.basename });
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
multi MAIN('search', Bool :$v, *@names, *%fields) is export(:search) {
    # Get the projects.json file
    my $auth := CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c;
    }, "Querying Server";


    # Filter the projects.json file
    my $results := CLI-WAITING-BAR { 
        $auth.search(|@names, |%fields).list;
    }, "Filtering Results";

    say "===> Found " ~ $results.list.elems ~ " results";
    my @rows = $results.list.grep(*).map({ [
        "{state $id += 1}",
         $_.<name>, 
        ($_.<ver> // $_.<version> // '*'), 
        ($_.<description> // '')
    ] });
    @rows.unshift([<ID Package Version Description>]);

    my @widths     := _get_column_widths(@rows);
    my @fixed-rows := @rows.map({ _row2str(@widths, @$_, max-width => $MAX-TERM-COLS) });
    my $width      := [+] _get_column_widths(@fixed-rows);
    my $sep        := '-' x $width;

    if @fixed-rows.end {
        say "{$sep}\n{@fixed-rows[0]}\n{$sep}";
        .say for @fixed-rows[1..*];
        say $sep;
    }

    exit ?@rows ?? 0 !! 1;
}



# todo: use the auto-sizing table formatting
multi MAIN('info', *@modules, Bool :$v, Bool :$boring) is export(:info) {
    my $auth := CLI-WAITING-BAR {
        my $p6c = Zef::Authority::P6C.new;
        $p6c.update-projects;
        $p6c;
    }, "Querying Server", :$boring;


    # Filter the projects.json file
    my $results := CLI-WAITING-BAR { 
        $auth.search(|@modules).list;
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
            my $deps := Zef::Utils::Depends.new(projects => $auth.projects)\
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
    my %r := @_.classify({ ?$_.hash.<ok> ?? 'ok' !! 'nok' });
    print "!!!> $phase failed for: {%r<nok>.list.map({ $_.hash.<module> })}\n" if %r<nok>;
    print "===> $phase OK for: {%r<ok>.list.map({ $_.hash.<module> })}\n"      if %r<ok>;
    return { ok => %r<ok>.elems, nok => %r<nok> }
}


# returns formatted row
sub _row2str (@widths, @cells, Int :$max-width) {
    my $format = join(" | ", @widths.map({"%-{$_}s"}) );
    return _widther(sprintf( $format, @cells.map({ $_ // '' }) ), :$max-width);
}


# Iterate over ([1,2,3],[2,3,4,5],[33,4,3,2]) to find the longest string in each column
sub _get_column_widths ( *@rows ) is export {
    return (0..@rows[0].elems-1).map( -> $col { 
        reduce { max($^a, $^b)}, map { .chars }, @rows[*;$col]; 
    } );
}
