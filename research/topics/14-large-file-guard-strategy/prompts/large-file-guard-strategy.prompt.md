# Deep-research prompt — Large-file guard strategy (R14, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation, no crate involved) for: whether `rs-launch-blueprint` guards against accidentally-committed large files at both the CI tier (a dedicated workflow rejecting new files over a size threshold) and the git-hook tier (a pre-commit/pre-push hook rejecting staged files over a size threshold), and, if both tiers are kept, what size threshold and path-exemption rule each uses. Item kind: `bundle`. Value test: if this answer is wrong, either a CI-level `large-file-guard.yml`-equivalent workflow or the hook-tier large-file check (or both) get added, removed, or re-thresholded, changing what a contributor can accidentally commit and how late in the pipeline it is caught.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py runs a large-file guard at two independent tiers with two different thresholds and exemption rules. At the CI tier, a dedicated `large-file-guard.yml` workflow rejects any new file over 1 MB, exempting files under `docs/assets/`. At the hook tier, `lefthook.yml`'s `large-files` job rejects staged files over `1048576` bytes (1 MB), with the same `docs/assets/*` exemption. ts has no CI-tier guard at all, and its hook-tier `check-large-files` job uses a stricter 500 KB threshold (`512000` bytes) with no path exemption. Evidence: py `.github/workflows/large-file-guard.yml:4` — rejects new files over 1 MB outside `docs/assets/`; ts: none (py-only; ts has no CI-tier large-file workflow); py `lefthook.yml:137`,`lefthook.yml:143` — `large-files` job rejects staged files over `1048576` bytes (1 MB), exempting `docs/assets/*`; ts `lefthook.yml:42` — `check-large-files` job rejects staged files over `512000` bytes (500 KB), no path exemption. Ledger rows: F043 (`docs/port/COMMONALITY.md`, area `ci-workflows`), F172 (`docs/port/COMMONALITY.md`, area `git-hooks-commit-hygiene`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): which hook manager runs the hook-tier check (`lefthook` or an alternative) is R37's decision (`hook-manager-distribution`) — this item decides only whether a large-file check exists at each tier and its threshold/exemption rule, not which tool executes the hook-tier half. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-020(6) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Extent of hook duties in lefthook.yml → pre-commit: parallel staged lint/format with stage_fixed (tool from T04) + tsc --noEmit + minimal hygiene checks (large-files etc., delegating whitespace/EOF to the formatter...)"; ts's decision record folds the large-file check into a broader "minimal hygiene checks" bucket with no separate rationale for its stricter 500 KB threshold or the dropped path exemption — ts's own D-020 "Why" section does not explain the specific threshold change.

## Out of scope
- Which hook manager executes the hook-tier check (`lefthook` vs. an alternative); R37 (`hook-manager-distribution`) owns that decision — this item assumes whatever hook manager R37 selects can run a file-size check and decides only the check's existence, threshold, and exemption rule.
- Every other hook-tier hygiene check bundled separately in py's `lefthook.yml` (whitespace/EOL, YAML lint, spell-check, actionlint); R40 (`auxiliary-hygiene-hooks`) owns F167-F170 — distinct checks, not bundled with the large-file guard.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R14
- owns:
- consumes:
- related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides whether `rs-launch-blueprint`'s CI checks are separate workflow files or jobs/steps inside `ci.yml`; py's CI-tier large-file guard is already its own dedicated workflow file (`large-file-guard.yml`), independent of `ci.yml`'s internal job structure, so this item's CI-tier recommendation does not need R11's value to be answered, only to be placed correctly relative to it.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` needs a CI-tier large-file guard in addition to a hook-tier one, and what size threshold and path-exemption rule each tier uses.
- HIGH: Does the hook-tier check alone (which every contributor's local git hooks enforce before a commit is even made) provide sufficient protection, or does the CI-tier guard earn its keep as a backstop against a contributor who bypasses hooks (`--no-verify`) or force-pushes from an environment where hooks were never installed?
- HIGH: What size threshold fits a Rust template — py's 1 MB or ts's stricter 500 KB — given Rust binaries, `target/` artifacts, and any bundled fixtures have different typical file-size profiles than Python or Node projects, and given `target/` is gitignored so committed-file size expectations are driven by source, docs, and test fixtures only?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Does a `docs/assets/*`-style path exemption (py's choice) make sense for `rs-launch-blueprint`, or does the template's docs tree (whichever shape R81's `docs-delivery-model` decision produces) have a different natural home for large binary assets that warrants a different exemption path or no exemption at all?
- LOW: Should the CI-tier and hook-tier checks share one threshold/exemption definition (a single source of truth referenced by both) to avoid the drift ts's port introduced (500 KB vs. py's 1 MB, with no stated reason), or is independent tuning per tier acceptable given they catch different failure windows?

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
