# 处理文件内容
function NameProcessor {
    param (
        [string]$path
    )

    $files = GetProjFiles -Path $path
    foreach ($item in $files) {
        $path = $item.FullName

        CsBasicReplace -Path  $path
    }
}


# 替换cs文件中的基础信息
function CsBasicReplace {
    param (
        [string]$path
    )
    
    # 替换后端文件中的内容
    if (IsCsFile($path)) {
        # 读取文件内容
        $content = ReadFile -Path $path
    

        $content = $content -Replace [Regex]::Escape('Yoyo.Abp'), 'GCT.Abp'
        $content = $content -Replace [Regex]::Escape('yoyoboot'), 'GCT'
        $content = $content -Replace [Regex]::Escape('YoyoBoot'), 'GCT'
        $content = $content -Replace [Regex]::Escape('portal-runner'), 'gct_docker'


        # 写入内容到文件
        WriteFile -Path $path  -Content $content
    }

    
}


# L.52Abp-7.3
function NameProcessor2 {
    param (
        [string]$path
    )

    $files = GetProjFiles -Path $path
    foreach ($item in $files) {
        $path = $item.FullName

        CsBasicReplace2 -Path  $path
    }
}

# L.52Abp-7.3 替换cs文件中的基础信息
function CsBasicReplace2 {
    param (
        [string]$path
    )
    
    # 替换后端文件中的内容
    if (IsCsFile($path)) {
        # 读取文件内容
        $content = ReadFile -Path $path
    

        $content = $content -Replace [Regex]::Escape('<Authors>梁桐铭,staneee,huan</Authors>'), '<Authors>GCT</Authors>'
        $content = $content -Replace [Regex]::Escape('<Company>YoyoSoft</Company>'), '<Company>GCT</Company>'
        $content = $content -Replace [Regex]::Escape('<Product>52ABP-PRO</Product>'), '<Product>GCT</Product>'
        $content = $content -Replace [Regex]::Escape('https://github.com/52ABP/Yoyosoft-abp-modules'), 'https://git.gct-china.com/dev/foundation_group/gct.abp.extensions'
        $content = $content -Replace [Regex]::Escape('https://www.52abp.com/'), 'https://git.gct-china.com/dev/foundation_group/gct.abp.extensions'
        $content = $content -Replace [Regex]::Escape('© 52ABP.com'), '© gct-china.com'

        $content = $content -Replace [Regex]::Escape('portal-runner'), 'gct_docker'
        $content = $content -Replace [Regex]::Escape('yoyoboot.abp'), 'gct.abp'
        $content = $content -Replace [Regex]::Escape('yoyoboot'), 'GCT'
        $content = $content -Replace [Regex]::Escape('YoyoBoot'), 'GCT'
        $content = $content -Replace [Regex]::Escape('Yoyo.Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('Yoyo'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('L.52AbpPro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L._52AbpPro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L52AbpPro'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52AbpPro'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('L.52Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L._52Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L52Abp'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52ABP'), 'GCTAbpEx'

        if ($path.EndsWith('.sln') -or $path.EndsWith('.csproj')) {
            $content = $content -Replace [Regex]::Escape('GCTAbpEx'), 'GCT.AbpEx'
        }

        # 替换 import中的  GXXX 为 YXXX
        $matches = [Regex]::Matches($content, '<PackageReference Include="(GCT.*?)".*?"')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $newMatchVal = $matchVal -replace 'AbpEx', 'Abp'
            $content = $content -Replace $matchVal, $newMatchVal
        }

        $matches = [Regex]::Matches($content, '<Description>(.*?)</Description>')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $content = $content -Replace $matchVal, ''
        }

        $matches = [Regex]::Matches($content, '<Summary>(.*?)</Summary>')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $content = $content -Replace $matchVal, ''
        }


        # 写入内容到文件
        WriteFile -Path $path  -Content $content
    }

    
}


# Foundaiton 1.5
function NameProcessor3 {
    param (
        [string]$path
    )

    $files = GetProjFiles -Path $path
    foreach ($item in $files) {
        $path = $item.FullName

        CsBasicReplace3 -Path  $path
    }
}

# Foundaiton 1.5-替换cs文件中的基础信息
function CsBasicReplace3 {
    param (
        [string]$path
    )
    
    # 替换后端文件中的内容
    if (IsCsFile($path)) {
        # 读取文件内容
        $content = ReadFile -Path $path
        # 
        # ..\..\..\..\..\gct.abp.extensions\src\modules\GCT.AbpEx\GCT.AbpEx.csproj
        # ..\..\..\..\..\..\52abp\L.52ABP\src\modules\L.52Abp.Auditing.Mongo\L.52Abp.Auditing.Mongo.csproj


        # 引入的项目
        $content = $content -Replace [Regex]::Escape('..\..\..\..\..\..\52abp\L.52ABP'), '..\..\..\..\..\gct.abp.extensions'
        $content = $content -Replace [Regex]::Escape('..\..\..\..\52abp\L.52ABP'), '..\..\..\gct.abp.extensions'

        # 项目名称单独替换
        $matches = [Regex]::Matches($content, 'gct.abp.extensions.*?.csproj')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $newMatchVal = $matchVal
            $newMatchVal = $newMatchVal -replace 'L.52AbpPro', 'GCT.AbpEx'
            $newMatchVal = $newMatchVal -replace 'L.52Abp', 'GCT.AbpEx'
            $newMatchVal = $newMatchVal -replace 'Yoyo.Abp', 'GCT.AbpEx'
            $newMatchVal = $newMatchVal -replace 'Yoyo', 'GCT.AbpEx'
            $content = $content -Replace [Regex]::Escape($matchVal), $newMatchVal
        }

        # 项目名称单独替换
        $matches = [Regex]::Matches($content, 'PackageReference.*?\(L52abpVersion\)')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $newMatchVal = $matchVal
            $newMatchVal = $newMatchVal -replace 'L.52AbpPro', 'GCT.AbpEx'
            $newMatchVal = $newMatchVal -replace 'L.52Abp', 'GCT.AbpEx'
            $newMatchVal = $newMatchVal -replace 'Yoyo.Abp', 'GCT.AbpEx'
            $newMatchVal = $newMatchVal -replace 'Yoyo', 'GCT.AbpEx'
            $content = $content -Replace [Regex]::Escape($matchVal), $newMatchVal
        }

        $content = $content -Replace [Regex]::Escape('52AbpDomainService'), 'GCTAbpDomainService'
        $content = $content -Replace [Regex]::Escape('YoyoSoftPermissionNames'), 'GCTPermissionNames'
        $content = $content -Replace [Regex]::Escape('YoYoMailKitSmtpBuilder'), 'GCTMailKitSmtpBuilder'
        $content = $content -Replace [Regex]::Escape('YoYoDapperRepository'), 'GCTDapperRepository'
        $content = $content -Replace [Regex]::Escape('YoYoABPEFCoreConsts'), 'GCTAbpEFCoreConsts'
        $content = $content -Replace [Regex]::Escape('YoYoJwtSecurityTokenValidator'), 'GCTJwtSecurityTokenValidator'
        $content = $content -Replace [Regex]::Escape('YoYoJwtSecurityTokenHandler'), 'GCTJwtSecurityTokenHandler'
        $content = $content -Replace [Regex]::Escape('YoyoCmsHealthCheck'), 'GCTHealthCheck'
        
        $content = $content -Replace [Regex]::Escape('yoyosoft'), 'gct'
        $content = $content -Replace [Regex]::Escape('52abp.com'), 'gct-china.com'
        $content = $content -Replace [Regex]::Escape('52abp-pro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L52abpVersion'), 'GCTAbpExVersion'
        $content = $content -Replace [Regex]::Escape('L52AbpRefMode'), 'GCTAbpExRefMode'
        $content = $content -Replace [Regex]::Escape('L.52AbpPro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L.52Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('Yoyo.Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('Yoyo'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L._52AbpPro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L._52Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L52AbpPro'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52AbpPro'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('L52Abp'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52Abp'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('GCT.AbpEx.Castle.Log4Net'), 'GCT.Abp.Castle.Log4Net'
        $content = $content -Replace [Regex]::Escape('GCT.AbpEx.TestBase'), 'GCT.Abp.TestBase'
        $content = $content -Replace [Regex]::Escape('await GCT.AbpExAbpWechatMP'), 'await GCTAbpExAbpWechatMP'
        $content = $content -Replace [Regex]::Escape('services.AddGCT.AbpExAlipay'), 'services.AddGCTAbpExAlipay'
        $content = $content -Replace [Regex]::Escape('UseGCT.AbpExRedis'), 'UseGCTAbpExRedis'
        $content = $content -Replace [Regex]::Escape('AddGCT.AbpExSenparcCo2Net'), 'AddGCTAbpExSenparcCo2Net'
        $content = $content -Replace [Regex]::Escape('UseGCT.AbpExSenparcCO2NET'), 'UseGCTAbpExSenparcCO2NET'
        $content = $content -Replace [Regex]::Escape('UseGCT.AbpExSenparcWeixin'), 'UseGCTAbpExSenparcWeixin'
        


        # 替换正常的模块
        $matches = [Regex]::Matches($content, 'PackageReference.*?\(AbpVersion\)')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $newMatchVal = $matchVal -replace 'GCT.AbpEx', 'GCT.Abp'
            $content = $content -Replace [Regex]::Escape($matchVal), $newMatchVal
        }

        if ($path.EndsWith('.cs')) {
            $matches = [Regex]::Matches($content, 'typeof\(.*?Module')
            foreach ($match in $matches) {
                $matchVal = $match.Value
                $newMatchVal = $matchVal -replace 'GCT.AbpEx', 'GCTAbpEx'
                $content = $content -Replace [Regex]::Escape($matchVal), $newMatchVal
            }
        }



        # 写入内容到文件
        WriteFile -Path $path  -Content $content
    }

    
}



# L.52Abp-5.1
function NameProcessor4 {
    param (
        [string]$path
    )

    $files = GetProjFiles -Path $path
    foreach ($item in $files) {
        $path = $item.FullName

        CsBasicReplace4 -Path  $path
    }
}

# L.52Abp-5.1 替换cs文件中的基础信息
function CsBasicReplace4 {
    param (
        [string]$path
    )
    
    # 替换后端文件中的内容
    if (IsCsFile($path)) {
        # 读取文件内容
        $content = ReadFile -Path $path
    

        $content = $content -Replace [Regex]::Escape('<Authors>梁桐铭,staneee,huan</Authors>'), '<Authors>GCT</Authors>'
        $content = $content -Replace [Regex]::Escape('<Company>YoyoSoft</Company>'), '<Company>GCT</Company>'
        $content = $content -Replace [Regex]::Escape('<Product>52ABP-PRO</Product>'), '<Product>GCT</Product>'
        $content = $content -Replace [Regex]::Escape('https://github.com/52ABP/Yoyosoft-abp-modules'), 'https://git.gct-china.com/dev/foundation_group/gct.abp.extensions'
        $content = $content -Replace [Regex]::Escape('https://www.52abp.com/'), 'https://git.gct-china.com/dev/foundation_group/gct.abp.extensions'
        $content = $content -Replace [Regex]::Escape('© 52ABP.com'), '© gct-china.com'
        $content = $content -Replace [Regex]::Escape('<PackageLicenseExpression>MIT</PackageLicenseExpression>'), ''

        $content = $content -Replace [Regex]::Escape('portal-runner'), 'gct_docker'
        $content = $content -Replace [Regex]::Escape('yoyoboot.abp'), 'gct.abp'
        $content = $content -Replace [Regex]::Escape('yoyoboot'), 'GCT'
        $content = $content -Replace [Regex]::Escape('YoyoBoot'), 'GCT'
        $content = $content -Replace [Regex]::Escape('Yoyo.Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('Yoyo'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('L.52AbpPro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L._52AbpPro'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L52AbpPro'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52AbpPro'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('L.52Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L._52Abp'), 'GCT.AbpEx'
        $content = $content -Replace [Regex]::Escape('L52Abp'), 'GCTAbpEx'
        $content = $content -Replace [Regex]::Escape('52ABP'), 'GCTAbpEx'

        if ($path.EndsWith('.sln') -or $path.EndsWith('.csproj')) {
            $content = $content -Replace [Regex]::Escape('GCTAbpEx'), 'GCT.AbpEx'
        }

        # 替换 import中的  GXXX 为 YXXX
        $matches = [Regex]::Matches($content, '<PackageReference Include="(GCT.*?)".*?"')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $newMatchVal = $matchVal -replace 'AbpEx', 'Abp'
            $content = $content -Replace $matchVal, $newMatchVal
        }

        $matches = [Regex]::Matches($content, '<Description>(.*?)</Description>')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $content = $content -Replace $matchVal, ''
        }

        $matches = [Regex]::Matches($content, '<Summary>(.*?)</Summary>')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $content = $content -Replace $matchVal, ''
        }


        # 写入内容到文件
        WriteFile -Path $path  -Content $content
    }

    
}