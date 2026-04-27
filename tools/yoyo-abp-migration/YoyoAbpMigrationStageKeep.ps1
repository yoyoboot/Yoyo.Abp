Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Copy-YoyoAbpDirectoryRecursively {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (!(Test-Path -LiteralPath $SourcePath)) {
        throw "Stage-keep source path does not exist: $SourcePath"
    }

    New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null

    Get-ChildItem -LiteralPath $SourcePath -Force -Recurse | ForEach-Object {
        $relativePath = [System.IO.Path]::GetRelativePath($SourcePath, $_.FullName)
        $targetPath = Join-Path $DestinationPath $relativePath

        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
        }
        else {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPath) | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $targetPath -Force
        }
    }
}

function Add-YoyoAbpProjectToSolutionIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SolutionPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    if (!(Test-Path -LiteralPath $SolutionPath)) {
        throw "Stage-keep solution path does not exist: $SolutionPath"
    }

    if (!(Test-Path -LiteralPath $ProjectPath)) {
        throw "Stage-keep project path does not exist: $ProjectPath"
    }

    $relativeProjectPath = [System.IO.Path]::GetRelativePath((Split-Path -Parent $SolutionPath), $ProjectPath)
    $solutionList = (& dotnet sln $SolutionPath list | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet sln list failed for solution: $SolutionPath"
    }

    if ($solutionList.Contains($relativeProjectPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return
    }

    & dotnet sln $SolutionPath add $ProjectPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet sln add failed for project: $ProjectPath"
    }
}

function Restore-YoyoAbpStageKeepProjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$OutputRoot,

        [Parameter(Mandatory = $true)]
        [string[]]$ProjectNames
    )

    $solutionPath = Join-Path $OutputRoot 'Abp.sln'
    foreach ($projectName in $ProjectNames) {
        $sourceProjectRoot = Join-Path $RepoRoot (Join-Path 'src' $projectName)
        $sourceProjectFile = Join-Path $sourceProjectRoot ($projectName + '.csproj')
        $outputProjectRoot = Join-Path $OutputRoot (Join-Path 'src' $projectName)
        $outputProjectFile = Join-Path $outputProjectRoot ($projectName + '.csproj')

        if (Test-Path -LiteralPath $outputProjectFile) {
            continue
        }

        if (!(Test-Path -LiteralPath $sourceProjectFile)) {
            throw "Stage-keep source project is missing from repo root: $sourceProjectFile"
        }

        Write-Host "Restore stage-keep project: $projectName"
        Copy-YoyoAbpDirectoryRecursively -SourcePath $sourceProjectRoot -DestinationPath $outputProjectRoot
        Add-YoyoAbpProjectToSolutionIfMissing -SolutionPath $solutionPath -ProjectPath $outputProjectFile
    }
}
