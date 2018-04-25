Param (
    [Parameter(Mandatory=$True)] [System.Uri]$uri,
    [Parameter(Mandatory=$True)] [string]$FilePath,
    $UserAgent = "rakudo perl6/zef powershell downloader"
)

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls";

$client = New-Object System.Net.WebClient;
$client.Headers['User-Agent'] = $UserAgent;
$client.DownloadFile($uri.ToString(), $FilePath)
