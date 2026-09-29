actor: fable
model: gpt-6
family: openai
decision-sha256: 96f388d12f267956fb57db29ae52801ef0e614dc0cfba7da36300ea54324845d
verdict: reject
unresolved-findings:

1. **F1 — Claim completion and abandonment do not identify the claim they own. High; JF-1, JF-3, JF-4, JF-10.**

   **Failed claims:** `review/DECISION.md:352-358` says, “The port is a compare-and-set, never a get-then-insert” and “This closes the hole py documents and leaves open.” Lines 949-951 say the OpenAI report reaches “this decision's port shape almost exactly.”

   **Evidence:** `review/evidence/probe/src/port.rs:38-40,74-77` returns an unqualified `Fresh`; `complete` and `abandon` take only the key. In `probe/src/adapter.rs`, lines 124-154 expire an in-flight claim independently of its handler, lines 171-178 allow capacity eviction of an in-flight claim, lines 192-212 complete whichever claim currently occupies the key, and lines 216-220 abandon whichever in-flight claim currently occupies it. The guard also stores only the key (`probe/src/layer.rs:56-74`).

   A source-derived counterexample is sufficient: request A claims key K with fingerprint A; that claim expires or is evicted while A still runs; request B claims K with fingerprint B; A then calls `complete(K, response_A)`. The adapter reads B's fingerprint and stores A's response under it. A retry of B can receive A's response. Alternatively, dropping A's guard deletes B's claim and allows another execution. This is reasoning from the committed transitions, not an executed reproduction. `s05` proves that expiry admits another claimant, but does not exercise the old claimant afterward (`probe/tests/store.rs:141-159`).

   The omitted engine difference is material: `raw/doxa-openai.normalized.md:150-178,228-245,274` specifies a lease identifier, completion/abort by lease, and rejection when capacity contains only in-flight entries. The decision neither adopts these safeguards nor adjudicates their removal. OV-16 discloses lost retention; it does not justify associating one operation's response with another operation's fingerprint.

   **Repair:** Give each claim an ownership token or generation and make completion/abandonment conditional on that exact claim. Do not evict a running claim merely to admit another request. Explain what expiration means when the original handler can still perform effects; a timer alone does not stop it. Adjudicate the OpenAI lease/capacity proposal explicitly. Require acceptance cases for stale completion, stale abandonment, and capacity pressure during a running handler.

2. **F2 — The distributed-store swap promise conflicts with the synchronous call sites. High; JF-1, JF-2, JF-10.**

   **Failed claims:** `review/DECISION.md:173-175` promises a distributed adapter “with no change to the layer or the port”; lines 357-358 say Redis/Postgres need no different layer. Lines 411-414 separately require a future I/O adapter to use `spawn_blocking`.

   **Evidence:** The core trait returns ordinary `Result` values (`probe/src/port.rs:74-77`). The middleware invokes `begin` and `complete` directly on the async request task (`probe/src/layer.rs:165,197,203,215`), and `Drop` invokes synchronous `abandon` directly (`:71-74`). There is no execution bridge selected by the composition root. Replacing those methods with blocking Redis/database I/O therefore either blocks the request task or requires changing the web call sites and the cancellation strategy. Calling `spawn_blocking` inside a synchronous method does not let that method await a result without blocking its caller. R05's accepted synchronous-core direction does not supply the missing bridge.

   **Repair:** Specify how the web adapter dispatches local operations inline and future blocking operations through an offload mechanism while retaining the core's synchronous port. Cover cleanup as well as normal completion. Put that mechanism in the proposed seam now, or explicitly qualify the no-layer-change claim and explain the resulting limitation against the prompt's HIGH-priority swap requirement (`inputs/prompt.md:33`). Do not silently change R05's owned architectural direction.

3. **F3 — The Perplexity fingerprint adjudication misrepresents its report. Medium; JF-3, JF-4, JF-10.**

   **Failed claim:** `review/DECISION.md:860-865` infers from `use-idempotency` having “no request hashing” that “the bundle that leads with it has no owner for the fingerprint requirement at all.”

   **Evidence:** `raw/doxa-perplexity.normalized.md:61` assigns body-hash comparison and a 422 response to middleware conflict handling. Line 237 assigns calculation of the optional body hash to the middleware; line 245 again specifies comparing stored and current hashes and rejecting a mismatch. A primitive crate's non-goal is not the absence of that responsibility from the proposed bundle. The report does make hashing optional in places, and its non-atomic `get`/insert approach remains a legitimate concern. Neither supports the quoted claim of no owner at all.

   **Repair:** Describe the report's actual allocation of responsibility. Adjudicate its optional/underspecified fingerprint policy against mandatory R3.9 fingerprinting. Retain independently supported objections such as concurrency and adoption, without relying on the false absence claim.

4. **F4 — Presence of `dry_run` is incorrectly treated as proof of rehearsal. Medium; JF-1, JF-2, JF-4, JF-10.**

   **Failed claim:** `review/DECISION.md:136` declares conformance because the layer suppresses claims when the reserved parameter “is present.”

   **Evidence:** At the pinned REST standard commit `0850d43e45d919ef5e37f7174c4212b46013c49f`, `rest-api-standard.md:716-728` specifies `?dry_run=true`. The any-value rule at lines 318-321 governs rejection by endpoints that do not implement dry-run. It does not say every value on a supporting endpoint is a rehearsal. `probe/src/layer.rs:103-106,144-148` bypasses protection for `dry_run=false`, an empty value, or any other value. A supporting handler that parses a boolean and executes normally for false can therefore execute duplicate real mutations without replay protection. Raw-string matching can also disagree with a handler's decoded query parsing. `w17` exercises only literal `dry_run=true` (`probe/tests/web.rs:482-502`); it establishes neither value agreement nor a non-mutating rehearsal.

   **Repair:** Define one validated interpretation shared with the endpoint. Bypass only an actual rehearsal; keep ordinary false-valued requests protected, or explicitly reject values outside the supported syntax before execution. State the handling of malformed, repeated, and encoded parameters. Require cases for true, false, and rejected/decoded forms, with a real rehearsal fixture that performs no mutation.

5. **F5 — The R75 handoff fixes owned ordering choices and gives an incorrect routing mechanism. Medium; JF-2, JF-4, JF-5.**

   **Failed claims:** `review/DECISION.md:987-1002` hands R75 “six constraints,” including fixed positions relative to request-id/access-log layers and “`.layer` on the router carrying the unsafe routes, not `.route_layer`, so a 405 … is not preceded by a claim.”

   **Evidence:** `inputs/prompt.md:16,28` explicitly leaves overall ordering, including the request-id/access-log relationship, to R75. Behavioral requirements such as a fresh correlation identifier are valid inputs to that owner; prescribing these positions as binding choices goes further. The routing rationale is also reversed. In the pinned axum 0.8.9 source, [`Router::layer`](https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/axum/src/routing/mod.rs) at lines 303-316 layers path and fallback routers, and [`MethodRouter::layer`](https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/axum/src/routing/method_routing.rs) at lines 967-992 layers its fallback. `MethodRouter::route_layer` at lines 997-1034 leaves that fallback alone. The [versioned MethodRouter documentation](https://docs.rs/axum/0.8.9/axum/routing/method_routing/struct.MethodRouter.html#method.route_layer) expressly identifies method-matched middleware as the way to preserve a 405 against middleware early returns. Router-level and MethodRouter-level `route_layer` must not be conflated.

   **Repair:** Hand R75 required observable behavior and proposed placements with their reasons, leaving its owned ordering decision intact. Correct the API claim and distinguish path matching from method matching. Include an unsupported unsafe method on an otherwise matching path as an acceptance case: 405, zero store claims, and no earlier idempotency error. The empirical auditor can verify the chosen wiring.

6. **F6 — Blanket retryability contradicts retained completion and validation states. Medium; JF-1, JF-2, JF-4.**

   **Failed claim:** The R11.6 conformance row at `review/DECISION.md:143` says “every non-2xx this layer returns or forwards is retryable with the same key.”

   **Evidence:** The decision itself requires a completed-but-unreplayable marker to keep returning 409 without re-execution (`:368-376`). `probe/src/layer.rs:165-168` returns 409 for that marker without releasing it. A mismatched fingerprint returns 422 while the original entry remains, and an invalid key returns 400 until the key is corrected (`:131-142`). Not storing an error response is different from permitting the attempted operation to run again. The pinned standard's R11.6 at lines 1743-1745 requires documentation of retryable failure classes; it does not declare all non-2xx responses retryable.

   **Repair:** Document the retry action by outcome: in-flight conflict, completed-but-unreplayable result, payload mismatch, malformed key, body limit, store failure, and forwarded handler error. Distinguish retrying an unchanged request, correcting input, and consulting an already-completed operation. Hand those distinctions to R70/R71 without choosing their owned envelope fields or catalogue entries.

7. **F7 — Several execution and count claims exceed the cited files. Low; JF-1, JF-4, JF-8.**

   **Failed claims and evidence:**

   - `review/DECISION.md:575-577` says `s10` executes the mapping of `PortError::Unavailable` to `RSLB101`. `probe/tests/store.rs:281-295` checks the variant and the word `poisoned`; it never checks a catalogue code. `probe/src/port.rs:54-70` contains no catalogue mapping. R03 proposes that mapping, but the R73 test does not execute it.
   - `review/DECISION.md:409` says “the nine store checks.” `r73-probe.log:28-43` and `probe/tests/store.rs` contain ten. Line 404 says “all four” `Begin` outcomes, while `probe/src/port.rs:38-51` defines five, including `Completed`.
   - `review/DECISION.md:156-158` says `s06` executes “exactly” the eviction caused by a 1,025th key at capacity 1,024. `probe/tests/store.rs:163-185` exercises a fourth key at capacity three. It supports the eviction rule at a smaller capacity, not the stated numeric experiment.

   **Repair:** Limit `s10`'s claim to the observed error variant, or supply the missing catalogue assertion. Correct the counts. Describe `s06` as a scaled eviction example. The main totals remain correct: 158 PASS across the five evidence logs, 41 PASS in the shape log, and 28 behavioural tests split into ten store and eighteen router tests.

8. **F8 — The required OpenTelemetry integration has no disposition. Medium; JF-2.**

   **Failed coverage claim:** `review/DECISION.md:1029-1037`, headed “What P03 must validate,” gives the integration obligations without addressing the applicable OpenTelemetry requirement. The relevant contract says, “Applicable web decisions must show that their selected components support the integrated path” (`research/RUNBOOK.md:208-212`).

   **Evidence:** The runbook requires an incoming request, handler, outbound operation, context propagation, actual export, useful metrics, exporter failure, and shutdown behavior; lines 33-34 also forbid turning the required example into an optional outcome. This middleware changes that path by short-circuiting replays/conflicts and by dropping claims on cancellation. Its decision discusses excluding cached correlation headers (`:381-383`) and outer request logging (`:996-998`), but supplies no OpenTelemetry compatibility analysis, R78/R79 handoff, or integrated validation disposition. `w16` checks that an old response header is absent; that cannot establish export, context propagation, or metrics behavior.

   **Repair:** Explain how the selected middleware/store arrangement composes with the required instrumented example, including fresh execution, replay/conflict, and cancellation. Give R78/R79 their owned telemetry choices and record the integrated acceptance obligations and evidence gaps. Do not claim that stale-header exclusion alone satisfies the required path, or require this audit to implement the example.

**Check results**

| Check | Result | Evidence and judgment |
|---|---|---|
| JF-1 — Internal consistency | fail | F1's claim transitions contradict the promised concurrency protection; F2's swap promise conflicts with its I/O-offload requirement; F6 contradicts the completed marker. F7 records smaller internal count errors. |
| JF-2 — Prompt coverage and constraints | fail | All five research questions receive an answer or an explicit gap: published middleware (`DECISION.md:255-307`), the 2xx condition (`:194-242,360-376`), store/key design (`:331-393`), and the limited template evidence (`:309-329`). The distributed-swap requirement, dry-run interpretation, R75 boundary, retry documentation, and required instrumented path remain deficient (F2, F4-F6, F8). Linux, real-template feature gating, and fixed-digest checks are explicitly unproven; I do not relabel them as executed. |
| JF-3 — Engine fidelity and disagreements | fail | All three engine legs and all three Doxa providers are represented. F3 misstates Perplexity; F1 identifies an unadjudicated, consequential difference from OpenAI. The repaired Gemini citations really do specify atomic acquisition at raw line 23 and a concurrent 409 check at line 109. The decision distinguishes Stripe's error caching from the requested 2xx policy and explicitly adjudicates Opus's unknown-length response behavior (`:953-964`); those repairs do not cure F1/F3. |
| JF-4 — Load-bearing evidence | fail | Source inspection supports the pinned REST clauses, py's 2xx guard, crate existence/MSRV snapshots, and the logged package deltas. It does not support the unconditional concurrency, dry-run, routing, retryability, and execution assertions detailed in F1 and F3-F7. |
| JF-5 — Ownership of couplings | fail | F5 fixes R75 relationships that the prompt reserves for that item. The remaining handoffs substantially preserve ownership: R70 supplies problem bodies, R71 documents the contract, R74's proposed placement is expressly left to R74, and R77 owns setting names (`:966-1027`). |
| JF-6 — Live assumption bytes | pass | Independently compared all four `- assumes` values at `DECISION.md:523-526` with `docs/port/PARAMETERS.md:7-10`: byte-identical `msrv-policy`, `rust-edition`, `target-os-matrix`, and `license`. No owned parameter is invented. |
| JF-7 — Prerequisite values | pass | Published R01, R67, and R69 were consulted, along with the accepted R02/R03 run decisions and R05's accepted direction/current run text. R02 revision 2 hashes to `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f`, matching `OWNER-ACCEPTANCES.md:71`. R69's accepted revision 10 hashes to `d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a`, matching line 60. Its optional `crates/web` shape and versions match R73. R73 expressly distinguishes that accepted value from the still-published revision 9 and requests rebinding; this pass does not certify publication readiness. F2 concerns an unprovided bridge, not a silently changed accepted parameter. |
| JF-8 — Evidence artifacts and counts | fail | All six cited shell scripts and corresponding logs exist. Independently counted PASS rows: standard 45, probe 27, sources 23, registry 17, Muse/currency 46, shape 41; zero FAIL/SKIP rows. The first five sum to 158. The shape log at line 6 binds the exact audited hash. Nevertheless, the nine-versus-ten store count and claimed numeric eviction experiment fail the requested count/evidence check (F7). |
| JF-9 — Published decision shape | pass | RUNBOOK lines 197-206 require the four H2 sections found at decision lines 39, 521, 581, and 758. `### Principles and implementation` is at line 78; one `re-verify:` line is at 519. OV-16 has Argument/Options, fixed assumptions are present, and no reversal is asserted that would require `## Supersedes`. Raw-report member headings are not imposed on a synthesized decision. The 41/41 log is corroborating structural evidence, not proof of semantic correctness. |
| JF-10 — Recommendation follows evidence | fail | A small axum-native layer, explicit 2xx policy, SHA-256 fingerprint, and bounded local adapter have substantial supporting evidence. Approval of the specified protocol and no-rewrite swap promise does not follow while F1/F2 remain unresolved. F3 weakens the alternative comparison; F4 leaves a real-mutation bypass. Repair the reasoning and state contract before accepting this revision. |

**Scope and evidence boundaries**

All `inputs/`, `raw/`, and `review/` paths above are relative to `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/`. Short `probe/` and `r73-*.log` references are under that run's `review/evidence/` directory. Other repository paths are relative to the working root `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.

The first tool action was `shasum -a 256` on the target. It matched the required digest. A second `shasum` immediately before writing this report matched again. I read the frozen prompt, RUNBOOK, revision-3 decision, pinned Opus/Muse reports, all three normalized Doxa provider reports, relevant prerequisites, evidence scripts/logs, and the cited probe sources. The Doxa normalization record identifies the three provider bodies as lossless; the combined raw report's hash was independently checked.

The raw-report hashes checked were: Opus `a909a140a6d5664c04c0d5f996cd4b76e6f367d9520c4cac30d8fd44e38527ba`; Doxa `da3903244093c9be53f29d426ac20f6b9de835f67b5d47f5ee57b0ee3d7dc6f4`; Muse `aca328034d31b0280241da56ec8f603e21c3230a299023dc00d0b9bac2870536`. This verifies which reports were judged; it does not endorse their claims.

Source-repository spot checks were read-only `git show` operations: Python `src/py_launch_blueprint/web/idempotency.py` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, especially lines 26-30 and 97-149; TypeScript `package.json` at `cb1cbcb2`, alongside the source inventory in `docs/port/areas/web-service.md`. These substantiate the Python behavior and TypeScript's lack of a matching web-service implementation. The pinned REST standard was read directly from its named commit, including corrected `dry_run` reservation line 338. R02's B1/B2 references resolve at its decision lines 78 and 251. The Gemini, R02, and reservation-locator repairs in revision 3 are accepted as repairs.

No evidence script, build, test suite, research-runner command, paid operation, or submitting API was executed. No git write occurred. No `review/audit-*.md` or `review/Rxx-r*-snapshot.md` was opened. References to those files inside permitted decisions/logs were not followed, and their findings or snapshot-equality claims were not used as independent evidence. This report is the only file written.

Public-query limitations: some docs.rs Router page/open/find requests returned `Internal Error`. The MethodRouter documentation succeeded, and the relevant axum 0.8.9 source files were subsequently fetched read-only from the project's exact release tag. The configured private Cargo home contained no axum 0.8.9 source to inspect. No failed retrieval is counted as supporting evidence.

Model identity limitation: the session identifies this auditor as GPT-6 in the OpenAI family. A more specific resolved runtime variant is not exposed by the available session metadata; no narrower model ID is asserted.
