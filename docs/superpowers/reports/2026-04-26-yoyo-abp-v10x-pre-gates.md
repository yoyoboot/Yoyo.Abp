# Yoyo.Abp v10.x / .NET 9 Pre-Gates

## Governance objective

This document defines the minimum governance conditions that must be satisfied before the team starts any real `v10.x` migration wave.

For avoidance of doubt, every `v10.x` reference in this governance track is classified as **`.NET 9`**, not `.NET 10`.

## Mandatory pre-gates

| Gate | Requirement | Why it is mandatory |
| --- | --- | --- |
| G1 | `v9.4.2 / .NET 8` compatibility migration is stable on `profile-33-compat`. | `v10.x` cannot become the first place where unresolved `v9` compatibility debt is discovered. A stable `v9.4.2` baseline is the required proving ground. |
| G2 | The upgrade radar and downstream smoke templates are not only defined, but have been exercised against the `v9.4.2` track. | Governance artifacts that have never been rehearsed are paperwork, not controls. The team must prove these tools catch drift before the next generation starts. |
| G3 | At least one retirement-candidate ledger exists and is maintained for a non-core compatibility package. | The migration program must show it can govern package retirement deliberately rather than mixing compatibility work with ad hoc package shrink. |
| G4 | Product leadership records an explicit decision on **compatibility-first vs package-surface shrink** for the `v10.x` wave. | The team must not start `v10.x` with an unresolved product strategy conflict between preserving compatibility and shrinking package surface area. |
| G5 | All `v10.x` documentation, scripts, and review outputs consistently classify `v10.x` as `.NET 9`. | A generation-label error would corrupt planning assumptions, gate evaluation, and downstream communication from day one. |

## Required evidence before the gate is considered open

- A stable `v9.4.2 / .NET 8` outcome is documented and accepted as the current migration baseline.
- The existing upgrade radar report and downstream smoke templates have been run in practice, not merely drafted.
- At least one retirement ledger exists in the governance reports set; the `Log4Net` retirement candidate ledger satisfies this condition for the current checkpoint.
- The product decision for `v10.x` explicitly states one of the following modes:
  - compatibility-first, with no package shrink in the wave; or
  - compatibility plus approved package shrink, with named retirement candidates and acceptance criteria.
- All participants acknowledge that `.NET 10` is out of scope for this checkpoint and must not be inferred from `v10.x` naming.

## Operating watch points

- Authentication and identity stack drift between upstream `v9.x` and `v10.x`
- Template and configuration drift in downstream repos
- Runtime behavior drift that appears only under downstream smoke validation
- Silent upstream package additions that would expand the compatibility surface without an explicit product decision

## Start rule

Do **not** begin `v10.x / .NET 9` execution until every mandatory pre-gate above is satisfied with recorded evidence.

If any gate is missing, the correct action is to continue hardening the `v9.4.2 / .NET 8` governance baseline rather than opening `v10.x` implementation work early.