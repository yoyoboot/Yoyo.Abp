param(
    # input src
    [Parameter(Mandatory = $true)]
    [string]$Src
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
$Src = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Src)
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..\..\..\..'))
$stageKeepHelperPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\YoyoAbpMigrationStageKeep.ps1'

if (!(Test-Path -LiteralPath $Src -PathType Container)) {
    throw "Src must be an existing directory: $Src"
}

if (!(Test-Path -LiteralPath $stageKeepHelperPath -PathType Leaf)) {
    throw "Stage-keep helper was not found: $stageKeepHelperPath"
}

function Assert-RequiredProjectList {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ProjectNames,

        [Parameter(Mandatory = $true)]
        [string]$ListLabel
    )

    if ($ProjectNames.Count -eq 0) {
        throw "$ListLabel must not be empty."
    }

    foreach ($projectName in $ProjectNames) {
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            throw "$ListLabel must contain only non-empty project names."
        }
    }
}

function NormalizeRootBuildCompatibility {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $rootCompatibilityFiles = Get-ChildItem -LiteralPath $RootPath -File | Where-Object {
        $_.Extension -in '.props', '.targets'
    }

    foreach ($rootCompatibilityFile in $rootCompatibilityFiles) {
        $content = ReadFile -Path $rootCompatibilityFile.FullName
        $content = RemoveNetFrameworkCompatibility -Content $content
        WriteFile -Path $rootCompatibilityFile.FullName -Content $content
    }
}

# 执行公用脚本
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'process_lib.ps1')
. (Join-Path $scriptRoot 'process_test.ps1')
. (Join-Path $scriptRoot 'process_test_demo.ps1')
. (Join-Path $scriptRoot 'validate_output.ps1')
. (Join-Path $scriptRoot 'engine_config.ps1')
. $stageKeepHelperPath

$configRoot = Get-MigrationConfigRoot -ScriptRoot $scriptRoot
$libraryProfile = Get-LibraryProfile33Compat -ConfigRoot $configRoot
$testProfile = Get-TestProfile33Compat -ConfigRoot $configRoot
$legacyPackageExclusions = Get-LegacyPackageExclusions -ConfigRoot $configRoot


# #====================== 基础库
$rootPath = "${Src}\src\"
$libraryProjectNames = @($libraryProfile['libraryProjects'])
Assert-RequiredProjectList -ProjectNames $libraryProjectNames -ListLabel 'libraryProjects manifest list'


RmLib -rootPath $rootPath -projNames $libraryProjectNames
RunLib -rootPath $rootPath -projNames $libraryProjectNames


#====================== 测试
$rootPath = "${Src}\test\"
$testProjectNames = @($testProfile['testProjects'])
Assert-RequiredProjectList -ProjectNames $testProjectNames -ListLabel 'testProjects manifest list'

RmLib -rootPath $rootPath -projNames $testProjectNames
RunTest -rootPath $rootPath -projNames $testProjectNames


#====================== 测试demos
$rootPath = "${Src}\test\aspnet-core-demo\"
$demoProjectNames = @(
    'AbpAspNetCoreDemo',
    'AbpAspNetCoreDemo.Core',
    'AbpAspNetCoreDemo.IntegrationTests',
    'AbpAspNetCoreDemo.Tests',
    'AbpAspNetCoreDemo.PlugIn'
)

RunTestDemos -rootPath $rootPath -projNames $demoProjectNames

# ====================== 代码文件移入对应位置
$rootPath = "${Src}\src\"
$abpZeroCoreEntityFrameworkCorePath = $rootPath + 'Abp.ZeroCore.EntityFrameworkCore\Zero\EntityFrameworkCore\'
Copy-Item (Join-Path $scriptRoot 'abp\AbpZeroDbContextExtensions.cs') -Destination ($abpZeroCoreEntityFrameworkCorePath + 'AbpZeroDbContextExtensions.cs') -Force

$abpEntityFrameworkCorePath = $rootPath + 'Abp.EntityFrameworkCore\EntityFrameworkCore\Extensions\'
Copy-Item (Join-Path $scriptRoot 'abp\AbpDbContextExtensions.cs') -Destination ($abpEntityFrameworkCorePath + 'AbpDbContextExtensions.cs') -Force
Copy-Item (Join-Path $scriptRoot 'abp\AbpStringPrimaryKeyValueGenerator.cs') -Destination ($abpEntityFrameworkCorePath + 'AbpStringPrimaryKeyValueGenerator.cs') -Force

$abpPath = $rootPath + 'Abp\Extensions\'
Copy-Item (Join-Path $scriptRoot 'abp\StringIdExtensions.cs') -Destination ($abpPath + 'StringIdExtensions.cs') -Force

$nupkgPath = "${Src}\nupkg\"
Copy-Item (Join-Path $scriptRoot 'abp\pack.ps1') -Destination ($nupkgPath + 'pack.ps1') -Force

NormalizeRootBuildCompatibility -RootPath $Src

Restore-YoyoAbpStageKeepProjects -RepoRoot $repoRoot -OutputRoot $Src -ProjectNames @(
    'Abp.EntityFrameworkCore.EFPlus',
    'Abp.ZeroCore.IdentityServer4',
    'Abp.ZeroCore.IdentityServer4.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4.vNext'
)

Assert-MigrationOutput -Src $Src -ExpectedLibraryProjectNames $libraryProjectNames -LegacyExclusionConfig $legacyPackageExclusions
