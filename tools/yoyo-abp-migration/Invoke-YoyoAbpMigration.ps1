[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UpstreamPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$EngineRoot = (Join-Path $PSScriptRoot '..\proj-rename-ps\src2\abp-yoyo.abp-string-7.3'),

    [string]$LogPath = (Join-Path $PSScriptRoot 'logs\last-run.log'),

    [switch]$CleanOutput,

    [switch]$SkipEngineRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

    $pathComparison = if ($IsWindows) {
        [System.StringComparison]::OrdinalIgnoreCase
    }
    else {
        [System.StringComparison]::Ordinal
    }

function Resolve-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

    function Get-NormalizedPath {
        param([Parameter(Mandatory = $true)][string]$Path)

        [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    }

    function Test-IsSameOrChildPath {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$ParentPath
        )

        $normalizedPath = Get-NormalizedPath $Path
        $normalizedParentPath = Get-NormalizedPath $ParentPath

        if ($normalizedPath.Equals($normalizedParentPath, $pathComparison)) {
            return $true
        }

        return $normalizedPath.StartsWith($normalizedParentPath + [System.IO.Path]::DirectorySeparatorChar, $pathComparison) -or
            $normalizedPath.StartsWith($normalizedParentPath + [System.IO.Path]::AltDirectorySeparatorChar, $pathComparison)
    }

    function Copy-DirectoryContents {
        param(
            [Parameter(Mandatory = $true)][string]$SourceRoot,
            [Parameter(Mandatory = $true)][string]$DestinationRoot,
            [string]$ExcludePath
        )

        $items = @(Get-ChildItem -LiteralPath $SourceRoot -Force -Recurse)
        if ($ExcludePath) {
            $items = @($items | Where-Object { -not (Test-IsSameOrChildPath -Path $_.FullName -ParentPath $ExcludePath) })
        }

        foreach ($directory in @($items | Where-Object { $_.PSIsContainer } | Sort-Object -Property FullName)) {
            $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $directory.FullName)
            New-Item -ItemType Directory -Force (Join-Path $DestinationRoot $relativePath) | Out-Null
        }

        foreach ($file in @($items | Where-Object { -not $_.PSIsContainer })) {
            $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $file.FullName)
            $destinationPath = Join-Path $DestinationRoot $relativePath

            New-Item -ItemType Directory -Force (Split-Path -Parent $destinationPath) | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        }
    }

    function Sync-TopLevelFiles {
        param(
            [Parameter(Mandatory = $true)][string]$SourceRoot,
            [Parameter(Mandatory = $true)][string]$DestinationRoot,
            [string[]]$FileNames
        )

        $files = @(Get-ChildItem -LiteralPath $SourceRoot -Force -File)
        if ($FileNames -and $FileNames.Count -gt 0) {
            $allowedFileNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($fileName in $FileNames) {
                [void]$allowedFileNames.Add($fileName)
            }

            $files = @($files | Where-Object { $allowedFileNames.Contains($_.Name) })
        }

        foreach ($file in $files) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $DestinationRoot $file.Name) -Force
        }
    }

$resolvedUpstreamPath = Resolve-FullPath $UpstreamPath
$resolvedOutputPath = Resolve-FullPath $OutputPath
$resolvedEngineRoot = Resolve-FullPath $EngineRoot
$resolvedLogPath = Resolve-FullPath $LogPath

if (!(Test-Path $resolvedUpstreamPath)) {
    throw "UpstreamPath does not exist: $resolvedUpstreamPath"
}

if (!(Test-Path (Join-Path $resolvedUpstreamPath 'Abp.sln'))) {
    throw "UpstreamPath is not an aspnetboilerplate source root: $resolvedUpstreamPath"
}

if (!(Test-Path (Join-Path $resolvedEngineRoot 'run.ps1'))) {
    throw "Migration engine run.ps1 not found under: $resolvedEngineRoot"
}

if ((Get-NormalizedPath $resolvedOutputPath).Equals((Get-NormalizedPath $resolvedUpstreamPath), $pathComparison)) {
    throw "OutputPath must be different from UpstreamPath: $resolvedOutputPath"
}

if (Test-IsSameOrChildPath -Path $resolvedUpstreamPath -ParentPath $resolvedOutputPath) {
    throw "OutputPath cannot contain UpstreamPath: $resolvedOutputPath"
}

if (Test-Path $resolvedOutputPath) {
    if (!$CleanOutput) {
        throw "OutputPath already exists. Re-run with -CleanOutput to replace it: $resolvedOutputPath"
    }

    Remove-Item -Path $resolvedOutputPath -Recurse -Force
}

New-Item -ItemType Directory -Force $resolvedOutputPath | Out-Null
New-Item -ItemType Directory -Force (Split-Path -Parent $resolvedLogPath) | Out-Null

Write-Host "Copy upstream source"
$copyExclusionPath = $null
if (Test-IsSameOrChildPath -Path $resolvedOutputPath -ParentPath $resolvedUpstreamPath) {
    $copyExclusionPath = $resolvedOutputPath
    Write-Host "Exclude output subtree from copy: $resolvedOutputPath"
}

Copy-DirectoryContents -SourceRoot $resolvedUpstreamPath -DestinationRoot $resolvedOutputPath -ExcludePath $copyExclusionPath
Sync-TopLevelFiles -SourceRoot $resolvedUpstreamPath -DestinationRoot $resolvedOutputPath

if ($SkipEngineRun) {
    Write-Host "SkipEngineRun is set. Output contains copied upstream source only."
    return
}

Write-Host "Run migration engine"
Push-Location $resolvedEngineRoot
try {
    & .\run.ps1 -Src $resolvedOutputPath 2>&1 | Tee-Object -FilePath $resolvedLogPath
    if ($LASTEXITCODE -ne 0) {
        throw "Migration engine failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Sync-TopLevelFiles -SourceRoot $resolvedUpstreamPath -DestinationRoot $resolvedOutputPath -FileNames @('LICENSE.md')

Write-Host "Migration output: $resolvedOutputPath"
Write-Host "Migration log: $resolvedLogPath"
