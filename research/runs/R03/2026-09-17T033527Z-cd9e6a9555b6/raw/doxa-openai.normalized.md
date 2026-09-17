### Landscape

**Research and retrieval date:** September 17, 2026. Every citation below is a source URL retrieved on that date unless a separate publication date is stated. Normative **MUST/SHOULD** language is the recommendation rather than a claim copied from a source.

**Category decided:** the semantic return contract of a fallible, single-resource lookup at a driven-I/O boundary, plus the architectural location where successful absence becomes an application/domain-facing not-found error.

| Bin | Candidates found | Assessment |
|---|---|---|
| **Built-in or first-party toolchain** | `Result<Option<T>, E>`; `Result<T, E>` with a not-found variant; `Option<Result<T, E>>`; explicit `Option::ok_or_else`; `?`/`From` propagation | Rust already has all required machinery. `Path::try_exists` is especially close precedent: it distinguishes a confirmed negative answer from inability to determine the answer. `Option::ok_or_else` is the standard explicit absence-to-error conversion, while `Option::transpose` converts the less-natural `Option<Result<…>>` ordering into `Result<Option<…>>`. Rust's error-handling project recommends concrete enums when callers must handle multiple cases and reporting types only after handling is no longer expected. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.PathBuf.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E&utm_source=openai)) |
| **Established industry standard** | Fallible optional lookups in SQLx, Diesel, kube, SeaORM, rust-postgres and RocksDB-style APIs; call-site `ok_or`/`ok_or_else` conversion | SQLx `fetch_optional` returns `Result<Option<Row>, Error>`; Diesel's `optional` converts only its `NotFound` condition to `Ok(None)`; kube exposes `get_opt`; SeaORM exposes both optional `one` and required `require_one`. These span databases and remote HTTP APIs rather than one library family. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)) |
| **Up-and-comer / refinement** | Paired optional/required entry points; richer `LookupOutcome<T>` enums when absence needs metadata | SeaORM's paired `one`/`require_one` interface is a useful newer refinement: one primitive preserves optionality while the other applies requiredness. A custom `Found`/`Missing` outcome enum is viable when “missing” later needs metadata, but the survey found no maintained Rust authority showing it as preferable for a binary present/absent lookup. ([docs.rs](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html)) |

**Authority weighting**

- Rust standard-library documentation, the Rust Reference and accepted RFCs are first-party sources for type and `?` semantics. RFC 2965 is particularly relevant because it distinguishes handleable concrete error types from later-stage reporting types. ([doc.rust-lang.org](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai))
- Alistair Cockburn's original Ports and Adapters article is the primary architectural source. It places technology conversion in adapters and use-case policy at the application boundary. ([alistair.cockburn.us](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai))
- SQLx, Diesel, kube and SeaORM documentation is maintained by the implementers and supplies executable API precedent rather than opinion.
- Tokio's maintained axum examples provide framework-level practice evidence: one converts an optional in-memory lookup to `NOT_FOUND` at the call site, while another demonstrates SQLx integration. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))
- The 2025 State of Rust survey reports that official documentation and studying source code remain preferred canonical learning references; that supports weighting current maintainer docs and code above isolated blog posts. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai))
- The source repositories remain direct evidence of the intended cross-repository architecture: Python explicitly documents “`None` means absent; exception means failed,” while TypeScript currently combines lookup and policy in `getProjects`. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/ports.py))

**Practice evidence**

| Reference | Observed practice | Why it is relevant |
|---|---|---|
| SQLx | `fetch_optional` returns `Result<Option<Row>, Error>`; `fetch_one` instead reports row-not-found as an error. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)) | One mainstream library deliberately offers both cardinality contracts. |
| Diesel | `OptionalExtension::optional` maps only `Error::NotFound` to `Ok(None)` and leaves other errors in `Err`; its changelog describes `Result<Option<T>>` as the more idiomatic representation when zero or one rows are expected. ([docs.rs](https://docs.rs/diesel/latest/src/diesel/result.rs.html?utm_source=openai)) | Direct evidence for normalizing technology-level no-row into successful absence without swallowing failures. |
| kube | `get_opt` returns `Result<Option<K>, Error>`, whereas `get` requires existence. ([docs.rs](https://docs.rs/kube/latest/kube/struct.Api.html)) | Remote HTTP-backed lookup, closer to this template than database-only evidence. |
| SeaORM | `one` returns `Result<Option<Model>, DbErr>` and `require_one` returns `Result<Model, DbErr>` with record-not-found as an error. ([docs.rs](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html)) | Demonstrates the optional-primitive/required-wrapper split in one API. |
| axum | Its maintained todos example performs an optional lookup and applies `.ok_or(StatusCode::NOT_FOUND)?` at the HTTP call site. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)) | Shows the ergonomics of explicit absence translation, though a full hexagonal application should translate first to an application error rather than directly to HTTP status. |
| Block's Buzz | A company-hosted Rust component exposes `Result<Option<…>, StoreError>` and later requires a value with `ok_or_else`. ([github.com](https://github.com/block/buzz/blob/main/crates/buzz-relay/src/api/git/store.rs?utm_source=openai)) | Independent production-practice corroboration outside the ORM/framework maintainers. |

**Evidence-protocol applicability**

This is a `pattern` item and the recommendation selects no external crate. Therefore 90-day downloads, all-time downloads, crate release date, stars, archive state, open-issue count, issue responsiveness and package-specific RustSec advisories are **inapplicable**. Reporting such figures for SQLx or kube would measure evidence examples, not competing dependencies. Adopter/source evidence remains applicable and is listed above, matching the governing specification's separate treatment of pattern items. ([raw.githubusercontent.com](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md))

**Fitness gates before popularity**

As of September 17, 2026, stable Rust is 1.98.0, released August 20, 2026; the fixed stable-minus-two floor is therefore Rust 1.96.0. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))

| Pattern candidate | License | MSRV | RustSec / `unsafe` | Ubuntu + macOS | Features/runtime | Compile/binary cost |
|---|---|---|---|---|---|---|
| `Result<Option<T>, E>` plus call-site conversion | Pass: no dependency | Pass: required APIs substantially predate 1.96 | No package advisory applies; no user `unsafe` required | Pass; target-neutral, with Windows also expected to work but not CI-required | None; sync/async-neutral | Lowest: standard types only |
| `Result<T, E::NotFound>` | Pass | Pass | Same | Pass | None | Same |
| `Result<T, DomainError>` from adapter | Pass | Pass | Same | Pass | None | Same |
| `Result<LookupOutcome<T>, E>` | Pass | Pass | Same | Pass | None | Small source/API expansion |
| `Option<Result<T, E>>` | Pass | Pass | Same | Pass | None | Same representation family; worse API ordering |

All shortlisted patterns pass the six ecosystem gates. Architectural fitness, not popularity, separates them.

### Principles and implementation

**Shared requirement and agreement level**

The owner explicitly requested a similar hexagonal best-practice pattern across Python, TypeScript and Rust. The required agreement level is therefore an **architectural pattern**, not an identical language-level type:

1. The driven adapter reports whether it successfully answered the lookup.
2. A successful answer may be present or absent.
3. The use case—not the transport adapter—decides whether absence violates that operation's contract.
4. Driving adapters map the resulting application error to CLI exit or HTTP response policy.
5. Transport/protocol causes remain distinguishable from not-found throughout the path.

This matches Cockburn's division between technology-specific adapters and application-boundary use cases, and the repository's owner review identifies R03 as a shared hex pattern. ([alistair.cockburn.us](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai))

The central Rust model is not “expected things use `Option`, unexpected things use `Result`” in isolation. It is **two independent axes**:

- Did the lookup complete? `Result<_, E>`
- If it completed, was a value present? `Option<T>`

That yields:

| State | Meaning |
|---|---|
| `Ok(Some(value))` | Lookup completed; resource exists. |
| `Ok(None)` | Lookup completed; resource does not exist. |
| `Err(error)` | Lookup did not produce a trustworthy answer. |

`Path::try_exists`, SQLx, Diesel and kube all embody this distinction in closely related forms. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.PathBuf.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E&utm_source=openai))

**What must agree and what may vary**

| Ecosystem | Idiomatic mechanism | Assessment |
|---|---|---|
| Python | Port returns `T | None`; transport failure raises a typed exception; application service converts `None` to `ProjectNotFoundError`. | Already conforms. Python has a separate exception channel, so a bare optional return annotation does not lose failure information. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/ports.py)) |
| TypeScript | Target: lookup returns `Promise<T \| undefined>` and rejects with a transport/API error; application service converts `undefined` to `NotFoundError`. A local discriminated `Result` would also preserve the pattern if the TS project later standardizes one. | Current `getProjects` resolves a workspace and throws `NotFoundError` inline, so the architectural split is missing. This is accidental coupling rather than a justified TypeScript difference: no dedicated TS decision selected it. `strictNullChecks` supports explicit handling of `undefined`, while `fetch` still requires the adapter to inspect HTTP status rather than treating all resolved promises as success. ([github.com](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts)) |
| Rust | Port returns `Result<Option<T>, E>`; use case maps `Err(E)` to its source-failure category and `None` to its not-found category. | Idiomatic and more statically explicit than either exception-based implementation. ([doc.rust-lang.org](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai)) |

**Architectural alternatives**

1. **`Result<Option<T>, PortError>` plus use-case conversion — chosen.**  
   It preserves the reusable question “is it there?” independently of “must it be there for this use case?” It also prevents a transport adapter from importing application-domain error policy.

2. **`Result<T, LookupError>` where `LookupError::NotFound` is a seam error — strong runner-up.**  
   This is appropriate when the port operation itself promises that the resource must exist. SQLx `fetch_one`, kube `get` and SeaORM `require_one` demonstrate that contract. It is less suitable for the template's primitive lookup because optional library callers must then catch and demote an error back to absence. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai))

3. **`Result<T, DomainError>` directly from the driven adapter — reject.**  
   It folds technology translation and use-case policy together. It is concise for one caller but couples every adapter and fake to the current domain error taxonomy, which is exactly what a hexagonal seam is intended to avoid.

4. **`Result<LookupOutcome<T>, PortError>` with `Found` and `Missing` — reserve.**  
   This is equivalent to `Result<Option<T>, E>` while there are only two nonfailure states. It becomes preferable if absence later carries information such as a tombstone, authoritative source, retry-after time or redaction reason.

5. **`Option<Result<T, E>>` — reject for this boundary.**  
   It can represent three states, but makes optionality govern the entire operation and puts failure inside the “present” branch. The standard library's `transpose` maps it to `Result<Option<T>, E>`, which better says that the operation may fail and its successful output is optional. ([doc.rust-lang.org](https://doc.rust-lang.org/core/option/enum.Option.html?utm_source=openai))

**Error enums and `thiserror`**

The recommendation uses **both** separate channels and typed enums:

- `Option` represents successful absence.
- A port error enum represents transport, protocol or upstream failures.
- An application/use-case error enum contains the not-found category and a source-failure category.
- `thiserror` may derive `Display` and `Error`, but it does not decide which state belongs in `Option` versus an error variant. It is an optional boilerplate reduction, not part of R03's contract. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/))
- An opaque reporting type such as `anyhow::Error` should not be the public port error while callers still need structured handling. RFC 2965 recommends conversion to a reporting type when errors are no longer expected to be handled beyond reporting. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html?utm_source=openai))

**Minimal dependency-free reference implementation**

```rust
use std::{error::Error, fmt};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProjectId(pub String);

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Project {
    pub id: ProjectId,
    pub name: String,
}

/// Errors mean the lookup could not produce a trustworthy answer.
/// There is deliberately no `NotFound` variant here.
#[derive(Debug)]
pub enum ProjectsPortError {
    Transport(Box<dyn Error + Send + Sync + 'static>),
    Protocol(String),
}

impl fmt::Display for ProjectsPortError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Transport(source) => {
                write!(f, "project source transport failed: {source}")
            }
            Self::Protocol(message) => {
                write!(f, "project source returned an invalid response: {message}")
            }
        }
    }
}

impl Error for ProjectsPortError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Transport(source) => Some(source.as_ref()),
            Self::Protocol(_) => None,
        }
    }
}

/// Reusable lookup-port contract.
pub type ProjectLookupResult = Result<Option<Project>, ProjectsPortError>;

/// Application/use-case error. R67 later assigns stable catalog names/codes.
#[derive(Debug)]
pub enum GetProjectError {
    NotFound { id: ProjectId },
    Source(ProjectsPortError),
}

impl fmt::Display for GetProjectError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NotFound { id } => write!(f, "project not found: {}", id.0),
            Self::Source(source) => write!(f, "could not load project: {source}"),
        }
    }
}

impl Error for GetProjectError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::NotFound { .. } => None,
            Self::Source(source) => Some(source),
        }
    }
}

/// Directly injected-function form. A trait or generic-bound form uses the
/// same `ProjectLookupResult` output.
pub fn get_project_with<F>(
    id: &ProjectId,
    find_project: F,
) -> Result<Project, GetProjectError>
where
    F: FnOnce(&ProjectId) -> ProjectLookupResult,
{
    let project = find_project(id).map_err(GetProjectError::Source)?;

    project.ok_or_else(|| GetProjectError::NotFound { id: id.clone() })
}
```

The same contract fits every R01 outcome:

```rust
// Formal port:
fn find_project(&self, id: &ProjectId)
    -> Result<Option<Project>, Self::Error>;

// Generic-bound caller:
fn get_project<P: ProjectsPort>(port: &P, id: &ProjectId) -> ...;

// Direct function injection:
F: FnOnce(&ProjectId) -> Result<Option<Project>, E>;

// Async variant:
Future<Output = Result<Option<Project>, E>>;
```

The recommended explicit application conversion is:

```rust
port.find_project(id)
    .await
    .map_err(GetProjectError::Source)?
    .ok_or_else(|| GetProjectError::NotFound { id: id.clone() })
```

That is one `map_err`, one `?` and one `ok_or_else`. A `From<PortError>` implementation could shorten it to `port.find_project(id).await?`, but the explicit constructor is preferable in a teaching template because the abstraction crossing remains visible. Rust's `?` operator otherwise converts `Err` through `From`, while conversion between `Option` and `Result` remains explicit. ([doc.rust-lang.org](https://doc.rust-lang.org/reference/expressions/operator-expr.html?highlight=two-complement&utm_source=openai))

**Adapter normalization**

| Adapter observation | Port result |
|---|---|
| HTTP success with valid resource | `Ok(Some(resource))` |
| Documented resource-level 404 | `Ok(None)` |
| Database query returns no row | `Ok(None)` |
| In-memory map has no key | `Ok(None)` |
| Timeout, DNS/connect failure, 5xx, rate-limit failure or authentication failure | `Err(port_error)` |
| Malformed or schema-invalid success body | `Err(port_error)` |
| Ambiguous 404 that might mean a bad endpoint, tenant or route | `Err(port_error)` unless the upstream protocol explicitly defines it as resource absence |

A cache miss is not automatically resource absence: a nonauthoritative cache adapter must fall through to its source of truth rather than return `Ok(None)`.

**Observable acceptance criteria**

1. Every optional single-resource lookup exposes three mechanically distinct states: `Ok(Some(_))`, `Ok(None)` and `Err(_)`.
2. The driven port error has no generic resource-not-found variant when the operation is the optional primitive.
3. An adapter contract test proves authoritative no-row/404 becomes `Ok(None)` while timeout/5xx/malformed data remains `Err`.
4. A use-case test proves `Ok(None)` becomes the exact typed application not-found category.
5. A use-case test proves port failure becomes a distinct source/application failure and retains its source chain.
6. A separate optional library use case can consume `Ok(None)` without manufacturing or catching an error.
7. CLI and web code match application errors only; neither inspects SQLx/kube/HTTP transport errors to decide domain absence.
8. R67 receives distinct typed categories but remains free to assign their final stable name, machine code and process exit code—even if two categories eventually share one numeric exit code.
9. The same contract tests can run against an in-memory fake and the real adapter.
10. Empty collection queries return `Ok(Vec::new())`, not `Ok(None)`; the optional contract applies to zero-or-one lookups.

**Performance assessment**

No alternative here changes request count, response bytes, retry policy or database query plan when applied to the same adapter. The selected pattern adds no dependency and requires no success-path heap allocation by contract; exact enum layout remains compiler- and type-dependent. The proposed empirical workload is a loopback adapter serving equal mixes of success, authoritative absence and failure, under the runtime/concurrency selected by R05. Instrumentation should count port calls and record wall-clock latency, throughput and peak memory in release mode. No such benchmark was run because the Rust repository is still research-only, and no evidence suggests that choosing a domain-collapsed error would produce meaningful end-to-end I/O gains. This is an architectural inference, not a benchmark result. ([github.com](https://github.com/smorinlabs/rs-launch-blueprint))

`BASELINE-REVIEW: F012 — agreement should be recorded at the architectural-policy level (“successful absence is distinct from failed lookup; requiredness belongs to the use case”), not as inheritance of either source mechanism — implement Rust as Result<Option<T>, E>, retain Python’s current split, and record a TypeScript follow-on that separates workspace lookup from getProjects; affected items: R03 directly, R01 only as the carrier shape, R67/R70 only as downstream mappings; do not reclassify the F012 ledger row until an owner-approved cross-repository follow-on lands — evidence: owner review, Python HEX-12, and convergent Rust std/SQLx/Diesel/kube/SeaORM practice.` ([raw.githubusercontent.com](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md))

### Dominant choice

**Lookup–Require Split**

- **Lookup:** driven seam returns `Result<Option<T>, E>`.
- **Require:** the application/use-case layer converts `None` with `ok_or_else`.
- **Failure:** `Err(E)` is separately mapped to an application source-failure category.
- **Dependency:** standard library only; `thiserror` is optional syntax.
- **Agreement level:** shared architectural pattern across Python, TypeScript and Rust; ecosystem-specific low-level encoding.

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **Lookup–Require Split: `Result<Option<T>, E>` then `ok_or_else`** | Rust `Option`; SQLx `fetch_optional`; Diesel `optional`; kube `get_opt`; SeaORM `one`; axum call-site conversion. ([doc.rust-lang.org](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai)) | SQLx, Diesel, kube, SeaORM, rust-postgres, rust-rocksdb, Block Buzz | Undated live API/source documentation, verified 2026-09-17 |
| **Required lookup error: `Result<T, LookupError::NotFound>`** | SQLx `fetch_one`; kube `get`; SeaORM `require_one`. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)) | SQLx, kube, SeaORM | Undated live API documentation, verified 2026-09-17 |
| **Adapter-owned domain collapse: `Result<T, DomainError>`** | Current TypeScript `getProjects` combines workspace lookup, HTTP activity and `NotFoundError`. ([github.com](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts)) | `ts-launch-blueprint` current implementation | Current main-branch source, verified 2026-09-17 |
| **Explicit nonfailure outcome: `Result<LookupOutcome<T>, E>`** | No maintained authoritative Rust reference found for the binary present/absent case | None identified in the surveyed shortlist | Evidence gap recorded 2026-09-17 |
| **Outer optional: `Option<Result<T, E>>`** | Rust documents it chiefly through `Option::transpose`, which produces `Result<Option<T>, E>`. ([doc.rust-lang.org](https://doc.rust-lang.org/core/option/enum.Option.html?utm_source=openai)) | No mainstream lookup API found using it as the public primitive | Undated live std documentation, verified 2026-09-17 |

The surveyed sources do not publish the exact port-to-use-case split under a standard Rust pattern name. **Lookup–Require Split** is therefore a project-defined name for an established composition of standard and widely practised idioms, not a claim of an existing Gang-of-Four-style name.

### Excluded by gate

No shortlisted standard-type pattern failed the six license/MSRV/security/platform/runtime/cost gates. The following shapes fail the item's semantic capability gate before shortlisting:

| Excluded shape | Failed gate |
|---|---|
| `Option<T>` as the complete Rust seam return | Cannot represent transport or protocol failure without panic, side channel or hidden global state. Python's bare annotation works only because exceptions provide another channel. |
| Panic/`unwrap` on transport failure or absence | Violates the requirement for recoverable, typed outcomes; Rust guidance recommends `Result` for recoverable errors. ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html?highlight=nu&utm_source=openai)) |
| `Result<Option<T>, anyhow::Error>` as the public library/port contract | It preserves three runtime states but loses a stable, matchable source-error contract. A reporting type belongs after structured handling is complete, not at this seam. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html?utm_source=openai)) |
| Adapter directly returns CLI exit errors or HTTP statuses | Violates inward dependency direction and prevents the same core use case from serving CLI, library and web front ends. ([alistair.cockburn.us](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai)) |
| Treating every HTTP 404 or cache miss as `None` | Cannot prove authoritative resource absence and risks hiding route, tenant, permission or cache-coverage failures. |

Crate-specific RustSec and maintenance gates remain inapplicable because R03 requires no new package.

### Up-and-comers

1. **Paired optional/required methods.** SeaORM's `one`/`require_one` design makes cardinality policy visible in naming. For this template, the analogous pair is a driven `find_project` and an application `get_project` or `require_project`. ([docs.rs](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html))
2. **Richer lookup outcomes.** If absence acquires meaningful metadata, graduate from `Option<T>` to:
   ```rust
   enum LookupOutcome<T> {
       Found(T),
       Missing { reason: MissingReason },
   }
   ```
   and retain the outer `Result<_, E>`.
3. **Richer error reporting libraries.** Diagnostic/reporting layers may improve CLI presentation, but they do not replace the lookup contract. Their selection belongs with R67 or another error-reporting item.
4. **No credible new contender presently displaces `Result<Option<T>, E>`.** The field's recent refinement is paired APIs and better diagnostics, not a new cardinality primitive.

### Fit for this template

**CLI**

- The command calls one application use case and receives either the resource, a typed not-found error or a typed source failure.
- R67 can map those categories without the CLI importing an HTTP client or database error.
- Optional commands such as “show if configured” can consume `Ok(None)` without treating it as command failure.
- Error output and exit-code behavior remain centralized rather than duplicated at each I/O call.

**Library**

- This target benefits most from retaining optionality. Library callers may legitimately probe for a resource, provide a fallback or treat absence as success.
- A public `find_project` returning `Result<Option<Project>, E>` supports those callers without asking them to inspect or downcast a manufactured `NotFound` error.
- Concrete, matchable port/application errors remain composable; opaque reporting errors can be added only at an executable boundary.

**Web service**

- The web adapter consumes the same application error as the CLI. It does not derive domain meaning directly from SQL or HTTP status.
- The eventual R70 mapping can translate application not-found to its chosen HTTP problem/status and source failure to its chosen upstream/internal problem.
- The contract is async-neutral: the future's output is still `Result<Option<T>, E>`.
- Official axum examples confirm that `ok_or`/`?` is ergonomic at an HTTP boundary, though this template should perform that conversion one layer earlier, in its shared use case. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))

### Recommendation

Adopt **Lookup–Require Split** as the R03 pattern:

1. A driven single-resource lookup **MUST** return:
   ```rust
   Result<Option<T>, E>
   ```
   or, asynchronously:
   ```rust
   Future<Output = Result<Option<T>, E>>
   ```

2. `Ok(None)` **MUST** mean the adapter successfully determined that the requested resource is absent.

3. `Err(E)` **MUST** mean the adapter could not produce a trustworthy answer. It includes transport, timeout, upstream rejection, protocol/schema and similar failures.

4. The driven port's error type **MUST NOT** contain a generic `NotFound` variant for this optional primitive.

5. The application/use-case that requires existence **MUST** perform the conversion:
   ```rust
   let value = lookup(...)
       .map_err(ApplicationError::Source)?
       .ok_or_else(|| ApplicationError::NotFound { key })?;
   ```

6. The resulting application error **MUST** contain separate, matchable categories for required-resource absence and source/I/O failure. R67 owns their final stable catalog names, codes and exit mappings.

7. Prefer naming that exposes the distinction:
   - driven seam: `find_project`, `resolve_workspace`
   - required use case: `get_project`, `require_project`

8. `thiserror` **MAY** derive the error boilerplate if selected elsewhere; R03 does not require it.

9. The pattern **MUST** be documented and tested independently of whether R01 chooses a trait, generic bound or injected closure.

10. Cross-repository rationale:
    - Python: retain current implementation.
    - Rust: implement `Result<Option<T>, E>`.
    - TypeScript follow-on: split optional workspace/resource lookup from the application service; use `Promise<T | undefined>` plus typed rejection unless that repository separately standardizes a discriminated result type.

### Ranked runner-up

**`Result<T, LookupError>` with a dedicated `NotFound` variant.**

It wins when **requiredness is invariant in the port contract**, not merely in one caller—for example:

- every valid invocation means “load this existing aggregate”;
- there is no probing or fallback use case;
- exposing an optional primitive would invite invalid handling;
- the operation is a command whose target must exist rather than a neutral query.

SQLx `fetch_one`, kube `get` and SeaORM `require_one` show this contract is legitimate. It does not win for the template's reusable lookup seam because the CLI, library and web targets can apply different policy to absence. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai))

### Tradeoffs

| Alternative | What the recommendation gives up | Why accepted |
|---|---|---|
| Required lookup error | A flatter `Result<T, E>` and direct `?` propagation of not-found | The flatter type hard-codes requiredness and makes optional callers demote an error back into absence. |
| Adapter-owned `DomainError` | Fewer mapping lines in a single adapter function | It couples transport code, fakes and every future adapter to application policy and R67's taxonomy. |
| Explicit `LookupOutcome<T>` | Named variants and easy future expansion | `Option<T>` is smaller and universally understood while there are only present/absent nonfailure outcomes. |
| `Option<Result<T, E>>` | Equivalent three-state expressiveness | The nesting order obscures that operation failure dominates the entire lookup; standard APIs consistently favor `Result<Option<…>>`. |
| Python-style bare optional return | Visually simpler signature | Rust has no exception channel; bare `Option<T>` would discard I/O failure information. |
| Automatic `From` conversion with bare `?` | One fewer visible combinator | Explicit `map_err(ApplicationError::Source)` teaches where the abstraction crossing occurs and is easier to assert in tests. |
| Opaque reporting error | Easy context attachment | Library and use-case code still needs structured matching; reporting belongs at the outer boundary. |

The accepted cost is one nested standard type and usually one `ok_or_else` at a required call site.

### Parameters

- `owns (none) = n/a`
- `assumes error-taxonomy-exit-codes = R67-defined; it must accept separately typed application categories for resource absence and source/I/O failure, but R03 does not require distinct numeric exit codes`
- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- `assumes current-msrv-floor = 1.96.0 as of 2026-09-17, because stable is 1.98.0`
- `assumes license = MIT OR Apache-2.0`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes http-transport-injection-seam = unresolved by R01; return semantics remain Result<Option<T>, E> for trait, generic-bound or injected-function forms`
- No `CONFLICT:` identified. ([raw.githubusercontent.com](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md))

### Migration implications

Logical file locations are shown below; R01/R02 may place them in one crate, modules or separate workspace members without changing the contract.

| File or logical module | Change |
|---|---|
| `<projects>/ports.rs` or the R01-selected seam module | Define the optional lookup signature `find_project(...) -> Result<Option<Project>, E>` and equivalent workspace-resolution lookup. Document all three states. |
| `<projects>/errors.rs` | Define the application/use-case not-found category and distinct source-failure category. Do not assign R67's final code here. |
| `<projects>/services.rs` | Translate `None` with `ok_or_else`; map port failures separately. Keep HTTP, SQL and CLI types out. |
| `<projects>/adapters/http.rs` | Inspect protocol semantics before generic status-to-error conversion; map only authoritative resource absence to `Ok(None)`. |
| `<projects>/adapters/in_memory.rs` | Return `Ok(None)` for a missing key and support an explicit injected-failure mode for contract tests. |
| `<projects>/adapters/database.rs`, if shipped | Use the datastore's optional lookup form rather than catching every error as no-row. |
| `<cli>/errors.rs` or CLI entry point | Consume only the application error and delegate final exit mapping to R67. |
| `<web>/problems.rs` | Consume only the application error and delegate HTTP problem/status mapping to R70. |
| `tests/port_contract.rs` | Shared found/absent/failure suite for every adapter. |
| `tests/projects_service.rs` | Assert explicit absence-to-not-found and source-failure mappings. |
| `tests/cli_errors.rs` and web error tests | Assert the two application categories remain distinguishable at each driving adapter. |
| `docs/design/lookup-require-split.md` | Record the pattern name, state table, authoritative-absence rule and examples for trait/generic/closure forms. |
| `research/topics/03-*/DECISION.md` | Record this recommendation and the `BASELINE-REVIEW` line. |
| `docs/port/COMMONALITY.md` | Do not silently reclassify F012; preserve its source divergence and link the resolved R03 decision. |

**Cross-repository follow-on, not part of this Rust implementation:**

- Python requires no behavior change; add or retain contract tests and shared terminology.
- TypeScript should split `src/lib/api.ts` so workspace/resource lookup returns `undefined` on authoritative absence and throws/rejects only on source failure; an application service should create `NotFoundError`. The current inline throw is visible at the workspace search inside `getProjects`. ([github.com](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts))

The Rust repository currently has no Rust implementation, so these are planned additions rather than edits to existing source files. ([github.com](https://github.com/smorinlabs/rs-launch-blueprint))

### Validation strategy

**Executed during this research:** none. The repository is explicitly in a research-only state with no Rust code, so the following checks are proposed acceptance commands, not claimed results. ([github.com](https://github.com/smorinlabs/rs-launch-blueprint))

**Toolchain and full-workspace checks**

```bash
# Current floor as of 2026-09-17.
rustup toolchain install 1.96.0

cargo +1.96.0 check --workspace --all-targets --all-features
cargo +stable fmt --all -- --check
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
cargo +stable test --workspace --all-targets --all-features
cargo +stable test --workspace --doc
```

Expected: the contract compiles on the MSRV and stable toolchains, with web features enabled and disabled, on both `ubuntu-latest` and `macos-latest`.

**Port contract**

```bash
cargo test --test port_contract -- --nocapture
```

Required cases:

```text
found:
  adapter -> Ok(Some(project))

authoritative absence:
  adapter -> Ok(None)

transport failure:
  adapter -> Err(ProjectsPortError::Transport(_))

protocol/schema failure:
  adapter -> Err(ProjectsPortError::Protocol(_))
```

Run the same suite against the in-memory fake and each concrete adapter. For an HTTP adapter, the realistic fixture must include a valid response, documented resource-level 404, timeout/reset, 5xx and malformed success body. The HTTP mocking library is whatever R48 selects; R03 does not choose it.

**Application translation**

```bash
cargo test --test projects_service \
  absence_becomes_not_found \
  source_failure_stays_distinct \
  optional_lookup_preserves_none \
  found_value_is_returned
```

Expected:

- `Ok(Some(project))` → `Ok(project)`
- `Ok(None)` → `Err(GetProjectError::NotFound { .. })`
- `Err(port_error)` → `Err(GetProjectError::Source(port_error))`
- `Error::source()` remains populated for wrapped transport failures
- the optional library use case still returns `Ok(None)`

**CLI and web integration**

```bash
cargo test --test cli_errors
cargo test --features web --test web_errors
```

Expected:

- not-found and source failure arrive as different application variants;
- CLI tests assert the exact R67 exit codes once assigned;
- web tests assert the exact R70 problem/status mappings once assigned;
- neither test imports or matches the concrete HTTP/database error to determine absence.

**Call-count and performance invariants**

Each fake should contain an invocation counter. Tests must assert one lookup call for found, absent and failure paths, proving `ok_or_else` adds no retry or second I/O operation.

A planned, nonblocking performance check may run an equal mix of found/absent/failure lookups through:

1. an in-memory adapter in `--release`;
2. a loopback HTTP adapter under R05's selected runtime and concurrency;
3. both dominant and runner-up encodings with identical adapter behavior.

Record wall-clock latency, operations per second, request count and peak memory. Do not establish a pass threshold unless measurement finds a material difference; semantic correctness is the acceptance gate.

### Confidence & re-verify trigger

**Confidence: high — 0.94.**

The recommendation is supported by first-party Rust semantics, multiple independent database and remote-API libraries, maintained framework examples, the original hexagonal architecture source and the Python repository's already-tested pattern.

Re-verify if any of these occur:

1. R01 chooses a seam representation that cannot retain `Result<Option<T>, E>` as its logical output.
2. R67 adopts an error model that cannot accept separately typed absence and source-failure categories.
3. The target upstream protocol cannot reliably distinguish resource absence from endpoint, authorization or tenant errors.
4. Every legitimate caller is proven to require existence, making the required-lookup runner-up simpler without sacrificing reuse.
5. Absence needs structured metadata, making `LookupOutcome<T>` preferable to `Option<T>`.
6. TypeScript standardizes an explicit result/discriminated-union convention; its follow-on should then use that convention rather than promise rejection.
7. Stable Rust advances, requiring the concrete MSRV CI value to move under the fixed stable-minus-two policy.
8. An empirical end-to-end benchmark unexpectedly finds material latency, throughput or resource differences attributable to the return encoding.

### Sources

All URLs were retrieved **2026-09-17**.

| Source | URL | Publication/current date and role |
|---|---|---|
| Rust `Option` documentation | `https://doc.rust-lang.org/std/option/enum.Option.html` | Live std documentation; `ok_or_else`, `transpose` |
| Rust Reference, operator expressions | `https://doc.rust-lang.org/reference/expressions/operator-expr.html` | Live normative reference; `?` behavior |
| Rust Book, recoverable errors | `https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html` | Live first-party guidance |
| `Path::try_exists` | `https://doc.rust-lang.org/stable/std/path/struct.Path.html#method.try_exists` | Live std precedent for negative answer versus inability to determine |
| RFC 0236, error conventions | `https://rust-lang.github.io/rfcs/0236-error-conventions.html` | 2014-10-30; Rust library error conventions |
| RFC 2965, Error Handling Project Group | `https://rust-lang.github.io/rfcs/2965-project-error-handling.html` | 2020-07-23; concrete error versus reporting type guidance |
| Rust 1.98.0 announcement | `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/` | 2026-08-20; current stable-version endpoint |
| 2025 State of Rust survey results | `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` | 2026-03-02; ecosystem/source-weighting context |
| Original Hexagonal Architecture article | `https://alistair.cockburn.us/hexagonal-architecture` | 2005-09-04; primary architectural source |
| SQLx `fetch_optional` | `https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html#method.fetch_optional` | Live maintainer documentation |
| Diesel `OptionalExtension` | `https://docs.rs/diesel/latest/diesel/prelude/trait.OptionalExtension.html` | Live maintainer documentation |
| Diesel changelog | `https://github.com/diesel-rs/diesel/blob/main/CHANGELOG.md` | Maintainer statement describing `Result<Option<T>>` as idiomatic for zero-or-one |
| kube `Api::get_opt` | `https://docs.rs/kube/latest/kube/struct.Api.html#method.get_opt` | Live maintainer documentation |
| SeaORM `one` / `require_one` | `https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html` | Live maintainer documentation |
| axum todos example | `https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs` | Maintained Tokio source; explicit `ok_or(NOT_FOUND)` |
| axum SQLx example | `https://github.com/tokio-rs/axum/blob/main/examples/sqlx-postgres/src/main.rs` | Maintained Tokio integration example |
| rust-postgres client | `https://github.com/sfackler/rust-postgres/blob/master/postgres/src/client.rs` | Maintained source showing fallible optional row lookup |
| rust-rocksdb database API | `https://github.com/rust-rocksdb/rust-rocksdb/blob/master/src/db.rs` | Maintained source showing `Result<Option<Vec<u8>>, Error>` |
| Block Buzz store | `https://github.com/block/buzz/blob/main/crates/buzz-relay/src/api/git/store.rs` | Company-hosted independent practice evidence |
| `thiserror` documentation | `https://docs.rs/thiserror/latest/thiserror/` | Live maintainer documentation; derive mechanics |
| MDN `fetch()` | `https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch` | Live web-platform documentation |
| TypeScript `strictNullChecks` | `https://www.typescriptlang.org/tsconfig/strictNullChecks.html` | Live first-party TypeScript documentation |
| Python hexagonal design | `https://github.com/smorinlabs/py-launch-blueprint/blob/main/docs/design/0005-hexagonal-architecture-and-enforcement.md` | Current repository design; HEX-12 |
| Python ports | `https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/src/py_launch_blueprint/core/ports.py` | Current source contract |
| Python projects service | `https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/src/py_launch_blueprint/core/services/projects.py` | Current absence-to-application-error translation |
| TypeScript API client | `https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts` | Current inline workspace-not-found translation |
| Rust research governing specification | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` | Approved 2026-09-01; amended 2026-09-04 |
| Commonality ledger | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md` | Current F012 classification |
| Fixed parameters | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md` | Owner-fixed values, 2026-09-02 |
| Owner review | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/OWNER-REVIEW.md` | R03 owner direction, 2026-09-04 |
| Rust template repository | `https://github.com/smorinlabs/rs-launch-blueprint` | Current research-only repository state |

## Sources

- [PathBuf in std::path - Rust](https://doc.rust-lang.org/std/path/struct.PathBuf.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E&utm_source=openai)
- [Query in sqlx::query - Rust](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)
- [Select in sea_orm::query - Rust](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html)
- [Option in std::option - Rust](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai)
- [hexagonal-architecture](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai)
- [axum/examples/todos/src/main.rs at main · tokio-rs/axum · GitHub](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)
- [2025 State of Rust Survey Results | Rust Blog](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai)
- [py-launch-blueprint/src/py_launch_blueprint/core/ports.py at main · smorinlabs/py-launch-blueprint · GitHub](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/ports.py)
- [result.rs - source](https://docs.rs/diesel/latest/src/diesel/result.rs.html?utm_source=openai)
- [Api in kube - Rust](https://docs.rs/kube/latest/kube/struct.Api.html)
- [buzz/crates/buzz-relay/src/api/git/store.rs at main · block/buzz · GitHub](https://github.com/block/buzz/blob/main/crates/buzz-relay/src/api/git/store.rs?utm_source=openai)
- [https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md)
- [Announcing Rust 1.98.0 | Rust Blog](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)
- [ts-launch-blueprint/src/lib/api.ts at main · smorinlabs/ts-launch-blueprint · GitHub](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts)
- [Option in core::option - Rust](https://doc.rust-lang.org/core/option/enum.Option.html?utm_source=openai)
- [thiserror - Rust](https://docs.rs/thiserror/latest/thiserror/)
- [2965-project-error-handling - The Rust RFC Book](https://rust-lang.github.io/rfcs/2965-project-error-handling.html?utm_source=openai)
- [Operator expressions - The Rust Reference](https://doc.rust-lang.org/reference/expressions/operator-expr.html?highlight=two-complement&utm_source=openai)
- [GitHub - smorinlabs/rs-launch-blueprint: Rust sibling of py-launch-blueprint / ts-launch-blueprint — CLI + library + web service template (research phase) · GitHub](https://github.com/smorinlabs/rs-launch-blueprint)
- [https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md)
- [To panic! or Not to panic! - The Rust Programming Language](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html?highlight=nu&utm_source=openai)
- [https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md)
