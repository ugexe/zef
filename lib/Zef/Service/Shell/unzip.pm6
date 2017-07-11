use Zef;

class Zef::Service::Shell::unzip does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }

    method probe {
        state $probe = try { zrun('unzip', '--help', :!out, :!err).so };
    }

    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));
        my $proc = zrun('unzip', '-o', '-qq', $archive-file, '-d', $save-as, :!out, :!err);
        my $extracted-to = $save-as.IO.child(self.list($archive-file).head);
        $proc.so ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $proc = zrun('unzip', '-Z', '-1', $archive-file, :out, :!err);
        my @extracted-paths = $proc.out.lines;
        $proc.out.close;
        $proc.so ?? @extracted-paths.grep(*.defined) !! ();
    }
}
