Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$helperPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\YoyoAbpMigrationStageKeep.ps1'

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    if (-not $Condition) {
        throw $Context
    }
}

if (!(Test-Path -LiteralPath $helperPath)) {
    throw "Missing stage-keep helper: $helperPath"
}

. $helperPath

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
$baselineRoot = Join-Path $tempRoot 'baseline'
$outputRoot = Join-Path $tempRoot 'output'
$solutionPath = $null

New-Item -ItemType Directory -Path (Join-Path $baselineRoot 'src\Abp.ZeroCore.IdentityServer4') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $baselineRoot 'src\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore') -Force | Out-Null
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

Set-Content -LiteralPath (Join-Path $baselineRoot 'src\Abp.ZeroCore.IdentityServer4\Abp.ZeroCore.IdentityServer4.csproj') -Encoding UTF8 -Value '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net6.0</TargetFramework></PropertyGroup></Project>'
Set-Content -LiteralPath (Join-Path $baselineRoot 'src\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore.csproj') -Encoding UTF8 -Value '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net6.0</TargetFramework></PropertyGroup></Project>'

try {
    Push-Location $outputRoot
    try {
        & dotnet new sln --name Abp --format sln | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet new sln failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }

    $solutionPath = (Get-ChildItem -LiteralPath $outputRoot -Filter '*.sln' | Select-Object -ExpandProperty FullName -First 1)
    if ([string]::IsNullOrWhiteSpace($solutionPath)) {
        throw 'dotnet new sln did not produce a solution file.'
    }

    Restore-YoyoAbpStageKeepProjects `
        -RepoRoot $baselineRoot `
        -OutputRoot $outputRoot `
        -ProjectNames @(
            'Abp.ZeroCore.IdentityServer4',
            'Abp.ZeroCore.IdentityServer4.EntityFrameworkCore'
        )

    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $outputRoot 'src\Abp.ZeroCore.IdentityServer4\Abp.ZeroCore.IdentityServer4.csproj')) -Context 'Stage-keep helper did not restore Abp.ZeroCore.IdentityServer4.'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $outputRoot 'src\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore.csproj')) -Context 'Stage-keep helper did not restore Abp.ZeroCore.IdentityServer4.EntityFrameworkCore.'

    $slnListOutput = (& dotnet sln $solutionPath list | Out-String)
    Assert-True -Condition $slnListOutput.Contains('src\Abp.ZeroCore.IdentityServer4\Abp.ZeroCore.IdentityServer4.csproj', [System.StringComparison]::Ordinal) -Context 'Solution file did not include Abp.ZeroCore.IdentityServer4.'
    Assert-True -Condition $slnListOutput.Contains('src\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore\Abp.ZeroCore.IdentityServer4.EntityFrameworkCore.csproj', [System.StringComparison]::Ordinal) -Context 'Solution file did not include Abp.ZeroCore.IdentityServer4.EntityFrameworkCore.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host 'Stage-keep helper restores auth projects into migration output.' -ForegroundColor Green
