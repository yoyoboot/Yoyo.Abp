# 前端文件扩展名集合
$vueFileEndsWith = (
    ".vue",
    ".ts",
    ".tsx",
    ".less",
    ".json",
    ".nswag",
    ".ps1",
    ".env",
    ".npmrc",
    ".html"
)
# 前端文件扩展名集合
$csFileEndsWith = (
    ".cs",
    ".props",
    ".Config",
    ".config",
    ".yml",
    ".sln",
    ".csproj",
    ".cshtml",
    ".ps1",
    "Dockerfile",
    ".md",
    ".env",
    ".html",
    ".json"
)



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