class Zef::App;

#core modes 
use Zef::Exception;
use Zef::Tester;
use Zef::Installer;
use Zef::Config;

#load plugins for extra justice
for @($config<plugins>) {
    $_.perl.say;
    require $_;
}

#| Test modules in cwd
multi MAIN('test') is export { 
    # Zef::Tester should instead be able to detect the 
    # default so there is no error if there is no t/ folder
    &MAIN('test', 't/') 
};

#| Test modules in the specified directories
multi MAIN('test', *@paths) is export {
    my $tester = Zef::Tester.new;
    $tester.*test($_) for @paths;
}

#| Install freshness
multi MAIN('install', *@modules) is export {
    my $installer = Zef::Installer.new;
    $installer.install($_) for @modules;
}
