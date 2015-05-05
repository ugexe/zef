use Zef::Phase::Testing;
use Zef::Utils::PathTools;

class Zef::Tester does Zef::Phase::Testing {
    method test(*@paths, :$lib = ['blib/lib', 'lib'], :$p6flags = ['--ll-exception']) {
        my $CWD := $*CWD;
        my @results := gather for @paths -> $path {
            my @files = $path.IO.ls(:r, :f).grep(/\.t$/);

            for @files -> $test-file {
                my $cmd         = "(cd $CWD && perl6 {$p6flags.list} {$lib.map({ qqw/-I$_/ })} $test-file)";

                # todo: capture output and save for reporting purposes
                my $test-result = shell($cmd).exitcode == 0 ?? 1  !! 0;

                take { ok => $test-result, file => $test-file }

                CATCH { default {
                    take { ok => -1, error => $_, file => $test-file }
                } }
            }
        }
        return @results;
    }
}

