use Zef;
use Zef::Shell;

class Zef::Service::Shell::PowerShell is Zef::Shell does Probeable {
    has @.invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    method probe {
        state $powershell-probe = !$*DISTRO.is-win ?? False !! try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('powershell', '-help');
        }
        ?$powershell-probe;
    }
}
