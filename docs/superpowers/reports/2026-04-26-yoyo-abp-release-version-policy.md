# Yoyo.Abp Release / Version / Feed Policy

## Scope

This document defines the versioning, branch, and feed policy for Yoyo.Abp release lines after the migration-governance tooling baseline was introduced.

The goal is to make `release/*`, `verify/*`, package versions, downstream consumption, and migration-engine commits evolve as one coherent system rather than as ad hoc per-version decisions.

## Core policy

### Branch roles

- `release/<upstream-version>` is the stable branch for downstream consumption.
- `verify/<upstream-version>-yoyo-on-<previous-baseline>` is the validation branch used to prove the next formal package line before it is promoted.
- `sync/*` or upstream input directories remain migration inputs and must not be treated as publishable package branches.

### Package channel roles

- `release/*` package lines publish to the **stable feed**.
- `verify/*` package lines publish to the **validation feed**.
- Validation packages must complete package smoke and downstream smoke before they are promoted into a stable release line.

### Version shape

Use a three-segment package version for every formal release or validation package line.

Examples:

- `release/7.4` -> `7.4.0`
- `verify/7.4-yoyo-on-dev-7.3.0` -> `7.4.1`
- `release/9.4.2` -> `9.4.2`
- `verify/9.4.2-yoyo-on-release-7.4` -> `9.4.3`
- `release/10.3` -> `10.3.0`
- `verify/10.3.1-yoyo-on-release-9.4.2` -> `10.3.2`

Rule summary:

1. `release/*` uses the branch token as the formal package version token.
2. Two-segment release tokens are normalized to `.0`.
3. `verify/*` uses the current formal package version token as the base, then increments the patch segment by one.
4. Future patch lines continue by incrementing the third segment.

## Current agreed version targets

### `7.4` line

- `release/7.4` produces `7.4.0`
- `verify/7.4-yoyo-on-dev-7.3.0` produces `7.4.1`
- `7.4.1` is a **formal patch target**, not a long-lived verify-only package identity

### `9.4.2` line

- `release/9.4.2` produces `9.4.2`
- `verify/9.4.2-yoyo-on-release-7.4` produces `9.4.3`
- Promotion to `release/9.4.2` requires real migration output plus package/downstream verification, not governance tooling alone

### `10.3` line

- `release/10.3` produces `10.3.0`
- future validation examples follow the same patch rule, for example `verify/10.3.1-yoyo-on-release-9.4.2` -> `10.3.2`
- `v10.3` is classified as the `.NET 9` generation and must not be treated as `.NET 10`

## Promotion policy

### Verify to release promotion

A `verify/*` package line may be promoted only after all of the following are true:

1. Migration-engine output passes package-surface and legacy-exclusion validation.
2. Package smoke succeeds.
3. Downstream smoke succeeds for at least `YoyoBoot` and `Rider aspnet-core`.
4. Any governance gates for the target generation are satisfied.
5. Promotion is recorded as an explicit release decision.

### Downstream consumption rule

Downstream repositories should consume:

- **stable feed packages** for normal development and production validation
- **validation feed packages** only when participating in an explicit verify campaign

This avoids accidental adoption of an in-progress migration line.

## Tooling policy

### Shared versioning helper

The package-version decision chain is centralized in:

- `tools/yoyo-abp-migration/YoyoAbpVersioning.ps1`

Precedence order:

1. explicit version override
2. production `TAG` when `IS_PRODUCTION=true` and the `TAG` value is already version-shaped
3. branch-aware mapping for `release/*` and `verify/*`
4. `common.props`

### Build and pack entry points

- `nupkg/pack.ps1` supports explicit `-Version` and branch-aware fallback.
- `nupkg/pack.ps1` must ignore production `TAG` values that are actually branch names such as `release/7.4`; those lines must still resolve through branch policy.
- `nupkg/pack_push.ps1` supports explicit `NUGET_CHANNEL` override and otherwise derives `stable` / `validation` from the current branch.
- `stable` publish routing uses `NUGET_STABLE_SOURCE` / `NUGET_STABLE_SOURCE_APIKEY`; `validation` routing uses `NUGET_VALIDATION_SOURCE` / `NUGET_VALIDATION_SOURCE_APIKEY`.
- `nuke Pack` must be given `--packageVersion`; it must fail fast when the version is omitted.
- `version-update.ps1` and `read-version.ps1` remain `common.props` utilities and are not, by themselves, the full branch-aware release policy.

### GitLab branch publishing

- `.gitlab-ci.yml` now includes `.gitlab/ci/module-nuget.branch-ci.yml` in addition to the legacy tag pipeline.
- `release/*` branches produce package artifacts and expose a manual stable-feed publish job.
- `verify/*` branches produce package artifacts and expose a manual validation-feed publish job.
- Tag-based publishing remains available for legacy release automation, but branch lines are now first-class publish routes.

## Commit policy for `proj-rename-ps`

`proj-rename-ps` is a long-lived migration engine and must preserve its own reviewable commit history.

Do not collapse the following into one mixed release commit:

- migration-engine refactors
- manifest/rule changes
- governance documentation
- generated release outputs
- downstream-specific patch adjustments

Recommended split:

1. engine/tooling change commit
2. governance/policy document commit
3. verify/release output commit
4. downstream promotion or patch commit

## Operational notes

- A verify branch should not become a permanent multi-purpose branch. Once a patch is promoted, create or advance the next verify line deliberately.
- A release branch should represent a stable downstream-consumable package line, not merely “the latest worktree that passed once.”
- Future version lines should reuse the same template instead of inventing new version semantics each time.

## Completion intent

This policy is the closure template for:

- `7.4`
- `9.4.2`
- `10.3`
- and future Yoyo.Abp migration lines that follow the same release / verify / promotion model.
