$ErrorActionPreference = "Stop"
$baseDir = $PSScriptRoot
$proxyPath = Join-Path $baseDir "proxy.js"
$errorLog = Join-Path $baseDir "error.log"
$nodeExe = "C:\Program Files\nodejs\node.exe"

function Start-ProxyIfNeeded {
    try {
        $nodeProcess = Get-WmiObject Win32_Process -Filter "Name='node.exe' AND CommandLine LIKE '%proxy.js%'"
        if (-not $nodeProcess) {
            Start-Process -FilePath $nodeExe -ArgumentList "`"$proxyPath`"" -WindowStyle Hidden
        }
    } catch {
        $_ | Out-File $errorLog -Append
    }
}

function Update-DataJs {
    $categoryDirs = Get-ChildItem -Path $baseDir -Directory | Where-Object { $_.Name -notlike ".*" }

    $filesData = @()
    foreach ($folder in $categoryDirs) {
        $files = Get-ChildItem -Path $folder.FullName -File
        foreach ($file in $files) {
            $encodedName = [uri]::EscapeDataString($file.Name)
            $encodedFolder = [uri]::EscapeDataString($folder.Name)
            $filesData += @{
                name = $file.Name
                href = "./$encodedFolder/$encodedName"
                category = $folder.Name
                desc = $folder.Name
            }
        }
    }

    $jsonFiles = @($filesData) | ConvertTo-Json -Compress
    if ([string]::IsNullOrWhiteSpace($jsonFiles)) { $jsonFiles = "[]" }

    $jsContent = "FILES = $jsonFiles;"
    $jsFile = Join-Path $baseDir "data.js"

    $maxRetries = 3
    for ($i=0; $i -lt $maxRetries; $i++) {
        try {
            [System.IO.File]::WriteAllText($jsFile, $jsContent, (New-Object System.Text.UTF8Encoding $false))
            break
        } catch {
            Start-Sleep -Milliseconds 200
        }
    }
}

Start-ProxyIfNeeded
Update-DataJs

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $baseDir
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -match 'data\.js$') { return }
    Update-DataJs
}

Register-ObjectEvent $watcher "Created" -Action $action | Out-Null
Register-ObjectEvent $watcher "Deleted" -Action $action | Out-Null
Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
Register-ObjectEvent $watcher "Renamed" -Action $action | Out-Null

while ($true) {
    Start-ProxyIfNeeded
    Start-Sleep -Seconds 10
}
