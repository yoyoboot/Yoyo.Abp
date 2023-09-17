# 预定义参数
$source = 'http://nuget.org/index.json' # 源
$apikey = 'key' # key
$fileName = './push.ps1' # 发布文件
$disableApiKey = $False # 禁用apikey
$distPath = './dist' # nupkg 所在目录

# 是否为发布
$isProduction = $env:IS_PRODUCTION

# export NUGET_SOURCE="${gitlab_pack_nuget}"
# export NUGET_SOURCE_APIKEY="${gitlab_pack_token}"
# export DISABLE_API_KEY='True'

# 发布模式，从环境变量读取
if ($isProduction -eq $True) {
    $source = $env:NUGET_SOURCE
    $apikey = $env:NUGET_SOURCE_APIKEY
    $fileName = $env:PUSH_FILE_NAME
    $disableApiKey = $env:DISABLE_API_KEY
    $distPath = $env:DIST_PATH
    Write-Host "PACK PUSH Production Mode"
    Write-Host ("API KEY" + $apikey)
}

# 处理路径
if ($Null -eq $distPath) {
    $distPath = './dist'
}
if ($Null -eq $fileName) {
    $fileName = './push.ps1'
}


# 前缀后缀
$prefix = 'dotnet nuget push '
$suffix = ' --source "' + $source + '" --api-key "' + $apikey + '" --skip-duplicate'
if ($disableApiKey -eq $True) {
    $suffix = ' --source "' + $source + '" --skip-duplicate'
}

# 生成推送脚本
Get-ChildItem ($distPath + '/*.nupkg') `
| Select-Object { $prefix + $distPath + '/' + $_.Name + $suffix }  `
| Out-File -width 5000 $fileName -Force

(Get-Content $fileName | Select-Object -Skip 3) | Set-Content $fileName

# 执行
if ($isProduction -eq $True) {
    . $fileName
}


