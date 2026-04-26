# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'


$rootPath = 'D:\dev\gct-jgz\gct.foundation'
$rootPath = 'D:\dev\gct-jgz\ftp_none'


## ci.yml文件
$devPath = [System.IO.Path]::Join($rootPath, '.gitlab', 'ci', 'docker-images.dev-ci.yml')
$tagPath = [System.IO.Path]::Join($rootPath, '.gitlab', 'ci', 'docker-images.tag-ci.yml')


$content = ReadFile -Path $devPath

$content = $content -replace [Regex]::Escape('开发环境'), 'tag环境'
$content = $content -replace [Regex]::Escape('_dev:'), '_tag:'
$content = $content -replace [Regex]::Escape(':dev'), ':${TAG}'
$content = $content -replace [Regex]::Escape('}_dev'), '}'

# 替换 import中的  GXXX 为 YXXX
$matches = [Regex]::Matches($content, [Regex]::Escape("-(.*?)_dev"))
foreach ($match in $matches) {
    if ($match.Success -and $match.Groups.Count -eq 2) {
        $oldVal = $match.Value
        $newVal = $match.Groups[1].Value + '_tag'
        $content = $content -Replace [Regex]::Escape($oldVal), $newVal
    }
}

WriteFile -Path $tagPath -Content $content


## docker-compose.yml文件
$devPath = [System.IO.Path]::Join($rootPath, 'docker', 'docker-compose-dev.yml')
$tagPath = [System.IO.Path]::Join($rootPath, 'docker', 'docker-compose-tag.yml')


$content = ReadFile -Path $devPath

$content = $content -replace [Regex]::Escape('_DEV}'), '_TAG}'
$content = $content -replace [Regex]::Escape(':dev'), ':${TAG}'
$content = $content -replace [Regex]::Escape('ASPNETCORE_ENVIRONMENT=Development'), 'ASPNETCORE_ENVIRONMENT=Production'

WriteFile -Path $tagPath -Content $content
