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
- If `OutputPath` is placed under `UpstreamPath` (for example a copy-only smoke run), the wrapper excludes that output subtree during the copy so it does not recurse into itself.
- Logs are written under `tools/yoyo-abp-migration/logs/` and are ignored by git.
- Generated outputs belong under `artifacts/yoyo-abp-migration/` and are ignored by git.

## Upgrade radar

Use this command to classify an upstream input and capture the first visible project/config deltas before running the migration engine:

The report title and version-specific summary fields are derived dynamically from the upstream `common.props` version.

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpUpgradeRadar.ps1 `
  -UpstreamPath artifacts/yoyo-abp-migration/upstream-v9.4.2 `
  -OutputPath docs/superpowers/reports/2026-04-26-yoyo-abp-v9.4.2-upgrade-radar.md
```

## Downstream smoke template

Preview the downstream smoke commands without executing them:

`-WhatIf` only renders command templates; it does not validate whether configured `repoRoot` or `solution` paths currently exist on the local machine. The sample config is intended as a local template.

```powershell
pwsh tools/yoyo-abp-migration/Invoke-YoyoAbpDownstreamSmoke.ps1 `
  -ConfigPath tools/yoyo-abp-migration/config/downstream-smoke-targets.json `
  -PackageVersion 9.4.2-preview `
  -PackageSource C:\temp\feed `
  -WhatIf
```

## Package version policy

Use a three-segment package version for every release or verify line:

- `release/7.4` -> `7.4.0`
- `verify/7.4-yoyo-on-dev-7.3.0` -> `7.4.1`
- `release/9.4.2` -> `9.4.2`
- `verify/9.4.2-yoyo-on-release-7.4` -> `9.4.3`
- `release/10.3` -> `10.3.0`
- `verify/10.3.1-yoyo-on-release-9.4.2` -> `10.3.2`

The verify branch token is interpreted as the current formal package version token for the next patch line. Two-segment tokens are normalized to `.0`, and verify lines always increment the patch segment by one.

Prefer an explicit package-version override in build and pack automation:

```powershell
pwsh version-update.ps1 -Version 7.4.0
pwsh nupkg/pack.ps1 -Version 7.4.0
nuke Pack --packageVersion 7.4.0
```

`nuke Pack` now requires `--packageVersion` so the Pack target never silently falls back to an unintended default.

For `nupkg/pack.ps1`, precedence is:

1. `-Version`
2. production `TAG` when `IS_PRODUCTION=true`
3. branch-aware mapping for `release/*` and `verify/*`
4. `common.props`

Feed policy:

- `release/*` package lines publish to the **stable feed** for downstream consumption.
- `verify/*` package lines publish to the **validation feed** and must complete package/downstream smoke before a release patch is promoted.