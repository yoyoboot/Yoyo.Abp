Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$packPath = Join-Path $repoRoot 'nupkg\pack.ps1'
$packPushPath = Join-Path $repoRoot 'nupkg\pack_push.ps1'
$gitlabCiPath = Join-Path $repoRoot '.gitlab-ci.yml'
$gitlabBranchCiPath = Join-Path $repoRoot '.gitlab\ci\module-nuget.branch-ci.yml'

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Snippet,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    if (!$Content.Contains($Snippet, [System.StringComparison]::Ordinal)) {
        throw "$Context is missing required snippet '$Snippet'."
    }
}

if (!(Test-Path -LiteralPath $packPath)) {
    throw "Missing pack script: $packPath"
}

if (!(Test-Path -LiteralPath $packPushPath)) {
    throw "Missing push script: $packPushPath"
}

$releasePackOutput = (& pwsh -NoLogo -NoProfile -Command @"
`$env:IS_PRODUCTION = 'true'
`$env:TAG = 'release/7.4'
`$env:CI_COMMIT_REF_NAME = 'release/7.4'
& '$packPath' -WhatIf
"@ 2>&1 | Out-String)
Assert-Contains -Content $releasePackOutput -Snippet 'Resolved package version: 7.4.0' -Context 'pack.ps1 release branch production invocation'

$verifyPackOutput = (& pwsh -NoLogo -NoProfile -Command @"
`$env:IS_PRODUCTION = 'true'
`$env:TAG = 'verify/7.4-yoyo-on-dev-7.3.0'
`$env:CI_COMMIT_REF_NAME = 'verify/7.4-yoyo-on-dev-7.3.0'
& '$packPath' -WhatIf
"@ 2>&1 | Out-String)
Assert-Contains -Content $verifyPackOutput -Snippet 'Resolved package version: 7.4.1' -Context 'pack.ps1 verify branch production invocation'

$releasePushOutput = (& pwsh -NoLogo -NoProfile -Command @"
`$env:IS_PRODUCTION = 'true'
`$env:CI_COMMIT_REF_NAME = 'release/7.4'
`$env:NUGET_STABLE_SOURCE = 'https://stable.example/v3/index.json'
`$env:NUGET_STABLE_SOURCE_APIKEY = 'stable-key'
`$env:NUGET_VALIDATION_SOURCE = 'https://validation.example/v3/index.json'
`$env:NUGET_VALIDATION_SOURCE_APIKEY = 'validation-key'
& '$packPushPath' -WhatIf
"@ 2>&1 | Out-String)
Assert-Contains -Content $releasePushOutput -Snippet 'Resolved package channel: stable' -Context 'pack_push.ps1 release branch invocation'
Assert-Contains -Content $releasePushOutput -Snippet 'Resolved source: https://stable.example/v3/index.json' -Context 'pack_push.ps1 release branch invocation'

$verifyPushOutput = (& pwsh -NoLogo -NoProfile -Command @"
`$env:IS_PRODUCTION = 'true'
`$env:CI_COMMIT_REF_NAME = 'verify/7.4-yoyo-on-dev-7.3.0'
`$env:NUGET_STABLE_SOURCE = 'https://stable.example/v3/index.json'
`$env:NUGET_STABLE_SOURCE_APIKEY = 'stable-key'
`$env:NUGET_VALIDATION_SOURCE = 'https://validation.example/v3/index.json'
`$env:NUGET_VALIDATION_SOURCE_APIKEY = 'validation-key'
& '$packPushPath' -WhatIf
"@ 2>&1 | Out-String)
Assert-Contains -Content $verifyPushOutput -Snippet 'Resolved package channel: validation' -Context 'pack_push.ps1 verify branch invocation'
Assert-Contains -Content $verifyPushOutput -Snippet 'Resolved source: https://validation.example/v3/index.json' -Context 'pack_push.ps1 verify branch invocation'

$explicitChannelOutput = (& pwsh -NoLogo -NoProfile -Command @"
`$env:IS_PRODUCTION = 'true'
`$env:NUGET_CHANNEL = 'validation'
`$env:NUGET_SOURCE = 'https://default.example/v3/index.json'
`$env:NUGET_SOURCE_APIKEY = 'default-key'
`$env:NUGET_VALIDATION_SOURCE = 'https://validation.example/v3/index.json'
`$env:NUGET_VALIDATION_SOURCE_APIKEY = 'validation-key'
& '$packPushPath' -WhatIf
"@ 2>&1 | Out-String)
Assert-Contains -Content $explicitChannelOutput -Snippet 'Resolved package channel: validation' -Context 'pack_push.ps1 explicit channel invocation'
Assert-Contains -Content $explicitChannelOutput -Snippet 'Resolved source: https://validation.example/v3/index.json' -Context 'pack_push.ps1 explicit channel invocation'

$gitlabCiContent = Get-Content -LiteralPath $gitlabCiPath -Raw -Encoding UTF8
Assert-Contains -Content $gitlabCiContent -Snippet '.gitlab/ci/module-nuget.branch-ci.yml' -Context '.gitlab-ci.yml include list'

$gitlabBranchCiContent = Get-Content -LiteralPath $gitlabBranchCiPath -Raw -Encoding UTF8
Assert-Contains -Content $gitlabBranchCiContent -Snippet 'release/' -Context 'branch ci release flow'
Assert-Contains -Content $gitlabBranchCiContent -Snippet 'verify/' -Context 'branch ci verify flow'
Assert-Contains -Content $gitlabBranchCiContent -Snippet 'NUGET_CHANNEL=stable' -Context 'branch ci stable channel export'
Assert-Contains -Content $gitlabBranchCiContent -Snippet 'NUGET_CHANNEL=validation' -Context 'branch ci validation channel export'

Write-Host 'Release publishing routes branch versions and package channels correctly.' -ForegroundColor Green
