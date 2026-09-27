actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 437ad0c97631f53435b1c17e4d6c898d965eb41cb25c51ce862a94c02237d35e
verdict: reject
unresolved-findings:
  1. F1 (JF-3, JF-2) — `## Engines` misstates the item's current engine set and cannot represent the Muse leg
  2. F2 (JF-4, JF-7) — R11 citations point at revision 1 lines that revision 7 no longer carries; one cited rationale no longer exists
  3. F3 (JF-5) — the CI migration row decides a choice R11 revision 7 hands to R32
  4. F4 (JF-4, JF-7, minor) — stale prerequisite citations and a stale registry-identity sentence (R70 revision, R72 publication, PARAMETERS.md byte-identity)
  5. F5 (JF-1, JF-8, minor) — the named SKIP range for the no-clone path disagrees with the script

# R83 openapi-contract-fuzzing — judgment audit of DECISION.md revision 1

Auditor: fable, fresh Claude context, model `claude-opus-5-5`, family anthropic.
I produced none of this item's raw reports, evidence or synthesis. Audit date: 2026-09-26.

## Scope and method

- **Target.** `research/runs/R83/2026-09-17T034011Z-2af391428997/review/DECISION.md`.
  I recomputed its sha256 before reading anything else. It is
  `437ad0c97631f53435b1c17e4d6c898d965eb41cb25c51ce862a94c02237d35e`, which equals the expected
  hash.
- **Inputs read.**
  - the run's `inputs/prompt.md`, sha256 `ab853b01…`, identical to the topic prompt;
  - `research/RUNBOOK.md` §2 and §5;
  - `raw/opus.md`, sha256 `5c8efd3c…`, pinned in `manifest.json`;
  - `raw/muse.md`, sha256 `dbd36128…`, untracked and not pinned (see F1);
  - `manifest.json` and `operations/*.json`;
  - the prerequisite decisions: R69 revisions 9 and 10, R11 revision 7 (topic and run tree),
    R72 revision 5 (topic), R70 revision 3 (run tree), R02 revision 2, R33, R20 and R42;
  - `docs/port/PARAMETERS.md` and `docs/port/COMMONALITY.md`;
  - `docs/planning/p02/owner-decisions.md` and `docs/planning/p02/execution-ledger.md`.
- **Not read.** I read no `review/audit-*.md` file and no `review/Rxx-r*-snapshot.md` file.
- **Primary-source spot-checks.**
  - py-launch-blueprint at `b08bccfb…`: `tests/web/test_contract.py:1-30`,
    `pyproject.toml:277-278` and `Justfile:300-301`.
  - The `rest-standards` blob `71bd813c…` at the nine cited lines, plus a rerun of `B13`'s
    rule count.
  - The published `oas3-0.22.0.crate`, fetched read-only into `/tmp`.
  - The two evidence logs and the fixture's line count.
- **Not done.** I did not rerun the scripts; that is the empirical audit's job. I made no git
  writes, ran no runner commands and called no paid APIs.

**Observation for the controller (not a finding).** The committed "revision 1" at `b1ac6d57` has a
different sha256 from the audited file: `3e62d6e4…` versus `437ad0c9…`. The audited bytes are the
staged edit. Two different contents therefore carry the label "revision 1". Acceptance binds to the
hash, so this does not affect the verdict. The controller should still give the next revision a
unique label.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass**, with one minor nit (F5) | The recommendation is consistent across sections: `oas3 = "0.22.0"` as a dev-dependency, `proptest`, and in-process `oneshot`. "No runtime dependency is added" is reconciled with the observation that `tower` is already in the normal graph through `axum` (`A21`, `A22`). The migration table matches the design table. The A2 line count of 482 matches `contract-fuzz-probe/tests/contract_fuzz.rs` (482 lines). |
| JF-2 prompt answered, constraints honored | **fail** → F1 | Every question is answered: the Decision question, the three HIGH questions, the two MEDIUM questions (default checks and discovery) and the LOW question (maturity). Gate 1 is stated as `inapplicable` with the Q7.B reason, as the prompt requires. The ubuntu leg is honestly labelled an inference. **However**, the current prompt says `- engines: muse, opus` and "its mirrored `- engines:` line is authoritative". The decision still describes a Codex-plus-Opus item. |
| JF-3 engines represented and disagreements adjudicated | **fail** → F1 | The Opus report is faithfully represented, and six corrections to it are recorded with evidence. The Muse report on disk is neither represented nor adjudicated, and the Engines text is false against `manifest.json`. |
| JF-4 load-bearing claims trace to sources | **fail** → F2, F4 | See the spot-check list below. The failures are the stale R11 lines (`:173`, `:104`) and the R70 revision number. |
| JF-5 couplings handed off, not decided | **fail** → F3 | R71 is conditioned on its plausible outcomes. R32 owns the exclusion mechanism, R70 the envelope, and R84 only shares the document. The exception is the CI migration row, which decides R32's job-versus-step slot. |
| JF-6 assumes lines byte-identical to the live registry | **pass** | I compared exact cells from the live `docs/port/PARAMETERS.md`. `msrv-policy`, `rust-edition`, `target-os-matrix`, `license` and `web-extra-surface` are all EXACT. The set is the four fixed rows plus the prompt's single `consumes: R69: web-extra-surface`, and the item owns nothing. |
| JF-7 no conflict with accepted or published prerequisites | **pass on substance, citations stale** → F2, F4 | No published value contradicts the recommendation. R69's registry row is still revision 9, and the decision records revision 10 as a pending publication rather than a `CONFLICT:`. R33 publishes `proptest` 1.11.0. The R42 quote is a substring of the live `package-manager-invocation` value. R20's `enforced-owner-prefix-pinning` exists. R72 revision 5 (`cursor`/`limit`, `1..=100`) and R11 revision 7 are both consistent with the design. |
| JF-8 evidence scripts exist and counts match | **pass**, with one minor nit (F5) | Both scripts and all three logs exist. The totals match: `PASS=24 FAIL=0 SKIP=0 TOTAL=24` with 24 `PASS` lines A0–A22, and `PASS=29 … TOTAL=29` with 29 `PASS` lines. `clean-extraction.log` shows 24 and 29. The cited figures appear in the logs (next table). |
| JF-9 decision shape | **pass** | The decision has the four RUNBOOK §5 H2s: `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`. `## Supersedes` is correctly absent because nothing is reversed. `### Principles and implementation`, the settled row F334 (`COMMONALITY.md:338`, verified), and a `re-verify:` line are all present. |
| JF-10 recommendation follows from the evidence | **pass**, conditional on F1's adjudication | The evidence supports this chain: no `schemathesis` equivalent exists (`B1`/`B2`); `openapi-fuzzer` fails gate 2 (`B3`–`B5`, `B23`); `openapiv3` declares no `rust-version` (`B27`); `oas3` supports 3.1, which R4.1 requires (`A16`–`A18`); boundary bias is necessary (`A13`–`A15`). Together these support the in-repository `oas3` + `proptest` harness. The runner-up and its win conditions are stated. |

### Spot-check results

**py-launch-blueprint at `b08bccfb…`**

- `test_contract.py` is verbatim as described. It uses `from_asgi("/openapi.json", …)`,
  `@pytest.mark.slow`, `max_examples=10` and `not_a_server_error`. Its scope note says response
  conformance is deferred.
- `pyproject.toml:277-278` contains `addopts = "-m 'not live and not slow'"`.
- `Justfile:300-301` contains `test-web`.

**`rest-standards` blob `71bd813c…`**

- All nine rules sit at their cited lines: R1.5 `:210`, R1.7 `:271`, R4.1 `:742`, R4.2 `:754`,
  R4.3 `:762`, R5.1 `:916`, R5.2 `:934`, R5.12 `:1019` and R5.13 `:1049`.
- `B13`'s own pattern `^\*\*R[0-9]` counts **145** on the blob, confirming the decision's figure.

**`oas3-0.22.0.crate`**

- `src/spec/mod.rs:75` is `OPENAPI_SUPPORTED_VERSION_RANGE: &str = "~3.1"`.
- `:205` is `pub fn operations(&self) -> impl Iterator<Item = (String, Method, &Operation)>`.
- `src/spec/schema.rs:594` is `pub fn resolve`.
- `Cargo.toml` declares `rust-version = "1.87"` and `license = "MIT"`.

**Evidence logs**

- `contract-fuzz-probe.log:18` has `projects-create: 16 cases, no finding` on the seeded-500 leg
  with bias removed (`A13`).
- `:13`–`14` have `20/20` versus `2/20`.
- `:42` has the minimized `limit: 0` request.
- `:159`–`160` have 60 and 141 packages.
- `registry-and-standard.log:6` and `:8` have `meta.total=0` and `107`.
- `:20`–`21` show `openapiv3` `2.2.0` with `rust_version=None` (`B27`).

**Ledger and owner rulings**

- `COMMONALITY.md:307` is F303, as cited.
- W1-CODEX3 is recorded at `owner-decisions.md:488` and `execution-ledger.md:1000`.
- Q7.B is recorded at `owner-decisions.md:157`.
- R02 revision 2 `:128` carries the `B3` sentence.
- R69 revision 10 `:1791` carries `crates/web/tests/`, `crates/web/**` and `rs-launch-blueprint-web`.

## Findings

### F1 (JF-3, JF-2) — `## Engines` misstates the item's engine set and does not represent the Muse leg

**Failed claim.** Lines 445–453:

> "The Codex leg is absent by the controller's deferral, not by omission. This is a Focused-tier item
> whose `required_engines` are `["codex", "opus"]` and whose `manifest.json` `state` is therefore
> `partial`."

and

> "With one engine there is no second lens and therefore no engine disagreement to settle."

**Evidence.**

- **Manifest.** `manifest.json` records a 2026-09-21T23:06:21Z migration event. It is `from: codex`,
  `to: muse`, with reason "muse bulk substitution (owner decision Q5.A 2026-09-21)". The current
  `required_engines` are `["muse", "opus"]`. `operations.muse` has request_id `2c70e838…` and is in
  state `submitting`.
- **Prompt.** `inputs/prompt.md`, which is identical to the topic prompt, now reads
  `- engines: muse, opus`. It adds "This item substitutes Muse (Meta) for Codex under the
  `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
- **RUNBOOK.** §2 lists R83 in the Muse bulk set.
- **Muse report on disk.** `raw/muse.md` (sha256 `dbd36128…`, dated 2026-09-25) is on disk but
  untracked and not pinned in the manifest. It disagrees with the decision on five load-bearing
  points:
  1. **Parser.** Muse names `openapiv3` "2" and treats gate 2 as "pass with gap", on the ground
     that its MSRV is inferred from a serde-only tree. The decision uses `oas3` and fails
     `openapiv3` on gate 2 (`B27`).
  2. **Transport.** Muse uses `reqwest::blocking` against a started or CI-hosted service. The
     decision uses an in-process `tower::ServiceExt::oneshot`.
  3. **Discovery.** Muse reads the committed R71 snapshot. The decision fetches the served
     document.
  4. **Named crate.** Muse names `proptest` `>=1.9,<2` as the item's crate. The decision names
     `oas3 = "0.22.0"`.
  5. **Exclusion ground for `openapi-fuzzer`.** Muse excludes it on gate 1 (AGPL-3.0). Owner
     ruling Q7.B makes gate 1 inapplicable, so the valid ground is gate 2. The outcome is the
     same; the reason differs.

  Muse also proposes a fast-tier-tested library module
  (`src/test_support/openapi_strategies.rs`), which the decision does not consider.

**Status of the finding.** The Muse leg postdates the decision and is still uncollected. This is
drift, not synthesis negligence. It still blocks acceptance: RUNBOOK §5 requires `## Engines` to
cover "all reports … disagreements, and the evidence that resolved each disagreement", and the
current prompt names Muse as a required engine.

**Repair.**

1. **Controller.** Collect the Muse operation (request `2c70e838…`) and pin `raw/muse.md` in the
   manifest. This is the controller's step; the auditor is forbidden to run it.
2. **Revision 2 rewrites `## Engines`:**
   - Replace the Codex-deferral paragraph with the 2026-09-21 migration and Q5.A.
   - Represent the Muse report's positions.
   - Adjudicate each of the five disagreements above with evidence. Much of that evidence
     already exists: `B27` against the literal "declared as rust-version" wording of gate 2;
     `A16`–`A18` on 3.1; the in-process rationale and acceptance criterion 6 against a listening
     service; the served-versus-committed paragraph under "Schema discovery"; Q7.B for gate 1.
   - Address Muse's fast-tier strategy-module proposal.
   - Correct "With one engine there is no second lens".
3. **Judgment.** None of this obviously overturns the recommendation. The revision must still
   decide it, not the auditor.

### F2 (JF-4, JF-7) — R11 citations point at revision 1 lines that revision 7 no longer carries

**Failed claim.** Line 230, the CI workflow row:

> "R11's own placement rule decides this: 'a check that compiles what `check` already compiles is
> an ordered step of `check`' (`research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/DECISION.md:173`)
> … gated on the `code` output rather than `web` — R11 spends the `web` key on the purely-web jobs,
> 'R71's and R84's OpenAPI and typed-client drift slots', and deliberately not on the compile tier
> (`:104`)"

Related: the Engines correction (1) at lines 472–476 ("R11 **revision 1** now exists…").

**Evidence.**

- The cited run-tree file is now **revision 7** (header: "2026-09-23 — R11 … decision
  (revision 7)"). It is also published at `research/topics/11-ci-workflow-job-structure/DECISION.md`,
  and the live registry row `ci-job-structure` carries its value.
- `:173` is now the F038/F040 ledger paragraph.
- The placement rule now sits at `:278` and reads "…is an ordered step of `check`, under
  `!cancelled()`".
- The `:104` sentence no longer exists. Revision 7 states instead "`web` now equals `code`"
  (`:202`), and its slot table (`:293`) says `openapi-snap` is "gated on `web == 'true'`, which is
  now set by every code change".
- The decision's own re-verify trigger, "R11 revision 1 publishing or changing its `check` job's
  step list", has therefore fired.

**Repair.**

- Re-cite R11 revision 7 at its published path and current lines, with the full rule text
  including `under !cancelled()`.
- Drop the `:104` "not on the compile tier" rationale. Replace it with revision 7's
  `web`-equals-`code` statement, or remove the code-versus-web contrast.
- Update Engines correction (1) to say revision 7.
- The conclusion itself (the suite compiles what `check` compiles) still follows from `:278`.

### F3 (JF-5) — the CI migration row decides a choice R11 hands to R32

**Failed claim.** Line 230:

> "CI workflow | **one ordered step of R11 revision 1's tier-2 `check` job**, after that job's
> feature-on `cargo test` step."

This is stated as a file-level change R83 makes.

**Evidence.** R11 revision 7's slot table (`:282`) assigns R32 "the tier names inside `check`'s test
steps, and **whether a slow tier earns its own job**". It adds the default rule "a tier becomes its
own job only if it needs a different toolchain, a different runner, or a `target/` it must not share;
otherwise it is an ordered step of `check`." The prompt's Out of scope section also gives R32 the
test-tiering mechanism. The decision correctly hands R32 the exclusion mechanism (line 165 and the
R32 coupling bullet). It then fixes the job-versus-step placement of that same excluded tier itself.

**Repair.** Restate the CI row as a requirement:

- the suite runs on both `target-os-matrix` legs;
- it needs the same toolchain, runner and `target/` as `check`, so under R11 revision 7's `:282`
  default it lands as an ordered step of `check`;
- R32 decides whether the slow tier earns its own job.

Add this to the R32 coupling bullet, and make "R32 naming the placement" part of the existing R32
re-verify trigger.

### F4 (JF-4, JF-7, minor) — stale prerequisite citations and a stale registry-identity sentence

**Failed claims.**

- **(a)** Line 138 and Engines correction (6) cite R70 "revision 2" in its run tree.
- **(b)** Lines 257–259 and the re-verify line treat R72 as unpublished. They list "R72
  publishing" as a pending trigger.
- **(c)** Lines 326–328 say "`research/runs/R83/…/inputs/PARAMETERS.md` is byte-identical to
  `docs/port/PARAMETERS.md` (`diff` empty…)".

**Evidence.**

- **(a)** The R70 run tree is now **revision 3** (header dated 2026-09-27). Its content still
  supports the claim. `:84`–`:92` render every non-2xx as problem+json with `type`, `title`,
  `status`, `code` and `catalog_code`: domain failures, router misses, extractor rejections and
  panics alike. The only R5.12 carve-out is upstream infrastructure (`:359`–`:361`), which is
  outside the in-process harness.
- **(b)** R72 revision 5 is at `research/topics/72-api-pagination/DECISION.md`, and the index row
  reads `resolved`. Its contract is `cursor`/`limit`, `1..=100`, with `limit=0` and `limit=101`
  rejected with `422` (`:154`–`:156`). This is consistent with the decision.
- **(c)** `diff` of the two files is now non-empty, because the live registry gained R11's
  `ci-job-structure` value. JF-6 is unaffected: all five `assumes` cells still match exactly.

**Repair.**

- Cite R70 revision 3.
- Record R72 revision 5 as published and mark its trigger fired. The query-parameter requirement
  for P03 is unchanged, and the minimum/maximum boundary generation should now target `1` and
  `100`.
- Reword the byte-identity sentence to the current truth: the run snapshot differs only in a row
  this item does not consume, and the five `assumes` lines equal the live cells.

### F5 (JF-1, JF-8, minor) — the named SKIP range disagrees with the script

**Failed claim.** Lines 371–372: the registry script skips "`B11..B27` when no clone of
`rest-standards` exists at the pinned path".

**Evidence.**

- `registry-and-standard.sh:122` names the skip as `'B11..B22 (every standard quote and the
  Spectral cross-check)'`. It does not name `B25` or `B26`, which that same path also skips.
- `B27` is in the crates.io block, which is skipped with `B1..B9`.
- `B23` and `B24` are the `gh` checks, which the decision lists separately.

The claim "Every `SKIP` path is named rather than silent" is therefore slightly inaccurate for
`B25` and `B26`.

**Repair.**

- Change the decision text to "`B11..B22`, `B25`, `B26` when no clone … exists".
- Add `B27` to the crates.io-unreachable skip.
- Make the script's skip label at `:122` name `B25` and `B26`.

## Verdict

**reject.** On substance the recommendation is well evidenced:

- In-repository `oas3 = "0.22.0"` + `proptest` + `oneshot` as dev-dependencies of `crates/web`.
- The primary sources I spot-checked reproduce.
- The assumes lines match the live registry.

Acceptance is blocked by three findings:

- **F1.** The item's current required engine set is Muse + Opus, and a Muse report with material
  disagreements exists but is neither collected nor adjudicated.
- **F2.** The R11 citations are stale and one cited rationale no longer exists.
- **F3.** The CI row decides a slot R11 hands to R32.

F4 and F5 are minor and should be folded into the same revision.
