$scriptContent = @'
function Update-DataJs {
    $baseDir = "E:\YS-刘伟\WEB\share"
    $folders = @("说明书", "配置文件", "安装包")
    
    $filesData = @()
    foreach ($folder in $folders) {
        $folderPath = Join-Path $baseDir $folder
        if (Test-Path $folderPath) {
            $files = Get-ChildItem -Path $folderPath -File
            foreach ($file in $files) {
                $encodedName = [uri]::EscapeDataString($file.Name)
                $encodedFolder = [uri]::EscapeDataString($folder)
                $filesData += @{
                    name = $file.Name
                    href = "./$encodedFolder/$encodedName"
                    category = $folder
                    desc = "$folder"
                }
            }
        }
    }
    
    $jsonFiles = $filesData | ConvertTo-Json -Compress
    if ([string]::IsNullOrWhiteSpace($jsonFiles)) { $jsonFiles = "[]" }
    
    $jsContent = "FILES = $jsonFiles;"
    $jsFile = Join-Path $baseDir "data.js"
    
    $maxRetries = 3
    for ($i=0; $i -lt $maxRetries; $i++) {
        try {
            [System.IO.File]::WriteAllText($jsFile, $jsContent, [System.Text.Encoding]::UTF8)
            break
        } catch {
            Start-Sleep -Milliseconds 200
        }
    }
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "E:\YS-刘伟\WEB\share"
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

Update-DataJs
while ($true) { Start-Sleep -Seconds 1 }
'@

[System.IO.File]::WriteAllText("E:\YS-刘伟\WEB\share\watch_service.ps1", $scriptContent, [System.Text.Encoding]::UTF8)
