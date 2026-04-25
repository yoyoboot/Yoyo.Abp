

## 处理测试库中的demos
function RunTestDemos {
    param (
        $rootPath,
        $projNames
    )

    Remove-Item -Force -Recurse -Path "$rootPath"
    
    return

    foreach ($projName in $projNames) {

        Write-Host ("正在处理: $projName")
    
        $inputRootPath = $rootPath + $projName

        # 获取项目文件遍历
        $files = GetProjFiles -Path $inputRootPath
        foreach ($item in $files) {
            if ($item.FullName.EndsWith('.js')) {
                ReplaceTestDemosJs -Path $item.FullName
                continue
            }

            if (!$item.FullName.EndsWith('.cs') -and !$item.FullName.EndsWith('.sql')) {
                continue
            }
            ReplaceTestDemos -Path $item.FullName
        }
    }
}

## 处理测试库中的demos
function ReplaceTestDemos {
    param (
        [string]$path
    )

    if (![regex]::IsMatch($path, [Regex]::Escape('aspnet-core-demo'))) {
        return
    }

    # 读取文件内容
    $content = ReadFile -Path $path

    ## ApplicationWithoutDb_Tests.cs Validation_Tests.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('MyDbContext.cs')) -or [regex]::IsMatch($path, [Regex]::Escape('ProductAppService.cs')) -or [regex]::IsMatch($path, [Regex]::Escape('TestAppService.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('int CreateProduct('), 'string CreateProduct('
        $content = $content -creplace [Regex]::Escape('Id = 1'), 'Id = "1"'
        $content = $content -creplace [Regex]::Escape('Id = 42,'), 'Id = "42",'
    }




    $content = $content -creplace [Regex]::Escape('__abp'), '__wrapper'

    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}

function ReplaceTestDemosJs {
    param (
        [string]$path
    )
    
    # 读取文件内容
    $content = ReadFile -Path $path

    ## ApplicationWithoutDb_Tests.cs Validation_Tests.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('abp.ng.js')) -or [regex]::IsMatch($path, [Regex]::Escape('abp.jquery.js')) 
    ) {
        $content = $content -creplace [Regex]::Escape('__abp'), '__wrapper'
    }


    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}