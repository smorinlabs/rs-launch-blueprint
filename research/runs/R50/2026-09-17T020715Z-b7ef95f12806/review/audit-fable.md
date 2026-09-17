decision-sha256: 316dd29d9681948a8e82623093b0aa450fde7c09c9aadbeeae7652cb0882c461
actor: audit-fable-2026-09-17T020715Z-b7ef95f12806-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Round 2, same auditor, fresh read of the revised file and of the whole revision-1
diff. Round 1's audit is archived byte-identical at `review/audit-fable.r1.md`
(sha256 `744ca6752bbbe9fc860b26451f4490c6c7baa9e5e23e3fc4b3d18f14d91beaca`), verdict
`reject`, findings JF-1 (blocking), JF-2 and JF-3 (non-blocking). The empirical
(Codex) audit remains deferred; `review/audit-codex.md` does not exist, which the
revision note states rather than leaving to be inferred. Revision 1 is
`git show cca20fe~1:…/review/DECISION.md`, which still hashes to
`a1ad3736d627f6038a86564dc5c9a0dcc314a0bb5a10fdec825aa1cb795053dd` — the file I
audited.

## Principle and agreement level

Unmoved, and correctly so. The shared requirement, its two agreement levels
(`capability` for the check existing, `architectural pattern` for the packaged
artifact being the subject), the B1–B4 split between what must agree and what may
vary, and the F221/F222 dispositions are all untouched by this revision. What
changed in this section is a citation: B1's py cell now reads `ci.yml:222` (wheel)
and `:224` (sdist) instead of the range `:220-223`. I re-read the pin: at
`b08bccfb`, `.github/workflows/ci.yml:222` is
`uvx --from "$(ls dist/*.whl)" plbp --version` and `:224` is the same against
`dist/*.tar.gz`, so both cells and the `### Principles and implementation`
sentence now name exactly the two steps the principle rests on. The evidence for
the principle is therefore stronger than in revision 1, and the principle itself is
identical.

## Design and evidence

I read the complete `git show cca20fe` diff rather than the revised file alone.
**The diff is the revision note plus eight hunks, and every hunk is one of the
edits the revision note enumerates in advance.** For the record, since the count was
relayed to me as six: the hunks are (1) the preamble, (2) `ci.yml:204-223` →
`:204-224` in runner ground 2, (3) the `BASELINE-REVIEW` sentence on ts
`Justfile:307`, (4) the disposition paragraph's new credit to the raw's `:306-310`,
(5) the `### Principles and implementation` py citation, (6) the B1 table cell, (7)
`re-verify:` gaining trigger (13), and (8) the archive-rerun paragraph, plus the
`--debug` unproven row. That is eight content hunks after the preamble, and the
note's own enumeration lists exactly these edits (one for JF-1 plus the trigger,
one plus a sentence for JF-2a, three for JF-2b, one paragraph for JF-3). Nothing
else in the file moved: the recommendation block, the five-option table, AC1–AC7,
the cost model and its levers, the lockfile paragraph, the recipe-vocabulary
paragraph, the reference implementations and every figure in them, `## Parameters`
in full, the `## Empirical check` phase table, and Disagreements 1–5 are all
byte-identical to the text I approved on the merits in round 1.

**JF-1 is closed, and closed on the evidence rather than by softening the claim.**
The unproven row now states that no release-profile compile happens at pull-request
time; that `cargo publish --dry-run` does **not** exercise the release path because
it runs the same packaging-and-verification build this run measured, citing
`r50-check.log:89-91` (`Verifying r50spike v0.4.2` → `Compiling …` → ``Finished
`dev` profile [unoptimized + debuginfo] target(s)``); that R68's release build is
consequently the only release-profile compile the template is currently expected to
perform; and that **R68 is `open`**, which I confirmed in `research/CLAUDE.md`
(`R68 | release-binary-artifacts | crate | different | DIVERGENT | — | open`). The
superseded revision-1 wording is quoted in place, so the correction is legible
rather than silent. The flip condition survives unchanged and is now joined by
`re-verify:` trigger (13), R68 resolving, which is the right trigger: it is the
event that fixes where the release-profile compile lives. The row is narrower than
revision 1's and matches what the run can support. The revision note also names the
cause — the one engine claim (`raw/opus.md:975`) carried without testing in a
decision that elsewhere tested exactly this class of assertion — which is the
accurate diagnosis.

**JF-2 is closed, at the pin.** I re-read `cb1cbcb2:Justfile`: `:307` is
`EXPECTED="{{command_name}} $VERSION"`, an assignment, and the comparison is
`:308-310` (`if [ "$BIN_VERSION" != "$EXPECTED" ]; then` … `fi`) — which is now
exactly what the `BASELINE-REVIEW` paragraph says. The disposition paragraph credits
the raw report's `:306-310` as having been right and records the imprecision as the
synthesis's own; that is the correct attribution, since `raw/opus.md:105` does cite
`:306-310`. The evidence script is untouched and the decision explains why it needs
no change: its assertion matches the literal `EXPECTED="{{command_name}} $VERSION"`,
which is the `:307` assignment, so `PASS ts-pin/version-equality-307` remains a true
statement about the line it names. The py citations are corrected in both places,
and the beyond-the-brief widening of the job block to `:204-224` is right — the
`build-smoke` job runs from `:204` to its last step at `:224`, with `:225` blank.

**JF-3 is closed with an artifact, not a restatement, and I verified the artifact
rather than the sentence.** `review/evidence/r50-r2-archive-rerun.log` hashes to
`9f2010087b00b51cab453fde9a23d95834877ad2c3786b250d7b38e99a849ec5` and is 216
lines, both as stated. Counted directly over that log: `^PASS` returns **64**,
`^PASS archive` returns **10**, `^FAIL` returns **0**, `^SKIP` returns **1**, and
`^PASS ts-pin/` returns **0** — every number the paragraph states, including the
64-versus-54 miscount it warns a reader about. The wrapper asserts rather than
reports: `r50-r2-archive-rerun.sh:108-119` hard-codes exit 0, 54, 0, 1, a named
skip and 0 ts-pin assertions, and fails otherwise, and `:102` runs
`"$SCRATCH/tree/$REL"` — the copy extracted from `git archive HEAD` — with `HOME`
pointed at `$SCRATCH/nohome`, which is what makes `SKIP ts-pin/all — checkout
absent at <SCRATCH>/nohome/c/ts-launch-blueprint` (log `:45`) the expected outcome.
The no-`.git` and byte-identity assertions are in the log at `:8` and `:11`, and the
inner script's sha256 recorded at `:10`,
`bdd7bc3c3c0e7fb025b92382342403cd32250da074c150496537a90ad6d55a39`, equals the
working tree's `r50-check.sh` as I hashed it. The claim that `r50-check.sh` and
`r50-check.log` are carried forward byte-identical is confirmed by
`git diff cca20fe~1 cca20fe` over those two paths, which is empty, and
`r50-check.log` still hashes to `310e9f61…`. The wrapper's own "run twice and
`diff`ed byte-identical" sentence is an unretained reproducibility claim of the same
kind revision 1 made for the inner script, which I did not fault then and do not
fault now: the artifact whose counts mattered is retained, its output is normalised
so byte-identity is plausible, and the claim adds nothing the log does not carry.

## Completeness

Every field the role requires is still present and still correct, and the revision
adds three things the runbook wants rather than subtracting anything.

- **Revision provenance.** The revision note names the actor
  (`synth-opus-2026-09-17T020715Z-b7ef95f12806-r2`), the model, the kind and tier,
  the revision-1 sha and its commits, the audit that rejected it, and the absence of
  a `## Supersedes` because nothing has been published for R50 — which is right:
  R50 is `open` in `research/CLAUDE.md`.
- **Mechanical enumeration before editing.** The note lists the `/usr/bin/grep -n`
  hit sets it worked from. I checked them against revision 1 as I read it: for JF-1,
  lines 94, 186, 250, 451 and 582, of which only 582 carried the refuted coverage
  claim, and the other four are correctly characterised (ts's `npm pack --dry-run`,
  option E's "never runs the command", uv's pull-request gate, and phase E's
  unstable `--dry-run`); for JF-2a, 83-84 as the citation with 139, 268, 271, 337
  and 579 describing ts's equality *form*, which is indeed unaffected; for JF-2b,
  126 and 136 plus 54; for JF-3, 426-431. Each set matches the revision-1 text, and
  the edit count matches the hunk count.
- **Parameters and gates.** Untouched, and still correct: four `- assumes` lines,
  no `CONFLICT:`, gate 1 `inapplicable` under the 2026-09-12 owner ruling, gates 2,
  3 and 5 `inapplicable` with reasons, gate 4 answered by the macOS execution, gate
  6 treated as the cadence question.
- **Unproven rows.** Still honest, and one of them is now more honest: macOS-only
  execution, no timing, no adopter of the composition, AC7 proven only on a fixture,
  R69's placeholder binary, the exact `--version` string assigned to R22/R60, and
  the `--debug` trade with its coverage stated at the size the evidence supports.
- **Evidence integrity.** Two scripts and two logs, all committed, all four hashes
  stated in the decision and all four confirmed here.

## Findings

None. JF-1 is closed in full, JF-2 in both locations plus one beyond the brief, and
JF-3 with a committed, self-asserting artifact whose every stated number I
reproduced by counting its log. No new finding arose from the revised text, from the
diff, or from the two new evidence files, and nothing I approved on the merits in
round 1 has been weakened to close a finding.

## Assessment

Approved at revision 2. The correction went the direction an audit wants: the
coverage claim got narrower and the evidence got larger, with the superseded wording
quoted rather than erased, the cause named, and a re-verify trigger added for the
open item the trade now depends on. The recommendation is untouched — `cargo package
--locked --no-verify` → extract outside the repository → `cargo install --path …
--root <scratch>/root --locked --debug --no-track --target-dir …` → assert the file
exists and `rslbp --version` exits 0 carrying the manifest version, one `just`
recipe `install-check`, one `install-smoke` job on `ubuntu-latest` only, option B as
the ranked runner-up — as are every parameter value, every gate disposition, the
F222 `BASELINE-REVIEW` and its endorsement, and the empirical check that grounds
them. Nothing moved that a finding did not require.
