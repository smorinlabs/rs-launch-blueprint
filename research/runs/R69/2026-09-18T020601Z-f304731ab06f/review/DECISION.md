# 2026-09-17 — R69 — web-framework-stack — decision (revision 10)

**Revision note (revision 10). Owner ruling W1-R02 of 2026-09-17 renames the thing the `web`
feature switches on: it now names one optional workspace member, `crates/web`, where it used to
name two optional crate dependencies. Six clauses of the owned value move and nothing else in
this decision does — not the recommendation, not a crate, not a version pin, not a feature list,
not an exclusion, not a fitness-gate answer, not an alternative ranking, not a reference-row
disposition, not an engine adjudication, and not one byte of any evidence script, log or
snapshot.** Revision 10 revises revision 9, which the owner accepted on **2026-09-16** at sha256
`d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d` and which was **published on
2026-09-17** (commit `28909ac`, from the carried-forward run
`research/runs/R69/2026-09-17T014646Z-d5b96f477092`). Those published bytes are preserved
verbatim in the supersession section at the end of this file, which revision 10 adds because
this is the first revision of a **published** R69 decision. This run submitted no provider
operation; its raw reports and its whole evidence tree are carried forward unchanged from the
run that published revision 9, as `review/CARRIED-FROM.md` records file by file.

**Why there is a revision 10, and who decided it.** **R02** `crate-boundary-enforcement` was
owner-accepted at revision 1 on **2026-09-17**
(`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`, sha256
`78788f7fe194341669eb4fc53aeed5fded3cd5886380c58ffe90928882f076bf`; `docs/port/OWNER-ACCEPTANCES.md`
records it as `W1-R02 option A (Wave 1)`). It recommends a **four-package Cargo workspace** — root
facade `rs-launch-blueprint` (lib, the `rslbp` and `rslbp-serve` binaries, composition root),
`crates/core`, `crates/cli`, and `crates/web` as an **optional dependency of the facade** — and it
raised a `CONFLICT:` line in its own `## Parameters` section against this item's owned value
`web-extra-surface`, on the ground that its topology moves `axum` and `tokio` out of the package
that declares the feature, so the feature can only name the optional member. The owner chose
R02's **option 1**: R69 is revised and R02's topology stands. The ruling is recorded at
`docs/port/OWNER-REVIEW.md`, heading *2026-09-17 — R69 `web-extra-surface` revised to name the
optional web member (W1-R02)*, at `docs/planning/p02/owner-decisions.md` section 13 row W1-R02,
and in the execution ledger's entries of 2026-09-17.

**R02's `CONFLICT:` line is the whole specification of the new value, and nothing else is.** R02
writes it as one unbroken line; it is quoted below word for word, with hard line breaks and the
blockquote prefix added to fit this file's width and nothing else changed — unwrapping the quote
reproduces R02's line exactly:

> CONFLICT: R69 web-extra-surface — `web = ["dep:rs-launch-blueprint-web"]` declared on the root
> package `rs-launch-blueprint`, with `axum` 0.8.9 and `tokio` 1.53.1 declared non-optionally in
> `crates/web/Cargo.toml` (feature list unchanged), the gated tree reading `crates/web/src/`
> rather than `src/web/`, the web integration tests living in `crates/web/tests/` with no
> file-level `#![cfg(feature = "web")]` needed because the whole member is optional, and `tower`
> 0.5.3 as `crates/web`'s dev-dependency — reason: the recommended multi-crate topology moves
> `axum` and `tokio` out of the declaring package, so the feature can only name the optional
> member; every other clause of R69's value (the four gated things, the
> `[[bin]] <app>-serve required-features = ["web"]` shape, the exit integers, the `otel`/`metrics`
> nesting, the skip-gating keys, `bacon` as a non-dependency) is preserved verbatim, with the
> skip-gating paths reading `crates/web/**` instead of `src/web/**`.

**The six clauses that move, each with the superseded wording quoted verbatim.** The quotations
are the revision-9 bytes of the `- owns web-extra-surface` line; nothing outside these six
substitutions changed on that line, which is otherwise byte-identical to revisions 2 through 9.

| # | Superseded wording (revision 9, verbatim) | Revision-10 wording |
|---|---|---|
| 1 | Revision 9: `declared on whichever crate hosts the binary targets (R02 decides which)` | `declared on the root package rs-launch-blueprint` — this also discharges the deferral the clause itself recorded, because R02 has now decided |
| 2 | Revision 9: `web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (…) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync` | `web = ["dep:rs-launch-blueprint-web"], with axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (…) and tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync` — **both feature lists are byte-identical**; only the manifest they are declared in, and the word `optional`, move |
| 3 | Revision 9: `(1) the library module src/web/ containing` | `(1) the library module crates/web/src/ containing` — a path substitution and nothing else; the six items the module contains are byte-identical |
| 4 | Revision 9: `(3) the web integration tests, gated file-level with #![cfg(feature = "web")], and` | `(3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional, and` |
| 5 | Revision 9: `tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature` | `tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature` — it names the manifest and still says **not gated** |
| 6 | Revision 9: `as modules inside that same gated src/web/ tree` and `path-based skip-gating keys on src/web/**` | `as modules inside that same gated crates/web/src/ tree` and `path-based skip-gating keys on crates/web/**` |

**What deliberately does not move, clause by clause.** The count "the feature gates exactly four
things and nothing else" and all four gated things; the `[[bin]] name = "<app>-serve"` target with
`required-features = ["web"]`, its org CLI Design Standard v1.4.14 R4.1 required global core
(`-h`/`--help`, `-V`/`--version`, `-v`/`--verbose`, `-q`/`--quiet`, `--config`, `--debug`) and the
clause that R60's parser is a non-optional dependency "whichever crate R60 picks"; the R67 exit
integers 143 / 130 / 1 / 0 returned as `ExitCode` from `main`; the deliberate omission of the
drain-deadline branch pending R67's disposition; the `otel = ["web", …]` and `metrics = ["web", …]`
nesting for R78 and R79; `bacon` 3.25.0 as a contributor-installed tool that is **not** a Cargo
dependency; the list of what the feature does **not** gate; and the consumer-selection clause
(`--features web` or `--all-features`, detected by the feature name). The five `- assumes` lines
are byte-identical to `docs/port/PARAMETERS.md` as it stands today. `axum` **0.8.9**, `tokio`
**1.53.1**, `tower` **0.5.3** and `bacon` **3.25.0** are the same crates at the same versions, and
every excluded candidate stays excluded for the same reason.

**The prose and table sites that had to move with the value, enumerated mechanically before any
edit and listed here in full.** The enumeration was built with `/usr/bin/grep -n` over the
published file for `src/web`, `dep:axum`, `dep:tokio`, `cfg(feature`, `tower`, `crates/`,
`optional`, `R02`, `pub mod web`, `web_api`, `single crate`, `single-crate`, `single package`,
`multi-crate` and `workspace`, and every hit was dispositioned. Line numbers cite the **published
revision-9 file**.

| Line(s) | Site | Disposition |
|---|---|---|
| 678, 679 | `## Decision` member table, the `axum` and `tokio` version cells | Corrected: `(optional, default features)` → `(non-optional in crates/web, default features)`, and the same for `tokio`. The **surface** is still optional; the two crates are not, inside the member |
| 683 | `## Decision` member table, *Optional-surface gate and target shape* mechanism cell | Corrected: `#[cfg(feature = "web")] pub mod web;` named a module of the declaring package that no longer exists there |
| 1400–1403 | the requirement-operator paragraph, which **quotes** the owned value and the migration row | Quotes refreshed to the revision-10 wording; the paragraph's point — that neither wording states a version operator — is unchanged, and its byte-identity claim is scoped to the revision it was written at |
| 1406, 1411–1417 | *Migration implications* lead-in and the whole file map | Rewritten against the four-package workspace: the root `Cargo.toml` row, a new `crates/web/Cargo.toml` row, `src/lib.rs`, three `crates/web/src/` rows, the serve-binary row scoped to the root package, and `crates/web/tests/web_api.rs` with its file-level `cfg` removed |
| 1428–1447 | the layout paragraph reconciling owner-reference row C13 | Corrected: the feature-vertical half stands, the single-crate half is superseded, and the two revision-9 sentences that called R02 open and said "no `CONFLICT:` line arises" are quoted and answered |
| 1453–1454 | the `[profile.release]` paragraph's enumeration of every manifest change | Corrected: the root package's changes and `crates/web`'s changes are enumerated separately. The `[profile.*]` argument itself is unchanged |
| 1582 | the `re-verify:` line | R02's clause is **replaced, not deleted** (the revision-7 JF-4 precedent): R02 is accepted but **not yet published**, so the watchable event becomes its published decision moving off the accepted four-package workspace |
| 1586 | the `- owns web-extra-surface` line | The six clauses above |
| 1593 | the `## Parameters` sentence "No `CONFLICT:` line is raised by this decision" | Left standing and annotated: it is true of **this** decision and its five raws; the `CONFLICT:` line that moved the value is **R02's**, in R02's own `## Parameters` section |
| 1627–1629 | the open-items list, R02 entry | Corrected: R02 is no longer open, and the value no longer "survives either layout" — it names the root package and `crates/web/src/` outright |
| 2199 | owner-reference hand-off table, row C13 | Corrected to name R02's accepted answer |
| 2342 | Disagreement 3, the `axum-extra` hand-off | Path substitution `src/web/` → `crates/web/src/`; the hand-off itself is unchanged |
| 218–225, 1931, 1945 | the revision-6 retained note's overlap table, an evidence script's search regex, and the revision-6 record of its own edits | **Byte-identical, deliberately.** These record what an earlier revision found, ran or did; rewriting them would falsify the record. The overlap row saying the crate boundary is "still open" was true when revision 6 wrote it |
| 715–745, 1355 | the acceptance-criteria lead-in, criteria 1 and 5, and the executed feature-shape check they cite | **The script, the log and every criterion's own text are byte-identical**, because no evidence result moves in this revision. What revision 10 adds is one scoping clause on the lead-in paragraph, naming the shape that probe ran on and the R02 checks that executed the same two observables on the accepted four-package shape |

**Two mechanical edits outside those sites, made for a publication-tool reason and reported
rather than made quietly.** `scripts/research_runner.py:check_history` splits a decision at the
**first substring** occurrence of the supersession heading's text and requires the prior published
bytes below it. **Seven** sentences above that point mention the heading in backticks — one each
in the retained notes of revisions **2, 3, 4, 5, 6 and 7** and one in the revision-9 note; the
retained revision-8 note has none. Each says, correctly at the time it was written, that no
revision had been published so the section did not yet exist. Left as written they would sit
above the real heading and the publication would preserve the wrong bytes, so in all seven the
backticked heading token is replaced by the words "supersession section". **That is the only edit
made in any of those seven notes**, and the statement each makes is now historical, because
revision 9 was published on 2026-09-17 and revision 10 adds the section. This file therefore
refers to that heading in prose as "the supersession section" everywhere above it. The second
edit is the revision-9 note's opening **heading**, rewritten into the retention form the
revision-8, -7, -6, -5, -4, -3 and -2 headings below it already use; its body is untouched apart
from that one token.

**The revision history line below is extended with revision 10.** The audits binding revision 9
(`review/audit-codex.md`, `review/audit-fable.md`) are **not** carried into this run: they bind
revision 9's sha and revision 10 gets fresh ones. `review/identities.json` is carried as copied
from the publishing run, so its `audits.*` entries still name the round-9 actors; they are
replaced when the revision-10 audits exist.

**Evidence: two new checks, and not one carried byte moved.** Every script, log and snapshot the
decision below cites is carried forward unchanged; `review/CARRIED-FROM.md` lists all **309**
carried files with their sha256, and `review/evidence/supersession-check-r10.sh` re-establishes
that on every run — check `S8c` compares all 309 against the publishing run's copies, and checks
`S10a`–`S10c` compare each of the **seven** carried `.sh` files against the blob `git ls-tree
HEAD` reports for its path in that run. Two new scripts assert what this revision claims, and
nothing else:

| Script | Log | Result |
|---|---|---|
| `review/evidence/owned-value-check-r10.sh` | `review/evidence/owned-value-check-r10.log` | **exit 0**, `CHECKS RUN: 53 PASS: 53 FAIL: 0 SKIP: 0` |
| `review/evidence/supersession-check-r10.sh` | `review/evidence/supersession-check-r10.log` | **exit 0**, `CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0` |

The first pins the sha256 of the `- owns web-extra-surface` line as `/usr/bin/grep` emits it,
asserts each of the six moved clauses in its new form and each unmoved clause verbatim, asserts
that none of the eight superseded forms survives in the value, resolves every clause of R02's
`CONFLICT:` line against R02's own decision file, and `diff`s the five `- assumes` lines against
rows it extracts from the live `docs/port/PARAMETERS.md` — **empty**. The second asserts the
title line, the H2 order of the current entry, that the supersession heading occurs exactly once
as a whole line with **zero** occurrences of its text in any form above it, and that the file's
last 228,667 bytes hash to `d4507f5b…` and `cmp` clean against the published topic decision.

Both carry `set -euo pipefail`, call `/usr/bin/grep` by absolute path and print its version
(`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`) beside the counts, assert on content rather
than on an exit code alone, sum `PASS`/`FAIL`/`SKIP` and exit non-zero on any `FAIL`, and are
`shellcheck`-clean at shellcheck **0.11.0** (exit 0, no directive suppressing anything). Neither
contains the supersession heading's literal text, which both assemble at run time: `check_history`
splits a decision at the **first substring** occurrence, and a script holding the literal would
write a copy of it into its own committed log. **Each zero is guarded by a control that makes it
non-vacuous.** `V5a`/`V5b` reinject the superseded `src/web/` form into a scratch copy of the owned line and
require the `V4a` matcher to fire on it, so the eight absences are not a matcher that cannot
match;
`S6a`/`S6b` flip one byte of the preserved tail and require both the digest and the `cmp`
comparison to reject it. `V8a`–`V8d` are the discipline in the other direction: each superseded
form still appears above the heading as a **marked quotation**, so each is counted against a
pinned number and each carrying line is required to hold a quotation marker on itself or within
the two lines above it.

**Reproducibility, shown rather than asserted.** Neither script prints a clock, a hostname, an
absolute path or a scratch-directory name, so both are byte-reproducible. Each was rerun in place
and from a clean `git archive` extraction. The extraction is of a tree written from a
**temporary index** holding exactly this commit's files — `git read-tree HEAD`, then `git add` of
this run directory with `GIT_INDEX_FILE` pointed at a scratch index, then `git write-tree` —
because this run directory is not in `HEAD` until the commit lands, and an extraction of `HEAD`
alone would be missing the very files under test. The four `diff` results are recorded as `review/evidence/owned-value-check-r10-rerun.diff`,
`review/evidence/owned-value-check-r10-archive.diff`,
`review/evidence/supersession-check-r10-rerun.diff` and
`review/evidence/supersession-check-r10-archive.diff`. Three are **empty**. The exception is
`supersession-check-r10.sh`'s archive leg, and the rule for comparing across it is exact: an
extraction has no `.git`, so checks `S10a`, `S10b` and `S10c` — the only three that read git
metadata — **SKIP by name**, their progress line is absent, and the summary reads
`PASS: 20 FAIL: 0 SKIP: 3`. Those lines and no others differ. The guard tests `.git` with `-e`
rather than `-d`, because in a worktree `.git` is a **file**.


**Revision note (revision 9), retained as the record of that revision. It was approved by both
round-9 audits, owner-accepted on 2026-09-16 and published on 2026-09-17. Its body below this
heading is retained verbatim and nothing in it is withdrawn; the one edit revision 10 made
there is the backticked supersession-heading token the revision-10 note above accounts for, and
this heading itself is the retention form the seven headings below it already use. Its own
heading recorded it as: three rows of the owner-supplied reference architecture that
revision 6's reconciliation missed, added to it; no owned value, no recommendation and no
existing evidence file moves.** Revision 9 rewrites revision 8 (sha256
`ce7a5dad994e4c5fa87a35674a7172913265cf70cc13456ed105a7018270407a`) in place. No revision of
this decision has been published, so there is still no supersession section. The one
`- owns web-extra-surface` line and the five `- assumes` lines are **byte-identical to
revisions 2 through 8**, the H2 set is unchanged, and every file of the six checks,
`yanked-control-r5.sh`, `owner-reference-check-r6.sh` and every snapshot outside the new
`snapshots/r9/` directory is **byte-identical**.

**Why there is a revision 9 at all.** Revision 8 was **approved by both round-8 audits** — the
empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r8`, model `gpt-5.6-terra`, family openai) with
`unresolved-findings: none`, and the judgment audit likewise. Revision 9 repairs no audit
finding. Its prompt is the **brief drafter's report**, which found that revision 6's
reconciliation with the owner-supplied reference architecture
(`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, folded in under
**owner decision 11 of 2026-09-16**) disposed of eight rows but left **three rows of that
document's reference `Cargo.toml` carrying no disposition at all**: its
`tokio = { version = "1", features = ["full"] }`, its `axum-extra` dependency, and its
`[profile.release]` block. Owner decision 11 requires a disposition for every overlapping row,
so the omission is a gap in the reconciliation rather than a defect in the recommendation.
Revision 9 closes it and does nothing else.

**The three rows, in the same form as the revision-6 table below, continuing its numbering.**
Each was verified at a primary source rather than taken from the document, whose own caveat
records that its patterns were "compiled in my head, not against the toolchain".

| # | Row | Disposition |
|---|---|---|
| 9 | Runtime features — the reference `Cargo.toml` writes `tokio = { version = "1", features = ["full"] }` against the six named features this decision selects | **Differs: ground.** `full` is twelve features; the six plus the `rt` that `rt-multi-thread` implies cover seven of them, and the five it adds — `fs`, `io-util`, `io-std`, `parking_lot`, `process` — serve no behaviour F338 asks for, while `parking_lot` is an optional **dependency** and so lands in the tree gate 6 measures. The ground is this decision's own rule, already stated at gate 5: "`tokio`'s `default = []`, so every feature is opted into explicitly." Owned value unmoved. Recorded at Disagreement 5. |
| 10 | `axum-extra` — the reference's shared core pairs `axum-extra 0.12.6` with axum, at `features = ["cookie", "cookie-private", "typed-header"]` | **Hand-off: not decided here.** The version is current, not stale (0.12.6 is the newest non-yanked and newest stable, MIT, `rust-version` 1.80, requiring `axum ^0.8.9`), so nothing is wrong with the document's figure; the crate is simply not a member of this item's stack, because the three features it enables are two extra optional crates — cookie jars and typed headers — that no behaviour this item owns asks for. Cookie jars are C6's (**no P02 item; pending owner scoping**); typed-header extractors belong to whichever of **R72**–**R76** needs them. It nests on top under the owned value's "heavier opt-ins nest on top rather than widening it" clause. Recorded at Disagreement 3 and in the overlap map. |
| 11 | `[profile.release]` — the reference sets `lto = "thin"` and `codegen-units = 1` | **Hand-off, and the owning item is not yet fixed — the gap is named rather than papered over.** Verified against this repository: **no** binding prompt of any of the 85 research items, and **no** row of the commonality ledger, names `[profile`, `lto`, `codegen-units` or `opt-level`. The controller's reading is **R68** (`release-binary-artifacts`), and R68 is indeed the nearest consumer — the release binary's size and build time are what the profile governs and what R68's own questions weigh — but R68's prompt scopes itself to "which distribution channels/artifact *types* … get built and shipped" and puts manifest declarations in **R49**'s scope, while R49's owned `build-tool-output-shape` makes "Cargo's own manifest … the entire declaration surface" yet sets no `[profile.*]` key. So: **hand-off to R68 as the controller's reading, with the ownership itself recorded as an open scoping question.** Recorded under *Migration implications* and in the overlap map. |

**The evidence, and what is deliberately not touched.** Two new files, matching the fetcher and
check pair revision 6 introduced: `review/evidence/fetch-owner-reference-r9.sh` writes reduced
snapshots under `review/evidence/snapshots/r9/`, which are committed, and
`review/evidence/owner-reference-check-r9.sh` asserts against them — plus, for row 11, against
this repository's own committed prompts and ledger, because "which item owns this subject" is a
fact about this repository rather than about an upstream project. Its cited log is
`review/evidence/owner-reference-check-r9.log`. Only **published crate metadata** is
snapshotted — versions, licences, declared `rust-version`, `[features]` maps and dependency
requirements, all served by the crates.io API — so no third-party source file enters this
repository and the rule the owner's 2026-09-12 ruling explicitly does not touch stays
unengaged. `owner-reference-check-r6.sh`, its snapshots, `yanked-control-r5.sh` and the six
checks are **not edited**. `review/empirical/parameters-check.sh` was re-run against this file
and `diff` reported no differences against `review/evidence/parameters-check-r2.log`.

**Revision note (revision 8), retained as the record of that revision. It was approved by both
round-8 audits, with `unresolved-findings: none`; its body is retained verbatim and nothing in
it is withdrawn. Its own heading recorded it as: two record-integrity corrections to the
revision-7 note below; no sentence of the JF-4 repair, no owned value and no evidence file
moves.** Revision 8 rewrites
revision 7 (sha256 `a64addcff304770e9c114d05d974da4aaa9395e9095dff2f86823a45a29dfcfe`) in place,
answering both findings of the round-7 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r7`, model `gpt-5.6-terra`, family openai), which
confirmed the three JF-4 repairs and rejected only the revision-boundary record, while the
round-7 judgment audit (`review/audit-fable.md`, actor
`audit-fable-2026-09-12T204004Z-d02022bf6f42-r7`, family anthropic) returned `approve` with
`unresolved-findings: none`. **Finding 1 — the hunk count**: the revision-6-to-7 boundary was
reported as **"six hunks"**, and that figure is corrected to **five**, because
`git diff 10a83c4 1187133 -- review/DECISION.md` prints five `@@` headers — at git's default
three-line context the retitled first line and the new revision-7 note are one contiguous hunk,
followed by the history line and the three JF-4 locations — whereas **six** is the count of
*edited locations*, which is what `diff -U0` reports because it splits that first pair; "hunk"
in this decision now means a unified-diff hunk at default context, and an enumeration of
locations is labelled as such. **Finding 2 — the no-evidence-change claim**: it was made against
the range `10a83c4..HEAD`, which spans the intervening revision-6 audit-checkpoint commits and
therefore carries `review/evidence/audit-*` additions belonging to those commits rather than to
this revision, so it is scoped instead to the commits that produced revision 7 —
`git show --stat --name-only 3e4c086` and the same command on `1187133` each list exactly one
path, `research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/DECISION.md`. **Nothing else
moves**: the title, this note, the revision-7 note's retention heading and the history line are
the whole of revision 8, whose own revision-7-to-8 boundary is **two unified-diff hunks**, and
the one `- owns web-extra-surface` line, the five `- assumes` lines, the H2 set, every sentence
of the JF-4 repair and every evidence file are byte-identical.

**Revision note (revision 7), retained as the record of that revision. It was approved by the
round-7 judgment audit and rejected by the round-7 empirical audit on the two record-integrity
findings the revision-8 note above answers; its body is retained verbatim and nothing in it is
withdrawn.** Revision 7 rewrites revision 6 (sha256
`d4d6a8d2a3297a6db488580142de6d651f33b8109e9023994f6cb9f5ecfd6a17`) in place. No revision of
this decision has been published, so there is still no supersession section. The one
`- owns web-extra-surface` line and the five `- assumes` lines are **byte-identical to revisions
2, 3, 4, 5 and 6**, and so are the recommendation, every version pin, every exclusion, every
fitness-gate answer including gate 1's `inapplicable` row, the R67 exit contract and the request
to R67, the CLI Design Standard's R4.1 required global core, the H2 set, and every evidence
script, cited log and committed snapshot. **No evidence file is added, edited or replaced.**
Check 6, `review/empirical/parameters-check.sh`, asserts only on lines beginning `- assumes `,
`- owns ` and `## `, none of which this revision touches; it was nevertheless re-run against
this file as a confirmation, exited `0`, and its output `diff`s **empty** against the cited
`review/evidence/parameters-check-r2.log`, which is therefore left unchanged rather than
superseded by an r7 copy of the same bytes. Checks 1 through 5, and `yanked-control-r5.sh`,
read no part of this file.

Revision 6 was **approved** by the round-6 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r6`, model `gpt-5.6-terra`, family openai, verdict
`approve`, `unresolved-findings: none`) and **rejected** by the round-6 judgment audit
(`review/audit-fable.md`, actor `audit-fable-2026-09-12T204004Z-d02022bf6f42-r6`, model
`claude-opus-5`, family anthropic) on **one** finding — that audit records JF-1, JF-2 and JF-3
as closed and marks its three observations explicitly as *not* findings. Revision 7 answers the
one finding and changes nothing else:

- **JF-4** — *"the decision states twice, as present fact, that the CLI parser its serve
  binary's required global core is parsed with is still R60's open choice, and keys a
  `re-verify:` trigger on that selection — but R60's parser selection (`clap` 4.6.6, derive
  API) was owner-accepted on 2026-09-15 as W0-R60, one day before revision 6, so the statement
  is false and the trigger has already fired"*. Repaired at the three locations the finding
  names, cited by **revision 6's line numbers**: the flag-surface paragraph of
  `### Principles and implementation` (**line 908**) and the global-core row of the unproven
  table (**line 2105**), each of which now quotes revision 6's wording, labels it superseded by
  the acceptance, and states the accepted fact in its place; and the `re-verify:` line (**line
  1378**), whose R60 clause is **replaced, not deleted**, because a watchable event remains.

**The accepted fact, cited rather than asserted.** `docs/port/OWNER-ACCEPTANCES.md` records
`R60 | 7 | 67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2 | accept |
2026-09-15 | W0-R60 option A; clap 4.6.6 derive, clap_complete 4.6.9, dependency-free build.rs;
OV-01 refused per the 2026-09-14 ruling; first publication pending`. R60's parser is therefore
**selected and owner-accepted, and unpublished as yet** — a pair of states this decision's own
vocabulary already keeps apart, since it cites R49 as having selected alternative A1 while
labelling that revision unpublished. Read on **2026-09-16**, together with
`research/runs/R60/2026-09-05T183002Z-09f93cfc507c/review/DECISION.md`, whose current revision 8
still selects `clap` 4.6.6 with the `derive` API and `clap_complete` 4.6.9. **No clap feature
set beyond `derive` is transcribed anywhere in this decision**, deliberately: R60 revision 8 is
still moving that set, and nothing here reads it. Only the `derive` API is named, because it is
part of what the owner accepted. **The design consequence does not move, and the accepted answer
strengthens it** — `clap` is a non-optional dependency of the package for the CLI binary, so the
serve binary reuses it, the `web` feature adds no parser crate, and check 2's measured 12 → 52
package delta stands by construction.

**The `re-verify:` R60 clause is replaced, not deleted, and narrowed to what is still
watchable.** *"when R60 selects the CLI parser the serve binary's global core is parsed with"*
names an event that occurred on 2026-09-15. What remains worth watching is the gap between the
accepted text and the published one — R60's file has already moved after its acceptance — so the
clause now reads, in full and unbackticked as that line is written, "when R60's published
decision moves off its owner-accepted clap 4.6.6 derive selection for the CLI binary the serve
binary's global core is parsed with". Every other clause on that line is byte-identical, which
a `diff` of the line shows rather than a count.

**Mechanical enumeration, run before any edit and re-run after it.** Two `/usr/bin/grep -n`
passes over this file: one for `R60`, and a separate case-insensitive one for `parser`, so that
a sentence about the parser's state which never says "R60" could not escape. The union, by
revision 6's line numbers, is **469, 894, 895, 908, 1244, 1378, 1382, 1835, 2105**. **Edited:
908, 1378, 2105.** **Deliberately left byte-identical, each with its ground:** 469, which sits
inside the retained revision-2 note and records what revision 2 did, which is still true; 894
and 895, which attribute who binds a behavior ("help layout is R60's parser") rather than
asserting a selection state; 1244, the migration table's `src/bin/<app>-serve.rs` row, and 1382,
the `- owns web-extra-surface` line, which share the wording *"the parser crate R60 selects for
the CLI binary"* — wording the round-6 judgment audit ruled "survives the correction verbatim",
true of a selected parser exactly as of an unselected one, and inside an owned value that 19
consumers read and check 6 validates; and 1835, which is an evidence script's JSON parser and
has nothing to do with R60. Both passes were re-run against the edited file: outside this note,
every hit is one of those nine locations at its shifted line number, and no new hit appeared
anywhere else. The `**Sources.**` paragraph is **not** extended, on the revision brief's
explicit instruction that no other sentence changes; the two files revision 7 read are named in
this note instead.

**Revision note (revision 6), retained as the record of that revision. It was approved by the
round-6 empirical audit and rejected by the round-6 judgment audit on JF-4 alone, which the
revision-7 note above repairs; its body is retained verbatim and nothing else in it is
withdrawn.** Revision 6 rewrites revision 5 (sha256
`0fc0ed8a9c4a6daac900e23524c1c3ba0ef1707aeb44833c0ca2b2b57eb4cf4c`) in place. No revision of
this decision has been published, so there is still no supersession section. The one
`- owns web-extra-surface` line and the five `- assumes` lines are **byte-identical to
revisions 2, 3, 4 and 5**, and so is everything the owned value fixes: `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency, `bacon`
3.25.0 as the dev watcher, the exclusions, the R67 exit contract (SIGTERM →143, SIGINT →130,
drain-deadline expiry →1) and the request to R67, the CLI Design Standard's R4.1 required
global core, gate 1's `inapplicable` answer under owner ruling Q7.B, and every evidence script
and cited log of the six checks and of `yanked-control-r5.sh`. **The specific question that
could have moved the owned value was asked and answered on evidence.** The owner-supplied
document advises `axum = "=0.8.9"` — an exact-equality requirement — and this item is not
owner-accepted, so changing the value was permitted. It is not warranted: **neither the owned
value nor the migration table states a requirement operator at all**, and Cargo's default for a
bare version string is the caret requirement, under which `"0.8.9"` *is* `>=0.8.9, <0.9.0` and
therefore already cannot resolve to 0.9 — which is the document's only stated reason for the
`=` form. Read at the Cargo Book and asserted in
`review/evidence/owner-reference-check-r6.log`, section B. The ground for *not* adopting `=` is
recorded under *Compatibility* below. So the value stays byte-identical, and
`review/empirical/parameters-check.sh` was re-run against this file with `diff` reporting no
differences against `review/evidence/parameters-check-r2.log`.

**What revision 6 is.** Revision 5 was **approved** by the round-5 empirical audit
(`review/audit-codex.md`, actor `audit-codex-2026-09-12T204004Z-d02022bf6f42-r5`, model
`gpt-5.6-terra`, family openai, verdict `approve`, `unresolved-findings: none`), which reran
all six checks plus `yanked-control-r5.sh` three times in place and once from a clean
`git archive HEAD` extraction, all byte-identical, and independently counted 54 yanked errors.
Revision 6 therefore repairs no defect. It carries out **owner decision 11 of 2026-09-16**
(`docs/planning/p02/owner-decisions.md`, *Owner-supplied reference architecture — STANDING
INPUT*), which rules that R69 "reconciles with it row by row where they overlap … and records
agreement or a ground for differing; rows belonging to other items are recorded as hand-offs,
not decided." The document is recorded as an owner-supplied **input** under `## Engines`, with
its provenance and overlap map; each row's reconciliation is placed where that row's topic
already lives, and **no new H2 heading is added** — the H2 set is the one the role contract
fixes and the audits have checked.

**The document is an input, not an authority, and every fact taken from it was re-verified.**
It says so itself: its closing caveat records that its code patterns were "compiled in my head,
not against the toolchain", and it flags several versions "verify". Owner-fixed parameters in
`docs/port/PARAMETERS.md` override it where they differ — **edition 2024 over its
`edition = "2021"`, and `msrv-policy` over its `rust-version = "1.85"`** — and those two `-
assumes` lines are unchanged. Two new scripts do the verification:
`review/evidence/fetch-owner-reference-r6.sh` (a fetcher, not a check, the sibling of
`fetch-figures.sh`) writes reduced snapshots under `review/evidence/snapshots/r6/`, which are
committed; `review/evidence/owner-reference-check-r6.sh` asserts against those snapshots, never
touches the network, carries a control that must report a present string, and is cited as
`review/evidence/owner-reference-check-r6.log`. It was run three times and runs 2 and 3 were
byte-identical to run 1; a scratch copy with one expectation mutated to `9.9.9` exited `1`, so
the assertions can fail.

**Every row's disposition, one line each.** The document is cited by its own section headings.

| # | Row | Disposition |
|---|---|---|
| 1 | Framework and runtime — axum 0.8.9 / tokio 1 (TL;DR, Key Finding 1, Recent-Bugs register) | **Agree** on the members and the version. **Differ with ground** on the `=0.8.9` pin (a bare requirement is already caret-bounded) and on "a 3-year horizon on 0.8 safe" (the primary source is weaker than the paraphrase, and 0.9 work is live on `axum::serve`). Owned value unmoved. Recorded under *Compatibility* and under F338. |
| 2 | Features — the document enables `ws`, `http2`, `macros` (reference `Cargo.toml`) | **Additive later-layer territory, not enabled here**, under the owned parameter's own "heavier opt-ins nest on top rather than widening it" clause. Recorded at Disagreement 4. |
| 3 | Dev loop — `bacon` over `cargo-watch` (C14) | **Agree**, and this item's finding is the stronger one: the document does not mention that bacon's default Unix job interruption is SIGKILL. The `bacon.toml` `kill` override stands. `cargo-chef` and `mold` are **hand-offs** (R51, R68). Recorded under F339. |
| 4 | Graceful shutdown — Cloud Run's 10-second SIGTERM window; axum issue #3003 (Cloud Run Runbook, C7) | **Verified at Google's own page and at the GitHub API.** The 10 s window is recorded as a **datum handed to R77** for its drain-deadline default; #3003 is recorded as a **hazard for a later WebSocket layer**, which has no P02 item. Neither changes anything here. Recorded under F338. |
| 5 | Test idiom — `axum-test` ranked over `tower::ServiceExt::oneshot` (C12) | **Differ with ground**, and the document's figure is stale: the `18` line is three majors behind. `oneshot` is kept, `axum-test` is recorded as the alternative with the condition under which it wins, and the harness tier remains **R32's**. Recorded at Disagreement 3. |
| 6 | Layout — single crate, feature-vertical modules, workspace later (C13) | **Agree**, and it matches R49's selected alternative A1. Which crate carries the feature is **R02's**, still open. Recorded under *Migration implications*. |
| 7 | Error contract — RFC 9457 Problem Details (C4) | **Hand-off to R70**, not decided here, with the note that owner-accepted R67's envelope differs in shape and R70 must reconcile them. Recorded under *Minimal realistic endpoint*. |
| 8 | Everything else — templating, static assets, OpenAPI, validation, database, sessions/auth, WebSocket fan-out, jobs, config/secrets, observability, middleware, container, Cloud Run deployment | **Hand-offs**, one line each, by item or as "no P02 item; pending owner scoping". Listed once under `## Engines`. No research was done on them and none is decided. |

**Revision note (revision 5), retained as the record of that revision. It was approved by the
round-5 empirical audit and nothing in it is withdrawn.** Revision 5 rewrites revision 4 (sha256
`1814883d3d4b83333ea145c6dae0e02d86ba058b46b512c4bdfeac00afca23c3`) in place. No revision of
this decision has been published, so there is still no supersession section. **Nothing about the
recommendation, the parameters, the checks or the evidence moves.** `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency and `bacon`
3.25.0 as the dev watcher stand unchanged; the single `- owns web-extra-surface` line and the
five `- assumes` lines are byte-identical to revisions 2, 3 and 4; the R67 exit contract
(SIGTERM →143, SIGINT →130, drain-deadline expiry →1) and the request to R67 are unchanged;
the CLI Design Standard's R4.1 required global core is unchanged; fitness gate 1 remains
`inapplicable` under owner ruling Q7.B; revision 4's repair — `review/evidence/feature-shape-check-r4.sh`,
its cited log `feature-shape-check-r4.log` and the isolated `CARGO_HOME` that makes the
crates.io-index warning impossible — is **untouched and byte-identical**, as are the other
five scripts and every cited log. Revision 5 repairs exactly one defect: **a number in
revision 4's own revision note that was written from recall instead of from a run.**

Revision 4 was **rejected** by the round-4 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r4`, model `gpt-5.6-terra`, family openai) on a
single finding, quoted verbatim:

> **Reject — the claimed yanked-lookup control has the wrong observed count.** Revision 4
> states at `review/DECISION.md:84-90`, and its own script repeats at
> `review/evidence/feature-shape-check-r4.sh:72-80`, that an empty isolated `CARGO_HOME` with
> yanked lookup enabled prints 55 `couldn't check if the package is yanked` errors. I recreated
> that variant with the same pinned advisory-db commit, an otherwise empty cargo home, and only
> the `cargo-audit` symlink required for Cargo to discover the subcommand. It loaded 1,243
> advisories, scanned 55 dependencies, exited `0`, and emitted **54** such errors
> (`review/evidence/audit-codex-r4-empty-cargo-home-yanked.log:59`). The decision must correct
> the count before acceptance.

The finding is correct and is accepted without qualification. The same auditor's findings 2 and
3 confirmed the rest of revision 4: the isolated-`CARGO_HOME` repair reproduces byte-for-byte in
every mode tried — three in-place reruns, a temporary-index `git archive` extraction, a `HEAD`
`git archive` extraction, and a rerun made while a separate process held `flock(LOCK_EX)` on
`~/.cargo/.package-cache` — and the retained r3 artefacts and the other five scripts and logs
are unchanged and matched their cited logs. Revision 5 changes none of that.

**Why the wrong figure arose, so a reader can see the confusion rather than take the correction
on trust.** **55 is the dependency count**, not the error count. It is the figure in
cargo-audit's own `Scanning Cargo.lock for vulnerabilities (55 crate dependencies)` line, which
check 2 asserts as a constant and which this decision cites correctly wherever else it appears.
The yanked lookup does **not** run over all 55. It is a crates.io **registry** query, so it runs
only over lockfile entries carrying a
`source = "registry+https://github.com/rust-lang/crates.io-index"` key; the probe's root package
`r69_feature_shape` is a **path** package with no `source` and is skipped. 55 − 1 = **54**, and
`yanked-control-r5.sh` asserts each of those three figures separately rather than leaving this
paragraph to be believed. Revision 4 reported the variant as tested, then wrote down the count
it had to hand — the figure on the line immediately above the first error line in that same
output — instead of the count the run produced. That is the failure mode this programme has
rejected all week, and the correction is therefore not a re-wording: it is a rerun.

**The repair: the figure is now true by construction.** Revision 5 re-ran the rejected variant
itself, in the new script `review/evidence/yanked-control-r5.sh`, whose cited log is
`review/evidence/yanked-control-r5.log`. The script recreates exactly what the round-4 audit
recreated — the pinned advisory-db commit `b50980aad8b8f14f77e25a97b32dd94bf008b0af`, an
isolated `mktemp -d` `CARGO_HOME` holding **only** a `bin/cargo-audit` symlink and deliberately
**no** `audit.toml`, so `[yanked] enabled` keeps its default `true` — and it **asserts** the
number rather than printing it for a reader to transcribe:

- the count of `couldn't check if the package is yanked` lines, taken with
  `/usr/bin/grep -cF` (the POSIX `grep` at its absolute path; a typed `grep` in an agent shell
  on this machine is `ugrep`), must be exactly **54**, and a control shows the same test
  **rejects 55**, the figure revision 4 stated, so the assertion can fail;
- the lockfile must hold 55 `[[package]]` entries and 54 `source = "registry+` keys, which is
  *why* the two figures differ;
- the 54 crate names in the error lines, sorted, must `diff` empty against the sorted names of
  the lockfile's registry-sourced packages, and the one lockfile package absent from the error
  lines must be `r69_feature_shape`.

Observed: `Loaded 1243 security advisories`, `Scanning Cargo.lock for vulnerabilities (55 crate
dependencies)`, cargo-audit `exit=0`, `yanked-error-lines (/usr/bin/grep -cF): 54`, every
assertion `OK`, script `rc=0`. The script was run three times in a row and runs 2 and 3 were
**byte-identical** to run 1, which is the cited log; absolute scratch paths are normalised to
`<pinned-advisory-db>` and `<isolated-cargo-home>` exactly as in `feature-shape-check-r4.sh`,
which is what makes that identity possible. The script sets `set -o pipefail`, asserts on
content, never writes inside this run directory (its advisory-db clone and its isolated home are
`mktemp -d` directories under `${TMPDIR:-/tmp}`, removed by an `EXIT` trap — **no nested git
repository is ever created in this tree**), and passes the repository's `shellcheck` pre-commit
hook carrying a file-level `# shellcheck disable=SC2015,SC2016,SC2329` directive that justifies
each of the three informational codes, exactly as `feature-shape-check-r4.sh` does. The
directive is a comment, so it changes no byte of the output.

**What is deliberately left byte-identical, and where the superseded figure therefore still
sits.** `review/evidence/feature-shape-check-r4.sh` is **not edited**. Its cited log
`feature-shape-check-r4.log` is the output that the round-4 audit reproduced five ways, and the
55 the finding names in that file sits in the **header comment block at lines 72-80**, not in
any assertion the script executes: no run, no exit status and no output line of that script
depends on it. Editing the file to fix a comment would invalidate a reproduction record to
correct prose, so **the r4 script's comment is left carrying the superseded figure**, and this
note is where a reader learns that. The live record of the count is
`yanked-control-r5.sh` — where the figure is asserted, not narrated.

**The two locations in the revision-4 note below were corrected in place, which is an exception
to this file's practice, and the exception is stated rather than hidden.** Revisions 4 and 3
each left the previous revision's note body **verbatim** as that revision's record, adding a
warning to its heading. Revision 5 does not do that at the two sentences the finding cites —
lines 87 and 89 of revision 4, the `prints 55 lines of` sentence and the `the log grew 55 lines`
sentence: it changes `55` to `54` in both and cites the new log, because the round-4 finding
requires the count in
`review/DECISION.md:84-90` to match the run, and a decision that carries a known-false empirical
figure in its own body — with only a later note to contradict it — is the defect being repaired,
not a record worth preserving. What revision 4 actually wrote is quoted in full in the finding
above, so nothing is lost. Every other sentence of the revision-4 note is byte-identical.

**Revision note (revision 4), retained as the record of that revision. Its two sentences
reporting the empty-`CARGO_HOME` variant's error count are the ones the round-4 audit refuted;
they are corrected in place to 54 and marked, and the revision-5 note above says why.**
Revision 4 rewrites revision 3 (sha256
`a9eec9bd3cc3631d61f395f470e0b15a389746f9e26e26a5b2b32a9fc9a7e98f`) in place. No revision of
this decision has been published, so there is still no supersession section. **Nothing about the
recommendation, the parameters or the other five checks moves.** `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency and `bacon`
3.25.0 as the dev watcher stand unchanged; the single `- owns web-extra-surface` line and the
five `- assumes` lines are byte-identical to revision 2 and revision 3; the R67 exit contract
(SIGTERM →143, SIGINT →130, drain-deadline expiry →1) and the request to R67 are unchanged;
the CLI Design Standard's R4.1 required global core is unchanged; fitness gate 1 remains
`inapplicable` under owner ruling Q7.B; the pinned advisory-database commit
`b50980aad8b8f14f77e25a97b32dd94bf008b0af` and its 1,243-advisory and 55-crate assertions are
unchanged; and the other five evidence scripts and their cited logs are untouched. Revision 4
repairs exactly one defect: **the conditions under which check 2's cited log is byte-identical
on rerun.**

Revision 3 was **rejected** by the round-3 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r3`, model `gpt-5.6-terra`, family openai) on a
single finding, quoted verbatim:

> **Reject — the repaired check is still not byte-reproducible under the decision's stated
> conditions.** Each successful rerun inserted `warning: couldn't open crates.io index: I/O
> operation failed: failed to obtain lock file '/Users/stevemorin/.cargo/.package-cache'` after
> `Loaded 1243 security advisories`; `diff -u review/evidence/feature-shape-check-r3.log
> review/evidence/audit-feature-shape-check-r3-inplace-1.log` shows this sole difference. The
> decision names a *missing* cached index as the warning condition, but the observed cause is an
> unavailable package-cache lock on a machine that has the cache. Cargo-audit 0.22.1's
> `src/auditor.rs:115-167` takes the same `CachedIndex::open` branch for `--no-fetch` and warns
> on any open failure, including a lock failure. Its stated conditions for cited-log identity
> must include a readable, unlocked cached crates.io index (or the claim must be narrowed to the
> deterministic feature-shape sections); otherwise its claim that the two named variations are
> exhaustive is false.

The finding is correct and is accepted without qualification. Revision 3's note below says, in
the sentence beginning "The residual environment dependency, named rather than claimed away",
that a **missing** cached index is the condition for that warning and that the SKIP and the
missing index are "the second and last documented way this log can vary". Both halves were
wrong: cargo-audit 0.22.1 warns on **any** `CachedIndex::open` failure, a contended
`~/.cargo/.package-cache` lock included, and that is what the auditor hit on a machine whose
index is present. The same auditor's findings 2, 3 and 4 confirmed everything else in revision
3 — the pinned-database repair, the scoped SKIP and mismatch controls, and the five unchanged
checks — and revision 4 changes none of it.

**The repair, and why this form.** The finding offered two remedies: make the warning
impossible, or narrow the byte-identity claim to the deterministic feature-shape sections and
classify the scan section's environment-dependent lines. Revision 4 takes the **first** form
for the warning, because it can be made **structurally impossible** rather than merely
classified. The new check is `review/evidence/feature-shape-check-r4.sh`; its cited log is
`review/evidence/feature-shape-check-r4.log`. It differs from `feature-shape-check-r3.sh` in
three **substantive** ways. The remaining differences a script-to-script `diff` shows are
wording and none of them touches an assertion: the rewritten header comment block, the
`# shellcheck disable=` directive reported after item 3 below, section 8's heading string
(`… PINNED advisory database, ISOLATED CARGO_HOME`) and the final summary label
(`advisory scan (section 8, pinned input, isolated CARGO_HOME): …`). The three substantive
ways:

1. **Section 8 runs `cargo audit` under an isolated `CARGO_HOME` with the yanked-crate lookup
   disabled, so the warning cannot be emitted.** The isolated home is a `mktemp -d` directory
   under `${TMPDIR:-/tmp}` containing exactly two things: an `audit.toml` holding
   `[yanked]` / `enabled = false`, and a `bin/cargo-audit` symlink to the cargo-audit binary
   already on `PATH`. Read at the published source of `cargo-audit` 0.22.1, `src/commands.rs`
   sets `CONFIG_FILE = "audit.toml"` and resolves `config_path()` to the project's
   `./.cargo/audit.toml` if it exists and otherwise to `home::cargo_home().join("audit.toml")`,
   and `home::cargo_home()` honours `$CARGO_HOME`; the probe directory has no `./.cargo`, so
   that file is the configuration this invocation loads. With `yanked.enabled` false,
   `src/auditor.rs:115-167` takes its `} else { None }` arm: **neither `CachedIndex::fetch` nor
   `CachedIndex::open` is called.** No crates.io index is read, no `.package-cache` lock is
   taken, and the warning the round-3 audit observed has no code path that can print it. The
   ambient `~/.cargo` is not consulted at all, so **neither a readable nor an unlocked cached
   crates.io index is required** to reproduce the log.
   **What that costs, stated rather than hidden:** the scan no longer reports yanked crates. A
   crate's yanked status is a **mutable** attribute of the live crates.io registry, not part of
   the pinned advisory corpus, and is exactly the kind of moving input for which revisions 2 and
   3 were rejected. No claim in this decision rests on a yanked result — gate 3 is answered on
   advisories alone, and the gate-2 "newest non-yanked version" figures come from the committed
   crates.io snapshots read by check 3, not from this scan. Yanked-crate detection against a
   current index belongs to P03's live CI.
   The repair is **asserted, not assumed**: the normalised cargo-audit output must contain
   neither `couldn't open crates.io index` nor `couldn't check if the package is yanked`, and
   must be **exactly two lines**. The line count is the assertion that catches a line nobody has
   seen yet; a string blocklist cannot. A control shows the same absence test reports a line
   that *is* present, so it can fail.
   **The variant the finding's own wording suggested was tested and rejected on evidence.** An
   isolated but *unpopulated* `CARGO_HOME` with `yanked.enabled` left at its default `true` does
   **not** print the warning: `CachedIndex::open` succeeds against a newly created empty index,
   and cargo-audit then prints **54** lines of
   `error: couldn't check if the package is yanked: not found: No such crate in crates.io index: <name>`
   — one for each of the 54 registry-sourced packages in the probe's 55-package lockfile; the
   root path package `r69_feature_shape` has no crates.io source and is not looked up. *(Revision
   4 wrote 55 here, the scan's dependency count, without re-running the variant; the round-4
   audit observed 54 and rejected it. Revision 5 re-ran the variant and asserts the count in
   `review/evidence/yanked-control-r5.sh`, cited log `yanked-control-r5.log`. See the revision-5
   note above.)*
   Asserting the warning's absence would have passed while the log grew 54 lines. Disabling the
   lookup is the form that makes the claim true by construction.
2. **One named, anchored classified line class, for a second environment dependency found while
   repairing the first.** Sections 1, 2, 5 and 7 run cargo under the **real** `CARGO_HOME` —
   they need the populated registry cache to resolve `--locked` — and capture its stderr. When
   another process holds `~/.cargo/.package-cache`, and ten agents share this worktree, cargo
   prints `Blocking waiting for file lock on package cache` (and, for the build-directory lock,
   `… on build directory`) and then proceeds normally. **This was reproduced deliberately, not
   inferred:** an exclusive `flock` was held on `~/.cargo/.package-cache` from a separate
   process while section 1's `cargo tree -e normal --locked --no-default-features` ran in the
   probe directory; the line appeared and the tree was otherwise identical. Left alone it would
   have rejected revision 4 for the same overclaim a third time, and unlike the section-8
   warning it **cannot** be made impossible. It is therefore handled by the R63 classifier
   discipline: `norm` deletes it with the single anchored pattern
   `/^[[:space:]]*Blocking waiting for file lock on /d`. **That is the only classified line
   class in this log, and it is named here, in the script's header and in a header line the log
   itself prints.** It carries no information about the feature shape; it is deleted before
   section 7's `tail -3` window is taken, so it cannot shift that window; and when no lock is
   contended nothing is deleted. Section 7's `cargo clean --quiet` and section 8's
   `cargo audit --version` now pipe their output through `norm` for the same reason — in
   revision 3 their stderr reached the log unclassified.
3. **Two sentinels and two log lines follow from the above.** `norm` also rewrites the isolated
   home's path to `<isolated-cargo-home>` (a sentinel initialised before first use, as revision
   3's `DB_DIR` was), the `EXIT` trap removes the isolated home alongside the advisory-database
   clone, the header prints the classified line class, and section 8 prints the isolated home
   and its `audit.toml`. Nothing else in the script moved: the pinned commit, the 1,243 and 55
   assertions, the advisory-count control, the `--db <clone> --no-fetch --stale` form, the
   scratch clone under `${TMPDIR:-/tmp}` that is never written inside this run directory, the
   named `SKIP: advisory-scan-skipped-pinned-db-unavailable`, the separate `rc_shape` that
   always reaches the exit code, and a pinned-hash mismatch being a FAIL and never a SKIP are
   all carried over unchanged.

**One mechanical, output-free addition, reported rather than left to a diff.** Between
revision 3's commit and revision 4's, this repository gained a `pre-commit` hook that runs
`shellcheck` over every staged `*.sh` file under `set -e`. `feature-shape-check-r3.sh` and four
of the five `review/empirical/` scripts do not pass it — each raises the same three
**informational** findings, SC2015, SC2016 and SC2329. Rather than bypass the hook,
`feature-shape-check-r4.sh` carries a file-level `# shellcheck disable=SC2015,SC2016,SC2329`
directive with a comment justifying each code: SC2015's `A && B || C` pattern is deliberate
here because `B` is an `echo` that cannot fail, SC2016's single-quoted `jq` and `awk` programs
must reach those tools unexpanded, and SC2329's `cleanup` is invoked indirectly by
`trap cleanup EXIT`. The directive is a comment: the script's output is unaffected, and the
run made before it was added `diff`s empty against the cited log made after.

`review/evidence/feature-shape-check-r3.sh` and its log `review/evidence/feature-shape-check-r3.log`
are **left byte-identical** as the record of revision 3, exactly as revision 3 left
`review/empirical/feature-shape-check.sh` and `feature-shape-check.log` as the record of
revision 1. The locations revision 4 edited are enumerated at the end of `## Empirical check`.

**Revision note (revision 3), retained as the record of that revision. Its "second and last
documented way this log can vary" claim is the claim the round-3 audit refuted; read it with
the revision-4 note above.** Revision 3 rewrites revision 2 (sha256
`9a8d825d0e204bcf6eed2185409c183ae27903ebd5614ec0245ed2a9537b8723`) in place. No revision of
this decision has been published, so there is still no supersession section. **Nothing about the
recommendation, the parameters or the other five checks moves.** `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency and `bacon`
3.25.0 as the dev watcher stand unchanged; the single `- owns web-extra-surface` line and the
five `- assumes` lines are byte-identical to revision 2; the R67 exit contract (SIGTERM →143,
SIGINT →130, drain-deadline expiry →1) and the request to R67 are unchanged; the CLI Design
Standard's R4.1 required global core is unchanged; fitness gate 1 remains `inapplicable` under
owner ruling Q7.B; and the other five evidence scripts and their cited logs are untouched.
Revision 3 repairs exactly one defect: **the reproducibility of check 2.**

Revision 2 was **rejected** by the round-2 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r2`, model `gpt-5.6-terra`, family openai) on a
single finding, quoted verbatim:

> check 2 is not reproducible as claimed. feature-shape-check.sh invokes bare `cargo audit`,
> which fetches and updates the advisory database. Its recorded log says 1,243 advisories; the
> successful private-db rerun observed 1,246. The original exact rerun failed only on the
> sandbox's read-only database lock, but it likewise did not reproduce. The decision says
> checks 1, 2, 5, and 6 reproduce byte-for-byte and that all six immediate reruns had no
> differences. The check needs a fixed advisory-db input (or the decision must stop claiming
> byte-identical check-2 reproduction).

The finding is correct and is accepted without qualification. Section 8 of
`review/empirical/feature-shape-check.sh` invoked bare `cargo audit`, which fetches and
updates `~/.cargo/advisory-db`; the advisory corpus was therefore a **mutable** input and the
printed advisory count was a moving number that no rerun could be held to. The same auditor's
findings 2, 3 and 4 confirmed everything else in revision 2 — the parameter repair, R67's
quoted taxonomy and exit contract, the CLI Design Standard's R4.1 core, and gate 1's
`inapplicable` answer — and revision 3 changes none of it.

**The repair, and why this form.** The finding allowed two remedies: give the check a fixed
advisory-database input, or stop claiming byte-identical check-2 reproduction and classify the
advisory line as volatile. Revision 3 takes the **first and stronger** form, because the second
would leave the decision's gate-3 answer resting on a number nobody can reproduce, and because
the pinned corpus turns out to load exactly the 1,243 advisories this decision already cites —
the figure becomes traceable to a recorded commit instead of to one moment in time. The new
check is `review/evidence/feature-shape-check-r3.sh`. It differs from its predecessor in four
**substantive** ways:

1. **The advisory database is pinned.** Section 8 clones `RustSec/advisory-db` at commit
   `b50980aad8b8f14f77e25a97b32dd94bf008b0af` (2026-09-09) into a scratch directory under
   `${TMPDIR:-/tmp}`, **asserts** the checked-out commit hash, and runs
   `cargo audit --db <that clone> --no-fetch --stale`. The loaded-advisory count and the
   scanned-crate count are asserted as constants (`1243` and `55`), with a control assertion
   showing the count test can fail. A hash **mismatch is a FAIL, never a skip**. The clone is
   removed by an `EXIT` trap and is never written inside this run directory: no advisory
   database and no nested git repository is committed here.
2. **`--no-fetch` drops one line the revision-1 log had, and the reason is narrower than it
   looks.** The revision-1 log printed `Updating crates.io index`. That line belongs to
   cargo-audit's yanked-crate lookup, not to the advisory corpus, and `--no-fetch` does **not**
   disable that lookup: read at the published source of `cargo-audit` 0.22.1
   (`src/commands/audit.rs:222`, `config.database.fetch &= !self.no_fetch;`, and
   `src/auditor.rs:115-167`), `--no-fetch` clears `database.fetch`, which turns the
   `yanked.update_index && database.fetch` branch — the one that prints the line and calls
   `CachedIndex::fetch` — into the `else` branch, which calls `CachedIndex::open` and still
   performs the yanked comparison against whatever crates.io index is already cached. So the
   observed facts, stated as observed: the index is not refreshed, the line is absent, and the
   yanked comparison reads a cached index. No advisory result depends on any of it, so the
   gate-3 answer below is unaffected. **The residual environment dependency, named rather than
   claimed away:** on a machine with no cached crates.io index that same `else` branch prints
   `couldn't open crates.io index: …` as a warning line, which would make the log differ there.
   That is the second and last documented way this log can vary, alongside the SKIP in item 4.
3. **Absolute paths are normalised.** `cargo tree` prints the probe package's absolute path,
   and the scratch clone's path varies per run and per machine. The script rewrites the two
   probe directories to `<feature-shape>` and `<feature-shape-r01base>` and the clone to
   `<pinned-advisory-db>`, which is what lets the log reproduce from a clean
   `git archive HEAD` extraction rather than only from the author's checkout.
4. **A named, narrowly scoped SKIP.** If the pinned commit can be obtained from neither the
   network nor a local `~/.cargo/advisory-db` mirror, section 8 prints exactly
   `SKIP: advisory-scan-skipped-pinned-db-unavailable` and contributes nothing to the exit
   status. The feature-shape status is computed as a separate variable (`rc_shape`) that always
   reaches the exit code, so a skipped advisory scan **cannot** mask a failed feature-shape
   assertion. This was tested rather than assumed, and the test is described so an auditor can
   repeat it: a **scratch copy** of the committed script, produced with `sed` and with the
   single assertion `must "axum v0.8.9" "$on"` rewritten to `must "axum v9.9.9" "$on"`, was run
   with `R69_ADVISORY_DB_URL` pointed at an unreachable host and `R69_NO_LOCAL_MIRROR=1`. It
   printed `SKIP: advisory-scan-skipped-pinned-db-unavailable`, reported `rc_shape=1`, and
   exited `1`. The scratch copy was deleted; the committed script is unmodified. The other
   three branches were exercised the same way: the local-mirror fallback (unreachable remote,
   mirror allowed → `advisory-db obtained from : local-mirror`, exit 0) and a forced
   pinned-hash mismatch (→ `FAIL`, `rc_audit=1`, exit `1`, **not** a skip).

**The remaining differences between the two scripts are mechanical**, and are listed so that a
script-to-script `diff` holds no surprises: `/usr/bin/grep`, `/usr/bin/sed` and `/usr/bin/awk`
are invoked by absolute path, and the log names the grep binary, because an interactive agent
shell on this machine resolves a typed `grep` to ugrep; the two scratch files that section 4
uses are created with `mktemp` under `${TMPDIR:-/tmp}` instead of fixed `/tmp/r69-rv*.txt`
names, because ten agents share this worktree; two header lines (`grep binary:` and
`probe dir:`) were added and therefore appear in the log; the single `rc` variable became the
pair `rc_shape` / `rc_audit` that item 4 depends on, and the final three lines of the log print
both; `--stale` accompanies `--no-fetch` so that a database pinned to a fixed commit does not
start failing cargo-audit's freshness window as it ages; and the `55 crate dependencies` line
and the advisory-count control are asserted where revision 1 asserted only the exit status.

`review/empirical/feature-shape-check.sh` and its log `review/evidence/feature-shape-check.log`
are **left byte-identical** as the record of revision 1, exactly as revision 1's
`parameters-check.log` was. The check-2 row of the table under `## Empirical check` now names
the r3 script and `review/evidence/feature-shape-check-r3.log`, and the reproducibility
paragraph there states precisely what the new check establishes. Beyond the title, this note,
the heading of the retained revision-2 note below and the preamble's synthesizer line, every
other sentence of this decision is unchanged from revision 2 except the five citation and
figure locations enumerated at the end of that paragraph.

**Revision note (revision 2), retained as the record of that revision.** Revision 2 rewrote
revision 1 (sha256
`7a1257842cfe1b39befa54e6ea0c8cdd125ee1768e13e72a1463c64d49d7d2d8`) in place. No revision of
this decision has been published, so there is no supersession section. **One owned parameter value
changes**: JF-3 requires the `<app>-serve` binary to carry the CLI Design Standard's required
global core, and revision 1 fixed that binary at "no CLI flags" inside the value of
`web-extra-surface`. Changing an owned value is permitted here only because this item is not
yet owner-accepted; the registry cell for `web-extra-surface` is still the placeholder `—` and
this revision does not edit `docs/port/PARAMETERS.md`. **The recommendation does not move**:
`axum` 0.8.9 on `tokio` 1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a
dev-dependency, and `bacon` 3.25.0 as the dev watcher are unchanged, as are every version pin,
every exclusion, every evidence script and every cited log except the one named below.

Revision 1 was **approved** by the empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r1`, model `gpt-5.6-terra`, family openai; it
reran all six scripts, five byte-identical and the sixth differing only in a sandbox-forced
advisory-database path) and **rejected** by the judgment audit (`review/audit-fable.md`, actor
`audit-fable-2026-09-12T204004Z-d02022bf6f42-r1`, model `claude-opus-5`, family anthropic) on
three blocking findings. Revision 2 answers each:

- **JF-1** — *"the serve binary's SIGTERM exit code contradicts R67's published contract, which
  the decision cites as satisfied, and the drain-deadline failure exit carries no number"*.
  Repaired by stating the serve binary's exit integers from R67's accepted taxonomy — SIGTERM
  →143, SIGINT →130, drain-deadline expiry →1 — in `### Principles and implementation`
  (criterion 4 and the new *The serve binary's process contract* paragraph), in the validation
  strategy and in the unproven table, whose acceptance test no longer says "a zero exit". The
  catalog token for the drain-deadline branch is recorded as a **request to R67**, whose
  catalog is append-only and owned there.
- **JF-2** — *"the fit ground that ranks `actix-web` runner-up and excludes `ntex` … is stated
  as present fact but is contradicted by the decision's own acceptance criterion 1 and is
  contingent on R05, which the decision records as open"*. Repaired by qualifying both
  locations (`## Decision` alternative E and the `ntex` row in *Excluded by gate and by fit*):
  the one tokio world exists when the `web` feature is **on**, and whether the CLI and library
  join it is R05's open question.
- **JF-3** — *"the new `<app>-serve` executable is fixed at 'no CLI flags' without examining
  the CLI Design Standard's required global core, which owner ruling 2026-09-14 binds to this
  template's CLI surface"*. Repaired by giving the serve binary the standard's R4.1 required
  global core and nothing beyond it, in the owned parameter value and in the new flag-surface
  paragraph, with the standard's own scope sentences cited.

**Everything revision 2 edited beyond the three findings, enumerated rather than folded in.**
Each is a consequence of a finding, not a new position, and none moves a recommendation, a
version, an exclusion or a gate answer: (1) the title, this note and the preamble's synthesizer
line; (2) a new paragraph, *What `serve_until`'s signature must carry*, because JF-1's integers
are undeliverable through the recorded `S: Future<Output = ()>`, plus its row in the unproven
table; (3) a third new unproven row for the serve binary's global-core conformance, which
nothing in this run verified; (4) three `re-verify:` triggers — R67 dispositioning the request
below, R60 selecting the parser, and the standard revising R4.1; (5) the migration table's
`src/bin/<app>-serve.rs` row; (6) two sentences in the confidence paragraph separating these
two rules, which are quoted from normative documents, from the behavior, which is unproven;
(7) the `**Sources.**` paragraph, which now lists R67, the standard and `OWNER-REVIEW.md` as
read by revision 2 on 2026-09-15. **The owned value carries changes from two findings, not
one**: JF-3's flag surface and JF-1's exit integers both sit inside it. It records only the
integers R67 has already settled — 143, 130, I/O→1 and 0 — and deliberately leaves the
drain-deadline branch out of the value, because this revision reads it as `1` under a question
R67 owns and has not yet answered; that reading lives in the prose table below, where an R67
ruling either way corrects prose rather than staling an owned value. The only evidence change
is a **rerun** of the unmodified `review/empirical/parameters-check.sh` against the revised
file, saved as the new `review/evidence/parameters-check-r2.log`; revision 1's
`parameters-check.log` is retained unchanged as the record of revision 1.

Bundle, Deep tier. Synthesizer: fresh Claude Opus 5 context, 2026-09-13; revision 2 by a
second fresh Claude Opus 5 context that produced none of this item's raws, audits or revision
1, 2026-09-15; revision 3 by a third fresh Claude Opus 5 context that produced none of this
item's raws, audits, revisions or their audits, 2026-09-15; revision 4 by a fourth fresh
Claude Opus 5 context that produced none of this item's raws, audits, revisions or their
audits, 2026-09-15; revision 5 by a fifth fresh Claude Opus 5 context that produced none of
this item's raws, audits, revisions or their audits, 2026-09-15; revision 6 by a sixth fresh
Claude Opus 5 context that produced none of this item's raws, audits, revisions or their
audits, 2026-09-16, folding in the owner-supplied reference architecture under owner decision
11; revision 7 by a seventh fresh Claude Opus 5 context that produced none of this item's raws,
audits, revisions or their audits, 2026-09-16, repairing the round-6 judgment audit's single
finding and nothing else; revision 8 by that same revision-7 context, 2026-09-16, correcting the
two record-integrity findings of the round-7 empirical audit and nothing else; revision 9 by
the revision-6 context, 2026-09-16, adding the three owner-reference rows the brief drafter's
report found undisposed and nothing else; revision 10 by a fresh Claude Opus 5 context that
produced none of this item's raws, audits, revisions or their audits, 2026-09-17, moving the six
clauses of the owned value that R02's `CONFLICT:` line names under owner ruling W1-R02 and
nothing else; runs `research/runs/R69/2026-09-12T204004Z-d02022bf6f42` (revisions 1 to 9),
`research/runs/R69/2026-09-17T014646Z-d5b96f477092` (the carried-forward run revision 9 was
published from) and `research/runs/R69/2026-09-18T020601Z-f304731ab06f` (this revision). This item was admitted ahead of the
Wave 0 review gate by owner decision Q3.A (2026-09-12) because it consumes only R01, which
the owner accepted on 2026-09-10, and because 19 items consume its owned parameter directly.
Five raw reports (codex, opus, and three Doxa providers) are listed under `## Engines`; every
figure, exclusion and disagreement below is attributed there.

## Decision

**Status: a proposal, to be validated in the implementation phase** (owner ruling,
2026-09-10). This is a P02 research decision, not a shipped design. P03 builds the template
and its CI proves the recommendation; the list of what P03 must validate is the unproven
table under `## Engines`. A recommendation that does not survive implementation is **revised
against this recorded research** — the raws, the alternatives comparison, the engine
disagreements and the evidence logs cited below — rather than researched again from scratch.

`rs-launch-blueprint` fills its already-decided optional web feature (ledger row F017,
`ADOPT`, not reopened here) with **`axum` on `tokio`, behind one additive, off-by-default
Cargo feature named `web`**:

| Member | Ledger row | Mechanism | Version |
|---|---|---|---|
| Web framework | F303 | `Router`, `State`, typed extractors and `IntoResponse` over `hyper` 1.x; `axum::serve` is the server | `axum` **0.8.9** (non-optional in `crates/web`, default features) |
| Async runtime, listener, OS signals, drain clock | F338 | multi-thread runtime, `tokio::net::TcpListener`, `tokio::signal`, `tokio::time::timeout`, `tokio::sync::oneshot` | `tokio` **1.53.1** (non-optional in `crates/web`; `rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`) |
| In-process handler test idiom | F303 (acceptance) | `tower::ServiceExt::oneshot` against the same `Router` production serves — a **`[dev-dependencies]` entry only**, not gated by `web`, because `axum` 0.8.9 already brings `tower` into the non-dev tree | `tower` **0.5.3** |
| Validated configuration and service injection | F330 | one `#[derive(Clone)] AppState` of `Arc`-held members, `axum::extract::State` with `FromRef` substates, and `build_router(state) -> Router` as the only constructor; **no lazy-load fallback** | language + `axum`, no separate crate |
| Resource registration | F331 | native `Router::merge`/`Router::nest` inside that one `build_router`; **no `ROUTERS` registry list** | language + `axum`, no separate crate |
| Optional-surface gate and target shape | F017 / F303 | one additive Cargo feature `web` on the root package, `web = ["dep:rs-launch-blueprint-web"]` making the `crates/web` member an optional dependency, and `[[bin]] required-features = ["web"]` (revision 9 wrote `#[cfg(feature = "web")] pub mod web;` here, which named a module of the declaring package that R02's accepted topology moved out of it) | Cargo, no crate |
| Production entrypoint and graceful shutdown | F338 | feature-gated `[[bin]]`, `#[tokio::main]`, `axum::serve(..).with_graceful_shutdown(..)`, with a settings-driven deadline whose clock starts **at the signal**, not at server start | Cargo + `tokio`, no further crate |
| Dev-serve recipe and auto-reload | F339 | Justfile `serve` recipe exporting a console-log env default and driving a headless restart loop; `serve-once` is the no-watcher fallback | `bacon` **3.25.0**, contributor-installed, **not** a Cargo dependency |

Settled ledger rows: **F303, F330, F331, F338, F339**.

**Not selected**, with the reason given under *Excluded by gate and by fit* below:
`actix-web` 4.15.0 (ranked runner-up), `poem` 3.1.12, `salvo` 0.96.0, `rocket` 0.5.1,
`warp` 0.4.3, `ntex`, `xitca-web` 0.8.3, `viz` 0.11.0, `tide`, `pavex` 0.2.10,
`loco-rs` 1.1.0, `dropshot` 0.17.1, a hand-written `hyper` loop, `axum::Extension` or a
`OnceLock` singleton for configuration, a function-pointer or link-time router registry,
`tower-http` (R75's to select), a direct `hyper` dependency (transitive through `axum`),
`signal-hook`/`ctrlc`, `systemfd` + `listenfd`, `cargo-watch` 8.5.3 and `watchexec-cli` 2.7.2.

### Principles and implementation

**Shared requirement.** The template ships an **optional** HTTP surface that is a thin adapter
over the same core library the CLI drives; it is composed by one explicit construction
function; validated configuration and the application service are available to handlers **and
to tests** through that construction; the production entrypoint runs the server and drains it
on a termination signal within a settings-driven window; and one developer command starts the
service with human-readable logs, distinct from the production structured profile.

**Source and agreement level.** `docs/port/COMMONALITY.md` rows F303/F330/F331/F338/F339 are
all `DIVERGENT`, origin `py-only`; `docs/port/DIVERGENCE-ANALYSIS.md` line 217 records
`harmonize: partly` at scope level. The level at which agreement is required is **capability**:
py, ts and rs must each be able to expose the core library over HTTP without a mirror data
model. What must **not** be harmonized is the mechanism — FastAPI's `Depends`, Hono's context
bindings and axum's `State<S>` are three ecosystem-appropriate realizations of one injection
principle, and no shared low-level value (route naming, DI shape, server library, watcher) is
recommended, because neither an explicit owner requirement nor evidence of the same tradeoff
in all three ecosystems supports one. All five engines agree on this framing.

**Essential behaviors and observable acceptance criteria.** These are requirements on P03's
template, not results of this run. Criteria 1, 3 and 5 were exercised here in the reduced,
verification-only forms described under `## Empirical check`; criteria 2, 4 and 6 were not,
and are carried in the unproven table under `## Engines`. **Revision 10 scopes criteria 1 and 5 to the shape their probe ran on.** That probe was the single-package shape this revision superseded, and its script and log are deliberately left byte-identical, because no evidence result moves in this revision; the same two observables were executed on R02's owner-accepted four-package shape by R02's own checks `B1`, `B2`, `B4` and `F` (`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/evidence/r02-workspace-probe.log`), which is where a reader should look for the workspace reading. Criterion 5's "module" is now the optional member crate, and criterion 1's `cargo tree -e normal` is root-package-scoped, which R02's check `F` projects.

1. **The surface is optional and costs nothing when off.** *Observable:* with no features,
   `cargo tree -e normal` lists no `axum`, `tokio`, `hyper` or `tower`, and
   `cargo build --bins` produces no serve binary. *Verified here on a manifest probe*
   (`review/evidence/feature-shape-check-r4.log`, sections 1, 2, 6 and 7), not on a template.
2. **The web handler reaches the same erased service the CLI reaches, over the same
   serialisable type, with no mirror struct** (R01 acceptance criterion 6). *Observable:* the
   handler's return type names the library's own `Project`, and a real HTTP GET against a
   bound listener decodes into the library's `Vec<Project>`. **Not run here** — that is a
   request-path behavior, and building it would mean building the recommendation.
3. **Configuration and the service are injected by explicit construction, checked by the
   compiler.** *Observable:* `build_router(state: AppState) -> Router` is the only way to
   build the app, and a handler asking for a substate the app never registered fails to
   compile rather than returning 500 at request time. *Partly verified here:* the type-level
   half — that R01's erased service satisfies axum's declared state bound — is
   `review/evidence/state-bound-check.log`. The compile-failure demonstration for an
   unregistered substate is P03's.
4. **The production entrypoint drains in-flight work on SIGINT/SIGTERM and gives up after a
   configured deadline.** *Observable:* the serve future is bounded by a timeout whose value
   comes from settings and whose clock starts when the shutdown signal fires, and the process
   exits with R67's integer for the signal that started the drain — **143** after SIGTERM,
   **130** after SIGINT, and **1** when the deadline expires (see *The serve binary's process
   contract* below). **Not run here**; the enabling fact — that axum supplies no deadline of
   its own — was verified by reading the published source (below).
5. **The `web` feature is what CI, container and docs gates select.** *Observable:* one
   feature name gates module, binary target and tests together. *Verified here* on the
   manifest probe: `cargo metadata` reports `"required-features":["web"]` on the binary
   target and `null` on the library target.
6. **One dev command serves with console-formatted logs and restarts on a source edit.**
   **Not run** — the environment variable's name and semantics belong to R58's unpublished
   `logging-pipeline-contract`. The tool's own capabilities were verified instead
   (`review/evidence/bacon-install-check.log`).

**Landscape — the three-bin map.** *Built-in / first-party toolchain:* `std::net` plus a
hand-written HTTP loop; Cargo `[features]`, `dep:` syntax, `optional`, `[[bin]]
required-features`, `#[cfg(feature = ..)]`; the `#[test]` harness; `cargo run`. `hyper`
1.11.1 is first-party-adjacent — the reference HTTP implementation nearly every candidate
embeds — not `std`. *Established industry standard:* `axum` 0.8.9, `actix-web` 4.15.0,
`warp` 0.4.3, `rocket` 0.5.1, `poem` 3.1.12; substrate `tokio` 1.53.1, `hyper` 1.11.1,
`tower` 0.5.3, `tower-http` 0.7.1; in the dev-reload sub-field, `cargo-watch` 8.5.3 (now
archived). *Up-and-comer:* `salvo` 0.96.0, `ntex`, `xitca-web` 0.8.3, `viz` 0.11.0,
`loco-rs` 1.1.0 (built *on* axum), `pavex` 0.2.10 (compile-time framework generator),
`dropshot` 0.17.1 (Oxide Computer's API-first framework); `tide` is the field's dead end,
kept in the map as a warning rather than a candidate; in the dev-reload sub-field,
`watchexec-cli` 2.7.2, `bacon` 3.25.0, and `systemfd` 0.4.6 + `listenfd` 1.0.2. Every
shortlisted candidate comes from that map.

**Authorities, and why each counts.** (1) `rust-lang/crates.io` at commit
`3df99c214d640090ab38aad14ae9c34289b0dec0` — the Rust project's own production web service
and the only surveyed codebase with this template's exact shape (a Cargo workspace of web
service, workers and library crates, `edition = "2024"`, `license = "MIT OR Apache-2.0"`);
R01 already established it as this programme's reference implementation. (2) Maintainers'
own published `.crate` artifacts read at an exact version — the literal bytes a consumer
compiles, and the manifests the MSRV gate is read against. (3) crates.io and the GitHub REST
API as the registries of record for population figures, not for judgement. (4) RustSec plus
an executed `cargo audit` for advisories. (5) The Rust project's 2025 State of Rust Survey
results, used **only** for the general finding that compile time and resource usage remain a
top reported problem; that report publishes no web-framework breakdown, so no framework share
is claimed from it. Deliberately **not** treated as authorities: single blog posts, framework
comparison articles, and any TechEmpower composite (see *Performance* below).

**Practice evidence, with the standing shown rather than asserted.** `rust-lang/crates.io`
pins `axum = "=0.8.9"` and `tokio = "=1.53.1"` in one workspace and is run by the Rust project
itself. `apollographql/router` (Apollo's commercially shipped GraphQL router) depends on
`axum` — reported by the opus raw at commit `e7b2b32`, not re-read here.
`meilisearch/meilisearch` depends on `actix-web` 4.14.1 — reported by the opus raw at commit
`a955694`, not re-read here; it is cited as the counterweight establishing actix-web's
production standing, not as a point against axum. `qdrant/qdrant` resolves `actix-web` in its
lockfile (openai raw). `axum` itself is maintained inside the `tokio-rs` organisation
alongside `tokio`, the substrate every established candidate except `ntex`/`xitca-web` sits on.

**Architectural alternatives compared, before any crate was weighed.**

| Alternative | Shape | Verdict and reason |
|---|---|---|
| A. No framework: `hyper` + a hand-written router | `service_fn` over `hyper_util::server::conn::auto` | Rejected. It buys nothing this template needs and pushes routing, extraction and response encoding into template code that R70–R80 would each have to re-solve. It is what every candidate embeds anyway. |
| **B. Framework with a compile-checked state type** | `axum`'s `Router<S>`/`State<S>`; `build_router(state) -> Router` | **Chosen.** A missing-state wiring mistake is a type error rather than a 500 under traffic, and every test constructs state the same way production does — which is precisely what removes the need for py's lazy fallback. |
| C. Framework with a runtime type-map for state | `actix-web`'s `web::Data<T>`, or axum's own `Extension` | Rejected as the primary mechanism. actix-web's own documentation states that using `Data<T>` when route data is not set "would cause a 500 Internal Server Error" (opus raw, `actix-web-4.15.0/src/data.rs:39`). A template whose purpose is to be copied should not ship a wiring-mistake class that only appears under traffic. |
| D. Batteries-included stack | `loco-rs` 1.1.0, `pavex` 0.2.10 | Rejected. This repository *is* the template; a second opinionated template inside it would own decisions R70–R80 are already assigned. `loco-rs` is itself built on axum, so choosing axum keeps that door open for template users. |
| E. Framework with its own runtime layer | `actix-web` + `actix-rt`/`actix-server`; `ntex` | **Ranked runner-up** (`actix-web`), not chosen. It is production-proven and its `HttpServer::shutdown_timeout(sec)` is a closer literal analogue of py's `timeout_graceful_shutdown`. The layering ground, stated with its conditions: **when the `web` feature is on**, the web surface and any future async adapter live in one tokio world, and actix-web would insert `actix-rt`/`actix-server` beside it inside that same feature — `tokio` is absent from the feature-off tree by criterion 1, measured in check 2, so this is not a claim about the template's default build. **Whether the CLI and library join that world is R05's open question** (`sync-async-execution-model`, recorded open under `## Parameters`): under an async R05 they do and the ground is at its strongest; under a synchronous R05 they do not, and the ground weakens to two runtime abstractions inside the feature rather than one. The ranking does not rest on it alone — the `Data<T>` runtime failure mode in alternative C holds either way. |

**Why the chosen design preserves each principle.** Optionality is carried by a Cargo
feature, the direct analogue of py's install extra. "Thin adapter over one contract" is
carried by `AppState` holding R01's erased service unchanged and by handlers returning the
library's own `serde`-derived types. "Config available to handlers and tests" is carried by
`FromRef` substates on one `AppState`, which is stronger than py's dependency-injection graph
because it is checked at compile time. "Drain on signal" is carried by
`axum::serve(..).with_graceful_shutdown(..)` plus an explicit, settings-driven deadline.
"One dev command" is carried by a Justfile recipe.

**F330 — the requirement behind py's lazy fallback, and whether Rust needs it.** py's
`get_config` (`src/py_launch_blueprint/web/deps.py:37`, read by the opus and codex raws at
programme pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`) falls back to `load_config()` when
`request.app.state.config` is unset, for "raw ASGI callers like schemathesis that bypass the
lifespan". The requirement behind it is *every caller of the app object — production, tests,
contract fuzzers — sees a loaded configuration*. The fallback exists because in FastAPI the
app object can be constructed and called without its lifespan ever running, so the invariant
is unenforceable at construction time. In Rust with axum it is enforceable: a `Router<S>` is
not a service until `with_state` has supplied `S`, so `build_router(state)` makes a
configuration-less app unrepresentable and a fallback would be dead code hiding a wiring bug.
**The Rust template must not port the lazy fallback**; it ports the invariant instead. All
five engines reach this conclusion independently.

BASELINE-REVIEW: F330 — validated configuration is available to every caller of the app object, including tests and contract fuzzers — drop py's lazy-load fallback in the Rust template and carry the invariant in the type system instead: `build_router(state: AppState) -> Router` is the only constructor, so an app without configuration cannot be built or called; affected items: R69 (this row), R77 (`web-env-settings`, which must expose a settings value the composition root constructs, not a lazily-loadable global), R83 (`openapi-contract-fuzzing`, whose fuzzer must construct the app through the same factory tests use rather than bypassing a lifespan) — evidence: py's fallback exists because a raw-ASGI caller can skip the lifespan (`src/py_launch_blueprint/web/deps.py:37` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read by the opus and codex raws); axum 0.8.9 makes the equivalent state unrepresentable because its state-carrying `impl<S> Router<S>` block is bounded `S: Clone + Send + Sync + 'static` and `with_state` is what turns a `Router<S>` into a service (`axum-0.8.9/src/routing/mod.rs:138-141` and `:408`, read in this run at the published artifact — `review/evidence/assert-figures.log`, section G).

**F331 — native composition versus a registry list.** py registers resources by iterating a
module-level list: `for router in ROUTERS: app.include_router(router, prefix=V1_PREFIX)`. The
prompt's baseline review (2026-09-04) asks that native composition be compared before a
registry is accepted, keeping "explicit, straightforward resource registration" as the
acceptance behavior. Evidence from the reference implementation, read in this run:
`rust-lang/crates.io` composes its entire API by chained explicit calls inside one function
ending in `.with_state(state)`, with **no registry list and no registration loop**
(`src/router.rs` at `3df99c2`; asserted in `review/evidence/assert-figures.log`, section F).
In axum the native operators are `Router::merge` (same prefix) and `Router::nest` (sub-path),
and a per-resource `pub(crate) fn router() -> Router<AppState>` composes with one line at the
call site. **Recommendation: native composition in one `build_router`; no `ROUTERS`
registry.** Adding a resource stays one import plus one line, which satisfies the acceptance
behavior with less machinery than a registry, and a missing registration is visible at the
composition site rather than in a separate list. The alternatives rejected on fit: a
`const ROUTERS: &[fn() -> Router<AppState>]` slice adds indirection that buys nothing where
the composition site is already one line per resource, and a link-time registry (`inventory`,
`linkme`) makes route registration invisible in source order, which is unacceptable in a
template whose readers are learning the layout. Note for R71/R72: axum 0.8 changed
path-parameter syntax from `/:id` to `/{id}`, and the old form panics rather than silently
changing behavior (opus raw, `axum-0.8.9/CHANGELOG.md:121-122`).

BASELINE-REVIEW: F331 — resource registration is explicit and straightforward — compose per-resource `axum::Router` values with `merge`/`nest` inside one `build_router` function rather than freezing py's module-level `ROUTERS` registry list into the Rust template; affected items: R69 (this row), R71 (`openapi-generation-pipeline`, whose route/OpenAPI composition must attach to native routers rather than to a registry), R75/R78/R79 (whose layers wrap the composed router from outside) — evidence: py's list-and-loop is FastAPI-specific (`src/py_launch_blueprint/web/app.py` and `web/routers/__init__.py` at pin `b08bccfb`, read by the opus and codex raws), while `rust-lang/crates.io` registers its resources by chained explicit calls with no registry and no loop (`src/router.rs` at commit `3df99c214d640090ab38aad14ae9c34289b0dec0`, asserted in `review/evidence/assert-figures.log`). Codex, opus, openai and gemini raise this finding independently and agree on the direction.

**F338 — the entrypoint, and what graceful shutdown needs beyond the framework.** The
mechanism is `axum::serve(listener, router).with_graceful_shutdown(signal)`, with the signal
future built from `tokio::signal::ctrl_c()` and, under `#[cfg(unix)]`,
`tokio::signal::unix::signal(SignalKind::terminate())`. Both maintained references do exactly
this: axum's own `examples/graceful-shutdown/src/main.rs` at tag `axum-v0.8.9`, and
`rust-lang/crates.io`'s `src/bin/crates-io/server.rs` at `3df99c2`, which selects over SIGINT
and SIGTERM (asserted in `review/evidence/assert-figures.log`, section F). **No crate beyond
`tokio` is needed** — its `signal` feature covers both signals on both legs of
`target-os-matrix`; `signal-hook` and `ctrlc` add a dependency for something already present,
and `hyper-util`'s `GracefulShutdown` is the layer `axum::serve` exists to wrap.

**The unreleased 0.9 line lands on exactly this mechanism, which sharpens the existing
`re-verify` trigger rather than changing the recommendation** (owner-reference *Key Finding 1*
and *Recent-Bugs-vs-Plan Register*; owner decision 11, row 1). The document's factual half is
confirmed: **axum has published nothing at or above 0.9**. Its registry `max_version`,
`max_stable_version` and `newest_version` all read `0.8.9`, and the set of published versions
starting `0.9`, `1.` or `2.` is **empty** across all 94 published versions
(`review/evidence/owner-reference-check-r6.log`, section A). The **inference** the document
draws from that — "This makes a 3-year horizon on 0.8 safe", with the pending breaking changes
"concentrated in **axum-extra**" — is stated more absolutely than its source, and this item
records the source instead:

- The statement the document paraphrases as "There isn't a timeline yet" is a comment by
  `mladedav` (`author_association: COLLABORATOR`) on `tokio-rs/axum` issue **#3809**
  (*Inquiry about the release timeline and features for axum 0.9.0*, closed 2026-06-30), and
  it reads, verbatim: *"There isn't any set timeline. We'd like to do it soon, but no promises
  and it could mean pretty much anything."* The second sentence is the half the document drops,
  and it is the half that bears on a three-year horizon.
- The breaking changes are **not** confined to `axum-extra`. The `release-plz` pull request
  **#3745** (*chore: release main (0.9)*, opened 2026-05-05, **closed without being merged** —
  `merged: false`, `merged_at: null`, which is why the registry still shows no 0.9.0) proposes
  `axum`: `0.8.9 -> 0.9.0` and lists its `cargo-semver-checks` failures against
  `axum/src/serve/mod.rs`: **`function serve` (3 → 4 generic types)**, **`trait Serve` (3 → 4
  required generic types)** and **`trait WithGracefulShutdown` (4 → 5 required generic
  types)**.
- Pull request **#3819** (*Extract `axum::serve` and friends into new `axum-serve` crate*) is
  **open** in milestone **0.9**.

All four facts are asserted in `review/evidence/owner-reference-check-r6.log`, section C.
**What this changes here: nothing, and that is the finding.** `axum::serve(..)
.with_graceful_shutdown(..)` is the F338 mechanism at 0.8.9, the version this decision
recommends and the only one published; a caret requirement cannot cross into 0.9 (see
*Compatibility*); and this decision's `re-verify:` line already fires **when axum publishes
0.9**. What is added is the shape of the work that trigger implies — the migration surface is
`serve_until`'s own call site, not a peripheral crate — and a caution against reading the
document's three-year horizon as a reason to build more on that surface than F338 needs. The
claim that the repository's "highest tag is `axum-v0.8.9`" was **not** re-verified: the GitHub
tags endpoint returns an unordered page, and the registry — the authority this decision already
uses for version facts — settles the same question.

What the framework does not give you is py's `timeout_graceful_shutdown`. **axum's drain is
unbounded by construction**: after the signal it stops accepting and then awaits
`close_tx.closed()` with no deadline. This run verified that by reading the published source
rather than inferring it — `axum-0.8.9/src/serve/mod.rs` contains the
`close_tx.closed().await` and **zero** occurrences of `timeout` or `deadline`
(`review/evidence/assert-figures.log`, section G). `rust-lang/crates.io` accepts that
unbounded drain: its call site awaits `axum::serve(..).with_graceful_shutdown(..)` directly,
and the one `Duration` in that file is a metrics logging interval (same log, section F). To
mirror py's settings-driven window the template must add the deadline itself.

**The deadline's clock must start at the signal, not at server start.** This is the one place
the raws disagree on something that is simply right or wrong. The opus and perplexity raws
both wrap the whole serve future — `tokio::time::timeout(Duration::from_secs(cfg.graceful_shutdown_seconds), server)`
— which bounds the server's entire lifetime and would terminate a healthy service after the
grace period. Only the openai raw gets it right, by signalling the start of shutdown over a
channel and applying the timeout to the already-pinned server future from that moment:

```rust
pub async fn serve_until<S>(listener: TcpListener, app: Router, shutdown: S, grace: Duration)
    -> Result<(), ServeError>
where S: Future<Output = ()> + Send + 'static,
{
    let (started_tx, mut started_rx) = tokio::sync::oneshot::channel::<()>();
    let server = async move {
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { shutdown.await; let _ = started_tx.send(()); })
            .await
    };
    tokio::pin!(server);
    tokio::select! {
        result  = &mut server  => result.map_err(ServeError::Io),
        _ = &mut started_rx => tokio::time::timeout(grace, &mut server).await
            .map_err(|_| ServeError::GracefulShutdownTimedOut(grace))?.map_err(ServeError::Io),
    }
}
```

That shape has a consequence for the manifest, also verified here: it needs
`tokio::sync::oneshot`, and **tokio 1.53.1's `sync` feature is enabled by none of
`signal`, `net`, `rt-multi-thread`, `time` or `macros`** — each was read from the published
feature graph (`review/evidence/assert-figures.log`, section G). So `sync` joins the feature
list; the opus raw's list omits it. A `sync`-free alternative exists — a second independent
signal listener raced against `tokio::time::sleep(grace)` inside the outer `select!`, which
works because tokio's signal listeners are independent — and is recorded here as the
variation to take if a consumer wants the narrower feature set. Gemini's proposal to bound
shutdown with `tower_http::timeout::TimeoutLayer` is a **per-request** bound, not a drain
deadline; the two are complementary, and the per-request layer is R75's to decide (axum's own
example uses it for exactly that adjacent problem).

**A deployment datum for R77's drain-deadline default, verified at Google's own page and handed
off rather than decided here** (owner-reference *Cloud Run Runbook*, the *Graceful shutdown*
caveat; owner decision 11, row 4). This item fixes the deadline's **mechanism** — a
settings-driven `tokio::time::timeout` whose clock starts at the signal — and leaves its
**value** to R77 (`web-env-settings`), which owns the environment variable. One published
platform constraint bears on that value strongly enough to record. Google's *Container runtime
contract*, requested at `https://cloud.google.com/run/docs/container-contract` and served
HTTP 200 from `https://docs.cloud.google.com/run/docs/container-contract`, says under
*Container instance lifecycle → Shutdown*, **for services**, verbatim:

> Before shutting down an instance, Cloud Run sends a SIGTERM signal to all the containers in
> an instance, indicating the start of a 10 second period before the actual shutdown occurs, at
> which point Cloud Run sends a SIGKILL signal.

Asserted in `review/evidence/owner-reference-check-r6.log`, section E, which also asserts the
neighbouring sentence *"If the instance doesn't shut down on its own within a few seconds after
receiving SIGTERM, Cloud Run sends a SIGKILL signal for a forced termination"* — that one sits
under **For jobs**, a different surface, and is asserted alongside so the two cannot be read as
contradicting each other. **The hand-off to R77, stated as a datum and not as a default:** on
that platform a drain deadline is honoured only if it is strictly shorter than 10 seconds
**measured from SIGTERM**, because the SIGKILL is unconditional at the deadline and the process
never reaches its own exit path — so R67's 143 would never be observed. **This is precisely the
distinction the clock-start rule above makes**, which is why that rule is not a fine point: a
whole-lifetime wrapper — the shape the opus and perplexity raws propose — bounds the server's
lifetime rather than the drain, and therefore answers nothing about a window that begins at the
signal. R51 (`container-image`) is the other consumer. **Cloud Run is not adopted as a target
by this item**: `target-os-matrix` is `ubuntu-latest, macos-latest`, this template ships no
deployment, and the document's Cloud Run rows are listed among the hand-offs under
`## Engines`.

**A hazard recorded for a later WebSocket layer, verified and not acted on here**
(owner-reference *C7*, "Known Axum issue … issue #3003"). The issue exists and says what the
document says it says: `tokio-rs/axum` issue **#3003**, *Graceful Shutdown ignores Websocket
handler task*, opened 2024-10-21 against **axum 0.7.4** and still **open**, reporting that
*"The task spawned in `ws.on_upgrade` is not connected to the graceful shutdown future at
all."* (`review/evidence/owner-reference-check-r6.log`, section F). **It changes nothing in
this decision.** The `web` feature recommended here enables axum's default features, which do
**not** include `ws`; nothing in this item's scope performs a WebSocket upgrade; and
`serve_until`'s deadline behaves identically either way. The hazard is real for whoever adds
that surface — an upgraded connection's task outliving the drain is exactly what the
ten-second window above converts into a SIGKILL — and the document's mitigation (`TaskTracker`
plus `CancellationToken`, and a close frame on SIGTERM) is recorded with it as that layer's
starting point, unverified here. **This programme has no P02 item for WebSockets**; the row is
listed under `## Engines` as pending owner scoping.

**The serve binary's process contract — R67's integers, not this item's.** R67
`error-and-exit-code-contract` is published and owner-accepted (2026-09-14, at
`research/topics/67-error-and-exit-code-contract/DECISION.md`, sha256
`16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`, read 2026-09-15), its
owned `error-taxonomy-exit-codes` fixes the taxonomy `0/1/2/3/4/5/130/143` with "unlisted
failures collapse to `1`", and it names this item as bound: "R05 (`sync-async-execution-model`)
and R69 (`web-extra-surface`) decide the web surface's signal source, which must return the
same 130/143". Revision 1 asserted agreement with R67 while leaving the numbers out; they are
stated here. The entrypoint returns `ExitCode` from `main` rather than calling `process::exit`,
which is what R67 requires, and:

| Serve-binary termination | Exit | R67 catalog row |
|---|---:|---|
| Drain initiated by `SIGTERM` completes inside the deadline | **143** | `RSLB902` SIGTERM → 143 |
| Drain initiated by `SIGINT` (Ctrl-C) completes inside the deadline | **130** | `RSLB901` SIGINT → 130 |
| Drain deadline expires — `ServeError::GracefulShutdownTimedOut` | **1** | none yet; see the request below |
| Bind, accept or other `std::io` failure — `ServeError::Io` | **1** | `RSLB101` I/O → 1 |
| The server future returns without a signal (normal `axum::serve` completion) | **0** | — |

**Request to R67 — one appended catalog row, no exit integer invented.** R67's catalog is
append-only and R67 owns it, so this item does not mint a code. The drain-deadline branch is a
*failure*, not a clean signal exit: the process gave up on requests it had accepted. R67's
taxonomy therefore gives it **1** today, as an unlisted failure, and until R67 appends a row the
branch exits 1 carrying no catalog token of its own. **The request:** append one `1xx` row —
the hundreds digit is the exit code in R67's scheme, so a `1xx` token implies exit 1 and
nothing else — for *graceful-shutdown drain deadline exceeded*; the next free slot in that block
appears to be `RSLB105` (`RSLB101`–`RSLB104` are taken), but the token is R67's to assign.
**One question travels with the request**: R67's boundary precedence is *signal → broken pipe →
domain error → unexpected*, which could instead be read as making any SIGTERM-initiated
termination 143 even when the drain failed. This item reads the timed-out drain as a domain
failure, because the observable outcome differs from a clean drain and R51's container image and
the template's process tests consume that difference; R67 owns the final reading. This is not a
`CONFLICT:` line — R67 is not on this item's `- consumes:` line, and nothing here diverges from
its published value — and not a `BASELINE-REVIEW:` line, because no py/ts baseline behavior is
at issue.

**What `serve_until`'s signature must carry, which the recorded shape does not.** The snippet
above takes `S: Future<Output = ()>`, a signal future that has forgotten *which* signal fired —
so as drawn it cannot deliver 130 versus 143. This is the same defect R67 excluded `ctrlc` for:
"the handler specified by `set_handler()` will be executed for `SIGINT`, `SIGTERM` and `SIGHUP`
… `ctrlc` therefore *cannot* produce distinct 130/143". The way out is already in this
decision's F338 mechanism rather than in a new dependency: `tokio::signal::ctrl_c()` and
`tokio::signal::unix::signal(SignalKind::terminate())` are two separate sources selected over —
the shape the reference implementation uses, asserted in check 3 as "selects over SIGTERM via
`tokio::signal::unix`" — so the `select!` inside `shutdown_signal()` can report which arm fired.
P03 threads that answer out: the future resolves to the signal kind, or directly to R67's `Exit`
value, rather than to `()`. **No check in this run exercised that**, and the row is carried in
the unproven table below. The snippet is retained unedited because it is the drain *shape* this
decision settles, and the clock-start rule it demonstrates is unaffected by what the future
carries.

**The serve binary's flag surface, under the binding CLI Design Standard.** Revision 1 fixed the
binary at "no CLI flags", copying py's `__main__.py`, which is the inherited-mechanism move the
research mandate asks to be justified rather than ported. Owner ruling 2026-09-14
(`docs/port/OWNER-REVIEW.md`, *"the CLI Design Standard binds, and OV-01 is refused"*) makes
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` v1.4.14 govern this template; its
header reads "Applies to: All new CLIs, any language" and its R4.1 opens "Every CLI **MUST**
implement the **required global core**". A second shipped executable is such a CLI, and the
standard offers it no exemption: its only profile relaxation, Appendix A's Small-CLI
(verb-first) profile — which `<app>-serve` would otherwise fit, being a single-purpose tool with
no resource nouns — states that under it "every other rule in Part III applies unchanged …
standard options (§4)". **So `<app>-serve` carries R4.1's required global core, and nothing
beyond it:**

| Option | Short | Meaning, per R4.1 | Who binds its behavior |
|---|---|---|---|
| `--help` | `-h` | print help for the binary and exit `0`, on stdout (R7.5, R7.1) | the standard; help layout is R60's parser |
| `--version` | `-V` | print version and exit `0`, on stdout — the single line `<app>-serve <semver>` per R4.6 and the owner's 2026-09-14 refusal of OV-01 | the standard; R60 |
| `--verbose` | `-v` | increase diagnostic detail, repeatable (R4.4) | R58's `logging-pipeline-contract` binds what the levels select |
| `--quiet` | `-q` | suppress non-essential stderr output; never suppresses stdout (R4.4) | R58 |
| `--config` | — | path to a config file, overriding discovery (R5.2) | R54's `config-discovery-tiers` and R77's `web-env-settings` |
| `--debug` | — | maximum diagnostics including internal detail (R4.4) | R58 |

Everything else stays out. The result-output tier (`-o`/`--output`, `--json`) is not required:
R4.1 scopes it to "commands that emit formatted result data", and this binary's stdout carries
no result set — it serves HTTP and logs to stderr. No safety/action option applies: it creates,
deletes and confirms nothing. Every *service* knob — host, port, log format, drain deadline —
remains an environment variable, as py's `__main__.py` has it and as R77 will name them; the
standard's R5.1 precedence (flag > env > config > default) is satisfied vacuously where no flag
exists for a knob. This adds **no crate to the `web` feature**. Revision 6 put that on a
condition — *"on a condition rather than as a present fact: the parser is R60's open choice, and
whichever crate R60 selects for the CLI binary is a non-optional dependency of the package"* —
and **that wording is superseded by the owner's acceptance of R60**: `docs/port/OWNER-ACCEPTANCES.md`
records R60 revision 7, sha256
`67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2`, accepted on **2026-09-15**
as "W0-R60 option A; `clap` 4.6.6 derive, `clap_complete` 4.6.9, dependency-free `build.rs`",
with first publication pending. So the parser is **selected, and unpublished as yet**, not open:
`clap` 4.6.6 with its `derive` API is a non-optional dependency of the package for the CLI
binary, and the serve binary parses R4.1's core with it instead of introducing one. The design
consequence is the one revision 6 stated, and the accepted answer strengthens rather than
weakens it. Check 2's measured 12 → 52 package delta stands unchanged **by construction,
not by re-measurement** — a non-optional dependency appears in both counts, so it cancels out
of the delta that is the feature's marginal cost. The CLI binary keeps its own flags. A `serve` subcommand on the existing
CLI binary is the ranked runner-up shape, rejected as primary because it would put `tokio` and
`axum` in the default CLI build unless the subcommand were itself feature-gated, and because
py's separate entry point is the shape R51's container image expects.

**F339 — the dev-server recipe, and what the owner's licence ruling changed.** py's recipe
(`Justfile:291`, pin `b08bccfb`) runs uvicorn with `--reload` after defaulting
`<APP>_WEB_LOG_FORMAT` to `console`. Two halves: a console-log default distinct from the
production structured profile, and auto-reload. The console half ports cleanly — one exported
environment variable whose name and semantics belong to R58 and R77, not to this item.

The auto-reload half is where the raws disagreed and where **owner ruling Q7.B of 2026-09-12
changes the answer**. Four of the five raws excluded `bacon` on fitness gate 1 because it is
`AGPL-3.0`; the opus raw then demoted auto-reload from a required recipe to an optional one
explicitly *because every surviving candidate failed a gate*. Gate 1 is struck. Re-evaluating
on the surviving grounds only:

| Candidate | Newest non-yanked | Declared `rust-version` (gate 2) | Maintenance | Outcome |
|---|---|---|---|---|
| `cargo-watch` | 8.5.3 (2024-10-02) | 1.75.0 — passes | repository `archived: true`, `pushed_at` 2025-01-14, and the README at tag `v8.5.3` says it "is on life support: it will not receive further updates … I recommend Bacon or Watchexec instead" | **Excluded on maintenance** — a maintainer's own end-of-life notice is `dormant` under the rubric. This ground survives the ruling. |
| `watchexec-cli` | 2.7.2 (2026-09-06) | **none declared** — fails | `archived: false`, `pushed_at` 2026-09-07 | **Excluded by gate 2**, under the strict reading settled 2026-09-11. This ground survives the ruling. |
| **`bacon`** | **3.25.0 (2026-08-23)** | **1.85 — passes** | `archived: false`, `pushed_at` 2026-09-12, 47 open issues, median 0.02 days to first maintainer response over the 10 most recently opened issues with 3 unanswered | **Selected.** Its only recorded exclusion was gate 1, which is now inapplicable. |
| `systemfd` + `listenfd` | 0.4.6 / 1.0.2 | 1.64.0 / **none declared** | `stable-quiet` | Not needed. Socket hand-off preserves connections across a restart, which is not a behavior F339 asks for, and `listenfd` would have to be linked into the shipped binary. |

So **auto-reload is restored to the required recipe, with `bacon` 3.25.0 as the named
watcher.** The opus raw's `BASELINE-REVIEW: F339` line — which proposed demoting auto-reload
to an optional recipe — is **withdrawn**; its premise no longer holds and F339 now ports at
capability level with no baseline change. This is the one recommendation in this item that
the licence ruling changed; everything else is unaffected.

Four capabilities of the tool were verified rather than assumed, because a TUI-first runner is
not obviously able to serve a long-running process with plain console logs
(`review/evidence/bacon-install-check.log` and `assert-figures.log`, section G):

- **A `run-long` job exists in the shipped defaults**, with `on_change_strategy =
  "kill_then_restart"`, `background = false` and `need_stdout = true`. `bacon --list-jobs` in
  a directory with no `bacon.toml` lists it, so reaching it needs no project configuration.
- **`--headless` streams the child's own output to the terminal**, not into a TUI pane:
  `CommandStream::StdOut => print!(..)`, `StdErr => eprint!(..)` in `src/tui/app.rs`. That is
  what makes the console half of F339 hold.
- **`--features` is plumbed through to the cargo command** (`src/mission.rs`), and arguments
  after `--` are appended to the job's command tokens, so the recipe needs no custom job
  definition to select the feature and the binary.
- **`-j run-long` still selects the job under `--headless`.** This needed checking rather than
  assuming, because bacon's own `--help` describes `--headless` as running "the default job on
  change" — had that been literal, the recipe would have looped `cargo check` and never started
  the server. Read at source: `-j` is stored as `settings.arg_job`, the initial job is
  `settings.arg_job` falling back to `default_job` (`src/jobs/job_stack.rs`), and every one of
  the four `headless` references in `src/cli/mod.rs` guards the alternate-screen setup, none of
  them job selection. No `default_job` override is required in the template's `bacon.toml`.
- **The default job interruption on Unix is `SIGKILL`** (bacon's own configuration reference).
  A SIGKILL restart cannot exercise the production drain path, and it kills the `cargo`
  process rather than the server it spawned. **The template must therefore ship a small
  `bacon.toml` overriding `run-long`'s `kill`** so a dev restart runs the same SIGTERM drain
  the container does. The opus raw's migration list states that no `bacon.toml` is needed;
  that is wrong on this point, and the correction is recorded here.

**The owner-supplied document agrees on the tool and this item's finding is the stronger one**
(owner-reference *C14*, "bacon (or cargo-watch) for reload … bacon better UX"; owner decision
11, row 3). The document's stack table picks `bacon` over `cargo-watch` on developer
experience. This decision reaches the same pick on a different and harder ground — gate 2 plus
`cargo-watch`'s own end-of-life notice at tag `v8.5.3`, with gate 1 struck by owner ruling
Q7.B — so agreement is recorded and nothing moves. **What the document does not carry is the
SIGKILL finding above**, which is the one fact that makes the recommendation usable: a `bacon`
recipe without the `bacon.toml` `kill` override never exercises the production drain path, and
the document's C14 row prescribes no `bacon.toml` at all. The override stands as recorded, and
its unproven row in the table under `## Engines` is unchanged. **Two of that row's three tools
are hand-offs, not this item's:** `cargo-chef` is a Docker dependency-layer cache and belongs
to **R51** (`container-image`); `mold`/`lld` is a linker selection that reaches the release
build and belongs to **R68** (`release-binary-artifacts`), with R42's published
`package-manager-invocation` governing how either is invoked. Neither is researched here and
neither is recommended or excluded by this item. The document's fourth C14 element, pinning the
toolchain with `rust-toolchain.toml`, is `msrv-policy`'s and R42's territory and is likewise
not decided here.

Recommended recipes, following R42's published `package-manager-invocation` (bare executables
resolved on PATH, no provisioner prefix; presence tested with `command -v bacon`, the rule
that parameter sets for a tool installed from crates.io):

```just
# Serve with dev-friendly console logs, restarting on source changes.
# Requires `bacon` on PATH: cargo install bacon --version 3.25.0 --locked
serve host="127.0.0.1" port="8000":
    #!/usr/bin/env bash
    set -euo pipefail
    command -v bacon >/dev/null || { echo "bacon not found: cargo install bacon --locked" >&2; exit 1; }
    export <APP>_WEB_HOST="{{host}}" <APP>_WEB_PORT="{{port}}"
    export <APP>_WEB_LOG_FORMAT="${<APP>_WEB_LOG_FORMAT:-console}"   # names owned by R58/R77
    exec bacon --headless -j run-long --features web -- --bin <app>-serve

# Same service, no watcher and no extra tool. The escape hatch.
serve-once host="127.0.0.1" port="8000":
    #!/usr/bin/env bash
    set -euo pipefail
    export <APP>_WEB_HOST="{{host}}" <APP>_WEB_PORT="{{port}}"
    export <APP>_WEB_LOG_FORMAT="${<APP>_WEB_LOG_FORMAT:-console}"
    exec cargo run --features web --bin <app>-serve
```

**The tradeoff stated plainly.** py's watcher arrives with the `web` install extra; Cargo
cannot install binary tools as dependencies, so `bacon` is one `cargo install` per
contributor and `serve-once` exists for anyone who has not run it. Against that, the reload
benefit is structurally smaller in Rust than in Python: uvicorn's `--reload` re-imports
modules in well under a second, while the Rust loop is a full incremental rebuild and process
restart — the opus raw measured 9.28 s wall / 25.61 s user CPU for a *clean* debug build with
the web feature, a figure this run did not re-measure and carries as engine-reported.
**Ranked runner-up: `watchexec-cli` 2.7.2**, which sends `TERM` with a bounded stop timeout
out of the box (`--restart --stop-signal TERM --stop-timeout 20s`, openai's recipe) and so
needs no kill override; it becomes the recommendation the moment it declares a
`rust-version`, and that is a re-verify trigger below.

**Minimal realistic endpoint at the R01 boundary.** The handler names R01's types and nothing
of its own; the error envelope is R70's, the middleware ordering R75's, the trace and metrics
layers R78's and R79's, and none is preselected here.

**The error contract is R70's, and revision 6 hands it one open question rather than answering
it** (owner-reference *C4*, "One `AppError` enum (`thiserror`) implementing `IntoResponse` …
RFC 9457 Problem Details JSON (`type`/`title`/`status`/`detail`/`errors`)"; owner decision 11,
row 7). **This item decides nothing about it** — `WebError` above is a placeholder naming
R70's type, and owner decision 11 rules that rows belonging to other items are recorded as
hand-offs, not decided. What is recorded for **R70** (`http-problem-envelope`) is the one
tension a later reader would otherwise have to discover: the owner-supplied document proposes
RFC 9457 Problem Details for the HTTP body, while **R67 is published and owner-accepted
(2026-09-14) and its owned `error-taxonomy-exit-codes` fixes a different envelope shape** — a
single JSON object `{"error":{"code","message","hint"?}}` with `hint` omitted rather than
`null` when absent. The two are not in conflict as they stand, because **R67's envelope is the
CLI process's stderr contract, not an HTTP response body**, and R67 states that it "defines
exactly those three keys and defines no trace, cause-array or diagnostic field" while R7.8
permits documented additions owned by the item that needs them. **R70's question, stated so it
is not lost:** whether the HTTP surface mirrors R67's three keys, adopts RFC 9457's member
names, or carries both — and, if RFC 9457, how `code` survives, since a stable catalog token is
what R67's `RSLB` rows exist to provide. Nothing here constrains that answer; the owner
document is an input to it under owner decision 11, which places C4 in R70's overlap set.

```rust
#[derive(Clone)]
pub struct AppState {
    pub config:   Arc<WebConfig>,                 // the typed settings struct is R77's
    pub projects: Arc<ErasedProjectsService>,     // R01's erased service, unchanged
}
impl FromRef<AppState> for Arc<WebConfig>             { fn from_ref(s: &AppState) -> Self { s.config.clone() } }
impl FromRef<AppState> for Arc<ErasedProjectsService> { fn from_ref(s: &AppState) -> Self { s.projects.clone() } }

async fn list_projects(
    State(svc): State<Arc<ErasedProjectsService>>,
    Query(q):   Query<ProjectQuery>,              // the library's own serde type
) -> Result<Json<Vec<Project>>, WebError> { /* WebError's envelope is R70's */ }

pub fn build_router(state: AppState) -> Router {
    Router::new()
        .nest("/v1", projects::router())          // native composition, no registry
        .merge(ops::router())                     // /healthz now; /readyz is R80's
        .with_state(state)
}
```

**Coupling to R01 — the highest-consequence claim in this item, verified here.** The opus raw
asserts there is no conflict with R01 because the erased service satisfies axum's state bound
**without `ProjectsService` deriving a clone trait**. That is the exact failure mode that
would force a published, owner-accepted decision to be reopened, so it was re-verified rather
than accepted, in two independent halves (`## Empirical check`, check 1). **The claim holds.**
axum's state-carrying `impl<S> Router<S>` block is bounded `S: Clone + Send + Sync + 'static`
— read at the published artifact — and R01's `ProjectsService<Arc<dyn ProjectsPort>>`,
holding a port whose supertraits are `Send + Sync`, satisfies that bound once wrapped in an
`Arc`, because `Arc<T>` is unconditionally `Clone`. Two negative twins show what each half
does: storing the service **by value** fails with ``the trait `Clone` is not implemented for
`ProjectsService<Arc<(dyn ProjectsPort + 'static)>>` ``, and removing R01's `Send + Sync`
supertraits from the port fails with ``the trait `Sync` is not implemented for `(dyn
ProjectsPort + 'static)` ``. **No `CONFLICT:` line is raised and R01's published value is
unchanged.** If P03 prefers to store the service by value it must add `#[derive(Clone)]` to
`ProjectsService<P>`, which imposes a `P: Clone` bound that library consumers would inherit;
that is a P03 implementation choice, not a change to the parameter.

**Performance, and the limits on what can be said.** No comparative throughput figure is used
anywhere in this decision. The HIGH question asks for a comparison with representative JSON
handling, validation, trace instrumentation and metrics all enabled; no public benchmark
measures that, and the opus raw records that the TechEmpower results payload could not be
retrieved on 2026-09-12 (HTTP 404 at the path the site bundle references;
`tfb-status.techempower.com` timed out after 20 s). TechEmpower's Rust entries are in any case
hand-tuned implementations written for the benchmark rather than idiomatic instrumented
services, and every candidate here except `ntex`/`xitca-web` sits on the same `tokio` + `hyper`
I/O path, so a composite ranking would not discriminate between them on this template's
workload — where a single upstream call through R01's port dominates any framework overhead.
`actix-web` replaces `axum` only if a measured, instrumented workload shows a material p99,
CPU or RSS advantage; openai's raw specifies that benchmark in full and it is carried as an
unproven item below. The costs this template actually pays are dependency count, compile time
and binary size; the dependency-count figure is measured here, the compile-time and
binary-size figures are engine-reported and carried as unproven.

**Cross-repo adjudication** (changes to py and ts are a follow-on project; this supplies their
rationale). The principle "one core library, optionally exposed over HTTP by a thin adapter
that emits the library's own types" is a capability-level agreement. py realizes it with
FastAPI + uvicorn; rs realizes it with axum + tokio; ts realizes it **not at all** —
`TS_PORT_DECISIONS.md` records no web-service decision, and the pinned ts snapshot
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` contains no web or HTTP-server code, dependency or
test (`docs/port/areas/web-service.md`, row F303; taken from the repository's own analysis,
not re-derived — no claim here depends on ts source). Per the owner's 2026-09-04 clarification
Hono was chosen for TypeScript on ecosystem merits, which is a direction rather than an
implementation in that snapshot. **Adjudication: ts's missing web tier is an absent
capability, not a justified ecosystem difference** — nothing about TypeScript prevents a Hono
adapter over the existing `CliDeps`-injected core, and the owner has already named the
framework. Proposed follow-on, not this item's to execute: ts gains a Hono adapter exposing
the same core contract behind an optional entry point, preserving F018 at capability level.
The gemini raw additionally surveyed `rspc` as a Rust analogue of tRPC and rejected it because
its primary maintainer stepped back in late 2025 declaring the project largely unmaintained;
that conclusion is adopted — a REST surface with OpenAPI generation (R71's to select) keeps
the typed client contract without depending on an unmaintained RPC framework.

**Excluded by gate and by fit.** Fitness gates were answered per candidate before popularity
was weighed. **Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`, for every candidate in this item,
and no candidate is excluded on it.** Licences are still reported as facts because they are
part of each crate's published metadata. Gate 2 figures below are the newest non-yanked
version's declared `rust_version`, read from `https://crates.io/api/v1/crates/<name>/versions`
and asserted in `review/evidence/assert-figures.log`, section C; the floor is **1.96** (stable
1.98.x minus two minors).

| Candidate | Newest non-yanked | Licence (reported, not gated) | Gate 2: `rust-version` | Outcome |
|---|---|---|---|---|
| `axum` | 0.8.9 (2026-04-14) | MIT | 1.80 — pass | **Selected** |
| `tokio` | 1.53.1 (2026-07-20) | MIT | 1.71 — pass | **Selected** |
| `tower` | 0.5.3 (2026-01-12) | MIT | 1.64.0 — pass | **Selected** (dev-dependency) |
| `actix-web` | 4.15.0 (2026-08-21) | MIT OR Apache-2.0 | 1.88 — pass | Ranked runner-up; excluded on fit (its own runtime layer between the template and tokio; `Data<T>`'s runtime failure mode) |
| `poem` | 3.1.12 (2025-07-28) | MIT OR Apache-2.0 | 1.85 — pass | Excluded on **maintenance**: a 13-month release gap, and the opus raw found no maintainer response in any of its 10 most recently opened issues (window 2025-12-16 → 2026-09-09) — a concrete `at-risk` signal |
| `salvo` | 0.96.0 (2026-08-27) | Apache-2.0 | 1.94 — passes today | Excluded on **MSRV-policy fit**: two minors of headroom against the 1.96 floor; a project tracking the compiler that closely can push a patch release past the floor between the template's minor releases. Same reasoning R01 applied to `shaku`. |
| `rocket` | 0.5.1 (2024-05-23) | MIT OR Apache-2.0 | **1.64** — pass | Excluded on **maintenance**: last release 28 months ago, `pushed_at` 2025-12-28. (Settles a raw disagreement: gemini reported MSRV 1.89.0, opus 1.64; the registry says 1.64.) |
| `warp` | 0.4.3 (2026-05-04) | MIT | **none declared — FAIL** | **Excluded by gate 2** |
| `viz` | 0.11.0 (2025-11-17) | MIT | **none declared — FAIL** | **Excluded by gate 2** |
| `pavex` | 0.2.10 (2025-11-10) | Apache-2.0 | **none declared — FAIL** | **Excluded by gate 2** |
| `tide` | 0.17.0-beta.1 (2021-12-06) | MIT OR Apache-2.0 | **none declared — FAIL** | **Excluded by gate 2**, and dormant on its own (no release in 4+ years) |
| `xitca-web` | 0.8.3 (2026-08-29) | Apache-2.0 | **1.98 — FAIL**, equals current stable, above the 1.96 floor | **Excluded by gate 2** |
| `ntex` | 4.0.0-beta.10 (2026-09-12) | MIT OR Apache-2.0 | 1.95 — passes today | Excluded on **fit and maturity**: its own `ntex-rt` runtime abstraction is a second runtime story inside the `web` feature, beside the tokio one the web surface already needs — carrying the same two conditions as alternative E above, that the tokio world exists only when the feature is on and that whether the CLI and library join it is R05's open question — and the newest non-yanked release is a prerelease |
| `loco-rs` | 1.1.0 (2026-08-16) | Apache-2.0 | 1.94 | Not a competitor: it is built **on** axum, so selecting axum keeps it available to template users without importing its opinions |
| `dropshot` | 0.17.1 (2026-06-02) | Apache-2.0 | 1.85 | Well-engineered and single-org; its first-class OpenAPI generation is relevant to R71 but does not outweigh axum's adoption or the ecosystem R70–R80 will draw on |

Gates 3–6 for the two selected compiled members, answered from the published artifacts and
this run's executed checks:

- **Gate 3 (advisories and `unsafe` posture).** `https://rustsec.org/packages/axum.html`,
  `/tower.html`, `/bacon.html` and `/watchexec-cli.html` return HTTP 404, which RustSec serves
  for a crate with no advisory. `tokio` and `hyper` have pages listing **historic** advisories
  only (`RUSTSEC-2025-0023`, `-2023-0005`, `-2023-0001`, `-2021-0124`, `-2021-0072` for tokio;
  `RUSTSEC-2022-0022` and older for hyper), none of which applies to a recommended version.
  The decisive check is executed rather than read: `cargo audit` 0.22.1 against the probe's
  resolved `--features web` lockfile, over an advisory database **pinned** at
  `RustSec/advisory-db` commit `b50980aad8b8f14f77e25a97b32dd94bf008b0af`, loaded 1,243
  advisories, scanned 55 crate dependencies and exited 0 with no findings. The pin is what
  makes that figure reproducible; revision 2 reported the same number from an unpinned fetch
  and was rejected for it (see the revision note).
  `axum` declares `[lints.rust] unsafe_code = "forbid"` and its `src/` contains **zero**
  occurrences of `unsafe` (both asserted). `tokio` uses `unsafe` pervasively and by design —
  the opus raw counted 1,066 occurrences in the published 1.53.1 `src/`, a figure this run did
  not recount — which is inherent to a runtime and is why the template's own `unsafe` policy
  (R06) applies to template code, not to this dependency.
- **Gate 4 (ubuntu + macOS).** `tokio`'s CI at tag `tokio-1.53.1` covers `ubuntu-latest`,
  `macos-latest` and `windows-latest` — **pass**. `axum`'s CI at tag `axum-v0.8.9` runs on
  `ubuntu-24.04` **only, with no macOS runner** — a gap, closed **for this version and this
  host only** by this run resolving and building `axum` 0.8.9 with `tokio` 1.53.1 on
  macOS 26.4 aarch64 at rustc 1.98.0. The template's own CI on `ubuntu-latest, macos-latest`
  re-establishes it continuously. `bacon`'s CI is `ubuntu-latest` only and its v3.25.0 GitHub
  release carries **no binary assets**, so its macOS support was closed the same way: an
  executed `cargo install bacon --version 3.25.0 --locked` on this host, exit 0, with the
  installed binary reporting `bacon 3.25.0`.
- **Gate 5 (default features and async-runtime coupling).** `axum`'s defaults are
  `form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing`, and
  `axum::serve` exists only with the `tokio` feature plus `http1` or `http2` — both read from
  the published artifact. It couples to tokio and to nothing else. `tokio`'s `default = []`,
  so every feature is opted into explicitly.
- **Gate 6 (binary-size and compile-time cost).** Measured here as **dependency count**: with
  the base set to R01's published members (`serde` 1.0.229 + `serde_json` 1.0.151), the
  non-dev tree goes from **12 packages to 52** when `--features web` is on, and with the
  feature off no `axum`, `tokio`, `hyper` or `tower` appears in the tree and no serve binary is
  produced. Wall-clock build time and binary size are **not** measured here — measuring them
  honestly means building the recommendation — and the opus raw's figures (clean debug build
  5.69 s → 9.28 s wall, 7.12 s → 25.61 s user CPU; release serve binary 2,001,600 bytes,
  1,574,392 stripped) are carried as engine-reported and unproven.

**Compatibility — proof the members work together.** Three ways, two of them by direct
observation in this run. (1) **A shared adopter at the exact recommended versions:**
`rust-lang/crates.io` at commit `3df99c2` pins `axum = "=0.8.9"` and `tokio = "=1.53.1"` in one
workspace under `edition = "2024"` and `MIT OR Apache-2.0` — the same two fixed parameters this
template carries — composes routes natively, injects one `AppState` via `with_state`, and
serves with `axum::serve(..).with_graceful_shutdown(..)` over SIGINT and SIGTERM. Every member
of this stack except the dev-serve recipe is exercised together in that one production
service. (2) **An executed resolution probe:** a manifest declaring exactly the recommended
feature, dependencies and feature sets resolved under `edition = "2024"` and
`rust-version = "1.96"` with the MSRV-aware resolver (`Locking 54 packages to latest Rust 1.96
compatible versions`); the highest declared `rust-version` anywhere in the resolved non-dev
tree is `axum`'s own **1.80**, 16 minors inside the floor, and `cargo audit` cleared it.
(3) **A version matrix would be misleading here**: `axum` 0.8.9 pulls `tokio` through its own
`tokio` feature and depends on `hyper` and `hyper-util` directly, so the pairing is expressed
by the resolver rather than by independent choices. The one cross-member constraint worth
stating is the `axum::serve` cfg above. `bacon` sits outside that compiled graph entirely: it
is a process wrapper with no Rust ABI or dependency-resolution relationship to the service.

**The requirement operator, which the owner-supplied document raises and this item does not
adopt** (owner-reference *Recent-Bugs-vs-Plan Register*, "pin `axum = "=0.8.9"`,
`axum-extra = "=0.12.6"`"; owner decision 11, row 1). The `rust-lang/crates.io` pins quoted
above are an **application** convention — that repository ships a service with a committed
`Cargo.lock`, so an `=` requirement costs it nothing and documents an exactly reproduced build.
This template is the opposite case: it is a repository people copy, and a requirement it ships
travels into their manifests. Three facts decide it, the first read at a primary source and
asserted in `review/evidence/owner-reference-check-r6.log`, section B:

- **A bare requirement is already caret-bounded, so the document's stated reason is already
  satisfied.** The Cargo Book's *Version requirement syntax* gives `0.2.3 := >=0.2.3, <0.3.0`,
  states that "Caret requirements are the default version requirement strategy", and that
  "Leaving off the caret is a simplified equivalent syntax to using caret requirements". A
  manifest reading `axum = { version = "0.8.9", … }` therefore means `>=0.8.9, <0.9.0` and
  **cannot** resolve to 0.9 when 0.9 is published. The document's mitigation buys nothing
  against 0.9 that the default already gives.
- **What `=` would additionally cost is real.** It blocks 0.8.10 and every later 0.8 patch,
  including a security patch, until a template release moves the literal; and in a consumer's
  tree it conflicts with any other crate requiring a later 0.8.x — `axum-test` 21.1.0 already
  declares `^0.8.9`, and a future `^0.8.10` would be unsatisfiable beside `=0.8.9`.
- **Nothing in this decision's owned value or migration table states an operator**, so this is
  a ground recorded for P03 rather than a change: the owned parameter says "axum 0.8.9 declared
  non-optionally in crates/web/Cargo.toml and its default features on", the
  `crates/web/Cargo.toml` migration row says "non-optional `axum` 0.8.9 (defaults on)", and both
  render as Cargo's default caret requirement. **Revision 9 wrote those two quotations as "axum
  0.8.9 optional and its default features on" and "optional `axum` 0.8.9 (defaults on)", and
  closed with "The owned value is byte-identical to revisions 2 through 5."** That byte-identity
  held from revision 2 through revision 9; revision 10 moved the six clauses its note enumerates,
  and **neither wording states a version operator**, which is the whole of this bullet's point.
  Reproducibility comes from the committed
  `Cargo.lock` and `--locked` in CI, which is where this programme already puts it.

**Migration implications** (file-level; crate placement was R02's and **R02 has now decided it**,
so revision 10 writes this table against R02's owner-accepted four-package workspace — root
facade `rs-launch-blueprint`, `crates/core`, `crates/cli`, and `crates/web` as an optional
dependency of the facade — while `<app>` is still R49's `build-tool-output-shape`):

| File | Change |
|---|---|
| `Cargo.toml` (root package `rs-launch-blueprint`) | `[features] web = ["dep:rs-launch-blueprint-web"]`; `rs-launch-blueprint-web` declared `optional = true` on the `crates/web` path; `[[bin]] name = "<app>-serve", required-features = ["web"]`. Revision 9 wrote this row as `[features] web = ["dep:axum", "dep:tokio"]` with the two crates and the `tower` dev-dependency on this one manifest |
| `crates/web/Cargo.toml` (new member) | **non-optional** `axum` 0.8.9 (defaults on) and `tokio` 1.53.1 (`rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`); `tower` 0.5.3 under `[dev-dependencies]`, still not gated by the feature |
| `src/lib.rs` | one line re-exporting the optional member under the name the gated surface has always carried — **illustrated, not specified**, as `#[cfg(feature = "web")] pub use rs_launch_blueprint_web as web;`. Revision 9 wrote `#[cfg(feature = "web")] pub mod web;`, which cannot resolve once the tree moves to `crates/web/src/`. **The facade's re-export form is R02's and R04's to fix, not this item's, and R02 is silent on it**: R02 fixes only that the root package is "the published facade: `[lib] src/lib.rs`, `[[bin]] rslbp`, `[[bin]] rslbp-serve`, the composition root, the production adapter", and R04's root-barrel rule now applies to both packages that carry a public surface. What this item owns is that the gated surface is reachable under the name `web`, and that it is absent when the feature is off |
| `crates/web/src/lib.rs` (new) | `AppState` and its `FromRef` impls, `build_router(state) -> Router`, `shutdown_signal()`, `serve_until(..)` — revision 9 placed these at `src/web/mod.rs` |
| `crates/web/src/routes/projects.rs` (new) | `pub(crate) fn router() -> Router<AppState>` and the handlers, returning the library's own contract types |
| `crates/web/src/routes/ops.rs` (new) | `/healthz` now; `/readyz` and its payload are R80's |
| `src/bin/<app>-serve.rs` (new, in the root package) | `#[tokio::main] async fn main() -> ExitCode` — R4.1's required global core parsed with the parser crate R60 selects for the CLI binary (non-optional whichever crate that is, so the feature adds none), then settings, R01's composition root, bind, `serve_until`, and R67's exit integers (143 / 130 / 1 / 0) |
| `crates/web/tests/web_api.rs` (new) | the `oneshot` and real-listener tests, with **no** file-level `#![cfg(feature = "web")]` because the whole member is optional. Revision 9 placed this file at `tests/web_api.rs` and gated it file-level with `#![cfg(feature = "web")]` |
| `Justfile` | `serve` (bacon-driven, required) and `serve-once` (no watcher) |
| `bacon.toml` (new) | one override on the `run-long` job's `kill`, so a dev restart sends SIGTERM and the production drain path runs; without it bacon's default Unix interruption is SIGKILL |
| dev-tool list | `bacon` 3.25.0, acquired from crates.io, presence tested with `command -v bacon` per R42 |
| `.github/workflows/ci.yml` | a `--features web` axis and a `--no-default-features` build — shape owned by R11 |

Not created by this item: `problems.rs` (R70), `openapi.rs` (R71), `pagination.rs` (R72),
`idempotency.rs` (R73), `rate_limit.rs` (R74), `middleware.rs` (R75), `cors.rs` (R76),
`settings.rs` (R77), `telemetry.rs` (R78/R79), `Dockerfile` (R51).

**Layout: agreement with the owner-supplied document, and the item that actually owns it**
(owner-reference *C13*, "Start **single crate, feature-vertical modules** … promote to a
workspace only when compile times or team boundaries demand it"; owner decision 11, row 6).
**Agreed on the feature-vertical half; superseded on the single-crate half by owner ruling
W1-R02.** Revision 9 wrote: *"The file table is a single crate with feature-vertical modules —
`src/web/routes/projects.rs`, `src/web/routes/ops.rs`, and R70 through R80's later layers nested
inside the same gated `src/web/` tree, which the owned parameter's clause (4) fixes."* The
feature-vertical half stands; the single-crate half does not. The file table is now R02's
owner-accepted four-package workspace, with the same feature-vertical modules one level down —
`crates/web/src/routes/projects.rs`, `crates/web/src/routes/ops.rs`, and R70 through R80's later
layers nested inside the same gated `crates/web/src/` tree, which the owned parameter's clause
(4) still fixes. `AppState` holding shared members with `FromRef` substates is the
document's own `AppState` + `FromRef` prescription, chosen here on the compile-time ground
under alternative B. Dependency injection "via traits behind concrete types" is R01's published
`http-transport-injection-seam`, which this item consumes unchanged. The same shape is selected
independently by **R49** (`build-target-declaration`), whose unpublished decision revision 8
(`research/runs/R49/2026-09-05T155504Z-2107cffb3ecf/review/DECISION.md`) compares four
alternatives and selects **A1 — "single package, one binary, web behind a Cargo feature"**,
recording that the selection "is shape-neutral: if R02 chooses a workspace, every field above
moves to the member manifests unchanged" — which is exactly what R02 then chose, and exactly
what revision 10 does. **What revision 9 left to R02, and how R02 answered it:** revision 9 wrote
*"whether the template stays a single crate is **R02**'s (`crate-boundary-enforcement`, open),
exactly as the sentence above this table says; the owned value is phrased to survive either
answer"*, and *"no `CONFLICT:` line arises"*. Both are superseded. R02 was owner-accepted at
revision 1 on 2026-09-17; it chose a four-package workspace; it **did** raise a `CONFLICT:` line
against this item's owned value; and the owner resolved it as R02's option 1 — R69 is revised and
R02's topology stands. The document's own "promote to a workspace only when compile times or team
boundaries demand it" was a trigger for R02's question rather than an answer to it, and R02 has
now answered it. The
document's reference repositories for C13 are Variant-A and Variant-B application samples; this
item names `rust-lang/crates.io` as its reference implementation for the reasons under
*Authorities*, and neither set was re-read for this row.

**The release profile: a row this item does not own, whose owner is not yet fixed either**
(owner-reference *Reference `Cargo.toml`*, `[profile.release]` with `lto = "thin"` and
`codegen-units = 1`; owner decision 11, row 11). The `Cargo.toml` row in the table above
enumerates every manifest change this item asks for — on the root package the `[features]` entry,
the one optional member dependency and the `[[bin]]` target, and on `crates/web` the two
non-optional dependencies and the `tower` dev-dependency (revision 9 wrote this as "the
`[features]` entry, the two optional dependencies, the `tower` dev-dependency and the `[[bin]]`
target", against the single-crate table it then carried) — and **`[profile.*]` is not
among them, deliberately.** A release profile tunes how *every* target in the package is
compiled; it is neither gated by the `web` feature nor specific to the web surface, so
selecting one here would reach the CLI and library builds this item does not own.
**Which item does own it was verified rather than assumed**, because the answer turned out to be
"none yet". Asserted in `review/evidence/owner-reference-check-r9.log`, section C, over the
**complete** set of **85** binding prompts and the commonality ledger, with the denominator
printed and a control showing the same census reports a string the prompts do carry:
**no prompt and no ledger row names `[profile`, `lto`, `codegen-units` or `opt-level`.**
What the same section does establish, positively:
- **R68** (`release-binary-artifacts`) is the nearest consumer: its prompt scopes it to "which
  distribution channels/artifact *types* … get built and shipped", and the values a release
  profile governs — binary size and build time — are exactly what its MEDIUM and LOW questions
  weigh. But the same prompt places "the Cargo manifest's build-target declarations" outside
  its scope, in R49's.
- **R49** (`build-target-declaration`) owns the declaration surface — its owned
  `build-tool-output-shape` reads "no build backend or bundler crate; Cargo's own manifest is
  the entire declaration surface" and it names `target/release/rslbp` as the filename "R68's
  release matrix uploads" — yet it **sets no `[profile.*]` key at all**, which the same check
  asserts.

**So the disposition is a hand-off to R68 as the controller's reading, with the ownership itself
recorded as an open scoping question** rather than settled by this item. Nothing here
recommends, excludes or evaluates `lto = "thin"` or `codegen-units = 1`; whoever takes the row
inherits a live tradeoff this decision deliberately leaves untouched — both settings trade
build time for run-time performance and binary size, and this item's gate-6 answer already
records that the wall-clock and binary-size halves of that measurement are **unproven here**.

**Validation strategy.** *Verified in this run:* the six checks under `## Empirical check` —
the R01 state-bound coupling with two negative twins, the feature's gating shape and
dependency cost, the resolved-tree MSRV, advisories against the resolved lockfile, the
published-artifact facts about axum's state bound, its unbounded drain and tokio's feature
graph, the population figures with their endpoints, the issue-responsiveness figure codex
could not compute, and the dev tool's install and capabilities on macOS. *Proposed for the
template's CI (wiring is R11's, tiers are R32's):* `cargo test --features web` and
`cargo build --features web --bin <app>-serve` on `ubuntu-latest` and `macos-latest`; a
`cargo check` leg pinned to the declared `rust-version`; `cargo hack --each-feature check`,
or at minimum a `--no-default-features` and an `--all-features` job; `cargo audit` on the
template's lockfile; one `oneshot` test per route; a real-listener test decoding into the
library's own `Vec<Project>`; a `compile_fail` doctest for a handler asking for an
unregistered substate; a process-level test that sends SIGTERM during a slow request and
asserts both the response completing and the process exiting **143** inside the configured
window, its SIGINT twin asserting **130**, and its twin against a permanently blocked request
asserting the drain-deadline branch exits **1**; a conformance fixture over the serve binary's
R4.1 global core (`--help` and `-V` on stdout at exit 0, per R7.5 and R9.14);
`just serve` answering `GET /healthz` with console-formatted logs and restarting on a source
edit (blocked on R58); and the instrumented comparative benchmark specified in openai's raw
before any decision to prefer `actix-web`.

**Confidence.** **High** for the framework, runtime, state-injection, router-composition,
feature-shape and entrypoint members: each rests on a published artifact read at an exact
version, a maintained reference implementation at a recorded commit, and an executed check on
this machine. **Medium-high** for the dev-serve member: the tool's gates, install and
capabilities are verified, but the recipe's end-to-end behavior depends on R58's unpublished
logging contract and was not exercised. **Medium** for the exact field list of `AppState`,
which R77 (settings) and R58 (logging) will refine, and for the drain-deadline code shape,
which is reasoned and read but not executed. The serve binary's **exit integers** and its
**required global core** are a separate case from both: they are **High** as *rules*, because
each is quoted from a normative document this programme has already settled — R67's accepted
owned value and the standard's R4.1 under the owner's 2026-09-14 ruling — and **unproven** as
*behavior*, because no binary exists to run; three rows in the unproven table carry them.

**Sources.** Retrieved by this synthesis on **2026-09-13** and snapshotted under
`review/evidence/snapshots/` (reduced, committed) and `review/evidence/sources/`
(verbatim, not committed): `https://crates.io/api/v1/crates/<name>` and `/versions` for
`axum`, `tokio`, `tower`, `bacon`, `watchexec-cli`, `cargo-watch`, `actix-web`, `warp`,
`poem`, `salvo`, `rocket`, `ntex`, `xitca-web`, `pavex`, `viz`, `tide`, `loco-rs`,
`dropshot`, `hyper`, `tower-http`, `systemfd`, `listenfd`;
`/reverse_dependencies?per_page=1` for `axum` and `tokio`;
`https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for `tokio-rs/axum`,
`tokio-rs/tokio`, `tower-rs/tower`, `Canop/bacon`, `watchexec/watchexec`,
`watchexec/cargo-watch`, `actix/actix-web`, `seanmonstar/warp`, `poem-web/poem`,
`rwf2/Rocket`; the same search endpoint sorted by creation plus each issue's comments for the
responsiveness figure; `https://rustsec.org/packages/<name>.html` for `axum`, `tokio`,
`tower`, `bacon`, `watchexec-cli`, `hyper`; published `.crate` artifacts of `axum` 0.8.9,
`tokio` 1.53.1, `bacon` 3.25.0, `watchexec-cli` 2.7.2 and `tower` 0.5.3 from
`https://crates.io/api/v1/crates/<name>/<version>/download`;
`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/.github/workflows/CI.yml` and
`.../examples/graceful-shutdown/src/main.rs`;
`https://raw.githubusercontent.com/tokio-rs/tokio/tokio-1.53.1/.github/workflows/ci.yml`;
`https://raw.githubusercontent.com/Canop/bacon/v3.25.0/.github/workflows/tests.yml`;
`https://api.github.com/repos/Canop/bacon/releases/latest`;
`https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/{Cargo.toml,src/router.rs,src/bin/crates-io/server.rs}`;
`https://raw.githubusercontent.com/watchexec/cargo-watch/v8.5.3/README.md`. Carried over from
the raws with their own retrieval date of **2026-09-12**: the py source at programme pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` (`src/py_launch_blueprint/web/app.py`, `web/deps.py`,
`web/__main__.py`, `web/routers/__init__.py`, `pyproject.toml`, `Justfile`);
`https://docs.rs/axum/0.8.9/axum/` and its `State`, `FromRef` and `serve` pages;
`https://docs.rs/tokio/1.53.1/tokio/` and `tokio/signal`; `https://tokio.rs/tokio/topics/shutdown`;
`https://doc.rust-lang.org/cargo/reference/features.html` and `.../cargo-targets.html`;
`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`;
`apollographql/router` at `e7b2b32b5c7183475ea874b58b9f0b7d01dc32d8`;
`meilisearch/meilisearch` at `a955694df9f50771b3ceaf7896754cecfbaf165d`;
`https://github.com/qdrant/qdrant/blob/master/Cargo.lock`;
`https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`;
`https://github.com/specta-rs/rspc/discussions/351`. Read by **revision 2 on 2026-09-15** and by
no earlier revision: `research/topics/67-error-and-exit-code-contract/DECISION.md` (R67,
published and owner-accepted 2026-09-14, sha256
`16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`) — its owned
`error-taxonomy-exit-codes` value, its `## Decision` answer to the SIGTERM question, its
boundary-precedence rule and its `ctrlc` source read; the org CLI Design Standard at
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` **v1.4.14** (2026-06-28) — its header
scope line, its conformance clause, R4.1, R4.4, R4.6, R5.1, R5.2, R7.1, R7.5, R9.6, R9.14 and
Appendix A; and `docs/port/OWNER-REVIEW.md`, section *2026-09-14 — the CLI Design Standard
binds, and OV-01 is refused*. Repository context:
`research/topics/01-ports-and-adapters-seam/DECISION.md` (R01, accepted 2026-09-10);
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` rows F017, F303, F330, F331, F338, F339;
`docs/port/DIVERGENCE-ANALYSIS.md` line 217; `docs/port/BASELINE-REVIEW.md` (the F331
reclassification); `docs/port/OWNER-REVIEW.md` (the 2026-09-04 owner direction).
Retrieved by **revision 6 on 2026-09-16** and by no earlier revision, each reduced into
`review/evidence/snapshots/r6/` by `fetch-owner-reference-r6.sh` and asserted by
`owner-reference-check-r6.sh`: `https://crates.io/api/v1/crates/axum` and `/versions`;
`https://crates.io/api/v1/crates/axum-test` and
`/axum-test/{18.0.0,18.3.0,18.7.0,21.1.0,22.0.0-rc.1}/dependencies`;
`https://api.github.com/repos/tokio-rs/axum/issues/3809` and its `/comments`;
`https://api.github.com/repos/tokio-rs/axum/issues/3003`;
`https://api.github.com/repos/tokio-rs/axum/pulls/3745` and `/pulls/3819`;
`https://cloud.google.com/run/docs/container-contract`, served HTTP 200 from
`https://docs.cloud.google.com/run/docs/container-contract`; and
`https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html`. Read by revision 6
and by no earlier revision:
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` (the owner-supplied
input, in full) and `docs/planning/p02/owner-decisions.md` section 11;
`research/runs/R49/2026-09-05T155504Z-2107cffb3ecf/review/DECISION.md` (R49 revision 8,
**unpublished**, for its selected alternative A1) and R67's published `## Parameters` block for
the envelope shape named under *Minimal realistic endpoint*.

re-verify: when axum publishes 0.9, when R58 (logging-pipeline-contract) publishes, when R02 (crate-boundary-enforcement) publishes a decision that moves off the owner-accepted four-package workspace this revision is written against, when watchexec-cli declares a rust-version or the owner rules on whether the MSRV gate reaches non-linked developer tools, when R67 dispositions this item's request for a drain-deadline catalog row or revises the 130/143 reading of its boundary precedence, when R60's published decision moves off its owner-accepted clap 4.6.6 derive selection for the CLI binary the serve binary's global core is parsed with, when the CLI Design Standard revises R4.1's required global core past v1.4.14, at the next msrv-policy floor advance past 1.96, or by 2027-03-13, whichever comes first

## Parameters

- owns web-extra-surface = one additive, off-by-default Cargo feature named web, declared on the root package rs-launch-blueprint; web = ["dep:rs-launch-blueprint-web"], with axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module crates/web/src/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional, and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated crates/web/src/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on crates/web/**, the serve binary's source file and the web test files
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92

**No `CONFLICT:` line is raised by this decision, and none of the five raws raised one.** The
one coupling that could have produced one is R01's, and it was verified rather than assumed:
the web adapter holds R01's erased service in `AppState` as `Arc<ErasedProjectsService>` and
returns the library's own `serde`-derived contract types, with no mirror struct and no second
construction path, and this requires **no change to R01's types** — `Arc<T>` is
unconditionally `Clone`, which is all axum's `S: Clone + Send + Sync + 'static` state bound
needs, so `ProjectsService` does not have to derive `Clone`. The check, its two negative
twins and what they do not establish are under `## Empirical check`, check 1.
**Revision 10:** the `CONFLICT:` line that moved this item's owned value was raised by **R02**,
in R02's own `## Parameters` section, against this parameter; it is not raised here and none of
this item's five raws raised one, so the sentence above is unchanged and correct.

The five `- assumes` lines above are quoted byte-for-byte from `docs/port/PARAMETERS.md` and
are assumptions here, not findings; `review/empirical/parameters-check.sh` re-derives them
from the registry and diffs them against this file, and its output is
`review/evidence/parameters-check.log`. How they bear on the decision: `rust-edition` and
`msrv-policy` set the resolver configuration every probe in this run ran under
(`edition = "2024"`, `rust-version = "1.96"`, stable 1.98.x minus two minors), and gate 2's
exclusions of `warp`, `viz`, `pavex`, `tide` and `xitca-web` are read against that floor;
`target-os-matrix` is why gate 4's macOS leg mattered enough to close by executing installs
and builds on this host, and why Windows support is noted rather than required — only the
macOS leg was exercised here, the Linux leg belongs to the template's CI (R11);
`license` governs this repository's own declared expression and, under owner ruling Q7.B, is
**not** evaluated against any dependency or tool, which is what restored `bacon` to the
dev-reload recommendation.

`package-manager-invocation` (R42, published) is not listed above because the prompt's
`- consumes:` line names only R01, so it is not a consumed parameter of this item. It still
bears on the answer: its rule that a crates.io-installed tool is invoked as a bare executable
on PATH and presence-tested with `command -v <executable>` is exactly the form the `serve`
recipe and the dev-tool list above take.

Open items this answer depends on but does not decide, and how it behaves either way:
**R05 `sync-async-execution-model`** — if R01's port stays synchronous the handler wraps the
call in `tokio::task::spawn_blocking`; if R05 chooses an async port the handler awaits it
directly and R01's `async-trait` clause applies. Nothing in this stack changes either way and
`rt-multi-thread` is required in both cases. R05 registers no parameter, so this is a coupling,
not a conflict. **R02 `crate-boundary-enforcement`** — **no longer open.** Revision 9 wrote that
it *"decides which crate carries the feature and the `src/web/` module; the owned value above is
phrased to survive either a single-crate or a multi-crate layout"*. R02 was owner-accepted at
revision 1 on 2026-09-17 and decided a four-package workspace, so the owned value above now names
the root package `rs-launch-blueprint` and the `crates/web/src/` tree outright instead of
surviving either layout. **R58 `logging-pipeline-contract`** — owns the console/structured profile
split the dev recipe's environment variable selects, and the name of that variable.

## Empirical check

This section reports **verification only**. This is a research programme: the template does not
exist yet and P03 builds it, so nothing here builds, wires or runs the recommended web surface.
No handler, router, listener, service, seam or template scaffold was written. The two probe
packages that exist contain an empty `src/lib.rs`, a `fn main() {}`, and type declarations with
no methods; they are described with each check and retained under `review/empirical/`.

**Toolchain and OS.** macOS 26.4 (build 25E246), `aarch64-apple-darwin`.
`rustc -vV` → `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `host: aarch64-apple-darwin`,
LLVM 22.1.8. `cargo --version` → `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`.
`cargo audit --version` → `cargo-audit-audit 0.22.1`. `jq` 1.x at `/opt/homebrew/bin/jq`;
`gh` authenticated as `smorin`. Under `msrv-policy` the floor today is **1.96**.

**Working directory.** Five of the six scripts live in
`research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/empirical/`; the sixth, check 2's
`feature-shape-check-r4.sh`, lives in the sibling
`research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/evidence/` and reads the two probe
packages under `../empirical/`. All six resolve their own paths from `${BASH_SOURCE[0]}`, so
they rerun unchanged from any directory after this decision is committed. Every script sets
`set -o pipefail`. Every script asserts on **content**, and three of them carry a deliberate
control assertion that must fail, so that a check which cannot fail is visible as such —
check 2 now carries three, the MSRV-floor control, revision 3's advisory-count control, and
revision 4's control showing the warning-absence test reports a line that *is* present.

**Five further scripts, none of which is a seventh check.** Two are revision 9's and are
described first; two are revision 6's; the fifth is revision 5's.

Revision 9 adds `review/evidence/fetch-owner-reference-r9.sh` and
`review/evidence/owner-reference-check-r9.sh`, with the cited log
`review/evidence/owner-reference-check-r9.log`. They stand in the same relation to each other
as revision 6's pair, for the same reason: the fetcher goes to the network and writes reduced
snapshots under `review/evidence/snapshots/r9/`, **which are committed**, and the check asserts
against those committed snapshots so that it reruns offline and byte-identically after this
decision is committed. Only **published crate metadata** is snapshotted — versions, licences,
declared `rust-version`, `[features]` maps and dependency requirements from the crates.io API —
so no third-party source file is written into this repository. The check has one property
revision 6's does not: **its section C reads committed files of *this* repository** — the 85
binding prompts under `research/topics/` and `docs/port/COMMONALITY.md` — because the question
row 11 asks is *which P02 item owns release-profile settings*, and that is a fact about this
repository, not about an upstream project. A census over prompts is exactly the shape this
programme has been burned by before, so it is written to fail loudly rather than quietly:
**the denominator is asserted and printed** (`prompt files searched (the complete set): 85`,
and a separate assertion that the set is non-empty), and **the control runs the identical
`find`/`/usr/bin/grep -l` census over the identical file set for a string the prompts do
carry**, reporting 85 of 85. That guard is not decorative — while this check was being written,
a wrong path expression made the file set empty, and the run reported `0` prompts naming
`[profile` for the wrong reason; the denominator assertion and the control both failed and
caught it. The script was run **three times in a row** and runs 2 and 3 were **byte-identical**
to run 1, which is the cited log. Failure capability was demonstrated separately: a scratch
copy, produced with `cp` and `sed` inside a mirrored scratch tree, with the single assertion
`must "what \`full\` adds beyond them, count" "5"` rewritten to `"9"`, printed
`FAIL … expected=9 actual=5` and exited `1`. The scratch tree was deleted and the committed
script is unmodified; section C's census does not execute inside that scratch tree, because
`find` does not follow the symlinked `topics` directory there, which is why the empty-file-set
failure described above is what stands as that section's failure evidence. Both scripts set
`set -o pipefail`, resolve their paths from `${BASH_SOURCE[0]}`, invoke `/usr/bin/grep` by
absolute path with the binary named in the log, name the repository rather than any personal
address in the User-Agent, write nothing inside this run directory except into
`snapshots/r9/`, and carry the same file-level `# shellcheck disable=SC2015,SC2016,SC2329`
directive with the same per-code justification the earlier scripts carry. **Neither is a
check**: no claim in the recommendation rests on either, and their exit status decides nothing
about it. What they establish is the three owner-reference rows revision 9 adds.

Revision 6's pair follows, unchanged and not edited by revision 9.

Revision 6 adds `review/evidence/fetch-owner-reference-r6.sh` and
`review/evidence/owner-reference-check-r6.sh`, with the cited log
`review/evidence/owner-reference-check-r6.log`. They exist because owner decision 11 folds an
owner-supplied reference architecture into this item as an **input**, and that document's own
caveat says its patterns were "compiled in my head, not against the toolchain" — so the facts
revision 6 takes from it are asserted rather than narrated. **The division between them is the
point.** `fetch-owner-reference-r6.sh` is a **fetcher, not a check**, the sibling of
`fetch-figures.sh`: it performs the retrievals, records each one's HTTP status and effective
URL, and writes a **reduced** snapshot of each — only the fields this decision cites — under
`review/evidence/snapshots/r6/`, **which is committed**. Its User-Agent names the repository
(`https://github.com/smorinlabs/rs-launch-blueprint`) and no personal email address appears in
any request, per R42 revision 7's precedent. `owner-reference-check-r6.sh` then **asserts
against those committed snapshots and never touches the network**, which is what makes it
rerunnable offline and byte-identical after this decision is committed rather than only from
the author's checkout on the day the sources were live. It asserts on content in seven
sections — axum's published release list, Cargo's default version-requirement rule, the
axum-0.9 state in `tokio-rs/axum`, axum-test's versions and declared axum requirements, the
Cloud Run shutdown sentences for services and for jobs, axum issue #3003, and a control — and
**the control must report a present string**, so the emptiness assertion it mirrors is capable
of failing. It was run **three times in a row** and runs 2 and 3 were **byte-identical** to run
1, which is the cited log; separately, a scratch copy produced with `cp` and `sed`, with the
single assertion `must "axum newest non-yanked num" "0.8.9"` rewritten to `"9.9.9"`, printed
`FAIL … expected=9.9.9 actual=0.8.9` and exited `1`. The scratch copy was deleted; the
committed script is unmodified. Both scripts set `set -o pipefail`, resolve their paths from
`${BASH_SOURCE[0]}`, invoke `/usr/bin/grep` by absolute path with the binary named in the log,
never write inside this run directory except into `snapshots/r6/`, and pass the repository's
`shellcheck` pre-commit hook carrying the same file-level
`# shellcheck disable=SC2015,SC2016,SC2329` directive, with the same per-code justification,
that `feature-shape-check-r4.sh` and `yanked-control-r5.sh` carry. **Neither is a check**: no
claim in the recommendation rests on either, and their exit status decides nothing about it.
What they establish is which of the owner-supplied document's statements this decision may
repeat — which is why the reconciliation rows above cite this log and not the document.

**One further script, which is not a seventh check either.** Revision 5 adds
`review/evidence/yanked-control-r5.sh` and its log `yanked-control-r5.log`. It tests **no claim
this decision makes**: it exists only to make the error-line count reported in the revision-4
note — the figure the round-4 audit rejected — an **executed assertion** rather than a
recalled number, and it carries its own control showing that assertion rejects 55. It lives in
`review/evidence/`, resolves its paths from `${BASH_SOURCE[0]}`, sets `set -o pipefail`,
asserts on content, and reruns unchanged after this decision is committed, like the six checks;
it is listed separately from them because its exit status decides nothing about the
recommendation.

| # | Claim under test | Script | Exit | Log under `review/evidence/` |
|---|---|---|---|---|
| 1 | **the R01 coupling**: the erased service satisfies axum's state bound without `ProjectsService` deriving `Clone`, and the `Arc` and R01's `Send + Sync` supertraits are each load-bearing | `state-bound-check.sh` | 0 | `state-bound-check.log` |
| 2 | the `web` feature's gating shape, its dependency cost, the resolved-tree MSRV, and that no advisory in a **pinned** RustSec database applies to the resolved lockfile | `feature-shape-check-r4.sh` (in `review/evidence/`; revision 3's `feature-shape-check-r3.sh` and revision 1's `review/empirical/feature-shape-check.sh` are retained unchanged) | 0 | `feature-shape-check-r4.log` (revision 3's `feature-shape-check-r3.log` and revision 1's `feature-shape-check.log` are retained unchanged) |
| 3 | every population figure, gate answer and published-artifact fact this decision cites | `assert-figures.sh` | 0 | `assert-figures.log` |
| 4 | the issue-responsiveness figure the codex raw recorded as unverified | `issue-responsiveness.sh` | 0 | `issue-responsiveness.log` |
| 5 | the recommended dev tool's version pin installs on macOS and exposes the two capabilities F339's recipe needs | `bacon-install-check.sh` | 0 | `bacon-install-check.log` |
| 6 | the `## Parameters` block's five `- assumes` lines are byte-identical to the registry, the one `- owns` line carries no backtick/link/whitespace defect, and the H2 section list is exactly what the role contract fixes | `parameters-check.sh` | 0 | `parameters-check-r2.log` (revision 2's rerun; revision 1's `parameters-check.log` is retained unchanged) |

Two fetchers feed them and are not themselves checks: `fetch-figures.sh` queries every
endpoint the prompt's figure table names and writes a **reduced** snapshot — only the fields
that table names — under `review/evidence/snapshots/`, which **is committed**;
`fetch-sources.sh` downloads the upstream files read at an immutable version, tag or commit
into `review/evidence/sources/`, which is **not** committed, because it is third-party source
and one of it (`bacon` 3.25.0) is AGPL-3.0 — and the owner's 2026-09-12 ruling explicitly does
not touch the rule against committing third-party copyleft files **into** this repository.

**On reproducibility, stated precisely — and corrected.** Revision 2 said in this place that
"checks 1, 2, 5 and 6 run locally and reproduce byte-for-byte" and that all six had just been
re-run with `diff` reporting no differences. **For check 2 that was false**, and the round-2
empirical audit was right to reject it: the check's advisory scan consumed a mutable database,
so its advisory count moved from 1,243 to 1,246 between the recorded log and the auditor's
rerun. The sentence is withdrawn and replaced by the following, which says for each check
exactly what was established, by whom, and under which conditions.

- **Check 2** reads a **pinned** advisory database, runs `cargo audit` under an **isolated
  `CARGO_HOME`** that disables the yanked-crate lookup, normalises every absolute path it would
  print, and deletes one named class of environment-dependent line. Its log
  `feature-shape-check-r4.log` is what revision 4 established: the script was run **three times
  in a row** in this checkout and runs 2 and 3 were **byte-identical** to run 1, which is the
  cited log; the same script and its committed probe inputs were then extracted into a scratch
  directory as `git archive` produces them from the tree this revision commits and run there,
  and that run was **byte-identical to the cited log as well**; and a fifth run, made while a
  separate process held an exclusive `flock` on `~/.cargo/.package-cache` — the exact condition
  that made revision 3's log irreproducible — was **byte-identical to the cited log too**.
  **The reproduction conditions, stated exactly.** `rustc 1.98.0` and `cargo 1.98.0` on Darwin
  arm64 (macOS 26.4) as printed in the log's first two lines, with `cargo-audit` 0.22.1, `jq`
  and `git` on `PATH`; the environment variables `R69_ADVISORY_DB_URL`,
  `R69_ADVISORY_DB_MIRROR` and `R69_NO_LOCAL_MIRROR` unset, so their defaults apply, and
  `${TMPDIR:-/tmp}` writable; the files read are the two committed probe packages
  `review/empirical/feature-shape/` and `review/empirical/feature-shape-r01base/` with their
  committed `Cargo.toml` and `Cargo.lock`, read `--locked`, plus `RustSec/advisory-db` at
  commit `b50980aad8b8f14f77e25a97b32dd94bf008b0af` obtained from github.com or from a local
  `~/.cargo/advisory-db` mirror that already contains it; and **cargo-audit is executed under
  an isolated `CARGO_HOME`** — a `mktemp -d` directory under `${TMPDIR:-/tmp}` holding exactly
  `audit.toml` with `[yanked] enabled = false` and a `bin/cargo-audit` symlink — **so that
  neither a readable nor an unlocked cached crates.io index is required, because the branch
  that opens one is never entered**. Sections 1, 2, 5 and 7 do use the ambient `CARGO_HOME`,
  and its registry cache must already contain every crate in the two `Cargo.lock` files —
  otherwise `cargo tree --locked` prints `Updating crates.io index` and `Downloaded …` lines
  into those sections, which are **not** classified and would make the log differ. When that
  cache's `.package-cache` lock is contended cargo prints
  `Blocking waiting for file lock on package cache` (or `… on build directory`), and `norm`
  deletes exactly that line class with the anchored pattern
  `/^[[:space:]]*Blocking waiting for file lock on /d`. **That is the only classified line in
  this log**, it is named in the header line the log itself prints, and the lock-held rerun
  above is the evidence that classifying it is sufficient. The one remaining documented way the
  log can differ is the named SKIP: when the pinned commit is reachable from neither the network
  nor a local mirror, section 8 prints
  `SKIP: advisory-scan-skipped-pinned-db-unavailable` instead of the advisory lines and the rest
  of the log is unchanged; it cannot hide a feature-shape failure, which is asserted by a
  separate status variable.
- **Check 6** was re-run for revision 4 against this revised file, with `diff` reporting no
  differences against `review/evidence/parameters-check-r2.log`. It is the only one of the six
  that reads `review/DECISION.md`, and revision 4 moves nothing it measures — the one `- owns`
  line, the five `- assumes` lines and the H2 section list are byte-identical to revisions 2 and
  3 — so revision 2's log remains the cited one and **no new log is written**. Revision 1's
  `parameters-check.log` stays unedited as the record of revision 1. **Revision 5 re-ran it
  again**, against revision 5's text, and `diff` again reported no differences against
  `parameters-check-r2.log`: revision 5 edits prose and adds one control script, and moves
  neither a parameter line nor an H2 heading, so revision 2's log remains the cited one and no
  new log is written for it either. **Revision 6 re-ran it a third time**, against revision 6's
  text, and `diff` reported no differences against `parameters-check-r2.log` again. That result
  is this revision's own evidence for two of its claims: the one `- owns` line and the five
  `- assumes` lines are byte-identical to revisions 2 through 5 — so the owner-supplied
  document moved no owned value — and the H2 section list is still exactly the five headings
  the role contract fixes, which is the constraint revision 6 worked under in placing each
  reconciled row inside an existing section rather than adding a heading. Revision 2's log
  therefore remains the cited one and no new log is written for it.
- **Checks 1, 3, 4 and 5** were **not** re-run by revision 4, and that is not asserted here.
  None of them reads this file and none of their inputs changed. What stands for them is the
  round-3 empirical audit's own rerun, recorded in `review/audit-codex.md`: its finding 4
  reports that the five unchanged checks — state bound, figures, issue responsiveness, bacon
  install and parameters — reran with `exit code: 0` and **byte-identical logs**, check 2 being
  the sole exception and the subject of this repair. **Revision 5 re-ran none of checks 1 to 5
  either, and does not assert that it did.** It changes no script, no probe input and no log
  among them. What stands for them, and for check 2 in particular, is the **round-4** empirical
  audit's own rerun recorded in `review/audit-codex.md`: its findings 2 and 3 report that
  `feature-shape-check-r4.sh` reproduced `feature-shape-check-r4.log` byte-for-byte in all five
  modes tried and that the other five scripts and their cited logs were unchanged from `a735e88^`
  through `HEAD` and matched. Revision 5's own run is the separate control script named above.
  **Revision 6 re-ran none of checks 1 to 5 either, and does not assert that it did.** It
  changes no script, no probe input, no snapshot and no log among them; the two scripts and one
  snapshot directory it adds are new paths that no existing check reads. What stands for checks
  1 to 5 is the **round-5** empirical audit's own rerun, recorded in `review/audit-codex.md`
  (verdict `approve`, `unresolved-findings: none`): it reran all six decision checks and
  `yanked-control-r5.sh` — the latter three times in place and once from a clean
  `git archive HEAD` extraction — reporting exit `0` for each and every output byte-identical to
  its cited log, and it independently counted the 54 yanked errors with its own
  `/usr/bin/grep -cF`. Revision 6's own runs are check 6 above and the two new scripts.
- **Checks 3 and 4** read the committed reduced snapshots rather than live endpoints, because
  download counters, `pushed_at` and star counts move hourly and a live re-run could never be
  byte-identical; `fetch-figures.sh` refreshes them and records its retrieval timestamp in
  `snapshots/RETRIEVED-AT.txt` (`2026-09-13T07:57:55Z`). Check 3 additionally reads the
  uncommitted sources and invokes `fetch-sources.sh` itself when they are absent — which
  reproduces, because every one of those files is fetched at an immutable coordinate (a
  published `.crate` version, a git tag, a commit SHA). Re-running `fetch-figures.sh` will move
  the counters inside the snapshots and therefore the figures the logs print; the assertions —
  the version numbers, MSRVs, licences, `archived` flags and source facts — are the stable
  part, and are what the decision rests on.

An auditor therefore runs the six scripts, five from `review/empirical/` and check 2 from
`review/evidence/`, plus — since revision 5 — the one control script named above,
`review/evidence/yanked-control-r5.sh`, which decides nothing about the recommendation and is
run only to reproduce the count in the revision-4 note, plus — since revision 6 —
`review/evidence/owner-reference-check-r6.sh`, which reads only the committed snapshots under
`review/evidence/snapshots/r6/` and likewise decides nothing about the recommendation, and
plus — since revision 9 — `review/evidence/owner-reference-check-r9.sh`, which reads the
committed snapshots under `review/evidence/snapshots/r9/` together with this repository's own
committed prompts and ledger, and likewise decides nothing about the recommendation.
**Neither fetcher is rerun as part of an audit** — not
`review/evidence/fetch-owner-reference-r6.sh` and not
`review/evidence/fetch-owner-reference-r9.sh`: each goes to the network, and rerunning it would
move the snapshot contents under the check that reads them — the same reason `fetch-figures.sh`
is not rerun for checks 3 and 4. Nothing else. **The five locations
revision 3 edited in this section and
above it, enumerated rather than left to a reader's diff:** (1) acceptance criterion 1's
citation, now `feature-shape-check-r3.log`; (2) the gate-3 paragraph, which now names the
pinned advisory-db commit and, in the same sentence, corrects "resolved 52-package lockfile"
to the 55 crate dependencies the scan actually reported — 52 is the *other* probe's non-dev
package count and did not belong there; (3) the working-directory sentence, since the six
scripts no longer share one directory; (4) the check-2 row of the table above; (5) the check-2
narrative below, which now names the pin. Nothing else in this section or in any other section
changed.

**The locations revision 4 edited, enumerated from a mechanical search rather than from a
re-reading.** The search was `/usr/bin/grep -n -i 'yank|crates\.io index|cached|no-fetch|
auditor\.rs|CachedIndex|package-cache|CARGO_HOME|Blocking'` over this file, plus
`feature-shape-check-r3` and `revision 3`, and every hit was classified before any edit was
made: (1) the title; (2) the new revision-4 note, which quotes the round-3 finding verbatim;
(3) the revision-3 note's heading, which now says the note is retained as that revision's
record and that its "second and last documented way this log can vary" claim is the one the
round-3 audit refuted — the note's body is left **verbatim**, because it is the record of what
revision 3 said; (4) the synthesizer line, which adds revision 4's context; (5) acceptance
criterion 1's citation, now `feature-shape-check-r4.log`; (6) the working-directory sentence,
which now names `feature-shape-check-r4.sh`; (7) the control-assertion sentence, since check 2
now carries three controls rather than two; (8) the check-2 row of the table above; (9) the
check-2 reproducibility bullet, which carries the exact reproduction conditions; (10) the
check-6 and checks-1/3/4/5 bullets, which now name revision 4 and the round-3 audit's rerun;
(11) the check-2 narrative below, whose command form now shows the isolated `CARGO_HOME` and
whose sentence about the yanked-crate lookup is corrected, because under revision 4 that lookup
does **not** run. **Deliberately left byte-identical, and why:** the gate-3 paragraph under
`### Principles and implementation` (it records the advisory answer — the pinned commit, 1,243
advisories, 55 crate dependencies, exit 0 — none of which revision 4 moves); every gate-2
"newest non-yanked version" figure in the candidate tables (those come from the committed
crates.io snapshots read by check 3, never from this scan); the `## Parameters` block in full;
and the retained revision-2 and revision-3 note bodies.

**The locations revision 5 edited, enumerated from a mechanical search rather than from a
re-reading.** The search was three passes of `/usr/bin/grep -n -E` over this file before any
edit was made: `'55 lines|grew 55|prints 55'`, `'unpopulated|yanked\.enabled|default .true'`,
and `'six scripts|six checks|synthesizer|revision 4'`; every hit was classified first, and the
same searches were re-run against the edited file. The complete edit list: (1) the title, now
revision 5; (2) the new revision-5 note, which quotes the round-4 finding verbatim, explains
that 55 was the dependency count, and names the new script and log; (3) the revision-4 note's
heading, which now says the note is retained as that revision's record and that its two
error-count sentences are corrected in place; (4) **the count itself, at the two sentences the
finding cites** — `prints 55 lines of` → `prints 54 lines of`, with the 55-versus-54 arithmetic
and the citation to `yanked-control-r5.sh` added, and `the log grew 55 lines` → `the log grew 54
lines`; (5) the preamble's synthesizer line, which adds revision 5's context; (6) a new
paragraph after the control-assertion sentence above, introducing `yanked-control-r5.sh` as a
control and **not** as a seventh check; (7) the auditor sentence, which now names that script
alongside the six checks; (8) this enumeration. **Deliberately left byte-identical, and why:**
`review/evidence/feature-shape-check-r4.sh` and `feature-shape-check-r4.log` (the r4 script's
header comment at lines 72-80 therefore still carries the superseded 55, which the revision-5
note states explicitly; editing a comment would invalidate a log the round-4 audit reproduced
five ways, and no assertion, exit status or output line of that script depends on the figure);
the check-2 row of the table above, its reproducibility bullet and its narrative below, all of
which describe the isolated-`CARGO_HOME` scan that revision 5 does not touch; the six checks
and their five other scripts and logs; the gate-3 paragraph and every `55 crate dependencies`
figure, which is the *correct* use of that number; the `## Parameters` block in full; the
recommendation, the R67 exit contract and request, the R4.1 global core, gate 1's
`inapplicable` row; and the retained revision-2 and revision-3 note bodies.

**The locations revision 6 edited, enumerated from a mechanical search rather than from a
re-reading.** Revision 6 differs from revisions 2 through 5 in that it repairs no audit
finding: it folds in an owner-supplied input, so the search had to find every place each
reconciled row's **topic** already lives rather than every occurrence of a rejected figure. The
search was one pass of `/usr/bin/grep -n -E` over this file, run **before any edit was made**,
with the alternation
`'axum-test|oneshot|0\.9|=0\.8\.9|SIGKILL|bacon\.toml|Cloud Run|WebSocket|Websocket|http2|macros|R70|R32|R02|R49|workspace|single crate|cargo-chef|mold|synthesizer|revision 5|six checks|control script|re-verify'`;
every hit was classified against the eight rows before any text was written, and the same
search was re-run against the edited file. The complete edit list, in file order: (1) the
title, now revision 6; (2) the new revision-6 note, whose first paragraph states that no owned
value moves and why, and whose table gives all eight rows' dispositions; (3) the revision-5
note's heading, which now records that the note is retained as that revision's record and was
approved — its body is left **verbatim**; (4) the preamble's synthesizer line, which adds
revision 6's context; (5) under F338, a new paragraph on the unreleased 0.9 line (row 1's
second half); (6) under F338, two new paragraphs — the Cloud Run ten-second datum handed to R77
and the axum #3003 WebSocket hazard (row 4); (7) under F339, a new paragraph recording
agreement on `bacon`, this item's stronger SIGKILL finding, and the `cargo-chef`/`mold`
hand-offs (row 3); (8) after *Minimal realistic endpoint*, a new paragraph handing the RFC 9457
question to R70 with R67's differing envelope named (row 7); (9) under *Compatibility*, a new
block on the requirement operator (row 1's first half); (10) after *Migration implications*, a
new paragraph on layout, R49's A1 and R02's open boundary (row 6); (11) inside Disagreement 3,
a new block grounding the `oneshot` idiom and recording `axum-test` as the alternative with its
winning condition and corrected figures (row 5); (12) inside Disagreement 4, a new block
recording `ws`/`http2`/`macros` as additive later-layer territory (row 2); (13) under
`## Engines`, the owner-supplied input's provenance, its standing, and the overlap-map table
carrying every remaining row as a hand-off (row 8); (14) in `## Empirical check`, the
further-scripts paragraph, which now introduces revision 6's two scripts before revision 5's;
(15) the auditor sentence, which now names `owner-reference-check-r6.sh` and says why the
fetcher is not rerun; (16) the check-6 bullet and (17) the checks-1-to-5 bullet, which record
revision 6's parameters rerun and that it reran no other check; (18) this enumeration.
**Deliberately left byte-identical, and why:** the `## Parameters` block in full — the one
`- owns` line and the five `- assumes` lines — because the one question that could have moved
it, the document's `=0.8.9` advice, is answered by the fact that neither the value nor the
migration table states an operator at all (revision-6 note, first paragraph; *Compatibility*);
the recommendation, every version pin, every exclusion, the gate answers including gate 1's
`inapplicable` row, the R67 exit contract and the request to R67, and the R4.1 required global
core, none of which the document reaches; the `re-verify:` line, because the 0.9 finding
**confirms** its existing "when axum publishes 0.9" trigger rather than adding one; the six
checks and all seven of their scripts and logs, `yanked-control-r5.sh` and its log, and every
committed snapshot outside the new `snapshots/r6/` directory; and the retained revision-2,
revision-3, revision-4 and revision-5 note bodies.

**The locations revision 9 edited, enumerated from a mechanical search rather than from a
re-reading.** Revision 9, like revision 6 and unlike revisions 7 and 8, repairs no audit
finding: it closes a **gap in coverage**, so the search had to find where each of the three
undisposed rows' subjects already appears, and confirm that where a subject appears nowhere —
as `[profile.release]` does — that absence is itself the finding. The search was one pass of
`/usr/bin/grep -n -E` over revision 8, run **before any edit was made**, with the alternation
`'axum-extra|profile|"full"|\[features\]|tokio feature set|member is a decidable|Migration implications|further scripts|An auditor therefore|Document row \| Subject|synthesizer|revision 8'`;
every hit was classified against the three rows before any text was written, and the same
search was re-run against the edited file. Two classifications from that pass are worth
recording because they are near misses rather than hits: the two existing `axum-extra` mentions
(inside the 0.9 discussion under F338) are about **where axum's 0.9 breaking changes land**,
not about adopting the crate, and are left byte-identical; and every existing occurrence of the
word "profile" is either the CLI standard's *Small-CLI profile*, R58's *console/structured
profile* or `target/release` as a directory — **none is `[profile.*]` in the manifest sense**,
which is what made row 11's absence real rather than an artefact of the search. The complete
edit list, in file order: (1) the title, now revision 9; (2) the new revision-9 note, carrying
the three rows in the revision-6 table's form and continuing its numbering at 9, 10 and 11;
(3) the revision-8 note's heading, which now records that the note is retained as that
revision's record and was approved by both round-8 audits — its body is left **verbatim**, with
its original heading sentence quoted inside the new one so nothing it said is lost; (4) the
history line, which adds revision 9's context; (5) after *Migration implications*, a new
paragraph on the release profile and the ownership gap (row 11); (6) inside Disagreement 3, a
new block on `axum-extra` (row 10); (7) inside Disagreement 5, a new block on `full` against
the six (row 9); (8) two new rows in the overlap-map table under `## Engines`, for rows 10 and
11; (9) in `## Empirical check`, the further-scripts paragraph, which now introduces revision
9's two scripts before revision 6's and states the census guard and the failure evidence;
(10) the auditor sentence, which now names `owner-reference-check-r9.sh` and scopes the
not-rerun rule to both fetchers; (11) this enumeration. **Deliberately left byte-identical, and
why:** the `## Parameters` block in full, because all three rows resolve to a *differs* whose
ground is a rule the decision already states and two *hand-offs* to other items, none of which
touches what the `web` feature gates; the recommendation, every version pin, the tokio feature
list itself, every exclusion, the gate answers, the R67 exit contract and request, and the R4.1
global core; the `re-verify:` line, which none of the three rows gives a new trigger; the six
checks and every one of their scripts and logs; `yanked-control-r5.sh` and its log;
`fetch-owner-reference-r6.sh`, `owner-reference-check-r6.sh`, its log and every file under
`snapshots/r6/`; and the retained revision-2 through revision-8 note bodies.

**Check 1 — the R01 coupling.** Three dependency-free packages under
`review/empirical/state-bound/`. Each declares R01's published seam shape transcribed from
`research/topics/01-ports-and-adapters-seam/DECISION.md` — `pub trait ProjectsPort: Send +
Sync`, the blanket `impl` for `Arc<T>`, `ProjectsService<P: ProjectsPort>` **deliberately not
deriving `Clone`**, and `ErasedProjectsService` — **with no methods, no bodies and no
behavior**, plus axum's state bound transcribed verbatim from the published artifact
(`axum-0.8.9/src/routing/mod.rs:138-141`) as
`pub fn assert_axum_state_bound<S: Clone + Send + Sync + 'static>() {}`. They import nothing:
no `axum`, no `tokio`, no handler, no router, no listener. Each builds with `--offline`, which
is itself an assertion that nothing crept into the manifests. Observed:

```text
case: positive             expect: expect-pass     exit=0     (no diagnostics)
    assert_axum_state_bound::<Arc<ErasedProjectsService>>();
    assert_axum_state_bound::<AppState>();            // #[derive(Clone)] over two Arc fields

case: neg-by-value         expect: expect-fail     exit=101
error[E0277]: the trait bound `ProjectsService<Arc<(dyn ProjectsPort + 'static)>>: Clone` is not satisfied
   |     assert_axum_state_bound::<ErasedProjectsService>();
   |  the trait `Clone` is not implemented for `ProjectsService<Arc<(dyn ProjectsPort + 'static)>>`
   |  note: required by a bound in `assert_axum_state_bound`

case: neg-no-supertraits   expect: expect-fail     exit=101
error[E0277]: `(dyn ProjectsPort + 'static)` cannot be shared between threads safely
   |  = help: the trait `Sync` is not implemented for `(dyn ProjectsPort + 'static)`
   |  note: required because it appears within `ProjectsService<Arc<(dyn ProjectsPort + 'static)>>`
state-bound-check rc=0
```

**What this establishes.** R01's erased service, `Arc`-held, satisfies axum 0.8.9's declared
application-state bound with `ProjectsService` deriving no clone trait; the positive case also
covers the recommended `AppState` whose own `Clone` derive sits over two `Arc` fields neither
of whose inner types is `Clone`. The first negative twin shows the outer `Arc` is what does the
work — storing the service by value fails, which is why P03 would have to add `#[derive(Clone)]`
and a `P: Clone` bound to take that route. The second shows R01's `Send + Sync` supertraits are
what make the erased service shareable at all. **What it does not establish:** anything about
handlers, dispatch, request behavior, or the real axum crate's behavior at runtime. It is a
type-level fact about a declared bound, paired with that bound read at the published artifact.

**Check 2 — the feature's shape and cost.** Two manifest probes under
`review/empirical/feature-shape/` and `feature-shape-r01base/`. Both contain an empty
`src/lib.rs` and a `fn main() {}` binary; their only purpose is to make the manifests resolvable
so the feature's gating, cost and resolved MSRV are observable. Observed, with the feature off:
`cargo tree -e normal` contains no `axum`, no `tokio`, no `hyper` and no `tower`, and after
`cargo clean && cargo build --no-default-features --bins` the serve binary is absent. With it
on, all four appear, at `axum v0.8.9` and `tokio v1.53.1`. `cargo metadata` reports
`"required-features":["web"]` on the binary target and `null` on the library target.
`cargo tree --invert tower` shows `tower v0.5.3 └── axum v0.8.9`, which settles the dev-dependency
question: `tower` is already in the non-dev tree through `axum`, so a direct entry is needed only
to bring `ServiceExt` into scope in tests. The resolved non-dev tree's highest declared
`rust-version` is **`axum` 0.8.9's 1.80** (the probe's own 1.96 is the floor itself and is
excluded); the same test applied against a 1.70 floor reports a failure, so it can fail. Nine
transitive dependencies declare no `rust-version` at all — the strict gate-2 reading is applied
to *candidates*, not to every transitive crate, and this figure records that limit. `cargo audit`
0.22.1, run as `CARGO_HOME=<isolated> cargo audit --db <clone> --no-fetch --stale` against a
scratch clone of `RustSec/advisory-db` **pinned** at commit
`b50980aad8b8f14f77e25a97b32dd94bf008b0af` and asserted to be at that commit, loaded 1,243
advisories, scanned 55 crate dependencies and exited 0 with no findings. The count and the
crate total are asserted as constants; a control assertion demanding a count the database
cannot have shows the test can fail; and the normalised output is asserted to be exactly two
lines containing neither `couldn't open crates.io index` nor
`couldn't check if the package is yanked`. This scan does not refresh the crates.io index and
prints no `Updating crates.io index` line. It also does **not** read a cached index at all: the
isolated `CARGO_HOME` supplies an `audit.toml` setting `[yanked] enabled = false`, so per
`cargo-audit` 0.22.1's source (`src/auditor.rs:115-167`) the yanked-crate lookup is skipped
entirely and neither `CachedIndex::fetch` nor `CachedIndex::open` is called. No advisory result
depends on that lookup, and no claim in this decision rests on a yanked result. Revision 1 ran
this scan against the live, self-updating `~/.cargo/advisory-db`, which is why its count was
not reproducible and why revision 2 was rejected; revision 3 pinned the corpus but still read
the ambient cached index, whose `.package-cache` lock inserted a warning line into every rerun,
which is why revision 3 was rejected.
With the base set to R01's published members, the non-dev tree is **12 packages with the feature
off and 52 with it on**; the 52 matches the opus raw exactly, and the base differs by one package
because that probe carried one further base dependency, so the delta reads 40 here and 39 there.
This confirms the **shape** of the opus measurement; the wall-clock and binary-size halves of
that measurement are not reproduced here and are carried as unproven.

**Check 3 — figures, gates and artifact facts.** 75 assertions, all passing, plus one
deliberate control that must and does report `FAIL`. **Gate 1 is asserted nowhere in this
script**, and the script says so in its own header: under owner ruling Q7.B it is inapplicable
to every dependency and tool, so licences are printed as published metadata and never
compared. What is asserted: the version, MSRV, licence and `archived` state of every
candidate; the RustSec HTTP status and listed advisory ids per crate; the upstream CI runner
lists at each pinned tag; the reference implementation's pins, its edition, its registry-free
router and its unwrapped drain call site; axum's state bound, its `with_state` signature, its
`FromRef` substate documentation, its `close_tx.closed().await`, its **zero** occurrences of
`timeout` or `deadline` in `src/serve/mod.rs`, its `unsafe_code = "forbid"` lint, its **zero**
occurrences of `unsafe` in `src/`, its default feature list and the `axum::serve` cfg; tokio's
`default = []` and that none of `signal`, `net`, `rt-multi-thread`, `time` or `macros` enables
`sync`; and bacon's declared MSRV, its SIGKILL default, its `run-long` job's
`kill_then_restart` strategy and `need_stdout`, its headless stdout/stderr passthrough, and
its `--features` and post-`--` argument plumbing, and that `-j` selects the initial job while
`--headless` guards only the screen setup. Figures as snapshotted at
`2026-09-13T07:57:55Z`:

| Crate | 90-day dl | All-time dl | Newest non-yanked | Stars / pushed / archived | Open issues | Licence | `rust-version` | Rev-deps |
|---|---:|---:|---|---|---:|---|---|---:|
| `axum` | 114,795,000 | 466,425,972 | 0.8.9 (2026-04-14) | 27,100 / 2026-09-11 / false | 34 | MIT | 1.80 | 8,598 |
| `tokio` | 222,551,461 | 961,082,746 | 1.53.1 (2026-07-20) | 33,136 / 2026-09-13 / false | 316 | MIT | 1.71 | 72,187 |
| `tower` | 169,723,285 | 656,241,115 | 0.5.3 (2026-01-12) | 4,293 / 2026-06-22 / false | 69 | MIT | 1.64.0 | — |
| `bacon` | 21,763 | 328,857 | 3.25.0 (2026-08-23) | 3,410 / 2026-09-12 / false | 47 | AGPL-3.0 | 1.85 | — |
| `watchexec-cli` | 8,702 | 659,914 | 2.7.2 (2026-09-06) | 7,180 / 2026-09-07 / false | 31 | Apache-2.0 | **none** | — |
| `cargo-watch` | 174,663 | 1,970,345 | 8.5.3 (2024-10-02) | 2,861 / 2025-01-14 / **true** | — | CC0-1.0 | 1.75.0 | — |

**Check 4 — issue responsiveness.** The codex raw declined to compute this figure, noting that
the ten-newest listing mixes issues and pull requests and that a maintainer-attribution
calculation needs comment sampling. The rule applied here is the prompt's: over the 10 most
recently **opened issues**, the first comment whose `author_association` is `OWNER`, `MEMBER`
or `COLLABORATOR`, excluding bots and the issue author. Observed — `tokio-rs/axum`: median
**0.41 days**, **5 of 10 unanswered**, window 2026-06-16 → 2026-09-07; `Canop/bacon`: median
**0.02 days**, **3 of 10 unanswered**, window 2026-02-17 → 2026-08-24; `tokio-rs/tokio`:
median **0.33 days**, **3 of 10 unanswered**, window 2026-08-27 → 2026-09-09. The axum and
bacon figures reproduce the opus raw's independently, including the identical axum window; the
tokio median differs from opus's 0.03 days, a method difference this synthesis did not
reconcile, and the figure reported here is this run's. A control asserts the parser reports no
response for an empty comment list, so it cannot invent one. `axum`'s 5-of-10 unanswered is the
one population figure that argues against it; set against a `pushed_at` of the previous day, 34
open issues in total, and a normal patch cadence on the 0.8 line, the maintenance verdict is
**active**.

**Check 5 — the dev tool.** `cargo install bacon --version 3.25.0 --locked` exited 0 on this
host and the installed binary reports `bacon 3.25.0`; `bacon --list-jobs` run in a directory
with **no `bacon.toml`** lists `run-long` among the default jobs; `--headless` and `--features`
are both present in `--help`; and a control confirms the flag assertion reports an absent flag
as absent. This closes gate 4's macOS leg for this pin, which neither bacon's CI
(`ubuntu-latest` only) nor its v3.25.0 GitHub release (zero binary assets) demonstrates. It
builds a development **tool**, not the recommendation.

**A boundary judgement recorded for the auditors.** The opus raw reports executing a probe that
built a feature-off binary, served a handler over a real bound TCP listener with a real HTTP
client, and measured a drain with an in-flight request. The research-worker contract says not
to scaffold a crate or write a server; the worker states it wrote only its own report file, so
the probe lived outside the run directory. In this synthesizer's judgement that exceeds the
contract as the role now reads it, and it is recorded here rather than repeated. **Nothing in
this decision rests on those executions except where independently re-verified above:** the
state bound (check 1, type-level only), the 52-package feature-on tree (check 2), and axum's
unbounded drain (check 3, read at source rather than timed). The three passing tests the opus
raw reports, and its build-time and binary-size figures, are carried as engine-reported and
unproven.

## Engines

- codex `raw/codex.md` — gpt-5.6-terra (sha256 `6f1d03df7be0ab3afc4c1fc2bed545d0ad0ab55f30b138c10750346e7f9e21fd`), bundle shape OK. Recommends `axum` 0.8.9 on `tokio` 1.53.1 behind a `web` feature with explicit `WebState` injection, `axum::serve` plus tokio signals, and externally installed `watchexec-cli` 2.7.2 for the dev recipe. Members: `axum`, `tokio`, `watchexec-cli`. Executed nothing. Raised `BASELINE-REVIEW: F331`. Flagged six figures it could not verify (resolved-tree MSRV, RustSec advisory counts, platform CI, issue-response medians, watchexec-cli's declared MSRV, and all proposed integration and benchmark measurements) — of these, this synthesis verified the resolved-tree MSRV (1.80, check 2), the advisory answer (`cargo audit` exit 0 over 55 crates, check 2), platform CI for `axum`, `tokio` and `bacon` (check 3), the issue-response medians for `axum`, `tokio` and `bacon` (check 4), and watchexec-cli's absent `rust_version` (check 3). The proposed integration and benchmark measurements remain unproven and are in the table below.
- opus `raw/opus.md` — claude-opus-5 (sha256 `161fcbb42aadb8752c59d36a7ba337e1b69e717429110ad94c548ce649e0f91d`), bundle shape OK. Recommends the same `axum`/`tokio` stack with `State` + `FromRef` over one `AppState`, native router composition, a feature-gated serve binary, and a settings-driven drain deadline. Seven members (two crates, five patterns). By far the most evidence-dense raw: read published `.crate` artifacts at exact versions, the reference implementation at a recorded commit, and executed a build-and-serve probe. Raised `BASELINE-REVIEW: F330` (adopted) and `BASELINE-REVIEW: F339` (**withdrawn** — see Disagreement 1). Three corrections to it are recorded below.
- doxa (one engine, three provider bodies from operation `research-20260912-134041-a1150ec8a7594fa0`). The merged digest `raw/doxa.normalized.md` **fails** bundle shape validation — `doxa/normalization.json` records `answer: bundle H5 member field is outside a named member in '### Members'` — because gemini's member fields are emitted under a different H2 in the regrouped file. That is a layout defect in the digest only; all three per-provider normalized files pass validation and are what this synthesis used.
  - `raw/doxa-openai.normalized.md` — OpenAI gpt-5.6-sol (sha256 `efa7c6dc8385077a86280841d101713fd6426f7e5802c613bdcc8024ae3d0106`), shape OK. Members: `axum` 0.8.9, `tokio` 1.53.1, `tower` 0.5.2, `watchexec-cli` 2.5.1. **The only raw that gets the drain deadline right** (Disagreement 2). Raised `BASELINE-REVIEW: F330` and `F331`. Its own ledger records every crates.io and GitHub figure as "pending exact endpoint collection; not inferred from scraped substitutes" — an honest gap, and its `watchexec-cli` 2.5.1 / Rust 1.93 figures are stale against the registry's 2.7.2 (2026-09-06) with no declared `rust_version`. Its `tower` 0.5.2 pin is likewise superseded by 0.5.3.
  - `raw/doxa-gemini.normalized.md` — Gemini deep-research-preview-04-2026 (sha256 `6b0772ed4e79cca4e8e100aa6bfaaa20a49b9ccc239baa72933af309d0e5d85c`), shape OK. Members: `axum`, `axum::extract::State`, `tokio::signal` combined with `with_graceful_shutdown`, `bacon`. **Alone among the five it declined to exclude `bacon` on licence**, reasoning that an external, developer-installed tool that is never linked into the shipped binary does not engage the gate — which is the position owner ruling Q7.B has since made binding, so this raw's dev-reload recommendation survives the ruling unchanged and is adopted. Against that, **its figures are not endpoint-collected and are not used anywhere in this decision**: it reports axum at ">15k" stars (actual 27,100), "~150-200" open issues (actual 34), bacon 90-day downloads as ">1,500,000 (Proxy estimate based on tooling adoption)" (actual 21,763) and bacon's all-time downloads as "Data unavailable … assumed highly active", and it gives `rocket`'s MSRV as 1.89.0 where the registry says 1.64. Most of its inline citations are Vertex redirect URLs. It also proposes bounding shutdown with `tower_http::timeout::TimeoutLayer`, which is a per-request bound and R75's to decide.
  - `raw/doxa-perplexity.normalized.md` — Perplexity sonar-deep-research (sha256 `666031a08615390c89d5a834f5b2c6e119f02e79d3649ffce838ef7534e0382d`), shape OK. Members: `axum`, `tokio`, `hyper`, `tower-http`, and dev tooling as `Just` + `cargo-watch`. Agrees on the framework, the feature shape, `State` injection and native composition, and raises `BASELINE-REVIEW: F330`. Three of its positions are not adopted: `cargo-watch` is archived with a maintainer end-of-life notice; `tower-http` is explicitly out of scope (R75 owns it); and its drain wrapper carries the same clock-start defect as opus's. It carries no crate figures and states so, citing comparative articles rather than endpoints.

**An owner-supplied input, which is not an engine and is listed apart from the five raws.**
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` — "The Axum Companion
Stack — Reference Architecture (September 2026)", supplied verbatim by the owner on 2026-09-16
during the Wave 0 review walk. It produced no raw report, ran no engine and answered no prompt
field; it is recorded here because **owner decision 11 of 2026-09-16** requires revision 6 to
reconcile with it row by row where the two overlap, and its own provenance note fixes its
standing: *"an owner-supplied research input, not a binding standard and not a decision: each
research item that overlaps it must either agree with it on the record or say why it differs."*

**Its weight, stated exactly, because agreement with it is not evidence.** It carries no
executed check and says so: *"The code patterns are illustrative and compiled in my head, not
against the toolchain — validate them locally before relying on them"*, and it marks several
versions "verify". So **every fact revision 6 relies on from it was re-verified at a primary
source and asserted**, in `review/evidence/owner-reference-check-r6.log` — crates.io for axum's
release list and axum-test's versions and requirements, the GitHub REST API for issues #3809 and
#3003 and pull requests #3745 and #3819, Google Cloud's *Container runtime contract* for the
ten-second shutdown window, and the Cargo Book for the default version-requirement rule. Where
the document and a **fixed parameter** differ, the parameter governs and the document is not
followed: its `edition = "2021"` against `rust-edition` **2024**, and its
`rust-version = "1.85"` against `msrv-policy`, whose floor today is **1.96**. Its sole
recommendation on this item's own members — `axum` 0.8.9 on `tokio` 1 / `hyper` 1 / `tower`
0.5 — agrees with what revisions 1 through 5 already recommended on the evidence recorded
above, and **agreement is recorded as agreement, not treated as confirmation**: nothing in this
decision now rests on the document.

**Its overlap map, as the controller recorded it, and what revision 6 did with each row.** The
eight rows that overlap this item are reconciled where their topic lives — rows 1 through 7 in
the revision-6 note's table name the location of each. The remaining rows belong to other items
or to nothing yet, and owner decision 11 rules them **not decided and not researched here**.
One line each, with no position taken on any:

| Document row | Subject | Where it goes |
|---|---|---|
| C1, C2 | Templating (`askama`), static assets and the frontend build (`ServeDir` + `rust-embed`, or Vite) | **No P02 item; pending owner scoping.** The HTMX-versus-SPA head is an owner question, not a research one. |
| C3 | OpenAPI generation (`utoipa`, `utoipa-axum`) | **R71** (`openapi-generation-pipeline`); the typed-client half is **R84**. |
| C3 | TypeScript client generation (`openapi-typescript`, `openapi-fetch`, `ts-rs`) | **R84** (`openapi-typed-client-generation`). |
| C4 | Validation (`garde` + `axum-valid`) | **No P02 item; pending owner scoping.** It reaches the handler signature R70 and R71 shape. |
| C4 | Error contract, RFC 9457 | **R70** — see *Minimal realistic endpoint* above for the one question handed to it. |
| C5 | Database access, migrations, Cloud SQL connection (`sqlx`) | **No P02 item; pending owner scoping.** |
| C6 | Sessions, auth, password hashing, CSRF, OIDC, JWT | **No P02 item; pending owner scoping.** |
| C7 | WebSocket fan-out (`axum ws` + Redis Pub/Sub) | **No P02 item; pending owner scoping.** Issue #3003 is recorded under F338 as that layer's inherited hazard. |
| C8 | Background and scheduled work (`apalis`, Cloud Tasks) | **No P02 item; pending owner scoping.** |
| C9 | Config layering (`figment`) and secrets | **R77** (`web-env-settings`), with **R53**–**R56** owning config schema, discovery, tolerance and secret policy. The ten-second datum under F338 is R77's. |
| C10 | Logs and traces (`tracing`, `tracing-stackdriver`), error reporting | **R58** (`logging-pipeline-contract`) for the pipeline, **R78** for OpenTelemetry, **R79** for metrics. |
| C11 | Middleware order, rate limiting, security headers | **R75** (stack), **R74** (rate limiting), **R76** (CORS), **R72**/**R73** for pagination and idempotency. |
| C12 | Testing — harness, fixtures, mocks, snapshots, CI order | **R32** (harness and tiers), **R33** (property and snapshot), **R48** (mocking), **R11** (CI job structure). The in-process idiom is settled at Disagreement 3. |
| C13 | Project structure | Reconciled above under *Migration implications*; the crate boundary is **R02**'s, and R02's owner-accepted four-package workspace is what revision 10 writes that section against. |
| C14 | `cargo-chef`, `mold`/`lld`, `rust-toolchain.toml` | **R51** (container), **R68** (release binaries), **R42** (toolchain provisioning). `bacon` is settled above under F339. |
| C15 | Container image, distroless base, `PORT`, probes | **R51** (image), **R80** (`/healthz`, `/readyz`). |
| Cloud Run Runbook | `gcloud run deploy` flags, affinity, migrations on deploy, pool sizing | **No P02 item; pending owner scoping.** The template ships no deployment and `target-os-matrix` names no cloud. |
| Variants A / B | HTMX head versus SPA head, and the hybrid | **No P02 item; pending owner scoping.** Owner decision 11 lists it explicitly among the rows it does not admit. |
| Level One, `tokio` throughout | Whether the library and CLI join the web surface's async world | **R05** (`sync-async-execution-model`, open), which `## Parameters` above already records as a coupling this decision survives either way. |
| Reference `Cargo.toml` | `axum-extra` 0.12.6 at `["cookie","cookie-private","typed-header"]` — added by revision 9 | Cookie jars are C6's, which has **no P02 item; pending owner scoping**; typed-header extractors belong to whichever of **R72**–**R76** needs one. Not a member here; reconciled at Disagreement 3. |
| Reference `Cargo.toml` | `[profile.release]` — `lto = "thin"`, `codegen-units = 1` — added by revision 9 | **R68** (`release-binary-artifacts`) as the controller's reading and the nearest consumer, **with the ownership recorded as an open scoping question**: no prompt and no ledger row names these keys. Reconciled under *Migration implications*. |

**What the owner's licence ruling changed versus the raws.** Every licence-based exclusion in
every raw was enumerated and re-evaluated. Gate 1 is recorded throughout this decision as
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any
dependency or tool`, and the row is retained rather than deleted because the binding prompt
still contains gate 1 and its sha256 is cited by acceptance records.

| Raw | Licence-based sentence | Disposition |
|---|---|---|
| codex, `#### watchexec-cli` → *Qualified shortlist*, *Excluded by gate*, *Ranked runner-up* | "`bacon` is not qualified because its latest crate license is AGPL-3.0"; "`bacon` is excluded by the repository's compatible-license gate"; "no runner-up passes all recorded checks: … bacon's license is incompatible" | **Struck.** `bacon` is not excluded. |
| opus, `#### Dev-serve recipe` → *Excluded by gate*, and `BASELINE-REVIEW: F339` | "`bacon` 3.25.0 — **gate 1**: licence `AGPL-3.0` … a tool the template *requires* every contributor to install is the wrong place to spend that ambiguity"; and the F339 demotion premised on "each surviving candidate fails one gate" | **Struck**, and the recommendation changes: `bacon` is selected and the `BASELINE-REVIEW: F339` line is withdrawn. |
| opus, `#### axum` → *Tradeoffs* and `#### tokio` → *Tradeoffs* | "`axum` is `MIT`-only, not dual-licensed — compatible … but without Apache-2.0's explicit patent grant, which is the owner's stated reason for the dual licence"; "`MIT`-only (see `#### axum`)" | **Struck as an evaluation ground.** It was explicitly non-discriminating in the raw itself (it notes 17 of 52 packages are MIT-only whatever the framework), so removing it changes no recommendation. Licences are still reported as published facts. |
| openai, *Fitness gates* table | "Bacon 3.24.x … fails the owner's strict dependency/tool license rubric. **Excluded by gate 1**"; and *Ranked runner-up*: "Bacon, only under a recorded license-policy exception" | **Struck.** The exception is now the rule; no policy exception is needed. |
| gemini, `#### bacon` → *Excluded by gate* | "Pass (`AGPL-3.0` - strictly a local dev tool, not linked into the template binary)"; "*Note: … entirely permissible because it functions exclusively as an external, developer-installed command-line tool*" | **No change.** This raw did not exclude on licence, so the ruling leaves its conclusion standing. |
| perplexity, `#### axum` → *Excluded by gate* | "None of the shortlisted frameworks are excluded by obvious license incompatibility" | **No change.** No exclusion to strike. |

No candidate anywhere in this item is excluded on licence. The exclusions that stand —
`warp`, `viz`, `pavex`, `tide`, `xitca-web` and `watchexec-cli` on gate 2; `cargo-watch`,
`poem` and `rocket` on maintenance; `salvo`, `ntex` and `actix-web` on fit — rest on grounds
the ruling does not touch. The ruling does **not** touch this repository's own declared
licence expression, nor any rule against committing third-party copyleft files into this
repository; `bacon` is installed from crates.io by each contributor and no AGPL-3.0 file
enters this repository.

**Disagreements, and the evidence that settled each.**

1. **The dev-reload tool** — `watchexec-cli` (codex, openai), `bacon` (gemini), `cargo-watch`
   (perplexity), or no tool with auto-reload demoted to optional (opus). **Settled for
   `bacon` 3.25.0** by the licence ruling plus registry facts: with gate 1 struck, `bacon` is
   the only candidate that fails no applicable gate — `cargo-watch` is archived with its
   maintainer's own end-of-life notice in the README at tag `v8.5.3`, and `watchexec-cli`
   2.7.2 declares no `rust_version`. Because opus's demotion was premised on every candidate
   failing a gate, the premise is gone and auto-reload returns to the required recipe;
   `BASELINE-REVIEW: F339` is withdrawn and F339 now ports at capability level. The tool's
   fitness for the *console-log* half of F339 was then verified rather than assumed, since a
   TUI-first runner is not obviously able to stream a server's logs: `--headless` prints the
   child's stdout and stderr directly, `run-long` is a default job needing no `bacon.toml`, and
   `--features` reaches cargo. One correction to opus follows from the same reading: its
   migration list says no `bacon.toml` is needed, but bacon's default Unix job interruption is
   SIGKILL, so a `kill` override is required for a dev restart to exercise the production drain.
2. **Where the drain deadline's clock starts.** Opus and perplexity both wrap the entire serve
   future in `tokio::time::timeout(grace, server)`, which bounds the server's whole lifetime
   and would terminate a healthy service after the grace period; openai starts the timeout when
   the shutdown future fires. **Settled for openai's shape** on the merits — the two behave
   identically only if shutdown is requested at t=0 — with a consequence verified at source:
   that shape needs `tokio::sync::oneshot`, and none of `signal`, `net`, `rt-multi-thread`,
   `time` or `macros` enables tokio's `sync` feature, so `sync` is added to the recommended
   feature list, which opus's manifest omits. Gemini's `tower_http::timeout::TimeoutLayer` is a
   per-request bound, not a drain deadline, and belongs to R75.
3. **The member list — naming and granularity.** The raws differ: codex lists three members
   (two crates plus a tool), openai four (three crates plus a tool, with versions in the
   headings), gemini four (one crate, one **extractor type**, one API pairing, one tool),
   perplexity five (four crates including `hyper` and `tower-http`, plus "Just + cargo-watch"),
   and opus seven (two crates plus five patterns). **Settled on the merits, not by vote, by one
   rule: a member is a decidable artifact this item owns.** The prompt's own value test names
   five things that get rewritten if this answer is wrong — the framework dependency, the
   feature-gate shape, the config-injection mechanism, `main`'s entrypoint, and the dev-serve
   recipe — and the 2026-09-04 baseline review added router composition (F331) to this item.
   That yields the eight rows in the table under `## Decision`: three crate members plus five
   pattern members, one per artifact. What this rule excludes, and why: **`hyper`** (perplexity)
   is never declared in the template's manifest — it arrives transitively through `axum`, so
   there is nothing to decide; **`tower-http`** (perplexity, gemini) is named in this item's
   `## Out of scope` as R75's; **`axum::extract::State`** (gemini) is the mechanism the F330
   decision *selects*, not a separate decision — listing a type as a member would equally
   oblige listing `Router` and `IntoResponse`; and **`Just`** (perplexity) is the repository's
   existing command runner, not something this item chooses. `tower` **is** kept as a member,
   against codex and opus who fold it away, because it is a crate with a version pin the
   template's manifest must carry — but as a `[dev-dependencies]` entry, which check 2 settles:
   `cargo tree --invert tower` shows it already in the non-dev tree through `axum`, so a direct
   entry buys only the `ServiceExt` import in tests and must not be inside the `web` feature as
   openai and perplexity have it.

   **The in-process test idiom, reconciled with the owner-supplied document** (owner-reference
   *C12*, which picks "**axum-test + `#[sqlx::test]` + wiremock + insta**", version "axum-test
   18", over runner-up "tower `oneshot`" on the ground that "oneshot lower-level, more
   boilerplate", and its *Agent Enablement Notes*, "Use `TestServer::new(app)`; requires axum ≥
   0.8.7"; owner decision 11, row 5). **The `oneshot` choice above is kept, and the document's
   authority is not what settles it** — owner decision 11 makes the document an input, not a
   pre-decision. The ground, stated positively rather than as a rejection:
   - **It adds no crate to the template.** `cargo tree --invert tower` (check 2) shows `tower`
     0.5.3 is already in the **non-dev** tree through `axum` itself, so the `[dev-dependencies]`
     entry buys only the `ServiceExt` import — measured, not assumed, and the reason this
     member sits outside the `web` feature. `axum-test` would be a new crate in a template whose
     whole cost argument is the 12 → 52 package delta that check 2 measures.
   - **It exercises the production object.** `oneshot` is called on the same `Router`
     `build_router(state)` returns and `axum::serve` consumes, which is what makes acceptance
     criterion 3 — "`build_router(state)` is the only constructor" — testable rather than
     merely asserted.
   - **What the document's "more boilerplate" objection buys is real but out of scope here.**
     `axum-test`'s `TestServer` wraps request construction, cookies and a WebSocket client; its
     value rises with the surface under test, and most of that surface (`#[sqlx::test]`,
     `wiremock`, `insta`, WS) belongs to items this one does not own.

   **The alternative is recorded with the condition under which it wins, and with corrected
   figures.** `axum-test`'s registry state, asserted in
   `review/evidence/owner-reference-check-r6.log`, section D: its newest non-yanked version
   under this item's field rule — the same literal reading applied to `ntex` and `tide` in
   Disagreement 8 — is **22.0.0-rc.1 (2026-08-24)**, a prerelease; its newest **stable** version
   is **21.1.0 (2026-08-20)**, `rust_version` **1.89**, licence MIT, and it declares
   `axum ^0.8.9`. **The document's "axum-test 18" is three majors stale**, and its "requires
   axum ≥ 0.8.7" holds only from **18.3.0** onward — `18.0.0` declares `^0.8.4`, `18.7.0`
   declares `^0.8.8`. No fitness gate is answered for it here, because it is not selected; a
   gate pass would have to be established by whoever selects it. **The condition under which it
   wins:** when the template's test surface grows past a single in-process request — a database
   fixture, a cookie-carrying session, or a WebSocket client — the boilerplate `oneshot` leaves
   in each test outweighs one dev-dependency. **That call is R32's** (`test-harness-and-execution`,
   open), which owns the harness and the tiers, as *Validation strategy* above already states;
   this item owns only the idiom its own acceptance criterion needs, and R32 adding `axum-test`
   as a harness crate would not disturb the `tower` member or the owned value. Owner decision
   11 places C12 in R32's overlap set, so the document reaches R32 as an input in its own right.

   **`axum-extra`, which the owner-supplied document pairs with axum in its shared core, is not
   a member of this stack** (owner-reference *TL;DR*, "axum 0.8.9 + **axum-extra 0.12.6** on
   tokio 1 / hyper 1 / tower 0.5 / tower-http 0.6 / http 1", and its *Reference `Cargo.toml`*,
   `axum-extra = { version = "0.12.6", features = ["cookie","cookie-private","typed-header"] }`;
   owner decision 11, row 10). **The document's figure is correct and is not the issue.**
   Verified at the registry and asserted in `review/evidence/owner-reference-check-r9.log`,
   section B: `axum-extra` **0.12.6** is the newest non-yanked *and* the newest stable version,
   published 2026-04-14 — the same day as `axum` 0.8.9 — licence MIT, declared `rust-version`
   **1.80** (inside the 1.96 floor), requiring `axum ^0.8.9`. Nothing about it is stale or
   unfit. **It is excluded by the member rule this Disagreement already states** — *a member is
   a decidable artifact this item owns* — for the same reason `tower-http` is: what the
   document enables it for is another layer's business. Its three named features resolve to two
   optional crates and nothing else: `cookie = ["dep:cookie"]` and
   `cookie-private = ["cookie", "cookie?/private"]` bring in `cookie ^0.18.0` for signed and
   private jars, and `typed-header = ["dep:headers"]` brings in `headers ^0.4.0` for the
   `TypedHeader` extractor. **No acceptance criterion in this item asks for either.** The
   handler in *Minimal realistic endpoint* takes `State` and `Query` and returns the library's
   own types; there is no cookie, no session and no typed header anywhere in F303, F330, F331,
   F338 or F339.
   **Where it goes, as a hand-off and not a decision.** Cookie jars serve sessions, auth and
   CSRF — the document's own *C6*, which **no P02 item covers**; it is listed under `## Engines`
   as pending owner scoping. Typed-header extractors serve request handling and middleware, so
   they belong to whichever of **R72**–**R76** needs one. Either way the mechanism is already
   fixed by the owned parameter and needs no change here: `axum-extra` would be an **additive**
   dependency of a later layer nested inside the gated `crates/web/src/` tree, under the clause
   *"heavier opt-ins nest on top rather than widening it"*. **This item neither selects nor
   excludes it on fitness** — no gate is answered for it, because it is not a candidate here —
   and the owned value is byte-identical.
4. **The axum feature set.** Codex proposes `default-features = false` with
   `["http1", "json", "tokio"]`; openai `default-features = false` with seven named features;
   opus leaves the defaults on. **Settled for defaults on.** Codex's minimal set drops
   `matched-path` (which R78 and R79 need for low-cardinality route labels rather than raw
   high-cardinality URLs), `query` (which R72's pagination anticipates) and `tracing` (which
   emits axum's own spans into whatever subscriber R58 selects) — openai identifies each of
   those reasons explicitly, and they are the merits argument. Openai's explicit list then
   differs from the defaults only by `form` and `tower-log`; enumerating a default set invites
   silent drift when the crate changes it, and the reference implementation keeps the defaults
   on and adds to them rather than disabling them. `http2` stays off; it is off by default and
   no consumer has asked for it.

   **The owner-supplied document's feature list is additive later-layer territory, and is not
   enabled here** (owner-reference *Reference `Cargo.toml`*,
   `axum = { version = "0.8.9", features = ["macros", "ws", "http2"] }`; owner decision 11,
   row 2). The three are **additions to** axum's defaults, not replacements for them, so this
   row is not a disagreement about the default set settled above; it is a question about
   opt-ins, and the owned parameter already answers that question in general terms: **"heavier
   opt-ins nest on top rather than widening it, as separate features that require `web`"**. Each
   of the three is taken by the layer that needs it, not by this item:
   - **`ws`** — the WebSocket upgrade surface. No item in this programme owns it (see the
     hand-offs under `## Engines`), and axum issue #3003 under F338 is the hazard whoever takes
     it inherits. Enabling it here would ship an unbuilt, untested surface inside the `web`
     feature.
   - **`http2`** — already answered two sentences above on its own merits, and unchanged: off
     by default, no consumer has asked for it, and `axum::serve` needs only *one* of `http1` or
     `http2`, which the defaults supply as `http1`. A Cloud Run deployment would want it off in
     any case; the document's own *C11* caution says "no end-to-end HTTP/2 for WebSockets".
   - **`macros`** — `#[debug_handler]` and friends, an ergonomic aid for handler authors. It is
     a template-authoring convenience with no effect on the shipped surface, and adding it would
     widen the base feature for something no acceptance criterion needs.

   **Nothing about the owned value or the recommended feature list changes**, and no gate is
   re-answered: the base stays axum's published defaults `form, http1, json, matched-path,
   original-uri, query, tokio, tower-log, tracing`, the pattern for anything heavier stays the
   separate-feature form the owned value names (`otel = ["web", …]` for R78, `metrics` for
   R79), and a later item wanting `ws` follows that same pattern rather than editing this one.
5. **The tokio feature set.** Codex `["macros", "rt-multi-thread", "net", "signal"]`; gemini
   `["rt-multi-thread", "net", "signal"]`; opus adds `time`; openai adds `time` and `sync`.
   **Settled for openai's set.** `time` is not optional — without it there is no
   `tokio::time::timeout` and therefore no drain deadline at all, so codex's and gemini's lists
   cannot implement the F338 behavior they describe. `sync` follows from Disagreement 2 and was
   confirmed to be implied by nothing else in the feature graph.

   **The owner-supplied document proposes a sixth list — `full` — and it is not adopted**
   (owner-reference *Reference `Cargo.toml`*, `tokio = { version = "1", features = ["full"] }`;
   owner decision 11, row 9). **The rule this is decided by is already stated in this decision,
   at gate 5:** *"`tokio`'s `default = []`, so every feature is opted into explicitly."* That is
   not a preference for small manifests; it is the reason the five raws' lists could be
   adjudicated at all, and it is the same rule that **added** `time` and `sync` above when a
   named behaviour needed them. Applied to `full`, it asks what behaviour each added name
   serves. Read at tokio 1.53.1's own published `[features]` map and asserted in
   `review/evidence/owner-reference-check-r9.log`, section A:
   - **`full` is twelve features** — `fs`, `io-util`, `io-std`, `macros`, `net`, `parking_lot`,
     `process`, `rt`, `rt-multi-thread`, `signal`, `sync`, `time`.
   - **The six selected already cover seven of them**, because `rt-multi-thread = ["rt"]`. So
     this is not a disagreement about the runtime, the listener, the signals or the clock: on
     all of those the document and this decision agree exactly.
   - **What `full` adds beyond them is five names — `fs`, `io-util`, `io-std`, `parking_lot`,
     `process`** — and no acceptance criterion, no F338 behaviour and no line of `serve_until`
     uses any of them. `fs` and `process` are filesystem and child-process APIs this surface
     never touches; `io-util`/`io-std` are AsyncRead/AsyncWrite helpers and stdio wrappers that
     `axum::serve` does not route through.
   - **One of the five costs a crate, not just a code path.** `parking_lot` carries no feature
     body: it is the implicit feature tokio's **optional dependency**
     `parking_lot = "^0.12.0"` creates, so enabling it puts `parking_lot` and its own tree into
     the resolved graph. That is measured cost against **gate 6**, whose whole finding is the
     12 → 52 package delta the `web` feature already pays.

   **So the disposition is *differs, with ground*, and it moves nothing.** The recommended list
   stays `rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`, and the owned value is
   byte-identical. The document's own preference is understandable in its context — a reference
   architecture for an application, where `full` saves a reader from auditing a feature list —
   but this template's cost argument is measured in packages, and a template is copied. **Where
   the document is right and this decision agrees:** its `version = "1"` is a caret requirement
   that admits 1.53.1, exactly as *Compatibility* above explains for axum; the two differ only
   on the feature list, not on the runtime or its version line.
6. **Whether Rust needs py's lazy configuration fallback.** All five raws say no, for the same
   reason. Recorded as `BASELINE-REVIEW: F330`; no disagreement to settle.
7. **Router registry versus native composition.** Codex, opus, openai and gemini all say
   native; perplexity does not raise it. Settled by the reference implementation read at
   source: `rust-lang/crates.io` has no `ROUTERS` list and no registration loop. Recorded as
   `BASELINE-REVIEW: F331`.
8. **Framework figures where the raws disagree.** `rocket`'s MSRV — gemini 1.89.0, opus 1.64 —
   settled at **1.64** by the registry. `ntex`'s newest non-yanked version — opus 3.12.3 with
   `rust-version` 1.88 — is **4.0.0-beta.10 (2026-09-12), `rust-version` 1.95** under the
   prompt's rule as written ("newest with `yanked: false`"); the same reading makes `tide`'s
   newest **0.17.0-beta.1 (2021-12-06)** rather than opus's 0.16.0 (2021-01-29). Both gaps are
   a **field-rule reading, not a data error on either side**: the opus raw appears to have
   applied a newest-*stable* filter that the prompt's rule does not contain. Neither crate is
   recommended, and both are excluded on grounds that hold under either reading. `watchexec-cli` — openai 2.5.1, codex and opus 2.7.2 — settled at **2.7.2** by the
   registry. Where codex's and opus's 2026-09-12 figures overlap they agree with each other and
   with this run's 2026-09-13 snapshot up to one day's counter drift (for example axum's 90-day
   downloads 115,597,652 → 114,795,000 and stars 27,095 → 27,100); the figures reported in this
   decision are **this run's**, with this run's retrieval date.

**Unproven here; P03's to prove in the real template.** Each row is a claim this decision makes
that no check in this run establishes, paired with what would establish it. A row that fails in
implementation sends the decision back for revision against this recorded research, not back to
research.

| Claim | Status | What would prove it |
|---|---|---|
| The web handler returns the library's own `serde` types over a real listener, with no mirror struct, byte-identical to the CLI's output (R01 acceptance criterion 6) | **Unproven here.** The opus raw reports two passing tests covering exactly this, in-process and over a bound listener; those are engine-reported and were not re-executed, because executing them means building the recommendation. | A template integration test: a real HTTP GET to a bound listener whose body decodes into the library's `Vec<Project>`, compared against the CLI's rendered output for the same query. |
| `build_router(state)` is the only constructor, and a handler asking for an unregistered substate fails to compile | **Partly proven.** The state bound itself is verified (check 1); the compile-failure demonstration is not. | A `compile_fail` doctest in the template showing a handler requesting a substate `AppState` has no `FromRef` impl for, and asserting the error. |
| The entrypoint drains in-flight work on SIGTERM and exits **143** within the configured window, exits **130** on the SIGINT path, and exits **1** when a request never completes | **Unproven.** The enabling fact — axum supplies no deadline — is read at source (check 3); the three behaviors are not exercised, and neither is the signal-kind threading the exit integers need. R67's own unproven list carries the same item ("*The web surface's `SIGTERM` drain to 143* … only the exit integer is shared, so the risk is low but the path is unbuilt"). | Three template tests: one that begins a slow request, sends SIGTERM, and asserts both the response completing and exit **143** inside the window; its SIGINT twin asserting exit **130**; and one with a permanently blocked request asserting the `GracefulShutdownTimedOut` branch and exit **1**. The opus raw reports a passing test for the unbounded-drain half only, and names no exit code. |
| The serve binary's shutdown future reports **which** signal fired, so `main` can map 130 versus 143 | **Unproven, and not implementable as the recorded snippet is written** — it takes `S: Future<Output = ()>`. The enabling fact is the two-source mechanism already recorded under F338: `tokio::signal::ctrl_c()` and `tokio::signal::unix::signal(SignalKind::terminate())` are separate listeners selected over, as the reference implementation does (`src/bin/crates-io/server.rs` at `3df99c2`, asserted in `assert-figures.log` section F as "selects over SIGTERM via tokio::signal::unix"). **No check in this run asserts that the two futures are distinguishable at the type level**; that is why this row exists. | A template test asserting the two integers (row above), which fails if the signal kind is erased; P03 threads the kind (or R67's `Exit` value) out of `shutdown_signal()` instead of `()`. |
| The serve binary satisfies the CLI Design Standard's required global core | **Unproven.** The rule and its scope are read at the standard (R4.1, its header scope line, Appendix A's "§4 … unchanged"); no binary exists to run, and the R9.14 conformance fixture has not been written. *(Revision 6 gave the second ground as "**R60 has not selected the parser**"; that wording is superseded by the owner's acceptance of R60 revision 7 on 2026-09-15 — `clap` 4.6.6 with the `derive` API, recorded in `docs/port/OWNER-ACCEPTANCES.md`, publication pending — and the row stays unproven on the grounds that remain true.)* | The R9.14 conformance fixture named under *Validation strategy*: `<app>-serve --help` and `<app>-serve -V` each printing to stdout and exiting `0`, `-V` printing the single `<app>-serve <semver>` line R4.6 fixes, and the four remaining core options accepted. |
| The stack compiles and tests on both `target-os-matrix` legs and at the MSRV floor | **Unproven.** Only the macOS host at rustc 1.98.0 was exercised here; the Linux leg and the 1.96 leg were not. | The template's CI matrix (R11): `cargo test --workspace --locked --features web` on `ubuntu-latest` and `macos-latest`, plus a `cargo check` leg pinned to the declared `rust-version`. |
| The web feature's wall-clock build cost and binary size | **Unproven and not measured here** — measuring them honestly means building the recommendation. The opus raw's figures (5.69 s → 9.28 s wall, 7.12 s → 25.61 s user CPU, release binary 2,001,600 bytes / 1,574,392 stripped) are engine-reported. Only the dependency-count half (12 → 52 packages) is reproduced here. | A timed clean and incremental build of the real template on each CI runner, and `cargo build --release` plus a size measurement of the stripped serve binary. |
| The dev recipe serves with console-formatted logs and restarts on a source edit | **Unproven, and blocked on R58.** The tool's capabilities are verified (check 5); the recipe's behavior is not, because the environment variable's name and semantics are R58's and unpublished. | Once R58 publishes: `just serve` answering `GET /healthz` with console-formatted logs on stderr, a source edit producing one restart, and the same binary outside the recipe emitting the production structured profile. |
| The exact `cargo` argv bacon composes from `-j run-long --features web -- --bin <app>-serve` | **Inferred, not observed.** Each link is read at source — the job's `["cargo", "run"]` tokens, post-`--` arguments appended to them, and `--features` applied after — but bacon has no dry-run mode, so the assembled command line was never printed. | Running the recipe once in the real template and reading the command bacon reports, or `bacon` with `RUST_LOG=debug`, which logs `command: {:#?}` in `src/mission.rs`. |
| A `bacon.toml` `kill` override makes the dev restart run the production SIGTERM drain | **Unproven.** That bacon's default is SIGKILL and that a `kill` override exists are both read from its published configuration reference; that the override produces a clean drain of `cargo run`'s grandchild process is not exercised. | A template check that edits a source file under `just serve` and observes the old process logging its graceful-shutdown path rather than dying silently. |
| `actix-web` does not win on a representative instrumented workload | **Unproven and deliberately unmeasured.** No public benchmark measures the required path, and the TechEmpower payload was unretrievable on 2026-09-12 (opus raw). | The two-workload benchmark openai's raw specifies — an adapter ceiling and a service-like run with R75/R78/R79's layers and a local collector — reporting p50/p95/p99, throughput, CPU-seconds per million requests, peak RSS, binary size and build times on identical hardware. Only a material advantage there reopens the framework choice. |
| `axum`'s and `bacon`'s macOS support beyond the pinned versions tested here | **Unproven beyond `axum` 0.8.9 and `bacon` 3.25.0 on macOS 26.4 aarch64.** Neither project's CI covers macOS. | The template's own `macos-latest` CI leg, continuously. |
| `unsafe` posture of `tokio` and of the unrecommended candidates | **Unproven here.** `axum`'s is verified (`unsafe_code = "forbid"`, zero occurrences in `src/`); tokio's 1,066 occurrences are the opus raw's count, not recounted; the remaining candidates were not inspected by anyone. | `cargo geiger` over the template's resolved tree, if a posture question ever arises; none of the uninspected candidates is recommended. |

**Uncertainty and coverage.** Every required top-level field and every member field of this
decision is supported by at least the codex, opus and openai raws; gemini and perplexity add
the dev-reload position that the licence ruling vindicated and independent agreement on the
framework, the feature shape and F330, and no field is left unsupported. Remaining uncertainty
beyond the unproven table: the resolved-tree MSRV figure of 1.80 is read from declared
`rust-version` fields, and nine transitive dependencies declare none, so it is a floor on what
is *declared*, not a proof that the tree compiles at 1.96 — the template's MSRV CI leg is what
would prove that. The population figures are a single snapshot at `2026-09-13T07:57:55Z` and
will drift. The `AppState` field list stays medium-confidence until R77 defines the settings
type and R58 the logging contract.

## Supersedes

**Revision 9, published 2026-09-17, sha256 `d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`, superseded 2026-09-17 by owner ruling W1-R02.** This section exists because revision 10 edits a **published** decision. Revision 10 changes the owned parameter `web-extra-surface` in the six clauses R02's `CONFLICT:` line names, and the prose and table sites that state the same facts; it changes no recommendation, no crate, no version pin, no feature list, no exclusion, no fitness-gate answer, no alternative ranking, no reference-row disposition, no engine adjudication and no evidence file. The five `- assumes` lines are unchanged. What moved, and what deliberately did not, is itemised in the revision-10 note at the top of the current entry and is established by diff against the bytes preserved below.

The complete revision-9 entry follows, preserved verbatim.

# R69 web-framework-stack — decision (revision 9, 2026-09-16)

**Revision note (revision 9). Three rows of the owner-supplied reference architecture that
revision 6's reconciliation missed, added to it; no owned value, no recommendation and no
existing evidence file moves.** Revision 9 rewrites revision 8 (sha256
`ce7a5dad994e4c5fa87a35674a7172913265cf70cc13456ed105a7018270407a`) in place. No revision of
this decision has been published, so there is still no `## Supersedes`. The one
`- owns web-extra-surface` line and the five `- assumes` lines are **byte-identical to
revisions 2 through 8**, the H2 set is unchanged, and every file of the six checks,
`yanked-control-r5.sh`, `owner-reference-check-r6.sh` and every snapshot outside the new
`snapshots/r9/` directory is **byte-identical**.

**Why there is a revision 9 at all.** Revision 8 was **approved by both round-8 audits** — the
empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r8`, model `gpt-5.6-terra`, family openai) with
`unresolved-findings: none`, and the judgment audit likewise. Revision 9 repairs no audit
finding. Its prompt is the **brief drafter's report**, which found that revision 6's
reconciliation with the owner-supplied reference architecture
(`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, folded in under
**owner decision 11 of 2026-09-16**) disposed of eight rows but left **three rows of that
document's reference `Cargo.toml` carrying no disposition at all**: its
`tokio = { version = "1", features = ["full"] }`, its `axum-extra` dependency, and its
`[profile.release]` block. Owner decision 11 requires a disposition for every overlapping row,
so the omission is a gap in the reconciliation rather than a defect in the recommendation.
Revision 9 closes it and does nothing else.

**The three rows, in the same form as the revision-6 table below, continuing its numbering.**
Each was verified at a primary source rather than taken from the document, whose own caveat
records that its patterns were "compiled in my head, not against the toolchain".

| # | Row | Disposition |
|---|---|---|
| 9 | Runtime features — the reference `Cargo.toml` writes `tokio = { version = "1", features = ["full"] }` against the six named features this decision selects | **Differs: ground.** `full` is twelve features; the six plus the `rt` that `rt-multi-thread` implies cover seven of them, and the five it adds — `fs`, `io-util`, `io-std`, `parking_lot`, `process` — serve no behaviour F338 asks for, while `parking_lot` is an optional **dependency** and so lands in the tree gate 6 measures. The ground is this decision's own rule, already stated at gate 5: "`tokio`'s `default = []`, so every feature is opted into explicitly." Owned value unmoved. Recorded at Disagreement 5. |
| 10 | `axum-extra` — the reference's shared core pairs `axum-extra 0.12.6` with axum, at `features = ["cookie", "cookie-private", "typed-header"]` | **Hand-off: not decided here.** The version is current, not stale (0.12.6 is the newest non-yanked and newest stable, MIT, `rust-version` 1.80, requiring `axum ^0.8.9`), so nothing is wrong with the document's figure; the crate is simply not a member of this item's stack, because the three features it enables are two extra optional crates — cookie jars and typed headers — that no behaviour this item owns asks for. Cookie jars are C6's (**no P02 item; pending owner scoping**); typed-header extractors belong to whichever of **R72**–**R76** needs them. It nests on top under the owned value's "heavier opt-ins nest on top rather than widening it" clause. Recorded at Disagreement 3 and in the overlap map. |
| 11 | `[profile.release]` — the reference sets `lto = "thin"` and `codegen-units = 1` | **Hand-off, and the owning item is not yet fixed — the gap is named rather than papered over.** Verified against this repository: **no** binding prompt of any of the 85 research items, and **no** row of the commonality ledger, names `[profile`, `lto`, `codegen-units` or `opt-level`. The controller's reading is **R68** (`release-binary-artifacts`), and R68 is indeed the nearest consumer — the release binary's size and build time are what the profile governs and what R68's own questions weigh — but R68's prompt scopes itself to "which distribution channels/artifact *types* … get built and shipped" and puts manifest declarations in **R49**'s scope, while R49's owned `build-tool-output-shape` makes "Cargo's own manifest … the entire declaration surface" yet sets no `[profile.*]` key. So: **hand-off to R68 as the controller's reading, with the ownership itself recorded as an open scoping question.** Recorded under *Migration implications* and in the overlap map. |

**The evidence, and what is deliberately not touched.** Two new files, matching the fetcher and
check pair revision 6 introduced: `review/evidence/fetch-owner-reference-r9.sh` writes reduced
snapshots under `review/evidence/snapshots/r9/`, which are committed, and
`review/evidence/owner-reference-check-r9.sh` asserts against them — plus, for row 11, against
this repository's own committed prompts and ledger, because "which item owns this subject" is a
fact about this repository rather than about an upstream project. Its cited log is
`review/evidence/owner-reference-check-r9.log`. Only **published crate metadata** is
snapshotted — versions, licences, declared `rust-version`, `[features]` maps and dependency
requirements, all served by the crates.io API — so no third-party source file enters this
repository and the rule the owner's 2026-09-12 ruling explicitly does not touch stays
unengaged. `owner-reference-check-r6.sh`, its snapshots, `yanked-control-r5.sh` and the six
checks are **not edited**. `review/empirical/parameters-check.sh` was re-run against this file
and `diff` reported no differences against `review/evidence/parameters-check-r2.log`.

**Revision note (revision 8), retained as the record of that revision. It was approved by both
round-8 audits, with `unresolved-findings: none`; its body is retained verbatim and nothing in
it is withdrawn. Its own heading recorded it as: two record-integrity corrections to the
revision-7 note below; no sentence of the JF-4 repair, no owned value and no evidence file
moves.** Revision 8 rewrites
revision 7 (sha256 `a64addcff304770e9c114d05d974da4aaa9395e9095dff2f86823a45a29dfcfe`) in place,
answering both findings of the round-7 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r7`, model `gpt-5.6-terra`, family openai), which
confirmed the three JF-4 repairs and rejected only the revision-boundary record, while the
round-7 judgment audit (`review/audit-fable.md`, actor
`audit-fable-2026-09-12T204004Z-d02022bf6f42-r7`, family anthropic) returned `approve` with
`unresolved-findings: none`. **Finding 1 — the hunk count**: the revision-6-to-7 boundary was
reported as **"six hunks"**, and that figure is corrected to **five**, because
`git diff 10a83c4 1187133 -- review/DECISION.md` prints five `@@` headers — at git's default
three-line context the retitled first line and the new revision-7 note are one contiguous hunk,
followed by the history line and the three JF-4 locations — whereas **six** is the count of
*edited locations*, which is what `diff -U0` reports because it splits that first pair; "hunk"
in this decision now means a unified-diff hunk at default context, and an enumeration of
locations is labelled as such. **Finding 2 — the no-evidence-change claim**: it was made against
the range `10a83c4..HEAD`, which spans the intervening revision-6 audit-checkpoint commits and
therefore carries `review/evidence/audit-*` additions belonging to those commits rather than to
this revision, so it is scoped instead to the commits that produced revision 7 —
`git show --stat --name-only 3e4c086` and the same command on `1187133` each list exactly one
path, `research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/DECISION.md`. **Nothing else
moves**: the title, this note, the revision-7 note's retention heading and the history line are
the whole of revision 8, whose own revision-7-to-8 boundary is **two unified-diff hunks**, and
the one `- owns web-extra-surface` line, the five `- assumes` lines, the H2 set, every sentence
of the JF-4 repair and every evidence file are byte-identical.

**Revision note (revision 7), retained as the record of that revision. It was approved by the
round-7 judgment audit and rejected by the round-7 empirical audit on the two record-integrity
findings the revision-8 note above answers; its body is retained verbatim and nothing in it is
withdrawn.** Revision 7 rewrites revision 6 (sha256
`d4d6a8d2a3297a6db488580142de6d651f33b8109e9023994f6cb9f5ecfd6a17`) in place. No revision of
this decision has been published, so there is still no `## Supersedes`. The one
`- owns web-extra-surface` line and the five `- assumes` lines are **byte-identical to revisions
2, 3, 4, 5 and 6**, and so are the recommendation, every version pin, every exclusion, every
fitness-gate answer including gate 1's `inapplicable` row, the R67 exit contract and the request
to R67, the CLI Design Standard's R4.1 required global core, the H2 set, and every evidence
script, cited log and committed snapshot. **No evidence file is added, edited or replaced.**
Check 6, `review/empirical/parameters-check.sh`, asserts only on lines beginning `- assumes `,
`- owns ` and `## `, none of which this revision touches; it was nevertheless re-run against
this file as a confirmation, exited `0`, and its output `diff`s **empty** against the cited
`review/evidence/parameters-check-r2.log`, which is therefore left unchanged rather than
superseded by an r7 copy of the same bytes. Checks 1 through 5, and `yanked-control-r5.sh`,
read no part of this file.

Revision 6 was **approved** by the round-6 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r6`, model `gpt-5.6-terra`, family openai, verdict
`approve`, `unresolved-findings: none`) and **rejected** by the round-6 judgment audit
(`review/audit-fable.md`, actor `audit-fable-2026-09-12T204004Z-d02022bf6f42-r6`, model
`claude-opus-5`, family anthropic) on **one** finding — that audit records JF-1, JF-2 and JF-3
as closed and marks its three observations explicitly as *not* findings. Revision 7 answers the
one finding and changes nothing else:

- **JF-4** — *"the decision states twice, as present fact, that the CLI parser its serve
  binary's required global core is parsed with is still R60's open choice, and keys a
  `re-verify:` trigger on that selection — but R60's parser selection (`clap` 4.6.6, derive
  API) was owner-accepted on 2026-09-15 as W0-R60, one day before revision 6, so the statement
  is false and the trigger has already fired"*. Repaired at the three locations the finding
  names, cited by **revision 6's line numbers**: the flag-surface paragraph of
  `### Principles and implementation` (**line 908**) and the global-core row of the unproven
  table (**line 2105**), each of which now quotes revision 6's wording, labels it superseded by
  the acceptance, and states the accepted fact in its place; and the `re-verify:` line (**line
  1378**), whose R60 clause is **replaced, not deleted**, because a watchable event remains.

**The accepted fact, cited rather than asserted.** `docs/port/OWNER-ACCEPTANCES.md` records
`R60 | 7 | 67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2 | accept |
2026-09-15 | W0-R60 option A; clap 4.6.6 derive, clap_complete 4.6.9, dependency-free build.rs;
OV-01 refused per the 2026-09-14 ruling; first publication pending`. R60's parser is therefore
**selected and owner-accepted, and unpublished as yet** — a pair of states this decision's own
vocabulary already keeps apart, since it cites R49 as having selected alternative A1 while
labelling that revision unpublished. Read on **2026-09-16**, together with
`research/runs/R60/2026-09-05T183002Z-09f93cfc507c/review/DECISION.md`, whose current revision 8
still selects `clap` 4.6.6 with the `derive` API and `clap_complete` 4.6.9. **No clap feature
set beyond `derive` is transcribed anywhere in this decision**, deliberately: R60 revision 8 is
still moving that set, and nothing here reads it. Only the `derive` API is named, because it is
part of what the owner accepted. **The design consequence does not move, and the accepted answer
strengthens it** — `clap` is a non-optional dependency of the package for the CLI binary, so the
serve binary reuses it, the `web` feature adds no parser crate, and check 2's measured 12 → 52
package delta stands by construction.

**The `re-verify:` R60 clause is replaced, not deleted, and narrowed to what is still
watchable.** *"when R60 selects the CLI parser the serve binary's global core is parsed with"*
names an event that occurred on 2026-09-15. What remains worth watching is the gap between the
accepted text and the published one — R60's file has already moved after its acceptance — so the
clause now reads, in full and unbackticked as that line is written, "when R60's published
decision moves off its owner-accepted clap 4.6.6 derive selection for the CLI binary the serve
binary's global core is parsed with". Every other clause on that line is byte-identical, which
a `diff` of the line shows rather than a count.

**Mechanical enumeration, run before any edit and re-run after it.** Two `/usr/bin/grep -n`
passes over this file: one for `R60`, and a separate case-insensitive one for `parser`, so that
a sentence about the parser's state which never says "R60" could not escape. The union, by
revision 6's line numbers, is **469, 894, 895, 908, 1244, 1378, 1382, 1835, 2105**. **Edited:
908, 1378, 2105.** **Deliberately left byte-identical, each with its ground:** 469, which sits
inside the retained revision-2 note and records what revision 2 did, which is still true; 894
and 895, which attribute who binds a behavior ("help layout is R60's parser") rather than
asserting a selection state; 1244, the migration table's `src/bin/<app>-serve.rs` row, and 1382,
the `- owns web-extra-surface` line, which share the wording *"the parser crate R60 selects for
the CLI binary"* — wording the round-6 judgment audit ruled "survives the correction verbatim",
true of a selected parser exactly as of an unselected one, and inside an owned value that 19
consumers read and check 6 validates; and 1835, which is an evidence script's JSON parser and
has nothing to do with R60. Both passes were re-run against the edited file: outside this note,
every hit is one of those nine locations at its shifted line number, and no new hit appeared
anywhere else. The `**Sources.**` paragraph is **not** extended, on the revision brief's
explicit instruction that no other sentence changes; the two files revision 7 read are named in
this note instead.

**Revision note (revision 6), retained as the record of that revision. It was approved by the
round-6 empirical audit and rejected by the round-6 judgment audit on JF-4 alone, which the
revision-7 note above repairs; its body is retained verbatim and nothing else in it is
withdrawn.** Revision 6 rewrites revision 5 (sha256
`0fc0ed8a9c4a6daac900e23524c1c3ba0ef1707aeb44833c0ca2b2b57eb4cf4c`) in place. No revision of
this decision has been published, so there is still no `## Supersedes`. The one
`- owns web-extra-surface` line and the five `- assumes` lines are **byte-identical to
revisions 2, 3, 4 and 5**, and so is everything the owned value fixes: `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency, `bacon`
3.25.0 as the dev watcher, the exclusions, the R67 exit contract (SIGTERM →143, SIGINT →130,
drain-deadline expiry →1) and the request to R67, the CLI Design Standard's R4.1 required
global core, gate 1's `inapplicable` answer under owner ruling Q7.B, and every evidence script
and cited log of the six checks and of `yanked-control-r5.sh`. **The specific question that
could have moved the owned value was asked and answered on evidence.** The owner-supplied
document advises `axum = "=0.8.9"` — an exact-equality requirement — and this item is not
owner-accepted, so changing the value was permitted. It is not warranted: **neither the owned
value nor the migration table states a requirement operator at all**, and Cargo's default for a
bare version string is the caret requirement, under which `"0.8.9"` *is* `>=0.8.9, <0.9.0` and
therefore already cannot resolve to 0.9 — which is the document's only stated reason for the
`=` form. Read at the Cargo Book and asserted in
`review/evidence/owner-reference-check-r6.log`, section B. The ground for *not* adopting `=` is
recorded under *Compatibility* below. So the value stays byte-identical, and
`review/empirical/parameters-check.sh` was re-run against this file with `diff` reporting no
differences against `review/evidence/parameters-check-r2.log`.

**What revision 6 is.** Revision 5 was **approved** by the round-5 empirical audit
(`review/audit-codex.md`, actor `audit-codex-2026-09-12T204004Z-d02022bf6f42-r5`, model
`gpt-5.6-terra`, family openai, verdict `approve`, `unresolved-findings: none`), which reran
all six checks plus `yanked-control-r5.sh` three times in place and once from a clean
`git archive HEAD` extraction, all byte-identical, and independently counted 54 yanked errors.
Revision 6 therefore repairs no defect. It carries out **owner decision 11 of 2026-09-16**
(`docs/planning/p02/owner-decisions.md`, *Owner-supplied reference architecture — STANDING
INPUT*), which rules that R69 "reconciles with it row by row where they overlap … and records
agreement or a ground for differing; rows belonging to other items are recorded as hand-offs,
not decided." The document is recorded as an owner-supplied **input** under `## Engines`, with
its provenance and overlap map; each row's reconciliation is placed where that row's topic
already lives, and **no new H2 heading is added** — the H2 set is the one the role contract
fixes and the audits have checked.

**The document is an input, not an authority, and every fact taken from it was re-verified.**
It says so itself: its closing caveat records that its code patterns were "compiled in my head,
not against the toolchain", and it flags several versions "verify". Owner-fixed parameters in
`docs/port/PARAMETERS.md` override it where they differ — **edition 2024 over its
`edition = "2021"`, and `msrv-policy` over its `rust-version = "1.85"`** — and those two `-
assumes` lines are unchanged. Two new scripts do the verification:
`review/evidence/fetch-owner-reference-r6.sh` (a fetcher, not a check, the sibling of
`fetch-figures.sh`) writes reduced snapshots under `review/evidence/snapshots/r6/`, which are
committed; `review/evidence/owner-reference-check-r6.sh` asserts against those snapshots, never
touches the network, carries a control that must report a present string, and is cited as
`review/evidence/owner-reference-check-r6.log`. It was run three times and runs 2 and 3 were
byte-identical to run 1; a scratch copy with one expectation mutated to `9.9.9` exited `1`, so
the assertions can fail.

**Every row's disposition, one line each.** The document is cited by its own section headings.

| # | Row | Disposition |
|---|---|---|
| 1 | Framework and runtime — axum 0.8.9 / tokio 1 (TL;DR, Key Finding 1, Recent-Bugs register) | **Agree** on the members and the version. **Differ with ground** on the `=0.8.9` pin (a bare requirement is already caret-bounded) and on "a 3-year horizon on 0.8 safe" (the primary source is weaker than the paraphrase, and 0.9 work is live on `axum::serve`). Owned value unmoved. Recorded under *Compatibility* and under F338. |
| 2 | Features — the document enables `ws`, `http2`, `macros` (reference `Cargo.toml`) | **Additive later-layer territory, not enabled here**, under the owned parameter's own "heavier opt-ins nest on top rather than widening it" clause. Recorded at Disagreement 4. |
| 3 | Dev loop — `bacon` over `cargo-watch` (C14) | **Agree**, and this item's finding is the stronger one: the document does not mention that bacon's default Unix job interruption is SIGKILL. The `bacon.toml` `kill` override stands. `cargo-chef` and `mold` are **hand-offs** (R51, R68). Recorded under F339. |
| 4 | Graceful shutdown — Cloud Run's 10-second SIGTERM window; axum issue #3003 (Cloud Run Runbook, C7) | **Verified at Google's own page and at the GitHub API.** The 10 s window is recorded as a **datum handed to R77** for its drain-deadline default; #3003 is recorded as a **hazard for a later WebSocket layer**, which has no P02 item. Neither changes anything here. Recorded under F338. |
| 5 | Test idiom — `axum-test` ranked over `tower::ServiceExt::oneshot` (C12) | **Differ with ground**, and the document's figure is stale: the `18` line is three majors behind. `oneshot` is kept, `axum-test` is recorded as the alternative with the condition under which it wins, and the harness tier remains **R32's**. Recorded at Disagreement 3. |
| 6 | Layout — single crate, feature-vertical modules, workspace later (C13) | **Agree**, and it matches R49's selected alternative A1. Which crate carries the feature is **R02's**, still open. Recorded under *Migration implications*. |
| 7 | Error contract — RFC 9457 Problem Details (C4) | **Hand-off to R70**, not decided here, with the note that owner-accepted R67's envelope differs in shape and R70 must reconcile them. Recorded under *Minimal realistic endpoint*. |
| 8 | Everything else — templating, static assets, OpenAPI, validation, database, sessions/auth, WebSocket fan-out, jobs, config/secrets, observability, middleware, container, Cloud Run deployment | **Hand-offs**, one line each, by item or as "no P02 item; pending owner scoping". Listed once under `## Engines`. No research was done on them and none is decided. |

**Revision note (revision 5), retained as the record of that revision. It was approved by the
round-5 empirical audit and nothing in it is withdrawn.** Revision 5 rewrites revision 4 (sha256
`1814883d3d4b83333ea145c6dae0e02d86ba058b46b512c4bdfeac00afca23c3`) in place. No revision of
this decision has been published, so there is still no `## Supersedes`. **Nothing about the
recommendation, the parameters, the checks or the evidence moves.** `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency and `bacon`
3.25.0 as the dev watcher stand unchanged; the single `- owns web-extra-surface` line and the
five `- assumes` lines are byte-identical to revisions 2, 3 and 4; the R67 exit contract
(SIGTERM →143, SIGINT →130, drain-deadline expiry →1) and the request to R67 are unchanged;
the CLI Design Standard's R4.1 required global core is unchanged; fitness gate 1 remains
`inapplicable` under owner ruling Q7.B; revision 4's repair — `review/evidence/feature-shape-check-r4.sh`,
its cited log `feature-shape-check-r4.log` and the isolated `CARGO_HOME` that makes the
crates.io-index warning impossible — is **untouched and byte-identical**, as are the other
five scripts and every cited log. Revision 5 repairs exactly one defect: **a number in
revision 4's own revision note that was written from recall instead of from a run.**

Revision 4 was **rejected** by the round-4 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r4`, model `gpt-5.6-terra`, family openai) on a
single finding, quoted verbatim:

> **Reject — the claimed yanked-lookup control has the wrong observed count.** Revision 4
> states at `review/DECISION.md:84-90`, and its own script repeats at
> `review/evidence/feature-shape-check-r4.sh:72-80`, that an empty isolated `CARGO_HOME` with
> yanked lookup enabled prints 55 `couldn't check if the package is yanked` errors. I recreated
> that variant with the same pinned advisory-db commit, an otherwise empty cargo home, and only
> the `cargo-audit` symlink required for Cargo to discover the subcommand. It loaded 1,243
> advisories, scanned 55 dependencies, exited `0`, and emitted **54** such errors
> (`review/evidence/audit-codex-r4-empty-cargo-home-yanked.log:59`). The decision must correct
> the count before acceptance.

The finding is correct and is accepted without qualification. The same auditor's findings 2 and
3 confirmed the rest of revision 4: the isolated-`CARGO_HOME` repair reproduces byte-for-byte in
every mode tried — three in-place reruns, a temporary-index `git archive` extraction, a `HEAD`
`git archive` extraction, and a rerun made while a separate process held `flock(LOCK_EX)` on
`~/.cargo/.package-cache` — and the retained r3 artefacts and the other five scripts and logs
are unchanged and matched their cited logs. Revision 5 changes none of that.

**Why the wrong figure arose, so a reader can see the confusion rather than take the correction
on trust.** **55 is the dependency count**, not the error count. It is the figure in
cargo-audit's own `Scanning Cargo.lock for vulnerabilities (55 crate dependencies)` line, which
check 2 asserts as a constant and which this decision cites correctly wherever else it appears.
The yanked lookup does **not** run over all 55. It is a crates.io **registry** query, so it runs
only over lockfile entries carrying a
`source = "registry+https://github.com/rust-lang/crates.io-index"` key; the probe's root package
`r69_feature_shape` is a **path** package with no `source` and is skipped. 55 − 1 = **54**, and
`yanked-control-r5.sh` asserts each of those three figures separately rather than leaving this
paragraph to be believed. Revision 4 reported the variant as tested, then wrote down the count
it had to hand — the figure on the line immediately above the first error line in that same
output — instead of the count the run produced. That is the failure mode this programme has
rejected all week, and the correction is therefore not a re-wording: it is a rerun.

**The repair: the figure is now true by construction.** Revision 5 re-ran the rejected variant
itself, in the new script `review/evidence/yanked-control-r5.sh`, whose cited log is
`review/evidence/yanked-control-r5.log`. The script recreates exactly what the round-4 audit
recreated — the pinned advisory-db commit `b50980aad8b8f14f77e25a97b32dd94bf008b0af`, an
isolated `mktemp -d` `CARGO_HOME` holding **only** a `bin/cargo-audit` symlink and deliberately
**no** `audit.toml`, so `[yanked] enabled` keeps its default `true` — and it **asserts** the
number rather than printing it for a reader to transcribe:

- the count of `couldn't check if the package is yanked` lines, taken with
  `/usr/bin/grep -cF` (the POSIX `grep` at its absolute path; a typed `grep` in an agent shell
  on this machine is `ugrep`), must be exactly **54**, and a control shows the same test
  **rejects 55**, the figure revision 4 stated, so the assertion can fail;
- the lockfile must hold 55 `[[package]]` entries and 54 `source = "registry+` keys, which is
  *why* the two figures differ;
- the 54 crate names in the error lines, sorted, must `diff` empty against the sorted names of
  the lockfile's registry-sourced packages, and the one lockfile package absent from the error
  lines must be `r69_feature_shape`.

Observed: `Loaded 1243 security advisories`, `Scanning Cargo.lock for vulnerabilities (55 crate
dependencies)`, cargo-audit `exit=0`, `yanked-error-lines (/usr/bin/grep -cF): 54`, every
assertion `OK`, script `rc=0`. The script was run three times in a row and runs 2 and 3 were
**byte-identical** to run 1, which is the cited log; absolute scratch paths are normalised to
`<pinned-advisory-db>` and `<isolated-cargo-home>` exactly as in `feature-shape-check-r4.sh`,
which is what makes that identity possible. The script sets `set -o pipefail`, asserts on
content, never writes inside this run directory (its advisory-db clone and its isolated home are
`mktemp -d` directories under `${TMPDIR:-/tmp}`, removed by an `EXIT` trap — **no nested git
repository is ever created in this tree**), and passes the repository's `shellcheck` pre-commit
hook carrying a file-level `# shellcheck disable=SC2015,SC2016,SC2329` directive that justifies
each of the three informational codes, exactly as `feature-shape-check-r4.sh` does. The
directive is a comment, so it changes no byte of the output.

**What is deliberately left byte-identical, and where the superseded figure therefore still
sits.** `review/evidence/feature-shape-check-r4.sh` is **not edited**. Its cited log
`feature-shape-check-r4.log` is the output that the round-4 audit reproduced five ways, and the
55 the finding names in that file sits in the **header comment block at lines 72-80**, not in
any assertion the script executes: no run, no exit status and no output line of that script
depends on it. Editing the file to fix a comment would invalidate a reproduction record to
correct prose, so **the r4 script's comment is left carrying the superseded figure**, and this
note is where a reader learns that. The live record of the count is
`yanked-control-r5.sh` — where the figure is asserted, not narrated.

**The two locations in the revision-4 note below were corrected in place, which is an exception
to this file's practice, and the exception is stated rather than hidden.** Revisions 4 and 3
each left the previous revision's note body **verbatim** as that revision's record, adding a
warning to its heading. Revision 5 does not do that at the two sentences the finding cites —
lines 87 and 89 of revision 4, the `prints 55 lines of` sentence and the `the log grew 55 lines`
sentence: it changes `55` to `54` in both and cites the new log, because the round-4 finding
requires the count in
`review/DECISION.md:84-90` to match the run, and a decision that carries a known-false empirical
figure in its own body — with only a later note to contradict it — is the defect being repaired,
not a record worth preserving. What revision 4 actually wrote is quoted in full in the finding
above, so nothing is lost. Every other sentence of the revision-4 note is byte-identical.

**Revision note (revision 4), retained as the record of that revision. Its two sentences
reporting the empty-`CARGO_HOME` variant's error count are the ones the round-4 audit refuted;
they are corrected in place to 54 and marked, and the revision-5 note above says why.**
Revision 4 rewrites revision 3 (sha256
`a9eec9bd3cc3631d61f395f470e0b15a389746f9e26e26a5b2b32a9fc9a7e98f`) in place. No revision of
this decision has been published, so there is still no `## Supersedes`. **Nothing about the
recommendation, the parameters or the other five checks moves.** `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency and `bacon`
3.25.0 as the dev watcher stand unchanged; the single `- owns web-extra-surface` line and the
five `- assumes` lines are byte-identical to revision 2 and revision 3; the R67 exit contract
(SIGTERM →143, SIGINT →130, drain-deadline expiry →1) and the request to R67 are unchanged;
the CLI Design Standard's R4.1 required global core is unchanged; fitness gate 1 remains
`inapplicable` under owner ruling Q7.B; the pinned advisory-database commit
`b50980aad8b8f14f77e25a97b32dd94bf008b0af` and its 1,243-advisory and 55-crate assertions are
unchanged; and the other five evidence scripts and their cited logs are untouched. Revision 4
repairs exactly one defect: **the conditions under which check 2's cited log is byte-identical
on rerun.**

Revision 3 was **rejected** by the round-3 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r3`, model `gpt-5.6-terra`, family openai) on a
single finding, quoted verbatim:

> **Reject — the repaired check is still not byte-reproducible under the decision's stated
> conditions.** Each successful rerun inserted `warning: couldn't open crates.io index: I/O
> operation failed: failed to obtain lock file '/Users/stevemorin/.cargo/.package-cache'` after
> `Loaded 1243 security advisories`; `diff -u review/evidence/feature-shape-check-r3.log
> review/evidence/audit-feature-shape-check-r3-inplace-1.log` shows this sole difference. The
> decision names a *missing* cached index as the warning condition, but the observed cause is an
> unavailable package-cache lock on a machine that has the cache. Cargo-audit 0.22.1's
> `src/auditor.rs:115-167` takes the same `CachedIndex::open` branch for `--no-fetch` and warns
> on any open failure, including a lock failure. Its stated conditions for cited-log identity
> must include a readable, unlocked cached crates.io index (or the claim must be narrowed to the
> deterministic feature-shape sections); otherwise its claim that the two named variations are
> exhaustive is false.

The finding is correct and is accepted without qualification. Revision 3's note below says, in
the sentence beginning "The residual environment dependency, named rather than claimed away",
that a **missing** cached index is the condition for that warning and that the SKIP and the
missing index are "the second and last documented way this log can vary". Both halves were
wrong: cargo-audit 0.22.1 warns on **any** `CachedIndex::open` failure, a contended
`~/.cargo/.package-cache` lock included, and that is what the auditor hit on a machine whose
index is present. The same auditor's findings 2, 3 and 4 confirmed everything else in revision
3 — the pinned-database repair, the scoped SKIP and mismatch controls, and the five unchanged
checks — and revision 4 changes none of it.

**The repair, and why this form.** The finding offered two remedies: make the warning
impossible, or narrow the byte-identity claim to the deterministic feature-shape sections and
classify the scan section's environment-dependent lines. Revision 4 takes the **first** form
for the warning, because it can be made **structurally impossible** rather than merely
classified. The new check is `review/evidence/feature-shape-check-r4.sh`; its cited log is
`review/evidence/feature-shape-check-r4.log`. It differs from `feature-shape-check-r3.sh` in
three **substantive** ways. The remaining differences a script-to-script `diff` shows are
wording and none of them touches an assertion: the rewritten header comment block, the
`# shellcheck disable=` directive reported after item 3 below, section 8's heading string
(`… PINNED advisory database, ISOLATED CARGO_HOME`) and the final summary label
(`advisory scan (section 8, pinned input, isolated CARGO_HOME): …`). The three substantive
ways:

1. **Section 8 runs `cargo audit` under an isolated `CARGO_HOME` with the yanked-crate lookup
   disabled, so the warning cannot be emitted.** The isolated home is a `mktemp -d` directory
   under `${TMPDIR:-/tmp}` containing exactly two things: an `audit.toml` holding
   `[yanked]` / `enabled = false`, and a `bin/cargo-audit` symlink to the cargo-audit binary
   already on `PATH`. Read at the published source of `cargo-audit` 0.22.1, `src/commands.rs`
   sets `CONFIG_FILE = "audit.toml"` and resolves `config_path()` to the project's
   `./.cargo/audit.toml` if it exists and otherwise to `home::cargo_home().join("audit.toml")`,
   and `home::cargo_home()` honours `$CARGO_HOME`; the probe directory has no `./.cargo`, so
   that file is the configuration this invocation loads. With `yanked.enabled` false,
   `src/auditor.rs:115-167` takes its `} else { None }` arm: **neither `CachedIndex::fetch` nor
   `CachedIndex::open` is called.** No crates.io index is read, no `.package-cache` lock is
   taken, and the warning the round-3 audit observed has no code path that can print it. The
   ambient `~/.cargo` is not consulted at all, so **neither a readable nor an unlocked cached
   crates.io index is required** to reproduce the log.
   **What that costs, stated rather than hidden:** the scan no longer reports yanked crates. A
   crate's yanked status is a **mutable** attribute of the live crates.io registry, not part of
   the pinned advisory corpus, and is exactly the kind of moving input for which revisions 2 and
   3 were rejected. No claim in this decision rests on a yanked result — gate 3 is answered on
   advisories alone, and the gate-2 "newest non-yanked version" figures come from the committed
   crates.io snapshots read by check 3, not from this scan. Yanked-crate detection against a
   current index belongs to P03's live CI.
   The repair is **asserted, not assumed**: the normalised cargo-audit output must contain
   neither `couldn't open crates.io index` nor `couldn't check if the package is yanked`, and
   must be **exactly two lines**. The line count is the assertion that catches a line nobody has
   seen yet; a string blocklist cannot. A control shows the same absence test reports a line
   that *is* present, so it can fail.
   **The variant the finding's own wording suggested was tested and rejected on evidence.** An
   isolated but *unpopulated* `CARGO_HOME` with `yanked.enabled` left at its default `true` does
   **not** print the warning: `CachedIndex::open` succeeds against a newly created empty index,
   and cargo-audit then prints **54** lines of
   `error: couldn't check if the package is yanked: not found: No such crate in crates.io index: <name>`
   — one for each of the 54 registry-sourced packages in the probe's 55-package lockfile; the
   root path package `r69_feature_shape` has no crates.io source and is not looked up. *(Revision
   4 wrote 55 here, the scan's dependency count, without re-running the variant; the round-4
   audit observed 54 and rejected it. Revision 5 re-ran the variant and asserts the count in
   `review/evidence/yanked-control-r5.sh`, cited log `yanked-control-r5.log`. See the revision-5
   note above.)*
   Asserting the warning's absence would have passed while the log grew 54 lines. Disabling the
   lookup is the form that makes the claim true by construction.
2. **One named, anchored classified line class, for a second environment dependency found while
   repairing the first.** Sections 1, 2, 5 and 7 run cargo under the **real** `CARGO_HOME` —
   they need the populated registry cache to resolve `--locked` — and capture its stderr. When
   another process holds `~/.cargo/.package-cache`, and ten agents share this worktree, cargo
   prints `Blocking waiting for file lock on package cache` (and, for the build-directory lock,
   `… on build directory`) and then proceeds normally. **This was reproduced deliberately, not
   inferred:** an exclusive `flock` was held on `~/.cargo/.package-cache` from a separate
   process while section 1's `cargo tree -e normal --locked --no-default-features` ran in the
   probe directory; the line appeared and the tree was otherwise identical. Left alone it would
   have rejected revision 4 for the same overclaim a third time, and unlike the section-8
   warning it **cannot** be made impossible. It is therefore handled by the R63 classifier
   discipline: `norm` deletes it with the single anchored pattern
   `/^[[:space:]]*Blocking waiting for file lock on /d`. **That is the only classified line
   class in this log, and it is named here, in the script's header and in a header line the log
   itself prints.** It carries no information about the feature shape; it is deleted before
   section 7's `tail -3` window is taken, so it cannot shift that window; and when no lock is
   contended nothing is deleted. Section 7's `cargo clean --quiet` and section 8's
   `cargo audit --version` now pipe their output through `norm` for the same reason — in
   revision 3 their stderr reached the log unclassified.
3. **Two sentinels and two log lines follow from the above.** `norm` also rewrites the isolated
   home's path to `<isolated-cargo-home>` (a sentinel initialised before first use, as revision
   3's `DB_DIR` was), the `EXIT` trap removes the isolated home alongside the advisory-database
   clone, the header prints the classified line class, and section 8 prints the isolated home
   and its `audit.toml`. Nothing else in the script moved: the pinned commit, the 1,243 and 55
   assertions, the advisory-count control, the `--db <clone> --no-fetch --stale` form, the
   scratch clone under `${TMPDIR:-/tmp}` that is never written inside this run directory, the
   named `SKIP: advisory-scan-skipped-pinned-db-unavailable`, the separate `rc_shape` that
   always reaches the exit code, and a pinned-hash mismatch being a FAIL and never a SKIP are
   all carried over unchanged.

**One mechanical, output-free addition, reported rather than left to a diff.** Between
revision 3's commit and revision 4's, this repository gained a `pre-commit` hook that runs
`shellcheck` over every staged `*.sh` file under `set -e`. `feature-shape-check-r3.sh` and four
of the five `review/empirical/` scripts do not pass it — each raises the same three
**informational** findings, SC2015, SC2016 and SC2329. Rather than bypass the hook,
`feature-shape-check-r4.sh` carries a file-level `# shellcheck disable=SC2015,SC2016,SC2329`
directive with a comment justifying each code: SC2015's `A && B || C` pattern is deliberate
here because `B` is an `echo` that cannot fail, SC2016's single-quoted `jq` and `awk` programs
must reach those tools unexpanded, and SC2329's `cleanup` is invoked indirectly by
`trap cleanup EXIT`. The directive is a comment: the script's output is unaffected, and the
run made before it was added `diff`s empty against the cited log made after.

`review/evidence/feature-shape-check-r3.sh` and its log `review/evidence/feature-shape-check-r3.log`
are **left byte-identical** as the record of revision 3, exactly as revision 3 left
`review/empirical/feature-shape-check.sh` and `feature-shape-check.log` as the record of
revision 1. The locations revision 4 edited are enumerated at the end of `## Empirical check`.

**Revision note (revision 3), retained as the record of that revision. Its "second and last
documented way this log can vary" claim is the claim the round-3 audit refuted; read it with
the revision-4 note above.** Revision 3 rewrites revision 2 (sha256
`9a8d825d0e204bcf6eed2185409c183ae27903ebd5614ec0245ed2a9537b8723`) in place. No revision of
this decision has been published, so there is still no `## Supersedes`. **Nothing about the
recommendation, the parameters or the other five checks moves.** `axum` 0.8.9 on `tokio`
1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency and `bacon`
3.25.0 as the dev watcher stand unchanged; the single `- owns web-extra-surface` line and the
five `- assumes` lines are byte-identical to revision 2; the R67 exit contract (SIGTERM →143,
SIGINT →130, drain-deadline expiry →1) and the request to R67 are unchanged; the CLI Design
Standard's R4.1 required global core is unchanged; fitness gate 1 remains `inapplicable` under
owner ruling Q7.B; and the other five evidence scripts and their cited logs are untouched.
Revision 3 repairs exactly one defect: **the reproducibility of check 2.**

Revision 2 was **rejected** by the round-2 empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r2`, model `gpt-5.6-terra`, family openai) on a
single finding, quoted verbatim:

> check 2 is not reproducible as claimed. feature-shape-check.sh invokes bare `cargo audit`,
> which fetches and updates the advisory database. Its recorded log says 1,243 advisories; the
> successful private-db rerun observed 1,246. The original exact rerun failed only on the
> sandbox's read-only database lock, but it likewise did not reproduce. The decision says
> checks 1, 2, 5, and 6 reproduce byte-for-byte and that all six immediate reruns had no
> differences. The check needs a fixed advisory-db input (or the decision must stop claiming
> byte-identical check-2 reproduction).

The finding is correct and is accepted without qualification. Section 8 of
`review/empirical/feature-shape-check.sh` invoked bare `cargo audit`, which fetches and
updates `~/.cargo/advisory-db`; the advisory corpus was therefore a **mutable** input and the
printed advisory count was a moving number that no rerun could be held to. The same auditor's
findings 2, 3 and 4 confirmed everything else in revision 2 — the parameter repair, R67's
quoted taxonomy and exit contract, the CLI Design Standard's R4.1 core, and gate 1's
`inapplicable` answer — and revision 3 changes none of it.

**The repair, and why this form.** The finding allowed two remedies: give the check a fixed
advisory-database input, or stop claiming byte-identical check-2 reproduction and classify the
advisory line as volatile. Revision 3 takes the **first and stronger** form, because the second
would leave the decision's gate-3 answer resting on a number nobody can reproduce, and because
the pinned corpus turns out to load exactly the 1,243 advisories this decision already cites —
the figure becomes traceable to a recorded commit instead of to one moment in time. The new
check is `review/evidence/feature-shape-check-r3.sh`. It differs from its predecessor in four
**substantive** ways:

1. **The advisory database is pinned.** Section 8 clones `RustSec/advisory-db` at commit
   `b50980aad8b8f14f77e25a97b32dd94bf008b0af` (2026-09-09) into a scratch directory under
   `${TMPDIR:-/tmp}`, **asserts** the checked-out commit hash, and runs
   `cargo audit --db <that clone> --no-fetch --stale`. The loaded-advisory count and the
   scanned-crate count are asserted as constants (`1243` and `55`), with a control assertion
   showing the count test can fail. A hash **mismatch is a FAIL, never a skip**. The clone is
   removed by an `EXIT` trap and is never written inside this run directory: no advisory
   database and no nested git repository is committed here.
2. **`--no-fetch` drops one line the revision-1 log had, and the reason is narrower than it
   looks.** The revision-1 log printed `Updating crates.io index`. That line belongs to
   cargo-audit's yanked-crate lookup, not to the advisory corpus, and `--no-fetch` does **not**
   disable that lookup: read at the published source of `cargo-audit` 0.22.1
   (`src/commands/audit.rs:222`, `config.database.fetch &= !self.no_fetch;`, and
   `src/auditor.rs:115-167`), `--no-fetch` clears `database.fetch`, which turns the
   `yanked.update_index && database.fetch` branch — the one that prints the line and calls
   `CachedIndex::fetch` — into the `else` branch, which calls `CachedIndex::open` and still
   performs the yanked comparison against whatever crates.io index is already cached. So the
   observed facts, stated as observed: the index is not refreshed, the line is absent, and the
   yanked comparison reads a cached index. No advisory result depends on any of it, so the
   gate-3 answer below is unaffected. **The residual environment dependency, named rather than
   claimed away:** on a machine with no cached crates.io index that same `else` branch prints
   `couldn't open crates.io index: …` as a warning line, which would make the log differ there.
   That is the second and last documented way this log can vary, alongside the SKIP in item 4.
3. **Absolute paths are normalised.** `cargo tree` prints the probe package's absolute path,
   and the scratch clone's path varies per run and per machine. The script rewrites the two
   probe directories to `<feature-shape>` and `<feature-shape-r01base>` and the clone to
   `<pinned-advisory-db>`, which is what lets the log reproduce from a clean
   `git archive HEAD` extraction rather than only from the author's checkout.
4. **A named, narrowly scoped SKIP.** If the pinned commit can be obtained from neither the
   network nor a local `~/.cargo/advisory-db` mirror, section 8 prints exactly
   `SKIP: advisory-scan-skipped-pinned-db-unavailable` and contributes nothing to the exit
   status. The feature-shape status is computed as a separate variable (`rc_shape`) that always
   reaches the exit code, so a skipped advisory scan **cannot** mask a failed feature-shape
   assertion. This was tested rather than assumed, and the test is described so an auditor can
   repeat it: a **scratch copy** of the committed script, produced with `sed` and with the
   single assertion `must "axum v0.8.9" "$on"` rewritten to `must "axum v9.9.9" "$on"`, was run
   with `R69_ADVISORY_DB_URL` pointed at an unreachable host and `R69_NO_LOCAL_MIRROR=1`. It
   printed `SKIP: advisory-scan-skipped-pinned-db-unavailable`, reported `rc_shape=1`, and
   exited `1`. The scratch copy was deleted; the committed script is unmodified. The other
   three branches were exercised the same way: the local-mirror fallback (unreachable remote,
   mirror allowed → `advisory-db obtained from : local-mirror`, exit 0) and a forced
   pinned-hash mismatch (→ `FAIL`, `rc_audit=1`, exit `1`, **not** a skip).

**The remaining differences between the two scripts are mechanical**, and are listed so that a
script-to-script `diff` holds no surprises: `/usr/bin/grep`, `/usr/bin/sed` and `/usr/bin/awk`
are invoked by absolute path, and the log names the grep binary, because an interactive agent
shell on this machine resolves a typed `grep` to ugrep; the two scratch files that section 4
uses are created with `mktemp` under `${TMPDIR:-/tmp}` instead of fixed `/tmp/r69-rv*.txt`
names, because ten agents share this worktree; two header lines (`grep binary:` and
`probe dir:`) were added and therefore appear in the log; the single `rc` variable became the
pair `rc_shape` / `rc_audit` that item 4 depends on, and the final three lines of the log print
both; `--stale` accompanies `--no-fetch` so that a database pinned to a fixed commit does not
start failing cargo-audit's freshness window as it ages; and the `55 crate dependencies` line
and the advisory-count control are asserted where revision 1 asserted only the exit status.

`review/empirical/feature-shape-check.sh` and its log `review/evidence/feature-shape-check.log`
are **left byte-identical** as the record of revision 1, exactly as revision 1's
`parameters-check.log` was. The check-2 row of the table under `## Empirical check` now names
the r3 script and `review/evidence/feature-shape-check-r3.log`, and the reproducibility
paragraph there states precisely what the new check establishes. Beyond the title, this note,
the heading of the retained revision-2 note below and the preamble's synthesizer line, every
other sentence of this decision is unchanged from revision 2 except the five citation and
figure locations enumerated at the end of that paragraph.

**Revision note (revision 2), retained as the record of that revision.** Revision 2 rewrote
revision 1 (sha256
`7a1257842cfe1b39befa54e6ea0c8cdd125ee1768e13e72a1463c64d49d7d2d8`) in place. No revision of
this decision has been published, so there is no `## Supersedes`. **One owned parameter value
changes**: JF-3 requires the `<app>-serve` binary to carry the CLI Design Standard's required
global core, and revision 1 fixed that binary at "no CLI flags" inside the value of
`web-extra-surface`. Changing an owned value is permitted here only because this item is not
yet owner-accepted; the registry cell for `web-extra-surface` is still the placeholder `—` and
this revision does not edit `docs/port/PARAMETERS.md`. **The recommendation does not move**:
`axum` 0.8.9 on `tokio` 1.53.1 behind an off-by-default `web` feature, `tower` 0.5.3 as a
dev-dependency, and `bacon` 3.25.0 as the dev watcher are unchanged, as are every version pin,
every exclusion, every evidence script and every cited log except the one named below.

Revision 1 was **approved** by the empirical audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-12T204004Z-d02022bf6f42-r1`, model `gpt-5.6-terra`, family openai; it
reran all six scripts, five byte-identical and the sixth differing only in a sandbox-forced
advisory-database path) and **rejected** by the judgment audit (`review/audit-fable.md`, actor
`audit-fable-2026-09-12T204004Z-d02022bf6f42-r1`, model `claude-opus-5`, family anthropic) on
three blocking findings. Revision 2 answers each:

- **JF-1** — *"the serve binary's SIGTERM exit code contradicts R67's published contract, which
  the decision cites as satisfied, and the drain-deadline failure exit carries no number"*.
  Repaired by stating the serve binary's exit integers from R67's accepted taxonomy — SIGTERM
  →143, SIGINT →130, drain-deadline expiry →1 — in `### Principles and implementation`
  (criterion 4 and the new *The serve binary's process contract* paragraph), in the validation
  strategy and in the unproven table, whose acceptance test no longer says "a zero exit". The
  catalog token for the drain-deadline branch is recorded as a **request to R67**, whose
  catalog is append-only and owned there.
- **JF-2** — *"the fit ground that ranks `actix-web` runner-up and excludes `ntex` … is stated
  as present fact but is contradicted by the decision's own acceptance criterion 1 and is
  contingent on R05, which the decision records as open"*. Repaired by qualifying both
  locations (`## Decision` alternative E and the `ntex` row in *Excluded by gate and by fit*):
  the one tokio world exists when the `web` feature is **on**, and whether the CLI and library
  join it is R05's open question.
- **JF-3** — *"the new `<app>-serve` executable is fixed at 'no CLI flags' without examining
  the CLI Design Standard's required global core, which owner ruling 2026-09-14 binds to this
  template's CLI surface"*. Repaired by giving the serve binary the standard's R4.1 required
  global core and nothing beyond it, in the owned parameter value and in the new flag-surface
  paragraph, with the standard's own scope sentences cited.

**Everything revision 2 edited beyond the three findings, enumerated rather than folded in.**
Each is a consequence of a finding, not a new position, and none moves a recommendation, a
version, an exclusion or a gate answer: (1) the title, this note and the preamble's synthesizer
line; (2) a new paragraph, *What `serve_until`'s signature must carry*, because JF-1's integers
are undeliverable through the recorded `S: Future<Output = ()>`, plus its row in the unproven
table; (3) a third new unproven row for the serve binary's global-core conformance, which
nothing in this run verified; (4) three `re-verify:` triggers — R67 dispositioning the request
below, R60 selecting the parser, and the standard revising R4.1; (5) the migration table's
`src/bin/<app>-serve.rs` row; (6) two sentences in the confidence paragraph separating these
two rules, which are quoted from normative documents, from the behavior, which is unproven;
(7) the `**Sources.**` paragraph, which now lists R67, the standard and `OWNER-REVIEW.md` as
read by revision 2 on 2026-09-15. **The owned value carries changes from two findings, not
one**: JF-3's flag surface and JF-1's exit integers both sit inside it. It records only the
integers R67 has already settled — 143, 130, I/O→1 and 0 — and deliberately leaves the
drain-deadline branch out of the value, because this revision reads it as `1` under a question
R67 owns and has not yet answered; that reading lives in the prose table below, where an R67
ruling either way corrects prose rather than staling an owned value. The only evidence change
is a **rerun** of the unmodified `review/empirical/parameters-check.sh` against the revised
file, saved as the new `review/evidence/parameters-check-r2.log`; revision 1's
`parameters-check.log` is retained unchanged as the record of revision 1.

Bundle, Deep tier. Synthesizer: fresh Claude Opus 5 context, 2026-09-13; revision 2 by a
second fresh Claude Opus 5 context that produced none of this item's raws, audits or revision
1, 2026-09-15; revision 3 by a third fresh Claude Opus 5 context that produced none of this
item's raws, audits, revisions or their audits, 2026-09-15; revision 4 by a fourth fresh
Claude Opus 5 context that produced none of this item's raws, audits, revisions or their
audits, 2026-09-15; revision 5 by a fifth fresh Claude Opus 5 context that produced none of
this item's raws, audits, revisions or their audits, 2026-09-15; revision 6 by a sixth fresh
Claude Opus 5 context that produced none of this item's raws, audits, revisions or their
audits, 2026-09-16, folding in the owner-supplied reference architecture under owner decision
11; revision 7 by a seventh fresh Claude Opus 5 context that produced none of this item's raws,
audits, revisions or their audits, 2026-09-16, repairing the round-6 judgment audit's single
finding and nothing else; revision 8 by that same revision-7 context, 2026-09-16, correcting the
two record-integrity findings of the round-7 empirical audit and nothing else; revision 9 by
the revision-6 context, 2026-09-16, adding the three owner-reference rows the brief drafter's
report found undisposed and nothing else; run
`research/runs/R69/2026-09-12T204004Z-d02022bf6f42`. This item was admitted ahead of the
Wave 0 review gate by owner decision Q3.A (2026-09-12) because it consumes only R01, which
the owner accepted on 2026-09-10, and because 19 items consume its owned parameter directly.
Five raw reports (codex, opus, and three Doxa providers) are listed under `## Engines`; every
figure, exclusion and disagreement below is attributed there.

## Decision

**Status: a proposal, to be validated in the implementation phase** (owner ruling,
2026-09-10). This is a P02 research decision, not a shipped design. P03 builds the template
and its CI proves the recommendation; the list of what P03 must validate is the unproven
table under `## Engines`. A recommendation that does not survive implementation is **revised
against this recorded research** — the raws, the alternatives comparison, the engine
disagreements and the evidence logs cited below — rather than researched again from scratch.

`rs-launch-blueprint` fills its already-decided optional web feature (ledger row F017,
`ADOPT`, not reopened here) with **`axum` on `tokio`, behind one additive, off-by-default
Cargo feature named `web`**:

| Member | Ledger row | Mechanism | Version |
|---|---|---|---|
| Web framework | F303 | `Router`, `State`, typed extractors and `IntoResponse` over `hyper` 1.x; `axum::serve` is the server | `axum` **0.8.9** (optional, default features) |
| Async runtime, listener, OS signals, drain clock | F338 | multi-thread runtime, `tokio::net::TcpListener`, `tokio::signal`, `tokio::time::timeout`, `tokio::sync::oneshot` | `tokio` **1.53.1** (optional; `rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`) |
| In-process handler test idiom | F303 (acceptance) | `tower::ServiceExt::oneshot` against the same `Router` production serves — a **`[dev-dependencies]` entry only**, not gated by `web`, because `axum` 0.8.9 already brings `tower` into the non-dev tree | `tower` **0.5.3** |
| Validated configuration and service injection | F330 | one `#[derive(Clone)] AppState` of `Arc`-held members, `axum::extract::State` with `FromRef` substates, and `build_router(state) -> Router` as the only constructor; **no lazy-load fallback** | language + `axum`, no separate crate |
| Resource registration | F331 | native `Router::merge`/`Router::nest` inside that one `build_router`; **no `ROUTERS` registry list** | language + `axum`, no separate crate |
| Optional-surface gate and target shape | F017 / F303 | one additive Cargo feature `web`, `#[cfg(feature = "web")] pub mod web;`, and `[[bin]] required-features = ["web"]` | Cargo, no crate |
| Production entrypoint and graceful shutdown | F338 | feature-gated `[[bin]]`, `#[tokio::main]`, `axum::serve(..).with_graceful_shutdown(..)`, with a settings-driven deadline whose clock starts **at the signal**, not at server start | Cargo + `tokio`, no further crate |
| Dev-serve recipe and auto-reload | F339 | Justfile `serve` recipe exporting a console-log env default and driving a headless restart loop; `serve-once` is the no-watcher fallback | `bacon` **3.25.0**, contributor-installed, **not** a Cargo dependency |

Settled ledger rows: **F303, F330, F331, F338, F339**.

**Not selected**, with the reason given under *Excluded by gate and by fit* below:
`actix-web` 4.15.0 (ranked runner-up), `poem` 3.1.12, `salvo` 0.96.0, `rocket` 0.5.1,
`warp` 0.4.3, `ntex`, `xitca-web` 0.8.3, `viz` 0.11.0, `tide`, `pavex` 0.2.10,
`loco-rs` 1.1.0, `dropshot` 0.17.1, a hand-written `hyper` loop, `axum::Extension` or a
`OnceLock` singleton for configuration, a function-pointer or link-time router registry,
`tower-http` (R75's to select), a direct `hyper` dependency (transitive through `axum`),
`signal-hook`/`ctrlc`, `systemfd` + `listenfd`, `cargo-watch` 8.5.3 and `watchexec-cli` 2.7.2.

### Principles and implementation

**Shared requirement.** The template ships an **optional** HTTP surface that is a thin adapter
over the same core library the CLI drives; it is composed by one explicit construction
function; validated configuration and the application service are available to handlers **and
to tests** through that construction; the production entrypoint runs the server and drains it
on a termination signal within a settings-driven window; and one developer command starts the
service with human-readable logs, distinct from the production structured profile.

**Source and agreement level.** `docs/port/COMMONALITY.md` rows F303/F330/F331/F338/F339 are
all `DIVERGENT`, origin `py-only`; `docs/port/DIVERGENCE-ANALYSIS.md` line 217 records
`harmonize: partly` at scope level. The level at which agreement is required is **capability**:
py, ts and rs must each be able to expose the core library over HTTP without a mirror data
model. What must **not** be harmonized is the mechanism — FastAPI's `Depends`, Hono's context
bindings and axum's `State<S>` are three ecosystem-appropriate realizations of one injection
principle, and no shared low-level value (route naming, DI shape, server library, watcher) is
recommended, because neither an explicit owner requirement nor evidence of the same tradeoff
in all three ecosystems supports one. All five engines agree on this framing.

**Essential behaviors and observable acceptance criteria.** These are requirements on P03's
template, not results of this run. Criteria 1, 3 and 5 were exercised here in the reduced,
verification-only forms described under `## Empirical check`; criteria 2, 4 and 6 were not,
and are carried in the unproven table under `## Engines`.

1. **The surface is optional and costs nothing when off.** *Observable:* with no features,
   `cargo tree -e normal` lists no `axum`, `tokio`, `hyper` or `tower`, and
   `cargo build --bins` produces no serve binary. *Verified here on a manifest probe*
   (`review/evidence/feature-shape-check-r4.log`, sections 1, 2, 6 and 7), not on a template.
2. **The web handler reaches the same erased service the CLI reaches, over the same
   serialisable type, with no mirror struct** (R01 acceptance criterion 6). *Observable:* the
   handler's return type names the library's own `Project`, and a real HTTP GET against a
   bound listener decodes into the library's `Vec<Project>`. **Not run here** — that is a
   request-path behavior, and building it would mean building the recommendation.
3. **Configuration and the service are injected by explicit construction, checked by the
   compiler.** *Observable:* `build_router(state: AppState) -> Router` is the only way to
   build the app, and a handler asking for a substate the app never registered fails to
   compile rather than returning 500 at request time. *Partly verified here:* the type-level
   half — that R01's erased service satisfies axum's declared state bound — is
   `review/evidence/state-bound-check.log`. The compile-failure demonstration for an
   unregistered substate is P03's.
4. **The production entrypoint drains in-flight work on SIGINT/SIGTERM and gives up after a
   configured deadline.** *Observable:* the serve future is bounded by a timeout whose value
   comes from settings and whose clock starts when the shutdown signal fires, and the process
   exits with R67's integer for the signal that started the drain — **143** after SIGTERM,
   **130** after SIGINT, and **1** when the deadline expires (see *The serve binary's process
   contract* below). **Not run here**; the enabling fact — that axum supplies no deadline of
   its own — was verified by reading the published source (below).
5. **The `web` feature is what CI, container and docs gates select.** *Observable:* one
   feature name gates module, binary target and tests together. *Verified here* on the
   manifest probe: `cargo metadata` reports `"required-features":["web"]` on the binary
   target and `null` on the library target.
6. **One dev command serves with console-formatted logs and restarts on a source edit.**
   **Not run** — the environment variable's name and semantics belong to R58's unpublished
   `logging-pipeline-contract`. The tool's own capabilities were verified instead
   (`review/evidence/bacon-install-check.log`).

**Landscape — the three-bin map.** *Built-in / first-party toolchain:* `std::net` plus a
hand-written HTTP loop; Cargo `[features]`, `dep:` syntax, `optional`, `[[bin]]
required-features`, `#[cfg(feature = ..)]`; the `#[test]` harness; `cargo run`. `hyper`
1.11.1 is first-party-adjacent — the reference HTTP implementation nearly every candidate
embeds — not `std`. *Established industry standard:* `axum` 0.8.9, `actix-web` 4.15.0,
`warp` 0.4.3, `rocket` 0.5.1, `poem` 3.1.12; substrate `tokio` 1.53.1, `hyper` 1.11.1,
`tower` 0.5.3, `tower-http` 0.7.1; in the dev-reload sub-field, `cargo-watch` 8.5.3 (now
archived). *Up-and-comer:* `salvo` 0.96.0, `ntex`, `xitca-web` 0.8.3, `viz` 0.11.0,
`loco-rs` 1.1.0 (built *on* axum), `pavex` 0.2.10 (compile-time framework generator),
`dropshot` 0.17.1 (Oxide Computer's API-first framework); `tide` is the field's dead end,
kept in the map as a warning rather than a candidate; in the dev-reload sub-field,
`watchexec-cli` 2.7.2, `bacon` 3.25.0, and `systemfd` 0.4.6 + `listenfd` 1.0.2. Every
shortlisted candidate comes from that map.

**Authorities, and why each counts.** (1) `rust-lang/crates.io` at commit
`3df99c214d640090ab38aad14ae9c34289b0dec0` — the Rust project's own production web service
and the only surveyed codebase with this template's exact shape (a Cargo workspace of web
service, workers and library crates, `edition = "2024"`, `license = "MIT OR Apache-2.0"`);
R01 already established it as this programme's reference implementation. (2) Maintainers'
own published `.crate` artifacts read at an exact version — the literal bytes a consumer
compiles, and the manifests the MSRV gate is read against. (3) crates.io and the GitHub REST
API as the registries of record for population figures, not for judgement. (4) RustSec plus
an executed `cargo audit` for advisories. (5) The Rust project's 2025 State of Rust Survey
results, used **only** for the general finding that compile time and resource usage remain a
top reported problem; that report publishes no web-framework breakdown, so no framework share
is claimed from it. Deliberately **not** treated as authorities: single blog posts, framework
comparison articles, and any TechEmpower composite (see *Performance* below).

**Practice evidence, with the standing shown rather than asserted.** `rust-lang/crates.io`
pins `axum = "=0.8.9"` and `tokio = "=1.53.1"` in one workspace and is run by the Rust project
itself. `apollographql/router` (Apollo's commercially shipped GraphQL router) depends on
`axum` — reported by the opus raw at commit `e7b2b32`, not re-read here.
`meilisearch/meilisearch` depends on `actix-web` 4.14.1 — reported by the opus raw at commit
`a955694`, not re-read here; it is cited as the counterweight establishing actix-web's
production standing, not as a point against axum. `qdrant/qdrant` resolves `actix-web` in its
lockfile (openai raw). `axum` itself is maintained inside the `tokio-rs` organisation
alongside `tokio`, the substrate every established candidate except `ntex`/`xitca-web` sits on.

**Architectural alternatives compared, before any crate was weighed.**

| Alternative | Shape | Verdict and reason |
|---|---|---|
| A. No framework: `hyper` + a hand-written router | `service_fn` over `hyper_util::server::conn::auto` | Rejected. It buys nothing this template needs and pushes routing, extraction and response encoding into template code that R70–R80 would each have to re-solve. It is what every candidate embeds anyway. |
| **B. Framework with a compile-checked state type** | `axum`'s `Router<S>`/`State<S>`; `build_router(state) -> Router` | **Chosen.** A missing-state wiring mistake is a type error rather than a 500 under traffic, and every test constructs state the same way production does — which is precisely what removes the need for py's lazy fallback. |
| C. Framework with a runtime type-map for state | `actix-web`'s `web::Data<T>`, or axum's own `Extension` | Rejected as the primary mechanism. actix-web's own documentation states that using `Data<T>` when route data is not set "would cause a 500 Internal Server Error" (opus raw, `actix-web-4.15.0/src/data.rs:39`). A template whose purpose is to be copied should not ship a wiring-mistake class that only appears under traffic. |
| D. Batteries-included stack | `loco-rs` 1.1.0, `pavex` 0.2.10 | Rejected. This repository *is* the template; a second opinionated template inside it would own decisions R70–R80 are already assigned. `loco-rs` is itself built on axum, so choosing axum keeps that door open for template users. |
| E. Framework with its own runtime layer | `actix-web` + `actix-rt`/`actix-server`; `ntex` | **Ranked runner-up** (`actix-web`), not chosen. It is production-proven and its `HttpServer::shutdown_timeout(sec)` is a closer literal analogue of py's `timeout_graceful_shutdown`. The layering ground, stated with its conditions: **when the `web` feature is on**, the web surface and any future async adapter live in one tokio world, and actix-web would insert `actix-rt`/`actix-server` beside it inside that same feature — `tokio` is absent from the feature-off tree by criterion 1, measured in check 2, so this is not a claim about the template's default build. **Whether the CLI and library join that world is R05's open question** (`sync-async-execution-model`, recorded open under `## Parameters`): under an async R05 they do and the ground is at its strongest; under a synchronous R05 they do not, and the ground weakens to two runtime abstractions inside the feature rather than one. The ranking does not rest on it alone — the `Data<T>` runtime failure mode in alternative C holds either way. |

**Why the chosen design preserves each principle.** Optionality is carried by a Cargo
feature, the direct analogue of py's install extra. "Thin adapter over one contract" is
carried by `AppState` holding R01's erased service unchanged and by handlers returning the
library's own `serde`-derived types. "Config available to handlers and tests" is carried by
`FromRef` substates on one `AppState`, which is stronger than py's dependency-injection graph
because it is checked at compile time. "Drain on signal" is carried by
`axum::serve(..).with_graceful_shutdown(..)` plus an explicit, settings-driven deadline.
"One dev command" is carried by a Justfile recipe.

**F330 — the requirement behind py's lazy fallback, and whether Rust needs it.** py's
`get_config` (`src/py_launch_blueprint/web/deps.py:37`, read by the opus and codex raws at
programme pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`) falls back to `load_config()` when
`request.app.state.config` is unset, for "raw ASGI callers like schemathesis that bypass the
lifespan". The requirement behind it is *every caller of the app object — production, tests,
contract fuzzers — sees a loaded configuration*. The fallback exists because in FastAPI the
app object can be constructed and called without its lifespan ever running, so the invariant
is unenforceable at construction time. In Rust with axum it is enforceable: a `Router<S>` is
not a service until `with_state` has supplied `S`, so `build_router(state)` makes a
configuration-less app unrepresentable and a fallback would be dead code hiding a wiring bug.
**The Rust template must not port the lazy fallback**; it ports the invariant instead. All
five engines reach this conclusion independently.

BASELINE-REVIEW: F330 — validated configuration is available to every caller of the app object, including tests and contract fuzzers — drop py's lazy-load fallback in the Rust template and carry the invariant in the type system instead: `build_router(state: AppState) -> Router` is the only constructor, so an app without configuration cannot be built or called; affected items: R69 (this row), R77 (`web-env-settings`, which must expose a settings value the composition root constructs, not a lazily-loadable global), R83 (`openapi-contract-fuzzing`, whose fuzzer must construct the app through the same factory tests use rather than bypassing a lifespan) — evidence: py's fallback exists because a raw-ASGI caller can skip the lifespan (`src/py_launch_blueprint/web/deps.py:37` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read by the opus and codex raws); axum 0.8.9 makes the equivalent state unrepresentable because its state-carrying `impl<S> Router<S>` block is bounded `S: Clone + Send + Sync + 'static` and `with_state` is what turns a `Router<S>` into a service (`axum-0.8.9/src/routing/mod.rs:138-141` and `:408`, read in this run at the published artifact — `review/evidence/assert-figures.log`, section G).

**F331 — native composition versus a registry list.** py registers resources by iterating a
module-level list: `for router in ROUTERS: app.include_router(router, prefix=V1_PREFIX)`. The
prompt's baseline review (2026-09-04) asks that native composition be compared before a
registry is accepted, keeping "explicit, straightforward resource registration" as the
acceptance behavior. Evidence from the reference implementation, read in this run:
`rust-lang/crates.io` composes its entire API by chained explicit calls inside one function
ending in `.with_state(state)`, with **no registry list and no registration loop**
(`src/router.rs` at `3df99c2`; asserted in `review/evidence/assert-figures.log`, section F).
In axum the native operators are `Router::merge` (same prefix) and `Router::nest` (sub-path),
and a per-resource `pub(crate) fn router() -> Router<AppState>` composes with one line at the
call site. **Recommendation: native composition in one `build_router`; no `ROUTERS`
registry.** Adding a resource stays one import plus one line, which satisfies the acceptance
behavior with less machinery than a registry, and a missing registration is visible at the
composition site rather than in a separate list. The alternatives rejected on fit: a
`const ROUTERS: &[fn() -> Router<AppState>]` slice adds indirection that buys nothing where
the composition site is already one line per resource, and a link-time registry (`inventory`,
`linkme`) makes route registration invisible in source order, which is unacceptable in a
template whose readers are learning the layout. Note for R71/R72: axum 0.8 changed
path-parameter syntax from `/:id` to `/{id}`, and the old form panics rather than silently
changing behavior (opus raw, `axum-0.8.9/CHANGELOG.md:121-122`).

BASELINE-REVIEW: F331 — resource registration is explicit and straightforward — compose per-resource `axum::Router` values with `merge`/`nest` inside one `build_router` function rather than freezing py's module-level `ROUTERS` registry list into the Rust template; affected items: R69 (this row), R71 (`openapi-generation-pipeline`, whose route/OpenAPI composition must attach to native routers rather than to a registry), R75/R78/R79 (whose layers wrap the composed router from outside) — evidence: py's list-and-loop is FastAPI-specific (`src/py_launch_blueprint/web/app.py` and `web/routers/__init__.py` at pin `b08bccfb`, read by the opus and codex raws), while `rust-lang/crates.io` registers its resources by chained explicit calls with no registry and no loop (`src/router.rs` at commit `3df99c214d640090ab38aad14ae9c34289b0dec0`, asserted in `review/evidence/assert-figures.log`). Codex, opus, openai and gemini raise this finding independently and agree on the direction.

**F338 — the entrypoint, and what graceful shutdown needs beyond the framework.** The
mechanism is `axum::serve(listener, router).with_graceful_shutdown(signal)`, with the signal
future built from `tokio::signal::ctrl_c()` and, under `#[cfg(unix)]`,
`tokio::signal::unix::signal(SignalKind::terminate())`. Both maintained references do exactly
this: axum's own `examples/graceful-shutdown/src/main.rs` at tag `axum-v0.8.9`, and
`rust-lang/crates.io`'s `src/bin/crates-io/server.rs` at `3df99c2`, which selects over SIGINT
and SIGTERM (asserted in `review/evidence/assert-figures.log`, section F). **No crate beyond
`tokio` is needed** — its `signal` feature covers both signals on both legs of
`target-os-matrix`; `signal-hook` and `ctrlc` add a dependency for something already present,
and `hyper-util`'s `GracefulShutdown` is the layer `axum::serve` exists to wrap.

**The unreleased 0.9 line lands on exactly this mechanism, which sharpens the existing
`re-verify` trigger rather than changing the recommendation** (owner-reference *Key Finding 1*
and *Recent-Bugs-vs-Plan Register*; owner decision 11, row 1). The document's factual half is
confirmed: **axum has published nothing at or above 0.9**. Its registry `max_version`,
`max_stable_version` and `newest_version` all read `0.8.9`, and the set of published versions
starting `0.9`, `1.` or `2.` is **empty** across all 94 published versions
(`review/evidence/owner-reference-check-r6.log`, section A). The **inference** the document
draws from that — "This makes a 3-year horizon on 0.8 safe", with the pending breaking changes
"concentrated in **axum-extra**" — is stated more absolutely than its source, and this item
records the source instead:

- The statement the document paraphrases as "There isn't a timeline yet" is a comment by
  `mladedav` (`author_association: COLLABORATOR`) on `tokio-rs/axum` issue **#3809**
  (*Inquiry about the release timeline and features for axum 0.9.0*, closed 2026-06-30), and
  it reads, verbatim: *"There isn't any set timeline. We'd like to do it soon, but no promises
  and it could mean pretty much anything."* The second sentence is the half the document drops,
  and it is the half that bears on a three-year horizon.
- The breaking changes are **not** confined to `axum-extra`. The `release-plz` pull request
  **#3745** (*chore: release main (0.9)*, opened 2026-05-05, **closed without being merged** —
  `merged: false`, `merged_at: null`, which is why the registry still shows no 0.9.0) proposes
  `axum`: `0.8.9 -> 0.9.0` and lists its `cargo-semver-checks` failures against
  `axum/src/serve/mod.rs`: **`function serve` (3 → 4 generic types)**, **`trait Serve` (3 → 4
  required generic types)** and **`trait WithGracefulShutdown` (4 → 5 required generic
  types)**.
- Pull request **#3819** (*Extract `axum::serve` and friends into new `axum-serve` crate*) is
  **open** in milestone **0.9**.

All four facts are asserted in `review/evidence/owner-reference-check-r6.log`, section C.
**What this changes here: nothing, and that is the finding.** `axum::serve(..)
.with_graceful_shutdown(..)` is the F338 mechanism at 0.8.9, the version this decision
recommends and the only one published; a caret requirement cannot cross into 0.9 (see
*Compatibility*); and this decision's `re-verify:` line already fires **when axum publishes
0.9**. What is added is the shape of the work that trigger implies — the migration surface is
`serve_until`'s own call site, not a peripheral crate — and a caution against reading the
document's three-year horizon as a reason to build more on that surface than F338 needs. The
claim that the repository's "highest tag is `axum-v0.8.9`" was **not** re-verified: the GitHub
tags endpoint returns an unordered page, and the registry — the authority this decision already
uses for version facts — settles the same question.

What the framework does not give you is py's `timeout_graceful_shutdown`. **axum's drain is
unbounded by construction**: after the signal it stops accepting and then awaits
`close_tx.closed()` with no deadline. This run verified that by reading the published source
rather than inferring it — `axum-0.8.9/src/serve/mod.rs` contains the
`close_tx.closed().await` and **zero** occurrences of `timeout` or `deadline`
(`review/evidence/assert-figures.log`, section G). `rust-lang/crates.io` accepts that
unbounded drain: its call site awaits `axum::serve(..).with_graceful_shutdown(..)` directly,
and the one `Duration` in that file is a metrics logging interval (same log, section F). To
mirror py's settings-driven window the template must add the deadline itself.

**The deadline's clock must start at the signal, not at server start.** This is the one place
the raws disagree on something that is simply right or wrong. The opus and perplexity raws
both wrap the whole serve future — `tokio::time::timeout(Duration::from_secs(cfg.graceful_shutdown_seconds), server)`
— which bounds the server's entire lifetime and would terminate a healthy service after the
grace period. Only the openai raw gets it right, by signalling the start of shutdown over a
channel and applying the timeout to the already-pinned server future from that moment:

```rust
pub async fn serve_until<S>(listener: TcpListener, app: Router, shutdown: S, grace: Duration)
    -> Result<(), ServeError>
where S: Future<Output = ()> + Send + 'static,
{
    let (started_tx, mut started_rx) = tokio::sync::oneshot::channel::<()>();
    let server = async move {
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { shutdown.await; let _ = started_tx.send(()); })
            .await
    };
    tokio::pin!(server);
    tokio::select! {
        result  = &mut server  => result.map_err(ServeError::Io),
        _ = &mut started_rx => tokio::time::timeout(grace, &mut server).await
            .map_err(|_| ServeError::GracefulShutdownTimedOut(grace))?.map_err(ServeError::Io),
    }
}
```

That shape has a consequence for the manifest, also verified here: it needs
`tokio::sync::oneshot`, and **tokio 1.53.1's `sync` feature is enabled by none of
`signal`, `net`, `rt-multi-thread`, `time` or `macros`** — each was read from the published
feature graph (`review/evidence/assert-figures.log`, section G). So `sync` joins the feature
list; the opus raw's list omits it. A `sync`-free alternative exists — a second independent
signal listener raced against `tokio::time::sleep(grace)` inside the outer `select!`, which
works because tokio's signal listeners are independent — and is recorded here as the
variation to take if a consumer wants the narrower feature set. Gemini's proposal to bound
shutdown with `tower_http::timeout::TimeoutLayer` is a **per-request** bound, not a drain
deadline; the two are complementary, and the per-request layer is R75's to decide (axum's own
example uses it for exactly that adjacent problem).

**A deployment datum for R77's drain-deadline default, verified at Google's own page and handed
off rather than decided here** (owner-reference *Cloud Run Runbook*, the *Graceful shutdown*
caveat; owner decision 11, row 4). This item fixes the deadline's **mechanism** — a
settings-driven `tokio::time::timeout` whose clock starts at the signal — and leaves its
**value** to R77 (`web-env-settings`), which owns the environment variable. One published
platform constraint bears on that value strongly enough to record. Google's *Container runtime
contract*, requested at `https://cloud.google.com/run/docs/container-contract` and served
HTTP 200 from `https://docs.cloud.google.com/run/docs/container-contract`, says under
*Container instance lifecycle → Shutdown*, **for services**, verbatim:

> Before shutting down an instance, Cloud Run sends a SIGTERM signal to all the containers in
> an instance, indicating the start of a 10 second period before the actual shutdown occurs, at
> which point Cloud Run sends a SIGKILL signal.

Asserted in `review/evidence/owner-reference-check-r6.log`, section E, which also asserts the
neighbouring sentence *"If the instance doesn't shut down on its own within a few seconds after
receiving SIGTERM, Cloud Run sends a SIGKILL signal for a forced termination"* — that one sits
under **For jobs**, a different surface, and is asserted alongside so the two cannot be read as
contradicting each other. **The hand-off to R77, stated as a datum and not as a default:** on
that platform a drain deadline is honoured only if it is strictly shorter than 10 seconds
**measured from SIGTERM**, because the SIGKILL is unconditional at the deadline and the process
never reaches its own exit path — so R67's 143 would never be observed. **This is precisely the
distinction the clock-start rule above makes**, which is why that rule is not a fine point: a
whole-lifetime wrapper — the shape the opus and perplexity raws propose — bounds the server's
lifetime rather than the drain, and therefore answers nothing about a window that begins at the
signal. R51 (`container-image`) is the other consumer. **Cloud Run is not adopted as a target
by this item**: `target-os-matrix` is `ubuntu-latest, macos-latest`, this template ships no
deployment, and the document's Cloud Run rows are listed among the hand-offs under
`## Engines`.

**A hazard recorded for a later WebSocket layer, verified and not acted on here**
(owner-reference *C7*, "Known Axum issue … issue #3003"). The issue exists and says what the
document says it says: `tokio-rs/axum` issue **#3003**, *Graceful Shutdown ignores Websocket
handler task*, opened 2024-10-21 against **axum 0.7.4** and still **open**, reporting that
*"The task spawned in `ws.on_upgrade` is not connected to the graceful shutdown future at
all."* (`review/evidence/owner-reference-check-r6.log`, section F). **It changes nothing in
this decision.** The `web` feature recommended here enables axum's default features, which do
**not** include `ws`; nothing in this item's scope performs a WebSocket upgrade; and
`serve_until`'s deadline behaves identically either way. The hazard is real for whoever adds
that surface — an upgraded connection's task outliving the drain is exactly what the
ten-second window above converts into a SIGKILL — and the document's mitigation (`TaskTracker`
plus `CancellationToken`, and a close frame on SIGTERM) is recorded with it as that layer's
starting point, unverified here. **This programme has no P02 item for WebSockets**; the row is
listed under `## Engines` as pending owner scoping.

**The serve binary's process contract — R67's integers, not this item's.** R67
`error-and-exit-code-contract` is published and owner-accepted (2026-09-14, at
`research/topics/67-error-and-exit-code-contract/DECISION.md`, sha256
`16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`, read 2026-09-15), its
owned `error-taxonomy-exit-codes` fixes the taxonomy `0/1/2/3/4/5/130/143` with "unlisted
failures collapse to `1`", and it names this item as bound: "R05 (`sync-async-execution-model`)
and R69 (`web-extra-surface`) decide the web surface's signal source, which must return the
same 130/143". Revision 1 asserted agreement with R67 while leaving the numbers out; they are
stated here. The entrypoint returns `ExitCode` from `main` rather than calling `process::exit`,
which is what R67 requires, and:

| Serve-binary termination | Exit | R67 catalog row |
|---|---:|---|
| Drain initiated by `SIGTERM` completes inside the deadline | **143** | `RSLB902` SIGTERM → 143 |
| Drain initiated by `SIGINT` (Ctrl-C) completes inside the deadline | **130** | `RSLB901` SIGINT → 130 |
| Drain deadline expires — `ServeError::GracefulShutdownTimedOut` | **1** | none yet; see the request below |
| Bind, accept or other `std::io` failure — `ServeError::Io` | **1** | `RSLB101` I/O → 1 |
| The server future returns without a signal (normal `axum::serve` completion) | **0** | — |

**Request to R67 — one appended catalog row, no exit integer invented.** R67's catalog is
append-only and R67 owns it, so this item does not mint a code. The drain-deadline branch is a
*failure*, not a clean signal exit: the process gave up on requests it had accepted. R67's
taxonomy therefore gives it **1** today, as an unlisted failure, and until R67 appends a row the
branch exits 1 carrying no catalog token of its own. **The request:** append one `1xx` row —
the hundreds digit is the exit code in R67's scheme, so a `1xx` token implies exit 1 and
nothing else — for *graceful-shutdown drain deadline exceeded*; the next free slot in that block
appears to be `RSLB105` (`RSLB101`–`RSLB104` are taken), but the token is R67's to assign.
**One question travels with the request**: R67's boundary precedence is *signal → broken pipe →
domain error → unexpected*, which could instead be read as making any SIGTERM-initiated
termination 143 even when the drain failed. This item reads the timed-out drain as a domain
failure, because the observable outcome differs from a clean drain and R51's container image and
the template's process tests consume that difference; R67 owns the final reading. This is not a
`CONFLICT:` line — R67 is not on this item's `- consumes:` line, and nothing here diverges from
its published value — and not a `BASELINE-REVIEW:` line, because no py/ts baseline behavior is
at issue.

**What `serve_until`'s signature must carry, which the recorded shape does not.** The snippet
above takes `S: Future<Output = ()>`, a signal future that has forgotten *which* signal fired —
so as drawn it cannot deliver 130 versus 143. This is the same defect R67 excluded `ctrlc` for:
"the handler specified by `set_handler()` will be executed for `SIGINT`, `SIGTERM` and `SIGHUP`
… `ctrlc` therefore *cannot* produce distinct 130/143". The way out is already in this
decision's F338 mechanism rather than in a new dependency: `tokio::signal::ctrl_c()` and
`tokio::signal::unix::signal(SignalKind::terminate())` are two separate sources selected over —
the shape the reference implementation uses, asserted in check 3 as "selects over SIGTERM via
`tokio::signal::unix`" — so the `select!` inside `shutdown_signal()` can report which arm fired.
P03 threads that answer out: the future resolves to the signal kind, or directly to R67's `Exit`
value, rather than to `()`. **No check in this run exercised that**, and the row is carried in
the unproven table below. The snippet is retained unedited because it is the drain *shape* this
decision settles, and the clock-start rule it demonstrates is unaffected by what the future
carries.

**The serve binary's flag surface, under the binding CLI Design Standard.** Revision 1 fixed the
binary at "no CLI flags", copying py's `__main__.py`, which is the inherited-mechanism move the
research mandate asks to be justified rather than ported. Owner ruling 2026-09-14
(`docs/port/OWNER-REVIEW.md`, *"the CLI Design Standard binds, and OV-01 is refused"*) makes
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` v1.4.14 govern this template; its
header reads "Applies to: All new CLIs, any language" and its R4.1 opens "Every CLI **MUST**
implement the **required global core**". A second shipped executable is such a CLI, and the
standard offers it no exemption: its only profile relaxation, Appendix A's Small-CLI
(verb-first) profile — which `<app>-serve` would otherwise fit, being a single-purpose tool with
no resource nouns — states that under it "every other rule in Part III applies unchanged …
standard options (§4)". **So `<app>-serve` carries R4.1's required global core, and nothing
beyond it:**

| Option | Short | Meaning, per R4.1 | Who binds its behavior |
|---|---|---|---|
| `--help` | `-h` | print help for the binary and exit `0`, on stdout (R7.5, R7.1) | the standard; help layout is R60's parser |
| `--version` | `-V` | print version and exit `0`, on stdout — the single line `<app>-serve <semver>` per R4.6 and the owner's 2026-09-14 refusal of OV-01 | the standard; R60 |
| `--verbose` | `-v` | increase diagnostic detail, repeatable (R4.4) | R58's `logging-pipeline-contract` binds what the levels select |
| `--quiet` | `-q` | suppress non-essential stderr output; never suppresses stdout (R4.4) | R58 |
| `--config` | — | path to a config file, overriding discovery (R5.2) | R54's `config-discovery-tiers` and R77's `web-env-settings` |
| `--debug` | — | maximum diagnostics including internal detail (R4.4) | R58 |

Everything else stays out. The result-output tier (`-o`/`--output`, `--json`) is not required:
R4.1 scopes it to "commands that emit formatted result data", and this binary's stdout carries
no result set — it serves HTTP and logs to stderr. No safety/action option applies: it creates,
deletes and confirms nothing. Every *service* knob — host, port, log format, drain deadline —
remains an environment variable, as py's `__main__.py` has it and as R77 will name them; the
standard's R5.1 precedence (flag > env > config > default) is satisfied vacuously where no flag
exists for a knob. This adds **no crate to the `web` feature**. Revision 6 put that on a
condition — *"on a condition rather than as a present fact: the parser is R60's open choice, and
whichever crate R60 selects for the CLI binary is a non-optional dependency of the package"* —
and **that wording is superseded by the owner's acceptance of R60**: `docs/port/OWNER-ACCEPTANCES.md`
records R60 revision 7, sha256
`67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2`, accepted on **2026-09-15**
as "W0-R60 option A; `clap` 4.6.6 derive, `clap_complete` 4.6.9, dependency-free `build.rs`",
with first publication pending. So the parser is **selected, and unpublished as yet**, not open:
`clap` 4.6.6 with its `derive` API is a non-optional dependency of the package for the CLI
binary, and the serve binary parses R4.1's core with it instead of introducing one. The design
consequence is the one revision 6 stated, and the accepted answer strengthens rather than
weakens it. Check 2's measured 12 → 52 package delta stands unchanged **by construction,
not by re-measurement** — a non-optional dependency appears in both counts, so it cancels out
of the delta that is the feature's marginal cost. The CLI binary keeps its own flags. A `serve` subcommand on the existing
CLI binary is the ranked runner-up shape, rejected as primary because it would put `tokio` and
`axum` in the default CLI build unless the subcommand were itself feature-gated, and because
py's separate entry point is the shape R51's container image expects.

**F339 — the dev-server recipe, and what the owner's licence ruling changed.** py's recipe
(`Justfile:291`, pin `b08bccfb`) runs uvicorn with `--reload` after defaulting
`<APP>_WEB_LOG_FORMAT` to `console`. Two halves: a console-log default distinct from the
production structured profile, and auto-reload. The console half ports cleanly — one exported
environment variable whose name and semantics belong to R58 and R77, not to this item.

The auto-reload half is where the raws disagreed and where **owner ruling Q7.B of 2026-09-12
changes the answer**. Four of the five raws excluded `bacon` on fitness gate 1 because it is
`AGPL-3.0`; the opus raw then demoted auto-reload from a required recipe to an optional one
explicitly *because every surviving candidate failed a gate*. Gate 1 is struck. Re-evaluating
on the surviving grounds only:

| Candidate | Newest non-yanked | Declared `rust-version` (gate 2) | Maintenance | Outcome |
|---|---|---|---|---|
| `cargo-watch` | 8.5.3 (2024-10-02) | 1.75.0 — passes | repository `archived: true`, `pushed_at` 2025-01-14, and the README at tag `v8.5.3` says it "is on life support: it will not receive further updates … I recommend Bacon or Watchexec instead" | **Excluded on maintenance** — a maintainer's own end-of-life notice is `dormant` under the rubric. This ground survives the ruling. |
| `watchexec-cli` | 2.7.2 (2026-09-06) | **none declared** — fails | `archived: false`, `pushed_at` 2026-09-07 | **Excluded by gate 2**, under the strict reading settled 2026-09-11. This ground survives the ruling. |
| **`bacon`** | **3.25.0 (2026-08-23)** | **1.85 — passes** | `archived: false`, `pushed_at` 2026-09-12, 47 open issues, median 0.02 days to first maintainer response over the 10 most recently opened issues with 3 unanswered | **Selected.** Its only recorded exclusion was gate 1, which is now inapplicable. |
| `systemfd` + `listenfd` | 0.4.6 / 1.0.2 | 1.64.0 / **none declared** | `stable-quiet` | Not needed. Socket hand-off preserves connections across a restart, which is not a behavior F339 asks for, and `listenfd` would have to be linked into the shipped binary. |

So **auto-reload is restored to the required recipe, with `bacon` 3.25.0 as the named
watcher.** The opus raw's `BASELINE-REVIEW: F339` line — which proposed demoting auto-reload
to an optional recipe — is **withdrawn**; its premise no longer holds and F339 now ports at
capability level with no baseline change. This is the one recommendation in this item that
the licence ruling changed; everything else is unaffected.

Four capabilities of the tool were verified rather than assumed, because a TUI-first runner is
not obviously able to serve a long-running process with plain console logs
(`review/evidence/bacon-install-check.log` and `assert-figures.log`, section G):

- **A `run-long` job exists in the shipped defaults**, with `on_change_strategy =
  "kill_then_restart"`, `background = false` and `need_stdout = true`. `bacon --list-jobs` in
  a directory with no `bacon.toml` lists it, so reaching it needs no project configuration.
- **`--headless` streams the child's own output to the terminal**, not into a TUI pane:
  `CommandStream::StdOut => print!(..)`, `StdErr => eprint!(..)` in `src/tui/app.rs`. That is
  what makes the console half of F339 hold.
- **`--features` is plumbed through to the cargo command** (`src/mission.rs`), and arguments
  after `--` are appended to the job's command tokens, so the recipe needs no custom job
  definition to select the feature and the binary.
- **`-j run-long` still selects the job under `--headless`.** This needed checking rather than
  assuming, because bacon's own `--help` describes `--headless` as running "the default job on
  change" — had that been literal, the recipe would have looped `cargo check` and never started
  the server. Read at source: `-j` is stored as `settings.arg_job`, the initial job is
  `settings.arg_job` falling back to `default_job` (`src/jobs/job_stack.rs`), and every one of
  the four `headless` references in `src/cli/mod.rs` guards the alternate-screen setup, none of
  them job selection. No `default_job` override is required in the template's `bacon.toml`.
- **The default job interruption on Unix is `SIGKILL`** (bacon's own configuration reference).
  A SIGKILL restart cannot exercise the production drain path, and it kills the `cargo`
  process rather than the server it spawned. **The template must therefore ship a small
  `bacon.toml` overriding `run-long`'s `kill`** so a dev restart runs the same SIGTERM drain
  the container does. The opus raw's migration list states that no `bacon.toml` is needed;
  that is wrong on this point, and the correction is recorded here.

**The owner-supplied document agrees on the tool and this item's finding is the stronger one**
(owner-reference *C14*, "bacon (or cargo-watch) for reload … bacon better UX"; owner decision
11, row 3). The document's stack table picks `bacon` over `cargo-watch` on developer
experience. This decision reaches the same pick on a different and harder ground — gate 2 plus
`cargo-watch`'s own end-of-life notice at tag `v8.5.3`, with gate 1 struck by owner ruling
Q7.B — so agreement is recorded and nothing moves. **What the document does not carry is the
SIGKILL finding above**, which is the one fact that makes the recommendation usable: a `bacon`
recipe without the `bacon.toml` `kill` override never exercises the production drain path, and
the document's C14 row prescribes no `bacon.toml` at all. The override stands as recorded, and
its unproven row in the table under `## Engines` is unchanged. **Two of that row's three tools
are hand-offs, not this item's:** `cargo-chef` is a Docker dependency-layer cache and belongs
to **R51** (`container-image`); `mold`/`lld` is a linker selection that reaches the release
build and belongs to **R68** (`release-binary-artifacts`), with R42's published
`package-manager-invocation` governing how either is invoked. Neither is researched here and
neither is recommended or excluded by this item. The document's fourth C14 element, pinning the
toolchain with `rust-toolchain.toml`, is `msrv-policy`'s and R42's territory and is likewise
not decided here.

Recommended recipes, following R42's published `package-manager-invocation` (bare executables
resolved on PATH, no provisioner prefix; presence tested with `command -v bacon`, the rule
that parameter sets for a tool installed from crates.io):

```just
# Serve with dev-friendly console logs, restarting on source changes.
# Requires `bacon` on PATH: cargo install bacon --version 3.25.0 --locked
serve host="127.0.0.1" port="8000":
    #!/usr/bin/env bash
    set -euo pipefail
    command -v bacon >/dev/null || { echo "bacon not found: cargo install bacon --locked" >&2; exit 1; }
    export <APP>_WEB_HOST="{{host}}" <APP>_WEB_PORT="{{port}}"
    export <APP>_WEB_LOG_FORMAT="${<APP>_WEB_LOG_FORMAT:-console}"   # names owned by R58/R77
    exec bacon --headless -j run-long --features web -- --bin <app>-serve

# Same service, no watcher and no extra tool. The escape hatch.
serve-once host="127.0.0.1" port="8000":
    #!/usr/bin/env bash
    set -euo pipefail
    export <APP>_WEB_HOST="{{host}}" <APP>_WEB_PORT="{{port}}"
    export <APP>_WEB_LOG_FORMAT="${<APP>_WEB_LOG_FORMAT:-console}"
    exec cargo run --features web --bin <app>-serve
```

**The tradeoff stated plainly.** py's watcher arrives with the `web` install extra; Cargo
cannot install binary tools as dependencies, so `bacon` is one `cargo install` per
contributor and `serve-once` exists for anyone who has not run it. Against that, the reload
benefit is structurally smaller in Rust than in Python: uvicorn's `--reload` re-imports
modules in well under a second, while the Rust loop is a full incremental rebuild and process
restart — the opus raw measured 9.28 s wall / 25.61 s user CPU for a *clean* debug build with
the web feature, a figure this run did not re-measure and carries as engine-reported.
**Ranked runner-up: `watchexec-cli` 2.7.2**, which sends `TERM` with a bounded stop timeout
out of the box (`--restart --stop-signal TERM --stop-timeout 20s`, openai's recipe) and so
needs no kill override; it becomes the recommendation the moment it declares a
`rust-version`, and that is a re-verify trigger below.

**Minimal realistic endpoint at the R01 boundary.** The handler names R01's types and nothing
of its own; the error envelope is R70's, the middleware ordering R75's, the trace and metrics
layers R78's and R79's, and none is preselected here.

**The error contract is R70's, and revision 6 hands it one open question rather than answering
it** (owner-reference *C4*, "One `AppError` enum (`thiserror`) implementing `IntoResponse` …
RFC 9457 Problem Details JSON (`type`/`title`/`status`/`detail`/`errors`)"; owner decision 11,
row 7). **This item decides nothing about it** — `WebError` above is a placeholder naming
R70's type, and owner decision 11 rules that rows belonging to other items are recorded as
hand-offs, not decided. What is recorded for **R70** (`http-problem-envelope`) is the one
tension a later reader would otherwise have to discover: the owner-supplied document proposes
RFC 9457 Problem Details for the HTTP body, while **R67 is published and owner-accepted
(2026-09-14) and its owned `error-taxonomy-exit-codes` fixes a different envelope shape** — a
single JSON object `{"error":{"code","message","hint"?}}` with `hint` omitted rather than
`null` when absent. The two are not in conflict as they stand, because **R67's envelope is the
CLI process's stderr contract, not an HTTP response body**, and R67 states that it "defines
exactly those three keys and defines no trace, cause-array or diagnostic field" while R7.8
permits documented additions owned by the item that needs them. **R70's question, stated so it
is not lost:** whether the HTTP surface mirrors R67's three keys, adopts RFC 9457's member
names, or carries both — and, if RFC 9457, how `code` survives, since a stable catalog token is
what R67's `RSLB` rows exist to provide. Nothing here constrains that answer; the owner
document is an input to it under owner decision 11, which places C4 in R70's overlap set.

```rust
#[derive(Clone)]
pub struct AppState {
    pub config:   Arc<WebConfig>,                 // the typed settings struct is R77's
    pub projects: Arc<ErasedProjectsService>,     // R01's erased service, unchanged
}
impl FromRef<AppState> for Arc<WebConfig>             { fn from_ref(s: &AppState) -> Self { s.config.clone() } }
impl FromRef<AppState> for Arc<ErasedProjectsService> { fn from_ref(s: &AppState) -> Self { s.projects.clone() } }

async fn list_projects(
    State(svc): State<Arc<ErasedProjectsService>>,
    Query(q):   Query<ProjectQuery>,              // the library's own serde type
) -> Result<Json<Vec<Project>>, WebError> { /* WebError's envelope is R70's */ }

pub fn build_router(state: AppState) -> Router {
    Router::new()
        .nest("/v1", projects::router())          // native composition, no registry
        .merge(ops::router())                     // /healthz now; /readyz is R80's
        .with_state(state)
}
```

**Coupling to R01 — the highest-consequence claim in this item, verified here.** The opus raw
asserts there is no conflict with R01 because the erased service satisfies axum's state bound
**without `ProjectsService` deriving a clone trait**. That is the exact failure mode that
would force a published, owner-accepted decision to be reopened, so it was re-verified rather
than accepted, in two independent halves (`## Empirical check`, check 1). **The claim holds.**
axum's state-carrying `impl<S> Router<S>` block is bounded `S: Clone + Send + Sync + 'static`
— read at the published artifact — and R01's `ProjectsService<Arc<dyn ProjectsPort>>`,
holding a port whose supertraits are `Send + Sync`, satisfies that bound once wrapped in an
`Arc`, because `Arc<T>` is unconditionally `Clone`. Two negative twins show what each half
does: storing the service **by value** fails with ``the trait `Clone` is not implemented for
`ProjectsService<Arc<(dyn ProjectsPort + 'static)>>` ``, and removing R01's `Send + Sync`
supertraits from the port fails with ``the trait `Sync` is not implemented for `(dyn
ProjectsPort + 'static)` ``. **No `CONFLICT:` line is raised and R01's published value is
unchanged.** If P03 prefers to store the service by value it must add `#[derive(Clone)]` to
`ProjectsService<P>`, which imposes a `P: Clone` bound that library consumers would inherit;
that is a P03 implementation choice, not a change to the parameter.

**Performance, and the limits on what can be said.** No comparative throughput figure is used
anywhere in this decision. The HIGH question asks for a comparison with representative JSON
handling, validation, trace instrumentation and metrics all enabled; no public benchmark
measures that, and the opus raw records that the TechEmpower results payload could not be
retrieved on 2026-09-12 (HTTP 404 at the path the site bundle references;
`tfb-status.techempower.com` timed out after 20 s). TechEmpower's Rust entries are in any case
hand-tuned implementations written for the benchmark rather than idiomatic instrumented
services, and every candidate here except `ntex`/`xitca-web` sits on the same `tokio` + `hyper`
I/O path, so a composite ranking would not discriminate between them on this template's
workload — where a single upstream call through R01's port dominates any framework overhead.
`actix-web` replaces `axum` only if a measured, instrumented workload shows a material p99,
CPU or RSS advantage; openai's raw specifies that benchmark in full and it is carried as an
unproven item below. The costs this template actually pays are dependency count, compile time
and binary size; the dependency-count figure is measured here, the compile-time and
binary-size figures are engine-reported and carried as unproven.

**Cross-repo adjudication** (changes to py and ts are a follow-on project; this supplies their
rationale). The principle "one core library, optionally exposed over HTTP by a thin adapter
that emits the library's own types" is a capability-level agreement. py realizes it with
FastAPI + uvicorn; rs realizes it with axum + tokio; ts realizes it **not at all** —
`TS_PORT_DECISIONS.md` records no web-service decision, and the pinned ts snapshot
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` contains no web or HTTP-server code, dependency or
test (`docs/port/areas/web-service.md`, row F303; taken from the repository's own analysis,
not re-derived — no claim here depends on ts source). Per the owner's 2026-09-04 clarification
Hono was chosen for TypeScript on ecosystem merits, which is a direction rather than an
implementation in that snapshot. **Adjudication: ts's missing web tier is an absent
capability, not a justified ecosystem difference** — nothing about TypeScript prevents a Hono
adapter over the existing `CliDeps`-injected core, and the owner has already named the
framework. Proposed follow-on, not this item's to execute: ts gains a Hono adapter exposing
the same core contract behind an optional entry point, preserving F018 at capability level.
The gemini raw additionally surveyed `rspc` as a Rust analogue of tRPC and rejected it because
its primary maintainer stepped back in late 2025 declaring the project largely unmaintained;
that conclusion is adopted — a REST surface with OpenAPI generation (R71's to select) keeps
the typed client contract without depending on an unmaintained RPC framework.

**Excluded by gate and by fit.** Fitness gates were answered per candidate before popularity
was weighed. **Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`, for every candidate in this item,
and no candidate is excluded on it.** Licences are still reported as facts because they are
part of each crate's published metadata. Gate 2 figures below are the newest non-yanked
version's declared `rust_version`, read from `https://crates.io/api/v1/crates/<name>/versions`
and asserted in `review/evidence/assert-figures.log`, section C; the floor is **1.96** (stable
1.98.x minus two minors).

| Candidate | Newest non-yanked | Licence (reported, not gated) | Gate 2: `rust-version` | Outcome |
|---|---|---|---|---|
| `axum` | 0.8.9 (2026-04-14) | MIT | 1.80 — pass | **Selected** |
| `tokio` | 1.53.1 (2026-07-20) | MIT | 1.71 — pass | **Selected** |
| `tower` | 0.5.3 (2026-01-12) | MIT | 1.64.0 — pass | **Selected** (dev-dependency) |
| `actix-web` | 4.15.0 (2026-08-21) | MIT OR Apache-2.0 | 1.88 — pass | Ranked runner-up; excluded on fit (its own runtime layer between the template and tokio; `Data<T>`'s runtime failure mode) |
| `poem` | 3.1.12 (2025-07-28) | MIT OR Apache-2.0 | 1.85 — pass | Excluded on **maintenance**: a 13-month release gap, and the opus raw found no maintainer response in any of its 10 most recently opened issues (window 2025-12-16 → 2026-09-09) — a concrete `at-risk` signal |
| `salvo` | 0.96.0 (2026-08-27) | Apache-2.0 | 1.94 — passes today | Excluded on **MSRV-policy fit**: two minors of headroom against the 1.96 floor; a project tracking the compiler that closely can push a patch release past the floor between the template's minor releases. Same reasoning R01 applied to `shaku`. |
| `rocket` | 0.5.1 (2024-05-23) | MIT OR Apache-2.0 | **1.64** — pass | Excluded on **maintenance**: last release 28 months ago, `pushed_at` 2025-12-28. (Settles a raw disagreement: gemini reported MSRV 1.89.0, opus 1.64; the registry says 1.64.) |
| `warp` | 0.4.3 (2026-05-04) | MIT | **none declared — FAIL** | **Excluded by gate 2** |
| `viz` | 0.11.0 (2025-11-17) | MIT | **none declared — FAIL** | **Excluded by gate 2** |
| `pavex` | 0.2.10 (2025-11-10) | Apache-2.0 | **none declared — FAIL** | **Excluded by gate 2** |
| `tide` | 0.17.0-beta.1 (2021-12-06) | MIT OR Apache-2.0 | **none declared — FAIL** | **Excluded by gate 2**, and dormant on its own (no release in 4+ years) |
| `xitca-web` | 0.8.3 (2026-08-29) | Apache-2.0 | **1.98 — FAIL**, equals current stable, above the 1.96 floor | **Excluded by gate 2** |
| `ntex` | 4.0.0-beta.10 (2026-09-12) | MIT OR Apache-2.0 | 1.95 — passes today | Excluded on **fit and maturity**: its own `ntex-rt` runtime abstraction is a second runtime story inside the `web` feature, beside the tokio one the web surface already needs — carrying the same two conditions as alternative E above, that the tokio world exists only when the feature is on and that whether the CLI and library join it is R05's open question — and the newest non-yanked release is a prerelease |
| `loco-rs` | 1.1.0 (2026-08-16) | Apache-2.0 | 1.94 | Not a competitor: it is built **on** axum, so selecting axum keeps it available to template users without importing its opinions |
| `dropshot` | 0.17.1 (2026-06-02) | Apache-2.0 | 1.85 | Well-engineered and single-org; its first-class OpenAPI generation is relevant to R71 but does not outweigh axum's adoption or the ecosystem R70–R80 will draw on |

Gates 3–6 for the two selected compiled members, answered from the published artifacts and
this run's executed checks:

- **Gate 3 (advisories and `unsafe` posture).** `https://rustsec.org/packages/axum.html`,
  `/tower.html`, `/bacon.html` and `/watchexec-cli.html` return HTTP 404, which RustSec serves
  for a crate with no advisory. `tokio` and `hyper` have pages listing **historic** advisories
  only (`RUSTSEC-2025-0023`, `-2023-0005`, `-2023-0001`, `-2021-0124`, `-2021-0072` for tokio;
  `RUSTSEC-2022-0022` and older for hyper), none of which applies to a recommended version.
  The decisive check is executed rather than read: `cargo audit` 0.22.1 against the probe's
  resolved `--features web` lockfile, over an advisory database **pinned** at
  `RustSec/advisory-db` commit `b50980aad8b8f14f77e25a97b32dd94bf008b0af`, loaded 1,243
  advisories, scanned 55 crate dependencies and exited 0 with no findings. The pin is what
  makes that figure reproducible; revision 2 reported the same number from an unpinned fetch
  and was rejected for it (see the revision note).
  `axum` declares `[lints.rust] unsafe_code = "forbid"` and its `src/` contains **zero**
  occurrences of `unsafe` (both asserted). `tokio` uses `unsafe` pervasively and by design —
  the opus raw counted 1,066 occurrences in the published 1.53.1 `src/`, a figure this run did
  not recount — which is inherent to a runtime and is why the template's own `unsafe` policy
  (R06) applies to template code, not to this dependency.
- **Gate 4 (ubuntu + macOS).** `tokio`'s CI at tag `tokio-1.53.1` covers `ubuntu-latest`,
  `macos-latest` and `windows-latest` — **pass**. `axum`'s CI at tag `axum-v0.8.9` runs on
  `ubuntu-24.04` **only, with no macOS runner** — a gap, closed **for this version and this
  host only** by this run resolving and building `axum` 0.8.9 with `tokio` 1.53.1 on
  macOS 26.4 aarch64 at rustc 1.98.0. The template's own CI on `ubuntu-latest, macos-latest`
  re-establishes it continuously. `bacon`'s CI is `ubuntu-latest` only and its v3.25.0 GitHub
  release carries **no binary assets**, so its macOS support was closed the same way: an
  executed `cargo install bacon --version 3.25.0 --locked` on this host, exit 0, with the
  installed binary reporting `bacon 3.25.0`.
- **Gate 5 (default features and async-runtime coupling).** `axum`'s defaults are
  `form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing`, and
  `axum::serve` exists only with the `tokio` feature plus `http1` or `http2` — both read from
  the published artifact. It couples to tokio and to nothing else. `tokio`'s `default = []`,
  so every feature is opted into explicitly.
- **Gate 6 (binary-size and compile-time cost).** Measured here as **dependency count**: with
  the base set to R01's published members (`serde` 1.0.229 + `serde_json` 1.0.151), the
  non-dev tree goes from **12 packages to 52** when `--features web` is on, and with the
  feature off no `axum`, `tokio`, `hyper` or `tower` appears in the tree and no serve binary is
  produced. Wall-clock build time and binary size are **not** measured here — measuring them
  honestly means building the recommendation — and the opus raw's figures (clean debug build
  5.69 s → 9.28 s wall, 7.12 s → 25.61 s user CPU; release serve binary 2,001,600 bytes,
  1,574,392 stripped) are carried as engine-reported and unproven.

**Compatibility — proof the members work together.** Three ways, two of them by direct
observation in this run. (1) **A shared adopter at the exact recommended versions:**
`rust-lang/crates.io` at commit `3df99c2` pins `axum = "=0.8.9"` and `tokio = "=1.53.1"` in one
workspace under `edition = "2024"` and `MIT OR Apache-2.0` — the same two fixed parameters this
template carries — composes routes natively, injects one `AppState` via `with_state`, and
serves with `axum::serve(..).with_graceful_shutdown(..)` over SIGINT and SIGTERM. Every member
of this stack except the dev-serve recipe is exercised together in that one production
service. (2) **An executed resolution probe:** a manifest declaring exactly the recommended
feature, dependencies and feature sets resolved under `edition = "2024"` and
`rust-version = "1.96"` with the MSRV-aware resolver (`Locking 54 packages to latest Rust 1.96
compatible versions`); the highest declared `rust-version` anywhere in the resolved non-dev
tree is `axum`'s own **1.80**, 16 minors inside the floor, and `cargo audit` cleared it.
(3) **A version matrix would be misleading here**: `axum` 0.8.9 pulls `tokio` through its own
`tokio` feature and depends on `hyper` and `hyper-util` directly, so the pairing is expressed
by the resolver rather than by independent choices. The one cross-member constraint worth
stating is the `axum::serve` cfg above. `bacon` sits outside that compiled graph entirely: it
is a process wrapper with no Rust ABI or dependency-resolution relationship to the service.

**The requirement operator, which the owner-supplied document raises and this item does not
adopt** (owner-reference *Recent-Bugs-vs-Plan Register*, "pin `axum = "=0.8.9"`,
`axum-extra = "=0.12.6"`"; owner decision 11, row 1). The `rust-lang/crates.io` pins quoted
above are an **application** convention — that repository ships a service with a committed
`Cargo.lock`, so an `=` requirement costs it nothing and documents an exactly reproduced build.
This template is the opposite case: it is a repository people copy, and a requirement it ships
travels into their manifests. Three facts decide it, the first read at a primary source and
asserted in `review/evidence/owner-reference-check-r6.log`, section B:

- **A bare requirement is already caret-bounded, so the document's stated reason is already
  satisfied.** The Cargo Book's *Version requirement syntax* gives `0.2.3 := >=0.2.3, <0.3.0`,
  states that "Caret requirements are the default version requirement strategy", and that
  "Leaving off the caret is a simplified equivalent syntax to using caret requirements". A
  manifest reading `axum = { version = "0.8.9", … }` therefore means `>=0.8.9, <0.9.0` and
  **cannot** resolve to 0.9 when 0.9 is published. The document's mitigation buys nothing
  against 0.9 that the default already gives.
- **What `=` would additionally cost is real.** It blocks 0.8.10 and every later 0.8 patch,
  including a security patch, until a template release moves the literal; and in a consumer's
  tree it conflicts with any other crate requiring a later 0.8.x — `axum-test` 21.1.0 already
  declares `^0.8.9`, and a future `^0.8.10` would be unsatisfiable beside `=0.8.9`.
- **Nothing in this decision's owned value or migration table states an operator**, so this is
  a ground recorded for P03 rather than a change: the owned parameter says "axum 0.8.9 optional
  and its default features on", the `Cargo.toml` migration row says "optional `axum` 0.8.9
  (defaults on)", and both render as Cargo's default caret requirement. **The owned value is
  byte-identical to revisions 2 through 5.** Reproducibility comes from the committed
  `Cargo.lock` and `--locked` in CI, which is where this programme already puts it.

**Migration implications** (file-level; crate placement is R02's, and `<app>` is R49's
`build-tool-output-shape`):

| File | Change |
|---|---|
| `Cargo.toml` | `[features] web = ["dep:axum", "dep:tokio"]`; optional `axum` 0.8.9 (defaults on) and `tokio` 1.53.1 (`rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`); `tower` 0.5.3 under `[dev-dependencies]`; `[[bin]] name = "<app>-serve", required-features = ["web"]` |
| `src/lib.rs` | one line: `#[cfg(feature = "web")] pub mod web;` |
| `src/web/mod.rs` (new) | `AppState` and its `FromRef` impls, `build_router(state) -> Router`, `shutdown_signal()`, `serve_until(..)` |
| `src/web/routes/projects.rs` (new) | `pub(crate) fn router() -> Router<AppState>` and the handlers, returning the library's own contract types |
| `src/web/routes/ops.rs` (new) | `/healthz` now; `/readyz` and its payload are R80's |
| `src/bin/<app>-serve.rs` (new) | `#[tokio::main] async fn main() -> ExitCode` — R4.1's required global core parsed with the parser crate R60 selects for the CLI binary (non-optional whichever crate that is, so the feature adds none), then settings, R01's composition root, bind, `serve_until`, and R67's exit integers (143 / 130 / 1 / 0) |
| `tests/web_api.rs` (new) | file-level `#![cfg(feature = "web")]`; the `oneshot` and real-listener tests |
| `Justfile` | `serve` (bacon-driven, required) and `serve-once` (no watcher) |
| `bacon.toml` (new) | one override on the `run-long` job's `kill`, so a dev restart sends SIGTERM and the production drain path runs; without it bacon's default Unix interruption is SIGKILL |
| dev-tool list | `bacon` 3.25.0, acquired from crates.io, presence tested with `command -v bacon` per R42 |
| `.github/workflows/ci.yml` | a `--features web` axis and a `--no-default-features` build — shape owned by R11 |

Not created by this item: `problems.rs` (R70), `openapi.rs` (R71), `pagination.rs` (R72),
`idempotency.rs` (R73), `rate_limit.rs` (R74), `middleware.rs` (R75), `cors.rs` (R76),
`settings.rs` (R77), `telemetry.rs` (R78/R79), `Dockerfile` (R51).

**Layout: agreement with the owner-supplied document, and the item that actually owns it**
(owner-reference *C13*, "Start **single crate, feature-vertical modules** … promote to a
workspace only when compile times or team boundaries demand it"; owner decision 11, row 6).
**Agreed, on three counts already recorded above.** The file table is a single crate with
feature-vertical modules — `src/web/routes/projects.rs`, `src/web/routes/ops.rs`, and R70
through R80's later layers nested inside the same gated `src/web/` tree, which the owned
parameter's clause (4) fixes. `AppState` holding shared members with `FromRef` substates is the
document's own `AppState` + `FromRef` prescription, chosen here on the compile-time ground
under alternative B. Dependency injection "via traits behind concrete types" is R01's published
`http-transport-injection-seam`, which this item consumes unchanged. The same shape is selected
independently by **R49** (`build-target-declaration`), whose unpublished decision revision 8
(`research/runs/R49/2026-09-05T155504Z-2107cffb3ecf/review/DECISION.md`) compares four
alternatives and selects **A1 — "single package, one binary, web behind a Cargo feature"**,
recording that the selection "is shape-neutral: if R02 chooses a workspace, every field above
moves to the member manifests unchanged". **What is not decided here, and by whom:** whether
the template stays a single crate is **R02**'s (`crate-boundary-enforcement`, open), exactly as
the sentence above this table says; the owned value is phrased to survive either answer. The
document's own "promote to a workspace only when compile times or team boundaries demand it" is
a trigger for R02's question, not an answer to it, and no `CONFLICT:` line arises. The
document's reference repositories for C13 are Variant-A and Variant-B application samples; this
item names `rust-lang/crates.io` as its reference implementation for the reasons under
*Authorities*, and neither set was re-read for this row.

**The release profile: a row this item does not own, whose owner is not yet fixed either**
(owner-reference *Reference `Cargo.toml`*, `[profile.release]` with `lto = "thin"` and
`codegen-units = 1`; owner decision 11, row 11). The `Cargo.toml` row in the table above
enumerates every manifest change this item asks for — the `[features]` entry, the two optional
dependencies, the `tower` dev-dependency and the `[[bin]]` target — and **`[profile.*]` is not
among them, deliberately.** A release profile tunes how *every* target in the package is
compiled; it is neither gated by the `web` feature nor specific to the web surface, so
selecting one here would reach the CLI and library builds this item does not own.
**Which item does own it was verified rather than assumed**, because the answer turned out to be
"none yet". Asserted in `review/evidence/owner-reference-check-r9.log`, section C, over the
**complete** set of **85** binding prompts and the commonality ledger, with the denominator
printed and a control showing the same census reports a string the prompts do carry:
**no prompt and no ledger row names `[profile`, `lto`, `codegen-units` or `opt-level`.**
What the same section does establish, positively:
- **R68** (`release-binary-artifacts`) is the nearest consumer: its prompt scopes it to "which
  distribution channels/artifact *types* … get built and shipped", and the values a release
  profile governs — binary size and build time — are exactly what its MEDIUM and LOW questions
  weigh. But the same prompt places "the Cargo manifest's build-target declarations" outside
  its scope, in R49's.
- **R49** (`build-target-declaration`) owns the declaration surface — its owned
  `build-tool-output-shape` reads "no build backend or bundler crate; Cargo's own manifest is
  the entire declaration surface" and it names `target/release/rslbp` as the filename "R68's
  release matrix uploads" — yet it **sets no `[profile.*]` key at all**, which the same check
  asserts.

**So the disposition is a hand-off to R68 as the controller's reading, with the ownership itself
recorded as an open scoping question** rather than settled by this item. Nothing here
recommends, excludes or evaluates `lto = "thin"` or `codegen-units = 1`; whoever takes the row
inherits a live tradeoff this decision deliberately leaves untouched — both settings trade
build time for run-time performance and binary size, and this item's gate-6 answer already
records that the wall-clock and binary-size halves of that measurement are **unproven here**.

**Validation strategy.** *Verified in this run:* the six checks under `## Empirical check` —
the R01 state-bound coupling with two negative twins, the feature's gating shape and
dependency cost, the resolved-tree MSRV, advisories against the resolved lockfile, the
published-artifact facts about axum's state bound, its unbounded drain and tokio's feature
graph, the population figures with their endpoints, the issue-responsiveness figure codex
could not compute, and the dev tool's install and capabilities on macOS. *Proposed for the
template's CI (wiring is R11's, tiers are R32's):* `cargo test --features web` and
`cargo build --features web --bin <app>-serve` on `ubuntu-latest` and `macos-latest`; a
`cargo check` leg pinned to the declared `rust-version`; `cargo hack --each-feature check`,
or at minimum a `--no-default-features` and an `--all-features` job; `cargo audit` on the
template's lockfile; one `oneshot` test per route; a real-listener test decoding into the
library's own `Vec<Project>`; a `compile_fail` doctest for a handler asking for an
unregistered substate; a process-level test that sends SIGTERM during a slow request and
asserts both the response completing and the process exiting **143** inside the configured
window, its SIGINT twin asserting **130**, and its twin against a permanently blocked request
asserting the drain-deadline branch exits **1**; a conformance fixture over the serve binary's
R4.1 global core (`--help` and `-V` on stdout at exit 0, per R7.5 and R9.14);
`just serve` answering `GET /healthz` with console-formatted logs and restarting on a source
edit (blocked on R58); and the instrumented comparative benchmark specified in openai's raw
before any decision to prefer `actix-web`.

**Confidence.** **High** for the framework, runtime, state-injection, router-composition,
feature-shape and entrypoint members: each rests on a published artifact read at an exact
version, a maintained reference implementation at a recorded commit, and an executed check on
this machine. **Medium-high** for the dev-serve member: the tool's gates, install and
capabilities are verified, but the recipe's end-to-end behavior depends on R58's unpublished
logging contract and was not exercised. **Medium** for the exact field list of `AppState`,
which R77 (settings) and R58 (logging) will refine, and for the drain-deadline code shape,
which is reasoned and read but not executed. The serve binary's **exit integers** and its
**required global core** are a separate case from both: they are **High** as *rules*, because
each is quoted from a normative document this programme has already settled — R67's accepted
owned value and the standard's R4.1 under the owner's 2026-09-14 ruling — and **unproven** as
*behavior*, because no binary exists to run; three rows in the unproven table carry them.

**Sources.** Retrieved by this synthesis on **2026-09-13** and snapshotted under
`review/evidence/snapshots/` (reduced, committed) and `review/evidence/sources/`
(verbatim, not committed): `https://crates.io/api/v1/crates/<name>` and `/versions` for
`axum`, `tokio`, `tower`, `bacon`, `watchexec-cli`, `cargo-watch`, `actix-web`, `warp`,
`poem`, `salvo`, `rocket`, `ntex`, `xitca-web`, `pavex`, `viz`, `tide`, `loco-rs`,
`dropshot`, `hyper`, `tower-http`, `systemfd`, `listenfd`;
`/reverse_dependencies?per_page=1` for `axum` and `tokio`;
`https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for `tokio-rs/axum`,
`tokio-rs/tokio`, `tower-rs/tower`, `Canop/bacon`, `watchexec/watchexec`,
`watchexec/cargo-watch`, `actix/actix-web`, `seanmonstar/warp`, `poem-web/poem`,
`rwf2/Rocket`; the same search endpoint sorted by creation plus each issue's comments for the
responsiveness figure; `https://rustsec.org/packages/<name>.html` for `axum`, `tokio`,
`tower`, `bacon`, `watchexec-cli`, `hyper`; published `.crate` artifacts of `axum` 0.8.9,
`tokio` 1.53.1, `bacon` 3.25.0, `watchexec-cli` 2.7.2 and `tower` 0.5.3 from
`https://crates.io/api/v1/crates/<name>/<version>/download`;
`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/.github/workflows/CI.yml` and
`.../examples/graceful-shutdown/src/main.rs`;
`https://raw.githubusercontent.com/tokio-rs/tokio/tokio-1.53.1/.github/workflows/ci.yml`;
`https://raw.githubusercontent.com/Canop/bacon/v3.25.0/.github/workflows/tests.yml`;
`https://api.github.com/repos/Canop/bacon/releases/latest`;
`https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/{Cargo.toml,src/router.rs,src/bin/crates-io/server.rs}`;
`https://raw.githubusercontent.com/watchexec/cargo-watch/v8.5.3/README.md`. Carried over from
the raws with their own retrieval date of **2026-09-12**: the py source at programme pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` (`src/py_launch_blueprint/web/app.py`, `web/deps.py`,
`web/__main__.py`, `web/routers/__init__.py`, `pyproject.toml`, `Justfile`);
`https://docs.rs/axum/0.8.9/axum/` and its `State`, `FromRef` and `serve` pages;
`https://docs.rs/tokio/1.53.1/tokio/` and `tokio/signal`; `https://tokio.rs/tokio/topics/shutdown`;
`https://doc.rust-lang.org/cargo/reference/features.html` and `.../cargo-targets.html`;
`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`;
`apollographql/router` at `e7b2b32b5c7183475ea874b58b9f0b7d01dc32d8`;
`meilisearch/meilisearch` at `a955694df9f50771b3ceaf7896754cecfbaf165d`;
`https://github.com/qdrant/qdrant/blob/master/Cargo.lock`;
`https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`;
`https://github.com/specta-rs/rspc/discussions/351`. Read by **revision 2 on 2026-09-15** and by
no earlier revision: `research/topics/67-error-and-exit-code-contract/DECISION.md` (R67,
published and owner-accepted 2026-09-14, sha256
`16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`) — its owned
`error-taxonomy-exit-codes` value, its `## Decision` answer to the SIGTERM question, its
boundary-precedence rule and its `ctrlc` source read; the org CLI Design Standard at
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` **v1.4.14** (2026-06-28) — its header
scope line, its conformance clause, R4.1, R4.4, R4.6, R5.1, R5.2, R7.1, R7.5, R9.6, R9.14 and
Appendix A; and `docs/port/OWNER-REVIEW.md`, section *2026-09-14 — the CLI Design Standard
binds, and OV-01 is refused*. Repository context:
`research/topics/01-ports-and-adapters-seam/DECISION.md` (R01, accepted 2026-09-10);
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` rows F017, F303, F330, F331, F338, F339;
`docs/port/DIVERGENCE-ANALYSIS.md` line 217; `docs/port/BASELINE-REVIEW.md` (the F331
reclassification); `docs/port/OWNER-REVIEW.md` (the 2026-09-04 owner direction).
Retrieved by **revision 6 on 2026-09-16** and by no earlier revision, each reduced into
`review/evidence/snapshots/r6/` by `fetch-owner-reference-r6.sh` and asserted by
`owner-reference-check-r6.sh`: `https://crates.io/api/v1/crates/axum` and `/versions`;
`https://crates.io/api/v1/crates/axum-test` and
`/axum-test/{18.0.0,18.3.0,18.7.0,21.1.0,22.0.0-rc.1}/dependencies`;
`https://api.github.com/repos/tokio-rs/axum/issues/3809` and its `/comments`;
`https://api.github.com/repos/tokio-rs/axum/issues/3003`;
`https://api.github.com/repos/tokio-rs/axum/pulls/3745` and `/pulls/3819`;
`https://cloud.google.com/run/docs/container-contract`, served HTTP 200 from
`https://docs.cloud.google.com/run/docs/container-contract`; and
`https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html`. Read by revision 6
and by no earlier revision:
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` (the owner-supplied
input, in full) and `docs/planning/p02/owner-decisions.md` section 11;
`research/runs/R49/2026-09-05T155504Z-2107cffb3ecf/review/DECISION.md` (R49 revision 8,
**unpublished**, for its selected alternative A1) and R67's published `## Parameters` block for
the envelope shape named under *Minimal realistic endpoint*.

re-verify: when axum publishes 0.9, when R58 (logging-pipeline-contract) or R02 (crate-boundary-enforcement) publishes, when watchexec-cli declares a rust-version or the owner rules on whether the MSRV gate reaches non-linked developer tools, when R67 dispositions this item's request for a drain-deadline catalog row or revises the 130/143 reading of its boundary precedence, when R60's published decision moves off its owner-accepted clap 4.6.6 derive selection for the CLI binary the serve binary's global core is parsed with, when the CLI Design Standard revises R4.1's required global core past v1.4.14, at the next msrv-policy floor advance past 1.96, or by 2027-03-13, whichever comes first

## Parameters

- owns web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92

**No `CONFLICT:` line is raised by this decision, and none of the five raws raised one.** The
one coupling that could have produced one is R01's, and it was verified rather than assumed:
the web adapter holds R01's erased service in `AppState` as `Arc<ErasedProjectsService>` and
returns the library's own `serde`-derived contract types, with no mirror struct and no second
construction path, and this requires **no change to R01's types** — `Arc<T>` is
unconditionally `Clone`, which is all axum's `S: Clone + Send + Sync + 'static` state bound
needs, so `ProjectsService` does not have to derive `Clone`. The check, its two negative
twins and what they do not establish are under `## Empirical check`, check 1.

The five `- assumes` lines above are quoted byte-for-byte from `docs/port/PARAMETERS.md` and
are assumptions here, not findings; `review/empirical/parameters-check.sh` re-derives them
from the registry and diffs them against this file, and its output is
`review/evidence/parameters-check.log`. How they bear on the decision: `rust-edition` and
`msrv-policy` set the resolver configuration every probe in this run ran under
(`edition = "2024"`, `rust-version = "1.96"`, stable 1.98.x minus two minors), and gate 2's
exclusions of `warp`, `viz`, `pavex`, `tide` and `xitca-web` are read against that floor;
`target-os-matrix` is why gate 4's macOS leg mattered enough to close by executing installs
and builds on this host, and why Windows support is noted rather than required — only the
macOS leg was exercised here, the Linux leg belongs to the template's CI (R11);
`license` governs this repository's own declared expression and, under owner ruling Q7.B, is
**not** evaluated against any dependency or tool, which is what restored `bacon` to the
dev-reload recommendation.

`package-manager-invocation` (R42, published) is not listed above because the prompt's
`- consumes:` line names only R01, so it is not a consumed parameter of this item. It still
bears on the answer: its rule that a crates.io-installed tool is invoked as a bare executable
on PATH and presence-tested with `command -v <executable>` is exactly the form the `serve`
recipe and the dev-tool list above take.

Open items this answer depends on but does not decide, and how it behaves either way:
**R05 `sync-async-execution-model`** — if R01's port stays synchronous the handler wraps the
call in `tokio::task::spawn_blocking`; if R05 chooses an async port the handler awaits it
directly and R01's `async-trait` clause applies. Nothing in this stack changes either way and
`rt-multi-thread` is required in both cases. R05 registers no parameter, so this is a coupling,
not a conflict. **R02 `crate-boundary-enforcement`** — decides which crate carries the feature
and the `src/web/` module; the owned value above is phrased to survive either a single-crate or
a multi-crate layout. **R58 `logging-pipeline-contract`** — owns the console/structured profile
split the dev recipe's environment variable selects, and the name of that variable.

## Empirical check

This section reports **verification only**. This is a research programme: the template does not
exist yet and P03 builds it, so nothing here builds, wires or runs the recommended web surface.
No handler, router, listener, service, seam or template scaffold was written. The two probe
packages that exist contain an empty `src/lib.rs`, a `fn main() {}`, and type declarations with
no methods; they are described with each check and retained under `review/empirical/`.

**Toolchain and OS.** macOS 26.4 (build 25E246), `aarch64-apple-darwin`.
`rustc -vV` → `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `host: aarch64-apple-darwin`,
LLVM 22.1.8. `cargo --version` → `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`.
`cargo audit --version` → `cargo-audit-audit 0.22.1`. `jq` 1.x at `/opt/homebrew/bin/jq`;
`gh` authenticated as `smorin`. Under `msrv-policy` the floor today is **1.96**.

**Working directory.** Five of the six scripts live in
`research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/empirical/`; the sixth, check 2's
`feature-shape-check-r4.sh`, lives in the sibling
`research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/evidence/` and reads the two probe
packages under `../empirical/`. All six resolve their own paths from `${BASH_SOURCE[0]}`, so
they rerun unchanged from any directory after this decision is committed. Every script sets
`set -o pipefail`. Every script asserts on **content**, and three of them carry a deliberate
control assertion that must fail, so that a check which cannot fail is visible as such —
check 2 now carries three, the MSRV-floor control, revision 3's advisory-count control, and
revision 4's control showing the warning-absence test reports a line that *is* present.

**Five further scripts, none of which is a seventh check.** Two are revision 9's and are
described first; two are revision 6's; the fifth is revision 5's.

Revision 9 adds `review/evidence/fetch-owner-reference-r9.sh` and
`review/evidence/owner-reference-check-r9.sh`, with the cited log
`review/evidence/owner-reference-check-r9.log`. They stand in the same relation to each other
as revision 6's pair, for the same reason: the fetcher goes to the network and writes reduced
snapshots under `review/evidence/snapshots/r9/`, **which are committed**, and the check asserts
against those committed snapshots so that it reruns offline and byte-identically after this
decision is committed. Only **published crate metadata** is snapshotted — versions, licences,
declared `rust-version`, `[features]` maps and dependency requirements from the crates.io API —
so no third-party source file is written into this repository. The check has one property
revision 6's does not: **its section C reads committed files of *this* repository** — the 85
binding prompts under `research/topics/` and `docs/port/COMMONALITY.md` — because the question
row 11 asks is *which P02 item owns release-profile settings*, and that is a fact about this
repository, not about an upstream project. A census over prompts is exactly the shape this
programme has been burned by before, so it is written to fail loudly rather than quietly:
**the denominator is asserted and printed** (`prompt files searched (the complete set): 85`,
and a separate assertion that the set is non-empty), and **the control runs the identical
`find`/`/usr/bin/grep -l` census over the identical file set for a string the prompts do
carry**, reporting 85 of 85. That guard is not decorative — while this check was being written,
a wrong path expression made the file set empty, and the run reported `0` prompts naming
`[profile` for the wrong reason; the denominator assertion and the control both failed and
caught it. The script was run **three times in a row** and runs 2 and 3 were **byte-identical**
to run 1, which is the cited log. Failure capability was demonstrated separately: a scratch
copy, produced with `cp` and `sed` inside a mirrored scratch tree, with the single assertion
`must "what \`full\` adds beyond them, count" "5"` rewritten to `"9"`, printed
`FAIL … expected=9 actual=5` and exited `1`. The scratch tree was deleted and the committed
script is unmodified; section C's census does not execute inside that scratch tree, because
`find` does not follow the symlinked `topics` directory there, which is why the empty-file-set
failure described above is what stands as that section's failure evidence. Both scripts set
`set -o pipefail`, resolve their paths from `${BASH_SOURCE[0]}`, invoke `/usr/bin/grep` by
absolute path with the binary named in the log, name the repository rather than any personal
address in the User-Agent, write nothing inside this run directory except into
`snapshots/r9/`, and carry the same file-level `# shellcheck disable=SC2015,SC2016,SC2329`
directive with the same per-code justification the earlier scripts carry. **Neither is a
check**: no claim in the recommendation rests on either, and their exit status decides nothing
about it. What they establish is the three owner-reference rows revision 9 adds.

Revision 6's pair follows, unchanged and not edited by revision 9.

Revision 6 adds `review/evidence/fetch-owner-reference-r6.sh` and
`review/evidence/owner-reference-check-r6.sh`, with the cited log
`review/evidence/owner-reference-check-r6.log`. They exist because owner decision 11 folds an
owner-supplied reference architecture into this item as an **input**, and that document's own
caveat says its patterns were "compiled in my head, not against the toolchain" — so the facts
revision 6 takes from it are asserted rather than narrated. **The division between them is the
point.** `fetch-owner-reference-r6.sh` is a **fetcher, not a check**, the sibling of
`fetch-figures.sh`: it performs the retrievals, records each one's HTTP status and effective
URL, and writes a **reduced** snapshot of each — only the fields this decision cites — under
`review/evidence/snapshots/r6/`, **which is committed**. Its User-Agent names the repository
(`https://github.com/smorinlabs/rs-launch-blueprint`) and no personal email address appears in
any request, per R42 revision 7's precedent. `owner-reference-check-r6.sh` then **asserts
against those committed snapshots and never touches the network**, which is what makes it
rerunnable offline and byte-identical after this decision is committed rather than only from
the author's checkout on the day the sources were live. It asserts on content in seven
sections — axum's published release list, Cargo's default version-requirement rule, the
axum-0.9 state in `tokio-rs/axum`, axum-test's versions and declared axum requirements, the
Cloud Run shutdown sentences for services and for jobs, axum issue #3003, and a control — and
**the control must report a present string**, so the emptiness assertion it mirrors is capable
of failing. It was run **three times in a row** and runs 2 and 3 were **byte-identical** to run
1, which is the cited log; separately, a scratch copy produced with `cp` and `sed`, with the
single assertion `must "axum newest non-yanked num" "0.8.9"` rewritten to `"9.9.9"`, printed
`FAIL … expected=9.9.9 actual=0.8.9` and exited `1`. The scratch copy was deleted; the
committed script is unmodified. Both scripts set `set -o pipefail`, resolve their paths from
`${BASH_SOURCE[0]}`, invoke `/usr/bin/grep` by absolute path with the binary named in the log,
never write inside this run directory except into `snapshots/r6/`, and pass the repository's
`shellcheck` pre-commit hook carrying the same file-level
`# shellcheck disable=SC2015,SC2016,SC2329` directive, with the same per-code justification,
that `feature-shape-check-r4.sh` and `yanked-control-r5.sh` carry. **Neither is a check**: no
claim in the recommendation rests on either, and their exit status decides nothing about it.
What they establish is which of the owner-supplied document's statements this decision may
repeat — which is why the reconciliation rows above cite this log and not the document.

**One further script, which is not a seventh check either.** Revision 5 adds
`review/evidence/yanked-control-r5.sh` and its log `yanked-control-r5.log`. It tests **no claim
this decision makes**: it exists only to make the error-line count reported in the revision-4
note — the figure the round-4 audit rejected — an **executed assertion** rather than a
recalled number, and it carries its own control showing that assertion rejects 55. It lives in
`review/evidence/`, resolves its paths from `${BASH_SOURCE[0]}`, sets `set -o pipefail`,
asserts on content, and reruns unchanged after this decision is committed, like the six checks;
it is listed separately from them because its exit status decides nothing about the
recommendation.

| # | Claim under test | Script | Exit | Log under `review/evidence/` |
|---|---|---|---|---|
| 1 | **the R01 coupling**: the erased service satisfies axum's state bound without `ProjectsService` deriving `Clone`, and the `Arc` and R01's `Send + Sync` supertraits are each load-bearing | `state-bound-check.sh` | 0 | `state-bound-check.log` |
| 2 | the `web` feature's gating shape, its dependency cost, the resolved-tree MSRV, and that no advisory in a **pinned** RustSec database applies to the resolved lockfile | `feature-shape-check-r4.sh` (in `review/evidence/`; revision 3's `feature-shape-check-r3.sh` and revision 1's `review/empirical/feature-shape-check.sh` are retained unchanged) | 0 | `feature-shape-check-r4.log` (revision 3's `feature-shape-check-r3.log` and revision 1's `feature-shape-check.log` are retained unchanged) |
| 3 | every population figure, gate answer and published-artifact fact this decision cites | `assert-figures.sh` | 0 | `assert-figures.log` |
| 4 | the issue-responsiveness figure the codex raw recorded as unverified | `issue-responsiveness.sh` | 0 | `issue-responsiveness.log` |
| 5 | the recommended dev tool's version pin installs on macOS and exposes the two capabilities F339's recipe needs | `bacon-install-check.sh` | 0 | `bacon-install-check.log` |
| 6 | the `## Parameters` block's five `- assumes` lines are byte-identical to the registry, the one `- owns` line carries no backtick/link/whitespace defect, and the H2 section list is exactly what the role contract fixes | `parameters-check.sh` | 0 | `parameters-check-r2.log` (revision 2's rerun; revision 1's `parameters-check.log` is retained unchanged) |

Two fetchers feed them and are not themselves checks: `fetch-figures.sh` queries every
endpoint the prompt's figure table names and writes a **reduced** snapshot — only the fields
that table names — under `review/evidence/snapshots/`, which **is committed**;
`fetch-sources.sh` downloads the upstream files read at an immutable version, tag or commit
into `review/evidence/sources/`, which is **not** committed, because it is third-party source
and one of it (`bacon` 3.25.0) is AGPL-3.0 — and the owner's 2026-09-12 ruling explicitly does
not touch the rule against committing third-party copyleft files **into** this repository.

**On reproducibility, stated precisely — and corrected.** Revision 2 said in this place that
"checks 1, 2, 5 and 6 run locally and reproduce byte-for-byte" and that all six had just been
re-run with `diff` reporting no differences. **For check 2 that was false**, and the round-2
empirical audit was right to reject it: the check's advisory scan consumed a mutable database,
so its advisory count moved from 1,243 to 1,246 between the recorded log and the auditor's
rerun. The sentence is withdrawn and replaced by the following, which says for each check
exactly what was established, by whom, and under which conditions.

- **Check 2** reads a **pinned** advisory database, runs `cargo audit` under an **isolated
  `CARGO_HOME`** that disables the yanked-crate lookup, normalises every absolute path it would
  print, and deletes one named class of environment-dependent line. Its log
  `feature-shape-check-r4.log` is what revision 4 established: the script was run **three times
  in a row** in this checkout and runs 2 and 3 were **byte-identical** to run 1, which is the
  cited log; the same script and its committed probe inputs were then extracted into a scratch
  directory as `git archive` produces them from the tree this revision commits and run there,
  and that run was **byte-identical to the cited log as well**; and a fifth run, made while a
  separate process held an exclusive `flock` on `~/.cargo/.package-cache` — the exact condition
  that made revision 3's log irreproducible — was **byte-identical to the cited log too**.
  **The reproduction conditions, stated exactly.** `rustc 1.98.0` and `cargo 1.98.0` on Darwin
  arm64 (macOS 26.4) as printed in the log's first two lines, with `cargo-audit` 0.22.1, `jq`
  and `git` on `PATH`; the environment variables `R69_ADVISORY_DB_URL`,
  `R69_ADVISORY_DB_MIRROR` and `R69_NO_LOCAL_MIRROR` unset, so their defaults apply, and
  `${TMPDIR:-/tmp}` writable; the files read are the two committed probe packages
  `review/empirical/feature-shape/` and `review/empirical/feature-shape-r01base/` with their
  committed `Cargo.toml` and `Cargo.lock`, read `--locked`, plus `RustSec/advisory-db` at
  commit `b50980aad8b8f14f77e25a97b32dd94bf008b0af` obtained from github.com or from a local
  `~/.cargo/advisory-db` mirror that already contains it; and **cargo-audit is executed under
  an isolated `CARGO_HOME`** — a `mktemp -d` directory under `${TMPDIR:-/tmp}` holding exactly
  `audit.toml` with `[yanked] enabled = false` and a `bin/cargo-audit` symlink — **so that
  neither a readable nor an unlocked cached crates.io index is required, because the branch
  that opens one is never entered**. Sections 1, 2, 5 and 7 do use the ambient `CARGO_HOME`,
  and its registry cache must already contain every crate in the two `Cargo.lock` files —
  otherwise `cargo tree --locked` prints `Updating crates.io index` and `Downloaded …` lines
  into those sections, which are **not** classified and would make the log differ. When that
  cache's `.package-cache` lock is contended cargo prints
  `Blocking waiting for file lock on package cache` (or `… on build directory`), and `norm`
  deletes exactly that line class with the anchored pattern
  `/^[[:space:]]*Blocking waiting for file lock on /d`. **That is the only classified line in
  this log**, it is named in the header line the log itself prints, and the lock-held rerun
  above is the evidence that classifying it is sufficient. The one remaining documented way the
  log can differ is the named SKIP: when the pinned commit is reachable from neither the network
  nor a local mirror, section 8 prints
  `SKIP: advisory-scan-skipped-pinned-db-unavailable` instead of the advisory lines and the rest
  of the log is unchanged; it cannot hide a feature-shape failure, which is asserted by a
  separate status variable.
- **Check 6** was re-run for revision 4 against this revised file, with `diff` reporting no
  differences against `review/evidence/parameters-check-r2.log`. It is the only one of the six
  that reads `review/DECISION.md`, and revision 4 moves nothing it measures — the one `- owns`
  line, the five `- assumes` lines and the H2 section list are byte-identical to revisions 2 and
  3 — so revision 2's log remains the cited one and **no new log is written**. Revision 1's
  `parameters-check.log` stays unedited as the record of revision 1. **Revision 5 re-ran it
  again**, against revision 5's text, and `diff` again reported no differences against
  `parameters-check-r2.log`: revision 5 edits prose and adds one control script, and moves
  neither a parameter line nor an H2 heading, so revision 2's log remains the cited one and no
  new log is written for it either. **Revision 6 re-ran it a third time**, against revision 6's
  text, and `diff` reported no differences against `parameters-check-r2.log` again. That result
  is this revision's own evidence for two of its claims: the one `- owns` line and the five
  `- assumes` lines are byte-identical to revisions 2 through 5 — so the owner-supplied
  document moved no owned value — and the H2 section list is still exactly the five headings
  the role contract fixes, which is the constraint revision 6 worked under in placing each
  reconciled row inside an existing section rather than adding a heading. Revision 2's log
  therefore remains the cited one and no new log is written for it.
- **Checks 1, 3, 4 and 5** were **not** re-run by revision 4, and that is not asserted here.
  None of them reads this file and none of their inputs changed. What stands for them is the
  round-3 empirical audit's own rerun, recorded in `review/audit-codex.md`: its finding 4
  reports that the five unchanged checks — state bound, figures, issue responsiveness, bacon
  install and parameters — reran with `exit code: 0` and **byte-identical logs**, check 2 being
  the sole exception and the subject of this repair. **Revision 5 re-ran none of checks 1 to 5
  either, and does not assert that it did.** It changes no script, no probe input and no log
  among them. What stands for them, and for check 2 in particular, is the **round-4** empirical
  audit's own rerun recorded in `review/audit-codex.md`: its findings 2 and 3 report that
  `feature-shape-check-r4.sh` reproduced `feature-shape-check-r4.log` byte-for-byte in all five
  modes tried and that the other five scripts and their cited logs were unchanged from `a735e88^`
  through `HEAD` and matched. Revision 5's own run is the separate control script named above.
  **Revision 6 re-ran none of checks 1 to 5 either, and does not assert that it did.** It
  changes no script, no probe input, no snapshot and no log among them; the two scripts and one
  snapshot directory it adds are new paths that no existing check reads. What stands for checks
  1 to 5 is the **round-5** empirical audit's own rerun, recorded in `review/audit-codex.md`
  (verdict `approve`, `unresolved-findings: none`): it reran all six decision checks and
  `yanked-control-r5.sh` — the latter three times in place and once from a clean
  `git archive HEAD` extraction — reporting exit `0` for each and every output byte-identical to
  its cited log, and it independently counted the 54 yanked errors with its own
  `/usr/bin/grep -cF`. Revision 6's own runs are check 6 above and the two new scripts.
- **Checks 3 and 4** read the committed reduced snapshots rather than live endpoints, because
  download counters, `pushed_at` and star counts move hourly and a live re-run could never be
  byte-identical; `fetch-figures.sh` refreshes them and records its retrieval timestamp in
  `snapshots/RETRIEVED-AT.txt` (`2026-09-13T07:57:55Z`). Check 3 additionally reads the
  uncommitted sources and invokes `fetch-sources.sh` itself when they are absent — which
  reproduces, because every one of those files is fetched at an immutable coordinate (a
  published `.crate` version, a git tag, a commit SHA). Re-running `fetch-figures.sh` will move
  the counters inside the snapshots and therefore the figures the logs print; the assertions —
  the version numbers, MSRVs, licences, `archived` flags and source facts — are the stable
  part, and are what the decision rests on.

An auditor therefore runs the six scripts, five from `review/empirical/` and check 2 from
`review/evidence/`, plus — since revision 5 — the one control script named above,
`review/evidence/yanked-control-r5.sh`, which decides nothing about the recommendation and is
run only to reproduce the count in the revision-4 note, plus — since revision 6 —
`review/evidence/owner-reference-check-r6.sh`, which reads only the committed snapshots under
`review/evidence/snapshots/r6/` and likewise decides nothing about the recommendation, and
plus — since revision 9 — `review/evidence/owner-reference-check-r9.sh`, which reads the
committed snapshots under `review/evidence/snapshots/r9/` together with this repository's own
committed prompts and ledger, and likewise decides nothing about the recommendation.
**Neither fetcher is rerun as part of an audit** — not
`review/evidence/fetch-owner-reference-r6.sh` and not
`review/evidence/fetch-owner-reference-r9.sh`: each goes to the network, and rerunning it would
move the snapshot contents under the check that reads them — the same reason `fetch-figures.sh`
is not rerun for checks 3 and 4. Nothing else. **The five locations
revision 3 edited in this section and
above it, enumerated rather than left to a reader's diff:** (1) acceptance criterion 1's
citation, now `feature-shape-check-r3.log`; (2) the gate-3 paragraph, which now names the
pinned advisory-db commit and, in the same sentence, corrects "resolved 52-package lockfile"
to the 55 crate dependencies the scan actually reported — 52 is the *other* probe's non-dev
package count and did not belong there; (3) the working-directory sentence, since the six
scripts no longer share one directory; (4) the check-2 row of the table above; (5) the check-2
narrative below, which now names the pin. Nothing else in this section or in any other section
changed.

**The locations revision 4 edited, enumerated from a mechanical search rather than from a
re-reading.** The search was `/usr/bin/grep -n -i 'yank|crates\.io index|cached|no-fetch|
auditor\.rs|CachedIndex|package-cache|CARGO_HOME|Blocking'` over this file, plus
`feature-shape-check-r3` and `revision 3`, and every hit was classified before any edit was
made: (1) the title; (2) the new revision-4 note, which quotes the round-3 finding verbatim;
(3) the revision-3 note's heading, which now says the note is retained as that revision's
record and that its "second and last documented way this log can vary" claim is the one the
round-3 audit refuted — the note's body is left **verbatim**, because it is the record of what
revision 3 said; (4) the synthesizer line, which adds revision 4's context; (5) acceptance
criterion 1's citation, now `feature-shape-check-r4.log`; (6) the working-directory sentence,
which now names `feature-shape-check-r4.sh`; (7) the control-assertion sentence, since check 2
now carries three controls rather than two; (8) the check-2 row of the table above; (9) the
check-2 reproducibility bullet, which carries the exact reproduction conditions; (10) the
check-6 and checks-1/3/4/5 bullets, which now name revision 4 and the round-3 audit's rerun;
(11) the check-2 narrative below, whose command form now shows the isolated `CARGO_HOME` and
whose sentence about the yanked-crate lookup is corrected, because under revision 4 that lookup
does **not** run. **Deliberately left byte-identical, and why:** the gate-3 paragraph under
`### Principles and implementation` (it records the advisory answer — the pinned commit, 1,243
advisories, 55 crate dependencies, exit 0 — none of which revision 4 moves); every gate-2
"newest non-yanked version" figure in the candidate tables (those come from the committed
crates.io snapshots read by check 3, never from this scan); the `## Parameters` block in full;
and the retained revision-2 and revision-3 note bodies.

**The locations revision 5 edited, enumerated from a mechanical search rather than from a
re-reading.** The search was three passes of `/usr/bin/grep -n -E` over this file before any
edit was made: `'55 lines|grew 55|prints 55'`, `'unpopulated|yanked\.enabled|default .true'`,
and `'six scripts|six checks|synthesizer|revision 4'`; every hit was classified first, and the
same searches were re-run against the edited file. The complete edit list: (1) the title, now
revision 5; (2) the new revision-5 note, which quotes the round-4 finding verbatim, explains
that 55 was the dependency count, and names the new script and log; (3) the revision-4 note's
heading, which now says the note is retained as that revision's record and that its two
error-count sentences are corrected in place; (4) **the count itself, at the two sentences the
finding cites** — `prints 55 lines of` → `prints 54 lines of`, with the 55-versus-54 arithmetic
and the citation to `yanked-control-r5.sh` added, and `the log grew 55 lines` → `the log grew 54
lines`; (5) the preamble's synthesizer line, which adds revision 5's context; (6) a new
paragraph after the control-assertion sentence above, introducing `yanked-control-r5.sh` as a
control and **not** as a seventh check; (7) the auditor sentence, which now names that script
alongside the six checks; (8) this enumeration. **Deliberately left byte-identical, and why:**
`review/evidence/feature-shape-check-r4.sh` and `feature-shape-check-r4.log` (the r4 script's
header comment at lines 72-80 therefore still carries the superseded 55, which the revision-5
note states explicitly; editing a comment would invalidate a log the round-4 audit reproduced
five ways, and no assertion, exit status or output line of that script depends on the figure);
the check-2 row of the table above, its reproducibility bullet and its narrative below, all of
which describe the isolated-`CARGO_HOME` scan that revision 5 does not touch; the six checks
and their five other scripts and logs; the gate-3 paragraph and every `55 crate dependencies`
figure, which is the *correct* use of that number; the `## Parameters` block in full; the
recommendation, the R67 exit contract and request, the R4.1 global core, gate 1's
`inapplicable` row; and the retained revision-2 and revision-3 note bodies.

**The locations revision 6 edited, enumerated from a mechanical search rather than from a
re-reading.** Revision 6 differs from revisions 2 through 5 in that it repairs no audit
finding: it folds in an owner-supplied input, so the search had to find every place each
reconciled row's **topic** already lives rather than every occurrence of a rejected figure. The
search was one pass of `/usr/bin/grep -n -E` over this file, run **before any edit was made**,
with the alternation
`'axum-test|oneshot|0\.9|=0\.8\.9|SIGKILL|bacon\.toml|Cloud Run|WebSocket|Websocket|http2|macros|R70|R32|R02|R49|workspace|single crate|cargo-chef|mold|synthesizer|revision 5|six checks|control script|re-verify'`;
every hit was classified against the eight rows before any text was written, and the same
search was re-run against the edited file. The complete edit list, in file order: (1) the
title, now revision 6; (2) the new revision-6 note, whose first paragraph states that no owned
value moves and why, and whose table gives all eight rows' dispositions; (3) the revision-5
note's heading, which now records that the note is retained as that revision's record and was
approved — its body is left **verbatim**; (4) the preamble's synthesizer line, which adds
revision 6's context; (5) under F338, a new paragraph on the unreleased 0.9 line (row 1's
second half); (6) under F338, two new paragraphs — the Cloud Run ten-second datum handed to R77
and the axum #3003 WebSocket hazard (row 4); (7) under F339, a new paragraph recording
agreement on `bacon`, this item's stronger SIGKILL finding, and the `cargo-chef`/`mold`
hand-offs (row 3); (8) after *Minimal realistic endpoint*, a new paragraph handing the RFC 9457
question to R70 with R67's differing envelope named (row 7); (9) under *Compatibility*, a new
block on the requirement operator (row 1's first half); (10) after *Migration implications*, a
new paragraph on layout, R49's A1 and R02's open boundary (row 6); (11) inside Disagreement 3,
a new block grounding the `oneshot` idiom and recording `axum-test` as the alternative with its
winning condition and corrected figures (row 5); (12) inside Disagreement 4, a new block
recording `ws`/`http2`/`macros` as additive later-layer territory (row 2); (13) under
`## Engines`, the owner-supplied input's provenance, its standing, and the overlap-map table
carrying every remaining row as a hand-off (row 8); (14) in `## Empirical check`, the
further-scripts paragraph, which now introduces revision 6's two scripts before revision 5's;
(15) the auditor sentence, which now names `owner-reference-check-r6.sh` and says why the
fetcher is not rerun; (16) the check-6 bullet and (17) the checks-1-to-5 bullet, which record
revision 6's parameters rerun and that it reran no other check; (18) this enumeration.
**Deliberately left byte-identical, and why:** the `## Parameters` block in full — the one
`- owns` line and the five `- assumes` lines — because the one question that could have moved
it, the document's `=0.8.9` advice, is answered by the fact that neither the value nor the
migration table states an operator at all (revision-6 note, first paragraph; *Compatibility*);
the recommendation, every version pin, every exclusion, the gate answers including gate 1's
`inapplicable` row, the R67 exit contract and the request to R67, and the R4.1 required global
core, none of which the document reaches; the `re-verify:` line, because the 0.9 finding
**confirms** its existing "when axum publishes 0.9" trigger rather than adding one; the six
checks and all seven of their scripts and logs, `yanked-control-r5.sh` and its log, and every
committed snapshot outside the new `snapshots/r6/` directory; and the retained revision-2,
revision-3, revision-4 and revision-5 note bodies.

**The locations revision 9 edited, enumerated from a mechanical search rather than from a
re-reading.** Revision 9, like revision 6 and unlike revisions 7 and 8, repairs no audit
finding: it closes a **gap in coverage**, so the search had to find where each of the three
undisposed rows' subjects already appears, and confirm that where a subject appears nowhere —
as `[profile.release]` does — that absence is itself the finding. The search was one pass of
`/usr/bin/grep -n -E` over revision 8, run **before any edit was made**, with the alternation
`'axum-extra|profile|"full"|\[features\]|tokio feature set|member is a decidable|Migration implications|further scripts|An auditor therefore|Document row \| Subject|synthesizer|revision 8'`;
every hit was classified against the three rows before any text was written, and the same
search was re-run against the edited file. Two classifications from that pass are worth
recording because they are near misses rather than hits: the two existing `axum-extra` mentions
(inside the 0.9 discussion under F338) are about **where axum's 0.9 breaking changes land**,
not about adopting the crate, and are left byte-identical; and every existing occurrence of the
word "profile" is either the CLI standard's *Small-CLI profile*, R58's *console/structured
profile* or `target/release` as a directory — **none is `[profile.*]` in the manifest sense**,
which is what made row 11's absence real rather than an artefact of the search. The complete
edit list, in file order: (1) the title, now revision 9; (2) the new revision-9 note, carrying
the three rows in the revision-6 table's form and continuing its numbering at 9, 10 and 11;
(3) the revision-8 note's heading, which now records that the note is retained as that
revision's record and was approved by both round-8 audits — its body is left **verbatim**, with
its original heading sentence quoted inside the new one so nothing it said is lost; (4) the
history line, which adds revision 9's context; (5) after *Migration implications*, a new
paragraph on the release profile and the ownership gap (row 11); (6) inside Disagreement 3, a
new block on `axum-extra` (row 10); (7) inside Disagreement 5, a new block on `full` against
the six (row 9); (8) two new rows in the overlap-map table under `## Engines`, for rows 10 and
11; (9) in `## Empirical check`, the further-scripts paragraph, which now introduces revision
9's two scripts before revision 6's and states the census guard and the failure evidence;
(10) the auditor sentence, which now names `owner-reference-check-r9.sh` and scopes the
not-rerun rule to both fetchers; (11) this enumeration. **Deliberately left byte-identical, and
why:** the `## Parameters` block in full, because all three rows resolve to a *differs* whose
ground is a rule the decision already states and two *hand-offs* to other items, none of which
touches what the `web` feature gates; the recommendation, every version pin, the tokio feature
list itself, every exclusion, the gate answers, the R67 exit contract and request, and the R4.1
global core; the `re-verify:` line, which none of the three rows gives a new trigger; the six
checks and every one of their scripts and logs; `yanked-control-r5.sh` and its log;
`fetch-owner-reference-r6.sh`, `owner-reference-check-r6.sh`, its log and every file under
`snapshots/r6/`; and the retained revision-2 through revision-8 note bodies.

**Check 1 — the R01 coupling.** Three dependency-free packages under
`review/empirical/state-bound/`. Each declares R01's published seam shape transcribed from
`research/topics/01-ports-and-adapters-seam/DECISION.md` — `pub trait ProjectsPort: Send +
Sync`, the blanket `impl` for `Arc<T>`, `ProjectsService<P: ProjectsPort>` **deliberately not
deriving `Clone`**, and `ErasedProjectsService` — **with no methods, no bodies and no
behavior**, plus axum's state bound transcribed verbatim from the published artifact
(`axum-0.8.9/src/routing/mod.rs:138-141`) as
`pub fn assert_axum_state_bound<S: Clone + Send + Sync + 'static>() {}`. They import nothing:
no `axum`, no `tokio`, no handler, no router, no listener. Each builds with `--offline`, which
is itself an assertion that nothing crept into the manifests. Observed:

```text
case: positive             expect: expect-pass     exit=0     (no diagnostics)
    assert_axum_state_bound::<Arc<ErasedProjectsService>>();
    assert_axum_state_bound::<AppState>();            // #[derive(Clone)] over two Arc fields

case: neg-by-value         expect: expect-fail     exit=101
error[E0277]: the trait bound `ProjectsService<Arc<(dyn ProjectsPort + 'static)>>: Clone` is not satisfied
   |     assert_axum_state_bound::<ErasedProjectsService>();
   |  the trait `Clone` is not implemented for `ProjectsService<Arc<(dyn ProjectsPort + 'static)>>`
   |  note: required by a bound in `assert_axum_state_bound`

case: neg-no-supertraits   expect: expect-fail     exit=101
error[E0277]: `(dyn ProjectsPort + 'static)` cannot be shared between threads safely
   |  = help: the trait `Sync` is not implemented for `(dyn ProjectsPort + 'static)`
   |  note: required because it appears within `ProjectsService<Arc<(dyn ProjectsPort + 'static)>>`
state-bound-check rc=0
```

**What this establishes.** R01's erased service, `Arc`-held, satisfies axum 0.8.9's declared
application-state bound with `ProjectsService` deriving no clone trait; the positive case also
covers the recommended `AppState` whose own `Clone` derive sits over two `Arc` fields neither
of whose inner types is `Clone`. The first negative twin shows the outer `Arc` is what does the
work — storing the service by value fails, which is why P03 would have to add `#[derive(Clone)]`
and a `P: Clone` bound to take that route. The second shows R01's `Send + Sync` supertraits are
what make the erased service shareable at all. **What it does not establish:** anything about
handlers, dispatch, request behavior, or the real axum crate's behavior at runtime. It is a
type-level fact about a declared bound, paired with that bound read at the published artifact.

**Check 2 — the feature's shape and cost.** Two manifest probes under
`review/empirical/feature-shape/` and `feature-shape-r01base/`. Both contain an empty
`src/lib.rs` and a `fn main() {}` binary; their only purpose is to make the manifests resolvable
so the feature's gating, cost and resolved MSRV are observable. Observed, with the feature off:
`cargo tree -e normal` contains no `axum`, no `tokio`, no `hyper` and no `tower`, and after
`cargo clean && cargo build --no-default-features --bins` the serve binary is absent. With it
on, all four appear, at `axum v0.8.9` and `tokio v1.53.1`. `cargo metadata` reports
`"required-features":["web"]` on the binary target and `null` on the library target.
`cargo tree --invert tower` shows `tower v0.5.3 └── axum v0.8.9`, which settles the dev-dependency
question: `tower` is already in the non-dev tree through `axum`, so a direct entry is needed only
to bring `ServiceExt` into scope in tests. The resolved non-dev tree's highest declared
`rust-version` is **`axum` 0.8.9's 1.80** (the probe's own 1.96 is the floor itself and is
excluded); the same test applied against a 1.70 floor reports a failure, so it can fail. Nine
transitive dependencies declare no `rust-version` at all — the strict gate-2 reading is applied
to *candidates*, not to every transitive crate, and this figure records that limit. `cargo audit`
0.22.1, run as `CARGO_HOME=<isolated> cargo audit --db <clone> --no-fetch --stale` against a
scratch clone of `RustSec/advisory-db` **pinned** at commit
`b50980aad8b8f14f77e25a97b32dd94bf008b0af` and asserted to be at that commit, loaded 1,243
advisories, scanned 55 crate dependencies and exited 0 with no findings. The count and the
crate total are asserted as constants; a control assertion demanding a count the database
cannot have shows the test can fail; and the normalised output is asserted to be exactly two
lines containing neither `couldn't open crates.io index` nor
`couldn't check if the package is yanked`. This scan does not refresh the crates.io index and
prints no `Updating crates.io index` line. It also does **not** read a cached index at all: the
isolated `CARGO_HOME` supplies an `audit.toml` setting `[yanked] enabled = false`, so per
`cargo-audit` 0.22.1's source (`src/auditor.rs:115-167`) the yanked-crate lookup is skipped
entirely and neither `CachedIndex::fetch` nor `CachedIndex::open` is called. No advisory result
depends on that lookup, and no claim in this decision rests on a yanked result. Revision 1 ran
this scan against the live, self-updating `~/.cargo/advisory-db`, which is why its count was
not reproducible and why revision 2 was rejected; revision 3 pinned the corpus but still read
the ambient cached index, whose `.package-cache` lock inserted a warning line into every rerun,
which is why revision 3 was rejected.
With the base set to R01's published members, the non-dev tree is **12 packages with the feature
off and 52 with it on**; the 52 matches the opus raw exactly, and the base differs by one package
because that probe carried one further base dependency, so the delta reads 40 here and 39 there.
This confirms the **shape** of the opus measurement; the wall-clock and binary-size halves of
that measurement are not reproduced here and are carried as unproven.

**Check 3 — figures, gates and artifact facts.** 75 assertions, all passing, plus one
deliberate control that must and does report `FAIL`. **Gate 1 is asserted nowhere in this
script**, and the script says so in its own header: under owner ruling Q7.B it is inapplicable
to every dependency and tool, so licences are printed as published metadata and never
compared. What is asserted: the version, MSRV, licence and `archived` state of every
candidate; the RustSec HTTP status and listed advisory ids per crate; the upstream CI runner
lists at each pinned tag; the reference implementation's pins, its edition, its registry-free
router and its unwrapped drain call site; axum's state bound, its `with_state` signature, its
`FromRef` substate documentation, its `close_tx.closed().await`, its **zero** occurrences of
`timeout` or `deadline` in `src/serve/mod.rs`, its `unsafe_code = "forbid"` lint, its **zero**
occurrences of `unsafe` in `src/`, its default feature list and the `axum::serve` cfg; tokio's
`default = []` and that none of `signal`, `net`, `rt-multi-thread`, `time` or `macros` enables
`sync`; and bacon's declared MSRV, its SIGKILL default, its `run-long` job's
`kill_then_restart` strategy and `need_stdout`, its headless stdout/stderr passthrough, and
its `--features` and post-`--` argument plumbing, and that `-j` selects the initial job while
`--headless` guards only the screen setup. Figures as snapshotted at
`2026-09-13T07:57:55Z`:

| Crate | 90-day dl | All-time dl | Newest non-yanked | Stars / pushed / archived | Open issues | Licence | `rust-version` | Rev-deps |
|---|---:|---:|---|---|---:|---|---|---:|
| `axum` | 114,795,000 | 466,425,972 | 0.8.9 (2026-04-14) | 27,100 / 2026-09-11 / false | 34 | MIT | 1.80 | 8,598 |
| `tokio` | 222,551,461 | 961,082,746 | 1.53.1 (2026-07-20) | 33,136 / 2026-09-13 / false | 316 | MIT | 1.71 | 72,187 |
| `tower` | 169,723,285 | 656,241,115 | 0.5.3 (2026-01-12) | 4,293 / 2026-06-22 / false | 69 | MIT | 1.64.0 | — |
| `bacon` | 21,763 | 328,857 | 3.25.0 (2026-08-23) | 3,410 / 2026-09-12 / false | 47 | AGPL-3.0 | 1.85 | — |
| `watchexec-cli` | 8,702 | 659,914 | 2.7.2 (2026-09-06) | 7,180 / 2026-09-07 / false | 31 | Apache-2.0 | **none** | — |
| `cargo-watch` | 174,663 | 1,970,345 | 8.5.3 (2024-10-02) | 2,861 / 2025-01-14 / **true** | — | CC0-1.0 | 1.75.0 | — |

**Check 4 — issue responsiveness.** The codex raw declined to compute this figure, noting that
the ten-newest listing mixes issues and pull requests and that a maintainer-attribution
calculation needs comment sampling. The rule applied here is the prompt's: over the 10 most
recently **opened issues**, the first comment whose `author_association` is `OWNER`, `MEMBER`
or `COLLABORATOR`, excluding bots and the issue author. Observed — `tokio-rs/axum`: median
**0.41 days**, **5 of 10 unanswered**, window 2026-06-16 → 2026-09-07; `Canop/bacon`: median
**0.02 days**, **3 of 10 unanswered**, window 2026-02-17 → 2026-08-24; `tokio-rs/tokio`:
median **0.33 days**, **3 of 10 unanswered**, window 2026-08-27 → 2026-09-09. The axum and
bacon figures reproduce the opus raw's independently, including the identical axum window; the
tokio median differs from opus's 0.03 days, a method difference this synthesis did not
reconcile, and the figure reported here is this run's. A control asserts the parser reports no
response for an empty comment list, so it cannot invent one. `axum`'s 5-of-10 unanswered is the
one population figure that argues against it; set against a `pushed_at` of the previous day, 34
open issues in total, and a normal patch cadence on the 0.8 line, the maintenance verdict is
**active**.

**Check 5 — the dev tool.** `cargo install bacon --version 3.25.0 --locked` exited 0 on this
host and the installed binary reports `bacon 3.25.0`; `bacon --list-jobs` run in a directory
with **no `bacon.toml`** lists `run-long` among the default jobs; `--headless` and `--features`
are both present in `--help`; and a control confirms the flag assertion reports an absent flag
as absent. This closes gate 4's macOS leg for this pin, which neither bacon's CI
(`ubuntu-latest` only) nor its v3.25.0 GitHub release (zero binary assets) demonstrates. It
builds a development **tool**, not the recommendation.

**A boundary judgement recorded for the auditors.** The opus raw reports executing a probe that
built a feature-off binary, served a handler over a real bound TCP listener with a real HTTP
client, and measured a drain with an in-flight request. The research-worker contract says not
to scaffold a crate or write a server; the worker states it wrote only its own report file, so
the probe lived outside the run directory. In this synthesizer's judgement that exceeds the
contract as the role now reads it, and it is recorded here rather than repeated. **Nothing in
this decision rests on those executions except where independently re-verified above:** the
state bound (check 1, type-level only), the 52-package feature-on tree (check 2), and axum's
unbounded drain (check 3, read at source rather than timed). The three passing tests the opus
raw reports, and its build-time and binary-size figures, are carried as engine-reported and
unproven.

## Engines

- codex `raw/codex.md` — gpt-5.6-terra (sha256 `6f1d03df7be0ab3afc4c1fc2bed545d0ad0ab55f30b138c10750346e7f9e21fd`), bundle shape OK. Recommends `axum` 0.8.9 on `tokio` 1.53.1 behind a `web` feature with explicit `WebState` injection, `axum::serve` plus tokio signals, and externally installed `watchexec-cli` 2.7.2 for the dev recipe. Members: `axum`, `tokio`, `watchexec-cli`. Executed nothing. Raised `BASELINE-REVIEW: F331`. Flagged six figures it could not verify (resolved-tree MSRV, RustSec advisory counts, platform CI, issue-response medians, watchexec-cli's declared MSRV, and all proposed integration and benchmark measurements) — of these, this synthesis verified the resolved-tree MSRV (1.80, check 2), the advisory answer (`cargo audit` exit 0 over 55 crates, check 2), platform CI for `axum`, `tokio` and `bacon` (check 3), the issue-response medians for `axum`, `tokio` and `bacon` (check 4), and watchexec-cli's absent `rust_version` (check 3). The proposed integration and benchmark measurements remain unproven and are in the table below.
- opus `raw/opus.md` — claude-opus-5 (sha256 `161fcbb42aadb8752c59d36a7ba337e1b69e717429110ad94c548ce649e0f91d`), bundle shape OK. Recommends the same `axum`/`tokio` stack with `State` + `FromRef` over one `AppState`, native router composition, a feature-gated serve binary, and a settings-driven drain deadline. Seven members (two crates, five patterns). By far the most evidence-dense raw: read published `.crate` artifacts at exact versions, the reference implementation at a recorded commit, and executed a build-and-serve probe. Raised `BASELINE-REVIEW: F330` (adopted) and `BASELINE-REVIEW: F339` (**withdrawn** — see Disagreement 1). Three corrections to it are recorded below.
- doxa (one engine, three provider bodies from operation `research-20260912-134041-a1150ec8a7594fa0`). The merged digest `raw/doxa.normalized.md` **fails** bundle shape validation — `doxa/normalization.json` records `answer: bundle H5 member field is outside a named member in '### Members'` — because gemini's member fields are emitted under a different H2 in the regrouped file. That is a layout defect in the digest only; all three per-provider normalized files pass validation and are what this synthesis used.
  - `raw/doxa-openai.normalized.md` — OpenAI gpt-5.6-sol (sha256 `efa7c6dc8385077a86280841d101713fd6426f7e5802c613bdcc8024ae3d0106`), shape OK. Members: `axum` 0.8.9, `tokio` 1.53.1, `tower` 0.5.2, `watchexec-cli` 2.5.1. **The only raw that gets the drain deadline right** (Disagreement 2). Raised `BASELINE-REVIEW: F330` and `F331`. Its own ledger records every crates.io and GitHub figure as "pending exact endpoint collection; not inferred from scraped substitutes" — an honest gap, and its `watchexec-cli` 2.5.1 / Rust 1.93 figures are stale against the registry's 2.7.2 (2026-09-06) with no declared `rust_version`. Its `tower` 0.5.2 pin is likewise superseded by 0.5.3.
  - `raw/doxa-gemini.normalized.md` — Gemini deep-research-preview-04-2026 (sha256 `6b0772ed4e79cca4e8e100aa6bfaaa20a49b9ccc239baa72933af309d0e5d85c`), shape OK. Members: `axum`, `axum::extract::State`, `tokio::signal` combined with `with_graceful_shutdown`, `bacon`. **Alone among the five it declined to exclude `bacon` on licence**, reasoning that an external, developer-installed tool that is never linked into the shipped binary does not engage the gate — which is the position owner ruling Q7.B has since made binding, so this raw's dev-reload recommendation survives the ruling unchanged and is adopted. Against that, **its figures are not endpoint-collected and are not used anywhere in this decision**: it reports axum at ">15k" stars (actual 27,100), "~150-200" open issues (actual 34), bacon 90-day downloads as ">1,500,000 (Proxy estimate based on tooling adoption)" (actual 21,763) and bacon's all-time downloads as "Data unavailable … assumed highly active", and it gives `rocket`'s MSRV as 1.89.0 where the registry says 1.64. Most of its inline citations are Vertex redirect URLs. It also proposes bounding shutdown with `tower_http::timeout::TimeoutLayer`, which is a per-request bound and R75's to decide.
  - `raw/doxa-perplexity.normalized.md` — Perplexity sonar-deep-research (sha256 `666031a08615390c89d5a834f5b2c6e119f02e79d3649ffce838ef7534e0382d`), shape OK. Members: `axum`, `tokio`, `hyper`, `tower-http`, and dev tooling as `Just` + `cargo-watch`. Agrees on the framework, the feature shape, `State` injection and native composition, and raises `BASELINE-REVIEW: F330`. Three of its positions are not adopted: `cargo-watch` is archived with a maintainer end-of-life notice; `tower-http` is explicitly out of scope (R75 owns it); and its drain wrapper carries the same clock-start defect as opus's. It carries no crate figures and states so, citing comparative articles rather than endpoints.

**An owner-supplied input, which is not an engine and is listed apart from the five raws.**
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` — "The Axum Companion
Stack — Reference Architecture (September 2026)", supplied verbatim by the owner on 2026-09-16
during the Wave 0 review walk. It produced no raw report, ran no engine and answered no prompt
field; it is recorded here because **owner decision 11 of 2026-09-16** requires revision 6 to
reconcile with it row by row where the two overlap, and its own provenance note fixes its
standing: *"an owner-supplied research input, not a binding standard and not a decision: each
research item that overlaps it must either agree with it on the record or say why it differs."*

**Its weight, stated exactly, because agreement with it is not evidence.** It carries no
executed check and says so: *"The code patterns are illustrative and compiled in my head, not
against the toolchain — validate them locally before relying on them"*, and it marks several
versions "verify". So **every fact revision 6 relies on from it was re-verified at a primary
source and asserted**, in `review/evidence/owner-reference-check-r6.log` — crates.io for axum's
release list and axum-test's versions and requirements, the GitHub REST API for issues #3809 and
#3003 and pull requests #3745 and #3819, Google Cloud's *Container runtime contract* for the
ten-second shutdown window, and the Cargo Book for the default version-requirement rule. Where
the document and a **fixed parameter** differ, the parameter governs and the document is not
followed: its `edition = "2021"` against `rust-edition` **2024**, and its
`rust-version = "1.85"` against `msrv-policy`, whose floor today is **1.96**. Its sole
recommendation on this item's own members — `axum` 0.8.9 on `tokio` 1 / `hyper` 1 / `tower`
0.5 — agrees with what revisions 1 through 5 already recommended on the evidence recorded
above, and **agreement is recorded as agreement, not treated as confirmation**: nothing in this
decision now rests on the document.

**Its overlap map, as the controller recorded it, and what revision 6 did with each row.** The
eight rows that overlap this item are reconciled where their topic lives — rows 1 through 7 in
the revision-6 note's table name the location of each. The remaining rows belong to other items
or to nothing yet, and owner decision 11 rules them **not decided and not researched here**.
One line each, with no position taken on any:

| Document row | Subject | Where it goes |
|---|---|---|
| C1, C2 | Templating (`askama`), static assets and the frontend build (`ServeDir` + `rust-embed`, or Vite) | **No P02 item; pending owner scoping.** The HTMX-versus-SPA head is an owner question, not a research one. |
| C3 | OpenAPI generation (`utoipa`, `utoipa-axum`) | **R71** (`openapi-generation-pipeline`); the typed-client half is **R84**. |
| C3 | TypeScript client generation (`openapi-typescript`, `openapi-fetch`, `ts-rs`) | **R84** (`openapi-typed-client-generation`). |
| C4 | Validation (`garde` + `axum-valid`) | **No P02 item; pending owner scoping.** It reaches the handler signature R70 and R71 shape. |
| C4 | Error contract, RFC 9457 | **R70** — see *Minimal realistic endpoint* above for the one question handed to it. |
| C5 | Database access, migrations, Cloud SQL connection (`sqlx`) | **No P02 item; pending owner scoping.** |
| C6 | Sessions, auth, password hashing, CSRF, OIDC, JWT | **No P02 item; pending owner scoping.** |
| C7 | WebSocket fan-out (`axum ws` + Redis Pub/Sub) | **No P02 item; pending owner scoping.** Issue #3003 is recorded under F338 as that layer's inherited hazard. |
| C8 | Background and scheduled work (`apalis`, Cloud Tasks) | **No P02 item; pending owner scoping.** |
| C9 | Config layering (`figment`) and secrets | **R77** (`web-env-settings`), with **R53**–**R56** owning config schema, discovery, tolerance and secret policy. The ten-second datum under F338 is R77's. |
| C10 | Logs and traces (`tracing`, `tracing-stackdriver`), error reporting | **R58** (`logging-pipeline-contract`) for the pipeline, **R78** for OpenTelemetry, **R79** for metrics. |
| C11 | Middleware order, rate limiting, security headers | **R75** (stack), **R74** (rate limiting), **R76** (CORS), **R72**/**R73** for pagination and idempotency. |
| C12 | Testing — harness, fixtures, mocks, snapshots, CI order | **R32** (harness and tiers), **R33** (property and snapshot), **R48** (mocking), **R11** (CI job structure). The in-process idiom is settled at Disagreement 3. |
| C13 | Project structure | Reconciled above under *Migration implications*; the crate boundary is **R02**'s. |
| C14 | `cargo-chef`, `mold`/`lld`, `rust-toolchain.toml` | **R51** (container), **R68** (release binaries), **R42** (toolchain provisioning). `bacon` is settled above under F339. |
| C15 | Container image, distroless base, `PORT`, probes | **R51** (image), **R80** (`/healthz`, `/readyz`). |
| Cloud Run Runbook | `gcloud run deploy` flags, affinity, migrations on deploy, pool sizing | **No P02 item; pending owner scoping.** The template ships no deployment and `target-os-matrix` names no cloud. |
| Variants A / B | HTMX head versus SPA head, and the hybrid | **No P02 item; pending owner scoping.** Owner decision 11 lists it explicitly among the rows it does not admit. |
| Level One, `tokio` throughout | Whether the library and CLI join the web surface's async world | **R05** (`sync-async-execution-model`, open), which `## Parameters` above already records as a coupling this decision survives either way. |
| Reference `Cargo.toml` | `axum-extra` 0.12.6 at `["cookie","cookie-private","typed-header"]` — added by revision 9 | Cookie jars are C6's, which has **no P02 item; pending owner scoping**; typed-header extractors belong to whichever of **R72**–**R76** needs one. Not a member here; reconciled at Disagreement 3. |
| Reference `Cargo.toml` | `[profile.release]` — `lto = "thin"`, `codegen-units = 1` — added by revision 9 | **R68** (`release-binary-artifacts`) as the controller's reading and the nearest consumer, **with the ownership recorded as an open scoping question**: no prompt and no ledger row names these keys. Reconciled under *Migration implications*. |

**What the owner's licence ruling changed versus the raws.** Every licence-based exclusion in
every raw was enumerated and re-evaluated. Gate 1 is recorded throughout this decision as
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any
dependency or tool`, and the row is retained rather than deleted because the binding prompt
still contains gate 1 and its sha256 is cited by acceptance records.

| Raw | Licence-based sentence | Disposition |
|---|---|---|
| codex, `#### watchexec-cli` → *Qualified shortlist*, *Excluded by gate*, *Ranked runner-up* | "`bacon` is not qualified because its latest crate license is AGPL-3.0"; "`bacon` is excluded by the repository's compatible-license gate"; "no runner-up passes all recorded checks: … bacon's license is incompatible" | **Struck.** `bacon` is not excluded. |
| opus, `#### Dev-serve recipe` → *Excluded by gate*, and `BASELINE-REVIEW: F339` | "`bacon` 3.25.0 — **gate 1**: licence `AGPL-3.0` … a tool the template *requires* every contributor to install is the wrong place to spend that ambiguity"; and the F339 demotion premised on "each surviving candidate fails one gate" | **Struck**, and the recommendation changes: `bacon` is selected and the `BASELINE-REVIEW: F339` line is withdrawn. |
| opus, `#### axum` → *Tradeoffs* and `#### tokio` → *Tradeoffs* | "`axum` is `MIT`-only, not dual-licensed — compatible … but without Apache-2.0's explicit patent grant, which is the owner's stated reason for the dual licence"; "`MIT`-only (see `#### axum`)" | **Struck as an evaluation ground.** It was explicitly non-discriminating in the raw itself (it notes 17 of 52 packages are MIT-only whatever the framework), so removing it changes no recommendation. Licences are still reported as published facts. |
| openai, *Fitness gates* table | "Bacon 3.24.x … fails the owner's strict dependency/tool license rubric. **Excluded by gate 1**"; and *Ranked runner-up*: "Bacon, only under a recorded license-policy exception" | **Struck.** The exception is now the rule; no policy exception is needed. |
| gemini, `#### bacon` → *Excluded by gate* | "Pass (`AGPL-3.0` - strictly a local dev tool, not linked into the template binary)"; "*Note: … entirely permissible because it functions exclusively as an external, developer-installed command-line tool*" | **No change.** This raw did not exclude on licence, so the ruling leaves its conclusion standing. |
| perplexity, `#### axum` → *Excluded by gate* | "None of the shortlisted frameworks are excluded by obvious license incompatibility" | **No change.** No exclusion to strike. |

No candidate anywhere in this item is excluded on licence. The exclusions that stand —
`warp`, `viz`, `pavex`, `tide`, `xitca-web` and `watchexec-cli` on gate 2; `cargo-watch`,
`poem` and `rocket` on maintenance; `salvo`, `ntex` and `actix-web` on fit — rest on grounds
the ruling does not touch. The ruling does **not** touch this repository's own declared
licence expression, nor any rule against committing third-party copyleft files into this
repository; `bacon` is installed from crates.io by each contributor and no AGPL-3.0 file
enters this repository.

**Disagreements, and the evidence that settled each.**

1. **The dev-reload tool** — `watchexec-cli` (codex, openai), `bacon` (gemini), `cargo-watch`
   (perplexity), or no tool with auto-reload demoted to optional (opus). **Settled for
   `bacon` 3.25.0** by the licence ruling plus registry facts: with gate 1 struck, `bacon` is
   the only candidate that fails no applicable gate — `cargo-watch` is archived with its
   maintainer's own end-of-life notice in the README at tag `v8.5.3`, and `watchexec-cli`
   2.7.2 declares no `rust_version`. Because opus's demotion was premised on every candidate
   failing a gate, the premise is gone and auto-reload returns to the required recipe;
   `BASELINE-REVIEW: F339` is withdrawn and F339 now ports at capability level. The tool's
   fitness for the *console-log* half of F339 was then verified rather than assumed, since a
   TUI-first runner is not obviously able to stream a server's logs: `--headless` prints the
   child's stdout and stderr directly, `run-long` is a default job needing no `bacon.toml`, and
   `--features` reaches cargo. One correction to opus follows from the same reading: its
   migration list says no `bacon.toml` is needed, but bacon's default Unix job interruption is
   SIGKILL, so a `kill` override is required for a dev restart to exercise the production drain.
2. **Where the drain deadline's clock starts.** Opus and perplexity both wrap the entire serve
   future in `tokio::time::timeout(grace, server)`, which bounds the server's whole lifetime
   and would terminate a healthy service after the grace period; openai starts the timeout when
   the shutdown future fires. **Settled for openai's shape** on the merits — the two behave
   identically only if shutdown is requested at t=0 — with a consequence verified at source:
   that shape needs `tokio::sync::oneshot`, and none of `signal`, `net`, `rt-multi-thread`,
   `time` or `macros` enables tokio's `sync` feature, so `sync` is added to the recommended
   feature list, which opus's manifest omits. Gemini's `tower_http::timeout::TimeoutLayer` is a
   per-request bound, not a drain deadline, and belongs to R75.
3. **The member list — naming and granularity.** The raws differ: codex lists three members
   (two crates plus a tool), openai four (three crates plus a tool, with versions in the
   headings), gemini four (one crate, one **extractor type**, one API pairing, one tool),
   perplexity five (four crates including `hyper` and `tower-http`, plus "Just + cargo-watch"),
   and opus seven (two crates plus five patterns). **Settled on the merits, not by vote, by one
   rule: a member is a decidable artifact this item owns.** The prompt's own value test names
   five things that get rewritten if this answer is wrong — the framework dependency, the
   feature-gate shape, the config-injection mechanism, `main`'s entrypoint, and the dev-serve
   recipe — and the 2026-09-04 baseline review added router composition (F331) to this item.
   That yields the eight rows in the table under `## Decision`: three crate members plus five
   pattern members, one per artifact. What this rule excludes, and why: **`hyper`** (perplexity)
   is never declared in the template's manifest — it arrives transitively through `axum`, so
   there is nothing to decide; **`tower-http`** (perplexity, gemini) is named in this item's
   `## Out of scope` as R75's; **`axum::extract::State`** (gemini) is the mechanism the F330
   decision *selects*, not a separate decision — listing a type as a member would equally
   oblige listing `Router` and `IntoResponse`; and **`Just`** (perplexity) is the repository's
   existing command runner, not something this item chooses. `tower` **is** kept as a member,
   against codex and opus who fold it away, because it is a crate with a version pin the
   template's manifest must carry — but as a `[dev-dependencies]` entry, which check 2 settles:
   `cargo tree --invert tower` shows it already in the non-dev tree through `axum`, so a direct
   entry buys only the `ServiceExt` import in tests and must not be inside the `web` feature as
   openai and perplexity have it.

   **The in-process test idiom, reconciled with the owner-supplied document** (owner-reference
   *C12*, which picks "**axum-test + `#[sqlx::test]` + wiremock + insta**", version "axum-test
   18", over runner-up "tower `oneshot`" on the ground that "oneshot lower-level, more
   boilerplate", and its *Agent Enablement Notes*, "Use `TestServer::new(app)`; requires axum ≥
   0.8.7"; owner decision 11, row 5). **The `oneshot` choice above is kept, and the document's
   authority is not what settles it** — owner decision 11 makes the document an input, not a
   pre-decision. The ground, stated positively rather than as a rejection:
   - **It adds no crate to the template.** `cargo tree --invert tower` (check 2) shows `tower`
     0.5.3 is already in the **non-dev** tree through `axum` itself, so the `[dev-dependencies]`
     entry buys only the `ServiceExt` import — measured, not assumed, and the reason this
     member sits outside the `web` feature. `axum-test` would be a new crate in a template whose
     whole cost argument is the 12 → 52 package delta that check 2 measures.
   - **It exercises the production object.** `oneshot` is called on the same `Router`
     `build_router(state)` returns and `axum::serve` consumes, which is what makes acceptance
     criterion 3 — "`build_router(state)` is the only constructor" — testable rather than
     merely asserted.
   - **What the document's "more boilerplate" objection buys is real but out of scope here.**
     `axum-test`'s `TestServer` wraps request construction, cookies and a WebSocket client; its
     value rises with the surface under test, and most of that surface (`#[sqlx::test]`,
     `wiremock`, `insta`, WS) belongs to items this one does not own.

   **The alternative is recorded with the condition under which it wins, and with corrected
   figures.** `axum-test`'s registry state, asserted in
   `review/evidence/owner-reference-check-r6.log`, section D: its newest non-yanked version
   under this item's field rule — the same literal reading applied to `ntex` and `tide` in
   Disagreement 8 — is **22.0.0-rc.1 (2026-08-24)**, a prerelease; its newest **stable** version
   is **21.1.0 (2026-08-20)**, `rust_version` **1.89**, licence MIT, and it declares
   `axum ^0.8.9`. **The document's "axum-test 18" is three majors stale**, and its "requires
   axum ≥ 0.8.7" holds only from **18.3.0** onward — `18.0.0` declares `^0.8.4`, `18.7.0`
   declares `^0.8.8`. No fitness gate is answered for it here, because it is not selected; a
   gate pass would have to be established by whoever selects it. **The condition under which it
   wins:** when the template's test surface grows past a single in-process request — a database
   fixture, a cookie-carrying session, or a WebSocket client — the boilerplate `oneshot` leaves
   in each test outweighs one dev-dependency. **That call is R32's** (`test-harness-and-execution`,
   open), which owns the harness and the tiers, as *Validation strategy* above already states;
   this item owns only the idiom its own acceptance criterion needs, and R32 adding `axum-test`
   as a harness crate would not disturb the `tower` member or the owned value. Owner decision
   11 places C12 in R32's overlap set, so the document reaches R32 as an input in its own right.

   **`axum-extra`, which the owner-supplied document pairs with axum in its shared core, is not
   a member of this stack** (owner-reference *TL;DR*, "axum 0.8.9 + **axum-extra 0.12.6** on
   tokio 1 / hyper 1 / tower 0.5 / tower-http 0.6 / http 1", and its *Reference `Cargo.toml`*,
   `axum-extra = { version = "0.12.6", features = ["cookie","cookie-private","typed-header"] }`;
   owner decision 11, row 10). **The document's figure is correct and is not the issue.**
   Verified at the registry and asserted in `review/evidence/owner-reference-check-r9.log`,
   section B: `axum-extra` **0.12.6** is the newest non-yanked *and* the newest stable version,
   published 2026-04-14 — the same day as `axum` 0.8.9 — licence MIT, declared `rust-version`
   **1.80** (inside the 1.96 floor), requiring `axum ^0.8.9`. Nothing about it is stale or
   unfit. **It is excluded by the member rule this Disagreement already states** — *a member is
   a decidable artifact this item owns* — for the same reason `tower-http` is: what the
   document enables it for is another layer's business. Its three named features resolve to two
   optional crates and nothing else: `cookie = ["dep:cookie"]` and
   `cookie-private = ["cookie", "cookie?/private"]` bring in `cookie ^0.18.0` for signed and
   private jars, and `typed-header = ["dep:headers"]` brings in `headers ^0.4.0` for the
   `TypedHeader` extractor. **No acceptance criterion in this item asks for either.** The
   handler in *Minimal realistic endpoint* takes `State` and `Query` and returns the library's
   own types; there is no cookie, no session and no typed header anywhere in F303, F330, F331,
   F338 or F339.
   **Where it goes, as a hand-off and not a decision.** Cookie jars serve sessions, auth and
   CSRF — the document's own *C6*, which **no P02 item covers**; it is listed under `## Engines`
   as pending owner scoping. Typed-header extractors serve request handling and middleware, so
   they belong to whichever of **R72**–**R76** needs one. Either way the mechanism is already
   fixed by the owned parameter and needs no change here: `axum-extra` would be an **additive**
   dependency of a later layer nested inside the gated `src/web/` tree, under the clause
   *"heavier opt-ins nest on top rather than widening it"*. **This item neither selects nor
   excludes it on fitness** — no gate is answered for it, because it is not a candidate here —
   and the owned value is byte-identical.
4. **The axum feature set.** Codex proposes `default-features = false` with
   `["http1", "json", "tokio"]`; openai `default-features = false` with seven named features;
   opus leaves the defaults on. **Settled for defaults on.** Codex's minimal set drops
   `matched-path` (which R78 and R79 need for low-cardinality route labels rather than raw
   high-cardinality URLs), `query` (which R72's pagination anticipates) and `tracing` (which
   emits axum's own spans into whatever subscriber R58 selects) — openai identifies each of
   those reasons explicitly, and they are the merits argument. Openai's explicit list then
   differs from the defaults only by `form` and `tower-log`; enumerating a default set invites
   silent drift when the crate changes it, and the reference implementation keeps the defaults
   on and adds to them rather than disabling them. `http2` stays off; it is off by default and
   no consumer has asked for it.

   **The owner-supplied document's feature list is additive later-layer territory, and is not
   enabled here** (owner-reference *Reference `Cargo.toml`*,
   `axum = { version = "0.8.9", features = ["macros", "ws", "http2"] }`; owner decision 11,
   row 2). The three are **additions to** axum's defaults, not replacements for them, so this
   row is not a disagreement about the default set settled above; it is a question about
   opt-ins, and the owned parameter already answers that question in general terms: **"heavier
   opt-ins nest on top rather than widening it, as separate features that require `web`"**. Each
   of the three is taken by the layer that needs it, not by this item:
   - **`ws`** — the WebSocket upgrade surface. No item in this programme owns it (see the
     hand-offs under `## Engines`), and axum issue #3003 under F338 is the hazard whoever takes
     it inherits. Enabling it here would ship an unbuilt, untested surface inside the `web`
     feature.
   - **`http2`** — already answered two sentences above on its own merits, and unchanged: off
     by default, no consumer has asked for it, and `axum::serve` needs only *one* of `http1` or
     `http2`, which the defaults supply as `http1`. A Cloud Run deployment would want it off in
     any case; the document's own *C11* caution says "no end-to-end HTTP/2 for WebSockets".
   - **`macros`** — `#[debug_handler]` and friends, an ergonomic aid for handler authors. It is
     a template-authoring convenience with no effect on the shipped surface, and adding it would
     widen the base feature for something no acceptance criterion needs.

   **Nothing about the owned value or the recommended feature list changes**, and no gate is
   re-answered: the base stays axum's published defaults `form, http1, json, matched-path,
   original-uri, query, tokio, tower-log, tracing`, the pattern for anything heavier stays the
   separate-feature form the owned value names (`otel = ["web", …]` for R78, `metrics` for
   R79), and a later item wanting `ws` follows that same pattern rather than editing this one.
5. **The tokio feature set.** Codex `["macros", "rt-multi-thread", "net", "signal"]`; gemini
   `["rt-multi-thread", "net", "signal"]`; opus adds `time`; openai adds `time` and `sync`.
   **Settled for openai's set.** `time` is not optional — without it there is no
   `tokio::time::timeout` and therefore no drain deadline at all, so codex's and gemini's lists
   cannot implement the F338 behavior they describe. `sync` follows from Disagreement 2 and was
   confirmed to be implied by nothing else in the feature graph.

   **The owner-supplied document proposes a sixth list — `full` — and it is not adopted**
   (owner-reference *Reference `Cargo.toml`*, `tokio = { version = "1", features = ["full"] }`;
   owner decision 11, row 9). **The rule this is decided by is already stated in this decision,
   at gate 5:** *"`tokio`'s `default = []`, so every feature is opted into explicitly."* That is
   not a preference for small manifests; it is the reason the five raws' lists could be
   adjudicated at all, and it is the same rule that **added** `time` and `sync` above when a
   named behaviour needed them. Applied to `full`, it asks what behaviour each added name
   serves. Read at tokio 1.53.1's own published `[features]` map and asserted in
   `review/evidence/owner-reference-check-r9.log`, section A:
   - **`full` is twelve features** — `fs`, `io-util`, `io-std`, `macros`, `net`, `parking_lot`,
     `process`, `rt`, `rt-multi-thread`, `signal`, `sync`, `time`.
   - **The six selected already cover seven of them**, because `rt-multi-thread = ["rt"]`. So
     this is not a disagreement about the runtime, the listener, the signals or the clock: on
     all of those the document and this decision agree exactly.
   - **What `full` adds beyond them is five names — `fs`, `io-util`, `io-std`, `parking_lot`,
     `process`** — and no acceptance criterion, no F338 behaviour and no line of `serve_until`
     uses any of them. `fs` and `process` are filesystem and child-process APIs this surface
     never touches; `io-util`/`io-std` are AsyncRead/AsyncWrite helpers and stdio wrappers that
     `axum::serve` does not route through.
   - **One of the five costs a crate, not just a code path.** `parking_lot` carries no feature
     body: it is the implicit feature tokio's **optional dependency**
     `parking_lot = "^0.12.0"` creates, so enabling it puts `parking_lot` and its own tree into
     the resolved graph. That is measured cost against **gate 6**, whose whole finding is the
     12 → 52 package delta the `web` feature already pays.

   **So the disposition is *differs, with ground*, and it moves nothing.** The recommended list
   stays `rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`, and the owned value is
   byte-identical. The document's own preference is understandable in its context — a reference
   architecture for an application, where `full` saves a reader from auditing a feature list —
   but this template's cost argument is measured in packages, and a template is copied. **Where
   the document is right and this decision agrees:** its `version = "1"` is a caret requirement
   that admits 1.53.1, exactly as *Compatibility* above explains for axum; the two differ only
   on the feature list, not on the runtime or its version line.
6. **Whether Rust needs py's lazy configuration fallback.** All five raws say no, for the same
   reason. Recorded as `BASELINE-REVIEW: F330`; no disagreement to settle.
7. **Router registry versus native composition.** Codex, opus, openai and gemini all say
   native; perplexity does not raise it. Settled by the reference implementation read at
   source: `rust-lang/crates.io` has no `ROUTERS` list and no registration loop. Recorded as
   `BASELINE-REVIEW: F331`.
8. **Framework figures where the raws disagree.** `rocket`'s MSRV — gemini 1.89.0, opus 1.64 —
   settled at **1.64** by the registry. `ntex`'s newest non-yanked version — opus 3.12.3 with
   `rust-version` 1.88 — is **4.0.0-beta.10 (2026-09-12), `rust-version` 1.95** under the
   prompt's rule as written ("newest with `yanked: false`"); the same reading makes `tide`'s
   newest **0.17.0-beta.1 (2021-12-06)** rather than opus's 0.16.0 (2021-01-29). Both gaps are
   a **field-rule reading, not a data error on either side**: the opus raw appears to have
   applied a newest-*stable* filter that the prompt's rule does not contain. Neither crate is
   recommended, and both are excluded on grounds that hold under either reading. `watchexec-cli` — openai 2.5.1, codex and opus 2.7.2 — settled at **2.7.2** by the
   registry. Where codex's and opus's 2026-09-12 figures overlap they agree with each other and
   with this run's 2026-09-13 snapshot up to one day's counter drift (for example axum's 90-day
   downloads 115,597,652 → 114,795,000 and stars 27,095 → 27,100); the figures reported in this
   decision are **this run's**, with this run's retrieval date.

**Unproven here; P03's to prove in the real template.** Each row is a claim this decision makes
that no check in this run establishes, paired with what would establish it. A row that fails in
implementation sends the decision back for revision against this recorded research, not back to
research.

| Claim | Status | What would prove it |
|---|---|---|
| The web handler returns the library's own `serde` types over a real listener, with no mirror struct, byte-identical to the CLI's output (R01 acceptance criterion 6) | **Unproven here.** The opus raw reports two passing tests covering exactly this, in-process and over a bound listener; those are engine-reported and were not re-executed, because executing them means building the recommendation. | A template integration test: a real HTTP GET to a bound listener whose body decodes into the library's `Vec<Project>`, compared against the CLI's rendered output for the same query. |
| `build_router(state)` is the only constructor, and a handler asking for an unregistered substate fails to compile | **Partly proven.** The state bound itself is verified (check 1); the compile-failure demonstration is not. | A `compile_fail` doctest in the template showing a handler requesting a substate `AppState` has no `FromRef` impl for, and asserting the error. |
| The entrypoint drains in-flight work on SIGTERM and exits **143** within the configured window, exits **130** on the SIGINT path, and exits **1** when a request never completes | **Unproven.** The enabling fact — axum supplies no deadline — is read at source (check 3); the three behaviors are not exercised, and neither is the signal-kind threading the exit integers need. R67's own unproven list carries the same item ("*The web surface's `SIGTERM` drain to 143* … only the exit integer is shared, so the risk is low but the path is unbuilt"). | Three template tests: one that begins a slow request, sends SIGTERM, and asserts both the response completing and exit **143** inside the window; its SIGINT twin asserting exit **130**; and one with a permanently blocked request asserting the `GracefulShutdownTimedOut` branch and exit **1**. The opus raw reports a passing test for the unbounded-drain half only, and names no exit code. |
| The serve binary's shutdown future reports **which** signal fired, so `main` can map 130 versus 143 | **Unproven, and not implementable as the recorded snippet is written** — it takes `S: Future<Output = ()>`. The enabling fact is the two-source mechanism already recorded under F338: `tokio::signal::ctrl_c()` and `tokio::signal::unix::signal(SignalKind::terminate())` are separate listeners selected over, as the reference implementation does (`src/bin/crates-io/server.rs` at `3df99c2`, asserted in `assert-figures.log` section F as "selects over SIGTERM via tokio::signal::unix"). **No check in this run asserts that the two futures are distinguishable at the type level**; that is why this row exists. | A template test asserting the two integers (row above), which fails if the signal kind is erased; P03 threads the kind (or R67's `Exit` value) out of `shutdown_signal()` instead of `()`. |
| The serve binary satisfies the CLI Design Standard's required global core | **Unproven.** The rule and its scope are read at the standard (R4.1, its header scope line, Appendix A's "§4 … unchanged"); no binary exists to run, and the R9.14 conformance fixture has not been written. *(Revision 6 gave the second ground as "**R60 has not selected the parser**"; that wording is superseded by the owner's acceptance of R60 revision 7 on 2026-09-15 — `clap` 4.6.6 with the `derive` API, recorded in `docs/port/OWNER-ACCEPTANCES.md`, publication pending — and the row stays unproven on the grounds that remain true.)* | The R9.14 conformance fixture named under *Validation strategy*: `<app>-serve --help` and `<app>-serve -V` each printing to stdout and exiting `0`, `-V` printing the single `<app>-serve <semver>` line R4.6 fixes, and the four remaining core options accepted. |
| The stack compiles and tests on both `target-os-matrix` legs and at the MSRV floor | **Unproven.** Only the macOS host at rustc 1.98.0 was exercised here; the Linux leg and the 1.96 leg were not. | The template's CI matrix (R11): `cargo test --workspace --locked --features web` on `ubuntu-latest` and `macos-latest`, plus a `cargo check` leg pinned to the declared `rust-version`. |
| The web feature's wall-clock build cost and binary size | **Unproven and not measured here** — measuring them honestly means building the recommendation. The opus raw's figures (5.69 s → 9.28 s wall, 7.12 s → 25.61 s user CPU, release binary 2,001,600 bytes / 1,574,392 stripped) are engine-reported. Only the dependency-count half (12 → 52 packages) is reproduced here. | A timed clean and incremental build of the real template on each CI runner, and `cargo build --release` plus a size measurement of the stripped serve binary. |
| The dev recipe serves with console-formatted logs and restarts on a source edit | **Unproven, and blocked on R58.** The tool's capabilities are verified (check 5); the recipe's behavior is not, because the environment variable's name and semantics are R58's and unpublished. | Once R58 publishes: `just serve` answering `GET /healthz` with console-formatted logs on stderr, a source edit producing one restart, and the same binary outside the recipe emitting the production structured profile. |
| The exact `cargo` argv bacon composes from `-j run-long --features web -- --bin <app>-serve` | **Inferred, not observed.** Each link is read at source — the job's `["cargo", "run"]` tokens, post-`--` arguments appended to them, and `--features` applied after — but bacon has no dry-run mode, so the assembled command line was never printed. | Running the recipe once in the real template and reading the command bacon reports, or `bacon` with `RUST_LOG=debug`, which logs `command: {:#?}` in `src/mission.rs`. |
| A `bacon.toml` `kill` override makes the dev restart run the production SIGTERM drain | **Unproven.** That bacon's default is SIGKILL and that a `kill` override exists are both read from its published configuration reference; that the override produces a clean drain of `cargo run`'s grandchild process is not exercised. | A template check that edits a source file under `just serve` and observes the old process logging its graceful-shutdown path rather than dying silently. |
| `actix-web` does not win on a representative instrumented workload | **Unproven and deliberately unmeasured.** No public benchmark measures the required path, and the TechEmpower payload was unretrievable on 2026-09-12 (opus raw). | The two-workload benchmark openai's raw specifies — an adapter ceiling and a service-like run with R75/R78/R79's layers and a local collector — reporting p50/p95/p99, throughput, CPU-seconds per million requests, peak RSS, binary size and build times on identical hardware. Only a material advantage there reopens the framework choice. |
| `axum`'s and `bacon`'s macOS support beyond the pinned versions tested here | **Unproven beyond `axum` 0.8.9 and `bacon` 3.25.0 on macOS 26.4 aarch64.** Neither project's CI covers macOS. | The template's own `macos-latest` CI leg, continuously. |
| `unsafe` posture of `tokio` and of the unrecommended candidates | **Unproven here.** `axum`'s is verified (`unsafe_code = "forbid"`, zero occurrences in `src/`); tokio's 1,066 occurrences are the opus raw's count, not recounted; the remaining candidates were not inspected by anyone. | `cargo geiger` over the template's resolved tree, if a posture question ever arises; none of the uninspected candidates is recommended. |

**Uncertainty and coverage.** Every required top-level field and every member field of this
decision is supported by at least the codex, opus and openai raws; gemini and perplexity add
the dev-reload position that the licence ruling vindicated and independent agreement on the
framework, the feature shape and F330, and no field is left unsupported. Remaining uncertainty
beyond the unproven table: the resolved-tree MSRV figure of 1.80 is read from declared
`rust-version` fields, and nine transitive dependencies declare none, so it is a floor on what
is *declared*, not a proof that the tree compiles at 1.96 — the template's MSRV CI leg is what
would prove that. The population figures are a single snapshot at `2026-09-13T07:57:55Z` and
will drift. The `AppState` field list stays medium-confidence until R77 defines the settings
type and R58 the logging contract.
