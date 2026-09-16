# R69 web-framework-stack — judgment audit (round 1, 2026-09-14)

decision-sha256: 7a1257842cfe1b39befa54e6ea0c8cdd125ee1768e13e72a1463c64d49d7d2d8
actor: audit-fable-2026-09-12T204004Z-d02022bf6f42-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 the serve binary's SIGTERM exit code contradicts R67's published contract, which the decision cites as satisfied, and the drain-deadline failure exit carries no number; JF-2 the fit ground that ranks `actix-web` runner-up and excludes `ntex` — "the template's CLI, library and future adapters live in one tokio world" — is stated as present fact but is contradicted by the decision's own acceptance criterion 1 and is contingent on R05, which the decision records as open; JF-3 the new `<app>-serve` executable is fixed at "no CLI flags" without examining the CLI Design Standard's required global core, which owner ruling 2026-09-14 binds to this template's CLI surface

## Principle and agreement level

The shared requirement is stated at the right level and sourced, not asserted. The decision
names capability as the level at which py, ts and rs must agree — each able to expose the core
library over HTTP without a mirror data model — and names the mechanism as what must **not**
harmonize, citing `docs/port/COMMONALITY.md` rows F303/F330/F331/F338/F339 (all `DIVERGENT`,
origin `py-only`) and `docs/port/DIVERGENCE-ANALYSIS.md` line 217. I read line 217: its
`harmonize` cell reads "partly — scope level only: whether ts-launch-blueprint should also ship
the web tier is one org call … the framework pick itself is Rust-only". The decision's framing
matches that cell exactly, and its cross-repo adjudication answers the scope-level question it
reserves — ts's absent web tier is classified as a missing capability with a proposed Hono
follow-on, not as a justified ecosystem difference. Recommending no shared low-level value
(route naming, DI shape, server library, watcher) is correct under the mandate: no explicit
owner requirement and no same-tradeoff evidence in all three ecosystems supports one.

The F330 analysis is the strongest passage in the item. It extracts the requirement behind py's
lazy fallback (every caller of the app object sees a loaded configuration), explains why py
cannot enforce it at construction (the app object is callable without its lifespan), shows why
axum can (`Router<S>` is not a service until `with_state` supplies `S`), and concludes that the
Rust template ports the invariant and not the fallback. That is a preserved principle realized
by a justified native design, not a copied mechanism. `BASELINE-REVIEW: F330` and
`BASELINE-REVIEW: F331` are both in the runbook's four-segment form, name affected items
(R69/R77/R83 and R69/R71/R75/R78/R79) and carry source evidence; neither touches the ledger,
which is correct — the controller adjudicates. The withdrawal of the opus raw's
`BASELINE-REVIEW: F339` is recorded with its ground (its premise was that every candidate failed
a gate; owner ruling Q7.B struck the gate that produced that premise) rather than silently
dropped, and `docs/port/COMMONALITY.md` row F339 carries no pending baseline finding to
reconcile. No `CONFLICT:` line is raised, and the decision states why the one candidate coupling
— R01's — does not produce one.

## Design and evidence

**Architecture before libraries.** Five alternatives (A–E) are compared before any crate is
weighed, and the comparison turns on mechanism, not popularity: alternative C is rejected because
actix-web's own documentation says an unset `Data<T>` "would cause a 500 Internal Server Error"
(read at `actix-web-4.15.0/src/data.rs:39`), so a template meant to be copied would ship a
wiring-mistake class visible only under traffic. That is a principled discriminator with a source.
The decision states outright that "No comparative throughput figure is used anywhere", refuses
TechEmpower with a stated reason (hand-tuned benchmark entries; every candidate but `ntex`/
`xitca-web` shares the same `tokio` + `hyper` I/O path), and names the condition under which the
runner-up wins — a measured, instrumented workload showing a material p99, CPU or RSS advantage,
with openai's two-workload benchmark specified in the unproven table. Selection does not rest on
download counts or on repository agreement.

**The R01 coupling (press point 2) — the claim is correctly narrowed, and I do not fault it.**
Check 1 does not exercise the real `axum` crate: it transcribes R01's seam shape and axum's
state bound into three dependency-free packages and asserts against
`assert_axum_state_bound<S: Clone + Send + Sync + 'static>`. The actor is therefore a transcribed
bound, not `Router::with_state`. The decision says so itself — "It is a type-level fact about a
declared bound, paired with that bound read at the published artifact", and "What it does not
establish: anything about handlers, dispatch, request behavior, or the real axum crate's behavior
at runtime" — puts the request-path behavior (R01 acceptance criterion 6) in the unproven table
with a template integration test named as what would prove it, and separately records that the
transcribed bound was read at `axum-0.8.9/src/routing/mod.rs:138-141`. The two negative twins do
what is claimed for them: the by-value twin shows the outer `Arc` is load-bearing, the
supertrait-stripped twin shows R01's `Send + Sync` are. `review/audit-codex.md` reran all six
scripts and confirms the diagnostics. The claim as stated and the evidence match.

**The re-admitted watch tool (press point 3) — justified on function, and the displaced
alternative is genuinely compared.** Re-entry is not argued from the absence of the old ground
alone. Five capabilities were verified rather than assumed, and one of them corrects the opus raw:
bacon's default Unix job interruption is `SIGKILL`, so the template must ship a `bacon.toml`
overriding `run-long`'s `kill` or a dev restart never exercises the production drain. The
`-j run-long` check under `--headless` was run precisely because bacon's own `--help` suggested
the opposite. The displaced alternative is named ranked runner-up with its functional advantage
stated against bacon — `watchexec-cli` sends `TERM` with a bounded stop timeout and needs no kill
override — and with the flip condition stated ("the moment it declares a `rust-version`"). The
selection is nonetheless elimination-driven: bacon wins because gate 2 removes watchexec-cli and
maintenance removes cargo-watch, not because it is functionally better, and on the kill-signal
axis it is worse. The decision is transparent about that and carries the unsettled applicability
question — whether the MSRV gate reaches non-linked developer tools — in its `re-verify:` line.
Given the programme's gates-before-popularity rubric, that is the right handling.

**The drain-deadline timing rule (press point 4) — correctly recorded unproven.** The rule is
"the deadline's clock starts at the signal, not at server start". It is not claimed as proved by a
run. The enabling fact is read at source and asserted: `axum-0.8.9/src/serve/mod.rs` awaits
`close_tx.closed()` with **zero** occurrences of `timeout` or `deadline`. The behavior itself is
in the unproven table with two template tests named, and the `## Decision`'s confidence paragraph
rates the drain-deadline code shape **medium**, "reasoned and read but not executed". The one
consequence the decision did verify — that the openai shape needs `tokio::sync::oneshot` and that
none of `signal`, `net`, `rt-multi-thread`, `time` or `macros` enables tokio's `sync` feature — is
read from the published feature graph and corrects the opus manifest. This is the pattern the
programme asks for.

**Where the evidence does not support the sentence.** Two places, both in the comparison against
the ranked runner-up and both stated as present fact about a template that does not exist:
`## Decision` alternative E — "the template's CLI, library and future adapters live in one tokio
world" — and the exclusion row for `ntex` — "a second runtime story for a template whose CLI and
library already have one". The decision's own acceptance criterion 1 says that with no features
`cargo tree -e normal` lists no `tokio` at all, and check 2 measured exactly that; `tokio` is
optional and reachable only through `web`. The decision also records at `## Parameters` that R05
`sync-async-execution-model` is open and that under a synchronous port the handler wraps the call
in `tokio::task::spawn_blocking` — under that branch the CLI has no runtime. See JF-2.

## Completeness

Verified mechanically rather than by reading.

- **H2 sections**: exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in
  that order, outside fences, none added, no `## Supersedes`. `### Principles and implementation`
  is present inside `## Decision`, and `re-verify:` is that section's final line.
- **Owned and assumed parameters**: I parsed `docs/port/PARAMETERS.md` and diffed each
  `- assumes` value byte-for-byte against the registry. `msrv-policy`, `rust-edition`,
  `target-os-matrix`, `license` and `http-transport-injection-seam` are all **identical**. The one
  `- owns web-extra-surface` line carries no backticks, no link, no trailing whitespace and no
  commentary; the registry's current value for it is `—`, which this decision sets. Every
  consumer question the prompt's `- related` line lists — does the surface exist as a named Cargo
  feature, its name, what it gates — is answered inside that value.
- **Fitness gates**: all six answered per candidate. Gate 1 is recorded as
  `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate, with no candidate excluded
  on it, and `assert-figures.sh` asserts gate 1 nowhere and says so in its own header — correct
  under the settled ruling. Gate 2 is answered from `crates.io/api/v1/crates/<name>/versions`
  against the 1.96 floor for all 14 candidates; gates 3–6 are answered for the two selected
  compiled members, with gate 4's macOS gap for `axum` and `bacon` closed by executed builds and
  an executed install on this host and the limit of that closure stated. Gate 6 is answered as a
  measured dependency count (12 → 52) with the wall-clock and binary-size halves explicitly
  carried as engine-reported and unproven.
- **Source dates**: `## Sources` carries 2026-09-13 for this synthesis's own retrievals and
  labels the 2026-09-12 material carried over from the raws as such, including the py source at
  programme pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`. Snapshot retrieval time is recorded
  as `2026-09-13T07:57:55Z`, with the drift rule for comparing across it stated.
- **Evidence artifacts**: all six cited logs exist under `review/evidence/`, each with its script
  under `review/empirical/`. `review/audit-codex.md` reran all six from a foreign directory and
  matched five byte-for-byte, with the sixth differing only in a sandbox-forced advisory-database
  path.
- **Engines**: one line per raw for all five, each with its sha256 and shape-validation state,
  including the honest record that the merged `raw/doxa.normalized.md` digest fails bundle-shape
  validation while all three per-provider files pass and are what was used. Eight disagreements
  are each settled with named evidence rather than by vote, and the licence-ruling disposition
  table enumerates every licence-based sentence in every raw with its disposition. Ten unproven
  rows each name what would prove them.

Two items are not defects but are worth naming. First, the raws' own figures were not adopted
where they were not endpoint-collected: gemini's star, issue and download figures are explicitly
excluded from use with the actual values given alongside. Second, the decision records a boundary
judgement that the opus raw's build-and-serve probe exceeded the research-worker contract, and
then states which of its results are and are not relied on — that is the right disclosure.

## Findings

**JF-1 (blocking) — the serve binary's exit-code contract contradicts R67, which this decision
cites as satisfied.** `## Decision` states: "The entrypoint returns `ExitCode` from `main` rather
than calling `process::exit`, which is what R67's published `error-taxonomy-exit-codes` requires,
and the drain-deadline branch is a failure exit." The unproven table then fixes the acceptance
test P03 must write: "one that begins a slow request, sends SIGTERM, and asserts both the response
completing and **a zero exit** inside the window". R67 is published and owner-accepted, and it
speaks to this exact case. Its `## Decision` answers the SIGTERM question by correcting the
premise that the template has no long-running mode — "the target shape is CLI + library + **web
service** (spec §4 D7; `web-extra-surface` owned by R69), and a container runtime stops a web
process with `SIGTERM` before escalating to `SIGKILL`. R9.6 makes `SIGTERM`→143 a `MUST`
independently." — and its cross-item dependency list names this item directly: "R05
(`sync-async-execution-model`) and R69 (`web-extra-surface`) decide the web surface's signal
source, **which must return the same 130/143**". R67's catalog carries `RSLB902` SIGTERM → 143.
A clean drain that exits 0 is therefore not consistent with the contract this decision says it
satisfies. Note that the zero-exit wording is this synthesis's own: the opus raw asks only for
"the process exit within the configured window" and names no code. The same paragraph leaves the
other branch unnumbered — "a failure exit" — where R67 assigns every failure an integer and
collapses unlisted ones to `1`; R51's container image and the template's own process tests consume
that number. **To resolve:** state the serve binary's exit integers explicitly — a clean
SIGTERM-initiated drain, a clean SIGINT-initiated drain, and the `GracefulShutdownTimedOut` branch
— and either align them with R67's `143`/`130`/`1` or, if the research supports a departure for a
server surface, argue it and raise it as a `BASELINE-REVIEW:` or `CONFLICT:` line rather than
asserting consistency with R67 while diverging from it.

**JF-2 (blocking) — the discriminating fit ground against the ranked runner-up is stated more
absolutely than the evidence, and contradicts this decision's own criterion 1.** Alternative E
ranks `actix-web` runner-up on the ground that "the template's CLI, library and future adapters
live in one tokio world and actix-web inserts `actix-rt`/`actix-server` between them", and the
exclusion row for `ntex` repeats it as "a template whose CLI and library already have one"
runtime. Both are written as facts about the template's present shape. They are not: acceptance
criterion 1 in this same decision requires that with no features `cargo tree -e normal` list no
`tokio`, check 2 measured that, and the owned parameter states that the `web` feature "does not
gate the CLI binary, the core library, R01's port and adapter seam". Whether the CLI is ever in a
tokio world is R05's to decide, and `## Parameters` records R05 as open with the synchronous
branch handled by `tokio::task::spawn_blocking` inside the web handler. Under that branch the
premise is simply false, and actix-web's runtime layer would be confined to the `web` feature
exactly as tokio is. The comparison survives in weakened form — two runtime abstractions inside
the feature rather than one — and actix-web is independently rejected as the primary state
mechanism on the evidenced `Data<T>` ground, so this is not a changed recommendation. It is the
failure mode the synthesizer contract names: a supporting sentence stated more absolutely than
its evidence, in the highest-stakes comparison in the item. **To resolve:** enumerate every line
carrying the claim (I found two: `## Decision` alternative E, and the `ntex` row in *Excluded by
gate and by fit*) and restate each conditionally — the web surface and any future async adapters
share one runtime, and under an async R05 the CLI joins them — or drop the premise and rest the
ranking on the `Data<T>` and layering grounds that hold either way.

**JF-3 (blocking) — the new executable's CLI surface is fixed without checking the binding CLI
Design Standard.** The owned parameter fixes `[[bin]] name = "<app>-serve"` as
"environment-variable-driven with no CLI flags", and `## Decision` repeats "The binary takes no
CLI flags — every knob is an environment variable, as in py's `__main__.py`". Owner ruling
2026-09-14 binds the org CLI Design Standard to this template wherever the web feature adds CLI
surface; a second shipped executable is such a surface. The standard's R4.1 makes `-h`/`--help`
and `-V`/`--version` **Required global core** — "Print help for the current command and exit `0`"
and "Print version and exit `0`", both on stdout under R7.5 — and R9.14 asks mature tools for
conformance fixtures over help shape, streams and exit codes. The decision predates the ruling
(it is dated 2026-09-13), so this is not an authoring fault, but it is unresolved, and it is
carried inside the owned parameter value that 33 items consume rather than in prose that a later
item could correct. Copying py's "no CLI flags" docstring is precisely the inherited-mechanism
move the research mandate asks to be justified rather than ported. **To resolve:** decide and
record whether `<app>-serve` carries the required global core, and if the decision is that a
non-interactive server binary is out of the standard's scope, say so with the standard's own scope
sentence cited, rather than leaving "no CLI flags" to be read as covering `--help` and `--version`.

## Assessment

The recommendation follows from the principles and the evidence, and I would not disturb it. The
framework and runtime selection is reached by comparing architectures before crates, is decided on
mechanism rather than on adoption figures, refuses the benchmark composite it could have leaned
on, names its runner-up with the condition that flips it, and separates what this run verified
from what P03 must prove with a ten-row table that names the proving check for each. The R01
coupling — the one claim that could have forced a published decision to be reopened — is verified
in the narrow form the evidence supports and is labeled as narrow. The licence-ruling reversal is
handled by enumerating every affected sentence in every raw rather than by re-reading, and the
restored tool is verified on function including one capability check that overturned the opus raw.
Gate 1's `inapplicable` recording is correct under Q7.B. `unproven, with what would prove it` is
used throughout, correctly, and nothing is asserted as proven that the checks did not show —
with the single exception in JF-2.

The three findings are all repairs to statements, not to the recommendation. JF-1 is the one that
must not travel: this item defines the process contract for the template's second binary, R51 and
R11 consume it, and the decision currently asserts agreement with R67 while fixing an acceptance
criterion R67's published value contradicts. JF-2 and JF-3 are narrower, but both sit inside text
that 33 consumers inherit — JF-3 inside the owned parameter's literal value. None requires new
research: JF-1 and JF-3 are resolved by reading R67 and the standard, which are both already
published, and JF-2 by qualifying two sentences. On a revision that resolves them I would expect
to approve.
