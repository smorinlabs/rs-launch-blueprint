# Deep-research prompt — `unsafe` code policy (R06, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: the repo-wide `unsafe` code policy — forbidden outright, or permitted only with a documented per-block justification — and the mechanism that enforces it. Item kind: `pattern`. Value test: if this answer is wrong, the crate-root lint attributes (or `Cargo.toml` `[lints]` table), any `// SAFETY:` comment convention, and the CI/clippy check that enforces the policy all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): none — origin `none` (RUST-ONLY). Neither py nor ts has an `unsafe`-equivalent construct to carry forward: py's memory safety is enforced by the CPython runtime, ts's by the V8/JS engine. Neither source repo's decision log addresses a safety-boundary policy because neither language exposes one. Ledger row: F023 (`docs/port/COMMONALITY.md`), verdict `RUST-ONLY` — this is a fresh, Rust-only safety-boundary decision with no cross-language precedent to inherit or override.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `unsafe` has no TypeScript analogue, so `TS_PORT_DECISIONS.md` has no relevant entry.

## Out of scope
- The Cargo workspace crate topology that would contain any `unsafe` code; R02 (`crate-boundary-enforcement`) owns F021 — this item sets the repo-wide policy and its enforcement mechanism, not which crate a future `unsafe` block would live in.
- Auditing specific dependency crates for their own internal `unsafe` usage; this item states the policy for code written in this template, not a review of the dependency tree's `unsafe` footprint.
- How the policy's enforcement check is wired into a specific CI job or hook tier; R11 (`ci-workflow-job-structure`) and R28 (`linter-and-editor-tooling`) own CI job shape and clippy/lint wiring respectively — this item names the lint/attribute that enforces the policy, not which job runs it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R06
- owns:
- consumes:
- related (not a registry dependency): R28 (`linter-and-editor-tooling`) decides how clippy/rustc lints are wired into the hook/CI pipeline. If this item recommends a clippy-based check (e.g. `clippy::undocumented_unsafe_blocks`) alongside a crate-root attribute, R28's CI-wiring answer is where that check lands — this item states the policy and the lint/attribute that expresses it, not which job runs it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what is `rs-launch-blueprint`'s repo-wide `unsafe` code policy — forbidden outright, or permitted only with a documented per-block justification — and what mechanism enforces it.
- HIGH: Should the template set `#![forbid(unsafe_code)]` (or the weaker `#![deny(unsafe_code)]`) at the crate root by default, given the template's expected dependencies (HTTP client, CLI framework, optional web framework) are all safe-Rust-only at the top level and the template itself needs no `unsafe`?
- HIGH: What do comparable Rust CLI/library/web-service templates (e.g. widely used `cargo-generate` templates, guidance from the Rust CLI working group's book) set as their default `unsafe` policy — is `forbid` (no override possible, even with justification) or `deny` (permits an explicit `#[allow(unsafe_code)]` override) the more common choice for a template meant to be forked and extended by consumers who may need `unsafe` later?
- MEDIUM: If `deny` (permitted-with-justification) is chosen instead of `forbid`, what convention documents the justification — a `// SAFETY:` comment convention (Rust API Guidelines C-SAFETY), the `clippy::undocumented_unsafe_blocks` lint enforcing that convention, or both together?
- MEDIUM: Does the policy need a mechanism for distinguishing the template's own code from its dependency tree — since a dependency's internal `unsafe` usage is unavoidable and outside the template author's control — e.g. does a tool like `cargo geiger` (or noting that `#![forbid(unsafe_code)]` only applies to the current crate, not transitive dependencies) belong in the stated policy so it is not misleadingly absolute?
- LOW: Should the policy differ between the `core`/library crate and a CLI or web front-end crate (if R02's workspace topology splits them), or apply uniformly workspace-wide via a single `[workspace.lints.rust]` table in the root `Cargo.toml`?

## Required evidence
Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
