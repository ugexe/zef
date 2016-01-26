use Zef;
use Zef::Shell;

class Zef::Shell::unzip is Zef::Shell does Extractor {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }

    method probe {
        # todo: check without spawning process (slow)
        state $unzip-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('unzip', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my $out |$proc.out.lines;
            $proc.out.close;
            $ = ?$proc;
        }
        ?$unzip-probe;
    }

    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));
        my $proc = $.zrun('unzip', '-qq', $archive-file, '-d', $save-as);
        my $extracted-to = $save-as.IO.child(self.list($archive-file).head);
        $ = ?$proc ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $nl   = Buf.new(10).decode;
        my $proc = $.zrun('unzip', '-Z', '-1', $archive-file, :out);
        my @extracted-paths = |$proc.out.lines;
        $proc.out.close;
        @ = @extracted-paths;
    }
}
