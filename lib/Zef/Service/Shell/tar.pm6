use Zef;

# XXX: when passing command line arguments to tar in this module be sure to use
# relative paths. ex: set :cwd to $tar-file.parent, and use $tar-file.basename as the target
# This is because gnu tar on windows can't handle a windows style volume in path arguments

class Zef::Service::Shell::tar does Extractor does Messenger {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz' | '.tgz') }

    method probe {
        state $probe = try { run('tar', '--help', :!out, :!err).so };
    }

    method extract($archive-file, $save-as) {
        my $from = $archive-file.IO.basename;
        my $cwd  = $archive-file.IO.parent;

        die "archive file does not exist: {$from}"
            unless $archive-file.IO.e && $archive-file.IO.f;
        die "target extraction directory {$save-as} does not exist and could not be created"
            unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));

        my @files    = self.list($archive-file);
        my $root-dir = $save-as.IO.child(@files[0]);

        my $proc = run('tar', '-zxvf', $from, '-C', $save-as.IO.relative($cwd), :$cwd, :!out, :!err);

        my $extracted-to = $save-as.IO.child(self.list($archive-file).head);
        ($proc.so && $extracted-to.IO.e) ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $from = $archive-file.IO.basename;
        my $cwd  = $archive-file.IO.parent;

        my $proc = run('tar', '--list', '-f', $from, :$cwd, :out, :!err);
        my @extracted-paths = $proc.out.lines;
        $proc.out.close;
        $proc.so ?? @extracted-paths.grep(*.defined) !! ();
    }
}
