use Zef::Phase::Testing;
use Zef::Utils::FileSystem;

class Zef::Tester does Zef::Phase::Testing {
    multi method test(*@paths, :$lib = ['blib/lib', 'lib'], :$p6flags = ['--ll-exception']) {
        my @files = Zef::Utils::FileSystem.dir(@paths, :r, :f).grep(/\.t/);

        for @files -> $test-file {
            my $cmd = "(cd $*CWD && perl6 {$p6flags.list} {$lib.map({ qqw/-I$_/ })} $test-file)";
            my $test_result = shell($cmd).exit == 0 ?? True  !! False;

            CATCH { default { say "Error: $_" } }
        }
    }
}