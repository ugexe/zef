use Zef;
use Zef::Shell;

class Zef::Shell::prove6 is Zef::Shell does Tester {
    method test-matcher($path) { True }

    method probe {
        # todo: check without spawning process (slow)
        state $prove6-help = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('prove6', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;
            $ = $proc.exitcode == 0 ?? @out !! False;
        }

        so $prove6-help;
    }

    method test($path) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;
        $.stdout.emit("[DEBUG] Testing: {$test-path.absolute}");
        my $proc = zrun('prove6', '-l', $test-path.relative($path), :cwd($path), :out, :err);
        $.stdout.emit($_) for $proc.out.lines;
        $.stderr.emit($_) for $proc.err.lines;
        $proc.out.close;
        $proc.err.close;
        $ = ?$proc;
    }
}
