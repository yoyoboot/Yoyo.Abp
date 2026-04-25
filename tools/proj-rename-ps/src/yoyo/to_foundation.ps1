# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'
. '.\func_foundation.ps1'

$inputRootPath = 'D:\dev\gct-jgz\ftp_none'
$outputRootPath = 'D:\dev\gct-jgz\gct.foundation'




# 获取前端项目文件
$files = GetProjFilesOnlyVue -Path $inputRootPath


# 遍历复制文件
foreach ($item in $files) {
    # 文件目录
    $path = DirReplace $item.DirectoryName $inputRootPath $outputRootPath

    # 文件夹不存在则创建
    If (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    # 复制文件到此目录
    Copy-Item $item.FullName -Destination $path -Force
}

# 移除shared模块
DelShared $outputRootPath

# 移除admin目录
MoveAdmin2 $outputRootPath

