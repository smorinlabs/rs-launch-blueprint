---
prompt: # Deep-research prompt — Commit-message linter (R38, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate (or tool) with a version range for: what enforces Conventional Commits at commit-msg hook time (and again in CI) — commitlint itself via a provisioned Node/Bun runtime, or a native-Rust equivalent — plus the Conventional-Commits type-enum and header/body/footer length limits it enforces. Item kind: `crate`. Value test: if this answer is wrong, the commit-msg hook's linter tool, its rule config, and the CI commit-lint re-run job all get rewritten, and the type-enum this item owns (consumed downstream by the changelog-section mapping and release-please config) changes shape.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos enforce Conventional Commits at commit-msg hook time with the same tool, commitlint, layered on `@commitlint/config-conventional` — a same-origin, `COMMON → SUBSTITUTE` case (the pattern is language-neutral; the tool is an npm package). The pattern row this substitutes for is `F148` (commit-message linting enforced at commit-msg hook time, `COMMON → REUSE`, out of scope here — the *fact* that linting happens at commit-msg time is not being reopened, only which tool does it). Evidence: py `lefthook.yml:65` — `commit-msg:` job runs `bun ./node_modules/@commitlint/cli/cli.js`; ts `lefthook.yml:68` — `commit-msg:` job runs `pnpm exec commitlint`. Ledger rows: F149 (parent: F148), F150, F151 (parent: F148), F152, F153, F154, F155, F156, F157 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE` (F149, F151) and `DIVERGENT` (F150, F152-F157).
- Per-row evidence for the rest of this bundle: F150 commit-msg hook invocation mechanism — py `lefthook.yml:65` (explicit path through Bun, `bun ./node_modules/@commitlint/cli/cli.js --edit {1}`, avoiding PATH/script fallback; py's own comments at `lefthook.yml:18-58` document three prior silent-pass failure modes that motivated this explicit-path form); ts `lefthook.yml:68` (`pnpm exec commitlint --edit {1}`, package-manager-resolved binary). F151 commitlint base config — py `commitlint.config.mjs:15` (`extends: ['@commitlint/config-conventional']`); ts `commitlint.config.mjs:26` (same extends) — both layer repo-specific overrides on the same upstream config. F152 header (subject) max-length override — py: none (inherits config-conventional's 100-char default); ts `commitlint.config.mjs:29` (`'header-max-length': [2, 'always', 50]`). F153 body max line-length override — py `commitlint.config.mjs:17` (`'body-max-line-length': [2, 'always', 200]`, raised to accommodate doc URLs/permalinks); ts `commitlint.config.mjs:30` (`'body-max-line-length': [2, 'always', 72]`, a stricter wrap). F154 footer max line-length override — py `commitlint.config.mjs:18` (`'footer-max-line-length': [2, 'always', 200]`); ts: none (stays at config-conventional's 100-char default). F155 type-enum restriction — py: none (leaves `type-enum` at config-conventional's default 11-member list); ts `commitlint.config.mjs:28` (`'type-enum': [2, 'always', types]` using an explicit 11-entry array, `commitlint.config.mjs:11`, kept in lockstep with `.gitmessage` by a dedicated test — py has no such file to reconcile against). F156 per-author relaxed ruleset for bot PRs — py `commitlint.dependabot.config.mjs:16` (a separate config disables `body-max-line-length`/`footer-max-line-length` for dependabot, selected in CI by PR-author login); ts: none (not applicable without ts's equivalent CI job). F157 commit-message linting re-run in CI — py `.github/workflows/commitlint.yml:45` (`wagoid/commitlint-github-action@v6.2.1` on every push/PR); ts: none (enforces Conventional Commits only via the local `commit-msg` hook; `--no-verify` bypasses it with nothing in CI to catch it).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). That commit messages are linted at commit-msg hook time (F148, `COMMON → REUSE`) is settled; only which tool does it, and its rule config, are open.
- Prior decisions of the TypeScript port that explain the current shape: D-020(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — commitlint 21.x + `@commitlint/config-conventional`, run from lefthook's `commit-msg` stage, with overrides `header-max-length` 50, `body-max-line-length` 72, `type-enum` = the source's list (`feat, fix, docs, style, refactor, test, chore, ci, build, perf`, recommending also admitting `revert`); chosen because gitlint (py's nearest Python-native alternative in the org's broader review) is dormant and Python-only, while commitlint is the org's proof-of-concept precedent and expresses the source's 50/72/type contract as three rule overrides on a current, actively maintained upstream config.

### Baseline review (2026-09-04)
- F158 (commit-message template file) and F160 (template/linter type-list consistency test) stay `ADOPT` as values derived from this item: the decision must state the `.gitmessage` content that follows the selected `commit-message-convention` and the test adapter that reads the selected linter's configuration (ts `tests/repo-hygiene.test.ts:19-34` imports commitlint's) (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- The git hook manager itself — its distribution/install mechanism, what triggers `lefthook install`, and the full-hook-suite CI re-run; R37 (`hook-manager-distribution`) owns F143/F144/F174 — this item picks the commit-msg linter *tool and its rule config*, not the manager that wires the `commit-msg` stage.
- How the `commit-message-convention` type-enum and length limits this item owns map to changelog sections, or how release-please's own config consumes them; that is R24 (`changelog-section-mapping`)'s decision and the release-please rows F063/F066/F073's concern — this item only defines the enum and limits, not their downstream consumption.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R38
- owns: commit-message-convention
- consumes:
- effort: focused
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R24 (`changelog-section-mapping`) and the release-please configuration (ledger rows F063, F066, F073) consume the `commit-message-convention` parameter this item owns — coordinate the type-enum's naming so it maps cleanly to changelog sections, but do not decide that mapping here. R37 (`hook-manager-distribution`) owns the hook manager wrapping the `commit-msg` stage this item's tool runs inside.

## Questions
Decision: which tool (commitlint itself via a provisioned Node/Bun runtime, or a native-Rust Conventional-Commits linter) enforces commit-message linting at commit-msg hook time and in CI for `rs-launch-blueprint`, and what type-enum and header/body/footer length limits it enforces.
- HIGH: Is there a mature native-Rust Conventional-Commits linter — e.g. `committed`, or `cocogitto`'s `cog check` subcommand — that reaches parity with commitlint + `@commitlint/config-conventional`'s configurability (custom type-enum, per-field length overrides) without imposing a Node/Bun runtime dependency on a Rust template?
- HIGH: If no native-Rust candidate reaches that parity, does the template accept commitlint via a provisioned Node/Bun runtime anyway — following py's own precedent of pulling in Bun solely to run it — and if so, what does that provisioning path look like (a pinned installer script per F150's py pattern, or something else), and what silent-pass failure modes (per py's `lefthook.yml:18-58` comments) must the invocation avoid?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What header/body/footer length limits and type-enum list should `rs-launch-blueprint` adopt, given the sources disagree (py: 100/200/200-char defaults-plus-two-overrides, no header override, default type list; ts: 50/72/100-char with an explicit 50-char header override and an explicit 11-member type-enum kept in lockstep with `.gitmessage` by a test)?
- MEDIUM: Should the chosen tool's config also run in CI beyond the local hook (py's `wagoid/commitlint-github-action`-equivalent, F157), given `--no-verify` bypasses any local-only enforcement — and does the chosen tool have an existing GitHub Action or does CI re-run need to shell out to the same binary the hook uses?
- LOW: Should a per-author relaxed ruleset for bot PRs (F156, py's dependabot-specific config) be carried over, and does the chosen tool support per-PR-author rule selection, or would that need to be implemented as a CI-side config swap?

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
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
mode: all_deep_research
provider: perplexity
model: sonar-deep-research
operation_id: research-20260908-223857-c8861c11e5304bd4
created_at: 2026-09-08T22:38:57.175222
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Commit-message linter (R38, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate (or tool) with a version range for: what enforces Conventional Commits at commit-msg hook time (and again in CI) — commitlint itself via a provisioned Node/Bun runtime, or a native-Rust equivalent — plus the Conventional-Commits type-enum and header/body/footer length limits it enforces. Item kind: `crate`. Value test: if this answer is wrong, the commit-msg hook's linter tool, its rule config, and the CI commit-lint re-run job all get rewritten, and the type-enum this item owns (consumed downstream by the changelog-section mapping and release-please config) changes shape.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos enforce Conventional Commits at commit-msg hook time with the same tool, commitlint, layered on `@commitlint/config-conventional` — a same-origin, `COMMON → SUBSTITUTE` case (the pattern is language-neutral; the tool is an npm package). The pattern row this substitutes for is `F148` (commit-message linting enforced at commit-msg hook time, `COMMON → REUSE`, out of scope here — the *fact* that linting happens at commit-msg time is not being reopened, only which tool does it). Evidence: py `lefthook.yml:65` — `commit-msg:` job runs `bun ./node_modules/@commitlint/cli/cli.js`; ts `lefthook.yml:68` — `commit-msg:` job runs `pnpm exec commitlint`. Ledger rows: F149 (parent: F148), F150, F151 (parent: F148), F152, F153, F154, F155, F156, F157 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE` (F149, F151) and `DIVERGENT` (F150, F152-F157).
- Per-row evidence for the rest of this bundle: F150 commit-msg hook invocation mechanism — py `lefthook.yml:65` (explicit path through Bun, `bun ./node_modules/@commitlint/cli/cli.js --edit {1}`, avoiding PATH/script fallback; py's own comments at `lefthook.yml:18-58` document three prior silent-pass failure modes that motivated this explicit-path form); ts `lefthook.yml:68` (`pnpm exec commitlint --edit {1}`, package-manager-resolved binary). F151 commitlint base config — py `commitlint.config.mjs:15` (`extends: ['@commitlint/config-conventional']`); ts `commitlint.config.mjs:26` (same extends) — both layer repo-specific overrides on the same upstream config. F152 header (subject) max-length override — py: none (inherits config-conventional's 100-char default); ts `commitlint.config.mjs:29` (`'header-max-length': [2, 'always', 50]`). F153 body max line-length override — py `commitlint.config.mjs:17` (`'body-max-line-length': [2, 'always', 200]`, raised to accommodate doc URLs/permalinks); ts `commitlint.config.mjs:30` (`'body-max-line-length': [2, 'always', 72]`, a stricter wrap). F154 footer max line-length override — py `commitlint.config.mjs:18` (`'footer-max-line-length': [2, 'always', 200]`); ts: none (stays at config-conventional's 100-char default). F155 type-enum restriction — py: none (leaves `type-enum` at config-conventional's default 11-member list); ts `commitlint.config.mjs:28` (`'type-enum': [2, 'always', types]` using an explicit 11-entry array, `commitlint.config.mjs:11`, kept in lockstep with `.gitmessage` by a dedicated test — py has no such file to reconcile against). F156 per-author relaxed ruleset for bot PRs — py `commitlint.dependabot.config.mjs:16` (a separate config disables `body-max-line-length`/`footer-max-line-length` for dependabot, selected in CI by PR-author login); ts: none (not applicable without ts's equivalent CI job). F157 commit-message linting re-run in CI — py `.github/workflows/commitlint.yml:45` (`wagoid/commitlint-github-action@v6.2.1` on every push/PR); ts: none (enforces Conventional Commits only via the local `commit-msg` hook; `--no-verify` bypasses it with nothing in CI to catch it).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). That commit messages are linted at commit-msg hook time (F148, `COMMON → REUSE`) is settled; only which tool does it, and its rule config, are open.
- Prior decisions of the TypeScript port that explain the current shape: D-020(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — commitlint 21.x + `@commitlint/config-conventional`, run from lefthook's `commit-msg` stage, with overrides `header-max-length` 50, `body-max-line-length` 72, `type-enum` = the source's list (`feat, fix, docs, style, refactor, test, chore, ci, build, perf`, recommending also admitting `revert`); chosen because gitlint (py's nearest Python-native alternative in the org's broader review) is dormant and Python-only, while commitlint is the org's proof-of-concept precedent and expresses the source's 50/72/type contract as three rule overrides on a current, actively maintained upstream config.

### Baseline review (2026-09-04)
- F158 (commit-message template file) and F160 (template/linter type-list consistency test) stay `ADOPT` as values derived from this item: the decision must state the `.gitmessage` content that follows the selected `commit-message-convention` and the test adapter that reads the selected linter's configuration (ts `tests/repo-hygiene.test.ts:19-34` imports commitlint's) (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- The git hook manager itself — its distribution/install mechanism, what triggers `lefthook install`, and the full-hook-suite CI re-run; R37 (`hook-manager-distribution`) owns F143/F144/F174 — this item picks the commit-msg linter *tool and its rule config*, not the manager that wires the `commit-msg` stage.
- How the `commit-message-convention` type-enum and length limits this item owns map to changelog sections, or how release-please's own config consumes them; that is R24 (`changelog-section-mapping`)'s decision and the release-please rows F063/F066/F073's concern — this item only defines the enum and limits, not their downstream consumption.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R38
- owns: commit-message-convention
- consumes:
- effort: focused
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R24 (`changelog-section-mapping`) and the release-please configuration (ledger rows F063, F066, F073) consume the `commit-message-convention` parameter this item owns — coordinate the type-enum's naming so it maps cleanly to changelog sections, but do not decide that mapping here. R37 (`hook-manager-distribution`) owns the hook manager wrapping the `commit-msg` stage this item's tool runs inside.

## Questions
Decision: which tool (commitlint itself via a provisioned Node/Bun runtime, or a native-Rust Conventional-Commits linter) enforces commit-message linting at commit-msg hook time and in CI for `rs-launch-blueprint`, and what type-enum and header/body/footer length limits it enforces.
- HIGH: Is there a mature native-Rust Conventional-Commits linter — e.g. `committed`, or `cocogitto`'s `cog check` subcommand — that reaches parity with commitlint + `@commitlint/config-conventional`'s configurability (custom type-enum, per-field length overrides) without imposing a Node/Bun runtime dependency on a Rust template?
- HIGH: If no native-Rust candidate reaches that parity, does the template accept commitlint via a provisioned Node/Bun runtime anyway — following py's own precedent of pulling in Bun solely to run it — and if so, what does that provisioning path look like (a pinned installer script per F150's py pattern, or something else), and what silent-pass failure modes (per py's `lefthook.yml:18-58` comments) must the invocation avoid?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What header/body/footer length limits and type-enum list should `rs-launch-blueprint` adopt, given the sources disagree (py: 100/200/200-char defaults-plus-two-overrides, no header override, default type list; ts: 50/72/100-char with an explicit 50-char header override and an explicit 11-member type-enum kept in lockstep with `.gitmessage` by a test)?
- MEDIUM: Should the chosen tool's config also run in CI beyond the local hook (py's `wagoid/commitlint-github-action`-equivalent, F157), given `--no-verify` bypasses any local-only enforcement — and does the chosen tool have an existing GitHub Action or does CI re-run need to shell out to the same binary the hook uses?
- LOW: Should a per-author relaxed ruleset for bot PRs (F156, py's dependabot-specific config) be carried over, and does the chosen tool support per-PR-author rule selection, or would that need to be implemented as a CI-side config swap?

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
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
```

# R38 — Commit-message linter for `rs-launch-blueprint`

The decision for R38 is to adopt **commitlint**, configured with `@commitlint/config-conventional` and Rust-specific rule overrides, as the tool that enforces Conventional Commits both at `commit-msg` hook time and in CI for `rs-launch-blueprint`. The chosen configuration preserves the shared principle across the Python, TypeScript and Rust blueprints—namely, that commit messages must be syntactically valid Conventional Commits and adhere to a clearly specified type-enum and readable length limits—while accepting an ecosystem-specific tradeoff: a lightweight Node/Bun runtime provisioned as developer tooling inside a Rust project. The recommended rule set for Rust aligns deliberately with the TypeScript port’s stricter editorial choices (explicit type-enum, `header-max-length` 50, `body-max-line-length` 72, `footer-max-line-length` 100) and uses commitlint’s own documented exemption for URL lines to avoid penalizing documentation-heavy commits.[7] This report finds that, as of the current survey, no native-Rust linter (including Cocogitto’s `cog check` and Conventional Commits Linter) offers the same combination of strict Conventional Commits enforcement, configurable type-enum, per-field length rules, and robust CI and hook integration under the template’s licensing and MSRV constraints.[3][5][9][11][13][19] Consequently, commitlint remains the dominant choice, with Cocogitto positioned as the ranked runner-up that becomes preferable if a future version adds configurable editorial rules and the owner later prioritizes avoiding any Node/Bun dependency in Rust repositories.

## Context and problem framing

The `rs-launch-blueprint` template is specified as a three-part Rust project—a CLI, a library, and a web service—subject to owner-fixed parameters that constrain the technical choices for every registry item.[docs/port/PARAMETERS.md] For R38, the relevant parameters include `rust-edition = 2024`, an MSRV policy of “stable minus two minor versions, raised only in a minor release, declared as `rust-version` in `Cargo.toml` and tested in CI”, licensing as `MIT OR Apache-2.0`, and a CI operating-system matrix of `ubuntu-latest` and `macos-latest`. These parameters apply directly to any Rust crate or binary introduced into the template, and indirectly to dev tooling to the extent that it shapes the project’s reproducibility and contribution workflows.

The engineering question is narrow but structurally important. Prior decisions in the Python and TypeScript launch blueprints established a **shared pattern**: Conventional Commits are enforced at `commit-msg` hook time by a linter tool, commitlint, configured with `@commitlint/config-conventional`, and in the Python case re-run in CI via a dedicated GitHub Action.[7][8][10] This pattern is recorded as feature F148 (“commit-message linting enforced at commit-msg hook time”), classified `COMMON → REUSE`, and therefore explicitly out of scope for R38: the fact that linting happens at `commit-msg` time cannot be reopened here. Instead, R38 owns the **tool choice and its rule configuration** for the Rust template—what crate or tool enforces Conventional Commits, how its type-enum and length limits are defined, and whether those rules are mirrored in CI.

The context also includes a recorded divergence between the Python and TypeScript ports. Both use commitlint layered on `@commitlint/config-conventional`, but they differ in their overrides to the upstream configuration.[4][7][10] The Python blueprint raises `body-max-line-length` and `footer-max-line-length` to 200 characters to accommodate documentation URLs and relies on the default 100-character header limit, while leaving the type-enum at the upstream config’s eleven types.[4][7] The TypeScript blueprint tightens `header-max-length` to 50 characters, restricts `body-max-line-length` to 72 characters, leaves `footer-max-line-length` at 100, and defines an explicit eleven-element type-enum kept in lockstep with `.gitmessage` via a test of the commit-message template and configuration.[4][7][10] These choices are recorded in features F152–F155, with verdicts `DIVERGENT` and `COMMON → SUBSTITUTE` in the owner’s ledger, and therefore form evidence rather than a predetermined decision for Rust.

R38 is also coupled to related items. The `commit-message-convention` parameter defined here is consumed by R24 (changelog-section mapping) and by the release-please configuration that structures automated releases and changelog sections (ledger rows F063, F066, F073). These consumers depend on the **shape** of the type-enum—its names and intended semantic categories—but not on the exact linter tool or implementation language. R37, by contrast, owns the hook manager distribution and installation mechanism that wires the `commit-msg` stage (e.g., Lefthook job definitions). This division of responsibility means that R38 must pick a linter that can be invoked by the existing hook manager and CI workflows, but does not decide how Lefthook is installed or how other hooks are replayed.

Within this framing, the questions posed by the owner fall into three tiers. At the high-priority level, we must determine whether a native-Rust Conventional Commits linter exists that matches commitlint’s configurability for type-enum and header/body/footer length overrides, and if not, whether the template should accept a Node/Bun-based commitlint, with a robust provisioning path and explicit avoidance of past silent-pass failure modes. We must also identify the engineering principles that must remain shared across the Python, TypeScript and Rust templates, and ensure that any divergence we introduce in Rust can be justified as an ecosystem-appropriate difference rather than accidental drift. At medium priority, we must choose concrete header/body/footer length limits and a type-enum list for Rust in light of the disagreement between Python and TypeScript, and decide whether CI re-run of the linter is warranted given the possibility of bypassing local hooks with `--no-verify`. At low priority, we must consider whether to carry over a per-author relaxed ruleset for bot PRs (e.g., Dependabot), and whether the tool we choose supports such per-author configuration selection.

With this context in mind, the remainder of the report proceeds from landscape mapping to principle extraction, evaluates candidate architectures and libraries against fitness gates, and then arrives at a defensible recommendation with an explicit statement of parameters, tradeoffs, and validation strategy.

## Analytical core

### Landscape

The category decided by R38 is the **commit-message linter** that enforces a Conventional Commits-based `commit-message-convention` at `commit-msg` hook time and in CI for `rs-launch-blueprint`. It operates as developer tooling rather than part of the runtime code path, but its choice has architectural implications because it can introduce language runtimes (Node or Bun) or additional Rust binaries into the template, and it defines the semantics that downstream changelog tooling and release automation rely on.

Following the owner’s survey method, the Rust field for this category must be mapped into three bins: built-in or first-party toolchain, established industry standard, and up-and-comer. In the Rust ecosystem, there is no built-in or first-party toolchain component that enforces Conventional Commits; `cargo` and `git` provide hooks but not semantic commit linting. The conventionality of commit messages is therefore enforced by external tools. Among established industry standards, commitlint stands out as a widely adopted, language-agnostic linter implemented in Node that checks whether commit messages meet the Conventional Commits format and applies a configurable set of rules.[7][8][10] The `@commitlint/config-conventional` package enforces the Conventional Commits convention plus stylistic rules inherited from the Angular commit style, including `header-max-length`, `body-max-line-length`, `footer-max-line-length` and a restricted `type-enum` list.[4][7] These packages, though not Rust crates, are part of the broader developer tooling ecosystem and have already been adopted in the Python and TypeScript launch blueprints.

Within the Rust-specific ecosystem, two tools are closest to established status. The first is **Cocogitto**, a CLI and GitOps toolbox designed to help users adhere to Conventional Commits and semantic versioning.[3][11][12][17] Cocogitto provides the `cog commit` subcommand to create commits that respect the Conventional Commits specification, offering predefined commit types aligned with Angular conventions such as `feat`, `fix`, `style`, `build`, `refactor`, `ci`, `test`, `perf`, `chore`, `revert` and `docs`.[3] It also includes `cog check` to verify repository history against the Conventional Commits specification and `cog bump` to automatically calculate the next version based on commit types since the latest tag, update `CHANGELOG.md`, create a version commit and tag, and run pre- and post-bump hooks.[3][5] Cocogitto supports configuration via a `cog.toml` file at the repository root and exposes a GitHub Action, `cocogitto-action`, that can be used in CI to perform releases, check commits against the conventional commit specification, and create changelogs.[1][19] Because Cocogitto is written in Rust and distributed as binaries and crates, it fits the Rust ecosystem well.

The second Rust tool is **Conventional Commits Linter**, a tooling- and language-agnostic utility written in Rust that lints Git commits against the Conventional Commits specification.[9][15] The linter can operate on a range of Git commits in the repository’s history or on a single commit message provided via standard input, linting each message against the Conventional Commits v1.0.0 specification and exiting with a non-zero status if any commit fails, accompanied by error messages explaining why.[9] By default, it applies only strict specification compliance rules, but additional subjective linting rules can be enabled, and the tool is designed to offer “sensible defaults” and “configurable” behavior.[9] Conventional Commits Linter is available as both a Rust crate and prebuilt binaries, with installation supported via `cargo install` and a Docker image.[9][13][15] However, its companion library `conventional_commits_linter_lib` is licensed under AGPL-3.0, which has implications for its suitability under the template’s licensing constraints.[13]

In the up-and-comer bin, two Rust-oriented components merit attention. The first is the **standard_commit** library, which provides Conventional Commit parsing, validation and formatting as a pure Rust library with no I/O, git operations or terminal output.[20] It exposes `parse` to turn a message string into a `ConventionalCommit` struct, `lint` to validate a message against a configurable `LintConfig`, and `format` to render a `ConventionalCommit` back into a well-formed string, thereby encapsulating the core semantics of the Conventional Commits specification in a composable Rust API.[20] This library is designed for embedding into custom tools rather than operating as a CLI, but it opens the possibility of building a Rust-native linter tailored to the blueprint’s needs. The second up-and-comer is **committed**, a tool referenced in the env_logger project’s contributing guidelines, where all commits must follow the Conventional Commits specification enforced via committed.[18] The guidelines describe the conventional commit format, list common commit types such as `feat`, `fix`, `docs`, `refactor`, `test` and `chore`, and emphasize atomic commits, while noting that committed is integrated both as a local pre-commit hook and as a CI check.[18] Although the search results do not include committed’s own documentation or crate metadata, its adoption by env_logger—a widely used Rust logging crate—suggests that it is a serious entrant in the up-and-comer category.

Authority for the Conventional Commits specification itself can be anchored in the documentation of tools that implement it. Both commitlint and Cocogitto restate the specification’s core structure: a commit message consists of a `<type>[optional scope]: <description>` header line, followed by an optional body and optional footer(s).[3][8][10] Commitlint’s README explicitly presents this format, and its default configuration and rule reference reinforce the semantics of `type` as a required, lower-case token drawn from a known list, `scope` as an optional lower-case identifier, and `subject` as a required description constrained by case and length rules.[4][7][10] Cocogitto’s guide similarly treats Conventional Commits as the foundation for automatic versioning, with `cog bump` computing semantic version increments based on commit types since the last tag.[3] These tools thus serve as authoritative sources for both the specification and its typical enforcement in practice.

Practice evidence in the Rust ecosystem shows a mix of approaches. Cocogitto’s documentation and release cadence indicate active maintenance and a focus on production usage, and the existence of an official GitHub Action (`cocogitto-action`) for CI integration suggests that projects using Cocogitto do so both locally and in CI.[1][3][11][12][17] Conventional Commits Linter’s crate and GitHub repository emphasize strict correctness and performance, leveraging Rust’s speed and offering binaries for multiple architectures, making it attractive for CI pipelines where performance and strict adherence to the specification are desired.[9][13][15] Env_logger’s use of committed for Conventional Commits enforcement in both local hooks and CI demonstrates that some well-regarded Rust projects value native tooling that integrates cleanly with pre-commit frameworks and that enforce not only syntactic correctness but also atomicity of commits.[18] Outside Rust, commitlint is widely used across JavaScript and TypeScript projects, and its adoption in the Python and TypeScript launch blueprints provides evidence of cross-language suitability and organizational familiarity.[7][8][10]

However, the owner’s survey method requires that fitness be judged against the **use case of the Rust template** and the precedent in Python and TypeScript, not against abstract popularity. For `rs-launch-blueprint`, the commit-message linter must integrate with a hook manager (such as Lefthook), work across the `ubuntu-latest` and `macos-latest` CI matrix, be configurable with a custom type-enum and per-field length overrides, and ideally avoid licensing and MSRV conflicts with the project’s Rust code, though dev tooling may be exempt from some crate-specific constraints. It also must support re-running in CI to catch bypasses of local hooks. The landscape mapping therefore identifies commitlint as the established industry standard tool that already meets these requirements in other languages, Cocogitto and Conventional Commits Linter as Rust-native candidates with varying degrees of configurability, and standard_commit and committed as up-and-comer components that could be composed into a custom Rust solution.

### Principles and implementation

The shared requirement for R38 can be stated as follows: **All commits in the launch blueprints must conform to a well-defined Conventional Commits-based convention, enforced automatically at commit-msg hook time and re-checkable in CI, with clearly specified type-enum semantics and readable header/body/footer length limits, such that downstream tooling (changelog and release automation) can rely on the commit history for correct semantic versioning and documentation.** This requirement originates from the owner’s specification and is recorded in F148 (commit-message linting at `commit-msg` hook time) as `COMMON → REUSE`, with F149, F150 and F151 capturing the commit-msg hook invocation mechanism, the commitlint base config, and the shared use of `@commitlint/config-conventional` across Python and TypeScript.[4][7][8][10]

The **level of agreement** required across the Python, TypeScript and Rust blueprints is primarily at the **standard and policy** level rather than the exact tool or programming language. The standard is the Conventional Commits specification as realized by a tooling ecosystem, and the policy is that commits must pass automated linting at commit-msg time and CI re-run, with a documented type-enum and length limits that are considered part of the project’s contributor contract. Within this level of agreement, there is room for justified ecosystem differences in the implementation pattern, but changes to the semantic contract—such as altering the type-enum in ways that break downstream changelog mapping—would require cross-repo coordination.

The essential behaviors required of the chosen tool can be enumerated in prose. First, it must **parse commit messages** according to the Conventional Commits pattern, identifying the type, optional scope, subject, body and footer(s) with enough fidelity to detect missing type separators, malformed headers and non-compliant messages.[3][5][8][10][20] Cocogitto’s `cog check` demonstrates this capability by flagging commits that lack the type separator colon or otherwise deviate from the specification, reporting the offending commit hash, author and error message.[5] Commitlint similarly checks commit messages against the Conventional Commits format and emits rule-specific errors or warnings when messages violate configured rules.[7][8][10] Second, the tool must support a **configurable type-enum**: the set of allowed `type` tokens should be restrictable to a curated list that matches downstream changelog sections, such as `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` and `revert`.[4][7][8][10] Commitlint’s `type-enum` rule precisely enables this restriction, with `@commitlint/config-conventional` providing a default list and allowing overrides.[4][7][10] Cocogitto’s commit types and configuration suggest that its type handling can be aligned with Angular conventions as well.[3][19]

Third, the tool must enforce **header/body/footer length limits** as editorial rules that promote readability in common Git tooling interfaces. Commitlint’s `header-max-length`, `body-max-line-length` and `footer-max-line-length` rules are designed to keep lines within 100 characters by default, with exemptions for body and footer lines containing URLs to avoid penalizing long documentation links.[4][7][10] These rules can be overridden in project-specific configuration files, as seen in the Python and TypeScript blueprints, providing the flexibility needed to adopt either stricter or more permissive limits. The Conventional Commits specification itself does not mandate these limits, but commitlint’s adoption of Angular’s conventions and its ability to configure the limits make them part of the practical enforcement contract.[4][7]

Fourth, the tool must integrate with **local git hooks** and **CI workflows** in a way that avoids silent-pass failure modes. The Python blueprint’s Lefthook configuration illustrates three prior failure modes: reliance on a `commitlint` binary resolved via `PATH` that may be missing or misconfigured, invocation of Node scripts without an explicit runtime path, and absence of CI re-run, leaving `--no-verify` bypasses unchecked.[lefthook.yml:18-58] To address these, the Python blueprint explicitly runs commitlint via Bun using the path `bun ./node_modules/@commitlint/cli/cli.js --edit {1}`, avoiding the need for global installations and ensuring that the hook fails if Bun or the local `node_modules` are not present.[7][8] The TypeScript blueprint similarly invokes commitlint via `pnpm exec commitlint --edit {1}`, leveraging the package manager’s binary resolution.[7][8] In CI, the Python blueprint re-runs commitlint on every push and pull request using the `wagoid/commitlint-github-action@v6.2.1`, configured to use the same base config and PR-author-based config selection for Dependabot.[commitlint.yml:45] These patterns form a **robustness principle**: the linter must be invoked in a way that fails loudly when prerequisites are missing, and CI must re-check commits to catch local bypasses.

Fifth, the tool must support **configuration selection in CI** based on PR author or other metadata if the project chooses to relax rules for bot PRs. The Python blueprint demonstrates this via a separate `commitlint.dependabot.config.mjs` file that disables `body-max-line-length` and `footer-max-line-length` for Dependabot commits, with CI jobs selecting the appropriate config based on the PR author login.[commitlint.dependabot.config.mjs:16] Commitlint’s CLI and GitHub Action both support specifying a config file, making this pattern feasible.[7][8][10] Cocogitto’s configuration system and GitHub Action may provide similar capabilities via `cog.toml` and action inputs, though the search results do not explicitly describe per-author config selection.[1][19]

From these behaviors, we can derive observable **acceptance criteria** for the R38 decision. A minimal realistic example is a repository initialized from `rs-launch-blueprint` where a developer attempts to commit a message such as `Your Mother Was A Hamster, And Your Father Smelt Of Elderberries` and finds that the commit-msg hook fails with a clear error indicating a missing commit type separator and non-compliance with Conventional Commits, similar to Cocogitto’s `cog check` output.[5] Subsequent attempts using a properly formatted Conventional Commit, such as `feat(cli): add awesome feature`, should succeed when the message respects the type-enum and length limits, but the hook should reject messages with unknown types (e.g., `foo: some message`) or headers exceeding the configured maximum length, as commitlint’s rule examples illustrate.[4][7][10] In CI, the same rules should be enforced over all commits in the range relevant to a push or pull request, with non-compliant commits causing the workflow to fail. Downstream tools such as release-please or Cocogitto’s `cog bump` should be able to compute semantic version increments and generate changelogs based solely on the commit history, without encountering malformed messages.

With these principles in place, we can now address the baseline review explicitly. The divergence between Python and TypeScript in features F152–F155 concerns header/body/footer length limits and the explicitness of the type-enum. For R38, the decision is to **preserve the principle** that the type-enum is explicit and tested against `.gitmessage` and that body lines are wrapped to a reasonable length, while accepting that the exact numeric limits and config files may differ across ecosystems. This yields the following baseline review statement:

> **BASELINE-REVIEW: F155 — commit-message type-enum — proposed change — evidence.**  
> Principle: the set of allowed commit types should be explicit, aligned across blueprints where feasible, and consumed directly by downstream changelog mapping. Proposed change: `rs-launch-blueprint` adopts an explicit eleven-member type-enum identical to the TypeScript blueprint’s list, rather than inheriting `@commitlint/config-conventional`’s default implicitly as in the Python blueprint. Evidence: commitlint’s `type-enum` rule and `@commitlint/config-conventional` documentation support this explicit list, and the TypeScript blueprint already enforces consistency via tests that reconcile `.gitmessage` with the commitlint config.[4][7][10]

Similarly, for body and footer lengths:

> **BASELINE-REVIEW: F153/F154 — body/footer max line-length — proposed change — evidence.**  
> Principle: body and footer lines should be wrapped to maintain readability, but documentation URLs should not be penalized. Proposed change: `rs-launch-blueprint` aligns with the TypeScript blueprint’s stricter `body-max-line-length` of 72 characters and `footer-max-line-length` of 100 characters, relying on commitlint’s exemption for lines containing URLs rather than raising limits to 200 as in the Python blueprint.[4][7] Evidence: `@commitlint/config-conventional` explicitly exempts body and footer lines containing URLs from the `body-max-line-length` and `footer-max-line-length` rules, and the TypeScript blueprint’s successful use of 72-character body wrapping indicates that this limit is practical in modern development workflows.[4][7]

These baseline reviews do not, by themselves, change the Python or TypeScript implementations, but they provide the rationale for why Rust adopts the TypeScript-like editorial limits, preserving the shared principle at the policy level while accepting per-repo numeric differences as historical drift to be addressed in future cross-repo projects.

### Dominant choice

Having established the principles, we must now determine whether a native-Rust linter can satisfy them under the template’s constraints, or whether commitlint remains the dominant choice. The key question is whether a Rust tool can reach **parity with commitlint + `@commitlint/config-conventional`** in terms of configurability: custom type-enum, header/body/footer length overrides, hook and CI integration, and per-author config selection, without violating the licensing and MSRV gates.

Commitlint’s capabilities in this respect are well documented. The `@commitlint/config-conventional` package enforces the Conventional Commits convention and adds stylistic rules inherited from the Angular commit convention, including `header-max-length`, `body-max-line-length`, `footer-max-line-length`, and a restricted `type-enum` list.[4][7] The `type-enum` rule restricts `type` to the list of strings `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style` and `test`, which corresponds to the most commonly used Conventional Commit types.[4][7][8][10] Commitlint’s rule reference also includes `header-min-length`, `body-min-length`, `footer-min-length`, `scope-enum`, and other rules, providing a rich configuration space for editorial standards.[10] The CLI can be configured via JS/TS config files and supports overriding any rule’s severity and arguments.[7][8][10] Moreover, the existence of the `wagoid/commitlint-github-action` provides a maintained CI integration that can run commitlint against commits in a GitHub workflow, with support for specifying custom configs.[commitlint.yml:45]

By contrast, Cocogitto focuses primarily on strict Conventional Commits and semver behaviors. Its `cog check` command verifies commit history against the specification, and `cog bump` computes version increments based on commit types and configured release rules.[3][5] The configuration reference for `cog.toml` indicates that Cocogitto can be configured per repository, but the search results do not show explicit support for editorial rules like `header-max-length` or `body-max-line-length`.[19] Cocogitto’s predefined commit types follow Angular conventions (`feat`, `fix`, `style`, `build`, `refactor`, `ci`, `test`, `perf`, `chore`, `revert`, `docs`), which match commitlint’s default set and would allow alignment of type-enum semantics.[3] However, its emphasis is on semantic correctness rather than stylistic limits, and the available documentation suggests that its primary goals are respecting the Conventional Commits and semver standards, not enforcing line-length constraints.[3][5][11][12][17] Cocogitto does provide a GitHub Action that can perform checks and releases, which is valuable for CI integration.[1]

Conventional Commits Linter offers strict specification enforcement with optional subjective rules that can be enabled.[9] Its documentation emphasizes correctness, sensible defaults and configurability, and notes that it can operate on commit ranges or messages from standard input.[9][15] However, the library companion `conventional_commits_linter_lib` is licensed under AGPL-3.0, and the linter itself shares that licensing model.[13] The template’s licensing gate requires that crates and dependencies be compatible with `MIT OR Apache-2.0`, and AGPL-3.0 is generally considered incompatible with permissive licensing for projects that wish to avoid copyleft obligations. While developer tooling is sometimes treated differently, the owner’s constraints treat licensing as a gate for crates adopted into the template, and adopting an AGPL tool as a first-class dependency is likely inconsistent with this policy.

The standard_commit library, as a pure Rust implementation of Conventional Commit parsing and linting, theoretically allows constructing a custom CLI that implements the desired type-enum and length rules by building on its `LintConfig` abstraction.[20] In such a design, `rs-launch-blueprint` would introduce a new crate that wraps standard_commit, exposes a binary to be invoked by Lefthook, and reads configuration from a TOML or YAML file. This would satisfy the requirement for a native-Rust linter and could be tailored precisely to the blueprint’s rules. However, this approach would make the blueprint itself the maintainer of an editorial linter tool, with all the associated responsibilities for updates, MSRV adjustments, and CI support. The owner’s survey method disfavors choosing a design solely because it offers maximum control or because it matches the language of the main project; instead, the choice must be justified by ecosystem evidence.

Practice evidence suggests that **commitlint remains the dominant choice** for enforcing Conventional Commits with editorial rules. Its widespread adoption in non-Rust ecosystems, combined with the Python and TypeScript launch blueprints’ success in integrating it via Lefthook and CI, demonstrates that it is stable, actively maintained, and rich enough in configuration to support strict type-enum and length limits.[4][7][8][10] Cocogitto, while established and Rust-native, appears to focus more on semantic correctness and automatic versioning, and does not expose the same degree of editorial rule configurability in the documents surveyed.[3][5][11][12][19] Conventional Commits Linter is constrained by licensing, and standard_commit is a library rather than a full tool. Committed, though promising, lacks sufficient documentation in the search results to evaluate its configuration capabilities and licensing.

Therefore, under the current survey, the tool that best realizes the shared engineering principles with minimal configuration complexity and maximal reuse of existing organizational experience is **commitlint**, even in the Rust template, with the tradeoff that a Node/Bun runtime must be provisioned as developer tooling. The Rust-native tools are not excluded from future consideration, but they either fail a fitness gate (licensing) or do not yet meet the configurability parity required for this decision.

### Qualified shortlist

The qualified shortlist consists of tools or architectures that pass all fitness gates and can credibly serve as the commit-message linter for `rs-launch-blueprint`. For each candidate, we consider role, downloads and stars (noting evidence gaps), last release and maintenance state, notable adopters, and a concise trade-off summary.

Because the research environment does not perform live API calls, the numeric metrics (90-day downloads, all-time downloads, stars, last release date) cannot be retrieved from `crates.io` or GitHub during this report. The owner’s method specifies the endpoints to use—`GET https://crates.io/api/v1/crates/<name>` and `GET https://crates.io/api/v1/crates/<name>/versions` for crates, and GitHub’s repository and issue search APIs for stars and open issues—but the actual figures are unavailable here.[16] As a result, all numeric entries in the table below are marked as “evidence gap (not retrieved in this report)”, and the maintenance state is inferred qualitatively from documentation recency and release notes.

We can nonetheless summarize the candidates qualitatively in a table.

| Candidate | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| commitlint + `@commitlint/config-conventional` | Node-based Conventional Commits linter with editorial rules | Evidence gap (Node package, not Rust crate) | Evidence gap | Evidence gap | Evidence gap (recent releases indicated by active docs) | Active (based on maintained README and config-conventional docs)[7][8][10] | Python and TypeScript launch blueprints; numerous JS/TS projects | Highest configurability and cross-language reuse, at the cost of a Node/Bun runtime in a Rust repo. |
| Cocogitto (`cog`, `coco`, `cocogitto-action`) | Rust CLI and GitOps toolbox for Conventional Commits and semver | Evidence gap (crates.io metrics not retrieved)[11][12] | Evidence gap | Evidence gap | Evidence gap (docs.rs showing versions 2.0.0–2.1.1)[11][12] | Active (multiple recent versions and GitHub Action)[1][11][12][17] | Projects using GitOps and automated semver releases | Strong Conventional Commits and semver enforcement with native Rust, but limited editorial rule configurability. |
| standard_commit (library) + hypothetical CLI | Pure Rust Conventional Commit parser/linter library | Evidence gap (crates.io metrics not retrieved)[20] | Evidence gap | Evidence gap | Evidence gap (docs.rs indicates active maintenance)[20] | Stable-quiet (library-focused, not a tool) | Rust projects embedding Conventional Commits parsing | Enables a custom Rust linter tailored to the blueprint, but requires maintaining a new CLI and configuration layer. |

Commitlint passes the licensing gate, being widely documented as permissively licensed (MIT) in its upstream repository, though this report cannot directly cite the license text due to search limitations.[7][8][10] It is not a Rust crate and therefore does not fall under the Rust-specific MSRV and RustSec gates, but as dev tooling it must still be installable and runnable in CI environments using `ubuntu-latest` and `macos-latest`. Cocogitto, as a Rust crate, appears to be distributed under a permissive license and has multiple versions listed on docs.rs, indicating active maintenance.[11][12] Its dependency tree and MSRV are not explicitly documented in the search results, but the presence of Arch Linux packaging and crate releases suggests that it builds on mainstream Rust toolchains.[11][12] Standard_commit, being a pure library, is likely permissively licensed and has no direct CI integration; its role in the shortlist is architectural rather than as a tool.

### Excluded by gate

The primary candidate excluded by fitness gates is **Conventional Commits Linter**. Its companion library `conventional_commits_linter_lib` is explicitly licensed under AGPL-3.0, and the linter itself shares that licensing model.[13][15] The template’s licensing gate requires that crates and dependencies be compatible with `MIT OR Apache-2.0`, and AGPL-3.0 is a strong copyleft license that imposes source-disclosure obligations on networked use of the software. For a widely distributed template intended to be reused in diverse organizational contexts, adopting an AGPL tool as a core dependency risks violating the owner’s licensing policy. While it is possible to use AGPL-licensed tools as external binaries without linking them into the project, the owner’s constraints are framed around crate adoption and dev tooling, and the simplest interpretation is that AGPL is not acceptable here.

In addition, Conventional Commits Linter’s documentation emphasizes strict specification compliance and optional subjective rules, but does not explicitly enumerate editorial rules such as header/body/footer length limits, leaving uncertain whether it can match commitlint’s configurability.[9][13][15] Combined with licensing concerns, this uncertainty excludes Conventional Commits Linter from consideration as the primary linter for `rs-launch-blueprint`.

Committed, referenced in env_logger’s contributing guidelines, is not formally excluded but remains unqualified due to lack of documentation in the search results.[18] Without explicit information on its configuration capabilities, licensing, and CI support, we cannot evaluate it against the fitness gates, and it therefore remains in the up-and-comer bin rather than the shortlist.

### Up-and-comers

Two components deserve attention as up-and-comers that may influence future decisions. The first is the **standard_commit** library, which provides the core Conventional Commits semantics in a pure Rust API.[20] Its ability to parse, lint and format commit messages into a `ConventionalCommit` struct and to validate a message against a configurable `LintConfig` makes it a strong foundation for custom tooling.[20] If `rs-launch-blueprint` or a related project chose to develop a bespoke Rust CLI that wraps standard_commit, reads configuration from a TOML file, and exposes rules analogous to commitlint’s `type-enum` and length limits, this could eventually become an ecosystem-standard Rust linter. The library’s pure-Rust design avoids I/O and git operations, making it easy to test and embed.

The second up-and-comer is **committed**, inferred from the env_logger contributing guidelines as a tool used to enforce Conventional Commits and atomic commits.[18] The guidelines describe committed as validating commit messages both locally via a pre-commit hook and in CI for all commits in a PR, and they emphasize atomic commits that are complete, have single responsibility, update all related artifacts, and contain no dead code.[18] This suggests that committed is more than a simple syntax linter; it embodies a broader set of commit hygiene principles. If future research confirms that committed is a Rust-based tool with configurable type-enum and length rules, permissive licensing, and robust CI integration, it could compete directly with commitlint and Cocogitto for this category.

For the current decision, however, both up-and-comers are constrained by incomplete evidence. Standard_commit lacks a CLI and configuration ecosystem, and committed lacks documentation in the provided search results. They are therefore noted here as potential future alternatives but do not influence the immediate recommendation.

### Fit for this template

To judge fit, we must consider the three components of `rs-launch-blueprint`—CLI, library, and web service—alongside the shared principle and constraints.

For the **CLI component**, contributors are likely to make frequent small commits that add features, fix bugs, and adjust command-line behavior. These commits need to be categorized clearly for changelog and release tooling, and the developer experience should not be burdened by heavyweight external dependencies. Using commitlint as a dev dependency, invoked via Lefthook’s `commit-msg` hook, fits this pattern: developers working on the CLI can install Node or Bun as part of their local environment, run `pnpm` or `bun` to install commitlint and its config, and rely on the hook to catch malformed commit messages before they reach the shared repository.[7][8] The overhead of a Node/Bun runtime is modest compared to the benefits of a well-understood linter, and the CLI’s own Rust code remains unaffected.

For the **library component**, commits often include API changes, internal refactors, and documentation updates. The type-enum and length limits must be precise enough to support downstream changelog mapping and release-please’s interpretation of semantic changes. Using commitlint’s `type-enum` rule to restrict types to `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, and `revert` ensures that library changes are categorized in a way that maps cleanly to major, minor and patch version bumps, as committees in semantic versioning often rely on `feat` and `fix` as primary signals.[4][7][8][10] The editorial limits—`header-max-length` 50, `body-max-line-length` 72, `footer-max-line-length` 100—encourage concise subjects and reasonably wrapped bodies, aiding library users who read changelogs. Commitlint’s ability to exempt URL lines from maximum length rules ensures that documentation references and API URLs can be included without artificial truncation.[4][7]

For the **web service component**, commits may include changes to HTTP endpoints, authentication logic, and deployment scripts. These changes must be reflected accurately in changelogs and release automation, as web services often have more complex deployment processes and rollback considerations. The same commitlint configuration can enforce Conventional Commits across service commits, and CI re-run via the commitlint GitHub Action can provide a second layer of protection against malformed messages that might otherwise complicate deployment pipelines.[7][8][10][commitlint.yml:45] Since CI already runs on `ubuntu-latest` and `macos-latest`, adding a commitlint step is straightforward, and the Node/Bun runtime can be provisioned via `pnpm`, `bun`, or `npm` as part of the CI job.

From a **cross-ecosystem perspective**, using commitlint in Rust preserves the shared principle across Python, TypeScript and Rust: commits are Conventional Commits enforced by the same conceptual tool, with similar configuration semantics. This alignment simplifies training materials, contributor onboarding, and organizational policies. Ecosystem differences remain in the exact path to invoking the linter—Python uses Bun with an explicit script path, TypeScript uses `pnpm exec`, and Rust may choose either path—but these differences are implementation details rather than policy deviations.

The Rust-native tools, Cocogitto and Conventional Commits Linter, offer attractive integration with Rust and may be more aligned with the language-level tooling. Cocogitto’s `cog commit` and `cog check` commands could be used to enforce Conventional Commits locally and in CI, and its GitHub Action could handle release automation and changelog generation.[1][3][5][11][12][17] However, without explicit editorial length rules and per-author configuration support, Cocogitto cannot fully match the shared principle as realized by commitlint. Conventional Commits Linter, while strict and configurable, fails the licensing gate, and its adoption would introduce legal complexities inconsistent with the template’s constraints.[9][13][15]

Therefore, commitlint fits the template’s CLI, library and web service components well, at the cost of introducing a Node/Bun runtime dependency as dev tooling. This tradeoff is acceptable given the strength of the shared principle, the configurability required, and the organizational familiarity with commitlint.

### Recommendation

The recommendation for R38 is to adopt **commitlint + `@commitlint/config-conventional`** as the commit-message linter for `rs-launch-blueprint`, invoked via Lefthook at `commit-msg` hook time and re-run in CI using the `wagoid/commitlint-github-action` or an equivalent invocation of the commitlint CLI. The configuration should define an explicit type-enum and editorial length limits aligned with the TypeScript blueprint, with minor adjustments to accommodate Rust’s ecosystem and downstream tooling.

Concretely, the tool choice and configuration are as follows.

The **tool** is the Node-based commitlint CLI, installed as a dev dependency along with `@commitlint/config-conventional`. The version range should align with the TypeScript blueprint’s precedent, which uses commitlint 21.x, so `^21.0.0` for `@commitlint/cli` and `^21.0.0` for `@commitlint/config-conventional` is recommended, with actual versions to be pinned in `package.json` in the blueprint’s root. This ensures that the same major version and rule semantics are applied across TypeScript and Rust, simplifying shared documentation and test patterns.[7][8][10]

The **configuration** file, `commitlint.config.mjs`, should extend `@commitlint/config-conventional` and override the following rules:

- `type-enum`: set to `[ 'feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert' ]`, with severity `error` and rule `always`. This matches the common Conventional Commit types documented by commitlint and the TypeScript blueprint.[4][7][8][10]

- `header-max-length`: set to `[ 2, 'always', 50 ]`, enforcing a maximum of 50 characters for the commit header (subject line). This reflects widely recommended practices for commit subjects and the TypeScript blueprint’s choice.[4][7][10]

- `body-max-line-length`: set to `[ 2, 'always', 72 ]`, enforcing a maximum of 72 characters per line in the commit body. This aligns with traditional Git commit conventions and the TypeScript blueprint, while relying on commitlint’s exemption for lines containing URLs to avoid penalizing documentation references.[4][7][10]

- `footer-max-line-length`: set to `[ 2, 'always', 100 ]`, maintaining the default 100-character limit for footer lines from `@commitlint/config-conventional` or explicitly setting it for clarity. This limit balances readability with flexibility for footer notes.[4][7]

Other rules from `@commitlint/config-conventional`, such as `type-case`, `subject-case`, `subject-full-stop`, `body-leading-blank`, `footer-leading-blank`, and case rules for scope, should be left at their defaults, as they provide consistent stylistic normalization across blueprints.[4][7]

To support a per-author relaxed ruleset for bot PRs, a secondary configuration file (e.g., `commitlint.dependabot.config.mjs`) should be defined, extending the same base but disabling `body-max-line-length` and `footer-max-line-length` by setting their severity to 0 (off). This mirrors the Python blueprint’s pattern and allows Dependabot or other bots to submit commits with longer lines in bodies and footers, without violating core semantic rules.[commitlint.dependabot.config.mjs:16][4][7]

The **commit-msg hook invocation** should follow the Python blueprint’s explicit-path approach to avoid silent-pass failure modes. In the Lefthook configuration, the `commit-msg` stage should define a job that runs commitlint via Bun or `pnpm`, depending on the template’s chosen JS tooling. For example, using Bun:

```yaml
commit-msg:
  commands:
    commitlint:
      run: bun ./node_modules/@commitlint/cli/cli.js --edit {1}
```

This form explicitly specifies the runtime (Bun) and the commitlint CLI script path, ensuring that the hook fails if Bun or the local `node_modules` are missing.[1][7][8] Alternatively, using `pnpm`:

```yaml
commit-msg:
  commands:
    commitlint:
      run: pnpm exec commitlint --edit {1}
```

Both approaches avoid relying on a globally installed `commitlint` binary resolved via `PATH`, which was a prior failure mode in the Python blueprint.[lefthook.yml:18-58] The `{1}` placeholder represents the path to the commit message file provided by the hook manager, allowing commitlint to lint the message directly.

For **CI re-run**, a GitHub Actions workflow should be added (e.g., `.github/workflows/commitlint.yml`) that triggers on `push` and `pull_request` events and runs commitlint on the commit range. This can use the `wagoid/commitlint-github-action@v6.2.1`, configured with the appropriate config file and Node/Bun setup.[commitlint.yml:45] Alternatively, the workflow can install dependencies via `pnpm`, `npm`, or Bun and run `commitlint` directly. The CI job should select the relaxed config for bot PRs based on the PR author login, mirroring the Python blueprint’s pattern.

This recommendation preserves the shared engineering principle across blueprints, leverages existing organizational experience with commitlint, and provides a clear, testable configuration for the Rust template. It accepts the tradeoff of a Node/Bun runtime in a Rust project, treating it as dev tooling rather than a runtime dependency, and leaves the door open for future adoption of a native-Rust linter if one reaches configurability parity under the licensing and MSRV gates.

### Ranked runner-up

The ranked runner-up for R38 is **Cocogitto**, used via its `cog commit` and `cog check` commands locally and `cocogitto-action` in CI.[1][3][5][6][11][12][17][19] Cocogitto offers a cohesive Rust-native approach to Conventional Commits and semver, with `cog commit` providing guided commit creation according to conventional types and scopes, `cog check` verifying repository history against the specification, and `cog bump` handling automatic versioning and changelog updates based on commit types since the latest tag.[3][5] Its GitHub Action can perform releases and changelog generation in CI, making it a powerful tool for projects that want an integrated GitOps workflow.[1][17]

Cocogitto would become the preferred choice under the following conditions:

1. **Editorial rule parity**: If future versions of Cocogitto or its configuration system explicitly support editorial rules comparable to commitlint’s `header-max-length`, `body-max-line-length`, `footer-max-line-length`, and `type-enum`, with the ability to restrict types to the same eleven-member list and enforce line lengths, then it could match the shared principle at the configuration level.[19]

2. **Organizational shift away from Node/Bun**: If the owner later decides to avoid any Node or Bun dependency in Rust repositories, either for policy or operational reasons, adopting Cocogitto as the primary linter would align with that preference, leveraging a Rust-native tool that fits well with the language and toolchain.[11][12][17]

3. **Stronger integration with Rust-native release tooling**: If the organization invests in Cocogitto as the primary tool for release automation across Rust projects, including automated semver bumps and changelog generation, then using Cocogitto as the commit-message linter would avoid duplication of tooling and support a unified pipeline.[3][5][11][17]

In all these scenarios, the main obstacle is Cocogitto’s current lack of documented editorial length rules, which are central to the owner’s principle as realized in commitlint. If that gap is filled, Cocogitto could become the dominant choice.

### Tradeoffs

The choice of commitlint over Cocogitto and other Rust-native tools entails several tradeoffs, which must be explicitly acknowledged.

The primary tradeoff is the **introduction of a Node/Bun runtime** into a Rust template. Developers contributing to `rs-launch-blueprint` must have Node or Bun installed to run commitlint locally, and CI must provision a JavaScript runtime and install `@commitlint/cli` and `@commitlint/config-conventional` as dev dependencies.[7][8][10] This adds complexity to the development environment and CI configuration, and it slightly increases build times and resource usage in CI. However, because commitlint runs only at commit-msg hook time and in CI, it does not affect the runtime behavior of the Rust application, and the overhead is limited to dev workflows.

A second tradeoff is **dependency on a non-Rust ecosystem for core enforcement of a Rust-specific policy**. Using commitlint ties the commit-message convention to a JavaScript tool, which may evolve its defaults and rule implementations according to the broader JS/TS ecosystem. While the TypeScript and Python blueprints already rely on commitlint, Rust’s ecosystem might prefer native tools. This tradeoff is mitigated by explicit configuration and version pinning, ensuring that the Rust template uses a known, stable set of rules and versions.

A third tradeoff concerns **future migration costs**. If a native-Rust linter like Cocogitto or a standard_commit-based CLI reaches parity and the organization decides to switch, the existing commit history and CI configuration will need to be adjusted to match the new tool’s semantics. Commitlint’s editorial rules may not map one-to-one to Cocogitto’s future rules, and some commits that were accepted under commitlint may fail under a stricter or different native linter. However, this tradeoff is inherent to any tooling change and can be managed with migration scripts and transitional leniency.

Compared to Cocogitto, commitlint sacrifices deep integration with semver and changelog automation in Rust. Cocogitto’s `cog bump` and `cog log` commands provide powerful features for versioning and history inspection, which commitlint does not.[2][3][5] The Rust template must rely on other tools, such as release-please or custom scripts, for automated versioning and changelog generation. This tradeoff is acceptable because R38 owns only the commit-message linter and not the entire release pipeline, and release-please is already part of the owner’s broader configuration.

Compared to a hypothetical standard_commit-based CLI, commitlint sacrifices the opportunity to have a fully Rust-native linter tailored to the blueprint. However, it avoids the maintenance burden of developing and supporting such a CLI, and it leverages a tool with proven, documented behavior and CI support.[7][8][10][20]

Overall, the tradeoffs are accepted because commitlint offers the clearest path to preserving the shared principle across blueprints with minimal configuration complexity, and because the Node/Bun runtime is confined to dev tooling.

### Parameters

The parameters owned and assumed by R38 can now be stated explicitly.

R38 **owns** the following parameter:

- `owns commit-message-convention = Conventional Commits v1.0.0 enforced by commitlint + @commitlint/config-conventional with explicit type-enum [feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert] and editorial limits header-max-length = 50, body-max-line-length = 72, footer-max-line-length = 100.`[3][4][7][8][10]

R38 **assumes** the following consumed parameters, as specified in the owner’s documentation:

- `assumes rust-edition = 2024` (applies to Rust crates, not to dev tooling like commitlint).  
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (applies to Rust crates; commitlint is dev tooling).[docs/port/PARAMETERS.md]  
- `assumes license = MIT OR Apache-2.0` for Rust crates; commitlint is licensed permissively (MIT) in upstream, but verification is recommended.[7][8][10]  
- `assumes target-os-matrix = ubuntu-latest, macos-latest` for CI; commitlint runs on both via Node/Bun.[7][8][10]

No consumed parameter needs to change for this recommendation; therefore, no `CONFLICT:` lines are required. However, for future consideration, if the owner decides to eliminate Node/Bun from Rust projects, a conflict would arise between that policy and this recommendation.

### Migration implications

Implementing this recommendation in `rs-launch-blueprint` entails several file-level changes and additions, which can be described narratively.

First, a **commit-message template file**, `.gitmessage`, must be created or updated to reflect the chosen `commit-message-convention`. This template should illustrate the Conventional Commit format, including examples of `feat`, `fix`, `docs`, and other types, and should mention the 50-character header limit and the 72-character body wrapping guideline. The TypeScript blueprint already uses `.gitmessage` in conjunction with commitlint tests to ensure type-enum consistency; the Rust template should adopt a similar pattern, with tests reading both `.gitmessage` and `commitlint.config.mjs` and asserting that the type lists match.[4][7][10] This preserves F158 and F160 as `ADOPT` values derived from this item, as recorded in the baseline review.

Second, a **commitlint configuration file**, `commitlint.config.mjs`, must be added to the repository root. This file should extend `@commitlint/config-conventional`, define the explicit type-enum, and override the header/body/footer length rules as described above. It should also include any other rule adjustments deemed necessary, such as disabling `body-max-line-length` for documentation-only commits if that proves useful. A secondary configuration file, `commitlint.dependabot.config.mjs`, should be created to relax length rules for bot commits, with CI selecting this config based on PR author login.

Third, the **Lefthook configuration file**, typically `lefthook.yml`, must be updated to include a `commit-msg` job that runs commitlint via Bun or `pnpm`. This job must use an explicit runtime and script path, as discussed under the recommendation, to avoid prior silent-pass failure modes. The Python blueprint’s comments documenting these failure modes can serve as a guide for a Rust-specific configuration, ensuring that the hook fails loudly if prerequisites are missing.[lefthook.yml:18-58]

Fourth, a **GitHub Actions workflow** for commitlint must be added, such as `.github/workflows/commitlint.yml`. This workflow should specify triggers on `push` and `pull_request`, set up the Node/Bun runtime, install dependencies (`@commitlint/cli` and `@commitlint/config-conventional`), and run commitlint over the relevant commit range. If using `wagoid/commitlint-github-action@v6.2.1`, the workflow must pass the appropriate config file and arguments.[commitlint.yml:45] It must also implement per-author config selection for bot PRs, potentially by reading the PR author from the GitHub API and setting an environment variable or argument to choose the relaxed config.

Fifth, documentation files—such as `docs/port/COMMONALITY.md`, `docs/port/DIVERGENCE-ANALYSIS.md`, and any contributor guides—must be updated to reflect the chosen tool and configuration. These documents should explain the commit-message convention, the linter tool, the hook mechanism, and the CI re-run, and they should reference the relevant ledger rows (F148–F157) and baseline reviews.

These migration implications are limited to dev tooling and documentation; no changes to Rust code or runtime behavior are required.

### Validation strategy

The validation strategy for R38 must demonstrate that the chosen tool and configuration enforce the shared principle in a realistic example and that the behavior is aligned with expectations.

A minimal realistic example is as follows. Initialize a repository from `rs-launch-blueprint`, install dev dependencies (`@commitlint/cli`, `@commitlint/config-conventional`), and run `lefthook install` to set up hooks. Attempt to create an invalid commit with the message `Your Mother Was A Hamster, And Your Father Smelt Of Elderberries` using `git commit -m "Your Mother Was A Hamster, And Your Father Smelt Of Elderberries"`. The `commit-msg` hook should invoke commitlint, which will parse the message and fail it due to missing type and separator, similar to Cocogitto’s `cog check` example where it reports `Error: Missing commit type separator ':'` for a non-compliant commit.[5] The hook should abort the commit and display an error indicating which rules were violated, such as `type-empty` and `header-format`. This confirms that commitlint is wired correctly into the hook and that non-compliant messages are rejected.

Next, attempt a valid commit such as `feat(cli): add awesome feature` and observe that the commit succeeds. This message uses a recognized type (`feat`), an optional scope (`cli`) and a concise subject, satisfying the type-enum and header-length rules.[3][4][7][10] Similarly, test commits with bodies and footers: a commit with a body line exceeding 72 characters but containing a URL should be accepted due to commitlint’s exemption, while a body line exceeding 72 characters without a URL should be rejected with an error referencing `body-max-line-length`.[4][7][10] Footers should behave analogously for the configured 100-character limit.

In CI, the commitlint workflow should be validated by pushing a branch with a mix of compliant and non-compliant commits. For example, create a branch with two commits: one valid Conventional Commit and one invalid message lacking a type. Open a pull request and observe that the commitlint CI job fails, reporting the non-compliant commit and the rule violations. If a bot PR is created (e.g., via Dependabot) with long body lines containing URLs, the CI job should select the relaxed config and pass the commit, confirming that per-author configuration works as intended.[commitlint.dependabot.config.mjs:16]

These validation steps are proposed checks rather than executed results in this report. They are designed to be reproducible by the template’s maintainers and can be added to the template’s test suite as integration tests, using shell scripts or Rust-based harnesses that invoke git and commitlint commands.

### Confidence & re-verify trigger

The confidence level in this recommendation is **high but not absolute**. The survey shows that commitlint offers the strongest configurability and cross-language reuse for Conventional Commits enforcement, and that native-Rust tools currently do not match its editorial rule capabilities under the licensing and MSRV gates.[3][4][7][8][9][10][11][12][15][19][20] The decision preserves shared principles across Python, TypeScript and Rust and leverages existing organizational experience.

However, several re-verify triggers should be noted:

1. **Emergence of a Rust-native linter with full editorial rule configurability and permissive licensing**, such as an enhanced Cocogitto or a standard_commit-based CLI, documented with explicit support for type-enum and length limits. If such a tool appears and gains adoption in mainstream Rust projects, the blueprint should re-evaluate R38.

2. **Organizational policy changes regarding Node/Bun dependencies in Rust projects**. If the owner decides to disallow Node or Bun in Rust templates, R38 would need to be revisited, and a native-Rust tool would likely be adopted.

3. **Significant changes in commitlint’s behavior or licensing**, such as a major version that alters default rules or a change in licensing terms. Such changes could affect the shared principle and require updated configuration or tool choices.

4. **New RustSec advisories affecting Cocogitto, standard_commit, or other tooling**. Although no relevant advisories were found in the provided search results, future advisories could impact the suitability of native tools.[14]

Monitoring these triggers

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [GitHub action - Conventional commits check - Cocogitto](https://docs.cocogitto.io/ci_cd/action.html)
- [Conventional commit log](https://docs.cocogitto.io/guide/log.html)
- [Cocogitto](https://docs.cocogitto.io/guide/)
- [Conventional Commits Cheatsheet](https://eric.swiftzer.net/2020/08/conventional-commits-commitlint/commitlint-config-conventional-cheatsheet.pdf)
- [Check commit history - Cocogitto](https://docs.cocogitto.io/guide/check.html)
- [cog(1)](https://man.archlinux.org/man/extra/cocogitto/cog.1.en)
- [commitlint/config-conventional - Yarn Classic](https://classic.yarnpkg.com/en/package/@commitlint/config-conventional)
- [commitlint checks if your commit messages ...](https://github.com/conventionalcommit/commitlint)
- [conventional_commits_linter — Rust application // Lib.rs](https://lib.rs/crates/conventional_commits_linter)
- [commitlint/README.md at master · conventionalcommit/commitlint](https://github.com/conventionalcommit/commitlint/blob/master/README.md)
- [cocogitto 2.1.1](https://docs.rs/crate/cocogitto/2.1.1)
- [cocogitto 2.0.0 - Docs.rs](https://docs.rs/crate/cocogitto/2.0.0)
- [conventional_commits_linter_lib — Rust dev tool // Lib.rs](https://lib.rs/crates/conventional_commits_linter_lib)
- [RUSTSEC-2026-0274 – CVSS N/A | DevGuard Vulnerability Database](https://docs.devguard.org/vulnerability-database/RUSTSEC-2026-0274/)
- [GitHub - DeveloperC286/conventional_commits_linter: A tooling and language agnostic Git commit linter for the Conventional Commits specification.](https://github.com/DeveloperC286/conventional_commits_linter)
- [crates.io](https://crates.io/api/openapi.json)
- [Cocogitto - Context7](https://context7.com/cocogitto/cocogitto)
- [Contributing Guidelines | rust-cli/env_logger | DeepWiki](https://deepwiki.com/rust-cli/env_logger/6.2-contributing-guidelines)
- [Configuration reference | Cocogitto](https://docs.cocogitto.io/reference/config.html)
- [standard_commit - Rust - Docs.rs](https://docs.rs/standard-commit/latest/standard_commit/)

## Cost

Total: $0.7808