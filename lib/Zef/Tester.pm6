use Zef::Phase::Testing;
use Zef::Utils::PathTools;

class Zef::Tester does Zef::Phase::Testing {
    method test(*@paths, :$lib = ['blib/lib', 'lib'], :$p6flags) {
        my @results = eager gather for @paths -> $path {
            my @files = $path.IO.ls(:r, :f).grep(/\.t$/);

            for @files -> $test-file {
                my $test-file-rel = $*SPEC.abs2rel($test-file, $path);
                my $cmd = qq|(cd $path && prove -v -e "perl6 {$p6flags.list} {$lib.map({ qqw/-I$_/ })}" $test-file-rel)|;

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

