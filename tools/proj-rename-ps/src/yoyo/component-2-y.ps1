# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'
. '.\func_y.ps1'


$inputRootPath = 'D:\dev\gct-jgz\gct-vue-abp-modules'
$outputRootPath = 'D:\dev\52abp\basic-module-vue'


# 获取所有文件
$files = GetProjFiles -Path $inputRootPath


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
    $ouputFullPath = DirReplace $ouputFullPath "gct-" "basic-"
    Copy-Item $item.FullName -Destination $ouputFullPath -Force
}


# 处理文件名称
VuePackNameProcessor -Path $outputRootPath 