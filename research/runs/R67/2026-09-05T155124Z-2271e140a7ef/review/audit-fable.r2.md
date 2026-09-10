decision-sha256: 530fe209e3f5d052e4cd754711936b22778a8831bf2c2f3795e1811fc0e0a4f3
actor: audit-fable-2026-09-05T155124Z-2271e140a7ef-r2
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: R8.2 is paraphrased as assigning exit 2 to input that is "missing or invalid" (`review/DECISION.md:559`), words the rule does not contain; the catalog row `RSLB203` (config value invalid → 2) rests on that added word and is presented as standard-derived rather than labelled a template choice; the backtrace rule "the trace never enters the JSON envelope" is called an assumption and "not published contract" at `review/DECISION.md:353-357` while the owned parameter publishes it at `:367` ("no backtrace and no cause array is serialized into the envelope")

## Principle and agreement level

The shared requirement is stated at the right altitude and, unusually, is
decomposed rather than asserted: five principles P1–P5, each with its own
agreement level, and an explicit column separating what must agree across py, ts
and rs from what may vary per ecosystem (`review/DECISION.md:68-74`). That
decomposition is the load-bearing move. P2 (the exit integers) is the only
principle raised to "standard, one value for all three repos", and the decision
does not raise it on its own judgement: it cites the owner's CLI Design Standard
R6.1, which I read at `/Users/stevemorin/c/cli-standards/cli-design-standard.md:351`.
The citation is exact. R6.1 is `(MUST)`, its table is verbatim
`0/1/2/3/4/5/130/143` with the meanings quoted, it carries "Unlisted failures
collapse to `1`", and it rejects `sysexits.h` (64–78) by name as "over-specified
and unavailable on Windows". The org decision row at `:70` is `org-locked` as
claimed. R7.6, R7.7, R7.8, R8.2 and R9.6 are likewise quoted accurately at
`:421`, `:426`, `:431`, `:460` and `:502`; R7.8's "MAY carry `details`,
`request_id`, or other documented fields" is genuinely the authority that lets
`hint` be a peer field. Nothing in the principle section is assigned from memory.

The three ecosystem-specific designs (broken pipe, signals, backtrace capture)
are each carried by a first-party source read at the MSRV floor tag `1.96.0`, not
by assertion, and each is argued as a justified difference that preserves the
same observable outcome — which is what the mandate asks for.

**On the task's framing of the signal crate.** My task message says the decision
rejects "the crate three of the five engines proposed for signal handling". The
raws do not support that count and the decision does not claim it. `signal-hook`
is chosen by codex (`raw/codex.md:43`), opus (`raw/opus.md:231`), OpenAI
(`raw/doxa-openai.normalized.md:523`) and Gemini
(`raw/doxa-gemini.normalized.md:263,296`); `ctrlc` is recommended by exactly one
provider body, Perplexity (`raw/doxa-perplexity.normalized.md:77`). The decision's
own accounting (`review/DECISION.md:527-539`) is the accurate one. What makes the
resolution evidence-led rather than majority-led is subtler and worth recording:
the decision reaches the same conclusion as the 4-of-5 majority *while correcting
the majority's reasoning*. Gemini excludes `ctrlc` because it "exclusively binds
to `SIGINT` and does not provide native `SIGTERM` capture"
(`raw/doxa-gemini.normalized.md:269`) — which is false; the `termination` feature
does capture `SIGTERM`. The decision instead reads the published tarball at the
pinned version and finds the real disqualifier: `set_handler<F> where F: FnMut()`
passes the callback no signal argument, and `termination` fans SIGINT, SIGTERM and
SIGHUP into one handler, so 130 and 143 cannot be told apart. That is a source
fact that survives whichever way the vote had gone, and it also refuses to wave
the crate off despite the Rust CLI Working Group book naming it — the decision
records the authority as real and the fit as wrong. Same pattern on F295: Gemini's
`strum` derive is rejected on the Cargo SemVer reference plus the exact ts defect
the item exists to fix, with `strum`'s 133.6M downloads and its use in Ruff and
Nushell named and set aside. Agreement level and evidence, not popularity, are
doing the work.

## Design and evidence

The five architectural alternatives A1–A5 are compared before any crate is named,
each rejected against a stated principle and a named downstream consumer rather
than on taste, and A3 is chosen for reasons (R70's exhaustive table, R03/R52–R56's
pattern match) that trace back to the parameter registry. The practice evidence is
real: seven manifests fetched at a stated endpoint and date, and the
`thiserror` + `anyhow` split shown in four of them.

Two precision notes that do not weaken a conclusion. First, "four of the seven do
exactly that, and the one that does not is the one with no library surface"
(`:313-315`) glosses three deviations, not one: ripgrep and fd are both
carrier-only binaries, and cargo-nextest ships `thiserror` + `color-eyre`, which is
the same two-layer shape with a different carrier — so the table supports the
conclusion slightly more strongly than the sentence describes. Second, essential
behavior 6's precedence shorthand "signal → broken pipe → domain error →
unexpected" (`:108`) is disambiguated only by the parameter's three-way EPIPE rule
at `:367` (result stream → 0; stderr envelope → retain the selected status; any
other stream → `RSLB101`/1). The parameter is unambiguous; the prose alone is not.

**The configuration-failure split — half justified, half over-claimed.** The
decision's own evidence log carries R8.2 verbatim
(`review/evidence/cli-design-standard-R6-R7.log:145`), and I re-read the rule at
source: "Use exit `2` when required non-auth input or consent is **missing**
because prompting is disabled/unavailable … and use exit `1` for runtime input
failures such as unreadable files." On that text:

| Row | Claim | Standing |
|---|---|---|
| `RSLB104` config layer unreadable → 1 | R8.2 verbatim | Justified. This is the half no engine proposed — OpenAI maps `ConfigRead` to 2 (`raw/doxa-openai.normalized.md:98`) — and the decision is right to depart from four engines on the rule's own words |
| `RSLB202` config document unparsable → 2 | R6.1's `2` = "Usage / parse error" | Justified. A document that fails to parse is a parse error on R6.1's face |
| `RSLB203` config value invalid → 2 | attributed to the same two rules | **Not established.** R6.1's `2` glosses as "bad flags, missing args"; R8.2's `2` is for input that is *missing*. A schema-valid-but-wrong value is neither, and R6.1's own default is that unlisted failures collapse to `1` |

The overreach is textual, not merely inferential: `:559` renders R8.2 as "exit `2`
when required non-auth input is missing **or invalid**", with the added words
outside the quotation marks, and `:261` draws "a value violating the schema is
exit **2**" from "R6.1 plus R8.2". A defensible route exists — treating a config
value as the persisted form of a flag puts it inside R6.1's usage family — but the
decision does not take that route, and it does not label the row a choice the way
Disagreement 5 honestly labels the `RSLB` prefix "not evidence-settleable". This is
finding 1. It is cheap to repair (one clause), and repairing it need not change the
integer.

**Empirical check.** Within the synthesizer's scope — verify, never implement — the
checks are the right ones and the revision-2 corrections land. I confirmed the
figures against `review/evidence/dependency-resolution.log`: "Locking 20 packages
to latest Rust 1.96 compatible versions" (`:200`, `:281`), 22 crate dependencies
scanned with no findings (`:272`), the `=1.0.102` control still reporting
RUSTSEC-2026-0190 (`:294`), no `etcetera` in the resolved tree (`:306`), and the
superseded one-package observation retained above a dated continuation header with
its narrower scope labelled (`:132-133`) rather than deleted. E4's paired-control
framing and E6/E7's "source-interface finding only" qualifiers are now stated where
the claims are made. `review/audit-codex.md` (r2, approve) reruns E13/E14 on a
Linux VM and reproduces exactly these numbers; its account and the decision's do
not diverge anywhere I could test.

## Completeness

Required sections, fields and gates are present and correct. Exactly the four
mandated H2 headings appear, in order, with `### Principles and implementation`
inside `## Decision` and `re-verify:` as that section's final line (`:363`). The
owned parameter is the one the registry assigns
(`docs/port/PARAMETERS.md:16`), and Gemini's five self-claimed parameters are
correctly read for content and disregarded for scope. The four fixed parameters
are quoted exactly against `docs/port/PARAMETERS.md:7-10`; `consumes:` is empty in
the prompt, and no consumed parameter is invented. All six fitness gates are
answered per crate, before popularity, with gate 2 executed rather than deferred.
Every figure carries an endpoint and a retrieval date. The catalog is internally
consistent against R6.1: every non-zero code in the table has at least one row, the
"hundreds digit = exit code" mnemonic is scoped to the `1xx`–`5xx` blocks so the
`9xx` signal block and the `RSLB000` sentinel are stated exceptions rather than
violations, and `RSLB205` reproduces R8.2's exit-2 case exactly.

`BASELINE-REVIEW:` handling is correct in form: the F301 line is carried verbatim
in the `## Decision` section, no other item and no ledger row is touched, and the
prompt's instruction to "treat them as open assumptions to state, not scope"
(`inputs/prompt.md`, Context) is followed. The declination itself is right —
the prompt's `- owns:` line names one parameter, and the owner question at
`docs/port/BASELINE-REVIEW.md:194` is undispositioned, so claiming the capture rule
would decide an owner question from inside an item.

**But the boundary is not stated cleanly enough to act on, in one specific way.**
`:353-357` lists two rules as "assumptions, not published contract": (a) capture
only via `Backtrace::capture` under `RUST_BACKTRACE`/`RUST_LIB_BACKTRACE`, and (b)
"the trace never enters the JSON envelope". Rule (b) is then published in the owned
parameter at `:367` as "no backtrace and no cause array is serialized into the
envelope" — the artifact seven items consume. The decision anticipates the tension
("which makes machine-mode suppression automatic rather than a separate rule") and
that reasoning is sound as far as it goes: the envelope's field set is R67's own
under F294/F295/F296, so closing the schema settles F301's question (b) as a
consequence. What is missing is the plain statement that follows from it — that of
the two questions the F301 amendment puts to the owner, **(b) is already answered
by the envelope schema and only (a), the capture mechanism, is genuinely open**. As
written, the owner reads "not published contract" in one paragraph and the rule in
the parameter two paragraphs later. This is finding 2: a status-labelling fix, not
a change to the rule.

Two non-blocking completeness observations. The HIGH owner-clarification question
asks the item to distinguish accidental drift from justified ecosystem difference
and to supply the rationale for the follow-on py/ts changes. The P1–P5 table does
this by construction — P2's "one value for all three repos" means py's
`SUCCESS/CONFIG/AUTH/API/IO/INTERRUPT` (0–5) and its `SIGINT`→5 cannot both stand
and conform — but that consequence is never said out loud, and the only place a
py-side change surfaces is the aside about a "harmonize-or-drop question for py" at
`:596`. One sentence naming py's taxonomy as drift against an org-locked rule would
discharge the question explicitly. Separately, the `CONFLICT:` handling is right:
Perplexity's line is quoted in full, and the three reasons it fails the protocol's
precondition (`consumes:` empty; R57 registers no parameter, which
`research/CLAUDE.md` confirms; the prompt's own `related` note) are each checkable.

**The unproven list is honest and, as far as I can test, complete.** Eight items,
each with a named proof, and they cover every runtime claim the design makes:
AC1–AC8 on both matrix OSes, destructor and flush behaviour under real signals,
the parser's exit 2, `RSLB903`'s reachability, the web `SIGTERM` drain, the crash
record's permissions, append-only enforcement, and build cost. The two structural
admissions are stated rather than buried: "No runtime behavior was executed by this
synthesis on any platform", and the resolution checks ran on macOS only so the
Linux half of `target-os-matrix` is unexercised even for resolution. opus's measured
results — the 101-vs-0 `println!`/`writeln!` control, the `Drop` guard, `clap`
exiting 2 — are recorded as opus-measured and not independently re-executed, which
matches `raw/opus.md:196-261`; they are used as corroboration, never as this
decision's own evidence. This is a research decision that declines to implement its
recommendation, exactly as the 2026-09-10 ruling requires, and I fault it for none
of that.

**Perplexity.** Weighed for what it contains and not leaned on for what it lacks.
Its four missing top-level fields are recorded once, with the consequence stated
(no parameter value, no re-verify trigger), and its prose is then used on the merits
in six of the eight disagreements — including where it is followed. Its `ctrlc`
recommendation is defeated by a source read rather than by its incompleteness, its
`RSBP` prefix is set aside for having no stated rule behind it rather than for
coming from the short report, and its `CONFLICT:` line is quoted in full and
answered on substance. Its shape error (the misfiled `BASELINE-REVIEW:` lines it
shares with OpenAI) is recorded and not propagated.

## Findings

1. **The R8.2 paraphrase overstates the rule, and `RSLB203` rests on the added
   word.** `review/DECISION.md:559` writes that R8.2 assigns exit `2` "when
   required non-auth input is missing or invalid"; the rule at
   `/Users/stevemorin/c/cli-standards/cli-design-standard.md:461`, quoted verbatim
   in this run's own log at `review/evidence/cli-design-standard-R6-R7.log:145`,
   says "missing" and not "invalid". `:261` inherits the error, concluding that "a
   value violating the schema is exit **2**" from "R6.1 plus R8.2". The
   consequence is confined to one catalog row: `RSLB104` (unreadable → 1) is R8.2
   verbatim and `RSLB202` (unparsable → 2) is R6.1's "parse error", but `RSLB203`
   (config value invalid → 2) is covered by neither text, against an R6.1 that
   collapses unlisted failures to `1`. Repair: either ground `RSLB203` in R6.1's
   usage family explicitly — a config value is the persisted form of a flag — and
   label it a template choice as Disagreement 5 labels the prefix, or drop "or
   invalid" and re-derive the row. The integer need not change; the justification
   must.

2. **The backtrace rule is labelled an assumption and published as contract.**
   `:353-357` states that "the trace never enters the JSON envelope" is an
   assumption and "not published contract"; `:367` publishes it in the owned
   parameter as "no backtrace and no cause array is serialized into the envelope".
   A consumer reads the parameter, not the caveat. Repair, one clause: say in the
   BASELINE-REVIEW paragraph that the envelope's closed field set — which is R67's
   own under F294/F295/F296 — settles F301's question (b) as a consequence, so the
   amendment the owner must disposition is (a), the capture mechanism, alone.

## Assessment

Reject, on two repairable findings, neither of which touches the recommendation.

The stack, the two-layer architecture, the exit integers, the boundary precedence,
the broken-pipe rule, the `ctrlc` exclusion, the `anyhow` floor and the crash-sink
deferral all survive this audit intact. The reasoning is evidence-led in the strict
sense the mandate asks for: it departs from four of five engines on the config-read
code because the rule's words require it, it rejects a crate the ecosystem's own
working group names because the published source cannot express the contract, and
it reaches the majority's signal answer while replacing the majority's false reason
with a true one. The revision-2 figures reproduce from the reviewed fixture, the
superseded observation is labelled rather than erased, and the empirical auditor's
independent rerun agrees. What fails is narrower: one org-locked `MUST` is
paraphrased into saying more than it says, and one rule is simultaneously disclaimed
and published. Both are edits of a clause each.

**Would I stake the dependents on it?** After those two edits, yes — and I would
have staked them before, on everything except the two clauses named. The registry
records **seven** formal consumers, not ten: R03, R52, R53, R54, R55, R56 and R70
(`docs/port/PARAMETERS.md:16`, confirmed against the `consumes:` lines in those
seven prompts). Five more items are coupled without consuming — R57, R60, R61, R66
and R05/R69 — and the decision names each with the direction of the dependency,
which is the accounting a dependent needs.

The staking case rests on where the risk actually sits. The exit integers are
org-locked and quoted exactly, so the part R70 and R03 pattern-match against cannot
move under them. The catalog's *shape* — `#[non_exhaustive]` plus `ALL` plus a
pinned-row coverage test — is settled by the Cargo SemVer reference and is the one
place the design is defensibly stronger than either source repo. Append-only means
a code added later never invalidates a consumer's existing match. The residual risk
is concentrated in the config block, which is precisely where R52–R56 live: finding
1 leaves `RSLB203`'s *justification* unsound, and a consumer that builds a
config-error path on it inherits an argument that does not close. That is an
argument defect, not a wrong integer, and it is why the fix is cheap — but it is
also why the fix should land before R52–R56 consume the value rather than after.
Finding 2 has the same character for R66 and R70, which read the envelope's field
set as binding.

One structural caveat the owner should carry forward rather than treat as a defect
here: every runtime property in this contract is unexecuted. Eight items say so,
name their proofs, and hand them to P03 — which is the correct posture for a
research decision, and I would not have it otherwise. It does mean the dependents
are staking on a proposal whose runtime half is validated in the implementation
phase, exactly as the programme intends.
