decision-sha256: 10caee16f01cb2b39bad301c7669abb65cef4cb24b112fb0821bc23869bc73e7
actor: audit-fable-2026-09-17T020715Z-7f97cd917c54-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 (blocking) — AC3's byte-empty stdout contradicts AC2 and the decision's own must-agree ordering row, and the resulting tension with R67's envelope invariant is unrecorded; JF-2 — fitness gate 3's `unsafe` posture for `arboard` is stated nowhere; JF-3 — the §7.6 issue-responsiveness figure is omitted; JF-4 — the `re-verify:` line names two alternatives the decision never defines; JF-5 — standard rule R5.6 is cited for a proposition it does not carry; JF-6 — "verbatim" overstates the `nushell` reference, which pins 3.6.0; JF-7 — the rejected warning policy is not recorded beside the fatal choice

I read, in order, `docs/superpowers/plans/p02-roles/judgment-auditor.md`,
`review/DECISION.md` whole, `raw/codex.md` whole, the parts of `raw/opus.md`
that carry the five disagreements and the fatal-versus-warning choice,
`inputs/prompt.md`, `research/RUNBOOK.md` §4–§5,
`research/topics/67-error-and-exit-code-contract/DECISION.md`,
`docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md:285-286`,
`docs/port/OWNER-REVIEW.md`, `docs/port/BASELINE-REVIEW.md`, the org CLI Design
Standard v1.4.14 at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, both
committed logs under `review/evidence/`, both evidence scripts, the `py`
commit `f587e48b41bcf6535ba1b62f348147294911c48d` and its parent through the pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`, and the `ts` pin. I reran nothing.
The decision file is committed and clean, and the sha256 above is the
working-tree file as I read it. No `review/audit-fable.md` existed before this
one. The empirical audit is deferred for this revision, so
`review/audit-codex.md` does not exist and the role doc's audit-consistency
check is inapplicable here; nothing in this audit stands in for it.

## Principle and agreement level

The requirement is stated at the level the owner clarification of 2026-09-04
asks for and no lower: a capability and a policy — an optional `--copy` on a
result-emitting command, the write strictly after the primary sink, the note on
stderr, a typed catchable failure carrying a remedy, and absence of the facility
treated as a normal runtime state. The five-row must-agree / may-differ table
(`### Principles and implementation`) puts the crate, the synchronous-versus-helper
question, the note's wording, the concrete error type and the catalogue code on
the may-differ side. That is the correct split for an item whose ledger rows are
`ts-only DIVERGENT`: there is no inherited Rust mechanism to preserve, only an
outcome.

The item's strongest analytical move is the one the prompt did not ask for. The
prompt's `## Context` gloss — "py ships no clipboard integration to compare
against" — is corrected rather than repeated, and the correction is load-bearing
for the "should `--copy` exist at all" question (architecture D). I verified the
correction at source rather than through the log:
`f587e48b41bcf6535ba1b62f348147294911c48d`, dated 2026-06-09, whose body names
"`--copy`/clipboard" among "the legacy flat-flag features … dropped"; at
`f587e48^`, `src/py_launch_blueprint/projects.py:398` calls `pyperclip.copy(result)`
immediately after `console.print(result)`, guarded by nothing more specific than
`except Exception` → `sys.exit(4)`; and `pyperclip` appears zero times in tracked
`*.py` and `pyproject.toml` at the pin. Every element of the decision's account
holds, including the reading that the removal is collateral rather than a
judgement against the capability.

Recording that as a finding and emitting no `BASELINE-REVIEW:` line is the right
handling, and I tested the contrary reading before accepting it. A
`BASELINE-REVIEW:` line proposes a change to a ledger row's classification;
`F281`/`F282` classify what the *source repositories ship at their pins*, and at
`b08bccfb` py ships nothing, so `ts-only` is accurate and no row changes.
`docs/port/BASELINE-REVIEW.md` adjudicated `COMMON → REUSE` and `ADOPT` rows
only; two `ts-only DIVERGENT` rows were never in its scope, so there is no
existing entry to amend either. The finding form is correct, and the decision's
sentence that the prompt is immutable is right.

The three-repository trajectory the decision draws — py had the capability and
got the failure path wrong, ts kept it and repaired the failure path, rs keeps
both and must additionally solve selection ownership, which neither Python nor
Node ever faced because neither owns the selection — is the clearest statement of
the shared principle in this run, and it is sourced rather than asserted.

## Design and evidence

**The architecture comparison precedes the library choice and is genuine.** Four
alternatives (native crate, shell out, OSC 52, do not ship) each carry a reason
that could have gone the other way, and the runner-up is named with the
condition that would promote it. Alternative B is rejected on a measured fact
rather than a preference: `xclip`, `xsel` and `wl-clipboard` are all absent from
the `ubuntu-latest` image, established against an `xvfb` presence control fetched
in the same request (checks A63–A66) — the pairing is what makes three absences
evidence instead of three nulls. Alternative C is rejected on a property of the
mechanism (fire-and-forget, so failure is undetectable), which is the right axis
for an item whose whole subject is clean degradation.

**Member 3 is the finding that justifies the run, and it is settled on source.**
I checked each of the four reads the decision rests it on. The `arboard` README
carries a *Clipboard Ownership* section and the "the data will be lost" sentence
(A31, A33); the X11 backend serves paste requests from a thread inside the
copying process (A34); the Wayland backend passes `foreground` only for
`WaitConfig::Forever` (A35); and `wl-clipboard-rs` documents `foreground` as a
*thread* switch, with its own doc comment contrasting `wl-copy` the binary, which
forks (A41, A42). Each assertion's text in the log matches what the decision
says it establishes. Codex's one-member stack is not a rejection of Member 3 —
`raw/codex.md` contains no discussion of selection ownership at all — so
"omission rather than considered disagreement" is the accurate characterisation,
and Disagreement 1 is settled on evidence rather than on a vote.

**The other four disagreements are settled on grounds, not on agreement.**
Placement in the binary crate only, behind a default-on `clipboard` feature, is
settled on the principle that the library and web-service builds must link no
desktop dependency, with `nushell/reedline`'s optional + feature-gated shape as
the production instance (A51, A52) and AC5 as the check that makes it falsifiable
— not on Opus's preference. RustSec is settled the only way a 404 can be: the
same endpoint returns 200 for `anyhow`, whose page is backed by an advisory
(A09), and the advisory-db contents API agrees independently (A10, A11); Codex's
caution was right about a bare 404 and the decision says so while closing the
question. `copypasta`'s CI is converted from Codex's impression to fact —
the matrix is `[windows-latest, macos-latest]` and `ubuntu` appears nowhere in
the file (A46, A47). The MSRV disagreement is resolved by correcting *both*
engines from an executed resolution (1.71.0 macOS, 1.86 Linux; S17, S18), and
the decision says plainly that the figure was wrong while the verdict is not,
since both floors sit far below R67's 1.96 floor.

**The new duplicate-resolution finding is correctly scoped, and neither
alternative instrument fits.** I read what R67 actually requires. Its
zero-duplicate result is an integration-cost measurement of its own two-crate
set — "the stack locks **20 packages** with **zero duplicate versions**", empirical
row E13 — and its own unproven row 8 says "Only the dependency *count* (20
packages, no duplicates) was established here". It is not a fitness gate, an
acceptance criterion, or a workspace invariant, so there is nothing for R62 to
fail. A `CONFLICT:` line is the wrong instrument on its own grammar: it names a
registered parameter and a needed value, R62 consumes none, and R67's owned
`error-taxonomy-exit-codes` is untouched by a `hashbrown` duplicate. A re-verify
trigger is not required either, because `## Empirical check` section B already
states that the package counts and the duplicate report are properties of the
resolution date and toolchain rather than of `arboard` 3.6.1. Calling it a cost
to record for P03 is the correct disposition.

**The fatal-versus-warning policy is grounded, and I checked it in both source
repositories rather than accepting the standard citation alone.** At the `ts`
pin, `src/commands/projects.ts` writes the result to stdout or to the
`--output` file and only then calls the injected clipboard writer, throwing
`CliError` on failure; `CliError`'s constructor defaults to `EXIT_CODES.error`
(`src/lib/errors.ts:28-34`), so ts exits non-zero with the result already on
stdout. Pre-removal py did the same shape by accident, exiting 4 from its generic
handler after `console.print(result)`. The standard supports it independently:
R6.3 makes a command that did its main work but failed part of it exit `1`, and
R8.2 assigns exit `1` to runtime failures. So "failure fatal" for a convenience
flag is evidenced, not asserted — the decision's own line 106 gloss
("best-effort side effect") is looser than its must-agree table, but the table is
the operative text and it is precise.

**What the fatal choice collides with is R67's envelope wording, and that is
finding JF-1 below.** The collision is real, it was inherited from `raw/opus.md`
unexamined, and it is the one defect in this decision that reaches an acceptance
criterion.

**Claims are held to what the evidence establishes.** The headless behaviour is
labelled a code-path read and named in Unproven 1 with "A code path read is not
an execution"; the Linux leg is labelled resolved-not-compiled; the
probe-before-spawn ordering is labelled an evidence gap with the reason the gap
exists (`code2prompt`'s `spawn_clipboard_daemon` contains no `Clipboard::new`
probe, check A61, so the best available reference implementation is also the
defect analysis); the `ext-data-control` question is left unresolved with its
blast radius bounded. Six unproven rows, each with what would prove it. The
decision does not implement its own recommendation — the only compiled artefact
is a one-line `fn main` — which is correct for a research programme where P03
builds and proves the template.

## Completeness

Required structure holds. The H2 set is `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines`, with no `## Supersedes` — correct, since
revision 1 reverses nothing. The `re-verify:` line sits at the end of
`## Decision` immediately before `## Parameters`, matching R64 and R67. The
`## Parameters` section opens with four `- assumes` lines and then prose,
matching the convention R64 established.

The four `- assumes` values are byte-identical to the live registry rows
(`docs/port/PARAMETERS.md`, `msrv-policy`, `rust-edition`, `target-os-matrix`,
`license`); I compared them against the registry directly, not through check
A89. No `owns` line is correct: the prompt's `## Couplings` carries an empty
`owns:` and an empty `consumes:`, and R67 appears there as "related (not a
registry dependency)", so discussing `error-taxonomy-exit-codes` in prose rather
than as an `assumes` line is the right treatment. The ledger rows are quoted
correctly against `docs/port/COMMONALITY.md:285-286`. Gate 1 is
`inapplicable` against the real owner ruling — `docs/port/OWNER-REVIEW.md`
carries "2026-09-12 — no licence check for anything the template uses (Q4,
superseded and widened by Q7.B)" — and nothing was excluded on licence.

The figures are stated within the logs. `r62-clipboard-claims.log` contains
exactly 120 `PASS` lines, zero `FAIL`, zero `SKIP`, and its summary reads
`assertions run : 120 / failures : 0 / skipped : 0`; `r62-spike-build.log`
contains 21 `PASS` lines and `assertions run : 21 / failures : 0`. The section
list "0-14" matches the log's fourteen section banners. Each numeric claim I
spot-checked in the decision — A05, A13, A14, A20–A30, A37–A39, A44, A49,
A61, A63–A66, S04–S08, S14, S15, S17–S21 — appears in the log with assertion
text that supports the use the decision makes of it. Every crate figure carries
its endpoint, and the block carries its retrieval date (2026-09-17 UTC, which is
the same clock as the run id and one local day after Codex's 2026-09-16
retrievals — a difference in timezone, not in freshness). The disclosure that the
committed log is the post-write run, preceded by an identical run that reported
one `SKIP` for check A91, is honest and self-reporting; it cannot be checked from
the committed artefact, and it does not need to be.

What is missing is listed as findings below: one fitness-gate field (JF-2), one
required §7.6 figure row (JF-3), and four precision defects (JF-4 through JF-7).

## Findings

**JF-1 — blocking. Acceptance criteria AC2 and AC3 cannot both hold, and the
tension with R67's envelope invariant is unrecorded.**

AC2 requires that on the headless path the command "emits the result unharmed,
and exits `1`". AC3 requires that the same failure under a machine output format
produce R67's stderr object "and **byte-empty stdout**". Those are the same
failure in two output modes, and the must-agree row at
`### Principles and implementation` says the write "happens **after** the result
has reached its primary sink, and never replaces it" — so stdout carries the
result in both modes and cannot be byte-empty in either. The defect is inherited:
`raw/opus.md` states both "The result still reaches stdout unchanged" in its
fatal-policy rationale and `[ ! -s out.txt ]` in its own A3 validation command,
and the synthesis carried the contradiction across without noticing it.

The standard resolves which half is wrong, in R62's favour on the design and
against AC3's wording. R7.8 requires the single stderr error object "for ordinary
command failures, **including a failure that occurs mid-stream**", and R6.3
describes exactly this shape — a command that completed its main work, failed a
part, reports both and exits `1`. Neither rule asks for an empty stdout. R67's
`## Decision` says "stdout stays byte-empty on the error path" and its AC2 repeats
it; that invariant was written for error paths where the command produced no
result, and R62 is the first item in the programme to present a post-result
partial failure. The decision does not surface that at all. It asserts R67
conformance instead, and attributes to check A95 two claims A95 does not make:
A95 asserts only the substring `{"error":{"code","message","hint"?}}`, not
"`hint` omitted rather than `null`" and not "stdout byte-empty on the error path".
Both extra claims are true of R67's text; neither is established by the check
cited for them, and the second is the one R62's own design cannot satisfy.

What this costs: nothing in the recommendation. The three members, the crate,
the version, the feature set, the crate placement and the fatal policy all
survive. What must change is AC3's byte-empty clause, the prose sentence in
`## Parameters` that repeats it, and the addition of the stated tension —
either as a note that R62 qualifies R67's invariant for post-result failures, or
as a re-verify trigger on R67 revisiting the envelope wording. Until that is
recorded, a P03 implementer reading AC2 and AC3 together has no implementable
target, and a downstream reader is told R67 conformance that the design does not
have.

**JF-2 — non-blocking. Fitness gate 3's `unsafe` posture is never stated for
`arboard`.**

The prompt's gate 3 is "no open RustSec advisory; `unsafe` posture stated", and
the tier guidance says an inapplicable metric must be marked `inapplicable` with
its reason rather than omitted silently. The advisory half is answered at length
and well. The `unsafe` half appears nowhere: the string `unsafe` occurs once in
the decision — "*No `unsafe`.* R06 sets `unsafe_code = "forbid"` in the workspace
lint table" — which is a statement about the template's own crates and the reason
re-exec beats `libc::fork()`, not about the selected dependency. Standing alone
in an item whose macOS and Linux backends are FFI, it reads as a claim about the
stack. Both raw reports carry what is missing: Codex records that `arboard` uses
`unsafe` internally in platform FFI, and `raw/opus.md` adds the point that makes
the sentence safe to keep — `unsafe_code = "forbid"` governs first-party crates
only, because Cargo passes `--cap-lints allow` to dependencies. The evidence log
contains no `unsafe` check at all. One sentence repairs it.

**JF-3 — non-blocking. The §7.6 issue-responsiveness figure is omitted.**

The prompt's figure table requires, per crate member, "median days to first
maintainer response; unanswered count" over the ten most recently opened issues.
The decision's figures table carries seven columns and not that one, and the
evidence log collects it nowhere. `raw/codex.md` supplies it — `arboard` one
response at 3.30 days with four unanswered; `copypasta` median 0.22 days with
none unanswered; `clipboard-rs` median 0.83 days with two unanswered — so the
item holds the evidence and only the decision drops it. It is not neutral
housekeeping: `copypasta`'s figures are the most responsive of the three and are
the one datum that pulls against the `at-risk` rubric verdict the decision
assigns it. The verdict still stands on its two concrete signals (sixteen months
with no release and no push, and no Ubuntu job), but a rubric verdict should
weigh the countervailing figure rather than omit it.

**JF-4 — non-blocking. The `re-verify:` line names two alternatives the decision
never defines.**

The line promises that R03 settling toward absence-as-value "promotes Member 2's
ranked runner-up", and that an owner inversion of the fatal policy "promotes
Member 3's acknowledgement-byte alternative". Neither is defined anywhere in
`DECISION.md`; the only ranked runner-up the decision states is architecture B,
shell-out. Both come from `raw/opus.md`, where they are Alternative 2a (a free
function, no port) and Alternative 3a (probe, spawn, wait for an acknowledgement
byte). A controller checking triggers quarterly still reruns the item, so the
trigger functions; its stated consequence is not evaluable from the decision
alone.

**JF-5 — non-blocking. R5.6 is cited for a proposition it does not carry.**

The decision writes "*No payload in a process listing.* Standard **R5.6**
(check A85) is why Member 3 hands the text to the child over **stdin** rather
than `argv`." R5.6 at the cited blob is *Secret redaction in output*: secret
values must be masked in all output, with `--show-secrets` to reveal them. It
governs what a tool prints, not what appears in `/proc/<pid>/cmdline`, and a
copied command result is not necessarily a secret. Check A85 is honest about this
— it asserts only "R5.6 exists" — but the decision's prose promotes existence
into causation. The design choice is right for the ordinary reason (a copied
payload may contain a secret and `argv` is world-readable on Linux); it should
be argued on that reason, with R5.6 cited as motivation rather than as the rule
that requires it.

**JF-6 — non-blocking. "Verbatim" overstates the `nushell` reference.**

The reference table says `nushell/nushell` ships
`arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }`
"verbatim" against a recommendation of 3.6.1. The dependency-line *shape* is
identical and that is what the row is for; the version is not, and "verbatim"
sitting beside two different version strings in the same sentence invites the
misreading.

**JF-7 — non-blocking. The rejected warning policy is not recorded beside the
fatal choice.**

`raw/opus.md` weighs both policies explicitly and records why fatal wins and what
the warning policy would cost. The decision states the fatal conclusion and lets
the alternative survive only as a re-verify trigger ("the owner inverting the
fatal-versus-warning policy"). Since this is the item's one genuinely
owner-flippable policy — and, per JF-1, the one place the design meets R67's
envelope rule — the two-line alternative belongs in
`### Principles and implementation` so the owner sees a choice rather than a
conclusion.

## Assessment

The recommendation does not move under any finding. The evidence supports three
members rather than one, and Disagreement 1 is settled on four independent source
reads that all say what the decision says they say; `arboard` 3.6.1 with
`default-features = false` and `wayland-data-control` is the choice both engines
reached and the one the fitness gates and the executed resolution support;
binary-crate-only placement behind a default-on `clipboard` feature follows from
the library/web-build constraint and has a production instance; and the fatal
policy is grounded in `ts`, in pre-removal `py`, and in the standard's own R6.3
and R8.2. The duplicate-resolution finding is scoped correctly against what R67
actually requires, and neither a `CONFLICT:` line nor a re-verify trigger is
owed. The prompt-gloss correction is handled in the right form, and the unproven
rows are honest about a macOS-only session.

The rejection is narrow and repairable in one edit. AC3 as written cannot be
satisfied by the design the same document specifies, and the reason it cannot —
that R62 is the programme's first post-result partial failure, a shape R67's
envelope wording did not anticipate — is exactly the kind of cross-item tension a
decision must surface rather than assert away. Because that edit reopens the
document anyway, JF-2 through JF-7 should be repaired in the same revision at no
extra audit cost. With those seven repairs and no change to the stack, this
decision should approve on its next round.
