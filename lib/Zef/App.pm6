class Zef::App;

#core modes 
use Zef::Tester;
use Zef::Installer;
use Zef::Getter;
use Zef::Builder;
use Zef::Config;
use Zef::Authority;

# load plugins from config file
BEGIN our @plugins := %config<plugins>.list;

# when invoked as a class, we have the usual @.plugins
has @.plugins;

# override config file plugins if invoked as a class
# *and* :@plugins was passed to initializer 
submethod BUILD(:@!plugins) { 
    @plugins := @!plugins if @!plugins.defined;
}



#| Test modules in cwd
multi MAIN('test') is export { &MAIN('test/', 'tests/', 't/', 'xt/') }
#| Test modules in the specified directories
multi MAIN('test', *@paths) is export {
    my $tester = Zef::Tester.new(:@plugins);
    $tester.test($_) for @paths;
}


#| Install freshness
multi MAIN('install', *@modules) is export {
    my $installer = Zef::Installer.new(:@plugins);
    $installer.install($_) for @modules;
}


#| Get the freshness
multi MAIN('get', *@modules) is export {
    my $getter = Zef::Getter.new(:@plugins);
    $getter.get($_, $*CWD) for @modules;
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*SPEC.catdir($*CWD, 'lib')) }
#| Build modules in the specified directories
multi MAIN('build', $path) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path);
}

multi MAIN('login', Str $username, Str $password?) {
    $password //= prompt 'Password: ';
    say "Password required" && exit(1) unless $password;
    my $auth = Zef::Authority.new;
    $auth.login(:$username, :$password);
    %config<session-key> = $auth.session-key;
    save-config;
}

multi MAIN('register', Str $username, Str $password?) {
    $password //= prompt 'Password: ';
    say "Password required" && exit(1) unless $password;
    my $auth = Zef::Authority.new;
    $auth.login(:$username, :$password);
    %config<session-key> = $auth.session-key;
    save-config;
}

multi MAIN('search', *@terms) {
    my $auth = Zef::Authority.new;
    $auth.search(@terms);
}

multi MAIN('push', @targets, Str :$session-key = %config<session-key>, :@exclude?, Bool :$force?) {
    @targets.push($*CWD) unless @targets;
    my $auth = Zef::Authority.new;
    $auth.push(:@targets, :$session-key, :@exclude, :$force);
}
