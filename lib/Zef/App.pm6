class Zef::App;
use Zef::Exception;
use Zef::Tester;

has $.tester = Zef::Tester.new;
has %.args;

multi method MAIN('test', *@paths) {
    $.tester.test($_) for @paths;
    
    CATCH { 
        when X::Zef { say 'Try and handle these' }
        default     { say "ERROR: $_"            }
    }
}
