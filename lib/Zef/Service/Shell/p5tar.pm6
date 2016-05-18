use Zef;
use Zef::Shell;

# covers untar for some windows users until a better solution is found
class Zef::Service::Shell::p5tar is Zef::Shell does Extractor does Messenger {
    method extract-matcher($path) { so $path.lc.ends-with('.tar.gz') }

    method probe {
        state $p5module-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('perl', %?RESOURCES<scripts/perl5tar.pl>);
        }
        ?$p5module-probe;
    }

    method extract($archive-file, $out) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$out folder does not exist and could not be created" unless (($out.IO.e && $out.IO.d) || mkdir($out));
        my $proc = $.zrun('perl', %?RESOURCES<scripts/perl5tar.pl>, $archive-file.IO.absolute, :cwd($out), :out);
        my @stdout = $proc.out.lines;
        $proc.out.close;
        my $extracted-to := IO::Path.new(self.list($archive-file)[0].Str, :CWD($out));
        $ = ?$proc ?? $extracted-to.absolute !! False;
    }

    method list($archive-file) {
        my $proc = $.zrun('perl', %?RESOURCES<scripts/perl5tar.pl>, '--list', $archive-file, :out);
        my @extracted-paths = |$proc.out.lines;
        $proc.out.close;
        $ = ?$proc ?? @extracted-paths.grep(*.defined) !! False;
    }
}
