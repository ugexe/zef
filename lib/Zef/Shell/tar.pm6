use Zef;
use Zef::Shell;

class Zef::Shell::tar is Zef::Shell does Extractor {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz') }

    method probe {
        # todo: check without spawning process (slow)
        state $untar-help = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('tar', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out  = $proc.out.lines;
            $proc.out.close;
            $ = $proc.exitcode == 0 ?? @out !! False;
        }

        so $untar-help;
    }

    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));
        my $proc = $.zrun('tar', '-zxvf', $archive-file, '-C', $save-as, :out);
        my $stdout = $proc.out.slurp-rest;
        $proc.out.close;
        my $extracted-to = $save-as.IO.child(self.list($archive-file)[0]);
        $ = try { so $proc } ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $proc = $.zrun('tar', '--list', '-f', $archive-file, :out);
        my @extracted-paths = $proc.out.lines.grep(*.defined);
        $proc.out.close;
        @ = @extracted-paths;
    }
}
