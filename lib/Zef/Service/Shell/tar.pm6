use Zef;

# A simple 'Extractor' that uses the `tar` command to extract archive files

# Note: when passing command line arguments to tar in this module be sure to use
# relative paths. ex: set :cwd to $tar-file.parent, and use $tar-file.basename as the target
# This is because gnu tar on windows can't handle a windows style volume in path arguments
class Zef::Service::Shell::tar does Extractor does Messenger {
    # Return true if this Extractor understands the given uri/path
    method extract-matcher($path --> Bool:D) {
        return so <.tar.gz .tgz>.first({ $path.lc.ends-with($_) });
    }

    # Return true if the `tar` command is available to use
    method probe(--> Bool:D) {
        state $probe = try { zrun('tar', '--help', :!out, :!err).so };
    }

    # Extract the given $archive-file
    method extract(IO() $archive-file, IO() $extract-to --> IO::Path) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;
        die "target extraction directory {$extract-to.absolute} does not exist and could not be created"
            unless ($extract-to.e && $extract-to.d) || mkdir($extract-to);

        my $passed;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('tar', '-zxvf', $archive-file.basename, '-C', $extract-to.relative($cwd));
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $extract-to !! Nil;
    }

    # Returns an array of strings, where each string is a relative path representing a file that can be extracted from the given $archive-file
    method ls-files(IO() $archive-file) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('tar', '--list', '-f', $archive-file.basename);
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;
        $passed ?? @extracted-paths.grep(*.defined) !! ();
    }
}
