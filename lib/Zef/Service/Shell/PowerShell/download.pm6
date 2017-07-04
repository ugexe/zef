use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::Shell::PowerShell::download is Zef::Service::Shell::PowerShell does Fetcher does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }
    method probe { nextsame }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.parent) unless $save-as.IO.parent.IO.e;
        my $proc = run(|@.invocation, %?RESOURCES<scripts/win32http.ps1>, $url, $save-as);
        $proc.exitcode == 0 ?? $save-as !! False;
    }
}
