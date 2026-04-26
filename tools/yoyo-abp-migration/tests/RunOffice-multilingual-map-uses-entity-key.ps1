Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$engineRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3'

Push-Location $engineRoot
try {
    . .\common.ps1
    . .\process_test.ps1
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

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('yoyo-office-map-' + [guid]::NewGuid().ToString('N'))
$generatedRoot = Join-Path $tempRoot 'test\Abp.ZeroCore.SampleApp'
$moduleFixturePath = Join-Path $generatedRoot 'AbpZeroCoreSampleAppModule.cs'
$appServiceFixturePath = Join-Path $generatedRoot 'Application\Shop\IOfficeAppService.cs'

$moduleFixtureContent = @'
namespace Abp.ZeroCore.SampleApp
{
    internal static class CustomDtoMapper
    {
        public static void CreateMappings(object configuration, object context)
        {
            configuration.CreateMultiLingualMap<Office, int, OfficeTranslation, long, OfficeListDto>(context, true);
        }
    }
}
'@

$appServiceFixtureContent = @'
namespace Abp.ZeroCore.SampleApp.Application.Shop
{
    public class OfficeAppService
    {
        private readonly IRepository<OfficeTranslation, long> _officeTranslationRepository;
    }
}
'@

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $moduleFixturePath) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $appServiceFixturePath) | Out-Null
    Set-Content -Path $moduleFixturePath -Value $moduleFixtureContent -Encoding UTF8
    Set-Content -Path $appServiceFixturePath -Value $appServiceFixtureContent -Encoding UTF8

    ReplaceTests -Path $moduleFixturePath
    ReplaceTests -Path $appServiceFixturePath

    $actualModule = Get-Content -Path $moduleFixturePath -Raw -Encoding UTF8
    $actualAppService = Get-Content -Path $appServiceFixturePath -Raw -Encoding UTF8

    Assert-True ($actualModule.Contains('CreateMultiLingualMap<Office,int, OfficeTranslation, OfficeListDto>')) 'Expected Office multilingual map rewrite to keep the Office entity key type as int in the collapsed four-parameter call.'
    Assert-True (-not $actualModule.Contains('CreateMultiLingualMap<Office,string, OfficeTranslation, OfficeListDto>')) 'Unexpected string entity key leaked into the Office multilingual map rewrite.'
    Assert-True (-not $actualModule.Contains('CreateMultiLingualMap<Office, int, OfficeTranslation, long, OfficeListDto>')) 'Expected Office multilingual map rewrite to remove the old translation primary-key generic argument.'
    Assert-True ($actualAppService.Contains('IRepository<OfficeTranslation, string>')) 'Expected Office translation repository injection to keep using the translation entity primary key type.'
    Assert-True (-not $actualAppService.Contains('IRepository<OfficeTranslation, long>')) 'Expected Office translation repository rewrite to remove the old long repository key.'

    Write-Host 'PASS: Office multilingual map rewrite keeps entity key type and translation repository key aligned.'
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}