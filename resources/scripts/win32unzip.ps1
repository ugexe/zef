param (
    [string]$file = $(throw "-file is required."),
    [string]$out
)
$shell = New-Object -com shell.application
$zip = $shell.NameSpace($file)

function List-ZipFiles {
    $ns = $shell.NameSpace($args[0])
    foreach( $item in $ns.Items() ) {
        if( $item.IsFolder ) {
            List-ZipFiles($item)
        } else {
            $path = $item | Select -ExpandProperty Path
            Write-Host($path)
        }
    }
}

if( $out -ne '' ) {
    $items = $zip.items()
    $to = $shell.NameSpace($out)
    $to.CopyHere($items, 0x14)
} else {
    $items = $zip.items()
    $path = $items | Select -ExpandProperty Path
    Write-Host $path
    List-ZipFiles $path
}
