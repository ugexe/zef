use Zef;

# An 'Extractor' that uses the perl command to launch an included perl script for extracting tar files
# (scripts/perl5tar.pl, a thin wrapper around Perls Archive::Tar module).
#
# Mostly for covering some edge case windows users

class Zef::Service::Shell::p5tar does Extractor does Messenger {
    # Return true if this Extractor understands the given uri/path
    method extract-matcher($path --> Bool:D) {
        return so <.tar.gz .tgz>.first({ $path.lc.ends-with($_) });
    }

    # Returns true if the included Perl script can be executed
    method probe(--> Bool:D) {
        state $probe = try { zrun('perl', %?RESOURCES<scripts/perl5tar.pl>.IO.absolute, '--help', :!out, :!err).so };
    }

    # Extract the given $archive-file
    method extract(IO() $archive-file, IO() $extract-to --> IO::Path) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;
        die "target extraction directory {$extract-to.absolute} does not exist and could not be created"
            unless ($extract-to.e && $extract-to.d) || mkdir($extract-to);

        my $passed;
        react {
            my $cwd := $extract-to;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/perl5tar.pl>.IO.absolute;
            my $proc = zrun-async('perl', $script, $archive-file.absolute);
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $extract-to !! Nil;
    }

    # Returns an array of strings, where each string is a relative path representing a file that can be extracted from the given $archive-file
    method ls-files(IO() $archive-file --> Array[Str]) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/perl5tar.pl>.IO.absolute;
            my $proc = zrun-async('perl', $script, '--list', $archive-file.absolute);
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;

        my Str @results = $passed ?? @extracted-paths.grep(*.defined) !! ();
        return @results;
    }
}
