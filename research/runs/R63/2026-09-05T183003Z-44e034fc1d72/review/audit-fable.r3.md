decision-sha256: 4da47900a8d5a0629dfaaff644f2773c10fdb6dead454fcc186a41574405469d
actor: audit-fable-2026-09-05T183003Z-44e034fc1d72-r3
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: suppression-predicate-omits---quiet-conflicting-with-the-binding-cli-design-standard-r7.4-must-and-leaving-the-prompt-s-low-question-unanswered

## Principle and agreement level

The shared requirement is stated at the right level and is not weakened into a goal.
The decision declares the agreement level **capability and standard** with two halves
that must agree — stream placement (stderr) and the suppression predicate — and it
records the ts predicate verbatim at the pin rather than paraphrasing it
(`DECISION.md:120-141`; `projects.ts:127-129` at pin `cb1cbcb2`). The semantics it
extracts — any non-empty `CI` suppresses, an empty `CI` does not — are exactly what the
quoted source says. What may vary (crate, frames, tick interval, the mechanism
expressing "disabled") is separated from what must agree, per spec §2.

The ledger citations are correct as read today: `docs/port/COMMONALITY.md:287` and
`docs/port/areas/cli-framework-ux.md:27` are the F283 rows, and both carry
`ts-only`/`DIVERGENT`. Leaving that verdict unchanged is right — py ships no indicator,
which the check confirms independently (grep exit 1 at py pin `b08bccfb`).

The defect is in the **standard** half. Since the owner's 2026-09-14 ruling, the org CLI
Design Standard (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`, v1.4.14)
binds this template, and **R7.4** reads: "Progress indicators **MUST** go to stderr
(R7.1) and **MUST** be suppressed when not a TTY or under `--quiet`." The decision
satisfies the first two clauses and not the third. It also never cites the standard as a
binding document — the only appearance of `cli-standards` is inside a quotation lifted
from the ts decision record (`DECISION.md:127-128`), i.e. as ts history rather than as
the standard this item must conform to. Because R7.4's progress sentence is MUST-level,
the standard's own waiver mechanism (lines 12 and 50: only SHOULDs may be waived, with a
documented rule ID, deviation, rationale and owner/date) is not available; a conforming
decision must carry the clause or record it as a named gap for P03.

Consequently the decision's affirmative baseline statement is wrong. It says "**No
`BASELINE-REVIEW:` line is emitted**… F283's recorded requirement — a stderr spinner
gated on stderr TTY-ness and the absence of `CI` — survives scrutiny unchanged"
(`DECISION.md:105-111`). I checked the ts pin: `src/router.ts:131` defines
`-q, --quiet`, and `src/commands/projects.ts:128` gates the spinner on
`deps.stderrIsTTY && (ci === undefined || ci === '')` only — nothing consults `quiet`,
and `src/lib/adapters.ts` has no quiet branch either. The **inherited requirement itself
fails R7.4**, so the prompt's `BASELINE-REVIEW: F### — principle — proposed change —
evidence` mechanism (prompt line 7) was the required vehicle here, and the decision
affirmatively declined it. Handling of `CONFLICT:` is correct: neither raw raised one and
no registered value needs changing.

## Design and evidence

**Architecture before libraries — genuinely done.** Alternatives A–D are compared before
any crate is picked (`DECISION.md:165-172`), and D (delegate gating to the crate) is
rejected on evidence read at the published 0.18.6 artifact, not on taste:
`ProgressDrawTarget::term` begins `if !term.is_term() || is_dumb() { return
Self::hidden(); }` (`draw_target.rs:79-82`), and `indicatif` 0.18.6 makes no environment
access at all (three greps exit 1, each additionally asserted as a zero match count). The
residual asymmetry — `is_dumb()` in `console` 0.16.6 can additionally hide when `TERM` is
unset or `dumb` — is named rather than glossed, bounded correctly (it can only suppress,
never write to stdout, because both gate branches yield `hidden()` or `stderr()`), and
converted into a P03 obligation to pin `TERM`. That is the right treatment of `TERM=dumb`.

**Library selection follows from principles, not popularity.** The clearest instance is
the refusal of `is_ci`: its predicate is value-equality against three literals plus 35
presence-checked variables, which diverges from the inherited contract in both directions
(`CI=yes`; `GITHUB_ACTION` with `CI` unset). That is read at a pinned published artifact
(`is_ci-1.2.0/src/lib.rs:25-70`, log section 3), and it decides the `std` recommendation
on contract-preservation grounds. Adoption figures are carried as `VOLATILE:` and
explicitly decide no gate.

**The re-admitted candidate was re-evaluated, not rubber-stamped.** `spinner` 0.5.0 loses
its gate-1 exclusion and is re-grounded on the maintenance rubric alone, which the prompt
defines (`archived` is one of the five rubric verdicts). The new ground is verified
independently in the check rather than asserted: log 1061-1067 shows `archived=true`,
`pushed_at 2020-04-20`, newest unyanked `0.5.0 2019-11-04`, and the licence string is
labelled in the log itself as recorded fact that "excludes nothing". The exclusion table
labels the row "none — excluded on maintenance" instead of burying the change
(`DECISION.md:315`), the shortlist sentence is restated to say two of seven exclusions are
not gate failures (`DECISION.md:302-305`), and `## Engines` item 7 records the
contradiction with the licence review's characterization of R63 rather than quietly
repairing it. The recommendation does not change and the reason is stated: the
re-admitted candidate loses on a non-licence ground it failed independently. Gate 1 as
`inapplicable` with the 2026-09-12 (Q7.B) ruling named is correct, and no `PASS` line in
the log asserts a struck gate-1 verdict (checked at log 246, 426, 1012, 1064).

**Standard conformance, clause by clause, and what the decision says it proved.** Stderr
placement: source read at 0.18.6 (`progress_bar.rs:147-154`), recorded as acceptance
criterion 1, unproven. Non-TTY: criterion 3, unproven. `CI` including `CI=""`: criterion
2, unproven. `TERM=dumb`: addressed as above, source read. `NO_COLOR`: **not a finding** —
the prompt puts it out of scope under R65 (prompt line 14) and the standard itself
excludes color, `NO_COLOR` and `FORCE_COLOR` from its scope (standard line 32).
`--quiet`: **absent everywhere** — zero occurrences of `quiet` or `no-input` in the
decision. The five criteria are correctly recorded as unproven with what would prove them
(a `TermLike` fake, a pty, `TERM` pinned, `cargo tree -i indicatif`); declining to
implement is right for a research decision and I do not fault it.

**The omission is a dropped convergence, not an oversight the raws share.** Both engines
answered the prompt's LOW question. Opus calls it out by name — "This is the whole answer
to the LOW question about `--quiet`: the gating lives [at the call site]" (`raw/opus.md:196`)
— and its migration table folds "not-a-TTY, `CI` set, `--quiet`, and later
`--no-progress`" into one `fn target(&self) -> ProgressDrawTarget` shaped after `uv`'s
`Printer` (`raw/opus.md:664-666`). Codex puts `--quiet` and `--no-input` in its acceptance
criteria (`raw/codex.md:17`), its migration plan (`:74`) and its validation strategy
(`:89`). The decision's `## Engines` records neither the convergence nor a deliberate
drop, which the runbook requires of that section (`RUNBOOK.md:188`).

**Minor, recorded but not escalated.** Codex alone requires cancellation to clear the
spinner line (`raw/codex.md:17`); the decision's essential behaviors name the success and
error paths only, with criterion 4 covering post-exit residue. That is a Codex-only
divergence the `## Engines` section does not mention, but no standard rule requires it in
those words, so it is a note, not a finding.

**Consumers and coupling are named honestly.** R65 appears five times and in the right
places: as the out-of-scope owner of F290, as the single TTY check the predicate consumes,
as acceptance criterion 5 ("a search of the workspace finds exactly one TTY test"), as the
one informal non-registry dependency in `## Parameters`, and as a re-verify trigger. R61
is handled with unusual care — the runner-up condition states the double-renderer-on-one-
stderr-line risk and explicitly refuses to decide R61 by side effect. R05 is named for the
deliberately-off `tokio` feature. R85 is not named, and I checked whether it should be:
R85 selects `anstyle-hyperlink` 1.0.2 and `supports-hyperlinks` 3.2.0, pulls no `console`
and renders no progress, so there is no real coupling to declare. Its absence is not a
defect.

**The empirical check verifies the claims it is cited for, and the r3 rerun is
consistent.** I re-hashed all five archived predecessors and every one matches the sha256
the decision records (`r63-spinner-claims.r1.sh/.log`, `.r2.sh/.log`,
`-negative-control.r2.log`). The cited log is 1071 lines with exactly 126 `VOLATILE: ` and
4 `HOST: ` lines and 168 `PASS` lines, ending `checks: 168 pass / 0 fail` / `RESULT: PASS`
— matching every figure the difference rule (R1/R2/R3) states. The comparator ends
`failed assertions: 0`. The run directory is clean against `HEAD`. One bookkeeping note
that breaks no claim: `audit-codex.md` records the classifier log at
`b38cba4a10c128af08364160ade596b2158fb5d50b7f0fae475dd1083c185742`, while the committed
file hashes `cc1fba04ec35060314faf590d2ade846b4232cde3d3d34e2eb44a3297f2a2c16` (identical
to `git show HEAD:…`); this is the controller's restore after an audit rerun overwrote one
ambient-locale line, and the decision cites no sha256 for that file.

## Completeness

Required H2s per `RUNBOOK.md:181-190` are all present and in order: `## Decision` with
`### Principles and implementation`, the settled `F283` row and a `re-verify:` line;
`## Parameters`; `## Empirical check` with toolchain, OS, working directory, exact command
and observed output; `## Engines` with both reports, five adjudicated disagreements and an
explicit `**Uncertainty**` block. `## Supersedes` is correctly absent — no revision has
been published, R63's index row is still `open` — and the decision says so in its first
paragraph rather than leaving the absence unexplained.

Parameters: no `owns` and no `consumes` lines, which matches the prompt's empty `- owns:`
and `- consumes:`; no `CONFLICT:`, correctly. The four `assumes` lines are byte-identical
to `docs/port/PARAMETERS.md`, checked value by value — `msrv-policy` ("stable minus 2
minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and
tested in CI"), `rust-edition` (`2024`), `target-os-matrix` (`ubuntu-latest, macos-latest`)
and `license` (`MIT OR Apache-2.0`) — and each is argued for its bearing on the decision
rather than merely listed.

All six fitness gates are reported, none omitted: gate 1 `inapplicable` with the ruling
named, gates 2-6 passed with figures, gate 6 explicitly qualitative with the reason no
byte figure exists. Source dates are present on every citation, and the two citations the
check does not cover — the `astral-sh/uv` `printer.rs` read on a moving branch and the two
in-repository ledger reads — are named individually under `## Engines` item 5 instead of
being folded into the blanket re-assert sentence. That is the correct handling.

The one completeness gap is the prompt's LOW question: "Does the candidate crate support
being disabled entirely via a runtime flag (composing with `--quiet`/`--no-input`), or
does that gating have to live in the call site rather than the crate?" (prompt line 36).
It has no answer anywhere in the decision, and the tier guidance is explicit that the
Focused tier "does not remove any prompt section, approved question, owner requirement,
shared principle, acceptance criterion, or applicable fitness gate" (prompt line 71).

## Findings

**Reject — the suppression predicate omits `--quiet`, conflicting with the binding CLI
Design Standard R7.4 and leaving the prompt's LOW question unanswered.** The decision
states the predicate as exactly two halves that must agree — stderr TTY-ness and `CI`
absent-or-empty (`DECISION.md:122-141`) — describes it as "a single function" whose TTY
half is R65's (criterion 5), and gives five acceptance criteria none of which mentions
`--quiet`. R7.4 is MUST-level and MUSTs are unwaivable under the standard's own
conformance language, so a P03 implementer following this decision literally ships a
spinner that renders under `--quiet` on an interactive stderr. Three independent grounds
converge: (1) the standard conflict; (2) the unanswered LOW question, which both raws did
answer and whose answers `## Engines` neither adopts nor records as dropped; and (3) the
affirmative "no `BASELINE-REVIEW:` line" claim, which is wrong because the ts
implementation the requirement is drawn from does not suppress under `--quiet` either
(`router.ts:131` defines `-q, --quiet`; `projects.ts:128` ignores it).

Two limbs, separable by the reviser. `--quiet` is the MUST conflict and must be carried:
add it as a third suppression input to the one predicate, extend criteria 2-4 (or add a
sixth) to cover it, record the `## Engines` convergence, and emit
`BASELINE-REVIEW: F283 — progress suppressed under --quiet — add the quiet clause to the
recorded requirement — CLI Design Standard R7.4; ts `projects.ts:128` at pin `cb1cbcb2`
does not consult it`. `--no-input` is only the unanswered prompt question: answering it
"a prompting concern owned by R61, not a progress input" would be legitimate, provided
the decision says so rather than staying silent.

No other unresolved finding. Nothing from rounds 1 and 2 dangles: r1's uninvoked
`supplements()` defect and r2's three evidence defects are each answered, and I confirmed
the archived artifacts those answers rest on are byte-identical to the hashes recorded.

## Assessment

Reject on one finding. **The recommendation itself follows from the principles and the
evidence, and I would not disturb it.** `indicatif = "0.18"` (0.18.6) in the CLI crate
only, design C with the render/suppress choice owned by the call site and expressed as a
`ProgressDrawTarget`, and a `std::env::var_os("CI")` predicate with
`is_none_or(|v| v.is_empty())`, are each derived from stated principles and verified
source rather than from adoption figures or repository agreement; the `dev-dependencies`
`in_memory` addition is the right way to make criteria 2-4 checkable without a pty. The
defect is not in the pick and does not reopen the candidate search: design C's call-site-
owned target already absorbs a third suppression input with no redesign — the `uv`
`Printer` the decision cites as its reference implementation folds `quiet`, `verbose` and
`no_progress` into exactly that one method. What must change is the stated predicate, the
acceptance criteria, the `## Engines` record, and the baseline line. The evidence
discipline in this revision is otherwise strong: claims are qualified as source reads
where they are source reads, the unproven list is honest and carries what would prove
each item, and the comparator demonstrates its own failure modes rather than asserting
them. Revision 4 should be a narrow edit, not a re-research.
