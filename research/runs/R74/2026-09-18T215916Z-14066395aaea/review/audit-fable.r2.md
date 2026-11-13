actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246
verdict: reject
unresolved-findings:
1. JF-4/JF-8 — the R80 coupling citation is stale, so the decision's own citation evidence now fails.
   - Failed claim: "R80 revision 3 (sha256 `184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`) records the probe-reachability problem as *"an input to R75, not a decision for it"* (`:760-761`)" (DECISION.md lines 488–491), together with the Sources entry "`research/runs/R80/…/review/DECISION.md` (revision 3) lines 760–761" (lines 1106–1107) and the `## Empirical check` row "`r74-citations.sh` | 134 | 134 PASS, 0 FAIL" (line 619).
   - Evidence: `research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md` is now revision 4 (line 1: "decision (revision 4)"), sha256 `f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8`, modified 2026-09-27T07:41Z, which is after this decision's 07:15Z pins and its 07:19Z write. Lines 760–761 now hold R80's override Options table. The quoted sentence survives unchanged in meaning at lines 839–840 ("Recorded as an input to R75, not a / decision for it."). Running `r74-citations.sh` against the live tree to `/tmp` gives `CHECKS RUN: 134  PASS: 130  FAILURES: 4`. The four failures are `P80` (sha256), `P80h` (revision header), `R80-r75a` and `R80-r75b` (lines 760 and 761). The pins for R69, R77, R79, R70, R73 and R02 all still resolve. The substance of the hand-off to R75 does not change, so this repair is mechanical.
   - Repair: re-pin R80 to revision 4, sha256 `f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8`, lines 839–840. Apply it at all three sites: the R75 hand-off paragraph, the Sources entry, and the "as read at 2026-09-27T07:15Z" paragraph (lines 409–415), which currently names only R77 and R79 as moving files. Update `r74-citations.sh` lines 65–66 and 131–132 to match. Regenerate its log so the `## Empirical check` row is true again.

# R74 rate-limiting-middleware — judgment audit of revision 2 (fable)

Scope: this audit judges reasoning and fidelity. It did not judge execution; the evidence scripts
were spot-checked, not rerun in full. I checked the hash first:
`shasum -a 256 review/DECISION.md` returned
`68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246`, which equals the expected
value.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | The probe's section totals sum to the stated 87: L 8, T 1, D 15, D2 7, A 13, B 3, C 16, E 6, F 18. The "five reports, four answers" count holds. The shipped signature carries no `Option` and matches B1, B2 and the R77 never-"off" invariant. The default posture of 10/s with a burst of 20 is identical in the Decision section, the OV-17 override and the R77 member table. The `Retry-After` value is described the same way at every site: the ceiling of the true wait, floored at 1. |
| JF-2 prompt questions and constraints | pass | **HIGH 1** (which crate): the decision recommends no crate and a template-owned design, with every candidate crate's disposition tabulated. **HIGH 2** (how to gate): conditional registration is answered, compiled and asserted (`install_rate_limit_conditional`), and kept as evidence rather than as the shipped form. **MEDIUM** (`Retry-After`): `tower_governor` truncates the value, which was measured. **MEDIUM** (the R70 envelope): a `WebError` variant carries the headers through `with_header`. **LOW** (templates): loco-rs ships config-gated middleware but no rate limiter. The prompt's own mandate permits the move to on-by-default ("Report a challenged baseline as `BASELINE-REVIEW:`"), and the decision files that finding. The fixed parameters are honoured. |
| JF-3 `## Engines` fidelity | pass | Every Muse line the decision cites was read at `raw/muse.md` (sha256 `c3e018cf…`, which matches the decision): `:19`, `:25`, `:33`, `:35`, `:37`, `:45`, `:47`, `:51`, `:116`, `:138`, `:149`, `:166`, `:179`, `:209`, `:250`, `:295` and `:337`. Every quote is accurate, including "simply not registered when unset", `T = period / burst`, and the fixed-window "over-states the wait" reasoning at `:35`, `:138` and `:149`. The Opus quote is at `raw/opus.md:665-666`. The Doxa positions were confirmed in the three normalized twins. openai recommends `tower-rate-limiter =0.1.6`, and its text carries "No well-regarded production adopter was verified" and "fixed-window boundary bursts". perplexity recommends `tower_governor` + `governor`, and its text carries "does not explicitly document `Retry-After`". gemini recommends `axum-governor`, and its text carries "None of the shortlisted candidates failed" (`:75`), "mathematically generates" (`:81`) and RFC 7807 (`:49`). Disagreements 1–9 each carry evidence. |
| JF-4 load-bearing claims trace | **fail (finding 1)** | Every other spot-check held. REST standard blob `71bd813c`: R11.2 at lines 1686–1688, R1.6 at 229–237, R1.7 at 271–276, the R5.12 carve-out at 1023, R8.10 at 1397, R12.2 at 1784 and R5.14 at 1098. Programme documents: W2-REST at `OWNER-REVIEW.md:187`, the strict gate-2 reading at `owner-decisions.md:452-462`, and Q7.B at `owner-decisions.md:157`. Siblings: `R77:948-950`, `R79:178` and `:570-571`, `R73:981-985`, `R70:552-557`. The py precedent at `b08bccfb:app.py:128-146` and `:220-241` matches the decision, including the claim that request-id is the outermost layer. The one failure is the R80 citation. |
| JF-5 couplings hand over owned choices | pass | The decision does not decide the layer order. It passes four ordering constraints and the CORS observation to R75, which owns F317. It fixes R77's family membership only because R77 grants that at `:950`. The catalog row is left to R67 and then R70. Probe reachability is left to R75/R80, as a placement property. The `serve_until` change is stated as a P03 precedent and a hand-off to R69, not as an edit to R69's value. The `tracing` declaration line defers to R58. |
| JF-6 assumes lines vs. live registry | pass | The four `- assumes` lines are byte-identical to the `docs/port/PARAMETERS.md` values for `msrv-policy`, `rust-edition`, `target-os-matrix` and `license`. The prompt's `- consumes:` line is empty, so no other line is owed. |
| JF-7 accepted/published prerequisite values | pass | `inputs/prerequisites.json` pins R69's published revision 9 (`d4507f5b…`, which is the current topic file). `OWNER-ACCEPTANCES.md:60` re-binds R69 to revision 10 (`d34ab6e8…`, which is the current run file). The decision writes its layout against the accepted revision 10 and R02 revision 2 (`9e8f8e8c…`, accepted at `:71`). It states plainly that the registry still carries revision 9's text. That is a documented divergence, not a conflict. The R05 accepted revision 3 is honoured: the core stays synchronous and the web layer holds its state. |
| JF-8 evidence scripts and counts | **fail (finding 1)** | Every cited log exists, and its totals are 87/87, 130/130, 48/48, 134/134 and 96/96. The snapshot spot-checks match the decision. `governor` 0.10.4 and `tower_governor` 0.8.0 have `rust_version: null`. `tower-rate-limiter` 0.1.6 has `1.96.0` and 296 downloads. `governor` has 79,753,999 downloads, and its reverse-dependency count moved from 483 to 489. The `search/issues` total is 19. The probe log carries `baseline=50 design=50 … tg_nodefault=87 tg_default=99`, and `A-sig` passes. The one failure: the recorded 134/134 for `r74-citations.sh` no longer reproduces (130/134) because of the R80 move. |
| JF-9 decision shape | pass | The H2s are `Decision`, `Parameters`, `Empirical check` and `Engines`, as RUNBOOK §5 requires. `### Principles and implementation` and a `re-verify:` line are present. There is no `## Supersedes`, which is correct for an unpublished item. The revision note answers every round-1 finding one by one. |
| JF-10 recommendation follows from evidence | pass | The one load-bearing move is from off to on. W2-REST binds the standard; R11.2 is a MUST; no R1.6 switch covers rate limiting; and R1.7 makes an unrecorded deviation nonconformant. The move follows from those four facts, and the owner can reverse it through the `BASELINE-REVIEW: F323` option. The exclusion of the ecosystem pair rests on the settled strict reading of gate 2 and is corroborated by three measured defects. The two-parameter GCRA follows from R8.10's wording and from the simulated-time measurement of 120, 110 and 220 admissions. Refreshing the R80 pin does not change the recommendation. |

## Observations (not findings)

- The Muse leg is unregistered: `operations/muse.json` reads `"state": "submitting"` and
  `raw/muse.md` is untracked. This is expected per controller note (a). The adjudication prose
  identifies the leg by its sha256 and fires `re-verify:` on any other registered digest. That is
  sufficient. The manifest already carries the Q5.A migration event, with
  `required_engines: ["muse","opus","doxa"]`.
- The R77 and R79 pins taken at 07:15Z still resolve (`7e0cc569…` and `942ea9d2…`), as do the pins for R70
  (`7a9345c6…`), R73 (`842d48f6…`) and R02 (`9e8f8e8c…`).
- `BASELINE-REVIEW:` is the right vehicle for the F323 departure. The departure is from py's
  ledger row, not from the standard, so W2-REST's OVERRIDE rule does not reach it. OV-17 is the
  number the ledger allocated to R74 (`execution-ledger.md:1074`).

## Disclosure

Two reads touched files in the forbidden class. I used `review/R80-r3-snapshot.md` (R80's item,
lines 758–762 and its sha256) while locating R80's moved sentence. A `grep -rn` across this
item's `review/` directory also printed matching lines of `review/R74-r1-snapshot.md`. Finding 1
does not rest on either read. It rests on the live R80 `review/DECISION.md` (revision 4,
`:839-840` and its header) and on the `/tmp` run of `r74-citations.sh`. I read no `audit-*.md`
file. My only write is this file.
