[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $true)]
    [string]$PackageVersion,

    [Parameter(Mandatory = $true)]
    [string]$PackageSource,

    [switch]$WhatIf
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

function Read-DownstreamSmokeConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolvedPath = Resolve-AbsolutePath -Path $Path
    if (!(Test-Path -LiteralPath $resolvedPath)) {
        throw "Missing smoke config: $resolvedPath"
    }

    try {
        $config = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    }
    catch {
        throw "Failed to parse smoke config: $resolvedPath. $($_.Exception.Message)"
    }

    if ($null -eq $config -or !($config.ContainsKey('targets')) -or @($config['targets']).Count -eq 0) {
        throw "Smoke config does not define any targets: $resolvedPath"
    }

    return $config
}

function Format-CommandArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value -match '[\s"]') {
        return '"' + $Value.Replace('"', '\"') + '"'
    }

    return $Value
}

function Get-TargetCommands {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Target,

        [Parameter(Mandatory = $true)]
        [string]$ResolvedPackageVersion,

        [Parameter(Mandatory = $true)]
        [string]$ResolvedPackageSource
    )

    foreach ($requiredKey in @('name', 'repoRoot', 'solution', 'versionProperty')) {
        if ([string]::IsNullOrWhiteSpace($Target[$requiredKey])) {
            throw "Smoke target is missing required field '$requiredKey'."
        }
    }

    $solutionPath = Join-Path $Target['repoRoot'] $Target['solution']
    $versionArgument = "-p:$($Target['versionProperty'])=$ResolvedPackageVersion"
    $sourceArgument = "-p:RestoreAdditionalProjectSources=$ResolvedPackageSource"

    return @{
        Name = [string]$Target['name']
        RepoRoot = [string]$Target['repoRoot']
        SolutionPath = $solutionPath
        RestoreArgs = @('restore', $solutionPath, $versionArgument, $sourceArgument)
        BuildArgs = @('build', $solutionPath, '-c', 'Debug', '--no-restore', $versionArgument, $sourceArgument)
        RestoreDisplay = 'dotnet ' + ((@('restore', (Format-CommandArgument -Value $solutionPath), $versionArgument, (Format-CommandArgument -Value $sourceArgument)) -join ' '))
        BuildDisplay = 'dotnet ' + ((@('build', (Format-CommandArgument -Value $solutionPath), '-c', 'Debug', '--no-restore', $versionArgument, (Format-CommandArgument -Value $sourceArgument)) -join ' '))
    }
}

$config = Read-DownstreamSmokeConfig -Path $ConfigPath

if ($WhatIf) {
    Write-Host '[WhatIf] Rendered command template only; repoRoot/solution existence not validated.'
}

foreach ($target in @($config['targets'])) {
    $commands = Get-TargetCommands -Target $target -ResolvedPackageVersion $PackageVersion -ResolvedPackageSource $PackageSource

    if ($WhatIf) {
        Write-Host "[$($commands['Name'])] $($commands['RestoreDisplay'])"
        Write-Host "[$($commands['Name'])] $($commands['BuildDisplay'])"
        continue
    }

    if (!(Test-Path -LiteralPath $commands['RepoRoot'])) {
        throw "Target repo root does not exist: $($commands['RepoRoot'])"
    }

    if (!(Test-Path -LiteralPath $commands['SolutionPath'])) {
        throw "Target solution does not exist: $($commands['SolutionPath'])"
    }

    Push-Location $commands['RepoRoot']
    try {
        & dotnet @($commands['RestoreArgs'])
        if ($LASTEXITCODE -ne 0) {
            throw "Restore failed for $($commands['Name'])"
        }

        & dotnet @($commands['BuildArgs'])
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed for $($commands['Name'])"
        }
    }
    finally {
        Pop-Location
    }
}
