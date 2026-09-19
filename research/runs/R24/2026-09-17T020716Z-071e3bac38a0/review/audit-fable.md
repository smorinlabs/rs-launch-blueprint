decision-sha256: bc5dcafa1ac0a864ce458bdc45dee92f02385cb28ebde7e8af364a5b04683a52
actor: audit-fable-2026-09-17T020716Z-071e3bac38a0-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

I read `review/DECISION.md` whole (654 lines) at the sha256 above, recomputed
with `shasum -a 256` on opening and again immediately before writing this file;
`raw/opus.md` whole (670 lines), confirmed at sha256
`70f25e538ae4bf34494ca1202ef653b57b98c9f3c6bf8fa1414d538239be1a75` and
byte-identical to the run's content-addressed copy
`raw/opus-70f25e53….md`; `inputs/prompt.md`;
`docs/superpowers/plans/p02-roles/judgment-auditor.md` and
`docs/superpowers/plans/p02-roles/synthesizer.md` (for the required H2 set);
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` rows F063, F066, F067 and
F073; `docs/port/BASELINE-REVIEW.md:54`, `:55` and `:60`;
`docs/port/OWNER-REVIEW.md:47`; `docs/planning/p02/execution-ledger.md:1000`
and `:1016`, and `docs/planning/p02/owner-decisions.md:488` for owner ruling
W1-CODEX3; `research/topics/38-commit-message-linter/DECISION.md`,
`research/topics/25-semver-bump-strategy/DECISION.md` and
`research/topics/19-dependabot-config-shape/DECISION.md` at the passages this
decision cites; `review/evidence/r24-checks.sh` in full (24 KB),
`review/evidence/probe/render.cjs`, `review/evidence/snap/RETRIEVED.txt`, both
committed logs and all seven rendered snapshots; and
`research/runs/R44/2026-09-17T020715Z-ff8c50edbd69/review/DECISION.md` with its
`review/audit-fable.md` for proportion and for the findings convention.

`review/audit-codex.md` does not exist. The role doc lists it as required
reading; the empirical audit is deferred under owner ruling W1-CODEX3 of
2026-09-18 — "Test Codex if it's available now, and if it is, use it. If not, do
without it" — with the 21:53Z probe returning the account's usage-limit error
(`docs/planning/p02/owner-decisions.md:488`). There is therefore no empirical
audit to be consistent with, and I reproduced the decision's executed evidence
myself rather than reading its logs only.

## Principle and agreement level

**The shared requirement is stated at the level the ledger classified, and the
statement is not a restatement of either source.** The requirement — a release
entry tells a consumer of the published artifact what changed for them, and the
type-to-visibility mapping is declared in one committed file rather than decided
per release — is sourced to both repositories' `release-please-config.json` at
the programme pins, and the agreement level is **policy**: the mapping must be
declared and must be total over the repository's own commit enum, while the
*membership* of the visible set may vary because it is an audience judgement.
That reading matches `docs/port/COMMONALITY.md:73`, where F067 is `DIVERGENT`
rather than `COMMON → REUSE`, and it is the reading that lets the decision
reject py's `refactor` stance and ts's `test` stance without treating either
repository as the winner. The five essential behaviours are observable, and each
maps to a numbered acceptance criterion with an honest `executed here` /
`partly executed` / `P03` label.

**The three neighbouring rows are inherited, correctly.** F063, F066 and F073
are `COMMON → REUSE` with tool `release-please` at `docs/port/COMMONALITY.md:69`,
`:72` and `:79`, and `retained` at `docs/port/BASELINE-REVIEW.md:54`, `:55` and
`:60`. I confirmed all six line numbers. No `BASELINE-REVIEW:` line is raised
and none was raised by the report, which is right: this item changes nothing in
those rows, and its `## Out of scope` excludes the tool choice itself.

**No `CONFLICT:` line is correct.** R24's prompt carries an empty `- owns:` line
(`inputs/prompt.md:19`) and consumes one parameter, `commit-message-convention`
from R38. The recommendation's array membership *is* that parameter's
`type-enum` field, unchanged — so there is nothing to conflict with.

## Design and evidence

**The three architectural shapes are genuinely compared, and the comparison is
executed rather than argued.** Shape A (inherit), Shape B (partial override) and
Shape C (total ordered map) are each scored against the same five behaviours and
each was actually rendered — runs A, C and D. Shape C is selected on the
mechanism that Shape B fails, not on repository agreement: py's array is Shape C
and is still ranked third, on `refactor` visibility and an unreachable `deps`
entry. The decision states plainly that the *membership* it recommends "is
composed for this template and has no named prior adopter", which is the
evidence gap named as a gap.

**I reproduced all three decisive claims independently.** I installed
`release-please@17.11.2` into a throwaway directory under `$TMPDIR` (deleted
before this file was written), confirmed that
`conventional-changelog-conventionalcommits@6.1.0` resolves transitively under
it, and drove `parseConventionalCommits`, `DefaultChangelogNotes.buildNotes`
and `BaseStrategy.prototype.changelogEmpty` with my own fixture and with ts's
seven-entry array copied from the pin rather than from the decision. I did not
run `probe/render.cjs`.

| Decisive claim | What my own run produced |
|---|---|
| Explicit hidden entries are not redundant: a breaking commit of an unmapped type renders under a raw lowercase heading sorted above Features | Under ts's array the heading order is `⚠ BREAKING CHANGES`, **`style`**, `Features`, … — the raw lowercase heading is present and precedes `Features`. Under the recommended eleven entries no heading matches `^[a-z]+$`, and the same commit renders under `Styles` |
| ts's array silently drops a non-breaking `revert:` | Under ts's array there is no `Reverts` heading and the revert subject appears zero times; under the recommended array both are present |
| `changelogEmpty` makes the visible set the releasable set | `BaseStrategy.prototype.changelogEmpty` taken off the prototype returns `true` on a `test:`+`ci:`+`chore(deps):` push, whose body is exactly one line — the release header — and `false` once a single `fix:` joins it, which also produces `### Bug Fixes` |

**The supporting mechanisms hold at source, and one holds more strongly than the
decision's own evidence.** I confirmed at the installed package that
`config.types = options.changelogSections` is an assignment guarded by
`if (options.changelogSections)` with no concatenation (mechanism 1); that the
preset's own default at `writer-opts.js:178-191` is the fallback; that the
predicate is literally `return changelogEntry.split('\n').length <= 1;`; that
`DEFAULT_HEADINGS` supplies all eleven titles the recommendation uses verbatim;
and that `DEFAULT_CHANGELOG_SECTIONS` is an eleven-entry map over **exactly**
R38's eleven types with four visible and no `deps` entry. That last point is
worth naming: check `3c-entry-count` asserts the count, not the identity of the
types, so the decision's stronger sentence — "a total map over exactly the
eleven types `commit-message-convention` declares" — rests on a check that does
not quite reach it. I read the array and the sentence is **correct**.

Likewise mechanism 4. The decision argues that `filterCommits` "never runs for a
Rust repository at all" from the absence of the identifier in
`strategies/rust.js`, which would not settle it if a shared caller existed. I
swept every occurrence in the 17.11.2 build tree: the helper is called only from
`strategies/node.js`, `strategies/node-librarian.js`, `strategies/python.js` and
`strategies/java-yoshi-mono-repo.js`, never from `base.js`. The claim is right,
and the strategy-level fallback arrays the decision attributes to `python`,
`java` and `r` are each present.

**The report's three corrections are right.** (1) Fitness gate 1: the owner's
ruling at `docs/port/OWNER-REVIEW.md:47`, "2026-09-12 — no licence check for
anything the template uses (Q4, superseded and widened by Q7.B)", is verbatim
what the decision says it is, so striking `raw/opus.md`'s Apache-2.0 `Pass` and
recording the gate as `inapplicable` is correct, and nothing below is ranked or
excluded on a licence ground. (2) The line ranges: I read both configuration
files through their pins with `git show`. py's `"changelog-sections"` key is on
line 22 and the array closes on line 35, twelve entries on lines 23–34; ts's key
is on line 11, closing on line 19, seven entries on lines 12–18. The report's
`:23-36` and `:12-20` are off by one; the synthesizer's corrected numbers are
exact, and both files carry the `$schema` declaration the migration note says to
keep. (3) The empty `⚠ BREAKING CHANGES` bullets: in my own render, driven with
real message strings, the two bullets carry their commit subjects and no empty
bullet appears — a fixture artifact in the report's probe, exactly as diagnosed.

**The consumed and cited decisions say what the decision says they say.** R38
owns `commit-message-convention` with the eleven-type enum, and the decision's
`- assumes` line is byte-identical to it. R19 fixes Dependabot's
`commit-message` to `prefix: "chore"` with `include: "scope"`, and py's own
`.github/dependabot.yml` at pin `b08bccfb` carries those keys at lines 24–27,
57–59 and 74–77 — I read all three. R25 settles `"release-type": "rust"` with
both pre-major flags `true`. The `deps`-entry-is-unreachable argument therefore
stands on checked ground.

**The unexecuted halves are labelled honestly.** Mechanism 5 is executed at the
predicate level and the decision says so three times, in `## Decision`, in
criterion A6 and in `## Engines`, each time naming what remains: that the
`return undefined` the guard wraps is what a caller experiences as "no release
pull request", which needs a GitHub repository and is P03's A6. Criterion A5 is
`partly executed` with the schema-validation half assigned to P03. The
"Nothing was built" paragraph is accurate at the scope it claims — that **this
item** built nothing. `git show --stat 9fce93c` and `ef4139e` between them touch
only `review/DECISION.md` and files under `review/evidence/` — 27 files in the
first commit, 3 in the second — adding no `release-please-config.json`, no
`CHANGELOG.md`, no workflow and no scaffold. The two source configurations the
run does carry are suffixed `.snapshot`, which `snap/RETRIEVED.txt` explains is
what keeps third-party bytes out of this repository's lint and test globs; they
are read-only copies of py's and ts's files at their pins, not configuration
this repository uses. The check script writes only `toolchain.txt`
and a scratch tree under `$TMPDIR` that its `EXIT` trap removes. Widened to the
whole repository the sentence would be false, and the decision does not widen
it: `git ls-files` returns four tracked files carrying those two names, all of
them fixtures inside other runs' evidence directories — one `CHANGELOG.md`
under `research/runs/R15/…/review/empirical/fixture/` and three
`release-please-config.json` files under
`research/runs/R23/…/review/empirical/`. None is a template scaffold and none
belongs to R24.

## Completeness

**The structure is exactly what the synthesizer role requires.** Four H2
sections in order — `## Decision`, `## Parameters`, `## Empirical check`,
`## Engines` — with the `### Principles and implementation` H3 inside the first
and the `re-verify:` line closing it with six named triggers plus a dated
backstop of 2027-03-18. There is no `## Supersedes`, correctly, this being
revision 1.

**The parameter block is correct.** Five `- assumes` lines, no `- owns` line. I
compared each value against its row in `docs/port/PARAMETERS.md`
programmatically rather than by eye: `msrv-policy`, `rust-edition`,
`target-os-matrix`, `license` and `commit-message-convention` are all
byte-identical, bare, with no backticks, citation or trailing commentary. The
prose that explains how the four fixed parameters bear on the item sits after
the list, where the format requires it.

**The empirical check reproduces, and I reran it three ways rather than reading
its log.** I redirected each rerun into my own scratch directory so the
committed log was never overwritten.

| Rerun | Result |
|---|---|
| In place, `bash r24-checks.sh` | exit 0; **byte-identical** to `review/evidence/r24-checks.log` |
| From a clean `git archive 9fce93c` extraction with no `.git` present | exit 0; **byte-identical** to the same log |
| Same extraction with `PATH=/usr/bin:/bin:/usr/sbin:/sbin` | exit 0; **byte-identical** to `review/evidence/r24-checks-skip-control.log` |

Counting the log's own lines rather than trusting its summary: the full run is
125 `PASS`, 0 `FAIL`, 0 `SKIP`, and the named-skip control is 109 `PASS`, 0
`FAIL` and 3 `SKIP` — `7a-install`, `7b-upstream-bytes` and `7c-rendered-bytes`,
each naming `node is not on PATH`. 109 + 16 = 125, and section 7 contains
exactly those sixteen assertions, so the two logs account for each other. The
script is `shellcheck`-clean at 0.11.0 on my own run, carries `set -euo
pipefail`, and every assertion compares an expected value against an observed
one rather than resting on an exit code.

**No check is unfalsifiable.** `count`/`countf` return `0` when a file is
absent, so an assertion expecting `0` would pass against a missing file. Every
rendered snapshot that carries such an assertion also carries a positive one
that a missing file would fail — `4e-order` and `4c`/`4d` for run D,
`4a-raw-lowercase-heading` for run C, `4h-reverts-present` for run A,
`4i-refactor-heading` for run B — so no zero-expectation is vacuous. The
snapshot-versus-pin check `6c` compares `git show` at the pin against the
committed snapshot and I reproduced both comparisons by hand: identical. One
fragility worth recording without calling it a defect: `1a` extracts the first
`type-enum:` match in the registry with `head -1`, which would read the wrong
row if a row carrying that string were ever added above
`commit-message-convention`; check `2-commit-message-convention` binds the whole
value byte-for-byte and would catch it.

**The executed evidence is dated and endpoint-bearing.** Everything outside
section 8 comes from the npm registry at a pinned version; section 8's two
GitHub REST endpoints are named in full with retrieval date 2026-09-18 in both
`## Empirical check` and `snap/RETRIEVED.txt`. The carried-but-not-re-executed
figures — the four crates.io download pairs, release-please's stars, `archived`,
`pushed_at` and open-issue count, `git-cliff`'s shipped `cliff.toml`, the
docs.rs quotations — are enumerated as carried, each at 2026-09-18, which is the
retrieval date `raw/opus.md` itself records for them. I made one live call,
`gh api repos/googleapis/release-please/releases/latest`: `v17.11.2`,
`draft: false`, `prerelease: false`, `published_at: 2026-08-24T21:20:30Z` — the
snapshot section 8 asserts on is still what the endpoint returns today.

**`## Engines` records the single engine honestly.** It names Claude Opus 5 with
the report's sha256, its fifteen H3 fields and its validator result; it records
the Codex leg as absent with the reason, names `raw/codex-*.txt` as timing stubs
rather than evidence, and notes that `raw/codex-transcript.txt` is gitignored —
which `git check-ignore` confirms, at `.gitignore:5`. I read that transcript: it
is the `gpt-5.6-luna` R24 dispatch of 2026-09-17T04:39Z ending in
"You've hit your usage limit", which is what the section says. The deferral cites
W1-CODEX3, recorded at `docs/planning/p02/owner-decisions.md:488` and
`docs/planning/p02/execution-ledger.md:1000`. The section then states the
material uncertainty in its own words — that a single-engine synthesis has no
independent lens on the framing even where every factual claim was re-executed —
and does not dress the re-verification up as a second opinion.

**Proportion fits a light item.** At 654 lines the decision is slightly shorter
than R44's accepted light decision (679 lines), and its 125 assertions are
concentrated on one tool at one version rather than spread thin. Nothing here is
padding.

**One committed file is rewritten by a rerun, as the decision says.**
`review/evidence/toolchain.txt` carries the run's UTC timestamp and scratch path
and is rewritten on every invocation; the decision states this explicitly and
explains why keeping that text off stdout is what makes the log reproducible. My
in-place rerun did modify it, and I restored it with `git checkout --` before
writing this file. `git status --porcelain` for the run directory is clean apart
from this audit.

## Findings

Four findings, **all non-blocking**. None is an unresolved finding in the sense
the role doc gives the term: none contradicts an executed result, none touches
the array, its order, its headings, the runner-up or the condition under which
the runner-up wins.

**JF-1 (non-blocking) — two line numbers cited for run C are off by two.**
`## Decision` says that under ts's array "a `style!:` commit renders as `###
style` at line 11 of the entry, above `### Features` at line 16". In
`review/evidence/snap/rendered/C-ts.md`, `### style` is on line **9** and `###
Features` on line **14**; lines 11 and 16 are the bullet lines beneath those two
headings. *Why it does not block:* the load-bearing claim is the ordering, not
the offsets, and the check that establishes it — `4a-sorted-above-features` —
compares the two headings' actual positions through the script's `lineno`
helper rather than against hard-coded numbers, so the assertion is sound and my
own render reproduces the ordering. *Worth recording anyway:* correction 2 in
`## Engines` faults `raw/opus.md` for off-by-one line citations, so the same
class of defect survives in the correcting document. A revision should either
fix the two numbers or drop them, since the sentence is complete without them.

**JF-2 (non-blocking) — mechanism 5's "no release pull request at all" is
unconditional in prose while the guard it quotes is conditional.** The decision
quotes the guard correctly, `if (!bumpOnlyOptions && this.changelogEmpty(…))`,
but never says what supplies `bumpOnlyOptions`, and then states the consequence
absolutely in four places: "opens no release pull request at all", "produces no
release pull request", "unshippable until a visible-type commit joins it", and
"the version a hidden-only period would have produced is never proposed at all".
I swept every call site in the 17.11.2 build tree. `manifest.js:364` passes four
arguments, leaving `bumpOnlyOptions` undefined and the guard live — which is the
path a single-package manifest takes. Two plugins pass a fifth argument and so
bypass the guard entirely: `plugins/node-workspace.js:172` and, the one that
matters for a Rust template, `plugins/cargo-workspace.js:158`. *Why it does not
block:* under the configuration this decision recommends and R25 settled — one
`"."` package, no `plugins` array — the `cargo-workspace` plugin is not enabled,
so every one of those sentences is true of this template as configured, and the
`docs`-visibility argument that rests on mechanism 5 is unaffected. *Worth
recording anyway:* the qualification is not idle. Other resolved items describe a
`crates/core` and `crates/web` layout, and `cargo-workspace` is release-please's
standard plugin for releasing a Cargo workspace; if the template adopts it, a
hidden-only period does get a bump pull request. Naming the plugin once would
make the sentences true generally instead of true by configuration.

**JF-3 (non-blocking) — "exits 0" is a process-status claim no check covers.**
`## Decision` says release-please "logs `No user facing commits found since
<sha> - skipping` and exits 0". The log string and the `return undefined` are
read at source and I confirmed both at `strategies/base.js:172-174`. The
**process exit status** is neither read nor executed, and it is not among the
unexecuted halves criterion A6 enumerates, which name only the `return
undefined` control flow. *Why it does not block:* the point the sentence carries
is that the failure mode is silent, which the log-and-return already establish;
the exit status adds nothing the argument needs. A revision should label it the
way the rest of the document labels read-versus-executed claims, or drop it.

**JF-4 (non-blocking) — "Executed run A is this runner-up's rendering" is true
of this fixture, not in general.** Run A is the preset default with no array
declared; the runner-up is a declared eleven-entry array with `docs` hidden and
moved down. Those are different configurations. The preset's own default list at
`writer-opts.js:178-191` is itself total over R38's eleven types and uses the
same titles as `DEFAULT_HEADINGS`, so the two differ only in the *position* of
the hidden entries — which is exactly what decides where a breaking commit of a
hidden type sorts. The fixture carries one such commit, `style!:`, and `Styles`
lands in the same place under both lists, so the two renderings coincide here;
they would not if the fixture carried a breaking `build!:` or `ci!:`. *Why it
does not block:* the operative clause is correctly hedged — run A "differs from
run D by the absence of `### Documentation` and nothing else **in heading
membership**" — and membership is what the runner-up comparison turns on. Only
the identification preceding that clause overreaches.

## Assessment

**The recommendation follows from the evidence as written.** The array is total
over R38's enum by construction and by asserted set equality; its order is
declared and shown to be the rendered order; its titles are release-please's own
`DEFAULT_HEADINGS`, which I read. The one membership call that is genuinely this
template's own — `docs` visible, `refactor` hidden — is argued from artifact
membership (rustdoc ships inside the published crate) rather than from either
source repository's precedent, and mechanism 5 converts that preference into a
capability question with an executed predicate behind it. The runner-up is a
one-boolean neighbour with two stated winning conditions, one of which the
decision makes actionable by proposing the contributing-guidance change that
would otherwise degrade the `Documentation` section's signal.

**The three decisive claims are reproduced, not asserted.** I drove
release-please 17.11.2 with `conventional-changelog-conventionalcommits` 6.1.0
myself, with ts's array taken from its pin rather than from the decision, and
all three reproduced: the raw lowercase heading sorted above `Features`, the
silently dropped non-breaking `revert:`, and `changelogEmpty` flipping from
`true` to `false` on a single added `fix:`. Two supporting claims proved
*stronger* than the checks cited for them — `DEFAULT_CHANGELOG_SECTIONS` is over
exactly R38's eleven types, and `filterCommits` has no caller reachable from the
Rust strategy — and neither needed correcting.

**The recommendation would not move under any finding.** JF-1 is two wrong
offsets in a sentence whose claim is separately and correctly asserted; JF-2 and
JF-3 are absolute phrasings of a mechanism whose executed half is sound and
whose unexecuted half is already assigned to P03; JF-4 is an over-identification
in a sentence whose operative clause is hedged. None touches the eleven entries,
their order, their `hidden` flags, the headings, the ledger disposition of F067,
or the inherited status of F063, F066 and F073. The two absoluteness findings
are the class the synthesizer runbook warns about and a revision should carry
their conditions; they are corrections to labelling, not to the answer.

**Acceptance is not complete on this audit alone.** `review/audit-codex.md` does
not exist and the empirical audit — including an independent rerun of
`r24-checks.sh` — is deferred while the Codex account is out of usage under
W1-CODEX3. What this audit can offer in its place is that I reran the script
three ways myself, byte-identical each time, and reproduced the decisive
evidence through my own install rather than through the run's probe.
