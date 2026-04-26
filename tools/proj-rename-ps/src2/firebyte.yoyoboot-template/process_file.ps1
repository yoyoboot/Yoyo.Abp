# 复制且重命名
function Copy-Rename-AbpFiles {
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
        $newPath = $newPath -creplace "Firebytes", "Tempalte"
        $newPath = $newPath -creplace "firebytes", "tempalte"

        if ($item.PSIsContainer) {
            # 如果是文件夹，创建相应的文件夹
            New-Item -ItemType Directory -Path $newPath -Force | Out-Null
        }
        else {
            # 如果是文件，复制文件并修改文件名和文件内容
            Copy-Item -Path $item.FullName -Destination $newPath -Force


            # 修改文件内容
            $extension = $item.Extension.ToLower()
            if ($extension -eq ".cs" -or $extension -eq ".cshtml" -or $extension -eq ".csproj" -or $extension -eq ".razor" -or $extension -eq ".config") {
                $content = Get-Content -Path $newPath -Raw

                $newContent = $content -creplace "Yoyo.Abp", "Abp"
                
                $newContent = $newContent -creplace '<PackageTags>(.*?)</PackageTags>', '<PackageTags>Firebytes</PackageTags>'
                $newContent = $newContent -creplace '<Description>(.*?)</Description>', '<Description>Firebytes</Description>'
                $newContent = $newContent -creplace '<PackageIcon>(.*?)</PackageIcon>', ''
                $newContent = $newContent -creplace '<PackageIconUrl>(.*?)</PackageIconUrl>', ''
                $newContent = $newContent -creplace '<PackageLicenseFile>(.*?)</PackageLicenseFile>', ''
                $newContent = $newContent -creplace '<PackageProjectUrl>(.*?)</PackageProjectUrl>', ''
                $newContent = $newContent -creplace '<RepositoryUrl>(.*?)</RepositoryUrl>', ''
                $newContent = $newContent -creplace 'abp_nupkg.png', 'nupkg.png'

                $newContent = $newContent -creplace "Abp", "Firebytes"
                $newContent = $newContent -creplace "abp", "firebytes"
                $newContent = $newContent -creplace '"this-is-my-container-name-firebytesfirebytesfirebytesfirebytesfirebytesfirebytesfirebytesfirebytes-a-b-p-a-b"', '"this-is-my-container-name-firebytesfirebytesfirebytesfirebytes"'
                
                Set-Content -Path $newPath -Value $newContent -Force
                Write-Host "Modified content of file: $newPath"
            }
        }
    }
}

# 处理公共文件路径
function Copy-Rename-CommonFiles {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )

    $fileNames = @(
        'common.props',
        'configureawait.props',
        'global.json',
        'Abp.sln',
        'Delete-BIN-OBJ-Folders.bat',
        'NuGet.Config',
        ''
    )
    
    foreach ($fileName in $fileNames) {
        if ($fileName -eq '') {
            continue
        }

        $filePath = Join-Path $SourcePath $fileName
        $newPath = $filePath.Replace($SourcePath, $OutputPath)

        $newPath = $newPath -creplace "Abp", "Firebytes"
        $newPath = $newPath -creplace "abp", "firebytes"
        # 复制文件
        Copy-Item -Path $filePath -Destination $newPath -Force

        # 替换内容
        if ($newPath.EndsWith('.props') -or $newPath.EndsWith('.sln')) {
            $content = Get-Content -Path $newPath -Raw

            $newContent = $content -creplace "Yoyo.Abp", "Abp"
            
            $newContent = $newContent -creplace '<PackageTags>(.*?)</PackageTags>', '<PackageTags>Firebytes</PackageTags>'
            $newContent = $newContent -creplace '<Description>(.*?)</Description>', '<Description>Firebytes</Description>'
            $newContent = $newContent -creplace '<PackageIcon>(.*?)</PackageIcon>', ''
            $newContent = $newContent -creplace '<PackageIconUrl>(.*?)</PackageIconUrl>', ''
            $newContent = $newContent -creplace '<PackageLicenseFile>(.*?)</PackageLicenseFile>', ''
            $newContent = $newContent -creplace '<PackageProjectUrl>(.*?)</PackageProjectUrl>', ''
            $newContent = $newContent -creplace '<RepositoryUrl>(.*?)</RepositoryUrl>', ''
            $newContent = $newContent -creplace '<RepositoryType>(.*?)</RepositoryType>', ''
            $newContent = $newContent -creplace 'abp_nupkg.png', 'nupkg.png'

            $newContent = $newContent -creplace "Abp", "Firebytes"
            $newContent = $newContent -creplace "abp", "firebytes"


            Set-Content -Path $newPath -Value $newContent -Force
            Write-Host "Modified content of file: $newPath"
        }
    }

}