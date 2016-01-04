use Zef::Shell::PowerShell;

# todo: untar (this is just gz)
my constant UNTAR_SCRIPT = q:to/END_POWERSHELL_SCRIPT/;
    $archive = $env:ZEF_SHELL_GZFILE
    $target = $env:ZEF_SHELL_TARGET
    $shell = New-Object -com shell.application
    $gz = $shell.NameSpace($archive)
    $out = $shell.NameSpace($target)
    $input = New-Object System.IO.FileStream $gz, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $out, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
    $buffer = New-Object byte[](1024)
    while($true){
        $read = $gzipStream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
    }
    $gzipStream.Close()
    $output.Close()
    $input.Close()
    END_POWERSHELL_SCRIPT

class Zef::Shell::PowerShell::tar is Zef::Shell::PowerShell does Extractor {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'gz' }
    method probe { nextsame } # todo: version check for .Copyhere
    method extract($archive-file, $save-as) {
        die "file does not exist: {$archive-file}" unless $archive-file.IO.e && $archive-file.IO.f;
        die "\$save-as folder does not exist and could not be created" unless (($save-as.IO.e && $save-as.IO.d) || mkdir($save-as));

        my $proc = $.run-script(UNTAR_SCRIPT, :ZEF_SHELL_GZFILE($archive-file), :ZEF_SHELL_TARGET($save-as));
        so $proc ?? $save-as !! False;
    }
}
