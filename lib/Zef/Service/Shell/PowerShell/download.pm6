use Zef;
use Zef::Service::Shell::PowerShell;

# A PowerShell based 'Fetcher' that uses the powershell command to launch an included powershell script
# for fetching uris (scripts/win32http.ps1, a thin wrapper around PowerShells `System.Net.WebClient`).

class Zef::Service::Shell::PowerShell::download is Zef::Service::Shell::PowerShell does Fetcher does Messenger {
    # Return true if this Fetcher understands the given uri/path
    method fetch-matcher($url --> Bool:D) {
        return so <https http>.first({ $url.lc.starts-with($_) });
    }

    # Delegate to parent class Zef::Service::Shell::PowerShell probe; Returns true if powershell is available
    method probe(--> Bool:D) { nextsame }

    # Fetch the given url
    method fetch($url, IO() $save-as --> IO::Path) {
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

        return ($passed && $save-as.IO.e) ?? $save-as !! Nil;
    }
}
