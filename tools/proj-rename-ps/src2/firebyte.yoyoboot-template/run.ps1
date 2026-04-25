param(
    # input src
    [string]$Src,
    # input target
    [string]$Target
)

# 执行公用脚本
. '.\process_file.ps1'

# 路径
$inputPath = "${Src}\"
$outputPath = "${Target}\"
Copy-Rename-CommonFiles -SourcePath $inputPath -OutputPath $outputPath

# 路径
$inputPath = "${Src}\src\"
$outputPath = "${Target}\src\"
Copy-Rename-AbpFiles -SourcePath $inputPath -OutputPath $outputPath


# 路径
$inputPath = "${Src}\test\"
$outputPath = "${Target}\test\"
Copy-Rename-AbpFiles -SourcePath $inputPath -OutputPath $outputPath

# 路径
$inputPath = "${Src}\build\"
$outputPath = "${Target}\build\"
Copy-Rename-AbpFiles -SourcePath $inputPath -OutputPath $outputPath





