# Deep-research prompt — Config schema validation (R53, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: which crate(s)/mechanism validates `rs-launch-blueprint`'s config file against a typed schema after TOML parsing, playing the role py's `pydantic` and ts's `zod` play. Item kind: `crate`. Value test: if this answer is wrong, the config schema's type definitions and the validation call that runs immediately after TOML deserialization get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos validate the parsed config file against a typed schema before use — that pattern itself is inherited as-is (F229, `COMMON → REUSE`, no research item owns it); only the validation *library* differs (F228, `DIVERGENT`). Evidence: py `src/py_launch_blueprint/core/settings.py:33` — `from pydantic import BaseModel, ValidationError`; py `src/py_launch_blueprint/core/settings.py:40` — `class OutputSettings(BaseModel):` (typed schema, `format`/`color` literals); ts `src/lib/config.ts:21` — `import { z } from 'zod';`; ts `src/lib/config.ts:33` — `configFileSchema` (`token`/`workspace`/`limit`). Ledger row F228 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; F229 (pattern row, `COMMON → REUSE`, no research item — "both validate the parsed file against a typed schema before use; the validation library is F228; serde's typed deserialization preserves this same pattern, so this is a substitution in spirit, not an override").
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Which crate parses/writes the raw TOML bytes is R52's decision, not this item's — design this item's schema types to sit downstream of whatever R52 returns (a parsed value or a directly-deserialized struct).
- Prior decisions of the TypeScript port that explain the current shape: D-017(4) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts chose zod v4 (4.4.3), `safeParse` on the merged config with fail-fast field-level errors, deliberately upgrading from the org's earlier Zod v3 precedent because "Zod 4 is the current stable major (57% smaller, much faster) and erases valibot's size argument, which has no org precedent."

## Out of scope
- Which crate parses/writes the raw TOML bytes; R52 (`toml-crate`) owns F225/F226 — this item defines the typed schema and validation layer applied to the parsed value, not the parser.
- Whether an invalid individual config value degrades to a dropped-with-warning key or fails the whole file; R55 (`config-error-tolerance`) owns F238 — this item picks the validation library/mechanism, not its failure-tolerance policy.
- Whether the config schema may carry a `token` field at all; R56 (`config-secret-policy`) owns F239/F240 — this item's schema shape must accommodate whatever field R56 decides, not decide it here.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R53
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R52 (`toml-crate`) — this item's schema validates the value R52's parser produces. R55 (`config-error-tolerance`) decides what happens when this item's validation fails per-key; treat that as open. R56 (`config-secret-policy`) may add a `token` field to this item's schema; treat that as open.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust crate(s)/mechanism validates `rs-launch-blueprint`'s config file against a typed schema after TOML parsing, playing the role py's `pydantic` and ts's `zod` play.
- HIGH: Does `serde` derive alone (`Deserialize` with `#[serde(deny_unknown_fields)]` and enum/literal field types) reach parity with pydantic/zod's field-level validation (literal/enum constraints, custom validators, aggregate multi-field error reporting), or does it need a dedicated validation crate layered on top?
- HIGH: Survey and compare current validation-crate candidates (e.g. `validator`, `garde`) against plain `serde` for this use case — gates, maintenance state, and ergonomics.
- MEDIUM: How does the chosen mechanism report multiple field errors at once (matching zod's `safeParse` aggregate-error shape) rather than failing fast on the first bad field?
- MEDIUM: Does the chosen mechanism integrate directly with whatever TOML crate R52 selects (deserializing straight into the typed struct), or does it require an intermediate untyped value (`toml::Value`) first?
- LOW: Are there published comparisons of serde-only versus validator-crate approaches specifically for Rust CLI config files?

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
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
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
