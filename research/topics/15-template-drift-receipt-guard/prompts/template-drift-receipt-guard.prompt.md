# Deep-research prompt — Template drift/receipt guard (R15, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: how `rs-launch-blueprint` carries py's template-press/receipt-guard machinery — a hermetic self-press check that verifies the template can re-generate itself, and a workflow that rejects a committed press receipt artifact — given the owner's decision that rs is rebrandable through the same `template-press` mechanism as py. Item kind: `pattern`. Value test: if this answer is wrong, `rs-launch-blueprint` either ships two workflow files (`press-verify.yml`, `template-receipt-guard.yml`) with no corresponding press tool to exercise them, or silently lacks a guard that would have caught a template-rebranding regression the owner did intend to support.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py-launch-blueprint is itself a `template-press`-rebrandable template — a separate tool can stamp out a renamed, re-branded copy of the repository — and carries two workflows to protect that capability: `press-verify.yml` runs a hermetic self-press check confirming the template can regenerate itself correctly, and `template-receipt-guard.yml` rejects a PR that accidentally commits a press-tool receipt artifact (a byproduct of running the press tool that should never be checked in). ts, a same-family port of py, did not carry either workflow forward, and its own port-decision record contains no entry discussing them — the concept was dropped, not evaluated and rejected. Evidence: py `.github/workflows/press-verify.yml:10` — hermetic self-press check; py `.github/workflows/template-receipt-guard.yml:6` — rejects a committed press receipt; ts: none (no equivalent concept found; ts's own port decisions carry no D-0xx adopting it either). Ledger row: F044 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): none of the fixed parameters bear directly on this item beyond the standard ones. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts silently dropped both workflows with no decision record; the area evidence note is the only documented rationale available ("ts's own port decisions carry no D-0xx adopting it either").
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): You should be using template-press just the way PyLaunch Blueprint does, and the same thing for TypeScript. We should all be using the same mechanism.

## Out of scope
- Whether `rs-launch-blueprint` is rebrandable via `template-press` at all — settled by the owner on 2026-09-04 (owner direction above): yes, through the same mechanism as py-launch-blueprint, with ts to follow; this item takes that as given and does not re-derive it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R15
- owns:
- consumes:
- related (not a registry dependency): none.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how `rs-launch-blueprint` ships a hermetic self-press verification workflow and a committed-receipt rejection guard matching py's template-press machinery, now that the owner has settled that all three repos use that mechanism.
- HIGH: What does py's self-press check (`press-verify.yml`) and receipt guard (`template-receipt-guard.yml`) require of a Rust template — which files, workflow steps and press inputs (crate names, `Cargo.toml` package fields, binary names) must exist for `template-press` to press `rs-launch-blueprint` and verify the pressed copy builds and tests?
- HIGH: Alongside `template-press`, what is the current-state Rust equivalent of a `template-press`-style tool the self-press workflow would exercise — is there an established Rust project-templating tool (e.g., `cargo-generate`) whose own regeneration/verification story this pattern should mirror, and does that tool's ecosystem have a precedent for a "does the template still generate a working project" CI check?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Beyond the press receipt, does the receipt-guard half of the pattern (rejecting an accidentally committed build/tool byproduct) have independent merit as a general "no stray tool-output files" hygiene check worth generalizing?
- LOW: Given ts (a same-family port with the same origin repository) dropped this pattern with no recorded rationale, does that silence itself constitute evidence the pattern was judged not worth porting, or is it simply an undocumented gap in the ts port that should not be treated as a decision?

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
### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
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
