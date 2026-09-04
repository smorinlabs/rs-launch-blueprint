# Deep-research prompt — Output format surface (R66, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which text-serialization output formats `rs-launch-blueprint`'s CLI supports (text, JSON, and a third format — py's markdown vs. ts's csv), and how the format-selection flag and the file-redirection flag are named to resolve the naming collision between py's `--output-file`/`-o`(`--output`) split and ts's single `--output` file-sink flag. Item kind: `bundle`. Value test: if this answer is wrong, the output-format enum, the flag names and any mutual-exclusion declarations between them, and the format-specific renderer implementations, all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py and ts diverge on both the format list and the flag naming. py's format enum is text/json/markdown; ts's is text/json/csv. py's format-selection flag is `-o`/`--output`, and file redirection is a separate `--output-file` flag; ts's single `--output <file>` flag is the file sink, with a distinct `--format` flag selecting the output format. Evidence: F291 py `src/py_launch_blueprint/cli/output.py:47` — `class OutputMode(StrEnum):` (`text`/`json`/`markdown`); ts `src/lib/format.ts:16` — `export const OUTPUT_FORMATS = ['text', 'json', 'csv'] as const;`. F293 py `src/py_launch_blueprint/cli/options.py:72` — `"--output-file",`, separate from format selection; ts `src/commands/projects.ts:83` — `.option('--output <file>', 'write results to file')` — a naming collision: ts's `--output` is py's `--output-file`; py's format flag is `-o`/`--output`, ts's is `--format`. Ledger rows: F291, F293 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): that a `--json` shorthand flag exists (F292) is inherited as-is (`COMMON → REUSE`); this item decides the underlying format-selection flag it aliases to and its naming, not whether `--json` exists. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-033 (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — while resolving an unrelated interactive-prompt-cancellation gate, the same change set implemented a `--json` alias for `--format json` and explicitly kept `--output` as the file-sink flag: "`--output` remains the file sink (source parity; documented divergence from cli-standards' `-o` output-format enum, noted in EXAMPLECLI)" — a deliberate, acknowledged departure from an external CLI-standards convention that would have made `-o`/`--output` the format-selection flag instead.

## Out of scope
- Which CLI-parsing framework hosts these flags; R60 (`cli-parsing-framework`) owns that bundle — this item's flag names only need to be declarable by whatever R60 selects.
- Rich-only terminal presentation niceties (OSC-8 hyperlinks, relative timestamps) layered on top of the text-mode table's individual cells; R85 (`rich-terminal-row-niceties`) owns F359 — this item decides which formats exist and their flag names, not per-cell terminal styling within the text format.
- Whether long text-mode output gets paged through the user's pager; R64 (`pager-integration`) owns F284/F285 — this item decides the text format's content shape, not whether it is paged.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R66
- owns:
- consumes:
- related (not a registry dependency): R85 (`rich-terminal-row-niceties`) owns F359, terminal-only presentation additions layered on top of whatever text-mode row rendering this item's answer produces; R85 needs no registered parameter from this item, only its text-format row shape as a starting point.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which text-serialization output formats `rs-launch-blueprint`'s CLI supports, and how the format-selection and file-redirection flags are named to resolve the `--output`/`--output-file`/`-o`/`--format` naming collision between the two sources.
- HIGH: Should the third format (beyond text and JSON) be py's markdown, ts's csv, both, or neither — what use case does each serve (markdown for human-readable/paste-into-PR output vs. csv for spreadsheet import), and does supporting either require a Rust crate (a markdown-table writer, or the `csv` crate) or can it be hand-rolled?
- HIGH: How should the format-selection flag and the file-redirection flag be named to resolve the collision — keep `--output` as the file sink and `--format` as format selection (ts's D-033 choice, an acknowledged divergence from an external `-o`-as-format-flag convention), or follow py's split (`-o`/`--output` selects format, a separate `--output-file` writes to a file)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Does `--json` remain a shorthand/alias for `--format json` (ts's D-033 choice), and does the chosen CLI framework (R60) support declaring that alias with a mutual-exclusion the way Commander's `.conflicts()` does (F292)?
- MEDIUM: Does rendering markdown or csv require a dedicated Rust crate, and if the text format later carries R85's terminal-only niceties (OSC-8 hyperlinks, relative timestamps), do markdown/csv need to stay strictly plain or can they carry equivalent non-terminal formatting (e.g. markdown links)?
- LOW: What should the file-redirection flag do when the target file already exists — overwrite, append, or error — given neither source repo's evidence cited here documents this behavior explicitly?

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
