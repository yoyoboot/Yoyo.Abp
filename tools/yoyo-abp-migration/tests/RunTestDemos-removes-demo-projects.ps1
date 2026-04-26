Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$engineRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3'

Push-Location $engineRoot
try {
    . .\common.ps1
    . .\process_test_demo.ps1
}
finally {
    Pop-Location
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("yoyo-runtestdemos-" + [guid]::NewGuid().ToString('N'))
$srcRoot = Join-Path $tempRoot 'src'
$testRoot = Join-Path $srcRoot 'test'
$demoRoot = Join-Path $testRoot 'aspnet-core-demo'
$solutionPath = Join-Path $srcRoot 'Abp.sln'

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

try {
    New-Item -ItemType Directory -Force -Path $demoRoot | Out-Null
    Push-Location $srcRoot
    try {
        dotnet new sln --name Abp --format sln | Out-Null
        Assert-True (Test-Path $solutionPath) 'Expected dotnet new sln to create Abp.sln test fixture.'

        $projects = @(
            @{ Folder = 'Keep.Project'; Name = 'Keep.Project' },
            @{ Folder = 'test\aspnet-core-demo\AbpAspNetCoreDemo'; Name = 'AbpAspNetCoreDemo' },
            @{ Folder = 'test\aspnet-core-demo\AbpAspNetCoreDemo.Core'; Name = 'AbpAspNetCoreDemo.Core' },
            @{ Folder = 'test\aspnet-core-demo\AbpAspNetCoreDemo.PlugIn'; Name = 'AbpAspNetCoreDemo.PlugIn' },
            @{ Folder = 'test\aspnet-core-demo\AbpAspNetCoreDemo.Tests'; Name = 'AbpAspNetCoreDemo.IntegrationTests' }
        )

        foreach ($project in $projects) {
            $projectDir = Join-Path $srcRoot $project.Folder
            New-Item -ItemType Directory -Force -Path $projectDir | Out-Null
            dotnet new classlib --name $project.Name --output $projectDir | Out-Null
            dotnet sln $solutionPath add (Join-Path $projectDir ($project.Name + '.csproj')) | Out-Null
        }
    }
    finally {
        Pop-Location
    }

    RunTestDemos -rootPath ($demoRoot + [System.IO.Path]::DirectorySeparatorChar) -projNames @(
        'AbpAspNetCoreDemo',
        'AbpAspNetCoreDemo.Core',
        'AbpAspNetCoreDemo.IntegrationTests',
        'AbpAspNetCoreDemo.Tests',
        'AbpAspNetCoreDemo.PlugIn'
    )

    Assert-True (-not (Test-Path $demoRoot)) 'Expected aspnet-core-demo folder to be deleted.'

    $solutionContent = Get-Content -Path $solutionPath -Raw -Encoding UTF8
    Assert-True ($solutionContent -notmatch 'AbpAspNetCoreDemo') 'Expected demo projects to be removed from Abp.sln.'
    Assert-True ($solutionContent -match 'Keep\.Project') 'Expected non-demo project to remain in Abp.sln.'

    Write-Host 'PASS: RunTestDemos removes demo projects from solution before deleting folder.'
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
