# 2026-09-27 — R83 — openapi-contract-fuzzing (crate, Focused) — decision (revision 4)

**Revision note, revision 4.** Revision 4 answers the judgment audit of revision 3
(`review/audit-fable.r3.md`, verdict `reject`, two blocking findings, JF3-1-1 and JF3-1-2). The
empirical audit of revision 3 (`review/audit-claude.r3.md`) approved with no unresolved findings.
Revision 3 is sha256 `9197c005a053eb476fe3ed4e7905700f243a3dd5f357082d7698de908ad5f331`, preserved
byte-identical at `review/R83-r3-snapshot.md`. **The recommendation does not move**: it is still
`oas3 = "0.22.0"` as a `[dev-dependencies]` entry of `crates/web`, with R33's `proptest` 1.11.0
and R69's `tower` 0.5.3 `oneshot` as resident companions. Both findings are text repairs inside
the design table, the migration table and acceptance criterion 7. No evidence script, log or fixture was changed or
rerun for revision 4, because no line the evidence cites moved.

| Finding | Disposition in this revision |
|---|---|
| **JF3-1-1** (blocking; JF-1) — the Generation row builds strategies from path-parameter and body schemas only, yet promises R72's `limit` query-parameter targets `0`, `1`, `100` and `101`; the `contract_fuzz.rs` and `common/mod.rs` migration rows omit query parameters too | **Accepted.** The Generation row's inputs are now the operation's `in: path`, `in: query`, `in: header` and `in: cookie` parameter schemas plus its `application/json` request-body schema. Header and cookie parameters are stated **in**, which is what the `## Empirical check` gap list already required P03 to prove ("Query, header and cookie parameter generation"). The `crates/web/tests/contract_fuzz.rs` row now names the generated parameters in its request construction and failure message, and the `crates/web/tests/common/mod.rs` row names the four parameter locations. The coverage-boundary paragraph is unchanged, because it describes the probe. |
| **JF3-1-2** (blocking; JF-1) — acceptance criterion 7 requires a boundary-invalid case just outside each declared bound, but the Case count row gives the mode 16 random draws shared by every constraint arm of the operation | **Accepted; the audit's option (b) is taken.** The boundary-invalid mode no longer draws its arm from a `Union`. It **enumerates one case per declared constraint arm, deterministically**: each case takes a valid base case drawn from the valid strategy and applies that arm's single violation. The Case count row now states that this mode's count is the number of declared arms, not 16, and the valid mode keeps 16 random cases. Criterion 7 now says the enumeration covers every arm, so the second half holds by construction in the fuzz run itself. Option (a), making criterion 7 a mapper-only property, was not taken: it would leave the 16-case run unable to promise that `limit=0` and `limit=101` are generated, which the Generation row, the R72 coupling hand-off, the `## Empirical check` gap list and P03 item (10) all state. |

**Revision history.** Revision 1, sha256
`437ad0c97631f53435b1c17e4d6c898d965eb41cb25c51ce862a94c02237d35e`
(`review/R83-r1-snapshot.md`), was rejected by `review/audit-fable.md` on blocking findings F1–F3,
with F4–F5 minor. Revision 2, sha256 `a6e3bfa5…3ec6` (`review/R83-r2-snapshot.md`), answered all
five. It adjudicated the Muse report (D1–D9, new script `muse-adjudication.sh`, 8/8), cited R11 at
revision 7, handed the CI placement to R32, updated R70 and R72, and fixed the SKIP-path defect with
new script `registry-skip-paths.sh` (12/12). Its full disposition table is preserved in
`review/R83-r2-snapshot.md`. Revision 2's empirical audit reran all four scripts at 73 PASS, 0 FAIL,
0 SKIP and approved; its judgment audit rejected on JF2-3-1. Revision 3, sha256 `9197c005…f331`
(`review/R83-r3-snapshot.md`), answered JF2-3-1 by adopting boundary-invalid generation: P2 was
widened, the Generation, Mapper placement and Case count rows gained boundary-invalid arms,
acceptance criteria 2 and 7 were extended, and a D10 row adjudicated Muse's generation scope. Its
full disposition table is preserved in `review/R83-r3-snapshot.md`. Revision 3's empirical audit
reran all four scripts at 73 PASS, 0 FAIL, 0 SKIP and approved; its judgment audit rejected on
JF3-1-1 and JF3-1-2, answered above. Revision 4 is this file; its evidence set is revision 2's,
unchanged.

## Decision

**Status.** This decision is a **proposal validated in the implementation phase** (owner ruling,
2026-09-10). `rs-launch-blueprint` contains no Rust source, no Cargo manifest and no OpenAPI
document today. Everything below records what the research found and what it recommends; P03
builds the template and its CI proves the recommendation. A decision that does not survive
implementation is revised against this recorded research, not researched again from scratch. What
P03 must validate is listed under `## Engines`.

**The finding first, because it is the answer to the prompt's Decision question. No Rust-ecosystem
equivalent of `schemathesis` exists.** No crate generates request cases for every documented
operation directly from an OpenAPI document, drives them at a live service and checks the
responses, at a maturity this template can adopt. Two independent re-verifications, both executed
by this synthesis on 2026-09-19 (UTC) and not carried from the raw report:

- `GET https://crates.io/api/v1/crates?q=schemathesis&per_page=12` returns `meta.total` **0**
  (check `B1`). The same endpoint, same run, returns `meta.total` **107** for
  `q=openapi%20fuzz` (check `B2`), so the zero is the niche and not a broken endpoint.
- The only Rust artefact with visible adoption in the niche, `openapi-fuzzer`, is a **binary, not a
  library**, its newest non-yanked version is **0.2.0 of 2023-08-30**, and it declares **no
  `rust-version`**, which fails fitness gate 2 (checks `B3`, `B4`, `B5`). Its repository
  `matusf/openapi-fuzzer` was last pushed **2024-01-29** (check `B23`), which is the concrete
  signal behind the maintenance verdict `at-risk`.

**Recommendation — an in-repository contract-fuzz harness anchored on `oas3`.** The named crate and
version range this item must deliver is **`oas3 = "0.22.0"`** — Cargo's caret semantics make that
`>=0.22.0, <0.23.0` — declared as a **`[dev-dependencies]` entry of `crates/web`**. The two
companions are already resident and are not new decisions here: `proptest = "1.11.0"`, published by
R33 (`research/topics/33-property-and-snapshot-testing/DECISION.md`), is the generative engine; and
`tower = "0.5.3"` with feature `util`, from R69 revision 10's owned `web-extra-surface` value, is
the in-process transport through `tower::ServiceExt::oneshot`. **No runtime dependency is added
anywhere** — measured, not asserted: `oas3` and `proptest` appear in `cargo tree -e normal,dev` and
in neither case in `cargo tree -e normal` (checks `A19`, `A20.oas3`, `A20.proptest`).

**Ledger row settled: F334** (`docs/port/COMMONALITY.md:338`, area `web-service`, origin `py-only`,
verdict `DIVERGENT`, `Item: R83`). It is settled as **adopted, as an in-repository `oas3` +
`proptest` harness rather than a third-party fuzzer, because no Rust equivalent of `schemathesis`
exists**. The row's `origin` and `verdict` strings remain factually correct and stay the
controller's to set. **No `BASELINE-REVIEW:` finding is raised.** F334 is a `DIVERGENT` row this
item is appointed to decide, not an inherited `COMMON → REUSE` or `ADOPT` baseline that a challenge
would be directed at; nothing inherited is contradicted by this recommendation.

**No `OVERRIDE` is recorded, and the controller's allocated number `OV-15` stays unused.** The
binding REST API Design Standard v2.0.0 (owner ruling W2-REST, 2026-09-18) governs the template's
**HTTP surface**. A test harness is not that surface. This item could therefore depart from the
standard in only two ways — by asserting something the standard forbids, or by requiring a contract
document in a shape the standard forbids — and it does neither. The harness asserts a subset of the
standard's own rules (R5.1's no-5xx consequence, R5.2, R4.3) and never the negation of one; and it
requires an **OpenAPI 3.1 JSON** document, which is exactly what R4.1 makes the unconditional
default. Under §1.9 R1.7 ("silent deviation from any rule strength is nonconformance regardless of
the deviation's merits", `rest-api-standard.md:271`) a departure would have to be written down.
There is none to write.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.** The source is
py-launch-blueprint at the programme pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, quoted by
`raw/opus.md` from `tests/web/test_contract.py:1-30`, `pyproject.toml:277-278` and
`Justfile:300-301`: a suite that derives property-based cases for every documented operation from
the OpenAPI schema itself, asserts `not_a_server_error`, is marked `slow` so `addopts = "-m 'not
live and not slow'"` skips it by default, and is run by one documented command. TypeScript has no
such suite because it has **no web service at all** (ledger row F303, `docs/port/COMMONALITY.md:307`),
so its absence is a **structural absence, not drift**: there is no service to fuzz and no portable
capability being declined.

| # | What must agree across the three repositories | Level |
|---|---|---|
| P1 | Every operation the published contract documents is exercised, enumerated **from the contract**, with no per-operation hand-written test data and no list of operation names in the test file | capability |
| P2 | Inputs are generated from each operation's declared schema in two modes: **valid** inputs, including the declared boundary values, and **boundary-invalid** inputs that violate exactly one declared constraint, including the value just outside each declared bound | capability |
| P3 | The assertion is **no server error** (no 5xx). Response-**schema** conformance is explicitly not asserted yet, carrying py's own scope note forward | policy |
| P4 | The suite is excluded from the default fast test run, and is run by CI and by one documented command | policy |
| P5 | A failure names a reproducible, minimized request | capability |

May vary by ecosystem: the library or in-repository harness; the generator engine; whether the
document is fetched from the running service or read from a file; the number of cases per
operation; the transport (an in-process router call versus a socket); and **which additional
response invariants are asserted alongside the 5xx check**, because those follow from each
repository's own binding standards. The last clause is what admits the two extra oracles below
without touching P3.

**Observable acceptance criteria** — criteria for P03 to prove against the real template, not
observations of it:

1. With the web surface enabled, one test enumerates every operation in the served OpenAPI
   document; adding a route and documenting it adds fuzz coverage with **no test-file edit**.
2. A handler that returns 5xx for an input the document declares valid fails that test. So does a
   handler that returns 5xx for a boundary-invalid input, for example a `limit=101` that the
   extractor admits because the Rust type admits it. A `400` or `422` for a boundary-invalid input
   passes.
3. The failure output names the operation and the minimized offending request.
4. Removing an operation from the router while it is still documented fails the test (drift).
5. The default developer test command does not run the suite; one documented command does.
6. The suite runs on `ubuntu-latest` and `macos-latest` with no service listening on a port, no
   container runtime and no second language runtime.
7. For each operation, the generator produced at least one valid case at each declared boundary,
   and the boundary-invalid mode enumerated exactly one case for every declared constraint arm,
   so every value just outside each declared bound was sent — the guard against silent
   under-generation, which is the failure mode measured at check `A13`. A uniform draw over the
   declared range cannot produce the second kind at all, which is why that mode enumerates its arms
   rather than drawing them.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Evidence | Verdict |
|---|---|---|---|
| A1 | Adopt a dedicated Rust fuzzing crate or binary (`openapi-fuzzer`, `apifuzz`, `momus-fuzz`, `mockforge-contracts`, `noson`) | Every one fails a fitness gate before popularity is weighed; the most adopted has shipped no release since 2023-08-30 and no repository push since 2024-01-29 (`B3`, `B4`, `B5`, `B23`). The gate verdicts on the other four are carried from `raw/opus.md` | **Rejected** |
| A2 | Assemble the capability in the repository: fetch the served document, map each operation's declared schema to a `proptest` strategy, drive the router in process, assert on the response | Executed by this synthesis — a probe whose harness is 482 committed lines found and minimized a seeded 500 in 0.01 s, and two further seeded standard violations that are **not** 5xx (`A6`–`A12`) | **Recommended** |
| A3 | Run the language-agnostic `schemathesis` CLI in CI against a started server | Mature and actively developed; strictly more capable than A2 | **Ranked runner-up**; costs a listening server and a second language runtime in CI |
| A4 | Generate requests from the Rust request types (`arbitrary`/`proptest` on the handler's `T` in `Json<T>`) rather than from the document | Cheapest, and idiomatic Rust | **Rejected on P1**: it tests the types, not the contract, so it cannot see an operation documented but unrouted, nor a path-parameter schema that disagrees with the extractor |
| A5 | No contract fuzzing; rely on typed extractors and example-based tests | See the ecosystem difference below | **Rejected**: it drops P1 and P4 outright, and the bug class is reduced, not empty |

**The justified ecosystem difference, stated plainly.** In FastAPI an undeclared edge case surfaces
as an unhandled Python exception that the framework turns into a 500 — the class
`not_a_server_error` exists to catch. In axum the `Json<T>` extractor rejects a body that does not
deserialize into `T` **before the handler runs**, returning 4xx, so the largest slice of that class
is removed by the type system rather than by a test. What survives in Rust, and is what this suite
is for: explicit 5xx mappings on paths the contract calls valid; `unwrap`, `expect` and arithmetic
edge cases inside a handler on *well-typed* input; path-parameter schemas that disagree with the
route's extractor type; and drift between document and router. The principle survives; its yield is
lower, which argues for a modest case count, not for dropping the suite. The probe's seeded defect
is drawn from exactly that surviving class — `limit = 0`, a value the document declares valid,
reaching the handler and producing a 500 — and the harness caught it and minimized it (`A6`, `A7`).

**HIGH question 2, answered in its own terms.** The prompt asks whether a candidate derives "both
valid and boundary-invalid request payloads per operation directly from the schema … or would a
Rust port require assembling that capability from lower-level pieces, and if so what is the
assembly cost?" (`inputs/prompt.md:36`). **No Rust candidate that passes the gates does either.**
The capability must be assembled, and this decision requires the assembly to cover **both** modes.

- *Valid mode* is **executed**. The probe's harness is 482 lines, and it covers path parameters and
  JSON bodies with explicit boundary bias (`A2`, `A13`–`A15`).
- *Boundary-invalid mode* is **proposed, not executed**. The probe's integer strategy is valid-only:
  its `Union` holds `min`, `max`, `0` when in range, and a uniform draw over the declared range
  (`review/evidence/contract-fuzz-probe/tests/contract_fuzz.rs:347`–`:355`). The proposed arms are
  listed in the Generation row below. Each is a `Just` of a fixed value or a one-property mutation of
  a valid object, so the added cost is small per keyword. That cost is **estimated, not measured**.

Three grounds make the second mode a requirement rather than an extra:

1. The prompt names it.
2. py's precedent generates it by default. The pinned `schemathesis` is 4.21.5 (py `uv.lock:2257`–`:2258` at `b08bccfb`). Its pytest builder draws from
   `st.one_of(... for mode in generation.modes)` (`schemathesis/generation/hypothesis/builder.py:103`,
   read in the 4.21.5 copy installed at `~/c/py-launch-blueprint/.venv`). `generation_for` returns the
   project's default generation config when no operation or phase config applies
   (`config/_projects.py:396`–`:418`). The default mode set is `modes or list(GenerationMode)`
   (`config/_generation.py:63`), which is `POSITIVE` and `NEGATIVE` (`generation/modes.py:6`–`:12`).
   py's test sets only `max_examples` and `checks` (`tests/web/test_contract.py:21`–`:30`). The pin
   carries no `schemathesis.toml`, and `pyproject.toml:80` only declares the dependency.
3. In Rust, boundary-invalid inputs of the right type are exactly the class that survives the type
   system. `limit=0` and `limit=101` both deserialize into a `u32`, so the extractor lets them through
   and the handler's own validation is the only guard. That is an inference from serde's integer
   semantics; it was not measured here. Wrong-type and missing-property inputs are mostly rejected by
   the extractor with a 4xx. They are still generated, because they cost almost nothing and they
   exercise the rejection path that R70's envelope will render.

**What the binding standard adds, and what a contract-fuzz harness can and cannot carry.** Owner
ruling W2-REST binds the REST API Design Standard v2.0.0 to this template's HTTP surface, at commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
(both re-verified at checks `B11`, `B12`); its conformance surface is **145 rules** of the form
`**R<n>.<n>**` (check `B13`). Under §1.7 R1.5 (`rest-api-standard.md:210`, "Every API declares one
**conformance tier** in its conformance note … Every rule in this standard applies at every tier
unless the rule itself states a tier scope") the template's tier — which this item does not own —
changes nothing here: none of the rules below carries a tier scope, so all three oracles bind at
`internal`, `partner` and `public` alike.

A contract-fuzz harness sees one thing no static linter sees: **the actual response** to a request
the document says is valid. That makes it the natural carrier for the standard's *response
invariants that need no per-operation declaration*, and a poor carrier for everything else.

| Rule, quoted at its line in the pinned blob | Can this harness check it? | Evidence |
|---|---|---|
| **R5.1** `rest-api-standard.md:916` — "The status code MUST match the registered semantics of the outcome **as that outcome is known when the status is generated**. A failed operation MUST NOT return 2xx." | **Partly.** The harness cannot know the intended outcome, so it cannot check the match. Its 5xx assertion is the one consequence of R5.1 that needs no intent: a documented-valid request that produces a server error is a defect whatever the intent | `A6`–`A8` |
| **R5.2** `:934` — "Unregistered status codes MUST NOT be defined or used." | **Yes, and only here.** A status is a runtime fact; the standard's own Spectral ruleset does not carry R5.2 (check `B22`). A seeded `299` fired the oracle while the 5xx oracle stayed silent | `A11`, `A12`, `B22` |
| **R4.3** `:762` — "Every JSON response body MUST have an object at the top level — never a bare array." | **Yes, as a second line.** R4.3 *is* in `conformance/spectral.yaml` (check `B21`), which checks the declared schema; the harness checks the emitted body. A seeded `201` with a bare array fired the oracle while the 5xx oracle stayed silent | `A9`, `A10`, `B21` |
| **R5.12** `:1019` — "Every API MUST be capable of returning every error response the application itself generates as `application/problem+json`" (RFC 9457), and **R5.13** `:1049` — "Every problem document **carried in an HTTP response** MUST carry `type`, `title`, `status`, and a stable machine-readable `code` extension member" | **Yes, once R70 lands, and it is the cheapest widening available.** R70's decision in this run tree (`research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md`, revision 4) renders "every non-2xx response — domain failure, router miss, extractor rejection and blocking-bridge panic alike — as one RFC 9457 `application/problem+json` document" carrying `type`, `title`, `status` and `code`, with `catalog_code` beside them (`:131`–`:139`). That is a repository-wide invariant, not a per-operation declaration, so a harness can assert it on every generated 4xx without waiting for declared error responses. R70's only carve-out is errors "emitted by infrastructure in front of the application" (`:407`–`:410`), which an in-process harness never reaches | **Not executed here.** Recorded as the first widening, with R70's publication as its trigger |
| **R4.1** `:742` — "Every API MUST publish an OpenAPI document as the contract source of truth — version 3.1, or 3.2 only where the team's full toolchain … is verified against it." | **It constrains the harness rather than being checked by it.** `oas3` 0.22.0 validates `~3.1` only | `A16`–`A18` |
| **R4.2** `:754` — the document's changes gated on an automated compatibility check | **No.** That is R71's snapshot-and-diff slot, not a runtime oracle | — |
| Static document rules — §2.3 path shape, R4.4 snake_case, R4.16, §1.10 `X-` headers, R6.1 collection envelope, R6.8 filter suffixes | **No, and they do not need it.** The standard ships `conformance/spectral.yaml`, whose rules cover R2.4, R4.3, R4.4, R4.11, R4.16, R5.6, R5.13, R6.1, R6.8, R10.1, R10.9, R13.1, R13.2 (check `B21`'s printed list). Those are document facts; a fuzz harness would be the wrong instrument | `B21` |
| Intent-dependent behaviour — R3.4 idempotency keys, R3.5 conditional operations, §7 caching and concurrency, §8.2 authorization | **No.** Each needs a purpose-built test that knows the intended outcome, which schema-derived generation cannot supply | — |
| §8.1 transport and credentials | **No, structurally.** The harness drives the `Router` in process through `tower::ServiceExt::oneshot`; there is no socket and no TLS to observe. That is a deliberate cost of the in-process design, not an oversight | — |

**P3 is unchanged, and the two extra oracles are not a widening of it.** P3 says the assertion is no
server error and that response-**schema** conformance is not asserted. The R5.2 and R4.3 oracles
assert neither a schema nor a declaration: they assert invariants that hold for every response of a
conforming API regardless of what the document declares. They are required of the Rust surface by a
binding standard that py is not bound by, which makes them a **justified ecosystem difference at the
level P3 allows to vary**, not a departure from the shared policy and not a `BASELINE-REVIEW:`
finding against py. Their measured value is the argument for them: each fired on a seeded violation
that the 5xx oracle did not see (`A9`–`A12`), at a cost of roughly twenty lines.

**The design, element by element.**

| Element | Decision | Principle |
|---|---|---|
| Location | `crates/web/tests/contract_fuzz.rs`, a normal integration test of the optional member — **no file-level `#![cfg(feature = "web")]`**, because R69 revision 10 makes the whole member optional | P4 |
| Schema discovery | **Fetch the served document in process**: `oneshot` a `GET` at the router's OpenAPI path and parse the body with `oas3::from_json`. This mirrors py's `schemathesis.openapi.from_asgi("/openapi.json", app)`, needs nothing from R71 beyond the path, and tests the document the service actually serves. Reading R71's committed snapshot instead would test a file, and R71's own staleness test (F332) already asserts served equals committed. The Muse report argues the opposite: that the snapshot is deterministic in CI and pins the suite to the reviewed contract. Both properties hold for the served document whenever that staleness test passes, so the committed snapshot adds nothing when both exist; it stays the fallback for an R71 that commits a document but serves none (R71 coupling below) | P1 |
| Enumeration | `Spec::operations()` → `(path, Method, &Operation)` for every documented operation. Verified at source in the published crate: `oas3-0.22.0/src/spec/mod.rs:205` | P1 |
| Generation | Per operation, a `BoxedStrategy<serde_json::Value>` built from the operation's `in: path`, `in: query`, `in: header` and `in: cookie` parameter schemas and its `application/json` request-body schema, `$ref` resolved through `Schema::resolve` (`src/spec/schema.rs:594`); keyword subset `enum`, `const`, `type`, `minimum`/`maximum`, `minLength`/`maxLength`, `minItems`/`maxItems`, `properties`, `items`; **explicit boundary bias** through `proptest::strategy::Union` over `{minimum, maximum, 0-if-in-range, uniform}` for numbers and `{shortest, longest, uniform}` for strings. **A second, boundary-invalid strategy per operation** (proposed, not executed; see HIGH question 2 above). It **enumerates one case per declared constraint arm**: the arm is fixed by enumeration, never drawn, so every declared arm is sent exactly once. Only the base case is a draw from the valid strategy, so `proptest` can still shrink it; the case applies that one arm's violation to it. The arms are: `minimum − 1` and `maximum + 1` for a bounded number; a string of `minLength − 1` or `maxLength + 1`; an array of `minItems − 1` or `maxItems + 1` items; a value outside a declared `enum`; a value of a different JSON type; and an object with one `required` property removed, which adds `required` to the keyword subset. An arm is generated only for a constraint the schema actually declares, never for the mapper's own fallback range, and never where the value would be negative for a `minLength` or `minItems` of 0. For R72's published `limit` (`1..=100`, `research/topics/72-api-pagination/DECISION.md:154`) the valid boundary targets are therefore `1` and `100`, and the boundary-invalid targets are `0` and `101`. The harness asserts only that those two produce no 5xx; that they produce exactly `422` is R72's contract (`:154`–`:155`) and R72's to test | P2 |
| Mapper placement and its own tests | The schema-to-`Strategy` mapper lives in **`crates/web/tests/common/mod.rs`**, shared by the excluded fuzz target and a second, **default-tier** target `crates/web/tests/contract_mapper.rs` that unit-tests the mapper against small inline schemas (criterion 7's guarantee for both the valid boundaries and the boundary-invalid neighbours, and that each boundary-invalid case violates exactly one constraint). This adopts the Muse report's aim, fast-tier tests of the strategy derivation, but not its location, `src/test_support/`: a `#[cfg(test)]` module of `src/` is invisible to integration tests (`M6`), and a non-test `src/` module cannot use `[dev-dependencies]` (`M7`), so the Muse location would require `oas3` and `proptest` under `[dependencies]` of `crates/web`, optional or not, which contradicts "no runtime dependency is added". A shared `tests/common/` module sees the dev-dependencies from both targets (`M8`) | P2, P4, acceptance criterion 7 |
| Case count | `proptest::test_runner::Config { cases: 16, failure_persistence: None, .. }` for the **valid** mode, so 16 random valid cases per operation. The **boundary-invalid** mode's count is **the number of declared constraint arms** in the operation, one case each, so it grows with the schema rather than sharing a fixed budget. Any failure message names the mode and, for a boundary-invalid case, the arm (py uses `max_examples=10` over both modes together). `failure_persistence: None` because a counterexample here is a **service** defect to fix, not a seed to replay — unlike R33's property suite, which commits `proptest-regressions/` | P2, P5 |
| Checks | `not_a_server_error`, plus the two zero-declaration standard invariants above. Response-schema conformance deliberately not asserted | P3 |
| Transport | `tower::ServiceExt::oneshot` against the `Router`, inside a `tokio` current-thread runtime built in a plain `#[test]` — **not** `#[tokio::test]`, because `TestRunner::run` takes a synchronous closure and `block_on` inside an active runtime panics | P4, acceptance criterion 6 |
| Exclusion from the default run | **R32 owns the mechanism.** This item states the requirement and the three Rust mechanisms available: (a) `#[ignore]` plus `cargo test -- --ignored`; (b) a dedicated `[[test]]` target selected by name, `cargo test --test contract_fuzz`; (c) a dedicated Cargo feature such as `contract-fuzz`. **The `web` feature cannot serve as the marker**: R02 revision 2's check `B3` observed `cargo build --workspace` compiling the optional web member with the feature off, "because workspace membership, not the root package's feature, decides which members are built" (`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:128`), so a `--workspace` test run reaches this suite unless one of (a)–(c) is applied | P4 |

**Why `oas3` and not `openapiv3`.** `openapiv3` is far more downloaded and is the parser
`openapi-fuzzer` itself uses, and its newest non-yanked version declares **no `rust-version`**, which
fails gate 2 — re-verified at check `B27` rather than carried. **It also cannot read a 3.1
document that uses 3.1's own spellings, measured rather than inferred from its description.**
`openapiv3` 2.2.0 accepts the probe document labelled `3.1.0`, because it does not check the
version label (`M1`). But it rejects the same document once one property uses the 3.1 nullable
form `"type": ["integer", "null"]` ("invalid type: sequence, expected a string", `M2`), or a
numeric `exclusiveMinimum` ("expected a boolean", `M4`). `oas3` 0.22.0 accepts both variants and
validates them as `3.1.0` (`M3`, `M5`). R4.1 fixes the contract at 3.1, so a parser that fails on
3.1 keywords would reject a conforming document. `oas3` 0.22.0 declares `rust-version` **1.87**
against the **1.96** floor (stable 1.98.0 minus two minors), re-verified at check `B7`. It is
actively released: `x52dev/oas3-rs` was pushed 2026-09-20 in the revision-2 rerun and 2026-09-09
in revision 1's, check `B24`. It models OpenAPI 3.1 natively and exposes exactly the two APIs
this design needs.

**Fitness gates, answered before popularity is weighed.** Gate 1, for every candidate in this item:

`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`

The reason the row is recorded rather than deleted: the binding prompt still contains gate 1 and
its sha256 is cited by published acceptance records, so the prompt cannot be edited, and the prompt
itself says to state `inapplicable` with the reason rather than omitting a gate silently. Licences
are therefore reported as facts and weigh nothing (`oas3` MIT, `proptest` MIT OR Apache-2.0).
Gate 2: `oas3` 1.87 and `proptest` 1.85, both
within the 1.96 floor (`B7`, `B9`). Gate 3: no RustSec advisory page exists for either crate — HTTP
404 at `https://rustsec.org/packages/oas3.html` and `…/proptest.html` (`B10.oas3`, `B10.proptest`);
no `unsafe` is required by this use, and neither crate's own `unsafe` posture was audited at
`grep` level. Gate 4: the whole stack was **built and run on macOS/arm64 with stable 1.98.0** by this
synthesis (`A0`–`A18`); the `ubuntu-latest` leg is **inference** from platform-neutral dependency
trees and is listed for P03. Gate 5: neither crate pulls an async runtime; `tokio` enters only
through the web surface R69 already declares. Gate 6: both are `[dev-dependencies]`, so **no
binary-size cost at all** (`A19`, `A20.*`); compile cost is the added test target.

**A `tower` observation, recorded because it refines an accepted value rather than contradicting
it.** R69's `web-extra-surface` says `tower 0.5.3 is a dev-dependency only`. Measured here, `tower`
is **already in the normal dependency graph** through `axum`, which depends on it (`A21`, `A22`).
The accepted value is about how `tower` is **declared**, and declaring it dev-only is still right —
it adds no runtime crate. It does not, however, keep `tower` out of the shipped binary, and any
later reasoning that assumes it does would be wrong. Whether the `util` feature the `oneshot` idiom
needs is unified into the runtime build was **not** measured.

**The coverage boundary of the assembled mapper, stated so that nobody reads it as `schemathesis`
parity.** The probe generates **path parameters and the `application/json` request body**. It does
**not** generate query, header or cookie parameters; it treats `number` as `integer`; and it
implements none of `format`, `pattern`, `oneOf`, `allOf`, `anyOf` or `discriminator`. It also
generates **valid values only**: no boundary-invalid arm exists in the probe
(`review/evidence/contract-fuzz-probe/tests/contract_fuzz.rs:347`–`:355`). This decision requires
that mode (P2), so it is a P03 requirement that no check here has executed. Two of the other
gaps have named consequences. **Query parameters are a P03 requirement, not an optional extra**:
R72's pagination decision, published at revision 5, fixes `cursor` and `limit` as the template's
client-visible query surface. `limit` "defaults to 50 and is capped at 100", and "`limit=0` and
`limit=101` are rejected with `422`" (`research/topics/72-api-pagination/DECISION.md:154`–`:155`,
emphasis removed).
A harness that skips `in: query` would leave the most-exercised parameters in the API ungenerated,
including the boundary-invalid values `0` and `101` that R72's contract rejects.
The probe's own fixture declares `limit` with `"minimum": 0` and seeds a 500 at `0`. That is the
probe's throwaway contract, chosen to put a documented-valid value on a boundary; it is not R72's
contract and asserts nothing about it. **`format`-constrained strings and `oneOf` are the runner-up's trigger**: the moment
the document uses them, a ~20-line-per-keyword in-repository mapper stops being the cheaper option.

**The residual risk, stated plainly, because it is measured rather than imagined.** The mapper is
template-owned code that can silently under-generate: a harness that generates weakly still passes.
This synthesis reproduced exactly that. With the boundary bias removed from the integer strategy and
the 500 still seeded, the suite **passed** and reported `projects-create: 16 cases, no finding`
(check `A13`). Measured over 20 fixed RNG seeds, the biased mapper reached the declared boundary `0`
under **20 of 20** seeds and a uniform draw over the same declared range under **2 of 20** (`A14`,
`A15`). Unlike Hypothesis, `proptest` supplies no boundary bias for a bare range; an assembled
mapper must ask for it. The boundary-invalid mode is exposed to the same failure more severely:
a draw over the declared range never leaves it, so without explicit arms that mode generates no
out-of-bound value at all. That follows from the range and was not separately measured.
Acceptance criterion 7 exists to keep both guarantees, and must be re-run whenever the mapper
changes, not once.

**Migration implications — file-level changes in the template.** All inside the optional web member;
nothing outside it moves.

| Path | Change |
|---|---|
| `crates/web/Cargo.toml` | add `oas3 = "0.22.0"` to `[dev-dependencies]`. `proptest = "1.11.0"` (R33) and `tower = { version = "0.5.3", features = ["util"] }` (R69) are added by those items; no `[dependencies]` entry anywhere |
| `crates/web/tests/contract_fuzz.rs` | **new**: served-document fetch through `oneshot`, `oas3` parse, operation enumeration, a `TestRunner` loop per operation for the valid mode and one case per declared constraint arm for the boundary-invalid mode, both over the shared mapper, each case built into a request from its path, query, header and cookie parameters and its body, the three oracles applied to both modes, and a failure message naming `operationId`, the mode, the arm where there is one, and the minimized request's path, parameters and body |
| `crates/web/tests/common/mod.rs` | **new**: the schema-to-`Strategy` mapper over path, query, header and cookie parameter schemas and the `application/json` request body, with explicit boundary bias and the enumerated boundary-invalid arms of the Generation row, shared by the two test targets (`M8`) |
| `crates/web/tests/contract_mapper.rs` | **new**, default tier: unit tests of the mapper against inline schemas, including that every declared boundary and every boundary-invalid neighbour is generated, and that each boundary-invalid case violates exactly one constraint (criterion 7) |
| `crates/web/src/` | **no change** — the suite needs only `build_router()` and whatever route R71 chooses for the served document |
| `Justfile` | one recipe running the excluded tier, the analogue of py's `Justfile:300-301` `test-web`. Its spelling follows R42's published `package-manager-invocation` (bare `cargo`, no runner prefix) and R32's exclusion mechanism |
| CI workflow | **A requirement, not a placement.** The excluded tier must run in CI on **both `target-os-matrix` legs**, because that is how gate 4's Linux leg gets proved. It needs no toolchain, runner or `target/` different from what R11 revision 7's tier-2 `check` job already has: `check` is "ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false", running "cargo test over the workspace with the feature on" among "ordered steps sharing one target/" (`research/topics/11-ci-workflow-job-structure/DECISION.md:320`). R11's partition rule is that "a check that compiles what `check` already compiles is an ordered step of `check`, under `!cancelled()`" (`:278`). R11 hands the tiered case to R32: R32 owns "whether a slow tier earns its own job", under the default that "a tier becomes its own job only if it needs a different toolchain, a different runner, or a `target/` it must not share; otherwise it is an ordered step of `check`" (`:282`). **So the default outcome is an ordered step of `check`, and R32 decides.** Which detector key gates it has no effect today, because R11 revision 7 states that "`web` now equals `code`" (`:202`). **No new third-party action is introduced**, so R20's published `enforced-owner-prefix-pinning` policy is satisfied with no new pin |
| `CONTRIBUTING`/docs | one paragraph: what the suite does, the one command that runs it, and that a failure prints a minimized request |

**Coupling hand-offs, none of which this item decides.**

- **R71 (`openapi-generation-pipeline`, not yet researched)** — R83 needs three things from it and
  asserts none: (1) the document is **OpenAPI 3.1 JSON**; (2) the router **serves** it at a known
  path; (3) operations carry stable `operationId`s, which this suite uses to name a failure. The
  recommendation is conditioned on R71's plausible outcomes as follows. If R71 selects a generator
  emitting 3.1 and serving it from the router — the outcome the owner reference architecture's row
  C3 points at, `utoipa` 5 with `utoipa-axum` — nothing here changes. If R71 emits 3.1 but serves
  nothing, discovery falls back to reading the committed snapshot; `oas3::from_json` is unaffected,
  and the design loses only the served-equals-committed failure mode that R71's own staleness test
  already covers. If R71 emits **3.0**, the parser choice must be revisited: `oas3` 0.22.0's
  `validate_version()` refuses 3.0.3 while still parsing it and still enumerating its operations
  (checks `A16`–`A18`), so the suite would run against an unvalidated document — and R4.1 would be
  violated by the document, not by this harness. R4.1's conditional **3.2** clause has the same
  shape from the other side: `oas3` declares `OPENAPI_SUPPORTED_VERSION_RANGE = "~3.1"`
  (`oas3-0.22.0/src/spec/mod.rs:75`), so a 3.2 document would also fail `validate_version()`; that
  follows from the constant and was not separately measured.
- **R32 (`test-harness-and-execution`)** — owns which of the three exclusion mechanisms marks this
  suite, **and whether the excluded tier runs as an ordered step of R11's `check` job or earns its
  own job** (R11 revision 7, `research/topics/11-ci-workflow-job-structure/DECISION.md:282`). The
  test tier this harness occupies **is R32's slot**. R32 designs the tiering. R83 states only
  three requirements: this suite sits outside the default run; `contract_mapper.rs` sits inside
  it; and the excluded tier runs on both `target-os-matrix` legs. R32 must account for R02 check
  `B3`.
- **R11 (`ci-workflow-job-structure`, revision 7, published)** — owns the job shape, the `check`
  job's step list and the skip-gating keys. This item reads R11's default for a tier with no
  distinct toolchain, runner or `target/` (`:282`) and proposes nothing against it.
- **R70 (`http-problem-envelope`, revision 4 in its run tree)** — its unconditional
  `application/problem+json` envelope is what turns R5.12/R5.13 into a checkable invariant here.
- **R72 (`api-pagination`, revision 5, published)** and **R84 (`openapi-typed-client-generation`)**
  — the client-visible shapes this suite exercises. R72's `cursor`/`limit` query parameters, with
  `limit` in `1..=100` and `422` outside it, are the concrete reason query generation is a P03
  requirement. The harness generates `0` and `101` and asserts only that they produce no 5xx;
  asserting the exact `422` stays with R72. R84 shares only the document.

**Owner reference architecture — row-by-row disposition** (the 2026-09-16 standing input,
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, admitted by
`docs/planning/p02/owner-decisions.md` §11). Three rows touch this item; the tally is **1 agree, 2
differ**, re-checked at the lines rather than carried.

| Reference row | Position | Ground |
|---|---|---|
| **C3 OpenAPI** — "utoipa + utoipa-axum" (`:50`) | **Agree**, as a hand-off | `utoipa` emits OpenAPI 3.1, which is what `oas3` 0.22.0 requires and what R4.1 mandates. Not decided here: R71 owns F307/F312/F332/F333 |
| **C12 Testing** — "**axum-test + …**; tower `oneshot` [alternative]: oneshot lower-level, more boilerplate" (`:72`, prose at `:117`) | **Differ**, on recorded ground rather than preference | R69 revision 10 already selects `tower::ServiceExt::oneshot` and makes `tower` 0.5.3 a `crates/web` dev-dependency. Adding `axum-test` would introduce a crate no item in this programme has gated, for ergonomics this harness does not need. The "more boilerplate" criticism did not materialise: the `oneshot` call is three lines of the probe |
| **CI outline** — "cargo fmt --check → clippy -D warnings → sqlx prepare --check → cargo test → cargo deny check → OpenAPI export + diff" (`:377`) | **Differ / extend** | The reference's CI carries no contract-fuzz step. R83 requires a contract-fuzz run on both matrix legs. Under R11 revision 7's default (`research/topics/11-ci-workflow-job-structure/DECISION.md:282`) that run is an ordered step of `check`, and R32 decides whether it earns its own job. Nothing in the reference is contradicted; a run it does not contain is added |

**Ranked runner-up: `schemathesis` itself, invoked as a language-agnostic CLI in CI against a
started server.** Principle agreement would be exact rather than reconstructed, and it is strictly
more capable — stateful sequences, response conformance, `format` and `pattern` coverage, and
negative generation across every keyword it supports, where this harness's boundary-invalid mode
covers only the bound, `enum`, type and `required` arms. **It wins when** the document starts using
`oneOf`/`allOf`/`discriminator`, `format`-constrained strings or `pattern`, or when P3 widens to
response-schema conformance, or when negative coverage beyond those four arms is wanted, or when
maintaining the mapper costs more than about one developer-day a year, or, a condition added from
the Muse report (`raw/muse.md:73`), when R32's tier design already provisions a Python runtime in
CI, which removes its main cost. **What it costs today:** a
listening server rather than an in-process router; a second language runtime on both legs of the
fixed `target-os-matrix`; and a tension with R42's published `package-manager-invocation`, which
forbids "any provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job"
— `uvx schemathesis …` is exactly such a prefix. **That tension is named, not resolved:** R42 is not
this item's to change, and the recommendation avoids it.

**Tradeoffs.** Versus the runner-up, the template owns a mapper it must keep working instead of
buying a maintained implementation; accepted because the suite runs in process with no server, no
port, no container and no second runtime on either OS, and adds nothing to the shipped binary.
The depth given up is stateful sequences, response conformance, and generation for `format`,
`pattern` and the composition keywords, in both modes; a first generated 3.1 document is unlikely
to use the last three, and P3 excludes response conformance. Boundary-invalid generation is **not**
given up: every bounded number, string and array admits a value just outside its bound, so the
harness generates one. Versus adopting `apifuzz`,
the template gives up zero assembly cost; accepted because that crate is unevidenced on
`macos-latest`, has no release since 2026-02-06 and effectively no adoption, so the template would
become its first serious user and de-facto maintainer. Versus generating from the Rust request
types, roughly two-thirds of the harness and a parsing dependency are given up; rejected because it
silently drops P1. Versus `openapiv3` as the parser, far greater adoption is given up; rejected on
gate 2 and on fit against a 3.1 document.

re-verify: 2027-03-18, or earlier on any of — **R71 publishing**, whose generator decides the document's OpenAPI version and whether the router serves it, and on which the parser choice and the discovery mechanism depend; **R32 publishing**, naming the exclusion mechanism this item states three options for and deciding whether the excluded tier is an ordered step of `check` or its own job; **R69 republishing** revision 10 or later into `docs/port/PARAMETERS.md`, at which point the `assumes web-extra-surface` line below must be re-bound to the new registry bytes and the `crates/web/tests/` path this design uses confirmed rather than anticipated; **R70 publishing** revision 4 or later, which makes the `application/problem+json` invariant assertable and is the first widening of the oracle set; **R72 revising** its published revision 5's `limit` bounds (`1..=100`, `422` outside them), which the valid boundary targets `1` and `100` and the boundary-invalid targets `0` and `101` follow (the earlier trigger, R72 publishing, fired at revision 5); **R11 revising** its published revision 7's `check` job or its `research/topics/11-ci-workflow-job-structure/DECISION.md:282` default for test tiers, which is where the excluded tier lands by default (the earlier trigger, R11 revision 1 changing, fired at revision 7); **the controller collecting** Muse operation `2c70e838ded84127bef9ddb00c07276e` with bytes other than sha256 `dbd361282090349b5eab8f61ea60f4add7421e451c4c739e9a5147447c00c5df`, which voids the Muse adjudication under `## Engines`; py-launch-blueprint's contract test, or a `schemathesis` configuration it adds, restricting generation to the `positive` mode, which removes ground 2 of the boundary-invalid requirement and reopens P2's second mode; `openapiv3` releasing a version that declares a `rust-version` and parses 3.1 type arrays, which would re-admit it as a parser candidate; `noson` declaring a `rust-version` within the then-current floor or acquiring dependents, which would replace the largest part of the mapper; `apifuzz` adding a `macos-latest` CI leg and shipping a release after 2026-02-06, which would make it a live A1 candidate; `GET https://crates.io/api/v1/crates?q=schemathesis&per_page=12` ceasing to return `meta.total` 0, or any new crate appearing for schema-driven HTTP fuzzing under the searches `openapi fuzz`, `swagger fuzz` or `api fuzzing`; `GET https://crates.io/api/v1/crates/oas3/versions` showing a newest non-yanked `num` other than `0.22.0` or a `rust_version` above the then-current floor, likewise for `proptest` past `1.11.0`; `https://rustsec.org/packages/oas3.html` or `…/proptest.html` returning anything but 404; the `msrv-policy` floor advancing past 1.96; the owner ruling on whether fitness gate 2 reaches non-linked developer tools, which would re-admit `openapi-fuzzer` and `noson` as candidates; a new version of the REST API Design Standard changing R4.1, R4.3, R5.1, R5.2, R5.12 or R5.13, or the template declaring a conformance tier that scopes one of them; or `schemathesis` shipping a self-contained native binary, which removes the runner-up's main cost

## Parameters

This item owns no parameter (`research/CLAUDE.md` R83 row: the `owns` cell is `—`).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

No `CONFLICT:` line is raised: nothing this recommendation needs requires a consumed value to
change.

**The note the `assumes web-extra-surface` line requires.** Those bytes are the **live registry
row**, which is R69 **revision 9**'s value and reads `the web integration tests, gated file-level
with #![cfg(feature = "web")]` and `path-based skip-gating keys on src/web/**`. R69 **revision 10**
is owner-accepted and not yet published
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, owned value at line 1791;
owner rulings `W1-R02` and `W0-R69c`): it declares the feature on the root package naming the
optional member `rs-launch-blueprint-web`, puts the web integration tests in **`crates/web/tests/`**
with **no file-level `cfg`** because the whole member is optional, and keys skip-gating on
**`crates/web/**`**. **This design uses revision 10's paths** — `crates/web/tests/contract_fuzz.rs`,
`crates/web/Cargo.toml`. This is a pending publication, not a disagreement, so it is not a
`CONFLICT:`; R69's republication is a trigger on the line above, and the registry's revision-9 bytes
are reproduced here unchanged because the validator compares them byte-for-byte against the live
row.

**How the five lines were produced, because retyping them is how this fails.** They were generated
by a script that reads the value column of `docs/port/PARAMETERS.md` and emits
`- assumes <param> = <value>`; they were never copied from `raw/opus.md`. Re-checked for revision 2
on 2026-09-27: `diff research/runs/R83/…/inputs/PARAMETERS.md docs/port/PARAMETERS.md` reports
exactly one differing line, the `ci-job-structure` row. The live registry has gained R11's
published value there, and the run snapshot still carries `—`. This item does not consume that
row. Each of the five `assumes` lines, compared cell by cell against the live registry's value
column, is equal. The set equals fixed plus consumed: the four fixed rows plus R69's
`web-extra-surface`, which is this prompt's only `- consumes:` entry.

`msrv-policy` bears on this decision twice and both readings are satisfied: the two crates named
declare 1.87 and 1.85 against the 1.96 floor (checks `B7`, `B9`), and the probe's resolved graph
built and ran on stable 1.98.0. `target-os-matrix` is the reason the excluded tier must run on both
runners rather than on one, whichever of step or job R32 chooses, and the reason the runner-up's
container route was rejected. `license` weighs nothing on candidates under the 2026-09-12 ruling and applies
only to this repository's own declared expression. `rust-edition` is the edition the probe's
manifest declares.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc
2026-08-05) (Homebrew)`, macOS 26.4 on `arm64`, for revision 1's runs. The host has since
moved to `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` / `cargo 1.98.1`, which is what
revision 2's new script `muse-adjudication.sh` ran on (printed in its log). `contract-fuzz-probe.log`
was not rerun, so it still records 1.98.0. `/usr/bin/grep` is `grep (BSD grep, GNU compatible)
2.6.0-FreeBSD`, printed beside the counts in every log. **Working directory** for both scripts:
`research/runs/R83/2026-09-17T034011Z-2af391428997/review/evidence/` in the shared worktree at
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan` (branch `research/p02-execution`). Each evidence script creates its scratch
workspace with `mktemp -d` under `$TMPDIR`, removes it on an `EXIT` trap, and writes nothing
outside it — in particular nothing under `/tmp` and nothing in the scratchpad root. No token bytes and no personal email address appear in
either script or log; the crates.io `User-Agent` is the repository URL.

**These checks verify claims; they do not implement the recommendation.** The probe under
`review/evidence/contract-fuzz-probe/` is a throwaway service and a throwaway harness whose only
purpose is to let the architecture be observed. It is committed as a **fixture**, with its manifest
named `Cargo.toml.fixture` so that no Cargo package is ever rooted inside this research repository;
no `target/` tree and no nested git repository is committed. P03 writes the template's real harness.

| Script | Command | Exit | Checks | Log |
|---|---|---|---|---|
| `review/evidence/contract-fuzz-probe.sh` | `./contract-fuzz-probe.sh` | 0 | **PASS=24 FAIL=0 SKIP=0 TOTAL=24** | `review/evidence/contract-fuzz-probe.log` |
| `review/evidence/registry-and-standard.sh` (revision 2: three lines changed, F5) | `./registry-and-standard.sh`, rerun 2026-09-27 | 0 | **PASS=29 FAIL=0 SKIP=0 TOTAL=29** | `review/evidence/registry-and-standard.log` (regenerated) |
| `review/evidence/muse-adjudication.sh` (new, revision 2) | `./muse-adjudication.sh` | 0 | **PASS=8 FAIL=0 SKIP=0 TOTAL=8** | `review/evidence/muse-adjudication.log` |
| `review/evidence/registry-skip-paths.sh` (new, revision 2) | `./registry-skip-paths.sh` | 0 | **PASS=12 FAIL=0 SKIP=0 TOTAL=12** | `review/evidence/registry-skip-paths.log` |
| the same script against revision 1's `registry-and-standard.sh` (sha256 `69951480…`) | run in a scratch copy holding the revision-1 bytes | 1 | **PASS=5 FAIL=7**, the recorded defect | `review/evidence/registry-skip-paths.pre-fix.log` |
| revision 1's two scripts, from a clean extraction | `git archive HEAD \| tar -x -C "$TMPDIR/…"`, then both scripts run from the extracted tree | 0 and 0 | **24/24 and 29/29, no SKIP** | `review/evidence/clean-extraction.log` (revision 1, carried) |
| revision 2's three changed or new scripts, from a copy outside the worktree | `cp -R review/evidence "$TMPDIR/…"`, then each script run from the copy | 0, 0, 0 | **8/8, 12/12, 29/29, no SKIP** | `review/evidence/r2-copy-rerun.log` |

Totals for revision 2's runs: `contract-fuzz-probe.sh` 24 (revision 1, carried),
`registry-and-standard.sh` 29, `muse-adjudication.sh` 8 and `registry-skip-paths.sh` 12, which
makes **73 PASS, 0 FAIL, 0 SKIP**. The pre-fix log's `FAIL=7` is the defect being demonstrated;
it is not a failing check of this revision. The scripts locate their inputs relative to
`${BASH_SOURCE[0]}`, so they can be rerun after this decision is committed and outside the
worktree entirely; that failure has rejected an item in this programme before.
**`git archive HEAD` cannot carry revision 2's uncommitted script edits**, so the
clean-extraction rerun for revision 2 follows the controller's commit. Until then,
`r2-copy-rerun.log` shows the same property from a `cp -R` copy with no `.git` present. Every
script opens with `set -euo pipefail`, calls `/usr/bin/grep` by absolute path, asserts on
**content** rather than on an exit code, counts PASS/FAIL/SKIP, prints the sum, and exits non-zero
if any check fails. All four are `shellcheck` clean. `muse-adjudication.sh` carries one
file-level `# shellcheck disable=SC2016`, because its expected substrings quote rustc's literal
backticks.

**Revision 3 ran nothing new.** Its one change is a proposed design element, boundary-invalid
generation, that no committed script exercises. No script, log or fixture was edited, and none was
rerun, because no line the evidence cites moved. Revision 2's empirical audit reran all four
scripts on 2026-09-27 at 73 PASS, 0 FAIL, 0 SKIP (`review/audit-claude.r2.md:54`–`:61`), and those
are the counts revision 3 carried.

**Revision 4 ran nothing new either.** Its two changes are text repairs to the proposed design:
the parameter inputs, and the boundary-invalid mode's enumeration and case count, in the Generation
and Case count rows, two migration rows and acceptance criterion 7.
No committed script exercises either, no script, log or fixture was edited, and none was rerun,
because no line the evidence cites moved. Revision 3's empirical audit reran all four scripts on
2026-09-27 at 73 PASS, 0 FAIL, 0 SKIP (`review/audit-claude.r3.md:28`–`:37`), and those are the
counts this revision carries.

**Every `SKIP` path is named rather than silent, and revision 2 exercises each one** instead of
asserting it (`registry-skip-paths.log`). The probe script skips `A0..A22` as one block when
`cargo` is absent from `PATH`. `muse-adjudication.sh` skips `M1..M8` when `cargo` is absent, and
`M1..M5` when the parser-contrast package cannot build, for example with the registry
unreachable. The registry script has four skip paths:

- `B1..B9, B27` when crates.io is unreachable (check `S1`);
- `B10.<crate>` individually when `rustsec.org` is unreachable (`S2.*`);
- `B11..B22, B25, B26` when no clone of `rest-standards` exists at the pinned path (`S3`), tested
  with `-e` because a worktree's `.git` is a file;
- `B23, B24` when `gh` is absent (`S4`) or unauthenticated.

With all four unreachable at once, the copy prints `PASS=0 FAIL=0 SKIP=6 TOTAL=6` and exits 0
(`S5`, `S6`). Before the revision-2 fix, the `rustsec.org` path reported
`FAIL  B10.oas3 an advisory page now exists for oas3  (HTTP 000000 …)` instead
(`registry-skip-paths.pre-fix.log`). No `SKIP` was taken in the real runs recorded here.

**What the probe observed** (`contract-fuzz-probe.log`), across the script’s six labelled legs and its dependency-graph measurement:

1. **No seeded defect** — the served document parses, `validate_version()` returns `3.1.0`,
   `operations discovered: 2`, both operations fuzzed at 16 cases each, all three oracles green,
   `test result: ok. 3 passed` (`A1`–`A5`).
2. **A 5xx seeded on a documented-valid input** (`limit = 0`, which the document declares with
   `"minimum": 0`) — `projects-create: 500 Internal Server Error for POST /projects
   body={"name":"a","limit":0}` with `minimal failing input: ("/projects", Some(Object {"name":
   String("a"), "limit": Number(0)}))`, and the suite fails (`A6`–`A8`). Acceptance criteria 2 and
   3 observed; criterion 1 observed in the weak sense that no operation name appears in the harness.
3. **A seeded R4.3 violation** — a `201` whose JSON body is a bare array: the R4.3 oracle fires and
   the 5xx oracle does not (`A9`, `A10`).
4. **A seeded R5.2 violation** — a `299`: the R5.2 oracle fires and the 5xx oracle does not
   (`A11`, `A12`).
5. **The same 5xx, boundary bias removed** — the suite **passes**, `projects-create: 16 cases, no
   finding`; and the seed sweep prints `with explicit boundary bias: 20/20` against `uniform draw
   only: 2/20` (`A13`–`A15`).
6. **The OpenAPI version range** — `3.1.0 validate_version: Ok("3.1.0")`; the same document
   relabelled 3.0.3 gives `Err(UnsupportedSpecFileVersion(…))` while still parsing and still
   enumerating two operations (`A16`–`A18`).
7. **Dependency cost** — 60 packages in `cargo tree -e normal`, 141 with `-e normal,dev`; `oas3` and
   `proptest` appear only in the second (`A19`, `A20.*`); `tower` appears in **both**, reached
   through `axum` (`A21`, `A22`).

**What the registry-and-standard script re-verified at source** (`registry-and-standard.log`).
It ran first on **2026-09-19 (UTC)** and again for revision 2 on **2026-09-27 (UTC)**; the
regenerated log's header prints `retrieved: 2026-09-27T07:41:52Z`. It checked: the `schemathesis` search total
and its control (`B1`, `B2`); the newest non-yanked version, release date and declared
`rust_version` of `openapi-fuzzer`, `oas3` and `proptest` (`B3`–`B9`); three RustSec pages
(`B10.*`); the `rest-standards` HEAD commit and the `rest-api-standard.md` blob against the two
hashes owner ruling W2-REST names, the 145-rule count, and nine rule texts each asserted **at its
line number** in the pinned blob — R1.5 at 210, R1.7 at 271, R4.1 at 742, R4.2 at 754, R4.3 at 762,
R5.1 at 916, R5.2 at 934, R5.12 at 1019, R5.13 at 1049 (`B11`–`B20`, `B25`, `B26`); the Spectral ruleset cross-check that R4.3 is statically
linted and R5.2 is not (`B21`, `B22`); and two GitHub repositories through keyring-authenticated
`gh api`, spaced by an explicit `sleep 20` and never polled more than once per 20 seconds (`B23`,
`B24`). Open-issue counts were not read from `open_issues_count`, which the prompt forbids; the
script prints no issue count at all.

**What `muse-adjudication.sh` observed** (`muse-adjudication.log`, revision 2). It settles the two
Muse disagreements that no revision-1 check covered.

*Part 1, parser.* A package pinning `openapiv3 = "=2.2.0"` and `oas3 = "=0.22.0"` parses three
documents: the committed probe document, and two variants each changing one keyword on `limit`.
The results:

| Document | `openapiv3` 2.2.0 | `oas3` 0.22.0 |
|---|---|---|
| probe document, `"openapi": "3.1.0"` | `Ok openapi=3.1.0 paths=2` (`M1`) | `Ok validate_version=Ok("3.1.0") operations=2` |
| `"type": ["integer", "null"]` | `Err invalid type: sequence, expected a string` (`M2`) | `Ok validate_version=Ok("3.1.0") operations=2` (`M3`) |
| `"exclusiveMinimum": 0` | ``Err invalid type: integer `0`, expected a boolean`` (`M4`) | `Ok validate_version=Ok("3.1.0") operations=2` (`M5`) |

*Part 2, module placement.* Three throwaway packages use path dependencies only, with a `helper`
crate standing in for `oas3`/`proptest` as a `[dev-dependencies]` entry:

- a `#[cfg(test)] pub mod test_support` in `src/`, called from `tests/`, fails with ``cannot find `test_support` in `web` `` (`M6`);
- a non-test `src/` module calling the dev-dependency fails ``could not compile `web` (lib)`` (`M7`);
- a `tests/common/mod.rs` shared by `contract_mapper.rs` and `contract_fuzz.rs` gives `1 passed` and
  `1 ignored` (`M8`). The `#[ignore]` is a stand-in for R32's mechanism, not a selection of it.

**Reproducibility, shown rather than claimed.** `contract-fuzz-probe.sh` was run twice in
succession and the two outputs `diff` **byte-identical**; the committed log is the second run's. Two
fields that legitimately vary are normalised inside the script before printing — the OS thread id in
a panic line and the wall-clock duration — and the normalisation is visible in the log as
`<thread-id>` and `<duration>`. `registry-and-standard.sh` was likewise run twice; its
`== stable assertions ==` section `diff`ed **byte-identical**, and the only difference anywhere in
the two runs was the `retrieved:` timestamp line. The `== volatile figures ==` section carries
download counters, star counts and `pushed_at`, which move on the servers: compare that section by
**re-reading it against the assertions that guard it** (`B23` fails if `openapi-fuzzer` is pushed
after 2024; `B24` fails if `oas3` is not pushed in 2026 or later), never by diffing it.
**Revision 2's rerun against revision 1's log:** `diff` shows the `== stable assertions ==`
section byte-identical, including every `PASS` line and the figures at `:6`, `:8` and `:20`–`:21`.
The only lines that moved are `retrieved:` and the volatile ones. `openapi-fuzzer` went from 577 to
578 stars with `pushed_at` unchanged (2024-01-29), and `oas3-rs`'s `pushed_at` went from
2026-09-09 to 2026-09-20. Download counters moved too. `muse-adjudication.sh` and
`registry-skip-paths.sh` were each run twice, and each pair of logs `diff`ed **byte-identical**.
`muse-adjudication.sh` normalises libtest durations and target-directory hashes, and
`registry-skip-paths.sh` normalises its scratch path and the inner `retrieved:` timestamp.

**Claims recorded as unproven here, and what would prove each.** The **`ubuntu-latest` leg of gate
4** — no Linux runner was available; the whole stack, and revision 2's `M1`–`M8`, were built and
run on macOS/arm64 only. It is proved by CI running the suite on both matrix legs, wherever R32
places it. **Whether `utoipa` 5, or whatever generator R71 selects, actually emits the 3.1
spellings `M2` and `M4` exercise** was not measured. If R71's output uses only spellings shared
with 3.0, `openapiv3`'s parse failure would not bite; its gate-2 failure (`B27`) still would. **Whether `cargo test
--workspace` runs, as opposed to builds, the optional member's tests with the feature off** — R02
check `B3` observed the build; the test consequence is an inference, and P03 proves it by asserting
both directions of acceptance criterion 5. **The R5.12/R5.13 problem+json oracle** — it depends on
R70's envelope, which does not exist yet; P03 proves it by asserting every non-2xx response's media
type and member set once R70 lands. **Query, header and cookie parameter generation, and `format`,
`pattern` and `oneOf` support** — absent from the probe by design; P03 proves them against R72's
`cursor`/`limit` surface. **Boundary-invalid generation** (P2's second mode, the Generation row's
arms and criterion 7's second half) — designed here, not executed; the probe is valid-only
(`contract_fuzz.rs:347`–`:355`). P03 proves it by showing `limit=0` and `limit=101` generated and
answered without a 5xx, and by seeding a handler that panics on an out-of-bound `u32` and watching
the suite fail. **That an axum `Query<T>` or `Json<T>` extractor passes a type-valid, out-of-bound
integer to the handler** follows from serde's integer semantics and was not measured here. **The wall-clock budget on a realistic document** — the probe's two
operations finish in 0.01 s, which says nothing about ten operations at sixteen cases each; P03
measures it to confirm the tier is still worth excluding. **The `unsafe` posture of `oas3` and
`proptest`** beyond the absence of any `unsafe` requirement in the probe's own code; a `grep`-level
audit of their sources would settle it.

## Engines

**Engine set.** R83 is a Focused-tier item whose current `required_engines` are
`["muse", "opus"]`, and whose `manifest.json` `state` is `partial`. It began as `["codex", "opus"]`.
On 2026-09-21T23:06:21Z, `manifest.json` records a migration event by `controller-muse-spark`:
`from: codex`, `to: muse`, reason "muse bulk substitution (owner decision Q5.A 2026-09-21)". The
ruling is also at `docs/planning/p02/execution-ledger.md:1114`. The prompt mirrors it as
`- engines: muse, opus` and says "its mirrored `- engines:` line is authoritative"
(`inputs/prompt.md:25`, `:74`). RUNBOOK §2 lists R83 in the Muse bulk set and records that owner
decision Q9.B retired Codex from P02 (`research/RUNBOOK.md:70`–`:73`). Revision 1's Opus-only
synthesis was the earlier state: owner ruling **W1-CODEX3** of 2026-09-18 had let the Wave 2 legs
run without Codex (`docs/planning/p02/execution-ledger.md:1000`; `docs/planning/p02/owner-decisions.md:488`). Q5.A replaced that deferral with
a Muse leg.

- `opus raw/opus.md` — Claude Opus 5, sha256
  `5c8efd3c7e46bd11098e23a6de843037e7257e0f2ac0d1c3624ad4fa38e28741`, registered in `manifest.json`
  as operation `agent:research-opus-2026-09-17T034011Z-2af391428997:5c8efd3c7e46bd11`, collected
  2026-09-19T00:29:25Z. Its figures were retrieved 2026-09-18 (UTC); the figures in this decision
  that carry a date of 2026-09-19 (UTC) are this synthesis's own.
- `muse raw/muse.md` — model `muse-spark` (Meta family), actor
  `research-muse-2026-09-17T034011Z-2af391428997`. The report is dated 2026-09-25 in its own H1 and
  its figures were retrieved 2026-09-25. **Its collection state is recorded, not assumed.**
  `manifest.json` `operations.muse` has `request_id` `2c70e838ded84127bef9ddb00c07276e` and state
  **`submitting`**, and `operations/muse.json` says the same. The file `raw/muse.md` is on disk,
  sha256 `dbd361282090349b5eab8f61ea60f4add7421e451c4c739e9a5147447c00c5df`, 138 lines, untracked
  by git and **not pinned** in the manifest. Collecting and pinning it is the controller's step; this
  synthesis runs no runner command. **This revision adjudicates exactly those on-disk bytes.** If
  collection pins different bytes, the adjudication below is void and must be redone; that event
  is a re-verify trigger. `scripts/check-answer-shape.sh raw/muse.md crate` prints
  `OK: validation passed`; a shape pass is not evidence of factual quality (RUNBOOK §5).

**Where the two reports agree**, so no adjudication is needed:

- No Rust equivalent of `schemathesis` passes the gates (`raw/muse.md:69`; `B1`, `B2`).
- The mechanism is an assembly around `proptest`, and the suite asserts no 5xx only, with
  response-schema conformance out of scope (`raw/muse.md:29`, `:80`; P3).
- TypeScript's absence is justified (`raw/muse.md:25`; F303).
- `openapi-fuzzer` is excluded, and `apifuzz` is an up-and-comer too immature to carry a template
  decision (`raw/muse.md:51`, `:58`).
- The ranked runner-up is `schemathesis` itself as an external CI step (`raw/muse.md:73`). Muse's
  win condition, "if R32's slow-tier design already provisions a Python sidecar in CI", is
  compatible with this decision's and is added to it here.

**Where they disagree, and the evidence that settles each disagreement.** The Opus report and
revision 1 agree with each other on every row below; the disagreement is Muse's.

| # | Point | Muse position (at `raw/muse.md`) | This decision | Evidence that settles it |
|---|---|---|---|---|
| D1 | Parser | `openapiv3` "2", gate 2 "pass with gap" because its MSRV is "inferred from its stable-only serde-only dependency tree, not declared" (`:45`, `:47`, `:69`) | `oas3 = "0.22.0"`; `openapiv3` rejected | **Settled for `oas3`, on two independent grounds.** (a) Gate 2 as the prompt words it requires the MSRV to be within a policy "declared as rust-version in Cargo.toml and tested in CI" (`inputs/prompt.md:67`). `openapiv3` 2.2.0 declares none (`B27`, agreeing with Muse's own `:118`), so an inferred MSRV cannot show it is within policy. (b) Independently of gate 2, `openapiv3` 2.2.0 rejects the 3.1 type array and the numeric `exclusiveMinimum` that `oas3` 0.22.0 accepts (`M2`–`M5`). R4.1 fixes the contract at 3.1 (`B14`). Muse itself concedes the parser has "no 3.1/JSON-Schema drift handling" (`:42`) and names "a 3.1-only output needs a different parser" as its own re-verify trigger (`:109`); R4.1 fires that trigger now. |
| D2 | Transport | `reqwest::blocking` against the running service: "test harness spawns it or targets a CI service URL" (`:25`, `:65`, `:91`) | in-process `tower::ServiceExt::oneshot` | **Settled for `oneshot`.** Acceptance criterion 6 requires "no service listening on a port". The consumed `web-extra-surface` value names "tower 0.5.3 … for the ServiceExt::oneshot in-process test idiom", so the transport is already resident. A socket client adds a crate that no item in this programme has gated, and Muse itself notes that `reqwest` "pulls TLS/default-tls dependency weight" (`:43`). Probe checks `A1`–`A15` observed the full find-and-minimize loop in process, with no port. |
| D3 | Schema discovery | read the committed R71 snapshot: "deterministic in CI … pins the suite to the reviewed contract" (`:65`, `:85`) | fetch the served document in process; committed snapshot as the fallback | **Settled for served-first**, as the "Schema discovery" row of the design table explains. Py's precedent is `from_asgi`, the served document. R71's staleness test (F332) makes served equal committed whenever CI is green, so Muse's two properties hold for the served document too. The committed snapshot remains the fallback when R71 commits a document but serves none (R71 coupling). |
| D4 | The named crate | `proptest`, range `1` / `>=1.9,<2` (`:35`, `:69`) | `oas3 = "0.22.0"` | **Settled for `oas3`.** `proptest` is already published by R33 as `proptest = "1.11.0"` (`research/topics/33-property-and-snapshot-testing/DECISION.md:27`). Naming it here would re-decide another item's accepted value. Muse's range would also admit 1.9 and 1.10, below R33's pin, and a consumer never moves another owner's value. The crate this item newly introduces, and whose choice the Decision question turns on, is the parser. |
| D5 | Exclusion ground for `openapi-fuzzer` | "FAILED gate 1: license AGPL-3.0" (`:51`, `:77`) | excluded on gate 2 (`B5`) and on fit | **Same outcome, and Muse's ground is invalid.** Owner ruling Q7.B makes gate 1 `inapplicable` for every dependency and tool (`docs/planning/p02/owner-decisions.md:157`). The AGPL-3.0 licence is recorded as a fact with zero weight. The standing grounds are: no declared `rust-version` (`B5`); a binary, not a library; and no push since 2024-01-29 (`B23`). |
| D6 | Where the strategy mapper lives | `src/test_support/openapi_strategies.rs`, "test-gated", "unit-tested in the fast tier" (`:64`, `:93`) | `crates/web/tests/common/mod.rs`, plus a default-tier `contract_mapper.rs` | **Muse's aim is adopted; its location is rejected, on executed evidence.** An integration test cannot see a `#[cfg(test)]` module of `src/` (`M6`). A non-test `src/` module cannot use `[dev-dependencies]` (`M7`). So `src/` would force `oas3`/`proptest` into `[dependencies]`. `tests/common/` gives both targets the dev-dependencies (`M8`). This is the one design change revision 2 makes. |
| D7 | `### Parameters` | `assumes openapi-schema-source = (R71 committed snapshot file)` and `assumes test-tier-exclusion = (R32 slow-tier mechanism)` (`:85`–`:86`) | the four fixed rows plus `web-extra-surface` | **Not adopted.** Neither name is a row of `docs/port/PARAMETERS.md`, and a consumer never adopts an unregistered value (RUNBOOK §4). Both concerns are carried as coupling hand-offs to R71 and R32 instead. Muse also writes `web-extra-surface` as "(R69 decision)" rather than the registry's bytes. |
| D8 | Location | root `Cargo.toml` and `tests/contract/` (`:91`–`:92`) | `crates/web/Cargo.toml`, `crates/web/tests/` | **Settled by R69 revision 10**, owner-accepted, which puts the web integration tests in `crates/web/tests/` (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`). |
| D9 | Assembly cost | "~150–250 lines of strategy-derivation code", "estimated, not built" (`:27`, `:109`) | measured | **Measured, not estimated.** The probe's harness is 482 lines covering path parameters and JSON bodies only, in the valid mode only (A2 row; D10). Muse's figure is an unexecuted estimate by its own statement (`:105`). |
| D10 | Generation scope | "schema-derived generated cases (valid and boundary-invalid)" (`:23`); "`proptest` strategies derived from each operation's schemas generate valid and boundary-invalid payloads" (`:25`); the web suite "generates valid and boundary-invalid cases per operation" (`:65`); the mapper derives "(valid + boundary-invalid)" (`:93`) | revisions 1 and 2: valid inputs only, with explicit boundary bias, as in the Opus report (`raw/opus.md:111`, `:363`). Revision 3: **both modes** | **Muse's position is adopted.** (a) HIGH question 2 asks for "both valid and boundary-invalid request payloads per operation" (`inputs/prompt.md:36`). (b) py's pinned `schemathesis` 4.21.5 generates the `NEGATIVE` mode by default and py's test does not narrow it; the trace is in the "HIGH question 2" paragraph (`builder.py:103`, `_projects.py:396`–`:418`, `_generation.py:63`, `modes.py:6`–`:12`; `tests/web/test_contract.py:21`–`:30`). (c) A type-valid, out-of-bound value such as `limit=101` passes axum's extractors and reaches the handler, which is the class the ecosystem-difference paragraph says survives in Rust. The Opus report's own P2 said "including its boundary values" and placed "negative testing" with the runner-up only (`raw/opus.md:380`). That was a narrowing below the prompt, not a justified difference. **What Muse's report does not supply, and this row does not claim:** neither report executed negative generation. Muse's design is unbuilt (`:105`), and the probe is valid-only (`contract_fuzz.rs:347`–`:355`), so the mode is a proposal for P03. |

**Consequence for confidence.** Revision 1 had one engine and replaced the cross-check with
re-verification at source. Revision 2 has the second lens, but that lens is on uncollected bytes.
No Muse point moved the recommendation. Two points changed the design: D6 in revision 2 and D10
in revision 3. Two points, D1 and D6, needed new executed evidence. D10 rests on the prompt, on
py's library source and on an inference from serde's integer semantics, and executes nothing. **Re-verified by this synthesis**, 2026-09-19 unless marked:

- the `schemathesis` search total and its control;
- `openapi-fuzzer`'s version, date, missing `rust_version`, and repository `pushed_at`;
- the newest non-yanked versions and declared `rust-version` of `oas3`, `proptest` and `openapiv3`;
- three RustSec pages;
- the `oas3` API surface, read out of the published `oas3-0.22.0.crate` tarball:
  `Spec::operations()` at `src/spec/mod.rs:205`, `Schema::resolve` at `src/spec/schema.rs:594`,
  and `OPENAPI_SUPPORTED_VERSION_RANGE` at `src/spec/mod.rs:75`;
- the whole A2 architecture, rebuilt from scratch and run, including the seeded-defect
  find-and-minimize and the boundary-bias counterfactual;
- the dev-only dependency posture;
- every REST API Design Standard quote at its line in the pinned blob;
- revision 2 (2026-09-27): all of `registry-and-standard.sh` again, the parser contrast `M1`–`M5`,
  the module-placement checks `M6`–`M8`, and every SKIP path (`S1`–`S6`).

**Carried from `raw/opus.md` without re-verification**, each load-bearing only to the degree
stated:

- Hypothesis's boundary bias. The report itself labels it understood rather than verified, and
  nothing here depends on it, because the Rust side was measured.
- The absence of a Docker daemon on `macos-latest` runners. It supports the runner-up's cost, not
  the recommendation.
- `utoipa` emitting 3.1, which the report read from `utoipa-5.5.0/src/openapi.rs:383-385`.
- The `Linux` leg of gate 4.
- The `oas3` issue-responsiveness table, and every figure for `apifuzz`, `noson`, `momus-fuzz` and
  `mockforge-contracts`, each of which fails gate 2 before fit is weighed.
- The py and ts source quotations at their programme pins.

**Carried from `raw/muse.md` without re-verification**, none load-bearing here: the `reqwest`,
`quickcheck` and `bolero` figures, and the proptest adopter list.

- **Report claims this synthesis found wrong, or superseded.** (1) The Opus report places the CI
  step "in the web job, after R71's OpenAPI export-and-diff step". It also says the job-versus-step
  question is R11's and "still open". R11 is now published at **revision 7**. R11 hands the
  question for a test tier to R32, with the default that a tier needing no distinct toolchain,
  runner or `target/` "is an ordered step of `check`"
  (`research/topics/11-ci-workflow-job-structure/DECISION.md:282`). So neither the report's web-job
  placement nor revision 1's fixed step placement stands; the CI row above states the requirement
  and hands the placement to R32. (2) The report cites R02 revision 1 for check `B3`. R02 is now at
  **revision 2**, where `B3` survives at `:128` and `:251`, and it is cited to revision 2. (3) The
  report's dependency figures, 50 packages normal and 114 with dev, were **not reproduced**: this
  synthesis measured **60** and **141** on its own probe manifest. Neither figure is wrong; the
  manifests differ. The claim that survives, and is asserted here, is the one both runs agree on:
  `oas3` and `proptest` are dev-only. (4) The report states `tower` is a dev-dependency only.
  Measured here, `tower` is already in the normal graph through `axum`. That refines R69's value
  rather than contradicting it, and is recorded above as an observation, not a `CONFLICT:`. (5) The
  report was written before owner ruling W2-REST and contains no REST API Design Standard analysis
  at all. The conformance-carrier table, the two extra oracles and the `OV-15`-stays-unused
  disposition are this synthesis's work, and the two extra oracles were **measured** firing on
  seeded non-5xx violations rather than proposed; the Muse report has no standard analysis either.
  (6) R70's run-tree decision is cited at **revision 4**, the current file. Revision 1 cited
  revision 2, and the judgment audit read revision 3; R70 moved twice while R83 was in review.
- **Shape validation.** `validate_answer_text(raw_text, "crate")` returns `[]` for `raw/opus.md`,
  and `scripts/check-answer-shape.sh raw/muse.md crate` prints `OK: validation passed`. That
  validator checks the fifteen H3 answer fields of a raw **report**, so it is not run against this
  **decision**, which carries the synthesizer role's H2 sections instead. This revision's H2s
  (`## Decision`, `## Parameters`, `## Empirical check`, `## Engines`), revision header and
  `assumes` lines follow the shape of the published
  `research/topics/53-config-schema-validation/DECISION.md`.
- **What P03 must validate, since every line above is a proposal.** (1) The six acceptance criteria
  plus criterion 7, against the real template on both runners. (2) That adding a documented route
  grows fuzz coverage with an empty `git diff --stat` on `contract_fuzz.rs`. (3) That removing a
  route while leaving it documented fails the suite. (4) That the default developer command does not
  run the suite and the documented one does, asserted in both directions and including under `cargo
  test --workspace`. (5) The wall-clock budget on a realistic document. (6) Query-parameter
  generation against R72's `cursor`/`limit`. (7) The `application/problem+json` oracle once R70
  lands. (8) Whichever exclusion mechanism R32 selects, and whichever step-or-job placement it
  chooses, running the excluded tier on both matrix legs. (9) That `contract_mapper.rs` runs in the
  default tier and fails when the mapper stops generating a declared boundary or a boundary-invalid
  neighbour. (10) That boundary-invalid generation reaches the handler: `limit=0` and `limit=101`
  are generated and answered without a 5xx, and a seeded handler that panics on an out-of-bound
  value fails the suite.
