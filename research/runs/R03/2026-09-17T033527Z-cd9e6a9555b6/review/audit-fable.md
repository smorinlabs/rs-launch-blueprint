decision-sha256: 610e33381016a64c05efd6a1ba1196eb37807abb18d18c68e0d4e7d987586226
actor: audit-fable-2026-09-17T033527Z-cd9e6a9555b6-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# R03 port-absence-vs-failure-contract — judgment audit (revision 1, 2026-09-17)

Fresh context; I wrote none of this item's artifacts. The sha256 above was recomputed
over `review/DECISION.md` as read (`shasum -a 256`) and binds this audit to that exact
byte sequence. No prior `review/audit-fable.md` existed in this run (checked before
writing). Read whole: `review/DECISION.md`; `raw/opus.md` (`shasum -a 256` =
`5b023ff3cfbd32b0323e0f6d136cfa907399b3bfffee153ab07a147df4025719`, matching the value
`## Engines` records, 15 H3 sections); `raw/doxa.normalized.md` and the three per-provider
twins `raw/doxa-{openai,perplexity,gemini}.normalized.md` (15 H3 sections each);
`inputs/prompt.md`; the three evidence logs and the three scripts that produced them;
`research/topics/01-ports-and-adapters-seam/DECISION.md` and
`research/topics/67-error-and-exit-code-contract/DECISION.md`; `docs/port/PARAMETERS.md`;
`docs/port/COMMONALITY.md`; `docs/port/OWNER-REVIEW.md:47`;
`docs/port/DIVERGENCE-ANALYSIS.md:58,80`; `docs/planning/p02/owner-decisions.md` §12; and
`docs/superpowers/plans/p02-roles/judgment-auditor.md`. I reran no evidence script.

**The empirical (Codex) audit is deferred, and that absence is recorded honestly, not as a
defect.** `docs/planning/p02/owner-decisions.md` §12 carries the row `W1-CODEX` dated
2026-09-16 with the owner's answer `"Let's skip codex for now"` and the consequence
"*Codex research legs and empirical audits are deferred*" — the decision's `## Engines`
quotes both. `raw/codex-transcript.txt` ends in the usage-limit error
("try again at Sep 19th, 2026 7:27 AM"), `raw/codex-exit.txt` is `1`, and there is no
`raw/codex.md`; the transcript is the evidence of a leg that was attempted and stopped,
not of a leg quietly dropped. The role doc's instruction to read `review/audit-codex.md`
is moot for the same reason: no such file exists in this run, and none is owed until the
Codex leg resumes. `## Engines` states the right disposition — a later Codex report is
folded in by **revision**, not by a fresh research run. I judge the decision on the two
engines it has.

## Principle and agreement level

**The principle is stated at the right level, and the level is argued rather than
asserted.** The decision separates the spelling from the requirement in its first move:
the principle "is not 'use `Option`', which is a spelling. It is: a driven-I/O read that
finds nothing reports a normal outcome, and the decision that 'nothing' is a user-facing
failure belongs to the use case, not to the adapter that performed the I/O." Two
consequences are then derived independently — the adapter cannot know whether a caller
wants absence fatal (`delete --if-exists` versus `show <id>`), and absence and transport
failure cannot be confused by a caller reading only the type. That is a layer assignment,
which is the agreement level the decision names: **architectural pattern**.

**The source of the requirement is pinned, and the pin is labelled as carried.** HEX-12 in
`py-launch-blueprint` at pin `b08bccfb`,
`docs/design/0005-hexagonal-architecture-and-enforcement.md:134-138`, with HEX-13 at
`:161-175` pinning the adapter's half and `core/ports.py:47,49` /
`core/services/projects.py:56-63` as the matching code. The decision says outright that
"Both readings are `raw/opus.md`'s, taken from the pinned checkouts; this synthesis did
not re-read the two source repositories", cross-references the unproven table, and repeats
the label at every later reuse: the py adapter comment at `py_api.py:188-195` is "(quoted
from `raw/opus.md`; not re-read here)", and `sccache`'s `Cache::{Hit, Miss, None, Recache}`
is "on `raw/opus.md`'s reading, which this synthesis did not re-read". Opus does carry
those readings at those pins (`raw/opus.md:110,120,186,621`), so the carrying is faithful.
The one thinning is JF-2 below.

**The `harmonize: no` / owner-direction tension is reconciled on the documents, not
waved through.** I read both cited lines directly rather than accepting them as carried.
`docs/port/DIVERGENCE-ANALYSIS.md:58` is the "Harmonize = no (38 items)" paragraph, and it
names R03 explicitly among "four F items whose disagreement is a per-repo architecture
choice rather than a shared value". Line `:80` is the R03 row and its `ts-decisions` cell
reads "no recorded reason (ts-decisions: —); inferred: py deliberately splits 'is it
there' (adapter) from 'is absence an error' (service); ts folds both into one call site".
Both cites are accurate. The reconciliation — `harmonize: no` is right about the
*mechanism* (nothing about `Result<Option<T>, E>` transfers to Python or TypeScript), the
owner is right about the *layer assignment* — is the only reading that leaves both
documents standing, and it is the reading the analysis's own `:80` inference already
implies.

**No `BASELINE-REVIEW:` line is correctly withheld.** The decision's ground is that F012
is this item's own research row, not a retained `REUSE`/`ADOPT` baseline being challenged.
I verified this rather than accepting it: `/usr/bin/grep -c F012 docs/port/BASELINE-REVIEW.md`
returns **0**, and `docs/port/COMMONALITY.md:18` carries F012 as `different` / `DIVERGENT`
/ `R03` (r03-contract.log §7 prints the row; I read the file myself and it matches). The
F012 wording correction — that Rust must separate `Ok(vec![])` from `Ok(None)`, where the
ledger's "`None`/empty means absent" conflates them — is carried in the answer body with
the stated reason that this decision is what settles that row. That is the runbook's
disposition for a row the item owns, not a silent edit of someone else's baseline.

## Design and evidence

**The recommendation follows from the evidence as written.** Six alternatives A–F are
compared before any library is weighed, each with the principle at stake named. C is
rejected on a structural argument backed by std shipping `Option::transpose` to convert
*out of* that nesting — which is, as the decision says, the ecosystem's own statement of
which nesting is canonical, and it answers the prompt's second HIGH question directly.
F is rejected on `Path::exists`'s own TOCTOU warning, read at tag `1.96.0`. B is rejected
for deleting the failure channel. E is kept as a documented variation with the migration
asymmetry stated (D→E mechanical, A→D not). D wins on behavior preservation plus AC7.

**The runner-up is ranked honestly, and the decision argues against its own pick where the
count goes the other way.** `## Engines`' closing *Uncertainty* paragraph states that
"counted across public crate surfaces, the *dominant* shape is the runner-up, not the
pick", names the four surfaces (`object_store`, `jj`, `sqlx::fetch_one`, std's `fs`), and
records that this run verified each of the four. The pick then rests on a narrower and
explicitly-named class — APIs shaped as a port with a substitutable implementation — where
`rust-lang/crates.io` and `sqlx`'s *primitive* both split. That is selection by principle
and fit, not by popularity or repository agreement; the popularity count is reported and
then explicitly declined. The runner-up's winning conditions are stated with the reason
attached: system-issued identities (a content hash, a surrogate key, a handle the system
itself issued), where absence is corruption rather than a normal answer, and mutations
(`delete(id)`, `update(id, …)`), where `Ok(None)` names nothing useful. Rule 1's scoping
to *reads* is what makes those conditions coherent rather than a hedge, and the decision
says so.

**The R67 mapping reads R67's rows correctly.** I checked each row against the registry
cell in `docs/port/PARAMETERS.md:16` (the `error-taxonomy-exit-codes` value), not against
the decision's own quotation of it:

| Decision's mapping | Registry row, verbatim | Correct |
|---|---|---|
| `Io` → `RSLB101` / 1 | `` `RSLB101` I/O → 1 `` | yes |
| `Transport` → `RSLB102` / 1 | `` `RSLB102` transport (DNS/connect/timeout/TLS) → 1 `` | yes |
| `RemoteApi` → `RSLB103` / 1 | `` `RSLB103` remote-API failure → 1 `` | yes |
| `Unauthorized` → `RSLB402` / 4 | `` `RSLB402` credentials rejected → 4 `` | yes |
| `Conflict` → `RSLB501` / 5 | `` `RSLB501` conflict/precondition failed → 5 `` | yes |
| `Unavailable` → `RSLB101` / 1, **as a proposal** | `` `RSLB101` I/O → 1 `` exists; the routing choice is not R67's | yes, and correctly labelled |
| absence → `RSLB301` / 3, constructed by the use case | `` `RSLB301` resource not found → 3 `` | yes |

The `Unauthorized` row deserves one sentence, because R67 ships two 4-exit codes.
`RSLB401` is *credentials absent* and `RSLB402` is *credentials rejected*; a 401/403 from
an upstream that the adapter did call is a rejection, so `RSLB402` is the right member and
`RSLB401` correctly has no `PortError` variant — it is a pre-call condition the port never
observes. The `Unavailable` row is the only one where the decision is choosing rather than
reading, and it says so twice: the table cell reads "(proposal; see `## Engines`)" and the
unproven table carries the row as "**A proposal, not a finding**", with the argument
(`RSLB000` is R67's unexpected sentinel and feeds the crash-record sink; a poisoned fake is
a diagnosed, named adapter state), the observation that both exit `1` so nothing
user-visible turns on it, and the honest note that "the probe asserts the routing the
proposal describes, which is not evidence that the proposal is right". That last sentence
is the distinction most decisions lose; this one keeps it.

**"No `CONFLICT:` line" is right.** The prompt's rule is that a `CONFLICT:` line is owed
only when the recommendation *needs a consumed parameter to change*. Nothing here needs
R67 to change: every `PortError` variant lands on a published row, and the absence path
uses `RSLB301` → 3 as published. I confirmed the two negatives the argument rests on —
`RSLB302` appears **0** times in both `docs/port/PARAMETERS.md` and R67's `DECISION.md`, so
no per-resource row exists to collide with, and R67's catalogue is stated append-only over
a `#[non_exhaustive]` enum, which makes a future `RSLB302` a non-breaking addition rather
than a conflict deferred. The decision's recommendation *not* to take that row now — "a
second row is dead weight until a caller actually branches on resource kind" — is a
judgment, is labelled as one, and does not foreclose the owner's option.

**The eight disagreements are settled on grounds, and the grounds are the ones claimed.**
I anchored each to its twin's text:

| # | Twin's claim, located | Ground the decision settles on | Sound |
|---|---|---|---|
| 1 | openai `:354-357` MUST rule 5 requires `.map_err(ApplicationError::Source)?`; `:398` "Explicit `map_err(ApplicationError::Source)` teaches where the abstraction crossing occurs" | the probe: the `source()` chain `["transport failed", "connect timed out"]` survives `?` under `#[from]` (§2.2) | yes — the quote is verbatim at `:398`, and "requires" is fair for a `MUST` |
| 2 | openai `:301,364-365` asks for `find_project` / `get_project`-or-`require_project`, citing SeaORM's `one`/`require_one` (`:29`) | R01's published text: `error[E0046]: not all trait items implemented, missing: get` at R01 `DECISION.md:51,337` | yes — R01 names the method `get`, read there, not re-executed, and the decision says so |
| 3 | perplexity `:190,193` writes `owns R03.seam_contract` and `owns R03.domain_translation` | prompt `- owns:` empty; registry has 0 R03-owned rows; `research/CLAUDE.md` records `—` (§1.2) | yes — all three verified in the log and by me |
| 4 | perplexity `:94,213` routes `main` through `anyhow::Result<()>` | R67's accepted value: "`main` returns `ExitCode` and does not call `process::exit` on the error path"; "the library crate must not depend on `anyhow`" | yes — both clauses present verbatim in the registry cell |
| 5 | gemini `:105` "a predictable and stable `EXIT_NOT_FOUND` (e.g., code 2 or 3)" and "an `EXIT_NETWORK_FAILURE` (e.g., code 77)" | R67 fixes not-found → `3` and `RSLB102` → `1`; `77` is `sysexits.h`, which this template does not follow | yes — both quotes are verbatim at `:105` |
| 6 | perplexity `:199-201` raises a conditional `CONFLICT:` — "If R67 were to require a single 'NotFound' error code that lumps transport failure and resource absence together" | the condition is false: R67 publishes `RSLB301` and `RSLB102` separately (§1.5) | yes — the conditional framing is the twin's own wording, quoted accurately |
| 7 | gemini `:119-120` reports `crate.recent_downloads` 268,005,132 and `crate.downloads` 1,099,987,875 with `[cite: 6, 12]` and no retrieval date | this run's own `GET https://crates.io/api/v1/crates/thiserror` on 2026-09-17: 362,994,715 and 1,470,911,701 (§3.5) | yes — and the decision adds that nothing rests on either figure |
| 8 | opus `:843` "Both repositories are private and return HTTP 404 from the network" | §3.6: all three `smorinlabs` repos report `.private = false` and the three cited URLs return 200 unauthenticated | yes, with the right epistemic care — see below |

That is five settled against R67 or registry text (2–6), two by this run's own probe and
fetch (1, 7), and one correcting a statement *about* the evidence (8). The split matches
what the decision claims for itself.

**I spot-checked disagreement 8 independently** rather than trusting §3.6, using
`gh api repos/smorinlabs/<repo> --jq .private` for all three repositories (no token read,
printed or passed). All three return `false` on 2026-09-17 — the same result the script
recorded. The decision's handling is the correct one: it records the contradiction as a
**dated observation**, states that "Whether the visibility changed between Opus's retrieval
and this check is not determinable from either record", and refuses to convert it into a
finding that the engine misreported. It then draws the right consequence in both
directions — opus's py and ts readings are quoted as its readings at their pins and were
not re-read, and openai's citations, though fetchable, "point at `main` rather than at the
pins, so they are not interchangeable with the pinned readings either". That second half
matters: a reviewer could have used the 200s to promote openai's `main` citations over
opus's pinned ones, and the decision explains why that would be wrong.

**The probe's provenance is sufficient to reproduce it.** `review/evidence/toolchain.txt`
records `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc
2026-08-05)`, `Darwin 25.4.0 arm64`, macOS `26.4`, and the manifest settings
`edition = "2024"`, `rust-version = "1.96"`, `thiserror = "=2.0.20"`, plus the note that
the crate lives in a `mktemp -d` directory under `$TMPDIR` and is deleted on exit. The
exact-version pin `=2.0.20` is the reproducibility-critical detail, and `r03-probe.log` §1
confirms the generated lockfile pins `version = "2.0.20"`. The seven test names are
printed verbatim in the log, the `test result: ok. 7 passed; 0 failed; …` line with it, and
both compile-fail forms appear as raw compiler text — `error[E0308]: `?` operator has
incompatible types` with `expected `Project`, found `Option<Project>``, and
`error[E0277]: the `?` operator can only be used on `Result`s, not `Option`s, in a
function that returns `Result``. Raw cargo output for all three is snapshotted under
`review/evidence/snap/` (`probe-cargo-test.txt`, `probe-forgot-translation.txt`,
`probe-question-mark-on-option.txt`). Timings are elided from the log by design so reruns
diff clean, and the toolchain strings are kept out of the log for the same reason — both
stated. `raw/opus.md` reports **8** tests for its own probe; this run's is **7**, and
`## Engines` records opus's count as opus's rather than merging the two. That is the
correct handling of a differing engine artifact.

**Nothing was implemented, and the decision is explicit that nothing was.** Both the
preamble and `## Empirical check` state it: "No template module, port, adapter, service,
CLI, web handler or acceptance harness was written into this repository; the only code is
the throwaway crate". That is the right posture for a P02 research decision, and the
decision is not to be faulted for it — AC8, AC9 and AC10 are correctly consigned to P03
with the tests that would close them.

## Completeness

**The five `- assumes` lines are byte-identical, and the check that says so is
construction-proof.** `r03-contract.sh` extracts each value from `docs/port/PARAMETERS.md`
with an `awk` field-split on the registry row and diffs the generated block against the
decision's lines — the expected text is generated, never typed, so the assertion cannot
pass by a matching typo. The log records `PASS decision `- assumes` line count (expected 5,
got 5)`, `PASS decision `- assumes` block byte-identical to registry (expected same, got
same)` and `PASS decision `- owns ` line count (expected 0, got 0)`, and prints each row's
byte length as a keyed digest (`msrv-policy 142`, `rust-edition 29`, `target-os-matrix 56`,
`license 37`, `error-taxonomy-exit-codes 4161`) without repeating the value text. I
independently confirmed that `docs/port/PARAMETERS.md` carries exactly those five rows at
lines 7, 8, 9, 10 and 16.

**The `## Parameters` grammar and the H2 set are right.** Five `- assumes` lines, zero
`- owns` lines, no `CONFLICT:` line — and the absence of an owned row is *stated* rather
than left to inference, with three independent confirmations (empty prompt `- owns:`, zero
registry rows owned by R03, `—` in `research/CLAUDE.md`'s R03 row). The H2 set is
`## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, which is exactly the
set the two owner-accepted prerequisites carry (`research/topics/01-…/DECISION.md` adds
`## Supersedes` only because it is revision 3; `research/topics/67-…/DECISION.md` carries
the same four). The `re-verify:` line is present, sits inside `## Decision`, names seven
concrete triggers with what to re-check for each, and carries a date bound
(`2027-03-17, whichever comes first`).

**The three checks' counts are exactly what the logs show.** Counting `PASS` lines and
subtracting the one `ALL CHECKS PASSED` terminator: `r03-contract.log` 33 − 1 = **32**,
`r03-probe.log` 10 − 1 = **9**, `r03-practice.log` 22 − 1 = **21**. Those are the decision's
32 / 9 / 21. `FAIL` appears **0** times in all three. Each script returns its failed-assertion
count as its exit status and names `/usr/bin/grep` beside every count, which is what makes
the counts trustworthy in an agent shell where a typed `grep` may be `ugrep`.

**The archive-reproduction sentence is within what the logs show.** The decision claims
portability, not an executed archive run: "Each script resolves its own paths from `$0`, so
it runs unchanged from anywhere, including a clean `git archive HEAD` extraction; the
sections that need something outside such an extraction — a Rust toolchain, the network,
`gh` — print `SKIP <name>` with the reason instead of failing." I verified that each of
those three guards exists and is named. `r03-contract.sh:80-87` prints
`SKIPPED (partial extraction)` and exits `0` when `docs/port/PARAMETERS.md` or R67's
decision is absent; `r03-probe.sh:64-67` prints `SKIPPED (no toolchain)` when `cargo` or
`rustc` is off `PATH`, and `:391` prints `SKIPPED (offline dependency unavailable)`;
`r03-practice.sh` calls `skip` at `:97,117,125,165,180,198,201,214` for an uncached
snapshot, an unreachable crates.io, a missing `jq` and a missing `gh`. No `SKIP` line
appears in any log, which is the correct and consistent outcome for three scripts run
against the whole tree with a toolchain, the network and `gh` all present. The one
apparent discrepancy resolves cleanly: `r03-contract.sh` is one commit newer than its log
(`55c1dd1`, "make the R03 record check skip by name on a partial extraction"), but the
commit is nine added lines forming a guard that is inert when the files exist, so the
committed log remains the stdout the committed script produces — which is what that
commit's own message says.

**Every figure carries its endpoint and date.** The decision carries very few figures,
which is correct for a pattern item that selects no crate. `thiserror`'s two download
counts and `max_stable_version` are given with `GET https://crates.io/api/v1/crates/thiserror`
and "retrieved 2026-09-17" (§3.5); the log prints the same endpoint and points at
`snap/RETRIEVED.txt`, which records `thiserror.json 2026-09-17T06:16:50Z` alongside a
timestamp for each of the eight source snapshots. Every practice source is pinned to an
immutable ref — `rust-lang/crates.io` `3a31e6c8`, `sqlx` `b54008a3`,
`apache/arrow-rs-object-store` `279572ea`, `jj-vcs/jj` `e6dd2c0d`, `rust-lang/rust` tag
`1.96.0` — and snapshotted, so the quoted bytes cannot drift. Opus's star and open-issue
table is *not* carried into the decision at all, which is the right call: those figures
bear on nothing the decision concludes, and carrying them would have imported numbers this
run did not re-fetch. gemini's stale figures are the one exception, carried deliberately as
the subject of disagreement 7 and labelled "unsourced and stale".

**The unproven rows are honest, and each names what would prove it.** Eight rows: no real
HTTP adapter for rule 3 / AC8 (with the exact contract test that would close it, and the
note that the stub crate is R48's to choose); AC9's malformed-200 case, flagged as "**not**
prevented by the type system — `Ok(None)` is well-typed whatever produced it", which is the
decision arguing against its own pick's protective value; AC10 blocked on R69/R70; the
async port ("No async code was written or compiled in this run"); the `Unavailable` routing
proposal; the six-variant `PortError` list sized to the example domain; **Linux** ("Every
compile and test in this run ran on macOS 26.4 `arm64`", with the CI matrix named as proof);
and the **MSRV toolchain** ("The probe declared `rust-version = "1.96"` but ran on `rustc`
1.98.0; no 1.96 toolchain was installed", with the stability attributes read at tag `1.96.0`
offered as the weaker evidence they are, and a pinned `cargo check` leg named as what would
close it). The `target-os-matrix` gap is stated twice — once in the unproven table and once
under `## Parameters`, where it says plainly "`target-os-matrix` is **not** satisfied by
this run". A decision that claimed platform coverage from a single-OS probe would be the
classic overreach here, and this one does not make it.

**Gate 1 raises no licence finding, as the owner ruling requires.** I read
`docs/port/OWNER-REVIEW.md:47` — "### 2026-09-12 — no licence check for anything the
template uses (Q4, superseded and widened by Q7.B)". The decision records gate 1 as
`inapplicable — owner ruling 2026-09-12 (Q7.B)`, states that nothing is admitted or
excluded on a licence, and states that no surveyed project's licence is reported at all. It
records the `license` parameter in `## Parameters` without evaluating it as a gate, which is
the exact distinction the ruling draws. Gates 2, 3, 5 and 6 are `inapplicable` for want of a
candidate — stated, not omitted — with the `unsafe` posture recorded as **none**; gate 4 is
`inapplicable` as a crate-CI question and answered substantively. I raise no licence
finding.

## Findings

Three findings, **all non-blocking**. None is an unresolved finding in the acceptance
sense, and the recommendation does not move under any of them.

**JF-1 (non-blocking) — a quoting bug in `r03-contract.sh` drops one illustrative line and
puts three `grep` errors into a log the decision describes as pure stdout.** Section 6 of
`r03-contract.sh` contains:

```sh
$GREP -n -m1 -F 'the port error type (vocabulary R67's, absence shape R03's)' "$R01" | cut -c1-240
```

The single-quoted string ends at the apostrophe in `R67's`, so the shell splits the
remainder into extra arguments. `r03-contract.log` §6 therefore shows, between two `PASS`
lines:

```
grep: absence: No such file or directory
grep: shape: No such file or directory
grep: R03s): No such file or directory
```

Two consequences, both cosmetic. First, the intended echo — the R01 line reserving this
item's slot, the counterpart of the F012 row §7 does print — never reaches the log, so §6
asserts without displaying. Second, those three lines are on stderr, which sits against the
decision's sentence that "Each log in the table is the complete stdout of its script: each
script was re-run after its log was written and `bash <script> | diff - <log>` was empty":
a stdout-only pipe would not carry them, so that rerun must have merged stderr. **No
assertion is affected.** The three §6 claims use `count`, which quotes correctly and
redirects stderr, and all three passed on their own terms (`expected 2, got 2`). I verified
each independently against `research/topics/01-ports-and-adapters-seam/DECISION.md`:
`absence shape R03` appears twice (`:117`, `:401`), `` `PortError::Unavailable` `` twice,
and `Json<Option<Project>>` twice (`:53`, `:339`). So §1.6's substance holds exactly as
written. Disposition: recorded, no change required to accept this revision. A later
revision should fix the quoting — `"…R67'"'"'s…"` or a pattern without the apostrophe — and
either re-cut the log or drop the merge-stderr wording.

**JF-2 (non-blocking) — the `PLBP005`/`PLBP006` reading travels without the file and line
its source gives it.** The decision writes "py has two not-found codes (`PLBP005` project,
`PLBP006` workspace), so per-resource codes are a reasonable thing for the owner to want
later". `raw/opus.md:282-283` supplies that reading with its location —
`src/py_launch_blueprint/core/errors.py:56-57` at pin `b08bccfb` — and the decision keeps
the fact while dropping the pin. It is not *unlabelled*: the sentence sits inside
`### Principles and implementation`, which the unproven table's last row covers wholesale
("py's and ts's current behavior, as described under `### Principles and implementation`
… Taken from `raw/opus.md` at its recorded pins … and **not re-read**"). But it is the one
py fact in the decision whose own file and line did not travel with it, where HEX-12,
HEX-13, `ports.py:47,49`, `services/projects.py:56-63` and `py_api.py:188-195` all kept
theirs. Nothing rests on it — it supports only the observation that the owner might want a
per-resource code later, and the recommendation is explicitly *not* to add one now.
Disposition: recorded. A later revision should restore `core/errors.py:56-57` at pin
`b08bccfb` so the row reads like its neighbours.

**JF-3 (non-blocking) — one internal section cross-reference is incomplete.** The
ranked-runner-up paragraph writes: "It is the more common shape at Rust crate surfaces
(verified: `object_store::Error::NotFound`, `jj`'s `BackendError::ObjectNotFound`,
`sqlx::Error::RowNotFound`, and std's `io::ErrorKind::NotFound`; `## Empirical check` §3.1,
§3.4)." Three of the four are where the pointer says — std's `io::ErrorKind::NotFound` in
§3.1, `object_store` and `jj` in §3.4 — but `sqlx::Error::RowNotFound` is verified in
**§3.3** ("`Error::RowNotFound` exists"; `r03-practice.log` §3 records
`PASS sqlx also ships the folded variant`). All four claims are verified in this run; only
the pointer is short one section. Disposition: recorded, trivial. A later revision should
read "§3.1, §3.3, §3.4".

## Assessment

The recommendation follows from the evidence as written, and **it does not move under any
of JF-1, JF-2 or JF-3.** None of the three touches the shape at the seam, the layer that
performs the translation, the R67 mapping, the "no `CONFLICT:`" judgment, or any of the
eight engine disagreements. JF-1 is a shell-quoting defect in an evidence script whose
three affected assertions I re-verified by hand against R01's published decision; JF-2 is a
missing file-and-line on a fact that supports an option the decision declines to take;
JF-3 is an incomplete section pointer to claims that are all verified elsewhere in the same
check.

What carries the decision is that its load-bearing claims are each anchored to something in
this run rather than to an engine's assertion. The compile-time prohibition that
distinguishes D from A is not argued but observed, in two forms (`E0308` and `E0277`), with
raw cargo output snapshotted. The per-operation 404 rule is not asserted as good practice
but counted in production code — `Err(GitHubError::NotFound(_)) => Ok(None),` appearing
**exactly twice** in `rust-lang/crates.io` at `3a31e6c8`, which is what makes "per
operation, opt-in, never blanket" an observation rather than a preference. The
split-as-primitive relationship is read out of `sqlx`'s own source at `b54008a3`, where
`fetch_optional` is declared with no body and `fetch_one` is derived from it. And the
decision reports, twice and unprompted, that the ecosystem count runs against its own pick,
then argues the narrower class on fit and on a stated migration asymmetry rather than
burying the count.

The engine record is honest in both directions. The Codex leg's absence is attributed to a
quoted owner ruling with its date and its recorded consequence, with the stopped runner's
transcript in place; the deferral is not presented as completeness. Opus's own probe count
(8) is kept distinct from this run's (7). Opus's one incorrect statement — that both source
repositories are private and answer 404 — is corrected with a dated check I reproduced
myself, and is correctly confined to a statement *about* the evidence rather than allowed
to discredit the pinned readings it accompanied. The three disagreements that could have
been settled by preference (naming, owned parameters, `main`'s return type) are each
settled against published text I read at the source.

The five `- assumes` values are byte-identical to `docs/port/PARAMETERS.md` by a check that
generates its expectation from the registry, the `## Parameters` grammar and the H2 set
match the two owner-accepted prerequisites, the 32 / 9 / 21 counts are exactly what the
logs contain with zero failures, the archive-portability sentence is a code-level claim with
three real named `SKIP` guards behind it, every figure carries its endpoint and date, and
the eight unproven rows each name the check that would close them — including the three the
task singles out: no real HTTP adapter, no Linux leg, and no toolchain at the declared MSRV
floor. Gate 1 raises no licence finding, per the owner ruling of 2026-09-12.

The decision is admitted for the owner's acceptance ask on the two engines it has. The
Codex empirical audit remains owed under `W1-CODEX` before publication, and a later Codex
report is folded in by revision, as `## Engines` already states.
