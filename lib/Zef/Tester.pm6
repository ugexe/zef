use Zef::Phase::Testing;
class Zef::Tester does Zef::Phase::Testing {
    multi method test(*@paths) {
        my $supply = Supply.new;
        $supply.act: {
            given $_.IO {
                when :d {
                    dir($_).map: -> $d { $supply.emit($d) };
                } 
                when :f & /\.t$/ {
                    my $cmd = "(cd $*CWD && perl6 --ll-exception -Iblib/lib -Ilib $_)";
                    my $test_result = shell($cmd).exit == 0 ?? True  !! False;

                    CATCH { default { say "Error: $_" } }
                }
            }
        }

        my $promise = await @paths.map: { $supply.emit($_) };
    }
}