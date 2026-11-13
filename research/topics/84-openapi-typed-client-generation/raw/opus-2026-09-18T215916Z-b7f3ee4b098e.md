# R84 — openapi-typed-client-generation (crate, Deep) — Opus raw research report

Engine: Opus (`claude-opus-5`), fresh context. Run `research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e`.
Every figure below was retrieved on **2026-09-18 (UTC)** unless a different date is stated beside it.
Every probe was executed in a throwaway directory under `$TMPDIR` on macOS 15 / darwin arm64 with
`rustc 1.98.0 (88d9e12ae 2026-08-18)` and `cargo 1.98.0 (797e8a9bc 2026-08-05)`, both Homebrew builds.
Commands and verbatim output are quoted where they are load-bearing.

### Landscape

**The category.** "Given a committed OpenAPI 3.x document, emit a typed Rust HTTP client whose
request and response types match the document's schemas, and whose method names are stable across
regenerations." The tool is a build-time code generator, not a runtime dependency of the template.
This is the Rust half of py's `WEB-60` — "typed clients are generated, never hand-written"
(`py-launch-blueprint` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`docs/design/0002-web-api-conventions.md:86`, read through the pin with
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>`).

**Bin 1 — built-in or first-party toolchain: empty, and that is a finding.**
Neither `cargo`, `rustc`, nor `rustup` ships an OpenAPI client generator, and the Rust Project
publishes none. The Cargo Book's built-in command list contains no such subcommand
(<https://doc.rust-lang.org/cargo/commands/index.html>, retrieved 2026-09-18). The bin is empty in
Python too — `openapi-python-client` is a third-party project — so the two ecosystems are being
compared on equal footing: in both, the answer is a third-party generator invoked by a recipe.

**Bin 2 — established industry standard (two entrants, one per lineage).**

| Tool | Lineage | Why it belongs in this bin |
|---|---|---|
| **OpenAPI Generator**, `rust` client generator, **7.25.0** | Cross-language, Java-implemented, community-governed (`OpenAPITools/openapi-generator`) | 26,752 stars, not archived, `pushed_at` `2026-09-17T17:54:53Z` (`GET https://api.github.com/repos/OpenAPITools/openapi-generator`). 7.25.0 published to Maven Central `2026-08-24T08:25:01 GMT` (`HEAD https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.25.0/openapi-generator-cli-7.25.0.jar`, `last-modified`), 7.24.0 on `2026-07-20T08:46:35 GMT` — a monthly cadence. Its own generator page states `generator stability STABLE`, `generator type CLIENT` (<https://openapi-generator.tech/docs/generators/rust/>) |
| **progenitor 0.15.0** (`oxidecomputer/progenitor`) | Rust-native, single-vendor (Oxide Computer) | 1,007 stars, not archived, `pushed_at` `2026-09-13T00:06:05Z`. 1,317,950 90-day downloads, 5,206,003 all-time (`GET https://crates.io/api/v1/crates/progenitor`); `progenitor-client`, the runtime half every generated client links, is at 1,604,720 / 6,154,989 |

**Bin 3 — up-and-comers.** `openapi-to-rust` 0.17.0, `spargen` 0.4.0, `ploidy` 0.15.0,
`openapi-nexus` 0.2.3, `openapi-model-generator` 0.6.3, and the thin Rust wrapper crate
`openapi-generator-cli` 0.1.2 (68 all-time downloads — a `cargo` shim around the same Java jar).
Found by `GET https://crates.io/api/v1/crates?q=<terms>&per_page=20..30` for the term sets
`openapi client generator`, `openapi codegen`, `swagger codegen`, `openapi generate client`, sorted
by `recent-downloads` and by `relevance`. `paperclip` 0.9.7 appears in these searches but is a
different category (spec hosting for actix-web, plus Swagger-2.0-era codegen) and is excluded below.

**Authoritative sources used, and why each counts.**

| Source | Why authoritative |
|---|---|
| crates.io API (`/api/v1/crates/<name>`, `/versions`) | The Rust registry's own canonical metadata; the exact fields the prompt's figure table names |
| GitHub REST API (`/repos/<o>/<r>`, `/search/issues`) | Canonical repository state; the prompt's named source for stars, `archived`, `pushed_at`, open issues |
| RustSec (`https://rustsec.org/packages/<name>.html`) | The Rust Secure Code Working Group's advisory database — the Rust project's own security source |
| Maven Central `maven-metadata.xml` and jar `last-modified` | The canonical release record for a Java-published artifact; crates.io cannot answer for it |
| **Maintainers' own published source**, read at the `.crate`/repository artifact: `progenitor-impl-0.15.0/src/lib.rs`, `cargo-progenitor-0.15.0/src/main.rs`, `utoipa-5.5.0/src/openapi.rs`, `oxidecomputer/oxide.rs` `xtask/src/main.rs` | The strongest form of maintainer documentation: the behaviour itself, not a description of it. A blog post is a lead; a released source file is the contract |
| openapi-generator.tech generator pages | The tool maintainers' own reference documentation |
| Homebrew formula API (`https://formulae.brew.sh/api/formula/openapi-generator.json`) | Canonical packaging record, which decides whether R42's "bare executable resolved on PATH" rule can be satisfied |
| `py-launch-blueprint` at pin `b08bccfb`, read via `git show` | The source precedent this item ports; the pin is the version the ledger cites |

**Practice evidence — well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Generator | Evidence of standing |
|---|---|---|
| **LanceDB**, `lance-namespace-reqwest-client` 0.13.0 | **OpenAPI Generator `rust`** — its `Cargo.toml:4` carries `authors = ["OpenAPI Generator team and contributors"]`, the exact marker my own probe emitted (<https://raw.githubusercontent.com/lancedb/lance-namespace/main/rust/lance-namespace-reqwest-client/Cargo.toml>) | 1,445,044 90-day downloads, 2,609,515 all-time (`GET https://crates.io/api/v1/crates/lance-namespace-reqwest-client`) — the Lance columnar format's official REST client |
| **Datadog**, `datadog-api-client` 0.36.0 | Generated from Datadog's public OpenAPI specs "by internal tooling" (<https://raw.githubusercontent.com/DataDog/datadog-api-client-rust/master/README.md>, line 3) — OpenAPI-driven, tool not named, so it evidences the *practice*, not the tool | 527,654 90-day, 2,082,824 all-time downloads |
| **Langfuse**, `langfuse-client-base` 0.14.0 | **OpenAPI Generator 7.25.0**, pinned by version in the generation script and run through the official Docker image (<https://raw.githubusercontent.com/genai-rs/langfuse-client-base/main/scripts/generate-openapi-client.sh>, lines 15 and 29) | 6,457 90-day downloads; a small but exactly-analogous case — a committed generated client regenerated from a fetched spec |
| **Oxide Computer**, `oxide` SDK and CLI | **progenitor**, through an `xtask` (<https://raw.githubusercontent.com/oxidecomputer/oxide.rs/main/xtask/Cargo.toml>, `progenitor` + `rustfmt-wrapper` dependencies) | progenitor's own authors; `oxide-api` 48,818 all-time downloads. The reference implementation of progenitor codegen |
| **Zoo / KittyCAD**, `kittycad` 0.5.2 | A generated, "fully generated & opinionated" API client | 99,860 90-day, 697,417 all-time downloads |

**Fit — the four-step method's last step, stated here and carried through the whole report.**
The template is CLI + library + optional web service. The generated client is *not* the CLI's HTTP
client: R05 revision 3 settles that the library and CLI are synchronous and reach the *upstream*
API through `ureq` 3.4.2 behind R01's `ProjectsPort`. The generated client points the other way —
it is a consumer artifact for the API this template *serves*. The two never meet in one dependency
tree, which is the single most important structural fact in this item.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**
Source: `py-launch-blueprint` at pin `b08bccfb`, `docs/design/0002-web-api-conventions.md:86` —
"**WEB-60 — typed clients are generated, never hand-written**: `just client-python`
(openapi-python-client) from the committed snapshot", and `EXAMPLEWEB.md:138` — "Generate a typed
client with `just client-python` — never hand-write one." `ts-launch-blueprint` at pin
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` has no web service and therefore no entry (F303).
Ledger row **F335**, `docs/port/COMMONALITY.md:339`, origin `py-only`, verdict `DIVERGENT`, item R84.

The agreement level is **policy plus capability**, not a shared low-level value:

| Level | Clause | Must agree across py / ts / rs? |
|---|---|---|
| Policy | A typed client is **generated from the committed OpenAPI document, never hand-written** | **Yes.** This is the whole of WEB-60 |
| Policy | The **committed snapshot is the reviewable contract**; the generated client is a derived artifact and is not the contract | **Yes** |
| Capability | A **single named recipe** regenerates the client with one command | **Yes** |
| Capability | **Operation ids are curated** so generated method names are stable and human-readable | **Yes** — and R71 owns the curation (F312) |
| Mechanism | Which tool; its implementation language; crate-vs-module output; committed or not; the HTTP client inside it; sync or async | **No.** Each ecosystem picks natively |

No shared low-level value is recommended. There is no owner requirement for one, and the evidence
does not support the same tradeoff in all three ecosystems: Python's generator is a Python program
producing a Python package that drops into the same interpreter; Rust's best available generator is
a Java program producing a Cargo package that must be kept *out* of the workspace. ts has no web
service at all, so there is nothing to preserve there beyond the policy itself.

**The evidence that settles the *shape*, and that nearly every reading of py gets wrong.**
py's recipe is on-demand and its output is **not committed, not gitignored, and not run in CI**:

- `Justfile:311-312` (at pin `b08bccfb`) — `[group('build')] @client-python out="clients/python":` /
  `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`.
- `git ls-tree -r --name-only b08bccfb | grep -i -E "^clients|openapi"` returns exactly three paths —
  `docs/api/openapi.json`, `scripts/export_openapi.py`, `tests/web/test_openapi_snapshot.py`. There is
  **no `clients/` tree in the pinned commit.**
- `git show b08bccfb:.gitignore | grep -i -E "client|openapi"` returns nothing — the directory is not
  ignored either; it simply is never produced in the repository's own history.
- `git grep -n "client-python\|openapi-python-client" b08bccfb --` returns five hits: `Justfile:311`,
  `Justfile:312`, and three documentation lines. **No workflow file invokes it.**

So the baseline is: *one build-group recipe, ephemeral output, no CI gate, no published package.*
The snapshot is gated (a staleness test and an `oasdiff` workflow, both R71's and R83's territory);
the client is not. Any Rust design that commits a generated client and drift-checks it in CI is
*adding* a gate the source repository deliberately does not have, and must justify the addition
rather than inherit it.

**Architectural alternatives, compared before any tool is chosen.**

| # | Architecture | Verdict | Ground |
|---|---|---|---|
| **A** | **Out-of-workspace generated crate, produced on demand by a `just` recipe, uncommitted** | **Chosen** | Reproduces py's shape exactly; keeps `reqwest`/`tokio` out of every workspace member's tree (R05 criterion 1); needs no `build.rs` (R49); adds no CI job, no pinned action, no published artifact |
| **B** | **Fifth workspace member, committed, drift-checked in CI with `git diff --exit-code`** | Rejected, conditionally | This is the owner reference's shape (line 89) and it is *feasible* — my determinism probe shows two runs of the generator over the same input produce byte-identical trees (`diff -r` clean). It is rejected because **there is no in-repo Rust consumer to keep in sync**: nothing in the CLI, core or web member calls the generated client, so the gate would guard an artifact no build depends on. It also fails R02's promotion rule (below) and drags `reqwest`+`tokio` into `cargo metadata` for the workspace. It becomes correct the moment the owner scopes a Rust consumer |
| **C** | **`build.rs` or `progenitor::generate_api!` proc-macro compiled into a consuming crate** | Rejected | Two independent grounds. R49's owned `build-tool-output-shape` contains the live clause "**no build.rs and no build-orchestration crate**". And the macro form compiles the client — and therefore `reqwest`, `hyper` and `tokio` — into whichever member expands it, which is exactly what R05's criterion 1 (`cargo tree -i tokio -e normal` on the root package's default tree finding nothing) forbids |
| **D** | **Hand-rolled codegen over `openapiv3` 2.2.0 or `oas3` 0.22.0** | Rejected | `openapiv3` 2,978,577 90-day downloads, last release 2.2.0 on `2025-06-02T15:56:56Z`; `oas3` 786,524 90-day, 0.22.0 on `2026-05-06T04:08:15Z`. Both are excellent *parsers*, and writing a generator on top of one is re-implementing a maintained tool inside a template whose purpose is to demonstrate good practice, not to ship a codegen project |
| **E** | **Skip the client; export types directly (the `ts-rs`/`specta` analogue the owner reference names at line 89)** | Rejected | F335 asks for a *client*, not types, and the owner reference itself says the cost of direct type export is that "you lose the served spec third parties need". It also cannot satisfy "never hand-written", because the request/response plumbing would still be hand-written |

**Where the generated crate sits, against R02's own promotion rule.** R02 revision 2
(`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`, owner-accepted `W1-R02`)
fixes a four-package workspace and records exactly when a fifth member is admitted. Its re-verify
line (`:186`) names the triggers: "**a second bounded context, a second production adapter or a
second installable binary appearing, any of which promotes `crates/adapters` to a fifth member**",
and its disagreement table (`:283`) says "A fifth `crates/adapters` member is the recorded promotion
path the moment a second adapter appears". A generated client of the template's *own served API* is
none of those three: it is not a bounded context, it does not implement `ProjectsPort` (it is
downstream of the service, not an adapter the core drives), and it ships no binary. It therefore
does not reach R02's promotion bar, and architecture A — outside the workspace — is the answer R02's
own rule produces. R02's mechanical guard reinforces it: the facade's dependency-free
`tests/workspace_edges.rs` asserts the intra-workspace edge set "plus `crates/core`'s
external-dependency allow-list", so a `reqwest` leak into the core would fail `cargo test --workspace`
without anyone having to notice.

**Essential behaviours and observable acceptance criteria.**

| # | Behaviour | Acceptance criterion | Status in this report |
|---|---|---|---|
| B1 | One command regenerates the client from the committed snapshot | `just client-rust` exits `0` and writes a Cargo package | **Executed** (generation probe) |
| B2 | The generated client compiles on stable Rust at the MSRV floor | `cargo build` succeeds on current stable and on `stable − 2` | **Executed** on 1.98.0 (28.03 s) and 1.96.0 (38.23 s) |
| B3 | Curated operation ids produce stable, human-readable method names | `operationId: projects-list_projects` → `pub fn projects_list_projects` | **Executed** |
| B4 | Absent curation degrades visibly and predictably | Missing `operationId` → a named, path-derived fallback, reported | **Executed** — `v1ProjectsGet` with a `WARN` |
| B5 | The generated tree never enters the workspace's default dependency graph | `cargo tree -i tokio -e normal` on the root package finds nothing | **Planned for P03** — R05 check C10/T06 already measures it at 38 crates; this design adds no member, so the number is unchanged by construction |
| B6 | Regeneration is deterministic | Two runs over one input produce byte-identical output | **Executed** — `diff -r` clean |
| B7 | The generated crate carries the repository's license | `info.license` in the snapshot → `license =` in the generated `Cargo.toml` | **Executed** |

**`BASELINE-REVIEW:` — none emitted, and here is why.** The `BASELINE-REVIEW:` process adjudicates
inherited mechanisms, that is `COMMON → REUSE` and `ADOPT` rows (`docs/port/README.md`, item 11).
F335 is `DIVERGENT` with origin `py-only` (`docs/port/COMMONALITY.md:339`) — it is not an inherited
baseline, it is an open decision this item makes. I examined py's mechanism closely (above) and found
nothing in it that needs challenging: the on-demand, uncommitted, un-gated shape is *correct* for an
artifact with no in-repo consumer, and this recommendation preserves it rather than departing from it.

**Owner reference architecture (`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`),
row-by-row disposition.** R69 revision 10 hands two C3 rows to this item (`:2398-2399`). Four rows
touch R84; the document names neither progenitor nor OpenAPI Generator anywhere.

| Row | Reference says | R84 |
|---|---|---|
| C3, OpenAPI generation — `utoipa` 5 + `utoipa-axum` 0.2 (`:50`, `:90`) | R71's row, not mine | **Agree, and compatible.** I verified what it implies for me: `utoipa` 5.5.0's `OpenApiVersion` enum has exactly one variant, `Version31`, `#[serde(rename = "3.1.0")]`, `#[default]`, and its `Deserialize` rejects anything that is not `3.1.x` (`utoipa-5.5.0/src/openapi.rs:378-425`, read at the published `.crate`). utoipa **cannot** emit 3.0. My pick consumes 3.1; progenitor cannot |
| C3, TypeScript client — `openapi-typescript` + `openapi-fetch` (`:51`, `:90`, `:2399`) | Generate a TS client for the SPA head | **Differ, on scope.** `docs/planning/p02/owner-decisions.md` section 11 states that the "HTMX-versus-SPA head" is among the rows "NOT decided and NOT researched by this instruction". There is no TypeScript surface in this template to consume such a client, and F335 asks for a client from the committed snapshot in *this* repository's language. I surveyed no npm tooling |
| C3, "Run generation in CI and `git diff --exit-code` so drift fails the build" (`:90`, `:426`) | A committed client, drift-gated | **Differ, on sourced ground.** py does the opposite — `Justfile:311-312` in `group('build')` only, no `clients/` tree at the pin, no workflow hit — and no Rust consumer of the generated client exists in this template, so the gate would guard nothing. My determinism probe shows the gate *would work* if it were wanted. **Condition under which I agree:** the owner scopes an in-repo Rust consumer (or adopts architecture B); then the client is committed and a drift job is requested from R11 |
| C3, "Direct Rust→TS export (`ts-rs` or `specta`)" (`:90`) | Viable for an internal SPA | **Differ.** The document's own caveat is the reason — "you lose the served spec third parties need" — and type export does not satisfy "never hand-written" for the request plumbing |

Tally: **4 rows touched — 1 agree-and-compatible, 3 differ.**

**Fitness gates, applied per candidate before popularity.**

Gate 1 (licence) is **`inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every candidate
(`docs/port/OWNER-REVIEW.md:46-62`: "Fitness gate 1 … is struck from every item's evaluation").
Declared licences appear below as recorded facts only; nothing is admitted, ranked or excluded on one.

The MSRV floor used for gate 2 is **1.96**, from `msrv-policy` against the stable toolchain in this
environment (`rustc 1.98.0`). Gate 2 for a Java-implemented tool applies to the **generated crate's
dependency tree**, not to the tool; that is stated per row rather than waived.

| Candidate | G1 licence | G2 MSRV | G3 advisory / `unsafe` | G4 `ubuntu-latest` + `macos-latest` | G5 default features / async coupling | G6 binary and compile cost |
|---|---|---|---|---|---|---|
| **OpenAPI Generator 7.25.0 `rust`** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; repo licence `Apache-2.0` | **Pass, executed.** Generated crate built clean under `rustup run 1.96.0 cargo build --no-default-features --features rustls` in **38.23 s**, and under 1.98.0 in **28.03 s**. The generated manifest itself declares `edition = "2021"` and no `rust-version` — see the limitation note under *Tradeoffs* | `https://rustsec.org/packages/reqwest.html` → **404**; control `https://rustsec.org/packages/atty.html` → **200**, so 404 means "no advisory page". No `unsafe` in the generated code; the tool is Java | **Executed on macOS 15 arm64** (this run). **Not executed on Linux** — the artifact is a platform-independent jar and Homebrew ships `openapi-generator` 7.25.0 with `dependencies: ["openjdk"]` for both platforms (`https://formulae.brew.sh/api/formula/openapi-generator.json`). Windows: same jar, not required | Generated crate: `reqwest ^0.13` with `default-features = false`, features `json, blocking, multipart, query, form`; crate features `default = ["native-tls"]`, `rustls`. With `supportAsync=false` the **public API is blocking `fn`**, no executor in the signatures. `tokio` is still *inside* reqwest's tree — irrelevant, because the crate is outside the workspace | 236-line `cargo tree -e normal`; 28–38 s clean debug build. Tool cost: a 30 MB jar plus a JVM (Temurin 21 unpacked to 336 MB here). Zero cost to the template's own build |
| **progenitor 0.15.0 / cargo-progenitor 0.15.0** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declared `MPL-2.0` | Pass — `rust_version: 1.88`, `edition: 2024` (crates.io `/versions`) | `https://rustsec.org/packages/progenitor.html` and `.../progenitor-client.html` → **404** (no advisory) | **Fail.** See *Excluded by gate* | Generated client links `progenitor-client` + `reqwest` + `futures`; async | Not measured — excluded before this point |
| **openapi-to-rust 0.17.0** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declared `MIT` | Pass — `rust_version: 1.88.0`, `edition: 2024` | No RustSec page; no `unsafe` observed in emitted code | Pass on macOS (executed here); repo CI not inspected | **Async only** — every operation is `pub async fn`. Emits `REQUIRED_DEPS.toml` naming `reqwest 0.13` (`query, rustls, stream`), `reqwest-middleware 0.5`, `futures-util 0.3`, `serde`, `serde_json`, `thiserror` to be pasted into a consuming crate's manifest | Not separately measured; emits 4 files, no crate |
| **paperclip 0.9.7** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declared `MIT OR Apache-2.0` | **Fail** — no `rust_version` on any published version | `unsafe` posture not assessed (excluded) | Not assessed | Not assessed | Not assessed |
| **openapi-model-generator 0.6.3** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declared `MIT OR Apache-2.0` | **Fail** — no `rust_version` on any published version | Not assessed | Not assessed | Models only; emits no HTTP client | Not assessed |

**Maintenance state by rubric.**

| Candidate | State | Concrete signal |
|---|---|---|
| OpenAPI Generator | **active** | 7.25.0 `2026-08-24`, 7.24.0 `2026-07-20`; `pushed_at` `2026-09-17T17:54:53Z`; not archived |
| progenitor | **active** | 0.15.0 `2026-09-10T04:03:39Z`; `pushed_at` `2026-09-13T00:06:05Z`; not archived. Its exclusion is functional, not a maintenance verdict |
| openapi-to-rust | **active, churning** | 0.17.0 `2026-09-14`; **33 published versions between 2026-02-13 and 2026-09-14** — roughly one release a week, with per-version downloads of 13–545 outside two spikes |
| spargen | **active, very young** | 0.4.0 `2026-08-29`; repo created `2026-07-04`; 4 stars against 133 open issues |
| ploidy | **active, very young** | 0.15.0 `2026-06-16`; repo created `2025-12-18`; `pushed_at` `2026-09-18T21:39:08Z`; 26 stars, 10 open issues |
| paperclip | **at-risk** | Last release `2026-04-20T21:31:23Z`, `pushed_at` `2026-04-20T21:46:37Z` — the no-release-in-6-months trigger fires, and the concrete signal is the **maintainers' own notice**: "It's currently under active development and **may not be ready for production use just yet**" (repository `README.md`). 81 open issues |

**Issue responsiveness — a partial sample, and why.** The polling budget is one GitHub API call per
20 s, and a per-issue first-response measurement is one call per issue. I sampled the first-comment
timeline of **6 of the 10** most recently opened issues for OpenAPI Generator and **4 of 10** for
progenitor, from `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc&per_page=10`
plus `GET https://api.github.com/repos/<o>/<r>/issues/<n>/comments?per_page=3`. I report the sample,
not an extrapolated median over ten.

- **OpenAPI Generator** (10 most recent issues opened `2026-09-09` → `2026-09-18`; lifetime issue
  count 10,140; **5,128 open**, from `search/issues?q=…+is:open`). Of the 6 sampled: #24959 answered
  by `jpfinne` (`CONTRIBUTOR`) after **0.25 d**; #24950 answered by `jpfinne` after **0.58 d**;
  #24954's only comment is the reporter's own, so it counts as unanswered by a maintainer; #24962,
  #24958, #24956 have zero comments. **Sample median among answered: 0.4 d; 4 of 6 unanswered.**
- **progenitor** (10 most recent issues opened `2026-01-10` → `2026-07-09` — the most recent issue is
  **71 days old at retrieval**; lifetime issue count 187, **93 open**). Of the 4 sampled: #1362
  answered by `ahl` (`COLLABORATOR`) after **0.21 d**; #1359 answered by `ahl` after **2.19 d**;
  #1382 and #1345 have zero comments. **Sample median among answered: 1.2 d; 2 of 4 unanswered.**

The 5,128 open issues on OpenAPI Generator are a whole-project figure across ~60 generators. Scoped
to the generator this item uses, `search/issues?q=repo:OpenAPITools/openapi-generator+is:issue+is:open+label:"Client: Rust"`
returns **`total_count: 15`**.

**Minimal realistic example.** A 3-operation OpenAPI 3.1.0 document mirroring py's committed snapshot
shape — `GET /healthz` (`operationId: ops-healthz`), `GET /v1/projects` (`projects-list_projects`,
one optional `limit` query parameter), `GET /v1/projects/{project_id}` (`projects-get_project`, a
404 branch returning `Problem`) — with `Health`, `Project`, `PageProject` and `Problem` under
`components/schemas`. I verified py's real snapshot has exactly this form:
`git show b08bccfb:docs/api/openapi.json` reports `openapi: 3.1.0` and operation ids
`ops-healthz`, `ops-readyz`, `projects-list_projects`, `projects-get_project` — that is, **py's
committed contract is OpenAPI 3.1.0 with curated `tag-function` ids**.

**Executed results on that example.**

*OpenAPI Generator 7.25.0, `rust` generator, blocking reqwest:*

```
java -jar openapi-generator-cli-7.25.0.jar generate -i api-3.1.json -g rust -o out \
  --additional-properties=packageName=rslbp-client,packageVersion=0.1.0,supportAsync=false,library=reqwest,hideGenerationTimestamp=true \
  --global-property=apiDocs=false,modelDocs=false,apiTests=false,modelTests=false
```

exits `0`, warning `OpenAPI 3.1 support is still in beta. To report an issue related to 3.1 spec,
please kindly open an issue in the Github repo`. It emits `src/lib.rs`, `src/apis/{mod,configuration,
ops_api,projects_api}.rs`, `src/models/{mod,health,project,page_project,problem}.rs`, `Cargo.toml`,
`README.md`. The client functions are:

```
pub fn projects_get_project(configuration: &configuration::Configuration, project_id: &str) -> Result<models::Project, Error<ProjectsGetProjectError>>
pub fn projects_list_projects(configuration: &configuration::Configuration, limit: Option<i32>) -> Result<models::PageProject, Error<ProjectsListProjectsError>>
```

*progenitor 0.15.0, on the same document:*

```
cargo progenitor -i api-3.1.json -o out -n rslbp-client -v 0.1.0 --license-name "MIT OR Apache-2.0"
exit=1
gen fail: UnexpectedFormat("invalid version: 3.1.0")
Error: generation experienced errors
```

*progenitor 0.15.0, on the same document downgraded to `openapi: 3.0.3`:*

```
exit=101
thread 'main' (858532481) panicked at .../cargo-progenitor-0.15.0/src/main.rs:95:68:
called `Result::unwrap()` on an `Err` value: Unstable("wrap_comments, normalize_doc_attributes")
```

Only `Cargo.toml` was written before the panic; no `src/` was produced.

### Dominant choice

**There is no dominant choice, and the reason is the finding of this item.**

The Rust-native leader, **progenitor**, and the Rust-native OpenAPI *server* leader, **utoipa**,
cannot be composed: utoipa 5.5.0 emits only OpenAPI **3.1.0** and progenitor 0.15.0 accepts only
OpenAPI **3.0.x**. Both facts are in the maintainers' own released source, and both are executed
above. So the category's Rust-native half has a hole in exactly the place this template needs it.

What is dominant is the **cross-language incumbent**: **OpenAPI Generator's `rust` client generator**
is the only tool in this survey that (a) reads OpenAPI 3.1, (b) emits a complete, standalone Cargo
package, (c) runs from a single CLI invocation with no `build.rs` and no proc-macro, (d) produced a
crate that compiled clean on stable at the MSRV floor, and (e) has a decade of cross-language
adoption and a monthly release cadence behind it.

### Qualified shortlist

**Two, and the shortness is itself the finding.** Only two surveyed tools both clear every applicable
gate and can read the OpenAPI 3.1 document this template will almost certainly commit.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| **OpenAPI Generator 7.25.0**, generator `rust` | Java CLI → standalone Rust client crate | `inapplicable` — not a crate; distributed via Maven Central, Docker, npm and Homebrew | `inapplicable` — same reason | 26,752 | 7.25.0, `2026-08-24T08:25:01 GMT` (Maven Central `last-modified`) | **active** | LanceDB `lance-namespace-reqwest-client` (1,445,044 90-day downloads); `langfuse-client-base`; Datadog's OpenAPI-driven Rust client | Needs a JVM; its 3.1 support is self-labelled beta |
| **openapi-to-rust 0.17.0** | Rust CLI → Rust module tree + a dependency fragment | 41,839 | 42,417 | 36 | 0.17.0, `2026-09-14T17:28:43Z` | **active, churning** | None found — no reverse dependency on crates.io and no adopter located | Pure Rust and `cargo install`-able, but async-only, emits a module rather than a crate, and 33 releases in 7 months |

Both figures come from `GET https://crates.io/api/v1/crates/openapi-to-rust` and
`GET https://api.github.com/repos/gpu-cli/openapi-to-rust` (3 open issues,
`pushed_at 2026-09-14T17:33:31Z`, not archived), retrieved 2026-09-18.

### Excluded by gate

**`progenitor` 0.15.0 and `cargo-progenitor` 0.15.0 — excluded, and it loses under *both* plausible
R71 outcomes.** R71 (`openapi-generation-pipeline`) is unresearched, so I state the exclusion as two
branches rather than as one contingent fact.

- **Branch (a): R71's snapshot is OpenAPI 3.1** — which is what utoipa 5 can *only* emit, and what py
  commits today. Then progenitor **cannot read the document at all, in any of its three modes**. The
  check lives in the shared core every mode goes through, `progenitor-impl-0.15.0/src/lib.rs:702-709`:
  `fn validate_openapi_spec_version(spec_version: &str)` returns `Ok` only when the string
  `starts_with("3.0.")`, and the file's own unit test at `:794-798` asserts that `3.1.0` produces
  `"unexpected or unhandled format in the OpenAPI document invalid version: 3.1.0"`. My CLI probe
  produced exactly that error. GitHub issue search
  (`search/issues?q=repo:oxidecomputer/progenitor+is:issue+3.1+in:title`) returns `total_count: 0` —
  there is not even an open tracking issue for 3.1 support.
- **Branch (b): R71's snapshot is OpenAPI 3.0** — then progenitor parses it, and still loses:
  - The **CLI mode fails gate 4 and the `## Constraints` clause "Stable Rust only"**. On a stable
    toolchain `cargo progenitor` panics at `cargo-progenitor-0.15.0/src/main.rs:95` because
    `reformat_code` sets `normalize_doc_attributes: Some(true)` and `wrap_comments: Some(true)` —
    both nightly-only rustfmt options — and `.unwrap()`s the result. This is **corroborated by the
    maintainers' own reference implementation**: `oxidecomputer/oxide.rs` `xtask/src/main.rs:162-189`
    catches the same `rustfmt_wrapper::Error::Unstable` and panics with the message *"\"generate\"
    xtask requires a nightly rustfmt more recent than {} to be installed, as it uses the following
    features: {}"*, with a ten-line comment explaining that a developer's nightly must also be
    *newer* than their stable. progenitor's own authors document that their codegen path needs a
    nightly rustfmt.
  - The **`build.rs` mode is excluded by R49's live clause** "no build.rs and no build-orchestration
    crate" in the owned `build-tool-output-shape` value.
  - The **`generate_api!` proc-macro mode collides with R05 criterion 1**: it expands the client into
    the consuming crate, putting `progenitor-client`, `reqwest`, `hyper` and `tokio` into that
    member's dependency tree.

  That leaves no mode that satisfies this template's constraints even under branch (b).

  Two further recorded facts, neither of them a gate: progenitor **requires** an `operationId` on
  every operation — my probe returned
  `gen fail: UnexpectedFormat("path /v1/projects is missing operation ID")` on the variant with one
  id removed — which is a *stricter* dependency on F312 than py's generator has; and Oxide's own
  generated SDK is published as **`MPL-2.0`** (`oxidecomputer/oxide.rs` `sdk/Cargo.toml:6`), which is
  the licence progenitor's runtime half carries. Gate 1 is struck by the Q7.B ruling and none of this
  excludes progenitor. It is noted because the same ruling explicitly does **not** touch "any rule
  against committing third-party copyleft files *into* this repository", and progenitor's
  `--include-client true` flag would inline MPL-2.0 source. The recommended design commits no
  generated file at all, so the question never arises.

**`paperclip` 0.9.7 — excluded on gate 2, with a second independent ground.** No published version
declares `rust_version` (`GET https://crates.io/api/v1/crates/paperclip/versions`), and under the
strict reading of the MSRV gate recorded in `docs/planning/p02/owner-decisions.md` section 11 an
undeclared version fails rather than merely counting against. Independently, it is not this
category's tool: its README describes spec *hosting* and compile-time API definition for actix-web,
and states "It's currently under active development and may not be ready for production use just yet."

**`openapi-model-generator` 0.6.3 — excluded on gate 2**, no `rust_version` on any published version,
and independently on scope: it emits models, not an HTTP client, so it cannot satisfy "never
hand-written" for the request plumbing.

**`openapi-generator-cli` 0.1.2 (the Rust wrapper crate) — excluded on fit, not on a gate.** It is a
68-download shim that downloads and runs the same Java jar. Homebrew already puts a real
`openapi-generator` executable on `PATH`, which is what R42's `package-manager-invocation` rule asks
for; a wrapper crate adds a supply-chain hop for nothing.

Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate in this section;
nothing above is excluded on a licence.

### Up-and-comers

| Crate | Version / date | What it is | Why it is not the pick yet |
|---|---|---|---|
| **`openapi-to-rust`** 0.17.0 | `2026-09-14`, MIT, `rust_version 1.88.0`, edition 2024 | The most credible pure-Rust challenger: reads 3.0 and 3.1 (executed here), emits models + client + optional axum server scaffolding, has a `--check` staleness mode that would make a drift gate trivial | Emits a **module tree** (`mod.rs`, `client.rs`, `types.rs`) plus a `REQUIRED_DEPS.toml` fragment to paste into a consuming crate's manifest — so its dependencies land in a workspace member unless you hand-write a wrapper crate for it. Every operation is `pub async fn`. 36 stars, no located adopter, 33 releases in 7 months |
| **`spargen`** 0.4.0 | `2026-08-29`, MIT OR Apache-2.0, `rust_version 1.88` | "A compile-time-correct Rust client generator for OpenAPI 3.1.x and 3.2.x" — the only surveyed tool targeting 3.2 | 4,286 all-time downloads, **4 stars against 133 open issues**, repository created `2026-07-04`. Too young and too unbalanced to weigh |
| **`ploidy`** 0.15.0 | `2026-06-16`, Apache-2.0, `rust_version 1.89` | "An OpenAPI compiler for large and complex specs", actively pushed (`pushed_at 2026-09-18T21:39:08Z`) | 621 all-time downloads, 26 stars, 10 open issues; repository created `2025-12-18`. No adopter located |
| **`openapi-nexus`** 0.2.3 | `2026-08-22`, MIT OR Apache-2.0, `rust_version 1.90` | Multi-language generator written in Rust — the shape that would eventually remove the JVM from this answer | 1,103 all-time downloads; pre-0.3 |

The honest summary of this bin: a Rust-native, 3.1-capable, crate-emitting generator is *arriving*,
and none of the four has enough adoption, stability or independent verification to carry a template
whose job is to demonstrate good practice.

### Fit for this template

**CLI.** No interaction, by construction, and this is the most important fit statement in the item.
R05 revision 3 settles a synchronous library and CLI whose HTTP client is `ureq` 3.4.2 reaching the
**upstream** API through R01's `ProjectsPort`. The generated client reaches **this template's own
served API**, in the opposite direction, and nothing in the CLI calls it. The CLI's dependency tree
is unchanged by this decision — no `reqwest`, no second HTTP client, no `tokio`. **No `CONFLICT:`
against R05 is warranted**, and the reason it is not warranted is worth stating plainly rather than
leaving implicit: the collision R05's criterion 1 guards against would only occur if the generated
client were compiled into a workspace member, which architecture A forbids.

**Library.** The core library (`crates/core` under R02) carries models, ports, services, the error
catalogue and the in-memory fake, "No CLI or web framework, no HTTP client." The generated client
never becomes a dependency of it, and R02's `crates/core` external-dependency allow-list in
`tests/workspace_edges.rs` mechanically enforces that. The generated package is not a workspace
member, so `rust-edition = 2024` and the `[package] include` allow-list R49 owns are untouched: the
generated tree cannot enter the `.crate` file, because R49's include list is `/src`, `/README.md`,
`/LICENSE-MIT`, `/LICENSE-APACHE`, `/CHANGELOG.md` and `clients/` is not among them.

One line of the root manifest is required, and I verified both halves of it. With a nested package
under a workspace root and no exclusion, Cargo refuses:

```
error: current package believes it's in a workspace when it's not:
current:   .../wsprobe/clients/rust/Cargo.toml
workspace: .../wsprobe/Cargo.toml
...
Alternatively, to keep it out of the workspace, add the package to the `workspace.exclude` array, or add an empty `[workspace]` table to the package's manifest.
```

Adding `exclude = ["clients"]` to the root `[workspace]` table makes `cargo check` inside
`clients/rust` succeed (13.68 s), and `cargo check` at the repository root is unaffected in both
cases (0.57 s, the root package only).

**Web.** The web surface is R69's optional member `crates/web` (revision 10, accepted), inside which
R71's OpenAPI generation lives. R84 consumes that member's *output* — the committed snapshot — and
adds nothing to the member itself: no dependency, no module, no feature, no binary. The generated
client is the artifact a reader of the template uses to call the example service, and the concrete
demonstration that the served contract is machine-consumable.

### Recommendation

**Adopt OpenAPI Generator 7.25.0's `rust` client generator, invoked as one `just` recipe against
R71's committed snapshot, writing an uncommitted, out-of-workspace crate.** This is py's WEB-60
shape, realized with the only tool that clears this template's constraints.

The recipe, in R42's `package-manager-invocation` form (a bare executable resolved on `PATH`, no
provisioner or runner prefix):

```just
# Generate a typed Rust client from the OpenAPI snapshot (F335)
[group('build')]
@client-rust out="clients/rust":
    openapi-generator generate -i docs/api/openapi.json -g rust -o {{out}} \
      --additional-properties=packageName=rs-launch-blueprint-client,packageVersion=0.1.0,library=reqwest,supportAsync=false,hideGenerationTimestamp=true \
      --global-property=apiDocs=false,modelDocs=false,apiTests=false,modelTests=false
    echo "client written to {{out}}"
```

with four supporting facts, each executed:

1. **`supportAsync=false, library=reqwest`** yields a **blocking** public API —
   `pub fn projects_list_projects(configuration: &Configuration, limit: Option<i32>) -> Result<models::PageProject, Error<…>>` —
   the same execution model R05 settles for the rest of the template, so the example client reads the
   way the rest of the template reads.
2. **`hideGenerationTimestamp=true` plus the `--global-property` doc/test suppressions** make the
   output deterministic and small: two runs over one input produced byte-identical trees
   (`diff -r` clean), and the emitted set drops from 20 files to 11.
3. **`.gitignore` gains `/clients/`; the root `[workspace]` table gains `exclude = ["clients"]`.**
   Cargo's own error text (quoted above) names this as the fix.
4. **Presence is tested the way R42 prescribes for a non-rustup tool**: `command -v openapi-generator`.
   Homebrew ships `openapi-generator` 7.25.0 with `dependencies: ["openjdk"]`; the official Docker
   image exists but is **rejected** because R42 forbids a runner prefix in a Justfile recipe.

**What this recommendation asks of R71, stated as requirements rather than decisions.** R71 owns the
snapshot's origin; R84 needs four properties from whatever it picks:

| # | Requirement on R71 | Consequence if unmet | Evidence |
|---|---|---|---|
| **N1** | The snapshot's declared `openapi:` version string | None for this pick — 7.25.0 reads both 3.0.x and 3.1.0 (3.1 with a self-declared beta warning). This requirement exists because it is *decisive for the runner-up analysis*, not for the pick | Executed: 3.0.3 and 3.1.0 both generate cleanly |
| **N2** | An `operationId` on **every** operation, curated as py's `tag-function` (F312) | Method names silently become path-derived: removing `operationId` from `GET /v1/projects` turned `pub fn projects_list_projects` into `pub fn v1_projects_get` (and the error enum into `V1ProjectsGetError`), announced only by `WARN … Empty operationId found for path: get /v1/projects. Renamed to auto-generated operationId: v1ProjectsGet`. Such names then change whenever a path changes | Executed |
| **N3** | An `info.license` object in the snapshot | The generated `Cargo.toml` defaults to `license = "Unlicense"`. With `info.license` set to `MIT OR Apache-2.0` the generated manifest carries `license = "MIT OR Apache-2.0"` | Executed, both cases |
| **N4** | A stable committed path for the snapshot (py uses `docs/api/openapi.json`) | The recipe's `-i` argument; a trivial edit if it moves | py at pin `b08bccfb` |

**Recommendation conditioned on R71's plausible outcomes.** If R71 picks `utoipa` 5 (the owner
reference's C3 row, and the overwhelmingly likely outcome), the snapshot is 3.1.0 and **only** this
recommendation and the runner-up can consume it. If R71 picks a hand-written or runtime-dumped 3.0
document, this recommendation is unchanged and merely gains progenitor as a theoretical alternative
that still fails on stable-Rust and `build.rs` grounds. **The pick does not move under either branch**,
which is the property I optimized for.

### Ranked runner-up

**`openapi-to-rust` 0.17.0.**

**It wins under either of two conditions.** First, if the owner rules that a **JVM must not be a
contributor prerequisite** for any template recipe — a defensible position for a Rust template, and
one this report cannot decide. Second, if OpenAPI Generator's self-declared **3.1 beta** support
mishandles R71's actual snapshot in a way my three-operation probe did not exercise (the warning
`OpenAPI 3.1 support is still in beta` is the tool's own words, and 3.1's `type: ["string","null"]`
unions, `const`, and JSON-Schema-2020-12 `$ref` siblings are the known risk area).

**Its cost, measured.** It emits a module tree, not a crate: `mod.rs`, `client.rs`, `types.rs` and a
`REQUIRED_DEPS.toml` fragment whose header reads "Append this fragment to the consuming crate's
Cargo.toml". Taking it therefore means either hand-writing a `Cargo.toml` for the out-of-workspace
crate the module is mounted in — which is a hand-written file in a "never hand-written" item, though
a manifest rather than a client — or mounting the module inside a workspace member and pulling
`reqwest 0.13`, `reqwest-middleware 0.5` and `futures-util 0.3` into it, which R05 criterion 1
forbids. Its API is async-only (`pub async fn projects_list_projects(...)`), so the example client
would not match the template's own execution model. And its standing is thin: 36 stars, three open
issues, no reverse dependency and no adopter I could locate, against 33 releases in seven months.

### Tradeoffs

**Against progenitor (the Rust-native option that a reader will expect to see win).** We give up a
`cargo install`-able, pure-Rust toolchain, a nicer generated API (progenitor's `--interface builder`
mode), and alignment with Oxide's well-regarded reference implementation. **The cost is accepted
because it is not a preference — it is an incompatibility.** progenitor cannot read an OpenAPI 3.1
document in any mode (`progenitor-impl-0.15.0/src/lib.rs:702-709`), and the document this template
will commit is 3.1 under every plausible R71 outcome; and even on a 3.0 document its CLI needs a
nightly rustfmt, which its own maintainers document in `oxide.rs`'s `xtask`.

**Against `openapi-to-rust`.** We give up a pure-Rust pipeline and accept a **JVM as an on-demand
contributor prerequisite** — `brew install openapi-generator` pulls `openjdk`; the jar is 30 MB and
a Temurin 21 JDK unpacks to 336 MB here. **The cost is accepted because** the tool is 8 years old,
26,752 stars, releasing monthly, distributed through four independent channels, and demonstrably
produces crates that real, widely-used projects publish (LanceDB, Langfuse); and because it is
**never required**: it is not a CI dependency, not a hook dependency, and not needed to build, test
or release the template. A contributor who never runs `just client-rust` never needs Java.

**Against the owner reference's committed, drift-gated client (architecture B).** We give up an
early-warning signal that the snapshot and client have diverged. **The cost is accepted because**
nothing in this template consumes the generated client, so the signal would guard an artifact no
build depends on, and py — the source of the principle — deliberately does not have it. The
determinism probe means adopting it later is a one-job change, not a redesign.

**Limitations recorded, not decided.** The generated `Cargo.toml` declares `edition = "2021"` and no
`rust-version`, and uses caret dependency requirements. `rust-edition = 2024` binds workspace
*members*, and this is not one, so nothing is violated; but if a future owner decision publishes this
client (R68's territory, not reached by an unpublished artifact), a fix-up step would be needed and
that would be a new decision. The generator also emits `.travis.yml`, `git_push.sh` and a `.gitignore`
by default; pre-seeding `.openapi-generator-ignore` with those three names suppresses all of them
(executed: 11 files instead of 14). Because the output is uncommitted, this is cosmetic.

### Parameters

This item **owns no parameter** (`research/CLAUDE.md`, R84 row, `owns` empty; the prompt's
`## Couplings` likewise lists `owns:` with no value).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

  **Prose note beside the line above, per the run's binding instruction.** The bytes above are the
  **live registry row** (`docs/port/PARAMETERS.md`), which still carries R69 **revision 9**'s form.
  R69 **revision 10** — owner-accepted but unpublished (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`,
  owner rulings `W1-R02` and `W0-R69c`) — moves the web tree from `src/web/` to the optional workspace
  member `crates/web/`, with the feature reading `web = ["dep:rs-launch-blueprint-web"]` and `axum`
  and `tokio` declared non-optionally inside `crates/web/Cargo.toml`. **Nothing in this
  recommendation depends on which form is live**: R84 adds no module, dependency, feature or binary
  to that surface and only consumes the snapshot the member produces. **R69's republication is a
  re-verify trigger** for this line and is recorded as such below. **No `CONFLICT:` is raised against
  R69** — the recommendation needs no change to R69's owned value.

- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component

`build-tool-output-shape` and `package-manager-invocation` are not declared in this prompt's
`## Couplings`, and are listed because the recommendation genuinely consumes them: R49's "no build.rs"
clause eliminates an entire architecture, and R42's rule fixes the recipe's invocation form and its
presence test. Both are quoted byte-identically from the live registry.

**`CONFLICT:` lines: none.** No consumed value needs to change for this recommendation to hold.
`[workspace] exclude = ["clients"]` is a workspace-table key, not a `[package]` target or packaged-file
declaration, so it falls outside R49's owned string; and it adds no member, so it falls outside R02's
four-package topology and does not reach R02's promotion rule. It is recorded below as a hand-off to
P03 and to whichever item owns the root manifest's workspace table, not as a conflict.

**Couplings stated, not decided.** R71 (`openapi-generation-pipeline`): requirements N1–N4 above.
R83 (`openapi-contract-fuzzing`): consumes the same document and therefore shares N1, N2 and N4
verbatim; nothing in this recommendation constrains its tool choice. R11
(`ci-workflow-job-structure`): **this recommendation requests no job slot** — the recipe is
contributor-invoked, exactly as py's is. R20 (action pinning), R86 and R18 (CI workflow shape and
pinning) are consequently unconsumed. R68 (release artifacts) and R04 (public API surface): neither
reaches an artifact that is not published and is not part of the facade's surface; the generated
crate is neither `cargo publish`ed nor re-exported from `src/lib.rs`, so R04's private-module barrel,
its three `deny` lints and its `cargo-semver-checks` gate do not apply to it.

### Migration implications

The template is not yet written, so "migration" here is the file-level delta this decision adds to
what other items already specify.

| File | Change | Owner |
|---|---|---|
| `Justfile` | **One new recipe**, `client-rust`, in `[group('build')]`, exactly as quoted under `### Recommendation`. py's analogue is `Justfile:311-312` | R84 |
| `.gitignore` | **One new line**, `/clients/`. Note that py does *not* ignore its `clients/` output; adding the line is a small, deliberate improvement over the baseline, because a Rust `clients/rust/target/` directory is far bulkier than a Python package tree and an accidental `git add -A` is a realistic failure | R84 |
| Root `Cargo.toml`, `[workspace]` table | **One new key**, `exclude = ["clients"]`. Required — without it `cargo` commands run inside the generated crate fail with `error: current package believes it's in a workspace when it's not`. Hand-off: the item that owns the root manifest's workspace table (R02's topology, realized in P03) | hand-off |
| `docs/` — the web-conventions document and the example walkthrough | **Two documentation lines**, the analogues of py's `docs/design/0002-web-api-conventions.md:86` and `EXAMPLEWEB.md:138`: "typed clients are generated, never hand-written — run `just client-rust`" | R84 |
| The dev-toolchain document R42 produces | **One optional, on-demand tool**: `openapi-generator` 7.25.0 (Homebrew formula `openapi-generator`, which pulls `openjdk`), explicitly marked *not required for build, test, hooks or CI*, with `command -v openapi-generator` as its presence test | hand-off to R42's document |
| R71's snapshot | Must carry an `operationId` on every operation and an `info.license` object — requirements N2 and N3 | hand-off to R71 |

**Not created by this item:** no workspace member, no Cargo dependency, no Cargo feature, no
`build.rs`, no GitHub Actions job, no pinned action, no published artifact, no source file under
`src/` or `crates/`.

### Validation strategy

**Executed in this run** (macOS 15 / darwin arm64; `rustc 1.98.0`; `cargo-progenitor 0.15.0` and
`openapi-to-rust 0.17.0` installed with `cargo install --locked` into a `$TMPDIR` root; OpenAPI
Generator 7.25.0 jar `sha256 41ce4f6b07f196676439d710759fa1ced7a08066d06ff1bf314681470289efae` from
Maven Central, run on Temurin 21.0.12.1+1 downloaded to `$TMPDIR`):

| # | Command | Expected | Observed |
|---|---|---|---|
| E1 | `java -jar openapi-generator-cli-7.25.0.jar generate -i api-3.1.json -g rust -o out --additional-properties=…supportAsync=false,library=reqwest… --global-property=apiDocs=false,…` | A complete Cargo package | `exit=0`; 11 files; `WARN … OpenAPI 3.1 support is still in beta` |
| E2 | `grep "^pub fn" out/src/apis/projects_api.rs` | Names derived from the curated ids | `pub fn projects_get_project(…)`, `pub fn projects_list_projects(…)` |
| E3 | Same, on the document with `operationId` removed from `GET /v1/projects` | A reported, path-derived fallback | `WARN … Empty operationId found for path: get /v1/projects. Renamed to auto-generated operationId: v1ProjectsGet`; `pub fn v1_projects_get(…)` |
| E4 | `cargo build --no-default-features --features rustls` in the generated crate, on stable | Builds clean | `Finished dev profile … in 28.03s`, `exit=0` |
| E5 | `rustup run 1.96.0 cargo build --no-default-features --features rustls` (the `msrv-policy` floor for stable 1.98.0) | Builds clean at the floor | `Finished dev profile … in 38.23s`, `exit=0` |
| E6 | `cargo tree --no-default-features --features rustls -e normal` in the generated crate | A large tree containing `tokio`, confirming it must stay out of the workspace | 236 lines; `cargo tree -i tokio` shows `tokio v1.53.1 ← hyper ← hyper-rustls ← reqwest ← rslbp-client` |
| E7 | Generate twice into two directories, `diff -r` | Byte-identical | `DETERMINISTIC: identical`, `exit=0` |
| E8 | Generate with `info.license = "MIT OR Apache-2.0"` in the document | `license =` in the generated manifest | `license = "MIT OR Apache-2.0"` (default without it: `license = "Unlicense"`) |
| E9 | `cargo progenitor -i api-3.1.json …` | — | `exit=1`; `gen fail: UnexpectedFormat("invalid version: 3.1.0")` |
| E10 | `cargo progenitor -i api-3.0.json …` on a stable toolchain | — | `exit=101`; `panicked at cargo-progenitor-0.15.0/src/main.rs:95:68: called Result::unwrap() on an Err value: Unstable("wrap_comments, normalize_doc_attributes")`; only `Cargo.toml` written |
| E11 | `cargo progenitor -i api-3.0-noopid.json …` | — | `exit=1`; `gen fail: UnexpectedFormat("path /v1/projects is missing operation ID")` |
| E12 | `cargo check` inside a nested generated crate under a workspace root, without and with `exclude = ["clients"]` | Fails, then succeeds | `error: current package believes it's in a workspace when it's not` → after adding `exclude`, `Finished dev profile … in 13.68s` |
| E13 | Pre-seed `.openapi-generator-ignore` with `.travis.yml`, `git_push.sh`, `.gitignore`, regenerate | Those three suppressed | 11 files, none of the three present |
| E14 | `openapi-to-rust generate api-3.1.json --output-dir out --module-name rslbp_client` | Module tree + dependency fragment | `exit=0`; `mod.rs`, `client.rs`, `types.rs`, `REQUIRED_DEPS.toml`; `pub async fn projects_list_projects(…)` |

**Planned for P03, not run here** (stated as proposals, per the prompt's requirement to distinguish):

| # | Planned command | Expected |
|---|---|---|
| P1 | `just client-rust && cargo build --manifest-path clients/rust/Cargo.toml` on `ubuntu-latest` | Exit `0`; this closes the Linux half of gate 4, which was not executed in this run |
| P2 | `cargo tree -i tokio -e normal` on the root package with default features, after this recipe exists | No output — R05's criterion 1 unchanged at 38 crates, because this decision adds no member |
| P3 | `cargo metadata --no-deps` asserted by R02's `tests/workspace_edges.rs` after `just client-rust` has run | The same four-member edge set; the generated package is absent |
| P4 | `just client-rust` twice, `diff -r` the two outputs against R71's real snapshot | Byte-identical, as in E7 on the synthetic document |
| P5 | A doc example in the generated client's `README.md` calling `projects_list_projects` against the template's own `serve` binary | A `Page<Project>` round trip, proving the served contract is machine-consumable end to end |

### Confidence & re-verify trigger

**Confidence: high on the exclusions, high on the shape, moderate on the pick's long-run fit.**

- *The exclusion of progenitor* is as strong as this kind of evidence gets: a version check in the
  maintainers' released source with its own unit test, an executed failure reproducing that test's
  exact message, a second executed failure on a stable toolchain, and the maintainers' own reference
  repository documenting the nightly requirement in a ten-line comment. Four independent confirmations.
- *The architecture* (out-of-workspace, uncommitted, one recipe, no CI job) follows from a fact about
  the source repository I verified four ways at the pin, and from three published or owner-accepted
  decisions (R49's no-`build.rs`, R05's sync model, R02's promotion rule).
- *The pick itself* carries one honest reservation: OpenAPI Generator calls its own OpenAPI 3.1
  support beta, and my probe exercised three operations and four schemas, not 3.1's harder corners
  (nullable type unions, `const`, JSON-Schema-2020-12 `$ref` siblings). That reservation is why the
  runner-up analysis is written as a live branch rather than a formality.

**re-verify:** when **R71** publishes and its snapshot's `openapi:` version, `operationId` coverage,
`info.license` and committed path are known (requirements N1–N4); when **R69** republishes the
`web-extra-surface` registry row at revision 10, which re-reads the `- assumes` line above; when
**R02** publishes and its four-package topology or promotion rule moves; when
`GET https://crates.io/api/v1/crates/progenitor/versions` shows a newest non-yanked `num` above
`0.15.0` **whose `progenitor-impl` `validate_openapi_spec_version` accepts `3.1.`** — the single
change that would reopen the Rust-native branch and very likely reverse this recommendation; when
`https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/maven-metadata.xml` shows a
release in which the `rust` generator's page drops the "(beta)" from its `helpTxt` or the 3.1 beta
warning disappears; when `GET https://crates.io/api/v1/crates/openapi-to-rust` shows a `1.0` release
together with a located production adopter, which would make a pure-Rust pipeline defensible; when
`https://rustsec.org/packages/reqwest.html` returns **200** while the `atty` control still returns
200; when the owner scopes an **in-repo Rust consumer** of the generated client, which flips
architecture A to B and requests a job slot from R11; or by **2027-03-18**, whichever comes first.

### Sources

**Source repositories, read at their pins.**
- `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read with
  `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`: `Justfile:295-313`;
  `docs/design/0002-web-api-conventions.md:76-86`; `EXAMPLEWEB.md:129-138`;
  `docs/api/openapi.json` (`openapi: 3.1.0`; operation ids `ops-healthz`, `ops-readyz`,
  `projects-list_projects`, `projects-get_project`); `.gitignore`;
  `git ls-tree -r --name-only b08bccfb`; `git grep -n "client-python\|openapi-python-client" b08bccfb --`.
- `ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — no web service, no analogue (F303).

**This repository.** `docs/port/COMMONALITY.md:307,311,316,336-339` (F303, F307, F312, F332–F335);
`docs/port/README.md` (verdict vocabulary; the `BASELINE-REVIEW` scope);
`docs/port/PARAMETERS.md` (all `- assumes` lines, quoted byte-identically);
`docs/port/OWNER-REVIEW.md:46-70` (the 2026-09-12 Q7.B licence ruling and its carve-outs);
`docs/planning/p02/owner-decisions.md` section 11 (the owner reference's standing-input ruling; the
strict MSRV-gate reading); `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`
lines 32, 50, 51, 89, 90, 426 (the four rows dispositioned above);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791,2398-2399`;
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:186,283` and its Decision table;
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (sync core, `ureq` 3.4.2,
criterion 1, the 38-crate default tree);
`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` (release channels);
`research/topics/49-build-target-declaration/DECISION.md:691,1059` (the "no build.rs" clause);
`research/topics/04-public-api-surface-enforcement/DECISION.md` (the barrel and semver gate);
`research/CLAUDE.md` (the R84 row). All read 2026-09-18.

**Registry and repository endpoints, all retrieved 2026-09-18.**
`GET https://crates.io/api/v1/crates/{progenitor,progenitor-client,progenitor-impl,cargo-progenitor,openapiv3,oas3,paperclip,openapi-to-rust,spargen,ploidy,openapi-nexus,openapi-model-generator,openapi-generator-cli,utoipa,datadog-api-client,lance-namespace-reqwest-client,oxide-api,kittycad,langfuse-client-base}`;
`GET https://crates.io/api/v1/crates/{progenitor,progenitor-client,paperclip,oas3,openapi-to-rust}/versions`;
`GET https://crates.io/api/v1/crates?q=…` for four term sets.
`GET https://api.github.com/repos/{oxidecomputer/progenitor,OpenAPITools/openapi-generator,gpu-cli/openapi-to-rust,getkono/spargen,linabutler/ploidy,paperclip-rs/paperclip}`;
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the same six;
`GET https://api.github.com/search/issues?q=repo:OpenAPITools/openapi-generator+is:issue+is:open+label:"Client: Rust"` → 15;
`GET https://api.github.com/search/issues?q=repo:oxidecomputer/progenitor+is:issue+3.1+in:title` → 0;
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc&per_page=10` and
`GET https://api.github.com/repos/<o>/<r>/issues/<n>/comments?per_page=3` for the responsiveness sample;
`GET https://api.github.com/repos/oxidecomputer/oxide.rs/contents`.
`https://rustsec.org/packages/{progenitor,progenitor-client,reqwest}.html` → 404, with controls
`https://rustsec.org/packages/{time,openssl,atty}.html` → 200.
`https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/maven-metadata.xml` and
`HEAD …/7.25.0/openapi-generator-cli-7.25.0.jar`, `…/7.24.0/…jar` (`last-modified`).
`https://formulae.brew.sh/api/formula/openapi-generator.json`.
`https://openapi-generator.tech/docs/generators/rust/`.
`https://doc.rust-lang.org/cargo/commands/index.html`.

**Maintainers' published source, read at the artifact.**
`https://static.crates.io/crates/progenitor-impl/progenitor-impl-0.15.0.crate` → `src/lib.rs:702-709`
and `:790-798`; `https://static.crates.io/crates/utoipa/utoipa-5.5.0.crate` → `src/openapi.rs:378-425`;
`~/.cargo/registry/src/index.crates.io-…/cargo-progenitor-0.15.0/src/main.rs:88-95` and its
`Cargo.toml:79-81` (`rustfmt-wrapper 0.2.1`);
`https://raw.githubusercontent.com/oxidecomputer/oxide.rs/main/{xtask/src/main.rs,xtask/Cargo.toml,sdk/Cargo.toml,rust-toolchain.toml}`;
`https://raw.githubusercontent.com/lancedb/lance-namespace/main/rust/lance-namespace-reqwest-client/Cargo.toml`;
`https://raw.githubusercontent.com/genai-rs/langfuse-client-base/main/scripts/generate-openapi-client.sh`;
`https://raw.githubusercontent.com/DataDog/datadog-api-client-rust/master/README.md`;
`https://raw.githubusercontent.com/paperclip-rs/paperclip/master/README.md`.

**Method notes.** Figures came from the endpoints the prompt's table names — crates.io
`/api/v1/crates/<name>` for `recent_downloads` and `downloads`, `/versions` for the newest
non-yanked `num`, `created_at`, `license`, `rust_version` and `edition`; GitHub
`/repos/<o>/<r>` for `stargazers_count`, `archived` and `pushed_at`; GitHub `/search/issues` for
`total_count`, never `open_issues_count`; `rustsec.org/packages/<name>.html` for advisories, with
three known-advisory controls run to establish that a 404 means "no advisory page" rather than a
transport failure. Because OpenAPI Generator is a Java artifact, its release figures come from Maven
Central's `maven-metadata.xml` and the jar's `last-modified` header, and its download counts are
recorded as `inapplicable` with the reason stated in the shortlist table rather than omitted. GitHub
calls were spaced at least 21 s apart throughout.

**What I could not verify, stated plainly.** (1) **Linux execution.** Every probe ran on macOS 15 /
darwin arm64. The generated crate was not built on `ubuntu-latest`; gate 4's Linux half rests on the
jar being platform-independent and on the Homebrew formula's `openjdk` dependency, and is carried to
P03 as check P1. (2) **Issue responsiveness is a partial sample** — 6 of 10 issues for OpenAPI
Generator and 4 of 10 for progenitor — because a per-issue first-response measurement costs one API
call and the polling budget is one call per 20 s. I report the sampled counts and a median over the
answered members of the sample, and deliberately do not extrapolate a ten-issue median. (3) **Runner
images' bundled Java.** I did not verify whether `ubuntu-latest` and `macos-latest` ship a JDK; the
path I found to the `actions/runner-images` READMEs 404s at `raw.githubusercontent.com` and the
directory listing shows versioned filenames I did not then fetch within budget. **This does not
affect the recommendation**, because the recipe is never invoked in CI. (4) **`openapi-to-rust`'s CI
platform coverage** was not inspected; its gate-4 row records only what I executed. (5) **No
adopter** of `openapi-to-rust`, `spargen`, `ploidy` or `openapi-nexus` was located, and I record that
as an absence of evidence rather than as evidence of absence. (6) **Datadog's exact generator** is
described by its own README as "internal tooling"; I cite it as evidence of the OpenAPI-driven
practice, not as an OpenAPI Generator adopter. (7) The scratch tree, the downloaded JDK and jar, and
the two installed Rust binaries lived only under a `$TMPDIR` subdirectory created and removed by this
run; nothing was written outside the one report file this task names.
