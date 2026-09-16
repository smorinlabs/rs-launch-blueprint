decision-sha256: 67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2
actor: audit-fable-2026-09-05T183002Z-09f93cfc507c-r7
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: F4 — row E5's claim to verify "every other standard line this decision cites" covers twelve of them, and two unverified citations (`:483`, `:270`) name a heading line where the quoted text is on the next line; F5 — the `bpaf` promotion condition is unmeasurable and absent from the `re-verify:` line, replacing a measurable trigger the raw report supplied; F6 — `string` and `wrap_help` are supported only by adopter manifests, the raw report's functional reason for them is dropped, and one is now obsolete under option (b); F7 — gate 2 is applied as a bar for exclusions but granted on the declaration half alone, with "No CI configuration was read in this run" carried to gate 4 only

This is the first judgment audit of R60. Seven empirical rounds have run; rounds 4, 5
and 6 rejected on evidence-script statements and no auditor has judged the substance.
I read `inputs/prompt.md`, all three raw reports (`codex.md`, `opus.md`,
`doxa.normalized.md` with its three provider bodies), `review/DECISION.md`,
`review/audit-codex.md`, `docs/port/PARAMETERS.md`, `docs/port/BASELINE-REVIEW.md`,
the spec's governing rule at
`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md:22-41` §2
together with its restatement in the prompt's `## Context`, the pinned standard
snapshot, the committed `clap` snapshots, `r60-standard-pin-r5.sh`, R66's accepted
decision and R64's and R69's gate-2 treatments. The decision hash matches the one
I was given; I bound it and read that text.

**Nothing below challenges the recommendation.** `clap` 4.6.6 derive, `clap_complete`
4.6.9, the dependency-free `build.rs`, `strsim` transitive, option (b), zero
overrides and the owner's ruling all stand. The four findings are precision and
completeness defects in how the decision supports what it recommends, in the same
shape as the r4, r5 and r6 rejections.

## Principle and agreement level

**The principle is stated at the right level and it is the right principle.** P1 is
`single-source interface declaration` at **capability** level (ledger F264
`DIVERGENT`): what must agree is that every derived artifact is generated, never
hand-maintained in parallel; what may vary is which crate generates and whether the
front end is derive or builder. That is the correct level — the shared requirement is
read out of both source implementations (py `cli/main.py:29`, ts `src/router.ts:13`,
both through their pins) and then explicitly generalized past them: "The principle is
not 'use a parser library'." The decision also names the principle's residual risk
precisely — drift is confined to a *committed* artifact, the completion scripts, which
is what AC4 exists for. That is a sharper statement than either raw report reached.

The seven-row agreement table distinguishes five levels and does not flatten them.
Three rows are `capability` (P1, P5, P6), two are `standard` (P2, P4), one is
`capability + standard` (P3), one is `capability` with a standard floor (P7). I
checked each against the pinned text. P2's escalation is correct and load-bearing:
the template is in the Standard profile because Appendix A's entry criteria are
conjunctive (`:578`, "all MUST hold") and criteria 1 and 2 fail for a two-resource
template built to be extended, which makes R1.1 a `MUST` (`:124`) rather than a
preference between py and ts. The counter-example at `:586` is quoted verbatim and
correctly flagged as carrying the standard's own illustrative plurals rather than the
template's grammar.

**R1.3 is the decision's strongest piece of work and it is right.** `:133-137` in the
pinned snapshot reads exactly as quoted, including the ❌ example "documenting `acme
widgets list` as the primary form", and row 5 of the org-locked Decision Log is at
`:67` as claimed. The decision's grammar conforms: the canonical documented noun is
`project`, the plural is permitted only as a hidden alias, and the clap mechanism is
verified rather than assumed — `Command::alias` is documented hidden (`:2664-2666`)
and `visible_alias` visible (`:2865-2868`), and the derive path to the hidden one is
traced through `clap_derive`'s generic branch. I confirmed the decision departs from
*both* source ports here and correctly declines to file an override for it: R1.3 is a
non-waivable `MUST` and `:50` admits waivers only at `SHOULD` level, so recording
conformance as a choice would misrepresent it. `## Engines`' "No engine raised R1.3"
is accurate — I searched all five provider bodies and none mentions noun number — and
the inference drawn from it ("agreement among engines is not evidence of conformance")
is exactly the spec §2 / A5 mandate applied to this item's own evidence.

R5.4 is cited correctly and for the right clause. The operative words at `:322` are
`MUST NOT` ("the tool **MUST NOT** auto-expose every flag as an env var"); the
curated-subset clause beside it is a `SHOULD`, and the decision rests F269's exclusion
on the `MUST NOT`, not on the `SHOULD`. It also states the reason precisely enough to
survive reuse: clap **can** express blanket binding via `Command::mut_args`, so the
design is excluded because the standard forbids it, not because the crate cannot do
it. Both Doxa proposals that it overrides (OpenAI's command-graph post-pass at
`doxa-openai.normalized.md:130`, Perplexity's prefix helper at
`doxa-perplexity.normalized.md:63`) are represented faithfully.

One precision note, not a finding. R1.6's body carries a `SHOULD` — "Aliases ...
**SHOULD** be listed in help" (`:148`) — which collides with R1.3's `MUST NOT` for a
plural alias. The `MUST NOT` governs and the decision's "no `SHOULD` is waived" claim
survives, because a `SHOULD` displaced by a more specific `MUST NOT` is inapplicable
rather than waived. The decision labels R1.6 a "`MAY`/`MUST NOT` pair", which is the
standard's own heading label, so the citation is faithful; one sentence under AC10
saying which clause governs would close the reading.

## Design and evidence

**Architecture C is genuinely compared and genuinely excluded on fit.** The ripgrep
case is put at its strongest rather than at its weakest: the maintainer's own words
are quoted from PR #2626, the bill he paid is enumerated ("I had to write my own shell
completion generator ... my own `-h/--help` output generator ... my own man page
generator"), and `Cargo.toml:63` is verified to still read `lexopt = "0.3.0"` with no
clap. The refutation is on the one axis that decided ripgrep's case — this template
*is* a subcommand tool, R1.1 makes that a `MUST`, R9.1 asks for a `completion`
command, and a template must make adding a noun cheap — not on popularity. That is
the mandate applied correctly to the strongest counterexample in the field.

**Architecture D is not compared to the same standard, and that is findings F5 and
F6's shared root.** D passes every gate, is the closest competitor on the only cost
figures in evidence (253 KiB against clap_derive's 596 KiB), and is disposed of in one
table cell — "combinator style; its completion support was not verified here" — plus a
runner-up sentence. Softening Opus's flat assertion that bpaf has "no first-party
completion story" into an unverified claim carried as U7 is the right call and I credit
it. But the fit argument that would do for D what the ripgrep paragraph does for C is
never made, and the promotion condition that stands in for it is unmeasurable (F5).

The empirical basis for the mechanical claims is sound where it is checked, and I
re-derived the load-bearing ones myself against the committed snapshots rather than
taking the rows on trust:

- `parser.rs:1322-1331` is exactly the `ArgAction::Version` arm and it ends
  `Err(self.version_err(use_long))`. The short-circuit claim is correct, and it is the
  claim that makes option (b) cost more than an AC2/AC3 rewrite.
- `render_version()` at `:1097` is `_render_version(false)`; the `false` branch reads
  `self.version` first and ends `format!("{display_name} {ver}\n")` at `:4913`;
  `disable_version_flag` documents itself as disabling both spellings at `:1448`, its
  doctest asserts `ErrorKind::UnknownArgument` at `:1455-1463`, and the trap the
  decision warns about — clap's own re-declaration recipe asserting
  `ErrorKind::DisplayVersion` — is at `:1490`, the exact line cited.
- **`ErrorKind::DisplayVersion` is correctly described as unreachable.**
  `version_err` is called from exactly one site in the committed `parser.rs` snapshot,
  the `ArgAction::Version` arm at `:1330`. With `disable_version_flag(true)` and a
  plain boolean flag, no argument carries that action, so clap never constructs the
  error. `disable_version_flag` sets a `global_setting`, so the removal reaches
  subcommands too. The routing rule the decision states — `DisplayHelp` to stdout at
  `0`, every other kind to `RSLB201`/`2` — follows from clap's own `stream()`/
  `exit_code()` pair, and the note that `DisplayHelpOnMissingArgumentOrSubcommand`
  falls in the `_` arm is a real trap correctly surfaced. The decision claims only
  agreement of values, not composition, and says the envelope and the `ExitCode`
  return are P03's to build. That is the right claim.
- **R4.6's span is exactly as the decision corrected it**: `:275` heading, `:276`
  rule, `:277` the ✅/❌ example, `:278` blank, `:279` R4.7's heading. Every clause
  option (b) rests on — the single-line `SHOULD`, the `-o json` permission, the object
  shape, the no-leading-`v` `MUST`, the omit-or-`null` allowance — is on `:276`.
- **R66's three compatibility properties are satisfied by R66's accepted decision.**
  `research/runs/R66/2026-09-05T183458Z-9ff7d91f9b8f/review/DECISION.md` selects
  `-o <table|json|markdown|name>`, answers R60's three requirements by name at
  `:147-158`, and declares the flag with `global = true` at `:154`. So property 1
  (a flag accepting `json`), property 2 (declarable at the root) and property 3 (the
  spelling R60 deliberately did not decide) all hold, and AC3 becomes R4.6's own
  worked example verbatim. **No finding and no `CONFLICT:`.** R66's own re-verify line
  records that the single R60-reopening outcome did not occur. R60 could not have known
  this — R66's decision is dated the day after revision 7 — so the `re-verify` entry is
  correctly forward-looking; P03 should record it as discharged rather than pending.

The three claims the decision declines to make are the right three. It does not
implement its own recommendation, and must not be faulted for that: P03 builds the
template. AC1–AC10 are labelled proposals, E11 and E12 are explicitly said to read
source rather than run clap, and the closing "What these runs do not establish"
paragraph is accurate against what I could check.

## Completeness

**Required fields.** All four H2s required by `research/RUNBOOK.md:181-188` are present
in order — `## Decision` (with `### Principles and implementation` and a `re-verify:`
line), `## Parameters`, `## Empirical check`, `## Engines` — and `## Supersedes` is
correctly absent, this being a revision rather than a reversal. The runbook's demand
that version-pin recommendations execute is met: `cargo generate-lockfile` and
`cargo audit` both at exit `0` on the recommended pins at the 1.96 floor.

**Parameters.** The four `assumes` lines are byte-identical to `docs/port/PARAMETERS.md`;
I diffed each against the registry row. The prompt's `- owns:` and `- consumes:` lines
are both empty, so no `owns` line is correct, and the decision's refusal to promote
the Doxa bodies' invented `owns` names (`blanket-global-env-binding` and the rest,
`doxa-openai.normalized.md:740`) into registry rows is right. No `CONFLICT:` line is
owed: R66 owns no registry parameter, which I confirmed against its prompt and against
`PARAMETERS.md`, so there is no consumed value a conflict line could name.

**Gates and dates.** All six gates are answered per candidate and none by a bare exit
status. Gate 1's `inapplicable` under the owner's 2026-09-12 Q7.B ruling is correct and
correctly reasoned — no exclusion ever rested on it, and `argh`'s `BSD-3-Clause` is
recorded as a registry fact rather than a verdict. Gate 3's 404-means-no-advisory
reading is validated against two positive controls, which is the right way to read an
absence. Gates 3 (`unsafe`), 4 (OS matrix) and 6 (cost at this version and feature set)
are honestly carried to U3, U1 and U2 rather than claimed. Retrieval dates are on every
figure. Gate 2 is where the asymmetry is — finding F7.

**`BASELINE-REVIEW:` handling is correct on its merits.** F266 and F271 are at
`BASELINE-REVIEW.md:114` and `:115` and both read `retained`; I confirmed the line
numbers. Declining to carry Codex's `BASELINE-REVIEW: F269` line is right: F269 is a
`DIVERGENT`, py-only row owned by R60 (`COMMONALITY.md:273`), not an inherited
baseline, so deciding it is this item's job rather than a challenge to a baseline, and
the line's substance survives in the decision and in AC5. One under-report, recorded as
a note rather than a finding because the disposition does not change: the Doxa OpenAI
body emits a **second** `BASELINE-REVIEW: F269` line
(`doxa-openai.normalized.md:320`), and `## Engines` Disagreement 4 names only Codex's.
The Doxa line argues the opposite substance — generated `PLBP_*` for every global —
which R5.4 excludes and Disagreement 2 already rejects, so no finding follows; the
census is nonetheless one short of what the raws contain.

**U1–U8 are correctly labelled.** U1 (Linux), U2 (cost at 4.6.6 with this feature set),
U3 (`unsafe`), U4 (clap usage text inside R67's envelope), U5 (AC1–AC10), U6 (issue
responsiveness beyond `clap-rs/clap`), U7 (bpaf's completion story) are all genuinely
unproven and each names what would prove it. U7's characterization of the engines is
accurate: Opus lists a first-party bpaf completion crate as a *re-verify trigger*
(`opus.md:493`), i.e. treats it as absent today, and Codex says an `autocomplete`
feature exists. U8 is correctly `RESOLVED` rather than deleted — I verified the owner
record exists at `docs/port/OWNER-REVIEW.md:72-91` with the clauses the decision relies
on. Keeping it listed is the right discipline.

**The empirical check and the r7 rerun are consistent.** `review/audit-codex.md` binds
the same decision hash I bound, reports preservation `183/0`, standard-pin `128/0` and
provenance `17/0/0/2` in place with empty diffs, and `183/0` + `128/0` + the documented
`14/0/0/5` from a clean `git archive`; the decision's Revision-7 table states the same
numbers. The r7 receipt, the exit file and the log agree. The structural repair itself
is sound: `r60-preservation-diff-r7.sh` reads five archived reports by name and the
live `review/audit-codex.md` nowhere, with `C1x`/`C1x0` as the control pair, which
closes F3's class rather than its instance — and the decision states what the script
deliberately does not assert (the round-6 report) rather than leaving it to be found.
That is the correct disposition of an assertion that could not have been written.

Two further notes, neither a finding. The R67 routing quote (`stream()`/`exit_code()`
at `error/mod.rs:222-237`, `USAGE_CODE`/`SUCCESS_CODE` at `util/mod.rs:26,32`) is
evidenced only in the revision-1 log at `r60-cli-parsing-verification.log:558-582`,
not in a hash-verified snapshot — the one integration-critical read that was never
moved onto the snapshot apparatus revisions 3–7 built for everything else. The log is
committed, so the claim is re-derivable and I do not fault it; a future revision that
touches the snapshots should carry `error/mod.rs` across. And the decision's
qualification that `casey/just` proves the *feature combination* ships in production
but not at 4.6.6/4.6.9 is exactly the right limit to state.

## Findings

**F4 — row E5's "every other standard line this decision cites" verifies twelve of
them, and two of the unverified citations name the wrong line.** `C8` of
`r60-standard-pin-r5.sh` carries exactly twelve `<line>|<expected>` specs — `50`,
`124`, `129`, `146`, `229`, `270`, `275`, `276`, `277`, `321`, `579`, `586` — and no
check in any of the three scripts reads `:220` (R3.8), `:237` (R4.1), `:483`/`:484`
(R9.1), `:491-493` (R9.3) or R4.5's rule body. Row E5's own title claims the set is
complete. Two of the unasserted citations are wrong against the decision's own
committed pinned text, which I read directly:

1. P7 quotes R9.1's "at least bash, zsh, and fish" at `` `:483` ``. `:483` is the
   heading `**R9.1 — Completion, man pages & help topics. (SHOULD / MAY)**`; the
   quoted phrase is at `:484`. P7 and AC4 rest on it.
2. "R4.5 (`:270`) and R4.6 (`:276-277`) both write it `-o`/`--output`" cites `:270`,
   which is the heading `**R4.5 — Global vs command-local flags. (SHOULD)**`.
   `--output`/`-o` appears at `:271`. `C8`'s spec for `:270` asserts that heading
   string, so the check passes while the proposition the line is cited for is never
   read — the check is vacuous for the claim it is offered as evidence of.
3. R9.3's verbatim quote ("command names, flag names, exit codes, env-var names, and
   machine-readable output shape") is at `:492`; the cited range `:491-493` ends on a
   blank line, the same two-line overrun class the decision self-reported for R4.6.

This is the identical heading-versus-body defect revision 4 found in R4.6 (`:275`
heading, `:276` rule) and closed with eight new `C8b` checks. The repair was applied to
one rule and not to the citation set as a class — the same instance-not-class pattern
findings F2 and F3 rejected in the preservation script, now in the standard-pin script.
**Repair:** extend `C8` to every `:<line>` the decision cites, with the expected text
the decision actually relies on rather than the heading; correct `:483`→`:484` and
`:270`→`:271`; tighten `:491-493`→`:491-492`; and restate row E5's scope to what it
asserts. No conclusion moves: R4.5 and R9.1 say what the decision says they say, one
line lower.

**F5 — the `bpaf` promotion condition is unmeasurable and is not on the `re-verify:`
line.** The decision's only recorded route from architecture A to architecture D is
"If a future re-verification finds the release cadence broken *and* the backlog
growing" (`:1864-1866`), stated in `## Engines` prose. Neither half has a threshold;
the prompt's own maintenance rubric supplies one the decision does not use ("no release
in 6 months is a trigger to investigate, never the verdict"); and the condition appears
nowhere on the `re-verify:` line at `:1071`, every other trigger of which is
mechanically checkable — the blob id via `C2a`, a clap 5.x release, a RustSec page
opening, R22 resolving, R66 leaving no root flag. The raw report supplied a measurable
trigger and the synthesis dropped it: Opus's ranked runner-up reads "Take it if a
future measurement shows clap's compile time is the template's binding constraint"
(`raw/opus.md:443-447`) — a condition tied directly to this decision's own U2. So the
reader who is supposed to fire the promotion cannot evaluate it, and the one
substantive comparison between A and D is left resting on it. **Repair:** state the
condition in terms a re-verifier can measure, or restore the compile-time trigger, and
put it on the `re-verify:` line beside the others.

**F6 — two of the four clap features are carried by adopter agreement, the raw
report's reason for them is dropped, and one reason is now obsolete.** `string` and
`wrap_help` appear in the stack table at `:275`, in three adopter manifest rows at
`:690-694`, and in the `casey/just` composition paragraph at `:698-707`. No sentence in
the decision says what *this template* needs either feature for. `derive` is tied to
P1 and `env` to F269; the other two are supported only by "ships **exactly** this
decision's feature set". That is repository agreement selecting a design, which the
spec's governing rule forbids in terms that name this exact failure first:
"**Repository agreement**, existing implementation, popularity, and benchmark rank are
evidence to investigate; none establishes the correct choice by itself", and "Other
source choices ... require a fitness argument"
(`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md:28-29,41`,
owner amendment A5; restated in this item's prompt as "Agreement, familiarity, or
maximum benchmark throughput alone cannot select a design"). A fitness argument for
these two features is exactly what is absent. The raw report supplied exactly the missing reason —
"`string` because owned `String` values are needed for `long_version` built at runtime
and for any `mut_args` post-pass ... `wrap_help` because help text must wrap to the
terminal" (`raw/opus.md:432-438`, with `clap_builder-4.6.6/src/builder/str.rs:54-80`
cited) — and the synthesis did not carry it. Worse, that reason no longer holds as
written: `long_version` left the design in revision 4 and `mut_args` is excluded under
R5.4, so the stated basis for `string` is gone and nothing replaced it. Compounding
this, qualification 3 quotes the `rosetta-rs` table selectively — `clap_derive` 596
KiB / 4 s, `clap` builder 574 / 3 s, `bpaf_derive` 253 / 4 s, `argh` 38, `lexopt` 37,
`pico-args` 24 — and omits the `clap-minimal` (no default features) row at **377 KiB /
2 s / 155 ms incremental** (`raw/opus.md:209-215`), the one row in the sole benchmark
the decision cites that bears on how much of clap's cost is feature configuration,
which is the question two added features raise. **Repair:** state what the template
needs each feature for, re-derive `string`'s justification under option (b) or drop the
feature, and quote the benchmark row that was left out. The recommendation does not
move either way; both features are defensible once a reason is given.

**F7 — gate 2 is read as a bar for exclusions and as a declaration check for passes,
and the gap is not carried as unproven.** The prompt's gate 2 quotes `msrv-policy` in
full, "declared as rust-version in Cargo.toml **and tested in CI**", and the
controller's ruling of 2026-09-11 settled that the gate is "a bar the candidate must
clear" read on the full policy, "declaration and CI testing included"
(`docs/planning/p02/execution-ledger.md:414`). R60 excludes `shadow-rs`, `argh`,
`lexopt` and `pico-args` on the declaration half — correct, and consistent with R64 and
R69 — but grants **pass** to `clap`, `clap_complete`, `strsim`, `built` and `bpaf` on
that same half alone, while qualification 2 states "**No CI configuration was read in
this run**". That limit is carried only to gate 4, as U1; nothing records gate 2's CI
clause as unestablished for any passing candidate. R64 reads both halves for its
selected candidate and says so ("If only one half appears, the gate still fails",
`R64 DECISION.md:349`); R69 reads the declaration half and **states the limit in its own
text** (`R69 DECISION.md:1417`). R60 does neither. The recommendation does not move —
nothing here suggests clap fails the clause, only that it was not read — but a decision
that excludes four candidates on one half of a bar owes the reader either the other
half or the limit. **Repair:** one sentence in the gate-2 column, or a U-row naming the
CI clause and what would discharge it.

## Assessment

Reject, on four findings, none of which touches the recommendation. The decision's
substance is strong and this is the first round to say so on the record: the shared
principle is identified at the right agreement level and generalized past both source
ports rather than copied from either; architecture C is excluded on fit against the
strongest counterexample in the field, quoted at its strongest; R1.3's `MUST` is found,
applied against both ports' shipped practice, and mechanized down to which clap method
the derive attribute reaches; R5.4's exclusion of blanket env binding rests on the
`MUST NOT` rather than on a capability claim the source would not support; the R67
coupling is correctly worked, with `DisplayVersion`'s unreachability following from a
single call site I verified in the committed snapshot; and R66's accepted decision
satisfies all three compatibility properties, so the coupling is correctly recorded as
`related` with no `CONFLICT:`. Every clap line range and every standard line range the
decision relies on for its *conclusions* resolved exactly when I read them. The
P03-builds discipline is respected throughout — the acceptance criteria are proposals,
E11 and E12 are explicitly said to read source rather than run clap, and the unproven
list is honest.

What fails is narrower and it repeats a pattern this item has now been rejected for
three times. F4 is the heading-versus-body defect the decision itself discovered in
R4.6 and closed for that rule alone, leaving the same defect live in two other
citations and the check that would catch it unwritten — instance, not class, again.
F5 and F6 are the same omission seen twice: a reason or a trigger that the raw report
supplied, that the synthesis dropped, and that adopter agreement was left standing in
for. F7 is a bar applied in one direction. Each is repairable inside the decision's own
apparatus without reopening the recommendation, the owner's ruling, the standard pin or
any parameter, and a revision 8 whose scope is these four findings should be a short
one.

One item for P03 rather than for the revision: R66 published on 2026-09-16 with
`-o`/`--output` global, which discharges the single `re-verify` trigger that would have
sent F267 to option (c). That entry can be marked fired-and-clear rather than pending.
