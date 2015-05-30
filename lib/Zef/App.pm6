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


#| Test modules in the specified directories
multi MAIN('test', *@paths, Bool :$v) is export {
    @paths = $*CWD unless @paths;

    my @testers      = @paths.map: -> $path { Zef::Test.new(:$path) }
    my @test-results = @testers.list>>.test;
    await Promise.allof: @test-results.list.map({ $_.list.map({ $_.promise }) });
    my @t = @test-results>>.list;
    my $failures = @t.grep({ !$_.ok }).elems;
    @t.map({ say $_.stdout }) if $v;

    say "-" x 42;
    say "Total  test files: {@t.elems}";
    say "Passed test files: {@t.elems - $failures}";
    say "Failed test files: $failures";
    say "-" x 42;
    exit $failures;
}

#| Install with business logic
multi MAIN('install', *@modules, Bool :$report, Bool :$v) is export {
    my $auth = Zef::Authority::P6C.new;

    # will be replaced soon
    sub verbose($phase, @_) {
        return unless @_;
        my %r = @_.classify({ $_.hash.<ok> ?? 'ok' !! 'nok' });
        say "!!!! $phase failed for: {%r<nok>.list.map({ $_.hash.<module> })}" if %r<nok>;
        say "===> $phase OK for: {%r<ok>.list.map({ $_.hash.<module> })}" if %r<ok>;
    }

    # todo: Parallelization. Will mostly 'just work' if we tweak build-dep-tree
    # to return the actual tree instead of flattening it into an array
    my @g = $auth.get: @modules;
    verbose('Fetching', @g);

    my @m = @g.grep({ $_<ok> }).map({ $_<ok> = ?$*SPEC.catpath('', $_.<path>, "META.info").IO.e; $_ });
    verbose('META.info availability', @m);

    my @repos = @m.grep({ $_<ok> }).map({ $_.<path> });

    my @b = Zef::Builder.new.pre-compile: @repos;
    verbose('Build', @b);

    # first crack at supplies/parallelization
    my @testers      = @repos.map: -> $path { Zef::Test.new(:$path) }
    my @test-results = @testers.list>>.test;
    await Promise.allof: @test-results.list.map({ $_.list.map({ $_.promise }) });
    my @t = @test-results>>.list;
    @t.map({ say $_.stdout }) if $v;
    verbose('Testing', @t.map({ ok => $_.ok, module => $_.file.IO.basename })); # 'module' is a lie

    my @metas-to-install = @m.grep({ $_<ok> }).map({ $*SPEC.catpath('', $_.<path>, "META.info").IO.path });

    my @r = $auth.report(
        @metas-to-install,
        test-results  => @t, 
        build-results => @b,
    ) and verbose('Reporting', @r) if ?$report;

    my @i = Zef::Installer.new.install: @metas-to-install;
    verbose('Install', @i.grep({ !$_.<skipped>}));
    verbose('Skip (already installed!)', @i.grep({ ?$_.<skipped> }));

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
