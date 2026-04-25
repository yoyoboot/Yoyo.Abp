# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'

$inputRootPath = 'D:\dev\gct-jgz\gct.foundation.template'
$outputRootPath = 'D:\dev\tmp'

# 获取所有的文件
$files = GetProjFiles -Path $inputRootPath




# 遍历文件
foreach ($item in $files) {
    $fileDir = $item.DirectoryName -Replace [Regex]::Escape($inputRootPath), $outputRootPath
    $fileDir = $fileDir -replace '\\g-', '\y-'

    # 文件夹不存在则创建
    If (!(Test-Path $fileDir)) {
        New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
    }
    # 复制文件到此目录
    Copy-Item $_.FullName -Destination $path -Force

    # 读取文件内容
    $content = ReadFile -Path $path

    # 前端项目重命名
    # VueG2Y -Path $path -Content $content

    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}

