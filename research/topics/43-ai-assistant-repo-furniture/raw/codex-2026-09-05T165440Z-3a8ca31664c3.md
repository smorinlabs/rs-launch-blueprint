### Landscape

This bundle decides repository-scoped AI-agent guidance and startup orientation, not a Rust runtime dependency. The field map is: **built-in or first-party toolchain** — Cursor Project Rules (`.cursor/rules/*.mdc`), Cursor `AGENTS.md`, Devin/Windsurf Rules (`.devin/rules/*.md`, with `.windsurf/rules/*.md` as a fallback), and Claude Code `.claude/settings.json` `companyAnnouncements`; **established industry standard** — a root `AGENTS.md` in plain Markdown as the version-controlled, tool-neutral instruction hub; **up-and-comer** — vendor-specific, glob-activated files used only for genuinely editor-specific policy. The map deliberately separates a portable instruction contract from proprietary delivery files. Cursor itself calls `AGENTS.md` the simple alternative to `.cursor/rules`, and Devin processes root `AGENTS.md` as an always-on rule. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

The authorities are the vendors' current documentation, because it defines the parsers and precedence rules; the AGENTS.md project, because it is stewarded by the Agentic AI Foundation under the Linux Foundation and reports use by more than 60,000 open-source projects; and the checked pinned source trees, because they establish the py/ts precedent rather than selecting the Rust result. ([AGENTS.md](https://agents.md/); retrieved 2026-09-05) ([ts decision D-024](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/docs/port/TS_PORT_DECISIONS.md#L317-L345); retrieved 2026-09-05) ([port ledger F197-F199](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L201-L203); retrieved 2026-09-05)

Practice evidence supports the standard rather than a duplicated vendor mesh. OpenAI's production, Rust-rich Codex repository has a root `AGENTS.md` with Rust-specific build, test, lint, workspace, and context rules; its public GitHub page reports 18,700 forks, and the file is 322 lines, making it a maintained, non-toy reference for a Rust repository with a task runner. The AGENTS.md registry also lists that repository as an example and describes the format as cross-agent. ([openai/codex AGENTS.md](https://github.com/openai/codex/blob/main/AGENTS.md); retrieved 2026-09-05) ([AGENTS.md examples](https://agents.md/); retrieved 2026-09-05)

The surveyed alternatives are: (1) hub only; (2) hub plus thin vendor pointers; and (3) copied, vendor-specific policy. Option 1 has one source of truth and now reaches both requested editors natively. Option 2 has a small file-count cost but does not add capability for a generic pointer. Option 3 can express proprietary activation semantics, but duplicates policy and creates drift. A file-glob is still idiomatic when its content is genuinely file-specific: Cursor supports `globs` in `.mdc` frontmatter and Devin supports `trigger: glob`; it is not an idiomatic reason to add a generic hub pointer. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

### Principles and implementation

The shared requirement is **portable, reviewable agent guidance with a discoverable first command**. Its agreement level is an architectural pattern: one canonical, version-controlled instruction source, not identical vendor files. F197 already fixes the hub as a single canonical `AGENTS.md` plus a thin per-tool import; F198/F199 decide only furniture around that hub. The essential behaviors are: Cursor and Devin/Windsurf receive the root instructions without a second copy; a maintainer changes instruction policy in one file; and a Claude Code user sees a compact project orientation that directs them to the canonical command index and hub. ([F197-F199 source evidence](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/dev-experience-repo-hygiene.md#L28-L30); retrieved 2026-09-05) ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

Observable acceptance criteria are: (a) exactly one root `AGENTS.md` holds project policy; (b) no `.cursor/rules` pointer and no `.windsurf/rules` pointer restates it; (c) Cursor recognizes the root hub; (d) Devin/Windsurf recognizes the root hub; (e) `.claude/settings.json` contains one valid `companyAnnouncements` entry naming the project, `AGENTS.md`, and `just --list`; and (f) the announcement mentions `cargo build` and `cargo test` only as direct Rust alternatives, not as a second task-runner vocabulary. The owner-fixed command-surface pattern is `just`, so the welcome should lead with `just --list`, while direct Cargo commands remain useful to Rust users and do not claim a particular Justfile recipe exists before the implementation plan defines it. ([F176 and F197-F199](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/dev-experience-repo-hygiene.md#L7-L7); retrieved 2026-09-05) ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

The recommended minimal example is a root `AGENTS.md` containing the charter and command contract, with no Cursor/Windsurf pointer file, plus this single static Claude announcement: `rs-launch-blueprint: Rust CLI + library + web-service template. Start with just --list; see AGENTS.md for the charter. Direct Rust commands include cargo build and cargo test.` This composes native discovery with an explicit human-facing start point. The proposed executable check is JSON parsing plus path-negative assertions, followed by a manual launch in installed Cursor, Devin/Windsurf, and Claude Code; none of those editor launches was run in this research environment. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05) ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

BASELINE-REVIEW: F198 — one canonical, portable instruction source — omit Cursor and legacy Windsurf hub-pointer files — Cursor documents root `AGENTS.md` as the simple alternative to `.cursor/rules`; Devin documents root `AGENTS.md` as always-on and `.devin/rules` as preferred while `.windsurf/rules` is fallback. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

BASELINE-REVIEW: F199 — a discoverable project start point — retain one short `companyAnnouncements` string but replace the stale detailed recipe inventory with `just --list` and direct Cargo examples — Claude Code documents `companyAnnouncements` as a startup announcement and cycles a list when multiple entries exist. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

### Recommendation

Ship the existing root `AGENTS.md` hub; ship neither `.cursor/rules/` nor `.windsurf/rules/` merely to point at it; and commit one short `.claude/settings.json` `companyAnnouncements` string. Add a Cursor or `.devin/rules` glob file later only when a rule contains editor-specific, file-scoped behavior that cannot live naturally in the hub. This preserves the shared capability while removing the duplicated, now-legacy mechanism. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

### Members

#### Cursor project-rule spoke

##### Landscape

Cursor supports version-controlled project rules in `.cursor/rules` as `.mdc` files and supports root and nested plain-Markdown `AGENTS.md` as a simpler alternative. This member is a pattern candidate, not a crate; crates.io downloads, release, GitHub issue responsiveness, RustSec advisories, and reverse dependencies are therefore inapplicable. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

Maintenance state: **active** — Cursor's first-party Rules documentation currently specifies both mechanisms; a release-age rubric is inapplicable because this is an editor feature rather than an independently released Rust package. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Principles and implementation

The required behavior is that Cursor receives the canonical hub without another policy source. Cursor explicitly supports root `AGENTS.md`; an always-applied `.mdc` pointer adds no instruction content and makes a second maintained route. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Dominant choice

Use the root `AGENTS.md` alone. Cursor calls it an alternative to project rules for straightforward use cases. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Qualified shortlist

The qualified alternatives are a hub-only design and a `.cursor/rules/*.mdc` file with `alwaysApply: true` that points to the hub. Both are license-neutral configuration patterns; MSRV, `unsafe`, async runtime, binary-size, compile-time, crates.io figures, and RustSec are inapplicable. The repository's MIT OR Apache-2.0 license applies to any committed text. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

##### Excluded by gate

No candidate is excluded by a crate fitness gate because there is no crate. The pointer is excluded on the architectural fitness gate: it cannot demonstrate an additional Cursor capability beyond the native hub and adds a stale duplicate route. CI compatibility on `ubuntu-latest` and `macos-latest` is inapplicable to an editor config's runtime behavior; syntax and absence checks can run on both, while actual Cursor loading needs manual re-verification on an installed client. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Up-and-comers

Use a scoped `.mdc` only for new Cursor-only behavior, such as a real `Justfile` policy. Cursor documents `globs` and the apply-to-specific-files mode; this is not a substitute for the hub. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Fit for this template

This template is one CLI, library, and web-service repository, not a monorepo needing Cursor-specific subtrees. A hub-only design keeps the command and policy source aligned across the three surfaces. The maintained Rust reference `openai/codex` likewise uses `AGENTS.md` for Rust workspace instructions and `just` commands. ([openai/codex AGENTS.md](https://github.com/openai/codex/blob/main/AGENTS.md); retrieved 2026-09-05)

##### Recommendation

Do not create `.cursor/rules/projectenv.mdc` or another generic pointer. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Ranked runner-up

One minimal `.mdc` pointer is the runner-up only if a tested Cursor version fails to load the root hub; its frontmatter must be valid and its body must contain only the hub reference. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Tradeoffs

Omission removes a discoverability artifact from Cursor's Rules panel, but avoids duplicated instructions. A pointer is cheap to write but becomes a maintenance obligation whenever filenames, paths, or tooling change. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest. These constraints do not select a configuration-only pattern. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

##### Migration implications

Do not add `.cursor/rules/projectenv.mdc`; place all general agent instructions in root `AGENTS.md`. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Validation strategy

Planned: assert root `AGENTS.md` exists and `find .cursor/rules -type f` is empty or absent; open the repository in Cursor and confirm the hub appears in agent context. The path check is executable in CI; the client-context observation is manual and was not run. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Confidence & re-verify trigger

High confidence as of 2026-09-05. Re-verify if Cursor removes root `AGENTS.md` discovery, changes `.mdc` semantics, or the template adds real Cursor-only policy. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05)

##### Sources

Pattern evidence: [Cursor Rules](https://cursor.com/docs/rules) and [openai/codex AGENTS.md](https://github.com/openai/codex/blob/main/AGENTS.md), retrieved 2026-09-05.

#### Devin/Windsurf rule spoke

##### Landscape

Devin's current documentation names `.devin/rules/*.md` as preferred and `.windsurf/rules/*.md` as fallback; it also processes root `AGENTS.md` through the same Rules engine. This is a pattern candidate, so all crate figures, RustSec, dependency-tree MSRV, `unsafe`, async-runtime coupling, binary-size, and compile-time metrics are inapplicable. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05) ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

Maintenance state: **active** — current first-party documentation marks `.devin/rules` preferred and retains the Windsurf path only for compatibility; release-age and package issue metrics are inapplicable to this configuration pattern. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Principles and implementation

The required behavior is native receipt of the root hub, not preservation of the TypeScript port's legacy directory. Root `AGENTS.md` is always-on; a subdirectory hub is automatically glob-scoped. This is the exact behavior the prior `.windsurf/rules/justfile-rules.md` tried to approximate for one file, but the old generic spoke is not needed. ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05) ([ts Justfile rule](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.windsurf/rules/justfile-rules.md); retrieved 2026-09-05)

##### Dominant choice

Use root `AGENTS.md` without a `.windsurf/rules` file. ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

##### Qualified shortlist

The shortlist is hub-only, a legacy `.windsurf/rules/*.md` pointer, or a current `.devin/rules/*.md` file for distinct editor-specific behavior. License, MSRV, advisories, unsafe posture, OS build matrix, default features, runtime coupling, and build cost are inapplicable to all three because none is a Rust dependency; tests can validate paths on the fixed Linux/macOS CI matrix, but editor parsing remains client behavior. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05) ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

##### Excluded by gate

The legacy `.windsurf/rules` generic pointer is excluded by current-format fitness: the vendor now calls `.devin/rules` preferred and `.windsurf/rules` fallback, while the hub already has native automatic discovery. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Up-and-comers

If a future rule must be editor-specific, use `.devin/rules/<name>.md` with `trigger: glob` for a genuine file class. The documented activation modes are `always_on`, `model_decision`, `glob`, and `manual`. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Fit for this template

No current Rust-specific concern needs proprietary editor activation. The template's portability goal is better served by standard Markdown in the root hub; Devin recommends `AGENTS.md` for simple location-based instructions and Rules only for more control. ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

##### Recommendation

Do not create `.windsurf/rules/justfile-rules.md` or another hub pointer. Do not create `.devin/rules` until a distinct rule is evidenced. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Ranked runner-up

The runner-up is a current `.devin/rules/justfile.md` with `trigger: glob` only if the template later needs a rule that is both Justfile-specific and not appropriate for `AGENTS.md`. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Tradeoffs

Hub-only loses a visible vendor-rule file but avoids a deprecated-path dependency and duplicate maintenance. A future `.devin` rule gains targeted activation at the cost of proprietary configuration and another policy surface. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest. No parameter change is required. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

##### Migration implications

Do not add `.windsurf/rules/`; retain root `AGENTS.md` as the only general instruction source. ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

##### Validation strategy

Planned: assert the root hub exists and legacy `.windsurf/rules` is absent; open the repository in Devin/Windsurf and verify the hub is loaded as an always-on root rule. The structural assertions are executable; no installed-client test was executed. ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05)

##### Confidence & re-verify trigger

High confidence as of 2026-09-05. Re-verify on any Devin/Windsurf rename, a change to native AGENTS discovery, or a real requirement for file-scoped editor-specific guidance. ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05)

##### Sources

Pattern evidence: [Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories), [Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md), and the [pinned TypeScript Justfile rule](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.windsurf/rules/justfile-rules.md), retrieved 2026-09-05.

#### Claude Code welcome announcement

##### Landscape

Claude Code provides project-shared `.claude/settings.json`; `companyAnnouncements` is the first-party static-startup-announcement field and accepts a list that is cycled at random. This is a configuration pattern, not a crate, so crate downloads/releases, GitHub figures, maintenance responsiveness, RustSec, MSRV/dependency tree, unsafe posture, runtime features, and binary/compile cost are inapplicable. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

Maintenance state: **active** — the current first-party settings reference documents the field; package release and issue metrics are inapplicable to a settings key. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Principles and implementation

The principle is discoverability, not a second instruction document. The announcement must be short enough not to become a stale command catalogue; it should name the project, `AGENTS.md`, and `just --list`, then give `cargo build` and `cargo test` as direct Rust equivalents. Claude Code documents shared-project settings as committed `.claude/settings.json`; actual client display and the field's behavior require re-verification because a user report has alleged a visibility failure in one past version. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05) ([visibility report](https://github.com/anthropics/claude-code/issues/22425); retrieved 2026-09-05)

##### Dominant choice

Commit one concise `companyAnnouncements` entry in `.claude/settings.json`. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Qualified shortlist

The alternatives are no announcement, one concise static announcement, or the TypeScript port's detailed list of recipes. All pass crate-related gates only as inapplicable pattern candidates. The concise entry is OS-neutral configuration for the fixed Ubuntu/macOS support target, but its visible behavior must be confirmed in an installed Claude Code client. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05) ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

##### Excluded by gate

Exclude the detailed recipe inventory on maintenance fitness: exact recipe names drift as the Justfile evolves, and the authoritative command index can be reached by `just --list`. No crate gate excludes a candidate because no crate is involved. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05) ([F176 task-runner evidence](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/dev-experience-repo-hygiene.md#L7-L7); retrieved 2026-09-05)

##### Up-and-comers

Do not replace this static announcement with a SessionStart hook for user-visible onboarding: a current feature request reports hook output as context-only and asks for a visible startup mechanism. This is not a recommendation to add a hook. ([Claude Code issue 32221](https://github.com/anthropics/claude-code/issues/32221); retrieved 2026-09-05)

##### Fit for this template

The template is meant to teach both the canonical `just` interface and normal Rust tooling. A one-line orientation gives both without hard-coding an evolving long recipe list; it preserves the ts benefit while correcting its staleness risk. ([ts settings source](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.claude/settings.json#L1-L17); retrieved 2026-09-05) ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Recommendation

Add one `companyAnnouncements` string: `rs-launch-blueprint: Rust CLI + library + web-service template. Start with just --list; see AGENTS.md for the charter. Direct Rust commands include cargo build and cargo test.` ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Ranked runner-up

Omit the field if an integration test on the supported Claude Code client proves it is not visibly displayed; the root hub remains sufficient for agent instruction. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05) ([visibility report](https://github.com/anthropics/claude-code/issues/22425); retrieved 2026-09-05)

##### Tradeoffs

The announcement provides a visible first action but is static and can become stale. Restricting it to a command index and durable direct Cargo examples makes maintenance small; putting all instructions there would duplicate `AGENTS.md`. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest. No owned or consumed researched parameter exists and no `CONFLICT:` is emitted. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

##### Migration implications

Add `.claude/settings.json` with the one announced string and no plugin-enablement keys. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Validation strategy

Planned: parse `.claude/settings.json` as JSON; assert `companyAnnouncements` is a one-element array containing `just --list` and `AGENTS.md`; then launch Claude Code in the repository and observe the announcement. JSON parsing is automatable on both CI OSs; no client launch was executed. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

##### Confidence & re-verify trigger

Medium confidence as of 2026-09-05: the official reference documents the field, but a reported historical visibility problem means the supported release must be checked during integration. Re-verify on a Claude Code settings-schema change or a failed visible-startup check. ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05) ([visibility report](https://github.com/anthropics/claude-code/issues/22425); retrieved 2026-09-05)

##### Sources

Pattern evidence: [Claude Code settings](https://code.claude.com/docs/en/settings), the [pinned TypeScript settings](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.claude/settings.json#L1-L17), and [issue 22425](https://github.com/anthropics/claude-code/issues/22425), retrieved 2026-09-05.

### Compatibility

The members compose through root `AGENTS.md`: Cursor documents it as a project-rule alternative, Devin/Windsurf feeds it into the same Rules engine as its native rule files, and the Claude announcement points humans to it without redefining it. There is no crate version matrix because the bundle has no Rust crate member. The maintained `openai/codex` example demonstrates a Rust project using `AGENTS.md` and `just`, but it is reference practice rather than a dependency. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05) ([openai/codex AGENTS.md](https://github.com/openai/codex/blob/main/AGENTS.md); retrieved 2026-09-05)

### Parameters

assumes rust-edition = 2024. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as `rust-version` in Cargo.toml and tested in CI. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

assumes license = MIT OR Apache-2.0. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

assumes target-os-matrix = ubuntu-latest, macos-latest. ([fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10); retrieved 2026-09-05)

R43 owns no parameter and consumes no researched parameter. No `CONFLICT:` line is emitted. ([R43 research index](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md); retrieved 2026-09-05)

### Migration implications

Add `.claude/settings.json` with the concise announcement. Do not add `.cursor/rules/projectenv.mdc`, `.windsurf/rules/justfile-rules.md`, or a `.devin/rules` substitute. Keep all universal policy in root `AGENTS.md`; if a future vendor-only rule is needed, add only the current vendor format and record why the hub cannot express it. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05) ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

### Validation strategy

Planned structural checks from the repository root:

```sh
test -f AGENTS.md
test ! -e .cursor/rules/projectenv.mdc
test ! -e .windsurf/rules/justfile-rules.md
python3 -m json.tool .claude/settings.json >/dev/null
python3 - <<'PY'
import json
settings = json.load(open('.claude/settings.json'))
announcements = settings['companyAnnouncements']
assert len(announcements) == 1
assert 'just --list' in announcements[0]
assert 'AGENTS.md' in announcements[0]
assert 'cargo build' in announcements[0]
assert 'cargo test' in announcements[0]
PY
```

Expected result: the hub exists, obsolete duplicate spokes are absent, and the welcome is valid JSON with durable guidance. These are planned checks, not executed results. Manual post-integration checks are to open the repository in Cursor and Devin/Windsurf and verify native hub discovery, then start supported Claude Code and verify a visible announcement; those client checks were not run. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md); retrieved 2026-09-05) ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

### Confidence & re-verify trigger

High confidence for omitting generic Cursor and Windsurf spokes because both vendors document native root-hub support, and medium confidence for the Claude welcome because its field is officially documented but needs visible-client confirmation. Re-run this research if Cursor removes `AGENTS.md` support, Devin/Windsurf changes the preferred `.devin` rule format or native hub discovery, Claude Code removes or changes `companyAnnouncements`, or the template gains a genuinely vendor-only file-scoped policy. ([Cursor Rules](https://cursor.com/docs/rules); retrieved 2026-09-05) ([Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories); retrieved 2026-09-05) ([Claude Code settings](https://code.claude.com/docs/en/settings); retrieved 2026-09-05)

### Sources

- [Cursor Rules](https://cursor.com/docs/rules) — first-party current rule formats, AGENTS.md support, scope, and anti-duplication guidance; retrieved 2026-09-05.
- [Devin Memories & Rules](https://docs.devin.ai/desktop/cascade/memories) and [Devin AGENTS.md](https://docs.devin.ai/desktop/cascade/agents-md) — first-party current preferred `.devin` format, legacy `.windsurf` fallback, activation modes, and root-hub handling; retrieved 2026-09-05.
- [Claude Code settings](https://code.claude.com/docs/en/settings) — first-party project settings scope and `companyAnnouncements` reference; retrieved 2026-09-05.
- [AGENTS.md](https://agents.md/) — open-format stewardship and adoption evidence; retrieved 2026-09-05.
- [openai/codex AGENTS.md](https://github.com/openai/codex/blob/main/AGENTS.md) — maintained Rust-project practice example; retrieved 2026-09-05.
- [Pinned TypeScript D-024](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/docs/port/TS_PORT_DECISIONS.md#L317-L345), [projectenv rule](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.cursor/rules/projectenv.mdc), [Justfile rule](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.windsurf/rules/justfile-rules.md), and [Claude settings](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.claude/settings.json) — pinned precedent; retrieved 2026-09-05.
- [R43 ledger evidence](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L201-L203), [area evidence](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/dev-experience-repo-hygiene.md#L7-L30), and [fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L7-L10) — current program constraints; retrieved 2026-09-05.

Method notes: queried the first-party Cursor, Devin, Claude Code, and AGENTS.md documentation endpoints and inspected pinned ts/py source with `git show`; no crates.io, RustSec, or crate GitHub figure endpoint was queried because every member is a configuration pattern rather than a crate. A direct GitHub REST survey for further Rust-project contents was rate-limited in this environment, so the practice evidence is limited to the accessible maintained `openai/codex` reference. No vendor client was launched; editor discovery and visible Claude startup behavior remain manual integration checks.
