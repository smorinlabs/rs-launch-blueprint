decision-sha256: 39f0df0410126a90f966b23f947939eba5be8c30b4299c85487e1ce8d050b661
actor: audit-fable-2026-09-05T183457Z-3c53ded23d05-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

I read `inputs/prompt.md`, `raw/codex.md`, `raw/opus.md`, `review/DECISION.md`,
`review/audit-codex.md` (r2) and `review/audit-codex.r1.md`, `docs/port/PARAMETERS.md`,
`docs/port/BASELINE-REVIEW.md`, `research/RUNBOOK.md` §4-§5, and the rows this item touches
in `docs/port/COMMONALITY.md`, `docs/port/OWNER-REVIEW.md` and
`docs/port/DIVERGENCE-ANALYSIS.md`. I verified the gate-2 withdrawal record in
`docs/planning/p02/execution-ledger.md` directly, and cross-read R63's and R67's published
decisions where this one cites them. I did not rerun `verify.sh`; that is the empirical
audit's job and it did (`review/audit-codex.md`, family openai, approve).

## Principle and agreement level

**The principle is stated at the right level, and the level is argued rather than asserted.**
P1 is written as a *capability plus policy* — all three repos should page interactive long
text and obey the user's configured pager — with the mechanism (subprocess plumbing,
tokenizer, stream ownership) left ecosystem-local. P2 (paging must never change what a
non-interactive consumer sees) and P3 (a pager failure must lose no output and change no exit
status) are written as *policy*, i.e. must agree everywhere. That split is the one the
evidence supports: P2 and P3 are statements about observable behaviour that every ecosystem
can implement identically, while the things placed under "may justifiably vary" — the
tokenizer, the TTY primitive, buffering versus streaming — move no acceptance criterion. I
checked that last claim against A1-A12 rather than accepting it: none of the twelve is
sensitive to which splitter parses `PAGER`, and A9 (SGR bytes reach the pager unmodified) is
satisfied by either stream-ownership style.

**The native design is justified, not copied.** py buffers into a `rich` capture and rs
streams into the child; the decision gives the ecosystem reason (py's renderer is a `Console`
that owns its file handle, Rust's `dyn Write` seam makes the sink a parameter) rather than
calling py's shape wrong. Conversely py's height gate is *not* inherited, and the reason is
argued from four reference implementations plus py's own ADR 0008 conceding the `less -F`
half. This is the spec §2 / A5 shape: same intended outcome, native mechanism, both directions
explained.

**Drift versus justified difference is handled honestly, including its uncertainty.** ts's
absence is classified as unconsidered omission, on a grep of the ts pin returning no file plus
`DIVERGENCE-ANALYSIS.md:202`, and the decision itself surfaces `:303`, the recorded caveat
that the class-D assignment rests on an inference. Stating the weakness of your own
classification is the correct handling, and no ts change is requested.

**Owner direction is used for what it settles and no more.** I read `OWNER-REVIEW.md:105`: the
disposition is `accept` with the owner's words quoted verbatim and correctly. It settles
adopt-or-omit, which is why the prompt's first HIGH question ("should this row be recommended
for omission?") is answered by owner direction plus alternative A's rejection rather than by
researcher preference. The decision says exactly this and does not over-read the quote: the
owner said "architectural pattern, not the exact library", and the decision does not claim
owner cover for the library choice.

**`BASELINE-REVIEW:` handling matches the runbook, and the count is complete.** I checked
that three is the whole set rather than the set the decision chose to carry: the raws contain
exactly three distinct findings — `raw/opus.md` emits two (`BASELINE-REVIEW: F285` and
`BASELINE-REVIEW: F284`, at lines 113 and 115; its six other occurrences of the token are
back-references to those two) and `raw/codex.md` emits one (`F284/F285`). None was silently
dropped. All three lines are carried verbatim,
labelled *not resolved*, each with what this review verified and — the part that matters —
what it did not. The F284 line is explicitly *qualified as broader than its evidence*: `-F`
supplies the display effect only for `less` or a pager honouring `-F`, and does not supply the
other two things py's gate supplies (no paging of short output under `PAGER=more`, no child
spawned at all). The four-file grep is bounded to those four files rather than to four
codebases. `docs/port/BASELINE-REVIEW.md` carries no F284/F285 row — that file adjudicates
`COMMON → REUSE` and `ADOPT` rows, and these are `py-only`/`DIVERGENT` — so there was no row
to reconcile, and RUNBOOK §4 makes adjudication the controller's. The decision edits no
ledger, index or registry file, which I confirmed is consistent with its own statement.

**No `CONFLICT:` line, and the absence is correct.** The item owns and consumes nothing (the
prompt's `## Couplings` block has both fields empty), and neither raw emits a `CONFLICT:` line
— both state in their own words that none is raised, so the decision inherits no conflict it
could have suppressed. The one cross-item demand — that the
`SIGINT` path finish the pager before `main` returns its `ExitCode` — is an ordering
constraint, not a changed value, and I checked it against R67's published decision rather than
taking the decision's word: R67 fixes `RSLB901` SIGINT → 130, `BrokenPipe` on the *result*
stream → exit 0 silently, `main` returning `ExitCode` without `process::exit` on the error
path, and AC4 "destructors run and streams flushed". R64's constraint is compatible with all
four and is arguably already satisfied by AC4; stating it anyway, with the `less -FRXK`
fallback if R67 declines, is conservative rather than wrong. R67 also records that no
`SIGPIPE` handler is installed, which is what makes A10 reachable at all — so the one
environment assumption A10 depends on is carried by the item that owns it.

## Design and evidence

**The architecture alternatives are genuinely compared, and each rejection is tied to a
principle rather than to popularity.** B (self-redirect) is rejected on three structural
counts — nothing left to fall back to after the redirect (P3 fails), a whole-process side
effect (A11 unguaranteeable for a crate that is also a library), and `Pager::with_env`
*substituting* the consulted variable rather than layering it above `PAGER` (the two-tier
chain is unrepresentable). C (in-process) is rejected because such a pager never consults the
user's configured pager, contradicting P1 at the root — and the decision then records where C
*is* right (bat's `PAGER=builtin`, jj's `:builtin`), which is the mark of a real comparison
rather than a strawman. D is selected and matched to three maintained implementations read at
pinned tags. Note that git itself takes shape B and the decision says why git can afford it
(it owns its whole process) instead of treating the most authoritative implementation as
automatically right.

**The library selection follows from the gate, and the gate reading is not this item's to
choose.** This is the load-bearing question for revision 2, because the recommendation
reverses on no new evidence. I checked the withdrawal record myself rather than through the
evidence log: `docs/planning/p02/execution-ledger.md` records "RULING WITHDRAWN: fitness gate 2
is read strictly", the controller's reason (the prompt quotes the policy in full, declaration
and CI included, and gates are answered before popularity), and — decisively for the charge of
back-fitting — the consequence sentence written by the controller *before* this revision
existed: "R64 must change its selection to the runner-up it already recorded, which declares a
version and has a matching continuous-integration job, because its current pick declares
none." The decision does exactly that. The reversal is the application of an external, dated
rule to unchanged facts, not a re-weighing of the same evidence to a new conclusion.

**The evidence that lost is preserved and correctly ranked rather than deleted.** `bat`
(`Cargo.toml:36,54`, the crate is present *because of* paging) and `delta` (`Cargo.toml:51`,
`output.rs:120`) use `shell-words` for this identical job, and `shell-words` carries
`#![forbid(unsafe_code)]` against one unchecked UTF-8 conversion on `shlex::split`'s path.
Both survive in the document as the runner-up's case, with the prompt's own ordering rule
quoted as the reason they cannot promote a candidate that fails a gate. The adoption figures
are used for what they are — general adoption, roughly six times — and the decision states
plainly that no surveyed Rust tool uses the `shlex` crate for *this* job. A decision that hid
that asymmetry would be the one to reject; this one leads with it.

**Environment-dependent claims are scoped to what was observed.** This is where a pager
decision is most likely to overreach, and I tested each claim against its stated observation:
the SGR/`less` behaviour is bounded to `less 668` on this macOS host under a pseudo-terminal
and explicitly *not* claimed as an observation of py; git's injection is observed with
`git 2.50.1 (Apple Git-155)` while the mechanism is read separately at tag v2.51.0, and both
are named; the `-F` claim is qualified as above; presence of `less` on either hosted runner is
recorded as **unproven** with the one-line CI step that would prove it, and two design
consequences (the `NotFound` fall-through, stub-pager assertions) are built in so the gap
cannot break anything; identical tokenizer behaviour across Ubuntu and macOS is established by
source reading and called **weaker than a green macOS job** in those words. The stub-pager
paragraph's second reason is the load-bearing one and is labelled so. I found no claim about
TTY state, `PAGER`/`LESS` handling or SIGPIPE asserted more broadly than the evidence supports
(one heading-level imprecision is noted below and changes nothing).

**Nothing is asserted as proven that the evidence did not show.** The whole "why D preserves
each principle" paragraph opens by stating that none of it is an executed result and that
A1-A12 are what would establish it. The `shlex` test run (7 unit tests, 1 doctest, macOS,
Rust 1.98.0) is carried from the Codex raw and labelled not re-executed, and labelled evidence
about the crate rather than about a template. Binary size, compile time and performance are
each recorded as unmeasured, with the raws' one quantitative spawn-cost statement deliberately
not repeated because it carries no workload or configuration. Gate 6 is answered
qualitatively and says so. This is the correct posture for a research programme whose template
does not exist: the decision does not implement its recommendation and must not be faulted for
declining to.

**The empirical check verifies the claims it is cited for.** The check's scope is stated in
both directions — what it does (pinned repository reads, immutable published crate artifacts,
registry/GitHub/RustSec endpoints, two pseudo-terminal observations) and what it does not (no
crate scaffolded, no `Cargo.toml` written, no `cargo build` or `cargo test`). The gate-2
evidence is read at the *published 2.0.1 artifact* rather than at a moving branch, which is
the version the recommendation names; that is a real improvement over revision 1 and the
decision says which reading it replaces. Capability-to-fail is demonstrated rather than
asserted, by retaining the first run that failed three assertions and exited 3, with each
failure diagnosed as a defect in the check and not in a finding. The cross-run comparison rule
sorts lines into three classes and names the live fields explicitly; I regard class (c) — the
unpinned-but-stable sources, each backed by a named assertion — as the part most likely to be
got wrong elsewhere, and it is got right here. I recomputed the four artifact hashes the
decision cites (`verify.sh`, `r64-pager-claims.log`, `r64-pager-claims.r1.log`,
`verify-first-run.log`) and all four match the document.

**The audit-codex rerun is consistent with the decision.** `review/audit-codex.md` binds the
same decision sha256, reports 103 assertions and 0 failures, reproduces the two-timestamp
rerun diff and attributes the third difference (`jj`'s `pushed_at`) to the live-field class
the decision's own rule names, and confirms the six protected regions byte-identical (133
lines, zero differences) against the revision-1 blob. Its four findings assert nothing the
decision does not, and nothing the decision asserts is contradicted by it. `audit-codex.r1.md`
is the rejecting audit whose two findings the revision note describes, and `audit-codex.md`
hashes identically to `audit-codex.r2.md`, so the archival claim in the revision note holds.

## Completeness

**Required fields.** RUNBOOK §5's H2s are all present and non-empty: `## Decision` (with
`### Principles and implementation` and a `re-verify:` line), `## Parameters`,
`## Empirical check` (toolchain, host, command, working directory, observed output),
`## Engines` (both reports, seven disagreements, the evidence that settled each, and an
explicit unproven list). `## Supersedes` is absent and correctly so: it is required for a
reversal of a *published* decision, and revision 1 was rejected at empirical audit and never
published. The revision note carries revision 1's sha256, both findings and what changed,
which is the revision discipline this case calls for.

**Parameters.** `owns:` and `consumes:` are both empty in the prompt's couplings block, so no
registry row is registered and none is formally consumed; the four fixed parameters appear as
`- assumes` lines and I compared each against `docs/port/PARAMETERS.md:7-10` — `msrv-policy`,
`rust-edition = 2024`, `target-os-matrix = ubuntu-latest, macos-latest` and
`license = MIT OR Apache-2.0` all match the registry's own wording. The MSRV floor of 1.96 is
derived from a dated stable-channel read and is the parameter the decision says selected the
tokenizer — correctly, since it is the policy's declaration-and-CI clauses, not its numeric
window, that separate the candidates. The two unregistered values (`RSLB_PAGER`, `less -FRX`)
are labelled derived and unregistered, with the grep that shows no parameter owns an env-var
prefix and the consequence if a later item registers one (rename, no design change). The
one-flag divergence from `clig.dev`'s `less -FIRX` is recorded rather than dropped.

**Fitness gates.** All six are answered per candidate, and `terminal_size` is explicitly
recorded as excluded on *fit* rather than on a gate, which keeps the two categories distinct.

**Fitness gate 1 (licence) — the point the 27-decision licence sweep raised, verified.** I
confirm the sweep's conclusion: **R64 carries only a passing licence mention and needs no
revision for the owner's 2026-09-12 ruling (Q7.B).** The verification, rather than the
assertion:

1. Gate 1 separates nothing. The comparison table records `pass` for `shlex` 2.0.1
   (`MIT OR Apache-2.0`) and `pass` for `shell-words` 1.1.1 (`MIT/Apache-2.0`, the older slash
   spelling). A gate both candidates clear cannot have selected either, so striking it leaves
   the selection exactly where it is.
2. No exclusion rests on it. I read the `**Excluded, with the reason.**` paragraph
   item by item: `shell-words` on gate 2; `pager` 0.16.1 on architecture B; `minus` 5.7.2 and
   `sapling-streampager` 0.12.0 on architecture C; `terminal_size` 0.4.4 on not being needed.
   None is a licence exclusion, and none becomes unsupported if gate 1 is struck.
3. No re-verify trigger is a licence event. The `re-verify:` line names advisories,
   archival, a `shell-words` release declaring `rust-version` plus CI, an overturned gate-2
   reading, and five item couplings. Compare R33, which had to *remove* a licence trigger when
   the ruling landed; R64 has none to remove.
4. The repository's own declared expression is untouched, as the ruling requires. The
   `- assumes license = MIT OR Apache-2.0` line records the registry's fixed value for this
   repository and stays valid.
5. The residual is cosmetic and needs no edit. The `## Parameters` sentence "The **licence**
   is satisfied — the selected crate declares `MIT OR Apache-2.0` … nothing in the tree is
   copyleft" performs a dependency-licence reading the programme no longer performs. It
   supports no verdict in the document, which is the same treatment R33 settled on (licence
   reads "retained as recorded fact … no verdict now rests on them"). Recording gate 1 as
   `inapplicable` with the ruling's reason would also be correct; not doing so costs this
   decision nothing, because striking gate 1 changes no selection and leaves no exclusion
   unsupported.

I therefore raise **no finding** about licence, and I confirm the licence review's conclusion
for R64 was right.

## Findings

**No unresolved findings.** The recommendation follows from the evidence, the evidence
establishes what the decision claims for it, and what it does not establish is listed as
unproven with what would prove it.

Three precision notes, recorded for the controller and deliberately **not** raised as
findings, on the treatment R18/R45 established: none of them changes a selection, an
exclusion, a parameter or an acceptance criterion, and editing the decision for them would
unbind both audits for a full round.

1. **A factual misstatement about R33, in `## Engines`, Disagreement 1.** The sentence "The
   programme's apparent precedent both ways — R63 excluding four crates on gate 2 for an
   undeclared `rust-version`, **R33 selecting a stack containing two crates that declared
   none** — is now settled the strict way for every crate item" is not supported by any record
   I can find, and is contradicted on its natural reading. R33's published decision records
   `rust_version` for all three selected members (`proptest` 1.85, `insta` 1.66.0,
   `cargo-insta` 1.66.0), and R33's own evidence log shows a declared `rust_version` for
   *every* crate it surveyed, including `quickcheck` 1.85.0, `expect-test` 1.60.0 and
   `proptest-derive` 1.84 — no null value appears anywhere in it. Revision 1 said "two
   *surveyed* crates carried none", which is also unsupported; revision 2's rewrite narrowed it
   to the selected stack and thereby made it more specific and more wrong. R64's own evidence
   log contains no R33 check at all, so nothing in the retained script backs the clause. Two
   further notes for the controller: the R63 half of the same sentence *does* check out (R63
   excludes `cliclack` 0.5.6 on gates 2 and 4 with exactly the quoted `.github` criterion, and
   lists four candidates at `rust_version: None`); and "settled the strict way **for every
   crate item**" is broader than the ledger, which records that R63's exclusions stand
   unchanged, that R64 must change its selection, and that "the two items will now read the
   gate the same way" — it says nothing about R33 or about every crate item. Why this is not a
   finding: the reversal's stated reason is the controller's withdrawal record, which I
   verified independently and which names R64 by name; the R33 clause supports no selection,
   and if anything it understates the consistency of the precedent rather than propping the
   recommendation up. The repair, whenever this document is next opened — not as a
   pre-publication edit, which would re-hash the decision and unbind both audits for a clause
   that decides nothing — is to strike the R33 clause and narrow "every crate item" to the two
   items the ledger names.

2. **Gate 4 is read two ways inside the paragraph that promises an exact count.** "The count,
   stated exactly" records `shell-words` as failing **two** gates, 2 and 4, while `shlex`
   passes gate 4 "on source rather than on a badge". But the source answer the next paragraph
   gives covers both crates in its own words — "every `cfg(` in **either** crate's `src/` is a
   `feature`, `test` or `doc` gate, and **neither** contains `target_os`, `cfg(unix)` or
   `cfg(windows)` code" — so on the reading that rescues the selected candidate, the runner-up
   clears gate 4 too, and the honest count is one gate failed, not two. This does not touch the
   outcome: gate 2 alone excludes `shell-words`, the `**Excluded, with the reason.**` paragraph
   cites only gate 2, and the runner-up's stated return condition (a release declaring
   `rust-version` *and* a CI workflow testing it) would restore it under either reading. It is
   worth recording only because the paragraph's own claim is exactness.

3. **One bullet heading is broader than the argv in its own body.** "**OBSERVED — a bare
   `less` does lose the colour**" introduces observations of `less -F` with `LESS` unset,
   `less -FR`, and bare `less` with `LESS=FRX` — a bare `less` with `LESS` unset was not among
   them. The substantive claim is unaffected (`-F` does not touch control-character handling,
   and `less` 668's own manual on `-R` is quoted in the same check), and the F285 carry-forward
   states the argv precisely. A reader quoting the heading alone would state slightly more than
   was run.

## Assessment

Revision 2 is a decision whose recommendation reverses without new evidence, which is the
hardest shape to audit for judgment, because the temptation is to read the rule so that it
produces the desired answer. It does not do that. The rule is external, dated, recorded by the
controller, argued for by two auditors against the controller's own provisional reading, and
its consequence sentence names R64 and specifies the change before this revision was written.
The facts the rule is applied to are read at the published artifacts of the exact versions
named, from two independent sources for the declaration half and from inside the 2.0.1 release
artifact for the CI half. The evidence that pointed the other way is neither deleted nor
argued away: it is preserved, ranked below a gate on the prompt's own ordering rule, and
restated as the cost of the selection and as the runner-up's standing case, with a single
checkable event that reopens the comparison.

The document also does the two things this programme most often finds missing. It separates
proven from unproven precisely where a pager decision is most environment-dependent — the
pseudo-terminal observations are bounded to the `less` and `git` builds on one macOS host,
runner pager presence is unproven with the CI step that would prove it and with two design
consequences that make the gap harmless, and cross-OS tokenizer behaviour rests on source
reading that the decision itself calls weaker than a green job. And it states what the change
costs rather than claiming it costs nothing: the `Option` return with no `Display`, so P03
must compose the A8 hint itself; the rule that only `split` may be called; the one structural
change to the renderer's signature; and the streaming design's own cost, that the child is
spawned before rendering completes.

The three notes above are precision defects in supporting text. The first is a false statement
about another item and should be struck at publication; none of the three touches the
principle, the architecture comparison, the gate reading, the selection, the exclusions, the
parameters or the twelve acceptance criteria. I confirm, as asked, that fitness gate 1 is a
passing mention in this decision and is not load-bearing anywhere in it: striking the gate
changes no selection and leaves no exclusion unsupported, so the licence review's conclusion
that R64 needs no revision is correct.

Approve.
