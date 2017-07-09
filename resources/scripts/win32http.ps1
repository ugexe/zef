Param (
    [Parameter(Mandatory=$True)] [System.Uri]$uri,
    [Parameter(Mandatory=$True )] [string]$FilePath
)

if ( -not (Test-Path $FilePath) ) {
    [void] (New-Object System.Net.WebClient).DownloadFile($uri.ToString(), $FilePath)
} else {
    try {
        $webRequest = [System.Net.HttpWebRequest]::Create($uri);
        $webRequest.IfModifiedSince = ([System.IO.FileInfo]$FilePath).LastWriteTime
        $webRequest.Method = "GET";
        [System.Net.HttpWebResponse]$webResponse = $webRequest.GetResponse()

        $stream = New-Object System.IO.StreamReader($response.GetResponseStream())
        $stream.ReadToEnd() | Set-Content -Path $FilePath -Force
    } catch [System.Net.WebException] {
        # If content isn't modified according to the output file timestamp then ignore the exception
        if ($_.Exception.Response.StatusCode -ne [System.Net.HttpStatusCode]::NotModified) {
            throw $_
        }
    }
}
