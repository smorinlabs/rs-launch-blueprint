decision-sha256: 1348f6b314dbb938552f6aae844cb9d68b5b3b753151cc18f287cc291c96ef49
actor: audit-fable-2026-09-17T033527Z-8dfef31d60fc-r3
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# Judgment audit — R54 config-discovery-tiers, revision 3 (round 3)

The two earlier rounds are preserved byte-identically (`cmp`-verified) at
`review/audit-fable.r1.md` (sha256
`144a21e11369b8e526217e4772397e0c6201694bd4ecda75bb0bb4729071f6b6`, which bound
revision 1 at `b0fb750d…` and returned `reject` on JF-1 and JF-2 blocking plus JF-3
and JF-4 non-blocking) and `review/audit-fable.r2.md` (sha256
`2ddb2a9ed4c9a8ce5fc614c982e2612a0eda8489014661f2583641e2f81030ac`, which bound
revision 2 at `f03dbef4…`, found JF-1..JF-4 closed at every site, and returned
`reject` on the single non-blocking JF-5). This round judges revision 3 at the sha
above, which arrived as commits `5c9abc9` ("correct the member-level owns count
(JF-5)") and `f240109` ("record the clean-archive rerun of check-r3.sh"). The
empirical (Codex) audit is still deferred under `W1-CODEX`, so this round again ran
alone and acceptance still needs a second approving verdict.

Every claim below was checked against the primary artifact rather than against the
revision note or the new log: the Doxa/OpenAI twin at the lines cited, the decision
text at the line cited, the eleven earlier evidence artifacts re-digested by me and
cross-checked against git, and `check-r3.sh` read for whether its assertions can
fail.

## Principle and agreement level

Unchanged, and untouched by this revision. I read the complete
revision-2-to-revision-3 diff rather than sampling it: it is the title line, the
new revision-3 note with its single-row finding table, the extended revision
history paragraph, one new paragraph in `## Empirical check` describing
`check-r3.sh`, and the corrected sentence in Disagreement 6. Nothing else in the
file changed — not the shared requirement, the `R5.1`/`R5.2` quotations, the C1–C6
agreement table, the six-rung table, `J1`–`J4`, A1–A5, the two carried
`BASELINE-REVIEW:` lines and their dispositions, AC1–AC11, the couplings, the
`re-verify:` line, `## Parameters`, the figures, or Disagreements 1–5 and 7.

## Design and evidence

**JF-5 is closed, and the corrected figure is the right one.** The sentence at
`DECISION.md:761` now reads "`project-search` is **not** among them — it is one of
**twelve** *member-level* `owns` lines (`:398-401`, `:536-539`, `:678-681`), at
`:401`". I re-derived every part of that independently of the new script: an
anchored count of lines beginning "- \`owns " in
`raw/doxa-openai.normalized.md` returns **12**, their line numbers are exactly
`398 399 400 401 536 537 538 539 678 679 680 681`, and the answer-level form
(lines beginning "\`owns ") still returns **8**. The three ranges in the sentence
are therefore exact rather than approximately right, and the eight-versus-twelve
distinction the sentence draws is a real difference between two forms in the same
file rather than a restatement.

**The count is now asserted non-vacuously.** This was the substance of JF-5 — the
figure was the one claim in revision 2 whose only support was the sentence itself —
and `check-r3.sh` answers it with ten checks that each compare a computed value
against a literal and take the `fail` branch otherwise. `M01` pins the count at 12;
`M02` pins the whole line-number list as a single string, so a line moving in that
file breaks it; `M03`–`M05` pin four per range, so twelve lines distributed some
other way would fail even if the total held; `M06` pins the twelve names in order
(`system-config-roots user-config-root config-relative-path project-search
table-merge leaf-merge array-merge source-order config-selector-cli
config-selector-env selector-precedence cli-data-overrides`), which I confirmed
matches the file; `M07` proves the answer-level count is a different number and
still 8; `M08` and `M10` pin the decision's own corrected wording and its line;
and `M09` guards the superseded "one of eight" to exactly one occurrence, inside
the revision note's JF-5 row. I verified that guard myself: `one of eight` occurs
once in the decision, and that occurrence is in the `| **JF-5** …` row. None of the
ten is a search that cannot miss.

**The script itself is sound.** `pass`, `fail` and `skip` are called in the
enclosing shell with no assertion fed from the tail of a pipeline, `FAILURES` gates
the exit status, and there is no `curl`, no `gh`, no URL and no `git` invocation —
so the header's "network none, and no git history is required" is true by
construction rather than by assertion. That is also why the clean-extraction rerun
needs no skip at all: `check-r3-archive.log` differs from `check-r3.log` in exactly
one line, the `repo-root` header, which I confirmed by diffing the two logs myself.
`r3-rerun.diff` and `shellcheck-r3.log` are both zero bytes, consistent with the
in-place rerun matching and shellcheck reporting nothing. The log carries 32
assertions — 11 group `B`, 10 `M`, 5 `P`, 6 `E` — with `failures=0 skipped=0`,
matching the decision's "32 checks, 32 PASS, 0 FAIL, 0 SKIP".

**Nothing earlier moved.** Group `B` now re-asserts **all eleven** revision-1 and
revision-2 artifacts by digest, and I recomputed every one: `check.sh`
`7e22e8ff…`, `check.log` and `check-rerun.log` both `a1f676c9…`, `walkup_probe.rs`
`faa0e5de…`, `shellcheck.log` `e3b0c442…`, the sorted snapshot manifest
`fa53d95a…`, `check-r2.sh` `165bd08d…`, `check-r2.log` `41aea179…`,
`check-r2-archive.log` `3dcb5981…`, and `r2-rerun.diff` and `shellcheck-r2.log`
both the empty-file digest. Each matches the log, and `git diff 3ee43ee HEAD` over
those eleven paths and `snapshots/` is empty, so the byte-identity claim holds in
two independent ways. `P01`–`P05` re-assert the five `- assumes` lines against the
registry, which I verified independently in round 1 and which no diff hunk has
touched since.

## Completeness

The title is `# 2026-09-18 — R54 — config-discovery-tiers (bundle, Deep) — decision
(revision 3)`, date first, and `E06` pins the H2 set to exactly `## Decision`,
`## Parameters`, `## Empirical check` and `## Engines`, which I confirmed. The
revision note quotes the round-2 audit's own words for the finding and for the
superseded wording, states `verdict: reject` for that round explicitly, and records
the audit's own assessment that the disposition never depended on the figure —
which is the honest framing, since the repair adds a check rather than only a word.
No `## Supersedes` section is added, correctly: the item is unpublished. Revision 2
remains recoverable at `git show 5c9abc9~1:<run>/review/DECISION.md`, and the
history paragraph now carries all three revisions. R54 still owns no parameter and
consumes only R67's.

One wording note, not a finding: the history paragraph says revision 2 was
"approved on those four by the round-2 judgment audit, which raised JF-5". Round 2
returned `verdict: reject`; the phrase is scoped to the four findings, which that
audit did record as closed, and the same note states the round-2 verdict verbatim
two paragraphs above, so a reader cannot mistake it for an approval of revision 2.

## Findings

None. JF-5 is closed at its one site, with the corrected figure verified against
the twin and the claim now carried by checks that can fail. The four earlier
findings remain closed: I re-read their sites in this revision and nothing in the
diff reopened them — R55 is still named at revision 3 in all three places,
Disagreement 7 is intact, the eight answer-level parameters are still listed in
full, and the `:193` attribution and the two byte-identical carried
`BASELINE-REVIEW:` lines are unchanged.

## Assessment

The recommendation does **not** move, and nothing in revision 3 could move it: the
six-rung chain, `etcetera` 0.11.0 reached through R57's `Paths`, the two `std`
resolvers, the `clap` `env` attribute plus its emptiness filter, the A2′ merge over
R55's per-layer-sanitized `toml::Table`s, the four force labels, the eleven
acceptance criteria and all five parameter values are identical to revision 1. The
whole three-revision arc changed exactly four sentences of substance — a sibling's
revision number, a missing disagreement, a parameter count and a line citation —
plus one figure, and each repair is now carried by an assertion rather than by the
synthesizer's word.

What earns approval here is not only that the count is right but that the fix
addressed the finding's actual complaint. JF-5 was "no check asserts that number",
and the answer is ten checks that pin the count, the line numbers, the
per-range distribution and the names, with the superseded wording fenced to one
quoted row. The decision as it now stands quotes its normative source verbatim,
grounds its one measured judgement in an executed probe whose approximation it
discloses, settles seven engine disagreements on evidence, labels every carried and
unproven row, and records the missing adversarial engine with both its owner
direction and its mechanical cause. This round approves it, with the standing
caveat that the empirical audit is deferred and acceptance still needs that second
lens.
