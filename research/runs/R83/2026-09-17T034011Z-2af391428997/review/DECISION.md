# 2026-09-18 — R83 — openapi-contract-fuzzing (crate, Focused) — decision (revision 1)

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
| P2 | Inputs are generated from each operation's declared schema, including its declared boundary values | capability |
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
2. A handler that returns 5xx for an input the document declares valid fails that test.
3. The failure output names the operation and the minimized offending request.
4. Removing an operation from the router while it is still documented fails the test (drift).
5. The default developer test command does not run the suite; one documented command does.
6. The suite runs on `ubuntu-latest` and `macos-latest` with no service listening on a port, no
   container runtime and no second language runtime.
7. For each operation, the generator produced at least one case at each declared boundary — the
   guard against silent under-generation, which is the failure mode measured at check `A13`.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Evidence | Verdict |
|---|---|---|---|
| A1 | Adopt a dedicated Rust fuzzing crate or binary (`openapi-fuzzer`, `apifuzz`, `momus-fuzz`, `mockforge-contracts`, `noson`) | Every one fails a fitness gate before popularity is weighed; the most adopted has shipped no release since 2023-08-30 and no repository push since 2024-01-29 (`B3`, `B4`, `B5`, `B23`). The gate verdicts on the other four are carried from `raw/opus.md` | **Rejected** |
| A2 | Assemble the capability in the repository: fetch the served document, map each operation's declared schema to a `proptest` strategy, drive the router in process, assert on the response | Executed by this synthesis — a ~380-line probe found and minimized a seeded 500 in 0.01 s, and two further seeded standard violations that are **not** 5xx (`A6`–`A12`) | **Recommended** |
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
| **R5.12** `:1019` — "Every API MUST be capable of returning every error response the application itself generates as `application/problem+json`" (RFC 9457), and **R5.13**'s required members | **Yes, once R70 lands, and it is the cheapest widening available.** R70's decision in this run tree (`research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md`, revision 2) makes **every non-2xx response** an unconditional `application/problem+json` document carrying `type`, `status`, `title`, `code` and `catalog_code`. That is a repository-wide invariant, not a per-operation declaration, so a harness can assert it on every generated 4xx without waiting for declared error responses | **Not executed here.** Recorded as the first widening, with R70's publication as its trigger |
| **R4.1** `:742` — "Every API MUST publish an OpenAPI document as the contract source of truth — version 3.1, or 3.2 only where the team's full toolchain … is verified against it." | **It constrains the harness rather than being checked by it.** `oas3` 0.22.0 validates `~3.1` only | `A16`–`A18` |
| **R4.2** `:759` — the document's changes gated on an automated compatibility check | **No.** That is R71's snapshot-and-diff slot, not a runtime oracle | — |
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
| Schema discovery | **Fetch the served document in process**: `oneshot` a `GET` at the router's OpenAPI path and parse the body with `oas3::from_json`. This mirrors py's `schemathesis.openapi.from_asgi("/openapi.json", app)`, needs nothing from R71 beyond the path, and tests the document the service actually serves. Reading R71's committed snapshot instead would test a file, and R71's own staleness test (F332) already asserts served equals committed | P1 |
| Enumeration | `Spec::operations()` → `(path, Method, &Operation)` for every documented operation. Verified at source in the published crate: `oas3-0.22.0/src/spec/mod.rs:205` | P1 |
| Generation | Per operation, a `BoxedStrategy<serde_json::Value>` built from the operation's path-parameter schemas and its `application/json` request-body schema, `$ref` resolved through `Schema::resolve` (`src/spec/schema.rs:594`); keyword subset `enum`, `const`, `type`, `minimum`/`maximum`, `minLength`/`maxLength`, `minItems`/`maxItems`, `properties`, `items`; **explicit boundary bias** through `proptest::strategy::Union` over `{minimum, maximum, 0-if-in-range, uniform}` for numbers and `{shortest, longest, uniform}` for strings | P2 |
| Case count | `proptest::test_runner::Config { cases: 16, failure_persistence: None, .. }` per operation (py uses `max_examples=10`). `failure_persistence: None` because a counterexample here is a **service** defect to fix, not a seed to replay — unlike R33's property suite, which commits `proptest-regressions/` | P2, P5 |
| Checks | `not_a_server_error`, plus the two zero-declaration standard invariants above. Response-schema conformance deliberately not asserted | P3 |
| Transport | `tower::ServiceExt::oneshot` against the `Router`, inside a `tokio` current-thread runtime built in a plain `#[test]` — **not** `#[tokio::test]`, because `TestRunner::run` takes a synchronous closure and `block_on` inside an active runtime panics | P4, P6 |
| Exclusion from the default run | **R32 owns the mechanism.** This item states the requirement and the three Rust mechanisms available: (a) `#[ignore]` plus `cargo test -- --ignored`; (b) a dedicated `[[test]]` target selected by name, `cargo test --test contract_fuzz`; (c) a dedicated Cargo feature such as `contract-fuzz`. **The `web` feature cannot serve as the marker**: R02 revision 2's check `B3` observed `cargo build --workspace` compiling the optional web member with the feature off, "because workspace membership, not the root package's feature, decides which members are built" (`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:128`), so a `--workspace` test run reaches this suite unless one of (a)–(c) is applied | P4 |

**Why `oas3` and not `openapiv3`.** `openapiv3` 2.2.0 is far more downloaded and is the parser
`openapi-fuzzer` itself uses, and it fails gate 2 by declaring no `rust-version`; it is also
3.0-shaped by its own crate description while R4.1 fixes the contract at 3.1. `oas3` 0.22.0 declares
`rust-version` **1.87** against the **1.96** floor (stable 1.98.0 minus two minors) — re-verified at
check `B7` — is actively released (`x52dev/oas3-rs` pushed 2026-09-09, check `B24`), models OpenAPI
3.1 natively, and exposes exactly the two APIs this design needs.

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
implements none of `format`, `pattern`, `oneOf`, `allOf`, `anyOf` or `discriminator`. Two of those
gaps have named consequences. **Query parameters are a P03 requirement, not an optional extra**:
R72's pagination decision fixes `cursor` and `limit` as the template's client-visible query surface,
so a harness that skips `in: query` would leave the most-exercised parameters in the API
ungenerated. **`format`-constrained strings and `oneOf` are the runner-up's trigger**: the moment
the document uses them, a ~20-line-per-keyword in-repository mapper stops being the cheaper option.

**The residual risk, stated plainly, because it is measured rather than imagined.** The mapper is
template-owned code that can silently under-generate: a harness that generates weakly still passes.
This synthesis reproduced exactly that. With the boundary bias removed from the integer strategy and
the 500 still seeded, the suite **passed** and reported `projects-create: 16 cases, no finding`
(check `A13`). Measured over 20 fixed RNG seeds, the biased mapper reached the declared boundary `0`
under **20 of 20** seeds and a uniform draw over the same declared range under **2 of 20** (`A14`,
`A15`). Unlike Hypothesis, `proptest` supplies no boundary bias for a bare range; an assembled
mapper must ask for it. Acceptance criterion 7 exists to keep that guarantee, and must be re-run
whenever the mapper changes, not once.

**Migration implications — file-level changes in the template.** All inside the optional web member;
nothing outside it moves.

| Path | Change |
|---|---|
| `crates/web/Cargo.toml` | add `oas3 = "0.22.0"` to `[dev-dependencies]`. `proptest = "1.11.0"` (R33) and `tower = { version = "0.5.3", features = ["util"] }` (R69) are added by those items; no `[dependencies]` entry anywhere |
| `crates/web/tests/contract_fuzz.rs` | **new**: served-document fetch through `oneshot`, `oas3` parse, operation enumeration, schema-to-`Strategy` mapper with explicit boundary bias, `TestRunner` loop, the three oracles, and a failure message naming `operationId`, path and body |
| `crates/web/src/` | **no change** — the suite needs only `build_router()` and whatever route R71 chooses for the served document |
| `Justfile` | one recipe running the excluded tier, the analogue of py's `Justfile:300-301` `test-web`. Its spelling follows R42's published `package-manager-invocation` (bare `cargo`, no runner prefix) and R32's exclusion mechanism |
| CI workflow | **one ordered step of R11 revision 1's tier-2 `check` job**, after that job's feature-on `cargo test` step. R11's own placement rule decides this: "a check that compiles what `check` already compiles is an ordered step of `check`" (`research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/DECISION.md:173`). `check` is matrixed over `target-os-matrix` with `fail-fast: false`, which is how gate 4's Linux leg gets covered, and is gated on the `code` output rather than `web` — R11 spends the `web` key on the purely-web jobs, "R71's and R84's OpenAPI and typed-client drift slots", and deliberately not on the compile tier (`:104`). **No new third-party action is introduced**, so R20's published `enforced-owner-prefix-pinning` policy is satisfied with no new pin |
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
  suite. The test tier this harness occupies **is R32's slot**: R32 designs the tiering, R83 states
  only that this suite must sit outside the default run, and R32 must account for R02 check `B3`.
- **R11 (`ci-workflow-job-structure`, revision 1)** — owns the job shape and the `crates/web/**`
  skip-gating key; the step placement above is read out of it rather than proposed against it.
- **R70 (`http-problem-envelope`, revision 2 in its run tree)** — its unconditional
  `application/problem+json` envelope is what turns R5.12/R5.13 into a checkable invariant here.
- **R72 (`api-pagination`)** and **R84 (`openapi-typed-client-generation`)** — the client-visible
  shapes this suite exercises: R72's `cursor`/`limit` query parameters are the concrete reason query
  generation is a P03 requirement; R84 shares only the document.

**Owner reference architecture — row-by-row disposition** (the 2026-09-16 standing input,
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, admitted by
`docs/planning/p02/owner-decisions.md` §11). Three rows touch this item; the tally is **1 agree, 2
differ**, re-checked at the lines rather than carried.

| Reference row | Position | Ground |
|---|---|---|
| **C3 OpenAPI** — "utoipa + utoipa-axum" (`:50`) | **Agree**, as a hand-off | `utoipa` emits OpenAPI 3.1, which is what `oas3` 0.22.0 requires and what R4.1 mandates. Not decided here: R71 owns F307/F312/F332/F333 |
| **C12 Testing** — "**axum-test + …**; tower `oneshot` [alternative]: oneshot lower-level, more boilerplate" (`:72`, prose at `:117`) | **Differ**, on recorded ground rather than preference | R69 revision 10 already selects `tower::ServiceExt::oneshot` and makes `tower` 0.5.3 a `crates/web` dev-dependency. Adding `axum-test` would introduce a crate no item in this programme has gated, for ergonomics this harness does not need. The "more boilerplate" criticism did not materialise: the `oneshot` call is three lines of the probe |
| **CI outline** — "cargo fmt --check → clippy -D warnings → sqlx prepare --check → cargo test → cargo deny check → OpenAPI export + diff" (`:377`) | **Differ / extend** | The reference's CI carries no contract-fuzz step. R83 adds one as an ordered step of R11's `check` job. Nothing in the reference is contradicted; a step it does not contain is added |

**Ranked runner-up: `schemathesis` itself, invoked as a language-agnostic CLI in CI against a
started server.** Principle agreement would be exact rather than reconstructed, and it is strictly
more capable — stateful sequences, negative testing, response conformance, `format` and `pattern`
coverage. **It wins when** the document starts using `oneOf`/`allOf`/`discriminator`,
`format`-constrained strings or `pattern`, or when P3 widens to response-schema conformance, or when
maintaining the mapper costs more than about one developer-day a year. **What it costs today:** a
listening server rather than an in-process router; a second language runtime on both legs of the
fixed `target-os-matrix`; and a tension with R42's published `package-manager-invocation`, which
forbids "any provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job"
— `uvx schemathesis …` is exactly such a prefix. **That tension is named, not resolved:** R42 is not
this item's to change, and the recommendation avoids it.

**Tradeoffs.** Versus the runner-up, the template owns a mapper it must keep working instead of
buying a maintained implementation; accepted because the suite runs in process with no server, no
port, no container and no second runtime on either OS, adds nothing to the shipped binary, and the
depth given up is depth a first generated 3.1 document cannot exercise. Versus adopting `apifuzz`,
the template gives up zero assembly cost; accepted because that crate is unevidenced on
`macos-latest`, has no release since 2026-02-06 and effectively no adoption, so the template would
become its first serious user and de-facto maintainer. Versus generating from the Rust request
types, roughly two-thirds of the harness and a parsing dependency are given up; rejected because it
silently drops P1. Versus `openapiv3` as the parser, far greater adoption is given up; rejected on
gate 2 and on fit against a 3.1 document.

re-verify: 2027-03-18, or earlier on any of — **R71 publishing**, whose generator decides the document's OpenAPI version and whether the router serves it, and on which the parser choice and the discovery mechanism depend; **R32 publishing** and naming the exclusion mechanism this item states three options for; **R69 republishing** revision 10 or later into `docs/port/PARAMETERS.md`, at which point the `assumes web-extra-surface` line below must be re-bound to the new registry bytes and the `crates/web/tests/` path this design uses confirmed rather than anticipated; **R70 publishing**, which makes the `application/problem+json` invariant assertable and is the first widening of the oracle set; **R72 publishing**, which fixes the query-parameter surface the mapper must learn to generate; **R11 revision 1 publishing or changing its `check` job's step list**, which is where the CI step is placed; `noson` declaring a `rust-version` within the then-current floor or acquiring dependents, which would replace the largest part of the mapper; `apifuzz` adding a `macos-latest` CI leg and shipping a release after 2026-02-06, which would make it a live A1 candidate; `GET https://crates.io/api/v1/crates?q=schemathesis&per_page=12` ceasing to return `meta.total` 0, or any new crate appearing for schema-driven HTTP fuzzing under the searches `openapi fuzz`, `swagger fuzz` or `api fuzzing`; `GET https://crates.io/api/v1/crates/oas3/versions` showing a newest non-yanked `num` other than `0.22.0` or a `rust_version` above the then-current floor, likewise for `proptest` past `1.11.0`; `https://rustsec.org/packages/oas3.html` or `…/proptest.html` returning anything but 404; the `msrv-policy` floor advancing past 1.96; the owner ruling on whether fitness gate 2 reaches non-linked developer tools, which would re-admit `openapi-fuzzer` and `noson` as candidates; a new version of the REST API Design Standard changing R4.1, R4.3, R5.1, R5.2, R5.12 or R5.13, or the template declaring a conformance tier that scopes one of them; or `schemathesis` shipping a self-contained native binary, which removes the runner-up's main cost

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
`- assumes <param> = <value>`; they were never copied from `raw/opus.md`. `research/runs/R83/…/inputs/PARAMETERS.md`
is byte-identical to `docs/port/PARAMETERS.md` (`diff` empty, run by this synthesis), so the run's
snapshot and the live registry agree and the set equals fixed plus consumed — the four fixed rows
plus R69's `web-extra-surface`, which is this prompt's only `- consumes:` entry.

`msrv-policy` bears on this decision twice and both readings are satisfied: the two crates named
declare 1.87 and 1.85 against the 1.96 floor (checks `B7`, `B9`), and the probe's resolved graph
built and ran on stable 1.98.0. `target-os-matrix` is the reason the CI step belongs in R11's
matrixed `check` job rather than in a single-runner job, and the reason the runner-up's container
route was rejected. `license` weighs nothing on candidates under the 2026-09-12 ruling and applies
only to this repository's own declared expression. `rust-edition` is the edition the probe's
manifest declares.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc
2026-08-05) (Homebrew)`, macOS 26.4 on `arm64`. `/usr/bin/grep` is `grep (BSD grep, GNU compatible)
2.6.0-FreeBSD`, printed beside the counts in both logs. **Working directory** for both scripts:
`research/runs/R83/2026-09-17T034011Z-2af391428997/review/evidence/` in the shared worktree at
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan` (branch `research/p02-execution`). Every scratch
workspace is created with `mktemp -d` under `$TMPDIR` and removed by an `EXIT` trap; nothing was
written to `/tmp` or to the scratchpad root. No token bytes and no personal email address appear in
either script or log; the crates.io `User-Agent` is the repository URL.

**These checks verify claims; they do not implement the recommendation.** The probe under
`review/evidence/contract-fuzz-probe/` is a throwaway service and a throwaway harness whose only
purpose is to let the architecture be observed. It is committed as a **fixture**, with its manifest
named `Cargo.toml.fixture` so that no Cargo package is ever rooted inside this research repository;
no `target/` tree and no nested git repository is committed. P03 writes the template's real harness.

| Script | Command | Exit | Checks | Log |
|---|---|---|---|---|
| `review/evidence/contract-fuzz-probe.sh` | `./contract-fuzz-probe.sh` | 0 | **PASS=24 FAIL=0 SKIP=0 TOTAL=24** | `review/evidence/contract-fuzz-probe.log` |
| `review/evidence/registry-and-standard.sh` | `./registry-and-standard.sh` | 0 | **PASS=26 FAIL=0 SKIP=0 TOTAL=26** | `review/evidence/registry-and-standard.log` |
| both, from a clean extraction | `git archive HEAD \| tar -x -C "$TMPDIR/…"`, then both scripts run from the extracted tree | 0 and 0 | **24/24 and 26/26, no SKIP** | `review/evidence/clean-extraction.log` |

Totals across the two scripts: **50 PASS, 0 FAIL, 0 SKIP**, and the same 50 again from the clean
extraction — the scripts locate their fixture relative to `${BASH_SOURCE[0]}`, so they are
rerunnable after this decision is committed and outside the worktree entirely, which is the failure
that has rejected an item in this programme before. Both scripts open with `set -euo
pipefail`, call `/usr/bin/grep` by absolute path, assert on **content** rather than on an exit code,
count PASS/FAIL/SKIP, print the sum, and exit non-zero if any check fails. Both are `shellcheck`
clean. Every `SKIP` path is named rather than silent: the probe script skips `A0..A22` as one block
when `cargo` is absent from `PATH` or the crate registry cannot be reached; the registry script
skips `B1..B9` when crates.io is unreachable, `B10.<crate>` individually when `rustsec.org` returns
no status, `B11..B22` when no clone of `rest-standards` exists at the pinned path (tested with
`-e`, because a worktree's `.git` is a file), and `B23`, `B24` when `gh` is absent or unauthenticated.
No `SKIP` was taken in the runs recorded here.

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

**What the registry-and-standard script re-verified at source** (`registry-and-standard.log`), all
on **2026-09-19 (UTC)**, the timestamp printed in the log's header: the `schemathesis` search total
and its control (`B1`, `B2`); the newest non-yanked version, release date and declared
`rust_version` of `openapi-fuzzer`, `oas3` and `proptest` (`B3`–`B9`); three RustSec pages
(`B10.*`); the `rest-standards` HEAD commit and the `rest-api-standard.md` blob against the two
hashes owner ruling W2-REST names, the 145-rule count, and seven rule texts each asserted **at its
line number** in the pinned blob — R4.1 at 742, R4.3 at 762, R1.5 at 210, R1.7 at 271, R5.1 at 916,
R5.2 at 934, R5.12 at 1019 (`B11`–`B20`); the Spectral ruleset cross-check that R4.3 is statically
linted and R5.2 is not (`B21`, `B22`); and two GitHub repositories through keyring-authenticated
`gh api`, spaced by an explicit `sleep 20` and never polled more than once per 20 seconds (`B23`,
`B24`). Open-issue counts were not read from `open_issues_count`, which the prompt forbids; the
script prints no issue count at all.

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

**Claims recorded as unproven here, and what would prove each.** The **`ubuntu-latest` leg of gate
4** — no Linux runner was available; the whole stack was built and run on macOS/arm64 only. It is
proved by R11's `check` job running the suite on both matrix legs. **Whether `cargo test
--workspace` runs, as opposed to builds, the optional member's tests with the feature off** — R02
check `B3` observed the build; the test consequence is an inference, and P03 proves it by asserting
both directions of acceptance criterion 5. **The R5.12/R5.13 problem+json oracle** — it depends on
R70's envelope, which does not exist yet; P03 proves it by asserting every non-2xx response's media
type and member set once R70 lands. **Query, header and cookie parameter generation, and `format`,
`pattern` and `oneOf` support** — absent from the probe by design; P03 proves them against R72's
`cursor`/`limit` surface. **The wall-clock budget on a realistic document** — the probe's two
operations finish in 0.01 s, which says nothing about ten operations at sixteen cases each; P03
measures it to confirm the tier is still worth excluding. **The `unsafe` posture of `oas3` and
`proptest`** beyond the absence of any `unsafe` requirement in the probe's own code; a `grep`-level
audit of their sources would settle it.

## Engines

- `opus raw/opus.md` — Claude Opus 5, sha256
  `5c8efd3c7e46bd11098e23a6de843037e7257e0f2ac0d1c3624ad4fa38e28741`, registered in `manifest.json`
  as operation `agent:research-opus-2026-09-17T034011Z-2af391428997:5c8efd3c7e46bd11`, collected
  2026-09-19T00:29:25Z. Its figures were retrieved 2026-09-18 (UTC); the figures in this decision
  that carry a date of 2026-09-19 (UTC) are this synthesis's own.
- **The Codex leg is absent by the controller's deferral, not by omission.** This is a Focused-tier
  item whose `required_engines` are `["codex", "opus"]` and whose `manifest.json` `state` is
  therefore `partial`. Owner ruling **W1-CODEX3** of 2026-09-18 — "Test Codex if it's available now,
  and if it is, use it. If not, do without it." — was applied after a probe that day returned
  `exit 1` with a usage-limit message, and the Wave 2 legs including R83 were dispatched on Opus
  alone (`docs/planning/p02/execution-ledger.md:1000`; the ruling is also recorded in
  `docs/planning/p02/owner-decisions.md` §12).
- **Consequence, and how it was handled.** With one engine there is no second lens and therefore no
  engine disagreement to settle; the usual cross-check was replaced by re-verifying every
  load-bearing claim at source. **Re-verified by this synthesis** (all `2026-09-19`, UTC): the
  `schemathesis` search total and its control; `openapi-fuzzer`'s version, date and missing
  `rust_version`, and its repository's `pushed_at`; `oas3`'s and `proptest`'s newest non-yanked
  versions and declared `rust-version`; three RustSec pages; the `oas3` API surface read out of the
  published `oas3-0.22.0.crate` tarball (`Spec::operations()` at `src/spec/mod.rs:205`,
  `Schema::resolve` at `src/spec/schema.rs:594`, `OPENAPI_SUPPORTED_VERSION_RANGE` at
  `src/spec/mod.rs:75`); the whole A2 architecture, rebuilt from scratch and run, including the
  seeded-defect find-and-minimize and the boundary-bias counterfactual; the dev-only dependency
  posture; and every REST API Design Standard quote at its line in the pinned blob. **Carried from
  `raw/opus.md` without re-verification, and load-bearing to the degree stated**: Hypothesis's
  boundary bias, which the report itself labels understood rather than verified and which nothing
  here depends on (the Rust side was measured); the absence of a Docker daemon on `macos-latest`
  runners, which supports the runner-up's cost and not the recommendation; `utoipa` emitting 3.1,
  read by the report from `utoipa-5.5.0/src/openapi.rs:383-385`; the `Linux` leg of gate 4; the
  `oas3` issue-responsiveness table and every figure for `apifuzz`, `noson`, `momus-fuzz` and
  `mockforge-contracts`, each of which fails gate 2 before fit is weighed; and the py and ts source
  quotations at their programme pins.
- **Report claims this synthesis found wrong, or superseded.** (1) The report places the CI step "in
  the web job, after R71's OpenAPI export-and-diff step" and says the job-versus-step question is
  R11's, "still open". R11 **revision 1 now exists** and answers it the other way: the suite
  compiles what `check` already compiles, so it is an ordered step of the tier-2 `check` job gated
  on `code`, and R11 deliberately does **not** spend the `web` key on the compile tier. Corrected
  above. (2) The report cites R02 revision 1 for check `B3`; R02 is now at **revision 2**, where
  `B3` survives at `:128` and `:251` — cited to revision 2. (3) The report's dependency figures, 50
  packages normal and 114 with dev, were **not reproduced**: this synthesis measured **60** and
  **141** on its own probe manifest. Neither figure is wrong; the manifests differ. The claim that
  survives and is asserted here is the one both runs agree on — `oas3` and `proptest` are dev-only.
  (4) The report states `tower` is a dev-dependency only; measured here, `tower` is already in the
  normal graph through `axum`. That refines R69's value rather than contradicting it, and is
  recorded above as an observation, not a `CONFLICT:`. (5) The report was written before owner ruling
  W2-REST and contains no REST API Design Standard analysis at all; the conformance-carrier table,
  the two extra oracles and the `OV-15`-stays-unused disposition are this synthesis's work, and the
  two extra oracles were **measured** firing on seeded non-5xx violations rather than proposed.
  (6) The task message names R70 "revision 1"; the decision in R70's run tree is **revision 2**, and
  it is cited as such.
- **Shape validation.** `validate_answer_text(raw_text, "crate")` returns `[]` for `raw/opus.md`:
  that validator checks the fifteen H3 answer fields of a raw **report**. Run against this
  **decision** it reports the same single H3-order diagnostic it reports against the accepted
  exemplar `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`, because a
  decision carries the synthesizer role's four H2 sections instead. `bash scripts/check-research-tree.sh .`
  was run before committing.
- **What P03 must validate, since every line above is a proposal.** (1) The six acceptance criteria
  plus criterion 7, against the real template on both runners. (2) That adding a documented route
  grows fuzz coverage with an empty `git diff --stat` on `contract_fuzz.rs`. (3) That removing a
  route while leaving it documented fails the suite. (4) That the default developer command does not
  run the suite and the documented one does, asserted in both directions and including under `cargo
  test --workspace`. (5) The wall-clock budget on a realistic document. (6) Query-parameter
  generation against R72's `cursor`/`limit`. (7) The `application/problem+json` oracle once R70
  lands. (8) Whichever exclusion mechanism R32 selects, wired to R11's `check` job.
