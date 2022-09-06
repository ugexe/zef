use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::Shell::PowerShell::download is Zef::Service::Shell::PowerShell does Fetcher does Messenger {

    =begin pod

    =title class Zef::Service::Shell::PowerShell::download

    =subtitle A PowerShell System.Net.WebClient based implementation of the Fetcher interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::PowerShell::download;

        my $downloader = Zef::Service::Shell::PowerShell::download.new;

        my $source   = "https://raw.githubusercontent.com/ugexe/zef/main/META6.json";
        my $save-to  = $*TMPDIR.child("zef-meta6.json");
        my $saved-to = $downloader.fetch($source, $save-to);

        die "Something went wrong" unless $saved-to;
        say "Zef META6 from HEAD: ";
        say $saved-to.slurp;

    =end code

    =head1 Description

    C<Fetcher> class for handling http based URIs using a thin PowerShell wrapper around C<System.Net.WebClient>
    located in C<resources.scripts/win32http.ps1>.

    You probably never want to use this unless its indirectly through C<Zef::Fetch>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Fetcher> interfaces that the e.g. git/file
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch C<powershell>.

    =head2 method fetch-matcher

        method fetch-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to fetch C<$uri>, which it decides based on if C<$uri>
    starts with C<http> or C<https>.

    =head2 method fetch

        method fetch(Str() $uri, IO() $save-as --> IO::Path)

    Fetches the given C<$uri> to C<$save-to> via a PowerShell script C<%?RESOURCES{"scripts/win32http.ps1"}>.

    On success it returns the C<IO::Path> where the data was actually saved to. On failure it returns C<Nil>.

    =end pod


    #| Delegate to parent class Zef::Service::Shell::PowerShell probe; Returns true if powershell is available
    method probe(--> Bool:D) { nextsame }

    #| Return true if this Fetcher understands the given uri/path
    method fetch-matcher(Str() $uri --> Bool:D) {
        return so <https http>.first({ $uri.lc.starts-with($_) });
    }

    #| Fetch the given url
    method fetch(Str() $uri, IO() $save-as --> IO::Path) {
        die "target download directory {$save-as.parent} does not exist and could not be created"
            unless $save-as.parent.d || mkdir($save-as.parent);

        my $passed;
        react {
            my $cwd := $save-as.IO.parent;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/win32http.ps1>.IO.absolute;
            my $proc = Zef::zrun-async(|@.ps-invocation, $script, $uri, '"' ~ $save-as.absolute ~ '"');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return ($passed && $save-as.IO.e) ?? $save-as !! Nil;
    }
}
