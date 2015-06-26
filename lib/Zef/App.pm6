unit class Zef::App;

#core modes 
use Zef::Authority::P6C;
use Zef::Builder;
use Zef::Config;
use Zef::Installer;
use Zef::Test;
use Zef::Uninstaller;
use Zef::Utils::PathTools;

# load plugins from config file
BEGIN our @plugins := %config<plugins>.list;

# when invoked as a class, we have the usual @.plugins
has @!plugins;

# override config file plugins if invoked as a class
# *and* :@plugins was passed to initializer 
#submethod BUILD(:@!plugins) { 
#    @plugins := @!plugins if @!plugins.defined;
#}

# will be replaced soon
sub verbose($phase, @_) {
    return unless @_;
    my %r = @_.classify({ $_.hash.<ok> ?? 'ok' !! 'nok' });
    print "!!!> $phase failed for: {%r<nok>.list.map({ $_.hash.<module> })}\n" if %r<nok>;
    print "===> $phase OK for: {%r<ok>.list.map({ $_.hash.<module> })}\n"      if %r<ok>;
    return { ok => %r<ok>.elems, nok => %r<nok> }
}


sub show-await($message, *@promises) {
    my $loading = Supply.interval(1);
    my $out = $*OUT;
    my $err = $*ERR;
    my $in  = $*IN;
    my @queue;

    $*ERR = $*OUT = class :: {
        my $lock = Lock.new;
        my $e;
        my $m;
        my $last-line-len = 0;

        $loading.tap({
            $e = do given ++$m { 
                when 2  { "-==" }
                when 3  { "=-=" }
                when 4  { "==-" }
                default { $m = 1; "===" }
            }

            print "";
        });

        method print(*@_) {
            my $hijacked  = @_.join;
            $lock.protect({
                my $msg       = "$e> $message...\r";
                my $output    = ($last-line-len ?? ((" " x $last-line-len) ~ "\r") !! '') ~ $hijacked ~ $msg;
                $last-line-len = $output.lines.[*-1].chars;

                my $out2 = $*OUT;
                $*ERR = $*OUT = $out;
                print $output;
                $*ERR = $*OUT = $out2;
            });
        }
        method flush {}
    }

    await Promise.allof: @promises;
    $loading.close;
    $*ERR = $err;
    $*OUT = $out;
}


#| Test modules in the specified directories
multi MAIN('test', *@paths, Bool :$v) is export {
    my @repos = @paths ?? @paths !! $*CWD;


    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $test-promise = Promise.new;
    my $test-vow     = $test-promise.vow;
    my $test-await   = start { show-await("Testing", $test-promise) };
    my @includes = gather for @repos -> $path {
        take $*SPEC.catdir($path, "blib");
        take $*SPEC.catdir($path, "lib");
    }
    my @t = @repos.map: -> $path { Zef::Test.new(:$path, :@includes) }
    my $longest = @t.list>>.test>>.list.reduce({ # for verbose output formatting
        $^a.file.IO.basename.chars > $^b.file.IO.basename.chars ?? $^a !! $^b
    }).file.IO.basename.chars if $v;
    for @t.list>>.test>>.list.grep({$v}) -> $tst {
        my $tfile = $tst.file.IO.basename;
        my $spaces = $longest - $tfile.chars;
        $tst.stdout.tap(-> $stdout {
            if $stdout.words {
                my $prefix = $tfile ~ (' ' x $spaces) ~ "# ";
                print $prefix ~ $stdout.subst(/\n/, "\n$prefix", :x( ($stdout.lines.elems // 1) - 1)).chomp ~ "\n";
            }
        });
        $tst.stderr.tap(-> $stderr {
            if $stderr.words {
                my $prefix = $tfile ~ (' ' x $spaces) ~ "# ";
                print $prefix ~ $stderr.subst(/\n/, "\n$prefix", :x( ($stderr.lines.elems // 1) - 1)).chomp ~ "\n";
            }
        });

    }
    await Promise.allof: @t.list>>.results>>.list>>.promise;
    $test-vow.keep(1);
    await $test-await;
    my $r = verbose('Testing', @t.list>>.results>>.list.map({ ok => all($_>>.ok), module => $_>>.file.IO.basename }));
    print "Failed tests. Aborting.\n" and exit $r<nok> if $r<nok>;


    exit 0;
}


#| Install with business logic
multi MAIN('install', *@modules, Bool :$report, IO::Path :$save-to = $*TMPDIR, Bool :$v) is export {
    my $SPEC := $*SPEC;
    my $auth  = Zef::Authority::P6C.new;

    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my $get-promise = Promise.new;
    my $get-vow     = $get-promise.vow;
    my $get-await   = start { show-await("Fetching", $get-promise) };
    my @g = $auth.get: @modules, :$save-to;
    $get-vow.keep(1);
    await $get-await;
    verbose('Fetching', @g);


    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m = @g.grep({ $_<ok> }).map({ $_<ok> = ?$SPEC.catpath('', $_.<path>, "META.info").IO.e; $_ });
    verbose('META.info availability', @m);
    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep({ $_<ok> }).map({ $_.<path> });
    my @metas = @repos.map({ $SPEC.catpath('', $_, "META.info").IO.path });


    # Precompile all modules and dependencies
    my $build-promise = Promise.new;
    my $build-vow     = $build-promise.vow;
    my $build-await   = start { show-await("Building", $build-promise) };
    my @b = Zef::Builder.new.pre-compile: @repos;
    $build-vow.keep(1);
    await $build-await;
    verbose('Build', @b);


    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my $test-promise = Promise.new;
    my $test-vow     = $test-promise.vow;
    my $test-await   = start { show-await("Testing", $test-promise) };
    my @includes = gather for @repos -> $path {
        take $SPEC.catdir($path, "blib");
        take $SPEC.catdir($path, "lib");
    }
    my @t = @repos.map: -> $path { Zef::Test.new(:$path, :@includes) }
    my @test-files = @t.list>>.test-files>>.IO>>.basename; # For templating: `00-testfile.t[spaces]# [output]`
    my $longest = @test-files.reduce({ $^a.chars > $^b.chars ?? $^a !! $^b }).chars if $v; # Spaces needed for template^^
    for @t.list>>.test>>.list.grep({$v}) -> $tst { # Print verbose test output
        my $tfile  = $tst.file.IO.basename;
        my $spaces = $longest - $tfile.chars;
        $tst.stdout.tap(-> $stdout {
            if $stdout.words {
                my $prefix = $tfile ~ (' ' x $spaces) ~ "# ";
                print $prefix ~ $stdout.subst(/\n/, "\n$prefix", :x( ($stdout.lines.elems // 1) - 1)).chomp ~ "\n";
            }
        });
        $tst.stderr.tap(-> $stderr {
            if $stderr.words {
                my $prefix = $tfile ~ (' ' x $spaces) ~ "# ";
                print $prefix ~ $stderr.subst(/\n/, "\n$prefix", :x( ($stderr.lines.elems // 1) - 1)).chomp ~ "\n";
            }
        });

    }
    await Promise.allof: @t.list>>.results>>.list>>.promise;
    $test-vow.keep(1);
    await $test-await;
    my $r = verbose('Testing', @t.list>>.results>>.list.map({ ok => all($_>>.ok), module => $_>>.file.IO.basename }));
    print "Failed tests. Aborting.\n" and exit $r<nok> if $r<nok>;


    # Send a build/test report
    if ?$report {
        my $report-promise = Promise.new;
        my $report-vow     = $report-promise.vow;
        my $report-await   = start { show-await("Uploading Test Reports", $report-promise) };
        my @r = $auth.report(
            @metas,
            test-results  => @t, 
            build-results => @b,
        );
        $report-vow.keep(1);
        await $report-await;
        verbose('Reporting', @r);
        print "===> Report{'s' if @r.elems > 1} can be seen shortly at:\n";
        print "\thttp://testers.perl6.org/reports/$_.html\n" for @r.grep(*.<id>).map({ $_.<id> });
    }


    my $install-promise = Promise.new;
    my $install-vow     = $install-promise.vow;
    my $install-await   = start { show-await("Installing", $install-promise) };
    my @i = Zef::Installer.new.install: @metas;
    $install-vow.keep(1);
    await $install-await;
    verbose('Install', @i.grep({ !$_.<skipped> }));
    verbose('Skip (already installed!)', @i.grep({ ?$_.<skipped> }));


    # exit code = number of modules that failed the install process
    exit @modules.elems - @i.grep({ !$_<ok> }).elems;
}


#| Install local freshness
multi MAIN('local-install', *@modules) is export {
    say "NYI";
}


#! Download a single module and change into its directory
multi MAIN('look', $module, :$save-to = $*SPEC.catdir($*CWD,time)) { 
    my $auth = Zef::Authority::P6C.new;
    my @g    = $auth.get: $module, :$save-to, :skip-depends;
    verbose('Fetching', @g);

    if @g.[0].<ok> {
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
multi MAIN('get', *@modules, :$save-to = $*TMPDIR, Bool :$skip-depends) is export {
    my $auth = Zef::Authority::P6C.new;
    my @g    = $auth.get: @modules, :$save-to, :$skip-depends;
    verbose('Fetching', @g);
    say $_.<path> for @g.grep({ $_.<ok> });
    exit @g.grep({ not $_.<ok> }).elems;
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directory
multi MAIN('build', $path, :$save-to) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path, :$save-to);
}


multi MAIN('search', *@terms) {
    say "NYI";
}
