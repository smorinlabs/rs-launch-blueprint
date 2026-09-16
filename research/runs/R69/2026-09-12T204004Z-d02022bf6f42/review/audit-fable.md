decision-sha256: d4d6a8d2a3297a6db488580142de6d651f33b8109e9023994f6cb9f5ecfd6a17
actor: audit-fable-2026-09-12T204004Z-d02022bf6f42-r6
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-4 the decision states twice, as present fact, that the CLI parser its serve binary's required global core is parsed with is still R60's open choice, and keys a `re-verify:` trigger on that selection — but R60's parser selection (`clap` 4.6.6, derive API) was owner-accepted on 2026-09-15 as W0-R60, one day before revision 6, so the statement is false and the trigger has already fired

# R69 web-framework-stack — judgment audit (round 2, revision 6, 2026-09-16)

Round 1 (archived at `review/audit-fable.r1.md`, rejecting revision 1 on JF-1, JF-2 and JF-3) is
the only previous judgment audit; revisions 2 through 6 have had none. This audit therefore
covers the whole current text, not a delta, and re-reads the round-1 findings against it.

## Principle and agreement level

Unchanged from revision 1 in every passage round 1 examined, and still right. The shared
requirement is stated at **capability** level — py, ts and rs must each expose the core library
over HTTP without a mirror data model — with the mechanism named as what must *not* harmonize,
sourced to `docs/port/COMMONALITY.md` rows F303/F330/F331/F338/F339 (all `DIVERGENT`, origin
`py-only`) and `docs/port/DIVERGENCE-ANALYSIS.md` line 217's `harmonize: partly — scope level
only`. The F330 analysis still separates the requirement (every caller of the app object sees a
loaded configuration) from py's mechanism (the lazy fallback) and ports only the first, which is
a preserved principle realized natively. `BASELINE-REVIEW: F330` and `F331` are in the runbook's
four-segment form with affected items and source evidence; the opus raw's `BASELINE-REVIEW: F339`
remains withdrawn with its ground recorded. No `CONFLICT:` line is raised, and the one coupling
that could have produced one is verified rather than asserted.

**Revision 6 does not move the agreement level, and is careful not to let the owner's document do
it.** The document is recorded under `## Engines` as an owner-supplied **input**, with its own
provenance sentence quoted — *"an owner-supplied research input, not a binding standard and not a
decision"* — and with its weight stated exactly: *"agreement is recorded as agreement, not treated
as confirmation ... nothing in this decision now rests on the document."* That is the correct
handling of §11, and it is the handling the mandate requires independently of §11: repository
agreement is not evidence of fitness.

## Design and evidence

**JF-1 is closed.** Round 1's finding was that *"the serve binary's SIGTERM exit code contradicts
R67's published contract, which the decision cites as satisfied, and the drain-deadline failure
exit carries no number"*. The text now carries *The serve binary's process contract — R67's
integers, not this item's*, which names R67 at the sha `16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`
and gives a five-row table: SIGTERM-initiated drain **143** (`RSLB902`), SIGINT-initiated drain
**130** (`RSLB901`), `GracefulShutdownTimedOut` **1**, `ServeError::Io` **1** (`RSLB101`), normal
completion **0**. I recomputed that sha against
`research/topics/67-error-and-exit-code-contract/DECISION.md`: it matches, and R67's owned value
carries the taxonomy `0/1/2/3/4/5/130/143` with "unlisted failures collapse to `1`", the
`ExitCode`-from-`main` rule, the boundary precedence *signal → broken pipe → domain downcast →
unexpected*, and the sentence naming this item — *"R05 ... and R69 (`web-extra-surface`) decide the
web surface's signal source, which must return the same 130/143"*. The drain-deadline branch is
handled the way an append-only catalog owned elsewhere requires: no code is minted, `1` is taken
as R67's own default for an unlisted failure, `RSLB105` is identified as the apparent next free
slot while leaving the token to R67, and the competing reading (boundary precedence making any
SIGTERM-initiated termination 143) is stated as R67's to settle rather than suppressed. The
validation strategy and the unproven table now assert 143/130/1 instead of round 1's "a zero
exit", and a separate paragraph records that the recorded `serve_until` signature
(`S: Future<Output = ()>`) cannot deliver the distinction, with that gap carried as its own
unproven row.

**JF-2 is closed.** Round 1 objected that the fit ground ranking `actix-web` runner-up —
*"the template's CLI, library and future adapters live in one tokio world"* — was stated as present
fact against the decision's own criterion 1. Both locations are now conditional. Alternative E
reads *"**when the `web` feature is on**, the web surface and any future async adapter live in one
tokio world ... `tokio` is absent from the feature-off tree by criterion 1, measured in check 2, so
this is not a claim about the template's default build. **Whether the CLI and library join that
world is R05's open question**"*, and it states what the ground weakens to under a synchronous R05
and that the ranking does not rest on it alone. The `ntex` exclusion row carries the same two
conditions verbatim. That is the repair round 1 asked for, at both of the two locations it named.

**JF-3 is closed, and I verified the closure at the standard itself rather than at the decision's
quotation.** Round 1 objected that `<app>-serve` was fixed at "no CLI flags" without examining the
binding CLI Design Standard. The text now carries *The serve binary's flag surface, under the
binding CLI Design Standard*, which cites `/Users/stevemorin/c/cli-standards/cli-design-standard.md`
v1.4.14, its header scope line, R4.1's opening MUST, and Appendix A's Small-CLI profile leaving
"§4 ... unchanged". I read that file: its latest changelog row is v1.4.14, its `Last updated` is
2026-06-28 as cited, and R4.1's **required global core** table is exactly the six rows the decision
reproduces — `--help`/`-h`, `--version`/`-V`, `--verbose`/`-v`, `--quiet`/`-q`, `--config`,
`--debug` — with the same meanings. The decision's exclusion of the result-output tier is argued
from R4.1's own scope sentence ("commands that emit formatted result data") rather than asserted,
the six options are carried inside the owned value, and the conformance fixture is carried as
unproven with R9.14 named. The inherited-mechanism move round 1 objected to is gone.

**The R01 coupling holds at both ends.** Check 1 remains a transcribed-bound, type-level result,
and the decision still says so — *"a type-level fact about a declared bound"*, with request-path
behavior in the unproven table. I read `review/evidence/state-bound-check.log`: the positive case
builds clean, the by-value twin fails on `Clone`, the supertrait-stripped twin fails on `Sync`, and
the quoted diagnostics in `## Empirical check` match the log. The claim's other end is confirmed at
R01's own published text, which hands this item *"the web state type is
`ProjectsService<Arc<dyn ProjectsPort>>` (`Clone + Send + Sync + 'static`)"* — so the decision's
statement that R01's Router state bound is satisfied by R01's port type is not this item's
inference alone.

**The three rules the task asked me to check for stated limits all carry them.** The
clock-starts-at-the-signal rule is argued on the merits (a whole-lifetime wrapper bounds the
server's lifetime, not the drain), its enabling fact is read at the published artifact
(`axum-0.8.9/src/serve/mod.rs`, `close_tx.closed().await` and zero `timeout`/`deadline`), and the
behavior is unproven with two named tests and a **medium** confidence rating. The bacon SIGKILL
override is stated with the limit that the override's effect on `cargo run`'s grandchild is not
exercised, in its own unproven row. The yanked-lookup disabling and the advisory-db pin are stated
with their cost — the scan no longer reports yanked crates, gate 2's "newest non-yanked" figures
come from the committed snapshots read by check 3 rather than from the scan, and live yanked
detection is P03's CI — and the superseded 55 in `feature-shape-check-r4.sh`'s header comment is
disclosed rather than edited away.

**The §11 reconciliation is honest about its own evidence chain.** Revision 6's two new scripts are
correctly classified as *not checks*: the fetcher goes to the network and writes the reduced
snapshots under `review/evidence/snapshots/r6/`, the checker reads only those committed snapshots
and never the network, and the decision says outright that the fetcher is not rerun in an audit for
the same reason `fetch-figures.sh` is not. The residual limit — the reduction is performed by the
fetcher, so the checker cannot detect a mis-extraction — is inherent to that design and is the same
one checks 3 and 4 already carry; the snapshots are committed, so a later reader can compare them
against the live endpoints. Nothing in the reconciliation prose claims more than the log shows.

## Completeness

Verified mechanically where possible rather than by reading.

- **H2 sections.** Exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in
  that order, outside fences, none added by revision 6, and no `## Supersedes` — correct, since no
  revision of this decision has been published. `### Principles and implementation` sits inside
  `## Decision` and `re-verify:` is that section's final line.
- **Owned and assumed parameters.** I parsed `docs/port/PARAMETERS.md` and compared each
  `- assumes` value to the registry cell exactly: `msrv-policy`, `rust-edition`,
  `target-os-matrix`, `license` and `http-transport-injection-seam` are all **byte-identical**.
  The single `- owns web-extra-surface` line is 2,638 bytes, carries no backtick, no markdown
  link, no double space and no leading or trailing whitespace; the registry cell for that
  parameter is still the placeholder `—`, which this decision sets. Those readings agree with
  `review/evidence/parameters-check-r2.log`, which the decision cites as re-run against revision 6
  with no differences.
- **Owned value against the body.** The value's four gated things match the migration table; the
  R4.1 core inside the value matches the six rows of the standard's table and of the body's own
  table; the exit integers inside the value (143 / 130 / 1 on I/O / 0) match the body's contract
  table, and the body's fifth row — the drain-deadline **1** — is the one the value deliberately
  omits, with the omission and its reason stated in the same sentence. The R60 clause inside the
  value survives JF-4 unchanged (see *Findings*).
- **Fitness gates.** All six answered. Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`
  for every candidate, with no candidate excluded on it and `assert-figures.sh` asserting it
  nowhere. Gate 2 is answered per candidate against the 1.96 floor for the fourteen framework
  candidates and the four dev-loop tools. Gates 3–6 are answered for the two selected compiled
  members, with gate 4's macOS gap closed by an executed build and an executed install on this host
  and the limit of that closure stated, and gate 6 answered as a measured dependency count (12 →
  52) with the wall-clock and binary-size halves carried as engine-reported.
- **Source dates.** 2026-09-13 for the original synthesis, 2026-09-12 for material carried from the
  raws, 2026-09-15 for revision 2's reading of R67 and the standard, and 2026-09-16 for revision
  6's retrievals, each list separated and labelled; the snapshot retrieval times are recorded
  (`2026-09-13T07:57:55Z` for `snapshots/`, `2026-09-16T22:12:37Z` in the r6 log).
- **The five §11 spot-checks the task named all land.** Read at
  `review/evidence/owner-reference-check-r6.log` and the committed snapshots it reads: axum's
  release list (section A — `max_version`, `max_stable_version` and `newest_version` all 0.8.9,
  the ≥ 0.9 set empty across 94 versions); the Cargo caret rule (section B — the Book's
  `0.2.3 := >=0.2.3, <0.3.0` row, "Caret requirements are the default version requirement
  strategy", and "Leaving off the caret is a simplified equivalent syntax"); Google's ten-second
  sentence (section E — quoted verbatim and matching the snapshot, with the neighbouring **jobs**
  sentence asserted alongside so the two cannot be conflated); axum issue #3003 (section F — open,
  not a pull request, reported against 0.7.4, with the quoted claim present); and axum-test
  (section D — newest non-yanked `22.0.0-rc.1` under this item's field rule, newest stable
  `21.1.0` declaring `axum ^0.8.9` at `rust_version` 1.89, with `18.0.0`'s `^0.8.4` showing the
  document's "requires axum ≥ 0.8.7" holds only from 18.3.0). The 0.9 timeline claims are
  likewise sourced rather than repeated: the collaborator comment is quoted with the qualifier
  the document dropped, PR #3745 is recorded closed and unmerged with its three
  `cargo-semver-checks` failures against `axum/src/serve/mod.rs`, PR #3819 is recorded open in
  milestone 0.9, and the document's "highest tag" claim is explicitly **not** re-verified, with
  the reason given.
- **No row belonging to another item is decided.** C4/RFC 9457 is handed to R70 with the R67
  envelope tension named and the question stated rather than answered; the Cloud Run ten-second
  window is handed to R77 as a datum with "Cloud Run is not adopted as a target by this item";
  `cargo-chef` and `mold`/`lld` are handed to R51 and R68 and explicitly neither recommended nor
  excluded; `rust-toolchain.toml` is handed to `msrv-policy` and R42; the crate boundary is left
  to R02 with the owned value phrased to survive either answer; the harness tier is left to R32;
  and the twenty remaining document rows are listed once under `## Engines` with "no position
  taken on any". The rows revision 6 does decide — the `=` operator, the feature list, the test
  idiom, the dev watcher — are all inside this item's own owned surface.
- **Engines.** One line per raw for all five with sha256 and shape-validation state, including the
  honest record that the merged doxa digest fails bundle-shape validation while the three
  per-provider files pass and are what was used; eight disagreements each settled with named
  evidence rather than by vote; the licence-ruling disposition table enumerating every
  licence-based sentence in every raw; eleven unproven rows each naming what would prove them.
- **Re-verify triggers, checked one by one against the repository's current state.** axum has
  published no 0.9 (section A of the r6 log); R58 and R02 are open; `watchexec-cli` still declares
  no `rust-version` and the owner has issued no ruling on whether the MSRV gate reaches non-linked
  developer tools; R67 has not dispositioned this item's request; the standard is still v1.4.14;
  the floor is still 1.96; 2027-03-13 is future. **One trigger has already fired**, which is JF-4.

Two things are worth naming as strengths rather than defects. The decision repeatedly states what
its own evidence does *not* establish — the transcribed bound is not the real crate, the fetcher is
not a check, the figures are a single drifting snapshot, agreement with the owner's document is not
confirmation — and revision 6 answers the one question that could have moved the owned value (the
`=0.8.9` advice) on a primary source rather than on caution, and then records that the value stays
byte-identical *because the question dissolves*, not because moving it was forbidden.

## Findings

**JF-4 (does not move the recommendation or the owned value; unresolved, and therefore verdict-
bearing) — the decision states as present fact that R60 has not selected the CLI parser, and keys a
`re-verify:` trigger on that selection, one day after the owner accepted it.** Three locations:

- `### Principles and implementation`, the flag-surface paragraph: *"This adds **no crate to the
  `web` feature**, on a condition rather than as a present fact: the parser is R60's open choice,
  and whichever crate R60 selects for the CLI binary is a non-optional dependency of the
  package"*.
- The unproven table, the global-core row: *"The rule and its scope are read at the standard ...
  no binary exists to run, and **R60 has not selected the parser**."*
- The `re-verify:` line: *"when R60 selects the CLI parser the serve binary's global core is parsed
  with"*.

**The problem.** R60's parser selection is made and owner-accepted. `docs/port/OWNER-ACCEPTANCES.md`
records `R60 | 7 | 67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2 | accept |
2026-09-15 | W0-R60 option A; clap 4.6.6 derive, clap_complete 4.6.9, dependency-free build.rs`,
and `docs/planning/p02/owner-decisions.md` section 10 carries the same W0-R60 row. The decision file
those records bind is `research/runs/R60/2026-09-05T183002Z-09f93cfc507c/review/DECISION.md`, now at
revision 8 (2026-09-16), which still selects `clap = { version = "4.6.6", features = ["derive", …] }`
and `clap_complete` 4.6.9. R60 is `open` in `research/CLAUDE.md` only in the sense that its decision
is not yet published — the acceptance row says "first publication pending" — and this decision's own
vocabulary already distinguishes the two: it cites R49 as having "selected alternative A1" while
labelling that revision **unpublished**. So "R60 has not selected the parser" is false as written,
and the `re-verify:` trigger names an event that occurred on 2026-09-15. Revision 2 (2026-09-15)
could not have known; revision 6 (2026-09-16) read `docs/planning/p02/owner-decisions.md` for
section 11, and the W0-R60 row is in section 10 of that same file. The consequence is not cosmetic
for a keystone the owner is about to bind at a sha: on its own terms the decision would be due
re-verification the moment it is accepted, on a trigger that has already fired.

**What does not follow from it.** Nothing in the recommendation moves, and the owned value moves
**not at all**. The claim the stale sentence supports — that the serve binary's global core adds no
crate to the `web` feature — is *strengthened*, not weakened, by the accepted answer: `clap` 4.6.6
is a non-optional dependency of the package for the CLI binary, so the serve binary reuses it and
check 2's 12 → 52 delta stands by construction exactly as the decision argues. The owned value's
wording, *"parsed with the parser crate R60 selects for the CLI binary, which is a non-optional
dependency of the package whichever crate R60 picks"*, survives the correction verbatim.

**To resolve.** (1) Replace the two present-fact sentences with the accepted fact — R60 revision 7,
owner-accepted 2026-09-15 as W0-R60, selecting `clap` 4.6.6 with the derive API, publication
pending — cited to `docs/port/OWNER-ACCEPTANCES.md`, and keep the global-core row unproven on the
ground that remains true (no binary exists to run, and the R9.14 fixture has not been written).
(2) Reword or retire the `re-verify:` trigger; "when R60 publishes" would match the verb the R58 and
R02 triggers already use. (3) Leave the `- owns web-extra-surface` line **byte-identical** — naming
`clap` inside an owned value that 19 consumers read would buy nothing and would re-open check 6 for
a phrase that already survives either answer.

**Observations, recorded explicitly as not findings** — none requires a change, and none is carried
into `unresolved-findings`:

1. The owned value's exit clause reads *"1 on an I/O failure, and 0 otherwise, ... with the
   drain-deadline branch deliberately left out of this value"*. The carve-out is in the same
   sentence as the catch-all, so the value is internally coherent, but a consumer reading only the
   value could take "0 otherwise" to cover the timed-out drain, which the body numbers **1**. If a
   future revision touches this line for another reason, "and 0 otherwise" would be better as "and
   0 on a normal completion".
2. `axum-test` is now evaluated and not selected, but it does not appear in `## Decision`'s
   **Not selected** list; its ground lives at Disagreement 3 instead. That placement follows owner
   decision 11's "no new H2" constraint and the list's own pointer to *Excluded by gate and by
   fit*, so it is defensible; a reader scanning the list alone will not learn the crate was
   considered.
3. The prose dates for issue #3809 (closed 2026-06-30), PR #3745 (opened 2026-05-05) and issue
   #3003 (opened 2024-10-21) are present in the committed r6 snapshots but are not among the
   fields `owner-reference-check-r6.sh` asserts. The sentence *"All four facts are asserted in ...
   section C"* is accurate for the four facts it enumerates, and the dates are verifiable in the
   committed snapshot the log names, so this is a precision note rather than an overstatement.

## Assessment

The recommendation follows from the evidence as written, and I would not disturb it. `axum` 0.8.9
on `tokio` 1.53.1 behind one additive, off-by-default `web` feature is reached by comparing five
architectures before any crate is weighed, decided on a mechanism discriminator with a source
(actix-web's own `Data<T>` 500-under-traffic documentation) rather than on adoption figures,
refuses the one benchmark composite it could have leaned on and says why, names the condition under
which the runner-up wins, and separates what this run verified from what P03 must prove in eleven
rows that each name the proving check. `tower` as a dev-dependency only is settled by a measurement
(`cargo tree --invert tower`), not by preference. `bacon` is selected on gates and maintenance with
its worse kill-signal behavior stated against it and repaired by a required `bacon.toml`. The
`State` + `FromRef` and feature-gated `[[bin]]` shapes are the ones the reference implementation
uses, read at a recorded commit. The three round-1 findings are all genuinely closed, each at the
normative document round 1 pointed to rather than at a paraphrase of it, and revision 6's
reconciliation with the owner's document honours owner decision 11 on every count I could test:
every reference claim re-verified at a primary source and asserted against a committed snapshot, no
row belonging to another item decided, hand-offs recorded as hand-offs, no new H2, and the
document's standing stated so that agreement with it is never mistaken for evidence.

The verdict is nonetheless `reject`, because the role contract admits `approve` only with no
unresolved findings and JF-4 is unresolved. I want the two halves of that stated separately so the
W0-R69 brief is not mis-built. **Neither the recommendation nor the owned parameter value moves
under JF-4** — it is a prose repair to two sentences and one `re-verify:` clause, and the fact that
corrects them makes the surrounding claim stronger rather than weaker. A revision 7 that makes that
repair, changes nothing else, and re-runs only `parameters-check.sh` (which will again report no
differences, since the `## Parameters` block is untouched) would carry no finding from me. The bar
this programme has applied all week is the reason I do not waive it: revision 4 was rejected for a
single mis-transcribed count in a revision note, and revision 5's own text says that a decision
carrying a known-false empirical figure in its body "is the defect being repaired, not a record
worth preserving". A false statement about a sibling item's settled state, sitting in the text that
33 consumers inherit and in the maintenance trigger the owner's acceptance will bind, is the same
class of defect and deserves the same treatment.
