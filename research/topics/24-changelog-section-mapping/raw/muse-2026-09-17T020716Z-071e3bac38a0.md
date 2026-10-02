# R24 — changelog-section-mapping (pattern, Light) — raw report (muse)

Actor: `research-muse-2026-09-17T020716Z-071e3bac38a0`. Engine: muse. All web retrievals 2026-09-22 unless noted. All local file reads 2026-09-22. Executed environment: release-please 17.11.2, conventional-changelog-conventionalcommits 6.1.0, conventional-changelog-writer 6.0.1, node v26.5.0, macOS arm64.

### Landscape

Category decided: the Conventional-Commits type → `CHANGELOG.md` section mapping (visible vs hidden per type, section order, section titles) inside release-please's `changelog-sections`. The generator tool itself is inherited and out of scope (prompt `## Out of scope`; ts D-021(3)); the map below covers the mapping field, with generator context kept brief.

Three-bin map of the Rust changelog field:

- Built-in / first-party toolchain.
  - Hand-maintained `CHANGELOG.md`: cargo ships no changelog generator, so the Rust default is a curated file. Practice: `tokio-rs/tokio` (`tokio/CHANGELOG.md`, per-release Added/Changed/Fixed/Documented sections, user-facing only); `clap-rs/clap` (`CHANGELOG.md`, Keep-a-Changelog format with Breaking Changes/Features sections).
  - release-please preset default mapping (first-party default of the inherited tool): feat/feature/fix/perf/revert visible; docs/style/chore/refactor/test/build/ci hidden (`conventional-changelog-conventionalcommits@6.1.0`, `writer-opts.js` `defaultConfig`). release-please self-hosts this default: its own `release-please-config.json` carries no `changelog-sections` (fetched 2026-09-22, HTTP 200).
- Established industry standard.
  - release-please with custom `changelog-sections`: py-narrow mapping (py-launch-blueprint `release-please-config.json:22-39`: feat/fix/perf/refactor/revert/deps visible plus four deps-scope routes, six explicit hidden) and ts-broad mapping (ts-launch-blueprint `release-please-config.json:11-19`: feat/fix/perf/docs/test/refactor visible, chore hidden, five types unmapped). Both are shipped, rendered evidence (see `### Principles and implementation`).
  - git-cliff mapping dialect (Rust-native generator): evaluated for ts at v2.13.1 and rejected on redundancy, not maturity (ts-launch-blueprint `docs/port/TS_PORT_DECISIONS.md:255,262`, D-021(3)). Out of scope as a tool; noted only to show the mapping question was considered against the Rust-native alternative.
- Up-and-comer.
  - Total-explicit mapping: every type of the enforced enum listed explicitly (visible or `hidden: true`), relying nowhere on the unmapped-default. Emerging from this research's executed finding (unmapped breaking commits render under raw lowercase headings sorted above Features). No shipped adopter yet; proposed here.
  - release-plz (Rust-native release automation): seen only as migration chatter (one small repo moved release-plz → release-please and deleted custom sections as identical to defaults). Lead, not authority; unevaluated and out of scope.

Authoritative sources used, and why each counts:

- release-please 17.11.2 published code (npm tarball `https://registry.npmjs.org/release-please/-/release-please-17.11.2.tgz`, retrieved 2026-09-22): the maintainers' own implementation; `build/src/strategies/base.js` (`changelogEmpty`, skip when notes ≤ 1 line) and `build/src/changelog-notes/default.js` (sections passed through as preset `types`) were read and executed.
- `conventional-changelog-conventionalcommits@6.1.0` published code (npm tarball, retrieved 2026-09-22): implements the mapping semantics (`writer-opts.js`: `findTypeEntry` with `scope` matching, unmapped/hidden discard rule, array-order group sort); executed via release-please's own parser and notes builder.
- `conventional-changelog-conventionalcommits@10.4.0` published code (npm tarball, retrieved 2026-09-22): `src/utils.js:70` retains `entry.scope` matching, so scope routing survives the preset major upgrade; guards the durability claim.
- release-please config schema (`https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json`, retrieved 2026-09-22, HTTP 200): `changelog-sections` items require `type` + `section`, optional `hidden`; no `additionalProperties: false` on items, so scope-qualified entries are schema-valid.
- Keep a Changelog 1.1.0 (`https://keepachangelog.com/en/1.1.0/`, retrieved 2026-09-22): "a curated, chronologically ordered list of notable changes … easier for users and contributors to see precisely what notable changes have been made between each release". Community standard; cited by ts's own `CHANGELOG.md:5` preamble and clap's changelog. Grounds the user-facing-only principle.
- Conventional Commits 1.0.0 (`https://www.conventionalcommits.org/en/v1.0.0/`, retrieved 2026-09-22): fixes feat→MINOR, `!`/BREAKING-CHANGE→MAJOR semantics; leaves other types and revert handling to tooling/convention — which is why this mapping item exists.
- Flagship Rust practice: tokio (`https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/CHANGELOG.md`, HTTP 200) and clap (`https://raw.githubusercontent.com/clap-rs/clap/master/CHANGELOG.md`, HTTP 200): user-facing-only sections, no test/refactor/ci sections. Standing: the ecosystem's most depended-upon async runtime and CLI parser; cited for section shape, not generator choice (clap's generator config was not located — gap, not load-bearing).
- In-org evidence, read as files not verdicts: py `release-please-config.json`, `CHANGELOG.md`, `commitlint.config.mjs`, `commitlint.dependabot.config.mjs`, `.github/dependabot.yml`, installed `@commitlint/config-conventional@21.0.2` default enum; ts `release-please-config.json`, `CHANGELOG.md`, `commitlint.config.mjs`, `.github/dependabot.yml`, D-021(3) rationale; `docs/port/DIVERGENCE-ANALYSIS.md:108` (class A: "pick one list").

Practice-evidence gaps, recorded honestly: GitHub REST code search was unavailable (API rate limit, unauthenticated, observed 2026-09-22) and grep.app returned HTTP 429, so no broad survey of third-party `changelog-sections` adopters was possible; web search surfaced only small-repo leads (single blog/commit snippets — leads, not authority). The mapping decision therefore rests on executed preset semantics, the two shipped in-org mappings with their rendered output, the maintainers' self-hosted default, and flagship section-shape practice — sufficient for a 15-entry config array, and the re-verify trigger covers preset drift.

Required-figure applicability (spec §7.6 table): inapplicable as a class, with reason per row rather than silent omission. This item kind is `pattern`: no crate is shortlisted, so 90-day/all-time downloads, last release, stars/archived, open issues, responsiveness, advisories, and adopters-by-`Cargo.toml` have no candidate to attach to. release-please is inherited tooling whose selection is explicitly out of scope, so scoring it would be popularity-weighing a non-candidate. Versions cited (17.11.2 / 6.1.0 / 6.0.1) are executed-environment facts from `https://registry.npmjs.org/release-please/latest` and the installed tree, not candidate figures. Maintenance rubric: inapplicable (no maintained artifact selected; the deliverable is a JSON array). Performance: workload is one changelog render per release (milliseconds, process-bound); no throughput figure was measured or claimed; the mapping is not selected on speed.

### Principles and implementation

Shared requirement, source, agreement level. Every `CHANGELOG.md` release entry across py, ts, and rs surfaces exactly the user-facing change types and hides the rest, while a breaking change is never lost to a hidden mapping (it renders via `⚠ BREAKING CHANGES` plus its section title — executed below). Source: ledger row F067 (`docs/port/COMMONALITY.md:73`, `DIVERGENT`), area doc `docs/port/areas/release-versioning.md:12`, and `docs/port/DIVERGENCE-ANALYSIS.md:108` which classes this item class A (`harmonize: yes` — "pick one list"). Agreement level is **shared policy/standard**: the visible/hidden mapping itself is one list in all three repos; only the surrounding config file (already `release-please-config.json` in both sources) is mechanism. This parallels R38's contract-level agreement (its eleven-type enum is the consumed vocabulary). Changes to py and ts are a follow-on project; the rationale is supplied under `### Migration implications`. No `BASELINE-REVIEW:` finding: F063/F066/F073 (release tool, changelog generation, trigger) were re-verified intact and are not challenged; F067 is this item's own row. Owner ruling W2-REST does not apply (no HTTP surface). Accepted-but-unpublished R69 revision 10 is noted in prose only: web changes (`serve` binary, handlers, middleware) use the same eleven types, so no web-specific section is needed.

Essential behaviors: (1) each of R38's eleven types resolves to exactly one visible section or to hidden for non-breaking commits; (2) section order is deliberate (array order), not incidental; (3) breaking commits render regardless of hidden flags, under a proper title; (4) dependency-bump commits route to one Dependencies section under both plausible dependabot prefix shapes; (5) a release containing only hidden non-breaking commits opens no release PR (inherited base-strategy behavior, verified — constrains the visible set to stay non-vacuous).

Observable acceptance criteria (each tied to an executed case in `### Validation strategy`):

| Criterion | Case | Observed |
|---|---|---|
| All eleven types render exactly the five intended sections in array order | FINAL x eleven | Features, Bug Fixes, Performance Improvements, Code Refactoring, Reverts; 26 lines |
| `chore(deps)`, `chore(deps-dev)`, `build(deps)`, `build(deps-dev)` render under Dependencies | FINAL x scoped-deps | one Dependencies group, 4 entries, 9 lines |
| Breaking commits on hidden types render with proper titles in array order | FINAL x breaking | BREAKING CHANGES + 6 titled groups, 40 lines, no raw headings |
| Hidden-only sets render header-only (1 line) so base strategy skips the release PR | FINAL x hidden-only | 1 line |
| Config covers all eleven types with `type`+`section` and boolean `hidden` | schema-shape check | 15 entries, 11/11 types, pass |

What must agree vs may vary. Must agree across py/ts/rs: the visible set, the hidden set, and the rule that every enforced type is listed explicitly. May vary: nothing structural — all three repos already embed the mapping in `release-please-config.json`; section-title spellings should converge on the preset defaults (follow-on rationale below) but a title spelling is cosmetic, not a mapping change.

Architectural alternatives compared before the mapping options (tool choice itself is inherited, recorded for completeness): (A) release-please-owned mapping — selected context: single bump+changelog+release-PR authority per D-021(3); (B) hand-curated Keep-a-Changelog file (tokio practice) — highest signal per line, but manual curation contradicts the org's bot-owned release flow and reintroduces a second authority; (C) a second generator (git-cliff v2.13.1 / cocogitto v7.0.0) — already rejected on competing authority in D-021(3), not maturity. Within (A), two mapping architectures were executed: default-reliant (ts-style: list some types, let unmapped ones hide) vs total-explicit (every enum type listed). Default-reliant fails on two executed defects: unmapped breaking commits render under raw lowercase headings (`### ci`, `### style`) sorted above Features (preset `writer-opts.js`: `indexOf` miss → rank −1), and ts's unmapped `revert` silently drops revert-only releases to header-only notes, which `base.js` `changelogEmpty` (≤1 line) turns into no release PR at all — even though the default versioning strategy would bump patch for the same commits (`versioning-strategies/default.js`: any list falls through to `PatchVersionUpdate`). Total-explicit is therefore the required architecture; the remaining choice is only which types are visible.

Per-type calls for R38's enum (HIGH fresh-call question answered inline; `deps` is not in R38's enum):

| Type | Call | Precedent and evidence |
|---|---|---|
| feat, fix, perf | visible, in that order | Unanimous (py, ts, preset default); spec-correlated with MINOR/patch releases |
| refactor | visible ("Code Refactoring") | Dual-source agreement (py "Refactor", ts "Code Refactoring"); py's rendered Refactor sections carry upgrade-relevant entries ("remove legacy py-projects CLI", `CHANGELOG.md:243-247`). Preset default hides it — deliberate deviation, justified below. Cost accepted: occasional internal-rename noise |
| revert | visible ("Reverts") | py visible + preset default visible. ts's omission is accidental drift (its `cog.toml` ancestor had no revert entry; ts never rendered a Reverts section), with the severe executed consequence above. A revert undoes shipped behavior — upgrade-critical |
| docs | hidden, explicit | py hidden + preset default hidden. ts-visible was inherited from `cog.toml` without audience rationale (`DIVERGENCE-ANALYSIS.md:108`); ts's rendered Documentation section is port-process chatter ("log D-034 model-tier routing", 18+ entries in 0.1.2). Rust docs ship via docs.rs on publish; doc-only commits carry no upgrade signal; breaking docs changes still surface via the breaking path |
| test | hidden, explicit | Same structure as docs, stronger: tests never ship. ts's rendered Tests sections ("port config tests", "pnpm 10 hygiene") are pure upgrader noise |
| build, ci | hidden, explicit | py-hidden-only precedent; ts silent (unmapped). Fresh call forced by the raw-heading execution: `ci!` under ts renders `### ci` above Features; explicit entries fix title and order |
| style | hidden, explicit | Same as build/ci (`style!` renders raw `### style` when unmapped) |
| chore | hidden, explicit | Unanimous hidden; explicit entry must come after the scope routes (first-match wins) |
| `deps` scope on chore/build | visible ("Dependencies") via four scope routes | py's mechanism, executed: bare `deps`-type entry omitted as dead (py's own commitlint enum, `@commitlint/config-conventional@21.0.2` default, has no `deps` type, so nothing can carry it; py's Dependencies sections show `**deps:**`/`**deps-dev:**` scopes on chore-typed commits). Four routes cover both `chore(deps)` (py's dependabot shape) and `build(deps)` (R38's anticipated R19 shape); inert entries are harmless. R19 coupling noted in prose, not a conflict |

Rust-audience reasoning (HIGH question): a Rust template's readers decide upgrades from behavior deltas (features, fixes, performance, removals/reverts, dependency moves with MSRV/transitive effects). `refactor` stays visible because Rust restructures routinely touch the public module surface and py's rendered history shows the section carrying removal notices; `test` is noise because the test target never reaches consumers. This differs from py/ts's own reasoning only in that neither source recorded audience reasoning for these rows — py's set is unexplained practice, ts's is `cog.toml` inheritance — so the audience argument here is fresh rather than transferred.

Schema surface beyond flat visible/hidden (MEDIUM question), all verified in preset 6.1.0 source and executed: (1) array order is section order (`commitGroupsSort` over `commitGroupOrder`) — adopted: impact order feat, fix, perf, refactor, revert, Dependencies, then hidden docs, test, build, ci, style, chore; (2) `section` is free text (custom headings/emoji supported) — not adopted: preset `DEFAULT_HEADINGS` titles are the standard (`Code Refactoring`, `Continuous Integration`, `Miscellaneous Chores`) and match ts where ts uses them; py's custom spellings ("Refactor", "CI", "Miscellaneous") are cosmetic drift for the follow-on; (3) per-entry `scope` routing — adopted (py's four entries): implemented by `findTypeEntry`, schema-valid (no `additionalProperties: false`), and durable (retained in preset 10.4.0 `src/utils.js:70`), though undocumented in release-please's schema description and `ChangelogSection` interface — the re-verify trigger watches preset upgrades.

Fitness gates (all six, each inapplicable with reason — the deliverable is a 15-entry JSON array, no code, no dependency, no build):

| Gate | Result | Reason |
|---|---|---|
| 1 license | inapplicable | No dependency or tool added; release-please already inherited. Owner ruling 2026-09-12 independently strikes licence evaluation |
| 2 MSRV | inapplicable | Data file; no Rust code, no toolchain floor |
| 3 advisories / unsafe | inapplicable | No crate, no `unsafe`, no dependency tree |
| 4 OS matrix | inapplicable | JSON consumed by the release-please action in CI; no OS-dependent behavior |
| 5 features / async | inapplicable | No features, no runtime |
| 6 size / compile cost | inapplicable | ~800 bytes of config; zero compile cost |

Minimal realistic example: the `changelog-sections` array in `### Recommendation`, validated by the schema-shape check and rendered by the four FINAL cases. Proposed-vs-run distinction: everything in `### Validation strategy` under "Executed" ran on 2026-09-22 in `/tmp/rpwork` (scratch, retained for re-run); the repo acceptance recipe under "Planned" is proposed for the synthesizer.

### Dominant choice

Total-explicit mapping over R38's eleven types with preset-default titles: feat, fix, perf, refactor, revert visible in that order, dependency bumps routed to a visible Dependencies section via four scope entries, and docs, test, build, ci, style, chore explicitly hidden in that order. No bare `deps` type entry. Rationale in one line: it keeps every upgrade-relevant type visible, hides every never-ships type explicitly (so breaking commits keep proper titles and order), and is the only architecture that survives the executed unmapped-breaking hazard.

### Options

Name · where documented · adopters that practice it · date of the most recent authoritative write-up. No download columns (pattern).

| Option | Documented | Adopters | Latest write-up |
|---|---|---|---|
| Total-explicit mapping (recommended): 15 entries, 5 visible + Dependencies routing + 6 hidden | this report; preset semantics in `conventional-changelog-conventionalcommits@6.1.0 writer-opts.js` | none shipped yet (proposed for rs) | 2026-09-22 (this report + executed preset source) |
| py-narrow: feat/fix/perf/refactor/revert/deps visible, 4 scope routes, 6 hidden | py-launch-blueprint `release-please-config.json:22-39` | py-launch-blueprint (rendered Refactor/Reverts/Dependencies sections in its `CHANGELOG.md`) | file read 2026-09-22 (no separate write-up; practice evidence) |
| ts-broad: feat/fix/perf/docs/test/refactor visible, chore hidden, 5 types unmapped | ts-launch-blueprint `release-please-config.json:11-19`, D-021(3) | ts-launch-blueprint (rendered Documentation/Tests sections; never rendered Code Refactoring — 0 occurrences) | D-021(3) rationale 2026-07 (file read 2026-09-22) |
| Preset default (no `changelog-sections`): feat/feature/fix/perf/revert visible, rest hidden | preset `defaultConfig`, release-please schema description | release-please itself (self-hosted, no override — config fetched 2026-09-22); small-repo removals of custom sections as identical to defaults (lead only) | preset 6.1.0 source 2023-06-17; self-config retrieved 2026-09-22 |

### Excluded by gate

None. The fitness gates are inapplicable to a JSON-config pattern (table in `### Principles and implementation`), so no option is excluded by gate. Mapping defects (ts-broad's unmapped revert and raw-heading hazard) are evidence findings decided under `### Recommendation` and `### Tradeoffs`, not gate exclusions.

### Up-and-comers

Total-explicit mapping (this report's pattern): the emerging practice of listing every enforced type explicitly instead of relying on the unmapped-default, motivated by the executed raw-heading finding. No shipped adopter yet; fits any release-please repo whose linter enforces a closed type enum (as R38's does). Watch item: if release-please documents `scope` in the schema or a future preset changes unmapped-type handling, this pattern's margin over default-reliant configs should be re-measured (see re-verify trigger). release-plz's mapping dialect is a second up-and-comer lead, unevaluated: out of scope (tool inherited), weak evidence (single migration snippet).

### Fit for this template

CLI: strongest fit. CLI consumers read the changelog to decide upgrades; Features/Bug Fixes/Performance Improvements/Reverts plus removal-type refactors ("remove legacy adapter") are exactly the upgrade signal, and Dependencies entries (`**deps:** bump tokio`) flag transitive/MSRV-relevant moves. Hidden docs/test/ci/style/chore remove the process chatter that dominates ts's rendered 0.1.2 notes.

Library: same mapping, no change. Library upgrades hinge on API deltas and fixes; internal refactors render as a safety net for restructures typed `refactor` rather than breaking; test/style/ci/build entries would be pure noise against a semver decision. Nothing enters the crate's dependency tree, docs.rs build, or MSRV.

Web service: orthogonal. The optional `web` feature (R69, prose-only here) adds no commit type — service work ships as feat/fix/perf/refactor like the rest — so no web-specific section is needed. Deployment-only changes (`ci`/`build`, non-deps scopes) stay hidden, matching py; if a deployment change is breaking it surfaces via the breaking path regardless.

### Recommendation

Adopt this `changelog-sections` array in `release-please-config.json` (15 entries; titles are preset `DEFAULT_HEADINGS`; order is deliberate — visible in impact order, then hidden):

```json
"changelog-sections": [
  {"type": "feat", "section": "Features"},
  {"type": "fix", "section": "Bug Fixes"},
  {"type": "perf", "section": "Performance Improvements"},
  {"type": "refactor", "section": "Code Refactoring"},
  {"type": "revert", "section": "Reverts"},
  {"type": "chore", "scope": "deps", "section": "Dependencies"},
  {"type": "chore", "scope": "deps-dev", "section": "Dependencies"},
  {"type": "build", "scope": "deps", "section": "Dependencies"},
  {"type": "build", "scope": "deps-dev", "section": "Dependencies"},
  {"type": "docs", "section": "Documentation", "hidden": true},
  {"type": "test", "section": "Tests", "hidden": true},
  {"type": "build", "section": "Build System", "hidden": true},
  {"type": "ci", "section": "Continuous Integration", "hidden": true},
  {"type": "style", "section": "Styles", "hidden": true},
  {"type": "chore", "section": "Miscellaneous Chores", "hidden": true}
]
```

Per-decision recap: feat/fix/perf visible (unanimous, spec-correlated); refactor visible (dual-source agreement + rendered removal-signal); revert visible (upgrade-critical; ts omission is accidental drift with release-suppressing consequences); docs/test hidden (ts-visible inherited without rationale; rendered as process noise; breaking cases still surface); build/ci/style/chore explicitly hidden (unanimous hidden; explicit because unmapped breaking commits render raw and mis-sorted); Dependencies via four scope routes covering both `chore(deps)` and `build(deps)` shapes; bare `deps` type entry omitted as dead under R38's enum. Relative order of the shared visible entries follows py (feat, fix, perf, refactor, revert). Net effect vs the sources: identical visibility to py minus its dead entry, with preset-default titles; vs ts, docs/test hidden, revert added, scope routing added, all hidden made explicit.

### Ranked runner-up

Docs-visible variant: the recommended array with `{"type": "docs", "section": "Documentation"}` (no `hidden` flag), placed after Reverts and before the scope routes. It wins if and only if the owner judges template documentation changes upgrade-relevant for downstream scaffolders — i.e., that a template's docs are product surface whose per-release delta belongs in release notes — accepting the executed cost that routine doc commits ("fix typo", "log D-034") will dominate the notes. Everything else (explicit hidden entries, scope routing, revert visibility, preset titles) carries over unchanged.

### Tradeoffs

What the pick gives up vs ts-broad (docs/test visible): per-type recall for documentation and test work; a reader diffing template versions cannot see doc/test deltas in the changelog. Accepted because ts's own rendered Documentation/Tests sections demonstrate the cost side (process chatter drowning signal), breaking docs/test changes still surface via the breaking path, and neither section informs an upgrade decision.

What the pick gives up vs the preset default (refactor hidden, no scope routing): zero-config simplicity and automatic tracking of future preset title changes. Accepted because refactor visibility preserves removal/restructure notices both sources chose to keep, and without scope routing every dependency bump is hidden — losing the transitive/MSRV signal — while the four inert-if-unused scope entries cost nothing.

What the pick gives up vs py-narrow as-shipped: py's custom titles ("Refactor", "CI", "Miscellaneous") and its bare `deps` entry. Accepted because preset-default titles are the three-repo convergence point (ts already uses "Code Refactoring"), and the bare entry is provably dead under a closed eleven-type enum.

What the pick gives up vs the docs-visible runner-up: nothing except the docs-recall question above; the runner-up is a one-flag delta, so the cost of being wrong on docs is a one-line change.

### Parameters

- owns: (none — R24 owns no registered parameter)
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes commit-message-convention = type-enum: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test; header-max-length: 50 (the whole `type(scope): description` line); body-max-line-length: 72; footer-max-line-length: 72; length-semantics: soft-line (the header and every body/footer line are measured up to their last space, so a bare URL or any other un-wrappable final token never violates a cap); bot-exemption: for pull requests opened by dependabot, CI relaxes only the width rules (grammar and type enum stay enforced)

CONFLICT lines: none. The recommendation consumes R38's enum as-is; no consumed value needs to change. Couplings noted in prose (not conflicts): R19 (`dependabot-config-shape`, undecided) — both plausible prefix shapes are pre-covered by the four scope routes; R25 (`semver-bump-strategy`) — the visible set gates release-PR existence via `changelogEmpty`, and revert visibility restores revert-only releases to releasable.

### Migration implications

Template file-level changes (rs only; no py/ts file is touched here):

- `release-please-config.json`: set `packages["."].changelog-sections` to the 15-entry array in `### Recommendation`. No other key changes; `release-type`/`bump-*`/title pattern belong to other items.
- No new files, no dependency, no workflow change: the mapping is data consumed by the existing release-please flow.

Follow-on rationale for py/ts (supplied, not applied): py — drop the dead bare `{"type": "deps"}` entry (unreachable under its commitlint enum) and converge titles on preset defaults ("Code Refactoring", "Continuous Integration", "Miscellaneous Chores"); visibility already matches. ts — hide docs and test, add visible `revert`, add the four deps-scope routes, and add explicit hidden entries for build/ci/style (plus keep chore explicit) to close the raw-heading hazard and the revert-release suppression; adopt preset-default titles (already used for refactor).

### Validation strategy

Executed 2026-09-22 in `/tmp/rpwork` (scratch; harness `/tmp/rpwork/check.js` plus inline probes; outputs below recorded from the runs; commit-link URLs elided to `(<link>)` by notation, headings/order/line counts exact).

Setup (executed):

- `npm init -y && npm_config_cache=/tmp/npm-cache npm install --no-audit --no-fund release-please@17.11.2` → installed release-please 17.11.2, conventional-changelog-conventionalcommits 6.1.0, conventional-changelog-writer 6.0.1 (verified via `node -e` requires).
- `curl -sL https://registry.npmjs.org/release-please/-/release-please-17.11.2.tgz`, `…/conventional-changelog-conventionalcommits-…-6.1.0.tgz`, `…-10.4.0.tgz` → sources read: `build/src/strategies/base.js` (`changelogEmpty`, skip), `build/src/changelog-notes/default.js` (sections → preset `types`), preset `writer-opts.js` (`findTypeEntry`, discard rule, group sort, `defaultConfig`), preset-10 `src/utils.js:70` (scope retained), `versioning-strategies/default.js` (any list → at least patch).

Harness shape (executed; `/tmp/rpwork/check.js`): release-please's own `parseConventionalCommits` on raw fixture messages, then `DefaultChangelogNotes.buildNotes` with `{owner, repository, version 0.2.0, previousTag v0.1.0, currentTag v0.2.0, targetBranch main}` under the py array (copied from py lines 22-39), the ts array (lines 11-19), and the FINAL array (byte content of `/tmp/rpwork/final.json`, validated: `schema-shape OK; entries: 15; types covered: 11`).

Decisive outputs (executed):

- `FINAL x eleven` → 26 lines, sections in array order: Features (`cli: add json output flag`), Bug Fixes, Performance Improvements, Code Refactoring (`core: rename tracing helper`), Reverts (`feat(cli): add json output flag`); docs/test/build/ci/style/chore absent. Expected: exactly this; passed.
- `FINAL x scoped-deps` → 9 lines: single Dependencies group with all four bumps (`deps-dev` × 2, `deps` × 2, sorted by scope then subject). Expected: one group; passed. Counter-case `TS x scoped-deps` → header-only, 1 line (all hidden): demonstrates ts hides every dependency bump.
- `FINAL x breaking` (feat!/fix!/refactor!/chore!/ci!/style!) → 40 lines: `⚠ BREAKING CHANGES` with 6 notes, then Features, Bug Fixes, Code Refactoring, Continuous Integration, Styles, Miscellaneous Chores — proper titles in array order. Expected: no raw headings; passed. Counter-case `TS x breaking` → 40 lines with `### ci` and `### style` raw lowercase groups sorted above Features: the unmapped-breaking hazard, reproduced.
- `FINAL x hidden-only` (test/style/chore) and `TS x hidden-only` (chore) → header-only, 1 line each: `changelogEmpty` true → base strategy opens no release PR. Expected: 1 line; passed.
- `PY x eleven` (skeleton) → Features, Bug Fixes, Performance Improvements, Refactor, Reverts; 26 lines; docs/test/ci/build/chore hidden. `TS x eleven` (skeleton) → Features, Bug Fixes, Performance Improvements, Documentation, Tests, Code Refactoring; 31 lines; revert/build/ci/style/chore dropped. `PY x deps-type` (`deps: …`) → Dependencies, 6 lines: the bare entry functions, but is unreachable under a closed enum (see below).
- Git-revert probe (executed): `Revert "feat(cli): …"` → `commit could not be parsed … unexpected token ' ' at 1:7` (skipped by the parser); `revert('feat'): drop flag` parses as type `revert` → under ts renders header-only (1 line): ts suppresses a revert-only release. Expected per code reading; passed.
- Dead-entry proof (executed reads, no install): py `commitlint.config.mjs` extends `@commitlint/config-conventional` with no `type-enum` override; installed `config-conventional@21.0.2 lib/index.js:20-35` enum is exactly the eleven (no `deps`); py `CHANGELOG.md:37,81-82` Dependencies entries show `**deps:**`/`**deps-dev:**` scopes. Conclusion: py's bare `deps` entry is unreachable; its Dependencies section is scope-routed only.

Planned (not executed — proposed repo acceptance for the synthesizer): commit the array in `release-please-config.json` and run a fixture render in CI using a pinned release-please (`npx -y release-please@17.11.2` is network-dependent; preferred: a lockfile-pinned dev install driving `buildNotes` over one fixture commit per R38 type plus one breaking commit per hidden type, asserting the five visible headings, Dependencies routing, no raw lowercase `###` headings, and header-only output for a hidden-only set). Also assert 11/11 enum coverage by parsing `committed.toml`'s `allowed_types` against the array — the R38/R24 consistency check. These planned checks are distinguished from the executed `/tmp` runs above.

### Confidence & re-verify trigger

Confidence: high on mechanics (preset semantics read in published source and executed end-to-end through release-please's own parser and notes builder, four FINAL cases plus counter-cases); medium-high on the docs-hidden call (rests on rendered-noise evidence and the Keep-a-Changelog principle against one shipped ts precedent — a judgment call, with the one-flag runner-up if the owner disagrees); high on revert-visible and explicit-hidden (executed consequences, not taste).

Re-verify on: any release-please upgrade that changes the `conventional-changelog-conventionalcommits` major (re-run the FINAL four cases; watch unmapped-type handling and `scope` support), any R38 enum change (coverage must return to 11/11 — add/remove entries to match), an R19 dependabot shape outside `deps`/`deps-dev` scopes (extend scope routes), or release-please documenting `scope` in the schema (no action expected; confirms the routing).

### Sources

- `https://registry.npmjs.org/release-please/latest` — 17.11.2 tarball URL; retrieved 2026-09-22.
- `https://registry.npmjs.org/release-please/-/release-please-17.11.2.tgz` — executed source (`strategies/base.js`, `changelog-notes/default.js`, `versioning-strategies/default.js`); retrieved 2026-09-22.
- `https://registry.npmjs.org/conventional-changelog-conventionalcommits` — 6.x versions (6.1.0, 2023-06-17) and latest (10.4.0); retrieved 2026-09-22.
- `https://registry.npmjs.org/conventional-changelog-conventionalcommits/-/conventional-changelog-conventionalcommits-6.1.0.tgz` — `writer-opts.js` mapping semantics; retrieved 2026-09-22.
- `https://registry.npmjs.org/conventional-changelog-conventionalcommits/-/conventional-changelog-conventionalcommits-10.4.0.tgz` — `src/utils.js:70` scope retention; retrieved 2026-09-22.
- `https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json` — `changelog-sections` schema (HTTP 200); retrieved 2026-09-22.
- `https://raw.githubusercontent.com/googleapis/release-please/main/docs/customizing.md` — no `changelog-sections` section (HTTP 200); retrieved 2026-09-22.
- `https://raw.githubusercontent.com/googleapis/release-please/main/release-please-config.json` — self-hosted, no override (HTTP 200); retrieved 2026-09-22.
- `https://keepachangelog.com/en/1.1.0/` — notable-changes principle; retrieved 2026-09-22.
- `https://www.conventionalcommits.org/en/v1.0.0/` — feat/fix/breaking semantics, revert non-prescriptive; retrieved 2026-09-22.
- `https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/CHANGELOG.md` — Added/Changed/Fixed/Documented practice (HTTP 200); retrieved 2026-09-22.
- `https://raw.githubusercontent.com/clap-rs/clap/master/CHANGELOG.md` — Keep-a-Changelog section shape (HTTP 200); retrieved 2026-09-22.
- `/Users/stevemorin/c/py-launch-blueprint/release-please-config.json:22-39`, `CHANGELOG.md` (Refactor/Reverts/Dependencies sections, e.g. lines 37, 81-82, 243-251), `commitlint.config.mjs`, `commitlint.dependabot.config.mjs`, `.github/dependabot.yml`, `node_modules/@commitlint/config-conventional@21.0.2 lib/index.js:20-35` — read 2026-09-22.
- `/Users/stevemorin/c/ts-launch-blueprint/release-please-config.json:11-19`, `CHANGELOG.md` (Documentation/Tests sections; 0 `### Code Refactoring` occurrences), `commitlint.config.mjs`, `.github/dependabot.yml`, `docs/port/TS_PORT_DECISIONS.md:249-265` (D-021) — read 2026-09-22.
- `research/topics/38-commit-message-linter/DECISION.md` (revision 9) — consumed eleven-type enum and bot-exemption shape; read 2026-09-22.
- `docs/port/COMMONALITY.md:73`, `docs/port/areas/release-versioning.md:12`, `docs/port/DIVERGENCE-ANALYSIS.md:108`, `docs/port/PARAMETERS.md` — ledger and registry context; read 2026-09-22.
- Gaps: `https://api.github.com/repos/googleapis/release-please/contents/src` (rate-limited, unauthenticated); `https://grep.app/api/search?q=changelog-sections` (HTTP 429); clap's generator config (not located at `cliff.toml`, `.cliff.toml`, `.config/cliff.toml` — all HTTP 404). Observed 2026-09-22.
