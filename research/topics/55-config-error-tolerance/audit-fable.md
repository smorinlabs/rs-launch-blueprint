decision-sha256: 5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b
actor: audit-fable-2026-09-17T020714Z-62a04ad8fee1-r3
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Judgment auditor for R55 (`config-error-tolerance`, kind `bundle`, Focused tier, owning no
parameter), **revision 3**, run `2026-09-17T020714Z-62a04ad8fee1`, round 3. I produced none of
this item's artifacts. My two earlier reports are archived byte-identically beside this one —
`review/audit-fable.r1.md` on revision 1 (`approve`, six non-blocking findings JF-1 to JF-6)
and `review/audit-fable.r2.md` on revision 2 (`reject`, JF-7 blocking plus JF-8 to JF-10).
Numbering continues from them. The hash above was taken before I opened revision 3 and
re-taken immediately before writing this file; it was unchanged across the audit. The
empirical (Codex) audit is still deferred, so this is again the only audit.

Revision 3 is a repair round with a narrow brief, and I audited it as one: the four round-2
findings, the claim that nothing else moved, and whether the committed diff is only what the
decision says it is. Everything I certified in rounds 1 and 2 — the four-clause rule, the
crate drop to zero, the `CONFLICT:` rejection, the R8a reading, the ledger dispositions, the
parameter lines — I re-checked for movement rather than re-deriving, and none of it moved.

## Principle and agreement level

Unchanged, and unchanged is the right outcome. The four principles, their sources and their
agreement levels are byte-identical to revision 2; the `git diff` carries no hunk in the
principles table, in the must-agree/may-vary split, in the F235 rationale paragraph or in the
`## Engines` section. P2 keeps the second role revision 2 gave it — the instrument that finds
the R8a gap — and revision 3 sharpens where that gap sits without weakening P2's claim on it:
the new wording still says "It also violates this item's P2" after locating the gap in R53's
loop shape, so the finding is not quietly reassigned away from the principle that produced it.

The one principle-adjacent change is an improvement in evidence rather than in doctrine: the
unknown-key policy's first ground now carries the pins it was asserted without, which I cover
under JF-9 below.

## Design and evidence

**JF-7 is closed, and the negative control is the right proof.** I asked for a repair that
restores the counters and the gate; revision 3 supplies that and then demonstrates it three
ways, of which the third is the one that settles it.

1. **The repair.** `evidence/check-r3.sh` is a new file — `evidence/check-r2.sh` and
   `evidence/check-r2.log` are untouched, which I confirmed from the commit: `439da7d` adds
   five files under `evidence/` and modifies none. The four call sites now read
   `assert_stream JF4a "…" '…' <<<"$(git -C "$PY_REPO" show "$PY_PIN:…" | sed -n '127,128p')"`
   (`check-r3.sh:214`, `:217`, `:220`, `:227`), which is the here-string form I verified in
   round 2. `assert_stream`'s body is unchanged and now carries the constraint as a comment:
   "MUST be fed by a here-string, never by a pipeline".
2. **The count invariant now holds, which is the cleanest evidence the fix worked.** I counted
   the committed log rather than reading the prose. `evidence/check-r3.log` carries 38 lines
   beginning `PASS `: nine from the probe binary and **29** at script level, whose identifiers
   are exactly `D01`, `D02`, `D03a`–`D03d`, `D04`, `JF7`, `JF7b`, `JF2a`, `JF2b`, `JF3`,
   `JF4a`, `JF4b`, `JF5a`, `JF5b`, `JF8a`, `JF8b`, `JF9c`, `JF9a`, `JF9b`, `D05`, `D05a`–`D05g`
   — revision 2's 22 plus the seven new ones. The summary prints `PASS=29`. Script-level `PASS`
   lines and the counter now agree, which is precisely what they did not do in revision 2, and
   it also rules out any *new* check having been added in a counter-losing position: a lost
   increment would show as a printed line the summary did not count. The decision's three
   figures — 29 script checks, nine probe assertions, 38 `PASS` lines — are each what the log
   contains, and its bullet list enumerates all 29 across six bullets rather than a number that
   disagrees with its own enumeration.
3. **The negative control, which is what makes this closed rather than plausible.**
   `evidence/check-r3-negative-control.log` states its procedure in reproducible form — a
   `git archive HEAD` extraction, a `sed` substitution replacing `JF5b`'s needle with text
   absent from the file, neither committed script edited — and records both runs. Revision 2's
   script prints `FAIL JF5b: …` and then `PASS=18 FAIL=0 SKIP=0` with `exit=0`; revision 3's
   prints the identical `FAIL` line and then `PASS=28 FAIL=1 SKIP=0` with `exit=1`. Same
   mutation, same failing check, same `FAIL` text, opposite gate behavior. The arithmetic is
   consistent with the healthy run in both directions: revision 2's `PASS` stays at 18 because
   `JF5b`'s pass was never counted either, and revision 3's falls 29 → 28 as the one check
   moves from the pass column to the fail column. That is a control, not a demonstration: it
   isolates the single variable and shows the defect present in one script and absent in the
   other.

   I did not rerun either script — the `D05` probe would rebuild — and I did not need to. The
   mechanism itself I proved independently in round 2 (`printf "x\n" | ok A` leaves the counter
   at `0`; `ok A <<<"x"` leaves it at `1`, and the same shape with `no` leaves `fail` at `1`),
   check `JF7` reproduces exactly that experiment in the live shell rather than asserting it in
   prose (`check-r3.sh:151`–`:168`, requiring **both** `pipeline pass=0 fail=0` and
   `herestring pass=1 fail=1`), and I confirmed the gate is still the script's last statement,
   `[ "$fail" -eq 0 ]`.

The superseded figure is quoted in place rather than overwritten — "**Result: `PASS=18 FAIL=0
SKIP=0`**… The eighteen script checks" appears as a blockquote with the grant beneath it — and
I checked that no live sentence still cites `PASS=18` as a result: every remaining occurrence
is inside that blockquote or inside the revision-3 note describing the granted finding.

**The R8a routing is now correctly stated.** Revision 2 said the gap was "not an observation
about R53's decision"; revision 3 says the opposite half out loud and keeps the same
destination. The new wording locates the gap in R53's **published loop shape**, quotes the
mechanism that produces it — `table.get("output").and_then(toml::Value::as_table)` at
`R53 review/evidence/verify.sh:620` — names the row it touches in **R53's own must-agree
table**, "A value outside a key's allowed set is rejected, never silently coerced" at
`R53 DECISION.md:184`, and only then states the disposition: the repair is one line inside
R53's module and belongs to P03, so R53 need not revise, and no `CONFLICT:` arises because R53
owns no parameter. Both source claims are checked (`JF8b` and `JF8a`) and I verified both line
numbers at R53 myself in round 2. The parallel sentence under `## Parameters` is narrowed the
same way, which matters because round 2 found the denial in both places. The superseded wording
is preserved with the reason the denial was wrong — "a reader of R53 told this was 'not an
observation about R53's decision' would not go looking" — which is the disposition I asked for,
stated more plainly than I stated it.

**JF-9 is closed with pins I re-verified at source.** The unknown-key precedent now reads
"py sets `model_config = {"extra": "ignore"}` on all three models,
`b08bccfb:src/py_launch_blueprint/core/settings.py:43,52,63`; ts declares `z.object({…})` at
`cb1cbcb2:src/lib/config.ts:37-41` with neither `.strict()` nor `.passthrough()`, so zod strips
unknown keys by default". I read both at their pins: the three `model_config` lines are at 43,
52 and 63, and `config.ts:37-41` is the `z.object({ token, workspace, limit });` declaration,
with zero `.strict()` or `.passthrough()` calls not merely in that range but anywhere in the
file — so `JF9b`'s assertion is true and conservative. The probe's helper provenance is
corrected from `:650-657` to `:649-657` and checked as `JF9c`; `:649` is indeed
`fn field<T: serde::de::DeserializeOwned>(`.

**JF-10 is closed.** The stray `**` is gone. I re-diffed both `BASELINE-REVIEW:` lines against
the raws rather than trusting the claim: the F237 line at `:412` is character-for-character
equal to `raw/opus.md:227` (1292 bytes each) and now closes correctly as `` …survives the port.`** ``;
the F238 line at `:420` is equal to the backtick-delimited line in `raw/codex.md:17`, whose
trailing citations sit outside the delimiters and are correctly not pulled in.

**The diff is only what is claimed.** I read the whole `439da7d~1..439da7d` diff rather than
sampling it. Six files: `DECISION.md` (140 insertions, 30 deletions) and five **new** evidence
files, with no modification to any existing artifact — revision 1's `check.sh`, `check.log`,
`rerun.diff`, `check-archive.log`, `spike/` and the crates.io snapshots, and revision 2's
`check-r2.sh`, `check-r2.log`, `r2-rerun.diff` and `spike-r2/` are all untouched, which is what
lets the negative control read revision 2's script as the record of what revision 2 ran. Inside
`DECISION.md` the hunks are: the revision-3 title and note; the revision-2 note retained
verbatim beneath it; the history line; the JF-9 pins in clause 3; the JF-8 rewrite with its
superseded blockquote; the JF-10 character fix; the JF-8 narrowing under `## Parameters`; and
the `## Empirical check` rewrite for the new script, the new checks, the negative control and
the archive run. There is no hunk in the recommendation, the four clauses other than the two
granted repairs, the acceptance criteria, the fitness gates, the `- assumes` lines, the
alternatives table, the reference implementations, the unproven list or `## Engines`.
**Nothing moves.**

## Completeness

The H2 set is exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in
order, with `### Principles and implementation` nested inside `## Decision`, no
`## Supersedes`, and both earlier revision notes plus the history retained inside
`## Decision` — the shape R48 and R53 use for their own revisions.

The five `- assumes` lines are byte-identical to `docs/port/PARAMETERS.md`. I re-parsed the
registry and compared against the revision-3 file rather than carrying the round-2 result:
`msrv-policy` 118 bytes, `rust-edition` 4, `target-os-matrix` 27, `license` 17,
`error-taxonomy-exit-codes` 4057, all equal; zero `- owns` lines. Because those lines did not
change, revision 1's `C05` remains true of the current file, which is what the decision's
"Revision 1's result stands" claims and no more.

Reproducibility is stated at the width the artifacts support. `evidence/r3-rerun.diff` is a
one-line diff in the `date (UTC)` header, which is what it contains. `evidence/check-r3-archive.log`
ends `PASS=29 FAIL=0 SKIP=0` and differs from `check-r3.log` in exactly two lines — `date (UTC)`
and `repository root` — and in no assertion, which is the decision's claim exactly; the
three-line difference revision 1's archive run showed came from its `C05` printing the root
inside its message, and `check-r3.sh` has no such check, so two is right rather than a
discrepancy. Each earlier revision's one-line rerun diff is restated as unchanged, and both are.

All four round-2 findings are closed: **JF-7** by the repaired script, the restored count
invariant and the negative control; **JF-8** by the rewritten sub-clause and its `## Parameters`
twin, both checked at R53's source; **JF-9** by the py, ts and R53 pins, all three re-verified
here; **JF-10** by the character fix and the verbatim re-diff. The six round-1 findings remain
closed, and their closing checks — `JF4a`, `JF4b`, `JF5a`, `JF5b` among them — are now inside a
gate that can trip, which was the whole of round 2's objection.

## Findings

**No unresolved findings.** One observation below does not block acceptance, and one latent
note is recorded so it is not lost. Neither changes a conclusion, a check result, a parameter
or the recommendation.

1. **JF-11 (non-blocking) — the "shellcheck-clean" claim appears in no log.** The decision
   writes, at `:598`–`:600`: "The script is shellcheck-clean, asserts on content in every
   check, finds the repository root by content rather than `.git`, and skips by name". The
   toolchain paragraph records `shellcheck` on `PATH`, but neither `check-r3.sh` nor
   `check-r3.log` invokes or records it — the only occurrence of the word in the script is the
   `# shellcheck disable=SC2016` directive at `:26`. This is the same shape as round 1's JF-2,
   a true figure asserted from an artifact the log does not print. It is true: I ran
   `shellcheck -S style evidence/check-r3.sh` myself, a level stricter than the default, and it
   reported nothing. **What resolves it:** run `shellcheck` on the script from inside the
   script, as a named check that skips when the binary is absent, so the claim is read rather
   than taken on trust.

**A latent note on the regression guard, recorded only so it is not lost.** `JF7b` counts
here-string-fed `assert_stream` calls and requires exactly four, and the decision says this is
"so the fix cannot silently regress". That claim is true as written: converting any of the four
repaired sites back to a pipeline drops the count to three, fails `JF7b`, and trips the gate. It
does not cover a different risk — a *fifth* `assert_stream` added later as a pipeline tail would
leave the count at four and pass, while losing its own increment. The script already computes
`n_pipe` at `:171` and only prints it in the failure message. The general invariant is the one I
used to audit this round and it catches every such case, present or future: assert that the
number of script-level lines beginning `PASS ` equals `pass`. This affects nothing in this run —
the two numbers are 29 and 29 — and is not a defect in any finding.

## Assessment

Approve. Revision 3 does the one thing round 2 asked and does it by demonstration rather than
by assertion. The harness now counts what it prints, its gate closes on a forced failure, and
the proof of that is a genuine negative control — the same mutation applied to both scripts
from a clean archive extraction, with revision 2 reporting `FAIL=0` and exiting `0` where
revision 3 reports `FAIL=1` and exits `1` — which is stronger evidence than the repair I
prescribed would have produced on its own. The superseded count is quoted in place rather than
overwritten, and neither cited script nor cited log from an earlier revision is edited, so the
record of what each revision actually ran survives intact. The R8a sentence now says where the
gap sits, cites R53's own must-agree row and the line of R53's loop that produces the silence,
and reaches the same disposition it reached before without the denial that obscured it. The two
missing pins are supplied and correct at their sources, the helper range is corrected, the stray
emphasis is gone and both `BASELINE-REVIEW:` lines are verbatim against the raws. The committed
diff is exactly the repair and nothing else: five new evidence files, no modified artifact, and
no hunk in the recommendation, the clauses, the criteria, the gates, the parameters or the
engines.

**The recommendation does not move, and has not moved since revision 2**: the provenance-aware
two-phase loader as a pattern over `toml` 1.1.6+spec-1.1.0 (R52), `serde` 1.0.229 with `derive`
(R53) and `thiserror` 2.0.20 (R67), adding no crate of R55's own; the four clauses; the
`RSLB203` reservation; the rejection of codex's `CONFLICT:` on R67's delegation sentence; the
blanket no-`flatten` rule; the R8a requirement on P03; and the ten acceptance criteria all stand
as written. Across three revisions the recommendation moved exactly once, at revision 2, for the
reason revision 1's own `re-verify:` line predicted — and the decision now says so in those
terms.
