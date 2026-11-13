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
provider: openai
model: gpt-5.6-sol
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

### Landscape

**Research date:** September 9, 2026.  
**Decision category:** a cross-surface **diagnostic protocol and process-lifecycle policy** for a Rust workspace containing a reusable library, CLI, and web service.

**Evidence-collection limitation:** the research browser could not directly retrieve several requested crates.io and GitHub JSON API endpoints. I report values corroborated by docs.rs, repository HTML, or registry mirrors and explicitly mark unavailable figures rather than fabricate 90-day downloads, `pushed_at`, or issue-response medians. The canonical commands to close those gaps are included under Validation strategy.

#### Three-bin field map

| Bin | Candidates found | Relevance |
|---|---|---|
| **Built-in / first-party toolchain** | `std::error::Error`, `Error::source`; `std::process::{ExitCode, Termination}`; `std::io::ErrorKind::BrokenPipe`; `std::backtrace::Backtrace`; panic hooks; `OpenOptions`; Rust/Cargo SemVer guidance | Sufficient for the catalog, exit enum, EPIPE classification, backtrace capture, and crash-file append. Stable Rust has no general signal-registration API, so SIGINT/SIGTERM need an external crate or runtime-specific adapter. Rust recommends returning a `Termination` value rather than calling `process::exit` early when cleanup matters. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html)) Retrieved September 9, 2026. |
| **Established industry choices** | `thiserror`, handwritten `Error`; `anyhow`/`eyre`; `miette`; SNAFU; `strum`; `signal-hook`; `ctrlc`; `clap`; `inquire`/`dialoguer`; `human-panic` | `thiserror` is the strongest fit for matchable library/domain errors; `miette` directly models diagnostic `code` and `help`; `signal-hook` provides safe signal-registration façades; `clap` establishes exit 2 for parser misuse; `inquire` demonstrates typed prompt cancellation. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026. |
| **Up-and-comers / narrower tools** | `error-stack`, `pipecheck`, `proc-exit`, dedicated SIGPIPE crates | Useful in specialized applications, but each adds a model beyond this bundle’s needs. `error-stack` emphasizes contextual reports; `pipecheck` restores signal-like EPIPE behavior. Neither removes the need for an explicit, governed catalog and mapping table. ([lib.rs](https://lib.rs/crates/error-stack)) Retrieved September 9, 2026. |

#### Authority used

1. **Rust Project sources:** standard-library documentation, Cargo SemVer guidance, Rust API Guidelines, RFC 2965, and the Rust SIGPIPE tracking work. These define language/API compatibility and runtime behavior rather than merely reporting third-party opinion. ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/interoperability.html)) Retrieved September 9, 2026.
2. **POSIX.1-2024 and GNU Bash:** authoritative for shell-observable process status. POSIX requires signal-derived statuses above 128; Bash uses `128 + signal`, yielding 130 for SIGINT and 143 for SIGTERM. ([gnu.org](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html)) Retrieved September 9, 2026.
3. **Maintainer documentation:** `thiserror`, `miette`, `signal-hook`, `clap`, and `inquire` documentation establishes their actual APIs and behavior. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.
4. **Rust community evidence:** the 2025 State of Rust Survey is the Rust Project’s tenth annual survey; it is useful ecosystem context, though it does not select a particular error crate. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)) Retrieved September 9, 2026.
5. **Production-practice evidence:** `thiserror` is reported as used by tens of thousands of crates; Cargo and uutils have both had to treat closed-output/SIGPIPE behavior explicitly; current Rust work still considers global SIGPIPE policy unsettled. ([lib.rs](https://lib.rs/crates/thiserror)) Retrieved September 9, 2026.

#### Practice findings

- `thiserror` is the dominant typed-error derive: its generated implementations do not become part of the public API, and its documentation explicitly positions it for dedicated library error types. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.
- `miette` is the closest architectural alternative because `Diagnostic` has separate `code()` and `help()` methods. Its rich renderer is optional but introduces more presentation policy and feature weight than this core bundle needs. ([docs.rs](https://docs.rs/miette/latest/miette/)) Retrieved September 9, 2026.
- Rust currently ignores SIGPIPE at startup, causing writes to closed pipes to surface as `ErrorKind::BrokenPipe`; stable applications must therefore make output writes fallible or deliberately change signal policy. The latter remains under active Rust design work. ([github.com](https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs)) Retrieved September 9, 2026.
- Different production workloads justify different EPIPE mechanisms: coreutils-like pure text producers often prefer signal-like termination, whereas a combined CLI/library/web-service process benefits from retaining Rust’s EPIPE error model and classifying only its CLI stdout boundary. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html)) Retrieved September 9, 2026.

### Principles and implementation

#### Shared requirement and agreement level

The shared principle is:

> **Machine-facing error identity and process outcomes are protocol values, independent of implementation type names and presentation text; human remediation, diagnostics, and ecosystem-specific capture mechanisms remain separate layers.**

That principle follows from F294’s settled machine envelope, F301’s settled trace-disclosure rule, and the observed F295–F302 divergence supplied by the owner.

| Concern | Required agreement level across py/ts/rs | May vary by ecosystem |
|---|---|---|
| Error identity | **Standard:** documented, stable, append-only wire strings | Python class hierarchy, TypeScript tagged union/class, Rust enum/trait |
| Message vs remedy | **Schema/policy:** concise `message`; optional separate `hint` | Human styling, colors, labels |
| Exit statuses | **Low-level process standard:** 0/1/2/3/4/5/130/143 meanings | How each runtime reports or returns them |
| SIGINT/SIGTERM | **Observable capability:** clean cancellation, 130/143 | Python exceptions, Node signals, Rust signal adapter |
| Prompt cancellation | **Observable capability if prompts exist:** no library-internal text, status 130 | Typed prompt errors versus process signal |
| EPIPE | **Observable capability:** expected early pipe closure is silent and non-crashing | Node stream handler versus Rust fallible writes |
| Unexpected-error persistence | **Process-boundary policy:** best-effort sanitized crash record | Filesystem API and platform state-directory provider |
| Stack traces | **Disclosure policy:** user-visible only under verbose/debug | Capture mechanism, pending F301 disposition |

This makes the recommendation a deliberate hybrid: Python supplies the stronger stable-code, hint, and crash-persistence ideas; TypeScript supplies the stronger shell status, SIGTERM, prompt-cancellation, and EPIPE behaviors. Neither language’s concrete mechanism is transplanted into Rust.

#### Architectural alternatives

| Alternative | Assessment |
|---|---|
| Derive wire code from a Rust variant name, discriminant, `Debug`, or type name | **Reject.** Renaming/refactoring changes the machine protocol accidentally. Numeric discriminants also conflate ABI/layout choices with protocol identity. |
| Explicit `ErrorCode` enum with manually declared wire strings | **Choose.** Rust code can match semantic variants while `as_str()` supplies a separately governed wire value. |
| Dynamic string codes carried by each error | Flexible but permits typos and incomplete mappings; no compiler coverage. Reject as the catalog’s source of truth. |
| `miette::Diagnostic` as the core abstraction | Qualified alternative: it directly supports codes and help, but its code is a dynamic `Display` value and its diagnostic/reporting layer is broader than the CLI/library/web contract needs. |
| `anyhow`/`eyre` throughout | Suitable only after an error is no longer expected to be handled. Erasing R03/R52–R56/R70 errors early would defeat typed downstream mapping. RFC 2965 similarly distinguishes structured error kinds from final reporting types. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html)) Retrieved September 9, 2026. |

#### Public append-only catalog versus Rust exhaustiveness

Rust cannot simultaneously promise both:

1. semver-compatible addition of public enum variants, and
2. exhaustive external matches that continue compiling unchanged.

Cargo documents adding a variant to an exhaustive public enum as breaking; `#[non_exhaustive]` is the standard mitigation. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html)) Retrieved September 9, 2026.

Therefore:

- `ErrorCode` is a **public `#[non_exhaustive]` enum**.
- A single `macro_rules!` catalog declaration generates:
  - the variants;
  - explicit wire strings;
  - `ErrorCode::ALL`;
  - `as_str()`;
  - `Display`;
  - the exit-code mapping.
- Mappings inside the defining crate remain compiler-exhaustive.
- Cross-crate mappings such as R70 must be coverage-tested by iterating `ErrorCode::ALL`.
- `strum` is not required. It would reduce boilerplate but would not establish append-only governance, collision checks, documentation, or mapping coverage.

The envelope’s `code` is populated **only** by `ErrorCode::as_str()`. It must never use `std::any::type_name`, enum `Debug`, default serde variant naming, a `thiserror` message, or a discriminant.

#### Initial catalog

Before implementation, compare these proposed new allocations against the complete existing Python append-only codebook. `PLBP000` is already fixed by owner evidence; no occupied Python code may be reassigned.

| Rust variant | Wire code | Meaning | Default CLI exit |
|---|---:|---|---:|
| `Unexpected` | `PLBP000` | Unclassified internal failure | 1 |
| `Usage` | `PLBP100` | Invalid CLI syntax, option, argument, or command usage | 2 |
| `ConfigNotFound` | `PLBP200` | A configuration path that must exist does not | 2 |
| `ConfigRead` | `PLBP201` | A surfaced configuration layer cannot be read | 2 |
| `ConfigParse` | `PLBP202` | A surfaced configuration document is syntactically invalid | 2 |
| `ConfigInvalid` | `PLBP203` | Parsed configuration violates the application schema or constraints | 2 |
| `ConfigSecretDisallowed` | `PLBP204` | A secret was supplied through a prohibited configuration channel | 2 |
| `AuthRequired` | `PLBP300` | Required credentials are absent | 4 |
| `AuthRejected` | `PLBP301` | Supplied credentials were rejected | 4 |
| `ResourceNotFound` | `PLBP400` | The requested domain resource does not exist | 3 |
| `Conflict` | `PLBP401` | Current state conflicts with the requested operation | 5 |
| `Transport` | `PLBP500` | DNS, connection, timeout, TLS, or equivalent transport failure | 1 |
| `RemoteApi` | `PLBP501` | Remote service returned a non-auth, non-not-found application failure | 1 |
| `Io` | `PLBP600` | Non-configuration filesystem or stream I/O failure | 1 |
| `BrokenPipe` | `PLBP601` | Broken pipe outside the benign successful-stdout case | 1 |
| `Interrupted` | `PLBP700` | Process received SIGINT/Ctrl-C | 130 |
| `Terminated` | `PLBP701` | Process received SIGTERM | 143 |
| `PromptCancelled` | `PLBP702` | Interactive prompt was interrupted, cancelled, or reached closed stdin | 130 |

Catalog rules:

- Existing wire strings are never renamed, reassigned, or deleted.
- A retired code remains documented as deprecated.
- New entries require a meaning, default exit class, documentation, and mapping tests.
- Message and hint wording may evolve without changing the code.
- Machine consumers branch on `code`, never `message` or `hint`.

#### Typed error layout

Use domain-specific enums rather than one unconstrained mega-enum:

```rust
use std::{borrow::Cow, error::Error};
use thiserror::Error;

pub trait CodedError: Error + Send + Sync + 'static {
    fn code(&self) -> ErrorCode;

    fn hint(&self) -> Option<Cow<'_, str>> {
        None
    }
}

#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("configuration file does not exist")]
    NotFound { path: std::path::PathBuf },

    #[error("configuration is invalid")]
    Invalid { reason: String },
}

impl CodedError for ConfigError {
    fn code(&self) -> ErrorCode {
        match self {
            Self::NotFound { .. } => ErrorCode::ConfigNotFound,
            Self::Invalid { .. } => ErrorCode::ConfigInvalid,
        }
    }

    fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::NotFound { path } =>
                Some(format!("create or correct {}", path.display()).into()),
            Self::Invalid { .. } =>
                Some("correct the invalid configuration value".into()),
        }
    }
}
```

`thiserror` owns `Display`, `source()`, and conversion boilerplate; the project-owned trait owns protocol metadata. `Unexpected` must display a sanitized generic message while retaining its source for verbose diagnostics and crash recording. `thiserror` supports concrete source chains and transparent wrappers without changing the public error representation. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.

#### Envelope and hint

Machine mode:

```json
{
  "error": {
    "code": "PLBP203",
    "message": "configuration is invalid",
    "hint": "correct the invalid configuration value"
  }
}
```

Rules:

- `hint` is optional and omitted when absent, rather than serialized as `null`.
- Human output renders it as a separate `hint:` block.
- JSON preserves it as a separate string field.
- A hint is actionable but not stable machine identity.
- Source chains and backtraces are not serialized into this envelope.
- Error stdout remains empty; stderr contains exactly one JSON document.

This follows the same semantic separation exposed by `miette::Diagnostic::code()` and `help()`, without adopting its renderer as core architecture. ([docs.rs](https://docs.rs/miette/latest/miette/trait.Diagnostic.html)) Retrieved September 9, 2026.

#### Exit taxonomy

```rust
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[repr(u8)]
pub enum CliExitCode {
    Success = 0,
    Failure = 1,
    Usage = 2,
    NotFound = 3,
    Auth = 4,
    Conflict = 5,
    SigInt = 130,
    SigTerm = 143,
}
```

Meaning:

- **0:** success, help/version, or benign stdout EPIPE after a downstream consumer closes early.
- **1:** unexpected, remote/API/network, general I/O, and other operational failure.
- **2:** parser misuse or a surfaced configuration failure.
- **3:** requested domain resource absent.
- **4:** credentials absent or rejected.
- **5:** domain/state conflict.
- **130:** SIGINT, Ctrl-C prompt interruption, prompt cancellation, or closed prompt stdin.
- **143:** SIGTERM.

This is preferable to Python’s `INTERRUPT=5`: exit 5 is useful as a domain conflict class, while 130 and 143 are recognizable shell conventions. It also aligns with `clap`, which reports parser failures as 2, and with POSIX/Bash’s signal-status conventions. ([docs.rs](https://docs.rs/clap/latest/clap/error/struct.Error.html)) Retrieved September 9, 2026.

Return `CliExitCode` through `Termination` or convert it to `std::process::ExitCode` from the top-level function. Do not call `process::exit` before crash-log flushes and other cleanup have completed. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html)) Retrieved September 9, 2026.

#### SIGINT and SIGTERM

- Install handlers only in executable entrypoints, never in the library.
- On Ubuntu and macOS, use `signal-hook` to distinguish SIGINT from SIGTERM.
- Handler-side work is restricted to signal-safe notification; rendering, allocation, logging, and filesystem writes occur after normal control resumes.
- The first signal requests cooperative cancellation.
- The top-level boundary converts SIGINT to `PLBP700`/130 and SIGTERM to `PLBP701`/143.
- A web-service runtime may use its own maintained signal adapter, such as its async runtime’s signal module, but must return the same contract values.

`signal-hook` explicitly documents the global and async-signal-safety hazards and supplies safe higher-level flag/iterator mechanisms. ([docs.rs](https://docs.rs/crate/signal-hook/latest)) Retrieved September 9, 2026.

#### Prompt cancellation

F299 is contingent on R61.

If R61 selects `inquire`, map:

- `InquireError::OperationInterrupted` → `PromptCancelled`, exit 130;
- `InquireError::OperationCanceled` → `PromptCancelled`, exit 130;
- prompt EOF/closed stdin → `PromptCancelled`, exit 130;
- `InquireError::IO(e)` → normal I/O classification unless the global signal token records SIGINT.

`inquire` explicitly distinguishes cancellation from Ctrl-C interruption; with its `console` backend, Ctrl-C can instead arrive as SIGINT, so both typed-error and process-signal paths are required. ([docs.rs](https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html)) Retrieved September 9, 2026.

Never match an error’s display text or type-name string.

#### Broken pipe

Use fallible `Write` calls throughout output renderers; do not use `println!`/`eprintln!` for potentially large or piped output.

```rust
match render_success(&mut stdout, value) {
    Ok(()) => CliExitCode::Success,
    Err(e) if e.kind() == std::io::ErrorKind::BrokenPipe => {
        CliExitCode::Success
    }
    Err(e) => {
        render_error(AppError::output(e));
        CliExitCode::Failure
    }
}
```

Specific rules:

- Successful stdout `BrokenPipe` is silent and exits 0.
- No secondary stderr diagnostic is emitted for that case.
- A broken pipe on another application stream maps to `PLBP601`/1.
- If writing an already-selected error envelope to stderr fails with EPIPE, retain the original application exit status.
- Do not globally restore SIGPIPE in the combined CLI/library/web template. Rust’s stable default deliberately exposes EPIPE, and its broader SIGPIPE policy remains unsettled. ([doc.rust-lang.org](https://doc.rust-lang.org/std/io/enum.ErrorKind.html)) Retrieved September 9, 2026.

#### Crash-log persistence

Adopt a process-boundary `CrashSink`:

- Fatal CLI/startup `Unexpected` errors are offered to the sink before rendering.
- The default executable uses a file sink when R57 supplies a state directory.
- The path is `<state-dir>/crash.log`; this item does **not** hard-code `~/.local/state`, macOS Library paths, or a temporary-directory fallback.
- Failure to create, serialize, append, or permission the file is silently ignored and never changes the primary envelope or exit status.
- Use newline-delimited JSON and restrictive Unix permissions (`0600`).
- Store timestamp, application version, PID, stable code, sanitized source chain, and optionally a backtrace.
- Do not store argv, environment variables, headers, tokens, configuration contents, or secret values by default.
- Routine expected domain errors and per-request HTTP errors do not create crash records.
- A binary panic hook may reuse the sink, but panic exit semantics remain Rust’s panic semantics unless a separate owner decision adopts `catch_unwind`.

This retains Python’s diagnostic-survival principle without making the reusable library perform filesystem I/O.

#### Performance assessment

No throughput benchmark was run, because the selected mechanisms execute primarily on errors or signals:

- `thiserror` generates ordinary trait implementations; runtime cost is equivalent to handwritten implementations.
- Catalog lookup is an exhaustive `match` over a small copyable enum.
- EPIPE handling adds one branch only on a failed write.
- Crash persistence is off the success path.
- `signal-hook::iterator` can consume one helper thread; a polling flag adapter can avoid it when all operations already support bounded polling.

The relevant future measurements are incremental compile time, release-binary size, idle helper-thread cost, signal-to-cancellation latency, and crash-write latency. No “fastest” claim is made from unrelated benchmarks.

#### Observable acceptance criteria

1. Every domain error has exactly one stable catalog code and default CLI exit.
2. Existing wire strings cannot disappear or change meaning without a failing catalog snapshot test.
3. Every `ErrorCode::ALL` member has an exit mapping; R70 later supplies a corresponding HTTP coverage test.
4. Renaming a Rust enum variant does not alter JSON output.
5. JSON errors emit exactly one stderr document and no stdout.
6. Hints are separate in both human and JSON formats.
7. Parser misuse exits 2; not-found 3; auth 4; conflict 5; SIGINT 130; SIGTERM 143.
8. Prompt cancellation exits 130 without prompt-crate internals.
9. `producer | head` causes no panic, no EPIPE diagnostic, and producer status 0.
10. Fatal unexpected errors create a sanitized best-effort crash record when a state directory is available.
11. Library-only tests prove that importing the library installs no signal or panic hooks and writes no process streams/files.

`BASELINE-REVIEW: F295 — machine identity is a protocol value, not an exception/type name — proposed change: migrate the TypeScript follow-on from err.name to the shared explicit catalog; Python already satisfies the principle — evidence: Rust typed-error guidance, Cargo SemVer constraints, and miette’s separately documented diagnostic codes.`

`BASELINE-REVIEW: F298 — process interruption must compose with shell automation — proposed change: migrate Python’s interrupt status from 5 to 130 and add SIGTERM 143; affects Python shell-status consumers — evidence: POSIX.1-2024 and GNU Bash 128+signal behavior.`

`BASELINE-REVIEW: F301 — diagnostic capture and diagnostic disclosure are separate policies — proposed change: provisionally use Backtrace::force_capture only for PLBP000 when verbose/debug or crash persistence is active, and never serialize a trace in JSON; affects R66 and R67; owner disposition remains pending — evidence: Backtrace::capture can be disabled by environment, whereas force_capture ignores those variables.` ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html)) Retrieved September 9, 2026.

### Recommendation

Adopt the **Typed Contract + Boundary Adapters** stack:

```toml
[dependencies]
thiserror = "2.0.20"

[target.'cfg(unix)'.dependencies]
signal-hook = { version = "0.4.4", default-features = false, features = ["iterator"] }
```

Plus a project-owned stable-Rust contract layer using:

- an explicit macro-generated `ErrorCode` catalog;
- domain-specific `thiserror` enums implementing `CodedError`;
- a separate `CliExitCode`;
- `std::process::Termination`;
- fallible `Write` and `ErrorKind::BrokenPipe`;
- an injected, best-effort `CrashSink`;
- `std::backtrace::Backtrace`, subject to the F301 disposition.

Do **not** add `strum`, `miette`, a dedicated exit-code crate, a SIGPIPE crate, or `human-panic` to the base template. They either duplicate a small governed mapping or couple the core library to a broader reporting policy.

### Members

#### thiserror 2.0.20

##### Landscape

`thiserror` is the established typed-error derive for Rust libraries. Its generated `Error`, `Display`, `source`, and `From` implementations behave like handwritten code and do not expose `thiserror` as a public API type. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.

##### Principles and implementation

Use it for concrete errors that R03, R52–R56, and R70 can inspect. Keep stable `code()` and `hint()` methods project-owned; do not make the wire contract depend on macro-generated variant names.

Fitness gates:

| Gate | Result |
|---|---|
| License | **Pass:** MIT OR Apache-2.0. |
| MSRV | **Pass:** current manifest declares Rust 1.71, below project MSRV 1.96. |
| Advisories / unsafe | **Pass with CI confirmation:** no open package advisory surfaced in the RustSec search; integration requires no application unsafe code. |
| Ubuntu/macOS | **Conditional pass:** platform-neutral proc-macro/generated Rust; template matrix must prove both targets. |
| Features/runtime | Default `std`; no async-runtime coupling. |
| Size/compile | Negligible runtime and release-binary cost; low-to-moderate proc-macro compile cost. |

The latest manifest’s license, MSRV, and default feature are visible in the repository. ([github.com](https://github.com/dtolnay/thiserror/blob/master/Cargo.toml)) Retrieved September 9, 2026.

##### Dominant choice

`thiserror` has substantially broader ecosystem adoption than richer report frameworks and directly fits Rust API guidance to return meaningful concrete error types. ([lib.rs](https://lib.rs/crates/thiserror)) Retrieved September 9, 2026.

##### Qualified shortlist

- Handwritten implementations of `Error`, `Display`, and `source`.
- `miette` without `fancy`, if R66 later requires source spans, labels, code URLs, or diagnostic severity.
- SNAFU where automatic context selectors and backtrace policy justify its larger abstraction.

##### Excluded by gate

None of the principal typed-error alternatives was excluded on license alone. Dynamic report-only errors are excluded by this item’s **typed downstream matching** capability gate, not by package fitness.

##### Up-and-comers

`error-stack` is the notable context-rich alternative. It is useful for attached context and reports but would not eliminate the explicit `ErrorCode` catalog or exit mapping. ([lib.rs](https://lib.rs/crates/error-stack)) Retrieved September 9, 2026.

##### Fit for this template

Excellent:

- reusable library APIs remain typed;
- CLI and HTTP adapters can classify the same domain error;
- source errors remain available for debug/crash reports;
- presentation remains outside the library;
- no async or OS coupling.

##### Recommendation

Use `thiserror = "2.0.20"` for every concrete domain/infrastructure error enum. Require each surfaced error type to implement the project’s `CodedError` trait.

##### Ranked runner-up

Handwritten standard-library implementations. They have zero dependencies but create repetitive, review-sensitive `Display`, `source`, and conversion code.

##### Tradeoffs

- Proc-macro compile cost.
- `#[from]` can encourage overly broad automatic classification; use it only where every source value maps to the same semantic code.
- It does not provide codes, hints, exit values, JSON, or crash logging; those remain deliberately project-owned.

##### Parameters

Contributes:

```text
domain-error-representation = concrete thiserror enums
code-source = project ErrorCode catalog, never thiserror variant names
```

##### Migration implications

- Replace generic/string errors in `src/core` with domain enums.
- Add explicit `code()` and `hint()` implementations.
- Prevent blanket `From<io::Error>` where context determines `ConfigRead`, `Transport`, `BrokenPipe`, or generic `Io`.
- Preserve source errors with `#[source]`.

##### Validation strategy

Planned:

```bash
cargo test -p rs-launch-blueprint-core error_contract
cargo test -p rs-launch-blueprint-core error_sources_are_send_sync
cargo semver-checks check-release
```

Expected:

- all public errors implement `Error + Send + Sync + 'static`;
- source chains remain intact;
- no wire code is obtained from `Debug` or variant spelling.

##### Confidence & re-verify trigger

**High architectural confidence; medium metric confidence.** Re-verify on a `thiserror` major release, MSRV increase above the project floor, RustSec advisory, or evidence that R66 needs source-span diagnostics in the core model.

##### Sources

| Figure | Value | Canonical endpoint / evidence | Retrieval |
|---|---:|---|---|
| 90-day downloads | **Not captured; refresh required** | `GET https://crates.io/api/v1/crates/thiserror` → `crate.recent_downloads` | September 9, 2026 |
| All-time downloads | 1,332,222,355, corroborated by registry mirror | Same crates.io endpoint; mirror evidence ([openapps.pro](https://openapps.pro/packages/thiserror)) | September 9, 2026 |
| Last non-yanked release | 2.0.20, August 8, 2026 | `GET https://crates.io/api/v1/crates/thiserror/versions`; docs.rs corroboration ([docs.rs](https://docs.rs/crate/thiserror/latest)) | September 9, 2026 |
| Stars | 5,530 in docs.rs GitHub snapshot | `GET https://api.github.com/repos/dtolnay/thiserror`; corroboration ([docs.rs](https://docs.rs/crate/thiserror/latest)) | September 9, 2026 |
| Archived | Direct API field not captured; repository is releasing and running CI | Same repository endpoint; activity evidence ([github.com](https://github.com/dtolnay/thiserror/releases)) | September 9, 2026 |
| `pushed_at` | Not captured | Same repository endpoint | September 9, 2026 |
| Open issues | 27 | `GET https://api.github.com/search/issues?q=repo:dtolnay/thiserror+is:issue+is:open`; repository corroboration ([github.com](https://github.com/dtolnay/thiserror/actions)) | September 9, 2026 |
| Issue responsiveness | Not measured; required API sample was unavailable | 10 newest issues plus comments/events | September 9, 2026 |
| Advisories | 0 open package advisories found in search; confirm with `cargo deny` | `https://rustsec.org/packages/thiserror.html` | September 9, 2026 |
| Maintenance | **active** | Recent signed release and continuing CI ([github.com](https://github.com/dtolnay/thiserror/releases)) | September 9, 2026 |
| Adopters | Aggregate evidence: 58,094 crates, 23,128 direct; strict named-adopter Cargo.toml check remains open | Reverse-dependency evidence ([lib.rs](https://lib.rs/crates/thiserror)) | September 9, 2026 |

#### signal-hook 0.4.4

##### Landscape

`signal-hook` is the established safe façade for Unix signal handling, with flag, channel, iterator, and lower-level adapters. Its documentation focuses explicitly on the global-resource and async-signal-safety constraints that make handwritten handlers risky. ([docs.rs](https://docs.rs/crate/signal-hook/latest)) Retrieved September 9, 2026.

##### Principles and implementation

Use it only in Unix executable targets. Register SIGINT and SIGTERM before worker threads, consume notifications in normal Rust code, and translate them to a runtime-neutral internal `ShutdownSignal`.

Fitness gates:

| Gate | Result |
|---|---|
| License | **Pass:** MIT OR Apache-2.0. |
| MSRV | **Pass:** Rust 1.66, below project MSRV 1.96. |
| Advisories / unsafe | **Pass with CI confirmation:** no open advisory surfaced; implementation necessarily contains platform `unsafe`/libc code, exposed through safe high-level APIs. |
| Ubuntu/macOS | **Pass subject to template integration test:** both are Unix targets; upstream has active test and security-audit workflows. |
| Features/runtime | Recommend `default-features = false, features = ["iterator"]`; iterator enables channel. No async-runtime coupling. |
| Size/compile | Low binary/compile impact; iterator design may use one helper thread at runtime. |

The manifest declares Rust 1.66, dual licensing, and default channel/iterator features. ([github.com](https://github.com/vorner/signal-hook/blob/master/Cargo.toml)) Retrieved September 9, 2026.

##### Dominant choice

It is the best fit where the executable must distinguish SIGINT from SIGTERM without binding the contract to Tokio or another async runtime.

##### Qualified shortlist

- A runtime-native signal module for the web-service binary, if its runtime is already fixed.
- `ctrlc` for applications needing only a unified Ctrl-C callback.
- A standard-library default-signal approach when no clean message, cancellation, or graceful shutdown is required.

##### Excluded by gate

- The legacy `tokio-signal` crate is excluded by the no-open-advisory/maintenance gate: RustSec lists it as unmaintained. This exclusion does **not** apply to the maintained `tokio::signal` module. ([rustsec.org](https://rustsec.org/advisories/)) Retrieved September 9, 2026.
- A std-only clean SIGINT/SIGTERM handler fails the capability gate because stable `std` does not provide general registration.

##### Up-and-comers

Runtime-neutral cancellation abstractions can sit above signal delivery, but they do not replace OS registration. A future stabilized Rust signal API would supersede this member.

##### Fit for this template

Strong for Ubuntu/macOS:

- separate SIGINT/SIGTERM identity;
- no mandatory async runtime;
- library remains free of global handlers;
- service and CLI can feed the same cancellation abstraction.

##### Recommendation

Use:

```toml
signal-hook = {
  version = "0.4.4",
  default-features = false,
  features = ["iterator"]
}
```

Register only SIGINT and SIGTERM. Do not register SIGPIPE in this member.

##### Ranked runner-up

A runtime-native signal adapter in the web-service executable. It may have lower integration overhead there, but it cannot serve a runtime-neutral synchronous CLI unless the CLI already uses that runtime.

##### Tradeoffs

- Signals are process-global.
- Iterator integration may consume a helper thread.
- Cooperative cancellation cannot interrupt arbitrary permanently blocking code unless the operation itself supports cancellation or timeouts.
- Windows behavior would need a separate adapter if Windows later enters the required matrix.

##### Parameters

Contributes:

```text
SIGINT = ErrorCode::Interrupted, CliExitCode::SigInt(130)
SIGTERM = ErrorCode::Terminated, CliExitCode::SigTerm(143)
handler ownership = executable only
```

##### Migration implications

- Add `src/cli/signals.rs` or `src/runtime/signals.rs`.
- Pass a cancellation receiver/token into command and service runners.
- Replace direct `process::exit` inside callbacks with normal outcome propagation.
- Ensure the library crate has no `signal-hook` dependency unless a private binary-support feature requires it.

##### Validation strategy

Planned Unix integration fixture:

```bash
cargo build --workspace

target/debug/rs-launch-blueprint test-support wait &
pid=$!
kill -INT "$pid"
wait "$pid"
test "$?" -eq 130

target/debug/rs-launch-blueprint test-support wait &
pid=$!
kill -TERM "$pid"
wait "$pid"
test "$?" -eq 143
```

Separate JSON-mode assertions verify one clean stderr envelope and no stdout.

##### Confidence & re-verify trigger

**High functional confidence, medium upstream-platform-evidence confidence.** Re-verify on a RustSec advisory, `signal-hook` 0.5, addition of Windows to the matrix, selection of an async runtime that makes a second signal stack unnecessary, or stabilization of a standard Rust signal API.

##### Sources

| Figure | Value | Canonical endpoint / evidence | Retrieval |
|---|---:|---|---|
| 90-day downloads | **Not captured; refresh required** | `GET https://crates.io/api/v1/crates/signal-hook` → `crate.recent_downloads` | September 9, 2026 |
| All-time downloads | 220,924,572, corroborated by registry mirror | Same crates.io endpoint; mirror evidence ([openapps.pro](https://openapps.pro/packages/signal-hook)) | September 9, 2026 |
| Last non-yanked release | 0.4.4, April 4, 2026 | `GET https://crates.io/api/v1/crates/signal-hook/versions`; docs.rs corroboration ([docs.rs](https://docs.rs/crate/signal-hook/latest)) | September 9, 2026 |
| Stars | 864 in docs.rs snapshot | `GET https://api.github.com/repos/vorner/signal-hook`; corroboration ([docs.rs](https://docs.rs/crate/signal-hook/latest)) | September 9, 2026 |
| Archived | Direct API field not captured; repository has current workflows/releases | Same repository endpoint ([github.com](https://github.com/vorner/signal-hook/actions)) | September 9, 2026 |
| `pushed_at` | Not captured | Same repository endpoint | September 9, 2026 |
| Open issues | 22 | `GET https://api.github.com/search/issues?q=repo:vorner/signal-hook+is:issue+is:open`; corroboration ([github.com](https://github.com/vorner/signal-hook/issues)) | September 9, 2026 |
| Issue responsiveness | Not measured; only a partial issue list was retrievable | 10 newest issues plus comments/events | September 9, 2026 |
| Advisories | 0 open package advisories found in search; confirm with `cargo deny` | `https://rustsec.org/packages/signal-hook.html` | September 9, 2026 |
| Maintenance | **active** | Release within six months, actively-developed badge, test and audit workflows ([github.com](https://github.com/vorner/signal-hook/blob/master/Cargo.toml)) | September 9, 2026 |
| Adopters | Mirror names CubeSandbox, PostgresML, and Trieve; strict direct-Cargo.toml verification remains open | Reverse-dependency/application evidence ([openapps.pro](https://openapps.pro/packages/signal-hook)) | September 9, 2026 |

#### Rust std contract layer — MSRV 1.96

##### Landscape

This is a project-owned pattern assembled from stable standard-library APIs: `Error`, `ExitCode`, `Termination`, `Write`, `ErrorKind::BrokenPipe`, `Backtrace`, panic hooks, `SystemTime`, and `OpenOptions`.

At the research date, fetched standard-library documentation reported Rust 1.98.1; applying the owner-fixed “stable minus two minor versions” rule gives an initial declared `rust-version = "1.96"`. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html)) Retrieved September 9, 2026.

##### Principles and implementation

The core declaration should resemble:

```rust
macro_rules! define_error_catalog {
    ($(
        $variant:ident => {
            wire: $wire:literal,
            exit: $exit:ident,
            summary: $summary:literal
        }
    ),+ $(,)?) => {
        #[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
        #[non_exhaustive]
        pub enum ErrorCode {
            $($variant),+
        }

        impl ErrorCode {
            pub const ALL: &'static [Self] = &[$(Self::$variant),+];

            pub const fn as_str(self) -> &'static str {
                match self {
                    $(Self::$variant => $wire),+
                }
            }

            pub const fn exit_code(self) -> CliExitCode {
                match self {
                    $(Self::$variant => CliExitCode::$exit),+
                }
            }
        }
    };
}
```

This makes the wire literal explicit while generating all local mappings from one declaration.

##### Dominant choice

A small explicit contract layer is preferable to a crate for:

- eight exit constants;
- fewer than two dozen catalog values;
- one EPIPE branch;
- one best-effort file append.

The difficult part is governance and test coverage, not boilerplate volume.

##### Qualified shortlist

- `strum` for enum iteration/string conversion.
- `miette::Diagnostic` for code/help/source-span metadata.
- `exitcode` or `proc-exit` for named process constants.
- `pipecheck` for restoring signal-like broken-pipe behavior.

All still require project-specific code allocation, semantic mapping, and compatibility policy.

##### Excluded by gate

- Variant/type-name-derived code: fails the stable-protocol gate.
- Numeric discriminant as wire code: fails decoupling and evolution gates.
- Global SIGPIPE restoration: fails combined CLI/web-service fit.
- Fixed crash path independent of R57: fails ownership/integration fit.
- Writing crash logs from the reusable library: fails side-effect isolation.
- Inlining hints into messages only: fails the structured-envelope capability.

##### Up-and-comers

`pipecheck` is useful for pure Unix text filters; `error-stack` is useful for rich contextual reports. Neither is the default because this template combines a library and web service with CLI output behavior. ([docs.rs](https://docs.rs/pipecheck/latest/pipecheck/)) Retrieved September 9, 2026.

##### Fit for this template

Excellent:

- no additional dependency for catalog, exits, EPIPE, or crash append;
- exact control over public protocol values;
- renderer and process policy remain outside domain logic;
- compatible with both synchronous and async surfaces;
- straightforward CI snapshots.

##### Recommendation

Implement one `error_contract` module as the sole source of codes and process mappings. Keep output formatting, signal receipt, prompt adaptation, and crash persistence in boundary modules.

##### Ranked runner-up

`miette 7.6.0` without `fancy`. It directly models unique diagnostic codes and help and has MSRV 1.70, but it is a larger reporting protocol and does not itself establish the append-only codebook or CLI exit taxonomy. ([docs.rs](https://docs.rs/miette/latest/miette/)) Retrieved September 9, 2026.

##### Tradeoffs

- Project owns the macro, documentation generator, and compatibility tests.
- `#[non_exhaustive]` means external consumers require a fallback arm.
- Internal coverage is enforced through generated mappings and `ALL`, not external compiler exhaustiveness.
- Crash-file locking across multiple simultaneous processes is not guaranteed without another crate; this is acceptable for best-effort fatal-process records.

##### Parameters

Contributes all concrete catalog values, hint semantics, exit values, EPIPE policy, and crash-persistence policy listed in the owned parameter below.

##### Migration implications

Create:

- `src/error/catalog.rs`
- `src/error/diagnostic.rs`
- `src/error/exit.rs`
- `src/cli/output.rs`
- `src/cli/entrypoint.rs`
- `src/cli/crash.rs`
- `docs/reference/error-codes.md`
- `docs/reference/error-codes.json`
- catalog and process integration tests.

##### Validation strategy

Planned:

```bash
cargo +1.96 check --workspace --all-targets
cargo +1.96 test --workspace
cargo +stable test --workspace
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo deny check advisories licenses
```

Additionally, an `xtask error-catalog --check` command must regenerate and compare the committed documentation/snapshot.

##### Confidence & re-verify trigger

**High.** Re-verify if Rust stabilizes an `on_broken_pipe` policy, changes default SIGPIPE handling, F301 changes backtrace capture/disclosure, or R57 declines to provide any state-directory capability.

##### Sources

Crate figures are **inapplicable**: this member is a project pattern over the Rust standard library, not a crate candidate. Relevant primary sources:

- `https://doc.rust-lang.org/std/process/trait.Termination.html`
- `https://doc.rust-lang.org/std/process/fn.exit.html`
- `https://doc.rust-lang.org/std/io/enum.ErrorKind.html`
- `https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html`
- `https://doc.rust-lang.org/cargo/reference/semver.html`
- `https://rust-lang.github.io/rfcs/2965-project-error-handling.html`
- `https://github.com/rust-lang/rust/issues/150588`

All retrieved September 9, 2026. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html))

### Compatibility

The members have no conflicting type or runtime ownership:

- `thiserror` generates ordinary standard-library error implementations.
- The catalog and exit layer consumes only those resulting error types.
- `signal-hook` is confined to Unix executables and communicates through a project-owned signal/cancellation enum.
- The library does not initialize `signal-hook`, output streams, or crash files.

Required version matrix:

| Rust | OS | `thiserror` | `signal-hook` | Features |
|---|---|---:|---:|---|
| 1.96 | Ubuntu latest | 2.0.20 | 0.4.4 | `iterator`, no defaults |
| 1.96 | macOS latest | 2.0.20 | 0.4.4 | `iterator`, no defaults |
| Current stable, presently 1.98.x | Ubuntu latest | 2.0.20 | 0.4.4 | same |
| Current stable | macOS latest | 2.0.20 | 0.4.4 | same |

**Execution status:** this matrix and the combined reference fixture are proposed, not run in this research environment. No maintained shared adopter was counted under the owner’s strict “reverse dependency plus direct Cargo.toml” rule. The matrix must pass before the dependency lock is accepted.

### Parameters

```text
owns error-taxonomy-exit-codes = error-contract/v1 {
  stack = [
    "thiserror@2.0.20",
    "signal-hook@0.4.4[target=unix,default-features=false,features=iterator]",
    "rust-std@msrv-1.96"
  ]

  code_source = "explicit project-owned ErrorCode catalog; wire code is ErrorCode::as_str(); never type/variant/discriminant derived"

  codes = {
    Unexpected = "PLBP000",
    Usage = "PLBP100",
    ConfigNotFound = "PLBP200",
    ConfigRead = "PLBP201",
    ConfigParse = "PLBP202",
    ConfigInvalid = "PLBP203",
    ConfigSecretDisallowed = "PLBP204",
    AuthRequired = "PLBP300",
    AuthRejected = "PLBP301",
    ResourceNotFound = "PLBP400",
    Conflict = "PLBP401",
    Transport = "PLBP500",
    RemoteApi = "PLBP501",
    Io = "PLBP600",
    BrokenPipe = "PLBP601",
    Interrupted = "PLBP700",
    Terminated = "PLBP701",
    PromptCancelled = "PLBP702"
  }

  envelope = {
    stderr_json = {"error":{"code":"<stable string>","message":"<concise string>","hint":"<optional actionable string>"}},
    hint_when_absent = "omit",
    stack_trace_in_json = false,
    stdout_on_error = "empty"
  }

  exits = {
    Success = 0,
    Failure = 1,
    Usage = 2,
    NotFound = 3,
    Auth = 4,
    Conflict = 5,
    SigInt = 130,
    SigTerm = 143
  }

  mappings = {
    Unexpected = Failure,
    Usage = Usage,
    ConfigNotFound = Usage,
    ConfigRead = Usage,
    ConfigParse = Usage,
    ConfigInvalid = Usage,
    ConfigSecretDisallowed = Usage,
    AuthRequired = Auth,
    AuthRejected = Auth,
    ResourceNotFound = NotFound,
    Conflict = Conflict,
    Transport = Failure,
    RemoteApi = Failure,
    Io = Failure,
    BrokenPipe = Failure,
    Interrupted = SigInt,
    Terminated = SigTerm,
    PromptCancelled = SigInt
  }

  signals = {
    SIGINT = {"code":"PLBP700","exit":130},
    SIGTERM = {"code":"PLBP701","exit":143},
    ownership = "executable boundary only"
  }

  prompt_cancel = {
    enabled_if = "R61 adopts interactive prompts",
    code = "PLBP702",
    exit = 130,
    detection = "typed prompt cancellation/interruption or recorded SIGINT; never string matching"
  }

  broken_pipe = {
    successful_stdout_epipe = {"diagnostic":"none","exit":0},
    other_epipe = {"code":"PLBP601","exit":1},
    mechanism = "fallible std::io::Write and ErrorKind::BrokenPipe; no global SIGPIPE handler"
  }

  crash_log = {
    enabled_for = "fatal process-boundary Unexpected errors and optional panic-hook records",
    behavior = "best-effort; failure never replaces primary error",
    path = "<R57 state-dir>/crash.log",
    fallback_path = "none",
    format = "sanitized NDJSON",
    unix_mode = "0600"
  }
}
```

```text
assumes R57/state-directory = "an optional per-application state-directory provider; this item does not select the platform path"
assumes R61/interactive-prompts = "if present, exposes a typed cancellation adapter; otherwise PromptCancelled remains reserved and unused"
CONFLICT: none
```

**Allocation guard:** before committing `PLBP100+`, compare against the full existing Python append-only catalog. Existing occupied codes win; they must not be renumbered or reassigned.

### Migration implications

| File/module | Change |
|---|---|
| `Cargo.toml` | Add `thiserror 2.0.20`; add Unix-only `signal-hook 0.4.4`; declare `rust-version = "1.96"`. |
| `src/error/catalog.rs` | Define the macro-generated catalog, `ErrorCode::ALL`, wire strings, lifecycle metadata, and exit mapping. |
| `src/error/exit.rs` | Define `CliExitCode` and `Termination` conversion. |
| `src/error/diagnostic.rs` | Define `CodedError`, `ErrorEnvelope`, hint semantics, and sanitized unexpected-error wrapper. |
| `src/error/config.rs` | Add codes needed by R52–R56 without deciding their degrade/fail behavior. |
| `src/error/domain.rs` | Add `ResourceNotFound` and `Conflict`; R03 decides when they arise. |
| `src/error/transport.rs` | Separate transport, remote API, generic I/O, and broken-pipe classifications. |
| `src/cli/entrypoint.rs` | Centralize rendering, crash persistence, cleanup, and final exit return. |
| `src/cli/signals.rs` | Translate SIGINT/SIGTERM into cooperative cancellation and final statuses. |
| `src/cli/output.rs` | Make every write fallible; render optional hint separately; classify stdout EPIPE. |
| `src/cli/crash.rs` | Add injected `CrashSink`, `NoopCrashSink`, and R57-backed `FileCrashSink`. |
| `src/cli/prompts.rs` | If R61 adopts prompts, translate typed cancellation to `PLBP702`/130. |
| `src/web/error.rs` | Expose `ErrorCode` to R70; do not put CLI exit numbers in HTTP responses. |
| `docs/reference/error-codes.md` | Document meaning, remediation, exit class, status, and introduction version. |
| `docs/reference/error-codes.json` | Machine-checkable append-only catalog snapshot. |
| `.github/workflows/ci.yml` | Test Rust 1.96 and stable on Ubuntu/macOS; add advisory/license and integration jobs. |

Downstream effects:

- **R03:** uses `ResourceNotFound`/3 versus `Transport`/1.
- **R52–R56:** use the five configuration codes, normally exit 2 when surfaced.
- **R70:** maps semantic `ErrorCode` variants to HTTP statuses independently of CLI exit values.
- **R66:** renders the same `code`/`message`/optional `hint`; JSON never includes a stack trace under the provisional F301 assumption.

### Validation strategy

All commands below are **planned**, not executed in this research run.

#### Dependency and MSRV proof

```bash
cargo +1.96 check --workspace --all-targets --all-features
cargo +1.96 test --workspace --all-features
cargo +stable test --workspace --all-features
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo deny check advisories licenses
```

Expected: all pass on both `ubuntu-latest` and `macos-latest`.

#### Catalog invariants

```bash
cargo test -p rs-launch-blueprint-core error_catalog
cargo run -p xtask -- error-catalog --check
```

Tests must prove:

- every code matches `^PLBP[0-9]{3}$`;
- wire strings are unique;
- all variants occur in `ErrorCode::ALL`;
- every code has an exit mapping;
- committed prior entries are unchanged;
- generated Markdown and JSON are current;
- an enum-variant rename test fixture retains the same wire string.

#### Error-envelope matrix

```bash
cargo test -p rs-launch-blueprint-cli --test error_contract
```

Expected fixture matrix:

| Scenario | Code | Exit | Stdout | Stderr |
|---|---:|---:|---|---|
| Unknown CLI flag | `PLBP100` | 2 | empty | one envelope |
| Explicit config missing | `PLBP200` | 2 | empty | one envelope |
| Invalid config | `PLBP203` | 2 | empty | one envelope with optional hint |
| Missing credential | `PLBP300` | 4 | empty | one envelope |
| Resource absent | `PLBP400` | 3 | empty | one envelope |
| Conflict | `PLBP401` | 5 | empty | one envelope |
| Transport failure | `PLBP500` | 1 | empty | one envelope |
| Unexpected error | `PLBP000` | 1 | empty | one envelope |

#### Signal checks

```bash
bash tests/scripts/sigint.sh target/debug/rs-launch-blueprint
bash tests/scripts/sigterm.sh target/debug/rs-launch-blueprint
```

Expected:

- SIGINT: status 130, `PLBP700`, no raw signal-library text.
- SIGTERM: status 143, `PLBP701`, graceful cleanup attempted.
- JSON mode: exactly one stderr JSON document.

#### Prompt checks, contingent on R61

Unit-test the adapter directly:

```rust
assert_eq!(
    classify_prompt_error(InquireError::OperationInterrupted),
    (ErrorCode::PromptCancelled, CliExitCode::SigInt)
);
```

Also test cancellation, EOF, and the console-backend SIGINT path.

#### Broken-pipe check

```bash
set +e
target/debug/rs-launch-blueprint test-support emit-many 2>epipe.err \
  | head -n 1 >/dev/null
statuses=("${PIPESTATUS[@]}")

test "${statuses[0]}" -eq 0
test "${statuses[1]}" -eq 0
test ! -s epipe.err
```

Expected: no panic text, no “broken pipe” diagnostic, producer status 0.

#### Crash persistence

```bash
tmp="$(mktemp -d)"
RS_LAUNCH_BLUEPRINT_TEST_STATE="$tmp" \
  target/debug/rs-launch-blueprint test-support unexpected \
  --format json 2>error.json
status=$?

test "$status" -eq 1
test -s "$tmp/crash.log"
test "$(stat -c '%a' "$tmp/crash.log" 2>/dev/null || stat -f '%Lp' "$tmp/crash.log")" = 600
jq -e 'select(.code == "PLBP000")' "$tmp/crash.log"
jq -e '.error.code == "PLBP000" and (.error | has("backtrace") | not)' error.json
```

Additional cases:

- an expected error creates no crash record;
- an unwritable state directory leaves the original code and exit unchanged;
- crash content contains no fixture token, environment secret, or configuration value;
- normal and JSON modes suppress traces;
- verbose human mode trace behavior follows the final F301 disposition.

#### Performance and integration measurements

```bash
cargo build --release
cargo tree --edges normal
cargo llvm-lines --release        # if installed
cargo bloat --release -n 30       # if installed
hyperfine \
  'target/release/rs-launch-blueprint test-support success' \
  'target/release/rs-launch-blueprint test-support classified-error'
```

Record:

- clean versus stack-enabled release-binary size;
- clean incremental compile time;
- idle signal-helper thread/resource usage;
- median SIGINT-to-process-exit latency;
- unexpected-error crash-write latency.

No throughput acceptance threshold should be set until these measurements are run on the same host and configuration.

#### Canonical ecosystem-metric refresh

```bash
for crate in thiserror signal-hook; do
  curl -fsSL \
    -H 'User-Agent: rs-launch-blueprint-research/1.0 (maintainer-contact)' \
    "https://crates.io/api/v1/crates/$crate" \
    > "$crate.crate.json"

  curl -fsSL \
    -H 'User-Agent: rs-launch-blueprint-research/1.0 (maintainer-contact)' \
    "https://crates.io/api/v1/crates/$crate/versions" \
    > "$crate.versions.json"
done

gh api repos/dtolnay/thiserror
gh api 'search/issues?q=repo:dtolnay/thiserror+is:issue+is:open'
gh api repos/vorner/signal-hook
gh api 'search/issues?q=repo:vorner/signal-hook+is:issue+is:open'
```

A small script must then inspect the ten most recently opened issues, find the first response by a maintainer/owner/member/collaborator, and report median days plus unanswered count.

### Confidence & re-verify trigger

**Recommendation confidence: high for architecture and observable behavior; medium-high overall.**

Strongest findings:

1. Stable machine codes must be explicit and independent of Rust type names.
2. Fine-grained `ErrorCode` and coarse `CliExitCode` should be separate.
3. The 0/1/2/3/4/5/130/143 taxonomy is more shell-composable than Python’s 0–5 interruption model.
4. `thiserror` plus a project-owned catalog is a better library/web fit than adopting a rich diagnostic renderer as the core model.
5. EPIPE should be classified at fallible stdout writes, not by a global signal policy.
6. Signal and crash-file side effects belong only at executable boundaries.

Re-verify before implementation if any of these occurs:

- the complete Python codebook collides with proposed `PLBP100+` allocations;
- F301’s owner disposition changes trace capture or JSON suppression;
- R57 provides no state-directory capability;
- R61 chooses a prompt crate without typed cancellation;
- Rust stabilizes `on_broken_pipe` or changes default SIGPIPE handling;
- Windows enters the required target matrix;
- `thiserror` or `signal-hook` publishes a major release, raises MSRV above 1.96, or receives a RustSec advisory;
- exact crates.io/GitHub metrics or the required adopter checks materially contradict the current maintenance assessment.

### Sources

All retrieved September 9, 2026 unless noted.

- Rust `Termination`: `https://doc.rust-lang.org/std/process/trait.Termination.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html))
- Rust `process::exit`: `https://doc.rust-lang.org/std/process/fn.exit.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/fn.exit.html))
- Rust `ErrorKind`: `https://doc.rust-lang.org/std/io/enum.ErrorKind.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/io/enum.ErrorKind.html))
- Rust `Backtrace`: `https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html` ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html))
- Cargo SemVer compatibility: `https://doc.rust-lang.org/cargo/reference/semver.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html))
- Rust RFC 2965: `https://rust-lang.github.io/rfcs/2965-project-error-handling.html` ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html))
- Rust API Guidelines, errors: `https://rust-lang.github.io/api-guidelines/interoperability.html` ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/interoperability.html))
- Rust SIGPIPE tracking: `https://github.com/rust-lang/rust/issues/150588` ([github.com](https://github.com/rust-lang/rust/issues/150588))
- Rust runtime SIGPIPE source: `https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs` ([github.com](https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs))
- POSIX.1-2024 shell exit statuses: `https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html` ([pubs.opengroup.org](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html))
- GNU Bash exit status: `https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html` ([gnu.org](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html))
- `thiserror` documentation: `https://docs.rs/thiserror/2.0.20/thiserror/` ([docs.rs](https://docs.rs/thiserror/latest/thiserror/))
- `thiserror` repository: `https://github.com/dtolnay/thiserror` ([github.com](https://github.com/dtolnay/thiserror))
- `signal-hook` documentation: `https://docs.rs/signal-hook/0.4.4/signal_hook/` ([docs.rs](https://docs.rs/crate/signal-hook/latest))
- `signal-hook` repository: `https://github.com/vorner/signal-hook` ([github.com](https://github.com/vorner/signal-hook))
- `miette::Diagnostic`: `https://docs.rs/miette/7.6.0/miette/trait.Diagnostic.html` ([docs.rs](https://docs.rs/miette/latest/miette/trait.Diagnostic.html))
- `clap::Error::exit_code`: `https://docs.rs/clap/latest/clap/error/struct.Error.html` ([docs.rs](https://docs.rs/clap/latest/clap/error/struct.Error.html))
- `inquire::InquireError`: `https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html` ([docs.rs](https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html))
- RFC 9457 extension members: `https://www.rfc-editor.org/rfc/rfc9457.html` ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9457.html))
- 2025 State of Rust Survey: `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- RustSec advisory index: `https://rustsec.org/advisories/` ([rustsec.org](https://rustsec.org/advisories/))

## Sources

- [https://doc.rust-lang.org/std/process/trait.Termination.html](https://doc.rust-lang.org/std/process/trait.Termination.html)
- [https://docs.rs/thiserror/latest/thiserror/](https://docs.rs/thiserror/latest/thiserror/)
- [https://lib.rs/crates/error-stack](https://lib.rs/crates/error-stack)
- [https://rust-lang.github.io/api-guidelines/interoperability.html](https://rust-lang.github.io/api-guidelines/interoperability.html)
- [https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://lib.rs/crates/thiserror](https://lib.rs/crates/thiserror)
- [https://docs.rs/miette/latest/miette/](https://docs.rs/miette/latest/miette/)
- [https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs](https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs)
- [https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html)
- [https://rust-lang.github.io/rfcs/2965-project-error-handling.html](https://rust-lang.github.io/rfcs/2965-project-error-handling.html)
- [https://doc.rust-lang.org/cargo/reference/semver.html](https://doc.rust-lang.org/cargo/reference/semver.html)
- [https://docs.rs/miette/latest/miette/trait.Diagnostic.html](https://docs.rs/miette/latest/miette/trait.Diagnostic.html)
- [https://docs.rs/clap/latest/clap/error/struct.Error.html](https://docs.rs/clap/latest/clap/error/struct.Error.html)
- [https://docs.rs/crate/signal-hook/latest](https://docs.rs/crate/signal-hook/latest)
- [https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html](https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html)
- [https://doc.rust-lang.org/std/io/enum.ErrorKind.html](https://doc.rust-lang.org/std/io/enum.ErrorKind.html)
- [https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html)
- [https://github.com/dtolnay/thiserror/blob/master/Cargo.toml](https://github.com/dtolnay/thiserror/blob/master/Cargo.toml)
- [https://openapps.pro/packages/thiserror](https://openapps.pro/packages/thiserror)
- [https://docs.rs/crate/thiserror/latest](https://docs.rs/crate/thiserror/latest)
- [https://github.com/dtolnay/thiserror/releases](https://github.com/dtolnay/thiserror/releases)
- [https://github.com/dtolnay/thiserror/actions](https://github.com/dtolnay/thiserror/actions)
- [https://github.com/vorner/signal-hook/blob/master/Cargo.toml](https://github.com/vorner/signal-hook/blob/master/Cargo.toml)
- [https://rustsec.org/advisories/](https://rustsec.org/advisories/)
- [https://openapps.pro/packages/signal-hook](https://openapps.pro/packages/signal-hook)
- [https://github.com/vorner/signal-hook/actions](https://github.com/vorner/signal-hook/actions)
- [https://github.com/vorner/signal-hook/issues](https://github.com/vorner/signal-hook/issues)
- [https://docs.rs/pipecheck/latest/pipecheck/](https://docs.rs/pipecheck/latest/pipecheck/)
- [https://doc.rust-lang.org/std/process/fn.exit.html](https://doc.rust-lang.org/std/process/fn.exit.html)
- [https://github.com/rust-lang/rust/issues/150588](https://github.com/rust-lang/rust/issues/150588)
- [https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html)
- [https://github.com/dtolnay/thiserror](https://github.com/dtolnay/thiserror)
- [https://github.com/vorner/signal-hook](https://github.com/vorner/signal-hook)
- [https://www.rfc-editor.org/rfc/rfc9457.html](https://www.rfc-editor.org/rfc/rfc9457.html)