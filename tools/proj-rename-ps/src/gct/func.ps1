

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
    $fileDir = $fileDir -Replace [Regex]::Escape('52AbpDomainService'), 'GCTAbpDomainService'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoyoSoftPermissionNames'), 'GCTPermissionNames'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoMailKitSmtpBuilder'), 'GCTMailKitSmtpBuilder'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoDapperRepository'), 'GCTDapperRepository'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoABPEFCoreConsts'), 'GCTAbpEFCoreConsts'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoJwtSecurityTokenValidator'), 'GCTJwtSecurityTokenValidator'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoYoJwtSecurityTokenHandler'), 'GCTJwtSecurityTokenHandler'
    $fileDir = $fileDir -Replace [Regex]::Escape('YoyoCmsHealthCheck'), 'GCTHealthCheck'
    $fileDir = $fileDir -Replace [Regex]::Escape('yoyosoft'), 'gct'
    $fileDir = $fileDir -replace 'L52AbpPro', 'GCTAbpEx'
    $fileDir = $fileDir -replace 'L52Abp', 'GCTAbpEx'
    $fileDir = $fileDir -replace 'L.52AbpPro', 'GCT.AbpEx'
    $fileDir = $fileDir -replace 'L.52ABP', 'GCT.AbpEx'
    $fileDir = $fileDir -replace 'L.52Abp', 'GCT.AbpEx'
    $fileDir = $fileDir -replace 'Yoyo.Abp', 'GCT.AbpEx'
    $fileDir = $fileDir -replace 'Yoyo', 'GCT.AbpEx'
    $fileDir = $fileDir -replace '52AbpPro', 'GCTAbpEx'
    $fileDir = $fileDir -replace '52Abp', 'GCTAbpEx'

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