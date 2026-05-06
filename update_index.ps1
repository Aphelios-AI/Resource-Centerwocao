$baseDir = "E:\YS-刘伟\WEB\share"
$folders = @("说明书", "配置文件", "安装包")
$htmlFile = Join-Path $baseDir "index.html"

# 获取文件列表
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

# 读取 index.html
$content = Get-Content $htmlFile -Raw -Encoding UTF8

# 使用正则表达式替换 FILES 数组
# 匹配 const FILES = [...];
$pattern = '(?s)const FILES = \[.*?\];'
$replacement = "const FILES = $jsonFiles;"
$newContent = [regex]::Replace($content, $pattern, $replacement)

# 写回 index.html
Set-Content $htmlFile $newContent -Encoding UTF8

Write-Host "已更新 index.html 中的文件列表。"
