$source = $env:NUGET_SOURCE
$apikey = $env:NUGET_SOURCE_APIKEY
$fileName = $env:PUSH_FILE_NAME


$prefix = 'dotnet nuget push '
$suffix = ' --source "' + $source + '" --api-key "' + $apikey + '"'

# 生成脚本
Get-ChildItem ./*.nupkg | Select-Object { $prefix + $_.Name + $suffix }  | Out-File -width 1000 ./push.bat -Force
(Get-Content $fileName | Select-Object -Skip 3) | Set-Content .$fileName


# 执行
. $fileName