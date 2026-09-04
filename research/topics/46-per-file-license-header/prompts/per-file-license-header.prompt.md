# Deep-research prompt — Per-file embedded license header (R46, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint` source files carry a per-file embedded license header, and what boilerplate it uses, given the fixed `license` parameter is dual `MIT OR Apache-2.0` rather than either source repo's single-license text. Item kind: `pattern`. Value test: if this answer is wrong, every `.rs` source file's header comment (or its absence) changes, and any enforcement/insertion tooling for it is added or removed.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge in how far each carried a per-file license header. py stamps a full 18-line MIT header comment on every source file (51 files). ts inherited that same 18-line header text verbatim into 12 copied config/workflow files but never finished converting it to a one-line SPDX comment as its own port decision intended, and carries no header at all in its `.ts` source files. Evidence: py `src/py_launch_blueprint/__init__.py:1` — full 18-line MIT header comment, present in 51 files; ts `.github/dependabot.yml:1` — legacy unconverted 18-line 2025 header, present in 12 config/workflow files; `.github/FUNDING.yml:1` — the one file where the intended conversion to a 2-line SPDX comment actually landed. Ledger row: F207 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Already decided, do not re-open: the root `LICENSE` file itself is `COMMON → REUSE` (F206, `docs/port/COMMONALITY.md`) with its value set by the fixed `license` parameter (`MIT OR Apache-2.0`, an owner override already recorded in `docs/port/PARAMETERS.md`) — this item decides only the per-file header, not the root license text or file. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-024(7) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — the intent was to add a root `LICENSE` file plus a `package.json` license field, then replace the 18-line embedded MIT headers with one-line SPDX-License-Identifier comments repo-wide, with no header-insertion automation; in the pinned ts commit that conversion landed only in `FUNDING.yml`, leaving the other 12 originally-copied files with the old unconverted header and every `.ts` source file with none — the decision's *intent* (SPDX one-liner, no automation) is the prior art to weigh, not its incomplete execution.

## Out of scope
- The root `LICENSE` file's own text and mechanism; that is `COMMON → REUSE` (F206) with its value already fixed by the `license` parameter — this item covers only the per-source-file header.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R46
- owns:
- consumes:
- related (not a registry dependency): none — this item's decision depends only on the already-fixed `license` parameter, not on any other research item's registered output.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s `.rs` source files carry a per-file embedded license header, and if so, what exact boilerplate — a full license-text block (py's pattern) or a one-line SPDX-License-Identifier comment (ts's stated intent) — given the dual `MIT OR Apache-2.0` license.
- HIGH: What is the correct SPDX license-expression syntax for a dual `MIT OR Apache-2.0` header comment in a Rust source file, and is a one-line `// SPDX-License-Identifier: MIT OR Apache-2.0` comment sufficient on its own, or does convention also expect a copyright-line companion?
- HIGH: Is per-file license-header stamping (of either shape) still common practice among current, actively-maintained Rust template/library repositories with a dual MIT/Apache-2.0 license, or has the ecosystem converged on relying on the root `LICENSE`/`Cargo.toml` `license` field alone with no per-file header?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).
- MEDIUM: If a header is adopted, is there a maintained Rust tool (e.g. a `cargo` subcommand, a lefthook-invokable script) that inserts or verifies the header across the tree, avoiding ts's documented "no header-insertion automation" gap that left its conversion incomplete?
- LOW: Does Rust doc-comment convention (`//!` module-level docs) create a placement conflict with a header comment at the top of a file that also carries crate-level documentation?

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
