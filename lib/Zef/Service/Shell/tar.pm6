use Zef;

# XXX: when passing command line arguments to tar in this module be sure to use
# relative paths. ex: set :cwd to $tar-file.parent, and use $tar-file.basename as the target
# This is because gnu tar on windows can't handle a windows style volume in path arguments

class Zef::Service::Shell::tar does Extractor does Messenger {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz' | '.tgz') }

    method probe {
        state $probe = try { zrun('tar', '--help', :!out, :!err).so };
    }

    method extract(IO() $archive-file, IO() $extract-to) {
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

        $passed ?? $extract-to !! False;
    }

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
