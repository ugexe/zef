BEGIN my $ZVER = $?DISTRIBUTION.meta<version>;
use Zef:ver($ZVER);

class Zef::Service::Shell::PowerShell does Probeable {
    has @.ps-invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    method probe {
        state $probe = !$*DISTRO.is-win ?? False !! try { zrun('powershell', '-help', :!out, :!err).so };
    }
}
