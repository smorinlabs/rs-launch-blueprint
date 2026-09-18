# R83 openapi-contract-fuzzing — Opus raw research report

Engine: Claude Opus 5 (`claude-opus-5[1m]`). Run `research/runs/R83/2026-09-17T034011Z-2af391428997`.
All crates.io, GitHub, RustSec and PyPI figures were retrieved **2026-09-18** (UTC) by this
report; every endpoint is named where the figure is used and again under `### Sources`. Source
repositories were read through their programme pins: `py-launch-blueprint` at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` (cited `py@b08bccfb`), `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (cited `ts@cb1cbcb2`). Local toolchain for every
executed probe: `rustc 1.98.0 (88d9e12ae 2026-08-18)`, `cargo 1.98.0`, macOS (arm64).

### Landscape

**The category this item decides.** *Contract-driven fuzzing of an HTTP service*: a test suite
that reads the service's own OpenAPI document, generates request cases for **every** documented
operation with no hand-written per-operation test data, sends them at the service, and fails when
any case produces a server error (5xx) — run outside the default fast test loop. It is a test-tier
and test-harness question, not an API-design one: the document itself is R71's (`F332`), the
framework is R69's, the tiering mechanism is R32's.

**The Rust field in three bins.** Candidates were found by crates.io full-text search
(`GET https://crates.io/api/v1/crates?q=<terms>&per_page=<n>`, 2026-09-18), over the terms
`openapi fuzz` (107 hits), `schemathesis` (**0 hits**), `swagger fuzz` (19), `api fuzzing` (1,886),
`openapi contract test` (390), `json schema fake data` (253), `jsonschema generate arbitrary` (49)
and `openapi spec parse` (412); every crate named below came from those result sets.

| Bin | What is in it | Verdict for this category |
|---|---|---|
| Built-in / first-party toolchain | `cargo test` + `libtest`; `cargo-fuzz` + `libfuzzer-sys` (rust-fuzz working group); `proptest` 1.11.0 and `quickcheck` as generic property engines | **Empty for this category.** `libtest` has no plugin model, so nothing parametrises a test from a document. `cargo-fuzz` is coverage-guided *byte-string* fuzzing of a function, with no notion of an HTTP operation, a JSON Schema or a status code. The property engines generate from a `Strategy`, and nothing in-tree turns a JSON Schema into one. |
| Established industry standard | The standard exists — and it is **not a Rust crate**: `schemathesis` (Python; PyPI `4.27.4`, `https://pypi.org/pypi/schemathesis/json`; 3,609 stars, MIT, `pushed_at` 2026-09-18, `https://api.github.com/repos/schemathesis/schemathesis`). In Rust the nearest established artefact is `openapi-fuzzer` (577 stars, `https://api.github.com/repos/matusf/openapi-fuzzer`) — a standalone AGPL CLI binary, newest non-yanked release `0.2.0` of 2023-08-30 | No Rust **library** occupies this bin. One Rust **binary** does, and it has not shipped a release in 25 months. |
| Up-and-comers | `apifuzz` / `apifuzz-core` / `apifuzz-runner` 0.1.3 (2026-02-06); `momus-fuzz` 0.9.3 (2026-08-13); `mockforge-contracts` 0.3.223 (2026-09-18); `noson` 0.2.2 (2026-08-08, "Generate random JSON values from a JSON Schema"); the document parsers `oas3` 0.22.0 and `openapiv3` 2.2.0; `jsonschema` 0.56.0 (validation only) | Everything here is either <8 months old with ~0 adoption, or a *component* of an assembly rather than the capability itself. |

**Authorities used, and why each counts.**

| Source | Why it is authoritative |
|---|---|
| crates.io API (`/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`) | The registry itself: the only non-derived source for downloads, release dates, declared `rust_version`, licence and dependents. |
| RustSec advisory database (`https://rustsec.org/packages/<name>.html`; `cargo audit` 0.22.x against `RustSec/advisory-db` at commit `2b34578f89884736e0fcbd42f7ba8d6b10b4a0ce`, 2026-09-18) | The Rust Secure Code working group's published database — the gate-3 source of record. |
| GitHub REST (`/repos/<o>/<r>`, `/search/issues`, `/issues/<n>/comments`) | Primary maintenance evidence (`archived`, `pushed_at`, issue windows, who answered). |
| Maintainers' own sources, read at the published version rather than from documentation prose: `oas3` 0.22.0, `openapi-fuzzer` 0.2.0, `apifuzz-core` 0.1.3, `apifuzz-runner` 0.1.3 and `noson` 0.2.2 `.crate` tarballs from `https://static.crates.io/crates/<n>/<n>-<v>.crate` | The shipped code is the claim; READMEs are the advertisement. |
| OpenAPI Initiative specification v3.1.1 (`https://spec.openapis.org/oas/v3.1.1`), as cited by `oas3`'s own doc comments | The contract format's normative definition; it fixes what "every documented operation" means. |
| The Cargo Book on dev-dependencies and integration-test targets (`https://doc.rust-lang.org/cargo/reference/`) | First-party toolchain semantics for where a test-only dependency and an integration test live. |
| py@b08bccfb `tests/web/test_contract.py`, `pyproject.toml`, `Justfile`; `ts@cb1cbcb2` tree listing | The programme's own precedent, read at the pins rather than from memory. |

No blog post is used as an authority anywhere in this report.

**Practice evidence — who actually uses these, and why those projects are relevant.**

- `oas3` has **36 dependents** (`https://crates.io/api/v1/crates/oas3/reverse_dependencies`,
  2026-09-18). The most visibly well-regarded is **`slumber`** (`slumber_import` 5.3.0 depends on
  `oas3 ^0.20.0`) — a terminal HTTP client with **1,228 stars**, `pushed_at` 2026-09-02
  (`https://api.github.com/repos/LucasPickering/slumber`), which uses it to import OpenAPI
  collections. Others: `roast` 0.12.0 (`^0.22`), `oas3-gen` 0.28.0 (`^0.22`), `openapi_type` 0.6.1
  (`^0.22`), `rmcp-openapi` 0.31.5, `openapi-to-hurl` 1.2.1. The four newest dependents all track
  the current `0.22` line, which is the adoption signal that matters: dependents are *following*
  releases, not stranded on old ones.
- `proptest` 1.11.0: 48,579,875 downloads in 90 days, 189,599,555 all-time
  (`https://crates.io/api/v1/crates/proptest`, 2026-09-18). It is also already this template's
  property engine: **R33 (`property-and-snapshot-testing`) published `proptest` 1.11.0 as a
  `[dev-dependencies]` entry** (`research/topics/33-property-and-snapshot-testing/DECISION.md`),
  so the recommendation below adds no new generative-testing dependency to the repository.
- `openapi-fuzzer` (577 stars, 25 forks, 11,730 all-time downloads) is the only Rust artefact in
  this niche with real visible use, and its own source shows the shape of the problem: its
  generator is `src/arbitrary.rs`, **335 lines** mapping `openapiv3` schema kinds onto
  `proptest::strategy::Strategy` values, and its runner `src/fuzzer.rs` is **281 lines**
  (`wc -l` on the extracted `openapi-fuzzer-0.2.0.crate`, 2026-09-18).
- `schemathesis` itself is maintained by Dmitry Dygalo, who also maintains the Rust `jsonschema`
  crate (`https://crates.io/api/v1/crates/jsonschema` → `repository`
  `https://github.com/Stranger6667/jsonschema`, 0.56.0 of 2026-09-10, 22,074,141 downloads in 90
  days). That is the sharpest evidence available for the gap: the same maintainer ships a
  best-in-class Rust *validator* and ships the *generator* only in Python.

**Fit frame.** This template is CLI + library + an **optional** web surface behind the `web`
feature (R69). Anything recommended here must therefore (a) cost nothing when the web surface is
off, (b) run on `ubuntu-latest` and `macos-latest`, and (c) be excludable from the default test
loop. A standalone binary that needs a listening server, a Docker daemon or a second language
runtime is judged against that frame, not against "best fuzzer in general".

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

Source (py@b08bccfb `tests/web/test_contract.py`, quoted from the pin):

- lines 1–10 — module docstring: *"Schemathesis contract fuzzing straight from the OpenAPI schema
  (WEB-50). Generates property-based test cases for every documented operation and asserts none of
  them produce a 5xx. Marked ``slow`` (hypothesis generation), so the default `pytest` run skips
  it; CI runs `-m ""` and `just test-web` includes it. Scope note: checks are limited to
  ``not_a_server_error`` until error responses (401/422/...) are declared per-operation in the
  schema — widening to full response-conformance checks is the natural next step."*
- lines 21–23 — `schema = schemathesis.openapi.from_asgi("/openapi.json", create_app(WebSettings.model_construct()))`
- lines 26–30 — `@pytest.mark.slow` · `@schema.parametrize()` ·
  `@hypothesis_settings(max_examples=10, deadline=None)` · `def test_no_server_errors(case):` ·
  `case.call_and_validate(checks=(not_a_server_error,))`
- py@b08bccfb `pyproject.toml:277-278` — `markers = ["live: requires external services", "slow: takes >1s"]`
  and `addopts = "-m 'not live and not slow'"`: the exclusion is real, not decorative.
- py@b08bccfb `Justfile:300-301` — `@test-web *options:` → `uv run --extra web pytest tests/web -m "" {{options}}`:
  one documented command runs the excluded tier.

TypeScript state, verified rather than inherited: `git ls-tree -r --name-only cb1cbcb2` matched
nothing for `openapi`, `contract` or `web` (executed 2026-09-18). ts has no web service at all
(ledger row **F303**), so its absence of contract fuzzing is a **structural absence, not drift** —
there is no service to fuzz and no portable capability being declined. This is the opposite
finding to R33's, where both capabilities were portable and unadopted.

**What must agree (capability + policy), and what may vary.**

| # | Must agree across repos | Level |
|---|---|---|
| P1 | Every operation the published contract documents is exercised, enumerated *from the contract*, with no per-operation hand-written test data and no list of operation names in the test file | capability |
| P2 | Inputs are generated from each operation's declared schema, including its boundary values | capability |
| P3 | The assertion is *no server error* (no 5xx). Response-schema conformance is explicitly **not** asserted yet (py's own scope note) | policy |
| P4 | The suite is excluded from the default fast test run and is run by CI and by one documented command | policy |
| P5 | A failure names a reproducible, minimized request (operation, path, body) | capability |

May vary by ecosystem: the library or in-repo harness; the generator engine; whether the document
is fetched from the running service or read from a file; the number of cases per operation; the
transport (in-process router call versus a socket).

**Observable acceptance criteria** (criteria for P03 to prove against the real template, not
observations of it):

1. With the `web` surface enabled, one test enumerates every operation in the served OpenAPI
   document; adding a route and documenting it adds fuzz coverage with **no test-file edit**.
2. A handler that returns 5xx for an input the document declares valid fails that test.
3. The failure output names the operation and the minimized offending request.
4. Removing an operation from the router while it is still documented fails the test (drift).
5. The default developer test command does not run the suite; one documented command does.
6. The suite runs on `ubuntu-latest` and `macos-latest` with no service listening on a port, no
   container runtime and no second language runtime.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Evidence | Verdict |
|---|---|---|---|
| A1 | Adopt a dedicated Rust fuzzing crate/binary (`openapi-fuzzer`, `apifuzz`, `momus-fuzz`) | See `### Excluded by gate` — every one fails a fitness gate before popularity is weighed; the most adopted of them has no release since 2023-08-30 | **Rejected** |
| A2 | Assemble the capability in the repository: parse the served document, map each operation's schema to a `proptest` strategy, drive the router in process, assert no 5xx | Executed here — see *Probe* below: 220 lines, found and minimized a seeded defect in 0.01 s | **Recommended** |
| A3 | Run the language-agnostic `schemathesis` CLI in CI against a started server | Mature, actively developed (pushed 2026-09-18), strictly more capable than A2 | **Ranked runner-up**; costs a second language runtime and a listening server in CI |
| A4 | Generate requests from the **Rust request types** (`arbitrary`/`proptest` on the handler's `T` in `Json<T>`) instead of from the document | Cheapest of all, and idiomatic Rust | **Rejected on principle P1**: it tests the types, not the contract, so it cannot detect an operation documented but unrouted, a path-parameter type mismatch, or any drift between document and router |
| A5 | No contract fuzzing; rely on typed extractors plus example-based tests | Discussed under *the ecosystem difference* below | **Rejected**: it drops P1 and P4 entirely and the bug class is reduced, not empty |

**The justified ecosystem difference, stated plainly.** In FastAPI, an undeclared edge case in a
handler surfaces as an unhandled Python exception, which the framework turns into a 500 — the
class `not_a_server_error` is built to catch. In axum, the `Json<T>` extractor rejects a body that
does not deserialize into `T` **before the handler runs**, returning 4xx, so the largest slice of
that class is removed by the type system and the extractor rather than by a test. What survives in
Rust, and is what this suite is for: explicit 5xx mappings on paths the contract says are valid;
`unwrap`/`expect`/arithmetic edge cases inside a handler on *well-typed* input; path-parameter
schemas that disagree with the route's extractor type; and drift between the document and the
router. The principle survives; its yield is lower, which is an argument for a modest case count
(py uses `max_examples=10`), not for dropping it. The seeded defect in the probe below is
deliberately drawn from the surviving class — a documented-valid input that reaches the handler
and produces a 500 — and the harness caught it.

**Probe (executed, 2026-09-18).** A scratch workspace under `$TMPDIR` (deleted afterwards)
implementing A2 exactly: `axum` 0.8.9 + `tokio` 1.53.1 + `serde_json` as runtime dependencies;
`tower` 0.5.3, `oas3` 0.22.0 and `proptest` 1.11.0 as `[dev-dependencies]`; a router with
`POST /projects` (documented body `{name: string(1..8), limit: integer(0..100)}`), `GET
/projects/{id}` and `GET /openapi.json` serving an OpenAPI **3.1.0** document; a seeded defect
where `limit = 0` — a value the contract documents as valid — returns
`StatusCode::INTERNAL_SERVER_ERROR`. One integration test (`tests/contract_fuzz.rs`, **220 lines**
including comments) fetches `/openapi.json` through `tower::ServiceExt::oneshot`, parses it with
`oas3::from_json`, enumerates operations with `Spec::operations()`, builds a
`BoxedStrategy<serde_json::Value>` per operation from the JSON-Schema keywords `type`, `enum`,
`minimum`/`maximum`, `minLength`/`maxLength`, `minItems`/`maxItems`, `properties` and `items`
(resolving `$ref` via `Schema::resolve`), and runs `proptest::test_runner::TestRunner` with
`Config { cases: 16, failure_persistence: None, .. }` per operation, failing on
`status.is_server_error()`. Measured results:

- Defect present → `test result: FAILED`, with
  `projects-create: Test failed: 500 Internal Server Error for /projects body={"name":"a","limit":0}.`
  and proptest's `minimal failing input: ("/projects", Some(Object {"name": String("a"), "limit": Number(0)}))`.
  Criteria 1, 2, 3 observed.
- Defect fixed (the same input returns 400) → `test result: ok. 1 passed`, `finished in 0.01s` for
  2 operations × 16 cases.
- **A measured design requirement, not a guess:** the *first* version of the mapper drew integers
  uniformly from the documented range and the suite **passed while the defect was present** — 16
  uniform draws from `0..=100` missed `0`. Hypothesis (and therefore `schemathesis`) biases toward
  boundary values for free; an assembled mapper must ask for it. Adding an explicit
  `proptest::strategy::Union` over `{minimum, maximum, 0-if-in-range, uniform}` for integers and
  `{shortest, longest, uniform}` for strings — roughly 20 lines — turned the pass into the failure
  above. Any synthesis of this item must keep that requirement.
- Dependency cost, measured with `cargo tree` in the same workspace: **50** packages in the
  `-e normal` graph, **114** with `-e normal,dev` — the fuzz suite's ~64 extra crates are
  `[dev-dependencies]` and reach neither the shipped binary nor its size. Clean `cargo build`
  22.21 s wall / 34.65 s user; `cargo build --tests` 22.33 s wall / 69.30 s user on a 10-core
  machine: the test target roughly doubles CPU work at near-equal wall time.
- `cargo audit` over that workspace's lockfile (advisory-db at commit
  `2b34578f89884736e0fcbd42f7ba8d6b10b4a0ce`, 1,251 advisories loaded, 124 crate dependencies
  scanned) exited **0** with no vulnerable package.
- `oas3` 0.22.0 and the OpenAPI version, measured in the same workspace: a **3.1.0** document
  parses and `Spec::validate_version()` returns `Ok("3.1.0")`; the same document relabelled
  **3.0.3** still parses permissively (`from_json` ok, 2 operations enumerated) but
  `validate_version()` returns `Err("Unsupported spec file version (3.0.3)")`. `oas3`'s own source
  declares `OPENAPI_SUPPORTED_VERSION_RANGE = "~3.1"` (`src/spec/mod.rs:75`). **This is the one
  hard constraint R83 places on R71**: the committed/served document must be OpenAPI **3.1** JSON.

**BASELINE-REVIEW:** none. F334 is a `DIVERGENT` row that this item is asked to decide; nothing
inherited (`COMMON → REUSE` or `ADOPT`) is challenged by this recommendation, so no finding is
forwarded.

**Owner reference architecture — row-by-row disposition** (`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`,
a standing input, not a standard; `docs/planning/p02/owner-decisions.md` §11). Three of its rows
touch this item.

| Reference row | Position | Ground |
|---|---|---|
| **C3 OpenAPI** — "utoipa 5 + utoipa-axum 0.2" (line 50), spec emitted from serde types | **Agree**, as a hand-off: `utoipa` 5 emits OpenAPI **3.1**, which is exactly what `oas3` 0.22.0 requires (measured above). Not decided here — R71 owns F307/F312/F332/F333. R83's requirement on it is stated as a coupling, not a decision. |
| **C12 Testing** — "axum-test 18 … tower `oneshot` [alternative]: oneshot lower-level, more boilerplate" (lines 72, 117) | **Differ**, on recorded ground rather than preference: R69 revision 10 (owner-accepted 2026-09-18) already selects `tower::ServiceExt::oneshot` as the in-process idiom and makes `tower` 0.5.3 a `crates/web` dev-dependency. Using `axum-test` here would add a dependency whose fitness gates nothing in this programme has evaluated, to gain ergonomics the 220-line harness does not need (it issues one request type). The "more boilerplate" criticism did not materialise: the `oneshot` call is 3 lines of the 220. |
| **CI outline** — "cargo fmt --check → clippy -D warnings → sqlx prepare --check → cargo test → cargo deny check → OpenAPI export + diff" (lines 117, 377) | **Differ / extend**: the reference's CI has no contract-fuzz step at all. R83 adds one, after the OpenAPI export-and-diff step and inside the web job, excluded from the default local `cargo test`. Nothing in the reference is contradicted; a step it does not contain is added. |

Tally: **1 agree** (C3, as a hand-off), **2 differ** (C12 test driver, CI outline).

### Dominant choice

**None — and that is the finding.** There is no Rust-ecosystem equivalent of `schemathesis`: no
crate generates request cases for every documented operation directly from an OpenAPI/JSON-Schema
document and checks the live responses, at a maturity and gate standing this template can adopt.
The evidence is three-fold and each part is independently checkable:

1. crates.io full-text search for `schemathesis` returns **`total: 0`**
   (`https://crates.io/api/v1/crates?q=schemathesis&per_page=12`, 2026-09-18).
2. The only Rust artefact with adoption in the niche, `openapi-fuzzer`, is a **binary, not a
   library** (`default-run = "openapi-fuzzer"`, no `[lib]`, `src/main.rs` with `argh` argument
   parsing), and is excluded by fitness gate 2 below.
3. The three 2026-vintage attempts (`apifuzz`*, `momus-fuzz`, `mockforge-contracts`) are each under
   eight months old with adoption between 1 and 11 GitHub stars, and each fails a gate.

Consequently this item's named crate is the **anchor of an assembled design**, which the prompt's
own HIGH question anticipates ("or a hand-assembled combination of `proptest`/`quickcheck` plus an
OpenAPI-schema-to-strategy crate"): `oas3`, with `proptest` (already resident via R33) and `tower`
(already resident via R69). The assembly cost was measured, not estimated: **220 lines**.

### Qualified shortlist

Candidates that passed **every applicable gate**. Gate 1 (licence) is `inapplicable — owner ruling
2026-09-12 (Q7.B)` for every candidate in this item; licences are reported as facts and weigh
nothing. Gate 2's floor is **1.96** (stable 1.98.0 minus two minors), applied in the strict reading
the Wave-0 auditors established and R69 revision 10 applies: a candidate declaring **no**
`rust-version` fails. Figures: `https://crates.io/api/v1/crates/<name>` and `/versions`, and
`https://api.github.com/repos/<o>/<r>`, all retrieved 2026-09-18.

**Only three crates qualify, none of them a fuzzer — that a dedicated-fuzzer shortlist of size
zero is the honest result is the item's central finding.**

| Crate | Role in the design | 90-day downloads | All-time | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `oas3` 0.22.0 | parse the served OpenAPI 3.1 document; enumerate operations; expose each schema's JSON-Schema keywords with `$ref` resolution | 786,524 | 2,000,625 | 79 | 0.22.0, 2026-05-06 | **active** (`pushed_at` 2026-09-09; release PR open 2026-09-09; Dependabot merges through 2026-09-06) | `slumber_import` 5.3.0 (`slumber`, 1,228 stars); `roast` 0.12.0; `oas3-gen` 0.28.0; `openapi_type` 0.6.1 — 36 dependents in total | OpenAPI **3.1 only** at `validate_version()`; a 3.0 document parses but is not validated (measured) |
| `proptest` 1.11.0 | the generative engine, shrinking and failure reporting | 48,579,875 | 189,599,555 | — (workspace `proptest-rs/proptest`) | 1.11.0, 2026-03-24 | **active** | already this template's property engine (R33, published) | generic: it has no schema front end, which is exactly the ~220 lines this item owns |
| `jsonschema` 0.56.0 | **optional, not adopted now**: response-schema conformance if P3 is ever widened | 22,074,141 | 90,900,038 | — (`Stranger6667/jsonschema`) | 0.56.0, 2026-09-10 | **active** | — | validation only; it cannot generate, so it does not shorten the assembly |

Declared `rust-version` (gate 2), licence (reported, not gated), advisories (gate 3, from
`https://rustsec.org/packages/<name>.html`, 2026-09-18) and platform posture (gate 4):

| Crate | `rust-version` | Licence (reported) | RustSec page | Gates 3–6 |
|---|---|---|---|---|
| `oas3` 0.22.0 | **1.87** — pass | MIT | HTTP 404 → no advisory | no `unsafe` needed by this use; pure-data parsing, no async runtime coupling; default features `preserve-order` only, `yaml-spec` **not** enabled (JSON only); dev-dependency, so zero binary-size cost |
| `proptest` 1.11.0 | **1.85** — pass | MIT OR Apache-2.0 | HTTP 404 → no advisory | runtime-agnostic; dev-dependency; compile cost folded into the test target measured above |
| `jsonschema` 0.56.0 | **1.85.0** — pass | MIT | HTTP 404 → no advisory | not adopted now; figures recorded so a later widening of P3 need not re-survey |

Gate 4 (`ubuntu-latest, macos-latest`) for the recommended pair is evidenced directly rather than
by badge: the full probe — `oas3` + `proptest` + `axum` + `tokio` + `tower` — **was built and run
on macOS/arm64 with stable 1.98.0** in this report, and `oas3`'s and `proptest`'s dependency trees
are platform-neutral Rust with no system libraries. The Linux leg is inference from that
platform-neutrality and is listed as an unexecuted check under `### Validation strategy`.
Gate 5: neither crate pulls an async runtime; `tokio` enters only through the web surface R69
already declares. Gate 6: both are `[dev-dependencies]` — **no binary-size cost at all**; compile
cost is the measured +64 crates / +34.7 s CPU on the test target.

Issue responsiveness (gate-adjacent maintenance evidence), `oas3`, from the 10 most recently
opened **issues** (`https://api.github.com/search/issues?q=repo:x52dev/oas3-rs+is:issue&sort=created&order=desc&per_page=10`,
window 2025-01-07 → 2026-05-03, comment authors read per issue):

| Issue | Opened | First maintainer (`robjtede`) response | Days |
|---|---|---|---|
| #333 | 2026-05-03 | 2026-05-05 | 2 |
| #318 | 2026-03-25 | none (closed with no comment) | unanswered |
| #300 | 2026-01-12 | 2026-03-26 | 73 |
| #281 | 2025-11-25 | none (still open) | unanswered |
| #278 | 2025-11-22 | none (closed with no comment) | unanswered |
| #275 | 2025-11-16 | none (only the reporter commented) | unanswered |
| #236 | 2025-08-22 | 2025-08-26 | 4 |
| #234 | 2025-08-15 | 2025-08-15 | 0 |
| #160 | 2025-01-14 | none | unanswered |
| #157 | 2025-01-07 | 2 comments, authors not read | not verified |

**Median days to first maintainer response among the four measured answers: 3. Unanswered: 5 of
10, one not verified.** Two of the unanswered were closed silently, which is consistent with
fix-and-release rather than neglect; 5 open issues total
(`search/issues?q=repo:x52dev/oas3-rs+is:issue+is:open` → `total_count` 5). Verdict **active**, not
`stable-quiet`: releases and dependency merges are continuous.

### Excluded by gate

| Candidate | Newest non-yanked | Licence (reported, not gated) | Gate outcome | Detail |
|---|---|---|---|---|
| `openapi-fuzzer` 0.2.0 | 2023-08-30 | AGPL-3.0-or-later | **Gate 2 — FAIL (no `rust-version` declared)**; independently **maintenance: at-risk** | 45 downloads in 90 days, 11,730 all-time; 577 stars, 25 forks, `archived: false`, `pushed_at` **2024-01-29**, 12 open issues. Edition 2018. Maintenance evidence is concrete, not merely "old": community issue #43 (2024-03-19) has **zero** comments; issue #40 (2024-01-10) has three comments, **none from the maintainer** (two from the reporter, one from a third party in 2024-12); community PR #41 (2024-01-29) is still open. A build of the published source on stable 1.98.0 **succeeded** in 25.6 s, so the rubric's `dormant` trigger "broken build on current stable" is **not** met — hence `at-risk`, not `dormant`. `cargo audit` against its **published `Cargo.lock`** reports **6 vulnerabilities and 6 warnings** (including `RUSTSEC-2024-0336` `rustls` 0.19.0 infinite loop, `RUSTSEC-2023-0052` `webpki` DoS, `RUSTSEC-2025-0009` `ring` panic, plus unmaintained `ring < 0.17`, `yaml-rust`, `instant`); after `cargo update` only two *unmaintained* warnings remain (`rustls-pemfile`, `yaml-rust` via `serde_yaml` 0.8), so the vulnerability count is an artefact of the frozen lockfile and is reported as such. |
| `apifuzz` 0.1.3 / `apifuzz-core` 0.1.3 / `apifuzz-runner` 0.1.3 | 2026-02-06 | MIT | Gate 2 **pass** (`rust-version` 1.85, edition 2024) — **Gate 4 — FAIL** | The only dedicated fuzzer that clears gate 2, which is why it was checked rather than assumed. Its CI (`.github/workflows/ci.yml`, read 2026-09-18) has exactly one job, `runs-on: ubuntu-latest`; there is **no macOS leg**, so the fixed `target-os-matrix` is not evidenced. Adoption: `apifuzz` 27 downloads in 90 days / 107 all-time; repo `ynishi/apifuzz` has **0 stars**, no description, no open issues, `pushed_at` 2026-02-06 — four releases inside 48 hours and nothing since. README claims six checks (5xx, status conformance, negative testing, response time, schema validation, content-type), and the code is substantial (`apifuzz-runner/src/datagen.rs` alone is 922 lines), so this is a real attempt, not a stub; it is simply unevidenced on the required matrix and unadopted. |
| `noson` 0.2.2 | 2026-08-08 | MIT OR Apache-2.0 | **Gate 2 — FAIL (no `rust-version` declared)** | The single closest thing to `hypothesis-jsonschema` in Rust — "Generate random JSON values from a JSON Schema", 5,947 lines including a `xeger` regex-to-string module for `pattern` support, edition 2024, actively pushed (2026-09-12). Adoption 313 / 1,526 downloads, **1 star**. Had it declared an MSRV it would have shortened this item's assembly considerably; as it stands the assembly implements the keyword subset itself. This is the candidate to re-check first (see re-verify triggers). |
| `momus-fuzz` 0.9.3 | 2026-08-13 | Apache-2.0 | **Gate 2 — FAIL (no `rust-version` declared)** | "Payload mutation engine — boundary, encoding, type mismatch, cardinality mutators"; 1,943 downloads (all inside 90 days), **63 published versions between 2026-08-04 and 2026-08-13**, repo `jlcoulter/momus` 1 star, 1 open issue. A release cadence of six versions a day with no adoption is a stability signal against it independent of the gate. |
| `mockforge-contracts` 0.3.223 | 2026-09-18 | MIT OR Apache-2.0 (repo `NOASSERTION`) | **Gate 2 — FAIL (no `rust-version` declared)**, and **fit** | Part of MockForge, a mocking framework (repo 11 stars, 50 open issues, 97 published versions). Its "contract testing, drift detection" validates mocks and recorded traffic against a spec; it does not generate a case per documented operation against the service under test. Wrong problem, before the gate. |
| `openapiv3` 2.2.0 | 2025-06-02 | MIT/Apache-2.0 | **Gate 2 — FAIL (no `rust-version` declared)** | The most-downloaded OpenAPI parser by a wide margin (2,978,577 in 90 days; 12,992,586 all-time) and the one `openapi-fuzzer` itself uses — and it declares no MSRV on its newest non-yanked version, so under the strict reading it cannot be this item's parser. It is also **OpenAPI 3.0-shaped**, while `utoipa` (the reference architecture's C3 pick) emits 3.1. Both facts point the same way: `oas3`. |

### Up-and-comers

- **`noson` 0.2.2** (`glennib/noson`, 1 star, `pushed_at` 2026-09-12, 313 / 1,526 downloads, MIT OR
  Apache-2.0, edition 2024). JSON-Schema → random JSON value generation, the exact missing piece.
  **Watch condition:** it declares a `rust-version` at or below the then-current floor *and*
  acquires either dependents on crates.io or a second maintainer. Adopting it would delete roughly
  120 of this item's 220 lines.
- **`apifuzz` family 0.1.3** (`ynishi/apifuzz`). **Watch condition:** a macOS CI leg plus any
  release after 2026-02-06. It is the only dedicated fuzzer already inside the MSRV policy.
- **`momus-fuzz`** and **`mockforge-contracts`**: recorded for completeness; neither is on a path
  this template should track today.
- **`jsonschema` 0.56.0**: not a fuzzer, but the crate that would implement a widening of P3 to
  response-schema conformance — py's own "natural next step".
- **`schemathesis` 4.27.4 itself**: actively developed (`pushed_at` 2026-09-18) and, per its PyPI
  summary, now "Adaptive API testing for OpenAPI **and GraphQL**". If it ever ships a
  self-contained native binary (as `ruff` and `uv` did for Python tooling), the runner-up below
  becomes materially cheaper and should be re-evaluated.

### Fit for this template

- **CLI** (`rslbp`): **no effect**. The recommendation adds nothing to the binary, its dependency
  tree or its size — every crate named is a `[dev-dependencies]` entry of the optional web member,
  and dev-dependencies never enter a shipped artefact. `cargo build` for the CLI with the `web`
  feature off resolves none of them.
- **Library** (`rs-launch-blueprint` core): **no effect**, and deliberately so. R01's port seam,
  R05's synchronous core and the domain types are untouched; the fuzz suite exercises the service
  through its HTTP surface only, which is the same boundary py's suite uses
  (`schemathesis.openapi.from_asgi`, an ASGI-level call, not a function-level one).
- **Web** (`crates/web`, behind the `web` feature): **the entire fit**. One new file,
  `crates/web/tests/contract_fuzz.rs`; one new dev-dependency line in `crates/web/Cargo.toml`;
  one CI step; one `Justfile` recipe. It exists only when the web surface exists, which matches
  the feature's own conditionality and py's `--extra web` shape (`Justfile:300-301`).

### Recommendation

**Adopt an in-repository contract-fuzz harness anchored on `oas3`, with `proptest` as the
generator and `tower::ServiceExt::oneshot` as the transport. Named crate and version range:
`oas3 = "0.22.0"` — Cargo's caret semantics make that `>=0.22.0, <0.23.0` — as a
`[dev-dependencies]` entry of `crates/web`.** The two companions are already resident and are not
new decisions: `proptest = "1.11.0"` (R33, published) and `tower = "0.5.3"` (R69 revision 10,
owner-accepted). No runtime dependency is added anywhere.

Concretely, and matching each principle:

| Element | Decision | Principle |
|---|---|---|
| Location | `crates/web/tests/contract_fuzz.rs`, a normal integration test of the optional member — **no file-level `#![cfg(feature = "web")]`**, because R69 revision 10 makes the whole member optional | P4 |
| Schema discovery | **Fetch the served document in process**: `oneshot` a `GET` at the router's OpenAPI path and parse the response body with `oas3::from_json`. This mirrors py's `schemathesis.openapi.from_asgi("/openapi.json", app)` exactly, needs nothing from R71 beyond the path, and tests the document the service actually serves. Reading R71's committed snapshot file instead would test a file, and R71's own staleness test (F332) already asserts served == committed — so fetching loses nothing and catches one more failure mode | P1 |
| Enumeration | `Spec::operations()` → `(path, method, &Operation)` for every documented operation; no list of operation names in the test | P1 |
| Generation | Per operation, a `BoxedStrategy<serde_json::Value>` built from the operation's path/query parameter schemas and its `application/json` request-body schema, with `$ref` resolved through `Schema::resolve`; keyword subset `type`, `enum`, `minimum`/`maximum`, `minLength`/`maxLength`, `minItems`/`maxItems`, `properties`, `items`; **explicit boundary bias** via `Union` over `{min, max, 0-if-in-range, uniform}` and `{shortest, longest, uniform}` | P2 |
| Case count | `proptest::test_runner::Config { cases: 16, failure_persistence: None, .. }` per operation (py uses `max_examples=10`; 16 was the probe's value and costs 0.01 s for two operations). `failure_persistence: None` because a counterexample here is a *service* defect to fix, not a seed to replay — unlike R33's property suite, which commits `proptest-regressions/` | P2, P5 |
| Check | **`not_a_server_error` only**: fail when `status.is_server_error()`. Response-schema conformance is deliberately **not** asserted, carrying py's own scope note forward — until error responses are declared per operation, conformance checking would fail on undeclared-but-correct 4xx responses. Recorded as the documented next step, with `jsonschema` 0.56.0 as its implementation when R70/R71 declare those responses | P3 |
| Transport | `tower::ServiceExt::oneshot` against the `Router`, inside a `tokio` current-thread runtime built in a plain `#[test]` (**not** `#[tokio::test]`: `TestRunner::run` takes a synchronous closure, and calling `block_on` inside an active runtime panics) | P4, P6 |
| Exclusion from the default run | **R32 owns the mechanism**; this item states the requirement and the three Rust mechanisms available: (a) `#[ignore]` plus `cargo test -- --ignored`; (b) a dedicated `[[test]]` target selected by name (`cargo test --test contract_fuzz`); (c) a dedicated Cargo feature such as `contract-fuzz`. **The `web` feature cannot serve as the marker**: R02 revision 1's check `B3` observed `cargo build --workspace` compiling the optional web member with the feature off, because workspace membership decides the build set — so a `--workspace` test run would run this suite unless one of (a)–(c) is applied | P4 |

Why `oas3` and not the obvious alternative: `openapiv3` 2.2.0 is 6.5× more downloaded, and fails
gate 2 by declaring no `rust-version`; it is also 3.0-shaped while the reference architecture's
OpenAPI generator (`utoipa` 5, C3) emits 3.1. `oas3` declares 1.87, is actively released, models
OpenAPI 3.1 natively, and — measured here — exposes exactly the two APIs this design needs
(`Spec::operations()`, `Schema::resolve`) plus every JSON-Schema keyword as a typed field.

### Ranked runner-up

**`schemathesis` 4.27.4 itself, invoked as a language-agnostic CLI in the CI web job against a
started server.** It is the same tool py uses, so principle agreement would be exact rather than
reconstructed; it is actively developed (3,609 stars, `pushed_at` 2026-09-18); and it is strictly
more capable than the harness above — stateful test sequences, negative testing, response
conformance, header and `format` coverage the 220-line mapper does not implement.

**The condition under which it wins:** when the assembled mapper's keyword coverage stops being
enough — concretely, when the template's OpenAPI document starts using `oneOf`/`allOf`/
`discriminator`, `format`-constrained strings (`uuid`, `date-time`, `email`), `pattern`, or when
P3 is widened to response-schema conformance — *or* when maintaining the mapper costs more than
one developer-day per year. At that point, buying a maintained implementation beats extending an
in-repo one.

**What it costs today, which is why it is second:** it needs (a) a **listening server**, so the
web binary must be started and torn down in CI rather than the router exercised in process; (b) a
**second language runtime** in a Rust template's CI (`uvx schemathesis` or `pip install`), or a
container image — and `macos-latest` GitHub runners have no Docker daemon, so the container route
cannot satisfy the fixed `target-os-matrix` and the Python route must run on both legs; (c) a
tension with R42's published `package-manager-invocation` value, which says to invoke tools as
bare executables on `PATH` with "no provisioner, runner or package-manager prefix in any Justfile
recipe or lefthook job" — `uvx schemathesis …` is exactly such a prefix. **That tension is named,
not resolved: R42 is not this item's to change, and the recommendation avoids it entirely.**

Third, for completeness: `openapi-fuzzer` 0.2.0 wins only if it declares a `rust-version`, ships a
release, and answers its open issues — three conditions simultaneously, on a project whose
maintainer has not commented since 2023.

### Tradeoffs

**Versus `schemathesis` as a CLI (the ranked runner-up).** Given up: stateful sequences, negative
testing, response-schema and content-type conformance, `format`/`pattern` coverage, and a
maintained implementation of all of it — the template owns ~220 lines it must keep working instead.
Accepted because: the suite runs **in process** (0.01 s for 2 operations × 16 cases, measured) with
no server start, no port, no container and no second language runtime on either OS of the fixed
matrix; because the added surface is dev-only and adds nothing to the shipped binary; and because
the depth given up is depth this template's document cannot yet exercise — the first version of a
generated 3.1 document has no `oneOf`, no `discriminator` and no declared error responses, which
is also why py's own suite runs with `checks=(not_a_server_error,)` and `max_examples=10`.

**Versus adopting a dedicated Rust crate (`apifuzz`).** Given up: zero assembly cost. Accepted
because the crate is unevidenced on `macos-latest` (gate 4), has 0 stars and 107 all-time
downloads, and has had no release since 2026-02-06 — the template would be the project's first
serious user and its de-facto maintainer, which is a larger liability than 220 lines it controls.

**Versus generating from the Rust request types (`arbitrary`/`proptest` on `T`).** Given up: ~150
of the 220 lines, and a schema-parsing dependency. Rejected because it silently drops P1: it
cannot notice an operation that is documented but unrouted, a path-parameter schema that disagrees
with the extractor, or any other document-to-router drift — which is most of what remains of the
bug class in a typed Rust service.

**Versus `openapiv3` as the parser.** Given up: 6.5× the downloads and the parser
`openapi-fuzzer` itself uses. Rejected on gate 2 (no declared `rust-version`) and on fit
(3.0-shaped against a 3.1 document).

**The residual risk, stated plainly.** The mapper is template-owned code that can silently
under-generate — the probe demonstrated exactly that failure mode, where a missing boundary bias
turned a real defect into a green test. A harness that generates weakly still passes. The
mitigation is criterion 2 of `### Validation strategy`: a deliberately seeded 5xx must fail the
suite, and that check must be run whenever the mapper changes, not only once.

### Parameters

This item owns no parameter (`research/CLAUDE.md` R83 row: `owns` is empty).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**Note beside the `web-extra-surface` line (not a conflict).** The bytes above are the live
`docs/port/PARAMETERS.md` row, which still carries R69 **revision 9**'s form (`src/web/`, a
file-level `#![cfg(feature = "web")]` on the web tests, skip-gating on `src/web/**`). R69
**revision 10** is owner-accepted but unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, owned-value line 1791;
owner ruling W1-R02/W0-R69c): the `web` feature names the optional member `crates/web`, the web
integration tests live in **`crates/web/tests/`** with **no file-level `cfg`** because the whole
member is optional, and skip-gating keys on **`crates/web/**`**. **This design uses revision 10's
paths** — `crates/web/tests/contract_fuzz.rs`, `crates/web/Cargo.toml` — and R69's republication is
recorded as a re-verify trigger below. No `CONFLICT:` line is raised: nothing this recommendation
needs requires a consumed value to change.

`msrv-policy` is consumed twice and both readings are satisfied: the recommended crates declare
1.87 and 1.85 against the 1.96 floor, and the probe's resolved dependency graph — 124 packages,
102 of which declare a `rust-version` — contains no declared `rust-version` above the floor other
than the probe package's own 1.96.

### Migration implications

File-level changes in the template (all inside the optional web member; nothing outside it moves):

| Path | Change |
|---|---|
| `crates/web/Cargo.toml` | add `oas3 = "0.22.0"` to `[dev-dependencies]`. `proptest = "1.11.0"` (R33) and `tower = { version = "0.5.3", features = ["util"] }` (R69) are already there or are added by those items; no `[dependencies]` entry anywhere |
| `crates/web/tests/contract_fuzz.rs` | **new**, ~220 lines: served-document fetch via `oneshot`, `oas3` parse, operation enumeration, schema→`Strategy` mapper with boundary bias, `TestRunner` loop, `is_server_error()` assertion, failure message naming `operationId`, path and body |
| `crates/web/src/` | **no change** — the suite needs only the existing `build_router()` and whatever route R71 chooses for the served document |
| `Justfile` | one recipe running the excluded tier, the analogue of py's `Justfile:300-301` `test-web`. Its exact spelling follows R42's published `package-manager-invocation` (bare `cargo`, no runner prefix) and R32's exclusion mechanism |
| CI workflow | one step in the web job, after R71's OpenAPI export-and-diff step. **No new third-party action is introduced**, so R20's published `enforced-owner-prefix-pinning` policy is satisfied without a new pin. Whether the step is its own job or a step in a shared job is R11's (`ci-job-structure`, still open) |
| `CONTRIBUTING`/docs | one paragraph: what the suite does, the single command that runs it, and that a failure prints a minimized request to reproduce |
| Ledger | **F334** is settled by this item as: adopted, as an in-repo `oas3` + `proptest` harness rather than a third-party fuzzer, because no Rust equivalent of `schemathesis` exists. Verdict `DIVERGENT` and origin `py-only` remain factually correct at both pins; verdict strings stay the controller's to set |

Coupling hand-offs, none of which this item decides:

- **R71 (`openapi-generation-pipeline`)** — R83 needs three things from it and asserts none of
  them: (1) the document is **OpenAPI 3.1 JSON** (measured constraint: `oas3` 0.22.0's
  `validate_version()` rejects 3.0.3); (2) the router **serves** it at a known path (py serves
  `/openapi.json`); (3) operations carry stable `operationId`s, which this suite uses to name a
  failure. If R71 chooses a generator that emits only 3.0, this item's parser choice must be
  revisited — that is a re-verify trigger, not a conflict.
- **R32 (`test-harness-and-execution`)** — owns which of the three exclusion mechanisms marks this
  suite, and must account for check `B3` above (a `--workspace` run reaches the optional member).
- **R11 (`ci-job-structure`)** — owns job shape and the `crates/web/**` skip-gating key.
- **R84 (`openapi-typed-client-generation`)** — separate concern; the two share only the document.

### Validation strategy

**Executed in this report (2026-09-18, macOS arm64, stable 1.98.0), in a scratch workspace under
`$TMPDIR` that has been deleted:**

| # | Command | Expected | Observed |
|---|---|---|---|
| 1 | `cargo test --test contract_fuzz` with a seeded 5xx on a documented-valid input | fail, naming a minimized request | **FAILED**: `projects-create: Test failed: 500 Internal Server Error for /projects body={"name":"a","limit":0}.` + `minimal failing input: ("/projects", Some(Object {"name": String("a"), "limit": Number(0)}))` |
| 2 | the same after the handler returns 400 for that input | pass | `test result: ok. 1 passed`, `finished in 0.01s` |
| 3 | operation enumeration from the **served** document | every documented operation, from the document alone | `operations discovered: 2`, both fuzzed, no operation names in the test |
| 4 | `cargo audit` on the probe lockfile (advisory-db `2b34578f…`, 1,251 advisories) | no vulnerable package | exit 0, 124 crate dependencies scanned |
| 5 | `cargo tree -e normal` vs `-e normal,dev` | the suite is dev-only | 50 vs 114 packages |
| 6 | `cargo build` vs `cargo build --tests` (clean target dir) | modest added compile cost | 22.21 s / 34.65 s user vs 22.33 s / 69.30 s user |
| 7 | `oas3::from_json` + `Spec::validate_version()` on 3.1.0 and on the same document relabelled 3.0.3 | 3.1 accepted | `Ok("3.1.0")` and `Err("Unsupported spec file version (3.0.3)")` |
| 8 | `cargo build` of `openapi-fuzzer` 0.2.0 source on stable 1.98.0 | decides `at-risk` vs `dormant` | built in 25.61 s → **not** dormant by the rubric's build criterion |
| 9 | `cargo audit` on `openapi-fuzzer`'s published lockfile, then after `cargo update` | quantify its advisory exposure | 6 vulnerabilities + 6 warnings frozen; 2 unmaintained warnings after update |

**Planned for P03, not executed here** (this repository contains no Rust code; P02 is research
only):

1. The same nine checks re-run on `ubuntu-latest` — the Linux leg of gate 4 is inference from
   platform-neutral dependency trees, not an observation.
2. Criterion 1 of the acceptance list: add a documented route and confirm fuzz coverage grows with
   **no edit** to `contract_fuzz.rs` (`git diff --stat` on the test file must be empty).
3. Criterion 4: remove a route while leaving it documented; the suite must fail (drift detection).
4. Criterion 5: the default developer command must **not** run the suite, and the documented
   command must — asserted both ways, including under `cargo test --workspace` (check `B3`).
5. Wall-clock budget on a real document with ~10 operations at 16 cases each, to confirm the tier
   stays worth excluding rather than becoming cheap enough to run by default.
6. A mapper-coverage assertion: for each operation, that the generator produced at least one case
   at each declared boundary — the guard against the silent under-generation the probe exhibited.

### Confidence & re-verify trigger

**High confidence** (directly evidenced, cheap to re-check): that no Rust crate reproduces
`schemathesis` today; the gate verdicts on every candidate; that the assembly works, finds a
seeded defect and shrinks it; the dependency, compile and advisory figures; that `oas3` 0.22.0
requires OpenAPI 3.1 at `validate_version()`.

**Medium confidence:** that a ~220-line mapper stays adequate as the template's document grows —
this is the tradeoff most likely to be revisited, and the ranked runner-up exists for exactly that
eventuality. Also medium: the case count (16) and the exact keyword subset, both of which P03 may
tune without changing the decision.

**Explicitly not established:** the Linux leg of gate 4 by observation; the median
time-to-first-response for `oas3` issue #157 (comment authors not read); any figure for
`momus-fuzz`/`mockforge-contracts` beyond registry and repository metadata, since both fail gate 2
before fit is weighed.

**Re-verify when any of these happens** — re-verify immediately, or by **2027-03-18**, whichever
comes first:

1. **R71 publishes** — if its generator emits OpenAPI 3.0, or does not serve the document from the
   router, the discovery mechanism and possibly the parser change.
2. **R32 publishes** — the exclusion mechanism is named there; this item currently states a
   requirement and three options.
3. **R69 republishes** (revision 10 or later reaching `docs/port/PARAMETERS.md`) — the `assumes`
   line above must be re-bound to the new registry bytes, and the `crates/web` paths this design
   uses confirmed rather than anticipated.
4. **`noson` declares a `rust-version`** within the floor, or acquires dependents — it would
   replace the largest part of the mapper.
5. **`apifuzz` adds a macOS CI leg and ships a release after 2026-02-06** — it clears gate 2
   already and would become a live A1 candidate.
6. **Any new crate appears** for schema-driven HTTP fuzzing: re-run the four crates.io searches
   that produced this landscape (`openapi fuzz`, `schemathesis`, `api fuzzing`, `swagger fuzz`).
7. **`oas3` publishes 0.23 or 1.0**, or raises its `rust-version` above the then-current floor;
   likewise `proptest` past 1.11.
8. **The owner rules on whether fitness gate 2 reaches non-linked developer tools** (the open
   question R69 revision 10 records in its own re-verify line). A ruling that it does not would
   re-admit `openapi-fuzzer` and `noson` as candidates — though `openapi-fuzzer` would still be
   excluded on maintenance.
9. **The `msrv-policy` floor advances past 1.96** — re-check every declared `rust-version` here.
10. **`schemathesis` ships a self-contained native binary** — the runner-up's main cost disappears.

### Sources

**crates.io** (`https://crates.io/api/v1/…`, all retrieved 2026-09-18): search endpoint
`crates?q=openapi%20fuzz`, `q=schemathesis`, `q=swagger%20fuzz`, `q=api%20fuzzing`,
`q=openapi%20contract%20test`, `q=json%20schema%20fake%20data`,
`q=jsonschema%20generate%20arbitrary`, `q=openapi%20spec%20parse`; crate endpoints
`crates/openapi-fuzzer`, `crates/apifuzz`, `crates/apifuzz-core`, `crates/apifuzz-runner`,
`crates/noson`, `crates/momus-fuzz`, `crates/mockforge-contracts`, `crates/openapiv3`,
`crates/oas3`, `crates/proptest`, `crates/jsonschema` (fields `crate.recent_downloads`,
`crate.downloads`, and `versions[]` filtered to `yanked: false` for `num`, `created_at`, `license`,
`rust_version`, `edition`); `crates/oas3/reverse_dependencies?per_page=15`.

**GitHub REST** (`https://api.github.com/…`, retrieved 2026-09-18, one call per ≥20 s):
`repos/matusf/openapi-fuzzer`, `repos/matusf/openapi-fuzzer/issues?state=all&sort=created&direction=desc&per_page=10`,
`repos/matusf/openapi-fuzzer/issues/40/comments`,
`search/issues?q=repo:matusf/openapi-fuzzer+is:issue+is:open` (`total_count` 12);
`repos/ynishi/apifuzz`, `search/issues?q=repo:ynishi/apifuzz+is:issue+is:open` (0),
`repos/ynishi/apifuzz/contents/.github/workflows` and the workflow body from
`https://raw.githubusercontent.com/ynishi/apifuzz/main/.github/workflows/ci.yml`;
`repos/x52dev/oas3-rs`, `search/issues?q=repo:x52dev/oas3-rs+is:issue+is:open` (5),
`search/issues?q=repo:x52dev/oas3-rs+is:issue&sort=created&order=desc&per_page=10`, and
`repos/x52dev/oas3-rs/issues/{333,300,275,236,234}/comments`; `repos/glennib/noson`;
`repos/jlcoulter/momus`; `repos/SaaSy-Solutions/mockforge`;
`repos/LucasPickering/slumber`; `repos/schemathesis/schemathesis`.

**RustSec** (retrieved 2026-09-18): `https://rustsec.org/packages/{openapi-fuzzer,apifuzz,apifuzz-core,apifuzz-runner,noson,oas3,proptest,openapiv3}.html`
— every one HTTP **404**, i.e. no advisory page exists for any of them; and `cargo audit` 0.22.x
against `RustSec/advisory-db` at commit `2b34578f89884736e0fcbd42f7ba8d6b10b4a0ce` (2026-09-18),
1,251 advisories loaded.

**PyPI** (2026-09-18): `https://pypi.org/pypi/schemathesis/json` — `info.version` 4.27.4,
`requires_python >=3.10`.

**Crate sources read at the published version** (`https://static.crates.io/crates/<n>/<n>-<v>.crate`,
2026-09-18): `openapi-fuzzer-0.2.0` (`Cargo.toml`, `src/arbitrary.rs` 335 lines, `src/fuzzer.rs`
281 lines, `src/main.rs` 174, `src/stats.rs` 32), `apifuzz-core-0.1.3` (`Cargo.toml`, `README.md`,
8 modules), `apifuzz-runner-0.1.3` (`src/datagen.rs` 922 lines), `noson-0.2.2` (`Cargo.toml`,
5,947 lines across 5 modules), `oas3-0.22.0` (`src/lib.rs`, `src/spec/mod.rs` including
`OPENAPI_SUPPORTED_VERSION_RANGE = "~3.1"` at line 75 and `Spec::operations()` at line 205,
`src/spec/schema.rs`, `src/spec/parameter.rs`).

**Repository and programme documents:** py@b08bccfb `tests/web/test_contract.py:1-30`,
`pyproject.toml:80,277-278`, `Justfile:300-301`; `ts@cb1cbcb2` full tree listing (no web, OpenAPI
or contract file); `docs/port/COMMONALITY.md:338` (F334), `:307` (F303), `:336-337` (F332/F333),
`:339` (F335); `docs/port/PARAMETERS.md` (the five consumed rows, byte-copied);
`docs/port/README.md` (verdict vocabulary); `docs/port/OWNER-REVIEW.md:47-59` (the 2026-09-12
licence ruling, quoted verbatim there); `docs/planning/p02/owner-decisions.md` §5 (gate 1 struck),
§11 (the reference architecture as a standing input), and the "two things you should know" section
recording the withdrawal of the lenient MSRV reading;
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` lines 50, 72, 89, 116-117,
377; `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision 10,
owner-accepted, unpublished — owned value at line 1791, gate-2 strict reading and the 1.96 floor at
lines 1481-1497, `tower` dev-dependency finding at line 2260-2267);
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:128,251` (check `B3`);
`research/topics/33-property-and-snapshot-testing/DECISION.md` (`proptest` 1.11.0 published);
`research/topics/20-third-party-action-pinning-policy/DECISION.md:48-54`
(`enforced-owner-prefix-pinning`); `docs/port/PARAMETERS.md` `package-manager-invocation` row (R42).

**Method notes.** Figures came from the endpoints named above and nowhere else; nothing in this
report is quoted from memory, and every version, licence, `rust_version`, star count and date was
read from a live response on 2026-09-18 rather than from documentation prose. GitHub calls were
spaced at ≥20 s. Two early attempts to batch those calls in a backgrounded shell script were
terminated by the harness after their first call, which produced a small number of duplicate
requests inside one 20 s window before the pattern was abandoned; the duplicates returned identical
payloads and no figure depends on which copy was read. The executed probes ran under a directory
created beneath `$TMPDIR` and deleted afterwards; no file outside this report's own path was
written. **What I could not verify:** the Linux leg of fitness gate 4 for any candidate (no
`ubuntu-latest` runner was available to this report — the recommended stack was built and run on
macOS/arm64 only, and `apifuzz`'s CI was read rather than executed); the comment authors of `oas3`
issue #157, so its first-maintainer-response time is recorded as not verified; whether
`cargo test --workspace` *runs* (as opposed to *builds*) the optional member's tests with the
feature off — R02's check `B3` observed the build and the test consequence is stated here as an
inference; and the unsafe-code posture of `oas3` and `proptest` beyond the absence of any
`unsafe` requirement in the probe's own code, which was not a `grep`-level audit of their sources.
