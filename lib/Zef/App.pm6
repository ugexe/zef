class Zef::App;

#core modes 
use Zef::Tester;
use Zef::Installer;
use Zef::Getter;

# load plugins from config file
our @plugins = BEGIN {
    use Zef::Config;
    $config<plugins>.list
}

# when invoked as a class, we have the usual @.plugins
has @.plugins;

# override config file plugins if invoked as a class
# *and* :@plugins was passed to initializer 
submethod BUILD(:@!plugins) { 
    @plugins := @!plugins if @!plugins.defined;
}



# need to find a way for each &MAIN to link to a class method
# or for method MAIN to 'is export' to work with long signature

#| Test modules in cwd
multi MAIN('test') is export { 
    # Zef::Tester should instead be able to detect the 
    # default so there is no error if there is no t/ folder
    &MAIN('test', 't/') 
}

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