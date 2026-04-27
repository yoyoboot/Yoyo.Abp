Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RequiredProjectList {
    param(
        [hashtable]$Profile,
        [string]$PropertyName,
        [string]$ProfilePath
    )

    if (!($Profile.ContainsKey($PropertyName))) {
        throw "Missing '$PropertyName' in profile: $ProfilePath"
    }

    $values = @($Profile[$PropertyName] | Sort-Object -Unique)
    if ($values.Count -eq 0) {
        throw "Profile property '$PropertyName' must not be empty: $ProfilePath"
    }

    return $values
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

function Assert-SequenceMatches {
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

function Get-PackProjectsFromScript {
    param(
        [string]$ScriptPath
    )

    $scriptContent = Get-Content $ScriptPath -Raw
    $projectsBlockMatch = [regex]::Match(
        $scriptContent,
        '(?ms)^\$projects\s*=\s*\(\s*(?<body>.*?)^\)',
        [System.Text.RegularExpressions.RegexOptions]::None
    )

    if (!($projectsBlockMatch.Success)) {
        throw "Could not locate `$projects list in pack script: $ScriptPath"
    }

    $projects = @(
        [regex]::Matches($projectsBlockMatch.Groups['body'].Value, '"(?<name>[^"\r\n]+)"') |
            ForEach-Object { $_.Groups['name'].Value } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    if ($projects.Count -eq 0) {
        throw "No projects found in `$projects list of pack script: $ScriptPath"
    }

    return $projects
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$configRoot = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config'
$engineConfigPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\engine_config.ps1'
$packScriptPath = Join-Path $repoRoot 'nupkg\pack.ps1'

if (!(Test-Path $engineConfigPath)) {
    throw "Missing engine config: $engineConfigPath"
}

. $engineConfigPath

$currentVersion = Get-VersionFromCommonProps -RootPath $repoRoot
$selection = Get-MigrationGenerationSelection -SourceRoot $repoRoot -ConfigRoot $configRoot

if ($currentVersion.StartsWith('9.', [System.StringComparison]::OrdinalIgnoreCase)) {
    Assert-Equal -Expected 'v9-stable' -Actual $selection['profile'] -Context 'resolved profile for current worktree'
}
elseif ($currentVersion.StartsWith('10.', [System.StringComparison]::OrdinalIgnoreCase)) {
    Assert-Equal -Expected 'v10-stable' -Actual $selection['profile'] -Context 'resolved profile for current worktree'
}
else {
    throw "Unexpected current version for profile alignment test: $currentVersion"
}

$libraryProfilePath = Join-Path $configRoot ("library-profile-{0}.json" -f $selection['profile'])
$testProfilePath = Join-Path $configRoot ("test-profile-{0}.json" -f $selection['profile'])

if (!(Test-Path $libraryProfilePath)) {
    throw "Missing library profile: $libraryProfilePath"
}

if (!(Test-Path $testProfilePath)) {
    throw "Missing test profile: $testProfilePath"
}

$libraryProfile = Get-LibraryProfileByName -ProfileName $selection['profile'] -ConfigRoot $configRoot
$testProfile = Get-TestProfileByName -ProfileName $selection['profile'] -ConfigRoot $configRoot

$libraryProjects = Get-RequiredProjectList -Profile $libraryProfile -PropertyName 'libraryProjects' -ProfilePath $libraryProfilePath
$currentProjects = @(
    Get-ChildItem (Join-Path $repoRoot 'src') -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName ($_.Name + '.csproj')) } |
        ForEach-Object Name |
        Sort-Object -Unique
)

$packProjects = Get-RequiredProjectList -Profile $libraryProfile -PropertyName 'packProjects' -ProfilePath $libraryProfilePath
$currentPackProjects = Get-PackProjectsFromScript -ScriptPath $packScriptPath

$testProjects = Get-RequiredProjectList -Profile $testProfile -PropertyName 'testProjects' -ProfilePath $testProfilePath
$currentTestProjects = @(
    Get-ChildItem (Join-Path $repoRoot 'test') -Directory |
        Where-Object {
            $_.Name -ne 'aspnet-core-demo' -and
            (Test-Path (Join-Path $_.FullName ($_.Name + '.csproj')))
        } |
        ForEach-Object Name |
        Sort-Object -Unique
)

Assert-SequenceMatches -Expected $libraryProjects -Actual $currentProjects -Context ("library profile {0}" -f $selection['profile'])
Assert-SequenceMatches -Expected $packProjects -Actual $currentPackProjects -Context ("pack profile {0}" -f $selection['profile'])
Assert-SequenceMatches -Expected $testProjects -Actual $currentTestProjects -Context ("test profile {0}" -f $selection['profile'])

Write-Host ("Generation-aware profile {0} matches current src/test/pack surface." -f $selection['profile']) -ForegroundColor Green
