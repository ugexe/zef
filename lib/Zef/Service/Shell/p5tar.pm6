use Zef;

# covers untar for some windows users until a better solution is found
class Zef::Service::Shell::p5tar does Extractor does Messenger {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz' | '.tgz') }

    method probe {
        state $probe = try { run('perl', %?RESOURCES<scripts/perl5tar.pl>, :out, :err).exitcode == 0 ?? True !! False };
        ?$probe;
    }

    method extract($archive-file, $out) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$out folder does not exist and could not be created" unless (($out.IO.e && $out.IO.d) || mkdir($out));
        my $proc = run('perl', %?RESOURCES<scripts/perl5tar.pl>, $archive-file.IO.absolute, :cwd($out), :out);
        my $extracted-to = IO::Path.new(self.list($archive-file).head.Str, :CWD($out));
        ($proc.exitcode == 0 && $extracted-to.IO.e) ?? $extracted-to.absolute !! False;
    }

    method list($archive-file) {
        my $proc = run('perl', %?RESOURCES<scripts/perl5tar.pl>, '--list', $archive-file, :out);
        my @extracted-paths = $proc.out.slurp(:close).lines;
        $proc.exitcode == 0 ?? @extracted-paths.grep(*.defined) !! ();
    }
}
