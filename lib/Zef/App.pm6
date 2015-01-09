class Zef::App;

#core modes 
use Zef::Tester;
use Zef::Installer;
use Zef::Getter;
use Zef::Builder;
use Zef::Config;

# load plugins from config file
BEGIN our @plugins := $config<plugins>.list;

# when invoked as a class, we have the usual @.plugins
has @.plugins;

# override config file plugins if invoked as a class
# *and* :@plugins was passed to initializer 
submethod BUILD(:@!plugins) { 
    @plugins := @!plugins if @!plugins.defined;
}



#| Test modules in cwd
multi MAIN('test') is export { &MAIN('test', 't/') }
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

multi MAIN('login', $user, $password?) {
    "Username: $user".say;
    my $pass = $password // prompt 'Password: ';
    "Password: {'*' x $pass.chars}".say;
    use IO::Socket::SSL;
    my $data = to-json({ username => $user, password => $pass, });
    my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
    $sock.send("POST /login HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n$data");
    my %result = %(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
    if %result<success> // False {
        say 'Login successful.';
        $config<session-key> = %result<newkey>;
        save-config;
    } elsif %result<failure> // False {
        say "Login failed with error: %result<reason>";
    } else {
        say 'Unknown problem -';
        %result.perl.say;
    }
}

multi MAIN('register', $user, $password?) {
    "Username: $user".say;
    my $pass = $password // prompt 'Password: ';
    "Password: {'*' x $pass.chars}".say;
    use IO::Socket::SSL;
    my $data = to-json({ username => $user, password => $pass, });
    my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
    $sock.send("POST /register HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n$data");
    my %result = %(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
    if %result<success> // False {
        say 'Welcome to Zef.';
        $config<sessionkey> = %result<newkey>;
        save-config;
    } elsif %result<failure> // False {
        say "Registration failed with error: %result<reason>";
    } else {
        say 'Unknown problem -';
        %result.perl.say;
    }
}

multi MAIN('search', *@terms) {
    use IO::Socket::SSL;
    for @terms -> $term {
        my $data = to-json({ query => $term });
        my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
        $sock.send("POST /search HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n$data");
        my @results = @(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
        "Results for $term".say;
        "Package\tAuthor\tVersion".say;
        for @results -> %result {
            "%result<name>\t%result<owner>\t%result<version>".say;
        }
    }
}
