# Deep-research prompt — Auxiliary hygiene hooks (R40, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of tools and reference pattern (with versions) for: `rs-launch-blueprint`'s auxiliary pre-commit hygiene/structural-validity tool stack beyond rustfmt/clippy — a whitespace/EOL/format-validity linter, a YAML structural lint hook, a spell-check hook, a GitHub Actions workflow-syntax lint hook, and the cross-editor `.editorconfig` baseline (with its documented per-filetype exceptions) that these hooks help enforce. Item kind: `bundle`. Value test: if this answer is wrong, the pre-commit hook jobs for these four checks, their config files, and the repository's `.editorconfig` and its exceptions all get added, removed, or rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py runs four auxiliary hygiene linters at pre-commit — a whitespace/EOL/format-validity checker, a YAML structural linter, a spell-checker, and a GitHub Actions workflow-syntax linter — on top of a committed `.editorconfig` baseline with two documented per-filetype exceptions. ts has none of the four hook tools; it folds trailing-whitespace/EOF-newline fixing into its formatter job instead of a separate validity linter, and carries no `.editorconfig` at all. Evidence: py `lefthook.yml:82` — `editorconfig-checker` job runs `uv run ec -config .editorconfig-checker.json` on staged files; ts: none. Ledger rows: F167, F168, F169, F170 (`docs/port/COMMONALITY.md`, area `git-hooks-commit-hygiene`), F191, F192 (area `dev-experience-repo-hygiene`), verdict `DIVERGENT`, origin `py-only` for all six.
- Per-row evidence for the rest of this bundle: F168 YAML lint hook — py `lefthook.yml:88` (`yamllint` job runs `uv run yamllint -c .yamllint {staged_files}`); ts: none — distinct from YAML *formatting* (owned by the non-code-file-formatting item), this is structural/style linting, not reformatting. F169 spell-check hook — py `lefthook.yml:102` (`codespell` job runs `uv run codespell --toml pyproject.toml {staged_files}`); ts: none. F170 GitHub Actions workflow syntax lint hook — py `lefthook.yml:99` (`actionlint` job runs `actionlint {staged_files}` on staged workflow files); ts: none (ts's `Justfile:83` only prints an optional-tool install hint for actionlint; it is never wired into any hook or CI job) — whether actionlint runs at hook tier at all is this item's concern; its *config content* (self-hosted-runner labels, `RUNNER_*` vars, stale-metadata suppression) belongs to the self-hosted-runner-indirection item, out of scope here. F191 cross-editor formatting baseline file — py `.editorconfig:3` (`root = true`; charset/EOL/indent_style/indent_size defaults, from `docs/port/areas/dev-experience-repo-hygiene.md`); ts: none (no `.editorconfig` exists in the ts tree, no row to compare). F192 documented per-filetype `.editorconfig` exceptions — py `.editorconfig:25`, `.editorconfig:31` (`[*.md]` keeps trailing whitespace for hard breaks; `[*.ambr]` keeps trailing whitespace for snapshot bytes, each with an inline rationale comment, from `docs/port/areas/dev-experience-repo-hygiene.md`); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Two researched parameters this item consumes are still open (no `DECISION.md` yet): `ci-job-structure` (R11), `package-manager-invocation` (R42) — design any CI re-run and tool-invocation prefix to fit whichever value each eventually takes; do not block on them.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing why editorconfig-checker, yamllint, codespell, actionlint, or `.editorconfig` itself were not carried over; ts simply never adopted any of the four.

## Out of scope
- The git hook manager itself — its distribution/install mechanism and the full-hook-suite CI re-run; R37 (`hook-manager-distribution`) owns F143/F144/F174 — this item picks the four auxiliary tools and their config, not the manager wrapping the pre-commit stage they run inside.
- YAML *formatting* (reformatting YAML files), as distinct from YAML structural/style linting (F168); R29 (`non-code-file-formatting`) owns YAML formatting (F098) — this item owns only the lint check.
- actionlint's *config content* for self-hosted-runner labels, `RUNNER_*` variables, and stale-metadata suppression; R09 (`self-hosted-runner-indirection`) owns that — this item decides only whether actionlint runs at hook tier at all, not its self-hosted-runner-specific rule content.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R40
- owns:
- consumes: R11: ci-job-structure; R42: package-manager-invocation
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R37 (`hook-manager-distribution`) owns the hook manager and its stage tiering these four hooks would run inside; this item does not re-decide the manager. R09 (`self-hosted-runner-indirection`) owns actionlint's self-hosted-runner-specific config content.

## Questions
Decision: which of py's four auxiliary pre-commit hygiene tools (whitespace/EOL/format-validity, YAML structural lint, spell-check, GitHub Actions workflow-syntax lint) `rs-launch-blueprint` adopts, and whether it ships a cross-editor `.editorconfig` baseline (with per-filetype exceptions) to back them.
- HIGH: Does `rs-launch-blueprint` need a separate whitespace/EOL/format-validity linter (editorconfig-checker's role, F167) given `rustfmt` already normalizes Rust source formatting, or does that gap only matter for non-Rust files (Markdown, YAML, TOML) the way ts folds it into its formatter job instead?
- HIGH: Should `rs-launch-blueprint` ship an `.editorconfig` (F191) at all, given ts — the more recently authored source repo — deliberately carries none; what is the current argument for or against an `.editorconfig` baseline in a Rust-primary repo where `rustfmt`/`clippy` already own Rust-file formatting?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Are `yamllint` (F168) and `codespell` (F169) — both Python tools requiring a Python runtime provisioned solely to run them — worth keeping as-is for a Rust template, or does the Rust ecosystem have native equivalents (e.g. a Rust-native YAML linter, a Rust-native spell-checker) worth comparing on maintenance state and installation footprint?
- MEDIUM: Is `actionlint` (a standalone Go binary, F170) the right choice to keep for a Rust template's GitHub Actions workflow-syntax linting, and should it run at pre-commit (py's tier) or only in CI, given Rust's slower iteration loop per commit compared to Python?
- LOW: If `.editorconfig` is adopted, what per-filetype exceptions (mirroring F192's Markdown hard-break and snapshot-file carve-outs) are relevant to this template's own file types (e.g. `.snap`/`.ambr`-equivalent snapshot fixtures if R33 adopts `insta`)?

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
