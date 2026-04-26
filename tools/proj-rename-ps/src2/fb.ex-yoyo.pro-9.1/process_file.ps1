# 复制且重命名
function Copy-Rename-Fb {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )

    # 创建输出目录（如果不存在）
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath | Out-Null
    }

    # 获取源路径下的所有文件和文件夹
    $items = Get-ChildItem -Path $SourcePath -Recurse

    foreach ($item in $items) {
        # 构造输出路径
        $newPath = $item.FullName.Replace($SourcePath, $OutputPath)
        $newPath = $newPath -creplace "Firebytes.Ex", "Yoyo.Pro"
        $newPath = $newPath -creplace "FirebytesEx", "YoyoPro"

        if ($item.PSIsContainer) {
            # 如果是文件夹，创建相应的文件夹
            New-Item -ItemType Directory -Path $newPath -Force | Out-Null
        }
        else {
            # 如果是文件，复制文件并修改文件名和文件内容
            Copy-Item -Path $item.FullName -Destination $newPath -Force


            # # 修改文件内容
            # $extension = $item.Extension.ToLower()
            # if ($extension -eq ".cs" -or $extension -eq ".cshtml" -or $extension -eq ".csproj" -or $extension -eq ".razor" -or $extension -eq ".config") {
            #     $content = Get-Content -Path $newPath -Raw

            #     $newContent = $content -creplace "Firebytes.Ex", "Yoyo.Pro"
            #     $newContent = $content -creplace "Firebytes.Shared", "YoyoBoot.Shared"
            #     $newContent = $content -creplace "Firebytes.Template", "YoyoBoot.Template"
            #     $newContent = $content -creplace "Firebytes", "YoyoBoot"

            #     Set-Content -Path $newPath -Value $newContent -Force
            #     Write-Host "Modified content of file: $newPath"
            # }
        }
    }
}

# 复制且重命名
function Copy-Rename-FbShared {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )

    # 创建输出目录（如果不存在）
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath | Out-Null
    }

    # 获取源路径下的所有文件和文件夹
    $items = Get-ChildItem -Path $SourcePath -Recurse

    foreach ($item in $items) {
        # 构造输出路径
        $newPath = $item.FullName.Replace($SourcePath, $OutputPath)
        $newPath = $newPath -creplace "Firebytes.Ex", "Yoyo.Pro"
        $newPath = $newPath -creplace "FirebytesEx", "YoyoPro"

        if ($item.PSIsContainer) {
            # 如果是文件夹，创建相应的文件夹
            New-Item -ItemType Directory -Path $newPath -Force | Out-Null
        }
        else {
            # 如果是文件，复制文件并修改文件名和文件内容
            Copy-Item -Path $item.FullName -Destination $newPath -Force


            # # 修改文件内容
            # $extension = $item.Extension.ToLower()
            # if ($extension -eq ".cs" -or $extension -eq ".cshtml" -or $extension -eq ".csproj" -or $extension -eq ".razor" -or $extension -eq ".config") {
            #     $content = Get-Content -Path $newPath -Raw

            #     $newContent = $content -creplace "Firebytes.Ex", "Yoyo.Pro"
            #     $newContent = $content -creplace "Firebytes.Shared", "YoyoBoot.Shared"
            #     $newContent = $content -creplace "Firebytes.Template", "YoyoBoot.Template"
            #     $newContent = $content -creplace "Firebytes", "YoyoBoot"

            #     Set-Content -Path $newPath -Value $newContent -Force
            #     Write-Host "Modified content of file: $newPath"
            # }
        }
    }
}