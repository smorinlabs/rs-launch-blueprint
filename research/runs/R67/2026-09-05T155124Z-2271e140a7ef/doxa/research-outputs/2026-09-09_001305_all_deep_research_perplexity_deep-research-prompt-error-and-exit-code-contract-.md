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
provider: perplexity
model: sonar-deep-research
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

# Error and Exit-Code Contract for `rs-launch-blueprint`: Crate Stack and Taxonomy Design

The error and exit-code contract for `rs-launch-blueprint` must unify three concerns that span the CLI, library, and web service surfaces: a stable, append-only machine-readable error code catalog, a principled exit-code taxonomy including signal and interactive cancellation handling, and a crash-log persistence strategy that fits Rust’s ecosystem while respecting the precedent from the Python and TypeScript ports. The design proposed here adopts a stable string error-code catalog similar to Python’s, embeds those codes as typed metadata on Rust error enums using `thiserror`, uses `anyhow` for application-level error propagation, and employs `ctrlc`-style signal handling with Broken Pipe awareness and a best-effort crash-log writer. This bundle preserves cross-repo agreement at the level of architectural patterns and observable behavior rather than forcing identical low-level mechanisms across ecosystems. It yields a single, named `error-taxonomy-exit-codes` parameter that downstream items (R03, R52–R56, R70) can match against deterministically, while allowing Rust to express richer type-level structure for domain errors and signal-aware exit codes. Where this differs from Python or TypeScript precedent, the report explicitly records `BASELINE-REVIEW` findings and the evidence that motivates the proposed alignment or justified divergence.

## Context and Background

The owner’s mandate for this item emphasizes that error-handling designs must be chosen not merely for familiarity or performance, but for their ability to express and preserve shared engineering principles across the Python, TypeScript, and Rust ports of the launch blueprint. The relevant context documents that Python employs a stable string catalog for its error `code` field, exemplified by constants such as `ERROR_CODE_UNEXPECTED = "PLBP000"`, and that this catalog is append-only and documented for machine consumers.[Context, py repo] TypeScript, by contrast, currently derives its `code` field from the thrown exception’s class name, effectively using a transient identifier whose stability is tied to internal type naming rather than an explicit catalog; this decision was influenced by JavaScript’s exception model and the external CLI standards spec that guided exit codes and JSON error envelopes.[Context, ts repo] The divergence between these two approaches is recorded in the ledger items F295–F302 with verdict `DIVERGENT`, and this report must treat those entries as evidence rather than predetermined winners.

The Rust port sits within a defined parameter matrix: it targets Rust edition 2024 with a minimum supported Rust version of “stable minus two minor versions,” carries a dual MIT OR Apache-2.0 license, and must be CI-tested on `ubuntu-latest` and `macos-latest`.[PARAMETERS.md] Within this matrix, the template must support three surfaces—a CLI, a shared library crate, and a web service—while exposing a JSON error envelope on stderr in machine mode and controlling when stack traces are shown. The existence of the machine-readable error envelope and the rule that full stack traces are printed only under verbose or debug modes are settled and out of scope for this item; the focus is instead on the semantics of the envelope’s `code` field, the optional structured `hint` field, the exit-code taxonomy used when the process terminates, and the handling of signals, interactive prompt cancellation, broken pipes, and crash logging as they feed into or supplement that taxonomy.

The prior decisions of the TypeScript port provide key evidence about how a CLI-standards spec shaped exit codes and signal behavior. Decision D-016(2) reconciled source exit codes with an external R6.1 contract, yielding a taxonomy of `success/error/usage/notFound/auth/conflict/sigint/sigterm` mapped to numeric codes 0, 1, 2, 3, 4, 5, 130, and 143. In addition, the TypeScript port introduced an EPIPE handler to avoid crashes when downstream consumers close a pipe early and formalized a machine-output envelope where stdout carries a single JSON result document and stderr emits a compact error object with `code` and `message` fields in machine mode.[Context, ts decisions] Decision D-033 further refined the behavior of interactive prompts, ensuring that prompt interruption or stdin closure lead to exit code 130 with a clean message that does not leak internal library details.

Python’s precedent diverges in several respects. Its exit-code taxonomy, expressed as an `IntEnum` with variants such as `SUCCESS`, `CONFIG`, `AUTH`, `API`, `IO`, and `INTERRUPT` mapped to 0–5, favors domain categories over CLI-standards codes. Python handles `KeyboardInterrupt` by exiting with `ExitCode.INTERRUPT` (5) but does not distinguish `SIGTERM` separately, nor does it currently have an EPIPE handler or interactive multi-select cancellation semantics. Conversely, Python does implement crash-log persistence, writing unexpected error details to a best-effort crash log under a state directory (for example `plbp_crash.log` under `<state>/plbp`) as described in ADR 0006.[Context, py code] These differences are central to the baseline review and will be revisited when establishing principles and recommendations for the Rust template.

Given this background, the Rust design must be grounded in the ecosystem’s own idioms and tooling for error handling and signals—specifically crates like `thiserror`, `anyhow`, `ctrlc`, and `signal-hook`—while also respecting the owner’s scope boundaries for related contracts, such as R03’s absence-vs-failure behavior, R54–R56’s config error tolerance patterns, and R70’s HTTP problem envelope mapping. It is essential to articulate clearly which aspects of the error and exit-code contract must agree across languages, and which may vary to better match the differing ecosystems, while nonetheless preserving a coherent architectural story and machine interface for consumers.

## Main Bundle Analysis

### Landscape

The category this item decides can be described as “Rust error taxonomy and exit-code stack for a multi-surface template,” encompassing domain error modeling, application-level error propagation, process exit codes, signal handling, broken-pipe behavior, and crash-log capture. In Rust, this category spans both language-level constructs and community-standard crates. To follow the required survey method, the landscape must first be mapped into three bins: built-in or first-party toolchain features, established industry standards, and up-and-comers.

At the built-in or first-party level, Rust’s `Result<T, E>` type, `std::error::Error` trait, and common error types like `std::io::Error` form the foundation of all error handling. The Rust Patterns & Engineering How-Tos produced by Microsoft explicitly frame error handling patterns around `Result<T, E>` and the distinction between concrete error enums and trait-object based application errors.[6] These built-in pieces are non-negotiable: any crate-level or architectural choice must integrate with them. The standard library also provides the mechanisms that surface broken pipe errors as `io::Error` with `ErrorKind::BrokenPipe`, and signal behavior via POSIX semantics, though Rust’s default disposition for `SIGPIPE` differs from C programs in that it tends to translate `SIGPIPE` into `BrokenPipe` errors rather than killing the process.[General Rust docs] While Rust’s standard library offers only limited direct signal handling, the crates considered below build on the underlying OS APIs.

In the established industry-standard bin, the error-handling crates `thiserror` and `anyhow` stand out. The `thiserror` crate provides derive macros that implement `Display` and the `Error` trait for custom error types, along with useful attributes such as `#[error("...")]`, `#[from]`, and `#[error(transparent)]` to model error variants compactly and idiomatically.[1][3][4][15] It is designed for defining structured error types, particularly in library code, and is widely considered lightweight and zero-cost, generating code equivalent to what a developer would write manually.[4][15] The Rust FAQ emphasizes that `thiserror` “deletes the boilerplate,” allowing developers to focus on error taxonomy rather than glue code, and notes that it is stable and widely used in the ecosystem.[3] The `anyhow` crate complements `thiserror` by providing a single trait-object based error type (`anyhow::Error`) and a convenient `anyhow::Result<T>` alias for application errors; it is intended for binaries and CLI tools where the caller does not need to pattern-match on structured error variants.[2][4][6][7] The Rust FAQ and Microsoft’s Rust Patterns documentation both highlight the pairing of `thiserror` for libraries and `anyhow` for applications as a dominant pattern.[6][7]

In signal handling, the `ctrlc` crate has become an established standard for cross-platform `Ctrl-C` (SIGINT) handling in Rust applications.[5][9][10] Its `set_handler` function allows registering a closure that executes when the user presses Ctrl-C, and with the `termination` feature enabled it can also handle `SIGTERM` and `SIGHUP` on Unix.[5][9][10] This crate abstracts over platform-specific signal APIs, including Unix signals (`SIGINT`), Windows console control events (`CTRL_C_EVENT` and `CTRL_BREAK_EVENT`), and Apple’s dispatch mechanisms, providing a single API that works across operating systems.[10] For more comprehensive Unix signal handling, the `signal-hook` crate and its backend `signal-hook-registry` offer a global registry of actions for signal arrival.[16][17][12][19] `signal-hook-registry` is specifically described as the backend that multiplexes signals, ensuring that an application contains just one version of the crate to manage this global resource.[12] Signal-hook supports registering multiple actions for the same signal, chaining previous handlers, and providing helper actions for common use cases.[16][17][19] These crates are widely adopted in Unix-focused applications needing robust signal handling.

The up-and-comers bin contains more specialized or stylistic crates that build on or extend the basic patterns established by `thiserror` and `anyhow`. Examples include crates that provide richer diagnostic information (such as human-readable error reports with color and context) or alternative structured error modeling frameworks. While the present search results do not enumerate these explicitly, the existence of such crates is referenced indirectly in discussions that compare `thiserror` and `anyhow` to other solutions, emphasizing that the former focus on idiomatic error enums and trait-object errors rather than more elaborate diagnostic systems.[4][6] In signal handling, up-and-comer patterns include integrating signal-hook with async runtimes to process signals in asynchronous streams, as described in the rust-cli DeepWiki, which shows how to convert a `Signals` instance into an async stream and integrate it with `select!`-based logic in async applications.[8] These patterns are relevant primarily for web services or highly concurrent CLIs.

Regarding authoritative sources, the documentation for `thiserror` and `thiserror-impl` maintained by David Tolnay on docs.rs and on crates.io is authoritative, as it comes directly from the crate maintainer and describes the intended use, supported attributes, and version information.[1][4][11][14][15] The Rust FAQ entries on `thiserror` and `anyhow` are written for developers seeking guidance on idiomatic error handling and emphasize ecosystem norms, which makes them a strong authority on practice.[3][7] The Microsoft Rust Patterns & Engineering How-Tos are backed by Microsoft’s Rust engineering team and present well-considered patterns for error handling in production-grade Rust systems, explicitly recommending `thiserror` for libraries and `anyhow` for applications.[6] For signal handling, the `ctrlc` and `signal-hook` documentation on docs.rs and Lib.rs is authoritative, providing API descriptions, feature flags, and platform behavior.[5][9][12][16][17][19] The rust-cli DeepWiki’s section on signal handling is a widely cited independent write-up that synthesizes the usage of `ctrlc`, `signal-hook`, and related patterns in Rust CLI applications, which makes it a valuable practice-oriented source.[8]

Practice evidence about adoption must be weighed carefully. While full reverse-dependency lists and download counts require direct querying of crates.io APIs, the available data for `signal-hook-registry` shows that it has substantial monthly downloads (14,949,924 downloads per month as of the referenced Lib.rs page) and a recent release history, indicating active and widespread use.[12] The presence of `thiserror`, `anyhow`, `ctrlc`, and `signal-hook` in curated training materials (such as Microsoft’s patterns book and Google’s Comprehensive Rust course) and in Rust FAQs strongly suggests that these crates are part of mainstream, well-regarded practice.[1][4][6][7][8] Numerous open-source CLIs, web services, and libraries reference these crates in their documentation and code examples, although detailed adopter lists cannot be exhaustively enumerated within the constraints of the current search results. Nonetheless, the combination of maintainer documentation, educational material, and explicit ecosystem guidance forms a coherent picture: `thiserror` and `anyhow` dominate Rust’s structured error handling landscape, while `ctrlc` and signal-hook dominate signal handling in CLI and Unix-centric applications.

It is also crucial to judge candidates against the specific use case of `rs-launch-blueprint`: a template combining CLI, library, and web service surfaces. For such a template, the pairing of `thiserror` (for domain error enums exposed by the library and web service) and `anyhow` (for application-wide errors in the CLI) aligns with the recommended division of responsibility.[4][6][7] The need for cross-platform signal handling for a CLI that may run on Ubuntu and macOS makes `ctrlc` an appropriate choice; meanwhile, `signal-hook` is more relevant for advanced Unix-only scenarios or when multiple signals must be multiplexed with complex behavior.[5][8][16][17] Broken pipe handling relies primarily on the standard library’s behavior and patterns like checking `io::Error::kind()` against `ErrorKind::BrokenPipe`, as referenced in Rust CLI treatises.[8] Crash-log persistence does not require external crates beyond those already used for filesystem access, but it must integrate with any state directory decisions made elsewhere in the template (R57).

Collectively, this landscape situates `rs-launch-blueprint` as a consumer of both built-in error and signal primitives and a stack of established crates—primarily `thiserror`, `anyhow`, and `ctrlc`, with optional `signal-hook` for more advanced scenarios. The next sections will articulate the cross-repo principles and implementation patterns that this stack must satisfy, including the shape of the error code catalog and the exit-code taxonomy.

### Principles and Implementation

The shared requirement across Python, TypeScript, and Rust ports can be stated as follows: the launch blueprint must expose a consistent, machine-readable classification of failures that is stable over time, append-only, and documented, and that can be observed both in its JSON error envelope and in its process exit codes. This classification must separate human-facing messages from machine-facing codes, allow downstream consumers to pattern-match on logical error categories (for example configuration errors, authentication failures, resource absence, and transport failures), and provide predictable behavior for interrupts (Ctrl-C / SIGINT), termination signals (SIGTERM), interactive-prompt cancellation, broken pipes, and unexpected errors that warrant crash-logs. The agreement level is architectural pattern and policy rather than identical implementation detail: each ecosystem may use different language constructs and libraries, but must preserve the same high-level contract.

The essential behaviors, distilled from the context, are as follows. First, there must be a JSON error envelope on stderr in machine mode, containing at least a `code` field, a `message` field, and optionally a structured `hint` field that provides remedial guidance separate from the core error message. Python already implements such a separation, storing `self.hint` and rendering it separately from the message in CLI output.[Context, py code] TypeScript embeds remedy text directly into the error message and currently does not expose a separate `hint` field, though its JSON envelope includes an `error.code` and `error.message` structure.[Context, ts code] Second, there must be a stable error-code catalog whose codes are append-only and documented. Python uses strings like `PLBP000` for this purpose; TypeScript uses exception class names, which are stable only insofar as the class names are not changed. Third, a defined exit-code taxonomy must map logical error categories to numeric exit codes, including specific codes for `success`, `usage/config errors`, `notFound`, `auth`, `conflict`, and signal-induced termination (SIGINT and SIGTERM). The TypeScript port already adheres to an external CLI standards spec for these codes, adopting 0 for success, 1 for generic errors, 2 for usage, 3 for not found, 4 for auth, 5 for conflict, 130 for SIGINT, and 143 for SIGTERM.[Context, ts decisions] Python’s taxonomy differs, using an `IntEnum` with domain-focused codes 0–5, but lacking separate codes for SIGINT/SIGTERM beyond `INTERRUPT`.[Context, py code]

Fourth, the system must handle interrupts and signals deterministically. Ctrl-C during normal CLI operation must lead to a well-defined exit code (preferably 130, in line with Unix conventions and CLI standards), and SIGTERM, if relevant, must either be mapped to its own code (143) or be treated equivalently to SIGINT depending on the application’s operational model. Fifth, interactive prompt cancellation—such as ^C mid-prompt—must behave similarly to SIGINT, with exit code 130 and a clean message that reveals no internal library details, aligning with TypeScript’s D-033 decision. Sixth, broken pipe scenarios (EPIPE) must be handled so that downstream pipe readers can close early without causing a crash or noisy error output; the usual pattern is to treat writing to a closed pipe as an expected scenario and exit cleanly, often with code 0, or to suppress error reporting for broken pipes entirely. TypeScript achieves this by listening to `stdout` error events and ignoring EPIPE.[Context, ts code] Rust’s idiom, as documented in rust-cli resources, is to check for `ErrorKind::BrokenPipe` and avoid panic or noisy logging in that case.[8] Finally, unexpected errors must be persisted to a crash-log file as a best-effort record, preferably in a state directory determined by R57’s `xdg-directory-set` decision, following Python’s ADR 0006 precedent.[Context, py ADR]

These behaviors constitute the acceptance criteria for the Rust implementation. The Rust template must expose a stable error-code catalog accessible from domain error variants, map those codes to a documented exit-code taxonomy aligned with the CLI standards spec where appropriate, handle SIGINT and SIGTERM with specific codes using idiomatic Rust signal handling crates, detect and map interactive prompt cancellation to exit code 130, recognize broken pipe errors and suppress spurious reporting, and persist unexpected errors to a crash-log file when possible. Observable acceptance criteria include the ability for downstream items—R03’s absence/failure contract, R52–R56’s config error handling, and R70’s HTTP status mapping—to pattern-match on a well-defined set of error variants and codes, and for automated tools to rely on exit codes for control flow.

Within this framework, we must define the shape of the error code catalog in Rust. The central question is whether the `code` field in the JSON envelope should be a stable string catalog (like Python’s `PLBP000`) or a value derived from a Rust error enum’s variant name or discriminant, akin to TypeScript’s exception class name. A stable string catalog has the advantage of being explicitly documented, language-agnostic, and decoupled from internal naming; it can remain stable even if the Rust enum is refactored, provided the code strings are not changed. This aligns with Python’s approach and with general practices in API design, where error codes are treated as part of the public contract. Conversely, deriving codes from enum variant names or discriminants risks accidental changes when refactoring and ties the codes to Rust-specific naming conventions, making cross-language reuse harder.

Rust’s ecosystem, however, favors strongly typed error enums with derive macros. The `thiserror` crate allows us to define enums with distinct variants, each annotated with an error message and optionally `#[from]` attributes for automatic conversion from inner error types.[1][3][4][15] It also supports transparent wrapping of inner errors when we want to preserve their display and source. The Rust FAQ suggests using `thiserror` for library error types in order to define clear, expressive error models that callers can pattern-match on.[3][4] Therefore, the architectural pattern that best preserves cross-repo principles is to adopt a stable string code catalog, but attach those codes as properties of a typed Rust error enum. This can be implemented by defining a dedicated `ErrorCode` type (for example a newtype around a string) and associating it with each variant of a domain error enum via methods or attributes. `thiserror` can supply the `Error` and `Display` implementations, while additional traits or helper functions expose the code string for use in the JSON envelope and exit-code mapping.

On the application side, the `anyhow` crate is the idiomatic choice for errors in binaries. It provides `anyhow::Error`, which can wrap any error that implements `std::error::Error`, allowing the `?` operator to propagate errors without additional glue code.[2][6][7] Its `anyhow::Result<T>` alias simplifies function signatures. The Rust FAQ notes that `anyhow::Error` functions like a universal adapter, wrapping errors from various sources and presenting a uniform interface.[7] In our context, the CLI entrypoint can use `anyhow::Result<()>` and convert domain errors into the structured JSON envelope and exit-code taxonomy, while unexpected errors (for example those not matching the domain enum) are treated as crash-worthy, recorded in a crash-log, and mapped to a generic error code and exit code 1.

Signal handling in Rust must be implemented using established crates like `ctrlc` or `signal-hook`. The `ctrlc` crate provides cross-platform handling of Ctrl-C via `set_handler`, starting a dedicated signal-handling thread to execute the registered closure on `SIGINT`.[5][9][10] When the `termination` feature is enabled, the same handler also runs on `SIGTERM` and `SIGHUP` on Unix.[5][9][10] The rust-cli DeepWiki recommends patterns such as using an `Arc<AtomicBool>` shared between threads and setting it to `true` in the signal handler, while periodically checking it in application loops to initiate graceful shutdown.[8] For applications that need to handle multiple signals in a more granular way, the `signal-hook` crate allows registering multiple actions per signal, chaining previous handlers, and removing handlers via IDs.[16][17][19] For `rs-launch-blueprint`, which is primarily a CLI template rather than a long-running daemon, the simpler `ctrlc` pattern suffices and aligns with cross-platform constraint, while `signal-hook` can be considered an up-and-comer for future web-service extension scenarios.

Broken pipe handling relies primarily on the standard library. As described in Rust CLI documentation, one idiom is to create a bounded channel and set up a signal handler that sends a message when a signal is received, selecting between normal work and signal events.[8] For broken pipes, however, the pattern is simpler: check whether write operations to `stdout` or `stderr` fail with `ErrorKind::BrokenPipe` and, if so, exit cleanly without printing an error message. This ensures that downstream tools like `head` can close the pipe early without causing the CLI to emit noisy failure output or crash. Node’s default behavior requires an explicit EPIPE handler, whereas Rust’s translation of `SIGPIPE` to `BrokenPipe` exceptions moves the logic into error handling rather than signal handling. 

Crash-log persistence must integrate with the template’s state-directory decisions. Python’s ADR 0006 defines a crash-log file under a state directory, and the Python CLI writes unexpected errors there as a best-effort append.[Context, py ADR] Rust can follow the same principle by using a function that locates the state directory (the answer to R57, or a default path if R57 is not yet decided), constructing a crash-log file path, and writing serialized error information when unexpected errors occur. This crash-log writer should be robust to IO failures (for example, it should fail silently if the directory is not writable) and should never prevent the process from exiting. The existence of this mechanism, rather than the precise path, is the principle that must be preserved.

Finally, it is necessary to distinguish shared architectural patterns from permissible ecosystem differences. The shared pattern is a stable error-code catalog, a JSON error envelope, a documented exit-code taxonomy, and specific behaviors for signals, interactive cancellation, broken pipes, and crash logs. Ecosystem differences may include the physical representation of codes (strings vs enum names), the precise numeric values chosen for exit codes, or the use of dynamic error types vs structured enums. For `rs-launch-blueprint`, adopting Python’s stable string catalog shape with Rust’s typed error enums and TypeScript’s CLI-standards exit codes is a way to reconcile these differences while preserving the shared principles. This leads to several baseline-review findings, which will be stated explicitly:

BASELINE-REVIEW: F295 — error code field shape — proposed change: adopt a stable, documented string catalog across all three ecosystems, rather than deriving codes from exception class names, while allowing Rust to express codes as typed properties on error enums; evidence: Python’s explicit catalog (`PLBP000` etc.) and the CLI standards’ emphasis on stable machine codes, contrasted with TypeScript’s use of exception names, which are less robust as a public interface.

BASELINE-REVIEW: F296 — structured hint field — proposed change: preserve Python’s separate `hint` field as a cross-ecosystem principle and extend TypeScript to adopt a structured hint alongside message, recognizing that inline remedy text conflates human-readable message with machine-readable guidance; evidence: Python’s separation of hint rendering in CLI output and the benefits of allowing different output formats (for example JSON vs human) to treat hints differently.

BASELINE-REVIEW: F297/F298/F299/F300/F302 — exit codes, interrupt handling, interactive cancellation, broken pipes, crash logs — proposed change: align Rust with TypeScript’s CLI-standards numeric exit codes for success, usage, not-found, auth, conflict, and signals, while preserving Python’s crash-log persistence principle as a cross-ecosystem behavior and adding broken pipe handling similar to TypeScript’s EPIPE suppression; evidence: TypeScript’s D-016(2) and D-033 decisions, Python’s ADR 0006, and typical Unix CLI conventions for exit codes 130 and 143.

These principles and baseline reviews frame the recommendations in the next sections.

### Recommendation

The recommended stack for `rs-launch-blueprint` can be summarized as a single cohesive design that combines error modeling, exit codes, signal handling, and crash logging. At its core, the Rust template should adopt a stable, append-only string error-code catalog, analogous to Python’s `PLBP000` pattern, but represented in Rust as a dedicated `ErrorCode` type and associated with a typed domain error enum that derives `thiserror::Error` and `Debug`.[1][3][4][15] Each variant of the domain error enum (for example `ConfigError`, `AuthError`, `ApiError`, `IoError`, `NotFound`, `Conflict`, `Interrupt`, `Unexpected`) should have an associated code string (such as `RSBP001` for config errors or `RSBP004` for auth errors) and an optional structured hint string. The catalog should be documented and append-only, with new codes added as new error variants are introduced, but existing codes never removed or repurposed.

The CLI entrypoint should use `anyhow::Result<()>` as its return type, allowing it to propagate errors from various subsystems using the `?` operator.[2][6][7] Where a domain error enum is returned, the CLI should downcast or otherwise recognize those errors and convert them into the JSON error envelope and exit-code taxonomy. Where an error is unexpected (that is, not part of the domain enum or representing a bug), the CLI should treat it as a generic “unexpected error,” map it to a reserved error code (for example `RSBP000`), capture its message and, optionally, stack trace in a crash-log file, and exit with code 1. This approach leverages `anyhow`’s convenience for propagation while preserving structured domain errors for pattern matching by downstream items like R03 and R70.[4][6][7]

The exit-code taxonomy should adopt the CLI-standards-aligned set used by TypeScript, with numeric codes 0 (success), 1 (generic error/unexpected), 2 (usage or configuration errors where the user’s invocation or config is invalid), 3 (resource not found, such as workspace missing), 4 (authentication or authorization failures), 5 (domain conflicts, such as attempting to create a resource that already exists), 130 (SIGINT / Ctrl-C), and 143 (SIGTERM).[Context, ts decisions] These codes should be expressed in Rust as a dedicated `ExitCode` enum with explicit numeric values, and maps should be defined from domain error variants to `ExitCode`. For example, `AppError::Config` maps to `ExitCode::Usage` (2), `AppError::NotFound` maps to `ExitCode::NotFound` (3), `AppError::Auth` maps to `ExitCode::Auth` (4), `AppError::Conflict` maps to `ExitCode::Conflict` (5), and `AppError::Api` or `AppError::Io` map to `ExitCode::Error` (1). Signals such as SIGINT and SIGTERM should be caught using `ctrlc` with the `termination` feature enabled, and the handler should cause the process to exit with codes 130 and 143 respectively.[5][9][10] Interactive prompts, if R61 adopts a prompt crate, should map cancellation errors or interruption signals to `ExitCode::Sigint` (130), ensuring consistent behavior.

Broken pipe handling should be implemented by inspecting errors from writes to `stdout` and `stderr`. If the error’s kind is `ErrorKind::BrokenPipe`, the CLI should suppress error reporting and exit cleanly, typically with `ExitCode::Success` (0). This ensures that when a user runs `rs-launch-blueprint-cli | head -n 10` and `head` closes the pipe, the CLI does not emit error messages or crash. This pattern matches TypeScript’s EPIPE handler, adjusted for Rust’s error-centric rather than signal-centric behavior.[8] For other IO errors, the usual mapping to `ExitCode::Error` (1) or domain-specific codes applies.

Crash-log persistence should follow Python’s ADR 0006 principle and be implemented as a best-effort writer that appends textual or JSON-formatted error information to a crash-log file under a state directory. The path to this state directory should be provided by R57’s `xdg-directory-set` decision when available; until then, the Rust template can assume a default state directory (for example under `$HOME/.rs-launch-blueprint/state`) and document this assumption. The crash-log writer should never panic or block exit; failures to write the crash log should be silently ignored or logged at a debug level.

The recommended stack of crates is therefore:

1. `thiserror = "2"` for defining domain error enums with structured variants and idiomatic `Error` and `Display` implementations.[1][3][4][15]  
2. `anyhow = "1"` for application-level error propagation in CLI and potentially in the web service’s entrypoints.[2][4][6][7]  
3. `ctrlc` (latest compatible release, with `termination` feature enabled) for cross-platform handling of Ctrl-C and Unix termination signals, mapping them to exit codes 130 and 143.[5][9][10]  

The `signal-hook` crate is recognized as a powerful alternative for Unix-specific signal handling, but for this template and its cross-platform, non-daemon focus, it is recommended as an up-and-comer rather than a primary dependency.[8][16][17][19] The stable Rust toolchain (`std`) provides broken pipe detection via `io::ErrorKind::BrokenPipe`, so no additional crate is necessary for EPIPE handling. Crash-log persistence can be implemented using `std::fs` and path utilities, integrating with the state-directory decision managed by R57.

This design yields a clear `error-taxonomy-exit-codes` parameter: a documented mapping from domain error codes (stable strings) and variants to exit codes and signal-driven exit behavior. Downstream items R03, R52–R56, and R70 can consume this parameter by matching on error codes or enum variants to determine HTTP statuses, config behavior, and absence-vs-failure semantics. The members of the stack are discussed in more detail in the following section.

### Members

#### Domain Error and Error-Code Catalog Module

##### Landscape

In Rust, the modeling of domain errors and their associated codes sits at the intersection of built-in language features and third-party crates. The landscape for this member includes the standard `Result<T, E>` type and `std::error::Error` trait as foundational elements, supplemented by struct and enum types that represent domain-specific failures. On the crate side, `thiserror` is the dominant library for deriving `Error` implementations for enums that model error taxonomies, while other crates like `snafu` and `derive_more` offer alternative approaches. The Rust FAQ and Microsoft’s Rust Patterns documentation both emphasize `thiserror` as the recommended choice for library error types, noting its idiomatic and zero-cost nature.[3][4][6][15] 

Beyond the choice of derive macro, the landscape includes patterns for associating metadata such as error codes and hints with error variants. Some projects embed codes directly in the error message; others define separate types or traits to expose codes. Crates like `strum` offer mechanisms to derive additional functionality for enums, such as string representations and properties. While explicit references to `strum` do not appear in the current search results, its use as a general-purpose enum helper is well-known in the Rust ecosystem. However, since the central requirement here is a stable string catalog, the design need not depend on `strum`; codes can be attached via manual implementations of a `ErrorCode` trait or associated functions. 

Authority for patterns in this space comes from the `thiserror` documentation, which shows how to derive error enums with `#[error("message")]` and `#[from]` attributes, and from practice-oriented write-ups that emphasize focusing on error taxonomy rather than boilerplate.[1][3][4][15] These sources establish that deriving `Error` for enums and treating them as the structured domain representation is standard practice. The existence of stable string error codes in Python’s implementation provides strong cross-language evidence that codes should be represented explicitly rather than derived from enum names.[Context, py code]

Practice evidence shows that many well-regarded Rust libraries expose custom error enums derived with `thiserror` and sometimes include code-like identifiers in their variants or messages. While full adopter lists are not available through the current search results, the inclusion of `thiserror` and its patterns in major training materials and FAQs implies widespread adoption.[1][3][4][6][15] The need for a stable catalog across ecosystems reinforces the choice of explicit codes attached to variants.

##### Principles and Implementation

The domain error and error-code catalog module must realize the principle of a stable, append-only catalog of machine-readable codes while leveraging Rust’s typed error enums. The core idea is to define a Rust enum `AppError` (or similar) that represents the domain error taxonomy for the template, and associate with each variant an `ErrorCode` value (a newtype around `&'static str`) and an optional `hint` string. The enum should derive `thiserror::Error` and `Debug`, with `#[error("...")]` attributes specifying the human-facing message for each variant.[1][3][4][15] 

An example might look as follows:

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("Configuration error: {details}")]
    Config {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("Authentication failed: {details}")]
    Auth {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("API request failed: {details}")]
    Api {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("I/O error: {source}")]
    Io {
        code: ErrorCode,
        hint: Option<String>,
        #[from]
        source: std::io::Error,
    },

    #[error("Resource not found: {details}")]
    NotFound {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("Conflict: {details}")]
    Conflict {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("Interrupted by signal")]
    Interrupt {
        code: ErrorCode,
        hint: Option<String>,
    },

    #[error("Unexpected error: {details}")]
    Unexpected {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },
}

#[derive(Clone, Copy, Debug)]
pub struct ErrorCode(&'static str);
```

In practice, we might omit the `code` and `hint` fields from each variant and instead implement methods on `AppError` that return a code and hint based on the variant. However, storing them as fields makes the design explicit and allows some variants to carry hints supplied by upstream code. The key point is that `ErrorCode` values such as `ErrorCode("RSBP001")` are defined in a dedicated catalog module and do not change once released. The catalog itself can be represented as a set of constants:

```rust
pub const ERROR_CONFIG_INVALID: ErrorCode = ErrorCode("RSBP001");
pub const ERROR_AUTH_FAILED: ErrorCode = ErrorCode("RSBP004");
// ...
```

And the `AppError` variants use these constants internally.

This design preserves the cross-repo principle of a stable catalog while exploiting Rust’s typed error enums. Downstream items such as R03 (absence vs failure) and R70 (HTTP problem envelope) can match on `AppError` variants or on `ErrorCode` values, depending on their needs. The JSON error envelope populates the `code` field from `ErrorCode` and the `message` field from `AppError`’s `Display` implementation. The optional `hint` field exposes remedy guidance separately from the message, aligning with Python’s pattern and enabling different output formats to handle hints differently.[Context, py code]

##### Dominant Choice

The dominant choice for this member is a domain error enum derived with `thiserror::Error` and a catalog of `ErrorCode` constants used to populate a `code` field in the JSON envelope. This combination aligns with authoritative guidance and mainstream practice: `thiserror` is recommended for library error types in Rust and is known to generate idiomatic and efficient code.[1][3][4][6][15] The explicit code catalog mirrors Python’s `PLBP000` approach, preserving cross-language stability while not over-constraining Rust’s error types.

##### Qualified Shortlist

Alternative patterns that satisfy the fitness gates include using `snafu` or similar crates for error enums, or deriving codes from enum variant names via helper traits. These alternatives can technically implement a stable catalog, but they either introduce additional complexity or tie codes to internal naming in ways that conflict with the owner’s preference for explicit, documented codes. Given that `thiserror` already integrates seamlessly with `std::error::Error` and is widely used, it remains the most appropriate choice in the shortlist.[3][4][6][15]

##### Excluded by Gate

No specific crate is excluded solely by licensing or RustSec concerns in this member, as `thiserror` is MIT-licensed and has no known RustSec advisories in the current search results.[15] However, patterns that derive codes implicitly from enum variant names are excluded by the principle gate rather than by legal or technical gates: they fail the requirement for a stable, documented catalog that is not accidentally changed by refactoring. 

##### Up-and-comers

Up-and-comer patterns include richer diagnostic crates that might embed codes and hints alongside styled error messages. While such crates could augment the developer experience, they are not strictly necessary for the core catalog and may add complexity. They can be considered in future revisions but are not recommended as part of the initial template stack.

##### Fit for This Template

This member’s design fits the template by providing a single, canonical domain error enum for the library and web service surfaces, with codes and hints that feed into the CLI’s JSON envelope and exit-code mapping. The `thiserror` derive macros avoid boilerplate in implementing `Error` and `Display`, while the manual code catalog gives precise control over the public interface.[1][3][4][15] The design is compatible with edition 2024 and should have an MSRV well within the “stable minus two minor versions” policy, given `thiserror`’ status as a widely used crate.[15]

##### Recommendation

The recommended implementation is to define an `AppError` enum derived with `thiserror::Error`, maintain a set of `ErrorCode` constants, and expose methods on `AppError` to return the associated code and hint. This ensures a stable catalog and structured domain error modeling.

##### Ranked Runner-up

The ranked runner-up is using a similar enum without `thiserror`, with manual implementations of `std::fmt::Display` and `std::error::Error`. This avoids third-party dependencies but reintroduces boilerplate and is less idiomatic. It may be used in environments where external crates are restricted, but for `rs-launch-blueprint` it is less desirable.

##### Tradeoffs

The main tradeoff in this design is between explicitness and flexibility. Storing code and hint fields directly in error variants can make the types more verbose, but it ensures that codes are always available and that hints can be customized. Using methods to derive codes can simplify the enum structure but makes the relationship between variants and codes more implicit. Overall, the design balances these concerns by keeping codes in a separate catalog module while exposing them through methods on the error enum.

##### Parameters

owns error-taxonomy-exit-codes = “Rust error taxonomy v1: stable string codes attached to `AppError` variants, mapped to CLI exit-code enum as described.”

There is no conflict with existing parameters; the design is compatible with R03, R52–R56, and R70’s needs for domain error mapping.

##### Migration Implications

For future alignment with Python and TypeScript ports, adopting this pattern may require those ecosystems to formalize their error code catalogs in ways similar to the Rust catalog, but such changes are a follow-on project. Internally, adding new error codes or variants must be done in an append-only fashion with thorough documentation.

##### Validation Strategy

Validation can be performed by writing unit tests that instantiate each `AppError` variant, generate the JSON error envelope, and assert that the `code` field matches the expected string and that `hint` appears separately. Integration tests can simulate CLI invocations that trigger different domain errors and verify that the envelope and exit codes align with the catalog.

##### Confidence & Re-verify Trigger

Confidence in this design is high, given `thiserror`’ ecosystem status and Python’s explicit catalog precedent.[3][4][15] Re-verification should be triggered by any major changes in `thiserror`’ behavior, new RustSec advisories, or owner directives that alter the catalog’s required shape.

##### Sources

This member’s design draws on `thiserror` documentation and Rust FAQ entries that describe its use for library error types, emphasizing its ability to derive `Error` implementations and remove boilerplate.[1][3][4][15] It also uses Python’s explicit string codes as cross-language evidence and the owner’s requirement for a stable catalog.

#### Exit-Code Enum and Mapping

##### Landscape

The exit-code enum and mapping member sits at the interface between domain errors and process termination behavior. The landscape includes Unix and CLI conventions for exit codes, the external CLI standards spec referenced in TypeScript decisions, Python’s `IntEnum` exit codes, and Rust’s own practices in CLI applications. TypeScript’s adoption of 0, 1, 2, 3, 4, 5, 130, and 143 for success, error, usage, notFound, auth, conflict, sigint, and sigterm was driven by external standards and is explicitly documented in D-016(2).[Context, ts decisions] Python’s `ExitCode(IntEnum)` variants 0–5 emphasize domain categories rather than CLI-specific codes.[Context, py code]

In Rust, there is no built-in exit-code enum; process exit codes are returned via `std::process::exit(code)` or by the implicit exit status of `main`. Rust CLI documentation often references Unix exit code conventions, including 0 for success and non-zero for failure, with specific codes sometimes borrowed from conventions such as that used by `bash`. Rust CLI patterns also emphasize capturing signals and mapping them to exit codes like 130 (SIGINT) and 143 (SIGTERM), consistent with TypeScript’s decisions.[8] 

##### Principles and Implementation

The exit-code enum must implement the principle of a stable mapping from domain error categories and signals to numeric exit codes, aligned with CLI standards where possible and consistent across ecosystems at the level of behavior. The Rust member should define an `ExitCode` enum with explicit numeric discriminants:

```rust
#[repr(i32)]
pub enum ExitCode {
    Success = 0,
    Error = 1,
    Usage = 2,
    NotFound = 3,
    Auth = 4,
    Conflict = 5,
    Sigint = 130,
    Sigterm = 143,
}
```

This enum is then used to map `AppError` variants and signals to exit codes. For example, `AppError::Config` maps to `ExitCode::Usage`, `AppError::NotFound` to `ExitCode::NotFound`, `AppError::Auth` to `ExitCode::Auth`, `AppError::Conflict` to `ExitCode::Conflict`, `AppError::Api` or `AppError::Io` to `ExitCode::Error`, and `AppError::Interrupt` to `ExitCode::Sigint`. Unexpected errors are mapped to `ExitCode::Error` and recorded in crash logs.

Signal handling via `ctrlc` ensures that when SIGINT or SIGTERM occurs, the appropriate `ExitCode::Sigint` or `ExitCode::Sigterm` is used. This mapping is consistent with TypeScript’s D-016(2) and with Unix conventions.[5][8][9] Python’s `ExitCode.INTERRUPT` (5) differs numerically but expresses a similar principle; the Rust design aligns with the CLI standards spec used by TypeScript to maximize cross-language agreement in behavior.

##### Dominant Choice

The dominant choice is to adopt the TypeScript exit-code taxonomy and numeric values, expressed as a Rust enum. This ensures consistency with the external CLI standards spec and cross-repo behavioral agreement. It also provides clear semantics for signals and domain error categories.

##### Qualified Shortlist

A qualified alternative would be to keep Python’s domain-focused codes (0–5) and add 130 and 143 for signals, but this would violate the external CLI standards spec used in TypeScript and potentially confuse users who expect standard exit codes. Therefore, the TypeScript-aligned mapping is preferred.

##### Excluded by Gate

No candidate is excluded by licensing or technical gates, since exit codes are not tied to external crates. Patterns that omit distinct codes for SIGINT and SIGTERM are excluded by principle, as they fail to capture the signal semantics emphasized in TypeScript and CLI standards.

##### Up-and-comers

There are no significant up-and-comer crates related to exit codes; this member is purely architectural.

##### Fit for This Template

This exit-code enum fits the template by providing a single, documented mapping that the CLI uses when terminating and that downstream items can rely on. It respects the Rust edition and MSRV constraints trivially, as it uses only language features.

##### Recommendation

The recommendation is to implement `ExitCode` as described and use it consistently across CLI, library, and web service surfaces where process exit behavior is relevant.

##### Ranked Runner-up

Using constants rather than an enum is a runner-up, but an enum is more expressive and type-safe.

##### Tradeoffs

The main tradeoff is between strict adherence to CLI standards and potential divergence from Python’s current codes. The design chooses standards-aligned codes, with Python pending a follow-on alignment project.

##### Parameters

owns error-taxonomy-exit-codes = “ExitCode enum values 0, 1, 2, 3, 4, 5, 130, 143 and their mapping from domain error variants.”

##### Migration Implications

Migrating other ecosystems to these codes would require updates to Python’s `ExitCode` enum and documentation, which is outside the scope of this item but is supported by the rationale here.

##### Validation Strategy

Tests can simulate various domain errors and signals, assert the exit codes used, and confirm that they match the enum values.

##### Confidence & Re-verify Trigger

Confidence is high; re-verification is triggered by any changes in external CLI standards or owner directives.

##### Sources

This design draws on TypeScript’s documented exit-code mapping and Unix CLI conventions, as well as rust-cli guidance on mapping signals to exit codes like 130 and 143.[8]

#### `thiserror` Crate

##### Landscape

The `thiserror` crate occupies the established industry standard bin for Rust error handling. Its documentation states that it provides a derive macro for the standard library’s `std::error::Error` trait, enabling developers to define error types with concise annotations.[1][15] It supports attributes like `#[error("message")]`, `#[from]`, and `#[error(transparent)]`, which generate implementations of `Display` and `Error` and the `From` traits needed for idiomatic propagation via the `?` operator.[1][3][4] The Rust FAQ underscores that `thiserror` deletes boilerplate, allowing engineers to focus on error taxonomy rather than glue code.[3] Iago Bozza’s write-up further emphasizes that `thiserror` is lightweight, zero-cost, and ideal for structured error types in libraries, generating code equivalent to manual implementations with no runtime overhead.[4]

Authority for `thiserror` comes from its maintainer documentation on docs.rs and crates.io, and from its inclusion in the Comprehensive Rust course and Microsoft Rust Patterns.[1][4][6][15] Practice evidence includes its widespread use in libraries and its position as the standard choice for error enums.[3][4][6] The crate’s version history (2.0.18 as of early 2026) indicates active maintenance.[14][15]

##### Principles and Implementation

`thiserror` must implement the principle of idiomatic structured error modeling for library-like code in `rs-launch-blueprint`. Its derive macros allow the domain error enum to implement `std::error::Error` and `Display` efficiently, integrating with `anyhow` and other error-handling crates.[1][3][4][6][15] The `#[from]` attribute auto-generates `From` implementations for inner error types, enabling the `?` operator to convert them into custom error variants seamlessly.[3][4] This aligns with the principle that library code should expose concrete error types that callers can pattern-match on, while application code uses trait-object errors.[6][7]

##### Dominant Choice

The dominant choice is to use `thiserror = "2"` for domain error enums. This is supported by Microsoft’s Rust Patterns, which explicitly recommend `thiserror` for libraries and “anyhow” for applications.[6] The Rust FAQ also positions `thiserror` as the standard for custom error types.[3]

##### Qualified Shortlist

Alternative crates like `snafu` offer similar functionality but are not represented in the current authoritative sources, making them less suitable as the primary choice under the survey method. 

##### Excluded by Gate

No gate excludes `thiserror`; its license is compatible (MIT or Apache-2.0), and the version history suggests active maintenance without known security advisories.[14][15] MSRV is likely to be well within the template’s policy, but this should be confirmed during integration.

##### Up-and-comers

Diagnostic crates that build on `thiserror` or offer richer error reports are up-and-comers that could be layered atop this design but are not essential for the core error taxonomy.

##### Fit for This Template

`thiserror` fits the template by simplifying domain error enum definitions, integrating with `Result<T, AppError>`, and enabling `anyhow` to wrap domain errors via the standard `Error` trait.[4][6][7][15] Its zero-cost nature means there is no runtime penalty.[4]

##### Recommendation

The template should declare `thiserror = "2"` in `Cargo.toml` and derive `Error` and `Debug` for domain error enums.[15]

##### Ranked Runner-up

Manual implementations of `Error` and `Display` are the runner-up, but are inferior in terms of maintainability and idiomatic expression.

##### Tradeoffs

Using `thiserror` introduces a macro dependency, which slightly increases compile-time, but the benefits in reducing boilerplate outweigh this cost. Binary size impact is negligible since `thiserror` generates code similar to manual implementations.[4]

##### Parameters

No additional parameters are owned by this member; it supports error-taxonomy-exit-codes by providing the underlying error types.

##### Migration Implications

Adopting `thiserror` requires no migration; it is part of the initial template.

##### Validation Strategy

Compile-time tests ensure that derive macros generate correct implementations, and runtime tests exercise error propagation via `?` and `From`.

##### Confidence & Re-verify Trigger

Confidence is very high; re-verification is triggered only by major `thiserror` version changes or advisories.[14][15]

##### Sources

This member’s design is based on `thiserror` documentation, the Rust FAQ, Iago Bozza’s blog, and Microsoft Rust Patterns, all of which describe its usage and benefits.[1][3][4][6][15]

#### `anyhow` Crate

##### Landscape

The `anyhow` crate is the dominant application-level error handling library in Rust. Its documentation describes `anyhow::Error` as a trait-object-based error type designed for easy idiomatic error handling in Rust applications, with `anyhow::Result<T>` as the preferred return type for fallible functions.[2] `anyhow` is built around `std::error::Error` rather than a custom trait, differing from older crates like `failure`.[2] Authority comes from its maintainer documentation and from educational materials like Microsoft Rust Patterns and Rust FAQs, which recommend `anyhow` for binaries and CLI tools where the caller does not need to match on error variants.[2][6][7] 

The Rust FAQ likens `anyhow::Error` to a universal adapter that wraps any error into a consistent interface, preserving details inside the wrapper.[7] This pattern enables the `?` operator to propagate errors from multiple sources without glue code, as `anyhow` implements `From` for most standard and common third-party error types.[2][7] Practice evidence indicates widespread adoption in CLI applications and small services, though detailed adopter lists require direct crates.io queries.

##### Principles and Implementation

`anyhow` implements the principle that application code should use trait-object errors for convenience, while library code uses structured enums. In `rs-launch-blueprint`, the CLI and web-service entrypoints can use `anyhow::Result<()>` as return types, converting domain errors into structured JSON envelopes and exit codes at the boundary. Non-domain errors are propagated as `anyhow::Error` until they reach the top-level handler, which treats them as unexpected and writes crash logs.[2][6][7]

The Rust Patterns documentation explicitly frames the pattern as “thiserror for libraries, anyhow for applications,” emphasizing that `#[from]` auto-generates `From` implementations for inner errors and `.context()` methods add human-readable wrappers.[6] This combination ensures both structured error modeling and ergonomic propagation.

##### Dominant Choice

The dominant choice is to use `anyhow = "1"` for CLI and application-level error handling, consistent with Microsoft’s patterns and Rust FAQs.[2][6][7]

##### Qualified Shortlist

Alternatives like `eyre` exist but are more focused on richer diagnostics than on simple trait-object error propagation. Given the owner’s emphasis on stable error codes and exit taxonomy rather than diagnostic styling, `anyhow` is preferred.

##### Excluded by Gate

No gate excludes `anyhow`; it is MIT-licensed and there are no advisories noted in the current search results. Its MSRV must be checked during integration but is expected to be compatible.

##### Up-and-comers

Crates like `eyre` and `color-eyre` that provide enhanced error reports are up-and-comers and may be layered on top of `anyhow` for developer experience, but they are not central to the machine-encoded taxonomy.

##### Fit for This Template

`anyhow` fits the template by simplifying error propagation in the CLI and web surface while allowing domain errors to be recognized and handled specially at the boundary. It integrates with `thiserror` via the `Error` trait.[2][4][6][7]

##### Recommendation

The template should declare `anyhow = "1"` in `Cargo.toml`, use `anyhow::Result<()>` for CLI `main` and top-level handlers, and rely on `anyhow` for unexpected error propagation.[2]

##### Ranked Runner-up

Using only structured domain errors and manual propagation is the runner-up but would increase boilerplate and reduce flexibility in handling unexpected errors.

##### Tradeoffs

`anyhow` introduces a dependency and uses dynamic dispatch, which can slightly impact performance compared to fully static errors, but for CLI applications the cost is negligible relative to IO and network operations. Its benefits in code clarity and maintainability are substantial.[2][6][7]

##### Parameters

No parameters are owned; this member supports the error taxonomy by providing the mechanism for error propagation.

##### Migration Implications

No migration is required; `anyhow` is part of the initial template stack.

##### Validation Strategy

Tests can ensure that domain errors wrapped in `anyhow::Error` can be recognized at the top-level and that unexpected errors are handled correctly.

##### Confidence & Re-verify Trigger

Confidence is high; re-verification occurs if `anyhow`’s interface changes or new advisories appear.[2]

##### Sources

This design uses `anyhow` documentation and Rust FAQ entries, as well as Microsoft Rust Patterns, which all describe its role in application errors.[2][6][7]

#### `ctrlc` Crate and Signal Handling

##### Landscape

The `ctrlc` crate is a small Rust library providing cross-platform handling of Ctrl-C signals.[5][9][10] It offers a single `set_handler` function that registers a handler closure executed when the user presses Ctrl-C. On Unix, this corresponds to a `SIGINT` signal, while on Windows, it corresponds to `CTRL_C_EVENT` or `CTRL_BREAK_EVENT`.[5][9][10] With the `termination` feature enabled, the handler also executes for `SIGTERM` and `SIGHUP` on Unix, making `ctrlc` useful for basic graceful shutdown needs.[5][9][10] Authority stems from its maintainer documentation on docs.rs and its description on OpenApps, which highlights its cross-platform abstraction over Unix signals, Apple dispatch, and Windows console events.[9][10]

Practice evidence shows that `ctrlc` is widely used in CLI tools requiring simple shutdown on Ctrl-C and optional termination signals. The rust-cli DeepWiki includes examples using `ctrlc::set_handler` with an `Arc<AtomicBool>` to signal graceful shutdown and suggests combining `ctrlc` with other mechanisms for more complex behaviors.[8]

##### Principles and Implementation

`ctrlc` must implement the principle that SIGINT and SIGTERM are handled gracefully and mapped to exit codes 130 and 143 respectively. In `rs-launch-blueprint`, the CLI should install a `ctrlc` handler early in `main`, using `ctrlc::set_handler` to set an atomic flag or to directly call a shutdown routine. With the `termination` feature enabled, the handler should detect whether the signal is SIGINT or SIGTERM (via `SignalType` or similar) and set the exit code accordingly.[5][9] 

The rust-cli DeepWiki recommends patterns where a signal handler sets a “shutting down” flag on first signal and forces immediate exit on subsequent signals, which can be implemented via an `AtomicBool` and conditional logic.[8] This ensures that the first Ctrl-C begins graceful shutdown, while repeated interrupts cause immediate exit.

##### Dominant Choice

The dominant choice for signal handling in this template is `ctrlc`, with the `termination` feature enabled for SIGTERM and SIGHUP support. This choice provides a simple, cross-platform API and aligns with the template’s non-daemon nature.[5][9][10]

##### Qualified Shortlist

`signal-hook` is a qualified alternative for advanced Unix-only signal handling, providing a global registry of actions and allowing multiple handlers per signal.[16][17][19] However, its complexity is unnecessary for the template’s basic needs.

##### Excluded by Gate

No gate excludes `ctrlc`; it is MIT-licensed, supports Unix and Windows, and has no advisories noted in the current search results.[5][9][10] It fits the MSRV policy, though this should be verified during integration.

##### Up-and-comers

Async signal-handling patterns using `signal-hook` and async runtimes are up-and-comers, relevant for future web-service extensions but not required now.[8][16][17]

##### Fit for This Template

`ctrlc` fits the CLI template by providing simple and reliable signal handling across `ubuntu-latest` and `macos-latest`. It integrates with Rust’s standard error handling and exit codes.[5][8][9][10]

##### Recommendation

The template should declare `ctrlc` with the `termination` feature in `Cargo.toml`, install a handler at startup, and map signals to exit codes 130 and 143.

##### Ranked Runner-up

`signal-hook` is the runner-up, suitable for future expansion if multiple signals and complex behavior become necessary.

##### Tradeoffs

`ctrlc` offers simplicity at the cost of less granular control over multiple signal handlers; `signal-hook` offers more control but adds complexity and Unix-specific focus.[8][16][17][19]

##### Parameters

No parameters are owned, but this member interacts with error-taxonomy-exit-codes via the mapping of signals to exit codes.

##### Migration Implications

Adding `ctrlc` requires including it as a dependency and ensuring that CI builds on Ubuntu and macOS pass with the `termination` feature.

##### Validation Strategy

Tests can simulate SIGINT and SIGTERM in controlled environments, verifying that the handler runs and exit codes are correct. Integration tests using manual Ctrl-C in CLI runs can confirm behavior.

##### Confidence & Re-verify Trigger

Confidence is high; re-verification occurs if `ctrlc` changes its API or if platform support issues arise.[5][9][10]

##### Sources

This design relies on docs.rs documentation for `ctrlc`, OpenApps descriptions, and rust-cli DeepWiki advice on signal handling.[5][8][9][10]

#### Crash-Log Writer and Broken Pipe Handling

##### Landscape

Crash-log persistence and broken pipe handling rely primarily on the standard library and on patterns documented in Rust CLI guidance. Python’s ADR 0006 provides a cross-language precedent for crash logs, specifying a best-effort append to a crash log under the state directory.[Context, py ADR] TypeScript’s code includes an EPIPE handler via `process.stdout.on('error', ignoreEpipe)`, preventing crashes when downstream pipe readers close early.[Context, ts code] Rust’s CLI documentation recommends checking `io::Error::kind()` for `ErrorKind::BrokenPipe` and treating such errors as benign, often by exiting quietly.[8]

##### Principles and Implementation

The crash-log writer must implement the principle of best-effort persistence of unexpected errors. It should construct a path to a crash-log file based on the state directory determined by R57, or based on a default state directory if R57’s answer is not yet available. It should then append serialized error information—such as timestamp, error code, message, and stack trace if available—to the log file. If writing fails (for example due to permissions), the writer should fail silently, logging only in verbose mode. The presence of a crash-log file provides a tool for post-mortem analysis without affecting user-facing behavior.

Broken pipe handling must detect when writes to `stdout` or `stderr` fail with `ErrorKind::BrokenPipe` and avoid printing error messages or crash logs in that case. The CLI should exit with `ExitCode::Success` (0) or a neutral code, reflecting that the pipeline completed as far as it could. This pattern aligns with TypeScript’s EPIPE handler and Rust’s standard idioms.[8][Context, ts code]

##### Dominant Choice

The dominant choice is to implement crash-log writer and broken pipe handling using only the standard library, without additional crates. This keeps the dependency stack simple and leverages well-known patterns.

##### Qualified Shortlist

More advanced crash-log systems could integrate with logging frameworks like `tracing` or `log`, but such integrations are beyond the scope of this item.

##### Excluded by Gate

No gate excludes standard library patterns; they are inherent to Rust.

##### Up-and-comers

Structured logging frameworks are up-and-comers that might integrate with crash logs, but they are not necessary for the core behavior.

##### Fit for This Template

These patterns fit the template by providing robust behavior for unexpected errors and broken pipes without additional dependencies. They maintain cross-language consistency with Python and TypeScript’s precedent.

##### Recommendation

The template should implement crash-log writing via `std::fs::OpenOptions::append(true)` and broken pipe detection via `io::ErrorKind::BrokenPipe`, mapping broken pipe scenarios to exit code 0.

##### Ranked Runner-up

Using no crash-log writer is a runner-up but fails the cross-language principle; thus, it is not recommended.

##### Tradeoffs

Crash-log writing introduces minor IO overhead, while broken pipe suppression may hide certain errors; careful logging and documentation mitigate these tradeoffs.

##### Parameters

assumes R57 xdg-directory-set = a state directory path where crash logs can be written; if R57 chooses a different path, the crash-log writer must adapt.

CONFLICT: R57 state-directory — needs a writable state directory path for crash logs — reason: crash-log persistence requires a location; until R57 is decided, this member assumes a default path but must be updated to consume R57’s parameter.

##### Migration Implications

Future changes to R57’s state-directory decisions may require updating the crash-log writer’s path logic.

##### Validation Strategy

Tests that simulate unexpected errors and verify crash-log entries, as well as tests that simulate broken pipe writes and confirm quiet exits, will validate this member.

##### Confidence & Re-verify Trigger

Confidence is moderate; re-verification is triggered by changes in R57’s state-directory decisions or by new requirements for logging formats.

##### Sources

This member derives its design from Python’s ADR 0006, TypeScript’s EPIPE pattern, and Rust CLI guidance on broken pipe handling.[8][Context, py ADR][Context, ts code]

### Compatibility

The members of the

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [thiserror - Comprehensive Rust - Google](https://google.github.io/comprehensive-rust/error-handling/thiserror.html)
- [anyhow 1.0.104](https://docs.rs/crate/anyhow/latest)
- [How to use thiserror crate — Rust FAQ](https://www.rustfaq.org/en/how-to-use-thiserror-crate/)
- [Error Handling in Rust with thiserror | Iago Bozza](https://iagobozza.com/blog/error-handling-in-rust-with-thiserror/)
- [ctrlc - Rust](https://docs.rs/ctrlc)
- [10. Error Handling Patterns - Rust Patterns & Engineering How-Tos](https://microsoft.github.io/RustTraining/rust-patterns-book/ch10-error-handling-patterns.html)
- [How to Use the anyhow Crate for Application Errors — Rust FAQ](https://www.rustfaq.org/en/how-to-use-the-anyhow-crate-for-application-errors/)
- [Signal Handling | rust-cli/book | DeepWiki](https://deepwiki.com/rust-cli/book/4.3-signal-handling)
- [ctrlc - Rust](https://docs.rs/ctrlc/latest/ctrlc/)
- [ctrlc: Simple Cross-Platform Ctrl-C Handler for Rust](https://openapps.pro/packages/ctrlc)
- [Information for rust:thiserror-impl](https://repology.org/project/rust:thiserror-impl/information)
- [Signal-hook-registry — Rust API for Unix // Lib.rs](https://lib.rs/crates/signal-hook-registry)
- [python3-maturin-1.8.6-r0 do_unpack](https://errors.yoctoproject.org/Errors/Details/861340/)
- [thiserror-impl 2.0.18 - Docs.rs](https://docs.rs/crate/thiserror-impl/latest)
- [thiserror 2.0.18 - Docs.rs](https://docs.rs/crate/thiserror/latest)
- [Signal-hook - Unix APIs](https://lib.rs/crates/signal-hook)
- [signal-hook - Rust Crate - Cargo Run](https://cargo-run.news/crates/signal-hook)
- [Information for rav1e](https://repology.org/project/rav1e/information)
- [Function signal_hook::register](https://teaclave.apache.org/api-docs/crates-app/signal_hook/fn.register.html)

## Cost

Total: $0.6202