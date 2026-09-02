# Deep-research prompt — TOML crate (R52, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates (with versions) for: which crate(s) `rs-launch-blueprint` uses to parse and serialize its TOML config file — a single crate that both parses and writes (matching ts's `smol-toml` shape) or two crates split by responsibility (matching py's `tomllib`/`tomli_w` split). Item kind: `bundle`. Value test: if this answer is wrong, the TOML dependency declaration in `Cargo.toml` and every call site that reads or writes the config file get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): TOML itself is already the fixed config format (F224, `COMMON → REUSE`, inherited as-is — not this item's decision). The libraries used to parse and write it differ: py splits parsing (`tomllib`, stdlib) from writing (`tomli_w`); ts's `smol-toml` does both. Evidence: py `src/py_launch_blueprint/core/config.py:40` — `import tomllib`; py `src/py_launch_blueprint/core/config.py:45` — `import tomli_w`; ts `src/lib/config.ts:20` — `import { parse, stringify } from 'smol-toml'` (one library, both directions). Ledger rows F225, F226 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: TOML is the config file format and the `<tool>_config.toml` naming convention (F224, F227, both `COMMON → REUSE`, inherited as-is); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-017(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts chose `smol-toml` 1.7.0 for being the only candidate that is current (2026-06 release), TOML 1.1.0 spec-complete, both parse and stringify, zero-dep ESM, and runtime-agnostic; `@iarna/toml` and `toml` were rejected as stale or parse-only.

## Out of scope
- The TOML format itself and the config-file naming convention; F224 and F227 are `COMMON → REUSE`, already inherited — do not re-litigate that TOML is used or how the file is named.
- Config schema validation applied to the parsed value; R53 (`config-schema-validation`) owns F228 — this item picks the parse/write crate(s), not the typed-schema/validation layer built on top of them.
- How a missing, unparsable, or otherwise-failed config read maps to a domain error or exit code; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item's chosen crate(s) must surface a distinguishable error, not classify it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R52
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R53 (`config-schema-validation`) validates the value this item's parser produces; this item does not decide the schema or validation mechanism.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which crate(s) `rs-launch-blueprint` uses to parse and serialize its TOML config file, and whether that is one crate covering both directions or two crates split by responsibility.
- HIGH: Compare `toml`, `basic-toml`, and `toml_edit` (and any other current contender) on serde integration, round-trip fidelity (comment/formatting preservation on write), and MSRV — which one (or pair) best matches py's parse/write split or ts's single-crate shape?
- HIGH: Does a single crate handle both parse and write with full round-trip fidelity, or does reaching py's atomic-write-with-0600-permissions behavior (F243, already-decided inherited pattern) need a companion crate or hand-rolled `std::fs` logic regardless of which TOML crate is chosen?
- MEDIUM: Which candidate integrates most directly with `serde`'s `Deserialize`/`Serialize` derive, given R53 will define a typed config schema on top of whatever this item returns?
- MEDIUM: What is each candidate's compile-time and binary-size cost, given the template targets a CLI, a library, and (optionally) a web service?
- LOW: Is there an ecosystem-standard adopters list or style guide favoring one TOML crate over another for CLI/config-file use cases specifically?

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

### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
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
