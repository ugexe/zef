unit class Zef::App;

use Zef::Distribution::Local;
use Zef::Manifest;

use Zef::Roles::Installing;
use Zef::Roles::Precompiling;
use Zef::Roles::Processing;
use Zef::Roles::Testing;
use Zef::Roles::Hooking;

use Zef::Authority::P6C;
use Zef::CLI::StatusBar;
use Zef::CLI::STDMux;
use Zef::Utils::PathTools;
use Zef::Utils::SystemInfo;


#| Test modules in the specified directories
multi MAIN('test', *@repos, :$lib, Bool :$async, Bool :$v, 
    Bool :$boring, Bool :$shuffle, Bool :$force, Bool :$no-wrap) is export(:test, :install) {
    

    @repos .= push($*CWD) unless @repos;
    @repos  = @repos.map({ $_.IO.is-absolute ?? $_ !! $_.IO.abspath }).list;

    my $dists := gather for @repos -> $path {
        state @perl6lib; # store paths to be used in PERL6LIB in subsequent `depends` processes
        my $dist := Zef::Distribution::Local.new(
            path     => $path.IO, 
            includes => $lib.list.unique,
            perl6lib => @perl6lib.unique,
        );
        $dist does Zef::Roles::Processing[:$async, :$force] unless $dist.does(Zef::Roles::Processing);
        $dist does Zef::Roles::Hooking unless $dist.does(Zef::Roles::Hooking);
        $dist does Zef::Roles::Testing;

        $dist.queue-processes: $($dist.hook-cmds(TEST, :before));
        $dist.queue-processes($($dist.test-cmds.list));
        $dist.queue-processes: $($dist.hook-cmds(TEST, :after));

        @perl6lib.push: $dist.precomp-path.absolute;

        take $dist;
    };


    my $tested-dists = CLI-WAITING-BAR {
        my @finished;
        for $dists.list -> $dist-todo {
            my $max-width = $MAX-TERM-COLS if ?$no-wrap;
            procs2stdout(:$max-width, $dist-todo.processes) if $v;
            my $promise = $dist-todo.start-processes;
            $promise.result; # osx bug RT125758
            await $promise;
            @finished.push: $dist-todo;
        }
        @finished;
    }, "Testing", :$boring;

    for $tested-dists.list -> $tested-dist {
        my @r;
        for $tested-dist.processes -> $group {
            for $group.list -> $proc {
                for $proc.list -> $item {
                    my $result = { ok => all($item.ok), module => $item.id.IO.basename };

                    if !$force && !$result<ok> {
                        print "!!!> Testing failure. Aborting.\n";
                        exit 255;
                    }

                    @r.push($result);
                }
            }
        }
        verbose('Testing', @r);
    }

    return $tested-dists;
}


multi MAIN('smoke', :$ignore, Bool :$no-wrap, :$projects-file is copy, Bool :$dry,
    Bool :$report, Bool :$v, Bool :$boring, Bool :$shuffle, Bool :$async) is export(:smoke) {
    say "===> Smoke testing started: [{time}]";

    temp $projects-file = packages(:$ignore, :packages-file($projects-file));
    my @packages = from-json($projects-file.IO.slurp).list;

    say "===> Filtered module count: {@packages.elems}";

    # todo: save to a custom CURLI so the install command can automatically ignore modules
    # that have already been tested to satisfy earlier dependencies.
    for @packages -> $result {
        my @args = 'zef', '--boring', "--projects-file={$projects-file}";
        @args.push('-v')        if $v;
        @args.push('--report')  if $report;
        @args.push('--dry')     if $dry;
        @args.push('--shuffle') if $shuffle;
        @args.push('--no-wrap') if $no-wrap;
        @args.push('--async')   if $async;
        @args.push("--ignore=$_") for $ignore.grep(*.so).list;

        say "===> Smoking next: {$result.<name>}";
        my $proc = run(@args.grep(*.so).list, 'install', $result.<name>, :out);

        say $_ for $proc.out.lines;
    }

    say "===> Smoke testing ended [{time}]";
}


multi MAIN('uninstall', *@names, :$auth, :$ver, :$from = %*CUSTOM_LIB<site>, Bool :$v) {
    my $ok;
    my $nok;

    for $from.list -> $cur {
        with CompUnitRepo::Local::Installation.new($cur) -> $curli {
            my $mani = Zef::Manifest.new(:cur($curli), :create);
            for @names.list -> $name {
                for $curli.candidates($name, :$auth, :$ver) -> $candi {
                    my $dist = Distribution.new(:name($candi<name>), :auth($candi<auth>), :ver($candi<ver>));

                    if $mani.uninstall($dist) {
                        say "===> Uninstalled {$dist.name} successfully.";
                        $ok++;
                    }
                    else {
                        say "!!!> Uninstall for {$dist.name} failed.";
                        $nok++;
                    }
                }
            }
        }
    }

    exit $nok.so ?? $nok !! 0;
}

#| Install with business logic
multi MAIN('install', *@modules, :$lib, :$ignore, :$save-to = $*TMPDIR, :$projects-file is copy, 
    Bool :$notest, Bool :$force, Bool :$async, Bool :$report, Bool :$v, Bool :$dry, 
    Bool :$skip-depends, Bool :$skip-build-depends, Bool :$skip-test-depends,
    Bool :$shuffle, Bool :$no-wrap, Bool :$boring) is export(:install) {

    # todo:
    # Change workflow so we can check the packages file and remove already installed modules 
    # if needed, so that we don't attempt a possibly pointless `git pull`.
    # Cannot just use :ignore, as this removes modules that depend on anything ignored.
    # Add :skip to act like ignore, but not follow depends?

    # FETCHING
    my $fetched := &MAIN('get', @modules, :ignore($ignore.list),
        :$save-to, :$projects-file,
        :$boring, :$async,
        :$skip-depends, :$skip-build-depends
        :skip-test-depends(($notest || $skip-test-depends) ?? True !! False),
    );



    # VALIDATION
    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m := $fetched.list.grep({ $_.<ok>.so }).list;
    verbose('META.info availability', @m);

    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep({ $_.<ok>.so })\
        .map({ $_.<path>.IO.is-absolute ?? $_.<path> !! $_.<path>.IO.abspath }).list;

    # META file check
    my @metas = eager gather for @repos -> $repo-path {
        if $repo-path.IO.child('META.info').IO.e {
            take $repo-path.IO.child('META.info');
        }
        elsif $repo-path.IO.child('META6.json').IO.e {
            take $repo-path.IO.child('META6.json');
        }
    }
    my @failed-metas = @metas.grep({
            !$_.IO.child('META.info').IO.e
        &&  !$_.IO.child('META6.json').IO.e
    }) unless @metas.elems == @repos.elems;
    die "!!!> Aborting. Missing META info for: {@failed-metas}" if !$force && @failed-metas.elems;


    # Prevent processing modules that are already installed with the same or greater version.
    # Version '*' is always installed for now.
    # TEMPORARY - need to refactor as to not create Zef::Distribution::Local for a path multiple times
    my @dists     = @repos.map(   { Zef::Distribution::Local.new(path => $_.IO)            } ).list;
    my @wanted    = @dists.grep(  { $_.wanted || ($force && $_.name ~~ any(@modules.list)) } ).list;
    my @installed = @dists.grep(  { $_.name !~~ any(@wanted>>.name)                        } ).list;
    @wanted       = @wanted.grep( { $_.name ~~ none(@installed)                            } ).list if @installed.elems;

    if @wanted.elems != @dists.elems {
        print "===> The following modules are already up to date: {@installed.map(*.name).join(', ')}\n";
        if !$force {
            @repos = @repos.grep: { none(@installed.map(*.path).grep(*.ACCEPTS($_.IO)))         }
            @metas = @metas.grep: { none(@installed.map(*.path).grep(*.ACCEPTS($_.dirname.IO))) }
        }
        print "===> ...but using --force\n" if ?$force;
        print "===> Nothing to do.\n" and exit 0 unless @repos.elems && @metas.elems;
    }

    # BUIDLING
    my $built = &MAIN('build', @repos, :save-to('blib/lib'), :$lib, :$v, :$boring, :$async, :$no-wrap)\
        or print "???> Nothing to build.\n";

    my @failed-builds = eager gather for $built.list -> $b {
        $b.map({ $_.processes.grep({ $_.nok }).map(-> $proc { take $proc }) });
    }
    die "!!!> Aborting. Build failures for: {@failed-builds.map(*.id)}" if !$report && !$force && @failed-builds.elems;

    # TESTING
    unless $notest {
        # force the tests so we can report them. *then* we will bail out
        my $tested = &MAIN('test', @repos, :lib('blib/lib'), :$lib, 
            :$v, :$boring, :$async, :$shuffle, :force, :$no-wrap
        );
        my @failed-tests = eager gather for $tested.list -> $t {
            $t.map({ $_.processes.grep({ $_.nok }).map(-> $proc { take $proc }) });
        }
        die "!!!> Aborting. Test failures for: {@failed-tests.map(*.id)}" if !$report && !$force && @failed-tests.elems;

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
            my @ok = $reported.list.grep(*.<id>.so).list;
            print "===> Report{'s' if $reported.list.elems > 1} can be seen shortly at:\n" if @ok;
            print "\thttp://testers.perl6.org/reports/$_.html\n" for @ok.map({ $_.<id> });
        }

        my @all = $tested.list;
        my @failed = flat @all.map({ $_.failures });
        my @passed = flat @all.map({ $_.passes   });

        if @failed.elems {
            !$force
                ?? do { print "!!!> Failed {@failed.elems} tests. Aborting.\n" and exit @failed.elems }
                !! do { print "???> Failed tests. Using \$force\n"                    };
        }
        elsif !@passed.elems {
            print "???> No tests.\n";
        }
    }


    my $install = do {
        my $i = CLI-WAITING-BAR { 
            my @finished;
            for $built.list -> $dist {
                # todo: check against $tested to make sure tests were passed
                # currently we call &MAIN for each phase, thus creating a new
                # Zef::Distribution::Local object for each phase. This means the roles
                # do not carry over. The fix should work around is.

                # todo: refactor
                # some of these roles may already be applied. in such situations 
                # we don't want to duplicate the functionality.
                $dist does Zef::Roles::Processing[:$async, :$force] unless $dist.does(Zef::Roles::Processing);
                $dist does Zef::Roles::Hooking unless $dist.does(Zef::Roles::Hooking);
                $dist does Zef::Roles::Installing;

                my $max-width = $MAX-TERM-COLS if ?$no-wrap;

                my $before-procs = $dist.queue-processes: $($dist.hook-cmds(INSTALL, :before));
                procs2stdout(:$max-width, $before-procs) if $v;

                my $promise1 = $dist.start-processes;
                $promise1.result; # osx bug RT125758
                await $promise1;

                @finished.push: $dist.install(:$force);
                
                my $after-procs  = $dist.queue-processes: $($dist.hook-cmds(INSTALL, :after));
                procs2stdout(:$max-width, $after-procs) if $v;
                my $promise2 = $dist.start-processes;
                $promise2.result; # osx bug RT125758
                await $promise2;
            }
            @finished;
        }, "Installing", :$boring;

        my @all       = $i.list;
        my @installed = @all.grep({ !$_.<skipped> }).flat.list;
        my @skipped   = @all.grep({ ?$_.<skipped> }).flat.list;

        verbose('Install', @installed)                 if @installed.elems;
        verbose('Skip (already installed!)', @skipped) if @skipped.elems;
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
multi MAIN('get', *@modules, :$ignore, :$save-to = $*TMPDIR, :$projects-file is copy, 
    Bool :$async, Bool :$v, Bool :$boring, Bool :$skip-depends, 
    Bool :$skip-test-depends, Bool :$skip-build-depends) is export(:get :install) {


    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my $fetched = CLI-WAITING-BAR {
        temp $projects-file = packages(:$ignore, :packages-file($projects-file));
        Zef::Authority::P6C.new(:$projects-file).get(
            @modules, :ignore($ignore.list), :$save-to, :depends(!$skip-depends),
            :test-depends(!$skip-test-depends), :build-depends(!$skip-test-depends),
        );
    }, "Fetching", :$boring;

    verbose('Fetching', $fetched.list);

    unless $fetched.list {
        say "!!!> No matching candidates found.";
        exit 1;
    }

    return $fetched;
}


#| Build modules in the specified directory
multi MAIN('build', *@repos, :$lib, :$ignore, :$save-to = 'blib/lib', Bool :$v, Bool :$no-wrap,
    Bool :$async, Bool :$boring, Bool :$force = True) is export(:build :install) {
    @repos .= push($*CWD) unless @repos;
    @repos  = @repos.map({ $_.IO.is-absolute ?? $_ !! $_.IO.abspath }).list;


    my $dists := gather for @repos -> $path {
        state @perl6lib; # store paths to be used in -I in subsequent `depends` processes
        my $dist := Zef::Distribution::Local.new(
            path         => $path.IO, 
            precomp-path => (?$save-to.IO.is-relative
                ?? $save-to.IO.absolute($path).IO
                !! $save-to.IO.abspath.IO
            ),
            includes     => $lib.list.unique,
            perl6lib     => @perl6lib.unique,
        );
        $dist does Zef::Roles::Processing[:$async, :$force];
        $dist does Zef::Roles::Precompiling;
        $dist does Zef::Roles::Hooking;

        $dist.queue-processes: $($dist.hook-cmds(BUILD, :before));
        $dist.queue-processes($($_)) for $dist.precomp-cmds.list;
        $dist.queue-processes: $($dist.hook-cmds(BUILD, :after));

        @perl6lib.push: $dist.precomp-path.absolute;

        take $dist;
    };

    my $precompiled-dists = CLI-WAITING-BAR {
        my @finished;
        for $dists.list -> $dist-todo {
            my $max-width = $MAX-TERM-COLS if ?$no-wrap;
            procs2stdout(:$max-width, $dist-todo.processes) if $v;
            my $promise = $dist-todo.start-processes;
            $promise.result; # osx bug RT125758
            await $promise;
            @finished.push: $dist-todo;
        }
        @finished;
    }, "Precompiling", :$boring;

    for $precompiled-dists.list -> $precomp-dist {
        my @r;
        for $precomp-dist.processes -> $group {
            for $group.list -> $proc {
                for $proc.list -> $item {
                    my $result = { ok => all($item.ok), module => $item.id.IO.basename };

                    if !$force && !$result<ok> {
                        print "!!!> Precompilation failure. Aborting.\n";
                        exit 254;
                    }

                    @r.push($result);
                }
            }
        }
        verbose('Precompiling', @r);
    }

    return $precompiled-dists;
}

# todo: non-exact matches on non-version fields
# todo: restrict fields to those found in a todo: Zef::META type module
multi MAIN('search', :$projects-file is copy, :$ignore, Bool :$v, *@names, *%fields) is export(:search) {
    # Filter the projects.json file
    my $results = CLI-WAITING-BAR { 
        temp $projects-file = packages(:force, :$ignore, :packages-file($projects-file));
        Zef::Authority::P6C.new(:$projects-file).search(|@names, |%fields).list;
    }, "Querying for: name = {@names.join('|')}{~%fields}";

    say "===> Found " ~ $results.list.elems ~ " results";
    my @rows = eager gather for $results.list {
        once { take [<ID Package Version Description>] }
        take ["{state $id += 1}", $_.<name>,  ($_.<ver> // $_.<version> // '*'), ($_.<description> // '')]
    }

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
multi MAIN('info', *@modules, :$projects-file is copy, :$ignore, Bool :$v, Bool :$boring) is export(:info) {
    my @packages;
    my $results = CLI-WAITING-BAR { 
        temp $projects-file = packages(:force, :$ignore, :packages-file($projects-file));
        my $auth = Zef::Authority::P6C.new(:$projects-file);
        @packages = $auth.projects.list;
        $auth.search(|@modules).list;
    }, "Querying for: name = {@modules.join('|')}";


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
            my $deps := Zef::Utils::Depends.new(projects => @packages.list)\
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

# this should go into Zef::Authority
sub packages(Bool :$force, :$ignore, :$boring, :$packages-file) {
    use Zef::Utils::JSON;
    my $file = $packages-file // $*TMPDIR.child("p6c-packages.{~time}.{(1..10000).pick(1)}.json");
    state $p6c = Zef::Authority::P6C.new(:projects-files($file));
    once { $p6c.update-projects unless $p6c.projects.elems }

    my @packages = $p6c.projects.list;
    print "===> Module count: {@packages.elems}\n";
    if $ignore.list.elems {
        @packages = @packages\
            .grep({ $_.<name>:exists })\
            .grep({ $_.<name> ~~ none($ignore.list.grep(*.so)) })\
            .grep({ any($_.<depends>.list.grep(*.so))       ~~ none($ignore.list.grep(*.so)) })\
            .grep({ any($_.<test-depends>.list.grep(*.so))  ~~ none($ignore.list.grep(*.so)) })\
            .grep({ any($_.<build-depends>.list.grep(*.so)) ~~ none($ignore.list.grep(*.so)) })\
            .pick(*);
    }

    print "===> Filtered module count: {@packages.elems}\n";
    my $json = to-json(@packages.list);
    $file.IO.spurt($json);
    print "===> Package file: $file\n";
    return ~$file;
}

# will be replaced soon
sub verbose($phase, $work) {
    my $glr;
    try {
        # XXX nom compatability inside here
        fail unless $work.list.[0].isa(Pair);
        $glr = @($work,());
    }
    $glr //= $work;
    my %r = $glr.list.grep(*.so).classify({ ?$_.hash.<ok> ?? 'ok' !! 'nok' }).hash;

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
    return @rows[0].keys.map: { @rows>>[$_]>>.chars.max }
}
