Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$radarScriptPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\Invoke-YoyoAbpUpgradeRadar.ps1'
$versionMatrixPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config\version-generations.json'

function New-TempDirectory {
    $directoryPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $directoryPath -Force | Out-Null
    return $directoryPath
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

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
                throw "${Context} is missing required snippet '$Snippet'."
        }
}

function Assert-RadarReportForVersion {
        param(
                [Parameter(Mandatory = $true)]
                [string]$TempRoot,

                [Parameter(Mandatory = $true)]
                [string]$Version,

                [Parameter(Mandatory = $true)]
                [string]$ExpectedGeneration,

                [Parameter(Mandatory = $true)]
                [string]$ExpectedTargetFramework,

                [Parameter(Mandatory = $true)]
                [string]$SignalSnippet,

                [Parameter(Mandatory = $true)]
                [string]$RadarScriptPath,

                [Parameter(Mandatory = $true)]
                [string]$VersionMatrixPath
        )

        $fixtureName = $Version.Replace('.', '-')
        $currentRoot = Join-Path $TempRoot ("current-root-$fixtureName")
        $upstreamRoot = Join-Path $TempRoot ("upstream-root-$fixtureName")
        $outputPath = Join-Path $TempRoot ("upgrade-radar-$fixtureName.md")
        $versionTag = if ($Version.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) { $Version } else { 'v' + $Version }

        Write-Utf8File -Path (Join-Path $currentRoot 'common.props') -Content @"
<Project>
    <PropertyGroup>
        <Version>7.3.0</Version>
    </PropertyGroup>
</Project>
"@

        Write-Utf8File -Path (Join-Path $upstreamRoot 'common.props') -Content @"
<Project>
    <PropertyGroup>
        <Version>$Version</Version>
    </PropertyGroup>
</Project>
"@

        Write-Utf8File -Path (Join-Path $currentRoot 'src\Abp.ZeroCore.IdentityServer4\Abp.ZeroCore.IdentityServer4.csproj') -Content @"
<Project Sdk=\"Microsoft.NET.Sdk\">
    <PropertyGroup>
        <TargetFramework>net8.0</TargetFramework>
    </PropertyGroup>
</Project>
"@

        Write-Utf8File -Path (Join-Path $upstreamRoot 'src\Abp.AspNetCore.OpenIddict\Abp.AspNetCore.OpenIddict.csproj') -Content @"
<Project Sdk=\"Microsoft.NET.Sdk\">
    <PropertyGroup>
        <TargetFramework>$ExpectedTargetFramework</TargetFramework>
    </PropertyGroup>
    <ItemGroup>
        <PackageReference Include=\"OpenIddict.AspNetCore\" Version=\"5.8.0\" />
    </ItemGroup>
</Project>
"@

        & pwsh -NoLogo -NoProfile -File $RadarScriptPath `
                -UpstreamPath $upstreamRoot `
                -CurrentRoot $currentRoot `
                -VersionMatrixPath $VersionMatrixPath `
                -OutputPath $outputPath

        if ($LASTEXITCODE -ne 0) {
                throw "Upgrade radar script execution failed with exit code $LASTEXITCODE for upstream version $Version"
        }

        if (!(Test-Path -LiteralPath $outputPath)) {
                throw "Upgrade radar output was not created: $outputPath"
        }

        $reportContent = Get-Content -LiteralPath $outputPath -Raw -Encoding UTF8
        $context = "Upgrade radar report for $Version"

        Assert-Contains -Content $reportContent -Snippet "# Yoyo.Abp $versionTag Upgrade Radar" -Context $context
        Assert-Contains -Content $reportContent -Snippet "- Generation: ``$ExpectedGeneration``" -Context $context
        Assert-Contains -Content $reportContent -Snippet "- Expected target framework: ``$ExpectedTargetFramework``" -Context $context
        Assert-Contains -Content $reportContent -Snippet '- Abp.AspNetCore.OpenIddict' -Context $context
        Assert-Contains -Content $reportContent -Snippet $SignalSnippet -Context $context
}

if (!(Test-Path -LiteralPath $radarScriptPath)) {
    throw "Missing radar script: $radarScriptPath"
}

if (!(Test-Path -LiteralPath $versionMatrixPath)) {
    throw "Missing version generation matrix: $versionMatrixPath"
}

$versionMatrix = Get-Content -LiteralPath $versionMatrixPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
if (!($versionMatrix.ContainsKey('generations'))) {
    throw "Version generation matrix is missing 'generations': $versionMatrixPath"
}

$generationNames = @(
    $versionMatrix['generations'] |
        ForEach-Object { $_['name'] } |
        Where-Object { $_ } |
        Sort-Object -Unique
)

foreach ($requiredGeneration in @('v9-net8', 'v10-net9')) {
    if ($generationNames -notcontains $requiredGeneration) {
        throw "Version generation matrix is missing required generation '$requiredGeneration': $versionMatrixPath"
    }
}

$radarScriptContent = Get-Content -LiteralPath $radarScriptPath -Raw -Encoding UTF8
if ($radarScriptContent -notmatch 'Get-UpstreamGeneration') {
    throw "Radar script does not declare Get-UpstreamGeneration: $radarScriptPath"
}

$tempRoot = New-TempDirectory

try {
        Assert-RadarReportForVersion `
                -TempRoot $tempRoot `
                -Version '9.4.2' `
                -ExpectedGeneration 'v9-net8' `
                -ExpectedTargetFramework 'net8.0' `
                -SignalSnippet 'OpenIddict.AspNetCore' `
                -RadarScriptPath $radarScriptPath `
                -VersionMatrixPath $versionMatrixPath

        $customVersionMatrixPath = Join-Path $tempRoot 'version-generations.custom.json'
        Write-Utf8File -Path $customVersionMatrixPath -Content @'
{
    "defaultProfile": "custom-profile",
    "generations": [
        {
            "name": "v9-generic",
            "tagPrefixes": ["v9"],
            "targetFramework": "net8.0",
            "riskNotes": ["generic"]
        },
        {
            "name": "v9-net84-specific",
            "tagPrefixes": ["v9.4"],
            "targetFramework": "net8.4",
            "riskNotes": ["specific"]
        }
    ]
}
'@

        Assert-RadarReportForVersion `
                -TempRoot $tempRoot `
                -Version '9.4.2' `
                -ExpectedGeneration 'v9-net84-specific' `
                -ExpectedTargetFramework 'net8.4' `
                -SignalSnippet 'TargetFramework' `
                -RadarScriptPath $radarScriptPath `
                -VersionMatrixPath $customVersionMatrixPath

        Assert-RadarReportForVersion `
                -TempRoot $tempRoot `
                -Version '10.1.0' `
                -ExpectedGeneration 'v10-net9' `
                -ExpectedTargetFramework 'net9.0' `
                -SignalSnippet 'TargetFramework' `
                -RadarScriptPath $radarScriptPath `
                -VersionMatrixPath $versionMatrixPath
}
finally {
        if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
}

Write-Host 'Upgrade radar script and generation matrix cover v9/v10, including live report generation.' -ForegroundColor Green