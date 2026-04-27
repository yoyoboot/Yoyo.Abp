# Yoyo.Abp 9.x / 10.x Release 收口最佳实践设计

> 状态：已完成用户确认，可进入实施
> 目标：在 `release-9.4.2` 与 `release-10.3` 两条稳定发行线中，同时完成官方 stable surface 对齐、`string` 主键语义收口、构建恢复，以及迁移治理层升级，形成可复用的最佳实践。

## 1. 背景与问题重述

当前 `Yoyo.Abp` 已完成 `7.4` 线的 GitHub-only 发布闭环与 33 包兼容基线，但 `9.4.2 / 10.3` 两条 release 线仍未真正收口。问题不再只是 SDK 或 restore，而是三类问题叠加：

1. **官方 stable surface 演进**：`v9.4.2` / `v10.3` 已正式引入 `OpenIddict`，并对 `IdentityServer4` / `EFPlus` / `Dapper` 相关项目面进行了调整；
2. **fork 永久差异**：当前 fork 的默认主键/租户/用户语义已经从官方 `int/long` 改为 `string`，不能机械覆盖官方源码；
3. **迁移工具链滞后**：现有 `33-compat` 与 `StageKeepProjects` 仍停留在 `7.3/7.4` 时代，无法作为 `v9/v10` 的唯一项目面来源。

因此，当前收口必须同时解决“官方项目面恢复”和“string-key overlay 修正”，而不是只做单点编译修补。

## 2. 已确认事实

### 2.1 官方 `v9.4.2` stable surface

官方 `v9.4.2` 正式包含：

- `Abp.AspNetCore.OpenIddict`
- `Abp.ZeroCore.OpenIddict`
- `Abp.ZeroCore.OpenIddict.EntityFrameworkCore`
- `Abp.EntityFrameworkCore.EFPlus`
- `Abp.ZeroCore.IdentityServer4.vNext`
- `Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore`

官方 `v9.4.2` 不再保留旧 stable 面：

- `Abp.ZeroCore.IdentityServer4`
- `Abp.ZeroCore.IdentityServer4.EntityFrameworkCore`

### 2.2 官方 `v10.3` stable surface

官方 `v10.3` 正式包含：

- `Abp.AspNetCore.OpenIddict`
- `Abp.ZeroCore.OpenIddict`
- `Abp.ZeroCore.OpenIddict.EntityFrameworkCore`
- `Abp.Dapper`，且 `Dapper-Extensions/Sql/*` 物理目录存在

官方 `v10.3` 不再进入 stable surface：

- `Abp.EntityFrameworkCore.EFPlus`
- `Abp.ZeroCore.IdentityServer4`
- `Abp.ZeroCore.IdentityServer4.EntityFrameworkCore`
- `Abp.ZeroCore.IdentityServer4.vNext`

### 2.3 当前本地 release 线缺口

- `release-9.4.2` 与 `release-10.3` 当前都没有完整纳入 `OpenIddict` 项目面；
- `release-10.3` 还缺失 `src/Abp.Dapper/Dapper-Extensions/Sql/*`；
- 多个关键类已经被改造成 `string` 语义，但实现仍残留官方 `int?/long?` 逻辑，导致 build fail；
- migration engine / profile / pack / stage-keep 之间不存在统一事实源。

## 3. 设计目标

本设计的目标是形成一套能直接指导实现的最佳实践：

1. 让 `release-9.4.2` 与 `release-10.3` 的 **solution / pack / migration / stage-keep** 同步对齐官方 stable surface；
2. 让所有关键源码修复遵循 **official stable surface + string-key overlay** 原则；
3. 将 `OpenIddict`、`Dapper Sql`、认证迁移差异纳入 generation-aware 治理，不再依赖单个 `33-compat` 老清单；
4. 以 `dotnet build Abp.sln -c Release` 为每条 release 线的阶段性出口条件。

## 4. 非目标

- 不将当前任务扩展为全量产品面瘦身；
- 不在本轮把所有下游业务模板默认切换到 `OpenIddict only`；
- 不回退 `string` 主键语义到官方 `int/long`；
- 不为了短期编译通过而继续维持与官方 stable surface 不一致的项目面。

## 5. 最佳实践主策略

## 5.1 核心原则

### 原则 A：以官方 stable surface 为基线

- `release-9.4.2` 的目标面必须包含 `EFPlus + IdentityServer4.vNext* + OpenIddict 三件套`；
- `release-10.3` 的目标面必须包含 `OpenIddict 三件套 + Dapper Sql 完整目录`；
- 官方已移除的 stable 项目不得继续作为稳定包面回流。

### 原则 B：以 string-key overlay 为适配方式

关键源码文件必须按本仓库 `string` 主键语义重写，而不是照搬 upstream：

- `AbpDbContext`
- `HttpHeaderTenantResolveContributor`
- `HttpCookieTenantResolveContributor`
- `AbpLoginManager`
- 未来引入 `OpenIddict` 后涉及 `TenantId/UserId/Entity<TKey>` 的相关类型

### 原则 C：generation-aware 治理优先于局部补丁

治理层必须从“单一 33-compat 清单”升级为“按代际选择 profile”：

- `v7-stable`
- `v9-stable`
- `v10-stable`

并让 generation 驱动：

- library profile
- solution surface
- pack list
- stage-keep list
- required/removed upstream signals

## 5.2 推荐方案

推荐采用 **“generation-aware profile + official surface restore + string-key overlay + build verification”** 四段式策略：

1. **治理建模**：定义 `v9` / `v10` 的 stable profile 与 generation matrix；
2. **官方项目面恢复**：补齐 `OpenIddict`、`Dapper Sql` 等官方存在但本地缺失的项目或源码面；
3. **string-key overlay 修复**：在保留本仓库永久差异的前提下修正关键编译/语义断层；
4. **验证出口**：分别在 `release-9.4.2`、`release-10.3` 上执行 `dotnet build Abp.sln -c Release` 并继续收敛剩余 blocker。

## 6. 版本矩阵

| 版本线 | 官方 generation | 目标 stable surface | 明确移除 | 关键 overlay 点 |
| --- | --- | --- | --- | --- |
| `release-9.4.2` | `v9-net8` | `EFPlus`、`IdentityServer4.vNext*`、`OpenIddict*` | 旧 `IdentityServer4*` | `AbpDbContext`、Dapper tests、后续 OpenIddict string-key |
| `release-10.3` | `v10-net9` | `OpenIddict*`、`Abp.Dapper` + `Sql/*` | `EFPlus`、旧 `IdentityServer4*`、`IdentityServer4.vNext` | `AbpDbContext`、tenant resolvers、`AbpLoginManager`、Dapper 源码补齐 |

## 7. 治理层设计

### 7.1 单一事实源

后续应由 generation matrix 选择 profile，而不是让以下文件各写各的名单：

- `config/library-profile-*.json`
- `run.ps1`
- `Invoke-YoyoAbpMigration.ps1`
- `nupkg/pack.ps1`
- `StageKeepProjects`

### 7.2 profile 的职责

每个 profile 至少描述：

- `libraryProjects`
- `packProjects`
- `solutionProjects`
- `stageKeepProjects`
- `deprecatedProjects`
- `requiredUpstreamProjects`

### 7.3 为什么 current 33-compat 不足

`33-compat` 仍然适合 `7.4` 兼容线，但不应继续充当 `v9/v10` 统一真相，因为：

- 它不知道 `OpenIddict` 是正式 stable surface；
- 它无法表达 `v9` 与 `v10` 的认证演进差异；
- 它会把“上一代兼容面”误当成“下一代稳定面”。

## 8. 实施顺序

### Phase 1：`release-10.3` 源码收口

优先处理当前最明显的 build blocker：

1. 修正 `AbpDbContext` 中 `string` 租户过滤签名；
2. 修正 `HttpHeaderTenantResolveContributor` / `HttpCookieTenantResolveContributor`；
3. 修正 `AbpLoginManager` 中所有残留的 `int?/long?` 逻辑；
4. 恢复 `Dapper-Extensions/Sql/*`；
5. 重新 build，得到下一轮剩余 blocker。

### Phase 2：`release-9.4.2` 源码收口

1. 修正 `AbpDbContext` 的 string-key 过滤签名；
2. 修正 `DapperRepository_Tests` 等明显的 `int -> string` 断层；
3. 重新 build，确认源码层已收敛。

### Phase 3：项目面与治理层收口

1. 将 `OpenIddict` 正式纳入 `release-9.4.2` / `release-10.3` 的 solution / pack / migration / stage-keep；
2. 将 generation-aware profile 固化进工具链；
3. 用升级雷达和 profile 验证脚本校验项目面不再漂移。

## 9. 成功定义

本轮收口成功的定义不是“解决若干编译错误”，而是：

$$
\text{成功} = \text{官方 stable surface 对齐} + \text{string-key overlay 正确} + \text{release build 通过} + \text{治理层不再回滚产物}
$$

## 10. 结论

本设计确认：

1. `OpenIddict` 不是可选增强项，而是 `v9/v10` 官方 stable surface 的正式组成；
2. `33-compat` 不应继续作为 `v9/v10` 的唯一真相来源；
3. 当前 release 收口必须同时修“项目面”和“string-key overlay”；
4. 最佳实践不是继续人工捡漏，而是把 generation-aware 治理固化后再完成 build 收口。
