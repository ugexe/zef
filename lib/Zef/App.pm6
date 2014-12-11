class Zef::App;

#core modes 
use Zef::Exception;
use Zef::Tester;
use Zef::Installer;

our @plugins = BEGIN {
    use Zef::Config;
    $config<plugins>.list;
}

#| Test modules in cwd
multi MAIN('test') is export { 
    # Zef::Tester should instead be able to detect the 
    # default so there is no error if there is no t/ folder
    &MAIN('test', 't/') 
};

#| Test modules in the specified directories
multi MAIN('test', *@paths) is export {
    my $tester = Zef::Tester.new(:@plugins);
    $tester.*test($_) for @paths;
}

#| Install freshness
multi MAIN('install', *@modules) is export {
    my $installer = Zef::Installer.new;
    $installer.install($_) for @modules;
}
