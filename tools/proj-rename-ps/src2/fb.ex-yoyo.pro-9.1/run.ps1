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
Copy-Rename-Fb -SourcePath $inputPath -OutputPath $outputPath





