# 2026-09-17 — R48 — mocking-crates (bundle, Focused) — decision (revision 1)

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
its CI proves the recommendation**. Nothing was built here and no Rust was compiled by
either engine or by this synthesis: the template does not exist yet. Every acceptance
criterion below is a requirement on P03, not an observed result. A decision that does not
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
`httpmock` 0.8.3 rather than `wiremock` 0.6.5 on two grounds, both re-verified at primary
sources by this synthesis and neither of them a licence, a download count or a
preference:

1. **`wiremock`'s API is async-only, and R05 (`sync-async-execution-model`) is still
   open.** `wiremock`'s own README comparison table records the split as `mockito:
   Async/Sync`, `httpmock: Async/Sync`, `wiremock: Async` (check C11). Selecting it today
   would decide by the back door that the template's test suite is async — a decision this
   item does not own.
2. **`wiremock`'s maintenance state is `at-risk` on concrete signals**, not on a
   release-age heuristic: `api.github.com` reports `archived: false` but a `pushed_at`
   date of **2025-08-24**, the day 0.6.5 was released (check C13), and the crate declares
   no `rust-version` at all (check C03), so the MSRV-aware resolver offers the template no
   protection against a patch release raising the effective floor silently.

*The condition under which `wiremock` wins instead*, stated so the owner can overturn this
on one fact rather than on a re-read: R05 resolves to async everywhere **and** a
re-verification finds commits on `LukeMathWalker/wiremock-rs` after 2025-08-24, or a
released 0.6.6+ that declares `rust-version`. Check C13 is written to FAIL the day the
second half of that becomes true. In that case the change is a drop-in swap of one
dev-dependency and the test scaffolding that constructs the server; nothing else in the
template changes.

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
commits the template to one contract suite "called from `tests/` once per adapter" and
names two adapters, one of which performs network I/O, so that suite needs an upstream to
answer it. py does exactly this and says so in the suite's own docstring — "the in-memory
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
`tokio-rs/tokio` carries `mockall` as a dev dependency and runs its test matrix on
`macos-latest`. `contentauth/c2pa-rs` — Adobe's Content Authenticity Initiative reference
SDK for the C2PA standard — carries **both** recommended members at **exactly** the
recommended versions in one manifest, `mockall = "0.15.0"` and `httpmock = "0.8.3"`, which
this synthesis re-read at source (check C14); it is the strongest compatibility evidence
available short of building the template, and no equivalent pairing of `mockall` with
`mockito` or with `wiremock` was found. `awslabs/aws-lambda-rust-runtime` carries
`httpmock`; `matrix-org/matrix-rust-sdk`, `XAMPPRocky/octocrab` and
`TrueLayer/reqwest-middleware` carry `wiremock`; `apache/iceberg-rust` carries `mockito`.

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

BASELINE-REVIEW: F120 — a driven-I/O adapter that performs real network I/O is exercised against a controlled upstream, not only substituted away at the port seam — narrow R01's sentence "the recommended seam needs no HTTP-mocking crate" to "no HTTP-mocking crate is needed **at the port seam**", and record that the F121 substitutability suite and the HTTP adapter's own boundary tests, both of which run against the real adapter, do need a loopback HTTP stub; affected items: R48 (this item, which selects the crate), R01 (the sentence's wording only — its owned parameter value, its recommendation and every crate it selected are unaffected), R32 (`test-harness-and-execution`, whose tiers must include one in which a loopback listener is bound) — evidence: R01's own F121 row commits the template to one contract function "called from `tests/` once per adapter" and names two adapters, one of them `src/core/adapters/http.rs`; R01's own unproven-claims table asks for "a template integration test that starts the real upstream (**or a bound test listener**)", which is precisely what an HTTP-stub crate provides; py at pin `b08bccfb` does exactly this, in `tests/core/test_projects_repository_contract.py` ("the in-memory fake and the real HTTP adapter (its network mocked with `responses`)"), in `tests/core/test_py_api_repository.py:104`, and in `pyproject.toml:101` ("`responses>=0.25`  # HEX-40 — HTTP mock for the port-contract suite") — the last two re-read at the pin by this synthesis, check C18.

**Fitness gates, answered per candidate before popularity was weighed.**

**Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate
in this item.** Licence compatibility is not evaluated, nothing is excluded on a licence,
and each crate's declared licence is recorded below as a fact only. Neither raw report
excluded any candidate on a licence, so nothing has to be re-evaluated on that account;
the codex report's phrase "No general-mocking candidate is excluded for an observed
incompatible license" is recorded as struck rather than as a passing gate.

| Candidate | 1 licence (recorded only) | 2 MSRV vs the 1.96 floor | 3 advisory / `unsafe` | 4 `ubuntu-latest, macos-latest` | 5 default features / async coupling | 6 binary size and compile cost |
|---|---|---|---|---|---|---|
| `mockall` 0.15.0 **(selected)** | `MIT OR Apache-2.0` | **passes** — declares `rust-version = "1.77.0"` (C01), enforced by a CI job pinned to that image; its six required dependencies are pure Rust and older-MSRV (C08) | **passes** — `rustsec.org/packages/mockall.html` HTTP 404, evidenced as "no advisory" by the `lock_api` control (C07). `unsafe`: the crate is safe Rust; `downcast` uses `unsafe` for type erasure and `fragile` for a thread-affinity check — **stated from manifests and documentation, not a line-by-line audit** | **passes by adopter evidence.** Its own CI is `ubuntu-latest` only; closed by `tokio-rs/tokio`, which carries `mockall` as a dev dependency and runs its matrix on `macos-latest`. **Version caveat: that adopter evidence is for 0.13.0, not 0.15.0** — the crate is pure Rust with no platform-conditional code, so the risk is low, but macOS support for 0.15.0 specifically is **inferred, not observed** | **passes** — the only feature is `nightly`, not default; no async runtime anywhere in the required dependency list (C08), so enabling `mock` does not drag `tokio` into a sync build. Composes with `async-trait` subject to `automock` preceding `#[async_trait]` | **passes** — zero bytes in the shipped binary (feature-and-dev-only). Compile cost is one extra proc-macro tree (`mockall_derive` → `syn`), paid only under `--features mock`, which is the reason for the gate. **No wall-clock figure: nothing was compiled** |
| `httpmock` 0.8.3 **(selected)** | `MIT` | **passes** — declares `rust-version = "1.88.0"` (C02), four minors of headroom below the 1.96 floor, enforced on master by `cargo hack check --rust-version --each-feature --no-dev-deps` | **passes** — `rustsec.org/packages/httpmock.html` HTTP 404 with the same control (C07). `unsafe`: **corrected here.** `unsafe_code = "forbid"` appears in the **master** manifest, which is already versioned 0.9.0; the released **v0.8.3 tag's manifest carries no such lint and declares `edition = "2021"`** (C06). For 0.8.3 the posture is "safe Rust over `hyper`/`tokio`", stated from manifests, not audited | **passes on its own CI** — `.github/workflows/platform.yml` runs the matrix `os: [ubuntu-latest, macos-latest, windows-latest]` (C09). It is the only candidate in the category whose own CI covers macOS, and `target-os-matrix` is owner-fixed, so this is the gate-4 discriminator | **passes with a change** — default feature set is exactly `["cookies"]` (C05), which this recommendation turns off with `default-features = false`; nothing here matches on cookies. `standalone`, `https`, `proxy`, `record`, `remote` stay off. `tokio` is a required dependency of the crate, but the **API** is sync-and-async, so the dev tree contains `tokio` while the template's test code need not be async | **passes** — zero bytes in the shipped binary. Heaviest dependency list of the four (26 required normal dependencies against `wiremock`'s 15 and `mockito`'s 16) because it bundles diffing and pretty-printing for readable mismatch output; paid only when the test suite compiles. **No wall-clock figure: nothing was compiled** |
| `mockito` 1.7.2 (**ranked runner-up**) | `MIT` | **passes** — declares 1.70 (C04); its master branch moves to 1.85, still inside the floor, so the headroom is narrowing | **passes** — HTTP 404 (C07) | **unverified for macOS test execution, not failed** — its own CI covers `ubuntu-latest` and `windows-latest` and no macOS; the best adopter evidence, `apache/iceberg-rust`, runs macOS in its `build` matrices but its `tests` job on `ubuntu-latest` only, so macOS *compilation* is evidenced and macOS *test execution* is not | **passes** — sync and async APIs; `tokio` required; one optional feature | **passes** — zero bytes shipped; 16 required dependencies, the lightest of the three full-featured options |
| `wiremock` 0.6.5 (**second runner-up; the crate the owner reference names**) | `MIT/Apache-2.0` | **passes on substance, fails on declaration** — it declares **no** `rust-version` at all (C03), so the MSRV-aware resolver offers no protection; its *effective* floor is at least 1.88, since its own issue #173 reports a let-chain compile error against 0.6.5 and let chains stabilized in Rust 1.88.0 | **passes** — HTTP 404 (C07) | **passes by adopter evidence** — its own CI has 0 macOS mentions across 5 `ubuntu-latest` jobs (C10); closed by `matrix-org/matrix-rust-sdk`, which runs its full suite against `wiremock = "0.6.5"` on `macos-latest` | **passes with a coupling to record** — `tokio` required; **API async-only** (C11), tested against both `tokio` and `async-std` | **passes** — zero bytes shipped; 15 required dependencies, the lightest of the three |

*Excluded by gate.* `faux` 0.1.13 — gate 1 `inapplicable`, and it is **not** excluded on a
licence; excluded on **gate 3** (its own documentation records liberal use of `unsafe`) and
on **fit** (it mocks a concrete struct, so it cannot produce a `ProjectsPort` implementor
for R01's seam). `double` 0.2.4 — excluded on **gates 2 and 6**: last release 2019-09-22,
no declared `rust-version`; maintenance `dormant` by the maintainer's own inactivity.
`stubr` 0.6.2 — excluded on **gates 2 and 6** (no declared `rust-version`, last release
2023-06-29) and because it is a layer *on top of* `wiremock`, inheriting every finding
against it. `rvcr` 0.2.1 — excluded on **gate 2** (no declared `rust-version`) and on
adoption; maintenance `at-risk`. `unimock` 0.6.8 and `mry` 0.14.0 fail no applicable gate
(`unimock` declares 1.70; `mry` declares none) and are excluded **on fit and ecosystem
weight**, not by a gate. `httptest` 0.16.4 fails no applicable gate and is kept on the
shortlist as the lightest full-featured option; not adopted, because 35 stars and 55
reverse dependencies make it an unsuitable default for a template other people copy.
`mockall_double` 0.3.1, `axum-test` and `tower-test` are **out of scope, not failed**:
the first swaps mocked *modules*, and the last two test *this* service's inbound router,
which is R69's and R32's subject, not an outbound upstream. A hand-rolled
`std::net::TcpListener` responder is excluded on **fit**, not by a gate: it would make the
template's tests a tutorial in HTTP framing rather than in hexagonal testing.

**Maintenance state by the rubric.** `mockall` **active** (not archived; pushed 2026-09-02;
0.15.0 released 2026-06-28; median 1.18 days to first maintainer response over the ten most
recently opened issues, 0 of 10 unanswered — opus, 2026-09-17). `httpmock` **active** (not
archived; pushed 2026-09-14; 0.8.3 released 2026-02-04) — with the honest cost that its
issue-queue responsiveness is the weakest of the four: median 10.53 days, 5 of 10 recent
issues unanswered (opus, 2026-09-17; the codex report did not compute this figure).
`mockito` **active** (median 0.46 days, 2 of 10 unanswered). `wiremock` **at-risk** on the
concrete signals recorded above, not on a release-age heuristic — and stated no harsher
than the evidence: the repository is not archived, 0.6.5 builds on docs.rs, it carries no
advisory, and a major adopter runs its suite against it on macOS today. It is `at-risk`,
not `dormant`. `httptest` **stable-quiet**; `faux`, `stubr`, `rvcr` **at-risk**; `double`
**dormant**.

**No performance claim is made.** No latency, throughput or resource figure is offered for
any candidate: the workload that would matter is this template's own test suite, which does
not exist, and inferring one from the crates' unlike published benchmarks is what the
prompt forbids. The only cost figures stated are dependency counts and feature sets, each
with its endpoint.

**The org CLI Design Standard v1.4.14** (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`
at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`) binds this port, and **no rule in it
bears on this item**: it contains no rule about test doubles, HTTP stubbing or
dev-dependency selection. Nothing from it is cited.

re-verify: 2027-03-17, or earlier on any of — R05 (`sync-async-execution-model`) publishes
a `DECISION.md`; the `pushed_at` date of `LukeMathWalker/wiremock-rs` leaves 2025-08-24, or
a `wiremock` 0.6.6+ release declares `rust-version` (checks C13 / C03 fail); the newest
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
`msrv-policy` is the binding gate-2 rule: at stable 1.98.1 the floor is 1.96, and the
highest declared `rust-version` across the selected members is `httpmock`'s 1.88.0, four
minors below it; `wiremock` is the one candidate that declares none at all, which is half
the ground for ranking it third. `target-os-matrix` is the gate-4 discriminator that
separates `httpmock` from `mockito`. `rust-edition` constrains nothing here — editions are
per-crate, so an `edition = "2024"` workspace consumes `mockall` 0.15.0 (`edition = "2021"`)
and `httpmock` 0.8.3 (`edition = "2021"`, check C06) without friction. `license` is
recorded but **not evaluated**: gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; Darwin arm64 (macOS 26.4);
`/usr/bin/grep` is `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`; `gh` authenticated on
this machine. **Nothing was compiled and nothing was implemented.** The template does not
exist, P03 builds it, and the role forbids building the thing being recommended. The check
below verifies the raws' claims at the endpoints the prompt names and at the crates' own
released sources.

**Working directory.** Any — the script resolves the repository root from its own path, so
it runs from a `git archive HEAD` extraction as well as from the worktree.

**Command.**

```
bash research/runs/R48/2026-09-17T020714Z-f9e4f950ea82/review/evidence/r48-claims-check.sh
```

**Result: 18 checks, 18 PASS, 0 FAIL, 0 SKIP; exit status 0.** Full output:
`review/evidence/r48-claims-check.log`.

| Check | What it asserts | Endpoint (all retrieved 2026-09-17) |
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
| C13 | `LukeMathWalker/wiremock-rs` is `archived: false` with a `pushed_at` date of **2025-08-24** — the maintenance ground for ranking `wiremock` third | `https://api.github.com/repos/LukeMathWalker/wiremock-rs` |
| C14 | `contentauth/c2pa-rs` carries `mockall = "0.15.0"` **and** `httpmock = "0.8.3"` in one manifest — the compatibility evidence | `https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml` |
| C15 | the owner reference document in this run's `inputs/` carries the C12 Testing row naming `wiremock` and the pin line `wiremock = "0.6"` — the row reconciled above | `inputs/owner-reference-axum-companion-stack-2026-09-16.md` |
| C16 | all **5** `- assumes` lines in this file are byte-identical to column 4 of the matching `docs/port/PARAMETERS.md` row — the publication guard | `docs/port/PARAMETERS.md` |
| C17 | the sha256 of `research/topics/01-ports-and-adapters-seam/DECISION.md` matches `inputs/prerequisites.json` `R01.decision` — the R01 read here is the revision this run pinned | repository files |
| C18 | py at pin `b08bccfb` pairs `responses>=0.25` with the comment "HTTP mock for the port-contract suite" and its contract-suite docstring names "the in-memory fake and the real HTTP adapter" — the evidence under `BASELINE-REVIEW: F120` | `git -C ~/c/py-launch-blueprint show b08bccfb:…` |

**Reproducibility, stated after re-running the script against the committed log rather than
before.** Every line beginning `# ` is volatile: the retrieval timestamp, the host banner,
the `rustc`/`cargo`/`grep` version lines. Every `PASS`/`FAIL`/`SKIP` line and the final
`RESULT:` line asserts on a stable field and reproduces byte-for-byte; the rule for
comparing across a rerun is

```
bash review/evidence/r48-claims-check.sh > /tmp/rerun.log
diff <(/usr/bin/grep -v '^# ' /tmp/rerun.log) <(/usr/bin/grep -v '^# ' review/evidence/r48-claims-check.log)
```

which was run and was empty. No download counter, star count, open-issue count or active
repository's `pushed_at` literal is printed anywhere, because those drift by the hour.

Two checks are designed to fail later, by intent, and their failure is a signal rather than
a defect. **C13** asserts the frozen date 2025-08-24: the day
`LukeMathWalker/wiremock-rs` is pushed again, C13 FAILs and half the ground for ranking
`wiremock` third has lapsed, which is exactly the recorded re-verify trigger. **C01/C02**
assert the current newest non-yanked versions: a FAIL there means the pin this decision
recommends is no longer the newest release. **C18** is the one check that reads outside
this repository: it prints `PASS` on a machine carrying the `py-launch-blueprint` clone at
pin `b08bccfb`, which is where the committed log was produced, and prints `SKIP` by name
where that clone is absent. The whole script was also re-run from a clean `git archive
HEAD` extraction into a temporary directory — a tree with no `.git`, carrying this commit's
`review/DECISION.md` and `review/evidence/r48-claims-check.sh` at their paths — and
produced `PASS` lines identical to the committed log and exit status 0; that run is
recorded in `review/evidence/r48-archive-rerun.log`, with its procedure in the log's own
header. No other check depends on anything outside this repository and the six endpoints
named above. The script sets `set -uo pipefail`, invokes `/usr/bin/grep` by absolute path,
names that binary beside every count it prints, checks each `curl` status separately rather
than trusting a pipeline, contains no personal email in its `User-Agent`, and passes
`shellcheck` with no findings.

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
fakes as the normal mechanism; both report that nothing was compiled. Five things they
settle differently, each settled here on evidence rather than on a vote.

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
3. **How `wiremock` leaves the shortlist.** Codex lists it under *Excluded by gate*,
   citing "macOS/MSRV" evidence; opus keeps it on the qualified shortlist at rank three on
   fit grounds. **Settled for opus, and codex's framing is recorded as overstated.**
   `wiremock` fails no applicable gate: gate 2 passes on substance (its effective floor is
   at least 1.88 even though it declares nothing, C03), and gate 4 passes by adopter
   evidence (`matrix-org/matrix-rust-sdk` runs its suite against 0.6.5 on `macos-latest`,
   despite the crate's own CI carrying no macOS lane, C10). It is ranked third on the two
   fit grounds re-verified here: async-only (C11) and `at-risk` maintenance (C13, C03).
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

**Evidence the two engines did not both collect.** Codex did not compute `httpmock`'s
issue responsiveness and said so, recording it as a re-verification task rather than
inferring a score; opus computed it (median 10.53 days, 5 of 10 unanswered, 2026-09-17) and
it is the honest cost recorded against the selected member. Opus computed responsiveness
for all four HTTP candidates and for `mockall` and `faux`; codex computed it for `mockall`
only. Where the two report the same figure from the same endpoint on different days
(2026-09-16 and 2026-09-17), the figures agree.

**Unproven, and left for P03 to prove in the real template.** Nothing was compiled by
either engine or by this synthesis, so every acceptance criterion above is proposed.

| Claim | Status | What would prove it |
|---|---|---|
| `MockProjectsPort: Send + Sync` and erasable to `Arc<dyn ProjectsPort>` | **Unproven.** Argued from `mockall`'s own source (its expectation storage is declared `Send + Sync`), not observed | One `--features mock` test that erases a `MockProjectsPort` to `Arc<dyn ProjectsPort>` and drives the CLI. The test compiling *is* the proof; R01 records `error[E0038]` as the failure mode |
| `mockall` 0.15.0 builds and tests on macOS | **Unproven.** Inferred from an adopter carrying **0.13.0** on a macOS matrix; the crate's own CI is `ubuntu-latest` only | The template's own `macos-latest` lane running `cargo test --features mock` |
| `httpmock` servers do not collide when tests run in parallel on both OSes | **Unproven** | `cargo test -- --test-threads=8` on `ubuntu-latest` and on `macos-latest` |
| The F121 contract suite passes for **both** adapters from one seed set, and a renamed `data` key fails the HTTP case while the in-memory case still passes | **Unproven.** This is the check that would falsify the recommendation | `cargo test --test port_contract`, then rename the stub's `data` key to `results` and re-run |
| The base suite resolves no mocking crate, and no test-only crate reaches the shipped artifact | **Unproven** | `cargo tree --edges dev -i mockall` with the feature off; `cargo tree --edges normal` for `httpmock`; `cargo build --release` with and without `--features mock` compared for size |
| Compile-time and binary-size cost of either member | **Unproven, and no figure is offered.** Measuring it honestly requires the template | A P03 measurement on the real workspace |
| The three members compile and pass together inside the real template | **Unproven.** The strongest available evidence short of that is `contentauth/c2pa-rs` resolving both crates at exactly these versions in one manifest (C14) | P03's first green CI run |

**Where the evidence is incomplete, stated plainly.** `mockito`'s macOS *test execution*
could be evidenced by neither engine at all, which is the whole of why it is second rather
than first; that is recorded as unverified, not as a failure. `unsafe` posture for every
candidate is stated from manifests and documentation, never from a line-by-line audit. No
performance figure of any kind is offered. And the choice against `wiremock` differs from
an owner-supplied document, so it is a recommendation with a stated ground and a stated
reversal condition, not a settled fact — the owner can overturn it on the R05 answer alone.
