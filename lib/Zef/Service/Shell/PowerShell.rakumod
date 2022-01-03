use Zef;

class Zef::Service::Shell::PowerShell does Probeable {

    =begin pod

    =title class Zef::Service::Shell::PowerShell

    =subtitle A base class for PowerShell invoking adapters

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::PowerShell;

        class MyPowerShell::HelloWorld is Zef::Service::Shell::PowerShell {
            method hello-world {
                say run(|@.ps-invocation, q|Write-Host 'hello world'|, :out).out.slurp
            }
        }

    =end code

    =head1 Description

    A base class for Zef::Service::Shell:: classes that handle the powershell invocation portion of commands.

    Note the invocation itself can be overridden. For strict windows environments you may want to override this in the
    config (although on the classes using this base class), which can be done be setting C<options> as appropriate:

    =begin code :lang<json>

        {
            "short-name" : "pswebrequest",
            "module" : "Zef::Service::Shell::PowerShell::download"
            "options" : {
                "ps-invocation" : ["powershell","-Command"]
            }
        }

    =end code

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<powershell> command.

    =end pod


    #| The invocation to use when launching PowerShell
    has @.ps-invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    #| Return true if the powershell command is available
    method probe(--> Bool:D) {
        state $probe = !$*DISTRO.is-win ?? False !! so try { Zef::zrun('powershell', '-help', :!out, :!err) };
    }
}
