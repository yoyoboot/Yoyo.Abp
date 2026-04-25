

# 目录路径替换
function DirReplace {
    param (
        [string]$path,
        [string]$inputPath,
        [string]$outputPath
    )

    
    $fileDir = $path -replace [Regex]::Escape($inputPath), $outputPath

    return $fileDir
}



# 目录路径替换
function DirReplace2 {
    param (
        [string]$path,
        [string]$inputPath,
        [string]$outputPath
    )



    $fileDir = DirReplace -Path $path -inputPath $inputPath -outputPath $outputPath
    $fileDir = $fileDir -Replace [Regex]::Escape('52AbpDomainService'), 'YoyoProDomainService'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoyoSoftPermissionNames'), 'YoyoProPermissionNames'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoMailKitSmtpBuilder'), 'YoyoProMailKitSmtpBuilder'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoDapperRepository'), 'YoyoProDapperRepository'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoABPEFCoreConsts'), 'YoyoProEFCoreConsts'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoJwtSecurityTokenValidator'), 'YoyoProJwtSecurityTokenValidator'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoJwtSecurityTokenHandler'), 'YoyoProJwtSecurityTokenHandler'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoyoCmsHealthCheck'), 'YoyoProHealthCheck'
    $fileDir = $fileDir -Replace [Regex]::Escape('yoyosoft'), 'YoyoPro'
    $fileDir = $fileDir -replace 'L52AbpPro', 'YoyoPro'
    $fileDir = $fileDir -replace 'L52Abp', 'YoyoPro'
    $fileDir = $fileDir -replace 'L.52AbpPro', 'Yoyo.Pro'
    $fileDir = $fileDir -replace 'L.52ABP', 'Yoyo.Pro'
    $fileDir = $fileDir -replace 'L.52Abp', 'Yoyo.Pro'
    $fileDir = $fileDir -replace 'Yoyo.Abp', 'Yoyo.Pro'
    $fileDir = $fileDir -replace 'YoyoAbp', 'YoyoPro'
    $fileDir = $fileDir -replace '52AbpPro', 'YoyoPro'
    $fileDir = $fileDir -replace '52Abp', 'YoyoPro'
    $fileDir = $fileDir -replace 'Yoyo.DbStore', 'Yoyo.Pro.DbStore'
    $fileDir = $fileDir -replace 'YoyoProAlipay', 'YoyoAlipay'

    # if ($path.EndsWith('.sln')) {
    #     Write-Host $fileDir
    # }

    return $fileDir
}

# 读取文件 utf8
function ReadFile {
    param (
        $path
    )
    return Get-Content -Path $path -Encoding UTF8
}

# 写入文件 utf8
function WriteFile {
    param (
        $path,
        $content
    )
    Set-Content -Path $path  -Value $content -Encoding UTF8 -Force
}

# 获取项目文件-所有
function GetProjFiles {
    param (
        $path
    )
    return Get-ChildItem $path -Recurse -File | Where-Object {
        $_.FullName -NotMatch '\\node_modules\\' -and $_.FullName -NotMatch '\\bin\\' -and $_.FullName -NotMatch '\\obj\\' -and $_.FullName -NotMatch '\\dist\\' -and $_.FullName -NotMatch '\\.vs\\' -and $_.FullName -NotMatch '\\.git\\'
    } 
}

# 获取项目文件-仅vue
function GetProjFilesOnlyVue {
    param (
        $path
    )
    return Get-ChildItem $path -Recurse -File | Where-Object {
        $_.FullName -Match '\\vue\\' -and $_.FullName -NotMatch '\\node_modules\\' -and $_.FullName -NotMatch '\\bin\\' -and $_.FullName -NotMatch '\\obj\\' -and $_.FullName -NotMatch '\\dist\\' -and $_.FullName -NotMatch '\\.vs\\' -and $_.FullName -NotMatch '\\.git\\'
    } 
}


# 是否为vue文件
function IsVueFile {
    param (
        [string]$path
    )

    foreach ($item in $vueFileEndsWith) {
        if ($path.EndsWith($item)) {
            return $true
        }
    }
    
    return $false
}
# 是否为cs文件
function IsCsFile {
    param (
        [string]$path
    )

    foreach ($item in $csFileEndsWith) {
        if ($path.EndsWith($item)) {
            return $true
        }
    }
    
    return $false
}