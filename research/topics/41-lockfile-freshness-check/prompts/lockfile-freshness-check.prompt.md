# Deep-research prompt — Lockfile-freshness check hook (R41, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint` runs a pre-commit hook that checks `Cargo.lock` stays in sync with `Cargo.toml` before a dependency-manifest change is committed, since Cargo has no single canonical `--check`-style flag equivalent to `uv lock --check`. Item kind: `pattern`. Value test: if this answer is wrong, the pre-commit hook job (or its absence) and its trigger-on-staged-manifest-change condition get added, removed, or rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py runs a dedicated pre-commit hook that checks its lockfile is up to date whenever the dependency manifest or lockfile itself is staged, catching an un-relocked dependency change before the push round-trip. ts has no equivalent hook. Evidence: py `lefthook.yml:131` — `uv-lock-check` job runs `uv lock --check` when `pyproject.toml`/`uv.lock` are staged; ts: none. Ledger row: F171 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `py-only`, standalone (not decided together with any other row).
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing lockfile-freshness checking at any hook tier; ts simply never adopted one.

## Out of scope
- The git hook manager itself — its distribution/install mechanism and the full-hook-suite CI re-run; R37 (`hook-manager-distribution`) owns F143/F144/F174 — this item picks the lockfile-freshness check pattern, not the manager wrapping the pre-commit stage it would run inside.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R41
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R37 (`hook-manager-distribution`) owns the hook manager and its stage tiering this item's check would run inside; this item does not re-decide the manager.

## Questions
Decision: whether `rs-launch-blueprint` adopts a pre-commit hook that verifies `Cargo.lock` stays in sync with `Cargo.toml`, and if so, what Cargo-native or third-party mechanism implements the check given no single canonical `--check`-style flag exists.
- HIGH: Does `cargo build --locked` (or `cargo check --locked`/`cargo metadata --locked`), which fails if `Cargo.lock` would need to change, serve as a direct drop-in for `uv lock --check`'s freshness-verification role — what is its output and failure mode when run against a staged-but-uncommitted manifest change?
- HIGH: Is `--locked` fast enough to run at pre-commit (staged-file scope, on every commit) given Rust's slower per-invocation cost compared to `uv lock --check`, or does it belong at a later tier (pre-push, matching the "slower full-tree checks deferred" tiering philosophy both source repos already share)?
- MEDIUM: Should the check be scoped only to commits that stage `Cargo.toml`/`Cargo.lock` (py's trigger condition), or run unconditionally given `--locked`'s cost profile might make conditional triggering unnecessary?
- MEDIUM: Are there other Cargo-ecosystem crates or scripts commonly used for this exact check (e.g. wrapping `cargo update --locked --dry-run` or `cargo generate-lockfile --locked`) with better error messaging than the bare `--locked` flag?
- LOW: What is the idiomatic user-facing error message and remediation instruction (e.g. "run `cargo build` to update `Cargo.lock`, then re-stage it") for a Rust equivalent of this hook?

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
name · where documented · adopters that practice it · date of the most recent authoritative write-up
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
