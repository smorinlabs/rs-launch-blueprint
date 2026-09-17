decision-sha256: 44e945045f0e2c964520918801f5c8f3921a3cfefc4ef5c72b0bc497038139ba
actor: audit-fable-2026-09-17T020714Z-8fdb5c2010e7-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# Judgment audit — R57 xdg-directory-set, revision 2 (round 2)

Round 1 of this audit is preserved byte-identically at `review/audit-fable.r1.md`
(sha256 `6f27abbea81182a678efe4b2b68f986b19ee8dd4ebc9fd412fb45b7e95c1e934`); it
bound revision 1 at sha256
`78d7256f6bd9ac21c78560ffffeea343bee6c46fa98de1aeb20ed1e7071be8d9` and returned
`reject` on five findings. This round judges revision 2 at the sha above, which
arrived as commit `8071cd3 fix(research): revise R57 xdg-directory-set to
revision 2 (JF-1..JF-5)`. The empirical (Codex) audit is still deferred for lack
of account usage, so this round again ran alone and acceptance still needs a
second approving verdict.

Every repair below was checked against the primary artifact, not against the
synthesizer's report of it, and not against revision 2's own new log alone: the
standard at its pinned blob, the two source repositories at their pins, and the
committed JSON responses.

## Principle and agreement level

Unchanged and still correct. The recommendation, the force-gradation table, the
Runtime omission, the `rslbp` namespace, the F249 disposition and its single
`BASELINE-REVIEW:` line, the B1–B7 criteria with the B6 correction, the
`RSLB101` gradation, the five engine disagreements, the seven `U#` rows and the
`re-verify:` line are all byte-identical to revision 1 — I checked by diffing the
two revisions rather than by reading the claim. `docs/port/COMMONALITY.md:253`
still carries the contingency clause, so the disposition remains a proposal for
the controller rather than an applied edit, as `research/RUNBOOK.md:167`
requires. The H2 set and order are still `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines`; no H2 was added. The four `- assumes` lines
are byte-identical to revision 1 and to `docs/port/PARAMETERS.md` lines 7–10, in
registry order.

## Design and evidence

Revision 2 changes no evidence that revision 1 relied on. `evidence/r57-claims.sh`,
`evidence/r57-claims.log`, `evidence/toolchain.txt` and every file under
`evidence/snap/` are untouched by commit `8071cd3` — `git diff --name-only`
across those paths returns nothing, and the log still hashes to
`fbbe9fae82267a67d220b71536095e82edc38776ed845bc4017b478252332143`. Nothing was
edited in place to make an old citation true; the three new checks live in a new
script, log and snapshot directory. That is the right shape for a revision whose
findings were about what the prose said, not about what the run observed.

The new run, `evidence/r57-claims-r2.log`, gives 13 `^PASS`, 0 `^FAIL`, 0 `^SKIP`
counted with `/usr/bin/grep -c` over the whole file, and its last line is `failed
assertions: 0`. The worktree fix the synthesizer reports is present and correctly
reasoned: `evidence/r57-claims-r2.sh:83-85` carries the comment "This repository
is a git WORKTREE, whose `.git` is a FILE, not a directory." and tests `[ -e
"$REPO/.git" ]`, with a `skip` arm for an extraction that has no `.git` at all.

**The diff is only what is claimed.** Ten hunks at default context, matching the
decision's own "Ten passages changed", and each maps to a named repair: the
title and revision note; the `snap/` inventory (JF-1); the `R5.9`/`R10.1`
back-reference (JF-2); the py and ts citations and the example's Windows comment
(JF-3, two hunks); the four attribution sites — paragraph heading, injection
argument, *Tradeoffs* sentence, `## Parameters` prose (JF-4, four hunks); the
adoption comparison (JF-5); and the closing "what changed, and what did not"
addendum. No hunk touches the recommendation, the gates, the engine section's
disagreements or the unproven rows.

## Completeness

**JF-1 — closed.** The sentence now reads "`snap/` holds **11** files, of which
**9 are tracked in `HEAD` and 2 are not**", names both superseded numbers, and
points at the recount. I re-derived both independently: `find snap -type f` gives
11, `git ls-tree -r --name-only HEAD` gives 9 under `snap/`, and the two absent
files are the `.crate` tarballs excluded by `.gitignore:12`
`research/runs/**/*.crate`. `evidence/r57-claims-r2.log` prints the census file by
file with each file's tracked or gitignored status, which is stronger than the
bare pair revision 1 stated.

**JF-2 — closed.** Both rules are now quoted rather than back-referenced, and
both quotations are byte-exact against blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`, which I read myself with `git
cat-file -p`. `R5.9`'s heading and first sentence match the blob's lines 343–344,
and the decision's parenthetical that the remainder "is about `--offline` and
`--refresh`, which this item does not use" is an accurate description of the rest
of that rule. The `R10.1` sentence matches the blob's line 545 exactly, and the
decision correctly labels it as "extracted from the middle of its paragraph"
rather than presenting it as the whole rule.

**JF-3 — closed, and the correction it uncovered is real.** I read both pins
directly, not the snapshots: `git -C ~/c/py-launch-blueprint show
b08bccfb:src/py_launch_blueprint/core/paths.py` has `APP_NAME = "plbp"` on line
**58**, the resolve-once rule "Resolve once; never read the raw env vars
elsewhere." on line **50**, and "(Windows has no data/state split)" on line
**36**; `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/xdg-paths.ts` has
`export const TOOL_DIR_NAME = 'ts-projects';` on line **14** and `export function
configDir(env: Record<string, string | undefined>, homedir: () => string)` on
line **21**. Every line number the decision now cites is right, `xdg-paths.ts` is
named, the example's Windows comment carries its citation again, and
`raw/opus.md`'s `paths.py:56` and `xdg-paths.ts:13` are indeed wrong — 56 is not
the constant and 13 is the doc comment above it. The committed
`evidence/snap-r2/py-paths.py` and `evidence/snap-r2/ts-xdg-paths.ts` are
byte-identical to the pins on every cited line.

**JF-4 — closed.** All four attribution sites are repaired, and the two surviving
occurrences of the old wording are explicit supersession quotes, which is the
correct way to retire a claim rather than erase it. The new split is exactly the
one the finding asked for: edition 2024 plus `unsafe_code = "forbid"` rules out
internal environment reads and therefore forces injection; the struct is then
carried by resolve-once, R01's composition root, and the embedding consumer that
must supply its own roots. Revision 2 goes further than the finding required and
argues against itself with evidence — it now records that ts's `configDir` is a
*free* function taking injected parameters, and that an injected free function
`pub fn config_dir(s: &impl BaseStrategy) -> PathBuf` "is hermetically testable
and violates nothing". Conceding the counter-example and then giving three
reasons that survive it is a stronger argument than revision 1 made. The
*Tradeoffs* sentence is likewise corrected to say the child-process test "is a
cost of injection, not an argument for a value type", which is right.

**JF-5 — closed, and the backwards-ratio correction is stated honestly and
changes no weighing.** The figures are now given with the endpoint `GET
https://crates.io/api/v1/crates/<name>`, the field `crate.recent_downloads`, and
the retrieval date 2026-09-16, which matches the snapshot files' creation. I
recomputed both ratios from the committed JSON: `etcetera` 32,829,812 against
`directories` 12,362,480 is 2.656×, stated as "2.66× *more*"; `dirs` 77,979,289
against `etcetera` is 2.375×, stated as 2.38×. The attribution is also right —
`raw/opus.md:688` reads "*Raw adoption depth.* `dirs` has ~2.4× the 90-day
downloads", so the multiplier was always `dirs`'s and revision 1 attached it to
`directories`.

The correction is disclosed prominently rather than absorbed: a headed paragraph
in the revision note says the figure "was not merely unsourced, it was false in
direction", and the *Tradeoffs* passage says plainly that "revision 1 was wrong
to say it did". On whether it moves anything — it does not, and the decision
bounds it correctly ("weakens nothing the decision relies on — the pick never
rested on download counts"). The direction of the error is favourable to the
recommendation, which is precisely when a self-correction is easiest to skip and
most important to make: the recommended crate has *more* adoption than the
excluded one, so revision 1 was conceding a cost it was not paying. The residual
tradeoff is real but inert — it exists only against `dirs`, which this decision
excludes together with `directories` on the same macOS `state_dir() -> None`
fact, and popularity is subordinate to the gates by the survey method's own rule.
No gate, no exclusion and no ranking moves.

One matter I considered and am **not** raising as a finding, recorded so the
controller can see it was weighed: revision 2's second script has no
toolchain-command-status block of its own inside `## Empirical check` the way
revision 1's does. It is named there (in the corrected `snap/` sentence) and
fully accounted for at the end of `## Engines` with its counts, its snapshots and
the statement that nothing cited by revision 1 was edited in place. Nothing in
`## Empirical check` misstates or omits a fact about that run, the run compiles
nothing, and every assertion it makes I reproduced from the pins and the blob
directly. That is a placement preference, not a defect.

## Findings

None. All five round-1 findings (JF-1, JF-2, JF-3, JF-4, JF-5) are closed as
required, each verified against the primary artifact rather than the repair
report. Revision 2 introduces no new finding: every changed passage is accurate,
every new citation resolves, every new figure carries its endpoint and retrieval
date, and the two corrections that go beyond the findings — `raw/opus.md`'s wrong
line numbers and the backwards adoption ratio — are reported rather than made
quietly.

## Assessment

**Approve.** The recommendation is unchanged and unmoved: four accessors on one
template-owned `Paths` over `etcetera` 0.11.0 `choose_base_strategy()`,
namespaced `rslbp`, no runtime accessor, with `directories` 6.0.0 excluded on the
macOS `state_dir() -> None` fact read in the crate's own `src/mac.rs` at a pinned
sha256 and corroborated by the macOS spike. Nothing in revision 2 touches the
crate, the version, the accessor set, the namespace, the Runtime omission, the
F249 disposition, the acceptance criteria or the parameters. What changed is
prose about evidence and attribution, and all of it changed in the direction of
claiming less and citing more.

Acceptance still requires the empirical verdict, which does not exist for any
revision of this item: there is no `review/audit-codex.md` in this run directory
because the Codex account is out of usage. Revision 2 records that limit itself,
in the closing paragraph of `## Engines`, rather than letting the missing audit
pass unmentioned. This approval is one of the two verdicts acceptance needs.
