use Zef::Shell;
use Zef::Shell::PowerShell;

my constant DOWNLOAD_SCRIPT = q:to/END_POWERSHELL_SCRIPT/;
    $progressPreference = 'silentlyContinue' # hide progress output
    $url = $env:ZEF_SHELL_URL
    $file = $env:ZEF_SHELL_PATH
    $http_proxy = $env:http_proxy;
    Invoke-WebRequest -Uri $url -OutFile $file
    END_POWERSHELL_SCRIPT
    
    #Invoke-WebRequest -Uri $url -OutFile $file -Proxy $http_proxy

class Zef::Shell::PowerShell::download is Zef::Shell::PowerShell does Fetcher {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }
    method probe { nextsame }
    method fetch($url, $save-as) {
        mkdir($save-as.IO.dirname) unless $save-as.IO.dirname.IO.e;
        my $proc = $.zrun-script(DOWNLOAD_SCRIPT, :ZEF_SHELL_URL($url), :ZEF_SHELL_PATH(~$save-as));
        ?$proc ?? $save-as !! False;
    }
}
