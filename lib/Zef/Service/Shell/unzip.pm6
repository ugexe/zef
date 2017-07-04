use Zef;

class Zef::Service::Shell::unzip does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }

    method probe {
        state $probe = try { run('unzip', '--help', :out, :err).exitcode == 0 ?? True !! False };
        ?$probe;
    }

    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));
        my $proc = run('unzip', '-o', '-qq', $archive-file, '-d', $save-as);
        my $extracted-to = $save-as.IO.child(self.list($archive-file).head);
        $proc.exitcode == 0 ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $proc = run('unzip', '-Z', '-1', $archive-file, :out);
        my @extracted-paths = $proc.out.slurp(:close).lines;
        $proc.exitcode == 0 ?? @extracted-paths.grep(*.defined) !! ();
    }
}
