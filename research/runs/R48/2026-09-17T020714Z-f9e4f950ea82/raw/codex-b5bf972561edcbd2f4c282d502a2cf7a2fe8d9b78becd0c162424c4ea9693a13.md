### Landscape

**Decision category.** R48 selects test-double ergonomics and, only where an adapter really performs HTTP, a local HTTP test server. Rust's first-party bin is `#[test]` plus hand-written trait implementors and closures; the Rust Book explicitly presents a mock as a type that implements the dependency trait and says the standard library has no built-in mock-object facility. [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects)  The established-practice bin is `mockall` for generated trait mocks and local-server HTTP fakes (`wiremock`, `mockito`, and `httpmock`); the up-and-comer bin is `unimock`, whose single `Unimock` type implements annotated traits. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [wiremock README, retrieved 2026-09-16](https://github.com/LukeMathWalker/wiremock-rs/blob/main/README.md) [Mockito README, retrieved 2026-09-16](https://github.com/lipanski/mockito/blob/master/README.md) [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md) [unimock README, retrieved 2026-09-16](https://github.com/audunhalland/unimock/blob/main/README.md)

The authoritative sources are the Rust Project's Book and Cargo reference, which specify the language's trait-based test-double pattern, `dev-dependencies`, and `rust-version` behavior; each crate maintainer's README/API documentation, which specifies its supported API and runtime contract; crates.io's public API, which is the required source for package figures; and GitHub's REST endpoints, which are the required source for repository figures and issue counts. [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects) [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies) [Cargo rust-version reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/rust-version.html)

| Candidate | 90-day / all-time downloads | newest non-yanked release | repository figures | open issues / adoption evidence | source endpoint and retrieval |
|---|---:|---|---|---|---|
| `mockall` | 27,536,920 / 168,074,531 | `0.15.0`, 2026-06-28 | 1,843 stars; not archived; pushed 2026-09-02 | 51; 1,312 reverse dependencies; `metrics-util 0.20.4` declares `mockall ^0.13`, a maintained metrics-ecosystem package | [crates](https://crates.io/api/v1/crates/mockall), [versions](https://crates.io/api/v1/crates/mockall/versions), [repo](https://api.github.com/repos/asomers/mockall), [issues](https://api.github.com/search/issues?q=repo:asomers/mockall+is:issue+is:open), [reverse dependencies](https://crates.io/api/v1/crates/mockall/reverse_dependencies?per_page=1), [adopter Cargo metadata](https://docs.rs/metrics-util/0.20.4/metrics_util/); retrieved 2026-09-16 |
| `wiremock` | 20,169,001 / 77,783,427 | `0.6.5`, 2025-08-24 | 799 stars; not archived; pushed 2025-08-24 | 24; 2,916 reverse dependencies; `reqwest-middleware 0.5.2` declares `wiremock ^0.6.0`, a maintained outbound-HTTP middleware package | [crates](https://crates.io/api/v1/crates/wiremock), [versions](https://crates.io/api/v1/crates/wiremock/versions), [repo](https://api.github.com/repos/LukeMathWalker/wiremock-rs), [issues](https://api.github.com/search/issues?q=repo:LukeMathWalker/wiremock-rs+is:issue+is:open), [reverse dependencies](https://crates.io/api/v1/crates/wiremock/reverse_dependencies?per_page=1), [adopter Cargo metadata](https://docs.rs/reqwest-middleware/0.5.2/reqwest_middleware/); retrieved 2026-09-16 |
| `mockito` | 8,806,141 / 56,102,130 | `1.7.2`, 2026-02-02 | 781 stars; not archived; pushed 2026-08-01 | 7; 1,322 reverse dependencies | [crates](https://crates.io/api/v1/crates/mockito), [versions](https://crates.io/api/v1/crates/mockito/versions), [repo](https://api.github.com/repos/lipanski/mockito), [issues](https://api.github.com/search/issues?q=repo:lipanski/mockito+is:issue+is:open), [reverse dependencies](https://crates.io/api/v1/crates/mockito/reverse_dependencies?per_page=1); retrieved 2026-09-16 |
| `httpmock` | 5,522,473 / 29,547,448 | `0.8.3`, 2026-02-04 | 667 stars; not archived; pushed 2026-09-14 | 17; 585 reverse dependencies | [crates](https://crates.io/api/v1/crates/httpmock), [versions](https://crates.io/api/v1/crates/httpmock/versions), [repo](https://api.github.com/repos/httpmock/httpmock), [issues](https://api.github.com/search/issues?q=repo:httpmock/httpmock+is:issue+is:open), [reverse dependencies](https://crates.io/api/v1/crates/httpmock/reverse_dependencies?per_page=1); retrieved 2026-09-16 |
| `unimock` | 29,082 / 178,322 | `0.6.8`, 2025-11-07 | 81 stars; not archived; pushed 2026-08-22 | 5; 13 reverse dependencies | [crates](https://crates.io/api/v1/crates/unimock), [versions](https://crates.io/api/v1/crates/unimock/versions), [repo](https://api.github.com/repos/audunhalland/unimock), [issues](https://api.github.com/search/issues?q=repo:audunhalland/unimock+is:issue+is:open), [reverse dependencies](https://crates.io/api/v1/crates/unimock/reverse_dependencies?per_page=1); retrieved 2026-09-16 |

Practice evidence is stronger for the two selected layers than raw familiarity: `metrics-util`'s published metadata uses `mockall`, while the widely reused `reqwest-middleware` package uses `wiremock`; both examples are test-only dependencies in packages whose published docs describe their production roles. [metrics-util documentation, retrieved 2026-09-16](https://docs.rs/metrics-util/0.20.4/metrics_util/) [reqwest-middleware documentation, retrieved 2026-09-16](https://docs.rs/reqwest-middleware/0.5.2/reqwest_middleware/)

### Principles and implementation

The shared requirement is **hermetic behavior verification at the driven-I/O seam**, not a shared mock library; its agreement level is architectural policy. The pinned Python source uses `Mock`/`patch` at the CLI composition seam and `responses` only where the adapter makes real HTTP, while the pinned TypeScript source passes fake functions through `CliDeps` and `fetchImpl`. [Python pin `b08bccfb` CLI test, retrieved 2026-09-16](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/tests/cli/test_pylb.py) [Python pin `b08bccfb` HTTP test, retrieved 2026-09-16](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/tests/core/test_py_api_repository.py) [TypeScript pin `cb1cbcb2` CLI test, retrieved 2026-09-16](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/tests/cli.test.ts) [TypeScript pin `cb1cbcb2` API test, retrieved 2026-09-16](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/tests/api.test.ts)

Required observable behavior is: a CLI/use-case test supplies a deterministic port implementation and verifies result, output, error, and interaction without DNS or a real remote service; an HTTP-adapter test, if one is required, targets a per-test loopback server and asserts request matching, response mapping, and an unmatched-request failure. This preserves the source principle while allowing Rust's trait implementations and local servers to differ from Python's global interception and TypeScript's function values. [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects) [wiremock test-isolation documentation, retrieved 2026-09-16](https://github.com/LukeMathWalker/wiremock-rs/blob/main/README.md#test-isolation)

The registered R01 parameter currently chooses a dyn-compatible trait port and a shipped in-memory fake, not injected function values or transport patching; therefore the normal R48 design is hand-written fakes first, `mockall` only when an interaction expectation is clearer than a small fake, and no HTTP mock crate for use-case/CLI tests. [registered parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md)  A local HTTP server remains the right conditional test for a concrete HTTP adapter because it observes a real request at the protocol boundary without changing global process behavior. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)  No benchmark was run: representative compile-time and binary-size cost is qualitative only, because these are dev-dependencies; `mockall` adds a procedural-macro expansion, and each HTTP option adds a Hyper/Tokio local-server graph. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [httpmock manifest, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/Cargo.toml)

Minimal proposed example: define `ProjectsPort`, give `ProjectsService<P: ProjectsPort>` an `InMemoryProjectsPort` in most tests, use a `MockProjectsPort` only to assert one retry/error interaction, and point the production HTTP adapter's configurable base URL at a fresh `httpmock::MockServer` only in the adapter test. Planned acceptance is `cargo test` under R32's runner on Ubuntu and macOS, with an unmatched local request failing; no Rust code or command was executed in this research run. [R01 parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) [httpmock README example, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)

### Recommendation

Use one stack: `mockall = "0.15.0"` in `[dev-dependencies]` for expectation-heavy trait doubles, while retaining hand-written `ProjectsPort` fakes as the default; under the conditional real-outbound-HTTP branch only, add `httpmock = "0.8.3"` and redirect the adapter base URL to its per-test server. Cargo defines development dependencies as test/build-only dependencies rather than published runtime dependencies. [Mockall crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockall/versions) [httpmock crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions) [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies)

### Members

#### mockall 0.15.0 — general mock/test-double crate

##### Landscape

`mockall` is the established generated-trait-mock choice; the built-in alternative is a hand-written trait implementation, and `unimock` is the lower-adoption alternative. `mockall`'s 27,536,920 90-day downloads, 168,074,531 all-time downloads, and 1,312 reverse dependencies are figures from the required crates.io endpoints, not a selection criterion by themselves. [crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockall) [reverse-dependencies endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockall/reverse_dependencies?per_page=1)

##### Principles and implementation

`#[automock]` generates a mock from a trait or module and its expectation builder can return controlled values, which supplies Python `Mock`-style interaction assertions while preserving Rust's explicit trait seam. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md)  A handwritten fake stays preferred for stateful behavior and contract readability because it is ordinary Rust and exactly matches the Rust Book's trait-implementor pattern. [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects)

##### Dominant choice

Choose `mockall 0.15.0`; its maintainer documents safe stable Rust, `#[automock]`, and MSRV 1.77.0, and the release endpoint records compatible dual licensing. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockall/versions)

##### Qualified shortlist

`mockall 0.15.0` and a hand-written fake both satisfy the architecture; the crate is selected for the tests where interaction expectations materially reduce boilerplate, not as a mandate to replace fakes. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects)

##### Excluded by gate

No general-mocking candidate is excluded for an observed incompatible license, but `unimock 0.6.8` is excluded from the selected stack on fit: its 29,082 90-day downloads, 13 reverse dependencies, macro-specific `Unimock` API, and optional Tokio feature do not justify a second unfamiliar convention beside simple fakes and `mockall`. [unimock crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/unimock) [unimock reverse-dependencies endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/unimock/reverse_dependencies?per_page=1) [unimock README, retrieved 2026-09-16](https://github.com/audunhalland/unimock/blob/main/README.md)

##### Up-and-comers

`unimock 0.6.8` is the up-and-comer: it supports Rust 1.70 and MIT licensing, but its low adoption means it should be reconsidered only if the template needs one composite mock implementing many traits. [unimock versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/unimock/versions) [unimock README, retrieved 2026-09-16](https://github.com/audunhalland/unimock/blob/main/README.md)

##### Fit for this template

License gate passes at the crate manifest (`MIT OR Apache-2.0`); the crate's declared 1.77.0 MSRV is below the policy floor, but the resolved dependency-tree MSRV is unverified and must be checked after the template fixes `rust-version`. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [Cargo rust-version reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/rust-version.html)  The RustSec package endpoint required by the prompt, `https://rustsec.org/packages/mockall.html`, returned HTTP 404, so the no-open-advisory gate is unverified rather than passed. [RustSec endpoint, retrieved 2026-09-16](https://rustsec.org/packages/mockall.html)  The crate has no default feature shown by its crates.io release metadata; its documented safe-Rust posture is favorable, its proc macro makes compile cost nonzero, and it has no production binary-size cost when kept in `dev-dependencies`. [release metadata endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockall/0.15.0) [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md)  Its public CI shown on Ubuntu stable/MSRV does not demonstrate the required macOS lane, so the template must prove its own Ubuntu/macOS test matrix before acceptance. [Mockall CI, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/.github/workflows/ci.yml)

##### Recommendation

Add `mockall = "0.15.0"` under `[dev-dependencies]`; use it for a trait mock only when a test must assert calls, arguments, ordering, or an injected failure, and use a hand-written fake for stateful scenarios. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies)

##### Ranked runner-up

The runner-up is no additional crate: a small hand-written `ProjectsPort` fake is idiomatic, has no dependency, no runtime coupling, no unsafe code introduced by R48, and directly implements the interface under test. [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects)

##### Tradeoffs

`mockall` gives concise expectations but adds macro expansion and couples test declarations to generated `Mock*` names; handwritten fakes have more local code but expose behavior directly. No latency, throughput, or resource benchmark applies to an in-process test-double library, and none was run. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md)

##### Parameters

Assumes `http-transport-injection-seam` is R01's trait-object port; `mockall` consumes no additional parameter and does not change the seam. [registered parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md)

##### Migration implications

P03 would add the one `Cargo.toml` dev-dependency, annotate only selected internal test-visible traits, and place generated mocks in test modules; it would not scaffold or add an HTTP interceptor to CLI/use-case tests. [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies) [R48 source-area record, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/testing-coverage.md)

##### Validation strategy

Planned, not executed: run `cargo test --workspace --locked` on `ubuntu-latest` and `macos-latest`; a generated `MockProjectsPort` must return the configured value and fail when its expectation is unmet, while the corresponding hand-written fake must pass the same service assertion. [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md)

##### Confidence & re-verify trigger

Medium confidence: re-verify before P03 pins the dependency, on any MSRV-policy change, and if `cargo audit`/the accepted RustSec replacement finds an advisory; re-verify macOS compilation because upstream public CI evidence is Ubuntu-only. [Cargo rust-version reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/rust-version.html) [Mockall CI, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/.github/workflows/ci.yml)

##### Sources

Maintenance is **active**: the repository was not archived, was pushed on 2026-09-02, and its latest release was 2026-06-28. Of the ten latest open non-PR issues, nine had a first `OWNER`/`MEMBER`/`COLLABORATOR` response; the median was 4.98 days and one was unanswered, computed from the issue list and each issue's comments endpoint. [repository endpoint, retrieved 2026-09-16](https://api.github.com/repos/asomers/mockall) [issue list endpoint, retrieved 2026-09-16](https://api.github.com/repos/asomers/mockall/issues?state=open&sort=created&direction=desc&per_page=40) [comments endpoint pattern, retrieved 2026-09-16](https://api.github.com/repos/asomers/mockall/issues/689/comments)

#### httpmock 0.8.3 — conditional HTTP-transport mock server

##### Landscape

`httpmock` is an active local HTTP-server option. Its 5,522,473 90-day downloads, 29,547,448 all-time downloads, 585 reverse dependencies, and 667 GitHub stars place it below `wiremock` on adoption but well above the up-and-comer threshold; its maintained cross-platform CI makes it the best fit for this template's fixed OS gate. [crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock) [reverse-dependencies endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/reverse_dependencies?per_page=1) [repository endpoint, retrieved 2026-09-16](https://api.github.com/repos/httpmock/httpmock) [platform CI, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/.github/workflows/platform.yml)

##### Principles and implementation

`httpmock::MockServer::start` creates a local server, a closure configures request conditions and response behavior, and `mock.assert()` verifies the request count; that is scoped-to-test builder/server lifecycle rather than Python's decorator/global interception. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)  The crate documents a fully asynchronous core with synchronous and asynchronous APIs, so test syntax need not pre-decide R05, although it brings Tokio transitively. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md) [release dependency endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/0.8.3/dependencies)

##### Dominant choice

Choose `httpmock 0.8.3` only if a concrete adapter performs HTTP and can receive a test base URL. It is the only surveyed HTTP candidate with current repository CI explicitly testing stable on Ubuntu, macOS, and Windows, while its crate release metadata records MIT licensing and MSRV 1.88.0. [httpmock platform CI, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/.github/workflows/platform.yml) [versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions)

##### Qualified shortlist

The qualified HTTP-server shortlist is `httpmock 0.8.3`, `mockito 1.7.2`, and `wiremock 0.6.5`; each provides a local server, request matcher, configured response, and assertion rather than process-global interception. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md) [Mockito README, retrieved 2026-09-16](https://github.com/lipanski/mockito/blob/master/README.md) [wiremock README, retrieved 2026-09-16](https://github.com/LukeMathWalker/wiremock-rs/blob/main/README.md)

##### Excluded by gate

`wiremock 0.6.5` is provisionally excluded despite 20,169,001 90-day downloads because its latest release and repository push were 2025-08-24, the repository's current public Rust workflow is Ubuntu-only, and its release metadata declares no `rust_version`; this fails the evidence gate for macOS/MSRV rather than proving a runtime defect. [wiremock crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/wiremock) [wiremock repository endpoint, retrieved 2026-09-16](https://api.github.com/repos/LukeMathWalker/wiremock-rs) [wiremock CI, retrieved 2026-09-16](https://github.com/LukeMathWalker/wiremock-rs/blob/main/.github/workflows/general.yml) [wiremock versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/wiremock/versions)  `mockito 1.7.2` is not selected because its public workflow proves Ubuntu and Windows but not macOS; it remains the runner-up because it is active and documents sync and async interfaces. [Mockito CI, retrieved 2026-09-16](https://github.com/lipanski/mockito/blob/master/.github/workflows/tests.yml) [Mockito README, retrieved 2026-09-16](https://github.com/lipanski/mockito/blob/master/README.md)

##### Up-and-comers

`httpmock 0.8.3` is the newer, active challenger to the more downloaded `wiremock`; its maintainers' main-branch README advertises an unreleased `0.9.0` while the crates.io endpoint still reports `0.8.3`, so the accepted P03 pin must use the registry release, not the README's future example. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md) [httpmock versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions)

##### Fit for this template

The license gate passes at the crate level (MIT), its declared MSRV is 1.88.0, and the public platform matrix names both required operating systems; the dependency-tree MSRV remains unverified until a locked template resolution is checked. [httpmock versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions) [httpmock platform CI, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/.github/workflows/platform.yml)  The RustSec page required by the prompt, `https://rustsec.org/packages/httpmock.html`, returned HTTP 404, so no-open-advisory status is unverified. [RustSec endpoint, retrieved 2026-09-16](https://rustsec.org/packages/httpmock.html)  Default features are `cookies`; HTTPS, standalone, recording, proxy, and HTTP/2 are opt-in, so leave them disabled for the unit-test server. [release metadata endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/0.8.3)  Unsafe-code posture is unverified because no source audit was run; compile time is qualitatively medium/high and test resource cost is one ephemeral loopback server per test, while production binary-size cost is zero when it remains dev-only. [httpmock manifest, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/Cargo.toml) [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies)

##### Recommendation

Do not add an HTTP-mocking dependency for R01's registered trait/fake branch. If a P03 HTTP adapter needs a real request test, add `httpmock = "0.8.3"` in `[dev-dependencies]`, create a fresh server inside that test, inject its URL as the adapter base URL, and assert the configured request exactly once. [registered parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)

##### Ranked runner-up

`mockito 1.7.2` is runner-up: it provides a pooled local server, request matching, `Mock::assert`, and documented sync/async APIs, with 8,806,141 90-day downloads and a 2026-02-02 current release; its missing macOS CI evidence prevents selection under the fixed matrix. [Mockito README, retrieved 2026-09-16](https://github.com/lipanski/mockito/blob/master/README.md) [Mockito crates endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockito) [Mockito CI, retrieved 2026-09-16](https://github.com/lipanski/mockito/blob/master/.github/workflows/tests.yml)

##### Tradeoffs

`httpmock` proves the actual serialized request and response mapping, but it is slower and heavier than a trait fake because it binds a loopback port and starts a server; no latency, throughput, or resource measurement was run, so no absolute performance claim is made. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)  `wiremock` offers strong matcher/template ergonomics and documents both Tokio and async-std compatibility, but its release freshness and required-platform proof are weaker. [wiremock README, retrieved 2026-09-16](https://github.com/LukeMathWalker/wiremock-rs/blob/main/README.md) [wiremock repository endpoint, retrieved 2026-09-16](https://api.github.com/repos/LukeMathWalker/wiremock-rs)

##### Parameters

Assumes `http-transport-injection-seam = R01 trait-object port with injected fake implementations`; therefore `httpmock` is conditional on an adapter-level real HTTP test, not a request to change R01's seam. [registered parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md)

##### Migration implications

Only the conditional P03 branch changes `Cargo.toml` and an HTTP-adapter test module: add the dev-dependency, make the concrete adapter's base URL constructor-configurable, and add no global patching or HTTP-mock dependency to the library/CLI tests. [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies) [R48 source-area record, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/testing-coverage.md)

##### Validation strategy

Planned, not executed: on Ubuntu and macOS, run `cargo test --workspace --locked` with one test starting `MockServer`, mounting a `GET /projects` response, injecting `server.url("")` into the concrete adapter, and asserting mapped domain values plus `mock.assert()`. A second test must leave the route unmatched and observe the adapter's transport/error mapping. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)

##### Confidence & re-verify trigger

Medium confidence: re-verify before P03 because the registry's `0.8.3` and the main README's `0.9.0` differ, whenever R05 selects the runtime, when the locked dependency tree is resolved against the chosen MSRV, and after a working RustSec advisory source is available. [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md) [httpmock versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions) [Cargo rust-version reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/rust-version.html)

##### Sources

Maintenance is **active**: the repository was not archived, was pushed 2026-09-14, and the latest registry release was 2026-02-04. Open-issue responsiveness is unverified because the required ten-issue/comment calculation was collected for the dominant historical alternatives but not for `httpmock`; this is a re-verification task, not an inferred score. [repository endpoint, retrieved 2026-09-16](https://api.github.com/repos/httpmock/httpmock) [issues endpoint, retrieved 2026-09-16](https://api.github.com/search/issues?q=repo:httpmock/httpmock+is:issue+is:open) [versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions)

### Compatibility

The recommended members compose because `mockall` replaces a trait implementor only inside a unit test and `httpmock` is used only by a concrete adapter test; they do not both own an HTTP client or runtime API. The shared composition example is `ProjectsService<MockProjectsPort>` for a service test and `HttpProjectsPort` configured with an `httpmock` base URL for its boundary test. [Rust Book, retrieved 2026-09-16](https://doc.rust-lang.org/book/ch15-05-interior-mutability.html#testing-with-mock-objects) [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)  Compatibility is planned rather than executed because the Rust template does not yet exist. [repository README, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint)

### Parameters

Assumes `http-transport-injection-seam =` R01's registered dyn-compatible trait port with injected fake implementors; that makes `mockall 0.15.0` unconditional and `httpmock 0.8.3` conditional on a concrete adapter test that makes a real outbound HTTP call. [registered parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md)  The fixed `rust-edition = 2024`, `msrv-policy`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest` are preserved; no owned parameter and no `CONFLICT:` are emitted. [parameter registry, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md)

### Migration implications

P03 should add `mockall = "0.15.0"` to `[dev-dependencies]`, keep an in-memory trait fake for normal service/CLI tests, and add `httpmock = "0.8.3"` only if an HTTP adapter test is implemented; it should not scaffold code, add global interception, or change R01's port contract. [Cargo dev-dependencies reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies) [R01 parameter source, retrieved 2026-09-16](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md)

### Validation strategy

Planned, not executed: P03 runs `cargo test --workspace --locked` on `ubuntu-latest` and `macos-latest` at the declared MSRV and stable. It must prove a hand-written fake and a `mockall` mock both satisfy the service behavior; if the conditional adapter exists, it must prove an `httpmock` server receives the expected method/path/headers, returns a fixture response mapped by the adapter, and turns an unmatched request into the expected error. [Cargo rust-version reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/rust-version.html) [Mockall README, retrieved 2026-09-16](https://github.com/asomers/mockall/blob/master/README.md) [httpmock README, retrieved 2026-09-16](https://github.com/httpmock/httpmock/blob/master/README.md)

### Confidence & re-verify trigger

Medium confidence. Re-verify registry versions, complete resolved-tree MSRV and RustSec checks, run the required two-OS acceptance tests, collect `httpmock`'s ten-issue responsiveness calculation, and revisit the conditional HTTP member if R01/R05 changes the transport or runtime contract. [Mockall versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/mockall/versions) [httpmock versions endpoint, retrieved 2026-09-16](https://crates.io/api/v1/crates/httpmock/versions) [Cargo rust-version reference, retrieved 2026-09-16](https://doc.rust-lang.org/cargo/reference/rust-version.html)

### Sources

Method notes: queried the required crates.io crate, versions, release-dependencies, and reverse-dependencies endpoints; GitHub repository, issue-search, issue-list, comments, and workflow sources; maintainer README/manifest/API documentation; the Rust Book and Cargo reference; and the prompt-specified RustSec package URLs. Every queried RustSec package URL returned HTTP 404, so advisory status is unverified; no dependency tree, Rust code, benchmark, or two-OS test was executed. [crates.io API](https://crates.io/data-access) [GitHub REST API](https://docs.github.com/en/rest) [RustSec mockall endpoint, retrieved 2026-09-16](https://rustsec.org/packages/mockall.html) [RustSec httpmock endpoint, retrieved 2026-09-16](https://rustsec.org/packages/httpmock.html)
