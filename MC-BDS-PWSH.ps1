# Global Variables
$gameDir = "C:\Minecraft_Server\Bedrock_Server"
$baseUri = "https://www.minecraft.net/en-us/download/server/bedrock"
$downloadFileUri = "https://minecraft.azureedge.net/bin-win"
$filesToBackup = "server.properties", "allowlist.json", "permissions.json"
$processName = "bedrock_server"

# Net Vars
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.54 Safari/537.36 Edg/95.0.1020.30"
$session.Cookies.Add((New-Object System.Net.Cookie("MSGCC", "granted", "/", "www.minecraft.net")))


Set-Location $gameDir
$result = Invoke-WebRequest -UseBasicParsing -Uri $baseUri -WebSession $session `
    -Headers @{
        "method"="GET"
        "authority"="www.minecraft.net"
        "path"="/en-us/download/server/bedrock"
        "pragma"="no-cache"
        "cache-control"="no-cache"
        "scheme"="https"
        "dnt"="1"
        "upgrade-insecure-requests"="1"
        "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
        "sec-fetch-site"="cross-site"
        "sec-fetch-mode"="navigate"
        "sec-fetch-user"="?1"
        "sec-fetch-dest"="document"
        "accept-encoding"="gzip, deflate, br"
        "accept-language"="en-US,en;q=0.9,es;q=0.8,en-GB;q=0.7,es-ES;q=0.6,nl;q=0.5"
        "sec-gpc"="1"
    }
$serverurl = $result.Links | Where-Object {$_.href -Match ("$downloadFileUri/bedrock-server*")}
$url = $serverurl.href
$filename = $url.Replace("$downloadFileUri/","")
$url = "$url"
$output = "$gameDir\$filename"

# If the file haven't been downloaded yet, download it and backup the configs
if(!(Get-Item $output)){
    Stop-Process -Name $processName -ErrorAction SilentlyContinue

    # DO AN BACKUP OF CONFIG
    if(!(Test-Path -Path "$gameDir\backup")) {
        New-Item -ItemType Directory -Name backup
    }
    foreach ($file in $filesToBackup) {
        Copy-Item -Path $file -Destination "$gameDir\backup"
    }

    $start_time = Get-Date

    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $output `
        -WebSession $session `
        -Headers @{
            "method"="GET"
            "authority"="minecraft.azureedge.net"
            "path"="/bin-win/bedrock-server-1.18.12.01.zip"
            "referer"="https://www.minecraft.net/"
            "scheme"="https"
            "dnt"="1"
            "upgrade-insecure-requests"="1"
            "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
            "sec-fetch-site"="cross-site"
            "sec-fetch-mode"="navigate"
            "sec-fetch-user"="?1"
            "sec-fetch-dest"="document"
            "accept-encoding"="gzip, deflate, br"
            "accept-language"="en-US,en;q=0.9,es;q=0.8,en-GB;q=0.7,es-ES;q=0.6,nl;q=0.5"
            "sec-gpc"="1"
        }


    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Expand-Archive -LiteralPath $output -DestinationPath $gameDir -Force

    # Recover backup configs
    foreach ($file in $filesToBackup) {
        Copy-Item -Path "$gameDir\backup\$file" -Destination $gameDir
    }

}

if(!(Get-process -Name bedrock_server -ErrorAction SilentlyContinue)){
    Start-Process -FilePath bedrock_server.exe
}
