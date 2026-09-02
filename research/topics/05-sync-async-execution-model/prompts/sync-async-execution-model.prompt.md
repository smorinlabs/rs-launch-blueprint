# Deep-research prompt — Sync/async execution model (R05, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint`'s driven-I/O boundary (the CLI's HTTP calls, and the optional web feature's request handlers) is sync end-to-end like py, or async end-to-end like ts — and, if async, which async runtime and HTTP client. Item kind: `bundle`. Value test: if this answer is wrong, every I/O-touching function signature in the core crate (sync `fn` vs. `async fn`), the CLI entry point's execution shape, the web adapter's handler signatures, and the HTTP-client crate choice all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge completely. py is sync end-to-end, with its optional web layer bridging into FastAPI's async request handling via a threadpool. ts is async end-to-end, with every layer from the CLI entry point down to the HTTP call built on `Promise`s. Evidence: py `src/py_launch_blueprint/core/adapters/py_api.py:38` — `import requests` (blocking); `src/py_launch_blueprint/web/routers/projects.py:25` — "Handlers are sync (``def``) because ``ProjectsService`` uses ``requests``; FastAPI runs them in its threadpool"; ts `src/router.ts:182` — `export async function runCli` and `src/lib/api.ts:108` — `async function request` wrap the injected `fetch`; the whole call chain from CLI entry to HTTP is `Promise`-based. Ledger rows: F016, F022 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` (F016, origin `different`) and `RUST-ONLY` (F022, origin `none` — neither repo picks a pluggable async executor; py is sync throughout, ts's `Promise`s run on the JS engine's built-in event loop, not a selectable runtime; F022 is moot unless F016 resolves async).
- Already decided, do not re-open: the web service ships as an optional, separately installed Cargo feature (F017, verdict `ADOPT`) — the question here is what execution model that optional web layer and the always-present CLI share, not whether the web layer exists. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's end-to-end async shape follows directly from JavaScript's single-threaded event-loop execution model, not from a deliberate runtime-selection decision; `TS_PORT_DECISIONS.md` records no dedicated entry choosing async over sync (there was no sync option to reject).

## Out of scope
- The shape of the ports-and-adapters seam itself (trait object vs. generic bound vs. direct injection); R01 (`ports-and-adapters-seam`) owns F001 and the `http-transport-injection-seam` parameter — this item decides sync-vs-async and the runtime, not how the I/O boundary is abstracted.
- Whether the web service exists as an optional capability at all; that is settled (F017, `ADOPT`) — this item only decides the execution model the web layer and CLI share.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R05
- owns:
- consumes:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) names this item as a related coupling — R01's seam decision (trait object, generic bound, or direct injection) wraps around whichever sync/async model this item picks, but R01 registers `http-transport-injection-seam`, which this item does not need to consume: the seam's shape is compatible with either a sync or an async execution model. Treat R01's direction as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s driven-I/O boundary is sync (blocking) end-to-end like py, or async (non-blocking, `async fn` plus an executor) end-to-end like ts — and, if async, which async runtime and HTTP client crate.
- HIGH: What are the concrete costs of a sync-blocking core (e.g. `reqwest::blocking`, or `ureq`, with threads for any concurrency) versus an async core (`reqwest` async + `tokio`) for a template that must serve as a CLI *and* an optional web service — binary size, dependency count, compile time, and API ergonomics for template consumers extending the CLI?
- HIGH: If sync, do the dominant Rust web frameworks (Axum, Actix-web) require an async executor regardless — meaning py's "sync core, async web adapter bridged through a threadpool" shape (FastAPI's threadpool) has a direct, awkward, or nonexistent Rust analogue — or does a sync-first web framework (e.g. a thread-per-request design) avoid needing an async runtime at all?
- MEDIUM: If async, which runtime — `tokio` (dominant, full-featured, near-mandatory for Axum) or a lighter-weight alternative (`smol`, `async-std`) — best fits a CLI-first template where most invocations are a single HTTP round-trip rather than many concurrent tasks, and what does each cost in binary size and dependency count?
- MEDIUM: Does an async-first core impose ergonomic costs on the CLI entry point (`#[tokio::main]`, or a hand-rolled `block_on`) compared to a sync core, and how do popular Rust CLI templates (e.g. `cargo-generate` CLI templates, `clap`'s own examples) handle that boundary when they also ship a library crate?
- LOW: Is there a documented "sync CLI wrapping an async library core" pattern in the Rust ecosystem that gives ts's async-native ergonomics for the web feature without forcing the CLI's synchronous-feeling entry point to become `async fn main`?

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
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
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
