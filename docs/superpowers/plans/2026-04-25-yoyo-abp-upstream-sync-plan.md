# Yoyo.Abp release/7.4 Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 产出 `release/7.4` 相对 `codex/dev-7.3.0` 的代码差异审计、NuGet 清单审计与候选移除池，并把审计结论回写到当前升级路线文档中，为后续是否 merge 以及是否进入 `v9.4.2 / .NET 8` 实施提供依据。

**Architecture:** 这不是继续改框架代码的计划，而是一份文档化审计计划。实施时只做只读比对与文档产出：先生成代码差异报告，再生成 NuGet / 打包边界报告，随后归纳“永久保留 / 7.4 阶段保留 / `v9.4.2` 优先复审”三类候选池，最后将结论回写到设计与计划文档。整个阶段不 merge `release/7.4`，不进入 `v9.4.2` 实现。

**Tech Stack:** Git、PowerShell、Markdown、ASP.NET Boilerplate 解决方案结构、NuGet 打包脚本 `nupkg/pack.ps1`

---

## Scope check

已批准的 spec 覆盖了三个相互独立的后续子项目：

1. `release/7.4` 审计落地
2. `v9.4.2 / .NET 8` 桥接实施
3. `v10.x / v10.3` 是否继续推进的后续评审

根据当前设计优先级，本计划只覆盖 **第一个子项目：`release/7.4` 审计落地**。`v9.4.2` 的实施计划必须等当前审计结论稳定后再单独编写。

## File map

### Create

- `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md` — 代码差异审计报告，按模块归类 `release/7.4` 与 `codex/dev-7.3.0` 的差异热点与性质。
- `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md` — NuGet / 打包清单审计报告，对比 `nupkg/pack.ps1`、项目列表和发包边界。
- `docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md` — 候选移除池，按“永久保留 / 7.4 阶段保留 / `v9.4.2` 优先复审”分类。

### Modify

- `docs/superpowers/plans/2026-04-25-yoyo-abp-upstream-sync-plan.md` — 当前计划文件本身；若审计边界发生变化，需要同步修订。
- `docs/superpowers/specs/2026-04-25-yoyo-abp-upstream-sync-design.md` — 仅在审计结果与当前 spec 的初步结论不一致时回写修订。

### Existing files used as audit sources

- `nupkg/pack.ps1` — 当前分支打包入口脚本。
- `Abp.sln` — 用于确认项目面与解决方案暴露面。
- `src/**` 与 `test/**` — 用于确认差异热点集中区域。

---

### Task 1: 创建审计报告骨架并锁定输入边界

**Files:**
- Create: `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md`
- Create: `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md`
- Create: `docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md`

- [ ] **Step 1: 创建报告目录并确认当前基线分支可读**

Run:

```powershell
New-Item -ItemType Directory -Force docs/superpowers/reports | Out-Null
git branch --show-current
git rev-parse --verify release/7.4
git rev-parse --verify codex/dev-7.3.0
```

Expected:
- 当前分支输出为 `codex/dev-7.3.0`
- `release/7.4` 与 `codex/dev-7.3.0` 两个引用都能解析成功

- [ ] **Step 2: 写入代码差异报告骨架**

Write `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md`:

```markdown
# release/7.4 vs codex/dev-7.3.0 Code Audit

## Summary

- Audit target: `release/7.4`
- Baseline: `codex/dev-7.3.0`
- Scope: code-only diff review before merge discussion

## Hotspot directories

| Area | Status | Notes |
| --- | --- | --- |
| `src/Abp.Zero.Common/*` | pending | |
| `src/Abp.Zero/*` | pending | |
| `src/Abp.ZeroCore/*` | pending | |
| `src/Abp.EntityFramework.Common/*` | pending | |
| `src/Abp.EntityFrameworkCore.EFPlus/*` | pending | |
| `src/Abp.AutoMapper/*` | pending | |
| `test/Abp.Tests/*` | pending | |
| `test/Abp.EntityFrameworkCore.Tests/*` | pending | |
| `test/Abp.ZeroCore.SampleApp/*` | pending | |
| `test/Abp.ZeroCore.Tests/*` | pending | |

## Classification

| Bucket | Definition | Current findings |
| --- | --- | --- |
| Permanent Yoyo delta | Must survive future upstream syncs | |
| `7.4` stage keep | Keep on `release/7.4`, re-check later | |
| Upstream-aligned change | Should not be treated as fork-specific permanent delta | |

## Merge recommendation inputs

- Is `release/7.4` safe to merge immediately?
- Which diffs are too coupled to decide without `v9.4.2` context?
- Which areas are already well-justified as permanent `string`-key deltas?
```

- [ ] **Step 3: 写入 NuGet 审计报告骨架**

Write `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md`:

```markdown
# release/7.4 vs codex/dev-7.3.0 NuGet Audit

## Summary

- Audit target: `release/7.4`
- Baseline: `codex/dev-7.3.0`
- Source of truth: `nupkg/pack.ps1`

## Script behavior delta

| Concern | `codex/dev-7.3.0` | `release/7.4` | Impact |
| --- | --- | --- | --- |
| Script root handling | pending | pending | |
| Restore/build failure handling | pending | pending | |
| Package count output | pending | pending | |

## Package set delta

| Package or project line | `codex/dev-7.3.0` | `release/7.4` | Classification |
| --- | --- | --- | --- |

## Auth package status

| Package family | `release/7.4` status | Notes |
| --- | --- | --- |
| `IdentityServer4` | keep | |
| `IdentityServer4.EntityFrameworkCore` | keep | |
| `IdentityServer4.vNext` | keep | |
| `IdentityServer4.vNext.EntityFrameworkCore` | keep | |

## Preliminary decision

- Which package lines are permanent?
- Which package lines are `7.4`-stage keep only?
- Which package lines should be re-reviewed first on `v9.4.2`?
```

- [ ] **Step 4: 写入候选移除池骨架**

Write `docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md`:

```markdown
# release/7.4 Candidate Removal Pool

## Permanent keep

| Item | Why it stays | Evidence source |
| --- | --- | --- |

## Keep on 7.4, revisit on v9.4.2

| Item | Why it stays for now | Revisit trigger |
| --- | --- | --- |

## First-priority review on v9.4.2

| Item | Why it becomes review candidate | Related module |
| --- | --- | --- |

## Not enough evidence yet

| Item | Missing evidence | Next source |
| --- | --- | --- |
```

- [ ] **Step 5: 提交报告骨架**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md
git commit -m "docs: add release 7.4 audit report skeletons"
```

Expected:
- 生成一个只包含审计文档骨架的提交

---

### Task 2: 生成代码差异审计结论

**Files:**
- Modify: `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md`

- [ ] **Step 1: 采集整体 diff 规模与热点目录**

Run:

```powershell
git diff --stat codex/dev-7.3.0..release/7.4
git diff --name-only codex/dev-7.3.0..release/7.4 | Select-String "^(src|test)/"
```

Expected:
- 第一条输出可用于判断改动规模
- 第二条输出可用于归纳热点目录

- [ ] **Step 2: 采集提交层面的高层语义线索**

Run:

```powershell
git log --oneline --no-merges codex/dev-7.3.0..release/7.4
```

Expected:
- 输出中能看到与 `string` 主键、`pack.ps1`、测试修复、Zero/ZeroCore 收口相关的提交主题

- [ ] **Step 3: 用固定分类回填代码审计报告**

Update the `## Classification` section of `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md` so it includes at least this table:

```markdown
| Bucket | Definition | Current findings |
| --- | --- | --- |
| Permanent Yoyo delta | Must survive future upstream syncs | Default `string` primary-key shortcut chain, plus the explicit generic fixes needed to keep that chain valid in Zero / OData / NHibernate / helper code. |
| `7.4` stage keep | Keep on `release/7.4`, re-check later | Auth-related project set, pack outputs, SampleApp references, and compatibility fixes needed only because `release/7.4` is still a `.NET 6` / pre-`v9.4.2` landing zone. |
| Upstream-aligned change | Should not be treated as fork-specific permanent delta | Pure upstream sync effects, test baseline shifts, package/build script hardening that should move with the branch rather than live as a separate Yoyo policy. |
```

- [ ] **Step 4: 补全热点模块结论**

For each hotspot row in the report, replace `pending` with one short conclusion in this style:

```markdown
| `src/Abp.ZeroCore/*` | reviewed | Heavy overlap of upstream sync and `string`-key replay; not safe to flatten into a one-line merge decision. |
| `test/Abp.ZeroCore.SampleApp/*` | reviewed | Mostly compatibility and auth-reference preservation for the `7.4` landing zone, not a permanent policy by itself. |
```

Do not leave any hotspot row as `pending`.

- [ ] **Step 5: 在报告末尾写出审计结论**

Append this section to `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md`:

```markdown
## Conclusion

- `release/7.4` is a stable audit baseline, not an automatic merge baseline.
- The dominant permanent delta remains the default `string` primary-key system.
- Several `release/7.4` differences are better understood as stage-specific compatibility keepers than as permanent fork policy.
- Merge should be discussed only after combining this report with the NuGet audit and candidate-removal classification.
```

- [ ] **Step 6: 提交代码审计报告**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-code-audit.md
git commit -m "docs: add release 7.4 code audit"
```

Expected:
- 生成一条仅包含代码审计结论的提交

---

### Task 3: 生成 NuGet / 打包清单审计结论

**Files:**
- Modify: `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md`

- [ ] **Step 1: 直接对比两个分支上的 `nupkg/pack.ps1`**

Run:

```powershell
git show codex/dev-7.3.0:nupkg/pack.ps1 > $env:TEMP\pack-dev-7.3.0.ps1
git show release/7.4:nupkg/pack.ps1 > $env:TEMP\pack-release-7.4.ps1
git diff --no-index $env:TEMP\pack-dev-7.3.0.ps1 $env:TEMP\pack-release-7.4.ps1
```

Expected:
- diff 能清晰暴露脚本路径处理、失败处理和项目列表差异

- [ ] **Step 2: 回填脚本行为差异表**

Update the `## Script behavior delta` section so it contains at least these rows:

```markdown
| Concern | `codex/dev-7.3.0` | `release/7.4` | Impact |
| --- | --- | --- | --- |
| Script root handling | Relies more on current directory assumptions | Uses `$PSScriptRoot` as stable path base | Makes pack behavior reproducible across working directories |
| Restore/build failure handling | Can hide failures behind later success-looking output | Checks `LASTEXITCODE` and fails earlier | Removes false-positive packaging results |
| Package count output | No reliable summary line | Emits `package count` | Makes smoke verification faster |
```

- [ ] **Step 3: 列出包集差异，并明确认证包当前仍保留**

Update the `## Package set delta` section so it includes at least these rows:

```markdown
| Package or project line | `codex/dev-7.3.0` | `release/7.4` | Classification |
| --- | --- | --- | --- |
| `Abp.ZeroCore.NHibernate` | absent from pack list | present in pack list | `7.4` stage keep pending later review |
| `Abp.ZeroCore.IdentityServer4` family | present | present | keep on `7.4`; not yet a removal action |
| `Abp.ZeroCore.IdentityServer4.vNext` family | present | present | keep on `7.4`; re-review on `v9.4.2` |
```

- [ ] **Step 4: 写出 NuGet 审计结论**

Append this section to `docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md`:

```markdown
## Conclusion

- The package surface did not shrink dramatically between the two branches.
- The most important `release/7.4` change is packaging reliability, not aggressive package removal.
- Auth packages remain part of the `7.4` package surface and should not be treated as already-removed debt.
- Candidate package removals should be discussed in the context of `v9.4.2`, not forced into the `7.4` merge decision.
```

- [ ] **Step 5: 提交 NuGet 审计报告**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-release-7.4-vs-dev-7.3.0-nuget-audit.md
git commit -m "docs: add release 7.4 nuget audit"
```

Expected:
- 生成一条仅包含 NuGet 审计结论的提交

---

### Task 4: 整理候选移除池并给出 merge 前决策输入

**Files:**
- Modify: `docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md`

- [ ] **Step 1: 先写入第一版分类结论**

Update `docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md` so it contains at least these rows:

```markdown
## Permanent keep

| Item | Why it stays | Evidence source |
| --- | --- | --- |
| Default `string` primary-key shortcut chain | This is the defining long-term Yoyo delta | Code audit |
| Explicit generic-key fixes around Zero / OData / NHibernate shortcuts | Required to keep the `string` default internally consistent | Code audit |

## Keep on 7.4, revisit on v9.4.2

| Item | Why it stays for now | Revisit trigger |
| --- | --- | --- |
| `IdentityServer4` package pair | Still part of the `7.4` package surface and compatibility story | `v9.4.2` auth-line review |
| `IdentityServer4.vNext` package pair | Still part of the `7.4` package surface and compatibility story | `v9.4.2` auth-line review |
| `Abp.ZeroCore.NHibernate` pack line | Present in `release/7.4`, but not yet classified as permanent | `v9.4.2` packaging review |

## First-priority review on v9.4.2

| Item | Why it becomes review candidate | Related module |
| --- | --- | --- |
| Classic `IdentityServer4` line | Upstream lifecycle pressure increases in the `.NET 8` generation | Auth modules |
| SampleApp auth-specific references | They may only exist to keep the `7.4` landing zone compiling | `test/Abp.ZeroCore.SampleApp/*` |
| Stage-specific pack entries | Packaging behavior must be rechecked when the target runtime changes | `nupkg/pack.ps1` |
```

- [ ] **Step 2: 补上“不足证据”区**

Add at least these rows under `## Not enough evidence yet`:

```markdown
| Item | Missing evidence | Next source |
| --- | --- | --- |
| Any package or module not seen in both the code audit and NuGet audit | No cross-report confirmation yet | Re-check after both reports are finalized |
| Future `OpenIddict` package assumptions | Outside `7.4` audit scope | `v9.4.2` / later design work |
```

- [ ] **Step 3: 写出 merge 前结论块**

Append this section to the report:

```markdown
## Merge-decision input

- Do not treat `release/7.4` as pre-approved for immediate merge.
- Do not delete auth-related packages during the audit stage.
- Use this pool to drive the first `v9.4.2` review, not to force premature cleanup on `.NET 6`.
```

- [ ] **Step 4: 提交候选移除池报告**

Run:

```powershell
git add docs/superpowers/reports/2026-04-25-release-7.4-candidate-removal-pool.md
git commit -m "docs: classify release 7.4 removal candidates"
```

Expected:
- 生成一条仅包含候选池分类的提交

---

### Task 5: 回写审计结论并冻结下一步边界

**Files:**
- Modify: `docs/superpowers/specs/2026-04-25-yoyo-abp-upstream-sync-design.md`
- Modify: `docs/superpowers/plans/2026-04-25-yoyo-abp-upstream-sync-plan.md`

- [ ] **Step 1: 只在发现不一致时回写设计文档**

Decision rule:

- 如果三份报告的结论与当前 spec 一致，则不要改 `docs/superpowers/specs/2026-04-25-yoyo-abp-upstream-sync-design.md`；
- 只有在发现以下任一情况时才回写：
  - `release/7.4` 不应再被视为稳定审计基线；
  - `v9.4.2` 不再适合作为主推荐下一跳；
  - `IdentityServer4 / vNext / OpenIddict` 生命周期判断需要纠偏。

- [ ] **Step 2: 在计划文件末尾追加执行边界说明**

Append this section to `docs/superpowers/plans/2026-04-25-yoyo-abp-upstream-sync-plan.md` after the self-review block:

```markdown
## Execution boundary after this plan

- This plan ends when the three audit reports are committed and reviewed.
- Merge discussion happens after the audit, not during it.
- A separate `v9.4.2 / .NET 8` implementation plan must be written before any upgrade execution starts.
```

- [ ] **Step 3: 验证本阶段只有文档改动**

Run:

```powershell
git diff --name-only HEAD~4..HEAD
```

Expected:
- 输出只包含 `docs/superpowers/reports/*.md` 与必要时的 `docs/superpowers/specs/*.md` / `docs/superpowers/plans/*.md`
- 不应出现 `src/`、`test/`、`nupkg/` 等实现文件改动

- [ ] **Step 4: 提交计划收口更新**

Run:

```powershell
git add docs/superpowers/plans/2026-04-25-yoyo-abp-upstream-sync-plan.md docs/superpowers/specs/2026-04-25-yoyo-abp-upstream-sync-design.md
git commit -m "docs: finalize release 7.4 audit execution boundary"
```

Expected:
- 生成一条只包含计划/设计边界说明的提交

---

## Self-review

### Spec coverage

- `release/7.4` 作为稳定审计基线：Task 1、Task 2、Task 5
- `release/7.4` 与 `codex/dev-7.3.0` 的代码差异审计：Task 2
- `release/7.4` 与 `codex/dev-7.3.0` 的 NuGet 清单审计：Task 3
- 候选移除池：Task 4
- 先审计、后讨论 merge：Task 4、Task 5
- 先不进入 `v9.4.2` 实施：Task 5

### Placeholder scan

已检查本计划，不包含以下失败模式：
- 没有 `TBD` / `TODO` / “后续补充”
- 没有“写一些报告/做一下审计”这种空话，每个报告步骤都给出了固定模板或明确命令
- 没有“类似 Task N”这类跳转式依赖
- 没有未定义的文件路径、分支名或命令

### Type consistency

本计划统一使用以下命名与语义：
- 审计目标分支：`release/7.4`
- 现实基线分支：`codex/dev-7.3.0`
- 下一跳版本：`v9.4.2 / .NET 8`
- 报告分类：`Permanent keep`、`Keep on 7.4, revisit on v9.4.2`、`First-priority review on v9.4.2`
