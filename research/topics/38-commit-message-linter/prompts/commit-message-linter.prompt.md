# Deep-research prompt — Commit-message linter (R38, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate (or tool) with a version range for: what enforces Conventional Commits at commit-msg hook time (and again in CI) — commitlint itself via a provisioned Node/Bun runtime, or a native-Rust equivalent — plus the Conventional-Commits type-enum and header/body/footer length limits it enforces. Item kind: `crate`. Value test: if this answer is wrong, the commit-msg hook's linter tool, its rule config, and the CI commit-lint re-run job all get rewritten, and the type-enum this item owns (consumed downstream by the changelog-section mapping and release-please config) changes shape.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos enforce Conventional Commits at commit-msg hook time with the same tool, commitlint, layered on `@commitlint/config-conventional` — a same-origin, `COMMON → SUBSTITUTE` case (the pattern is language-neutral; the tool is an npm package). The pattern row this substitutes for is `F148` (commit-message linting enforced at commit-msg hook time, `COMMON → REUSE`, out of scope here — the *fact* that linting happens at commit-msg time is not being reopened, only which tool does it). Evidence: py `lefthook.yml:65` — `commit-msg:` job runs `bun ./node_modules/@commitlint/cli/cli.js`; ts `lefthook.yml:68` — `commit-msg:` job runs `pnpm exec commitlint`. Ledger rows: F149 (parent: F148), F150, F151 (parent: F148), F152, F153, F154, F155, F156, F157 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE` (F149, F151) and `DIVERGENT` (F150, F152-F157).
- Per-row evidence for the rest of this bundle: F150 commit-msg hook invocation mechanism — py `lefthook.yml:65` (explicit path through Bun, `bun ./node_modules/@commitlint/cli/cli.js --edit {1}`, avoiding PATH/script fallback; py's own comments at `lefthook.yml:18-58` document three prior silent-pass failure modes that motivated this explicit-path form); ts `lefthook.yml:68` (`pnpm exec commitlint --edit {1}`, package-manager-resolved binary). F151 commitlint base config — py `commitlint.config.mjs:15` (`extends: ['@commitlint/config-conventional']`); ts `commitlint.config.mjs:26` (same extends) — both layer repo-specific overrides on the same upstream config. F152 header (subject) max-length override — py: none (inherits config-conventional's 100-char default); ts `commitlint.config.mjs:29` (`'header-max-length': [2, 'always', 50]`). F153 body max line-length override — py `commitlint.config.mjs:17` (`'body-max-line-length': [2, 'always', 200]`, raised to accommodate doc URLs/permalinks); ts `commitlint.config.mjs:30` (`'body-max-line-length': [2, 'always', 72]`, a stricter wrap). F154 footer max line-length override — py `commitlint.config.mjs:18` (`'footer-max-line-length': [2, 'always', 200]`); ts: none (stays at config-conventional's 100-char default). F155 type-enum restriction — py: none (leaves `type-enum` at config-conventional's default 11-member list); ts `commitlint.config.mjs:28` (`'type-enum': [2, 'always', types]` using an explicit 11-entry array, `commitlint.config.mjs:11`, kept in lockstep with `.gitmessage` by a dedicated test — py has no such file to reconcile against). F156 per-author relaxed ruleset for bot PRs — py `commitlint.dependabot.config.mjs:16` (a separate config disables `body-max-line-length`/`footer-max-line-length` for dependabot, selected in CI by PR-author login); ts: none (not applicable without ts's equivalent CI job). F157 commit-message linting re-run in CI — py `.github/workflows/commitlint.yml:45` (`wagoid/commitlint-github-action@v6.2.1` on every push/PR); ts: none (enforces Conventional Commits only via the local `commit-msg` hook; `--no-verify` bypasses it with nothing in CI to catch it).
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). That commit messages are linted at commit-msg hook time (F148, `COMMON → REUSE`) is settled; only which tool does it, and its rule config, are open.
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
- MEDIUM: What header/body/footer length limits and type-enum list should `rs-launch-blueprint` adopt, given the sources disagree (py: 100/200/200-char defaults-plus-two-overrides, no header override, default type list; ts: 50/72/100-char with an explicit 50-char header override and an explicit 11-member type-enum kept in lockstep with `.gitmessage` by a test)?
- MEDIUM: Should the chosen tool's config also run in CI beyond the local hook (py's `wagoid/commitlint-github-action`-equivalent, F157), given `--no-verify` bypasses any local-only enforcement — and does the chosen tool have an existing GitHub Action or does CI re-run need to shell out to the same binary the hook uses?
- LOW: Should a per-author relaxed ruleset for bot PRs (F156, py's dependabot-specific config) be carried over, and does the chosen tool support per-PR-author rule selection, or would that need to be implemented as a CI-side config swap?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.

## Required evidence
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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

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
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
