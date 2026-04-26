Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$engineRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3'

Push-Location $engineRoot
try {
    . .\common.ps1
    . .\process_lib.ps1
}
finally {
    Pop-Location
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$fixtureContent = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net9.0;net461</TargetFrameworks>
  </PropertyGroup>

  <ItemGroup Condition="'$(TargetFramework)' != 'net461' and '$(TargetFramework)' != 'net461'">
    <PackageReference Include="Oracle.ManagedDataAccess.Core" Version="23.9.1" />
  </ItemGroup>

  <ItemGroup Condition="'$(TargetFramework)' == 'net461' and '$(OSTYPE)' != 'linux-gnu' and '$(OSTYPE)' != 'darwin18'">
    <PackageReference Include="Oracle.ManagedDataAccess" version="19.28.0" targetFramework="net461" />
  </ItemGroup>
</Project>
'@

$actual = RemoveNetFrameworkCompatibility -Content ($fixtureContent -split "`r?`n")

Assert-True ($actual.Contains('<TargetFramework>net9.0</TargetFramework>')) 'Expected TargetFrameworks to collapse to net9.0 only.'
Assert-True (-not $actual.Contains('net461')) 'Expected cleanup to remove all lingering net461 tokens, including conditional ItemGroup references.'
Assert-True ($actual.Contains('Oracle.ManagedDataAccess.Core')) 'Expected non-.NET Framework package references to remain after cleanup.'
Assert-True (-not $actual.Contains('Oracle.ManagedDataAccess" version="19.28.0"')) 'Expected .NET Framework-only Oracle package reference to be removed.'

Write-Host 'PASS: RemoveNetFrameworkCompatibility removes lingering net461 conditional groups.'
