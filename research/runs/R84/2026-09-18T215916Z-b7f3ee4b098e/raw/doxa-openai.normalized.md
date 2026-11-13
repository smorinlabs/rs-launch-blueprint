### Landscape

**Evidence date:** September 18, 2026. All cited web sources were retrieved on that date unless stated otherwise. `N/R` means the prompt-mandated API endpoint could not be rendered by this research environment; I did not silently substitute a different metric source.

**Decision category:** ahead-of-time OpenAPI 3.x → typed Rust HTTP-client code generation, producing a committed crate/module from a committed contract snapshot.

| Bin | Rust landscape |
|---|---|
| **Built-in or first-party toolchain** | The Rust Project has no first-party OpenAPI client generator. Cargo supplies `build.rs`, proc-macro, package, and workspace mechanisms, but not OpenAPI semantics. Importantly, Cargo’s own guidance says checked-in generated source should be produced outside `build.rs` and verified in CI. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) |
| **Established industry standard** | **OpenAPI Generator** is the cross-language standard; its Rust client generator is marked `STABLE` while its help text still says “beta,” defaults to async Reqwest, and supports Hyper/Reqwest variants. **Progenitor** is the established Rust-native specialist, with async clients, streams, static-crate generation, build-script and macro modes. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) |
| **Up-and-comer** | **`openapi-to-rust`**, **`spargen`**, **Satay**, **`openapi_gen`**, **`oas3-gen`**, and Ploidy. They explore ahead-of-time checked-in generation, OpenAPI 3.1, explicit support diagnostics, sans-I/O transport, or improved union handling. ([github.com](https://github.com/gpu-cli/openapi-to-rust)) |

#### Authority used

- **Rust Project publications:** the Cargo Book establishes the authoritative treatment of generated source, `OUT_DIR`, `rust-version`, N-2 policies, and MSRV verification. Rust 1.98.0 was current stable on September 18, 2026, making this template’s N-2 MSRV **1.96**. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html))
- **OpenAPI Initiative specification:** `operationId` must be unique and is expressly intended for tools to identify operations; programming-style names are recommended. ([spec.openapis.org](https://spec.openapis.org/oas/v3.0.3))
- **Maintainer-owned primary sources:** candidate manifests, READMEs, CI workflows, support matrices, and generated examples establish actual behavior rather than marketing summaries. ([github.com](https://github.com/gpu-cli/openapi-to-rust))
- **Production-practice evidence:** Oxide’s Omicron and Buildomat use Progenitor-generated clients from checked-in OpenAPI documents; KPN’s DSH client documents a standalone regeneration workflow and the need to add missing operation IDs. ([github.com](https://github.com/oxidecomputer/omicron))
- **Registry/adoption context:** the official Rust survey shows crates.io is overwhelmingly the normal package source, supporting the mandate to collect registry figures—but downloads remain secondary evidence, never a design selector. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2024-annual-survey/report/annual-survey-2024-report.pdf))

#### Practice evidence

- **Progenitor has the strongest demonstrated Rust production practice.** Omicron checks schemas into source control to expose API changes during review, then derives clients from them; Buildomat likewise generates a client from a repository-managed schema. DSH provides independent, non-Oxide adoption evidence. Oxide is a verified organization whose Rust projects include widely followed infrastructure components. ([github.com](https://github.com/oxidecomputer/omicron))
- **`openapi-to-rust` has narrower but relevant practice evidence.** Its maintainers report internal use against OpenAI, Anthropic, and Cloudflare specifications, maintain a 56-spec supported corpus, and compile-check major real-world specifications. `meteora-api` exposes generated code identifying `openapi-to-rust` as its generator. This proves real use, but not yet mainstream independent adoption. ([github.com](https://github.com/gpu-cli/openapi-to-rust))
- **OpenAPI Generator has the broadest cross-language adoption and maintenance footprint.** Release 7.25.0 was published on August 24, 2026; a CERN presentation described its use and showed roughly 23,000 stars, although the required GitHub API figure could not be collected here. ([github.com](https://github.com/OpenAPITools/openapi-generator/releases))
- **No mainstream, independent adopter evidence was found for Spargen, Satay, or `openapi_gen`.** Satay explicitly describes itself as work in progress; Spargen is only weeks into published releases. ([github.com](https://github.com/zeon256/satay-rs))

#### Mandatory figure-collection limitation

The required crates.io and GitHub API endpoints for downloads, release dates, stars, archived state, open-issue count, and recent-issue responsiveness were attempted but were inaccessible to this research environment. Therefore this answer does **not** fabricate those figures or promote HTML/UI counts to exact API measurements. ([]())

### Principles and implementation

#### Shared requirement and agreement level

The Python precedent and owner direction imply agreement at the **architectural-policy and capability level**, not agreement on one package name or HTTP stack.

| Level | Must agree across py/ts/rs | May vary by ecosystem |
|---|---|---|
| **Standard** | A committed OpenAPI document is the client contract. Operations have unique, curated, stable `operationId` values. | OpenAPI 3.0 versus 3.1 syntax, provided the selected generator supports the committed version. |
| **Architectural policy** | Typed request/response models and HTTP operations are generated, never handwritten; output is reproducible, reviewable, and CI-checked for drift. | Generated package layout, formatting, error representation, and runtime library. |
| **Capability** | Consumers can invoke typed async/sync methods without manually serializing paths, parameters, bodies, or responses. | Python may use HTTPX/Pydantic; TypeScript may use Fetch-oriented output; Rust may use Reqwest. |
| **Ownership policy** | The schema and generator configuration are inputs; generated files are outputs and are not edited. | The exact recipe can be `just`, an `xtask`, or an ecosystem package command. |

Cargo’s first-party guidance strongly favors this architecture for checked-in source: generate outside `build.rs`, then have CI verify that the checked-in file precisely matches regenerated output. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-script-examples.html))

#### Cross-repository interpretation

- **Python:** the supplied `openapi-python-client generate` recipe already realizes the policy. A follow-on should ensure deterministic drift checking if that is not already enforced.
- **TypeScript:** absence is currently justified because F303 says there is no web service or schema. It is **inapplicable capability**, not evidence that hand-written clients are acceptable. If a TS web surface is later added, a TS-native ahead-of-time generator must implement the same policy.
- **Rust:** should add the capability now because the fixed target includes a web service. The Rust package and output layout may differ from Python while preserving the architectural contract.

`BASELINE-REVIEW: F335 — typed clients are generated from the committed OpenAPI contract and never handwritten, at architectural-policy/capability agreement level — replace tool-level DIVERGENT/harmonize:no with conditional commonality: py and rs implement now; ts is inapplicable while F303 has no web service, but must implement the policy if that changes — evidence: Python’s supplied recipe, Cargo’s checked-in-codegen guidance, OpenAPI operationId semantics, and maintained Rust generators. Affected: R84, R71/F312/F332, F303; ledger changes remain a follow-on.`

#### Architectural alternatives

| Architecture | Assessment |
|---|---|
| **Standalone ahead-of-time CLI writing committed source** | **Chosen.** Matches Python, exposes generated changes to review, keeps the generator out of consumer builds, and supports a direct CI `--check`/regenerate-and-diff gate. |
| **`build.rs` + `include!(OUT_DIR)`** | Valid Cargo mechanism, but wrong default here. Generated API changes are hidden in `target/`, every clean build compiles/runs codegen, and Cargo expressly recommends external generation for checked-in source. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) |
| **Proc macro in the consumer crate** | Most opaque option. It places the generator in the compile graph, makes generated output harder to review, and couples normal compilation to codegen behavior. |
| **Hand-rolled generator using `openapiv3`/Typify** | Reject. Those libraries can parse schemas or generate types, but the template would own HTTP-method generation, parameter serialization, status handling, and compatibility behavior—the exact maintenance burden this item is meant to avoid. |
| **Generic OpenAPI Generator CLI** | Viable fallback with exceptional ecosystem breadth, but adds a Java/container toolchain and emits a more generic SDK layout. Its Rust generator’s own documentation is inconsistent between `STABLE` metadata and “beta” help text. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) |

#### Gate-first assessment

| Candidate | License | MSRV | Advisory / unsafe posture | OS evidence | Features/runtime | Cost | Result |
|---|---|---|---|---|---|---|---|
| **`openapi-to-rust`** | MIT: pass. | Manifest and CI declare/test 1.88, below required 1.96. Generated dependency tree still needs the template’s 1.96 test. | RustSec endpoint not retrievable; generator does not establish a repository-wide unsafe policy in reviewed evidence. Generated crate can enforce `#![forbid(unsafe_code)]`. | Upstream CI reviewed here is Ubuntu-only; macOS must be proven by R84 acceptance. | Generator default is `cli`; emitted client is async Reqwest, therefore native use is Tokio-coupled. | Generator is dev-only; runtime cost is primarily Reqwest/TLS/Serde. | **Conditional acceptance candidate.** ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml)) |
| **Progenitor** | MPL-2.0. Fails if the gate means the candidate itself must be MIT or Apache; otherwise needs explicit legal-policy confirmation. | Workspace declares 1.88. | RustSec result and explicit unsafe policy not verified here. | Production portability is strong, but upstream Ubuntu/macOS generator CI evidence was not established. | Default feature enables its macro; generated clients use async Reqwest, futures, and streams. | AOT mode is acceptable; macro/build modes add substantial compile-time dependencies. | **Runner-up, conditional on OAS 3.0 and license policy.** ([github.com](https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml)) |
| **OpenAPI Generator 7.25** | Apache-2.0: pass. | No reviewed evidence that default Rust output declares and tests this template’s `rust-version` policy. | Adds a non-Rust Java/container supply-chain boundary. | Broadly portable as a CLI. | Async Reqwest is default; Hyper and trait variants exist. | Largest generator/tooling footprint and more boilerplate. | Excluded from this crate-valued item. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) |
| **`openapi_gen` 0.3.1** | Not sufficiently established in reviewed evidence. | Not sufficiently established. | Not sufficiently established. | No required matrix evidence found. | Proc-macro-only interface in reviewed docs. | Adds generation directly to compilation. | Excluded. ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html)) |
| **Hand-rolled `openapiv3`/Typify** | Component licenses may pass. | Component-dependent. | Template would own security-sensitive serialization and response handling. | Template-owned. | No complete client generation. | Highest long-term ownership cost. | Excluded by capability/policy. |

#### Recommended composition

1. R71 produces and commits the OpenAPI document.
2. A preflight rejects any missing or duplicate operation IDs.
3. A pinned standalone generator reads only that local document.
4. Generated files are committed under a dedicated client crate.
5. The crate root adds policy attributes and re-exports generated items, but does not wrap each operation.
6. CLI/library consumers import generated `HttpClient`, request models, response models, and typed errors directly.
7. CI regenerates in check mode and compiles/tests the client on Ubuntu, macOS, stable, and Rust 1.96.

This keeps R84 independent of whichever framework R69 selects and whichever schema-generation mechanism R71 selects.

#### Idiomatic-use assessment

`openapi-to-rust` generates an async `HttpClient`, typed structs/enums, builders for larger parameter sets, per-operation typed errors, bounded response buffering, and exact dependency fragments. Its normal generated API is directly consumable; a wrapper is not necessary merely to make it usable. An optional application-level factory for base URL, auth, and tracing is reasonable, but wrapping every operation would recreate a handwritten client and should be rejected. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

Illustrative usage—the actual symbols must derive from R71’s operation IDs:

```rust
use rs_launch_blueprint_api_client::{HealthResponse, HttpClient};

async fn check(base_url: &str) -> anyhow::Result<HealthResponse> {
    let client = HttpClient::new().with_base_url(base_url);
    Ok(client.health_check().await?)
}
```

#### Operation-ID dependency

The template should make curated operation IDs a hard precondition, not rely on any generator’s fallback naming. OpenAPI defines them as unique tool-facing identifiers; DSH’s Progenitor workflow had to patch a schema that omitted them. Without curation, method names may be rejected or derived from paths/methods in tool-specific ways, producing noisy or unstable public APIs. ([spec.openapis.org](https://spec.openapis.org/oas/v3.0.3))

#### Performance evidence

The `openapi-to-rust` maintainers report one 120-operation comparison with a 26.5% lower median clean `cargo check` time than Progenitor and effectively identical no-op builds. The retrieved material did not expose enough machine, compiler, repetition, or variance details to treat that as an absolute ranking, and it is maintainer-controlled evidence. It is therefore **not** a selection reason. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

No comparable runtime latency/throughput study was found. The acceptance benchmark should use the actual R71 schema and record:

- generator wall time and peak RSS;
- clean and no-op `cargo check` wall time;
- release binary size;
- 10,000 loopback JSON requests at concurrency 1 and 32;
- p50/p95/p99 latency, requests/second, CPU, and peak RSS;
- identical Reqwest/TLS features for every compared generator.

### Dominant choice

**`openapi-to-rust`, version range `>=0.17.0, <0.18.0`, used only as a standalone ahead-of-time generator.**

This is the fit-dominant choice because it supports OpenAPI 3.0 and 3.1, emits a typed async Reqwest client, has native `--check` behavior for committed output, declares an MSRV below the template’s current 1.96 requirement, and uses an MIT license. The repository manifest currently says 0.17.0, but the crates.io unyanked-release endpoint must be rechecked before merge. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Qualified shortlist

**Strict result: zero candidates are fully evidence-complete today.** This is a finding, not a silent waiver: the dominant candidate lacks upstream macOS CI in the reviewed workflow, and the required RustSec/registry/API checks could not be completed.

**Post-R71 acceptance candidate—not yet counted as fully gate-passed:**

| Name · role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | One-line trade-off |
|---|---:|---:|---:|---|---|---|---|
| `openapi-to-rust` · AOT OpenAPI 3.0/3.1 → typed Reqwest client module | **N/R** via required crates.io endpoint | **N/R** via required crates.io endpoint | **N/R** via required GitHub API; HTML corroboration: 36 | **N/R** via required versions endpoint; current repository manifest: 0.17.0 | **active** — current CI, corpus generation, MSRV job, rapid development | Maintainer-reported GPU CLI usage; `meteora-api` generated by v0.12.2 | Best architectural and schema-version fit, but young, rapidly evolving, and not yet independently mainstream. ([github.com](https://github.com/gpu-cli/openapi-to-rust)) |

**Issue responsiveness:** N/R. The required ten-recent-issues query and comment traversal could not be fetched; the GitHub HTML page showed three issues but that is not substituted for the mandated API calculation. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Excluded by gate

- **`openapi-to-rust`—excluded from unconditional adoption, not from the acceptance trial.** Gate 3 remains incomplete because the RustSec package endpoint did not render; Gate 4 remains incomplete because reviewed upstream CI had no `macos-latest` job. Both are mandatory post-R71 checks. ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml))
- **Progenitor 0.15.** Its MPL-2.0 license fails a strict “candidate itself must be MIT or Apache” interpretation, and it only supports OpenAPI 3.0.x. Selecting it now would impose a schema-version constraint on still-open R71. Its production maturity makes it the runner-up rather than a discarded option. ([docs.rs](https://docs.rs/progenitor/latest/progenitor/))
- **OpenAPI Generator 7.25.** Not a Rust crate; default Rust output was not shown to declare and test this template’s MSRV policy. It also adds a Java/container tool boundary and more generic boilerplate. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md))
- **`openapi_gen` 0.3.1.** The reviewed interface is a proc macro rather than an ahead-of-time checkable recipe, and required license/MSRV/macOS evidence was insufficient. ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html))
- **Paperclip.** Its own project description frames complete client/server/CLI code generation as a future capability and warns that it may not be production-ready. ([lib.rs](https://lib.rs/crates/paperclip))
- **`openapiv3`, Typify, or another parser/type generator plus handwritten transport.** Fails the essential capability: paths, parameters, auth, body encoding, response decoding, and typed errors would still be template-owned.
- **A `build.rs` or macro deployment of an otherwise acceptable generator.** Fails the chosen architectural policy for committed, reviewable output; Cargo recommends an external generation/check workflow for this exact case. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-script-examples.html))

### Up-and-comers

- **Spargen 0.4.0:** strongest explicit determinism/support-policy story. It recommends checked-in CLI generation, embeds a freestanding runtime, rejects unsupported constructs rather than silently degrading them, and provides `--check` and generated-surface diffing. It is extremely new and targets OpenAPI 3.1+, so adopter, license, MSRV, and OS evidence must mature before it can displace the dominant candidate. ([docs.rs](https://docs.rs/crate/spargen/latest/source/README.md))
- **Satay:** promising sans-I/O architecture with optional Reqwest and Ureq adapters, validation newtypes, and MIT/Apache licensing. It explicitly says it is work in progress and currently optimizes for one client family. ([github.com](https://github.com/zeon256/satay-rs))
- **`oas3-gen` 0.23:** generates OpenAPI 3.1 models and companion client operations with filtering, but the reviewed evidence did not establish comparable end-to-end transport ergonomics, adoption, or target-matrix testing. ([docs.rs](https://docs.rs/crate/oas3-gen-support/0.23.0))
- **Ploidy:** potentially valuable for complex polymorphic schemas and reports 3.0/3.1 use, but evidence was an announcement rather than a sufficiently mature authoritative implementation record. ([reddit.com](https://www.reddit.com/r/rust/comments/1qtgbb1/ploidy_an_openapi_generator_for_polymorphic_specs/))
- **`openapi_gen` 0.3.1:** useful proof that compile-time client generation is possible, but its proc-macro architecture conflicts with this template’s committed-output policy. ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html))

### Fit for this template

**CLI**

- Good fit if the CLI calls the service: async Reqwest methods and typed errors are directly usable from a Tokio-based command path.
- The CLI should depend on `rs-launch-blueprint-api-client`, not on the generator.
- If the CLI is purely local, do not add an artificial runtime dependency merely to demonstrate the client; use the generated crate in integration tests and examples instead.

**Library**

- Keep the generated client in a separate workspace crate so schema-generated types do not accidentally become the core library’s entire semver surface.
- The library may expose an opt-in `api-client` feature or tell callers to depend directly on the client crate.
- Do not hand-wrap every operation. A small client factory or extension trait for application policy is acceptable; wire models and HTTP calls remain generated.

**Web**

- The web-service crate must not depend on the generated client in its normal dependency graph; that would create needless producer/consumer coupling.
- It may use the client as a dev-dependency for end-to-end tests.
- R84 always reads the committed R71 snapshot, never fetches a live development server during generation.
- Do not enable `openapi-to-rust`’s optional Axum server generation; R69 owns the web framework.

### Recommendation

**Decision: yes, a Rust-ecosystem equivalent exists.**

Adopt:

```toml
# Decision range
openapi-to-rust = ">=0.17.0, <0.18.0"
```

Use an **exact 0.17.0 tool pin** in the recipe, with the range documenting the approved compatibility line. Do not put the generator in any runtime dependency table.

Proposed `Justfile` recipe:

```make
OPENAPI_TO_RUST_VERSION := "0.17.0"
OPENAPI_TO_RUST_ROOT := "target/tools/openapi-to-rust-{{OPENAPI_TO_RUST_VERSION}}"
OPENAPI_TO_RUST := "{{OPENAPI_TO_RUST_ROOT}}/bin/openapi-to-rust"

openapi-client-tool:
    cargo install --locked \
        --root "{{OPENAPI_TO_RUST_ROOT}}" \
        --version "{{OPENAPI_TO_RUST_VERSION}}" \
        openapi-to-rust

openapi-client-generate: openapi-client-tool
    "{{OPENAPI_TO_RUST}}" validate --config openapi-to-rust.toml
    "{{OPENAPI_TO_RUST}}" generate --config openapi-to-rust.toml

openapi-client-check: openapi-client-tool
    "{{OPENAPI_TO_RUST}}" validate --config openapi-to-rust.toml
    "{{OPENAPI_TO_RUST}}" generate --config openapi-to-rust.toml --check
    cargo check -p rs-launch-blueprint-api-client --all-targets
```

Proposed configuration:

```toml
# openapi-to-rust.toml

[generator]
spec_path = "docs/api/openapi.json"
output_dir = "crates/api-client/src/generated"
module_name = "api"

[features]
enable_async_client = true
enable_sse_client = false
enable_registry = false
```

Omitting `[client].operations` generates the full client rather than an application-selected subset. That better matches a reusable template and makes the complete committed schema consumable. The tool writes an exact `REQUIRED_DEPS.toml`; CI must verify those requirements are reflected in the generated client crate’s manifest. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Ranked runner-up

**Progenitor 0.15 line: `>=0.15.0, <0.16.0`.**

It wins if all of the following become true:

1. R71 guarantees an OpenAPI 3.0.x snapshot;
2. the actual snapshot passes a Progenitor support trial without lossy patches;
3. dependency-license policy explicitly accepts MPL-2.0 without changing the template’s own `MIT OR Apache-2.0` license;
4. production maturity, pagination streams, generated CLI support, and typed mocks are valued more highly than native OpenAPI 3.1 support and built-in drift checking.

If selected, use `cargo-progenitor` only in static-crate mode, generate into a temporary directory, and diff/copy the output. Do not use its macro or `build.rs` modes. Progenitor documents static-crate generation specifically as a way to prevent unexpected changes from generator updates. ([github.com](https://github.com/oxidecomputer/progenitor))

### Tradeoffs

| Versus | What the dominant pick gives up | Why accepted |
|---|---|---|
| **Progenitor** | Much stronger production adoption; typed mocks; pagination streams; generated CLI; approximately thousand-star project footprint. | Progenitor is OpenAPI 3.0-only, Dropshot-oriented, MPL-licensed, and lacks the same direct AOT `--check` fit. |
| **OpenAPI Generator** | Far larger community, language breadth, templates, plugins, and organizational familiarity. | Adds Java/container tooling, produces more generic boilerplate, and does not naturally deliver the crate-valued, Rust-native, MSRV-enforced result. |
| **Spargen** | Stronger explicit guarantees around deterministic output, unsupported-schema diagnostics, and avoidance of silent `serde_json::Value` degradation. | It is extremely new, OpenAPI 3.1+-focused, and lacks sufficient adoption and gate evidence. |
| **Satay** | Transport independence and potential support for Reqwest, Ureq, blocking, async, WebSocket, and WASM from one generated action model. | The template benefits more from a direct async Reqwest drop-in than from owning an adapter layer around a self-described work-in-progress generator. |
| **Handwritten wrapper/client** | Maximum hand-tuned ergonomics. | Violates the principal requirement and creates permanent schema/client drift risk. |

The main accepted risk is maturity: `openapi-to-rust` explicitly says pre-1.0 minor releases may change generated Rust APIs. Exact tool pinning, committed output, compiler-checked consumers, and minor-line re-evaluation contain that risk. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Parameters

`owns none`

`assumes R69:web-extra-surface = enabled web service, with no framework assumption`

`assumes R71:committed-openapi-snapshot = a repository-local JSON or YAML OpenAPI document; illustrative path docs/api/openapi.json`

`assumes R71:openapi-document-version = OpenAPI 3.0.x or 3.1.x; 3.2 support is experimental and triggers re-evaluation`

`assumes F312:operation-ids = unique, non-empty, curated and stable`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, currently rust-version 1.96, raised only in a minor release and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

### Migration implications

| File/path | Proposed change |
|---|---|
| `/Cargo.toml` | Add `crates/api-client` to workspace members; centralize compatible generated-runtime dependencies if the template uses workspace dependencies. |
| `/crates/api-client/Cargo.toml` | New package `rs-launch-blueprint-api-client`; `edition = "2024"`, `rust-version = "1.96"`, `license = "MIT OR Apache-2.0"`; dependencies synchronized with generated `REQUIRED_DEPS.toml`. |
| `/crates/api-client/src/lib.rs` | Add `#![forbid(unsafe_code)]`, `pub mod generated;`, and deliberate re-exports only. No handwritten HTTP methods or duplicate wire models. |
| `/crates/api-client/src/generated/` | Commit generated `types.rs`, `client.rs`, `mod.rs`, optional streaming files, and `REQUIRED_DEPS.toml`. Add a generated-file header where supported. |
| `/openapi-to-rust.toml` | Add local snapshot and output configuration; do not configure server generation. |
| `/Justfile` | Add pinned tool-install, generate, and check recipes. |
| `/xtask/` or `/tools/` | Add operation-ID validation and a check that `REQUIRED_DEPS.toml` matches `crates/api-client/Cargo.toml`. This is codegen plumbing, not handwritten client code. |
| `/crates/cli/Cargo.toml` | Depend on the client crate only if CLI commands call the service. |
| `/crates/library/Cargo.toml` | Optional dependency or no dependency; avoid unintentional re-export of every generated type. |
| `/crates/web/Cargo.toml` | Add the client only as a dev-dependency for integration tests. |
| `/.github/workflows/ci.yml` | Add generate/check and client compile/test jobs on Ubuntu and macOS, stable and 1.96. |
| `/.gitignore` | Ignore `target/tools/`; explicitly do not ignore generated client source. |
| `/docs/port/COMMONALITY.md` | Follow-on ledger update reflecting F335’s architectural-policy commonality. |
| `/docs/architecture/openapi-client.md` | Document ownership: R71 snapshot is input, R84 output is generated, editing generated files is forbidden. |

### Validation strategy

**Executed during this research:** source and documentation inspection only. No repository checkout, code generation, compilation, audit, benchmark, or runtime smoke test was executed.

**Mandatory planned acceptance—after R71 supplies the real snapshot:**

1. **Verify the selected release exists and is unyanked.**

   ```bash
   cargo info openapi-to-rust@0.17.0
   ```

   Expected: package information resolves for 0.17.0. Failure blocks adoption rather than silently choosing another minor line.

2. **Reject absent or duplicate operation IDs before codegen.**

   ```bash
   jq -e '
     [.paths
      | to_entries[]
      | .value
      | to_entries[]
      | select(.key | IN(
          "get", "put", "post", "delete",
          "options", "head", "patch", "trace"
        ))
      | .value.operationId] as $ids
     | ($ids | all(type == "string" and length > 0))
       and (($ids | length) == ($ids | unique | length))
   ' docs/api/openapi.json
   ```

   Expected: exit 0. Any missing or duplicate identifier fails before generated method names can drift.

3. **Generate from a clean checkout.**

   ```bash
   rm -rf crates/api-client/src/generated
   just openapi-client-generate
   cargo check -p rs-launch-blueprint-api-client --all-targets
   ```

   Expected: complete typed source is regenerated without manual intervention and compiles.

4. **Prove deterministic committed output.**

   ```bash
   git diff --exit-code
   just openapi-client-generate
   git diff --exit-code -- crates/api-client/src/generated
   just openapi-client-check
   ```

   Expected: both diffs are empty. Editing any generated file manually must cause `openapi-client-check` to fail.

5. **Prove the generator is absent from runtime dependencies.**

   ```bash
   cargo tree -p rs-launch-blueprint-api-client -e normal
   ```

   Expected: neither `openapi-to-rust` nor another codegen crate appears in the normal dependency graph.

6. **Prove the MSRV policy.**

   ```bash
   cargo +1.96.0 check --workspace --all-targets
   cargo +1.96.0 test -p rs-launch-blueprint-api-client
   cargo +stable check --workspace --all-targets
   ```

   Expected: all succeed. The generated dependency tree, not just the generator itself, must work on 1.96.

7. **Prove OS support.**

   Run generation, check, and the generated-client tests in this matrix:

   ```yaml
   os: [ubuntu-latest, macos-latest]
   rust: [stable, "1.96.0"]
   ```

   Expected: byte-stable generation and successful client compilation on both operating systems. Windows is informative but not required.

8. **Prove typed runtime behavior.**

   ```bash
   cargo test \
     -p rs-launch-blueprint-api-client \
     --test generated_client_smoke \
     -- --nocapture
   ```

   The test should start the real web router/service on `127.0.0.1:0`, call at least:
   - one bodyless GET;
   - one operation with path or query parameters;
   - one JSON request/response;
   - one documented non-2xx typed response.

   Expected: consumer code uses generated request/response/error types and no `serde_json::Value` escape hatch for those operations.

9. **Prove advisory and unsafe posture.**

   ```bash
   cargo audit --deny warnings
   cargo geiger -p rs-launch-blueprint-api-client
   ```

   Expected: no open RustSec advisory. First-party client source compiles under `#![forbid(unsafe_code)]`; transitive unsafe is reported and reviewed rather than misrepresented as absent.

10. **Characterize—not gate on—performance.**

    ```bash
    /usr/bin/time -v just openapi-client-generate
    /usr/bin/time -v cargo check -p rs-launch-blueprint-api-client
    cargo build --release -p rs-launch-blueprint-cli
    cargo bloat --release -p rs-launch-blueprint-cli -n 20
    ```

    On macOS, use `/usr/bin/time -l`. Record generator/compile wall time, peak RSS, release binary size, and the loopback latency/throughput workload described above. Compare with Progenitor only if the same schema can be represented without changing its semantics.

### Confidence & re-verify trigger

**Confidence: moderate.**

The architectural decision—standalone generation from the committed snapshot, committed output, stable operation IDs, and CI drift checking—is high confidence because it follows the Python precedent, normative OpenAPI semantics, and Cargo’s first-party guidance.

The specific crate decision is only moderate confidence because:

- `openapi-to-rust` is young and explicitly allows generated-API changes between pre-1.0 minor releases;
- independent mainstream adopter evidence is limited;
- upstream macOS testing was not found;
- mandated crates.io/GitHub/RustSec endpoint checks could not be completed;
- the repository manifest’s 0.17.0 must still be confirmed as an unyanked published release.

**Re-verify immediately if:**

- R71 selects OpenAPI 3.2 or emits constructs the tool marks experimental/unsupported;
- 0.18.0 or 1.0.0 is released;
- generation produces untyped `serde_json::Value` for a contractually typed operation;
- the generated client requires a method-by-method handwritten wrapper;
- macOS or Rust 1.96 acceptance fails;
- a RustSec advisory opens;
- the project goes six months without a release and shows another concrete maintenance-risk signal;
- Progenitor adds OpenAPI 3.1 support or changes to an accepted permissive license;
- Spargen establishes independent production adopters and complete gate evidence.

### Sources

| Source | Why authoritative | URL | Retrieved |
|---|---|---|---|
| Cargo build-script examples | Rust Project first-party guidance explicitly addresses checked-in generated source | `https://doc.rust-lang.org/cargo/reference/build-script-examples.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-script-examples.html)) | 2026-09-18 |
| Cargo build scripts | Rust Project definition of `OUT_DIR` and build-script lifecycle | `https://doc.rust-lang.org/cargo/reference/build-scripts.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) | 2026-09-18 |
| Cargo Rust version | Rust Project MSRV/N-2 policy guidance | `https://doc.rust-lang.org/cargo/reference/rust-version.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html)) | 2026-09-18 |
| Rust 1.98 release | Establishes current stable for N-2 arithmetic | `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)) | 2026-09-18 |
| OpenAPI 3.0.3 specification | Normative `operationId` semantics | `https://spec.openapis.org/oas/v3.0.3` ([spec.openapis.org](https://spec.openapis.org/oas/v3.0.3)) | 2026-09-18 |
| `openapi-to-rust` README | Maintainer-owned behavior, generated surface, corpus, CLI, versioning and examples | `https://github.com/gpu-cli/openapi-to-rust` ([github.com](https://github.com/gpu-cli/openapi-to-rust)) | 2026-09-18 |
| `openapi-to-rust` manifest | Current repository version, edition, MSRV, license, dependencies and features | `https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml` ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml)) | 2026-09-18 |
| `openapi-to-rust` CI | Upstream test, MSRV and OS evidence | `https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml` ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml)) | 2026-09-18 |
| `meteora-api` generated module | Independent generated-output adoption evidence | `https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html` ([docs.rs](https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html)) | 2026-09-18 |
| Progenitor README/repository | Maintainer-owned usage modes and static-crate behavior | `https://github.com/oxidecomputer/progenitor` ([github.com](https://github.com/oxidecomputer/progenitor)) | 2026-09-18 |
| Progenitor workspace manifest | MSRV, edition, license and dependency versions | `https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml` ([github.com](https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml)) | 2026-09-18 |
| Omicron | Production checked-in-schema and generated-client practice | `https://github.com/oxidecomputer/omicron` ([github.com](https://github.com/oxidecomputer/omicron)) | 2026-09-18 |
| Buildomat | Maintained Progenitor client implementation | `https://github.com/oxidecomputer/buildomat` ([github.com](https://github.com/oxidecomputer/buildomat)) | 2026-09-18 |
| DSH generated-client upgrade guide | Independent Progenitor adoption and operation-ID dependency | `https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md` ([docs.rs](https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md)) | 2026-09-18 |
| OpenAPI Generator Rust docs | Primary Rust-generator configuration and stability metadata | `https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md` ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) | 2026-09-18 |
| OpenAPI Generator releases | Current release and maintenance evidence | `https://github.com/OpenAPITools/openapi-generator/releases` ([github.com](https://github.com/OpenAPITools/openapi-generator/releases)) | 2026-09-18 |
| Spargen README/docs | Maintainer-owned AOT/build/macro architecture and determinism guarantees | `https://docs.rs/crate/spargen/latest/source/README.md` ([docs.rs](https://docs.rs/crate/spargen/latest/source/README.md)) | 2026-09-18 |
| Satay repository | Maintainer-owned sans-I/O architecture, support status and license | `https://github.com/zeon256/satay-rs` ([github.com](https://github.com/zeon256/satay-rs)) | 2026-09-18 |
| `openapi_gen` docs | Primary proc-macro behavior | `https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html` ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html)) | 2026-09-18 |
| `oas3-gen` docs | Primary model/client-generation behavior | `https://docs.rs/crate/oas3-gen-support/0.23.0` ([docs.rs](https://docs.rs/crate/oas3-gen-support/0.23.0)) | 2026-09-18 |
| Paperclip project description | Primary readiness and planned-capability statement | `https://lib.rs/crates/paperclip` ([lib.rs](https://lib.rs/crates/paperclip)) | 2026-09-18 |

**Mandated figure endpoints to rerun before merge:**

| Figure | Required endpoint |
|---|---|
| `openapi-to-rust` downloads | `GET https://crates.io/api/v1/crates/openapi-to-rust` |
| `openapi-to-rust` last unyanked release | `GET https://crates.io/api/v1/crates/openapi-to-rust/versions` |
| Repository stars/archive/push | `GET https://api.github.com/repos/gpu-cli/openapi-to-rust` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:gpu-cli/openapi-to-rust+is:issue+is:open` |
| Ten newest issues | `GET https://api.github.com/search/issues?q=repo:gpu-cli/openapi-to-rust+is:issue&sort=created&order=desc&per_page=10` |
| Advisories | `https://rustsec.org/packages/openapi-to-rust.html` |

The same endpoint pattern must be rerun for `progenitor`, `cargo-progenitor`, `progenitor-client`, `spargen`, and any newly promoted candidate.

## Sources

- [https://doc.rust-lang.org/cargo/reference/build-scripts.html](https://doc.rust-lang.org/cargo/reference/build-scripts.html)
- [https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)
- [https://github.com/gpu-cli/openapi-to-rust](https://github.com/gpu-cli/openapi-to-rust)
- [https://doc.rust-lang.org/cargo/reference/rust-version.html](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [https://spec.openapis.org/oas/v3.0.3](https://spec.openapis.org/oas/v3.0.3)
- [https://github.com/oxidecomputer/omicron](https://github.com/oxidecomputer/omicron)
- [https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2024-annual-survey/report/annual-survey-2024-report.pdf](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2024-annual-survey/report/annual-survey-2024-report.pdf)
- [https://github.com/OpenAPITools/openapi-generator/releases](https://github.com/OpenAPITools/openapi-generator/releases)
- [https://github.com/zeon256/satay-rs](https://github.com/zeon256/satay-rs)
- [https://doc.rust-lang.org/cargo/reference/build-script-examples.html](https://doc.rust-lang.org/cargo/reference/build-script-examples.html)
- [https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml](https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml)
- [https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml](https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml)
- [https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html)
- [https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml](https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml)
- [https://docs.rs/progenitor/latest/progenitor/](https://docs.rs/progenitor/latest/progenitor/)
- [https://lib.rs/crates/paperclip](https://lib.rs/crates/paperclip)
- [https://docs.rs/crate/spargen/latest/source/README.md](https://docs.rs/crate/spargen/latest/source/README.md)
- [https://docs.rs/crate/oas3-gen-support/0.23.0](https://docs.rs/crate/oas3-gen-support/0.23.0)
- [https://www.reddit.com/r/rust/comments/1qtgbb1/ploidy_an_openapi_generator_for_polymorphic_specs/](https://www.reddit.com/r/rust/comments/1qtgbb1/ploidy_an_openapi_generator_for_polymorphic_specs/)
- [https://github.com/oxidecomputer/progenitor](https://github.com/oxidecomputer/progenitor)
- [https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)
- [https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html](https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html)
- [https://github.com/oxidecomputer/buildomat](https://github.com/oxidecomputer/buildomat)
- [https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md](https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md)
