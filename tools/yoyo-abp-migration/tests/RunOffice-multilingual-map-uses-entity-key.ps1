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
$translationFixturePath = Join-Path $generatedRoot 'Core\Shop\OfficeTranslation.cs'

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

$translationFixtureContent = @'
namespace Abp.ZeroCore.SampleApp.Core.Shop
{
    public class OfficeTranslation : IEntityTranslation<Office>
    {
        public int CoreId { get; set; }
    }
}
'@

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $moduleFixturePath) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $appServiceFixturePath) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $translationFixturePath) | Out-Null
    Set-Content -Path $moduleFixturePath -Value $moduleFixtureContent -Encoding UTF8
    Set-Content -Path $appServiceFixturePath -Value $appServiceFixtureContent -Encoding UTF8
    Set-Content -Path $translationFixturePath -Value $translationFixtureContent -Encoding UTF8

    ReplaceTests -Path $moduleFixturePath
    ReplaceTests -Path $appServiceFixturePath
    ReplaceTests -Path $translationFixturePath

    $actualModule = Get-Content -Path $moduleFixturePath -Raw -Encoding UTF8
    $actualAppService = Get-Content -Path $appServiceFixturePath -Raw -Encoding UTF8
    $actualTranslation = Get-Content -Path $translationFixturePath -Raw -Encoding UTF8

    Assert-True ($actualModule.Contains('CreateMultiLingualMap<Office,string, OfficeTranslation, OfficeListDto>')) 'Expected Office multilingual map rewrite to align with the default string entity key in Yoyo.Abp.'
    Assert-True (-not $actualModule.Contains('CreateMultiLingualMap<Office,int, OfficeTranslation, OfficeListDto>')) 'Unexpected int entity key remained in the Office multilingual map rewrite.'
    Assert-True (-not $actualModule.Contains('CreateMultiLingualMap<Office, int, OfficeTranslation, long, OfficeListDto>')) 'Expected Office multilingual map rewrite to remove the old translation primary-key generic argument.'
    Assert-True ($actualAppService.Contains('IRepository<OfficeTranslation, string>')) 'Expected Office translation repository injection to keep using the translation entity primary key type.'
    Assert-True (-not $actualAppService.Contains('IRepository<OfficeTranslation, long>')) 'Expected Office translation repository rewrite to remove the old long repository key.'
    Assert-True ($actualTranslation.Contains('IEntityTranslation<Office, string>')) 'Expected Office translation interface to align with the default string Office primary key.'
    Assert-True (-not $actualTranslation.Contains('IEntityTranslation<Office>')) 'Expected Office translation interface rewrite to remove the implicit int-key translation contract.'
    Assert-True ($actualTranslation.Contains('public string CoreId { get; set; }')) 'Expected Office translation CoreId to align with the default string Office primary key.'
    Assert-True (-not $actualTranslation.Contains('public int CoreId { get; set; }')) 'Expected Office translation CoreId rewrite to remove the old int key.'

    Write-Host 'PASS: Office multilingual map rewrite keeps Office translation types aligned with string primary keys.'
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}