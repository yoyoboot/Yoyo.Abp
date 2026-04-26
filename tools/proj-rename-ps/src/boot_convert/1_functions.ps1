
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

        # 从Foundation 到 YoyoBoot

        $content = $content -Replace [Regex]::Escape('gct.abp.extensions'), 'yoyo.pro'
        $content = $content -Replace [Regex]::Escape('GCT.Foundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCTFoundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('Foundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCT.AbpEx'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('GCTAbpExRefMode'), 'YoyoProRefMode'
        $content = $content -Replace [Regex]::Escape('GCTAbpExVersion'), 'YoyoProVersion'
        $content = $content -Replace [Regex]::Escape('GCTAbpEx'), 'YoyoPro'        
        $content = $content -Replace [Regex]::Escape('GCT.Abp'), 'Yoyo.Abp'
        $content = $content -Replace [Regex]::Escape('IGCTAbp'), 'IYoyo'
        $content = $content -Replace [Regex]::Escape('GCTPermissionNames'), 'AppProPermissionNames'
        $content = $content -Replace [Regex]::Escape('YoyoProAbp'), 'YoyoPro'
        $content = $content -Replace [Regex]::Escape('GCT-YoyoBoot'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCTAbpExTemplate'), 'YoyoBootTemplate'
        $content = $content -Replace [Regex]::Escape('GCTAbpExTemplate'), 'YoyoBootTemplate'
        $content = $content -Replace [Regex]::Escape('GCTMedPro'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCTYoyoBoot'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCT冠骋信息技术有限公司'), '技术平台'
        $content = $content -Replace [Regex]::Escape('"MedPro": "MedPro",'), ''
        $content = $content -Replace [Regex]::Escape('"GctLowCode": "GCT-LowCode",'), ''
        $content = $content -Replace [Regex]::Escape('"MedHub": "MedHub",'), ''
        $content = $content -Replace [Regex]::Escape('GCT'), 'AppPro'
        $content = $content -Replace [Regex]::Escape('MedPro'), ''


        # $content = $content -Replace [Regex]::Escape('GCTMailKitSmtpBuilder'), 'AppProMailKitSmtpBuilder'
        # $content = $content -Replace [Regex]::Escape('GCTDapperRepository'), 'AppProDapperRepository'

        # $content = $content -Replace [Regex]::Escape('YoyoProAlipayModule'), 'YoyoProAlipayModule'
        # $content = $content -Replace [Regex]::Escape('YoyoProAbpAliyunVodModule'), 'YoyoProAliyunVodModule'
        # $content = $content -Replace [Regex]::Escape('YoyoProAbpWechatMP'), 'YoyoProWechatMP'
        # $content = $content -Replace [Regex]::Escape('YoyoProAbpRedisCacheModule'), 'YoyoProRedisCacheModule'
        # $content = $content -Replace [Regex]::Escape('YoyoProSenparc'), 'YoYoSenparc'
        # $content = $content -Replace [Regex]::Escape('UseYoyoProRedis'), 'UseYoyoRedis'
        # $content = $content -Replace [Regex]::Escape('AddYoyoProAlipay'), 'AddYoYoAlipay'

       

        # YoYoAlipayConsts              YoyoProAlipayConsts
        # AddYoYoAlipay                 AddYoyoProAlipay
        # YoYoAlipayExtension           YoyoProAlipayExtension
        # AddYoYoSenparc                AddYoyoProSenparc
        # AddYoYoSenparcCo2Net          AddYoyoProSenparcCo2Net
        # AddYoYoSenparcWeixin          AddYoyoProSenparcWeixin
        # UseYoYoSenparcCO2NET          UseYoyoProSenparcCO2NET
        # UseYoYoSenparcCO2NETGlobalCache   UseYoyoProSenparcCO2NETGlobalCache
        # UseYoYoSenparcMpAccount       UseYoyoProSenparcMpAccount
        # UseYoYoSenparcMpJsApiTicket   UseYoyoProSenparcMpJsApiTicket
        # UseYoYoSenparcOpenComponent   UseYoyoProSenparcOpenComponent
        # UseYoYoSenparcTenpayV2        UseYoyoProSenparcTenpayV2
        # UseYoYoSenparcTenpayV3        UseYoyoProSenparcTenpayV3
        # UseYoYoSenparcWorkAccount     UseYoyoProSenparcWorkAccount
        # UseYoYoSenparcWxOpenAccount   UseYoyoProSenparcWxOpenAccount
        # UseYoyoRedis                  UseYoyoProRedis
        # YoYoAlipayModule              YoyoProAlipayModule
        # YoyoAbpAliyunVodModule        YoyoProAliyunVodModule

      
        # # 替换 import中的  GXXX 为 YXXX
        # $matches = [Regex]::Matches($content, "(G.*?) .*?vue")
        # foreach ($match in $matches) {
        #     $oldVal = $match.Groups[1].Value.Trim()
        #     $newVal = 'Y' + $oldVal.Substring(1, $oldVal.Length - 1)
        #     $content = $content -Replace $oldVal, $newVal
        # }


        # 写入内容到文件
        WriteFile -Path $path  -Content $content
    }

}


# 删除 shared 模块
function DelShared {
    param (
        $rootPath
    )

    # 删除的文件和目录
    $removeItems = (
        'src\AppPro.Shared.Application',
        'src\AppPro.Shared.Core',
        'src\AppPro.Shared.EntityFrameworkCore',
        'src\AppPro.Shared.Web.Core',
        'src\YoyoBoot.Web.Host\logs',
        'YoyoBoot.Packs.sln',
        'YoyoBoot.SourceLink.sln',
        'YoyoBoot.SourceLink.MedPro.sln',
        'YoyoBoot.SourceLink.LowCode.sln',
        'YoyoBoot.SourceLink.Template.sln',
        'src\vue\src\assets\images\2.png',
        'src\vue\src\assets\images\gctlog.png',
        'src\vue\src\assets\images\gctlog2.png',
        'src\vue\src\assets\images\logo.png'
    )
    foreach ($item in $removeItems) {
        $path2 = [System.IO.Path]::Join($rootPath, $item)
        if ((Test-Path $path2)) {
            Remove-Item -Force -Recurse -Path $path2
        }
    }
}

# 生成图标
function GenLogo {
    param (
        $rootPath
    )

    # 删除的文件和目录
    $sourceItems = (
        'src\vue\src\assets\images\logos\logo-color-shield.svg',
        'src\vue\src\assets\images\logos\logo-txt-color-shield.svg'
    )
    $targetItems = (
        'src\vue\src\assets\images\logo.svg',
        'src\vue\src\assets\images\logo-loading.svg'
    )

    $counter = 0
    foreach ($item in $sourceItems) {
        $sourcePath = [System.IO.Path]::Join($rootPath, $item)
        $targetPath = [System.IO.Path]::Join($rootPath, $targetItems[$counter++])

        Copy-Item $sourcePath -Destination $targetPath -Force
    }
}


# 删除 CI 模块
function DelCI {
    param (
        $rootPath
    )

    # 删除的文件和目录
    $removeItems = (
        '.gitlab',
        'build',
        'docker',
        '.gitlab-ci.yml'
    )
    foreach ($item in $removeItems) {
        $path2 = [System.IO.Path]::Join($rootPath, $item)
        if ((Test-Path $path2)) {
            Remove-Item -Force -Recurse -Path $path2
        }
    }
}
