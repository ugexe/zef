use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::Shell::PowerShell::unzip is Zef::Service::Shell::PowerShell does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }
    method probe { nextsame }

    method extract($archive-file, $out) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$out folder does not exist and could not be created" unless (($out.IO.e && $out.IO.d) || mkdir($out));
        my $extract-to = $out.IO.child(self.list($archive-file).head).absolute;
        my $proc = run(|@.invocation, %?RESOURCES<scripts/win32unzip.ps1>.IO.absolute, $archive-file.IO.absolute, $out.IO.absolute :!out, :!err);
        $ = (?$proc && $extract-to.IO.e) ?? $extract-to !! False;
    }

    method list($archive-file) {
        my $proc = run(|@.invocation, %?RESOURCES<scripts/win32unzip.ps1>.IO.absolute, $archive-file.IO.absolute, :out, :!err);
        my @extracted-paths = $proc.out.lines.map({ .IO.relative($archive-file) });
        $proc.out.close;
        $proc.so ?? @extracted-paths.grep(*.defined) !! ();
    }
}
