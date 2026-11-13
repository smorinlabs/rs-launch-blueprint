decision-sha256: d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a
actor: audit-fable-2026-09-18T020601Z-f304731ab06f-r10
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# R69 web-framework-stack — judgment audit (round 10, revision 10, 2026-09-18)

Fresh context. I produced none of this item's raw reports, no revision of its decision, and
neither audit of any earlier round. The empirical (Codex) leg of this round is deferred under
owner ruling W1-CODEX, recorded in `docs/port/OWNER-ACCEPTANCES.md` (the R02 row reads
"judgment-only acceptance under W1-CODEX; publication waits for the empirical audit"), so this
is a solo judgment audit and every mechanical claim below was executed by me rather than taken
from the synthesizer's report.

## Principle and agreement level

**The shared principle is unchanged and was not reopened.** Revision 10 answers one owner
ruling, W1-R02 of 2026-09-17, and nothing else. I read the ruling at its primary sites rather
than through a paraphrase: `docs/port/OWNER-REVIEW.md` heading *2026-09-17 — R69
`web-extra-surface` revised to name the optional web member (W1-R02)* (line 151), and
`docs/planning/p02/owner-decisions.md` section 13 row W1-R02 (line 502). Both record the same
disposition — R02 `crate-boundary-enforcement` is accepted at revision 1 with its four-package
workspace, its `CONFLICT:` against R69's owned value is resolved as R02's **option 1**, and R69
is revised. `docs/port/OWNER-ACCEPTANCES.md` row R02 states the resolution in the same terms.

**R02's `CONFLICT:` line is the authoritative specification, and the decision quotes it
faithfully.** It is one unbroken line at
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:184` (file sha256
`78788f7fe194341669eb4fc53aeed5fded3cd5886380c58ffe90928882f076bf`, recomputed here). The
revision-10 note renders it as an eleven-line blockquote; I unwrapped that blockquote
programmatically (strip the `> ` prefix, join on single spaces) and compared it to R02's line:
**equal, byte for byte.** R02's own *The R69 disposition* section states the same six clauses in
prose and answers the deferral — "the crate that hosts the binary targets is the root package
`rs-launch-blueprint`" — which is the ground for clause 1.

**The agreement level is right.** The value continues to state one Cargo-feature contract for a
template P03 will build, not an implementation. Revision 10 implements nothing, and the role
contract's rule that a decision must not implement its own recommendation is respected.

## Design and evidence

**(a) My own diff, with the supersession tail excluded, and every hunk classified.** The
supersession heading is the only whole-line `## Supersedes` in the file, at line 2685; the
preserved tail begins at line 2691. I diffed `head -2684` of the revision-10 decision against the
published revision-9 topic file (`research/topics/69-web-framework-stack/DECISION.md`,
sha256 `d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`, recomputed). The
diff has **20 hunks**. Every one classifies; **none is unclassified**:

| Class | Hunks | What they are |
|---|---|---|
| Mechanical | 9 | The date-first H1 title; the revision-10 note; the **seven** backticked supersession-heading tokens rewritten to "supersession section" (one each in the retained notes of revisions 2, 3, 4, 5, 6, 7 and one in the revision-9 note — I confirmed the retained revision-8 note carries none); the revision-history line extended with revision 10 and the three run ids; and the blank line that separates the current entry from the section heading |
| One of the six ruled clauses, or a prose or table site that states the same fact | 9 | Published 678/679/683 (member table); 1400–1403 (requirement-operator paragraph); 1406 and 1411–1417 (migration lead-in and file map); 1428–1447 (C13 layout, two hunks); 1453–1454 (profile manifest enumeration); 1586 (the `- owns` line); 1627–1629 (open items, R02 entry); 2199 (C13 hand-off row); 2342 (Disagreement 3 path substitution) |
| Judged consequence of W1-R02 beyond the literal six clauses | 2 exclusively, plus 3 sites inside hunks of the row above | The five sites adjudicated under *(e)* below |
| Something else | **0** | — |

**(b) The new owned value is the old one with exactly the six ruled substitutions, and each
matches R02's line.** I took the revision-9 `- owns web-extra-surface` line verbatim from the
published topic file, applied eight textual replacements mapping onto the six ruled clauses, and
compared the result to the revision-10 line: **identical.** Each replacement occurred exactly
once in the source, so nothing was substituted twice and nothing else moved. Clause 2 is two
replacements (`axum` and `tokio`) and clause 6 is two (the gated tree's second mention and the
skip-gating key); the other four are one each. Quoting both sides for each clause:

| # | R02's `CONFLICT:` line says | Revision 10's owned value says |
|---|---|---|
| 1 | "declared on the root package `rs-launch-blueprint`" | `declared on the root package rs-launch-blueprint` (replacing `declared on whichever crate hosts the binary targets (R02 decides which)`) |
| 2 | "`web = [\"dep:rs-launch-blueprint-web\"]` … with `axum` 0.8.9 and `tokio` 1.53.1 declared non-optionally in `crates/web/Cargo.toml` (feature list unchanged)" | `web = ["dep:rs-launch-blueprint-web"], with axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync` |
| 3 | "the gated tree reading `crates/web/src/` rather than `src/web/`" | `(1) the library module crates/web/src/ containing …` and `as modules inside that same gated crates/web/src/ tree` |
| 4 | "the web integration tests living in `crates/web/tests/` with no file-level `#![cfg(feature = \"web\")]` needed because the whole member is optional" | `(3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional, and` |
| 5 | "`tower` 0.5.3 as `crates/web`'s dev-dependency" | `tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature` |
| 6 | "the skip-gating paths reading `crates/web/**` instead of `src/web/**`" | `path-based skip-gating keys on crates/web/**, the serve binary's source file and the web test files` |

**Both feature lists survive verbatim**, as R02's parenthesis "(feature list unchanged)" requires,
and so does every clause R02 lists as preserved: the four-gated-things count, the
`[[bin]] <app>-serve required-features = ["web"]` shape and its CLI Design Standard v1.4.14 R4.1
core, R67's exit integers 143/130/1/0 returned as `ExitCode`, the `otel`/`metrics` nesting, and
`bacon` 3.25.0 as a non-dependency. **No recommendation, alternative ranking, reference-row
disposition, exit integer, gated-thing count, version pin, exclusion, fitness-gate answer or
evidence result moves anywhere in the file.** I checked the last of those directly: no hunk of my
diff touches `## Empirical check`'s results, and every evidence artefact is byte-identical (see
*(d)*).

**(c) The supersession tail and the heading's uniqueness.** `tail -n +2691` of the revision-10
decision is **byte-identical** to the published topic file — `cmp` reports no difference and the
extracted bytes hash to `d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`, the
owner-accepted sha. Searching lines 1–2684 for the substring `## Supersedes` returns **zero**
hits, so `check_history`'s first-substring split lands on the real heading. The current entry is
titled `# 2026-09-17 — R69 — web-framework-stack — decision (revision 10)`, the date-first H1 form
the republication recipe requires above the split.

**(d) Carried bytes, and the two new scripts rerun by me.** I enumerated the source run's tracked
files with `git ls-files` over `research/runs/R69/2026-09-17T014646Z-d5b96f477092`, restricted to
`raw/`, `review/evidence/`, `review/.gitignore` and `review/identities.json`: **309 files**. I
`cmp`ed each against its counterpart in the revision-10 run — **309 compared, 0 differing, 0
missing** — and the only files the revision-10 run adds are the eight new r10 artefacts (two
scripts, two logs, four diffs). This independently reproduces `CARRIED-FROM.md`'s list and check
`S8c`. I also reproduced the `git hash-object` proof commit `3860f0b`'s body claims: for all
**seven** carried `review/evidence/*.sh` files, `git hash-object` on the revision-10 copy equals
the blob `git ls-tree HEAD` reports for that path in the publishing run, with the seven object ids
the commit body lists.

I reran both new scripts from the repository root, as their headers require:

| Run | `owned-value-check-r10.sh` | `supersession-check-r10.sh` |
|---|---|---|
| In place | exit 0, stderr empty, log **byte-identical** to the committed log | exit 0, stderr empty, log **byte-identical** to the committed log |
| Clean `git archive HEAD` extraction (no `.git`) | exit 0, output **identical** to the committed log, `PASS: 53 FAIL: 0 SKIP: 0` | exit 0, `PASS: 20 FAIL: 0 SKIP: 3` — `S10a`, `S10b`, `S10c` **SKIP by name** ("no .git in this tree (a git archive extraction); git blob comparison not possible") and nothing else differs |

My archive diff matches the committed `supersession-check-r10-archive.diff` exactly, and the
other three committed diffs are empty, which I confirmed by size. The claimed `53/0/0` and
`23/0/0` are the summary lines the logs actually print, so both are stated within what their logs
show. The logs were not regenerated after commit `c6b7d2b` moved the decision's sha from
`6560d28b…` to `d34ab6e8…`; that commit changed eight lines without changing the line count, and
my rerun confirms both logs still reproduce byte-identically, so the claim holds rather than
being asserted. The two scripts carry `set -euo pipefail`, call `/usr/bin/grep` by absolute path,
assemble the heading token at run time so no copy of it lands above the real heading, and carry
non-vacuous controls: `V5a`/`V5b` reinject the superseded `src/web/` form and require the `V4a`
matcher to fire on it, and `S6a`/`S6b` mutate one byte of the tail and require both the digest
and the `cmp` to reject it.

**(e) The five sites beyond the six clauses — all faithful, none overreach.**

1. **The `re-verify:` line (published 1582).** R02's clause is **replaced, not deleted**:
   "when R58 … or R02 (crate-boundary-enforcement) publishes" becomes "when R58 …
   publishes, when R02 … publishes a decision that moves off the owner-accepted four-package
   workspace this revision is written against". This is correct on the facts — R02 is accepted
   but **not published** (`docs/port/OWNER-ACCEPTANCES.md` R02 row: "publication waits for the
   empirical audit") — so the watchable event genuinely narrows rather than disappears. It
   follows the revision-7 JF-4 precedent the decision cites. Faithful.
2. **The `## Parameters` sentence (published 1593).** "No `CONFLICT:` line is raised by this
   decision" is **left standing** and annotated with a "Revision 10:" sentence saying the line
   that moved the value is R02's, raised in R02's own `## Parameters`. The original sentence is
   true — R69 raises none, and none of its five raws did — so this is the preservation-target
   discipline applied to a sentence that was not even wrong. Faithful.
3. **The acceptance-criteria lead-in (published 715) and the scoping of criteria 1 and 5.** This
   is one added clause on the lead-in paragraph. It does not touch a criterion's text, a script
   or a log — my diff confirms only the lead-in line changed, and criteria 1 through 6 are
   byte-identical. It is required by honesty rather than optional: criteria 1 and 5 were verified
   on a manifest probe of the **single-package** shape this revision supersedes, and leaving the
   lead-in unscoped would let them read as evidence for the four-package shape. I verified the
   cross-reference it adds: `research/runs/R02/2026-09-17T033527Z-40929a603f91/review/evidence/r02-workspace-probe.log`
   exists and contains passing `B1` ("the optional web member is not compiled by a root-scoped
   default build"), `B2` ("enabling the feature pulls the optional member in"), `B4` ("the
   feature-gated serve binary is skipped by default (required-features)") and `F` ("the manifests
   project to exactly the intended four-row edge set") — which are exactly the two observables
   criteria 1 and 5 name. Faithful, and it adds no evidence result of its own.
4. **The `src/lib.rs` re-export note in the file map.** Revision 9's row read `one line:
   #[cfg(feature = "web")] pub mod web;`, which cannot resolve once clause 3 moves the tree, so
   the row **had** to change. Revision 10 writes an illustrative `#[cfg(feature = "web")] pub use
   rs_launch_blueprint_web as web;`, marks it **illustrated, not specified**, and assigns the form
   to R02 and R04. I verified the two supporting claims: R02's "published facade" clause is quoted
   verbatim from its line 13, and R02 contains **zero** occurrences of "pub use" or "re-export",
   so "R02 is silent on it" is accurate. The string `pub use` occurs **once** in the whole
   revision-10 file, in that row — it is not in the owned value, which my reconstruction in *(b)*
   proves unchanged outside the six clauses. Faithful and correctly hedged; see JF-3 for the one
   residue I hand forward.
5. **The C13 layout paragraph, the open-items R02 entry and the C13 hand-off row.** Each quotes
   the superseded revision-9 sentence and answers it rather than silently rewriting it; the
   feature-vertical half of C13 is kept and only the single-crate half is marked superseded. This
   is the honest form for a reference-row disposition that an owner ruling has overtaken, and the
   **disposition itself does not move** — C13 remains "Agree", reconciled under *Migration
   implications*, with the crate boundary R02's. Faithful.

**(h) The retained notes are intact.** The retained notes of revisions 2 through 7 each show
**exactly one** changed line in my diff, and in each it is only the backticked heading token
becoming "supersession section". The revision-6 overlap table at published 218–225 (head line
402, "Layout — single crate, feature-vertical modules, workspace later (C13) … R02's, still
open"), the evidence script's search regex and the revision-6 record of its own edits are all
byte-identical, which is right: they record what an earlier revision found and was true when it
was written. The revision-9 note's **heading** is rewritten into the retention form, which the
decision discloses; I checked it against the house form and it matches revision 8's exactly
("retained as the record of that revision. It was approved by … Its own heading recorded it as:
…"), with revision 9's original heading sentence preserved word for word after the colon. Its
body is otherwise untouched apart from the one token.

**No unmarked contradiction survives.** The `V8a`–`V8d` controls pin `src/web/`, `web =
["dep:axum", "dep:tokio"]`, `pub mod web` and `(optional, default features)` as marked quotations
only. I ran the search those controls do **not** cover — "single crate", "single-crate", "single
package", "single-package", "multi-crate", "workspace" over the whole current entry — and every
hit is either inside a retained note, inside a marked quotation of revision 9's wording, a
statement about R02's four-package workspace, or about another codebase's workspace or the CI
matrix. Nothing in the current `## Decision` prose still asserts a single-crate topology.

## Completeness

**(f) The five `- assumes` lines.** I parsed `docs/port/PARAMETERS.md` and compared each value
byte-for-byte against the decision's line: `msrv-policy`, `rust-edition`, `target-os-matrix`,
`license` and `http-transport-injection-seam` are **all five byte-identical** to the live rows.
The `- owns web-extra-surface` line differs from the live row, and must: the live row still
carries the revision-9 value, and publication is what rewrites it. That is the expected
pre-publication state, not a defect.

**Fields and gates.** Both `## Parameters` line forms are bare values with no backticks, citation
or commentary, as the validator requires. Gate 1 remains recorded as `inapplicable` under the
owner's 2026-09-12 Q7.B ruling, unmoved. Every required section is present and the H2 order of
the current entry is `## Decision` / `## Parameters` / `## Empirical check` / `## Engines`, which
check `S4` also asserts.

**(g) The loose ends `CARRIED-FROM.md` states.** Both are honestly disclosed and neither is this
revision's to repair.

- **`review/identities.json` carried unedited, naming the round-9 actors.** This is correct, not
  a gap: the file cannot name round-10 actors before the round-10 audits exist. `CARRIED-FROM.md`
  says so explicitly and the revision note repeats it. The republication recipe makes editing
  `audits.*.actor` and `synthesis.actor` the publisher's step, so this is a publication
  precondition rather than a decision defect (JF-4).
- **`review/empirical/` and the five cited empirical script paths.** I verified the substance.
  The source run `2026-09-17T014646Z-d5b96f477092` has **no `review/empirical/` directory at
  all**, so `git ls-files` could not carry one; in the run that produced them,
  `research/runs/R69/2026-09-12T204004Z-d02022bf6f42`, the directory **is tracked** (25 files, 8
  of them `.sh`, including `parameters-check.sh` and `feature-shape-check.sh`). The decision's
  `## Empirical check` anchors them by full repository-relative path — "Five of the six scripts
  live in `research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/empirical/`" — so the
  citations resolve in the repository as written. The round-9 empirical audit reran all six from
  that directory and recorded byte-identical output. This is therefore a **pre-existing,
  correctly stated property** that both round-9 audits approved and the owner accepted at
  revision 9, not a citation defect revision 10 must repair — and repairing it would mean moving
  evidence, which W1-R02 forbids. One word of `CARRIED-FROM.md`'s phrasing is imprecise (JF-2).

## Findings

**JF-1 — non-blocking (record integrity).** The enumeration table's row for the
acceptance-criteria site cites published lines "715–745". Published line 715 is a blank line; the
lead-in paragraph begins at 716 and the edited line is 719. Criterion 5 ends at published line
747, not 745. The row's **disposition is accurate** — my diff confirms the criteria's own text,
the script and the log are byte-identical and only the lead-in moved — so nothing substantive
rests on the range. Given commit `c6b7d2b` exists precisely to correct a mis-binned line and the
round-7 empirical audit rejected a revision for that class of defect, I record it rather than
leave it unrecorded. **No repair is required under W1-R02**, which moves no line of the
enumeration's subject matter; the range can be tightened at the next revision if one occurs.

**JF-2 — non-blocking (wording).** `CARRIED-FROM.md`'s "What was NOT carried" table describes
`review/empirical/` as "untracked in the source run". It is **absent** from the source run
entirely — there is no such directory there. The consequence the same row states is exactly
right, and the substance of the disclosure is correct, so this is one imprecise word in a run
artefact, not in the decision. **No repair required.**

**JF-3 — non-blocking (handed forward, not a defect).** The file map's `src/lib.rs` row is the
one place revision 10 states an ownership claim the owned value does not literally carry: "What
this item owns is that the gated surface is reachable under the name `web`, and that it is absent
when the feature is off." The `- owns` line fixes the gated tree, the tests, the binary and the
skip-gating keys, but says nothing about a facade re-export. The row is correctly marked
**illustrated, not specified**, correctly assigns the form to R02 and R04, and correctly reports
that R02 is silent (verified: zero "pub use" or "re-export" hits in R02). I judge it faithful —
the superseded line was unresolvable and something had to stand there. The residue is that the
**facade's re-export form is currently owned by nobody**. I hand that to the controller for R02's
or R04's re-verify rather than leaving it unstated; it does not belong in R69's value and is not
this revision's to settle.

**JF-4 — non-blocking (publication precondition, already disclosed).** `review/identities.json`
still names the round-9 actors and the revision-9 synthesizer. Before this run is packaged, the
publisher must set `audits.empirical.actor` and `audits.judgment.actor` to the round-10 actors
(this file's actor is `audit-fable-2026-09-18T020601Z-f304731ab06f-r10`),
`synthesis.actor` to the revision-10 synthesizer, and `empirical` to the round-10 rerun. Stated
plainly in `CARRIED-FROM.md` and in the revision note; no repair to the decision is required.

All four findings are non-blocking and none requires a repair under owner ruling W1-R02, so the
unresolved set is empty.

## Assessment

Revision 10 does exactly what owner ruling W1-R02 authorises and nothing more. I reconstructed the
new owned value from the published revision-9 line by applying only the six ruled clauses and got
the revision-10 line byte for byte, so **no owned-value clause moves beyond the six ruled
substitutions**; each substitution is quoted against R02's `CONFLICT:` line, which the decision
reproduces verbatim. Classifying my own 20-hunk diff leaves **nothing unclassified**: 9 hunks are
mechanical, 9 carry a ruled clause or a site stating the same fact, and the 5 sites that go beyond
the literal clauses are each a faithful consequence — a re-verify clause narrowed rather than
deleted, a true sentence annotated rather than rewritten, a probe honestly scoped to the shape it
ran on with R02's executed checks named, an unresolvable file-map line replaced by one explicitly
marked as illustration, and reference-row prose that supersedes only its single-crate half. **No
recommendation, ranking, disposition or evidence result moves.** The supersession tail is the
published bytes, verbatim and uniquely split; all 309 carried files are byte-identical by my own
comparison; both new scripts reproduce their logs in place and from a clean archive, with the
only archive difference being three git-reading checks that SKIP by name; and the five `- assumes`
lines are byte-identical to the live registry. The four findings are record-keeping and
hand-forward items that the ruling gives this revision no licence to touch.

I therefore **approve** revision 10, with no unresolved findings.
