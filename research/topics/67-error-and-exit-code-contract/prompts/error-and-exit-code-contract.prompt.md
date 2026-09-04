# Deep-research prompt — Error and exit-code contract (R67, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: the stable, append-only error-code catalog and exit-code taxonomy `rs-launch-blueprint` uses across its whole error/exit-code/signal-handling contract — covering the error-envelope "code" field's source, a structured `hint` field, the process-interrupt (Ctrl-C) exit-code contract, interactive-prompt-cancellation handling, broken-pipe (EPIPE) handling, and whether unexpected errors persist to a crash-log file. Item kind: `bundle`. Value test: if this answer is wrong, the domain error type(s), the error-code catalog, the exit-code enum and its mapping, the `SIGINT`/`SIGTERM`/EPIPE handlers, and the crash-log writer all get rewritten, and every downstream consumer of this item's `error-taxonomy-exit-codes` parameter (R03's absence/failure pattern, R52 through R56's config error handling, R70's domain-error-to-HTTP-status table) inherits a different set of error variants and codes.

## Context
- Inherited pattern (spec §2, presumption of reuse): py and ts diverge on the shape of the error-code catalog itself, and on every contract built on top of it. py's error "code" field is a stable, append-only, documented string catalog; ts's is the transient name of the thrown exception's class. Evidence: py `src/py_launch_blueprint/core/errors.py:51` — `ERROR_CODE_UNEXPECTED = "PLBP000"`, a stable string catalog; ts `src/router.ts:211` — `const code = err instanceof Error ? err.name : 'Error';`, a transient exception-class name. Ledger rows: F295, F296, F297, F298, F299, F300, F302 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F296 structured `hint` field — py `src/py_launch_blueprint/core/errors.py:76` — `self.hint = hint` (rendered separately at `src/py_launch_blueprint/cli/output.py:298`); ts: none (ts inlines remedy text directly into the error message instead, e.g. a `missingTokenMessage`). F297 exit-code taxonomy — py `src/py_launch_blueprint/core/errors.py:34` — `class ExitCode(IntEnum):` (`SUCCESS`/`CONFIG`/`AUTH`/`API`/`IO`/`INTERRUPT` = 0-5); ts `src/lib/errors.ts:13` — `export const EXIT_CODES = {` (`success`/`error`/`usage`/`notFound`/`auth`/`conflict`/`sigint`/`sigterm` = 0,1,2,3,4,5,130,143). F298 process-interrupt (Ctrl-C) exit-code contract — py `src/py_launch_blueprint/cli/options.py:215` — `except KeyboardInterrupt:` exits `ExitCode.INTERRUPT` (5); ts `src/cli.ts:21` — `process.on('SIGINT', () => {` exits 130; ts also handles `SIGTERM` separately (exit 143), which py does not. F299 interactive-prompt cancellation (^C mid-prompt) — py: none (py has no interactive multi-select to cancel); ts `src/router.ts:200` — `if (err instanceof Error && err.name === 'ExitPromptError') {`. F300 broken-pipe (EPIPE) handling — py: none; ts `src/cli.ts:17` — `process.stdout.on('error', ignoreEpipe);`, letting a downstream pipe reader (e.g. `head`) close early without a crash. F302 unexpected errors persisted to a crash-log file — py `src/py_launch_blueprint/cli/options.py:143` — `crash_path = paths.state_file("crash")`, best-effort append to `<state>/plbp/plbp_crash.log` (ADR 0006); ts: none.
- Already decided, do not re-open: that a JSON machine-readable error envelope exists on stderr (F294, `COMMON → REUSE`) is settled — py `src/py_launch_blueprint/cli/output.py:283` builds the `detail` dict inside `error()`; ts `src/router.ts:216` — `deps.stderr(\`${JSON.stringify({ error: { code, message: concise } })}\n\`);` — this item decides what populates the envelope's `code` field (F295) and the rest of this bundle, not whether the envelope itself exists. That an unexpected error's stack trace is shown to the user only under verbose/debug (F301, `COMMON → REUSE`) is also settled and out of scope. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — reconciled the source's 0/1/3/4 exit codes with an external cli-standards spec's R6.1 contract, adopting 0/1/2/3/4/5/130/143 (usage→2, missing-token/auth→4, workspace-not-found→3, API/network→1, unexpected→1, SIGINT→130, SIGTERM→143), plus an EPIPE handler and the R7.8 JSON error schema. D-018(4) — the machine-output envelope: stdout carries exactly one JSON document (the result), machine-mode errors are a single `{"error":{"code","message"}}` object on stderr, `--json` aliases `--format json`. D-033 — exit 130 on prompt interrupt/stdin-close with a clean message (no leaked library internals), implementing D-018(4)'s outstanding envelope requirement and guarding the spinner against 0-column TTYs.

## Out of scope
- Whether the driven-I/O seam splits "not found" from "transport failure" and where that becomes a domain error; R03 (`port-absence-vs-failure-contract`) owns that pattern — this item supplies the catalog entry and exit code R03's domain error eventually maps to, not the seam-level absence/failure split itself.
- The specific degrade-vs-fail behaviors for config loading (a missing `--config` path, an unparsable discovered layer, an invalid config value); R54 (`config-discovery-tiers`), R55 (`config-error-tolerance`), and R56 (`config-secret-policy`) own those behaviors — this item supplies the catalog entries and exit codes those behaviors map to, not the behaviors themselves.
- The domain-error-to-HTTP-status mapping table for the web surface; R70 (`http-problem-envelope`) owns that bundle — this item supplies the error variants R70 maps to HTTP statuses, not the mapping itself.
- Whether an interactive-prompt crate exists at all; R61 (`interactive-prompts`) owns that decision — F299's cancellation contract in this item is contingent on R61 adopting a crate, and does not apply if R61 declines.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R67
- owns: error-taxonomy-exit-codes
- consumes:
- related (not a registry dependency): R57 (`xdg-directory-set`) decides whether `rs-launch-blueprint` adopts a dedicated state/cache directory set beyond config; this item's crash-log file (F302) needs a location that answer would provide, but R57 registers no parameter this item formally consumes — treat the state-directory question as open, state the assumption made, and do not block on R57's answer. R61 (`interactive-prompts`) decides whether an interactive-prompt crate exists at all; F299 is contingent on R61's answer.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what stable, append-only error-code catalog and exit-code taxonomy `rs-launch-blueprint` adopts, covering the error-envelope code field, a structured hint field, the Ctrl-C interrupt contract, interactive-prompt cancellation, broken-pipe handling, and crash-log persistence — and how that becomes the `error-taxonomy-exit-codes` value other items consume.
- HIGH: Should the error-envelope `code` field be a stable, append-only string catalog (py's shape, e.g. `PLBP000`) or a value derived from a Rust error enum's variant/discriminant (a typed analogue of ts's exception-class-name shape) — and what crate (`thiserror`, `strum`) best expresses a stable, exhaustively-matchable catalog that downstream items (R03, R52-R56, R70) can pattern-match against?
- HIGH: What exit-code taxonomy should the template adopt — py's narrower `SUCCESS/CONFIG/AUTH/API/IO/INTERRUPT` (0-5), ts's cli-standards-reconciled `success/error/usage/notFound/auth/conflict/sigint/sigterm` (0,1,2,3,4,5,130,143), or a Rust-specific taxonomy — and what does each code mean for a Rust CLI's own error surface (parse errors, I/O errors, network errors, config errors)?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.
- MEDIUM: Should `rs-launch-blueprint` handle `SIGTERM` with its own exit code (143, ts's addition) in addition to `SIGINT` (130), or is py's SIGINT-only handling (exit 5) sufficient for a CLI template with no long-running daemon mode — and what is the idiomatic Rust mechanism for each (a signal-handling crate, or `std`-only)?
- MEDIUM: Should the template ship a structured `hint` field rendered separately from the error message (py's F296, `self.hint`) or inline remedy text into the message itself (ts's shape) — and does the answer depend on which output format (R66) renders the error?
- MEDIUM: If R61 adopts an interactive-prompt crate, what is the Rust-idiomatic way to detect prompt cancellation (^C mid-prompt, F299) and map it to a distinct exit code, mirroring ts's `ExitPromptError` detection — does the candidate prompt crate surface a typed cancellation error, or does the template need to catch a signal directly?
- MEDIUM: Does the template need broken-pipe (EPIPE) handling (F300) so a downstream pipe reader (e.g. `head`) can close early without the process crashing, and what is the idiomatic Rust mechanism, given Rust's default `SIGPIPE` disposition differs from Node's (checking `io::Error::kind() == ErrorKind::BrokenPipe` on writes, vs. installing a signal handler)?
- LOW: Should unexpected errors persist to a best-effort crash-log file (py's F302, ADR 0006), and if so, does its path depend on R57's (`xdg-directory-set`) eventual state/cache-directory answer, or can it default to a fixed location regardless of that outcome?

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
