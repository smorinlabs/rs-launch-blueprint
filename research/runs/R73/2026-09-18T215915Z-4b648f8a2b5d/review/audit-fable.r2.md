actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 842d48f67a140cb46b9909ac5e09de729fd267660bdf4f106aaa82ac2d99915e
verdict: reject
unresolved-findings:
  1. JF-3 — Gemini's concurrency position misrepresented in `## Engines`
  2. JF-7/JF-4 — stale sibling pin: "R02 revision 1" where the accepted revision is 2
  3. JF-4 — wrong line locator for the §1.10 `dry_run` reservation (`:335`)

# R73 idempotency-middleware — judgment audit of revision 2

Target: `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md`. The
sha256 was recomputed with `shasum -a 256` before any other step. It matches the
expected `842d48f6…915e`.

Scope: this audit judges reasoning and fidelity. The separate empirical audit
re-executes the scripts. This auditor read the decision, `inputs/prompt.md`,
`research/RUNBOOK.md` §5, the raw reports under `raw/`, the evidence scripts and
logs (spot-checked, not rerun), and the prerequisite and sibling decisions cited.
No `review/audit-*.md` file of any seat or revision and no
`review/R73-r1-snapshot.md` was opened. This audit is blind to the revision-1
audits.

**The recommendation stands.** `idempotency-replay/v1` follows from the evidence:
a `from_fn_with_state` layer over a compare-and-set `IdempotencyStore` port, a
`std`-only in-memory adapter, and `sha2` 0.11.0. None of the three findings
touches the design. Each repair is text-only, and none needs a new provider run
or a new probe.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass** | Probe totals agree everywhere: 28 behavioural checks = 10 store (`s01`–`s10`) + 18 web (`w01`–`w17`, `w09b`). The five evidence logs are 45 + 27 + 23 + 17 + 46 = 158, as `## Empirical check` states. Every `P6-*` delta in the prose matches the executed-results table. The one inconsistency found, a convergence count, is reported under JF-3. |
| JF-2 prompt coverage | **pass** | HIGH-1: answered as "one crate exists (`cratestack-axum`) and two gates exclude it", so the template hand-rolls a layer over a store trait. HIGH-2: the 2xx predicate is explicit and tested by `w02` and `w13`. MEDIUM store type: `Mutex<HashMap>` with LRU eviction and lazy TTL, weighed against moka, mini-moka, quick_cache, lru and hashlink at measured tree cost. MEDIUM key: `(method, path, query, key)` with the fingerprint stored beside the key. LOW: answered explicitly with Zero To Production and a stated evidence gap. Constraints: edition 2024, the 1.96 MSRV floor, and the OS matrix are applied. The macOS-only execution is disclosed as a gap. Gate 1 is recorded as `inapplicable` under Q7.B. |
| JF-3 engine fidelity | **fail** | Finding 1. All other engine characterisations spot-checked hold. Muse lines 15, 21, 23, 25, 87, 140, 160, 185, 209, 217, 287 and 291 say what the decision says they say. Opus's "No published Rust crate…" (across its line breaks), the *Medium* hedge at `:551-553`, `:24`, `:41` and `:1081` hold. Perplexity has no `409` and no in-flight state; its `get` / `insert_success` / `mark_conflict` design is at `:49`. Gemini has no payload fingerprint (`:25`), and its "prevents payload collisions" line is at `:110`. |
| JF-4 claims trace to sources | **fail** | Findings 2 and 3. The following spot-checks pass. All quoted standard lines read back from blob `71bd813c` at commit `0850d43e`: 229, 271, 312, 318, 347, 651–655, 668–677, 728, 868, 880, 916, 934, 939–942, 967, 1020, 1049, 1076, 1098, 1743 and 1752. Stripe's "regardless of whether it succeeds or fails", the execution gate, the 255-character limit and the 24-hour retention all appear in `snapshots/stripe-idempotent.extract.txt`. The draft's `:262`, `:311` and `:342` are verified. F314's Notes text is at `docs/port/areas/web-service.md:20`, and `COMMONALITY.md:317-319` carries no Stripe text. Ledger lines 1114, 1121, 1160 and 1215 carry Q5.A, Q9.B, the R73 Muse collection and Q17.A. `R67 DECISION.md:683-689` and `RUNBOOK.md:18-22` are verified as cited. |
| JF-5 couplings hand over owned choices | **pass** | R75's six items are labelled constraints with reasons, and P03 validates the final position "once R75 fixes the ordering". R74's item is "proposed, not fixed". R77 receives names only. R71 and R76 receive the contract duties the standard imposes (R4.17). R70 is asked for nothing. |
| JF-6 `assumes` byte-identical | **pass** | The four `- assumes` values match `docs/port/PARAMETERS.md:7-10` exactly. `D3-params` agrees. The decision names the one registry row that drifted in the snapshot, `ci-job-structure` (R11). Diffing `inputs/PARAMETERS.md` against the live registry confirms it is the only difference. |
| JF-7 no conflict with prerequisite values | **pass, with a re-pin** | R69: prerequisite pin `d4507f5b` is today's `research/topics/69-…/DECISION.md` (revision 9). Revision 10 (`d34ab6e8`) is owner-accepted by re-bind (`OWNER-ACCEPTANCES.md:60`). Line 1791 carries the `crates/web` value with tokio 1.53.1 and tower as a dev-dependency only, and controller request 5 discloses the re-bind. R70: the revision-3 snapshot sha `802e5292…` resolves, `:36`, `:134` and `:497` match, and live revision 4 still carries M-1 and the R73 hand-over at `:550`. R01: the seam value in `PARAMETERS.md:11` matches the port's stated shape. R03: rule 1 is scoped to reads in its own Ranked runner-up at `:72-81`, and `Unavailable` maps to `RSLB101` at `:69`. R05 accepted revision 3: its `spawn_blocking` bridge is scoped to R01's driven-I/O port. R73 argues the inline call to a sub-microsecond in-memory adapter explicitly and sends I/O adapters through `spawn_blocking`, so this is an argued position, not a conflict. R02: see finding 2. |
| JF-8 evidence scripts and counts | **pass** | All six scripts and logs are present. The logs read 45/45, 27/27, 23/23, 17/17, 46/46 and, for shape, 33/33, with 0 fail and 0 skip. `M2-minco`, `M1-no-concurrency`, `M1-missed`, `M1-sha2-default` and `C1-R1.9` were spot-read. OV-16 is the controller's allocation to R73 (`execution-ledger.md:1074`, `:1078`). R79's single mention of OV-16 only quotes the allocation table. |
| JF-9 decision shape | **pass** | H1 is date-first. The four H2s appear in RUNBOOK §5 order, with no `## Supersedes` because nothing is reversed. `### Principles and implementation` is present, as is exactly one `re-verify:` line. OV-16 carries **Argument:** and **Options:**. |
| JF-10 recommendation follows | **pass** | Measured tree costs are +8 against +37 for `axum-idempotent` and +14 for moka. `cratestack-axum` is excluded by gate 2 (`rust-version` 1.98.0 against the 1.96 floor) and independently on fit. The compare-and-set contract is the only store shape reviewed that closes py's documented single-flight gap. The 2xx-only rule is re-grounded honestly on the layer's lack of an execution-started signal, not on Stripe. |

## Findings

### 1. JF-3 — Gemini's concurrency position is misrepresented

**Failed claim** (`DECISION.md:924-927`): "Where the legs converge is worth
recording too: … and — in the two legs that address concurrency at all, Opus and
OpenAI — an atomic reserve-or-conflict primitive returning 409."

**Evidence.** The Gemini provider addresses concurrency and proposes exactly that
primitive. `raw/doxa-gemini.normalized.md:23` reads: "The Rust template must
define an `IdempotencyStore` trait that mandates an atomic `try_acquire_lock`
method. This method must atomically return either an `Acquired` token if the key
is new, or a `Conflict` response (typically yielding an HTTP 409) if a request
tied to that key is currently in flight". `:109` plans the matching check:
"all simultaneous requests immediately receive an `HTTP 409 Conflict`". The same
error propagates to the revision table at `DECISION.md:13`. That row claims
"every count now covers five reports", but this convergence count omits a leg.
The error does not move the recommendation, and correcting it strengthens the
convergence. It is still a false statement of an engine's position, which JF-3
does not permit.

**Repair.** Say "the three legs that address concurrency — Opus, OpenAI and
Gemini" and cite `raw/doxa-gemini.normalized.md:23,109`. Keep the separate, true
charge that Gemini has no payload fingerprint (`:25`, `:110`). Optionally add a
check, such as an `M1`-style `grep` for `try_acquire_lock` in the Gemini twin,
so the count is asserted rather than stated.

### 2. JF-7/JF-4 — "R02 revision 1" is a stale pin; the accepted revision is 2

**Failed claim.** `DECISION.md:382` has "R02 revision 1's four-package workspace
places the port in `crates/core`…". `:418` has "C13's single-crate layout —
**differ**, on R02 revision 1's ground". `:450`, criterion 19, has "*Proposed* —
R02 revision 1 executed the equivalent (`B1`/`B2`)". The re-verify line says
"R02 … publishing a decision differing from the accepted revisions this is
written against".

**Evidence.** `docs/port/OWNER-ACCEPTANCES.md:71` records R02 as accepted at
**revision 2**, `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f`,
re-bound 2026-09-18 as an evidence-only revision. The current file
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` is headed
"(revision 2)". The substance holds at revision 2: the four-package workspace is
at `:22-27`, and `B1`/`B2` are at `:78` and `:251`. No R73 check pins an R02 sha.
The acceptance moved nine days before this revision was written, so this is
controller note (b)'s re-pin case. It is not a moving-sibling byte-identity
demand.

**Repair.** Re-cite all three sites as "R02 revision 2 (`9e8f8e8c…`, accepted)".
Optionally add a `K`-style check asserting that sha and the `B1`/`B2` row.

### 3. JF-4 — the §1.10 `dry_run` locator points at the wrong line

**Failed claim** (`DECISION.md:118`, the R3.12.4 row): "the reserved `dry_run`
parameter (§1.10, `:335`; R1.9 at `:318`)". The paragraph introducing the table
(`:84-86`) says "Every rule below was read at its line out of that blob and
asserted by a check that fails if the line moves".

**Evidence.** In blob `71bd813c`, line 335 is the `fields` (sparse fieldsets)
row. The §1.10 `dry_run` row is line **338**. No `C*` check asserts `:335` or
`:338`. `C1-R1.9` asserts `:318` only, which is correct.

**Repair.** Change `:335` to `:338`. Either add a `quote` check for line 338
carrying "`dry_run` | Rehearse a mutation", or narrow the "every rule … asserted"
sentence so it excludes section locators.

## Observations (not findings)

- **Muse leg registration** (controller note a). `operations/muse.json` reads
  `state: submitting`, `raw/muse.md` is untracked, and the manifest predates
  migration. This is expected on this item. The decision discloses it and files
  controller request 4. The adjudication prose was judged, not the manifest.
- **`minco-plugin-idempotency`** is checked (`M2-minco`, 870 all-time downloads)
  but is not named in the decision prose. Opus (`raw/opus.md:421`) and Muse
  (`raw/muse.md:59`) agree that it is a framework-locked plugin, so there is no
  disagreement to adjudicate.
- **2xx-only rule under R3.9.** The layer cannot tell a 5xx whose side effect
  committed from one whose side effect did not. The decision states this cost
  (A1, "cannot see whether the handler's side effect committed"). It rests
  conformance on R5.1, where non-2xx means failed, and on R11.6, which requires
  documented retryable classes. The argument is explicit and defensible. It is
  recorded here so that the owner sees it next to OV-16.
- **`sha2` adopter evidence** (the prompt's Adopters row) lives in
  `raw/opus.md:928`, not in the decision. The RUNBOOK §5 decision contract does
  not require restating it.
- The Muse raw dates its figures 2026-09-25, and the ledger records collection on
  2026-09-23. The decision discloses the discrepancy and leaves it to the
  controller, which is correct.
