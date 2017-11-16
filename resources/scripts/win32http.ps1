Param (
    [Parameter(Mandatory=$True)] [System.Uri]$uri,
    [Parameter(Mandatory=$True)] [string]$FilePath,
    $UserAgent = "rakudo perl6/zef powershell downloader"
)

$client = New-Object System.Net.WebClient;
$client.Headers['User-Agent'] = $UserAgent;
$client.DownloadFile($uri.ToString(), $FilePath)
