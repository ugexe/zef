class Zef::Tester;
use Zef::Exception;
use Zef::Config;

submethod BUILD( ) {
    use Zef::Role::Test;
    for @($config<plugins>) -> $plugin {
        require ::($plugin);
        next unless ::($plugin) ~~ Zef::Role::Test;
        self does ::($plugin);
    }
}

CATCH { 
    when X::Zef { say 'Try and handle these' }
    default     { say "ERROR: $_"            }
}    

