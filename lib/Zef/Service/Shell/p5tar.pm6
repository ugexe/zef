use Zef;

# covers untar for some windows users until a better solution is found
class Zef::Service::Shell::p5tar does Extractor does Messenger {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz' | '.tgz') }

    method probe {
        state $probe = try { zrun('perl', %?RESOURCES<scripts/perl5tar.pl>.IO.absolute, '--help', :!out, :!err) };
    }

    method extract(IO() $archive-file, IO() $extract-to) {
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
            my $script := %?RESOURCES<scripts/perl5tar.pl>.IO.absolute;
            my $proc = zrun-async('perl', $script, '--list', $archive-file.absolute);
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;
        $passed ?? @extracted-paths.grep(*.defined) !! ();
    }
}
