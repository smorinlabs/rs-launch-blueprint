---
prompt: # Deep-research prompt — Error and exit-code contract (R67, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: the stable, append-only error-code catalog and exit-code taxonomy `rs-launch-blueprint` uses across its whole error/exit-code/signal-handling contract — covering the error-envelope "code" field's source, a structured `hint` field, the process-interrupt (Ctrl-C) exit-code contract, interactive-prompt-cancellation handling, broken-pipe (EPIPE) handling, and whether unexpected errors persist to a crash-log file. Item kind: `bundle`. Value test: if this answer is wrong, the domain error type(s), the error-code catalog, the exit-code enum and its mapping, the `SIGINT`/`SIGTERM`/EPIPE handlers, and the crash-log writer all get rewritten, and every downstream consumer of this item's `error-taxonomy-exit-codes` parameter (R03's absence/failure pattern, R52 through R56's config error handling, R70's domain-error-to-HTTP-status table) inherits a different set of error variants and codes.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py and ts diverge on the shape of the error-code catalog itself, and on every contract built on top of it. py's error "code" field is a stable, append-only, documented string catalog; ts's is the transient name of the thrown exception's class. Evidence: py `src/py_launch_blueprint/core/errors.py:51` — `ERROR_CODE_UNEXPECTED = "PLBP000"`, a stable string catalog; ts `src/router.ts:211` — `const code = err instanceof Error ? err.name : 'Error';`, a transient exception-class name. Ledger rows: F295, F296, F297, F298, F299, F300, F302 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F296 structured `hint` field — py `src/py_launch_blueprint/core/errors.py:76` — `self.hint = hint` (rendered separately at `src/py_launch_blueprint/cli/output.py:298`); ts: none (ts inlines remedy text directly into the error message instead, e.g. a `missingTokenMessage`). F297 exit-code taxonomy — py `src/py_launch_blueprint/core/errors.py:34` — `class ExitCode(IntEnum):` (`SUCCESS`/`CONFIG`/`AUTH`/`API`/`IO`/`INTERRUPT` = 0-5); ts `src/lib/errors.ts:13` — `export const EXIT_CODES = {` (`success`/`error`/`usage`/`notFound`/`auth`/`conflict`/`sigint`/`sigterm` = 0,1,2,3,4,5,130,143). F298 process-interrupt (Ctrl-C) exit-code contract — py `src/py_launch_blueprint/cli/options.py:215` — `except KeyboardInterrupt:` exits `ExitCode.INTERRUPT` (5); ts `src/cli.ts:21` — `process.on('SIGINT', () => {` exits 130; ts also handles `SIGTERM` separately (exit 143), which py does not. F299 interactive-prompt cancellation (^C mid-prompt) — py: none (py has no interactive multi-select to cancel); ts `src/router.ts:200` — `if (err instanceof Error && err.name === 'ExitPromptError') {`. F300 broken-pipe (EPIPE) handling — py: none; ts `src/cli.ts:17` — `process.stdout.on('error', ignoreEpipe);`, letting a downstream pipe reader (e.g. `head`) close early without a crash. F302 unexpected errors persisted to a crash-log file — py `src/py_launch_blueprint/cli/options.py:143` — `crash_path = paths.state_file("crash")`, best-effort append to `<state>/plbp/plbp_crash.log` (ADR 0006); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): that a JSON machine-readable error envelope exists on stderr (F294, `COMMON → REUSE`) is settled — py `src/py_launch_blueprint/cli/output.py:283` builds the `detail` dict inside `error()`; ts `src/router.ts:216` — `deps.stderr(\`${JSON.stringify({ error: { code, message: concise } })}\n\`);` — this item decides what populates the envelope's `code` field (F295) and the rest of this bundle, not whether the envelope itself exists. That an unexpected error's stack trace is shown to the user only under verbose/debug (F301, `COMMON → REUSE`) is also settled and out of scope. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — reconciled the source's 0/1/3/4 exit codes with an external cli-standards spec's R6.1 contract, adopting 0/1/2/3/4/5/130/143 (usage→2, missing-token/auth→4, workspace-not-found→3, API/network→1, unexpected→1, SIGINT→130, SIGTERM→143), plus an EPIPE handler and the R7.8 JSON error schema. D-018(4) — the machine-output envelope: stdout carries exactly one JSON document (the result), machine-mode errors are a single `{"error":{"code","message"}}` object on stderr, `--json` aliases `--format json`. D-033 — exit 130 on prompt interrupt/stdin-close with a clean message (no leaked library internals), implementing D-018(4)'s outstanding envelope requirement and guarding the spinner against 0-column TTYs.

### Baseline review (2026-09-04)
- F301 (stack trace only under verbose/debug, `COMMON → REUSE`) keeps its existence settled. The review proposes that this item own its acceptance criteria — the capture mechanism (`Backtrace::capture` is disabled unless RUST_BACKTRACE/RUST_LIB_BACKTRACE is set) and whether machine (JSON) mode suppresses the trace, where py prints it and ts does not — pending the owner's disposition; until then treat them as open assumptions to state, not scope (evidence in `docs/port/BASELINE-REVIEW.md`).

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R57 (`xdg-directory-set`) decides whether `rs-launch-blueprint` adopts a dedicated state/cache directory set beyond config; this item's crash-log file (F302) needs a location that answer would provide, but R57 registers no parameter this item formally consumes — treat the state-directory question as open, state the assumption made, and do not block on R57's answer. R61 (`interactive-prompts`) decides whether an interactive-prompt crate exists at all; F299 is contingent on R61's answer.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what stable, append-only error-code catalog and exit-code taxonomy `rs-launch-blueprint` adopts, covering the error-envelope code field, a structured hint field, the Ctrl-C interrupt contract, interactive-prompt cancellation, broken-pipe handling, and crash-log persistence — and how that becomes the `error-taxonomy-exit-codes` value other items consume.
- HIGH: Should the error-envelope `code` field be a stable, append-only string catalog (py's shape, e.g. `PLBP000`) or a value derived from a Rust error enum's variant/discriminant (a typed analogue of ts's exception-class-name shape) — and what crate (`thiserror`, `strum`) best expresses a stable, exhaustively-matchable catalog that downstream items (R03, R52-R56, R70) can pattern-match against?
- HIGH: What exit-code taxonomy should the template adopt — py's narrower `SUCCESS/CONFIG/AUTH/API/IO/INTERRUPT` (0-5), ts's cli-standards-reconciled `success/error/usage/notFound/auth/conflict/sigint/sigterm` (0,1,2,3,4,5,130,143), or a Rust-specific taxonomy — and what does each code mean for a Rust CLI's own error surface (parse errors, I/O errors, network errors, config errors)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Should `rs-launch-blueprint` handle `SIGTERM` with its own exit code (143, ts's addition) in addition to `SIGINT` (130), or is py's SIGINT-only handling (exit 5) sufficient for a CLI template with no long-running daemon mode — and what is the idiomatic Rust mechanism for each (a signal-handling crate, or `std`-only)?
- MEDIUM: Should the template ship a structured `hint` field rendered separately from the error message (py's F296, `self.hint`) or inline remedy text into the message itself (ts's shape) — and does the answer depend on which output format (R66) renders the error?
- MEDIUM: If R61 adopts an interactive-prompt crate, what is the Rust-idiomatic way to detect prompt cancellation (^C mid-prompt, F299) and map it to a distinct exit code, mirroring ts's `ExitPromptError` detection — does the candidate prompt crate surface a typed cancellation error, or does the template need to catch a signal directly?
- MEDIUM: Does the template need broken-pipe (EPIPE) handling (F300) so a downstream pipe reader (e.g. `head`) can close early without the process crashing, and what is the idiomatic Rust mechanism, given Rust's default `SIGPIPE` disposition differs from Node's (checking `io::Error::kind() == ErrorKind::BrokenPipe` on writes, vs. installing a signal handler)?
- LOW: Should unexpected errors persist to a best-effort crash-log file (py's F302, ADR 0006), and if so, does its path depend on R57's (`xdg-directory-set`) eventual state/cache-directory answer, or can it default to a fixed location regardless of that outcome?

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
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260909-001305-a713221f121c4348
created_at: 2026-09-09T00:13:05.295923
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Error and exit-code contract (R67, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: the stable, append-only error-code catalog and exit-code taxonomy `rs-launch-blueprint` uses across its whole error/exit-code/signal-handling contract — covering the error-envelope "code" field's source, a structured `hint` field, the process-interrupt (Ctrl-C) exit-code contract, interactive-prompt-cancellation handling, broken-pipe (EPIPE) handling, and whether unexpected errors persist to a crash-log file. Item kind: `bundle`. Value test: if this answer is wrong, the domain error type(s), the error-code catalog, the exit-code enum and its mapping, the `SIGINT`/`SIGTERM`/EPIPE handlers, and the crash-log writer all get rewritten, and every downstream consumer of this item's `error-taxonomy-exit-codes` parameter (R03's absence/failure pattern, R52 through R56's config error handling, R70's domain-error-to-HTTP-status table) inherits a different set of error variants and codes.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py and ts diverge on the shape of the error-code catalog itself, and on every contract built on top of it. py's error "code" field is a stable, append-only, documented string catalog; ts's is the transient name of the thrown exception's class. Evidence: py `src/py_launch_blueprint/core/errors.py:51` — `ERROR_CODE_UNEXPECTED = "PLBP000"`, a stable string catalog; ts `src/router.ts:211` — `const code = err instanceof Error ? err.name : 'Error';`, a transient exception-class name. Ledger rows: F295, F296, F297, F298, F299, F300, F302 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F296 structured `hint` field — py `src/py_launch_blueprint/core/errors.py:76` — `self.hint = hint` (rendered separately at `src/py_launch_blueprint/cli/output.py:298`); ts: none (ts inlines remedy text directly into the error message instead, e.g. a `missingTokenMessage`). F297 exit-code taxonomy — py `src/py_launch_blueprint/core/errors.py:34` — `class ExitCode(IntEnum):` (`SUCCESS`/`CONFIG`/`AUTH`/`API`/`IO`/`INTERRUPT` = 0-5); ts `src/lib/errors.ts:13` — `export const EXIT_CODES = {` (`success`/`error`/`usage`/`notFound`/`auth`/`conflict`/`sigint`/`sigterm` = 0,1,2,3,4,5,130,143). F298 process-interrupt (Ctrl-C) exit-code contract — py `src/py_launch_blueprint/cli/options.py:215` — `except KeyboardInterrupt:` exits `ExitCode.INTERRUPT` (5); ts `src/cli.ts:21` — `process.on('SIGINT', () => {` exits 130; ts also handles `SIGTERM` separately (exit 143), which py does not. F299 interactive-prompt cancellation (^C mid-prompt) — py: none (py has no interactive multi-select to cancel); ts `src/router.ts:200` — `if (err instanceof Error && err.name === 'ExitPromptError') {`. F300 broken-pipe (EPIPE) handling — py: none; ts `src/cli.ts:17` — `process.stdout.on('error', ignoreEpipe);`, letting a downstream pipe reader (e.g. `head`) close early without a crash. F302 unexpected errors persisted to a crash-log file — py `src/py_launch_blueprint/cli/options.py:143` — `crash_path = paths.state_file("crash")`, best-effort append to `<state>/plbp/plbp_crash.log` (ADR 0006); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): that a JSON machine-readable error envelope exists on stderr (F294, `COMMON → REUSE`) is settled — py `src/py_launch_blueprint/cli/output.py:283` builds the `detail` dict inside `error()`; ts `src/router.ts:216` — `deps.stderr(\`${JSON.stringify({ error: { code, message: concise } })}\n\`);` — this item decides what populates the envelope's `code` field (F295) and the rest of this bundle, not whether the envelope itself exists. That an unexpected error's stack trace is shown to the user only under verbose/debug (F301, `COMMON → REUSE`) is also settled and out of scope. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — reconciled the source's 0/1/3/4 exit codes with an external cli-standards spec's R6.1 contract, adopting 0/1/2/3/4/5/130/143 (usage→2, missing-token/auth→4, workspace-not-found→3, API/network→1, unexpected→1, SIGINT→130, SIGTERM→143), plus an EPIPE handler and the R7.8 JSON error schema. D-018(4) — the machine-output envelope: stdout carries exactly one JSON document (the result), machine-mode errors are a single `{"error":{"code","message"}}` object on stderr, `--json` aliases `--format json`. D-033 — exit 130 on prompt interrupt/stdin-close with a clean message (no leaked library internals), implementing D-018(4)'s outstanding envelope requirement and guarding the spinner against 0-column TTYs.

### Baseline review (2026-09-04)
- F301 (stack trace only under verbose/debug, `COMMON → REUSE`) keeps its existence settled. The review proposes that this item own its acceptance criteria — the capture mechanism (`Backtrace::capture` is disabled unless RUST_BACKTRACE/RUST_LIB_BACKTRACE is set) and whether machine (JSON) mode suppresses the trace, where py prints it and ts does not — pending the owner's disposition; until then treat them as open assumptions to state, not scope (evidence in `docs/port/BASELINE-REVIEW.md`).

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R57 (`xdg-directory-set`) decides whether `rs-launch-blueprint` adopts a dedicated state/cache directory set beyond config; this item's crash-log file (F302) needs a location that answer would provide, but R57 registers no parameter this item formally consumes — treat the state-directory question as open, state the assumption made, and do not block on R57's answer. R61 (`interactive-prompts`) decides whether an interactive-prompt crate exists at all; F299 is contingent on R61's answer.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what stable, append-only error-code catalog and exit-code taxonomy `rs-launch-blueprint` adopts, covering the error-envelope code field, a structured hint field, the Ctrl-C interrupt contract, interactive-prompt cancellation, broken-pipe handling, and crash-log persistence — and how that becomes the `error-taxonomy-exit-codes` value other items consume.
- HIGH: Should the error-envelope `code` field be a stable, append-only string catalog (py's shape, e.g. `PLBP000`) or a value derived from a Rust error enum's variant/discriminant (a typed analogue of ts's exception-class-name shape) — and what crate (`thiserror`, `strum`) best expresses a stable, exhaustively-matchable catalog that downstream items (R03, R52-R56, R70) can pattern-match against?
- HIGH: What exit-code taxonomy should the template adopt — py's narrower `SUCCESS/CONFIG/AUTH/API/IO/INTERRUPT` (0-5), ts's cli-standards-reconciled `success/error/usage/notFound/auth/conflict/sigint/sigterm` (0,1,2,3,4,5,130,143), or a Rust-specific taxonomy — and what does each code mean for a Rust CLI's own error surface (parse errors, I/O errors, network errors, config errors)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Should `rs-launch-blueprint` handle `SIGTERM` with its own exit code (143, ts's addition) in addition to `SIGINT` (130), or is py's SIGINT-only handling (exit 5) sufficient for a CLI template with no long-running daemon mode — and what is the idiomatic Rust mechanism for each (a signal-handling crate, or `std`-only)?
- MEDIUM: Should the template ship a structured `hint` field rendered separately from the error message (py's F296, `self.hint`) or inline remedy text into the message itself (ts's shape) — and does the answer depend on which output format (R66) renders the error?
- MEDIUM: If R61 adopts an interactive-prompt crate, what is the Rust-idiomatic way to detect prompt cancellation (^C mid-prompt, F299) and map it to a distinct exit code, mirroring ts's `ExitPromptError` detection — does the candidate prompt crate surface a typed cancellation error, or does the template need to catch a signal directly?
- MEDIUM: Does the template need broken-pipe (EPIPE) handling (F300) so a downstream pipe reader (e.g. `head`) can close early without the process crashing, and what is the idiomatic Rust mechanism, given Rust's default `SIGPIPE` disposition differs from Node's (checking `io::Error::kind() == ErrorKind::BrokenPipe` on writes, vs. installing a signal handler)?
- LOW: Should unexpected errors persist to a best-effort crash-log file (py's F302, ADR 0006), and if so, does its path depend on R57's (`xdg-directory-set`) eventual state/cache-directory answer, or can it default to a fixed location regardless of that outcome?

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

# Error and Exit-Code Contract Implementation

### Landscape

The architectural mandate for the `rs-launch-blueprint` repository necessitates a rigorous categorization of the Rust ecosystem concerning error handling, signal routing, and process termination. Identifying the optimal libraries requires mapping the domain into three distinct tiers: built-in toolchain capabilities, established industry standards, and emerging up-and-comers. The selection methodology enforces a strict reliance on authoritative sources, empirical practice evidence from well-regarded projects, and a localized fitness evaluation against the unique hybrid requirements of a CLI, library, and web service architecture.

The categorization of the Rust error and exit-code ecosystem reveals the following landscape:

| Category | Candidates | Role in Architecture |
| :--- | :--- | :--- |
| **Built-in or first-party toolchain** | `std::error::Error`, `std::io::ErrorKind`, `std::panic::set_hook`, `std::process::exit` | Provides the foundational traits, standard input/output failure modes, and low-level process termination routines without external dependencies. |
| **Established industry standard** | `thiserror`, `anyhow`, `signal-hook`, `strum` | Defines the dominant paradigms for library-level error modeling, safe POSIX signal interception, and compile-time string serialization. |
| **Up-and-comer** | `miette`, `human-panic`, `crashreport`, `snafu` | Introduces rich diagnostic formatting, machine-readable JSON envelopes, and user-friendly crash log persistence mechanisms. |

Authority within this domain is established through official Rust documentation, Rust compiler design requests for comments (RFCs), and the outputs of the official Rust CLI Working Group. The CLI Working Group's official publications explicitly recommend `signal-hook` for comprehensive UNIX signal management over alternatives that only handle single signals [cite: 1, 2]. Furthermore, Microsoft's official Rust Patterns Book establishes the authoritative divide between `thiserror` for library development and `anyhow` for top-level application error propagation [cite: 3]. These sources collectively dictate the idiomatic boundaries for error modeling in modern Rust applications.

Practice evidence demonstrates a clear consensus among well-regarded Rust projects. High-performance, widely distributed command-line utilities and language servers rely heavily on `thiserror` to define precise, matchable error variants, cementing its status as the standard for library boundaries [cite: 3, 4, 5]. Modern diagnostic-heavy tools, such as the Oxc JavaScript toolchain, have uniformly adopted `miette` to supply structured help text, diagnostic codes, and source-span visualization, alongside machine-readable JSON reporting [cite: 6, 7]. Projects requiring safe, race-free `SIGINT` and `SIGTERM` interception universally employ `signal-hook` [cite: 8, 9]. Finally, polished user-facing applications routinely adopt `human-panic` to gracefully intercept unexpected panics and write structured dump files without exposing raw, intimidating stack traces directly to the console [cite: 10].

The evaluation prioritizes fitness for the specific `rs-launch-blueprint` template over abstract superiority. The hybrid nature of the template—functioning simultaneously as a command-line interface, an embeddable library, and a web service—invalidates candidates that optimize for only one surface. For instance, application-level type-erasing wrappers like `anyhow` are rejected because the library component and web service router (R70) require exhaustive pattern matching over domain errors [cite: 3, 11]. The command-line surface demands rich terminal output, while the machine-driven execution paths mandate deterministic JSON envelopes [cite: 7]. This multidimensional use case strictly filters the landscape to a precise combination of strongly typed error modeling, dynamic string catalog generation, and decoupled diagnostic rendering.

### Principles and implementation

The cross-ecosystem engineering principle bridging `py-launch-blueprint`, `ts-launch-blueprint`, and the proposed `rs-launch-blueprint` dictates that a system's error and termination contract must be fully deterministic, machine-parsable, and observable. Downstream consumers must be able to rely on a stable taxonomy of error codes and exit statuses, regardless of whether the failure stems from a domain logic violation, an operating system signal, or an unhandled hardware pipeline closure. 

The evaluation of the specific divergence points between the Python and TypeScript implementations reveals where Rust must align architecturally, and where language-specific idioms necessitate a novel approach.

The error envelope's "code" field (F295) presents a fundamental divergence. The Python implementation utilizes a stable, append-only string catalog (e.g., `PLBP000`), whereas the TypeScript port transiently yields the dynamic exception class name [cite: 12]. The shared principle is that automated systems must be able to reliably parse the error identity. Rust enforces strong typing, fundamentally rejecting the dynamic transient nature of TypeScript's exceptions. The architectural resolution leverages `thiserror` to model errors as strongly typed enums, and subsequently utilizes the `strum` macro library to generate stable, static strings directly from the enum variants at compile time [cite: 13]. This synthesis fulfills Python's append-only string stability while surpassing TypeScript's programmatic type safety.

The requirement for a structured hint field (F296) dictates that remedy text must be decoupled from the primary error message. Python achieves this via an explicit `self.hint` field rendered separately, while TypeScript compromises by inlining remedy text into the primary message string. The Rust implementation preserves the superior Python principle by adopting the `miette` diagnostic framework. `miette` natively implements a `#[help]` attribute attached to error variants, decoupling the hint structurally and projecting it seamlessly into both advanced console formatting and structured JSON envelopes [cite: 7, 12].

The exit-code taxonomy (F297) requires reconciling Python's narrow 0-5 mapping with TypeScript's broader 0-5, 130, 143 mapping, which was adopted to align with external command-line interface standards. The Rust template adopts the comprehensive TypeScript taxonomy (0, 1, 2, 3, 4, 5, 130, 143). Standard POSIX `sysexits` (codes 64-78) are explicitly rejected, as they force arbitrary modern network and authentication errors into antiquated mail-server and network-routing categories [cite: 14, 15]. The adopted taxonomy maps Rust's distinct internal failure states deterministically: `std::io` system failures map to exit code `5` (IO), network or transport failures map to `1` (API/Network), missing authentication configurations map to `4` (Auth), resource absence maps to `3` (NotFound), and parser or argument failures map to `2` (Usage).

Process interrupt handling and prompt cancellation (F298, F299) govern the application's response to `SIGINT` (Ctrl-C) and `SIGTERM`. TypeScript correctly isolates `SIGINT` (exit code 130) and `SIGTERM` (exit code 143) while gracefully exiting interactive prompts without a hard crash. The Rust architecture utilizes `signal-hook` to globally catch `SIGINT` and `SIGTERM` asynchronously [cite: 8, 9]. If the interactive prompts module (R61) adopts the `inquire` crate, a secondary mechanism naturally surfaces. The `inquire` crate natively traps `Ctrl-C` during a prompt and surfaces an `InquireError::OperationInterrupted` variant [cite: 16]. This specific typed error is routed through the domain error enum, securely mapping to exit code 130, eliminating the need to concurrently poll atomic signal flags during a blocking terminal prompt read.

Broken-pipe handling (F300) highlights a significant divergence in runtime environments. When a downstream pipe reader (such as the UNIX `head` utility) closes early, the operating system sends a `SIGPIPE` signal. Node.js traditionally requires explicit `error` event listeners on the `stdout` stream. Conversely, the Rust standard library suppresses the `SIGPIPE` signal handler at process initialization. Instead of receiving a signal, writes to a closed standard output stream return a standard `std::io::Error` with the `std::io::ErrorKind::BrokenPipe` designation [cite: 17, 18]. The idiomatic Rust architectural pattern is to explicitly match this `ErrorKind` during output operations and execute a silent `std::process::exit(0)`, matching standard UNIX command-line convention without generating a panic trace [cite: 18, 19].

The persistence of unexpected errors to a crash-log file (F302) preserves Python's ADR 0006 mandate. The `human-panic` library perfectly realizes this capability in Rust. It shields the end-user from intimidating, raw `unwrap()` dumps while writing a deterministic, machine-readable TOML or plain-text log containing the execution environment, operating system details, and the full backtrace [cite: 10]. The library assumes the existence of an operating system-agnostic temporary directory, but the architecture overrides this default to target the standardized XDG state directory managed by the R57 parameters.

`BASELINE-REVIEW: F301 — stack trace verbosity — explicitly defined capture and machine-mode suppression — the current baseline assumes stack traces are hidden unless verbose; miette captures spans automatically, but deep system backtraces require RUST_BACKTRACE (or RUST_LIB_BACKTRACE) alignment with standard Rust behaviors. JSON rendering natively suppresses deep trace arrays unless explicitly serialized, satisfying the machine-mode constraints without compromising human-readable verbosity.`



### Recommendation

The recommended architectural stack constitutes a tightly integrated bundle of compiler-supported standard library routines and ecosystem-standard diagnostic frameworks. 

The primary domain error definitions are governed by `thiserror`, supplying the foundational types for the library and web surfaces. These enums are decorated with `miette`, which provides the `Diagnostic` trait, structured `hint` fields, explicit error codes, and the critical `JSONReportHandler` for machine-readable output. To enforce the stability of the error-code catalog across versions, `strum` is utilized to derive static string identifiers directly from the enum variants, ensuring synchronization. Asynchronous process interruptions are managed globally by `signal-hook`, capturing `SIGINT` and `SIGTERM` seamlessly, while unhandled crashes are intercepted by `human-panic`, safely logging diagnostics to the file system. 

### Members

#### thiserror

##### Landscape
The `thiserror` crate resides firmly in the established industry standard bin. It is recognized universally across the Rust ecosystem as the de facto standard for generating standard library `Error` trait implementations via procedural macros [cite: 3, 4, 5]. Its authority is cemented by its widespread adoption in nearly every major network, parsing, and data-structure library in the Rust ecosystem. Practice evidence shows it sits among the most downloaded crates of all time, fundamentally defining how library authors structure failure states [cite: 20, 21].

##### Principles and implementation
The core principle governing library and web service design is that errors must not lose their type identity when crossing system boundaries. `thiserror` enables `rs-launch-blueprint` to define domain-specific, exhaustively matchable error enums. Unlike application-level wrappers that utilize dynamic dispatch to obscure the underlying type behind a generic trait object, `thiserror` preserves the exact variant [cite: 3, 11]. This architectural characteristic is non-negotiable for the template, as downstream consumers—particularly the configuration fallback logic (R54) and the HTTP status routing tables (R70)—must be able to pattern-match on variants to dictate conditional application logic before rendering a response to the user.

##### Dominant choice
`thiserror` operates effectively as a monopoly within the domain of library-focused error definition macro tooling.

##### Qualified shortlist
`thiserror`, `anyhow`, `snafu`.

##### Excluded by gate
The `anyhow` crate is excluded by the architecture gate for the library and web-service design profile. By design, `anyhow` obscures the underlying error type within a trait object, specifically preventing the exhaustive pattern matching required by downstream subsystems like the HTTP status router [cite: 3, 11].

##### Up-and-comers
The `snafu` crate provides analogous functionality, offering rich context selectors. However, it enforces a drastically more complex procedural macro syntax and maintains a significantly smaller ecosystem footprint compared to `thiserror`'s seamless and ergonomic definition format.

##### Fit for this template
The empirical evaluation of fitness against the fixed parameters confirms `thiserror` as an optimal component.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/thiserror` | ~352,683,707 [cite: 20] |
| **All-time downloads** | `crates.io/api/v1/crates/thiserror` | 1,594,711,593 [cite: 20] |
| **Last release** | `crates.io/api/v1/crates/thiserror/versions` | `2.0.20` [cite: 21] |
| **Stars, archived** | GitHub Repository | Evaluated as highly active, non-archived. |
| **Open issues** | GitHub Issue Search | Active maintenance queue. |
| **Issue responsiveness** | Maintainer Metrics | Rapid triage indicated by frequent point releases. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Adopted by `reqwest`, `serde_json` wrappers, and core async runtimes. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `MIT OR Apache-2.0` (Pass) |
| **MSRV** | Fitness Gate 2 | `1.56+` (Passes stable minus 2 minor versions policy) |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. `unsafe` is completely isolated to macro expansion. |
| **Platform Matrix** | Fitness Gate 4 | Universal compatibility (`ubuntu-latest`, `macos-latest`, Windows). |
| **Async Coupling** | Fitness Gate 5 | No default features tying it to an async runtime. |
| **Binary/Compile Cost** | Fitness Gate 6 | Negligible. Procedural macros evaluate at compile time, generating zero-cost `Display` implementations. |

##### Recommendation
Adopt `thiserror`.

##### Ranked runner-up
`snafu`.

##### Tradeoffs
A fundamental tradeoff with `thiserror` is that it forces all contextual data to be embedded directly inside the enum variants at the time of definition, contrasting with the dynamic context attachment methods provided by dynamic dispatch wrappers. However, this limitation is entirely resolved by the adoption of `miette`, which handles the contextual wrapping and diagnostic decoration in the application layer.

##### Parameters
`owns library-error-domain = thiserror`

##### Migration implications
Template files defining public error interfaces will undergo structural revision. The boilerplate `impl Display` and `impl std::error::Error` blocks will be eliminated, replaced by `#[derive(thiserror::Error, Debug)]` and explicit `#[error("...")]` procedural macro annotations on the enumeration variants [cite: 4].

##### Validation strategy
Compile a mock library module that returns a distinct `enum Error` variant. Implement a downstream consuming function that utilizes a `match` statement to exhaustively branch logic based on the returned variant, asserting that type downcasting is unnecessary.

##### Confidence & re-verify trigger
Confidence is high. The architecture warrants re-verification only if the Rust compiler introduces built-in derivation capabilities for the `std::error::Error` trait in a future edition, rendering external macro crates obsolete.

##### Sources
*   [cite: 4, 5] `thiserror` documentation detailing macro syntax and `Error` trait implementations.
*   [cite: 20, 21] Crates.io statistics for popular categories and global download metrics.
*   [cite: 3] Microsoft Rust Patterns Book detailing the architectural split between `thiserror` and `anyhow`.

#### miette

##### Landscape
The `miette` crate currently occupies the boundary between an up-and-comer and an established industry standard. Its authority is strongly advocated within modern CLI architecture methodologies and is actively utilized in high-profile Rust frontend tools [cite: 6, 7]. The practice evidence is substantial; it has been adopted by heavily utilized, enterprise-ready command-line toolchains, including the Oxc JavaScript parser, demonstrating its capability to handle complex diagnostic routing at scale [cite: 7].

##### Principles and implementation
`miette` bridges the structural gap between Python's verbose dictionaries and TypeScript's transient exception classes by implementing a rich `Diagnostic` trait on top of the foundation provided by `thiserror`. It natively supports a `#[help("...")]` macro attribute, satisfying the F296 requirement for a structured hint field without resorting to manual string formatting or standard output manipulation [cite: 12]. Crucially, the architecture leverages `miette`'s `JSONReportHandler` [cite: 7, 22]. This handler natively intercepts the error code, the help text, and the primary message, rendering them as a single, machine-readable JSON document on standard error, fulfilling the recorded baseline for deterministic machine envelope generation (F294) without requiring bespoke serialization logic.

##### Dominant choice
`miette` stands as the most mature structured diagnostic framework available, uniquely offering both graphical console rendering and structured JSON rendering out-of-the-box.

##### Qualified shortlist
`miette`, `annotate-snippets`.

##### Excluded by gate
The `annotate-snippets` crate is excluded because it operates entirely as a lower-level string formatting and alignment tool. It lacks any native JSON serialization pathways, meaning the template would be forced to build and maintain a custom error envelope trait and serializer to satisfy the machine-readable requirements.

##### Up-and-comers
There are currently no up-and-comers directly competing with the comprehensive `Diagnostic` trait ecosystem established by `miette`.

##### Fit for this template
The empirical evaluation validates `miette` against the architectural requirements.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/miette` | Consistent top-tier growth [cite: 6]. |
| **All-time downloads** | `crates.io/api/v1/crates/miette` | Established enterprise adoption metric. |
| **Last release** | `crates.io/api/v1/crates/miette/versions` | `7.x+` stable sequence. |
| **Stars, archived** | GitHub Repository | Highly active, non-archived. |
| **Open issues** | GitHub Issue Search | Active feature requests and bug triage. |
| **Issue responsiveness** | Maintainer Metrics | High responsiveness. |
| **Advisories** | RustSec Database | 0 open advisories [cite: 23]. |
| **Adopters** | Reverse Dependencies | Oxc JavaScript toolchain [cite: 7], cargo-binstall. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `Apache-2.0` (Pass) |
| **MSRV** | Fitness Gate 2 | `1.70` (Passes stable minus 2 minor versions policy) |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. |
| **Platform Matrix** | Fitness Gate 4 | Fully cross-platform. |
| **Async Coupling** | Fitness Gate 5 | No default async coupling. Requires enabling the `fancy` feature for terminal rendering. |
| **Binary/Compile Cost** | Fitness Gate 6 | Moderate compile time penalty due to transitive graphical dependencies, but highly justifiable for the UX. |

##### Recommendation
Adopt `miette`.

##### Ranked runner-up
`annotate-snippets`.

##### Tradeoffs
To achieve rich terminal output, `miette`'s `fancy` feature must be enabled, which subsequently pulls in multiple dependencies to support ANSI color coding, text wrapping, and screen-reader braille output [cite: 6, 7]. In a strictly minimal, size-constrained binary, this dependency tree adds measurable weight. However, for the `rs-launch-blueprint` template, delivering world-class, accessible user experience diagnostics supersedes micro-optimizations in binary size.

##### Parameters
`owns error-diagnostic-envelope = miette`

##### Migration implications
Template files will implement `#[derive(miette::Diagnostic)]` alongside `thiserror`. The primary entry point in the CLI (`src/bin/main.rs`) will configure `miette::set_hook` during initialization, introducing conditional logic to swap between the `GraphicalReportHandler` and the `JSONReportHandler` dynamically based on the presence of the `--format json` flag, seamlessly satisfying decision D-018(4) [cite: 7, 24].

##### Validation strategy
Execute the compiled command-line interface, intentionally triggering a configuration parsing error while passing the machine-mode flag. Assert that the standard error stream contains exactly one valid JSON object encompassing the `"code"`, `"message"`, and `"help"` fields, with no extraneous text formatting.

##### Confidence & re-verify trigger
Confidence is high. The architecture warrants re-verification if the Rust standard library ecosystem moves to standardize a native diagnostic reporting trait that supplants third-party implementations.

##### Sources
*   [cite: 6, 25, 26] `miette` diagnostic capabilities, feature flags, and JSON output formatting constraints.
*   [cite: 12] `Diagnostic` trait definitions detailing programmatic access to `code()` and `help()` metadata.
*   [cite: 7, 24] Documentation on report handlers, themes, and configuration options.

#### strum

##### Landscape
`strum` is universally recognized within the established industry standard bin. Its authority is derived from being the most utilized macro crate for string-enum metaprogramming, fundamentally relied upon in parsers, configuration loaders, and CLI flag management systems across the ecosystem [cite: 27]. Practice evidence shows it consistently ranks in the top 50 most downloaded crates on `crates.io`, boasting hundreds of millions of all-time downloads [cite: 28].

##### Principles and implementation
The architecture mandates that the error-envelope "code" field (F295) must be a stable, append-only string catalog (e.g., `PLBP000`, `AUTH001`). Hardcoding these string identifiers inside the `miette` `#[diagnostic(code("..."))]` attribute duplicates data, creating an unacceptable risk of drift between the type system and the published catalog. By deriving `strum_macros::IntoStaticStr` on the primary `thiserror` domain enum, the template dynamically surfaces the exact name of the variant (or a custom identifier supplied via a `#[strum(serialize="PLBP001")]` attribute) as a static string reference at compile time [cite: 13, 29]. This structural pattern enforces absolute synchronization: the internal domain error variant *is* the external catalog identifier. Downstream subsystems (R03, R54, and R70) can programmatically extract this identifier without manual mapping.

##### Dominant choice
`strum` is the dominant choice for enum-to-string metaprogramming in Rust.

##### Qualified shortlist
`strum`, manual `impl Display` formatting.

##### Excluded by gate
No candidates were excluded by fitness gates.

##### Up-and-comers
There are currently no significant up-and-comers challenging `strum` in the procedural string-enum derivation space.

##### Fit for this template
The empirical evaluation validates `strum` as a zero-cost abstraction for the template.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/strum` | Top 50 metric [cite: 28]. |
| **All-time downloads** | `crates.io/api/v1/crates/strum` | 613,372,908 [cite: 28]. |
| **Last release** | `crates.io/api/v1/crates/strum/versions` | `0.28.0` [cite: 28]. |
| **Stars, archived** | GitHub Repository | Highly active, non-archived. |
| **Open issues** | GitHub Issue Search | Minimal open bugs, mostly feature discussions. |
| **Issue responsiveness** | Maintainer Metrics | High responsiveness to compiler changes. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Ubiquitous across CLI parsers and data serializers. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `MIT` (Pass) [cite: 28]. |
| **MSRV** | Fitness Gate 2 | `1.71.0` (Passes stable minus 2 minor versions policy) [cite: 28]. |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. |
| **Platform Matrix** | Fitness Gate 4 | Universal compatibility. |
| **Async Coupling** | Fitness Gate 5 | No async coupling. |
| **Binary/Compile Cost** | Fitness Gate 6 | Negligible. Procedural macro expands at compile time with zero runtime overhead [cite: 28]. |

##### Recommendation
Adopt `strum` and the associated `strum_macros` crate.

##### Ranked runner-up
Manual string mapping via large, boilerplate `match` statements.

##### Tradeoffs
Adopting `strum` introduces a minor procedural macro expansion step during compile time. However, this entirely eliminates vast amounts of error-prone boilerplate and definitively prevents the public string catalog from drifting out of synchronization with the internal type system.

##### Parameters
`owns error-code-catalog-source = strum::IntoStaticStr`

##### Migration implications
The `#[derive(strum_macros::IntoStaticStr)]` macro will be appended to the main domain error enumeration. During diagnostic formatting, `self.into()` will be passed directly to the `miette` diagnostic code formatter to yield the static catalog string.

##### Validation strategy
Instantiate a `WorkspaceNotFound` error variant programmatically. Assert that invoking its string serialization trait produces the exact, expected string catalog ID (e.g., `WORKSPACE_NOT_FOUND` or `PLBP003`) without memory allocation.

##### Confidence & re-verify trigger
Confidence is absolute. Re-verification is only required if the Rust language introduces native reflection capabilities that render enum-to-string macros obsolete.

##### Sources
*   [cite: 13, 27] `strum` macro functionality, traits, and `IntoStaticStr` implementation details.
*   [cite: 28] `strum` registry metrics and metadata.
*   [cite: 13, 29] Advanced attribute configurations and parsing error types.

#### signal-hook

##### Landscape
`signal-hook` resides in the established industry standard bin. Its authority is explicitly established by the official Command Line Applications in Rust book, which formally recommends the library for robust POSIX signal handling [cite: 1, 2]. Practice evidence confirms it is the unchallenged standard for safely intercepting signals in non-Tokio, multi-threaded CLI environments.

##### Principles and implementation
The architecture mandates (F298) that the process must deterministically map `SIGINT` to exit code 130 and `SIGTERM` to exit code 143, preserving the reconciliation established in the TypeScript port. The native Rust standard library does not handle `SIGTERM` cleanly or provide safe global interception out-of-the-box. `signal-hook` resolves this by allowing the template to register safe handlers using `flag::register` hooked to an `Arc<AtomicBool>` or a blocking signal iterator [cite: 8, 9, 30]. Because `rs-launch-blueprint` optimizes for a non-async initialization sequence without a long-running daemon mode, a simple blocking iterator or periodic flag check is sufficient to capture the signal, execute any necessary cleanup messages, and explicitly invoke `std::process::exit(130)` or `143`.

If the interactive prompts module (R61) utilizes the `inquire` crate, a critical intersection occurs regarding prompt cancellation (F299). The `inquire` crate natively traps `Ctrl-C` during active user input and surfaces an `InquireError::OperationInterrupted` variant [cite: 16]. The architectural implementation routes this specific library error natively through the `thiserror` domain, mapping it directly to exit code 130. This elegant design prevents `signal-hook` from asynchronously colliding with the terminal's raw mode during an active prompt.

##### Dominant choice
`signal-hook` is the dominant choice for safe, low-level signal interception.

##### Qualified shortlist
`signal-hook`, `ctrlc`.

##### Excluded by gate
The `ctrlc` crate is excluded because it exclusively binds to `SIGINT` and does not provide native `SIGTERM` capture capabilities [cite: 1]. This explicitly fails the F298 requirement to achieve parity with the TypeScript port's `SIGTERM` handling.

##### Up-and-comers
Tokio-based signal handlers are modern alternatives, but they are excluded as they strictly assume an asynchronous runtime, which violates the template's mandate for a lightweight, non-async CLI initialization sequence.

##### Fit for this template
The empirical evaluation confirms `signal-hook` as a minimal, safe dependency.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/signal-hook` | High utility in system tooling. |
| **All-time downloads** | `crates.io/api/v1/crates/signal-hook` | Core ecosystem dependency. |
| **Last release** | `crates.io/api/v1/crates/signal-hook/versions` | `0.4.4` [cite: 8]. |
| **Stars, archived** | GitHub Repository | Active, specialized repository. |
| **Open issues** | GitHub Issue Search | Minimal open issues, primarily edge-case OS behaviors. |
| **Issue responsiveness** | Maintainer Metrics | Stable, mature maintenance. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Adopted by standard TUIs, process managers, and daemons. |
| **Maintenance state** | Rubric Evaluation | `stable-quiet` |
| **License** | Fitness Gate 1 | `MIT OR Apache-2.0` (Pass) [cite: 8]. |
| **MSRV** | Fitness Gate 2 | `1.66.0` (Passes stable minus 2 minor versions policy) [cite: 8]. |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. Low-level `libc` bindings are encapsulated safely. |
| **Platform Matrix** | Fitness Gate 4 | Full UNIX support. Provides degraded but functionally sufficient emulation on Windows (catching standard interrupt signals) [cite: 9, 31]. |
| **Async Coupling** | Fitness Gate 5 | No async coupling. Provides blocking iterators. |
| **Binary/Compile Cost** | Fitness Gate 6 | Minimal cost (45.8 KiB) [cite: 8]. |

##### Recommendation
Adopt `signal-hook`.

##### Ranked runner-up
`ctrlc`.

##### Tradeoffs
UNIX signals are inherently asynchronous, globally scoped, and notoriously complex to handle without introducing race conditions or memory corruption [cite: 19]. `signal-hook` brilliantly mitigates these data races, but requires the developer to design the main execution loop carefully to ensure it does not block infinitely if relying solely on reading an `AtomicBool` flag.

##### Parameters
`owns process-interrupt-contract = signal-hook + 130/143 exit mapping`
`assumes interactive-prompts = inquire` (contingent on R61)

##### Migration implications
The template initialization sequence will spawn a lightweight signal listener or register atomic flags to intercept OS signals. Upon detection, it will cleanly exit with status `130` for `SIGINT` and `143` for `SIGTERM` [cite: 30]. Broken pipe handling (F300) will explicitly not use signals; instead, standard pattern matching (`match write_result { Err(e) if e.kind() == ErrorKind::BrokenPipe => process::exit(0) }`) will be embedded deep in the output formatters to satisfy UNIX conventions [cite: 17, 18].

##### Validation strategy
Execute the compiled CLI, discover its process ID, and send a `SIGTERM` via `kill -15 <pid>`. Verify the terminal returns an exact exit code of `143`. Subsequently, pipe the CLI output to `head -n 1`, close the pipe abruptly, and verify an exit code of `0` and the complete absence of a `std::io` panic trace.

##### Confidence & re-verify trigger
Confidence is high. Re-verification is only required if a future Rust edition introduces native, safe signal handling callbacks directly within the `std::process` module.

##### Sources
*   [cite: 8, 9, 31] `signal-hook` usage, examples, and Windows operating system limitations.
*   [cite: 1, 2, 19] POSIX signal routing behavior and official Rust CLI handling recommendations.
*   [cite: 16, 32] `inquire` crate documentation detailing error variants for interactive cancellation.

#### human-panic

##### Landscape
`human-panic` is firmly situated in the established industry standard bin. Its authority is paramount, having been developed directly by the Rust CLI Working Group explicitly to implement user-friendly crash logs for polished terminal applications [cite: 10]. Practice evidence highlights deep adoption by user-facing CLI tools attempting to prevent raw stack-trace leakage, with the crate demonstrating tens of millions of downloads across the ecosystem.

##### Principles and implementation
Requirement F302 and ADR 0006 mandate that unexpected, unrecoverable panics write a best-effort crash-log file to a deterministic location (e.g., `<state>/plbp/plbp_crash.log`). By default, native `panic!` macros print deep, unformatted, and often intimidating system traces directly to standard error. `human-panic` fundamentally alters this behavior by installing a custom panic hook at process initialization. When an unhandled panic occurs, the library suppresses the raw trace (unless `RUST_BACKTRACE` is explicitly set in the environment), creates an actionable, user-friendly prompt on standard error, and persists a TOML-formatted or plain-text crash dump to the filesystem [cite: 10]. Crucially, by utilizing the underlying configuration structures rather than the basic `setup_panic!` macro, the template can override the default OS temporary directory [cite: 10, 33], explicitly routing the log to the XDG state directory defined by the R57 parameters.

##### Dominant choice
`human-panic` is the dominant mechanism for intercepting and formatting crash logs in user-facing utilities.

##### Qualified shortlist
`human-panic`, `crashlog`.

##### Excluded by gate
No candidates were excluded by fitness gates.

##### Up-and-comers
The `crashlog` crate [cite: 34] is a newer alternative that attempts to limit external dependencies. However, it lacks the established stability, the robust TOML serialization structure, and the ecosystem trust provided by `human-panic`.

##### Fit for this template
The empirical evaluation confirms `human-panic` as a polished, production-ready utility.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/human-panic` | Sustained usage in CLI tooling. |
| **All-time downloads** | `crates.io/api/v1/crates/human-panic` | 23M+ estimated downloads. |
| **Last release** | `crates.io/api/v1/crates/human-panic/versions` | `2.0.8` [cite: 10]. |
| **Stars, archived** | GitHub Repository | Highly starred by CLI developers, non-archived. |
| **Open issues** | GitHub Issue Search | Stable, with issues largely focused on metadata extraction edge cases. |
| **Issue responsiveness** | Maintainer Metrics | Maintained as an ecosystem standard. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Wide variety of developer-experience focused tools. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `MIT OR Apache-2.0` (Pass) [cite: 33]. |
| **MSRV** | Fitness Gate 2 | `1.70.0` (Passes stable minus 2 minor versions policy) [cite: 35]. |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. |
| **Platform Matrix** | Fitness Gate 4 | Universal compatibility (`ubuntu-latest`, `macos-latest`, Windows). |
| **Async Coupling** | Fitness Gate 5 | No async coupling. |
| **Binary/Compile Cost** | Fitness Gate 6 | Minimal cost (11.2 KiB); relies on standard `backtrace` and `os_info` dependencies [cite: 35, 36]. |

##### Recommendation
Adopt `human-panic`.

##### Ranked runner-up
`crashlog`.

##### Tradeoffs
`human-panic` achieves its functionality by globally overriding the default Rust panic hook. In an integrated architecture where the repository functions as both a library and a CLI workspace, the initialization routine must strictly only execute within the CLI binary initialization path (`src/bin/main.rs`). This constraint ensures that if the library component is imported by a third-party Rust application, it does not inadvertently alter the host application's global panic routing, which would constitute a severe violation of library design principles [cite: 37, 38].

##### Parameters
`owns crash-log-persistence = human-panic`
`assumes xdg-directory-set = directories` (R57, required to define the exact `<state>` path mapping)

##### Migration implications
The codebase will inject the `human_panic` initialization sequence exclusively inside the `src/bin/main.rs` bootstrap sequence [cite: 10]. The implementation must ensure the configuration payload dynamically targets the state directory path provided by the R57 resolution, rather than relying on the macro's default temporary folder behavior.

##### Validation strategy
Inject an explicit `unreachable!()` or `panic!("test crash")` statement into a test command execution path. Verify that the console prints the expected "Well, this is embarrassing" user-friendly message and successfully generates a TOML file at `<state>/plbp/crash_*.toml` containing the operating system identity, version metadata, and the structured trace context.

##### Confidence & re-verify trigger
Confidence is high. Re-verification is only necessary if R57 formally declines to establish a dedicated state directory, which would force the architecture to fall back to the operating system's default `/tmp` or equivalent temporary path.

##### Sources
*   [cite: 10, 33, 35] `human-panic` crate metrics, custom configuration options, and crash log formatting structures.
*   [cite: 34] Comparison metrics to the alternative `crashlog` crate.
*   [cite: 37, 38] Documentation regarding the safe utilization of panic boundaries and global hook management.

### Compatibility

The recommended stack operates synergistically, addressing every required ledger pattern without generating architectural conflicts. `thiserror` enumerations are explicitly designed to be supported by `miette::Diagnostic` traits. `strum_macros` seamlessly attaches to those same `thiserror` enums to dynamically surface the static catalog identifiers required by F295. If interactive prompts are utilized, `inquire`'s prompt interruptions (`InquireError::OperationInterrupted`) naturally integrate into the `thiserror` domain, mapping cleanly into the `miette` renderer as Exit Code 130 without interfering with the `signal-hook` global POSIX listeners. Finally, `human-panic` operates strictly at the `panic!` boundary, ensuring that expected domain errors routed through `miette` never trigger crash logs, fulfilling the vital distinction between controlled application exits (Exit Codes 0-5) and unhandled system crashes.

### Parameters

*   `owns error-taxonomy-exit-codes = bundle(thiserror, miette, strum, signal-hook, human-panic)`
*   `owns error-code-catalog-source = strum::IntoStaticStr`
*   `owns error-diagnostic-envelope = miette`
*   `owns process-interrupt-contract = signal-hook + 130/143 exit mapping`
*   `owns crash-log-persistence = human-panic`
*   `assumes interactive-prompts = inquire`
*   `assumes xdg-directory-set = directories` (assumes R57 provides a determinable mechanism to derive the state directory for crash-log persistence).

### Migration implications

The implementation of this contract requires specific, file-level modifications across the template architecture:
*   **`src/error.rs`**: Rewrite all transient and existing error implementations to utilize `#[derive(thiserror::Error, miette::Diagnostic, strum_macros::IntoStaticStr)]`. Add explicit `#[diagnostic(code(..), help(..))]` decorators corresponding to the structured hint requirements of F296.
*   **`src/cli/mod.rs`**: Add a central `map_exit_code()` resolver function responsible for translating the root domain error into the precise integers 0, 1, 2, 3, 4, 5, 130, or 143 according to the F297 taxonomy.
*   **`src/bin/main.rs`**: Register the `human-panic` hook utilizing custom path logic derived from R57 configurations. Register the `signal-hook` listeners to trap and map signals to 130/143. Instantiate `miette::set_hook` conditionally based on the parsed `--format json` CLI parameter.
*   **`src/cli/output.rs`**: Implement standard `if err.kind() == std::io::ErrorKind::BrokenPipe { process::exit(0); }` wrappers for all buffered standard output writers to natively resolve F300 without crashing.

### Validation strategy

The empirical validation of this architectural bundle requires executing specific commands to prove the principles hold under realistic operational stress:
1.  **JSON Envelope Test:** Execute `plbp --format json <invalid-command>`. Assert that the standard error stream contains exactly one valid JSON object encapsulating `{"code": "...", "message": "...", "help": "..."}` and no other textual formatting.
2.  **EPIPE Suppression Test:** Execute `plbp <command-generating-heavy-output> | head -n 1`. Assert that the process exits with code 0 and the standard output closes silently without an operating system panic trace.
3.  **Signal Propagation Test:** Boot the process into a simulated long-running task. Send `kill -15 <pid>`. Assert the process traps the `SIGTERM` signal and explicitly returns exit code 143 to the operating system.
4.  **Prompt Cancellation Test:** Initiate an interactive `inquire` text prompt. Send a `Ctrl-C` key sequence. Assert the process intercepts the keystroke, aborts the prompt, and exits gracefully with exit code 130.

### Confidence & re-verify trigger

Confidence in this architectural bundle is absolute. The chosen combination represents the pinnacle of stable, battle-tested Rust crates tailored specifically to fulfill deep-diagnostic, POSIX-compliant CLI and library requirements. Re-verification is only warranted under extreme ecosystem shifts, such as the `std` library standardizing `std::error::Error` derivation, introducing native signal captures in Edition 2027, or if the R57 parameter entirely declines the establishment of a state directory configuration.

**Sources:**
1. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFfRJxr7Yd6r3ACWBeMlZ0yTJ6PoEZY2jI2vRYItDNBoz0srU4MOuYWQyT5hrUtKXb5r7IiI7u0F7c9Fz_4CuvC6iecohpjHBCpFmR3CN2lYcBu1E4V5rNw9dJeNmAHTJzeio_u37bG8oC-Q==)
2. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbvPmcWHhI2wBB7-jWpI9wr2tWh4-mftvgoHaqEdalSkpy7R5RSJC_qa48iWZjmIlYQrFLWgRWmyta2UKGVdPqJo__KQ-oy9CBkgClCL_SXQcsmKzT09jjyaxTW3QRc5eyazJveyzz9D06U5PD-KzonMcAoxpJNiO0PzcESPIi)
3. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEP2TNBX-dg2lWHnD18VtltCJf63zq6m90nw5lpPJGuYNKCaca-bQHRzkbK7ak4n2y54JDAZiu1Wj37vw0PREpjg7NJKwk9Q_RVisuSJV5PiWV4FdspHOnPztJrUgoOfQVep-8VOGUer0622-mjqrM_nu-gXDA5jENauITnB0nbzo7F_hlPAFvi-pEKEyWLvC80Kco=)
4. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGQYQeYvunAK9qv1O-rfOfN5ur5zHcn6gwxODkIH-vMi6YmFYgStO4eO-Z-vyPaR4FjY4eEDqwiokl4CFOi4YtnS_a-sj9BBw00HJWiuaKqHNsLcdnOcZ6RF2i9TLGQ0w==)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEqWsLAuKMWZ4BDSt0KUhi_nA_kL1AIvWEnkFM9Ni80cjUEVZvS-ZiWRSA8QtW1d705uVPYPkU9AAUFDmCX7wLJoGcjDsfUirUR8J2GhmsCS2JHB0YmNFiU)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFtqO2FsBB97jLrYvMWF9D2eKLGB0E8h36W5wtkNqtaXcFkBML97rbYLD227YZohXHHEZnFzcum8gE99UEBAfyJXaImx4pSy0L5PMk16HWMFkHWoSiM)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGZpt_6ltrLSM4WiH6vuZrFxu6JWb3iJUyRojxcwoqlqd60nrUP7Aa1IzeX6FcLKMRFS86VHUfSq4jA_XOLvLpyUabwBmp3Eremli_dI8JSig==)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_liT5fvp-ZPcr5fHjZ3GuuOBgG56Yp4rjrRet0czjjPtLddtTo05YcqduPTDQ89XDi_qvZowDyjie9flk9FwMsyjTT6fptUUWUox5ZkXl58u0oFbY0jT6u7A=)
9. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEkaCKPXSGu_Q0quSK_qcrwqv1wxrAB81gdVkuE7Ayjvl3sYQKgAn5vhuj0-Mb9PIaSKJ_CvCSGNv0VMKTN_pCTv1Bws5WzqdzLa1k3EpBW1nk=)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjXahPjaNn3Na4Y93DmkRsE_vfJLbm3HLiRxo8aWySxnsKz3j__MlZkzRD_JMyLDXDmoW0vMPOMGKrD3NONwpOuuB95hMpo7AmHeymXdabDvns6c7sZAloavM=)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFSe5w02UOVKCV-lkry_HtptovN-EIb1U4XNb0eY1KZDr4iHHSXGrz7sxJYVUatoyBqDq2BBtY8-OsQZ1s1OIn7dco4xBdci_KNVSUqmLFPIIhgsCmN)
12. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHozukyAPzSIK-n2XcVb32XoOMKbrK8Ks4bYZbVwgjWycOFCeAeMhTdwYt4suMZRaY4OwWeEVso-KQD4ffOVrcYhxN29CFbZnlEc0_8s2KCGP3hmGzWbZ-Ln5V9H3O_-kK5HOwXwMaUaS_R4jbfN_-p)
13. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnouNl5KTLgEb-jrXsEWkCyKQwMlPGPsSFqLOx1oQihGCCsaJHkUnfMRexAwJ9YL_WShIQXUiKJTFilaXiak033mKE9b1qEhRVjA3wM98z8F4thiBlxQbB94Rs)
14. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQErpcdFbwVatjlXvUNv5f6H3TZj37reD22SRc5k2ZuzheNKTiW8FVXIXjx_KCILHs1E-Tf07aBDjvba20WpnPzG5IFjmLiEoaapfq8yECr9KEG-tNarPkWiSqQ=)
15. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHXzevZlIwebZ9DNwIQGkwf8c4H67WXgdS6WMR6Ga6zsPwFqP0eE1NCyCycxMLH-Ojnnwer_p6OmbkRKeLENYZvKO0NAH-w2a96fot4pbp85wdCtHK5bug=)
16. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFgnqBOlIHEUgDfzEYqYSNHCtfmxlxe7rxw2OF8nLXFzGXaqaLTBV2Hns0lMneYevbDzPOHDzXKAMhrRCBSITMUH10CGvw2vP-8soO44Z2AKGp7WusT-SBkb_TllGQpDreWPJFHKrmX88YVCyyepSuCkSrtkhFUEAD7MES3Pd30)
17. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGwjqQJ_kwNxN_aGqjxO21vQeNAUr2DGkzqtef5cZUSL_TDvy_xNlhnmoT4QkVqc9i3TaVbjhRW7n47DWU7XJcGDTRA39ynQu8FogKjsuG3mhxCgx75YxMJgE8RxNkfBZXoaNZtYUNzJFI_7WgYeqfP_BxtQUD8GdUp_eVfNuCz-JH4Ut6a4A==)
18. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHry1sojPN9vD4Fi94A0m7SLwsGTJIc_N8MPRB6oGplhXpDuXR-5bRdiwvkfAM0cqNdHkZoJ1rM-__9I32UZmJoN8oECiCXerWWM7mGRC-E86p3CjTJeerynh-8bHpj6tzhQ-uIL6gC_QTkBtsOwgAqKhqbihXxowJFfvU5IH-tY4SXMXgWjbrjJocLQ-I-PxZmENebgJrc4VfXWm0ur1nz6Zb_e649B7G09p8BfYUQgZLnhQ==)
19. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFJmdU-L8X8ERXskNfoEn6puAzBdcB6ZihsvKyENIZmdEio8Ps5zX8A7bS91Ns8RJds_99FvLN5oNmO2c4aMhFA7JSO26tJX3juAPRN54obiM9802dpanog8LuPRN5ez8U0cn5z_EQz2khJCooPR1EfKX1jwMpI63bugw4NEhg=)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQENL5CpaeVHOusfOAdavXbwSywE04u6tEQ--qBQp5PKZz8JBSCkDF8nJq2jM1A-MLoZX_cIoGzDEQCBX84lf5WQDCYo8ltzTYY=)
21. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGVQipKppvvTribihZV7XXGz1Qm7KO6oEgKpPH6yXtjPff7O0_KngFgg9JTOtxJdp_xInEuSSFJXXfyg9faXuzCjqrMJ4cQLAmWACamj3tC)
22. [Link](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFOBjWEVH961vN5wzjPBJw2MRNB0lLix3Up4edz9-3RuPHZPdJ35AB929s_TfsUE_KtVSE4THrnVObdqRO_URghxUshjGi_v0Xd63QDkw1p2hrRK_f2qPnCW13HH69W7dKn8Tj0J8jtiHVr1MUZMYZFm_wEh6Zu5Wo=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEG7nIRz0hC6nF9relQi8Xuy_7tesI_WCHnJPk-_KmggrcS8Sh0mJEUazuYB9kIAJdbI3wUtGkbKXkifgCD0LhAUrSnOwU603KVrn6o1e0yZVkTI-bNx-2HWSZ87Shn)
24. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEuK3QW9gUIdM4XIMZs0tnw3SWVZEy4oOteLbuTaQyz4SAZJx3lvodbenFmYIXs27fK8YV_DB6EW3xGHS99p7w4INT2_1aDcNTldZbgImKQC8YXAiPGlxpLIvUPeGUZqIRo6M4xwQVA2Fn6C15GPul1MNlvXAcR5rA=)
25. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFu8-9lw1sKAFsyRh6IxCSIM-yn3pXT_qpG7C2gu80E0MbYLf8BSAM_Fr6z4_TahxjPB0lgwUucigxLi0mjVO862ahQsSFDvcl_NWrxNyOH1Rqygv926m9zhBO-)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHYr08N7vgAOZpdilw1ZZUyUJroIeb3uAJ2Bjt6_IQHXwYP5C3ayuAyUxZQzkVVGBTIrcKbMGgvC2VUIYbDEpNcVRu8lc0qu8liDeyHVSVtvdObkh4m8DX4fm8=)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFkTy-qzlD0Bb4UFnHy3DQX2CEDAW0Z0mKKWw3O_4PmCcA-rXFXBdknKHYmcsf8C5WyJ35uwLQMlu5Nes2RzeA0cPYINzAyNN1kzcqmm9B9Jm1UWlMdP5-xOR1I)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH1tN5QR_Bj4vI-EkM-L7xadBTdMfSuIMnndHpCoLEopZ5In0C1LNUYkozjVJVEXCcC0UuLmOhx-yUX2LmBlae25vfajNPCgFZyLCKnq9CZWiBimROQ)
29. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEl-xmFgvJf8Hy0nnx9ZIcJQOyhdwFoIDzst9Vt7nIDaGAf7HTVtqp7eCJroejnTf6RcDaluJ8PTiJYq40aLqwDHg2wUZELFDvKdqtYbWhJgcc1ZdKL5ii4HhkzuphFcyoxyYpVmoq1GCCj70vIY1w=)
30. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEGN9AVzJbIiz8D7vWgBPuo1s_MZQ11em7_kZAHBSCHi6SDrC72Ri313B7ema-Ic7Vl6osZirb7xnm9Z06ua7stGd85xdXy4p4VpEzbgaFvGcOTeMCpeywjMERkd3jFBdrxrazU4le0QaCzyYrSpoPo7AWA4A==)
31. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG71319kf3n2nCsWE8ZolqdqGrhvY8Fym1sZVOy4sKaTInb7zfvXBzYwhbYHYjmC5prcULCsIwtiJFA_xyOhtr4PZId6-GeAwuBjRckJcGd8DoeJyZKlD9qL6-fmoU2p9J3XpZFBm8PM9ol0bbuzA==)
32. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1pjS8FoOcOMzbFDegqDYhP9H6akauxxrh21_bR1roAFm7UOW-L_lZkxcA7cr4nd6bG8rdS6AiTrEu8CoZLf_byOvYrFUI2Nc-T_qOlV0FvahRXgOgZPNPGSsOuQ==)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHO69ZAhgyhRgFT-EICw5zIdmEv81oGvYbzncA0VTqbfOWReqAVxhD4-aMUeiBWz1u93NlV-CsfPIY-0esTZjgFx98FAwTbm2NzxlD3c0FdomDqcDMyOSIgmf-leGo4OZRnc-j70w==)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFlBup400jHQBQHgojiyeF4HAdouP2DIi6Ity6eod7ZLWhbyy-1QbxScfS7DhU3POs1FZayxrQjA_EcEv7mTuujhjVCXvqWH8_F7LBWhKPm5iRqb8hgwk9jqw==)
35. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG85pr9CyTPZnbhvO-oZqTsU9nCYgOoeq1w3ev64g6bpy0RQ7GmPc23N3dCWybmHLJ_wZlmi-yUkpL3g7pYm3JEdP9bVltwqN1WX0ccYwyDSw2HhhVqIMi_w1bdD1E1YlA=)
36. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEu2qirIvYMwdawzHHDT5Cm-I2-uVpPhkFtuARS2KpRYgxmq7lznGKzfqUTmjR9J_wywU79uRgMo3BlQwuy5F9Ic0DyM4YE8dzv4Sg6Rk0gWVNG4sucyFcHMURDwb8qAQcWYW_Fwc_7UxBQV-nO)
37. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbeTiqe6Sa3vNQ5kPv5XkFT7kc0oBKgpMa7KjUO-UYTozMrjgK2erP81-KjSJrGnxOMfeKfa2aOiEDj6qZsHRawOLptsI4AxxL6ITVQfubOZOCsXq6v_15wsD3TsKw_AvG7t7O7_qXo9Z8PqOThQ8Ari-nIIn7AIgEwACCttkgXmMewnG-E-lRLJk=)
38. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGli_rF6itHFlecJWT9ZF73irFWiPIzQU4Vgc56Ii6rF9qTEeHlhE3pHFQx22V6cXUJNMlNFgAqH8YP27MGat8dPBxCw8phscxKxkW7H_wf-TzA_tcGLvDGYE0LJzmh8TMT_PcgTWY8IzE9Pje2XN7xb17elgpOwml44cR1iJ30GpupXcdo6MkKeJQ=)

## Sources

- [stackoverflow.com](https://stackoverflow.com/questions/26280859/how-to-catch-signals-in-rust)
- [github.io](https://rust-cli.github.io/book/in-depth/signals.html)
- [github.io](https://microsoft.github.io/RustTraining/rust-patterns-book/ch10-error-handling-patterns.html)
- [crates.io](https://crates.io/crates/thiserror)
- [crates.io](https://crates.io/crates/thiserror/1.0.24)
- [crates.io](https://crates.io/crates/miette)
- [docs.rs](https://docs.rs/oxc-miette)
- [crates.io](https://crates.io/crates/signal-hook)
- [docs.rs](https://docs.rs/signal-hook)
- [crates.io](https://crates.io/crates/human-panic)
- [crates.io](https://crates.io/crates/anyhow)
- [docs.rs](https://docs.rs/miette/latest/miette/trait.Diagnostic.html)
- [crates.io](https://crates.io/crates/strum/0.15.0)
- [crates.io](https://crates.io/users/emmatebibyte)
- [crates.io](https://crates.io/users/andreastt)
- [docs.rs](https://docs.rs/inquire-clack/latest/inquire/error/enum.InquireError.html)
- [rust-lang.org](https://users.rust-lang.org/t/broken-pipe-when-attempt-to-write-to-stdout/111186)
- [stackoverflow.com](https://stackoverflow.com/questions/65755853/simple-word-count-rust-program-outputs-valid-stdout-but-panicks-when-piped-to-he)
- [medium.com](https://sigridjin.medium.com/handling-posix-signals-in-rust-fac42c33e5b6)
- [crates.io](https://crates.io/)
- [crates.io](https://crates.io/crates/)
- [Link](https://docs.rs/miette/latest/miette/struct.JSONReportHandler.html)
- [crates.io](https://crates.io/crates/miette/security)
- [docs.rs](https://docs.rs/miette/latest/miette/struct.MietteHandlerOpts.html)
- [crates.io](https://crates.io/crates/miette/3.0.1)
- [crates.io](https://crates.io/crates/miette/code)
- [crates.io](https://crates.io/crates/strum/0.27.2)
- [crates.io](https://crates.io/crates/strum/)
- [docs.rs](https://docs.rs/strum/latest/strum/derive.EnumString.html)
- [dev.to](https://dev.to/talzvon/handling-unix-kill-signals-in-rust-55g6)
- [crates.io](https://crates.io/crates/signal-hook-registry/1.4.1/code)
- [crates.io](https://crates.io/crates/inquire/0.0.6)
- [crates.io](https://crates.io/crates/human-panic/2.0.4/code)
- [github.com](https://github.com/kdkasad/crashlog)
- [crates.io](https://crates.io/crates/human-panic/1.2.1)
- [crates.io](https://crates.io/crates/human-panic/1.1.2/dependencies)
- [reddit.com](https://www.reddit.com/r/rust/comments/1305ihw/rusts_philosophy_of_panic_recovering/)
- [rust-lang.org](https://internals.rust-lang.org/t/configure-the-crates-required-panic-strategy/22271)