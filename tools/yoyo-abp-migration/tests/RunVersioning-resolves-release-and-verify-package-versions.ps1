Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$helperPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\YoyoAbpVersioning.ps1'
$versionUpdatePath = Join-Path $repoRoot 'version-update.ps1'
$readVersionPath = Join-Path $repoRoot 'read-version.ps1'
$packPath = Join-Path $repoRoot 'nupkg\pack.ps1'
$buildPath = Join-Path $repoRoot 'build\Build.cs'

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Actual,

        [Parameter(Mandatory = $true)]
        [string]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    if (!($Actual.Equals($Expected, [System.StringComparison]::Ordinal))) {
        throw "$Context expected '$Expected' but got '$Actual'."
    }
}

if (!(Test-Path -LiteralPath $helperPath)) {
    throw "Missing versioning helper: $helperPath"
}

. $helperPath

$commonPropsPath = Join-Path $repoRoot 'common.props'
Assert-Equal -Actual (Get-YoyoAbpPackageVersion -BranchName 'release/7.4' -CommonPropsPath $commonPropsPath) -Expected '7.4.0' -Context 'release/7.4 package version'
Assert-Equal -Actual (Get-YoyoAbpPackageVersion -BranchName 'verify/7.4-yoyo-on-dev-7.3.0' -CommonPropsPath $commonPropsPath) -Expected '7.4.1' -Context 'verify/7.4 package version'
Assert-Equal -Actual (Get-YoyoAbpPackageVersion -BranchName 'release/9.4.2' -CommonPropsPath $commonPropsPath) -Expected '9.4.2' -Context 'release/9.4.2 package version'
Assert-Equal -Actual (Get-YoyoAbpPackageVersion -BranchName 'release/10.3' -CommonPropsPath $commonPropsPath) -Expected '10.3.0' -Context 'release/10.3 package version'
Assert-Equal -Actual (Get-YoyoAbpPackageVersion -ExplicitVersion '7.4.1' -CommonPropsPath $commonPropsPath) -Expected '7.4.1' -Context 'explicit package version override'

$tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDirectory -Force | Out-Null
$tempCommonPropsPath = Join-Path $tempDirectory 'common.props'

try {
    Set-Content -LiteralPath $tempCommonPropsPath -Encoding UTF8 -Value @"
<Project>
  <PropertyGroup>
    <Version>7.3.0</Version>
  </PropertyGroup>
</Project>
"@

    Assert-Equal -Actual (Get-CommonPropsVersion -CommonPropsPath $tempCommonPropsPath) -Expected '7.3.0' -Context 'common.props read'

    & pwsh -NoLogo -NoProfile -File $versionUpdatePath -Version '7.4.0' -CommonPropsPath $tempCommonPropsPath
    if ($LASTEXITCODE -ne 0) {
        throw "version-update.ps1 failed with exit code $LASTEXITCODE"
    }

    $readVersionOutput = (& pwsh -NoLogo -NoProfile -File $readVersionPath -CommonPropsPath $tempCommonPropsPath | Out-String).Trim()
    Assert-Equal -Actual $readVersionOutput -Expected '7.4.0' -Context 'read-version.ps1 output'
}
finally {
    if (Test-Path -LiteralPath $tempDirectory) {
        Remove-Item -LiteralPath $tempDirectory -Recurse -Force
    }
}

$packContent = Get-Content -LiteralPath $packPath -Raw -Encoding UTF8
if ($packContent -notmatch 'Get-YoyoAbpPackageVersion') {
    throw 'nupkg/pack.ps1 does not use the shared versioning helper.'
}

$buildContent = Get-Content -LiteralPath $buildPath -Raw -Encoding UTF8
if ($buildContent -notmatch 'PackageVersion') {
    throw 'build/Build.cs does not declare a PackageVersion parameter.'
}

if ($buildContent -notmatch 'SetVersion') {
    throw 'build/Build.cs does not wire PackageVersion into DotNetPack.'
}

Write-Host 'Versioning helper resolves release/verify package versions and wiring is in place.' -ForegroundColor Green
