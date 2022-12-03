$source = $env:NUGET_SOURCE
$apikey = $env:NUGET_SOURCE_APIKEY
$fileName = $env:PUSH_FILE_NAME
$disableApiKey = $env:DISABLE_API_KEY
$version = $env:TAG


# $source = 'http://nuget.org/index.json'
# $apikey = 'key'
# $fileName = './a-push.ps1'
# $version = '7.3.0.1'

$prefix = 'dotnet nuget push '
$suffix = ' --source "' + $source + '" --api-key "' + $apikey + '" --skip-duplicate'
if ($disableApiKey -eq $True) {
    $suffix = ' --source "' + $source + '" --skip-duplicate'
}

# 生成脚本
Get-ChildItem ./*.nupkg | Where-Object { $_.Name -match $version } `
| Select-Object { $prefix + $_.Name + $suffix }  `
| Out-File -width 1000 $fileName -Force

(Get-Content $fileName | Select-Object -Skip 3) | Set-Content $fileName

# 执行
. $fileName