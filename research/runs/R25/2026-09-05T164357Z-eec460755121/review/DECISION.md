# R25 — Pre-1.0 semver bump strategy (pattern, Deep) — revision 7, 2026-09-10

## Decision

**Status: this is a proposal to be validated in the implementation phase.** P02 is research
only; the `rs-launch-blueprint` template does not exist yet, and P03 builds it and proves this
recommendation with its own CI. Nothing here has been implemented: no repository was scaffolded,
no release tooling was configured to run, no CI workflow was written. The owner has reviewed R01
only — no owner acceptance of this item is claimed or implied. If this recommendation does not
survive implementation, it is **revised against this recorded research**, not researched again
from scratch; the executed evidence under `## Empirical check` is the baseline any revision argues
against.

**This is revision 7 (2026-09-10).** It corrects **a count and a label**, and changes nothing else in
the argument. The sixth empirical audit
(`review/audit-codex.md`, model gpt-5.6-terra, `review/evidence/audit-r25-r6.log`) **approved**
revision 6 with no findings. The judgment audit that followed (`review/audit-fable.r6.md`, model
claude-opus-5) **endorses the recommendation** — launch at `0.1.0`, `release-type: rust`, both
pre-major flags `true`, manifest created empty — and agrees the controller was right to continue
past the round limit; its single finding is a tally. This decision said in three places that **two**
raw reports emitted `BASELINE-REVIEW:` lines. **Three** did, one each:
`raw/doxa-openai.normalized.md:82`, `raw/doxa-gemini.normalized.md:29` and
`raw/doxa-perplexity.normalized.md:71`. `## Engines` item 7 recorded the third's substance but never
identified it as a `BASELINE-REVIEW:` line, so a controller adjudicating those lines under runbook §4
from this decision's own tally would have checked two and closed on two. Revision 7 makes the four
edits that finding asks for — the count at each of the three locations, and the label on item 7.

It also makes one further clarification, which the judgment auditor asked the controller to
consider, at both places that route the `bootstrap-sha` question away from R25 — the implementation
note under `### Principles and implementation` and unproven item 5 under `## Engines`. Each now names
the ledger row that owns the pin itself, **F071** *release-please bootstrap-sha pin*
(`docs/port/COMMONALITY.md:77`, `ADOPT`, no research item), alongside the F066/R24 routing of
changelog scope that was already there. The auditor's other observation — adjudicating or explicitly
closing doxa-gemini's release-plz proposal against F066 and F073 under runbook §4 — is a controller
filing action outside this document and is not acted on here.

Revision 7 ran no new probe; it re-read raw reports already in this run directory — the three that
emit a `BASELINE-REVIEW:` line and the two that carry that token, colon included, only in the
negative (`## Empirical check`). Before editing, the file was enumerated mechanically rather than re-read, with two patterns
run over **revision 6 of this file**, chosen to cover **counts and labels** rather than the phrase
alone. Pattern 1, the token `BASELINE-REVIEW`, returned six lines: `:349`, `:352`, `:852`, `:895`,
`:980` and `:989`. Pattern 2, a counting word
(*one/two/three/four/five/both/neither/none/all/each*) standing before *raw*, *report*, *engine* or
*doxa*, returned four: `:351`, `:602`, `:932` and `:937`. Their disposition: `:351-352`, `:852` and
`:895` stated the miscount and were corrected; `:349`, `:980` and `:989` were checked and are
correct as written (`:349` denies that *this decision* emits a line, and `:980`/`:989` are the two
`## Engines` items that already carried the label); `:602` (*"Two raw reports invented owned
parameters"*) was checked against `## Engines` item 6 and names exactly doxa-gemini and
doxa-perplexity; `:932` (*"those three Doxa bodies"*) and `:937` (*"All five engines agree"*) were
checked against the engine table above them. Those four are correct and were left untouched.
**Neither pattern could return item 7**, because the defect there was the *absence* of the token: it
was found by walking each `## Engines` item against the three raw lines the grep over `raw/` names,
and the label was added there. That is the auditor's lesson in its exact form — revision 5's sweep
enumerated *version-outcome* assertions and could not reach a count of baseline-review lines, and no
token pattern can reach a missing label, so a mechanical sweep is only as wide as its pattern and
must be closed by an enumeration of the artifacts themselves.
Nothing else moved. Everything the six empirical audits approved — the version outcomes and their
conditioning markers, **Override precedence**, the pre-major boundary phrases, the schema
quotations, the options table, the source-repository history table and the four `- assumes` lines —
was confirmed unchanged by diffing this revision against the revision-6 blob
(sha256 `91ca2e8691aed687715dbec9cacdb90d59558445cc6a5bfa425bd1b4b0c7949e`), not from memory.

**Revision 6 (2026-09-10).** It corrects exactly one supporting sentence and changes nothing
else. Item 2 of *What revision 5 changed* said that **Override precedence** records "the two separate
paths with their two sources apiece". That is wrong, and it contradicted this decision's own correct
statement under **Override precedence**: the paths are asymmetric. The `release-as` value has two
sources — the deprecated `release-as` configuration key and the `--release-as` command-line option —
and the `Release-As:` commit footer has one. The fifth audit
(`review/evidence/audit-r25-r5.log`) confirmed the rest: the revision-5 sweep is complete, with no
unconditioned version outcome left in the file; the two override paths and the footer's second
check-site inside `DefaultVersioningStrategy` are described accurately; every region an earlier audit
approved is untouched, the four `- assumes` lines still matching `docs/port/PARAMETERS.md`
byte-for-byte; and the recommendation is supported. Revision 6 ran no new probe. Before editing, the
file was searched for every location stating how many sources an override path has or characterising
the two paths as parallel; every other such location either names the sources asymmetrically or counts
paths rather than sources, and the one location that asserted symmetry is the one edited.

**Revision 5 (2026-09-10).** Four prior revisions were rejected by empirical audit. Not one
rejection touched the recommendation, and all four are the same defect: **a supporting sentence
stated more absolutely than its evidence.** Revision 1 claimed the TypeScript source repository
"first published v0.1.1" when the evidence showed only a release commit; revision 2 said
release-please merges the release commit when the repository does; revision 3 said a seeded `0.1.0`
makes the first release `0.1.1` when that holds only for some commit histories; revision 4 said the
empty-manifest first version is `0.1.0` "whatever the commits are" when a version override beats
that outcome. Each revision repaired the locations its auditor named and then swept the rest **by
reading**, and each sweep missed something.

Revision 5 changes the sweep method rather than only the sentences. Every location was enumerated
mechanically before a single edit: a regular expression over **revision 4 of this file** matching
version numbers, `first release`, `next release`, `initial`, `manifest`, `propose`, `Release-As`,
`release-as`, `bump`, `→`, `moves the`, `digit`, `yields`, `produces`, `releases`, `released`,
`returns` and `starts at` produced 293 candidate lines; classifying each one for whether it asserts
what version comes out of something produced a work queue of **25 locations carrying 26 such
assertions**, all 25 edited. A **second, block-level pass over the edited file** — flagging any
paragraph or table row containing both a produce-or-result verb and a version literal but not the
marker word — surfaced **3 further locations**, all edited: architecture alternative 1's "pure
function of commit history", the graduation clause under *What (A) gives up*, and revision 4's own
changelog item 3, which claimed a completeness its sweep did not have. **28 locations edited in
total, found by two passes.** Both methods and the exclusions are itemised at the top of
`## Engines`. The exception itself is stated once and in full under **Override precedence** below,
and every one of the 28 locations carries the word *override* in its governing sentence, so the
sweep is re-runnable by either method: search this file for a version-outcome assertion whose
governing sentence lacks that word.

**A second overstatement, corrected in the same revision and found the same way.** Revisions 1-4
said in three places that the reversed gloss of the two flags should be fixed in the binding prompt
*and* in the F070 explanatory prose at `docs/port/COMMONALITY.md:76`. Read directly on 2026-09-10,
that row's explanatory cell reads *"whether rs-launch-blueprint starts pre-1.0
(bump-minor-pre-major/bump-patch-for-minor-pre-major) or post-1.0 like py"* — it names both flags and
glosses neither, so it cannot state their roles in reverse, and `git log` over that file shows the
cell never carried a gloss. **Revision 5 narrows the claim from two documents to one:** the defect is
in the binding prompt alone, at
`research/topics/25-semver-bump-strategy/prompts/semver-bump-strategy.prompt.md` line 28. All three
locations were corrected. This decision edits neither the prompt nor the commonality file.

The recommendation has never changed. Revision 3 rewrote the four `- assumes` lines into the bare
form the packaging validator compares byte-for-byte against `docs/port/PARAMETERS.md`; those lines
are unchanged in revisions 4 and 5 and were not touched by this sweep.

**Recommendation.** `rs-launch-blueprint` launches **pre-1.0 at `0.1.0`** with release-please's
pre-major dampening fully enabled. Three artifacts, and one of them is deliberately empty:

| Artifact | Value | Why this exact value |
|---|---|---|
| `Cargo.toml` → `[package] version` | `"0.1.0"` | What `cargo new` itself emits (executed, cargo 1.98.0) |
| `release-please-config.json` | `"release-type": "rust"`, `"bump-minor-pre-major": true`, `"bump-patch-for-minor-pre-major": true` | The unique flag pair that makes each commit type move the digit Cargo's resolver treats as its compatibility class |
| `.release-please-manifest.json` | created **empty**: `{}` | **Absent a version override** (see **Override precedence** immediately below, which governs both halves of this cell): the **first version release-please releases is `0.1.0`** whatever the commit types are, because with no latest release `BaseStrategy.buildNewVersion` returns `initialReleaseVersion()` without consulting them at all. A seeded `{".": "0.1.0"}` instead makes `0.1.0` the *previous* release, and the next proposed version is then whatever the strategy computes from the commits since — `0.1.1` for a patch-or-feature-only history, `0.2.0` for one containing a breaking change (probe rows *A both true · 0.1.0*). Derived from the tool's source; unproven until P03's first Release PR — see `## Engines`, unproven item 2 |

**Override precedence — the mechanism that outranks every version outcome stated in this decision,
stated once here and referenced everywhere else.** Read at `v17.11.2`,
`BaseStrategy.buildNewVersion` (`src/strategies/base.ts:543-574`) decides a package's next version
by four checks in this order, first match winning:

1. `this.releaseAs`, when set — `return Version.parse(this.releaseAs)` (`base.ts:547-552`);
2. otherwise the newest conventional commit carrying a note titled `RELEASE AS` —
   `return Version.parse(note.text)` (`base.ts:554-564`);
3. otherwise, when a `latestRelease` exists —
   `this.versioningStrategy.bump(latestRelease.tag.version, conventionalCommits)`
   (`base.ts:566-571`);
4. otherwise `this.initialReleaseVersion()` (`base.ts:573`), which `release-type: rust` overrides to
   `0.1.0`.

**Steps 1 and 2 are two separate paths, not one**, and this decision's wording distinguishes them
because they have different sources and different lifetimes:

- the **`release-as` value** of step 1 arrives either from the deprecated `release-as` configuration
  key (`src/manifest.ts:1403`, `releaseAs: config['release-as']`) or from the `--release-as` command
  line option, whose own help text reads *"override the semantically determined release version"*
  (`src/bin/release-please.ts:290-293`) and which `parseConfig` writes over the configuration key for
  every package (`src/manifest.ts:1444-1463`). Set in configuration it persists across runs; passed
  on the command line it applies to that invocation.
- the **`Release-As:` commit footer** of step 2 arrives from a single commit: `src/commit.ts:262`
  lower-cases the footer key and compares it with `release-as`, and lines 282-292 record it as a note
  `{title: 'RELEASE AS', text: <version>}`.

The footer is checked in a **second** place as well. `DefaultVersioningStrategy.determineReleaseType`
returns a `CustomVersionUpdate` for the first commit carrying that note *before* it counts breaking
or feature commits (`src/versioning-strategies/default.ts:74-82`). Step 3 therefore honours the
footer too — and the executed probe under `## Empirical check` drives that strategy directly, so the
probe rows are themselves rows for histories with no such footer. **The consequence, which is why
this paragraph exists: no statement in this decision — about a version release-please releases or
about a bump the strategy computes — is one that a version override cannot falsify.** Every such
statement carries its conditions, and each carries the word *override* pointing back here.

Two limits on how far that reaches. The recommended `release-please-config.json` sets no
`release-as` key, so under the recommendation as written the persistent configuration path is not
live and the override would have to be a commit footer or a command-line argument. And because the
empty manifest makes the first run collect the whole default-branch history (the `bootstrap-sha`
note below), a `Release-As:` footer anywhere in that history — not only on a recent commit — would
fire on the very first Release PR.

Verified first-hand for revision 5 by fetching `src/strategies/base.ts`, `src/commit.ts`,
`src/manifest.ts`, `src/versioning-strategies/default.ts`, `src/bin/release-please.ts` and
`schemas/config.json` at tag `v17.11.2` and reading them; the excerpts are appended to
`review/evidence/release-please-source-v17.11.2.log` on 2026-09-10 as check 8. The fourth audit's
inverse control corroborates the reading rather than proving it: a breaking commit carrying
`Release-As: 0.7.0` selected `0.7.0` (`review/evidence/audit-r25-r4.log`).

**Vocabulary, used exactly and consistently from here on**, because the whole manifest argument
turns on these distinctions and two earlier revisions blurred them. Each term is defined from
release-please's own pinned documentation and source at `v17.11.2`, quoted rather than paraphrased,
because this paragraph is where both earlier precision errors occurred.

- a **Release PR** is the pull request release-please opens and keeps current. README: *"Rather than
  continuously releasing what's landed to your default branch, release-please maintains Release
  PRs"*, and *"These Release PRs are kept up-to-date as additional work is merged."* Its changes
  include `Cargo.toml`, the changelog and `.release-please-manifest.json` —
  `Manifest` pushes an update for `this.manifestPath` onto `releasePullRequest.updates` with
  `createIfMissing: false` (`src/manifest.ts:785-792`), which is why that file must already exist,
  empty, rather than be absent.
- a **release commit** is that Release PR's content once it lands on the default branch. **The merge
  is the repository's act, not release-please's** — README: *"When you're ready to tag a release,
  simply merge the release PR. Both squash-merge and merge commits work with Release PRs."*
- a **tag** is what release-please does *after* that merge. README, listing what happens *"When the
  Release PR is merged"*: *"2. Tags the commit with the version number"*, *"3. Creates a GitHub
  Release based on the tag"*. The tag's spelling follows `include-v-in-tag`, whose schema
  description is *"When tagging a release, include `v` in the tag. Defaults to `true`."*
- a **registry publication** is a version actually served by crates.io (for rs) or npmjs.com (for
  ts). Release-please does not do this at all, and says so: *"It does not handle publication to
  package managers or handle complex branch management."* Its own status-label convention concedes
  the same boundary — `autorelease: published` *"means that a GitHub release has been published
  based on the Release PR (release-please does not automatically add this tag, but we recommend it
  as a convention for publication tooling)"*.

So the division of labour is: **release-please computes the version and prepares the release commit
inside a Release PR; the repository merges that PR; release-please then tags the merged commit and
creates a GitHub release; and something else entirely publishes to a registry** — here ledger rows
F074 (tag/version guard) and F075 (OIDC Trusted Publishing), both `COMMON → REUSE` and both outside
R25. **No claim in this decision infers a registry publication from a release commit or a tag, and
none attributes the merge to release-please.**

Tool under which those keys were read and exercised: **release-please `v17.11.2`**
(`tag_name` from `GET https://api.github.com/repos/googleapis/release-please/releases/latest`, whose
`published_at` field reads `2026-08-24T21:20:30Z` — that is a GitHub release, not a registry
publication; retrieved 2026-09-09), which is the version reached through
`googleapis/release-please-action` `v5.0.0` — its `package.json` declares
`"release-please": "^17.6.0"` (retrieved 2026-09-09). The flag semantics and the executed bump
table below were established at `v17.11.2` only; at `v17.6.0`, the floor of that range, one thing
was checked — that `Rust.initialReleaseVersion()` still returns `0.1.0`.

**Resulting bump table (executed, not asserted), per commit type, for a release carrying no version
override:** from `0.1.z`, `fix:` → patch, non-breaking `feat:` → patch, `feat!:`/`BREAKING CHANGE:`
→ minor. From `1.0.0` and above both flags are inert and ordinary SemVer resumes. A release usually
aggregates several commits, and — again once no commit in the release carries a `Release-As:` footer
and no `release-as` value is in force — the strongest type present wins: `determineReleaseType`
counts breaking commits first, then features, and falls through to a patch bump, so a release
containing one `feat!:` among many `fix:` commits moves the minor digit. Full 36-row output in
`review/evidence/release-please-bump-probe.log`; the override that precedes all of this arithmetic
is **Override precedence** above.

**Ledger rows this settles.** `F070` — *pre-1.0 semver bump strategy*, `docs/port/COMMONALITY.md:76`,
verdict `DIVERGENT`, origin `ts-only`, item `R25`. This decision supplies F070's content: rs adopts
the same low-level flag values ts uses, on Rust's own evidence rather than by inheritance, and py
needs no change. This decision proposes **no change to F070's `DIVERGENT` verdict** and makes no
edit to the ledger; reclassifying the row is not within R25's authority. Rows F063 (version source
of truth), F066 (changelog generation), F072 (auth), F073 (release trigger), F074 (tag/version
guard), F075 (OIDC publishing) and F133 (version-single-sourcing test) are `COMMON → REUSE`, are
assumed by this item per the prompt's `## Out of scope`, and are unaffected by bump arithmetic.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

- *Requirement*: the published version number must tell the consuming package manager's resolver
  the truth about compatibility — a routine dependency update must never silently pull a breaking
  change, and a compatible release must never be withheld behind a number the resolver reads as
  incompatible.
- *Source*: ledger rows F063, F066 and F073 (`COMMON → REUSE`) fix release-please as the sole
  version bumper across py, ts and rs. D-021(1)
  (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`, read from the pinned clone at
  `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`) records the ts instantiation:
  "`package.json` version bumped exclusively by release-please v5.0.0 manifest-mode Release PRs
  (`release-type: node`, `bump-minor-pre-major`, `include-v-in-tag`)".
- *Agreement level*: **capability / standard.** What must agree across the three repositories is
  the capability — an automated bumper whose output is correct under the host ecosystem's own
  compatibility rule. What **may vary** is the flag setting, because each ecosystem's compatibility
  rule is its own and because both flags are unreachable code at `1.0.0` and above
  (`Version.isPreMajor` is `this.major < 1`, so they go inert *at* `1.0.0`, not after it).

**Essential behaviors.** For every release whose version the automation itself decides — that is,
every release carrying no version override (**Override precedence** above), since an override is a
deliberate human act that replaces the computed number and these are requirements on the computation:
1. a commit that breaks the public API moves whichever digit the host resolver treats as the
   incompatibility boundary;
2. a commit that only adds API moves a digit the resolver treats as compatible, so existing
   consumers receive it with no manifest edit;
3. a `fix` moves the smallest digit;
4. the first version the project releases — and therefore the first one it can publish to
   crates.io — is one the ecosystem reads as an accurate stability claim.

**Observable acceptance criteria.** These are the checks P03's CI must make pass; A0–A3 were
proven here against the pinned tool and against `cargo` itself, A4 is a property of the
configuration rather than of a single run.

| # | Criterion | Status in P02 |
|---|---|---|
| A0 | The template's initial `[package] version` equals what a fresh Rust package starts at | **Executed** — `cargo new` emits `version = "0.1.0"` |
| A1 | Given a release with no version override whose commits are `fix:` only, the next version differs only in the patch digit | **Executed** — `0.1.3 → 0.1.4` |
| A2 | Given a release with no version override containing a non-breaking `feat:` and no breaking commit, the next version stays inside the current caret band | **Executed** — `0.1.3 → 0.1.4`; and a bare Cargo requirement `"0.7.0"` locks `axum` to `0.7.9` while `0.8.9` exists |
| A3 | Given a release with no version override containing a `feat!:` / `BREAKING CHANGE:`, the next version leaves the caret band | **Executed** — `0.1.3 → 0.2.0` |
| A4 | No release crosses `0.x → 1.x` without an explicit human act | **Argued from source, not executed end to end** — under both flags `true`, from any pre-1.0 baseline, no commit type produces `1.0.0`; reaching `1.0.0` takes a version override, which is exactly the explicit human act the criterion demands: a `Release-As: 1.0.0` commit footer (the documented route), or the deprecated `release-as` configuration key, or a `--release-as 1.0.0` argument (**Override precedence** above). P03 proves it on the real repository |

**Cargo's compatibility rule, quoted rather than paraphrased.** The Cargo Book's SemVer reference
states: *"This guide uses the terms 'major' and 'minor' assuming this relates to a '1.0.0' release
or later. Initial development releases starting with '0.y.z' can treat changes in 'y' as a major
release, and 'z' as a minor release. '0.0.z' releases are always major changes. This is because
Cargo uses the convention that only changes in the left-most non-zero component are considered
incompatible."* (`https://doc.rust-lang.org/cargo/reference/semver.html`, retrieved 2026-09-09.)
*Specifying Dependencies* states the resolver side: *"Versions are considered compatible if their
left-most non-zero major/minor/patch component is the same. This is different from SemVer which
considers all pre-1.0.0 packages to be incompatible."*, with the worked bands
`0.2.3 := >=0.2.3, <0.3.0` and `0.0.3 := >=0.0.3, <0.0.4`, and *"Caret requirements are the default
version requirement strategy."* (same URL, retrieved 2026-09-09).

**Attribution, stated precisely.** The `0.y`-as-major rule recommended here is **Cargo's own stated
convention, and it departs from Semantic Versioning 2.0.0** — the Cargo Book says so in the sentence
quoted above. semver.org grants no compatibility band below 1.0.0 at all: *"Major version zero
(0.y.z) is for initial development. Anything MAY change at any time. The public API SHOULD NOT be
considered stable. Version 1.0.0 defines the public API."* (`https://semver.org/`, item 4, retrieved
2026-09-09). Nothing in this decision is derived from the SemVer specification; every version-shape
claim below is derived from Cargo's documented convention, from Cargo's observed resolver behavior,
or from the Rust API Guidelines, and each is labeled with which.

Map the four essential behaviors onto Cargo's rule at a `0.y.z` version and the required table — for
the releases the automation decides, so again no version override in force (**Override precedence**
above) — is
`fix → z`, non-breaking `feat → z`, breaking `→ y`. That is exactly `bump-minor-pre-major: true`
**and** `bump-patch-for-minor-pre-major: true`. The correspondence is arithmetic, not stylistic,
and `review/evidence/release-please-bump-probe.log` shows that no other flag combination produces
it.

**Correction to the binding prompt's gloss of the two flags — confirmed independently at the pinned
version.** The prompt's `## Questions` (line 28) glosses the flags as "feat commits bump the minor
digit, not major; fix commits bump patch even under a `0.x` minor". That reverses them. Read at
`v17.11.2` (`review/evidence/release-please-source-v17.11.2.log`):

- `bump-minor-pre-major` — schema description, verbatim: *"Breaking changes only bump semver minor
  if version < 1.0.0"*.
- `bump-patch-for-minor-pre-major` — schema description, verbatim: *"Feature changes only bump
  semver patch if version < 1.0.0"*.
- `docs/manifest-releaser.md` agrees in prose (*"BREAKING CHANGE only bumps semver minor if version
  < 1.0.0"*, *"feat commits bump semver patch instead of minor if version < 1.0.0"*), and adds
  *"absence defaults to false"* for both.
- The implementation agrees: `DefaultVersioningStrategy.determineReleaseType`
  (`src/versioning-strategies/default.ts`) first walks the commits for a `RELEASE AS` note and
  returns a `CustomVersionUpdate` if it finds one — the override path, lines 74-82, which reaches no
  flag at all — and only then branches on `breaking > 0`
  (`version.isPreMajor && this.bumpMinorPreMajor` → `MinorVersionUpdate`, else
  `MajorVersionUpdate`), then on `features > 0`
  (`version.isPreMajor && this.bumpPatchForMinorPreMajor` → `PatchVersionUpdate`, else
  `MinorVersionUpdate`), and otherwise returns `PatchVersionUpdate`. `isPreMajor` is
  `this.major < 1` (`src/version.ts:86-88`). So `fix` always moves the patch digit; the flags govern
  breaking commits and `feat` commits respectively; both are inert once the major digit reaches 1.

The prompt's gloss describes option (D) in the table below — `bump-minor-pre-major` alone — which is
measurably wrong under Cargo's rule. **The error should be corrected at its source, and that source
is one document, not two.** It is the binding prompt, at
`research/topics/25-semver-bump-strategy/prompts/semver-bump-strategy.prompt.md` line 28 (reached in
this run as `inputs/prompt.md`); this decision does not edit it. Revisions 1-4 also named
`docs/port/COMMONALITY.md:76`, and that was wrong: read directly, the F070 row's explanatory cell
reads *"whether rs-launch-blueprint starts pre-1.0
(bump-minor-pre-major/bump-patch-for-minor-pre-major) or post-1.0 like py"*. It names the two flags
and glosses neither, so it cannot state their roles in reverse, and `git log` over that file shows
the cell has carried that same wording since the row was written (only its `Item` column changed,
`R27` → `R25`). Retrieved and read 2026-09-10.

**Are both flags supported identically for `rust` as for `node`? Yes — the MEDIUM question,
answered from source.** `src/manifest.ts:1395-1396` maps `config['bump-minor-pre-major']` →
`bumpMinorPreMajor` and `config['bump-patch-for-minor-pre-major']` → `bumpPatchForMinorPreMajor`;
lines 1748-1752 let a per-package value fall back to the top-level default. The flags belong to
`DefaultVersioningStrategy`, which the versioning-strategy factory builds for the `default`
versioning type and which `BaseStrategy` installs unless a language strategy overrides
`versioningStrategy` (`base.ts:138-140`). `src/strategies/rust.ts` declares
`export class Rust extends BaseStrategy` and contains **zero** occurrences of `versioningStrategy`
(`grep` returned no match, exit 1 — appended to the source log), so it inherits the default. Nothing
about the two flags is Node-specific.

**Cargo's `0.x` interpretation versus npm's — the second HIGH question.** Arithmetically the two
compatibility bands are the same (npm's caret range for `^0.2.3` is `>=0.2.3 <0.3.0-0`), so ts's
choice does not need re-deriving on arithmetic grounds. Two differences are real and both push Rust
*harder* toward the dampening, not away from it. First, Cargo makes the `0.y`-as-major reading
**normative in its own reference** and reachable through the default, bare requirement syntax — a
consumer who writes `rs-launch-blueprint = "0.1"`, the idiomatic spelling, is inside
`>=0.1.0, <0.2.0` whether or not they thought about ranges. Second, Rust tooling builds on the rule
and enforces it: release-plz, an independently built Rust-native release tool, documents the
contrary setting as a violation. Its `features_always_increment_minor` field reads: *"If `true`,
feature commits will always bump the minor version, even in 0.x releases. If `false` (default),
feature commits will only bump the minor version starting with 1.x releases."*, carrying the warning
*"This option violates the Cargo SemVer rules because the transition from `0.x` to `0.(x+1)` is used
for breaking changes. Instead, new features for `0.x` should bump the version from `0.x.y` to
`0.x.(y+1)`."* (`https://raw.githubusercontent.com/release-plz/release-plz/main/website/docs/config.md`,
retrieved 2026-09-09). release-plz's default is `bump-patch-for-minor-pre-major: true` by another
name. Two independently built tools, one policy.

**What must agree across py, ts and rs, and what may vary — the third HIGH question.** The principle
(truthful compatibility signalling) is preserved in all three at capability/standard level, and the
apparent divergence F070 records is not drift:

- **py has no flags because they cannot fire.** py adopted release-please already post-1.0: the
  commit that added its manifest, `1bd0344`, wrote `{".": "1.0.0"}` (pinned clone `b08bccf`), and
  its config contains zero occurrences of `pre-major`. Every branch those flags guard is gated on
  `version.isPreMajor`, i.e. `major < 1`. py's absence of the keys is inherited state, not a design
  decision and not accidental drift; adding them would change nothing.
- **ts has both flags because it launched pre-1.0 under the same `0.x` band.** Its config sets both
  (pinned clone `cb1cbcb`); its manifest reads `{".": "0.1.3"}`.
- **rs is in ts's starting position, in an ecosystem where the pre-major rule is stronger.** The same
  low-level value is therefore recommended for rs, and it is recommended on Cargo's documented
  convention and observed resolver behavior, not by inheritance from ts. That satisfies the owner's
  A5 test for recommending a shared low-level value: the evidence supports the same tradeoff in both
  ecosystems independently.

**A defect in the recorded ts rationale, for the follow-on project.** D-021(1)'s decision text names
only `bump-minor-pre-major`, while ts's shipped `release-please-config.json` sets both flags. The
one-flag configuration is a materially different policy (option D below), so the ts decision record
understates what ts actually does. This is a documentation gap in ts, not a fitness finding about
rs, and no change to ts is made here.

**No `BASELINE-REVIEW:` finding is emitted by this decision.** F070 is `DIVERGENT`, not a retained
`COMMON → REUSE` or `ADOPT` baseline row, so there is no baseline to challenge; and the analysis
confirms rather than contradicts the principle behind F063/F066/F073. Three raw reports did emit
`BASELINE-REVIEW:` lines — `raw/doxa-openai.normalized.md:82`, `raw/doxa-gemini.normalized.md:29`
and `raw/doxa-perplexity.normalized.md:71`, handled under `## Engines` as items 5, 4 and 7
respectively, and none is adopted.

**Architecture alternatives compared, before any flag was chosen.**

1. *Commit-derived automated bump with ecosystem-aware pre-major dampening.* The version is a
   function of commit history plus a policy declared in configuration — pure in the commit history
   except where a version override displaces it (**Override precedence** above), which is the
   deliberate escape hatch rather than a leak in the model. Integration cost: two JSON
   booleans. Dependability: machine-enforced on every release, so it cannot drift with maintainer
   attention. Its residual risk is that it trusts the commit message — a breaking change mislabelled
   `feat:` ships as a patch bump.
2. *Commit-derived automated bump with no dampening, launched at `1.0.0`.* The same machine with the
   pre-major branch never taken. Correct by construction — but only because it asserts a stable
   public API before any code exists. That is a claim about the code, not about the tooling.
3. *API-diff-derived bump* (release-plz driving `cargo-semver-checks`): the tool compares the
   compiled public API against the previous release and bumps on what actually changed. Strictly
   more accurate; strictly more machinery and a second release tool. **Out of scope to adopt** — the
   release tool is fixed by F063/F066/F073 and this prompt's `## Out of scope` — but its *policy* is
   admissible evidence, and its checker can be added as a CI gate without changing the release tool.

Architecture 1 is selected. Adding `cargo-semver-checks` as a pull-request gate is **proposed, not
decided here**: it recovers most of architecture 3's accuracy at CI cost only, but its job placement
belongs to R11 (`ci-job-structure`) and this decision does not claim that slot.

**The options, separated empirically.** Executed 2026-09-09 against `release-please@17.11.2`
installed into the session scratchpad, driving `DefaultVersioningStrategy` directly. Cell format is
the resulting version. No probe commit carried a `Release-As:` footer and no `release-as` value was
supplied, so every cell below is the no-override outcome for its row (**Override precedence**
above); had a probe commit carried the footer, that strategy would have returned the footer's
version instead of any cell shown here.

| # | Option | `0.1.3` + `fix:` | + `feat:` | + `feat!:` | `1.0.0` + `fix:` | + `feat:` | + `feat!:` |
|---|---|---|---|---|---|---|---|
| **A** | **both flags `true` — recommended** | 0.1.4 | 0.1.4 | **0.2.0** | 1.0.1 | 1.1.0 | 2.0.0 |
| B | start `1.0.0`, no flags | — | — | — | 1.0.1 | 1.1.0 | 2.0.0 |
| C | start `0.1.0`, neither flag (raw defaults) | 0.1.4 | **0.2.0** | **1.0.0** | 1.0.1 | 1.1.0 | 2.0.0 |
| D | `bump-minor-pre-major` only (what the prompt's gloss describes) | 0.1.4 | **0.2.0** | 0.2.0 | 1.0.1 | 1.1.0 | 2.0.0 |
| E | `bump-patch-for-minor-pre-major` only | 0.1.4 | 0.1.4 | **1.0.0** | 1.0.1 | 1.1.0 | 2.0.0 |

Reading the bold cells against Cargo's rule, stating each as the general case rather than as the one
row that demonstrates it, and carrying the same no-override condition the table's cells carry
(**Override precedence** above) into both readings: under (C) and (E), from any pre-1.0 baseline, the *first release
containing a breaking change silently promotes the crate to `1.0.0`* — an irreversible stability
claim made by a bot. Under (C) and (D), from a `0.y.z` baseline, a release whose strongest commit is
a *non-breaking* `feat` produces `0.(y+1).0` — `0.2.0` in the demonstrated `0.1.3` row — which every
Cargo consumer of the `0.y` band reads as incompatible: the crate withholds a compatible release and forces a manifest edit across
its consumers for no reason. Only (A) satisfies A1–A4. Option (B) is arithmetically correct — at
`1.0.0` and above every configuration behaves identically, as the right-hand columns show — so its
cost is not arithmetic but the claim it makes on day one.

**Why the manifest is created empty, and what the first released version therefore is.** This is
the artifact the raw reports left unsettled, and it is what the prompt's value test names — the
prompt's words are "the template's first-published version number", and the part of that this item
controls is which version release-please *releases* first. Read at `v17.11.2`:

- `BaseStrategy.buildNewVersion` (`src/strategies/base.ts:543-574`) reaches
  `this.initialReleaseVersion()` **last, and only when the three checks before it all fall
  through**: a `release-as` value at `base.ts:547`, then a `RELEASE AS` commit note at
  `base.ts:554-564` — the two override paths of **Override precedence** above — and then a
  `latestRelease`, whose presence sends it to `this.versioningStrategy.bump(...)` at
  `base.ts:566-571` instead. Only with no override and no latest release does line 573 return
  `this.initialReleaseVersion()`.
- `Manifest` backfills that latest release *from the manifest file*: the block commented
  `// backfill latest release tags from manifest` treats `this.releasedVersions[path]` as the latest
  release whenever it is present and is not the sentinel `'0.0.0'`. The maintainers' docs say the
  same in prose: seeding `{"path/to/pkg": "1.1.1"}` means *"release-please will now use '1.1.1' as
  the last-released/current version"*.
- `Rust.initialReleaseVersion()` returns `Version.parse('0.1.0')` — at `v17.11.2` **and** at
  `v17.6.0`. `BaseStrategy.initialReleaseVersion()` returns `1.0.0` unless the `initial-version` key
  is set; `python.ts` also overrides to `0.1.0`; `node.ts` has no override and so inherits `1.0.0`.

Two consequences, and the asymmetry between them is the whole argument. First, **`release-type:
rust` starts a brand-new crate at `0.1.0` with no seeding, no `initial-version` key and no
hand-written manifest entry** — the seeding ts had to do is a `node` problem, not a Rust one. This
first consequence is unconditional **in the commit types**, and conditional on nothing else being in
force: with no latest release, `buildNewVersion` returns `initialReleaseVersion()` before any commit
type is examined, so `0.1.0` is proposed whatever landed — given at least one releasable commit, and
given no version override, meaning no `release-as` value from the configuration key or the
`--release-as` argument and no `Release-As:` commit footer anywhere in the collected history
(**Override precedence** above). Those two overrides are checked *before* the missing latest release
is, so they beat this outcome rather than merely competing with it.

Second, **seeding `{".": "0.1.0"}` makes `0.1.0` the *previous* release rather than the next one, so
with no version override in force the first proposed version is never `0.1.0` — and which version it
is then depends on the commits since the seed.** Under the recommended flags the probe gives both
answers from a `0.1.0` baseline: a patch-or-feature-only history yields `0.1.1`, and a history
containing a breaking change yields `0.2.0` (`evidence/release-please-bump-probe.log`, rows
*A both true · 0.1.0*: `fix:` → `0.1.1`, `feat:` → `0.1.1`, `feat!:` → `0.2.0`). An override displaces
both answers (**Override precedence** above). How far that goes — whether an override can name a
version release-please has already released — is **not** settled by what was read here:
`buildNewVersion` performs no such comparison at `base.ts:547` or `base.ts:554-564`, but nothing read
establishes what the surrounding pipeline does with a repeat, and the only recorded evidence in that
direction is the maintainers' warning quoted under the runner-up below, that a standing `release-as`
makes subsequent runs keep proposing the same version. Revision 3 wrote `0.1.1` unconditionally;
that is true only of the first of those histories,
and it is the claim the third audit rejected.

That second consequence is an inference **from the tool's source**, and the source is its only
authority: `BaseStrategy.buildNewVersion` plus `Manifest`'s backfill block, quoted above — the
narrow proven premise being that a manifest entry is the package's *last-released/current* version,
which the strategy then bumps from according to the conventional commits it finds. The ts
repository corroborates it, and revision 1 overstated what that corroboration is. What ts's history
actually establishes, each item checked separately in
`review/evidence/ts-registry-publication-check.log` (executed 2026-09-10):

| Event | What ts shows | What it proves |
|---|---|---|
| Manifest seed | commit `19ff9b5` wrote `{".": "0.1.0"}` | the seed existed |
| First **release commit** after the seed | `bdc7567`, `chore(release): publish v0.1.1` | release-please's first release skipped the seeded number |
| **Tags** in the pinned clone | `ts-launch-blueprint-v0.1.1`, `v0.1.2`, `v0.1.3` — no `v0.1.0` | no tag was ever cut for the seeded number |
| **Registry publication** on npmjs.com | the name resolves (HTTP 200) with exactly two versions, `0.0.1` (2026-07-21, published by the user account `smorin`, no `repository` field) and `0.1.3` (2026-07-22, published by `GitHub Actions` through a trusted publisher). `npm view ts-launch-blueprint@0.1.1 …` exits 1 with `E404` | ts **never published `0.1.0`, `0.1.1` or `0.1.2`**. Its first pipeline publication was `0.1.3` |

So the corroboration is this and only this: ts seeded `0.1.0`, and its first release commit and tag
were `v0.1.1` — the seeded number never became a release commit, a tag, **or** a registry version.
That is consistent with the source reading. It is **not** evidence that ts "published `0.1.1`" — it
did not — and the divergence between ts's tags and its registry has a recorded cause unrelated to
bump arithmetic: D-021(5) shipped ts's publish workflow "inert-but-ready until the consumer
configures the npmjs.com trusted publisher" (pinned clone `cb1cbcb`). Nothing about npm's registry
is carried over to crates.io here.

If `0.1.0` is to be the first version released, the manifest must be created empty
(`echo "{}" > .release-please-manifest.json`, the maintainers' own bootstrap instruction — the file
has to exist because the manifest updater runs with `createIfMissing: false`) and `Cargo.toml` left
at `0.1.0`. Release-please then **opens a Release PR proposing `0.1.0`** — proposed on the strength
of there being no latest release, so it does not depend on which commit types landed, and equally on
there being no version override, without which condition the proposal is whatever the override names
(**Override precedence** above) — whose changes include
writing `{".": "0.1.0"}` into the manifest; **the repository merges that PR**; and release-please
then tags the merged commit, in whatever form `include-v-in-tag` produces, and creates a GitHub
release. Whether that release reaches crates.io is F075's business, not this item's, and P03 proves
the released number at the first Release PR (`## Engines`, unproven item 2).

*Implementation note that travels with the empty manifest, flagged rather than decided here:* with
no manifest entry, the first Release PR *"will collect all the commits (in the history of the
default/configured branch) to parse out conventional commits for changelog generation"*
(`docs/manifest-releaser.md`, v17.11.2). The documented control is a top-level `"bootstrap-sha"` key, which py already uses
(`b08bccf`). The pin itself is owned by ledger row **F071**, *release-please bootstrap-sha pin*
(`docs/port/COMMONALITY.md:77`, `ADOPT`, no research item, *"mechanical: pin the commit
release-please starts scanning from when first configured"*); what the resulting first changelog
contains is F066/R24 territory. Neither is R25's; P03 should set the pin deliberately when it wires
the first release.

**Fit for this template, per shape.**

- *Library (crates.io-published) — the binding case.* A published library's version is a
  machine-readable promise to code the maintainer will never see, and the template's three shapes
  share one version number, so the strictest shape governs. The Rust API Guidelines' C-STABLE item
  states: *"A crate cannot be stable (>=1.0.0) without all of its public dependencies being stable.
  Public dependencies are crates from which types are used in the public API of the current crate."*
  (`rust-lang/api-guidelines`, `src/necessities.md`, retrieved 2026-09-09). This is a guidelines
  checklist item — a Rust Library Team publication — not a toolchain rule, and it is cited as such.
  Its force here is that the template's likely public surface includes crates that are themselves
  pre-1.0 (`axum` 0.8.9, `tower` 0.5.3, `tracing` 0.1.44, `config` 0.15.25 — `crate.max_stable_version`
  from `GET https://crates.io/api/v1/crates/<name>`, retrieved 2026-09-09), and R53, R55, R58, R67
  and R69 have not yet chosen them. A `1.0.0` launch would make a claim the guidelines say the crate
  is not entitled to make, on evidence that does not exist yet.
- *CLI (installed binary).* Weakest constraint. A binary's consumer does not write a version
  requirement at all — `cargo install` takes an optional `--version <VERSION>` ("Specify a version to
  install", `cargo install --help`, cargo 1.98.0), so pinning is opt-in rather than the caret band
  the library case turns on — and users read release notes rather than version arithmetic. Neither
  option harms this shape. One point for `0.1.0`: in a single-version workspace the CLI's `--version` string and
  the library's version are the same string, so the CLI should not be the surface making a stability
  promise on the library's behalf.
- *Web service (optional feature-gated surface).* A feature-gated HTTP surface built on pre-1.0
  dependencies inherits their churn: an `axum` `0.8 → 0.9` bump is, by Cargo's rule, a breaking
  change, and where those types reach the template's public API it is breaking for the template too.
  Under (A), and absent a version override on the release (**Override precedence** above), that
  propagates as `0.y.z → 0.(y+1).0` — `0.1.z → 0.2.0` at the launch version —
  accurate and cheap. Under (B) the same routine upstream bump forces `1.x → 2.0.0`, and the next
  one `2.x → 3.0.0`, driving the major digit up for reasons unrelated to the
  template's own design. This is the strongest practical argument against (B), and it is specific to
  a Rust web stack; ts faced nothing equivalent.

**Ranked runner-up, and the condition under which it wins.** Option (B) — launch at `1.0.0` with
ordinary SemVer, py's present shape. It requires a deliberate act to reach that number — the
`"initial-version": "1.0.0"` key, hand seeding the manifest, or one of the two version overrides of
**Override precedence** above — because with no latest release and no such act, `release-type: rust`
starts at `0.1.0`. It is a runner-up rather than a
rejected option because at `1.0.0` and above its arithmetic is identical to (A)'s; its whole cost is the
claim it makes on day one. It wins only if, **before first publication**, all of the following hold:
R04's public-API enforcement is wired and the curated surface is final; no crate appearing in that
public surface is itself pre-1.0 (C-STABLE); the web surface's dependency churn is walled off behind
private types; and the owner accepts that every subsequent breaking change costs a whole major
digit. The practical reconciliation is to take (A) now and reach (B)'s position later with a
`Release-As: 1.0.0` commit footer — the maintainers document the syntax
(*"When a commit to the main branch has `Release-As: x.x.x` (case insensitive) in the **commit
body**, Release Please will open a new pull request for the specified version"*, `README.md`,
v17.11.2). In the running flow the footer is honoured by `BaseStrategy.buildNewVersion` at
`base.ts:554-564`, before the latest release is even consulted; `DefaultVersioningStrategy` honours
the same note again at `default.ts:74-82` before any flag branch, so the override holds on both
paths (**Override precedence** above). No config change is needed, and both flags become inert
automatically once `major >= 1`. The deprecated `release-as`
**config key** is the inferior route to the same override: the schema marks it *"[DEPRECATED] …
Consider using a `Release-As` commit instead"*, and the docs warn that leaving it in place makes
subsequent runs keep proposing the same version.

**What (A) gives up.** Versus (B): the stability signal. Some risk-averse consumers and some
corporate policies treat `0.x` as experimental. That cost is accepted because a false `1.0.0`
followed by an early `2.0.0` is more damaging than honest pre-1.0 iteration, because `0.x` carries
no visible adoption penalty in Rust (four of the six widely-adopted crates sampled above are
pre-1.0, several with nine-figure all-time download counts), and because pre-1.0 is the recoverable
direction — graduation is one override commit footer away, retreat from `1.0.0` is not. Versus (C)/(D)/(E): the
familiar teaching that `feat` bumps the minor digit. That cost is accepted because under Cargo's
rule a `0.x` minor bump *is* an incompatibility signal, and the translation happens in CI where no
contributor has to think about it. The residual risk (A) does not remove is a breaking change
mislabelled `feat:` shipping as a patch bump; the proposed `cargo-semver-checks` pull-request gate
is the answer to it, and it is proposed, not proven.

**Reference implementations cited.** ts-launch-blueprint practices the npm equivalent of exactly
this flag pair (pinned clone `cb1cbcb`). release-plz ships this policy as its Rust-native default and
documents the opposite as a Cargo SemVer violation. `axum`, `tracing`, `tower` and `config` are
maintained, heavily adopted crates that keep breaking changes on the `y` digit while pre-1.0.
release-please itself is **active** by the prompt's rubric: latest GitHub release `v17.11.2`,
`published_at` 2026-08-24, repository `pushed_at` 2026-09-03, `archived: false`, `license.spdx_id` `Apache-2.0`,
297 open issues (`GET https://api.github.com/search/issues?q=repo:googleapis/release-please+is:issue+is:open`,
retrieved 2026-09-09). No release-drought trigger fires. Issue responsiveness (median days to first
maintainer response over the 10 most recently opened issues) was **not measured** — recorded as an
unmet evidence requirement, not estimated.

**Fitness gates.** All six gates in the prompt's `## Required evidence` are written for crate
candidates. R25 is a `pattern` item whose candidates are configuration policies: adopting any of
them adds **zero** entries to `[dependencies]` or `[dev-dependencies]`, and release-please runs as a
Node GitHub Action, never in the built artifact or its dependency tree. Each gate is therefore
recorded as `inapplicable` with its reason rather than omitted, and **no candidate is excluded by
any gate**. (1) *License* — inapplicable; no crate enters the tree. For completeness,
`googleapis/release-please` is `Apache-2.0` (`license.spdx_id`, retrieved 2026-09-09). (2) *MSRV* —
inapplicable; a version string has no MSRV and does not constrain `rust-version`. (3) *RustSec /
`unsafe`* — inapplicable to a version-number policy, which has no code. (4) *`ubuntu-latest,
macos-latest`* — inapplicable as written, nothing is built; version arithmetic is platform
independent and release-please runs wherever the workflow's `runs-on` puts it. (5)
*Default features / async coupling* — inapplicable; the two flags are JSON booleans that default to
`false` when absent. (6) *Binary size and compile time* — inapplicable and measurably zero: the
decision changes only the `[package] version` string, which reaches the binary at most through the
compile-time `CARGO_PKG_VERSION` variable. The one tool this decision *proposes* (rather than
decides) for CI, `cargo-semver-checks`, was **not** gated here and was **not** executed on either
required runner; that is listed under `## Engines` as work for P03.

re-verify: before P03 cuts the first release (run the end-to-end `release-please release-pr --dry-run` against a scratch repository), or on any release-please major version past v17 reaching this repository through `googleapis/release-please-action`, whichever comes first.

## Parameters

- owns: none
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

Each `- assumes` line above carries the registry value bare and byte-identical to
`docs/port/PARAMETERS.md`, with no backticks, citation or commentary on the line itself. The notes
that used to sit on those lines are here instead, none of them lost.

**Ownership.** R25 owns no entry in `docs/port/PARAMETERS.md`: the binding prompt's `## Couplings`
`- owns:` line is empty and `research/CLAUDE.md`'s R25 row records `—` in the `owns` column. This
item's output is consumed as ledger row F070's content, not as a registry parameter. Two raw reports
invented owned parameters; that is corrected under `## Engines`.

**Why each assumed parameter is unaffected.** All four are owner-fixed (`docs/port/PARAMETERS.md`,
owner decisions of 2026-09-02).

- `msrv-policy` — the recommendation adds no crate and touches no `rust-version` key.
- `rust-edition` — the edition is independent of the version field. (`cargo new` on cargo 1.98.0
  emitted `edition = "2024"`, executed 2026-09-09.)
- `target-os-matrix` — version arithmetic is platform independent. The one *proposed* CI addition,
  `cargo-semver-checks`, would have to run on both runners; it was not executed on either here, and
  that is recorded as an evidence gap.
- `license` — no dependency is introduced, so no license-compatibility question arises.

**Assumed from the ledger rather than from the registry**, per the prompt's `## Out of scope`:
release-please is the release tool and `Cargo.toml`'s `[package] version` is the version source of
truth (F063, F066, F073, all `COMMON → REUSE`).

**No `CONFLICT:` line is raised.** The prompt's `## Couplings` lists no `consumes:` entries, no
consumed parameter needs to change, and none of the four owner-fixed values is contradicted.

## Empirical check

Toolchain and host, recorded per the role contract (`review/evidence/toolchain.log`):

```
rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
macOS 26.4 (build 25E246), Darwin arm64
node v26.5.0, npm 12.0.1
```

**Nothing was implemented.** No template was scaffolded, no release tooling was configured to run,
no CI workflow was written, and nothing was created inside the repository worktree. Every command
below ran in the session scratchpad
(`/private/tmp/claude-501/.../scratchpad`, abbreviated `<scratch>`) except the read-only toolchain
and repository reads. All eight checks in the table below exited `0` **except check 7's first
command, whose non-zero exit is itself the result** — `npm view ts-launch-blueprint@0.1.1` exits 1
with `E404`, which is what the check was run to find out. All HTTP fetches returned `200` except
where a status is quoted otherwise. Retrieval date: **2026-09-09** for checks 1–6, **2026-09-10**
for check 7 (added in revision 2) and for check 8 (added in revision 5). Check 8 verifies a claim
about the tool's ordering and implements nothing; its output was **appended** to the existing
`evidence/release-please-source-v17.11.2.log` under a dated banner rather than replacing it, and no
other evidence log was changed. **Revision 6 ran no new probe.** On **2026-09-10** it appended one
further dated entry to that same log, recording that check 8's captured excerpts were re-read at the
pin to confirm the source mapping of the two override paths — two sources for the `release-as` value,
one for the `Release-As:` commit footer — with no new fetch and no other log altered.

**Revision 7 ran no new probe either.** On **2026-09-10** it appended one further dated entry to that
same `evidence/release-please-source-v17.11.2.log`, under the banner *"which raw reports emitted a
`BASELINE-REVIEW:` line"*. The entry records the one pipeline it ran — `grep -n 'BASELINE-REVIEW'
"$f" | sed 's/^/#   /' | cut -c1-200`, once for each of `raw/doxa-openai.normalized.md`,
`raw/doxa-gemini.normalized.md`, `raw/doxa-perplexity.normalized.md`, `raw/codex.md` and
`raw/opus.md`, in this run directory — and its output as captured, each line carrying the `#   `
prefix and cut at 200 columns. That is a read of static files already inside this run directory, not a source
fetch: nothing was fetched, installed or executed against a network endpoint, which is why it is
appended to the existing log rather than opening a new check. The finding: **three** raws emit a
`BASELINE-REVIEW:` line, one each, at `raw/doxa-openai.normalized.md:82`,
`raw/doxa-gemini.normalized.md:29` and `raw/doxa-perplexity.normalized.md:71`; `raw/codex.md:26` and
`raw/opus.md:124` carry `BASELINE-REVIEW:` only in the negative (*"No `BASELINE-REVIEW:` line is
emitted"*). The grep's two remaining `raw/opus.md` hits, `:192` and `:389`, are not that token at
all: they name the file `docs/port/BASELINE-REVIEW.md`, which has no trailing colon. The colon is
what distinguishes an emitted finding from a reference to the ledger's baseline-review file. Because the inputs are static files that do
not drift, the appended output is reproducible byte-for-byte, and it was re-run and diffed against
the appended block before this sentence was written. No other evidence log was changed and no check
was re-run.

| # | What it decides | Command (working directory) | Result | Log |
|---|---|---|---|---|
| 1 | Toolchain and OS of record | `rustc --version`; `cargo --version`; `sw_vers`; `uname -sm` (repository worktree, read-only) | as quoted above; exit 0 | `evidence/toolchain.log` |
| 2 | What the two flags actually do, whether they are Rust-specific, and what a fresh Rust crate's initial version is | `curl -sS -A <ua> https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/<path>` for 10 paths, plus `v17.6.0/src/strategies/rust.ts` and `release-please-action/v5.0.0/package.json` (`<scratch>/rp-src`) | all `200`; schema, docs and implementation agree, and all three contradict the prompt's gloss; `Rust.initialReleaseVersion()` → `0.1.0` at both tags; action `v5.0.0` depends on `release-please ^17.6.0`; exit 0 | `evidence/release-please-source-v17.11.2.log` |
| 3 | Which flag combination produces the table Cargo's rule requires | `npm --prefix <scratch>/rp-probe install release-please@17.11.2` then `node <scratch>/rp-probe/probe.cjs` — 4 configurations × 3 start versions × 3 commit types, no probe commit carrying a `Release-As:` footer | 36 rows; with no version override in any row, only both-flags-`true` gives `fix→z`, `feat→z`, `feat!→y` at `0.x`; exit 0 | `evidence/release-please-bump-probe.log` |
| 4 | Cargo's own initial version, and whether a `0.y` minor bump really is the incompatibility boundary | `cargo new --lib/--bin --vcs none`; then `cargo generate-lockfile` on three throwaway manifests (`<scratch>`) | `version = "0.1.0"`, `edition = "2024"`; `bitflags = "0.9.0"` → `0.9.1` while `2.13.2` exists; `axum = "0.7.0"` → `0.7.9` while `0.8.9` exists; `bitflags = "1.0.0"` → `1.3.2`, never `2.x`; exit 0 | `evidence/cargo-initial-version-and-resolver.log` |
| 5 | That every rule attributed to a standard or tool is quoted from a source that covers that case | `curl -sSL` of Cargo Book `semver.html` and `specifying-dependencies.html`, `semver.org`, `rust-lang/api-guidelines` `necessities.md`, release-plz `config.md` (`<scratch>/docs`) | all `200`; the five verbatim quotations reproduced in `### Principles and implementation`; exit 0 | `evidence/authority-quotations.log` |
| 6 | Maintenance state, adoption figures, and the two source repositories at their pinned commits | `GET api.github.com/repos/...`, `GET api.github.com/search/issues?...`, `GET crates.io/api/v1/crates/<name>` (6 crates); `git -C ~/c/{ts,py}-launch-blueprint show <pinned sha>:<path>` | release-please `v17.11.2` / `pushed_at` 2026-09-03 / `archived: false` / 297 open issues; ts seeded `0.1.0` and its first release commit was `v0.1.1`; py adopted release-please at `1.0.0` and sets no `pre-major` key; exit 0 | `evidence/registry-and-source-repos.log` (see the correction appended at its foot, and check 7) |
| 7 | **Added in revision 2.** Whether ts's `v0.1.1` was a release commit, a tag, or a registry publication — three different things | `npm view ts-launch-blueprint@0.1.1 …`; `npm view ts-launch-blueprint versions …` (isolated cache); `curl https://registry.npmjs.org/ts-launch-blueprint`; `git tag --list`; `git log` (`<scratch>`) | release commit `bdc7567` and tag `ts-launch-blueprint-v0.1.1` exist; npm serves only `0.0.1` and `0.1.3`, and `@0.1.1` exits 1 with `E404`; `0.1.0` appears in none of the three | `evidence/ts-registry-publication-check.log` |
| 8 | **Added in revision 5.** Where a version override is checked relative to `latestRelease` and `initialReleaseVersion()`, and whether the deprecated configuration and the commit footer are one path or two | `curl -sS -A <ua> https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/<path>` for `src/strategies/base.ts`, `src/commit.ts`, `src/manifest.ts`, `src/versioning-strategies/default.ts`, `src/bin/release-please.ts`, `schemas/config.json` (`<scratch>/rp`), then read at the pinned line ranges | all `200`; `buildNewVersion` checks `this.releaseAs` (`base.ts:547`), then a `RELEASE AS` commit note (`554-564`), then `latestRelease` (`566-571`), then `initialReleaseVersion()` (`573`) — **two separate override paths**, both ahead of the last two checks; the footer is honoured a second time inside `DefaultVersioningStrategy.determineReleaseType` (`default.ts:74-82`), so check 3's probe is subject to it too; exit 0 | `evidence/release-please-source-v17.11.2.log` (appended section dated 2026-09-10) |

**The one method caveat.** Check 3 imports `release-please/build/src/versioning-strategies/default`
and `.../version` — package-internal build paths, not a public API. A future release may relocate
them. That is a durability caveat on the method, not on the result: check 2 read the same logic from
the pinned TypeScript source independently, and the two agree.

**Deliberately not run, because running it would be implementing rather than researching:** the
end-to-end `npx release-please@17.11.2 release-pr --repo-url=<owner>/<repo> --dry-run` against a
real scratch repository (it needs a GitHub token and a throwaway repository), and
`cargo-semver-checks` on `ubuntu-latest` and `macos-latest`. Both are listed under `## Engines` as
P03's work.

## Engines

**Audit of revision 4, and what revision 5 changed.** Revision 4
(sha256 `5a744eb02d24894777e7d795a95e4f54defaf6f0afddb61ede654aa1254643d4`) was **rejected** by
`audit-codex-2026-09-05T164357Z-eec460755121-r4` (`review/audit-codex.r4.md`, model gpt-5.6-terra)
on one finding, and **confirmed** on everything else it checked.

- *Rejected by the audit — an outcome asserted as if nothing could override it.* Revision 4 stated
  the `Release-As` exception at one location and asserted an empty-manifest or seeded outcome without
  it at six others. The auditor's inverse control selected `0.7.0` for a breaking commit carrying a
  `Release-As: 0.7.0` footer. **The finding is correct**, and I verified its mechanism first-hand
  rather than adopting it: check 8 reads `src/strategies/base.ts:543-574` at `v17.11.2` and confirms
  the ordering the auditor named, with `this.releaseAs` at line 547 and the `RELEASE AS` commit note
  at 554-564 both preceding the `latestRelease` check at 566 and `initialReleaseVersion()` at 573.
- *Two things the source read added that the finding did not name.* First, the deprecated
  configuration and the commit footer are **two separate paths**, not one, and the `release-as` value
  has a second source besides the configuration key — the `--release-as` command-line option, which
  `parseConfig` writes over the key for every package (`manifest.ts:1444-1463`,
  `bin/release-please.ts:290-293`). The decision's wording now matches that. Second, and more
  consequential for the sweep, the footer is honoured **again** inside
  `DefaultVersioningStrategy.determineReleaseType` (`default.ts:74-82`) before any flag branch. That
  removes the tempting escape hatch that statements scoped to the versioning strategy are exempt:
  check 3's probe drives that strategy directly and is itself subject to the footer. Every
  version-outcome statement in this decision therefore carries the condition.
- *Confirmed by the audit, and unchanged in revision 5.* All 36 version outcomes against their named
  starting versions, flag configurations and commit histories; the aggregation rule; the two
  pre-major boundary phrases against `Version.isPreMajor` (`this.major < 1`); and the four
  `- assumes` lines byte-for-byte against `docs/port/PARAMETERS.md`. None of those lines was
  reworded. The `- assumes` lines were re-checked against the registry after the edits and are
  unchanged.

**Mechanism this decision depends on, recorded here because it was implicit for four revisions.**
The version override described under **Override precedence** in `## Decision` is a mechanism of the
recommended tool, not a caveat about it: `release-type: rust` plus an empty manifest yields `0.1.0`
only for a history in which neither override path fires. It is recorded as a *dependency* rather
than an unproven item because it was read from the pinned source (check 8), and as corroboration the
r4 auditor's independent inverse control produced `0.7.0` from a `Release-As: 0.7.0` footer
(`review/evidence/audit-r25-r4.log`). What stays unproven is the same thing as before — the
end-to-end first Release PR — now with the override condition attached to it in unproven item 2.

**What revision 5 changed, and nothing else.** The recommendation (launch at `0.1.0`,
`release-type: rust`, both flags `true`, empty manifest), the vocabulary and division of labour, the
registry finding, the parameter lines, checks 1-7 and their logs, and the unproven list all stand as
written. Checks 1-7 were not re-run and no existing evidence log content was altered; check 8's
output was appended to `evidence/release-please-source-v17.11.2.log` under a dated banner on
2026-09-10. The edits are:

1. **the sweep method changed, because reading the document four times had failed four times.**
   Locations were enumerated mechanically before any edit, over revision 4 of this file: a regular
   expression matching version
   numbers, `first release`, `next release`, `initial`, `manifest`, `propose`, `Release-As`,
   `release-as`, `bump`, `→`, `moves the`, `digit`, `yields`, `produces`, `releases`, `released`,
   `returns` and `starts at` matched **293 lines**; classifying each for whether it asserts what
   version comes out of something produced a queue of **25 locations carrying 26 assertions**;
   **all 25 were edited**; the same enumeration was re-run against the edited file and every queued
   location was confirmed to carry its conditions. A **second pass with a different method** then ran
   over the edited file — block-level rather than line-level, flagging any paragraph or table row
   holding a produce-or-result verb (`propose`, `releases`, `produces`, `yields`, `returns`, `bumps`,
   `moves`, `starts at`, `gives`, `selected`, `forcing`) together with a version literal but not the
   marker word. It surfaced **3 locations the line-level queue had not**: architecture alternative 1
   ("the version is a pure function of commit history"), the graduation clause in *What (A) gives
   up*, and item 3 of revision 4's own changelog, which asserted a completeness that revision's sweep
   did not have. All 3 were edited, for **28 in total**. That pass's other 19 flags were reviewed
   individually and left alone as correct: verbatim quotations, `cargo new` and resolver facts that
   are not release-please outcomes, ts's observed release history, the historical audit records, and
   the options-table rows, which are governed by the marked preamble directly above them.
   Explicitly excluded, and why: the two
   `isPreMajor` phrases and the schema quotations (audit-confirmed, and a quotation may not be
   edited), the four `- assumes` lines (byte-compared), the options-table cell values and probe
   citations (governed by their preamble), the ts history table (observed events, not predicted
   outcomes), and the historical revision records except where one restates the defect;
2. **the exception stated once and in full** as **Override precedence** in `## Decision` — the
   four-step order in `buildNewVersion` with pinned line numbers, the two separate paths with their
   asymmetric sources — two for the `release-as` value (the deprecated configuration key and the
   `--release-as` option), one for the `Release-As:` commit footer — the second check-site inside
   `DefaultVersioningStrategy`, and the two limits
   on its reach (the recommended config sets no `release-as` key; the empty manifest makes a footer
   anywhere in the scanned history fire on the first Release PR). Every one of the 25 locations
   carries the word *override* in its governing sentence, which is what makes the sweep re-runnable
   by an auditor;
3. **three wrong-actor statements corrected**, all found by the enumeration rather than reported by
   the audit: the `determineReleaseType` description omitted the `RELEASE AS` short-circuit that
   precedes its breaking/feature count; the runner-up paragraph credited `DefaultVersioningStrategy`
   with honouring the footer "before any other decision" when `BaseStrategy.buildNewVersion` acts
   first in the running flow; and `## Engines` item 3 said "the strategy already returns `0.1.0`"
   when the value comes from `buildNewVersion` returning `Rust.initialReleaseVersion()`;
4. **the prompt-defect claim narrowed from two documents to one.** Revisions 1-4 said the reversed
   flag gloss should be fixed in the binding prompt *and* in the F070 explanatory prose at
   `docs/port/COMMONALITY.md:76`. Read directly on 2026-09-10, that cell reads *"whether
   rs-launch-blueprint starts pre-1.0 (bump-minor-pre-major/bump-patch-for-minor-pre-major) or
   post-1.0 like py"*: it names both flags and glosses neither, so it cannot state their roles in
   reverse, and `git log` shows the cell never carried a gloss (only its `Item` column changed,
   `R27` → `R25`). The defect is in the binding prompt alone, at
   `research/topics/25-semver-bump-strategy/prompts/semver-bump-strategy.prompt.md` line 28. Three
   locations carried the overstated version and all three were corrected, including `## Engines`
   item 5, which had mis-restated doxa-openai's conditional request (*"correct any wording that
   says…"*) as an assertion about that file's contents. Neither the prompt nor the commonality file
   is edited by this decision. This is the same failure mode as the `Release-As` finding — a claim
   propagated to more locations than the evidence supports — and it was found the same way;
5. **check 8 added**, run by me rather than taken from the audit, and appended rather than
   overwriting: it reads the six pinned files that establish the override ordering and the two
   paths.

**Audit of revision 3, and what revision 4 changed.** Revision 3
(sha256 `23d42766b5319c95de680b50dc20334332243e66079eab5f0b981b02c6df9fbd`) was **rejected** by
`audit-codex-2026-09-05T164357Z-eec460755121-r3` (`review/audit-codex.r3.md`, model gpt-5.6-terra)
on one finding, and **confirmed** on the repair the previous round had made.

- *Confirmed by the audit.* "The vocabulary and division of labour are now accurate. The pinned
  README says release-please maintains Release PRs, tells the repository to merge one, then tags the
  commit." The audit's rerun also matched this decision on the manifest-existence claim, the
  `bootstrap-sha` claim, the 36-row bump table and the four `- assumes` lines. All of that stands
  unchanged in revision 4.
- *Rejected by the audit — an overstated consequence.* Revision 3 said in three places that seeding
  `{".": "0.1.0"}` makes the first release or Release PR `0.1.1`. The proven premise is narrower: a
  manifest entry is the package's last-released/current version, which `Manifest` backfills as
  `latestRelease` and `BaseStrategy.buildNewVersion` then bumps according to the *subsequent*
  commits. My own probe carries the counterexample — from `0.1.0` with both recommended flags,
  `feat!:` yields `0.2.0`, not `0.1.1`. The finding is correct, and it is the third consecutive
  rejection of the same shape: right mechanism, right recommendation, a number stated as though it
  were unconditional.

**What revision 4 changed, and nothing else.** The recommendation (launch at `0.1.0`,
`release-type: rust`, both flags `true`, empty manifest), the confirmed prompt correction, the
corrected vocabulary and division of labour, the registry finding, the parameter lines, all seven
checks and their logs, and the unproven list all stand as written. No evidence log was changed and
no check was re-run — the counterexample was already in
`evidence/release-please-bump-probe.log`, which is precisely why revision 3 should not have made the
claim. The edits are:

1. the three rejected locations — the recommendation table's manifest cell, the "Two consequences"
   passage, and `## Engines` item 2 — rewritten to say the seed makes `0.1.0` the *previous*
   release and that the next proposed version depends on the commits since, citing probe rows
   *A both true · 0.1.0* for both outcomes (`0.1.1` on a patch-or-feature-only history, `0.2.0` on
   one containing a breaking change);
2. the **asymmetry stated explicitly**, because it is the actual argument for the empty manifest:
   with no latest release, `buildNewVersion` returns `initialReleaseVersion()` *before* examining
   any commit type, so `0.1.0` is proposed whatever landed; with a seed, the outcome is
   commit-dependent. One branch is unconditional in the commit types and the other is not, and
   revision 3 blurred that. (Revision 4 wrote that asymmetry without the version-override condition
   that governs both branches, which is the defect revision 5 repairs — see **Override precedence**
   in `## Decision`;)
3. a sweep of every other sentence stating a version number or bump outcome, each marked as holding
   for all histories or given the condition under which it holds. **That sweep was done by reading
   and was incomplete** — it conditioned outcomes on the commit history while omitting the version
   override that precedes the history entirely, which is the fourth audit's finding and what
   revision 5 re-swept mechanically. What it did reach: the per-commit-type
   bump summary gained the aggregation rule (`determineReleaseType` takes the strongest type
   present), acceptance criteria A1–A4 name the release's commit mix rather than a lone commit, the
   (C)/(D)/(E) readings are stated in general form (`0.(y+1).0`) with the demonstrated row named as
   the example, the runner-up's `initial-version` override is conditioned on there being no latest
   release, and unproven item 1's `0.1.1 → 0.1.2 → 0.2.0` sequence names the one history that
   produces it and states what batching the same commits differently would give instead.

**Audit of revision 2, and what revision 3 changed.** Revision 2
(sha256 `9dfb724a0c4a90b5cea05fbd387ddaa79da8428bf3aaffbd0f61180d6b256c14`) was **rejected** by
`audit-codex-2026-09-05T164357Z-eec460755121-r2` (`review/audit-codex.r2.md`, model gpt-5.6-terra)
on one finding, and **confirmed** on five.

- *Rejected by the audit — the merge actor.* Revision 2's new vocabulary paragraph defined a release
  commit as one *"release-please merges to the default branch"*. Release-please does not merge
  anything. Its pinned README says it *"maintains Release PRs"* and instructs the reader: *"When
  you're ready to tag a release, simply merge the release PR."* Only after that merge does
  release-please act — *"2. Tags the commit with the version number"*, *"3. Creates a GitHub Release
  based on the tag"*. The finding is correct, and it is the second consecutive precision error in
  this same paragraph, so revision 3 rebuilt the paragraph rather than patching the sentence: every
  term is now defined by a quotation from the pinned README, schema or source, and the division of
  labour is stated explicitly (release-please proposes and tags; the repository merges; something
  else publishes).
- *Confirmed by the audit.* The registry finding and the corrected registry passages (findings 2 and
  3); the empty-manifest recommendation as source-grounded at `v17.11.2` (finding 4); the binding
  prompt's reversed flag gloss (finding 5); and R25's empty `owns`/`consumes` scope (finding 6). The
  audit reran the checks in an isolated scratch area — Cargo checks on a Linux VM at `rustc`/`cargo`
  1.98.1, the Node probe and the npm query on macOS — and reports that the substantive source,
  arithmetic, Cargo and registry output matches this decision. All of that stands unchanged in
  revision 3.

**What revision 3 changed, and nothing else.** The recommendation (launch at `0.1.0`,
`release-type: rust`, both flags `true`, empty manifest), the confirmed prompt correction and its
evidence, the registry check and its finding that ts never published `0.1.0`, `0.1.1` or `0.1.2`,
the three recorded-but-not-adopted `BASELINE-REVIEW:` lines, all seven checks and their logs, and the
unproven list all stand as written. No evidence log was changed and no check was re-run. The edits
are:

1. the **vocabulary paragraph rebuilt** from the pinned README, schema and source, with the merge
   attributed to the repository, tagging attributed to release-please, and publication attributed to
   neither — plus a new *Release PR* term, since the release commit's content is prepared there;
2. the sentence describing what happens after an empty manifest reworded to the same division of
   labour, and extended with the source fact that makes the empty file necessary: the manifest
   updater runs with `createIfMissing: false` (`src/manifest.ts:785-792`), so the file must exist
   rather than be absent;
3. one further tool-behaviour sentence corrected in the fitness gates: release-please "runs on
   whichever GitHub-hosted runner the workflow picks" became "runs wherever the workflow's `runs-on`
   puts it", because a self-hosted runner is equally possible and nothing in the sources says
   otherwise;
4. **the four `- assumes` lines rewritten into the bare form the packaging validator compares
   byte-for-byte against `docs/port/PARAMETERS.md`** — no backticks around the parameter name or the
   value, no citation and no commentary after the value. The values were copied out of the registry
   table programmatically rather than retyped, and re-verified character by character after the
   edit. The `- owns` line was checked for the same defect and reduced to `- owns: none`, which
   carries no `= ` at all. Every note those lines used to carry is preserved in prose immediately
   below the list; none was dropped.

**Audit of revision 1, and what revision 2 changed.** Revision 1
(sha256 `75d8edd839ae6ad7f69004a4e7947cd43c6d8af73414f81215f876a5a8dc7fc0`) was **rejected** by
`audit-codex-2026-09-05T164357Z-eec460755121` (`review/audit-codex.r1.md`, model gpt-5.6-terra) on
one finding, and **confirmed** on the load-bearing one.

- *Confirmed by the audit.* The correction to the binding prompt holds: at `v17.11.2` the schema
  makes `bump-minor-pre-major` govern **breaking** changes and `bump-patch-for-minor-pre-major`
  govern **feature** changes, `src/versioning-strategies/default.ts` uses exactly that branch order,
  and the executed probe reproduces `fix`/`feat` → patch and `feat!` → minor at `0.x`. The audit
  also reproduced checks 2–6 independently (a Linux rerun on `rustc`/`cargo` 1.98.1, with the
  Node-dependent check 3 on macOS) and confirmed that each cited log supports the claims it is cited
  for. That evidence is unchanged in revision 2.
- *Rejected by the audit.* Revision 1 asserted that ts "first published v0.1.1" and that `0.1.0`
  "was never published". `review/evidence/registry-and-source-repos.log` supports only a release
  commit and a tag; the audit found `npm view ts-launch-blueprint@0.1.1 version dist.tarball --json`
  returns `E404`. The finding is correct: a release commit is not a tag and neither is a registry
  publication.

**What revision 2 changed, and nothing else.** The recommendation (launch at `0.1.0`,
`release-type: rust`, both flags `true`, empty manifest), the confirmed prompt correction and its
evidence, the three recorded-but-not-adopted `BASELINE-REVIEW:` lines, checks 1–6 and their logs, and
the unproven list all stand as written. The edits are:

1. a **vocabulary paragraph** in `## Decision` defining release commit / tag / registry publication
   and stating that no claim here infers one from another;
2. every statement that ts *published* a version replaced by the narrower proven fact — its first
   **release commit and tag** were `v0.1.1` after a manifest seed of `0.1.0` — with an explicit note
   of which inference that supports (the source-level reading of the manifest backfill) and which it
   cannot (anything about a registry);
3. **check 7 added**, run by me rather than taken from the audit: it separates the three events and
   records what npmjs.com actually serves;
4. the maintenance-state figure relabelled as a GitHub release's `published_at`, and essential
   behavior 4, the manifest-section heading, the check-6 row, `## Engines` item 2 and unproven item 2
   reworded from "published" to "released" where that is what the evidence supports;
5. unproven item 2 extended so it cannot be read as contradicting the recommendation: what P03
   proves is the *released* number, and reaching crates.io is separately unproven and claimed
   nowhere above.

**A finding of my own, beyond what the audit reported.** The audit checked `@0.1.1` only. Querying
the whole packument shows npmjs.com serves `ts-launch-blueprint` (HTTP 200) with exactly two
versions — `0.0.1`, published 2026-07-21 by the user account `smorin` with no `repository` field,
and `0.1.3`, published 2026-07-22 by `GitHub Actions` through a trusted publisher — so ts's first
*pipeline* publication was `0.1.3`, and `0.1.0`, `0.1.1` and `0.1.2` were never published at all.
The cause is recorded in ts's own decision record and is unrelated to bump arithmetic: D-021(5)
shipped its publish workflow "inert-but-ready until the consumer configures the npmjs.com trusted
publisher". This strengthens rather than weakens the corroboration — `0.1.0` is absent from all
three of ts's release commits, tags and registry versions — while confirming the audit's point that
none of it proves a publication.

| Engine | Report | Recommendation |
|---|---|---|
| codex (gpt-5.6-terra) | `raw/codex.md` | `0.1.0`, `release-type: rust`, both flags `true` |
| opus (claude-opus-5[1m]) | `raw/opus.md` | `0.1.0`, `release-type: rust`, both flags `true` |
| doxa · openai | `raw/doxa-openai.normalized.md` | `0.1.0`, `release-type: rust`, both flags `true`, plus a bootstrap-only `release-as: 0.1.0` |
| doxa · gemini | `raw/doxa-gemini.normalized.md` | `0.1.0` with dampening — but proposes replacing release-please with release-plz |
| doxa · perplexity | `raw/doxa-perplexity.normalized.md` | `0.1.0`, both flags `true` |

`raw/doxa.normalized.md` is those three Doxa bodies regrouped per template field, with the repairs
recorded in `doxa/normalization.json`; `raw/doxa-perplexity.normalized.md` lacks the *Up-and-comers*,
*Ranked runner-up* and *Confidence & re-verify trigger* fields, so no perplexity evidence was
available for those three positions.

**All five engines agree on the outcome**: launch at `0.1.0` with both pre-major flags `true`. The
disagreements are about the mechanism and the paperwork, and each was settled by reading the pinned
tool source rather than by counting votes.

1. **The binding prompt's gloss of the two flags is wrong — confirmed independently, first-hand.**
   codex, opus and doxa-openai each flagged it; doxa-gemini and doxa-perplexity used the correct
   semantics without noting the discrepancy. I did not take any of them on trust: I fetched
   `schemas/config.json`, `docs/manifest-releaser.md`, `src/versioning-strategies/default.ts` and
   `src/version.ts` at tag `v17.11.2` and read them (check 2), then reproduced the resulting
   arithmetic by driving `release-please@17.11.2` itself (check 3). The schema's own words are
   *"Breaking changes only bump semver minor if version < 1.0.0"* and *"Feature changes only bump
   semver patch if version < 1.0.0"* — the reverse of the prompt's line 28. The prompt's gloss
   describes option (D), which the executed table shows is wrong under Cargo's rule. **The error is
   on the record here and should be fixed at its one source** — the binding prompt at
   `research/topics/25-semver-bump-strategy/prompts/semver-bump-strategy.prompt.md` line 28, reached
   in this run as `inputs/prompt.md`; this decision does not edit it. Revision 5 removed
   `docs/port/COMMONALITY.md:76` from this sentence: the F070 cell names both flags and glosses
   neither, so the defect is not there (read 2026-09-10; see the correction in
   `### Principles and implementation`).
2. **How the first released version is actually produced — a correction to the opus report, which
   no engine got fully right.** opus's migration table recommends seeding
   `.release-please-manifest.json` as `{".": "0.1.0"}` *and* relies on
   `Rust.initialReleaseVersion()` returning `0.1.0`. Those do not compose. `src/manifest.ts`'s
   "backfill latest release tags from manifest" block treats a manifest entry as the *last released*
   version, and `docs/manifest-releaser.md` says the same in prose, so a seeded `0.1.0` becomes the
   previous release and, with no version override in force (**Override precedence** in
   `## Decision`), the first Release PR proposes whatever the strategy computes from the
   commits since — `0.1.1` on a patch-or-feature-only history, `0.2.0` on one with a breaking change
   (probe rows *A both true · 0.1.0*). **The proof is the source; ts's history is corroboration
   only** — it seeded `0.1.0` at `19ff9b5`, and on its actual commit history its first release
   commit and tag were `v0.1.1`, with the seeded number appearing as neither. Revision 1 wrote that ts "first published v0.1.1"; it did
   not, and that overstatement is finding 1 of the audit recorded below. This decision therefore
   creates the manifest **empty**, so that on a history carrying no version override the first
   version released is `0.1.0`.
3. **doxa-openai's bootstrap-only `release-as: 0.1.0` is not adopted.** It solves the same worry a
   different way, but the schema marks the `release-as` config key *"[DEPRECATED] … Consider using a
   `Release-As` commit instead"* and the docs warn that leaving it in place makes subsequent runs
   keep proposing the same version. With `release-type: rust` and an empty manifest it is
   unnecessary, and the actor is worth naming precisely: the version does not come from the
   versioning strategy at all but from `BaseStrategy.buildNewVersion` returning
   `Rust.initialReleaseVersion()` (`base.ts:573`), which is `0.1.0`. Adopting doxa-openai's key would
   put a standing override ahead of that return (`base.ts:547`) — the first step of **Override
   precedence** in `## Decision` — and so would replace a correct computed result with a pinned one.
4. **doxa-gemini's `BASELINE-REVIEW: F066, F073 — replace release-please with release-plz` is
   recorded and not adopted.** The binding prompt's `## Out of scope` states that whether the
   template uses release-please at all is settled by F063, F066 and F073 (`COMMON → REUSE`) and that
   R25 decides only the bump semantics within it. The proposal is therefore outside this item's
   authority; no ledger row is touched. Its *evidence* is used, however, and it is good evidence:
   release-plz's documented default equals `bump-patch-for-minor-pre-major: true`, and it labels the
   contrary setting a violation of Cargo's SemVer rules — an independent Rust-native tool reaching
   the same policy. If the owner wants the release-tool choice reopened, that is a new item, not a
   revision of this one.
5. **doxa-openai's `BASELINE-REVIEW: F070` is really the flag-gloss correction, restated.** Quoted
   exactly, it asks to *"correct any wording that says 'feat bumps minor' when both flags are true to
   'breaking bumps minor; feat and fix bump patch'"* — a conditional request about wording wherever
   it occurs, which revisions 1-4 mis-restated as an assertion that F070's own explanatory prose says
   it. It does not: the F070 cell names both flags and glosses neither (read 2026-09-10). The wording
   doxa-openai describes occurs in the binding prompt, which is item 1 above. It is not a baseline
   review in the ledger's sense either: F070 is `DIVERGENT`, not a retained `REUSE`/`ADOPT` row, so
   there is no baseline to challenge.
6. **doxa-gemini and doxa-perplexity both invented owned parameters** (`owns initial_version`,
   `owns release_please_bump_minor_pre_major`, `owns R25.versioning-epoch`, and others). R25 owns
   nothing: the prompt's `- owns:` line is empty and `research/CLAUDE.md` records `—`. `## Parameters`
   above records `owns: none`.
7. **doxa-perplexity's `BASELINE-REVIEW: F070 — pre-1.0 semver dampening — reclassify as a common
   architectural pattern for new library-shaped blueprints` is recorded and not adopted**
   (`raw/doxa-perplexity.normalized.md:71`). It proposes reclassifying F070 away from `DIVERGENT`
   and editing `docs/port/COMMONALITY.md`. Outside R25's authority; not done, and recorded here
   instead. This is the third of the three emitted `BASELINE-REVIEW:` lines, with items 4 and 5.
8. **codex's evidence was documentation-only for the implementation question** — its report notes
   that a GitHub REST probe of the implementation source returned HTTP 403, so it relied on
   maintainer docs and schema. Checks 2 and 3 here fill that gap with the pinned source and an
   executed probe, and confirm codex's conclusion.
9. **Two figures in the raws are close but not identical to what I retrieved**, which is normal
   drift and worth stating rather than hiding: doxa-openai cites release-please `v17.11.1`
   (2026-07-31) where `releases/latest` returned `v17.11.2` (2026-08-24) on 2026-09-09; codex cites
   `axum` `crate.recent_downloads` 113,586,445, retrieved 2026-09-05, against my 112,813,910 four
   days later. Neither changes any conclusion, and the second is explained by the gap:
   `crate.recent_downloads` is a rolling 90-day figure that moves daily.

**What P03 must validate — the unproven list.** Each item names what would prove it.

1. **The end-to-end proposal.** `npx release-please@17.11.2 release-pr --repo-url=<owner>/<repo>
   --dry-run` against the real template repository after `fix:`, then `feat:`, then `feat!:`
   commits, each released before the next lands, and none of them carrying a `Release-As:` footer.
   Expected `0.1.1`, then `0.1.2`, then `0.2.0`,
   starting from a released `0.1.0` — a sequence that holds for that history, that batching and no
   version override, and for nothing else; batched
   differently, the same three commits release once as `0.2.0`, and any one of them carrying an
   override releases that override's version instead (**Override precedence** in `## Decision`).
   Check 3 proved the
   arithmetic in isolation; only this exercises the real strategy including `Cargo.toml` and
   `Cargo.lock` rewriting. **Not run here: it needs a GitHub token and a repository, and building
   either would be implementing the recommendation.**
2. **That the first version release-please releases is `0.1.0`, on a bootstrap history carrying no
   version override.** The empty-manifest reading is
   derived from the pinned source and corroborated by ts's contrary history; no first release was
   executed here, and none could be without building the template. The override condition is not a
   formality for this item in particular: the empty manifest makes the first run scan the entire
   default-branch history, so P03 must confirm that no commit in that history carries a `Release-As:`
   footer and that no `release-as` value is configured or passed (**Override precedence** in
   `## Decision`). P03 proves it the first time the
   Release PR opens — this is the artifact the prompt's value test names, so it is checked before
   the release, not after. **Separately unproven, and claimed nowhere above: that the released
   `0.1.0` reaches crates.io.** That is F074's guard and F075's publishing path, not R25's, and ts
   is the cautionary case — release commits and tags `v0.1.1` and `v0.1.2` exist there and were
   never published to npmjs.com (check 7).
3. **`cargo-semver-checks` as a pull-request gate** — proposed, not decided. Unproven: that it runs
   green on both `ubuntu-latest` and `macos-latest`, its runtime cost, and its false-positive rate
   on this template's surface. Its job placement is R11's (`ci-job-structure`) to decide, not R25's.
   Its RustSec position is also unproven: `https://rustsec.org/packages/cargo-semver-checks.html`
   was reported as HTTP 404 by the opus report, which reads as "no advisory page published" — an
   interpretation, not an affirmative clearance, and I did not re-query it.
4. **Acceptance criterion A4** (no bot-driven `0.x → 1.x` promotion) as a property of the running
   repository rather than of the configuration, and the `Release-As: 1.0.0` graduation path, which
   was read from source and never executed.
5. **The `bootstrap-sha` question that rides along with the empty manifest** — the pin itself, and
   what the first changelog should contain. R25 decides neither: the pin is ledger row **F071**
   (`release-please bootstrap-sha pin`, `ADOPT`, no research item, mechanical), and the changelog
   scope is F066/R24's. P03 must set the pin deliberately rather than inherit whatever the full
   history produces.
6. **Issue responsiveness** (median days to first maintainer response over the 10 most recently
   opened issues) for release-please and for `cargo-semver-checks`. The prompt's evidence table
   requires it; it was not measured and is not estimated.
7. **The C-STABLE dependency question**, which cannot be closed until R53, R55, R58, R67 and R69
   choose the crates whose types reach the public API. If every such crate turns out to be post-1.0
   and the surface is settled, the graduation condition in the runner-up paragraph is met and the
   recommendation should be revised — against this record, not from scratch.
