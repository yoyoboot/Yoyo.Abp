Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$scriptPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\Invoke-YoyoAbpDownstreamSmoke.ps1'
$configPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\config\downstream-smoke-targets.json'
$packageSource = 'C:\temp\feed with spaces'

if (!(Test-Path $scriptPath)) {
    throw "Missing smoke script: $scriptPath"
}

if (!(Test-Path $configPath)) {
    throw "Missing smoke config: $configPath"
}

$output = & pwsh -File $scriptPath -ConfigPath $configPath -PackageVersion '9.4.2-preview' -PackageSource $packageSource -WhatIf 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "Smoke plan WhatIf failed unexpectedly. Output:`n$output"
}

if ($output -notmatch '\[WhatIf\] Rendered command template only; repoRoot/solution existence not validated\.') {
    throw 'Smoke plan did not explain the WhatIf preview boundary.'
}

if ($output -notmatch '\[YoyoBoot\]') {
    throw 'Smoke plan did not render the YoyoBoot target name.'
}

if ($output -notmatch '\[RiderAspNetCore\]') {
    throw 'Smoke plan did not render the RiderAspNetCore target name.'
}

if ($output -notmatch 'dotnet restore') {
    throw 'Smoke plan did not render a restore command.'
}

if ($output -notmatch 'dotnet build') {
    throw 'Smoke plan did not render a build command.'
}

if ($output -notmatch 'YoyoAbpVersion=9\.4\.2-preview') {
    throw 'Smoke plan did not render the package version property override.'
}

if ($output -notmatch 'RestoreAdditionalProjectSources=C:\\temp\\feed with spaces') {
    throw 'Smoke plan did not render the additional restore source override.'
}

$tempConfigPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName() + '.json')
try {
    Set-Content -LiteralPath $tempConfigPath -Value '{"targets":[]}' -Encoding UTF8

    $negativeOutput = & pwsh -File $scriptPath -ConfigPath $tempConfigPath -PackageVersion '9.4.2-preview' -PackageSource $packageSource -WhatIf 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        throw "Smoke plan unexpectedly accepted an empty targets config. Output:`n$negativeOutput"
    }

    if ($negativeOutput -notmatch 'Smoke config does not define any targets') {
        throw "Smoke plan returned an unexpected empty-targets error. Output:`n$negativeOutput"
    }
}
finally {
    if (Test-Path -LiteralPath $tempConfigPath) {
        Remove-Item -LiteralPath $tempConfigPath -Force
    }
}

Write-Host 'Downstream smoke script renders both target command templates.' -ForegroundColor Green
