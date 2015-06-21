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
    say "!!!! $phase failed for: {%r<nok>.list.map({ $_.hash.<module> })}" if %r<nok>;
    say "===> $phase OK for: {%r<ok>.list.map({ $_.hash.<module> })}" if %r<ok>;
    return { ok => %r<ok>.elems, nok => %r<nok> }
}


#| Test modules in the specified directories
multi MAIN('test', *@paths, Bool :$v) is export {
    my @repos = @paths ?? @paths !! $*CWD;
    my @t = @repos.map: -> $path { Zef::Test.new(:$path) }
    @t.list>>.test>>.list.grep({$v})>>.stdout>>.tap(*.say); # start tests and tap output if -v
    await Promise.allof: @t.list>>.results>>.list>>.promise;
    my $r = verbose('Testing', @t.list>>.results>>.list.map({ ok => all($_>>.ok), module => $_>>.file.IO.basename }));
    exit ?$r<nok> ?? $r<nok> !! 0;
}

#| Install with business logic
multi MAIN('install', *@modules, Bool :$report, Bool :$v) is export {
    my $auth = Zef::Authority::P6C.new;

    # Download the requested modules from some authority
    # todo: allow turning dependency auth-download off
    my @g = $auth.get: @modules;
    verbose('Fetching', @g);

    # Ignore anything we downloaded that doesn't have a META.info in its root directory
    my @m = @g.grep({ $_<ok> }).map({ $_<ok> = ?$*SPEC.catpath('', $_.<path>, "META.info").IO.e; $_ });
    verbose('META.info availability', @m);

    # An array of `path`s to each modules repo (local directory, 1 per module) and their meta files
    my @repos = @m.grep({ $_<ok> }).map({ $_.<path> });
    my @metas = @repos.map({ $*SPEC.catpath('', $_, "META.info").IO.path });

    # Precompile all modules and dependencies
    my @b = Zef::Builder.new.pre-compile: @repos;
    verbose('Build', @b);

    # Test all modules (important to pass in the right `-Ilib`s, as deps aren't installed yet)
    # (note: first crack at supplies/parallelization)
    my @t = @repos.map: -> $path { Zef::Test.new(:$path) }
    @t.list>>.test>>.list.grep({$v})>>.stdout>>.tap(*.say);
    await Promise.allof: @t.list>>.results>>.list>>.promise;
    verbose('Testing', @t.list>>.results>>.list.map({ ok => all($_>>.ok), module => $_>>.file.IO.basename }));

    # Send a build/test report
    my @r = $auth.report(
        @metas,
        test-results  => @t, 
        build-results => @b,
    ) and verbose('Reporting', @r) if ?$report;
    say "===> Report{'s' if @r.elems > 1} can be seen shortly at:";
    say "\thttp://testers.perl6.org/reports/$_.html" for @r.grep(*.<id>).map({ $_.<id> });

    # Install the modules
    my @i = Zef::Installer.new.install: @metas;
    verbose('Install', @i.grep({ !$_.<skipped>}));
    verbose('Skip (already installed!)', @i.grep({ ?$_.<skipped> }));

    # exit code = number of modules that failed the install process
    exit @modules.elems - @i.grep({ !$_<ok> }).elems;
}


#| Install local freshness
multi MAIN('local-install', *@modules) is export {
    my $installer = Zef::Installer.new(:@plugins);
    $installer.install($_) for @modules;
}


#| Get the freshness
multi MAIN('get', :$save-to = "$*CWD/{time}", *@modules) is export {
    say "NYI";
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directories
multi MAIN('build', $path, :$save-to) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path, :$save-to);
}


multi MAIN('search', *@terms) {
    say "NYI";
}
