use Zef;

class Zef::Service::Shell::unzip does Extractor {

    =begin pod

    =title class Zef::Service::Shell::unzip

    =subtitle An unzip based implementation of the Extractor interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::unzip;

        my $unzip = Zef::Service::Shell::unzip.new;

        # Assuming a zef-main.zip file is in the cwd...
        my $source       = $*HOME.child("zef-main.zip");
        my $extract-to   = $*TMPDIR.child(time);
        my $extracted-to = $unzip.extract($source, $extract-to);

        die "Something went wrong" unless $extracted-to;
        say "Zef META6 from HEAD: ";
        say $extracted-to.child("zef-main/META6.json").slurp;

    =end code

    =head1 Description

    C<Extractor> class for handling file based URIs ending in .zip using the C<unzip> command.

    You probably never want to use this unless its indirectly through C<Zef::Extract>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Extractor> interfaces that the e.g. git/tar
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<unzip> command.

    =head2 method extract-matcher

        method extract-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to extract C<$uri>, which it decides based on if C<$uri> is
    an existing local file and ends with C<.zip>.

    =head2 method extract

        method extract(IO() $archive-file, IO() $extract-to, Supplier :$stdout, Supplier :$stderr --> IO::Path)

    Extracts the files in C<$archive-file> to C<$save-to> via the C<unzip> command. A C<Supplier> can be supplied
    as C<:$stdout> and C<:$stderr> to receive any output.

    On success it returns the C<IO::Path> where the data was actually extracted to. On failure it returns C<Nil>.

    =head2 method ls-files

        method ls-files(IO() $archive-file --> Array[Str])

    On success it returns an C<Array> of relative paths that are available to be extracted from C<$archive-file>.

    =end pod


    #| Return true if the `unzip` command is available to use
    method probe(--> Bool:D) {
        state $probe = try { Zef::zrun('unzip', '--help', :!out, :!err).so };
    }

    #| Return true if this Fetcher understands the given uri/path
    method extract-matcher(Str() $uri --> Bool:D) {
        return so $uri.IO.extension.lc eq 'zip';
    }

    #| Extract the given $archive-file
    method extract(IO() $archive-file, IO() $extract-to, Supplier :$stdout, Supplier :$stderr --> IO::Path) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;
        die "target extraction directory {$extract-to.absolute} does not exist and could not be created"
            unless ($extract-to.e && $extract-to.d) || mkdir($extract-to);

        my $passed;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('unzip', '-o', '-qq', $archive-file.basename, '-d', $extract-to.absolute);
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $extract-to !! Nil;
    }

    #| Returns an array of strings, where each string is a relative path representing a file that can be extracted from the given $archive-file
    method ls-files(IO() $archive-file) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('unzip', '-Z', '-1', $archive-file.basename);
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;

        my Str @results = $passed ?? @extracted-paths.grep(*.defined) !! ();
        return @results;
    }
}
