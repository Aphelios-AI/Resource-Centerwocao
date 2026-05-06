$ErrorActionPreference = "Stop"
try {
    # 启动本地代理服务解决火山引擎跨域限制
    $proxyPath = "E:\YS-刘伟\WEB\share\proxy.js"
    $nodeProcess = Get-WmiObject Win32_Process -Filter "Name='node.exe' AND CommandLine LIKE '%proxy.js%'"
    $nodeExe = "C:\Program Files\nodejs\node.exe"
    if (-not $nodeProcess) {
        Start-Process -FilePath $nodeExe -ArgumentList "'$proxyPath'" -WindowStyle Hidden
    }
} catch {
    $_ | Out-File "E:\YS-刘伟\WEB\share\error.log" -Append
}

function Update-DataJs {
    $baseDir = "E:\YS-刘伟\WEB\share"
    $folders = @("常用软件", "运维工具", "使用文档", "常见问题")
    
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
            [System.IO.File]::WriteAllText($jsFile, $jsContent, (New-Object System.Text.UTF8Encoding $false))
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
