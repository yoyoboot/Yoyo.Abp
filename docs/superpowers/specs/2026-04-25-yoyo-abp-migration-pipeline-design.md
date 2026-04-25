# Yoyo.Abp 标准化迁移流水线设计

> 状态：本设计完全取代旧的 `2026-04-25-yoyo-abp-upstream-sync-design.md`。旧设计把 `Yoyo.Abp` 近似建模为普通 upstream fork；本设计将其重新定义为已投产的、由官方 ABP 源码经迁移引擎生成并持续维护的 Yoyo 品牌发行版。

## 1. 背景与问题重定义

`Yoyo.Abp` 当前不是普通意义上的 `aspnetboilerplate/aspnetboilerplate` fork。当前生产基线 `codex/dev-7.3.0` / `7.3.0.12` 的形成路径是：

1. 以官方 ABP 7.3.x 源码作为原始输入；
2. 使用 `C:\Code\yoyoboot\proj-rename-ps` 中的脚本执行批量迁移；
3. 迁移过程包含包名与程序集名重命名、默认主键改为 `string`、项目白名单裁剪、补丁文件注入、打包脚本替换等动作；
4. 在迁移结果上继续进行手工修复、删除和生产适配；
5. 最终形成当前已被下游生产仓库使用的 `Yoyo.Abp.*` NuGet 发行版。

因此，旧设计中将 `codex/dev-7.3.0` 与 `.worktrees/sync-upstream` / `release/7.4` 直接作为普通分支差异审计的前提不成立。两者之间的大量差异不是单纯 upstream 升级差异，而是“原始 upstream 输入”和“Yoyo 产品化输出”之间天然存在的迁移产物差异。

后续不再沿用旧的 `release/7.4`、`sync/7.4-yoyo`、`sync/8.0-yoyo` 本地分支结果。这些分支已判定为问题结果并从本地删除；新的 `7.4` 产物必须从官方 upstream 干净输入重新生成。

本设计的目标不是简单把当前分支 merge 到某个 upstream 版本，而是建立一套可重复、可审计、可验证的标准化迁移流水线，使官方 upstream 后续版本能够持续转化为 `Yoyo.Abp` 产品线，并逐步支持 `.NET 8` 与未来 `.NET 10`。

## 2. 已确认事实

### 2.1 当前生产基线

- 当前 `Yoyo.Abp` 主工作基线：`codex/dev-7.3.0`。
- 当前对外使用版本：`7.3.0.12`。
- 当前仓库 `global.json` 锁定 `.NET SDK 6.0.100`。
- 当前主线发包体系使用 `Yoyo.Abp.*` 包名。
- 当前默认 `IEntity` / `IRepository<TEntity>` 主键语义为 `string`。

### 2.2 下游生产约束

以下下游已投入使用，必须作为升级门禁的一部分：

- `C:\Code\yoyoboot\YoyoBoot`
  - `build/Versions.props` 中使用 `YoyoAbpVersion=7.3.0.12`。
  - 当前目标框架仍为 `net6.0`。
- `C:\Code\gitea\Rider\src\aspnet-core`
  - `common.props` 中使用 `YoyoAbpVersion=7.3.0.12`。
  - 当前目标框架仍为 `net6.0`。

因此，后续升级不能只验证 `Yoyo.Abp` 自身编译或测试通过，还必须验证这些实际消费者能 restore、build，并在关键路径上 smoke 通过。

### 2.3 迁移工具事实

`proj-rename-ps` 已经完成了当前 Yoyo 产品形态的大部分迁移能力，包括但不限于：

- 将 `<PackageId>Abp...` 替换为 `<PackageId>Yoyo.Abp...`；
- 将 `<AssemblyName>Abp...` 替换为 `<AssemblyName>Yoyo.Abp...`；
- 将 `<Description>Abp...` 替换为 `<Description>Yoyo.Abp...`；
- 白名单保留项目，删除不在白名单中的库和测试项目；
- 将大量 `int` / `long` 主键相关类型替换为 `string`；
- 对 Zero、ZeroCore、EF、EFCore、OData、Dapper、MemoryDb、测试项目和 SampleApp 进行专项修补；
- 移除 `.NET Framework` / `net4x` 兼容目标、条件依赖和 `AssetTargetFallback` 遗留项，将生成线收敛到当前 `.NET 6` 生产线；
- 注入 `AbpStringPrimaryKeyValueGenerator.cs`、`StringIdExtensions.cs`、`AbpDbContextExtensions.cs`、`AbpZeroDbContextExtensions.cs` 等补丁文件；
- 替换 `nupkg/pack.ps1`。

因此，`proj-rename-ps` 不应被视为可忽略的历史脚本，而应作为正式迁移引擎纳入 `Yoyo.Abp` 的标准化升级设计。

## 3. 旧方案缺陷

旧 upstream sync 方案的主要缺陷如下：

1. **对象建模错误**：把 `Yoyo.Abp` 当作普通 fork，而不是脚本驱动的品牌发行版。
2. **差异归因错误**：把迁移引擎自然产生的命名、包面、补丁和裁剪差异误判为普通分支差异。
3. **分支语义错误**：把 `.worktrees/sync-upstream` / `release/7.4` 视为可能直接 merge 的成品分支，而不是 upstream 输入经过部分改造后的中间结果。
4. **工具资产低估**：没有把 `proj-rename-ps` 作为核心迁移能力纳入设计。
5. **生产约束不足**：虽然提到了下游消费验证，但没有把已投产的 `YoyoBoot` 与 `Rider` 作为升级路线的硬门禁。
6. **错误结果延续风险**：旧 `release/7.4`、`sync/7.4-yoyo`、`sync/8.0-yoyo` 已确认不应继续承载后续工作，应删除后从官方 upstream 重新制作。
7. **兼容层清理缺失**：旧方案没有把 `.NET Framework` / `net461` 兼容层、NHibernate/Owin/legacy ASP.NET Web 包裁剪作为规则门禁，容易把当前分支没有保留的历史包重新带回。

因此，旧设计应废弃，不再作为后续实施依据。

## 4. 总体设计目标

新的标准化迁移流水线需要达成以下目标：

1. 将 `proj-rename-ps` 纳入 `Yoyo.Abp` 仓库，作为正式迁移引擎治理；
2. 以官方 upstream 版本作为原料输入，而不是直接把 upstream 分支 merge 成 Yoyo 成品；
3. 将当前已经投产的 `Yoyo.Abp 7.3.0.12` 作为生产兼容基线；
4. 将 `Yoyo.Abp.*` 包名与程序集名视为长期永久差异；
5. 将默认 `string` 主键体系视为长期永久差异；
6. 将项目裁剪、打包脚本、补丁注入和下游验证标准化；
7. 将 `.NET Framework` / `net461` 兼容层清理纳入迁移规则，避免已废弃目标框架和条件依赖回流；
8. 先重建并验证 `7.4` 生成路径，再将生成结果回灌到当前生产基线派生的验证分支中验证；
9. 在 `7.4` 回灌验证通过后，再推进 `v9.4.2 / .NET 8`；
10. 在 `.NET 8` 版本稳定后，再评估 `v10.x / .NET 9` 与未来 `.NET 10` 路线。

## 5. 架构设计

### 5.1 四层模型

本设计采用四层模型，但不要求每一层都映射为独立长期分支。

#### 第一层：官方 upstream 输入层

仓库地址：https://github.com/aspnetboilerplate/aspnetboilerplate/

职责：

- 提供官方 ABP 原始版本；
- 作为迁移引擎输入；
- 不直接作为 Yoyo 发包产物。

典型输入：

- 官方 `.NET 6`：`v7.4`；
- 官方 `.NET 8`：`v9.4.2`；
- 官方 `v10.x / .NET 9`：[v10.3](https://github.com/aspnetboilerplate/aspnetboilerplate/releases/tag/v10.3)；
- 未来官方 `.NET 10` 对应版本待 upstream 明确发布后再确认，不能直接把 `v10.3` 当作 `.NET 10` 锚点。

#### 第二层：Yoyo 基底语义层

职责：

- 承载必须进入源码语义的核心规则；
- 主要包括默认 `string` 主键体系及其必要配套。

典型规则：

- `IEntity` 默认主键为 `string`；
- `IRepository<TEntity>` 默认主键为 `string`；
- Tenant/User/Role/Edition 等与主键相关的类型改写；
- EF/EFCore 主键生成器与映射补丁；
- 与默认 `string` 主键相关的测试修复。

#### 第三层：Yoyo 产品化层

职责：

- 将基底源码变成 `Yoyo.Abp` 产品线；
- 保持下游 NuGet 消费体验稳定。

典型规则：

- `PackageId` 改为 `Yoyo.Abp.*`；
- `AssemblyName` 改为 `Yoyo.Abp.*`；
- 项目白名单裁剪；
- `.NET Framework` / `net4x` 目标框架与条件依赖裁剪；
- 补丁文件注入；
- `nupkg/pack.ps1` 替换或标准化；
- 版本号规则与发包清单维护。

#### 第四层：生产消费兼容层

职责：

- 确保已投产下游能够平滑升级；
- 约束所有 breaking change 的引入节奏。

典型对象：

- `YoyoBoot`；
- `Rider/src/aspnet-core`；
- 其他实际业务项目。

验证要求：

- NuGet restore；
- 关键项目 build；
- 关键启动或核心链路 smoke；
- 必要时提供迁移说明。

### 5.2 迁移流水线

标准迁移路径为：

1. 选择官方 upstream 版本；
2. 准备干净 upstream 输入目录或 worktree；
3. 运行迁移引擎；
4. 执行基底语义规则；
5. 执行产品化规则；
6. 清理 `.NET Framework` / `net4x` 兼容层；
7. 注入补丁文件；
8. 生成 `Yoyo.Abp.*` 包面；
9. 执行 Yoyo.Abp 自身编译、测试、打包验证；
10. 执行包身份、包面和目标框架验证；
11. 从当前生产基线创建短生命周期回灌验证分支；
12. 将生成结果以受控 overlay 方式回灌到验证分支；
13. 执行下游消费验证；
14. 输出 `release/<version>`。

### 5.3 回灌验证模型

官方 upstream 经迁移引擎生成的目录不是最终 release。它必须先回灌到当前生产基线派生的验证分支中，证明生成结果能够承接现有仓库治理资产、版本脚本、下游消费方式和人工维护差异。

推荐验证分支命名：

- `verify/7.4-yoyo-on-dev-7.3.0`；
- `verify/9.4.2-yoyo-on-release-7.4`。

回灌规则：

- 验证分支从当前生产基线或上一稳定发行分支创建；
- 迁移生成结果以 overlay 方式进入验证分支，不直接 merge 生成目录的历史；
- framework 内容可覆盖，例如 `src/`、`test/`、`nupkg/pack.ps1`、`common.props`、`global.json`、解决方案文件和构建配置；
- 仓库治理资产默认保留，例如 `.git/`、`docs/superpowers/`、`tools/`、本地工作区配置和迁移报告；
- 如果 overlay 后验证失败，修复入口优先回到迁移引擎或补丁文件，不在生成结果上堆积不可复现的手工修复。

旧 `.worktrees/sync-upstream` / `release/7.4` 结果不能作为后续输入或参考产物。当前核查显示该问题结果包含 48 个 `Abp.*` PackageId，而当前生产基线是 33 个 `Yoyo.Abp.*` PackageId；后续必须以官方 upstream 干净输入和当前分支的 33 包清单重新生成。

### 5.4 包面与规则单一事实源

当前迁移引擎、`nupkg/pack.ps1` 和实际 `src/` 项目目录都可能包含项目清单。后续治理必须避免多个清单长期分叉。

第一阶段不强行重写工具，但必须建立以下门禁：

- 迁移白名单、实际 `src/` 目录和打包项目清单必须输出对比报告；
- 当前生产兼容线以当前分支 `codex/dev-7.3.0` 的 33 个 `Yoyo.Abp.*` 包为唯一基线；
- `nupkg/pack.ps1` 和迁移引擎内置 pack 清单不得包含当前 33 包之外的 NHibernate、Owin、legacy ASP.NET Web、GraphDiff、FluentMigrator、legacy Zero 包；
- 若要引入 48 包扩展线，必须单独做产品决策和下游验证，不能作为 `7.4` 迁移的隐式副作用；
- 生成结果不得保留 `.NET Framework` / `net4x` 目标框架、`net461` 条件依赖或 `portable-net45+win8+wp8+wpa81` fallback；
- 所有 release candidate 必须确认 `.nupkg` / `.snupkg` 文件名、nuspec 依赖和 csproj `PackageId` 均为 `Yoyo.Abp.*` 体系。

## 6. `proj-rename-ps` 治理设计

### 6.1 工具定位

`proj-rename-ps` 在新设计中定位为：

> Yoyo.Abp 标准化迁移引擎的初始实现。

它不再只是外部历史工具，也不应被遗留在主流程之外。

### 6.2 迁入原则

后续实施时，应将 `proj-rename-ps` 迁入 `Yoyo.Abp` 仓库内的工具目录，例如：

- `tools/proj-rename-ps/`

迁入后先保持脚本行为可追溯，不应立即进行大规模重写。第一阶段重点是：

1. 保留现有能力；
2. 固化当前规则来源；
3. 使执行入口参数化；
4. 输出迁移日志；
5. 支持 dry-run 或至少支持可重复的临时输出目录；
6. 将补丁文件与迁移规则放在仓库中统一版本管理。

### 6.3 工具完善方向

工具迁入后，按以下方向逐步完善：

1. 将硬编码路径改为参数；
2. 将项目白名单从脚本主体中提取为清单；
3. 将补丁文件注入动作显式化；
4. 将包名/程序集名规则显式化；
5. 将主键替换规则分组；
6. 将测试与 SampleApp 修补规则分组；
7. 输出迁移报告，包括新增、删除、修改文件清单；
8. 为关键规则补充最小验证脚本。

## 7. 分支与版本策略

### 7.1 分支策略

为避免过度治理，分支不按四层模型展开。实际只保留三类长期有意义的分支：

| 分支类型 | 示例 | 职责 |
| --- | --- | --- |
| 生产基线 | `codex/dev-7.3.0` | 当前已投产版本的维护基线 |
| 升级工作区 | `sync/7.4-yoyo`、`sync/9.4.2-yoyo` | 从官方 upstream 干净输入重新创建，接收 upstream 输入并运行迁移引擎 |
| 回灌验证 | `verify/7.4-yoyo-on-dev-7.3.0` | 将迁移结果叠加到当前基线派生分支，验证真实仓库与下游兼容性 |
| 稳定发行 | `release/7.4`、`release/9.4.2` | 已验证、可供下游消费的发行分支 |

官方 upstream 版本优先通过 tag、临时 worktree 或只读输入目录表示，不强制长期维护 `upstream/*`、`base/*`、`product/*` 多层分支。`sync/*` 与 `release/*` 分支名可在重新制作时复用，但不得继承旧 `release/7.4`、`sync/7.4-yoyo`、`sync/8.0-yoyo` 的问题历史。`verify/*` 分支是短生命周期分支，只用于快速证明迁移结果能否进入当前产品线；验证通过后再决定是否创建或替换 `release/<version>`。

### 7.2 版本路线

#### Phase 0：固化当前生产基线

目标：确认 `7.3.0.12` 的真实生产包面、下游依赖和迁移规则来源。

输出：

- 当前 `Yoyo.Abp.*` 包面清单；
- 当前 `proj-rename-ps` 规则清单；
- 下游 `YoyoBoot` / `Rider` 消费矩阵；
- 当前手工修正差异账本。

#### Phase 1：重建 `7.4` 标准生成路径

目标：以官方 `v7.4` 为输入，通过迁移引擎生成标准化 `Yoyo.Abp 7.4.x`。

重点：

- 不再把当前 `.worktrees/sync-upstream` 直接视为最终成品；
- 使用迁移引擎重新解释 `7.4`；
- 以官方 `v7.4` 干净输入重新生成，不沿用旧 `sync-upstream` / `release/7.4` 结果；
- 对比生成结果与当前分支 33 包生产基线的差异；
- 确认输出包身份是 `Yoyo.Abp.*`，不能保留官方 `Abp.*` PackageId；
- 先保持当前 33 包生产兼容线，48 包扩展线必须作为单独产品决策；
- 将生成结果回灌到 `verify/7.4-yoyo-on-dev-7.3.0` 验证分支；
- 输出可被下游验证的 `Yoyo.Abp 7.4.x`。

#### Phase 2：进入 `v9.4.2 / .NET 8`

目标：以官方 `v9.4.2` 为输入，通过迁移引擎生成 `.NET 8` 代际的 Yoyo 发行版。

重点：

- 不要求先单独落地 `v8.x / .NET 7`；
- 将 `v8.x` 作为差异分析参考；
- 重点处理 `.NET 8` 依赖、认证模块、OpenIddict 并存/替换状态；
- 验证 `YoyoBoot` 与 `Rider` 的迁移窗口。

#### Phase 3：评估 `v10.x / .NET 9` 与未来 `.NET 10`

目标：在 `.NET 8` 版本稳定后，再评估官方 `v10.x / .NET 9` 路线，并等待未来 `.NET 10` 对应 upstream 锚点。

重点：

- 不在当前设计中强行承诺 `.NET 10` 立即落地；
- `v10.3` 不能被当作 `.NET 10` 版本输入，它属于 `v10.x / .NET 9` 评估范围；
- 以 `.NET 8` 稳定产物为下一轮输入；
- 重新评估认证模块、目标框架、包面和下游升级成本。

## 8. 验证设计

每个发行候选必须通过五类验证。

### 8.1 迁移引擎验证

- 能从指定 upstream 输入目录运行；
- 能输出迁移日志；
- 能识别项目白名单裁剪结果；
- 能确认补丁文件已注入；
- 能生成 `Yoyo.Abp.*` 包名和程序集名。

### 8.2 Yoyo.Abp 自身验证

- 解决方案 restore；
- 关键项目 build；
- 核心测试矩阵；
- `string` 主键回归测试；
- `nupkg/pack.ps1` 打包 smoke。

### 8.3 NuGet 包面验证

- 包 ID 必须为 `Yoyo.Abp.*`；
- 版本号必须符合 Yoyo 版本策略；
- 包数量变化必须有解释；
- 包依赖不能回退到未重命名的 `Abp.*` 依赖；
- `.nupkg` 与 `.snupkg` 数量应匹配。
- 打包项目清单必须与迁移白名单、实际 `src/` 项目目录进行差异检查。

### 8.4 下游消费验证

必须覆盖：

- `C:\Code\yoyoboot\YoyoBoot`；
- `C:\Code\gitea\Rider\src\aspnet-core`。

最小门禁：

- 本地 NuGet 源可消费；
- restore 成功；
- 关键项目 build 成功；
- 至少一个关键启动或核心业务链路 smoke 成功。

### 8.5 回灌验证

`7.4` 起，每个候选版本都必须经过回灌验证：

- 从上一生产基线或稳定发行创建 `verify/*` 分支；
- overlay 迁移生成结果；
- 保留仓库治理资产；
- 检查 `src/` 项目数、PackageId、AssemblyName、nupkg 文件名、nuspec 依赖；
- 在验证分支上运行 Yoyo.Abp 自身验证和下游消费验证；
- 只有验证分支通过后，才允许创建或更新 `release/<version>`。

## 9. 风险与应对

### 风险 1：迁移引擎规则过于脚本化，难以审计

应对：先迁入并冻结行为，再逐步把硬编码规则提取为清单和分组，不在第一阶段重写工具。

### 风险 2：生成结果与当前生产基线不一致

应对：先对 `7.3.0.12` 做基线复盘，建立“脚本生成差异”和“人工维护差异”账本。

### 风险 3：下游项目被破坏

应对：将 `YoyoBoot` 与 `Rider` 消费验证作为 release 门禁，不允许只凭框架仓库测试通过就发布。

### 风险 4：分支过多导致治理复杂

应对：设计上保留四层模型，实际分支只保留生产基线、升级工作区、稳定发行三类。

### 风险 5：`.NET 8` 与 `.NET 10` 目标被混在一个阶段

应对：先完成 `.NET 8 / v9.4.2`，稳定后再评估 `v10.x / .NET 9`；未来 `.NET 10` 以官方明确版本为准。

### 风险 6：旧 `release/7.4` / `sync/*` 结果被误复用

应对：旧 `release/7.4`、`sync/7.4-yoyo`、`sync/8.0-yoyo` 已从本地删除，后续不得复用其内容。新的 `7.4` 工作必须从官方 upstream 干净输入开始，通过迁移引擎重新生成 `Yoyo.Abp.*` 包身份，并通过回灌验证后再决定 release 分支。

### 风险 7：包面从 33 个隐式扩大到 48 个

应对：当前生产兼容线以当前分支的 33 个 `Yoyo.Abp.*` 包为基线。48 包扩展线涉及 legacy ASP.NET MVC/WebApi/NHibernate/Owin 等包，必须单独做产品决策、包身份重写和下游验证，不能作为 `7.4` 升级的默认副作用。当前第一波 pack 清单必须排除 NHibernate、Owin、legacy ASP.NET Web、GraphDiff、FluentMigrator 和 legacy Zero 包；`Abp.Web.Common` 是当前 33 包之一，不属于要删除的 legacy Web 包。

### 风险 8：项目清单分散导致打包遗漏或多打包

应对：第一阶段输出迁移白名单、实际 `src/` 目录和 `nupkg/pack.ps1` 项目清单对比报告；后续再将项目清单收敛为单一事实源。

### 风险 9：官方 upstream 生命周期与目标框架误判

应对：官方 `v10.3` 先按 `v10.x / .NET 9` 评估；`.NET 10` 不绑定到 `v10.3`。同时需要关注 ASP.NET Boilerplate 官方支持窗口，避免长期路线依赖已停止维护的 upstream。

### 风险 10：`.NET Framework` 兼容层回流

应对：迁移引擎必须在处理库项目和测试项目 `.csproj` 时删除 `net4x` / `net461` 目标框架、对应条件 `ItemGroup` / `PropertyGroup`、以及 `portable-net45+win8+wp8+wpa81` fallback。生成验证必须搜索 `src/`、`test/` 和 `nupkg/pack.ps1`，发现 `.NET Framework` 目标或旧兼容包即失败。

## 10. 新设计结论

本设计确认：

1. 旧 upstream sync 设计废弃；
2. `Yoyo.Abp` 是已投产的、脚本驱动的官方 ABP 衍生发行版；
3. `proj-rename-ps` 是核心迁移引擎，应迁入 `Yoyo.Abp` 仓库并纳入版本管理；
4. 后续升级应以“官方 upstream 输入 → 迁移引擎生成 Yoyo 发行版 → 回灌验证分支 → 下游消费验证”为标准路径；
5. `Yoyo.Abp.*` 包名/程序集名和默认 `string` 主键语义是长期永久差异；
6. 分支策略应保持精简，不按理论层级过度拆分；
7. 路线优先级为：固化 `7.3.0.12` 生产基线 → 重建 `7.4` 标准生成路径 → 回灌当前基线验证分支 → 推进 `v9.4.2 / .NET 8` → 稳定后评估 `v10.x / .NET 9` 与未来 `.NET 10`。

## 11. 下一步

用户 review 本设计后，下一步不应直接修改框架源码，而应先编写实施计划。实施计划应优先覆盖：

1. 将 `proj-rename-ps` 迁入 `Yoyo.Abp` 仓库；
2. 参数化迁移入口；
3. 固化当前 `7.3.0.12` 包面与下游消费基线；
4. 建立迁移规则清单；
5. 重建 `7.4` 标准生成路径；
6. 将 `7.4` 生成结果回灌到当前基线派生的验证分支；
7. 定义进入 `v9.4.2 / .NET 8` 的前置门禁。
