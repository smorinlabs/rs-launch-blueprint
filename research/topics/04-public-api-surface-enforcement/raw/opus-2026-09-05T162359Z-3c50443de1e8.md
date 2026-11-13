# R04 — Public API surface enforcement (pattern) — raw report

Actor id: `research-opus-2026-09-05T162359Z-3c50443de1e8`. Engine: opus. Item kind: `pattern`.
Every figure below carries its endpoint and a retrieval date of **2026-09-05**; every claim carries a source URL and the same retrieval date unless stated otherwise.

Item kind is `pattern`, so the crate figure table applies only to the *tools* shortlisted inside the pattern (`cargo-public-api`, `cargo-semver-checks`, `cargo-check-external-types`). It is `inapplicable` to the language-native mechanisms (module privacy, `pub use`, rustc lints, `compile_fail` doctests, Cargo `publish`): those ship inside the Rust toolchain, have no crates.io registry entry, no independent repository, and no independent release cadence, so `crate.recent_downloads`, `crate.downloads`, `/versions`, `stargazers_count` and `rustsec.org/packages/<name>.html` have no value to read. Their maturity evidence is the language reference, the RFCs that decided them, and the compiler release they shipped in.

### Landscape

**Category this item decides.** The mechanism that makes `rs-launch-blueprint`'s curated public library surface non-bypassable, plus the mechanism that detects unreviewed drift in that surface over time. Two separable sub-decisions: (a) *reachability* — can a consumer name an item the template did not sanction; (b) *drift detection* — does an unreviewed addition or removal fail CI.

**Three-bin map of the Rust field.**

*Bin 1 — built-in or first-party toolchain.*

| Mechanism | What it does for this item | Reference |
|---|---|---|
| Module privacy (private-by-default; `pub`, `pub(crate)`, `pub(super)`, `pub(in path)`, `pub(self)`) | Decides reachability at compile time | [Rust Reference, Visibility and Privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html), retrieved 2026-09-05 |
| `pub use` re-export | Publishes an item from a private module at a chosen path; "short-circuits the privacy chain" | same page, retrieved 2026-09-05 |
| `unreachable_pub` lint (allow-by-default) | Flags a `pub` item that is not reachable from another crate — i.e. an internal item that *looks* exported | [rustc lint listing, allowed-by-default](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html), retrieved 2026-09-05 |
| `private_interfaces`, `private_bounds` lints (warn-by-default) | Catch a private type or bound leaking through a public signature | [rustc lint listing, warn-by-default](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html), retrieved 2026-09-05; [RFC 2145 Type privacy](https://rust-lang.github.io/rfcs/2145-type-privacy.html), retrieved 2026-09-05 |
| `unnameable_types` lint (allow-by-default) | Flags a type reachable but not nameable outside its module | RFC 2145, retrieved 2026-09-05 |
| `missing_docs` lint (allow-by-default) | Forces every item on the sanctioned surface to be documented | rustc allowed-by-default listing, retrieved 2026-09-05 |
| `#[doc(hidden)]` | "will not appear in the documentation" while remaining reachable in code — the exact Rust analogue of py's `__all__`: documents, does not enforce | [rustdoc book, the `#[doc]` attribute](https://doc.rust-lang.org/rustdoc/write-documentation/the-doc-attribute.html), retrieved 2026-09-05 (quoted); the reachability half is executed check 5 below |
| `compile_fail` doctest | Turns "this deep import must not compile" into an executed test in `cargo test` | [rustdoc book, documentation tests](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html), retrieved 2026-09-05 |
| Cargo `publish = false` | Marks a workspace member as never publishable | [Cargo manifest reference, the publish field](https://doc.rust-lang.org/cargo/reference/manifest.html#the-publish-field), retrieved 2026-09-05 |

*Bin 2 — established industry standard (CI drift detectors).* `cargo-semver-checks` (with `obi1kenobi/cargo-semver-checks-action`) and `cargo-public-api` (with its `public-api` library for snapshot tests).

*Bin 3 — up-and-comer.* `cargo-check-external-types` (awslabs); and the substrate both established tools sit on, rustdoc JSON, still unstable under [rust-lang/rust#76578](https://github.com/rust-lang/rust/issues/76578) (retrieved 2026-09-05).

**Crate figures for the Bin 2 and Bin 3 tools.** Endpoints exactly as the prompt's table specifies; all retrieved 2026-09-05.

| Figure (endpoint) | cargo-public-api | cargo-semver-checks | cargo-check-external-types |
|---|---|---|---|
| 90-day downloads (`GET https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads`) | 88,432 | 158,054 | 12,324 |
| All-time downloads (same → `crate.downloads`) | 262,912 | 604,321 | 112,085 |
| Last release (`GET https://crates.io/api/v1/crates/<name>/versions`, newest `yanked: false`) | `0.52.0`, `2026-05-25T17:36:08Z` | `0.50.0`, `2026-08-01T17:02:07Z` | `0.5.0`, `2026-06-08T21:38:35Z` |
| Declared license (same endpoint, `license`) | `MIT` | `Apache-2.0 OR MIT` | `Apache-2.0` |
| Declared `rust-version` / `edition` (same endpoint) | none / `2024` | `1.93` / `2024` | none / `2021` |
| Stars, archived, pushed_at (`GET https://api.github.com/repos/<o>/<r>`) | 573, `archived: false`, `2026-09-04T04:43:39Z` | 1,675, `archived: false`, `2026-08-29T20:34:57Z` | 71, `archived: false`, `2026-06-11T18:44:14Z` |
| Open issues (`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`) | 3 | 161 | 5 |
| Issue responsiveness (10 most recently opened issues; median days to first maintainer reply; unanswered) | median 3.15 d; 3 of 10 unanswered, and all 3 (`#904`, `#881`, `#847`) were filed by `github-actions[bot]` automation rather than by a person — every human-filed issue in the window got a maintainer reply | median 2.05 d; 7 of 10 unanswered raw — but 4 of the 10 are self-filed tracking issues opened by the owner `obi1kenobi`; of the 6 externally filed, 3 answered (median 2.05 d) and 3 unanswered, all opened within 10 days of retrieval | no maintainer reply on any of the 8 issues returned (oldest 2024-05-29, newest 2026-06-29); median `inapplicable` — no responses to take a median of |
| Advisories (`https://rustsec.org/packages/<name>.html`) | HTTP 404 — no advisory page exists, i.e. no recorded advisory | HTTP 404 — same | HTTP 404 — same |
| Maintenance verdict (rubric) | `active` | `active` | `at-risk` |

Maintenance rubric application. `cargo-public-api`: last release 2026-05-25 is inside 6 months and `pushed_at` is 2026-09-04, one day before retrieval — `active`. `cargo-semver-checks`: released 2026-08-01, pushed 2026-08-29 — `active`. `cargo-check-external-types`: released 2026-06-08 (inside 6 months, so the release date alone is not a trigger), but the concrete `at-risk` signal is the responsiveness figure — zero maintainer replies across all 8 issues returned, spanning 2024-05-29 to 2026-06-29. That is a concrete signal, not merely a quiet release cadence. It is not `dormant`: there is no unpatched advisory, no maintainer notice of retirement, and its CI runs on current stable.

**Authoritative sources used, and why each counts.**

1. *The Rust Reference* — the Rust project's normative description of the language; visibility rules are defined there, not inferred. Used for the reachability answer.
2. *rustc lint listings (allowed-by-default, warn-by-default)* — the compiler team's own reference for lint names and default levels; the default level is the fact that decides whether the template must opt in.
3. *RFC 1422 (`pub(restricted)`)* and *RFC 2145 (Type privacy)* — Rust RFC process output; these are the decisions themselves, not commentary on them.
4. *The Rust Programming Language, ch. 14.2* — the project's canonical teaching text; the source of the "re-export a convenient public API with `pub use`" guidance.
5. *Rust API Guidelines* — published by the Rust library team; consulted for surface-shaping guidance (C-STABLE, C-STRUCT-PRIVATE, C-SEALED, C-NEWTYPE-HIDE).
6. *Rust Project Goals 2026* — a Rust project publication owned by the cargo and rustdoc teams; establishes that `cargo-semver-checks` is on a path into `cargo publish` itself, which is the strongest available signal of first-party endorsement short of shipping.
7. *Maintainers' own documentation* — `cargo-public-api` README, `cargo-semver-checks` README and source, `cargo-check-external-types` README, and `cargo-semver-checks-action`'s `action.yml`; authoritative for toolchain requirements and CI inputs.
8. *2025 State of Rust Survey results* ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/), published 2026-03-02, retrieved 2026-09-05) — the annual survey the prompt names as an authority class. **Evidence gap, stated rather than papered over:** its published findings cover language features, compile times, community and hiring; it contains no question or finding about public-API surface enforcement or the tools above, so it contributes no weight to this item.

**Practice evidence — well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Evidence it is well regarded | What it practises (source, retrieved 2026-09-05) |
|---|---|---|
| `tokio-rs/tokio` | The de-facto Rust async runtime; the dependency almost every Rust web/service stack sits on | `.github/workflows/ci.yml:498-515` — a dedicated `semver` job running `obi1kenobi/cargo-semver-checks-action@v2` with `rust-toolchain: ${{ env.rust_stable }}` — i.e. the drift gate runs on **stable**. [raw file](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/workflows/ci.yml) |
| `hyperium/hyper` | The HTTP implementation underneath `reqwest` and `axum`'s server stack | `.github/workflows/CI.yml:347-355` — `semver` job using `cargo-semver-checks-action@v2`, and `semver` is listed at line 32 among the jobs the aggregate gate requires. [raw file](https://raw.githubusercontent.com/hyperium/hyper/master/.github/workflows/CI.yml) |
| `ratatui/ratatui` | The maintained successor to `tui-rs` and the mainstream Rust TUI library — a *newer* popular project, which the survey method asks to weight | `.github/workflows/check-semver.yml` — a whole workflow dedicated to `cargo-semver-checks-action`, SHA-pinned, with `permissions: {}`. [raw file](https://raw.githubusercontent.com/ratatui/ratatui/main/.github/workflows/check-semver.yml) |
| `trishume/syntect` | 2,413 stars, `archived: false`, `pushed_at 2026-04-28` (`GET https://api.github.com/repos/trishume/syntect`); the standard Rust syntax-highlighting crate | `tests/public_api.rs` — a committed public-API snapshot test built on the `public-api` library (`GET https://api.github.com/search/code?q=public-api+repo:trishume/syntect` → `total_count` 4, paths `Cargo.toml`, `tests/public_api.rs`, `Cargo.lock`, `CHANGELOG.md`) |
| `tokio-rs/axum` | The mainstream Rust web framework, and the shape this template's web surface will most resemble | `axum/src/lib.rs:553-602` — private `mod boxed; mod extension; mod form; mod json; mod service_ext; mod util;` for internals, `pub mod body / error_handling / extract / handler / middleware / response / routing / serve` for namespaced public areas, and root `pub use self::routing::Router;`, `pub use self::json::Json;` etc. for the hot items. (`GET https://api.github.com/repos/tokio-rs/axum/contents/axum/src/lib.rs`) |

Ecosystem-wide adoption breadth, same retrieval date: `GET https://api.github.com/search/code?q=cargo-semver-checks-action+path:.github/workflows` → `total_count` **1,144**; `GET https://api.github.com/search/code?q="cargo public-api"+path:.github/workflows` → `total_count` **88**. Reverse dependencies of the `public-api` library (`GET https://crates.io/api/v1/crates/public-api/reverse_dependencies`) → 30 total, including `syntect 5.3.0`, `backer`, `lilt`, `supercilex-tests`.

A negative practice result worth recording: searching the same nine well-regarded repos (`tokio`, `reqwest`, `axum`, `clap`, `ratatui`, `sqlx`, `hyper`, `serde`, `regex`, plus `smol-rs/async-io` and `awslabs/aws-sdk-rust`) for `public-api` returned `total_count` 0. Snapshot testing is a real practice (syntect) but a much narrower one than the semver gate.

### Principles and implementation

**The shared requirement.** Library consumers get exactly one sanctioned import surface; anything not on it is not part of the contract and may change without notice. Source: py `src/py_launch_blueprint/core/__init__.py:61-85` declares `__all__` with 23 names (verified at py pinned tree `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, retrieved 2026-09-05); ts `src/lib.ts:1-3` states "The root export is the only stable API surface (D-012(3))" and `src/lib.ts:5` opens the barrel `export { ... }` (verified at ts pinned tree `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, retrieved 2026-09-05).

**Agreement level.** Two levels, and the item's scope is only the second.

- *Architectural pattern (settled, out of scope for this item):* one curated surface exists. Ledger F014, `COMMON → REUSE`, `rust-ok: yes` (`docs/port/COMMONALITY.md:20`); adjudicated and `retained` under A5 in `docs/port/BASELINE-REVIEW.md:38`.
- *Policy/mechanism (this item, F015, `DIVERGENT`, `docs/port/COMMONALITY.md:21`):* whether that surface is enforced or merely documented. py: enforced by nothing — `docs/design/0005-hexagonal-architecture-and-enforcement.md:298` states "**HEX-34 — `__all__` documents, it does not enforce.** ... It is a convention, not a guard — the guards are HEX-30/31." ts: enforced by the resolver — `package.json:24` declares `"exports": { ".": { "types": "./dist/lib.d.ts", "default": "./dist/lib.js" }, "./package.json": "./package.json" }`, and `TS_PORT_DECISIONS.md:88` D-012(3) records the deliberate choice of a "Hand-authored root-only exports map ... do NOT use tsdown's exports auto-generation".

**Essential behaviors, with observable acceptance criteria.**

| # | Behavior | Observable acceptance criterion |
|---|---|---|
| B1 | A consumer cannot name an item the template did not sanction | A consumer crate that references an internal path fails to build with a specific compiler error |
| B2 | The sanctioned surface is enumerable in one reviewable place | One file (`src/lib.rs`) lists every exported name; a reviewer diffs that file |
| B3 | No internal type escapes through a public signature | Compiler rejects a public signature mentioning a `pub(crate)` type |
| B4 | An item that *looks* exported but is unreachable is an error, not silent dead weight | Compiler rejects `pub` in a private module that is not re-exported |
| B5 | A removal from or breaking change to the surface fails CI without a human noticing | A CI command exits nonzero on a removed public method |
| B6 | An addition to the surface cannot land unreviewed | The addition either forces a diff in the reviewed file (B2) or fails a CI check |

**Compared architectural alternatives (not just candidate libraries).**

- **A. Convention only** — document the surface, enforce nothing; `#[doc(hidden)] pub` for internals. This is the faithful port of py's `__all__`. *Rejected:* it satisfies none of B1, B3, B4, B5, B6, and I verified the hole empirically — a `#[doc(hidden)] pub fn escape_hatch()` re-exported at the root was callable from a consumer crate and returned the crate-private constant `SECRET` (`42`). Choosing A would knowingly port py's weakest property into a language that hands the stronger one over for free.
- **B. Language visibility only** — every internal module declared `mod` (private), only `pub use` at the crate root. Satisfies B1 and B2. Verified empirically (see `### Validation strategy`): a consumer crate writing `surface_demo::internal::Widget::new(1)` failed with `error[E0603]: module 'internal' is private`, and the compiler even annotated `struct 'Widget' is not publicly re-exported`. This is **stronger than ts's `exports` map**, not merely equivalent: ts enforces at module-resolution time in the consumer's runtime/bundler, whereas Rust refuses to compile, and Rust has no `require`-style or `node_modules`-path bypass. The Reference states the rule directly — "If an item is public, then it can be accessed externally from some module `m` if you can access all the item's ancestor modules from `m`" — so a `pub` item in a private module is unreachable across the crate boundary.
- **C. B plus denied reachability lints** — `#![deny(unreachable_pub)]`, `#![deny(private_interfaces, private_bounds)]`, `#![deny(missing_docs)]` at the crate root. Adds B3 and B4. Both verified empirically: adding `pub struct Leaked;` to the private module produced `error: unreachable 'pub' item ... help: consider restricting its visibility: 'pub(crate)'`; adding `pub fn engine(&self) -> Engine` where `Engine` is `pub(crate)` produced `error: type 'Engine' is more private than the item 'Widget::engine'`.
- **D. C plus a CI surface-drift detector.** Two sub-options, and this is where the discriminating constraint lives (below).
- **E. Physical crate boundary** — put internals in a separate workspace member that is never published. *Blocked for this template.* Verified empirically: `cargo publish --dry-run` on a crate depending on a `publish = false` path member fails two ways — with `version` on the dependency, `error: failed to prepare local package for uploading / Caused by: no matching package named 'rs_blueprint_internal_demo' found / location searched: crates.io index`; without it, `error: ... all dependencies must have a version requirement specified when publishing.` This template *does* publish to crates.io (ledger F075 `docs/port/COMMONALITY.md:81` — OIDC Trusted Publishing, "crates.io supports Trusted Publishing"; F214 `:218` — "`cargo publish` produces one `.crate` file"), so an internal `publish = false` crate cannot be a dependency of the published library crate. **This is a stated dependency note for R02, not a decision for it:** whichever topology R02 picks, any internal crate reachable from the published crate's dependency graph must itself be published, so `publish = false` is usable only for members outside that graph (test fixtures, xtask helpers, examples).

**The discriminating constraint: which drift detector runs on stable.** The prompt's constraints say "Stable Rust only". Both drift detectors read rustdoc JSON, which is unstable ([rust-lang/rust#76578](https://github.com/rust-lang/rust/issues/76578), retrieved 2026-09-05). They differ in how they obtain it, and that difference decides the recommendation.

- `cargo-semver-checks` sets `RUSTC_BOOTSTRAP=1` internally, so it produces rustdoc JSON from whatever toolchain is active. Source: `src/data_generation/generate.rs:544` — `cmd.env("RUSTC_BOOTSTRAP", "1")` — at commit [`b778c28f67b6a537bab95a344c9aac38706f02cc`](https://github.com/obi1kenobi/cargo-semver-checks/blob/b778c28f67b6a537bab95a344c9aac38706f02cc/src/data_generation/generate.rs#L544), retrieved 2026-09-05. Its README states "When each `cargo-semver-checks` version is released, it will at minimum include support for the then-current stable and beta Rust versions" and that nightly support is "on a best-effort basis". Its GitHub Action defaults `rust-toolchain: stable` (`action.yml`, retrieved 2026-09-05). **Verified by execution:** ran on stable `rustc 1.98.0` with no nightly toolchain installed.
- `cargo-public-api` requires a nightly toolchain to be *installed*, though not active. Its README states: "Relies on and automatically builds rustdoc JSON, for which a recent version of the Rust nightly toolchain must be installed" and "Ensure **nightly-2025-11-22** or later is installed (does not need to be the active toolchain)". A source search confirms it does not use the bootstrap escape hatch (`GET https://api.github.com/search/code?q=RUSTC_BOOTSTRAP+repo:cargo-public-api/cargo-public-api` → `total_count` **0**). **Verified by execution:** with `stable`, `1.91.1`, `1.93.0`, `1.96.0` and `1.97.1` installed and no nightly, `cargo-public-api 0.52.0` failed with `error: toolchain 'nightly-aarch64-apple-darwin' is not installed` / `Error: Failed to build rustdoc JSON`. Its README's compatibility table pins each release to a nightly window (`0.52.x` → `nightly-2025-11-22 —`; `0.50.x — 0.51.x` → `nightly-2025-08-02 — nightly-2025-11-21`), so the pinned nightly must be advanced roughly every few months in step with the tool.

Neither hides the fact that rustdoc JSON is unstable; `cargo-semver-checks` makes that operationally invisible while `cargo-public-api` makes it the operator's problem.

**The gap neither the language nor `cargo-semver-checks` closes — B6, stated rather than papered over.** With every internal module private and `deny(unreachable_pub)` on, a *new exported item* cannot reach consumers without appearing in `lib.rs`'s `pub use` list. That makes a reviewed `lib.rs` diff the addition detector on the stable lane, at zero tooling cost. The residual hole is a **new method, associated function, field, or trait impl on an already-exported type**: it touches neither `lib.rs` nor any semver rule. Verified empirically both ways against the same baseline: removing `Widget::id` gave `--- failure inherent_method_missing: pub method removed or renamed ---` and exit code **100**; adding `Widget::undocumented_addition` gave `196 checks: 196 pass`, `Summary no semver update required`, exit code **0**. Only a full-surface snapshot (`cargo-public-api`) closes that hole mechanically.

Four disciplines keep the `lib.rs`-as-review-surface property true, and each is worth writing into the template's contributor docs: (1) no `pub mod` for internals in `lib.rs` — namespaced `pub mod` is fine for deliberately public areas, as axum does, but a `pub mod` over internals reopens deep imports; (2) no glob `pub use internal::*`, which makes the surface unreviewable by diff; (3) no `#[doc(hidden)] pub` outside declarative-macro support code — that is precisely the `__all__` hole; (4) `#[macro_export]` reviewed explicitly, because it bypasses module privacy. Verified: a `#[macro_export] macro_rules! shout` defined inside the private `internal` module was callable from a consumer as `surface_demo::shout!()` and printed `escaped`.

**Maturity, dependability, performance and integration cost.** The language mechanisms are as mature as Rust itself: `pub(restricted)` was decided by [RFC 1422](https://rust-lang.github.io/rfcs/1422-pub-restricted.html) ("Expand the current `pub`/non-`pub` categorization of items with the ability to say 'make this item visible *solely* to a (named) module tree'"), and the private-in-public lints by [RFC 2145](https://rust-lang.github.io/rfcs/2145-type-privacy.html) ("Type privacy rules are documented. Private-in-public errors are relaxed and turned into lints"), both retrieved 2026-09-05. Runtime cost is zero — visibility and lints are compile-time only, produce no code, and add no dependency, so binary size and compile time are unchanged. CI cost, measured on this machine (Apple aarch64, `rustc 1.98.0`, 2026-09-05): the whole `cargo-semver-checks` run against a one-type crate reported `Finished [ 0.923s]` and `Checked [ 0.010s] 196 checks`; its prebuilt macOS binary is a 7.2 MB download expanding to a 21 MB executable; `cargo install cargo-public-api --locked --version 0.52.0` built in `50.09s` release. These are single-crate figures on a trivial workload — they establish order of magnitude, not a benchmark, and neither tool's cost scales with anything this template controls beyond its own surface size.

**Minimal realistic example.** A library crate whose `src/lib.rs` contains only lint attributes, `mod internal;`, one `pub use internal::Widget;`, and three doctests — two `compile_fail,E0603` proving deep imports are refused, one proving the sanctioned path works — with all types defined in `src/internal.rs`. That example is what I built and ran; its full text and results are in `### Validation strategy`.

**BASELINE-REVIEW findings: none.** F014's `COMMON → REUSE` classification survives scrutiny under A5: `pub use` is the language-supported re-export mechanism, the Rust Book ch. 14.2 recommends exactly this shape ("you can re-export items to make a public structure that's different from your private structure by using `pub use`"), and axum, tokio and hyper all practise it. I emit no `BASELINE-REVIEW:` line.

### Dominant choice

The Rust field's dominant enforcement mechanism is **the language's own module privacy system** — internals in private `mod`s, the curated surface published by `pub use` at the crate root — with **`cargo-semver-checks` in CI** as the mainstream drift gate on top. There is no ecosystem-wide analogue of ts's `exports` map because none is needed: the compiler already refuses the import. Adoption evidence for the CI half: 1,144 workflow files reference `cargo-semver-checks-action` (`GET https://api.github.com/search/code?q=cargo-semver-checks-action+path:.github/workflows`, 2026-09-05), including tokio, hyper and ratatui; the Rust project's own 2026 goal, status **Accepted**, is "Continue resolving `cargo-semver-checks` blockers for merging into cargo", with the cargo team envisioning `cargo publish` requiring semver compliance by default ([goals.rust-lang.org](https://goals.rust-lang.org/2026/cargo-semver-checks.html), retrieved 2026-09-05).

### Options

| Option | Where documented | Adopters that practise it | Most recent authoritative write-up |
|---|---|---|---|
| Private `mod` + crate-root `pub use` barrel | Rust Reference "Visibility and Privacy"; The Rust Book ch. 14.2 "Exporting a Convenient Public API with `pub use`"; RFC 1422 | tokio, axum (`axum/src/lib.rs:553-602`), hyper, ratatui, syntect | Rust Book ch. 14.2, current stable edition, retrieved 2026-09-05 |
| Denied reachability lints (`unreachable_pub`, `private_interfaces`, `private_bounds`, `missing_docs`) | rustc lint listings, allowed-by-default and warn-by-default pages; RFC 2145 | Widespread crate-root practice; `cargo-semver-checks` itself uses crate-root `forbid`/`deny` attributes (`src/lib.rs:1`) | rustc lint reference, current stable, retrieved 2026-09-05 |
| `compile_fail` doctest asserting a deep import is refused | rustdoc book, "Documentation tests" | Common in library test suites; used in the reference implementation built for this report | rustdoc book, current stable, retrieved 2026-09-05 |
| `cargo-semver-checks` CI gate (stable lane) | [github.com/obi1kenobi/cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks); `cargo-semver-checks-action` `action.yml` | tokio (`ci.yml:498-515`), hyper (`CI.yml:347-355`), ratatui (`check-semver.yml`); 1,144 workflow files ecosystem-wide | Rust Project Goals 2026, "Continue resolving `cargo-semver-checks` blockers for merging into cargo", status Accepted, retrieved 2026-09-05 |
| `cargo-public-api` committed surface snapshot | [github.com/cargo-public-api/cargo-public-api](https://github.com/cargo-public-api/cargo-public-api) README | syntect (`tests/public_api.rs`); 30 reverse dependencies of the `public-api` library; 88 workflow files ecosystem-wide | cargo-public-api README at `0.52.0`, retrieved 2026-09-05 |
| Convention-only (`#[doc(hidden)]`, docs prose) — the faithful py port | rustdoc book, "the `#[doc]` attribute" | py-launch-blueprint itself (`__all__`) | py `docs/design/0005-hexagonal-architecture-and-enforcement.md:298` (HEX-34), retrieved 2026-09-05 |
| Physical crate split with `publish = false` | Cargo manifest reference, "the `publish` field" | Common for `xtask` and fixture members; not usable under a published dependency | Cargo book, current stable, retrieved 2026-09-05 |

### Excluded by gate

**`cargo-check-external-types` — excluded.** Gates applied before any popularity weighing:

- Gate 1 (license compatible with `MIT OR Apache-2.0`): **pass with a caveat.** Declared `Apache-2.0` only (crates.io `/versions`, 2026-09-05). Because it is a CI-invoked binary and never enters the template's dependency tree, it imposes nothing on the template's dual license; this gate does not exclude it.
- Gate 2 (MSRV within stable minus 2 minors, declared as `rust-version`): **fail.** It declares no `rust-version` at all (crates.io `/versions` → `rust_version: null`), and its README requires an *active* nightly (`cargo +nightly check-external-types`), which cannot be reconciled with an MSRV floor tested in CI.
- Gate 3 (no open RustSec advisory; `unsafe` posture stated): **fail on the posture half.** No advisory (rustsec.org 404), but `GET https://api.github.com/search/code?q=unsafe_code+repo:awslabs/cargo-check-external-types` → `total_count` **0** — neither `forbid(unsafe_code)` nor `deny(unsafe_code)` appears anywhere in the repository, so the posture is unstated.
- Gate 4 (builds and is tested on `ubuntu-latest, macos-latest`): **fail.** `.github/workflows/ci.yml` runs seven jobs, every one `runs-on: ubuntu-latest`; there is no macOS job.
- Gate 5 (default features and async-runtime coupling): `inapplicable` — a standalone CI binary, not a dependency; no features are compiled into the template and it has no async-runtime coupling.
- Gate 6 (binary size and compile-time cost): `inapplicable` to the template's artifact — it links nothing into the template. Its CI cost is a `cargo install --locked` from source, since it ships no prebuilt release binaries.

It is also excluded on fit: it answers a different question (whether *external* types leak into the public API — the Rust API Guidelines' C-STABLE concern), not whether the curated surface drifted. Its `at-risk` maintenance state (zero maintainer replies across all 8 issues returned, 2024-05-29 to 2026-06-29) is corroborating, not the reason.

**Convention-only (`#[doc(hidden)]` / docs prose) — excluded, but by the item's own requirement rather than a fitness gate.** The prompt asks for the mechanism that gives the same non-bypassable guarantee ts's `exports` map gives. Convention-only gives none: verified by execution, a `#[doc(hidden)] pub fn` re-exported at the root was called successfully from a consumer crate.

No other candidate failed a gate. Both retained tools pass gates 1-4 as follows. `cargo-semver-checks`: `Apache-2.0 OR MIT` (gate 1 pass); declares `rust-version = 1.93` and its README distinguishes a compile MSRV from a runtime MSRV, supporting "at minimum ... the then-current stable and beta Rust versions" (gate 2 pass); no RustSec advisory and `#![forbid(unsafe_code)]` at `src/lib.rs:1` (gate 3 pass); CI is `ubuntu-latest` with a Windows binary-build job and no macOS job, but it ships an `aarch64-apple-darwin` release binary that I downloaded and ran successfully on macOS (gate 4 pass by execution). `cargo-public-api`: `MIT` (gate 1 pass); no declared `rust-version`, but installs and runs with `cargo +stable install` per its README and installed cleanly here on `1.98.0` (gate 2 pass on the stable half — the nightly requirement is a *separate* toolchain, not an MSRV raise); no RustSec advisory and `scripts/lint.sh:14` runs clippy with `--forbid unsafe_code` (gate 3 pass); its `CI.yml:77-80` matrix has `ubuntu-latest` and `windows-latest` with macOS commented out behind `# FIXME: Enable after fixing why 'warn_when_using_beta' fails`, so macOS CI is absent — but I built and ran it on `aarch64-apple-darwin` (gate 4 pass by execution, with the missing macOS job recorded as a real risk). Gate 5 for both: `inapplicable` — CI binaries, not template dependencies, with no async-runtime coupling. Gate 6 for both: no contribution to the template's binary size or compile time; CI cost is 7.2 MB download / 21 MB binary for `cargo-semver-checks` versus a 50.09 s source build for `cargo-public-api`.

### Up-and-comers

1. **rustdoc JSON stabilization** ([rust-lang/rust#76578](https://github.com/rust-lang/rust/issues/76578), retrieved 2026-09-05) — the substrate every surface tool reads. While it is unstable, `cargo-semver-checks` needs `RUSTC_BOOTSTRAP=1` and `cargo-public-api` needs a pinned nightly. Stabilization would remove the only structural objection to a snapshot lane.
2. **`cargo-semver-checks` merging into `cargo` itself** — Rust Project Goal 2026, point of contact Predrag Gruevski, teams cargo and rustdoc, status **Accepted**; the tool ships 245 lints today and the goal names cross-crate linting (re-export handling) as a remaining blocker. If this lands, the drift gate becomes first-party and this item's tool choice becomes moot.
3. **`unnameable_types`** (allow-by-default, RFC 2145) — catches types reachable but not nameable by consumers, the last visibility hole a curated surface leaves. Worth adopting as a `warn` when the template's surface grows past a handful of types; deferred here because at three exported items it has nothing to say.
4. **`cargo-check-external-types`** — the only maintained tool for the C-STABLE concern (external types in the public API). Currently `at-risk` and nightly-active; re-check if awslabs resumes issue triage.

### Fit for this template

The template is one repository presenting three shapes. The enforcement mechanism is not the same weight in each.

**Library — the shape this item exists for.** Full strength required: private `mod`s, root `pub use`, denied reachability lints, `compile_fail` doctests, and the CI drift gate. This is where "the sanctioned surface is the contract" has consumers who can be broken, and it is exactly the shape tokio, hyper, ratatui and syntect are in. The py precedent (`__all__`, unenforced) and the ts precedent (`exports`, resolver-enforced) both target this shape; Rust reaches a strictly stronger point than ts here, at compile time.

**CLI.** The binary crate is not a public API surface at all — nothing can import it, so B1 is vacuous. What matters instead is that the CLI consumes the library *through the same sanctioned surface a third party would*, i.e. `use rs_launch_blueprint::{...}` at the root and never a deep path. Under the recommended design this is enforced automatically when the binary lives in a separate crate from the library; within a single package (`src/main.rs` plus `src/lib.rs`), `src/main.rs` is compiled as a separate crate that links the library crate, so a deep import from `main.rs` fails identically. That makes the CLI a free, always-on consumer-side test of the surface. The drift gate should exclude the binary target: `cargo-semver-checks` has nothing to check on a `[[bin]]`, and the action's `package` / `exclude` inputs exist for exactly this.

**Web service.** Under the ledger's expectation that the web surface is optional and feature-gated (`web-extra-surface`, owned by R69), the enforcement mechanism must survive feature flags: a `#[cfg(feature = "web")] pub use web::Router;` at the root means the *sanctioned surface changes with the feature set*. Two consequences. First, the reviewed-`lib.rs`-diff property still holds — the `cfg` re-export is in the same reviewed file. Second, the drift gate must be told which feature group to check, or it silently checks only default features; tokio's own workflow does exactly this (`feature-group: only-explicit-features`, `features: ${{ env.TOKIO_STABLE_FEATURES }}`), and hyper's does too (`feature-group: only-explicit-features`). This template should follow that precedent rather than accept the default. The web adapter's internals (router construction, middleware wiring, handler types) stay `pub(crate)` behind the feature gate; only the composition entry point is exported.

### Recommendation

Adopt the pattern **`private-module root barrel + denied reachability lints + stable-lane semver gate`** — three layers, each with a distinct job, all on stable Rust.

**Layer 1 — reachability (replaces ts's `exports` map, strictly stronger).** Every module holding implementation is declared `mod name;` (private) in `src/lib.rs`. Nothing else lives in `src/lib.rs` except attributes, module declarations, and one `pub use` block naming every sanctioned item. Internals use `pub(crate)` where they must cross module lines. `pub mod` appears only for a deliberately namespaced *public* area (axum's `pub mod extract` shape), never over internals.

**Layer 2 — compiler-enforced hygiene.** At the crate root:

```rust
#![deny(unreachable_pub)]
#![deny(private_interfaces, private_bounds)]
#![deny(missing_docs)]
```

`unreachable_pub` and `missing_docs` are allow-by-default, so they must be opted into explicitly; `private_interfaces` and `private_bounds` are warn-by-default and are raised to `deny` so a leak fails the build rather than scrolling past. Add two `compile_fail,E0603` doctests in the `lib.rs` module documentation asserting that a deep import does not compile — this converts B1 from an argument into a test that `cargo test` runs on every commit, and it doubles as the reader-facing documentation of the contract.

**Layer 3 — CI drift gate on the stable lane.** `obi1kenobi/cargo-semver-checks-action@v2` in its own job, with `rust-toolchain: stable`, an explicit `feature-group`/`features` selection covering the optional web feature, and `baseline-rev` set to the last release tag (the action's crates.io-baseline default cannot work before the template's first publish; `baseline-rev` and `baseline-root` inputs exist for this). Action pinning policy belongs to R20 — reference it, do not decide it here.

**Addition detection (B6) is answered by review, not by Layer 3.** Because all internal modules are private and `unreachable_pub` is denied, a new *exported item* cannot reach consumers without appearing in `lib.rs`'s `pub use` block. `src/lib.rs` therefore *is* the surface snapshot, and a `CODEOWNERS`-reviewed diff of that one file is the addition gate — at zero tooling cost and with no nightly. The honest residual, proven above: a new method or field on an already-exported type is caught by neither `lib.rs` nor `cargo-semver-checks`. Accept that gap for a template whose surface is deliberately small, and document it, rather than importing a nightly toolchain to close it.

**Reference implementation.** Two, both maintained: `tokio-rs/axum` for the module-shape half (`axum/src/lib.rs:553-602` — private `mod`s for internals, `pub mod` namespaces for public areas, root `pub use` for hot items) and `tokio-rs/tokio` for the gate half (`.github/workflows/ci.yml:498-515` — a `semver` job on `rust-toolchain: ${{ env.rust_stable }}` with an explicit feature group). Plus the minimal end-to-end example built and executed for this report, reproduced under `### Validation strategy`.

### Ranked runner-up

**`cargo-public-api` committed surface snapshot** (`tests/public_api.rs` plus a checked-in `tests/public-api.txt`), following syntect's shape.

**The condition under which it wins:** the owner decides that an unreviewed *addition* to the public surface must fail CI mechanically rather than be caught by human review of a `lib.rs` diff — and accepts, in exchange, that CI installs a pinned nightly toolchain whose pin must be advanced in step with each `cargo-public-api` release (`0.52.x` → `nightly-2025-11-22 —`; `0.50.x — 0.51.x` → `nightly-2025-08-02 — nightly-2025-11-21`). It also becomes the better pick if the template's public surface grows past roughly a dozen types, at which point method-level additions on exported types stop being reviewable by eye — the exact residual gap the recommendation accepts. It is not mutually exclusive with the recommendation: syntect runs a snapshot test while tokio runs a semver gate, and a template could run both, at the cost of the nightly pin.

Second runner-up, distant: `cargo-check-external-types`, if the owner's priority turns out to be C-STABLE (no external types in the public API) rather than surface drift. It fails gates 2, 3 and 4 today and is `at-risk`, so this is a re-verify trigger, not a live option.

### Tradeoffs

**Versus `cargo-public-api` (ranked runner-up).** The recommendation gives up mechanical detection of surface *additions* — both new root exports (mitigated: they force a reviewed `lib.rs` diff) and new methods/fields on already-exported types (not mitigated; proven: `196 checks: 196 pass`, exit `0`, on an added public method). It also gives up a human-readable, diffable full-surface artifact in the repository, which is genuinely useful in review. Why the cost is accepted: closing the gap costs a nightly toolchain in CI on a template whose constraints say "Stable Rust only", and costs a recurring maintenance chore — advancing the nightly pin every few months as the compatibility table moves — imposed on every downstream user of this template, not just on its author. For a template whose curated surface is deliberately small, the cheaper detector (a reviewed one-file diff) covers the realistic failure mode.

**Versus a physical crate split (alternative E).** The recommendation gives up the strongest possible boundary — an internal crate that consumers cannot depend on because it does not exist on the registry. Why the cost is accepted: it is not available. `cargo publish --dry-run` refuses a published crate whose dependency is `publish = false` or lacks a version requirement, verified both ways, and this template publishes to crates.io (F075, F214). Layer 1 delivers the same *reachability* guarantee at zero packaging cost.

**Versus convention-only (the faithful py port).** The recommendation gives up nothing of value and costs three lint attributes plus two doctests. It deliberately departs from py's mechanism because py's own design document says that mechanism does not enforce (HEX-34).

**Versus doing nothing beyond Layer 1.** Layers 2 and 3 cost: three `deny` attributes that will occasionally fail a contributor's build with an error they have not seen before (`unreachable_pub` in particular is unfamiliar because it is allow-by-default), plus one CI job whose baseline must be configured. Why accepted: `deny(missing_docs)` and `deny(unreachable_pub)` are precisely the errors a *template* should teach, and Layer 3 is what tokio, hyper and ratatui all run.

**Versus a stricter lint set.** `unnameable_types` is deliberately left off. At three exported items it has nothing to report, and switching it on now would only add noise to a template that must build clean on first `cargo new`-equivalent use.

### Parameters

R04 owns no registered parameter — `research/CLAUDE.md`'s `owns` column for R04 is `—`, and `docs/port/PARAMETERS.md` lists no `researched` row owned by R04 (both retrieved 2026-09-05). No `owns <param> = <value>` lines.

- `assumes rust-edition = 2024` — the reference implementation was built and tested with `edition = "2024"` in `Cargo.toml`; all three doctests and both compile-failure checks pass under it.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — the reference implementation declares `rust-version = "1.96"`. Every mechanism recommended is long-stable: `pub(restricted)` since RFC 1422, the type-privacy lints since RFC 2145, `unreachable_pub` and `missing_docs` older still. Nothing in Layer 1 or Layer 2 raises the floor. Layer 3 is a CI binary, not a dependency, so it does not enter the MSRV computation; `cargo-semver-checks 0.50.0` declares `rust-version = 1.93` for *compiling itself*, which is satisfied by any stable in this policy's window.
- `assumes license = MIT OR Apache-2.0` — no runtime dependency is added, so nothing enters the template's license tree. `cargo-semver-checks` is `Apache-2.0 OR MIT`, itself compatible even if it were linked.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — the reference implementation is pure language machinery and is OS-independent. `cargo-semver-checks 0.50.0` was executed on macOS `aarch64-apple-darwin` for this report and ships prebuilt binaries for `aarch64-apple-darwin`, `x86_64-apple-darwin`, and both `x86_64`/`aarch64` Linux gnu and musl (`GET https://api.github.com/repos/obi1kenobi/cargo-semver-checks/releases/latest`, 2026-09-05), covering both required runners.

No `CONFLICT:` lines. The recommendation needs no registered value changed.

Recorded dependency note for R02 (not a `CONFLICT:`, because no registered parameter is involved, and not a `BASELINE-REVIEW:`, because F021 is `RUST-ONLY` with no inherited baseline to challenge): if R02 chooses a multi-crate topology, any member reachable from the published library crate's `[dependencies]` must itself be published to crates.io. `publish = false` is available only for members outside that graph. Both failure modes were verified by execution and are quoted in `### Principles and implementation`.

### Migration implications

File-level changes in the template. Paths assume a single package until R02 decides otherwise; the same edits apply per public crate in a multi-crate topology.

- **`src/lib.rs`** — becomes surface-only. Contents: crate documentation including the two `compile_fail,E0603` doctests and one passing doctest; the three `#![deny(...)]` attributes; private `mod` declarations for every internal module; exactly one `pub use` block naming the sanctioned items; `#[cfg(feature = "web")]` guarding any web-only re-export. No type, function, or trait is *defined* here.
- **`src/*.rs` (internal modules)** — items default to private; `pub(crate)` where they cross module lines within the crate; `pub` only on items that appear in `lib.rs`'s `pub use` block. `deny(unreachable_pub)` makes any mistake here a compile error, so this is mechanically checked, not a review convention.
- **`src/main.rs` (or `src/bin/`)** — imports the library only through the root path, e.g. `use rs_launch_blueprint::{Config, run};`. No deep paths. This compiles as a separate crate, so the compiler enforces it.
- **`Cargo.toml`** — no new `[dependencies]` or `[dev-dependencies]` entries; the pattern adds nothing to the dependency tree. `rust-version` and `edition = "2024"` per the fixed parameters. If R02 selects a multi-crate topology, `publish = false` may be set only on members outside the published crate's dependency graph.
- **`.github/workflows/ci.yml`** — one new job running `obi1kenobi/cargo-semver-checks-action@v2` with `rust-toolchain: stable`, `baseline-rev` pointing at the last release tag, and explicit `feature-group` / `features` covering the optional web feature. Job placement and whether it joins the aggregate required check are R11's and R12's decisions; the action reference's pinning form is R20's. Skip-gating this job on library-path changes is likewise R11's call.
- **`CONTRIBUTING.md` (or the template's contributor doc)** — a short "public API surface" section stating the four disciplines: no `pub mod` over internals, no glob re-exports, no `#[doc(hidden)] pub` outside macro-support code, and `#[macro_export]` reviewed explicitly because it bypasses module privacy.
- **Files *not* added:** no `tests/public-api.txt`, no `rust-toolchain.toml` pinning a nightly, no `external-types.toml`. Those belong to the ranked runner-up and the excluded candidate respectively.

### Validation strategy

Toolchain and OS for everything below: `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, macOS `aarch64-apple-darwin`, 2026-09-05. Installed rustup toolchains at the time of the runs: `stable` (active, default), `1.91.1`, `1.93.0`, `1.96.0`, `1.97.1` — **no nightly**, which is what makes the toolchain results below meaningful.

**Executed — the reference implementation.** A crate `surface_demo` (`edition = "2024"`, `rust-version = "1.96"`, `license = "MIT OR Apache-2.0"`):

`src/lib.rs`

```rust
//! Curated public surface: this file is the only sanctioned import path.
//!
//! A deep import of an internal module does not compile:
//! ```compile_fail,E0603
//! use surface_demo::internal::Engine;
//! ```
//!
//! A private-but-reachable item is also unreachable by path:
//! ```compile_fail,E0603
//! let _ = surface_demo::internal::SECRET;
//! ```
//!
//! The curated re-export does compile:
//! ```
//! use surface_demo::Widget;
//! let _ = Widget::new(7);
//! ```
#![deny(unreachable_pub)]
#![deny(private_interfaces, private_bounds)]
#![deny(missing_docs)]

mod internal;

pub use internal::Widget;
```

`src/internal.rs` defines `pub(crate) const SECRET: u32 = 42;`, `pub struct Widget { id: u32 }` with `pub fn new` and `pub fn id`, and `pub(crate) struct Engine;`.

**Executed check 1 — the surface behaves as specified.** `cargo test -p surface_demo` → `test surface_demo/src/lib.rs - (line 14) ... ok`; `test surface_demo/src/lib.rs - (line 4) - compile fail ... ok`; `test surface_demo/src/lib.rs - (line 9) - compile fail ... ok`; `test result: ok. 2 passed; 0 failed` and `test result: ok. 1 passed; 0 failed`. Expected behavior: the sanctioned path compiles, both deep paths do not. **Observed as expected.**

**Executed check 2 — an external consumer cannot deep-import (B1).** A separate crate depending on `surface_demo = { path = ... }` with `let _w = surface_demo::internal::Widget::new(1);` → `cargo build` fails: `error[E0603]: module 'internal' is private`, with the note `struct 'Widget' is not publicly re-exported`. Expected: compile failure. **Observed as expected.** This is the direct equivalent of Node refusing a non-listed subpath under ts's `exports` map, moved from resolution time to compile time.

**Executed check 3 — an unreachable `pub` is an error (B4).** Adding `pub struct Leaked;` to the private `internal` module → `error: unreachable 'pub' item ... help: consider restricting its visibility: 'pub(crate)'`, `error: could not compile 'surface_demo' (lib) due to 1 previous error`. Expected: build failure. **Observed as expected.**

**Executed check 4 — no private type escapes a public signature (B3).** Adding `pub fn engine(&self) -> Engine` where `Engine` is `pub(crate)` → `error: type 'Engine' is more private than the item 'Widget::engine'`, with `note: but type 'Engine' is only usable at visibility 'pub(crate)'`. Expected: build failure. **Observed as expected.**

**Executed check 5 — the documented escape hatches really are escape hatches.** A `#[macro_export] macro_rules! shout` defined inside the private `internal` module, and a `#[doc(hidden)] pub fn escape_hatch()` re-exported at the root, were both reachable from the consumer crate: `cargo run` printed `escaped` then `42`. Expected: both succeed, demonstrating the two holes the contributor documentation must name. **Observed as expected.**

**Executed check 6 — the drift gate runs on stable and catches a removal (B5).** `cargo-semver-checks 0.50.0` (prebuilt `aarch64-apple-darwin` binary from the `v0.50.0` GitHub release) run as `cargo-semver-checks semver-checks --manifest-path surface_demo/Cargo.toml --baseline-root <baseline copy>` after deleting `Widget::id` → `Checked [ 0.010s] 196 checks: 195 pass, 1 fail, 0 warn, 58 skip`, `--- failure inherent_method_missing: pub method removed or renamed ---`, `Summary semver requires new major version: 1 major and 0 minor checks failed`, exit code **100**. Expected: nonzero exit naming the removed item, with no nightly toolchain present. **Observed as expected.**

**Executed check 7 — the drift gate does *not* catch an addition (the accepted gap).** Same command with `Widget::undocumented_addition` added instead → `196 checks: 196 pass, 58 skip`, `Summary no semver update required`, exit code **0**. Expected (per the tool's documented purpose — it lints semver breakage, not surface change): exit 0. **Observed as expected.** This is the evidence behind the recommendation's stated residual gap.

**Executed check 8 — `cargo-public-api` requires nightly.** `cargo install cargo-public-api --locked --version 0.52.0` succeeded on stable in `50.09s`; running `cargo-public-api public-api --manifest-path surface_demo/Cargo.toml` with no nightly installed → `error: toolchain 'nightly-aarch64-apple-darwin' is not installed`, `Error: Failed to build rustdoc JSON`. Expected per its README. **Observed as expected.** This is the fact that ranks it second rather than first.

**Executed check 9 — `publish = false` cannot sit under a published crate.** A two-member workspace where the public crate depends on an internal `publish = false` member: with `version = "0.1.0"` on the dependency, `cargo publish --dry-run -p <public> --allow-dirty` → `error: failed to prepare local package for uploading` / `no matching package named 'rs_blueprint_internal_demo' found` / `location searched: crates.io index`; with the version removed, → `error: failed to verify manifest ... all dependencies must have a version requirement specified when publishing.` Expected: refusal in both forms. **Observed as expected.**

**Planned, not executed (and why).**

- The `cargo-semver-checks-action` job in a real GitHub Actions run on `ubuntu-latest` and `macos-latest`. Not executed because no CI run exists for this template yet. Expected behavior on first run: with `baseline-rev` unset and no crates.io release, the action fails to find a baseline — which is exactly why `baseline-rev` must be set explicitly. Verification once the template has CI: open a PR removing one `pub use` line and confirm the `semver` job fails; open a PR adding a `pub use` line and confirm the job passes while the `lib.rs` diff is what review catches.
- `cargo-public-api` snapshot behavior (the runner-up). Not executed because it needs a nightly toolchain installed, which would mutate this machine's rustup state beyond the scope of a research run. Expected per its README: `assert_eq_or_update` writes `tests/public-api.txt` and fails the test when the surface differs, with `UPDATE_SNAPSHOTS=yes` to re-baseline.
- MSRV verification of the whole pattern at the policy floor. Not executed — the floor's concrete value follows from the stable release at implementation time. Expected: no failure, since every mechanism used predates any plausible floor by many releases.

### Confidence & re-verify trigger

**High confidence** on the reachability half (Layer 1 and Layer 2). It rests on the language reference, two accepted RFCs, and nine executed compiler outcomes on the current stable toolchain — not on inference. The claim that Rust's guarantee is stronger than ts's `exports` map is a compile-time-versus-resolution-time argument backed by `E0603` in an actual consumer build.

**Medium-high confidence** on Layer 3's tool choice. The evidence is strong (tokio, hyper and ratatui all run it on stable; the Rust project has an Accepted 2026 goal to merge it into cargo; I executed it on stable with no nightly present), but it depends on an unstable substrate reached through `RUSTC_BOOTSTRAP=1`, and on `cargo-semver-checks` releases continuing to track stable rustc promptly. Its 161 open issues are a function of an ambitious lint backlog rather than neglect (median 2.05 days to first maintainer reply on externally filed issues), but three externally filed issues opened in the ten days before retrieval were still unanswered, which is worth watching rather than dismissing.

**Medium confidence** on the accepted B6 gap. The judgement that a reviewed `lib.rs` diff is sufficient addition detection holds for a small curated surface. It weakens as the surface grows, and it depends on the four disciplines being followed; only two of the four (`no pub mod over internals`, `no #[doc(hidden)] pub`) are partially mechanically enforced.

**Re-verify triggers.**

1. rustdoc JSON stabilizes ([rust-lang/rust#76578](https://github.com/rust-lang/rust/issues/76578)) — `cargo-public-api` loses its nightly requirement and the ranked runner-up may become the recommendation outright.
2. `cargo-semver-checks` lands inside `cargo publish` (Rust Project Goals 2026) — Layer 3 becomes first-party and the CI job may be replaced by a `cargo publish` flag.
3. `cargo-semver-checks` gains addition/surface-change detection, or the template's public surface passes roughly a dozen exported types — either closes or widens the accepted B6 gap.
4. `unreachable_pub` changes default level in a future edition — the explicit `deny` becomes redundant but remains harmless.
5. `cargo-semver-checks` misses a stable release window (its README's support promise is "the then-current stable and beta"), or its externally filed unanswered-issue count keeps growing past the 3-in-10-days observed here.
6. R02 selects a multi-crate topology — re-read the `publish = false` finding before designing the crate graph.

Calendar re-verify: **2027-03-05** (six months), or immediately on any trigger above.

### Sources

Source repositories, pinned. py-launch-blueprint at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`; ts-launch-blueprint at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. Both read locally 2026-09-05.

- py `src/py_launch_blueprint/core/__init__.py:61-85` — `__all__` with 23 names. Retrieved 2026-09-05.
- py `docs/design/0005-hexagonal-architecture-and-enforcement.md:298` — HEX-34, "`__all__` documents, it does not enforce ... a convention, not a guard". Retrieved 2026-09-05.
- ts `src/lib.ts:1-3,5` — "The root export is the only stable API surface (D-012(3))". Retrieved 2026-09-05.
- ts `package.json:24-30` — root-only `exports` map. Retrieved 2026-09-05.
- ts `docs/port/TS_PORT_DECISIONS.md:88` — D-012(3), hand-authored root-only exports map. Retrieved 2026-09-05.
- This repo: `docs/port/COMMONALITY.md:20` (F014), `:21` (F015), `:27` (F021), `:81` (F075), `:218` (F214); `docs/port/BASELINE-REVIEW.md:38` (F014 retained); `docs/port/areas/workspace-architecture.md:20-21`; `docs/port/PARAMETERS.md`; `research/CLAUDE.md` (R04 `owns: —`). All retrieved 2026-09-05.

Rust project publications. [Rust Reference — Visibility and Privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html); [The Rust Book ch. 14.2 — Exporting a Convenient Public API with `pub use`](https://doc.rust-lang.org/book/ch14-02-publishing-to-crates-io.html); [rustc lints — allowed-by-default](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html) (`unreachable_pub`, `missing_docs`); [rustc lints — warn-by-default](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html) (`private_interfaces`, `private_bounds`); [RFC 1422 `pub(restricted)`](https://rust-lang.github.io/rfcs/1422-pub-restricted.html); [RFC 2145 Type privacy](https://rust-lang.github.io/rfcs/2145-type-privacy.html); [Rust API Guidelines — Necessities (C-STABLE, C-PERMISSIVE)](https://rust-lang.github.io/api-guidelines/necessities.html) and [Future proofing (C-SEALED, C-STRUCT-PRIVATE, C-NEWTYPE-HIDE, C-STRUCT-BOUNDS)](https://rust-lang.github.io/api-guidelines/future-proofing.html); [Cargo manifest reference — the `publish` field](https://doc.rust-lang.org/cargo/reference/manifest.html#the-publish-field); [Rust Project Goals 2026 — Continue resolving `cargo-semver-checks` blockers for merging into cargo](https://goals.rust-lang.org/2026/cargo-semver-checks.html); [rust-lang/rust#76578 — rustdoc JSON tracking issue](https://github.com/rust-lang/rust/issues/76578); [2025 State of Rust Survey results](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/). All retrieved 2026-09-05.

Maintainers' documentation and source. [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api) (nightly requirement; nightly compatibility table; `cargo +stable install`); [cargo-public-api `.github/workflows/CI.yml:77-80`](https://raw.githubusercontent.com/cargo-public-api/cargo-public-api/main/.github/workflows/CI.yml) (macOS job commented out behind a FIXME); [cargo-public-api `scripts/lint.sh:14`](https://raw.githubusercontent.com/cargo-public-api/cargo-public-api/main/scripts/lint.sh) (`--forbid unsafe_code`); [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks) (stable/beta support promise; nightly best-effort; compile vs runtime MSRV); [cargo-semver-checks `src/data_generation/generate.rs:544` at `b778c28f`](https://github.com/obi1kenobi/cargo-semver-checks/blob/b778c28f67b6a537bab95a344c9aac38706f02cc/src/data_generation/generate.rs#L544) (`RUSTC_BOOTSTRAP=1`); [cargo-semver-checks `src/lib.rs:1`](https://raw.githubusercontent.com/obi1kenobi/cargo-semver-checks/main/src/lib.rs) (`#![forbid(unsafe_code)]`); [cargo-semver-checks-action `action.yml`](https://raw.githubusercontent.com/obi1kenobi/cargo-semver-checks-action/main/action.yml) (`rust-toolchain` default `stable`; `baseline-version`, `baseline-rev`, `baseline-root`, `package`, `exclude`, `feature-group`, `features`); [cargo-check-external-types README](https://raw.githubusercontent.com/awslabs/cargo-check-external-types/main/README.md) (`cargo +nightly`, last tested `nightly-2026-03-20`); [cargo-check-external-types `.github/workflows/ci.yml`](https://raw.githubusercontent.com/awslabs/cargo-check-external-types/main/.github/workflows/ci.yml) (all jobs `ubuntu-latest`). All retrieved 2026-09-05.

Practice evidence. [tokio `.github/workflows/ci.yml:498-515`](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/workflows/ci.yml); [hyper `.github/workflows/CI.yml:32,347-355`](https://raw.githubusercontent.com/hyperium/hyper/master/.github/workflows/CI.yml); [ratatui `.github/workflows/check-semver.yml`](https://raw.githubusercontent.com/ratatui/ratatui/main/.github/workflows/check-semver.yml); axum `axum/src/lib.rs:553-602` via `GET https://api.github.com/repos/tokio-rs/axum/contents/axum/src/lib.rs`; syntect `tests/public_api.rs` via `GET https://api.github.com/search/code?q=public-api+repo:trishume/syntect` and `GET https://api.github.com/repos/trishume/syntect`. All retrieved 2026-09-05.

**Method notes.** Endpoints queried on 2026-09-05, all with a `User-Agent` header where required: `GET https://crates.io/api/v1/crates/{cargo-public-api,cargo-semver-checks,cargo-check-external-types}` for `crate.recent_downloads` and `crate.downloads`; `GET https://crates.io/api/v1/crates/<name>/versions` for the newest non-yanked `num`, `created_at`, `license`, `rust_version` and `edition`; `GET https://crates.io/api/v1/crates/public-api/reverse_dependencies` for adopters; `GET https://api.github.com/repos/<o>/<r>` for `stargazers_count`, `archived` and `pushed_at`; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for `total_count` (never `open_issues_count`, whose differing values — 4, 182, 12 — are recorded here only to show they were not used); `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100` plus `GET .../issues/<n>/comments` over the 10 most recently opened non-PR issues for the responsiveness figures; `GET https://api.github.com/search/code?q=...` for unsafe-posture and adoption counts; `GET https://api.github.com/repos/<o>/<r>/contents/...` and `https://raw.githubusercontent.com/...` for workflow and source text; `https://rustsec.org/packages/<name>.html` for advisories (HTTP 404 for all three, meaning no advisory page exists — recorded as "no recorded advisory", not as a failed fetch). Local execution used `cargo 1.98.0` / `rustc 1.98.0` on macOS `aarch64-apple-darwin`, the prebuilt `cargo-semver-checks 0.50.0` `aarch64-apple-darwin` release binary, and `cargo-public-api 0.52.0` installed from source into a scratch root.

Could not verify: (1) the 2025 State of Rust Survey contains no question or finding bearing on public-API surface enforcement, so the annual-survey authority class contributed nothing beyond being consulted; (2) `cargo-public-api`'s snapshot behavior in practice — it needs a nightly toolchain installed, which was outside the scope of this run, so that check is recorded as planned, not executed; (3) `cargo-public-api`'s README "Used by" section could not be read — a grep of the raw README on `main` returned no such section, so its adopters are evidenced instead through the `public-api` library's crates.io reverse-dependency list and syntect's committed `tests/public_api.rs`; (4) the exact Rust release that stabilized `private_interfaces` and `private_bounds` — the 1.74.0 release announcement does not mention them, so the claim rests on RFC 2145 and the current warn-by-default lint listing plus an executed 1.98.0 run, which is sufficient because the MSRV floor makes the precise release moot; (5) no GitHub Actions run of the recommended CI job exists yet for this template, so Layer 3's in-CI behavior is planned rather than executed.
