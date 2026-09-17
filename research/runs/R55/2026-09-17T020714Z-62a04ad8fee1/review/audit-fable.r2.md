decision-sha256: b4ad24de2daac2429614a4dcd268050f845480c188ddcda9e3ad92e2eaa857a8
actor: audit-fable-2026-09-17T020714Z-62a04ad8fee1-r2
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-7 (blocking): the revision-2 script's four `assert_stream` checks (`JF4a`, `JF4b`, `JF5a`, `JF5b`) are the tail of a pipeline, so `ok`/`no` mutate `pass`/`fail` in a subshell and neither counter survives — `evidence/check-r2.log` prints 22 script-level `PASS` lines where the summary the decision cites reads `PASS=18`, the decision's own bullet list enumerates those 22 ids while its prose says "The eighteen script checks", and a *failing* one of the four would print `FAIL` yet leave `fail=0`, so the closing gate `[ "$fail" -eq 0 ]` cannot be tripped by them — which is the "a check that cannot fail is not evidence" defect the synthesizer role doc names, and two of the four (`JF4a`, `JF4b`) are the checks underwriting evidence (ii) and (iii) that revision 2 uses to narrow Disagreement 2; all four claims are nonetheless true, verified at their pins in both rounds; JF-8 (non-blocking): the R8a routing sentence denies too much — "this is a requirement R55 places on how P03 writes the loop, not an observation about R53's decision" — when the silence is a property of R53's published loop shape (`R53 review/evidence/verify.sh:620`) and bears on R53's own must-agree row at `R53 DECISION.md:184`, although the destination it routes to is correct; JF-9 (non-blocking): two new load-bearing claims carry no pin of their own — clause 3's "both sources tolerate unknown keys (py sets `model_config = {"extra": "ignore"}`, zod's `z.object` strips them)", and the probe's helper provenance cited as `R53 review/evidence/verify.sh:650-657` where the helper begins at `:649` — both verified true here; JF-10 (non-blocking): the restored F237 line at `:354` ends `…survives the port.**`**`, one `**` too many before its closing backtick

Judgment auditor for R55 (`config-error-tolerance`, kind `bundle`, Focused tier, owning no
parameter), **revision 2**, run `2026-09-17T020714Z-62a04ad8fee1`, round 2. I produced none of
this item's artifacts. My round-1 report on revision 1 is archived byte-identically at
`review/audit-fable.r1.md` (`verdict: approve`, six non-blocking findings JF-1 to JF-6); the
numbering here continues from it. The hash above was taken before I opened revision 2 and
re-taken immediately before writing this file; it was unchanged across the audit. The
empirical (Codex) audit is still deferred, so this is again the only audit, and I ran the
source checks an empirical lane would otherwise duplicate: R53's decision and its evidence
script at the pinned sha, the py source at `b08bccfb`, the ts source at `cb1cbcb2`, the
registry, and revision 2's own logs and probe. I did not rerun either check script; I read
their committed logs and the scripts themselves.

**Round-1's approval is not disturbed.** JF-7 is a defect in a script revision 2 introduces,
in a revision-2 file. Revision 1's `check.sh`, `check.log` and `rerun.diff` are untouched — I
confirmed the three are byte-identical across the two commits and that their sha256 prefixes
are the `ed0029f0…`, `d83a1fea…`, `3dda6290…` the decision cites.

## Principle and agreement level

The four principles, their sources and their agreement levels are unchanged from revision 1
and remain correctly stated; my round-1 assessment of them stands. Two things changed around
them and both improve the record.

P2 gains a second, sharper role. It is no longer only the reason a missing explicit path
warns; it is the test revision 2 applies to R53's published loop, and the test that fails
(R8a). Using the item's own declared acceptance criterion as the instrument that finds a gap
in a sibling's mechanism is the right use of a principle stated at that level.

P1's citation is unchanged, and revision 2 adds the citation my round-1 JF-4 asked for, at
the range it verified: `b08bccfb:src/py_launch_blueprint/core/config.py:148-150`, the
`load_config` docstring — "Tolerant by design — with one exception: an *explicit* ``--config``
file that exists but cannot be parsed raises :class:`ConfigError`. Discovered layers and
invalid values degrade to warnings (see ``Config.warnings``)." I read it at the pin again. It
is py stating clause 2's explicit limb and clause 3 in py's own words, and the decision now
says so rather than arguing the split unaided.

The must-agree/may-vary split is unchanged and still correct, with one honest sharpening: the
"mechanism may vary" clause now names what Rust actually pays — "Rust recovers the collection
by writing the loop out — roughly sixty lines, which R53 owns and accepted" — which is more
accurate than revision 1's "roughly sixty lines in Rust and roughly zero in Python", because
the sixty lines are now on another item's budget and the decision says whose.

Ledger handling is unchanged: F235, F236 and F238 settled, F237 preserved and not reopened,
with the same grounds I verified in round 1.

## Design and evidence

**Dropping both crates is grounded by what the probe measured, and the measurement is the
right one.** The question the drop turns on is not "is `serde_path_to_error` good" — revision
2 is explicit that both crates "pass every gate" and are "simply **not needed**, which is a
different disposition" — but "does R53's selected mechanism already produce the two pieces of
information the crates were adopted for". That is a comparison on identical inputs, and it was
run as one:

- `serde_ignored`'s job was the unknown-key set. `R1` runs R53's loop plus a per-level
  set-difference over a document carrying one top-level and one nested unknown key and gets
  `["output.colour", "verbose"]`; `R2` runs `serde_ignored` over the same document and gets
  `["output.colour", "verbose"]`; `R3` asserts the two are identical. The decision's claim is
  stated at exactly that width — "the same unknown-key set as `serde_ignored`, **at both
  nesting depths**" — and the schema has exactly those two depths.
- `serde_path_to_error`'s job was a machine-readable key path. `R4` takes R53's
  `Issue { path: "output.format", … }`, prunes that path out of the same `toml::Table`, and
  shows the sibling `limit = 7` surviving with a clean second pass. The decision's conclusion —
  "its `Issue.path` **addresses a prunable leaf in the same `toml::Table`**" — is what the log
  prints.

The reasoning that accompanies the measurement is sound on its own terms and does not overrun
it: `serde_path_to_error` "existed to turn a fail-fast whole-struct error into a
machine-readable key path; R53's loop deserializes one leaf at a time and knows the leaf's
name at the call site, so it never produces an unlocated error and there is nothing to
locate." I verified that against R53's published helper —
`fn field<T: serde::de::DeserializeOwned>(table: &toml::Table, section: &str, key: &str, issues: &mut Vec<(String, String)>)`
at `R53 review/evidence/verify.sh:649-657`, which pushes `(format!("{section}.{key}"), …)` at
the call site. The drop is conditional on P03 actually writing the per-level set-difference,
and the decision carries that as an explicit requirement in `## Migration implications` and in
`What P03 must validate` rather than assuming it. That is the honest form.

**The probe's limits are stated, including the one the coordinator asked about.** Under "What
the probe does not establish": "It runs R53's loop shape against a two-level schema of this
synthesis's own construction, not against the template's real schema, which does not exist.
R5/R6 use two layers; three or more, and R54's actual merge depth, are unexercised. Everything
ran on macOS arm64 only." The same limit is carried as unproven row 2 (marked *New*), so it
survives into the unproven list rather than living only in a prose aside. The probe is built
outside the repository from `evidence/spike-r2/`, and the decision states plainly why the
probe depends on the two crates it does not recommend: "It depends on `serde_ignored` and
`serde_path_to_error` **only in order to measure them against R53's loop**; the decision
recommends neither." That disclosure is necessary and present.

**R8a is a correct reading of R53's published text.** I checked it at R53's source rather than
taking the probe's word. R53's per-key loop reaches a section through
`if let Some(t) = table.get("output").and_then(toml::Value::as_table) { … }`
(`R53 review/evidence/verify.sh:620`). With `output = 5`, `table.get("output")` is
`Some(Integer(5))`, `as_table()` returns `None`, the body never runs, no `field::<T>` call is
made and no `Issue` is pushed; and because `output` is in the loop's enumerated key list it is
not in the unconsumed set either, so no unknown-key report appears. Silent built-in defaults,
which is precisely what `R8a` prints: `issues=[] unconsumed=[] value=ConfigFile { output:
OutputSettings { format: Table, color: Auto, limit: None } }`. The repair and its effect are
measured too (`R8b`: one `Issue` at path `output`, prunable, second pass clean).

**The routing of R8a is to the right place, and the sentence announcing it denies too much**
(JF-8). Right: no `CONFLICT:` line is raised — correct, since a `CONFLICT:` is for a consumed
*parameter* and R53 owns none, which the decision states and checks; R53's decision is not
edited; the repair is named as one line and lands in `## Migration implications`, in
acceptance criterion 7 and in `What P03 must validate`; and "R53 being revised" heads the
`re-verify:` list. The overreach is the clause "not an observation about R53's decision" —
covered in Findings.

**The `CONFLICT:` ruling is unchanged and is now stronger.** codex's line is still quoted
verbatim and still rejected on R67's delegation sentence, which I re-read at
`research/topics/67-error-and-exit-code-contract/DECISION.md:272-274`. Revision 2 adds the
observation that under R53's mechanism `RSLB203` is reserved for exactly what codex asked it
be reserved for, and pre-empts the obvious misreading: "That `RSLB203` is currently unreached
is **not** an argument for codex's reading: R67 guarantees the entry whether or not this item
reaches it." That is the correct disposal of the risk my round-1 JF-1 flagged, and unproven
row 6 records the unreachability as unproven rather than as a virtue.

**The engine dispositions are revised honestly where R53's publication changed them.**
Disagreement 3 is the one that moved: revision 1's settlement is quoted as superseded wording,
the ground for it ("D drifts from whatever R53 selects") is stated as dissolved because R53
selected D, and the new disposition is "neither engine's crate is needed", with codex credited
for the architecture and opus credited for a mechanism that "was correct as a mechanism R55
could own alone, was executed, and is superseded". The `flatten` rule's history is likewise
kept in both states rather than one being quietly replaced — revision 1's narrowing was right
for `serde_path_to_error`'s tracked path, and the blanket rule returns on the ground R7
measures (leaves at an unenumerated level come back as unknown keys and none is validated).
Keeping both states visible is the right archival behavior.

**The dependency statement is honest.** "R55 adds no crate of its own", with the three
consumed selections named and attributed: `toml` 1.1.6+spec-1.1.0 to R52, `serde` 1.0.229 with
`derive` to R53, `thiserror` 2.0.20 to R67. I confirmed each against the owning decision —
R52's read path is `toml` 1.1.6 with `toml_edit` 0.25.15 for the write path only; R53
publishes `serde >= 1.0.229, < 2.0.0` with `features = ["derive"]` and "**No dependency is
added by this item.**"; R67's Layering clause fixes `thiserror` in the library crate. Gates 2
to 6 are recorded `inapplicable — this item has no crate member` with the reason and with the
gating item named for each composed crate, which is the prompt's required form rather than a
silent omission, and gate 1 keeps the owner's licence ruling. Critically, revision 1's
per-member gate table is preserved as superseded wording "because it is the record that the
two crates were evaluated rather than dismissed" — so dropping the members does not erase the
evidence that they were assessed. The MSRV floor is restated correctly: 1.71 from
`thiserror`, unmoved by dropping the two 1.61 crates.

## Completeness

The H2 set is exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in
order, with `### Principles and implementation` nested inside `## Decision`, no `## Supersedes`
and the revision note and history inside `## Decision` — the same shape R53 revision 2 and R48
revision 2 use. `re-verify:` is the last line of `## Decision`, with the fired trigger marked
discharged and the two crate-specific triggers marked retired rather than deleted.

The five `- assumes` lines are byte-identical to `docs/port/PARAMETERS.md` — I re-parsed the
registry table and compared the strings for revision 2 rather than trusting the claim:
`msrv-policy` 118 bytes, `rust-edition` 4, `target-os-matrix` 27, `license` 17,
`error-taxonomy-exit-codes` 4057, all equal. Zero `- owns` lines. The note that R53 supplies a
decision rather than a parameter, so no `- assumes` line is added for it, is correct — R53
owns no registry parameter.

The unproven list is handled well. Ten rows become ten, with each carried, new or retired row
labelled, and the five retirements justified rather than dropped: the two crates' `unsafe`
posture and crate figures go with the members, `toml_edit::DocumentMut` goes because R52
settled the read path, and "whether `serde_ignored` belongs to this item" is marked *answered*
with the answer. Three new rows are added, including the probe's constructed schema and
`RSLB203`'s unreachability. Acceptance criteria grow from eight to ten, adding the unknown-key
case, the non-table section case and criterion 10 — "`RSLB203` is unreachable from any of the
above; the first cross-field rule R53 adds is the test that reaches it" — which is the right
way to record a reserved code.

Round-1 findings JF-1 through JF-6 are all closed in substance. I verified each at its source
rather than at the decision's claim:

- **JF-1 — closed.** Clause 3's third sub-clause is rewritten, revision 1's wording is quoted
  as superseded, and the grant is explicit: case F "constructed `toml::Value::Integer(5)`
  directly rather than parsing it, and a parsed TOML document always has a table at its root".
  Unproven row 6 replaces the old claim.
- **JF-2 — closed.** `evidence/check-archive.log` exists and ends `PASS=25 FAIL=0 SKIP=0`. The
  decision's description of it is exact: I diffed it against `check.log` and it differs in
  three lines and no assertion — the `date (UTC)` header, the `repository root` header, and
  the `C05` line that prints that root inside its message. `JF2a` asserts 20 `[[package]]`
  stanzas in revision 1's spike lockfile, which is the count I made by hand in round 1.
- **JF-3 — closed.** `JF3` asserts R5.7's anti-pattern line at the pinned standard blob, and
  the Disagreement-5 sentence is split so `C06d` carries the R5.8 half and `JF3` the R5.7 half,
  with the reason stated ("revision 1 attached `C06d` to both halves, and `C06d` covers only
  the first").
- **JF-4 — closed in substance.** `config.py:124-139` is cited for the collapse with `:127-128`
  quoted, and `:148-150` is quoted in full under `### Principles and implementation` and cited
  as evidence (iii) of Disagreement 2. Both ranges are right at the pin.
- **JF-5 — closed in substance.** `ts: src/lib/config.ts` `:153` → `:154` and py
  `core/config.py` `:102` → `:103`, both correct at their pins; the codex quotation now runs to
  the end of its clause and the decision draws the right conclusion from the restored tail
  ("that second clause is now the live description of `RSLB203`'s only reachable target"); and
  the four reference implementations now carry commit shas, which was the fourth point.
- **JF-6 — closed.** I diffed both lines against the raws. The F237 line at `:354` is equal to
  `raw/opus.md:227`. The F238 line at `:362` is equal to the backtick-delimited line in
  `raw/codex.md:17`, whose trailing `[Python settings pin](…)` and `[toml Value](…)` citations
  sit outside the delimiters and are correctly not pulled in. Both generalizations are moved
  into the disposition beneath, where the F238 disposition now says plainly that the leaf
  boundary is `toml::Table` rather than `toml::Value` and why.

The closures for JF-4 and JF-5, however, are exactly the four checks JF-7 is about: they are
true, and their checks cannot fail. Reproducibility is stated at the right width for the new
script too — `evidence/r2-rerun.diff` is a one-line diff in the `date (UTC)` header, which is
what I found when I read it.

## Findings

Numbering continues from round 1. One finding blocks.

1. **JF-7 (blocking) — four of revision 2's checks cannot fail the run, and the summary the
   decision cites undercounts its own script by four.** The decision states, at `:538`:
   "**Result: `PASS=18 FAIL=0 SKIP=0`, exit status `0`.**", and at `:542`–`:543`: "The eighteen
   script checks and the nine probe assertions nested inside `D05` are:". Counted from the
   committed log rather than from the prose, `evidence/check-r2.log` carries **31** lines
   beginning `PASS `: nine printed by the probe binary inside the `D05` section
   (`R1`–`R8b`) and **22** at script level — `D01`, `D02`, `D03a`, `D03b`, `D03c`, `D03d`,
   `D04`, `JF2a`, `JF2b`, `JF3`, `JF4a`, `JF4b`, `JF5a`, `JF5b`, `D05`, `D05a`–`D05g`. The
   decision's own bullet list enumerates those same 22 identifiers, so its prose and its
   enumeration disagree with each other as well as with the log.

   The cause is mechanical and I reproduced it. `evidence/check-r2.sh` is `#!/usr/bin/env bash`
   with `set -euo pipefail` and no `shopt -s lastpipe`. Four checks are invoked as the tail of
   a pipeline — `check-r2.sh:168`–`:188`, of the form
   `git -C "$PY_REPO" show "$PY_PIN:…/config.py" | sed -n '127,128p' | assert_stream JF4a …` —
   and `assert_stream` (`:78`–`:86`) calls `ok` or `no`, which do `pass=$((pass + 1))` and
   `fail=$((fail + 1))`. In bash the last element of a pipeline runs in a subshell, so the
   `echo` reaches the log and the assignment is discarded:
   `bash -c 'p=0; ok(){ echo "PASS $1"; p=$((p+1)); }; printf "x\n" | ok A; echo "counter=$p"'`
   prints `PASS A` then `counter=0`. Exactly four such checks exist and exactly four
   increments are missing: 22 − 18.

   The count is the symptom; the defect is the gate. The script ends `[ "$fail" -eq 0 ]`, and
   `no` returns 0, so a **failing** `JF4a`, `JF4b`, `JF5a` or `JF5b` would print its `FAIL`
   line into the log and leave `fail=0`, and the script would still exit `0` and still report
   `FAIL=0`. Those four checks cannot fail the run. That is the defect the synthesizer role doc
   names in terms — "make every check assert on the content it expected rather than on an exit
   code alone. A check that cannot fail is not evidence" — and it is the same family as the
   pipeline-status bug the same paragraph records a prior rejection for. It is not
   presentational here: `JF4a` and `JF4b` are the checks behind evidence (ii) and (iii) of
   Disagreement 2, and revision 2 uses evidence (iii) to narrow the decision's own most
   contestable branch from "the one place in this decision an owner could reasonably decide the
   other way" to something "narrow[ed] considerably". The strengthened claim is gated by two
   checks that cannot fail.

   **All four claims are true.** I read them at their pins in round 1 and again in round 2: py
   `config.py:127-128` carries the `--config` collapse docstring, `:148-150` the `load_config`
   tolerance docstring, `:103` the discovered-layer warning return, and ts `config.ts:154` the
   `click.Path(exists=True)` parity comment. Nothing the decision asserts is false, and no
   conclusion moves. **What resolves it:** feed `assert_stream` without a pipeline so the
   counters and the gate survive — a here-string works, and I confirmed it rather than
   assuming: `bash -c 'p=0; ok(){ echo "PASS $1"; p=$((p+1)); }; ok A <<<"x"; echo "counter=$p"'`
   prints `counter=1`, and the same shape with `no` gives `fail counter=1`, so the gate trips
   again. Write the four as
   `assert_stream JF4a "…" "…" <<<"$(git -C "$PY_REPO" show "$PY_PIN:…" | sed -n '127,128p')"`
   (or write each slice to a temp file and use the already-correct `assert_contains`), rerun,
   and restate both the summary figure and the "eighteen script checks" sentence to whatever
   the repaired run prints.

2. **JF-8 (non-blocking) — the sentence routing R8a denies more than it should, though it
   routes to the right place.** Clause 3's second sub-clause reads, at `:146`–`:151`:
   "Measured: R53's loop as published skips such a section silently, returning built-in
   defaults with no issue and no unconsumed entry (`## Empirical check`, R8a). That violates
   P2, so this is a requirement R55 places on how P03 writes the loop, **not an observation
   about R53's decision**: the loop must push an `Issue` at the section's path when the key
   exists and is not a table." The same framing recurs at `:495`–`:498` ("both inside what R53
   left to R55 rather than changes to R53's decision"). The measurement and the destination are
   both right — see `## Design and evidence` for my independent confirmation at
   `R53 review/evidence/verify.sh:620`, and no `CONFLICT:`, no edit to R53 and a one-line
   repair are the correct handling for a sibling that owns no parameter. What the denial
   obscures is that the silence *is* a property of R53's published loop shape, and that it
   bears on a row in R53's own must-agree table — `R53 DECISION.md:184`, "A value outside a
   key's allowed set is rejected, never silently coerced" — which `output = 5` under the loop
   as published does not satisfy. A reader of R53 who is told this is "not an observation about
   R53's decision" will not go looking. **What resolves it:** say that the gap is in R53's
   published loop shape and touches R53's own must-agree row, that the repair belongs to P03
   inside R53's module, and that R53 therefore need not revise — the same destination,
   described without the denial.

3. **JF-9 (non-blocking) — two claims new to revision 2 carry no pin of their own; both are
   true and I verified them.** (i) The unknown-key policy is *decided* for the first time in
   revision 2, and its first ground is stated at `:137`–`:139` as "both sources tolerate
   unknown keys (py sets `model_config = {"extra": "ignore"}`, zod's `z.object` strips them),
   so failing would be a new strictness neither precedent supports" — with no file:line, and
   reaching the evidence only indirectly through `D03c`, which asserts that R53's sentence
   exists. I checked the sources: `b08bccfb:src/py_launch_blueprint/core/settings.py` carries
   `model_config = {"extra": "ignore"}` at lines 43, 52 and 63 — the three models R53 refers
   to — and `cb1cbcb2:src/lib/config.ts:37` declares `z.object({…})` with neither `.strict()`
   nor `.passthrough()`, so zod strips by default. (ii) The probe's provenance is cited at
   `:566`–`:567` as reproducing R53's helper "in shape from `R53 review/evidence/verify.sh:650-657`";
   the helper begins at `:649`, `fn field<T: serde::de::DeserializeOwned>(`, and `:650` is its
   second signature line. **What resolves it:** put the py and ts pins beside the claim, or
   attribute it to R53 explicitly as a consumed finding, and correct `650` to `649`.

4. **JF-10 (non-blocking) — a markdown artifact in one restored `BASELINE-REVIEW:` line.** The
   F237 line at `:354` ends `…that one error type survives the port.**`**` — a `**` too many
   between the sentence and the closing backtick, which will render as stray emphasis or break
   the code span. The F238 line at `:362` ends correctly, `…affected R53, R54, R55, R58, R67.`**`.
   Both lines are verbatim against their raws; this is presentation only. **What resolves it:**
   delete the stray `**`.

## Assessment

Reject, on JF-7 alone, and narrowly. Everything this revision set out to do, it did, and it did
well: the member list moves from two crates to none on a measurement that compares R53's
published mechanism against each crate on identical inputs rather than on an argument from
parsimony; the drop is stated as conditional on the per-level set-difference P03 must write,
and that requirement is carried where P03 will read it; both crates are recorded as passing
every gate and not needed, with revision 1's gate table preserved so the evidence that they
were evaluated survives the decision that they are unnecessary; the probe's constructed-schema
limit is stated twice, once in prose and once as an unproven row; the R8a reading of R53 is
correct, and I confirmed it at R53's own source rather than at the probe's; the
`CONFLICT:` ruling stands unchanged and is now sharper about what its own unreached row does
and does not imply; the dependency statement is honest and each of the three consumed
selections checks out against the owning decision; the four-clause rule is re-measured rather
than re-asserted; and all six round-1 findings are closed in substance, each of which I
verified at its source rather than at the decision's claim.

What fails is the harness, and it fails in the one way this programme's role doc singles out.
Four checks print a verdict they cannot enforce: their `ok`/`no` runs in a pipeline subshell,
so a `FAIL` among them would leave `fail=0` and the closing `[ "$fail" -eq 0 ]` would still
exit `0`. The decision then cites that harness's summary — `PASS=18` — as its result while its
own log prints 22 script-level passes and its own bullet list enumerates 22 identifiers. Two of
the four inert checks are the evidence on which revision 2 narrows the decision's most
contestable branch. A count that disagrees with its own log and a gate that cannot close are
not presentation, and I would be certifying a verification I had just shown cannot fail.

**The recommendation does not move under any finding.** The provenance-aware two-phase loader
with no R55-added crate, the four clauses, the `RSLB203` reservation, the `CONFLICT:`
rejection, the no-`flatten` rule on its new ground, the R8a requirement and its routing, the
ten acceptance criteria, the parameter lines and every round-1 closure all stand as written.
Revision 3 is four lines of shell, a rerun, and two sentences restated to the repaired count,
plus the three non-blocking repairs if the synthesizer chooses to take them in the same pass.
