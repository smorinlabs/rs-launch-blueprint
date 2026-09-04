# Deep-research prompt — AI-assistant repo furniture (R43, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of patterns (with reference implementations) for: whether `rs-launch-blueprint` adds vendor-specific AI-editor rule files (Cursor, Windsurf) as spokes pointing back to the AGENTS.md hub, and a Claude Code repo-welcome startup announcement, beyond the AGENTS.md hub itself. Item kind: `bundle`. Value test: if this answer is wrong, the repo's `.cursor/rules/`, `.windsurf/rules/`, and `.claude/settings.json` `companyAnnouncements` content all get added, removed, or rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): ts adds vendor-specific AI-editor rule files (Cursor, Windsurf) as thin spokes re-pointing to the AGENTS.md hub, and a Claude Code repo-welcome startup announcement naming the project and its `just` commands; py carries neither, having consolidated into AGENTS.md-only furniture before the ts port began. Evidence: ts `.cursor/rules/projectenv.mdc:9` — "read rules @AGENTS.md"; `.windsurf/rules/justfile-rules.md:2` — a glob rule scoped to `Justfile`; py: none (dropped `.windsurfrules`/Cursor rules in commit `fc8d944`, pre-pin, consolidating into AGENTS.md only). Ledger rows: F198, F199 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F199 repo-welcome startup announcement — ts `.claude/settings.json:2` — `"companyAnnouncements"` array with a project summary plus a `just` command list; py: none (py's `.claude/settings.json` has no such key).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the AI-agent instruction hub itself (single canonical `AGENTS.md` file plus a thin per-tool import) is `COMMON → REUSE` (F197, `docs/port/COMMONALITY.md`) — both repos keep it, and this item does not re-decide whether the hub exists, only what spokes point at it. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-024(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — kept the hub-and-spoke mesh but promoted AGENTS.md to the hub (replacing `.windsurfrules`), because Windsurf demoted `.windsurfrules` to legacy and both Cursor and Windsurf read AGENTS.md natively as the durable Linux-Foundation format; and D-024(6) — reused the org's difftree `companyAnnouncements` welcome-string convention plus agent2linear's plugin enables, per the owner's own global instruction mandating repo-welcome announcements.

## Out of scope
- The content and structure of `AGENTS.md`/`CLAUDE.md` themselves as the instruction hub; that pattern is already `COMMON → REUSE` (F197) — this item only decides the vendor-specific spokes and the welcome announcement around it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R43
- owns:
- consumes:
- related (not a registry dependency): none — this item's decision is self-contained repo furniture with no other research item's parameter as an input.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships vendor-specific Cursor/Windsurf rule files pointing back to the AGENTS.md hub, and a Claude Code repo-welcome startup announcement, given the repo already ships the AGENTS.md hub itself.
- HIGH: Do Cursor and Windsurf's current rule-file formats and AGENTS.md-reading conventions (as of research date) still match ts's `.cursor/rules/*.mdc` and `.windsurf/rules/*.md` shapes, or has either vendor changed its native-AGENTS.md support since the ts port (2026-07)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: Is a glob-scoped rule file (ts's `Justfile`-scoped Windsurf rule) still the idiomatic way to steer an AI editor toward a specific file, or has a simpler single hub-pointer rule superseded it?
- MEDIUM: Should the Claude Code repo-welcome announcement (F199) name Rust-specific commands (`cargo build`, `cargo test`) alongside or instead of `just` recipes, given the template's task-runner tool is already `just` (`docs/port/COMMONALITY.md` F176, `COMMON → REUSE`)?
- LOW: Is there a maintenance cost (staleness risk) to committing vendor-specific rule files that argues for omitting them and relying on the AGENTS.md hub alone, given both vendors already read AGENTS.md natively?

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
