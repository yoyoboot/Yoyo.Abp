# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'
. '.\func_g.ps1'

$inputRootPath = 'D:\dev\gct-migration\gct.foundation_old\src\aspnet-core'
$outputRootPath = 'D:\dev\gct-migration\gct.foundation\src\aspnet-core'




# 获取项目文件
$files = GetProjFiles -Path $inputRootPath


# 遍历复制文件
foreach ($item in $files) {

    # # 不复制angular
    # if ($item.FullName.Contains('angular')) {
    #     continue
    # }

    # # 不复制
    # if ($item.FullName.Contains('docs')) {
    #     continue
    # }    

    # 文件目录
    $path = DirReplace2 $item.DirectoryName $inputRootPath $outputRootPath

    # 文件夹不存在则创建
    If (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }

   

    # 复制文件到指定文件
    $ouputFullPath = DirReplace2 $item.FullName $inputRootPath $outputRootPath
    Copy-Item $item.FullName -Destination $ouputFullPath -Force

    if ($ouputFullPath.EndsWith('.sln')) {
        Write-Host $ouputFullPath
    }
}


# 处理文件内容
NameProcessor3 -Path $outputRootPath 
