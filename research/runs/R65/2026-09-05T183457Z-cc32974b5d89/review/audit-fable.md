decision-sha256: 4b9b21a1454461ce691976580f07d8df73e89323d2a17c1df79dc7526ac70956
actor: audit-fable-2026-09-05T183457Z-cc32974b5d89-r4
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This is the round-4 judgment audit of revision 4. Revision 3 (sha256
`31164f3d13e4df56826548bd74de5fa448ae6e111a5273e807c3d8a5774bbd22`) was rejected by the
round-3 judgment audit on findings J1, J2 and J3; that audit is archived unchanged at
`review/audit-fable.r3.md`. This audit re-reads the whole decision, not only the repairs.

## Principle and agreement level

Unchanged from revision 3 and re-confirmed. The shared principle — *the user, not the
program, decides whether ANSI colour appears, and the program resolves that decision once,
from an ordered set of increasingly specific inputs, before any styled byte is written* —
is stated at capability and observable-behaviour level, with the flag's spelling, the force
variable's spelling, the force tie-break and the seam's shape explicitly on the may-vary
side. Sources are named, dated and read from committed snapshots whose sha256 sits beside
the assertion that read them. The two deliberate departures from the standards (config
`always`/`never` above `NO_COLOR`; `FORCE_COLOR="0"` falling through) are argued with
evidence and cost rather than assumed.

The CLI Design Standard (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
v1.4.14) binds and places colour outside its own scope (Non-goals, line 32), so there is no
precedence rule, variable set or `--color` rule in the binding standard for this chain to
conflict with — settled in round 3 and not reopened here. Revision 4 changes nothing in
this section.

## Design and evidence

**The four things the press asks me to re-confirm all hold.** Architecture (B) —
`anstream` as a per-stream adapter, `anstyle` as the only colour type in the library
crate's public API, plus a template-owned `resolve_color` for tiers 1–4 — is still chosen
on criterion 8 and on keeping a renderer type out of the public surface, not on adoption;
(A) and (C) are compared on their own terms with named costs and read source. The stack
table, the resolved chain's shape and the answers to F287–F290 are byte-identical to
revision 3. The four `- assumes` lines match the `value` column of
`docs/port/PARAMETERS.md` rows 7–9 (and the `license` row) and
`review/evidence/params-diff.txt` is zero bytes. The round-4 empirical audit
(`review/audit-codex.md`, actor `audit-codex-…-r4`, model `gpt-5.6-terra`, family openai)
is bound to this same decision hash, approves, and reproduces 207 primary and 35
supplementary assertions in an isolated copy with only the two expected pathname
differences. Consistent.

**J1 — the tier-7 repair is correct, and I verified it independently.** Outside this run's
scripts I re-fetched `crates/anstream/src/auto.rs` at tag `anstream-v1.0.0` and
`crates/anstyle-query/src/lib.rs` at tag `anstyle-query-v1.1.5` and checked every offset the
decision now cites in its own voice. `auto.rs`: `:62` `pub fn new(raw: S, choice: ColorChoice)`,
`:65` the `ColorChoice::Auto => Self::auto(raw)` dispatch, `:78` `let choice = Self::choice(&raw);`,
`:95` and `:113` the two other handle reads, `:186` `#[cfg(feature = "auto")]`, `:187`
`pub fn current_choice(&self) -> ColorChoice`, `:199` `let choice = ColorChoice::global();`,
`:203` `let clicolor_enabled = clicolor.unwrap_or(false);`, and `:211-214` the disjunction
exactly as printed verbatim in the decision. `lib.rs`: `:55` `pub fn term_supports_color()`,
`:61` `None => return false` (so `TERM` unset is also `false`), `:63` `if k == "dumb"`,
`:123` the doc sentence quoted as ground (a), `:128` `pub fn is_ci()` and `:134`
`std::env::var_os("CI").is_some()`. Every line carries the text the decision says it
carries.

The repair itself is the right one. Criterion 9 is re-scoped to `TERM=dumb` on a TTY **with
`CI` and `CLICOLOR` both unset**, Disagreement 2's tie-break is restated as what the source
shows (`term_supports_color()` *participates in* tier 7; the difference from Codex's shape
is narrower than revision 3 claimed), and `## Engines` item 1 says the thing that matters
most: with `CI` set the criterion is **"false, not merely unproven"**. Item 2 adds that the
pty child must have `CI` and `CLICOLOR` *removed*, not set to `0`, because `is_ci()` tests
presence and `CLICOLOR=0` would pass the assertion for the wrong reason at tier 6. That is
an honest account of the developer-in-a-CI-flagged-container case the press names: on a
real TTY with `TERM=dumb` and `CI` set, this stack emits colour, and the decision says so
rather than burying it.

**Declining a template-owned `TERM` tier is the right call.** Ground (a) is the substantive
one and it is sourced: `is_ci()` exists so that CI jobs — commonly piped, often with `TERM`
unset or `dumb` — still get coloured logs, and since `term_supports_color()` returns `false`
for `TERM` unset as well as for `dumb`, a template `TERM` tier would suppress exactly the
case the operand was added for. Ground (b)'s first clause is a real contradiction: the
template owns only tiers 1–4, so any `TERM` tier it adds necessarily sits above tier 5 and
would let `TERM=dumb` beat `CLICOLOR_FORCE`, contradicting this decision's own answer to
F288 — and none of the three orderings read here (`anstream`, `supports-color`, `termcolor`)
puts `TERM` above a force tier. Ground (c) is the standards ground, quoted from the
committed `no-color.org` snapshot, which argues against `TERM` as the lever at all. Nothing
in the binding standard or in the decision's own principle is left unsatisfied: `TERM=dumb`
is a weak, ambiguous signal that the quoted standard explicitly declines to treat as a
colour policy, and the strong user signals (`--color`, config, `NO_COLOR`) all remain above
everything `anstream` does. The closing sentence — that an unconditional `TERM` suppression
would be a new tier and a new decision against this recorded research — leaves the
alternative on the record for P03 rather than hiding it. I record one imprecision in ground
(b) under `## Assessment`; it does not change the decline.

**J2 — criteria 11 and 12 exercise the order, not single inputs.** Criterion 11 sets config
`color = "always"` *against* `NO_COLOR=1` with both streams piped and requires SGR on both:
the two inputs conflict, and py's implemented order — the order this decision deliberately
inverts — would produce no colour and fail it. Criterion 12 sets config `color = "never"`
*against* both `FORCE_COLOR=1` and `CLICOLOR_FORCE=1` on two TTYs and requires no `ESC [`
byte, then puts `--color=always` against the same config value and requires SGR. So the
three adjacent boundaries tier 1 : tier 2, tier 2 : tier 3 and tier 2 : tiers 4–5 each have
a criterion whose expected outcome discriminates this decision's order from the one it
rejected. Both are correctly marked unproven — no `resolve_color` exists to call — and both
are listed in `## Engines` item 1 among the unit-provable set with what would prove them
(a single call asserting the returned `ColorChoice` with an injected environment source and
an injected config value). That is the gap J2 named, closed in the form J2 asked for.

**J3 — R85's assumptions are disposed of correctly.** I read R85's published decision
myself at `research/topics/85-rich-terminal-row-niceties/DECISION.md`. Both quotations are
verbatim from `:243-248`, and the `FORCE_HYPERLINK` sentence is repeated at `:532-533` as
R85's P03 validation item 4, exactly as the decision says. Assumption 1 is disposed of more
strictly than R85 itself required: R85 would have accepted "an `anstream`-style color
choice", and `resolve_color` does return one — but the decision correctly points out that
`ColorChoice::Auto` is a *request*, not an answer, and locates the answer on the constructed
stream at `AutoStream::current_choice()` (`auto.rs:187`, gated `#[cfg(feature = "auto")]` at
`:186`, which the recommended default features keep on; `Never` for a stripping stream,
`AlwaysAnsi`/`Always` otherwise — I verified `:189-192`). It then records as unproven that
the template actually exposes that value to a renderer, with the P03 assertion that would
prove it. Assumption 2 is ruled **out** of the chain with the ground stated — `FORCE_HYPERLINK`
gates OSC 8 emission, a different capability, on a crate not in this stack table and not
evaluated here — and the interaction R85 relies on is shown to survive without a tier,
because R85 composes `color_enabled && supports_hyperlinks::on(Stdout)`, so colour resolving
to `Never` suppresses hyperlinks regardless and `FORCE_HYPERLINK` can never turn colour on.
That reasoning checks out against R85's own composition at `:17-22`. "Out" is the answer the
round-3 audit named as defensible, and it is now given rather than left implicit.

## Completeness

Required structure per `research/RUNBOOK.md` §4 is present and unchanged: `## Decision`
settling F287–F290, `### Principles and implementation`, an event-form `re-verify:` line,
`## Parameters`, `## Empirical check` with toolchain, OS, command, working directory and
observed output, `## Engines` with both raws and four disagreements, and correctly no
`## Supersedes` — no revision has been published, and the superseded revision's sha256 is
given in the revision note instead.

Parameters: four `- assumes` lines, byte-identical to the registry, regenerated and diffed
by the primary script's §9 to a zero-byte diff. `- owns:` and `- consumes:` are both empty
in the prompt and the decision registers and consumes nothing, accurately.

`CONFLICT:` handling: no conflict line is warranted and none is raised. I confirmed that
neither raw emits one — both state so explicitly (`raw/opus.md:430,559,708,846,957`;
`raw/codex.md:238,287`). `BASELINE-REVIEW:` handling matches the runbook: the single F286
line is carried through in four-part form with affected items (F286, R60, R66) and evidence,
the ledger untouched; Codex's `BASELINE-REVIEW: F287` is not carried, with the stated reason
that F287 is a `DIVERGENT` row this item decides outright rather than an inherited baseline.

Fitness gates: all six present, none silently omitted. Gate 1 is `inapplicable` naming the
owner ruling of 2026-09-12 (Q7.B) — settled, and correct — with licence fields still
recorded as facts that exclude nobody, and `colored` 3.1.1 excluded on three architectural
grounds read at its own tag rather than on its `MPL-2.0` field. Gates 2–6 are as cleared in
round 3: a stated qualified MSRV pass, per-crate advisory and `unsafe` posture, the CI
matrix, default features with no async coupling, and a qualitative gate 6 marked
**unmeasured** with no throughput or binary-size number claimed anywhere.

Unproven claims are labelled as such throughout, with what would prove each, in the eight
items of **Where evidence is incomplete** — including the two items revision 4 added
(criterion 9's cleared-environment requirement, and R85's readable capability). The decision
implements nothing, which is correct for this programme and is not a fault.

New-citation coverage: the twelve `file:line` citations added in revision 4 are asserted by
a separate script, `review/evidence/check-color-enablement-chain-r4.sh` (35 assertions, exit
0), leaving the primary script and its committed log byte-identical to the artifacts the
round-3 empirical audit already reproduced. That is the right way to add evidence without
invalidating a passed check, and the round-4 empirical audit reproduced both.

## Findings

No unresolved findings.

## Assessment

All three round-3 findings are repaired in the form the round-3 audit specified, and the
repairs are narrower and more honest than the claims they replace: criterion 9 now states
the environment in which it holds and `## Engines` says plainly that outside that
environment it is false rather than merely unproven; criteria 11 and 12 make the decision's
most contested ordering falsifiable by P03; R85 is named as a consumer with both of its
assumptions quoted and answered. Everything the round-3 audit cleared — the architecture
comparison, the stack table, the chain shape, F287–F290, the parameters, the gates, the
`BASELINE-REVIEW`/`CONFLICT` handling and consistency with the empirical audit — I
re-checked and re-confirm, including an independent re-fetch of both cited crate sources at
their tags.

One imprecision is recorded here rather than as a finding, because it does not bear on the
recommendation and is worth having on the record for P03. In the paragraph declining a
template-owned `TERM` tier, ground (b)'s second clause reads: *"placed below tier 5 it would
not make criterion 9 unconditional anyway, since `CI` is read at tier 7."* As reasoning that
does not follow: any tier that returns `Never` on `TERM=dumb` and sits anywhere above tier 7
short-circuits before tier 7 runs, so `CI` would never be read. The correct reason that
placement is unavailable is architectural, and the decision establishes it elsewhere: tiers
5–7 live inside `anstream` and are reached only by returning `ColorChoice::Auto`, so the
template cannot interleave a tier between tier 5 and tier 6 at all — to put `TERM` below
`CLICOLOR_FORCE` it would have to absorb tier 5 into the resolver, which is the Codex shape
Disagreement 2 declined on separate grounds. Deleting the clause costs the decline nothing:
it stands independently on ground (a), on ground (b)'s first clause, and on ground (c), and
the alternative is explicitly left open for P03 as a new tier requiring a new decision. So
the decline is the right call, the surviving grounds are sound, and the `TERM=dumb`-on-a-TTY
-with-`CI`-set case is disclosed accurately rather than glossed.

Verdict: approve.
