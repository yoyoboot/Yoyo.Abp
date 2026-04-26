[CmdletBinding()]
param(
    [string]$BranchName,

    [string]$Channel,

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $repoRoot 'tools\yoyo-abp-migration\YoyoAbpVersioning.ps1')

function Get-FirstNonEmptyValue {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if (!([string]::IsNullOrWhiteSpace($candidate))) {
            return $candidate.Trim()
        }
    }

    return $null
}

function ConvertTo-BooleanOrDefault {
    param(
        [string]$Value,

        [bool]$Default = $false
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Default
    }

    return [System.Convert]::ToBoolean($Value)
}

$packFolder = [System.IO.Path]::GetFullPath($PSScriptRoot)
$distPath = [System.IO.Path]::GetFullPath((Get-FirstNonEmptyValue -Candidates @( 
    $env:DIST_PATH,
    (Join-Path $packFolder 'dist'))))
$fileName = [System.IO.Path]::GetFullPath((Get-FirstNonEmptyValue -Candidates @(
    $env:PUSH_FILE_NAME,
    (Join-Path $packFolder 'push.ps1'))))
$isProduction = ConvertTo-BooleanOrDefault -Value $env:IS_PRODUCTION

$resolvedChannel = Get-FirstNonEmptyValue -Candidates @(
    $Channel,
    $env:NUGET_CHANNEL,
    (Get-YoyoAbpPackageChannel -BranchName $BranchName))

if ([string]::IsNullOrWhiteSpace($resolvedChannel)) {
    $resolvedChannel = 'default'
}

$resolvedChannel = $resolvedChannel.ToLowerInvariant()

$source = $null
$apiKey = $null
$disableApiKey = $false

switch ($resolvedChannel) {
    'stable' {
        $source = Get-FirstNonEmptyValue -Candidates @($env:NUGET_STABLE_SOURCE, $env:NUGET_SOURCE, 'https://api.nuget.org/v3/index.json')
        $apiKey = Get-FirstNonEmptyValue -Candidates @($env:NUGET_STABLE_SOURCE_APIKEY, $env:NUGET_SOURCE_APIKEY, 'key')
        $disableApiKey = ConvertTo-BooleanOrDefault -Value (Get-FirstNonEmptyValue -Candidates @($env:NUGET_STABLE_DISABLE_API_KEY, $env:DISABLE_API_KEY))
        break
    }
    'validation' {
        $source = Get-FirstNonEmptyValue -Candidates @($env:NUGET_VALIDATION_SOURCE, $env:NUGET_SOURCE, 'https://api.nuget.org/v3/index.json')
        $apiKey = Get-FirstNonEmptyValue -Candidates @($env:NUGET_VALIDATION_SOURCE_APIKEY, $env:NUGET_SOURCE_APIKEY, 'key')
        $disableApiKey = ConvertTo-BooleanOrDefault -Value (Get-FirstNonEmptyValue -Candidates @($env:NUGET_VALIDATION_DISABLE_API_KEY, $env:DISABLE_API_KEY))
        break
    }
    default {
        $source = Get-FirstNonEmptyValue -Candidates @($env:NUGET_SOURCE, 'https://api.nuget.org/v3/index.json')
        $apiKey = Get-FirstNonEmptyValue -Candidates @($env:NUGET_SOURCE_APIKEY, 'key')
        $disableApiKey = ConvertTo-BooleanOrDefault -Value $env:DISABLE_API_KEY
        break
    }
}

$suffix = ' --source "' + $source + '" --api-key "' + $apiKey + '" --skip-duplicate'
if ($disableApiKey) {
    $suffix = ' --source "' + $source + '" --skip-duplicate'
}

Write-Host "Resolved package channel: $resolvedChannel" -ForegroundColor Blue
Write-Host "Resolved source: $source" -ForegroundColor Blue
Write-Host "Push file: $fileName" -ForegroundColor Blue
Write-Host "Dist path: $distPath" -ForegroundColor Blue
Write-Host "IS_PRODUCTION: $isProduction" -ForegroundColor Blue

if ($WhatIf) {
    Write-Host 'WhatIf: push plan rendered only; dotnet nuget push was not executed.' -ForegroundColor Yellow
    return
}

if (!(Test-Path -LiteralPath $distPath)) {
    throw "Missing dist path: $distPath"
}

$packageCommands = @(
    Get-ChildItem -LiteralPath $distPath -Filter '*.nupkg' -File |
        Sort-Object Name |
        ForEach-Object { 'dotnet nuget push "' + $_.FullName + '"' + $suffix }
)

if ($packageCommands.Count -eq 0) {
    throw "No .nupkg files found under $distPath"
}

$packageCommands | Set-Content -LiteralPath $fileName -Encoding UTF8

if ($isProduction) {
    & $fileName
}


