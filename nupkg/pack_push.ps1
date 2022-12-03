$source = $env:NUGET_SOURCE
$apikey = $env:NUGET_SOURCE_APIKEY
$fileName = $env:PUSH_FILE_NAME

# $source = 'http://nuget.org/index.json'
# $apikey = 'key'
# $fileName = './aaa.ps1'

$prefix = 'dotnet nuget push '
$suffix = ' --source "' + $source + '" --api-key "' + $apikey + '" --skip-duplicate'

# 生成脚本
Get-ChildItem ./*.nupkg | Select-Object { $prefix + $_.Name + $suffix }  `
| Out-File -width 1000 $fileName -Force

(Get-Content $fileName | Select-Object -Skip 3) | Set-Content $fileName

# 执行
. $fileName