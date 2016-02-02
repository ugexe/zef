param (
    [string]$url = $(throw "-url is required."),
    [string]$out = $(throw "-out is required.")
)

$progressPreference = 'silentlyContinue' # hide progress output
$http_proxy = $env:http_proxy;

if ( $http_proxy -ne $null ) {
    Invoke-WebRequest -Uri $url -OutFile $out -Proxy
} else {
    Invoke-WebRequest -Uri $url -OutFile $out    
}
