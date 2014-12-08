class Zef::App;
use Zef::Exception;
use Zef::Tester;
use Zef::Installer;


#| Test modules in cwd
multi MAIN('test') is export { 
    # Zef::Tester should instead be able to detect the 
    # default so there is no error if there is no t/ folder
    &MAIN('test', 't/') 
};

#| Test modules in the specified directories
multi MAIN('test', *@paths) is export {
    my $tester = Zef::Tester.new;
    $tester.test($_) for @paths;
}

#| Install freshness
multi MAIN('install', *@modules) is export {
    my $installer = Zef::Installer.new;
    $installer.install($_) for @modules;
}

END {
    CATCH { 
        when X::Zef { say 'Try and handle these' }
        default     { say "ERROR: $_"            }
    }    
}