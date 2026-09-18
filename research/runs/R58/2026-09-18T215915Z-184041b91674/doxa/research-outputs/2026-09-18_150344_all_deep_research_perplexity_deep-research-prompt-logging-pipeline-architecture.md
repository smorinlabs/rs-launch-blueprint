---
prompt: # Deep-research prompt — Logging pipeline architecture (R58, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference architecture for structured, useful diagnostics that protect secrets, support the intended log-level controls, respect a library host's logging ownership, and integrate with the shared OpenTelemetry web example. Derive the required behaviors and agreement level from the owner direction, source evidence and industry practice, then compare native Rust designs. Item kind: `bundle`. Value test: if this answer is wrong, logging initialization, formatting, redaction, configuration, telemetry correlation and CLI/web integration all change.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py builds a full structured logging pipeline — a processor chain that auto-selects JSON vs. human console output from TTY-ness, redacts sensitive keys, optionally correlates OpenTelemetry trace/span IDs, exposes an explicit `--log-level` flag/env ahead of the `-v`/`-q` ladder, and only tears down handlers it itself owns on reconfiguration (idempotent, host-safe). ts's logger is a hand-rolled leveled-line writer with none of these: always plain text, no redaction, no tracing, no explicit level override, a fresh closure per call with no global state to protect. Evidence: F250 py `src/py_launch_blueprint/core/logging.py:120` — `def _resolve_format(fmt: LogFormat) -> LogFormat:` (`sys.stderr.isatty()`); ts's `createLogger` (`src/lib/logger.ts:58`) always writes plain leveled text, no JSON mode. F251 py `src/py_launch_blueprint/core/logging.py:154` — `def _shared_processors() -> list[Processor]:` (structlog processor chain); ts `src/lib/logger.ts:47` — hand-rolled leveled line writer, no structured-event/key-value model. F252 py `src/py_launch_blueprint/core/logging.py:93` — `SENSITIVE_KEY_PARTS: tuple[str, ...] = ("token", "password", ...)` applied by `_redact_sensitive` (`logging.py:143`); ts: no redaction step exists. F253 py `src/py_launch_blueprint/core/logging.py:106` — `_otel_trace: Any = importlib.import_module("opentelemetry.trace")` (soft-imported, optional extra); ts: no tracing integration. F254 py `src/py_launch_blueprint/cli/options.py:85` — `"--log-level", ... envvar="PLBP_LOG_LEVEL",`; ts has no way to set an exact level directly, only relative `-v`/`-q`/`--debug` flags. F262 py `src/py_launch_blueprint/core/logging.py:226` — `for handler in root.handlers[:]: if getattr(handler, _OWNED_FLAG, False): ...`; ts's `createLogger` returns a fresh closure per call with no global registry to protect. F263 py `src/py_launch_blueprint/web/logging.py:20` — web profile docstring: "Same engine as the CLI (`core/logging.py`), different policy"; ts has only the CLI front-end, no second profile to compare. F274 py `src/py_launch_blueprint/cli/context.py:197` — `def _resolve_console_level(` (a two-upstream-override ladder: `--log-level` flag/env, then config-file default, ahead of `-q`/`-v`); ts `src/lib/logger.ts:29` — `export function resolveLevel(flags: VerbosityFlags): LogLevel {` consults only the `-v`/`-q`/`--debug` flags, with no flag/env or config-file override tier. Ledger rows F250, F251, F252, F253, F254, F262, F263 (`docs/port/COMMONALITY.md`, area `config-env-logging`) and F274 (`docs/port/COMMONALITY.md`, area `cli-framework-ux`, cited from both areas' angles per its Notes), all verdict `DIVERGENT`, item R58.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): py's choice of a logging *library* to drive this pipeline, versus ts's choice of no library at all (D-018(1)), is presumption-of-reuse context, not a separate research item — this item's decision already subsumes "does `rs-launch-blueprint` use a logging crate," since a JSON/human-format-switching, redacting, optionally-OTel-correlating pipeline (F250-F253) is exactly what a logging crate provides. The relative verbosity-flag-to-level counting mechanics (`-q`/`-v` counting itself) belong to `cli-framework-ux`'s own verbosity items, not this one — this item owns only the resolution ladder's precedence order (F274) and the console pipeline's other properties (F250-F254, F262, F263). `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-018(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts deliberately chose "no logging library; hand-rolled leveled stderr logger... with injected stdout/stderr writers via the CLI deps interface," reusing the org's existing precedent rather than adopting a structured-logging crate; D-018(3) — ts's verbosity mapping adapts cli-standards' repeatable `-v` ladder (`-q` errors+warns only; default info; repeatable `-v`; `--debug` overrides `--quiet`; `--quiet` beats `--verbose`) but has no flag/env/config-file override tier ahead of it, unlike py's F274.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Look at the best practices and principles from the Python logging and see what applies to best architectural practices for both TypeScript and Rust. There should be a specific research item here.

### Baseline review (2026-09-04)
- F304 (tracing dependencies as a separate optional extra) was reclassified `DIVERGENT` under this item, because `logging-pipeline-contract` includes the optional OTel feature boundary: set that boundary inside the `web` surface R69 defines, with R78 defining the integration, and keep the working OTel web example an owner requirement, never an optional outcome (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Whether a rotating file log sink exists, its rotation policy, and its own independent level; R59 (`file-log-sink`) owns F255-F261 — this item designs the console/structured pipeline itself, not the file sink attached to it.
- The separate XDG data/state/cache directory set a file sink's default path might need; R57 (`xdg-directory-set`) owns F249.
- Whether `rs-launch-blueprint` ships an optional web surface at all (the `web-extra-surface` parameter); R69 (`web-framework-stack`) owns that decision — this item's per-front-end-profile design (F263) must work whether or not a web surface exists, and must not assume one.
- The repeatable `-v`/`--verbose` flag's existence and repeat-counting mechanics themselves (as opposed to this item's F274 resolution-ladder precedence); F273, `COMMON → REUSE`, is already inherited (both repos count repeated `-v` occurrences the same way) — it is not a research item, so there is nothing to defer to on that point. The CLI-parsing framework/library that provides those flags (`clap` or equivalent) is R60's (`cli-parsing-framework`) decision (F264) — this item's pipeline design must not assume a specific framework.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R58
- owns: logging-pipeline-contract
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R59 (`file-log-sink`) builds its file sink on top of whatever pipeline this item recommends; treat R59 as downstream of this item. R57 (`xdg-directory-set`) may supply a state-directory default this item's pipeline does not itself need but R59 will.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust logging architecture and crate stack preserve the shared diagnostic principles, which CLI/web policies should agree, and which implementation details should differ from the source logging pipelines?
- HIGH: Compare the significant Rust logging and instrumentation architectures found in the landscape, including event/span-based instrumentation and conventional log records with native formatting layers. Which best preserves the required structured diagnostics, secret handling, library-host ownership and OpenTelemetry integration? Treat `tracing`, `tracing-subscriber`, `log` and `env_logger` as leads to verify, and explain the native composition pattern rather than assuming a structlog-style processor chain.
- HIGH: What crate or pattern performs key-based secret redaction (F252) on structured log fields in the chosen pipeline — a custom subscriber layer, a field-visitor implementation, or is this simple enough to hand-roll regardless of crate choice?
- MEDIUM: Does the chosen crate have first-class, currently-maintained OpenTelemetry trace/span correlation support (matching py's soft-imported optional extra, F253), and can it be gated behind an optional Cargo feature the way py gates it behind an optional dependency extra?
- MEDIUM: What does "idempotent, only tears down handlers it owns" (F262) mean in the chosen crate's global-subscriber model, where the global default can typically only be set once per process — does the pipeline need a reload-capable layer to support reconfiguration at all, and if so is that different enough from py's model to note as a migration risk?
- LOW: If R69 concludes the template ships a web surface, does the chosen crate/pattern support "one pipeline, two profiles" (F263) as two layer configurations sharing one dispatcher, or as two independently initialized subscribers — and does this item's answer hold either way R69 lands?

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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
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
mode: all_deep_research
provider: perplexity
model: sonar-deep-research
operation_id: research-20260918-150344-b74724d646f64958
created_at: 2026-09-18T15:03:44.935064
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Logging pipeline architecture (R58, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference architecture for structured, useful diagnostics that protect secrets, support the intended log-level controls, respect a library host's logging ownership, and integrate with the shared OpenTelemetry web example. Derive the required behaviors and agreement level from the owner direction, source evidence and industry practice, then compare native Rust designs. Item kind: `bundle`. Value test: if this answer is wrong, logging initialization, formatting, redaction, configuration, telemetry correlation and CLI/web integration all change.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py builds a full structured logging pipeline — a processor chain that auto-selects JSON vs. human console output from TTY-ness, redacts sensitive keys, optionally correlates OpenTelemetry trace/span IDs, exposes an explicit `--log-level` flag/env ahead of the `-v`/`-q` ladder, and only tears down handlers it itself owns on reconfiguration (idempotent, host-safe). ts's logger is a hand-rolled leveled-line writer with none of these: always plain text, no redaction, no tracing, no explicit level override, a fresh closure per call with no global state to protect. Evidence: F250 py `src/py_launch_blueprint/core/logging.py:120` — `def _resolve_format(fmt: LogFormat) -> LogFormat:` (`sys.stderr.isatty()`); ts's `createLogger` (`src/lib/logger.ts:58`) always writes plain leveled text, no JSON mode. F251 py `src/py_launch_blueprint/core/logging.py:154` — `def _shared_processors() -> list[Processor]:` (structlog processor chain); ts `src/lib/logger.ts:47` — hand-rolled leveled line writer, no structured-event/key-value model. F252 py `src/py_launch_blueprint/core/logging.py:93` — `SENSITIVE_KEY_PARTS: tuple[str, ...] = ("token", "password", ...)` applied by `_redact_sensitive` (`logging.py:143`); ts: no redaction step exists. F253 py `src/py_launch_blueprint/core/logging.py:106` — `_otel_trace: Any = importlib.import_module("opentelemetry.trace")` (soft-imported, optional extra); ts: no tracing integration. F254 py `src/py_launch_blueprint/cli/options.py:85` — `"--log-level", ... envvar="PLBP_LOG_LEVEL",`; ts has no way to set an exact level directly, only relative `-v`/`-q`/`--debug` flags. F262 py `src/py_launch_blueprint/core/logging.py:226` — `for handler in root.handlers[:]: if getattr(handler, _OWNED_FLAG, False): ...`; ts's `createLogger` returns a fresh closure per call with no global registry to protect. F263 py `src/py_launch_blueprint/web/logging.py:20` — web profile docstring: "Same engine as the CLI (`core/logging.py`), different policy"; ts has only the CLI front-end, no second profile to compare. F274 py `src/py_launch_blueprint/cli/context.py:197` — `def _resolve_console_level(` (a two-upstream-override ladder: `--log-level` flag/env, then config-file default, ahead of `-q`/`-v`); ts `src/lib/logger.ts:29` — `export function resolveLevel(flags: VerbosityFlags): LogLevel {` consults only the `-v`/`-q`/`--debug` flags, with no flag/env or config-file override tier. Ledger rows F250, F251, F252, F253, F254, F262, F263 (`docs/port/COMMONALITY.md`, area `config-env-logging`) and F274 (`docs/port/COMMONALITY.md`, area `cli-framework-ux`, cited from both areas' angles per its Notes), all verdict `DIVERGENT`, item R58.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): py's choice of a logging *library* to drive this pipeline, versus ts's choice of no library at all (D-018(1)), is presumption-of-reuse context, not a separate research item — this item's decision already subsumes "does `rs-launch-blueprint` use a logging crate," since a JSON/human-format-switching, redacting, optionally-OTel-correlating pipeline (F250-F253) is exactly what a logging crate provides. The relative verbosity-flag-to-level counting mechanics (`-q`/`-v` counting itself) belong to `cli-framework-ux`'s own verbosity items, not this one — this item owns only the resolution ladder's precedence order (F274) and the console pipeline's other properties (F250-F254, F262, F263). `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-018(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts deliberately chose "no logging library; hand-rolled leveled stderr logger... with injected stdout/stderr writers via the CLI deps interface," reusing the org's existing precedent rather than adopting a structured-logging crate; D-018(3) — ts's verbosity mapping adapts cli-standards' repeatable `-v` ladder (`-q` errors+warns only; default info; repeatable `-v`; `--debug` overrides `--quiet`; `--quiet` beats `--verbose`) but has no flag/env/config-file override tier ahead of it, unlike py's F274.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Look at the best practices and principles from the Python logging and see what applies to best architectural practices for both TypeScript and Rust. There should be a specific research item here.

### Baseline review (2026-09-04)
- F304 (tracing dependencies as a separate optional extra) was reclassified `DIVERGENT` under this item, because `logging-pipeline-contract` includes the optional OTel feature boundary: set that boundary inside the `web` surface R69 defines, with R78 defining the integration, and keep the working OTel web example an owner requirement, never an optional outcome (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Whether a rotating file log sink exists, its rotation policy, and its own independent level; R59 (`file-log-sink`) owns F255-F261 — this item designs the console/structured pipeline itself, not the file sink attached to it.
- The separate XDG data/state/cache directory set a file sink's default path might need; R57 (`xdg-directory-set`) owns F249.
- Whether `rs-launch-blueprint` ships an optional web surface at all (the `web-extra-surface` parameter); R69 (`web-framework-stack`) owns that decision — this item's per-front-end-profile design (F263) must work whether or not a web surface exists, and must not assume one.
- The repeatable `-v`/`--verbose` flag's existence and repeat-counting mechanics themselves (as opposed to this item's F274 resolution-ladder precedence); F273, `COMMON → REUSE`, is already inherited (both repos count repeated `-v` occurrences the same way) — it is not a research item, so there is nothing to defer to on that point. The CLI-parsing framework/library that provides those flags (`clap` or equivalent) is R60's (`cli-parsing-framework`) decision (F264) — this item's pipeline design must not assume a specific framework.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R58
- owns: logging-pipeline-contract
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R59 (`file-log-sink`) builds its file sink on top of whatever pipeline this item recommends; treat R59 as downstream of this item. R57 (`xdg-directory-set`) may supply a state-directory default this item's pipeline does not itself need but R59 will.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust logging architecture and crate stack preserve the shared diagnostic principles, which CLI/web policies should agree, and which implementation details should differ from the source logging pipelines?
- HIGH: Compare the significant Rust logging and instrumentation architectures found in the landscape, including event/span-based instrumentation and conventional log records with native formatting layers. Which best preserves the required structured diagnostics, secret handling, library-host ownership and OpenTelemetry integration? Treat `tracing`, `tracing-subscriber`, `log` and `env_logger` as leads to verify, and explain the native composition pattern rather than assuming a structlog-style processor chain.
- HIGH: What crate or pattern performs key-based secret redaction (F252) on structured log fields in the chosen pipeline — a custom subscriber layer, a field-visitor implementation, or is this simple enough to hand-roll regardless of crate choice?
- MEDIUM: Does the chosen crate have first-class, currently-maintained OpenTelemetry trace/span correlation support (matching py's soft-imported optional extra, F253), and can it be gated behind an optional Cargo feature the way py gates it behind an optional dependency extra?
- MEDIUM: What does "idempotent, only tears down handlers it owns" (F262) mean in the chosen crate's global-subscriber model, where the global default can typically only be set once per process — does the pipeline need a reload-capable layer to support reconfiguration at all, and if so is that different enough from py's model to note as a migration risk?
- LOW: If R69 concludes the template ships a web surface, does the chosen crate/pattern support "one pipeline, two profiles" (F263) as two layer configurations sharing one dispatcher, or as two independently initialized subscribers — and does this item's answer hold either way R69 lands?

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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
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
```

# Logging Pipeline Architecture for `rs-launch-blueprint`: A Structured Diagnostics Stack for CLI, Library, and Web Service

The logging pipeline for `rs-launch-blueprint` must reconcile Python’s structured, redacting, optionally OpenTelemetry‑correlated logging engine with Rust’s idioms, while respecting that the Rust template is both a CLI, a reusable library, and (optionally) a web service host. It must deliver structured diagnostics, protect secrets, give the CLI and web layers coherent level and format controls, and avoid seizing global logging ownership away from host applications that embed the library. The landscape and current practice in Rust point to a split between simple, flat log records using the `log` facade and richer, span‑based instrumentation using the `tracing` ecosystem, with `tracing` + `tracing-subscriber` now the dominant choice for services and async code and `log` remaining the conventional facade for libraries.[6][7][30] A careful comparison of architectures, crates, and production examples supports a hybrid design: library crates instrument via `log`, application crates—CLI and web—instrument via `tracing`, and a single `tracing-subscriber` registry composes layers for formatting, redaction, level filtering, and optional OpenTelemetry export, capturing `log` records via `tracing-log` when the host opts in.[43][47][48] Secret redaction is handled by a custom filtering layer plus the `redactable` crate for structured data, while optional OpenTelemetry integration reuses the established `tracing-opentelemetry` bridge and compatible OpenTelemetry SDK crates.[2][20][44] Dynamic configuration is limited to filter and format reloading using `tracing-subscriber`’s `reload` module rather than handler teardown, a divergence from Python’s handler model that is noted explicitly as a migration difference.[22][25] The resulting stack preserves the shared principles of structured, secret‑safe diagnostics and host‑respecting logging ownership, while fitting Rust’s global‑subscriber architecture and the current ecosystem standard for observability.

## Background

`rs-launch-blueprint` is a Rust template shaped as three cooperating surfaces: a CLI front‑end, a reusable library crate, and an optional web service surface decided by R69.[Context] In the Python origin, logging is treated as a first‑class architectural concern: the template ships a fully structured pipeline built on structlog, with human‑versus‑JSON format auto‑selection based on TTY detection, key‑based secret redaction, optional OpenTelemetry trace/span correlation, and a clear precedence ladder between explicit `--log-level`/environment overrides and `-v`/`-q` style verbosity.[Context] This pipeline is idempotent and host‑safe: it only tears down logging handlers it created itself, leaving externally installed handlers intact on reconfiguration.[Context] The TypeScript port deliberately diverged: D‑018(1) and D‑018(3) record a choice of “no logging library” and a hand‑rolled leveled stderr logger, with no structured format, no redaction, no tracing integration, and no separate `--log-level` override tier.[Context] These divergences are recorded in the ledger as F250–F254, F262–F263 and F274, all marked `DIVERGENT` under R58’s `logging-pipeline-contract`, and the owner has asked for an explicit research item to reconcile them for Rust.[Context]

Rust’s ecosystem does not ship a built‑in structured logging framework in the standard library; instead, it offers a widely adopted `log` facade crate and a separate `tracing` ecosystem for span‑based, structured diagnostics.[30][48][43] The `log` crate is maintained by the Rust core team and provides a single logging API that abstracts over backends; executables pair it with implementations like `env_logger`, `flexi_logger`, `fern` or `log4rs` to actually emit log records, and library crates are expected to depend only on `log`, not on specific logging implementations.[30][6][29] The `tracing` ecosystem, maintained by the Tokio project, expands upon logging by introducing spans—hierarchical execution contexts capturing temporality and causality—and events; it is designed to collect structured, async‑aware diagnostics and has become the de facto standard for instrumentation in Rust services.[43][47][41][7] `tracing-subscriber` provides composable subscribers and layers for formatting, filtering, and export, including JSON output and OpenTelemetry integration via `tracing-opentelemetry`.[3][20][42]

The research mandate for R58 is explicit: identify the shared engineering principle and the agreement level (capability, standard, architectural pattern or policy), then survey architectures and libraries that best realize them in Rust, using evidence from maintained documentation, RustSec advisories, crate adoption, and production practice.[39] Architectures and ledger classifications are evidence, not predetermined winners; agreement, familiarity, or performance benchmarks alone cannot select a design.[Context] The mandate also requires treating the optional OpenTelemetry feature boundary as part of the logging‑pipeline contract: tracing dependencies are an optional extra controlled inside the web surface R69 defines, with R78 owning the concrete integration, but the existence of a working OpenTelemetry web example is an owner requirement, not an optional outcome.[Context] Within this frame, the choice of a logging library is presumptive context: given that py’s pipeline is exactly what a logging crate provides, the Rust template is expected to use crates rather than hand‑rolled logging, and this item’s decision subsumes “does `rs-launch-blueprint` use a logging crate.”[Context]

## Report

### Landscape

The category this item decides is “logging and diagnostics architecture for a Rust template that is simultaneously a CLI, a reusable library, and a web service,” with specific emphasis on structured logging, secret handling, OpenTelemetry correlation, level controls, and host‑safe ownership. In Rust, this landscape naturally divides into three bins: built‑in or first‑party toolchain facilities; established industry‑standard crates; and up‑and‑coming libraries and patterns that could contribute to secret‑safe structured diagnostics.

In the built‑in or first‑party bin, there is the standard library’s basic `println!`/`eprintln!` output and ad‑hoc error reporting, which lack structure, levels, and shared configuration, and thus cannot meet R58’s requirements on their own.[30] More relevant is the `log` crate, maintained under the `rust-lang/log` repository, which provides a lightweight logging facade designed to be used by libraries to log information without committing to a specific backend.[30][48] `log` defines macros for standard levels (`error!`, `warn!`, `info!`, `debug!`, `trace!`), supports optional structured key‑value data via a `kv` feature, and is widely embedded across the ecosystem.[30] The crate’s documentation emphasizes that executables must choose and initialize a backend, while libraries should depend only on `log`, respecting the host’s logging ownership.[30][37] This aligns closely with the “library‑host logging ownership” principle in the prompt.

The established industry standard bin is dominated by the `tracing` ecosystem and its associated crates.[43][47][41][11] The `tracing` crate provides the primary instrumentation API, allowing libraries and applications to emit structured events and spans with fields representing context.[43][47][11][12] It is maintained by the Tokio project and designed to be async‑aware, capturing temporality and causality in a way that traditional flat log records cannot.[43][41] `tracing-core` offers stable primitives for subscriber authors, and `tracing-subscriber` provides composable subscribers and layers for formatting, filtering, and exporting trace data.[3][16][16][47] `tracing-subscriber`’s `fmt` module implements formatters for human‑readable, compact, pretty, and JSON output, and its `filter` module supplies `EnvFilter` and other filtering strategies for controlling which spans and events are enabled.[21][26][28] The `tracing-opentelemetry` crate connects `tracing` spans to OpenTelemetry‑compatible distributed tracing systems, emitting spans to collectors like the OpenTelemetry Collector, Jaeger, or vendor backends via OTLP.[2][4][20][42] Together, these crates form a coherent ecosystem for structured diagnostics and observability in Rust services.

Also in the established bin are logging backends for `log`: `env_logger` (a simple, environment‑driven logger), `flexi_logger` (a flexible logger with runtime configuration and file output), `fern` (a configurable runtime logger with multiple outputs), and `log4rs` (a strongly configurable framework modeled after Logback and log4j).[1][6][5][8][10][23][24][27] `env_logger` is maintained by the Rust CLI Working Group and provides a minimal configuration logger that can be initialized with a single `env_logger::init()` call and configured via the `RUST_LOG` environment variable.[1][6][29][37] `flexi_logger` plugs into the `log` facade, supports writing logs to stderr and/or files, runtime filter changes, and various features like async logging and compressed log files.[8][46] `fern` acts as a backend to `log`, supporting multiple loggers, configurable output formats via closures, and multiple outputs per logger, including files and stdout/stderr.[10][5] `log4rs` offers appenders, encoders, filters, and loggers, with YAML‑based configuration and support for features like file rotation and compression.[23][24][27] These backends are well suited to CLI tools and synchronous applications that do not need spans or OpenTelemetry.

In the up‑and‑comer bin are specialized crates that address needs like redaction and simplified OpenTelemetry setup. The `redactable` crate is a redaction library for Rust that lets developers mark sensitive data in structs and enums and produce safe, redacted versions for logging and telemetry. It offers derive macros `Sensitive` and `SensitiveDisplay` for structured and string‑formatted redacted values, respectively, and integrates with both slog and tracing via marker traits and `valuable`. The crate provides `SlogRedacted` and `TracingRedacted` marker traits to enforce that only certified types pass through logging pipelines, helping ensure sensitive data is not exposed. This is directly relevant to F252’s requirement for key‑based secret redaction. Another up‑and‑comer is `tracing-opentelemetry-extra`, which wraps `tracing-opentelemetry` with easy OpenTelemetry initialization, OTLP exporter configuration, sampling settings, resource attributes, and support for tracing, metrics, and logs.[17][17][17] It is organized around the official `tracing-opentelemetry` OTLP example and aims to simplify observability setup.[17][17] The standalone `env_filter` crate offers the same filter parsing and matching as `tracing-subscriber::filter::EnvFilter`, allowing custom loggers to reuse the same directive syntax and behavior.[19][19][19] These crates demonstrate an emerging trend toward explicit redaction and easier observability integration.

Authority for this landscape comes primarily from crate documentation and maintainer repositories, which describe APIs, intended use, and minimum Rust versions, and from the Rust Secure Code Working Group via RustSec advisories. The `log` crate’s docs describe it as a lightweight facade and list numerous compatible logger implementations, alongside guidance that libraries should link only to `log` and executables must choose a backend.[30][48] The `tracing` ecosystem’s GitHub pages and documentation explain tracing’s role as a framework for structured, event‑based diagnostics, the distinction between instrumentation and subscribers, and the role of `tracing-core`.[43][41][11][47] `tracing-subscriber`’s README details the `Subscriber` and `Layer` traits, composition patterns, and filter strategies, as well as minimum supported Rust compiler versions.[3][16][16] `tracing-opentelemetry`’s docs describe OpenTelemetry integration, the `OpenTelemetryLayer` and `OpenTelemetrySpanExt` types, and feature flags for metrics, while also noting version compatibility with OpenTelemetry crates.[4][20][20][42] OpenTelemetry’s Rust implementation documentation explains telemetry signals (logs, metrics, traces), OTLP export, and crate responsibilities (`opentelemetry`, `opentelemetry-sdk`, `opentelemetry-otlp`, `opentelemetry-stdout`).[44][49] RustSec advisories document malicious or vulnerable crates, such as `envlogger` (malicious typosquat), `tracings`, `tracing-ethers`, and `tracing-check`, reinforcing the need to avoid similarly named, non‑canonical crates.[34][15][15][35][36] These sources are authoritative: they are maintained by the crate authors and the Rust security working group, respectively.

Practice evidence comes from widely regarded Rust projects and frameworks. Tokio, the dominant async runtime for Rust, is instrumented with tracing, and the `tokio-console` project uses `tracing-subscriber` with `EnvFilter` and `fmt` layers to collect task diagnostics, demonstrating first‑class tracing integration in a core ecosystem component. Axum, a popular web framework, has community tooling like `axum-tracing-opentelemetry` that integrates axum, tracing, and OpenTelemetry via middlewares and subscriber extensions. Actix‑web, another major web framework, offers structured diagnostics via `tracing-actix-web`, which provides a `TracingLogger` middleware to collect telemetry data from HTTP requests, and blog posts and guides show production configurations using `tracing-subscriber` for JSON logs and `EnvFilter` for level control. The “Zero to Production in Rust” series uses `env_logger` initially and then transitions to `tracing` + `tracing-subscriber` and JSON log output for a web service, illustrating a migration path from simple logging to structured tracing. Shuttle’s “Logging in Rust” article compares `log`, `env_logger`, `fern`, `simplelog`, `log4rs`, `slog`, and `tracing`, concluding that `tracing` is best for production apps and microservices needing structured logging, while `log` is best for libraries.[6] A 2026 Rust logging comparison similarly recommends `tracing` for services and APIs, and `log` for libraries and simple tools, noting that `tracing` has become the production default for web services.[7]

Fit over abstract “best” requires judging candidates against the specific needs of `rs-launch-blueprint`: it is both a library and an application, with CLI and optional web surfaces, and it must preserve Python’s structured logging behaviors (format switching, redaction, optional OpenTelemetry correlation, explicit level overrides) while respecting Rust’s global subscriber model and host ownership expectations. Flat `log` + `env_logger` alone cannot provide spans or OpenTelemetry integration, and although `log4rs`, `fern`, or `flexi_logger` add configurability and file sinks, they still operate at the flat log‑record level.[5][8][10][27] The `tracing` ecosystem, on the other hand, can provide structured spans, event fields, JSON output, OpenTelemetry integration, and async‑aware context, making it well suited to the web service and CLI surfaces.[43][47][2][20] However, using `tracing` directly in library crates would violate the ecosystem convention that libraries defer logging backend choices to hosts; the `log` facade remains the appropriate instrumentation API for reusable libraries.[30][7] Therefore, an architecture that combines `log` for libraries with `tracing` + `tracing-subscriber` for applications, and uses `tracing-log` to bridge `log` records into the tracing pipeline, best fits both the shared principles and Rust’s practices.[43][47][48][7]

### Principles and implementation

The shared requirement for R58, drawn from the Python precedent and owner direction, is a logging pipeline that provides structured, useful diagnostics across CLI, library, and web service surfaces, protects secrets, supports explicit log‑level controls with a precedence ladder, preserves host ownership of logging for library usage, and optionally correlates logs with OpenTelemetry traces and spans.[Context] This requirement is at the level of architectural pattern and policy, not just capabilities: both the presence of structured logging and the policy of secret redaction and host‑respecting ownership are part of the contract. Observable acceptance criteria include: logs can be emitted in both human‑friendly console format and machine‑readable JSON; the pipeline can automatically select format based on TTY detection or explicit profile; sensitive fields are redacted based on key patterns or annotations; explicit `--log-level`/environment overrides precede verbosity ladders; library crates do not unilaterally initialize global loggers or subscribers; OpenTelemetry integration is optional, gated behind features, but is present and demonstrably working in the web example; and logging configuration changes do not tear down logging handlers owned by other host code.

Python’s pipeline uses structlog processors to implement these behaviors, including `_resolve_format` based on `sys.stderr.isatty()`, `_shared_processors` with key/value structlog processors, `_redact_sensitive` based on key parts like `"token"` or `"password"`, optional OpenTelemetry correlation via soft import of `opentelemetry.trace`, and a resolution ladder that prefers `--log-level` and `PLBP_LOG_LEVEL` over `-v`/`-q` flags.[Context] It also uses an “owned handler” flag to ensure only its own handlers are removed on reconfiguration.[Context] Rust’s ecosystem offers analogous capabilities but via different abstractions: `tracing-subscriber` layers and filters instead of structlog processors, and a global subscriber model instead of handler lists.[3][16][16] The question is which architecture best preserves the principles.

The key principles can be summarized as follows. First, **structured diagnostics**: logs should carry structured fields (key/value pairs) and, in the case of spans, hierarchical context, so that downstream tools can filter and correlate events. `tracing` is explicitly designed to collect structured, scoped, async‑aware diagnostics, with spans that have begin and end times and may be nested, and events that carry fields and metadata.[43][47][11][12] `tracing-subscriber`’s `fmt::Layer` and formatters support JSON output, which is the natural representation for structured logs in production. Second, **secret handling**: sensitive data must be redacted before leaving the process, and redaction should be based on either key patterns or annotations, covering both simple fields and structured types. Third, **library host ownership**: library crates must not dictate logging backends or global subscribers; they should instrument via facades (`log` or optionally `tracing` with a compatibility layer) and let hosts decide how to collect and format logs.[30][43][47] Fourth, **OpenTelemetry integration**: logs and traces must be correlatable via trace IDs and span IDs when the optional feature is enabled, using a standardized exporter like OTLP to send data to a collector.[2][9][20][44][49] Fifth, **idempotent configuration and handler ownership**: the pipeline should configure only components it owns and avoid disrupting external logging configuration, even though Rust’s global subscriber model limits this to initial setup and dynamic filter reload rather than handler teardown.[22][25][29] Sixth, **CLI/web policy coherence**: the CLI and web surfaces should share the same logging engine and differ only in profile policy—for example, a default pretty console format with optional JSON for CLI, and a default JSON format for web—with shared level resolution and redaction behavior.[1][6]

Comparing architectural alternatives, we can consider three broad designs. One is a **pure `log` + backend** design: the library and CLI/web surfaces all use the `log` facade and configure a backend like `env_logger`, `flexi_logger`, `fern`, or `log4rs` to emit logs.[30][1][6][8][10][27] This design fits library host ownership well, as `log` is the conventional facade, but it struggles with structured diagnostics beyond flat records and lacks first‑class span context and OpenTelemetry integration.[7][4][20] JSON output is possible via backends like `fern` or with custom formatting, but correlating logs with traces requires additional tooling, and structured spans are not part of the model. A second design is a **pure `tracing` application** model: all code, including libraries, instrument via `tracing`, and the template expects hosts to use `tracing-subscriber` for subscribers.[43][47][41] This design offers the richest structured diagnostics and seamless OpenTelemetry integration via `tracing-opentelemetry`, but diverges from ecosystem convention that libraries depend on `log` and may make adoption harder for hosts that are not yet on `tracing`.[7][30] A third design is a **hybrid `log` + `tracing` model**: library crates instrument via `log`, application crates instrument via `tracing`, and `tracing-log` is used to route `log` records into the tracing pipeline, allowing a single `tracing-subscriber` registry to handle formatting, redaction, filtering, and OpenTelemetry export.[43][47][48][13]

Industry guidance and production practice favor the hybrid model for templates like `rs-launch-blueprint`. Shuttle’s logging comparison notes that `log` is best for libraries and `tracing` is best for applications and services, and emphasizes that `tracing` has integrations like `tracing-subscriber` and OpenTelemetry that make it ideal for production observability.[6] The Rust logging comparison article from 2026 explicitly recommends `tracing` for web services, APIs, and async apps, and `log` for libraries and simple tooling, and notes that `tracing` is backward compatible with `log` and can capture `log` records.[7] The `tracing` repository itself provides `tracing-log` to bridge `log` records into the tracing ecosystem, reinforcing this pattern.[13][43] Web frameworks like Actix‑web and Axum use tracing‑based middleware (`tracing-actix-web`, `axum-tracing-opentelemetry`) to integrate HTTP request context with tracing and OpenTelemetry, while libraries that these frameworks depend on continue to use `log`. This suggests that the best fit for `rs-launch-blueprint` is to adopt the hybrid pattern: `log` for the core library, `tracing` for CLI and web surfaces, and a tracing‑centric pipeline for diagnostics.

Within the hybrid pattern, the implementation must realize Python’s behaviors using the `tracing-subscriber` architecture. Format switching can be implemented by constructing two `fmt::Layer`s, one configured for pretty human output (e.g., `format::Pretty` or `format::Full`) and one for JSON output, and selecting between them based on whether stderr is a TTY or based on profile; `tracing-subscriber` allows multiple layers to be composed in a registry, and layers can be configured for different destinations (stderr, stdout, files). Redaction can be implemented via a custom `Layer` that inspects event and span fields and replaces values for keys that match sensitive patterns, or via the `redactable` crate for structured data, combined with `valuable` integration for tracing; `redactable`’s `Sensitive` and `SensitiveDisplay` derive macros and `TracingRedacted` markers provide a robust path for typed redaction. Level resolution can reuse the `EnvFilter` syntax, which is similar to `env_logger`’s `RUST_LOG` directives but extended for span and field matching; `EnvFilter::from_env` or `try_from_default_env` can parse the environment, and a builder can set default directives.[21][28] The precedence ladder—explicit `--log-level` or environment override ahead of verbosity flags—can be implemented in the CLI parsing layer, which then sets `RUST_LOG` or constructs an `EnvFilter` string passed to the subscriber builder; R58 owns only the resolution order, not the CLI framework, so this can be expressed as a contract between CLI options and filter setup.[Context][6]

Handler ownership and idempotent configuration are where Rust’s model diverges from Python’s. In Python, logging handlers are objects attached to logger hierarchies, and the template can mark its own handlers and only remove those.[Context] In Rust’s `log` facade, the global logger is set once via `log::set_logger` or `log::set_max_level`, and subsequent attempts to set a logger fail; similarly, `tracing-subscriber`’s `init()` sets a global default subscriber and cannot be called twice.[30][29][3][16] Dynamic reconfiguration is supported via the `reload` module in `tracing-subscriber`, which allows a layer or filter to be wrapped in a `reload::Layer` and modified at runtime via a `Handle`, but it does not change the global subscriber itself.[22][25] Therefore, “idempotent, only tears down handlers it owns” must be reinterpreted for Rust as “the template provides functions to build subscribers and layers but does not call `init()` unless it is the process owner, and dynamic reconfiguration is expressed via reload handles that modify only layers built by the template.” This is a migration difference worth noting explicitly.

This leads to a **BASELINE-REVIEW** finding: 

> **BASELINE-REVIEW: F262 — handler ownership — proposed change — evidence.** In Python, F262 defines handler ownership via a flag on handler objects and allows removing only owned handlers on reconfiguration. In Rust, the global logger/subscriber model makes handler teardown impractical and potentially unsafe. The proposed change is to define ownership at the subscriber/layer level: `rs-launch-blueprint` will provide a builder that constructs a `tracing-subscriber` registry with owned layers and optionally sets it as the global subscriber when acting as an application, but library crates will never call `init()`. Dynamic changes will use `reload::Layer` and `EnvFilter` modification to adjust behavior, and the template will document that it does not attempt to tear down global subscribers or loggers. This change is supported by `tracing-subscriber` documentation on `reload::Layer` and `EnvFilter`, and by the `log` crate’s global logger semantics.[22][25][21][30][29]

Similarly, the structured pipeline itself must be reviewed:

> **BASELINE-REVIEW: F250–F254, F263, F274 — logging pipeline principle — proposed change — evidence.** Python’s logging pipeline uses structlog processors for format switching, structred events, redaction, and optional OpenTelemetry correlation, with CLI and web profiles differing only in policy. The proposed Rust pipeline replaces structlog processors with `tracing-subscriber` layers: a `fmt::Layer` configured for pretty or JSON output, an `EnvFilter` for level resolution, a custom redaction layer and/or `redactable` for secret handling, and an optional `OpenTelemetryLayer` for tracing export. CLI and web profiles are implemented as different layer configurations sharing the same registry builder; both surfaces share redaction and level resolution behavior, but defaults differ (CLI default pretty, web default JSON). The precedence ladder for `--log-level`/environment over `-v`/`-q` is implemented via `EnvFilter` directives. Evidence comes from `tracing-subscriber` documentation, Rust logging comparisons recommending `tracing` for services, and production examples from Actix‑web, Axum, and Tokio using tracing and OpenTelemetry.[3][7][21]

### Recommendation

The recommended logging architecture for `rs-launch-blueprint` is a **hybrid structured diagnostics stack** centered on the `tracing` ecosystem for application surfaces and the `log` facade for library instrumentation. The stack members and their roles are:

1. **`log`**: the logging facade used by the core library crate(s), emitting flat log records with levels and optional key‑value data, without committing to a backend.[30][48]
2. **`tracing`**: the instrumentation framework used by the CLI and web service crates, emitting spans and events with structured fields and async‑aware context.[43][47][41][11]
3. **`tracing-log`**: the bridge that routes `log` records into the tracing pipeline, allowing library logs to be collected as tracing events.[13][43]
4. **`tracing-subscriber`**: the subscriber and layer composition framework that collects tracing data, formats it for console or JSON output, filters it via `EnvFilter`, and provides dynamic reload via `reload::Layer`.[3][16][16][21][22][25]
5. **`redactable`**: the redaction library that provides typed redacted representations for structured data and integrates with tracing via `TracingRedacted` and `valuable`.
6. **`tracing-opentelemetry`**: the OpenTelemetry bridge that adds an `OpenTelemetryLayer` to the tracing subscriber, exporting spans to OpenTelemetry‑compatible collectors via OTLP, with optional metrics support.[2][4][20][42][49]
7. **OpenTelemetry SDK crates** (`opentelemetry`, `opentelemetry-sdk`, `opentelemetry-otlp`): the implementation of OpenTelemetry APIs, SDK, and OTLP exporter used by `tracing-opentelemetry`.[44][49][9]

In this architecture, the core library crate instruments log points using `log` macros (`info!`, `debug!`, etc.), ensuring that host applications—whether they use `env_logger`, `flexi_logger`, `tracing-subscriber`, or something else—can choose their logging backend.[30][6] The CLI and web service crates instrument their own code using `tracing` macros (`info!`, `warn!`, `instrument`, spans), providing rich context and structured fields.[43][47] When the template itself acts as the process owner (e.g., in the `rs-launch-blueprint` CLI binary), it constructs a `tracing-subscriber` registry with layers for formatting, redaction, and filtering, adds a `tracing-log` layer to capture `log` records, and optionally adds an `OpenTelemetryLayer` when the `otel` Cargo feature is enabled.[2][4][20][42] The CLI and web surfaces share the same registry builder, but they choose different defaults: CLI defaults to pretty human output with JSON available via a flag or environment; web defaults to JSON output for production observability.

Secret redaction is implemented in two ways. For primitive fields and ad‑hoc log messages, a custom `Layer` inspects event and span fields and replaces values for keys whose names contain sensitive parts (e.g., `"token"`, `"password"`, `"secret"`) with placeholder values like `"[REDACTED]"`; this mirrors Python’s `SENSITIVE_KEY_PARTS` approach. For structured data types, the `redactable` crate’s `Sensitive` and `SensitiveDisplay` derives are used to mark fields as sensitive and produce redacted versions; the tracing integration via `TracingRedacted` and `tracing_redacted_valuable()` ensures that only redacted versions are emitted into spans and events, with compile‑time enforcement via marker traits. This combination covers both string‑based logs and structured payloads, aligning with F252’s requirement.

OpenTelemetry integration is optional and gated behind a Cargo feature, e.g., `otel`, which pulls in `tracing-opentelemetry` and OpenTelemetry SDK crates only when enabled.[2][20][49][9] When the feature is active, the registry builder adds an `OpenTelemetryLayer` to the subscriber, and the web example uses an OTLP exporter configured via environment variables (e.g., `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`) to send spans to a collector like Jaeger.[4][9] When the feature is not enabled, the pipeline remains purely local. This mirrors Python’s soft import of `opentelemetry.trace` and optional extra, while leveraging Rust’s feature system.

Dynamic configuration uses `EnvFilter` and `reload::Layer`. The CLI parsing code resolves a desired log level based on explicit `--log-level` or environment override, followed by `-v`/`-q` counts, and constructs an `EnvFilter` string representing directives for modules and levels (e.g., `"info,my_crate=debug"`); `EnvFilter::new` or builder APIs parse this string, and the filter is wrapped in a `reload::Layer` to allow runtime adjustment.[21][28][22][25] For the web service, level changes may be driven by environment or management APIs, applied via the reload handle. The template avoids calling `tracing_subscriber::fmt().init()` directly in library code and exposes builder functions that hosts can use; this respects host logging ownership.

Under this recommendation, CLI and web policies agree on the logging engine (tracing), redaction behavior, and level resolution precedence, but differ on default formats and perhaps on which fields are recorded (web may record additional HTTP context via middleware). The file sink architecture (R59) builds on this pipeline by adding `tracing-appender` layers or separate `log4rs` configurations; it is explicitly downstream and not decided here.[27] The stack meets all fitness gates for Rust edition 2024, MSRV policy (`stable minus 2`), license compatibility (MIT/Apache), RustSec advisories (none for these canonical crates), OS support (Linux and macOS via CI badges and maintained documentation), async runtime neutrality (tracing does not require Tokio, though it integrates deeply with it), and binary size/compile‑time cost (qualitatively moderate, consistent with structured logging setups).[3][43][30][44][49][8][46]

### Members

#### tracing

##### Landscape

The `tracing` crate sits at the heart of the established industry‑standard bin for structured diagnostics in Rust.[43][47][41] It is described as a framework for instrumenting Rust programs to collect structured, event‑based diagnostic information, expanding on traditional logging by allowing recording of spans and events with additional information about temporality and causality.[43][47][11] The crate is maintained by the Tokio project, hosted at `tokio-rs/tracing` on GitHub, and is part of a broader repository that includes `tracing-core`, `tracing-attributes`, `tracing-log`, and several utility crates.[43][41][45][13] The documentation notes that `tracing` is maintained by the Tokio project but does not require the Tokio runtime; it can be used in any Rust application.[43][41] Crate metadata and the repository show regular releases and active development through at least 2026.[45][13]

Authoritative sources for `tracing` include its docs.rs README, the GitHub repository, and the GitHub Pages site explaining application‑level tracing for Rust.[11][11][43][41] The docs describe the crate’s purpose, its macros for events and spans, and its relationship to `tracing-core`.[11][11] The GitHub Pages site explains the distinction between instrumentation (`tracing`) and subscribers (`tracing-subscriber`), and the concept of spans as hierarchical execution contexts.[47][43] These sources are maintained by the crate authors and are therefore authoritative.

Practice evidence shows broad adoption of `tracing` in major Rust projects. Tokio itself is instrumented with tracing spans for tasks and IO operations, and the `tokio-console` tooling leverages tracing to observe async behavior. Web frameworks like Actix‑web and Axum use tracing middleware (`tracing-actix-web`, `axum-tracing-opentelemetry`) to capture structured diagnostics for HTTP requests. Observability examples such as OneUptime’s Actix production configuration, Rust NiceDX’s Tokio console guide, and Axum tracing instrumentation guides all rely on `tracing` as the core instrumentation API.[9] This places `tracing` firmly in the “established standard” category.

##### Principles and implementation

`tracing` implements the principle of structured diagnostics by introducing spans and events as first‑class constructs. A span represents a period of time in the program’s execution, with a beginning and end, and may be entered and exited as control flow changes.[47][43][11] Spans form a nested tree, allowing logs to be contextualized with parent spans and their fields.[47] Events represent discrete occurrences, such as log messages, and carry fields and metadata describing the event.[47][11] `tracing` macros like `info!`, `warn!`, `error!`, `debug!`, and `trace!` emit events, while `span!` and `#[instrument]` create and manage spans.[43][47]

The crate’s design separates instrumentation from data collection: `tracing` emits events and spans, while subscribers (implemented in `tracing-subscriber` or custom crates) decide how to record and format them.[43][47][3] This separation aligns with the principle that library code should instrument without committing to a specific backend, especially when `tracing` is used in reusable libraries. However, in `rs-launch-blueprint`, `tracing` is primarily used in application surfaces—CLI and web—where the template controls the subscriber.[43][47]

`tracing` supports structured fields via macros that allow key/value pairs, e.g., `info!(user_id = %user.id, "User logged in")`, and the fields are carried with spans and events.[47] This is crucial for redaction and OpenTelemetry correlation: fields like `trace_id`, `span_id`, `user_id`, or `http.route` can be emitted and later filtered or exported.[9] The crate integrates with `valuable` for structured data, enabling deeper inspection of types, which is used by `redactable` to provide safe paths for redacted structured logging.

##### Dominant choice

Within the category of span‑based instrumentation frameworks for Rust, `tracing` is the dominant choice. There are other structured logging frameworks, such as `slog`, which offers contextual, extensible logging, but `slog` focuses on log records rather than spans and is older, with guidance suggesting `tracing` for new projects.[6][50] The `tracing` ecosystem is deeply integrated with Tokio, Axum, Actix‑web, and OpenTelemetry, and has become the de facto standard for observability in Rust services.[7] Maintainer standing (Tokio project), widespread adoption, and ongoing development make it the dominant choice.

##### Qualified shortlist

The qualified shortlist for structured diagnostics frameworks includes `tracing` and `slog`. `slog` offers structured, contextual logging and an ecosystem of components, and it can be used with crates like `redactable` for redaction.[50] However, `slog` lacks built‑in span semantics, and its integration with OpenTelemetry is not as direct as `tracing`’s via `tracing-opentelemetry`.[4][20] Given the emphasis on spans and OpenTelemetry correlation in R58, `slog` is a secondary choice. `log` is not in this shortlist; it is a logging facade, not a structured diagnostics framework.[30][48]

##### Excluded by gate

No gate excludes `tracing`. License is MIT (compatible with `MIT OR Apache-2.0`).[43][11] Minimum supported Rust compiler version for the broader ecosystem is at least 1.65, as `tracing-subscriber` notes; `tracing` itself is built against the latest stable release.[3][16][11] There are no RustSec advisories for `tracing`; advisories exist only for malicious crates with similar names, like `tracings` and `tracing-ethers`, which reinforces the need to depend on the canonical `tracing` crate.[15][15][35] CI badges and documentation indicate support for Linux and macOS; Windows is also supported but not required by this item.[43][44][49] Binary size and compile‑time costs are moderate: `tracing` adds macros and data structures but is designed to be zero‑cost when disabled, with minimal overhead per span when enabled.[7][43]

##### Up-and-comers

Up‑and‑coming alternatives or complements to `tracing` include specialized wrappers and integrations, such as `axum-tracing-opentelemetry`, which provides middlewares for axum services, and `tracing-opentelemetry-extra`, which simplifies OpenTelemetry setup.[17][17] These build on `tracing` rather than replacing it. The `valuable` crate, used for structured data inspection, is also growing in importance, especially for redaction via `redactable`. None of these displace `tracing` as the core instrumentation crate; they enhance its usage.

##### Fit for this template

For `rs-launch-blueprint`, `tracing` fits as the primary instrumentation framework for the CLI and web service surfaces. It enables structured events and spans capturing CLI commands, configuration context, and HTTP request handling, and integrates seamlessly with `tracing-subscriber` for formatting and `tracing-opentelemetry` for OpenTelemetry export.[43][47][2][20] It does not require the Tokio runtime, making it suitable even if R69’s web framework choice is not Tokio‑based.[43] Its macros and `#[instrument]` attribute are ergonomic and align with Python’s use of decorators and structlog processors for contextual logging.[47] `tracing` is not used directly in library crates in this template to respect host logging ownership; instead, library crates use `log`, and `tracing-log` bridges them.[30][48][13]

##### Recommendation

`tracing` is recommended as the core instrumentation crate for `rs-launch-blueprint`’s CLI and web surfaces. All application code in these surfaces should emit spans and events via `tracing`, and only the application surfaces should initialize subscribers; library crates should avoid calling `tracing_subscriber::init()`.[43][3] Instrumentation should use `#[instrument]` on functions where context matters, and event macros with structured fields should be preferred over plain strings.[47]

##### Ranked runner-up

`slog` is the ranked runner‑up for structured logging frameworks. It could provide structured logging for CLI tools and synchronous applications, and its ecosystem supports JSON output and integration with `redactable`.[50] However, it lacks first‑class span semantics and has less direct integration with OpenTelemetry, making it a weaker fit for the web service and observability requirements.[4][20][49] For `rs-launch-blueprint`, `slog` is not recommended as the primary framework but could be considered in specialized contexts.

##### Tradeoffs

Using `tracing` introduces a dependency on the Tokio‑maintained ecosystem and a slightly more complex instrumentation model compared to flat `log` records.[43][7] Developers must understand spans and events and manage subscriber configuration. However, the tradeoffs are favorable: structured diagnostics, async awareness, OpenTelemetry integration, and ecosystem support outweigh the complexity, especially for web services and complex CLIs. Binary size and compile time increase modestly, but the cost is in line with the template’s observability goals.[7][43]

##### Parameters

`tracing` does not own any parameters in the template; it is a member of the logging stack. It assumes `rust-edition = 2024` and MSRV policy `stable minus 2`, which are compatible with its own minimum Rust version (built against latest stable).[3][11] It also assumes that R69 may choose a web framework that has tracing integrations (e.g., Actix‑web or Axum), but this is not required.

##### Migration implications

Migration from Python’s structlog to `tracing` involves replacing processor chains with span and event instrumentation. Where Python used structlog processors to add context and redaction, Rust uses `#[instrument]` and fields on spans and events.[47] For example, a Python function decorated with structlog context becomes a Rust function annotated with `#[instrument(skip(state), fields(user_id))]`, as shown in Actix‑web examples. The template’s logging module must define macros or helper functions that emit events with consistent fields, mirroring Python’s structured logs.

##### Validation strategy

Validation involves instrumenting a sample CLI command and web handler with `#[instrument]` and event macros, then observing the spans and events using a `tracing-subscriber` subscriber. For example, the web handler `get_user` in Actix‑web examples uses `#[instrument(skip(state), fields(user_id))]` and emits `info!` events; running the service and triggering the endpoint should produce structured logs with spans containing `user_id` and HTTP context. Planned checks include verifying span nesting, field propagation, and correct level filtering via `EnvFilter`.

##### Confidence & re-verify trigger

Confidence in `tracing` is high, given its maintainer backing, adoption in major projects, and continued development.[43][7] Re‑verification should be triggered by a major `tracing` release that changes subscriber APIs, a RustSec advisory against `tracing` or related crates, or a shift in ecosystem guidance (e.g., if a new framework supplants `tracing` for structured diagnostics).[39][45][44]

##### Sources

This analysis of `tracing` draws on its docs.rs README,[11][11] GitHub repository,[41][43] GitHub Pages site,[47] ecosystem documentation for `tracing-subscriber` and `tracing-opentelemetry`,[3][4][20][42] and production examples in Tokio, Actix‑web, Axum, and observability guides.

#### tracing-subscriber

##### Landscape

`tracing-subscriber` is the primary subscriber and layer composition crate for the `tracing` ecosystem.[3][16][16] It provides utilities for implementing and composing subscribers, with the `Subscriber` trait representing the functionality necessary to collect trace data and the `Layer` trait representing modular behaviors that can be composed into a subscriber.[3][16][16] The crate is maintained alongside `tracing` in the `tokio-rs/tracing` repository and is documented on docs.rs and GitHub.[3][16][16][43]

Authoritative documentation describes `tracing-subscriber` as intended for use by both subscriber authors and application authors using `tracing` to instrument their applications.[3][16][16] It notes that the minimum supported Rust compiler version is 1.65 and that the crate is built against the latest stable release.[3] The README explains the `Layer` trait, the `Filter` trait, and various built‑in subscribers and layers, including `fmt` for formatting and logging tracing data and `EnvFilter` for filtering spans and events.[3][21][26][28]

Practice evidence shows `tracing-subscriber` as the standard way to set up tracing subscribers in Rust applications. Tokio console examples use `tracing-subscriber`’s `fmt::Layer` and `EnvFilter` to configure console output and filtering based on environment variables. Actix‑web and Axum observability examples use `tracing-subscriber` for JSON output and filtering, and community guides explain how to compose layers for logging and OpenTelemetry export. Shuttle’s logging comparison notes that `tracing-subscriber` is used with `tracing` in most new Rust services.[6][7]

##### Principles and implementation

`tracing-subscriber` implements the principle of flexible, composable logging pipelines via the `Layer` abstraction.[3][16][16] A `Layer` defines a particular behavior for collecting trace data, such as formatting, filtering, or exporting, and can be composed with other layers to form a subscriber that records traces in various ways.[3][16][16] Unlike subscribers, which implement complete strategies for collecting trace data, layers provide modular implementations of specific behaviors.[3]

The `fmt` module provides a `FmtSubscriber` and `fmt::Layer` that format and record tracing events as line‑oriented logs. Formatters include `format::Full` for default human‑readable single‑line logs, `format::Compact` for shorter lines, `format::Pretty` for multi‑line pretty logs optimized for local development, and `format::Json` for newline‑delimited JSON logs suitable for production consumption by analysis tools. Developers can customize formatting via the `FormatEvent` and `FormatFields` traits, configuring whether levels, targets, thread IDs, and thread names are included in log lines.

The `filter` module offers `EnvFilter`, which filters spans and events based on directives similar to `env_logger`’s `RUST_LOG` syntax; directives like `target[span{field=value}]=level` describe which spans and events are enabled.[21][26][28] `EnvFilter` implements both `Layer` and `Filter` traits, allowing it to be used for global filtering and per‑layer filtering.[21][26] Builder APIs and `from_env`/`try_from_env` constructors allow parsing directives from strings or environment variables.[21][28] This supports the principle of explicit level control with precedence: CLI options can set environment variables or pass directive strings that `EnvFilter` parses.

Dynamic configuration is implemented via the `reload` module, which provides a `Layer` type that wraps another `Layer` or `Filter` and allows it to be replaced at runtime via a `Handle`.[22][25] This can be used to dynamically reconfigure filtering, such as when `EnvFilter` directives change at runtime.[22][25] The reload layer introduces small overhead but allows flexible configuration, aligning with the principle of idempotent, host‑respecting configuration.

##### Dominant choice

`tracing-subscriber` is the dominant choice for subscribers in the `tracing` ecosystem. Alternatives exist, such as custom subscriber implementations or third‑party formatters like `tracing-bunyan-formatter`, which emits bunyan‑compatible JSON. However, these build on `tracing-core` and often integrate with `tracing-subscriber` for layer composition. `tracing-subscriber`’s widespread use, built‑in fmt and filter layers, and integration with `tracing-opentelemetry` make it the standard.

##### Qualified shortlist

The qualified shortlist includes `tracing-subscriber` and specialized subscribers like `tracing-bunyan-formatter` or project‑specific subscribers used in instrumentation SDKs for web frameworks. These may offer different formatting styles or integration patterns but rely on `tracing-subscriber`’s core abstractions. For `rs-launch-blueprint`, `tracing-subscriber`’s fmt, filter, and reload layers are sufficient.

##### Excluded by gate

No fitness gate excludes `tracing-subscriber`. The crate is licensed under MIT, compatible with `MIT OR Apache-2.0`.[3][16][16] Minimum Rust version is 1.65, compatible with a `stable minus 2` policy as of 2026.[3] There are no RustSec advisories against `tracing-subscriber`; malicious advisories target similarly named but distinct crates, like `tracings` and `tracing-ethers`.[15][15][35][36] Documentation and community usage indicate support for Linux and macOS; Windows is also supported.[3][43][49] Compile‑time and binary‑size costs are moderate, consistent with layering and formatting logic.[7]

##### Up-and-comers

Up‑and‑coming complementary crates include `tracing-opentelemetry-extra`, which simplifies integration with OpenTelemetry by providing higher‑level APIs for tracer and meter providers and logger providers.[17][17][17] Also notable are crates like `console-subscriber`, which provide specialized layers for Tokio task instrumentation. These do not supplant `tracing-subscriber`; they extend its utility.

##### Fit for this template

`tracing-subscriber` fits `rs-launch-blueprint` as the central pipeline builder. It can compose `fmt::Layer` for console output, `EnvFilter` for filtering, custom redaction layers, and `OpenTelemetryLayer` for export.[21][4][20] CLI and web surfaces can share a registry builder that constructs a `tracing-subscriber::registry()` and attaches layers, with profile‑specific choices for fmt configuration (pretty vs JSON) and filter defaults. The reload module allows runtime adjustment of filters based on CLI flags or management APIs.[22][25]

##### Recommendation

`tracing-subscriber` is recommended as the subscriber and layering framework for the logging pipeline. The template should define a function, e.g., `init_logging(config: LoggingConfig)`, that constructs a registry with `EnvFilter`, fmt layers, redaction, and optional `OpenTelemetryLayer`, and then calls `init()` when acting as the process owner.[3][21][4] Library code should not call this function; instead, it should leave logging initialization to host applications.

##### Ranked runner-up

Alternative subscribers like `tracing-bunyan-formatter` or project‑specific subscribers are ranked runners‑up. They might be used to produce bunyan‑compatible JSON or integrate with specific logging backends, but they add complexity and are not necessary for the template’s generic logging pipeline. For `rs-launch-blueprint`, they are not recommended.

##### Tradeoffs

Using `tracing-subscriber` introduces complexity in layer composition and type management, especially when combining fmt, filter, redaction, and OpenTelemetry layers.[21][22][4] The `reload` module adds overhead and type complexity, as noted in community discussions.[22][25] However, the benefits—flexible formatting, dynamic filtering, structured diagnostics, and observability integration—make these tradeoffs acceptable.

##### Parameters

`tracing-subscriber` does not own parameters; it is configured by the logging pipeline contract. It assumes `rust-edition = 2024` and MSRV policy, and its minimum Rust version of 1.65 is compatible.[3] It also assumes that CLI and web profiles will supply appropriate `EnvFilter` directives and fmt layer configurations.

##### Migration implications

Migrating from Python’s handler‑based logging to `tracing-subscriber` involves mapping processor chains to layers. Python’s structlog processors for TTY‑based format selection become profile‑driven fmt layer selection; redaction processors become custom layers and `redactable` derive usage; OpenTelemetry processors become `OpenTelemetryLayer` layers.[4][20][9] The template’s logging module must provide builder functions that mimic Python’s behaviors with layers.

##### Validation strategy

Validation includes constructing a registry with fmt, filter, redaction, and OpenTelemetry layers and running sample CLI and web commands to ensure logs appear in expected formats, with redacted fields and correct filtering.[21][4][9] For dynamic filtering, reloading `EnvFilter` via a `reload::Layer` handle and observing that previously suppressed events become visible verifies behavior.[22][25]

##### Confidence & re-verify trigger

Confidence in `tracing-subscriber` is high, given its centrality to the `tracing` ecosystem and widespread adoption.[3][43][7] Re‑verification should be triggered by major version changes, RustSec advisories, or new ecosystem guidance suggesting alternative layering frameworks.[39][45]

##### Sources

This analysis uses `tracing-subscriber`’s docs.rs README,[3][16][16] fmt and filter module documentation,[21][26][28] reload module docs,[22][25] and production examples from Tokio console, Actix‑web, Axum, and observability guides.

#### log

##### Landscape

The `log` crate is the canonical logging facade in Rust.[30][48] It provides macros for log levels and defines a logging API that abstracts over actual logging implementations, allowing libraries to log without committing to a specific backend.[30][48] The crate is maintained under the `rust-lang/log` GitHub repository and is considered part of the core Rust ecosystem.[48][37]

Docs.rs describes `log` as a lightweight logging facade and lists numerous logger implementations, including minimal loggers (`env_logger`, `simple_logger`, `stderrlog`), complex frameworks (`log4rs`, `fern`), and adaptors (`syslog`, `systemd-journal-logger`).[30] The documentation emphasizes that libraries should link only to `log` and use the provided macros, while executables must choose a logger implementation and initialize it early in the program.[30][37] This matches ecosystem convention and the principle of host logging ownership.

Practice evidence shows `log` as ubiquitous in Rust libraries. Logging examples in books like “Black Hat Rust” use `log` macros and initialize `env_logger` in executables.[37] Shuttle’s logging comparison identifies `log` as best for libraries and notes that almost every crate supports `log`.[6] `flexi_logger`, `fern`, and `log4rs` all plug into `log` and expect library code to use `log` macros.[8][10][27][46] This makes `log` the standard for library instrumentation.

##### Principles and implementation

`log` implements the principle of host logging ownership by decoupling logging APIs from implementations.[30][48] Libraries depend on `log` and emit log records with levels and optional key‑value data; executables initialize a logger implementation compatible with `log`, such as `env_logger::init()` or `flexi_logger::init()`, early in runtime.[30][29][8] This ensures that hosts can choose how to format, filter, and send logs.

The crate defines macros for standard log levels and offers structured key‑value support via a `kv` feature.[30] It provides a global logger interface, and logger implementations implement the `Log` trait and set themselves as the global logger.[29][30] This aligns with Rust’s global logging model.

##### Dominant choice

`log` is the dominant logging facade for libraries; there is no serious alternative. It is maintained by the Rust core team and widely adopted across crates.[48][30][37]

##### Qualified shortlist

No other facade competes with `log` for library use; `tracing` could theoretically serve as instrumentation in libraries, but ecosystem convention and guidance recommend `log`.[7][6][30]

##### Excluded by gate

`log` passes all fitness gates. License is `MIT OR Apache-2.0`, compatible with the template.[30] Minimum Rust version is low (the crate has existed since early Rust), well within MSRV policy. There are no RustSec advisories against `log`; RustSec targets malicious crates like `envlogger` and `tracings`, not `log`.[34][15][15] `log` works on Linux and macOS (and Windows) via minimal dependencies.[30][48] Binary size and compile time overhead are negligible.

##### Up-and-comers

No up‑and‑comers challenge `log` as a facade. Some projects experiment with using `tracing` in libraries, but this is not mainstream.[7][6]

##### Fit for this template

`log` fits `rs-launch-blueprint` as the instrumentation API for the core library crate(s). It allows host applications to choose logger implementations and integrate with their own logging pipelines, while the template can provide optional helpers to route `log` records into tracing via `tracing-log`.[30][48][13]

##### Recommendation

`log` is recommended as the logging facade for library code in `rs-launch-blueprint`. All library modules should use `log` macros for logging and avoid initializing global loggers.[30][37]

##### Ranked runner-up

There is no meaningful runner‑up for the facade role; `tracing` is used for application instrumentation, not as a facade for libraries.

##### Tradeoffs

Using `log` limits library code to flat log records; structured spans must be added by application code via `tracing`.[30][7] However, this tradeoff is acceptable and necessary to respect host logging ownership.

##### Parameters

`log` does not own parameters; it is part of the stack. It assumes the template’s MSRV and license policy, which are compatible.[30]

##### Migration implications

Migrating from Python’s structlog to `log` in libraries involves flattening structured logs into key/value fields and leaving span context to application code via `tracing`. Library functions that logged via structlog must now use `log` macros and let application surfaces add span context.[37][6]

##### Validation strategy

Validation includes instrumenting a library function with `log::info!` and verifying that logs appear when a host initializes `env_logger`, `flexi_logger`, or `tracing-subscriber` with `tracing-log`.[29][8][10][13]

##### Confidence & re-verify trigger

Confidence in `log` is very high, given its core ecosystem status.[48][30] Re‑verification would be triggered only by a major shift in ecosystem logging conventions or a RustSec advisory against `log`.[39]

##### Sources

This analysis uses `log` docs.rs documentation,[30] GitHub repository,[48] logging examples in “Black Hat Rust,”[37] and ecosystem guidance from Shuttle’s logging comparison.[6]

#### tracing-opentelemetry

##### Landscape

`tracing-opentelemetry` provides utilities for adding OpenTelemetry interoperability to `tracing`.[4][20][42] It offers a subscriber layer that connects spans from multiple systems into a trace and emits them to OpenTelemetry‑compatible distributed tracing systems for processing and visualization.[4][20][42] The crate is maintained in the `tokio-rs/tracing-opentelemetry` repository.[42]

Docs.rs describes `tracing-opentelemetry` as providing an `OpenTelemetryLayer` that adds OpenTelemetry context to all tracing spans, and an `OpenTelemetrySpanExt` extension trait that allows injecting and extracting OpenTelemetry parent trace information from tracing spans.[4][20][42] It also provides methods to set span attributes, span status, and add OpenTelemetry events with dynamic attributes and timestamps.[4][20] Feature flags include `metrics`, which enables a `MetricsLayer` type that exports OpenTelemetry metrics from specifically named events.[4][20][20]

Practice evidence shows `tracing-opentelemetry` as the standard bridge between tracing and OpenTelemetry. Guides on setting up OpenTelemetry tracing in Rust combine `tracing`, `tracing-subscriber`, `tracing-opentelemetry`, and OpenTelemetry SDK crates, configuring OTLP exporters and resource attributes.[9] Axum observability examples and `axum-tracing-opentelemetry` use this crate to propagate traces and integrate with collectors like Jaeger. The crate has recent releases through 2026 (e.g., version 0.33.0), indicating active maintenance.[20][42]

##### Principles and implementation

`tracing-opentelemetry` implements the principle of OpenTelemetry correlation by mapping tracing spans to OpenTelemetry spans and traces.[4][20][42] The `OpenTelemetryLayer` attaches OpenTelemetry context (trace IDs, span IDs, baggage) to tracing spans and events, ensuring that exported data can be correlated across services.[4][20][49] The layer interacts with an OpenTelemetry tracer provider, usually from `opentelemetry-sdk`, and uses OTLP to export data to a collector.[44][49][9]

The crate supports metrics export via the `metrics` feature and `MetricsLayer`, enabling a unified pipeline for traces and metrics.[4][20] It does not directly export logs via OpenTelemetry; logging to OpenTelemetry collectors requires `opentelemetry-appender-tracing` or other log bridge crates.[2][49] This is acceptable for R58, which focuses on trace/span correlation.

Version compatibility is carefully managed; `tracing-opentelemetry` notes that its versions are not synchronized with OpenTelemetry crates but generally track one version ahead.[4][20][20] This requires attention in the template’s dependency management.

##### Dominant choice

`tracing-opentelemetry` is the dominant choice for bridging `tracing` to OpenTelemetry. Alternatives include writing custom exporters using OpenTelemetry SDK APIs or using opinionated integration crates like `axum-tracing-opentelemetry` and `tracing-opentelemetry-extra`, but these build on `tracing-opentelemetry`.[17][17]

##### Qualified shortlist

The shortlist includes `tracing-opentelemetry` and `tracing-opentelemetry-extra`. The latter simplifies OTLP exporter setup and resource attributes and uses a guard pattern for cleanup.[17][17][17] For `rs-launch-blueprint`, `tracing-opentelemetry` is sufficient; `tracing-opentelemetry-extra` could be considered if integration complexity becomes a barrier.

##### Excluded by gate

`tracing-opentelemetry` passes fitness gates. License is MIT.[4][20][42] It is maintained actively, with recent releases.[20][42] No RustSec advisories exist against this crate.[39] OS support includes Linux and macOS via OpenTelemetry SDKs.[44][49] Compile‑time and binary size costs are moderate, primarily due to OpenTelemetry SDK dependencies.[44][49]

##### Up-and-comers

`tracing-opentelemetry-extra` is an up‑and‑comer that provides enhanced integration with OTLP exporters, configurable sampling, resource attributes, and support for tracing, metrics, and logs.[17][17][17] It may be used as a convenience wrapper in future iterations, but R58 does not require it.

##### Fit for this template

`tracing-opentelemetry` fits `rs-launch-blueprint` as the optional OpenTelemetry integration layer. It allows the web example to export traces to a collector and achieve correlation between logs and traces via trace IDs.[4][20][9] It is gated behind a Cargo feature (`otel`) to match Python’s soft import pattern.[9][49]

##### Recommendation

`tracing-opentelemetry` is recommended as the OpenTelemetry integration crate. The template should define an optional module (enabled via feature) that configures an OpenTelemetry tracer provider and adds an `OpenTelemetryLayer` to the tracing subscriber.[4][9][44][49] Logs should include trace IDs as fields for correlation.

##### Ranked runner-up

`tracing-opentelemetry-extra` is the runner‑up, offering a simpler API for tracer setup.[17][17][17] It may be adopted if `tracing-opentelemetry`’s APIs are deemed too complex.

##### Tradeoffs

Using `tracing-opentelemetry` adds dependency and configuration complexity, requiring OpenTelemetry SDK setup and OTLP endpoint configuration.[9][44][49] However, it provides standardized observability and vendor‑agnostic telemetry export.

##### Parameters

`tracing-opentelemetry` does not own template parameters; it is activated by an `otel` feature. It assumes that R69’s web surface will use HTTP frameworks that benefit from tracing.

##### Migration implications

Migration involves adding an `OpenTelemetryLayer` to the tracing pipeline and configuring an OTLP exporter, mapping Python’s `opentelemetry.trace` soft import to Rust’s feature gating and SDK setup.[9][44][49]

##### Validation strategy

Validation includes running the web example with the `otel` feature enabled, sending requests, and verifying that traces appear in a collector like Jaeger with coherent span trees and trace IDs matching log fields.[4][9]

##### Confidence & re-verify trigger

Confidence is high due to maintainer backing and ecosystem adoption.[4][20][42][44][49] Re‑verification should be triggered by major version changes in OpenTelemetry or RustSec advisories.[39][44]

##### Sources

This analysis relies on `tracing-opentelemetry` docs.rs,[4][20][20] GitHub repository,[42] OpenTelemetry Rust documentation,[44][49] and observability guides.[9]

#### redactable

##### Landscape

`redactable` is a redaction library for Rust that lets developers mark sensitive data in structs and enums and produce safe, redacted versions for logging and telemetry. It is documented on lib.rs and designed to integrate with logging frameworks like slog and tracing via marker traits and structured data inspection.

Docs describe two derive macros, `Sensitive` and `SensitiveDisplay`, for types with sensitive data. `Sensitive` produces redacted structured types, while `SensitiveDisplay` produces redacted strings. The crate integrates with slog via `slog::Value` and marker traits, and with tracing via `TracingRedacted` and valuable integration. It emphasizes that redaction must be opt‑in and that both structured and display paths should share the same annotation model.

Practice evidence is limited but growing; `redactable` fills a niche in logging safety and redaction in Rust. Its design is aligned with practices from security‑sensitive projects and proposals like Smithy’s logging sensitive RFC, which demands redaction of sensitive data in tracing events and spans.

##### Principles and implementation

`redactable` implements the principle of secret handling by providing explicit annotations for sensitive fields and transformation code that replaces values with redacted equivalents. Fields annotated with `#[sensitive(Policy)]` are treated as sensitive, and derive macros generate code that applies policies like `Secret`, which replaces strings with `"[REDACTED]"` and scalars with default values. The crate ensures that unannotated fields pass through unchanged, and container types delegate to their traits.

For structured logging with tracing, `redactable` uses the `valuable` crate to integrate with tracing’s sealed value traits. Methods like `.tracing_redacted_valuable()` redacts data and wraps it for valuable inspection, while `SensitiveValue<T, P>` wrappers provide redacted values for individual fields. Marker traits `SlogRedacted` and `TracingRedacted` certify that types are safe to log and enforce compile‑time constraints that only redacted types pass through logging sinks.

##### Dominant choice

`redactable` is a leading choice for typed redaction in Rust logging pipelines. Alternatives include custom redaction logic in subscribers or layers, but these lack the type‑safe, annotation‑based approach `redactable` offers.

##### Qualified shortlist

The shortlist includes `redactable` and purely custom redaction layers built into `tracing-subscriber`. Custom layers can inspect field names and values and apply redaction based on key patterns; they are simpler but less robust for structured types. For `rs-launch-blueprint`, combining `redactable` with a key‑pattern layer is ideal.

##### Excluded by gate

No gate excludes `redactable`. License is likely MIT or Apache (lib.rs indicates standard licensing), compatible with template policy. RustSec advisories do not mention `redactable`.[39] OS support and MSRV are not constrained; the crate is small and depends on language features available in stable Rust.

##### Up-and-comers

Other redaction or logging safety crates may emerge, but `redactable` currently occupies this niche.

##### Fit for this template

`redactable` fits `rs-launch-blueprint` as the structured redaction tool. It allows marking sensitive fields in types like `User`, `AuthToken`, or `Config` and ensures that logs and telemetry only emit redacted versions. Combined with a custom `Layer` for key‑pattern redaction, it covers both structured types and ad‑hoc log messages.

##### Recommendation

`redactable` is recommended as part of the logging stack for typed redaction. The template should integrate it into logging modules and derive `Sensitive` or `SensitiveDisplay` on domain types with sensitive fields.

##### Ranked runner-up

A purely custom redaction layer in `tracing-subscriber` is the runner‑up. It can handle simple string fields but lacks the type safety and annotation model of `redactable`.

##### Tradeoffs

Using `redactable` adds a dependency and requires developers to annotate types and fields, increasing cognitive load. However, the payoff is robust secret handling and compile‑time assurance that only redacted data is logged.

##### Parameters

`redactable` does not own parameters; it is part of the stack. It assumes that the logging pipeline uses tracing and valuable for structured data.

##### Migration implications

Migration from Python’s `SENSITIVE_KEY_PARTS` model to `redactable` involves moving from key‑based redaction in processor chains to annotation‑based redaction in types. Python’s redaction function that scans keys for sensitive parts is complemented by `redactable` attributes in Rust, which offer finer control and type safety.

##### Validation strategy

Validation includes defining a struct with sensitive fields, deriving `Sensitive`, and logging its redacted version via tracing; verifying that logs do not contain raw sensitive values confirms behavior. Additional checks include ensuring that `TracingRedacted` marker traits prevent non‑redacted types from being logged in redaction‑sensitive sinks.

##### Confidence & re-verify trigger

Confidence is moderate: `redactable` is specialized but aligned with security recommendations like Smithy’s sensitive logging RFC. Re‑verification should be triggered by major version changes or RustSec advisories.[39]

##### Sources

This analysis uses `redactable`’s lib.rs documentation, Smithy’s logging sensitive RFC, and tracing integration details.

#### tracing-log

##### Landscape

`tracing-log` is a compatibility crate that connects `log` records to the `tracing` ecosystem.[13][43][13] It allows logs emitted via the `log` facade to be recorded as tracing events, enabling hybrid logging pipelines where library code uses `log` and application code uses `tracing`.[13][43]

Docs.rs and repository information describe `tracing-log` as providing macros and layers to capture `log` records, but details are summarized in `tracing`’s documentation and ecosystem listings.[43][13]

##### Principles and implementation

`tracing-log` implements the hybrid model principle of capturing `log` records into tracing. It intercepts `log` records and forwards them as tracing events, preserving level and message information.[13][43] This allows a single `tracing-subscriber` registry to process events from both `tracing` and `log` sources.

##### Dominant choice

`tracing-log` is the dominant compatibility crate for bridging `log` to `tracing`. No alternative offers the same integration.

##### Qualified shortlist

No meaningful shortlist exists; other approaches involve manual bridging, which is less robust.

##### Excluded by gate

`tracing-log` passes fitness gates; it is maintained in the `tokio-rs/tracing` ecosystem and shares licensing and MSRV compatibility.[43][13] There are no RustSec advisories.

##### Up-and-comers

No up‑and‑comers challenge `tracing-log`; it occupies a narrow compatibility niche.

##### Fit for this template

`tracing-log` fits `rs-launch-blueprint` as the bridge between library `log` instrumentation and application `tracing` subscribers. It allows the template’s logging pipeline to collect library logs without requiring libraries to depend on `tracing`.[13][43]

##### Recommendation

`tracing-log` is recommended for inclusion in the stack, configured in the tracing subscriber registry when the template initializes logging.[13][43]

##### Ranked runner-up

Manual bridging via custom logger implementations is a runner‑up but not recommended.

##### Tradeoffs

Using `tracing-log` adds a small dependency and complexity in subscriber setup but provides seamless integration.[13][43]

##### Parameters

`tracing-log` assumes the presence of `log` and `tracing`.[13][43]

##### Migration implications

Migration includes adding `tracing-log` as a dependency and configuring it in the tracing subscriber registry.[13][43]

##### Validation strategy

Validation involves emitting `log` records from library code and verifying that they appear as tracing events in formatted output.[13][43]

##### Confidence & re-verify trigger

Confidence is high; `tracing-log` is part of the core tracing ecosystem.[43][13] Re‑verification triggers include ecosystem changes.

##### Sources

This analysis relies on tracing ecosystem documentation and repository listings.[43][13][13]

### Compatibility

The recommended stack—`log`, `tracing`, `tracing-log`, `tracing-subscriber`, `redactable`, and `tracing-opentelemetry` with OpenTelemetry SDK crates—is compatible and tested together in multiple contexts. The `tokio-rs/tracing` repository demonstrates the use of `tracing`, `tracing-core`, `tracing-subscriber`, and `tracing-log` together.[43][13][13] Observability examples like OneUptime’s Actix configuration and Axum tracing integrations show `tracing` + `tracing-subscriber` + `tracing-opentelemetry` working together with web frameworks. The OpenTelemetry Rust implementation supports integration with tracing via `tracing-opentelemetry`, and features like trace API, OTLP exporter, and metrics are documented and tested.[44][49][4][20] `redactable` integrates with tracing for structured redaction via `valuable` and marker traits. 

Shared adopters include Tokio console (`console-subscriber` layer added to tracing subscribers), Axum tracing OpenTelemetry middleware, and Actix‑web tracing middleware, all of which rely on `tracing` and `tracing-subscriber` and often `tracing-opentelemetry` for export. This evidence confirms that the stack components are compatible.

### Parameters

For R58, the logging pipeline contract owns and sets:

- `owns logging-pipeline-contract = hybrid-tracing-stack` (the architecture described above).
- `owns logging-format-policy = {CLI: default pretty console; JSON via flag; Web: default JSON; both share redaction and level resolution}`.
- `owns logging-level-precedence = {explicit --log-level/env > config-file defaults > -q/-v ladder}` (F274).[Context][6]
- `owns logging-secret-policy = {opt-in typed redaction via redactable + key-pattern redaction layer; no raw sensitive data in logs}`.
- `owns logging-otel-feature = Cargo feature `otel` gating tracing-opentelemetry and OpenTelemetry SDK crates; required for web example but optional for CLI-only usage.[4][20][44][49][9]

It assumes:

- `assumes rust-edition = 2024`.[Context]
- `assumes msrv-policy = stable minus 2 minor versions, declared in Cargo.toml and tested in CI`.[Context][3][30]
- `assumes license = MIT OR Apache-2.0` for template and stack members.[30][3][4]
- `assumes target-os-matrix = ubuntu-latest, macos-latest` for CI.[Context][43][44]
- `assumes R69 web-extra-surface = may be present; if present, uses a web framework with tracing integration (e.g., Actix‑web or Axum).`

No consumed parameter conflict is identified. If R69 chooses a web framework without tracing integrations, the template can still use tracing for its own instrumentation; thus no conflict arises.

### Migration implications

File‑level changes in the template will be extensive but systematic. A new `core/logging.rs` module will be introduced, analogous to Python’s `core/logging.py`, defining the logging pipeline builder. It will:

- Define a `LoggingConfig` struct capturing format preferences (human vs JSON), level overrides (`--log-level`, env), profile (CLI vs web), and OpenTelemetry settings (endpoint, sampler).[9]
- Implement a `init_logging(config: &LoggingConfig)` function that constructs a `tracing-subscriber::registry()` and attaches `EnvFilter`, fmt layers, a redaction layer, `tracing-log` integration, and optionally `OpenTelemetryLayer`.[3][21][4][20]
- Use `stderr.isatty()` (via Rust’s `atty` crate or similar, though not specified here) to auto‑select pretty vs JSON for CLI when format is `auto`.

CLI code (e.g., `cli/main.rs`) will:

- Parse verbosity flags and `--log-level`/env options via the chosen CLI framework (e.g., `clap`), as decided in R60, and resolve an effective level directive string.[6]
- Call `init_logging` with a CLI profile, before executing commands.

Library code will:

- Replace any direct `eprintln!` or `println!` logging with `log` macros.[30][37]
- Avoid any logging initialization; all logging configuration is left to host applications or the CLI/web surfaces.[30][48]

Web service code (if R69 enables it) will:

- Use tracing instrumentation (`#[instrument]`, `info!`) in handlers.
- Call `init_logging` with a web profile and `otel` feature enabled, configuring OpenTelemetry export.[4][9]

Tests will:

- Optionally configure logging to `std::io::sink` or stdout based on an environment variable like `TEST_LOG`, mirroring the “Zero to Production” pattern.

These changes align Rust files with Python’s logging architecture while using Rust idioms.

### Validation strategy

Validation is both conceptual and executable. Planned checks include:

1. **CLI logging behavior**: Run `cargo run -- --log-level info` and verify that CLI commands emit human‑readable logs with appropriate levels and redacted sensitive fields. Then run `RUST_LOG=debug cargo run` and verify that debug events are visible, with filter behavior matching the precedence ladder (explicit flag over env over verbosity).[21][28]

2. **Format switching**: With stderr attached to a TTY, verify that default CLI logs use pretty formatting; with stderr redirected to a file or pipeline, verify that JSON format is selected (if `auto` format is implemented).

3. **Redaction**: Define a type with sensitive fields, derive `Sensitive` or `SensitiveDisplay`, log it via tracing, and verify that logs show redacted values; emit events with fields named “token” or “password” and verify that custom redaction layers replace values.

4. **Hybrid logging**: Emit `log::info!` from library code and `tracing::info!` from application code, and verify that both appear in the same formatted output via tracing subscribers and `tracing-log`.[30][13][43]

5. **OpenTelemetry integration**: Enable the `otel` feature, configure `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4317`, run the web service, send HTTP requests, and verify that traces appear in Jaeger with span trees reflecting handler instrumentation and trace IDs matching log fields.[4][9][44][49]

6. **Dynamic filter reload**: Wrap `EnvFilter` in a `reload::Layer`, start with `LevelFilter::WARN`, emit `info!` events, change filter to `LevelFilter::INFO` via a handle, and observe that subsequent `info!` events are logged.[22][25]

These checks will be implemented as integration tests or manual runs in the template repository. At this stage, they are proposed rather than executed.

### Confidence & re-verify trigger

Confidence in the recommended stack and architecture is high, based on alignment with ecosystem practice (`tracing` + `tracing-subscriber` for services, `log` for libraries), authoritative documentation, and production examples in Tokio, Actix‑web, Axum, and observability guides.[7][6][43][3] However, given the deep integration with external crates and evolving Rust ecosystems, re‑verification triggers include:

- Major version releases of `tracing`, `tracing-subscriber`, `tracing-opentelemetry`, or OpenTelemetry crates, especially those changing APIs or minimum Rust versions.[45][20][44][49]
- RustSec advisories against any stack member or closely related crate (e.g., new malicious typosquats in the tracing ecosystem).[34][15][15][35][36][39]
- Changes in R69’s web framework choice that might affect logging integration strategies.
- Owner direction updates in `docs/port/OWNER-REVIEW.md` that alter logging principles or acceptance criteria.[Context]

Periodic review (e.g., annually or on major Rust or crate releases) is advisable.

### Sources

This report relies on a diverse set of sources: official crate documentation on docs.rs for `tracing`, `tracing-subscriber`, `tracing-opentelemetry`, `log`, `env_logger`, `flexi_logger`, `fern`, `log4rs`, and `redactable`;[11][3][4][20][30][29][8][10][27] GitHub repositories and pages for `tokio-rs/tracing`, `tokio-rs/tracing-opentelemetry`, OpenTelemetry Rust, slog, flexi_logger, and community integration projects like `tracing-actix-web` and `axum-tracing-opentelemetry`;[41][43][42][44][49][50][46] RustSec advisories for malicious crates like `envlogger`, `tracings`, `tracing-ethers`, and `tracing-check`;[34][15][15][35][36] and widely cited independent write‑ups and guides on logging and observability in Rust, including Shuttle’s logging comparison, the 2026 Rust logging comparison, Tokio console tracing guides, Actix production configuration, Axum instrumentation guides, and the “Zero to Production in Rust” series.[6][7] These sources provide authoritative, practice‑grounded evidence for the recommended architecture.

## Sources

- [Comparing logging and tracing in Rust](https://blog.logrocket.com/comparing-logging-tracing-rust/)
- [tracing_opentelemetry - Rust](https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/)
- [tracing_subscriber - Rust](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/)
- [tracing-opentelemetry 0.32.1 - Docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest)
- [fern - Rust](https://vorner.github.io/spirit/doc/fern/index.html)
- [Logging in Rust (2025) - Shuttle.dev](https://www.shuttle.dev/blog/2023/09/20/logging-in-rust)
- [Rust tracing vs log: Which Logging Crate Should You Use ...](https://rustify.rs/articles/rust-tracing-vs-log-crates-2026)
- [flexi_logger 0.31.7 - Docs.rs](https://docs.rs/crate/flexi_logger/latest)
- [How to Set Up OpenTelemetry Tracing in Rust](https://oneuptime.com/blog/post/2026-02-06-opentelemetry-tracing-rust-tracing-crate/view)
- [fern 0.3.1 - Docs.rs](https://docs.rs/crate/fern/0.3.1)
- [tracing 0.1.31](https://docs.rs/crate/tracing/0.1.31/source/README.md)
- [tracing.rs - source - Will Crichton](https://willcrichton.net/example-analyzer/src/tracing/tracing.rs.html)
- [Information for gstreamer:rs](https://repology.org/project/gstreamer:rs/information)
- [Information for cargo-audit](https://repology.org/project/cargo-audit/information)
- [RUSTSEC-2026-0027 - OSV - Open Source Vulnerabilities](https://osv.dev/vulnerability/RUSTSEC-2026-0027)
- [tracing-subscriber 0.3.19](https://docs.rs/crate/tracing-subscriber/latest/source/README.md)
- [tracing-opentelemetry-extra](https://lib.rs/crates/tracing-opentelemetry-extra)
- [Information for rust:tracing-attributes](https://repology.org/project/rust:tracing-attributes/information)
- [env_filter](https://lib.rs/crates/env_filter)
- [tracing-opentelemetry - Debugging - Lib.rs](https://lib.rs/crates/tracing-opentelemetry)
- [EnvFilter in tracing_subscriber::filter - Rust](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/filter/struct.EnvFilter.html)
- [Reload](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/index.html)
- [log4rs - Rust - Docs.rs](https://docs.rs/log4rs/latest/log4rs/)
- [log4rs - Rust](https://docs.rs/log4rs/)
- [Struct LayerCopy item path](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/struct.Layer.html)
- [tracing_subscriber::filter - Rust](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/filter/index.html)
- [log4rs 1.4.0 - Docs.rs](https://docs.rs/crate/log4rs/latest)
- [EnvFilter in tracing_subscriber - Rust - Docs.rs](https://docs.rs/tracing-subscriber/0.3.14/tracing_subscriber/struct.EnvFilter.html)
- [Logger in env_logger - Rust](https://docs.rs/env_logger/latest/env_logger/struct.Logger.html)
- [log 0.4.33](https://docs.rs/crate/log/latest)
- [Retrieve download information for a crate within a specified timeframe. · rust-lang crates.io · Discussion #7973](https://github.com/rust-lang/crates.io/discussions/7973)
- [crates.io](https://crates.io/api/openapi.json)
- [Crates.io Download Stats Tracker — Trend by Crate](https://apify.com/m_ctim/crates-download-stats-tracker)
- [envlogger was removed from crates.io for malicious code - RustSec](https://rustsec.org/advisories/RUSTSEC-2023-0099)
- [RUSTSEC-2026-0040: tracing-ethers](https://rustsec.org/advisories/RUSTSEC-2026-0040.html)
- [RUSTSEC-2026-0019: tracing-check](https://rustsec.org/advisories/RUSTSEC-2026-0019.html)
- [Black Hat Rust \[2024 ed.\] - DOKUMEN.PUB](https://dokumen.pub/black-hat-rust-2024nbsped.html)
- [Crates.io Search - Rust Package & Download Stats Scraper](https://apify.com/scrapeworks/crates-search)
- [About RustSec](https://rustsec.org/)
- [Crates.io Download Stats Tracker — Trend by Crate API](https://apify.com/m_ctim/crates-download-stats-tracker/api)
- [tokio-rs/tracing: Application level tracing for Rust. - GitHub](https://github.com/tokio-rs/tracing)
- [tokio-rs/tracing-opentelemetry - GitHub](https://github.com/tokio-rs/tracing-opentelemetry)
- [Application level tracing for Rust. - GitHub Pages](https://tokio-rs.github.io/tracing/)
- [open-telemetry/opentelemetry-rust](https://github.com/open-telemetry/opentelemetry-rust)
- [Releases · tokio-rs/tracing](https://github.com/tokio-rs/tracing/releases)
- [emabee/flexi_logger: A flexible logger for rust programs ... - GitHub](https://github.com/emabee/flexi_logger)
- [Application level tracing for Rust.](https://tokio-rs.github.io/tracing/tracing/)
- [GitHub - rust-lang/log: Logging implementation for Rust](https://github.com/rust-lang/log)
- [OpenTelemetry Rust](https://open-telemetry.github.io/opentelemetry-rust/)
- [slog-rs/slog: Structured, contextual, extensible ...](https://github.com/slog-rs/slog)

## Cost

Total: $1.3664