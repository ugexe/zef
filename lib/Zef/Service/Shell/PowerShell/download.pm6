use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::Shell::PowerShell::download is Zef::Service::Shell::PowerShell does Fetcher does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }
    method probe { nextsame }

    method fetch($url, IO() $save-as) {
        die "target download directory {$save-as.parent} does not exist and could not be created"
            unless $save-as.parent.d || mkdir($save-as.parent);

        my $passed;
        react {
            my $cwd := $save-as.IO.parent;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/win32http.ps1>.IO.absolute;
            my $proc = zrun-async(|@.ps-invocation, $script, $url, '"' ~ $save-as.absolute ~ '"');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        ($passed && $save-as.IO.e) ?? $save-as !! False;
    }
}
