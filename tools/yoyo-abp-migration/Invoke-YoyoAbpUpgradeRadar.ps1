[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UpstreamPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$CurrentRoot = (Join-Path $PSScriptRoot '..\..'),

    [string]$VersionMatrixPath = (Join-Path $PSScriptRoot '..\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config\version-generations.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Read-JsonHashtable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (!(Test-Path -LiteralPath $Path)) {
        throw "Missing JSON file: $Path"
    }

    try {
        return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable)
    }
    catch {
        throw "Failed to parse JSON file: $Path. $($_.Exception.Message)"
    }
}

function Get-VersionFromCommonProps {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $commonPropsPath = Join-Path $Root 'common.props'
    if (!(Test-Path -LiteralPath $commonPropsPath)) {
        throw "Missing common.props: $commonPropsPath"
    }

    try {
        [xml]$commonPropsXml = Get-Content -LiteralPath $commonPropsPath -Raw -Encoding UTF8
    }
    catch {
        throw "Failed to read common.props XML: $commonPropsPath. $($_.Exception.Message)"
    }

    $versionNode = $commonPropsXml.SelectSingleNode('//Version')
    if ($null -eq $versionNode -or [string]::IsNullOrWhiteSpace($versionNode.InnerText)) {
        throw "Unable to resolve <Version> from common.props: $commonPropsPath"
    }

    return $versionNode.InnerText.Trim()
}

function Normalize-VersionTag {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    if ($Version.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Version
    }

    return 'v' + $Version
}

function Get-UpstreamGeneration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UpstreamPath,

        [Parameter(Mandatory = $true)]
        [string]$VersionMatrixPath
    )

    $matrix = Read-JsonHashtable -Path $VersionMatrixPath
    if (!($matrix.ContainsKey('generations'))) {
        throw "Version generation matrix is missing 'generations': $VersionMatrixPath"
    }

    $version = Get-VersionFromCommonProps -Root $UpstreamPath
    $normalizedVersion = Normalize-VersionTag -Version $version
    $matches = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($generation in @($matrix['generations'])) {
        $tagPrefixes = @($generation['tagPrefixes'])
        foreach ($tagPrefix in $tagPrefixes) {
            if ([string]::IsNullOrWhiteSpace($tagPrefix)) {
                continue
            }

            $normalizedPrefix = Normalize-VersionTag -Version $tagPrefix

            if ($normalizedVersion.StartsWith($normalizedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $matches.Add(@{
                    generation = $generation
                    normalizedPrefix = $normalizedPrefix
                })
            }
        }
    }

    if ($matches.Count -eq 0) {
        throw "No generation mapping matched upstream version '$version' using $VersionMatrixPath"
    }

    $maxPrefixLength = ($matches | ForEach-Object { $_['normalizedPrefix'].Length } | Measure-Object -Maximum).Maximum
    $bestMatches = @($matches | Where-Object { $_['normalizedPrefix'].Length -eq $maxPrefixLength })
    $bestGenerationNames = @(
        $bestMatches |
            ForEach-Object { $_['generation']['name'] } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    if ($bestGenerationNames.Count -gt 1) {
        $matchedPrefixes = @(
            $bestMatches |
                ForEach-Object { "{0} ({1})" -f $_['generation']['name'], $_['normalizedPrefix'] } |
                Sort-Object -Unique
        )

        throw "Ambiguous generation mapping matched upstream version '$version' using $VersionMatrixPath. Longest matching prefixes: $($matchedPrefixes -join ', ')"
    }

    $selectedGeneration = $bestMatches[0]['generation']

    return @{
        version = $version
        versionTag = $normalizedVersion
        generation = $selectedGeneration['name']
        targetFramework = $selectedGeneration['targetFramework']
        riskNotes = @($selectedGeneration['riskNotes'])
        defaultProfile = $matrix['defaultProfile']
    }
}

function Get-CsprojBaseNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    if (!(Test-Path -LiteralPath $Root)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.csproj' |
            ForEach-Object { $_.BaseName } |
            Sort-Object -Unique
    )
}

function Get-ProjectSurfaceDiff {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CurrentProjects,

        [Parameter(Mandatory = $true)]
        [string[]]$UpstreamProjects
    )

    $currentOnly = @(
        Compare-Object -ReferenceObject $UpstreamProjects -DifferenceObject $CurrentProjects |
            Where-Object { $_.SideIndicator -eq '=>' } |
            ForEach-Object { $_.InputObject } |
            Sort-Object -Unique
    )

    $upstreamOnly = @(
        Compare-Object -ReferenceObject $UpstreamProjects -DifferenceObject $CurrentProjects |
            Where-Object { $_.SideIndicator -eq '<=' } |
            ForEach-Object { $_.InputObject } |
            Sort-Object -Unique
    )

    return @{
        currentCount = $CurrentProjects.Count
        upstreamCount = $UpstreamProjects.Count
        onlyInCurrent = $currentOnly
        onlyInUpstream = $upstreamOnly
    }
}

function Get-PackageConfigSignals {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    if (!(Test-Path -LiteralPath $Root)) {
        return @()
    }

    $signalPattern = 'IdentityServer4|OpenIddict|Serilog|log4net|TargetFramework'
    $signals = New-Object System.Collections.Generic.List[string]

    foreach ($projectFile in @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.csproj')) {
        $matches = @(Select-String -LiteralPath $projectFile.FullName -Pattern $signalPattern -AllMatches)
        foreach ($match in $matches) {
            $relativePath = [System.IO.Path]::GetRelativePath($Root, $match.Path)
            $signals.Add(('{0}:{1}: {2}' -f $relativePath, $match.LineNumber, $match.Line.Trim()))
        }
    }

    return @($signals | Sort-Object -Unique)
}

function Add-MarkdownBulletList {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IList]$Lines,

        [string[]]$Items,

        [Parameter(Mandatory = $true)]
        [string]$EmptyMessage
    )

    if ($Items.Count -eq 0) {
        [void]$Lines.Add("- $EmptyMessage")
        return
    }

    foreach ($item in $Items) {
        [void]$Lines.Add("- $item")
    }
}

$resolvedUpstreamPath = Resolve-AbsolutePath -Path $UpstreamPath
$resolvedCurrentRoot = Resolve-AbsolutePath -Path $CurrentRoot
$resolvedVersionMatrixPath = Resolve-AbsolutePath -Path $VersionMatrixPath
$resolvedOutputPath = Resolve-AbsolutePath -Path $OutputPath

if (!(Test-Path -LiteralPath $resolvedUpstreamPath)) {
    throw "UpstreamPath does not exist: $resolvedUpstreamPath"
}

if (!(Test-Path -LiteralPath (Join-Path $resolvedUpstreamPath 'src'))) {
    throw "UpstreamPath does not contain src/: $resolvedUpstreamPath"
}

if (!(Test-Path -LiteralPath (Join-Path $resolvedCurrentRoot 'src'))) {
    throw "CurrentRoot does not contain src/: $resolvedCurrentRoot"
}

$upstreamGeneration = Get-UpstreamGeneration -UpstreamPath $resolvedUpstreamPath -VersionMatrixPath $resolvedVersionMatrixPath
$currentVersion = Get-VersionFromCommonProps -Root $resolvedCurrentRoot
$projectSurfaceDiff = Get-ProjectSurfaceDiff `
    -CurrentProjects (Get-CsprojBaseNames -Root (Join-Path $resolvedCurrentRoot 'src')) `
    -UpstreamProjects (Get-CsprojBaseNames -Root (Join-Path $resolvedUpstreamPath 'src'))
$packageSignals = Get-PackageConfigSignals -Root $resolvedUpstreamPath

$reportLines = [System.Collections.Generic.List[string]]::new()
[void]$reportLines.Add('# Yoyo.Abp ' + $upstreamGeneration['versionTag'] + ' Upgrade Radar')
[void]$reportLines.Add('')
[void]$reportLines.Add('- Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
[void]$reportLines.Add('- Upstream root: `' + $resolvedUpstreamPath + '`')
[void]$reportLines.Add('- Current root: `' + $resolvedCurrentRoot + '`')
[void]$reportLines.Add('- Current root version: `' + $currentVersion + '`')
[void]$reportLines.Add('')
[void]$reportLines.Add('## Upstream generation')
[void]$reportLines.Add('')
[void]$reportLines.Add('- Version: `' + $upstreamGeneration['version'] + '`')
[void]$reportLines.Add('- Generation: `' + $upstreamGeneration['generation'] + '`')
[void]$reportLines.Add('- Expected target framework: `' + $upstreamGeneration['targetFramework'] + '`')
[void]$reportLines.Add('- Default migration profile: `' + $upstreamGeneration['defaultProfile'] + '`')
[void]$reportLines.Add('')
[void]$reportLines.Add('## Risk notes')
[void]$reportLines.Add('')
Add-MarkdownBulletList -Lines $reportLines -Items @($upstreamGeneration['riskNotes']) -EmptyMessage 'No generation-specific risk notes were found.'
[void]$reportLines.Add('')
[void]$reportLines.Add('## Project surface diff')
[void]$reportLines.Add('')
[void]$reportLines.Add('- Current src project count: ' + $projectSurfaceDiff['currentCount'])
[void]$reportLines.Add('- Upstream src project count: ' + $projectSurfaceDiff['upstreamCount'])
[void]$reportLines.Add('')
[void]$reportLines.Add('### Only in current root')
[void]$reportLines.Add('')
Add-MarkdownBulletList -Lines $reportLines -Items @($projectSurfaceDiff['onlyInCurrent']) -EmptyMessage 'No current-only src project basenames detected.'
[void]$reportLines.Add('')
[void]$reportLines.Add('### Only in upstream')
[void]$reportLines.Add('')
Add-MarkdownBulletList -Lines $reportLines -Items @($projectSurfaceDiff['onlyInUpstream']) -EmptyMessage 'No upstream-only src project basenames detected.'
[void]$reportLines.Add('')
[void]$reportLines.Add('## Package/config signals')
[void]$reportLines.Add('')
Add-MarkdownBulletList -Lines $reportLines -Items $packageSignals -EmptyMessage 'No watched package/config signals detected in upstream .csproj files.'

$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (![string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

Set-Content -LiteralPath $resolvedOutputPath -Value ($reportLines -join [Environment]::NewLine) -Encoding UTF8
Write-Host "Upgrade radar written: $resolvedOutputPath"