decision-sha256: 32b4a3904630f63a964baf5dc5904a0b156a578f180ae37b083a9291f7a69a83
actor: audit-fable-2026-09-05T163018Z-d7ade3a111f8-r12
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged, and re-checked rather than carried. Revision 12 edits two lines and adds eight: the
title, the two corrected measurement sentences inside `## Empirical check`'s measurement list (line
233), a three-paragraph revision note (lines 77, 79, 81) and an enumeration record (line 251). It
touches no recommendation, no gate wording, no runner-up, no `BASELINE-REVIEW:` line and no
fitness-gate row. Part 2 is still the TruffleHog OSS CLI, `>= 3.97.0, < 4.0.0`, a pinned release
binary in a `run:` step with `--only-verified --fail` under owner ruling W0-R17b; the passing set is
still `0` alone of the documented `{0,1,183}`; `--fail-on-scan-errors` is still required; fitness
gate 1 is still `inapplicable` under Q7.B and I raise no licence finding.

`4c7118f` changes one file, with 10 insertions and 2 deletions. I searched the whole
`4c7118f~1`-to-`4c7118f` diff for section 13's fourteen anchor prefixes and for `- assumes`: **zero
hits**. The four `- assumes` lines are still byte-identical to `docs/port/PARAMETERS.md`, rebuilt
from that file's table rows and `diff`ed to empty. The six artefacts line 81 names are unchanged on
disk — `mutations-r11.sh` `3a29123c…`, `mutations-r11-curl-shim.sh` `a1cf665d…`,
`fixtures-r11/MANIFEST.txt` `423f97fb…`, `mutations-r9.sh` `774eb8d4…`, `mutations-r8.sh`
`0663adc4…`, `run-checks-r8.sh` `697ea3b1…` — and no log changed, since the commit touches only
`DECISION.md`.

## Design and evidence

**JF-9 is closed, and I reproduced both diffs from the committed revision-11 logs rather than
reading the repair paragraph.** The measurement list at line 233 now states each figure per side,
names each category with an example line, and quotes the superseded wording in place.

*Measurement (7), `…-r11-mutations.log` against `…-r11-mutations-shim-path.log`.* The corrected text
says "both files are **118** lines and `diff` reports **28 differing lines on each side**, in two
categories and no others", then "**Six per side carry a path this run generated or a resolution it
made**" — naming `HOME used by this harness:`, `mutant workspace:`, the shim's `placed at:` line,
the two per-mutant section-00 `curl=<workspace>/bin/curl` echoes and the interpreter-resolution line
— and "**The remaining twenty-two per side are the echoed section-08 `RESULT` lines**", whose only
difference is the `grep -n` prefix. **Measured here:** both logs are 118 lines; `diff` reports 56
lines, 28 on each side; normalising the prefix and re-running `diff` leaves **12**, and the six that
remain on each side are exactly the six the sentence names, in that order. So the twenty-two are the
prefix and nothing else, which is the claim the sentence says it measured, and it does.

*Measurement (8), the same log against `…-r11-mutations-archive.log`.* The corrected text says
"`diff` reports **7 differing lines on each side**, in two categories and no others. **Five per side
carry this run's `mktemp` workspace** … **Two per side name a committed file by absolute path, and
each prints the same digest on both sides**", with "no fixture line differs at all, because the
harness prints the six recorded bodies by digest and basename rather than by path". **Measured
here:** `diff` reports 14 lines, 7 on each side; five carry the `mktemp` workspace (`HOME used by
this harness:`, `mutant workspace:`, `placed at:`, and the two section-00 echoes) and two are the
shim's `source:` line and the `source under mutation:` line, whose printed digests — `a1cf665d…` and
`697ea3b1…` — are identical on both sides and equal the files on disk. No fixture line appears in
the diff, and no `RESULT` line differs.

*And the two figures are now on the same footing.* Revision 12 records the cause of the original
defect rather than only its correction: "measurement (7)'s figure was a per-side count and
measurement (8)'s was a both-sides total, stated side by side as though comparable. Both are now per
side and say so." That was the ambiguity I declined to make a finding in round 10 and which
round 11's JF-9 turned on; naming it is what stops it recurring.

**Nothing else moves, and I checked the claims in line 81 rather than accepting them.** No `RESULT`
label, verdict, count or exit status changes; the four revision-11 logs still end
`mutation-harness failures: 0` and `RESULT: PASS` with `60 0` before and after; no measurement's
conclusion moves; the anchors and `- assumes` lines are untouched. The fixture-boundary reasoning I
approved in round 11 is unchanged, and revision 12 adds nothing to it.

**Line 77's account of the round-11 empirical audit is accurate in every particular, which I checked
because a compressed quotation of another audit is the kind of claim that has slipped here before.**
That audit ran `mutations-r11.sh` four times — ordinary ambient `PATH` and the no-credential
scratch-`HOME` mise-first form, each from the run directory and from a clean `git archive HEAD`
extraction — with all four exiting `0` (its line 10); mutation 1's observed failing set exactly
`08h`/`08i`/`08j` and mutation 2's exactly `08e` (line 12); zero `no recorded fixture` and zero
`mise ERROR` (line 19); the unchanged revision-8 and revision-9 digests (line 21); the five request
sites at 218/221, 353, 842, 843 and 884 with "Section 08 has zero API request lines" (line 18); and
the live anonymous budget read as `60 20` before and after its reruns (line 12). The decision's
gloss on that last figure — "which is the comparison rule working as written, since what the rule
requires is equality within a run and not a particular remaining figure" — is right, and it is the
correct reading of its own rule rather than a convenient one.

## Completeness

| Required item | Status |
|---|---|
| `## Decision`, `### Principles and implementation`, `re-verify:` (198), `## Parameters` (200), `## Empirical check` (226), `## Engines` (275) | present, in order |
| `## Supersedes` | correctly absent — unpublished revision |
| Owned / consumed parameters | none; the prompt's `- owns:` and `- consumes:` lines are empty |
| The four `- assumes` lines | byte-identical to `docs/port/PARAMETERS.md`, verified programmatically |
| Ledger row, `BASELINE-REVIEW:`, `CONFLICT:` | unchanged and correct |
| Six fitness gates | all six answered for both candidates; gate 1 `inapplicable` under Q7.B |
| Findings JF-4 to JF-8 | closed in revisions 10 and 11 and unaffected here |
| JF-9 | closed; both diffs reproduced above from the committed logs |
| Scripts, shim, fixtures, logs | untouched; the commit changes `DECISION.md` alone and every named digest matches disk |
| audit-codex | round 11 bound `6a26da1a…`, `verdict: approve`, `unresolved-findings: none` — consistent with this decision and with my round-11 audit's closure of JF-7 and JF-8. Round 12 is queued and owns the reruns; this audit binds nothing to it and states consistency with round 11 only |

**One observation, recorded because it is a count and this document is judged on counts — not a
finding.** Line 81 reads "`run-checks-r8.sh` `697ea3b1…` and **all fifteen committed logs** are
byte-identical". `git ls-files review/evidence` lists **25** committed decision-side logs
(`secret-scanning-ci-workflow*.log`: revision 5's 2, revision 6's 4, revision 7's 5, revision 8's 6,
revision 9's 4 and revision 11's 4), and the group the sentence's own digest list implies — the logs
those six artefacts produced, which is revision 11's "all ten of revisions 8's and 9's logs" plus
revision 11's four — is **14**. No candidate set has fifteen members.

I record this as an observation rather than a finding, and the line matters so I state it rather
than leave it to be inferred. In JF-4 and JF-9 the number *was* the claim: a reader who checked it
found the claim false — no cited log carried 27,941, and three differing lines were unaccounted for.
Here the claim is that the logs are byte-identical, that claim is true of **every** log in **every**
candidate set, and I verified it: the commit touches `DECISION.md` alone. Only the cardinal labelling
the set is wrong, which is the tier of round 9's JF-6 (a run count contradicting a neighbouring
count while both instants were correct) and of round 10's JF-8 — both of which I judged
non-blocking, and JF-8 reached a header only because a blocking finding was already forcing that
reject. There is no blocking finding this round. *The repair is one word,* and the next edit made
for any reason should carry it: "fourteen" for the group those digests name, or "twenty-five" for
all committed logs.

## Assessment

Revision 12 does exactly what round 11 asked and nothing else. Both file-difference figures were
re-taken from the artefacts and written down as they print — 118 lines each, 28 per side for
measurement (7) and 7 per side for measurement (8) — and both are now given per side, split into
named categories with an example line rather than a bare number. I ran both `diff`s against the
committed revision-11 logs and they reproduce exactly, including the part that was previously only
asserted: normalising `grep -n`'s prefix and re-diffing leaves 12 lines, which is the six-per-side
category and confirms that the twenty-two section-08 echoes differ in the prefix alone. Measurement
(8)'s two path-bearing lines carry identical digests on both sides, and no fixture line differs at
all. The document also records why the original figures were wrong — one per-side count printed
beside a both-sides total — which is the more useful half of the repair.

The substance I judged in earlier rounds is undisturbed: the recommendation implements owner ruling
W0-R17b exactly, the gate rule and its runner conditions are unchanged, the fixture-shim
falsifiability proof and its honestly drawn boundary stand as I approved them in round 11, JF-4
through JF-8 remain closed, and the round-11 empirical audit approved the revision this one corrects.
Every digest, anchor and parameter line I checked is unchanged. One count in a
"what did not change" paragraph names a set of fifteen logs that does not exist; every log it means
is byte-identical, which is what the sentence asserts, so it is an observation for the next edit and
not a reason to hold this revision. I approve.
