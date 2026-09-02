# Deep-research prompt — Logging pipeline architecture (R58, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts py's structured logging pipeline — TTY-aware JSON-vs-human console format auto-selection, a structured key/value processor chain, key-based secret redaction, optional OpenTelemetry trace/span correlation, an explicit `--log-level` flag/env alongside the verbosity ladder, idempotent own-handler-only reconfiguration, and (if a web surface exists) one shared pipeline expressed as per-front-end policy profiles — versus ts's hand-rolled plain-text leveled logger with none of these. Item kind: `bundle`. Value test: if this answer is wrong, the logging crate dependency, the console format auto-detection logic, the redaction step, the OpenTelemetry integration (if any), the `--log-level` flag, and the verbosity-to-level resolution ladder's precedence order all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py builds a full structured logging pipeline — a processor chain that auto-selects JSON vs. human console output from TTY-ness, redacts sensitive keys, optionally correlates OpenTelemetry trace/span IDs, exposes an explicit `--log-level` flag/env ahead of the `-v`/`-q` ladder, and only tears down handlers it itself owns on reconfiguration (idempotent, host-safe). ts's logger is a hand-rolled leveled-line writer with none of these: always plain text, no redaction, no tracing, no explicit level override, a fresh closure per call with no global state to protect. Evidence: F250 py `src/py_launch_blueprint/core/logging.py:120` — `def _resolve_format(fmt: LogFormat) -> LogFormat:` (`sys.stderr.isatty()`); ts's `createLogger` (`src/lib/logger.ts:58`) always writes plain leveled text, no JSON mode. F251 py `src/py_launch_blueprint/core/logging.py:154` — `def _shared_processors() -> list[Processor]:` (structlog processor chain); ts `src/lib/logger.ts:47` — hand-rolled leveled line writer, no structured-event/key-value model. F252 py `src/py_launch_blueprint/core/logging.py:93` — `SENSITIVE_KEY_PARTS: tuple[str, ...] = ("token", "password", ...)` applied by `_redact_sensitive` (`logging.py:143`); ts: no redaction step exists. F253 py `src/py_launch_blueprint/core/logging.py:106` — `_otel_trace: Any = importlib.import_module("opentelemetry.trace")` (soft-imported, optional extra); ts: no tracing integration. F254 py `src/py_launch_blueprint/cli/options.py:85` — `"--log-level", ... envvar="PLBP_LOG_LEVEL",`; ts has no way to set an exact level directly, only relative `-v`/`-q`/`--debug` flags. F262 py `src/py_launch_blueprint/core/logging.py:226` — `for handler in root.handlers[:]: if getattr(handler, _OWNED_FLAG, False): ...`; ts's `createLogger` returns a fresh closure per call with no global registry to protect. F263 py `src/py_launch_blueprint/web/logging.py:20` — web profile docstring: "Same engine as the CLI (`core/logging.py`), different policy"; ts has only the CLI front-end, no second profile to compare. F274 py `src/py_launch_blueprint/cli/context.py:197` — `def _resolve_console_level(` (a two-upstream-override ladder: `--log-level` flag/env, then config-file default, ahead of `-q`/`-v`); ts `src/lib/logger.ts:29` — `export function resolveLevel(flags: VerbosityFlags): LogLevel {` consults only the `-v`/`-q`/`--debug` flags, with no flag/env or config-file override tier. Ledger rows F250, F251, F252, F253, F254, F262, F263 (`docs/port/COMMONALITY.md`, area `config-env-logging`) and F274 (`docs/port/COMMONALITY.md`, area `cli-framework-ux`, cited from both areas' angles per its Notes), all verdict `DIVERGENT`, item R58.
- Already decided, do not re-open: py's choice of a logging *library* to drive this pipeline, versus ts's choice of no library at all (D-018(1)), is presumption-of-reuse context, not a separate research item — this item's decision already subsumes "does `rs-launch-blueprint` use a logging crate," since a JSON/human-format-switching, redacting, optionally-OTel-correlating pipeline (F250-F253) is exactly what a logging crate provides. The relative verbosity-flag-to-level counting mechanics (`-q`/`-v` counting itself) belong to `cli-framework-ux`'s own verbosity items, not this one — this item owns only the resolution ladder's precedence order (F274) and the console pipeline's other properties (F250-F254, F262, F263). `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-018(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts deliberately chose "no logging library; hand-rolled leveled stderr logger... with injected stdout/stderr writers via the CLI deps interface," reusing the org's existing precedent rather than adopting a structured-logging crate; D-018(3) — ts's verbosity mapping adapts cli-standards' repeatable `-v` ladder (`-q` errors+warns only; default info; repeatable `-v`; `--debug` overrides `--quiet`; `--quiet` beats `--verbose`) but has no flag/env/config-file override tier ahead of it, unlike py's F274.

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
Decision: what Rust logging crate stack and pattern give `rs-launch-blueprint` py's structured pipeline properties — TTY-aware console format switching, a structured key/value event model, key-based secret redaction, optional OpenTelemetry correlation, an explicit `--log-level` override ahead of the verbosity ladder, idempotent own-handler-only reconfiguration, and (contingent on R69) one pipeline expressed as per-front-end policy profiles — or does it instead follow ts's no-library, hand-rolled leveled-writer shape?
- HIGH: Is `tracing` (+ `tracing-subscriber`) the dominant Rust analogue for a structured, processor-chain-style pipeline (matching structlog's role), with format auto-selection via a `fmt` layer switching on terminal-ness, or does a simpler crate (e.g. `env_logger`, `log` plus a formatter) suffice given the template's scope?
- HIGH: What crate or pattern performs key-based secret redaction (F252) on structured log fields in the chosen pipeline — a custom subscriber layer, a field-visitor implementation, or is this simple enough to hand-roll regardless of crate choice?
- MEDIUM: Does the chosen crate have first-class, currently-maintained OpenTelemetry trace/span correlation support (matching py's soft-imported optional extra, F253), and can it be gated behind an optional Cargo feature the way py gates it behind an optional dependency extra?
- MEDIUM: What does "idempotent, only tears down handlers it owns" (F262) mean in the chosen crate's global-subscriber model, where the global default can typically only be set once per process — does the pipeline need a reload-capable layer to support reconfiguration at all, and if so is that different enough from py's model to note as a migration risk?
- LOW: If R69 concludes the template ships a web surface, does the chosen crate/pattern support "one pipeline, two profiles" (F263) as two layer configurations sharing one dispatcher, or as two independently initialized subscribers — and does this item's answer hold either way R69 lands?

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
