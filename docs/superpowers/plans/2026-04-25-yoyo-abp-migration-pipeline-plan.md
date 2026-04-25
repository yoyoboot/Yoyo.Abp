# Yoyo.Abp Migration Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `proj-rename-ps` 纳入 `Yoyo.Abp` 仓库并建立可重复的 Yoyo.Abp 迁移流水线，先固化 `7.3.0.12` 生产基线，再重建 `v7.4` 标准生成路径，为后续 `v9.4.2 / .NET 8` 实施建立门禁。

**Architecture:** 本计划实现第一阶段迁移基础设施，不直接升级到 `.NET 8`。实现方式是：把外部 `proj-rename-ps` 作为迁移引擎导入仓库，增加安全包装入口和运行日志，再用报告固定当前生产包面、迁移规则、下游消费矩阵，最后用官方 upstream `v7.4` 作为输入验证可重复生成路径。

**Tech Stack:** PowerShell、Git、NuGet、.NET SDK 6、ASP.NET Boilerplate upstream `https://github.com/aspnetboilerplate/aspnetboilerplate/`、Markdown

---

## Scope check

本计划只覆盖设计文档中的第一实施波次：

1. 迁入并治理 `proj-rename-ps`；
2. 固化当前 `Yoyo.Abp 7.3.0.12` 生产基线；
3. 建立迁移规则清单；
4. 重建 `v7.4` 标准生成路径；
5. 定义进入 `v9.4.2 / .NET 8` 的前置门禁。

本计划不实施 `v9.4.2 / .NET 8` 升级，不实施 `.NET 10`，不清理 `.NET Framework` 兼容层。

## File map

### Create

- `tools/proj-rename-ps/` — 从 `C:\Code\yoyoboot\proj-rename-ps` 迁入的迁移引擎源码。
- `tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1` — 新增安全包装入口，负责复制 upstream 输入、调用迁移引擎、记录日志。
- `tools/yoyo-abp-migration/README.md` — 说明迁移入口、输入输出、约束与执行示例。
- `tools/yoyo-abp-migration/logs/.gitkeep` — 保留日志目录，实际日志不提交。
- `docs/superpowers/reports/2026-04-25-yoyo-abp-7.3-production-baseline.md` — 当前生产基线报告。
- `docs/superpowers/reports/2026-04-25-yoyo-abp-migration-rules-inventory.md` — 迁移规则清单。
- `docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md` — `v7.4` 标准生成路径准备度报告。

### Modify

- `docs/superpowers/specs/2026-04-25-yoyo-abp-migration-pipeline-design.md` — 已由用户补充官方 upstream 地址，本计划仅在提交时保留该文档修订。
- `.gitignore` — 若日志或临时输出未被忽略，则追加 `tools/yoyo-abp-migration/logs/*.log` 与 `artifacts/yoyo-abp-migration/`。

### External inputs

- `C:\Code\yoyoboot\proj-rename-ps` — 迁移引擎来源。
- `https://github.com/aspnetboilerplate/aspnetboilerplate/` — 官方 upstream 仓库。
- `C:\Code\yoyoboot\YoyoBoot` — 已投产下游模板/平台仓库。
- `C:\Code\gitea\Rider\src\aspnet-core` — 已投产业务项目仓库。

---

### Task 1: Commit approved design revision and import migration engine

**Files:**
- Modify: `docs/superpowers/specs/2026-04-25-yoyo-abp-migration-pipeline-design.md`
- Create: `tools/proj-rename-ps/`
- Modify: `.gitignore` if needed

- [ ] **Step 1: Verify current design diff only contains approved upstream-source refinements**

Run:

```powershell
git diff -- docs/superpowers/specs/2026-04-25-yoyo-abp-migration-pipeline-design.md
```

Expected:
- Diff shows the official upstream URL `https://github.com/aspnetboilerplate/aspnetboilerplate/`.
- Diff shows version input labels for `.NET 6` / `v7.4`, `.NET 8` / `v9.4.2`, and `.NET 10` / `v10.3`.
- No framework source files under `src/` or `test/` are included.

- [ ] **Step 2: Commit the approved design revision before implementation files**

Run:

```powershell
git add docs/superpowers/specs/2026-04-25-yoyo-abp-migration-pipeline-design.md
git commit -m "docs: refine migration pipeline upstream inputs"
```

Expected:
- A docs-only commit is created.
- Working tree may still contain unrelated pre-existing changes such as `.gitignore`, `.vscode/mcp.json`, or `docs/说明.md`; do not include them unless they are required by this plan.

- [ ] **Step 3: Copy `proj-rename-ps` into the repository**

Run:

```powershell
$source = 'C:\Code\yoyoboot\proj-rename-ps'
$target = 'tools\proj-rename-ps'
if (!(Test-Path $source)) { throw "Missing migration source: $source" }
if (Test-Path $target) { throw "Target already exists: $target" }
New-Item -ItemType Directory -Force tools | Out-Null
Copy-Item -Path $source -Destination $target -Recurse -Force
Remove-Item -Path (Join-Path $target '.git') -Recurse -Force -ErrorAction SilentlyContinue
```

Expected:
- `tools/proj-rename-ps/README.md` exists.
- `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1` exists.
- The nested `.git` directory from the external tool repo is not copied into the main repo.

- [ ] **Step 4: Add ignore rules for migration artifacts if missing**

Run:

```powershell
$ignorePath = '.gitignore'
$rules = @(
  'artifacts/yoyo-abp-migration/',
  'tools/yoyo-abp-migration/logs/*.log'
)
$content = if (Test-Path $ignorePath) { Get-Content $ignorePath -Raw } else { '' }
foreach ($rule in $rules) {
  if ($content -notmatch [regex]::Escape($rule)) {
    Add-Content -Path $ignorePath -Value $rule
  }
}
```

Expected:
- `.gitignore` contains `artifacts/yoyo-abp-migration/`.
- `.gitignore` contains `tools/yoyo-abp-migration/logs/*.log`.

- [ ] **Step 5: Commit migration engine import**

Run:

```powershell
git add tools/proj-rename-ps .gitignore
git commit -m "chore: import yoyo abp migration engine"
```

Expected:
- Commit contains only `tools/proj-rename-ps/**` and required `.gitignore` additions.
- No generated `bin/`, `obj/`, `dist/`, or nested `.git` files are committed.

---

### Task 2: Add safe migration wrapper

**Files:**
- Create: `tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1`
- Create: `tools/yoyo-abp-migration/README.md`
- Create: `tools/yoyo-abp-migration/logs/.gitkeep`

- [ ] **Step 1: Create wrapper directory**

Run:

```powershell
New-Item -ItemType Directory -Force tools/yoyo-abp-migration/logs | Out-Null
New-Item -ItemType File -Force tools/yoyo-abp-migration/logs/.gitkeep | Out-Null
```

Expected:
- `tools/yoyo-abp-migration/logs/.gitkeep` exists.

- [ ] **Step 2: Create `Invoke-YoyoAbpMigration.ps1`**

Write `tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1` exactly as follows:

```powershell
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

function Resolve-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
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

if (Test-Path $resolvedOutputPath) {
    if (!$CleanOutput) {
        throw "OutputPath already exists. Re-run with -CleanOutput to replace it: $resolvedOutputPath"
    }

    Remove-Item -Path $resolvedOutputPath -Recurse -Force
}

New-Item -ItemType Directory -Force $resolvedOutputPath | Out-Null
New-Item -ItemType Directory -Force (Split-Path -Parent $resolvedLogPath) | Out-Null

Write-Host "Copy upstream source"
Copy-Item -Path (Join-Path $resolvedUpstreamPath '*') -Destination $resolvedOutputPath -Recurse -Force

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

Write-Host "Migration output: $resolvedOutputPath"
Write-Host "Migration log: $resolvedLogPath"
```

- [ ] **Step 3: Create wrapper README**

Write `tools/yoyo-abp-migration/README.md` exactly as follows:

````markdown
# Yoyo.Abp Migration Wrapper

This directory contains the safe entry point for running the imported `proj-rename-ps` migration engine against a clean ASP.NET Boilerplate upstream source tree.

## Source of upstream

Official repository: https://github.com/aspnetboilerplate/aspnetboilerplate/

## Command shape

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1 `
  -UpstreamPath artifacts/yoyo-abp-migration/upstream-v7.4 `
  -OutputPath artifacts/yoyo-abp-migration/yoyo-v7.4 `
  -CleanOutput
```

## Safety rules

- The wrapper never runs directly against `codex/dev-7.3.0`.
- The wrapper copies upstream input into an output directory before running the engine.
- Logs are written under `tools/yoyo-abp-migration/logs/` and are ignored by git.
- Generated outputs belong under `artifacts/yoyo-abp-migration/` and are ignored by git.
````

- [ ] **Step 4: Run wrapper copy-only smoke**

Run:

```powershell
New-Item -ItemType Directory -Force artifacts/yoyo-abp-migration | Out-Null
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1 `
  -UpstreamPath . `
  -OutputPath artifacts/yoyo-abp-migration/copy-only-smoke `
  -CleanOutput `
  -SkipEngineRun
```

Expected:
- `artifacts/yoyo-abp-migration/copy-only-smoke/Abp.sln` exists.
- No files under `artifacts/yoyo-abp-migration/` are tracked by git.

- [ ] **Step 5: Commit wrapper**

Run:

```powershell
git add tools/yoyo-abp-migration
git commit -m "chore: add yoyo abp migration wrapper"
```

Expected:
- Commit contains wrapper script, wrapper README, and `.gitkeep` only.

---

### Task 3: Configure upstream input and current production baseline report

**Files:**
- Create: `docs/superpowers/reports/2026-04-25-yoyo-abp-7.3-production-baseline.md`

- [ ] **Step 1: Configure official upstream remote if missing**

Run:

```powershell
$remote = git remote get-url upstream 2>$null
if (!$remote) {
  git remote add upstream https://github.com/aspnetboilerplate/aspnetboilerplate.git
}
git fetch upstream --tags
git rev-parse --verify refs/tags/v7.4
git rev-parse --verify refs/tags/v9.4.2
git rev-parse --verify refs/tags/v10.3
```

Expected:
- `upstream` points to `https://github.com/aspnetboilerplate/aspnetboilerplate.git`.
- Tags `v7.4`, `v9.4.2`, and `v10.3` resolve.

- [ ] **Step 2: Generate current package surface snapshot**

Run:

```powershell
$dist = 'nupkg/dist'
if (!(Test-Path $dist)) { throw "Missing package dist folder: $dist" }
Get-ChildItem $dist -File | Sort-Object Name | Select-Object Name, Length | ConvertTo-Json -Depth 3 | Set-Content artifacts/yoyo-abp-migration/current-dist-files.json
Get-ChildItem $dist -Filter *.nupkg -File | Sort-Object Name | Select-Object -ExpandProperty Name | Set-Content artifacts/yoyo-abp-migration/current-nupkg-list.txt
```

Expected:
- `artifacts/yoyo-abp-migration/current-nupkg-list.txt` contains `Yoyo.Abp.*.nupkg` entries.
- No `artifacts/yoyo-abp-migration/*` files are tracked by git.

- [ ] **Step 3: Generate downstream version snapshot**

Run:

```powershell
$paths = @(
  'C:\Code\yoyoboot\YoyoBoot\build\Versions.props',
  'C:\Code\yoyoboot\YoyoBoot\abpversion.props',
  'C:\Code\gitea\Rider\src\aspnet-core\common.props'
)
$rows = foreach ($path in $paths) {
  if (Test-Path $path) {
    Select-String -Path $path -Pattern 'YoyoAbpVersion|DotNetVersion|YoyoProVersion|YoyoBootVersion|AbpVersion' | ForEach-Object {
      [PSCustomObject]@{ Path = $path; LineNumber = $_.LineNumber; Line = $_.Line.Trim() }
    }
  }
}
$rows | ConvertTo-Json -Depth 4 | Set-Content artifacts/yoyo-abp-migration/downstream-version-snapshot.json
```

Expected:
- Snapshot includes `YoyoAbpVersion=7.3.0.12` for `YoyoBoot`.
- Snapshot includes `YoyoAbpVersion=7.3.0.12` for `Rider/src/aspnet-core`.

- [ ] **Step 4: Create production baseline report**

Write `docs/superpowers/reports/2026-04-25-yoyo-abp-7.3-production-baseline.md` with this content, updating only numeric counts from the generated snapshots:

```markdown
# Yoyo.Abp 7.3.0.12 Production Baseline

## Summary

- Production branch: `codex/dev-7.3.0`
- Production version: `7.3.0.12`
- Package identity: `Yoyo.Abp.*`
- Runtime generation: `.NET 6`
- Official upstream source: https://github.com/aspnetboilerplate/aspnetboilerplate/

## Current package surface

- Source directory: `nupkg/dist`
- `.nupkg` package count: use `artifacts/yoyo-abp-migration/current-nupkg-list.txt`
- `.snupkg` package count: count `nupkg/dist/*.snupkg`
- Rule: all package IDs must remain `Yoyo.Abp.*` for production consumers.

## Downstream consumers

| Consumer | Version entry | Current Yoyo.Abp version | Runtime |
| --- | --- | --- | --- |
| `C:\Code\yoyoboot\YoyoBoot` | `build/Versions.props` | `7.3.0.12` | `net6.0` |
| `C:\Code\gitea\Rider\src\aspnet-core` | `common.props` | `7.3.0.12` | `net6.0` |

## Baseline rule

Future generated releases must not be considered valid until they pass restore/build smoke against both downstream consumers.
```

- [ ] **Step 5: Commit baseline report**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-yoyo-abp-7.3-production-baseline.md
git commit -m "docs: capture yoyo abp production baseline"
```

Expected:
- Commit contains only the baseline report.

---

### Task 4: Create migration rules inventory

**Files:**
- Create: `docs/superpowers/reports/2026-04-25-yoyo-abp-migration-rules-inventory.md`

- [ ] **Step 1: Inventory migration entry points**

Run:

```powershell
Get-ChildItem tools/proj-rename-ps -Recurse -File -Include *.ps1 | Select-Object FullName | Sort-Object FullName | Set-Content artifacts/yoyo-abp-migration/migration-ps1-files.txt
Select-String -Path tools/proj-rename-ps/**/*.ps1 -Pattern 'PackageId|AssemblyName|Entity<string>|Entity<int>|Entity<long>|Repository<|Copy-Item|RmLib|RunLib|RunTest|RunTestDemos' | Select-Object Path,LineNumber,Line | ConvertTo-Json -Depth 4 | Set-Content artifacts/yoyo-abp-migration/migration-rule-hits.json
```

Expected:
- `migration-ps1-files.txt` includes `src2\abp-yoyo.abp-string-7.3\run.ps1`.
- `migration-rule-hits.json` includes package rename, string primary key, project removal, and patch injection patterns.

- [ ] **Step 2: Create migration rules inventory report**

Write `docs/superpowers/reports/2026-04-25-yoyo-abp-migration-rules-inventory.md` exactly as follows:

```markdown
# Yoyo.Abp Migration Rules Inventory

## Source

- Imported engine: `tools/proj-rename-ps`
- Primary ABP 7.3 entry point: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1`

## Rule groups

| Group | Current source | Purpose | First implementation action |
| --- | --- | --- | --- |
| Package identity rewrite | `process_lib.ps1` / `RunLib` | Rewrite `Abp.*` packages and assemblies to `Yoyo.Abp.*` | Keep behavior, later extract to manifest |
| Project white-list pruning | `run.ps1` + `RmLib` | Keep only supported Yoyo.Abp package surface | Capture list before v7.4 generation |
| String primary key rewrite | `process_lib.ps1`, `process_test.ps1`, `process_test_demo.ps1` | Preserve default `string` key semantics | Keep as permanent migration rule |
| Patch injection | `run.ps1` copy operations from `abp/` | Inject Yoyo-specific helper and EFCore files | Verify injected file list after every run |
| Pack script replacement | `run.ps1` copy to `nupkg/pack.ps1` | Preserve Yoyo package output behavior | Verify output package IDs are `Yoyo.Abp.*` |
| Test and SampleApp compatibility | `process_test.ps1`, `process_test_demo.ps1` | Keep migration result buildable and testable | Run targeted tests after generation |

## Non-negotiable permanent rules

- `Yoyo.Abp.*` package identity remains permanent.
- Default `string` primary key remains permanent.
- Downstream `YoyoBoot` and `Rider` restore/build smoke remain release gates.

## Tooling rule

The imported engine is preserved first, then improved incrementally. The first implementation wave must not rewrite all migration logic at once.
```

- [ ] **Step 3: Commit rules inventory**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-yoyo-abp-migration-rules-inventory.md
git commit -m "docs: inventory yoyo abp migration rules"
```

Expected:
- Commit contains only the migration rules inventory report.

---

### Task 5: Rebuild v7.4 generation path with migration wrapper

**Files:**
- Create: `docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md`

- [ ] **Step 1: Materialize official upstream v7.4 input**

Run:

```powershell
New-Item -ItemType Directory -Force artifacts/yoyo-abp-migration | Out-Null
if (Test-Path artifacts/yoyo-abp-migration/upstream-v7.4) {
  Remove-Item artifacts/yoyo-abp-migration/upstream-v7.4 -Recurse -Force
}
git archive refs/tags/v7.4 --prefix=upstream-v7.4/ | tar -x -C artifacts/yoyo-abp-migration
if (!(Test-Path artifacts/yoyo-abp-migration/upstream-v7.4/Abp.sln)) {
  throw 'Unable to materialize upstream v7.4 input under artifacts/yoyo-abp-migration/upstream-v7.4'
}
```

Expected:
- `artifacts/yoyo-abp-migration/upstream-v7.4/Abp.sln` exists.
- Input source is ignored by git.

- [ ] **Step 2: Run migration wrapper against v7.4 input**

Run:

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1 `
  -UpstreamPath artifacts/yoyo-abp-migration/upstream-v7.4 `
  -OutputPath artifacts/yoyo-abp-migration/yoyo-v7.4 `
  -CleanOutput
```

Expected:
- `artifacts/yoyo-abp-migration/yoyo-v7.4/Abp.sln` exists.
- `tools/yoyo-abp-migration/logs/last-run.log` exists but is ignored by git.
- Generated `.csproj` files include `Yoyo.Abp` package identity.

- [ ] **Step 3: Verify generated package identity**

Run:

```powershell
$generated = 'artifacts/yoyo-abp-migration/yoyo-v7.4'
$packageIds = Select-String -Path "$generated/src/**/*.csproj" -Pattern '<PackageId>' | ForEach-Object { $_.Line.Trim() }
$badPackageIds = $packageIds | Where-Object { $_ -match '<PackageId>Abp' -and $_ -notmatch '<PackageId>Yoyo\.Abp' }
if ($badPackageIds) { $badPackageIds; throw 'Generated output contains non-Yoyo package IDs.' }
$packageIds | Sort-Object | Set-Content artifacts/yoyo-abp-migration/yoyo-v7.4-packageids.txt
```

Expected:
- No non-Yoyo `Abp.*` package IDs remain in generated package projects.
- `yoyo-v7.4-packageids.txt` lists `Yoyo.Abp.*` package identities.

- [ ] **Step 4: Run generated solution restore/build smoke**

Run:

```powershell
Push-Location artifacts/yoyo-abp-migration/yoyo-v7.4
try {
  dotnet restore --ignore-failed-sources
  dotnet build Abp.sln -c Release --no-restore
}
finally {
  Pop-Location
}
```

Expected:
- Restore completes successfully.
- Build either passes or fails with a captured error list that becomes the first repair queue.
- If build fails, do not continue to package or downstream smoke until errors are classified.

- [ ] **Step 5: Create v7.4 generation readiness report**

Write `docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md` with this content after Step 4 outcome is known:

```markdown
# Yoyo.Abp v7.4 Generation Readiness

## Input

- Official upstream repository: https://github.com/aspnetboilerplate/aspnetboilerplate/
- Official upstream tag: `v7.4`
- Local upstream input: `artifacts/yoyo-abp-migration/upstream-v7.4`

## Migration engine

- Wrapper: `tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1`
- Imported engine: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1`
- Output: `artifacts/yoyo-abp-migration/yoyo-v7.4`

## Checks

| Check | Result | Evidence |
| --- | --- | --- |
| Upstream input materialized | record pass or failure | `Abp.sln` exists under upstream input |
| Migration wrapper ran | record pass or failure | `tools/yoyo-abp-migration/logs/last-run.log` |
| Package IDs rewritten | record pass or failure | `artifacts/yoyo-abp-migration/yoyo-v7.4-packageids.txt` |
| Restore/build smoke | record pass or failure | terminal output from `dotnet restore` and `dotnet build` |

## Decision

- If all checks pass, the next implementation plan can add package smoke and downstream consumption smoke.
- If build fails, classify errors into migration-rule gaps before touching framework code manually.
```

- [ ] **Step 6: Commit v7.4 readiness report**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md
git commit -m "docs: report yoyo abp v7.4 generation readiness"
```

Expected:
- Commit contains only the v7.4 readiness report.

---

### Task 6: Define downstream smoke gate for the next execution wave

**Files:**
- Modify: `docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md`

- [ ] **Step 1: Add downstream smoke gate section to readiness report**

Append this section to `docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md`:

````markdown
## Downstream smoke gate for next wave

Before any `release/7.4` publication decision, the generated package set must pass:

1. `Yoyo.Abp` package smoke with a production-style version such as `7.4.0.1`.
2. `C:\Code\yoyoboot\YoyoBoot` restore/build against local package source.
3. `C:\Code\gitea\Rider\src\aspnet-core` restore/build against local package source.
4. A recorded decision on whether `v9.4.2 / .NET 8` planning may start.

Suggested package smoke command from generated output:

```powershell
Push-Location artifacts/yoyo-abp-migration/yoyo-v7.4/nupkg
try {
  $env:IS_PRODUCTION = 'true'
  $env:TAG = '7.4.0.1'
  pwsh ./pack.ps1
}
finally {
  Remove-Item Env:IS_PRODUCTION -ErrorAction SilentlyContinue
  Remove-Item Env:TAG -ErrorAction SilentlyContinue
  Pop-Location
}
```
````

- [ ] **Step 2: Commit downstream smoke gate**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-yoyo-abp-7.4-generation-readiness.md
git commit -m "docs: define downstream smoke gate for yoyo abp v7.4"
```

Expected:
- Commit contains only the readiness report update.

---

## Self-review

### Spec coverage

- Migrate `proj-rename-ps` into `Yoyo.Abp`: Task 1.
- Add safe execution wrapper and logs: Task 2.
- Preserve official upstream URL and version inputs: Task 1 and Task 3.
- Preserve `7.3.0.12` production baseline and downstream consumers: Task 3.
- Create migration rules inventory: Task 4.
- Rebuild `v7.4` standard generation path: Task 5.
- Define gate before `v9.4.2 / .NET 8`: Task 6.

### Completeness scan

This plan intentionally avoids draft markers, open-ended “fill in” statements, and undefined file paths. Report templates use fixed sections and require recording pass/failure after concrete commands run.

### Scope control

This plan stops before implementing `v9.4.2 / .NET 8`. The next plan should only start after Task 6 produces a clear gate decision.
