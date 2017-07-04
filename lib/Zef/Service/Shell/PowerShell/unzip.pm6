use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::PowerShell::unzip is Zef::Service::Shell::PowerShell does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }
    method probe { nextsame }

    method extract($archive-file, $out) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$out folder does not exist and could not be created" unless (($out.IO.e && $out.IO.d) || mkdir($out));
        my $extracted-to = $out.IO.child(self.list($archive-file).head).absolute;
        my $proc = run(|@.invocation, %?RESOURCES<scripts/win32unzip.ps1>, $archive-file, $out);
        ($proc.exitcode == 0 && $extracted-to.IO.e) ?? $extracted-to !! False;
    }

    method list($archive-file) {
        my $proc = run(|@.invocation, %?RESOURCES<scripts/win32unzip.ps1>, $archive-file, :out);
        my @extracted-paths = $proc.out.slurp(:close).lines.map({ $_.IO.relative($archive-file) });
        $proc.exitcode == 0 ?? @extracted-paths.grep(*.defined) !! ();
    }
}
