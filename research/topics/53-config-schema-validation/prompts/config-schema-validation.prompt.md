# Deep-research prompt — Config schema validation (R53, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: which crate(s)/mechanism validates `rs-launch-blueprint`'s config file against a typed schema after TOML parsing, playing the role py's `pydantic` and ts's `zod` play. Item kind: `crate`. Value test: if this answer is wrong, the config schema's type definitions and the validation call that runs immediately after TOML deserialization get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos validate the parsed config file against a typed schema before use — that pattern itself is inherited as-is (F229, `COMMON → REUSE`, no research item owns it); only the validation *library* differs (F228, `DIVERGENT`). Evidence: py `src/py_launch_blueprint/core/settings.py:33` — `from pydantic import BaseModel, ValidationError`; py `src/py_launch_blueprint/core/settings.py:40` — `class OutputSettings(BaseModel):` (typed schema, `format`/`color` literals); ts `src/lib/config.ts:21` — `import { z } from 'zod';`; ts `src/lib/config.ts:33` — `configFileSchema` (`token`/`workspace`/`limit`). Ledger row F228 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; F229 (pattern row, `COMMON → REUSE`, no research item — "both validate the parsed file against a typed schema before use; the validation library is F228; serde's typed deserialization preserves this same pattern, so this is a substitution in spirit, not an override").
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Which crate parses/writes the raw TOML bytes is R52's decision, not this item's — design this item's schema types to sit downstream of whatever R52 returns (a parsed value or a directly-deserialized struct).
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
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

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

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
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
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
