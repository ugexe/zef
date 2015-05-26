unit class Zef::App;

#core modes 
use Zef::Authority;
use Zef::Builder;
use Zef::Config;
use Zef::Getter;
use Zef::Installer;
use Zef::Reporter;
use Zef::Tester;
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
multi MAIN('test', *@paths) is export {
    @paths = $*CWD unless @paths;
    my $tester  = Zef::Tester.new(:@plugins);
    my @results = $tester.test(@paths);
    my $failures = @results.grep({ !$_.<ok>  }).elems;
    say "-" x 42;
    say "Total  test files: {@results.elems}";
    say "Passed test files: {@results.elems - $failures}";
    say "Failed test files: $failures";
    say "-" x 42;
    exit $failures;
}

#| Install with business logic
multi MAIN('install', *@modules, Bool :$report) is export {
    sub verbose($phase, @_) {
        return unless @_;
        my %r = @_.classify({ $_.<ok> ?? 'ok' !! 'nok' });
        say "***> $phase failed for: {%r<nok>.list.map({ $_.<module> })}" if %r<nok>;
        say "===> $phase OK for: {%r<ok>.list.map({ $_.<module> })}" if %r<ok>;
    }

    my @installed = gather for @modules -> $module-name {
        my @g = Zef::Getter.new( plugins => ["Zef::Plugin::P6C_Ecosystem"] ).get($module-name);
        verbose('Fetching', @g);

        my @metas = @g.map({ $*SPEC.catpath("", $_.<path>, "META.info") });

        my @b = Zef::Builder.new.pre-compile( @g.map({ $_.<path> }) );
        verbose('Build', @b);

        my @t = Zef::Tester.new.test(@b.map({ $_.<path> }));
        verbose('Testing', @t);

        my @r = Zef::Reporter.new( plugins => ['Zef::Plugin::P6C_Reporter']).report(
            @metas, 
            test-results  => @t, 
            build-results => @b,
        ) and verbose('Reporting', @r) if ?$report;

        my @i = Zef::Installer.new.install(@metas);
        verbose('Install', @i.grep({ !$_.<skipped>}));
        verbose('Skip (already installed!)', @i.grep({ ?$_.<skipped> }));

        take $module-name unless @i.grep({ !$_.<ok> });
    }
    exit @modules.elems - @installed.elems;
}


#| Install local freshness
multi MAIN('local-install', *@modules) is export {
    my $installer = Zef::Installer.new(:@plugins);
    $installer.install($_) for @modules;
}


#| Get the freshness
multi MAIN('get', :$save-to = "$*CWD/{time}", *@modules) is export {
    # {time} can be removed when we fetch actual versioned archives
    # so we dont accidently overwrite files in $*CWD
    my $getter = Zef::Getter.new(:@plugins);
    my @results = $getter.get(:$save-to, |@modules);
    return @results;
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directories
multi MAIN('build', $path, :$save-to) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path, :$save-to);
}

multi MAIN('login', Str $username, Str $password? is copy) {
    $password //= prompt 'Password: ';
    say "Password required" && exit(1) unless $password;
    my $auth = Zef::Authority.new;
    $auth.login(:$username, :$password) or { $*ERR.say; exit(2) }();
    %config<session-key> = $auth.session-key // exit(3);
    save-config;
}

multi MAIN('register', Str $username, Str $password? is copy) {
    $password //= prompt 'Password: ';
    say "Password required" && exit(1) unless $password;
    my $auth = Zef::Authority.new;
    $auth.register(:$username, :$password) or { $*ERR.say; exit(5) }();
    %config<session-key> = $auth.session-key or exit(6);
    save-config;
}

multi MAIN('search', *@terms) {
    my $auth = Zef::Authority.new;
    my %results = $auth.search(@terms) or exit(4);
    for %results.kv -> $term, @term-results {
        say "No results for $term" and next unless @term-results;
        try say @term-results.hash.<reason> and next if @term-results.hash.<failure>;
        say "Results for $term";
        say "Package\tAuthor\tVersion";
        for @term-results -> %result {
            say "{%result<name>}\t{%result<owner>}\t{%result<version>}";
        }
    }

    exit(7) if [] ~~ all(%results.values);
}

multi MAIN('push', *@targets, Str :$session-key = %config<session-key>, :@exclude? = (/'.git'/,/'.gitignore'/), Bool :$force?) {
    @targets.push($*CWD.IO.path) unless @targets.elems;
    my $auth = Zef::Authority.new;
    $auth.push(@targets, :$session-key, :@exclude, :$force) or { $*ERR.say; exit(7); }();
}
