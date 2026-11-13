# R75 http-middleware-stack — judgment audit (revision 1)

actor: fable
model: claude-opus-5-5
family: anthropic
decision: research/runs/R75/2026-09-26T190305Z-54dc44c45419/review/DECISION.md (revision 1)
decision-sha256: 7b936d861827d81e7f9bff2023b29511980864ec9c7d593b8034ba433ab7a4e5
verdict: reject
unresolved-findings:
1. JF-7 / JF-1 — the `web` feature literal: the decision says R69's registered value must change, declines to raise the `CONFLICT:` line, and contradicts published R72's reading of the same clause.
2. JF-8 — the A12 figure `duration_ms` 201.2 is not in `stack-acceptance.log`, which records 202.0 (host) and 202.2 (1.96.0).
3. JF-1 — the template-code size is stated two ways: "four functions" at line 53 and "the two functions" at lines 201-202.

## Scope and method

The recomputed sha256 of the target equals the expected value, so the audit proceeded. It was
recomputed with `shasum -a 256` before any other step.

Read in full: the decision, `inputs/prompt.md`, `research/RUNBOOK.md`,
`inputs/prerequisites.json`, `inputs/parameters.json` and `inputs/PARAMETERS.md`. Spot-read: the four
raw reports under `raw/` at every line range checked below, the published R69 decision (sha256
`d4507f5b…c10d`, equal to `inputs/prerequisites.json`), the published R72 decision at lines
255-300, and all seven `review/evidence/*.log` files. R58 has no decision
(`research/topics/58-logging-pipeline-architecture/` holds only `prompts/`).

Independent source reads, all read-only:

- **Upstream crates.** The synthesis probe at `$TMPDIR/r75-synth-probe` was copied to
  `/tmp/r75-jf-probe`. Its `Cargo.lock` sha256 is `5e89a57d…3cb`, equal to the decision.
  `cargo fetch --locked` then filled the private cargo home, which made the pinned sources of
  `axum` 0.8.9 and `tower-http` 0.7.1 readable.
- **py.** The local clone `~/c/py-launch-blueprint` sits at HEAD `b55b8c26`, the commit the opus
  leg pins.

Out of scope for this audit: rerunning any script (the empirical audit reruns them), and every
`review/audit-*.md` and snapshot file (none was opened).

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (findings 1 and 3) | See findings. Apart from those two, the slot table (L1-L10), the `apply_middleware` code, the per-row agreement table, the hand-offs and the Engines dispositions agree with each other. |
| JF-2 prompt questions and constraints | pass | See *JF-2 detail*. |
| JF-3 Engines fidelity | pass | See *JF-3 detail*. |
| JF-4 load-bearing claims trace | pass | See *JF-4 detail*. |
| JF-5 couplings hand over owned choices | pass, with finding 1 counted under JF-7 | See *JF-5 detail*. |
| JF-6 assumes lines byte-identical | pass | See *JF-6 detail*. |
| JF-7 no conflict with published prerequisite values | **fail** (finding 1) | See finding 1. |
| JF-8 evidence scripts exist; counts match | **fail** (finding 2) | See *JF-8 detail* and finding 2. |
| JF-9 decision shape | pass | See *JF-9 detail*. |
| JF-10 recommendation follows from evidence | pass | See *JF-10 detail*. |

### JF-2 detail

Each prompt question is answered, and the answer is located as follows:

| Prompt question | Where the decision answers it |
|---|---|
| HIGH 1: layered model, and ready-made or hand-written layers | lines 156-188 |
| HIGH 2: ordering and direction of composition | slot table at lines 70-81; direction at lines 158-167 |
| HIGH 3: cross-repo principles and agreement levels | lines 112-154 and 383-387 |
| MEDIUM: the access event | lines 182-188 and disagreement 2 |
| MEDIUM: probe exclusion | lines 140-144 and disagreement 3 |
| MEDIUM: framework log fold-in | lines 280-303 |
| LOW: named convention in published templates | gap 7, stated as an evidence gap |

Constraints:

- **Edition.** The probe's `Cargo.toml` declares `edition = "2024"` and `rust-version = "1.96"`.
- **MSRV.** E1 passed on the 1.96.0 floor.
- **ubuntu-latest.** Not executed. The decision discloses this at lines 372 and 551.
- **Gates 1-6.** Each is answered per crate member at lines 367-374.
- **Gate 1.** Recorded as inapplicable under owner ruling Q7.B, as R69 records it at R69
  `DECISION.md:2207-2213` (verified).

### JF-3 detail

Each leg's position was spot-checked against the raw text:

| Leg | Lines checked | Position the decision attributes to it |
|---|---|---|
| muse | `raw/muse.md:172-185` | `overriding`; `TraceLayer` as `route_layer`, "Sees every response … including 429s" |
| muse | `raw/muse.md:130-136` | 404s and preflights unlogged, called a "justified difference" |
| muse | `raw/muse.md:238`, `:245`, `:976-979` | no BASELINE-REVIEW; `tower` promoted to a normal dependency |
| muse | `raw/muse.md:909-911`, `:956-967` | hyper residual; `assumes … = pending` |
| opus | `raw/opus.md:3`, `:135` | model `claude-opus-5-5`; `setdefault` |
| opus | `raw/opus.md:224-229`, `:286-298` | span-field versus event-field argument; the C11 table |
| opus | `raw/opus.md:377-405`, `:536-539`, `:587-589` | three BASELINE-REVIEW lines; `if_not_present`; the E0277 pitfall |
| openai | `raw/doxa-openai.normalized.md:26`, `:55-57` | Actix `Logger` writes through `log`; two BASELINE-REVIEW lines |
| openai | `raw/doxa-openai.normalized.md:64`, `:95`, `:108`, `:131`, `:402` | `OnResponse` limit; force echo; `overriding` and boxing objection; central denylist |
| gemini | `raw/doxa-gemini.normalized.md:51-54`, `:69`, `:223-224` | probes outside the layer; `EnvFilter`; the invalid `owns` and `rust-version` lines |

Each of the nine disagreements is resolved by an executed case (N01-N06, A13, A14, E3) or by a
cited source line. None is resolved by counting legs. The invalid parameter lines are struck, and
the reasons are stated.

### JF-4 detail

Claims confirmed in the upstream crates:

- `tower-http-0.7.1/src/request_id.rs:454-461`: `PropagateRequestId` keeps an existing header.
- `axum-0.8.9/src/routing/mod.rs:303-316`: the `Router::layer` bounds, including
  `Into<Infallible>`, and the fact that the layer wraps both `path_router` and `fallback_router`.
- `axum-0.8.9/src/docs/middleware.md:63-65`: "bottom to top".
- `axum-0.8.9/src/serve/listener.rs:156` (`error!`) and `axum-0.8.9/src/serve/mod.rs:369` (`trace!`).
- `tower-http-0.7.1/src/set_header/response/mod.rs:174`, and `multiple_headers.rs:69`
  (`if_not_present`).
- `tower-http-0.7.1/src/timeout/service.rs:145-146` (`B::default()` with the configured status).
- `tower-http-0.7.1/src/catch_panic.rs:351` (500).
- tower-http `Cargo.toml`: `rust-version = "1.65"`; `src/lib.rs:200`: `#![deny(unsafe_code)]`.

Claims confirmed in R69's published decision:

- `DECISION.md:943-944`: the per-request timeout is R75's.
- `:1424`: `middleware.rs` is reserved for R75.
- `:1586`: the `web` literal and the dev-only status of `tower`.
- `:2197`: C11 is handed to R75.

**Facts the decision labelled "inherited, not re-verified".** The py clone at `b55b8c26` confirms
each one:

- `web/middleware.py:120` `response.headers.setdefault(name, value)`, so `if_not_present` is the
  faithful semantic.
- `:60` HSTS `max-age=63072000; includeSubDomains`.
- `:72` `uuid.uuid4().hex`.
- `:89` exclusion on the raw path.
- `web/app.py:137-146`: CORS is added, then `_install_rate_limiting`, then
  `SecurityHeadersMiddleware`, then `RequestIDMiddleware`. The rate limiter therefore wraps CORS,
  which confirms `BASELINE-REVIEW: F317`.

These confirmations close the py items of gap 3 (decision line 674). The C11 text of the owner
reference was not read by this audit either.

### JF-5 detail

The decision decides only the stack layers and the ordering slots. It hands each owned choice to
its owner, one line per item, at lines 389-411:

| Item | What the decision hands over |
|---|---|
| R73, R74, R76 | the behaviour of their layers, with only a slot and bounds imposed |
| R77 | the timeout variable and its default |
| R70 | whether to re-map 408 and 500 responses |
| R78 | whether its span replaces the `request` span |
| R58 | the subscriber, rendering, levels, panic hook and an optional `EnvFilter` |

The four assumptions about R58 are stated at lines 451-459, as RUNBOOK §1 requires for a
conditional answer. The BASELINE-REVIEW findings go to the controller, and no ledger row is moved.

### JF-6 detail

A Python comparison of all five `- assumes` lines against the value column of the live
`docs/port/PARAMETERS.md` returned `True` for each. That includes
`logging-pipeline-contract = —` (U+2014). R75 owns no parameter, and none is claimed.

### JF-8 detail

All seven cited logs have a matching `.sh` script. The counts match the logs:

- E1: 15 pass and 0 fail on both toolchains.
- E2: 12 pass and 0 fail.
- E3: 4 pass. The tallies are 7 TRACE events, 3 INFO events and 1 ERROR event. There is one
  panic-hook line.
- Shape check: 126 pass.

Every figures-table cell matches `figures.log`, spot-checked across all eight crates. The
responsiveness arithmetic also matches: tower-http has 2 of 10 issues answered, with a median of
0.1 days. Of its 8 unanswered issues, 6 were opened on or after 2026-08-28 (#741, #740, #737, #736,
#732, #731). The crates.io and axum example lines in `practice-check.log` match the decision's
citations.

The exception is finding 2.

### JF-9 detail

- The H2 set is exactly `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`.
- `## Supersedes` is correctly absent, because this is the first revision.
- `### Principles and implementation` sits under `## Decision`.
- The settled `F###` rows are listed at line 65.
- The `re-verify:` line is present at line 108.
- `## Empirical check` states the toolchain, OS, working directory, commands and observed output,
  as RUNBOOK §5 requires.

### JF-10 detail

Every choice that departs from a leg rests on an executed discriminator:

| Choice | Discriminating evidence |
|---|---|
| access log at L5 rather than a `route_layer` | N02 |
| overwrite echo | N03 and A14 |
| `CatchPanicLayer` | N04 |
| `if_not_present` | py `setdefault`, confirmed above; N05 and A13 |
| chained spelling | N06 shows runtime equivalence; R69's dev-only `tower` clause decides |
| no F327 step | E3 |

The residual uncertainty is stated in the Confidence section. It covers R58's formatter and the
stand-ins in slots L7, L8 and L10.

## Findings

### 1. JF-7 / JF-1: the `web` feature literal is treated as a registered-value change without a `CONFLICT:` line, and against published R72

**Failed claim.** Decision lines 466-471:

> "**One integration note requires an R69 revision or a controller ruling.** R69's published value
> writes the feature literally as `web = ["dep:axum", "dep:tokio"]` … and this stack needs
> `"dep:tower-http"` in that list. … It is still a literal change to a registered value, which a
> consumer may not make on its own (RUNBOOK §4)."

The decision also says at line 449, "**No `CONFLICT:` line is raised.**", and at line 417 it
recommends `dep:tower-http` in `web` "(needs R69, see `## Parameters`)".

**Evidence.**

- *The decision contradicts itself.* RUNBOOK §4 (`research/RUNBOOK.md:175-176`) prescribes one
  mechanism for a recommendation that "needs a registered value changed": the
  `CONFLICT: R## <param> — <needed value> — <reason>` line. RUNBOOK §4 also says, at line 186, "A
  consumer never adopts an unregistered value." The decision asserts that the value must change,
  declines that mechanism, and still recommends the change in `## Migration implications`. An
  acceptance reviewer therefore cannot tell whether R75 is adopting an unregistered value.
- *The decision disagrees with a published decision.* R72 is resolved and published, and it made
  the identical kind of addition, `web = ["dep:axum", "dep:tokio", "dep:base64"]`
  (`research/topics/72-api-pagination/DECISION.md:260-300`). R72 argued from R69's clause (4),
  which names "R72 to R76's middleware" as modules inside the `web` tree. On that clause R72 found
  that the literal "records R69's own two dependencies; it does not close the list". R72 therefore
  concluded that the addition leaves the registered value unchanged, so no `CONFLICT:` line was
  needed. R75 takes the opposite reading of the same clause and does not cite R72. Two published
  consumers would then hold incompatible readings of one registered value.

**Repair.** Choose one of two options.

- **(a) Recommended, because it matches accepted precedent.** Adopt R72's clause-(4) reasoning,
  cite R72 `DECISION.md:260-300`, and state that adding `dep:tower-http` to `web` is a thing-(4)
  dependency within R69's value. Then make three edits:
  - delete "requires an R69 revision or a controller ruling" and "a literal change to a registered
    value, which a consumer may not make on its own";
  - drop "(needs R69, see `## Parameters`)" from the `Cargo.toml` row and "must join" from the R69
    hand-off at line 411;
  - keep "No `CONFLICT:` line".
- **(b)** If the synthesizer rejects R72's reading, raise the §4 line instead, for example
  `CONFLICT: R69 web-extra-surface — web = ["dep:axum", "dep:tokio", "dep:tower-http"] — the
  R75 layers need tower-http compiled exactly when web is on`. Then state why R72's contrary reading
  does not govern.

### 2. JF-8: the A12 figure does not match the log

**Failed claim.** Decision line 532: "| A12 | 5 s handler, 200 ms timeout | 408, headers present,
1 event, `duration_ms` 201.2 |".

**Evidence.** `review/evidence/stack-acceptance.log` records `duration_ms=202.0` in the host run and
`duration_ms=202.2` in the 1.96.0 run. The value 201.2 appears in neither run. The decision states
that "every figure below was rerun fresh" and that the E1 table is quoted from
`stack-acceptance.log`.

**Repair.** Replace `201.2` with the logged values, for example "`duration_ms` 202.0 (host) / 202.2
(1.96.0)", or with "≥ 200" as the assertion states.

### 3. JF-1: the size of the template code is stated inconsistently

**Failed claim.** Decision lines 201-202: "the header table and the two functions are the whole of
the template code R75 adds".

**Evidence.** Line 53 says "about 75 lines of template code (the header table and four
functions)". The code block that follows line 202 defines four functions: `security_headers`,
`echo_request_id`, `access_log` and `apply_middleware`.

**Repair.** Change "the two functions" to "the four functions" at line 202.

## Observations (not findings)

- **Controller note (a): the prompt snapshot predates Q17.A.**
  - *What was checked.* `diff inputs/prompt.md
    research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md` shows exactly
    two differing lines, 26 (`engines: codex` versus `muse`) and 76 (the substitution sentence).
    `manifest.json` `required_engines` still reads codex, opus and doxa.
  - *How the decision handles it.* The decision's claim about the snapshot is accurate. The
    decision cites the snapshot only for lines the two files share, and the gap is disclosed at
    lines 11-18 and 686-688.
  - *Repair.* The controller re-freezes the inputs and cites Q17.A. This does not fail the
    synthesis.
- **Controller note (c): tower-http 0.6.11 in the OTel tree.** R78 reports that its OTel tree
  already carries tower-http 0.6.11. R75 selects 0.7.1 and is silent on this.
  - *Scope of R75's evidence.* The decision's "only duplicates are the proc-macro `syn` 2 / 3 split"
    (line 510) holds for the probe tree without an `otel` feature.
  - *Consequence.* With R78's feature on, the tree would presumably carry two tower-http minors, and
    any R78 layer built against 0.6 types would occupy slot L4.
  - *Assessment.* The decision reserves L4 and hands the span question to R78. It does not mishandle
    the tension. It could add "an R78 tower-http line other than 0.7" to its re-verify trigger.
- **Synthesizer seat.** RUNBOOK §2 (line 88) names a fresh Claude Fable context as the synthesizer.
  This synthesis ran on `claude-opus-5-5`, the same model as the opus raw leg. The decision
  discloses this at lines 32-34. Staffing is the controller's business.
- **RUNBOOK §5, the OpenTelemetry integrated path.** R75 does not exercise the OTel path. It
  reserves L4 for R78's layer. This is consistent with R69 and R72, neither of which demonstrates
  that path for its own layer. R78's integrated example should run through this stack.
- **Probe dev-dependencies.** The probe's dev-dependencies enable tower-http `trace` and `cors`, so
  the test builds unify more features than the production set. E0 reports the normal tree
  separately. This bears only on the empirical audit.
- **Muse model identity.** The muse leg records an actor but no model identifier. The decision
  records this as gap 4.
