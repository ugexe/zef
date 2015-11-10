unit class Zef::App;

use PathTools;
use Storage;

use Zef::CLI;

use Zef::Utils::JSON;
use Zef::Utils::SystemInfo;

use Zef::Distribution::Local;
use Zef::Manifest;

use Zef::Roles::Installing;
use Zef::Roles::Precompiling;
use Zef::Roles::Processing;
use Zef::Roles::Testing;
use Zef::Roles::Hooking;

use Zef::Authority::P6C;
use Zef::Authority::Local;

my $ZEF_HOME_DIR = $*HOME.child(".zef")        andthen do { mkdir($_) unless $_.IO.e }
my $ZEF_GIT_DIR  = $ZEF_HOME_DIR.child("git")  andthen do { mkdir($_) unless $_.IO.e }

#| Build modules in the specified directory
multi MAIN('build', *@repos, :$lib, :$ignore, :$save-to = 'blib/lib', Bool :$v, Bool :$no-wrap,
    Int :$jobs, Bool :$boring, Bool :$force = True, Bool :$no-build) is export {

    @repos .= append($*CWD) unless @repos;

    my @built-dists = CLI-WAITING-BAR {
        my @does = Zef::Roles::Processing[:$jobs, :$force], Zef::Roles::Hooking;
        @does.append(Zef::Roles::Precompiling) unless ?$no-build;
        my @dists = DISTS(:$lib, :@does, |@repos).map: -> $dist {
            $dist.queue-processes: $($dist.hook-cmds(BUILD, :before));
            unless ?$no-build { # allow Build.pm to run :/
                $dist.queue-processes($($_)) for $dist.precomp-cmds.cache;
            }
            $dist.queue-processes: $($dist.hook-cmds(BUILD, :after));
            $dist;
        }
        my @built = @dists.map( -> $dist-todo {
            my $max-width = $MAX-TERM-COLS if ?$no-wrap;
            procs2stdout(:$max-width, $dist-todo.processes) if $v;
            my $promise = $dist-todo.start-processes;
            $promise.result; # osx bug RT125758
            await $promise;
            $dist-todo;
        }).Slip;
    }, "Building", :$boring;

    my @r = @built-dists>>.map( -> $dist {
        my @results = eager gather for $dist.processes -> @group {
            for @group -> $proc {
                for @$proc -> $item {
                    take %( :ok($item.ok), :id($item.id.IO.basename) );

                    if !$force && !$item<ok> {
                        print "!!!> Precompilation failure. Aborting.\n";
                        exit 254;
                    }
                }
            }
        }
        %( :ok(all(@results>><ok>)), :unit-id($dist.name), :results(@results) );
    })>>.Slip;

    verbose('Building', |@r);

    @built-dists;
}

#| Test modules in the specified directories
multi MAIN('test', *@repos, :$lib, Int :$jobs, Bool :$v, Bool :$no-test,
    Bool :$boring, Bool :$shuffle, Bool :$force, Bool :$no-wrap, Bool :$no-build) is export {
    
    # todo: better handling of blib/precomp testing other than passing $no-build option (use $lib?)
    @repos .= append($*CWD) unless @repos;

    my @tested-dists = CLI-WAITING-BAR {
        my @does   = Zef::Roles::Processing[:$jobs, :$force], Zef::Roles::Hooking;
        @does.append(Zef::Roles::Testing) unless ?$no-test;
        my @dists  = DISTS(:$lib, :@does, |@repos).map: -> $dist {
            $dist.queue-processes: $($dist.hook-cmds(TEST, :before));
            unless ?$no-test {
                $dist.queue-processes($($dist.test-cmds.cache));
            }
            $dist.queue-processes: $($dist.hook-cmds(TEST, :after));
            $dist;
        }
        my @tested = @dists.map( -> $dist-todo {
            my $max-width = $MAX-TERM-COLS if ?$no-wrap;
            procs2stdout(:$max-width, $dist-todo.processes) if $v;
            my $promise = $dist-todo.start-processes;
            $promise.result; # osx bug RT125758
            await $promise;
            $dist-todo;
        });
    }, "Testing", :$boring;

    my @r = @tested-dists>>.map( -> $dist {
        my @results = eager gather for $dist.processes -> @group {
            for @group -> $proc {
                for @$proc -> $item {
                    if !$force && !$item.ok {
                        print "!!!> Test failure. Aborting.\n";
                        exit 254;
                    }

                    take %( :ok($item.ok), :id($item.id.IO.basename) );
                }
            }
        }
        %( :ok(all(@results>><ok>)), :unit-id($dist.name), :results(@results) );
    })>>.Slip;

    verbose('Testing', |@r);

    @tested-dists;
}


multi MAIN('smoke', :$ignore, Bool :$no-wrap, :$projects-file is copy, Bool :$dry,
    Bool :$report, Bool :$v, Bool :$boring, Bool :$shuffle, Int :$jobs) is export {
    say "===> Smoke testing started: [{time}]";

    my @packages = packages(:$ignore, :packages-file($projects-file)).cache;

    say "===> Filtered module count: {@packages.elems}";

    # todo: save to a custom CURLI so the install command can automatically ignore modules
    # that have already been tested to satisfy earlier dependencies.
    for @packages -> $result {
        # todo: fix first argument so it invokes the bin wrapper directly if it can find it,
        # else try to invoke $*PROGRAM?
        my @args = 'zef', '--boring', "--projects-file={$projects-file}";
        @args.append('-v')           if $v;
        @args.append('--report')     if $report;
        @args.append('--dry')        if $dry;
        @args.append('--shuffle')    if $shuffle;
        @args.append('--no-wrap')    if $no-wrap;
        @args.append("--jobs=$jobs") if $jobs;
        @args.append("--ignore=$_")  for $ignore.grep(*.so).cache;

        say "===> Smoking next: {$result.<name>}";
        my $proc = run(@args.grep(*.so).cache, 'install', $result.<name>, :out);

        say $_ for $proc.out.lines;
    }

    say "===> Smoke testing ended [{time}]";
}


multi MAIN('uninstall', *@names, :$auth, :$ver, :$from = %*CUSTOM_LIB<site>, Bool :$v) {
    my $ok;
    my $nok;

    for $from.cache -> $cur {
        with CompUnitRepo::Local::Installation.new($cur) -> $curli {
            my $mani = Zef::Manifest.new(:cur($curli), :create);
            for @names.cache -> $name {
                for $curli.candidates($name, :$auth, :$ver) -> $candi {
                    my $dist = Distribution.new(:name($candi<name>), :auth($candi<auth>), :ver($candi<ver>));

                    if $mani.uninstall($dist) -> @deleted {
                        say "===> [{$dist.name}] Deleted files: " ~ @deleted>>.IO>>.basename.join(',') if $v;
                        say "===> Uninstalled {$dist.name} successfully";
                        $ok++;
                    }
                    else {
                        say "!!!> Uninstall for {$dist.name} failed";
                        $nok++;
                    }
                }
            }
        }
    }

    say "!!!> Nothing to do." unless $ok || $nok;
    exit $nok.so ?? $nok !! 0;
}

#| Install with business logic
multi MAIN('install', *@modules, :$lib, :$ignore, :$save-to = $*TMPDIR, :$projects-file is copy, 
    Bool :$no-test, Bool :$no-build = True, Bool :$force = False, Int :$jobs, Bool :$report, Bool :$v, 
    Bool :$dry, Bool :$skip-depends, Bool :$skip-build-depends is copy, Bool :$skip-test-depends is copy,
    Bool :$shuffle, Bool :$no-wrap, Bool :$boring) is export {

    # hooks still need depends... should set these accordingly
    # $skip-build-depends = True if ?$no-build && !$skip-build-depends.defined;
    # $skip-test-depends  = True if ?$no-test  && !$skip-build-depends.defined;

    # todo:
    # Change workflow so we can check the packages file and remove already installed modules 
    # if needed, so that we don't attempt a possibly pointless `git pull`.
    # Cannot just use :ignore, as this removes modules that depend on anything ignored.
    # Add :skip to act like ignore, but not follow depends?

    # FETCHING
    my @fetched = &MAIN('get', @modules, :ignore($ignore.cache),
        :$save-to, :$projects-file, :$boring, :$jobs,
        :$skip-depends, :$skip-build-depends, :$skip-test-depends,
    );

    # VALIDATION
    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m = flat @fetched>>.grep(*.<ok>.so);

    verbose('META.info availability', @m);

    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep(*.<ok>.so).map: { $_.<path>.IO.is-absolute ?? $_.<path> !! $_.<path>.IO.abspath }

    # META file check
    my @metas = eager gather for @repos -> $repo-path {
        if $repo-path.IO.child('META.info').IO.e {
            take $repo-path.IO.child('META.info');
        }
        elsif $repo-path.IO.child('META6.json').IO.e {
            take $repo-path.IO.child('META6.json');
        }
    }
    my @failed-metas = @metas.grep: {!$_.IO.child('META.info').IO.e &&  !$_.IO.child('META6.json').IO.e }\
        unless @metas.elems == @repos.elems;
    die "!!!> Aborting. Missing META info for: {@failed-metas}" if !$force && @failed-metas.elems;


    # Prevent processing modules that are already installed with the same or greater version.
    # Version '*' is always installed for now.
    my @dists  = DISTS(:$lib, |@repos);
    my @wanted = @dists.grep:  { $_.wanted || ($force && $_.name ~~ any(@modules)) }
    my @have   = @dists.grep:  { $_.name !~~ any(@wanted>>.name) }
    @wanted    = @wanted.grep: { $_.name ~~ none(@have)          } if @have.elems;

    if @wanted.elems != @dists.elems {
        print "===> The following modules are already up to date: {@have.map(*.name).join(', ')}\n";
        if !$force {
            @repos = @repos.grep: -> $rp { none(@have.map(*.path).grep(*.ACCEPTS($rp.IO)))         }
            @metas = @metas.grep: -> $mp { none(@have.map(*.path).grep(*.ACCEPTS($mp.dirname.IO))) }
        }
        print "===> ...but using --force\n" if ?$force;
        print "===> Nothing to do.\n" and exit 0 unless @repos.elems && @metas.elems;
    }

    # BUIDLING
    my @built = do {
        my @built  = &MAIN('build', |@dists, :save-to('blib/lib'), :$lib, :$v, :$boring, :$jobs, :$no-wrap, :$no-build);
        my @procs  = flat @built>>.processes>>.Slip;
        my @failed = flat @procs>>.grep(*.nok);
        die "!!!> Aborting. Build failures for: {@failed>>.id}" if !$report && !$force && @failed.elems;
        @built>>.Slip;
    }

    # TESTING
    my @tested = do {
        my @to-test = (?$force || !@built.elems) ?? @repos !! @built;
        my @tested = &MAIN('test', @to-test, :$lib,
            :$v, :$boring, :$jobs, :$shuffle, :force, :$no-wrap, :$no-build, :$no-test
        );
        my @procs  = flat @tested>>.processes>>.Slip;
        my @failed = flat @procs>>.grep(*.nok);
        die "!!!> Aborting. Test failures for: {@failed>>.id}" if !$report && !$force && @failed.elems;
        @tested>>.Slip;
    }

    # Send a build/test report
    if ?$report && !$no-test {
        my @reported = CLI-WAITING-BAR {
            my @reports = Zef::Authority::P6C.new.report(
                @metas,
                :test-results(@tested),
                :build-results(@built),
            );
        }, "Reporting", :$boring;

        verbose('Reporting', |@reported);

        my @ok = flat @reported>>.grep(*.<report-id>.so);
        print "===> Report{'s' if @reported.elems > 1} can be seen shortly at:\n" if @ok;
        print "\thttp://testers.perl6.org/reports/$_.html\n" for @ok>><report-id>;
    }

    my @failed-tests = flat @tested>>.failures>>.Slip if @tested;
    my @passed-tests = flat @tested>>.passes>>.Slip   if @tested;

    if @failed-tests.elems {
        !$force
            ?? do { print "!!!> {@failed-tests.elems} packages failed testing. Aborting.\n" and exit @failed-tests.elems }
            !! do { print "!==> {@failed-tests.elems} packages failed testing. [but using --force to continue]\n"  };
    }
    elsif !@passed-tests.elems {
        ?$no-test
            ?? do { print "===> Testing skipped\n" }
            !! do { print "???> No tests\n"        }
    }

    my @installed = do {
        my @results = CLI-WAITING-BAR {
            my @to-do     = @tested.elems ?? @tested !! @built.elems ?? @built !! @repos;
            my @does      = Zef::Roles::Processing[:$force], Zef::Roles::Hooking, Zef::Roles::Installing;
            my @dists     = DISTS(:$lib, :@does, |@to-do);
            my @installed = flat @dists.map( -> $dist {
                my $max-width = $MAX-TERM-COLS if ?$no-wrap;

                my $before-procs = $dist.queue-processes: $($dist.hook-cmds(INSTALL, :before));
                procs2stdout(:$max-width, $before-procs) if $v;

                my $promise1 = $dist.start-processes;
                $promise1.result; # osx bug RT125758
                await $promise1;

                my @result = $dist.install(:$force);
                
                my $after-procs  = $dist.queue-processes: $($dist.hook-cmds(INSTALL, :after));
                procs2stdout(:$max-width, $after-procs) if $v;
                my $promise2 = $dist.start-processes;
                $promise2.result; # osx bug RT125758
                await $promise2;

                @result.Slip;
            });
        }, "Installing", :$boring;

        my @tried   = flat @results>>.grep({ !$_.<skipped> });
        my @skipped = flat @results>>.grep({ ?$_.<skipped> });

        verbose('Install', @tried)                     if @tried.elems;
        verbose('Skip (already installed!)', @skipped) if @skipped.elems;
        @results.Slip;
    } unless ?$dry;

    my @failed-install = flat @installed>>.grep({ !$_<ok> });
    my @passed-install = flat @installed>>.grep({ ?$_<ok> });

    exit ?$dry ?? 0 !! @failed-install.elems;
}


# Not Yet Reimplemented?
#! Download a single module and change into its directory
multi MAIN('look', $module, Bool :$v, :$save-to = $*CWD.IO.child(time)) is export { 
    my $auth = Zef::Authority::P6C.new;
    my @g = $auth.get: $module, :$save-to;
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
multi MAIN('get', *@modules, :$ignore, :$save-to is copy = $*TMPDIR, :$projects-file is copy, 
    Int :$jobs, Bool :$v, Bool :$boring, Bool :$skip-depends, 
    Bool :$skip-test-depends, Bool :$skip-build-depends) is export {

    my @gits;
    my @locals;
    my @identifiers;

    for @modules -> $m {
        given $m {
            when *.starts-with('.' | '/') { @locals.append($_) }
            when *.starts-with('git://')  { @gits.append($_)   }
            when *.starts-with('git@')    { @gits.append($_)   }
            when *.starts-with('https://') && *.index('.git')  { 
                @gits.append($_)
            }
            default { @identifiers.append($_) }
        }
    }

    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my @fetched = CLI-WAITING-BAR {
        my @f;

        # This should all be put into a Storage module which handles fetching based on scheme/identity-spec/source-type
        if @gits.elems {
            for @gits -> $source-uri {
                my $store = Storage.new($save-to, $source-uri);
                my @dists-from-store = $store.rms>>.dist;
                @locals.append(~$_) for @dists-from-store>>.path;
            }
        }

        if @locals.elems {
            my @packages = packages(:$ignore, :packages-file($projects-file));

            @f.append: Zef::Authority::Local.new(:projects(@packages)).get(
                @locals, :ignore($ignore.cache), :$save-to, :depends(!$skip-depends),
                :test-depends(!$skip-test-depends), :build-depends(!$skip-build-depends),
            );
        }

        if @identifiers.elems {
            my @packages = packages(:ignore($ignore.cache), :packages-file($projects-file));
            @f.append: Zef::Authority::P6C.new(:projects(@packages)).get(
                @identifiers, :ignore($ignore.cache), :$save-to, :depends(!$skip-depends),
                :test-depends(!$skip-test-depends), :build-depends(!$skip-build-depends),
            );
        }

        @f.Slip;
    }, "Fetching", :$boring;

    verbose('Fetching', |@fetched);

    unless @fetched.grep(*.so).elems {
        say "!!!> No matching candidates found.";
        exit 1;
    }

    @fetched;
}

# todo: non-exact matches on non-version fields
# todo: restrict fields to those found in a todo: Zef::META type module
multi MAIN('search', :$projects-file is copy, :$ignore, Bool :$v, *@names, *%fields) is export {
    # Filter the projects.json file
    my $results = CLI-WAITING-BAR { 
        my @projects = packages(:force, :$ignore, :packages-file($projects-file));
        Zef::Authority::P6C.new(:@projects).search(|@names, |%fields).cache;
    }, "Querying for: name = {@names.join('|')}{~%fields}";

    say "===> Found " ~ $results.cache.elems ~ " results";
    my @rows = eager gather for $results.cache {
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
multi MAIN('info', *@modules, :$projects-file is copy, :$ignore, Bool :$v, Bool :$boring) is export {
    my @packages;
    my $results = CLI-WAITING-BAR { 
        my @projects = packages(:force, :$ignore, :packages-file($projects-file));
        my $auth = Zef::Authority::P6C.new(:@projects);
        @packages = $auth.projects.cache;
        $auth.search(|@modules).cache;
    }, "Querying for: name = {@modules.join('|')}";


    say "===> Found " ~ $results.cache.elems ~ " results";

    for $results.cache -> $meta {
        print "[{$meta.<name>}]\n";
        print "# Version: {$meta.<version> // $meta.<vers> // '*'}\n";
        print "# Auth:\t {$meta.<auth>}\n"                                   if $meta.<auth>;
        print "# Authority:\t {$meta.<authority>}\n"                         if $meta.<authority>;
        print "# Author:\t {$meta.<author>}\n"                               if $meta.<author>;
        print "# Authors:\t {$meta.<authors>.grep(*.so).cache.join(', ')}\n" if $meta.<authors>.grep(*.so).cache.elems;
        print "# Description:\t {$meta.<description>}\n"                     if $meta.<description>;
        print "# Source-url:\t {$meta.<source-url>}\n"                       if $meta.<source-url>;
        print "# Source:\t {$meta.<source>}\n"                               if $meta.<source>;

        if $meta.<provides> {
            print "# Provides: {$meta.<provides>.cache.elems} items\n";
            if $v { print "#\t$_\n" for $meta.<provides>.keys }
        }

        if $meta.<support> {
            print "# Support:\n";
            for $meta.<support>.kv -> $k, $v {
                print "#   $k:\t$v\n";
            }
        }

        if $meta.<depends>.cache.elems -> $dep-count {
            once print "# Depends: {$dep-count} items\n";

            if $v {
                my $deps = Zef::Utils::Depends.new(projects => @packages.cache)\
                    .topological-sort($meta);

                for $deps.cache.kv -> $i1, $level {
                    for $level.cache.kv -> $i2, $dep {
                        my $mark = $dep ~~ any($meta.<depends>.cache) ?? '*' !! ' ';
                        print "#  $mark $i1\.$i2) $dep\n";
                    }
                }
            }
            else {
                for $meta.<depends>.kv -> $k, $v {
                    print "#   $k)\t$v\n";
                }
            }
        }
    }
}

sub DISTS(:$lib, :@does, *@repos) {
    my @dists;
    my @perl6lib;
    for @repos -> $r {
        my $dist =  do given $r {
            when ::('Zef::Distribution::Local') {
                $r;
            }
            when IO::Path | Str {
                my $new-dist = Zef::Distribution::Local.new( :path($_.IO.is-absolute ?? $_.IO !! $_.IO.abspath) );
                $new-dist;
            }
        }

        for @does -> $role { $dist does $role unless $dist.does($role) }

        $dist.includes = $lib.cache if $lib.grep(*.so);
        $dist.perl6lib.append($_) for @perl6lib;
        $dist.perl6lib = $dist.perl6lib.unique.cache;

        @perl6lib.append($dist.precomp-path.absolute) if $dist.precomp-path;
        @perl6lib.append($dist.source-path.absolute)  if $dist.source-path;

        @dists.append($dist);
    }

    @dists;
}

sub packages(Bool :$force, :$ignore, :$boring, :$packages-file) {
    my @packages = $packages-file ?? from-json($packages-file.IO.slurp) !! git-package-json('p6c').cache;
    print "===> Module count: {@packages.elems}\n";

    if $ignore && $ignore.elems {
        my @filtered = filter-packages(|@packages, :$ignore).cache;
        print "===> Filtered module count: {@filtered.elems}\n";
        @packages = @filtered;
    }
    
    @packages;
}

sub filter-packages(*@packages, :$ignore) {
    return @packages unless ?$ignore && $ignore.elems;
    my @ = @packages\
        .grep({ $_.<name>:exists })\
        .grep({ $_.<name> ~~ none($ignore.grep(*.so)) })\
        .grep({ any($_.<depends>.grep(*.so))       ~~ none($ignore.grep(*.so)) })\
        .grep({ any($_.<test-depends>.grep(*.so))  ~~ none($ignore.grep(*.so)) })\
        .grep({ any($_.<build-depends>.grep(*.so)) ~~ none($ignore.grep(*.so)) })\
        .pick(*);
}

our $GIT_EXE = 'git';
sub git-shell(:$cwd = $*CWD, :$out = False, :$err = False, :$in = False, *@_, *%_) {
    my %args  = |%_.classify({ .value === True ?? 'flags' !! 'opts' });
    my @flags = do with %args<flags> {.hash.keys.map: { $_.chars == 1 ?? "-{$_}" !! "--{$_}" }}
    my @opts  = do with %args<opts>  {.map: { qq|--{.key}="{.value}"| }}
    my $proc  = ?%_<quiet>
        ?? (run( $GIT_EXE, |@opts, |@_, :$cwd, :out, :err ) andthen ($_.out.close && $_.err.close))
        !!  run( $GIT_EXE, |@opts, |@_, :$cwd , :out($out) );
}

sub git-update-index(:$cwd) {
    try { so git-shell('update-index', :$cwd) }
}

sub git-ls(:$cwd) {
    git-update-index(:$cwd);
    my $p  = git-shell(qq|ls-files|, :$cwd, :out);
    my $nl = Buf.new(10).decode; # TEMPORARY: split(/regex/) doesn't work on jvm yet, and windows
                                 # proc output uses "\n" for proc.out line endings unlike everything else
    my @lines <== grep *.so <== split $nl, $p.out.slurp-rest;
    $p.out.close;
    @lines;
}

sub git-package-json($name) {
    my $eco-dir = $ZEF_GIT_DIR.child('packages');

    try {
        my sub fetch(|c) { git-shell('fetch', '--depth=1', '--quiet', :cwd($eco-dir)) }

        # clone or fetch
        $eco-dir.IO.child('.git').IO.e ?? fetch() !! do {
            git-shell('clone', '--depth=1', '--quiet', 'https://github.com/ugexe/Perl6-ecosystems.git', $eco-dir, :cwd($eco-dir.IO.dirname));
            CATCH {
                when X::Proc::Unsuccessful {
                    if .proc.exitcode == 127 {
                        fetch;
                    }
                    elsif .proc.exitcode == 128 {
                        die "directory already exists and is not empty";
                    }
                }
                default { die "Don't know how to handle this error: $_" }
            }
        }
    }

    my $eco          = git-ls(:cwd($eco-dir)).first(*.lc eq "{$name}.json".lc);
    my $eco-json     = $eco-dir.IO.child($eco).IO.slurp;
    my $eco-projects = from-json($eco-json);   
}


# will be replaced soon
sub verbose($phase, @work) {
    my %r = @work.classify({ ?$_<ok> ?? 'ok' !! 'nok' });
    if %r<ok>  -> @ok  { print "===> $phase OK for: {@ok>><unit-id>.join(', ')}\n" }
    if %r<nok> -> @nok {
        for @nok -> $failed {
            once print "!!!> $phase FAILED: {@nok>><unit-id>}\n";
            my $to-print = "!> {$failed<unit-id>}";
            with $failed<results> -> $f { $to-print ~= ": {$f.grep(!*<ok>)>><id>.join(', ')}" }
            $to-print ~= "\n";
            print $to-print;
        }
    }
    %( :ok(%r<ok>.elems), :nok(%r<nok>.elems) )
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
