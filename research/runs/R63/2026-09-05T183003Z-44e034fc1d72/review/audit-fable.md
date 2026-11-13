decision-sha256: 0ce8e4378bc9a0b52eb62f8279c0897ba9116ba9c4f56b89154b23f721ab1b97
actor: audit-fable-2026-09-05T183003Z-44e034fc1d72-r4
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This audit binds revision 4 of `review/DECISION.md` at the hash above, which matches the
hash given in the task message. The round-3 judgment audit of revision 3 (hash
`4da47900a8d5a0629dfaaff644f2773c10fdb6dead454fcc186a41574405469d`, reject, one finding) is
preserved unedited at `review/audit-fable.r3.md`
(sha256 `4cc6f4df6dd1442c3e9126a1be0bf9a04a2a3914ce38de6885116a3f97d1b1c0`).

Read for this audit: `inputs/prompt.md`; both raw reports end to end (`raw/opus.md`, 864
lines; `raw/codex.md`, 97 lines — read in full, not sampled at the lines the decision
cites); `review/DECISION.md` in full; `review/audit-codex.md` (round 4) and its receipt;
`docs/port/PARAMETERS.md`; `docs/port/BASELINE-REVIEW.md`; `research/RUNBOOK.md`;
`research/CLAUDE.md` (index rows); the governing spec §2
(`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md`, lines 44-127);
the binding CLI Design Standard v1.4.14
(`/Users/stevemorin/c/cli-standards/cli-design-standard.md`, R4.1 option table, R4.4, R7.1,
R7.3, R7.4); `review/evidence/r63-quiet-baseline-r4.log`; and the two pinned source trees
read directly at their pins. `review/evidence/r63-crossrun-compare.sh` was **not** run, as
the task requires; the divergence between its committed hash and the round-3 audit record
is explained in the decision (`## Empirical check`) and is not treated as a finding here.

## Principle and agreement level

The stated requirement is right and is stated at the right level. Spec §2's table
(lines 45-47) names three levels; `capability/standard` is one of them, and
`docs/port/BASELINE-REVIEW.md`'s own reading note repeats that vocabulary verbatim. The
decision's "**capability and standard**" is that single level, not an invented compound,
and it is decomposed into what must agree (stream placement; a three-clause suppression
predicate) and what may vary (crate, frames, tick interval, the expression of "disabled").
That is the §2 shape: shared requirement, agreement level and source, essential behaviors,
ecosystem-specific design, and an acceptance check tying the design back to the
requirement.

**The `--quiet` clause, which is why round 4 exists, is now correct and is carried on a
rule rather than on engine agreement.** Revision 3's two-clause predicate conflicted with
the binding standard; revision 4 states three inputs to one call-site predicate in the
recommendation paragraph, the must-agree list, the essential behaviors, acceptance
criterion 6, criterion 5's scope, the design-preservation paragraph, the CLI fit note, the
py rationale and the `BASELINE-REVIEW:` line. `## Engines` item 8 records that both raws
had already converged on it and that revision 3 dropped the convergence — and then
explicitly subordinates the convergence to the rule: "it does not rest on engine
agreement — which is the correct order under the research mandate, since agreement alone
cannot select a design." That is the mandate's own ordering (spec §2, owner amendment A5),
applied against the failure mode the mandate exists to prevent.

**Press 1 — the `(SHOULD)` heading over a MUST-worded sentence.** I read both rules. The
disclosure is accurate and nothing depends on the label:

- `cli-design-standard.md:394` is `**R7.4 — Pager & progress. (SHOULD)**`; the heading is
  composite (the rule covers pager and progress together) and the body at line 395 carries
  its own RFC-2119 keywords — "Progress indicators **MUST** go to stderr (R7.1) and
  **MUST** be suppressed when not a TTY or under `--quiet`." Under ordinary RFC-2119
  reading the keyword in the sentence governs, and the pager half of the same line also
  carries a **MUST**, so a (SHOULD) heading over MUST-level sentences is the rule's own
  shape rather than an anomaly this decision must resolve.
- `cli-design-standard.md:265` is `**R4.4 — Verbosity semantics. (MUST)**`, and line 266
  contains "`--quiet`/`-q` suppresses progress and informational diagnostics on stderr
  only; it **MUST NOT** suppress the requested result on stdout". **R4.4 is the same
  obligation**, stated from the flag's side: progress is suppressed under `--quiet`. It
  adds the stdout-preservation half, which acceptance criterion 6 asserts in the same run.
  The decision quotes the sentence verbatim, so a reader sees for himself that the
  suppression half is declarative inside a MUST-labelled rule; the decision's wording
  ("restated inside the MUST-labelled R4.4") claims the label, not a keyword it does not
  carry. No overclaim.
- The handling makes nothing depend on the label. The decision carries the clause and says
  so: "This decision carries the clause, which conforms under either reading of the label,
  so nothing here depends on resolving it and no waiver is sought." Carrying a clause is
  conformant whether the sentence is MUST or SHOULD, so the design is label-independent;
  and the baseline challenge, which is the one place a MUST reading would do work, is
  independently supported by the MUST-labelled R4.4 cited in the same evidence field.
- Crucially, the disclosure is **asserted, not merely asserted-in-prose**: section 1 of
  `review/evidence/r63-quiet-baseline-r4.log` prints both headings verbatim with their
  line numbers (394 and 265) as content assertions, so a future reader cannot lose the
  `(SHOULD)` label to a paraphrase.

## Design and evidence

**Architecture before libraries, and the load-bearing rejection argued from source.**
Alternatives A-D are compared as designs, not as crate substitutions, and D — delegating
the gate to `indicatif`'s own terminal test — is rejected on two grounds read at pinned
versions: it would place a second TTY check beside R65's, which this item's `## Out of
scope` forbids, and it cannot cover `CI` at all, because `indicatif` 0.18.6 makes no
environment access (three greps, all zero matches, log section 16). The residual
asymmetry (`is_dumb()` in `console` 0.16.6 reading `TERM`) is named rather than glossed,
its direction is argued (it can only suppress, never write to stdout, because both gate
branches yield `hidden()` or `stderr()`), and the consequence for P03's tests — pin `TERM`
to a non-`dumb` value — is stated. Design C is not chosen because `--quiet` demanded it:
the decision is explicit that C was selected before the clause was known to be required,
which is why absorbing the clause needed no redesign.

**Selection follows from gates and source reading, not popularity.** Eight candidates (the
union of both raws' landscapes) are gate-checked; exactly one is gate-clean and
maintained, which the decision reports as the finding the prompt asks for rather than as a
result. Two exclusions carry independent grounds that would have decided them anyway
(`spinoff` writes to stdout by its own documentation; `spinners` panics on `EPIPE`), and
the decision says plainly that under a looser gate-2 reading `spinners` would reach the
shortlist and still lose — an honest statement of how much the gate is actually carrying.

**Press 2 — the `--debug`-overrides-`--quiet` ranking handed to R60.** This is a
legitimate hand-off, not a gap, on four independent grounds:

1. **The predicate's normative form absorbs the override.** It is stated throughout as
   "`--quiet` is **not in effect**", not "`--quiet` was not given". A resolved boolean
   computed by the verbosity ladder is exactly what that phrasing consumes, so R4.4's
   `--debug` override changes the value fed in, not the predicate.
2. **The owner is the right one.** R60 (`cli-parsing-framework`) is a `bundle` covering the
   global-option declarations and stackable global options (F270); R63 owns no parameter
   and consumes none, and says "R63 defines no flag; it consumes the resolved boolean,
   exactly as it consumes R65's resolved TTY answer." The R65 analogy is the pattern this
   item's own prompt endorses for the TTY half.
3. **The source precedent resolves the ladder at the same boundary.** At ts pin
   `cb1cbcb2`, `src/router.ts:132` is
   `.option('--debug', 'maximum diagnostics; implies -v and overrides -q', false)` and
   `router.ts:105` folds `verbose`, `quiet` and `debug` into one `resolveLevel(...)` call.
   The ladder already lives in the parser layer in the repository F283 records — so
   locating it in R60 preserves the inherited structure rather than inventing one.
4. **The gap is declared, not silently left.** `## Engines`' unproven-claims list states
   "R4.4's rule that `--debug` overrides `--quiet` has no resolved ranking here — R63
   consumes a boolean it does not compute", and the `re-verify:` trigger fires on R60
   landing the global option set, requiring the implementer to "record how R4.4's
   `--debug`-overrides-`--quiet` ladder ranks against it". Spec §2 prescribes precisely
   this treatment: "Where the boundary is unresolved, state the gap and recommend a
   boundary with evidence instead of treating it as decided."

Neither raw report mentions `--debug` anywhere (zero matches in `raw/opus.md` and
`raw/codex.md`), so no engine convergence on the ranking was available to drop. The
round-3 failure mode is not repeated.

**Press 3 — the `BASELINE-REVIEW: F283` line.** It is in the runbook's form and it says
what the ts source actually does.

- **Form.** `research/RUNBOOK.md:22` fixes
  `BASELINE-REVIEW: F### — principle — proposed change — evidence`. The line at
  `DECISION.md:173` opens at column 0 with `BASELINE-REVIEW: F283` and carries exactly
  those four em-dash-separated segments. Routing matches `RUNBOOK.md:167` — the controller
  adjudicates it with the affected decision — and the decision states that it changes no
  other item and no ledger file, and that the recommendation already carries the clause so
  P03 is not blocked while it is pending.
- **Mechanism.** `BASELINE-REVIEW:` is the correct instrument and `OVERRIDE (OV-nn)` is
  not available: spec lines 88 and 110 confine `OVERRIDE` to a pattern row of legal origin
  `same`, and F283 is `DIVERGENT` with origin `ts-only` (`research/CLAUDE.md:68`). The
  decision leaves that verdict and origin explicitly unchanged. `docs/port/BASELINE-REVIEW.md`
  adjudicated only the `COMMON → REUSE` and `ADOPT` rows and therefore holds no F283 row,
  so the line contradicts no recorded adjudication.
- **Factual accuracy, re-read by me today at the pin, not taken from the log.**
  `src/router.ts:131` is byte-exactly
  `.option('-q, --quiet', 'only show warnings and errors', false)`; `quiet` occurs on
  exactly three lines of that file (78, 105, 131); `router.ts:105` is the only *consumer* —
  line 78 is the type field `quiet: boolean;`, a declaration and not a feed — so "feeds it
  only to the log level" is literally true; `projects.ts:127` is `const ci = deps.env['CI'];`
  and `:128` is `const spinnerEnabled = deps.stderrIsTTY && (ci === undefined || ci === '');`;
  and `grep -c quiet` returns `0` for both `src/commands/projects.ts` and
  `src/lib/adapters.ts`. Every clause of the evidence field is exact.
- **Supporting check.** `review/evidence/r63-quiet-baseline-r4.log` (78 lines, sha256
  `b081a1e33b2fb87cfb855565a5588485215479716f19d589904b7b660f417d7a`, `checks: 21 pass /
  0 fail`) asserts all of the above on content, not on exit codes: `lineis` echoes the
  numbered line it read and `has` asserts a match count, so the two absence claims read
  `(matching lines) == 0`. Its four controls are the right ones — wrong line text, an
  absence asserted where the literal is present, an unreadable checkout, and a true-count
  positive — and their verdicts are themselves asserted as `probe tally == 1 pass /
  3 fail`, so a control cannot quietly stop failing. The round-4 empirical audit reran it
  three times byte-identically.

**Nothing material in either raw is unaccounted for.** Because the round-3 finding was in
part a dropped convergence, I read both raws end to end and checked every substantive
assertion against the decision rather than only the lines it cites. Everything either raw
raises is adopted, adjudicated with evidence, or declined with a stated reason: Codex's
cancellation criterion (routed to R67's exit-code taxonomy), its `--no-input` criterion
(declined as R61's subject), its `CI` predicate, its zero-width regression test, its
`prodash` macOS gap and its RustSec-404 reading (all four adjudicated in `## Engines`
items 1-4); Opus's `--no-progress` note, its informal R65 `assumes` line, its criterion
5, its `in_memory` dev-dependency, its `enable_steady_tick` requirement and its
library/web exclusions (all adopted). Two raw-only items are dropped without an explicit
note, and both are correctly dropped: Opus's `spinach` licence-history caution and its
`cliclack` `once_cell` advisory analysis are gate-1 material, which the settled 2026-09-12
Q7.B ruling strikes.

One divergence between the raws is not recorded as such, and I checked it rather than
assume: the mandated issue-responsiveness figure differs between them — Codex reports a
median of about 13.2 hours over 8 answered of 10 (retrieved 2026-09-05), Opus a median of
0.13 days, about 3 hours, over 8 answered of 10 (retrieved 2026-09-10). The decision
carries Opus's figure alone. That is correct and is covered rather than overlooked: the
window is the ten *most recently opened* issues, so a five-day gap changes the sample;
`## Uncertainty` states the governing rule ("Codex's figures were not re-queried at their
own retrieval date") and names this exact figure as carried forward unconfirmed; and the
figure decides nothing, because the `active` maintenance verdict is stated to rest on the
release date, `pushed_at` and `archived: false`, all of which the check asserts. Both raws
agree on the two numbers that would matter — 8 answered, 2 unanswered — and both medians
support the same verdict.

**Press 4 — everything the round-3 audit cleared, re-confirmed.**

| Cleared item | Status in revision 4 |
|---|---|
| `indicatif = "0.18"` (0.18.6), CLI crate only | Unchanged; library exclusion restated with the semver reason, plus the `in_memory` dev-dependency for acceptance tests |
| Design C, call-site-owned `ProgressDrawTarget` | Unchanged; the `--quiet` clause reaches the same `hidden()` value by the same route |
| `spinner` 0.5.0 excluded on maintenance | Unchanged; archived 2020-04-20, newest unyanked 2019-11-04, and the table says in terms that gate 1 now excludes nothing |
| R65 and R61 named honestly | Verified against their prompts: R65 owns F290's TTY mechanism; R61 owns `--no-input`'s behavioral fork (F360) and the prompt crate. `--no-input` is declined with that reason rather than by silence |
| Four `- assumes` lines | Byte-identical to `docs/port/PARAMETERS.md` rows 7-10, re-diffed today |
| `review/audit-codex.md` rerun | Consistent: it binds this same decision hash, approves with no unresolved finding, and its recorded figures (1071 lines / 168 checks; 21 checks and the `b081a1e3…` hash for all three quiet-baseline runs) match the decision's claims exactly |

## Completeness

All four required H2s are present with non-empty bodies (`RUNBOOK.md:181-190`):
`## Decision` carrying the recommendation, the version, the settled `F283` row,
`### Principles and implementation` and a `re-verify:` line with seven named triggers;
`## Parameters`; `## Empirical check` with toolchain, host, command, working directory and
observed output; and `## Engines` with both reports, four adjudicated disagreements, the
figure-drift accounting and an explicit uncertainty statement. No `## Supersedes` is
required — no revision has been published and R63's index row is still `open`
(`research/CLAUDE.md:68`), which is what the decision states.

Owned and assumed parameters: none owned (the prompt's `- owns:` line is empty), four
fixed parameters assumed and byte-exact, and the absence of a `CONFLICT:` line is stated
with its reason rather than left implicit. The two informal non-registry dependencies
(R65's TTY check, R60's `--quiet`) are named as such and correctly kept out of the
`assumes` list.

All six fitness gates are reported. Gate 1 is `inapplicable` with its reason, per the
settled 2026-09-12 Q7.B ruling. Gates 2-6 pass with figures, and gate 6 states plainly
that no measured byte or second figure exists because no crate exists to build. Source
dates are present and their non-uniformity is explained rather than smoothed: 2026-09-10
for pinned-source readings and the preserved tables, 2026-09-13 for re-quoted live
figures, 2026-09-15 for the new check, with the two citations covered by neither
(`astral-sh/uv` on a moving branch, and the two in-repository ledger reads) named
individually.

The empirical check verifies what it is cited for and the decision claims no more.
Acceptance criterion 6 is marked unproven on its face, with the test that would prove it
named concretely (`InMemoryTerm` with `TERM` pinned non-`dumb`, asserting empty contents
and an intact stdout JSON body). The unproven-claims list carries six entries, each with
what would prove it, and the `--quiet` clause is described as "the least proven thing
here" with its documentary support separated from the behavior nobody has observed. That
is the correct posture for a research decision whose template P03 builds.

## Findings

None.

## Assessment

**Approve.** Revision 4 repairs all three limbs of the round-3 finding without disturbing
anything that was right. The predicate now has the clause the binding standard requires,
stated once and consumed at one call site; the prompt's LOW question is answered with a
mechanism (`indicatif` 0.18.6 has no flag surface and reads no environment variable, so
gating cannot live in the crate) rather than a preference, and `--no-input` is declined on
a stated ownership ground; the wrong affirmative baseline sentence is replaced by a
correctly formed, correctly routed `BASELINE-REVIEW:` line whose every factual clause I
re-read at the ts pin today and found exact. The recommendation, crate, version, design
alternatives, gate outcomes, exclusions, runner-up condition and parameter lines are
unchanged from the revision two auditors already examined, which is what a repair of this
kind should look like.

One non-blocking observation for the controller, recorded because it is a wording matter
and not an evidentiary one. The recommendation paragraph describes the third input once as
"the parsed value of the CLI's own `--quiet`/`-q` flag". Under R4.4 the *parsed* and
*effective* values diverge in the single `-q --debug` case, where `--debug` must win. Every
normative statement of the predicate in this document uses the effective form — "`--quiet`
is not in effect" in the recommendation, the must-agree list, the essential behaviors and
the `BASELINE-REVIEW:` line, and "consumes the resolved boolean" in the must-agree list and
`## Parameters` — and the same sentence that says "parsed value" cites "R4.4's verbosity
ladder" two clauses later, so no implementer following the normative text ships a spinner
that wrongly suppresses under `-q --debug`. It is one descriptive phrase against four
normative ones; tightening "parsed" to "resolved" at publication would remove the last
ambiguity. This does not rise to a finding and does not qualify this approval.

Acceptance now requires the controller to confirm the second approving verdict and current
consumed values; the round-4 empirical audit (`review/audit-codex.md`, `gpt-5.6-terra`,
family openai) approves the same decision hash with no unresolved finding.
