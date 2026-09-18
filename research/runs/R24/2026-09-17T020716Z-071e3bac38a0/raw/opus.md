# R24 — changelog-section-mapping (pattern, light) — Opus raw report

### Landscape

**The category this item decides.** Not "which tool writes the changelog" (inherited: F063,
F066, F073 are `COMMON → REUSE`, tool `release-please`, `docs/port/COMMONALITY.md:69,72,79`)
but **the commit-type visibility policy a changelog generator is configured with**: given a
closed enum of Conventional-Commits types, which types produce a reader-visible section, in
what order, under what heading, and what happens to the rest. The artifact that expresses it
for release-please is the `changelog-sections` array in `release-please-config.json`.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What each is |
|---|---|---|
| Built-in / first-party toolchain | **none** | Cargo has no changelog subcommand and no changelog schema. `cargo package`/`cargo publish` never read or write `CHANGELOG.md`; the Cargo publishing reference only *recommends* keeping one (<https://doc.rust-lang.org/cargo/reference/publishing.html>, retrieved 2026-09-18). There is no first-party Rust answer to this question, so the category is entirely third-party. |
| Established industry standard | **release-please** (the inherited tool) with its `changelog-sections` array; **conventional-changelog-conventionalcommits** preset defaults, which release-please delegates to; **Keep a Changelog 1.1.0** as the human-facing convention; **git-cliff** `commit_parsers`; **cargo-release** (version/tag orchestration; delegates changelog text to a generator) | The `type → section, hidden` mapping shape is common to all of them; only the key names differ. |
| Up-and-comer | **release-plz**, **cocogitto** | Rust-native release managers that embed git-cliff (release-plz) or their own `changelog` table (cocogitto) and ship their own default visible set. |

**Authoritative sources used, and why each is authoritative.**

| Source | Why authoritative |
|---|---|
| `googleapis/release-please` source at tag `v17.11.2` | The maintainer's own implementation of the option this item configures. It is the *only* complete statement of the behaviour: the tool's documentation points at a retired `git.io` shortlink for the default (`docs/manifest-releaser.md:185`, "absence defaults to https://git.io/JqCZL"), so the source is the primary record and the docs are a secondary, partly-broken one. Read at `v17.11.2` (shallow clone of <https://github.com/googleapis/release-please>, 2026-09-18). |
| `schemas/config.json` at `v17.11.2` | The published JSON Schema the two source repositories' configs declare in `$schema`; it fixes which keys are *supported*, as opposed to merely reachable. Retrieved via `GET https://api.github.com/repos/googleapis/release-please/contents/schemas/config.json?ref=v17.11.2`, 2026-09-18. |
| `conventional-changelog-conventionalcommits@6.1.0` (npm) | release-please's pinned rendering engine (`package-lock.json` resolves `6.1.0`); the file `writer-opts.js` contains the transform that actually decides visibility, grouping and section order. Retrieved from `https://registry.npmjs.org/conventional-changelog-conventionalcommits/-/conventional-changelog-conventionalcommits-6.1.0.tgz`, 2026-09-18. |
| Conventional Commits 1.0.0 | Defines the type vocabulary and the `!`/`BREAKING CHANGE` marker whose interaction with hidden types is the decisive mechanism here (<https://www.conventionalcommits.org/en/v1.0.0/>, retrieved 2026-09-18). |
| Keep a Changelog 1.1.0 | The convention the changelog's audience test comes from — "for humans, not machines" (<https://keepachangelog.com/en/1.1.0/>, retrieved 2026-09-18). |
| `orhun/git-cliff` shipped default `config/cliff.toml` at tag `v2.14.2` | The default configuration of the Rust field's most widely used standalone changelog generator; a shipped default is a maintainer's own recommendation, not a blog opinion (<https://raw.githubusercontent.com/orhun/git-cliff/v2.14.2/config/cliff.toml>, retrieved 2026-09-18). |

A single blog post was not used as an authority anywhere in this report.

**Practice evidence — what well-regarded projects actually do, and why they count.**

| Project / artifact | Evidence it is well regarded | What it does about type visibility |
|---|---|---|
| `googleapis/release-please` itself | `stargazers_count` 7517, `archived: false`, `pushed_at` 2026-09-14T18:48:58Z (`GET https://api.github.com/repos/googleapis/release-please`, 2026-09-18); latest release `v17.11.2`, 2026-08-24T21:20:30Z (`GET .../releases/latest`, 2026-09-18) | Its own `release-please-config.json` declares **no** `changelog-sections` key at all — it takes the preset default (read at `v17.11.2`, 2026-09-18). The maintainers' own repository is an adopter of the do-nothing option. |
| release-please's `Python` strategy default (`src/strategies/python.ts:31-45`) | Shipped, maintained default for every `release-type: python` repository | A **total** 12-entry map: `feat`/`fix`/`perf`/`deps`/`revert`/`docs` visible; `style`/`chore`/`refactor`/`test`/`build`/`ci` explicitly `hidden: true`. This is the maintained reference implementation of the *pattern* this report recommends. |
| `git-cliff` shipped default (`config/cliff.toml:63-79`, v2.14.2) | 90-day downloads 48,133; all-time 339,181; newest version 2.14.2 published 2026-09-18 (`GET https://crates.io/api/v1/crates/git-cliff`, 2026-09-18) | Shows **everything**: Features, Bug Fixes, Documentation, Performance, Refactor, Styling, Testing, Miscellaneous Tasks (`chore|ci`), Revert, plus a catch-all `.*` → "Other". Its only skips are `chore(release): prepare for` and **`^chore\(deps.*\)`**. Order is forced with numeric HTML-comment prefixes (`<!-- 0 -->` … `<!-- 10 -->`). |
| `release-plz` | 90-day downloads 68,423; all-time 359,618; newest 0.3.168, 2026-09-17 (`GET https://crates.io/api/v1/crates/release-plz`, 2026-09-18) | Embeds git-cliff, so it inherits the everything-visible-minus-`deps` default above. |
| `cocogitto` | 90-day downloads 8,299; all-time 220,766; newest 7.0.0, 2026-03-04 (`GET https://crates.io/api/v1/crates/cocogitto`, 2026-09-18) | Ships its own `changelog` type map; named here to complete the bin, not evaluated as a candidate (tool choice is out of scope). |
| `cargo-release` | 90-day downloads 16,449; all-time 541,456; newest 1.1.6, 2026-09-16 (`GET https://crates.io/api/v1/crates/cargo-release`, 2026-09-18) | Orchestrates version/tag/publish and delegates changelog text; it takes no position on type visibility, which is itself evidence that the mapping is a separable policy. |

**The field is not uniform on this question.** The two most-used Rust-native generators
(git-cliff, release-plz) default to showing nearly every type and hiding dependency bumps;
release-please and its preset default to showing four types and hiding the rest. So neither
"show almost everything" nor "show almost nothing" can be adopted as *the* ecosystem
convention; the choice has to be argued from the template's audience, which
`### Fit for this template` does.

### Principles and implementation

**The shared requirement.** *A release's changelog entry tells a consumer of the published
artifact what changed for them, so that they can decide whether and how to upgrade; the
mapping from commit type to changelog visibility is declared in one committed file rather
than decided per release.* Source: py `release-please-config.json` (`changelog-sections`,
12 entries) at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`; ts
`release-please-config.json` (`changelog-sections`, 7 entries) at pin
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`; ledger row F067 (`docs/port/COMMONALITY.md:73`,
origin `different`, verdict `DIVERGENT`).

**Agreement level: policy.** What must agree across py, ts and rs is that (a) the mapping is
declared, not defaulted by accident, and (b) it is a *function of the repository's own commit
enum*, so no commit the linter accepts has undefined changelog behaviour. What may vary is
the *membership* of the visible set, because membership is an audience judgement and the
three repositories publish to three different audiences (PyPI package, npm package, crates.io
crate plus a CLI binary plus a service). This is the same conclusion the ledger reached by
classifying F067 `DIVERGENT` rather than `COMMON → REUSE`.

**Essential behaviours.**

1. Every type in `commit-message-convention`'s enum has a declared disposition — visible with
   a heading, or hidden with a heading held in reserve for its breaking changes.
2. A breaking change is never lost and never rendered under a machine-looking heading,
   whatever its type.
3. A `revert:` commit is visible.
4. Bot-generated dependency bumps do not dominate the entry.
5. The section order in the rendered entry is deliberate, not incidental.

**How release-please actually implements this — the four mechanisms that decide the answer.**
All four were read at `v17.11.2` / preset `6.1.0` and then executed (see
`### Validation strategy`).

*Mechanism 1 — `changelog-sections` replaces, never merges.*
`src/changelog-notes/default.ts:65-69` sets `config.types = options.changelogSections` and
passes it to the preset, whose `defaultConfig` is `config.types = config.types || [ … ]`
(`writer-opts.js:176-191`). Supplying the key therefore discards the entire default list,
including the `{type: 'feature', section: 'Features'}` alias. That alias is unreachable under
R38's enum anyway, so nothing is lost — but the replacement semantics mean a partial array is
a *total* policy, which is exactly the trap ts's 7-entry array fell into.

*Mechanism 2 — an unmapped type and an explicitly hidden type are NOT equivalent.*
The preset transform is `if (discard && (entry === undefined || entry.hidden)) return`
(`writer-opts.js:102-103`) — so for an ordinary commit the two are the same, which is what
makes an explicit `hidden: true` entry look redundant. But `discard` is set to `false` by
`commit.notes.forEach(…)` at `:96-99` whenever the commit carries a `BREAKING CHANGE` note,
and release-please attaches that note for a bare `!` marker too (`src/commit.ts:131-136`,
plus the preset's own `add-bang-notes.js`). For a breaking commit the two paths then diverge
at `:105`: `if (entry) commit.type = entry.section`. With an entry, the group heading is the
configured section title; **without an entry, `commit.type` stays the raw lowercase type
string and becomes the heading.**

*Mechanism 3 — array position is the section order, and an unmapped type sorts first.*
`const commitGroupOrder = config.types.flatMap(t => t.section)` and
`commitGroupsSort: (a, b) => commitGroupOrder.indexOf(a.title) - commitGroupOrder.indexOf(b.title)`
(`writer-opts.js:76, 164-168`). `indexOf` returns `-1` for a title that is not in the array,
so an unmapped type's breaking-change group sorts **above Features**. Executed run C in
`### Validation strategy` shows exactly this: under ts's array, a `style!:` commit renders as
`### style` at the top of the entry, above `### Features`.

*Mechanism 4 — `filterCommits` does not apply to `release-type: rust`.*
`src/util/filter-commits.ts:43-63` drops any commit whose type is in neither the visible nor
the hidden list, *even when breaking*. It is imported only by `node.ts:78`, `python.ts:143`,
`node-librarian.ts:79` and `java-yoshi-mono-repo.ts:257`, and only to populate the optional
`changelog.json` artifact. `src/strategies/rust.ts` extends `BaseStrategy` and calls it
nowhere, and — unlike `python.ts:48`, `java.ts:64`, `r.ts:39`, `php.ts:40` — it sets **no**
`CHANGELOG_SECTIONS` fallback. Two consequences for this template, both load-bearing:
the effective default for an unconfigured `release-type: rust` repository is the *preset's*
four-visible-type list, not release-please's own `DEFAULT_CHANGELOG_SECTIONS`
(`filter-commits.ts:20-32`, which additionally omits `deps`); and no `changelog.json` is
produced, so `changelog-sections` has exactly one observable consumer — `CHANGELOG.md` and
the identical release-notes body.

**Architectural alternatives compared before choosing a configuration.** Three shapes exist
for "which types are visible", independent of tool: (A) *inherit* — declare nothing and take
the generator's default; (B) *partial override* — list only the types you want to move,
accepting the default for the rest (this is what ts's array *reads* as, and is a mistake
under mechanism 1, since there is no "rest"); (C) *total map over the repository's own commit
enum* — one entry per type the linter accepts, visible or hidden, in a deliberate order.
(A) fails essential behaviour 1 (undeclared) and 5 (incidental order), and in this template
also fails behaviour 3 only accidentally-not (the preset default does include `revert`).
(B) fails behaviours 1, 2, 3 and 5 as executed run C demonstrates. (C) satisfies all five and
costs eleven lines of JSON. (C) is the pattern; its maintained reference implementation is
release-please's own `Python` strategy default (`src/strategies/python.ts:31-45`, a total map
over the preset's type space) and, in this programme's own sources, py-launch-blueprint's
12-entry array at pin `b08bccfb`.

**No `BASELINE-REVIEW:` finding is emitted by this report.** F063, F066 and F073 were
re-read at `docs/port/BASELINE-REVIEW.md:54,55,60` and re-verified against the live tool
(`release-please` `v17.11.2`, repo unarchived, pushed 2026-09-14); the inherited
release-please mechanism is sound for a Rust repository and nothing in this item challenges
it. The two source-repository defects found here (ts's unmapped `revert` and `style`; py's
unreachable `deps` entry) are facts about the *sources*, recorded under
`### Tradeoffs` as follow-on rationale for the py/ts project, not baseline challenges.

**Observable acceptance criteria.**

- A1: for each of the 11 types in `commit-message-convention`'s enum, a commit of that type
  either appears under its declared section or does not appear, matching the declared table.
- A2: a breaking commit of an otherwise-hidden type appears under that type's declared
  section heading, not under a raw lowercase type string, and not above `Features`.
- A3: a non-breaking `revert:` commit appears under `Reverts`.
- A4: a `chore(deps): …` commit produced under R19's Dependabot configuration produces no
  changelog line.
- A5: `release-please-config.json` validates against the `$schema` it declares.

### Dominant choice

**Inheriting the `conventional-changelog-conventionalcommits` preset default** —
`feat` (and the `feature` alias), `fix`, `perf`, `revert` visible; `docs`, `style`, `chore`,
`refactor`, `test`, `build`, `ci` hidden (`writer-opts.js:178-191`, preset 6.1.0, 2026-09-18).
It is dominant by construction: it is what every release-please repository that declares no
`changelog-sections` key gets, including release-please's own repository
(`release-please-config.json` at `v17.11.2`, no such key). Under `release-type: rust` it is
also the *only* default, because `src/strategies/rust.ts` sets no strategy-level fallback.
Both source repositories in this programme depart from it, in opposite directions.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **A · Inherit the preset default** (declare no `changelog-sections`): `feat`/`fix`/`perf`/`revert` visible | `conventional-changelog-conventionalcommits@6.1.0` `writer-opts.js:176-191`; release-please `docs/manifest-releaser.md:184-186` (whose "defaults to" link, `https://git.io/JqCZL`, is a retired shortlink) | `googleapis/release-please` itself (`release-please-config.json`, no key, `v17.11.2`) | preset 6.1.0 on npm; release-please `v17.11.2`, 2026-08-24 |
| **B · py's set**: `feat`/`fix`/`perf`/`refactor`/`revert`/`deps` visible, `chore`/`docs`/`style`/`test`/`ci`/`build` hidden — a total 12-entry map | py `release-please-config.json:23-36` at pin `b08bccfb` | `py-launch-blueprint`; closely tracks release-please's shipped `Python` strategy default (`src/strategies/python.ts:31-45`), which differs only in showing `docs` and ordering `deps` earlier | py pin `b08bccfb`; strategy default current at `v17.11.2`, 2026-08-24 |
| **C · ts's set**: `feat`/`fix`/`perf`/`docs`/`test`/`refactor` visible, `chore` hidden — a 7-entry **partial** array | ts `release-please-config.json:12-20` at pin `cb1cbcb2`; rationale D-021(3) in `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` | `ts-launch-blueprint` | ts pin `cb1cbcb2` |
| **D · Total map over the repository's commit enum** (recommended): one entry per R38 type, visible set `feat`/`fix`/`perf`/`revert`/`docs`, hidden set `refactor`/`test`/`build`/`ci`/`style`/`chore` | This report; pattern reference implementation release-please `src/strategies/python.ts:31-45` and py's 12-entry array | The *pattern* is shipped by release-please for `python`, `java` (`java.ts:37-51`) and `r` (`r.ts:23-33`); this exact *membership* is composed here and has no named prior adopter — stated as the evidence gap it is | release-please `v17.11.2`, 2026-08-24 |
| **E · Everything visible except dependency bumps** (git-cliff's shipped default shape) | `orhun/git-cliff` `config/cliff.toml:63-79` at `v2.14.2` | `git-cliff`, and `release-plz` which embeds it | git-cliff 2.14.2 on crates.io, 2026-09-18 |

### Excluded by gate

**No option is excluded by a fitness gate.** Every gate is answered below; the ones marked
`inapplicable` are marked so with their reason rather than omitted. The subject of the gates
is a JSON array inside a configuration file consumed by an inherited tool, so most crate-shaped
gates have no subject.

| Gate | Disposition |
|---|---|
| 1 · license compatible with `MIT OR Apache-2.0` | **Pass.** The configuration itself is repository content under the repository's own dual licence. The tool that reads it, `googleapis/release-please`, is `Apache-2.0` (`GET https://api.github.com/repos/googleapis/release-please` → `license.spdx_id: Apache-2.0`, 2026-09-18), which is compatible, and it runs in CI rather than linking into the crate. |
| 2 · crate and dependency-tree MSRV within `stable minus 2 minor versions, …` | **`inapplicable`.** No crate and no Rust dependency are added. release-please is a Node program executed by a GitHub Action; it contributes nothing to `Cargo.toml`, `Cargo.lock` or the MSRV-tested build. |
| 3 · no open RustSec advisory; `unsafe` posture | **`inapplicable`.** RustSec indexes crates.io crates; there is no `https://rustsec.org/packages/release-please.html` page to consult because release-please is not a crate. No Rust code, safe or `unsafe`, is added by this item. |
| 4 · builds and is tested on `ubuntu-latest, macos-latest` | **Pass, trivially.** The mapping is data read by the release workflow, which runs on `ubuntu-latest`; the rendering is platform-independent JSON→Markdown and touches no target-OS behaviour. The probe in `### Validation strategy` executed on macOS (Darwin 25.4.0, Node v26.5.0) and produces the same output the Linux runner would, since no platform-conditional code is on the path. Windows: noted, not required, and equally unaffected. |
| 5 · default features and async-runtime coupling | **`inapplicable`.** No Cargo feature and no async runtime are involved. For completeness: the mapping is orthogonal to `web-extra-surface`'s `web` feature — one `CHANGELOG.md` covers all three shapes whatever features are enabled. |
| 6 · binary-size and compile-time cost | **`inapplicable`, qualitatively zero.** Eleven JSON objects in a file Cargo never reads. No effect on `cargo build` time, incremental rebuild, or artifact size. |

### Up-and-comers

`release-plz` (90-day downloads 68,423; newest 0.3.168, 2026-09-17; `GET
https://crates.io/api/v1/crates/release-plz` and `/versions`, 2026-09-18) and `cocogitto`
(90-day downloads 8,299; newest 7.0.0, 2026-03-04; same endpoints, 2026-09-18) are the
Rust-native release managers rising against release-please. Maintenance state: release-plz
**active** (a release yesterday); cocogitto **stable-quiet** by the rubric — no release in
6 months is the trigger to investigate, not the verdict, and no unpatched advisory, broken
build on current stable, or maintainer notice was found, so `at-risk` is not claimed.

They matter to this item in exactly one way, and it is not as candidates: **both ship an
everything-visible default**, release-plz because it embeds git-cliff's `commit_parsers`
(`config/cliff.toml:63-79`) and cocogitto because its `changelog` defaults render each type
group. That is what keeps option E on the table as a real position in the Rust field rather
than a strawman. Replacing release-please with either is explicitly out of scope
(`## Out of scope`; F063/F066/F073 `COMMON → REUSE`; ts D-021(3) rejected git-cliff and
cocogitto on redundancy), and this report does not propose it. The one forward-looking note:
if a future item ever revisits the generator, the mapping recommended here ports as
`commit_parsers` entries with `skip = true` for the hidden set, so the policy survives the
tool change — which is the point of deciding membership at the policy level rather than
inheriting a tool's default.

### Fit for this template

The template is one repository publishing one `CHANGELOG.md` across three shapes, so the
sections cannot be specialised per shape. The argument has to name which shape's reader
dominates, and pay the cost for the others.

**Library.** The decisive shape, and the one whose reasoning differs from both py's and ts's.
A Rust library is consumed as a *published crate*, and rustdoc ships **inside** that crate:
docs.rs builds the documentation from the uploaded `.crate` file, per released version. A
`docs:` commit that corrects a wrong example in a `///` block is therefore a change to the
artifact the consumer receives, and it reaches them only when a release happens — the same
delivery condition as a `fix:`. That is a Rust-specific argument with no analogue in py's
reasoning (a Python package's docs are typically a separate Sphinx site) and a different
basis from ts's (D-021(3) shows `docs` because `cog.toml` did, not because of artifact
membership). `refactor` is the mirror image: Conventional Commits defines it as "a code
change that neither fixes a bug nor adds a feature", so by its own definition it cannot
inform an upgrade decision — the semantic-versioning consumer contract is unmoved by it. If
a refactor *does* change observable behaviour it is a `fix` or a `feat!`, not a `refactor`.
So `docs` in, `refactor` out — which rejects py's stance on `refactor` and ts's on `test`
while keeping ts's on `docs`, and rejects the claim that either source repo is simply right.

**CLI.** The reader is someone who installed `rslbp` and wants to know what changed between
versions. `feat`, `fix`, `perf` and `revert` are their whole interest. `docs` is partly
wasted on them: a rustdoc fix is invisible to a CLI user, and a README edit is visible only
on the repository page. This is the shape that pays the cost of the library decision, and the
cost is bounded — a handful of lines per release under a clearly-labelled `Documentation`
heading that a CLI user can skip. `test`, `build` and `ci` would be pure noise to this reader
and are hidden.

**Web service.** Deployed from the repository rather than consumed from a registry; its
operator reads the changelog for behavioural and configuration changes, which arrive as
`feat`/`fix`/`perf`. `build` and `ci` changes can matter operationally — but they matter at
deploy time, where the git log and the workflow diff are available, not in a consumer-facing
changelog. Hidden. Note that `web-extra-surface` puts the whole web layer behind an
off-by-default `web` feature, so for most consumers of the published crate these commits are
not even compiled; that reinforces hiding them rather than arguing for a section.

**Across all three:** dependency bumps. R19's resolved decision fixes Dependabot's
`commit-message` to `prefix: "chore"` with `include: "scope"`, so every bot bump arrives as
`chore(deps): …`, at a weekly cadence with a 5-PR budget. Under every candidate array those
commits are hidden, and py's `{"type": "deps", …}` entry never matches one. git-cliff's
shipped default reaches the same place from the opposite direction, skipping
`^chore\(deps.*\)` explicitly. The three-shape template has no reader who benefits from
per-crate bump lines in a release entry; a bump that actually changes the public surface
(an MSRV raise, a re-exported type) is a `feat`/`fix`/`!` commit under R38's enum and is
visible on that basis.

### Recommendation

**Adopt the *total ordered type map*: one `changelog-sections` entry for every type in
`commit-message-convention`'s enum — eleven entries, no more and no fewer — visible set
`feat`, `fix`, `perf`, `revert`, `docs` in that order, hidden set `refactor`, `test`,
`build`, `ci`, `style`, `chore` after them, with release-please's own default headings
(`src/changelog-notes.ts:43-54`) as the section titles.**

```json
"changelog-sections": [
  { "type": "feat",     "section": "Features" },
  { "type": "fix",      "section": "Bug Fixes" },
  { "type": "perf",     "section": "Performance Improvements" },
  { "type": "revert",   "section": "Reverts" },
  { "type": "docs",     "section": "Documentation" },
  { "type": "refactor", "section": "Code Refactoring",        "hidden": true },
  { "type": "test",     "section": "Tests",                   "hidden": true },
  { "type": "build",    "section": "Build System",            "hidden": true },
  { "type": "ci",       "section": "Continuous Integration",  "hidden": true },
  { "type": "style",    "section": "Styles",                  "hidden": true },
  { "type": "chore",    "section": "Miscellaneous Chores",    "hidden": true }
]
```

Four properties make this the recommendation rather than a taste:

1. **Totality is derived, not chosen.** The array's membership is exactly R38's enum, so it
   cannot drift out of sync silently: adding a type to the linter without adding it here is
   a visible one-line omission, and a type here that the linter rejects is dead config.
2. **The hidden entries are load-bearing**, and this is the answer to the LOW question: they
   are *not* redundant with release-please's unmapped-is-hidden behaviour. For an ordinary
   commit they are (`writer-opts.js:102-103`); for a **breaking** commit of a hidden type
   they decide the heading and the position (`:105`, `:164-168`). Executed run C below shows
   the failure they prevent — `### style` above `### Features`.
3. **Headings are the tool's own defaults verbatim**, so the array expresses only membership
   and order and adds no vocabulary a maintainer has to keep consistent.
4. **Order is deliberate.** The visible order is the preset's own severity order
   (`feat`, `fix`, `perf`, `revert`) with `Documentation` appended after it, so the
   behavioural sections always precede the documentation section; the hidden entries follow,
   which is where their breaking-change groups then render.

Answers to the remaining prompt questions, stated plainly:

- **HIGH — which types have no py-or-ts precedent?** None. py's 12-entry array covers all
  eleven of R38's types (plus the unreachable `deps`), so every type has at least one
  precedent. The genuinely open calls are the **three the sources contradict each other on** —
  `docs` (py hidden, ts visible → **visible**), `test` (py hidden, ts visible → **hidden**),
  `refactor` (py visible, ts visible → **hidden**, departing from *both*). The reverse case is
  the notable one: `deps` is a precedent with no type.
- **HIGH — noise or signal for a Rust audience?** `refactor` and `test` are noise; see
  `### Fit for this template`. `docs` is signal, on an artifact-membership argument that is
  Rust-specific and is *not* the reasoning either source used.
- **MEDIUM — a `deps` section?** No, and more strongly than "not worth it": under R38's enum
  `deps` is not a legal type, so a `{"type": "deps"}` entry can never match a commit this
  repository accepts. It is unreachable configuration, exactly as it is in py, where R19's
  own evidence shows bumps arriving as `chore(deps): …`.
- **MEDIUM — anything in the schema beyond visible/hidden?** Two things, one adopted and one
  rejected. *Adopted:* section **order is positional** — the array index is the rendering
  rank (`writer-opts.js:76,164-168`). The schema never says so and neither source repository
  appears to have ordered deliberately, so this is a real capability recovered from the
  implementation. *Rejected:* the preset's `findTypeEntry` also matches an `entry.scope`
  field (`writer-opts.js:60-71`), which would allow `{"type":"chore","scope":"deps",
  "section":"Dependencies"}` — the only honest way to build a Dependencies section under this
  template's grammar. It is rejected because release-please neither declares `scope` in its
  `ChangelogSection` interface (`src/changelog-notes.ts:41-45`) nor in `schemas/config.json`,
  so it is undocumented behaviour that survives only because the key is passed through
  untouched; and because `types.find` is first-match, so the scoped entry would have to
  precede its unscoped sibling — a positional dependency no schema enforces. Two other
  documented keys were considered and are not adopted: `changelog-path` (default
  `CHANGELOG.md` is correct, and `build-tool-output-shape`'s `include` allow-list already
  names `/CHANGELOG.md`) and `changelog-type: github` (would replace the generated body with
  GitHub's auto-notes and discard the type mapping entirely).
- **LOW — explicit hidden entries for `ci`/`build`?** Yes, explicitly, for the
  breaking-change heading and ordering reason in point 2 above. "Unmapped is hidden" is true
  only for non-breaking commits.

### Ranked runner-up

**Option A — inherit the preset default** (`feat`/`fix`/`perf`/`revert` visible), written out
as a total eleven-entry map so that properties 1, 2 and 4 above are kept; i.e. the
recommended array with the `docs` entry moved down and given `"hidden": true`. It differs
from the recommendation by exactly one boolean.

**The condition under which it wins:** if the owner judges the CLI binary and the web service
— not the published library crate — to be the template's primary consumed artifacts, the
artifact-membership argument for `docs` loses its subject, and `Documentation` becomes a
section two of the three readers skip. It also wins on a second, independent condition: if
the template's contributing guidance is not going to distinguish rustdoc changes from
repository-meta changes (README, CONTRIBUTING, this repository's own docs), because then the
`Documentation` section mixes shipped and unshipped changes and its signal degrades toward
`refactor`'s.

Third place, not second, is **option B (py's set)**: it is a total map and gets properties 1
and 2 right, but it shows `refactor`, which the Conventional Commits definition itself says
carries no consumer-visible change, and carries an unreachable `deps` entry. Option C (ts's
set) is last on the executed evidence below, and option E (everything visible) is rejected
as a position that inverts the Keep a Changelog audience test.

### Tradeoffs

**Versus option A (the runner-up).** Gives up the quietest possible default. A repository
whose documentation work is mostly README polish will carry `Documentation` lines that two of
its three reader groups skip. Accepted because a rustdoc correction is a change to the
published crate that reaches the consumer only at release time, and silently withholding it
is the worse failure; the cost is a few skippable lines under a labelled heading. **Mitigation
recommended, not asserted:** the template's `CONTRIBUTING.md` should say that `docs:` is for
documentation that ships in the crate and that repository-meta documentation is `chore:`.
That is a documentation convention this item proposes; it is not a change to R38's enum and
does not need one.

**Versus option B (py's set).** Gives up `refactor` visibility, so a large internal
restructuring that genuinely took a release cycle produces no changelog line. Accepted:
`refactor` is defined as behaviour-preserving, and a reader deciding whether to upgrade is
asking about behaviour. Also gives up the `deps` entry, which costs nothing because it
matches nothing.

**Versus option C (ts's set).** Gives up `test` visibility, which costs the reader nothing —
test changes are not in the published crate at all (`build-tool-output-shape`'s `[package]
include` allow-list is `/src`, the two licences, `README.md` and `CHANGELOG.md`; integration
tests are not packaged). What is *gained* rather than given up is the repair of two defects
run C exhibits, and these are the follow-on rationale for the py/ts project that the HIGH
owner-clarification question asks for:

- ts's array has no `revert` entry, so a non-breaking `revert:` commit is discarded from the
  changelog entirely. Executed run C has no `Reverts` section.
- ts's array omits `style`, `build` and `ci`, so a breaking commit of any of those three
  renders under a raw lowercase heading, sorted above `Features`. Executed run C shows
  `### style` in that position.
- py's array is total and suffers neither defect; its only dead weight is the `deps` entry.
  Its `Refactor` heading also departs from release-please's own `Code Refactoring` for no
  stated reason.

**Versus option E (everything visible).** Gives up the property that a reader can see the
whole release at a glance. Accepted on the Keep a Changelog test — "for humans, not machines";
a changelog that reprints the git log has stopped selecting, and selection is the only thing
a changelog does that `git log` does not.

**What the recommendation gives up unconditionally.** A release whose commits are all hidden
types produces a version bump with an empty changelog entry. This is a property of every
option except E and is not introduced here; it is observable and P03 should decide whether to
suppress such releases, which is a release-trigger question (F073) rather than a mapping one.

### Parameters

R24 owns no parameter (`## Couplings` → `- owns:` is empty; `research/CLAUDE.md` row R24
carries `—`). The recommendation needs no consumed value changed, so no `CONFLICT:` line is
emitted.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes commit-message-convention = type-enum: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test; header-max-length: 50 (the whole `type(scope): description` line); body-max-line-length: 72; footer-max-line-length: 72; length-semantics: soft-line (the header and every body/footer line are measured up to their last space, so a bare URL or any other un-wrappable final token never violates a cap); bot-exemption: for pull requests opened by dependabot, CI relaxes only the width rules (grammar and type enum stay enforced)

### Migration implications

File-level changes in the template, all additive and all in files that other resolved items
already create:

1. **`release-please-config.json`** — add the eleven-entry `changelog-sections` array shown
   in `### Recommendation` to the `"."` package object, alongside the keys R25 already fixes
   (`"release-type": "rust"`, `"bump-minor-pre-major": true`,
   `"bump-patch-for-minor-pre-major": true`). Keep the `$schema` declaration both source
   repositories carry, `https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json`;
   the array validates against it (verified against `schemas/config.json` at `v17.11.2`,
   whose items require `type` and `section` and allow `hidden`).
2. **`CHANGELOG.md`** — no change from this item. Its existence is F066's and its packaging
   is already settled: `build-tool-output-shape`'s `[package] include` allow-list names
   `/CHANGELOG.md`, so the file ships in the `.crate`.
3. **`CONTRIBUTING.md`** (or whichever file the template uses for commit guidance) — add the
   `docs:`-ships-in-the-crate convention from `### Tradeoffs`, and a short table of which
   types appear in the changelog, so a contributor can predict the effect of their type
   choice. Proposed, not required by the mapping.
4. **No workflow change.** `.github/workflows/release-please.yml` passes no
   `--changelog-sections` flag; the array is read from the config file. No CI job, no
   dependency, no `Cargo.toml` edit.

Nothing in `Cargo.toml`, `Cargo.lock` or the crate graph changes, which is why the
crate-shaped fitness gates are `inapplicable`.

### Validation strategy

**Executed.** A probe was run on 2026-09-18 that reproduces release-please's rendering path
for `release-type: rust` exactly: `src/changelog-notes/default.ts:51-120` calls
`presetFactory({types: changelogSections})` and then
`conventionalChangelogWriter.parseArray(commits, context, preset.writerOpts)`. The probe
replicates those ~40 lines against the versions release-please's own `package-lock.json`
resolves — `conventional-changelog-conventionalcommits@6.1.0`,
`conventional-changelog-writer@6.0.1` — installed from the npm registry. Fixture: one commit
per R38 type, plus `chore(deps): bump serde …`, plus two breaking commits (`style!:` and
`chore!:`) carrying the `{title: 'BREAKING CHANGE'}` note release-please attaches for a bare
`!` (`src/commit.ts:131-136`). Four arrays were rendered: none (the `release-type: rust`
default), py's, ts's, and the recommendation. Environment: Darwin 25.4.0, Node v26.5.0.
Commit SHAs in the output are fixture constants and were collapsed to `([sha])`.

The four results, abbreviated to the section headings in rendered order (full bodies were
inspected; the headings are what the acceptance criteria turn on):

| Run | Array | Sections, in rendered order |
|---|---|---|
| A | none (preset default) | `⚠ BREAKING CHANGES`, `Features`, `Bug Fixes`, `Performance Improvements`, `Reverts`, `Styles`, `Miscellaneous Chores` |
| B | py's 12 entries | `⚠ BREAKING CHANGES`, `Features`, `Bug Fixes`, `Performance Improvements`, `Refactor`, `Reverts`, `Miscellaneous`, `Styles` |
| C | ts's 7 entries | `⚠ BREAKING CHANGES`, **`style`**, `Features`, `Bug Fixes`, `Performance Improvements`, `Documentation`, `Tests`, `Code Refactoring`, `Miscellaneous` |
| D | recommended 11 entries | `⚠ BREAKING CHANGES`, `Features`, `Bug Fixes`, `Performance Improvements`, `Reverts`, `Documentation`, `Styles`, `Miscellaneous Chores` |

What that establishes, against the acceptance criteria:

- **A2 confirmed, and the LOW question settled empirically.** Run C renders the breaking
  `style!:` commit under a heading that is the literal lowercase type string, `### style`,
  placed **above** `### Features` — the `indexOf(...) === -1` consequence predicted from
  `writer-opts.js:164-168`. Runs A, B and D, which all map `style` explicitly (hidden),
  render the same commit under `### Styles` at its configured rank. An explicit `hidden`
  entry is therefore not redundant.
- **A3 confirmed.** Run C has no `Reverts` section at all: ts's array omits `revert`, and the
  non-breaking `revert:` commit is discarded. Runs A, B and D all render it.
- **A4 confirmed.** No run renders the `chore(deps):` commit — including run B, whose `deps`
  entry does not match it, since `findTypeEntry` matches on `type`, and the commit's type is
  `chore`.
- **A1 confirmed for run D**: `feat`, `fix`, `perf`, `revert`, `docs` each produced their
  declared section; `refactor`, `test`, `build`, `ci` produced nothing; `style` and `chore`
  produced nothing except through their breaking variants.
- Section order followed array position in every run (run D places `Documentation` after
  `Reverts` because it is later in the array; run A places `Reverts` before `Styles` for the
  same reason).

One artifact to record honestly: the `⚠ BREAKING CHANGES` bullets render empty in all four
runs because the fixture passes `text: ''` for the breaking note, which is release-please's
initial value (`src/commit.ts:135`) before a `BREAKING CHANGE:` footer populates it. That is a
property of the fixture, not a finding about any array, and it is identical across all four
runs so it does not affect the comparison.

**Proposed, not executed** — for P03, on the real template, because they need a repository
and a release cycle that do not exist yet:

1. `npx release-please@17.11.2 release-pr --dry-run --repo-url=<owner>/rs-launch-blueprint
   --config-file=release-please-config.json --manifest-file=.release-please-manifest.json`
   against a branch seeded with one commit of each of the eleven types, asserting the rendered
   body matches run D's section set. This is the end-to-end form of A1.
2. A JSON-schema assertion in CI: validate `release-please-config.json` against the `$schema`
   it declares, and assert the `changelog-sections` `type` values are exactly R38's enum —
   set equality, so that adding a type to the linter without adding it here fails a check.
   This is A5 plus the totality property, and it is the check that keeps the two files in
   sync over the template's life.
3. Criterion A2 as a regression test on a real `style!:` commit, since it is the only
   criterion whose failure mode is silent and cosmetic.

### Confidence & re-verify trigger

**High** on the mechanisms (replacement semantics, unmapped-versus-hidden divergence for
breaking commits, positional ordering, `filterCommits` not reaching the Rust strategy): each
was read in the maintainer's source at a pinned tag and then reproduced by execution against
the pinned rendering engine, and the two agree.

**High** on the structural half of the recommendation (a total map over R38's enum, explicit
hidden entries, deliberate order): it follows from the mechanisms and from the executed
failure of the partial array, and its pattern has a shipped reference implementation in
release-please's own `python`/`java`/`r` strategy defaults.

**Medium** on one membership call, `docs` visible. It rests on an artifact-membership argument
(rustdoc ships in the `.crate` and renders per version on docs.rs) that is sound but whose
weight depends on which shape's reader the owner treats as primary — a judgement, not a fact.
The runner-up differs by that one boolean, so the cost of being wrong is one line of JSON and
no migration. Every other membership call (`refactor`, `test`, `build`, `ci`, `style`, `chore`
hidden; `feat`, `fix`, `perf`, `revert` visible) is agreed by at least two of the five options
surveyed and is not close.

**Re-verify when any of these changes:**

- `commit-message-convention`'s type enum (R38). The array's membership is defined as that
  enum; any addition or removal makes this answer incomplete rather than merely stale.
- release-please's major version, or its pinned `conventional-changelog-conventionalcommits`
  major. The visibility, grouping and ordering behaviour all live in the preset's
  `writer-opts.js`; a preset major bump is the single event most likely to invalidate the
  executed evidence. Current pins: release-please `v17.11.2` (2026-08-24), preset `6.1.0`.
- `src/strategies/rust.ts` gaining a `CHANGELOG_SECTIONS` fallback the way `python.ts:48`
  has one. That would change the *default* this recommendation is argued against, though not
  the recommendation itself, since it declares the array explicitly.
- R19's Dependabot `commit-message.prefix`, if it ever moves off `chore`. The `deps` answer
  is conditioned on bumps arriving as `chore(deps): …`.
- A decision to replace release-please (currently foreclosed by F063/F066/F073 and ts
  D-021(3)). The membership policy ports; the key names do not.

### Sources

| # | Source | Retrieved |
|---|---|---|
| 1 | `googleapis/release-please` at tag `v17.11.2` — `src/changelog-notes/default.ts`, `src/changelog-notes.ts`, `src/util/filter-commits.ts`, `src/strategies/rust.ts`, `src/strategies/python.ts`, `src/strategies/node.ts`, `src/strategies/java.ts`, `src/strategies/r.ts`, `src/commit.ts`, `docs/manifest-releaser.md`, `release-please-config.json`, `package-lock.json` (shallow clone of <https://github.com/googleapis/release-please>) | 2026-09-18 |
| 2 | `GET https://api.github.com/repos/googleapis/release-please/releases/latest` → `tag_name: v17.11.2`, `published_at: 2026-08-24T21:20:30Z` | 2026-09-18 |
| 3 | `GET https://api.github.com/repos/googleapis/release-please` → `stargazers_count: 7517`, `archived: false`, `pushed_at: 2026-09-14T18:48:58Z`, `license.spdx_id: Apache-2.0` | 2026-09-18 |
| 4 | `GET https://api.github.com/search/issues?q=repo:googleapis/release-please+is:issue+is:open` → `total_count: 300` | 2026-09-18 |
| 5 | `GET https://api.github.com/repos/googleapis/release-please/contents/schemas/config.json?ref=v17.11.2` — `changelog-sections` item schema (`type`, `section` required; `hidden` boolean, "Defaults to `false`"), and the `changelog-type`, `changelog-path`, `changelog-host`, `skip-changelog` siblings | 2026-09-18 |
| 6 | `conventional-changelog-conventionalcommits@6.1.0` — `writer-opts.js`, `add-bang-notes.js`, `parser-opts.js`, from `https://registry.npmjs.org/conventional-changelog-conventionalcommits/-/conventional-changelog-conventionalcommits-6.1.0.tgz` | 2026-09-18 |
| 7 | `conventional-changelog-writer@6.0.1` (npm), used to execute the probe | 2026-09-18 |
| 8 | py-launch-blueprint `release-please-config.json` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (`git -C ~/c/py-launch-blueprint show b08bccfb:release-please-config.json`) | 2026-09-18 |
| 9 | ts-launch-blueprint `release-please-config.json` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (`git -C ~/c/ts-launch-blueprint show cb1cbcb2:release-please-config.json`) | 2026-09-18 |
| 10 | `https://raw.githubusercontent.com/orhun/git-cliff/v2.14.2/config/cliff.toml` — `commit_parsers` at `:63-79` | 2026-09-18 |
| 11 | `GET https://crates.io/api/v1/crates/git-cliff` → `recent_downloads: 48133`, `downloads: 339181`, `newest_version: 2.14.2`, `updated_at: 2026-09-18T21:21:53Z` | 2026-09-18 |
| 12 | `GET https://crates.io/api/v1/crates/release-plz` → `recent_downloads: 68423`, `downloads: 359618`, `newest_version: 0.3.168`, `updated_at: 2026-09-17T16:10:51Z` | 2026-09-18 |
| 13 | `GET https://crates.io/api/v1/crates/cocogitto` → `recent_downloads: 8299`, `downloads: 220766`, `newest_version: 7.0.0`, `updated_at: 2026-03-04T08:33:54Z` | 2026-09-18 |
| 14 | `GET https://crates.io/api/v1/crates/cargo-release` → `recent_downloads: 16449`, `downloads: 541456`, `newest_version: 1.1.6`, `updated_at: 2026-09-16T21:49:48Z` | 2026-09-18 |
| 15 | Conventional Commits 1.0.0 — <https://www.conventionalcommits.org/en/v1.0.0/> (the `refactor` definition and the `!` marker) | 2026-09-18 |
| 16 | Keep a Changelog 1.1.0 — <https://keepachangelog.com/en/1.1.0/> ("for humans, not machines") | 2026-09-18 |
| 17 | Cargo publishing reference — <https://doc.rust-lang.org/cargo/reference/publishing.html> (Cargo recommends but does not generate a changelog) | 2026-09-18 |
| 18 | This repository: `docs/port/COMMONALITY.md:69,72,73,79`; `docs/port/BASELINE-REVIEW.md:54,55,60`; `docs/port/PARAMETERS.md`; `research/topics/25-semver-bump-strategy/DECISION.md` (`release-type: rust`, both pre-major flags `true`); `research/topics/19-dependabot-config-shape/DECISION.md` (`commit-message` `prefix: "chore"` + `include: "scope"`) | 2026-09-18 |

**Method notes.** Endpoints queried: `api.github.com` (`/repos/googleapis/release-please`,
`/releases/latest`, `/search/issues`, `/contents/schemas/config.json?ref=v17.11.2`), each
spaced at least 20 s apart; `registry.npmjs.org` (package metadata and the
`conventional-changelog-conventionalcommits` 6.1.0 tarball); `crates.io/api/v1/crates/<name>`
for `git-cliff`, `release-plz`, `cocogitto`, `cargo-release` with a User-Agent header;
`raw.githubusercontent.com` for git-cliff's default `cliff.toml` at `v2.14.2`; and a shallow
`git clone --depth 1 --branch v17.11.2` of `googleapis/release-please` for the source reads
above. Both source repositories were read through their programme pins with `git show`, never
from the working tree.

Not verified, and why: (a) **`crate.recent_downloads` / `crate.downloads` / RustSec for the
decided subject** — release-please is an npm package executed by a GitHub Action, so the
crates.io and RustSec endpoints have no entry for it; the crates.io figures above are for the
landscape bins only, and are not claims about the inherited tool. (b) **Issue-responsiveness
(median days to first maintainer response over the 10 most recently opened issues)** — not
computed. The open-issue count is recorded (300); the responsiveness figure would be evidence
about whether to *keep* release-please, a question F063/F066/F073 close as `COMMON → REUSE`
and this item's `## Out of scope` excludes. Stated as an omission, not an oversight.
(c) **The documented default's canonical page** — release-please's
`docs/manifest-releaser.md:185` points the default at `https://git.io/JqCZL`, a retired
GitHub shortlink service; no live documentation page states the default list, so the default
is cited from the preset source (`writer-opts.js:176-191`) instead. (d) **The two proposed
end-to-end checks in `### Validation strategy`** were not run: they need a real repository,
a `.release-please-manifest.json` and a release cycle, none of which exist during P02. The
probe that *was* run is a faithful replication of the rendering path, not the action itself.
