class Zef::Tester;
use Zef::Exception;

submethod BUILD( ) {
    use Zef::Role::Test;

    my @plugins = <Zef::Role::P5Prove>;
    for @plugins -> $plugin {
        require ::($plugin);
        next unless ::($plugin) ~~ Zef::Role::Test;
        self does ::($plugin);
    }
}

CATCH { 
    when X::Zef { say 'Try and handle these' }
    default     { say "ERROR: $_"            }
}    

