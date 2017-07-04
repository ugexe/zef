use Zef;

class Zef::Service::Shell::PowerShell does Probeable {
    has @.invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    method probe {
        state $probe = !$*DISTRO.is-win ?? False !! try { run('powershell', '--help') };
        ?$probe;
    }
}
