Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$helperPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\YoyoAbpMigrationStageKeep.ps1'
$engineConfigPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\engine_config.ps1'
$configRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config'

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

function Assert-SequenceEqual {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Expected,

        [Parameter(Mandatory = $true)]
        [string[]]$Actual,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    $difference = Compare-Object -ReferenceObject @($Expected) -DifferenceObject @($Actual)
    if ($difference) {
        $formattedDifference = $difference | ForEach-Object { "{0} {1}" -f $_.SideIndicator, $_.InputObject }
        throw "$Context does not match expected values:`n$($formattedDifference -join [Environment]::NewLine)"
    }
}

if (!(Test-Path -LiteralPath $helperPath)) {
    throw "Missing stage-keep helper: $helperPath"
}

if (!(Test-Path -LiteralPath $engineConfigPath)) {
    throw "Missing engine config helper: $engineConfigPath"
}

. $helperPath
. $engineConfigPath

$selection = Get-MigrationGenerationSelection -SourceRoot $repoRoot -ConfigRoot $configRoot
$stageKeepProjects = @($selection['stageKeepProjects'])
$candidateProjects = @(
    'Abp.AspNetCore.OpenIddict',
    'Abp.ZeroCore.OpenIddict',
    'Abp.ZeroCore.OpenIddict.EntityFrameworkCore',
    'Abp.EntityFrameworkCore.EFPlus',
    'Abp.ZeroCore.IdentityServer4.vNext',
    'Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4',
    'Abp.ZeroCore.IdentityServer4.EntityFrameworkCore'
)
$excludedProjects = @($candidateProjects | Where-Object { $stageKeepProjects -notcontains $_ })

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
$baselineRoot = Join-Path $tempRoot 'baseline'
$outputRoot = Join-Path $tempRoot 'output'
$solutionPath = $null

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

foreach ($projectName in $candidateProjects) {
    $projectDirectory = Join-Path $baselineRoot (Join-Path 'src' $projectName)
    New-Item -ItemType Directory -Path $projectDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $projectDirectory ($projectName + '.csproj')) -Encoding UTF8 -Value ("<Project Sdk=`"Microsoft.NET.Sdk`"><PropertyGroup><TargetFramework>{0}</TargetFramework></PropertyGroup></Project>" -f $selection['targetFramework'])
}

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
        -ProjectNames $stageKeepProjects

    foreach ($projectName in $stageKeepProjects) {
        Assert-True -Condition (Test-Path -LiteralPath (Join-Path $outputRoot (Join-Path 'src' (Join-Path $projectName ($projectName + '.csproj'))))) -Context ("Stage-keep helper did not restore {0}." -f $projectName)
    }

    foreach ($projectName in $excludedProjects) {
        Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $outputRoot (Join-Path 'src' (Join-Path $projectName ($projectName + '.csproj')))))) -Context ("Stage-keep helper should not restore {0}." -f $projectName)
    }

    $slnListOutput = (& dotnet sln $solutionPath list | Out-String)

    $solutionProjects = @(
        ($slnListOutput -split "`r?`n") |
            Where-Object { $_ -like 'src\*.csproj' } |
            ForEach-Object {
                $trimmedLine = $_.Trim()
                [System.IO.Path]::GetFileNameWithoutExtension($trimmedLine)
            } |
            Sort-Object -Unique
    )

    Assert-SequenceEqual -Expected $stageKeepProjects -Actual $solutionProjects -Context 'solution stage-keep project list'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host ("Stage-keep helper restores generation-aware auth projects for profile {0}." -f $selection['profile']) -ForegroundColor Green
