[CmdletBinding()]
param(
    [string]$Version,

    [string]$BranchName,

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $repoRoot 'tools\yoyo-abp-migration\YoyoAbpVersioning.ps1')

$explicitVersion = $Version
$isProduction = $false
if (!([string]::IsNullOrWhiteSpace($env:IS_PRODUCTION))) {
    $isProduction = [System.Convert]::ToBoolean($env:IS_PRODUCTION)
}

if ([string]::IsNullOrWhiteSpace($explicitVersion) -and $isProduction -and (Test-YoyoAbpVersionText -VersionText $env:TAG)) {
    $explicitVersion = $env:TAG
}

$resolvedVersion = Get-YoyoAbpPackageVersion `
    -ExplicitVersion $explicitVersion `
    -BranchName $BranchName `
    -CommonPropsPath (Join-Path $repoRoot 'common.props')

Write-Host "Resolved package version: $resolvedVersion" -ForegroundColor Blue
Write-Host "IS_PRODUCTION: $isProduction" -ForegroundColor Blue

# Paths
$packFolder = [System.IO.Path]::GetFullPath($PSScriptRoot)
$distPath = Join-Path $packFolder "dist"
$slnPath = [System.IO.Path]::GetFullPath((Join-Path $packFolder '..'))
$srcPath = Join-Path $slnPath "src"

Write-Host "Pack folder: $packFolder" -ForegroundColor Blue
Write-Host "Solution root: $slnPath" -ForegroundColor Blue
Write-Host "Dist path: $distPath" -ForegroundColor Blue

# List of projects
$projects = (
    "Abp",
    "Abp.AspNetCore",
    "Abp.AspNetCore.OData",
    "Abp.AspNetCore.SignalR",
    "Abp.AspNetCore.TestBase",
    "Abp.AspNetCore.PerRequestRedisCache",
    "Abp.AutoMapper",
    "Abp.Castle.Log4Net",
    "Abp.Dapper",
    "Abp.EntityFramework",
    "Abp.EntityFramework.Common",
    "Abp.EntityFrameworkCore",
    "Abp.EntityFrameworkCore.EFPlus",
    "Abp.FluentValidation",
    "Abp.HangFire",
    "Abp.HangFire.AspNetCore",
    "Abp.MailKit",
    "Abp.MemoryDb",
    "Abp.MongoDB",
    "Abp.RedisCache",
    "Abp.RedisCache.ProtoBuf",
    "Abp.Quartz",
    "Abp.TestBase",
    "Abp.Web.Common",
    "Abp.Zero.Common",
    "Abp.Zero.Ldap",
    "Abp.ZeroCore",
    "Abp.ZeroCore.EntityFramework",
    "Abp.ZeroCore.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4",
    "Abp.ZeroCore.IdentityServer4.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4.vNext",
    "Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore"
)

if ($WhatIf) {
    Write-Host 'WhatIf: pack plan rendered only; restore/publish/pack were not executed.' -ForegroundColor Yellow
    Set-Location $packFolder
    return
}

# Rebuild solution
Set-Location $slnPath
& dotnet restore --ignore-failed-sources

# Copy all nuget packages to the pack folder
$packageCounter = 0
foreach ($project in $projects) {

    ## path
    $projectFolder = Join-Path $srcPath $project
    $csprojFile = Join-Path $projectFolder ($project + '.csproj')
    if (!(Test-Path $csprojFile)) {
        continue
    }

    # Create nuget pack
    Set-Location $projectFolder
    & dotnet publish --no-restore -c Release
    & dotnet pack --no-restore `
        -c Release `
        -o $distPath `
        -p:IncludeSymbols=true `
        -p:SymbolPackageFormat=snupkg `
        -p:Version=${resolvedVersion}

    $packageCounter += 1
}

Write-Host ('package count: ' + $packageCounter )

# Go back to the pack folder
Set-Location $packFolder