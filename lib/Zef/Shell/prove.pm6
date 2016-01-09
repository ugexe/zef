use Zef;
use Zef::Shell;

class Zef::Shell::prove is Zef::Shell does Tester {
    method test-matcher($path) { True }

    method probe {
        state $prove-help = try {
            my $proc = zrun('prove', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;

            # `prove --help` has exitcode == 1 unlike most other processes
            # so it requires a more convoluted probe check
            CATCH {
                when X::Proc::Unsuccessful {
                    return True if $proc.exitcode == 1 && @out.first(*.contains("-exec"));
                    return False
                }
                default { return False }
            }
        }

        so $prove-help;
    }

    method test($path) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;
        my $proc = zrun('prove', '-v', '-e', q|perl6 -Ilib|, $test-path, :cwd($path));
        $ = ?$proc;
    }
}
