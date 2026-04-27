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

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Expected,

        [Parameter(Mandatory = $true)]
        [object]$Actual,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    if ($Expected -ne $Actual) {
        throw "$Context expected '$Expected' but found '$Actual'."
    }
}

function Assert-SequenceEqual {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Expected,

        [Parameter(Mandatory = $true)]
        [string[]]$Actual,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    $difference = Compare-Object -ReferenceObject @($Expected) -DifferenceObject @($Actual)
    if ($difference) {
        $formattedDifference = $difference | ForEach-Object { "{0} {1}" -f $_.SideIndicator, $_.InputObject }
        throw "$Context does not match expected values:`n$($formattedDifference -join [Environment]::NewLine)"
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

function Assert-GenerationSelection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedGeneration,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedProfile,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedTargetFramework,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedStageKeepProjects,

        [Parameter(Mandatory = $true)]
        [string]$ConfigRoot
    )

    $selection = Get-MigrationGenerationSelection -Version $Version -ConfigRoot $ConfigRoot
    Assert-Equal -Expected $ExpectedGeneration -Actual $selection['generation'] -Context "generation for $Version"
    Assert-Equal -Expected $ExpectedProfile -Actual $selection['profile'] -Context "profile for $Version"
    Assert-Equal -Expected $ExpectedTargetFramework -Actual $selection['targetFramework'] -Context "target framework for $Version"
    Assert-SequenceEqual -Expected $ExpectedStageKeepProjects -Actual @($selection['stageKeepProjects']) -Context "stage keep projects for $Version"
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$configRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config'
$engineConfigPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\engine_config.ps1'
$runPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\run.ps1'
$validatorPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\validate_output.ps1'
$migrationPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\Invoke-YoyoAbpMigration.ps1'
$runContent = Get-Content -LiteralPath $runPath -Raw -Encoding UTF8
$validatorContent = Get-Content -LiteralPath $validatorPath -Raw -Encoding UTF8
$migrationContent = Get-Content -LiteralPath $migrationPath -Raw -Encoding UTF8

if ($runContent -notmatch 'engine_config\.ps1') {
    throw 'run.ps1 does not load engine_config.ps1.'
}

foreach ($requiredSnippet in @('Get-MigrationGenerationSelection', 'Get-LibraryProfileByName', 'Get-TestProfileByName')) {
    if ($runContent -notmatch $requiredSnippet) {
        throw "run.ps1 does not use $requiredSnippet."
    }
}

if ($runContent -notmatch 'ExpectedPackProjectNames') {
    throw 'run.ps1 does not pass expected pack projects into the validator.'
}

if ($runContent -notmatch '-LegacyExclusionConfig') {
    throw 'run.ps1 does not pass legacy exclusions into the validator.'
}

if ($validatorContent -notmatch 'ExpectedPackProjectNames') {
    throw 'validate_output.ps1 does not accept generation-aware pack project expectations.'
}

if ($migrationContent -notmatch 'Get-MigrationGenerationSelection') {
    throw 'Invoke-YoyoAbpMigration.ps1 does not reuse generation-aware stage keep selection.'
}

. $engineConfigPath

$currentVersion = Get-VersionFromCommonProps -RootPath $repoRoot
$currentSelection = Get-MigrationGenerationSelection -SourceRoot $repoRoot -ConfigRoot $configRoot

if ($currentVersion.StartsWith('9.', [System.StringComparison]::OrdinalIgnoreCase)) {
    Assert-Equal -Expected 'v9-stable' -Actual $currentSelection['profile'] -Context 'current worktree profile'
}
elseif ($currentVersion.StartsWith('10.', [System.StringComparison]::OrdinalIgnoreCase)) {
    Assert-Equal -Expected 'v10-stable' -Actual $currentSelection['profile'] -Context 'current worktree profile'
}
else {
    throw "Unexpected current version for release worktree test: $currentVersion"
}

$libraryProfile = Get-LibraryProfileByName -ProfileName $currentSelection['profile'] -ConfigRoot $configRoot
Assert-HasNonEmptyStringArrayProperty -Config $libraryProfile -PropertyName 'libraryProjects' -ConfigLabel 'library profile'
Assert-HasNonEmptyStringArrayProperty -Config $libraryProfile -PropertyName 'packProjects' -ConfigLabel 'library profile'

$testProfile = Get-TestProfileByName -ProfileName $currentSelection['profile'] -ConfigRoot $configRoot
Assert-HasNonEmptyStringArrayProperty -Config $testProfile -PropertyName 'testProjects' -ConfigLabel 'test profile'

$legacyPackageExclusions = Get-LegacyPackageExclusions -ConfigRoot $configRoot
Assert-HasNonEmptyStringArrayProperty -Config $legacyPackageExclusions -PropertyName 'exactProjectNames' -ConfigLabel 'legacy package exclusions'
Assert-HasNonEmptyStringArrayProperty -Config $legacyPackageExclusions -PropertyName 'tokenPatterns' -ConfigLabel 'legacy package exclusions'

$versionGenerationMatrix = Get-VersionGenerationMatrix -ConfigRoot $configRoot
Assert-Equal -Expected '33-compat' -Actual $versionGenerationMatrix['defaultProfile'] -Context 'default profile in version generation matrix'

Assert-GenerationSelection -Version '9.4.2' -ExpectedGeneration 'v9-net8' -ExpectedProfile 'v9-stable' -ExpectedTargetFramework 'net8.0' -ExpectedStageKeepProjects @(
    'Abp.AspNetCore.OpenIddict',
    'Abp.ZeroCore.OpenIddict',
    'Abp.ZeroCore.OpenIddict.EntityFrameworkCore',
    'Abp.EntityFrameworkCore.EFPlus',
    'Abp.ZeroCore.IdentityServer4.vNext',
    'Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore'
) -ConfigRoot $configRoot

Assert-GenerationSelection -Version '10.3.0' -ExpectedGeneration 'v10-net9' -ExpectedProfile 'v10-stable' -ExpectedTargetFramework 'net9.0' -ExpectedStageKeepProjects @(
    'Abp.AspNetCore.OpenIddict',
    'Abp.ZeroCore.OpenIddict',
    'Abp.ZeroCore.OpenIddict.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore'
) -ConfigRoot $configRoot

$invalidLibraryJsonConfigRoot = New-TestConfigRoot -SourceConfigRoot $configRoot -FileName 'library-profile-v9-stable.json' -Content '{ invalid-json '
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-LibraryProfileByName -ProfileName 'v9-stable' -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidLibraryJsonConfigRoot `
        -Scenario 'invalid v9 stable library profile JSON' `
        -ExpectedMessageParts @(
            'Failed to parse migration config JSON',
            'library-profile-v9-stable.json'
        )
}
finally {
    if (Test-Path -LiteralPath $invalidLibraryJsonConfigRoot) {
        Remove-Item -LiteralPath $invalidLibraryJsonConfigRoot -Recurse -Force
    }
}

$invalidTestProfileConfigRoot = New-TestConfigRoot -SourceConfigRoot $configRoot -FileName 'test-profile-v10-stable.json' -Content @'
{
  "testProjects": []
}
'@
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-TestProfileByName -ProfileName 'v10-stable' -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidTestProfileConfigRoot `
        -Scenario 'empty v10 stable testProjects list' `
        -ExpectedMessageParts @(
            'test-profile-v10-stable.json',
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
      "name": "v9-net8",
      "tagPrefixes": ["v9."],
      "targetFramework": "net8.0",
      "stageKeepProjects": ["Abp.AspNetCore.OpenIddict"]
    }
  ]
}
'@
try {
    Assert-LoaderThrows `
        -Loader { param($tempRoot) Get-VersionGenerationMatrix -ConfigRoot $tempRoot } `
        -ConfigRoot $invalidVersionGenerationConfigRoot `
        -Scenario 'missing generation profile mapping' `
        -ExpectedMessageParts @(
            'version-generations.json',
            'profile'
        )
}
finally {
    if (Test-Path -LiteralPath $invalidVersionGenerationConfigRoot) {
        Remove-Item -LiteralPath $invalidVersionGenerationConfigRoot -Recurse -Force
    }
}

Write-Host 'run.ps1, validate_output.ps1 and Invoke-YoyoAbpMigration.ps1 are wired to generation-aware manifests.' -ForegroundColor Green
