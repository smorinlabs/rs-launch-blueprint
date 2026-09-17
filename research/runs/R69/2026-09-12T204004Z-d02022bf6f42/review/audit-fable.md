decision-sha256: d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d
actor: audit-fable-2026-09-12T204004Z-d02022bf6f42-r9
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# R69 web-framework-stack — judgment audit (round 9, revision 9, 2026-09-16)

Round 8 (archived byte-identical at `review/audit-fable.r8.md`) approved revision 8 with no
unresolved finding, as did the round-8 empirical audit. Revision 9 repairs no audit finding: it
closes a **coverage gap** the brief drafter found in revision 6's owner-decision-11
reconciliation — three rows of the owner-supplied document's reference `Cargo.toml` that carried
no disposition at all. This round audits revision 9 as a delta against revision 8
(`git show 91bfe39:…/review/DECISION.md`, sha256
`ce7a5dad994e4c5fa87a35674a7172913265cf70cc13456ed105a7018270407a`, recomputed here) and judges
the three new dispositions on their own evidence.

## Principle and agreement level

Unmoved, and the three new rows are handled at the agreement level §11 fixes. Owner decision 11
makes the document a standing **input**: overlapping rows are reconciled with agreement or a
stated ground, and rows belonging to other items are hand-offs, not decisions. Revision 9 adds
one *differs with ground* on a row this item owns outright (the `tokio` feature list, fixed by
this item's own owned value) and two *hand-offs* on rows it does not (`axum-extra`,
`[profile.release]`). No new `BASELINE-REVIEW:` or `CONFLICT:` line is raised, correctly — no
py/ts baseline behaviour and no consumed parameter is at issue in any of the three, and the
mechanism §11 provides for a row nobody owns is exactly the one used: record it, route it, do
not decide it.

## Design and evidence

**Row 9, `tokio = { features = ["full"] }` — *differs, with ground*, and the ground is genuinely
this decision's own rule.** The block quotes gate 5 verbatim — *"`tokio`'s `default = []`, so
every feature is opted into explicitly"* — and I confirmed that sentence is present, unchanged,
at its original gate-5 location, so the ground is not manufactured for this row. It is also the
*same* rule that earlier **added** two features (`time` for the drain deadline, `sync` for the
`oneshot` channel) when a named behaviour required them, which is what makes it a rule rather
than a preference for short manifests. The arithmetic is read at tokio 1.53.1's published
`[features]` map and asserted in `review/evidence/owner-reference-check-r9.log`, section A; I
re-derived all of it from the committed snapshot `snapshots/r9/crates-tokio-features.json`:
`full` is the twelve names `fs, io-util, io-std, macros, net, parking_lot, process, rt,
rt-multi-thread, signal, sync, time`; the six selected plus the `rt` that `rt-multi-thread`
implies cover seven of them; the residue is exactly the five the block names; and
`parking_lot = "^0.12.0"` is an optional **dependency**, so that name is a package in the tree
gate 6 measures rather than a code path. The disposition follows: the added names serve no F338
behaviour, one of them costs a crate against the item's own cost argument, and the owned value
is byte-identical. The block is also careful to say where the document is right — `version = "1"`
is a caret requirement that admits 1.53.1, so the disagreement is the feature list alone, not
the runtime or its version line.

**Row 10, `axum-extra` — a hand-off that neither adopts nor excludes, and says so.** The figure
is checked before it is set aside, which is the right order: section B and the committed
`crates-axum-extra.json` give 0.12.6 as both newest non-yanked and newest stable, published
2026-04-14 (the same day as `axum` 0.8.9, per the r6 snapshot), MIT, declared `rust-version`
1.80, requiring `axum ^0.8.9` — so the decision states plainly that the document's figure is
current, not stale, and that staleness is not the reason. The reason given is the member rule
Disagreement 3 already carries — *a member is a decidable artifact this item owns* — applied
through the crate's own feature bodies: `cookie`/`cookie-private` resolve to `cookie ^0.18.0`
and `typed-header` to `headers ^0.4.0`, both optional dependencies, and no acceptance criterion
in F303/F330/F331/F338/F339 asks for a cookie jar or a typed header. Routing is routing, not
deciding: cookie jars go to the document's own C6, which the overlap map already records as
having no P02 item; typed headers go to "whichever of R72–R76 needs one", which names a range
rather than picking an item. The block closes with *"This item neither selects nor excludes it on
fitness — no gate is answered for it, because it is not a candidate here"*, which is the honest
statement and the same treatment `axum-test` received at revision 6.

**Row 11, `[profile.release]` — the ownership flag is the honest state, and I verified the
negative myself.** A negative census is the one claim in this revision that could not be taken on
trust, so I ran it independently rather than reading the log: over `research/topics/**` the
complete prompt set is **85** files, `/usr/bin/grep -l -E '\[profile|\blto\b|codegen-units|opt-level'`
matches **none** of them, and `docs/port/COMMONALITY.md` carries **no** row naming those keys —
the same three figures the log's section C asserts. The check's own guards are the right ones for
a census: the denominator is asserted and printed, and section D's control runs the identical
`find`/`grep -l` over the identical file set for a string every prompt does carry, reporting 85
of 85, so a zero cannot come from an empty file set. The decision reports that this guard already
caught exactly that failure once while the script was being written, which is a disclosure that
strengthens rather than weakens the result. The two positive halves check out as well: R68's
prompt does scope itself to "distribution channels/artifact *types*" and does place "The Cargo
manifest's build-target declarations" in R49's scope, and R49's owned `build-tool-output-shape`
does read "Cargo's own manifest is the entire declaration surface" while its decision file
contains **zero** occurrences of `[profile`. So "R68 as the controller's reading, with the
ownership recorded as an open scoping question" is the state of the repository, not a hedge; the
alternative — a silent hand-off to R68 — would have asserted an ownership no prompt supports.
The flag is not orphaned either: `docs/planning/p02/execution-ledger.md` carries it forward as an
owner scoping question for the W0-R69 brief, so the open question has a destination outside this
file.

**Nothing else moves, verified at a scope that can support the claim.** The revision-8-to-9 diff
is nine hunks at default context, all of them the revision-9 note, the revision-8 retention
heading, the history line, the three new blocks, two new overlap-map rows, the further-scripts
and auditor sentences in `## Empirical check`, and the revision-9 edit enumeration. The one
`- owns web-extra-surface` line, the five `- assumes` lines and the `re-verify:` line are
byte-identical to revision 8 (I diffed each set of lines directly), the five `- assumes` values
still match `docs/port/PARAMETERS.md`, and the H2 set is still exactly the four headings. Commit
`c1e5131` lists **seven** paths — `review/DECISION.md`, the two new scripts, the new log and the
three files under `snapshots/r9/` — so no existing evidence file is touched. I scope that claim
to the commit deliberately: the range `91bfe39..HEAD` also carries `audit-*-r8` artifacts, which
belong to the round-8 empirical audit's checkpoints and not to this revision, and reporting the
range instead of the commit is the defect revision 8 was written to correct.

## Completeness

- **The new evidence is classified the way the earlier pair was.** The fetcher goes to the
  network and writes committed reduced snapshots; the check reads only committed files and never
  the network; neither is a check of the recommendation, and the decision says so. The auditor
  sentence now names `owner-reference-check-r9.sh` and scopes the not-rerun rule to **both**
  fetchers, which keeps the audit instruction complete.
- **Only published crate metadata is snapshotted** — versions, licences, `rust-version`,
  `[features]` maps, dependency requirements — so no third-party source file enters the
  repository, which is the rule the owner's Q7.B ruling explicitly did not touch. The decision
  states that reasoning rather than leaving it to be inferred.
- **The check's failure capability is demonstrated and its one limit stated.** A mutated scratch
  copy exits `1` on section A's count, and the decision records that section C's census cannot
  execute inside that scratch tree because `find` does not follow the symlinked `topics`
  directory there — so the empty-file-set failure that occurred during authoring is what stands
  as section C's failure evidence. Naming that asymmetry instead of implying a uniform mutation
  test is the right disclosure.
- **The edit enumeration is mechanical and its two near misses are recorded**: the existing
  `axum-extra` mentions under F338 are about where axum's 0.9 breaking changes land, not about
  adopting the crate, and every existing occurrence of "profile" is the CLI standard's Small-CLI
  profile, R58's console/structured profile, or the `target/release` directory — none is
  `[profile.*]` in the manifest sense, which is what makes row 11's absence real rather than an
  artefact of the search. I spot-checked both classifications and they hold.
- **The overlap map now carries all eleven dispositions**, the three new ones cross-referenced to
  the sections where their topic lives, with no new H2 heading — the constraint revision 6 worked
  under and revision 9 keeps.
- **Everything the earlier rounds bound is untouched**: the recommendation, every version pin and
  exclusion, the six fitness-gate answers including gate 1's `inapplicable` row, the R67 exit
  contract and its request, the R4.1 required global core, the JF-4 repair, and the six checks
  with their scripts and logs.

## Findings

None. Each of the three rows is disposed of on evidence read at a primary source, the one row
this item owns is decided by a rule the decision already stated, and the two rows it does not own
are routed rather than answered.

Observations, recorded as not findings and requiring no change. (1) The auditor sentence now
reads "…and likewise decides nothing about the recommendation, **and plus** — since revision 9 —",
where the conjunction doubles; it is the one seam the new clause leaves in an otherwise clean
sentence. (2) The `full` block's "One of the five costs a crate, not just a code path" is true of
`parking_lot` and is the right marginal statement for this stack, but the committed snapshot also
shows `io-util` and `process` naming further optional dependencies (`bytes`, `libc`,
`signal-hook-registry`); those are already in the resolved tree through `axum` and tokio's
`signal`, which is why the marginal claim holds — that half is visible in the snapshot but is not
asserted in the log. (3) `axum-extra`, like `axum-test`, is not added to `## Decision`'s **Not
selected** list; that is consistent, since the list's own pointer is to *Excluded by gate and by
fit* and neither crate is a candidate here. The observations carried from rounds 6, 7 and 8 —
the owned value's "and 0 otherwise" clause, the unasserted prose dates in the r6 rows, and the
trailing relative clause in the replaced `re-verify:` R60 trigger — are unchanged.

## Assessment

Approve. Revision 9 makes the reconciliation complete without making the decision say anything
new about its own recommendation: the `- owns web-extra-surface` value is byte-identical to every
revision since 2, the member table, the tokio feature list, the exclusions, the gate answers and
the `re-verify:` line are untouched, and the three additions are one grounded difference and two
hand-offs. The row that mattered most to get right is row 11, because the tempting move was to
hand `[profile.release]` quietly to R68 and let a later item discover that nobody had been asked;
instead the decision ran a census over all 85 binding prompts and the ledger, found the subject
unclaimed, named R68 as the controller's reading with the prompt text that both supports and
limits it, and recorded the ownership itself as open — which is the state of the repository, and
which the controller's ledger now carries into the W0-R69 brief as an owner question. Five
consecutive rounds across two model families have now tested this text; the recommendation and
the owned parameter value have not moved since revision 2, and no finding remains open from any
round.
