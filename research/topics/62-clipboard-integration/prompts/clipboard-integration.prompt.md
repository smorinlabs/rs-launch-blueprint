# Deep-research prompt — Clipboard integration (R62, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a cross-platform clipboard-write crate for a `--copy` flag on command results, and how a clipboard write degrades cleanly instead of crashing in a headless/CI environment with no display server. Item kind: `bundle`. Value test: if this answer is wrong, whether a `--copy` flag and clipboard-writer dependency exist at all, and the function/trait wrapping the write plus its headless-degrade error path, get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): this bundle is ts-only — py ships no clipboard integration to compare against. ts's `--copy` flag copies command results to the OS clipboard, with the write wrapped to degrade instead of crash when no clipboard is available. Evidence: ts `src/commands/projects.ts:84` — `.option('--copy', 'copy results to clipboard', false)`; ts `src/lib/adapters.ts:49` — `export const realClipboard: ClipboardWriter = async (text) => {`; failure is caught and re-raised as a `CliError` (`src/commands/projects.ts:193`) instead of crashing. Ledger rows: F281, F282 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(7) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — `clipboardy` 5.3.1, wrapped to degrade with a clear stderr error in headless/CI environments instead of crashing; chosen as "the only serious cross-platform Node clipboard lib (macOS/Windows native, Linux `xsel`/`wl-clipboard`)," with upstream confirming headless Linux has no clipboard, making graceful degradation mandatory rather than optional.

## Out of scope
- Which CLI-parsing framework hosts the `--copy` flag; R60 (`cli-parsing-framework`) owns that bundle — this item's crate choice only needs to compose with whatever R60 selects.
- The exact error code and exit status a clipboard-write failure maps to; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item decides only that a clipboard-write failure raises a typed, catchable error, not its catalog entry or exit code.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R62
- owns:
- consumes:
- related (not a registry dependency): R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes`; the typed error this item's clipboard-write function raises on failure eventually gets a catalog entry and exit code from R67, but this item does not need that value to make its own recommendation.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether/which Rust crate provides cross-platform clipboard write for `--copy`, and how a clipboard-write failure in a headless/CI environment degrades cleanly instead of crashing the command.
- HIGH: What is the dominant Rust crate for cross-platform clipboard write covering macOS, Windows, and Linux (X11 and Wayland, mirroring `clipboardy`'s `xsel`/`wl-clipboard` coverage) — e.g. `arboard`, `copypasta`, `clipboard-win`+platform-specific crates — and does it reach parity with `clipboardy`'s platform matrix?
- HIGH: How does the candidate crate behave on headless Linux (no X11/Wayland display server) — does it return a typed, catchable error the template can turn into a clean stderr message, or does it hang, panic, or require an external binary (`xsel`/`xclip`) to be present on PATH?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: Does the candidate crate require any external system binary at runtime (as `xsel`/`wl-clipboard` are external processes `clipboardy` shells out to on Linux), or does it use native platform APIs/libraries with no external process dependency?
- MEDIUM: What is the idiomatic Rust error type for a clipboard-write failure that lets the call site convert it into the template's domain error uniformly, without this item pre-deciding the catalog entry R67 owns?
- LOW: Should the flag be named `--copy` (matching ts) or does the chosen CLI framework's (R60) conventions suggest a different name or short form?

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
