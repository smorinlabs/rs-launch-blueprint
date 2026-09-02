# Deep-research prompt — Ports-and-adapters seam (R01, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` expresses its driven-I/O seam as a port/adapter split (py's shape) or as direct injection of function values (ts's shape), and — if a port split is adopted — how the port is verified against its adapter, how the composition root wires them, how a first-class fake adapter ships, and how the web layer reuses the CLI's data contract. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's port trait module, composition root, in-memory fake adapter, web-adapter boundary, and the fake-vs-real substitutability test suite all get rewritten around a different seam mechanism.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge on the driven-I/O seam. py separates a `Protocol` port from its adapters, wired by a composition root, verified structurally by the type checker, with a shipped in-memory fake and a web layer that reuses the CLI's data contract. ts injects concrete function values directly into the CLI router with no port/adapter split. Evidence: py `src/py_launch_blueprint/core/ports.py:40` — `ProjectsRepository(Protocol)`, structurally satisfied by adapters; ts `src/router.ts:31` — `CliDeps` interface: individually typed I/O functions injected directly, no port+adapter split. Ledger rows: F001, F002, F011, F013, F018, F121 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F002 composition root — py `src/py_launch_blueprint/composition.py:36` (`build_projects_service()` binds a concrete adapter to the service); ts `src/router.ts:55` (`realDeps()` builds production values directly, nothing to swap). F011 adapter-satisfies-port verification — py `pyproject.toml:253` (`ty` type-checks structural satisfaction); ts: none (structural typing is a language default, not a chosen verification step). F013 first-class fake adapter — py `src/py_launch_blueprint/core/adapters/in_memory.py:20` (`InMemoryProjectsRepository` ships in `core/adapters/`); ts: none (fakes are constructed inline in `tests/*.test.ts`). F018 web layer as thin adapter — py `docs/adr/0013-web-service-best-practices.md:21`; ts: none (no web front-end exists to compare). F121 substitutability suite — py `tests/core/test_projects_repository_contract.py:70` (one parametrized suite runs against both adapters); ts: none.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-019(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — DI-first mocking with "injected fetchImpl as the only HTTP transport seam"; ts deliberately kept no port/adapter split, only an injected-function seam at the CLI-deps boundary.

## Out of scope
- Async runtime selection and the sync/async execution model for the I/O boundary; R05 (`sync-async-execution-model`) owns F016/F022 — treat sync-vs-async as undecided, do not choose one here.
- Cargo workspace crate topology and which crate a port trait or its adapter physically lives in; R02 (`crate-boundary-enforcement`) owns F021 — this item decides the seam's shape, not its crate placement.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R01
- owns: http-transport-injection-seam
- consumes:
- related (not a registry dependency): R05 (`sync-async-execution-model`, F016/F022) decides the sync/async shape of the I/O boundary this seam wraps. R05 registers no parameter this item can consume — treat its direction as open, do not block on it.
- related (not a registry dependency): R02 (`crate-boundary-enforcement`) owns the Cargo workspace crate topology (F021); this item does not decide which crate a port trait or adapter physically lives in.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a port/adapter split for its driven-I/O seam and, if so, what Rust mechanism expresses the port, verifies an adapter against it, wires the composition root, ships a first-class fake, and lets the web layer reuse the CLI's data contract.
- HIGH: Should the port abstraction (F001) be a `dyn Trait` object (boxed, runtime dispatch) or a generic type parameter bound by a trait (static dispatch, monomorphized)? What are the ergonomics, compile-time, and binary-size trade-offs for a CLI + library + web target?
- HIGH: Does Rust's trait system alone verify that an adapter structurally satisfies a port (F011) at compile time, or does reaching parity with py's parametrized fake-vs-real substitutability suite (F121) need a mocking/fake-generation crate (e.g. `mockall`)?
- MEDIUM: What is the idiomatic Rust shape for the composition root (F002) that wires a concrete adapter to the chosen seam — a `fn build_service() -> impl Trait` factory, a struct holding a boxed trait object, or a dependency-injection crate?
- MEDIUM: What is the idiomatic Rust shape for a first-class in-memory/fake adapter (F013) shipped in the library crate itself (not test-only), and does it require any supporting crate (e.g. for interior mutability)?
- LOW: How does the web layer (F018), as a thin adapter, reuse the CLI's data contract without duplicating serialization types — shared structs derived with `serde`, or a translation layer at the boundary?

## Required evidence
Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on Windows;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
