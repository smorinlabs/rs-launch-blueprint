# R74 rate-limiting-middleware — judgment audit (revision 1)

actor: fable
model: claude-opus-5-5
family: anthropic
decision: research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md (revision 1)
decision-sha256: 84c01ec019f9ba68b731b56ad846dece449ddecdf8fb6d548530f2dc1b4b3056
audited: 2026-09-26, against the current working-tree registry, prompt, policy and prerequisites
verdict: reject
unresolved-findings:
1. JF-3/JF-9 — `## Engines` names the wrong absent leg and omits the Muse report (blocking)
2. JF-4 — REST-standard rule IDs mislabelled, so the re-verify trigger watches the wrong rule
3. JF-4 — R1.7 misquoted in the opening argument
4. JF-8 — a cited log does not exist
5. JF-4/JF-5 — coupled-decision citations have drifted (R77, R79, R70, R73)
6. JF-1 — "always registered" versus an `Option`-taking install call is not resolved

The sha256 was recomputed with `shasum -a 256` before any other read and matched the expected value.
Reads: the decision; `inputs/prompt.md` (byte-identical to the live topic prompt); `research/RUNBOOK.md`
§2 and §5; `raw/opus.md`, `raw/doxa-{openai,perplexity,gemini}.normalized.md`, `raw/muse.md`;
`manifest.json`; `inputs/prerequisites.json`; the evidence logs and snapshots; published
`research/topics/{01,67,69}/DECISION.md`; the run decisions of R69 r10, R70, R73, R77, R79 and R80;
`docs/port/{PARAMETERS,OWNER-REVIEW,OWNER-ACCEPTANCES,COMMONALITY}.md`; py at `b08bccfb`. I did not read
any `audit-*.md` or snapshot file of any seat. No git write, no runner command, no network call.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (finding 6) | Otherwise consistent. B1–B9 statuses match the probe log. "nine tests" (line 211) is 7 A-tests + 2 B-tests (`r74-probe.log:100-109`, `:233`), and the two B-tests exercise `tower_governor` rather than the composition. That is a wording note, not a finding. |
| JF-2 prompt questions and constraints | pass | HIGH Q1: the crate table (lines 213–223) and exclusion (58–75). HIGH Q2: lines 144–155 (conditional registration compiled; Cargo feature rejected). MEDIUM Q3: `tower_governor` truncation `D2a`, plus B6. MEDIUM Q4: A2 (125–129) and the R70 coupling (354–365). LOW Q5: `loco` (201–205). Gates 1–6: lines 215–237, with gate 1 marked `inapplicable` and its reason. Out-of-scope items are handed over rather than decided, with the reservation noted under JF-5. |
| JF-3 `## Engines` faithful and every disagreement adjudicated | **fail** (finding 1) | The Opus and Doxa quotes check out: gemini `:75` "None of the shortlisted candidates failed…" and its RFC 7807 citation `:22`; perplexity `:63` "does not explicitly document `Retry-After`"; openai `:37` "No well-regarded production adopter was verified" and `:94` "fixed-window boundary bursts"; Opus `:665` "over-states the wait". Each leg's recommendation is represented correctly (openai `:229`, perplexity `:73-75`, gemini `:55-59`). The Muse leg is missing. |
| JF-4 load-bearing claims trace | **fail** (findings 2, 3, 5) | Spot-checks that hold: R11.2 at snapshot `:1686-1688`; R5.12 carve-out `:1023`; R8.10 `:1387`, `:1397`; R11.5 `:1724`; R12.2 `:1784`. py `app.py:131-146` (idempotency first, rate limit, then SecurityHeaders, then RequestID last-added); `settings.py:70`; `app.py:220-241`. R01 `:138`; R67 `:383`; R69 r10 `:1106` (`axum::serve(listener, app)`), `:1492` (salvo), zero `ConnectInfo`/`into_make_service` in R69 r10 and in the owner reference (`:333`). COMMONALITY `:320,321,327`. |
| JF-5 couplings hand over owned choices | pass, with one reservation | R69: a hand-off, correctly not a `CONFLICT:` (R69 r10 fixes no `serve_until` argument). R70: the envelope and catalog gap are stated and not decided. R67: the catalog number is left to R67 (line 373). R77: fixes family members, which R77 r2/r3 explicitly delegate (R77 r3 `:43`, `:682`). R79: the declined hand-off is reported honestly. R75: constraints only. Reservation: line 378 says "**Decided:** the rate limiter sits outside R73's layer". The prompt's Out-of-scope says "this item does not decide where in the stack rate limiting sits". R73 did delegate it (R73 `:754-758`, "R74 owns the decision"), so this is defensible, but the wording should be "a constraint handed to R75, agreed with R73". The line 387 constraint list already frames it that way. Folded into finding 5's repair. |
| JF-6 assumes lines byte-identical to the live registry | pass | All four `- assumes` lines (decision `:462-465`) equal `docs/port/PARAMETERS.md:7-10` byte for byte. Leaving out `web-extra-surface` is correct: `- consumes:` is empty, and R69 r10 (accepted, unpublished; `OWNER-ACCEPTANCES.md:60`) is carried in prose, per the standing rule. |
| JF-7 no conflict with accepted/published prereq values | pass | `prerequisites.json` binds R69 r9 (`d4507f5b…`), which is still the published text. The decision's `crates/web` paths follow R69 r10, which the owner accepted (W0-R69c, `OWNER-ACCEPTANCES.md:60`). R02 r2 (`:71`) and R05 r3 (`:75`) are consumed as recorded. R01's seam (`:138`) and R67's catalog grammar (`:383`) are honoured. No coupled item that has moved (R70, R73, R77, R79, R80) is accepted. |
| JF-8 evidence scripts and counts | **fail** (finding 4) | Counts match: `r74-probe.log` has 54 PASS / 0 FAIL, `r74-registry-figures.log` 88/0, `r74-rest-conformance.log` 40/0, and each `CHECKS RUN:` line agrees. `MANIFEST.tsv` has 37 data rows. `C3` +37 and `C4` +49 are at `r74-probe.log:254-255`. `F2-rv` null values and `F6` are at `r74-registry-figures.log:19,25,43,104-105`. The shape log is missing. |
| JF-9 decision shape | **fail** (finding 1) | The H2 set follows RUNBOOK §5, with `## Supersedes` correctly absent. `## Engines` does not cover the current required engine set. |
| JF-10 recommendation follows from evidence | pass, conditional on finding 1 | The gate-2 exclusions (`F2-rv`, `F6`), the three measured `tower_governor` defects, the +0 dependency delta, and R11.2's MUST with no applicability switch together support a zero-crate, always-on GCRA layer. The unadjudicated Muse disagreement goes to this move, so the pass is conditional on revision 2. |

## Findings

### 1. JF-3/JF-9 — the engine set is stale, and the Muse report is neither listed nor adjudicated (blocking)

**Failed claim** (`## Engines`, line 640): *"codex — **absent.** The controller deferred the Codex leg
under owner ruling **W1-CODEX3** (2026-09-18). A Deep-tier item's engine set is `codex, opus, doxa`;
this item ran two of the three…"*

**Evidence.**
- The live prompt and this run's `inputs/prompt.md` now read `- engines: muse, opus, doxa`, and the
  tier guidance adds *"This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot;
  its mirrored `- engines:` line is authoritative."*
- `RUNBOOK.md` lists R74 in the Muse bulk set.
- `manifest.json` records a migration event with `"from": "codex"`, `"to": "muse"`,
  `"reason": "muse bulk substitution (owner decision Q5.A 2026-09-21)"`, and
  `required_engines: ["muse","opus","doxa"]`.
- `raw/muse.md` exists (sha256 `c3e018cfd5f7df4f4887d4c04d2464fbd0280e749a42d7a69e48a8684c2690dd`;
  `scripts/check-answer-shape.sh … bundle` returns `OK`). It is untracked, and its manifest operation
  is still `"state": "submitting"`, so it is present but not yet registered as collected.
- The Muse report disagrees with this decision's load-bearing move:
  - `raw/muse.md:25`: *"(B1) off by default — with the setting unset, unbounded request counts all
    succeed and no limiter state exists"*.
  - `raw/muse.md:47`: *"No `BASELINE-REVIEW:` finding is raised."*
  - It also repeats, for `tower-rate-limiter`, the fixed-window *"over-states the wait"* reasoning
    that this decision's Disagreement 2 calls wrong.
- RUNBOOK §5 requires `## Engines` to cover "all reports and evidence checks, disagreements, and the
  evidence that resolved each". Acceptance requires current inputs.

**Repair.** Once the controller has collected and registered the Muse leg, write revision 2:
- `## Engines` lists `muse` (model `muse-spark`, raw path and sha256) in place of the Codex bullet,
  and cites Q5.A.
- It adjudicates, on evidence, at least: Muse's off-by-default B1/B2 and its missing `BASELINE-REVIEW`
  against W2-REST/R11.2; its fixed-window wait claim; and any figure or source reading in which it
  differs.

This audit does not pre-judge those adjudications.

### 2. JF-4 — rule IDs are mislabelled against the pinned standard, so the re-verify trigger watches the wrong rule

**Failed claims.**
- Conformance table: `| R1.8 | 229 | — | switch-scoped rules bind only while the switch is on… |`
  and `| R1.10 | 352, 353, 362 | — | …reserved…; no new X- names |`.
- The opening paragraph and line 244 cite "§1.7 line 273".
- The re-verify line names "R1.7, R1.8" among the watched rules.

**Evidence.** In `review/evidence/snapshots/rest-api-standard.md`:
- `:227` is `### 1.8 Applicability switches` and `:229` is `**R1.6**`.
- `:301` is `### 1.10 Reserved names` and `:312` is `**R1.8 — Reservation discipline.**`. No rule
  R1.10 exists.
- `:269` is `### 1.9 Deviations…` and `:271` is `**R1.7 — No silent deviation.**`.

The decision confuses section numbers with rule IDs. As a result, the re-verify trigger never names
R1.6, the switch rule on which "R11.2 binds unconditionally" rests. The W2-REST ruling itself uses R1.8
correctly, for the reservation of `cursor`/`limit` (`OWNER-REVIEW.md:195`). `r74-rest-conformance.sh:81-82`
carries the same wrong labels (`at "R1.8" 229`, `at "R1.8-vocab" 237`).

**Repair.**
- Relabel the rows `R1.6 | 229, 237` and `R1.8 | 312 (352, 353, 362)`.
- Change "§1.7" to "R1.7 (§1.9)".
- Add R1.6 to the re-verify rule list.
- Rename the matching check labels in `r74-rest-conformance.sh`, then regenerate its log.

### 3. JF-4 — R1.7 is misquoted in the opening argument

**Failed claim** (lines 14–16): *"A template that ships with limiting off is nonconformant with a MUST
from its first request, which §1.7 calls *'nonconformance regardless of the deviation's merits'*
(line 273)."*

**Evidence.** Snapshot `:272-275`: *"A deviation from a **MUST** makes the API nonconformant unless it
is recorded as an approved exception in the conformance note; silent deviation from any rule strength
is nonconformance regardless of the deviation's merits."* The "regardless of merits" clause is scoped
to *silent* deviation. A recorded, approved exception is expressly conformant. Line 244 states this
correctly ("an unrecorded deviation").

The conclusion survives: conforming is preferable to spending an exception, and the re-verify line
already says that declining the F323 move "turns R11.2 into a second override". The quoted rationale
does not survive.

**Repair.** Restate lines 14–16 as follows: shipping off by default would deviate from a MUST. That
deviation is conformant only as a recorded, owner-approved exception. The decision chooses to conform
rather than ask for one.

### 4. JF-8 — a cited log does not exist

**Failed claim** (`## Empirical check` table): `| r74-decision-shape.sh | see its own summary line |
run last, against this file as committed | review/evidence/r74-decision-shape.log |`, and line 610:
*"`r74-decision-shape.sh` asserts all four of those results"*.

**Evidence.** `review/evidence/` contains `r74-decision-shape.sh` but no `r74-decision-shape.log`.
The validator-diagnostic count and the "no build artefacts" assertion (line 511) that the decision
attributes to this script therefore have no recorded output. Separately, the whole `review/` directory
is untracked in this worktree, while the decision says "as committed"; that is a matter for the
controller and the empirical auditor.

**Repair.** Run the script against revision 2 and commit its log. Alternatively, change the row to say
the log is produced at audit time and cite no result from it.

### 5. JF-4/JF-5 — coupled-decision citations have drifted since 2026-09-18

**Failed claims.**
- R77 is pinned as *"revision 2 (sha256 `46b2a05f…`)"* at lines 246 and 783.
- R79 is cited as *"Two instruments, not three"* (`:36`) and *"deliberately unlike R74's opt-in rate
  limiting"* (`:322`).
- On R70, lines 360–365 say: *"Two things are **stated, not decided here**: R70 omits `type` by
  default (`:52`) … and R70 sets `code` to R67's `ErrorCode::as_str()` token verbatim (`:57`)"*.
  R5.13's row says *"R70 revision 1 omits `type` by default"*.
- On R73, line 378 reads *"**Decided:** the rate limiter sits outside R73's layer"*, citing R73's
  `raw/opus.md:1218-1224`.

**Evidence.**
- R77's run decision is now revision 3 (sha256 prefix `5985ee47`, commit `1e3cdb5b`). The rate-limit
  constraints are unchanged at `:43` and `:682`.
- R79 is now revision 2. The quotes have moved to `:83` and `:369`.
- R70's working copy is revision 3 and resolves both "stated" items. `:36` makes `type` mandatory
  under R5.13 point 5. `:155-156` and `:184-195` separate a snake_case `code` from `catalog_code`.
  `:499-503` confirms R74 still has no catalog code.
- R73 now has a `review/DECISION.md` (revision 1). It hands the placement over at `:754-758`
  (*"R74 owns the decision"*).
- None of these items is accepted, so JF-7 is unaffected. The citations are stale and must not be
  published as current.

**Repair.**
- Re-pin R77, R79 and R70 to their current revisions, hashes and lines.
- Rewrite the R70 coupling and the R5.13 row as "resolved by R70 revision 3". Keep the catalog-row
  request to R67.
- Cite R73's `DECISION.md:754-758` rather than its raw report.
- Word the R73 placement as a constraint handed to R75 and agreed with R73, matching the
  Out-of-scope bullet.

### 6. JF-1 — "always registered" versus an `Option`-taking install call is not resolved

**Failed claim.**
- Line 42: *"The layer is **always registered**"*.
- Line 19: the conditional-registration mechanism *"is still answered and still compiled — it is
  simply no longer the shipped default"*.
- B2's evidence is `A conditional_registration_is_the_gate`, whose `None` branch yields no layer.
- The migration table puts `install_rate_limit(router, policy, store)` in shipped
  `crates/web/src/lib.rs`.

**Evidence.** The decision does not say whether the shipped `install_rate_limit` takes
`Option<RateLimitPolicy>`. If it does, "no member can disable limiting" (line 44) is enforced only by
R77's settings type never producing `None`, and that invariant is not recorded as a hand-off to R77.
If it does not, B2's cited test exercises a code path the template does not ship. P03 needs one answer.

**Repair.** State the shipped signature. For example: `install_rate_limit` takes a non-optional
`RateLimitPolicy`, and the `Option` form survives only as evidence for HIGH question 2 and for
`OVERRIDE (OV-17)`/F323 reversal options. Then point B2 at a test of the shipped form. Alternatively,
record the "never `None`" invariant as a hand-off to R77.

## Notes (not findings)

- The recommendation itself is well argued. The gate-2 exclusions are executed at the release and at
  `master` (`F2-rv`, `F6`), the three `tower_governor` defects are measured, the zero-crate delta has
  a discriminating control (`C5-control`), and the correction of Opus's fixed-window reasoning is
  right. Revision 2 should need no change of direction unless the Muse adjudication finds new evidence.
- `OVERRIDE (OV-17)` follows the §1.9 deviation shape. OV-17 is the number the controller allocated
  (`execution-ledger.md:1074`).
- The ledger observation for R75 checks out at the pin: `app.py:146` adds `RequestIDMiddleware` after
  `SecurityHeadersMiddleware`, so the request-id middleware is outermost.
