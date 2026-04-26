
# 处理文件内容
function NameProcessor {
    param (
        [string]$path
    )

    $files = GetProjFiles -Path $path
    foreach ($item in $files) {
        $path = $item.FullName

        VueG2Y -Path  $path

        CsBasicReplace -Path  $path
    }
}

# 处理文件内容
function VuePackNameProcessor {
    param (
        [string]$path
    )

    $files = GetProjFiles -Path $path
    foreach ($item in $files) {
        $path = $item.FullName

        VuePackG2Y -Path $path

        VueG2Y -Path  $path

        CsBasicReplace -Path  $path
    }
}

# 打包重命名
function VuePackG2Y {
    param (
        [string]$path
    )
    
    if (IsVueFile($path)) {
        # 读取文件内容
        $content = ReadFile -Path $path

        # 链接
        $content = $content -Replace [Regex]::Escape('git+https://git.gct-china.com/dev/gct.ng.modules/gct-vue-abp-modules.git'), 'git+https://gitlab.com/basic-module-vue.git'
        $content = $content -Replace [Regex]::Escape('https://git.gct-china.com/dev/gct.ng.modules/gct-vue-abp-modules/-/issues'), 'https://gitlab.com/basic-module-vue'
        $content = $content -Replace [Regex]::Escape('"@delivery:registry": "https://git.gct-china.com/api/v4/projects/60/packages/npm/"'), '"@yoyoboot:registry": "https://registry.npmjs.org/"'
        $content = $content -Replace [Regex]::Escape('https://git.gct-china.com'), 'https://gitlab.com/basic-module-vue'
        $content = $content -Replace [Regex]::Escape('#--access public'), '--access public'

        # 内容

        $content = $content -Replace [Regex]::Escape('GctConfigInstance'), 'BasicConfigInstance'
        $content = $content -Replace [Regex]::Escape('GctConfig'), 'BasicConfig'
        $content = $content -Replace [Regex]::Escape('gct-config'), 'basic-config'
        $content = $content -Replace [Regex]::Escape('default as G'), 'default as Y'
        $content = $content -Replace [Regex]::Escape('@delivery/gct-vue-abp-modules'), '@yoyoboot/basic-module-vue'
        $content = $content -Replace [Regex]::Escape('gct-vue-abp-modules'), 'basic-module-vue'
        $content = $content -Replace [Regex]::Escape('GCT'), 'yoyoboot'
        $content = $content -Replace [Regex]::Escape('staneee'), 'yoyoboot'

        # 写入内容到文件
        WriteFile -Path $path  -Content $content        
    }

}

# g- to y-
function VueG2Y {
    param (
        [string]$path
    )
    
    # 替换前端文件中的内容, g->y 
    if (IsVueFile($path)) {
    
        # 读取文件内容
        $content = ReadFile -Path $path
            
        # 替换内容
        # $content = VueG2Y -Path  $path -Content $content
       
        # 替换 import 中的 g- 为 y-
        $content = $content -Replace [Regex]::Escape('/g-'), '/y-'
           
        # 替换 import中的  GXXX 为 YXXX
        $matches = [Regex]::Matches($content, [Regex]::Escape("(G.*?) .*?vue.*?"))
        foreach ($match in $matches) {
            if ($match.Success -and $match.Groups.Count -eq 2) {
                $oldVal = $match.Groups[1].Value.Trim()
                $newVal = 'Y' + $oldVal.Substring(1, $oldVal.Length - 1)
                $content = $content -Replace [Regex]::Escape($oldVal), $newVal
            }
        }
           
        # 替换 html tag 中的 <g- 为 <y- , </g- 为 </y-
        $content = $content -Replace [Regex]::Escape('<g-'), '<y-'
        $content = $content -Replace [Regex]::Escape('</g-') , '</y-'
                   
        # 替换 name 或class 中的 g- 为 y-
        $content = $content -Replace [Regex]::Escape('"g-'), '"y-'
        $content = $content -Replace [Regex]::Escape("'g-"), ("'y-")
           
        # 替换样式中的 .g- 为 .y-
        $content = $content -Replace [Regex]::Escape('.g-'), '.y-'

        # packages.json
        if ($path.EndsWith('package.json')) {
            # $content = $content -Replace '"@delivery/gct-vue-abp-modules".*?,', ''
        }
        # .npmrc
        if ($path.EndsWith('.npmrc')) {
            $content = ''
        }
        # account-layout.less
        if ($path.EndsWith('account-layout.less')) {
            $content = ''
        }
       
        # 从Foundation 到 YoyoBoot

        ## yml
        $content = $content -Replace [Regex]::Escape('hub.gct-china.com/staneee'), 'registry.cn-shanghai.aliyuncs.com/staneee'
        $content = $content -Replace [Regex]::Escape('Database=foundation'), 'Database=yoyoboot'
        $content = $content -Replace [Regex]::Escape('IMAGE_NAME: "gct_foundation"'), 'IMAGE_NAME: "yoyoboot"'
        $content = $content -Replace [Regex]::Escape('- local: ".gitlab/ci/module-nuget.tag-ci.yml"'), '#- local: ".gitlab/ci/module-nuget.tag-ci.yml"'
        $content = $content -Replace [Regex]::Escape('gct_docker'), 'portal-runner'
        $content = $content -Replace [Regex]::Escape('ftp_dev'), 'yoyoboot_dev'
        $content = $content -Replace [Regex]::Escape('CI_IMG_REGISTRY: $CI_REGISTRY_tencentyun'), 'CI_IMG_REGISTRY: $CI_REGISTRY_aliyun'
        $content = $content -Replace [Regex]::Escape('${CI_IMG_REGISTRY}/${IMAGE_NAME}'), '${CI_IMG_REGISTRY}/yoyosoft/${IMAGE_NAME}'
        
        ### yml 环境变量
        $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_user'), '$env:gitlab_pack_user'
        $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_token'), '$env:gitlab_pack_token'
        $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_nuget_source'), '$env:gitlab_pack_nuget'

        $content = $content -Replace [Regex]::Escape('$env:gct_nexus_nuget_path'), '$env:nexus_nuget'
        $content = $content -Replace [Regex]::Escape('$env:gct_nexus_nuget_token'), '$env:nexus_nuget_token'
        
        $content = $content -Replace [Regex]::Escape('$env:gct_npm_private_path'), '$env:nexus_npm'

        $content = $content -Replace [Regex]::Escape('$env:gct_nuget_config'), '$env:nexus_nuget_config'
        $content = $content -Replace [Regex]::Escape('$env:gct_npm_config'), '$env:nexus_npmrc_config'
        $content = $content -Replace [Regex]::Escape('$env:gct_dokcer_hub_config'), '$env:nexus_docker_config'

        ## 图标图片
        $content = $content -Replace [Regex]::Escape('/assets/images/2.png'), '/assets/images/logo-loading.svg'
        $content = $content -Replace [Regex]::Escape('/assets/images/logo.png'), '/assets/images/logo.svg'
        $content = $content -Replace [Regex]::Escape('/assets/images/logo.png'), '/assets/images/logo.svg'
        $content = $content -Replace [Regex]::Escape('/assets/images/gctlog2.png'), '/assets/images/logo.svg'

        ## .env
        $content = $content -Replace [Regex]::Escape('VITE_GLOB_APP_TITLE = "GCT Foundation"'), 'VITE_GLOB_APP_TITLE = "YoyoBoot"'
        $content = $content -Replace [Regex]::Escape('VITE_GLOB_APP_SHORT_NAME = GCT'), 'VITE_GLOB_APP_SHORT_NAME = YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCT Foundation'), 'YoyoBoot'
        

        ## icon
        $content = $content -Replace [Regex]::Escape('"name": "Gct_foundation",'), '"name": "yoyoboot",'
        $content = $content -Replace [Regex]::Escape('"font_family": "gcticons",'), '"font_family": "iconfont",'
        $content = $content -Replace [Regex]::Escape('"css_prefix_text": "gct",'), '"css_prefix_text": "yo-icon-",'
        $content = $content -Replace [Regex]::Escape('"description": "冠骋信息框架",'), '"description": "",'

        ## 多语言
        $content = $content -Replace [Regex]::Escape('"MedHub": "MedHub",'), ''
        $content = $content -Replace [Regex]::Escape('"MedPro": "MedPro",'), ''
        $content = $content -Replace [Regex]::Escape('"GctLowCode": "GCT-低代码",'), ''
        $content = $content -Replace [Regex]::Escape('GCT冠骋信息技术有限公司'), 'YoyoSoft'

        ## appsttings.json
        ### minio
        $content = $content -Replace [Regex]::Escape('"AccessKey": "medpro1",'), '"AccessKey": "账号",'
        $content = $content -Replace [Regex]::Escape('"SecretKey": "medpro1abcd",'), '"SecretKey": "密钥",'
        $content = $content -Replace [Regex]::Escape('"BucketName": "medpro1",'), '"BucketName": "存储桶",'
        ### mongo
        $content = $content -Replace [Regex]::Escape('GctMedProAuditLog'), 'AuditLog'
        $content = $content -Replace [Regex]::Escape('http://ftpapi.dev.gct-china.com'), 'http://localhost:6698'

        $content = $content -Replace [Regex]::Escape('pmo.dev.gct-china.com'), '(localdb)\\MSSQLLocalDB'
        $content = $content -Replace [Regex]::Escape('var keys = GetKeys(dt.Date, "gct");'), 'var keys = GetKeys(dt.Date, "yoyosoft");'
        $content = $content -Replace [Regex]::Escape('GCT-Foundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCT.Foundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCTFoundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('Foundation'), 'YoyoBoot'

        $content = $content -Replace [Regex]::Escape('#gct'), '#yo-icon-'
        $content = $content -Replace [Regex]::Escape('#gct-'), '#yo-icon-'
        $content = $content -Replace [Regex]::Escape('gct-'), 'yo-icon-'
        $content = $content -Replace [Regex]::Escape('"icon": "gct'), '"icon": "yo-icon-'
        $content = $content -Replace [Regex]::Escape('gct_'), ''
        $content = $content -Replace [Regex]::Escape('gct'), 'yo-icon-'        
        $content = $content -Replace [Regex]::Escape('GCT.'), ''              
        $content = $content -Replace [Regex]::Escape('GCT'), ''
        $content = $content -Replace [Regex]::Escape('Gct'), ''
        $content = $content -Replace [Regex]::Escape('MedPro'), ''
        $content = $content -Replace [Regex]::Escape('medpro'), ''
        $content = $content -Replace [Regex]::Escape('@delivery/gct-vue-abp-modules'), '@yoyoboot/basic-module-vue'
                 
        # 写入内容到文件
        WriteFile -Path $path  -Content $content
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

        ## yml
        $content = $content -Replace [Regex]::Escape('hub.gct-china.com/staneee'), 'registry.cn-shanghai.aliyuncs.com/staneee'
        $content = $content -Replace [Regex]::Escape('Database=gct_foundation'), 'Database=yoyoboot'
        $content = $content -Replace [Regex]::Escape('IMAGE_NAME: "gct_foundation"'), 'IMAGE_NAME: "yoyoboot"'
        $content = $content -Replace [Regex]::Escape('- local: ".gitlab/ci/module-nuget.tag-ci.yml"'), '#- local: ".gitlab/ci/module-nuget.tag-ci.yml"'
        $content = $content -Replace [Regex]::Escape('gct_docker'), 'portal-runner'
        $content = $content -Replace [Regex]::Escape('ftp_dev'), 'yoyoboot_dev'
        $content = $content -Replace [Regex]::Escape('CI_IMG_REGISTRY: $CI_REGISTRY_tencentyun'), 'CI_IMG_REGISTRY: $CI_REGISTRY_aliyun'
        $content = $content -Replace [Regex]::Escape('${CI_IMG_REGISTRY}/${IMAGE_NAME}'), '${CI_IMG_REGISTRY}/yoyosoft/${IMAGE_NAME}'


        ### yml 环境变量
        $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_user'), '$env:gitlab_pack_user'
        $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_token'), '$env:gitlab_pack_token'
        $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_nuget_source'), '$env:gitlab_pack_nuget'

        $content = $content -Replace [Regex]::Escape('$env:gct_nexus_nuget_path'), '$env:nexus_nuget'
        $content = $content -Replace [Regex]::Escape('$env:gct_nexus_nuget_token'), '$env:nexus_nuget_token'
        
        $content = $content -Replace [Regex]::Escape('$env:gct_npm_private_path'), '$env:nexus_npm'

        $content = $content -Replace [Regex]::Escape('$env:gct_nuget_config'), '$env:nexus_nuget_config'
        $content = $content -Replace [Regex]::Escape('$env:gct_npm_config'), '$env:nexus_npmrc_config'
        $content = $content -Replace [Regex]::Escape('$env:gct_dokcer_hub_config'), '$env:nexus_docker_config'





        ## .env
        $content = $content -Replace [Regex]::Escape('VITE_GLOB_APP_TITLE = "GCT Foundation"'), 'VITE_GLOB_APP_TITLE = "YoyoBoot"'
        $content = $content -Replace [Regex]::Escape('VITE_GLOB_APP_SHORT_NAME = GCT'), 'VITE_GLOB_APP_SHORT_NAME = YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCT Foundation'), 'YoyoBoot'
        

        ## icon
        $content = $content -Replace [Regex]::Escape('"name": "Gct_foundation",'), '"name": "yoyoboot",'
        $content = $content -Replace [Regex]::Escape('"font_family": "gcticons",'), '"font_family": "iconfont",'
        $content = $content -Replace [Regex]::Escape('"css_prefix_text": "gct",'), '"css_prefix_text": "yo-icon-",'
        $content = $content -Replace [Regex]::Escape('"description": "冠骋信息框架",'), '"description": "",'

        ## 多语言
        $content = $content -Replace [Regex]::Escape('"MedHub": "MedHub",'), ''
        $content = $content -Replace [Regex]::Escape('"MedPro": "MedPro",'), ''
        $content = $content -Replace [Regex]::Escape('"GctLowCode": "GCT-低代码",'), ''
        $content = $content -Replace [Regex]::Escape('GCT冠骋信息技术有限公司'), 'YoyoSoft'

        ## appsttings.json
        ### minio
        $content = $content -Replace [Regex]::Escape('"AccessKey": "medpro1",'), '"AccessKey": "账号",'
        $content = $content -Replace [Regex]::Escape('"SecretKey": "medpro1abcd",'), '"SecretKey": "密钥",'
        $content = $content -Replace [Regex]::Escape('"BucketName": "medpro1",'), '"BucketName": "存储桶",'
        ### mongo
        $content = $content -Replace [Regex]::Escape('GctMedProAuditLog'), 'AuditLog'
        $content = $content -Replace [Regex]::Escape('http://ftpapi.dev.gct-china.com'), 'http://localhost:6698'

        $content = $content -Replace [Regex]::Escape('pmo.dev.gct-china.com'), '(localdb)\\MSSQLLocalDB'
        $content = $content -Replace [Regex]::Escape('var keys = GetKeys(dt.Date, "gct");'), 'var keys = GetKeys(dt.Date, "yoyosoft");'
        $content = $content -Replace [Regex]::Escape('GCT-Foundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCT.Foundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('GCTFoundation'), 'YoyoBoot'
        $content = $content -Replace [Regex]::Escape('Foundation'), 'YoyoBoot'

        $content = $content -Replace [Regex]::Escape('#gct'), '#yo-icon-'
        $content = $content -Replace [Regex]::Escape('#gct-'), '#yo-icon-'
        $content = $content -Replace [Regex]::Escape('gct-'), 'yo-icon-'
        $content = $content -Replace [Regex]::Escape('"icon": "gct'), '"icon": "yo-icon-'
        $content = $content -Replace [Regex]::Escape('gct_'), ''
        $content = $content -Replace [Regex]::Escape('gct'), 'yo-icon-'        
        $content = $content -Replace [Regex]::Escape('GCT.'), ''              
        $content = $content -Replace [Regex]::Escape('GCT'), ''
        $content = $content -Replace [Regex]::Escape('Gct'), ''
        $content = $content -Replace [Regex]::Escape('MedPro'), ''
        $content = $content -Replace [Regex]::Escape('medpro'), ''
        # $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_user'), '$env:private_source'
        # $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_user'), '$env:private_source_user'
        # $content = $content -Replace [Regex]::Escape('$env:gitlab_gct_pack_token'), '$env:private_source_token'



        # 移除冗余的值
        if ($path.EndsWith('.ps1')) {
            $content = $content -Replace [Regex]::Escape('.Web.Core",'), '.Web.Core"'
            $content = $content -Replace [Regex]::Escape('"GCT.Shared.Application",'), ''
            $content = $content -Replace [Regex]::Escape('"GCT.Shared.Core",'), ''
            $content = $content -Replace [Regex]::Escape('"GCT.Shared.EntityFrameworkCore",'), ''
            $content = $content -Replace [Regex]::Escape('"GCT.Shared.Web.Core"'), ''
        }

        # 清空文件中的内容
        if ($path.EndsWith('pre_config.ps1')) {
            # $content = ''
        }

        # 替换 NuGet.Config 中的内容
        elseif ($path.EndsWith('NuGet.Config')) {
            $content = '<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <!-- 私有源 -->
        <!--<add key="private_source" value="" />-->
    </packageSources>
    <packageSourceCredentials>
        <!-- 私有源 - 认证信息 -->
        <!--<private_source>
            <add key="username" value="" />
            <add key="cleartextpassword" value="" />
        </private_source>-->
    </packageSourceCredentials>
</configuration>
'
        }

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
        'src\aspnet-core\src\GCT.Shared.Application',
        'src\aspnet-core\src\GCT.Shared.Core',
        'src\aspnet-core\src\GCT.Shared.EntityFrameworkCore',
        'src\aspnet-core\src\GCT.Shared.Web.Core',
        'src\aspnet-core\YoyoBoot.Packs.sln',
        'src\aspnet-core\YoyoBoot.SourceLink.sln',
        'src\aspnet-core\YoyoBoot.SourceLink.MedPro.sln',
        'src\aspnet-core\YoyoBoot.SourceLink.LowCode.sln',
        'src\aspnet-core\YoyoBoot.SourceLink.Template.sln',
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
