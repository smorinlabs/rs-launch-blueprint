decision-sha256: 7e6ecd93e64abf664689445c94877b5b50f85762a947b66e47c17959a610a7ef
actor: audit-fable-2026-09-05T163018Z-d7ade3a111f8-r9
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-4 (blocking): the star counts 27,941 (TruffleHog) and 1,232 (Kingfisher) and the instant `2026-09-16T05:03:35Z` are stated as "read … in this revision's own run" and as the evidence table's section-10 observation, and no log this revision cites carries them — all six revision-8 logs read 27960 and 1233 at instants between 22:22:48Z and 22:28:54Z, and the quoted pair is revision 7's log; JF-5 (blocking, same class): the Rust-stable retrieval instant `2026-09-16T05:03:38Z` at lines 189 and 242 is likewise revision 7's, where the logs this revision cites read the manifest at 22:22:50Z–22:28:55Z (the value 1.98.1 and the manifest date are in the cited logs and are correct); JF-6 (non-blocking): `## Empirical check` still says "the six recorded runs open at `UTC now:` instants between …" nine lines above "**Nine runs are recorded**", and only five of revision 8's six recorded runs print a `UTC now:` line at all

## Principle and agreement level

The remit for this round is the whole current text, not the delta from revision 8. On the parts
round 6 judged, nothing has regressed and I re-checked each rather than carrying my predecessor's
verdict.

The shared requirement is still stated as an outcome and not as a mechanism — *a credential that
is live at merge time must not reach the default branch without a server-side check failing
first* (line 108) — sourced to ledger row F050 (`docs/port/COMMONALITY.md:56`) and to py's
`.github/workflows/secret-scan.yml` at pin `b08bccfb`, reproduced in the evidence log's
section 01. The agreement level (line 110, **capability and policy — not tool, not
configuration**) is recorded before alternatives are compared, and the must-agree / may-vary
table (lines 112–117) keeps *which binary produces the verdict* on the may-vary side.

**The owner's ruling lands on the may-vary side of that table, which is why it is a substitution
and not an override.** W0-R17b (`docs/port/OWNER-REVIEW.md`, "2026-09-15 — R17 secret scanner:
TruffleHog CLI, pinned binary") directs the **TruffleHog OSS CLI, `>= 3.97.0, < 4.0.0`,
installed as a pinned release binary in a `run:` step with `--only-verified --fail`**, on both
owner-fixed runners, after validating that py runs TruffleHog in CI and ts has no secret-scan CI,
and it leaves Part 1 standing with Kingfisher as runner-up. Part 2 (line 75) states exactly that
version range, that install form, those two flags and both runners; Part 1 is unchanged and its
recommendation line is asserted byte-identical to revision 2 (`13b`); the runner-up is Kingfisher
with the reversed winning condition (line 85). The ruling's two grounds are re-executed rather
than recited: py's pin, tag `trufflesecurity/trufflehog@v3.95.9`, `--only-verified` and its
ubuntu-only runner (`01a`–`01c`), and ts's eight workflow files with zero scanner references
(`02a`). **The ruling is implemented exactly.**

**The additions beyond the ruling are correctly attributed to the packaging layer the ruling does
not speak to, and they are not departures.** `--fail-on-scan-errors`, the `--github-actions`
output format, the passing set `{0}` of the documented `{0,1,183}`, the three runner conditions
and the report-as-additional-condition are all this document's own; line 75 splits confidence on
precisely that seam — "the TOOL is high, and it rose from revision 6's medium … the packaging and
the gate stay medium" — and says what P03 may overturn is "no longer the tool; it is this
document's shape for running it". No `OVERRIDE (OV-nn)` is owed, because nothing contradicts a
recorded pattern or an owner ruling.

Per owner ruling Q7.B (2026-09-12, recorded at `docs/port/OWNER-REVIEW.md` and
`docs/planning/p02/execution-ledger.md:505`), fitness gate 1 is struck from every item's
evaluation and is recorded `inapplicable` rather than deleted. The decision does that at line 195
and explains why it is recorded rather than dropped (published acceptance records cite the prompt
by digest). **I raise no licence finding.**

## Design and evidence

**The three carried findings are closed, and I checked the scripts and logs rather than the
prose that reports them.**

*Round-7 F1*, quoted from `review/audit-codex.r7.md`: "**F1: 08a's zero `redact` matches in
`--help` does not establish that `--redact` does not exist, because 06d establishes that this
release has hidden flags**". The text that answers it is line 83: "TruffleHog ships no `--redact`
flag, and that is **executed** rather than inferred from `--help`: invoked with it, the pinned
binary answers `trufflehog: error: unknown long flag '--redact', try --help` and exits `1`, on
both the `filesystem` and the `git` source, where the accepted control flag `--no-verification`
exits `0` on both (`08e`, `08f`)." `run-checks-r8.sh:713–734` does exactly that: two `--redact`
invocations (`filesystem "$WORK/redactprobe"` and `git "file://$WORK/fixA"`), two
`--no-verification` controls on the same targets, `08e` asserting the quadruple `1 1 1 1` (two
exits, two message counts) and `08f` asserting `0 0 0 0`. The `--help` count is printed at
line 733–734 with "PRINTED, NEVER" and carries no `RESULT` line. Both assert `PASS` in
`review/evidence/secret-scanning-ci-workflow-r8-repo.log:222–223`. **Closed.**

*Round-7 F2*: "**F2: 08c checks only the synthetic PAT bytes while the decision claims that
`--github-actions` prints no secret, leaving the other fixture credential values untested**". The
answering text is line 83 — "on the same fixture it writes **zero** occurrences, on stdout and on
stderr, of **each of the three values this scanner detects** — asserted one value at a time, so
each can fail on its own (`08h`, `08i`, `08j`)" — and line 45's explicit retraction: "this
document no longer says `--github-actions` 'prints no secret', it says it prints no occurrence of
the three values this scanner detects, and names the fourth as undetected". The script asserts
three distinct variables, each as a stdout/stderr pair (`08h` `$G_PAT $GE_PAT`, `08i`
`$G_AKIA $GE_AKIA`, `08j` `$G_SK $GE_SK`), with `08g` pinning the detector set (`2 AWS,Github`)
as the oracle for "detected" and `08k` asserting the URI's four zero counts. The two surviving
principle labels — "Name the finding's location without printing the secret" (line 119) and
"*Names the location without printing the secret*" (line 156) — are scoped inside the same
sentence to "each of the three fixture values this scanner detects", so they are section headings
for evidence that is correctly narrowed, not residual overclaims. **Closed.**

*Round-8 F3*, quoted from `review/audit-codex.md`: "**F3: `review/empirical/mutations-r8.sh` does
not reproduce under its recorded ordinary invocation because its `PY3=$(command -v python3)`
accepts the host's failing `mise` shim; neither mutation is applied, so its claimed falsifiability
evidence depends on an undeclared clean PATH.**" The answering text is lines 53–57 and
measurements (5), (7), (8) and (9) in `## Empirical check`. `mutations-r9.sh` exports
`HOME="$WORK/home"` at line 74 — **before** `resolve_tool` is defined or called at lines 78–92 —
resolves `python3` by probing each candidate for `print(7*6)` = `42`, exits `2` by name when none
passes, and prints the interpreter, its `--version` and either `python3 first on PATH was
BYPASSED: …` or `… was NOT bypassed: …`. I read all four new logs: each ends `mutation-harness
failures: 0` and `RESULT: PASS`, each mutant exits `1`, mutation 1 fails `08h`/`08i`/`08j` and
mutation 2 fails `08e` with `08f` still passing, and `/usr/bin/grep -c 'mise ERROR'` returns
**0** on all four where the same count on
`review/evidence/audit-secret-scanning-ci-workflow-r8-mutations-ambient-path.log` returns **8**,
exactly as line 213 states. The shim-path and auditor-form logs print the `BYPASSED` line naming
`/Users/stevemorin/.local/share/mise/shims/python3`. **Closed.**

**The falsifiability claim is itself falsifiable, which is the part worth saying.** The added
set assertion (`mutations-r9.sh:170–184`) collects the mutant's FAILing labels and compares them
**as a set** with the targets, and `mutate_and_run`'s mutator exits when a target string does not
match exactly once, so a mutation that silently failed to apply is a harness failure rather than a
pass. Revision 9's claim at line 59 that this is new relative to revision 8 is accurate.

**The comparisons the four new logs are said to support reproduce.** Measurement (7) against (5):
25 changed lines on each side, every `RESULT`/`summary:`/`MUTATION CHECK`/`mutation-harness` line
identical once the `grep -n` prefix is stripped. Measurement (8) against (5): three changed lines
on each side — the `HOME` line, the `source under mutation:` line naming the extraction root, and
the `mutant workspace:` line — with the same `sha256 697ea3b1…` for the mutated script. Measurement
(9) against (5): exactly two differing lines, the two `summary:` lines, whose `FAIL=` figures `3`
and `1` do not move, plus exactly two lines (5) does not print, the `04g` skip named once per
mutant. Each of those is what the document says. Two counting conventions sit side by side —
(7)'s "25 lines" counts one side, (8)'s "six lines" counts both — and the verdict-block cardinal
"39" depends on where the block is delimited (I get 38 or 40 under the two readings of the
document's own enumeration). Neither moves a claim, both reproduce in substance, and I record them
as observations rather than findings.

**Architecture before library, and the ruling does not hollow that out.** Four architectures are
still compared before any tool is weighed (lines 143–148), and shape C is recommended on its own
grounds *and* named as the form the ruling directs. The provenance argument for shape C is
correctly re-derived for the new tool rather than transferred: TruffleHog publishes **no** GitHub
build attestation (`04g`, asserted as an absence, so it fails if that ever changes — the log shows
the endpoint answering `HTTP 404` for digest `57e2a41c…`), and what is executed instead is the
Sigstore-signed `checksums.txt` (`04a`–`04e`), with the chain-and-Rekor check a named `SKIP`
(`04h`) because cosign is absent. The qualification paragraph at line 152 states in full what
`openssl dgst -verify` does not establish. That is the right posture and it is unchanged from the
one round 6 approved.

**The gate rule is re-derived at the new tool's pin, not carried.** `06a` reads the documented set
`0 / 1 / 183` from `README.md` at `v3.97.4` and compares it as a set (`PASS` at
`…-r8-repo.log:152`), and the allow-list of *passing* codes is `0` alone, with `183` and `1` and
anything outside the documented set failing. The two tool-level fail-open paths are executed
(`07g`–`07j`), and all eleven observed codes lie inside `{0,1,183}` (`07k`). Every mention of
Kingfisher's `0 / 200 / 205` in the current text is either a historical revision note or the
runner-up transfer paragraph at line 85, which states correctly that the rule "transfers in form
but not in values". I found no location where the old values leak into the recommendation.

**The unproven table is honestly scoped, and the adverse row is the test of that.** Six rows, each
with what would prove it and who owns it. Row 2 enters the `postgres://user:password@localhost:5432/appdb`
non-detection as evidence **against** the decision's own assumption: "**Revision 8 executed one
data point against this row and it is adverse** … One synthetic `localhost` URI is not a
measurement of the detector's behavior on a real database URL, and it is not evidence that the
class is missed; it is evidence that this row is not safe to assume". That is the correct reading
of `08g`/`08k` in both directions — it neither inflates one fixture into a detector verdict nor
buries it — and line 49 repeats it without softening. Row 4 records `04h` as a `SKIP` that "never"
counts as a pass. Row 3 refuses to compare TruffleHog's carried "700+" against revision 6's
executed 485 because the two counts are not commensurable. I press on none of these.

## Completeness

| Required item | Status |
|---|---|
| `## Decision`, `### Principles and implementation`, `re-verify:` (line 178) | present |
| `## Parameters`, `## Empirical check`, `## Engines` | present, in that order |
| `## Supersedes` | correctly absent — unpublished revision, not a reversal |
| Owned / consumed parameters | none; the prompt's `- owns:` and `- consumes:` lines are empty and line 182 says so |
| The four `- assumes` lines | **byte-identical** to `docs/port/PARAMETERS.md`: I rebuilt all four lines from that file's table rows programmatically and `diff` against lines 184–187 is empty. `13g`–`13j` additionally assert them unchanged from revision 2 |
| Settled ledger row | F050 named with file and line and its settled value; the ledger is not edited |
| `BASELINE-REVIEW:` handling | correct: emitted in the four-field form at line 168, carried verbatim, unresolved, affected items named (R17, R39), ledger and R39 untouched; line 170 states why the ruling does not disturb it (rs and py now share a tool, which F050 does not speak to; F050's clause is about the two tiers inside one repository) |
| `CONFLICT:` | none owed; no registered parameter changes (line 204) |
| Six fitness gates | all six answered for **both** candidates in one table (lines 193–199), each labelled executed, executed (r6), carried, or `inapplicable` with its reason. Gate 1 `inapplicable` under Q7.B is correct and is not a finding |
| Source dates | present on the sources I sampled; the exceptions are JF-4 and JF-5, which carry a date belonging to another revision's run |
| Unproven material | six rows with what would prove each and who owns it, repeated in the P03 test list |
| audit-codex | round 8 (bound to `b9af0931`) rejects on F3 alone and records F1 and F2 "repaired by executed, falsifiable checks"; revision 9 changes only F3's artifact, and I confirm the quotations at lines 41 and 53 are verbatim from `audit-codex.r7.md` and `audit-codex.md`. Round 9 is pending and binds nothing yet |

**Figures I verified against the cited artifacts rather than accepted.** `run-checks-r8.sh`
`697ea3b1…` / 993 lines; `mutations-r8.sh` `0663adc4…` / 137 lines and
`…-r8-mutations.log` `66db94fa…` / 65 lines, both **byte-identical**, which is what makes line 61's
preservation claim true; `mutations-r9.sh` `774eb8d4…` / 225 lines; the four r9 logs
`476c491a…`, `c3ad7680…`, `5de422b1…`, `dc2c8c02…` at 85/85/85/87 lines; the four r8 run logs
`d49dd10a…`, `7b1978a0…`, `867f3fff…`, `55d8aa01…` at 305/304/245/307 lines;
`…-r8-rev7-script-against-rev8.log` `35bd65ee…` / 282 lines; `rev2-DECISION.md` `e2c3d588…` /
48,926 bytes. Every one matches the document. The provenance digests match too: `git show
6d159fd:…/DECISION.md` is `4c312aae…` and `git show 68377e2:…` is `c8cbb44a…`, as lines 216 state.
The r8 repo log carries exactly **71** `RESULT`/`summary` lines, as claimed. Release figures
71,971,202 and 170,569,362 bytes, tarball digest `57e2a41c…`, `v3.97.4` published
2026-09-03T20:01:40Z, 2 darwin + 2 linux tarballs, `09a`'s two verified findings with detectors
`AWS,URI` at exit `183`, `11a`'s `GITLEAKS_LICENSE` at lines **43** and **75** of the README at
commit `bcfb9cce…` with its digest asserted by `11b`, and `12a`'s manifest date 2026-09-03 with
`1.98.1 (48a229cea 2026-09-01)` — all present in
`review/evidence/secret-scanning-ci-workflow-r8-repo.log`. Round 6's F2 and F3 are therefore
substantively repaired; what is left of F3's class is the retrieval instant, JF-5.

**The anchor claim holds.** I extracted the eleven `cmp_anchor` prefixes and the three
`moved_anchor` pairs from `run-checks-r8.sh:961–976` and searched the `781feac..HEAD` diff of this
file — revision 8 to revision 9, 18 insertions and 6 deletions — for every one of them. **None
appears.** Line 61's "no `RESULT` verdict in any section changes" and line 225's closing check are
accurate.

## Findings

Numbering continues from the round-6 judgment audit's F1–F3.

**JF-4 (blocking) — two counters and their retrieval instant are attributed to a run this
revision does not cite, and the values in the logs it does cite are different.** Line 160 reads:
"TruffleHog is the mature incumbent and is now the recommended tool: **27,941 stars**, `archived:
false`, AGPL-3.0, created 2016-12-31, latest release `v3.97.4` on 2026-09-03 — the licence and the
archived flag asserted (`10a`, `10b`), the star count **read at 2026-09-16T05:03:35Z in this
revision's own run** and never asserted on, because it is a counter that moves." The same line
gives Kingfisher "**1,232 stars** at the same instant", and the evidence table's section-10 row
(line 240) repeats both: "Read at 2026-09-16T05:03:35Z: `trufflesecurity/trufflehog` 27,941 stars
… `mongodb/kingfisher` 1,232 stars".

**All six revision-8 logs — every log this revision cites for the run that produced sections 00–13
— record `stargazers_count: 27960` and `1233`**, read at instants between `2026-09-16T22:22:48Z`
and `2026-09-16T22:28:54Z`
(`review/evidence/secret-scanning-ci-workflow-r8-repo.log:240–242`, and the archive, archive-bare,
shim-path and rev7-script logs identically). A search for `27941` across all six revision-8 logs
and all four revision-9 logs returns **zero**. The quoted pair belongs to revision 7's run:
`review/evidence/secret-scanning-ci-workflow-r7-repo.log:217–218` reads `27941` and `1232` at
`2026-09-16T05:03:35Z` — and line 214 of this document says revision 7's logs "are untouched and
remain their own revisions' records", so they are not this revision's evidence.

Why it is blocking rather than cosmetic: this is round-6 finding F1 recurring one revision after
its recorded repair, in the same printed-never-asserted region where a `RESULT`-line rerun is
blind by construction — which is why neither round 7's nor round 8's empirical audit could catch
it. It also breaks a rule this document states about itself in revision 9's own new prose, at the
end of line 216: "The counter figures quoted in this document are read at these logs' retrieval
instant and will drift." And revision 9 reaffirms rather than merely inherits the figures: line 61
says "no table figure moves". Revision 7's repair was sound when written; revision 8 regenerated
the logs with a full rerun of sections 00–13 and did not carry the new values forward.

*What resolves it:* restate both counters and the instant from a log this revision cites (27,960
and 1,233 at 2026-09-16T22:25:39Z from `…-r8-repo.log`), **or** relabel them as revision 7's run
with that log named, dropping "in this revision's own run". Neither touches an anchor line or a
`RESULT` line, and neither moves a conclusion: the maturity gap is 23× at either pair, and the
counters are printed and never asserted on.

**JF-5 (blocking, same class) — the Rust-stable retrieval instant is also revision 7's.** Line 189
reads: "read from `https://static.rust-lang.org/dist/channel-rust-stable.toml` — manifest date
2026-09-03, `[pkg.rust] version = \"1.98.1 (48a229cea 2026-09-01)\"`, retrieved
2026-09-16T05:03:38Z (`12a`)", and the evidence table's section-12 row (line 242) repeats "read
2026-09-16T05:03:38Z". That instant is `…-r7-repo.log:239`. The logs this revision cites read the
same manifest at `22:22:50Z`–`22:28:55Z` (`…-r8-repo.log:262`).

This is narrower than JF-4 because the **value** is genuinely in the cited logs and is correct:
`…-r8-repo.log:261` prints `manifest date: 2026-09-03; [pkg.rust] version: 1.98.1 (48a229cea
2026-09-01)`, and `12a` passes there. Only the retrieval instant names a run this revision does not
cite. It is nevertheless the round-6 F3 defect in its repaired form — the endpoint is now given,
the date is not this run's — and it is listed because the fix is one token.

*What resolves it:* replace the instant with the cited log's (2026-09-16T22:25:41Z), at both
line 189 and line 242.

**JF-6 (non-blocking) — a stale run count nine lines above its own correction.** Line 208 reads:
"Executed 2026-09-16 (each section's own instant is printed in the log; **the six recorded runs**
open at `UTC now:` instants between `2026-09-16T22:22:17Z` and `2026-09-16T22:28:25Z`)", while
line 213 reads "**Nine runs are recorded**, all on 2026-09-16". Two further details: only **five**
of revision 8's six recorded runs print a `UTC now:` line at all — the mutation-harness log
(`…-r8-mutations.log`) carries none — and revision 9's four new logs carry none either, so the
quoted window is the endpoint pair of the five run-checks logs and nothing wider. The two instants
themselves are correct (`…-r8-rev7-script-against-rev8.log:29` and `…-r8-archive-bare.log:29`).

It is non-blocking because it misstates no evidence and moves nothing; it is listed because it is
the "present-tense claim written for an earlier revision" class this document has already had to
scope five times by its own count, and because a reader comparing the two sentences cannot tell
which is current. *What resolves it:* scope the sentence to revision 8's run-checks runs, or give
the count as five and say which logs carry a `UTC now:` line.

**Would the recommendation move under any finding? No.** None of JF-4, JF-5 or JF-6 touches the
tool (settled by owner ruling W0-R17b), the install shape, the passing exit set `{0}` of
`{0,1,183}`, `--fail-on-scan-errors`, the output-format requirement, the runner-up or its reversed
winning condition, an `- assumes` line, an anchor line, or any `RESULT` line. All three live in
printed-never-asserted regions. Each is a provenance label, not a fact.

## Assessment

Revision 9 does what round 8 asked, and it does it by the mechanism the evidence script already
used rather than by a new one: `HOME` is replaced before anything is resolved, `python3` is
resolved by probing for a working interpreter, the binary actually used is named in the log with
its version, a bypassed shim is named, and the harness exits `2` by name if no candidate passes
instead of reporting unapplied mutations as failures. The four new logs reproduce under the
ambient `PATH`, under a shim-first `PATH`, from a clean `git archive` extraction, and under the
auditor's own invocation form with no declared token — `mise ERROR` count zero in all four, against
eight in round 8's failing run. The added set assertion makes each mutation prove it broke its
targets *and nothing else*. F3 is closed, and round 7's F1 and F2 remain closed under my own
reading of the script and the log rather than on round 8's say-so.

On the substance my remit covers: the ruling is implemented exactly, the additions beyond it are
correctly located in the packaging layer and confidence-labelled there, the gate is re-derived at
the new tool's own pin with the passing set narrowed to `0` and both tool-level fail-open paths
executed, the fitness gates are all answered for both candidates with gate 1 `inapplicable` under
Q7.B, the four `- assumes` lines are byte-identical to `docs/port/PARAMETERS.md`, the unproven rows
are honestly scoped — the undetected `localhost` database URI is entered as adverse evidence
against the decision's own assumption and is not laundered into a detector claim — and every
preservation claim about earlier files is true at the digest level.

I still reject, on two provenance labels and one stale count. JF-4 is the one that matters: it is
round-6 F1 reappearing one revision after its repair, with a figure and an instant presented as
this revision's own run when every log this revision cites carries different ones. That it moves
no conclusion is exactly what made the same defect survive rounds 7 and 8 — a `RESULT`-line rerun
cannot see a printed counter, so the only place it can be caught is here. Restate the two counters
and the two instants from the logs this revision cites, or relabel them as revision 7's with that
log named; scope the "six recorded runs" sentence. None of it touches an anchor line, a `RESULT`
line, or the recommendation.
