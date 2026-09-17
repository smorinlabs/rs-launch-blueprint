decision-sha256: 90628ace220ffdacb6170763c894342718e335e3d84e7bce4f405a8e8e1bd69e
actor: audit-fable-2026-09-05T163018Z-d7ade3a111f8-r6
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: F1: the star counts 27,756 (TruffleHog) and 1,226 (Kingfisher) are stated as read "at the cited log's retrieval instant" and "verified, evidence log section 04/05", and none of revision 6's four cited logs contains either number — they read 27,898 and 1,232; F2: the `GITLEAKS_LICENSE` organization-key requirement is the only ground for excluding `gitleaks/gitleaks-action` that survives the owner's Q7.B ruling, and it is labelled "verified, evidence log section 04" when no executed check in this run reads it — section 04's grep pattern cannot match the README text, so the quotation has never appeared in a cited log; F3 (minor, same class): "a current stable of 1.98.1" carries no endpoint and no retrieval date and appears in no cited log

## Principle and agreement level

The shared requirement is stated as an outcome and not as a mechanism: *a credential that is
live at merge time must not reach the default branch without a server-side check failing first*
(line 78), sourced to ledger row F050 (`docs/port/COMMONALITY.md:56`, which I read and which
reads as quoted) and to py's `.github/workflows/secret-scan.yml` at pin `b08bccfb`, reproduced
in the evidence log's section 01. The agreement level — **capability and policy, not tool and
not configuration** (line 80) — is recorded before alternatives are compared, as spec §2
requires, and it is argued rather than asserted: the scanner is an executed build tool that
enters no repository's public API and no repository's dependency graph.

The must-agree / may-vary table (lines 82–87) is the operative test and it is drawn at the right
line. *That* a non-bypassable CI-tier check exists and fails on a validated credential must
agree; *which binary* produces the verdict, *how* it reaches the runner, and *whether* the scan
is diff-scoped or full-history may vary. Spec §2's pattern-versus-tool boundary (spec lines
78–82) is honoured in both directions: swapping TruffleHog for Kingfisher is a **substitution**
under an unchanged pattern and is correctly not labelled `OVERRIDE`; and dropping py's
diff/full split is not an override either, because that split is not a recorded shared pattern —
F050's row note records only "distinct tool and tier", the prompt's `## Context` presents the
split as evidence, and the decision verified at the pinned tag that it exists to dodge the
Action's equal-base/head guard (`03a`, guard at `action.yml:70-72`, entered only via line 59 —
both reproduced in the log I read). The stronger claim that only a different tool can drop it is
explicitly refused at line 107.

The strongest contrary evidence in the item is confronted rather than buried: 0 of 10 surveyed
well-regarded Rust projects run such a job. The decision names the disanalogy — all ten are
public repositories where GitHub's native scanning is free, whereas a template's principal
deployment is a clone into a private repository — and adds that native scanning raises alerts
rather than a status check branch protection or R12 can require. That is a fitness argument
against practice evidence, which is what §2 and the prompt's survey method ask for.

Part 1 (keep the workflow) and Part 2 (the tool) are separated and carry different stated
confidence. That separation is the decision's best structural feature and it survives both
findings below, which touch Part 2's supporting citations and not Part 1.

## Design and evidence

**Architecture before library, and the library choice does not rest on agreement.** Four
architectures (A–D) are compared before any tool is weighed (lines 111–116) and each verdict
turns on the requirement rather than on preference: A fails in private clones; B inherits the
vendor's runtime constraints; D is left open under the `BASELINE-REVIEW:`. The selection is
demonstrably *not* from popularity or repository agreement — py runs TruffleHog, TruffleHog has
23× the stars, and the decision picks Kingfisher anyway, over the engine (codex) that
recommended the incumbent.

**Does the recommendation follow? Yes, at the medium confidence it claims, and it says where
the margin is thin.** The chain is: no gate excludes either candidate (line 168); the prompt's
macOS constraint excludes TruffleHog's *Action* only, on primary evidence I re-read in the log
(`docker run` at `action.yml:101`, `using: "composite"`), and that exclusion is itself qualified
as conditional on R11 in a paragraph that governs every later mention of it (line 124); under
shape C the two CLIs are equally integrable, which the decision states rather than hides; the
residual discriminators are therefore two — maintainer responsiveness (9/10 vs 0/10, explicitly
**carried** from the Opus raw and not re-executed, with the raw's own undercount caveat
repeated) and validation egress (17 vs 15,624 network requests, explicitly labelled
vendor-authored wherever used). The egress discriminator is principled rather than a
performance preference, and the decision says why: "each validation request transmits a
candidate string to a third party". A 900× difference in third-party transmission by a
secret-scanning tool is a data-minimisation argument, and its direction is structural (verify
every candidate versus pre-filter) rather than an artifact of the vendor's benchmark host.
Against that stand maturity and adoption, and the decision does not smooth them: line 126 says
"On raw maturity TruffleHog wins, and that is the strongest argument against Part 2", line 128
records that **no third-party well-regarded Rust project running Kingfisher in CI was found**,
and line 225 concedes "a reasonable reviewer could prefer the mature incumbent's CLI on those
grounds". The cost of being wrong is bounded and stated: one workflow-file edit, because both
tools consume the same repository and emit SARIF.

**The runner-up's winning condition follows.** The TruffleHog OSS CLI `>= 3.97.0, < 4.0.0` is
ranked with its install shape, and the switch is made testable rather than re-arguable:
trigger (1) — `archived: true`, no release for six months, or a maintainer notice — and trigger
(6) — P03 measures a live credential TruffleHog catches and Kingfisher misses. Both are
observable, both name the flip. The transfer rule is stated with the right asymmetry and it is
the part I pressed hardest on: the gate's *values* do not transfer (TruffleHog's documented exit
codes were never executed here, so a switch re-derives the allow-list at its own pin), while the
gate's *three conditions* do transfer unchanged, because they are properties of the GitHub
runner rather than of the scanner. That is correct, and it is the difference between a runner-up
that can actually be taken up and a name in a table.

**The gate rule, and what round 5's fail-open left.** The rule is an allow-list (`0` and `200`
pass, `205` fails, anything outside the documented set fails as a tool error) resting on an
executed set (`10a`, with `10b`–`10d` establishing that the table *is* the documented set and
not one file's contents) and two reachable codes outside it (`10e` = 2, `10f` = 1, `10g`). Its
second condition is the one that is genuinely earned rather than argued: section 12 runs the
rule's literal implementation under both shell command lines extracted from a pinned
`github/docs` commit and shows the gate **passing a job in which nothing was scanned** when the
scanner sits upstream of an unguarded pipe under `bash -e` (`12c`, `12f`), with four negative
controls isolating the pipeline as the mechanism (`12d`, `12e`, `12g`, `12h`). I read those
eight assertions in the script and in the log; they do what the prose says. The third condition
— the report as an additional condition and never a substitute — is reasoned, not executed, and
its reasoning ("a scanner that never ran wrote no report, and an absent or stale report reads as
zero findings") is sound on its face; it is the one part of the rule whose status the decision
does not label, which I note without making it a finding.

**What the workflow does on a finding, and whether that is verified.** The behaviour is: the
step fails, so the job fails, so the pull-request check is red. Merge-blocking is explicitly
**not** claimed — it is branch protection, deferred to R12, and the decision claims only that
"the job is an ordinary workflow job, so R11 and R12 can fold it in". Annotation is not claimed
anywhere; SARIF is mentioned only as a report shape the gate may read, never as an upload to
code scanning. The behaviour on a *live* credential is recorded as **unproven with what would
prove it** (acceptance criterion 3, and the unproven table's first two rows, both owned by P03),
and the gate-as-a-CI-job is acceptance criterion 5, "Proposed, not executed as a workflow". That
is the correct P03 posture and I do not fault it. **No `CONFLICT:` line is owed.** I checked the
two neighbours named to me: R16's decision recommends a separate `.github/workflows/codeql.yml`
and nowhere touches secret scanning; R34's decision defines a three-leg `canary.yml` for
toolchain and dependency freshness. R17's line 142 offers "a scheduled lane under R34, or a
documented maintenance note" as P03's version-refresh path — that is a correctly-scoped handoff
and not a claim about R34's content, and no registered parameter changes, which is what a
`CONFLICT:` line is for. R17 consumes nothing (`inputs/prompt.md` lines 19–20 are both empty),
so line 170's "No `CONFLICT:` line" is right.

**Environment dependence, read from the script rather than the prose — this is where five
rounds were spent, and revision 6 closes it.** I read all 923 lines of
`review/empirical/run-checks-r6.sh`. Every environmental dependency is declared in the header
block, probed in section 00, and either exercised or `SKIP`ped by name. `HOME` is replaced by a
fresh empty directory under `$TMPDIR` and the replacement is *asserted* (`00a`), not merely
performed. The API transport's branch is asserted per branch, and the anonymous branch's
assertion — core rate limit exactly `60` — is the executed statement that no ambient credential
reached the transport; I confirmed both branch labels appear in the logs that claim them. `gh`
authentication is a declared token or nothing, and with no token `07a`/`07d`/`07e`/`07f` `SKIP`
by name rather than passing on a login; the bare-mode log shows exactly that, with
`gh=/opt/homebrew/bin/gh token=none` printed in the skip reason. `07g` is redefined to something
that can still fail on a real host (the realpath's basename is `gh` and `--version` begins
`gh version` under the control's own empty environment), and `07i` reads the refusal code from
the resolved binary's own `gh help exit-codes` rather than from a literal. Section 13 resolves
every path from `dirname "$0"`, and `13p` is the single assertion that needs Git history and
skips by name. **I found no assertion that passes only because of something on the
synthesizer's machine.** One residual, recorded as an observation and not a finding: `bash`
itself — which section 12 invokes for both shells and section 00 prints the version of — is
taken from `PATH` and is neither in the declared ten nor in the probed helper toolchain. It
cannot mask anything: the version in force is printed in every log, `12a`/`12b` read the argv
from the pinned docs rather than from the host, the behaviours asserted are pipeline-status
invariants of any bash, and a broken `bash` would fail the assertions loudly rather than pass
them.

**Where the evidence does not reach the claim.** Two citations in this document point at
executed evidence that does not carry them, and they are in the one place a `RESULT`-line rerun
is structurally blind to: printed-never-asserted regions. They are F1 and F2 below.

## Completeness

| Required item | Status |
|---|---|
| `## Decision`, `### Principles and implementation`, `re-verify:` (line 144) | present |
| `## Parameters`, `## Empirical check`, `## Engines` | present, in order |
| `## Supersedes` | correctly absent — this is a revision, not a reversal |
| Owned parameters | none; the prompt's `- owns:` line is empty and the decision says so |
| The four `- assumes` lines | **byte-identical** to `docs/port/PARAMETERS.md`; I compared them field by field programmatically, and `13i`–`13l` additionally assert them unchanged from revision 2 |
| Settled ledger row | F050 named with its file and line, with the settled value; the ledger is not edited |
| `BASELINE-REVIEW:` handling | correct per the runbook: emitted in the four-field form, carried verbatim, unresolved, affected items named (R17, R39), ledger and R39 untouched, adjudication left to the controller. F050 is `py-only`/`DIVERGENT` and so was never in `BASELINE-REVIEW.md`'s REUSE/ADOPT scope — its absence there is right, not an omission |
| `CONFLICT:` | none owed (see above) |
| Six fitness gates | all six answered for **both** candidates in one table (lines 159–166), each labelled executed, carried, or `inapplicable` with its reason. Gate 1's `inapplicable` under the owner's 2026-09-12 Q7.B ruling is correct and I do not treat it as a finding |
| Source dates | present on the cited sources I sampled (GitHub Docs secret scanning, `action.yml@v3.95.9`, `docs/USAGE.md`, the pinned `github/docs` commit, the two community threads, the TruffleHog README) — all 2026-09-10 or 2026-09-12, with the run executed 2026-09-15. The exception is F3 |
| Unproven material | tabulated with what would prove it and who owns it, six rows, and the P03 test list repeats them |
| audit-codex r6 | consistent with this decision — see below |

**Figures I verified against the cited logs rather than accepted.** Log digests, line counts and
byte counts for all four r6 logs; `run-checks-r6.sh` = `479b3ab9…`; `rev2-DECISION.md` =
`e2c3d588…`, 48,926 bytes; the four recorded rerun modes' `summary:` lines (65/0/0, 64/0/1,
57/0/8, 65/0/0) and the eight named bare-mode skips; the assertion count (I counted 65 labels in
the script, and section 13's 15 + `13p`); `action.yml` sha256 `c3847cdb…` with the guard at
70–72, the entry condition at 59, the `else` branch at 78+, `docker run` at 101;
`docs/USAGE.md` sha256 `28cbe0ca…` with the whole `0 / 200 / 205` table printed; the eight ts
workflow files and the 0 scanner references; the tarball digest `4e741aba…` and both byte sizes;
485 rules; 29 blobs and one finding; `active_findings 0` / `failed_validations 1`; `gh version
2.98.0 (2026-08-20)` with observed exit 4. Every one of them matches. I also re-ran the email
sweep over the four new logs: zero matches, so revision 6's correction (1) holds.

**audit-codex r6 is consistent with this decision, and its coverage does not overlap mine.** It
binds the same digest, reran three modes from genuine `git archive HEAD` extractions under
`env -i`, applied three discriminating mutations that each produced exactly one failure, and
diffed every `RESULT` line plus `summary:` against the cited logs. Its approval is sound for
everything it checked. Both findings below live in printed-never-asserted regions that a
`RESULT`-line diff cannot reach, and its five citation spot-checks did not include the
`gitleaks/gitleaks-action` README.

## Findings

**F1 — two star counts are attributed to logs that do not contain them.** Line 126 gives
TruffleHog "27,756 stars at the cited log's retrieval instant … (verified, evidence log section
04)" and Kingfisher "1,226 stars … (verified, evidence log section 05)"; the evidence table
repeats both at lines 196 and 197; and line 182 states the rule that "the counter figures quoted
below are read at these logs' retrieval instant", where "these logs" are revision 6's four new
ones. **All four r6 logs record `stargazers_count` 27898 and 1232.** Revision 5's log recorded
27853 and 1229. The figures 27,756 and 1,226 trace to the round-1 and round-2 *audit* logs
(`review/evidence/audit-secret-scanning-ci-workflow-r1.log:110`, `…r2.log:115`) and have been
carried unchanged since revision 2. This moves no conclusion — the maturity gap is 23× either
way, and the decision itself marks stars as a drifting counter that is never asserted on — but
it is the document's own stated rule broken in the one region no rerun can catch, and it is the
same defect class the empirical rounds rejected five times: a figure presented as verified
against a named artifact that the artifact does not carry. *Either repair closes it:* replace
the two numbers with the r6 logs' values, or drop the "at the cited log's retrieval instant" and
"verified, evidence log section 04/05" attributions and label them as what they are.

**F2 — the only surviving ground for excluding `gitleaks/gitleaks-action` is labelled executed
when it is carried, and the check that would execute it cannot match.** After the owner's Q7.B
ruling removed licence compatibility from evaluation, the decision restates the exclusion on one
ground and says so four times — line 37 ("restated on the ground that survives the ruling — it
requires a purchased `GITLEAKS_LICENSE` key for organizations"), line 114 ("**both verified**,
evidence log section 04"), line 168 and line 223 ("of their two grounds only the purchased
organization key survives"). The evidence table at line 196 presents both README quotations as
section 04's observation. **`GITLEAKS_LICENSE` appears in none of revision 6's four cited logs,
and in none of revision 5's.** The cause is a pattern bug, not upstream drift: the script's
section-04 grep (line 383) is `GITLEAKS_LICENSE \(required`, and the README's text is
`` `GITLEAKS_LICENSE` (required for organizations `` — a closing backtick sits between the
identifier and the parenthesis, so the alternation only ever matches its second branch. I
fetched the live README under an empty `HOME` to confirm: the requirement is still there at
lines 43 and 75, and the script's pattern still yields exactly one line. So the **fact is true
and current** and the exclusion stands on its merits; what is wrong is the provenance label. The
correct label is the one the decision defines for itself at line 157: **carried** — Opus raw,
`gitleaks/gitleaks-action` README lines 43 and 75, `GET
https://api.github.com/repos/gitleaks/gitleaks-action/readme`, retrieved 2026-09-10 — not
executed. *Either repair closes it:* relabel the ground as carried with that endpoint and date,
or fix the one character in the grep pattern and let section 04 execute it.

**F3 (minor, same class) — a number with no endpoint.** "against a current stable of 1.98.1"
(lines 155 and 162) carries no source URL and no retrieval date, and appears in no cited log;
the host's own `rustc 1.98.0 (Homebrew)` is what section 00 prints, and that is the host's
toolchain, not a statement about current stable. The prompt's constraint (line 105) is that
every number carries its endpoint. It decides nothing — gate 2 is `inapplicable` because no
Rust toolchain compiles the scanner, and the "no headroom" observation survives either value —
but it is the third uncited-provenance instance in the same document and is cheaper to fix than
to defend.

**All three repairs are section-13-safe.** Lines 37, 114, 126, 155, 162, 196 and 197 are none of
them anchor lines: `13b`–`13o` read the Part 1 recommendation, the F050 ledger row, the
`BASELINE-REVIEW:` line, the two equal-base/head lines, the shape-C opener, the four `assumes`
lines, the provenance-diagnosis opener, the Part 2 recommendation, the ranked runner-up and the
validity-filter finding. The ten-same / four-differ split cannot move, and no `RESULT` line
changes.

## Assessment

Revision 6 does what round 5 asked and does it well. Ten environmental dependencies are
declared, probed and branched; the caller's `HOME` is replaced and the replacement asserted; the
credential is a declared token with the anonymous branch asserted at the 60-request ceiling;
`gh api` is gone; `07g` is redefined into something that can fail; section 13 carries its own
evidence and the one assertion that still wants Git history skips by name. Four rerun modes,
including a deliberately adverse shim-first `PATH`, all exit 0 and all reproduce. On the
substance six empirical rounds never judged: the principle is stated at the right agreement
level and preserved by a justified native design, the architectures were compared before the
tools, the library selection follows from gates and evidence rather than from popularity or
repository agreement, the runner-up's winning condition follows and transfers correctly, what
the workflow does on a finding is either executed or recorded unproven with what would prove it,
and every required field, gate, parameter and `BASELINE-REVIEW:` line is present and correct.

I still reject, on two citations and one uncited number. The recommendation follows and none of
the three findings moves a conclusion — but all three are the same defect this document has been
rejected for five times, relocated into the printed-never-asserted regions where an empirical
rerun is blind by construction. F2 is the one that matters: the sole surviving ground for
excluding a candidate architecture is presented as executed evidence, and the check written to
execute it has never matched. A reader who followed the citation to section 04 would find the
other half of the quotation and nothing else. Relabel it as carried with the Opus raw's endpoint
and date, or fix the pattern; correct the two star counters or their attribution; give 1.98.1 an
endpoint. None of it touches an anchor line, a `RESULT` line, or the recommendation.
