use Zef::Phase::Testing;
use Zef::Utils::PathTools;

class Zef::Tester does Zef::Phase::Testing {
    method test(*@repos, :$lib = ['blib/lib','lib'], :$p6flags) {
        say @repos.perl;
        my @results = eager gather for @repos -> $repo {
            my @files = $repo.IO.ls(:r, :f).grep(/\.t$/);

            for @files -> $test-file {
                my $test-file-rel = $*SPEC.abs2rel($test-file, $repo);
                my $cmd = qq|(cd $repo && prove -v -e "perl6 {$p6flags.list} {$lib.map({ qqw/-I$_/ })}" $test-file-rel)|;
say $cmd;
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

