# Yoyo.Abp Migration Rules Inventory

## Source

- Imported engine: `tools/proj-rename-ps`
- Primary ABP 7.3 entry point: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/run.ps1`

## Rule groups

| Group | Current source | Purpose | First implementation action |
| --- | --- | --- | --- |
| Package identity rewrite | `process_lib.ps1` / `RunLib` | Rewrite `Abp.*` packages and assemblies to `Yoyo.Abp.*` | Keep behavior, later extract to manifest |
| Project white-list pruning | `run.ps1` + `RmLib` | Keep only supported Yoyo.Abp package surface | Capture list before v7.4 generation |
| .NET Framework compatibility cleanup | `process_lib.ps1` / `RemoveNetFrameworkCompatibility`, `process_test.ps1` | Remove `net4x`/`net461` targets, conditional dependencies, and portable fallback from generated projects | Keep as a first-wave hard gate |
| String primary key rewrite | `process_lib.ps1`, `process_test.ps1`, `process_test_demo.ps1` | Preserve default `string` key semantics | Keep as permanent migration rule |
| Patch injection | `run.ps1` copy operations from `abp/` | Inject Yoyo-specific helper and EFCore files | Verify injected file list after every run |
| Pack script replacement | `run.ps1` copy to `nupkg/pack.ps1` | Preserve Yoyo package output behavior and current 33-package surface | Verify output package IDs are `Yoyo.Abp.*` and no old compatibility packages are listed |
| Test and SampleApp compatibility | `process_test.ps1`, `process_test_demo.ps1` | Keep migration result buildable and testable | Run targeted tests after generation |

## Non-negotiable permanent rules

- `Yoyo.Abp.*` package identity remains permanent.
- Default `string` primary key remains permanent.
- `.NET Framework` / `net4x` compatibility is removed from generated output in the first wave.
- NHibernate, Owin, legacy ASP.NET Web, GraphDiff, FluentMigrator, and legacy Zero packages are not part of the first-wave 33-package surface.
- Downstream `YoyoBoot` and `Rider` restore/build smoke remain release gates.

## Tooling rule

The imported engine is preserved first, then improved incrementally. The first implementation wave must not rewrite all migration logic at once.