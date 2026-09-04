# Deep-research prompt — Config error tolerance (R55, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s config loading tolerates three distinct failure modes — an explicit `--config` path pointing at a missing file, an unparsable *discovered* (non-explicit) config layer, and an individually invalid config value in an otherwise-valid file — each with its own degrade-vs-fail behavior. Item kind: `bundle`. Value test: if this answer is wrong, the config-loading function's error branches for missing/unparsable/invalid-value cases, and whether a bad key is dropped-with-warning or fails the whole load, all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the repos diverge across three related-but-distinct tolerance questions. (1) An explicit `--config` path that doesn't exist: py tolerates it as an empty layer (a valid `config set` target); ts throws a usage error, exit 2. (2) An unparsable *discovered* (non-explicit) layer: py degrades to a warning and treats it as empty; ts has no discovered-and-tolerated tier to compare — its one discovered file, if present, is read the same strict way as `--config`. (3) An individually invalid config *value* in an otherwise-parseable file: py drops just the bad key with a warning; ts's zod `safeParse` failure raises `ConfigError` for the whole file. Evidence: F235 py `src/py_launch_blueprint/core/config.py:114` — `if not path.exists(): return {}`; ts `src/lib/config.ts:153` — `if (!fs.existsSync(options.configPathFlag)) { throw new UsageError(...)`, exit 2. F236 py `src/py_launch_blueprint/core/config.py:102` — `except (OSError, tomllib.TOMLDecodeError) as exc: return {}, f"ignoring unreadable config file {path}: {exc}"`; ts: none (py-only, no discovered-and-tolerated tier exists). F238 py `src/py_launch_blueprint/core/settings.py:169` — `warnings.append(f"ignoring invalid config value {section}.{key} = {bad!r}{suffix}")`; ts `src/lib/config.ts:129` — zod `safeParse` failure raises `ConfigError` for the whole file, no per-key drop. Ledger rows F235 (origin `different`), F236 (origin `py-only`), F238 (origin `py-only`) (`docs/port/COMMONALITY.md`), all verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): an unparsable *explicit* config file raises loudly in both repos (F237, `COMMON → REUSE`, inherited as-is — py `src/py_launch_blueprint/core/config.py:118` — `raise ConfigError(...)`; ts `src/lib/config.ts:119` — `throw new ConfigError(...)`); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- The area file's own note on F238 is live context, not a settled conclusion: it was "considered as an OVERRIDE candidate (serde's typed deserialization makes per-key drop-and-continue awkward) but this row's origin is py-only, not same, so OVERRIDE is not legal here; stays DIVERGENT." Propose how (or whether) Rust achieves py's per-key-drop behavior despite serde's typed, whole-struct deserialization model.
- Prior decisions of the TypeScript port that explain the current shape: none for F235/F236/F238 specifically — `TS_PORT_DECISIONS.md`'s D-017(1) covers the overall precedence chain but records no dedicated decision on any of these three tolerance questions; ts's strict-fail behavior in each case is a byproduct of its schema-validation and file-existence checks, not a separately reasoned choice.

## Out of scope
- How many config-discovery tiers exist and where they search (system/user/project); R54 (`config-discovery-tiers`) owns F230/F231/F232/F234 — this item decides what happens when a layer that tier structure discovers is missing, unparsable, or contains a bad value, not how many tiers exist.
- Whether the config file may carry a secret/token, and permission warnings on it; R56 (`config-secret-policy`) owns F239/F240/F245 — this item's tolerance rules apply to config values generally, not to secret handling specifically.
- Which crate parses TOML and which crate/mechanism performs schema validation; R52 (`toml-crate`) and R53 (`config-schema-validation`) own those — this item decides what happens on failure, not which library produces the failure.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R55
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R54 (`config-discovery-tiers`) — F236's discovered-layer tolerance only applies if R54 adopts a discovered (non-explicit) tier; treat R54's answer as open. R53 (`config-schema-validation`) — F238's per-key-drop tolerance depends on whatever validation mechanism R53 selects.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint`'s config loading tolerate (a) an explicit `--config` path pointing at a missing file, (b) an unparsable discovered config layer, and (c) an individually invalid config value in an otherwise-valid file — degrade-with-warning versus hard failure, for each.
- HIGH: For (a), does Rust follow py's tolerant shape (missing explicit path = empty layer, valid `config set` target) or ts's strict shape (exit with a usage error)? What does each imply for a `config set`-style workflow that needs to write to a not-yet-existing explicit path?
- HIGH: For (c), can serde's typed `Deserialize` impl realistically drop one bad key and keep the rest (py's behavior), or does Rust's whole-struct deserialization model force an all-or-nothing outcome unless the schema first deserializes into an untyped `toml::Value`/similar and validates key-by-key?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: For (b), assuming R54 adopts a discovered tier, is degrading an unreadable/unparsable discovered file to a warning-and-skip a few lines of `match` on the parse `Result`, or does it need a more structured "layer with provenance" abstraction to report which file the warning is about?
- MEDIUM: What warning-emission mechanism (matching R58/R59's eventual logging pipeline) surfaces these three degrade cases — a `Vec<String>` of warnings returned alongside the config (py's shape), or a `tracing::warn!` call at the point of degradation?
- LOW: Does this pattern's error type distinguish "expected, tolerated" outcomes from "unexpected, fatal" ones in the same style R03 (`port-absence-vs-failure-contract`) already establishes for the I/O seam — should this item reuse that pattern rather than invent a parallel one?

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
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
