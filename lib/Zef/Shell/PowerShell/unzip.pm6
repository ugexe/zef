use Zef::Shell::PowerShell;

my constant UNZIP_SCRIPT = q:to/END_POWERSHELL_SCRIPT/;
    $archive = $env:ZEF_SHELL_ZIPFILE
    $target = $env:ZEF_SHELL_TARGET
    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($archive)
    $out = $shell.NameSpace($target)
    $out.CopyHere($zip.items(), 0x14)
    END_POWERSHELL_SCRIPT

class Zef::Shell::PowerShell::unzip is Zef::Shell::PowerShell does Extractor {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }
    method probe { nextsame } # todo: version check for .Copyhere
    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));
        my $proc = $.run-script(UNZIP_SCRIPT, :ZEF_SHELL_ZIPFILE($archive-file), :ZEF_SHELL_TARGET($save-as));
        my $extracted-to = $save-as.IO.child(self.list($archive-file).head);
        so $proc ?? $extracted-to !! False;
    }

    method list($archive-file) {
        #my $nl   = Buf.new(10).decode;
        #my $proc = $.zrun('unzip', '-Z', '-1', $archive-file, :out);
        #my @extracted-paths <== grep *.defined <== split $nl, $proc.out.slurp-rest;
    }
}
