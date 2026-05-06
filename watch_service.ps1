$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "E:\YS-刘伟\WEB\share"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $baseDir = "E:\YS-刘伟\WEB\share"
    $folders = @("说明书", "配置文件", "安装包")
    $htmlFile = Join-Path $baseDir "index.html"
    
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
                    desc = "$folder文件"
                }
            }
        }
    }
    
    $jsonFiles = $filesData | ConvertTo-Json -Compress
    if ($jsonFiles -eq $null) { $jsonFiles = "[]" }
    
    # 尝试重试读取，防止文件被锁
    $maxRetries = 3
    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
        try {
            $content = Get-Content $htmlFile -Raw -Encoding UTF8
            $pattern = '(?s)const FILES = \[.*?\];'
            $replacement = "const FILES = $jsonFiles;"
            $newContent = [regex]::Replace($content, $pattern, $replacement)
            Set-Content $htmlFile $newContent -Encoding UTF8
            Write-Host "Updated index.html at $(Get-Date)"
            break
        } catch {
            Start-Sleep -Milliseconds 500
            $retryCount++
        }
    }
}

Register-ObjectEvent $watcher "Created" -Action $action | Out-Null
Register-ObjectEvent $watcher "Deleted" -Action $action | Out-Null
Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
Register-ObjectEvent $watcher "Renamed" -Action $action | Out-Null

Write-Host "监控已启动，请勿关闭此窗口... (按 Ctrl+C 停止)"
while ($true) { Start-Sleep -Seconds 1 }
