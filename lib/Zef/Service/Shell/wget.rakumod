use Zef:ver($?DISTRIBUTION.meta<version> // $?DISTRIBUTION.meta<ver>// '*'):api($?DISTRIBUTION.meta<api> // '*'):auth($?DISTRIBUTION.meta<auth> // '');

class Zef::Service::Shell::wget does Fetcher does Probeable {

    =begin pod

    =title class Zef::Service::Shell::wget

    =subtitle A wget based implementation of the Fetcher interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::wget;

        my $wget = Zef::Service::Shell::wget.new;

        my $source   = "https://raw.githubusercontent.com/ugexe/zef/main/META6.json";
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

        method fetch(Str() $uri, IO() $save-as, Supplier :$stdout, Supplier :$stderr --> IO::Path)

    Fetches the given C<$uri>, saving it to C<$save-to>. A C<Supplier> can be supplied as C<:$stdout> and
    C<:$stderr> to receive any output.

    On success it returns the C<IO::Path> where the data was actually saved to. On failure it returns C<Nil>.

    =end pod

    my Str $command-cache;
    my Lock $command-lock = Lock.new;

    method !command {
        $command-lock.protect: {
            return $command-cache if $command-cache.defined;
            if BEGIN { $*DISTRO.is-win } && try so Zef::zrun('wget.exe', '--help', :!out, :!err) {
                # When running under powershell we don't want to use the wget Invoke-WebRequest
                # alias so explicitly add the .exe
                return $command-cache = 'wget.exe';
            }
            return $command-cache = 'wget';
        }
    }

    my Lock $probe-lock = Lock.new;
    my Bool $probe-cache;

    #| Return true if the `curl` command is available to use
    method probe(--> Bool:D) {
        $probe-lock.protect: {
            return $probe-cache if $probe-cache.defined;
            my $command = self!command();
            my $probe is default(False) = try so Zef::zrun($command, '--help', :!out, :!err);
            return $probe-cache = $probe;
        }
    }

    #| Return true if this Fetcher understands the given uri/path
    method fetch-matcher(Str() $uri --> Bool:D) {
        return so <https http>.first({ $uri.lc.starts-with($_) });
    }

    #| Fetch the given url
    method fetch(Str() $uri, IO() $save-as, Supplier :$stdout, Supplier :$stderr --> IO::Path) {
        die "target download directory {$save-as.parent} does not exist and could not be created"
            unless $save-as.parent.d || mkdir($save-as.parent);

        my $passed;
        react {
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $cmd := self!command();
            my $proc = Zef::zrun-async($cmd, '-P', $cwd, '--quiet', $uri, '-O', $save-as.absolute);
            $stdout.emit("Command: {$proc.command}");
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return ($passed && $save-as.e) ?? $save-as !! Nil;
    }
}
