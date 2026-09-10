# R25 — Pre-1.0 semver bump strategy (pattern, Deep) — revision 2, 2026-09-10

## Decision

**Status: this is a proposal to be validated in the implementation phase.** P02 is research
only; the `rs-launch-blueprint` template does not exist yet, and P03 builds it and proves this
recommendation with its own CI. Nothing here has been implemented: no repository was scaffolded,
no release tooling was configured to run, no CI workflow was written. The owner has reviewed R01
only — no owner acceptance of this item is claimed or implied. If this recommendation does not
survive implementation, it is **revised against this recorded research**, not researched again
from scratch; the executed evidence under `## Empirical check` is the baseline any revision argues
against.

**This is revision 2 (2026-09-10).** Revision 1 was rejected by an empirical audit on one claim —
that the TypeScript source repository "first published v0.1.1" — which its cited evidence did not
establish. The recommendation is unchanged; what changed is the precision of the supporting claim
and a new registry check that settles it. The full diff is recorded at the end of `## Engines`.

**Recommendation.** `rs-launch-blueprint` launches **pre-1.0 at `0.1.0`** with release-please's
pre-major dampening fully enabled. Three artifacts, and one of them is deliberately empty:

| Artifact | Value | Why this exact value |
|---|---|---|
| `Cargo.toml` → `[package] version` | `"0.1.0"` | What `cargo new` itself emits (executed, cargo 1.98.0) |
| `release-please-config.json` | `"release-type": "rust"`, `"bump-minor-pre-major": true`, `"bump-patch-for-minor-pre-major": true` | The unique flag pair that makes each commit type move the digit Cargo's resolver treats as its compatibility class |
| `.release-please-manifest.json` | created **empty**: `{}` | So the **first version release-please releases is `0.1.0`**. A seeded `{".": "0.1.0"}` is read as an *already-released* version, and the first release would then be `0.1.1`. Derived from the tool's source; unproven until P03's first Release PR — see `## Engines`, unproven item 2 |

**Vocabulary, used exactly and consistently from here on**, because the whole manifest argument
turns on the distinction and revision 1 blurred it:

- a **release commit** is the `chore(release): …` commit release-please merges to the default branch;
- a **tag** is the Git tag the release then carries;
- a **registry publication** is a version actually served by crates.io (for rs) or npmjs.com (for ts).

They are three different events. Release-please decides the first two. Whether a publication follows
is the publish workflow's business — ledger rows F074 (tag/version guard) and F075 (OIDC Trusted
Publishing), both `COMMON → REUSE` and both outside R25. **No claim in this decision infers a
registry publication from a release commit or a tag.**

Tool under which those keys were read and exercised: **release-please `v17.11.2`**
(`tag_name` from `GET https://api.github.com/repos/googleapis/release-please/releases/latest`, whose
`published_at` field reads `2026-08-24T21:20:30Z` — that is a GitHub release, not a registry
publication; retrieved 2026-09-09), which is the version reached through
`googleapis/release-please-action` `v5.0.0` — its `package.json` declares
`"release-please": "^17.6.0"` (retrieved 2026-09-09). The flag semantics and the executed bump
table below were established at `v17.11.2` only; at `v17.6.0`, the floor of that range, one thing
was checked — that `Rust.initialReleaseVersion()` still returns `0.1.0`.

**Resulting bump table (executed, not asserted):** from `0.1.z`, `fix:` → patch, non-breaking
`feat:` → patch, `feat!:`/`BREAKING CHANGE:` → minor. From `1.0.0` and above both flags are inert
and ordinary SemVer resumes. Full 36-row output in
`review/evidence/release-please-bump-probe.log`.

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
  rule is its own and because both flags are unreachable code above `1.0.0`.

**Essential behaviors.** For every release the automation cuts:

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
| A1 | Given `fix:` only, the next version differs only in the patch digit | **Executed** — `0.1.3 → 0.1.4` |
| A2 | Given a non-breaking `feat:`, the next version stays inside the current caret band | **Executed** — `0.1.3 → 0.1.4`; and a bare Cargo requirement `"0.7.0"` locks `axum` to `0.7.9` while `0.8.9` exists |
| A3 | Given `feat!:` / `BREAKING CHANGE:`, the next version leaves the caret band | **Executed** — `0.1.3 → 0.2.0` |
| A4 | No release crosses `0.x → 1.x` without an explicit human act | **Argued from source, not executed end to end** — under both flags `true` no commit type produces `1.0.0`; graduation requires a `Release-As: 1.0.0` footer. P03 proves it on the real repository |

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

Map the four essential behaviors onto Cargo's rule at a `0.y.z` version and the required table is
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
  (`src/versioning-strategies/default.ts`) branches on `breaking > 0` first
  (`version.isPreMajor && this.bumpMinorPreMajor` → `MinorVersionUpdate`, else
  `MajorVersionUpdate`), then on `features > 0`
  (`version.isPreMajor && this.bumpPatchForMinorPreMajor` → `PatchVersionUpdate`, else
  `MinorVersionUpdate`), and otherwise returns `PatchVersionUpdate`. `isPreMajor` is
  `this.major < 1` (`src/version.ts:86-88`). So `fix` always moves the patch digit; the flags govern
  breaking commits and `feat` commits respectively; both are inert once the major digit reaches 1.

The prompt's gloss describes option (D) in the table below — `bump-minor-pre-major` alone — which is
measurably wrong under Cargo's rule. **The error should be corrected at its source** in
`research/runs/R25/.../inputs/prompt.md` line 28 and in the F070 explanatory prose in
`docs/port/COMMONALITY.md:76`; this decision does not edit either file.

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
confirms rather than contradicts the principle behind F063/F066/F073. Two raw reports did emit
`BASELINE-REVIEW:` lines — both are handled under `## Engines`, and neither is adopted.

**Architecture alternatives compared, before any flag was chosen.**

1. *Commit-derived automated bump with ecosystem-aware pre-major dampening.* The version is a pure
   function of commit history plus a policy declared in configuration. Integration cost: two JSON
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
the resulting version.

| # | Option | `0.1.3` + `fix:` | + `feat:` | + `feat!:` | `1.0.0` + `fix:` | + `feat:` | + `feat!:` |
|---|---|---|---|---|---|---|---|
| **A** | **both flags `true` — recommended** | 0.1.4 | 0.1.4 | **0.2.0** | 1.0.1 | 1.1.0 | 2.0.0 |
| B | start `1.0.0`, no flags | — | — | — | 1.0.1 | 1.1.0 | 2.0.0 |
| C | start `0.1.0`, neither flag (raw defaults) | 0.1.4 | **0.2.0** | **1.0.0** | 1.0.1 | 1.1.0 | 2.0.0 |
| D | `bump-minor-pre-major` only (what the prompt's gloss describes) | 0.1.4 | **0.2.0** | 0.2.0 | 1.0.1 | 1.1.0 | 2.0.0 |
| E | `bump-patch-for-minor-pre-major` only | 0.1.4 | 0.1.4 | **1.0.0** | 1.0.1 | 1.1.0 | 2.0.0 |

Reading the bold cells against Cargo's rule: under (C) and (E) the *first breaking change ever
merged silently promotes the crate to `1.0.0`* — an irreversible stability claim made by a bot.
Under (C) and (D) a *non-breaking* `feat` produces `0.2.0`, which every Cargo consumer of `"0.1"`
reads as incompatible: the crate withholds a compatible release and forces a manifest edit across
its consumers for no reason. Only (A) satisfies A1–A4. Option (B) is arithmetically correct — above
`1.0.0` every configuration behaves identically — so its cost is not arithmetic but the claim it
makes on day one.

**Why the manifest is created empty, and what the first released version therefore is.** This is
the artifact the raw reports left unsettled, and it is what the prompt's value test names — the
prompt's words are "the template's first-published version number", and the part of that this item
controls is which version release-please *releases* first. Read at `v17.11.2`:

- `BaseStrategy.buildNewVersion` returns `this.initialReleaseVersion()` **only when there is no
  latest release**; otherwise it bumps the latest release's version.
- `Manifest` backfills that latest release *from the manifest file*: the block commented
  `// backfill latest release tags from manifest` treats `this.releasedVersions[path]` as the latest
  release whenever it is present and is not the sentinel `'0.0.0'`. The maintainers' docs say the
  same in prose: seeding `{"path/to/pkg": "1.1.1"}` means *"release-please will now use '1.1.1' as
  the last-released/current version"*.
- `Rust.initialReleaseVersion()` returns `Version.parse('0.1.0')` — at `v17.11.2` **and** at
  `v17.6.0`. `BaseStrategy.initialReleaseVersion()` returns `1.0.0` unless the `initial-version` key
  is set; `python.ts` also overrides to `0.1.0`; `node.ts` has no override and so inherits `1.0.0`.

Two consequences. First, **`release-type: rust` starts a brand-new crate at `0.1.0` with no seeding,
no `initial-version` key and no hand-written manifest entry** — the seeding ts had to do is a `node`
problem, not a Rust one. Second, **seeding `{".": "0.1.0"}` would make the first released version
`0.1.1`, not `0.1.0`.**

That second consequence is an inference **from the tool's source**, and the source is its only
authority: `BaseStrategy.buildNewVersion` plus `Manifest`'s backfill block, quoted above. The ts
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
(`echo "{}" > .release-please-manifest.json`, the maintainers' own bootstrap instruction) and
`Cargo.toml` left at `0.1.0`; release-please then proposes `0.1.0`, writes `{".": "0.1.0"}` itself,
and tags it in whatever form the repository's `include-v-in-tag` setting produces. Whether that
release reaches crates.io is F075's business, not this item's, and P03 proves the released number at
the first Release PR (`## Engines`, unproven item 2).

*Implementation note that travels with the empty manifest, flagged rather than decided here:* with
no manifest entry, release-please collects **all** commits in the branch's history for the first
changelog. The documented control is a top-level `"bootstrap-sha"` key, which py already uses
(`b08bccf`). Changelog scope is F066/R24 territory, not R25's; P03 should set it deliberately when
it wires the first release.

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
- *CLI (installed binary).* Weakest constraint. `cargo install` resolves the newest version whatever
  the digits are, and users read release notes rather than version arithmetic. Neither option harms
  this shape. One point for `0.1.0`: in a single-version workspace the CLI's `--version` string and
  the library's version are the same string, so the CLI should not be the surface making a stability
  promise on the library's behalf.
- *Web service (optional feature-gated surface).* A feature-gated HTTP surface built on pre-1.0
  dependencies inherits their churn: an `axum` `0.8 → 0.9` bump is, by Cargo's rule, a breaking
  change, and where those types reach the template's public API it is breaking for the template too.
  Under (A) that propagates as `0.1.z → 0.2.0` — accurate and cheap. Under (B) the same routine
  upstream bump forces `1.x → 2.0.0`, driving the major digit up for reasons unrelated to the
  template's own design. This is the strongest practical argument against (B), and it is specific to
  a Rust web stack; ts faced nothing equivalent.

**Ranked runner-up, and the condition under which it wins.** Option (B) — launch at `1.0.0` with
ordinary SemVer, py's present shape. It requires an override (`"initial-version": "1.0.0"`, or hand
seeding), because `release-type: rust` otherwise starts at `0.1.0`. It is a runner-up rather than a
rejected option because above `1.0.0` its arithmetic is identical to (A)'s; its whole cost is the
claim it makes on day one. It wins only if, **before first publication**, all of the following hold:
R04's public-API enforcement is wired and the curated surface is final; no crate appearing in that
public surface is itself pre-1.0 (C-STABLE); the web surface's dependency churn is walled off behind
private types; and the owner accepts that every subsequent breaking change costs a whole major
digit. The practical reconciliation is to take (A) now and reach (B)'s position later with a
`Release-As: 1.0.0` commit footer — the maintainers document the syntax
(*"When a commit to the main branch has `Release-As: x.x.x` (case insensitive) in the **commit
body**, Release Please will open a new pull request for the specified version"*, `README.md`,
v17.11.2), `DefaultVersioningStrategy` honours it before any other decision, no config change is
needed, and both flags become inert automatically once `major >= 1`. The deprecated `release-as`
**config key** is the inferior route: the schema marks it *"[DEPRECATED] … Consider using a
`Release-As` commit instead"*, and the docs warn that leaving it in place makes subsequent runs keep
proposing the same version.

**What (A) gives up.** Versus (B): the stability signal. Some risk-averse consumers and some
corporate policies treat `0.x` as experimental. That cost is accepted because a false `1.0.0`
followed by an early `2.0.0` is more damaging than honest pre-1.0 iteration, because `0.x` carries
no visible adoption penalty in Rust (four of the six widely-adopted crates sampled above are
pre-1.0, several with nine-figure all-time download counts), and because pre-1.0 is the recoverable
direction — graduation is a commit footer, retreat from `1.0.0` is not. Versus (C)/(D)/(E): the
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
independent and release-please runs on whichever GitHub-hosted runner the workflow picks. (5)
*Default features / async coupling* — inapplicable; the two flags are JSON booleans that default to
`false` when absent. (6) *Binary size and compile time* — inapplicable and measurably zero: the
decision changes only the `[package] version` string, which reaches the binary at most through the
compile-time `CARGO_PKG_VERSION` variable. The one tool this decision *proposes* (rather than
decides) for CI, `cargo-semver-checks`, was **not** gated here and was **not** executed on either
required runner; that is listed under `## Engines` as work for P03.

re-verify: before P03 cuts the first release (run the end-to-end `release-please release-pr --dry-run` against a scratch repository), or on any release-please major version past v17 reaching this repository through `googleapis/release-please-action`, whichever comes first.

## Parameters

- owns: **none.** R25 owns no entry in `docs/port/PARAMETERS.md`; the binding prompt's
  `## Couplings` `- owns:` line is empty and `research/CLAUDE.md`'s R25 row records `—` in the
  `owns` column. This item's output is consumed as ledger row F070's content, not as a registry
  parameter. Two raw reports invented owned parameters; that is corrected under `## Engines`.
- assumes `msrv-policy` = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — owner-fixed (`docs/port/PARAMETERS.md`, 2026-09-02). Unaffected: the recommendation adds no crate and touches no `rust-version` key.
- assumes `rust-edition` = `2024` — owner-fixed. Unaffected: the edition is independent of the version field. (`cargo new` on cargo 1.98.0 emitted `edition = "2024"`, executed 2026-09-09.)
- assumes `license` = `MIT OR Apache-2.0` — owner-fixed. Unaffected: no dependency is introduced, so no license-compatibility question arises.
- assumes `target-os-matrix` = `ubuntu-latest, macos-latest` — owner-fixed. Unaffected: version arithmetic is platform independent. The one *proposed* CI addition (`cargo-semver-checks`) would have to run on both runners; it was not executed on either here, and that is recorded as an evidence gap.
- Assumed from the ledger rather than from `PARAMETERS.md`, per the prompt's `## Out of scope`:
  release-please is the release tool and `Cargo.toml`'s `[package] version` is the version source of
  truth (F063, F066, F073, all `COMMON → REUSE`).
- The prompt's `## Couplings` lists no `consumes:` entries. **No `CONFLICT:` line is raised** — no
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
and repository reads. All seven checks in the table below exited `0` **except check 7's first
command, whose non-zero exit is itself the result** — `npm view ts-launch-blueprint@0.1.1` exits 1
with `E404`, which is what the check was run to find out. All HTTP fetches returned `200` except
where a status is quoted otherwise. Retrieval date: **2026-09-09** for checks 1–6, **2026-09-10**
for check 7, which was added in revision 2.

| # | What it decides | Command (working directory) | Result | Log |
|---|---|---|---|---|
| 1 | Toolchain and OS of record | `rustc --version`; `cargo --version`; `sw_vers`; `uname -sm` (repository worktree, read-only) | as quoted above; exit 0 | `evidence/toolchain.log` |
| 2 | What the two flags actually do, whether they are Rust-specific, and what a fresh Rust crate's initial version is | `curl -sS -A <ua> https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/<path>` for 10 paths, plus `v17.6.0/src/strategies/rust.ts` and `release-please-action/v5.0.0/package.json` (`<scratch>/rp-src`) | all `200`; schema, docs and implementation agree, and all three contradict the prompt's gloss; `Rust.initialReleaseVersion()` → `0.1.0` at both tags; action `v5.0.0` depends on `release-please ^17.6.0`; exit 0 | `evidence/release-please-source-v17.11.2.log` |
| 3 | Which flag combination produces the table Cargo's rule requires | `npm --prefix <scratch>/rp-probe install release-please@17.11.2` then `node <scratch>/rp-probe/probe.cjs` — 4 configurations × 3 start versions × 3 commit types | 36 rows; only both-flags-`true` gives `fix→z`, `feat→z`, `feat!→y` at `0.x`; exit 0 | `evidence/release-please-bump-probe.log` |
| 4 | Cargo's own initial version, and whether a `0.y` minor bump really is the incompatibility boundary | `cargo new --lib/--bin --vcs none`; then `cargo generate-lockfile` on three throwaway manifests (`<scratch>`) | `version = "0.1.0"`, `edition = "2024"`; `bitflags = "0.9.0"` → `0.9.1` while `2.13.2` exists; `axum = "0.7.0"` → `0.7.9` while `0.8.9` exists; `bitflags = "1.0.0"` → `1.3.2`, never `2.x`; exit 0 | `evidence/cargo-initial-version-and-resolver.log` |
| 5 | That every rule attributed to a standard or tool is quoted from a source that covers that case | `curl -sSL` of Cargo Book `semver.html` and `specifying-dependencies.html`, `semver.org`, `rust-lang/api-guidelines` `necessities.md`, release-plz `config.md` (`<scratch>/docs`) | all `200`; the five verbatim quotations reproduced in `### Principles and implementation`; exit 0 | `evidence/authority-quotations.log` |
| 6 | Maintenance state, adoption figures, and the two source repositories at their pinned commits | `GET api.github.com/repos/...`, `GET api.github.com/search/issues?...`, `GET crates.io/api/v1/crates/<name>` (6 crates); `git -C ~/c/{ts,py}-launch-blueprint show <pinned sha>:<path>` | release-please `v17.11.2` / `pushed_at` 2026-09-03 / `archived: false` / 297 open issues; ts seeded `0.1.0` and its first release commit was `v0.1.1`; py adopted release-please at `1.0.0` and sets no `pre-major` key; exit 0 | `evidence/registry-and-source-repos.log` (see the correction appended at its foot, and check 7) |
| 7 | **Added in revision 2.** Whether ts's `v0.1.1` was a release commit, a tag, or a registry publication — three different things | `npm view ts-launch-blueprint@0.1.1 …`; `npm view ts-launch-blueprint versions …` (isolated cache); `curl https://registry.npmjs.org/ts-launch-blueprint`; `git tag --list`; `git log` (`<scratch>`) | release commit `bdc7567` and tag `ts-launch-blueprint-v0.1.1` exist; npm serves only `0.0.1` and `0.1.3`, and `@0.1.1` exits 1 with `E404`; `0.1.0` appears in none of the three | `evidence/ts-registry-publication-check.log` |

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
evidence, the two recorded-but-not-adopted `BASELINE-REVIEW:` lines, checks 1–6 and their logs, and
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
   on the record here and should be fixed at its source** (`inputs/prompt.md` line 28 and the F070
   prose at `docs/port/COMMONALITY.md:76`); this decision edits neither.
2. **How the first released version is actually produced — a correction to the opus report, which
   no engine got fully right.** opus's migration table recommends seeding
   `.release-please-manifest.json` as `{".": "0.1.0"}` *and* relies on
   `Rust.initialReleaseVersion()` returning `0.1.0`. Those do not compose. `src/manifest.ts`'s
   "backfill latest release tags from manifest" block treats a manifest entry as the *last released*
   version, and `docs/manifest-releaser.md` says the same in prose, so a seeded `0.1.0` makes the
   first Release PR propose `0.1.1`. **The proof is the source; ts's history is corroboration only**
   — it seeded `0.1.0` at `19ff9b5`, and its first release commit and tag were `v0.1.1`, with the
   seeded number appearing as neither. Revision 1 wrote that ts "first published v0.1.1"; it did
   not, and that overstatement is finding 1 of the audit recorded below. This decision therefore
   creates the manifest **empty** so the first version released is `0.1.0`.
3. **doxa-openai's bootstrap-only `release-as: 0.1.0` is not adopted.** It solves the same worry a
   different way, but the schema marks the `release-as` config key *"[DEPRECATED] … Consider using a
   `Release-As` commit instead"* and the docs warn that leaving it in place makes subsequent runs
   keep proposing the same version. With `release-type: rust` and an empty manifest it is
   unnecessary — the strategy already returns `0.1.0`.
4. **doxa-gemini's `BASELINE-REVIEW: F066, F073 — replace release-please with release-plz` is
   recorded and not adopted.** The binding prompt's `## Out of scope` states that whether the
   template uses release-please at all is settled by F063, F066 and F073 (`COMMON → REUSE`) and that
   R25 decides only the bump semantics within it. The proposal is therefore outside this item's
   authority; no ledger row is touched. Its *evidence* is used, however, and it is good evidence:
   release-plz's documented default equals `bump-patch-for-minor-pre-major: true`, and it labels the
   contrary setting a violation of Cargo's SemVer rules — an independent Rust-native tool reaching
   the same policy. If the owner wants the release-tool choice reopened, that is a new item, not a
   revision of this one.
5. **doxa-openai's `BASELINE-REVIEW: F070` is really the flag-gloss correction, restated.** It asks
   that F070's explanatory prose stop saying "feat bumps minor". That is item 1 above and this
   decision records it. It is not a baseline review in the ledger's sense: F070 is `DIVERGENT`, not
   a retained `REUSE`/`ADOPT` row, so there is no baseline to challenge.
6. **doxa-gemini and doxa-perplexity both invented owned parameters** (`owns initial_version`,
   `owns release_please_bump_minor_pre_major`, `owns R25.versioning-epoch`, and others). R25 owns
   nothing: the prompt's `- owns:` line is empty and `research/CLAUDE.md` records `—`. `## Parameters`
   above records `owns: none`.
7. **doxa-perplexity proposes reclassifying F070 away from `DIVERGENT` and editing
   `docs/port/COMMONALITY.md`.** Outside R25's authority; not done, and recorded here instead.
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
   commits. Expected `0.1.1`, `0.1.2`, `0.2.0` from a released `0.1.0`. Check 3 proved the
   arithmetic in isolation; only this exercises the real strategy including `Cargo.toml` and
   `Cargo.lock` rewriting. **Not run here: it needs a GitHub token and a repository, and building
   either would be implementing the recommendation.**
2. **That the first version release-please releases is `0.1.0`.** The empty-manifest reading is
   derived from the pinned source and corroborated by ts's contrary history; no first release was
   executed here, and none could be without building the template. P03 proves it the first time the
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
5. **The `bootstrap-sha` question that rides along with the empty manifest** — what the first
   changelog should contain. R25 does not decide it; F066/R24 do. P03 must set it deliberately
   rather than inherit whatever the full history produces.
6. **Issue responsiveness** (median days to first maintainer response over the 10 most recently
   opened issues) for release-please and for `cargo-semver-checks`. The prompt's evidence table
   requires it; it was not measured and is not estimated.
7. **The C-STABLE dependency question**, which cannot be closed until R53, R55, R58, R67 and R69
   choose the crates whose types reach the public API. If every such crate turns out to be post-1.0
   and the surface is settled, the graduation condition in the runner-up paragraph is met and the
   recommendation should be revised — against this record, not from scratch.
