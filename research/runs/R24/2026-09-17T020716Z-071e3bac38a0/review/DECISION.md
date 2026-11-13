# 2026-09-28 — R24 — changelog-section-mapping (pattern, Light) — decision (revision 2)

**What revision 2 changes, and why. The recommendation does not move: the
eleven-entry array, its order, its headings, the ledger row, the runner-up and
the five `- assumes` lines are byte-identical to revision 1.** Revision 1
(sha256 `bc5dcafa1ac0a864ce458bdc45dee92f02385cb28ebde7e8af364a5b04683a52`,
preserved as `review/R24-r1-snapshot.md`) was rejected by its judgment audit
(`review/audit-fable.md.v2`) on two blocking findings and one minor one; the
filed empirical audit `review/audit-claude.md` approved. This revision repairs exactly those three. **Finding
1 — engine account.** Revision 1 named Codex as the absent required leg. The
item's required engine is now Muse, under owner decision Q5.A's bulk
substitution, and a Muse report exists that disagrees on three memberships.
`## Engines` now names Muse, represents its position, and adjudicates the
three disagreements (`refactor`, `docs`, a scope-routed `Dependencies`
section) with evidence; Muse's four scope routes are filtered against R19
rather than adopted. **Finding 2 — the `deps` and schema questions.** Revision
1 concluded that dependency bumps are hidden "under every candidate array",
which holds only because a reachable alternative was not considered: a
`{"type": "chore", "scope": "deps", "section": "Dependencies"}` entry. This
revision answers the schema question on the `scope` axis, executes the
config-file loader to confirm the key survives it (new probe
`review/evidence/probe/loader.cjs`, new checks 7d and 9a–9f), and re-argues
dependency visibility against that entry on both audience cost and the
mechanism-5 release-cadence effect. It rejects the entry, for reasons under
*Across all three — dependency bumps*. The check 3h log header is reworded so
that it asserts only what its greps check. **Finding 3 — run C line
numbers.** `### style` and `### Features` are on lines 9 and 14 of
`snap/rendered/C-ts.md`, not 11 and 16; the ordering claim and check 4a stand.
The evidence log was regenerated after the final text of this revision was
fixed: 146 assertions, all `PASS` (`## Empirical check`).

## Decision

**Status.** This decision is a **proposal validated in the implementation phase**
(owner ruling, 2026-09-10). P02 is research only: the template does not exist
yet, P03 builds it, and P03's CI is what proves the recommendation. This
document records what the research found, what was executed here, and what was
not; the unexecuted parts are enumerated under `## Engines` as what P03 must
validate. A decision that does not survive implementation is revised against
this recorded research, not researched again from scratch. **Nothing was built
for this decision**: no `release-please-config.json`, no `CHANGELOG.md`, no
workflow and no template scaffold was written anywhere in this repository, and
release-please was never run against a repository. What was executed is
release-please's own rendering code and, in revision 2, its config-file loader,
called as a library inside a throwaway directory under `$TMPDIR` that the check
script deletes on exit; the loader reads its two files from an in-memory
stand-in for GitHub, not from a repository.

**Fitness gate 1 (licence compatibility) is `inapplicable — owner ruling
2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or
tool`** (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check for
anything the template uses"). The registered report `raw/opus.md` answers gate 1
as **Pass**, reasoning from release-please's `Apache-2.0` declaration; that
evaluation is superseded and is not carried. No candidate is excluded, ranked or
preferred on a licence ground anywhere below, and no licence is recorded as a
test. The repository's own declared `license = MIT OR Apache-2.0` is untouched by
this item, which adds no file carrying a licence header.

**Recommendation — declare a total, ordered `changelog-sections` array: exactly
one entry for each of the eleven types in `commit-message-convention`'s enum, no
more and no fewer.** Visible, in this order: `feat`, `fix`, `perf`, `revert`,
`docs`. Hidden, after them, in this order: `refactor`, `test`, `build`, `ci`,
`style`, `chore`. Every section title is release-please's own default heading for
that type, taken verbatim from the `DEFAULT_HEADINGS` map in
`src/changelog-notes.ts` at tag `v17.11.2` (check 3d, eleven assertions, one per
heading). The array goes in the `"."` package object of
`release-please-config.json`, beside the three keys R25 already fixes
(`"release-type": "rust"`, `"bump-minor-pre-major": true`,
`"bump-patch-for-minor-pre-major": true`):

```json
"changelog-sections": [
  { "type": "feat",     "section": "Features" },
  { "type": "fix",      "section": "Bug Fixes" },
  { "type": "perf",     "section": "Performance Improvements" },
  { "type": "revert",   "section": "Reverts" },
  { "type": "docs",     "section": "Documentation" },
  { "type": "refactor", "section": "Code Refactoring",       "hidden": true },
  { "type": "test",     "section": "Tests",                  "hidden": true },
  { "type": "build",    "section": "Build System",           "hidden": true },
  { "type": "ci",       "section": "Continuous Integration", "hidden": true },
  { "type": "style",    "section": "Styles",                 "hidden": true },
  { "type": "chore",    "section": "Miscellaneous Chores",   "hidden": true }
]
```

**Ledger row this settles.**

| Row | Settled value |
|---|---|
| F067 changelog section type mapping (visible vs hidden) — `docs/port/COMMONALITY.md:73`, origin `different`, verdict `DIVERGENT`, item R24 | The eleven-entry array above: `feat`/`fix`/`perf`/`revert`/`docs` visible in that order, `refactor`/`test`/`build`/`ci`/`style`/`chore` hidden after them, headings verbatim from release-please's `DEFAULT_HEADINGS` |

Three neighbouring rows are **inherited, not re-decided here**, and this decision
changes nothing in them: F063 (version source of truth), F066 (changelog file
generation) and F073 (release trigger), all `COMMON → REUSE` with tool
`release-please` (`docs/port/COMMONALITY.md:69,72,79`;
`docs/port/BASELINE-REVIEW.md:54,55,60`, each `retained`). **No
`BASELINE-REVIEW:` finding is raised by this decision**, and none was raised by
the report it synthesizes.

### Principles and implementation

**The shared requirement, and where it comes from.** *A release entry tells a
consumer of the published artifact what changed for them, so that they can
decide whether and how to upgrade; the mapping from commit type to entry
visibility is declared in one committed file rather than decided per release.*
Source: py-launch-blueprint's `release-please-config.json` at pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` — a twelve-entry `changelog-sections`
array opening at line 22 and running to line 35 (check 6a; the array's entries
are lines 23–34); and ts-launch-blueprint's at pin
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — a seven-entry array opening at line
11 and running to line 19 (check 6b; entries are lines 12–18). Both files were
read through their pins with `git show`, never from a working tree, and both are
snapshotted under `review/evidence/snap/sources/` with the snapshot proved equal
to the pin (check 6c). The ledger classifies the row `DIVERGENT` because the two
sources disagree (`docs/port/COMMONALITY.md:73`).

**Agreement level: policy.** What must agree across py, ts and rs is that (a) the
mapping is *declared*, not inherited by accident, and (b) it is a *total function
of the repository's own commit enum*, so that no commit the linter accepts has
undefined changelog behaviour. What may vary is the *membership* of the visible
set, because membership is an audience judgement and the three repositories
publish to three different audiences — a PyPI distribution, an npm package, and a
crates.io crate that is simultaneously a library, an installed CLI and a
deployable service. That is the same reading the ledger reached by classifying
F067 `DIVERGENT` rather than `COMMON → REUSE`.

**Essential behaviours.** Any acceptable mapping must satisfy all five:

1. Every type in `commit-message-convention`'s enum has a declared disposition —
   visible under a heading, or hidden with a heading held in reserve for its
   breaking changes.
2. A breaking change is never lost and never rendered under a machine-looking
   heading, whatever its type.
3. A non-breaking `revert:` commit is visible.
4. Bot-generated dependency bumps do not dominate the entry.
5. The section order in the rendered entry is deliberate rather than incidental.

**How release-please implements this — five mechanisms, four of them executed
here.** All five were read in release-please's own code at version `17.11.2`, as
shipped by npm, and the first four were then reproduced by calling that code.
The citations name the TypeScript paths; the bytes read and asserted on are the
compiled JavaScript the npm package ships, snapshotted under
`review/evidence/snap/rp-17.11.2/`.

*Mechanism 1 — `changelog-sections` replaces the preset's list; it never merges
into it.* `src/changelog-notes/default.ts` assigns `config.types =
options.changelogSections` and hands `config` to the preset factory, whose own
default is `config.types = config.types || [ … ]` in the preset's
`writer-opts.js` (checks 3a-assigns-types, 3a-preset-default-list; 3a-no-merge
asserts that no concatenation exists). The assignment is guarded by `if
(options.changelogSections)` (check 3a-guarded-by-presence), so declaring nothing
takes the preset default and declaring anything discards the default entirely.
**A partial array is therefore a total policy**, which is the trap ts's
seven-entry array fell into.

*Mechanism 2 — an unmapped type and an explicitly hidden type are not
equivalent.* The preset transform reads `if (discard && (entry === undefined ||
entry.hidden)) return` (check 3g-discard-rule), so for an ordinary commit the two
are indistinguishable — which is exactly what makes an explicit `"hidden": true`
entry look redundant. But `discard` is set to `false` on a commit carrying a
`BREAKING CHANGE` note (check 3g-breaking-clears-discard, two assignments), and
release-please attaches that note for a bare `!` marker too, taking the note's
text from the commit subject (`src/commit.ts`, checks 3f-subject-as-note-text and
3f-push-only-when-nonempty). For a breaking commit the two paths then diverge at
`if (entry) commit.type = entry.section` (check 3g-entry-renames-group): with an
entry the group heading is the configured section title; **without an entry,
`commit.type` stays the raw lowercase type string and becomes the heading.**

*Mechanism 3 — array position is the section order, and an unmapped type sorts
first.* The preset builds `const commitGroupOrder = config.types.flatMap(t =>
t.section)` and sorts groups by `commitGroupOrder.indexOf(a.title)` (checks
3g-group-order-from-array, 3g-sort-by-indexof). `indexOf` returns `-1` for a
title absent from the array, so an unmapped type's breaking-change group sorts
**above Features**. Executed run C shows precisely that: under ts's array a
`style!:` commit renders as `### style` at line 9 of the entry, above `###
Features` at line 14 (checks 4a-raw-lowercase-heading, 4a-sorted-above-features).

*Mechanism 4 — the Rust strategy sets no fallback, so the preset default is the
whole default.* `src/strategies/rust.ts` extends `BaseStrategy` and contains zero
occurrences of `CHANGELOG_SECTIONS` and zero of `filterCommits` (checks
3b-rust-no-changelog-sections, 3b-rust-no-filter-commits, 3b-rust-extends-base) —
unlike the `python`, `java` and `r` strategies, each of which ships a
strategy-level fallback array. Two consequences follow, and both are
load-bearing. First, the effective default for an unconfigured `release-type:
rust` repository is the *preset's* four-visible-type list, not release-please's
own `DEFAULT_CHANGELOG_SECTIONS`. Second, the `filterCommits` helper — which
drops any commit whose type is in neither list, even when breaking — never runs
for a Rust repository at all.

That second helper is worth naming for a reason beyond its absence:
`DEFAULT_CHANGELOG_SECTIONS` in `src/util/filter-commits.ts` is itself an
**eleven-entry total map over exactly the eleven types `commit-message-convention`
declares**, with `feat`/`fix`/`perf`/`revert` visible, the other seven hidden, and
no `deps` entry (checks 3c-entry-count, 3c-visible-four, 3c-no-deps-entry). The
pattern this decision recommends is therefore not invented here: release-please's
own maintained default is a total map over the same type space, and the
recommendation differs from it in two respects only — `docs` is moved to the
visible set, and the order is stated deliberately.

*Mechanism 5 — the visible set is also the releasable set.* This is the one the
report read but did not execute; it is executed here. `src/strategies/base.ts`
builds the release-notes body from the rendering path above (`const
releaseNotesBody = await this.buildReleaseNotes(…)`, check
3e-body-is-rendered-notes), then guards release-pull-request creation with `if
(!bumpOnlyOptions && this.changelogEmpty(releaseNotesBody))` → log `No user
facing commits found since <sha> - skipping` → `return undefined` (checks
3e-guard-call-site, 3e-guard-log, 3e-guard-returns-undefined). The predicate is
`changelogEntry.split('\n').length <= 1` (checks 3e-predicate-signature,
3e-predicate-body). The probe takes that predicate **off
`BaseStrategy.prototype`** — release-please's own function object, not a
re-typed copy — and applies it to bodies produced by release-please's own
`buildNotes`. Under the recommended array, a push of `test:` + `ci:` +
`chore(deps):` renders a body of exactly one line, the release header, and the
predicate returns `true` (checks 5a-predicate-text, 5b-line-count, 5b-empty-true,
5b-body-is-header-only, 5b-body-has-no-sections). Adding a single `fix:` commit
to the same push makes the predicate return `false` and produces a `### Bug
Fixes` section (checks 5c-empty-false, 5c-bug-fixes-section). So **a push whose
commits all map to hidden or unmapped types opens no release pull request at
all** — not a version bump with an empty entry, but no release. Hiding a type
does not merely omit its lines; it makes commits of that type unable to ship on
their own. What remains read rather than executed is only the control flow around
the predicate — that `return undefined` in `buildReleasePullRequest` is what a
caller sees as "no release pull request"; driving `buildReleasePullRequest`
itself needs a GitHub repository and is P03's check A6.

**Architectural alternatives compared, before any configuration was chosen.**
Three shapes exist for "which types are visible", independent of the tool:

| Shape | What it is | How it fares against the five behaviours |
|---|---|---|
| A · Inherit | declare no `changelog-sections` and take the generator's default | Fails 1 (undeclared) and 5 (incidental order). Satisfies 3 only accidentally, because the preset default happens to include `revert`. Executed as run A |
| B · Partial override | list only the types you want to move, expecting the default for the rest | Fails 1, 2, 3 and 5, because mechanism 1 means there is no "rest". Executed as run C — ts's array |
| C · Total ordered map | one entry per type the linter accepts, visible or hidden, in a deliberate order | Satisfies all five, and costs eleven lines of JSON. Executed as run D |

Shape C is the pattern. Its maintained reference implementations are
release-please's own `DEFAULT_CHANGELOG_SECTIONS` and its `python`, `java` and
`r` strategy defaults; within this programme, py's twelve-entry array is the same
shape. The *membership* recommended here is composed for this template and has no
named prior adopter — stated as the evidence gap it is.

**Why this membership, per target shape.** The template is one repository
publishing one `CHANGELOG.md` across three shapes, so the sections cannot be
specialised per shape; the argument has to name which shape's reader dominates
and pay the cost for the others.

*Library — the decisive shape, and the one whose reasoning differs from both
sources'.* A Rust library is consumed as a published crate, and rustdoc ships
**inside** that crate: docs.rs documents every library published to crates.io and
renders per published version. A `docs:` commit that corrects a wrong example in
a `///` block is therefore a change to the artifact the consumer receives, and it
reaches them only when a release happens — the same delivery condition as a
`fix:`. Mechanism 5 turns that from a preference into a capability question: with
`docs` hidden, a sprint of documentation work opens no release pull request at
all, so corrected rustdoc cannot reach docs.rs until an unrelated `feat` or `fix`
drags it out. With `docs` visible, documentation can ship on its own. That
argument has no analogue in py's reasoning (a Python distribution's prose docs
are typically a separate site) and a different basis from ts's, whose D-021(3)
shows `docs` because `cog.toml` did, not because of artifact membership.
`refactor` is the mirror image: Conventional Commits defines it as a change that
neither fixes a bug nor adds a feature, so by its own definition it cannot inform
an upgrade decision; a refactor that *does* change observable behaviour is a
`fix` or a `feat!`, not a `refactor`. So `docs` in, `refactor` out — which
rejects py's stance on `refactor` and ts's on `test` while keeping ts's on
`docs`, and declines to treat either source as simply right.

*CLI.* The reader installed the binary and wants to know what changed between
versions; `feat`, `fix`, `perf` and `revert` are their whole interest. `docs` is
partly wasted on them — a rustdoc correction is invisible to a CLI user. This is
the shape that pays the cost of the library decision, and the cost is bounded: a
few skippable lines under a clearly labelled `Documentation` heading. `test`,
`build` and `ci` would be pure noise and are hidden.

*Web service.* Deployed from the repository rather than consumed from a registry;
its operator reads the entry for behavioural and configuration changes, which
arrive as `feat`/`fix`/`perf`. `build` and `ci` changes can matter operationally,
but they matter at deploy time, where the git log and the workflow diff are
available. Hidden. R69's published `web-extra-surface` puts the whole web layer
behind an off-by-default `web` Cargo feature, so for most consumers of the
published crate those commits are not even compiled — which reinforces hiding
them rather than arguing for a section.

*Across all three — dependency bumps.* R19's published decision fixes
Dependabot's `commit-message` to `prefix: "chore"` with `include: "scope"` on
both of its entries, `cargo` and `github-actions` (check 9f), and py's own
`.github/dependabot.yml` at pin `b08bccfb` sets the same two keys on every
ecosystem entry (lines 24–27, 57–59, 74–77), so every bot bump arrives as
`chore(deps): …`. py's `{"type": "deps", "section": "Dependencies"}` entry never
matches one, because the commit's type is `chore`. Executed: none of runs A–D
renders the `chore(deps): bump serde …` fixture commit, py's run included, and
py's run produces no `Dependencies` section at all (checks 4g-no-bump ×4,
4g-py-no-dependencies-section). **The bare `deps` entry is unreachable
configuration. A reachable way to show bumps does exist, and revision 1 did not
evaluate it.**

*The scope-routed alternative.* The preset's type lookup matches on `scope` as
well as `type` whenever an entry declares one: `findTypeEntry` rejects an entry
`if (entry.scope && entry.scope !== commit.scope)` (check 9a). So the entry
`{"type": "chore", "scope": "deps", "section": "Dependencies"}`, placed before
the bare `chore` entry because the lookup takes the first match, captures
exactly the bot bumps. Three facts make it a real option. (1) **The schema
leaves `scope` undocumented but does not reject it.** An entry's declared
properties are `type`, `section` and `hidden`, with `type` and `section`
required, and no `scope` (checks 3h, 9b). The entry object also declares no
`additionalProperties` (check 9b-entry-no-additional-properties), so under JSON
Schema an entry carrying `scope` still validates. release-please exports that
schema as `configSchema` (`build/src/index.js:36`), and — read, not executed —
nothing under `build/src` validates a configuration against it on load. (2)
**The config-file loader passes the key through unchanged.**
`review/evidence/probe/loader.cjs` gives release-please's own
`Manifest.fromManifest` a `release-please-config.json` carrying the entry,
beside R25's three keys, over an in-memory GitHub stand-in. The path it drives
is `parseConfig` → `extractReleaserConfig` → `mergeReleaserConfig` →
`getStrategiesByPath`, and the Rust strategy it builds holds twelve entries
with the scoped entry intact (checks 9c). (3) **The strategy renders it.** That
strategy's own `buildReleaseNotes` puts the bump under `### Dependencies`
(checks 9d-dependencies-heading, 9d-bump-rendered). This agrees with the
revision-1 judgment audit's scratch render, which called `buildNotes` directly.

*Only one scope route is reachable under R19.* Muse's report proposes four
routes: `chore(deps)`, `chore(deps-dev)`, `build(deps)` and `build(deps-dev)`.
Both R19 entries fix `prefix: "chore"`, so neither `build(…)` route can match a
bot commit (check 9f-r19-prefix-chore). R19 records that `include: "scope"`
"can only ever append `deps` for a Cargo entry"
(`research/topics/19-dependabot-config-shape/DECISION.md:134`, check
9f-r19-cargo-deps-only), so `chore(deps-dev)` is unreachable for the `cargo`
entry. R19 records nothing about `deps-dev` for its `github-actions` entry;
that case is unrecorded here, not shown unreachable. The alternative that needs
evaluating is therefore the single `chore(deps)` entry.

*Why that entry is rejected — the release-cadence effect.* Mechanism 5 applies
to it directly. The push that opens no release pull request under the
recommendation — `test:` + `ci:` + `chore(deps):` — renders a one-line body
through the loaded strategy, and `changelogEmpty` returns `true` (check
9d-recommended-empty-true). Under the scope-routed entry the same push renders
a six-line body with a `Dependencies` section, and `changelogEmpty` returns
`false` (checks 9d-scope-routed-lines, 9d-scope-routed-empty-false). The guard
therefore does not fire, and release-please goes on to build a release pull
request. What was executed is the predicate on that body; that
`buildReleasePullRequest` then builds a pull request is read at the call site
(checks 3e), exactly as for mechanism 5 in general. R19 schedules both
ecosystems weekly, each with one catch-all group, so any week in which either
ecosystem's grouped pull request is merged puts a `chore(deps)` commit on
`main`. Under the
scope-routed entry, each such week makes a release pull request proposable from
dependency activity alone. Two costs follow. First, a pending release pull
request stops meaning "a consumer-visible change is waiting", which is the
property the next paragraph calls wanted. Second, essential behaviour 4 — bot
bumps do not dominate the entry — fails in exactly the releases that contain
nothing else: an entry proposed only because of bumps consists only of bumps.
Merging stays a human act, so bumps would *open* release pull requests, not
*force* releases; the cost is the lost signal and a recurring bumps-only
release proposal, not an automatic publish.

*What rejecting it costs — the audience side.* Muse argues that visible bumps
carry a transitive and MSRV signal. The MSRV half is thin: `msrv-policy`
declares the MSRV "tested in CI", so a bump that breaks it fails a check on the
bump's own pull request instead of waiting for a changelog reader. The real
cost is different, and revision 1 overstated its absence. Revision 1 said that
a bump which changes the public surface "is a `feat`/`fix`/`!` commit … and is
visible on that basis". A Dependabot commit cannot type itself: it is always
`chore(deps): …`. Such a change therefore reaches the changelog only if a
person commits it, or a follow-up to it, under a visible type. Hiding bumps
accepts that dependence on a person, as the price of behaviour 4 and of the
cadence property. **Condition under which the scope-routed entry wins:** the
owner prefers every dependency move to be visible and accepts a release pull
request that is proposable most weeks. Then add the one entry
`{"type": "chore", "scope": "deps", "section": "Dependencies"}` immediately
before the `chore` entry; nothing else in the array changes.

*Across all three — a consequence of mechanism 5 that is wanted rather than
tolerated.* Because hidden types cannot open a release on their own, a week whose
only commits are Dependabot bumps, CI adjustments and test work produces no
release pull request. That is the behaviour under every shape that hides
dependency bumps — every shape except "show everything" and the scope-routed
entry above — it keeps the release cadence tied to consumer-visible change rather
than to bot activity, and it is why the empty-entry worry does not arise.

**Observable acceptance criteria.** Each is marked with what this decision did
with it. `executed here` means the check script asserts it; `P03` means it needs
a repository and a release cycle that do not exist during P02.

| # | Criterion | Status |
|---|---|---|
| A1 | For each of the eleven types, a commit of that type appears under its declared section or does not appear, matching the table above | **executed here** — run D, checks 4c–4f |
| A2 | A breaking commit of an otherwise-hidden type appears under that type's declared section heading, not under a raw lowercase type string, and not above `Features` | **executed here** — runs C and D, checks 4a and 4c |
| A3 | A non-breaking `revert:` commit appears under `Reverts` | **executed here** — checks 4b (its failure under ts's array) and 4d |
| A4 | A `chore(deps): …` commit produced under R19's Dependabot configuration produces no changelog line | **executed here** — check 4g |
| A5 | `release-please-config.json` validates against the `$schema` it declares, and the array's `type` values are exactly `commit-message-convention`'s enum, by set equality | **partly executed** — the schema's entry shape is asserted (checks 3h, 9b); set equality between the array and the live registry enum is asserted here (checks 1a–1c). Validating a real config file against the real schema is **P03** |
| A6 | A push containing only hidden-type commits opens no release pull request; a push containing at least one visible-type commit opens one | **partly executed** — release-please's own emptiness predicate is executed over release-please's own rendered bodies (checks 5a–5c). The `return undefined` it guards is read, not driven: end-to-end confirmation is **P03** |

**What P03 must build and prove.** (1) A `release-please release-pr --dry-run`
against a branch seeded with one commit of each of the eleven types, asserting
the rendered body matches run D's section set — the end-to-end form of A1. (2) A
CI assertion that `release-please-config.json` validates against the `$schema` it
declares **and** that the array's `type` values are exactly
`commit-message-convention`'s enum by set equality, so that adding a type to the
linter without adding it here fails a check — A5, and the check that keeps the
two files in sync over the template's life. (3) A regression test on a real
`style!:` commit, because A2's failure mode is silent and cosmetic. (4) A second
dry-run over a branch carrying only `test:`/`ci:`/`chore(deps):` commits,
asserting release-please emits `No user facing commits found since <sha> -
skipping` and proposes no release — A6 end to end, which converts mechanism 5's
remaining read half into an executed one.

**Migration implications.** All additive, all in files other resolved items
already create. (1) `release-please-config.json` — add the eleven-entry array to
the `"."` package object; keep the `$schema` declaration both source
repositories carry. (2) `CHANGELOG.md` — no change from this item; its existence
is F066's and its packaging is already settled, `build-tool-output-shape`'s
`[package] include` allow-list naming `/CHANGELOG.md`. (3) `CONTRIBUTING.md` (or
whichever file carries commit guidance) — **proposed, not required**: say that
`docs:` is for documentation that ships in the crate and that repository-meta
documentation (README, CONTRIBUTING, the port docs) is `chore:`, and carry a
short table of which types appear in the changelog. That is a documentation
convention this item proposes; it is not a change to
`commit-message-convention`'s enum and needs none. (4) No workflow change, no CI
job, no `Cargo.toml` edit, nothing in `Cargo.lock` or the crate graph.

**Runner-up, and the condition under which it wins.** **Inherit the preset
default — `feat`/`fix`/`perf`/`revert` visible — written out as a total eleven-
entry map** so that totality, explicit hidden entries and deliberate order are
kept; that is the recommended array with the `docs` entry moved down and given
`"hidden": true`. It differs from the recommendation **by exactly one boolean**.
It wins if the owner judges the CLI binary and the web service — not the
published library crate — to be the template's primary consumed artifacts, because
the artifact-membership argument for `docs` then loses its subject and
`Documentation` becomes a section two of three readers skip. Note what the same
choice costs under mechanism 5: it also removes documentation's ability to
trigger a release, so a docs-only change waits for the next `feat` or `fix`. For
a CLI-first or service-first template that wait is harmless; for a library it is
the cost the recommendation declines to pay. It wins on a second, independent
condition too: if the template's contributing guidance will **not** distinguish
rustdoc changes from repository-meta changes, the `Documentation` section mixes
shipped and unshipped changes and its signal degrades toward `refactor`'s — which
is why migration item (3) exists. Executed run A is this runner-up's rendering,
and it differs from run D by the absence of `### Documentation` and nothing else
in heading membership (check 4h-no-documentation).

Third place is **py's twelve-entry array**: a total map that gets behaviours 1, 2
and 5 right, but shows `refactor`, which Conventional Commits' own definition
says carries no consumer-visible change, and carries an unreachable `deps` entry;
its `Refactor` heading also departs from release-please's own `Code Refactoring`
for no stated reason. Last is **ts's seven-entry array**, on the executed evidence
in `## Empirical check`. A fifth position — show every type except dependency
bumps, which is git-cliff's shipped default shape — is rejected on Keep a
Changelog's audience test: a changelog that reprints the git log has stopped
selecting, and selection is the only thing a changelog does that `git log` does
not.

**What the recommendation gives up, and the coupling it records rather than
resolves.** Versus the runner-up it gives up the quietest possible default: a
repository whose documentation work is mostly README polish will carry
`Documentation` lines that two of its three reader groups skip. Versus py it
gives up `refactor` visibility, so a large internal restructuring that took a
release cycle produces no changelog line. Versus ts it gives up `test`
visibility, which costs the reader nothing — `tests/` is outside
`build-tool-output-shape`'s `[package] include` allow-list, so integration tests
are not packaged at all, and a `#[cfg(test)] mod tests` inside `src/` ships in
the `.crate` bytes but is never compiled for a dependent. Unconditionally, it
accepts mechanism 5: work of hidden types is invisible *and* unshippable until a
visible-type commit joins it, and the failure mode is silent — release-please
logs `No user facing commits found since <sha> - skipping` and exits 0. That
property belongs to every shape except "show everything" and is not introduced
here, but it creates a coupling this decision records rather than resolves: **the
mapping partly determines release cadence, which is F073's and R25's territory.**
R25 settled `release-type: rust` with both pre-major flags `true` and an empty
manifest and did not consider this guard; nothing in R25's recommendation is
contradicted by it, but P03 should know that the version a hidden-only period
would have produced is never proposed at all.

re-verify: on any of — (1) a change to `commit-message-convention`'s type enum (R38), which makes this answer incomplete rather than merely stale, because the array's membership is defined as that enum; (2) release-please reaching this repository at a major version past v17, or its pinned `conventional-changelog-conventionalcommits` reaching a major past 6, either of which can move the visibility, grouping and ordering behaviour the executed evidence rests on — current pins release-please `17.11.2` (latest release 2026-08-24, check 8a) reached through `googleapis/release-please-action` `v5.0.0`, whose `package.json` requires `release-please` `^17.6.0` (check 8b), and preset `6.1.0` (check 7a); (3) `src/strategies/rust.ts` gaining a `CHANGELOG_SECTIONS` fallback the way `python.ts` has one, which would change the default this recommendation is argued against though not the recommendation itself; (4) R19's Dependabot `commit-message.prefix` moving off `chore`, on which the `deps` answer is conditioned; (5) a decision to replace release-please, currently foreclosed by F063/F066/F073 and ts D-021(3), after which the membership policy ports but the key names do not; and in any case (6) 2027-03-18, six months from this decision.

## Parameters

R24 owns no parameter: its prompt's `## Couplings` carries an empty `- owns:`
line and the `research/CLAUDE.md` row for R24 carries `—` in the `owns` column.
It consumes one, `commit-message-convention` from R38. No consumed value needs to
change, so **no `CONFLICT:` line is emitted.**

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes commit-message-convention = type-enum: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test; header-max-length: 50 (the whole `type(scope): description` line); body-max-line-length: 72; footer-max-line-length: 72; length-semantics: soft-line (the header and every body/footer line are measured up to their last space, so a bare URL or any other un-wrappable final token never violates a cap); bot-exemption: for pull requests opened by dependabot, CI relaxes only the width rules (grammar and type enum stay enforced)

Two notes on how these bear on the decision, kept off the lines above because
the packaging validator reads everything after `= ` as the value. First,
`commit-message-convention` is the whole subject of the recommendation: the
array's membership **is** its `type-enum` field, and check 1a asserts set
equality between that field as the live registry states it and the eleven types
this decision maps. Second, the four fixed parameters bear on this item only
negatively, and that is itself the finding: the mapping is a JSON array in a
configuration file read by a Node program in CI. It adds no crate, so
`msrv-policy` has no subject; it adds no Rust source, so `rust-edition` has no
subject; it is platform-independent JSON-to-Markdown, so `target-os-matrix` is
satisfied trivially; and `license` is not evaluated at all, per the owner ruling
recorded under `## Decision`.

## Empirical check

**Toolchain and host.** No Rust toolchain is involved and none was required:
this item adds no crate and no Rust source, so `rustc --version` and `cargo
--version` have no subject here. Both are recorded in
`review/evidence/toolchain.txt` all the same — at the revision-2 run,
`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1 (797e8a9bc
2026-08-05) (Homebrew)` — and neither is used by any check. The revision-2 run
is on macOS `arm64` (`Darwin 25.4.0`) with `node v26.9.0`, `npm 12.0.1`,
`shellcheck 0.11.0`,
`gh` reading its own keyring credential, and `/usr/bin/grep` —
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` — as the counting binary. The
exact strings are written to `review/evidence/toolchain.txt` rather than to the
log, deliberately: keeping machine-dependent text off stdout is what lets the log
be byte-identical across reruns. That file is rewritten on every run and carries
the run's UTC timestamp, so it is the one committed artifact here that a rerun
modifies; the log is not.

**Working directory.**
`research/runs/R24/2026-09-17T020716Z-071e3bac38a0/review/evidence`.

**Command.**

```bash
bash r24-checks.sh > r24-checks.log 2>&1
```

**Result: exit 0 — 146 assertions, 146 `PASS`, 0 `FAIL`, 0 `SKIP`.** Full output: `review/evidence/r24-checks.log`. The
script is `shellcheck`-clean at 0.11.0 (exit 0, with two documented disables:
`SC2329` on the `EXIT`-trap cleanup function, and `SC2016` on check
9f-r19-cargo-deps-only, whose backticks are literal text in R19's decision). It carries `set -euo pipefail` at
the top, every probe that can be absent runs inside a guarded branch so that a
missing tool prints a named `SKIP` instead of aborting the run, every check
asserts on expected **content** rather than on an exit code alone, and
`/usr/bin/grep` is called by absolute path with its version printed beside every
count it produces. No count in this decision or in the log comes from output
truncated by `head` or `cut`.

**Nothing was built and release-please was never run against a repository.** The
recommendation is a configuration array; what the check executes is the
*rendering code that consumes such an array*, called as a library. There is no
`release-please-config.json` in this repository, no `CHANGELOG.md`, no CI job and
no template scaffold: those are P03's to build.

**What was executed, and how faithfully.** `review/evidence/probe/render.cjs`
calls release-please's own compiled entry points from an install of
`release-please@17.11.2` — `parseConventionalCommits` from `build/src/commit.js`,
`DefaultChangelogNotes.buildNotes` from
`build/src/changelog-notes/default.js`, and `BaseStrategy.prototype.changelogEmpty`
from `build/src/strategies/base.js`. It is **not** a re-typed replica of those
lines; it is those lines, reached through release-please's own API, fed real
Conventional-Commits message strings (`style!: rename the public Error variants`,
`revert: undo the projects list command`, `chore(deps): bump serde …`) rather
than hand-built commit objects. That distinction repairs a defect the registered
report records against its own probe: that report passed `text: ''` for the
breaking-change note and its `⚠ BREAKING CHANGES` bullets rendered empty. Here
they do not — the bullets carry the commit subjects, because
`parseConventionalCommits` assigns the subject as the note text for a bare `!`
(checks 4j-first-bullet, 4j-second-bullet, 4j-no-empty-bullet).

Revision 2 adds `review/evidence/probe/loader.cjs`, which reaches the renderer
the way a repository does rather than by handing `buildNotes` an array. It
calls `Manifest.fromManifest` from `build/src/manifest.js` over an in-memory
GitHub stand-in that serves exactly two files, `release-please-config.json` and
`.release-please-manifest.json`, and makes no network call. It then takes the
Rust strategy from `getStrategiesByPath`, renders the mechanism-5 push through
that strategy's own `buildReleaseNotes`, and applies
`BaseStrategy.prototype.changelogEmpty` to the body. It does this twice: once
with the recommended array and once with the scope-routed entry added. Its two
outputs are `snap/rendered/loader.txt` and
`snap/rendered/G-scope-routed-hidden-only.md`. It does not call
`buildReleasePullRequest`, which needs a repository's `Cargo.toml`.

Six bodies were rendered: four arrays over one fixture (the preset default, py's
twelve entries at its pin, ts's seven at its pin, and the recommendation), plus
the two mechanism-5 pushes. The four heading sets:

| Run | Array | Sections, in rendered order |
|---|---|---|
| A | none — the `release-type: rust` default, and the runner-up | `⚠ BREAKING CHANGES`, `Features`, `Bug Fixes`, `Performance Improvements`, `Reverts`, `Styles`, `Miscellaneous Chores` |
| B | py's twelve entries at pin `b08bccfb` | `⚠ BREAKING CHANGES`, `Features`, `Bug Fixes`, `Performance Improvements`, `Refactor`, `Reverts`, `Miscellaneous`, `Styles` |
| C | ts's seven entries at pin `cb1cbcb2` | `⚠ BREAKING CHANGES`, **`style`**, `Features`, `Bug Fixes`, `Performance Improvements`, `Documentation`, `Tests`, `Code Refactoring`, `Miscellaneous` |
| D | the recommended eleven entries | `⚠ BREAKING CHANGES`, `Features`, `Bug Fixes`, `Performance Improvements`, `Reverts`, `Documentation`, `Styles`, `Miscellaneous Chores` |

**What each section of the log establishes** (section numbers are the log's):

| § | Claim verified | Outcome |
|---|---|---|
| 1a–1c | The recommended array's eleven `type` values equal `commit-message-convention`'s `type-enum` as the live registry states it, as a set; the probe rendered that array in that order; this decision publishes the same eleven in the same order with six `"hidden": true` | PASS ×5 |
| 2 | Each of the five `- assumes` lines is byte-identical to its row in `docs/port/PARAMETERS.md` | PASS ×10 |
| 3a | Mechanism 1 — `config.types = options.changelogSections` replaces, guarded by the key's presence; no concatenation exists; the preset's own `config.types = config.types || [ … ]` is the default | PASS ×4 |
| 3b | Mechanism 4 — `strategies/rust.js` contains 0 `CHANGELOG_SECTIONS` and 0 `filterCommits`, and extends `BaseStrategy` | PASS ×3 |
| 3c | `DEFAULT_CHANGELOG_SECTIONS` is an 11-entry total map with 4 visible and no `deps` entry | PASS ×3 |
| 3d | All eleven section titles the recommendation uses are `DEFAULT_HEADINGS` verbatim | PASS ×11 |
| 3e | Mechanism 5 — the guard reads the rendered notes, logs `No user facing commits found since `, returns `undefined`, and its predicate is `changelogEntry.split('\n').length <= 1` | PASS ×6 |
| 3f | A bare `!` takes its breaking-note text from the commit subject and is pushed only when non-empty | PASS ×2 |
| 3g | Mechanisms 2 and 3 in the preset — the `discard` rule, the two breaking clears, the group rename, the positional order and the `indexOf` sort | PASS ×5 |
| 3h | In `schemas/config.json`, from the first `"changelog-sections"` key to the end of the file: that key occurs twice, `"required": ["type", "section"]` once, `"hidden"` once, and `"scope"` zero times | PASS ×4 |
| 4a–4b | ts's array: `### style` renders above `### Features`, no `### Styles` heading exists, no `### Reverts` section exists, and the revert subject appears 0 times | PASS ×5 |
| 4c–4e | The recommended array: 0 raw lowercase headings, `### Styles` below `### Documentation`, `### Reverts` and its subject present, `### Documentation` present, and the eight headings in exactly the declared order | PASS ×7 |
| 4f | The six non-breaking hidden-type subjects each appear 0 times in run D | PASS ×6 |
| 4g | No run renders `bump serde`, py's included; py's run produces no `### Dependencies` | PASS ×5 |
| 4h–4i | The preset default hides `docs` and shows `revert`; py's array shows `Refactor` and hides `docs` | PASS ×4 |
| 4j | The two breaking bullets carry their commit subjects and 0 empty bullets appear | PASS ×3 |
| 5a–5c | `changelogEmpty` taken off `BaseStrategy.prototype`: an all-hidden push renders a one-line, section-free body and the predicate returns `true`; one `fix:` added makes it `false` and produces `### Bug Fixes` | PASS ×7 |
| 6a–6c | py at `b08bccfb`: 12 entries, array opening at line 22, a `deps` entry, `refactor` visible, `docs` hidden. ts at `cb1cbcb2`: 7 entries, array opening at line 11, and 0 entries for `revert`, `style`, `build`, `ci`. Both snapshots byte-identical to `git show` at the pin | PASS ×13 |
| 7a–7d | A fresh `npm install release-please@17.11.2` resolves `release-please@17.11.2`, `conventional-changelog-conventionalcommits@6.1.0` and `conventional-changelog-writer@6.0.1`; the eight snapshotted upstream files are byte-identical to that install; re-rendering reproduces all seven saved outputs byte-for-byte; re-running the loader probe reproduces its two saved outputs byte-for-byte | PASS ×18 |
| 8a–8b | `v17.11.2` is release-please's latest published release (not a draft, not a prerelease, published 2026-08-24T21:20:30Z); `release-please-action` `v5.0.0` — the action F063 names — declares `"release-please": "^17.6.0"`, which `17.11.2` satisfies | PASS ×6 |
| 9a | The preset's `findTypeEntry` also matches on `scope` when an entry declares one | PASS ×1 |
| 9b | The `"changelog-sections"` property block alone (22 lines): `"required": ["type", "section"]`, no `"scope"` key, no `"additionalProperties"` | PASS ×4 |
| 9c | Through `Manifest.fromManifest`: the recommended strategy holds 11 entries; the scope-routed configuration loads the scoped entry and its strategy holds 12 entries with the scoped entry intact | PASS ×4 |
| 9d | The mechanism-5 push through the loaded strategy: `changelogEmpty` `true` under the recommendation; under scope routing a six-line body, `changelogEmpty` `false`, a `### Dependencies` heading carrying the bump, and `test`/`ci` still absent | PASS ×6 |
| 9e | py's array at pin `b08bccfb` carries no `"scope"` key | PASS ×1 |
| 9f | R19's decision: `prefix: "chore"` twice, `include: "scope"` twice, and the sentence that Cargo scope can only be `deps` | PASS ×3 |

**Endpoints and retrieval dates.** Everything but section 8 comes from the npm
registry: `npm install release-please@17.11.2`, whose package ships both the
compiled sources and `schemas/config.json`, so **no GitHub API call was needed to
read release-please's source or its schema**. Two GitHub REST calls were made by
hand on **2026-09-18 (UTC)**, spaced more than 20 seconds apart, through
keyring-authenticated `gh api`, which reads its own credential; their exact
commands are recorded in `review/evidence/snap/RETRIEVED.txt`, section 8 asserts
on their snapshotted responses, and **the script itself makes no network call
outside section 7's npm install**. The two endpoints:
`GET https://api.github.com/repos/googleapis/release-please/releases/latest` and
`GET https://api.github.com/repos/googleapis/release-please-action/contents/package.json?ref=v5.0.0`.
No token byte was printed, written or committed; no personal email address
appears in any script, log or snapshot. The two source repositories were read
through the programme's pins with `git show`, never from a working tree. Every
snapshot's origin is recorded in `review/evidence/snap/RETRIEVED.txt` with its
retrieval date.

**Reproducibility, stated as a rule after re-running rather than asserted.** For
revision 2 the log was produced after this document's final text was fixed,
then the script was re-run in place and the output compared with `cmp` —
**byte-identical**. Revision 1's log was additionally reproduced from a clean
`git archive HEAD` extraction of commit
`9fce93c43cd66000bf320bb7b7ca1ba74f7a59c6`, which has no `.git` at all; that is
a revision-1 result. Revision 2's new files are not yet committed, so it has
not been repeated for them.

The rule: **the log is byte-identical on any rerun on this host while `./snap/`
is present and `node`, `npm` and the npm registry are reachable.** Two classes of
line can legitimately differ elsewhere, and they are named rather than glossed.
(1) On a host whose `/usr/bin/grep` reports a different `--version` line, every
`PASS` line differs in its trailing `counting binary:` field, because this
decision's brief requires the version beside every count; the verdicts do not
move. (2) Without `node`, `npm` or the network, section 7's eighteen assertions
become four named `SKIP`s — demonstrated below — and the log differs by those
lines alone.

**A named-skip control, so the `SKIP` paths are shown to work rather than
asserted to.** The same script was re-run from the same clean extraction with
`PATH` restricted to `/usr/bin:/bin:/usr/sbin:/sbin`, which removes `node` and
`npm`: `review/evidence/r24-checks-skip-control.log` records 128 `PASS`, **4 named `SKIP`s** and 0 `FAIL` at exit 0, each
naming what was missing (`7a-install`, `7b-upstream-bytes`, `7c-rendered-bytes`,
`7d-loader-bytes` — all four `node is not on PATH`). For revision 2 the control
was re-run in place and compared with `cmp` against the saved log —
**byte-identical**. The exact invocation is:

```bash
PATH=/usr/bin:/bin:/usr/sbin:/sbin bash r24-checks.sh
```

**The scratch directory.** Section 7 creates it with `mktemp -d
"${TMPDIR:-/tmp}/r24.XXXXXX"` and deletes it in an `EXIT` trap. Nothing is
written to the scratchpad root, no `node_modules` tree is committed, and no
nested git repository is created: `npm init -y` writes a `package.json` in the
throwaway directory only, and that directory is gone when the script returns.

**Claims carried from `raw/opus.md` that this check did *not* re-execute**, so
that no reader mistakes them for verified here. Each was retrieved by that report
on 2026-09-18 and is carried at that date. None of them carries the
recommendation: the recommendation rests on sections 1–8 above.

- The crates.io figures for `git-cliff` (90-day 48,133; all-time 339,181;
  2.14.2), `release-plz` (68,423; 359,618; 0.3.168), `cocogitto` (8,299;
  220,766; 7.0.0) and `cargo-release` (16,449; 541,456; 1.1.6). These are
  landscape-bin figures for tools this item does not choose between; the
  changelog generator is inherited under F063/F066/F073.
- `googleapis/release-please`'s `stargazers_count` 7,517, `archived: false`,
  `pushed_at` 2026-09-14, and its open-issue count 300. What *was* re-executed is
  the release pin itself (check 8a).
- The contents of `git-cliff`'s shipped `config/cliff.toml` at `v2.14.2`, which
  is the whole basis for calling "show nearly everything" a live position in the
  Rust field rather than a strawman.
- The docs.rs `/about` quotations behind the artifact-membership premise for
  `docs` ("an open source documentation host for crates of the Rust Programming
  Language"; "All libraries published to crates.io are documented").
- The Cargo publishing reference's statement that Cargo recommends but never
  generates a changelog, and the Conventional Commits 1.0.0 and Keep a Changelog
  1.1.0 texts quoted in the argument.
- `release-please`'s `docs/manifest-releaser.md` pointing its documented default
  at the retired `git.io/JqCZL` shortlink. The default itself **was** re-read,
  from the preset's own `writer-opts.js` (check 3a-preset-default-list) and from
  release-please's `DEFAULT_CHANGELOG_SECTIONS` (checks 3c).
- That `release-plz` and `cocogitto` were named to complete the landscape bin and
  their own default type maps were **not** read — an omission the report states
  and this decision keeps stated.
- From `raw/muse.md`, retrieved by that report on 2026-09-22: that
  `conventional-changelog-conventionalcommits@10.4.0` keeps the `scope` match
  (`src/utils.js:70`); the tokio and clap changelog shapes; release-please's own
  `release-please-config.json` carrying no `changelog-sections`; and the
  rendered sections of py's and ts's `CHANGELOG.md` files, which that report read
  from the working trees rather than at the programme pins. None of them
  selects the recommendation or the rejection of the scope-routed entry.

## Engines

- **Muse — the item's required engine.** `raw/muse.md`, sha256
  `9b8bd88503fc00b0b22d0cc9a22353669af4e636080bba6f0b2c43d9f0e6a9ad`, read in
  full for this revision. At this writing it is on disk but not registered: the
  revision-1 judgment audit records `operations/muse.json` in state
  `submitting` with no `raw_sha256`, and registration is the controller's step,
  not this document's. The same audit records why Muse is required:
  `manifest.json` carries `required_engines: ["muse"]` and a migration event at
  `2026-09-21T23:06:19Z` from `codex` to `muse`, reason "muse bulk substitution
  (owner decision Q5.A 2026-09-21)", and the prompt's `- engines: muse` line is
  authoritative. **Muse's position:** a total, explicit fifteen-entry array over
  R38's eleven types with release-please's `DEFAULT_HEADINGS` titles — `feat`,
  `fix`, `perf`, `refactor`, `revert` visible in that order; dependency bumps
  routed to a visible `Dependencies` section by four scope entries
  (`chore(deps)`, `chore(deps-dev)`, `build(deps)`, `build(deps-dev)`); and
  `docs`, `test`, `build`, `ci`, `style`, `chore` explicitly hidden. Its
  runner-up is the same array with `docs` visible. It executed its cases on
  2026-09-22 through release-please's own `parseConventionalCommits` and
  `buildNotes` at 17.11.2 in a scratch directory. It carries no `CONFLICT:` and
  no `BASELINE-REVIEW:` line.
- **Claude Opus 5.** `raw/opus.md`, sha256
  `70f25e538ae4bf34494ca1202ef653b57b98c9f3c6bf8fa1414d538239be1a75`, registered
  as `raw/opus-70f25e53….md`, 15 H3 fields, validated as a `pattern` answer by
  `validate_answer_text(text, "pattern")` from `scripts/research_validation.py`
  (0 diagnostics). Recommends the total ordered type map adopted above; carries
  no `CONFLICT:` and no `BASELINE-REVIEW:` line.
- **Codex (gpt-5.6-luna) — no longer a required leg; recorded as history.** The
  light-tier Codex research leg failed on the Codex account's usage limit on
  2026-09-17 and produced no report; the `raw/codex-*.txt` files are its timing
  stubs, not evidence, and `raw/codex-transcript.txt` is gitignored. Revision 1
  was written under owner ruling **W1-CODEX3** of 2026-09-18, which says proceed
  without Codex, and recorded the Terra evidence check as unavailable for the
  same reason. Owner decision Q5.A then substituted Muse for Codex on this item,
  as recorded above.

**Where the two reports agree, and this decision with them.** Both recommend a
total, explicit map over R38's eleven types rather than relying on the preset's
default for unmapped types. Both use release-please's `DEFAULT_HEADINGS` titles.
Both show `feat`, `fix`, `perf` and `revert`, and hide `test`, `build`, `ci`,
`style` and `chore`. Both find py's bare `deps` entry dead. Muse reproduced,
independently, the two defects run C shows — an unmapped breaking commit
rendering under a raw lowercase heading above `Features` (for `ci!` and
`style!`), and ts's array dropping a revert-only release to a header-only body —
and the mechanism-5 predicate on a hidden-only push.

**Three disagreements between Muse and this decision, each adjudicated.**

1. **`refactor` — Muse visible, this decision hidden. Hidden stands.** Muse's
   evidence is that both sources show `refactor`, and that py's rendered
   `Refactor` section carries upgrade-relevant entries such as "remove legacy
   py-projects CLI". Removing a command a consumer uses is a breaking change.
   Under `commit-message-convention` it carries `!` or a `BREAKING CHANGE`
   footer, and a breaking commit renders under `⚠ BREAKING CHANGES` and under
   its type's own section heading whatever that entry's `hidden` flag says
   (mechanism 2; executed for `style!:` under a hidden `style` entry in run D,
   checks 4c and 4j). So a hidden `refactor` loses no removal notice that is
   typed correctly; Muse's example argues for typing removals as breaking, not
   for showing every refactor. That both sources show `refactor` is precedent,
   which this programme treats as evidence rather than a winner; Muse itself
   records the cost it accepts, "occasional internal-rename noise", and that is
   the cost this decision declines.
2. **`docs` — Muse hidden, this decision visible. Visible stands.** Muse's
   evidence is that ts's rendered `Documentation` section is port-process
   chatter ("log D-034 model-tier routing", 18 or more entries in ts 0.1.2),
   and that doc-only commits carry no upgrade signal. Muse accepts that Rust
   documentation ships through docs.rs on publish, but does not apply mechanism
   5 to `docs`: with `docs` hidden, a documentation-only period opens no release
   pull request, so corrected rustdoc cannot reach docs.rs until an unrelated
   `feat` or `fix` ships. Muse applies that same mechanism to `revert` and calls
   the result release-suppressing. Muse's noise evidence is
   repository-meta documentation, which is exactly what migration item (3)
   routes to `chore:` and what the runner-up's second winning condition names.
   It therefore strengthens that condition; it does not select the runner-up.
   The two engines are one boolean apart on this row: Muse's own runner-up is
   the `docs`-visible variant.
3. **A `Dependencies` section — Muse visible via four scope routes, this
   decision none. Rejected, after filtering Muse's routes against R19.** Only
   `chore(deps)` is reachable under R19; the single-entry alternative is
   executed and then rejected on the release-cadence effect and behaviour 4,
   with its audience cost stated and the condition under which it wins, all
   under `## Decision`, *Across all three — dependency bumps*.

**What the re-verification found wrong in `raw/muse.md`.** Three corrections,
none of which moves the recommendation:

1. **py's scope routes are not at the programme pin.** Muse describes py's
   array as `release-please-config.json:22-39` with four scope routes, and its
   `### Sources` names the working-tree path
   `/Users/stevemorin/c/py-launch-blueprint/release-please-config.json`. At pin
   `b08bccfb` the array holds twelve entries on lines 23–34 and no `"scope"` key
   (checks 6a, 6c, 9e). The four routes are present in py's working tree at this
   writing (file read 2026-09-28), so Muse's "py's mechanism, executed" is py's
   practice after the pin, not the programme's source evidence. The mechanism
   itself is real, and is executed here (checks 9a–9d).
2. **R19 is decided.** Muse lists R19 as "undecided" and anticipates a
   `build(deps)` shape. R19's published decision (revision 5, 2026-09-15) fixes
   `prefix: "chore"` with `include: "scope"` on both entries (check 9f).
3. **Three of Muse's four routes are unreachable, or not shown reachable, under
   R19.** Both `build(…)` routes are unreachable while the prefix is `chore`;
   `chore(deps-dev)` is unreachable for the `cargo` entry; R19 records nothing
   about `deps-dev` for the `github-actions` entry. Muse calls the extra entries
   "inert … harmless"; they are inert, but carrying configuration that cannot
   fire is the defect this decision already declines in py's bare `deps` entry.

Muse also states that `scope` is schema-valid because entries carry no
`additionalProperties: false`, and that it is undocumented; both agree with
checks 3h and 9b. Muse did not test the config-file loader; checks 9c do.

**What the re-verification found wrong in `raw/opus.md`.** Three corrections,
none of which moves the recommendation:

1. **Fitness gate 1.** The report answers gate 1 **Pass**, reasoning from
   release-please's `Apache-2.0` declaration. Under the owner's ruling of
   2026-09-12 (Q4 as superseded by Q7.B) licence compatibility is not evaluated
   for any dependency or tool, so that evaluation is superseded. This decision
   records the gate as `inapplicable` with the ruling as its reason, and excludes
   nothing on a licence ground.
2. **Two line citations are off by one.** The report cites py's array as
   `release-please-config.json:23-36` and ts's as `:12-20`. Read at the pins by
   this check: py's `"changelog-sections"` key is on line **22** and the array
   closes on line **35**, its twelve entries occupying lines 23–34; ts's key is
   on line **11** and the array closes on line **19**, its seven entries
   occupying lines 12–18 (checks 6a-array-opens-at-22, 6b-array-opens-at-11).
   Both counts of entries — twelve and seven — are correct.
3. **The empty breaking-change bullets are a probe artifact and do not recur.**
   The report records, honestly, that its own probe rendered empty `⚠ BREAKING
   CHANGES` bullets because the fixture passed `text: ''`. Driving
   release-please's own `parseConventionalCommits` with real message strings
   removes the artifact: the bullets carry their commit subjects (checks 4j).
   The report's diagnosis of the cause was right.

**What could not be reproduced, and what was reproduced beyond `raw/opus.md`.** No
claim of that report failed to reproduce. One claim the report stated as read
rather than executed — mechanism 5, that the visible set is the releasable set —
is executed here at the predicate level, with release-please's own
`changelogEmpty` function object taken off `BaseStrategy.prototype` and applied
to bodies its own `buildNotes` produced (checks 5a–5c). The remaining half, that
the guard's `return undefined` is what a caller experiences as "no release pull
request", is read at the call site (checks 3e) and is P03's criterion A6. One
claim the report attributed to `src/changelog-notes.ts` — that the eleven section
titles are release-please's own default headings — was checked at source and is
**correct**: `DEFAULT_HEADINGS` in that file supplies all eleven strings verbatim
(checks 3d), and release-please's separate `DEFAULT_CHANGELOG_SECTIONS` in
`src/util/filter-commits.ts` agrees with every heading it also carries.

**What P03 must validate**, gathered in one place: acceptance criteria A1, A5 and
A6 end to end against a real repository and a real release cycle; the schema-plus-
set-equality CI check that keeps `release-please-config.json` and the commit
linter's type enum in sync; and the `style!:` regression test whose failure mode
is silent. The four items are stated with their commands under `## Decision`,
*What P03 must build and prove*.

**Where the evidence is incomplete.** The landscape figures carried from
`raw/opus.md` (crates.io download counts, star and issue counts, git-cliff's shipped
default, the docs.rs quotations) were not re-retrieved here; they are enumerated
under `## Empirical check` with their retrieval date, and none of them selects
the recommendation. `release-plz`'s and `cocogitto`'s own default type maps were
read by neither `raw/opus.md`, `raw/muse.md` nor this check, so the strength of the
"show-everything" position rests on git-cliff's shipped default alone — carried
at that strength, and it is the position this decision rejects anyway. Muse's
executed scratch runs were not re-run as Muse ran them; the claims this
decision takes from them are re-executed by its own checks, and the rest are
listed as carried under `## Empirical check`. Finally, `raw/opus.md` computed no issue-responsiveness figure for release-please; that
figure would bear on whether to *keep* release-please, which F063/F066/F073 close
as `COMMON → REUSE` and this item's `## Out of scope` excludes.
