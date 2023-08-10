use Zef;

# Note: when passing command line arguments to tar in this module be sure to use relative
# paths. ex: set :cwd to $archive-file.parent, and use $archive-file.basename as the target
# This is because gnu tar on windows can't handle a windows style volume in path arguments
class Zef::Service::Shell::tar does Extractor {

    =begin pod

    =title class Zef::Service::Shell::tar

    =subtitle A tar based implementation of the Extractor interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::tar;

        my $tar = Zef::Service::Shell::tar.new;

        # Assuming a zef-main.tar.gz file is in the cwd...
        my $source       = $*HOME.child("zef-main.tar.gz");
        my $extract-to   = $*TMPDIR.child(time);
        my $extracted-to = $tar.extract($source, $extract-to);

        die "Something went wrong" unless $extracted-to;
        say "Zef META6 from HEAD: ";
        say $extracted-to.child("zef-main/META6.json").slurp;

    =end code

    =head1 Description

    C<Extractor> class for handling file based URIs ending in .tar.gz / .tgz using the C<tar> command. If bsdtar is
    used it will also work on C<.zip> files.

    You probably never want to use this unless its indirectly through C<Zef::Extract>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Extractor> interfaces that the e.g. git/unzip
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<tar> command.

    =head2 method extract-matcher

        method extract-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to extract C<$uri>, which it decides based on if C<$uri> is
    an existing local file and ends with C<.tar.gz> or C<.tgz>. If bsdtar is used it will also work on
    C<.zip> files.

    =head2 method extract

        method extract(IO() $archive-file, IO() $extract-to, Supplier :$stdout, Supplier :$stderr --> IO::Path)

    Extracts the files in C<$archive-file> to C<$save-to> via the C<tar> command. A C<Supplier> can be supplied
    as C<:$stdout> and C<:$stderr> to receive any output.

    On success it returns the C<IO::Path> where the data was actually extracted to. On failure it returns C<Nil>.

    =head2 method ls-files

        method ls-files(IO() $archive-file --> Array[Str])

    On success it returns an C<Array> of relative paths that are available to be extracted from C<$archive-file>.

    =end pod

    my Lock $probe-lock = Lock.new;
    my Bool $probe-cache;
    my Str @extract-matcher-extensions = '.tar.gz', '.tgz';

    #| Return true if the `tar` command is available to use
    method probe(--> Bool:D) {
        $probe-lock.protect: {
            return $probe-cache if $probe-cache.defined;

            # OpenBSD tar doesn't have a --help flag so we can't probe
            # using that, and we need the --help output to detect if
            # it can support .zip files. So we have a special case to
            # probe for tar on OpenBSD (which doesn't support .zip).
            if BEGIN $*VM.osname.lc.contains('openbsd') {
                # For OpenBSD run just `tar` and see if the output contains
                # any of the following words (which suggest the command exists)
                BEGIN my @needles = <archive file specify>;
                my $proc = Zef::zrun('tar', :!out, :err);
                my $stderr = $proc.err.slurp(:close).lc;
                return $probe-cache = any($stderr.words) ~~ any(@needles);
            }

            my $proc = Zef::zrun('tar', '--help', :out, :!err);
            my $probe is default(False) = try so $proc;
            @extract-matcher-extensions.push('.zip') if $proc.out.slurp(:close).contains('bsdtar');
            return $probe-cache = $probe;
        }
    }

    #| Return true if this Extractor understands the given uri/path
    method extract-matcher(Str() $uri --> Bool:D) {
        $probe-lock.protect: { # protect the read on @extract-matcher-extensions
            self.probe();      # prime @extract-matcher-extensions
            return so @extract-matcher-extensions.first({ $uri.lc.ends-with($_) });
        }
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
            my $proc = Zef::zrun-async('tar', '-zxvf', $archive-file.basename, '-C', $extract-to.relative($cwd));
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
            my $proc = Zef::zrun-async('tar', '-t', '-f', $archive-file.basename);
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;
        $passed ?? @extracted-paths.grep(*.defined) !! ();
    }
}
