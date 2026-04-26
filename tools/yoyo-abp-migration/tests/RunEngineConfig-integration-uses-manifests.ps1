Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-HasNonEmptyStringArrayProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigLabel
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "$ConfigLabel is missing required property '$PropertyName'."
    }

    $values = @($Config[$PropertyName])
    if ($values.Count -eq 0) {
        throw "$ConfigLabel property '$PropertyName' must not be empty."
    }

    foreach ($value in $values) {
        if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
            throw "$ConfigLabel property '$PropertyName' must contain only non-empty strings."
        }
    }
}

function Assert-HasNonEmptyStringProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigLabel
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "$ConfigLabel is missing required property '$PropertyName'."
    }

    $value = $Config[$PropertyName]
    if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
        throw "$ConfigLabel property '$PropertyName' must be a non-empty string."
    }
}

function Assert-HasNonEmptyCollectionProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigLabel
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "$ConfigLabel is missing required property '$PropertyName'."
    }

    $values = @($Config[$PropertyName])
    if ($values.Count -eq 0) {
        throw "$ConfigLabel property '$PropertyName' must not be empty."
    }
}

function Assert-VersionGenerationsHaveRequiredShape {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$VersionMatrix
    )

    Assert-HasNonEmptyStringProperty -Config $VersionMatrix -PropertyName 'defaultProfile' -ConfigLabel 'version generation matrix'
    Assert-HasNonEmptyCollectionProperty -Config $VersionMatrix -PropertyName 'generations' -ConfigLabel 'version generation matrix'

    $index = 0
    foreach ($generation in @($VersionMatrix['generations'])) {
        if ($generation -isnot [hashtable]) {
            throw "version generation matrix entry [$index] must be an object."
        }

        Assert-HasNonEmptyStringProperty -Config $generation -PropertyName 'name' -ConfigLabel "version generation matrix[$index]"
        Assert-HasNonEmptyStringArrayProperty -Config $generation -PropertyName 'tagPrefixes' -ConfigLabel "version generation matrix[$index]"
        Assert-HasNonEmptyStringProperty -Config $generation -PropertyName 'targetFramework' -ConfigLabel "version generation matrix[$index]"
        $index++
    }
}

function New-TestConfigRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceConfigRoot,

        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $tempConfigRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("yoyo-abp-engine-config-" + [System.Guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $tempConfigRoot -Force)
    Copy-Item -Path (Join-Path $SourceConfigRoot '*.json') -Destination $tempConfigRoot -Force
    Set-Content -LiteralPath (Join-Path $tempConfigRoot $FileName) -Value $Content -Encoding UTF8

    return $tempConfigRoot
}

function Assert-LoaderThrows {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Loader,

        [Parameter(Mandatory = $true)]
        [string]$ConfigRoot,

        [Parameter(Mandatory = $true)]
        [string]$Scenario,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedMessageParts
    )

    try {
        & $Loader $ConfigRoot | Out-Null
        throw "Expected loader failure for scenario: $Scenario"
    }
    catch {
        $message = $_.Exception.Message
        if ($message -eq "Expected loader failure for scenario: $Scenario") {
            throw
        }

        foreach ($expectedMessagePart in $ExpectedMessageParts) {
            if ($message -notlike "*$expectedMessagePart*") {
                throw "Scenario '$Scenario' did not include expected message fragment '$expectedMessagePart'. Actual: $message"
            }
        }
    }
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$configRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config'
$engineConfigPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\engine_config.ps1'
$runPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\run.ps1'
$validatorPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\validate_output.ps1'
$runContent = Get-Content -LiteralPath $runPath -Raw -Encoding UTF8
$validatorContent = Get-Content -LiteralPath $validatorPath -Raw -Encoding UTF8

if ($runContent -notmatch 'engine_config\.ps1') {
    throw 'run.ps1 does not load engine_config.ps1.'
}

if ($runContent -notmatch 'Get-LibraryProfile33Compat') {
    throw 'run.ps1 does not use the manifest-backed library profile.'
}

if ($runContent -notmatch 'Get-TestProfile33Compat') {
    throw 'run.ps1 does not use the manifest-backed test profile.'
}

if ($runContent -notmatch 'Get-LegacyPackageExclusions') {
    throw 'run.ps1 does not use the manifest-backed legacy exclusion config.'
}

if ($runContent -notmatch '-LegacyExclusionConfig') {
    throw 'run.ps1 does not pass legacy exclusions into the validator.'
}

if ($validatorContent -notmatch 'LegacyExclusionConfig') {
    throw 'validate_output.ps1 does not accept manifest-backed legacy exclusions.'
}

. $engineConfigPath

$libraryProfile = Get-LibraryProfile33Compat -ConfigRoot $configRoot
Assert-HasNonEmptyStringArrayProperty -Config $libraryProfile -PropertyName 'libraryProjects' -ConfigLabel 'library profile'
Assert-HasNonEmptyStringArrayProperty -Config $libraryProfile -PropertyName 'packProjects' -ConfigLabel 'library profile'

$testProfile = Get-TestProfile33Compat -ConfigRoot $configRoot
Assert-HasNonEmptyStringArrayProperty -Config $testProfile -PropertyName 'testProjects' -ConfigLabel 'test profile'

$legacyPackageExclusions = Get-LegacyPackageExclusions -ConfigRoot $configRoot
Assert-HasNonEmptyStringArrayProperty -Config $legacyPackageExclusions -PropertyName 'exactProjectNames' -ConfigLabel 'legacy package exclusions'
Assert-HasNonEmptyStringArrayProperty -Config $legacyPackageExclusions -PropertyName 'tokenPatterns' -ConfigLabel 'legacy package exclusions'

$versionGenerationMatrix = Get-VersionGenerationMatrix -ConfigRoot $configRoot
Assert-VersionGenerationsHaveRequiredShape -VersionMatrix $versionGenerationMatrix

$invalidLibraryJsonConfigRoot = New-TestConfigRoot -SourceConfigRoot $configRoot -FileName 'library-profile-33-compat.json' -Content '{ invalid-json '
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-LibraryProfile33Compat -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidLibraryJsonConfigRoot `
        -Scenario 'invalid library profile JSON' `
        -ExpectedMessageParts @(
            'Failed to parse migration config JSON',
            'library-profile-33-compat.json'
        )
}
finally {
    if (Test-Path -LiteralPath $invalidLibraryJsonConfigRoot) {
        Remove-Item -LiteralPath $invalidLibraryJsonConfigRoot -Recurse -Force
    }
}

$invalidTestProfileConfigRoot = New-TestConfigRoot -SourceConfigRoot $configRoot -FileName 'test-profile-33-compat.json' -Content @'
{
  "testProjects": []
}
'@
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-TestProfile33Compat -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidTestProfileConfigRoot `
        -Scenario 'empty testProjects list' `
        -ExpectedMessageParts @(
            'test-profile-33-compat.json',
            'testProjects'
        )
}
finally {
    if (Test-Path -LiteralPath $invalidTestProfileConfigRoot) {
        Remove-Item -LiteralPath $invalidTestProfileConfigRoot -Recurse -Force
    }
}

$invalidLegacyExclusionsConfigRoot = New-TestConfigRoot -SourceConfigRoot $configRoot -FileName 'legacy-package-exclusions.json' -Content @'
{
  "exactProjectNames": ["Abp.Web"],
  "tokenPatterns": []
}
'@
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-LegacyPackageExclusions -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidLegacyExclusionsConfigRoot `
        -Scenario 'empty legacy exclusion tokenPatterns list' `
        -ExpectedMessageParts @(
            'legacy-package-exclusions.json',
            'tokenPatterns'
        )
}
finally {
    if (Test-Path -LiteralPath $invalidLegacyExclusionsConfigRoot) {
        Remove-Item -LiteralPath $invalidLegacyExclusionsConfigRoot -Recurse -Force
    }
}

$invalidVersionGenerationConfigRoot = New-TestConfigRoot -SourceConfigRoot $configRoot -FileName 'version-generations.json' -Content @'
{
  "defaultProfile": "33-compat",
  "generations": [
    {
      "name": "",
      "tagPrefixes": [],
      "targetFramework": ""
    }
  ]
}
'@
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-VersionGenerationMatrix -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidVersionGenerationConfigRoot `
        -Scenario 'invalid version generation entry' `
        -ExpectedMessageParts @(
            'version-generations.json',
            'name'
        )
}
finally {
    if (Test-Path -LiteralPath $invalidVersionGenerationConfigRoot) {
        Remove-Item -LiteralPath $invalidVersionGenerationConfigRoot -Recurse -Force
    }
}

Write-Host 'run.ps1 and validate_output.ps1 are wired to manifest-backed config.' -ForegroundColor Green
