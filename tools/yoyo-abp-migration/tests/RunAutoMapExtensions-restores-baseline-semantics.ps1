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

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('yoyo-automapextensions-' + [guid]::NewGuid().ToString('N'))
$fixturePath = Join-Path $tempRoot 'AutoMapExtensions.cs'

$fixtureContent = @'
using Abp.Domain.Entities;

namespace Abp.AutoMapper
{
    public static class AutoMapExtensions
    {
        public static CreateMultiLingualMapResult<TMultiLingualEntity, TTranslation, TDestination> CreateMultiLingualMap<TMultiLingualEntity, TMultiLingualEntityPrimaryKey, TTranslation, TTranslationPrimaryKey, TDestination>(
            object configuration, object multiLingualMapContext, bool fallbackToParentCultures = false)
            where TTranslation : class, IEntityTranslation<TMultiLingualEntity, TMultiLingualEntityPrimaryKey>, IEntity<TTranslationPrimaryKey>
            where TMultiLingualEntity : IMultiLingualEntity<TTranslation>
        {
            return default;
        }

        public static CreateMultiLingualMapResult<TMultiLingualEntity, TTranslation, TDestination> CreateMultiLingualMap<TMultiLingualEntity, TTranslation, TDestination>(object configuration,
            object multiLingualMapContext,
            bool fallbackToParentCultures = false)
            where TTranslation : class, IEntity, IEntityTranslation<TMultiLingualEntity, int>
            where TMultiLingualEntity : IMultiLingualEntity<TTranslation>
        {
            return configuration.CreateMultiLingualMap<TMultiLingualEntity, int, TTranslation, int, TDestination>(multiLingualMapContext, fallbackToParentCultures);
        }
    }
}
'@

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    Set-Content -Path $fixturePath -Value $fixtureContent -Encoding UTF8

    ReplaceEntitys -Path $fixturePath

    $actual = Get-Content -Path $fixturePath -Raw -Encoding UTF8

    Assert-True ($actual.Contains('CreateMultiLingualMap<TMultiLingualEntity, TMultiLingualEntityPrimaryKey, TTranslation, TDestination>(')) 'Expected engine to collapse the five-parameter CreateMultiLingualMap signature back to the four-parameter baseline shape.'
    Assert-True (-not $actual.Contains('TTranslationPrimaryKey')) 'Expected generated AutoMapExtensions.cs to drop TTranslationPrimaryKey references.'
    Assert-True ($actual.Contains('where TTranslation : class, IEntityTranslation<TMultiLingualEntity, TMultiLingualEntityPrimaryKey>')) 'Expected generated AutoMapExtensions.cs to keep only the IEntityTranslation constraint on the primary generic overload.'
    Assert-True (-not $actual.Contains('IEntity<TTranslationPrimaryKey>')) 'Expected generated AutoMapExtensions.cs to drop the IEntity<TTranslationPrimaryKey> constraint.'
    Assert-True ($actual.Contains('CreateMultiLingualMap<TMultiLingualEntity, int, TTranslation, TDestination>(multiLingualMapContext, fallbackToParentCultures)')) 'Expected the convenience overload to call the four-parameter baseline helper.'

    Write-Host 'PASS: AutoMapExtensions rule restores baseline multi-lingual map generic semantics.'
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}