# R60 — CLI parsing framework (bundle, Deep) — revision 7, 2026-09-15

Synthesized 2026-09-10 by a fresh context that produced none of this item's raw
reports, from three engine reports (five provider bodies) plus the verification
run recorded under `## Empirical check`. No template code exists and none was
written here.

Revised 2026-09-12 after the revision-1 draft (sha256
`d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c`) was
**rejected** on two findings — a non-conformant plural command noun and an
unpinned standard.

Revised again 2026-09-13 after the revision-2 draft (sha256
`18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c`) was
**rejected** on one finding: **its evidence scripts could not be rerun once the
revision was committed.** Nothing about the recommendation was challenged and
nothing about it moves. The evidence apparatus is rebuilt so that every input a
script reads is either committed inside this run directory or fetched from a
pinned remote source, and the rerun is demonstrated from a clean extraction of
the commit rather than asserted. This revision also records fitness gate 1 as
`inapplicable` under the owner's 2026-09-12 licence ruling. What changed, and
what is unchanged, is enumerated at the end of `## Engines`. No crate was
scaffolded and no command surface was written in any revision.

Revised again 2026-09-14, and **not on an audit finding**: the revision-3 draft
(sha256 `14f66259aad6063f9506410735e61e9a58a026fc24200cb048b9bbc71bbc2100`) was
**approved**, with `unresolved-findings: none`, by
`audit-codex-2026-09-05T183002Z-09f93cfc507c-r3` (`review/audit-codex.md`). This
revision implements an **owner ruling of 2026-09-14** on the one question
revision 3 left open. Asked whether the org CLI Design Standard binds this port
and whether OVERRIDE (OV-01)'s `SHOULD` waiver was granted, the owner answered
that the standard binds — the same pinned revision 1.4.14, blob `f9de0437`,
recorded under "THE STANDARD PIN" — and that **the waiver is refused**, choosing
this decision's own conforming **option (b)** instead. Three things follow.
**OV-01 is retired**, so R60 now declares **zero overrides**; the argument and
the options table are kept unedited as the record of how the choice was reached,
re-labelled rather than deleted, per the charter's `OVERRIDE (OV-nn)`
discipline. **F267 changes to option (b)**: `-V` and `--version` each print the
single conformant line and the extended build data moves behind a JSON version
object. **The template now conforms to the pinned standard with no waived
`SHOULD`**, where revision 3 had to record a waiver as outstanding.

Revision 3 predicted that adopting (b) would rewrite "only the acceptance
criteria AC2/AC3". **That prediction was too narrow and this revision says so
rather than absorbing it.** Delivering (b)'s JSON path is not reachable through
`ArgAction::Version`, which terminates parsing before any other flag is seen, so
the clap wiring for F267 moves as well: `Command::long_version` leaves the stack,
`Command::disable_version_flag(true)` and a template-declared global
`-V`/`--version` enter it, and `ErrorKind::DisplayVersion` stops being reachable,
which shortens the R67 error-routing paragraph by one kind. Essential behaviors 1
and 2, AC2, AC3, AC7 and the F267 row all move with it. The evidence for the
short-circuit is read in the published crate source and is `## Empirical check`
rows E11 and E12. Nothing else in the decision moves: the crate pins, the
architecture comparison, the fitness gates, the parameter lines, the four failure
mechanisms revision 3 diagnosed, the snapshot apparatus and the post-commit
`git archive` proof all stand exactly as the revision-3 audit approved them.

Revised again 2026-09-14 after the revision-4 draft (sha256
`12aaf65c88f6bbcde915723913257f78d2e2e483c6deac4ee808b41af122ef43`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r4` on one finding,
quoted here in full:

> **F1 — stale claim that makes E13 fail.** `review/DECISION.md:650-660` says
> the ruling is not in the repository and `:1330` carries that assertion as U8.
> The durable owner record contradicts it: `docs/port/OWNER-REVIEW.md:72-91`
> binds standard 1.4.14/blob `f9de0437`, records OV-01 as refused, selects
> option (b), and states zero overrides with no waived `SHOULD`. Accordingly the
> exact r4 standard-pin rerun failed C16h/C16i (`OV-01` count `3`, `2026-09-14`
> count `1`) rather than its recorded 115/0. Remove or revise U8 and its
> surrounding provenance assertions, then update the C16/E13 evidence and
> recorded result.

**The finding is correct, and this revision's scope is that finding and nothing
else.** Revision 4's provenance statements were true when they were written and
are false now: the controller wrote the ruling into
`docs/port/OWNER-REVIEW.md:72-91` after revision 4 was drafted, under the
heading `### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused`,
and the reasoning behind it is recorded at
`docs/planning/p02/owner-decisions.md:261-292` under
`## 9. Whether your CLI Design Standard binds this port -- ANSWERED 2026-09-14`.
So the ruling is now re-derivable from this repository alone, U8 is no longer an
unproven claim, and the two checks that asserted its *absence* — `C16h` and
`C16i` of `r60-standard-pin-r4.sh` — assert a falsehood and fail. Three things
follow. The provenance paragraph under OV-01 is **kept and corrected in place**,
the way revision 4 corrected revision 3's "only AC2/AC3" sentence rather than
deleting it. **U8 is re-labelled RESOLVED** in `## Engines`, naming where the
record is, rather than being deleted. And `C16h`/`C16i` are **inverted to assert
the record's presence** in a new script, `r60-standard-pin-r5.sh`;
`r60-standard-pin-r4.sh` is left byte-identical as the historical artifact the
revision-4 audit ran. **Nothing about the recommendation moves, and the owner's
ruling is not re-opened**: the standard still binds, OV-01 is still refused,
option (b) is still what F267 implements, and R60 still declares zero overrides.
What changed is that those facts now rest on a file in this repository instead
of on a task instruction.

Revised again 2026-09-15 after the revision-5 draft (sha256
`2a665e73f5a5d93794fe49520615e204be294d156f1d537b7bafe1421c042c06`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r5` on one finding,
quoted here in full:

> **F2 — the preservation script is not insulated from untracked audit files.**
> `r60-preservation-diff-r5.sh` claims to read committed files only. Its C1o
> instead searches `"$RUN_DIR"/review/audit-codex*.md`. The live run already
> contained the untracked `review/audit-codex.r4.md`, a byte-for-byte r4-audit
> copy beside the canonical `review/audit-codex.md`. Both files contain revision
> 4's decision hash. C1o therefore observed two matching reports, failed its
> required one-report assertion, and made the in-place r5 preservation rerun exit
> 1 with 133 checks and one failure. The committed log and decision claim exit 0
> with no failures.
>
> The clean archive passes because it contains only the tracked canonical report;
> that does not establish the claim that the script reads committed inputs only or
> that its in-place result reproduces. Make C1o select an explicit canonical,
> tracked report (or enumerate tracked paths), regenerate the preservation log,
> and correct the decision's in-place reproducibility claim.

**The finding is correct, and revision 6's scope is finding F2 and the evidence
apparatus it names, and nothing else.** No claim about `clap`, the standard, the
owner's ruling, the parameters or any acceptance criterion is touched, and **the
owner's ruling is not re-opened**. What was wrong is a property of one lookup.
`C1o` — and, reported beyond the brief, `C1i` carried the identical defect —
located an audit report by *searching* this run's `review/` directory for
whichever file named a given decision hash, then required exactly one match.
Reading a directory rather than naming a file produces two failures, and the
audit observed the first:

1. **The match count is not the script's to control.** Any extra copy of a
   report — tracked or untracked, placed by anyone working in this shared
   worktree — enters the set. That is F2 as observed: an untracked byte-for-byte
   copy of the revision-4 report sat beside the canonical one, so the in-place
   rerun **exited `1` with 133 checks and one failure** while the committed log
   recorded `133   FAILURES: 0`.
2. **The search result is printed, so the log moves when the directory moves.**
   When the revision-5 audit landed, the controller archived the revision-4
   report under its round name; the wildcard followed it, and **the printed
   basename changed from `audit-codex.md` to `audit-codex.r4.md`**. Rerun in
   place on 2026-09-15, the revision-5 script exits `0` with 133 checks and no
   failures — the count is right again — and its output still differs from the
   committed log on that one printed line. A passing count is not a reproducing
   log, and this second observation is recorded here because it shows the defect
   is the directory read itself, not the duplicate file.

The repair is `review/evidence/r60-preservation-diff-r6.sh`, which **names every
audit report it reads** and asserts the header lines that bind it: its
`decision-sha256:`, its `actor:` and its `verdict:`. No directory is searched, so
a file the script does not name cannot be read and cannot change what it prints,
and each report is pinned to bytes only that round's auditor wrote, so no check
can pass by accident. `C1r` forbids the wildcard from returning, with `C1r0` as
its positive control. `r60-preservation-diff-r5.sh` is left byte-identical as the
artifact the revision-5 audit ran. The cost of naming is stated rather than left
for an auditor to find, and stated at the precision the observed convention
supports rather than one step beyond it. The controller's observed sequence in
round 5 was: copy the outgoing report to its round name at the audit's start
(`review/audit-codex.r4.md`, 00:01), then overwrite `review/audit-codex.md` with
the incoming one at the audit's end (00:10). So `review/audit-codex.md` still
binds revision 5 for the whole of a round-6 audit, and `C1t`–`C1v` pass while
that audit runs. **The moment the round-6 report lands, `review/audit-codex.md`
binds revision 6's hash instead, and `C1t2`, `C1u2`, `C1u3` and `C1v` fail** —
not `C1t`, because the file is still present at that path. That is the same
expected historical-control failure as `C4h`'s title check, and the reason each
superseded script is kept rather than edited. `r60-standard-pin-r5.sh` and
`r60-snapshot-provenance-r4.sh` are unchanged, rerun in both modes for this
revision, and remain this decision's live evidence.

**The bolded prediction in the paragraph above is the sentence finding F3
falsified.** It is
kept here verbatim as the record of what revision 6 predicted, and corrected
immediately below, the way every superseded claim in this document is kept.

Revised again 2026-09-15 after the revision-6 draft (sha256
`89d888fb3a649ed7a99c895e4bc279a1afcc61438c3c41b6db8a966b6459db38`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r6` on one finding,
quoted here in full:

> **F3 — the post-landing assertion is incomplete.**
> `review/DECISION.md:157-159` and `r60-preservation-diff-r6.sh:339-344` say that
> only `C1t2`, `C1u2`, `C1u3`, and `C1v` fail when this report replaces the
> canonical round-5 report. The post-landing rerun instead exits `5`, with exactly
> five real failures: those four plus `C1u`. `C1u` requires `verdict: reject`;
> this report correctly carries `verdict: approve`, so it must fail too. Evidence:
> `review/evidence/audit-cli-parsing-framework-r6-post-landing.log`.

**The finding is correct, and revision 7's scope is finding F3 and the evidence
apparatus it names, and nothing else.** No claim about `clap`, the standard, the
owner's ruling, the parameters or any acceptance criterion is touched, and **the
owner's ruling is not re-opened**. What moves is one property of the preservation
script, and this time it is repaired as a class rather than as a count.

**The defect is structural, and this is the third round of it.** Round 5 rejected
a directory wildcard (F2); round 6 rejected an incomplete list of the checks that
would fail after the next report landed (F3). Both are the same mistake in two
spellings, and that makes this **the third round in which this decision's
preservation script has been rejected** for what it says about an audit report
that lands *after* the script is written. `review/audit-codex.md` is the path the
programme controller **overwrites** with each incoming round's report. Any check
whose subject is that path has its subject replaced while the script sits
committed beside the decision it supports, and no list of expected post-landing
failures can repair that, because the list is not knowable when it is written.

**Two measurements say so, and they disagree with each other.** Both are of the
same script, `r60-preservation-diff-r6.sh`, run after a round-6 report had
replaced the round-5 one at the canonical path:

1. **The auditor's.** Against a round-6 report carrying `verdict: approve` and
   `unresolved-findings: none`, it exited `5`, failing `C1t2`, `C1u`, `C1u2`,
   `C1u3` and `C1v` — the four revision 6 predicted, plus `C1u`, which requires
   `verdict: reject`. That is finding F3, and its log is
   `review/evidence/audit-cli-parsing-framework-r6-post-landing.log`.
2. **This revision's.** The report that actually landed at
   `review/audit-codex.md` is the rejection that produced this revision, so it
   carries `verdict: reject`. Rerun in place on 2026-09-15 against the
   revision-6 text it supports, the same script
   exited `4`: `C1u` passed, because the incoming verdict happened to match the
   outgoing one, while `C1t2`, `C1u2`, `C1u3` and `C1v` failed.

The check finding F3 names therefore passes or fails according to a verdict
written by someone else after the script was committed, which is the evidence
that **the failure set was never the script's to state**.

**The repair is `review/evidence/r60-preservation-diff-r7.sh`, which asserts only
archived audit reports, by explicit path, and reads the live
`review/audit-codex.md` nowhere.** The five reports it reads —
`review/audit-codex.r1.md`, `.r2.md`, `.r3.md`, `.r4.md` and `.r5.md` — are files
the controller writes once under a round name and never overwrites, so no
incoming report can reach any file the script names and nothing in it changes
meaning when the next report lands. `C1x` is the structural control that keeps it
so: no executable line of the script may contain the path
`/review/audit-codex.md`, with `C1x0` as its positive control requiring that
pattern to occur in the file at all, so a search that had stopped working could
not satisfy `C1x` by finding nothing. `r60-preservation-diff-r6.sh` is left
byte-identical as the artifact the revision-6 audit ran.

**What the new script deliberately does not assert, stated rather than left for
an auditor to find.** Finding F3 is carried by round 6's report, and
the round-6 report is asserted by no check in `r60-preservation-diff-r7.sh`.
When that script was written the report
existed at exactly one path, the live `review/audit-codex.md`, and
`review/audit-codex.r6.md` did not exist when that script was written: the
controller archives the outgoing report under its round name at the *next*
audit's start, which is after this revision is committed. Naming a file that does
not exist yet would fail the script's own rerun; naming the live path would be F3
again. So the round-6 report is quoted in this document and in the script's
header and asserted nowhere, and the sixth baseline is anchored by its own sha256
instead (`C1w`/`C1w2`), which pins bytes without reading any report. The gap is
one assertion wide and it is stated here rather than discovered: nothing in this
revision's evidence binds the round-6 report's bytes, and the auditor of this
revision holds that report itself.

## Decision

**Status.** This is a **proposal**, to be validated in the implementation phase
(P03) against the real template (owner ruling, 2026-09-10). Everything below
rests on registry and GitHub queries, reads of the published crate sources at
their exact versions, reads of the org CLI Design Standard **at the pinned
revision recorded under "THE STANDARD PIN" below (version 1.4.14, blob
`f9de0437`)**, reads of the two source repositories through their pins, and one
MSRV-aware dependency resolution — not on a working command-line interface,
which does not exist yet.
P03 builds the template and its CI proves the recommendation. Where a
recommendation here does not survive contact with the built template, the
correction is made **against this recorded research** — its principles, its
compared alternatives and its verified mechanisms — rather than by researching
the item again from scratch. The owner has ruled on exactly one question this
decision put — OV-01's waiver request, **refused 2026-09-14**, with option (b)
selected in its place — but has not reviewed the decision as a whole; no
acceptance of the decision is claimed or implied.

Adopt **`clap` with its `derive` API** as the single declaration of the argv
grammar, and take every one of this bundle's six derived surfaces from that one
declaration rather than from application code. The named stack, at the versions
that resolved and audited clean on 2026-09-10:

| Slot | Selection | Where it goes |
|---|---|---|
| Argument parser | `clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }` | CLI binary crate only |
| Shell completions | `clap_complete = "4.6.9"` (default features; `aot` generation) | CLI binary crate only |
| Build metadata for extended `--version` | a dependency-free `build.rs` reading Cargo's `TARGET` and running `$RUSTC -vV` | CLI binary crate only |
| Did-you-mean matcher | `strsim`, **transitive** through clap's default `suggestions` feature — never a direct dependency | resolved at `0.11.1` on 2026-09-10 |

The library crate and the web crate depend on none of these.

The six surfaces this bundle decides, and the mechanism chosen for each:

| Ledger row | Surface | Mechanism |
|---|---|---|
| F264 | parsing framework | `clap` 4.6.6, `derive` API; a `Cli::command()` factory kept for completion generation and parser tests |
| F265 | command surface shape | noun-verb subcommand groups as nested `Subcommand` enums, each noun **singular in its canonical documented form** (R1.3 `MUST`, `:133`); **no default business command** |
| F267 | extended `--version` | `Command::version` alone — `-V` and `--version` each print the single conformant line `<tool> <semver>`; the target triple and the rustc version move behind `<tool> --version <format-flag> json`, which R4.6 permits (`:276-277`). **No `Command::long_version`.** Delivering the JSON path costs `Command::disable_version_flag(true)` plus a template-declared global `-V`/`--version` — **see "F267 AS DECIDED" below**, and **RETIRED OVERRIDE (OV-01)** for the history |
| F268 | completion generation | a regular `completion <shell>` subcommand calling `clap_complete::aot::generate` against a fresh `Cli::command()` |
| F269 | env-var binding | a **curated** per-option `#[arg(env = "<TOOL>_<NAME>")]`; **no blanket prefix** — py's `auto_envvar_prefix` is not ported |
| F270 | stackable global options | one `#[derive(Args)] struct GlobalArgs`, `#[command(flatten)]`-ed at the root, `global = true` on each field |
| F272 | did-you-mean matching | clap's default `suggestions` feature (`strsim::jaro`, confidence `> 0.7`); no hand-rolled matcher, no direct `strsim`, `infer_subcommands` left off |

F266 (`-V`/`--version` exists) and F271 (a suggestion appears) are inherited
`COMMON → REUSE` rows adjudicated `retained` in
`docs/port/BASELINE-REVIEW.md:114` and `:115` (read 2026-09-10). This item
decides only which crate provides them and, for F272, the matching mechanism.
Both are natively available in the recommended stack: verified in the crate
source, cited below.

**Integration point with the already-published R67.** R67 requires `main` to
return `ExitCode`, a usage/parse failure to be `RSLB201` → exit `2`, a single
JSON envelope on stderr, and stdout byte-empty on the error path
(`research/topics/67-error-and-exit-code-contract/DECISION.md`, read
2026-09-10). `Cli::parse()` does not compose with that: it prints clap's own
message and terminates the process itself. So the template calls
**`Cli::try_parse()`** and routes the `clap::Error` by `kind()`. Clap's own rule
sends exactly two kinds to stdout at exit `0` — `ErrorKind::DisplayHelp` and
`ErrorKind::DisplayVersion` — because that is the exact match arm clap uses:
`stream()` is `ErrorKind::DisplayHelp | ErrorKind::DisplayVersion =>
Stream::Stdout, _ => Stream::Stderr`, and `exit_code()` returns `USAGE_CODE`
for every stderr kind and `SUCCESS_CODE` otherwise, those constants being `2`
and `0` (`clap_builder-4.6.6/src/error/mod.rs:222-237`,
`clap_builder-4.6.6/src/util/mod.rs:26,32`, read 2026-09-10). **In this
template only the first of those two is reachable.** F267's decided mechanism
sets `Command::disable_version_flag(true)` and declares its own `-V`/`--version`
as a plain boolean, so no argument carries `ArgAction::Version` and clap never
constructs a `DisplayVersion` error; the version path returns through `Ok` and
the template prints it (see "F267 AS DECIDED" below). The routing rule the
template implements is therefore: `ErrorKind::DisplayHelp` is successful output
on stdout at exit `0`; every other kind is `RSLB201` → `2`. Handling
`DisplayVersion` as well is harmless and costs one match arm, but it is dead
code under this design, and P03 should either omit it or assert it unreachable
rather than leave a reader to infer that `--version` still travels the error
path. Note the one kind
that reads as if it belonged in the exit-`0` list and does not:
`DisplayHelpOnMissingArgumentOrSubcommand` (`error/kind.rs:300`) falls in the
`_` arm, so clap sends it to stderr at `2`. Whether the template overrides that
is not decided here — it depends on `Command::arg_required_else_help`, which
this item does not set. clap's numbering therefore agrees with R67 at both
ends, but agreement of values is not composition: the envelope and the
`ExitCode` return are the template's, and P03 must build them. Rendering clap's usage text *inside* R67's
JSON envelope is not decided here and is listed under `## Engines` as work P03
must resolve.

### Principles and implementation

**The shared requirement.** Both source implementations declare the command
surface once, as data, and generate every user-visible artifact from that one
declaration — help text, the version flag, the completion script, the
environment fallback and the unknown-command suggestion. py does this with
`click` (py `src/py_launch_blueprint/cli/main.py:29` — `import click`); ts does
it with Commander (ts `src/router.ts:13` — `import { Command, CommanderError }
from 'commander';`). Both lines were read through the pins on 2026-09-10 (`git
-C ~/c/py-launch-blueprint show b08bccfb…:<path>`, `git -C
~/c/ts-launch-blueprint show cb1cbcb2…:<path>`; full output in the evidence
log, section Y/Z). The principle is not "use a parser library". It is
**single-source interface declaration**: the argv grammar has exactly one
definition, and no derived artifact is maintained by hand alongside it. The
residual drift risk is confined to an artifact that is *committed* rather than
emitted at run time — the completion scripts, if the template ever checks them
in — which is what acceptance criterion AC4 is for.

**Source and agreement level.** Five levels are in play, and conflating them
produces the wrong answer. Where a row's source is the org CLI Design Standard,
the citation is `/Users/stevemorin/c/cli-standards/cli-design-standard.md:<line>`,
read 2026-09-10 and pinned as follows.

**THE STANDARD PIN — every `R<n>.<m>` rule and every bare `:<line>` in this
decision resolves against exactly this revision.** A decision that cites a
moving document cannot be re-verified, so the applied revision is fixed by four
identifiers — the declared document version, the commit, the blob object id and
the content sha256 — in the repository named alongside them. Each is
independently checkable, and the content hash is the authoritative one: a
document could in principle be edited without its version being bumped, and the
hash would still catch it.

| Identifier | Value |
|---|---|
| Document version | **1.4.14**, `Status: Active — canonical`, `Last updated 2026-06-28` (declared in the document's own header table, `:1-12`) |
| Repository | `https://github.com/smorinlabs/cli-standards`, path `cli-design-standard.md` |
| Commit | `fb30a591c267a7ec1130ba4cda679eaee494b9d7` (`docs: resolve PR #1 review findings (v1.4.14)`, 2026-06-28) — the most recent commit to touch the file, **confirmed against the published history rather than against a local clone**: `GET https://api.github.com/repos/smorinlabs/cli-standards/commits?path=cli-design-standard.md&per_page=1` returns this commit as the newest, checked 2026-09-12 against `origin/main` after `git fetch` and re-checked 2026-09-13 through that endpoint (`## Empirical check` row E10) |
| Blob object id | `f9de0437baece3383e73ca2c5f48b7ab399b51c7` |
| Content sha256 | `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f` |

**How a future reader resolves it, without a clone and without this machine.**
The pinned text is committed in this run directory as
`review/evidence/snapshots/cli-design-standard-1.4.14.md`, and its sha256 is
`9fb05d3d…` — the same hash the pinned blob has. So the primary recipe is: hash
that file and confirm the value. Two independent recipes re-derive the same
bytes from the published source: `curl -sSL
https://raw.githubusercontent.com/smorinlabs/cli-standards/fb30a591c267a7ec1130ba4cda679eaee494b9d7/cli-design-standard.md`
(a content-addressed URL — the commit id is in the path, so the bytes cannot
move under it), or, given any clone of the repository, `git cat-file blob
f9de0437baece3383e73ca2c5f48b7ab399b51c7`. All three were executed on
2026-09-13 and agreed (`## Empirical check` rows E1 and E10). Every `:<line>`
citation below is a **line number in that text**, not in whatever the working
tree holds later; the pinned text is 773 lines, which is itself asserted so that
an out-of-range citation cannot pass silently. The local working-tree file read
on 2026-09-10 was verified byte-identical to the pinned blob (same sha256), so
the reads this decision rests on and the pinned text are the same bytes. Version,
sha256 and each cited line were checked mechanically; see `## Empirical check`
rows E1–E5 and E10.

**R67 did not pin this document in its decision, and that is why the pin is
stated here in full.** The distinction matters, so state both halves exactly.

- **R67's decision body carries no pin.** It cites the standard by absolute
  path, line and retrieval date only —
  `/Users/stevemorin/c/cli-standards/cli-design-standard.md:351` with the org
  decision row at `:70`, read 2026-09-09
  (`research/topics/67-error-and-exit-code-contract/DECISION.md:78`, and once
  more in its evidence table at `:464`; those two lines are its only citations
  of the file). Neither carries a version, commit, blob id or content hash, and
  the string `1.4.14` does not appear in that document at all.
- **R67's audit trail does name the version.** Its revision-4 audit log records
  "Standard read: `/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
  version 1.4.14"
  (`research/topics/67-error-and-exit-code-contract/evidence/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract-r4.log:6`).
  That is an auditor's record rather than a pin in the deliverable — it fixes
  no commit or hash, and a reader of R67 alone would not find it — but it is
  independent attestation that **R67 and R60 applied the same revision, 1.4.14**.

Both halves were checked mechanically, including the negative one, which is
asserted as a count of zero rather than as absent output (`## Empirical check`
row E6). So there is no R67 *pin form* to be consistent with: this decision
keeps R67's citation style — absolute path, `:<line>`, retrieval date — and adds
the version, commit, blob id and content hash that R67's body omits. The two are
compatible rather than divergent, and now demonstrably about the same text: R67's
2026-09-09 read, its auditor's 1.4.14, and R60's 2026-09-10 read all fall after
the 2026-06-28 commit that is still the file's latest. Should R67 be revised,
adopting this pin form is the cheaper direction of alignment.

| # | Principle | Agreement level | Must agree across py/ts/rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | The argv grammar has one declaration; help, version and completions are generated from it | **capability** (ledger F264 `DIVERGENT`) | that generation is derived, never hand-maintained in parallel | which crate generates; derive vs builder front-end |
| P2 | A command path reads noun then verb, and the noun is singular | **standard, one value for all three repos** — R1.1 `(MUST, Standard profile)` (`:124`), org-locked (`:63` row 1); R1.3 `(MUST)` noun number (`:133`), org-locked (`:67` row 5) | the ordering itself, **and that the canonical documented noun is singular** | nesting depth (R1.2 `SHOULD` ≤ 3, `:129`) and the module layout; whether a hidden plural alias is offered at all (R1.3's `MAY`) |
| P3 | `-V`/`--version` exists and reports the tool's version | **capability + standard** — ledger F266 `COMMON → REUSE`; R4.1 `(MUST)` required global core (`:237`), R4.6 `(SHOULD)` output shape (`:275`) | that the flag exists, that `-v` is verbose, not version (`:65` row 3, org-locked), and — after the owner's 2026-09-14 ruling — that the default output of both spellings is R4.6's single line | whether a machine-readable version object is offered at all (R4.6's `MAY`, `:276`), which spelling reaches it (R66), and where the extra data comes from (R22) |
| P4 | A setting exposed in more than one place uses one deterministic name, and env exposure is curated | **standard** — R3.8 `(MUST)` (`:220`), R5.4 `(MUST)` (`:321`), org-locked (`:69` row 7) | `--some-flag` ↔ `TOOL_SOME_FLAG`, and that the env surface is a curated subset | which options are in the curated subset |
| P5 | Global options work wherever the user puts them | **capability**, floor fixed by R4.5 `(SHOULD)`: "Global flags **MUST** be accepted before the subcommand and **SHOULD** also be accepted after it" (`:270-271`) | before-the-verb acceptance | whether after-the-verb acceptance is free or costs per-command declarations |
| P6 | An unknown command produces a suggestion, not a bare failure | **capability** (ledger F271 `COMMON → REUSE`) | that a suggestion appears | the string metric and threshold (F272) |
| P7 | The tool can print completion scripts for the user's shell | **capability** — R9.1 `(SHOULD)` "at least bash, zsh, and fish" (`:483`) | that a `completion <shell>` surface exists for those three shells | static script generation vs runtime completion |

**The standard binds this item, on the same footing as R67.** R60's own prompt
does not name the org CLI Design Standard, and the Opus raw report therefore
treats its applicability as an open owner question. It is not open. The
already-published R67 rests on the same document, adjudicating its R6.1 as a
`(MUST)` that is `org-locked` and quoting its exit-code table verbatim
(`research/topics/67-error-and-exit-code-contract/DECISION.md:76-82`, read
2026-09-10). This decision follows that treatment: every rule cited above is
cited by file and line with its retrieval date **against the pinned revision
above**, and a `MUST` marked org-locked in the Part II Decision Log table
(header `:61`; row *N* at line 62 + *N*, so row 1 is `:63`, row 5 `:67`, row 7
`:69` and row 8 — R67's exit-code row — `:70`) is binding, not advisory. The ts port
already reconciled onto the same document in code — its router carries the
comment "Usage errors must exit 2 (cli-standards R6.1)" (ts `src/router.ts:117`,
read through the pin 2026-09-10).

Three consequences follow, and they are different in kind:

- **The template is in the Standard profile, so R1.1 is a `MUST` here.** The
  standard defines two profiles (`:50-53`); the verb-first Small-CLI profile
  requires *all three* of its entry criteria to hold (`:578-581`), the first
  being a small fixed command set acting on "a **single implicit resource** or
  no resource at all". This template ships two resource groups (`project`,
  `config`) and exists to be extended, so criteria 1 and 2 both fail. The
  standard's own counter-example is decisive: "a platform tool managing
  `projects`, `deploys`, `tokens`, and `users` — that **MUST** use noun-verb"
  (`:586`). That sentence is **quoted verbatim from the standard, and its plural
  spellings are the standard's own illustrative wording in an Appendix A
  counter-example, not this template's grammar** — the template's nouns are
  singular under R1.3, the next bullet. F265's ordering is therefore settled by
  the standard, not by a preference between the two ports. The ecosystem
  evidence agrees rather than conflicts on ordering, so no override is filed.
- **R1.3 is a `MUST` that fixes the noun's *number*, and the canonical
  documented form is singular.** R1.3 (`:133-137`) states it in three parts:
  "Resource nouns **MUST** be **singular** in their canonical form. The plural
  form **MAY** be accepted as an undocumented alias but **MUST NOT** appear in
  help or docs. The verb already carries cardinality, so `list` returning many
  is not a reason to pluralize." Its non-conformant example is precisely a
  documented plural — "❌ documenting `acme widgets list` as the primary form"
  — and the rule is org-locked (Decision Log row 5, `:67`: "Singular canonical;
  plural accepted as undocumented alias"). So the canonical, documented,
  help-visible noun in this template is **`project`**, giving `<tool> project
  list`; `<tool> projects list` **MAY** be wired as an explicit hidden alias
  (permitted by R1.3's `MAY` and by R1.6's alias allowance, `:146-149`) and, if
  it is, **MUST NOT** appear in `--help` or in any documentation. Three points
  on the mechanism, because each is easy to get wrong:

  1. **clap already distinguishes the two alias kinds, and only one of them
     conforms.** `Command::alias` documents itself as "Aliases defined with this
     method are *hidden* from the help message", pointing at
     `Command::visible_alias` for the other behavior, which in turn is "*visible*
     from the help message and displayed as if it were just another regular
     subcommand" (`clap_builder-4.6.6/src/builder/command.rs:2664-2666` and
     `:2865-2868`; the methods themselves at `:2691` and `:2893`, read
     2026-09-12). So `#[command(alias = "projects")]` is the conformant form,
     and `visible_alias` would *violate* R1.3 by putting the plural in help.
     R1.3's "undocumented alias" is therefore a behavior clap supplies directly,
     not something the template has to build.

     That the *derive* spelling reaches that builder method is verified rather
     than assumed, because this is the mechanism the whole R1.3 repair rests on.
     `alias` is not one of `clap_derive`'s special attribute names — the
     `MagicAttrName` table in `clap_derive-4.6.4/src/attr.rs` contains no
     `Alias` variant and does not mention `alias` at all — so it falls to the
     generic branch, which pushes it verbatim as
     `self.methods.push(Method::new(name, arg))` (`src/item.rs:337-345`), and a
     `Method` renders as `quote!( .#name(#args) )` (`:1281-1289`). The generated
     code is therefore literally `.alias("projects")`, calling
     `Command::alias` — the hidden one. Read 2026-09-12 in the published
     `clap_derive-4.6.4` tarball, whose sha256 matches crates.io's recorded
     checksum (`## Empirical check` row E8).
  2. **An alias is an explicit declaration, so it does not reopen R3.10.** The
     plural is reachable only because it was named; nothing is inferred. This is
     the opposite of `infer_subcommands`, which stays off (essential behavior 6).
  3. **The alias is optional.** The conformant minimum is the singular form
     alone, and P03 may ship that and nothing else.

  **This departs from both source ports, and deliberately.** py declares a
  help-visible plural group — `@click.group(name="projects", cls=SuggestingGroup)`
  (py `src/py_launch_blueprint/cli/commands/projects.py:37`) registered as
  `COMMAND_GROUPS = [projects_group, config_group]`
  (py `cli/commands/__init__.py`) — and ts declares
  `.command('projects', { isDefault: true })` (ts `src/commands/projects.ts:70`),
  which `src/router.ts:234` then looks up by that exact plural name. All three
  lines were read through their pins on 2026-09-12 (`## Empirical check` row E7). **No override is filed for this departure**, on the same footing
  as F269 below: R1.3 is a non-waivable `MUST`, the standard's conformance
  clause admits waivers only for `SHOULD`-level rules (`:50`), and a `MUST`
  leaves nothing to trade off. Recording conformance to an org-locked `MUST` as
  an override would misrepresent a settled constraint as a choice this item
  made. The ports' plural is evidence of prior practice, not a competing option.
- **R4.6 is a `SHOULD` that this design satisfies.** Revision 3 deviated from it
  and filed OVERRIDE (OV-01) for the deviation. The owner **refused** that waiver
  on 2026-09-14 and selected the conforming **option (b)**, so the deviation is
  withdrawn: `-V` and `--version` both print R4.6's single line, and the JSON
  object R4.6 itself specifies carries the extended data. **This decision
  therefore records no override at all, and no `SHOULD` of the pinned standard
  is waived.** OV-01 is kept below, re-labelled as retired, because the charter
  asks that the argument and the options be preserved as the record of how the
  choice was reached — not because any deviation survives. The conformance
  record for this item now reads: **every rule this decision cites is satisfied
  as written, with no waiver on file** — the `MUST`s R1.1, R1.3, R3.8, R3.10,
  R4.1, R5.4 and R9.3 as constraints the design meets, and the `SHOULD`s R1.2,
  R4.5, R4.6 and R9.1 met on their own terms. R1.6's `MAY`/`MUST NOT` pair is
  engaged only if P03 declares the optional hidden alias (AC10).

**What the standard excludes, and why the exclusion is not a clap limitation.**
py binds *every* option to an env var through one prefix (py
`cli/main.py:60-66` — `"auto_envvar_prefix": APP_NAME.upper(),`, whose own
comment calls the prefix "the catch-all for any others"; read through the pin
2026-09-10). R5.4 `(MUST)` says the opposite: "Only a **curated subset** of
settings **SHOULD** read from the environment … and the tool **MUST NOT**
auto-expose every flag as an env var" (`:321-323`). py's own code already hedges
toward the curated form — four of its global options carry explicit `envvar=`
names (`PLBP_OUTPUT`, `PLBP_LOG_LEVEL`, `PLBP_LOG_FILE`, `PLBP_CONFIG`, py
`cli/options.py:62,89,98,107`, read through the pin 2026-09-10). So F269 is
decided by the standard: keep the deterministic `--some-flag` ↔
`<TOOL>_SOME_FLAG` naming that R3.8 `(MUST)` requires, drop the catch-all.

**`<TOOL>`/`<tool>` is a placeholder throughout this decision, and deliberately
so.** py's tool is named `plbp` and its variables are `PLBP_*`; the Rust
template's binary name is **not this item's to set**. It follows from R49
(`build-tool-output-shape`), whose registry value is still `—`
(`docs/port/PARAMETERS.md`, read 2026-09-10), and R9.3 `(MUST)` makes env-var
names part of the tool's public contract — "command names, flag names, exit
codes, env-var names, and machine-readable output shape" (`:491-493`, read
2026-09-10) — so writing
`PLBP_` here would propagate py's name into a Rust interface this item has no
authority over. Every `<TOOL>_` and `<tool>` below resolves to R49's binary name
uppercased and as-is respectively; the *rule* this item fixes is the
deterministic transform, not the string. Where `PLBP_` appears without a
placeholder it is quoting py's own source or a raw report, and says so.

State the reason precisely, because a wrong reason here would propagate. clap
**can** do blanket binding: `Command::mut_args` takes an `FnMut(Arg) -> Arg`
over every argument (`clap_builder-4.6.6/src/builder/command.rs:296-302`, read
2026-09-10), so a builder post-pass that derives `<TOOL>_<UPPER_SNAKE>` from
each long name — which is what the Doxa OpenAI body proposes — is mechanically
constructible. What clap does not ship is a *declarative* prefix switch: a grep
of `clap_builder 4.6.6` and `clap_derive 4.6.4` for `env_prefix`, `auto_env` and
`envvar_prefix` returns nothing, and the only env API is per-argument
`Arg::env` / `Arg::env_os` (`arg.rs:2205,2221`). The blanket design is therefore
excluded **because R5.4 forbids it**, not because clap cannot express it.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Representative | What it gives | What it costs for this template |
|---|---|---|---|---|
| A | Declarative single-source parser, derive front-end | `clap` + `clap_derive` | subcommand routing, help, `-h`/`-V`, completions, env fallback and suggestions from one type definition | the largest compile-time and binary cost among the candidates surveyed (figures and their limits below) |
| B | Same crate, builder front-end | `clap` builder | commands composed at runtime (plugins, config-driven flags) | more code for a fixed command set; no compile-time typing of the parse result |
| C | Minimal lexer, everything else hand-written | `lexopt`, `pico-args`, `clap_lex` | smallest binary, fastest builds, total control over argv semantics | the template must hand-write help, version, man page, completion generators and suggestion matching |
| D | Statically-typed combinator parser | `bpaf` | compile-time-checked parsers; smaller release overhead than clap in the upstream benchmark (qualification 3 below) | combinator style; its completion support was not verified here (see `## Engines`) |
| E | Small derive parser aimed at binary size | `argh`, `xflags` | tiny overhead | `argh` is BSD-3-Clause and declares no `rust-version`; `xflags`'s newest release is a pre-release |

Architecture C is excluded **on fit, not on popularity**, and the strongest
argument for it is worth stating in full because it is real. ripgrep left clap
for `lexopt`, and its maintainer wrote down why (PR #2626, merged 2023-11-21;
quoted in the Opus raw report from `GET
https://api.github.com/repos/BurntSushi/ripgrep/pulls/2626`, retrieved
2026-09-10): "I perceived that Clap solves a more general problem than what I
actually need solved … **No multi-value flags. No sub-commands.**" The same PR
body enumerates the bill: "I had to write my own shell completion generator. I
had to write my own `-h/--help` output generator. I also had to write my own man
page generator." `rs-launch-blueprint` is the inverse of ripgrep's case on the
axis that decided it: it *is* a subcommand tool (F265, and R1.1 makes that a
`MUST`), it *does* need a `completion` command (F268, R9.1), and as a template
it must make adding a noun cheap for every downstream user. ripgrep's
`Cargo.toml:63` still reads `lexopt = "0.3.0"` and names no clap (verified
2026-09-10, evidence log section AA) — the counterexample is genuine, and it
does not transfer.

**Fitness gates, answered per candidate before popularity was weighed.** Every
figure below is from the run recorded in `## Empirical check`, retrieved
2026-09-10.

| Candidate | 1. license — **gate inapplicable**; the value is recorded as a fact, see below | 2. MSRV (floor 1.96) | 3. advisory / `unsafe` | 4. OS matrix | 5. default features | 6. size & build cost | Gate result |
|---|---|---|---|---|---|---|---|
| `clap 4.6.6` | `MIT OR Apache-2.0` | declares `1.85` — 11 minors of headroom | no RustSec page; `cargo audit` clean on the resolved tree | see qualification 2 | `std,color,help,usage,error-context,suggestions` | largest of the surveyed field in the upstream benchmark (qualification 3) | **pass** |
| `clap_complete 4.6.9` | `MIT OR Apache-2.0` | declares `1.85` | no RustSec page | see qualification 2 | `default = []`; requires `clap >= 4.5.20` | not separately measured in the upstream benchmark; adds five shell writers | **pass** |
| `strsim` — `0.11.1` at the 2026-09-10 resolution, and transitive, so the version floats | `MIT` | declares `1.56` | no RustSec page | see qualification 2 | n/a — pulled by clap's `suggestions` | not separately measured | **pass** |
| `vergen 10.0.3` | `MIT OR Apache-2.0` | declares **`1.96.0` — exactly the floor, zero headroom** | no RustSec page | not assessed | `cargo`, `rustc` features needed | build-time only | **pass today, at risk** — see below |
| `built 0.8.1` | `MIT` | declares `1.87` | no RustSec page | not assessed | build-time only | build-time only | **pass** (runner-up) |
| `shadow-rs 2.0.0` | `MIT AND Apache-2.0` | **declares none** | no RustSec page | not assessed | build-time only | build-time only | **excluded by gate 2** (no MSRV evidence) |
| `bpaf 0.9.27` | `MIT OR Apache-2.0` | declares `1.68` | no RustSec page | not assessed | not assessed | smaller than clap in the upstream benchmark (qualification 3) | passes gates; loses on fit (D above) |
| `argh 0.1.19` | **`BSD-3-Clause`** | **declares none** | no RustSec page | not assessed | not assessed | 38 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; also rejects invalid-UTF-8 argv per that same benchmark's own column |
| `lexopt 0.3.2` | `MIT` | **declares none** | no RustSec page | not assessed | not assessed | 37 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; also architecture C |
| `pico-args 0.5.0` | `MIT` | **declares none** | no RustSec page | not assessed | not assessed | 24 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; newest release 2022-06-04, repo `pushed_at` 2023-10-19 |

**Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility
is not evaluated for any dependency or tool`.** The owner ruled that this project
performs no licence check on any tool or library it uses, and extended that
knowingly to crates compiled into the shipped artifact; the repository's own
declared expression `MIT OR Apache-2.0` and its per-file headers are unaffected,
because those are this repository's own source. The gate row is stated rather
than deleted because this item's binding prompt still lists it and directs that
an inapplicable metric carry its reason. **The recommendation does not move, and
no exclusion in the table above ever rested on this gate**: all four exclusions
(`shadow-rs`, `argh`, `lexopt`, `pico-args`) are gate-2 exclusions for declaring
no `rust-version`, and `argh`'s `BSD-3-Clause` — the only value in the column
that differs in kind from the rest — excluded nothing before the ruling and
excludes nothing after it. The licence expressions recorded in that column, in
`## Empirical check` §01 and §08, and in the evidence log's section W are
retained as the values the registry endpoint returned. They are facts about the
crates, evaluated against no gate.

Four qualifications on that table, each of which limits exactly one column:

1. **Gate 3, advisories.** "No RustSec page" means `GET
   https://rustsec.org/packages/<name>.html` returned HTTP 404 for all eight
   crates queried. That reading was validated against two controls that do carry
   advisories — `anyhow` (HTTP 200, `RUSTSEC-2026-0190`, the advisory R67 cites)
   and `atty` (HTTP 200, two IDs) — so a 404 here is absence of an advisory page,
   not a failed request. `cargo audit` (advisory DB of 1,243 advisories, fetched
   2026-09-10) scanned the resolved 29-crate tree and exited `0`. **The `unsafe`
   posture of these crates was not assessed in this run** and is carried to
   `## Engines` as unproven.
2. **Gate 4, the OS matrix.** No CI configuration was read in this run. The
   resolution and the crate reads were performed on macOS 26.4 `aarch64` only.
   That `clap`, `clap_complete` and `strsim` build and are tested on
   `ubuntu-latest` and `macos-latest` is **not established by this decision**; it
   is carried to `## Engines` as unproven with what would prove it. What *is*
   established here is that the recommended pins resolve at the declared MSRV
   floor on one host.
3. **Gate 6, size and build cost.** The only figures available are the upstream
   `rosetta-rs/argparse-rosetta-rs` benchmark's published results, quoted in the
   Opus raw report from that project's README (retrieved 2026-09-10). They were
   measured **by that project, on its own stated system — "Linux 6.17.9-76061709-generic
   (x86_64), rustc 1.94.0 (4a4ef493e 2026-03-02) w/ `-j 8`" — with clap at
   v4.5.60, which is not the 4.6.6 recommended here, and on neither CI runner.**
   No benchmark was run by the Opus report and none was run by this decision.
   Within those limits the published numbers are: `clap_derive` ~596 KiB release
   overhead and ~4 s full debug build against a null baseline of 0 KiB / 163 ms;
   `clap` builder 574 KiB / 3 s; `bpaf_derive` 253 KiB / 4 s; `argh` 38 KiB;
   `lexopt` 37 KiB; `pico-args` 24 KiB. Two readings matter and both are
   qualified the same way: parse latency is 2 ms for *every* entrant in that
   run including the minimal ones, so **on those figures** no candidate can be
   preferred on parsing throughput; and the incremental-rebuild delta the
   template's users would feel is 182 ms vs 123 ms, ~59 ms, **on that system at
   that version**. The cost at 4.6.6 with this template's feature set, on
   `ubuntu-latest` and `macos-latest`, is unmeasured — see `## Engines`.
4. **Gate 2, `vergen`.** `vergen 10.0.3` declares `rust-version = 1.96.0`,
   which is *exactly* today's floor (stable `1.98.1`, published 2026-09-03,
   minus two minors). Resolution at `rust-version = "1.96"` succeeds; resolution
   at `rust-version = "1.95"` — the floor as it stood one Rust release ago —
   makes Cargo report "Adding vergen v10.0.3 (requires Rust 1.96.0)". A
   build-dependency whose MSRV tracks current stable will therefore sit outside
   this template's floor whenever the floor lags, and the template would have to
   pin `vergen` back. That is the concrete reason the dependency-free `build.rs`
   is preferred over the Codex raw report's `vergen` recommendation, and it is a
   maintenance cost the Codex report does not state.

**Practice evidence, verified rather than asserted.** Every manifest line below
was read in this run via `GET
https://api.github.com/repos/<o>/<r>/contents/Cargo.toml`, base64-decoded,
2026-09-10; star counts are from the Opus raw report at the same retrieval date.

| Project | Why it is a relevant reference | Manifest evidence |
|---|---|---|
| `rust-lang/cargo` | the Rust project's own package manager | `Cargo.toml:42-43` — `clap = "4.6.0"`, `clap_complete = { version = "4.6.0", features = ["unstable-dynamic"] }`; `:173` adds `wrap_help` |
| `rust-lang/rustup` | the Rust project's toolchain installer | `Cargo.toml:46,48` — `clap = { version = "4", features = ["derive","wrap_help","string"] }`, `clap_complete` |
| `astral-sh/uv` | one of the newest high-adoption Rust CLIs (89,684 stars per the Opus report) | `Cargo.toml:125,131` — `clap = { version = "4.5.17", … }`, `clap_complete_command = "0.6.1"` |
| `astral-sh/ruff` | same maintainer, 49,573 stars per the Opus report | `Cargo.toml:82-83` — `clap = { version = "4.5.3", features = ["derive"] }` |
| `casey/just` | ships **exactly** this decision's feature set | `Cargo.toml:24-26` — `clap = { version = "4.0.0", features = ["derive","env","string","wrap_help"] }`, `clap_complete = "=4.6.8"`, `clap_mangen = "0.3.0"` |
| `starship/starship` | tracks clap closely; also the adopter of the *rejected* metadata crate | `Cargo.toml:38-39` — `clap = { version = "4.6.6", … }`, `clap_complete = "4.6.9"`; `:79` — `shadow-rs = "2.0.0"` |
| `BurntSushi/ripgrep` | the strongest counterexample | `Cargo.toml:63` — `lexopt = "0.3.0"`; no clap |

`casey/just` is the composition evidence for this feature set: one released
binary carrying `clap` with `derive`+`env`+`string`+`wrap_help` alongside
`clap_complete`. State its limit exactly — its manifest requests `clap =
"4.0.0"` and pins `clap_complete = "=4.6.8"`, so it demonstrates that this
*feature combination* ships in production, not that it ships at the 4.6.6 and
4.6.9 recommended here. The version matrix is proved independently in the
crate metadata — `clap_complete 4.6.9` declares `clap >= 4.5.20`
(`clap_complete-4.6.9/Cargo.toml:127-130`), so `clap 4.6.6` satisfies it, and
the resolution in `## Empirical check` produced a single `clap v4.6.6` node
shared by both.

**Essential behaviors** — each verified by reading the published crate source at
the version cited, 2026-09-10:

1. **`ArgAction::Version` terminates the parse, so no other flag on the command
   line is ever seen.** Its match arm computes `use_long` from the identifier —
   `Identifier::Long` sets `use_long = true`, `Identifier::Short` sets it
   `false` — and then returns `Err(self.version_err(use_long))`
   (`clap_builder-4.6.6/src/parser/parser.rs:1322-1331`, read 2026-09-14;
   `## Empirical check` row E11). `version_err` renders from the
   `Command::version` and `Command::long_version` *strings* and has no access to
   any parsed value, and `_render_version` prefers one or the other by
   `use_long`, each falling back to the other
   (`command.rs:4898-4914`). Two consequences decide F267's mechanism. The
   built-in flag **can** give `-V` and `--version` different text, which is what
   revision 3's withdrawn option (a) used. It **cannot** give either of them
   `<tool> --version <format-flag> json`: the parse stops at `--version`, so a
   format flag placed after it is never read, and one placed before it is read
   into a `ArgMatches` the version renderer never receives. That is why option
   (b) is not a pure acceptance-criteria change.
2. **`Command::render_version()` is public and emits exactly R4.6's shape**, so
   the conformant line stays clap's own formatting rather than a hand-rolled
   `format!`. It is `self._render_version(false)` (`command.rs:1097-1099`), and
   `_render_version` ends `format!("{display_name} {ver}\n")`
   (`command.rs:4913`) — the version string appended to the display name on one
   line. With `Command::version` set and `Command::long_version` unset, the
   `false` branch reads `self.version` (`command.rs:4906-4911`), so
   `render_version()` is `<tool> <semver>\n`: R4.6's GNU name-and-version shape,
   one line, no leading `v` because Cargo rejects a leading `v` in a manifest
   `version` field and `CARGO_PKG_VERSION` therefore carries none.
   `Command::disable_version_flag(true)` removes the built-in `-V`/`--version`
   entirely — its own doctest asserts that `--version` then returns
   `ErrorKind::UnknownArgument` (`command.rs:1448-1463`, method at `:1493`) —
   and the documentation shows re-declaring a custom flag in its place
   (`:1465-1478`). Read that second example carefully, because it is a trap
   here: it re-declares the flag with `.action(ArgAction::Version)` (`:1476`),
   which restores the very short-circuit behavior 1 describes, and its own
   assertion at `:1490` is that `--version` still yields
   `ErrorKind::DisplayVersion`. The template must **not** follow that recipe. It
   declares a plain boolean instead, so the flag records a value and the parse
   continues to the format flag. Those three facts are what make option (b)
   buildable:
   `disable_version_flag(true)`, a template-declared global `-V`/`--version`
   boolean that does **not** carry `ArgAction::Version`, and `render_version()`
   for the conformant line once the parse has completed and the format flag is
   known. All four line ranges are verified in the committed crate snapshots
   (`## Empirical check` rows E11 and E12).
3. A `global = true` argument matches on every child subcommand: "Global
   arguments *only* propagate down … it doesn't matter where the user *uses* the
   global argument" (`arg.rs:877-886`, with the doctest at `:894-911` asserting
   `prog do-stuff --verbose`). This satisfies R4.5's `MUST` (before the verb)
   and its `SHOULD` (after the verb) from one declaration.
4. `Arg::env` is per-argument and reads the process environment at declaration
   time (`arg.rs:2205-2210`), gated on the `env` feature. No prefix or
   auto-binding API exists (grep, above).
5. Unknown-command matching is `strsim::jaro` with the literal threshold
   `confidence > 0.7`, sorted most-similar-last
   (`clap_builder-4.6.6/src/parser/features/suggestions.rs:17-35`). The source
   carries the maintainers' own reason for `jaro` over `jaro_winkler`: "GH
   #4660: using `jaro` because `jaro_winkler` implementation in `strsim-rs` is
   wrong causing strings with common prefix >=10 to be considered perfectly
   similar" (`:17-18`). With the `suggestions` feature off, `did_you_mean`
   returns an empty `Vec` (`:38-45`) — so the feature, which is on by default
   (`clap-4.6.6/Cargo.toml`, `default = [… "suggestions"]`), must stay on.
6. `infer_subcommands` is opt-in (`command.rs:1840`), so exact matching is the
   default. Leave it off: R3.10 `(MUST)` forbids automatic prefix abbreviation
   because "adding a flag later silently breaks scripts that relied on the
   shorter form" (`:229-230`). With the canonical noun singular under R1.3, the
   conformant behavior on a mistyped noun — say `<tool> projct list` — is a
   suggestion that *names* `project`, at exit `2`; what R3.10 forbids is
   *resolving* a prefix such as `proj` to `project` by inference. The
   distinction is between naming a candidate and silently accepting one. A
   plural spelling is a different case again: it is reachable only if an
   explicit hidden alias is declared for it (R1.3's `MAY`), never by inference,
   and it stays absent from help either way.
7. `clap_complete 4.6.9`'s `Shell` enum is `Bash`, `Elvish`, `Fish`,
   `PowerShell`, `Zsh` (`clap_complete-4.6.9/src/aot/shells/shell.rs:15-26`),
   covering R9.1's required three, and `aot::generate` writes to any
   `dyn Write` (`src/aot/generator/mod.rs:284-291`) — so the `completion`
   subcommand can print to stdout rather than to a file.

**Observable acceptance criteria — every one is a proposal for P03; none was
executed here** (see `## Empirical check` for what was and was not run):

| # | Criterion |
|---|---|
| AC1 | `<tool> project list --json` and `<tool> --json project list` both parse, and the flag is declared exactly once (R4.5) |
| AC2 | **`<tool> -V` and `<tool> --version` produce byte-identical output**: exactly one line matching `^<tool> \d+\.\d+\.\d+$`, on stdout, exit `0` (R4.6's single-line `SHOULD`, `:276`). Byte-identity is the assertion that discharges the owner's 2026-09-14 ruling, because it is what a `Command::long_version` on the long spelling would break; asserting each spelling separately would pass a tool that printed extended data on one of them. A second assertion makes the mechanism observable rather than inferred: the semver carries **no leading `v`** (R4.6 `MUST`, `:276`) |
| AC3 | **`<tool> --version <format-flag> json` emits one JSON object and exits `0`**, where `<format-flag>` is R66's format-selection flag (see `## Parameters`). The object parses, and `version` is the same SemVer string AC2 asserts, again with no leading `v` (R4.6 `MUST`, `:276`). It carries a `target` field holding the build's target triple and a `rustc` field holding the compiler version; `commit` and `built` are **absent**, which R4.6's "**MAY** be omitted or `null` when unknown" permits for a build script that reads neither. The build-script half is what AC3 exists to prove: `target` differs between the `ubuntu-latest` and `macos-latest` CI legs, which is what distinguishes a `build.rs` that read Cargo's `TARGET` from one carrying a hard-coded string. Nothing but the object goes to stdout on this path |
| AC4 | `<tool> completion bash`, `… zsh` and `… fish` each write a non-empty script to stdout and exit `0`; a golden-file test detects drift between the parser and the emitted scripts |
| AC5 | `<TOOL>_OUTPUT=json <tool> project list` honors the env var; a global option deliberately left out of the curated set is **not** readable from `<TOOL>_*`, asserted by a test over `Cli::command()` that enumerates every argument carrying an `env` and compares it to a pinned list (R5.4) |
| AC6 | `<tool> projct list` (a mistyped noun, unknown) exits `2`, prints a suggestion naming `project` on stderr, keeps stdout byte-empty, and executes no command; and `<tool> proj list` (a bare prefix) also exits `2` rather than resolving to `project`, which is what `infer_subcommands` left off buys (R3.10 + R67) |
| AC7 | `<tool> --help` and `<tool> --version` exit `0` with output on stdout; every other parse failure exits `2` inside R67's JSON envelope on stderr. The two halves now reach that outcome by different routes and the test must not assume one: `--help` is still a `clap::Error` of kind `DisplayHelp` that `try_parse` returns and the template maps to `0`, while `--version` returns through `Ok` and is printed by the template, because F267's mechanism removes `ArgAction::Version` (essential behavior 1). Asserted on the observable outcome — stream, bytes and exit status — not on the error kind |
| AC8 | every command path is `<noun> <verb>` at depth ≤ 3, asserted by walking `Cli::command().get_subcommands()` (R1.1, R1.2) |
| AC9 | **the canonical form of every documented noun is singular (R1.3 `MUST`).** Three assertions, because the rule has three parts. (a) `<tool> project list` parses and is the documented spelling: `<tool> project --help` and `<tool> --help` both exit `0` and name `project`. (b) Walking `Cli::command().get_subcommands()` (`command.rs:3932`), every subcommand that is help-visible — `is_hide_set()` (`:4242`) false — has a singular `get_name()` (`:3756`), checked against a pinned list of the template's nouns rather than by an English pluralization heuristic, which would misjudge irregular nouns. (c) No plural spelling appears in any rendered help: `render_long_help()` (`:1037`) for the root and for every subcommand contains no `projects`, asserted by string search over the rendered text. (c) is the assertion that actually discharges "**MUST NOT** appear in help or docs"; (a) and (b) alone would pass a tool that documented both spellings |
| AC10 | **if, and only if, a hidden plural alias is declared:** `<tool> projects list` parses to the same command as `<tool> project list` and exits `0`, while the alias is absent from every help surface AC9(c) searches — for the `project` subcommand, `get_visible_aliases()` (`command.rs:3847`) yields nothing and `get_all_aliases()` (`:3874`) yields `projects`, which is exactly the split `Command::alias` produces and `visible_alias` does not (R1.3's `MAY`, R1.6). If no alias is declared, AC10 is vacuous and `<tool> projects list` exits `2` under AC6's rule. Both outcomes conform; P03 records which it chose |

**RETIRED OVERRIDE (OV-01) — F267's proposed deviation from R4.6 `(SHOULD)`,
withdrawn on the owner's ruling of 2026-09-14.** OV-01 was filed by revision 1 as
the programme's first override and carried by revisions 2 and 3 as an outstanding
waiver request. **It is no longer an override.** The owner refused the waiver and
selected this item's own conforming **option (b)**, so **R60 declares zero
overrides** and no `SHOULD` of the pinned standard is waived. The block is kept,
re-labelled rather than deleted: the charter records a departure as
`OVERRIDE (OV-nn)` with its `**Argument:**` and `**Options:**`, and the argument
and the options table below are the record of how the choice was reached — the
owner chose from exactly this table. They now describe a **withdrawn proposal**,
not an active deviation, and nothing in them should be read as a live departure.

Its rule references — R4.6 and the conformance clause at `:50` — resolve against
the pinned standard revision recorded under "THE STANDARD PIN" above (version
1.4.14, blob `f9de0437`), so the `SHOULD` at issue is fixed text rather than
whatever a later amendment makes of it. **One citation correction, found while
re-reading R4.6 for this revision and reported rather than fixed silently:** R4.6
spans `:275-277` in the pinned text — heading at `:275`, the rule at `:276`, the
✅/❌ example at `:277` — with `:278` blank and `:279` the heading of R4.7. The
ranges `:275-279` and `:277-279` used below therefore overrun the rule by two
lines. They are **left byte-identical** because those lines are the preserved
historical record and one of them is a revision-1 preservation target; every
citation this revision *relies* on uses the corrected range. The permission that
option (b) rests on and the object shape it must match are both on **`:276`**,
and the worked example is on `:277`. Verified line by line in
`## Empirical check` row E5.

**Waiver status — two dated states, the second superseding the first.**

- **Requested 2026-09-12**, by revision 2, and recorded as outstanding through
  revision 3. The text of that record is kept verbatim below.
- **REFUSED 2026-09-14.** The owner declined the waiver and selected **option
  (b)**. No `SHOULD` waiver is owed for this item, none is outstanding, and no
  owner waiver record under `:50` needs to exist — because there is no longer a
  deviation for one to cover.

**What the repository can and cannot show for that ruling, stated plainly.** The
refusal reached this revision as a task instruction from the programme
controller. **It is not written into any file in this repository**:
`docs/port/OWNER-REVIEW.md:101` carries only R60's 2026-09-04 codesign
acceptance ("Effect: none; runs as written") and says nothing about OV-01, and a
search of that file for `OV-01` or `2026-09-14` returns nothing. So a reader of
this repository alone cannot re-derive the ruling, and this decision does not
pretend otherwise: the ruling is listed under `## Engines` as **U8, unproven
from the repository**, with what would prove it. What *is* checkable here is the
consequence — that the decision now declares no override and claims no waiver —
and that is asserted mechanically in `## Empirical check` row E9.

**That whole paragraph was true when revision 4 wrote it and is false now, and
this revision corrects it in place rather than deleting it.** The revision-4
audit found it stale (finding F1, quoted in full at the top of this document).
Between revision 4's drafting and its audit, the programme controller wrote the
ruling into the port's durable record, so every clause above that claims absence
is now wrong: **the ruling IS written into two files in this repository**, a
reader of this repository alone **can** re-derive it, and it is no longer
unproven. Where it is recorded, exactly:

- **`docs/port/OWNER-REVIEW.md:72-91`**, in the section
  `### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused`, under
  the file's own heading "Later owner rulings that bind every item (recorded
  after the 2026-09-04 codesign)". It states that version 1.4.14, blob
  `f9de0437`, governs this template; that "**Override OV-01 is REFUSED**"; that
  "The owner instead selected R60's own conformant option (b)"; that
  "**Consequence for conformance: the template waives no `SHOULD`**"; and that
  "R60 carries zero overrides; OV-01 is retired as refused rather than deleted,
  its argument and options table kept as the record of how the choice was
  reached". That is this block's own disposition, written by the owner's record
  rather than inferred from it.
- **`docs/planning/p02/owner-decisions.md:261-292`**, section
  `## 9. Whether your CLI Design Standard binds this port -- ANSWERED 2026-09-14`,
  which carries the reasoning and the blast radius: "**DECIDED.** The standard
  BINDS. Override OV-01 is NOT waived; the owner selected R60's own conformant
  option (b)."

Both files are read-only to this item — the charter forbids a synthesizer from
editing either — so this revision cites them and changes neither. The sentence
"`docs/port/OWNER-REVIEW.md:101` carries only R60's 2026-09-04 codesign
acceptance … and says nothing about OV-01" above described that file as it stood
on 2026-09-14 before the controller's write; the codesign row is still there and
still says what the sentence says, but it is no longer the only R60 material in
the file. **U8 is accordingly re-labelled RESOLVED under `## Engines`**, and the
two checks that asserted the ruling's absence are inverted to assert its
presence (`## Empirical check` row E13, `C16h`–`C16o2` of
`r60-standard-pin-r5.sh`).

**One divergence between the owner's record and this decision, reported rather
than quietly reconciled, and it does not touch the ruling.** The
`owner-decisions.md` section says "AC2 and AC3 are rewritten and nothing else in
R60 changes, exactly as R60 itself predicted for options (b) and (c)", and cites
R4.6 as `:277-279`. Both clauses are R60's own revision-3 text repeated back:
revision 4 established that the prediction was too narrow (delivering (b)'s JSON
path also moves the clap wiring, essential behaviors 1 and 2, AC7 and the R67
routing paragraph — evidence rows E11 and E12) and that R4.6 spans `:275-277`,
so `:277-279` overruns the rule by two lines. **Neither correction changes the
owner's choice**, which is option (b) either way; they change only what
implementing it costs inside R60, which is this item's to establish. Nothing in
the owner's record is edited here.

**The status as recorded on 2026-09-12, kept verbatim as the record of what was
asked and when. It is superseded by the refusal above and is not this revision's
position:**

**Waiver status, as of 2026-09-12: requested, not granted.** The owner has not
answered the waiver request, and nothing below should be read as approval. Only
the owner can record a `SHOULD` waiver (`:50`), no such record exists, and until
one does the recommended option (a) is a *proposed* deviation. The conforming
alternatives are named in the Options table below and are **option (b)** —
extended data behind `<tool> --version -o json` — and **option (c)** — extended
data moved to a `doctor` verb; either can be adopted instead of (a) with no
waiver at all, and the cost of adopting one is confined to rewriting AC2 and
AC3.

**The argument and the options exactly as filed, kept unedited. Option (a) is
the withdrawn proposal; option (b) is what the owner selected:**

**Argument:** R4.6 (`:275-279`, read 2026-09-10) says `--version`/`-V`
"**SHOULD** print a single line `acme <semver>` … a build **MAY** append
commit/date for pre-release builds". Printing a target-triple line and a rustc
line on *every* build is more than that `MAY` permits, so the recommended shape
is a deviation. It is a `SHOULD`, and the standard's own conformance clause
makes such a deviation legitimate only when recorded: "A SHOULD waiver **MUST**
name the rule ID, describe the deviation, explain the rationale, and record the
owner/date or equivalent review record" (`:50`). That owner record does not
exist yet, so this is filed as an override rather than settled. The deviation is
narrow in three ways worth stating exactly: it applies to `--version` only, `-V`
stays fully conformant, and the first line of `--version` is still
`<tool> <semver>` because clap formats `{display_name} {ver}` (essential
behavior 2 above). py's precedent for the extended content is real but is not
itself a reason — py prints three lines on *both* spellings unconditionally (py
`cli/main.py:48-56`, read through the pin 2026-09-10), which is further from
R4.6 than what is recommended here.

**Options:**

| | Option | Effect | Conformance |
|---|---|---|---|
| a | **Recommended.** `-V` one line; `--version` prints that line plus a target line and a rustc line, via `Command::long_version` | F267's information content is available from the flag a user already knows; one `long_version` string, no new command | R4.6 deviation, waiver required per `:50` |
| b | `-V` *and* `--version` both one line; extended data behind `<tool> --version -o json`, which R4.6 explicitly permits (`:277-279`) | fully conformant; costs the user a second flag to discover, and couples F267 to R66's output-format surface, which R60's prompt puts out of scope | conformant |
| c | `-V` and `--version` both one line; extended data moved to a `doctor` verb (py has one at `cli/main.py:103`) | fully conformant; separates "what version" from "what build", which is arguably the cleaner split | conformant |

The owner's ruling is needed because only the owner can record a `SHOULD`
waiver. **If the ruling is (b) or (c), nothing else in this decision changes**:
the build-metadata mechanism, the `version`/`long_version` API and every other
member are unaffected, and only the acceptance criteria AC2/AC3 are rewritten.

**That last sentence was wrong on one clause, and this revision corrects it
rather than quietly working to it.** The ruling was (b). The build-metadata
mechanism and every other member are indeed unaffected, as predicted. But the
`version`/`long_version` API is **not** unaffected, and the change is not
confined to AC2 and AC3. `Command::long_version` leaves the design entirely, and
delivering (b)'s JSON path requires `Command::disable_version_flag(true)` plus a
template-declared `-V`/`--version`, because `ArgAction::Version` ends the parse
before a format flag can be read (essential behavior 1, evidence row E11). The
sentence was written from the *content* of the two options — both print one line
by default — without checking whether clap's built-in version flag could carry
(b)'s second half. It could not. The full list of what moved is in `## Engines`
under "Audit of revision 3, and what revision 4 changed".

**F267 AS DECIDED — option (b), and the mechanism that delivers it.**

| Surface | Behavior | Mechanism |
|---|---|---|
| `<tool> -V` | one line, `<tool> <semver>`, stdout, exit `0` | `Command::render_version()` (`command.rs:1097`), which is `_render_version(false)` and reads `Command::version` |
| `<tool> --version` | **byte-identical to `-V`** | the same call; there is no `long_version` to diverge from |
| `<tool> --version <format-flag> json` | one JSON object, stdout, exit `0` | the template serializes `{"version","target","rustc"}` from `CARGO_PKG_VERSION` and the two `build.rs` values |

The declaration, in derive form: `#[command(disable_version_flag = true)]` on the
root, and a `-V`/`--version` boolean carried in the same `#[derive(Args)]
GlobalArgs` struct F270 already flattens with `global = true`, so R4.5's `MUST`
(accepted before the subcommand) and its `SHOULD` (accepted after it) hold for it
as they do for every other global. The flag must be a plain boolean; giving it
`ArgAction::Version`, as clap's own `disable_version_flag` example does at
`command.rs:1476`, would reinstate the short-circuit and make the JSON path
unreachable again.

**The JSON object, matched to R4.6 rather than invented.** R4.6 (`:276`) says a
supported JSON version output "**SHOULD** emit an object such as
`{"version":"1.4.0","commit":"abc123","built":"2026-06-27T12:00:00Z"}`;
`version` **MUST** be SemVer without a leading `v`, while `commit` and `built`
**MAY** be omitted or `null` when unknown." This template emits:

- `version` — required, and the `MUST` is satisfied structurally rather than by
  a runtime check: the value is `CARGO_PKG_VERSION`, which mirrors the manifest
  `version` field, and **Cargo refuses to parse a manifest whose `version`
  carries a leading `v`** — verified in this run, command and verbatim output
  under `## Empirical check`, "Revision-4 one-off check". So the string cannot
  carry one, and AC2 and AC3 still assert it observably rather than relying on
  that argument alone. Which of compile-time `env!` and a runtime metadata
  lookup supplies the value is **R22's** decision, not this item's; both satisfy
  the `MUST` identically.
- `target` and `rustc` — the target triple and the compiler version, from the
  dependency-free `build.rs` that reads Cargo's `TARGET` and runs `$RUSTC -vV`.
  These are the two fields F267 exists to carry. R4.6's wording is "an object
  **such as**", which makes its three named keys illustrative rather than
  closed, so additional fields ride alongside without deviating.
- `commit` and `built` — **omitted**, not `null`. The recommended `build.rs`
  reads neither git state nor a clock, so both are genuinely unknown, which is
  the case R4.6's `MAY` names. Omission rather than `null` also matches R67's
  envelope convention for an absent optional field — R67's essential behavior 4
  reads "`hint` is optional, structured, non-secret, and omitted (not `null`)
  when absent"
  (`research/topics/67-error-and-exit-code-contract/DECISION.md:105`, **read
  2026-09-14 for this revision**, not carried over from an earlier retrieval;
  the same wording appears in the `error-taxonomy-exit-codes` row of
  `docs/port/PARAMETERS.md`) — so the two machine-readable surfaces this
  template ships treat absence the same way.

**`<format-flag>` is a placeholder, on the same footing as `<tool>`, and the
coupling to R66 is named rather than absorbed.** Option (b)'s own text warned
that it "couples F267 to R66's output-format surface, which R60's prompt puts
out of scope". The owner selected (b), so that coupling is now real. Three
questions decide how to record it, and each is answered from the two prompts and
the registry rather than from judgement.

1. **Does R60 need a value R66 owns?** No, because **R66 owns no registry
   parameter**. Its prompt's `- owns:` line is empty
   (`research/runs/R66/2026-09-05T183458Z-9ff7d91f9b8f/inputs/prompt.md`, the
   `## Couplings` block, read 2026-09-14), and `docs/port/PARAMETERS.md` carries
   no output-format row (read 2026-09-14; `## Empirical check` row E13). A
   `CONFLICT: R66 <param> — <needed value> — <reason>` line names a *consumed
   parameter* whose registry value would have to change; there is no such
   parameter to name, so writing one would invent a registry row. **No
   `CONFLICT:` line is raised**, and this is recorded instead as a
   `related (not a registry dependency)` note in `## Parameters`.
2. **Does R60's conformance depend on R66 resolving?** No. R4.6's `SHOULD` is
   the single line, and both spellings print it under this decision. The JSON
   path is R4.6's `MAY` (`:276`). So if R66 never resolved at all, F267 would
   still conform; what would be lost is F267's extended content, not the
   template's conformance. The `no waived SHOULD` claim above therefore stands
   on its own.
3. **What must R66 stay compatible with, exactly?** Three things, and nothing
   else:
   - **A format-selection flag that accepts the value `json`.** F292 (`--json`
     shorthand, `COMMON → REUSE`) already guarantees a JSON mode exists; R66
     decides the underlying flag it aliases to.
   - **That flag being declarable on the root command**, so
     `<tool> --version <format-flag> json` parses. R60 supplies this half: the
     flag is declared in F270's flattened `GlobalArgs` with `global = true`.
     R66 need not make it global for result output — R4.6 says `--version`
     "**MAY** honor `-o json`/`--output json` **even when normal result-output
     options are otherwise command-scoped**" (`:276`), so R66's scoping choice
     for result output does not constrain F267 either way.
   - **The spelling**, which is the only part R60 cannot supply. R4.5 (`:270`)
     and R4.6 (`:276-277`) both write it `-o`/`--output`; ts's D-033 instead
     keeps `--output` as the file sink and uses `--format`, which R66's own
     prompt describes as "a documented divergence from cli-standards' `-o`
     output-format enum". **R60 does not decide between them**, exactly as it
     does not decide `<tool>` (R49's binary name). Every `<format-flag>` here
     resolves to whatever R66 names; if R66 lands on `-o`/`--output`, the
     surface is R4.6's own worked example verbatim, and if it lands on
     `--format`, the surface is `<tool> --version --format json` and every
     sentence above holds with the spelling substituted.

   If R66 were to decide that **no** format-selection flag is accepted at the
   root under any spelling, F267 would have to fall back to option (c) — the
   `doctor` verb — which is equally conformant and needs nothing from R66. That
   is the one R66 outcome that would reopen F267, and it is added to
   `re-verify`.

**BASELINE-REVIEW findings.** None. F266 and F271, the two inherited rows this
item touches, are marked `retained` in `docs/port/BASELINE-REVIEW.md:114-115`
(read 2026-09-10), and the crate-source reads above confirm both capabilities
are native to the recommended stack rather than hand-built. The Codex raw report
emits a `BASELINE-REVIEW: F269` line; that line is not carried, for the reason
given in `## Engines`.

re-verify: 2027-03-10, or earlier on any of — **the org CLI Design Standard moving off the pinned revision (version 1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`), which is detectable by re-running `## Empirical check` row E10, the only check here that reads live history — `bash review/evidence/r60-snapshot-provenance-r3.sh`, whose check `C2a` fails the moment the newest published commit for that path is no longer `fb30a591…`: any new commit to `cli-design-standard.md` changes the blob id and invalidates every `:<line>` citation here, and an amendment to R1.1, R1.3, R3.10, R4.5, R4.6, R5.4, R9.1 or the Appendix A entry criteria would change the substance as well**; clap releasing a 5.x line; the `clap_complete` `unstable-dynamic` completion path stabilizing; a RustSec advisory opening against `clap`, `clap_builder`, `clap_derive`, `clap_complete` or `strsim`; R22 (`runtime-version-accessor`) resolving and changing where the version value comes from; Rust stable advancing far enough that the MSRV floor rises above a recommended crate's declared `rust-version` (the highest declared `rust-version` among the 28 dependency crates is **1.85**, shared by the five `clap`-family crates, so the current 1.96 floor has eleven minors of headroom and this trigger is remote); or **R66 (`output-format-surface`) resolving in a way that leaves no format-selection flag acceptable on the root command under any spelling, which is the one R66 outcome that reopens F267 and sends it to option (c)** — R66 merely *naming* the flag does not reopen anything, because `<format-flag>` is a placeholder that resolves to whatever R66 names. **The trigger "the owner ruling on OVERRIDE (OV-01)", carried by revisions 1 through 3, has fired and is removed:** the owner ruled on 2026-09-14, refusing the waiver and selecting option (b), and OV-01 is retired.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item's prompt carries an empty `- owns:` line and an empty `- consumes:`
line, so it owns no registry parameter and consumes none; the four lines above
are the fixed parameters, copied from `docs/port/PARAMETERS.md`. No `CONFLICT:`
line is raised.

How each bears on the decision. **msrv-policy** fixes the floor at `1.96` today
(stable `1.98.1`, published 2026-09-03, minus two minors) and is what excludes
`shadow-rs`, `argh`, `lexopt` and `pico-args` at gate 2 for declaring no
`rust-version` at all, and what demotes `vergen 10.0.3` — whose declared
`1.96.0` sits exactly on the floor with no headroom — beneath a dependency-free
`build.rs`. **rust-edition** is satisfied without action: `clap 4.6.6` and
`clap_complete 4.6.9` both declare `edition = "2024"` themselves.
**license** is this repository's own declared expression and is unaffected by
anything recommended here, because nothing recommended here is committed into
this repository as source. Under the owner's 2026-09-12 ruling (Q7.B) no
dependency's licence is evaluated against it, so this parameter imposes no
constraint on crate selection and excluded no candidate; the expressions the
registry returned for all 28 resolved crates are recorded as facts in the
evidence log, section W. **target-os-matrix** is the gate
this run did *not* discharge: nothing here was executed on `ubuntu-latest`, and
that gap is recorded under `## Engines`.

Four parameter-shaped notes that are deliberately **not** parameter lines.
R22 (`runtime-version-accessor`, ledger F064) supplies the version *value* that
F267 prints; it is listed in this item's prompt as "related (not a registry
dependency)", and this decision is compatible with either R22 outcome and
imposes no constraint on it.

**R66 (`output-format-surface`) — related (not a registry dependency), and no
`CONFLICT:` line.** F267's decided mechanism (option (b), on the owner's ruling
of 2026-09-14) puts the extended build data behind
`<tool> --version <format-flag> json`, where `<format-flag>` is R66's
format-selection flag. That is a real coupling and it is recorded here rather
than absorbed. It is **not** a registry dependency and **not** a `CONFLICT:`,
for a checked reason: **R66 owns no registry parameter.** Its prompt's
`- owns:` line is empty, and `docs/port/PARAMETERS.md` carries no output-format
row, so there is no consumed parameter whose value this item could need changed
— which is what a `CONFLICT:` line names. What R66 must stay compatible with is
three properties, set out in full under "F267 AS DECIDED" in `## Decision`: a
format-selection flag that accepts `json`; that flag being declarable on the
root command, which R60 itself supplies by carrying it in F270's flattened
`GlobalArgs` with `global = true`; and its spelling, which R60 deliberately does
not decide. R60's *conformance* does not depend on R66 at all, because R4.6's
`SHOULD` is discharged by the single line that both `-V` and `--version` print
and the JSON path is R4.6's `MAY`. The single R66 outcome that would reopen
F267 — no root-acceptable format flag under any spelling — is on the
`re-verify` line.

R67 owns `error-taxonomy-exit-codes`; this item
consumes none of it as a parameter, but its parser-error routing must satisfy
R67's contract, as described in `## Decision`. All three Doxa provider bodies
wrote `owns` lines for names such as `cli-parsing-framework`,
`command-surface`, `extended-version` and `blanket-global-env-binding`; no such
row exists in `docs/port/PARAMETERS.md`, and the prompt's `- owns:` line is
empty, so none of them appears above.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4, `aarch64`.
Rust stable at the retrieval date is `1.98.1`, published 2026-09-03 (`GET
https://api.github.com/repos/rust-lang/rust/releases/latest`, `tag_name`), so
the local toolchain is one patch behind stable and the MSRV floor is `1.96`.

**Working directory** for every command:
`/private/tmp/claude-501/…/scratchpad/r60` (a scratch directory). Nothing was
written into the template repository. **Nothing here implements the
recommendation**: no command surface, no `completion` command, no `build.rs`, no
CLI of any kind was written. The only Rust files created are two
resolution-only manifests, each with an empty `src/lib.rs`, which exist solely
so that `cargo` will resolve the pins.

**Three runs, kept separate.** Sections 01–12 below are the **revision-1** run
of 2026-09-10. Rows **E1–E10** are the verification run first performed for
revision 2 on 2026-09-12, re-executed in full for revision 3 on 2026-09-13
against a rebuilt, self-contained evidence apparatus, re-executed again in full
for revision 4 on 2026-09-14 against the revision-4 scripts, **re-executed once
more for revision 5 on 2026-09-14** against the revision-5 scripts, and
**re-executed a fifth time for revision 6 on 2026-09-15** — the preservation half
against the new `r60-preservation-diff-r6.sh`, the standard-pin and provenance
halves against the unchanged `r60-standard-pin-r5.sh` and
`r60-snapshot-provenance-r4.sh` — and **re-executed a sixth time for revision 7
on 2026-09-15**, the preservation half against the new
`r60-preservation-diff-r7.sh` and the other two halves against those same two
unchanged scripts. Rows
**E11–E13** were added in revision 4: they carry the three
claims the owner's ruling made load-bearing — that `ArgAction::Version`
terminates the parse, that the four `Command` version APIs behave as the decided
mechanism needs, and that R66 owns no registry parameter. **E13's second half is
rewritten in revision 5**, because the fact it asserted — that the owner's
ruling was absent from this repository — stopped being true, which is the
revision-4 audit's finding F1. Together the rows
verify the standard pin, the R1.3 rule text, every standard line this decision
cites, the clap APIs the acceptance criteria name, what this revision preserved,
and — row E10 — that every snapshot read really came from the source it names.
**Identifier note:** `E<n>` numbers an evidence row in this section and `C<n>` a
check inside a saved script; `P<n>` numbers a *principle* in `## Decision`'s
agreement table and `AC<n>` an acceptance criterion. The four sequences are
independent — `E6` and `P6` are unrelated. The `C<n>` ids were renumbered in
revision 3 when the scripts were rewritten, extended in revision 4, extended
again in revision 5, extended again in revision 6, and extended again in
revision 7; **where a row names a
`C<n>`, it names the id in the script that row cites** — the revision-7
preservation script for row E9, the unchanged revision-5 standard-pin script for
rows E1–E8 and E11–E13, and the unchanged revision-4 provenance script for row
E10 — and each later script carries the earlier ones' ids unchanged for every
check it inherits.

**Revision-1 output: `review/evidence/r60-cli-parsing-verification.log`** (1,142
lines; the section numbers and letters below match the headings in that file).
**Neither later revision re-ran sections 01–12**, and neither restates their output
as freshly reproduced. Those sections queried live endpoints (crates.io, the
GitHub API, rustsec.org), so a rerun would legitimately differ in download
counts, star counts, issue totals and advisory-database size. What is
independently attested instead is the pair of headline commands: the
revision-1 auditor reran `cargo generate-lockfile` and `cargo-audit audit` in an
isolated fixture and reported both at **exit 0**, with 28 registry packages
locked at `rust-version = "1.96"`, 29 stanzas including the local root, 29 crate
dependencies scanned, and `clap 4.6.6`, `clap_complete 4.6.9` and `strsim 0.11.1`
resolving as recommended (`review/audit-codex.r1.md:8-15`, actor
`audit-codex-2026-09-05T183002Z-09f93cfc507c-r1`, rerun log
`review/evidence/audit-cli-parsing-framework-r1.log`). Those two exit-zero
results are therefore reproduced evidence from a second party, not a
re-description of the original run.

| § | What it checks | Command | Result |
|---|---|---|---|
| 01 | version, license, declared MSRV, downloads for 13 candidates | `GET https://crates.io/api/v1/crates/<name>` and `/versions`, newest unyanked | `clap 4.6.6` MSRV `1.85`, `MIT OR Apache-2.0`, 226,398,266 recent / 1,119,879,906 all-time; `clap_complete 4.6.9` MSRV `1.85`; `vergen 10.0.3` MSRV **`1.96.0`**; `shadow-rs`/`argh`/`lexopt`/`pico-args` declare **no** `rust_version`; `argh` is `BSD-3-Clause` |
| 02 | repository state and open issues | `GET https://api.github.com/repos/<o>/<r>`; `GET /search/issues?q=repo:<o>/<r>+is:issue+is:open` | `clap-rs/clap` 16,697 stars, `archived` false, `pushed_at` 2026-09-09, **369** open issues; `pico-args` `pushed_at` 2023-10-19 |
| 02–03 | advisories, with the 404 reading validated | `GET https://rustsec.org/packages/<name>.html` | 404 for all eight recommended-or-runner-up crates; controls `anyhow` → 200 `RUSTSEC-2026-0190` and `atty` → 200 (two IDs) confirm 404 means "no advisory page" |
| 04 | clap behavior, read in the published tarball | `curl https://static.crates.io/crates/clap/clap-4.6.6.crate` (sha256 `473c7e07f409a8d772161724aa8db6a765a2532a70f9667eeb7b49d3d02fbdca`) and the three companion tarballs, unpacked | the seven essential behaviors listed in `## Decision`, each at a cited file and line; `default = [std,color,help,usage,error-context,suggestions]`; **no** `env_prefix`/`auto_env`/`envvar_prefix` symbol anywhere in `clap_builder` or `clap_derive` |
| 05 | completion generator | read `clap_complete-4.6.9` | `Shell` = Bash/Elvish/Fish/PowerShell/Zsh; depends on `clap >= 4.5.20` with `default-features = false` |
| 06 | build-metadata mechanism | `rustc -vV`; `GET https://doc.rust-lang.org/cargo/reference/environment-variables.html` | `rustc -vV` prints `release:`, `host:`, `commit-hash:`; the Cargo reference lists `TARGET`, `HOST`, `RUSTC`, `PROFILE` among the variables Cargo sets **for build scripts** — the two facts the dependency-free `build.rs` relies on |
| 07 | do the recommended pins resolve at the floor | `cargo generate-lockfile` and `cargo tree -e normal` on a manifest with `rust-version = "1.96"`, `edition = "2024"` and the two dependency lines | **exit 0** — "Locking 28 packages to latest Rust 1.96 compatible versions"; one shared `clap v4.6.6` node under both dependencies; `strsim v0.11.1` present transitively under `clap_builder`, never direct |
| 08 | advisories and licenses of the resolved tree | `cargo audit`; per-crate registry license lookup for all 28 | `cargo audit` **exit 0**, 1,243 advisories loaded, 29 crate dependencies scanned, nothing reported; every license MIT-or-Apache-compatible, `strsim` MIT the only single-licensed one |
| 09 | `vergen` MSRV headroom | the same resolution with `rust-version` `1.96`, then `1.95` | resolves at `1.96`; at `1.95` Cargo reports "Adding vergen v10.0.3 (requires Rust 1.96.0)" |
| 10 | the two source repositories, through their pins | `git -C ~/c/py-launch-blueprint show b08bccfb…:<path>`; `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:<path>` | every `## Context` line confirmed: py `import click`, the three-line eager `_print_version`, `"auto_envvar_prefix": APP_NAME.upper()` with its "catch-all" comment, `COMMAND_GROUPS`, four explicit `envvar=` names, the `_GLOBAL_OPTIONS` re-application loop, `difflib.get_close_matches`; ts `import { Command, CommanderError }`, `.showSuggestionAfterError(true)`, root-only `.option(…)`, `.command('projects', { isDefault: true })`, and the comment "Usage errors must exit 2 (cli-standards R6.1)". These are quotations of the two ports' source; their plural noun is the recorded practice that R1.3 overrides for the Rust template, not this decision's grammar — see the R1.3 consequence bullet in `## Decision` and row P7 below |
| 11 | adopter manifests | `GET /repos/<o>/<r>/contents/Cargo.toml`, base64-decoded, for seven projects | the practice-evidence table in `## Decision`; `casey/just` carries this decision's exact feature set; `starship` carries `shadow-rs`; `ripgrep` carries `lexopt` and no clap |
| 12 | MSRV of the whole resolved tree | `cargo metadata --format-version 1 --all-features` | 28 of the 29 packages declare a `rust-version`; the highest among the dependencies is **1.85**, shared by `clap`, `clap_builder`, `clap_complete`, `clap_derive` and `clap_lex`; `utf8parse` declares none |

**Revision-3 run — the standard pin, R1.3, the new criteria's APIs, and the
provenance of every input.** Three scripts, all under `review/evidence/`, run on
macOS 26.4 `aarch64` on 2026-09-13. Each takes no argument and no working
directory: each derives its own location from `${BASH_SOURCE[0]}` and reaches
everything else relative to that, so the invocation is the same from any
directory and the results do not depend on where the checkout lives.

| Script | Log | Result |
|---|---|---|
| `r60-standard-pin-r3.sh` | `r60-standard-pin-r3.log` | exit `0`, `CHECKS RUN: 73   FAILURES: 0` |
| `r60-preservation-diff-r3.sh` | `r60-preservation-diff-r3.log` | exit `0`, `CHECKS RUN: 66   FAILURES: 0` |
| `r60-snapshot-provenance-r3.sh` | `r60-snapshot-provenance-r3.log` | exit `0`, `CHECKS RUN: 14   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 2` |

**Nothing was implemented**: no crate was scaffolded, no command surface,
`build.rs`, `completion` command or test was written, and **no script writes
anything into this repository or this run directory**. The two offline scripts
create no file at all and emit only to stdout. The provenance script emits only
to stdout as well, but it does download into a directory of its own from
`mktemp -d`, which it removes on exit through a `trap`; that directory is where
the re-fetched tarballs and files are hashed.

**The revision-2 scripts and logs are retained and are not evidence for this
revision.** `r60-standard-pin-r2.sh`, `r60-preservation-diff-r2.sh`, their two
logs and the volatile sidecar `r60-concurrent-branch-state-r2.txt` stay in
`review/evidence/` because `review/audit-codex.r2.md` cites them by name and
deleting them would erase the record the rejection rests on. They are **known not
to rerun to their saved output from the committed state** — that is the finding
that produced this revision, reproduced by the auditor at exit `1` and exit `2`
— and no row below cites them. The sidecar is no longer produced by anything;
nothing in this decision ever rested on it.

**Why the apparatus was rebuilt, since that is this revision's whole subject.**
Revision 2's two scripts produced the same *content* answers, but they could not
be rerun once revision 2 was committed. Four distinct mechanisms did that, and
each one is removed rather than worked around:

| # | What revision 2 depended on | Why it failed after the commit | What revision 3 does instead |
|---|---|---|---|
| 1 | `HEAD:…/DECISION.md` resolving to the revision-1 blob `5ae06c37…` | at revision 2's commit that path resolves to the revision-2 blob, so the check inverted | the revision-1 and revision-2 texts are committed as `snapshots/r60-decision-r1.md` and `snapshots/r60-decision-r2.md` and identified by the sha256 each audit report names |
| 2 | `git status --porcelain` reporting exactly six dirty paths, one of them `DECISION.md` | committing makes the tree clean, so both counts go to zero | "the revision landed" is the r1→r3 and r2→r3 diffs being non-empty; "nothing was scaffolded" is a `find` over the committed run directory |
| 3 | `$HOME/c/cli-standards`, `$HOME/c/py-launch-blueprint`, `$HOME/c/ts-launch-blueprint` | those clones exist only on the authoring machine | the exact bytes read are committed under `review/evidence/snapshots/`, each verified against `snapshots/MANIFEST.txt` before it is read |
| 4 | an unpacked crate tarball under `/private/tmp/r60-r2-verify/` | a scratch directory that no longer exists; the script's own fallback branch counted a failure | the two source files read out of those tarballs are committed as snapshots, and the tarballs are re-downloaded and re-extracted by the provenance script |

**What each script guarantees, stated as the claims an auditor will test.**

**They can fail.** Every script opens with a `C0` negative control asserting a
substring known to be absent, so each log opens with a deliberate `FAIL` line
followed by `PASS C0 …`; if a harness ever stops detecting mismatches it exits
`99` and says the results are meaningless. Counters are then reset, which is why
the deliberate failure is not in the totals. That control exists because an early
draft put `check` on the right-hand side of a pipe — a subshell, whose increment
of the failure counter is lost — and printed `ALL CHECKS PASSED` while two checks
had in fact failed.

**They assert on content, never on exit status alone.** Every check names an
expected substring, and an empty expectation is itself reported as a bug rather
than passed. Numeric checks compare a labelled string (`count=0`, not `0`), so a
count of `10` cannot satisfy an expectation of `0` by substring match — a latent
defect in revision 2's harness, found and fixed here.

**The two offline logs are reproducible byte-for-byte, and that was demonstrated
from the committed state rather than from the working tree.** `r60-standard-pin-r3.sh`
and `r60-preservation-diff-r3.sh` read only files committed in this repository:
the snapshots under `review/evidence/snapshots/`, `docs/port/PARAMETERS.md`, the
published R67 topic, this run's audit reports, and `review/DECISION.md` itself.
They make no network call and need no git repository. Both were rerun against an
extraction of the exact tree this revision commits — `git archive` of that tree
into an empty directory outside the repository, which carries no `.git` and no
working-tree state — and `diff` against the two logs cited here reported no
difference. **The procedure, so that the claim is checkable rather than merely
transcribed:** `git archive <this revision's commit> | tar -x -C <empty
directory>`, then, in that directory's copy of this run, run each script and
`diff` its output against the log committed beside it. Transcripts of that run
are in this revision's commit messages, which also record — for the reader who
finds them — that two of those messages quote a `git write-tree` id that is not
the resulting commit's tree, because other agents commit to this shared branch
between one command and the next; the verification of record is the one against
the **commit** above, which is immutable. Two properties make the byte-identity
possible and are worth naming, because losing either would silently break it: no
script prints an absolute path, and `shasum` is always fed on **stdin** so it
prints `-` instead of a file name.

**The provenance log is reproducible under two stated conditions, and the exact
variance outside them is recorded here rather than discovered by an auditor.**
The log cited above reproduces byte-for-byte when the network is reachable **and**
the checkout carries git history. Without the network, the affected rows report
`UNREACHABLE`. Without git history — a `git archive` extraction, for instance —
the two rows that check this decision's own revision-1 and revision-2 baselines
against this repository's git objects cannot run, so they report
`UNVERIFIABLE-HERE` and the totals read `CHECKS RUN: 12 … UNVERIFIABLE-HERE: 4`
instead of `14 … 2`. That is the only difference, it was observed by running the
script in exactly that situation, and it is why the byte-for-byte claim above is
made for the two offline logs and not for this one.
`r60-snapshot-provenance-r3.sh` re-downloads
every pinned source and re-derives each snapshot's sha256 from it. It counts three
outcomes separately — `FAILURES` (the source was reached and disagrees),
`UNREACHABLE` (it could not be fetched, so nothing is proved either way) and
`UNVERIFIABLE-HERE` (there is no public remote at all) — and exits on `FAILURES`
alone, so an offline rerun is visibly incomplete instead of quietly green. Its two
`UNVERIFIABLE-HERE` entries are the two TypeScript source files: `smorinlabs/ts-launch-blueprint`
is a private repository, so no rerun outside the owning organisation can refetch
them. That is not asserted either: the script probes
`https://raw.githubusercontent.com/smorinlabs/ts-launch-blueprint/cb1cbcb2…/<path>`
anonymously and requires **HTTP 404**, which is what makes "no public remote" a
checked fact. For those two files the committed snapshot is the evidence of
record. Everything else re-derived exactly: the standard from a commit-addressed
`raw.githubusercontent.com` URL, the two `clap` sources from crates.io tarballs
whose checksums crates.io itself records, the two Python sources from a
commit-addressed URL, and the two decision texts from this repository's own git
objects.

Sections 01–12 above remain **not** claimed as reproducible, for the unchanged
reason: they queried live counters.

**Revision-4 one-off check — does Cargo actually reject a leading `v`?** F267's
JSON object claims R4.6's `version` `MUST` (SemVer, no leading `v`) is satisfied
structurally, so the premise is checked rather than asserted. **This is one
command run by hand; it is deliberately not part of the three scripts and is
counted in none of their totals**, because it needs a toolchain rather than a
committed file and would make an offline rerun of those scripts impossible.
Toolchain `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4
`aarch64`. Working directory a scratch directory outside this repository holding
a two-file throwaway package — `Cargo.toml` and an empty `src/lib.rs` — created
only as input to the parse, exactly as the revision-1 run's resolution manifests
were. **Nothing was written into this repository or this run directory, and
nothing recommended here was implemented.** With `version = "v0.1.0"`,
`cargo metadata --format-version 1 --no-deps` exits **101** and prints:

```
error: unexpected character 'v' while parsing major version number
 --> Cargo.toml:3:11
  |
3 | version = "v0.1.0"
  |           ^^^^^^^^
```

With `version = "0.1.0"` and nothing else changed, the same command exits **0**.
The pair is the evidence: the failure is caused by the leading `v` and by
nothing else about the manifest. So a `CARGO_PKG_VERSION` carrying a leading
`v` cannot arise from a manifest Cargo accepted.

**Revision-4 run — the clap version-flag mechanism, the standard's R4.6 text,
and the R66 coupling.** Revision 4 changes F267's mechanism on an owner ruling,
and three of its load-bearing claims are new: that `ArgAction::Version`
terminates the parse, that `render_version()` and `disable_version_flag` give
the conformant line and the escape from that termination, and that R66 owns no
registry parameter. Each is checked, and the revision-3 apparatus is extended
rather than replaced — same harness, same negative controls, same
committed-input rule.

| Script | Log | Result |
|---|---|---|
| `r60-standard-pin-r4.sh` | `r60-standard-pin-r4.log` | exit `0`, `CHECKS RUN: 115   FAILURES: 0` — revision 3's 73 checks plus the eight R4.6 range checks, the `ArgAction::Version` short-circuit, the four `clap_builder` version APIs and the derive forwarding of `disable_version_flag`, and the R66 `- owns:`/registry checks |
| `r60-preservation-diff-r4.sh` | `r60-preservation-diff-r4.log` | exit `0`, `CHECKS RUN: 104   FAILURES: 0` — revision 3's preservation targets against r1 and r2, plus r3 as a third baseline, plus the 34 inverted override and waiver assertions this ruling requires |
| `r60-snapshot-provenance-r4.sh` | `r60-snapshot-provenance-r4.log` | exit `0`, `CHECKS RUN: 17   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 2` — every snapshot re-derived from its pinned source, now including the `parser.rs` snapshot and the revision-3 decision baseline |

**Two snapshots were added and `snapshots/MANIFEST.txt` grew from 10 rows to
12.** `clap_builder-4.6.6-src-parser-parser.rs.txt` is the file carrying
`ArgAction::Version`'s match arm, taken from the same `clap_builder-4.6.6.crate`
tarball whose crates.io checksum the MANIFEST already records; adding it means
the short-circuit claim rests on a hash-verified committed file rather than on a
line number remembered from the revision-1 run. `r60-decision-r3.md` is the
approved revision-3 text, sha256
`14f66259aad6063f9506410735e61e9a58a026fc24200cb048b9bbc71bbc2100` — the value
`review/audit-codex.md` itself names — taken from commit
`d642814cddfd3f1756fc56cd38738904440d9141`, the commit that audit archived.

**Revision-5 run — the owner's ruling, now read out of this repository instead
of asserted.** Revision 5 implements the revision-4 audit's finding F1 and
nothing else. The claim that moved is a provenance claim: revision 4 said the
owner's ruling of 2026-09-14 was recorded in no file here, and by the time it was
audited the programme controller had written it into
`docs/port/OWNER-REVIEW.md:72-91`. Two of the three scripts are therefore
reissued under r5 names; the third is unchanged and stays at r4.

| Script | Log | Result |
|---|---|---|
| `r60-standard-pin-r5.sh` | `r60-standard-pin-r5.log` | exit `0`, `CHECKS RUN: 128   FAILURES: 0` — revision 4's 115 checks with `C16h`/`C16i` **inverted** into `C16h`–`C16o2`, which assert the owner record's presence clause by clause, plus the `C-grep` binary-identity check |
| `r60-preservation-diff-r5.sh` | `r60-preservation-diff-r5.log` | exit `0`, `CHECKS RUN: 133   FAILURES: 0` — revision 4's 104 checks, plus the rejected revision-4 text as a fourth baseline (`C1m`–`C1q`), the 13 `C4k` checks of the repair itself, the `C9` r4→r5 diff, six more `C5c` evidence files and `C-grep` |
| `r60-snapshot-provenance-r4.sh` | `r60-snapshot-provenance-r4.log` | **unchanged and still live evidence**: exit `0`, `CHECKS RUN: 17   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 2`, and the rerun for this revision **diffed empty** against the committed log. No snapshot moved and `snapshots/MANIFEST.txt` is untouched, so there is nothing for an r5 successor to change |

**The middle row of that table is false as an in-place claim, and revision 6
corrects it here rather than rewriting it.** The row is kept because it is the
record the revision-5 audit judged. What it says of the clean `git archive`
extraction is true and the auditor confirmed it: from an archive, which contains
only the tracked canonical report, `r60-preservation-diff-r5.sh` exits `0` with
`CHECKS RUN: 133   FAILURES: 0`. What it says **in place** is not. Two in-place
observations, both of them the same defect:

- **At audit time**, an untracked byte-for-byte copy of the revision-4 report,
  `review/audit-codex.r4.md`, sat beside the canonical `review/audit-codex.md`.
  `C1o` searched the directory, found two files carrying the revision-4 hash,
  failed its one-report assertion, and the run **exited `1` with 133 checks and
  one failure**. That is finding F2.
- **On 2026-09-15**, with the revision-4 report archived under its round name and
  the revision-5 report at the canonical one, the count is `1` again and the run
  exits `0` with 133 checks and no failures — but **the printed basename changed
  from `audit-codex.md` to `audit-codex.r4.md`**, so the output differs from the
  committed `r60-preservation-diff-r5.log` on that one line. The log still does
  not reproduce in place.

So the honest statement of the revision-5 preservation result is: reproducible
from a clean extraction, **not** reproducible in place, for a reason that is the
script's and not the tree's. `r60-preservation-diff-r6.sh` replaces it as this
decision's preservation evidence and its own results are the **Revision-6 run**
table below.

**A fourth decision baseline was committed, and deliberately not as a
`snapshots/` row.** `review/evidence/r60-decision-r4-baseline.md` is the
rejected revision-4 text, sha256
`12aaf65c88f6bbcde915723913257f78d2e2e483c6deac4ee808b41af122ef43` — the value
`review/audit-codex.md` itself names — so that `C9` can enumerate the r4→r5 diff,
which is the delta an auditor of revision 5 has to review. It is **not** added to
`snapshots/MANIFEST.txt`, because a new MANIFEST row would change
`r60-snapshot-provenance-r4.sh`'s recorded totals and force a fourth script
revision for a file nothing else about this revision touches. It is anchored the
way the revision-3 baseline is anchored instead: located by the sha256 its own
audit report names rather than by a file name (`C1m`–`C1q`, which also assert
that report's `verdict: reject`, its `F1`, and its revision-4 actor).

**That last sentence describes the defect finding F2 rejected, and revision 6
reverses the reasoning rather than deleting the paragraph.** "Located by the
sha256 its own audit report names rather than by a file name" means *searched
for in a directory*, which is precisely what let an untracked duplicate decide
the result. The baseline files are still anchored by hash — that part was never
the problem, because a hash pins bytes — but the **reports** are now named:
`review/audit-codex.r3.md`, `review/audit-codex.r4.md` and, for the current
round, `review/audit-codex.md`, each asserted against its own
`decision-sha256:`, `actor:` and `verdict:` lines in
`r60-preservation-diff-r6.sh`.

**How the two checks were inverted, and why they are anchored rather than
counted.** Revision 4's `C16h` and `C16i` asserted `OV-01` **count 0** and
`2026-09-14` **count 0** over the whole of `docs/port/OWNER-REVIEW.md`. Revision
5's assert the opposite fact, but not as a file-wide count: the ruling's own
section is located by its heading
(`### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused`),
extracted with `sed`, and each clause this decision relies on is asserted
**inside that extraction** — the 1.4.14/`f9de0437` pin, `Override OV-01 is
REFUSED`, the selection of option (b), `the template waives no SHOULD`, and
`R60 carries zero overrides`. `C16m` is the control that keeps the extraction
honest: a string belonging to the *2026-09-12* licence section of the same file
must be absent from the extraction, so an extraction that silently widened to
the whole file fails. `C16n`–`C16n4` do the same for
`docs/planning/p02/owner-decisions.md`, whose `## 9.` heading appears twice — the
original ask and the `-- ANSWERED 2026-09-14` disposition — so the answered one
is named in full. **A file-wide count would have been the same mistake in
mirror image**, and this is not hypothetical: between the revision-4 audit and
this revision the same file gained a further section (`## Wave 0 owner
acceptances`), moving its `2026-09-14` count from the **1** the auditor observed
to **3**. Those raw counts are therefore neither asserted nor printed in the r5
log. For the same reason `C16o` counts R60's dispositions row inside the
extracted `## Dispositions` section rather than file-wide.

**The revision-4 standard-pin and preservation scripts are retained, are no
longer this revision's evidence, and their failure against this text is
recorded rather than predicted.** Both were rerun against the revision-5 tree,
in place and again from the same `git archive` extraction, with identical
results in both places:

- `bash review/evidence/r60-standard-pin-r4.sh` → **exit 2**,
  `CHECKS RUN: 115   FAILURES: 2`, failing exactly `C16h` (`wanted count=0`, `got
  count=3`) and `C16i` (`wanted count=0`, `got count=3`). That is the
  revision-4 audit's finding F1 reproduced here, with `2026-09-14` now at 3
  rather than the 1 the auditor saw, for the reason given above.
- `bash review/evidence/r60-preservation-diff-r4.sh` → **exit 1**,
  `CHECKS RUN: 104   FAILURES: 1`, failing exactly `C4h`, which requires the
  title to read revision 4. **Every other check in it passes** — all 23
  preservation targets, the whole 34-check `C4f` inversion family, `C4g` and its
  positive control, the structural checks and the gate rows. That single
  failure is itself the scope evidence for this revision: nothing revision 5
  changed touches anything revision 4's script pins except the title.

Both are left **byte-identical**: they are the artifacts the revision-4 audit
ran, and `review/audit-codex.md` cites them by name. The revision-3 scripts are
retained on the same footing, as the revision-2 pair is before them. **No row
below cites a revision-3 or revision-4 script for a revision-5 claim**, with one
deliberate exception that is not a revision-4 claim at all:
`r60-snapshot-provenance-r4.sh` is unchanged, reruns byte-identical, and is
cited by row E10 as this revision's live provenance evidence. **Revision 6 adds
the revision-5 preservation script to that retained set** and keeps the same
rule: `r60-preservation-diff-r5.sh` is superseded by
`r60-preservation-diff-r6.sh` and no row cites it for a revision-6 claim, while
`r60-standard-pin-r5.sh` — untouched by finding F2, which is a property of the
preservation script's report lookup alone — stays live and is cited by rows E1
through E8 and E11 through E13.

**The same two reproducibility claims, re-demonstrated rather than inherited.**
`r60-standard-pin-r5.sh` and `r60-preservation-diff-r5.sh` read only files
committed in this repository and make no network call; both were rerun against a
`git archive` extraction of the exact tree this revision commits — an empty
directory with no `.git` and no working-tree state — and `diff` against the two
logs cited here reported no difference.

**That sentence was true of `r60-standard-pin-r5.sh` and false of
`r60-preservation-diff-r5.sh`, and it is the sentence finding F2 falsified.** It
is kept here as the record and corrected immediately, per this document's
practice for a superseded claim. The archive half holds for both scripts: the
auditor reran both from a clean `git archive HEAD` extraction and both diffed
empty. The "reads only files committed in this repository" half does not hold for
the preservation script, because `C1i` and `C1o` read the run's `review/`
**directory** rather than named files, and a directory in this shared worktree
carries whatever anyone has put in it, tracked or not. The consequences, with
their observed numbers, are recorded above under the revision-5 results table.
`r60-preservation-diff-r6.sh` restores the claim by naming every file it reads;
its two-mode results are the **Revision-6 run** table below. `r60-snapshot-provenance-r4.sh` carries
the identical two conditions revision 3 recorded: byte-for-byte only while the
network is reachable **and** the checkout carries git history. **The exact
variance outside the second condition, observed rather than predicted**, from the
same `git archive` extraction: the three `self` rows — the revision-1, revision-2
and revision-3 baselines, which are checked against this repository's own git
objects — report `UNVERIFIABLE-HERE`, and the totals read
`CHECKS RUN: 14 … UNVERIFIABLE-HERE: 5` rather than `17 … 2`. **That is the only
difference**; every other line is byte-identical, including the network-dependent
ones. Revision 3 recorded the same variance with its own numbers
(`12 … 4` against `14 … 2`, two `self` rows rather than three), so the behavior
is unchanged and only the counts moved with the MANIFEST.

**One input this revision reads that it does not own, stated so the limit is
visible.** `C16h`–`C16n4` read `docs/port/OWNER-REVIEW.md` and
`docs/planning/p02/owner-decisions.md`, which the programme controller writes and
this item may not edit. A `git archive` rerun freezes them with everything else,
so the archive rerun is byte-identical; an *in-place* rerun months later would
legitimately fail if the controller reworded the ruling, and that failure would
be information rather than noise — it is the same class of live-source check as
row E10's "is the pin still the newest commit". Nothing in the r5 log records a
number read out of either file, precisely so that an unrelated edit to them
cannot change this log.

**Revision-6 run — the report lookup named rather than searched.** Revision 6
implements the revision-5 audit's finding F2 and nothing else. One script is
reissued; the other two are unchanged and were rerun in both modes for this
revision rather than inherited.

| Script | Log | Result |
|---|---|---|
| `r60-preservation-diff-r6.sh` | `r60-preservation-diff-r6.log` | exit `0`, `CHECKS RUN: 159   FAILURES: 0` — revision 5's 133 checks with `C1i`/`C1i2` and `C1o`/`C1o2` **rewritten to name their report file and assert its `decision-sha256:`**, plus `C1r`/`C1r0` forbidding a directory search from returning, plus the rejected revision-5 text as a fifth baseline (`C1s`–`C1v`), the 11 `C4m` checks of the repair itself, the `C10` r5→r6 diff and two more `C5c` evidence files |
| `r60-standard-pin-r5.sh` | `r60-standard-pin-r5.log` | **unchanged and still live evidence**: exit `0`, `CHECKS RUN: 128   FAILURES: 0`, and the rerun for this revision **diffed empty against the committed log in both modes** — in place and from a clean `git archive` extraction. It names no audit report and reads no directory, so F2 does not reach it |
| `r60-snapshot-provenance-r4.sh` | `r60-snapshot-provenance-r4.log` | **unchanged and still live evidence**: exit `0`, `CHECKS RUN: 17   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 2` in place, diffing empty against the committed log; from the clean extraction it carries its two documented conditions and reads `CHECKS RUN: 14   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 5`, unchanged from revision 5 |

**A fifth decision baseline was committed, on the fourth's footing.**
`review/evidence/r60-decision-r5-baseline.md` is the rejected revision-5 text,
sha256 `2a665e73f5a5d93794fe49520615e204be294d156f1d537b7bafe1421c042c06` — the
value `review/audit-codex.md` itself names — so that `C10` can enumerate the
r5→r6 diff, which is the delta an auditor of revision 6 has to review. Like the
fourth baseline it is **not** added to `snapshots/MANIFEST.txt`, because a new
MANIFEST row would change `r60-snapshot-provenance-r4.sh`'s recorded totals and
force a revision of a script this revision does not otherwise touch. Its hash is
asserted directly (`C1s2`), and the report that bound that hash is read at its
named path `review/audit-codex.md` with its `decision-sha256:`, `verdict:`,
`unresolved-findings:` and `actor:` lines all asserted (`C1t`–`C1v`).

**How the lookup was rewritten, and what `C1r` adds.** Revision 5 asked *which
file in this directory carries hash H?* and required the answer to be one file.
Revision 6 asks *does the file at path P carry hash H, and was it written by
round N's auditor with verdict V?* The first question's answer depends on
everything else in the directory; the second's depends only on the named file's
bytes. Four report paths are now named — `review/audit-codex.r1.md`,
`.r2.md`, `.r3.md`, `.r4.md`, all archived under their round names and stable —
plus `review/audit-codex.md` for the current round. `C1r` then asserts that no
executable line of the script contains a wildcard over those names at all, so the
defect cannot return silently; `C1r0` is its positive control, requiring the
pattern to be found somewhere in the file — it occurs in the quotation of F2 in
the script's own header — so a search that had stopped working could not satisfy
`C1r` by finding nothing. **Both were validated by making them fire**: a wildcard
placed on an executable line of a throwaway copy took `C1r` to `FAIL` with
`count=1`, and the copy was discarded.

**That last paragraph describes the state finding F3 rejected, and revision 7
corrects it here rather than deleting it.** Naming
`review/audit-codex.md` "for the current round" is what left revision 6 asserting
a file whose bytes the next auditor writes. Revision 7 keeps the four archived
paths, adds the fifth — `review/audit-codex.r5.md`, where the controller archived
the round-5 report when the round-6 audit opened — and removes the live path from
the script entirely, so `C1t`–`C1v` now read an archived round and can no longer
move. `C1r` and `C1r0` are carried forward unchanged, and `C1x`/`C1x0` are the
new pair that forbids the live path itself. **Both new checks were validated by
making them fire**: the revision-6 assignment
`R5REPORT="$RUN_DIR/review/audit-codex.md"` pasted onto an executable line of a
throwaway copy took `C1x` to `FAIL` with `count=1`, and deleting every occurrence
of the pattern from that copy took `C1x0` to `FAIL` with `live=no`; the copy was
discarded.

**The revision-5 preservation script's failure against this text is recorded
rather than predicted.** `bash review/evidence/r60-preservation-diff-r5.sh` run
against the revision-6 tree → **exit 1**, `CHECKS RUN: 133   FAILURES: 1`,
failing exactly `C4h`, which requires the title to read revision 5. Every other
check in it passes, which is this revision's scope evidence: nothing revision 6
changed touches anything that script pins except the title. Its log still differs
in place on the one printed report name, for the reason recorded above — that is
the defect, still visible in the artifact that carries it. `r60-standard-pin-r4.sh`
and `r60-preservation-diff-r4.sh` were not rerun for this revision and their
recorded revision-5 results stand; they are superseded twice over.

**Revision-7 run — the reports asserted are archived rounds only.** Revision 7
implements the revision-6 audit's finding F3 and nothing else. One script is
reissued; the other two are unchanged and were rerun in both modes for this
revision rather than inherited.

| Script | Log | Result |
|---|---|---|
| `r60-preservation-diff-r7.sh` | `r60-preservation-diff-r7.log` | exit `0`, `CHECKS RUN: 183   FAILURES: 0` — revision 6's 159 checks with the `C1t`–`C1v` family **moved onto the archived `review/audit-codex.r5.md`**, plus `C1x`/`C1x0` forbidding the live report path on any executable line, plus the rejected revision-6 text as a sixth baseline (`C1w`, `C1w2`), the 13 `C4n` checks of the repair itself, the `C11` r6→r7 diff and four more `C5c` evidence files |
| `r60-standard-pin-r5.sh` | `r60-standard-pin-r5.log` | **unchanged and still live evidence**: exit `0`, `CHECKS RUN: 128   FAILURES: 0`, and the rerun for this revision **diffed empty against the committed log in both modes** — in place and from a clean `git archive` extraction. It names no audit report at all, so neither F2 nor F3 reaches it |
| `r60-snapshot-provenance-r4.sh` | `r60-snapshot-provenance-r4.log` | **unchanged and still live evidence**: exit `0`, `CHECKS RUN: 17   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 2` in place, diffing empty against the committed log; from the clean extraction it carries its two documented conditions and reads `CHECKS RUN: 14   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 5`, unchanged from revisions 5 and 6 |

**A sixth decision baseline was committed, on the fifth's footing.**
`review/evidence/r60-decision-r6-baseline.md` is the rejected revision-6 text,
sha256 `89d888fb3a649ed7a99c895e4bc279a1afcc61438c3c41b6db8a966b6459db38` — the
value the round-6 report itself names — so that `C11` can enumerate the r6→r7
diff, which is the delta an auditor of revision 7 has to review. Like the fourth
and fifth baselines it is **not** added to `snapshots/MANIFEST.txt`, because a new
MANIFEST row would change `r60-snapshot-provenance-r4.sh`'s recorded totals and
force a revision of a script this revision does not otherwise touch. **Unlike
them it is anchored by its hash alone** (`C1w2`), with no accompanying assertion
about the report that named that hash: that report is the live
`review/audit-codex.md`, and asserting it is finding F3.

**One line of the new script is not about finding F3, and is reported here
rather than left to be noticed.** This repository gained a pre-commit hook on
2026-09-15 that runs `shellcheck` over every staged `.sh` file and fails on any
finding, info level included. This script's expectation strings are markdown
quoted out of this decision, so they contain backticks, and single-quoting them
is what keeps them literal; `shellcheck` reads those backticks as unexpanded
command substitutions and reports `SC2016` fourteen times. The rule is
suppressed file-wide with one `# shellcheck disable=SC2016` directive rather
than by rewriting the strings, because rewriting an expectation changes what the
script asserts. The directive is a comment: the run is byte-identical with and
without it, which was checked by diffing the log across the change.

**The revision-6 preservation script's failure against this text is recorded
rather than predicted, and it is recorded twice because the two runs differ.**
Against the revision-6 text, with the round-6 report landed, it exited `4`, as
set out in the revision note above. Against **this** text —
`bash review/evidence/r60-preservation-diff-r6.sh` run on the revision-7 tree →
**exit 5**, `CHECKS RUN: 159   FAILURES: 5`, failing `C1t2`, `C1u2`, `C1u3` and
`C1v` on the replaced report plus `C4h`, which requires the title to read
revision 6. Every other check in it passes, which is this revision's scope
evidence: nothing revision 7 changed touches anything that script pins except the
title and the report path. The two counts agree with neither the r6 prediction
(four) nor the auditor's measurement (five, a different set), which is the whole
of finding F3 in one line. `r60-preservation-diff-r5.sh` and the revision-4 pair
were not rerun for this revision; their recorded results stand and they are
superseded again.

| Row | What it checks | Command | Result |
|---|---|---|---|
| E1 | that the text every `:<line>` citation resolves against is the pinned revision (`C1`, `C2` of `r60-standard-pin-r5.sh`) | verify each snapshot's sha256 against `snapshots/MANIFEST.txt`, then hash `snapshots/cli-design-standard-1.4.14.md` | all 10 snapshots match their recorded hashes, MANIFEST records exactly the files present and no others, and the standard snapshot's sha256 is `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f` — **the sha256 of blob `f9de0437…` at commit `fb30a591…`**, which is how the committed text and the pinned blob are established to be the same bytes without needing a clone of the standards repository. The snapshot is 773 lines, asserted, so an out-of-range `:<line>` citation cannot pass silently. Its recorded origin is the commit-addressed URL `raw.githubusercontent.com/smorinlabs/cli-standards/fb30a591…/cli-design-standard.md`. That the pin is still the *newest* published commit is a live-history claim and is row E10 |
| E2 | the document declares version 1.4.14 (`C3`) | `sed -n '1,12p'` on the pinned text | `| **Version** | 1.4.14 |`, `| **Status** | Active — canonical |`, `| **Last updated** | 2026-06-28 |` |
| E3 | R1.3's full text, the rule revision 2 repaired the decision against (`C4`) | the same pinned text, `sed -n '133,137p'` | `**R1.3 — Noun number. (MUST)**`; "Resource nouns **MUST** be **singular** in their canonical form"; "The plural form **MAY** be accepted as an undocumented alias but **MUST NOT** appear in help or docs"; "`list` returning many is not a reason to pluralize"; and the ❌ example "documenting `acme widgets list` as the primary form" |
| E4 | R1.3 is org-locked, and the Decision Log line numbers (`C5`, `C6`) | the same pinned text, `sed -n '61p;63p;65p;67p;69p;70p'` | row 5 `| 5 | Noun number | Singular canonical; plural accepted as undocumented alias |` is at **`:67`**, marked `org-locked`; the table header is at `:61` and row *N* at line 62 + *N*, so row 1 is `:63`, row 3 `:65`, row 7 `:69`, and **`:70` is row 8, Exit codes** — R67's row. **This corrected three citations**: revision 1 cited `:70` for rows 1, 3 and 7, having copied R67's line for its own row 8 |
| E5 | every other standard line this decision cites (`C7`–`C9`) | the same pinned text, one `sed -n '<n>p'` per citation | all resolve: `:50` the SHOULD-waiver clause, `:124` R1.1, `:129` R1.2, `:146` R1.6, `:229` R3.10, `:270` R4.5, `:275` R4.6's heading, `:321` R5.4, `:579` Appendix A criterion 1, `:586` the noun-verb counter-example; R1.3 is cross-referenced by R2.2 at `:177` and by the Appendix C checklist at `:635` ("R1.3 singular nouns"). **Revision 4 adds the eight checks that fix R4.6's range (`C8b`)**, because option (b) rests on R4.6's body rather than on its heading: `:276` is the rule itself and carries every clause this decision cites from it — the single-line `SHOULD`, the "`--version` **MAY** honor `-o json`/`--output json`" permission, the "**SHOULD** emit an object such as" shape, the "`version` **MUST** be SemVer without a leading `v`" requirement and the "`commit` and `built` **MAY** be omitted or `null`" allowance; `:277` is the ✅/❌ worked example carrying `acme --version -o json`; `:278` is **blank**, asserted as blank rather than merely left unquoted; and `:279` is R4.7's heading. So R4.6 spans `:275-277`, and the `:275-279` and `:277-279` ranges revisions 1 through 3 used overran it by exactly those two lines |
| E6 | whether R67 pinned the standard (`C13`) | `grep` over the published R67 topic's `DECISION.md` and its 18 evidence logs, reached by a path relative to the script | **R67's body: no pin** — zero citations carrying a version, commit, blob or hash, across its two citations of the file (`:78`, `:464`), and zero occurrences of `1.4.14`. **R67's audit trail: the version, but not a pin** — its revision-4 audit log records at `:6` "Standard read: `…/cli-design-standard.md`, version 1.4.14"; the only other mention among the evidence logs is one quoted line of the standard's own changelog. Asserted as labelled counts (`count=0`, `count=2`, `count=2`, `count=1`), so an absence cannot be confused with a failed search and a two-digit count cannot satisfy a one-digit expectation. The presence of R67's decision file is itself asserted first, so a moved file would fail rather than read as four zeroes |
| E7 | that both source ports document the plural noun (`C10`) | read the four committed port snapshots, taken through each port's pin | py `cli/commands/projects.py:37` is `@click.group(name="projects", cls=SuggestingGroup)`; py `cli/commands/__init__.py` is `COMMAND_GROUPS = [projects_group, config_group]`; ts `src/commands/projects.ts:70` is `.command('projects', { isDefault: true })`, looked up by that name at ts `src/router.ts:234`. This is the recorded practice R1.3 overrides |
| E8 | the clap 4.6.6 APIs AC9/AC10 name (`C11`, `C12`) | read `snapshots/clap_builder-4.6.6-src-builder-command.rs.txt` and the two `clap_derive-4.6.4` snapshots, each hash-verified against MANIFEST, which records the tarball each came from and that tarball's checksum | the `clap_builder` snapshot's recorded origin is `clap_builder-4.6.6.crate`, sha256 `7b48fea5a88e9ae728a2dcbedbfc0e730f7d60da42e1cb049a83c9fb8b789889` — **the checksum crates.io records for 4.6.6** (`GET /api/v1/crates/clap_builder/4.6.6`, retrieved 2026-09-12 and re-retrieved 2026-09-13; the same response gives `rust_version: 1.85`). All eight methods exist on `Command` at the cited lines: `get_subcommands` `:3932`, `get_name` `:3756`, `is_hide_set` `:4242`, `render_long_help` `:1037`, `get_visible_aliases` `:3847`, `get_all_aliases` `:3874`, `alias` `:2691`, `visible_alias` `:2893`. And the behavioral half: `alias`'s own doc says "Aliases defined with this method are *hidden* from the help message" (`:2664-2666`) while `visible_alias`'s says its alias "is *visible* from the help message" (`:2865-2868`) — which is what makes `#[command(alias = …)]` the R1.3-conformant spelling and `visible_alias` a violation. **The derive forwarding is verified too** (`C12`), since the R1.3 repair rests on it: `clap_derive-4.6.4` (tarball sha256 `d012d2b9d65aca7f18f4d9878a045bc17899bba951561ba5ec3c2ba1eed9a061`, likewise the checksum crates.io records) has no `MagicAttrName::Alias` variant and no mention of `alias` in `src/attr.rs`, so the name falls to the generic branch `_ => self.methods.push(Method::new(name, arg))` (`src/item.rs:337-345`) and a `Method` renders as `quote!( .#name(#args) )` (`:1281-1289`) — emitting `.alias("projects")`, the hidden method |
| E9 | that this revision preserved what the approved revision 3 established, and that the owner's ruling is implemented rather than asserted (`review/evidence/r60-preservation-diff-r7.sh`, log `review/evidence/r60-preservation-diff-r7.log`; its `C0`–`C11`) | confirm the committed revision-1 through revision-5 texts hash to the values the five audit reports themselves name — **each report read at a named path, and every one of those paths an archived round**, which is finding F2's repair carried through finding F3's: `review/audit-codex.r1.md` through `.r5.md`, each asserted against its own `decision-sha256:`, `verdict:` and `actor:` lines, with `C1r` asserting that no executable line of the script contains a wildcard over those names and `C1x` that none contains the live `/review/audit-codex.md` path either — and that the revision-3 report's `verdict:` is `approve` with `unresolved-findings: none`, the revision-4 report's is `reject` naming `F1` and `docs/port/OWNER-REVIEW.md`, and the revision-5 report's is `reject` naming `F2` and `r60-preservation-diff-r5.sh`; for each preserved claim, require every baseline line carrying it to still be present verbatim; assert the inverted override and waiver state the ruling produces; re-read the four `assumes` values out of `docs/port/PARAMETERS.md`; `find` the run directory for Rust or Cargo artifacts; enumerate every differing line against all four baselines | **exit 0**, `CHECKS RUN: 183 FAILURES: 0`. **Preservation:** the 20 revision-1 targets and the 3 revision-2 targets are all still verbatim — the `clap 4.6.6` pin and its four features, the `clap_complete 4.6.9` pin, `strsim 0.11.1` transitive-only, the dependency-free `build.rs`, `clap_complete`'s `default = []` and its `clap >= 4.5.20` floor, "Locking 28 packages to latest Rust 1.96 compatible versions", the `cargo generate-lockfile`/`cargo tree` row, the `cargo audit` **exit 0** row with its 1,243 advisories and 29 dependencies, all four `assumes` lines, **OV-01's R4.6 quotation, its option (b) and option (c) rows and its owner-ruling sentence**, architectures A and E, the `clap` fitness-gate data row, the `casey/just` composition evidence, the 2026-09-12 status line, R1.3's rule text and the standard-pin content-hash row. That OV-01's argument and options survive its retirement byte-for-byte is the point, not an accident: the owner chose from exactly that table. **The inversion**, the 34 checks of the `C4f` family (`C4f` through `C4f29`; the count exceeds the labels because `C4f28` is a loop over the six fitness gates): the refusal is recorded and dated `REFUSED 2026-09-14`; option (b) is named as what the owner selected; OV-01 carries the `RETIRED OVERRIDE` label; the decision declares **zero overrides** and states that no `SHOULD` is waived; the 2026-09-12 record is labelled as superseded; the F267 row drops `Command::long_version` and names the JSON path at `:276-277`; AC2 asserts byte-identity and the no-leading-`v` `MUST`; AC3 asserts the JSON object with `commit` and `built` absent; AC7 records that `--version` returns through `Ok`; the R66 note is `related (not a registry dependency)` with the reason; **there are zero `CONFLICT:` lines**; the fired OV-01 `re-verify` trigger is marked removed and the R66 one added; and all six fitness gates appear in the closing enumeration. **C4g survives the inversion** — a refusal is not a grant, so eight affirmative grant phrasings must still be absent, and revision 4 both scans sentence-wise instead of line-wise (this prose is hard-wrapped, so a line-scoped scan could see `waiver was granted` while its `whether` sat on the previous line) and adds `C4g2`, a positive control running the same patterns over synthetic text that does claim a grant, which must fire. Structurally: four H2 sections in the required order, no `## Supersedes`, no second override declared, the title recording revision 7, and gate 1 recorded as `inapplicable` with the ruling as its reason while the gate's row is kept in the table rather than removed. `find` reports zero `.rs`, `Cargo.toml` or `Cargo.lock` files and zero `src/` or `target/` directories anywhere in this run directory, and each of the eighteen evidence files this decision cites is asserted present. **Revision 5's own repair is the 13 checks of the `C4k` family**: finding F1 is quoted rather than paraphrased; both durable records are cited by path-and-line-range *and* by section heading, so a citation survives a line shift; the two sentences the audit named are **still present verbatim**, each with its correction beside it, because a superseded record is corrected in place here rather than deleted; U8 is re-labelled `RESOLVED` and kept; and the note states that the owner's ruling is not re-opened. **Revision 6's own repair is the 11 checks of the `C4m` family**: finding F2 is quoted rather than paraphrased; the repaired script is named; the rejected one is recorded as kept byte-identical; **both** in-place observations are recorded with their numbers — the auditor's exit `1` with 133 checks and one failure, and the moved printed basename seen on 2026-09-15; the two sentences the finding falsified, the revision-5 results row and the "read only files committed in this repository" claim, are **kept verbatim** with their corrections beside them rather than deleted; the beyond-brief correction that `C1i` carried the same defect is reported; and the new lookup's own cost — that `C1t2`, `C1u2`, `C1u3` and `C1v` will fail once the round-6 audit lands and `review/audit-codex.md` binds revision 6's hash instead — is stated rather than left to be found; that last sentence is the one finding F3 falsified, and `C4m10` now asserts it as the kept superseded record rather than as a current prediction. **Revision 7's own repair is the 13 checks of the `C4n` family**: finding F3 is quoted rather than paraphrased; the defect is recorded as structural and as the third round of the same mistake; the new invariance property is stated — archived reports only, the live path nowhere; **both** post-landing measurements are recorded with their numbers and with what produced each, the auditor's `5` against a `verdict: approve` draft and this revision's `4` against the `verdict: reject` report that landed; the falsified sentence is kept verbatim with its correction beside it; and what the new script deliberately does not assert — the round-6 report itself, which existed only at the live path when the script was written — is stated rather than left to be found. All six diffs are enumerated in full in the log; **their line counts are deliberately not quoted here, because quoting a count of the decision's own changed lines would change it** |
| E10 | that every committed snapshot really is what MANIFEST.txt says, and that the pin is still the newest published commit (`review/evidence/r60-snapshot-provenance-r4.sh`, log `review/evidence/r60-snapshot-provenance-r4.log`; its `C1`, `C2`) | re-download each pinned source and re-derive the snapshot's sha256 from it; for a crate, verify the tarball against the checksum crates.io records before extracting; for a private origin, probe anonymously and require HTTP 404; then `GET https://api.github.com/repos/smorinlabs/cli-standards/commits?path=cli-design-standard.md&per_page=1` | **exit 0**, `CHECKS RUN: 17 FAILURES: 0 UNREACHABLE: 0 UNVERIFIABLE-HERE: 2` — three checks more than revision 3's 14, which is the two MANIFEST rows revision 4 added (`parser.rs` contributes both a tarball-checksum and an extracted-file check; `r60-decision-r3.md` contributes one git-object check). The standard re-fetched from its commit-addressed URL hashes to `9fb05d3d…`; both `clap` tarballs hash to the checksums crates.io records and **all four** extracted files hash to their snapshots; both Python sources re-fetched from their commit-addressed URLs match; **all three** decision baselines match this repository's own git objects, including revision 3 at commit `d642814cddfd3f1756fc56cd38738904440d9141`. The newest published commit touching `cli-design-standard.md` is still `fb30a591c267a7ec1130ba4cda679eaee494b9d7` — this is the live half of the `re-verify` trigger, and it is the check that will fail first when the standard moves. The 2 `UNVERIFIABLE-HERE` entries are unchanged: the two TypeScript snapshots, whose repository `smorinlabs/ts-launch-blueprint` returns **HTTP 404** to an anonymous request, which the script asserts rather than assumes |
| E11 | **that `ArgAction::Version` terminates the parse** — the one new mechanical fact behind F267's move to option (b) (`C14` of `r60-standard-pin-r5.sh`) | read `snapshots/clap_builder-4.6.6-src-parser-parser.rs.txt`, hash-verified against MANIFEST, which records the tarball it came from and that tarball's crates.io checksum; `sed -n '1322,1331p'` | the arm at `parser.rs:1322` computes `use_long` from the identifier — `Some(Identifier::Long) => true`, `Some(Identifier::Short) => false` — and then **returns `Err(self.version_err(use_long))`**. Asserted in both directions: the arm contains no `Ok(` continuation (`count=0`), so it cannot fall through to a later argument, and — the control that keeps that zero from being vacuous — the immediately preceding arms *do* return `Ok(ParseResult::…)`, which the same search finds. So `<tool> --version <format-flag> json` is unreachable through clap's built-in version flag: the parse ends at `--version`, and `version_err` renders from the `Command::version`/`long_version` strings, which no parsed value reaches. **This is why option (b) costs more than an AC2/AC3 rewrite** |
| E12 | that the four `clap 4.6.6` APIs F267's decided mechanism names exist and behave as described, and that the derive spelling reaches one of them (`C15` of `r60-standard-pin-r5.sh`) | read `snapshots/clap_builder-4.6.6-src-builder-command.rs.txt`, the same hash-verified snapshot row E8 uses (origin `clap_builder-4.6.6.crate`, sha256 `7b48fea5…`, the checksum crates.io records) | `Command::render_version` `:1097`, `disable_version_flag` `:1493`, `version` `:2119`, `long_version` `:2151` all exist at those lines. Behaviorally: `render_version()` is `self._render_version(false)` — the **short**, single-line form — and `_render_version`'s `false` branch reads `self.version` first and ends `format!("{display_name} {ver}\n")` (`:4906-4913`), which is R4.6's GNU name-and-version shape; `disable_version_flag` documents itself as disabling **both** `-V` and `--version` (`:1448`) and its own doctest asserts `--version` then yields `ErrorKind::UnknownArgument` (`:1455-1463`). The trap is asserted too: clap's documented custom-flag recipe re-declares the flag with `.action(ArgAction::Version)` and its doctest asserts `ErrorKind::DisplayVersion` (`:1465-1491`), so following that recipe would restore the short-circuit E11 describes. The template declares a plain boolean instead. **The derive forwarding is verified too** (`C15h`), on the same footing as revision 3's `alias` proof, because F267's mechanism rests on it: `disable_version_flag` appears zero times in `clap_derive-4.6.4`'s `MagicAttrName` table (`src/attr.rs`), so `#[command(disable_version_flag = true)]` takes the same generic branch row E8 already verified — `_ => self.methods.push(Method::new(name, arg))` rendered as `quote!( .#name(#args) )` — and emits `.disable_version_flag(true)`, the builder method above |
| E13 | **that R66 owns no registry parameter**, which is why the coupling is recorded as `related (not a registry dependency)` and no `CONFLICT: R66 <param>` line is raised (`C16` of `r60-standard-pin-r5.sh`) | `grep` over R66's committed binding prompt, `docs/port/PARAMETERS.md`, `research/CLAUDE.md` and `docs/port/OWNER-REVIEW.md`, all reached by paths relative to the script | R66's prompt carries `- owns:` at `:20` with **no value** (`count=0` owns lines carrying one); the registry carries **no** output-format row (`count=0`); the research index has exactly one R66 row, recording `—` for `owns` and `open` for status, so its flag spelling is genuinely undecided. Each negative is a labelled count and each is preceded by an assertion that the file is present, so a moved file fails rather than reading as a zero. **The same row carries revision 5's repair of U8, inverted from revision 4's** (`C16h`–`C16o2`). Revision 4 asserted that `docs/port/OWNER-REVIEW.md` contained `OV-01` zero times and `2026-09-14` zero times — true when written, false by the time it was audited, and the revision-4 audit's finding F1. The assertion is now the opposite one and is **anchored, not counted**: the ruling's section is located by its heading `### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused` (`count=1`), extracted with `sed` up to the next H2, and each clause this decision relies on is asserted inside that extraction — the standard-pin clause "(version 1.4.14, blob `f9de0437`) governs this template", the refusal "**Override OV-01 is REFUSED.**", the selection "The owner instead selected R60's own conformant option (b)", the conformance clause "the template waives no `SHOULD`", and "R60 carries zero overrides; OV-01 is retired as". `C16m` is the control that keeps the extraction from silently becoming the whole file: `Zero license`, which belongs to the *2026-09-12* section of the same file, must be absent from it (`count=0`). `C16n`–`C16n4` do the same for `docs/planning/p02/owner-decisions.md`, naming the `-- ANSWERED 2026-09-14` heading in full because that file carries two `## 9.` headings, and asserting "**DECIDED.** The standard BINDS. Override OV-01 is NOT waived". `C16o`/`C16o2` confirm R60 still has exactly one row inside the extracted `## Dispositions` section and that it is still the untouched 2026-09-04 codesign acceptance. **No file-wide count is asserted or printed**, because the file is the controller's and grew another section between the revision-4 audit and this revision |

**Headline command and exit status.** `cargo generate-lockfile` on the
recommended pins at `rust-version = "1.96"` → **exit 0**, followed by
`cargo audit` on the resulting lockfile → **exit 0** (revision-1 run, and both
independently reproduced at exit 0 by the revision-1 auditor as described
above). For revision 3: `bash review/evidence/r60-standard-pin-r3.sh` → **exit
0**, 73 checks, 0 failures. For revision 4:
`bash review/evidence/r60-standard-pin-r4.sh` → **exit 0**, 115 checks, 0
failures. For revision 5:
`bash review/evidence/r60-standard-pin-r5.sh` → **exit 0**, 128 checks, 0
failures. For revision 6 the standard-pin script is unchanged and reruns to the
same **exit 0**, 128 checks, 0 failures, in place and from a clean extraction;
revision 6's own headline was its preservation script,
`bash review/evidence/r60-preservation-diff-r6.sh` → **exit 0**, 159 checks, 0
failures. For revision 7 the standard-pin script is again unchanged and again
reruns to **exit 0**, 128 checks, 0 failures in both modes; this revision's own
headline is `bash review/evidence/r60-preservation-diff-r7.sh` → **exit 0**, 183
checks, 0 failures.

**What these runs do not establish**, stated so they are not read as more:
none of them built or ran any CLI; none executed any acceptance criterion; none
ran a benchmark; none ran anything on `ubuntu-latest`; and none audited any
crate's `unsafe` usage. Each of those is carried to `## Engines`. Rows E1–E13
narrow none of that list: they verify that the standard says what this decision
says it says, that its cited lines resolve, that the clap methods AC9 and
AC10 name exist with the documented alias visibility, that
`ArgAction::Version` short-circuits and that the four version APIs F267's
mechanism names exist and are documented as described, that R66 owns no registry
parameter, and that the evidence can be rerun from the committed state —
**not** that any criterion passes. Say the same thing about the new rows
specifically, because they are the ones most likely to be over-read: **E11 and
E12 read source and documentation, they do not run clap.** Nothing here compiled
a `Cli` type, set `disable_version_flag`, called `render_version()` or executed
`<tool> --version <format-flag> json`; that the mechanism composes as described
is P03's to prove, and AC2, AC3 and AC7 are as unexecuted as every other
criterion. **E13 establishes that no registry parameter exists for R66 to owe
this item, not that R66 will name a flag this item can use** — which R66 outcome
lands is R66's, and the one outcome that would reopen F267 is on the `re-verify`
line. In particular, AC9 and AC10 are unexecuted, exactly as AC1–AC8 are.

## Engines

- codex `raw/codex-99cfaa33b3ae00b921df4ad482e3b1a73a9f787eaa4d138197f544d3491cfb05.md` — figures retrieved 2026-09-05; three members (`clap 4.6.6`, `clap_complete 4.6.9`, `vergen 10.0.3`); states it could not compute issue responsiveness.
- opus `raw/opus-26f8720eb4b2714cb14fdca45302b55449205a5c3889909e881aa7116aff7735.md` — figures retrieved 2026-09-10; seven members, one per ledger row; the most complete report, and the only one that read the crate source rather than the documentation.
- doxa `raw/doxa.normalized.md` — three provider bodies regrouped by template field (`doxa-openai.normalized.md`, `doxa-perplexity.normalized.md`, `doxa-gemini.normalized.md`; repairs recorded in `doxa/normalization.json`), retrieved 2026-09-09.

**Where the engines agreed.** All three name `clap` as the framework and
`clap_complete` for F268; all three choose noun-verb subcommand groups over ts's
default-command shape for F265 — **on ordering only; none of them addressed the
noun's number, see "No engine raised R1.3" below** — all three choose `global = true` on a flattened
`GlobalArgs` for F270; and all three keep clap's built-in suggestions for F272
with no direct `strsim`. That agreement is not itself the evidence — the source
reads and the fitness gates in `## Decision` are — but no disagreement had to be
resolved on those four rows.

**Disagreement 1 — where the extended `--version` metadata comes from.** Codex
recommends `vergen 10.0.3` (`cargo` + `rustc` features); Opus recommends a
dependency-free `build.rs` with `built 0.8.1` ranked second; the Doxa OpenAI
body also recommends a plain `build.rs`; the Doxa Gemini body recommends
`shadow-rs`. **Settled by the registry and by resolution**, both in this run:
`shadow-rs 2.0.0` declares no `rust-version`, so it fails gate 2 on evidence;
`vergen 10.0.3` declares `1.96.0`, exactly today's floor, and Cargo reports it
as out of range the moment the floor is one minor lower — a permanent
maintenance coupling that Codex's report does not mention; the Cargo reference
plus `rustc -vV` confirm that `TARGET` and the rustc version are both reachable
from a build script with no crate at all. Hence the dependency-free script, with
`built 0.8.1` (MSRV `1.87`, real headroom) as the ranked runner-up and `vergen`
available if git-derived metadata later becomes a requirement. Note that
`starship/starship`, a well-regarded adopter, does ship `shadow-rs 2.0.0`
(`Cargo.toml:79`, verified 2026-09-10) — the exclusion is on declared-MSRV
evidence under this template's policy, not on the crate's quality.

**Disagreement 2 — blanket versus curated env binding (F269).** The Doxa OpenAI
body recommends automatic `PLBP_<UPPER_SNAKE_LONG_NAME>` binding generated by a
command-graph post-pass "for every application-defined global", and the Doxa
Perplexity body likewise recommends "blanket env-var binding using a standard
prefix such as `PLBP_` … via a small helper or macro that applies the prefix
automatically to each global option". Codex and Opus both recommend a curated
per-option mapping. **Settled by the org CLI Design Standard**, R5.4 `(MUST)`:
"the tool **MUST NOT** auto-expose every flag as an env var"
(`/Users/stevemorin/c/cli-standards/cli-design-standard.md:321-323`, read
2026-09-10 at the pinned revision recorded under "THE STANDARD PIN" — version
1.4.14, blob `f9de0437`), org-locked at `:69` row 7, and already treated as binding by the
published R67. The blanket designs are excluded on that rule alone. Both
blanket proposals are *mechanically* sound — `Command::mut_args` exists and
would do exactly what they describe — and this decision says so rather than
resting the exclusion on a capability claim that the source does not support.

**Disagreement 3 — is the standard binding on R60 at all?** The Opus report
raises this explicitly, treating the standard as "an owner-side requirement
input that the owner should confirm applies to R60 as well as R67", and keeps
its ecosystem case independent of it. **Settled against that framing**, on the
task's direction and on precedent: the published R67 adjudicates the same
document's R6.1 as an org-locked `MUST` and quotes its table verbatim, and ts's
own router cites `cli-standards R6.1` in a code comment. This decision therefore
cites the standard by file, line and retrieval date as R67 did, **and adds the
version, commit, blob id and content hash that R67 did not record** — see "THE
STANDARD PIN" in `## Decision` for the pin and for the verification that R67
carries no version pin of its own. The practical effect is confined but is wider
than revision 1 stated: it fixes F265's ordering as a `MUST` rather than a
preference **and F265's noun number as a `MUST` (R1.3), which is where revision 1
was wrong** — it proposed a plural canonical noun; it decides F269; and it
decides F267's output shape. On that last row the effect changed again in
revision 4: revisions 1 through 3 turned F267 into a recorded override, and the
owner's refusal of that waiver on 2026-09-14 turned it back into plain
conformance with R4.6, leaving this decision with **no override**. Every other
row lands where all three engines already put it. Note what that does to the
standard's practical effect overall: it did **not** change which crate is
recommended on any row, and it has now changed F267's mechanism twice without
touching `clap`, `clap_complete` or the `build.rs`.

**No engine raised R1.3.** None of the three reports — and none of the five
provider bodies — mentions noun number at all; all of them carried the plural
`projects` straight across from py's and ts's command surfaces, and revision 1
adopted it. The rule was found only by auditing the decision against the standard
it claimed to apply. Two things follow that matter beyond this item. First, the
engines' unanimity on "noun-verb subcommand groups" was agreement on *ordering*
only, and was read in revision 1 as if it settled the whole of F265; agreement
among engines is not evidence of conformance, and here it concealed a `MUST`
violation. Second, because R60 is a prerequisite for much of the programme, a
plural noun documented here would have propagated into every downstream item
that builds a command surface on it — which is the specific reason this
correction is worth its length rather than a one-word edit.

**Disagreement 4 — Codex's `BASELINE-REVIEW: F269` line is not carried.** The
prompt reserves `BASELINE-REVIEW:` for a *challenged baseline*. F269 is a
`DIVERGENT`, py-only row owned by this item
(`docs/port/COMMONALITY.md:273`), not an inherited baseline; the only baseline
rows this item touches are F266 and F271, both already `retained`. Deciding F269
against a curated mapping is this item's job, so it is recorded as the decision
rather than as a challenge to a baseline. The substance of Codex's line — that
an implicit prefix would silently turn every newly added global flag into a
public environment API — is preserved in `## Decision` and in acceptance
criterion AC5.

**Disagreement 5 — Doxa's parameter lines.** All three Doxa bodies write `owns`
lines for names that do not exist in `docs/port/PARAMETERS.md`, and the OpenAI
body additionally writes `assumes current rust-version = 1.96.0`. This item's
prompt carries an empty `- owns:` line, so `## Parameters` above carries only
the four fixed `assumes` values. No engine raised a `CONFLICT:`; none is raised
here.

**Doxa's own evidence gap, carried rather than repaired.** The regrouped Doxa
report opens with an "Evidence-completeness warning" stating that its transport
did not expose the crates.io JSON bodies, so its download, star and
responsiveness cells are marked pending rather than invented
(`doxa.normalized.md:38`). Its architecture reasoning is used above; none of its
figures is. Every registry and GitHub figure in this decision comes from the run
in `## Empirical check` or, where attributed, from the Opus report at its stated
retrieval date.

**Unproven claims, and what would prove each.** P03 must validate all of these
in the real template. **One row, U8, is no longer unproven**: it is kept in the
table, re-labelled `RESOLVED`, because deleting a retired entry would erase how
the question was settled — the same discipline this decision applies to OV-01.
U1–U7 are unproven and are P03's to prove:

| # | Unproven | What would prove it |
|---|---|---|
| U1 | That `clap 4.6.6`, `clap_complete 4.6.9` and the transitive tree build and test on **`ubuntu-latest`** — gate 4. Nothing in this run executed on Linux; the resolution and the crate reads were done on macOS 26.4 `aarch64` only. | the template's own CI matrix running `cargo test` on both runners |
| U2 | The compile-time and binary-size cost **at 4.6.6, with the `derive`/`env`/`string`/`wrap_help` feature set, on this template's two runners**. The only figures cited anywhere in this decision are upstream `rosetta-rs` results measured by that project on Linux `x86_64` with `rustc 1.94.0` at clap **v4.5.60**; neither Opus nor this decision ran a benchmark. | `cargo bloat` or `cargo build --timings` on the built template, on each runner |
| U3 | The `unsafe` posture of `clap`, `clap_builder`, `clap_derive`, `clap_complete` and `strsim` — gate 3's second half, not assessed in this run. | `cargo geiger`, or reading each crate's `#![forbid(unsafe_code)]`/`unsafe` blocks at the pinned versions |
| U4 | That clap's usage text can be rendered **inside** R67's JSON envelope without losing clap's own formatting, and what the envelope's `message` and `hint` carry for a parse failure. This decision fixes the routing (`try_parse` + `kind()`) and the codes; it does not fix the rendering. | AC6/AC7 executed against the built CLI |
| U5 | Every acceptance criterion AC1–AC10. None was executed: no Rust CLI exists. AC9 and AC10 were added in revision 2 and are as unexecuted as the rest; what revision 2 *did* verify is that the clap APIs they name exist at 4.6.6 with the documented hidden-vs-visible alias behavior (`## Empirical check` row E8), which is a different and weaker claim than the criteria passing. | P03's integration tests |
| U6 | Issue responsiveness for every candidate except `clap-rs/clap`. The Opus report measured the 10 most recently opened issues for that one repository (5 of 10 answered, median 1.29 days among those answered, 5 unanswered, retrieved 2026-09-10) and states it measured no other; that figure also covers `clap_complete`, which shares the tracker. For `bpaf`, `built`, `vergen`, `argh`, `lexopt`, `pico-args` and `strsim`, the maintenance verdicts above rest on open-issue `total_count`, `pushed_at`, `archived` and release recency only. | the same 10-issue procedure run per candidate |
| U7 | That `bpaf` lacks a completion story equivalent to `clap_complete`. Opus asserts it does; Codex asserts a completion feature exists. Neither was verified here, and `bpaf` is excluded on fit (architecture D) rather than on this point, so the disagreement does not change the recommendation. | reading `bpaf 0.9.27`'s published source and feature table |
| U8 | **RESOLVED 2026-09-14 by revision 5, and kept on this list as the record rather than deleted.** Revision 4 listed the owner's ruling of 2026-09-14 — refusing OV-01's waiver and selecting option (b) — as unproven from this repository, because at the time it reached the item as a task instruction and was written in no file here. **That is no longer true.** The programme controller wrote it into `docs/port/OWNER-REVIEW.md:72-91`, section `### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused`, and the reasoning is at `docs/planning/p02/owner-decisions.md:261-292`, section `## 9. Whether your CLI Design Standard binds this port -- ANSWERED 2026-09-14`. The ruling is therefore re-derivable from this repository alone and **is no longer an unproven claim**; the revision-4 audit's finding F1 named exactly this staleness. Everything downstream of it was already checkable and is still checked — that F267 takes option (b), that no override is declared, that no waiver is claimed. | nothing further: it is proven. The record's presence, and each clause this decision relies on, is asserted in `## Empirical check` row E13 (`C16h`–`C16o2` of `r60-standard-pin-r5.sh`) |

**Uncertainty that is not an evidence gap.** `clap-rs/clap` carries 369 open
issues against a project led by a single primary maintainer, which is a real
backlog signal. It does not meet the rubric's `at-risk` bar — no unpatched
advisory, no broken build on current stable, no maintainer notice, and releases
continuing (newest `4.6.6`, `created_at` 2026-08-06; repository `pushed_at`
2026-09-09) — so the maintenance verdict recorded here is **`active`**. If a
future re-verification finds the release cadence broken *and* the backlog
growing, architecture D (`bpaf`) is the shortlisted successor and U7 becomes the
first thing to settle.

**Audit of revision 1, and what revision 2 changed.** The revision-1 draft
(sha256 `d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c`, blob
`5ae06c378ee71a8d6b16eb394862806284c72ca5`) was **rejected** by
`audit-codex-2026-09-05T183002Z-09f93cfc507c-r1` (gpt-5.6-terra; report at
`review/audit-codex.r1.md`, rerun log
`review/evidence/audit-cli-parsing-framework-r1.log`) on two findings, both
repaired here.

**F1 — a `MUST` violation of R1.3.** Revision 1 made `projects` a canonical
documented resource noun and its acceptance criteria omitted the singular
canonical form. R1.3 `(MUST)` requires the canonical form to be singular, and a
`SHOULD` waiver cannot waive a `MUST`. Repaired at **nine** locations, found by
searching for every line carrying the noun rather than by re-reading: the F265
mechanism row; the P2 principles row; the Standard-profile consequence bullet
(`projects`→`project` in the template's resource groups); a new consequence
bullet stating R1.3 in full, with the hidden-alias mechanism and its clap
spelling; essential behavior 6, whose R3.10 example had rested on the plural
being canonical; AC1; AC5; AC6, rewritten around a mistyped noun and a bare
prefix instead of the singular form; and the engines-agreement paragraph, which
had read unanimity on *ordering* as though it settled the noun's number. Two new
criteria, **AC9** and **AC10**, assert the rule's three parts directly — that is
the specific gap the auditor named. Two occurrences of the plural were
deliberately **kept**: the verbatim quotation of the standard's own Appendix A
counter-example at `:586`, now marked as a quotation whose plurals are the
standard's illustrative wording, and the quoted `.command('projects', …)` line
from ts's source. Editing either would have falsified a quotation.

**F2 — the standard was not version-pinned.** Repaired by "THE STANDARD PIN" in
`## Decision`, which fixes version 1.4.14, commit `fb30a591…`, blob
`f9de0437…` and content sha256 `9fb05d3d…`, states the three independent recipes
that resolve it (the committed snapshot, the commit-addressed
`raw.githubusercontent.com` URL, and `git cat-file` in any clone), and records
that R67's body pins nothing while R67's revision-4
audit log independently attests the same version 1.4.14. The pin is referenced
from the status paragraph, from OV-01, from the R5.4 citation in this section,
and from the `re-verify` line, which now triggers on the blob id changing.

**Found while verifying the pin, and repaired although the auditor did not raise
it:** revision 1 cited the org-locked Decision Log at `:70` for rows 1, 3 and 7,
but `:70` is row 8 — R67's exit-code row, copied across. The correct lines are
`:63`, `:65` and `:69` (header `:61`, row *N* at 62 + *N*), and row 5, the
noun-number rule F1 turns on, is at `:67`. Three citations corrected. This is
the pin doing its job on its first use: pinning a document is worth nothing if
the line numbers into it are wrong, and only a mechanical check of every cited
line surfaces that.

**What is unchanged from revision 1** — **a statement about revision 2, in
revision 2's present tense, kept as written; three of its clauses are no longer
true of the current text and each is named immediately after it** — and
confirmed unchanged by diffing
against blob `5ae06c378ee71a8d6b16eb394862806284c72ca5`: the recommended crate
and feature set (`clap 4.6.6` with `derive`/`env`/`string`/`wrap_help`,
`clap_complete 4.6.9`, the dependency-free `build.rs`, `strsim 0.11.1`
transitive only); the lockfile generation and advisory audit that both exited
`0`; the four fixed `assumes` parameter lines, byte-for-byte; the five
architecture alternatives and every data row of the fitness-gate table (its
header cell is the one part that changed, and only to mark gate 1 inapplicable —
see the revision-3 note below); the seven essential
behaviors; the practice-evidence table; OV-01's argument, its three options and
its pending status; the five engine disagreements; and U1–U7 apart from U5's
criterion range. **OV-01 remains the only override** and remains ungranted: the
owner has not answered the waiver request, and revision 2 adds an explicit
"requested, not granted" status line plus the two conforming alternatives by
name, so no reading of it implies approval. Conformance to R1.3 is deliberately
**not** recorded as a second override, because a non-waivable `MUST` is a
constraint rather than a choice — the same treatment F269 already receives.

**The three clauses of that paragraph that revision 4 falsified, listed so no
reader takes it for a current claim.** (i) "the seven essential behaviors" — six
are unchanged; **behaviors 1 and 2 are rewritten** around `ArgAction::Version`'s
short-circuit and `render_version()`, so the count holds but the content of two
does not. (ii) "OV-01's argument, its three options and its pending status" —
the argument and the three options are still byte-identical, but **the pending
status is gone**: the waiver was refused on 2026-09-14 and OV-01 is retired.
(iii) "**OV-01 remains the only override** and remains ungranted" — **R60 now
declares no override at all**, and "ungranted" is superseded by "refused". The
rest of the paragraph still holds, including every preservation target the
revision-3 script checks: the crate and feature set, the lockfile and advisory
results, the four `assumes` lines byte-for-byte, the five architectures, the
fitness-gate data rows, the practice-evidence table and the five engine
disagreements.

**Audit of revision 2, and what revision 3 changed.** The revision-2 draft
(sha256 `18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r2` (gpt-5.6-terra;
report at `review/audit-codex.r2.md`) on a single blocker: **the evidence scripts
were not rerunnable once the revision was committed**, which contradicted the
decision's own byte-for-byte reproducibility claim. The auditor reported every
substantive content check passing and both negative controls behaving correctly;
what failed were lifecycle assertions that could only hold in an uncommitted
working tree. **No finding touched the recommendation, and the recommendation
does not move.** The four mechanisms behind the failure are named and removed one
by one in the table under `## Empirical check`; the two offline scripts now read
only committed files, and the rerun was demonstrated from a `git archive`
extraction of this revision's own commit rather than asserted.

**Corrected while rebuilding the scripts, although the auditor did not raise
it:** revision 2's harness compared counts as bare substrings, so an expectation
of `0` was satisfied by an actual count of `10`. Six checks were exposed to that.
Every numeric comparison in the revision-3 scripts is now a labelled string
(`count=0`), which cannot match that way. No revision-2 result changes as a
result — the counts were genuinely `0`, `1` and `2` — but the checks were weaker
than they read.

**Also changed in revision 3, on the owner's licence ruling of 2026-09-12 (Q4 as
superseded by Q7.B):** fitness gate 1 is struck from every item's evaluation, so
it is recorded here as `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`, with the reason, in
the two places this decision evaluated a licence against a criterion: the
fitness-gate table's gate-1 column header, which now marks the gate inapplicable
and points at the qualification that carries the ruling, and the `## Parameters`
prose for `license`, which had said the parameter was "satisfied by the whole
resolved tree". **Nothing else moves, because nothing else rested on it**: all
four gate exclusions are gate-2 exclusions for a missing `rust-version`, and
`argh`'s `BSD-3-Clause` excluded nothing before the ruling and excludes nothing
after it. The licence values recorded in the table's cells, in `## Empirical
check` §01 and §08 and in the evidence log's section W are left byte-identical
and are re-labelled in prose as facts the registry returned rather than gate
verdicts — deliberately, because three of those lines are revision-1
preservation targets whose alteration would break the preservation claim this
decision rests on, and because deleting an observation is not what the ruling
asks for. The `- assumes license = MIT OR Apache-2.0` line is unchanged: it is
the repository's own declared expression, which the ruling explicitly leaves
standing, and it must in any case match `docs/port/PARAMETERS.md` byte-for-byte.

**Audit of revision 3, and what revision 4 changed.** The revision-3 draft
(sha256 `14f66259aad6063f9506410735e61e9a58a026fc24200cb048b9bbc71bbc2100`) was
**approved** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r3` (gpt-5.6-terra;
report at `review/audit-codex.md`, rerun log
`review/evidence/audit-cli-parsing-framework-r3.log`) with
`unresolved-findings: none`. The auditor archived commit
`d642814cddfd3f1756fc56cd38738904440d9141` into an empty directory with no
`.git`, ran all three revision-3 scripts from that extraction, and reported all
three at exit `0` with the two offline logs diffing empty. **So revision 4
implements no audit finding.** It implements the owner's ruling of 2026-09-14 on
the single question revision 3 left open, and its scope is that ruling and
nothing else.

**What the ruling was, and what it did to this decision.** The owner was asked
whether the org CLI Design Standard binds this port and whether OV-01's `SHOULD`
waiver was granted. The answer: the standard binds — the same pinned revision
1.4.14, blob `f9de0437`, that this decision already records and that the
published R67 already relies on for R6.1 — and **the waiver is refused**, with
F267's own conforming **option (b)** selected in its place. OV-01 is therefore
retired and **R60 declares zero overrides**. The ruling itself is not recorded in
this repository and is carried as **U8**.

**That last sentence was true when revision 4 wrote it and is false now, and
revision 5 corrects it here rather than rewriting the paragraph around it.** The
controller wrote the ruling into `docs/port/OWNER-REVIEW.md:72-91` and
`docs/planning/p02/owner-decisions.md:261-292` after revision 4 was drafted, so
the ruling **is** recorded in this repository and **U8 is resolved** rather than
carried. The revision-4 audit found the stale claim (F1) and rejected the draft
for it; the repair is enumerated below under "Audit of revision 4, and what
revision 5 changed".

**The edit list, enumerated mechanically before any edit was made rather than by
re-reading afterwards.** The document was searched for every line carrying
`OV-01`, `OVERRIDE`, `waiv`, `granted`, `long_version`, `DisplayVersion`,
`--version`, `` `-V` ``, `F267`, `AC2`, `AC3`, `AC7`, `R4.6`, `R66`, `extended`,
`re-verify`, `only override`, `first override` and `has not reviewed`; the
resulting line list was the work queue, and the same search was re-run against
the edited file. Fourteen locations moved:

| # | Location | Change |
|---|---|---|
| 1 | the title | revision 3 → revision 4 |
| 2 | the revision preamble | a revision-4 paragraph naming the approval, the ruling, and the widening beyond AC2/AC3 |
| 3 | `## Decision`'s status paragraph | "the owner has not reviewed R60" qualified: one question answered, the decision not reviewed |
| 4 | the F267 row of the six-surfaces table | `long_version` out; single line on both spellings; the JSON path and its cost named |
| 5 | the R67 integration paragraph | `ErrorKind::DisplayVersion` is no longer reachable, so the template's routing rule names one kind, not two |
| 6 | principles row P3 | what must agree now includes the single-line default; what may vary is the JSON object and its spelling |
| 7 | the third standard-consequence bullet | "R4.6 is a `SHOULD` this design deviates from" → satisfies, with the full conformance record and no waiver |
| 8 | essential behaviors 1 and 2 | rewritten around `ArgAction::Version`'s short-circuit, `render_version()`, and `disable_version_flag(true)` |
| 9 | AC2 | byte-identity of `-V` and `--version`, plus the no-leading-`v` `MUST` |
| 10 | AC3 | the JSON object replaces the two extra lines; fields matched to R4.6 `:276` |
| 11 | AC7 | the two halves now reach exit `0` by different routes; assert on the outcome, not the error kind |
| 12 | the OV-01 block | retitled `RETIRED OVERRIDE`, the refusal recorded, the argument and options table kept unedited, the "only AC2/AC3" prediction corrected, and `F267 AS DECIDED` plus the R66 coupling analysis added |
| 13 | the `re-verify` line | the fired OV-01 trigger removed; the one R66 outcome that reopens F267 added |
| 14 | `## Parameters` prose | three related-notes become four; R66 recorded as `related (not a registry dependency)` with the reason no `CONFLICT:` line is possible |

Two further locations were edited to stop a *historical* statement from reading
as a current one, rather than to change a claim: Disagreement 3's sentence about
what the standard's applicability decided, which now records that F267's row
moved twice; and the revision-2 "What is unchanged from revision 1" paragraph,
which is kept in revision 2's present tense with its three now-false clauses
listed immediately after it.

**What did not change, and why that is the point.** The recommendation is
untouched: `clap 4.6.6` with `derive`/`env`/`string`/`wrap_help`,
`clap_complete 4.6.9`, the dependency-free `build.rs`, `strsim 0.11.1`
transitive only. So are the five architecture alternatives, every data row and
every qualification of the fitness-gate table, the practice-evidence table, the
`## Parameters` lines byte-for-byte, the five engine disagreements, U1–U7, the
standard pin, the R1.3 repair, the four failure mechanisms revision 3
diagnosed, the snapshot apparatus and the post-commit `git archive` proof. Gate
1 stays `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is
not evaluated for any dependency or tool`. Sections 01–12 of `## Empirical
check` are not re-run and are not re-claimed.

**Two corrections made beyond the brief, reported rather than fixed quietly.**
First, R4.6's line range: the rule spans `:275-277` in the pinned text, not the
`:275-279` and `:277-279` that revisions 1 through 3 used, which overrun into
the blank line at `:278` and R4.7's heading at `:279`. The historical lines are
left byte-identical — one is a revision-1 preservation target — and every
citation this revision relies on uses `:276` for the rule and `:277` for the
worked example. Second, revision 3's own sentence predicting that adopting (b)
would rewrite "only the acceptance criteria AC2/AC3" is false, and is corrected
in place under OV-01 rather than deleted: it was written from the two options'
*content* without checking whether clap's built-in version flag could carry
(b)'s JSON half. It cannot, and behaviors 1 and 2, AC7, the F267 row and the R67
routing paragraph move with it.

**Audit of revision 4, and what revision 5 changed.** The revision-4 draft
(sha256 `12aaf65c88f6bbcde915723913257f78d2e2e483c6deac4ee808b41af122ef43`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r4` (gpt-5.6-terra;
report at `review/audit-codex.md`, rerun log
`review/evidence/audit-cli-parsing-framework-r4.log`) on **one** finding, F1,
quoted in full in the revision note at the top of this document. The auditor
confirmed everything else: the pinned `clap_builder 4.6.6` parser source
returning `Err(self.version_err(use_long))` at `parser.rs:1322-1331`, the
corrected R4.6 span `:275-277`, AC2/AC3/AC7, the retired OV-01 record, R66's
`related`-not-conflict classification, the five source refetches matching their
pinned bytes, and U1/U3 correctly labelled unproven. **So the recommendation was
not challenged and does not move.**

**What F1 was, in one sentence.** Revision 4 stated that the owner's ruling of
2026-09-14 was recorded in no file in this repository and carried that as U8;
between its drafting and its audit the programme controller wrote the ruling
into `docs/port/OWNER-REVIEW.md:72-91`, so the statement had gone stale and the
two checks that asserted the ruling's absence — `C16h` and `C16i` of
`r60-standard-pin-r4.sh` — failed, taking that script from its recorded 115/0 to
exit `2`.

**The edit list, enumerated mechanically before any edit was made rather than by
re-reading afterwards.** The document was searched for every line carrying `U8`,
`not written into any file`, `OWNER-REVIEW`, `owner-decisions`, `re-derive`,
`task instruction`, `controller`, `C16h`, `C16i`, `E13`, `E9`, `-r4.sh`,
`-r4.log`, `revision 4`, `115`, `104`, `twelve`, `E11–E13` and
`No row below cites`; the resulting line list was the work queue, and the same
searches were re-run against the edited file. Eleven locations moved, and the
list below was checked against the `C9` r4→r5 diff in
`review/evidence/r60-preservation-diff-r5.log` rather than against memory:

| # | Location | Change |
|---|---|---|
| 1 | the title | revision 4 → revision 5 |
| 2 | the revision preamble | a revision-5 paragraph quoting finding F1 verbatim and naming the repair |
| 3 | the OV-01 provenance paragraph ("What the repository can and cannot show") | **kept verbatim** and corrected immediately after, naming both durable records by path, line range and section heading |
| 4 | `## Empirical check`'s "Three runs, kept separate" paragraph | a fourth execution recorded; E13's second half flagged as rewritten |
| 5 | the identifier note | `C<n>` ids now name the revision-5 script |
| 6 | `## Empirical check` | the retained-scripts and reproducibility paragraphs rewritten to cover revisions 3 *and* 4, and a **Revision-5 run** section added: its results table, how the two checks were inverted, the fourth baseline, the observed failures of the two revision-4 scripts, and the one input this revision reads but does not own |
| 7 | rows E1, E9, E11, E12, E13 | script names r4 → r5 where the row is a revision-5 claim; E9's counts, its fourth baseline and its `C4k` family; E13's U8 half inverted. E5 and E6 name no script and did **not** move. **E10 deliberately still cites `r60-snapshot-provenance-r4.sh`**, which is unchanged and reruns byte-identical |
| 8 | the headline command line | the revision-5 standard-pin result added beside revision 3's and revision 4's |
| 9 | the U8 row of the unproven table | re-labelled `RESOLVED`, naming where the record is; the table's preamble now says U1–U7 are what remains unproven |
| 10 | the closing sentence of "Audit of revision 3, and what revision 4 changed" | the "not recorded in this repository" sentence **kept** and corrected immediately after |
| 11 | the closing fitness-gate sentence | "nothing revision 4 changed touches any of them" → "nothing revision 4 or revision 5 changed"; the six gate bullets themselves are byte-identical |

**What did not change, and why that is the point.** The recommendation is
untouched: `clap 4.6.6` with `derive`/`env`/`string`/`wrap_help`,
`clap_complete 4.6.9`, the dependency-free `build.rs`, `strsim 0.11.1`
transitive only. So are the owner's ruling and everything it decided — the
standard binds, OV-01 is refused, F267 implements option (b), R60 declares zero
overrides and waives no `SHOULD`. So are AC2, AC3 and AC7; the retired OV-01
record with its argument and options table; the corrected R4.6 `:275-277`
citations; R66's `related (not a registry dependency)` classification; the five
architecture alternatives; every fitness-gate row including gate 1's
`inapplicable`; the `## Parameters` lines byte-for-byte; the five engine
disagreements; U1–U7; the standard pin; `snapshots/MANIFEST.txt` and every
snapshot in it. **The mechanical evidence for that** is that
`r60-preservation-diff-r4.sh`, rerun unmodified against this text, fails on
`C4h` — the title — **and on nothing else**: all 23 preservation targets, the
whole 34-check `C4f` inversion family, `C4g` with its positive control, and
every structural and gate check still pass.

**One thing reported beyond the brief.** `docs/planning/p02/owner-decisions.md`
records, as the effect of the ruling on R60, that "AC2 and AC3 are rewritten and
nothing else in R60 changes", and cites R4.6 as `:277-279`. Both clauses are
R60's own revision-3 text quoted back; revision 4 established that the first is
too narrow and the second overruns the rule by two lines, and revision 5 leaves
the owner's file untouched and says so here instead. Neither correction changes
the owner's choice, which is option (b) either way.

**Audit of revision 5, and what revision 6 changed.** The revision-5 draft
(sha256 `2a665e73f5a5d93794fe49520615e204be294d156f1d537b7bafe1421c042c06`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r5` (gpt-5.6-terra;
report at `review/audit-codex.md`, rerun log
`review/evidence/audit-cli-parsing-framework-r5.log`) on **one** finding, F2,
quoted in full in the revision note at the top of this document. The auditor
confirmed everything else from a clean `git archive HEAD` extraction: the owner
ruling correctly recorded, the revision-5 anchoring, the parameter preservation,
the retired OV-01 record, AC2/AC3/AC7, R66's `related`-not-conflict
classification, the corrected R4.6 `:275-277` span, gate 1's `inapplicable`
treatment under Q7.B, the r5 standard-pin script's owner-record section
extraction including its `C16m` scoped-extraction control, and five external
citations refetched and hash-matched. **So the recommendation was not challenged
and does not move, and neither does the owner's ruling.**

**What F2 was, in one sentence.** `r60-preservation-diff-r5.sh` said it read
committed files only, but `C1i` and `C1o` located an audit report by searching
this run's `review/` directory for whichever file carried a given decision hash;
an untracked byte-for-byte copy of the revision-4 report was sitting there, two
files matched, the one-report assertion failed, and the in-place rerun exited `1`
with 133 checks and one failure while the committed log recorded `133` and no
failures.

**Two things are corrected, not one.** The finding names the count; rerunning the
script in place on 2026-09-15 exposed the second half. With the revision-4 report
since archived under its round name, the count is `1` again and the script exits
`0` — yet the printed basename moved from `audit-codex.md` to
`audit-codex.r4.md`, so the log still does not reproduce in place. A directory
read is unreproducible whether or not its count happens to be right, which is why
the repair names files rather than tightening the count.

**The edit list, enumerated mechanically before any edit was made rather than by
re-reading afterwards.** The document was searched for every line carrying
`-r5.sh`, `-r5.log`, `133`, `byte-for-byte`, `reproduc`, `in place`,
`located by the hash`, `renames the previous`, `C1i`, `C1m`, `C1o`, `C1q`, `E9`,
`fourth baseline`, `revision-5 script`, `re-executed`, `For revision 5`,
`revision 4 or revision 5 changed`, `No row below cites` and
`revision 5`; the resulting line list was the work queue, and the
same searches were re-run against the edited file. Twelve locations moved, and
the list below was checked against the `C10` r5→r6 diff in
`review/evidence/r60-preservation-diff-r6.log` rather than against memory:

| # | Location | Change |
|---|---|---|
| 1 | the title | revision 5 → revision 6 |
| 2 | the revision preamble | a revision-6 paragraph quoting finding F2 verbatim, recording both in-place observations and naming the repair and its cost |
| 3 | `## Empirical check`'s "Three runs, kept separate" paragraph | a fifth execution recorded, naming which script each half ran |
| 4 | the identifier note | `C<n>` now names the id in whichever script the citing row names, since the three scripts are now at three different revisions |
| 5 | the Revision-5 results table | **kept**, with the correction of its preservation row immediately after: reproducible from a clean extraction, not in place, with both observations and their numbers |
| 6 | the fourth-baseline paragraph | **kept**, with its "located by the hash its own audit report names rather than by a file name" reasoning reversed immediately after — that phrasing describes the defect |
| 7 | the "same two reproducibility claims" paragraph | its sentence **kept verbatim** and corrected: true of the standard-pin script, false of the preservation script, and why |
| 8 | the retained-scripts paragraph | `r60-preservation-diff-r5.sh` added to the retained-but-superseded set; `r60-standard-pin-r5.sh` stated to stay live, with the reason F2 does not reach it |
| 9 | `## Empirical check` | a **Revision-6 run** section added: its results table in both modes, the fifth baseline, how the lookup was rewritten, what `C1r` adds and the demonstration that it fires, and the observed failure of the revision-5 script against this text |
| 10 | row E9 | script r5 → r6; its method rewritten around named reports; its count 133 → 159; the title check; and the `C4m` family |
| 11 | the headline command line | the revision-6 preservation result added, and the unchanged standard-pin result restated for this revision |
| 12 | the closing fitness-gate sentence | "nothing revision 4 or revision 5 changed" → "nothing revision 4, revision 5 or revision 6 changed"; the six gate bullets themselves are byte-identical |

**What did not change, and why that is the point.** The recommendation is
untouched: `clap 4.6.6` with `derive`/`env`/`string`/`wrap_help`,
`clap_complete 4.6.9`, the dependency-free `build.rs`, `strsim 0.11.1`
transitive only. So are the owner's ruling and everything it decided — the
standard binds, OV-01 is refused, F267 implements option (b), R60 declares zero
overrides and waives no `SHOULD`. So are AC2, AC3 and AC7; the retired OV-01
record with its argument and options table; the corrected R4.6 `:275-277`
citations; R66's `related (not a registry dependency)` classification; U8's
`RESOLVED` label and its `OWNER-REVIEW.md:72-91` citation; the five architecture
alternatives; every fitness-gate row including gate 1's `inapplicable`; the
`## Parameters` lines byte-for-byte; the five engine disagreements; U1–U7; the
standard pin; `snapshots/MANIFEST.txt` and every snapshot in it; and the two
unchanged scripts `r60-standard-pin-r5.sh` and `r60-snapshot-provenance-r4.sh`,
both of which reran to their committed logs for this revision. **The mechanical
evidence for that** is that `r60-preservation-diff-r5.sh`, rerun unmodified
against this text, fails on `C4h` — the title — **and on nothing else**.

**One thing reported beyond the brief.** The audit named `C1o`. `C1i`, which
locates the revision-3 report, carried the identical defect: it searched the same
directory for the revision-3 hash and required one match, and its count came back
`1` by luck of timing rather than by construction. Both are repaired, and `C1r`
now forbids the pattern on any executable line of the script, so the class is
closed rather than the two instances.

**Audit of revision 6, and what revision 7 changed.** The revision-6 draft
(sha256 `89d888fb3a649ed7a99c895e4bc279a1afcc61438c3c41b6db8a966b6459db38`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r6` (gpt-5.6-terra;
report at `review/audit-codex.md`, which the controller archives as
`review/audit-codex.r6.md` when the next round opens; rerun log
`review/evidence/audit-cli-parsing-framework-r6.log`) on **one** finding, F3,
quoted in full in the revision note at the top of this document. The auditor
reran all three scripts in place and from a clean `git archive HEAD` extraction —
preservation `159/0`, standard-pin `128/0`, provenance `17/0/0/2` in place and
its documented `14/0/0/5` from the archive, each diffing empty against its
committed log — and confirmed everything else: `C1r0`'s comment-only wildcard and
`C1r`'s zero executable uses, the archived-report assertions `C1i` through `C1q`,
the revision-5 control failing only `C4h` at `133/1`, the four parameter lines
against `docs/port/PARAMETERS.md`, AC2, AC3, AC7, the retired OV-01 record, R66's
`related` classification, R4.6's `:275-277` span, U8's resolved owner record at
`docs/port/OWNER-REVIEW.md:72-91`, gate 1's `inapplicable` treatment under Q7.B,
and five cited endpoints refetched with `curl`. **So the recommendation was not
challenged and does not move, and neither does the owner's ruling.**

**What F3 was, in one sentence.** `r60-preservation-diff-r6.sh` read the current
round's audit report at `review/audit-codex.md` and the decision stated that four
named checks would fail once the next report replaced it; the auditor's
post-landing rerun exited `5`, because `C1u` requires `verdict: reject` and the
draft report the auditor ran against carried `verdict: approve`.

**Why revision 7 repairs a class and not a count.** Adding `C1u` to the list
would have produced a list that is still wrong whenever the next verdict differs,
and this is not hypothetical: the report that actually landed carries
`verdict: reject`, so the same script measured `4` failures in place, not the
auditor's `5`. Both measurements are recorded in the revision note; they cannot
both be a complete list, and neither was knowable when the list was written. The
repair therefore removes the live path from the script rather than extending what
the decision says about it.

**The edit list, enumerated mechanically before any edit was made rather than by
re-reading afterwards.** The document was searched for every line carrying `C1t`,
`C1u`, `C1v`, `post-landing`, `current round`, `canonical`, `audit-codex.md`,
`-r6.sh`, `-r6.log`, `159`, `revision 6`, `revision-6` and `For revision 6`; the
resulting line list was the work queue, and the same searches were re-run against
the edited file. Ten locations moved, and the list below was checked against the
`C11` r6→r7 diff in `review/evidence/r60-preservation-diff-r7.log` rather than
against memory:

| # | Location | Change |
|---|---|---|
| 1 | the title | revision 6 → revision 7 |
| 2 | the revision preamble | the falsified post-landing sentence **kept verbatim** and labelled, then a revision-7 block quoting finding F3, diagnosing the defect as structural, recording both measurements, naming the repair and stating what it deliberately does not assert |
| 3 | `## Empirical check`'s "Three runs, kept separate" paragraph | a sixth execution recorded, naming which script each half ran |
| 4 | the identifier note | `C<n>` for row E9 now names the revision-7 preservation script |
| 5 | the "how the lookup was rewritten" paragraph | **kept**, with the correction immediately after: naming the live path "for the current round" is the state F3 rejected, and the fifth archived path replaces it |
| 6 | `## Empirical check` | a **Revision-7 run** section added: its results table in both modes, the sixth baseline anchored by hash alone, and the revision-6 script's two measured failures against this text |
| 7 | row E9 | script r6 → r7; its method rewritten around archived reports and `C1x`; its count 159 → 183; the title check; `C4m10` relabelled as a kept superseded record; and the `C4n` family |
| 8 | the headline command line | the revision-7 preservation result added, and the unchanged standard-pin result restated for this revision |
| 9 | `## Engines` | this audit block, the F3 summary, why a class is repaired rather than a count, and this edit list |
| 10 | the closing fitness-gate sentence | "nothing revision 4, revision 5 or revision 6 changed" → "nothing revision 4, revision 5, revision 6 or revision 7 changed"; the six gate bullets themselves are byte-identical |

**What did not change, and why that is the point.** The recommendation is
untouched: `clap 4.6.6` with `derive`/`env`/`string`/`wrap_help`,
`clap_complete 4.6.9`, the dependency-free `build.rs`, `strsim 0.11.1`
transitive only. So are the owner's ruling and everything it decided — the
standard binds, OV-01 is refused, F267 implements option (b), R60 declares zero
overrides and waives no `SHOULD`. So are AC2, AC3 and AC7; the retired OV-01
record with its argument and options table; the corrected R4.6 `:275-277`
citations; R66's `related (not a registry dependency)` classification; U8's
`RESOLVED` label and its `OWNER-REVIEW.md:72-91` citation; the five architecture
alternatives; every fitness-gate row including gate 1's `inapplicable`; the
`## Parameters` lines byte-for-byte; the five engine disagreements; U1–U7; the
standard pin; `snapshots/MANIFEST.txt` and every snapshot in it; the r5
standard-pin script's anchoring of the owner record; and the two unchanged
scripts `r60-standard-pin-r5.sh` and `r60-snapshot-provenance-r4.sh`, both of
which reran to their committed logs for this revision.

**One thing reported beyond the brief.** The finding named the decision's
sentence and the script's comment. The `C1t`–`C1v` family that the comment
described carried the same defect in executable form, and `C1i`/`C1o`'s repair in
revision 6 had already moved every *other* report read onto an archived path — so
the live path survived in exactly one place, which is why one more round was
needed to see it. Revision 7 closes the class with `C1x` rather than the
instance, in the same way revision 6 closed F2's class with `C1r`.

**The six fitness gates, enumerated mechanically at the close of this revision
because two items this week shipped an "exhaustive" edit list that had silently
dropped one.** Each is answered for every candidate in the fitness-gate table
under `## Decision`, and nothing revision 4, revision 5, revision 6 or revision 7
changed touches any of them.
**Gate 1, licence:** `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` — stated on one unwrapped line here, so the recorded wording can be matched whole; the column is kept with the registry's values recorded as facts, and no exclusion ever rested on it. **Gate 2, MSRV within the policy:** answered per candidate against the 1.96
floor; it is the gate that excludes `shadow-rs`, `argh`, `lexopt` and
`pico-args` for declaring no `rust-version`, and that demotes `vergen 10.0.3`
for declaring exactly the floor (qualification 4). **Gate 3, RustSec advisories
and `unsafe` posture:** no advisory page for any of the eight crates queried,
the 404 reading validated against two positive controls, and `cargo audit` clean
on the resolved tree; the `unsafe` half is **explicitly not assessed** and is
carried as U3 (qualification 1). **Gate 4, builds and is tested on
`ubuntu-latest, macos-latest`:** **not established by this decision** — no CI
configuration was read and nothing ran on Linux — and carried as U1
(qualification 2). **Gate 5, default features and async-runtime coupling:**
answered per candidate in its own column — `clap`'s
`std,color,help,usage,error-context,suggestions`, `clap_complete`'s
`default = []` with its `clap >= 4.5.20` floor, `strsim` pulled only by clap's
`suggestions` — and no candidate couples to an async runtime, which is why no
row names one. **Gate 6, binary-size and compile-time cost:** answered
qualitatively per candidate from the upstream `rosetta-rs` benchmark, with its
limits stated in full (another project's system, `rustc 1.94.0`, clap v4.5.60,
neither CI runner) and the unmeasured case carried as U2 (qualification 3). All
six are answered, none is omitted, and none is answered by a bare exit status.
