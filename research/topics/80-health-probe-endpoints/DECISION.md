# 2026-09-27 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 7)

**Revision note (revision 7) — a flag-day parameter swap; the recommendation does not move.**
Owner decision Q3.A (flag day now) re-binds every consumer of R69's
`web-extra-surface` at once. R69 revision 11
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, sha256
`2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`) is approved
for re-accept under Q3.A. R69's owned value changed at revision 10 under owner
ruling W1-R02: the web surface is the workspace member `crates/web`, whose
`axum` and `tokio` are non-optional in `crates/web/Cargo.toml`, and the root
package reaches it through `web = ["dep:rs-launch-blueprint-web"]`. Revision 11
carries that value unchanged at its line 1885. Revision 6 of this decision still
assumed revision 9's text. Revision 7 adopts W1-R02's shape through R69
revision 11. Revision 6 is preserved byte-for-byte as
`review/R80-r6-snapshot.md` (sha256 `4b63412a…`, check `V1`). This revision was
written on 2026-09-27 by an Opus-seat context (`claude-opus-5-5`) that produced
none of this item's raw reports, under the Q23 scope of RUNBOOK section 7: the
swap and its dependent prose only.

| What | Revision 6 | Revision 7 | Check |
|---|---|---|---|
| `- assumes web-extra-surface = ` | revision 9's value: `src/web/`, `web = ["dep:axum", "dep:tokio"]` with both crates optional, file-level `cfg` on the web tests | R69 revision 11's line-1885 value, byte-identical after the prefix: `crates/web/src/`, `web = ["dep:rs-launch-blueprint-web"]`, `axum` and `tokio` non-optional in `crates/web/Cargo.toml`, web tests in `crates/web/tests/` with no file-level `cfg` | `O3`, `O5` |
| The `CONFLICT:` paragraph and the prose note beside that line | the line held the registry's revision-9 bytes; R69 revision 10 was unpublished; a publication lag | the line holds R69 revision 11's bytes under Q3.A, ahead of the registry row, which the flag-day publication rewrites | `O5` |
| Citations of R69's owned line | line 1791 of revision 10 | line 1885 of revision 11 | `O5`, `V6` |

**The revision-11 value breaks no claim.** This decision's design already used
revision 10's paths — `crates/web/src/routes/ops.rs`, `crates/web/src/lib.rs`,
`crates/web/tests/`, `crates/web/Cargo.toml` — and revision 11 moves none of
them. Only the description of the line changes. The recommendation
`probe-contract/v1`, every finding, verdict and figure the prose states, and
the `re-verify:` line are unchanged.

**Evidence touched, and why.** `O3` compared all seven `- assumes` values with
the registry. The registry row still carries revision 9's text until the
flag-day publication. `O3` therefore now compares six values with the registry
and `web-extra-surface` with R69 revision 11's line 1885, bound by the sha256
above, and prints the registry row's current form as information. `O5` now
asserts that owned line at 1885, bound the same way, and no longer asserts the
registry's revision-9 form. `V6` reads line 1885. The header bump re-baselines
the three H1 checks, `C2`, `R1` and `V1`, and `V1` also pins the revision-6
snapshot. The digest tables `C1`, `R6` and `V13` re-pin the edited scripts and
the re-recorded logs. The four logs were re-recorded in the order
`## Empirical check` states, and `shellcheck` on the four edited scripts is
recorded in `shellcheck-r7.log`, which is empty. The four logs' reproduction
was repeated, and its eight rerun diffs replace the prior files of those names. The check counts
do not move: 14 in
`check-standard-r4.sh` and 113 across the six scripts. `check-probe.sh` and
`check-live.sh` assert nothing about the value and were neither edited nor
re-run.

**Two failures recorded, not repaired.** `check-standard-r4.log` now records
**12 PASS, 2 FAIL, 0 SKIP**. `V3` and `V4` fail on drift outside this item's
`review/` directory. The controller's Q23 pack re-freeze (2026-09-28T03:12:17Z)
added a second migration event to `manifest.json` that carries no `from` key.
`V3`'s reader raises `KeyError: 'from'` on it, and `V3` also expects exactly one
migration event. `V4` reads the manifest's prompt hash from `V3`'s output, which
the exception cut short. The frozen prompt is byte-identical to the live prompt
(both `584f0994…`). Under RUNBOOK section 7.1 this is drift, so it is recorded
here and not repaired by this revision.

**Rerun logs rewritten.** `check-offline.r2-rerun.log`,
`check-standard-r2.r3-rerun.log` and `check-standard-r3.r4-rerun.log` are
rewritten by every run of their parent scripts, so revision 6's bytes of them
are gone. No check pins them.

**Revision note (revision 6) — an evidence repair; the recommendation does not move.**
The empirical audit of revision 5 (sha256
`6ee8ad17642a847856766e914b45eac8727525f64a9f6f7159f6e1e7be97a6d9`),
`review/audit-codex.r5.md`, returned `reject` on two findings. The judgment
audit of revision 5 approved. Revision 6 repairs both findings and changes no
finding, verdict or recommendation. Revision 5 is preserved byte-for-byte as
`review/R80-r5-snapshot.md` (check `V1`). This revision was resynthesized on
2026-09-27 by a fresh Opus-seat context (`claude-opus-5-5`) that produced none
of this item's raw reports. It read the empirical audit in full, revision 5,
line 9 of `review/audit-claude.r4.md`, the run's evidence and RUNBOOK section 5.

| Finding | What was wrong | Repair | Where, and the check that holds it |
|---|---|---|---|
| Codex finding 1, observed failure | `V3` indexed `empirical_auditor_overrides.R80` in `research/EXECUTION.json`. The live policy no longer lists R80 in that map, so `V3` raised `KeyError: 'R80'` and failed, and `check-standard-r4.sh` returned 13 PASS and 1 FAIL against a log that said 14 and 0. `## Engines` also named a `claude` empirical seat that the live policy no longer assigns | `V3` now reads the seat the way `scripts/research_validation.py` line 705 does, `seat_overrides.get(item, "codex")`, and expects `codex`. `## Engines` states that R80 has no seat override and so takes the default `codex` empirical seat. `check-standard-r4.sh` was re-run and its log re-recorded at **14 PASS, 0 FAIL, 0 SKIP** | `## Engines`; `check-standard-r4.sh`, `check-standard-r4.log`; `V3` |
| Codex finding 2, evidence support | Revision 5's EF-1 row said revision 4's log recorded the grep error "six times" and bound that count only to "the audit". The revision-4 log was never committed and was re-recorded in place, so the count had no named record | The count now cites its one surviving record, `review/audit-claude.r4.md` line 9, which quotes the error at the revision-4 log's lines 32, 34, 36, 38, 40 and 42 | revision 5's note, EF-1 row; no check, because the record is an audit file |

**The header bump again forces the three H1 checks and the two digest tables to
move.** `C2`, `R1` and `V1` now pin the revision-6 title, and `V1` also pins
`review/R80-r5-snapshot.md` by its sha256 and its H1. `R6` re-pins
`check-standard-r2.sh` and `check-standard-r2.log`; `V13` re-pins those two
plus `check-standard-r3.sh` and `check-standard-r3.log`. The three standard
scripts' logs were re-recorded, and their reproduction repeated, in the order
`## Empirical check` states. Every other script, pinned log, snapshot and
probe source is unchanged, and no other check was edited.

**What did not change:** the recommendation `probe-contract/v1` and everything
revision 5's note lists as unchanged; every figure the prose states; and the
check counts, 14 in `check-standard-r4.sh` and 113 across the six scripts.

**Revision note (revision 5) — an evidence repair; the recommendation does not move.**
The empirical audit of revision 4 (sha256
`f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8`),
`review/audit-claude.r4.md`, returned `reject` on one finding, EF-1. The
judgment audit of revision 4 approved. Revision 5 repairs EF-1 and changes no
finding, verdict or recommendation. Revision 4 is preserved byte-for-byte as
`review/R80-r4-snapshot.md` (check `V1`). This revision was resynthesized on
2026-09-27 by a fresh Opus-seat context (`claude-opus-5-5`) that produced none
of this item's raw reports. It read the empirical audit in full, revision 4, the
run's evidence and RUNBOOK section 5.

| Finding | What was wrong | Repair | Where, and the check that holds it |
|---|---|---|---|
| EF-1, evidence support | `V8`, which revision 4 cited as the static proof for EA-3, could not fail. Each of its two patterns began with an unescaped pipe character, which ERE reads as an empty alternative. `/usr/bin/grep` rejected the pattern with `empty (sub)expression` and exit status 2 and printed no count. A fallback that ignored grep's status hid the error, and the empty count added as 0. Revision 4's `check-standard-r4.log` recorded the error six times, next to six blank counts, at its lines 32, 34, 36, 38, 40 and 42, as `review/audit-claude.r4.md` line 9 quotes them. Revision 5 re-recorded that log in place, and the revision-4 log was never committed, so that audit line is the only surviving record of the failing run | Both leading pipes are escaped. A grep status of 2 or more, or a non-numeric count, now fails `V8`. A positive control, one here-string line that pipes into `grep -q`, must count exactly 1 | `check-standard-r4.sh`, `check-standard-r4.log`; `V8` |

**What the repaired `V8` observed.** The positive control counts **1** with grep
status 0. Each of the six scans prints a count of **0** with grep status 1,
which is grep's "no line matched" status. The re-recorded
`check-standard-r4.log` contains no grep error. The property `V8` asserts
therefore held in revision 4 as well: no assertion in the six scripts pipes into
an early-exiting grep. The audit's independent scan found the same 0 in each
script. Only the evidence for that property was vacuous, and revision 5 makes
it executable.

**The header bump forces three re-baselined checks and two re-pinned digest
tables.** Three checks compare the H1 with a literal title: `C2` in
`check-standard-r2.sh`, `R1` in `check-standard-r3.sh` and `V1` in
`check-standard-r4.sh`. Revision 5's H1 falsifies all three, so each now pins
the revision-5 title. `V1` also pins `review/R80-r4-snapshot.md` by its sha256
and its H1. Editing the revision-2 and revision-3 scripts changes their
digests. `R6` therefore re-pins `check-standard-r2.sh` and
`check-standard-r2.log`, and `V13` re-pins those two plus
`check-standard-r3.sh` and `check-standard-r3.log`. The three logs of the
standard scripts were re-recorded in the order `## Empirical check` states. The
other 18 artifacts `V13` pins are the bytes revision 4 recorded, unchanged.
`shellcheck-r4.log` is still empty after `shellcheck` re-ran on all six scripts,
so its pinned digest holds.

**What did not change:** the recommendation `probe-contract/v1` and everything
revision 4's note lists as unchanged; every figure the prose states; and the
check counts. `check-standard-r4.sh` still carries 14 checks and the six scripts
113, because revision 5 repairs `V8` rather than removing it.

**Revision note (revision 4) — an audit repair; the recommendation does not move.**
Both audits of revision 3 (sha256
`184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`) returned
`reject`. The judgment audit, `review/audit-fable.md`, raised four findings. The
empirical audit, `review/audit-claude.md`, raised five. Revision 4 repairs all
nine. Revision 3 is preserved byte-for-byte as `review/R80-r3-snapshot.md`
(check `V1`). This revision was resynthesized on 2026-09-27 by a fresh
Opus-seat context (`claude-opus-5-5`) that produced none of this item's raw
reports. It read both audits in full, both engine reports, revision 3, the
run's evidence and RUNBOOK section 5.

| Finding | What was wrong | Repair | Where, and the check that holds it |
|---|---|---|---|
| Judgment 1 (JF-2, JF-3, JF-9), blocking | `## Engines` described a Codex + Opus run. The manifest and the prompt require Muse + Opus, and `raw/muse.md` sat on disk unadjudicated | The substitution is recorded with its authority. The Muse leg is represented with its digest and its collection gap. Its five material disagreements, and four lesser ones, are adjudicated with evidence this decision already held | `## Engines`; `V2`–`V5` |
| Judgment 2 (JF-5, JF-7), blocking | R22 was called open with no decision. R22 revision 1 is owner-accepted, and its constant sits in the facade, which `crates/web` cannot import under R69 revision 10 | R22's accepted revision is cited. R02 revision 2 is recorded as having fired R22's own re-verify trigger. The package question is handed to R22 and R02 with two options and decided by neither | the version paragraph under `### Principles and implementation`, the migration table, `re-verify:`; `V6` |
| Judgment 3 (JF-1, JF-8), low | three miscounts in `## Empirical check` | corrected, and each figure is now asserted against its artifact | `## Empirical check`; `V10`, `V11` |
| Judgment 4 (JF-7), low | R55 and R57 were described as unpublished | now "published", and `O28` reads the published texts | `### Principles and implementation`, `## Engines`; `O28`, `V7` |
| EA-1, observed failure | `O17` read R05's mutable H1. R05's working file now holds an unaccepted later revision, so three scripts failed | `O17` binds R02, R05 and R03 by the sha256 their owner-acceptance rows record. `re-verify:` gains a re-bind trigger | `check-offline.sh`; `O17` |
| EA-2, evidence support | the `q=liveness` denominator was misquoted, 9 higher than the log and the snapshot, which both say 28,347 | corrected at both sites, and "advance continuously" is withdrawn, because that figure fell | `## Empirical check`, `## Engines`; `V10` |
| EA-3, observed failure | 33 assertions in three scripts piped a variable into `grep -q` under `set -o pipefail`, which is a SIGPIPE race | every site reads a here-string or a file, and a static check proves none remains | `check-offline.sh`, `check-standard-r2.sh`, `check-standard-r3.sh`; `V8` |
| EA-4, reproducibility | no committed `Cargo.lock`, so the stated "`--offline` from the warm cache" build did not reproduce and two transitive crates drifted | lockfiles are committed, pinned to revision 1's measured `hyper-util 0.1.20` and `smallvec 1.16.1`, and every cargo call passes `--locked` | `probe/manifests-a/Cargo.lock`, `probe/manifests-b/Cargo.lock`; `V9` |
| EA-5, evidence support | the prose said the override heading appears 10 times; the log said 11 | the prose states the current count, and a check compares it with the file | `## Empirical check`; `V10` |

**The byte-identity promise ends here, by the audits' own repair orders.**
Revisions 2 and 3 each promised that every earlier evidence artifact stayed
byte-identical. EA-1, EA-3 and EA-4 require editing four of those scripts:
`check-offline.sh`, `check-probe.sh`, `check-standard-r2.sh` and
`check-standard-r3.sh`. Revision 4 edits them in place and re-records their
logs. It also re-baselines the checks that pinned an earlier revision's text:
`O25` (shape), `C2` and `R1` (the H1), `C4` (the override name), and the digest
tables in `C1` and `R6`. The re-runs `C9` and `R7` previously expected named
failures and now expect none. The earlier bytes remain in git at revision 3's
commit `53b13f45`. The new `check-standard-r4.sh` pins every revision-4 artifact
by sha256 in check `V13`, which restarts the promise for any later revision.
`check-live.sh` has no racy site, so its script and its log are unchanged.

**What did not change:** the recommendation `probe-contract/v1`; the stack and
every version pin; `run_diagnostics` in `crates/core`, its signature and its
three-state `CheckStatus`; the latch; the `spawn_blocking` bridge; the liveness
field list and the declined uptime field; every architectural alternative and
its disposition; every rule verdict, the conformance note, and the override's
argument and four options; the seven `- assumes` lines; and the absence of any
`- owns` or `CONFLICT:` line. Muse's alternative stack is answered by evidence
this decision already held, so nothing was researched again.

**Revision note (revision 3) — a mechanical renumber, and nothing else.**
Revision 2 and R77's revision 2 each ran a scoped "next free override number"
search minutes apart and each allocated **`OV-04`**. The controller now allocates
override numbers rather than leaving items to search: **R77 keeps `OV-04`, and
this item's override is `OV-05`** (ledger entry *"OVERRIDE NUMBER COLLISION,
2026-09-18"*). Revision 3 renames it and does nothing else.

**What changed, exhaustively:** the H1; this note; the fifteen occurrences of
`OV-04` that named *this item's* override, at revision 2's lines 28, 528, 530,
531, 532, 537, 551, 585, 609, 611, 613, 653, 752, 1231 and 1237, enumerated by
search before any edit and re-checked by search afterwards; the allocation
paragraph, which now records the controller's assignment instead of this item's
own search; and the history below. `OV-04` still appears eleven times, all of
them deliberate and none of them naming this item's override: four in this note,
four in the allocation paragraph and three in the history, where the string names
**R77's** override, revision 2's superseded choice, or the collision itself. The
checkable claim is the narrow one — **the heading form `OVERRIDE (…)` never
carries the old number, and `OVERRIDE (OV-05)` is this decision's only override
heading** — and check `R2` asserts it by counting both forms. (This sentence
deliberately does not spell the old heading out: an earlier draft did, which made
the claim count itself and fail, and `R2` caught it.)

**What did not change:** the recommendation, the override's argument and its
four options, every rule verdict, the conformance note's content, every version
pin, the seven `- assumes` lines, the absence of any `- owns` or `CONFLICT:`
line, and **every evidence artifact of revisions 1 and 2** — `check-offline.sh`,
`check-probe.sh`, `check-live.sh`, `check-standard-r2.sh`, all of their logs,
diffs, snapshots and probe sources are byte-identical, asserted by digest in
`check-standard-r3.sh`.

**Revision note (revision 2).** Owner ruling **W2-REST** of 2026-09-18
(`docs/port/OWNER-REVIEW.md`, heading *"2026-09-18 — the REST API Design Standard
binds the HTTP surface (W2-REST)"*) makes the organisation's **REST API Design
Standard v2.0.0** bind this template's HTTP surface the way the CLI Design
Standard binds its CLI. Revision 1 (sha256 `fde7de28…`) was written before that
ruling and never audited, so this is a **pre-audit revision**: revision 1's three
evidence scripts, their logs, their rerun and archive diffs, and all five probe
sources are **byte-identical** and were not re-run (asserted, file by file, by
check `C1`). Everything revision 2 adds is in new `*-r2` files.

The standard is read at the pin the ruling names: repository
`/Users/stevemorin/c/rest-standards`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, read with
`git -C /Users/stevemorin/c/rest-standards show 71bd813c1cf61286586b4ee41ed83ff065e5c8d9`.
Twenty-six rules are quoted at their line numbers and one absence is counted;
each is asserted at the blob by checks `S1`–`S27`, so a rule whose text moves
fails this decision rather than being silently re-read.

**The recommendation moves, which is allowed because nothing here is accepted
yet.** Rule **R7.1** is a MUST that revision 1 did not meet, so
`Cache-Control: no-cache` is now part of the contract for both probe responses,
executed by checks `P1` and `P2`. Rule **R5.17** adds a redaction obligation to
the diagnostic report's `detail` field. Rules **R5.13** and **R5.16** sharpen the
requirement this item places on R70 from "the report must be reachable" to a
named member set plus a catalogued code. **One `OVERRIDE (OV-05)`** is recorded,
covering the four rules the unversioned probe paths cannot satisfy, and **two
SHOULD deviations** are recorded in the conformance note. Nothing else moves: not
the stack, not a version pin, not the shared-function placement, not the latch,
not a parameter line, and not one byte of revision 1's evidence.

Synthesized 2026-09-18 by a fresh context that produced none of this item's raw
reports. Inputs read in full: `inputs/prompt.md` (binding), `inputs/PARAMETERS.md`
and the live `docs/port/PARAMETERS.md`, `inputs/owner-reference-axum-companion-stack-2026-09-16.md`
with `docs/planning/p02/owner-decisions.md` section 11, `docs/port/README.md` for
its closed verdict vocabulary (`ADOPT` for F308; `DIVERGENT` for F328 and F329),
`docs/port/COMMONALITY.md` rows F303/F308/F320/F328/F329/F337, `research/CLAUDE.md`,
and the single engine report then registered, `raw/opus.md`. Revision 4 adds the
Muse report, `raw/muse.md`; see its note above and `## Engines`. No template code exists in
this repository and none was written here; every executed check runs against a
throwaway workspace created under `$TMPDIR` and deleted, or against a live source.

## Decision

**Every decision in this programme is a proposal validated in the implementation
phase** (owner ruling, 2026-09-10). This one records what the research found and
what it recommends; P03 builds the template and its CI proves the recommendation.
The list of what P03 must validate is under `## Engines`. A decision that does not
survive implementation is revised against this recorded research, not researched
again from scratch.

**Recommendation — `probe-contract/v1`: one shared synchronous diagnostics
function in `crates/core`, two hand-written axum handlers in
`crates/web/src/routes/ops.rs`, and an `AtomicBool` readiness latch flipped by
R69's shutdown signal. No new crate, at any version.**

Concretely:

- `GET /healthz` is a **stateless** handler — it declines axum's `State`, so it
  can reach no dependency, no lock and no pool by construction — answering `200`
  with `{"status":"ok","version":…,"os":…,"arch":…}`, built from R22's accepted
  `VERSION` constant, evaluated so that it reports the distributed artifact's
  version (which package holds it is handed to R22 and R02 below), and
  `std::env::consts::{OS, ARCH}`, under `Cache-Control: no-cache` (R7.1, check
  `P1`).
- `GET /readyz` reads the readiness latch, then calls
  `rs_launch_blueprint_core::diagnostics::run_diagnostics` — the same function
  the CLI's `doctor` command calls — through `tokio::task::spawn_blocking`. It
  answers `200` with the serialized report when the process is accepting and no
  check is `error`, and `503` otherwise, carrying the report in the body through
  R70's problem envelope (see the standing constraint on R70 below). Both branches
  carry `Cache-Control: no-cache` (R7.1, check `P2`), and every `detail` string in
  the report is redacted of filesystem paths, internal hostnames and dependency
  detail before it reaches the wire (R5.17).
- Both paths are **unversioned**, per F308 applied rather than re-derived; both
  accept `GET` and `HEAD`; both live inside the optional `crates/web` member and
  therefore vanish from a default build.

**Ledger rows this settles.** **F328** (liveness endpoint reports version +
runtime info) and **F329** (readiness endpoint runs the same diagnostics as the
CLI `doctor` command), both `DIVERGENT`, both owned by R80
(`docs/port/COMMONALITY.md:332-333`, asserted by check `O7`). **F308** (`ADOPT`,
owned by no item) is applied to the two paths, not re-derived, exactly as the
prompt instructs. No `BASELINE-REVIEW:` finding is raised: the one `ADOPT` row
this item touches is applied unchanged, and the design findings below concern
F329, a row this item owns the answer to.

**Fitness gate 1** is recorded, for every candidate named in this decision, as:

inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool

The reason is that the owner struck the
gate from every item's evaluation, knowingly extending it to crates compiled into
the shipped artifact (`docs/port/OWNER-REVIEW.md`, asserted by check `O11`). The
licence strings in the figures table below are recorded as facts about the crates,
not as a compatibility verdict. `raw/opus.md` and `raw/muse.md` each answer gate 1 per candidate; those
verdicts are **not carried**. What the ruling does not touch is untouched here:
this repository's own `license = MIT OR Apache-2.0` expression stands, and nothing
in this recommendation commits a third-party file into the repository.

### The recommendation — one stack

Five members. Two are decided by this item; three are consumed from
owner-accepted decisions and are re-verified here rather than re-selected.

| # | Member | Version | Status in this decision | What it supplies |
|---|---|---|---|---|
| 1 | `rs_launch_blueprint_core::diagnostics` (the shared contract — no crate) | — | **decided here** | `CheckStatus`, `Check`, `Diagnostics`, `Diagnostics::has_error`, `run_diagnostics`; the one place the check list exists |
| 2 | `std` build identity (`std::env::consts::{OS, ARCH}` + Cargo's compile-time version — no crate) | — | **decided here** | the liveness payload's fields, with no build script and no git dependency |
| 3 | `serde` | 1.0.229, `features = ["derive"]` | consumed from R66 | the derived wire shape for both payloads |
| 4 | `axum` | 0.8.9, default features | consumed from R69 revision 10 | `Router`, `routing::get`, `State`, `StatusCode`, `Json`, `http::header::CACHE_CONTROL`, and — free — `405` with `Allow: GET,HEAD` (which R5.11 makes a MUST) and `HEAD` served by the `GET` handler |
| 5 | `tokio` | 1.53.1, features `rt-multi-thread, net, signal, macros, time, sync` | consumed from R69 revision 10 | `spawn_blocking`, R05's bridge from the async handler to the synchronous core |

The **marginal cost of this recommendation is zero crates**: every mechanism is
`std`, or one of the three crates R69, R66 and R05 already put in the tree. Check
`C11` shows that the member holding `run_diagnostics` resolves `serde v1.0.229`
and its four proc-macro dependencies and names no web crate at all; check `C9`
shows a default build's normal dependency graph contains `axum` on **0** lines.

**Figures, collected exactly as the prompt's table prescribes** — 90-day downloads
= `crate.recent_downloads` and all-time = `crate.downloads` from
`GET https://crates.io/api/v1/crates/<name>`; last release = the newest
`yanked: false` entry from `GET https://crates.io/api/v1/crates/<name>/versions`;
stars, `archived` and `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`;
open issues from `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`, never `open_issues_count`). All retrieved **2026-09-18 (UTC)**,
GitHub at no more than one call per 20 s. Download counters move between runs; see
the comparison rule under `## Empirical check`.

| Crate | 90-day | all-time | last release | declared `rust-version` | licence (fact, not a gate) | stars | archived | open issues |
|---|---|---|---|---|---|---|---|---|
| `serde` | 314,208,639 | 1,410,307,353 | 1.0.229, 2026-07-18 | 1.56 | MIT OR Apache-2.0 | 10,826 | false | 319 |
| `serde_json` | 317,743,616 | 1,313,719,716 | 1.0.151, 2026-07-20 | 1.71 | MIT OR Apache-2.0 | 5,635 | false | 191 |
| `axum` | 118,234,751 | 475,506,585 | 0.8.9, 2026-04-14 | 1.80 | MIT | 27,176 | false | 33 |
| `tokio` | 228,862,107 | 978,381,970 | 1.53.1, 2026-07-20 | 1.71 | MIT | 33,173 | false | 320 |
| `built` | 18,238,136 | 63,168,750 | 0.8.1, 2026-05-21 | 1.87 | MIT | 198 | false | 8 |
| `vergen` | 8,605,373 | 52,213,287 | 10.0.3, 2026-08-24 | 1.96.0 | MIT OR Apache-2.0 | 473 | false | 4 |
| `shadow-rs` | 2,184,341 | 10,812,524 | 2.0.0, 2026-04-23 | **none declared** | MIT AND Apache-2.0 | 702 | false | 8 |
| `git-version` | 5,528,772 | 24,871,629 | 0.3.9, **2023-12-13** | **none declared** | BSD-2-Clause | 131 | false | **absent (HTTP 422)** |

The `serde`, `serde_json`, `axum` and `tokio` GitHub rows are **carried from
`raw/opus.md` without re-collection**; only their crates.io pins were re-verified
here (check `L1`). The four build-metadata repositories' GitHub rows **were**
re-collected (check `L9`) because a gate-2 exclusion turns on them.
`git-version`'s open-issue figure is **absent, not estimated**: the issue-search
endpoint answered HTTP 422 *"The listed users and repositories cannot be
searched"* for `repo:fusion-engineering/rust-git-version` on both 2026-09-18
collections, while the plain repository endpoint answered 200 for the same path.
The prompt forbids substituting `open_issues_count`, so nothing is substituted.

**Fitness gates 2 to 6**, answered per candidate before popularity was weighed.
Gate 2 (declared MSRV within `msrv-policy`) **excludes `shadow-rs` 2.0.0 and
`git-version` 0.3.9**: `GET https://crates.io/api/v1/crates/<name>/versions`
returns `rust_version: null` for the newest non-yanked version of each (check
`L2`), and the owner withdrew the provisional "unproven rather than failed"
reading in favour of the auditors' strict one
(`docs/planning/p02/owner-decisions.md`, *"Two things you should know"*), under
which a failed gate excludes. Gate 3: `https://rustsec.org/packages/<name>.html`
answers **404** for `serde`, `serde_json`, `axum`, `built`, `vergen`, `shadow-rs`
and `git-version`, and **200** for `tokio`, whose newest entry
`RUSTSEC-2025-0023` lists an open-ended patched range `>=1.44.2` that 1.53.1
satisfies — with `atty` answering **200** as a positive control, so the 404s are
evidence of absence rather than of an outage (checks `L3`, `L4`). `unsafe`
posture: axum's workspace sets `[workspace.lints.rust] unsafe_code = "forbid"`
and `axum/Cargo.toml` opts in with `[lints] workspace = true`, so axum forbids
`unsafe`; tokio uses `unsafe` extensively in its runtime internals and does not
forbid it, which is unavoidable for a work-stealing scheduler and is mitigated by
its Miri/loom suite and its public advisory record. Both postures are carried
from `raw/opus.md`; the axum manifest read was not re-executed here. Gate 4:
every executed check in this decision ran on **macOS 26.4 `arm64` only**;
`ubuntu-latest` was **not** exercised, and each member's Linux answer rests on the
crates' own CI and on R66's and R69's prior records. Gate 5: default features for
axum, the six-feature list R69 owns for tokio, `derive` only for serde; the
async-runtime coupling is tokio, and this item adds no feature to any of them.
Gate 6: qualitatively, axum and tokio dominate the gated surface's compile time,
and this item adds two handler functions, three structs and one `AtomicBool` to
it. Revision 1's cold compile of the probe workspace printed
`Finished \`test\` profile [unoptimized + debuginfo] target(s) in 16.48s`.
Revision 4's recorded run shared a private `CARGO_TARGET_DIR` with earlier runs,
so its dependencies were already built, and `check-probe.log` shows `1.46s`. Both
figures are **observations, not assertions** — they are lines that differ between
reruns, and no check depends on them. **No latency, throughput,
memory or binary-size figure is claimed anywhere in this decision; none was
measured.**

**Excluded, and on which ground.** `shadow-rs` 2.0.0 and `git-version` 0.3.9 are
excluded **by gate 2**, above. `built` 0.8.1 and `vergen` 10.0.3 are excluded
**on fit, which is not a fitness gate and is labelled as such**, because both
require a Cargo build script and R49's owner-accepted `build-tool-output-shape`
states *"no build.rs and no build-orchestration crate"* (check `O6`, quoted from
the live registry row). The requirement is read from the maintainers' own
documentation rather than inferred: `built`'s README shows its usage under the
comment `// In build.rs`, `vergen`'s says its tools are configured in cargo build
scripts, and `shadow-rs`'s instructs creating a `build.rs` (check `L6`). **No
`CONFLICT:` line is raised for this**: the recommendation does not need R49's
value changed — it needs none of these crates. `rocket_healthz` 0.5.0 and every
other name-matched candidate are excluded on adoption (check `L8`). The gRPC
Health Checking Protocol as shipped by `tonic-health` is excluded on fit: it is
the one real standard in this space, and it is for gRPC servers, which this
template is not.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is owed.**

| Level | What must agree across py, ts and rs | Source |
|---|---|---|
| **Architectural pattern** | the readiness endpoint and the CLI's `doctor` command run **the same function**, in one place, with no second copy of the check list | F329's ledger Note, *"one source of truth with the CLI"*; py at pin `b08bccfb` imports `run_diagnostics` from `core/diagnostics.py` into **both** `web/app.py` and `cli/main.py` (check `O21`) |
| **Capability** | a liveness endpoint exists that reports the build's identity and is answerable without reaching any dependency | F328; py `web/app.py:153` (check `O20`) |
| **Capability** | a readiness endpoint exists that fails with a non-2xx status a probe reads, carrying the diagnostic detail in the body | F329; py `web/app.py:184-198` (check `O20`) |
| **Policy** (verbatim paths) | the two endpoints are unversioned: `/healthz`, `/readyz` | F308, `ADOPT`; applied, not re-derived |
| **Nothing — free to vary** | the payload's field list; which non-2xx status means "not ready"; whether readiness is computed per request or latched; the transport plumbing | Kubernetes reads only the status code; the surveyed production systems disagree on every one of these |

`ts` has neither front end at pin `cb1cbcb2`: a case-insensitive search for
`healthz|readyz` across `src/` matches **0** files (check `O23`), which is F303 as
recorded. Nothing cross-repo is owed to ts by this item; changes to py remain a
follow-on project, and this decision supplies their rationale rather than making
them.

**What Kubernetes requires, re-verified at source on 2026-09-18 (check `L5`),
because the whole contract hangs on it.** From
`https://kubernetes.io/docs/concepts/workloads/pods/probes/`: *"Liveness probes
determine when to restart a container"*; *"Readiness probes determine when a
container is ready to accept traffic"*, and a readiness failure makes the
EndpointSlice controller remove the Pod's IP address. From
`https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/`:
*"Any code greater than or equal to 200 and less than 400 indicates success. Any
other code indicates failure."*

Three consequences fix the design and are not matters of taste. **(a)** Liveness
failure is a *restart*, so `/healthz` must never be able to fail for a reason a
restart cannot fix — it reaches no dependency, no lock and no pool. **(b)**
Readiness failure is *traffic removal*, so `/readyz` is the correct and only place
for anything conditional. **(c)** The probe reads the **status code**; the body is
for humans and for a command-line client. Apollo Router's own source records
learning (c) the hard way — *"It's hard to get k8s to parse payloads. Especially
since we can't install curl or jq into our docker images because of CVEs. So,
compromise, k8s will interpret this as probe fail."* (check `L7`).

**Observable acceptance criteria.** Criteria marked **executed** were run here
against a throwaway workspace resolving the exact versions R69 revision 10 and
R66 select; the check identifiers are reproduced under `## Empirical check`. The
rest are P03's.

| # | Behavior | Observable criterion | State |
|---|---|---|---|
| AC1 | Liveness answers 200 and names the build | `GET /healthz` → `200`, body exactly `{"status","version","os","arch"}` | **executed** (`T1`) |
| AC2 | The liveness body is byte-stable for the process's life | two successive `GET /healthz` bodies are byte-identical | **executed** (`T2`) |
| AC3 | Liveness reaches no dependency | the `/healthz` handler's signature names no `State`, no pool and no port | **executed by construction** (`T1`, `T5`); enforceable in P03 by a one-line review of `routes/ops.rs` |
| AC4 | Warn-level findings do not remove traffic | a missing config file and a missing credential leave `GET /readyz` at `200` | **executed** (`T3`) |
| AC5 | An error-level finding removes traffic | a hand-built report containing one `error` check yields `503` | **executed** (`T6`) |
| AC6 | Readiness reports not-ready as soon as the drain begins | after `Readiness::begin_draining()`, `GET /readyz` → `503` | **executed** (`T4`) |
| AC7 | Draining is not a restart signal | after `begin_draining()`, `GET /healthz` is still `200` | **executed** (`T5`) |
| AC8 | Method handling is correct for a probe | `POST /healthz` → `405` with `Allow: GET,HEAD`; `HEAD /healthz` → `200` | **executed** (`T7`, `T8`) |
| AC9 | The CLI and the web service share one function | `crates/cli` and `crates/web` both call `rs_launch_blueprint_core::diagnostics::run_diagnostics`, and a search for the check-name literals finds them in exactly one file | **P03** |
| AC10 | The probe surface disappears with the feature | a default `cargo build` produces no probe route and no `axum` in the dependency graph | **executed** (`C9`, with `C10` as its converse) |
| AC11 | `/readyz` answers 503 for the whole drain window and the process exits 143 | a process test: send `SIGTERM`, assert `GET /readyz` → `503` while an in-flight request completes, then assert exit `143` | **P03** — needs a running binary; see the honesty note on the drain race below |

**Architectural alternatives, compared before any library was considered.**

| # | Alternative | Mechanism | Disposition |
|---|---|---|---|
| **A** | Re-run the diagnostics on every readiness probe — py's literal shape | `/readyz` calls `run_diagnostics(config)` per request, 503 if any check errors | **Adopted for the diagnostic half.** It is the only shape that satisfies the shared pattern, and the check set is local and cheap. Its weakness is that it says nothing about process lifecycle |
| **B** | Latch process state in an `AtomicBool` — kubert's and Apollo Router's shape | `/readyz` reads `Arc<AtomicBool>`; startup sets it true, shutdown sets it false | **Adopted for the lifecycle half.** Both surveyed production systems chose it independently (check `L7`). It is the only shape that can report *draining*, the state Kubernetes most needs to see |
| **C** | **A + B: the latch OR'd with the shared diagnostics** | `/readyz` → 503 if draining, else run diagnostics, 503 if any check errors, else 200 | **Selected.** The two arguments below |
| **D** | Move the probes to a second listener on a second port — Apollo Router's and kubert's *deployment* shape | a separate `axum::serve` on an admin address | **Rejected for this template; recorded as the scale-out path.** It buys isolation of ops traffic from request-path middleware and lets probes outlive the main server during drain; it costs a second bound port, a second `serve_until`, a second variable in R77's settings and a second row in R51's container contract. py binds one port, this template ships no deployment, and R75 already owns excluding the probes from access logs (F320) — the concrete benefit D would otherwise buy |
| **E** | Adopt a probe crate | `rocket_healthz`, or a hand-rolled `tower` layer | **Rejected on the census** (check `L8`). No crate exists at adoption worth depending on, and the surface is two handlers |
| **F** | Speak the gRPC Health Checking Protocol (`tonic-health`) | a gRPC `Health` service | **Rejected on fit, recorded because it is the one real standard here.** This template serves HTTP/1.1 JSON and has no gRPC surface; adopting it would add `tonic` for nothing |

**The first reason alternative C, not A, is the recommendation — and the honest
limit of that reason.** R69 revision 10 puts `shutdown_signal()` and
`serve_until(..)` in `crates/web/src/lib.rs`, and `serve_until` starts the grace
clock at the signal. Kubernetes removes a Pod from its EndpointSlices only once a
readiness probe has *failed*, which takes at least one probe period. **Flipping
the latch is necessary but, on its own, not sufficient.** Once `shutdown_signal()`
resolves, `axum::serve` stops accepting, so a kubelet opening a *fresh* connection
to `/readyz` gets a connection refusal — already a probe failure — and never reads
the latch at all. A flip immediately followed by resolution therefore changes
nothing observable on a fresh-connection probe; what it changes is the answer
given on a connection that is already open. **What actually closes the race is a
nonzero pre-drain pause inside `shutdown_signal()`**: flip the latch, keep the
listener open for a readiness-propagation window during which `/readyz` answers
503 and the EndpointSlice controller removes the Pod, *then* resolve and let the
drain begin. The latch is what makes that pause do anything; the pause is what
makes the latch observable to a fresh-connection probe. **The mechanism is inert
if that window is zero, and no item owns its value today** — see the correction
under `## Engines`: `raw/opus.md` says R77 owns it, and R77's own in-flight report
owns a drain *deadline* (`RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, recommended 8 s)
and names no propagation pause on any line (check `O15`). This decision therefore
**hands R77 a requirement rather than citing a fact**: whatever window R77 or a
later item chooses must hold both the readiness-propagation delay and the drain
inside the platform's kill budget, of which the Cloud Run 10-second SIGTERM window
R69 records is the recorded instance. That datum is **carried from R69, not
re-verified here.**

**The second reason: in the ported design the latch is the only thing that makes
the 503 branch reachable from a real environment — and `raw/opus.md` overstates
this, so the corrected form is recorded here.** py's four checks are `python`,
`platform`, `config-file` and `token`; exactly one of them, `python`, can be
`error`, and only when the interpreter is older than `MIN_PYTHON = (3, 12)`, which
the package's own floor already forbids (check `O27`). py's passing-path test says
so in a comment: *"# Missing token/config are warnings, not errors, so readiness
holds."* **`raw/opus.md` then claims "there is no test in that file for the 503
branch". That is wrong.** `tests/web/test_app.py:248-262` is
`test_readyz_failure_is_a_problem_with_diagnostics`, and it does assert `503` — but
it reaches that branch only by `monkeypatch.setattr(app_module, "run_diagnostics",
lambda _config: failing)`, substituting the function with a hand-built failing
report (check `O22`). The substitution is itself the evidence: the branch is
reachable in a test and unreachable from any real environment. Rust has no
runtime-toolchain check to port at all, so a literal port of alternative A would
ship a readiness endpoint whose diagnostic half can never return 503. The latch
gives the endpoint one state it can genuinely report, and the check list stays open
for whatever later items add. **Which checks can reach `CheckStatus::Error` in Rust
is not decided here, and no accepted decision defines one**: R55
(`config-error-tolerance`, published at revision 3) and R57
(`xdg-directory-set`, published at revision 2) are the two items whose
subject matter could produce one, and **neither names `run_diagnostics`, `doctor`,
`readyz` or `CheckStatus` on any line — 0 hits and 0 hits, counted rather than
read** in the published texts (check `O28`; check `V7` confirms they are the
accepted bytes). R55's typed `Vec<ConfigWarning>` is diagnostic-adjacent and
is not the same thing: it is a config-load warning list, not a check in this
report. The check list is unowned; this decision names that gap rather than
filling it.

**Where the shared function lives, and why the placement is forced rather than
chosen.** `run_diagnostics` goes in **`crates/core`**, the member R02 revision 2
(owner-accepted, unpublished) defines as models, ports, services, the error
catalogue and the shipped `InMemoryProjectsPort`, with no CLI or web framework
(check `O18`). Both front ends depend on core and on nothing else, so core is the
*only* place a function can sit and be reachable from both; anywhere else would
either duplicate it or create the front-end-to-front-end edge Cargo refuses as a
cycle. This is the Rust analogue of py's `core/diagnostics.py`, and it is stronger
than py's: in py the placement is a convention an `import-linter` contract polices,
whereas here Cargo's own resolver refuses the alternative. Check `C11` demonstrates
the consequence — the member holding the function names no web crate.

**The signature, and the three accepted decisions it satisfies simultaneously.**

```rust
// crates/core/src/diagnostics.rs — the only place the check list exists
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "lowercase")]
pub enum CheckStatus { Ok, Warn, Error }

#[derive(Debug, Clone, serde::Serialize)]
pub struct Check { pub name: &'static str, pub status: CheckStatus, pub detail: String }

#[derive(Debug, Clone, serde::Serialize)]
pub struct Diagnostics { pub checks: Vec<Check> }

impl Diagnostics {
    pub fn has_error(&self) -> bool {
        self.checks.iter().any(|c| c.status == CheckStatus::Error)
    }
}

/// Synchronous (R05 revision 3), infallible (R03 revision 1), framework-free (R02 revision 2).
pub fn run_diagnostics(config: &Config) -> Diagnostics;
```

- **R05 revision 3** (synchronous core) makes this an ordinary `fn`, not `async
  fn`, and makes the web side reach it through `tokio::task::spawn_blocking`
  (check `O19`). The CLI calls it directly.
- **R03 revision 1** (`absent is a value, broken is an error`) is why the return
  type is `Diagnostics` and **not** `Result<Diagnostics, _>`. A failing check is a
  fact about the environment that the report exists to carry, not a failure of the
  function that collected it. A `Result` would force both callers into an
  identical `match` — the CLI to print something, the handler to pick a status code
  — re-creating the duplication the pattern exists to remove. py chose the same:
  `run_diagnostics` has no failure mode and returns `DoctorReport`.
- **R02 revision 2** forbids a web or CLI type in core, so core derives
  **`serde::Serialize` and nothing else**. No `IntoResponse`, no `utoipa::ToSchema`
  and no `clap` attribute ever goes on `Diagnostics`; the hand-off to R71 is below.

**Ranked runner-up for the shared contract:** `Result<Diagnostics,
DiagnosticsError>`. It is qualified, not absurd — a check that must read a file
could fail in a way that is not itself a finding — and it is the shape to move to
if P03 finds one. The migration is mechanical: the CLI adds one `?` and the
handler adds one `match` arm mapping the error to 503.

**The initial check set** ports py's minus the one with no Rust analogue: `build`
(version, OS, arch — informational, always `ok`), `config-file` (`ok`/`warn`) and
`credential` (`ok`/`warn`). `name` is `&'static str` because every check name is a
literal; `detail` is `String` because it interpolates paths and values. The
executed probe ran exactly this set (`T3`).

**The liveness payload: the one place where a faithful port is the wrong answer.**
py reports `python: platform.python_version()` — the version of the interpreter
*at this moment executing the process*. Rust has no such fact at runtime: the
binary is statically compiled, there is no toolchain in the container to report,
and the nearest equivalent (the `rustc` that produced the binary) is obtainable
only through a Cargo build script or a compile-time proc macro — the mechanisms
R49 excludes and gate 2 excludes respectively. The **principle** py's field serves
is *"the liveness payload identifies which build is answering"*, which is what its
docstring says (*"Liveness + build info (the web analog of ``--version``)"*). Rust
preserves that principle with facts it already carries for free:

```rust
#[derive(Serialize)] pub struct LivenessReport {
    pub status:  LiveStatus,     // "ok"
    pub version: &'static str,   // R22's VERSION constant, from whichever package R22 and R02 settle on
    pub os:      &'static str,   // std::env::consts::OS
    pub arch:    &'static str,   // std::env::consts::ARCH
}
```

This is a **justified ecosystem difference, not drift**: the capability ("identify
the build") agrees, and the field that realizes it differs because the underlying
fact differs. On a multi-architecture image the `arch` field also tells an operator
which image the orchestrator actually pulled, which py's field cannot. Check `T1`
served exactly `{"status":"ok","version":"0.4.2","os":"macos","arch":"aarch64"}`
from a workspace containing **no** `build.rs`, and `T2` shows the body is
byte-stable across calls.

**A workspace hazard this decision must state, because it silently breaks the
field just specified.** `env!("CARGO_PKG_VERSION")` expands to the version of *the
package being compiled*. Under R02's four-package workspace, evaluating it inside
`crates/web` yields the web member's version, not the distributed artifact's.
Executed as check `A`: with the facade at `0.4.2` and the web member at `0.1.0`,
the macro read inside the web member reports **`0.1.0`** — the endpoint would
report the wrong version, correctly, forever. Check `B` shows the repair:
`[workspace.package] version` plus `version.workspace = true` on every member
makes all three packages report `0.4.2`.

**The constant is R22's, and R22's accepted placement cannot be read from
`crates/web` as the workspace now stands.** R22 (`runtime-version-accessor`)
revision 1 is owner-accepted: `docs/port/OWNER-ACCEPTANCES.md:79` records it at
sha256 `0e7ea78e…` on 2026-09-18, under owner ruling W1-R22 option A
(`docs/planning/p02/owner-decisions.md:516`). Its accepted text puts one
`pub const VERSION: &str = env!("CARGO_PKG_VERSION");` in `src/lib.rs` of the
single `[lib]` `rs_launch_blueprint`. It says that the optional web surface's
health response reads `rs_launch_blueprint::VERSION`, and its AC3 asks for
*"one value, one symbol"* (check `V6`). Two accepted decisions have since moved
the ground under that text:

- **R02 revision 2** makes the workspace four packages. That is the event R22
  revision 1's own `re-verify:` line names: *"R02
  (`crate-boundary-enforcement`, still `open`) selecting a multi-crate
  workspace"*. The trigger has fired.
- **R69 revision 10** declares `web = ["dep:rs-launch-blueprint-web"]` on the
  root package (its owned value, carried unchanged by revision 11 at line 1885). The facade therefore depends on
  `crates/web`, and `crates/web` cannot import `rs_launch_blueprint::VERSION`
  without a dependency cycle, which Cargo refuses.

R22's run directory also holds unaccepted revisions 2 to 5. This decision relies
on none of them.

**Handed to R22 and R02, decided by neither here.** This item's own requirement
is narrow: `/healthz` reports the distributed artifact's version, never the web
member's (check `A`). Either of two placements meets it:

| Option | Mechanism | R22 revision 1's AC3, "one value, one symbol" | Cost |
|---|---|---|---|
| (a) | the constant moves to `crates/core`, which inherits `[workspace.package] version`; the facade re-exports it, so `rs_launch_blueprint::VERSION` still resolves; `crates/web` and `crates/cli` read `rs_launch_blueprint_core::VERSION` | met: one value and one symbol, re-exported | R22's "where it goes" paragraph changes package |
| (b) | every member inherits `[workspace.package] version` with `version.workspace = true`, and each package evaluates `env!("CARGO_PKG_VERSION")` itself | met for the value (check `B`), not for the symbol | several call sites evaluate the macro; the version-consistency test proposed below is what would catch a member that stops inheriting |

The design here works under either option, and its code sketch names neither.
This is a coupling, not a `CONFLICT:` line, because R22 owns
no registry parameter.

**Uptime: asked by the prompt, and declined, with the cost stated.** It is cheap —
one `Instant` at startup and one monotonic subtraction — and it is not
recommended, for three reasons. (1) A body that changes on every request destroys
AC2, and R33 (`property-and-snapshot-testing`, published) selects snapshot
testing, so a monotonically-increasing field forces every such test to redact a
field before comparing. (2) Neither surveyed production system emits it: kubert's
`/live` body is the plain-text literal `"alive\n"` (asserted at source by check
`L7`) and Apollo's is `{"status":"UP"}` (carried from `raw/opus.md`). (3) Kubernetes never reads the body. The operational question uptime
answers — "did this process restart?" — is better answered by the container
runtime's own restart count. **Recorded as the alternative so the owner can
overturn it cheaply**: if wanted, it is one `pub started: Instant` field on
`AppState`, one line in the handler, and AC2 is deleted.

**Structured types versus a minimal body (the prompt's MEDIUM question):
structured, `serde`-derived types.** Three pieces of evidence in ascending order
of force. `apollographql/router` derives `Serialize` on its `Health` struct rather
than writing a literal (check `L7`). `rust-lang/crates.io` derives both
`Serialize` and `utoipa::ToSchema` on the analogous build-identity response
(carried from `raw/opus.md`, not re-read here). And py records the concrete cost of
not doing it, in a comment at the `/readyz` decorator: *"response_model declares
the 200 shape in OpenAPI (contract safety, WEB-50): without it the snapshot
publishes an empty `{}` schema."* Since R71 will publish a spec that R83 fuzzes, an
untyped ops body is a hole in that spec. The **ranked runner-up** is the
hand-written literal — kubert's `"alive\n"` with a `text/plain` content type — a
defensible choice for a body only a kubelet reads, rejected here because a spec is
published over these routes. **The hand-off to R71, stated precisely because it
collides with R02:** if R71 selects `utoipa`, its `ToSchema` derive must **not** be
placed on `crates/core`'s `Diagnostics`; R71's options are a `crates/web` DTO built
by `From<Diagnostics>`, or a hand-written schema fragment. This item states the
constraint and decides nothing for R71.

**Does the readiness check dial the upstream API? No, by default — and the
extension point is specified rather than left implicit.** py's `run_diagnostics`
never contacts the upstream service: all four of its checks are local (check
`O27`). Kubernetes explicitly permits the other choice — *"the readiness probe
additionally checks that each required back-end service is available"* — when the
app has a strict dependency on back-end services, but pairs it with the
cascading-failure caution, and a correlated upstream blip would then remove **every**
replica from service simultaneously. So: **local checks only by default; an
upstream check is an opt-in.** When a template user wants one, its shape is fixed
by R01's published `http-transport-injection-seam`: the check calls the erased
service held in `AppState` — core's port — **never a concrete adapter**, inside the
same `spawn_blocking` hop, with a timeout strictly shorter than the probe's
`timeoutSeconds` and a short result cache so that N probes per second do not become
N upstream calls per second. Adding it changes no signature in this design: it is
one more `Check` pushed onto the report.

**The bridge, and the latch, in tokio's terms.** `/readyz` reaches the synchronous
core through `tokio::task::spawn_blocking`, which is R05 revision 3's own
mechanism. The honest counter-argument is recorded: today's check set is a single
`stat`, far below the threshold at which blocking matters, so a direct call would
work. It is not recommended, for consistency with R05's rule (so no reader has to
relitigate which core calls are "small enough") and for extensibility (the opt-in
upstream check above, and whatever checks later items add, are exactly the ones
that would stall the reactor). `tokio::task::block_in_place` is the third
candidate and is rejected on a concrete cost, not a stylistic one: it panics on a
current-thread runtime, which is what `#[tokio::test]` uses by default, so it would
make the probe untestable in the idiom R69 selected. The **latch** is `std`, not
tokio: `Arc<AtomicBool>` with `Ordering::Release` on the store and `Ordering::Acquire`
on the load. `tokio::sync::watch` would also serve and is the runner-up, to be
taken if anything ever needs to *await* the transition rather than read it; nothing
does. `spawn_blocking`'s `JoinHandle` can report a panic in the closure, and the
handler maps a `JoinError` to **503**, since a probe that panics is by definition
not ready — the executed probe used `.expect(..)`, which is **not** the recommended
production shape and is marked as such in the committed probe source.

**Agreement and difference with the owner-supplied reference architecture**
(`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, the standing input
`docs/planning/p02/owner-decisions.md` section 11 places in this item's overlap set
at row C15). Row by row, for every row that touches this item:

| Reference row | What it says | This item |
|---|---|---|
| **C15**, *Container & Cloud Run* | "expose `/healthz` (liveness) and `/readyz` (readiness, checks DB)" (check `O24`) | **Agree on the two paths and their roles.** **Differ on "checks DB", on sourced ground**: this template has no database, its single driven dependency is an upstream HTTP API behind R01's port, and the Kubernetes cascading-failure caution plus py's local-only check set make an unconditional dependency dial the wrong default. The capability is preserved as the specified opt-in above |
| **C15**, *distroless/cc-debian12*, run as `nonroot`, bind `PORT` | the image shape | **Not this item's** — R51 owns it. One consequence is stated below, not fixed |
| **C4**, *Error contract* | "One `AppError` enum (`thiserror`) implementing `IntoResponse` … RFC 9457 Problem Details JSON" | **Agree that `/readyz`'s 503 reuses the single envelope**, which is what py does. The envelope itself is R70's and is still in flight; the standing constraint this item places on it is below |
| **C10**, *Observability* | JSON logs, trace correlation | **No position** — R58/R75/R78/R79. The only interaction is F320, which is R75's |
| **C13**, *Project structure* | "feature-vertical modules" | **Agree**, as realized by R69 revision 10: the probe handlers are one module, `crates/web/src/routes/ops.rs` |
| **Reference `Cargo.toml`** | `edition = "2021"`, `rust-version = "1.85"` (check `O24`) | **Differ — owner-fixed parameters override**, per section 11's own rule: `rust-edition` = 2024 and `msrv-policy` as registered. The executed probe workspace uses edition 2024 throughout |

Tally over the six rows: **3 agree, 2 differ** — one difference on sourced ground,
one on an owner-fixed parameter, both grounds section 11 requires — plus 2 rows
recorded as belonging to other items. Those counts sum to seven over six rows
because the C15 *probes* row is counted twice: it agrees on the two paths and
differs on "checks DB".

### Conformance with the REST API Design Standard v2.0.0

Owner ruling W2-REST binds this standard to the template's HTTP surface. **The
standard names no health, readiness, liveness or ops-endpoint rule anywhere** —
0 rule lines match `health|readiness|liveness|probe endpoint`, counted at the
pinned blob by check `S27`. There is no ops carve-out, so the probe surface is
judged by the general rules, one at a time, below. Every rule is quoted at its
line number by checks `S1`–`S26`; the six that can only be settled by running
axum 0.8.9 are measured by `P1`–`P6`.

| Rule | Line | Strength | What it requires | `probe-contract/v1` |
|---|---|---|---|---|
| R1.6 | 229 | — | rules scoped by applicability switch; an off-switch declaration MUST carry a reason | **CONFORMS** — the conformance note below declares all four switches off, each with its reason |
| R1.7 | 271 | MUST | no silent deviation; every SHOULD deviation recorded, every MUST deviation an approved exception | **CONFORMS** — `OVERRIDE (OV-05)` and the two SHOULD deviations are in writing below |
| R1.8 | 312 | MUST | a reserved name MUST NOT carry another meaning | **CONFORMS** — neither `healthz` nor `readyz` is reserved; the probes take no query parameter, define no media type and reuse no reserved header for a new meaning |
| R2.1 | 443 | MUST | a resource-oriented surface; no RPC carve-out for any service class | **OVERRIDE (OV-05)** — the probes are operational signals, not resources |
| R2.2 | 456 | MUST | collections plural; the singleton exception requires a documented singleton | **OVERRIDE (OV-05)** — neither path is a plural collection nor a documented singleton noun |
| R2.3 | 467 | MUST | resource names unabbreviated, one noun per concept | **OVERRIDE (OV-05)** — `healthz` and `readyz` are orchestrator coinages, not the domain's nouns |
| R2.4 | 477 | MUST | path segments kebab-case, `^[a-z][a-z\-0-9]*$` | **CONFORMS** — both segments match the pattern |
| R2.5 | 487 | MUST | at most three resources in a path | **CONFORMS** — one segment each |
| R2.6 | 499 | MUST + SHOULD | canonical URIs carry no trailing slash; a trailing-slash request SHOULD get `308` | **CONFORMS** on the canonical form; **SHOULD deviation** on the redirect — check `P3` measures axum 0.8.9 answering `GET /healthz/` with `404` and no `Location` |
| R2.9 | 525 | MUST | operation modifiers travel as query parameters, never path segments | **CONFORMS** — the probes take no parameter at all |
| R2.11 | 542 | MUST | a non-CRUD *operation* uses `POST /{collection}/{id}/{action}` | **CONFORMS, vacuously** — the probes are safe `GET`s, not mutations; the action form is the alternative modeling OV-05 weighs and rejects |
| R3.10 | 693 | MUST + exception | a conditionally-updatable resource MUST emit a strong `ETag`; **exception:** resources never updated by clients | **CONFORMS by the named exception** — no client updates a probe, so no `ETag` is owed under R7.3 tier 1 |
| R4.10 | 846 | MUST + SHOULD | default media type `application/json` UTF-8, selected by negotiation not a `format` parameter; an unsatisfiable `Accept` SHOULD get `406` | **CONFORMS** on the default and on the absence of a `format` parameter (`P1`); **SHOULD deviation** on `406` — check `P4` measures axum's `Json` responder serving JSON for `Accept: application/xml` |
| R4.11 | 856 | MUST + exception | `Vary` on any response whose content was header-selected; **exception:** responses with no negotiation | **CONFORMS by the named exception** — the probes negotiate nothing, which is the same fact `P4` measures |
| R5.1 | 916 | MUST | the status matches the outcome known when it is generated; a failed operation MUST NOT return 2xx | **CONFORMS** — not-ready answers `503`, never a 2xx (`T4`, `T6`, `P2`) |
| R5.2 | 934 | MUST | no unregistered status codes | **CONFORMS** — `200`, `405` and `503` are all registered |
| R5.11 | 1008 | MUST | `405` MUST carry `Allow` | **CONFORMS** — axum 0.8.9 supplies `Allow: GET,HEAD` with no code written for it (`T7`, `P6`). The rule turns revision 1's observation into a standard-bound obligation |
| R5.12 | 1019 | MUST | every application-generated error response MUST be available as `application/problem+json`; the carve-out is infrastructure errors only | **CONFORMS by design** — `/readyz`'s 503 is application-generated and reuses R70's envelope. The carve-out does not reach it |
| R5.13 | 1049 | MUST | every response-carried problem document MUST carry `type`, `title`, `status` and a stable `code` extension member | **Requirement on R70, sharpened** — the 503 needs those four members *plus* a carrier for the report. This is stronger than revision 1's "the report must be reachable" |
| R5.16 | 1114 | MUST | the API MUST publish a catalog of every `type`/`code` pair it can return | **Obligation recorded** — the readiness failure needs a catalogued pair. R70 owns the envelope, R67's append-only catalog owns the token; this item assigns neither |
| R5.17 | 1120 | MUST | no response body may expose stack traces, query fragments, internal hostnames or dependency detail | **Moves the recommendation** — `Check::detail` interpolates paths today (the probe printed `no config file at /nonexistent-r80-probe/config.toml`). Every `detail` reaching the wire is redacted; §8.5's secret and PII rules apply to it identically |
| R7.1 | 1259 | MUST | every response MUST carry an explicit `Cache-Control` header | **Moved, and now CONFORMS** — revision 1 emitted none. Both probes emit `Cache-Control: no-cache` (`P1`, `P2`) |
| R7.2 | 1271 | MUST + exception | user-specific or authenticated responses MUST be `private` or `no-store`; **exception:** genuinely public responses | **CONFORMS by the named exception** — a probe body is unauthenticated and identical for every caller, so no `private` marker is owed |
| R7.3 | 1281 | — | three-tier posture; blanket `no-store` is a named anti-pattern reserved for genuinely sensitive payloads | **CONFORMS** — tier 1 (`no-cache`) is the mutable-resource default; `no-store` is the ranked runner-up and is declined on the rule's own anti-pattern ground, a probe body not being sensitive |
| R9.1 | 1435 | MUST | one uniform version-marker placement, the major version in the path (`/v1`) | **OVERRIDE (OV-05)** — F308 fixes `/healthz` and `/readyz` unversioned, and the prompt instructs applying F308 rather than re-deriving it |
| R11.7 | 1752 | MUST | every response, including errors, MUST carry the `request-id` correlation header | **Obligation recorded, not yet met** — check `P5` measures the handlers emitting none, because the header is middleware's. **R75's correlation layer MUST cover `/healthz` and `/readyz`**, and F320's access-log exclusion must not be read as excluding them from the header |

**Three moves, two deviations, one override — and what did not move.** The
recommendation moves on R7.1 (the `Cache-Control` header, executed), on R5.17
(redaction of `detail`, a contract change with no executable check here because
the real `Config` does not exist) and on R5.13/R5.16 (a sharper requirement
handed to R70). It does **not** move on the stack, the versions, the
shared-function placement, the latch, the `spawn_blocking` bridge, the liveness
field list or any parameter line.

#### Conformance note — `rs-launch-blueprint` optional web surface

Recorded in the standard's own section 1.9 template. It is **provisional**: this
item owns only the two probe paths, and the note's tier, switches and deviation
list belong to the template as a whole. R69 owns the surface; R70, R71 and
R72–R76 each add rows. The rows below are the ones R80's two endpoints create.

```markdown
## Conformance note — rs-launch-blueprint optional web surface (R80 rows only)

Standard: rest-api-standard v2.0.0
Tier: internal
Switches: webhooks=off, async-operations=off,
  bulk-operations=off, streaming=off
  (webhooks=off — the template delivers no outbound callbacks;
   async-operations=off — no endpoint returns 202, so no operation resource exists;
   bulk-operations=off — no endpoint accepts a batch;
   streaming=off — no endpoint serves a stream media type)
Context: a project template, not a deployed service. The probe surface is
  consumed by a container orchestrator, not by API clients; it is
  unauthenticated, carries no PII, and is single-tenant by construction.

Deviations:
- OV-05 · MUST (R2.1, R2.2, R2.3, R9.1) · the two probe endpoints are
  unversioned, non-plural, abbreviated non-resource paths · the orchestrator
  contract fixes the names and F308 fixes the absence of a version segment ·
  approver: PENDING OWNER · date: PENDING
- R2.6 · SHOULD · a trailing-slash request to a probe path answers 404, not the
  preferred 308 redirect · axum 0.8.9 supplies no such redirect (measured, P3),
  and no orchestrator probe is configured with a trailing slash; the conforming
  alternative is one extra route per probe returning 308 · approver: PENDING
  OWNER · date: PENDING
- R4.10 · SHOULD · an Accept header excluding application/json receives 200 with
  JSON, not the preferred 406 · axum's Json responder ignores Accept (measured,
  P4); a kubelet httpGet probe sends no Accept header, and the conforming
  alternative is an Accept check in each handler · approver: PENDING OWNER ·
  date: PENDING

N/A declarations:
- R3.10 · the probes are never updated by clients, which is the rule's own
  stated exception
- R4.11 · the probes negotiate nothing, which is the rule's own stated exception
- §6 (collections, pagination, filtering, sorting) · neither probe is a
  collection
- §10.1–§10.4, §13 · the four switches above are off, each with its reason
```

#### `OVERRIDE (OV-05)` — the probe paths are unversioned, non-resource names

`OV-05` is **assigned by the controller**, not chosen here. Revision 2 picked
`OV-04` from its own scoped search of `docs/` and `research/` for `OV-[0-9]+`,
which returned `OV-01` (R60, refused 2026-09-14), `OV-02` (R61), `OV-03` (R02)
and one range notation in an R61 audit, leaving `OV-04` through `OV-08` unused.
R77's revision 2 ran the same search minutes earlier and reached the same answer,
so two items allocated `OV-04` concurrently. The controller now allocates
override numbers: **R77 keeps `OV-04` and this item's override is `OV-05`**
(ledger entry *"OVERRIDE NUMBER COLLISION, 2026-09-18"*). The deviation is from
four **MUST** rules at once, argued
once rather than four times because a single fact creates all four: the probe
paths are not resources and not part of the versioned API.

**Argument:** R2.1 requires a resource-oriented surface, R2.2 plural collections
or a documented singleton, R2.3 unabbreviated domain nouns, and R9.1 the major
version in the path. `/healthz` and `/readyz` satisfy none of them, and the
reason is the same in each case: they are not API resources. They are signals
addressed to a container orchestrator, whose meaning — restart the container,
remove the Pod from its EndpointSlices — is fixed by the Kubernetes probe
contract quoted under `### Principles and implementation`, not by this
template's domain. Three facts make the deviation necessary rather than
convenient. **(1)** The names are a consumer-side convention: the kubelet reads
whatever path its `httpGet` names, so a conforming `/v1/health-checks` would
work technically, but every operator, every container `HEALTHCHECK` and every
piece of copied deployment YAML in the ecosystem expects `/healthz` and
`/readyz`, and both surveyed production systems — `olix0r/kubert` and
`apollographql/router` — serve short unversioned ops paths (`/live`, `/ready`,
`/health`). **(2)** F308 is an `ADOPT` ledger row, and this item's binding
prompt instructs that it be *applied, not re-derived*: "a trivial URL-prefix
convention, do not re-derive it, just apply it to the two endpoints this item
designs". Re-deriving it against R9.1 is outside what this item was asked to
decide. **(3)** Versioning an ops probe is actively harmful: R9.1 exists so a
breaking change can ship behind `/v2`, but a probe path must stay stable across
every major version precisely because the deployment manifest that names it is
not redeployed in lockstep with the API. The cost of the deviation is real and
is stated: a reader of the OpenAPI document sees two paths that do not follow
the API's own naming rules, and R71 must either document them as such or exclude
them from the spec — a choice this item hands to R71 rather than making.

**Options:**

| | Option | Effect | Conformance |
|---|---|---|---|
| a | **Recommended.** Keep `/healthz` and `/readyz` unversioned, record this override, and let R71 decide whether the spec documents or excludes them | F308 applied as instructed; the orchestrator contract holds; ecosystem-standard names | Deviates from R2.1, R2.2, R2.3, R9.1 — four MUSTs, approval required per R1.7 |
| b | Version the probes as `/v1/health` and `/v1/readiness` | Conforms to R9.1 and to R2.3's unabbreviated-name rule | Still deviates from R2.1 and R2.2 — they are not resources and not plural — so it trades four deviations for two while breaking every copied deployment manifest and contradicting F308 |
| c | Model readiness as an action, `POST /v1/service-instances/{id}/check-readiness` per R2.11 | Fully conforms to §2 and §9 | Unusable: a kubelet `httpGet` probe issues `GET`, cannot supply an id, and R5.1 would then make a readiness failure a failed `POST` rather than a probe signal. Rejected on the consumer contract, not on taste |
| d | Serve the probes on a second admin listener, off the API's URI space entirely | The standard governs the API's URI space (§1.3); a separate admin port arguably falls outside it | This is alternative **D** under `### Principles and implementation`, already rejected there for this template on cost grounds, and the §1.3 reading is an interpretation this item is not entitled to make on the owner's behalf. Recorded as the scale-out path that would also retire this override |

**What settles it.** The owner records `OV-05` as approved, or selects (b), (c)
or (d). Until then the deviation is **requested, not granted**, exactly as
`OV-01` was recorded before its refusal, and the conformance note above carries
`approver: PENDING OWNER`.

### What this decision does not decide

Each of these is a coupling stated at the strength the evidence supports. None is
a `CONFLICT:` line: a `CONFLICT:` records a consumed *parameter value* that must
change, and none must.

**R70 (`http-problem-envelope`) — a standing constraint, and the one place a
reader should expect friction.** This design needs the diagnostic report carried
in the 503 body, which is what py does: `problem_response(..., status_code=503,
extensions={"diagnostics": report.model_dump(mode="json")})`, with the 503
declared in py's own OpenAPI responses as *"RFC 9457 problem document with a
`diagnostics` extension"* (check `O20`). **R70's in-flight raw report chooses an
envelope that "adds one extension member and no more"** — `code` — plus an optional
`errors` map, and in the same report hands `/readyz`'s failure body to R80 (check
`O12`). Those two sentences are in tension, and R70 is being researched in
parallel, so this item **states the requirement and decides nothing**: the
diagnostic report must be reachable from the 503 response. Three ways satisfy it —
a second extension member named `diagnostics`; the report folded into a
structured error-detail member of R70's envelope; or a `detail` string that names the failing checks with the full
report left to the logs. R70 owns the choice. **Until R70 publishes, the executed
probe's 503 body is a plain JSON stand-in, and this decision claims nothing about
the envelope's member names.**

**Revision 2 sharpens that requirement, because the standard now fixes part of
it.** R5.13 (line 1049) makes `type`, `title`, `status` and a stable `code`
extension member mandatory on every response-carried problem document, so the
503 body is not free-form: R70's envelope must carry those four **and** a carrier
for the diagnostic report, which is five members where R70's raw report plans for
four. R5.16 (line 1114) then requires the readiness failure's `type`/`code` pair
to appear in a published catalog — R70 owns the envelope and R67's append-only
catalog owns the token, and this item assigns neither. R5.17 (line 1120)
constrains what the carrier may hold: no stack traces, no query fragments, no
internal hostnames, no dependency detail. That is a change to this item's own
contract and is recorded as such — `Check::detail` interpolates filesystem paths
today, which the executed probe printed verbatim
(`no config file at /nonexistent-r80-probe/config.toml`), and the shipped
`detail` must be redacted before it reaches the wire. **No executable check
proves the redaction here**: the real `Config` does not exist, so this is a
contract obligation P03 validates, listed under `## Engines`.

**R51 (`container-image`) — what `/healthz` returns, for it to probe.** Two facts
are established here rather than guessed. First, `/healthz` answers `200` with a
JSON body, on `GET` and on `HEAD`, with no state and no dependency, for the life of
the process. Second, the *probe client* problem: py solves it with the interpreter
it already ships (`Dockerfile:27-30`, commented *"urllib — the slim base image has
no curl"*), and a Rust distroless image has neither a shell nor an interpreter nor
`curl`. R51's in-flight raw report answers it with a static `busybox` applet stage
and an exec-form `HEALTHCHECK` against `/healthz` (check `O13`). **This item does
not choose among R51's options**; it records that `/healthz` is `HEAD`-safe, which
is what makes the cheapest probe clients viable.

**R79 (`prometheus-metrics`) — a third unversioned ops route is coming.** R79's
in-flight raw report names a three-path exclusion set, `/metrics`, `/healthz` and
`/readyz` (check `O14`). Whether `/metrics` is registered in the same
`routes/ops.rs` module or its own is R79's; F308's unversioned convention applies
to it identically.

**R77 (`web-env-settings`) — the readiness-propagation pause.** Stated above: R77's
in-flight report owns a drain deadline and names no pause (check `O15`). This item
hands R77 the requirement; if R77 declines it, the pause needs an owner.

**R75 (`http-middleware-stack`) — what can fail in front of `/healthz`.** The probe
handlers sit behind whatever middleware stack R75 builds, so a bug in an outer
layer can make `/healthz` fail and trigger a container restart for a reason
unrelated to liveness. Both surveyed production systems avoid this with
alternative D's separate listener. The mitigation available without D is R75's:
order the layers so the probes' path is reached before anything that can reject,
and keep a catch-panic layer outside them. Recorded as an input to R75, not a
decision for it.

**Revision 2 adds a second, harder input to R75.** R11.7 (line 1752) makes the
`request-id` correlation header a MUST on *every* response, errors included.
Check `P5` measures the probe handlers emitting none — correctly, because the
header is middleware's to add — so **R75's correlation layer must cover
`/healthz` and `/readyz`**, and F320's access-log exclusion must not be read as
excluding them from the header. The two are different mechanisms with the same
paths, and conflating them would make the probe responses nonconformant.

**The CLI `doctor` subcommand — presupposed by F329 and owned by no item, and it is
not R60's to carry.** R60 (`cli-parsing-framework`, published) put three options
for the extended `--version` data to the owner, of which **(c)** was "extended data
moved to a `doctor` verb"; **the owner's ruling was (b)**, the `--version -o json`
path, and R60's decision records that ruling verbatim (check `O8`). R60 would fall
back to (c) only if R66 refused a root format flag, which R66 did not. So no
published or accepted item specifies `doctor`'s flag surface or its exit code, and
`docs/port/COMMONALITY.md`'s only "doctor" rows (F185, F186) are contributor-facing
recipes, not the product subcommand. R67's accepted `error-taxonomy-exit-codes`
catalog is append-only and contains **no** diagnostics row; the nearest existing
rows are `RSLB104` (config layer unreadable → 1) and `RSLB203` (config value
invalid → 2) (check `O16`). **This item assigns no exit code.** It records that
whoever specifies `doctor` must reuse one of those or add a row through R67's
append-only process, and that today — with no check able to reach `error` —
`doctor` would exit `0` on every machine.

re-verify: when the REST API Design Standard moves off blob 71bd813c1cf61286586b4ee41ed83ff065e5c8d9, in particular any change to R2.1, R2.2, R2.3, R2.6, R4.10, R5.11, R5.13, R5.16, R5.17, R7.1, R7.3, R9.1 or R11.7, or the addition of any rule naming health, readiness or liveness, which would retire or reshape OVERRIDE (OV-05); when the owner rules on OV-05, which is requested and not granted; when R69 republishes web-extra-surface at revision 10, which fixes every file path in this decision's migration table and is the single most likely trigger; when R70 publishes the problem envelope, which decides how the 503 body carries the diagnostic report; when R71 publishes and requires a schema derive, which must meet the no-OpenAPI-derive-in-crates/core constraint; when R22 or R02 settles which package holds the VERSION constant — option (a), crates/core re-exported by the facade, or option (b), workspace version inheritance — which must stay workspace-safe as check A demonstrates; when any item, R55 and R57 included, adds a diagnostics check that can reach CheckStatus::Error; when R77 publishes a readiness-propagation pause or moves the drain deadline; when R51 publishes the container probe client; when R75 publishes the middleware order; when R79 publishes /metrics as a third unversioned ops route; when R05 is reopened to an async core, which deletes the spawn_blocking hop; when R02, R05 or R03 is re-bound to a new accepted revision, which check O17 detects by sha256 against docs/port/OWNER-ACCEPTANCES.md and which obliges this decision to re-cite that item (R05's run already holds unaccepted revisions 4 and 5); when the controller collects the Muse operation and the registered digest differs from 395c1426cd8db1e2d46588dcd364caac86a0beca6ca3119d5b7a56333672b012; when GET https://crates.io/api/v1/crates/axum/versions stops giving 0.8.9 as the newest non-yanked version in a release that changes MethodRouter's 405/Allow behaviour or Json's IntoResponse; when https://rustsec.org/packages/axum.html, .../serde.html or .../tokio.html changes status while the atty control holds at 200; when GET https://crates.io/api/v1/crates/shadow-rs/versions or .../git-version/versions begins returning a non-null rust_version, which reverses a gate-2 exclusion; when the Kubernetes probe documentation changes the quoted sentences; or by 2027-03-18, whichever comes first

## Parameters

**Owned parameters: none.** `research/CLAUDE.md`'s R80 row carries `—` in the
`owns` column and the binding prompt's `- owns:` coupling line is empty, so this
decision adds no registry parameter and carries no `- owns` line (check `O4`). The
contract it fixes — the two paths, their status codes, their payloads and the
shared function — is recorded in this decision's text, not in the shared-parameter
registry.

**Consumed parameters.** The prompt's `- consumes:` line is also empty, so none of
the following is a registered dependency; each is nonetheless load-bearing and is
declared rather than left implicit. Every value below is **byte-identical to its
row in `docs/port/PARAMETERS.md`** as read on 2026-09-18, asserted mechanically by
check `O3`, which parses the registry table and compares each value character for
character.

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on the root package rs-launch-blueprint; web = ["dep:rs-launch-blueprint-web"], with axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module crates/web/src/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional, and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated crates/web/src/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on crates/web/**, the serve binary's source file and the web test files

**`CONFLICT:` lines: none.** No consumed value needs to change for this
recommendation. The two places a reader might expect one, and why neither is: R49's
`build-tool-output-shape` no-`build.rs` clause **excludes** `built`, `vergen` and
`shadow-rs`, and this decision declines all three rather than asking for the clause
to move; and this decision's `web-extra-surface` line carries R69 revision 11's
owned value ahead of the registry row, which is the Q3.A flag day, not a needed
change.

**Prose note beside the `web-extra-surface` line, required because the line runs
ahead of the registry.** The line above carries **R69 revision 11's** owned value,
copied byte-for-byte from the `- owns web-extra-surface` line at **line 1885** of
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (sha256
`2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, verified by
checks `O3` and `O5`). Revision 11 is approved for re-accept under owner decision
Q3.A (flag day now). Its value changed at revision 10 under owner ruling W1-R02: it
puts the tree in the optional workspace member `crates/web/`, declares
`web = ["dep:rs-launch-blueprint-web"]` on the root package, declares `axum` and
`tokio` **non-optionally** in `crates/web/Cargo.toml`, and puts the web tests in
`crates/web/tests/` with **no** file-level `cfg` because the whole member is
optional. The registry row still carries revision 9's `src/web/` form until the
flag-day publication rewrites it. **This decision's design uses these paths** —
`crates/web/src/routes/ops.rs`, `crates/web/src/lib.rs`,
`crates/core/src/diagnostics.rs` — and the executed probe workspace is built in
that shape. **This is not a `CONFLICT:`**: the recommendation needs nothing in
R69's value changed. **R69's republication is a re-verify trigger** for every file
path in the migration table below; revision 11 moves none of them.

**Two further published values bind the recommendation without being consumed as
values**, so they are named here rather than given an `assumes` line. **R67's
`error-taxonomy-exit-codes`**: the serve binary's drain exits (143 / 130 / 1 / 0)
are R69's application of it and are untouched here; the CLI `doctor` command's exit
code is **not assigned by this decision** and is recorded above as an open scoping
question against R67's append-only catalog. **R01's
`http-transport-injection-seam`** carries an `assumes` line above because the
specified opt-in upstream readiness check calls the erased service — core's port —
and never a concrete adapter; with that check off by default, nothing in the
shipped design dials it.

**Migration implications, file by file**, written against R02 revision 2's
four-package workspace and R69 revision 10's accepted paths.

| File | Change |
|---|---|
| `crates/core/src/diagnostics.rs` (new) | `CheckStatus`, `Check`, `Diagnostics`, `Diagnostics::has_error`, `run_diagnostics(&Config) -> Diagnostics`. `#[derive(Serialize)]` only — no framework or OpenAPI derive ever enters this member. **`detail` is built redacted at its source** (R5.17): no absolute filesystem path, no internal hostname, no dependency detail — a check reports *that* a config file is absent, never where the loader looked |
| `crates/core/src/lib.rs` | one `pub mod diagnostics;`. Whether it is re-exported from the facade's barrel is R04's rule to apply, not this item's to decide |
| `crates/core/Cargo.toml` | **no change** — `serde` with `derive` is already present for R66's result contract |
| `crates/web/src/routes/ops.rs` | filled in: `LiveStatus`, `LivenessReport`, `async fn healthz()` (no `State`), `pub fn readiness_response(draining: bool, report: Diagnostics) -> Response`, `async fn readyz(State(..))`, a `router()` registering `/healthz` and `/readyz`, and **one `const PROBE_CACHE_CONTROL: &str = "no-cache"` applied to every response leaving this module** (R7.1). R69's file map already reserves this file with the note "`/healthz` now; `/readyz` and its payload are R80's" |
| `crates/web/src/lib.rs` | a `Readiness(Arc<AtomicBool>)` newtype with `accepting()`, `is_accepting()`, `begin_draining()`; one `readiness: Readiness` field on `AppState`; one `readiness.begin_draining()` call inside `shutdown_signal()`, **before** that future resolves. `build_router`'s `.merge(ops::router())` line is already in R69's recorded snippet |
| `crates/web/tests/web_api.rs` | the eight probe tests `T1`–`T8`, adapted to the template's types |
| `crates/web/Cargo.toml` | **gains `serde = { version = "1.0.229", features = ["derive"] }`**, and `serde_json` only if R70's envelope is constructed in this member directly. R69 revision 10's manifest row for that member lists only `axum`, `tokio` and the `tower` dev-dependency, because R66 places `serde` in the *library* crate, which under R02's topology is `crates/core`. The executed probe workspace had to add exactly these rows to compile the `#[derive(Serialize)]` on `LivenessReport`; a manifest written from "no change" would not build |
| `Cargo.toml` (root) | **no change from this item.** Check `A` shows that `/healthz` reports the artifact's version only if the constant is evaluated in a package carrying it. Under either option of the R22/R02 hand-off, the `[workspace.package] version` key, each member's `version.workspace = true`, and under option (a) the facade's `pub use` of `rs_launch_blueprint_core::VERSION`, are R22's and R02's edit |

**Not created by this item**, named so a later reader does not look for them here:
the problem envelope `/readyz`'s 503 reuses (R70); the OpenAPI annotations on these
routes and any DTO they need (R71, subject to the no-derive-in-core constraint);
the access-log exclusion for both paths (R75, F320); the settings module and any
readiness-propagation pause (R77); the `Dockerfile` and its `HEALTHCHECK` (R51,
F337); the `/metrics` route (R79); the CLI `doctor` subcommand's flag surface and
exit code (unowned); and any check capable of reaching `CheckStatus::Error`.

## Empirical check

**Toolchain and host, as observed for revision 4.** `rustc 1.98.1 (48a229cea
2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)`, macOS 26.4
(`Darwin 25.4.0`) on `arm64`, `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` at
`/usr/bin/grep`, `Python 3.14.7`, `ShellCheck 0.11.0`, `curl 8.7.1` and
`jq-1.8.2`. Revisions 1 to 3 ran on `rustc 1.98.0`. The compiler is recorded as
observed, not required: every probe manifest declares `rust-version = "1.96"`,
and no check asserts a patch release. Cargo ran with a private `CARGO_HOME` that
started empty and a private `CARGO_TARGET_DIR` shared across this revision's runs.
Revision 5 re-ran the three standard scripts on the same host, compiler, grep,
Python and ShellCheck, with its own private `CARGO_HOME` and
`CARGO_TARGET_DIR`. Working directory for every command: the repository root,
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. **No template code exists in
this repository and none was written**: the recommendation is verified, never
implemented.

**Six scripts, 113 checks, every one re-run for revision 4.** Revisions 1 and 2
wrote four scripts between them (three and one), revision 3 wrote one, and
revision 4 adds one. Each asserts on content, not on an exit code; each carries
`set -euo pipefail`; each counts PASS/FAIL/SKIP and exits non-zero on any FAIL.
A check that could not fail is not counted as evidence. Revision 4's `V8` was
such a check, and revision 5 repaired it so it can fail (audit EF-1). The totals
stand because `V8` was repaired, not dropped.

| Script | Checks | Added by | In revision 4 | Paired log | Result |
|---|---|---|---|---|---|
| `check-offline.sh` | 28: `O1`–`O28` | revision 1 | edited: EA-1, EA-3, published R55/R57, `O25`; revision 7 moved `O3` and `O5` to R69 revision 11 | `check-offline.log` | **28 PASS, 0 FAIL, 0 SKIP** |
| `check-probe.sh` | 13: `A`, `B`, `T1`–`T8`, `C9`–`C11` | revision 1 | edited: EA-4 | `check-probe.log` | **13 / 0 / 0** |
| `check-live.sh` | 9: `L1`–`L9` | revision 1 | unchanged | `check-live.log` (revision 1's), plus `check-live.r4-fetch.log` and `check-live.r4-snapshots.log` | **9 / 0 / 0** in all three |
| `check-standard-r2.sh` | 42: `S1`–`S27`, `P1`–`P6`, `C1`–`C9` | revision 2 | edited: EA-3, EA-4, re-baselined; revision 5 re-baselined `C2`; revision 6 re-baselined `C2`; revision 7 re-baselined `C2`, re-pinned `C1` and re-worded its message | `check-standard-r2.log` | **42 / 0 / 0** |
| `check-standard-r3.sh` | 7: `R1`–`R7` | revision 3 | edited: EA-3, re-baselined; revision 5 re-baselined `R1`, re-pinned `R6`; revision 6 re-baselined `R1`, re-pinned `R6`; revision 7 re-baselined `R1`, re-pinned `R6` | `check-standard-r3.log` | **7 / 0 / 0** |
| `check-standard-r4.sh` | 14: `V1`–`V14` | revision 4 | new; revision 5 repaired `V8` (EF-1), re-baselined `V1`, re-pinned `V13`; revision 6 repaired `V3` (Codex finding 1), re-baselined `V1`, re-pinned `V13`; revision 7 re-baselined `V1`, moved `V6` to line 1885, re-pinned `V13` | `check-standard-r4.log` | **12 / 2 / 0** since revision 7 (`V3`, `V4`: manifest drift) |

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R80/2026-09-17T034011Z-74765d801b92/review/evidence
bash check-offline.sh "$ROOT"      > check-offline.log       # ROOT = the repository root
bash check-probe.sh                > check-probe.log
bash check-standard-r2.sh "$ROOT"  > check-standard-r2.log 2>&1   # C9 re-runs check-offline.sh into check-offline.r2-rerun.log
bash check-standard-r3.sh "$ROOT"  > check-standard-r3.log 2>&1   # R7 re-runs check-standard-r2.sh into check-standard-r2.r3-rerun.log
shellcheck check-offline.sh check-probe.sh check-live.sh check-standard-r2.sh check-standard-r3.sh check-standard-r4.sh > shellcheck-r4.log   # exit 0, empty
bash check-standard-r4.sh "$ROOT"  > check-standard-r4.log 2>&1   # V14 re-runs check-standard-r3.sh into check-standard-r3.r4-rerun.log
# check-live.sh ran from a copy of evidence/ under $TMPDIR, because fetch mode rewrites ./snapshots:
bash "$COPY/check-live.sh"              > check-live.r4-fetch.log
bash "$COPY/check-live.sh" --snapshots  > check-live.r4-snapshots.log
```

**Order matters, because logs are pinned.** `C1` pins revision 1's scripts and
logs, `R6` pins those plus revision 2's, and `V13` pins everything. So the
scripts ran once, in the order above, and each digest table was filled in from
the bytes just written before the next script ran. The shared files that a
later script rewrites on every run — `check-offline.r2-rerun.log`,
`check-standard-r2.r3-rerun.log` and `check-standard-r3.r4-rerun.log` — are
pinned nowhere. Revision 1's `shellcheck.log` and revisions 2 and 3's
`shellcheck-r2.log` and `shellcheck-r3.log` describe earlier script bytes and are
kept as history; `shellcheck-r4.log` is the current record. Revision 5 repeated
that sequence's `check-standard-r2.sh`, `check-standard-r3.sh`, `shellcheck` and `check-standard-r4.sh` lines, in that order, with
stderr merged into each log so that a grep error cannot go unrecorded again.
Revision 6 repeated the same four lines, in the same order, with a warm
private `CARGO_HOME` and `CARGO_TARGET_DIR`; `shellcheck` again printed nothing,
so `shellcheck-r4.log` is unchanged.
The logs of the first three scripts were not re-recorded; `check-offline.sh`
still re-ran nested, through `C9`, into its unpinned `check-offline.r2-rerun.log`.

**`check-offline.sh` — 28 checks, all offline.** It re-verifies at source the
claims of `raw/opus.md` that need no network: the registered report's digest
(`O1`); its bundle answer shape through
`validate_answer_text(text, "bundle")` from `scripts/research_validation.py`,
including the `### Members` window rule that keeps every H5 field inside a named
member (`O2`, **0 errors**); the byte-identity of all seven `- assumes` values in
this decision, compared character for character by a table parser rather than
by eye — six against the live registry and, since revision 7, `web-extra-surface`
against R69 revision 11's owned value at line 1885 (`O3`); the absence of any
`- owns` line (`O4`); R69 revision 11's owned value at line 1885, bound by sha256,
which is what earns the prose note beside the line (`O5`);
R49's no-`build.rs` clause (`O6`); the F308/F328/F329 ledger rows (`O7`); R60's
recorded ruling (b) (`O8`); the acceptance rows for R55, R57, R02, R05, R03 and
R56 (`O9`); the W1-CODEX3 ruling (`O10`); the owner's licence ruling (`O11`); the
in-flight coupling facts in R70's, R51's, R79's and R77's raw reports
(`O12`–`O15`); R67's catalog rows and the absence of a diagnostics row (`O16`);
the accepted revisions of R02, R05 and R03 (`O17`); R02's `crates/core`
(`O18`); R05's `spawn_blocking` (`O19`); py's `/healthz`, `readyz` and 503 at the
pin (`O20`); py's one-function-two-callers pattern (`O21`); **both** of py's
readyz tests including the monkeypatched 503 (`O22`); py's four checks with
exactly one error-capable status (`O27`); ts's zero matches (`O23`); the owner
reference's C15 sentence and its edition 2021 line (`O24`); this decision's own
shape — exactly one `re-verify:` line, one `## Supersedes`, and six `^## ` lines,
one of them inside the conformance note's fence (`O25`); its gate-1 wording
(`O26`); and the counted absence of any diagnostics term in R55's and R57's
published decisions (`O28`).

**`O17` now binds by identity (EA-1).** Revision 3's `O17` checked that each
coupled decision's H1 named the cited revision. R05's working file has since
become an unaccepted later revision, so the check failed and cascaded into
`C9` and `R7`. `O17` now pins each decision to the (revision, sha256) its row in
`docs/port/OWNER-ACCEPTANCES.md` records — R02 revision 2 `9e8f8e8c…` (line
71), R05 revision 3 `3ca4b81a…` (line 75) and R03 revision 1 `610e3338…` (line
70) — asserts that each row still says so, and then finds the file whose bytes
hash to it. The file is the live `DECISION.md` or the `R##-r<N>-snapshot.md` a
later revision preserved. For R05 it is `R05-r3-snapshot.md`. `O18` and `O19`
read the files `O17` located. No `.git` is needed, so the check survives an
archive extraction. A re-bind to a new accepted revision changes the row and
fails `O17`, which is the re-verify trigger this revision adds.

Result: **28 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-offline.log`.

**`check-probe.sh` — 13 checks against a throwaway axum workspace.** The workspace
is created by `mktemp -d` under `$TMPDIR` from the committed sources in
`review/evidence/probe/`, built, exercised, and **deleted on exit by a trap**; no
`target/` tree and no nested git repository is ever committed. It resolves
**axum 0.8.9 · tokio 1.53.1 · serde 1.0.229 · serde_json 1.0.151 · tower 0.5.3**
(dev-dependency, for the `ServiceExt::oneshot` idiom R69 selects), edition **2024**
throughout, and `rust-version = "1.96"` on every manifest. **It builds
`--locked` from a committed lockfile (EA-4):** `probe/manifests-a/Cargo.lock`
and `probe/manifests-b/Cargo.lock`, which differ only in the two local packages'
versions. Both pin the transitive crates at the versions revision 1 measured,
`hyper-util 0.1.20` and `smallvec 1.16.1`; a fresh resolution on 2026-09-27
picked `0.1.21` and `1.16.2`. `--offline` succeeds only from a warm local
registry cache, so the script tries it first and falls back to an online fetch,
still `--locked`, when the cache is cold. The recorded run printed
`cargo network flags: '--locked'`: the offline attempt failed and the online path
ran, holding the committed resolution. It **measures**; it does not assert a
latency or a throughput, and it does not build the template.

| Check | What it asserts | Observed |
|---|---|---|
| `A` | `env!("CARGO_PKG_VERSION")` inside a member reports the **member's** version, and `std::env::consts::{OS, ARCH}` resolve as `&'static str` with no `build.rs` anywhere in the tree | `facade_env_CARGO_PKG_VERSION=0.4.2`, `web_member_env_CARGO_PKG_VERSION=0.1.0`, `std_env_consts_OS=macos`, `std_env_consts_ARCH=aarch64`, `os_and_arch_are_static_str=true` |
| `B` | `[workspace.package] version` + `version.workspace = true` repairs it | all three packages report `0.4.2` |
| `T1` | `GET /healthz` → 200 with exactly four fields | `{"status":"ok","version":"0.4.2","os":"macos","arch":"aarch64"}` |
| `T2` | the liveness body is byte-stable across calls | `byte-stable=true` |
| `T3` | warn-only checks keep readiness | `200`; checks `build`/`config-file`/`credential` with statuses `ok`/`warn`/`warn` |
| `T4` | the drain latch removes traffic | `503 Service Unavailable`, body still carrying the report under `diagnostics` |
| `T5` | draining is not a restart signal | `GET /healthz` still `200` |
| `T6` | a hand-built error report yields 503 **without touching the environment** | `503` from the pure `readiness_response(false, report)` |
| `T7` | probe method handling | `POST /healthz status=405 Method Not Allowed allow=Some("GET,HEAD")` |
| `T8` | `HEAD` is served by the `GET` handler | `200`, `body_len=0` |
| `C9` | a default build has no probe surface | `axum` occurs on **0** lines of `cargo tree -p facade --edges normal` |
| `C10` | `--features web` brings it back | the optional member and `axum v0.8.9` reappear |
| `C11` | the member holding the shared function names no web crate | `probe-core` → `serde v1.0.229` → `serde_core` + `serde_derive`; `axum|tokio|hyper|tower` matched on **0** lines |

Result: **13 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-probe.log`. `T6` is the check that matters most: because it
drives the pure `readiness_response` function rather than the handler, the 503
branch is provable on any machine in any environment — which is exactly the
property py has to reach with a monkeypatch.

**`check-live.sh` — 9 checks against the live sources, script unchanged.** `L1`
the eight crates' `max_stable_version` against the pins this decision names;
`L2` the declared-MSRV facts that decide gate 2 (`shadow-rs` and `git-version`
still `rust_version: null`; `built` 1.87; `vergen` 1.96.0); `L3` the RustSec
picture with `atty` as a 200 control; `L4` `RUSTSEC-2025-0023`'s open-ended
`>=1.44.2` patched range; `L5` the four Kubernetes sentences quoted in this
decision, the back-end-dependency caution included; `L6` the build-script
requirement in `built`'s, `vergen`'s and `shadow-rs`'s own READMEs and
`git-version`'s git-binary requirement; `L7` the two production probe
implementations read at `raw.githubusercontent.com`; `L8` the crates.io census;
`L9` the four build-metadata repositories through keyring-authenticated `gh api`,
**never faster than one call per 20 s** (the script enforces the spacing itself),
with the `git-version` HTTP 422 reproduced and recorded absent. No token bytes
and no personal email address appear in any script, log, snapshot or User-Agent;
the User-Agent is
`rs-launch-blueprint-research (+https://github.com/smorinlabs/rs-launch-blueprint)`.
Revision 1's `check-live.log` stays the paired log. For revision 4 the script ran
twice more from a copy under `$TMPDIR`: in fetch mode against the live sources on
2026-09-27, saved as `check-live.r4-fetch.log`, and in `--snapshots` mode against
the committed snapshots, saved as `check-live.r4-snapshots.log`. Result:
**9 PASS, 0 FAIL, 0 SKIP** in each.

**`check-standard-r2.sh` — 42 checks, added by revision 2.** `S1`–`S26` read the
pinned blob with
`git -C /Users/stevemorin/c/rest-standards show 71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
and assert each quoted rule **at its recorded line number**, printing the line it
found, so a rule whose text moves FAILs rather than being silently re-read;
`S27` counts rule lines naming health, readiness or liveness and asserts **0**,
which is what makes the argument-from-general-rules necessary rather than lazy.
`P1`–`P6` build an r2 probe workspace under `$TMPDIR` from
`review/evidence/probe-r2/`, with revision 1's facade, core and `manifests-b`
unchanged, the committed `manifests-b/Cargo.lock`, and `--locked`. They measure
axum 0.8.9: `P1` and `P2` assert the moved `Cache-Control: no-cache` on
liveness and on **both** readiness branches; `P3` measures `GET /healthz/`
answering `404` with no `Location` where R2.6 prefers `308`; `P4` measures
`Accept: application/xml` answering `200` with JSON where R4.10 prefers `406`;
`P5` measures the handlers emitting no `request-id`, which is the evidence behind
the obligation handed to R75; `P6` re-asserts `405` with `Allow: GET,HEAD` now
that R5.11 makes it a MUST. `C1`–`C9` assert this decision's own claims. `C1`
compares the sha256 of the twelve revision-1-era scripts, logs and probe sources
against digests recorded in the script. `C2` pins the current H1 and `C4` the
override name. `C7` counts headings outside code fences the way the publication
validator counts them, because the conformance note embeds the standard's own
section 1.9 template, whose first line is an H2 inside a fence. `C9` re-runs the
offline script into `check-offline.r2-rerun.log` and now expects **28 PASS and
0 FAIL**; through revision 3 it expected one named failure, `O25`.

Result: **42 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-standard-r2.log`.

**`check-standard-r3.sh` — 7 checks, added by revision 3.** `R1` pins the
current H1. `R2` counts the override heading: the old heading appears **0** times
and `OVERRIDE (OV-05)` appears **11** times in revision 4, its own H4
included. Revision 3's prose said 10 where its own log said 11; check `V10` now
compares the number stated in this sentence with the file, so the two cannot
diverge again. `R3` accounts for every surviving bare mention of the old number
by region — 11 occurrences, all in the revision-3 note, the allocation paragraph
or the history, **0** stray; revision 4's note names the old number 0 times.
`R4` re-measures the decision's shape outside code fences, and `R5` re-counts the
seven `- assumes` lines, the absent `- owns` line, the single
`**Argument:**`/`**Options:**` pair and the gate-1 wording. `R6` compares the
seventeen artifacts of revisions 1 and 2 by sha256. `R7` re-runs the revision-2
script into `check-standard-r2.r3-rerun.log` and now expects **42 PASS and 0
FAIL**; through revision 3 it expected exactly `C2` and `C4` to fail.

Result: **7 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-standard-r3.log`.

**`check-standard-r4.sh` — 14 checks, new, one per repair.** `V1` pins the
current H1, now revision 6's, the revision-3 snapshot's sha256, and, since
revision 5, the revision-4 snapshot's sha256 and H1, and, since revision 6, the
revision-5 snapshot's. `V2` asserts the Muse leg's
digest, its bundle shape (0 errors) and its retrieval date, and accepts its
operation in one of two states: uncollected (`submitting`, no `raw_sha256`), as
on 2026-09-27, or collected at exactly this digest. `V3` asserts the engine set: the
manifest's one migration event (`codex` → `muse`, Q5.A), `required_engines`
`muse, opus`, the live `engine_overrides` row, and RUNBOOK section 2's Q9.B and
Q17.A sentences. Since revision 6 it also asserts the empirical seat R80 takes
from the live policy, `codex`, read as the validator reads it, with no
`empirical_auditor_overrides` entry meaning the default. `V4` is the I-prompt check: `inputs/prompt.md` is
byte-identical to the live topic prompt and to the manifest's recorded prompt
hash `7596eda6…`, and reads `- engines: muse, opus`; it also prints whether the
other frozen inputs equal their live files. `V5` anchors each Muse disagreement
at source in `raw/muse.md`. `V6` asserts R22 revision 1's acceptance row, its
placement text, its re-verify trigger, and R69's facade→web edge at line 1885
of revision 11. `V7` asserts R55 and R57 published at their accepted bytes. `V8` is
the static proof for EA-3: across all six scripts, **0** lines pipe into
`grep -q`. As revision 4 recorded it, `V8` could not fail (audit EF-1). Since
revision 5 its patterns escape the leading pipe, a grep status of 2 or more
fails the check, and a positive control must count **1**. `V9` asserts both lockfiles' seven pins, `--locked` on both cargo
paths of both build scripts, and both logs recording it. `V10` asserts that the
override count and the three census denominators this prose states equal the
logged ones. `V11` asserts the archive assertion-diff sizes stated below. `V12`
asserts the one `re-verify:` line and its three new triggers. `V13` pins 22
artifacts by sha256. `V14` re-runs the revision-3 script into
`check-standard-r3.r4-rerun.log` and expects **7 PASS and 0 FAIL**, which nests
the revision-2 and offline re-runs, so one call exercises the whole chain.

Result through revision 6: **14 PASS, 0 FAIL, 0 SKIP**, exit 0. Revision 7's
re-recording of `review/evidence/check-standard-r4.log`: **12 PASS, 2 FAIL,
0 SKIP**, exit 1; `V3` and `V4` fail on the `manifest.json` drift revision 7's note
records, and every other check passes. Through revision 6, `shellcheck` on all six scripts exits 0
with no output, recorded in `shellcheck-r4.log`. Revision 5's re-recording gives
the same totals, and its log contains no grep error. Revision 6's re-recording
gives the same totals, and `V3` prints `policy_empirical_auditor_R80=codex`.

**Reproduction, stated exactly rather than asserted.** Every re-recorded log was
re-run once more from a copy of `evidence/` under `$TMPDIR`, against the same
repository root, and diffed against the committed log. Two kinds of line cannot
repeat and are normalised out of every comparison: the `date(UTC):` stamp, and
the `mktemp` workspace path the probe prints and `cargo tree` echoes back. The
diffs are committed as `*.rerun.diff` (the whole log) and
`*.rerun.assertions.diff` (every `PASS`/`FAIL`/`SKIP` line and the totals line),
replacing revision 1's files of those names. The same two
kinds of file were also written for `check-standard-r4.log` and
`check-live.r4-snapshots.log`.
**`check-offline.log`, `check-standard-r3.log`, `check-standard-r4.log` and
`check-live.r4-snapshots.log` reproduce byte-for-byte** after normalisation: each
`.rerun.diff` is **0 bytes**. **For `check-probe.log` and `check-standard-r2.log`
the assertion lines reproduce byte-for-byte and the rest does not**: each
`.rerun.assertions.diff` is **0 bytes**, while the whole-log diffs carry 8 and 4
differing lines. Every one of them is a cargo `Finished` timing line or the test
harness's `finished in` duration, and **0 differing lines are anything else**.
Because the target directory was already warm, no `Compiling` line differs.
`check-live.r4-fetch.log` has no rerun diff: fetch mode reads moving counters by
design (below).
Revision 5 repeated this reproduction for its three re-recorded logs, with the
same normalisation, and its six rerun diffs replaced revision 4's files of those
names. `check-standard-r3.log` and `check-standard-r4.log` reproduce
byte-for-byte: each `.rerun.diff` is **0 bytes**. For `check-standard-r2.log`
the `.rerun.assertions.diff` is **0 bytes**, and the whole-log diff carries
**4** differing lines, two before-and-after pairs: the cargo `Finished` timing
line and the `finished in` duration.
Revision 6 repeated it once more for the same three logs, and its six rerun
diffs replace revision 5's. `check-standard-r3.log` and `check-standard-r4.log`
reproduce byte-for-byte: each `.rerun.diff` is **0 bytes**. For
`check-standard-r2.log` the `.rerun.assertions.diff` is **0 bytes**, and the
whole-log diff carries **2** differing lines, one before-and-after pair: the
cargo `Finished` timing line.
Revision 7 repeated it for its four re-recorded logs, `check-offline.log`,
`check-standard-r2.log`, `check-standard-r3.log` and `check-standard-r4.log`,
and its eight rerun diffs replace the prior files of those names. The
normalisation also maps the probe's `r80-probe-r2.*` workspace path, which the
`Compiling` lines echo, to one placeholder. `check-offline.log`,
`check-standard-r3.log` and `check-standard-r4.log` reproduce byte-for-byte:
each `.rerun.diff` is **0 bytes**. For `check-standard-r2.log` the
`.rerun.assertions.diff` is **0 bytes**, and the whole-log diff carries **4**
differing lines, two before-and-after pairs: the cargo `Finished` timing line
and the `finished in` duration.

**Revision 1's archive diffs are history, and one of revision 3's statements
about them was wrong.** The `*.archive.diff` and `*.archive.assertions.diff`
files come from a `git archive` extraction of revision 1's commit `f940e56`, and
they describe revision-1 logs. Of the three `*.archive.assertions.diff` files,
two, for the offline and probe scripts, are 0 bytes. The third,
`check-live.archive.assertions.diff`, is **96 bytes**: it holds the single
`mode: fetch` versus `mode: snapshots` banner line (check `V11`). Revision 3 said
all three were 0 bytes. **No archive reproduction exists for revision 4.** This
seat may not commit, and a `git archive` of `HEAD` would extract revision 3's
scripts, not these.

**`check-live.sh` cannot reproduce byte-for-byte, and this decision does not claim
that it does.** crates.io download counters and search denominators move between
reads, and not only upward. Its assertions are therefore written on
**structure and pins** — version strings, `rust_version` null-ness, HTTP status
codes, quoted sentences — and never on a counter; every moving figure is *printed*
beside its endpoint so a reader can see what it was. Revision 1's log recorded the
three census denominators on 2026-09-18, a few hours after `raw/opus.md` read them:
`q=health` 6,487 → **6,488**, `q=probe` 5,271 → **5,273**, `q=liveness` 28,351 →
**28,347**. The liveness denominator fell by 4. Revision 3 printed a figure 9 higher,
which no artifact supports. The 2026-09-27 fetch-mode run read
6,657 for health, 5,567 for probe and 29,607 for liveness, and
`check-live.r4-snapshots.log` reproduces the committed snapshots' 6,488, 5,273 and
28,347 exactly. Every
reduced response body the script reads is snapshotted under
`review/evidence/snapshots/`, and `--snapshots` mode re-runs every assertion
against those committed bytes with no network at all. The snapshots of crates.io
JSON and of the two kubernetes.io pages are **reduced in place** by a projection
the script documents and applies before any assertion, so the committed artifact
and the artifact the assertions read are the same bytes in both modes; nothing
else is reduced. The revision-4 fetch-mode run wrote its refreshed snapshots into
the `$TMPDIR` copy, never into `evidence/snapshots/`.

**Not run, and why.** No `ubuntu-latest` execution: every check above ran on macOS
only, so each member's gate-4 Linux answer rests on the crates' own CI and on R66's
and R69's prior records. No process-level test of the drain window (AC11): it needs
a running `<app>-serve` binary and none exists. No measurement of the
`spawn_blocking` hop under concurrency: R05 records the same gap for the same
bridge. No issue-responsiveness figure for seven of the eight crates: each needs
roughly eleven GitHub calls at the mandated one-per-20-seconds, and no member's
verdict turns on it — the figure `raw/opus.md` did compute, for `lukaslueg/built`
(median 0 days, about 3.4 hours, 0 of 4 unanswered), is **carried without
re-collection**. No archive reproduction for revision 4, for the reason above.
No re-collection of `raw/muse.md`'s 2026-09-25 figures.

**Proposed for the template's CI, not run here** (job wiring is R11's, tiers are
R32's): `cargo test --features web` and `cargo build --features web --bin
<app>-serve` on `ubuntu-latest` and `macos-latest`; `T1`–`T8` as template
integration tests through `oneshot` and once against a real listener; a
version-consistency test asserting `GET /healthz`'s `version` equals what
`--version` prints, the Rust analogue of py's `tests/meta/test_version_consistency.py`,
which fails loudly if the constant is ever evaluated in the wrong package; a
`cargo check` leg pinned to the declared `rust-version`; and the AC11 `SIGTERM`
test. None of these can run today: no Rust code exists in this repository.

## Engines

**Engine set: Muse and Opus. Codex was substituted, not skipped.** The binding
prompt reads `- engines: muse, opus` and says that this item substitutes Muse
(Meta) for Codex and that its mirrored `- engines:` line is authoritative
(`inputs/prompt.md:25` and `:74`; the file is byte-identical to the live topic
prompt, check `V4`). The run's `manifest.json` records the substitution as its
one migration event, at 2026-09-21T23:06:21Z: `from` `codex`, `to` `muse`, reason
*"muse bulk substitution (owner decision Q5.A 2026-09-21)"*, previous engines
`codex, opus`, now `required_engines: ["muse", "opus"]`, state `partial` (check
`V3`). Owner decision Q9.B then retired Codex from P02 altogether. The live
`engine_overrides` map in `research/EXECUTION.json`, as last amended under Q17.A
on 2026-09-27, lists R80 as `muse, opus`. Its `empirical_auditor_overrides`
map has no R80 entry, so R80 takes the default `codex` empirical seat
(`scripts/research_validation.py` line 705, `seat_overrides.get(item, "codex")`). The
rulings are recorded in `research/RUNBOOK.md` section 2 (lines 70–76) and in the
execution ledger, `docs/planning/p02/execution-ledger.md`: the entry *"Owner
decision (2026-09-21, Q5.A)"* (line 1114), the 2026-09-22 entry carrying
*"Owner decision (Q9.B)"* (line 1121), and *"Q17.A IMPLEMENTED (2026-09-27)"*
(line 1215). Other sessions edit the ledger, so the entry titles govern if the
line numbers move. Revision 3 said that the Codex leg was deferred
under W1-CODEX3 and that this was a single-engine synthesis. That described the
run before the substitution and is withdrawn. W1-CODEX3
(`docs/planning/p02/owner-decisions.md:488`, check `O10`) remains the reason the
Opus leg ran alone at first. **Three frozen inputs are stale.**
`inputs/prompt.md` equals the live prompt, but `inputs/EXECUTION.json`,
`inputs/CLAUDE.md` and `inputs/PARAMETERS.md` differ from their live files
(`V4` prints each comparison). This decision reads the live registry for every
`- assumes` value (`O3`). Re-freezing `inputs/` is the controller's; this seat
may not write there.

- **opus** — `raw/opus.md`, sha256
  `dd3bdeae9566ae10ea300c1c2e6727264075523cb2ccce1e95eea9eccc06a0fb` (Claude Opus
  5, collected 2026-09-18T22:26:40Z, registered in `manifest.json`; digest and
  bundle answer shape re-verified here by checks `O1` and `O2`).
- **muse** — `raw/muse.md`, sha256
  `395c1426cd8db1e2d46588dcd364caac86a0beca6ca3119d5b7a56333672b012` (Muse Spark,
  Meta, `model: muse-spark` in the operation record; live figures retrieved
  2026-09-25). It passes the bundle answer shape with 0 errors:
  `scripts/check-answer-shape.sh raw/muse.md bundle` printed
  `OK: validation passed`, and check `V2` re-asserts it through
  `validate_answer_text`. **It is present but not collected.**
  `operations/muse.json` is still in state `submitting` (request
  `9d63b9c66e354800a931ac35871f647d`) with no `raw_sha256`, and the file is not
  tracked by git. Collecting and registering it is the controller's work. This
  decision adjudicates the bytes on disk and names their digest, so a collected
  file with a different digest is a re-verify trigger.

**Where the two reports agree.** Muse and Opus agree on the shape of the answer,
and this decision carries each point on its own evidence:

| Point | Muse | Opus | This decision's evidence |
|---|---|---|---|
| one synchronous diagnostics function, called by the CLI `doctor` command and by `/readyz` | yes | yes | F329; py's pattern (`O21`) |
| `serde`-derived response bodies rather than a hand-written literal (the prompt's MEDIUM question) | yes | yes | Apollo Router's derive (`L7`); py's `response_model` comment |
| `/readyz` needs no crate beyond the envelope, the framework and `serde` (the other MEDIUM question) | yes | yes | the members table: zero added crates |
| no maintained probe crate worth adopting (the LOW question) | yes | yes | the census (`L8`) |
| both paths unversioned under F308 | yes | yes | `O7` |
| the 503 carries R70's problem envelope | yes | yes | py's `problem_response` (`O20`) |
| open issues: `built` 8, `vergen` 4, `serde` 319 | yes | yes | the figures table |

**Where they disagree, and what resolved each.** Muse recommends a different
stack: `built` 0.8.1 as a build-dependency with a `build.rs`, a liveness body
carrying `rustc_version`, `git_sha` and `uptime_seconds`, a two-state check, and
no readiness latch. Each point is answered by evidence this decision already
held, and none required new research. The anchors in `raw/muse.md` are asserted
by check `V5`.

1. **Stack: `built` 0.8.1 with a `build.rs`. Rejected on fit, and Muse's own
   parameter claim is corrected.** Muse's migration plan adds a `build.rs` calling
   `built::write_built_file()`. R49's published `build-tool-output-shape`, which
   this decision assumes, says *"no build.rs and no build-orchestration crate"*
   (check `O6`), and R22's accepted revision 1 repeats "no `build.rs`" for the
   version itself. Muse's recommendation therefore needs R49's value changed,
   which is the case RUNBOOK section 4 says a `CONFLICT:` line must record. Muse
   raises none and states *"No `CONFLICT:` lines — the recommendation fits all
   consumed values."* That statement is wrong. This decision does not raise the
   `CONFLICT:` on Muse's behalf, because its own recommendation needs no such
   change: Cargo's version and `std::env::consts` realize the liveness principle
   with no build script (checks `A`, `T1`). Muse's runner-up `vergen` and its
   up-and-comer `vergen-gitcl` fall on the same clause (check `L6`).
2. **Liveness fields: `rustc_version`, `git_sha`, `uptime_seconds`.** Muse itself
   concedes that *"`rustc --version` via `RUSTC_VERSION` is not built-in — it
   needs a build script"*; a git SHA needs the same mechanism, so both fall with
   point 1. The principle both fields serve, identifying the build that answers,
   is met by `version`, `os` and `arch` (the liveness-payload paragraph above).
   Uptime is declined for the three reasons stated there: it destroys AC2's byte
   stability (check `T2`), it forces a redaction into R33's snapshot tests, and
   neither surveyed production system emits it (check `L7`). Muse argues for it
   from availability only. Muse also says the prompt's HIGH question *"explicitly
   asks `/healthz` to report"* the toolchain version and git SHA. That overstates
   the prompt, which asks *what* the endpoint reports and lists "binary version,
   build metadata, uptime, Rust/toolchain version" as candidates
   (`inputs/prompt.md:36`).
3. **Check status: `ok: bool` versus `CheckStatus { Ok, Warn, Error }`.** A
   boolean must fold `warn` into one side. Folded into failure, a missing config
   file or credential would remove every replica from traffic on a fresh install.
   py treats both as warnings (*"Missing token/config are warnings, not errors, so
   readiness holds"*, check `O22`), and AC4 requires the same (executed as `T3`).
   Folded into success, the CLI `doctor` loses the warning. py itself uses three
   statuses (check `O27`). The three-state type stays.
4. **Lifecycle: no readiness latch.** Muse proposes alternative A alone, re-running
   the diagnostics on every probe. The two arguments for alternative C answer it:
   only a latch can report the drain state (checks `T4`, `T5`; AC6, AC7), and
   without one the 503 branch is unreachable from a real environment (checks
   `O22`, `O27`). Muse's own validation plan reaches 503 by toggling a stub check,
   which is the same substitution py's test needs.
5. **Fitness gates.** Muse answers gate 1 per candidate. Those answers are not
   carried, for the reason recorded under `## Decision` (checks `O11`, `O26`).
   Muse says `built` *"passes all six fitness gates"*. On gates 2 to 6 this
   decision agrees: `built` declares `rust-version` 1.87 (check `L2`) and has no
   RustSec entry (check `L3`). Its exclusion is on fit, labelled as not a gate.

Four lesser disagreements:

6. **Placement.** Muse puts the module at `src/core/diagnostics.rs` in a single
   library crate, with `run_diagnostics()` taking no argument. R02 revision 2's
   accepted four-package workspace puts it in `crates/core` (check `O18`), and it
   takes `&Config` because the config-file check reads configuration.
7. **Bridge.** Muse calls `spawn_blocking` "only if a check blocks". This decision
   always does, following R05 revision 3 (check `O19`), for the consistency and
   extensibility reasons in the bridge paragraph.
8. **Standard.** Muse's report does not weigh the REST API Design Standard, which
   binds under owner ruling W2-REST, and emits no `Cache-Control`. R7.1's header
   and R5.17's redaction stand (checks `P1`, `P2`).
9. **Figures.** Muse's 2026-09-25 crates.io counters are a week later than this
   decision's 2026-09-18 table and larger, as download counters grow: `built`
   19,003,082 in 90 days and 65,076,989 all-time, `vergen` 9,061,345 and
   53,257,922, `serde` 324,724,704 and 1,439,926,984. They are carried as Muse's
   and not re-collected; no verdict turns on them. Muse records GitHub stars,
   `archived` and `pushed_at` as a gap after a rate limit; this decision has them
   for `built` and `vergen` (check `L9`).

**Muse claims carried, and claims corrected.** Carried at Muse's own confidence:
the agreement points above, and its reverse-dependency totals (`serde` 124,928,
`built` 237, `vergen` 203), which were not re-collected. Corrected: its claim that
the recommendation fits all consumed values (point 1), its reading of the prompt
(point 2), its gate-1 answers (point 5), and its single-crate placement (point 6).

**Re-verified here, with the check that did it.** The registered report's digest
and shape (`O1`, `O2`). The seven `- assumes` values against the live registry
(`O3`), `web-extra-surface` against R69 revision 11 since revision 7. R69
revision 11's owned value at line 1885 (`O5`). R49's
no-`build.rs` clause (`O6`). The ledger rows (`O7`). R60's ruling (`O8`). The
acceptance record (`O9`). The W1-CODEX3 and licence rulings (`O10`, `O11`). The
four in-flight couplings (`O12`–`O15`). R67's catalog (`O16`). The accepted
revisions of R02, R05 and R03, bound by sha256, and their clauses
(`O17`–`O19`). The py and ts source
precedent at the programme pins, including both readyz tests and the error-capable
check count (`O20`–`O22`, `O27`, `O23`). The counted absence of a diagnostics
check in R55's and R57's accepted decisions (`O28`). The owner reference's two
rows (`O24`).
The whole endpoint contract in axum 0.8.9 and tokio 1.53.1 — routing, statuses,
the latch, the `spawn_blocking` bridge, `405` with `Allow: GET,HEAD`, `HEAD`
handling, byte stability, the feature gating and the core member's dependency
graph (`A`, `B`, `T1`–`T8`, `C9`–`C11`). The crates.io pins and MSRV facts, the
RustSec picture with its control, the Kubernetes sentences, the build-script
requirement in three maintainers' own READMEs, the two production probe
implementations, the census, and the four build-metadata repositories' GitHub
rows (`L1`–`L9`). Revision 4's repairs: the Muse leg's digest, shape and
collection state, the engine substitution, the frozen prompt, the Muse
disagreement anchors, R22's accepted text and R69's facade→web edge, R55's and
R57's published bytes, the absence of any racy pipeline, the lockfiles, and the
figures this decision states (`V1`–`V12`).

**Carried from `raw/opus.md` without re-verification, and therefore held at the
report's own confidence.** The GitHub rows for `serde`, `serde_json`, `axum` and
`tokio` (stars, `archived`, open issues) — only their crates.io pins were
re-checked. The `unsafe` postures read from axum's and tokio's manifests. The
issue-responsiveness figure for `lukaslueg/built` and the statement that it was not
computed for the other seven. `rust-lang/crates.io`'s use of a runtime environment
variable for its deployed commit, and its `utoipa::ToSchema` derive on the
analogous build-identity response. The Cloud Run 10-second SIGTERM window, which
reaches this decision through R69. The observation that the four kubernetes.io
pages read for the report configure probes on the Pod spec and none mentions a
Dockerfile `HEALTHCHECK` — an observation about those pages, not a claim about
kubelet behaviour.

**Claims of `raw/opus.md` found wrong or overstated, and corrected above rather
than carried.**

1. **Wrong.** *"there is no test in that file for the 503 branch"* (py's
   `tests/web/test_app.py`). There is:
   `test_readyz_failure_is_a_problem_with_diagnostics` at lines 248-262 asserts
   `503`, reaching the branch by monkeypatching `run_diagnostics` with a hand-built
   failing report (check `O22`). The corrected form is in
   `### Principles and implementation`: the substitution is the evidence that the
   branch is unreachable from a real environment, which is the point the report was
   reaching for. **The recommendation does not move**: alternative C is selected
   for the drain state it can report, which alternative A cannot report at all.
2. **Stale citations.** The report cites **R02 revision 1** and **R05 revision 2**.
   The accepted revisions are **R02 revision 2** (`9e8f8e8c…`) and **R05 revision
   3** (`3ca4b81a…`), both evidence-only re-binds whose substance is unchanged
   (check `O17`). This decision cites the current revisions.
3. **Wrong status.** The report calls **R55 and R57 "open"**. Both are
   **owner-accepted and now published** — W1-R55 at revision 3 (2026-09-17) and
   W1-R57 at revision 2 (2026-09-16) (checks `O9`, `V7`). The substantive point
   survives in a stronger form: neither published decision names `run_diagnostics`,
   `doctor`, `readyz` or `CheckStatus` on any line (check `O28`), so the check list
   that could reach `CheckStatus::Error` is **unowned**, not merely unpublished.
4. **Overstated.** *"R77 owns the window's value"* for the pre-drain
   readiness-propagation pause. R77's in-flight report owns a drain **deadline**
   (`RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, recommended 8 s) and mentions a
   propagation or pre-drain pause on **0** lines (check `O15`). Recorded above as a
   requirement this item hands to R77, not as a fact about R77.
5. **Not carried.** The report answers **fitness gate 1** per candidate ("MIT,
   compatible with `MIT OR Apache-2.0`"). Those verdicts are struck; gate 1 is
   recorded as `inapplicable — owner ruling 2026-09-12 (Q7.B)` in the wording the
   revision rules prescribe (check `O26`).
6. **Newly surfaced, not in the report.** R70's in-flight raw report both reserves
   its envelope to "one extension member and no more" and hands `/readyz`'s failure
   body to R80 (check `O12`). The report assumed a `diagnostics` extension member
   was available. This decision states the requirement three ways and leaves the
   choice to R70.
7. **Drift, not error.** The census denominators moved between the report's
   collection and revision 1's on the same day, in both directions (6,487→6,488,
   5,271→5,273, and 28,351→28,347, a fall of 4). The comparison rule is under
   `## Empirical check`.
8. **Probe fidelity, stated so it is not mistaken for the recommendation.** The
   executed probe's shared function takes `(&Path, bool)` rather than the
   recommendation's `&Config`, because no published item defines `Config` yet; and
   its 503 body is a plain JSON stand-in, not R70's envelope. The probe exercises
   the *shape* — status codes, field sets, the latch, the bridge, the graph — and
   claims nothing about the final signature or the envelope's member names. Its
   `.expect(..)` on the `JoinHandle` is marked in the committed source as not the
   production shape.

**Revision 2's own re-verification, and what it could not prove.** Twenty-six
rules of the REST API Design Standard are quoted at the pinned blob and asserted
at their line numbers (`S1`–`S26`); the absence of any health or readiness rule
is counted, not assumed (`S27`); six conformance questions that only axum can
answer are measured (`P1`–`P6`); and the twelve revision-1 artifacts are
digest-compared so the pre-audit contract is enforced rather than promised
(`C1`). **Three conformance claims carry no executable check and say so.**
(1) **R5.17's redaction** of `Check::detail` — the real `Config` does not exist,
so the obligation is stated and P03 validates it; the executed probe deliberately
prints an unredacted path, which is what makes the obligation visible.
(2) **R5.12/R5.13's problem document** — the 503 body is R70's, still in flight,
so the probe's stand-in proves the status code and the presence of the report and
nothing about member names. (3) **R11.7's `request-id`** — `P5` proves the
handlers do not emit it, which is the *absence* the obligation rests on; that
R75's middleware will supply it is unproven here and unprovable until R75
publishes. **One further limit:** the standard binds the whole HTTP surface, and
this item owns two paths. The conformance note is therefore explicitly partial —
its tier, its switch declarations and its deviation list are the template's, and
R69, R70, R71 and R72–R76 each own rows this decision does not write.

**Unproven, and left for P03 to prove in the real template.** AC9 (one function,
two callers, one check list — needs the template's crates to exist). AC11 (the
drain window: `/readyz` answering 503 for the whole interval between the signal and
the exit, with the in-flight request completing and the process exiting 143 — needs
a running binary; the latch itself is executed, its interaction with R69's
`shutdown_signal()` and `serve_until` is reasoned from R69's recorded snippet). The
nonzero pre-drain pause that makes the latch observable to a fresh-connection probe
(needs an owner first). The package that holds R22's `VERSION` constant (R22's and
R02's). The Muse operation's collection and registration (the controller's). Every member's gate-4 answer on `ubuntu-latest`. The
concurrency cost of the `spawn_blocking` hop. And the 503 body's exact member names,
which are R70's to fix.

**Confidence.** **High** for the endpoint contract, the shared-function placement,
the latch, the method handling, the liveness payload's mechanism, the version
hazard and the feature gating: each rests on a published or owner-accepted artifact
*and* on a check executed here against the exact crate versions. **High** for the
census answering the prompt's LOW question, which has a printed denominator.
**Medium-high** for the drain-window behaviour, executed at the latch and reasoned
at the signal. **Medium** for the exact field list of `LivenessReport` — declining
uptime is a judgement with a stated cost, and adding a commit SHA is a one-field
change — and for the initial check set, which later items will extend. **Low
confidence is claimed nowhere**, and two figures are explicitly absent rather than
estimated: `git-version`'s open-issue count (HTTP 422, reproduced) and issue
responsiveness for seven of the eight crates. The Muse report disagrees on the
liveness field list and the check type; both disagreements are answered above on
this decision's evidence, and neither moves a confidence level.

## Supersedes

**Revision 3, 2026-09-18, sha256
`184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`, commit
`53b13f45`; superseded 2026-09-27 by two audit rejections.** Revision 3 is
preserved verbatim as `review/R80-r3-snapshot.md`. It was the controller's
override renumber and nothing else. It was audited — `review/audit-fable.md`
(judgment) and `review/audit-claude.md` (empirical), both `reject` — and never
published. **What revision 4 changed** is listed exhaustively in its revision
note: `## Engines` rewritten around the Muse + Opus engine set, with the Muse
report adjudicated; the R22 coupling rebuilt on R22's accepted revision; the
`re-verify:` line extended; three miscounts, one misquoted figure and the R55/R57
status corrected; four evidence scripts edited and their logs re-recorded; one
new script, two lockfiles and two live re-run logs added. **What it did not
change:** the recommendation and everything listed under "What did not change"
in the revision-4 note.

**Revision 2, 2026-09-18, sha256
`9d3e0a0791182aa62d04ab7b9d7960b8011b2a0ce4fa75243e77384e70deac88`, commit
`ce291fe`; superseded 2026-09-18 by the controller's override-number
allocation.** Revision 2 was never published and never audited. It is superseded
for one reason, recorded in the execution ledger as *"OVERRIDE NUMBER COLLISION,
2026-09-18"*: revision 2 and R77's revision 2 each allocated `OV-04` by
concurrent scoped searches, neither able to see the other's uncommitted work.
The controller resolved it by taking allocation in-house — R77 keeps `OV-04`,
this item takes `OV-05`. **Revision 3 is a renumber and contains no other
change**: not one rule verdict, not one option, not one word of the override's
argument, not one parameter line, and not one byte of any evidence artifact from
revision 1 or revision 2. The complete revision-2 content stands as written,
with `OV-04` read as `OV-05` throughout.

**Revision 1, 2026-09-18, sha256
`fde7de281d018980176edb2b95b68eaa635c27d5fec0d280a1abef68779f79a0`, commits
`d930c24`, `00b0293`, `f940e56` and `a8080b3`; superseded 2026-09-18 by owner
ruling W2-REST.** Revision 1 was never published and never audited, so this
section records the history rather than preserving a published entry verbatim.

**What revision 1 said.** The same recommendation, `probe-contract/v1`: one
shared synchronous `run_diagnostics` in `crates/core`, two hand-written axum
0.8.9 handlers in `crates/web/src/routes/ops.rs`, an `AtomicBool` readiness latch
flipped by R69's `shutdown_signal()`, no new crate at any version, settling F328
and F329 and applying F308 unchanged. Fifty checks over three scripts, all
passing in place and from a clean `git archive HEAD` extraction.

**Why it moved.** Owner ruling W2-REST of 2026-09-18 made the organisation's REST
API Design Standard v2.0.0 binding on this template's HTTP surface. Revision 1
was written against the Kubernetes probe contract, F308 and the coupled P02
decisions, and had no reason to consult the standard. Two of its clauses turned
out to be nonconformant once the standard bound: it emitted no `Cache-Control`
header (R7.1, a MUST) and it placed no redaction obligation on the diagnostic
report's `detail` field (R5.17, a MUST).

**What revision 2 changed, exhaustively.** (1) The H1 and this history. (2) A
`### Conformance with the REST API Design Standard v2.0.0` H3 inside
`## Decision`, carrying the rule-by-rule table, the provisional conformance note
in the standard's section 1.9 template, and `OVERRIDE (OV-05)`. (3)
`Cache-Control: no-cache` on both probe responses, in the recommendation bullets,
the members table and the migration table. (4) The R5.17 redaction obligation on
`Check::detail`, in the recommendation bullets and the migration table. (5) The
R70 coupling sharpened by R5.13 and R5.16. (6) A second obligation on R75 from
R11.7. (7) The `re-verify:` line extended with the standard's own triggers and
the pending OV-05 ruling. (8) A new evidence script `check-standard-r2.sh`, new
probe sources under `review/evidence/probe-r2/`, and their log.

**What revision 2 did not change.** The recommendation's stack, every version
pin, the shared-function placement and signature, the readiness latch, the
`spawn_blocking` bridge, the liveness field list, the declined uptime field, the
architectural alternatives and their dispositions, the fitness-gate answers, the
figures, every `- assumes` line, the absence of any `- owns` line, the absence of
any `CONFLICT:` line — and every byte of revision 1's three evidence scripts,
their six logs, their rerun and archive diffs, the 92 snapshots and the five
probe sources, which check `C1` compares by sha256 rather than by assertion.
