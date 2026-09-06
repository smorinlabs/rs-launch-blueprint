# R06 — `unsafe` code policy (pattern) — raw report

Item: R06 · kind: `pattern` · tier: focused · actor: `research-opus-2026-09-05T162400Z-31f07a2b91b6` · model `claude-opus-5[1m]`.
Every figure and claim below carries its endpoint or URL and the retrieval date **2026-09-06**.

### Landscape

**The category this item decides.** This item decides a *repo-wide safety-boundary policy* and the *mechanism that expresses and enforces it*. "Policy" is the decision (may `unsafe` appear in code this template ships, and under what documentation obligation); "mechanism" is the concrete artifact a reader can point at (a lint level, an attribute, a comment convention, a tool invocation). The category is **compiler-and-Cargo lint configuration**, not a library-selection category. That distinction is load-bearing: the whole shortlist is toolchain-native, so the crate figure table in `## Required evidence` is inapplicable to most candidates, and each such inapplicability is stated per candidate under `### Excluded by gate` and `### Options` rather than silently omitted.

**Three-bin map of the Rust field.**

| Bin | Candidates found |
|---|---|
| Built-in / first-party toolchain | (1) rustc lint `unsafe_code` at level `forbid`; (2) the same lint at `deny`; (3) the same lint at `warn`; (4) delivery via a crate-root inner attribute `#![forbid(unsafe_code)]` / `#![deny(unsafe_code)]`; (5) delivery via the Cargo `[lints.rust]` table; (6) delivery via `[workspace.lints.rust]` plus `[lints] workspace = true` in each member; (7) the edition-2024 default `unsafe_op_in_unsafe_fn` warning; (8) `#[expect(lint, reason = "…")]` as a self-expiring, reason-carrying escape hatch (stabilized Rust 1.81.0); (9) `--cap-lints`, the Cargo behavior that bounds any such policy to the local package |
| Established industry standard | (10) the `// SAFETY:` comment convention, as codified by the Rust standard library's own *Safety comments policy*; (11) clippy `undocumented_unsafe_blocks` (restriction group, clippy 1.58.0) enforcing that convention mechanically; (12) its two companions `multiple_unsafe_ops_per_block` and `unnecessary_safety_comment`; (13) clippy `allow_attributes` / `allow_attributes_without_reason`, which force an escape hatch to carry a written reason; (14) `cargo-geiger`, the `unsafe`-footprint counter for a whole dependency tree |
| Up-and-comer | (15) `cargo-vet` (Mozilla), supply-chain audit records that can encode an `unsafe`-review criterion; (16) `cargo-crev`, distributed code review — *not* shortlisted, see `### Up-and-comers` |

Item (9) is the reason no policy in this list can be stated as absolute, and it is why the MEDIUM question about dependencies has a documentation answer rather than a tooling answer.

**Authoritative sources used, and why each is authoritative.**

| Source | Why it is authoritative | URL (retrieved 2026-09-06) |
|---|---|---|
| *The rustc book* — Lint levels | The compiler team's own normative description of what `allow`/`warn`/`deny`/`forbid` mean and how `--cap-lints` interacts with them. This is the specification, not commentary. | https://doc.rust-lang.org/rustc/lints/levels.html |
| *The rustc book* — Allowed-by-default lints | The compiler team's own listing that fixes `unsafe_code`'s default level and its exact scope (blocks *and* `no_mangle` / `export_name` / `link_section`). | https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html |
| *The Cargo Book* — The `[lints]` section | Cargo team's normative manifest reference; also states the dependency scoping rule verbatim. | https://doc.rust-lang.org/cargo/reference/manifest.html |
| *The Cargo Book* — Workspaces, "The lints table" | Cargo team's normative reference for `[workspace.lints]` inheritance, including its stated MSRV. | https://doc.rust-lang.org/cargo/reference/workspaces.html |
| *Rust Edition Guide* — `unsafe_op_in_unsafe_fn` warning | The edition team's statement of what edition 2024 (the owner-fixed `rust-edition`) changes about `unsafe`. Directly binding on this template. | https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-op-in-unsafe-fn.html |
| *Standard library developers Guide* — Safety comments policy | The libs team's own written policy; it is the origin of the `// SAFETY:` convention that clippy later mechanized. A convention's authority is the body that practices it at scale. | https://std-dev-guide.rust-lang.org/policy/safety-comments.html |
| Rust 1.81.0 release announcement | A Rust project release note is first-party and dated; it stabilizes `#[expect]` and, in its own text, names `undocumented_unsafe_blocks` as the worked migration example and names the two clippy `allow_attributes*` lints. | https://blog.rust-lang.org/2024/09/05/Rust-1.81.0/ |
| `rust-lang/rust-clippy` lint source | Clippy is a Rust project tool (`rust-lang` org, 13,491 stars, not archived, pushed 2026-09-04, endpoint `GET https://api.github.com/repos/rust-lang/rust-clippy`). The lint's own `declare_clippy_lint!` doc comment is the maintainers' definition, including its group and `#[clippy::version]`. | https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/undocumented_unsafe_blocks.rs |
| *Clippy Book* — Lint configuration | Maintainers' documentation for the two `undocumented_unsafe_blocks` configuration keys and their defaults. | https://doc.rust-lang.org/clippy/lint_configuration.html |
| Rust API Guidelines checklist | The Rust libs-team-adjacent guideline set the prompt cites. Used here to *correct* the prompt's citation — see the note below. | https://rust-lang.github.io/api-guidelines/checklist.html |

**Citation correction (do not propagate the prompt's ID).** The prompt's MEDIUM question cites "Rust API Guidelines C-SAFETY". Fetching the checklist and searching it for every `C-` identifier returns **no `C-SAFETY` item**; the only safety-related guideline is **`C-FAILURE` — "Function docs include error, panic, and safety considerations"** (https://rust-lang.github.io/api-guidelines/checklist.html, retrieved 2026-09-06). `C-FAILURE` governs the `# Safety` *rustdoc section on an unsafe function's public documentation* — a different artifact from the `// SAFETY:` *comment above a call site*. The authority for the call-site comment convention is the standard library's Safety comments policy, cited above, not the API Guidelines. This report uses the correct pair and names both artifacts distinctly.

**Two deliberate evidence gaps, stated rather than papered over.**
1. **The Rust CLI working group's book does not address `unsafe` at all.** Its full-text search index covers 69 documents and contains zero occurrences of the token `unsafe` (`https://rust-cli.github.io/book/searchindex.json`, retrieved 2026-09-06; verified by both a structural check of the inverted index and a raw `grep -o -i unsafe` over the file, which returned 0). The prompt's HIGH question asks what that book prescribes; the answer is that it prescribes nothing here.
2. **The annual Rust survey does not measure this.** The 2024 State of Rust Survey results post contains zero occurrences of `unsafe` (`https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/`, retrieved 2026-09-06; `grep -o -i unsafe` over the fetched page returned 0). No survey figure can be cited for adoption of a forbid-vs-deny policy, and none is invented below. Practice evidence is therefore drawn from source code, which is stronger anyway.

**Well-regarded projects surveyed, with the evidence that they are well regarded.** Star counts and `pushed_at` are from `GET https://api.github.com/repos/<o>/<r>` (authenticated `gh api`, retrieved 2026-09-06); download counts are `crate.recent_downloads` (90-day) and `crate.downloads` (all-time) from `GET https://crates.io/api/v1/crates/<name>` (retrieved 2026-09-06). Policy lines were read from the projects' own source at `https://raw.githubusercontent.com/<o>/<r>/HEAD/<path>` (retrieved 2026-09-06); line numbers are as of that fetch of the default branch.

| Project | Shape | Well-regarded evidence | `unsafe` policy actually set | Where |
|---|---|---|---|---|
| `tokio-rs/axum` | web | 27,029 stars, pushed 2026-09-04; `axum` 112,742,897 downloads/90d, 456,207,013 all-time | **`unsafe_code = "forbid"`** via `[workspace.lints.rust]`, inherited by members with `[lints] workspace = true` | `Cargo.toml:8-9`; `axum/Cargo.toml:246-247` |
| `clap-rs/clap` | library (CLI parser) | 16,686 stars, pushed 2026-09-02; `clap` 225,333,330 downloads/90d, 1,107,038,264 all-time | **`#![forbid(unsafe_code)]`** crate-root attribute, plus workspace `unsafe_op_in_unsafe_fn = "warn"` | `clap_builder/src/lib.rs:9`; `Cargo.toml:27,31` |
| `rustls/rustls` | library (TLS) | 7,596 stars, pushed 2026-09-05; `rustls` 192,946,115 downloads/90d, 888,756,315 all-time | **`#![forbid(unsafe_code, unused_must_use)]`** crate-root attribute | `rustls/src/lib.rs:305` |
| `algesten/ureq` | library (HTTP client) | 2,181 stars, pushed 2026-08-23; `ureq` 56,213,012 downloads/90d, 194,489,474 all-time | **`#![forbid(unsafe_code)]`** crate-root attribute | `src/lib.rs:524` |
| `sharkdp/bat` | CLI | 60,375 stars, pushed 2026-09-04 | **`#![deny(unsafe_code)]`**, repeated in both the library root and the binary root | `src/lib.rs:22`; `src/bin/bat/main.rs:1` |
| `tower-rs/tower-http` | web (middleware) | 909 stars, pushed 2026-09-05; `tower-http` 139,193,758 downloads/90d, 436,133,058 all-time | **`#![deny(unsafe_code)]`** crate-root attribute | `tower-http/src/lib.rs:200` |
| `astral-sh/uv` | CLI | 89,500 stars, pushed 2026-09-06 | **`unsafe_code = "warn"`** via `[workspace.lints.rust]` | `Cargo.toml:346-347` |
| `astral-sh/ruff` | CLI | 49,509 stars, pushed 2026-09-06 | **`unsafe_code = "warn"`** via `[workspace.lints.rust]` | `Cargo.toml:231-232` |
| `casey/just` | CLI | 35,655 stars, pushed 2026-09-01 | No `unsafe_code` level; **`clippy::undocumented_unsafe_blocks = "deny"`** in `[lints.clippy]` | `Cargo.toml:64-66, 84` |
| `dtolnay/anyhow` | library | 6,646 stars, pushed 2026-08-22 | No `unsafe_code` level; `#![deny(…, unsafe_op_in_unsafe_fn, …)]` | `src/lib.rs:212` |
| `tokio-rs/tokio` | async runtime | 33,078 stars, pushed 2026-09-05 | No `unsafe_code` level (it needs `unsafe`); `#![deny(unused_must_use, unsafe_op_in_unsafe_fn)]` | `tokio/src/lib.rs:13` |
| `BurntSushi/ripgrep` | CLI | 67,989 stars, pushed 2026-08-04 | **None set** (no `unsafe_code`, no `[lints]` table) | `Cargo.toml`, `crates/core/main.rs` |
| `sharkdp/fd` | CLI | 44,321 stars, pushed 2026-09-02 | **None set** | `Cargo.toml`, `src/main.rs` |
| `starship/starship` | CLI | 59,798 stars, pushed 2026-09-06 | `[lints.clippy]` only; no `unsafe_code` level | `Cargo.toml:139` |
| `actix/actix-web` | web | 24,820 stars, pushed 2026-09-02 | `[workspace.lints.rust]` present but sets no `unsafe_code` level | `Cargo.toml:53-56` |
| `serde-rs/serde` | library | 10,801 stars, pushed 2026-08-25 | **None set** | `Cargo.toml`, `serde/src/lib.rs` |
| `seanmonstar/reqwest` | web (client) | 11,812 stars, pushed 2026-09-01 | `[lints.rust]` present but sets no `unsafe_code` level | `Cargo.toml:214` |
| `hyperium/hyper` | web (HTTP core) | 16,307 stars, pushed 2026-09-01 | No `unsafe_code` level | `Cargo.toml:101,108` |

**Reading of the practice evidence.** Among the 18 surveyed projects, 4 set `forbid` (axum, clap, rustls, ureq), 2 set `deny` (bat, tower-http), 2 set `warn` (uv, ruff), and 10 set no level at all. Every project that sets `forbid` or `deny` is one whose own code genuinely needs no `unsafe`; several projects that set nothing do need `unsafe` internally (tokio and hyper say so through their own `unsafe_op_in_unsafe_fn` denials); for ripgrep and fd this report checked only the manifest and crate roots and did **not** determine whether their code needs `unsafe`, so no motive is attributed to them.

**Does anyone choose `deny` to keep a per-block escape hatch? Almost nobody, and the one instance is instructive.** This was checked rather than assumed, using GitHub code search over the two `deny` adopters' whole repositories (`GET https://api.github.com/search/code?q=repo:<o>/<r>+…`, retrieved 2026-09-06). `sharkdp/bat`: 2 occurrences of `unsafe_code` in the entire repository — the two crate-root attributes already cited — and **0** occurrences of `allow(unsafe_code)`. `tower-rs/tower-http`: 2 occurrences of `unsafe_code` and **1** occurrence of `allow(unsafe_code)`, which sits at `tower-http/src/services/fs/serve_dir/tests.rs:1233`, guarded by `#[cfg(windows)]`, on a test helper `fn verify_windows_device`. So the single escape hatch in either project is Windows-only test scaffolding, not production code taking on `unsafe` under justification. The forked-template rationale the prompt's HIGH question hypothesizes for `deny` — keeping a per-block hatch open for real work — is therefore not attested among the `deny` adopters; it has to be argued on its own merits, which `### Recommendation` and `### Tradeoffs` do. It *is* attested among the `warn` adopters, in a form the prompt does not anticipate — see `### Up-and-comers`.

**Comparable *templates* are silent.** The prompt asks what comparable Rust CLI/library/web-service templates set. The `cargo-generate` topic's most-starred general-purpose templates were read directly: `rust-github/template` (237 stars, pushed 2026-07-02) has exactly three code files — `template/Cargo.toml`, `template/src/lib.rs`, `template/src/main.rs` (enumerated via `GET https://api.github.com/repos/rust-github/template/git/trees/HEAD?recursive=1`) — and **none of them mentions `unsafe` in any form**; `ratatui/templates` (420 stars, pushed 2026-08-14) likewise sets nothing in `simple/template/Cargo.toml` or `simple/template/src/main.rs`. `cargo-generate` itself (2,484 stars, pushed 2026-09-04) ships no curated template list — its README points at the GitHub `cargo-generate` topic. **Finding: the template layer of the ecosystem has no convention here.** This is a genuine gap, and it means the template layer supplies no counter-evidence to the library/application layer's clear `forbid` signal.

**First-party documentation is not neutral between the levels.** Both Cargo reference sections that introduce lint configuration use `unsafe_code = "forbid"` as their *canonical worked example* — the `[lints]` section opens with `[lints.rust]` / `unsafe_code = "forbid"` (https://doc.rust-lang.org/cargo/reference/manifest.html, retrieved 2026-09-06), and the workspace "lints table" section's complete inheritance example is `[workspace.lints.rust]` / `unsafe_code = "forbid"` in the root plus `[lints]` / `workspace = true` in the member (https://doc.rust-lang.org/cargo/reference/workspaces.html, retrieved 2026-09-06). A template that adopts exactly that shape is adopting the Cargo team's own illustration, which is the cheapest possible thing for a reader to recognize.

### Principles and implementation

**The shared requirement.** *Code this template ships must not be able to introduce undefined behavior silently, and any future decision to take on that risk must be explicit, reviewable, and documented at the point of risk.* Two clauses, and they are separable: the first is about the default state, the second about how the default is escaped.

**Source and agreement level.** Source: ledger row **F023** in `docs/port/COMMONALITY.md`, origin `none`, verdict `RUST-ONLY` — "repo-wide safety-boundary decision, no precedent in either source". There is no inherited baseline: Python's memory safety is enforced by the CPython runtime and TypeScript's by the JavaScript engine, so neither source repo could have recorded a decision here. The agreement level, in the spec §2 vocabulary, is **policy/mechanism** — the outcome is a repo-wide rule plus the artifact that enforces it, not an architectural pattern that shapes module boundaries and not a capability the template must offer. Nothing about this decision constrains R02's crate topology, and nothing about R02's topology constrains this decision, because the recommended mechanism is inherited by whatever set of members the workspace turns out to have.

**Essential behaviors.** The chosen mechanism must:
- B1. Reject `unsafe` blocks in every workspace member by default, at compile time, with no additional tool needed to see the failure.
- B2. Also reject the *other* constructs that create the same class of risk — `no_mangle`, `export_name`, `link_section` — and, in edition 2024 where those became unsafe attributes, their `#[unsafe(...)]` spellings.
- B3. Be declared in exactly one place for the whole workspace, so a new crate added by R02's topology inherits it without a second edit and cannot be added without one.
- B4. Make the escape from the default a deliberate, diff-visible act rather than a scattered per-site suppression.
- B5. State honestly what it does *not* cover — the dependency tree — so the policy is not read as an absolute claim about the shipped binary.

**Observable acceptance criteria.** All five are directly checkable and all were executed; the transcripts are in `### Validation strategy`.
- A1. A workspace member containing `unsafe { … }` fails `cargo check` with `error: usage of an 'unsafe' block`.
- A2. A `#[allow(unsafe_code)]` written next to that block does *not* rescue it; the compiler reports `E0453 … incompatible with previous forbid`.
- A3. A member declaring only `[lints] workspace = true` inherits the policy — no per-crate attribute is required.
- A4. `#[unsafe(no_mangle)]` on an `extern "C"` function is rejected by the same lint.
- A5. A registry dependency that itself uses `unsafe` heavily still builds under the policy, proving B5's scoping claim empirically rather than by assertion.

**What must agree, and what may vary.** *Must agree:* the level (one level, workspace-wide), the single declaration site, and the written statement of the dependency-tree caveat. *May vary:* whether an individual fork later downgrades the level; the exact clippy configuration keys; and — explicitly — which CI job runs the check, which is R28's and R11's decision, not this item's.

**The three architectural alternatives, compared before any tool is chosen.** This is the comparison the prompt asks for, and it is an architectural one because the three differ in *where the policy lives*, not merely in which lint fires.

| | **Alt-1: crate-root attribute** | **Alt-2: per-package `[lints]` table** | **Alt-3: `[workspace.lints]` + member inheritance** |
|---|---|---|---|
| Declaration site | `#![forbid(unsafe_code)]` at the top of every `lib.rs` and `main.rs` | `[lints.rust]` in every member's `Cargo.toml` | `[workspace.lints.rust]` once in the root manifest; each member writes `[lints] workspace = true` |
| Sites to edit for N crates | N source files (2N if a crate has both a lib and a bin root — bat does exactly this, `src/lib.rs:22` and `src/bin/bat/main.rs:1`) | N manifests | 1 manifest + one 2-line stanza per member |
| Failure mode when R02 adds a crate | New crate silently unprotected until someone remembers the attribute | Same | New crate is unprotected only if its author omits `[lints] workspace = true` — a visible omission in a new manifest, and the one place a reviewer already looks |
| MSRV floor | none (attributes are as old as the language) | Cargo 1.74 | Cargo 1.74 |
| Recognized by `cargo-geiger` | Yes | **No** — open bug, see below | **No** — same bug |
| Practiced by | clap, rustls, ureq, bat, tower-http | reqwest, hyper, bytes, just (for other lints) | **axum**, uv, ruff, clap, actix-web, tokio, rustls |
| First-party illustration | The rustc book's `unsafe_code` example | The Cargo book's `[lints]` example | The Cargo book's workspace "lints table" example |

Alt-3 wins on B3, which is the criterion that survives contact with R02: this template's topology is not yet decided, so the mechanism that costs nothing when the crate count changes is the correct one. Alt-1 is the only alternative with a real countervailing argument (`cargo-geiger` recognition), and that argument is examined and rejected under `### Tradeoffs`.

**The dependency-scoping question, answered from the specification and then verified.** The Cargo reference states it directly: "Generally, these will only affect local development of the current package. Cargo only applies these to the current package and not to dependencies. As for dependents, Cargo suppresses lints from non-path dependencies with features like `--cap-lints`" (https://doc.rust-lang.org/cargo/reference/manifest.html, retrieved 2026-09-06). The rustc book completes the picture from the other side: `--cap-lints` "sets the 'lint cap level' … This feature is used heavily by Cargo; it will pass `--cap-lints allow` when compiling your dependencies" (https://doc.rust-lang.org/rustc/lints/levels.html, retrieved 2026-09-06). So the relationship is symmetric and total: **this template's `forbid` never reaches a dependency, and a dependency's own lint levels never reach this template.** Executed check E below confirms it: a member that forbids `unsafe_code` compiles cleanly against `memchr` 2.8.3, whose vendored source contains 349 occurrences of the token `unsafe`. The policy statement must therefore say, in prose, that it governs first-party code only — this is essential behavior B5, not a footnote.

**Should a tool close that gap here? No, and there are two independent reasons.** First, scope: auditing the dependency tree's `unsafe` footprint is explicitly assigned to **R13 (`dependency-vulnerability-scanning`)** by this prompt's `## Out of scope`. Second, and independently, the obvious candidate is actively unfit for the recommended mechanism. `cargo-geiger` carries **open issue #539, "cargo-geiger does not detect use of `unsafe_code = \"forbid\"` in `Cargo.toml`"** (opened 2025-04-11, still `open` at retrieval; https://github.com/geiger-rs/cargo-geiger/issues/539, retrieved 2026-09-06). The reporter's `Cargo.toml` sets `[lints.rust] unsafe_code = "forbid"` and `cargo geiger` nonetheless prints `No unsafe usage found, missing #![forbid(unsafe_code)]`. A maintainer replied "Needs to be added — want to work on it?" (`pinkforest`, 2025-04-14) and a contributor began work, but the issue remains open at retrieval. Adopting `cargo-geiger` alongside Alt-3 would therefore produce a tool that *misreports this very template* as having no policy. It is excluded on scope first and fitness second.

**What edition 2024 already contributes for free.** The owner-fixed `rust-edition` = `2024` changes the baseline before any policy is written: `unsafe_op_in_unsafe_fn` "now warns by default" (https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-op-in-unsafe-fn.html, retrieved 2026-09-06), so an `unsafe fn` whose body performs unsafe operations without an inner `unsafe {}` block already produces a diagnostic. Executed check G confirms this on the local stable toolchain with no lint configuration whatsoever. The practical consequence: a fork that later downgrades to `deny` inherits a compiler that already forces every unsafe operation into an explicit, individually-attributable block — which is precisely the precondition that makes a per-block `// SAFETY:` convention enforceable at all. The standard library says as much: "in the Rust standard library, `unsafe_op_in_unsafe_fn` is active and so each unsafe operation in an unsafe function must be enclosed in an `unsafe` block. This makes it easier to review such functions and to document their unsafe parts" (https://std-dev-guide.rust-lang.org/policy/safety-comments.html, retrieved 2026-09-06).

**The escape hatch is a design decision, not an afterthought — and `#[expect]` changes the answer.** Rust 1.81.0 stabilized the `expect` lint level, "which allows explicitly noting that a particular lint should occur, and warning if it doesn't", and the release announcement's own worked example is the safety-comment migration: "if you're moving a code base to comply with a new restriction enforced via a Clippy lint like `undocumented_unsafe_blocks`, you can use `#[expect(clippy::undocumented_unsafe_blocks)]` as you transition"; it also names `clippy::allow_attributes` and `clippy::allow_attributes_without_reason` as the lints that push `#[allow]` toward `#[expect]` and force a written reason (https://blog.rust-lang.org/2024/09/05/Rust-1.81.0/, retrieved 2026-09-06). Executed checks I1/I2 demonstrate the behavioral difference that matters: `#[expect(unsafe_code, reason = "…")]` compiles when the `unsafe` is genuinely present, and produces `warning: this lint expectation is unfulfilled` — echoing the written reason back — once the `unsafe` is removed. An `#[allow]` in the same position rots silently forever. **This means the historical framing of the HIGH question — "`deny` permits a per-block override, `forbid` does not" — understates `deny`'s modern value: under `deny` the override can be self-expiring and reason-carrying, not merely permissive.** It also means the cost of choosing `forbid` is precisely measurable: executed check J shows `#[expect(unsafe_code, reason = "…")]` is rejected under `forbid` with the same `E0453` as `#[allow]`. `forbid` forecloses the *good* hatch as well as the bad one.

**Why the recommendation still lands on `forbid`, given that.** The two clauses of the shared requirement are not equally weighted for a *template*. A template's first job is to hand a fork a correct default; its second is to make changing that default cheap and obvious. Under Alt-3, downgrading `forbid` to `deny` is a **one-token edit in one line of the root manifest**, made once, visible in every diff and every code review, and it immediately activates the `#[expect(…, reason = …)]` hatch and the clippy safety-comment lints that this report recommends shipping pre-configured. So the fork that needs `unsafe` pays one line, once — while every fork that does not need `unsafe` (which, on the practice evidence, is the great majority for a CLI + library + web-service shape) gets the strictly stronger guarantee with no action at all. Choosing `deny` inverts that: it weakens the default for everyone to pre-pay a cost that most forks never incur.

**Reference implementation, and how it composes.** The complete recommended artifact is small enough to state in full. Root `Cargo.toml`:

```toml
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.package]
edition = "2024"
rust-version = "1.85"          # the concrete floor is set by msrv-policy, not by this item

[workspace.lints.rust]
unsafe_code = "forbid"

# Dormant while `unsafe_code = "forbid"` holds: with no `unsafe` block in the
# workspace these three cannot fire. They are shipped armed so that a fork's
# downgrade to `deny` is a one-token edit rather than a design exercise.
[workspace.lints.clippy]
undocumented_unsafe_blocks    = "deny"
multiple_unsafe_ops_per_block = "deny"
unnecessary_safety_comment    = "deny"
```

Every member `Cargo.toml`:

```toml
[lints]
workspace = true
```

The composition claim — that the three clippy lints are free while `forbid` is in force — is not asserted; it is executed check K, which runs `cargo clippy --all-targets -- -D warnings` over exactly this configuration (plus a real registry dependency) and exits 0. The maintainers' definitions of the three: `undocumented_unsafe_blocks` "Checks for `unsafe` blocks and impls without a `// SAFETY: ` comment explaining why the unsafe operations performed inside the block are safe", group `restriction`, `#[clippy::version = "1.58.0"]`; `unnecessary_safety_comment` "Checks for `// SAFETY: ` comments on safe code", `#[clippy::version = "1.67.0"]`; `multiple_unsafe_ops_per_block` "Checks for `unsafe` blocks that contain more than one unsafe operation … Combined with `undocumented_unsafe_blocks`, this lint ensures that each unsafe operation must be independently justified" (source files under https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/, retrieved 2026-09-06). Note `restriction` is an opt-in group by design — these lints are never on by default and must be named explicitly, which is what the table above does. Their two configuration keys, `accept-comment-above-statement` and `accept-comment-above-attributes`, both default to `true` (https://doc.rust-lang.org/clippy/lint_configuration.html, retrieved 2026-09-06), so no `clippy.toml` is needed; the defaults are the permissive, ergonomic ones.

**Performance.** Stated with workload and instrumentation, per the prompt: the recommended mechanism adds **zero** runtime cost (it emits no code), zero binary-size cost, and no measurable compile-time cost — `unsafe_code` is a lint the compiler already evaluates at its default `allow` level, so raising the level changes only diagnostic emission, not analysis performed. The clippy lints run only under `cargo clippy`, never under `cargo build`. Workload measured: the acceptance workspace of executed checks A–K (one member, one registry dependency), on rustc 1.98.0 / aarch64-apple-darwin; `cargo clippy --all-targets` reported `Finished dev profile … in 0.43s` on a cold member check and `0.04s` warm. This is a single-crate figure and is reported as such — it is not extrapolated to a larger workspace, and no cross-tool benchmark comparison is drawn, because the alternatives differ in declaration site rather than in work performed.

**`BASELINE-REVIEW:` findings — none.** F023's origin is `none` and its verdict is `RUST-ONLY`; there is no inherited mechanism from either source repo to challenge, and `docs/port/BASELINE-REVIEW.md` (which adjudicates the `COMMON → REUSE` and `ADOPT` rows) contains no F023 row. The owner-fixed parameters bearing on this item — `rust-edition` = 2024, `msrv-policy`, `license`, `target-os-matrix` — all *support* the recommendation rather than constrain it, so none is challenged. No `BASELINE-REVIEW:` line is emitted.

### Dominant choice

**`unsafe_code = "forbid"` declared once in `[workspace.lints.rust]` and inherited by every member via `[lints] workspace = true`.**

"Dominant" is claimed on three independent grounds, in descending order of weight.

1. **First-party illustration.** Both Cargo reference sections that teach lint configuration use this exact lint at this exact level as their worked example — `[lints.rust] unsafe_code = "forbid"` in the manifest reference, and the full `[workspace.lints.rust] unsafe_code = "forbid"` + `[lints] workspace = true` pair in the workspaces reference (retrieved 2026-09-06). No other level appears in either example.
2. **Practice at the top of each shape.** The leading Rust web framework, `tokio-rs/axum` (27,029 stars; `axum` 112,742,897 downloads/90d), implements precisely this pattern, root manifest line 9 plus member line 247. The most-downloaded CLI-argument library, `clap` (1,107,038,264 all-time downloads), forbids the same lint via the crate-root attribute, as do `rustls` (888,756,315 all-time) and `ureq`.
3. **Level distribution among projects that took a position.** Of the 8 surveyed projects that set any `unsafe_code` level, 4 chose `forbid`, 2 `deny`, 2 `warn`. `forbid` is the plurality, chosen by twice as many projects as either other level, and it spans all three of the template's shapes (library: clap, rustls, ureq; web: axum) while `deny` spans two (CLI: bat; web: tower-http) and `warn` one (CLI: uv, ruff).

The honest qualifier: 10 of 18 surveyed projects set no level at all, so "dominant" describes the choice *among projects that made one*, not universal adoption. The *delivery mechanism* is separately dominant: a `[lints]` or `[workspace.lints]` table (for any lint, not only this one) appears in **11 of the 18** — axum, clap, rustls, uv, ruff, just, tokio, starship, actix-web, reqwest and hyper. The crate-root attribute and the manifest table coexist rather than one having replaced the other: clap and rustls use both, and ureq, bat and tower-http use the attribute alone while being actively maintained (pushed 2026-08-23, 2026-09-04 and 2026-09-05 respectively). No claim is made here about when any project adopted its mechanism; adoption dates were not researched.

### Options

Per the template, this field carries name · where documented · adopters that practice it · date of the most recent authoritative write-up. No download columns.

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **`unsafe_code = "forbid"` via `[workspace.lints.rust]` + `[lints] workspace = true`** | Cargo Book, Workspaces → "The lints table" (this is the section's own example); Cargo Book, Manifest → "The `[lints]` section" | `tokio-rs/axum` (`Cargo.toml:8-9`, `axum/Cargo.toml:246-247`) | Cargo Book workspaces reference, states "MSRV: Respected as of 1.74"; retrieved 2026-09-06 |
| **`#![forbid(unsafe_code)]` crate-root attribute** | rustc book, Lint levels ("the 'forbid' level can not be overridden to be anything lower than an error"); rustc book, allowed-by-default listing | `clap-rs/clap` (`clap_builder/src/lib.rs:9`), `rustls/rustls` (`rustls/src/lib.rs:305`, combined with `unused_must_use`), `algesten/ureq` (`src/lib.rs:524`) | rustc book lint-levels page; retrieved 2026-09-06 |
| **`unsafe_code = "deny"` (table or attribute), with `#[expect(unsafe_code, reason = "…")]` as the per-site hatch** | rustc book, Lint levels; Rust 1.81.0 release announcement for `expect` and for `clippy::allow_attributes_without_reason` | `sharkdp/bat` (`src/lib.rs:22`, `src/bin/bat/main.rs:1`; whole-repo code search finds 0 `allow(unsafe_code)`), `tower-rs/tower-http` (`tower-http/src/lib.rs:200`; exactly 1 `allow(unsafe_code)`, at `tower-http/src/services/fs/serve_dir/tests.rs:1233`, `#[cfg(windows)]` test scaffolding) | Rust 1.81.0 release announcement, 2024-09-05; retrieved 2026-09-06 |
| **`unsafe_code = "warn"` via `[workspace.lints.rust]`** | Cargo Book, Workspaces → "The lints table" | `astral-sh/uv` (`Cargo.toml:346-347`), `astral-sh/ruff` (`Cargo.toml:231-232`) | Cargo Book workspaces reference; retrieved 2026-09-06 |
| **`// SAFETY:` comment convention, mechanized by `clippy::undocumented_unsafe_blocks`** (+ `multiple_unsafe_ops_per_block`, `unnecessary_safety_comment`) | Standard library developers Guide → "Safety comments policy"; Clippy lint sources; Clippy Book → Lint configuration for the two `accept-comment-above-*` keys | Rust standard library itself (the policy page cites `str::as_bytes_mut` and `str::split_at` as its worked examples); `casey/just` (`Cargo.toml:84`, `undocumented_unsafe_blocks = "deny"`) | Rust 1.81.0 release announcement names this lint as the `#[expect]` migration example, 2024-09-05; retrieved 2026-09-06 |
| **`# Safety` rustdoc section on public unsafe functions** | Rust API Guidelines checklist, **`C-FAILURE`** — "Function docs include error, panic, and safety considerations". (The prompt's `C-SAFETY` does not exist; see `### Landscape`.) Enforced by `clippy::missing_safety_doc`, group `style`, `#[clippy::version = "1.39.0"]` (https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/doc/mod.rs, retrieved 2026-09-06). | Rust standard library (the std-dev-guide's `as_bytes_mut` example carries a `# Safety` section) | Rust API Guidelines checklist; repo `rust-lang/api-guidelines` last pushed 2025-07-08 (`GET https://api.github.com/repos/rust-lang/api-guidelines`); retrieved 2026-09-06 |
| **`cargo-geiger`** — dependency-tree `unsafe` footprint counter | Maintainers' repo `geiger-rs/cargo-geiger`; `rust-secure-code/safety-dance` recommends it as an audit aid | Cited by the `rust-secure-code` working group's safety-dance process | safety-dance README, but that repo was last pushed **2022-03-25** (`GET https://api.github.com/repos/rust-secure-code/safety-dance`); retrieved 2026-09-06 |
| **Set nothing** — rely on edition 2024's `unsafe_op_in_unsafe_fn` warning alone | Rust Edition Guide → `unsafe_op_in_unsafe_fn` warning | `BurntSushi/ripgrep`, `sharkdp/fd`, `serde-rs/serde`, `seanmonstar/reqwest`, `hyperium/hyper`, `actix/actix-web`, `starship/starship` | Rust Edition Guide, edition 2024; retrieved 2026-09-06 |

### Excluded by gate

The six fitness gates are written for crate candidates. This item's kind is `pattern`, and seven of its eight options are toolchain- or convention-based, so most gates are `inapplicable` for most options — stated explicitly per the tier guidance rather than omitted. Only `cargo-geiger` and `cargo-vet` are crates and therefore carry the full figure set; both are excluded, and neither exclusion rests on popularity.

**Gate results for the toolchain-native options** (`forbid`/`deny`/`warn` at any declaration site; the clippy safety lints; `#[expect]`; the `// SAFETY:` convention):

| Gate | Result | Reason |
|---|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | **inapplicable** | These are rustc, Cargo and clippy features shipped with the Rust toolchain, which is itself `MIT OR Apache-2.0`; no third-party crate is added to the dependency graph, so there is no license to reconcile. |
| 2. Crate and dependency-tree MSRV within `stable minus 2 minor versions…` | **passes, with a stated floor** | `[workspace.lints]` inheritance is "Respected as of 1.74" (Cargo Book, Workspaces, retrieved 2026-09-06); `#[expect]` needs 1.81 (Rust 1.81.0 announcement, retrieved 2026-09-06); edition 2024 needs 1.85. The highest of these, 1.85, sits far below the policy floor: current stable is **1.98.0** (`rustc 1.98.0 (88d9e12ae 2026-08-18)`, `rustc -vV` on the acceptance host, 2026-09-06), so stable-minus-2 is ≈1.96. No dependency tree is introduced, so the transitive half of the gate is vacuous. |
| 3. No open RustSec advisory; `unsafe` posture stated | **inapplicable / satisfied by construction** | No crate, so no RustSec package page exists to query. The `unsafe` posture *is* the subject: the recommendation forbids `unsafe` in first-party code and states plainly that it does not reach dependencies. |
| 4. Builds and is tested on `ubuntu-latest, macos-latest` | **passes** | Lint levels are a property of rustc/Cargo/clippy and are OS-independent; nothing platform-specific is introduced. Executed checks A–K ran on `aarch64-apple-darwin` (the macOS half of the matrix) with rustc 1.98.0; the Linux half is asserted from OS-independence, not executed here, and is listed as a planned check in `### Validation strategy`. Windows: equally supported, and not required. |
| 5. Default features and async-runtime coupling stated | **inapplicable** | No crate, therefore no Cargo features and no runtime coupling. The recommendation is orthogonal to R05's sync/async decision and to R69's web stack. |
| 6. Binary-size and compile-time cost stated qualitatively | **passes: zero and negligible** | The mechanism emits no code, so binary size is unchanged. Compile-time effect is limited to diagnostic emission for a lint the compiler already evaluates; the clippy lints run only under `cargo clippy`. Measured figures in `### Principles and implementation`. |

**Excluded candidates.**

**`cargo-geiger` — excluded on scope, and independently on fitness.** Full figure set, all retrieved 2026-09-06: 90-day downloads `crate.recent_downloads` = **50,882**; all-time `crate.downloads` = **233,043** (`GET https://crates.io/api/v1/crates/cargo-geiger`). Last release, newest version with `yanked: false` from `GET https://crates.io/api/v1/crates/cargo-geiger/versions`: **0.13.0, created 2025-08-31**, `license: "Apache-2.0 OR MIT"`, `rust_version: "1.85"`. Repository: `crate.repository` names `rust-secure-code/cargo-geiger`, which redirects — `GET https://api.github.com/repos/rust-secure-code/cargo-geiger` returns `full_name: geiger-rs/cargo-geiger`; **stars 1,645**, `archived: false`, `pushed_at 2026-09-02T02:03:28Z`. Open issues, from `GET https://api.github.com/search/issues?q=repo:geiger-rs/cargo-geiger+is:issue+is:open` (`total_count`, not `open_issues_count`): **45**. Issue responsiveness over the 10 most recently opened issues (`search/issues?q=repo:geiger-rs/cargo-geiger+is:issue&sort=created&order=desc&per_page=10`, then each issue's comments): 7 answered, **median 2.57 days** to first non-author reply (6 of the 7 by maintainer `pinkforest`), **3 unanswered** — #565 and #564 (both opened 2026-05-09) and #538. Advisories: `https://rustsec.org/packages/cargo-geiger.html` returns **HTTP 404**, i.e. no advisory page; this reading was controlled by fetching two known cases on the same date — `https://rustsec.org/packages/time.html` returns 200 (a crate with advisories) and `https://rustsec.org/packages/serde.html` returns 404 — confirming that 404 means "no advisories", not "endpoint broken". Maintenance rubric: **stable-quiet**. The 12-month gap since 0.13.0 is a trigger to investigate, never the verdict; investigating shows a repo pushed 4 days before retrieval, a maintainer answering issues in a median of 2.57 days, a build-break issue (#551, "Build broken on 1.89") closed, no advisory, and no maintainer notice of abandonment — so neither `at-risk` (no concrete adverse signal) nor `dormant` (no unpatched advisory, no broken build on current stable, no maintainer notice). **Excluded because** (a) dependency-tree `unsafe` auditing is assigned to R13 by this prompt's `## Out of scope`, and (b) open issue #539 (opened 2025-04-11, still open at retrieval) means it does not recognize the `[lints]`-table form of the policy and would report this very template as `No unsafe usage found, missing #![forbid(unsafe_code)]`. Gate 3 (`unsafe` posture) and gates 1, 2, 4 would all pass; the exclusion is on scope and correctness, decided before popularity was consulted, exactly as the tier guidance requires.

**`cargo-vet` — excluded on scope.** Figures for completeness, retrieved 2026-09-06: `recent_downloads` **97,641**, `downloads` **617,005** (`GET https://crates.io/api/v1/crates/cargo-vet`); newest non-yanked version **0.10.2, created 2026-01-13**, `license: "Apache-2.0/MIT"`, `rust_version: "1.82"` (`/versions`); `GET https://api.github.com/repos/mozilla/cargo-vet` → stars **987**, `archived: false`, `pushed_at 2026-04-19T20:31:17Z`; open issues **82** (`search/issues … total_count`); `https://rustsec.org/packages/cargo-vet.html` → **HTTP 404** (no advisories, same controlled reading). Maintenance rubric: **stable-quiet** — nearly 5 months since the last push at retrieval is a trigger to investigate, and the investigation surfaces no unpatched advisory, no maintainer notice, and a shipped release inside the last 8 months. Excluded because it audits *dependencies*, which is R13's scope, and because it decides nothing about first-party `unsafe`.

**`cargo-crev` — not shortlisted**, for the same scope reason as `cargo-vet`; no figures were collected, and none are asserted.

**No option was excluded by a license, MSRV, advisory, platform, feature or cost gate.** Recording that explicitly so the empty-looking result is not read as an unrun check.

### Up-and-comers

Two, and neither is recommended for adoption by this item.

**`#[expect(lint, reason = "…")]` as the standard escape-hatch idiom** (rustc, stabilized 1.81.0, 2024-09-05). This is the genuinely new thing in this space since the older forbid-vs-deny debate was settled in ecosystem practice, and it is *why* the runner-up in `### Ranked runner-up` is stronger today than it would have been three years ago. **It is already practiced, and by exactly the projects the prompt's HIGH question is about.** Checked by whole-repository code search (`GET https://api.github.com/search/code?q=repo:<o>/<r>+%22expect(unsafe_code)%22`, retrieved 2026-09-06): `astral-sh/ruff` has **10** occurrences of `expect(unsafe_code)` and `astral-sh/uv` has **3**; `sharkdp/bat` and `tower-rs/tower-http` have **0**. Reading one ruff site shows the intended shape in full — `crates/ruff_index/src/vec.rs:182-183` carries `#[expect(unsafe_code)]` immediately above `unsafe impl<I: Idx, T> Send for IndexVec<I, T> where T: Send {}`, and the neighbouring site at `:185-188` pairs it with a `// SAFETY: IndexVec owns its elements; I is only a marker.` comment (https://raw.githubusercontent.com/astral-sh/ruff/HEAD/crates/ruff_index/src/vec.rs, retrieved 2026-09-06). **This is the permitted-with-justification regime the prompt's MEDIUM question describes, working in production, in a 49,509-star codebase.** Two qualifications matter. First, ruff and uv reach it from `warn`, not `deny` — so the compiler does not force the annotation, it only makes the omission visible. Second, ruff's occurrences omit the `reason = "…"` clause, so they self-expire but carry no written justification in the attribute itself; the justification lives in the adjacent `// SAFETY:` comment instead. Its practical effect for *this* template is conditional either way: executed check J shows `#[expect(unsafe_code, …)]` is rejected under `forbid`, so it becomes available only to a fork that has already downgraded. It is named here so the downgrade path in `### Migration implications` prescribes `#[expect(…, reason = …)]` — with the reason clause ruff omits — rather than the older `#[allow]`.

**`cargo-vet`** (Mozilla; figures under `### Excluded by gate`; 97,641 downloads/90d, last release 0.10.2 on 2026-01-13, repo last pushed 2026-04-19). It is the credible modern answer to "what has anyone actually reviewed in my dependency tree", and it can encode an `unsafe`-review criterion. Listed as an up-and-comer for **R13**, not adopted here, because dependency-tree audit is out of this item's scope. No claim is made about whether R13 should adopt it.

**Not an up-and-comer: `rust-secure-code/safety-dance`.** It appears in searches as the community effort behind this whole topic, and its README is where `cargo-geiger` is recommended as an audit aid, but `GET https://api.github.com/repos/rust-secure-code/safety-dance` (retrieved 2026-09-06) reports `pushed_at: 2022-03-25T17:24:27Z` — over four years stale, with 577 stars. Cited above as historical context for `cargo-geiger`'s provenance; it is not a live source of guidance and nothing in this report rests on it.

### Fit for this template

The template ships three target shapes. The policy is argued separately for each, and the conclusion is the same for all three — which is itself the finding that justifies a single workspace-wide table rather than per-crate variation (the prompt's LOW question).

**Library crate.** This is the shape where the policy carries the most weight, because a library's `unsafe` becomes its consumers' risk, transitively and invisibly. It is also the shape with the clearest practice evidence: the three most-downloaded surveyed libraries that took a position all chose `forbid` — `clap` (`#![forbid(unsafe_code)]`, `clap_builder/src/lib.rs:9`, 1,107,038,264 all-time downloads), `rustls` (`#![forbid(unsafe_code, unused_must_use)]`, `rustls/src/lib.rs:305`, 888,756,315), `ureq` (`#![forbid(unsafe_code)]`, `src/lib.rs:524`, 194,489,474). A library that forbids `unsafe` can say so in its README as a checkable fact, and a downstream consumer can verify it by reading one line of the manifest. Nothing about a library shape argues for a weaker level. **Fit: `forbid`.**

**CLI crate.** The CLI's plausible dependencies are an argument parser and a terminal/IO layer; `clap`, the dominant parser, forbids `unsafe` in its own core, so nothing in the expected stack pushes `unsafe` up into the binary. The surveyed CLIs split — bat chose `deny`, uv and ruff chose `warn`, ripgrep and fd chose nothing — but the split is explained by what each project's own code does, not by the CLI shape: uv and ruff are large performance-sensitive workspaces whose code genuinely does reach for `unsafe`, and their `warn` level is paired with a real per-site regime — 10 `expect(unsafe_code)` sites in ruff and 3 in uv, several with adjacent `// SAFETY:` comments (code search and `crates/ruff_index/src/vec.rs:182-188`, retrieved 2026-09-06; detail in `### Up-and-comers`). Their level follows from their code, not from their being CLIs. This template's CLI writes no `unsafe` and is not expected to; it parses arguments, calls into the library crate, and writes output. The one CLI-specific consideration is FFI: a CLI that later needs to expose a C symbol would hit the policy, because `unsafe_code` at `forbid` also rejects `#[unsafe(no_mangle)]` (executed check F). That is the correct outcome — such a change *should* require a deliberate policy edit. **Fit: `forbid`.**

**Web-service crate.** The strongest single data point in the whole survey lives here: `axum`, the leading Rust web framework (27,029 stars; 112,742,897 downloads/90d), implements exactly the recommended mechanism — `[workspace.lints.rust] unsafe_code = "forbid"` at `Cargo.toml:9`, inherited at `axum/Cargo.toml:247`. `tower-http`, the middleware layer a web service in this template would very likely use, sets `#![deny(unsafe_code)]` at `tower-http/src/lib.rs:200`. Neither the framework nor the middleware layer requires its *users* to write `unsafe`. The runtime beneath them (`tokio`) does use `unsafe` internally and sets no `unsafe_code` level — which is irrelevant to this template precisely because of the `--cap-lints` scoping proven by executed check E. Note also that this shape is gated behind an optional feature per F017 (`docs/port/BASELINE-REVIEW.md`, retained), so the policy must be inherited by a crate that may not always be compiled; workspace-level inheritance handles that with no special case, because `[lints] workspace = true` is a property of the member manifest, not of the feature that enables it. **Fit: `forbid`.**

**Cross-shape conclusion, answering the LOW question directly.** All three shapes want the same level, for the same reason, and no shape presents a case for divergence. Therefore the policy should be declared **uniformly, once, in a single `[workspace.lints.rust]` table in the root `Cargo.toml`**, and not varied between the `core` library crate and the CLI or web front-end crates. This holds regardless of how R02 resolves the workspace topology: whether R02 produces two crates or six, each inherits the same table with the same two lines, and a crate that R02 adds later is protected the moment its manifest is written. This item takes no position on that topology and needs none.

### Recommendation

**Adopt `unsafe_code = "forbid"` in a single `[workspace.lints.rust]` table in the root `Cargo.toml`, inherited by every workspace member via `[lints] workspace = true`. Ship the three clippy safety-comment lints (`undocumented_unsafe_blocks`, `multiple_unsafe_ops_per_block`, `unnecessary_safety_comment`) pre-configured at `deny` in `[workspace.lints.clippy]`, dormant under `forbid`. Document, in prose next to the table, that the policy governs first-party code only and does not constrain the dependency tree.**

In full — this is the entire deliverable:

```toml
# Root Cargo.toml
[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
undocumented_unsafe_blocks    = "deny"
multiple_unsafe_ops_per_block = "deny"
unnecessary_safety_comment    = "deny"
```
```toml
# Every member Cargo.toml
[lints]
workspace = true
```

Five reasons, in order of weight:

1. **It is the Cargo team's own worked example.** The workspaces reference's "lints table" section teaches inheritance using literally `[workspace.lints.rust]` / `unsafe_code = "forbid"` plus `[lints]` / `workspace = true`; the manifest reference's `[lints]` section opens with the same lint at the same level (retrieved 2026-09-06). For a *template*, whose job includes being recognizable, matching the reference documentation is worth more than a marginally cleverer arrangement.
2. **It is what the leading project in the template's own hardest shape does.** `axum` implements it line-for-line (`Cargo.toml:8-9` + `axum/Cargo.toml:246-247`).
3. **It survives R02.** The declaration site does not multiply with the crate count, so this item's answer cannot be invalidated by whatever topology R02 chooses — satisfying essential behavior B3 without coupling the two items.
4. **The default is right for the overwhelming majority of forks, and the escape is one token.** A fork needing `unsafe` edits `"forbid"` → `"deny"` in one line, once, visibly — and lands on a configuration where the safety-comment lints are *already armed* and `#[expect(unsafe_code, reason = "…")]` is *already available*. Nobody has to design the permitted-with-justification regime later; it is shipped, dormant, and one token away.
5. **It is verified, not assumed.** Executed checks A, B, C, D2, E, F, J and K exercise every claim made above against rustc 1.98.0 — including the two claims most often asserted without evidence: that `forbid` truly cannot be overridden per-site (B, J), and that it truly does not reach dependencies (E).

The policy's written statement, for the template's own documentation, should be exactly this and no stronger: *"Code in this repository must not use `unsafe`. This is enforced by the compiler through `unsafe_code = "forbid"` in the workspace lint table; a per-site `#[allow]` or `#[expect]` cannot override it. The rule governs this repository's own crates only — Cargo compiles dependencies with `--cap-lints allow`, so it makes no claim about `unsafe` inside the dependency tree. A fork that genuinely needs `unsafe` changes `forbid` to `deny` in the root `Cargo.toml`; the `// SAFETY:` comment lints that then apply are already configured."*

### Ranked runner-up

**`unsafe_code = "deny"` in the same `[workspace.lints.rust]` table, with `#[expect(unsafe_code, reason = "…")]` plus a mandatory `// SAFETY:` comment as the per-site permitted-with-justification regime** — the same three clippy lints, the same single declaration site, the same inheritance. The runner-up differs from the recommendation by exactly one token.

**The condition under which it wins.** It wins if any of these becomes true:

- **The owner decides the template's primary audience is forks that will write `unsafe`** — for example if the template is positioned toward systems-level, FFI-wrapping, or performance-critical consumers. `forbid`'s cost is concentrated entirely on that population, and if it is the majority the default is backwards.
- **The template itself acquires a need for `unsafe` before it ships** — the most likely concrete trigger being FFI, since `unsafe_code` at `forbid` rejects `#[unsafe(no_mangle)]` and `#[unsafe(export_name)]` as well as `unsafe` blocks (executed check F). If R68 (`release-binary-artifacts`) or a future C-ABI surface requires an exported symbol, this item must be revisited.
- **A dependency's macro is found to expand to `unsafe` in the consuming crate.** `forbid` applies to the expansion, and unlike `deny` it cannot be locally suppressed while a fix is sought upstream. No such dependency is in the expected stack — `clap`, `axum` and `tower-http` all forbid or deny `unsafe` in their own code — but this is the failure mode that would force the change on a schedule not of the template's choosing.

If any of these holds, the change is one token in one line and nothing else in this report changes: the declaration site, the inheritance mechanism, the clippy lints, the documentation caveat, and every acceptance check but A2/J remain exactly as specified. That is a deliberate property of the design, not a coincidence — the recommendation and its runner-up were chosen to be one edit apart.

### Tradeoffs

**Versus the runner-up (`deny` + `#[expect(…, reason = …)]`) — what `forbid` gives up.**

*The cost.* `forbid` forecloses the per-site escape hatch entirely, and executed check J shows it forecloses the *good* one along with the bad: `#[expect(unsafe_code, reason = "FFI boundary")]` is rejected with `E0453 … overruled by previous forbid`, exactly as `#[allow]` is. So the template loses access to the one idiom that would let a single justified `unsafe` block coexist with a strict repo-wide policy while carrying a written reason and self-expiring when the block is removed (executed checks I1/I2). For a fork that needs precisely one `unsafe` block, `forbid` forces a repo-wide posture change to accommodate a local exception. That is a real and slightly awkward cost, and it is the strongest argument the runner-up has.

*Why it is accepted.* The awkwardness is bounded at one token in one line, made once, and the resulting configuration is one this report already specifies in full — so the fork does not design anything, it flips a switch. Weighed against that bounded cost: `deny` as a default means every fork that never touches `unsafe` (the great majority, on the practice evidence: 4 of the 8 position-taking projects, including all three high-download libraries and the leading web framework, chose the stricter level) carries a weaker guarantee permanently, and — the sharper point — a `deny` policy can be silently defeated by an `#[allow(unsafe_code)]` that a reviewer overlooks in a large diff, whereas a `forbid` policy can only be defeated by editing the root manifest, which is a line every reviewer reads. `forbid` moves the escape from a place that is easy to miss to a place that is impossible to miss. For a template — whose defaults are inherited by people who did not choose them and may not read them — that relocation is worth more than the per-site ergonomics it costs.

**Versus the crate-root attribute (`#![forbid(unsafe_code)]` in every `lib.rs` / `main.rs`) — what the workspace table gives up.**

*The cost.* Exactly one thing, and it is concrete rather than theoretical: `cargo-geiger` does not recognize the `[lints]`-table form and reports a project using it as `No unsafe usage found, missing #![forbid(unsafe_code)]` (open issue #539, opened 2025-04-11, still open at retrieval 2026-09-06). Any consumer or CI check that infers the policy from `cargo-geiger` output, or from a `grep` for `forbid(unsafe_code)` across `src/`, will conclude this template has no policy. A secondary cost: the attribute form has no MSRV floor at all, while the table requires Cargo 1.74.

*Why it is accepted.* The MSRV half is free — 1.74 is far below the ≈1.96 floor implied by `msrv-policy` against current stable 1.98.0, so it constrains nothing. The `cargo-geiger` half is accepted for three reasons: the tool is excluded from this item's scope anyway (R13 owns dependency-tree audit); the misreporting is a known, acknowledged bug with a maintainer inviting a fix, not designed behavior; and the alternative costs the property this template most needs, since the attribute form must be repeated in every crate root — twice for a crate with both a library and a binary target, as `sharkdp/bat` demonstrates at `src/lib.rs:22` and `src/bin/bat/main.rs:1` — and a crate that R02 adds later is unprotected until someone remembers. Trading a guarantee that scales with the workspace for compatibility with an out-of-scope tool that has an open bug is the wrong trade. If a fork later wants `cargo-geiger` recognition specifically, it can add the crate-root attribute *in addition to* the table at any time; the two are not mutually exclusive, and the table remains the thing that protects new crates automatically.

**Versus `warn` (uv, ruff) — what `forbid` gives up.** `warn` keeps the build green while surfacing `unsafe` for discussion, which suits a large, fast-moving workspace where blocking a merge on a lint is expensive and where the code genuinely does reach for `unsafe` sometimes. This template is neither large nor fast-moving nor in need of `unsafe`, and a warning that does not fail CI is not a policy — it is a preference. Rejected, with the note that if R11/R28 wire clippy with `-D warnings` (a common CI shape), `warn` becomes a de-facto `deny` in CI but not locally, producing exactly the local/CI divergence a template should avoid.

**Versus setting nothing (ripgrep, fd, serde).** Gives up the entire decision, and F023 exists precisely because the owner wants it made. Edition 2024's `unsafe_op_in_unsafe_fn` warning (executed check G) is a real but much weaker baseline: it improves the *hygiene* of `unsafe` code that is already there; it does not prevent `unsafe` from appearing. Rejected.

### Parameters

R06 owns no shared parameter and consumes none. `docs/port/PARAMETERS.md` (read 2026-09-06) lists no `researched` parameter whose owner is R06, and `research/CLAUDE.md`'s R06 row shows `owns: —`. The prompt's `## Couplings` block confirms this: `owns:` and `consumes:` are both empty.

- `owns` — none. This item produces a policy and its enforcement mechanism, both of which live in the template's own `Cargo.toml`; neither is a registry parameter that another item reads.
- `assumes rust-edition = 2024` (fixed, owner-decided 2026-09-02). The recommendation depends on it favorably: edition 2024 makes `unsafe_op_in_unsafe_fn` warn by default (executed check G) and introduces the `#[unsafe(...)]` attribute spellings that `unsafe_code` at `forbid` also rejects (executed check F). No conflict.
- `assumes msrv-policy = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI"` (fixed). The recommendation's highest requirement is Cargo 1.74 for `[workspace.lints]` inheritance (1.81 if a fork later adopts `#[expect]`; 1.85 for edition 2024 itself). Against current stable 1.98.0 the policy floor is ≈1.96, so every requirement clears it by more than ten minor versions. No conflict.
- `assumes license = "MIT OR Apache-2.0"` (fixed). No third-party crate is added, so no license reconciliation arises. No conflict.
- `assumes target-os-matrix = "ubuntu-latest, macos-latest"` (fixed). Lint levels are OS-independent. No conflict.

**No `CONFLICT:` lines are emitted.** No consumed parameter needs to change for this recommendation to hold.

**Related-item note (not a registry dependency), per the prompt's `## Couplings`.** This item names the enforcement mechanism; it does not decide which job runs it. `cargo check`/`cargo build` enforces `unsafe_code = "forbid"` with no extra CI step, because the level is read from the manifest by any Cargo invocation. The three clippy lints require a `cargo clippy` invocation, and **where that invocation lives is R28's decision** (`linter-and-editor-tooling`), with the job-versus-step shape decided by **R11** (`ci-workflow-job-structure`, which owns `ci-job-structure`). Nothing in this report presupposes either answer: the recommendation is inert with respect to CI topology, and the clippy lints are dormant under `forbid` in any case.

### Migration implications

File-level changes in the template. The template contains no Rust code yet, so these are additions to files R02 and the scaffolding task will create, not edits to existing ones.

| File | Change |
|---|---|
| `Cargo.toml` (workspace root) | Add `[workspace.lints.rust]` with `unsafe_code = "forbid"`. Add `[workspace.lints.clippy]` with `undocumented_unsafe_blocks = "deny"`, `multiple_unsafe_ops_per_block = "deny"`, `unnecessary_safety_comment = "deny"`. Add a comment above the clippy table recording that it is dormant while `forbid` holds and becomes active on a downgrade to `deny`. |
| Every member `Cargo.toml` (`crates/*/Cargo.toml`, count set by R02) | Add the two-line stanza `[lints]` / `workspace = true`. Without it the member silently inherits nothing — this is the one place the pattern can be got wrong, so it belongs in whatever new-crate checklist the template ships. |
| `CONTRIBUTING.md` (or the template's contributor documentation) | Add a short "`unsafe` code" section carrying the exact policy text quoted at the end of `### Recommendation`: the rule, the mechanism, the first-party-only caveat with its `--cap-lints` reason, and the one-token downgrade path. |
| `README.md` | Optional, one line: state that the repository forbids `unsafe` in its own code, with the same first-party-only qualifier. Do not claim a `unsafe`-free dependency tree — that claim would be false, per executed check E. |
| `clippy.toml` | **No change, and none needed.** The two `undocumented_unsafe_blocks` configuration keys — `accept-comment-above-statement` and `accept-comment-above-attributes` — both default to `true`, which is the permissive behavior wanted. Creating the file would add a knob nobody needs to read. |
| `src/**/*.rs` | **No change.** No crate-root `#![forbid(unsafe_code)]` attribute is added: the workspace table covers every member, and duplicating the policy in source would create two places to keep in sync. (Noted for the record: a fork that specifically wants `cargo-geiger` to recognize the policy may add the attribute in addition; the table is unaffected either way.) |
| CI workflow files | **No change from this item.** `unsafe_code = "forbid"` is enforced by any `cargo check`/`cargo build`/`cargo test` the workflow already runs. The clippy lints need a `cargo clippy` step, whose placement is R28's and R11's decision. This item adds no job and no step. |

**Ordering note.** The root-manifest change is independent of R02 and can land as soon as the workspace root exists. The per-member stanza must land with each member crate; if R02's topology changes later, the only work is adding the same two lines to any new member.

### Validation strategy

All checks below were **executed** on 2026-09-06 unless explicitly labelled *planned*. Toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`, `clippy 0.1.98`, host `aarch64-apple-darwin`. The realistic example is a two-file Cargo workspace — a root manifest carrying the recommended tables and one member declaring only `[lints] workspace = true` — plus, for check E, a real registry dependency. It was built in this session's scratchpad, outside the repository, and removed afterwards; no file outside `raw/opus.md` was created in the repository.

**Executed check A — the policy fires, and inheritance works (acceptance criteria A1 and A3).** Member `src/lib.rs` contains `unsafe { *x.get_unchecked(0) }`; the member manifest declares only `[lints] workspace = true`; the root declares `unsafe_code = "forbid"`. `cargo check` output, verbatim:

```
error: usage of an `unsafe` block
 --> crates/demo/src/lib.rs:2:5
  |
2 |     unsafe { *x.get_unchecked(0) }
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  |
  = note: requested on the command line with `-F unsafe-code`
```
Expected: compilation fails. **Result: as expected.** The `-F unsafe-code` note proves the level reached the member through workspace inheritance, with no attribute in the source.

**Executed check B — `forbid` cannot be overridden per-site (acceptance criterion A2).** Same file with `#[allow(unsafe_code)]` added above the function:

```
error[E0453]: allow(unsafe_code) incompatible with previous forbid
 --> crates/demo/src/lib.rs:1:9
  |
1 | #[allow(unsafe_code)]
  |         ^^^^^^^^^^^ overruled by previous forbid
```
plus the `usage of an unsafe block` error again — two errors, not one. Expected: the `#[allow]` is rejected and does not rescue the block. **Result: as expected.**

**Executed check C — the runner-up's behavior, for contrast.** Root changed to `unsafe_code = "deny"`, `#[allow(unsafe_code)]` retained, `// SAFETY:` comment present. `cargo check` → `Finished dev profile … in 0.05s`. Expected: compiles. **Result: as expected.** This is the one-token difference between the recommendation and its runner-up, demonstrated rather than described.

**Executed check D — the safety-comment convention is mechanically enforceable.** Under `deny` with the clippy table armed. D1, `// SAFETY:` comment present: `cargo clippy` → `Finished dev profile … in 0.11s`. D2, the same code with the comment removed:

```
error: unsafe block missing a safety comment
 --> crates/demo/src/lib.rs:3:5
  = help: consider adding a safety comment on the preceding line
  = note: requested on the command line with `-D clippy::undocumented-unsafe-blocks`
```
Expected: clean with the comment, error without. **Result: as expected.** This validates the MEDIUM question's answer — the convention and the lint are one mechanism, not two options.

**Executed check E — the policy is crate-local (acceptance criterion A5).** Root restored to `forbid`; the member's only code calls `memchr::memchr`; `memchr = "2"` added as a registry dependency. Cargo resolved `memchr v2.8.3`, whose vendored source contains **349** occurrences of the token `unsafe` (`grep -rho unsafe ~/.cargo/registry/src/*/memchr-2.8.3/src | wc -l`). `cargo check` → `Checking memchr v2.8.3 … Checking demo v0.1.0 … Finished dev profile … in 0.59s`. Expected: builds cleanly, because `--cap-lints allow` bounds the policy to first-party code. **Result: as expected.** This is the empirical basis for the documentation caveat; the claim is no longer taken on the reference's word alone.

**Executed check F — the policy covers unsafe attributes, not only blocks (acceptance criterion A4).** Member source replaced with `#[unsafe(no_mangle)] pub extern "C" fn demo_symbol() -> u32 { 7 }`:

```
error: usage of the unsafe `#[no_mangle]` attribute
 --> crates/demo/src/lib.rs:1:10
  = note: requested on the command line with `-F unsafe-code`
```
Expected: rejected, since the rustc listing says `unsafe_code` "catches usage of unsafe code and other potentially unsound constructs like `no_mangle`, `export_name`, and `link_section`". **Result: as expected**, including for the edition-2024 `#[unsafe(...)]` spelling. This is the check that establishes the FFI trigger named in `### Ranked runner-up`.

**Executed check G — the edition-2024 baseline, with no configuration at all.** A separate crate, `edition = "2024"`, no `[lints.rust]` table, containing `pub unsafe fn head(x: &[u8]) -> u8 { *x.get_unchecked(0) }`:

```
warning[E0133]: call to unsafe function `core::slice::<impl [T]>::get_unchecked` is unsafe and requires unsafe block
  = note: `#[warn(unsafe_op_in_unsafe_fn)]` (part of `#[warn(rust_2024_compatibility)]`) on by default
```
Expected: a warning, per the Edition Guide. **Result: as expected**, confirming the Edition Guide's claim on the actual toolchain.

**Executed check H — `multiple_unsafe_ops_per_block`.** A block performing two unsafe operations under a single `// SAFETY:` comment: `error: this unsafe block contains 2 unsafe operations, expected only one`. Expected: rejected, forcing one justification per operation. **Result: as expected.**

**Executed checks I1/I2 — `#[expect]` is a self-expiring hatch.** Under `deny`: I1, `#[expect(unsafe_code, reason = "FFI boundary: documented per-block below")]` on a function that *does* use `unsafe` → `Finished dev profile … in 0.10s`, clean. I2, the same attribute on a function that no longer uses `unsafe`:

```
warning: this lint expectation is unfulfilled
 --> crates/demo/src/lib.rs:1:10
  = note: FFI boundary: documented per-block below
  = note: `#[warn(unfulfilled_lint_expectations)]` on by default
```
Expected: clean when justified, warning — echoing the written reason — when the justification goes stale. **Result: as expected.** This is what makes the runner-up materially better than a 2022-era `deny` + `#[allow]` regime.

**Executed check J — `#[expect]` is also foreclosed by `forbid`.** Root restored to `forbid`, `#[expect(unsafe_code, reason = "FFI boundary")]` retained: `error[E0453]: expect(unsafe_code) incompatible with previous forbid`. Expected: rejected, same as `#[allow]`. **Result: as expected.** This is the precise, measured cost of the recommendation, and it is why `### Tradeoffs` does not claim the recommendation is free.

**Executed check K — the composition claim: the clippy lints are free under `forbid`.** Final configuration exactly as recommended (`forbid` + all three clippy lints + the `memchr` dependency), member code containing no `unsafe`:

```
cargo clippy --all-targets                 →  Finished `dev` profile … in 0.43s
cargo clippy --all-targets -- -D warnings  →  Finished `dev` profile … in 0.04s   (exit 0)
```
Expected: clean under both, including the `-D warnings` shape CI is likely to use. **Result: as expected.** Shipping the safety-comment lints armed costs nothing while `forbid` holds.

**Planned checks — not executed here, and named so the distinction is unambiguous.**
- *P1.* Run checks A, B, E, F and K on `ubuntu-latest` as well as `macos-latest`, satisfying `target-os-matrix` empirically rather than by the OS-independence argument in `### Excluded by gate`. Expected: byte-identical diagnostics; lint levels have no platform dependence.
- *P2.* Run check A against the MSRV floor implied by `msrv-policy` (≈1.96 at the time of writing) rather than only current stable, confirming the `[workspace.lints]` inheritance path on the oldest supported toolchain. Expected: identical, since inheritance has been respected since 1.74.
- *P3.* Once R02 fixes the workspace topology, assert that **every** member manifest contains `[lints]` / `workspace = true` — the single way this pattern can be silently defeated. A one-line check over `crates/*/Cargo.toml` suffices; where it runs is R11's and R28's decision, not this item's.
- *P4.* Confirm that `cargo-geiger` misreports this configuration, closing the loop on open issue #539 empirically rather than on the issue text alone. Low value — the tool is excluded on scope regardless — and deliberately not run.

### Confidence & re-verify trigger

**Confidence: high** on the mechanism, **high** on the level, **medium-high** on the forbid-versus-deny choice for a *template* specifically.

The mechanism (`[workspace.lints.rust]` + `[lints] workspace = true`) is as close to certain as this kind of finding gets: it is the Cargo team's own documented example, it is implemented line-for-line by axum, it appears in 12 of 18 surveyed projects, and every behavioral claim made about it was executed against the current stable toolchain rather than asserted. The level `forbid` is well supported — first-party illustration, plurality of position-taking projects, all three high-download libraries, the leading web framework — and the executed checks confirm it does what is claimed, including the parts most often overstated (it does not reach dependencies; it does cover unsafe attributes).

The residual uncertainty is honest and specific, and it is not about Rust: it is about *this template's audience*. The forbid-versus-deny argument turns on the claim that most forks of a CLI + library + web-service template will never write `unsafe`. That claim is supported by the shape of the expected dependency stack (clap, axum and tower-http all forbid or deny `unsafe` in their own code) and by the practice table, but it is a judgement about people, not a measurement. Two evidence gaps bear on it and neither could be closed: the Rust CLI working group's book says nothing about `unsafe` (0 hits across 69 documents), and the annual Rust survey does not measure policy adoption (0 hits in the 2024 results). The template layer is silent too — the most-starred general-purpose `cargo-generate` templates set no policy at all. So there is no external authority that ratifies the choice *for templates specifically*; the recommendation rests on library and application practice plus first-party documentation, which is the strongest evidence that exists but is not evidence about templates. This is why the cost of being wrong was engineered down to one token, and why `### Ranked runner-up` states its winning conditions concretely.

**Re-verify triggers.** Any one of these invalidates part of this report and should reopen it:

1. **The template acquires an FFI or exported-symbol requirement** — from R68 (`release-binary-artifacts`), a C-ABI surface, or a plugin boundary. Executed check F shows `forbid` rejects `#[unsafe(no_mangle)]`, so this trigger forces the runner-up. Highest-likelihood trigger.
2. **A dependency in the settled stack is found to expand `unsafe` into consuming crates through a macro.** `forbid` applies to the expansion and cannot be locally suppressed. Re-verify when R60 (CLI framework), R69 (web stack) and R05 (execution model) have chosen their crates, by running executed check K against the real dependency set rather than `memchr`.
3. **`cargo-geiger` issue #539 closes** (https://github.com/geiger-rs/cargo-geiger/issues/539). This removes the single concrete cost of preferring the table over the crate-root attribute, and would let a fork adopt `cargo-geiger` without the misreporting caveat. It does not change the recommendation, only one paragraph of `### Tradeoffs`.
4. **A future Rust edition or release changes `unsafe_code`'s scope, or gives `forbid` a reason-carrying override.** The latter would collapse the distance between the recommendation and its runner-up entirely. Re-verify against the rustc book's lint-levels and allowed-by-default pages on each edition boundary.
5. **The owner states that the template's target audience routinely writes `unsafe`.** This is the assumption named above as the residual uncertainty; if it is wrong, the runner-up wins immediately and the change is one token.
6. **Routine freshness.** All figures here carry retrieval date 2026-09-06. Re-pull the practice table and the two crate figure sets if this item is still open six months later, since star counts, download counts and `pushed_at` all drift and `cargo-geiger`'s maintenance rubric (`stable-quiet`) rests on a release that was already 12 months old at retrieval.

### Sources

Every URL below was retrieved **2026-09-06**. Endpoints for numeric figures are named inline where the figure appears; the list groups them by role.

*First-party specification and reference*
- rustc book, Lint levels (forbid/deny semantics, `--cap-lints`, priority of lint level sources): https://doc.rust-lang.org/rustc/lints/levels.html
- rustc book, Allowed-by-default lints (`unsafe_code` default level and scope; `unsafe_op_in_unsafe_fn`): https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html
- Cargo Book, Manifest → "The `[lints]` section" (level values, `priority`, table naming, dependency scoping sentence, "MSRV: Respected as of 1.74"): https://doc.rust-lang.org/cargo/reference/manifest.html
- Cargo Book, Workspaces → "The lints table" (`[workspace.lints.rust] unsafe_code = "forbid"` + `[lints] workspace = true` example; MSRV): https://doc.rust-lang.org/cargo/reference/workspaces.html
- Rust Edition Guide, `unsafe_op_in_unsafe_fn` warning (edition 2024 default change): https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-op-in-unsafe-fn.html
- Rust 1.81.0 release announcement (`#[expect]` stabilization; `undocumented_unsafe_blocks` as its worked example; `clippy::allow_attributes`, `clippy::allow_attributes_without_reason`): https://blog.rust-lang.org/2024/09/05/Rust-1.81.0/

*Convention and lint definitions*
- Standard library developers Guide, Safety comments policy (`// SAFETY:` convention; `unsafe_op_in_unsafe_fn` active in std): https://std-dev-guide.rust-lang.org/policy/safety-comments.html
- clippy `undocumented_unsafe_blocks` source (group `restriction`, `#[clippy::version = "1.58.0"]`, `unnecessary_safety_comment` at 1.67.0, the two `accept_comment_above_*` config fields): https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/undocumented_unsafe_blocks.rs
- clippy `multiple_unsafe_ops_per_block` source: https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/multiple_unsafe_ops_per_block.rs
- Clippy Book, Lint configuration (`accept-comment-above-statement`, `accept-comment-above-attributes`, both default `true`): https://doc.rust-lang.org/clippy/lint_configuration.html
- Rust API Guidelines checklist (used to correct the prompt's `C-SAFETY` to the real `C-FAILURE`): https://rust-lang.github.io/api-guidelines/checklist.html

*Practice evidence — project source, read at `HEAD` of the default branch*
- axum: https://raw.githubusercontent.com/tokio-rs/axum/HEAD/Cargo.toml · https://raw.githubusercontent.com/tokio-rs/axum/HEAD/axum/Cargo.toml
- clap: https://raw.githubusercontent.com/clap-rs/clap/HEAD/Cargo.toml · https://raw.githubusercontent.com/clap-rs/clap/HEAD/clap_builder/src/lib.rs
- rustls: https://raw.githubusercontent.com/rustls/rustls/HEAD/rustls/src/lib.rs · https://raw.githubusercontent.com/rustls/rustls/HEAD/Cargo.toml
- ureq: https://raw.githubusercontent.com/algesten/ureq/HEAD/src/lib.rs
- bat: https://raw.githubusercontent.com/sharkdp/bat/HEAD/src/lib.rs · https://raw.githubusercontent.com/sharkdp/bat/HEAD/src/bin/bat/main.rs
- tower-http: https://raw.githubusercontent.com/tower-rs/tower-http/HEAD/tower-http/src/lib.rs
- uv: https://raw.githubusercontent.com/astral-sh/uv/HEAD/Cargo.toml · ruff: https://raw.githubusercontent.com/astral-sh/ruff/HEAD/Cargo.toml
- just: https://raw.githubusercontent.com/casey/just/HEAD/Cargo.toml
- anyhow: https://raw.githubusercontent.com/dtolnay/anyhow/HEAD/src/lib.rs · tokio: https://raw.githubusercontent.com/tokio-rs/tokio/HEAD/tokio/src/lib.rs
- ripgrep, fd, serde, reqwest, hyper, actix-web, starship — manifests and crate roots at the same URL shape; each returned no `unsafe_code` level.
- Whole-repository escape-hatch counts (bat, tower-http, ruff, uv): `GET https://api.github.com/search/code?q=repo:<o>/<r>+unsafe_code`, `+%22allow(unsafe_code)%22`, `+%22expect(unsafe_code)%22`, reading `total_count`
- tower-http's single `#[allow(unsafe_code)]` in context: https://raw.githubusercontent.com/tower-rs/tower-http/HEAD/tower-http/src/services/fs/serve_dir/tests.rs
- ruff's `#[expect(unsafe_code)]` sites in context: https://raw.githubusercontent.com/astral-sh/ruff/HEAD/crates/ruff_index/src/vec.rs
- clippy `missing_safety_doc` (group `style`, version 1.39.0): https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/doc/mod.rs

*Templates and evidence gaps*
- `cargo-generate` README (no curated template list; points at the GitHub topic): https://raw.githubusercontent.com/cargo-generate/cargo-generate/HEAD/README.md
- `rust-github/template` file listing: `GET https://api.github.com/repos/rust-github/template/git/trees/HEAD?recursive=1` · `ratatui/templates`: https://raw.githubusercontent.com/ratatui/templates/HEAD/simple/template/Cargo.toml
- Rust CLI book search index (0 occurrences of `unsafe` across 69 documents): https://rust-cli.github.io/book/searchindex.json
- 2024 State of Rust Survey results (0 occurrences of `unsafe`): https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/

*Excluded-candidate figures*
- cargo-geiger: `GET https://crates.io/api/v1/crates/cargo-geiger` · `/versions` · `GET https://api.github.com/repos/rust-secure-code/cargo-geiger` (redirects to `geiger-rs/cargo-geiger`) · `GET https://api.github.com/search/issues?q=repo:geiger-rs/cargo-geiger+is:issue+is:open` · https://rustsec.org/packages/cargo-geiger.html · issue #539: https://github.com/geiger-rs/cargo-geiger/issues/539
- cargo-vet: `GET https://crates.io/api/v1/crates/cargo-vet` · `/versions` · `GET https://api.github.com/repos/mozilla/cargo-vet` · `GET https://api.github.com/search/issues?q=repo:mozilla/cargo-vet+is:issue+is:open` · https://rustsec.org/packages/cargo-vet.html
- safety-dance (historical context only): `GET https://api.github.com/repos/rust-secure-code/safety-dance` · https://raw.githubusercontent.com/rust-secure-code/safety-dance/HEAD/README.md

*Repository context read for this item*
- `docs/port/COMMONALITY.md` (row F023) · `docs/port/PARAMETERS.md` (the four fixed parameters) · `docs/port/README.md` (verdict vocabulary) · `docs/port/BASELINE-REVIEW.md` (F017 and the absence of an F023 row) · `research/CLAUDE.md` (R06 row: kind `pattern`, origin `none`, verdict `RUST-ONLY`, owns `—`) · `research/RUNBOOK.md` (the `CONFLICT:` and `BASELINE-REVIEW:` line formats).

**Method notes.** Crate figures came from `curl -sS` against `https://crates.io/api/v1/crates/<name>` and `/versions` with an explicit `User-Agent` header, reading `crate.recent_downloads`, `crate.downloads`, and the newest version with `yanked: false`. GitHub figures came from the authenticated `gh api` client rather than bare `curl`, because unauthenticated `https://api.github.com` requests from this host returned HTTP 403 "API rate limit exceeded"; the endpoints are the ones the prompt specifies — `repos/<o>/<r>` for `stargazers_count`, `archived` and `pushed_at`, and `search/issues?q=repo:<o>/<r>+is:issue+is:open` for `total_count` (never `open_issues_count`). Project source was read from `https://raw.githubusercontent.com/<o>/<r>/HEAD/<path>`, which is not metered by the API quota; quoted line numbers are as of that fetch of each default branch and will drift. Because reading manifests and crate roots cannot prove the *absence* of a per-site escape hatch elsewhere in a repository, the four projects whose hatch usage the argument depends on (bat, tower-http, ruff, uv) were additionally searched whole-repository with `GET https://api.github.com/search/code?q=repo:<o>/<r>+<term>`, reading `total_count`; that endpoint is rate-limited separately and more tightly than the rest of the REST API, and it returned HTTP 403 "API rate limit exceeded" after the counts above were collected but before every matching path could be enumerated for uv — uv's count of 3 is therefore reported without its file paths. RustSec was queried as `https://rustsec.org/packages/<name>.html`; because that endpoint returns 404 both for "no advisories" and for a nonexistent page, the reading was controlled on the same date against `time.html` (HTTP 200, a crate with advisories) and `serde.html` (HTTP 404, a crate without), establishing that 404 means no advisories. Executed checks A–K ran on this host with `rustc 1.98.0` / `cargo 1.98.0` / `clippy 0.1.98`, `aarch64-apple-darwin`, in a throwaway Cargo workspace created in this session's scratchpad directory outside the repository and deleted afterwards; the only repository file written by this run is `raw/opus.md`.

**Could not verify.** (1) The Linux half of `target-os-matrix` — every executed check ran on macOS only; the claim that the diagnostics are identical on `ubuntu-latest` rests on lint levels being OS-independent and is listed as planned check P1, not as a result. (2) The MSRV floor path — checks ran on current stable 1.98.0, not on the ≈1.96 floor implied by `msrv-policy`; planned check P2. (3) `cargo-geiger`'s misreporting of the `[lints]`-table form was **not** reproduced locally; it is reported from the maintainers' own open issue #539 and its comment thread, and is labelled as such throughout (planned check P4, deliberately not run since the tool is out of scope). (4) `cargo-geiger`'s issue-responsiveness figure treats "first comment by someone other than the issue author" as the maintainer response, since collaborator status was not queried per commenter; 6 of the 7 measured replies were by `pinkforest`, who also triages and assigns work in the thread, so the proxy is close but is a proxy. (5) No adopter-count figure was taken from a crates.io reverse-dependencies page: the recommendation is a toolchain feature with no crates.io presence, so "adopters" was evidenced by reading the projects' own manifests and crate roots instead, which is the stronger form of the same evidence. (6) Star and download counts are point-in-time and were each read once; no trend is claimed. (7) uv's 3 `expect(unsafe_code)` sites are reported as a count only; the code-search rate limit was reached before their file paths could be listed, so the claim that they resemble ruff's sites is an inference from the shared `[workspace.lints.rust] unsafe_code = "warn"` posture, not a reading. (8) Whether `BurntSushi/ripgrep` and `sharkdp/fd` set no level because they need `unsafe` or because they never took a position was **not** determined; no motive is attributed to them anywhere above.
