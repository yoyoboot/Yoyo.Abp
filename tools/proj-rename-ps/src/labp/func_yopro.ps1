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
    

        $content = $content -Replace [Regex]::Escape('<Authors>梁桐铭,staneee,huan</Authors>'), '<Authors>YoyoBoot</Authors>'
        $content = $content -Replace [Regex]::Escape('<Company>YoyoSoft</Company>'), '<Company>YoyoBoot</Company>'
        $content = $content -Replace [Regex]::Escape('<Product>52ABP-PRO</Product>'), '<Product>YoyoBoot</Product>'
        $content = $content -Replace [Regex]::Escape('https://github.com/52ABP/Yoyosoft-abp-modules'), 'https://github.com/yoyoboot'
        $content = $content -Replace [Regex]::Escape('https://www.52abp.com/'), 'https://github.com/yoyoboot'
        $content = $content -Replace [Regex]::Escape('© 52ABP.com'), '© https://github.com/yoyoboot'

        $content = $content -Replace [Regex]::Escape('Yoyo.DbStore'), 'Yoyo.Pro.DbStore'
        $content = $content -Replace [Regex]::Escape('Yoyo.Abp'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('YoyoAbp'), 'YoyoPro'
        # $content = $content -Replace [Regex]::Escape('YoYoAlipay'), 'YoyoProAlipay'
        # $content = $content -Replace [Regex]::Escape('Yoyo'), 'Yoyo.Pro'
        # $content = $content -Replace [Regex]::Escape('Yoyo.Pro.Pro'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('L.52AbpPro'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('L._52AbpPro'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('L52AbpPro'), 'YoyoPro'
        $content = $content -Replace [Regex]::Escape('52AbpPro'), 'YoyoPro'
        $content = $content -Replace [Regex]::Escape('L.52Abp'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('L._52Abp'), 'Yoyo.Pro'
        $content = $content -Replace [Regex]::Escape('L52Abp'), 'YoyoPro'
        $content = $content -Replace [Regex]::Escape('52ABP'), 'YoyoPro'

        # if ($path.EndsWith('.sln') -or $path.EndsWith('.csproj')) {
        #     $content = $content -Replace [Regex]::Escape('YoyoPro'), 'Yoyo.Pro'
        # }

        # 替换 import中的  GXXX 为 YXXX
        $matches = [Regex]::Matches($content, '<PackageReference Include="(Yoyo.Pro.*?)".*?"')
        foreach ($match in $matches) {
            $matchVal = $match.Value
            $newMatchVal = $matchVal -replace 'Yoyo.Pro', 'Yoyo.Abp'
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

