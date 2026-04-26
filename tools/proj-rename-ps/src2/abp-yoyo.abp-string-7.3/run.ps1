param(
    # input src
    [Parameter(Mandatory = $true)]
    [string]$Src
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
$Src = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Src)

if (!(Test-Path -LiteralPath $Src -PathType Container)) {
    throw "Src must be an existing directory: $Src"
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



# #====================== 基础库
$rootPath = "${Src}\src\"
$libraryProjectNames = @(
    'Abp',
    'Abp.Web.Common',
    'Abp.AspNetCore',
    'Abp.AspNetCore.OData',
    'Abp.RedisCache',
    'Abp.RedisCache.ProtoBuf',
    'Abp.AspNetCore.PerRequestRedisCache',
    'Abp.AspNetCore.SignalR',
    'Abp.TestBase',
    'Abp.AspNetCore.TestBase',
    'Abp.AutoMapper',
    'Abp.Castle.Log4Net',
    'Abp.Dapper',
    'Abp.EntityFramework.Common',
    'Abp.EntityFramework',
    'Abp.EntityFrameworkCore',
    'Abp.EntityFrameworkCore.EFPlus',
    'Abp.FluentValidation',
    'Abp.HangFire',
    'Abp.HangFire.AspNetCore',
    'Abp.MailKit',
    'Abp.MemoryDb',
    'Abp.MongoDB',
    'Abp.Quartz',
    'Abp.Zero.Common',
    'Abp.Zero.Ldap',
    'Abp.ZeroCore',
    'Abp.ZeroCore.EntityFramework',
    'Abp.ZeroCore.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4',
    'Abp.ZeroCore.IdentityServer4.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4.vNext',
    'Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore'
)


RmLib -rootPath $rootPath -projNames $libraryProjectNames
RunLib -rootPath $rootPath -projNames $libraryProjectNames


#====================== 测试
$rootPath = "${Src}\test\"
$testProjectNames = @(
    'Abp.AspNetCore.Tests',
    'Abp.AutoMapper.Tests',
    'Abp.Castle.Log4Net.Tests',
    'Abp.Dapper.Tests',
    'Abp.EntityFramework.Tests',
    'Abp.EntityFrameworkCore.Dapper.Tests',
    'Abp.EntityFrameworkCore.Tests',
    'Abp.MailKit.Tests',
    'Abp.MemoryDb.Tests',
    'Abp.Quartz.Tests',
    'Abp.RedisCache.Tests',
    'Abp.TestBase.Tests',
    'Abp.Tests',
    'Abp.Web.Common.Tests',
    'Abp.ZeroCore.IdentityServer4.Tests',
    'Abp.ZeroCore.SampleApp',
    'Abp.ZeroCore.Tests'
)

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

Assert-MigrationOutput -Src $Src -ExpectedLibraryProjectNames $libraryProjectNames
