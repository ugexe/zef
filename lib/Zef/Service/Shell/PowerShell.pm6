use Zef;

# A base class for Zef::Service::Shell:: classes that handle the powershell invocation portion of commands.

# Note the invocation itself can be overridden. For strict windows environments you may want to override this in
# the config, which can be done be setting `options` as appropriate:
# {
#    "short-name" : "pswebrequest",
#    "module" : "Zef::Service::Shell::PowerShell::download"
#    "options" : {
#		"ps-invocation" : ["powershell","-Command"]
#	 }
# }

class Zef::Service::Shell::PowerShell does Probeable {
    has @.ps-invocation = 'powershell', '-NoProfile', '-ExecutionPolicy', 'unrestricted', '-Command';

    # Return true if the powershell command is available
    method probe(--> Bool:D) {
        state $probe = !$*DISTRO.is-win ?? False !! try { zrun('powershell', '-help', :!out, :!err).so };
    }
}
