use Zef;
use Zef::Service::Shell::PowerShell;

# A PowerShell based 'Extractor' that uses the powershell command to launch an included powershell script
# for extracting zip files (scripts/win32unzip.ps1, a thin wrapper around PowerShells built-in zip file access).

class Zef::Service::Shell::PowerShell::unzip is Zef::Service::Shell::PowerShell does Extractor does Messenger {
    # Return true if this Fetcher understands the given uri/path
    method extract-matcher($path --> Bool:D) {
        return so $path.IO.extension.lc eq 'zip';
    }

    # Delegate to parent class Zef::Service::Shell::PowerShell probe; Returns true if powershell is available
    method probe(--> Bool:D) { nextsame }

    # Extract the given $archive-file
    method extract(IO() $archive-file, IO() $extract-to --> IO::Path) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;
        die "target extraction directory {$extract-to.absolute} does not exist and could not be created"
            unless ($extract-to.e && $extract-to.d) || mkdir($extract-to);

        my $passed;
        react {
            my $cwd := $archive-file.IO.parent;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/win32unzip.ps1>.IO.absolute;
            my $proc = zrun-async(|@.ps-invocation, $script, $archive-file.basename, '"' ~ $extract-to.absolute ~ '"');
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
            my $script := %?RESOURCES<scripts/win32unzip.ps1>.IO.absolute;
            my $proc = zrun-async(|@.ps-invocation, $script, $archive-file.basename);
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;

        my Str @results = $passed ?? @extracted-paths.grep(*.defined) !! ();
        return @results;
    }
}
