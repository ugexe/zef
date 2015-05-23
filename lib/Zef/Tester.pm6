use Zef::Phase::Testing;
use Zef::Utils::PathTools;

class Zef::Tester does Zef::Phase::Testing {
    method test(*@repos, :$lib = ['blib/lib','lib'], :$p6flags) {
        my @libs = gather for @repos -> $path { 
            for $lib.list -> $l {
                take $*SPEC.catdir($path, $l);
            }
        }

        my @results = eager gather for @repos -> $path {
            my @files = $path.IO.ls(:r, :f).grep(/\.t$/);

            for @files -> $test-file {
                my $test-file-rel = $*SPEC.abs2rel($test-file, $path);
                my $cmd = qq|(cd $path && prove -v -e "perl6 {$p6flags.list} {@libs.map({ qqw/-I$_/ })}" $test-file-rel)|;

                # todo: capture output and save for reporting purposes
                my $test-result = shell($cmd).exitcode == 0 ?? 1  !! 0;

                take { ok => $test-result, file => $test-file, path => $path }

                CATCH { default {
                    take { ok => -1, error => $_, file => $test-file, path => $path }
                } }
            }
        }
        return @results;
    }
}

