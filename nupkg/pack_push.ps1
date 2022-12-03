$source = $env:NUGET_SOURCE
$apikey = $env:NUGET_SOURCE_APIKEY
$fileName = $env:PUSH_FILE_NAME
$disableApiKey = $env:DISABLE_API_KEY

# $source = 'http://nuget.org/index.json'
# $apikey = 'key'
# $fileName = './a-push.ps1'

$prefix = 'dotnet nuget push '
$suffix = ' --source "' + $source + '" --api-key "' + $apikey + '" --skip-duplicate'
if ($disableApiKey -eq $True) {
    $suffix = ' --source "' + $source + '" --skip-duplicate'
}

# 生成脚本
Get-ChildItem ./*.nupkg | Select-Object { $prefix + $_.Name + $suffix }  `
| Out-File -width 5000 $fileName -Force

(Get-Content $fileName | Select-Object -Skip 3) | Set-Content $fileName

# 执行
. $fileName