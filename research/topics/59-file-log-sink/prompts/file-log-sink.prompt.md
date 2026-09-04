# Deep-research prompt — File log sink (R59, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` ships an optional rotating file log sink (matching py's `[logging]` config-table-driven, size+backup-count-rotated, independently-leveled file handler) or ships no file sink at all (matching ts). Item kind: `bundle`. Value test: if this answer is wrong, whether a `[logging]` table exists in the config schema at all, whether a `--log-file` flag/env and a rotation dependency exist, and the dual-sink level-floor logic all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py ships an optional rotating file log sink, configured by a `[logging]` table in the config file (`level`/`file`/`file_level`/`format` fields), enabled by a `--log-file` flag/env defaulting to an XDG state path, with flag/env > config `logging.file` > off precedence, an independently overridable file-sink format via env, and a level floor that is the minimum of the console and file sink levels so the root logger never filters out something either sink wants. ts has no file sink at all — its logger writes only to the injected stderr writer. Evidence: F255 py `src/py_launch_blueprint/core/settings.py:49` — `class LoggingSettings(BaseModel):` (`level`, `file`, `file_level`, `format` fields); ts's config schema (`src/lib/config.ts:33`) carries only `token`/`workspace`/`limit`, no logging settings. F256 py `src/py_launch_blueprint/core/logging.py:241` — `file_handler = RotatingFileHandler(file_path, maxBytes=ROTATE_MAX_BYTES, backupCount=ROTATE_BACKUP_COUNT, ...)`; ts: no file sink at all (`src/lib/logger.ts:58` writes only the injected stderr writer). F257 py `src/py_launch_blueprint/core/logging.py:82` — `ROTATE_MAX_BYTES = 10 * 1024 * 1024` / `ROTATE_BACKUP_COUNT = 5`; ts: none. F258 py `src/py_launch_blueprint/cli/options.py:93` — `"--log-file", ... envvar="PLBP_LOG_FILE",`; ts: none. F259 py `src/py_launch_blueprint/cli/context.py:212` — `def _resolve_log_file(...)`; ts: none. F260 py `src/py_launch_blueprint/cli/context.py:233` — `def _resolve_log_format(config_format: str) -> str:`; ts: none. F261 py `src/py_launch_blueprint/core/logging.py:259` — `floor = min(level, file_level)` then `root.setLevel(floor)` (`logging.py:262`); ts: none, since there is only one sink. Ledger rows F255, F256, F257, F258, F259, F260, F261 (`docs/port/COMMONALITY.md`), all verdict `DIVERGENT`, item R59.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the console/structured logging pipeline this file sink attaches to (F250-F254, F262, F263, F274) is R58's decision, not this item's — design the file sink to plug into whatever pipeline R58 recommends. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item is a strict subset of F255's `[logging]` table: `level`/`format` defaults belong to R58's console pipeline (or are shared), while `file`/`file_level` and everything below are specific to this item.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a file sink, so `TS_PORT_DECISIONS.md`'s D-018 entries (which cover only the console/stderr logger, color, verbosity, JSON envelope, and progress-stream routing) have no file-sink-specific decision to carry forward.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Implementation, but this is about the design pattern. Things like this are about making sure we have best-in-class logging, best practices, and configurations, and that we research the appropriate libraries for Python. We should take the same principles and apply them to TypeScript and Rust.

## Out of scope
- The console logging pipeline's own format-selection, redaction, tracing, and reconfiguration behavior; R58 (`logging-pipeline-architecture`) owns F250-F254/F262/F263/F274 — this item only designs the optional file sink attached to that pipeline.
- Whether a broader XDG data/state/cache directory set exists to supply this item's default file-sink path; R57 (`xdg-directory-set`) owns F249 — this item's default path assumes whatever R57 concludes; if R57 concludes no state directory exists, state that as a fallback (e.g. a relative or explicitly-flagged-only path) rather than deciding R57's question here.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R59
- owns:
- consumes:
- related (not a registry dependency): R58 (`logging-pipeline-architecture`) — this item's file sink is a component attached to R58's pipeline; treat this item as downstream of R58. R57 (`xdg-directory-set`) — this item's default file-sink path (F258) depends on whether R57 concludes a state directory exists; treat R57's answer as open and state the fallback.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does `rs-launch-blueprint` ship an optional rotating file log sink at all, and if so, what Rust crate/pattern implements size+backup-count rotation, a `[logging]` config-table section, a `--log-file` flag/env with an XDG-state-path default, flag/env > config > off precedence, an independently settable file-sink format, and a dual-sink level floor.
- HIGH: Does the crate R58 selects for the console pipeline already ship a rotating-file layer/appender, or does achieving py's exact size-plus-backup-count rotation policy (not just daily/hourly rotation) need a separate crate?
- HIGH: Survey candidates for size-based rotation with a backup-count cap specifically (as opposed to time-based rotation, which is the more common Rust-crate default) — note any gate failures.
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: How does "flag/env > config `logging.file` > off" precedence (F259) compose with R54's config-discovery-tiers answer and R58's pipeline initialization order — is the file sink initialized in a second pass after the config is fully resolved, or can it be wired in the same pass as the console sink?
- MEDIUM: What is the idiomatic Rust shape for "the root logger level is the minimum of the console and file sink levels" (F261, the dual-sink floor) in whatever subscriber model R58 adopts — is this automatic (each layer independently filters, so no floor computation is needed) or does it require an explicit combined-level computation at the dispatcher?
- LOW: Does py's default rotation policy (10 MiB per file, 5 backups) have an idiomatic Rust-crate default that differs meaningfully, and should this item's recommendation match py's numbers or a crate's own sane default?

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
