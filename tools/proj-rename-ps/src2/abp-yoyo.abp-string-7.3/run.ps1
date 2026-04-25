param(
    # input src
    [string]$Src
)

# 执行公用脚本
. '.\common.ps1'
. '.\process_lib.ps1'
. '.\process_test.ps1'
. '.\process_test_demo.ps1'



# #====================== 基础库
$rootPath = "${Src}\src\"
$projNames = @(
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


RmLib -rootPath $rootPath -projNames $projNames
RunLib -rootPath $rootPath -projNames $projNames


#====================== 测试
$rootPath = "${Src}\test\"
$projNames = @(
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

RmLib -rootPath $rootPath -projNames $projNames
RunTest -rootPath $rootPath -projNames $projNames


#====================== 测试demos
$rootPath = "${Src}\test\aspnet-core-demo\"
$projNames = @(
    'AbpAspNetCoreDemo',
    'AbpAspNetCoreDemo.Core',
    'AbpAspNetCoreDemo.IntegrationTests',
    'AbpAspNetCoreDemo.Tests',
    'AbpAspNetCoreDemo.PlugIn'
)

RunTestDemos -rootPath $rootPath -projNames $projNames

# ====================== 代码文件移入对应位置
$rootPath = "${Src}\src\"
$abpZeroCoreEntityFrameworkCorePath = $rootPath + 'Abp.ZeroCore.EntityFrameworkCore\Zero\EntityFrameworkCore\'
Copy-Item './abp/AbpZeroDbContextExtensions.cs' -Destination ($abpZeroCoreEntityFrameworkCorePath + 'AbpZeroDbContextExtensions.cs') -Force

$abpEntityFrameworkCorePath = $rootPath + 'Abp.EntityFrameworkCore\EntityFrameworkCore\Extensions\'
Copy-Item './abp/AbpDbContextExtensions.cs' -Destination ($abpEntityFrameworkCorePath + 'AbpDbContextExtensions.cs') -Force
Copy-Item './abp/AbpStringPrimaryKeyValueGenerator.cs' -Destination ($abpEntityFrameworkCorePath + 'AbpStringPrimaryKeyValueGenerator.cs') -Force

$abpPath = $rootPath + 'Abp\Extensions\'
Copy-Item './abp/StringIdExtensions.cs' -Destination ($abpPath + 'StringIdExtensions.cs') -Force

$nupkgPath = "${Src}\nupkg\"
Copy-Item './abp/pack.ps1' -Destination ($nupkgPath + 'pack.ps1') -Force
