# Yoyo.Abp Log4Net Retirement Candidate Ledger

## Status

- Package: `Yoyo.Abp.Castle.Log4Net`
- Assessment date: `2026-04-26`
- Governance classification: high-priority retirement candidate
- Current release decision: retain in the compatibility surface and **do not remove from `profile-33-compat` at this stage**

This ledger records why `Yoyo.Abp.Castle.Log4Net` is a retirement candidate, and why the package is not yet eligible for removal from the current compatibility release train.

## Current evidence

### Main repository

- `src/Abp.Castle.Log4Net/Abp.Castle.Log4Net.csproj` confirms the maintained package identity remains active in the main repository:
  - `<AssemblyName>Yoyo.Abp.Castle.Log4Net</AssemblyName>`
  - `<PackageId>Yoyo.Abp.Castle.Log4Net</PackageId>`
- `test/Abp.Castle.Log4Net.Tests/Abp.Castle.Log4Net.Tests.csproj` still carries a direct `ProjectReference` to `..\..\src\Abp.Castle.Log4Net\Abp.Castle.Log4Net.csproj`, which means the package continues to have a dedicated repository test path.
- The same test project still includes `log4net.config` as content copied to output/publish directories, which confirms runtime configuration expectations are not yet retired from the test surface.
- `src/Abp.Castle.Log4Net/Castle/Logging/Log4Net/LoggingFacilityExtensions.cs` still exposes `UseAbpLog4Net()`, so the public integration entry point remains part of the supported package contract.

### YoyoBoot downstream evidence

- `C:\Code\yoyoboot\YoyoBoot\apps\yoyoboot\backend\src\YoyoBoot.Web.Core\YoyoBoot.Web.Core.csproj:31` contains `<PackageReference Include="Yoyo.Abp.Castle.Log4Net" Version="$(YoyoAbpVersion)" />`, which is an active direct downstream package reference.
- The same project file already carries a partial Serilog adoption path at lines `37-39`:
  - `Castle.Core-Serilog`
  - `Serilog.AspNetCore`
  - `Serilog.Sinks.Console`
- `C:\Code\yoyoboot\YoyoBoot\build\Versions.props:8` pins `<YoyoAbpVersion>7.3.0.12</YoyoAbpVersion>`, so the currently validated downstream consumer is bound to the `7.3.0.12` package line rather than to an unpinned experimental feed.

Governance implication: `YoyoBoot` has already started introducing the successor logging stack, but the direct `Yoyo.Abp.Castle.Log4Net` dependency is still present and therefore remains an active removal blocker.

### Rider aspnet-core downstream evidence

- `C:\Code\gitea\Rider\src\aspnet-core\src\YoyoBoot.Template.Migrator\Startup.cs:7` imports `Abp.Castle.Logging.Log4Net`.
- `C:\Code\gitea\Rider\src\aspnet-core\src\YoyoBoot.Template.Migrator\Startup.cs:45` still wires `f.UseAbpLog4Net().WithConfig("log4net.config");`, which is a verified runtime integration path.
- `C:\Code\gitea\Rider\src\aspnet-core\src\YoyoBoot.Template.Migrator\YoyoBoot.Template.Migrator.csproj:23` still includes `<None Update="log4net.config">`, confirming the migrator continues to ship the configuration artifact.
- `C:\Code\gitea\Rider\src\aspnet-core\src\YoyoBoot.Template.Migrator\YoyoBoot.Template.Migrator.csproj:39` contains `<PackageReference Include="Yoyo.Abp.Castle.Log4Net" Version="$(YoyoAbpVersion)" />`, which is a verified direct package reference.

Governance implication: the earlier assumption that Rider had only an indirect runtime dependency is obsolete. The current verified state is stricter: **Rider Migrator has both a direct package reference and a live runtime integration path**, so retirement cannot proceed until both are removed.

## Exit criteria before removal

All of the following conditions must be satisfied before `Yoyo.Abp.Castle.Log4Net` can be proposed for removal from `profile-33-compat`:

1. `YoyoBoot` removes its direct `Yoyo.Abp.Castle.Log4Net` package reference and completes migration to the approved replacement logging path.
2. Rider Migrator removes both the direct package reference and the `UseAbpLog4Net()` + `log4net.config` runtime path.
3. Main-repository validation proves there is no remaining smoke, package, or test dependency on `Yoyo.Abp.Castle.Log4Net` or its configuration artifacts.
4. Downstream smoke verification is executed against both `YoyoBoot` and Rider after the package is excluded from the compatibility profile.
5. Product governance records an explicit decision on whether the next release train is still compatibility-first or is authorized to shrink the public package surface.

Until all five criteria are met, the package remains a retirement candidate under observation rather than an approved removal item.

## Rollback plan

If any downstream migration stalls, or if smoke validation shows unresolved runtime coupling, retain `Yoyo.Abp.Castle.Log4Net` in `profile-33-compat`, keep the package published for the current release train, and defer retirement to a later governance checkpoint with refreshed evidence.