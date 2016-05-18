use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::PowerShell::unzip is Zef::Service::Shell::PowerShell does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }
    method probe { nextsame }

    method extract($archive-file, $out) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$out folder does not exist and could not be created" unless (($out.IO.e && $out.IO.d) || mkdir($out));
        my $extract-to = $out.IO.child(self.list($archive-file).head).absolute;
        my $proc = $.zrun(%?RESOURCES<scripts/win32unzip.ps1>, $archive-file, $out);
        $ = (?$proc && $extract-to.IO.e) ?? $extract-to !! False;
    }

    method list($archive-file) {
        my $proc = $.zrun(%?RESOURCES<scripts/win32unzip.ps1>, $archive-file, :out);
        my @extracted-paths = |$proc.out.lines.map({ $_.IO.relative($archive-file) });
        $proc.out.close;
        @ = ?$proc ?? @extracted-paths.grep(*.defined) !! ();
    }
}
