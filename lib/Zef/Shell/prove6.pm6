use Zef;
use Zef::Shell;

class Zef::Shell::prove6 is Zef::Shell does Tester {
    method test-matcher($path) { so ($path.IO.extension.lc eq 't' || $path.IO.dir.first(*.IO.extension.lc eq 't') ) }

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
        my $cwd = $path.IO.parent; # XXX
        my $test-path = $path.IO.f ?? $path !! $path.IO.relative($cwd);
        my $proc = zrun('prove6', '-l', '-e', q|perl6 -Ilib|, $test-path, :$cwd);
        $ = ?$proc;
    }
}
