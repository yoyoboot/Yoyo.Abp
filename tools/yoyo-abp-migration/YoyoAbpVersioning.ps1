Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Normalize-YoyoAbpBranchName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )

    $normalizedBranchName = $BranchName.Trim()
    foreach ($prefix in @('refs/heads/', 'refs/remotes/origin/', 'origin/')) {
        if ($normalizedBranchName.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $normalizedBranchName = $normalizedBranchName.Substring($prefix.Length)
            break
        }
    }

    return $normalizedBranchName
}

function ConvertTo-YoyoAbpThreeSegmentVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VersionText
    )

    $segments = @($VersionText.Split('.', [System.StringSplitOptions]::RemoveEmptyEntries))
    if ($segments.Count -eq 2) {
        return "$($segments[0]).$($segments[1]).0"
    }

    if ($segments.Count -eq 3) {
        return "$($segments[0]).$($segments[1]).$($segments[2])"
    }

    throw "Version '$VersionText' must use either major.minor or major.minor.patch format."
}

function Get-YoyoAbpVerifyPackageVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseVersion
    )

    $normalizedVersion = ConvertTo-YoyoAbpThreeSegmentVersion -VersionText $BaseVersion
    $segments = @($normalizedVersion.Split('.'))
    $patchVersion = [int]$segments[2] + 1
    return "$($segments[0]).$($segments[1]).$patchVersion"
}

function Get-CommonPropsVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommonPropsPath
    )

    if (!(Test-Path -LiteralPath $CommonPropsPath)) {
        throw "Missing common.props file: $CommonPropsPath"
    }

    [xml]$xml = Get-Content -LiteralPath $CommonPropsPath
    $versionNode = $xml.SelectSingleNode('//Version')
    if ($null -eq $versionNode -or [string]::IsNullOrWhiteSpace($versionNode.'#text')) {
        throw "common.props does not contain a Version node: $CommonPropsPath"
    }

    return $versionNode.'#text'
}

function Set-CommonPropsVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommonPropsPath,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    if (!(Test-Path -LiteralPath $CommonPropsPath)) {
        throw "Missing common.props file: $CommonPropsPath"
    }

    [xml]$xml = Get-Content -LiteralPath $CommonPropsPath
    $versionNode = $xml.SelectSingleNode('//Version')
    if ($null -eq $versionNode) {
        throw "common.props does not contain a Version node: $CommonPropsPath"
    }

    $versionNode.'#text' = $Version
    $xml.Save($CommonPropsPath)
}

function Get-YoyoAbpCurrentBranchName {
    [CmdletBinding()]
    param(
        [string]$BranchName
    )

    if (!([string]::IsNullOrWhiteSpace($BranchName))) {
        return (Normalize-YoyoAbpBranchName -BranchName $BranchName)
    }

    foreach ($environmentVariableName in @('BUILD_SOURCEBRANCH', 'GITHUB_REF_NAME', 'CI_COMMIT_REF_NAME', 'APPVEYOR_REPO_BRANCH', 'BRANCH_NAME')) {
        $environmentValue = [Environment]::GetEnvironmentVariable($environmentVariableName)
        if (!([string]::IsNullOrWhiteSpace($environmentValue))) {
            return (Normalize-YoyoAbpBranchName -BranchName $environmentValue)
        }
    }

    try {
        $gitBranch = (& git rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and !([string]::IsNullOrWhiteSpace($gitBranch))) {
            return (Normalize-YoyoAbpBranchName -BranchName $gitBranch)
        }
    }
    catch {
    }

    return $null
}

function Get-YoyoAbpPackageVersion {
    [CmdletBinding()]
    param(
        [string]$ExplicitVersion,
        [string]$BranchName,
        [Parameter(Mandatory = $true)]
        [string]$CommonPropsPath
    )

    if (!([string]::IsNullOrWhiteSpace($ExplicitVersion))) {
        return $ExplicitVersion.Trim()
    }

    $resolvedBranchName = Get-YoyoAbpCurrentBranchName -BranchName $BranchName
    if (!([string]::IsNullOrWhiteSpace($resolvedBranchName))) {
        if ($resolvedBranchName.StartsWith('release/', [System.StringComparison]::OrdinalIgnoreCase)) {
            $releaseVersion = $resolvedBranchName.Substring('release/'.Length)
            return (ConvertTo-YoyoAbpThreeSegmentVersion -VersionText $releaseVersion)
        }

        if ($resolvedBranchName.StartsWith('verify/', [System.StringComparison]::OrdinalIgnoreCase)) {
            $verifyVersionToken = $resolvedBranchName.Substring('verify/'.Length)
            $pivot = $verifyVersionToken.IndexOf('-yoyo-on-', [System.StringComparison]::OrdinalIgnoreCase)
            if ($pivot -ge 0) {
                $verifyVersionToken = $verifyVersionToken.Substring(0, $pivot)
            }

            return (Get-YoyoAbpVerifyPackageVersion -BaseVersion $verifyVersionToken)
        }
    }

    return (Get-CommonPropsVersion -CommonPropsPath $CommonPropsPath)
}

function Get-YoyoAbpPackageChannel {
    [CmdletBinding()]
    param(
        [string]$BranchName
    )

    $resolvedBranchName = Get-YoyoAbpCurrentBranchName -BranchName $BranchName
    if (!([string]::IsNullOrWhiteSpace($resolvedBranchName))) {
        if ($resolvedBranchName.StartsWith('release/', [System.StringComparison]::OrdinalIgnoreCase)) {
            return 'stable'
        }

        if ($resolvedBranchName.StartsWith('verify/', [System.StringComparison]::OrdinalIgnoreCase)) {
            return 'validation'
        }
    }

    return 'default'
}
