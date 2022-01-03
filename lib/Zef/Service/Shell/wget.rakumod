use Zef;

class Zef::Service::Shell::wget does Fetcher does Probeable does Messenger {

    =begin pod

    =title class Zef::Service::Shell::wget

    =subtitle A wget based implementation of the Fetcher interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::wget;

        my $wget = Zef::Service::Shell::wget.new;

        my $source   = "https://raw.githubusercontent.com/ugexe/zef/master/META6.json";
        my $save-to  = $*TMPDIR.child("zef-meta6.json");
        my $saved-to = $wget.fetch($source, $save-to);

        die "Something went wrong" unless $saved-to;
        say "Zef META6 from HEAD: ";
        say $saved-to.slurp;

    =end code

    =head1 Description

    C<Fetcher> class for handling http based URIs using the C<wget> command.

    You probably never want to use this unless its indirectly through C<Zef::Fetch>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Fetcher> interfaces that the e.g. git/file
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<wget> command.

    =head2 method fetch-matcher

        method fetch-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to fetch C<$uri>, which it decides based on if C<$uri>
    starts with C<http> or C<https>.

    =head2 method fetch

        method fetch(Str() $uri, IO() $save-as --> IO::Path)

    Fetches the given C<$uri>, saving it to C<$save-to>.

    On success it returns the C<IO::Path> where the data was actually saved to. On failure it returns C<Nil>.

    =end pod


    #} Return true if the `wget` command is available to use
    method probe(--> Bool:D) {
        state $probe = try { Zef::zrun('wget', '--help', :!out, :!err).so };
    }

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
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('wget', '-P', $cwd, '--quiet', $uri, '-O', $save-as.absolute);
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return ($passed && $save-as.e) ?? $save-as !! Nil;
    }
}
