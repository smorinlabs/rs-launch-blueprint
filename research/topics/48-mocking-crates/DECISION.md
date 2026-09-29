# 2026-09-17 — R48 — mocking-crates (bundle, Focused) — decision (revision 6)

**Revision note, revision 6.** Revision 6 answers the judgment audit of revision 5
(`review/audit-fable.r5.md`, verdict `reject`, finding JF-R5-1) and is **prose-only**.
The round's empirical audit (`review/audit-claude.r5.md`, verdict `approve`, no findings)
reran all five scripts green against their committed logs, with every stable line
reproducing byte-for-byte; every script and log is carried forward **byte-identical**, and
no cited script line or log line moved. Revision 6 moves no member, no version, no manifest
shape, no gate disposition, no maintenance verdict and no parameter value; it gathers no new
evidence about any crate's fitness.

| Finding | Disposition in this revision |
|---|---|
| **JF-R5-1** (blocking; JF-3, engine fidelity) — the two engines' `mockall` issue-responsiveness figures disagree (codex: median 4.98 days, 1 of 10 unanswered, `state=open`, 2026-09-16, `raw/codex.md:93`; opus: median 1.18 days, 0 of 10 unanswered, `state=all`, 2026-09-17, `raw/opus.md:660-663`), yet revision 5 showed only opus's figure and said the engines' shared figures "agree" | **Accepted; the audit is right.** Under **`## Engines` → Evidence the two engines did not both collect**, codex's figure is now stated beside opus's with each engine's endpoint, and the disagreement is adjudicated: the prompt's rubric is the "10 most recently opened issues" (`inputs/prompt.md:55`), which opus's `state=all` sample implements and codex's `state=open` sample does not, so the maintenance paragraph keeps opus's figure; `mockall` is `active` under either figure. Revision 5's sentence "Where the two report the same figure from the same endpoint on different days (2026-09-16 and 2026-09-17), the figures agree" is superseded and rescoped to the registry and repository-metadata figures. The maintenance paragraph gains one pointer sentence to the adjudication, and the `## Engines` introduction now says that one further disagreement sits outside the numbered items. No script, log, member, version or gate disposition changes. |

**Revision note, revision 5.** Revision 5 answers the judgment audit of revision 4
(`review/audit-fable.r3.md`, verdict `reject`, finding JF-R4-1) and is **prose-only**.
The round's empirical audit (`review/audit-claude.r3.md`, verdict `approve`, no findings)
reran all five scripts green against their committed logs; every script and log is carried
forward **byte-identical**. It moves no member, no version, no manifest shape, no gate
disposition and no parameter value; it gathers no new evidence about any crate's fitness.

| Finding | Disposition in this revision |
|---|---|
| **JF-R4-1** (blocking) — revision 4's H02 claim (the repository commits no `Cargo.lock`) carries no endpoint and no retrieval date in the decision, violating "Every claim carries a source URL and retrieval date; every number carries its endpoint" and falsifying the Sources completeness sentence (rev-4 line 458) and the check-table date header (rev-4 line 630) | **Accepted; the audit is right on provenance.** Under **Sources → GitHub**, the `repos/contentauth/c2pa-rs/git/trees/main?recursive=1` endpoint is listed for the `truncated` flag and the `Cargo.lock` path count *(check H02)*, retrieved 2026-09-26, and the Adopters entry dates H01's `sdk/Cargo.toml` re-fetch to 2026-09-26. The C-check table header is qualified to "(retrieved 2026-09-17; H-check facts 2026-09-26)" and H01–H03 gain their own endpoint table dated 2026-09-26, as C, D and E have. Line 458's universal stands, now true. |

**Revision note, revision 4.** Revision 4 answers the round-3 empirical audit
(`review/audit-codex.md`, verdict `reject`, finding E-1) and carries one invited
tidy from the round-3 judgment audit (`review/audit-fable.md`, verdict `approve`,
no findings). It moves no member, no version, no manifest shape, no gate
disposition and no parameter value; it gathers no new evidence about any crate's
fitness. The finding is the same kind of mistake as JF-9 — a script's `PASS` line
claims more than the script asserts, and the prose repeated it — and it is repaired
the same way: the committed script and log stay byte-identical, a new check asserts
the narrowed claim directly, and the old wording is marked superseded where it
appears. The round-3 empirical auditor's own treatment of the JF-9 erratum —
reproducing the old D01 line exactly but not using it as proof, because revision 3
marks it superseded — is the precedent this revision follows for C14.

| Finding | Disposition in this revision |
|---|---|
| **E-1** (blocking) — check C14 counts two version-requirement lines in `sdk/Cargo.toml` but its `PASS` line says both members "resolve in one lockfile in a shipping project", and the decision repeats the stronger form; `contentauth/c2pa-rs` commits no `Cargo.lock`, so no jointly resolved pins exist to cite | **Accepted; the audit is right on the facts.** All three locations that overstated the claim are narrowed to co-declaration — the reference-implementations paragraph, the C14 row of the check table, and the unproven table — each quoting revision 3's wording as superseded. No gate cites C14, so no disposition moves and the recommendation stands. |
| **E-1, the log line** | **The committed script and log are not edited.** `review/evidence/r48-claims-check.sh` and `r48-claims-check.log` are artifacts the round-1 empirical audit reproduced and both round-3 audits quote, so they stay byte-identical — **and the C14 `PASS` line's "resolve in one lockfile" wording is wrong**, exactly as the audit says. Rather than rewrite history, revision 4 adds a new check, `review/evidence/r48-r4-c14-narrow.sh`, which re-runs C14's fetch and asserts the narrowed claim directly — H01 asserts the same 1-and-1 line counts as co-declared semver requirements, H02 asserts **0** `Cargo.lock` paths in the repository's `main` tree with a fail-closed truncation guard. Where the two logs' wording disagrees, `r48-r4-c14-narrow.log` is correct and C14's line counts were right as written. |
| **Round-3 judgment observation (not a finding)** — the reproducibility sentence counting "three scripts' output" where four scripts existed | **Tidied as invited.** That numeral and its twin, "applied to each of the three", are carried to five now that a fifth script exists; the property both sentences assert holds of the new script too, which prints only asserted counts and fixed strings. |

**Revision note, revision 3.** Revision 3 answers the round-2 judgment audit
(`review/audit-fable.md`, verdict `reject`, findings JF-9 and JF-10) and is **prose-only**.
It moves no member, no version, no manifest shape, no gate disposition and no parameter
value; it gathers no new evidence about any crate. Both findings are the same kind of
mistake — revision 2's executed compile changed what is true about this run, and two
sentence-families did not follow it — and both are repaired by mechanical enumeration from
the line numbers the audit records, not by re-reading.

| Finding | Disposition in this revision |
|---|---|
| **JF-9** (blocking) — five prose locations credit check D01 with compiling **both** selected members' dependency trees, which D01 did not do, and which revision 2's own D05 disproves from the other side | **Accepted; the audit is right on the facts.** D01 runs `cargo test` with the `mock` feature **off**, and `mockall` is an optional dependency behind that feature, so it is absent from that build graph: D01 carries `httpmock`'s tree, **D02** carries `mockall`'s. All five locations now cite the pair — the revision-2 note's JF-4 row, the `## Parameters` prose, the D01 row of the spike table (whose D02 row is also amended to say what it carries), engine item 7, and the unproven table — each quoting revision 2's wording as superseded. The `mockall` gate-2 cell already cited "(D01, D02)" correctly and is unchanged. |
| **JF-9, the log line** | **The committed log is not edited.** `review/evidence/r48-r2-msrv-macos-spike.log` is an artifact the round-1 and round-2 audits read, so it and its script stay byte-identical — **and its D01 `PASS` line is wrongly worded**, exactly as the audit says: it credits that feature-off run with compiling "mockall's and httpmock's resolved dependency trees". Rather than rewrite history, revision 3 adds a new check, `review/evidence/r48-r3-tree-msrv-relabel.sh`, which re-runs the same two commands on the same probe crate and asserts the split directly — G01 asserts **0** `Compiling mockall` lines in the feature-off run, G02 asserts **1** in the feature-on run. Where the two logs' wording disagrees, `r48-r3-tree-msrv-relabel.log` is correct and the D02 and D05 lines of the revision-2 log were right as written. |
| **JF-10** (blocking) — two claims revision 2's own `## Empirical check` declares superseded are still live | **Accepted.** `## Decision` no longer says "Nothing was built here and no Rust was compiled by either engine or by this synthesis"; it now separates the template (not built, not implemented) from the throwaway probe crate (compiled, outside the repository, described under `## Empirical check`). The `httpmock` gate-6 cell no longer says "**No wall-clock figure: nothing was compiled**"; it now says what its `mockall` neighbour already said — figures exist but do not represent the template. The `## Engines` sentence that the two raw reports "both report that nothing was compiled" is **true of codex and opus and is deliberately left standing**, as the audit directs. |

**Revision note, revision 2.** Revision 2 answers the round-1 judgment audit
(`review/audit-fable.md`, verdict `reject`, findings JF-1 to JF-8) and changes
**nothing in the recommendation**: the stack is still the same three members at the same
versions in the same manifest shapes, no parameter value moves, and the
`BASELINE-REVIEW: F120` finding stands as written. The round-1 empirical audit
(`review/audit-codex.md`, verdict `approve`) reproduced `review/evidence/r48-claims-check.sh`
and both of its logs; all three are carried into this revision **byte-identical**, and the
two new checks are new files (`r48-r2-msrv-macos-spike.sh`, `r48-r2-citations-check.sh`).
The one finding the auditor said could move the recommendation, JF-2, is closed by
executed evidence rather than by demotion, so member 2 stays in the stack.

| Finding | Disposition in this revision |
|---|---|
| **JF-1** (blocking) — `wiremock` 0.6.5 kept on the qualified shortlist under a gate-2 reading the programme withdrew | **Accepted.** Fitness gate 2 is now applied by one rule to every candidate, the strict one the programme settled at `docs/planning/p02/execution-ledger.md:414` and applied at `:640`: an absent declared `rust-version` does not clear the gate. `wiremock` 0.6.5 and `httptest` 0.16.4 move to *Excluded by gate*, `mry` 0.14.0's clause is corrected, and codex's reading at `raw/codex.md:115` is recorded as right. Superseded wording: "**passes on substance, fails on declaration**" in `wiremock`'s gate-2 cell; "`wiremock` fails no applicable gate: gate 2 passes on substance" in engine item 3; "`unimock` 0.6.8 and `mry` 0.14.0 fail no applicable gate"; "`httptest` 0.16.4 fails no applicable gate and is kept on the shortlist". The C12 reversal condition is rewritten so commit activity alone cannot re-admit `wiremock`: superseded wording — "a re-verification finds commits on `LukeMathWalker/wiremock-rs` after 2025-08-24, **or** a released 0.6.6+ that declares `rust-version`". |
| **JF-2** (blocking) — `mockall`'s gate 4 recorded as a pass on evidence the same document calls unproven | **Accepted, and closed with observed evidence.** A throwaway probe crate was compiled **outside** the repository on this macOS host at the `msrv-policy` floor (1.96.0) and at stable (1.98.0): `review/evidence/r48-r2-msrv-macos-spike.log`, checks D01–D05. Gate 4 for `mockall` 0.15.0 is now `passes` on an executed macOS compile plus the crate's own `ubuntu-latest` CI, not on a 0.13.0 adopter. Superseded wording: "**passes by adopter evidence.** … macOS support for 0.15.0 specifically is **inferred, not observed**". Codex's contrary position at `raw/codex.md:61` is added to `## Engines` as item 7. Because the gate is closed, **member 2 stays**; had it not been, `mockall` would have moved to *Excluded by gate* and the stack would have become two members. |
| **JF-3** (blocking) — every figure outside the check table is uncited | **Accepted.** The three adopter claims that carried three gate-4 dispositions are re-read at source by checks E01–E03, and a **Sources** paragraph now gives an endpoint and a retrieval date for every remaining figure, following R01's precedent. |
| **JF-4** (blocking) — a gate-2 cell cites C08 for a property C08 does not assert, and dependency-tree MSRV is established for no candidate | **Accepted.** The "(C08)" attribution is removed from the clause it did not support. Dependency-tree MSRV is now **executed** for both selected members — `httpmock`'s tree in the feature-off run (D01, G01) and `mockall`'s in the feature-on run (D02, G02) — and recorded as **unproven** for `mockito`, with what would prove it, in the unproven table. (Revision 2's wording of this row credited D01 alone with "their whole resolved trees"; that is corrected under JF-9 below.) |
| **JF-5** (non-blocking) — R01's F121 row quoted by half | **Accepted.** The row is quoted in full, including "no parametrization or mocking crate", with one sentence distinguishing the suite *mechanism* R01 governs from the upstream member 3 stubs. |
| **JF-6** (non-blocking) — member 1 receives no gate or figure statement | **Accepted.** Member 1 now carries an explicit `inapplicable` statement for gates 1 to 6 and for the crate figures, with the reason, following R01's precedent at its line 93. |
| **JF-7** (non-blocking) — an unrecorded `shellcheck` claim | **Accepted.** `shellcheck` now runs inside check E05 over all three evidence scripts and its result is in a committed log; the unrecorded claim is gone. |
| **JF-8** (non-blocking) — "printed anywhere" is true of the log and false of the decision body | **Accepted.** The sentence is scoped to the scripts' own output, and the body figures it mis-described are given endpoints under JF-3. Superseded wording: "is printed anywhere, because those drift by the hour". |

**Revision history.** Revision 1 — sha256
`0309754689dc338010858e46a59f7b6f52ed8859464b9ac1dfc564d5a537ed5f`, commits `aa585df`
(first write) and `2d79de8` (checks C19–C20); approved by the round-1 empirical audit
(`review/audit-codex.md`), rejected by the round-1 judgment audit on JF-1 to JF-8.
Revision 2 — sha256 `29e7c7cf1f207e564ec839db168258abe7d0a5e1cdb79959e0b3faf5992fb683`,
commit `695f673`; the round-2 judgment audit (`review/audit-fable.md`, commit `453ac73`)
closed JF-1 to JF-4 and rejected on JF-9 and JF-10. Revision 3 — sha256
`dc1ef152a473cd0a3a3811489cd1a8c98867e9e4751d33dc79b9f2faaf499782`, commit `894f965`;
the round-3 empirical audit (`review/audit-codex.md`) reran all four scripts green and
rejected on E-1, while the round-3 judgment audit (`review/audit-fable.md`) approved with
no findings and one numeral observation carried for a later revision. Revision 4 — sha256
`2cd910baf4d69a6b59ec269c37378b69d341a20e9fdd299f8ccb34e0769aa7b6` (uncommitted
worktree at audit time): the E-1 prose narrowing plus the new `r48-r4-c14-narrow` check
and log; the empirical audit (`review/audit-claude.r3.md`) approved with no findings while
the judgment audit (`review/audit-fable.r3.md`) rejected on JF-R4-1. Revision 5 — sha256
`683c23107df366217d22e5e195c342c4c8f99f0172af402ee387ec160a742148` (uncommitted worktree
at audit time): the JF-R4-1 provenance repair, prose-only; the empirical audit
(`review/audit-claude.r5.md`) approved with no findings while the judgment audit
(`review/audit-fable.r5.md`) rejected on JF-R5-1. Revision 6 — this file: the JF-R5-1
engine-fidelity repair, prose-only. Every revision-1 through revision-5 script and log is
carried forward byte-identical.

## Decision

**One stack, three members.**

| # | Member | Manifest shape | Role |
|---|---|---|---|
| 1 | Hand-written port fakes and a `RecordingPort<P>` spy wrapper — **no crate** | template code in `src/core/testing.rs`, no manifest line | The default. The only test-double mechanism the base `cargo test` run needs. |
| 2 | **`mockall` 0.15.0** | `[dependencies] mockall = { version = "0.15.0", optional = true }` with `[features] mock = ["dep:mockall"]`, applied as `#[cfg_attr(feature = "mock", mockall::automock)]` | Off-by-default escape hatch for call-count, argument-matcher and ordered-call assertions a hand-written fake makes verbose. One CI lane must run `cargo test --features mock`. |
| 3 | **`httpmock` 0.8.3** | `[dev-dependencies] httpmock = { version = "0.8.3", default-features = false }` | The hermetic loopback upstream for the real HTTP adapter: R01's F121 contract-suite invocation against that adapter, and the adapter's own boundary tests. |

Ledger rows settled: **F119** (mock/test-double library) and **F120** (HTTP transport
mocking mechanism in tests), both `DIVERGENT` in `docs/port/COMMONALITY.md:125-126`.

**This is a proposal validated in the implementation phase** (owner ruling, 2026-09-10).
It records what the research found and what it recommends; **P03 builds the template and
its CI proves the recommendation**. The template was not built here and this decision
implements none of its recommendation: the template does not exist yet. Neither engine
compiled anything; the only Rust this synthesis compiled is the throwaway probe crate
described under `## Empirical check`, built outside this repository to close two gates and
deleted afterwards. Every acceptance criterion below is a requirement on P03, not an
observed result. (Revision 2 still carried revision 1's categorical sentence here —
"Nothing was built here and no Rust was compiled by either engine or by this synthesis" —
which its own `## Empirical check` had already superseded; that wording is retired.) A decision that does not
survive implementation is revised against this recorded research, not researched again
from scratch. The claims P03 must validate are listed under `## Engines`.

**The conditional in the prompt fires.** The prompt makes member 3 conditional on "R01
choosing a port/adapter split with a real outbound HTTP call to intercept". R01 has since
resolved (`research/topics/01-ports-and-adapters-seam/DECISION.md`, revision 3,
2026-09-13; sha256 verified as this run's pinned prerequisite, check C17) to a
dyn-compatible `pub trait ProjectsPort: Send + Sync` with the production adapter in
`src/core/adapters/http.rs`. That adapter performs real outbound HTTP, so the condition is
met and member 3 is in the stack rather than held in reserve. The narrowing this forces on
one sentence of R01's published prose is carried as `BASELINE-REVIEW: F120` below — a
disposition recorded here, **not** an edit to R01, whose owned parameter value,
recommendation and crate selections are all unaffected.

**Reconciliation with the owner-supplied standing input.** The reference architecture
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` (copied into this
run's `inputs/`) names **`wiremock = "0.6"`** for "Mock outbound HTTP" in its C12 Testing
row and its pin block (both lines re-verified in the input document, check C15). Owner
decision 11 of 2026-09-16 rules the document "an owner-supplied research input, not a
binding standard and not a pre-decision".

*Disposition on the mocking half of C12: **differ, with ground.*** Member 3 selects
`httpmock` 0.8.3 rather than `wiremock` 0.6.5 on three grounds, each re-verified at a
primary source by this synthesis and none of them a licence, a download count or a
preference. The first is decisive on its own; the other two are why `httpmock` rather
than `mockito` takes the vacant place.

1. **`wiremock` 0.6.5 does not clear fitness gate 2, so it is not eligible.** It declares
   no `rust-version` at all (checks C03 and E04). The programme settled how gate 2 is
   read: `docs/planning/p02/execution-ledger.md:414` withdraws the permissive reading in
   terms — "an unknown effective version is not evidence of incompatibility … but it is
   insufficient evidence to PASS a gate the prompt says must be passed" — and `:640`
   applies the strict reading to a crate in exactly this position. The prompt's own
   instruction is that a failed gate lists the candidate under *Excluded by gate*, and
   that is where `wiremock` now sits. An owner who wants `wiremock` is choosing to waive
   a gate, not to prefer a crate.
2. **`wiremock`'s API is async-only, and R05 (`sync-async-execution-model`) is still
   open.** `wiremock`'s own README comparison table records the split as `mockito:
   Async/Sync`, `httpmock: Async/Sync`, `wiremock: Async` (check C11). Selecting it today
   would decide by the back door that the template's test suite is async — a decision this
   item does not own.
3. **`wiremock`'s maintenance state is `at-risk` on concrete signals**, not on a
   release-age heuristic: `api.github.com` reports `archived: false` but a `pushed_at`
   date of **2025-08-24**, the day 0.6.5 was released (check C13).

*The condition under which `wiremock` becomes eligible again*, stated so the owner can
overturn this on one fact rather than on a re-read: **a released `wiremock` 0.6.6 or later
that declares `rust-version` inside the floor** — that is the gate, and nothing else
clears it. Commit activity on `LukeMathWalker/wiremock-rs` alone does **not** re-admit the
crate; it would lift ground 3 only, leaving grounds 1 and 2 standing. With the gate
cleared, `wiremock` would re-enter the qualified shortlist and win outright only if R05
also resolves to async everywhere, since ground 2 lapses only then. In that case the
change is a drop-in swap of one dev-dependency and the test scaffolding that constructs
the server; nothing else in the template changes. Check E04 is written to FAIL the day
`wiremock` declares a `rust-version`, and check C13 the day the repository is pushed
again.

*The rest of the C12 row is a hand-off, not this item's to decide.* `axum-test` and the
in-process router idiom belong to R69 (`web-framework-stack`, already resolved), `insta`
snapshots to R33 (`property-and-snapshot-testing`, already resolved), and `#[sqlx::test]`
and the CI lane order to R32 (`test-harness-and-execution`). *Process note for the
controller, not a finding against any item:* owner decision 11's overlap set assigns C12
to R32, whose prompt does not own F119 or F120; R48 is the item that owns them, and the
controller supplied the document to this run accordingly.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

| Row | Requirement | Source | Agreement level |
|---|---|---|---|
| F119 | A test can replace a collaborator with a programmable stand-in and can afterwards assert *what the code under test asked of it*. | `docs/port/areas/testing-coverage.md:9`, `docs/port/DIVERGENCE-ANALYSIS.md:177` (cause class **B**, `harmonize: no`) | **Capability.** The mechanism is explicitly allowed to differ: the analysis row's own words are "same DI-and-spy pattern, only the framework-native tool differs". |
| F120 | The code that performs real outbound HTTP is exercised against a controlled, hermetic upstream: no test reaches the public internet, and upstream schema drift fails a test rather than degrading silently. | `docs/port/areas/testing-coverage.md:10`, `docs/port/DIVERGENCE-ANALYSIS.md:178` (cause class **F**, genuine design disagreement, `harmonize: no`) | **Capability** (hermetic upstream control), explicitly *not* mechanism: the analysis row records that the mechanism follows from each repo's seam shape. |

**What must agree, and what may vary.** The two capabilities above must agree across
`py-launch-blueprint`, `ts-launch-blueprint` and `rs-launch-blueprint`. The *mechanism* may
vary and here it varies three ways, each justified rather than accidental: (i) Rust's
double is a nominal `impl` the compiler checks, where py uses `unittest.mock` over a
`Protocol` and ts uses structural typing, so the Rust template needs no mocking library to
obtain a *substitute* at all; (ii) Rust's built-in `#[test]` harness ships no spy
primitive, so the recording wrapper is written once in the template rather than imported,
which is why a crate is offered as a gated escape hatch and not as the default;
(iii) Rust's hermetic upstream is a real loopback socket rather than py's in-process
transport patch, which is strictly more faithful and costs one constructor parameter.

**Essential behaviors, read from what the two source repos do at their programme pins**
(`py` at `b08bccfb`, `ts` at `cb1cbcb2`; all line references from the opus report, read at
those pins on 2026-09-17):

| # | Behavior | py | ts | Rust realization |
|---|---|---|---|---|
| B1 | Canned return values for a collaborator | `svc = Mock(); svc.list_projects.return_value = [...]` (`tests/cli/test_pylb.py:58-62`) | `vi.fn<Prompter>(() => Promise.resolve(selection))` (`tests/cli.test.ts:102`) | a hand-written struct implementing `ProjectsPort`, returning stored rows (member 1) |
| B2 | Error injection at a collaborator | `mock_service.list_projects.side_effect = RuntimeError("kaboom")` (`tests/cli/test_pylb.py:556,570`) | an `Error` pushed into the fake's reply queue (`tests/api.test.ts:21-37`) | a fake with a failure knob (member 1), or `mockall`'s `.returning(\|_\| Err(..))` (member 2) |
| B3 | Interaction assertion — *what was asked* | `mock_service.list_projects.assert_called_with(workspace="WS", limit=5)` (`tests/cli/test_pylb.py:95`) | recorded `calls`/`urls` vectors interrogated after the act (`tests/api.test.ts:18-38`) | `RecordingPort<P>` holding `Mutex<Vec<PortCall>>` (member 1), or `mockall`'s `.with(..).times(1)` (member 2) |
| B4 | Hermetic upstream with per-route canned bodies | `@responses.activate` + `responses.get(f"{BASE}/projects", json={...})` (`tests/core/test_py_api_repository.py:104-110`) | not needed — the transport *is* the injected `fetchImpl` (`tests/api.test.ts:27`) | a loopback HTTP server on an ephemeral port plus a base URL the adapter accepts (member 3) |
| B5 | Request-derived response bodies for the contract suite | `_projects_cb(request)` reads `workspace`/`limit` from the query string and computes the body (`tests/core/test_projects_repository_contract.py:52-60`) | `makeApiFetch` routes on `url.pathname` (`tests/cli.test.ts:45-60`) | `httpmock`'s `Then::respond_with(closure)` (member 3; present in the released 0.8.3, check C12) |
| B6 | Schema drift is loud | a renamed `data` key raises `APIError` instead of reading as "no projects found" (`tests/core/test_py_api_repository.py:113-117`) | typed decode of the canned `Response` | the adapter's own boundary tests against the stub server (member 3) |

**Observable acceptance criteria.** These are requirements on the template P03 builds.
None was executed here.

1. The base suite needs no mocking crate. *Observable:* `cargo test` passes and
   `cargo tree --edges dev -i mockall` reports nothing when `--features mock` is absent.
2. B3 is expressible without a crate. *Observable:* a CLI test asserts the exact
   `ProjectQuery` the CLI passed to the service and fails when the CLI's default `limit`
   changes.
3. B4/B5/B6 hold for the real adapter. *Observable:* R01's
   `assert_projects_port_contract` is invoked once with `InMemoryProjectsPort` and once
   with the HTTP adapter pointed at a loopback stub, both from the same seed rows; a
   deliberate rename of the stub's `data` key to `results` makes the HTTP invocation fail
   while the in-memory invocation still passes.
4. No test binds a fixed port or reaches a non-loopback address. *Observable:* the stub's
   URL is taken from the server object and the suite passes with tests running in parallel
   on `ubuntu-latest` and on `macos-latest`.
5. The `mock` feature does not rot. *Observable:* one CI lane runs
   `cargo test --features mock` and fails if the gated mocks stop compiling. That lane's
   placement is R32's and R11's; this item's requirement is only that some lane exists.

**Architectural alternatives compared, before any crate was weighed.**

*F119 — the test-double mechanism:*

| Alternative | Shape | Verdict |
|---|---|---|
| **A. Hand-written fake implementing the port trait** | `InMemoryProjectsPort` plus a generic `RecordingPort<P>` wrapper holding `Mutex<Vec<PortCall>>` | **Chosen as the default.** R01 already ships the fake as a public, unconditional library item (F013). "Framework-native", which is what both source repos use, *means hand-written in Rust*, because libtest ships no spy. Zero dependencies; the recording wrapper is written once and is generic over the port. |
| **B. Derive-macro mocking crate (`mockall`)** | `#[cfg_attr(feature = "mock", automock)]` on the port trait | **Chosen as a gated escape hatch, not the default.** It expresses B3 in one line and B2 per call. It cannot serve F121 — R01's reason stands and is restated: a mock's behavior is programmed per test, so running the same assertions against it compares nothing. |
| **C. Struct mocking without a trait (`faux`)** | `#[create]`/`#[methods]` on the concrete adapter struct | **Rejected.** It mocks a concrete type instead of implementing the port trait, so it cannot produce a `ProjectsPort` implementor for F013 or F121. Its own documentation records liberal use of `unsafe` (gate 3). |
| **D. Closure-injected collaborators (ts's `CliDeps`)** | `Box<dyn Fn(..) -> .. + Send + Sync>` fields | **Rejected as the seam** — R01 compared and rejected it (its alternative B) for the whole bundle, and re-litigating it is out of scope here. Retained as a legitimate shape for single-method *leaf* collaborators (a clipboard writer, a spinner factory) where a trait buys nothing. |
| **E. One universal mock type (`unimock`, `mry`)** | one mock struct answering every trait | **Rejected on ecosystem weight and fit.** Nothing in a one-port template needs the cross-trait unification they exist to provide. |

*F120 — the HTTP upstream stub:*

| Alternative | Shape | Verdict |
|---|---|---|
| **A. Loopback mock HTTP server plus an injectable base URL** | the stub binds an ephemeral loopback port; the adapter is constructed with `server.base_url()` | **Chosen.** Highest fidelity: the real client builds real requests, headers and query strings, and real status codes come back — which is the whole reason the adapter exists. It is also what every surveyed Rust adopter does. |
| **B. Transport injection inside the adapter (ts's `fetchImpl`, translated)** | the adapter holds an injected client trait or `tower::Service`; tests pass a fake | **Rejected as the primary mechanism.** It leaves the adapter's own request construction — header names, query encoding, status handling, body decoding — untested, and adds a second seam under the seam R01 just decided, with no ledger row asking for one. Recorded as a *complement*: a failure mode unreachable through a real socket (a mid-body connection reset, a DNS failure) is the one case where a narrow injected-transport test is the right tool. |
| **C. In-process HTTP interception, py's `responses` model** | patch the client's transport globally, no socket | **Not available in Rust.** `responses` works by monkey-patching `requests`' transport adapter at run time; Rust has no run-time patching of a linked crate's internals, and every candidate binds a real loopback socket instead. This is the largest justified ecosystem difference in this item, and it has one structural consequence: **the HTTP adapter's base URL must be a constructor parameter**, where py keeps a class constant precisely because `responses` intercepts below it. |
| **D. Record/replay cassettes (`rvcr`)** | record real traffic once, replay thereafter | **Rejected.** Cassette staleness is a maintenance liability in a template meant to be copied, and its adoption is negligible. The same idea is available inside the recommended crate through `httpmock`'s `record` feature if it is ever wanted; that feature is not enabled here. |
| **E. No HTTP-level test at all** | rely solely on the port-level fake | **Rejected.** It is the status quo ts lives with *because ts has no real transport to test*. Here it would leave the only I/O-performing code in the template unexercised and would silently drop half of F121. |

**Why the selected design preserves each principle.** F119's capability is preserved in
full by member 1 alone: B1 and B2 are a struct with stored rows and a failure knob, and B3
is `RecordingPort<P>`, which is roughly twenty lines, is `Send + Sync` for free (a
`Mutex<Vec<_>>` of plain data is both — which matters because R01's port carries
`Send + Sync` supertraits and the root erases to `Arc<dyn ProjectsPort>`), and is generic
over the port so it survives a second port. Member 2 adds only terseness; dropping it
costs the template no capability, and that is stated here rather than implied. F120's
capability is preserved by member 3 and cannot be preserved without it: R01's F121 row
commits the template to one contract suite "called from `tests/` once per adapter; **no
parametrization or mocking crate**" and names two adapters, one of which performs network
I/O, so that suite needs an upstream to answer it. **The row's second clause governs the
suite's own mechanism, not the upstream the adapter talks to.** R01's reason for it is
that a mock's behavior is programmed per test, so running one shared set of assertions
against a mock compares nothing; `httpmock` programs no adapter and implements no port —
it answers HTTP requests the real adapter makes, leaving the suite a plain generic
function over the port bound, exactly as R01 specifies. py holds both halves at once, and
that is the direct precedent: its contract suite takes no parametrization library and no
mocking library, and stubs the upstream with `responses`. py does exactly this and says so
in the suite's own docstring — "the in-memory
fake and the real HTTP adapter (its network mocked with `responses`)" — and records the
dependency's purpose verbatim in `pyproject.toml:101` as
`"responses>=0.25",       # HEX-40 — HTTP mock for the port-contract suite`. Both lines
were re-read at pin `b08bccfb` by this synthesis (check C18).

**Reference implementations, cited because they are well regarded and relevant rather than
merely popular.** `rust-lang/crates.io` — the Rust project's own registry service, and the
only surveyed project with this template's exact shape (workspace, web service, workers,
library crates) — pins `mockall = "=0.15.0"` and implements the gated-mock pattern member 2
copies: `crates/crates_io_github/src/lib.rs` carries
`#[cfg_attr(feature = "mock", mockall::automock)] pub trait GitHubClient: Send + Sync` with
`[features] mock = ["dep:mockall"]` in that crate's manifest (recorded by R01 from a
2026-09-05 source read and re-confirmed at the root manifest by opus on 2026-09-17).
`tokio-rs/tokio` declares `mockall = "0.13.0"` in `tokio/Cargo.toml` and names
`macos-latest` in `.github/workflows/ci.yml`
(`https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml` and
`.../master/.github/workflows/ci.yml`, both re-read 2026-09-17, check E01) — corroborating
evidence for `mockall` on macOS, at 0.13.0 and **not** at the recommended 0.15.0, which is
why gate 4 for 0.15.0 is closed below by an executed compile instead.
`contentauth/c2pa-rs` — Adobe's Content Authenticity Initiative reference
SDK for the C2PA standard — **declares both version requirements in one manifest**,
`mockall = "0.15.0"` and `httpmock = "0.8.3"` in `sdk/Cargo.toml`, which
this synthesis re-read at source (check C14, narrowed wording H01); those lines are Cargo
semver requirements, not lockfile pins, and the repository commits no `Cargo.lock` (H02),
so what is established is co-declaration, not a jointly resolved tree. It is still the
strongest compatibility evidence available short of building the template, and no
equivalent pairing of `mockall` with `mockito` or with `wiremock` was found. (Revision 3's
wording here — "carries **both** recommended members at **exactly** the recommended versions
in one manifest" — is superseded: "exactly" is true of the requirement strings and false of
any resolved versions.) `awslabs/aws-lambda-rust-runtime` declares
`httpmock = "0.8.1"` (`https://raw.githubusercontent.com/awslabs/aws-lambda-rust-runtime/main/lambda-runtime/Cargo.toml:63`,
opus, 2026-09-17). `matrix-org/matrix-rust-sdk` declares
`wiremock = { version = "0.6.5", default-features = false }` and names `macos-latest` in
its own CI (`https://raw.githubusercontent.com/matrix-org/matrix-rust-sdk/main/Cargo.toml`
and `.../main/.github/workflows/ci.yml`, both re-read 2026-09-17, check E02);
`XAMPPRocky/octocrab` and `TrueLayer/reqwest-middleware` declare `wiremock = "0.6.0"`
(`.../octocrab/main/Cargo.toml:106` and
`.../reqwest-middleware/main/reqwest-middleware/Cargo.toml:37`, opus, 2026-09-17).
`apache/iceberg-rust` declares `mockito = "1"` and names `macos-latest` in its own CI
(`https://raw.githubusercontent.com/apache/iceberg-rust/main/Cargo.toml` and
`.../main/.github/workflows/ci.yml`, both re-read 2026-09-17, check E03); that its macOS
lanes are `build` and `build_with_no_default_features` while its `tests` job is
`ubuntu-latest` only is carried from the opus report at
`.github/workflows/ci.yml:118-145,182-210`, 2026-09-17, and is **not** asserted by E03.

**Minimal realistic example** (a description of what P03 writes, not code written here).
One library crate; `ProjectsPort` with `list(query)` and `get(id)`; R01's shipped
`InMemoryProjectsPort`; `HttpProjectsPort::new(base_url, token)`; R01's
`assert_projects_port_contract<P: ProjectsPort>(label, make)` under `tests/`.
`tests/port_contract.rs` calls it twice — once with the in-memory adapter seeded from the
canonical rows, once with `HttpProjectsPort::new(server.base_url(), "t")` where `server` is
an `httpmock::MockServer` whose single mock answers `GET /projects` with a `respond_with`
closure reading `workspace` and `limit` from the query string, the direct translation of
py's `_projects_cb`. `tests/http_adapter_boundary.rs` holds the drift tests (a renamed
`data` key, a project with no `name`, 401 and 500 mapped into R67's error vocabulary).
`tests/cli_projects.rs` builds the CLI over `RecordingPort<InMemoryProjectsPort>` and
asserts the exact `ProjectQuery` — py's `assert_called_with` parity, with no crate.

**File-level changes in the template** (crate naming and workspace placement are R02's;
test tiers and CI lanes are R32's and R11's):

| File | Change |
|---|---|
| `Cargo.toml` | `mockall = { version = "0.15.0", optional = true }` under `[dependencies]` — **not** `[dev-dependencies]`, because `dep:mockall` can only name a normal dependency — plus `[features] mock = ["dep:mockall"]`; and `httpmock = { version = "0.8.3", default-features = false }` under `[dev-dependencies]` |
| `src/core/ports.rs` | `#[cfg_attr(feature = "mock", mockall::automock)]` above `pub trait ProjectsPort`; under an async R05 it must precede `#[async_trait]` |
| `src/core/adapters/http.rs` | the constructor takes a base URL — `HttpProjectsPort::new(base_url, token)` rather than a private `const BASE_URL` — so tests can point it at a loopback stub. **This is the single structural change this item forces on R01's design**, and it is the direct consequence of alternative C above being unavailable in Rust. |
| `src/core/testing.rs` (new) | `pub struct RecordingPort<P>`, `pub struct PortCall`, `pub fn calls()` |
| `src/lib.rs` | re-export `RecordingPort` and `PortCall` beside R01's exports, for the same reason R01 made the fake public: integration tests under `tests/` link the library as an external crate and cannot see `#[cfg(test)]` items (the public-surface policy itself is R04's) |
| `tests/port_contract.rs` | a second invocation of R01's `assert_projects_port_contract`, against the HTTP adapter pointed at an `httpmock::MockServer` |
| `tests/http_adapter_boundary.rs` (new) | the drift and status-mapping tests |
| `tests/cli_projects.rs` | build the CLI over `RecordingPort<InMemoryProjectsPort>` and assert the recorded `ProjectQuery` |
| CI workflow | one lane runs `cargo test --features mock` |

Nothing in this item changes the shipped binary, the library's runtime dependency graph or
any `[profile.*]` setting.

**Baseline review.** One finding is carried, in the required form. It narrows the wording
of one sentence in a published prerequisite; it is not an edit to that decision and not a
`CONFLICT:`, because R01's owned parameter is consumed here verbatim and unchanged.

BASELINE-REVIEW: F120 — a driven-I/O adapter that performs real network I/O is exercised against a controlled upstream, not only substituted away at the port seam — narrow R01's sentence "the recommended seam needs no HTTP-mocking crate" to "no HTTP-mocking crate is needed **at the port seam**", and record that the F121 substitutability suite and the HTTP adapter's own boundary tests, both of which run against the real adapter, do need a loopback HTTP stub; affected items: R48 (this item, which selects the crate), R01 (the sentence's wording only — its owned parameter value, its recommendation and every crate it selected are unaffected), R32 (`test-harness-and-execution`, whose tiers must include one in which a loopback listener is bound) — evidence: R01's own F121 row commits the template to one contract function "called from `tests/` once per adapter; no parametrization or mocking crate" and names two adapters, one of them `src/core/adapters/http.rs` (the row's second clause governs the suite's own mechanism — this finding proposes no parametrization and no mocking crate in that suite, only an upstream for the adapter it already runs against); R01's own unproven-claims table asks for "a template integration test that starts the real upstream (**or a bound test listener**)", which is precisely what an HTTP-stub crate provides; py at pin `b08bccfb` does exactly this, in `tests/core/test_projects_repository_contract.py` ("the in-memory fake and the real HTTP adapter (its network mocked with `responses`)"), in `tests/core/test_py_api_repository.py:104`, and in `pyproject.toml:101` ("`responses>=0.25`  # HEX-40 — HTTP mock for the port-contract suite") — the last two re-read at the pin by this synthesis, check C18.

**Fitness gates, answered per candidate before popularity was weighed.**

**Member 1 carries no crate, so its gates and figures are `inapplicable`, stated rather
than omitted.** Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)` like every other
candidate's; gates 2 to 6 are `inapplicable — no crate exists to carry a declared MSRV, an
advisory, a platform matrix, a feature set or a build cost`. The crate figures the prompt's
evidence table requires — 90-day and all-time downloads, last release, stars, open issues,
issue responsiveness, advisories, adopters — are `inapplicable` for the same reason: there
is no registry page and no repository to query. For the record, traits, `impl` blocks and
`std::sync::Mutex` predate Rust 1.0, the code the template writes is `unsafe`-free, and
nothing in member 1 constrains the 1.96 floor or the `ubuntu-latest, macos-latest` matrix.
This follows R01's precedent for its own language-feature members (its line 93).

**Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate
in this item.** Licence compatibility is not evaluated, nothing is excluded on a licence,
and each crate's declared licence is recorded below as a fact only. Neither raw report
excluded any candidate on a licence, so nothing has to be re-evaluated on that account;
the codex report's phrase "No general-mocking candidate is excluded for an observed
incompatible license" is recorded as struck rather than as a passing gate.

| Candidate | 1 licence (recorded only) | 2 MSRV vs the 1.96 floor | 3 advisory / `unsafe` | 4 `ubuntu-latest, macos-latest` | 5 default features / async coupling | 6 binary size and compile cost |
|---|---|---|---|---|---|---|
| `mockall` 0.15.0 **(selected)** | `MIT OR Apache-2.0` | **passes, both halves.** *Crate:* declares `rust-version = "1.77.0"` (C01, E04), inside the 1.96 floor, enforced by a CI job pinned to that image. *Dependency tree:* **executed** — the whole resolved tree compiles and its test passes at 1.96.0 on this macOS host (D01, D02), which is the tree half the prompt asks for. C08 is cited only for the dependency **names** it asserts, not for their MSRVs | **passes** — `rustsec.org/packages/mockall.html` HTTP 404, evidenced as "no advisory" by the `lock_api` control (C07). `unsafe`: the crate is safe Rust; `downcast` uses `unsafe` for type erasure and `fragile` for a thread-affinity check — **stated from manifests and documentation, not a line-by-line audit** | **passes, observed.** *Ubuntu:* the crate's own CI (`.github/workflows/ci.yml` at the `v0.15.0` tag) runs `ubuntu-latest`. *macOS:* **executed at the recommended version** — a throwaway probe crate outside this repository resolved `mockall 0.15.0`, expanded `#[automock]`, and passed a test erasing the generated mock to `Arc<dyn Trait>` at 1.96.0 and at stable 1.98.0 on Darwin 26.4 aarch64 (D02, D03, D04). That is the architecture `macos-latest` runs today, though not the GitHub runner image itself. `tokio-rs/tokio` (E01) is corroboration at 0.13.0, no longer the basis | **passes** — the only feature is `nightly`, not default; no async runtime anywhere in the required dependency list (C08), so enabling `mock` does not drag `tokio` into a sync build. Composes with `async-trait` subject to `automock` preceding `#[async_trait]` | **passes** — zero bytes in the shipped binary (feature-and-dev-only). Compile cost is one extra proc-macro tree (`mockall_derive` → `syn`), paid only under `--features mock`, which is the reason for the gate. **No wall-clock figure is offered**: the spike compiles a two-method probe crate, not the template, so its timings would not represent the template's cost |
| `httpmock` 0.8.3 **(selected)** | `MIT` | **passes, both halves.** *Crate:* declares `rust-version = "1.88.0"` (C02, E04), four minors of headroom below the 1.96 floor, enforced on master by `cargo hack check --rust-version --each-feature --no-dev-deps`. *Dependency tree:* **executed** — its whole resolved tree, `tokio` and `hyper` included, compiles and links at 1.96.0 on this macOS host (D01) | **passes** — `rustsec.org/packages/httpmock.html` HTTP 404 with the same control (C07). `unsafe`: **corrected here.** `unsafe_code = "forbid"` appears in the **master** manifest, which is already versioned 0.9.0; the released **v0.8.3 tag's manifest carries no such lint and declares `edition = "2021"`** (C06). For 0.8.3 the posture is "safe Rust over `hyper`/`tokio`", stated from manifests, not audited | **passes on its own CI** — `.github/workflows/platform.yml` runs the matrix `os: [ubuntu-latest, macos-latest, windows-latest]` (C09). It is the only candidate in the category whose own CI covers macOS, and `target-os-matrix` is owner-fixed, so this is the gate-4 discriminator | **passes with a change** — default feature set is exactly `["cookies"]` (C05), which this recommendation turns off with `default-features = false`; nothing here matches on cookies. `standalone`, `https`, `proxy`, `record`, `remote` stay off. `tokio` is a required dependency of the crate, but the **API** is sync-and-async, so the dev tree contains `tokio` while the template's test code need not be async | **passes** — zero bytes in the shipped binary. Heaviest dependency list of the three full-featured candidates — **25** required normal dependencies against `wiremock`'s 15 and `mockito`'s 16, re-read at the endpoint (C19), which corrects the opus report's 26 — because it bundles diffing and pretty-printing for readable mismatch output; paid only when the test suite compiles. **No wall-clock figure is offered**: the spike's appendix does print times for compiling this tree, but they are times for a two-method probe crate, not for the template, so they would misrepresent the cost. Revision 2's wording here, "**No wall-clock figure: nothing was compiled**", is superseded — `httpmock`'s tree is the one thing the spike compiled three times |
| `mockito` 1.7.2 (**ranked runner-up**) | `MIT` | **crate half passes; tree half unproven.** *Crate:* declares 1.70 (C04, E04); its master branch moves to 1.85 (`https://raw.githubusercontent.com/lipanski/mockito/master/.github/workflows/tests.yml`, `MINIMUM_SUPPORTED_TOOLCHAIN`, opus, 2026-09-17), still inside the floor, so the headroom is narrowing. *Dependency tree:* **not established** — no `mockito` tree was resolved or compiled here, and the unproven table records what would prove it | **passes** — HTTP 404 (C07) | **unverified for macOS test execution, not failed** — its own CI covers `ubuntu-latest` and `windows-latest` and no macOS; the best adopter evidence, `apache/iceberg-rust`, runs macOS in its `build` matrices but its `tests` job on `ubuntu-latest` only, so macOS *compilation* is evidenced and macOS *test execution* is not | **passes** — sync and async APIs; `tokio` required; one optional feature | **passes** — zero bytes shipped; **16** required normal dependencies (C19), the lightest of the three full-featured options |

The qualified shortlist is therefore `mockall` 0.15.0 and `unimock` 0.6.8 for F119, and
`httpmock` 0.8.3 and `mockito` 1.7.2 for F120. `unimock` passes every applicable gate
(declares `rust-version` 1.70, E04; RustSec HTTP 404) and is not adopted **on fit and
ecosystem weight** — one mock type for all traits solves a cross-trait problem a one-port
template does not have.

**Fitness gate 2 is applied here by one rule, the programme's strict reading.** An absent
declared `rust-version` does not clear the gate:
`docs/planning/p02/execution-ledger.md:414` withdrew the permissive reading — "an unknown
effective version is not evidence of incompatibility … but it is insufficient evidence to
PASS a gate the prompt says must be passed" — and `:640` applies the strict one. Check E04
reads the declaration for all eleven surveyed crates in one pass, so the rule is applied
from one table rather than crate by crate. Revision 1 read the gate two ways inside one
document, passing `wiremock` "on substance" while excluding `double`, `stubr` and `rvcr`
on the identical absence; that reading is superseded.

*Excluded by gate.* **`wiremock` 0.6.5** — the crate the owner reference names. Excluded on
**gate 2**: it declares no `rust-version` (C03, E04), and a pull request to add one, #172,
was closed unmerged on 2025-08-26 (`https://api.github.com/repos/LukeMathWalker/wiremock-rs/pulls/172`,
opus, 2026-09-17), so the absence is settled rather than pending. Its *effective* floor is
at least 1.88 — its own issue #173 ("Error: `let` expressions in this position are
unstable", opened 2025-08-27, since closed) reports a let-chain compile failure against
0.6.5 (C20) and let chains stabilized in Rust 1.88.0
(`https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/`, opus, 2026-09-17) — but an effective
floor inferred from a bug report is exactly the "unknown effective version" the ledger
rules insufficient. Recorded so the exclusion is not read as harsher than the evidence:
`wiremock` fails **no other** gate. Gate 3 passes (RustSec HTTP 404, C07); gate 4 passes by
adopter evidence — its own CI has 0 macOS mentions across 5 `ubuntu-latest` jobs (C10),
closed by `matrix-org/matrix-rust-sdk` running its suite against `wiremock = "0.6.5"` on
`macos-latest` (E02); gate 5 passes with a coupling to record (`tokio` required, **API
async-only**, C11); gate 6 passes (zero bytes shipped; 15 required normal dependencies,
the lightest of the three, C19). It is not archived and 0.6.5 builds on docs.rs. **`httptest`
0.16.4** — excluded on **gate 2** on the same rule: it declares no `rust-version` (E04).
Revision 1 kept it on the shortlist as the lightest full-featured option; that is
superseded. Its adoption was the previously stated ground and is recorded as a figure only:
35 stars (`https://api.github.com/repos/ggriffiniii/httptest`, `stargazers_count`) and 55
reverse dependencies (`https://crates.io/api/v1/crates/httptest/reverse_dependencies`,
`meta.total`), both opus, 2026-09-17. **`mry` 0.14.0** — excluded on **gate 2**: it declares
no `rust-version` (E04). Revision 1 said `mry` "fails no applicable gate"; that is
superseded. **`double` 0.2.4** — excluded on **gates 2 and 6**: no declared `rust-version`
(E04), last release 2019-09-22
(`https://crates.io/api/v1/crates/double/versions`, opus, 2026-09-17); maintenance
`dormant` by the maintainer's own inactivity. **`stubr` 0.6.2** — excluded on **gates 2 and
6** (no declared `rust-version`, E04; last release 2023-06-29, same endpoint) and because
it is a layer *on top of* `wiremock`, inheriting every finding against it. **`rvcr` 0.2.1**
— excluded on **gate 2** (no declared `rust-version`, E04) and on adoption (262 downloads
in 90 days, `https://crates.io/api/v1/crates/rvcr`, `crate.recent_downloads`, opus,
2026-09-17); maintenance `at-risk`. **`faux` 0.1.13** — gate 1 `inapplicable`, and it is
**not** excluded on a licence; gate 2 it **passes** (declares `rust-version` 1.65, E04);
excluded on **gate 3** (its own documentation records liberal use of `unsafe`) and on
**fit** (it mocks a concrete struct, so it cannot produce a `ProjectsPort` implementor for
R01's seam). `mockall_double` 0.3.1, `axum-test` and `tower-test` are **out of scope, not
failed**:
the first swaps mocked *modules*, and the last two test *this* service's inbound router,
which is R69's and R32's subject, not an outbound upstream. A hand-rolled
`std::net::TcpListener` responder is excluded on **fit**, not by a gate: it would make the
template's tests a tutorial in HTTP framing rather than in hexagonal testing.

**Maintenance state by the rubric.** Every figure in this paragraph comes from one of three
endpoints, all retrieved **2026-09-17** and reported by the opus raw except where a check
is named: `https://api.github.com/repos/<owner>/<repo>` for `archived` and `pushed_at`;
`https://crates.io/api/v1/crates/<name>/versions` for the newest non-yanked release and its
date; and, for issue responsiveness,
`https://api.github.com/repos/<owner>/<repo>/issues?state=all&sort=created&direction=desc`
plus each issue's `/comments`, taking the median days from `created_at` to the first
comment whose `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose author
is not the reporter.

`mockall` (`asomers/mockall`) **active** — not archived, pushed 2026-09-02, 0.15.0 released
2026-06-28 (C01), median 1.18 days over the ten most recently opened issues, 0 of 10
unanswered. The codex raw computed a different figure for `mockall` from open issues only;
that disagreement, and why this paragraph uses the figure above, is adjudicated under
`## Engines`. `httpmock` (`httpmock/httpmock`) **active** — not archived, pushed 2026-09-14,
0.8.3 released 2026-02-04 (C02) — with the honest cost that its issue-queue responsiveness
is the weakest of the four surveyed HTTP candidates: median 10.53 days, 5 of 10 unanswered
(the codex raw did not compute this figure and said so). `mockito` (`lipanski/mockito`)
**active** — median 0.46 days, 2 of 10 unanswered. `wiremock`
(`LukeMathWalker/wiremock-rs`) **at-risk** on concrete signals, not on a release-age
heuristic: `pushed_at` 2025-08-24 (C13), 7 of its 10 most recently opened issues
unanswered, 7 open pull requests whose oldest is #127 from 2023-09-11
(`https://api.github.com/repos/LukeMathWalker/wiremock-rs/pulls?state=open&sort=created&direction=asc`).
Stated no harsher than the evidence: the repository is not archived (C13), 0.6.5 builds on
docs.rs (`https://docs.rs/crate/wiremock/0.6.5/status.json` → `{"doc_status":true}`), it
carries no advisory (C07), and a major adopter runs its suite against it on macOS today
(E02). It is `at-risk`, not `dormant` — and note that the reason it is excluded above is
gate 2, not this verdict. `httptest` (`ggriffiniii/httptest`) **stable-quiet** — pushed
2026-01-06, median 0.03 days, 1 of 10 unanswered. `faux` (`nrxus/faux`) **at-risk** — last
release and last push both 2025-09-27, with good responsiveness (median 1.54 days, 0 of 10
unanswered), so the verdict rests on the release gap plus the `unsafe` posture rather than
on neglect of users. `stubr`, `rvcr` **at-risk** on their release gaps (2023-06-29 and
2024-03-05); `double` **dormant** (last release 2019-09-22).

**No performance claim is made.** No latency, throughput or resource figure is offered for
any candidate: the workload that would matter is this template's own test suite, which does
not exist, and inferring one from the crates' unlike published benchmarks is what the
prompt forbids. The only cost figures stated are dependency counts and feature sets, each
with its endpoint.

**Sources.** Every figure this decision states has an endpoint, either in the check table
under `## Empirical check` or here. Figures marked *(check)* were executed by this
synthesis; the rest are carried from the raw reports at the retrieval dates given, which is
what the role permits and requires to be labelled.

*Registry, `https://crates.io/api/v1/crates/…`* — `<name>/versions` for the newest
non-yanked `num`, `created_at`, `rust_version` and `license` of `mockall`, `httpmock`,
`mockito`, `wiremock`, `unimock`, `faux`, `mry`, `double`, `stubr`, `rvcr`, `httptest`
*(checks C01–C04, E04)*; `<name>/<version>/dependencies` for the required-normal
dependency counts *(checks C08, C19)*; `httpmock/0.8.3` for the default feature set
*(check C05)*; `<name>` `crate.recent_downloads` and `crate.downloads`, and
`<name>/reverse_dependencies` `meta.total`, for every adoption figure quoted above
(90-day downloads: `mockall` 27,536,920, `wiremock` 20,169,001, `mockito` 8,806,141,
`httpmock` 5,522,473, `httptest` 1,089,926, `faux` 118,043, `unimock` 29,082, `mry` 11,012,
`stubr` 9,091, `double` 801, `rvcr` 262; reverse dependencies: `mockall` 1,312, `wiremock`
2,916, `mockito` 1,322, `httpmock` 585, `httptest` 55, `unimock` 13, `mry` 4) — codex
2026-09-16 and opus 2026-09-17, agreeing where both collected the same figure.

*GitHub, `https://api.github.com/…`* — `repos/<owner>/<repo>` for `stargazers_count`,
`archived` and `pushed_at` (`asomers/mockall` 1,843 stars, `LukeMathWalker/wiremock-rs` 799
*(check C13)*, `lipanski/mockito` 781, `httpmock/httpmock` 667, `ggriffiniii/httptest` 35);
`search/issues?q=repo:<owner>/<repo>+is:issue+is:open` for `total_count`, never
`open_issues_count` (`mockall` 51, `wiremock` 24, `httpmock` 17, `mockito` 7, `httptest` 1);
`repos/<owner>/<repo>/issues` plus each issue's `/comments` for the responsiveness medians
in the maintenance paragraph; `repos/LukeMathWalker/wiremock-rs/pulls` and `/pulls/172` for
the open-pull-request count and the closed-unmerged MSRV pull request;
`repos/LukeMathWalker/wiremock-rs/issues/173` *(check C20)*; `repos/rust-lang/rust/releases`
for stable 1.98.1, published 2026-09-03, from which the 1.96 floor follows;
`repos/contentauth/c2pa-rs/git/trees/main?recursive=1` for the `truncated` flag and the
`Cargo.lock` path count *(check H02)*, retrieved 2026-09-26. All codex 2026-09-16 or opus
2026-09-17 except H02, retrieved 2026-09-26.

*Advisories* — `https://rustsec.org/packages/<name>.html`, HTTP 404 for every candidate,
with `lock_api` HTTP 200 as the discriminating control *(check C07)*.

*Maintainers' own sources, read at the version or branch named* —
`raw.githubusercontent.com` for `httpmock`'s `Cargo.toml` at `v0.8.3` and at `master`
*(check C06)*, its `platform.yml` *(check C09)* and its `ci.yml` (`cargo hack check
--rust-version`); `wiremock`'s `general.yml` *(check C10)* and `README.md` *(check C11)*;
`mockito`'s `tests.yml` (`MINIMUM_SUPPORTED_TOOLCHAIN` 1.85.0) and `src/mock.rs`
(`match_request`, `with_body_from_request`); `mockall`'s `mockall/Cargo.toml`,
`mockall/src/lib.rs` (async-trait ordering rules; `AnyExpectations : Any + Send + Sync`)
and `.github/workflows/ci.yml` at the `v0.15.0` tag; `docs.rs/httpmock/0.8.3` for
`Then::respond_with` and `When::is_true` *(check C12)*;
`https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/` for let-chain stabilization. Opus
2026-09-17 except where a check is named.

*Adopters* — `tokio-rs/tokio` *(check E01)*, `matrix-org/matrix-rust-sdk` *(check E02)*,
`apache/iceberg-rust` *(check E03)*, `contentauth/c2pa-rs` *(checks C14, H01/H02; H01
re-reads `sdk/Cargo.toml` 2026-09-26, H02 reads the `main` tree 2026-09-26)*,
`awslabs/aws-lambda-rust-runtime`, `XAMPPRocky/octocrab`, `TrueLayer/reqwest-middleware`
and `rust-lang/crates.io`, each cited with its raw manifest URL at the point of use above.

*Programme and source-repo documents* — `research/topics/01-ports-and-adapters-seam/DECISION.md`
*(sha256 pinned, check C17)*; `docs/port/PARAMETERS.md` *(check C16)*;
`docs/port/COMMONALITY.md:125-126`; `docs/port/DIVERGENCE-ANALYSIS.md:176-178`;
`docs/port/areas/testing-coverage.md:9-10`; `docs/port/OWNER-REVIEW.md` (the 2026-09-12
licence ruling); `docs/planning/p02/owner-decisions.md` sections 7 and 11;
`docs/planning/p02/execution-ledger.md:414,640` (the gate-2 reading);
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` *(check C15)*; py at pin
`b08bccfb` *(check C18)* and ts at pin `cb1cbcb2`.

**The org CLI Design Standard v1.4.14** (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`
at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`) binds this port, and **no rule in it
bears on this item**: it contains no rule about test doubles, HTTP stubbing or
dev-dependency selection. Nothing from it is cited.

re-verify: 2027-03-17, or earlier on any of — R05 (`sync-async-execution-model`) publishes
a `DECISION.md`; **a `wiremock` 0.6.6 or later release declares a `rust-version` inside the
floor** (checks C03 / E04 fail), which is the only event that makes it eligible again,
commit activity alone being insufficient — a `pushed_at` date leaving 2025-08-24 (check C13
fails) lifts the maintenance ground only; the newest
non-yanked version of `mockall` or `httpmock` on crates.io stops being 0.15.0 or 0.8.3
(checks C01 / C02 fail), in particular `httpmock` 0.9.0 shipping from master, whose
`respond_with` and `is_true` signatures must then be re-read; Rust stable advances far
enough that the `stable minus 2 minor versions` floor exceeds `httpmock`'s declared 1.88.0
(four minors of headroom at stable 1.98.1); any of `mockall`, `httpmock`, `wiremock`,
`mockito` gains a RustSec advisory (check C07 fails); `mockito` ships a release declaring
`rust-version` 1.85 **and** adds a macOS CI lane, which would match `httpmock` on gate 4
with a lighter dependency tree and require a re-rank; or R01 is revised such that the port
stops being a trait or the HTTP adapter stops performing real I/O, which retires member 3
entirely.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92

No parameter is owned by this item: the prompt's `## Couplings` section carries an empty
`owns:` line. **No `CONFLICT:` lines** — neither raw report raised one, and this decision
raises none.

How the parameters bear on the decision. `http-transport-injection-seam` is consumed
verbatim and needs no change: member 1 supplies `ProjectsPort` implementors, member 2
generates one, and member 3 stubs the upstream *below* the port rather than patching a
transport *at* it — the value's clause "never by patching a transport" constrains how
doubles reach the **port**, and a loopback HTTP server is not a patch of any transport.
`msrv-policy` is the binding gate-2 rule, and it is the parameter that decides F120: at
stable 1.98.1 the floor is 1.96, the highest declared `rust-version` across the selected
members is `httpmock`'s 1.88.0, four minors below it, and both selected members' whole
resolved dependency trees were compiled at 1.96.0 to prove the tree half — `httpmock`'s in
the feature-off run (D01, G01) and `mockall`'s in the feature-on run (D02, G02). Six
surveyed crates declare no `rust-version` at all — `wiremock`, `httptest`, `mry`, `double`,
`stubr`, `rvcr` (E04) — and under the strict reading the programme applies they do not
clear the gate, which is why the crate the owner reference names is excluded rather than
ranked. `target-os-matrix` is what separates `httpmock` from `mockito` at gate 4, and it is
why this synthesis compiled `mockall` on macOS rather than inferring it. `rust-edition`
constrains nothing here — editions are per-crate, so an `edition = "2024"` package consumes
`mockall` 0.15.0 (`edition = "2021"`) and `httpmock` 0.8.3 (`edition = "2021"`, check C06)
without friction, which the probe crate's own `edition = "2024"` manifest demonstrates
(D01–D03). `license` is
recorded but **not evaluated**: gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `cargo 1.96.0 (30a34c682 2026-05-25)` and
`rustc 1.96.0 (ac68faa20 2026-05-25)` through `rustup`, the `msrv-policy` floor; Darwin
26.4 arm64; `/usr/bin/grep` is `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`;
`shellcheck` and `gh` on `PATH`, `gh` authenticated on this machine.

**The template was not built, and nothing here implements the recommendation.** The
template does not exist, P03 builds it, and the role forbids building the thing being
recommended. Revision 1 said "nothing was compiled"; revision 2 compiles one thing and it
is worth being exact about what: a **throwaway probe crate in a temporary directory outside
this repository**, holding one two-method trait named `ProbePort`, one `#[automock]`
attribute, and two tests, deleted when the script exits. It is not a seam, a service, an
acceptance script or a template scaffold — it is the "confirm a version pin exists and
installs" check the role permits, and R01 closed the identical macOS gap for `serde` the
same way. What it proves is stated narrowly beside each claim; what it does not prove stays
in the unproven table under `## Engines`.

**Working directory.** Any — each script resolves the repository root from its own path, so
all five run from a `git archive HEAD` extraction as well as from the worktree.

**Commands, and what each produced.** Paths are relative to the run directory
`research/runs/R48/2026-09-17T020714Z-f9e4f950ea82/`.

| # | Command | Result | Log |
|---|---|---|---|
| 1 | `bash review/evidence/r48-claims-check.sh` | **20 checks, 20 PASS, 0 FAIL, 0 SKIP; exit 0** | `review/evidence/r48-claims-check.log` |
| 2 | `bash review/evidence/r48-r2-msrv-macos-spike.sh` | **6 checks, 6 PASS, 0 FAIL, 0 SKIP; exit 0** | `review/evidence/r48-r2-msrv-macos-spike.log` |
| 3 | `bash review/evidence/r48-r2-citations-check.sh` | **5 checks, 5 PASS, 0 FAIL, 0 SKIP; exit 0** | `review/evidence/r48-r2-citations-check.log` |
| 4 | `bash review/evidence/r48-r3-tree-msrv-relabel.sh` | **4 checks, 4 PASS, 0 FAIL, 0 SKIP; exit 0** | `review/evidence/r48-r3-tree-msrv-relabel.log` |
| 5 | `bash review/evidence/r48-r4-c14-narrow.sh` | **3 checks, 3 PASS, 0 FAIL, 0 SKIP; exit 0** | `review/evidence/r48-r4-c14-narrow.log` |

Scripts 1 to 4 and every log committed through revision 3 are **byte-identical to
revision 3**, which the round-3 empirical audit reran green in full even as it rejected on
E-1; script 5 is the only new file, added by revision 4. Its checks are numbered
`H01`–`H03` so no identifier collides with `C01`–`C20`, `D00`–`D05`, `E01`–`E05` or
`G00`–`G03`.

**Script 4 — the attribution correction** (`review/evidence/r48-r3-tree-msrv-relabel.log`).
It gathers no new evidence about any crate: it re-runs script 2's first two commands on the
same probe crate and asserts, directly, which run compiles which tree. **G00** repeats the
outside-the-repository check. **G01** asserts the feature-off run exits 0 with 1 passing
test, **1** `Compiling httpmock v0.8.3` line and **0** `Compiling mockall v` lines — so that
run establishes `httpmock`'s tree and nothing about `mockall`'s. **G02** asserts the
feature-on run exits 0 with 2 passing tests, **1** `Compiling mockall v0.15.0` line and
**1** `Compiling mockall_derive v0.15.0` line — so that run is where `mockall`'s tree is
established. This exists because the D01 `PASS` line in script 2's committed log is wrongly
worded and that log is not edited; see the revision-3 note above.

**Script 5 — the compatibility narrowing** (`review/evidence/r48-r4-c14-narrow.log`).
It gathers no new evidence about any crate's fitness: it re-runs C14's fetch on the same
manifest and asserts, directly, the narrowed claim. **H01** asserts the same 1-and-1 line
counts C14 counted, as co-declared semver requirements rather than a joint resolution.
**H02** asserts the negative that carries the narrowing — the `main` tree reports
`truncated = false` with **0** paths ending in `Cargo.lock` — failing closed on a
truncated or empty response. This exists because the C14 `PASS` line in script 1's
committed log is wrongly worded and that log is not edited; see the revision-4 note above.

| Check | What it asserts | Endpoint (retrieved 2026-09-26) |
|---|---|---|
| H01 | `contentauth/c2pa-rs` `sdk/Cargo.toml` declares 1 `mockall = "0.15.0"` line and 1 `httpmock = "0.8.3"` line — the C14 counts re-asserted as co-declared semver requirements | `https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml` |
| H02 | the `main` tree reports `truncated = false` with **0** paths ending in `Cargo.lock` — the repository commits no lockfile, failing closed on a truncated or empty response | `https://api.github.com/repos/contentauth/c2pa-rs/git/trees/main?recursive=1` |
| H03 | `shellcheck` reports no findings and exits 0 for all five evidence scripts | local files |

| Check | What it asserts | Endpoint (retrieved 2026-09-17; H-check facts 2026-09-26) |
|---|---|---|
| C01–C04 | newest non-yanked release and declared `rust-version` for `mockall` (0.15.0 / 1.77.0), `httpmock` (0.8.3 / 1.88.0), `wiremock` (0.6.5 / **none declared**), `mockito` (1.7.2 / 1.70) | `https://crates.io/api/v1/crates/<name>/versions` |
| C05 | `httpmock` 0.8.3's default feature set is exactly `["cookies"]`, so `default-features = false` is a real change | `https://crates.io/api/v1/crates/httpmock/0.8.3` |
| C06 | the v0.8.3 tag's manifest has **0** `unsafe_code` lines and `edition = "2021"`, while master has **1** — `unsafe_code = "forbid"` and edition 2024 are unreleased 0.9.0 facts | `https://raw.githubusercontent.com/httpmock/httpmock/{v0.8.3,master}/Cargo.toml` |
| C07 | RustSec returns HTTP 404 for all four candidates **and** HTTP 200 for the control `lock_api` (which carries `RUSTSEC-2020-0070`) — the control is what makes 404 evidence of no advisory rather than evidence of a broken probe | `https://rustsec.org/packages/<name>.html` |
| C08 | `mockall` 0.15.0's required normal dependencies are exactly `cfg-if downcast fragile mockall_derive predicates predicates-tree` — no `tokio`, no `hyper` | `https://crates.io/api/v1/crates/mockall/0.15.0/dependencies` |
| C09 | `httpmock`'s own CI runs `os: [ubuntu-latest, macos-latest, windows-latest]` — the gate-4 discriminator | `https://raw.githubusercontent.com/httpmock/httpmock/master/.github/workflows/platform.yml` |
| C10 | `wiremock-rs`'s own CI has 0 macOS mentions across 5 `ubuntu-latest` jobs, so its gate 4 rests on adopter evidence | `https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/.github/workflows/general.yml` |
| C11 | `wiremock`'s **own** README comparison table records `wiremock: Async`, `httpmock: Async/Sync`, `mockito: Async/Sync` — the R05 coupling, in the maintainer's own words | `https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/README.md` |
| C12 | the released 0.8.3 (not master) carries `Then::respond_with` and `When::is_true`, the dynamic responder and closure matcher the F121 suite needs | `https://docs.rs/httpmock/0.8.3/httpmock/struct.{Then,When}.html` |
| C13 | `LukeMathWalker/wiremock-rs` is `archived: false` with a `pushed_at` date of **2025-08-24** — the maintenance ground, which in revision 2 is a supporting ground and no longer the ranking ground, `wiremock` being excluded on gate 2 | `https://api.github.com/repos/LukeMathWalker/wiremock-rs` |
| C14 | `contentauth/c2pa-rs` **declares** `mockall = "0.15.0"` **and** `httpmock = "0.8.3"` as version requirements in one manifest (`sdk/Cargo.toml`) — co-declaration evidence, re-asserted with narrowed wording by H01; the C14 `PASS` line's phrase "resolve in one lockfile" is superseded, because those lines are semver requirements and the repository commits no `Cargo.lock` (H02), and script 1's committed log is not edited | `https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml` |
| C15 | the owner reference document in this run's `inputs/` carries the C12 Testing row naming `wiremock` and the pin line `wiremock = "0.6"` — the row reconciled above | `inputs/owner-reference-axum-companion-stack-2026-09-16.md` |
| C16 | all **5** `- assumes` lines in this file are byte-identical to column 4 of the matching `docs/port/PARAMETERS.md` row — the publication guard | `docs/port/PARAMETERS.md` |
| C17 | the sha256 of `research/topics/01-ports-and-adapters-seam/DECISION.md` matches `inputs/prerequisites.json` `R01.decision` — the R01 read here is the revision this run pinned | repository files |
| C18 | py at pin `b08bccfb` pairs `responses>=0.25` with the comment "HTTP mock for the port-contract suite" and its contract-suite docstring names "the in-memory fake and the real HTTP adapter" — the evidence under `BASELINE-REVIEW: F120` | `git -C ~/c/py-launch-blueprint show b08bccfb:…` |
| C19 | required normal dependency counts: `wiremock` **15**, `mockito` **16**, `httpmock` **25** — the gate-6 figures, and the correction of the opus report's 26 for `httpmock` | `https://crates.io/api/v1/crates/<name>/<version>/dependencies` |
| C20 | `LukeMathWalker/wiremock-rs` issue **#173**, title "Error: `let` expressions in this position are unstable", opened 2025-08-27, state closed — the evidence that `wiremock`'s *effective* MSRV is at least 1.88 despite declaring none | `https://api.github.com/repos/LukeMathWalker/wiremock-rs/issues/173` |

**Script 2 — the compile spike** (`review/evidence/r48-r2-msrv-macos-spike.log`). It builds
a throwaway probe crate in a temporary directory outside this repository — `edition =
"2024"`, `rust-version = "1.96.0"`, `mockall = { version = "=0.15.0", optional = true }`
behind `[features] mock = ["dep:mockall"]`, and `httpmock = { version = "=0.8.3",
default-features = false }` as a dev-dependency — and deletes it on exit.

| Check | What it asserts | Toolchain |
|---|---|---|
| D00 | the probe directory is outside the repository tree, so no template, seam or scaffold is created inside it | — |
| D01 | `cargo test` with the feature **off** exits 0 with exactly 1 passing integration test — **`httpmock`'s whole resolved dependency tree compiles at the `msrv-policy` floor**, which is `httpmock`'s half of gate 2's tree question, and the gated `mockall` test is correctly invisible without the feature. It establishes **nothing about `mockall`'s tree**, which is behind the off-by-default feature and absent from this build graph; D02 is the check that carries that. Revision 2's wording, "**both selected members' whole resolved dependency trees compile at the `msrv-policy` floor**", is superseded here and re-labelled by G01 | `cargo 1.96.0` |
| D02 | `cargo test --features mock` exits 0 and the named test passes — **`mockall`'s whole resolved dependency tree compiles at the floor** (this is the check that carries `mockall`'s half of gate 2's tree question), `#[automock]` expands, the generated mock satisfies the trait's `Send + Sync` supertraits, and `Arc::new(mock) as Arc<dyn Trait>` compiles and returns the programmed value under `.with(eq(7)).times(1)` | `cargo 1.96.0` |
| D03 | the same lockfile passes `cargo test --locked --features mock` at current stable — **gate 4's macOS half for `mockall` 0.15.0, observed** | `cargo 1.98.0` |
| D04 | the resolved `Cargo.lock` pins are exactly `mockall 0.15.0`, `mockall_derive 0.15.0`, `httpmock 0.8.3` — the versions recommended are the versions that built | — |
| D05 | `cargo tree -i mockall` exits non-zero with "did not match any packages" when the feature is off and prints `mockall v0.15.0` when it is on — the off-by-default gate keeps the crate out of the build graph, and the two invocations differ, so the check can fail | `cargo 1.96.0` |

**Script 3 — citations and the uniform gate-2 reading**
(`review/evidence/r48-r2-citations-check.log`).

| Check | What it asserts | Endpoint (retrieved 2026-09-17) |
|---|---|---|
| E01 | `tokio-rs/tokio` declares `mockall = "0.13.0"` and names `macos-latest` in its own CI — corroboration at 0.13.0, explicitly **not** at the recommended 0.15.0 | `raw.githubusercontent.com/tokio-rs/tokio/master/{tokio/Cargo.toml,.github/workflows/ci.yml}` |
| E02 | `matrix-org/matrix-rust-sdk` declares `wiremock = { version = "0.6.5" …}` and names `macos-latest` in its own CI — the gate-4 sentence in `wiremock`'s *Excluded by gate* entry | `raw.githubusercontent.com/matrix-org/matrix-rust-sdk/main/{Cargo.toml,.github/workflows/ci.yml}` |
| E03 | `apache/iceberg-rust` declares `mockito = "1"` and names `macos-latest` in its own CI — `mockito`'s gate-4 disposition; the build-only/tests-ubuntu-only refinement is carried from opus and **not** asserted | `raw.githubusercontent.com/apache/iceberg-rust/main/{Cargo.toml,.github/workflows/ci.yml}` |
| E04 | newest non-yanked version and declared `rust-version` for **all eleven** surveyed crates in one pass — five declare one inside the floor (`mockall`, `httpmock`, `mockito`, `unimock`, `faux`); six declare none and fail gate 2 (`wiremock`, `httptest`, `mry`, `double`, `stubr`, `rvcr`). This is the check that makes the gate-2 rule uniform | `https://crates.io/api/v1/crates/<name>/versions` |
| E05 | `shellcheck` reports no findings and exits 0 for **all three** evidence scripts in this run, its output being 0 lines long | local files |

**Reproducibility, stated after re-running all five scripts against their committed logs
rather than before.** In every log, each line beginning `# ` is volatile — the retrieval
timestamp, the host and toolchain banners, and in script 2 the appendix carrying cargo's
raw output and the resolved lockfile, since cargo prints compile order, wall-clock times
and hashed artifact paths, and an MSRV-aware resolve may pick different transitive **patch**
versions on a later day. Every `PASS`/`FAIL`/`SKIP` line and every `RESULT:` line asserts
on a stable field and reproduces byte-for-byte. The rule for comparing across a rerun,
applied to each of the five:

```
bash review/evidence/<script>.sh > /tmp/rerun.log
diff <(/usr/bin/grep -v '^# ' /tmp/rerun.log) <(/usr/bin/grep -v '^# ' review/evidence/<script>.log)
```

which was run for all five and was empty each time. **Scoped, because revision 1 scoped it
too widely:** no download counter, star count, open-issue count or active repository's
`pushed_at` literal is printed in any of the five **scripts' output**. Figures of those
kinds do appear in this decision's prose, where each now carries its endpoint and retrieval
date under **Sources** above; revision 1's claim that they are not "printed anywhere" was
true of the log and false of the document, and is superseded.

Three checks are designed to fail later, by intent, and their failure is a signal rather
than a defect. **C13** asserts the frozen date 2025-08-24: the day
`LukeMathWalker/wiremock-rs` is pushed again, C13 FAILs and the maintenance ground lapses —
which does **not** on its own re-admit the crate, because the gate-2 ground stands until
`E04` reports a declared `rust-version`. **E01–E03** assert each adopter's currently
declared dependency version, so an upstream bump FAILs the check and tells the reader the
cited figure needs updating. **C01/C02**
assert the current newest non-yanked versions: a FAIL there means the pin this decision
recommends is no longer the newest release. **C18** is the one check that reads outside
this repository: it prints `PASS` on a machine carrying the `py-launch-blueprint` clone at
pin `b08bccfb`, which is where the committed log was produced, and prints `SKIP` by name
where that clone is absent. The whole script was also re-run from a clean `git archive
HEAD` extraction into a temporary directory — a tree with no `.git`, carrying this commit's
`review/DECISION.md` and `review/evidence/r48-claims-check.sh` at their paths — and
produced `PASS` lines identical to the committed log and exit status 0; that run is
recorded in `review/evidence/r48-archive-rerun.log`, with its procedure in the log's own
header; that log is a revision-1 artifact and is carried forward unchanged, as is
`review/evidence/r48-r2-archive-rerun.log`, which recorded the same exercise over the three
scripts that existed in revision 2 (31 `PASS` lines, three `RESULT: all checks passed (0
FAIL)` lines). `review/evidence/r48-r3-archive-rerun.log` recorded the same exercise over
the four scripts of revision 3 — 35 `PASS` lines, four `RESULT` lines — and is carried
forward unchanged. **All five scripts** were re-run from a fresh clean extraction for
revision 4 — 38 `PASS` lines, five `RESULT: all checks passed (0 FAIL)` lines, exit 0 each,
every stable line identical to the corresponding committed log — recorded in
`review/evidence/r48-r4-archive-rerun.log`. Outside this repository the five scripts reach six network hosts and nothing
else: `crates.io` and `static.crates.io` (the latter through `cargo`'s own downloads in
script 2), `raw.githubusercontent.com`, `rustsec.org`, `docs.rs` and `api.github.com`
(reached through the machine's authenticated `gh`). Every check whose toolchain may be
absent — `gh`, `shellcheck`, `rustup`'s 1.96.0 toolchain, the Homebrew `cargo`, and the
`py-launch-blueprint` clone — prints `SKIP` **by name** rather than passing vacuously.

All five scripts set `set -uo pipefail`, invoke `/usr/bin/grep` by absolute path, name that
binary beside every count they print, check each `curl` or `cargo` status separately rather
than trusting a pipeline, and contain no personal email in any `User-Agent`. **That they
pass `shellcheck` with no findings is now executed and logged, not asserted:** check E05
runs `shellcheck` over the three scripts that existed in revision 2 and asserts both a zero
exit and zero lines of output, check G03 does the same over the four that existed in
revision 3, and check H03 does the same over all five.
Revision 1 claimed the `shellcheck` result in prose while no script ran it and no log
recorded it; that claim is superseded by E05.

## Engines

Two engines, the Focused tier: no Doxa.

- **codex** `raw/codex.md` — Codex `gpt-5.6-terra`, sha256 `b5bf9725…`, 10 H3 sections,
  figures retrieved **2026-09-16**. Recommends `mockall = "0.15.0"` in `[dev-dependencies]`
  plus `httpmock = "0.8.3"` **conditionally**, held in reserve for R01's branch. Raised no
  `BASELINE-REVIEW:` and no `CONFLICT:`.
- **opus** `raw/opus.md` — Claude Opus 5, sha256 `7d40a913…`, 10 H3 sections, 3 members,
  figures retrieved **2026-09-17 (UTC)**. Recommends hand-written fakes plus
  `RecordingPort` as the default, `mockall` 0.15.0 behind an off-by-default `mock` feature,
  and `httpmock` 0.8.3 unconditionally because the prompt's condition is met. Carries
  `BASELINE-REVIEW: F120` and an accompanying note on R01's F121 row; `CONFLICT: none`.

**The engines agree on the two crates and on their versions.** Both name `mockall` 0.15.0
and `httpmock` 0.8.3; both rank `mockito` 1.7.2 the HTTP runner-up; both keep hand-written
fakes as the normal mechanism; both report that nothing was compiled. Seven numbered items
follow: items **1 to 4** and **7** are genuine disagreements between the engines, each
settled here on evidence rather than on a vote; items **5 and 6** are corrections to
figures a single engine reported, which no disagreement raised and which this synthesis
found by re-reading the source. One further disagreement — over the one
issue-responsiveness figure both engines computed, `mockall`'s — is adjudicated under
*Evidence the two engines did not both collect* below, where the engines' responsiveness
coverage is already compared, rather than as a numbered item.

1. **Does the HTTP condition fire?** Codex writes "Do not add an HTTP-mocking dependency
   for R01's registered trait/fake branch"; opus says the condition is met and puts
   `httpmock` in the stack. **Settled for opus, on R01's own text, not on inference.**
   R01's F121 row commits the template to one contract function "called from `tests/` once
   per adapter" and names two adapters, one of which is the HTTP adapter in
   `src/core/adapters/http.rs`; and R01's own unproven-claims table asks for a test that
   starts "the real upstream (or a bound test listener)". Codex read R01's cross-repo
   sentence ("the recommended seam needs no HTTP-mocking crate") correctly *at the port
   seam* and missed the adapter *below* it. **Disposition of `BASELINE-REVIEW: F120`:
   carried in full under `### Principles and implementation`, as a narrowing of R01's
   wording with no edit to R01 and no `CONFLICT:`.** R01's precedent for this placement is
   its own baseline-review paragraph. No separate finding is minted for F121: that row is
   R01's and is settled; it is cited here as evidence for the F120 finding.
2. **Where `mockall` is declared.** Codex puts it in `[dev-dependencies]`; opus makes it
   `optional = true` under `[dependencies]` behind `[features] mock`. **Settled for opus.**
   The gated shape is the one R01 explicitly reserved for this item (the
   `crates_io_github` pattern), and it is forced by a language constraint: integration
   tests under `tests/` link the library as an *external* crate, so a mock generated under
   `#[cfg(test)]` — or a `[dev-dependencies]` declaration that `dep:mockall` cannot name —
   is invisible to them. Codex's shape is sound only for a mock redeclared inside a test
   file, which neither engine recommends.
3. **How `wiremock` leaves the shortlist.** Codex lists it under *Excluded by gate*
   (`raw/codex.md:115`: "its release metadata declares no `rust_version`; this fails the
   evidence gate"); opus keeps it on the qualified shortlist at rank three on fit grounds.
   **Settled for codex on the gate.** Revision 1 settled this for opus and recorded
   codex's framing as overstated, on a permissive reading of gate 2 that the programme had
   already withdrawn at `docs/planning/p02/execution-ledger.md:414` and replaced at `:640`.
   Under the strict reading an absent declared `rust-version` does not clear the bar, so
   `wiremock` 0.6.5 is **excluded on gate 2** (C03, E04) and revision 1's sentence
   "`wiremock` fails no applicable gate: gate 2 passes on substance" is superseded. What
   survives from opus is everything *other* than the gate: its gate-3, gate-4, gate-5 and
   gate-6 dispositions all hold, its `at-risk` maintenance verdict holds on its own
   signals, and its async-only finding (C11) holds — those are now the supporting grounds
   in the C12 reconciliation rather than the leading ones. The same rule is applied in the
   same pass to `httptest`, `mry`, `double`, `stubr` and `rvcr` (E04), so no candidate is
   read two ways.
4. **What a RustSec 404 means.** Codex records advisory status as "unverified" because
   every `rustsec.org/packages/<name>.html` returned HTTP 404; opus and R01 read 404 as
   RustSec's "no advisory" response. **Settled for opus, and made evidenced rather than
   assumed**: check C07 adds a control, `lock_api`, which carries `RUSTSEC-2020-0070` and
   returns HTTP 200 from the same probe in the same run. Gate 3 therefore passes for all
   four candidates.
5. **`httpmock`'s `unsafe` posture and edition — a correction to opus, not a tie-break.**
   Opus reports `unsafe_code = "forbid"` and `edition = "2024"` as facts about the
   recommended crate, having read them from `master/Cargo.toml`. Master is already
   versioned **0.9.0**. Check C06 re-read the **v0.8.3 tag's** manifest: it carries **no**
   `unsafe_code` lint and declares `edition = "2021"`. The gate-3 row above is restated
   accordingly — for the released 0.8.3 the posture is "safe Rust over `hyper`/`tokio`,
   stated from manifests, not audited" — and the `default-features = false` recommendation
   is *unaffected*, because C05 confirms `default = ["cookies"]` on the released version
   from the registry rather than from master.
6. **`httpmock`'s dependency count — a second correction to opus.** Opus states 26
   required normal dependencies for `httpmock` 0.8.3. Check C19 re-read the endpoint for
   all three HTTP candidates in one pass: `wiremock` **15**, `mockito` **16**, `httpmock`
   **25**. The gate-6 row is restated with 25. The correction does not change the ranking
   — `httpmock` still carries the heaviest tree of the three, which is the honest cost the
   decision records against the selected member. Codex offered no dependency counts, so
   this is a correction rather than a disagreement settled.
7. **Whether `mockall`'s gate 4 can be closed by citation.** Codex says it cannot:
   `raw/codex.md:61` records that `mockall`'s "public CI shown on Ubuntu stable/MSRV does
   not demonstrate the required macOS lane, so the template must prove its own
   Ubuntu/macOS test matrix before acceptance". Opus records gate 4 as passing by adopter
   evidence while conceding the adopter carries 0.13.0. Revision 1 followed opus and
   omitted codex's position from these numbered items; both are corrected here.
   **Settled for codex on the reasoning, and then closed by executed evidence rather than
   by demotion.** Codex is right that neither the crate's own CI nor a 0.13.0 adopter
   demonstrates the required lane: the workflow at the **v0.15.0 tag** carries 0 macOS
   mentions, and E01 confirms `tokio-rs/tokio`'s pin is `0.13.0`. So this synthesis
   compiled the recommended version instead: D02 and D03 build and run `mockall` 0.15.0's
   generated mock on Darwin 26.4 aarch64 at 1.96.0 and at 1.98.0, carrying `mockall`'s
   whole resolved tree with them, while D01 does the same for `httpmock`'s tree at the
   floor (re-confirmed and re-labelled by G01 and G02). Gate 4 is therefore
   `passes` on an observed macOS compile plus the crate's own `ubuntu-latest` CI, and
   revision 1's "**inferred, not observed**" cell is superseded. Codex's wider point
   stands and is recorded in the unproven table: the template must still prove its own
   two-OS matrix in P03, because a probe crate on a developer's Mac is not a GitHub
   `macos-latest` runner executing the template's suite.

**Evidence the two engines did not both collect.** Codex did not compute `httpmock`'s
issue responsiveness and said so, recording it as a re-verification task rather than
inferring a score; opus computed it (median 10.53 days, 5 of 10 unanswered, 2026-09-17) and
it is the honest cost recorded against the selected member. Opus computed responsiveness
for all four HTTP candidates and for `mockall` and `faux`; codex computed it for `mockall`
only.

**The one responsiveness figure both engines computed disagrees, and is adjudicated here.**

| Engine | `mockall` figure | Sample | Endpoint | Retrieved | Source |
|---|---|---|---|---|---|
| codex | median **4.98** days, **1** of 10 unanswered | "the ten latest open non-PR issues" | `https://api.github.com/repos/asomers/mockall/issues?state=open&sort=created&direction=desc&per_page=40`, plus each issue's `/comments` | 2026-09-16 | `raw/codex.md:93` |
| opus | median **1.18** days, **0** of 10 unanswered | "the 10 most recently opened issues" | `repos/asomers/mockall/issues?state=all&sort=created&direction=desc`, plus each issue's `/comments` | 2026-09-17 | `raw/opus.md:660-663` |

The two engines drew different samples: codex filtered to `state=open`, and opus did not
filter by state (`state=all`). **Settled for opus, on the prompt's rubric.** The prompt
defines the figure over the "10 most recently opened issues" (`inputs/prompt.md:55`), with
no restriction to issues still open, and opus's `state=all` sample is the one that
implements that definition. A `state=open` sample leaves out every recent issue that has
since been closed, including those a maintainer answered and resolved. By reasoning about
the sampling rule, not by measurement, that omission tends to raise the median and the
unanswered count, because it keeps the issues still waiting and drops those already
resolved. The one-day gap between retrievals is not the cause: opus records its sample
window as "2025-10-02 → 2026-08-20" (`raw/opus.md:663-664`), so the newest issue in the
`state=all` sample was opened 27 days before either retrieval, and a one-day difference
could not change which ten issues were most recently opened. This is why the
maintenance paragraph under `## Decision` uses opus's 1.18 days. **The verdict does not
depend on the choice:** `mockall` is `active` under either figure — not archived, pushed
2026-09-02, 0.15.0 released 2026-06-28, which both engines report identically — so no
maintenance verdict, gate disposition or member moves.

The registry and repository-metadata figures that both engines collected — downloads,
reverse dependencies, stars, `archived`, `pushed_at` and release dates — agree between the
codex retrieval of 2026-09-16 and the opus retrieval of 2026-09-17. Revision 5's sentence
"Where the two report the same figure from the same endpoint on different days (2026-09-16
and 2026-09-17), the figures agree" is superseded by this paragraph: it was literally true,
because the two responsiveness figures came from different endpoints, but it left a reader
believing that the one shared responsiveness figure matched.

**Unproven, and left for P03 to prove in the real template.** Neither engine compiled
anything. This synthesis compiled one throwaway probe crate outside this repository, which
closes three rows revision 1 listed as unproven and narrows a fourth; the rest are
proposed, and the template's own suite is where they are settled.

| Claim | Status | What would prove it |
|---|---|---|
| A `mockall` mock generated for a `Send + Sync` trait erases to `Arc<dyn Trait>` | **Proven for the mechanism** (D02): the probe crate's test compiles and passes, and compiling is the proof. **Still unproven against R01's actual `ProjectsPort`**, whose method set and any async form differ | One `--features mock` test in the template that erases a `MockProjectsPort` to `Arc<dyn ProjectsPort>` and drives the CLI; R01 records `error[E0038]` as the failure mode |
| `mockall` 0.15.0 builds and its generated mocks run on macOS | **Proven at the recommended version** (D02, D03) on Darwin 26.4 aarch64 at 1.96.0 and 1.98.0 — the architecture `macos-latest` runs today, **but not the GitHub runner image**, and not the template's suite | The template's own `macos-latest` CI lane running `cargo test --features mock`, which is the point codex's `raw/codex.md:61` makes and which stands |
| Both selected members' dependency trees are within the MSRV floor | **Proven, by two checks and not one:** `httpmock`'s 25 required crates including `tokio` and `hyper` compile at 1.96.0 in the feature-off run (D01, G01), and `mockall`'s six compile at 1.96.0 in the feature-on run (D02, G02) — `mockall` is behind an off-by-default feature, so it is absent from the feature-off graph, which D05 states from the other side. Revision 2 credited D01 alone with both trees; that attribution is superseded. **Caveat:** `cargo` 1.96's MSRV-aware resolution chose that tree, so this proves a satisfying resolution exists, not that every newest transitive version is within the floor | The template's own `Cargo.lock` compiled on an MSRV CI lane, which is where the pinned tree becomes the tested one |
| `mockito` 1.7.2's dependency-tree MSRV | **Unproven.** Only its declared crate-level `rust-version` was read (C04, E04); no `mockito` tree was resolved or compiled here | Resolving and compiling a `mockito` tree at the floor, the way D01 does for `httpmock`'s and D02 for `mockall`'s — worth doing only if `mockito` is promoted |
| `httpmock` servers do not collide when tests run in parallel on both OSes | **Unproven.** No `MockServer` was started anywhere in this run; the spike links `httpmock` and names its types without binding a port | `cargo test -- --test-threads=8` on `ubuntu-latest` and on `macos-latest` |
| The F121 contract suite passes for **both** adapters from one seed set, and a renamed `data` key fails the HTTP case while the in-memory case still passes | **Unproven.** This is the check that would falsify the recommendation | `cargo test --test port_contract`, then rename the stub's `data` key to `results` and re-run |
| The gated feature really keeps `mockall` out of the default build graph | **Proven for the mechanism** (D05): with the feature off `cargo tree -i mockall` reports no such package and exits non-zero; with it on it prints `mockall v0.15.0`. **Unproven for the template**, which has a different manifest | `cargo tree --edges dev -i mockall` in the template with the feature off; `cargo tree --edges normal` for `httpmock`; `cargo build --release` with and without `--features mock` compared for size |
| Compile-time and binary-size cost of either member | **Unproven, and no figure is offered.** The spike compiles a two-method probe crate, not the template, so its wall-clock times would misrepresent the cost; measuring it honestly requires the template | A P03 measurement on the real workspace |
| The three members compile and pass together inside the real template | **Unproven.** The strongest available evidence short of that is `contentauth/c2pa-rs` declaring both version requirements in one manifest (C14, narrowed by H01/H02) — co-declaration, not a jointly resolved lockfile. Revision 3's wording, "resolving both crates at exactly these versions in one manifest", is superseded | P03's first green CI run |

**Where the evidence is incomplete, stated plainly.** `mockito`'s macOS *test execution*
could be evidenced by neither engine and is not evidenced here either — its own CI has no
macOS lane and its best adopter runs macOS only in build jobs — which is the whole of why
it is the runner-up rather than the selection; that is recorded as unverified, not as a
failure. Its dependency-tree MSRV is likewise unproven, as the table above now records.
`unsafe` posture for every candidate is stated from manifests and documentation, never from
a line-by-line audit; in particular `httpmock`'s `unsafe_code = "forbid"` is a property of
its unreleased 0.9.0 master and **not** of the recommended 0.8.3 (C06). No performance
figure of any kind is offered. The probe crate proves what D00–D05 say it proves and
nothing wider: it is not the template, its timings are not the template's, and it starts no
server. And the choice against `wiremock` differs from an owner-supplied document: in
revision 2 the leading ground is a fitness gate the programme's own ruling makes decisive
rather than a fit preference, so overturning it means waiving gate 2 or waiting for a
`wiremock` release that declares a `rust-version` — the R05 answer alone no longer suffices,
which is a narrowing of what revision 1 told the owner.
