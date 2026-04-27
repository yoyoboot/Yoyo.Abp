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

function Set-PackScriptProjectList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackScriptPath,

        [Parameter(Mandatory = $true)]
        [string[]]$ProjectNames
    )

    $scriptContent = Get-Content -LiteralPath $PackScriptPath -Raw -Encoding UTF8
    $projectBody = ($ProjectNames | ForEach-Object { '    "{0}"' -f $_ }) -join (',' + [Environment]::NewLine)
    $replacement = '$projects = (' + [Environment]::NewLine + $projectBody + [Environment]::NewLine + ')'
    $updatedContent = [regex]::Replace($scriptContent, '(?ms)^\$projects\s*=\s*\(\s*.*?^\)', $replacement)

    if ($updatedContent -eq $scriptContent) {
        throw "Failed to update `$projects list in generated pack script: $PackScriptPath"
    }

    Set-Content -LiteralPath $PackScriptPath -Value $updatedContent -Encoding UTF8
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
$generationSelection = Get-MigrationGenerationSelection -SourceRoot $Src -ConfigRoot $configRoot
$profileName = $generationSelection['profile']
$libraryProfile = Get-LibraryProfileByName -ProfileName $profileName -ConfigRoot $configRoot
$testProfile = Get-TestProfileByName -ProfileName $profileName -ConfigRoot $configRoot
$legacyPackageExclusions = Get-LegacyPackageExclusions -ConfigRoot $configRoot
$resolvedStageKeepProjects = @($generationSelection['stageKeepProjects'])

Write-Host ("Resolved migration version: {0}" -f $generationSelection['version']) -ForegroundColor Blue
Write-Host ("Resolved migration generation: {0}" -f $generationSelection['generation']) -ForegroundColor Blue
Write-Host ("Resolved migration profile: {0}" -f $profileName) -ForegroundColor Blue
if ($resolvedStageKeepProjects.Count -gt 0) {
    Write-Host ("Resolved stage-keep projects: {0}" -f ($resolvedStageKeepProjects -join ', ')) -ForegroundColor Blue
}
else {
    Write-Host 'Resolved stage-keep projects: <none>' -ForegroundColor Blue
}


# #====================== 基础库
$rootPath = "${Src}\src\"
$libraryProjectNames = @($libraryProfile['libraryProjects'])
$packProjectNames = @($libraryProfile['packProjects'])
Assert-RequiredProjectList -ProjectNames $libraryProjectNames -ListLabel 'libraryProjects manifest list'
Assert-RequiredProjectList -ProjectNames $packProjectNames -ListLabel 'packProjects manifest list'


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
$generatedPackScriptPath = $nupkgPath + 'pack.ps1'
Copy-Item (Join-Path $scriptRoot 'abp\pack.ps1') -Destination $generatedPackScriptPath -Force
Set-PackScriptProjectList -PackScriptPath $generatedPackScriptPath -ProjectNames $packProjectNames

NormalizeRootBuildCompatibility -RootPath $Src

if ($resolvedStageKeepProjects.Count -gt 0) {
    Restore-YoyoAbpStageKeepProjects -RepoRoot $repoRoot -OutputRoot $Src -ProjectNames $resolvedStageKeepProjects
}

Assert-MigrationOutput `
    -Src $Src `
    -ExpectedLibraryProjectNames $libraryProjectNames `
    -ExpectedPackProjectNames $packProjectNames `
    -LegacyExclusionConfig $legacyPackageExclusions
