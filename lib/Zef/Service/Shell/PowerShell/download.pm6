use Zef;
use Zef::Shell;
use Zef::Service::Shell::PowerShell;

class Zef::Service::Shell::PowerShell::download is Zef::Service::Shell::PowerShell does Fetcher does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }
    method probe { nextsame }

    # This seems like overkill for what is likely an edge case
    #method probe {
    #    state $powershell-webrequest-probe = !$*DISTRO.is-win ?? False !! try {
    #        CATCH {
    #            when X::Proc::Unsuccessful { return False }
    #            default { return False }
    #        }
    #        my $proc = zrun('powershell', '-Command', 'Get-Command', '-Name', 'Invoke-WebRequest', :out);
    #        my @out  = $proc.out.lines;
    #        $proc.out.close;
    #        $ = ?$proc;
    #    }
    #    ?$powershell-webrequest-probe;
    #}

    method fetch($url, $save-as) {
        mkdir($save-as.IO.parent) unless $save-as.IO.parent.IO.e;
        my $proc = $.zrun(%?RESOURCES<scripts/win32http.ps1>.IO.absolute, $url, $save-as.IO.absolute);
        ?$proc ?? $save-as !! False;
    }
}
