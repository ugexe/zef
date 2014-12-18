class Zef::App;

#core modes 
use Zef::Tester;
use Zef::Installer;
use Zef::Getter;
use Zef::Builder;

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
multi MAIN('build') is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directories
multi MAIN('build', $path) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path);
}
