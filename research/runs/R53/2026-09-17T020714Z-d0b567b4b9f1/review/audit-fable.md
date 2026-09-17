decision-sha256: be59d65bfa7ee087766a315af09c0ba4c93a8fa211927091314c86222cbb9af9
actor: audit-fable-2026-09-17T020714Z-d0b567b4b9f1-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Judgment auditor for R53 (`config-schema-validation`, kind `crate`, Focused tier, owns
nothing), **revision 2**, round 2. Same auditor as round 1; I produced none of this item's
artifacts. Round 1's report is preserved byte-identical at `review/audit-fable.r1.md`
(sha256 `f498961d1e07824e2f54bd7d8f21fcb2eefab08d4cffa8d8977bea376ba5788f`), which rejected
revision 1 on JF-1 with JF-2 to JF-4 non-blocking. The hash above was taken before I read
revision 2 and again before this file was committed, and did not move. I confirmed the
revision-1 baseline independently: `git show c893fb0~1:…/review/DECISION.md | shasum -a 256`
returns `62f5c9f7…`, the value round 1 bound, so the diff I read is the diff between the
audited version and the current one. The empirical (Codex) audit still has not run, so this
remains a single-auditor round and acceptance still needs the second verdict.

Gate 1 remains `inapplicable` by the owner's ruling of 2026-09-12; I raise no licence finding.

**The four round-1 findings are closed.** All four, JF-1 by executed evidence rather than by
carrying the raw. One new non-blocking precision note, JF-5, is recorded below; it does not
bear on the recommendation, the runner-up ranking or any gate disposition, and I approve.

## Principle and agreement level

Unchanged and unchallenged. The diff touches no part of `### Principles and implementation`
except the determinism paragraph (JF-3) and adds no requirement, so round 1's assessment
carries: the shared requirement is stated as a behaviour, the agreement level is fixed at
"an **architectural pattern plus an observable standard**, not a library", F228 and F229 are
cited correctly at `docs/port/COMMONALITY.md:232-233`, and no `OVERRIDE (OV-nn)` is owed
because F229's own Notes anticipate the substitution. The `re-verify:` line is byte-unchanged.

One addition sits inside this territory and I checked it rather than waving it through. A new
sentence under the R55 coupling states that "**R53's per-key loop supplies leaf-level dotted
paths and free unknown-key detection** — every key present in the parsed table that the loop
did not consume — which is exactly what R55's own re-verify trigger watches; R55 decides what
to do with both, and nothing here constrains that choice." The claim about R55's trigger is
accurate at source: R55's `re-verify:` line lists "R53 publishing (whether validation runs
through `serde::Deserialize`, whether it owns unknown-key policy and therefore whether
`serde_ignored` belongs to this item, and whether cross-field invariants are fatal)", and
R55's own `:10` records `serde_ignored` as "recommended **contingent on R53**, which owns
schema validation and may decide unknown-key handling itself". The sentence supplies exactly
the two facts that trigger asks for and decides nothing on R55's behalf, which is consistent
with revision 1's position that the unknown-key *policy* is R55's. It is a real improvement,
not scope creep.

## Design and evidence

**Nothing moves.** I checked this structurally rather than taking the revision note's word.
The diff is ten hunks. The recommendation sentence, the runner-up sentence and their version
ranges are untouched; the `## Parameters` block is untouched, and I re-ran the byte comparison
against the registry on the *new* file — all five `- assumes` values are still byte-identical
to `docs/port/PARAMETERS.md` (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`,
`error-taxonomy-exit-codes`), there is still no `- owns` line, and the H2 set is still
`## Decision`, `## Parameters`, `## Empirical check`, `## Engines` with no `## Supersedes`.
No gate disposition reverses: `validify` stays excluded on maintenance, `garde` stays
`at-risk`, gate 4 stays satisfied by portability with the template's own `macos-latest` job as
the receipt. No candidate is admitted or excluded by the new evidence.

**The diff contains only what is claimed.** Mapping the ten hunks: the revision note and
finding table (new); the R55 coupling sentence discussed above; the determinism paragraph
(JF-3); the new per-candidate gate table and its two method paragraphs (JF-1); the
runner-up's three grounds re-sourced (JF-3); the commands and observed-result block (JF-1,
JF-4); the reproducibility paragraph (JF-4); the not-proven list, where `serde`'s `unsafe`
posture is removed *because it is now audited* and the transitive limit is added (JF-1); the
Codex quotation (JF-2); one `G34`/`G35` citation inserted into Disagreement 1; and the
not-re-read list correction (JF-1). Every hunk is attributable to a round-1 finding or to the
two disclosed additions. `review/evidence/verify.sh` and `review/evidence/r53-verify.log` are
untouched by `c893fb0` — I confirmed with a path-scoped `git show --stat`, which returns
empty — so the 117-check body of evidence round 1 examined is carried forward unaltered, not
re-derived.

**The new check is real evidence, not a restatement.** `r53-r2-gate-posture.sh` fetches each
candidate's published `.crate` tarball at an exact version, extracts into a `$TMPDIR` vendor
directory deleted by an `EXIT` trap, and censuses with `/usr/bin/grep -n -w 'unsafe'` by
absolute path over every `.rs` file. Its log reports `checks run: 37`, `failures: 0`,
`skips: 0`, and an independent count of line-initial `PASS ` / `FAIL ` / `SKIP ` gives
37 / 0 / 0. All 37 identifiers `G01`–`G37` resolve to result lines, every one a content
assertion. Two design choices are worth naming because they are what make a null result
admissible: every matching line is printed beneath its count, so the count is auditable
against the listing rather than trusted, and the census is stated as run over the whole tree
and never a `head`-truncated prefix. Nothing is compiled and nothing is written into the
repository, which keeps the check on the verification side of the programme's line against a
decision implementing its own recommendation. I confirmed the shellcheck claim independently:
`shellcheck` at `/Users/stevemorin/.local/bin/shellcheck` exits 0 on the new script with no
finding.

**`garde`'s default-path `unsafe` is surfaced honestly, and the arithmetic reconciles.** The
log's listing gives `garde` 0.23.0 seven matching lines, which I classified from the printed
listing myself rather than from the table: `src/rules/pattern.rs:122,139,140,149` (four),
`src/i18n.rs:402,414` (two) and `src/error/rc_list/mod.rs:93` (one). The check's own split
matches — `G05` = 7 total, `G07` = 4 in `pattern.rs`, `G06` = 2 in `i18n.rs`, `G08` = 1 in
`rc_list` — and 4 + 2 + 1 = 7, so no line is double-counted or dropped. The gating evidence is
the right evidence for the question asked: `pattern.rs`'s `regex_js_sys` module header is
printed with `#[cfg(all(target_arch = "wasm32", target_os = "unknown"))]` (`G16`, `G17`),
while the two modules carrying the other three sites are printed with their declaration lines
and **zero** `cfg` attributes above them — `mod rc_list;` at `src/error.rs:6` (`G18`, `G19`)
and `pub mod i18n;` at `src/lib.rs:4` (`G20`, `G21`). The decision reports the adverse half in
its own words rather than burying it: "**adopting `garde` adds three `unsafe` sites on the
default build path**, one of them a `transmute` in the allocator-free list that backs its
error `Path`", and it puts that in front of anyone acting on re-verify trigger 6. It also
declines the easy asymmetry, recording that the *recommended* crate is not `unsafe`-free
either — `serde` carries two `str::from_utf8_unchecked` calls (`G01`, `G02`), mirrored in
`serde_core` (`G03`), with `serde_derive` at zero (`G04`) — so "the finding does not separate
the recommendation from the runner-up in the template's favour by accident." That sentence is
the test of whether a late-added gate was answered honestly or steered, and it passes.

**The "no exclusion" reasoning under R06 is correct at source.** R06
(`research/topics/06-unsafe-code-policy/DECISION.md`) forbids `unsafe` in the template's own
code through `[workspace.lints.rust] unsafe_code = "forbid"` (`:24`), and its own MEDIUM row
states the dependency-tree distinction in exactly the terms revision 2 uses: "state that
`forbid` is crate-local because Cargo passes `--cap-lints allow` to dependencies" (`:53`). So
a dependency's `unsafe` cannot breach R06, gate 3's `unsafe` limb is a stated posture rather
than a filter, and excluding a candidate on it would have been the error. The log carries the
same scope note beside the census so a reader of the evidence alone reaches the same place.
Recording that no candidate declares a crate-level `unsafe_code` lint (`G22`, `G23`, with the
per-crate zero counts printed) is the right way to state an absence rather than assume it.

**The transitive limit is stated, in the right place and at the right width.** The not-proven
list now reads: "it reads each candidate's **own** `src/` tree only, so the `unsafe` posture
of the transitive dependencies those crates pull in — `regex`, `idna`, `url`, `serde_json`,
`compact_str`, `smallvec` and the rest — is unexamined. Proving that needs a whole-tree audit
against a resolved lockfile (`cargo geiger` or equivalent), which P03 can run once a lockfile
exists and which no gate here requires." That is the correct boundary for a census over
extracted crate sources, it names the crates it did not reach, and it says what would close
it. Naming `cargo geiger` does not collide with R06's ruling that the tool is "out of scope
(R13) and unfit for this mechanism": R06's objection is to `cargo-geiger` as a checker of the
template's *own* `[lints]`-table `forbid` (its issue #539 misreads that form), not to a
whole-tree dependency census, and revision 2 offers it as "or equivalent" for work no gate
requires rather than adopting it.

**Gate 5 is answered for all six candidates and the null result is earned.** The pattern
searched is printed in the log —
`^(tokio|async-std|smol|futures|futures-.*|async-global-executor|async-io|async-executor|actix-rt)$`
— applied to each crate's whole `kind == "normal"` dependency list with optional entries
included, and each crate's full list is printed so the zero can be checked against names. The
total across six candidates is 0 (`G31`), and the decision states the method for exactly the
reason it should: "a null result is only evidence if the search was real". Default-feature
keys are recorded per candidate (`G24`–`G30`) and each agrees with the printed crates.io
reading. One apparent conflict is not one: the gate 5b row counts optional dependencies
(`serde` 2, `garde` 13, `validator` 9, `serde_valid` 13) while the maturity table counts
non-optional ones (`serde` 1, `garde` 2, `validator` 6, `serde_valid` 10). Both carry their
qualifier in the text, and the pairs reconcile against the printed lists.

**JF-3's three container types now rest on published source.** `toml 1.1.6+spec-1.1.0`
`src/table.rs` `pub type Table = Map<String, Value>;` (`G32`) with `src/map.rs`
`type MapImpl<K, V> = BTreeMap<K, V>;` under `#[cfg(not(feature = "preserve_order"))]`
(`G33`); `garde 0.23.0` `src/error.rs` `errors: Vec<(Path, Error)>` and
`pub fn into_inner(self) -> Vec<(Path, Error)>` (`G34`, `G35`); `validator 0.21.0`
`src/types.rs:50` `pub struct ValidationErrors(pub HashMap<Cow<…>, ValidationErrorsKind>)`
(`G36`), with a separate assertion that it is not a `BTreeMap` (`G37`). The determinism
sentence is rewritten to say so — "**the ground is the crate's `cfg` line, not an inference
from behaviour**" — with the single probe observation demoted to corroboration. That is
precisely the repair the finding asked for: the claims were re-sourced rather than softened.

**JF-2 and JF-4 are closed by artifact.** The Codex quotation now runs to its clause end —
"…not full Zod aggregate parity, and R55 decides how either class is tolerated" — matching
`raw/codex.md:13`, with the correction disclosed in place rather than silently applied. For
JF-4 I did the comparison myself over the two committed logs: `diff r53-verify.log
r53-r2-verify-rerun.log` outputs exactly four lines, two changed pairs, at lines 315 and 357,
both carrying the probe crate's PID-bearing `$TMPDIR` path (`r53-verify.83722` versus
`r53-verify.19453`). That is exactly what revision 1 asserted and could not show, so the
committed pair both closes the finding and vindicates the original claim.

## Completeness

Structure holds: four H2s in runbook order, `### Principles and implementation` present with
`re-verify:` as its final line, no `## Supersedes` and the absence explained. Five `- assumes`
lines, no `- owns`, no backtick-wrapped value, no citation or commentary on a parameter line.
No `CONFLICT:` line is emitted, which remains correct — neither of this item's raws contains
one. The revision history is accurate: the two revision-1 commits it names (`9b5cdbc`,
`1a4ba6f`) and the round-1 audit commit (`57c1a3d`) all exist and carry the described
subjects, and the revision-1 sha it quotes matches the blob at `c893fb0~1`.

Evidence totals are stated within what the logs show: 117 / 0 / 0 for `verify.sh`, 37 / 0 / 0
for the new script, and "**154 assertions in total, none failing, none skipped on this host**"
sums correctly. The new figures carry endpoint and retrieval date — the crate-download and
dependency endpoints are named in the log header and in the decision's method paragraph, the
retrieval date is 2026-09-17, and the immutability argument for why the counts are stable
("crates.io releases are immutable") is stated rather than assumed. The not-re-read list is
corrected exactly where round 1 said it was wrong: "carried from `raw/opus.md`" becomes
"**referred to from `raw/opus.md` … and are not reproduced here**", with the word choice
flagged deliberately, and the paragraph records where the new census and `raw/opus.md:533-547`
differ and that **the census governs**. Superseding one's own earlier wording in the open,
naming what it said, is the right handling for a revision that must stay auditable against
its predecessor.

## Findings

1. **JF-1 (round 1, blocking) — CLOSED.** Gate 3's `unsafe` limb and gate 5's async limb are
   now answered for `serde`, `garde`, `validator`, `serde_valid`, `nutype` and `validify` in a
   per-candidate table, from a source-level census executed in this run (`G01`–`G31`) rather
   than referred to from a raw. The two inaccurate sentences round 1 named are corrected in
   place. Closed as required, and closed more strongly than the finding asked: the finding
   would have been satisfied by attributing the raw's audit, and the revision re-ran it.

2. **JF-2 (round 1, non-blocking) — CLOSED.** The quotation carries Codex's clause to its end
   and the earlier truncation is disclosed.

3. **JF-3 (round 1, non-blocking) — CLOSED.** All three container types are asserted from
   published source with check identifiers, and the determinism conclusion is re-grounded on
   the `cfg` line rather than on the single probe observation.

4. **JF-4 (round 1, non-blocking) — CLOSED.** Both logs are committed, the `diff` command is
   in the text, and I reproduced the four-line result from the tree.

5. **JF-5 (new, non-blocking) — one cell of the gate-3b table asserts a module boundary the
   evidence does not quite print.** The table says `garde`'s four `pattern.rs` sites are "inside
   `src/rules/pattern.rs`'s `regex_js_sys` module, gated `#[cfg(all(target_arch = "wasm32",
   target_os = "unknown"))]` and therefore absent from an `ubuntu-latest`/`macos-latest`
   build". The log prints the module header with its `cfg` at lines 97–101 and prints the four
   matching lines at 122, 139, 140 and 149, but it does not print where the module closes, so
   membership is demonstrated for 122, 139 and 140 by proximity and asserted for 149. The
   conclusion is unaffected in either case: line 149 is
   ``unsafe { $crate::rules::pattern::regex_js_sys::SyncWrapper::new(::js_sys::RegExp::new($pat, "u")) }``,
   whose `unsafe` block can only be expanded through a `js_sys` type that does not exist on a
   native target, so it is off an `ubuntu-latest`/`macos-latest` build path whether or not it
   sits inside the gated module. The decision's own headline number — three default-path sites,
   the number it counts against the runner-up — is untouched, and it is the conservative
   direction. **What would close it:** print the module's closing line in the census, or assert
   line 149's `js_sys` path dependency directly. **Not blocking**, and I do not require a
   revision 3 for it; it is a note for whoever reruns this check.

## Assessment

**Nothing moves under JF-5 or under anything else in revision 2.** The recommendation is
`serde >= 1.0.229, < 2.0.0` with `features = ["derive"]` and no validation crate, unchanged,
still resting on `P2_GARDE_REACHED = false` / `P2_GARDE_REPORT_ENTRIES = 0` plus the fact that
every constraint in the current schema is a type. `garde >= 0.23.0, < 0.24.0` remains the
ranked runner-up on the same three grounds, two of which are now sourced to `garde`'s and
`validator`'s published code instead of asserted. No parameter value, gate disposition,
exclusion or ledger position changed, and `verify.sh` with its log came through byte-identical.

The revision's own claim that closing JF-1 **strengthens** the recommendation is fair rather
than self-serving, and I checked it in both directions: the crate carrying `unsafe` on its
default build path is the one not chosen, and the decision says out loud that the chosen crate
is not `unsafe`-free either, which is what stops the new evidence from reading as a retrofit.

**One observation for the controller, which is not a finding against this item.** R55's
in-flight decision selects prune-and-retry over the untyped document through
`serde_path_to_error`, and lists "Hand-rolled per-key extraction" among its rejected
alternatives partly because "it drifts from whatever R53 selects" (`:141`), while requiring
that "**R53** must validate through `serde::Deserialize` for the prune loop to localize"
(`:328`). R53's per-key loop does deserialize each key through a derived `Deserialize`, so
R53 satisfies what R55 asks of it, and R53's new coupling sentence is hedged correctly. But
the two in-flight siblings propose different shapes for the one
`crates/rs-launch-blueprint/src/config/loader.rs` that R53 itself describes as "shared with
R52/R54/R55". Neither decision can reconcile that against an unaccepted sibling without
consuming an unregistered value, so the reconciliation belongs to the controller at
acceptance, or to P03. I raise no finding and require no change here; I record it because it
is actionable and easy to lose between two items that each correctly decline to decide it.

**On the empirical audit.** It still has not run, so no artifact in this run has been
reproduced by a second engine, and acceptance under the runbook still requires two
approving verdicts. Every claim I could check from the tree — the two evidence logs, the
ledger rows, the registry values, the standard at its blob, R06, R52, R55, R67 and both
raws — held.

Revision 2 closes the blocking finding by doing more work than the finding required, closes
the three non-blocking ones by artifact rather than by wording, and disturbs nothing it was
not asked to touch. I approve it.
