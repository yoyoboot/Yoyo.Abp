# ȫ��ͨ�õ����ñ�����Ϣ
$version = "1.0.0"

# �Ƿ�Ϊ����
$isProduction = $env:IS_PRODUCTION



Write-Host "IS_PRODUCTION: $isProduction" -ForegroundColor Blue




# ����ģʽ���ӻ���������ȡ
if ($isProduction -eq $True) {
    Write-Host "TAG: $env:TAG" -ForegroundColor Blue

    $version = $env:TAG
    Write-Host "version: $version" 

}

# Paths
$packFolder = (Get-Item -Path "./" -Verbose).FullName
$distPath = Join-Path $packFolder "dist"
$slnPath = Join-Path $packFolder "../"
$srcPath = Join-Path $slnPath "src"

# List of projects
$projects = (
    "Abp",
    "Abp.AspNetCore",
    "Abp.AspNetCore.OData",
    "Abp.AspNetCore.SignalR",
    "Abp.AspNetCore.TestBase",
    "Abp.AspNetCore.PerRequestRedisCache",
    "Abp.AutoMapper",
    "Abp.BlobStoring",
    "Abp.BlobStoring.Azure",
    "Abp.BlobStoring.FileSystem",
    "Abp.Castle.Log4Net",
    "Abp.Dapper",
    "Abp.EntityFramework",
    "Abp.EntityFramework.Common",
    "Abp.EntityFramework.GraphDiff",
    "Abp.EntityFrameworkCore",
    "Abp.EntityFrameworkCore.EFPlus",
    "Abp.FluentMigrator",
    "Abp.FluentValidation",
    "Abp.HangFire",
    "Abp.HangFire.AspNetCore",
    "Abp.HtmlSanitizer",
    "Abp.MailKit",
    "Abp.MemoryDb",
    "Abp.MongoDB",
    "Abp.NHibernate",
    "Abp.Owin",
    "Abp.RedisCache",
    "Abp.RedisCache.ProtoBuf",
    "Abp.Quartz",
    "Abp.TestBase",
    "Abp.Web",
    "Abp.Web.Api",
    "Abp.Web.Api.OData",
    "Abp.Web.Common",
    "Abp.Web.Mvc",
    "Abp.Web.SignalR",
    "Abp.Web.Resources",
    "Abp.Zero",
    "Abp.Zero.Common",
    "Abp.Zero.EntityFramework",
    "Abp.Zero.Ldap",
    "Abp.Zero.NHibernate",
    "Abp.Zero.Owin",
    "Abp.ZeroCore",
    "Abp.ZeroCore.EntityFramework",
    "Abp.ZeroCore.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4",
    "Abp.ZeroCore.IdentityServer4.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4.vNext",
    "Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore"
)

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
        -p:Version=${version}

    $packageCounter += 1
}

Write-Host ('package count: ' + $packageCounter )
# Go back to the pack folder
Set-Location $packFolder
