# Deep-research prompt — Commit-message linter (R38, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate (or tool) with a version range for: what enforces Conventional Commits at commit-msg hook time (and again in CI) — commitlint itself via a provisioned Node/Bun runtime, or a native-Rust equivalent — plus the Conventional-Commits type-enum and header/body/footer length limits it enforces. Item kind: `crate`. Value test: if this answer is wrong, the commit-msg hook's linter tool, its rule config, and the CI commit-lint re-run job all get rewritten, and the type-enum this item owns (consumed downstream by the changelog-section mapping and release-please config) changes shape.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos enforce Conventional Commits at commit-msg hook time with the same tool, commitlint, layered on `@commitlint/config-conventional` — a same-origin, `COMMON → SUBSTITUTE` case (the pattern is language-neutral; the tool is an npm package). The pattern row this substitutes for is `F148` (commit-message linting enforced at commit-msg hook time, `COMMON → REUSE`, out of scope here — the *fact* that linting happens at commit-msg time is not being reopened, only which tool does it). Evidence: py `lefthook.yml:65` — `commit-msg:` job runs `bun ./node_modules/@commitlint/cli/cli.js`; ts `lefthook.yml:68` — `commit-msg:` job runs `pnpm exec commitlint`. Ledger rows: F149 (parent: F148), F150, F151 (parent: F148), F152, F153, F154, F155, F156, F157 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE` (F149, F151) and `DIVERGENT` (F150, F152-F157).
- Per-row evidence for the rest of this bundle: F150 commit-msg hook invocation mechanism — py `lefthook.yml:65` (explicit path through Bun, `bun ./node_modules/@commitlint/cli/cli.js --edit {1}`, avoiding PATH/script fallback; py's own comments at `lefthook.yml:18-58` document three prior silent-pass failure modes that motivated this explicit-path form); ts `lefthook.yml:68` (`pnpm exec commitlint --edit {1}`, package-manager-resolved binary). F151 commitlint base config — py `commitlint.config.mjs:15` (`extends: ['@commitlint/config-conventional']`); ts `commitlint.config.mjs:26` (same extends) — both layer repo-specific overrides on the same upstream config. F152 header (subject) max-length override — py: none (inherits config-conventional's 100-char default); ts `commitlint.config.mjs:29` (`'header-max-length': [2, 'always', 50]`). F153 body max line-length override — py `commitlint.config.mjs:17` (`'body-max-line-length': [2, 'always', 200]`, raised to accommodate doc URLs/permalinks); ts `commitlint.config.mjs:30` (`'body-max-line-length': [2, 'always', 72]`, a stricter wrap). F154 footer max line-length override — py `commitlint.config.mjs:18` (`'footer-max-line-length': [2, 'always', 200]`); ts: none (stays at config-conventional's 100-char default). F155 type-enum restriction — py: none (leaves `type-enum` at config-conventional's default 11-member list); ts `commitlint.config.mjs:28` (`'type-enum': [2, 'always', types]` using an explicit 11-entry array, `commitlint.config.mjs:11`, kept in lockstep with `.gitmessage` by a dedicated test — py has no such file to reconcile against). F156 per-author relaxed ruleset for bot PRs — py `commitlint.dependabot.config.mjs:16` (a separate config disables `body-max-line-length`/`footer-max-line-length` for dependabot, selected in CI by PR-author login); ts: none (not applicable without ts's equivalent CI job). F157 commit-message linting re-run in CI — py `.github/workflows/commitlint.yml:45` (`wagoid/commitlint-github-action@v6.2.1` on every push/PR); ts: none (enforces Conventional Commits only via the local `commit-msg` hook; `--no-verify` bypasses it with nothing in CI to catch it).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). That commit messages are linted at commit-msg hook time (F148, `COMMON → REUSE`) is settled; only which tool does it, and its rule config, are open.
- Prior decisions of the TypeScript port that explain the current shape: D-020(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — commitlint 21.x + `@commitlint/config-conventional`, run from lefthook's `commit-msg` stage, with overrides `header-max-length` 50, `body-max-line-length` 72, `type-enum` = the source's list (`feat, fix, docs, style, refactor, test, chore, ci, build, perf`, recommending also admitting `revert`); chosen because gitlint (py's nearest Python-native alternative in the org's broader review) is dormant and Python-only, while commitlint is the org's proof-of-concept precedent and expresses the source's 50/72/type contract as three rule overrides on a current, actively maintained upstream config.

## Out of scope
- The git hook manager itself — its distribution/install mechanism, what triggers `lefthook install`, and the full-hook-suite CI re-run; R37 (`hook-manager-distribution`) owns F143/F144/F174 — this item picks the commit-msg linter *tool and its rule config*, not the manager that wires the `commit-msg` stage.
- How the `commit-message-convention` type-enum and length limits this item owns map to changelog sections, or how release-please's own config consumes them; that is R24 (`changelog-section-mapping`)'s decision and the release-please rows F063/F066/F073's concern — this item only defines the enum and limits, not their downstream consumption.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R38
- owns: commit-message-convention
- consumes:
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
