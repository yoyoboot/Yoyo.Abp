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