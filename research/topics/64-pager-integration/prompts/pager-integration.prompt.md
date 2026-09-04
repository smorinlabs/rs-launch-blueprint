# Deep-research prompt — Pager integration (R64, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` pages long text-mode output through the user's pager, and, if adopted, what Rust crate/pattern resolves the pager command (an app-specific env var taking precedence over the generic `PAGER`, falling back to `less -FRX`) and invokes it. Item kind: `bundle`. Value test: if this answer is wrong, whether a paging dependency exists at all, and the output-rendering function's paging gate plus the pager-command resolution precedence, get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): this bundle is py-only — ts ships no pager integration to compare against. py pages long text-mode output through the user's pager when output is a terminal, resolving the pager command through an app-specific env var before the generic `PAGER`, falling back to `less -FRX`. Evidence: py `src/py_launch_blueprint/cli/output.py:177` — `if not (self.paging and self.out.is_terminal and _isatty(self.out)):` (the paging gate); py `src/py_launch_blueprint/cli/output.py:88` — `for var in ("PLBP_PAGER", "PAGER"):` (resolution precedence), falling back to `less -FRX` (`src/py_launch_blueprint/cli/output.py:56`). Ledger rows: F284, F285 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; ADR 0008.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision on pager integration; ts's CLI has no long-form text output mode to page in the first place, so the absence was never a considered-and-rejected choice.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Looking at architectural pattern, not the exact library. We'd like a similar pager pattern for TypeScript and Rust.

## Out of scope
- Which output formats exist (text/json/csv and any file-redirection flag); R66 (`output-format-surface`) owns F291/F293 — this item decides only whether/how the text-mode format gets paged, not which formats exist.
- The TTY-detection mechanism used to gate paging; R65 (`color-enablement-chain`) owns F290's TTY-detection mechanism — this item reuses whatever check R65 selects for "is this stream a terminal," it does not redecide that check.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R64
- owns:
- consumes:
- related (not a registry dependency): R65 (`color-enablement-chain`) decides F290's TTY-detection mechanism; this item's paging gate ("is stdout a terminal") should reuse whatever check R65 lands on rather than implementing a second, divergent TTY check, but R65 registers no parameter this item formally consumes.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` pages long text-mode output through the user's pager, and if so, what Rust crate/pattern resolves and invokes the pager command with the app-specific-env-var-then-`PAGER`-then-`less -FRX` precedence.
- HIGH: Is paging worth adopting for a Rust CLI template at all, given ts ships no equivalent and no ts decision record even considered it — does the template's typical text-mode output length justify a pager, or should this row be recommended for omission?
- HIGH: If adopted, what Rust crate or pattern spawns and pipes output to an external pager subprocess while preserving ANSI color codes through the pipe (matching `less -FRX`'s `-R` "raw control chars" flag) — is there a maintained `pager`-invocation crate, or does the template hand-roll `std::process::Command` plumbing?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What env-var precedence should the pager lookup follow — an app-specific override (renamed from py's `PLBP_PAGER`) before the generic `PAGER`, matching py's two-tier chain — and what happens when neither is set and `less` itself is not installed (some minimal Linux images, and Windows, ship no `less`)?
- MEDIUM: Does paging need the same "is this stream a terminal" gate R65 selects for color (F290), or does the paging gate need to check a different stream (py checks `self.out`, the primary output stream) than whatever stream R65's color gate checks?
- LOW: Given `target-os-matrix` excludes Windows from CI, should paging be conditionally compiled or documented as POSIX-only, or does a maintained cross-platform pager crate make that unnecessary?

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
