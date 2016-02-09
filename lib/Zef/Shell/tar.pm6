use Zef;
use Zef::Shell;

# XXX: when passing command line arguments to tar in this module be sure to use
# relative paths. ex: set :cwd to $tar-file.parent, and use $tar-file.basename as the target
# This is because gnu tar on windows can't handle a windows style volume in path arguments

class Zef::Shell::tar is Zef::Shell does Extractor does Messenger {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz') }

    method probe {
        # todo: check without spawning process (slow)
        state $tar-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('tar', '--help');
        }
        ?$tar-probe;
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

        my $proc = $.zrun('tar', '-zxvf', $from, '-C', $save-as.IO.relative($cwd), :$cwd, :out, :err);
        my @out  = |$proc.out.lines;
        my @err  = |$proc.err.lines;
        $proc.out.close;
        $proc.err.close;

        $ = (?$proc && $root-dir.IO.e) ?? $root-dir !! False;
    }

    method list($archive-file) {
        my $from = $archive-file.IO.basename;
        my $cwd  = $archive-file.IO.parent;

        my $proc  = $.zrun('tar', '--list', '-f', $from, :$cwd, :out, :err);
        my @files = |$proc.out.lines;
        my @err   = |$proc.err.lines;
        $proc.out.close;
        $proc.err.close;

        @ = ?$proc ?? @files.grep(*.defined) !! ();
    }
}
