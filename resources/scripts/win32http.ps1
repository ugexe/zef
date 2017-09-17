Param (
    [Parameter(Mandatory=$True)] [System.Uri]$uri,
    [Parameter(Mandatory=$True)] [string]$FilePath,
    $UserAgent = "rakudo perl6/zef powershell downloader"
)

if ( -not (Test-Path $FilePath) ) {
    $client = New-Object System.Net.WebClient;
    $client.Headers['User-Agent'] = $UserAgent;
    $client.DownloadFile($uri.ToString(), $FilePath)
} else {
    try {
        $webRequest = [System.Net.HttpWebRequest]::Create($uri);
        $webRequest.IfModifiedSince = ([System.IO.FileInfo]$FilePath).LastWriteTime
        $webRequest.UserAgent = $UserAgent;
        $webRequest.Method = "GET";
        [System.Net.HttpWebResponse]$webResponse = $webRequest.GetResponse()

        $stream = New-Object System.IO.StreamReader($webResponse.GetResponseStream())
        $stream.ReadToEnd() | Set-Content -Path $FilePath -Force
    } catch [System.Net.WebException] {
        # If content isn't modified according to the output file timestamp then ignore the exception
        if ($_.Exception.Response.StatusCode -ne [System.Net.HttpStatusCode]::NotModified) {
            throw $_
        }
    }
}
