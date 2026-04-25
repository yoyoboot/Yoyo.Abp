# 执行公用脚本
. '..\common\common.ps1'
. '.\1_functions.ps1'

$inputRootPath = 'D:\dev\gct-jgz\gct.foundation\src\aspnet-core'
$outputRootPath = 'D:\dev\test1\yoyoboot\src\aspnet-core'

# 获取项目文件
$files = GetProjFiles -Path $inputRootPath


# 目录路径替换
function DirReplace2 {
    param (
        [string]$path,
        [string]$inputPath,
        [string]$outputPath
    )

    $fileDir = DirReplace -Path $path -inputPath $inputPath -outputPath $outputPath
    $fileDir = $fileDir -replace '\\g-', '\y-'
    $fileDir = $fileDir -replace 'GCT.Foundation', 'YoyoBoot'
    $fileDir = $fileDir -replace 'Foundation', 'YoyoBoot'
    $fileDir = $fileDir -replace 'GCT.AbpEx', 'Yoyo.Pro'
    $fileDir = $fileDir -replace 'IGCTAbp', 'IYoyo'
    $fileDir = $fileDir -replace 'GCT', 'AppPro'
    # $fileDir = $fileDir -replace 'GCTPermissionNames', 'AppProPermissionNames'
    # $fileDir = $fileDir -replace 'GCTMailKitSmtpBuilder', 'AppProMailKitSmtpBuilder'
    # $fileDir = $fileDir -replace 'GCTDapperRepository', 'AppProDapperRepository'

    if ($path.EndsWith('GCT.Foundation.sln')) {
        Write-Host $fileDir
    }

    return $fileDir
}

# 遍历复制文件
foreach ($item in $files) {

    # 文件目录
    $path = DirReplace2 $item.DirectoryName $inputRootPath $outputRootPath

    # 文件夹不存在则创建
    If (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }

   

    # 复制文件到指定文件
    $ouputFullPath = DirReplace2 $item.FullName $inputRootPath $outputRootPath
    Copy-Item $item.FullName -Destination $ouputFullPath -Force
}

# # 移除shared模块
DelShared $outputRootPath

# # 调整图标
# GenLogo $outputRootPath

# 处理文件名称
NameProcessor -Path $outputRootPath 
