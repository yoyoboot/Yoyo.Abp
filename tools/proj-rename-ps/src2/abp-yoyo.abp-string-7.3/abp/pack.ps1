# Paths
$packFolder = (Get-Item -Path "./" -Verbose).FullName
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

# Rebuild solution
Set-Location $slnPath
& dotnet restore

# Copy all nuget packages to the pack folder
foreach ($project in $projects) {

    ## path
    $projectFolder = Join-Path $srcPath $project
    if (!(Test-Path $projectFolder)) {
        continue
    }

    # Create nuget pack
    Set-Location $projectFolder
    Get-ChildItem (Join-Path $projectFolder "bin/Release") -ErrorAction SilentlyContinue | Remove-Item -Recurse
    & dotnet msbuild /p:Configuration=Release
    & dotnet msbuild /p:Configuration=Release /t:pack /p:IncludeSymbols=true /p:SymbolPackageFormat=snupkg

    # Copy nuget package
    $projectPackPath = Join-Path $projectFolder ("/bin/Release/" + 'Yoyo.' + $project + ".*.nupkg")
    Move-Item $projectPackPath $packFolder

    # Copy symbol package
    $projectPackPath = Join-Path $projectFolder ("/bin/Release/" + 'Yoyo.' + $project + ".*.snupkg")
    Move-Item $projectPackPath $packFolder
}

# Go back to the pack folder
Set-Location $packFolder