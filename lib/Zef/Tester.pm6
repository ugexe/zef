class Zef::Tester;
use Zef::Exception;

# emulate plugins
submethod INIT( ) {
    self does self.Test;
    self does ::($_) for ($?CLASS::P5Prove);
}

# provide a `test` method to Zef::Tester via default or plugin (if available)
role Test { 
    has $.status;
    has $.verbose;

    # default test method? assuming it gets overridden by plugins
    method test($dir) {
        shell "perl6 -V" 
            or fail 'perl6 command missing?';

        shell "(cd $dir && perl6 -Iblib/lib -Ilib t/)"
            or fail "test failed?";

        say "Test successful?";        

        CATCH {
            default {
                X::Zef.new( :stage($?ROLE), :reason("$!") );
            }
        }
    }
}
