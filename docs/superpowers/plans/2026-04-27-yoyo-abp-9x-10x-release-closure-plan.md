# Yoyo.Abp 9.x / 10.x Release Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 `release-9.4.2` 与 `release-10.3` 的稳定面收口：先修复当前真实 build blocker，再把 `OpenIddict` / generation-aware profile / pack / stage-keep 正式纳入，最终使两条 release 线具备可验证的 stable build。

**Architecture:** 先把 `release-10.3` 与 `release-9.4.2` 中已经暴露的 string-key overlay 编译断层修平，再恢复官方 stable surface 缺失项（尤其是 `OpenIddict` 与 `Dapper Sql`），最后把 generation-aware 治理固化到 migration / pack / stage-keep，使 solution、pack、profile、验证脚本由同一事实源驱动。

**Tech Stack:** PowerShell、Markdown、.NET 8/9、ABP upstream tags、`dotnet build`、solution/pack/profile manifests

---

### Task 1: 固化 release closure 设计基线

**Files:**
- Create: `docs/superpowers/specs/2026-04-27-yoyo-abp-9x-10x-release-closure-design.md`
- Create: `docs/superpowers/plans/2026-04-27-yoyo-abp-9x-10x-release-closure-plan.md`

- [ ] 将最新“official stable surface + string-key overlay + generation-aware profile”结论固化到 spec。
- [ ] 将实施顺序拆成 `release-10.3`、`release-9.4.2`、治理层、验证四段。

### Task 2: 收口 `release-10.3` 当前源码断层

**Files:**
- Modify: `.worktrees/release-10.3/src/Abp.EntityFrameworkCore/EntityFrameworkCore/AbpDbContext.cs`
- Modify: `.worktrees/release-10.3/src/Abp.AspNetCore/AspNetCore/MultiTenancy/HttpHeaderTenantResolveContributor.cs`
- Modify: `.worktrees/release-10.3/src/Abp.AspNetCore/AspNetCore/MultiTenancy/HttpCookieTenantResolveContributor.cs`
- Modify: `.worktrees/release-10.3/src/Abp.ZeroCore/Authorization/AbpLoginManager.cs`
- Create: `.worktrees/release-10.3/src/Abp.Dapper/Dapper-Extensions/Sql/*`

- [ ] 以 `dotnet build Abp.sln -c Release` 作为红灯测试复现失败。
- [ ] 修复 `AbpDbContext` 中所有 `string` 租户过滤签名与 `GetMethod` 类型。
- [ ] 修复两个 tenant resolver，移除错误的 `int.TryParse` 返回路径。
- [ ] 修复 `AbpLoginManager` 中残留的 `int?/long?` 逻辑。
- [ ] 补齐 `Dapper-Extensions/Sql/*` 缺失源码。
- [ ] 重新 build，记录剩余 blocker。

### Task 3: 收口 `release-9.4.2` 当前源码断层

**Files:**
- Modify: `.worktrees/release-9.4.2/src/Abp.EntityFrameworkCore/EntityFrameworkCore/AbpDbContext.cs`
- Modify: `.worktrees/release-9.4.2/test/Abp.Dapper.Tests/DapperRepository_Tests.cs`

- [ ] 以 `dotnet build Abp.sln -c Release` 作为红灯测试复现失败。
- [ ] 修复 `AbpDbContext` 的 string-key 过滤签名。
- [ ] 修复 Dapper 测试中的 `int -> string` 断层。
- [ ] 重新 build，记录剩余 blocker。

### Task 4: 恢复官方 stable surface 到两条 release 线

**Files:**
- Modify: `.worktrees/release-9.4.2/Abp.sln`
- Modify: `.worktrees/release-9.4.2/nupkg/pack.ps1`
- Modify: `.worktrees/release-10.3/Abp.sln`
- Modify: `.worktrees/release-10.3/nupkg/pack.ps1`
- Modify: `.worktrees/release-9.4.2/tools/proj-rename-ps/...`
- Modify: `.worktrees/release-10.3/tools/proj-rename-ps/...`
- Modify: `.worktrees/release-9.4.2/tools/yoyo-abp-migration/...`
- Modify: `.worktrees/release-10.3/tools/yoyo-abp-migration/...`
- Create: `OpenIddict` project trees in both release worktrees

- [ ] 把 `OpenIddict` 三件套补回两条 release 线的源码、solution 与 pack。
- [ ] 让 `v9` 保留 `EFPlus + IdentityServer4.vNext* + OpenIddict*`。
- [ ] 让 `v10` 保留 `OpenIddict* + Dapper Sql`，并明确不恢复 `EFPlus` 与旧 `IdentityServer4` stable 面。
- [ ] 同步更新 stage-keep / migration / profile 清单。

### Task 5: 固化 generation-aware 治理

**Files:**
- Modify: `tools/proj-rename-ps/src2/abp-yoyo.abp-string-7.3/config/*`
- Modify: `tools/yoyo-abp-migration/Invoke-YoyoAbpMigration.ps1`
- Modify: `tools/yoyo-abp-migration/tests/*`

- [ ] 将 `version-generations.json` 从“只认 TFM”升级为“generation 选择 profile”。
- [ ] 为 `v9` / `v10` 新增显式 stable profile 与 required/removed project signals。
- [ ] 让 `pack` / `solution` / `stage-keep` 共享同一事实源。

### Task 6: 验证收口结果

**Files:**
- Modify: 对应 release worktree 中因验证暴露问题的文件

- [ ] 在 `release-10.3` 执行 `dotnet build Abp.sln -c Release`。
- [ ] 在 `release-9.4.2` 执行 `dotnet build Abp.sln -c Release`。
- [ ] 核对 solution / pack / profile / migration 不再彼此矛盾。
- [ ] 若仍有 blocker，按“源码断层 / stable surface 缺失 / 治理回滚”三类继续归因。
