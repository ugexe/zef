use Zef;
use Zef::Shell;

class Zef::Shell::PowerShell is Zef::Shell does Probeable {
    has @.invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    method probe {
        state $powershell-probe = !$*DISTRO.is-win ?? False !! try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            my $proc = zrun('powershell', '-help', :out);
            my @out  = $proc.out.lines;
            $proc.out.close;
            $ = ?$proc;
        }
        ?$powershell-probe;
    }
}
