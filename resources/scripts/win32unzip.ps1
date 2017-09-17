Param (
    [Parameter(Mandatory=$True)] [string]$FilePath,
    $out = ""
)
$shell = New-Object -com shell.application
$FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
$items = $shell.NameSpace($FilePath).items()

function List-ZipFiles {
    $ns = $shell.NameSpace($args[0])
    foreach( $item in $ns.Items() ) {
        if( $item.IsFolder ) {
            List-ZipFiles($item)
        } else {
            $path = $item | Select -ExpandProperty Path
            Write-Host $path
        }
    }
}

if( $out -ne '' ) {
    $to = $shell.NameSpace($out)
    $to.CopyHere($items, 0x14)
} else {
    $path = $items | Select -ExpandProperty Path
    Write-Host $path
    List-ZipFiles $path
}
