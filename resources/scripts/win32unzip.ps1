param (
    [string]$file = $(throw "-file is required."),
    [string]$out
)
$shell = New-Object -com shell.application
$zip = $shell.NameSpace($file)

if( $out -ne '' ) {
    $items = $zip.items()
    $to = $shell.NameSpace($out)
    $to.CopyHere($items, 0x14)
} else {
    $path = $zip.items() | Select -ExpandProperty Path
    Write-Host $path

    # TODO:
    # Make this list *all files* in an archive. Currently only lists
    # the root directory of the archive. However the root can be used
    # to get the files/folders inside, which could then be filtered by
    # file/folder while recursively repeating this on folders
    # $root = $shell.NameSpace($path)
    # $rootItems = $root.Items() | Select -ExpandProperty Path
}
