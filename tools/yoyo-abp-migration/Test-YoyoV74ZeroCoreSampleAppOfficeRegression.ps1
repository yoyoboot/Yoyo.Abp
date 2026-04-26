[CmdletBinding()]
param(
    [string]$GeneratedRoot = (Join-Path $PSScriptRoot '..\..\artifacts\yoyo-abp-migration\yoyo-v7.4')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not $Content.Contains($Expected)) {
        throw "$Label is missing expected content: $Expected"
    }
}

function Assert-NotContains {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Unexpected,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Content.Contains($Unexpected)) {
        throw "$Label still contains unexpected content: $Unexpected"
    }
}

$resolvedRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($GeneratedRoot)
$modulePath = Join-Path $resolvedRoot 'test\Abp.ZeroCore.SampleApp\AbpZeroCoreSampleAppModule.cs'
$officeAppServicePath = Join-Path $resolvedRoot 'test\Abp.ZeroCore.SampleApp\Application\Shop\IOfficeAppService.cs'
$officeTranslationPath = Join-Path $resolvedRoot 'test\Abp.ZeroCore.SampleApp\Core\Shop\OfficeTranslation.cs'

foreach ($path in @($modulePath, $officeAppServicePath, $officeTranslationPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required generated file not found: $path"
    }
}

$moduleContent = Get-Content -LiteralPath $modulePath -Raw
$officeAppServiceContent = Get-Content -LiteralPath $officeAppServicePath -Raw
$officeTranslationContent = Get-Content -LiteralPath $officeTranslationPath -Raw

Assert-Contains -Content $moduleContent -Expected 'CreateMultiLingualMap<Office,string, OfficeTranslation, OfficeListDto>' -Label 'SampleApp module'
Assert-NotContains -Content $moduleContent -Unexpected 'CreateMultiLingualMap<Office,int, OfficeTranslation, OfficeListDto>' -Label 'SampleApp module'
Assert-NotContains -Content $moduleContent -Unexpected 'CreateMultiLingualMap<Office, int, OfficeTranslation, long, OfficeListDto>' -Label 'SampleApp module'

Assert-Contains -Content $officeAppServiceContent -Expected 'IRepository<OfficeTranslation, string>' -Label 'Office app service'
Assert-NotContains -Content $officeAppServiceContent -Unexpected 'IRepository<OfficeTranslation, long>' -Label 'Office app service'
Assert-Contains -Content $officeTranslationContent -Expected 'IEntityTranslation<Office, string>' -Label 'Office translation'
Assert-NotContains -Content $officeTranslationContent -Unexpected 'IEntityTranslation<Office>' -Label 'Office translation'
Assert-Contains -Content $officeTranslationContent -Expected 'public string CoreId { get; set; }' -Label 'Office translation'
Assert-NotContains -Content $officeTranslationContent -Unexpected 'public int CoreId { get; set; }' -Label 'Office translation'

Write-Host 'Office regression checks passed.'