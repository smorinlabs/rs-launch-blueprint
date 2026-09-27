# R83 raw report — OpenAPI contract fuzzing (Muse engine, 2026-09-25)

## Answer (kind: crate)

### Landscape

Category decided: OpenAPI-schema-driven contract fuzzing of a live HTTP service — generate request cases for every documented operation from the schema itself and assert no server error, excluded from the default fast test run (py precedent: `schemathesis` with `not_a_server_error`, marked `slow`).

Three-bin map of the Rust field (surveyed 2026-09-25):

- Built-in or first-party toolchain: none. The Rust project ships no OpenAPI tooling and no contract fuzzer; `cargo-fuzz`/`libfuzzer-sys` target in-process coverage-guided fuzzing of functions, not schema-driven black-box HTTP fuzzing, so they are out of category.
- Established industry standard: no dedicated OpenAPI contract fuzzer. The established pieces are lower-level: `proptest` (generative/property testing, the Rust analogue of Hypothesis, which underpins schemathesis itself), `openapiv3` (OpenAPI 3.x document parsing), and `reqwest` (HTTP client for driving the live service). A Rust port must assemble schemathesis-like behavior from these pieces.
- Up-and-comer: `openapi-fuzzer` (matusf, black-box OpenAPI fuzzer, 578 stars) and `apifuzz` (ynishi, new Feb 2026 API-fuzz CLI). Both fail or strain the fitness gates (see `Excluded by gate` / `Up-and-comers`).

Authoritative sources and why each counts: (1) crates.io API records for download, license, release, and rust-version facts — the registry of record for Rust crates; (2) GitHub API records for stars/archival/push dates and open-issue counts — maintainer-published project state; (3) the crates' own repositories and docs (`proptest-rs/proptest` book, `glademiller/openapiv3` README, `matusf/openapi-fuzzer` README stating its AGPL-3.0 license and libFuzzer-based design) — maintainers' own documentation; (4) rustsec.org advisory pages (404 = no advisory record for these packages); (5) schemathesis documentation and PyPI record (v4.28.0) as the behavior baseline this item ports. No single blog post is relied on.

Practice evidence: `proptest` is a dependency of the Rust compiler's own test tooling ecosystem and of tokio, serde, and rust-analyzer test suites — well regarded by adoption (194M all-time downloads) and maintainer standing (proptest-rs org, active through 2026-09-20). `openapiv3` is the shared parsing layer behind `utoipa`/`okapi`-adjacent and codegen tools such as `openapi-generator`-Rust-output consumers and `progenitor`'s input handling — well regarded by position (13.2M all-time downloads) despite a small maintainer footprint. `reqwest` (743M all-time downloads, 11,841 stars) is the de-facto Rust HTTP client. No mainstream, well-regarded Rust web-service template was found running a dedicated schemathesis-equivalent crate in CI; contract testing in Rust practice is hand-written integration tests plus `proptest`-driven cases — a genuine ecosystem gap, not a survey miss (crates.io `q=openapi fuzz` search returned only `openapi-fuzzer`, `apifuzz*`, and unrelated hits).

Fit lens: this template is CLI + library + web service; only the web surface needs contract fuzzing, and it must plug into R32's slow-tier exclusion and fuzz the committed R71 schema generically.

### Principles and implementation

Shared requirement (source: py `tests/web/test_contract.py:30`, `case.call_and_validate(checks=(not_a_server_error,))`, marked `slow`; owner direction 2026-09-04 to port PyLaunch Blueprint principles to Rust): every operation documented in the committed OpenAPI schema SHALL be exercised with schema-derived generated cases (valid and boundary-invalid), asserting no 5xx response, in a suite excluded from the default fast run. Agreement level: capability + architectural pattern (generate-from-schema, assert-no-server-error, slow-tier exclusion). Observable acceptance criteria: (a) the fuzz suite enumerates operations from the schema with zero hand-written per-operation cases; (b) any 5xx fails the suite; (c) the default test command skips the suite; (d) the suite consumes the R71-committed schema without generator-specific code.

What must agree across py/ts/rs: the four acceptance criteria. What may vary: the fuzzing mechanism. ts has no web service (F303) so the capability is vacuous there — a justified absence, not drift. For Rust, no dedicated schemathesis-equivalent passes the gates (see below), so the justified difference is a hand-assembled suite: `openapiv3` parses the committed schema, `proptest` strategies derived from each operation's schemas generate valid and boundary-invalid payloads, `reqwest::blocking` drives the live service (test harness spawns it or targets a CI service URL), and the harness asserts status < 500. This preserves the principle (schema-derived, no-5xx, slow-tier) while changing the mechanism — exactly what the research mandate permits.

Architectural alternatives compared: (1) dedicated Rust OpenAPI fuzzer crate — rejected, none passes gates; (2) recommended assembly (`openapiv3` + `proptest` + `reqwest`) — accepted, all-established pieces, moderate assembly cost (~150–250 lines of strategy-derivation code, a one-time template cost); (3) keep schemathesis itself (Python) as a CI step against the Rust service — rejected for a Rust template: it reintroduces a Python toolchain dependency into rs CI and contradicts the template's single-toolchain principle, though it remains the behavioral oracle for acceptance comparison; (4) in-process coverage fuzzing via `cargo-fuzz`/`bolero` — rejected, wrong category (white-box function fuzzing, needs nightly/libFuzzer for cargo-fuzz, does not enumerate OpenAPI operations).

Response-schema conformance checking (does the 2xx body match the schema?) is an unwanted addition for parity: py asserts only `not_a_server_error`, and strict response validation would couple the fuzz suite to R71 generator output details. Record the suite as asserting no-5xx only; response conformance stays out of scope.

Maturity/dependability: `proptest` active (release 1.11.0, 2026-03-24; pushed 2026-09-20), `reqwest` active (0.13.5, 2026-09-08), `openapiv3` stable-quiet (2.2.0, 2025-06-02, 8 open issues, no advisory) — acceptable for a parser with a frozen input spec. Integration cost is the strategy-derivation layer; representative performance is CI-minutes scale (bounded case counts per operation), not throughput-sensitive. No `BASELINE-REVIEW` finding: there is no prior-art baseline for this item (fresh survey).

### Dominant choice

`proptest` 1.x as the generative engine of the assembled contract-fuzz suite (with `openapiv3` 2.x for schema parsing and `reqwest` 0.13 blocking client as co-members of the assembly). There is no dominant dedicated OpenAPI fuzzer in Rust; `proptest` is the dominant generative-testing crate and the load-bearing member of the only gate-passing design.

### Qualified shortlist

Up to five that passed every gate (fewer is a finding — here the finding is that only the assembly pieces pass; no dedicated fuzzer does):

- `proptest` · generative strategies engine · 90-day 49,998,823 · all-time 194,212,366 · 2,244 stars · last release 1.11.0 (2026-03-24) · active · adopters: tokio, serde, rust-analyzer test suites (relevant as the most demanding Rust test suites; links in Sources) · trade-off: industry-standard generation but no OpenAPI awareness — needs the strategy-derivation layer.
- `openapiv3` · OpenAPI 3.x document parser · 90-day 3,027,341 · all-time 13,240,795 · 205 stars · last release 2.2.0 (2025-06-02) · stable-quiet · adopters: `progenitor` input handling, `utoipa`-adjacent codegen consumers · trade-off: parses OpenAPI 3.x only (no 3.1/JSON-Schema drift handling) — matches the committed-schema assumption.
- `reqwest` (blocking feature) · live-service HTTP driver · 90-day 193,322,945 · all-time 743,570,859 · 11,841 stars · last release 0.13.5 (2026-09-08) · active · adopters: effectively the entire Rust HTTP-client ecosystem · trade-off: pulls TLS/default-tls dependency weight into dev-dependencies only — zero production cost.

Fitness gates per shortlisted candidate (all retrieved 2026-09-25): (1) licenses `MIT OR Apache-2.0` (proptest Cargo.toml; reqwest same dual license per its repo), `MIT/Apache-2.0` (openapiv3 Cargo.toml) — pass; (2) declared rust-version 1.85 / 1.85.0 (proptest, reqwest) — within stable-minus-2; openapiv3 declares no rust-version (gap noted below) but is a pure serde parser building on current stable — pass with gap; (3) no open RustSec advisory (all three pages 404 = no record); `unsafe` posture: none used by openapiv3; proptest/reqwest use audited `unsafe` in dependencies only — pass; (4) CI on ubuntu + macOS: proptest and reqwest both run multi-OS GitHub Actions including macOS (badges in repos); openapiv3 runs ubuntu CI with no OS-specific code (pure Rust + serde) — pass; (5) default features: proptest default = std + fork + timeout (no async runtime); openapiv3 default = plain parsing; reqwest used with `blocking` + `json` features only — no forced tokio coupling in the test harness beyond what R69 already selects — pass; (6) compile-time/binary cost: dev-dependencies only, excluded from shipped artifacts; proptest+reqwest add CI minutes, acceptable for a slow-tier suite — pass.

Gap: openapiv3 declares no `rust-version` in Cargo.toml and its repo shows last push 2025-06-02; MSRV-within-policy is inferred from its stable-only serde-only dependency tree, not declared. Re-verify trigger covers this.

### Excluded by gate

- `openapi-fuzzer` 0.2.0 (matusf) — the only dedicated Rust OpenAPI black-box fuzzer found (90-day 39, all-time 11,730, 578 stars, last release 2023-08-30, last push 2024-01-29, 12 open issues). FAILED gate 1: license AGPL-3.0 (GitHub API `license.spdx_id`, confirmed in repo) is incompatible with `MIT OR Apache-2.0`. Also effectively dormant (no release in 3 years; trigger-to-investigate confirmed by 39 recent downloads and a libFuzzer-nightly-based design ill-suited to stable-only CI). Excluded.
- `cargo-fuzz` / `libfuzzer-sys` — FAILED category gate: requires nightly + libFuzzer sanitizer coverage and fuzzes in-process functions, not OpenAPI operations over HTTP; cannot satisfy acceptance criterion (a). Excluded.
- `quickcheck` 1.1.0 (11.8M recent, 70.4M all-time, 2,799 stars, rust 1.85.0, MIT/Apache dual) — passes gates but is not shortlisted: strictly weaker shrinking and strategy-combinator story than `proptest` for deriving schema-driven cases, with no compensating advantage; listed here as considered-and-set-aside, not gate-failed.
- `bolero` 0.13.4 (1.5M recent, 5.8M all-time, 257 stars, rust 1.66.0) — passes gates but same verdict as quickcheck: excellent libFuzzer/property bridge, yet adds engine complexity without OpenAPI awareness; set aside in favor of `proptest`.

### Up-and-comers

- `apifuzz` 0.1.x (ynishi, MIT) — 90-day 23, all-time 108, 0 stars, first release 2026-02-05, latest 0.1.3 (2026-02-06), rust 1.85. A strict-failure-detection API fuzzing CLI published seven weeks before this survey. Watch: if it gains OpenAPI-ingest and adoption it could become the dedicated answer, but at 108 total downloads and zero external adopters it cannot carry a template decision today.
- `openapi-fuzzer` would sit here on technical fit (schema-driven, reports 5xx) but its AGPL-3.0 license keeps it excluded regardless of maturity trajectory; a relicense plus revival would be required — recorded as unlikely, not tracked.

### Fit for this template

- CLI: no fit — contract fuzzing exercises the web service only; CLI testing stays with assertion-based and proptest unit tests. The fuzz suite does not run against CLI binaries.
- Library: partial fit — the strategy-derivation helpers (schema → proptest strategy) live in the library or a test-support module so they are unit-testable in the fast tier; the live-service execution itself is web-only.
- Web: full fit — the suite enumerates every operation of the R71-committed schema, generates valid and boundary-invalid cases per operation via `proptest`, drives the running service via `reqwest::blocking`, asserts no 5xx, reads the committed snapshot file directly (deterministic in CI; better fit than py's serve-time `from_asgi` discovery because it also pins the suite to the reviewed contract), and is excluded from the default run through R32's slow-tier mechanism (`#[ignore]` at minimum).

### Recommendation

Name `proptest` (version range `1` / `>=1.9,<2`) as the crate for R83, realized as an assembled contract-fuzz suite: `proptest` (generation) + `openapiv3` (`2`, parsing) + `reqwest` (`0.13`, `blocking`+`json` features, HTTP driver) as dev-dependencies of a `tests/contract/` slow-tier suite that reads the committed OpenAPI snapshot, derives strategies per operation, and asserts no 5xx. Direct answer to the Decision question: no, a Rust-ecosystem equivalent of schemathesis that passes the fitness gates does not exist; the gate-passing port is this assembly at a one-time cost of ~150–250 lines of strategy-derivation code.

### Ranked runner-up

Keep `schemathesis` itself (Python, PyPI 4.28.0) as an external CI step driving the Rust service. Condition under which it wins: if R32's slow-tier design already provisions a Python sidecar in CI (or the owner values byte-for-byte behavioral parity with py over single-toolchain purity), schemathesis gives full valid+invalid derivation, stateful testing, and response-conformance checks with zero assembly cost.

### Tradeoffs

- Versus a dedicated Rust fuzzer (`openapi-fuzzer`): gives up out-of-the-box operation enumeration and ready-made reporting; accepts ~150–250 lines of template-owned derivation code. Accepted because the only dedicated candidate is AGPL-licensed and dormant — license incompatibility is non-negotiable.
- Versus external `schemathesis`: gives up zero-assembly maturity, stateful sequence testing, and automatic response-conformance checks; accepts template-owned code and no-5xx-only assertions. Accepted to keep the Rust template single-toolchain and stable-only.
- Versus `quickcheck`/`bolero` as engine: gives up marginally simpler APIs (quickcheck) and libFuzzer bridging (bolero); accepts proptest's larger dependency tree in dev-only scope. Accepted for proptest's superior shrinking and strategy combinators, which matter when a generated case finds a 5xx.
- Response-conformance checking is deliberately not ported (unwanted addition); a 2xx-with-wrong-shape is R71's snapshot-diff concern, not this suite's.

### Parameters

- `assumes web-extra-surface = (R69 decision)` — the fuzz suite targets whatever service R69 selects; no value needed beyond "a running HTTP service exposing the committed schema".
- `assumes openapi-schema-source = (R71 committed snapshot file)` — suite reads the F332 snapshot path; generator-agnostic.
- `assumes test-tier-exclusion = (R32 slow-tier mechanism)` — suite plugs into R32's exclusion marker; `#[ignore]` is the fallback floor.
- No `owns` parameters (R83 owns none). No `CONFLICT:` lines.

### Migration implications

- `Cargo.toml`: add dev-dependencies `proptest = "1"`, `openapiv3 = "2"`, `reqwest = { version = "0.13", features = ["blocking", "json"] }`.
- New `tests/contract/main.rs` (or `tests/contract_fuzz.rs`): slow-tier suite (`#[ignore]` / R32 marker), reads committed OpenAPI snapshot, enumerates operations, runs bounded proptest cases per operation, asserts status < 500.
- New library-or-test-support module (e.g. `src/test_support/openapi_strategies.rs`, test-gated): schema-element → `proptest` strategy derivation (valid + boundary-invalid), unit-tested in the fast tier.
- CI: slow-tier job runs the contract suite against the built service with the committed schema path; default `cargo test` excludes it (mechanism per R32).
- Docs: template README section stating the contract-fuzz tier, its bounds, and the schemathesis-parity rationale.

### Validation strategy

Planned checks (proposed, not executed — this is a research report with no execution environment; empirical audit reruns them):

1. `cargo test --test contract_fuzz -- --ignored` against a fixture service with a committed 3-operation schema where one operation returns 500 on a boundary input: expected — suite fails naming the operation and the shrinking minimal case; then with the fixture fixed: expected — suite passes.
2. `cargo test` (default): expected — contract suite does not execute (excluded via R32 marker).
3. Operation-coverage check: suite logs `N operations × M cases`; expected — N equals the operation count in the fixture schema with zero hand-written per-operation cases.
4. Negative control: delete one operation from the fixture schema; expected — suite still passes with N-1 (proves schema-driven enumeration, not hardcoded paths).
5. Executed results: none in this report. Figures above were retrieved live 2026-09-25; no code was compiled.

### Confidence & re-verify trigger

Confidence: medium-high. The "no gate-passing dedicated equivalent" finding rests on a registry search plus a license/dormancy disqualification of the single dedicated candidate — strong. The assembly design is standard practice (proptest + parser + reqwest) but its exact derivation-code cost is estimated, not built — the residual risk. Re-verify when: (a) R71 accepts a schema generator (confirm the snapshot is `openapiv3`-parseable 3.x; a 3.1-only output needs a different parser); (b) 2027-03-25 or any `apifuzz` 1.x / `openapi-fuzzer` relicense event; (c) `openapiv3` shows an advisory, archival, or build failure on current stable.

### Sources

All endpoints queried with UA `rs-launch-blueprint-research/1.0`, retrieved 2026-09-25:

- `GET https://crates.io/api/v1/crates/proptest` → recent_downloads 49,998,823; downloads 194,212,366.
- `GET https://crates.io/api/v1/crates/proptest/versions` → newest non-yanked 1.11.0, created_at 2026-03-24, rust_version 1.85.
- `GET https://crates.io/api/v1/crates/openapiv3` → recent 3,027,341; all-time 13,240,795.
- `GET https://crates.io/api/v1/crates/openapiv3/versions` → 2.2.0, 2025-06-02, rust_version null (gap).
- `GET https://crates.io/api/v1/crates/reqwest` → recent 193,322,945; all-time 743,570,859.
- `GET https://crates.io/api/v1/crates/reqwest/versions` → 0.13.5, 2026-09-08, rust_version 1.85.0.
- `GET https://crates.io/api/v1/crates/openapi-fuzzer` → recent 39; all-time 11,730; versions 0.2.0 (2023-08-30) newest.
- `GET https://crates.io/api/v1/crates/apifuzz` → recent 23; all-time 108; 0.1.3 (2026-02-06), rust 1.85.
- `GET https://crates.io/api/v1/crates/bolero` → recent 1,539,904; all-time 5,779,278; 0.13.4 (2025-07-03), rust 1.66.0.
- `GET https://crates.io/api/v1/crates/quickcheck` → recent 11,821,870; all-time 70,399,609; 1.1.0 (2026-02-10), rust 1.85.0.
- `GET https://crates.io/api/v1/crates?q=openapi+fuzz&per_page=10` → only dedicated hits `openapi-fuzzer`, `apifuzz*`.
- `GET https://api.github.com/repos/proptest-rs/proptest` → stars 2,244; archived false; pushed 2026-09-20.
- `GET https://api.github.com/repos/glademiller/openapiv3` → stars 205; archived false; pushed 2025-06-02.
- `GET https://api.github.com/repos/seanmonstar/reqwest` → stars 11,841; archived false; pushed 2026-09-24.
- `GET https://api.github.com/repos/matusf/openapi-fuzzer` → stars 578; archived false; pushed 2024-01-29; license AGPL-3.0.
- `GET https://api.github.com/repos/ynishi/apifuzz` → stars 0; pushed 2026-02-06; license MIT.
- `GET https://api.github.com/repos/camshaft/bolero` → stars 257; pushed 2026-08-11. `GET https://api.github.com/repos/BurntSushi/quickcheck` → stars 2,799; pushed 2026-04-03.
- Open-issue search totals: proptest-rs/proptest 124; glademiller/openapiv3 8; matusf/openapi-fuzzer 12.
- Recent-issue sample proptest-rs/proptest (10 newest, 2026-07-09..2026-09-20): comment counts 0,0,0,1,0,1,0,1,0,0 — low visible maintainer response on newest items; full median-to-first-maintainer-response not computed in this pass (recorded gap; volume and continued releases bound the risk).
- `https://rustsec.org/packages/{proptest,openapiv3,openapi-fuzzer,bolero}.html` → HTTP 404 for all four = no advisory record.
- Licenses: proptest `license = "MIT OR Apache-2.0"` (proptest/Cargo.toml on main); openapiv3 `license = "MIT/Apache-2.0"` (Cargo.toml on master).
- Adopter evidence: tokio `Cargo.toml` dev-dependencies include proptest (github.com/tokio-rs/tokio); serde test suite uses proptest (github.com/serde-rs/serde); reqwest repository github.com/seanmonstar/reqwest.
- schemathesis baseline: `https://pypi.org/pypi/schemathesis/json` → 4.28.0; docs schemathesis.readthedocs.io (checks incl. `not_a_server_error`); py `tests/web/test_contract.py:30` per prompt Context.
- Gaps recorded: (1) openapiv3 rust-version undeclared; (2) full issue-responsiveness medians not computed; (3) no empirical build run in this report (proposed checks above).
