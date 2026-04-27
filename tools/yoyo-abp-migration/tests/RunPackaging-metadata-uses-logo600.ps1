Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$commonPropsPath = Join-Path $repoRoot 'common.props'

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Snippet,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    if (!$Content.Contains($Snippet, [System.StringComparison]::Ordinal)) {
        throw "$Context is missing required snippet '$Snippet'."
    }
}

function Assert-NotContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Snippet,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    if ($Content.Contains($Snippet, [System.StringComparison]::Ordinal)) {
        throw "$Context still contains forbidden snippet '$Snippet'."
    }
}

if (!(Test-Path -LiteralPath $commonPropsPath)) {
    throw "Missing common.props: $commonPropsPath"
}

$content = Get-Content -LiteralPath $commonPropsPath -Raw -Encoding UTF8
Assert-Contains -Content $content -Snippet '<PackageIcon>logo_600.png</PackageIcon>' -Context 'common.props package icon metadata'
Assert-Contains -Content $content -Snippet '<None Include="../../nupkg/logo_600.png" Pack="true" PackagePath="/"/>' -Context 'common.props packed icon file'
Assert-Contains -Content $content -Snippet '<PackageProjectUrl>https://github.com/yoyoboot/Yoyo.Abp</PackageProjectUrl>' -Context 'common.props package project url metadata'
Assert-Contains -Content $content -Snippet '<RepositoryUrl>https://github.com/yoyoboot/Yoyo.Abp</RepositoryUrl>' -Context 'common.props repository url metadata'
Assert-NotContains -Content $content -Snippet 'abp_nupkg.png' -Context 'common.props legacy icon metadata'
Assert-NotContains -Content $content -Snippet 'http://www.aspnetboilerplate.com/' -Context 'common.props legacy package project url metadata'
Assert-NotContains -Content $content -Snippet 'https://github.com/aspnetboilerplate/aspnetboilerplate' -Context 'common.props legacy repository url metadata'

Write-Host 'Packaging metadata points to logo_600.png and yoyoboot GitHub URLs.' -ForegroundColor Green
