actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: b7368070722f08e4a7a879896bf19bc929b5c823379060aa962d2fd6a5f37f40
verdict: reject
unresolved-findings:
1. JF-3 (blocking): the Muse leg is required and collected, but the decision leaves it out.
2. JF-8 (blocking): a fifth evidence log, bound to this decision's sha, records a FAIL. The decision does not mention it.
3. JF-4 (blocking): controller request (1) sends the F314 correction to the wrong file and line.
4. JF-5/JF-7 (drift): the R70 coupling and controller request (3) rest on R70 revision 1. R70 has since reached revision 3.
5. JF-4/JF-6 (drift): the claim "`inputs/PARAMETERS.md` snapshot is identical to the live registry" is now false.
6. JF-2: the prompt's LOW question has no explicit answer.

# Judgment audit — R73 idempotency-middleware, DECISION.md revision 1

Target: `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md`.
The recomputed `shasum -a 256` equals the expected
`b7368070722f08e4a7a879896bf19bc929b5c823379060aa962d2fd6a5f37f40`.
The decision is judged against the current prompt, registry, prerequisites and
policy on 2026-09-26, as instructed.

## Summary

The design reasoning is strong and mostly well-evidenced. That includes the
compare-and-set port, fingerprint-beside-key, 2xx-only on a corrected ground,
OV-16, and the `cratestack-axum` gate-2 exclusion. Three fidelity failures
still block approval:

- a required engine leg is missing;
- a committed FAIL is undisclosed;
- a controller request targets the wrong file.

Three drift or coverage items need repair in the same revision.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass (with note)** | The design clauses 1–14, the conformance table, the criteria table and the couplings agree with each other. The count claims that break are recorded under JF-3 and JF-8. Minor: criterion 18 lists `s01`–`s09`, but `s10` is executed (`w15`, `s10`). |
| JF-2 prompt questions and constraints | **fail** → F6 | HIGH Q1 is answered at `:211-245` ("one does, and two independent gates exclude it"). HIGH Q2 is answered in clause 8 and the F314 section. MEDIUM Q3 is answered in the members table and clause 6. MEDIUM Q4 is answered in clauses 4–5. The LOW question ("Do any published Rust web-service templates document Stripe-style idempotency-key replay as a named pattern, and where?") gets no explicit answer. Zero To Production appears only as alternative A2 (`:205`) and in a security note (`:316`). Constraints honoured: stable only, edition 2024, the MSRV floor applied, the OS gap stated, every fitness gate addressed at `:416-441`. |
| JF-3 Engines fidelity | **fail** → F1 | The current `inputs/prompt.md` (identical to the topic prompt) says `- engines: muse, opus, doxa`. `manifest.json` `required_engines` is `["muse","opus","doxa"]`, with a migration record "muse bulk substitution (owner decision Q5.A 2026-09-21)". `raw/muse.md` exists: 291 lines, sha256 `aca328034d31b0280241da56ec8f603e21c3230a299023dc00d0b9bac2870536`, recorded in the ledger as "R73 MUSE LEG COLLECTED, 2026-09-23". `## Engines` (`:622-641`) lists opus and doxa and says "codex — absent … W1-CODEX3". The Opus and Doxa legs themselves are represented faithfully, and the six adjudications are evidence-backed (see JF-4). |
| JF-4 load-bearing claims trace | **fail** → F3, F5 | Verified against sources: Stripe "regardless of whether it succeeds or fails", "only after the execution of an endpoint begins" and "up to 255 characters" in `snapshots/stripe-idempotent.extract.txt:10-12`. `cratestack-axum` `rust-version = "1.98.0"` at `snapshots/cratestack-axum-0.12.0.extract.txt:45`. Standard blob `71bd813c` lines 347, 651-655, 668-670, 673-677, 728, 880, 939-942, 1049, 1743 and 1752 all read as cited. `RUNBOOK.md:18-22` is the REUSE/ADOPT scope. `COMMONALITY.md:317-319` holds F313–F315. R67 `DECISION.md:683-689` holds the misfiled-review-label precedent. `raw/opus.md:1081,1261-1262` confirms the probe was deleted. R69 r10 `DECISION.md:1791` holds the `crates/web` owned value. Owner rulings Q7.B and §11 exist in `owner-decisions.md`. **Wrong:** `:791` and `:182` place the "(Stripe semantics …)" parenthetical in `COMMONALITY.md:318`'s Notes, where the row actually reads `\| bundle \|`. **Stale:** `:457-459` (F5). |
| JF-5 couplings hand over, not decide | **pass (with drift)** → F4 | R75 gets six constraints, each with its reason, and "R75 owns the decision" framing. R74 gets "proposed, not fixed". R77 gets "names proposed only". R71 and R76 are handed constraints. No coupled item's owned choice is decided here. The R70 coupling is stale: see F4. |
| JF-6 assumes lines byte-identical | **pass** | All four `- assumes` lines at `:447-450` match `docs/port/PARAMETERS.md` rows 7–10 byte for byte. The empty `owns` and `consumes` match the prompt and the `research/CLAUDE.md` R73 row (`—`). |
| JF-7 no conflict with accepted or published prereqs | **pass (with note)** | R69 publishes revision 9 (`src/web/`), but owner ruling W0-R69c (ledger, 2026-09-18) re-bound acceptance to revision 10 (`crates/web`). The decision's `crates/web` paths therefore match an owner-accepted value, and they are disclosed with a re-verify trigger. Note for packaging: `inputs/prerequisites.json` still pins R69 decision `d4507f5b…` (revision 9) and must re-bind when revision 10 publishes. R01 `http-transport-injection-seam` and R67 `error-taxonomy-exit-codes` are followed as published. |
| JF-8 evidence scripts and counts | **fail** → F2 | The four named logs count exactly as claimed: 43/0/0, 26/0/0, 23/0/0 and 17/0/0 = 109. Probe claims match the logs: 10 `#[test]` in `tests/store.rs` and 18 in `tests/web.rs`; the P6 deltas 51/+8/+3/+5/+9/+11/+14/+37; 275 ns/op; "Locking 62 packages … Rust 1.96". The snapshots directory exists as described. **Undisclosed:** `review/evidence/r73-decision-shape.sh` and its log, which records `decision_sha256: b7368070…` and `CHECKS RUN: 30 PASS: 29 FAIL: 1` (`FAIL D7-tree — … publication lock is active`), and whose `D7-control` records an h3-field `validate_answer_text` diagnostic. |
| JF-9 decision shape | **pass** | The date-first H1. Exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, and no `## Supersedes` at revision 1. `## Decision` carries the recommendation, versions, the settled F313–F315, `### Principles and implementation`, and a `re-verify:` line (`:443`). This matches `RUNBOOK.md` §5. |
| JF-10 recommendation follows from evidence | **pass (with note)** | Both published crates are excluded, on MSRV and fit (`cratestack-axum`) and on sessions plus measured +37 (`axum-idempotent`). The std store is measured cheaper than every cache crate. The compare-and-set follows from R3.9 non-re-execution. The 2xx-only rule is re-grounded on the layer's lack of an execution-started signal plus R11.6. Note: R3.9 at `:653` itself says "(Stripe semantics): the server fingerprints …", while the decision shows Stripe replays failures. The colon bounds what the standard means, so 2xx-only conforms. The conformance table should say so explicitly, so readers do not see an apparent contradiction. |

Currency checks, 2026-09-26 (read-only, public):

- `https://static.rust-lang.org/dist/channel-rust-stable.toml` reports rustc `1.98.1 (48a229cea 2026-09-01)`. The 1.96 floor still holds.
- `https://crates.io/api/v1/crates/cratestack-axum` reports newest `0.14.0` (the decision cites 0.12.0), and every recent version still declares `rust_version` `1.98.0`. The gate-2 exclusion stands, and the re-verify trigger has not fired.
- Disclosure: that crates.io request carried the user's email address in its `User-Agent` header. This was an auditor error and is recorded here.

State observation for the controller, not a decision finding: `operations/muse.json` and the manifest's muse operation still read `state: submitting`, although `raw/muse.md` is present.

## Findings

**F1 — JF-3, blocking. The Muse leg is missing from `## Engines`.**

- **Failed claim** (`:634-641`): "**codex** — **absent.** The Codex leg is deferred by owner ruling **W1-CODEX3** … **no second model family reviewed the Opus report**". Also `:705`: "all four independently reach a client-supplied key …".
- **Evidence:** the current prompt says `- engines: muse, opus, doxa` and adds "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative". The manifest's `required_engines` includes muse, with migration reason "owner decision Q5.A 2026-09-21". `RUNBOOK.md` §2 lists R73 in the Muse bulk set. `raw/muse.md` (sha `aca32803…`, model `muse-spark`, request `511e5c1c36164801b65a8c5383665aa3`) takes positions that disagree with the decision and that `## Engines` must adjudicate:
  - "none exists" for published crates: 404 probes plus `minco-plugin-idempotency`, missing `cratestack-axum`;
  - a hand-rolled `tower::Layer` with `tower` as a direct dependency;
  - a `moka::sync::Cache` store;
  - a body hash folded into the composite key;
  - an async `IdempotencyStore` trait;
  - `Idempotency-Replayed: true`;
  - no in-flight state and no 409 or 422;
  - 2xx-only justified as "Stripe semantics";
  - Zero To Production attributed to "Luke Maxwell".
- **Repair:** in revision 2, add a `muse` entry with its raw path, sha and model. Adjudicate each Muse position against the evidence the decision already holds: `S4-cs-*`, `P2-tower-edge` and R69 r10, the P6 cache deltas and clause 6, clause 5 with R3.9 `:653-655`, R05's sync core (`P3-sync`), R4.12, R3.9 non-re-execution, and `S1-replay-errors`. Replace the "codex absent / W1-CODEX3" paragraph with the Q5.A substitution. Correct the convergence and count statements to cover five legs: `:705`, the "two of the three Doxa providers" sentence at `:181`, and disagreements 1 and 4.

**F2 — JF-8, blocking. A committed FAIL is undisclosed.**

- **Failed claim** (`:505-507`): "Four scripts, **109 checks, 109 pass, 0 fail, 0 skip**".
- **Evidence:** `review/evidence/r73-decision-shape.log` names this exact decision (`decision_sha256: b7368070…`) and ends `CHECKS RUN: 30 PASS: 29 FAIL: 1 SKIP: 0`. The failure is `FAIL D7-tree — scripts/check-research-tree.sh . failed: FAIL: publication lock is active`. The script and log appear nowhere in `## Empirical check`. `D7-control` also records that this decision produces one h3-field `validate_answer_text` diagnostic, which the log attributes to document class.
- **Repair:** add `r73-decision-shape.sh` to the evidence table with its true count. Rerun D7-tree once the publication lock is clear and commit a passing log, or report the environmental FAIL and its cause in the decision. State the h3-field diagnostic and why it is acceptable.

**F3 — JF-4, blocking. The F314 correction cites the wrong file.**

- **Failed claim** (`:791-793`, echoed at `:182`): "`docs/port/COMMONALITY.md:318`'s F314 Notes parenthetical — '(Stripe semantics: errors are meant to be retried for real, not replayed)' — is factually wrong".
- **Evidence:** `COMMONALITY.md:318` reads `| F314 | idempotency cache only stores successful (2xx) outcomes | web-service | py-only | DIVERGENT | R73 | bundle |`. It has no Stripe text, and the file is unchanged since 2026-09-12. The text lives in `docs/port/areas/web-service.md:20` (Notes column: "Stripe semantics: errors are meant to be retried for real, not replayed.") and, parenthesized, in `inputs/prompt.md:9`. A controller acting on the request would edit the wrong file.
- **Repair:** re-cite the request to `docs/port/areas/web-service.md:20` and the prompt's per-row evidence line. Keep the substance, which `S1-replay-errors` supports.

**F4 — JF-5/JF-7, drift. The R70 coupling is stale.**

- **Failed claim** (`:730-735`, `:798`): "**R70 revision 1 does not conform to the standard that now binds it**: its envelope omits `type` by default and relies on `about:blank` …". Request (3): "The R70 revision 1 `about:blank` conflict with R5.13 should reach R70 before it publishes."
- **Evidence:** `research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md` is now revision 3. Its M-1 (`:36`) makes "`type` … **mandatory**" and its field table (`:134`) says "**always present**, never `about:blank`". The conflict has already reached R70 and been addressed there.
- **Repair:** re-cite the R70 coupling to its current revision. Drop controller request (3). Keep the five status bodies and the "error responses are never replayed" note. Keep R70's publication as a re-verify trigger.

**F5 — JF-4/JF-6, drift. The registry-snapshot identity claim is false.**

- **Failed claim** (`:457-459`): "this run's `inputs/PARAMETERS.md` snapshot is identical to the live registry, verified by `diff` (check `D3-params`)".
- **Evidence:** `diff inputs/PARAMETERS.md docs/port/PARAMETERS.md` now differs, because R11 published `ci-job-structure` on 2026-09-25. The four `assumes` lines remain byte-identical (JF-6 passes on them).
- **Repair:** have the controller re-snapshot `inputs/PARAMETERS.md` and rerun `D3-params`, or narrow the sentence to the four fixed rows it actually depends on.

**F6 — JF-2. The LOW question is unanswered.**

- **Failed claim:** none. The question is simply not addressed: "Do any published Rust web-service templates document Stripe-style idempotency-key replay as a named pattern, and where?"
- **Evidence:** Zero To Production appears only as alternative A2 (`:205`) and in a security note (`:316`). The decision never says whether any template documents the pattern. The Opus raw has the material (`raw/opus.md:24,41,53`: the companion repository `LukeMathWalker/zero-to-production` `src/idempotency/`, 6,539 stars). The Muse raw states the gap ("No mainstream Rust web template found documents …").
- **Repair:** add one sourced sentence answering the question: no template does, and Zero To Production's book companion is the named reference, DB-backed and in-handler. Carry the evidence gap explicitly.
