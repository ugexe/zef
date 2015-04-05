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
multi MAIN('test') is export { &MAIN('test', |('test/', 'tests/', 't/', 'xt/')) }
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
multi MAIN('get', :$save-to = "$*CWD/{time}", *@modules) is export {
    # {time} can be removed when we fetch actual versioned archives
    # so we dont accidently overwrite files in $*CWD
    my $getter = Zef::Getter.new(:@plugins);
    $getter.get(:$save-to, |@modules);
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*SPEC.catdir($*CWD, 'lib')) }
#| Build modules in the specified directories
multi MAIN('build', $path) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path);
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
        say @term-results.hash.<reason> and next if @term-results.hash.<failure>;
        say "Results for $term";
        say "Package\tAuthor\tVersion";
        for @term-results -> %result {
            say "{%result<name>}\t{%result<owner>}\t{%result<version>}";
        }
    }

    exit(7) if [] ~~ all(%results.values);
}

multi MAIN('push', *@targets, Str :$session-key = %config<session-key>, :@exclude? = (/'.git'/,/'.gitignore'/), Bool :$force?) {
    @targets.push($*CWD.Str) unless @targets.elems;
    my $auth = Zef::Authority.new;
    $auth.push(@targets, :$session-key, :@exclude, :$force) or { $*ERR.say; exit(7); }();
}
