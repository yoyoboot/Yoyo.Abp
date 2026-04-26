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
$libraryProfilePath = Join-Path $configRoot 'library-profile-33-compat.json'
$testProfilePath = Join-Path $configRoot 'test-profile-33-compat.json'
$packScriptPath = Join-Path $repoRoot 'nupkg\pack.ps1'

if (!(Test-Path $libraryProfilePath)) {
    throw "Missing library profile: $libraryProfilePath"
}

if (!(Test-Path $testProfilePath)) {
    throw "Missing test profile: $testProfilePath"
}

$libraryProfile = Get-Content $libraryProfilePath -Raw | ConvertFrom-Json -AsHashtable
$testProfile = Get-Content $testProfilePath -Raw | ConvertFrom-Json -AsHashtable

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

if (Compare-Object $libraryProjects $currentProjects) {
    throw 'library-profile-33-compat.json does not match current src package surface.'
}

if (Compare-Object $packProjects $currentPackProjects) {
    throw 'library-profile-33-compat.json does not match current nupkg/pack.ps1 project list.'
}

if (Compare-Object $testProjects $currentTestProjects) {
    throw 'test-profile-33-compat.json does not match current test project surface.'
}

Write-Host 'Profile 33 compatibility manifest matches current src/test/pack surface.' -ForegroundColor Green
