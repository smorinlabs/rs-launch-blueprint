# Deep-research prompt — File log sink (R59, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` ships an optional rotating file log sink (matching py's `[logging]` config-table-driven, size+backup-count-rotated, independently-leveled file handler) or ships no file sink at all (matching ts). Item kind: `bundle`. Value test: if this answer is wrong, whether a `[logging]` table exists in the config schema at all, whether a `--log-file` flag/env and a rotation dependency exist, and the dual-sink level-floor logic all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py ships an optional rotating file log sink, configured by a `[logging]` table in the config file (`level`/`file`/`file_level`/`format` fields), enabled by a `--log-file` flag/env defaulting to an XDG state path, with flag/env > config `logging.file` > off precedence, an independently overridable file-sink format via env, and a level floor that is the minimum of the console and file sink levels so the root logger never filters out something either sink wants. ts has no file sink at all — its logger writes only to the injected stderr writer. Evidence: F255 py `src/py_launch_blueprint/core/settings.py:49` — `class LoggingSettings(BaseModel):` (`level`, `file`, `file_level`, `format` fields); ts's config schema (`src/lib/config.ts:33`) carries only `token`/`workspace`/`limit`, no logging settings. F256 py `src/py_launch_blueprint/core/logging.py:241` — `file_handler = RotatingFileHandler(file_path, maxBytes=ROTATE_MAX_BYTES, backupCount=ROTATE_BACKUP_COUNT, ...)`; ts: no file sink at all (`src/lib/logger.ts:58` writes only the injected stderr writer). F257 py `src/py_launch_blueprint/core/logging.py:82` — `ROTATE_MAX_BYTES = 10 * 1024 * 1024` / `ROTATE_BACKUP_COUNT = 5`; ts: none. F258 py `src/py_launch_blueprint/cli/options.py:93` — `"--log-file", ... envvar="PLBP_LOG_FILE",`; ts: none. F259 py `src/py_launch_blueprint/cli/context.py:212` — `def _resolve_log_file(...)`; ts: none. F260 py `src/py_launch_blueprint/cli/context.py:233` — `def _resolve_log_format(config_format: str) -> str:`; ts: none. F261 py `src/py_launch_blueprint/core/logging.py:259` — `floor = min(level, file_level)` then `root.setLevel(floor)` (`logging.py:262`); ts: none, since there is only one sink. Ledger rows F255, F256, F257, F258, F259, F260, F261 (`docs/port/COMMONALITY.md`), all verdict `DIVERGENT`, item R59.
- Already decided, do not re-open: the console/structured logging pipeline this file sink attaches to (F250-F254, F262, F263, F274) is R58's decision, not this item's — design the file sink to plug into whatever pipeline R58 recommends. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item is a strict subset of F255's `[logging]` table: `level`/`format` defaults belong to R58's console pipeline (or are shared), while `file`/`file_level` and everything below are specific to this item.
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
- MEDIUM: How does "flag/env > config `logging.file` > off" precedence (F259) compose with R54's config-discovery-tiers answer and R58's pipeline initialization order — is the file sink initialized in a second pass after the config is fully resolved, or can it be wired in the same pass as the console sink?
- MEDIUM: What is the idiomatic Rust shape for "the root logger level is the minimum of the console and file sink levels" (F261, the dual-sink floor) in whatever subscriber model R58 adopts — is this automatic (each layer independently filters, so no floor computation is needed) or does it require an explicit combined-level computation at the dispatcher?
- LOW: Does py's default rotation policy (10 MiB per file, 5 backups) have an idiomatic Rust-crate default that differs meaningfully, and should this item's recommendation match py's numbers or a crate's own sane default?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). The divergence analysis marked this item harmonize: no; the owner asked for the cross-repo answer anyway, so answer it in full.

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
