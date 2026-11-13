decision-sha256: 31164f3d13e4df56826548bd74de5fa448ae6e111a5273e807c3d8a5774bbd22
actor: audit-fable-2026-09-05T183457Z-cc32974b5d89-r3
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: J1 — acceptance criterion 9 (`TERM=dumb` on a TTY ⇒ no colour) is asserted as verified behaviour of the recommended stack, but the decision's own verbatim `anstream` source shows tier 7 is a disjunction (`term_supports_color() || clicolor_enabled || is_ci()`), so `CI` set — the condition on both CI runners — or `CLICOLOR=1` yields colour under `TERM=dumb`; J2 — no observable acceptance criterion exercises the config tier, the one order interaction this decision adds against py's implemented order and against the Codex raw, so P03 is given no way to prove the part of the chain most in dispute; J3 — R85 (`rich-terminal-row-niceties`, resolved) records two non-registry assumptions on this item and hands back one unscoped input (`FORCE_HYPERLINK`); the decision names R63, R64, R04, R32, R53, R55, R60 and R66 as touched items and never names R85 or either assumption

## Principle and agreement level

The shared principle is stated at the right level and is not a restatement of either
source implementation: *the user, not the program, decides whether ANSI colour appears,
and the program resolves that decision once, from an ordered set of increasingly specific
inputs, before any styled byte is written.* Agreement is claimed at capability and
observable behaviour, explicitly not at variable names or libraries, and the
must-agree / may-vary table is real rather than decorative — it puts the flag's spelling,
the force variable's spelling, the tie-break between two force variables, and the seam's
shape (deps object / constructor argument / value passed to a stream adapter) on the
may-vary side, which is what lets the Rust design differ from py's and ts's without
breaking the principle.

The principle's sources are named and dated: `https://no-color.org/` and
`https://force-color.org/` (read from committed snapshots, not live), py's `R5.5` at pin
`b08bccfb` and ts's `D-018(2)`/`D-038`. The snapshot mechanism is the right answer to an
unversioned source: the three pages are read from bytes whose sha256 is printed beside the
assertion that read them, the live re-read is opt-in and adds no assertion, and the cost —
quotations current only to 2026-09-10T16:10:03Z — is stated and converted into a
re-verify trigger.

Two deliberate departures from the stated standards are argued rather than assumed: an
explicit config `always`/`never` above `NO_COLOR` (against py's implemented order, for
`no-color.org`'s own FAQ sentence and `cargo` 0.99.0's implementation), and
`FORCE_COLOR="0"` falling through (against `force-color.org`'s literal "regardless of its
value", for the ts port and `supports-color`'s mapping). Both are recorded as departures
with their evidence and their cost. That is the correct handling.

The CLI Design Standard (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
v1.4.14) was read rule by rule for this item and yields no conformance finding. Its
Non-goals section states in terms that colour is out of scope: *"**Color, theming,
terminal styling, and detailed accessibility presentation rules** are governed by a
separate standard and are deliberately omitted here. This document does not define color
usage, `NO_COLOR`/`FORCE_COLOR`, visual styling, or screen-reader/terminal rendering
details."* (line 32). There is therefore no precedence order, variable set or `--color`
flag rule in the binding standard for this chain to conflict with, and no rule ID to
waive. The two colour-adjacent statements that are in scope are consistent with this
decision: R7.x holds that a pipe suppresses the interactive niceties "and, per the
separate color standard, color" (line 390), which is this decision's criteria 7 and 8; and
R4.1's required global core and reserved short letters (`-h -V -v -q -o -f -y`) contain
neither `--color` nor `--no-color`, so the `BASELINE-REVIEW: F286` proposal to add a
tri-state `--color <when>` beside the inherited boolean reassigns no reserved name. The
separate colour standard the document defers to does not exist in that repository
(`docs/` contains only `skills/cli-standards.md`), so nothing further binds.

## Design and evidence

**Architectures before libraries.** (A) boolean gate plus conditional styling, (B) stream
adapter, (C) console object are compared on their own terms, each with a named cost, and
each is anchored in read source rather than in reputation: `owo-colors`' `Override(AtomicU8)`
at `src/overrides.rs:78`, `colored`'s `SHOULD_COLORIZE` `LazyLock` at `src/control.rs:86`,
`console`'s second detection stack. (B) is chosen on criterion 8 and on keeping a renderer
type out of the library crate's public API, not on adoption. The mandate's ordering
(architectures, then libraries) is honoured in substance.

**Selection is not popularity and not repository agreement.** The strongest evidence for
this is the handling of `colored` 3.1.1, the field's most-adopted candidate at 6,631
reverse dependencies: with fitness gate 1 struck by the owner's 2026-09-12 ruling, the
decision did not restore the exclusion by assertion. It read the crate at tag
`colored-rs/colored@v3.1.1` and gave three architectural grounds, each with a `file:line`
citation and each asserted by the check script's new section 11. It then says plainly what
is no longer claimed — that `colored` now fails **no** gate this decision evaluated, gate 2
passing at `rust-version = "1.80"` and gate 3 at a RustSec 404 — rather than hedging the
licence out of the record. That is the correct shape for a struck gate, and the r3
empirical audit reproduced it independently at the tag.

**The central finding is checked against the candidates' own source.** Seven candidates
were read at pinned tags, and the claim that none composes an application flag/config tier
with a `FORCE_COLOR` tier ordered below `NO_COLOR` is supported by discriminating facts,
not by a survey summary: `grep -c FORCE_COLOR` = 0 in `anstyle-query`; `supports-color`
3.0.2 evaluating force at line 91 above `NO_COLOR` at line 94; `console` 0.16.6 letting
`CLICOLOR_FORCE` beat `NO_COLOR` and treating `NO_COLOR=` as disabling; `termcolor` 1.4.1
having no force tier at all; zero `env::args` in every candidate read. The omission is then
shown to be deliberate by a dated on-the-record statement, with exactly two attribution
claims made and each separately sourced, and with the `clap`/`cargo` maintainer roles
explicitly *not* claimed. Crate ownership's mutability is carried into the volatile table.
This is the standard the programme asks for.

**Runner-up.** `termcolor` 1.4.1 is named as the runner-up adapter and compared on the
property that decides between them — it accepts an explicit `ColorChoice` and reads
`TERM`, but ships no force tier — read at its tag. Adequate.

**Independent re-verification of the citation ledger.** I re-fetched
`crates/anstream/src/auto.rs` at tag `anstream-v1.0.0` and
`crates/anstyle-query/src/lib.rs` at tag `anstyle-query-v1.1.5` outside this run's script
and checked the decision's load-bearing offsets myself: `pub fn new(raw: S, choice: ColorChoice)`
at `:62`; the `ColorChoice::Auto => Self::auto(raw)` dispatch at `:65`; `let choice = Self::choice(&raw);`
at `:78`; `if raw.is_terminal()` inside `always_ansi` at `:95`; `let use_wincon = raw.is_terminal()`
inside `if cfg!(windows)` at `:113`; `let choice = ColorChoice::global();` at `:199`;
`no_color()` at `:205`, `clicolor_force()` at `:207`, `raw.is_terminal()` at `:211`. Every
one carries the text the decision says it carries. The reproducibility statement, the
regenerated log, and the two byte-identical reruns recorded in the round-3 empirical audit
are consistent with what I read.

**Precedence as an order, not as a set of inputs.** For tiers 5–7 the order is genuinely
established rather than asserted: `fn choice()` is an `if` / `else if` chain, so its source
order *is* its precedence, and the decision prints it verbatim and asserts the line order.
For tiers 1–4 the order is this template's own design and no Rust code exists to run, which
the decision states without euphemism — criteria 1–10 are "proposed, not executed", the
`cargo tree` assertions and the pty test likewise, all listed under `## Engines` as P03's.
That is correct for this programme and I do not fault it. What I do fault is the one place
where a composite behaviour is claimed as verified from an isolated proof (finding J1) and
the one tier for which no observable criterion exists at all (finding J2).

**Conflicting combinations the design does handle**, traced against the verbatim source:
`NO_COLOR=1` with `--color=always` resolves at tier 1 to `Always`; `CLICOLOR_FORCE=1` with
`--color=never` resolves at tier 1 to `Never`, so the adapter never reaches its own force
tier; `NO_COLOR=1` with `CLICOLOR_FORCE=1` resolves at tier 3 to `Never` because the
template owns `NO_COLOR` and returns before `Auto` — and `anstream` would order them the
same way if it were reached. The `colorchoice` process global is never written, so
`ColorChoice::global()` is `Auto` and the chain continues, which the decision states and
the check asserts against `cargo`'s zero `write_global` calls.

## Completeness

Required structure per `research/RUNBOOK.md` §4: `## Decision` with the settled `F###` rows
(F287, F288, F289, F290), a `### Principles and implementation`, and a `re-verify:` line
(event-form, which the runbook permits); `## Parameters`; `## Empirical check` with
toolchain, OS, command, working directory and observed output; `## Engines` with both
reports, four disagreements and the evidence; and no `## Supersedes`, correctly, since no
revision has been published — the decision says so and gives the superseded revision's
sha256 in its revision note instead. All present.

Parameters are byte-identical to the registry. The four `- assumes` lines match the `value`
column of `docs/port/PARAMETERS.md` for `msrv-policy`, `rust-edition`, `target-os-matrix`
and `license`; section 9 regenerates them by `awk` from that file and diffs, and
`review/evidence/params-diff.txt` is zero bytes. The prompt's `- owns:` and `- consumes:`
lines are both empty and the decision registers nothing and consumes nothing, which is
accurate. No `CONFLICT:` line is warranted and none is raised; neither raw emits one
(both say so explicitly).

Fitness gates: all six are present and none is silently omitted. Gate 1 is recorded as
`inapplicable` naming the owner ruling of 2026-09-12 (Q7.B) — correct under that ruling —
while licence fields stay recorded as facts that exclude nobody. Gate 2 is a stated
qualified pass (per-crate `rust-version = "1.66.0"` verified; the resolved tree deferred to
P03's lockfile). Gate 3 carries the advisory results and a specific `unsafe` posture per
crate. Gate 4 names the CI matrix. Gate 5 names the default features and states the absence
of async-runtime coupling. Gate 6 is qualitative and marked unmeasured, with no throughput
or binary-size number claimed anywhere.

Source dates are present and honest about their class: the snapshot retrieval instant
(2026-09-10T16:10:03Z), the crates.io owners lookup (2026-09-12), the issue comment's own
timestamp (2024-06-04T02:23:48Z), and the adoption figures carried with the raws' dates
(Codex 2026-09-05, Opus 2026-09-10) rather than re-asserted. The three-class provenance
section and the six-row volatile table say for each input whether the log asserts it or
merely prints it.

`BASELINE-REVIEW:` handling matches the runbook: one line for F286 in the required
four-part form with affected items (F286, R60, R66) and evidence, carried through
unresolved, ledger untouched; and a stated reason for not carrying Codex's
`BASELINE-REVIEW: F287`, since F287 is a `DIVERGENT` row this item decides outright rather
than an inherited baseline. I confirmed against `docs/port/BASELINE-REVIEW.md:120` that
F286 is the inherited `retained` row and that its own note already points the chain at R65.
The F286 evidence line is also self-correcting in the right direction: it withdraws the
Opus raw's "every first-party Rust CLI exposes the tri-state form" and states what was
actually read — `ripgrep` 15.2.0 takes four values, and `clap` is a library whose enum is
evidence of an API model, not a third observed CLI shape.

Consistency with the round-3 empirical audit: it approved at this same decision hash, with
two consecutive reruns at 207 passing assertions, an empty repeat diff, and one non-assertion
difference attributable to the isolated copy's `PARAMETERS.md` pathname. Nothing in my read
contradicts it; its scope was reproduction, and findings J1–J3 are judgment matters a
reproduction pass would not surface.

Engine handling is honest in both directions. Four disagreements are settled with the losing
position preserved, including Codex's unit-testable resolver kept on the record as the
fallback if the pty harness proves unworkable on both runners. The Codex raw's total silence
on `colored` is called a coverage gap in that raw, not a disagreement, and is asserted by
count. The Opus raw's false method note (that `zkat/supports-color` has no tags) is refuted
rather than repeated, and every default-branch line offset it carried was re-derived at a
tag, with four specific corrections listed.

## Findings

**J1 — a composite behaviour is claimed as verified from an isolated proof; the decision's
own evidence refutes it.** Acceptance criterion 9 reads, unqualified: "`TERM=dumb` on a TTY
⇒ no colour." `## Engines`, Disagreement 2 then makes that criterion the ground for
settling the resolver's shape: "acceptance criterion 9 — no colour on a `TERM=dumb`
terminal — is behaviour the recommended stack already implements for free (`anstream` via
`anstyle_query::term_supports_color()`), and so does the runner-up adapter (`termcolor` via
its own `TERM` check); both were verified." What was verified is that
`term_supports_color()` appears in the tier-7 condition. The condition is a disjunction.
The decision prints it verbatim in its own evidence and states it correctly in its own
tier-7 row — "*this stream's own* `is_terminal()` and (`TERM` supports colour, or
`CLICOLOR` enabled, or `CI` set)" — and I re-read it independently at the tag:

```
} else if raw.is_terminal()
    && (anstyle_query::term_supports_color()
        || clicolor_enabled
        || anstyle_query::is_ci())
```

`anstyle_query::is_ci()` at `anstyle-query-v1.1.5` `src/lib.rs:128` is
`std::env::var_os("CI").is_some()`, and `term_supports_color()` at `:55` returns `false`
for `TERM=dumb`. So on a TTY with `TERM=dumb`, colour is emitted whenever `CI` is set or
`CLICOLOR=1` — and `CI` is set on both runners in `target-os-matrix`, which is exactly
where `## Engines` item 2 proposes to allocate a pty. The criterion as written would fail
in the harness built to test it. This is not the programme's permitted "unproven, with what
would prove it"; it is a behaviour asserted as already implemented and verified, contradicted
by the cited source, and it is load-bearing because it is the stated tie-break for
Disagreement 2. Resolution: qualify criterion 9 to the environment in which it holds
(`CLICOLOR` unset and `CI` unset), or give the template a `TERM` tier of its own above
tier 5 and say so; then restate Disagreement 2's claim as what the source shows —
`term_supports_color()` participates in tier 7, `CI` and `CLICOLOR` can override it — and
have P03 prove the criterion with `CI` explicitly cleared.

**J2 — the one order interaction this decision adds has no observable acceptance
criterion.** Tier 2, the config key, is the decision's most contested element: it settles
Disagreement 1 against the Codex raw, inverts py's implemented order, and places an
explicit config `always`/`never` above `NO_COLOR`. None of criteria 1–10 exercises it.
Criterion 3 mentions config only as absent ("no flag, no config value"); criteria 1, 2, 5
and 6 name the flag and the environment variables; `## Engines` item 1, which divides the
criteria into unit-provable and end-to-end, never mentions the config tier. So the criteria
prove tier 1 against the environment, tier 3 against tier 4, tiers 4–5 against TTY, and
tier 7 per stream, while the tier whose position is in dispute is proved by nothing. Given
the decision's own framing — precedence is an order, and criterion 8 is named as the one
that separates architectures — the absence is a gap in the required observable acceptance
criteria, not a stylistic one. Resolution: add at least one criterion of the form
`color = "always"` in the config file with `NO_COLOR=1` set and no flag ⇒ SGR sequences,
and its converse (`color = "never"` with `FORCE_COLOR=1` ⇒ none), and list them among the
unit-provable set in `## Engines` item 1.

**J3 — a resolved consumer and its two stated assumptions are not named.** R85
(`rich-terminal-row-niceties`, resolved, `research/runs/R85/2026-09-06T043455Z-beb2d764c756/review/DECISION.md`)
records under "Two non-registry assumptions this decision rests on": that R65 "must expose
something the CLI can read as 'this stream will accept escape codes'", and that R65
"additionally acquires an input it may not have scoped: `FORCE_HYPERLINK`, which
`supports-hyperlinks` honors independently of `NO_COLOR`/`FORCE_COLOR`
(`src/lib.rs:14,66`)" — the second repeated as R85's P03 validation item 4. This decision
names R63, R64, R04, R32, R53, R55, R60 and R66, and lists R63 and R60 as re-verify
triggers, but never names R85 or either assumption. The first assumption interacts directly
with what this decision settles: under Disagreement 2's chosen shape, `resolve_color`
returns `Auto` in the ordinary case, so the value a caller can read at that point is not a
yes/no. It is satisfiable — I confirmed `pub fn current_choice(&self) -> ColorChoice`
exists at `crates/anstream/src/auto.rs:187` at tag `anstream-v1.0.0`, under
`#[cfg(feature = "auto")]`, which the recommended default features keep on — so this is a
recording defect rather than a design defect, which is why it is ranked last. The statement
that this item "registers no parameter value and consumes none" is accurate and is not what
is at issue. Resolution: name R85 as a consumer, state that the per-stream effective choice
is readable through `AutoStream::current_choice()` rather than through `resolve_color`'s
return, and rule `FORCE_HYPERLINK` explicitly in or out of this chain (out, on the ground
that it gates hyperlink capability rather than colour, is a defensible answer — but it has
to be given, since a resolved item asked for it).

## Assessment

This is a strong decision and the recommendation is right. The principle is stated at the
level the mandate asks for; the architectures are compared before the libraries; the
library selection follows from source read at pinned tags rather than from adoption or from
py/ts agreement; the struck licence gate is handled by re-grounding the `colored` exclusion
on three architectural findings rather than by assertion or by silence; the parameters are
byte-identical to the registry; every fitness gate is answered; the citation ledger holds
under independent re-fetching; and what the check does not establish is stated plainly and
handed to P03 rather than dressed up. Does the recommendation follow from the evidence? Yes
— architecture (B) with `anstream`/`anstyle` and a template-owned resolver for tiers 1–4 is
what the read source supports, and none of my findings touches the stack table, the
resolved chain's shape, or the answers to F287–F290.

The verdict is nevertheless a rejection, on J1. The brief for this round is precedence as a
state interaction, and J1 is precisely that failure mode in miniature: an input proved in
isolation (`term_supports_color()` is in the condition) reported as a composite behaviour
proved (`TERM=dumb` on a TTY yields no colour, "verified"), when the decision's own verbatim
evidence shows two other operands in the same disjunction, one of which is set by default on
both runners this template targets. A reader building P03 from this text would write a test
that fails and would not know why. J2 is the same class one level up — an order asserted for
a tier that no criterion exercises. Both are text-level repairs against evidence already in
this run; neither requires new research, and J3 requires only naming what a resolved sibling
already wrote down. Revision 4 answering these three should be approvable without a new
empirical pass beyond re-running the existing script.
