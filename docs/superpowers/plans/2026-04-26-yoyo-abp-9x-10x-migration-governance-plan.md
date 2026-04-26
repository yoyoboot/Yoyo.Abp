# Yoyo.Abp 9.x / 10.x Migration Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `proj-rename-ps` 强化为版本感知的迁移治理引擎，先固化 `profile-33-compat`、`v9.4.2` 输入扫描、下游 smoke 模板与 `Log4Net` 退役候选账本，再为后续 `v10.x / .NET 9` 建立前置门禁。

**Architecture:** 本计划不直接实施 `v9.4.2` 框架迁移，而是在现有 `v7.4` 闭环成果之上补齐治理层：用 JSON 清单替代硬编码包面和禁入项，用版本代际矩阵驱动引擎行为，用 upgrade radar 和 downstream smoke 模板前移问题分类，再把 `Log4Net` 与 `v10.x` 风险收敛为显式文档资产。执行策略保持兼容优先：先稳住当前 33 包线，再把瘦身治理作为独立可验证动作推进。

**Tech Stack:** PowerShell、JSON manifests、Git、Markdown、.NET SDK 6/8/9 元数据、ASP.NET Boilerplate upstream tags、现有 `tools/proj-rename-ps` 与 `tools/yoyo-abp-migration`

---

## Scope check

本计划只实现一个子系统：**9.x / 10.x 迁移治理层**。它覆盖：

1. `proj-rename-ps` 的规则清单化；
2. `profile-33-compat` 与 legacy exclusion 的单一事实源；
3. `v9.4.2 / .NET 8` 的输入扫描与差异报告；
4. 下游 smoke 模板化；
5. `Log4Net` 退役候选账本；
6. `v10.x / .NET 9` 前置门禁文档。

本计划**不**执行 `v9.4.2` 真实迁移，也**不**删除 `Yoyo.Abp.Castle.Log4Net`，更**不**收缩当前 33 包兼容面。

## Critical findings to preserve

- 当前兼容线固定为 33 个 `Yoyo.Abp.*` 包，`profile-33-compat` 是首个正式 profile。
- `string` 默认主键是永久差异，不能在 v9/v10 代际回退到 upstream 的 `int` 世界观。
- `v9.0`/`v9.4.2` 属于 `.NET 8` 代际，`v10.0`/`v10.3` 属于 `.NET 9` 代际；`v10.x` 不能被错误标记为 `.NET 10`。
- `Yoyo.Abp.Castle.Log4Net` 当前是高优先级退役候选，但仍存在主仓、`YoyoBoot`、`Rider` 的真实消费点，当前不能删除。
- 所有迁移候选都必须继续经过主仓 validator、package smoke、`YoyoBoot` smoke、`Rider` smoke；下游 smoke 不能再次退化为最后补跑。

## File map

### Create

- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/library-profile-33-compat.json` — 33 包兼容线的类库项目清单与 pack 清单。
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/test-profile-33-compat.json` — 当前兼容线测试项目清单。
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/version-generations.json` — `v7/v9/v10` 代际映射与风险注记。
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/legacy-package-exclusions.json` — legacy 包禁入名单。
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/engine_config.ps1` — JSON 清单加载入口。
- `tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1` — 对 upstream 输入执行差异扫描并输出报告。
- `tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1` — 用模板执行或预览下游 smoke。
- `tools/yoyo-abp-migration/config/downstream-smoke-targets.json` — 下游 smoke 目标、solution、参数模板。
- `tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1` — 校验 profile 与当前 33 包面一致。
- `tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1` — 校验引擎入口已接入 manifest。
- `tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1` — 校验代际矩阵与 radar 输出。
- `tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1` — 校验 smoke 模板脚本生成预期命令。
- `docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md` — `v9.4.2` 输入差异扫描报告。
- `docs/superpowers/reports/2026-04-26-yoyo-abp-log4net-retirement-candidate-ledger.md` — `Log4Net` 退役候选账本。
- `docs/superpowers/reports/2026-04-26-yoyo-abp-v10x-pre-gates.md` — `v10.x / .NET 9` 前置门禁清单。

### Modify

- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1` — 用 manifest 替换硬编码项目数组。
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/validate_output.ps1` — 用 manifest / legacy exclusion 清单替换内联常量。
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/README.md` — 记录 config 目录、profile 和代际矩阵。
- `tools/yoyo-abp-migration/README.md` — 记录 upgrade radar 与 downstream smoke 入口。

### External inputs

- `https://github.com/aspnetboilerplate/aspnetboilerplate/` — upstream 源。
- `C:\Code\yoyoboot\YoyoBoot` — 下游 smoke 目标 1。
- `C:\Code\gitea\Rider\src\aspnet-core` — 下游 smoke 目标 2。

---

### Task 1: Manifest the 33-package compatibility profile

**Files:**
- Create: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/library-profile-33-compat.json`
- Create: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/test-profile-33-compat.json`
- Create: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/version-generations.json`
- Create: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/legacy-package-exclusions.json`
- Test: `tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1`

- [ ] **Step 1: Write the failing profile test**

Create `tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1` with this content:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

$libraryProjects = @($libraryProfile.libraryProjects | Sort-Object -Unique)
$currentProjects = @(
    Get-ChildItem (Join-Path $repoRoot 'src') -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName ($_.Name + '.csproj')) } |
        ForEach-Object Name |
        Sort-Object -Unique
)

$packProjects = @(
    [regex]::Matches((Get-Content $packScriptPath -Raw), '"(Abp[^"\r\n]*)"') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
)

$testProjects = @($testProfile.testProjects | Sort-Object -Unique)
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

if (Compare-Object $libraryProjects $packProjects) {
    throw 'library-profile-33-compat.json does not match current nupkg/pack.ps1 project list.'
}

if (Compare-Object $testProjects $currentTestProjects) {
    throw 'test-profile-33-compat.json does not match current test project surface.'
}

Write-Host 'Profile 33 compatibility manifest matches current src/test/pack surface.' -ForegroundColor Green
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1
```

Expected:
- FAIL with `Missing library profile` because the config files do not exist yet.

- [ ] **Step 3: Create the compatibility manifests**

Create `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/library-profile-33-compat.json`:

```json
{
  "profileName": "33-compat",
  "packageIdentityPrefix": "Yoyo.Abp",
  "libraryProjects": [
    "Abp",
    "Abp.Web.Common",
    "Abp.AspNetCore",
    "Abp.AspNetCore.OData",
    "Abp.RedisCache",
    "Abp.RedisCache.ProtoBuf",
    "Abp.AspNetCore.PerRequestRedisCache",
    "Abp.AspNetCore.SignalR",
    "Abp.TestBase",
    "Abp.AspNetCore.TestBase",
    "Abp.AutoMapper",
    "Abp.Castle.Log4Net",
    "Abp.Dapper",
    "Abp.EntityFramework.Common",
    "Abp.EntityFramework",
    "Abp.EntityFrameworkCore",
    "Abp.EntityFrameworkCore.EFPlus",
    "Abp.FluentValidation",
    "Abp.HangFire",
    "Abp.HangFire.AspNetCore",
    "Abp.MailKit",
    "Abp.MemoryDb",
    "Abp.MongoDB",
    "Abp.Quartz",
    "Abp.Zero.Common",
    "Abp.Zero.Ldap",
    "Abp.ZeroCore",
    "Abp.ZeroCore.EntityFramework",
    "Abp.ZeroCore.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4",
    "Abp.ZeroCore.IdentityServer4.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4.vNext",
    "Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore"
  ],
  "packProjects": [
    "Abp",
    "Abp.AspNetCore",
    "Abp.AspNetCore.OData",
    "Abp.AspNetCore.SignalR",
    "Abp.AspNetCore.TestBase",
    "Abp.AspNetCore.PerRequestRedisCache",
    "Abp.AutoMapper",
    "Abp.Castle.Log4Net",
    "Abp.Dapper",
    "Abp.EntityFramework",
    "Abp.EntityFramework.Common",
    "Abp.EntityFrameworkCore",
    "Abp.EntityFrameworkCore.EFPlus",
    "Abp.FluentValidation",
    "Abp.HangFire",
    "Abp.HangFire.AspNetCore",
    "Abp.MailKit",
    "Abp.MemoryDb",
    "Abp.MongoDB",
    "Abp.RedisCache",
    "Abp.RedisCache.ProtoBuf",
    "Abp.Quartz",
    "Abp.TestBase",
    "Abp.Web.Common",
    "Abp.Zero.Common",
    "Abp.Zero.Ldap",
    "Abp.ZeroCore",
    "Abp.ZeroCore.EntityFramework",
    "Abp.ZeroCore.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4",
    "Abp.ZeroCore.IdentityServer4.EntityFrameworkCore",
    "Abp.ZeroCore.IdentityServer4.vNext",
    "Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore"
  ]
}
```

Create `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/test-profile-33-compat.json`:

```json
{
  "profileName": "33-compat-tests",
  "testProjects": [
    "Abp.AspNetCore.Tests",
    "Abp.AutoMapper.Tests",
    "Abp.Castle.Log4Net.Tests",
    "Abp.Dapper.Tests",
    "Abp.EntityFramework.Tests",
    "Abp.EntityFrameworkCore.Dapper.Tests",
    "Abp.EntityFrameworkCore.Tests",
    "Abp.MailKit.Tests",
    "Abp.MemoryDb.Tests",
    "Abp.Quartz.Tests",
    "Abp.RedisCache.Tests",
    "Abp.TestBase.Tests",
    "Abp.Tests",
    "Abp.Web.Common.Tests",
    "Abp.ZeroCore.IdentityServer4.Tests",
    "Abp.ZeroCore.SampleApp",
    "Abp.ZeroCore.Tests"
  ]
}
```

Create `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/version-generations.json`:

```json
{
  "defaultProfile": "33-compat",
  "generations": [
    {
      "name": "v7-net6",
      "tagPrefixes": ["v7."],
      "targetFramework": "net6.0",
      "riskNotes": [
        "Use current 33-package baseline as reference.",
        "Keep string primary key rules locked."
      ]
    },
    {
      "name": "v9-net8",
      "tagPrefixes": ["v9."],
      "targetFramework": "net8.0",
      "riskNotes": [
        "Expect upstream authentication and template drift.",
        "Treat Abp.ZeroCore.IdentityServer4 removal as explicit radar signal."
      ]
    },
    {
      "name": "v10-net9",
      "tagPrefixes": ["v10."],
      "targetFramework": "net9.0",
      "riskNotes": [
        "Do not interpret v10.x as .NET 10.",
        "Require v9.4.2-stable governance output before entering this generation."
      ]
    }
  ]
}
```

Create `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/legacy-package-exclusions.json`:

```json
{
  "exactProjectNames": [
    "Abp.Web",
    "Abp.Web.Api",
    "Abp.Web.Mvc",
    "Abp.Web.SignalR",
    "Abp.Web.Resources",
    "Abp.Zero",
    "Abp.Zero.EntityFramework",
    "Abp.Zero.NHibernate",
    "Abp.Zero.Owin"
  ],
  "tokenPatterns": [
    "NHibernate",
    "Owin",
    "GraphDiff",
    "FluentMigrator"
  ]
}
```

- [ ] **Step 4: Run the profile test to verify it passes**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1
```

Expected:
- PASS with `Profile 33 compatibility manifest matches current src/test/pack surface.`

- [ ] **Step 5: Commit the config baseline**

Run:

```powershell
git add tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1
git commit -m "test: manifest current 33-package compatibility profile"
```

Expected:
- Commit contains only the new config files and the profile test.

---

### Task 2: Wire the engine and validator to the manifests

**Files:**
- Create: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/engine_config.ps1`
- Modify: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1`
- Modify: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/validate_output.ps1`
- Test: `tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1`

- [ ] **Step 1: Write the failing integration test**

Create `tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1` with this content:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$runPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\run.ps1'
$validatorPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\validate_output.ps1'
$runContent = Get-Content $runPath -Raw
$validatorContent = Get-Content $validatorPath -Raw

if ($runContent -notmatch 'engine_config\.ps1') {
    throw 'run.ps1 does not load engine_config.ps1.'
}

if ($runContent -notmatch 'Get-LibraryProfile33Compat') {
    throw 'run.ps1 does not use the manifest-backed library profile.'
}

if ($runContent -notmatch 'Get-TestProfile33Compat') {
    throw 'run.ps1 does not use the manifest-backed test profile.'
}

if ($validatorContent -notmatch 'LegacyExclusionConfig') {
    throw 'validate_output.ps1 does not accept manifest-backed legacy exclusions.'
}

Write-Host 'run.ps1 and validate_output.ps1 are wired to manifest-backed config.' -ForegroundColor Green
```

- [ ] **Step 2: Run the integration test to verify it fails**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1
```

Expected:
- FAIL with `run.ps1 does not load engine_config.ps1.`

- [ ] **Step 3: Create the manifest loader**

Create `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/engine_config.ps1` with this content:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MigrationConfigRoot {
    param([string]$ScriptRoot = $PSScriptRoot)

    return (Join-Path $ScriptRoot 'config')
}

function Read-MigrationJsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigRoot,
        [Parameter(Mandatory = $true)][string]$FileName
    )

    $path = Join-Path $ConfigRoot $FileName
    if (!(Test-Path -LiteralPath $path)) {
        throw "Missing migration config file: $path"
    }

    return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable)
}

function Get-LibraryProfile33Compat {
    param([string]$ConfigRoot = (Get-MigrationConfigRoot))

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'library-profile-33-compat.json')
}

function Get-TestProfile33Compat {
    param([string]$ConfigRoot = (Get-MigrationConfigRoot))

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'test-profile-33-compat.json')
}

function Get-VersionGenerationMatrix {
    param([string]$ConfigRoot = (Get-MigrationConfigRoot))

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'version-generations.json')
}

function Get-LegacyPackageExclusions {
    param([string]$ConfigRoot = (Get-MigrationConfigRoot))

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'legacy-package-exclusions.json')
}
```

- [ ] **Step 4: Replace hard-coded arrays in `run.ps1` and `validate_output.ps1`**

Modify `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1` by adding the config loader and replacing the hard-coded arrays:

```powershell
. (Join-Path $scriptRoot 'engine_config.ps1')
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'process_lib.ps1')
. (Join-Path $scriptRoot 'process_test.ps1')
. (Join-Path $scriptRoot 'process_test_demo.ps1')
. (Join-Path $scriptRoot 'validate_output.ps1')

$configRoot = Join-Path $scriptRoot 'config'
$libraryProfile = Get-LibraryProfile33Compat -ConfigRoot $configRoot
$testProfile = Get-TestProfile33Compat -ConfigRoot $configRoot
$legacyPackageExclusions = Get-LegacyPackageExclusions -ConfigRoot $configRoot

$rootPath = "${Src}\src\"
$libraryProjectNames = @($libraryProfile.libraryProjects)
RmLib -rootPath $rootPath -projNames $libraryProjectNames
RunLib -rootPath $rootPath -projNames $libraryProjectNames

$rootPath = "${Src}\test\"
$testProjectNames = @($testProfile.testProjects)
RmLib -rootPath $rootPath -projNames $testProjectNames
RunTest -rootPath $rootPath -projNames $testProjectNames

Assert-MigrationOutput -Src $Src -ExpectedLibraryProjectNames $libraryProjectNames -LegacyExclusionConfig $legacyPackageExclusions
```

Modify the validator signatures in `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/validate_output.ps1`:

```powershell
function Assert-LegacyPackageExclusions {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$PackProjectNames,

        [Parameter(Mandatory = $true)]
        [hashtable]$LegacyExclusionConfig
    )

    $legacyExactNames = @($LegacyExclusionConfig.exactProjectNames)
    $legacyTokenPatterns = @($LegacyExclusionConfig.tokenPatterns)

    $legacyProjects = New-Object System.Collections.Generic.List[string]
    foreach ($projectName in $PackProjectNames) {
        if ($legacyExactNames -contains $projectName) {
            $legacyProjects.Add($projectName)
            continue
        }

        foreach ($pattern in $legacyTokenPatterns) {
            if ($projectName -match $pattern) {
                $legacyProjects.Add($projectName)
                break
            }
        }
    }

    if ($legacyProjects.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'LegacyPackageExclusion' `
            -Summary 'Generated nupkg/pack.ps1 still contains legacy package lines that are explicitly excluded from the first-wave compatibility surface.' `
            -Examples ($legacyProjects | Sort-Object -Unique)
    }
}

function Assert-MigrationOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedLibraryProjectNames,

        [Parameter(Mandatory = $true)]
        [hashtable]$LegacyExclusionConfig
    )

    ...

    Write-Host 'Validate migration output: legacy package exclusions'
    Assert-LegacyPackageExclusions -PackProjectNames $packProjectNames -LegacyExclusionConfig $LegacyExclusionConfig

    ...
}
```

- [ ] **Step 5: Re-run the tests to verify the manifest integration passes**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1
pwsh tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1
```

Expected:
- Both scripts PASS.
- `RunEngineConfig-integration-uses-manifests.ps1` prints `run.ps1 and validate_output.ps1 are wired to manifest-backed config.`

- [ ] **Step 6: Commit the manifest integration**

Run:

```powershell
git add tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1 tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/validate_output.ps1 tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/engine_config.ps1 tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1
git commit -m "refactor: load migration governance from manifests"
```

Expected:
- Commit contains only manifest loader integration and its test.

---

### Task 3: Add the v9.4.2 upgrade radar and generation detection

**Files:**
- Create: `tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1`
- Create: `tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1`
- Create: `docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md`
- Modify: `tools/yoyo-abp-migration/README.md`

- [ ] **Step 1: Write the failing generation/radar test**

Create `tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1` with this content:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$scriptPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\Invoke-YoyoAbpUpgradeRadar.ps1'
$matrixPath = Join-Path $repoRoot 'tools\proj-rename-ps\src2\abp-yoyo.abp-string-7.3\config\version-generations.json'

if (!(Test-Path $scriptPath)) {
    throw "Missing radar script: $scriptPath"
}

$matrix = Get-Content $matrixPath -Raw | ConvertFrom-Json -AsHashtable
$generationNames = @($matrix.generations | ForEach-Object { $_.name })

if ($generationNames -notcontains 'v9-net8') {
    throw 'version-generations.json is missing v9-net8.'
}

if ($generationNames -notcontains 'v10-net9') {
    throw 'version-generations.json is missing v10-net9.'
}

$scriptContent = Get-Content $scriptPath -Raw
if ($scriptContent -notmatch 'Get-UpstreamGeneration') {
    throw 'Invoke-YoyoAbpUpgradeRadar.ps1 does not implement Get-UpstreamGeneration.'
}

Write-Host 'Upgrade radar script and generation matrix cover v9/v10.' -ForegroundColor Green
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1
```

Expected:
- FAIL with `Missing radar script` because the scanner does not exist yet.

- [ ] **Step 3: Create the radar script**

Create `tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1` with this content:

```powershell
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

function Get-UpstreamGeneration {
    param(
        [Parameter(Mandatory = $true)][string]$UpstreamPath,
        [Parameter(Mandatory = $true)][string]$VersionMatrixPath
    )

    $matrix = Get-Content $VersionMatrixPath -Raw | ConvertFrom-Json -AsHashtable
    $commonPropsPath = Join-Path $UpstreamPath 'common.props'
    if (!(Test-Path $commonPropsPath)) {
        throw "Missing upstream common.props: $commonPropsPath"
    }

    $versionMatch = Select-String -Path $commonPropsPath -Pattern '<Version>([^<]+)</Version>' | Select-Object -First 1
    if (!$versionMatch) {
        throw 'Unable to resolve upstream version from common.props.'
    }

    $version = ([regex]::Match($versionMatch.Line, '<Version>([^<]+)</Version>')).Groups[1].Value
    foreach ($generation in $matrix.generations) {
        foreach ($prefix in $generation.tagPrefixes) {
            if ($version.StartsWith($prefix.TrimEnd('.'), [System.StringComparison]::OrdinalIgnoreCase) -or $version.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                return @{
                    version = $version
                    name = $generation.name
                    targetFramework = $generation.targetFramework
                    riskNotes = @($generation.riskNotes)
                }
            }
        }
    }

    throw "No generation mapping matched upstream version $version."
}

function Get-ProjectNames {
    param([Parameter(Mandatory = $true)][string]$Root)

    return @(
        Get-ChildItem $Root -Recurse -Filter '*.csproj' -File |
            ForEach-Object { $_.BaseName } |
            Sort-Object -Unique
    )
}

function Get-PackageSignals {
    param([Parameter(Mandatory = $true)][string]$Root)

    $signals = @(
        Select-String -Path (Join-Path $Root '**\*.csproj') -Pattern 'IdentityServer4|OpenIddict|Serilog|log4net|TargetFramework' -ErrorAction SilentlyContinue |
            ForEach-Object { "{0}:{1}: {2}" -f $_.Path, $_.LineNumber, $_.Line.Trim() }
    )

    return ($signals | Sort-Object -Unique)
}

$resolvedUpstreamPath = [System.IO.Path]::GetFullPath($UpstreamPath)
$resolvedCurrentRoot = [System.IO.Path]::GetFullPath($CurrentRoot)
$generation = Get-UpstreamGeneration -UpstreamPath $resolvedUpstreamPath -VersionMatrixPath $VersionMatrixPath
$currentProjects = Get-ProjectNames -Root (Join-Path $resolvedCurrentRoot 'src')
$upstreamProjects = Get-ProjectNames -Root (Join-Path $resolvedUpstreamPath 'src')
$projectDiff = Compare-Object $currentProjects $upstreamProjects
$signals = Get-PackageSignals -Root $resolvedUpstreamPath

$lines = @(
    '# Yoyo.Abp v9.4.2 Upgrade Radar',
    '',
    '## Upstream generation',
    '',
    "- Version: `$($generation.version)`",
    "- Generation: `$($generation.name)`",
    "- Expected target framework: `$($generation.targetFramework)`",
    '',
    '## Risk notes',
    ''
)

$lines += @($generation.riskNotes | ForEach-Object { "- $_" })
$lines += @('', '## Project surface diff', '')

if ($projectDiff) {
    $lines += @($projectDiff | ForEach-Object { "- $($_.SideIndicator) $($_.InputObject)" })
}
else {
    $lines += '- No src project-name delta detected at this scan level.'
}

$lines += @('', '## Package/config signals', '')
if ($signals.Count -gt 0) {
    $lines += @($signals | Select-Object -First 40 | ForEach-Object { "- $_" })
}
else {
    $lines += '- No watched package/config signal detected.'
}

Set-Content -Path $OutputPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
Write-Host "Upgrade radar written: $OutputPath"
```

- [ ] **Step 4: Materialize `v9.4.2` input and generate the radar report**

Run:

```powershell
New-Item -ItemType Directory -Force artifacts/yoyo-abp-migration | Out-Null
if (Test-Path artifacts/yoyo-abp-migration/upstream-v9.4.2) {
  Remove-Item artifacts/yoyo-abp-migration/upstream-v9.4.2 -Recurse -Force
}

git fetch upstream --tags
git archive refs/tags/v9.4.2 --prefix=upstream-v9.4.2/ | tar -x -C artifacts/yoyo-abp-migration

pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1 `
  -UpstreamPath artifacts/yoyo-abp-migration/upstream-v9.4.2 `
  -OutputPath docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md
```

Expected:
- `docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md` exists.
- Report identifies generation `v9-net8`.

- [ ] **Step 5: Re-run the radar test and update the README**

Append this section to `tools/yoyo-abp-migration/README.md`:

````markdown
## Upgrade radar

Use this command to classify an upstream input and capture the first visible project/config deltas before running the migration engine:

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1 `
  -UpstreamPath artifacts/yoyo-abp-migration/upstream-v9.4.2 `
  -OutputPath docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md
```
````

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1
```

Expected:
- PASS with `Upgrade radar script and generation matrix cover v9/v10.`

- [ ] **Step 6: Commit the radar capability**

Run:

```powershell
git add tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1 tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1 tools/yoyo-abp-migration/README.md docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md
git commit -m "feat: add yoyo abp v9 upgrade radar"
```

Expected:
- Commit contains the radar script, radar test, README update, and the generated radar report.

---

### Task 4: Template downstream smoke execution

**Files:**
- Create: `tools/yoyo-abp-migration/config/downstream-smoke-targets.json`
- Create: `tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1`
- Create: `tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1`
- Modify: `tools/yoyo-abp-migration/README.md`

- [ ] **Step 1: Write the failing smoke-template test**

Create `tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1` with this content:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$scriptPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\Invoke-YoyoAbpDownstreamSmoke.ps1'
$configPath = Join-Path $repoRoot 'tools\yoyo-abp-migration\config\downstream-smoke-targets.json'

if (!(Test-Path $scriptPath)) {
    throw "Missing smoke script: $scriptPath"
}

if (!(Test-Path $configPath)) {
    throw "Missing smoke config: $configPath"
}

$output = pwsh $scriptPath -ConfigPath $configPath -PackageVersion '9.4.2-preview' -PackageSource 'C:\temp\feed' -WhatIf 2>&1 | Out-String
if ($output -notmatch 'Yoyo.Monorepo\.sln') {
    throw 'Smoke plan did not render YoyoBoot solution command.'
}

if ($output -notmatch 'YoyoBoot\.Template\.sln') {
    throw 'Smoke plan did not render Rider solution command.'
}

Write-Host 'Downstream smoke script renders both target command templates.' -ForegroundColor Green
```

- [ ] **Step 2: Run the smoke-template test to verify it fails**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1
```

Expected:
- FAIL with `Missing smoke script` because the template executor does not exist yet.

- [ ] **Step 3: Create the downstream smoke config and script**

Create `tools/yoyo-abp-migration/config/downstream-smoke-targets.json`:

```json
{
  "targets": [
    {
      "name": "YoyoBoot",
      "repoRoot": "C:\\Code\\yoyoboot\\YoyoBoot",
      "solution": "Yoyo.Monorepo.sln",
      "versionProperty": "YoyoAbpVersion"
    },
    {
      "name": "RiderAspNetCore",
      "repoRoot": "C:\\Code\\gitea\\Rider\\src\\aspnet-core",
      "solution": "YoyoBoot.Template.sln",
      "versionProperty": "YoyoAbpVersion"
    }
  ]
}
```

Create `tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1`:

```powershell
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

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
foreach ($target in $config.targets) {
    $solutionPath = Join-Path $target.repoRoot $target.solution
    $restoreCommand = "dotnet restore \"$solutionPath\" -p:$($target.versionProperty)=$PackageVersion -p:RestoreAdditionalProjectSources=\"$PackageSource\""
    $buildCommand = "dotnet build \"$solutionPath\" -c Debug --no-restore -p:$($target.versionProperty)=$PackageVersion -p:RestoreAdditionalProjectSources=\"$PackageSource\""

    if ($WhatIf) {
        Write-Host "[$($target.name)] $restoreCommand"
        Write-Host "[$($target.name)] $buildCommand"
        continue
    }

    Push-Location $target.repoRoot
    try {
        Invoke-Expression $restoreCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Restore failed for $($target.name)"
        }

        Invoke-Expression $buildCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed for $($target.name)"
        }
    }
    finally {
        Pop-Location
    }
}
```

- [ ] **Step 4: Run the smoke-template test to verify it passes**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1
```

Expected:
- PASS with `Downstream smoke script renders both target command templates.`

- [ ] **Step 5: Document the smoke executor and commit it**

Append this section to `tools/yoyo-abp-migration/README.md`:

````markdown
## Downstream smoke template

Preview the downstream smoke commands without executing them:

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1 `
  -ConfigPath tools/yoyo-abp-migration/config/downstream-smoke-targets.json `
  -PackageVersion 9.4.2-preview `
  -PackageSource C:\temp\feed `
  -WhatIf
```
````

Run:

```powershell
git add tools/yoyo-abp-migration/config/downstream-smoke-targets.json tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1 tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1 tools/yoyo-abp-migration/README.md
git commit -m "feat: template yoyo downstream smoke targets"
```

Expected:
- Commit contains only the smoke config, script, test, and README update.

---

### Task 5: Document retirement candidates and v10 pre-gates

**Files:**
- Create: `docs/superpowers/reports/2026-04-26-yoyo-abp-log4net-retirement-candidate-ledger.md`
- Create: `docs/superpowers/reports/2026-04-26-yoyo-abp-v10x-pre-gates.md`
- Modify: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/README.md`

- [ ] **Step 1: Write the `Log4Net` retirement ledger**

Create `docs/superpowers/reports/2026-04-26-yoyo-abp-log4net-retirement-candidate-ledger.md` with this content:

```markdown
# Yoyo.Abp Log4Net Retirement Candidate Ledger

## Status

- Package: `Yoyo.Abp.Castle.Log4Net`
- Current classification: high-priority retirement candidate
- Current deletion decision: **do not remove from `profile-33-compat` yet**

## Current evidence

### Main repository

- Source project exists: `src/Abp.Castle.Log4Net/Abp.Castle.Log4Net.csproj`
- Dedicated test project exists: `test/Abp.Castle.Log4Net.Tests/Abp.Castle.Log4Net.Tests.csproj`
- Current package output remains in the compatibility pack surface.

### YoyoBoot consumer

- `apps/yoyoboot/backend/src/YoyoBoot.Web.Core/YoyoBoot.Web.Core.csproj` still references `Yoyo.Abp.Castle.Log4Net`.
- `Serilog` packages already coexist, so migration is partially started but not complete.

### Rider aspnet-core consumer

- `src/YoyoBoot.Template.Migrator/Startup.cs` imports `Abp.Castle.Logging.Log4Net` and still calls `UseAbpLog4Net()`.
- `src/YoyoBoot.Template.Migrator/log4net.config` still exists and `src/YoyoBoot.Template.Migrator/YoyoBoot.Template.Migrator.csproj` includes it as content.
- No direct `Yoyo.Abp.Castle.Log4Net` project-file reference is currently verified in this repo snapshot, so the runtime integration path must be treated as the active blocker and package source resolution should be confirmed during execution.

## Exit criteria before removal

1. Remove direct package references from `YoyoBoot`.
2. Replace `UseAbpLog4Net()` usage and `log4net.config` dependency in `Rider` Migrator.
3. Confirm whether `Rider` resolves `Abp.Castle.Logging.Log4Net` via transitive or shared props/package wiring, then remove that path.
4. Confirm no main-repo smoke/test path requires the package.
5. Run package smoke and both downstream smokes without `Yoyo.Abp.Castle.Log4Net` in the profile.
6. Record an explicit product decision for package-surface shrink.

## Rollback plan

If consumer migration stalls, keep the package in `profile-33-compat` and postpone removal to the next release train.
```

- [ ] **Step 2: Write the `v10.x` pre-gate report**

Create `docs/superpowers/reports/2026-04-26-yoyo-abp-v10x-pre-gates.md` with this content:

```markdown
# Yoyo.Abp v10.x / .NET 9 Pre-Gates

## Scope

This document lists the conditions that must be true before the team starts a real `v10.x / .NET 9` migration wave.

## Required gates

1. `v9.4.2 / .NET 8` compatibility migration is stable on `profile-33-compat`.
2. Upgrade radar and downstream smoke templates are already exercised on `v9.4.2`.
3. At least one retirement-candidate ledger exists for non-core compatibility packages.
4. The team has an explicit decision on whether `v10.x` remains compatibility-only or includes package-surface shrink.
5. `v10.x` is still treated as `.NET 9`, not `.NET 10`.

## Known watch points

- Authentication and identity project drift
- Template/configuration drift
- Header and runtime behavior drift
- Any new upstream package additions that would silently expand the compatibility surface

## Start condition

Do not begin `v10.x` execution until all five required gates above are marked pass.
```

- [ ] **Step 3: Update the engine README and verify there are no placeholders**

Append this section to `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/README.md`:

````markdown
## Governance config

This engine now reads its compatibility package surface and generation metadata from `config/`:

- `library-profile-33-compat.json`
- `test-profile-33-compat.json`
- `version-generations.json`
- `legacy-package-exclusions.json`

Do not expand the package surface by editing `run.ps1` directly. Update the manifests and matching tests first.
````

Run:

```powershell
if (Get-Command rg -ErrorAction SilentlyContinue) {
  rg -n "TODO|TBD|implement later|fill in details" docs/superpowers/reports/2026-04-26-yoyo-abp-log4net-retirement-candidate-ledger.md docs/superpowers/reports/2026-04-26-yoyo-abp-v10x-pre-gates.md tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/README.md
} else {
  Select-String -Path docs/superpowers/reports/2026-04-26-yoyo-abp-log4net-retirement-candidate-ledger.md,docs/superpowers/reports/2026-04-26-yoyo-abp-v10x-pre-gates.md,tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/README.md -Pattern "TODO|TBD|implement later|fill in details"
}
```

Expected:
- No matches found.

- [ ] **Step 4: Commit the governance docs**

Run:

```powershell
git add docs/superpowers/reports/2026-04-26-yoyo-abp-log4net-retirement-candidate-ledger.md docs/superpowers/reports/2026-04-26-yoyo-abp-v10x-pre-gates.md tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/README.md
git commit -m "docs: define yoyo abp v9 v10 governance gates"
```

Expected:
- Commit contains only the retirement ledger, v10 pre-gates report, and README update.

---

### Task 6: Run the governance verification suite

**Files:**
- Modify: `docs/superpowers/specs/2026-04-26-yoyo-abp-9x-10x-migration-governance-design.md` only if a spec/plan mismatch is discovered during verification

- [ ] **Step 1: Execute the governance test suite**

Run:

```powershell
pwsh tools/yoyo-abp-migration/tests/RunProfile33Compat-aligns-engine-and-pack-surface.ps1
pwsh tools/yoyo-abp-migration/tests/RunEngineConfig-integration-uses-manifests.ps1
pwsh tools/yoyo-abp-migration/tests/RunUpgradeRadar-detects-v9-v10-generations.ps1
pwsh tools/yoyo-abp-migration/tests/RunDownstreamSmoke-renders-target-commands.ps1
```

Expected:
- All four tests PASS.

- [ ] **Step 2: Rebuild the v9.4.2 radar report once after tests pass**

Run:

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1 `
  -UpstreamPath artifacts/yoyo-abp-migration/upstream-v9.4.2 `
  -OutputPath docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md
```

Expected:
- Radar report is refreshed after the final code state.

- [ ] **Step 3: If verification exposed a spec/plan mismatch, fix the docs before moving on**

If, and only if, the verification run reveals that the design doc names a behavior the code path cannot support, update `docs/superpowers/specs/2026-04-26-yoyo-abp-9x-10x-migration-governance-design.md` in the same commit that fixes the mismatch.

Use this exact diff shape for the design doc only when needed:

```markdown
- Old statement that no longer matches the implementation plan
+ Corrected statement that matches the verified governance behavior
```

Expected:
- No design/spec drift remains after verification.

- [ ] **Step 4: Commit final governance verification results**

Run:

```powershell
git add tools/yoyo-abp-migration/tests tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1 tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1 tools/yoyo-abp-migration/config docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md docs/superpowers/specs/2026-04-26-yoyo-abp-9x-10x-migration-governance-design.md
git commit -m "test: verify yoyo abp migration governance tooling"
```

Expected:
- Final commit contains the verified governance runtime outputs and only any spec drift fixes that were proven necessary.

---

## Self-review

### Spec coverage

- `proj-rename-ps` 规则清单化与版本感知：Task 1 + Task 2。
- `profile-33-compat` 正式定义：Task 1。
- `v9.4.2 / .NET 8` 输入扫描与差异报告：Task 3。
- 下游 smoke 模板化：Task 4。
- `Log4Net` 退役候选账本：Task 5。
- `v10.x / .NET 9` 前置门禁：Task 5。
- 错误分类、验证矩阵、执行出口：Task 2 + Task 3 + Task 4 + Task 6。

### Placeholder scan

This plan intentionally contains no `TODO`, `TBD`, “implement later”, or undefined file paths. Every code-writing step includes concrete file content or replacement snippets. Every verification step includes runnable commands and expected outcomes.

### Type consistency

- The compatibility profile is consistently named `33-compat`.
- The loader functions are consistently named `Get-LibraryProfile33Compat`, `Get-TestProfile33Compat`, `Get-VersionGenerationMatrix`, and `Get-LegacyPackageExclusions`.
- The downstream smoke script consistently uses `PackageVersion`, `PackageSource`, and `WhatIf` as public parameters.
- `v9-net8` and `v10-net9` are the only new generation identifiers referenced across the plan.
