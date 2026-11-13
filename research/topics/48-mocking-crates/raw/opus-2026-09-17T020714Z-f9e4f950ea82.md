# R48 mocking-crates — raw report (opus)

Engine identity `research-opus-2026-09-17T020714Z-f9e4f950ea82`, model `claude-opus-5`.
Item kind `bundle`. All registry, GitHub, RustSec, docs.rs and raw-manifest figures were
retrieved **2026-09-17 (UTC)** unless a different date is stated beside the figure. GitHub
figures come from `api.github.com` through the machine's authenticated `gh api` (5,000
requests/hour); registry figures from `https://crates.io/api/v1/...` with a `User-Agent`
header. Source-repo evidence is read through the programme pins —
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>` and
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>` — never from a working tree. No Rust
code was compiled in this run: the template does not exist and P03 builds it, so every
acceptance check below is **proposed, not executed**.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every
candidate in this report** (`docs/planning/p02/owner-decisions.md` section 7, recorded at
`docs/planning/p02/execution-ledger.md:495,505`). Licence compatibility is not evaluated for
any dependency or tool, nothing is excluded on a licence, and each crate's declared licence
is still reported below as a recorded fact rather than as a criterion.

### Landscape

**The category this item decides.** Two distinct capabilities, decided together because the
ledger binds them as one bundle (`docs/port/COMMONALITY.md:125-126`, F119 and F120, verdict
`DIVERGENT`, both owned by R48):

1. **F119 — the test-double mechanism**: how a test supplies a programmable stand-in for a
   collaborator the code under test depends on, and how it interrogates the calls made to it.
2. **F120 — the HTTP-transport stub mechanism**: how a test supplies canned upstream HTTP
   responses to the code that makes a real outbound HTTP request.

These are different problems in Rust and are answered by disjoint sets of crates, which is
why the bundle has separate members rather than one stack member.

**Three-bin map of the Rust field.**

| Bin | F119 — test doubles | F120 — HTTP upstream stub |
|---|---|---|
| **Built-in / first-party toolchain** | `trait` + a hand-written `impl` (a fake struct); closures behind `Box<dyn Fn>`; `std::sync::Mutex`/`RwLock` for recording state; the built-in `#[test]` harness; `std::net::TcpListener` bound to `127.0.0.1:0` plus a hand-rolled responder | `std::net::TcpListener` on port 0 with a hand-written accept-and-reply loop; `tower::util::ServiceFn` / `tower-test` 0.4.0 when the adapter is built on `tower` rather than a client crate |
| **Established industry standard** | `mockall` 0.15.0 (+ its companion `mockall_double` 0.3.1) | `wiremock` 0.6.5, `mockito` 1.7.2, `httpmock` 0.8.3 |
| **Up-and-comer / niche** | `faux` 0.1.13 (mocks a concrete struct, no trait needed), `unimock` 0.6.8 (one mock type for all traits), `mry` 0.14.0; `double` 0.2.4 is abandoned (last release 2019-09-22) | `httptest` 0.16.4 (small, well-regarded, low adoption), `stubr` 0.6.2 (WireMock-JSON stubs mounted into a `wiremock` server), `rvcr` 0.2.1 (VCR-style record/replay), `axum-test` 21.1.0 (tests *your* server, not an upstream — R69's subject, not this item's) |

Every shortlisted candidate below comes from this map. Registry figures for the whole map are
in the table under *Practice evidence*; the shortlist's gates are applied member by member.

**Authoritative sources used, and why each counts.**

- **The Rust Reference and the Rust standard library documentation** — the normative
  definition of trait implementation and dyn compatibility, which is what makes a hand-written
  fake a compiler-checked substitute rather than a convention
  (`https://doc.rust-lang.org/reference/items/traits.html`, `https://doc.rust-lang.org/std/`).
  Authoritative because they are the language's own specification-level documents.
- **The Rust release blog** — `https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/` (retrieved
  2026-09-17) for the stabilization of let chains in Rust 1.88.0, used below to date a
  candidate's effective, undeclared minimum compiler. Authoritative because it is the Rust
  project's own release announcement.
- **`rust-lang/rust` releases** (`https://api.github.com/repos/rust-lang/rust/releases`,
  retrieved 2026-09-17): newest stable is **1.98.1, published 2026-09-03**; the preceding
  minors are 1.97.x (2026-07-09) and 1.96.x. Under the owner-fixed `msrv-policy` ("stable
  minus 2 minor versions"), the floor this item must respect today is **1.96**. Authoritative
  because it is the toolchain's own release record rather than a third-party tracker.
- **Maintainers' own documentation and manifests, read at source** — `mockall`'s crate-level
  docs (`mockall/src/lib.rs`), `wiremock`'s, `mockito`'s and `httpmock`'s `README.md`,
  `httpmock`'s `Cargo.toml` and `src/api/spec.rs`, and each project's GitHub Actions
  workflows. Authoritative for API shape, declared MSRV, feature defaults and tested platforms
  because they are the artifacts CI actually runs.
- **`docs.rs` build status** (`https://docs.rs/crate/<name>/<version>/status.json`) —
  independent confirmation that a published version compiles on docs.rs's current toolchain.
- **The programme's own published prerequisite**, `research/topics/01-ports-and-adapters-seam/DECISION.md`
  (revision 3, 2026-09-13) and the registry value it wrote into `docs/port/PARAMETERS.md`.
  Authoritative for this item because it is the decided architecture this item must fit.
- **The owner-supplied reference architecture**,
  `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` (standing input,
  owner decision 11 of 2026-09-16). Its own caveat records that its patterns were "compiled in
  my head, not against the toolchain", and owner decision 11 rules it "an owner-supplied
  research input, not a binding standard and not a pre-decision". Treated here as a strong
  lead that must be reconciled, not as an authority that settles the question.

A single blog post was not used as an authority anywhere in this report.

**Practice evidence — well-regarded projects surveyed, with the evidence that they are well
regarded.** Adopters were found from each crate's crates.io reverse-dependency page
(`https://crates.io/api/v1/crates/<name>/reverse_dependencies`, retrieved 2026-09-17), then
confirmed in the project's own manifest at source.

| Project | Uses | Manifest evidence (retrieved 2026-09-17) | Why it is a relevant, well-regarded reference |
|---|---|---|---|
| `rust-lang/crates.io` | `mockall` `=0.15.0`, `async-trait` `=0.1.92` | `https://raw.githubusercontent.com/rust-lang/crates.io/main/Cargo.toml:137,74` | The Rust project's own registry service; a Cargo workspace with a web service, workers and library crates — the only surveyed project with this template's exact shape. Cited by R01 as its primary reference implementation. |
| `tokio-rs/tokio` | `mockall` `0.13.0` (dev) | `https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml:153` | The ecosystem's async runtime; its CI matrix includes `macos-latest` (`.github/workflows/ci.yml:67,102,144`). |
| `contentauth/c2pa-rs` | `mockall` `0.15.0` **and** `httpmock` `0.8.3` (both dev) | `https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml:266,280` | Adobe's Content Authenticity Initiative reference SDK for the C2PA standard; the only surveyed project pairing both recommended members at exactly the recommended versions. |
| `awslabs/aws-lambda-rust-runtime` | `httpmock` `0.8.1` (dev) | `https://raw.githubusercontent.com/awslabs/aws-lambda-rust-runtime/main/lambda-runtime/Cargo.toml:63` | AWS's official Rust Lambda runtime. |
| `matrix-org/matrix-rust-sdk` | `wiremock` `0.6.5` (workspace dev) | `https://raw.githubusercontent.com/matrix-org/matrix-rust-sdk/main/Cargo.toml:130` | The Matrix.org Foundation's official Rust SDK; its `test-all-crates` job runs the full suite on `macos-latest` with `nextest` (`.github/workflows/ci.yml:164-215`). |
| `XAMPPRocky/octocrab`, `TrueLayer/reqwest-middleware` | `wiremock` `0.6.0` (dev) | `.../octocrab/main/Cargo.toml:106`; `.../reqwest-middleware/main/reqwest-middleware/Cargo.toml:37` | The de-facto Rust GitHub client and the `reqwest` middleware family (retry, tracing, caching) that most `reqwest` users compose with. |
| `apache/iceberg-rust` | `mockito` `"1"` (workspace dev) | `.../iceberg-rust/main/Cargo.toml:120`, used in `crates/catalog/rest/Cargo.toml:51` | An Apache Software Foundation top-level project's Rust implementation. Its `build` and `build_with_no_default_features` matrices include `macos-latest`; its `tests` job is `ubuntu-latest` only (`.github/workflows/ci.yml:118-145,182-210`). |
| `obmarg/cynic`, `mgrachev/update-informer`, `datadog` `libdd-*`, `async-stripe`, `goose` | `mockito` / `httpmock` | reverse-dependency listings, retrieved 2026-09-17 | Breadth evidence that both crates are used by mainstream client libraries, not only by hobby projects. |

**Fit over abstract best.** The use case this template presents is narrow and specific: a
workspace that is simultaneously a CLI, a library and (per R69) an optional `axum` web
service; exactly one driven-I/O port (`ProjectsPort`, R01); two adapters behind it (an
in-memory fake and a real HTTP adapter); CI on `ubuntu-latest, macos-latest` only; an MSRV
floor of 1.96; and an execution model (`sync-async-execution-model`, R05) that is **still
open**. Candidates are judged against that, not against "best HTTP mocking library in
general". The R05 openness is decisive for member 3 and is treated as a first-class fit
criterion rather than an afterthought.

### Principles and implementation

**The conditional in this item's prompt fires. Say it first.** The prompt instructs this item
to "recommend the HTTP-transport-mocking crate **conditionally** on R01 choosing a
port/adapter split with a real outbound HTTP call to intercept". R01 has since resolved
(`research/topics/01-ports-and-adapters-seam/DECISION.md`, revision 3, 2026-09-13) to design E
— a dyn-compatible `pub trait ProjectsPort: Send + Sync` erased to `Arc<dyn ProjectsPort>` at
the composition root — with the production adapter living in `src/core/adapters/http.rs` and
"the HTTP client and runtime it wraps" left to other items (that decision, *Migration
implications*). That is a port/adapter split whose production adapter makes a real outbound
HTTP call. **The condition is met and an HTTP-stub crate is required.**

R01's own prose says the opposite in one place and this report disagrees with it on evidence,
narrowly. Its *Cross-repo adjudication* paragraph reads: "ts's D-019(5) … gives R48 the same
conclusion this decision gives: **the recommended seam needs no HTTP-mocking crate** because
the transport sits behind an injected port." That sentence is correct **at the port seam** and
incorrect **below it**, for two reasons drawn from the same decision and from py at the pin:

1. R01's F121 row commits the template to "one generic
   `pub fn assert_projects_port_contract<P: ProjectsPort>(label, make)` holding every
   behavioral assertion once, called from `tests/` **once per adapter**". The decision names
   two adapters — `InMemoryProjectsPort` and the `src/core/adapters/http.rs` production
   adapter. Running that one suite against the HTTP adapter requires an upstream to answer it.
   py does exactly this and says so in the suite's own docstring: "One set of behavioural
   assertions run against *both* adapters that satisfy `ProjectsRepository` — the in-memory
   fake and the real HTTP adapter (**its network mocked with `responses`**) — seeded from the
   *same* canonical data" (`py: tests/core/test_projects_repository_contract.py:1-13`, at pin
   `b08bccfb`).
2. R01's own unproven-claims table asks for "a template integration test that starts the real
   upstream (**or a bound test listener**), builds the client-facing service through
   `production_service(..)`, and exercises it" (that decision, `## Engines`). "A bound test
   listener" is precisely what an HTTP-stub crate provides; R01 contemplates the mechanism
   without naming the crate, which it explicitly leaves to this item.

Accordingly:

BASELINE-REVIEW: F120 — a driven-I/O adapter that performs real network I/O is exercised against a controlled upstream, not only substituted away at the port seam — narrow R01's sentence "the recommended seam needs no HTTP-mocking crate" to "**no HTTP-mocking crate is needed at the port seam**", and record that the F121 substitutability suite and the adapter's own boundary tests, both of which run against the real HTTP adapter, do need a loopback HTTP stub; affected items: R48 (this item, which selects the crate), R01 (the sentence's wording only — its owned parameter value, its recommendation and every crate it selected are unaffected), R32 (`test-harness-and-execution`, whose tiers must include a tier in which a loopback listener is bound) — evidence: py `tests/core/test_projects_repository_contract.py:1-13` and `tests/core/test_py_api_repository.py:104` at pin `b08bccfb` run the contract suite and the boundary tests against the real adapter with `responses`; `py: pyproject.toml:101` records the dependency's purpose verbatim as "`responses>=0.25`  # HEX-40 — HTTP mock for the port-contract suite"; R01's F121 row ("called from `tests/` once per adapter") and its `## Engines` table ("a bound test listener") are in `research/topics/01-ports-and-adapters-seam/DECISION.md`.

This is a `BASELINE-REVIEW:` and **not** a `CONFLICT:`: R01's owned parameter
`http-transport-injection-seam` is consumed here **verbatim and unchanged**, and nothing in
this report asks R01 to re-decide the seam.

**The shared requirement, its source, and its agreement level.**

- **Requirement (F119).** A test can replace a collaborator with a programmable stand-in and
  can afterwards assert *what the code under test asked of it*. Source: `docs/port/areas/testing-coverage.md:9`
  and `docs/port/DIVERGENCE-ANALYSIS.md:177`, cause class **B**, `harmonize: no`. Agreement
  level: **capability**. The mechanism is explicitly allowed to differ — the analysis row's own
  words are "same DI-and-spy pattern, only the framework-native tool differs".
- **Requirement (F120).** The code that performs real outbound HTTP is exercised against a
  controlled, hermetic upstream — no test ever reaches the public internet, and upstream
  schema drift fails a test rather than degrading silently. Source:
  `docs/port/areas/testing-coverage.md:10` and `docs/port/DIVERGENCE-ANALYSIS.md:178`, cause
  class **F** (genuine design disagreement), `harmonize: no`. Agreement level: **capability**
  (hermetic upstream control), explicitly *not* mechanism: the analysis row records that the
  mechanism follows from each repo's seam shape.

**Essential behaviors, taken from what the two source repos actually do at the pin.**

| # | Behavior | py at `b08bccfb` | ts at `cb1cbcb2` | Rust realization |
|---|---|---|---|---|
| B1 | Canned return values for a collaborator | `svc = Mock(); svc.list_projects.return_value = [...]` (`tests/cli/test_pylb.py:58-62`) | `vi.fn<Prompter>(() => Promise.resolve(selection))` (`tests/cli.test.ts:102`) | a hand-written struct implementing the trait, returning stored rows |
| B2 | Error injection at a collaborator | `mock_service.list_projects.side_effect = RuntimeError("kaboom")` (`tests/cli/test_pylb.py:556,570`) | a `Response`/`Error` pushed into the fake's reply queue (`tests/api.test.ts:21-37`) | a fake with a failure knob, or a `mockall` `returning(|_| Err(..))` |
| B3 | Interaction assertion — *what was asked* | `mock_service.list_projects.assert_called_with(workspace="WS", limit=5)` (`tests/cli/test_pylb.py:95`) | recorded `calls`/`urls` vectors interrogated after the act (`tests/api.test.ts:18-38`, `tests/cli.test.ts:44-50`) | a recording fake holding `Mutex<Vec<Call>>`, or `mockall`'s `.with(..).times(1)` |
| B4 | Hermetic upstream with per-route canned bodies | `@responses.activate` + `responses.get(f"{BASE}/projects", json={...})` (`tests/core/test_py_api_repository.py:104-110`) | not needed — the transport itself is the injected `fetchImpl` (`tests/api.test.ts:27`) | a loopback HTTP server bound on port 0, plus a base URL the adapter accepts |
| B5 | Request-derived response bodies for the contract suite | `_projects_cb(request)` reads `workspace`/`limit` from the query string and computes the body (`tests/core/test_projects_repository_contract.py:52-60`) | `makeApiFetch` routes on `url.pathname` (`tests/cli.test.ts:45-60`) | a dynamic responder closure on the stub server |
| B6 | Schema drift is loud | renamed `data` key raises `APIError` instead of reading as "no projects found" (`tests/core/test_py_api_repository.py:113-117`) | typed decode of the canned `Response` | the adapter's own boundary test against the stub server |

**Observable acceptance criteria** (requirements on the template; none was executed in this
run):

1. `grep -R "unittest.mock\|vi.fn"`-equivalent is vacuous in Rust, so the criterion is
   structural: the base `cargo test` run compiles and passes with **no mocking crate in the
   resolved dev-dependency graph for the default feature set**. *Observable:*
   `cargo tree --edges dev -i mockall` reports nothing when `--features mock` is absent.
2. B3 is expressible without a crate. *Observable:* a test asserts the exact arguments the CLI
   passed to the service, and it fails if the CLI changes the `limit` it sends.
3. B4/B5/B6 hold for the real adapter. *Observable:* the F121 contract function
   `assert_projects_port_contract` is invoked once with `InMemoryProjectsPort` and once with
   the HTTP adapter pointed at a loopback stub, and both invocations pass against the same
   seed data; a deliberate rename of the upstream `data` key makes the HTTP invocation fail
   while the in-memory invocation still passes.
4. No test binds a fixed port or reaches a non-loopback address. *Observable:* the stub
   server's URL is taken from the server object, and the suite passes with tests running in
   parallel on `ubuntu-latest` and `macos-latest`.
5. The `mock` feature does not rot. *Observable:* one CI lane runs
   `cargo test --features mock` and fails if the gated mocks stop compiling.

**Architectural alternatives compared, before any crate was weighed.**

*For F119 (test doubles):*

| Alternative | Shape | Verdict |
|---|---|---|
| **A. Hand-written fake implementing the port trait** | `pub struct InMemoryProjectsPort { rows: Mutex<Vec<Project>> }` plus, where B3 is needed, a `RecordingPort<P>` wrapper holding `Mutex<Vec<Call>>` | **Chosen as the default.** R01 already ships the fake as a public, unconditional library item (F013). Rust's built-in test harness ships **no** spy primitive, so "framework-native", which is what both source repos use, *means hand-written here*. Zero dependencies, no proc macro, and the recording wrapper is written once and reused. |
| **B. Derive-macro mocking crate (`mockall`)** | `#[cfg_attr(feature = "mock", automock)]` on the port trait; `MockProjectsPort` with `expect_list().with(eq(..)).times(1).returning(..)` | **Chosen as a gated escape hatch, not the default.** It expresses B3 in one line and B2 per-call, which a hand-written fake expresses more verbosely. It cannot serve F121 — R01's reason stands: a mock's behavior is programmed per test, so there is nothing to compare across adapters. |
| **C. Struct mocking without a trait (`faux`)** | `#[create]`/`#[methods]` on the concrete adapter struct | **Rejected.** It mocks a concrete type instead of implementing the port trait, which is the substitution mechanism R01 selected; it cannot produce a `ProjectsPort` implementor for F013/F121. Its own documentation records "liberal use of unsafe". |
| **D. Closure-injected collaborators (ts's `CliDeps`)** | `Box<dyn Fn(..) -> .. + Send + Sync>` fields | **Rejected as the seam.** R01 compared and rejected this (its alternative B) for the whole bundle; re-litigating it here is out of scope. Retained only as a legitimate shape for *leaf* collaborators with exactly one method (a clipboard writer, a spinner factory) where a trait buys nothing. |
| **E. One universal mock type (`unimock`) / `mry`** | one mock struct answering every trait | **Rejected on adoption and ecosystem weight** (figures below); nothing in this template needs the cross-trait unification they exist to provide. |

*For F120 (HTTP upstream stub):*

| Alternative | Shape | Verdict |
|---|---|---|
| **A. Loopback mock HTTP server + injectable base URL** | the stub binds `127.0.0.1:0`, the adapter is constructed with `server.base_url()` | **Chosen.** Highest fidelity: the real HTTP client builds real requests, real headers and real query strings, and real status codes come back — which is the whole reason the adapter exists. It is also the Rust ecosystem's established practice (every adopter in the table above does this). |
| **B. Transport injection inside the adapter (ts's `fetchImpl`, translated)** | the adapter holds an injected `tower::Service` or a client trait; tests pass a fake | **Rejected as the primary mechanism.** It leaves the adapter's actual request construction — header names, query encoding, status handling, body decoding — untested, which is the exact class of bug py's HEX-40/P04 work fixed (`tests/core/test_py_api_repository.py:1-8`). It also adds a second seam under the seam R01 just decided, with no F-row asking for one. Recorded as a *complement*, not a replacement: if a specific failure mode is unreachable through a real socket (a mid-body connection reset, a DNS failure), a narrow injected-transport test is the right tool for that one case. |
| **C. In-process HTTP interception, py's `responses` model** | patch the client's transport globally, no socket | **Not available in Rust and not worth building.** Python's `responses` works by monkey-patching `requests`' transport adapter at runtime; Rust has no runtime patching of a linked crate's internals. Every Rust candidate — `wiremock`, `mockito`, `httpmock`, `httptest` — binds a real loopback socket instead. This is the single largest justified ecosystem difference in this item, and it has a direct structural consequence: **the adapter's base URL must become a constructor parameter** (py gets away with a class constant, `PyApiProjectsRepository.BASE_URL`, precisely because `responses` intercepts below it). |
| **D. Record/replay cassettes (`rvcr`)** | record real traffic once, replay thereafter | **Rejected.** 262 downloads in 90 days and a last release of 2024-03-05 (figures below); cassette staleness is a maintenance liability in a template meant to be copied. `httpmock`'s own `record` feature offers the same idea inside the recommended crate if it is ever wanted. |
| **E. No HTTP-level test at all** | rely solely on the port-level fake | **Rejected.** It is the status quo ts lives with because ts has no real transport to test; here it would leave the only I/O-performing code in the template unexercised and would silently drop half of F121. |

**How the recommended design preserves each principle, and where Rust justifiably differs.**
The capability both source repos agree on — a programmable double plus a hermetic upstream —
is preserved in full. The *mechanisms* differ three ways, each justified rather than
accidental: (i) Rust's double is a nominal `impl` the compiler checks, where py uses a
structural `Protocol` and ts uses structural typing, so the template needs no mocking library
to obtain a *substitute* at all; (ii) Rust has no built-in spy, so a recording wrapper is
written once in the template rather than imported, which is why a crate is offered as a gated
escape hatch rather than as the default; (iii) Rust's hermetic upstream is a real loopback
socket rather than an in-process patch, which is strictly more faithful than py's mechanism
and costs one constructor parameter. Against ts: ts genuinely needs no HTTP stub, and that
remains defensible (D-019(5)) — but only because ts's transport *is* the injected seam. Rust
has a transport under the seam, so the ts conclusion does not transfer, and R01's sentence
carrying it over is the wording this report narrows above.

**Minimal realistic example.** One library crate; `ProjectsPort` with `list(query) ->
Result<Vec<Project>, PortError>` and `get(id) -> Result<Option<Project>, PortError>`;
`InMemoryProjectsPort` (shipped, R01 F013); `HttpProjectsPort::new(base_url, token)` holding
the HTTP client; `assert_projects_port_contract<P: ProjectsPort>(label, make)` (R01 F121)
under `tests/`. `tests/port_contract.rs` calls it twice: once with `InMemoryProjectsPort`
seeded from the canonical rows, once with `HttpProjectsPort::new(server.base_url(), "t")`
where `server` is an `httpmock::MockServer` whose single mock answers `GET /projects` with a
`respond_with` closure that reads `workspace` and `limit` from the query string and returns the
matching rows — the direct translation of py's `_projects_cb`.
`tests/http_adapter_boundary.rs` holds the drift tests: a renamed `data` key, a project with
no `name`, a 401 and a 500, each asserted to produce the right `PortError`.
`tests/cli_projects.rs` builds the CLI over a `RecordingPort` wrapping `InMemoryProjectsPort`
and asserts the exact `ProjectQuery` the CLI passed — py's `assert_called_with` parity, with no
crate.

### Recommendation

**One stack, three members.**

1. **Hand-written port fakes and a `RecordingPort` spy wrapper — no crate.** The default and
   the only mechanism the base `cargo test` run needs. Extends R01's shipped
   `InMemoryProjectsPort` with a generic recording wrapper for interaction assertions.
2. **`mockall` 0.15.0**, declared `optional = true` and reachable only through an
   off-by-default Cargo feature `mock = ["dep:mockall"]`, exercised by one dedicated CI lane.
   The escape hatch for interaction and ordering assertions a hand-written fake makes verbose.
   This follows `rust-lang/crates.io`'s `crates_io_github` pattern exactly and takes up the
   option R01 reserved for this item.
3. **`httpmock` 0.8.3** as a plain `[dev-dependencies]` entry with
   `default-features = false`, providing the loopback upstream for the F121 contract suite's
   HTTP-adapter invocation and for the adapter's own boundary tests. Conditional on R01
   choosing a port/adapter split with a real outbound call — **that condition is met**, so the
   member is in the stack rather than held in reserve.

**Reconciliation with the owner-supplied reference architecture.**
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md:72,117,197` names
**`wiremock = "0.6"`** for "Mock outbound HTTP". Owner decision 11 (2026-09-16) lists the
overlap set for that document and it contains **R32 (C12 testing)** but **not R48**; the
document was correspondingly not copied into this run's `inputs/` (which holds `CLAUDE.md`,
`EXECUTION.json`, `parameters.json`, `PARAMETERS.md`, `prerequisites.json`, `prompt.md`). It
is therefore a lead here, not a required input — but the C12 mock row is squarely this item's
subject matter, so it is reconciled in the R69 style rather than ignored. *Process note, for
the controller and not a finding against any item:* the C12 row's mocking half was handed to
R32, whose prompt does not own F119/F120; R48 is the item that owns them.

**Disposition: differs, with ground.** Member 3 selects `httpmock` 0.8.3 rather than
`wiremock` 0.6.5 on two grounds, both recorded with figures below: (a) `wiremock`'s API is
**async-only**, which would create a hidden coupling to R05 (`sync-async-execution-model`),
still open — the prompt's own MEDIUM question asks for exactly this flag; and (b) `wiremock`'s
maintenance state is **at-risk** on concrete signals (no commit on `main` since 2025-08-24;
a compiler-compatibility fix PR open since 2025-11-29; the "set MSRV in Cargo.toml" PR closed
unmerged, so the crate still declares no `rust-version`; 7 of its 10 most recently opened
issues unanswered). **The condition under which `wiremock` wins instead:** R05 resolves to
async everywhere *and* a re-verification finds commits on `main` after 2025-08-24 or a
released 0.6.6+. In that case it is a drop-in swap of one dev-dependency and roughly forty
lines of test scaffolding; nothing else in the template changes.

### Members

#### Hand-written port fakes and `RecordingPort` (language mechanism, no crate)

##### Landscape

Built-in / first-party bin. The mechanism is a plain `impl` of the port trait plus, for
interaction assertions, a generic wrapper struct holding `std::sync::Mutex<Vec<Call>>`. There
is no candidate to survey and no registry page: Rust's trait system, `std::sync::Mutex` and
the built-in `#[test]` harness all predate Rust 1.0. The relevant comparison is not against
other language features but against the crates in the *established standard* bin, done under
*Architecture alternatives* above.

##### Principles and implementation

This member carries B1, B2 and B3 for the base test suite, and is the mechanism R01 already
committed the template to for F013 (`pub struct InMemoryProjectsPort`, public and
unconditional, no `cfg(test)` and no feature gate). What this item adds is the *spy* half that
R01 did not need: a `pub struct RecordingPort<P: ProjectsPort> { inner: P, calls:
std::sync::Mutex<Vec<PortCall>> }` with `impl ProjectsPort for RecordingPort<P>` forwarding to
`inner` after pushing a `PortCall`, plus `pub fn calls(&self) -> Vec<PortCall>`. Roughly twenty
lines, written once, reused by every CLI-level and web-level test. It is `Send + Sync` for free
(a `Mutex<Vec<_>>` of plain data is both), which matters because R01's port carries
`Send + Sync` supertraits and the composition root erases to `Arc<dyn ProjectsPort>`.

Why this is the default rather than a crate: the observed demand is small and bounded. py's
entire F119 usage at the pin is **three call sites in one file** —
`svc = Mock()` with `return_value` (`tests/cli/test_pylb.py:55-65`), one `assert_called_with`
(`:95`), and two `side_effect` assignments (`:556,570`) — plus one further use in the contract
suite. ts's is `vi.fn`, a built-in of the runner it already has. Neither repo took a dedicated
mocking dependency. Rust's parallel choice, given libtest has no spy, is to write the twenty
lines rather than to add a proc-macro crate to the default build.

Production usage: R01's cited reference implementations ship exactly this shape —
`jj-vcs/jj`'s `lib/testutils/src/test_backend.rs` is a first-class fake shipped in a library
crate, and `lib/tests/test_commit_builder.rs:72-74` runs one test body against two backends
(figures and paths from `research/topics/01-ports-and-adapters-seam/DECISION.md`, whose opus
report read them at source on 2026-09-05; `jj-vcs/jj` had 31,409 stars at that date).

Integration cost: zero new manifest lines. Maturity and dependability: the language's own.
Representative performance: no measurable cost — a `Mutex` lock per port call on a path that
otherwise performs I/O.

Executable acceptance check (**proposed, not run**): `cargo test --no-default-features` passes
with no mocking crate resolved; a test asserting `calls()[0]` equals the expected
`ProjectQuery` fails when the CLI's `limit` default is changed.

##### Dominant choice

A hand-written `impl` of the port trait, plus a generic `RecordingPort<P>` wrapper for
interaction assertions. This is the framework-native answer in Rust, in the same sense that
`unittest.mock` is framework-native in Python and `vi.fn` is in Vitest.

##### Qualified shortlist

None — there is no second language mechanism competing for this role. `Box<dyn Fn>` closure
fields are retained for single-method leaf collaborators (clipboard writer, spinner factory,
prompter) where a trait and an `impl` would be pure ceremony; that is a style note inside this
member, not a rival member.

##### Excluded by gate

Not applicable: no crate, so no gate can exclude it. Gates 1 through 6 are all
`inapplicable` for the reasons given under *Parameters* below.

##### Up-and-comers

None applicable. The nearest thing to an up-and-comer in this space is
`rust-lang/impl-trait-utils`' `trait-variant` 0.1.3, which generates async trait variants and
has no `dyn` support shipped (recorded by R01, 2026-09-05) — watch, do not adopt; it changes
how an async port is *declared*, not how it is doubled.

##### Fit for this template

Exact. The template has one port with two methods; the fake already exists in R01's design;
the recording wrapper is generic over the port so it costs one file and survives adding a
second port. It adds nothing to the shipped binary, nothing to compile time, and nothing to
the dependency graph a downstream consumer of the library inherits.

##### Recommendation

Adopt as the default and only mechanism required by the base `cargo test` run. Ship
`RecordingPort<P>` in the library crate as a public item beside `InMemoryProjectsPort`, for the
same reason R01 made the fake public: integration tests under `tests/` link the library as an
external crate and cannot see `#[cfg(test)]` items.

##### Ranked runner-up

`mockall` 0.15.0 (member 2), which is not a runner-up in the usual sense — it is adopted
alongside, gated off by default.

##### Tradeoffs

Verbosity is the cost. A `mockall` expectation such as
`m.expect_list().with(eq(q)).times(1).returning(|_| Ok(vec![]))` is one line; the hand-written
equivalent is a wrapper plus an assertion on the recorded vector. The benefit is that the base
suite reads as ordinary Rust with no macro expansion to reason about, compiles with no
proc-macro in the graph, and cannot drift with a macro crate's releases. A second cost: a
hand-written fake can *lie* — it can drift from the real adapter's behavior. R01's F121
substitutability suite is the control for that, and it is exactly why member 3 is required.

##### Parameters

`assumes http-transport-injection-seam` — R01's value, verbatim, under `### Parameters` below.
No owned parameter. No `CONFLICT:`.

Gate 1: `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Gates 2 through 6:
`inapplicable — no crate exists to carry an MSRV, an advisory, a platform matrix, a feature
set or a build cost`. For the record: traits, `impl` blocks and `std::sync::Mutex` predate
Rust 1.0, the code is `unsafe`-free, and nothing here constrains the 1.96 floor or the
`ubuntu-latest, macos-latest` matrix.

##### Migration implications

`src/core/adapters/in_memory.rs` — already R01's (`InMemoryProjectsPort`); unchanged by this
item. `src/core/testing.rs` (new, this item) — `pub struct RecordingPort<P>`, `pub struct
PortCall`, `pub fn calls()`. `src/lib.rs` — re-export `RecordingPort` and `PortCall` (the
public-surface policy itself is R04's).

##### Validation strategy

**Proposed, not executed.** `cargo test` — the CLI tests build the service over
`RecordingPort::new(InMemoryProjectsPort::seeded(rows))` and assert the recorded
`ProjectQuery`. Expected behavior: the argument assertion fails when the CLI's default `limit`
changes, which is the B3 capability py gets from `assert_called_with`.
`cargo tree --edges dev` — expected to list no mocking crate for the default feature set.

##### Confidence & re-verify trigger

**High.** The mechanism is a language feature and the design it plugs into is already decided
and published. Re-verify if R01 is revised such that the port stops being a trait, or if the
template grows more than roughly four ports — at which point writing a recording wrapper per
port stops being cheaper than a derive macro and member 2 should become the default.

##### Sources

`research/topics/01-ports-and-adapters-seam/DECISION.md` (revision 3, 2026-09-13), rows F013
and F121 and *Migration implications*, read 2026-09-17.
`py: tests/cli/test_pylb.py:6,55-65,95,556,570` and
`py: tests/core/test_projects_repository_contract.py` at pin `b08bccfb`, read 2026-09-17.
`ts: tests/cli.test.ts:12,101-102,171,280-332` and `ts: tests/api.test.ts:18-38` at pin
`cb1cbcb2`, read 2026-09-17.
`https://doc.rust-lang.org/reference/items/traits.html` and
`https://doc.rust-lang.org/std/sync/struct.Mutex.html`, 2026-09-17.

#### `mockall` 0.15.0 (gated behind an off-by-default `mock` feature)

##### Landscape

Established-standard bin, and effectively uncontested there: it is the only trait-mocking
crate in Rust with eight-figure download volume. Its companion `mockall_double` 0.3.1
(2,236,241 downloads in 90 days; all-time 13,978,639) exists to swap a mocked module in and
out at compile time and is **not** recommended here — the template mocks a trait, not a module.
The up-and-comer bin holds `unimock` 0.6.8 (29,082 / 178,322; last release 2025-11-07;
13 reverse dependencies), `mry` 0.14.0 (11,012 / 104,339; 2025-05-28; 4 reverse dependencies)
and `faux` 0.1.13 (118,043 / 1,884,293; 2025-09-27; 8 reverse dependencies). `double` 0.2.4
(801 / 41,678; last release **2019-09-22**) is abandoned. All figures from
`https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`) and
`/reverse_dependencies`, retrieved 2026-09-17.

##### Principles and implementation

This member carries B2 and B3 where a hand-written fake is clumsy: per-call error injection,
call-count assertions, argument matchers and ordered-call sequences. `#[automock]` on the port
trait generates `MockProjectsPort` implementing that same trait, so it drops into R01's seam
unchanged — `Arc::new(MockProjectsPort::new()) as Arc<dyn ProjectsPort>` is the erasure R01
already uses.

**The feature gate is required, not stylistic.** A `#[cfg(test)]`-generated mock is invisible
to integration tests under `tests/`, which link the library crate as an external dependency —
the same constraint that made R01 declare `InMemoryProjectsPort` public and unconditional.
`rust-lang/crates.io` solves this exactly as recommended here:
`crates/crates_io_github/src/lib.rs:74-76` carries
`#[cfg_attr(feature = "mock", mockall::automock)] pub trait GitHubClient: Send + Sync`, and
`crates/crates_io_github/Cargo.toml` declares `[features] mock = ["dep:mockall"]` with
`mockall = { version = "=0.15.0", optional = true }` (paths and pins recorded by R01 from a
2026-09-05 source read; the root-manifest pin `mockall = "=0.15.0"` re-verified today at
`https://raw.githubusercontent.com/rust-lang/crates.io/main/Cargo.toml:137`).

**How the feature reaches `cargo test`.** Two mechanisms exist and the choice matters:
(a) a self-dev-dependency, `[dev-dependencies] rs-launch-blueprint = { path = ".", features =
["mock"] }`, which makes the gated mocks visible to `tests/` on every plain `cargo test` — at
the cost of building the library twice, once with and once without the feature; or (b) a
dedicated CI lane running `cargo test --features mock`. **Recommend (b).** The whole point of
gating is to keep the default build free of the proc-macro tree, and (a) gives that back on
every developer's every test run. The lane itself is R32's and R11's to place; this item's
requirement is only that **some** lane builds `--features mock`, so the gated code cannot rot
unnoticed.

**Async compatibility, for the R05 async branch.** `mockall` documents support for
`async_trait` with two stated limitations: "The `#[automock]` attribute must appear _before_
the crate's attribute", and "The `#[async_trait]` and `#[trait_variant::make]` macros must be
imported with their canonical names" (`mockall/src/lib.rs:1068-1100`, read at
`https://raw.githubusercontent.com/asomers/mockall/master/mockall/src/lib.rs`, 2026-09-17).
That composes with R01's conditional `async-trait` 0.1.92 member with no further change.

**`Send + Sync`.** R01's port carries `Send + Sync` supertraits and the root erases to
`Arc<dyn ProjectsPort>`, so `MockProjectsPort` must satisfy both. `mockall`'s expectation
storage is declared `pub trait AnyExpectations : Any + Send + Sync {}`
(`mockall/src/lib.rs:1445`), and the `fragile` 2.0 dependency exists as the escape for
non-`Send` return values — which this port does not need, since `Project` is plain
`serde`-derived data. **This is the one claim in this member I could not execute**: proving
`MockProjectsPort: Send + Sync` requires compiling, and no Rust code was built in this run. It
is listed as a P03 check under *Validation strategy*.

Production usage: `rust-lang/crates.io` (`=0.15.0`), `tokio-rs/tokio` (`0.13.0`, dev),
`contentauth/c2pa-rs` (`0.15.0`, dev), `solana-runtime`, the `google-cloud-*` SDK family and
`passkey-authenticator` (reverse-dependency listing, 2026-09-17). Maturity: first published
2017, 1,312 reverse dependencies. Integration cost: two manifest lines plus one
`#[cfg_attr]` per mocked trait.

##### Dominant choice

`mockall` 0.15.0. Nothing else in the trait-mocking category is within two orders of magnitude
on adoption: 27,536,920 downloads in 90 days against `unimock`'s 29,082 and `mry`'s 11,012.

##### Qualified shortlist

- **`mockall` 0.15.0** — recommended, gated.
- **`unimock` 0.6.8** — passes every applicable gate (declared `rust-version` 1.70; RustSec
  404; last release 2025-11-07). A genuinely interesting design — one mock type for all
  traits — but 13 reverse dependencies and 29,082 downloads in 90 days make it an unsuitable
  default for a template other people copy. Not adopted.
- **`mry` 0.14.0** — passes gates 1 and 3; declares **no** `rust-version` (gate 2 undeclared);
  4 reverse dependencies. Not adopted.

##### Excluded by gate

- **`faux` 0.1.13.** Gate 1 `inapplicable` (owner ruling Q7.B); this crate is **not** excluded
  on its licence. Excluded on **gate 3 (`unsafe` posture)** and on **fit**: its own
  documentation records liberal use of `unsafe` (recorded in R01's gate table from its docs,
  2026-09-05), and it mocks a concrete struct rather than implementing a trait, so it cannot
  produce a `ProjectsPort` implementor for R01's seam — no `impl` item, so no compiler-checked
  substitution. Maintenance `at-risk`: last release 2025-09-27, repository last pushed
  2025-09-27 (`https://api.github.com/repos/nrxus/faux`, 2026-09-17); its issue responsiveness
  is in fact good (median 1.54 days to first maintainer response, 0 of 10 unanswered), so the
  `at-risk` verdict rests on the release/push gap plus the `unsafe` posture, not on
  neglect of users.
- **`double` 0.2.4.** Excluded on **gates 2 and 6**: last release 2019-09-22, no declared
  `rust-version`, predates edition 2018 conventions entirely. Maintenance `dormant` by the
  maintainer's own inactivity.
- **`mockall_double` 0.3.1.** Not excluded by a gate — excluded on **scope**. It swaps mocked
  *modules*, which this template does not do.

##### Up-and-comers

`unimock` 0.6.8 and `mry` 0.14.0, described above. Watch `unimock`: its single-mock-type design
removes the per-trait `MockX` proliferation that makes `mockall` verbose in a workspace with
many ports. Re-evaluate if its reverse-dependency count passes roughly 100.

##### Fit for this template

Good, with the gate. The template has one port today, so `mockall`'s per-trait generation costs
one `#[cfg_attr]`. It is dev-and-feature-only, so it adds **zero** bytes to the shipped binary
and nothing to the graph a library consumer inherits. Its normal dependencies are six and
contain no async runtime — `cfg-if 1.0`, `downcast 0.11`, `fragile 2.0`, `mockall_derive
=0.15.0`, `predicates 3.0` (`default-features = false`), `predicates-tree 1.0`
(`https://crates.io/api/v1/crates/mockall/0.15.0/dependencies`, 2026-09-17) — so enabling the
`mock` feature does not drag `tokio` into a sync build. The one real cost is a second `syn`
proc-macro tree in the feature-enabled build, which is why the feature is off by default.

##### Recommendation

Adopt as `mockall = { version = "0.15.0", optional = true }` with `[features] mock =
["dep:mockall"]`, applied as `#[cfg_attr(feature = "mock", mockall::automock)]` on
`ProjectsPort` and on any further port the template grows. Do **not** use it in the F121
substitutability suite — R01's reason is correct and is restated here: a mock's behavior is
programmed per test, so running the same assertions against it compares nothing. Require one
CI lane to build `--features mock`.

##### Ranked runner-up

Hand-written fakes and `RecordingPort` (member 1), which is also the default. If the owner
prefers a zero-crate answer for F119, dropping this member costs the template only terseness:
every capability py exercises (B1, B2, B3) remains expressible. State that explicitly rather
than implying `mockall` is required.

##### Tradeoffs

Compile time is the cost, and it is the reason for the gate: `mockall_derive` brings a `syn`
2.x tree that the default build does not otherwise need for tests, and macro-generated
expectation code is a known contributor to test-build times. The 2025 State of Rust survey
(7,156 responses; cited by R01, 2026-09-05) records compile time as a persistent top
productivity limiter, which is the general reason this template prefers a zero-dependency
default. The second cost is error-message quality: a violated expectation panics at run time
with a generated message, where a hand-written fake's assertion failure points at the
assertion the author wrote. The benefit is expressive power — ordered call sequences and
argument matchers are the two things a recording wrapper genuinely cannot match without
becoming a mocking library itself.

##### Parameters

`assumes http-transport-injection-seam` — R01's value verbatim (see `### Parameters`). No
owned parameter. No `CONFLICT:`.

- **Gate 1 — licence:** `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Declared licence,
  recorded as fact only: `MIT OR Apache-2.0`
  (`https://raw.githubusercontent.com/asomers/mockall/master/mockall/Cargo.toml`, 2026-09-17).
- **Gate 2 — MSRV:** **passes.** `rust-version = "1.77.0"`, `edition = "2021"` (same file);
  the floor today is 1.96 (stable 1.98.1, 2026-09-03), leaving 19 minors of headroom. The
  project keeps a `Cargo.lock.msrv` at the repository root and a CI job pinned to
  `image: rust:1.77.0` (`.github/workflows/ci.yml:53-56`), so the declared MSRV is enforced
  rather than aspirational. Dependency tree: `predicates` 3.x and `downcast`/`fragile` are
  pure-Rust and older-MSRV; none is newer than the floor.
- **Gate 3 — advisories and `unsafe`:** **passes.** `https://rustsec.org/packages/mockall.html`
  returns HTTP 404 (2026-09-17), which RustSec uses to mean no advisory. `unsafe` posture:
  `mockall` itself is safe Rust; its `downcast` 0.11 dependency uses `unsafe` for type erasure
  and `fragile` 2.0 uses `unsafe` for its thread-affinity check. **Stated from documentation
  and manifests, not from a line-by-line audit.** Nothing in this member is linked into the
  shipped binary.
- **Gate 4 — `ubuntu-latest, macos-latest`:** **passes, by adopter evidence.** The crate's own
  CI is `ubuntu-latest` only (`.github/workflows/ci.yml:15,53`) — so *its* matrix does not
  cover macOS. Closed instead by `tokio-rs/tokio`, which carries `mockall = "0.13.0"` as a dev
  dependency (`tokio/Cargo.toml:153`) and runs its test matrix on `macos-latest`
  (`.github/workflows/ci.yml:67,102,144`). **Version caveat:** that evidence is for 0.13.0, not
  0.15.0; the crate is pure Rust with no platform-conditional code and a `build.rs` that only
  probes for the nightly compiler, so the risk is low but the macOS evidence for 0.15.0
  specifically is **inferred, not observed**. Windows: not covered by the crate's CI either;
  not required.
- **Gate 5 — default features and async coupling:** **passes.** The only feature is `nightly`
  (better error messages and auto-defaulted returns), which is **not** default. No async
  runtime anywhere in the normal dependency list. Compatible with `async-trait` subject to the
  macro-ordering rule quoted above.
- **Gate 6 — binary size and compile cost (qualitative):** **passes.** Binary size: **zero
  impact** — dev-and-feature-only, never linked into `target/release/rslbp`. Compile cost:
  one additional proc-macro tree (`mockall_derive` → `syn` 2.x → `quote`, `proc-macro2`) plus
  five small runtime crates, paid only in builds that pass `--features mock`. No figure is
  offered: measuring it honestly requires the template, which does not exist, and this run
  compiled nothing.

##### Migration implications

`Cargo.toml` — add `mockall = { version = "0.15.0", optional = true }` under
`[dependencies]` (not `[dev-dependencies]`: an optional dependency behind a feature must be a
normal dependency for `dep:mockall` to name it) and `[features] mock = ["dep:mockall"]`.
`src/core/ports.rs` — add `#[cfg_attr(feature = "mock", mockall::automock)]` above
`pub trait ProjectsPort`, and under an async R05 place it **before** `#[async_trait]`.
`tests/` — a test module that uses `MockProjectsPort` must itself be
`#![cfg(feature = "mock")]`. CI — one lane running `cargo test --features mock` (lane placement
is R32's and R11's).

##### Validation strategy

**All proposed, none executed in this run.**
`cargo test --features mock` — expected: a test constructing
`MockProjectsPort`, setting `expect_list().with(eq(query)).times(1).returning(|_| Ok(rows))`,
erasing it to `Arc<dyn ProjectsPort>` and driving the CLI, passes; and fails if the CLI sends a
different `ProjectQuery`. This single test is also the **compile-level proof that
`MockProjectsPort: Send + Sync`**, because the erasure to `Arc<dyn ProjectsPort>` will not
compile otherwise (R01 records `error[E0038]` as the failure mode for a non-dyn-compatible
port and `error[E0046]` for a missing method).
`cargo build` and `cargo tree --edges normal` with the feature off — expected: `mockall` absent
from the graph.
`cargo test` with the feature off — expected: the whole base suite still passes, proving the
gated code is genuinely optional.

##### Confidence & re-verify trigger

**Medium-high.** The crate's registry, MSRV, advisory and feature facts are directly verified;
its macOS support and its `Send + Sync` behavior under R01's erasure are inferred rather than
observed, which is why both are named as P03 checks. Re-verify if: a 0.16 release changes the
`automock`/`async_trait` ordering rule or raises `rust-version` above the floor;
`asomers/mockall` goes six months without a push from 2026-09-02; R01 is revised so the port is
no longer a trait; or the template's port count passes roughly four, at which point this member
should be promoted from escape hatch to default.

##### Sources

`https://crates.io/api/v1/crates/mockall` and `/mockall/0.15.0/dependencies` and
`/mockall/reverse_dependencies` — 90-day downloads 27,536,920, all-time 168,074,531, newest
non-yanked 0.15.0 created 2026-06-28, 1,312 reverse dependencies (2026-09-17).
`https://api.github.com/repos/asomers/mockall` — 1,843 stars, `archived: false`,
`pushed_at: 2026-09-02T22:10:08Z` (2026-09-17).
`https://api.github.com/search/issues?q=repo:asomers/mockall+is:issue+is:open` —
`total_count: 51` (2026-09-17).
Issue responsiveness, computed 2026-09-17 from the 10 most recently opened issues
(`repos/asomers/mockall/issues?state=all&sort=created&direction=desc`, then each issue's
comments, first comment whose `author_association` is `OWNER`/`MEMBER`/`COLLABORATOR` and whose
author differs from the reporter): **median 1.18 days, 0 of 10 unanswered**, window
2025-10-02 → 2026-08-20; per-issue days
689:7.70, 681:0.32, 680:4.98, 679:5.95, 678:0.08, 675:1.87, 674:0.89, 671:1.48, 669:0.26,
667:0.02. **Maintenance: `active`.**
`https://rustsec.org/packages/mockall.html` — HTTP 404, no advisory (2026-09-17).
`https://docs.rs/crate/mockall/0.15.0/status.json` — `{"doc_status":true}` (2026-09-17).
`https://raw.githubusercontent.com/asomers/mockall/master/mockall/Cargo.toml`,
`.../mockall/src/lib.rs:1068-1100,1445`, `.../.github/workflows/ci.yml` (2026-09-17).
`https://raw.githubusercontent.com/rust-lang/crates.io/main/Cargo.toml:137`,
`https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml:153`,
`https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml:266` (2026-09-17).
`research/topics/01-ports-and-adapters-seam/DECISION.md` (the `crates_io_github` pattern, the
F121 exclusion, the 2026-09-05 figures), read 2026-09-17.

#### `httpmock` 0.8.3 (loopback upstream for adapter and contract tests)

##### Landscape

Established-standard bin, which holds exactly three crates — `wiremock` 0.6.5, `mockito` 1.7.2
and `httpmock` 0.8.3 — all three implementing the same architecture: a real HTTP server bound
to an ephemeral loopback port, configured per test. The up-and-comer/niche bin holds
`httptest` 0.16.4 (small and well-run but 35 stars and 55 reverse dependencies),
`stubr` 0.6.2 (mounts WireMock JSON stubs into a `wiremock` server; last release 2023-06-29)
and `rvcr` 0.2.1 (VCR-style record/replay; 262 downloads in 90 days; last release 2024-03-05).
The built-in bin holds a hand-rolled `std::net::TcpListener` responder — viable and
dependency-free, rejected because it re-implements request matching, parallel-safe port
allocation and assertion reporting that three maintained crates already provide, in a template
whose readers are meant to copy patterns rather than plumbing.

Registry figures, all from `https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`), `/versions` (newest non-yanked `num`, `created_at`) and
`/reverse_dependencies` (`meta.total`), retrieved **2026-09-17**:

| Crate | 90-day downloads | All-time downloads | Newest non-yanked | Declared `rust-version` | Licence (recorded, not evaluated) | Reverse deps |
|---|---:|---:|---|---|---|---:|
| `wiremock` | 20,169,001 | 77,783,427 | 0.6.5 (2025-08-24) | **none** | `MIT/Apache-2.0` | 2,916 |
| `mockito` | 8,806,141 | 56,102,130 | 1.7.2 (2026-02-02) | 1.70 | `MIT` | 1,322 |
| `httpmock` | 5,522,473 | 29,547,448 | 0.8.3 (2026-02-04) | 1.88.0 | `MIT` | 585 |
| `httptest` | 1,089,926 | 11,180,035 | 0.16.4 (2026-01-06) | **none** | `MIT OR Apache-2.0` | 55 |
| `stubr` | 9,091 | 88,136 | 0.6.2 (2023-06-29) | **none** | `Apache-2.0` | — |
| `rvcr` | 262 | 23,704 | 0.2.1 (2024-03-05) | **none** | `Apache-2.0` | — |

GitHub figures, from `https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`, never
`open_issues_count`), retrieved **2026-09-17**:

| Repository | Stars | `archived` | `pushed_at` | Open issues |
|---|---:|---|---|---:|
| `LukeMathWalker/wiremock-rs` | 799 | false | **2025-08-24** | 24 |
| `lipanski/mockito` | 781 | false | 2026-08-01 | 7 |
| `httpmock/httpmock` | 667 | false | **2026-09-14** | 17 |
| `ggriffiniii/httptest` | 35 | false | 2026-01-06 | 1 |

Issue responsiveness, computed **2026-09-17** by the same method as member 2 (10 most recently
opened issues; first comment by `OWNER`/`MEMBER`/`COLLABORATOR` other than the reporter):

| Crate | Median days to first maintainer response | Unanswered | Window of the 10 issues | Maintenance verdict |
|---|---:|---:|---|---|
| `wiremock` | 0.42 (over the 3 answered) | **7 of 10** | 2024-10-26 → **2025-08-27** | **at-risk** |
| `mockito` | 0.46 | 2 of 10 | 2024-09-07 → 2026-03-10 | **active** |
| `httpmock` | **10.53** | 5 of 10 | 2025-12-04 → 2026-08-21 | **active** |
| `httptest` | 0.03 | 1 of 10 | 2021-09-09 → 2026-01-06 | stable-quiet |

##### Principles and implementation

This member carries B4, B5 and B6 — the hermetic upstream, the request-derived response body
the F121 suite needs, and the drift tests that make schema breakage loud. The architecture is
alternative A above: the stub binds `127.0.0.1:0`, the test builds
`HttpProjectsPort::new(server.base_url(), token)`, and the adapter's real HTTP client performs
a real request.

**The mechanism differs from py's by construction and that difference is justified, not
drift.** `responses` patches `requests`' transport in-process, so py's adapter can keep
`BASE_URL` as a class constant. Rust has no equivalent, so the base URL becomes a constructor
parameter — and the template gains something in exchange: the request that reaches the stub is
the one the real client actually built, headers and query encoding included, which is the layer
py's approach cannot observe.

**Why `httpmock`, concretely.** Three fit facts decide it against two strong rivals:

1. **It does not couple this item to R05.** `R05 (sync-async-execution-model)` is open. The
   prompt's MEDIUM question asks whether the candidates support sync and async equally and
   whether that creates a hidden coupling. They do not: `wiremock`'s entire API is `async`
   (`MockServer::start().await`, `.mount(&server).await` —
   `https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/README.md`, 2026-09-17),
   and its own comparison table in that README records the split as
   `mockito: Async/Sync`, `httpmock: Async/Sync`, `wiremock: Async`. `httpmock` exposes both:
   `MockServer::start()`/`start_async()`, `Mock::assert()`/`assert_async()`,
   `assert_calls(n)`/`assert_calls_async(n)`, `hits()`
   (`https://raw.githubusercontent.com/httpmock/httpmock/master/src/api/mock.rs:114,154,193,231,275,318,382`,
   2026-09-17). Choosing `wiremock` today would decide, by the back door, that the template's
   test suite is async — a decision this item does not own.
2. **It is the only candidate whose own CI tests `macos-latest`.** `httpmock`'s
   `.github/workflows/platform.yml` is a weekly cross-platform lane with
   `os: [ubuntu-latest, macos-latest, windows-latest]` and a `rust` axis
   (`https://raw.githubusercontent.com/httpmock/httpmock/master/.github/workflows/platform.yml:20-38`,
   2026-09-17). `target-os-matrix` is owner-fixed at `ubuntu-latest, macos-latest`, so this is
   the gate-4 discriminator, not a nicety.
3. **It has the API shapes the F121 suite needs.** Extensible request matching:
   `When::is_true(impl Fn(&HttpMockRequest) -> bool + Send + Sync + 'static)` and `is_false`
   (`src/api/spec.rs:4360,4400`), which supersede the deprecated `matches` (`:4320`). Dynamic
   response bodies: `Then::respond_with<F: Fn(&HttpMockRequest) -> HttpMockResponse + Send +
   Sync + 'static>` (`src/api/spec.rs:5041-5049`). Both are present in the **released 0.8.3**,
   confirmed on `https://docs.rs/httpmock/0.8.3/httpmock/struct.Then.html` (lists
   `method.respond_with`) and `.../struct.When.html` (lists `method.is_true`,
   `method.is_false`), retrieved 2026-09-17. `respond_with` is the direct translation of py's
   `_projects_cb`, which computes the body from the `workspace` and `limit` query parameters.
   Spying: `Mock::assert()`, `assert_calls(n)`, `hits()`.

Production usage: `awslabs/aws-lambda-rust-runtime` (`httpmock = "0.8.1"`,
`lambda-runtime/Cargo.toml:63`), `contentauth/c2pa-rs` (`httpmock = "0.8.3"`,
`sdk/Cargo.toml:280`), DataDog's `libdd-trace-utils`/`libdd-telemetry`/`libdd-data-pipeline`,
`async-stripe`, `goose` and `axiom-rs` (reverse-dependency listing, 2026-09-17).

Representative performance: each test binds its own ephemeral port and the crate's servers are
pooled (`async-object-pool` 0.2 in its dependency list), so tests run in parallel; the request
path is `hyper` 1.x over loopback. **No latency or throughput figure is offered**: the workload
that would matter is this template's own test suite, which does not exist, and inferring one
from the crates' unlike published benchmarks is exactly what the prompt forbids.

Integration cost: one `[dev-dependencies]` line and a base-URL parameter on the adapter's
constructor.

##### Dominant choice

There is **no** dominant choice in this category, and saying otherwise would misreport the
evidence. `wiremock` leads on adoption (20,169,001 downloads in 90 days; 2,916 reverse
dependencies) but its repository has not been pushed since **2025-08-24** — 12.8 months before
retrieval — while `mockito` leads on maintainer responsiveness and `httpmock` on platform
coverage and release cadence. The category is a genuine three-way split and this report picks
on fit, per the prompt's instruction to apply the gates before weighing popularity.

##### Qualified shortlist

- **`httpmock` 0.8.3** — recommended. Passes every applicable gate on its own published
  evidence.
- **`mockito` 1.7.2** — ranked runner-up; fails no gate, leaves gate 4 partly unverified.
- **`wiremock` 0.6.5** — second runner-up; fails no gate outright, but is `at-risk` on
  maintenance and async-only. This is the crate the owner-reference document names.
- **`httptest` 0.16.4** — passes gates 3 and 5 and is well run (median 0.03 days to first
  maintainer response). Not adopted: 35 stars, 55 reverse dependencies and no declared
  `rust-version` make it an unsuitable default for a template. Kept on the shortlist because
  it is the lightest full-featured option if dependency count ever becomes the binding
  constraint.

##### Excluded by gate

- **`stubr` 0.6.2.** Gate 1 `inapplicable` (Q7.B). Excluded on **gates 2 and 6**: no declared
  `rust-version`, last release 2023-06-29, and it is a *layer on top of* `wiremock`, so it
  inherits every `wiremock` finding below and adds a JSON stub format the template does not
  need. Maintenance `at-risk` on the release gap.
- **`rvcr` 0.2.1.** Gate 1 `inapplicable` (Q7.B). Excluded on **gate 2** (no declared
  `rust-version`) and on **adoption**: 262 downloads in 90 days, last release 2024-03-05.
  Maintenance `at-risk`. Its record/replay idea is available inside the recommended crate via
  `httpmock`'s `record` feature, which is not enabled here.
- **A hand-rolled `std::net::TcpListener` responder.** Not excluded by a gate — excluded on
  **fit**. It would make the template's tests a tutorial in HTTP framing rather than in
  hexagonal testing.
- **`axum-test` 21.1.0 / `tower-test` 0.4.0.** Out of scope, not failed: they test *this*
  service's inbound router, which is R69's and R32's subject (R69 settled `tower::ServiceExt::
  oneshot` as the in-process handler idiom and recorded `axum-test` as the alternative). They
  do not stub an outbound upstream.

##### Up-and-comers

`httptest` 0.16.4 is the one to watch: it is the smallest of the four server-based options and
its maintainer answers issues within hours, but its adoption is an order of magnitude below the
others. `httpmock`'s own master branch is already versioned **0.9.0** with `edition = "2024"`,
`rust-version = "1.88.0"` and `unsafe_code = "forbid"`
(`https://raw.githubusercontent.com/httpmock/httpmock/master/Cargo.toml:1-20`, 2026-09-17), so
the next release is an edition-2024 crate — aligned with this template's fixed `rust-edition`.

##### Fit for this template

Strong, with one honest cost. Fit: sync **and** async, so it survives either R05 branch
unchanged; `macos-latest` in its own CI; a dynamic responder that matches py's contract-suite
shape exactly; a declared, CI-enforced MSRV; `unsafe_code = "forbid"` declared in the manifest;
and adopters (AWS, Adobe, DataDog) that are exactly the "mainstream, well-regarded, newer"
weighting the survey method asks for. Cost: it has the **heaviest dependency list** of the
four — 26 required normal dependencies against `wiremock`'s 15 and `mockito`'s 16
(`https://crates.io/api/v1/crates/<name>/<version>/dependencies`, 2026-09-17) — because it
bundles diffing and pretty-printing (`similar`, `stringmetrics`, `tabwriter`,
`assert-json-diff`) to produce readable mismatch output. That cost is paid only in dev builds
and only when the test suite compiles.

##### Recommendation

Adopt `httpmock = { version = "0.8.3", default-features = false }` under
`[dev-dependencies]`. Turn the default `cookies` feature off: `default = ["cookies"]` pulls
`headers` 0.4 (`https://raw.githubusercontent.com/httpmock/httpmock/master/Cargo.toml:72-74`,
2026-09-17) and nothing in this template matches on cookies. Do not enable `standalone`,
`https`, `proxy`, `record` or `remote`. Use it in two places and no others: the HTTP-adapter
invocation of R01's `assert_projects_port_contract` (F121), and the adapter's own boundary
tests (F120, py's `test_py_api_repository.py` parity).

##### Ranked runner-up

**`mockito` 1.7.2.** Adopt this instead if the dependency-tree weight of the test build, or
maintainer responsiveness, is weighted above the macOS CI lane. It is the lightest of the three
full-featured options, exposes sync and async (`Server::new()` / `Server::new_async()`,
`https://raw.githubusercontent.com/lipanski/mockito/master/README.md` and
`src/lib.rs:111-112,170`, 2026-09-17), has the extensible matcher
`Mock::match_request(closure)` (`src/mock.rs:327`) and the dynamic responder
`Mock::with_body_from_request(|request| ..)` (`src/mock.rs:524`) that the F121 suite needs, and
its maintainer's median first response is 0.46 days with 2 of 10 recent issues unanswered.
**Why it is second and not first:** gate 4. Its own CI covers `ubuntu-latest` and
`windows-latest` and **no macOS at all**
(`https://raw.githubusercontent.com/lipanski/mockito/master/.github/workflows/tests.yml:16,40,55,68-70`,
2026-09-17), and the best adopter evidence found is `apache/iceberg-rust`, whose `build` and
`build_with_no_default_features` matrices include `macos-latest` but whose `tests` job is
`ubuntu-latest` only (`.github/workflows/ci.yml:118-145,182-210`, 2026-09-17) — so macOS
**compilation** is evidenced and macOS **test execution** is not. Recorded as
**unverified, not failed**. One further watch item: the crate's master `README.md` badge and
its CI `MINIMUM_SUPPORTED_TOOLCHAIN` both read **1.85.0** while the released 1.7.2 declares
`rust-version = 1.70`, so the next release raises the declared MSRV — still inside the 1.96
floor, but the headroom is narrowing.

**Second runner-up: `wiremock` 0.6.5** — the crate the owner-reference document names. It
fails no gate outright and it has the richest matcher story (the `Match` trait and the
`Respond` trait for dynamic responses) and by far the widest adoption, including
`matrix-org/matrix-rust-sdk` at `0.6.5`, `XAMPPRocky/octocrab` and the
`TrueLayer/reqwest-middleware` family. It is ranked third on two concrete grounds, both
recorded above and repeated here because they are the ones that differ from the owner's row:
(a) **async-only**, an R05 coupling this item must not create; (b) **maintenance `at-risk`**,
on signals rather than on a release-age heuristic — last commit on `main`
**2025-08-24T11:50:03Z** ("chore: Release wiremock version 0.6.5"), **7 open pull requests**
whose oldest is #127 from 2023-09-11, PR **#175 "fix(compiler): Refactor let-chains for stable
rustc compatibility" open since 2025-11-29**, PR **#172 "set MSRV in Cargo.toml" closed
unmerged on 2025-08-26** (which is why the crate still declares no `rust-version`), and **7 of
its 10 most recently opened issues unanswered**, the newest of them dated 2025-08-27. All from
`https://api.github.com/repos/LukeMathWalker/wiremock-rs/{commits,pulls,issues}`, 2026-09-17.
Mitigating facts, stated so the verdict is not read as harsher than the evidence: the
repository is **not archived**, 0.6.5 builds on docs.rs
(`https://docs.rs/crate/wiremock/0.6.5/status.json` → `{"doc_status":true}`, 2026-09-17), it
carries no RustSec advisory, and `matrix-org/matrix-rust-sdk` runs its full test suite against
it on `macos-latest` today. It is `at-risk`, not `dormant`.

##### Tradeoffs

The trade this member makes is **platform-and-runtime evidence in exchange for dependency
weight and issue-queue speed.** `httpmock` costs 26 required dev-tree crates and a maintainer
whose median first response to the last ten issues was 10.53 days with 5 of 10 unanswered —
the weakest responsiveness of the four. It buys the only self-evidenced `macos-latest` test
lane in the category, a sync-and-async API that leaves R05 undecided, a declared MSRV that its
CI enforces with `cargo hack check --rust-version --each-feature --no-dev-deps`
(`.github/workflows/ci.yml:88-90`, 2026-09-17), `unsafe_code = "forbid"` in its manifest, and a
repository pushed three days before retrieval. The opposite trade — `mockito`'s lighter tree
and faster maintainer against unverified macOS test execution — is a legitimate owner choice
and is why `mockito` is ranked immediately behind rather than excluded. A third consideration
that did **not** decide it: all three candidates pull `tokio` and `hyper` 1.x into the dev
tree, so none of them is "free" for a sync template; the difference is only whether the *test
code* must be async, and that is the R05 coupling.

##### Parameters

`assumes http-transport-injection-seam` — R01's value verbatim (see `### Parameters`). No
owned parameter. No `CONFLICT:`.

- **Gate 1 — licence:** `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Declared licences,
  recorded as fact only: `httpmock` `MIT`, `mockito` `MIT`, `wiremock` `MIT/Apache-2.0`,
  `httptest` `MIT OR Apache-2.0` (crates.io version metadata, 2026-09-17). No candidate is
  admitted, ranked, preferred or excluded on a licence.
- **Gate 2 — MSRV:** `httpmock` **passes** — `rust-version = "1.88.0"`, inside the 1.96 floor,
  and enforced by the `cargo hack check --rust-version` CI job. Its dependency tree's highest
  declared floor is its own. `mockito` **passes** — 1.7.2 declares 1.70, with master moving to
  1.85. `wiremock` **passes on substance, fails on declaration** — it declares **no**
  `rust-version`, so the MSRV-aware resolver offers the template no protection and a patch
  release could raise the effective floor silently; its *effective* floor is **at least
  1.88**, because its own issue #173 (2025-08-27) reports "`let` expressions in this position
  are unstable" against 0.6.5 and let chains stabilized in **Rust 1.88.0, 2025-06-26**
  (`https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/`, 2026-09-17). `httptest` declares none
  either.
- **Gate 3 — advisories and `unsafe`:** all four **pass**.
  `https://rustsec.org/packages/{httpmock,mockito,wiremock,httptest}.html` each return HTTP 404
  (2026-09-17), RustSec's "no advisory" response. `unsafe` posture: `httpmock`'s manifest
  declares `unsafe_code = "forbid"` at the crate level
  (`Cargo.toml:19`, master, 2026-09-17) — the strongest posture of the four, and the only one
  stated in a manifest rather than inferred. The others are safe Rust over `hyper`/`tokio`,
  which contain `unsafe` by construction; none of this is linked into the shipped binary.
  **Stated from manifests and documentation, not from a line-by-line audit.**
- **Gate 4 — `ubuntu-latest, macos-latest`:** `httpmock` **passes on its own CI** —
  `platform.yml` matrix `os: [ubuntu-latest, macos-latest, windows-latest]`. `wiremock`
  **passes by adopter evidence** — its own CI is `ubuntu-latest` only
  (`.github/workflows/general.yml:15,26,37,49,60`), closed by `matrix-org/matrix-rust-sdk`'s
  `test-all-crates` job "🍏 all crates, 🦀 stable" on `macos-latest` running the suite with
  `nextest` against `wiremock = "0.6.5"`. `mockito` — **unverified for macOS test execution**
  (ubuntu + windows in its own CI; macOS compilation only, via `apache/iceberg-rust`'s `build`
  matrix). `httptest` — not investigated for macOS; it is not adopted. Windows is noted, not
  required: `httpmock` and `mockito` cover it, `wiremock` does not.
- **Gate 5 — default features and async coupling:** `httpmock` **passes with a change**:
  `default = ["cookies"]`, which this recommendation turns off with
  `default-features = false`. Async-runtime coupling: `tokio` 1.43 with features
  `sync, macros, rt-multi-thread, signal, net` is a **required** dependency, but the crate's
  *API* is sync-and-async, so the dev tree contains `tokio` while the template's test code need
  not be async. `wiremock` **passes with a coupling to record**: `tokio` 1.47.1 required, API
  async-only, tested against both `tokio` and `async-std` per its README. `mockito` **passes**:
  `tokio` 1.25 required, sync and async APIs, one optional feature (`color` → `colored`).
- **Gate 6 — binary size and compile cost (qualitative):** all four **pass**; every one is a
  dev-dependency and contributes **zero** bytes to `target/release/rslbp`. Compile cost, ranked
  by required normal dependencies at the newest non-yanked version
  (`https://crates.io/api/v1/crates/<name>/<version>/dependencies`, 2026-09-17):
  `wiremock` 15 · `mockito` 16 · `httptest` 16 · `httpmock` **26** (plus 12 optional, none
  enabled here). All four share the `hyper` 1.x + `tokio` + `http-body-util` core, so the
  marginal cost of `httpmock` over `mockito` is roughly ten small pure-Rust crates
  (`similar`, `stringmetrics`, `tabwriter`, `path-tree`, `serde_regex`, `thiserror`, `tracing`,
  `async-object-pool`, `futures-timer`, `form_urlencoded`). **No wall-clock figure is offered:
  nothing was compiled in this run.**

##### Migration implications

`Cargo.toml` — add `httpmock = { version = "0.8.3", default-features = false }` under
`[dev-dependencies]`.
`src/core/adapters/http.rs` — **the base URL becomes a constructor parameter**:
`HttpProjectsPort::new(base_url: Url, token: String)` with the production default supplied by
the composition root, not by a `const BASE_URL` the tests cannot reach. This is the single
structural change this item forces on R01's design and it is the direct consequence of Rust
having no in-process interception equivalent to py's `@responses.activate`.
`tests/port_contract.rs` (R01's F121 file) — a second invocation of
`assert_projects_port_contract`, constructing the HTTP adapter against a per-test
`MockServer` whose `respond_with` closure honours the `workspace` and `limit` query parameters
exactly as py's `_projects_cb` does.
`tests/http_adapter_boundary.rs` (new) — the drift tests: renamed `data` key, missing `name`,
non-string `name`, plus 401/404/500 status mappings into R67's `error-taxonomy-exit-codes`
vocabulary.
No change to `src/lib.rs`'s public surface beyond the constructor signature; no change to the
shipped binary; no CI job added by this item (the tier placement is R32's and R11's).

##### Validation strategy

**All proposed, none executed in this run — no Rust code was compiled.**

1. `cargo test --test port_contract` — expected: two passing cases,
   `assert_projects_port_contract("in_memory", ..)` and
   `assert_projects_port_contract("http", ..)`, from the same seed rows. **The check that
   proves the principle:** deliberately rename the stub's `data` key to `results` and re-run;
   the `http` case must fail while the `in_memory` case still passes. That is py's headline
   regression (`tests/core/test_py_api_repository.py:113-117`, "The headline bug:
   `.get("data", [])` turned drift into 'No projects found.'") reproduced in Rust.
2. `cargo test --test http_adapter_boundary` — expected: each drift and status case maps to the
   `PortError`/`ErrorCode` R67 defines; a 401 must not surface as a generic I/O failure.
3. `cargo test -- --test-threads=8` on `ubuntu-latest` and on `macos-latest` — expected: no
   port collision and no cross-test interference, because every `MockServer` takes an ephemeral
   port. This is the check that closes gate 4 empirically for *this* template rather than by
   citation.
4. `cargo tree --edges normal` — expected: `httpmock` absent, proving it never reaches the
   shipped artifact.
5. Under whichever branch R05 picks, the same two test files compile unchanged except for
   `#[tokio::test]` versus `#[test]` attributes and `start_async().await` versus `start()`.
   Expected result: no other line changes. This is the check that would have failed had
   `wiremock` been chosen while R05 was still open.

##### Confidence & re-verify trigger

**Medium.** The registry, GitHub, RustSec, docs.rs, manifest, CI-matrix and API-surface facts
are all directly verified at their endpoints today, and the three-way comparison rests on
figures rather than reputation. Confidence is not higher because (i) nothing was compiled, so
every acceptance criterion is proposed; (ii) the choice against `wiremock` differs from the
owner-supplied reference architecture and therefore needs owner confirmation, not just
evidence; and (iii) `httpmock`'s issue-queue responsiveness is the weakest of the four, which
is a real if non-blocking risk for a template dependency.

Re-verify if any of these change: R05 resolves to async everywhere (re-weigh `wiremock`, whose
matcher story is the richest, **after** re-checking its commit activity);
`LukeMathWalker/wiremock-rs` gains commits after 2025-08-24 or ships 0.6.6 with a declared
`rust-version` (the maintenance ground for ranking it third would lapse); `httpmock` releases
0.9.0 (edition 2024, `rust-version` 1.88.0 on master today) — check the `respond_with` and
`is_true` signatures survive; `mockito` releases with `rust-version` 1.85 and adds a macOS CI
lane (it would then match `httpmock` on gate 4 with a lighter tree and should be re-ranked);
any of the four gains a RustSec advisory; or the MSRV floor moves past a declared
`rust-version` as stable advances (at stable 1.98.1 the floor is 1.96; `httpmock`'s 1.88 has
four minors of headroom).

##### Sources

crates.io, retrieved 2026-09-17: `https://crates.io/api/v1/crates/{httpmock,mockito,wiremock,httptest,stubr,rvcr}`
(`crate.recent_downloads`, `crate.downloads`), the same paths' `/versions` (newest non-yanked
`num` and `created_at`, and each version's declared `rust_version` and `license`),
`/<name>/<version>/dependencies` (dependency counts and feature-optionality), and
`/<name>/reverse_dependencies` (`meta.total` and the top dependents listing).
GitHub REST through authenticated `gh api`, retrieved 2026-09-17:
`repos/{LukeMathWalker/wiremock-rs,lipanski/mockito,httpmock/httpmock,ggriffiniii/httptest}`
(`stargazers_count`, `archived`, `pushed_at`);
`search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`);
`repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus each issue's
`/comments` for the responsiveness medians;
`repos/LukeMathWalker/wiremock-rs/commits?per_page=5` (last commit 2025-08-24T11:50:03Z);
`repos/LukeMathWalker/wiremock-rs/pulls?state=open&sort=created&direction=asc` (7 open, oldest
#127 from 2023-09-11, #175 from 2025-11-29); `repos/LukeMathWalker/wiremock-rs/pulls/{172,174}`
(`merged: false`).
RustSec, retrieved 2026-09-17: `https://rustsec.org/packages/{httpmock,mockito,wiremock,httptest}.html`
— HTTP 404 each.
docs.rs, retrieved 2026-09-17: `https://docs.rs/crate/{wiremock/0.6.5,mockito/1.7.2,httpmock/0.8.3}/status.json`
→ `{"doc_status":true}`; `https://docs.rs/httpmock/0.8.3/httpmock/struct.Then.html` and
`.../struct.When.html` for the released 0.8.3 API surface.
Maintainers' sources, retrieved 2026-09-17:
`https://raw.githubusercontent.com/httpmock/httpmock/master/{Cargo.toml,src/api/spec.rs,src/api/mock.rs,.github/workflows/ci.yml,.github/workflows/platform.yml}`;
`https://raw.githubusercontent.com/lipanski/mockito/master/{README.md,src/lib.rs,src/mock.rs,.github/workflows/tests.yml}`;
`https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/{README.md,.github/workflows/general.yml}`.
Adopters, retrieved 2026-09-17:
`https://raw.githubusercontent.com/awslabs/aws-lambda-rust-runtime/main/lambda-runtime/Cargo.toml:63`;
`https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml:266,280`;
`https://raw.githubusercontent.com/matrix-org/matrix-rust-sdk/main/{Cargo.toml:130,.github/workflows/ci.yml:164-215}`;
`https://raw.githubusercontent.com/XAMPPRocky/octocrab/main/Cargo.toml:106`;
`https://raw.githubusercontent.com/TrueLayer/reqwest-middleware/main/reqwest-middleware/Cargo.toml:37`;
`https://raw.githubusercontent.com/apache/iceberg-rust/main/{Cargo.toml:120,crates/catalog/rest/Cargo.toml:51,.github/workflows/ci.yml:118-210}`.
Rust project sources, retrieved 2026-09-17: `https://api.github.com/repos/rust-lang/rust/releases`
(stable 1.98.1, 2026-09-03); `https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/` (let chains).
Source repos at their pins, read 2026-09-17:
`py: tests/core/test_py_api_repository.py:1-8,104-140`,
`py: tests/core/test_projects_repository_contract.py:1-60`, `py: pyproject.toml:101` at
`b08bccfb`; `ts: tests/api.test.ts:1-38` at `cb1cbcb2`.
Programme documents, read 2026-09-17: `research/topics/01-ports-and-adapters-seam/DECISION.md`;
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md:125-126`;
`docs/port/DIVERGENCE-ANALYSIS.md:176-178`; `docs/port/areas/testing-coverage.md:9-10`;
`docs/planning/p02/owner-decisions.md` sections 7 and 11;
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md:72,117,197`;
`research/topics/69-web-framework-stack/DECISION.md:221,680,2280-2314`.

### Compatibility

The three members are proved to work together three ways, in descending order of directness.

1. **A shared adopter at the exact recommended versions.** `contentauth/c2pa-rs` — Adobe's
   Content Authenticity Initiative reference SDK for the C2PA standard — carries
   `mockall = "0.15.0"` in `[dev-dependencies]` and `httpmock = "0.8.3"` in
   `[target.'cfg(not(target_arch = "wasm32"))'.dev-dependencies]` of the same manifest
   (`https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml:266,280`,
   retrieved 2026-09-17). Both members, both at the versions recommended here, resolving in one
   lockfile in a shipping project. No equivalent pairing exists for `mockall` with `mockito` or
   with `wiremock` in the projects surveyed, which is an additional, independent reason the
   recommendation lands on `httpmock`.
2. **Member 1 composes with both crate members by construction.** `RecordingPort<P: ProjectsPort>`
   is generic over the port, so it wraps `InMemoryProjectsPort`, the HTTP adapter under an
   `httpmock` server, and `MockProjectsPort` alike — there is no version matrix to satisfy,
   because it is template code with no dependency.
3. **Version-matrix reasoning against the fixed parameters.** Highest declared `rust-version`
   across the three members and their dependency trees is `httpmock`'s **1.88.0**, inside the
   **1.96** floor implied by stable 1.98.1 (2026-09-03). `mockall` 0.15.0 declares 1.77.0 and
   `edition = "2021"`, which an `edition = "2024"` workspace consumes without friction
   (editions are per-crate). Neither crate constrains the other: `mockall`'s tree contains no
   `hyper`, no `tokio` and no `http`; `httpmock`'s contains no `syn`. R01's own probe already
   resolved `mockall` 0.15.0 alongside `serde` 1.0.229 and, separately, `async-trait` 0.1.92
   without conflict, noting only that `mockall` adds a second `syn` major — a build-cost fact,
   not a conflict (`research/topics/01-ports-and-adapters-seam/DECISION.md`, *Compatibility*).
   **Not proved here:** that all three compile and pass together inside the real template.
   That is P03's, for the same reason R01 deferred the equivalent claim.

### Parameters

No parameter is owned by this item (`## Couplings`, `owns:` is empty).

`assumes http-transport-injection-seam = ` **trait-object port erased at the composition root:
the driven-I/O contract is a dyn-compatible Rust trait (`pub trait ProjectsPort: Send + Sync`;
no `async fn`, generic methods, associated consts or non-receiver `Self`) with a blanket impl
for `Arc<T>`; the use case is generic over it (`ProjectsService<P: ProjectsPort>`); the
composition root (plain functions, no DI container) erases the production adapter to
`Arc<dyn ProjectsPort>` and hands the single `ProjectsService<Arc<dyn ProjectsPort>>` to the
CLI and the web layer; fakes and test doubles are injected as any `ProjectsPort` implementor
(the shipped `InMemoryProjectsPort`), never as injected function values and never by patching a
transport; under an async R05 the trait keeps dyn compatibility with `async-trait` 0.1.92**
(verbatim from `docs/port/PARAMETERS.md`, row `http-transport-injection-seam`, owner R01, read
2026-09-17).

This item's recommendation needs **no change** to that value. Every member composes with it as
written: member 1 supplies `ProjectsPort` implementors, member 2 generates one, and member 3
stubs the upstream *below* the port rather than patching a transport *at* it — the clause
"never by patching a transport" constrains how doubles reach the **port**, and a loopback
server is not a patch of any transport.

**No `CONFLICT:` lines.**

Other parameters read but not consumed as registry dependencies: `rust-edition = 2024`,
`msrv-policy`, `license = MIT OR Apache-2.0`, `target-os-matrix = ubuntu-latest, macos-latest`
(all owner-fixed, `docs/port/PARAMETERS.md`); `error-taxonomy-exit-codes` (R67), referenced
only to say the adapter's boundary tests assert against its vocabulary.

One `BASELINE-REVIEW:` line is emitted, in full form, under `### Principles and
implementation` (F120).

### Migration implications

File-level, against the template P03 will build. Crate naming and workspace placement are
R02's; test-tier placement and CI lane structure are R32's and R11's.

| File | Change | Owner of the surrounding decision |
|---|---|---|
| `Cargo.toml` | add `mockall = { version = "0.15.0", optional = true }` under `[dependencies]`; add `[features] mock = ["dep:mockall"]`; add `httpmock = { version = "0.8.3", default-features = false }` under `[dev-dependencies]` | this item |
| `src/core/ports.rs` | add `#[cfg_attr(feature = "mock", mockall::automock)]` above `pub trait ProjectsPort`; under an async R05 it must precede `#[async_trait]` | R01 owns the trait; this item owns the attribute |
| `src/core/adapters/http.rs` | **constructor takes a base URL** — `HttpProjectsPort::new(base_url, token)` rather than a private `const BASE_URL` — so tests can point it at a loopback stub | this item (the requirement); R01 owns the file |
| `src/core/testing.rs` | **new** — `pub struct RecordingPort<P>`, `pub struct PortCall`, `pub fn calls()` | this item |
| `src/lib.rs` | re-export `RecordingPort` and `PortCall` beside R01's exports | R04 owns the public-surface policy |
| `tests/port_contract.rs` | second invocation of R01's `assert_projects_port_contract`, against the HTTP adapter pointed at an `httpmock::MockServer` with a `respond_with` closure honouring `workspace` and `limit` | R01 owns the suite; this item supplies the upstream |
| `tests/http_adapter_boundary.rs` | **new** — drift and status-mapping tests (renamed `data` key, missing `name`, non-string `name`, 401/404/500) | this item |
| `tests/cli_projects.rs` | build the CLI over `RecordingPort<InMemoryProjectsPort>` and assert the recorded `ProjectQuery` — py's `assert_called_with` parity | R32 owns the tier; this item owns the double |
| CI workflow | one lane must run `cargo test --features mock` so the gated mocks cannot rot | R11 and R32 own the lane |

Nothing in this item changes the shipped binary, the library's runtime dependency graph, or any
`[profile.*]` setting.

### Validation strategy

Commands that would prove the principle holds in a realistic example. **Every one is proposed.
None was executed: the Rust template does not exist yet, P03 builds it, and this run compiled
no Rust.** The only things actually *run* in this research were HTTP retrievals against
crates.io, `api.github.com` (through authenticated `gh api`), RustSec, docs.rs,
`raw.githubusercontent.com` and `blog.rust-lang.org`, plus `git show` reads at the two pins.

| # | Command | Expected behavior | Which principle it proves |
|---|---|---|---|
| 1 | `cargo test` | Passes with no mocking crate in the resolved graph | The default suite needs no mock crate (F119 capability, framework-native mechanism) |
| 2 | `cargo tree --edges dev \| grep -c mockall` | `0` without `--features mock` | The escape hatch is genuinely gated |
| 3 | `cargo test --features mock` | The `MockProjectsPort` test passes; the file compiles, which is itself the proof that the generated mock is `Send + Sync` and erasable to `Arc<dyn ProjectsPort>` | B3 parity with `assert_called_with`; compatibility with R01's erasure |
| 4 | `cargo test --test port_contract` | Two passing cases, `in_memory` and `http`, from one seed set | F121 substitutability across **every** adapter, including the one that performs I/O |
| 5 | Rename the stub's `data` key to `results`, re-run #4 | The `http` case fails; the `in_memory` case still passes | B6 — schema drift is loud, py's headline HEX-40/P04 regression, reproduced |
| 6 | `cargo test --test http_adapter_boundary` | Each drift and status case maps to the `ErrorCode` R67 defines | The adapter's error translation is tested, not assumed |
| 7 | `cargo test -- --test-threads=8` on `ubuntu-latest` **and** `macos-latest` | No port collision, no cross-test interference | Gate 4 closed empirically for this template rather than by citation |
| 8 | `cargo tree --edges normal \| grep -c httpmock` | `0` | No test-only crate reaches the shipped artifact |
| 9 | `cargo build --release` then compare `target/release/rslbp` size with and without the `mock` feature | Identical | Gate 6, measured rather than asserted |

Checks 3, 5 and 7 are the three that would actually falsify this report's recommendation; the
rest are hygiene.

### Confidence & re-verify trigger

**Overall: medium-high on member 1, medium-high on member 2, medium on member 3.**

What is solid: every registry, GitHub, RustSec, docs.rs and manifest figure in this report was
retrieved today from the endpoint the prompt names, and the API-shape claims were read in the
crates' own released sources or on docs.rs for the exact recommended version. The conditional
this item was told to answer is resolved on the published R01 decision rather than on
inference. The architectural comparison was done before any crate was weighed, and every gate
is answered per candidate.

What is not: nothing was compiled, so all nine acceptance checks are proposed;
`MockProjectsPort: Send + Sync` under R01's erasure is argued from `mockall`'s own source and
not observed; `mockall` 0.15.0's macOS support is inferred from a 0.13.0 adopter; and
`mockito`'s macOS **test execution** could not be evidenced at all.

Re-verify the whole item if: **R05 resolves** (it is the one open input that could re-rank
member 3 — an async-everywhere answer makes `wiremock`'s async-only API costless and its
matcher story its strongest asset, subject to a fresh maintenance check); **the owner rules on
the `wiremock` row** of the reference architecture against this report's ground; **R01 is
revised** such that the port is no longer a dyn-compatible trait or the HTTP adapter no longer
performs real I/O (which would retire member 3 entirely); or **R32 selects a runner that
changes the test-attribute surface** (a runner requiring its own async attribute would change
which of `httpmock`'s two API halves the template uses, though not the crate choice).

Per-crate triggers are listed in each member's own `Confidence & re-verify trigger`. The
shortest-fused one: `LukeMathWalker/wiremock-rs` gaining commits after 2025-08-24, which would
lapse half the ground for ranking it third.

### Sources

Every URL below was retrieved **2026-09-17 (UTC)**. Figures are named with the field they came
from. Repository files read at the programme pins are cited with the pin.

**Registry (crates.io API, `User-Agent` header sent).**
`https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads` (90-day),
`crate.downloads` (all-time), for `mockall`, `mockall_double`, `faux`, `unimock`, `mry`,
`double`, `wiremock`, `mockito`, `httpmock`, `httptest`, `stubr`, `rvcr`, `axum-test`,
`tower-test`.
`https://crates.io/api/v1/crates/<name>/versions` → newest entry with `yanked: false`: `num`,
`created_at`, and that version's `rust_version` and `license`.
`https://crates.io/api/v1/crates/<name>/<version>/dependencies` → required and optional normal
and dev dependencies, used for the compile-cost and async-coupling gates.
`https://crates.io/api/v1/crates/<name>/reverse_dependencies` → `meta.total` (adoption) and the
top dependents by downloads (adopter leads, each then confirmed in the project's own manifest).

**GitHub REST (authenticated `gh api`, 5,000/hour).**
`repos/<o>/<r>` → `stargazers_count`, `archived`, `pushed_at`, for `asomers/mockall`,
`LukeMathWalker/wiremock-rs`, `lipanski/mockito`, `httpmock/httpmock`, `ggriffiniii/httptest`,
`nrxus/faux`.
`search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count` (never `open_issues_count`).
`repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus each issue's `/comments` →
issue responsiveness: median days from `created_at` to the first comment whose
`author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose author is not the
reporter; unanswered counted where no such comment exists.
`repos/LukeMathWalker/wiremock-rs/commits`, `/pulls?state=open`, `/pulls/172`, `/pulls/174`.
`repos/rust-lang/rust/releases` → stable 1.98.1, published 2026-09-03.

**Advisories.** `https://rustsec.org/packages/<name>.html` for `mockall`, `wiremock`,
`mockito`, `httpmock`, `httptest`, `faux`, `unimock`, `mry` — HTTP **404** for every one, which
RustSec serves when a package has no advisory.

**Build status.** `https://docs.rs/crate/<name>/<version>/status.json` for `wiremock/0.6.5`,
`mockito/1.7.2`, `httpmock/0.8.3`, `mockall/0.15.0` → `{"doc_status": true}` in all four cases.

**API surface, read at source.**
`https://docs.rs/httpmock/0.8.3/httpmock/struct.Then.html` and `.../struct.When.html`;
`https://raw.githubusercontent.com/httpmock/httpmock/master/src/api/spec.rs` (`is_true` 4360,
`is_false` 4400, deprecated `matches` 4320, `respond_with` 5041) and `src/api/mock.rs`
(`assert` 114, `assert_async` 154, `assert_hits` 193, `assert_calls` 231, `hits` 382);
`https://raw.githubusercontent.com/lipanski/mockito/master/src/mock.rs` (`match_request` 327,
`with_body_from_request` 524, `expect` 562) and `src/lib.rs` (111-112, 170);
`https://raw.githubusercontent.com/asomers/mockall/master/mockall/src/lib.rs` (Async Traits
1068-1100; `AnyExpectations` 1445) and `mockall/Cargo.toml`;
`https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/README.md` (runtime
compatibility and the prior-art comparison table).

**CI matrices.**
`https://raw.githubusercontent.com/httpmock/httpmock/master/.github/workflows/platform.yml`
and `ci.yml`; `.../lipanski/mockito/master/.github/workflows/tests.yml`;
`.../LukeMathWalker/wiremock-rs/main/.github/workflows/general.yml`;
`.../asomers/mockall/master/.github/workflows/ci.yml`;
`.../tokio-rs/tokio/master/.github/workflows/ci.yml`;
`.../matrix-org/matrix-rust-sdk/main/.github/workflows/ci.yml`;
`.../apache/iceberg-rust/main/.github/workflows/ci.yml`.

**Adopter manifests.** `rust-lang/crates.io` `Cargo.toml`; `tokio-rs/tokio` `tokio/Cargo.toml`;
`contentauth/c2pa-rs` `sdk/Cargo.toml`; `awslabs/aws-lambda-rust-runtime`
`lambda-runtime/Cargo.toml`; `matrix-org/matrix-rust-sdk` `Cargo.toml`; `XAMPPRocky/octocrab`
`Cargo.toml`; `TrueLayer/reqwest-middleware` `reqwest-middleware/Cargo.toml`;
`apache/iceberg-rust` `Cargo.toml` and `crates/catalog/rest/Cargo.toml`.

**Rust project publications.** `https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/` (let
chains stabilized); `https://doc.rust-lang.org/reference/items/traits.html`;
`https://doc.rust-lang.org/std/sync/struct.Mutex.html`.

**Source repositories, through their pins.**
`git -C ~/c/py-launch-blueprint show b08bccfb:tests/cli/test_pylb.py` (lines 6, 55-65, 95, 556,
570); `:tests/core/test_py_api_repository.py` (lines 1-8, 104-140); 
`:tests/core/test_projects_repository_contract.py` (lines 1-60); `:pyproject.toml` (line 101,
`responses>=0.25` with its recorded purpose).
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:tests/api.test.ts` (lines 1-38);
`:tests/cli.test.ts` (lines 12, 45-60, 101-102); `:package.json` (devDependencies — no mocking
or HTTP-interception package present, confirming F119/F120's ts side).
Where this report cites both pins on the same subject it names which commit each claim comes
from; no claim here depends on the HEAD of either repository.

**Programme documents.** `research/topics/01-ports-and-adapters-seam/DECISION.md` (revision 3,
2026-09-13); `research/topics/69-web-framework-stack/DECISION.md` (revision 9, 2026-09-16);
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md`; `docs/port/DIVERGENCE-ANALYSIS.md`;
`docs/port/areas/testing-coverage.md`; `docs/planning/p02/owner-decisions.md` (sections 7 and
11); `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`; this run's
`inputs/prompt.md`, `inputs/PARAMETERS.md` and `inputs/CLAUDE.md`.

**Method notes.** Endpoints queried in this run: `https://crates.io/api/v1/crates/...`
(`<name>`, `/versions`, `/<version>/dependencies`, `/reverse_dependencies`) for 14 crates;
`https://api.github.com/...` through authenticated `gh api` (`repos/<o>/<r>`,
`search/issues`, `repos/<o>/<r>/issues`, `.../comments`, `.../pulls`, `.../commits`,
`repos/rust-lang/rust/releases`) for 7 repositories; `https://rustsec.org/packages/<name>.html`
for 8 crates; `https://docs.rs/crate/<name>/<version>/status.json` and two `docs.rs` HTML API
pages; `https://raw.githubusercontent.com/...` for 20 manifests, workflows, READMEs and source
files; `https://blog.rust-lang.org/2025/06/26/Rust-1.88.0/`. The first six GitHub calls of the
run were made anonymously before the coordinator's correction that `gh` is authenticated on
this machine; they returned the same `stargazers_count`/`archived`/`pushed_at` values later
confirmed through `gh api`, and every figure reported above is the authenticated one.

**What I could not verify, stated as unverified rather than guessed.**
(1) **Nothing was compiled.** No `cargo` command was run — the template does not exist, P03
builds it, and this run was instructed not to scaffold. Every acceptance check in
`### Validation strategy` and in each member's `Validation strategy` is therefore **proposed,
not executed**, and no wall-clock compile-time or binary-size figure is offered for any
candidate; gate 6 is answered qualitatively throughout, as the prompt permits.
(2) **`MockProjectsPort: Send + Sync`** under R01's `Arc<dyn ProjectsPort>` erasure is argued
from `mockall`'s own source (`AnyExpectations : Any + Send + Sync`, `mockall/src/lib.rs:1445`)
and from the absence of non-`Send` return types in this port, but it is **not observed**; it is
listed as a P03 compile check.
(3) **`mockall` 0.15.0 on macOS** is inferred. The crate's own CI is `ubuntu-latest` only; the
macOS evidence is `tokio-rs/tokio`'s macOS test matrix against `mockall` **0.13.0**, a
different minor.
(4) **`mockito` 1.7.2 macOS test execution** — **unverified**. Its own CI covers `ubuntu-latest`
and `windows-latest`; the best adopter evidence found (`apache/iceberg-rust`) compiles it on
`macos-latest` but runs its `tests` job on `ubuntu-latest` only. Recorded as unverified, not as
a gate failure.
(5) **`wiremock` 0.6.5's dependency-tree MSRV** — **unverified as a resolved number**. The
crate declares no `rust-version`; its effective floor is **at least 1.88** by inference from
its own issue #173 (unstable `let` expressions) and the Rust 1.88.0 release announcement, not
from a resolved lockfile.
(6) **`httptest`'s macOS support** was not investigated; the crate is not adopted, so the gate
was not pursued.
(7) **`faux`'s `unsafe` posture** is taken from its documentation as recorded by R01 on
2026-09-05, not from a line-by-line audit; the same caveat applies to every `unsafe` statement
in this report, which are all documentation- and manifest-level rather than audited.
(8) **The owner-reference reconciliation** is offered as this report's disposition, not as a
settled outcome: `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` names
`wiremock` and R48 is not in owner decision 11's overlap set, so the differ-with-ground above
needs an owner ruling rather than more evidence.
