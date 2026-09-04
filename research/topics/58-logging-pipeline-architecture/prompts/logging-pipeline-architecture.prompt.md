# Deep-research prompt — Logging pipeline architecture (R58, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference architecture for structured, useful diagnostics that protect secrets, support the intended log-level controls, respect a library host's logging ownership, and integrate with the shared OpenTelemetry web example. Derive the required behaviors and agreement level from the owner direction, source evidence and industry practice, then compare native Rust designs. Item kind: `bundle`. Value test: if this answer is wrong, logging initialization, formatting, redaction, configuration, telemetry correlation and CLI/web integration all change.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py builds a full structured logging pipeline — a processor chain that auto-selects JSON vs. human console output from TTY-ness, redacts sensitive keys, optionally correlates OpenTelemetry trace/span IDs, exposes an explicit `--log-level` flag/env ahead of the `-v`/`-q` ladder, and only tears down handlers it itself owns on reconfiguration (idempotent, host-safe). ts's logger is a hand-rolled leveled-line writer with none of these: always plain text, no redaction, no tracing, no explicit level override, a fresh closure per call with no global state to protect. Evidence: F250 py `src/py_launch_blueprint/core/logging.py:120` — `def _resolve_format(fmt: LogFormat) -> LogFormat:` (`sys.stderr.isatty()`); ts's `createLogger` (`src/lib/logger.ts:58`) always writes plain leveled text, no JSON mode. F251 py `src/py_launch_blueprint/core/logging.py:154` — `def _shared_processors() -> list[Processor]:` (structlog processor chain); ts `src/lib/logger.ts:47` — hand-rolled leveled line writer, no structured-event/key-value model. F252 py `src/py_launch_blueprint/core/logging.py:93` — `SENSITIVE_KEY_PARTS: tuple[str, ...] = ("token", "password", ...)` applied by `_redact_sensitive` (`logging.py:143`); ts: no redaction step exists. F253 py `src/py_launch_blueprint/core/logging.py:106` — `_otel_trace: Any = importlib.import_module("opentelemetry.trace")` (soft-imported, optional extra); ts: no tracing integration. F254 py `src/py_launch_blueprint/cli/options.py:85` — `"--log-level", ... envvar="PLBP_LOG_LEVEL",`; ts has no way to set an exact level directly, only relative `-v`/`-q`/`--debug` flags. F262 py `src/py_launch_blueprint/core/logging.py:226` — `for handler in root.handlers[:]: if getattr(handler, _OWNED_FLAG, False): ...`; ts's `createLogger` returns a fresh closure per call with no global registry to protect. F263 py `src/py_launch_blueprint/web/logging.py:20` — web profile docstring: "Same engine as the CLI (`core/logging.py`), different policy"; ts has only the CLI front-end, no second profile to compare. F274 py `src/py_launch_blueprint/cli/context.py:197` — `def _resolve_console_level(` (a two-upstream-override ladder: `--log-level` flag/env, then config-file default, ahead of `-q`/`-v`); ts `src/lib/logger.ts:29` — `export function resolveLevel(flags: VerbosityFlags): LogLevel {` consults only the `-v`/`-q`/`--debug` flags, with no flag/env or config-file override tier. Ledger rows F250, F251, F252, F253, F254, F262, F263 (`docs/port/COMMONALITY.md`, area `config-env-logging`) and F274 (`docs/port/COMMONALITY.md`, area `cli-framework-ux`, cited from both areas' angles per its Notes), all verdict `DIVERGENT`, item R58.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): py's choice of a logging *library* to drive this pipeline, versus ts's choice of no library at all (D-018(1)), is presumption-of-reuse context, not a separate research item — this item's decision already subsumes "does `rs-launch-blueprint` use a logging crate," since a JSON/human-format-switching, redacting, optionally-OTel-correlating pipeline (F250-F253) is exactly what a logging crate provides. The relative verbosity-flag-to-level counting mechanics (`-q`/`-v` counting itself) belong to `cli-framework-ux`'s own verbosity items, not this one — this item owns only the resolution ladder's precedence order (F274) and the console pipeline's other properties (F250-F254, F262, F263). `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-018(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts deliberately chose "no logging library; hand-rolled leveled stderr logger... with injected stdout/stderr writers via the CLI deps interface," reusing the org's existing precedent rather than adopting a structured-logging crate; D-018(3) — ts's verbosity mapping adapts cli-standards' repeatable `-v` ladder (`-q` errors+warns only; default info; repeatable `-v`; `--debug` overrides `--quiet`; `--quiet` beats `--verbose`) but has no flag/env/config-file override tier ahead of it, unlike py's F274.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Look at the best practices and principles from the Python logging and see what applies to best architectural practices for both TypeScript and Rust. There should be a specific research item here.

## Out of scope
- Whether a rotating file log sink exists, its rotation policy, and its own independent level; R59 (`file-log-sink`) owns F255-F261 — this item designs the console/structured pipeline itself, not the file sink attached to it.
- The separate XDG data/state/cache directory set a file sink's default path might need; R57 (`xdg-directory-set`) owns F249.
- Whether `rs-launch-blueprint` ships an optional web surface at all (the `web-extra-surface` parameter); R69 (`web-framework-stack`) owns that decision — this item's per-front-end-profile design (F263) must work whether or not a web surface exists, and must not assume one.
- The repeatable `-v`/`--verbose` flag's existence and repeat-counting mechanics themselves (as opposed to this item's F274 resolution-ladder precedence); F273, `COMMON → REUSE`, is already inherited (both repos count repeated `-v` occurrences the same way) — it is not a research item, so there is nothing to defer to on that point. The CLI-parsing framework/library that provides those flags (`clap` or equivalent) is R60's (`cli-parsing-framework`) decision (F264) — this item's pipeline design must not assume a specific framework.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R58
- owns:
- consumes: R69: web-extra-surface
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
