# R05 sync-async-execution-model — raw report (opus)

Engine identity: `research-opus-2026-09-17T033527Z-bfacc9e801a5`, model `claude-opus-5`, family anthropic.
Item kind: `bundle`. Effort tier: `deep`. Answer-template kind: `bundle` (per `inputs/prompt.md` title line and `## Answer template`).

**Dates.** Every endpoint in this report was queried on **2026-09-17 (UTC)**; the session's local date is 2026-09-16 (America/Los_Angeles) and repository files were read on 2026-09-16/17. Where a figure is quoted below, "retrieved 2026-09-17" means that UTC date.

**Toolchain the probes ran on.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `host: aarch64-apple-darwin`, LLVM 22.1.8; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4 (build 25E246), `arm64`. Under `msrv-policy` ("stable minus 2 minor versions") the floor today is **1.96**, and every probe manifest declared `rust-version = "1.96"`, `edition = "2024"`.

**Licence gate.** Fitness gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate in this report (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)"). Licence strings are still recorded as published metadata, and nothing is excluded on licence.

---

### Landscape

This item decides one category: **the execution model of the template's driven-I/O boundary** — whether the library crate's I/O-touching functions are synchronous `fn` that block the calling thread, or `async fn` driven by an executor — and, as a dependent sub-question, **which HTTP client crate** carries the CLI's outbound calls and **which runtime** (if any) the always-present code joins. The optional web surface's own runtime is not open: R69 (`web-framework-stack`, owner-accepted) already selected `axum` 0.8.9 on `tokio` 1.53.1 behind the off-by-default `web` feature, and states that "whether the CLI and library join that world is R05's open question" (`research/topics/69-web-framework-stack/DECISION.md`, line 799 and the overlap-map row at line 2204, read 2026-09-16).

**The three-bin map of the Rust field**

**Bin 1 — built-in or first-party toolchain.** Rust's standard library ships blocking I/O (`std::net::TcpStream`, `std::io::Read`/`Write`) and OS threads (`std::thread`, and `std::thread::scope`, stabilised in **Rust 1.63.0** — `https://doc.rust-lang.org/std/thread/fn.scope.html`, retrieved 2026-09-17). It ships the `Future` trait, `async`/`await` syntax and, since **Rust 1.75**, `async fn` in traits (*"Rust 1.75 supports use of `async fn` and `-> impl Trait` in traits. However, this initial release comes with some limitations that are described in the announcement post."* — `https://blog.rust-lang.org/2023/12/28/Rust-1.75.0/`, retrieved 2026-09-17) — but **no executor and no reactor**: there is no first-party async runtime in `std`, which is why an async choice is always also a third-party-runtime choice. This asymmetry is the single most important structural fact in this landscape: the synchronous branch needs **zero** runtime dependencies; the asynchronous branch needs at least one, and in practice a tree of them. Verified in this run: the synchronous scenario probe resolves with `tokio` entirely absent from its default dependency tree (`cargo tree -i tokio -e normal` exits non-zero), while the asynchronous one has `tokio` in the default tree (probe evidence below).
- Candidates from this bin: **`std::thread` + blocking `std::io`** (execution model); **`std::thread::scope`** (bounded CLI-side concurrency without a crate).

**Bin 2 — established industry standard.**
- Runtime: **`tokio`** — 224,518,658 recent (90-day) downloads and 972,640,252 all-time downloads (`GET https://crates.io/api/v1/crates/tokio`, `crate.recent_downloads` / `crate.downloads`, retrieved 2026-09-17); **72,755** crates.io reverse dependencies (`GET https://crates.io/api/v1/crates/tokio/reverse_dependencies?per_page=1`, `meta.total`, retrieved 2026-09-17). It is the runtime `axum` is built on (both live under the `tokio-rs` GitHub organisation), which is why R69 could not avoid it inside the `web` feature.
- Async HTTP client: **`reqwest`** — 183,008,208 recent / 720,508,363 all-time downloads; **29,543** reverse dependencies (same endpoints, retrieved 2026-09-17). Built on `hyper` 1 (202,085,596 recent downloads).
- Sync HTTP client: **`ureq`** — 58,361,888 recent / 202,969,771 all-time downloads; **3,718** reverse dependencies (same endpoints, retrieved 2026-09-17). It is the largest genuinely blocking client, and the only one in the shortlist that does not embed a runtime.
- Sync HTTP client (C binding): **`curl`** crate — used by `rust-lang/cargo` itself (see practice evidence).
- Dyn-compatibility shim for async traits: **`async-trait`** — 145,531,756 recent / 663,301,596 all-time downloads (retrieved 2026-09-17); already named by R01 as the conditional member that joins "only if R05 selects an async I/O boundary".

**Bin 3 — up-and-comers and niche.**
- Runtimes: **`smol`** (4,654,658 recent downloads; 726 reverse dependencies; newest non-yanked `2.0.2`, 2024-09-07 — `GET https://crates.io/api/v1/crates/smol/versions`, retrieved 2026-09-17), **`async-std`** (10,307,882 recent downloads but **discontinued**, see *Excluded by gate*), and the thread-per-core runtimes `monoio`/`compio`/`glommio` (not shortlisted: they target io_uring-class Linux server workloads, not a two-OS CLI).
- Minimal `block_on` shims: **`pollster`** 1.0.1 (11,391,650 recent downloads), **`futures-lite`** 2.6.1 (54,043,133 recent downloads) — relevant only to the LOW question (a sync CLI over an async core).
- Sync HTTP clients: **`attohttpc`** 0.31.0 (6,212,919 recent downloads), **`minreq`** 3.0.0 (1,317,831), **`isahc`** 2.0.1 (1,200,401, libcurl-backed).
- Sync-first web frameworks (the HIGH question's "thread-per-request design"): **`rouille`** 3.6.2, **`tiny_http`** 0.12.0, **`astra`** 0.4.0 — all three quiet or dormant, figures under *Excluded by gate* in member 3.

**Authoritative sources used, and why each counts**

| Source | Why it is authoritative | What it was used for |
|---|---|---|
| The Rust standard library reference, `doc.rust-lang.org` | The Rust project's own normative documentation | That `std` ships blocking I/O and threads and ships no executor |
| The Cargo Book, `doc.rust-lang.org/cargo/reference/features.html` | The Rust project's own normative documentation for the manifest format | The `dep:` syntax and optional-dependency rule that R69's owned `web` value depends on |
| `tokio.rs/tokio/topics/bridging` ("Bridging with sync code") | The maintainers' own topic guide for exactly this boundary | The `#[tokio::main]` expansion, `Runtime::block_on`, and the current-thread-runtime recommendation for CLI-shaped programs |
| `docs.rs/tokio/1.53.1/tokio/runtime/struct.Builder.html` | Generated from the maintainers' own source at the exact version R69 pinned | `max_blocking_threads` default (512) and `thread_keep_alive` default (10 s), which bound the `spawn_blocking` bridge |
| `docs.rs/reqwest/0.13.5/reqwest/blocking/index.html` | The maintainer's own module documentation at the newest published version | The blocking client's own statement about running inside a runtime (and the discrepancy this run measured against it) |
| `rustsec.org` advisory database | The Rust Secure Code WG's published database — the gate-3 source named by the prompt | `async-std`'s unmaintained advisory; `tokio`'s advisory history |
| crates.io API (`/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`) | The registry of record; the prompt's mandated figure source | Every download, version, `rust_version` and reverse-dependency count |
| GitHub REST (`repos/<o>/<r>`, `search/issues`, `repos/<o>/<r>/contents/...`) | The hosting platform of record for each project; the prompt's mandated figure source | Stars, archived flag, `pushed_at`, open-issue counts, and the adopters' own `Cargo.toml` files |
| R69 `DECISION.md` and R01 `DECISION.md` in this repository | Owner-accepted decisions of this programme | The constraints this item must not silently break |

Two sources that a survey of this topic would normally reach for **did not yield a usable figure and are reported as gaps, not guessed**: the *2025 State of Rust Survey Results* (`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results`, fetched 2026-09-17) contains no async-runtime breakdown in its HTML body — the async figures, if any, are only in the linked PDF, which was not retrieved; and the *2023 Annual Rust Survey Results* (`https://blog.rust-lang.org/2024/02/19/2023-Rust-Annual-Survey-2023-results/`, fetched 2026-09-17) discusses async Rust as a difficulty area but publishes no runtime-share numbers. **No survey-based "N% of Rust async projects use tokio" figure is asserted anywhere in this report.** Adoption evidence rests on the registry counts and the named projects below.

**Well-regarded projects surveyed, with the evidence that they are well regarded**

Every `Cargo.toml` below was read through the GitHub contents API on 2026-09-17 (`GET https://api.github.com/repos/<o>/<r>/contents/Cargo.toml`), at each repository's default branch; stars, `archived` and `pushed_at` come from `GET https://api.github.com/repos/<o>/<r>` on the same date.

| Project | Stars | Last push | I/O stack in its own manifest | What it shows |
|---|---|---|---|---|
| `rust-lang/cargo` | 15,484 | 2026-09-16 | `curl = "0.4.49"` + `curl-sys`, `futures` with `default-features = false, features = ["std","executor","async-await"]`; **no `tokio`, no `reqwest`** | The Rust project's own flagship CLI, which makes many concurrent HTTP requests, uses libcurl's multi interface and a bare `futures` executor rather than tokio. Authoritative because it is maintained by the Rust project itself. |
| `astral-sh/uv` | 89,891 | 2026-09-17 | `reqwest = "0.13.1"` + `tokio = "1.40.0"` + `tokio-stream`, `tokio-util`, `hyper` | The strongest counter-case: a very widely adopted Rust CLI that is async end-to-end. Its workload is a dependency resolver issuing hundreds of concurrent registry fetches — materially unlike one round trip per invocation. |
| `rust-lang/rustup` | 7,044 | 2026-09-17 | `reqwest = { version = "0.13", default-features = false, features = ["blocking", …], optional = true }` **and** `tokio = { version = "1.26.0", default-features = false, features = ["macros","rt-multi-thread","sync"] }` | A hybrid: the Rust project's own installer calls HTTP through `reqwest::blocking` while still carrying tokio for other work. Evidence that "blocking client" and "no tokio" are **not** the same claim. |
| `ducaale/xh` | 8,080 | 2026-09-05 | `reqwest` 0.13.2 with `features = [… "blocking" …]`; `tokio` only in `[dev-dependencies]` | A popular HTTPie-style CLI whose production path is entirely blocking; tokio appears only in tests. |
| `EmbarkStudios/cargo-deny` | 2,426 | 2026-09-03 | `ureq` (listed in ureq's reverse-dependency page) | A cargo subcommand in the same supply-chain-tooling space as this template, choosing the blocking client. |
| `nextest-rs/nextest` (`nextest-runner`) | 3,293 | 2026-09-17 | `ureq` (reverse-dependency page) | The de facto modern Rust test runner; blocking client. |
| `rustwasm/wasm-pack` | 7,283 | 2026-08-12 | `ureq` (reverse-dependency page) | A rust-lang-org-adjacent CLI; blocking client. |
| `sharkdp/hyperfine` | 28,871 | 2026-04-30 | no HTTP client at all | Included only to note that the most-starred Rust CLI in this sample does no network I/O and therefore votes on nothing here. |
| `tokio-rs/axum` | (R69's selected framework) | — | requires `tokio` | Settled by R69; restated here because it fixes the runtime **inside** the `web` feature whichever way this item goes. |

Reading of the practice evidence: **the CLI camp is genuinely split, and it splits by workload, not by fashion.** Tools whose job is many concurrent fetches (`uv`) are async; tools that issue a few requests per invocation (`cargo-deny`, `nextest`, `wasm-pack`, `xh`, `rustup`'s downloader) use a blocking client; and the Rust project's own `cargo` avoids both tokio and reqwest entirely. `rs-launch-blueprint`'s CLI is, per the prompt, a template whose "most invocations are a single HTTP round-trip", which places it squarely in the second group.

---

### Principles and implementation

**The shared requirement, its source and agreement level**

**Requirement.** Every inbound front end (the CLI, and the optional web service) must reach the same use-case layer, which must reach the outside world through the driven-I/O port R01 defines, and the template must work on `ubuntu-latest` and `macos-latest` with an MSRV floor of stable-minus-two. **The execution model is the mechanism by which that requirement is met, not the requirement itself.**

**Source.** `docs/port/COMMONALITY.md` rows F016 ("Sync/async execution model for the I/O boundary", origin `different`, verdict `DIVERGENT`, item R05, "bundle; decides F022") and F022 ("Async runtime selection for the async I/O boundary", origin `none`, verdict `RUST-ONLY`, "bundle; moot if F016 resolves sync"), read 2026-09-16.

**Agreement level: mechanism — Rust decides alone.** The two sources do not agree with each other, and neither's answer is portable. py is sync end-to-end because CPython's blocking `requests` is the ecosystem default, and its web tier bridges into FastAPI's async request handling through a threadpool — evidenced at the pin `b08bccfb` by `src/py_launch_blueprint/core/adapters/py_api.py` (`import requests`; `DEFAULT_TIMEOUT = 30`) and by the module docstring of `src/py_launch_blueprint/web/routers/projects.py`: *"Handlers are sync (``def``) because ``ProjectsService`` uses ``requests``; FastAPI runs them in its threadpool."* Its handlers are plain `def list_projects(...)` / `def get_project(...)`. ts is async end-to-end because JavaScript has no blocking I/O to choose — evidenced at the pin `cb1cbcb2` by `src/router.ts` (`export async function runCli(argv: string[], deps: CliDeps): Promise<number>`) and `src/lib/api.ts` (`async function request(path, params?)` awaiting `options.fetchImpl`). The prompt's own Context records that `TS_PORT_DECISIONS.md` has no entry choosing async, "there was no sync option to reject". **So neither precedent transfers as a decision; what transfers is py's *shape* — a synchronous core with a bridged async web tier — which is a real architectural pattern, and ts's *absence* of a choice, which is not.**

What must agree across py, ts and rs: that one use-case layer serves both front ends, and that the web tier is a thin adapter. What may vary: whether the functions in that layer block.

**Observable acceptance criteria**

These are requirements on the template P03 builds. Criteria 1–5 were **executed in this run against throwaway probe packages** (not against the template, which does not exist); criteria 6–8 are **proposed** and are P03's to demonstrate.

1. **The default build carries no async runtime.** *Observable, executed:* in a package whose non-optional dependencies are the selected HTTP client plus `serde`/`serde_json`, `cargo tree -i tokio -e normal` fails to find `tokio`, and `cargo tree -i tokio -e normal --features web` finds it.
2. **The `web` feature's `dep:tokio` clause remains legal.** *Observable, executed:* a manifest declaring `web = ["dep:tokio"]` against a **non-optional** `tokio` fails to parse with `feature 'web' includes 'dep:tokio', but 'tokio' is not an optional dependency`. R69's owner-accepted owned value uses exactly that clause, so this criterion is the mechanical test of whether an execution-model choice is compatible with R69 at all.
3. **R01's port stays dyn compatible without a macro.** *Observable, executed:* a trait with a native `async fn` method fails erasure with `error[E0038]: the trait ... is not dyn compatible` on rustc 1.98.0; the same trait under `#[async_trait::async_trait]` compiles.
4. **The CLI completes a real HTTPS round trip with the selected client.** *Observable, executed:* the probe binary performs `GET https://example.com/` and prints the body length (559 bytes).
5. **The web adapter can call the synchronous port from inside an axum-shaped runtime.** *Observable, executed:* `rt.block_on(async { tokio::task::spawn_blocking(|| ureq::get(..).call()..).await.unwrap() })` returns the same 559 bytes.
6. **The CLI entry point is a synchronous `fn main`.** *Observable, proposed:* `src/main.rs` contains `fn main() -> ExitCode`, not `async fn main`, and no `#[tokio::main]` attribute appears outside the `web`-gated serve binary.
7. **No function in the library crate's public surface is `async`.** *Observable, proposed:* `cargo public-api` (R04's tool) output contains no `async fn`; or, weaker, `cargo doc` shows no `impl Future` return types on the port or the service.
8. **Feature-off and feature-on both build and test on both CI runners.** *Observable, proposed:* `cargo test` and `cargo test --features web` both pass on `ubuntu-latest` and `macos-latest` (R11 owns the job shape).

**Architectural alternatives, compared before any crate was weighed**

| # | Alternative | Shape | Verdict |
|---|---|---|---|
| **A** | **Synchronous core, async only inside the `web` feature** | Library and CLI are blocking `fn`; the `web` feature adds `axum` + `tokio`; handlers call the blocking port through `tokio::task::spawn_blocking` | **Selected.** The direct Rust analogue of py's shape, and the only alternative that leaves R69's and R01's owner-accepted values untouched. Cost and behaviour measured below. |
| **B** | **Async core end-to-end** (ts's shape) | Port methods are `async fn` (boxed by `async-trait` for dyn compatibility), `reqwest` async client, `tokio` non-optional, CLI entry is `#[tokio::main]` | **Rejected**, on measured cost (2.4× default dependencies, 2.3× clean release build, 2.1× release binary) plus two hard consequences: it makes `tokio` non-optional, which **breaks R69's owned `web = ["dep:axum", "dep:tokio"]` string at manifest-parse time**, and it forces `async-trait` into R01's accepted port, which R01 declares "no `async fn`". Ranked runner-up. |
| **C** | **Async core with a synchronous CLI façade** (the LOW question) | Library is `async fn`; the CLI wraps each call in a lazily built current-thread runtime's `block_on`; the web feature awaits directly | **Rejected**, though it is a real and documented pattern (tokio's *Bridging with sync code*). It keeps every cost of B (tokio non-optional; `async-trait` in the port) and adds a footgun this run reproduced: `block_on` called from inside a runtime panics with *"Cannot start a runtime from within a runtime."* A library that exposes only `block_on` wrappers is therefore unusable from its own web feature, so it must expose **both** shapes — two public surfaces for one operation. |
| **D** | **Synchronous core with a synchronous, thread-per-request web framework** (no executor at all) | `rouille`/`tiny_http`-style server instead of axum | **Rejected, and not this item's to choose.** R69 (owner-accepted) already selected `axum` 0.8.9. Independently, all three sync-first candidates fail the maintenance rubric (figures in member 3). |
| **E** | **Synchronous core, but with a runtime-embedding "blocking" client** (`reqwest::blocking`) | Library is blocking `fn`, but the client spawns its own background tokio runtime | **Rejected as the default**, kept as member 2's ranked runner-up. It gives the sync *API* without the sync *dependency profile*: `cargo tree -i tokio` shows tokio in the tree through `hyper`/`hyper-util`/`tokio-rustls`/`tower`, so `tokio` cannot be optional and criterion 2 fails exactly as in B. |

**The measured evidence**

Two probe families were built, run and deleted under a directory created inside `$TMPDIR` for this run. **This is a research programme: the template does not exist and P03 builds it. No template code was written.** Each probe package contained one `Cargo.toml` and one `src/main.rs`.

**Family 1 — one HTTPS GET, five clients.** Workload: a single `GET https://example.com/` over TLS, cold process, no keep-alive reuse, body read to a `String` and its length printed. Configuration: `edition = "2024"`, `rust-version = "1.96"`, default `[profile.release]` (no LTO, default `codegen-units`), `--release`. Instrumentation: dependency count from `cargo tree --prefix none -e normal | sed 's/ (\*)$//' | awk 'NF' | sort -u | wc -l` (**this count includes the probe package itself**, so `p_base` = 1); wall-clock clean release build measured with `date +%s` around `cargo build --release -q` after `cargo clean`; binary size from `stat -f %z target/release/<name>`. Single run each, on one machine — these are order-of-magnitude comparisons, not benchmarks, and no latency or throughput claim is made from them.

| Probe | Client configuration | Unique normal deps (incl. root) | Clean `--release` build, s | Release binary, bytes | Real GET result |
|---|---|---|---|---|---|
| `p_base` | none (`fn main(){println!("ok")}`) | 1 | 0 | 433,712 | n/a |
| `p_ureq` | `ureq = "3.4.2"` (default `rustls` + `gzip`) | 28 | 18 | 2,704,896 | 559 bytes |
| `p_ureq_native` | `ureq` `default-features = false`, `native-tls` + `gzip` | 36 | not built | — | n/a |
| `p_reqwest_blocking` | `reqwest 0.13.5` `default-features = false`, `blocking`+`rustls`+`json` | 90 | 48 | 5,586,720 | 559 bytes |
| `p_reqwest_async_ct` | `reqwest 0.13.5` async + `tokio 1.53.1` (`rt`,`macros`), `#[tokio::main(flavor="current_thread")]` | 89 | 56 | 5,528,272 | 559 bytes |
| `p_reqwest_async_mt` | `reqwest 0.13.5` async + `tokio 1.53.1` (R69's six features), `#[tokio::main]` | 91 | 59 | 5,694,352 | 559 bytes |

Binary name beside each count: the binaries measured are `p_base`, `p_ureq`, `p_reqwest_blocking`, `p_reqwest_async_ct`, `p_reqwest_async_mt` respectively, each the sole `[[bin]]` of its package. All four network probes printed `559`.

**Family 2 — the template's actual shape.** Two packages, each with a `web = [...]` feature carrying `axum = { version = "0.8.9", optional = true }`, matching R69's owned value as closely as a probe can.

| Scenario | Non-optional deps declared | Feature-off unique normal deps | Feature-off clean release build, s | Feature-on unique normal deps | Feature-on clean release build, s | `tokio` in the feature-off tree? |
|---|---|---|---|---|---|---|
| `p_scen_sync` (alternative A) | `ureq 3.4.2`, `serde 1.0.229` (`derive`), `serde_json 1.0.151`; `web = ["dep:axum","dep:tokio"]` with `tokio 1.53.1` optional at R69's six features | **38** | **19** | **71** | **21** | **No** (`cargo tree -i tokio -e normal` finds nothing) |
| `p_scen_async` (alternative B) | `reqwest 0.13.5` (`rustls`,`json`), `tokio 1.53.1` at R69's six features (**non-optional**), `async-trait 0.1.92`, `serde`, `serde_json`; `web = ["dep:axum"]` | **93** | **43** | **101** | **48** | **Yes** |

The asymmetry is the finding: **turning the optional web feature on costs the synchronous template 33 extra crates; adopting the asynchronous model costs it 55 extra crates in every build, including the default one that has no web service at all.**

**Family 3 — behaviour probes.** Each is a statement about the language or a crate, reproduced rather than recalled.

| Probe | Command / shape | Observed |
|---|---|---|
| Manifest legality | `web = ["dep:tokio"]` with `tokio` **not** optional, then `cargo check` | `error: failed to parse manifest … Caused by: feature 'web' includes 'dep:tokio', but 'tokio' is not an optional dependency` |
| Dyn compatibility | `pub trait NativeAsyncPort: Send + Sync { async fn list(&self) -> Vec<String>; }` erased to `Arc<dyn NativeAsyncPort>` | `error[E0038]: the trait 'NativeAsyncPort' is not dyn compatible` on rustc 1.98.0. The same trait under `#[async_trait::async_trait]` erases and `cargo check` finishes clean; `async-trait` adds **6** unique normal deps (incl. root) — itself plus `proc-macro2`, `quote`, `syn`, `unicode-ident`. |
| Sync `main` over an async core (alternative C, happy path) | `Builder::new_current_thread().enable_all().build()?.block_on(async { … })` from a plain `fn` | works; returns the value |
| Sync `main` over an async core (alternative C, footgun) | the same helper called from inside `Runtime::block_on` | **panics**: `Cannot start a runtime from within a runtime. This happens because a function (like 'block_on') attempted to block the current thread while the thread is being used to drive asynchronous tasks.` |
| The bridge (alternative A's web path) | `rt.block_on(async { tokio::task::spawn_blocking(\|\| ureq::get("https://example.com/").call()…).await.unwrap() })` on a multi-thread runtime | works; 559 bytes |
| `reqwest::blocking` inside a runtime | direct call on a multi-thread runtime worker, and on a current-thread runtime | **no panic in either case**; both returned 559 bytes — see the documentation discrepancy below |

**Documentation discrepancy, reported rather than smoothed over.** `https://docs.rs/reqwest/0.13.5/reqwest/blocking/index.html` (retrieved 2026-09-17) states: *"the functionality in `reqwest::blocking` must not be executed within an async runtime, or it will panic when attempting to block. If calling directly from an async function, consider using an async `reqwest::Client` instead. If the immediate context is only synchronous, but a transitive caller is async, consider changing that caller to use `tokio::task::spawn_blocking` around the calls that need to block."* **In this run, reqwest 0.13.5 did not panic** when called directly on either a multi-thread or a current-thread tokio runtime worker (probe `p_blockpanic`, rustc 1.98.0, macOS arm64); both calls completed. The observed behaviour is consistent with the blocking client owning a dedicated background thread, so that the caller blocks on a channel receive rather than on a nested `block_on` — but that is an inference from the outcome, not something this run inspected in reqwest's source, and it is not asserted as fact. **The operational hazard the docs warn about is still real** — the call occupies a runtime worker thread for the whole round trip, which starves the executor under concurrency — and `spawn_blocking` is still the right wrapper. But the specific claim "it will panic" did not reproduce at this version, and this report does not repeat it as fact. Nothing in this report's recommendation depends on that claim either way.

**Reconciliation with the owner-supplied reference architecture**

`inputs/owner-reference-axum-companion-stack-2026-09-16.md` (= `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, owner decision 11 of 2026-09-16) is an owner-supplied research **input**, not a binding standard and not a pre-decision; owner-fixed parameters override anything in it, and its own caveat records that its code patterns were *"compiled in my head, not against the toolchain"*. Its overlap map names this item once: *"R05 — async model"*. Every row below was re-verified at a primary source rather than taken from the document.

**First, a naming correction.** The phrase **"tokio throughout" does not appear in the owner document**; `grep -n -i "throughout"` over the file returns exactly one hit, in the Caveats section, and it is about rustls (*"prefer rustls features throughout"*). "Level One, `tokio` throughout" is **R69's own overlap-map label** for the document's *"Level One — what Axum + tower-http already give you"* paragraph plus its `tokio = { version = "1", features = ["full"] }` line (`research/topics/69-web-framework-stack/DECISION.md` line 2204, read 2026-09-16). This report reconciles the document's rows, and treats "tokio throughout" as R69's label rather than as a quotation.

| # | Row in the owner document (with its location) | Disposition |
|---|---|---|
| R05-1 | **Level One / shared core**: "axum 0.8.9 + axum-extra 0.12.6 on tokio 1 / hyper 1 / tower 0.5 / tower-http 0.6 / http 1" (TL;DR, line 31) — read as: the whole application lives in one tokio world | **Differ, with ground.** Agree for the **web surface**, which R69 already settled. Differ on the scope: this report confines that world to the `web` feature and keeps the library and CLI outside it. **Ground:** the document describes a service that is *always* a web service on Cloud Run; this template's web surface is an off-by-default Cargo feature (F017 `ADOPT`; R69's owned `web-extra-surface`), so its default build has no server, no port to bind and no concurrency to schedule. Measured cost of extending the tokio world to the default build: **93 vs 38** unique normal dependencies, **43 s vs 19 s** clean release build (Family-2 probe, this run). Owner-fixed parameters are untouched. |
| R05-2 | **`tokio = { version = "1", features = ["full"] }`** (reference `Cargo.toml`, line 139) | **Hand-off to R69 for the feature set; disposed here only as to scope.** R69 revision 9 row 9 already dispositioned the feature list as *"Differs: ground"* and selected six features (`rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`) instead of `full`. Verified independently at the release tag, `GET https://api.github.com/repos/tokio-rs/tokio/contents/tokio/Cargo.toml?ref=tokio-1.53.1` (retrieved 2026-09-17): `default = []` and `full = ["fs","io-util","io-std","macros","net","parking_lot","process","rt","rt-multi-thread","signal","sync","time"]` — twelve features, confirming R69's arithmetic. This report adds one fact R69's row did not need: **`tokio` is optional in R69's owned value, and it can only stay optional if this item resolves synchronous** (probe: `dep:tokio` on a non-optional dependency is a manifest parse error). |
| R05-3 | **`#[tokio::main] async fn main()`** bootstrap (Key Wiring Patterns, line 322) | **Split: agree for one binary, differ for the other.** Agree for R69's `web`-gated `<app>-serve` binary, whose entry point is the web server's. Differ for the **CLI binary**, which stays a synchronous `fn main() -> ExitCode` — required by R67's owner-accepted contract that "`main` returns `ExitCode` and does not call `process::exit` on the error path", and unnecessary for a process whose work is one blocking round trip. **Ground:** tokio's own bridging guide recommends the *current-thread* runtime for exactly this shape (*"For our use-case, we are only going to be doing one thing at the time, so we won't gain anything by running multiple threads"*, `https://tokio.rs/tokio/topics/bridging`, retrieved 2026-09-17) — and the synchronous core removes even that. |
| R05-4 | **Variant A (HTMX) / Variant B (SPA)**, and the recommendation to default to Variant B (TL;DR; Recommendations 2–4) | **Hand-off; no P02 item.** R69's overlap map records Variants A/B as *"No P02 item; pending owner scoping"*, and owner decision 11 lists them among the rows it does not admit. This item's disposition of the variant rows is narrow and is the only part that is R05's: **both variants' handler heads are `async fn` axum handlers** (`async fn tasks(...)`, `async fn create(...)`, `async fn ws(...)` at lines 288, 305, 310), and **nothing in either variant constrains what those handlers call into**. Under this report's recommendation they call the blocking port through `tokio::task::spawn_blocking`; under an async R05 they would await it. The variants are therefore **compatible with either answer**, and neither is evidence for one. |
| R05-5 | **Dependency-tree hygiene**: "choose **one** rustls crypto provider (aws-lc-rs *or* ring) across sqlx, HTTP clients, and the GCP SDK to avoid duplicate crypto providers" (Caveats) | **Agree on the principle; the provider choice itself is an unowned gap, named rather than papered over.** Verified in this run: with the recommended stack (`ureq` default `rustls` + `axum` 0.8.9, feature on) the tree contains exactly one provider — `ring v0.17.14`, with `rustls v0.23.45`, `rustls-pki-types v1.15.1`, `rustls-webpki v0.103.15` and **no** `aws-lc-rs`, **no** `openssl`, **no** `native-tls`. Under alternative B the single provider is instead `aws-lc-rs v1.18.1` + `aws-lc-sys v0.45.0` (a C library built at compile time) plus `rustls-platform-verifier v0.7.0`, because `reqwest` 0.13's `default-tls` now resolves to `rustls` with the aws-lc-rs provider (verified at the release tag, `GET https://api.github.com/repos/seanmonstar/reqwest/contents/Cargo.toml?ref=v0.13.5`, retrieved 2026-09-17: `default = ["default-tls","charset","http2","system-proxy"]`, `default-tls = ["rustls"]`, `rustls = ["__rustls-aws-lc-rs", "dep:rustls-platform-verifier", "__rustls"]`). **No research item in `research/CLAUDE.md` owns "TLS backend / crypto provider"** — this report names that as an open scoping question rather than deciding it, and records that the recommendation below happens to satisfy the one-provider rule. |
| R05-6 | **`sqlx = { … "runtime-tokio-rustls" … }`** and every other row of the reference stack (C1, C2, C5–C15, the Cloud Run runbook) | **Out of scope for this item; already dispositioned by R69.** They bear on this item only through the general observation that every one of them presupposes a permanently running async service, which this template's default build is not. |

**`BASELINE-REVIEW`**

`BASELINE-REVIEW: F022 — principle: the async runtime is selected for this template regardless of how F016 resolves, because the optional `web` feature needs an executor either way, so "moot if F016 resolves sync" misstates the row's scope — proposed change: restate F022 as "async runtime selection for any async surface", record it as **answered by R69** (tokio 1.53.1, features rt-multi-thread, net, signal, macros, time, sync, optional, inside the `web` feature) and mark it *inapplicable to the CLI and library* under a synchronous F016, rather than *moot* — evidence: R69's owner-accepted owned `web-extra-surface` value already names that tokio version and feature set (`research/topics/69-web-framework-stack/DECISION.md` `## Parameters`, read 2026-09-16), R69 states "`rt-multi-thread` is required in both cases" (line 1626), and this run measured `tokio v1.53.1` in the feature-on tree of the synchronous scenario probe (Family-2, 2026-09-17). Affected items: the F022 row in `docs/port/COMMONALITY.md`; no other item's value changes, and this report does not edit the ledger.`

No other baseline is challenged. R01's and R69's accepted values are **preserved, not challenged**, by the recommendation below.

**Minimal realistic example, and how its behaviour is verified**

The smallest arrangement that exercises the principle, expressed as the template's shape rather than as code to be copied:

- `src/lib.rs` — `pub trait ProjectsPort: Send + Sync { fn list(&self, q: &ProjectQuery) -> Result<Vec<Project>, PortError>; fn get(&self, id: &str) -> Result<Option<Project>, PortError>; }` — exactly R01's accepted shape, **unchanged**, with no `async fn` and therefore no `async-trait`.
- `src/adapters/http.rs` — the production adapter holding a `ureq::Agent` built once (connection pool, timeouts, the `Authorization`/`Accept` headers py's `PyClient.__init__` sets), implementing `ProjectsPort` with ordinary blocking method bodies.
- `src/main.rs` — `fn main() -> std::process::ExitCode`, no runtime, no `#[tokio::main]`.
- `src/web/mod.rs` (behind `#[cfg(feature = "web")]`) — axum handlers that are `async fn`, each holding R69's `Arc<ErasedProjectsService>` out of `AppState` and calling it as `tokio::task::spawn_blocking(move || service.list(&q)).await`. The `<app>-serve` binary keeps `#[tokio::main]`.

Executable acceptance check, **proposed** (P03's to run against the real template): `cargo tree -i tokio -e normal` must fail; `cargo tree -i tokio -e normal --features web` must succeed; `cargo test` and `cargo test --features web` must both pass on both runners; a `#[test]` that boots the router on an ephemeral port and issues a real request must decode into the library's own `Vec<Project>`. **Executed in this run** (against probes, not the template): every row of Families 1–3 above.

---

### Recommendation

**Alternative A — a synchronous, blocking execution model for the library crate and the CLI, with async confined to the optional `web` feature.**

One stack:

| Member | Mechanism | Version |
|---|---|---|
| **Execution model** | Synchronous, blocking `fn` throughout the library crate and the CLI binary; no executor in the default dependency tree; `fn main() -> ExitCode` | language feature, no crate |
| **HTTP client** | **`ureq`** with its default features (`rustls` → `rustls-no-provider` + `_ring` + `rustls-webpki-roots`, and `gzip`) plus `json`; one `ureq::Agent` built at the composition root and reused | **3.4.2** (2026-09-13) |
| **Web-adapter bridge** | `tokio::task::spawn_blocking` inside each axum handler, wrapping the call into R01's synchronous port | `tokio` **1.53.1** — **R69's member, assumed not re-selected** |
| **CLI-side concurrency** | `std::thread::scope` when a command must fan out; no `rayon`, no runtime | language feature, no crate |

`async-trait` **does not** join the stack: R01's conditional clause ("joins the stack only if R05 selects an async I/O boundary") is **not triggered**, and R01's port keeps its accepted "no `async fn`" form.

Settled ledger rows: **F016** (sync end-to-end for the library and CLI, async inside the `web` feature). **F022** is answered by R69 for the `web` feature and is inapplicable to the CLI and library — see the `BASELINE-REVIEW` line above.

---

### Members

#### Execution model — synchronous core, async confined to the `web` feature

##### Landscape
Category: how the driven-I/O boundary executes. Bin 1 (built-in): blocking `std::io` + `std::thread` — no crate, no executor, and the only option in the field that adds nothing to the dependency tree. Bin 2 (established): `async fn` + `tokio`, the shape `axum`, `hyper`, `tower` and `reqwest` all assume. Bin 3 (up-and-comer): `async fn` + `smol`, and thread-per-core runtimes (`monoio`, `compio`, `glommio`) that are Linux-server-shaped and out of fit for a two-OS CLI. There is no fourth shape: Rust offers blocking calls, or futures plus an executor.

##### Principles and implementation
The principle this member must preserve is that both front ends reach one use-case layer through one port, on both target operating systems, within the MSRV floor. A synchronous core preserves it directly: the port is an ordinary trait, the CLI calls it on its own thread, and the web adapter calls it from tokio's blocking pool. The ecosystem-specific adaptation is that Rust, unlike CPython, gives the bridge a *typed* form — `tokio::task::spawn_blocking` returns a `JoinHandle<T>` that the handler awaits — rather than FastAPI's implicit "sync `def` gets run in the threadpool" convention. The py precedent is therefore honoured in substance and improved in explicitness: in Rust the bridge is visible at the call site, so a reviewer can see which calls block.

##### Dominant choice
**Asynchronous** is the dominant choice in the Rust *server* ecosystem and in the *library* ecosystem (`tokio` 224.5 M recent downloads, 72,755 reverse dependencies; `reqwest` 183.0 M recent downloads — all `GET https://crates.io/api/v1/crates/<name>` and `/reverse_dependencies`, retrieved 2026-09-17). It is **not** dominant in the Rust CLI ecosystem: of the eight well-regarded CLIs surveyed above, `cargo` uses neither tokio nor reqwest, `xh` and `rustup` call HTTP through `reqwest::blocking`, `cargo-deny`, `nextest-runner` and `wasm-pack` use `ureq`, `hyperfine` does no I/O, and only `uv` is async end-to-end. Dominance is therefore reported per-context and is not, on its own, treated as evidence — per the mandate.

##### Qualified shortlist
1. **Synchronous core, async web feature** (this member's recommendation) — passes every gate; measured cost above.
2. **Async core end-to-end** — passes every gate; costs 55 extra default dependencies, 24 s of extra clean release build and ~3.0 MB of extra binary, and breaks R69's owned value's `dep:tokio` clause.
3. **Async core with a sync CLI façade** — passes every gate; keeps all of (2)'s costs and adds the nested-`block_on` panic and a doubled public surface.

##### Excluded by gate
None. Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Gates 2–6 are crate-level and this member selects no crate; gate 5 (default features and async-runtime coupling) is the substance of the member and is stated in *Fit* below; gate 6 (binary size and compile time) is measured rather than qualitative, in Family 1 and Family 2.

##### Up-and-comers
`async fn` in traits (stable since Rust 1.75, per that release's announcement cited under `### Landscape`) and return-position `impl Trait` in traits are the live language work that would, in time, remove `async-trait` from the async branch's cost. They do **not** yet remove it for this template: verified on rustc 1.98.0 in this run, a trait with a native `async fn` is still not dyn compatible (`E0038`), and R01's accepted seam is a trait object. `dyn`-compatible async traits remain an open Rust language problem; nothing in this landscape changes on that account before this decision's re-verify horizon.

##### Fit for this template
The template is a **CLI + library, with a web service behind an off-by-default feature** (F017 `ADOPT`; R69's `web-extra-surface`). The prompt states its workload directly: "most invocations are a single HTTP round-trip rather than many concurrent tasks". A synchronous core matches that workload exactly — one thread, one socket, no scheduler — and keeps the cost of the optional capability inside the optional capability. Async-runtime coupling, stated per gate 5: **the default build has none**; the `web` feature couples to `tokio` 1.53.1 at R69's six features, and to nothing else.

##### Recommendation
Synchronous, blocking `fn` in the library crate and the CLI binary. `fn main() -> ExitCode`. The `web` feature adds the only async surface.

##### Ranked runner-up
**Async core end-to-end** (alternative B). It is the correct answer if the template's identity changes — if the web service becomes the primary surface rather than an optional feature, or if a CLI command must fan out to tens of upstream calls per invocation. Under it, `tokio` becomes a non-optional dependency, R69's owned `web` value must drop `"dep:tokio"`, and R01's `async-trait 0.1.92` clause fires.

##### Tradeoffs
- **Gained:** 38 instead of 93 default dependencies; 19 s instead of 43 s clean release build; ~2.70 MB instead of ~5.69 MB release binary; no colored-function split in the public API; R01's port unchanged; R69's owned value unchanged; no `async-trait` macro between a caller and a port method.
- **Given up:** two I/O stacks coexist when `web` is on — `ureq`'s blocking sockets for outbound calls and `hyper`/`tokio` for inbound ones — with no shared connection pool and two independent timeout configurations. A handler's upstream call occupies one thread from tokio's blocking pool for its whole duration; that pool's default ceiling is 512 threads and idle threads exit after 10 s (`https://docs.rs/tokio/1.53.1/tokio/runtime/struct.Builder.html`, `max_blocking_threads` and `thread_keep_alive`, retrieved 2026-09-17), so concurrent upstream calls are capped at 512 and each costs a thread stack. For a template that is an acceptable and documentable ceiling; for a high-fan-out production service it is not, which is what the runner-up is for.
- **Not given up:** streaming, HTTP/2 and proxies are all available from `ureq` 3 (`http2` is not among its features; see *Confidence* for the one capability actually lost).

##### Parameters
This member registers no parameter. It **assumes** `web-extra-surface` (R69, published) and `http-transport-injection-seam` (R01, published) at their registry values, both of which it leaves unchanged. No `CONFLICT:` line.

##### Migration implications
Not a migration: the template does not exist. In P03's template, this member fixes that `src/lib.rs`, `src/services/*.rs`, `src/ports.rs`, `src/adapters/*.rs` and `src/main.rs` contain no `async` keyword, and that `src/web/**` is the only tree that does.

##### Validation strategy
Executed in this run (against probes): the Family-2 dependency counts and build times; `cargo tree -i tokio -e normal` absent feature-off and present feature-on; the `dep:tokio` manifest-parse error; the `E0038` dyn-compatibility result. Proposed for P03: acceptance criteria 6, 7 and 8 above.

##### Confidence & re-verify trigger
**High.** The decisive facts are mechanical (a manifest parse error, a compiler error, a dependency tree) rather than judgemental. Re-verify when the `web` feature stops being off-by-default, when a CLI command is specified that must issue more than a handful of concurrent upstream calls, when `dyn`-compatible native `async fn` in traits stabilises on a version within the MSRV floor, when R69 republishes its owned `web-extra-surface` value, or by **2027-03-17**, whichever comes first.

##### Sources
`research/topics/69-web-framework-stack/DECISION.md` (revision 9, lines 799, 1591, 1623, 2204), read 2026-09-16 · `research/topics/01-ports-and-adapters-seam/DECISION.md` (revision 3, the Decision table and the `async-trait` clause), read 2026-09-16 · `docs/port/COMMONALITY.md` rows F016, F017, F022, read 2026-09-16 · `docs/port/PARAMETERS.md`, read 2026-09-16 · `https://tokio.rs/tokio/topics/bridging`, retrieved 2026-09-17 · `https://docs.rs/tokio/1.53.1/tokio/runtime/struct.Builder.html`, retrieved 2026-09-17 · `GET https://crates.io/api/v1/crates/tokio` and `/reverse_dependencies`, retrieved 2026-09-17 · probe families 1–3, this run, 2026-09-17.

---

#### HTTP client — `ureq` 3.4.2

##### Landscape
Category: the crate that carries the CLI's outbound HTTP. Bin 1 (built-in): none — `std` has no HTTP client, so a crate is unavoidable. Bin 2 (established): `reqwest` (async, with an optional blocking façade), `ureq` (blocking), the `curl` crate (blocking, C binding, used by `cargo` itself). Bin 3 (up-and-comer/niche): `attohttpc`, `minreq`, `isahc`.

##### Principles and implementation
The principle from both sources is a **single request wrapper owning URL construction, headers, timeout and failure translation**, injected rather than global. py: `src/py_launch_blueprint/core/adapters/py_api.py` at pin `b08bccfb` holds a `requests` session with `DEFAULT_TIMEOUT = 30`, validates every response into private `_*` boundary models before anything reaches the domain, returns `None` for absence and raises `APIError` on transport failure. ts: `src/lib/api.ts` at pin `cb1cbcb2` has `async function request(path, params?)` wrapping an **injected** `options.fetchImpl` with a `Bearer` header, an `Accept` header, `AbortSignal.timeout(timeoutMs)`, and translation of 401/403 into `AuthError`. Both principles survive unchanged in Rust behind R01's port: the client crate lives entirely inside the adapter, is never named by the use case, and its errors map to R67's `RSLB102` (transport) / `RSLB103` (remote-API failure) / `RSLB401`–`RSLB402` (credentials) codes. `ureq` supplies each piece: `ureq::Agent` is the reusable session, `AgentConfig` carries timeouts, and its error enum distinguishes transport failure from an HTTP status.

##### Dominant choice
**`reqwest`** is the dominant HTTP client crate overall: 183,008,208 recent downloads, 720,508,363 all-time, **29,543** reverse dependencies; newest non-yanked **0.13.5** (2026-09-08), `rust_version` **1.85.0**, licence `MIT OR Apache-2.0` (`GET https://crates.io/api/v1/crates/reqwest`, `/versions`, `/reverse_dependencies`, retrieved 2026-09-17). GitHub `seanmonstar/reqwest`: **11,824** stars, `archived: false`, `pushed_at` 2026-09-14; **367** open issues (`GET https://api.github.com/repos/seanmonstar/reqwest`, `GET https://api.github.com/search/issues?q=repo:seanmonstar/reqwest+is:issue+is:open`, `total_count`, retrieved 2026-09-17). Dominance is recorded and then set against fit, per the mandate.

##### Qualified shortlist

| Crate | Version (newest non-yanked) + date | 90-day / all-time downloads | Reverse deps | Stars / archived / pushed | Open issues | Declared `rust_version` | Licence | Gates |
|---|---|---|---|---|---|---|---|---|
| **`ureq`** | **3.4.2**, 2026-09-13 | 58,361,888 / 202,969,771 | 3,718 | 2,193 / false / 2026-09-16 | 30 | **1.85** | MIT OR Apache-2.0 | 1 inapplicable; 2 pass (1.85 ≤ 1.96); 3 pass (no advisory page — `https://rustsec.org/packages/ureq.html` returns **HTTP 404**, i.e. no advisories ever filed); 4 see below; 5 stated below; 6 measured |
| `reqwest` (async) | 0.13.5, 2026-09-08 | 183,008,208 / 720,508,363 | 29,543 | 11,824 / false / 2026-09-14 | 367 | 1.85.0 | MIT OR Apache-2.0 | 1 inapplicable; 2 pass; 3 pass (`https://rustsec.org/packages/reqwest.html` → HTTP 404); 4 pass; 5 **couples to tokio unconditionally**; 6 measured |
| `reqwest` (`blocking`) | same crate/version | same | same | same | same | same | same | identical, **including the tokio coupling** — `blocking = [… "tokio/sync"]` in its own manifest, and `cargo tree -i tokio` shows `tokio v1.53.1` reached through `hyper`, `hyper-rustls`, `hyper-util`, `tokio-rustls` and `tower` |
| `curl` crate | (not a shortlist member — see *Excluded*) | — | — | — | — | — | — | — |

**Gate 4 (`ubuntu-latest`, `macos-latest`) per candidate, stated precisely.**
- `ureq`: its own CI at the 3.4.2 tag (`GET https://api.github.com/repos/algesten/ureq/contents/.github/workflows/test.yml?ref=3.4.2`, retrieved 2026-09-17) declares **seven `runs-on:` lines, all `ubuntu-latest`** — there is no macOS job and no Windows job. **This run supplies the missing leg directly**: `ureq` 3.4.2 was built and executed on macOS 26.4 `aarch64-apple-darwin` with rustc 1.98.0 and completed a real HTTPS GET (probe `p_ureq`, 559 bytes). Windows: `ureq` declares a `win-system-proxy` feature and `winreg` dependency, so Windows is supported by the crate; not required here.
- `reqwest`: its CI matrix (`.github/workflows/ci.yml`, retrieved 2026-09-17) includes `ubuntu-latest`, `ubuntu-24.04-arm`, `macOS-latest`, `windows-latest` and `windows-11-arm`. Also built and run on macOS in this run.
- Both pass gate 4; `ureq`'s pass rests on this run's execution plus the crate's Windows feature, not on its CI badge, and that distinction is stated rather than elided.

**Gate 3 `unsafe` posture.** `ureq`'s own crate declares `#![forbid(unsafe_code)]` (`GET https://api.github.com/repos/algesten/ureq/contents/src/lib.rs?ref=3.4.2`, line 524, read at the **release tag**, retrieved 2026-09-17) — no `unsafe` is possible in the crate itself; its transitive tree still contains `ring` and `libc`, which do use `unsafe`. `reqwest`'s `src/lib.rs` declares `#![deny(missing_docs)]`, `#![deny(missing_debug_implementations)]` and no `unsafe` lint (same endpoint shape, retrieved 2026-09-17), so its posture is "unsafe permitted, none audited here". `tokio`'s `src/lib.rs` declares `#![deny(unused_must_use, unsafe_op_in_unsafe_fn)]` — a runtime necessarily uses `unsafe`, and tokio's mitigations are `loom` and Miri in CI rather than a forbid.

**Gate 5 default features and runtime coupling.** `ureq` 3.4.2: `default = ["rustls", "gzip"]`, where `rustls = ["rustls-no-provider", "_ring", "rustls-webpki-roots"]` — so the default TLS is rustls with the **ring** provider and **bundled** webpki roots, needing no OpenSSL and no system trust store; `platform-verifier`, `native-tls`, `json`, `cookies`, `socks-proxy`, `win-system-proxy`, `charset`, `brotli` and `multipart` are all opt-in, and **the manifest contains no `http2` feature and no `h2` dependency at all** (`GET https://api.github.com/repos/algesten/ureq/contents/Cargo.toml?ref=3.4.2` — read at the **release tag**, not the default branch — retrieved 2026-09-17). **No async runtime coupling of any kind** — verified by tree. `reqwest` 0.13.5: `default = ["default-tls", "charset", "http2", "system-proxy"]` with `default-tls = ["rustls"]` and `rustls = ["__rustls-aws-lc-rs", "dep:rustls-platform-verifier", "__rustls"]`, so its default TLS is now rustls with the **aws-lc-rs** provider plus the platform verifier (a change worth noting against older guidance that reqwest defaults to `native-tls`/OpenSSL). Read at the **release tag** `GET https://api.github.com/repos/seanmonstar/reqwest/contents/Cargo.toml?ref=v0.13.5`, retrieved 2026-09-17, so the feature set is the published 0.13.5 one rather than the default branch's. Its `tokio` dependency is `tokio ^1.0`, **not optional** (`https://docs.rs/reqwest/0.13.5/reqwest/blocking/index.html` dependency panel, retrieved 2026-09-17).

**Gate 6 binary size and compile time, measured rather than asserted** (Family 1, binary names given): `p_ureq` 2,704,896 bytes / 18 s / 28 deps; `p_reqwest_blocking` 5,586,720 bytes / 48 s / 90 deps; `p_reqwest_async_mt` 5,694,352 bytes / 59 s / 91 deps; baseline `p_base` 433,712 bytes / 0 s / 1.

**Maintenance state by the rubric.** `ureq` — **active**: newest release 3.4.2 on 2026-09-13 (four days before retrieval), `pushed_at` 2026-09-16, 30 open issues, single maintainer organisation with a clear release cadence. `reqwest` — **active**: 0.13.5 on 2026-09-08, `pushed_at` 2026-09-14. Neither is `at-risk` or `dormant`; no unpatched advisory, no broken build on current stable (both built here), no maintainer notice.

**Issue responsiveness.** Method: `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=20`, pull requests filtered out by `.pull_request == null`, then up to the 10 most recently opened **issues** among that page; for each, `GET .../issues/<n>/comments?per_page=100` and the first comment whose `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose author is not the issue's own author. Retrieved 2026-09-17. **The sample is smaller than 10 for three of the four repositories** because the 20 most recent records were mostly pull requests — this is stated rather than padded.

| Repository | Issues sampled | Answered | Unanswered | Median days to first maintainer response |
|---|---|---|---|---|
| `algesten/ureq` | 4 | 2 | 2 | 4.08 |
| `seanmonstar/reqwest` | 7 | 1 | 6 | 0.09 |
| `tokio-rs/tokio` | 4 | 3 | 1 | 0.21 |
| `dtolnay/async-trait` | 10 | 6 | 4 | 0.37 |

Read honestly: `reqwest`'s median is fast but its **unanswered rate in the sample is 6 of 7**, which is the more informative figure for a project with 367 open issues; `ureq`'s median is slower but it answers a larger share and carries 30 open issues in total. Neither result is a gate failure and neither is decisive.

##### Excluded by gate
- **`async-std` 1.13.2** — **gate 3 failure**: `https://rustsec.org/packages/async-std.html` (retrieved 2026-09-17) lists **RUSTSEC-2025-0052**, dated 2025-08-24, `informational = "unmaintained"`, `patched = []`, titled *"async-std has been discontinued"*, recommending `smol` as the alternative. Maintenance state **dormant** by the rubric (a maintainer's own notice plus an open advisory). Not a client, listed here because it is the runtime a survey of this topic would otherwise shortlist.
- **`attohttpc` 0.31.0** — no gate failure, **excluded on fit**: it declares **no `rust_version`** (`GET https://crates.io/api/v1/crates/attohttpc/versions`, retrieved 2026-09-17), so gate 2 cannot be answered from published metadata without a tree resolution; 294 stars; 6,212,919 recent downloads against `ureq`'s 58.4 M. Its licence is MPL-2.0 — recorded as metadata only; **not** an exclusion, per the owner ruling.
- **`minreq` 3.0.0** — no gate failure, **excluded on fit**: 1,317,831 recent downloads, 255 stars, 5 open issues, `rust_version` 1.63, licence ISC. Deliberately minimal (it omits connection pooling and proxy support), which is the wrong trade for a template meant to be extended.
- **`isahc` 2.0.1** — **excluded on fit**: 1,200,401 recent downloads; libcurl-backed, so it inherits a C build dependency that `ureq`'s pure-Rust tree avoids, and its async surface is executor-agnostic in a way this template does not need.
- **`curl` crate** — **excluded on fit**, despite being `rust-lang/cargo`'s own choice: it binds libcurl, adding a C library and a system-dependency story (vendored vs system OpenSSL) across two operating systems that a pure-Rust `ureq` + `ring` tree does not have. Recorded prominently because it is the strongest evidence that the Rust project itself does not treat tokio as mandatory for a networked CLI.
- **`surf` 2.3.2** — **dormant**: newest non-yanked release 2021-11-01, 520,484 recent downloads (`GET https://crates.io/api/v1/crates/surf`, `/versions`, retrieved 2026-09-17). Its runtime story was `async-std`'s.

##### Up-and-comers
`ureq` 3.x itself is the notable recent movement: the 3.0 line rebuilt the crate on a sans-I/O core (`ureq-proto`) with a new `Agent`/`AgentConfig` API, which is why its `rust_version` is a modern **1.85** rather than the 1.6x floors typical of the minimal-client bin. `hyper` 1's `client::conn` layer is the other up-and-comer in this space — a hand-rolled blocking client over it is possible but would re-implement redirects, proxies, pooling and body decoding, and is not proposed.

##### Fit for this template
Three fit arguments, in order of weight. **(1)** It is the only shortlisted client that keeps `tokio` out of the default tree, which is the sole mechanical requirement R69's owned `web = ["dep:axum", "dep:tokio"]` value places on this item. **(2)** Its cost profile matches a CLI that makes one round trip: 28 vs 90 dependencies and 2.70 vs 5.59 MB against the closest blocking alternative, for the same observable behaviour (both probes returned the same 559-byte body). **(3)** Its API maps one-to-one onto the two sources' request wrapper: a reusable `Agent` (py's session, ts's injected `fetchImpl`), configurable timeouts (py's `DEFAULT_TIMEOUT = 30`, ts's `AbortSignal.timeout`), and a transport-vs-status error split that R67's `RSLB102`/`RSLB103` taxonomy already expects.

##### Recommendation
**`ureq` 3.4.2**, default features (`rustls` with the ring provider and bundled webpki roots, plus `gzip`) with `json` added, constructed once as a `ureq::Agent` in the composition root and held by the production adapter. `default-features = false` is **not** used: the default set is already minimal and its rustls-with-ring choice is the one this template wants.

##### Ranked runner-up
**`reqwest` 0.13.5** — async, `default-features = false`, `features = ["rustls", "json"]`. It is the right client the moment the execution model flips to alternative B, and it is the better client on capability grounds alone (HTTP/2, streaming bodies, a `tower` middleware ecosystem, `reqwest-middleware` retries). The second runner-up is `reqwest` with `blocking`, which is what `rustup` and `xh` do; it is ranked below plain async `reqwest` because it pays the whole async dependency tree to obtain a synchronous API, and therefore gets the costs of B with the capabilities of A.

##### Tradeoffs
- **Gained:** 62 fewer crates than `reqwest::blocking` in the default tree; 2.88 MB smaller binary; 30 s faster clean release build; `#![forbid(unsafe_code)]` in the client crate itself; one rustls crypto provider (`ring`), no C toolchain requirement, no OpenSSL on either runner.
- **Given up:** **HTTP/2** — `ureq` 3.4.2's manifest at its release tag contains no `http2` feature and no `h2` dependency, so the CLI speaks HTTP/1.1 only, while `reqwest` enables `http2` by default. For a JSON API client this is a latency-and-multiplexing question, not a correctness one, and no upstream in the sources' scope requires HTTP/2 — but it is the one real capability lost and it is named here rather than buried. Also given up: `reqwest`'s middleware ecosystem, and a single shared TLS/connection-pool configuration between outbound calls and the inbound server when `web` is on.
- **Not given up:** proxies (`socks-proxy`, `win-system-proxy`), cookies, redirects, gzip/brotli, `platform-verifier` for OS trust stores — all available as `ureq` features.

##### Parameters
Registers no parameter. Assumes `msrv-policy`, `rust-edition`, `target-os-matrix`, `license` at their fixed values, and `web-extra-surface` and `http-transport-injection-seam` at their published values. No `CONFLICT:` line.

##### Migration implications
In P03's template: one line in `[dependencies]` (`ureq = { version = "3.4.2", features = ["json"] }`); one `ureq::Agent` field on the production adapter; the adapter's error-mapping arm translating `ureq::Error::StatusCode(401 | 403)` to R67's `RSLB401`/`RSLB402` and transport variants to `RSLB102`. Nothing in the library's public surface names `ureq`.

##### Validation strategy
Executed in this run: `p_ureq` built clean on rustc 1.98.0 / macOS arm64 and completed a real `GET https://example.com/`; `p_scen_sync` resolved with `tokio` absent from its default tree and present under `--features web`; the feature-on tree contains exactly one crypto provider (`ring v0.17.14`) and no `aws-lc-rs`, `openssl` or `native-tls`. Proposed for P03: a `wiremock`-style or `tiny_http`-style local fixture asserting the `Authorization`/`Accept` headers and the 30-second timeout, plus a `cargo deny check advisories` gate.

##### Confidence & re-verify trigger
**High** on the figures (all from the mandated endpoints on 2026-09-17), **medium-high** on the selection, because `ureq`'s macOS coverage rests on this run rather than on the project's CI and because HTTP/2 is a real capability gap. Re-verify when `ureq` publishes a 4.x line or an `http2` feature, when `ureq`'s CI adds or continues to omit a macOS job at the next MSRV floor advance past 1.96, when a first RustSec advisory is filed against `ureq` or `reqwest`, when this item's execution-model member is revisited, or by **2027-03-17**.

##### Sources
`GET https://crates.io/api/v1/crates/{ureq,reqwest,attohttpc,minreq,isahc,surf,async-std}` and `/versions` and `/reverse_dependencies`, retrieved 2026-09-17 · `GET https://api.github.com/repos/{algesten/ureq,seanmonstar/reqwest}` and `/contents/Cargo.toml`, `/contents/src/lib.rs`, `/contents/.github/workflows/*`, retrieved 2026-09-17 · `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, retrieved 2026-09-17 · `https://rustsec.org/packages/{ureq,reqwest,async-std,tokio,hyper}.html`, retrieved 2026-09-17 · `https://docs.rs/reqwest/0.13.5/reqwest/blocking/index.html`, retrieved 2026-09-17 · py `src/py_launch_blueprint/core/adapters/py_api.py` at pin `b08bccfb`, read 2026-09-16 · ts `src/lib/api.ts` at pin `cb1cbcb2`, read 2026-09-16 · probe family 1 and 2, this run.

---

#### Web-adapter bridge — `tokio::task::spawn_blocking`

##### Landscape
Category: how an async axum handler calls a synchronous port. Bin 1 (built-in): none — the bridge is a runtime facility, not a language one. Bin 2 (established): `tokio::task::spawn_blocking` (the blocking pool) and `tokio::task::block_in_place` (a multi-thread-runtime-only escape that converts the current worker into a blocking thread). Bin 3 (up-and-comer): `blocking` crate (smol's thread-pool bridge) — inapplicable, because R69 fixed the runtime as tokio. The sync-first web frameworks that would remove the need for a bridge altogether are surveyed under *Excluded by gate* because the HIGH question asks about them explicitly, even though R69 has already settled the framework.

##### Principles and implementation
The principle is py's, stated in its own words at the pin: *"Handlers are sync (`def`) because `ProjectsService` uses `requests`; FastAPI runs them in its threadpool"* (`src/py_launch_blueprint/web/routers/projects.py`, pin `b08bccfb`). The behaviour to preserve is that **a blocking call in a request handler must not occupy the event loop**. FastAPI does this implicitly, by inspecting whether the handler is `def` or `async def`. Rust has no such inspection — an axum handler is always `async fn` — so the bridge must be **explicit at the call site**. That is a better fit for Rust, not a worse one: the reviewer can see which calls block, and the compiler enforces the `Send + 'static` bound on the closure, which R01's `Arc<dyn ProjectsPort>` (declared `Send + Sync`) already satisfies.

##### Dominant choice
**`tokio::task::spawn_blocking`.** It is the facility tokio's own documentation names for this exact case, and the one `reqwest`'s blocking-module documentation points callers at: *"If the immediate context is only synchronous, but a transitive caller is async, consider changing that caller to use `tokio::task::spawn_blocking` around the calls that need to block"* (`https://docs.rs/reqwest/0.13.5/reqwest/blocking/index.html`, retrieved 2026-09-17).

##### Qualified shortlist
1. **`spawn_blocking`** — moves the closure onto tokio's blocking pool, returns `JoinHandle<T>`, frees the worker immediately. Requires tokio's `rt` feature, which R69's `rt-multi-thread` implies. Pool ceiling 512 threads, idle timeout 10 s (`https://docs.rs/tokio/1.53.1/tokio/runtime/struct.Builder.html`, retrieved 2026-09-17).
2. **`block_in_place`** — *"Runs the provided blocking function on the current thread without blocking the executor"*, handing this worker's queued tasks to other workers. Cheaper (no task hand-off to the blocking pool, no `'static` bound) but, in the maintainers' own words, *"This function panics if called from a `current_thread` runtime"* (`https://docs.rs/tokio/1.53.1/tokio/task/fn.block_in_place.html`, retrieved 2026-09-17), so it makes the handler depend on the runtime flavour. Ranked runner-up.
3. A dedicated `std::thread` pool owned by the adapter — more control, more code, and it duplicates a facility R69's tokio already ships. Not recommended.

##### Excluded by gate
These are the sync-first web frameworks the prompt's second HIGH question names. Each would remove the bridge entirely by avoiding an executor; each fails the maintenance rubric, and all are moot because R69 (owner-accepted) fixed `axum`.

| Crate | Newest non-yanked + date | 90-day / all-time downloads | Stars / archived / pushed | Open issues | `rust_version` | Licence | Rubric |
|---|---|---|---|---|---|---|---|
| `rouille` | 3.6.2, **2023-04-24** | 3,328,838 / 15,082,452 | 1,240 / false / 2025-06-17 | (not sampled) | none declared | MIT/Apache-2.0 | **at-risk** — no release in ~2 years 5 months, and the concrete signal is a declared-MSRV gap that makes gate 2 unanswerable from metadata |
| `tiny_http` | 0.12.0, **2022-10-06** | 13,772,847 / 63,651,280 | 1,138 / false / 2024-08-14 | (not sampled) | none declared | MIT OR Apache-2.0 | **at-risk** — no release in ~3 years 11 months; last push over a year before retrieval |
| `astra` | 0.4.0, **2024-11-07** | 1,703 / 17,745 | 226 / false / 2025-01-12 | 5 | none declared | MIT | **at-risk** — 1,703 downloads in 90 days is negligible adoption for a web server |

Direct answer to the HIGH question: **both dominant Rust web frameworks require an async executor.** `axum` 0.8.9 is published by the `tokio-rs` organisation and is built on `hyper`/`tower`/`tokio` (R69's selected member; 115,771,541 recent downloads, `rust_version` 1.80, licence MIT — `GET https://crates.io/api/v1/crates/axum` and `/versions`, retrieved 2026-09-17). `actix-web` 4.15.0 (10,478,339 recent downloads, `rust_version` 1.88, `MIT OR Apache-2.0`; `actix/actix-web` 24,826 stars, `pushed_at` 2026-09-16) runs on its own `actix-rt`/`actix-server`, which is itself built on tokio — an executor either way. A sync-first, thread-per-request Rust framework therefore exists but is not maintained at a level this template can take. **Consequently py's shape has a direct Rust analogue, and it is not awkward**: the executor is present inside the `web` feature regardless, and the bridge is one well-documented function call — proved in this run (probe C: `spawn_blocking(ureq …)` inside `rt.block_on` returned 559 bytes).

##### Up-and-comers
None applicable: the bridge is a tokio API and R69 fixed tokio. Worth watching only in the sense that if tokio ever exposes a blocking-pool sizing knob per call site, the ceiling discussed under *Tradeoffs* becomes tunable per route rather than per runtime.

##### Fit for this template
Exact. R69 already anticipated it: *"if R01's port stays synchronous the handler wraps the call in `tokio::task::spawn_blocking`"* (`research/topics/69-web-framework-stack/DECISION.md` line 1623, read 2026-09-16). This report takes that branch, and adds the measurement R69 did not need: the `rt` feature that `spawn_blocking` requires is already implied by R69's `rt-multi-thread`, so the bridge adds **no feature and no crate** to R69's owned value.

##### Recommendation
Each `web`-gated handler clones R69's `Arc<ErasedProjectsService>` out of `AppState` and calls `tokio::task::spawn_blocking(move || service.list(&q)).await`, mapping a `JoinError` (a panic inside the closure) to R67's `RSLB000` unexpected class. `block_in_place` is not used.

##### Ranked runner-up
`tokio::task::block_in_place`, for a route where the hand-off cost measurably matters and the runtime flavour is known to be multi-thread. Not recommended by default because it couples handler code to the runtime flavour and panics on the wrong one.

##### Tradeoffs
- **Gained:** the event loop is never blocked; the bridge is visible at each call site; no new crate and no new tokio feature; the same port implementation serves the CLI and the web layer with no second code path.
- **Given up:** one blocking-pool thread per in-flight upstream call, capped at tokio's default `max_blocking_threads` of 512, with idle threads reaped after `thread_keep_alive`'s default 10 s. A `'static` bound on the closure, satisfied here by `Arc` cloning. One extra task hand-off per request, whose cost was **not** measured in this run and is not asserted.
- **Unmeasured and stated as such:** no latency or throughput figure for the bridge is given anywhere in this report. Establishing one needs a load generator, a concurrency sweep and a fixed upstream, none of which this research run ran.

##### Parameters
Registers no parameter. **Assumes `web-extra-surface` at R69's published value**, including `tokio 1.53.1` with `features rt-multi-thread, net, signal, macros, time, sync`, and relies on `rt-multi-thread` implying `rt`. No `CONFLICT:` line — the recommendation is the branch R69 already wrote down.

##### Migration implications
In P03's template: `src/web/handlers/*.rs` each wrap one service call in `spawn_blocking`; `src/web/error.rs` gains one arm mapping `tokio::task::JoinError` to the unexpected class. No change to `Cargo.toml`.

##### Validation strategy
Executed in this run: probe C (`spawn_blocking(ureq …)` inside `Runtime::block_on` on a multi-thread runtime) returned 559 bytes; probe F did the same with `reqwest::blocking`; probe B established the panic that the bridge exists to avoid. Proposed for P03: an integration test that boots the router on an ephemeral port, issues a real request, and asserts the handler's response decodes into the library's `Vec<Project>` — R01's acceptance criterion 6, which R01 also assigns to P03.

##### Confidence & re-verify trigger
**High.** The mechanism is a documented tokio API and it was executed. Re-verify when R69 republishes `web-extra-surface` with a different tokio feature set, when tokio changes `max_blocking_threads`' default, when a route is specified whose upstream fan-out approaches the 512-thread ceiling, or by **2027-03-17**.

##### Sources
`https://docs.rs/tokio/1.53.1/tokio/runtime/struct.Builder.html`, retrieved 2026-09-17 · `https://docs.rs/tokio/1.53.1/tokio/task/fn.block_in_place.html`, retrieved 2026-09-17 · `https://tokio.rs/tokio/topics/bridging`, retrieved 2026-09-17 · `https://docs.rs/reqwest/0.13.5/reqwest/blocking/index.html`, retrieved 2026-09-17 · `GET https://crates.io/api/v1/crates/{axum,actix-web,rouille,tiny_http,astra}` and `/versions`, retrieved 2026-09-17 · `GET https://api.github.com/repos/{tomaka/rouille,tiny-http/tiny-http,ibraheemdev/astra,actix/actix-web}`, retrieved 2026-09-17 · `research/topics/69-web-framework-stack/DECISION.md` lines 799, 1591, 1623, read 2026-09-16 · py `src/py_launch_blueprint/web/routers/projects.py` at pin `b08bccfb`, read 2026-09-16 · probe family 3, this run.

---

#### CLI-side concurrency — `std::thread::scope`

##### Landscape
Category: how a synchronous CLI issues more than one upstream call at a time, since it has no executor to `join!` on. Bin 1 (built-in): `std::thread::spawn`, and `std::thread::scope` (stable since Rust 1.63), which lets borrowed data cross into threads without `Arc`/`'static`. Bin 2 (established): `rayon` (data parallelism over a work-stealing pool), `crossbeam` (scoped threads before `std` had them, plus channels), `threadpool`. Bin 3 (up-and-comer): none material; this is settled ground in Rust.

##### Principles and implementation
Neither source has a concurrency principle to preserve: py's `ProjectsService` issues one `requests` call per operation and ts's `request` awaits one `fetch`. The requirement here is therefore **negative** — the synchronous choice must not make concurrency impossible, and must not pull a parallelism framework into the default tree to prove it. `std::thread::scope` satisfies both: it is in `std`, it adds nothing to `Cargo.toml`, and it is well within the 1.96 MSRV floor.

##### Dominant choice
`rayon` is the dominant Rust *data-parallelism* crate, but it is dominant for CPU-bound iterator work, not for a handful of blocking network calls. For "issue N HTTP requests at once and collect the results", plain scoped threads are the ordinary Rust answer and require no crate.

##### Qualified shortlist
1. **`std::thread::scope`** — no crate, no MSRV risk, no dependency-tree cost, borrows cross the boundary without `Arc`.
2. `rayon` — justified only if a command becomes CPU-bound over a large collection. Deferred to whichever item needs it; not adopted here.
3. `crossbeam::thread::scope` — superseded by `std::thread::scope` for this purpose.

##### Excluded by gate
None evaluated, because the recommendation selects no crate. Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`; gates 2–6 are `inapplicable — no crate is selected by this member` (the mechanism is a `std` API, so there is no registry metadata, no advisory page, no feature set and no independent dependency cost to state).

##### Up-and-comers
None. This is a `std` facility whose shape has been stable since Rust 1.63.

##### Fit for this template
The prompt states the workload: most invocations are a single HTTP round trip. The member exists to record that the synchronous choice **does not forfeit concurrency** — it relocates it from the executor to threads — and to say precisely what a template consumer reaches for when they need it. For a command issuing, say, five upstream lookups, five scoped threads cost five OS thread stacks and finish in the slowest call's time, with no runtime and no `Cargo.toml` change.

##### Recommendation
`std::thread::scope` when a CLI command must fan out. No `rayon`, no `crossbeam`, no thread-pool crate in the template's default dependencies.

##### Ranked runner-up
`rayon` 1.x, if and when a command's work becomes CPU-bound over a large collection rather than I/O-bound over a few requests. Selecting it is that command's item's decision, not this one's.

##### Tradeoffs
- **Gained:** zero dependency cost; no runtime; concurrency remains available and obvious.
- **Given up:** the ceiling is OS threads rather than tasks, so "thousands of concurrent requests from the CLI" is not reachable without an executor. That is exactly the workload that would flip the execution-model member to its runner-up, and it is the trigger recorded there.

##### Parameters
Registers no parameter; assumes none beyond the four fixed values. No `CONFLICT:` line.

##### Migration implications
None to `Cargo.toml`. In P03's template this member is documentation plus, at most, one worked example in the CLI's extension guide.

##### Validation strategy
Nothing was executed for this member in this run, and no figure is claimed for it. Proposed for P03: if a fan-out command is specified, a test asserting that N concurrent calls complete in approximately the slowest call's wall time rather than their sum.

##### Confidence & re-verify trigger
**High**, and low-stakes — the member commits the template to nothing it must later undo. Re-verify when a CLI command with genuine fan-out is specified, or by **2027-03-17**.

##### Sources
`https://doc.rust-lang.org/std/thread/fn.scope.html`, retrieved 2026-09-17 — stabilised in **Rust 1.63.0**, *"Creates a scope for spawning scoped threads"*, well inside the 1.96 floor · `docs/port/PARAMETERS.md` (`msrv-policy`), read 2026-09-16 · the prompt's own statement of the CLI workload (`inputs/prompt.md`, MEDIUM question 1).

---

### Compatibility

The members are proven to work together by **three independent kinds of evidence**, not by assertion.

**1. A version matrix resolved and built in this run.** The `p_scen_sync` probe is the four members' composition minus the `std::thread` member (which adds nothing to resolve): `ureq 3.4.2` + `serde 1.0.229` + `serde_json 1.0.151` as non-optional dependencies, and `web = ["dep:axum", "dep:tokio"]` with `axum = { version = "0.8.9", optional = true }` and `tokio = { version = "1.53.1", optional = true, features = ["rt-multi-thread","net","signal","macros","time","sync"] }` — R69's owned value transcribed. Resolved on rustc 1.98.0 / cargo 1.98.0 under `edition = "2024"`, `rust-version = "1.96"`:

| Build | Unique normal deps (incl. root) | Clean `--release` build | `tokio` present | Crypto providers in tree |
|---|---|---|---|---|
| feature-off | 38 | 19 s | no | `ring v0.17.14` (via `ureq` → `rustls v0.23.45`) |
| `--features web` | 71 | 21 s | `tokio v1.53.1` | `ring v0.17.14` only — no `aws-lc-rs`, no `openssl`, no `native-tls` |

The feature-on tree's TLS/runtime crates in full: `hyper v1.11.1`, `hyper-util v0.1.20`, `ring v0.17.14`, `rustls v0.23.45`, `rustls-pki-types v1.15.1`, `rustls-webpki v0.103.15`, `tokio v1.53.1`, `tokio-macros v2.7.2`. This satisfies the owner document's one-crypto-provider rule (row R05-5) by construction.

**2. A shared adopter for the pairing of a blocking client with a tokio server.** `rust-lang/rustup` (7,044 stars, `pushed_at` 2026-09-17) declares in one manifest both `reqwest` with the `blocking` feature and `tokio` with `rt-multi-thread`, `macros`, `sync` — a maintained, widely deployed Rust program in which a blocking HTTP path and a tokio runtime coexist in one binary. It is not a `ureq`+`axum` adopter, and this report does not claim one; what it demonstrates is that the coexistence pattern is normal rather than exotic.

**3. Executed cross-member behaviour.** Probe C ran `ureq` **inside** a tokio multi-thread runtime through `spawn_blocking` and returned the expected 559-byte body; probe E ran `ureq` directly on a runtime worker (no panic, as expected of a crate with no runtime of its own). Members 2 and 3 are therefore proven to compose at run time, not only to resolve.

**Evidence gap, stated.** No public repository was found in this run that ships `ureq` and `axum` in the same binary at these versions; the compatibility claim rests on the resolved-and-built matrix plus the executed bridge, not on a third-party reference implementation. That gap is real and is the weakest link in this section.

---

### Parameters

This item registers **no owned parameter** (`research/CLAUDE.md`, R05 row, `owns` = `—`; `inputs/prompt.md` `## Couplings`, `owns:` empty).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92

The five `assumes` lines are quoted from `docs/port/PARAMETERS.md` (read 2026-09-16). The prompt's `## Couplings` lists `consumes:` as empty and records R01 as "related (not a registry dependency) … Treat R01's direction as open, do not block on it"; `http-transport-injection-seam` is listed above because R01 is now **published and owner-accepted** and this recommendation is written against its actual value. `web-extra-surface` (R69, published and owner-accepted) is likewise not a declared consumed parameter of this item, but the recommendation is written against its actual value and would be wrong if that value changed — that dependency is stated here rather than hidden.

**No `CONFLICT:` line is raised.** The recommendation was chosen, in part, because it needs no consumed parameter to change:

- `web-extra-surface` — the recommendation takes the branch R69 already wrote (`spawn_blocking`), keeps `tokio` optional, and leaves R69's owned string byte-identical. **Had this item recommended alternative B (async core), a `CONFLICT:` line would have been mandatory**, because `tokio` would become non-optional and R69's `web = ["dep:axum", "dep:tokio"]` clause would fail to parse — verified in this run as `error: failed to parse manifest … feature 'web' includes 'dep:tokio', but 'tokio' is not an optional dependency`. A conflict line against R69 `web-extra-surface` would then have been required, asking for `web = ["dep:axum"]` with `tokio` declared as a non-optional dependency, on the ground that an async core makes `tokio` unconditional and Cargo rejects a `dep:` clause naming a non-optional dependency. **No such line is raised here**, because that branch was not taken.
- `http-transport-injection-seam` — the recommendation keeps R01's port free of `async fn`, so R01's conditional `async-trait 0.1.92` clause does not fire and R01's owned value is unchanged.

---

### Migration implications

Not a migration: `rs-launch-blueprint` has no Rust code and P03 builds it. These are the file-level shapes this decision fixes for P03, and the ledger rows it settles.

| Path in the template | What this decision fixes |
|---|---|
| `Cargo.toml` `[dependencies]` | `ureq = { version = "3.4.2", features = ["json"] }` is added as a **non-optional** dependency, alongside R01's `serde 1.0.229` / `serde_json 1.0.151`. `tokio` stays **optional** and appears only in R69's `web` feature. `async-trait` is **not** added. `reqwest` is **not** added. |
| `Cargo.toml` `[features]` | Unchanged from R69's owned value: `web = ["dep:axum", "dep:tokio"]`. This decision adds no feature. |
| `src/ports.rs` (or wherever R01's port lives) | `pub trait ProjectsPort: Send + Sync` with **synchronous** `fn` methods — R01's accepted text, unchanged. No `#[async_trait]` attribute anywhere in the crate. |
| `src/adapters/http.rs` | Holds a `ureq::Agent` built once; method bodies are ordinary blocking code; error arms map `ureq`'s transport-vs-status split onto R67's `RSLB102`/`RSLB103`/`RSLB401`/`RSLB402`. |
| `src/lib.rs`, `src/services/*.rs` | No `async` keyword. Acceptance criterion 7 is the check. |
| `src/main.rs` (the `rslbp` CLI binary, per R49's `build-tool-output-shape`) | `fn main() -> std::process::ExitCode`. No `#[tokio::main]`, no `block_on`. |
| `src/web/**` (gated `#[cfg(feature = "web")]`) | The only tree containing `async fn`. Each handler wraps its service call in `tokio::task::spawn_blocking`. |
| the `<app>-serve` binary (R69's, `required-features = ["web"]`) | Keeps `#[tokio::main]`; unchanged by this decision. |
| CI (R11's job shape) | Both `cargo test` and `cargo test --features web` must run, on `ubuntu-latest` and `macos-latest`. The feature-off job is the one that proves criterion 1. |

Ledger rows settled: **F016**. **F022** is answered by R69 for the `web` feature and inapplicable to the CLI and library — see the `BASELINE-REVIEW` line, which proposes the wording change and does not make it.

---

### Validation strategy

**Distinguish what was run from what is proposed.** Everything under "executed" below ran in this session against throwaway probe packages created under a directory inside `$TMPDIR` and deleted afterwards; **no template code exists and none was written**. Everything under "proposed" is P03's to run against the real template.

**Executed in this run** (rustc 1.98.0, cargo 1.98.0, macOS 26.4 `aarch64-apple-darwin`, 2026-09-17):

| # | Command (as run, in the probe package) | Expected | Observed |
|---|---|---|---|
| E1 | `cargo tree --prefix none -e normal \| sed 's/ (\*)$//' \| awk 'NF' \| sort -u \| wc -l` in `p_scen_sync` and `p_scen_async` | sync tree materially smaller | **38** vs **93** |
| E2 | the same with `--features web` | sync tree grows by the web feature's cost | **71** vs **101** |
| E3 | `cargo tree -i tokio -e normal` in `p_scen_sync` | no match | no match (command exits non-zero) |
| E4 | `cargo tree -i tokio -e normal --features web` in `p_scen_sync` | `tokio v1.53.1` present | present |
| E5 | `cargo tree -i tokio -e normal` in `p_reqwest_blocking` | present despite the "blocking" API | present, via `hyper`, `hyper-rustls`, `hyper-util`, `tokio-rustls`, `tower` |
| E6 | `cargo clean && cargo build --release` timed with `date +%s` | sync faster | **19 s** vs **43 s** (feature-off); **21 s** vs **48 s** (feature-on) |
| E7 | `stat -f %z target/release/<bin>` | sync binary smaller | `p_ureq` **2,704,896** B vs `p_reqwest_async_mt` **5,694,352** B (baseline `p_base` **433,712** B) |
| E8 | run each probe binary | a real HTTPS GET completes | all four printed **559** |
| E9 | `cargo check` on a manifest with `web = ["dep:tokio"]` and non-optional `tokio` | rejected | `error: failed to parse manifest … feature 'web' includes 'dep:tokio', but 'tokio' is not an optional dependency` |
| E10 | `cargo check` on a trait with a native `async fn` erased to `Arc<dyn …>` | rejected | `error[E0038]: the trait 'NativeAsyncPort' is not dyn compatible` |
| E11 | the same trait under `#[async_trait::async_trait]` | accepted | `Finished 'dev' profile` |
| E12 | `Runtime::block_on` called from inside `Runtime::block_on` | panic | `Cannot start a runtime from within a runtime.` |
| E13 | `spawn_blocking(\|\| ureq::get(..).call()..)` awaited inside `block_on` | succeeds | 559 bytes |
| E14 | `reqwest::blocking::get` on a multi-thread and a current-thread runtime worker | docs say it panics | **did not panic** on either; both returned 559 bytes — discrepancy recorded above |
| E15 | `cargo tree ... --features web` filtered for crypto providers | exactly one provider | `ring v0.17.14` only in the sync scenario; `aws-lc-rs v1.18.1` + `aws-lc-sys v0.45.0` in the async one |

**Proposed for P03** (commands that would prove the principle on the real template; none of these was run, because the template does not exist):

1. `cargo tree -i tokio -e normal` — **must fail**; `cargo tree -i tokio -e normal --features web` — **must succeed**. This is criterion 1 and it is the single command that distinguishes this decision from its runner-up.
2. `cargo test` and `cargo test --features web`, on `ubuntu-latest` and `macos-latest` (R11 owns the job shape) — both green.
3. `cargo public-api` (R04's selected tool) — its output must contain no `async fn` and no `impl Future` on the library's public surface.
4. An integration test that boots the `web` router on an ephemeral port, issues a real HTTP GET, and asserts the body decodes into the library's own `Vec<Project>` and equals the CLI's rendering — R01's acceptance criterion 6.
5. A local HTTP fixture asserting the adapter sends `Authorization: Bearer …` and `Accept: application/json` and honours a 30-second timeout — the py/ts request-wrapper principle.
6. `cargo deny check advisories` against a pinned RustSec database — gate 3, continuously.
7. A `compile_fail` doctest pinning criterion 3: a port with a native `async fn` must not erase.

---

### Confidence & re-verify trigger

**Overall confidence: high**, with the qualifications named rather than averaged away.

- **High** on the execution-model choice. Its two decisive grounds are mechanical and were reproduced in this session: R69's owner-accepted `web = ["dep:axum", "dep:tokio"]` string is only legal while `tokio` is optional, and `tokio` is only optional while the core is synchronous; and R01's owner-accepted port declares "no `async fn`", which an async core cannot honour without `async-trait`. The cost measurements (2.4× dependencies, 2.3× compile, 2.1× binary) point the same way independently of both.
- **Medium-high** on `ureq` specifically. Its figures are strong and its gates pass, but two things are softer than the rest of this report: its CI does not exercise macOS (this run supplied that leg directly, on one machine, once), and it has **no HTTP/2**, which is a real capability the runner-up has.
- **Medium** on the compatibility section, because no third-party repository shipping `ureq` and `axum` together was found; the claim rests on a resolved-and-built matrix and an executed bridge.
- **Explicitly not claimed:** any latency, throughput or requests-per-second figure. None was measured. The build-time and size figures are single runs on one macOS arm64 machine and are comparisons of magnitude, not benchmarks.

**Re-verify when any of the following occurs, or by 2027-03-17, whichever comes first:**
- R69 republishes `web-extra-surface` with `tokio` non-optional, or with a different feature set;
- R01 republishes `http-transport-injection-seam` with an async port;
- the `web` feature stops being off-by-default, or the web service becomes the template's primary surface;
- a CLI command is specified whose normal invocation issues many concurrent upstream calls;
- `ureq` publishes a 4.x line, gains an `http2` feature, adds or continues to omit a macOS CI job at the next MSRV floor advance past 1.96, or receives its first RustSec advisory;
- `reqwest` publishes a 0.14 or 1.0 line, or changes `default-tls` again;
- `dyn`-compatible native `async fn` in traits stabilises on a Rust version within the MSRV floor, which would remove `async-trait` from the runner-up's cost;
- the owner scopes any of the reference document's currently unowned rows (TLS/crypto-provider selection, Variants A/B) into a P02 item.

---

### Sources

**This repository** (read 2026-09-16 unless noted):
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/inputs/prompt.md` · `.../inputs/PARAMETERS.md` · `.../inputs/parameters.json` · `.../inputs/prerequisites.json` · `.../inputs/EXECUTION.json` · `.../inputs/owner-reference-axum-companion-stack-2026-09-16.md` (all 435 lines) · `research/topics/01-ports-and-adapters-seam/DECISION.md` (revision 3, owner-accepted 2026-09-10) · `research/topics/69-web-framework-stack/DECISION.md` (revision 9, 2026-09-16; lines 217–224, 611–614, 799, 1315, 1591, 1623–1626, 2204) · `docs/port/COMMONALITY.md` rows F016, F017, F022 · `docs/port/PARAMETERS.md` · `research/CLAUDE.md` · `docs/superpowers/plans/p02-roles/research-worker.md`.

**Pinned source repositories** (read through the pins, not the working trees):
`~/c/py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` — `git show b08bccfb:src/py_launch_blueprint/core/adapters/py_api.py` (the `import requests` line and `DEFAULT_TIMEOUT = 30`) and `git show b08bccfb:src/py_launch_blueprint/web/routers/projects.py` (the module docstring's threadpool sentence and the two `def` handlers). `~/c/ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — `git show cb1cbcb2:src/router.ts` (`export async function runCli(...): Promise<number>`) and `git show cb1cbcb2:src/lib/api.ts` (`async function request(...)` over the injected `options.fetchImpl`). **Every claim about either source in this report comes from its pin**; no claim is attributed to either repository's HEAD.

**crates.io API** (`User-Agent` header sent; all retrieved 2026-09-17):
`GET https://crates.io/api/v1/crates/<name>` for `crate.recent_downloads` and `crate.downloads` — `tokio`, `reqwest`, `ureq`, `smol`, `async-std`, `async-trait`, `hyper`, `attohttpc`, `minreq`, `isahc`, `futures-lite`, `pollster`, `surf`, `axum`, `actix-web`, `rouille`, `tiny_http`, `astra` · `GET https://crates.io/api/v1/crates/<name>/versions` for the newest `yanked: false` `num` + `created_at` + `rust_version` + `license` on the same set · `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies` for `meta.total` (`tokio` 72,755; `reqwest` 29,543; `ureq` 3,718; `smol` 726) and, for `ureq`, the adopter list (`cargo-deny`, `nextest-runner`, `wasm-pack`, `crates-index`, `wasm-bindgen-cli`, `self_update`, `bevy`, `oauth2`, `sentry`, `xwin`, `cargo-xwin`, `wasmer`, `c2pa`).

**GitHub REST** (via authenticated `gh api`; all retrieved 2026-09-17):
`GET repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`, `license.spdx_id`) for `tokio-rs/tokio`, `seanmonstar/reqwest`, `algesten/ureq`, `smol-rs/smol`, `async-rs/async-std`, `dtolnay/async-trait`, `hyperium/hyper`, `sbstp/attohttpc`, `neonmoe/minreq`, `zesterer/pollster`, `tomaka/rouille`, `tiny-http/tiny-http`, `ibraheemdev/astra`, `actix/actix-web`, `rust-lang/cargo`, `rust-lang/rustup`, `astral-sh/uv`, `astral-sh/ruff`, `cargo-bins/cargo-binstall`, `ducaale/xh`, `sharkdp/hyperfine`, `helix-editor/helix`, `EmbarkStudios/cargo-deny`, `nextest-rs/nextest`, `rustwasm/wasm-pack` · `GET search/issues?q=repo:<o>/<r>+is:issue+is:open` for `total_count` (never `open_issues_count`) · `GET repos/<o>/<r>/contents/Cargo.toml`, `/contents/src/lib.rs`, `/contents/tokio/Cargo.toml`, `/contents/tokio/src/lib.rs`, `/contents/.github/workflows/{ci.yml,test.yml}` for the adopters' declared dependencies, the crates' lint attributes, and the CI platform matrices. **Pin discipline:** the adopter manifests (`rust-lang/cargo`, `rust-lang/rustup`, `astral-sh/uv`, `ducaale/xh`, and the rest of the practice table) were read at each repository's **default branch**, which is the right ref for "what does this project use today" and is labelled as such; every claim about a *selected crate's own* manifest, lint attributes or CI matrix was **re-read at the release tag** — `?ref=3.4.2` for `ureq`, `?ref=v0.13.5` for `reqwest`, `?ref=tokio-1.53.1` for `tokio` — so no default-branch text is attributed to a pinned version · `GET repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=20` and `GET repos/<o>/<r>/issues/<n>/comments?per_page=100` for issue responsiveness.

**RustSec** (retrieved 2026-09-17): `https://rustsec.org/packages/{tokio,hyper,async-std}.html` (HTTP 200) and `https://rustsec.org/packages/{reqwest,ureq,smol,async-trait,attohttpc,minreq,pollster}.html` (HTTP 404 — no advisories ever filed) · `https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/async-std/RUSTSEC-2025-0052.md` for the discontinuation advisory's verbatim text.

**Maintainers' and project documentation** (all fetched 2026-09-17): `https://tokio.rs/tokio/topics/bridging` · `https://docs.rs/tokio/1.53.1/tokio/runtime/struct.Builder.html` · `https://docs.rs/tokio/1.53.1/tokio/task/fn.block_in_place.html` · `https://docs.rs/reqwest/0.13.5/reqwest/blocking/index.html` · `https://doc.rust-lang.org/std/thread/fn.scope.html` · `https://blog.rust-lang.org/2023/12/28/Rust-1.75.0/` · `https://doc.rust-lang.org/cargo/reference/features.html` — the last states that an optional dependency implicitly defines a same-named feature, that *"If you specify the optional dependency with the `dep:` prefix anywhere in the `[features]` table, that disables the implicit feature"*, and that `dep:` is available from Rust 1.60; it does **not** spell out the non-optional case in prose, which is why the exact rejection message is quoted from the executed `cargo check` instead.

**Attempted and unusable, reported as gaps:** `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results` and `https://blog.rust-lang.org/2024/02/19/2023-Rust-Annual-Survey-2023-results/` — neither page's HTML body carries an async-runtime breakdown; the 2025 results' linked PDF was not retrieved. No survey-derived figure appears in this report.

**Method notes.** Endpoints queried: the crates.io API (`/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`) with a `User-Agent` header, for every download count, version, release date, declared `rust_version` and licence string; the GitHub REST API through authenticated `gh api` (`repos/<o>/<r>`, `search/issues?q=…+is:issue+is:open`, `repos/<o>/<r>/contents/<path>`, `repos/<o>/<r>/issues`, `repos/<o>/<r>/issues/<n>/comments`), for stars, archived status, last push, open-issue totals, the adopters' own manifests and the issue-responsiveness sample; `rustsec.org/packages/<name>.html` plus the advisory-db raw file for gate 3; `docs.rs`, `tokio.rs`, `doc.rust-lang.org` (the `std::thread::scope` page and the Cargo Book's features chapter) and `blog.rust-lang.org` (the Rust 1.75.0 release announcement) for the projects' own documentation; and `blog.rust-lang.org`'s survey-results pages for the survey attempt. Every URL listed under `### Sources` was actually fetched in this run. Figures were never taken from a README or a secondary write-up. The probe families were built under a directory created inside `$TMPDIR` for this run and **deleted afterwards**; no file was written anywhere in this repository except this one report file. **Not verified, and stated as such:** (a) any async-runtime share from the annual Rust survey — the published HTML carries none and the PDF was not fetched; (b) `ureq` on a macOS **CI runner** — the project's workflow has no macOS job, so gate 4's macOS leg rests on this run's single local build-and-run on macOS 26.4 arm64; (c) the Linux leg of every gate-4 answer — no `ubuntu-latest` execution happened in this run, and the Linux evidence is the projects' own CI matrices (`reqwest`, `tokio`, `ureq` all run Ubuntu jobs) rather than an execution here; (d) any latency, throughput or per-request cost figure for the `spawn_blocking` bridge, which would need a load generator this run did not build; (e) the claim in `reqwest` 0.13.5's own blocking-module documentation that it "will panic" inside an async runtime — it did **not** panic in either runtime flavour tested here, and this report records the observed behaviour and the hazard separately rather than repeating the documented claim; (f) issue-responsiveness medians for `ureq`, `reqwest` and `tokio` rest on 4, 7 and 4 sampled issues respectively rather than 10, because pull requests occupied the rest of each repository's 20 most recent records.
