# Deep-research prompt — Web env settings (R77, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s web service loads typed, env-var-driven settings under an app-derived prefix and threads them through the web framework's state/DI mechanism. Item kind: `crate`. Value test: if this answer is wrong, the web crate's settings module (env-prefix derivation, struct fields, parsing/validation) and the code path that threads it into request handlers both get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py's web layer loads settings from environment variables into a typed object under a prefix derived from the app name at import time; ts has no web service to compare against (no equivalent settings object exists). Evidence: py `src/py_launch_blueprint/web/settings.py:38` — `ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"`; ts: none (no web service exists in ts; F303). Ledger rows: F324 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Which web framework the settings object is threaded through, and how that framework exposes state/DI to handlers, is undecided (`web-extra-surface`, owned by R69) — do not assume a specific framework's extractor API.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing web env-settings.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): We should take the principles from the Python implementation and make sure there are equivalents in TypeScript and Rust.

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the settings-loading crate and describes how it fits any candidate framework's DI mechanism.
- The CLI's own config schema, file discovery tiers, error tolerance, and secret policy (`docs/port/areas/config-env-logging.md`); R53 (`config-schema-validation`), R54 (`config-discovery-tiers`), R55 (`config-error-tolerance`) and R56 (`config-secret-policy`) own that — this item is scoped to the web-only, env-only settings object with its derived prefix, not the CLI's layered file+env config.
- The stable error-code catalog and exit-code mapping; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — state how a malformed/missing env var surfaces as an error, do not design a new taxonomy.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R77
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework whose state/DI mechanism this item's settings object is threaded through; treat the framework choice as open and answer *Fit for this template* generically or per-candidate-framework rather than assuming one.
- related (not a registry dependency): R53 (`config-schema-validation`) decides the CLI's general config schema/validation crate; this item's env-settings object is web-only and does not need to share a crate with it, though reuse is a valid finding if the crate fits both.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust crate(s) load typed, env-var-driven web settings under an app-derived prefix and thread them through the web framework's state/DI mechanism, matching py's `pydantic-settings`-based `WebSettings` object.
- HIGH: What crate(s) provide typed env-var deserialization with a configurable/derivable prefix, analogous to `pydantic-settings`' `env_prefix` (candidates to investigate: `envy`, `config`, `figment`, hand-rolled `serde` + `std::env`)?
- HIGH: Does the candidate support deriving the prefix from an app-name constant at compile time (matching py's `f"{APP_NAME.upper()}_WEB_"`), or must the prefix be hand-maintained as a string literal per fork?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: How does the crate's parsed output typically get threaded through a Rust web framework's state/DI mechanism (e.g. `axum::extract::State<T>`, `actix_web::web::Data<T>`) without duplicating parsing logic between the CLI and web front-ends — is a shared settings struct constructed once at startup and cloned/`Arc`-wrapped into the framework's state, matching py's app-factory composition?
- MEDIUM: What is each candidate's error-reporting shape for malformed/missing env vars (field name, expected type, offending value), and can it surface through the template's error-taxonomy/exit-code convention (owned by R67) without a translation layer?
- LOW: Do these crates support layering (env over file over default) or only flat env-var parsing — relevant only as a note for a future config-discovery item, not a decision to make here?

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
