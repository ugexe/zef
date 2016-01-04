use Zef;
use Zef::Shell;

class Zef::Shell::PowerShell is Zef::Shell does Probeable {
    has @.invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    method probe {
        return False unless $*DISTRO.is-win;

        # todo: check without spawning process (slow)
        state $powershell-help = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            # May only be a type object still, so use normal `run`
            my $proc = run('powershell', '-help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;
            $ = $proc.exitcode == 0 ?? @out !! False;
        }

        so $powershell-help;
    }
}
