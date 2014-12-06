use Zef::Exception;

role Zef::Tester {
    my $default-role = role {
        method test($dir) {
            shell "perl6 -V" 
                or fail 'perl6 command missing?';

            shell "(cd $dir && perl6 -Iblib/lib -Ilib t/)"
                or fail "test failed?";

            say "Test successful?";
        }
    };

    method test {
        qw<$default-role Zef::Tester::P5Prove>.map({
            ::($_).does(Zef::Tester) 
            ?? ::($_).new.test 
            !! Nil
        });
    }
}; 

class Zef::Test does Zef::Tester { }; 