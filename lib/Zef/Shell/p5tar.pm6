use Zef;
use Zef::Shell;

# covers untar for some windows users until a better solution is found
class Zef::Shell::p5tar is Zef::Shell does Extractor {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz') }

    method probe {
        state $p5-module-ok = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('perl', '-MArchive::Tar', '-e', 1);
        }

        so $p5-module-ok;
    }

    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));
        my $p5script = 'my $extractor = Archive::Tar->new(); $extractor->read($ARGV[0]); $extractor->extract();';
        my $proc = zrun('perl', '-MArchive::Tar', '-e', $p5script, $archive-file.IO.absolute, :cwd($save-as));
        my $extracted-to = $save-as.IO.child(self.list($archive-file).head);
        $ = ?$proc ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $nl   = Buf.new(10).decode;
        my $p5script = 'my $extractor = Archive::Tar->new(); $extractor->read($ARGV[0]); for($extractor->list_files()) { print $_ . qq{\n} };';
        my $proc = zrun('perl', '-MArchive::Tar', '-e', $p5script, $archive-file, :out);
        say $proc.perl;
        my @extracted-paths <== grep *.defined <== split $nl, $proc.out.slurp-rest;
        $proc.out.close;
        @ = @extracted-paths;
    }
}
