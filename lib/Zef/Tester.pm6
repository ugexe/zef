use Zef::Phase::Testing;
use Zef::Utils::PathTools;

class Zef::Tester does Zef::Phase::Testing {
    method test(*@paths, :$lib = ['blib/lib', 'lib'], :$p6flags = ['--ll-exception']) {
        my $CWD := $*CWD;
        my @results;
        for @paths -> $path {
            my @files = $path.IO.ls(:r, :f).grep(/\.t$/);

            for @files -> $test-file {
                my $cmd = "(cd $CWD && perl6 {$p6flags.list} {$lib.map({ qqw/-I$_/ })} $test-file)";
                my $test_result = shell($cmd).exitcode == 0 ?? 1  !! 0;
                @results.push({ pass => $test_result, file => $test-file });
                CATCH { default { say "Error: $_" } }
            }
        }
        return @results;
    }
}