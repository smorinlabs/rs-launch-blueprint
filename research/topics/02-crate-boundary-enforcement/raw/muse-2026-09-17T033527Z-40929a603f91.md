# R02 crate-boundary-enforcement — raw research report (Muse engine)

Engine: `muse-spark`, actor `research-muse-2026-09-17T033527Z-40929a603f91` (operation request `28862c836e8643e2b6fa949bb4b18965`, provider `muse`). Item kind: `bundle`. Tier: Deep. Retrieval date for every live figure below: **2026-09-26** (UTC).
Local toolchain for every executed check: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1`, `clippy 0.1.98`, `cargo-deny 0.20.2` (installed into a throwaway `CARGO_HOME` for this run), macOS (`darwin`) arm64. Executed checks ran in a throwaway workspace under `/tmp/r02muse` (retained for review; no template code exists and none was scaffolded).

**Fitness gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`.** Licence compatibility is not evaluated for any dependency or tool, and nothing below is admitted, ranked, preferred or excluded on a licence. Declared licences are still reported as recorded facts, because the figure table asks for the crates.io field. Ruling recorded at `docs/port/OWNER-REVIEW.md:47-62`.

### Landscape

**Category this item decides.** Not "which linter" but *what the boundary is physically attached to*. Python has no compile-time module direction, so py's boundary is whatever a graph checker declares it to be. Rust's compilation unit is the crate, and a crate can only name crates listed in its own `Cargo.toml`. The decision is therefore: draw each architectural boundary on a compiler-enforced crate edge, or on a module convention the compiler ignores — and, for the manifest that declares those edges, what tool (if any) asserts the intended set.

**Three-bin map of the Rust field.** Every shortlisted candidate comes from bins 1–2.

- Bin 1 — built-in / first-party toolchain: Cargo workspace members and `[dependencies]` edges; Cargo's cyclic-package rejection; `cargo metadata --no-deps` (the machine-readable declared edge set); `cargo tree -i`; Cargo features with `dep:` syntax and `[[bin]] required-features`; `[workspace.package]` / `[workspace.lints]` inheritance; module visibility (`pub`, `pub(crate)`, `pub(super)`, `pub(in path)`); rustc lints (`unreachable_pub`, `private_interfaces`); `clippy::disallowed_types` / `clippy::disallowed_methods` driven by a per-package `clippy.toml`. Enforces crate-to-crate direction, cycles, optional surfaces and lint policy. Does not enforce module-to-module direction inside one crate.
- Bin 2 — established industry standard: `cargo-deny` 0.20.2 (`bans.deny[].wrappers` — per-crate confinement of a banned dependency); `guppy` 0.19.1 (a `cargo metadata` graph library, the basis for a custom dependency lint); `cargo-hakari` 0.9.39; `cargo-machete` 0.9.2; `cargo-udeps` 0.1.61; `cargo-shear` 1.14.0; `cargo-modules` 0.27.0 (module-graph rendering plus a `--acyclic` failing mode). Of these, only `cargo-deny` and `guppy` act on the package graph in a way a boundary needs. The `hakari`/`machete`/`udeps`/`shear` group finds unused, duplicated or misplaced dependencies and shrinks build times — none of them expresses "crate A may not depend on crate B" and all four are named here only to be excluded from the shortlist.
- Bin 3 — up-and-comer: `cackle` 0.2.0 (per-crate API *permissions* — net, fs, process — not per-crate dependency *direction*); `cargo-bylaw` 0.1.0 (0 stars, 38 downloads, single release 2026-08-14); `LukasNiessen/ArchUnitRust` (4 stars); `oknozor/archunit_rs` (1 star, last push 2023-11-29, **not on crates.io**: `GET https://crates.io/api/v1/crates/archunit_rs` → `{"errors":[{"detail":"crate \`archunit_rs\` does not exist"}]}`); `modernizing/guarding` (75 stars, last push 2022-02-21). An intra-crate layer-contract checker — the direct `import-linter`/`tach` analogue — **does not exist in maintained form**. This is the single most decisive landscape finding.

**Authoritative sources, and why each counts.**

- The Cargo Book (*Workspaces*, *The Manifest Format*, *Cargo Targets*, *Specifying Dependencies* — `https://doc.rust-lang.org/cargo/reference/`, the Cargo team's normative reference): the root-package workspace shape ("If the `[workspace]` section is added to a `Cargo.toml` that already defines a `[package]`, the package is the root package of the workspace"); sub-package `include` skipping; `required-features` target skipping; the path-dependency publish rule ("Crates that use dependencies specified with only a `path` are not permitted on crates.io"). Each cited rule was additionally verified empirically in this run (see `### Principles and implementation`), so the recommendation does not rest on quotation alone.
- The Rust Reference, *Visibility and Privacy* (`https://doc.rust-lang.org/reference/visibility-and-privacy.html`, the language's normative reference): visibility governs who may *name* an item, never which module may depend on which — the reason F004 is inexpressible in one crate, confirmed by executed fixture A.
- `cargo-deny` maintainer documentation, `docs/src/checks/bans/cfg.md` at `main` (retrieved 2026-09-26 via `GET https://api.github.com/repos/EmbarkStudios/cargo-deny/contents/docs/src/checks/bans/cfg.md?ref=main`): `deny = [{ crate = "…", wrappers = ["this-can-use-it"] }]` — "This field allows specific crates to have a direct dependency on the banned crate but denies all transitive dependencies on it".
- `EmbarkStudios/cargo-deny` issue #891, "Support per-layer (crate-group) dependency boundaries within a workspace", state `open`, 0 comments, created 2026-08-20 (`GET https://api.github.com/repos/EmbarkStudios/cargo-deny/issues/891`, 2026-09-26): a filed, unanswered feature request against the recommended tool, direct evidence of its limit.
- `EmbarkStudios/cargo-deny` `.github/workflows/ci.yaml` at `main` (retrieved 2026-09-26 via the contents API): test matrix `os: [ubuntu-24.04, macos-14]` and an MSRV job pinning toolchain `1.88.0` — the gate-4 and gate-2 evidence for the recommended tool.
- py-launch-blueprint at the pinned revision (`docs/adr/0017-hexagonal-core-and-boundary-enforcement.md`, `pyproject.toml:318-355`, `tach.toml`, `src/py_launch_blueprint/core/ruff.toml`, `lefthook.yml:170-177`): the source precedent this port carries — every contract py declares and the tier each runs at.
- This programme's published decisions R01 (trait-port seam, blanket `Arc<T>` impl), R04 (public-surface rule), R49 (target declaration) and R69 revision 9 (web feature, still `web = ["dep:axum", "dep:tokio"]` on `src/web/`): the seam this boundary must hold and the values it must fit or conflict with.

**Well-regarded projects surveyed, with the evidence that they are well regarded** (`GET https://api.github.com/repos/<o>/<r>`, 2026-09-26; all `archived: false`, all pushed 2026-09-26):

| Project | Stars | Shape evidence (retrieved 2026-09-26) |
|---|---|---|
| `astral-sh/uv` | 90,195 | Flat multi-crate workspace (this template's layout question at scale) |
| `astral-sh/ruff` | 49,800 | Flat multi-crate workspace |
| `jj-vcs/jj` | 31,758 | Root `Cargo.toml` `[workspace] members = ["cli", "core", "core/proc-macros", "lib", "lib/gen-protos", "lib/testutils"]` (verified via contents API) — a CLI package separate from its library package, this template's exact question; already R01's reference |
| `rust-lang/rust-analyzer` | 16,875 | Flat `crates/` workspace; its crate graph is its layering |
| `rust-lang/crates.io` | 3,703 | Multi-crate workspace; R01 calls it the closest shape match (web service + library crates) |
| `MystenLabs/walrus` | 427 | `deny.toml:91-93` uses `wrappers` in production to confine dependencies to one member: `{ name = "ssh2", wrappers = ["walrus-orchestrator"] }` (verified via contents API) |

**Fit over abstract best.** The template is one small capability behind one port, one production adapter, one CLI, one optional web surface, published as one installable command. Every judgement below is against that, not against a monorepo.

### Principles and implementation

**Shared requirement.** Architectural boundaries are *enforced by a machine, not by review*: the composition root is reachable only from front ends and never from the core (F003); the core never depends on a front end (F004); front ends never depend on each other (F005); the core's own layers stay ordered (F006); no CLI or web framework enters the core, guarded both authoritatively and in a fast local tier (F008, F009); the permitted edges are *declared in one readable artifact* (F010); the check runs at a defined place in the hook and CI pipeline (F116).

**Source and agreement level.** `docs/port/DIVERGENCE-ANALYSIS.md:77,241` puts F003–F010 and F116 in one item-level bucket, cause class **C** ("no recorded reason for any row"), `harmonize: partly`; F020 is class C with `harmonize: no`; F021 is class **G** ("no precedent either side"), `harmonize: no`. py's ADR-0017 states the principle in the source's own words: "**enforce the boundaries mechanically** rather than by convention". ts has none of it: "ts's flat `src/` with one front-end and no core/front-end split leaves nothing for these tools to check (consequence of F001)".

| Rows | What must agree | What may vary |
|---|---|---|
| F007, F003, F004, F005, F008 | **Policy + capability**: a violation fails a build or a check, in every repo with a core/front-end split | The mechanism entirely |
| F006, F009, F010, F116 | **Capability**: internal layering is constrained; a fast tier exists; permitted edges are declared; the check has a defined tier | Mechanism, granularity and tier — they follow from how fast the ecosystem's authoritative check is |
| F020 | Nothing above "the public name is unambiguous" | Everything: Python needs an importable package directory, Rust namespaces by `Cargo.toml` `name` |
| F021 | — | Rust-only; no agreement to preserve |

No shared low-level value is recommended: no owner requirement asks for one, and the evidence does not support the same tradeoff in all three ecosystems. Python's checker exists because the language has no compile-time module direction; Rust's compiler makes the same guarantee stronger and free — at *crate* granularity only.

**Executed result 1 — a single crate cannot enforce F004.** A one-package crate with `pub mod core_layer;` and `pub(crate) mod cli_layer;`, where `core_layer.rs` contains `use crate::cli_layer::CliThing;` — core reaching upward into the front-end layer, exactly what F004 forbids — **compiles clean** (`Finished dev profile in 0.31s`). Visibility is about who may *name* an item, and `pub(crate)` grants naming rights to the whole crate including the module that must not have them. Module visibility is not a weaker boundary; for this requirement it points the wrong way.

**Executed result 2 — the crate edge enforces F003, F004 and F005 as build errors.** A root-package workspace (`[package] rs-launch-blueprint` + `[workspace] members = ["crates/*"]`, members `rs-launch-blueprint-core`, `-cli`, `-web`, facade holding `pub mod composition`):

| Case | Violation introduced | Observed |
|---|---|---|
| C1 (F004) | `crates/core/src/lib.rs` calls `rs_launch_blueprint_cli::run()` | `error[E0433]: cannot find module or crate rs_launch_blueprint_cli in this scope` |
| C2 (F004, manifest tier) | `crates/core/Cargo.toml` adds the cli path dependency | `error: cyclic package dependency: package rs-launch-blueprint-cli … depends on itself. Cycle:` — Cargo refuses before rustc runs |
| C3 (F005) | `crates/cli/src/lib.rs` calls `rs_launch_blueprint_web::router()` | `error[E0433]` |
| C4 (F003) | `crates/core/src/lib.rs` calls `rs_launch_blueprint::composition::production_service()` | `error[E0433]` |
| C5 | baseline restored | `Finished dev profile in 0.12s` |

For a boundary between two crates that already have an edge in one direction, the reverse edge is not merely discouraged — Cargo rejects it as a cycle, so F004/F005 are self-enforcing for every pair on the spine. The one direction Cargo accepts is a *new* edge that closes no cycle, which is exactly what the manifest guard covers.

**Executed result 3 — `[workspace.lints]` carries R04's lint policy to every member from one place.** With `[workspace.lints.rust] unreachable_pub = "deny"` at the root and `[lints] workspace = true` in each member, a `pub struct Leaked;` inside a private module of `crates/core` produced `error: unreachable pub item`. The split costs R04 nothing: three `deny` attributes become three workspace-inherited lines.

**Executed result 4 — py's subtree-scoped fast mirror has no sub-package analogue; the package is the finest granularity.** A `clippy.toml` at the single-crate package root banning `std::collections::HashMap` (stand-in for a framework type) flagged **both** layers (4 diagnostics across `core_layer.rs` and `cli_layer.rs`). The same file at `src/clippy.toml` (py's nested shape) was **ignored** (0 diagnostics). A `clippy.toml` at `crates/core/clippy.toml` in the workspace, with `cargo clippy --workspace`, flagged **only** `crates/core/src/lib.rs` (2 warnings) and left the identical `HashMap` use in `crates/cli` untouched. F009's capability exists in Rust at package granularity and nowhere else — a second, independent reason for the split. Note: `disallowed_types` is warn-by-default, so the gate must run clippy with `-D warnings` or a workspace lint table.

**Executed result 5 — the declared dependency graph (F010) is already a first-party artifact.** `cargo metadata --offline --format-version 1 --no-deps`, `real 0.05s`, emitted the complete intra-workspace edge set including optionality:

```
rs-launch-blueprint      -> ['rs-launch-blueprint-cli', 'rs-launch-blueprint-core', 'rs-launch-blueprint-web[opt]']
rs-launch-blueprint-cli  -> ['rs-launch-blueprint-core']
rs-launch-blueprint-core -> []
rs-launch-blueprint-web  -> ['rs-launch-blueprint-core']
```

That is `tach.toml`'s module table, generated rather than hand-maintained. What Cargo does not give is the assertion that this set is the *intended* one — the one job left for a checked-in test.

**Executed result 6 — `cargo-deny check bans` with `wrappers` fails exactly the forbidden edge.** With `deny = [{ crate = "itoa", wrappers = ["rs-launch-blueprint-cli"] }]` (`itoa` standing in for a framework crate): clean tree → `bans ok`, exit 0; wrapper member depending on `itoa` → `bans ok`, exit 0; non-wrapper `core` depending on `itoa` → `warning[unmatched-wrapper]: direct parent 'rs-launch-blueprint-core = 0.1.0' of banned crate 'itoa = 1.0.18' was not marked as a wrapper`, `bans FAILED`, exit 2. The check is offline-capable (`--offline` used throughout) and names the violating parent, not just the banned crate.

**Executed result 7 — `required-features` keeps the optional surface out of the default build.** Default `cargo build` compiled three packages and produced only `target/debug/rslbp`; `--features web` additionally compiled `rs-launch-blueprint-web` and produced `target/debug/rslbp-serve`. The serve binary is silently skipped by default, matching the Cargo Book's `required-features` wording.

**Architectural alternatives compared, before any tool was weighed.**

| Alternative | Shape | Verdict |
|---|---|---|
| A. Single package, module visibility + review | `src/core/`, `src/cli/`, `src/web/` with `pub(crate)` | **Rejected.** Executed result 1: the violating code compiles. Fails F007 outright with F003–F006; F009 cannot be scoped to core. The ts position |
| B. Single package + intra-crate layer linter (the literal `import-linter` port) | A tool failing on a forbidden module edge | **Rejected for absence of a candidate.** `cargo-modules` 0.27.0 renders graphs but its only failing mode is `--acyclic`, and a cycle check is not a direction check (`core → cli` with no back-edge is acyclic and forbidden). The ArchUnit ports sit at 75/4/1/0 stars with last pushes 2022-02-21, 2026-09-20, 2023-11-29, 2026-08-14. A template gate cannot rest on any of them |
| C. Single package + `cargo-deny` on the external graph only | One crate, ban `axum`/`clap` nowhere in particular | **Rejected.** `bans` acts on packages; with one package there is no member to confine a framework to. "This workspace may not use `axum`" is false — the web surface must |
| D. Multi-crate workspace, virtual manifest (jj's shape) | Binaries live in `crates/cli` | **Rejected on R49 compatibility; ranked second.** Sound enforcement, but the published package stops being the repository root, so R49's `include` allow-list and `[[bin]]` paths move, and R69's `required-features` would have to move to whichever package declares the feature |
| E. Multi-crate workspace with a root package | `[package] rs-launch-blueprint` + `[workspace] members = ["crates/*"]`; facade holds `[lib]`, both `[[bin]]`s, the composition root, the production adapter and the `web` feature | **Chosen.** Results 2–7. The Cargo Book names this exact shape. Every R49 field stays byte-identical and every R69 field lands on the package that declares the feature |

**Why the chosen design preserves each row.** F003: `composition` is a module of the facade `[lib]`; no member depends on the facade (`cargo check`, C4). F004: `crates/core/Cargo.toml` names no front end; the reverse edge is a Cargo cycle (C1, C2). F005: `cli`/`web` name only `core` (C3). F006: the production adapter moves *out* of `core` into the facade, so adapters-above-services becomes a crate edge; models-below-services inside `core` stays module discipline plus R04's root barrel — **the one row the split does not fully compile-enforce** (see `BASELINE-REVIEW: F006`). F007: every row above fails a build. F008: `cargo deny check bans` with `wrappers` guards the manifest, the only remaining path for a framework into `core` (result 6). F009: `crates/core/clippy.toml` plus `cargo check` itself, which already rejects `use axum::…` in `core` with E0432. F010: member manifests are the declaration; a `cargo metadata --no-deps` assertion test pins the intended set. F020: the package name *is* the namespace; flat `crates/<name>/src/`. F021: this decision.

**Minimal realistic example.** Five directories, four packages: root `Cargo.toml` (`[package] rs-launch-blueprint` + `[workspace]`, `[lib]`, `[[bin]] rslbp`, `[[bin]] rslbp-serve` with `required-features = ["web"]`, `[features] web = ["dep:rs-launch-blueprint-web"]`); `crates/core/` (domain types, port trait, service, in-memory adapter — no `clap`, `axum`, `tokio`); `crates/cli/` (parsing + rendering over core's types); `crates/web/` (optional: state, router, handlers); `deny.toml` (`[bans]` with `wrappers`); `crates/core/clippy.toml` (disallowed framework types); `tests/workspace_edges.rs` (pins the metadata edge set). The production HTTP adapter lives in the facade `[lib]` beside `composition`: F006's adapters-above-services becomes a crate edge, the HTTP client stays out of `core`'s tree, and R01's `production_service(..)` sits next to the only type it constructs. `InMemoryProjectsPort` stays in `core` exactly as R01 requires — it has no I/O dependency.

**Reference implementations.** `jj-vcs/jj` (CLI package separate from library packages, first-class fake in `lib/testutils`) is the closest maintained match and already R01's seam reference. `rust-lang/crates.io` (web service + library crates, 29 members) is the closest shape match. `MystenLabs/walrus` (`deny.toml:91-93`) is the maintained `wrappers` example in production. `uv`, `ruff` and `rust-analyzer` corroborate the flat multi-crate layout for F020.

**Cross-repo adjudication (changes to py and ts are a follow-on project).** py is the reference realization and needs no change; its two-tier split (fast `ruff` mirror at pre-commit, authoritative `import-linter` at pre-push/CI) is the right shape where the authoritative check must build a whole import graph. ts's absence is **contingent drift, not missing capability**: with no core/front-end split the rows are vacuous rather than violated (consequence of F001, `DIVERGENCE-ANALYSIS.md:77`). It is not *justified* — no `D-0nn` records a decision — but not independently actionable either; if ts ever grows a second front end, its realizations are `eslint-plugin-boundaries` / `dependency-cruiser` on py's tool-based tier, since `tsc` supplies no crate-equivalent. rs preserves the principle at a *stronger* level than either source: py and ts enforce with a checker a contributor can skip, while Rust's enforcement is the build itself — a justified ecosystem difference needing no harmonization. The one value worth naming across all three is the **declared-graph artifact** (F010): py has `tach.toml`, rs gets `cargo metadata` plus an assertion test, ts has nothing — capability-level agreement, not a shared file format.

BASELINE-REVIEW: F006 — core internal layering is constrained by a machine, not by review — restate the row so its Rust acceptance criterion is "adapters sit above services and models on a *crate* edge; the models-below-services ordering inside the core crate is carried by module privacy and the R04 root barrel, not by a boundary tool", and record that Rust has no maintained intra-crate layer-contract checker to select; affected items: R02 (this row) and R28 (`linter-and-editor-tooling`), which must not scope an intra-crate module-graph linter into its gate — evidence: py's row rests on an `import-linter` `layers` contract over `core.adapters`/`core.services`/`core.models`; the only Rust candidates are `cargo-modules` 0.27.0, whose sole failing mode is `--acyclic` and therefore cannot express direction, and ArchUnit ports at 75, 4, 1 and 0 stars with last pushes 2022-02-21, 2026-09-20, 2023-11-29 and 2026-08-14 (`GET https://api.github.com/repos/<o>/<r>`, 2026-09-26); this run observed that a single crate cannot enforce even the simpler F004 (executed result 1).

BASELINE-REVIEW: F009 — a fast local guard mirrors the authoritative framework-bleed check — restate the row's mechanism as a per-package `clippy.toml` (`disallowed-types`, `disallowed-methods`) in the core member, backed by `cargo check` itself, and record that py's subtree-scoped configuration has no Rust analogue finer than a package; affected items: R02 (this row), R28 (`linter-and-editor-tooling`, which owns the clippy configuration surface) and R37 (`hook-manager-distribution`, which wires the tier) — evidence: py's row rests on a nested `core/ruff.toml` (`TID251`); this run observed that a `clippy.toml` at `src/clippy.toml` is ignored (0 diagnostics), a package-root one flags every layer indiscriminately (4 diagnostics across both layers), and `crates/core/clippy.toml` flags only that member (executed result 4).

**OVERRIDE (OV-nn) — multi-crate workspace instead of the single-package precedent (F021).** `docs/port/COMMONALITY.md:F021` records that the precedent is a single package with internal layering, so a multi-crate split is a §2 pattern change needing an `OV-nn` label (Phase 4 review #4). This report proposes it; the number is left as `nn` for the synthesizer to assign. Argument: the recorded precedent is a *Python* layout carrying its boundary burden in a checker, because Python has no compile-time module direction. Porting the layout without the checker ports the weakest half; porting the checker is unavailable (no maintained Rust tool enforces intra-crate layer contracts); the only mechanism making an illegal dependency a build-breaking error is the crate edge, and this run observed the single-package alternative compiling the violation clean. The split additionally supplies the only granularity at which the F009 mirror can be scoped, and costs R49/R69 nothing because the facade stays the repository-root package. Options: (1) single package + review — F003–F007 become conventions, F009 unscopable; (2) single package + intra-crate linter — unavailable; (3) multi-crate root-package workspace (recommended) — F003/F004/F005 become build errors, F009 scopable, F010 generated-plus-asserted, at the real price that **four crates.io names must be published in dependency order on every release** (path-only dependencies are not permitted on crates.io); (4) virtual-manifest workspace — same enforcement, but R49's fields move off the repository root.

**Observable acceptance criteria** (1–5, 8–9 verified in this run against a throwaway workspace; 6–7 are requirements on the template, **not** results):

1. A `use` of a front-end crate from `core` fails `cargo check` with `E0433`. *Verified, C1.*
2. Adding a front-end crate to `crates/core/Cargo.toml` fails resolution with `error: cyclic package dependency`. *Verified, C2.*
3. A `use` of the web crate from the CLI crate fails with `E0433`. *Verified, C3.*
4. A `use` of the facade's `composition` module from `core` fails with `E0433`. *Verified, C4.*
5. A banned type used in `core` fails `cargo clippy` while the same use in `cli` passes. *Verified, result 4.*
6. `cargo deny check bans` exits non-zero (observed: exit 2, `bans FAILED`) when a framework is added to any member other than its wrapper. *Verified with `itoa` as the stand-in, result 6* — the template's entries name the real frameworks R60/R69 select.
7. `cargo test` fails when the `cargo metadata --no-deps` edge set differs from the checked-in one. **Planned, not executed** — the metadata command and output shape were verified (result 5); the assertion test is P03's to write.
8. `cargo build` with default features does not compile the web member, and `--features web` does. *Verified, result 7.*
9. `[workspace.lints]` denials fire inside members. *Verified (`unreachable_pub`), result 3.*

### Recommendation

**One stack: a Cargo *root-package* workspace of four members** — `rs-launch-blueprint` (repository root; `[lib]`, `[[bin]] rslbp`, `[[bin]] rslbp-serve`, composition root, production adapter, `web` feature) plus `crates/core`, `crates/cli`, `crates/web` (optional) — **with the crate graph as the declared dependency graph, `cargo-deny` 0.20.2 `check bans` with `wrappers` as the authoritative framework-bleed guard (pre-push + CI), a per-member `crates/core/clippy.toml` plus `cargo check` as the fast local mirror (edit loop), and a `cargo metadata --no-deps` assertion test as the declared-graph pin (runs with `cargo test`).**

### Members

#### Crate topology and package namespacing (F021, F003, F004, F005, F007, F020)

Pattern member: no crate is selected, so crate figures are `inapplicable` — the member decides workspace shape, and its evidence is executed compiler behavior plus adopter layouts, reported below.

##### Landscape

The category is where the composition-root isolation, inward-only core and front-end independence boundaries physically live. Bin 1 (first-party) holds the only mechanisms that can express them: workspace members, per-crate `[dependencies]`, Cargo cycle rejection, `[workspace.lints]` inheritance, `required-features`. Bin 2 holds no topology tool — every established candidate in this item acts on an *existing* graph rather than choosing the member layout. Bin 3 holds nothing for topology. Authorities: the Cargo Book workspaces/manifest/targets pages (normative, each cited rule re-verified empirically here) and the Rust Reference visibility page (normative for why module visibility cannot substitute).

##### Principles and implementation

F003/F004/F005/F007 must agree at policy + capability level (a violation fails a build or check); F020 agrees only on "the public name is unambiguous". The compiler already implements the mechanism if the boundary sits on a crate edge: executed result 2 shows all three boundaries failing as E0433/cycle errors. The adapter-out-of-core placement additionally turns F006's top edge into a crate edge. Namespacing falls out for free: each member's `Cargo.toml` `name` is its namespace (`rs-launch-blueprint-core` → `rs_launch_blueprint_core`), with a flat `crates/<name>/src/` layout corroborated by `uv`, `ruff`, `rust-analyzer` and `crates.io`. No directory nesting (py's `src/<package>/`) is needed or wanted.

##### Dominant choice

Multi-crate workspace with a root package: `[package] rs-launch-blueprint` + `[workspace] members = ["crates/*"]`, members `crates/core`, `crates/cli`, `crates/web` (optional), facade holding `[lib]`, both `[[bin]]`s, `pub mod composition` and the production adapter. Dominant because it is the only alternative under which all three boundaries fail a build (results 1–2) while keeping every published R49 field byte-identical.

##### Qualified shortlist

Virtual-manifest workspace (jj's shape: `[workspace]` with no `[package]`, binaries in member crates). Enforcement-identical to the dominant choice; shortlisted rather than chosen because the published package stops being the repository root — R49's `include` allow-list and `[[bin]]` paths would move, and R69's `required-features` would have to move to the feature-declaring package.

##### Excluded by gate

No gate excludes a topology (gates 2–6 are crate/tool gates and this member selects no crate; gate 1 is struck programme-wide). Alternatives A (single package + review) and C (single package + deny-only) are excluded on **capability**, not on a gate: the violation compiles (result 1), and `bans` cannot confine a framework to a sub-package that does not exist.

##### Up-and-comers

None. Workspace topology is settled Cargo functionality, not an area of active tooling competition; no new candidate in this category was found.

##### Fit for this template

Exact: one capability, one port, one production adapter, one CLI, one optional web surface. Four members is the minimum that gives each boundary its own edge; fewer collapses a boundary back into unenforceable module discipline, more adds publish-order cost per release for no further guarantee.

##### Recommendation

The dominant choice: root-package workspace, `crates/core`, `crates/cli`, `crates/web` (optional), facade as described. `[workspace.package]` carries version/edition/rust-version/license; `[workspace.lints]` carries R04's denials to every member (verified, result 3).

##### Ranked runner-up

Virtual-manifest workspace. Loses only on R49/R69 fit, not on enforcement; adopt it if a later item ever requires the repository root to stop being a package.

##### Tradeoffs

Enforcement (build-breaking boundaries, scopable F009 mirror, generated F010 graph) versus publish cost (four crates.io names released in dependency order every release, since path-only dependencies cannot publish) and versus the single-package simplicity the F020 precedent suggests. The F020 precedent is Python-shaped and carries no enforcement weight in Rust.

##### Parameters

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes build-tool-output-shape = R49's published value, unchanged (root-package shape keeps every R49 field in place)

##### Migration implications

Root `Cargo.toml` gains `[workspace]`, `resolver = "3"`, `[workspace.package]`, `[workspace.lints]`, three path+version dependencies; keeps `[package]`, `[lib]`, `[[bin]] rslbp`, `autobins = false`, the `include` allow-list. New: `crates/core/`, `crates/cli/`, `crates/web/` (each `Cargo.toml` + `src/`), `src/bin/serve.rs`, `[features] web`. Not added: nested `src/rs_launch_blueprint/` directories, `publish = false` on any member.

##### Validation strategy

Executed in this run (criteria 1–4, 8–9): E0433 for C1/C3/C4, cycle error for C2, `unreachable_pub` firing via `[workspace.lints]`, serve binary skipped by default and built with `--features web`. Planned for P03: none beyond keeping these fixtures' assertions green — the template's own crates are the check.

##### Confidence & re-verify trigger

High. The enforcement claim is compiler behavior, not tool behavior, and was executed on the current stable toolchain. Re-verify if: Cargo changes cycle handling or `required-features` semantics; R01 re-decides the seam shape (topology holds either answer by design, but the member count assumption should be re-checked); R49 or R69 revise their values.

##### Sources

Cargo Book workspaces/manifest/targets/specifying-dependencies pages (`https://doc.rust-lang.org/cargo/reference/`, rules re-verified empirically 2026-09-26); Rust Reference visibility (`https://doc.rust-lang.org/reference/visibility-and-privacy.html`, confirmed by fixture A); `jj-vcs/jj` root `Cargo.toml` (verified via `GET https://api.github.com/repos/jj-vcs/jj/contents/Cargo.toml?ref=main`, 2026-09-26); R49/R69 published decisions; this run's fixtures A/B (results 1–3, 7).

#### Core internal layering (F006)

Pattern member: no crate is selected, so crate figures are `inapplicable` — the member's finding is that no selectable crate exists, and its evidence is the candidate census plus executed compiler behavior.

##### Landscape

The category is a direction check *inside* one crate (adapters above services above models). Bin 1 has nothing: rustc and clippy express no module-direction rule. Bin 2's only adjacent candidate is `cargo-modules` 0.27.0, whose sole failing mode is `--acyclic` — a cycle check, not a direction check. Bin 3 holds the ArchUnit ports (`modernizing/guarding` 75 stars, push 2022-02-21; `LukasNiessen/ArchUnitRust` 4 stars, push 2026-09-20; `oknozor/archunit_rs` 1 star, push 2023-11-29, not on crates.io; `cargo-bylaw` 0.1.0, 0 stars, 38 downloads) — all verified 2026-09-26 via `GET https://api.github.com/repos/<o>/<r>` and `GET https://crates.io/api/v1/crates/<name>`. An `import-linter layers` analogue does not exist in maintained form.

##### Principles and implementation

F006 agrees at capability level (internal layering is constrained). The split preserves the capability partially: moving the production adapter into the facade turns adapters-above-services into a crate edge the compiler enforces; models-below-services inside `core` remains module privacy plus R04's private-`mod` root barrel. This is a deliberate, recorded weakening of the mechanism (not the policy): see `BASELINE-REVIEW: F006`. Adopting an unmaintained 75-star checker to keep the letter of the mechanism would trade a documented convention for an unmaintained build gate — worse dependability for the same rows.

##### Dominant choice

Crate-edge split (adapter in facade) + module discipline inside `core` (private `mod models; mod services;` with a root barrel re-exporting only the sanctioned surface, per R04). Dominant because it is the only option whose enforced half is compiler-enforced and whose unenforced half is honestly documented.

##### Qualified shortlist

`cargo-modules 0.27.0` as a *rendering* aid (`structure`/`dependencies` views for review-time inspection, not a gate). Shortlisted because it is maintained (release 2026-08-03, `rust-version 1.95.0`, 1,267 stars, pushed 2026-09-24, no RustSec page) and useful to human reviewers; not the choice because `--acyclic` cannot express direction. Figures: `GET https://crates.io/api/v1/crates/cargo-modules` (recent 13,714, all-time 251,223) and `/versions` (newest not yanked 0.27.0, 2026-08-03), `GET https://api.github.com/repos/regexident/cargo-modules`, `https://rustsec.org/packages/cargo-modules.html` → 404, all 2026-09-26.

##### Excluded by gate

None of the layering candidates fails a fitness gate; they are excluded on **capability/dependability** instead: `guarding` (no push since 2022-02-21), `archunit_rs` (not published, 1 star, no push since 2023-11-29), `ArchUnitRust` (4 stars, no adoption evidence), `cargo-bylaw` (0 stars, 38 downloads, single 0.1.0). `cargo-modules` is not excluded — it is the shortlisted rendering aid above.

##### Up-and-comers

`cargo-bylaw` 0.1.0 and `LukasNiessen/ArchUnitRust` are the only active layer-checker experiments (both pushed August–September 2026). Neither has adoption, dependability or responsiveness evidence; watch, do not adopt.

##### Fit for this template

`core` holds a handful of modules (`models`, `ports`, `services`, `errors`, `in_memory`). A direction checker would guard a graph a reviewer can already see in one screen; the crate-edge split handles the architecturally load-bearing half (adapters above services). The template gains nothing from a gate here that it does not already get from the split plus R04.

##### Recommendation

No layering tool. Enforce adapters-above-services as a crate edge; carry models-below-services by module privacy and the R04 root barrel; optionally render `cargo modules structure` output during reviews.

##### Ranked runner-up

`cargo-modules` as a documented review aid (no gate). Loses to "no tool" only in that it adds an install without adding enforcement; wins over every ArchUnit port on maintenance alone.

##### Tradeoffs

Honest partial enforcement (compiler where possible, documented discipline where not) versus the false comfort of an unmaintained gate, or the cost of writing and maintaining a bespoke module-graph lint for a five-module crate.

##### Parameters

- assumes rust-edition = 2024
- assumes public-api-surface-shape = R04's published value, unchanged (the root barrel carries the in-crate half)

##### Migration implications

`crates/core/src/` gets `lib.rs` (private-`mod` root barrel), `models.rs`, `ports.rs`, `services/`, `errors.rs`, `in_memory.rs`; the production adapter lives in the facade (`src/adapters/`), not in `core`. No config file, no gate job.

##### Validation strategy

Executed: C2-equivalent — the adapter cannot be named from `core` because `core` does not depend on the facade (E0433, result 2 C4 shape). Planned for P03: a review checklist line (models must not `use` services) rather than a command; `cargo modules structure -p rs-launch-blueprint-core` as the optional inspection command (not executed — tool not installed in this run).

##### Confidence & re-verify trigger

Medium-high. The "no maintained checker" census is dated 2026-09-26 and could change; the compiler-enforced half is stable. Re-verify if: a layer checker reaches credible maintenance (releases, adoption, responsiveness); R04 changes the barrel rule; `core` grows past the size a reviewer can hold in one screen.

##### Sources

`GET https://crates.io/api/v1/crates/cargo-modules` and `/versions` (2026-09-26); `GET https://api.github.com/repos/regexident/cargo-modules`, `/modernizing/guarding`, `/LukasNiessen/ArchUnitRust`, `/oknozor/archunit_rs`, `/danielgerlag/cargo-bylaw` (2026-09-26); `GET https://crates.io/api/v1/crates/archunit_rs` → 404-detail (2026-09-26); `https://rustsec.org/packages/cargo-modules.html` → 404 (2026-09-26); R04 published decision; fixture A/B.

#### Declared module/crate dependency graph (F010)

Pattern member: no crate is selected, so crate figures are `inapplicable` — the declaration is the member manifests themselves (first-party artifacts), and the pin is an ordinary test. Adjacent-candidate figures (`guppy`, `cargo-hakari`) are reported under `##### Qualified shortlist` / `##### Excluded by gate` where the figure table applies.

##### Landscape

The category is the declared, checkable record of which crate may depend on which — py's `tach.toml` role. Bin 1 already supplies it: the member manifests *are* the declaration, and `cargo metadata --no-deps` renders the complete edge set with kind and optionality in 0.05s (result 5). Bin 2's adjacent candidate is `guppy` 0.19.1, a graph library over `cargo metadata` output — the foundation a custom assertion would build on if the assertion outgrows plain `serde_json`. Everything else in bin 2 (`hakari`, `machete`, `udeps`, `shear`) optimizes the graph rather than declaring it. Bin 3 holds nothing for this category.

##### Principles and implementation

F010 agrees at capability level (the permitted edges are declared in one readable artifact). The workspace improves on py's mechanism: instead of a hand-maintained `tach.toml` that can drift from reality, the manifests are simultaneously the declaration and the build input — drift is impossible by construction — and a checked-in test asserts the rendered set equals the intended literal table. `guppy` stays available as the implementation library if the assertion needs graph queries (reachability, cycle search) rather than set equality; for four members and five edges, set equality over `cargo metadata --no-deps` JSON suffices and adds no dependency.

##### Dominant choice

Member manifests as the declaration + `tests/workspace_edges.rs` asserting the `cargo metadata --no-deps` edge set (with `optional` flags) equals a literal table. Dominant because it adds zero dependencies, runs with `cargo test` at every tier, and cannot drift.

##### Qualified shortlist

`guppy 0.19.1` as the assertion-implementation library if set equality ever proves insufficient. Maintained and heavily adopted: `GET https://crates.io/api/v1/crates/guppy` → recent 3,920,876, all-time 16,796,377; `/versions` → newest not yanked 0.19.1, created 2026-09-24, `rust-version 1.91`; version detail → licence `MIT OR Apache-2.0`; `GET https://api.github.com/repos/guppy-rs/guppy` → 289 stars, `pushed_at 2026-09-26T06:09:39Z`, not archived; open issues `total_count` 14 (`GET https://api.github.com/search/issues?q=repo:guppy-rs/guppy+is:issue+is:open`); `https://rustsec.org/packages/guppy.html` → 404 (no advisories); all 2026-09-26. Adopters: `cargo-hakari` itself is built on `guppy` (its crates.io record names `https://github.com/guppy-rs/guppy` as its repository), and Nextest's author maintains the `guppy-rs` org — relevant because hakari/Nextest are workspace-graph tooling of exactly this kind. Not the choice because a four-member template does not need graph queries.

##### Excluded by gate

No gate failure in this category. `cargo-hakari` 0.9.39, `cargo-machete` 0.9.2, `cargo-udeps` 0.1.61 and `cargo-shear` 1.14.0 are excluded on **capability** (each optimizes or audits the graph; none declares or asserts permitted edges): hakari (recent 94,872, all-time 1,134,382; 0.9.39 released 2026-09-19, rust 1.91, `MIT OR Apache-2.0`); machete (recent 542,580, all-time 2,943,714; 0.9.2 released 2026-04-15, rust-version unstated, `MIT`; 1,380 stars, pushed 2026-09-07, 25 open issues); udeps (recent 133,938, all-time 1,480,303; 0.1.61 released 2026-04-29, rust-version unstated, `MIT OR Apache-2.0`; 2,136 stars); shear (recent 56,235, all-time 497,411; 1.14.0 released 2026-09-22, rust 1.95, `MIT`; 567 stars, pushed 2026-09-22); all figures `GET https://crates.io/api/v1/crates/<name>` (+`/versions`, +`/<version>` detail) and `GET https://api.github.com/repos/<o>/<r>`, 2026-09-26; all four RustSec pages → 404.

##### Up-and-comers

None for the declaration role. (`cargo-bylaw` 0.1.0 gestures at declared boundaries but has 0 stars and 38 downloads; see the F006 member.)

##### Fit for this template

Five edges, one optional. The manifests-plus-test shape is proportionate: readable in one screen, asserted in one test file, no new tool to install or pin.

##### Recommendation

The dominant choice. R49 forbids a build-orchestration crate, so the assertion is an ordinary `tests/workspace_edges.rs` in the root package using `cargo_metadata` output via a test-only JSON parse — not an `xtask` member, not a `build.rs` gate (build scripts run implicitly and their failures are obscure; a test failure names the edge).

##### Ranked runner-up

`guppy`-backed assertion. Loses only on added dependency weight for unneeded graph queries; adopt it if the member count grows to the point where reachability queries beat literal tables.

##### Tradeoffs

Zero-dependency set-equality (simple, complete for this size, brittle only if members churn weekly — they will not) versus `guppy` queries (robust to growth, one more dependency with its own MSRV 1.91 to track).

##### Parameters

- assumes rust-edition = 2024
- assumes build-tool-output-shape = R49's published value, unchanged (no `xtask` member, no `build.rs`, artifacts in workspace-root `target/`)

##### Migration implications

New file `tests/workspace_edges.rs` in the root package: runs `cargo metadata --no-deps --format-version 1`, parses `packages[].dependencies` (name + `optional`), asserts equality with the literal edge table. No new manifest dependency (the test shells out to the installed `cargo`, like the rest of the suite).

##### Validation strategy

Executed: the metadata command, its JSON shape (`packages[].dependencies` with name/optional/kind) and its 0.05s wall time (result 5). Planned, not executed: the assertion test itself — P03's to write; its red/green behavior is specified under top-level criterion 7 (temporarily add a forbidden edge, watch the test fail, revert).

##### Confidence & re-verify trigger

High for the mechanism (first-party, executed). Medium for the "no library needed" call — revisit if membership passes ~10 crates. Re-verify if: `cargo metadata --no-deps` output shape changes (`--format-version 1` guards this); R49 revises the no-orchestration-crate rule.

##### Sources

`cargo metadata` executed output (2026-09-26, cargo 1.98.1); `GET https://crates.io/api/v1/crates/guppy|cargo-hakari|cargo-machete|cargo-udeps|cargo-shear` (+`/versions`, +`/<version>`) (2026-09-26); `GET https://api.github.com/repos/guppy-rs/guppy`, `/bnjbvr/cargo-machete`, `/est31/cargo-udeps`, `/Boshen/cargo-shear` (2026-09-26); `GET https://api.github.com/search/issues?q=repo:guppy-rs/guppy+is:issue+is:open` → 14 (2026-09-26); `https://rustsec.org/packages/<name>.html` → 404 for all five (2026-09-26); R49 published decision.

#### Framework-bleed guard, authoritative (F008)

Crate member. Full crate figures below for the recommendation, the runner-up basis and every excluded candidate.

##### Landscape

The category is the authoritative check that a framework crate (CLI parser, web framework, async runtime) cannot enter `core` through the manifest — py's CI `import-linter` role. Bin 1 cannot express it: `cargo check` rejects *used-but-undeclared* crates (E0432) but accepts a *declared-but-unused* framework dependency, so the manifest needs its own guard. Bin 2 holds the only true candidate, `cargo-deny` 0.20.2 (`bans.deny[].wrappers`), plus `guppy` 0.19.1 as the build-it-yourself substrate. Bin 3 holds `cackle` 0.2.0, which answers a different question (API permissions, not dependency direction) and is stale on top of it.

##### Principles and implementation

F008 agrees at policy + capability level (framework bleed fails the authoritative check). The mechanism: `deny.toml [bans]` with one entry per framework, each naming the owning member as its `wrappers` — e.g. the web framework confined to `rs-launch-blueprint-web`, the CLI parser to `rs-launch-blueprint-cli`. Maintainer semantics ("allows specific crates to have a direct dependency on the banned crate but denies all transitive dependencies on it") were verified behaviorally: wrapper-member use passes, non-wrapper use fails with exit 2 and names the violating parent (result 6). Known limit, recorded rather than hidden: per-layer boundaries inside one workspace are a filed, open, unanswered feature request (issue #891, created 2026-08-20, 0 comments) — `wrappers` confines *which member* may touch a crate, which is exactly this template's need, but it cannot express richer per-group policies.

Fitness gates for `cargo-deny` 0.20.2, answered before popularity: (1) licence — `inapplicable` per Q7.B (recorded: `MIT OR Apache-2.0`); (2) MSRV — declared `rust-version 1.88.0`, inside stable-minus-2 (stable 1.98.1), and its CI runs an MSRV job pinned at toolchain 1.88.0 — pass; (3) advisories — RustSec page 404, none open; `unsafe` posture not audited in this run (gap recorded) — pass with gap; (4) OS — CI test matrix `os: [ubuntu-24.04, macos-14]`, covering `ubuntu-latest, macos-latest` — pass; Windows: not in the matrix (informative only, not required); (5) default features / async coupling — a standalone binary invoked as `cargo deny check bans`; no feature surface enters the template, no runtime coupling — pass; (6) binary size / compile time — contributor/CI installs a prebuilt binary or compiles once; zero cost to the template's own build — pass. Maintenance state: `active` (release 2026-07-09, push 2026-09-18, 81 open issues against 5.9M all-time downloads).

##### Dominant choice

`cargo-deny 0.20.2`, `check bans` with `wrappers`. Figures, all retrieved 2026-09-26: `GET https://crates.io/api/v1/crates/cargo-deny` → `recent_downloads` 1,716,628, `downloads` 5,942,978; `/versions` → newest not yanked 0.20.2, created 2026-07-09T17:58:09Z, `rust_version 1.88.0`; `/0.20.2` detail → licence `MIT OR Apache-2.0`; `GET https://api.github.com/repos/EmbarkStudios/cargo-deny` → 2,433 stars, `archived: false`, `pushed_at 2026-09-18T11:59:03Z`; open issues `total_count` **81** (`GET https://api.github.com/search/issues?q=repo:EmbarkStudios/cargo-deny+is:issue+is:open` — never `open_issues_count`); `https://rustsec.org/packages/cargo-deny.html` → 404. Issue responsiveness: 10 most recently opened issues (#898–#869, 2026-06-10–2026-09-16) show **zero maintainer-authored responses in the visible comment windows** — 7 with zero comments, #894 with 4 comments all `author_association: NONE`, #889 with 1 `NONE`, #878 with 1 non-member comment; median days to first maintainer response is therefore **not measurable**, unanswered-by-maintainer count 10/10 in-window (caveat: 5 of the 10 are closed, possibly fixed silently). Adopters: `MystenLabs/walrus` (`deny.toml:91-93`, `wrappers` confining `ssh2` to `walrus-orchestrator` — 427 stars, pushed 2026-09-26, a production monorepo using exactly the recommended feature); `rust-lang/crates.io` and `jj-vcs/jj` both ship a root `deny.toml` (standard furniture). Dominant because it is the only maintained tool expressing per-member confinement, with the semantics executed (not merely read) in this run.

##### Qualified shortlist

A bespoke `guppy`-based lint (a small test or CI script asserting "no path from `core` to the framework set"). Qualified because `guppy` 0.19.1 is active and heavily adopted (figures under the F010 member) and the query is genuinely expressible; not the choice because it trades a 5.9M-download tool with a declarative config for hand-maintained code the template then owns forever.

##### Excluded by gate

`cackle 0.2.0` — **fails gate 2 (MSRV)**: declared `rust-version 1.67` against a stable-minus-2 floor of ~1.96 (stable 1.98.1), and no release since 2023-09-07. It would additionally fail on capability (API permissions ≠ dependency direction) and dependability (47 downloads in 90 days). Figures: `GET https://crates.io/api/v1/crates/cackle` → recent 47, all-time 5,592; newest not yanked 0.2.0, created 2023-09-07, rust 1.67, `MIT OR Apache-2.0`; `GET https://api.github.com/repos/cackle-rs/cackle` → 287 stars, pushed 2026-08-03, not archived; RustSec 404; all 2026-09-26. Maintenance: `at-risk` — no release in 3 years with a 31-minor-stale `rust-version` is the concrete signal past the 6-month trigger. The `hakari`/`machete`/`udeps`/`shear` group is excluded on **capability**, not on a gate (figures under the F010 member): none of them expresses a forbidden edge.

##### Up-and-comers

None for the confinement role. No new per-member dependency-confinement tool was found in this category.

##### Fit for this template

Exact: the template's bleed set is tiny (CLI parser → cli member; web framework + runtime → web member; nothing → core/facade-lib), and each entry is one declarative line with a `reason`. The check is offline-capable, runs in seconds against an existing lockfile, and its failure names the violating parent crate.

##### Recommendation

`cargo-deny 0.20.2`, invoked as `cargo deny check bans` at pre-push and in CI, with `deny.toml [bans]` carrying one `wrappers` entry per framework (framework names follow R60/R69; the entries' shape is this item's). Pin the binary version in CI (e.g. `EmbarkStudios/cargo-deny@v0.20.2` action or `cargo install cargo-deny --locked --version 0.20.2`).

##### Ranked runner-up

Bespoke `guppy` lint. Loses on ownership cost (template-maintained code vs. declarative config) and on dependability breadth (one template's script vs. 5.9M downloads); wins only if issue #891's missing expressiveness ever blocks a policy this template actually needs.

##### Tradeoffs

Declarative config in a maintained external tool (failure diagnostics name the parent; semantics verified here) versus template-owned code (full expressiveness, full ownership). Plus the honest limit: `wrappers` confines *which member*, not richer group policies (issue #891) — sufficient for four members and three frameworks, recorded for the day it is not.

##### Parameters

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest (covered by deny's own CI matrix)
- assumes package-manager-invocation = R42's published value, unchanged (`cargo deny check bans` via a crates.io-installed `cargo-deny`; toolchain `cargo`)
- assumes web-extra-surface = R69's published value **with the amendment in the top-level `CONFLICT:` line** (framework crates live in `crates/web`, so the `wrappers` entries name the member, not the facade)

##### Migration implications

New file `deny.toml` at the repository root: `[bans]` with one `deny` entry per framework carrying `wrappers` + `reason`. (`[licenses]`, `[advisories]` and `[sources]` sections are R13's, not this item's.) CI installs `cargo-deny 0.20.2`; `lefthook.yml` gains a pre-push `cargo deny check bans` job.

##### Validation strategy

Executed in this run (criterion 6): clean tree → `bans ok`, exit 0; wrapper member depending on the banned stand-in → `bans ok`, exit 0; non-wrapper `core` depending on it → `warning[unmatched-wrapper]`, `bans FAILED`, exit 2 — all with `--offline`. Planned for P03: substitute the real framework names once R60/R69 land, and re-run the red/green triple against the template (add framework to `core`, watch exit 2, revert).

##### Confidence & re-verify trigger

High. The gating semantics were executed end-to-end on the recommended version, including exit codes. Re-verify if: `cargo-deny` releases a 0.21+ with changed `wrappers` semantics; issue #891 lands and offers a better expression; R60/R69 change the framework set (entries must track it); the responsiveness gap (no maintainer reply in the 10-issue window) turns into an unpatched defect affecting this use.

##### Sources

`GET https://crates.io/api/v1/crates/cargo-deny` (+`/versions`, +`/0.20.2`) (2026-09-26); `GET https://api.github.com/repos/EmbarkStudios/cargo-deny` (2026-09-26); `GET https://api.github.com/search/issues?q=repo:EmbarkStudios/cargo-deny+is:issue+is:open` → 81 (2026-09-26); 10 most-recent issues + comment windows via `GET https://api.github.com/repos/EmbarkStudios/cargo-deny/issues?…` (2026-09-26); issue #891 via `GET …/issues/891` → open, 0 comments (2026-09-26); `docs/src/checks/bans/cfg.md` and `.github/workflows/ci.yaml` at `main` via the contents API (2026-09-26); `MystenLabs/walrus` `deny.toml:91-93` via the contents API (2026-09-26); `https://rustsec.org/packages/cargo-deny.html` → 404 (2026-09-26); `GET https://crates.io/api/v1/crates/cackle` (+`/versions`, +`/0.2.0`) and `GET https://api.github.com/repos/cackle-rs/cackle` (2026-09-26); `cargo-deny 0.20.2` executed red/green/exit-code runs (2026-09-26).

#### Framework-bleed guard, fast local mirror (F009)

Pattern member: no crate is selected, so crate figures are `inapplicable` — the mirror is first-party toolchain behavior (`cargo check` + a per-member `clippy.toml`), configured not installed.

##### Landscape

The category is the fast local tier that catches framework bleed in the contributor's edit loop — py's pre-commit `ruff` TID251 role. Bin 1 supplies two layers: `cargo check` itself, which rejects `use axum::…` in a member that does not declare it (E0432 — free, instant, already in every edit loop), and `clippy::disallowed_types` / `disallowed_methods` driven by a per-package `clippy.toml`, which bans *names* (useful for transitively-available or prelude-adjacent types the manifest cannot exclude). Bin 2 and bin 3 hold nothing: every established or upcoming candidate in this item is an offline/CI-speed graph tool, not an edit-loop mirror.

##### Principles and implementation

F009 agrees at capability level (a fast tier exists). The Rust realization differs from py's in granularity, not in purpose: py scopes its mirror to a source subtree (`core/ruff.toml`); Rust scopes to a package (`crates/core/clippy.toml`) — executed result 4 shows the subtree shape is ignored (0 diagnostics) while the member shape flags only that member. The mirror therefore *requires* the multi-crate split; on a single crate it would either flag every layer or none. `cargo check` covers the common case (undeclared framework named in code); the `clippy.toml` covers the residual (declared-but-forbidden names, e.g. a framework re-exported through another dependency). Both run in seconds without network.

##### Dominant choice

`cargo check` (always, free) + `crates/core/clippy.toml` with `disallowed-types` / `disallowed-methods` naming the framework surface (kept in sync with the `deny.toml` entries by review, not by tooling). Dominant because it is the only shape that scopes to `core` without touching `cli` (executed), costs nothing beyond a config file, and runs inside the loop the contributor already uses.

##### Qualified shortlist

`cargo check` alone (no `clippy.toml`). Qualified because E0432 already rejects the realistic accident (naming a framework `core` never declared); not the choice because it cannot ban a name that *is* reachable — e.g. a framework type re-exported through a shared utility — where the disallowed-list is the only fast backstop.

##### Excluded by gate

No gate applies (no crate selected; gate 1 struck). A hypothetical "workspace-root `clippy.toml` banning frameworks everywhere" is excluded on **capability**: package-wide is its only granularity, so it would ban `clap` in the CLI too — executed result 4, first bullet.

##### Up-and-comers

None. Edit-loop lint configuration is settled clippy functionality.

##### Fit for this template

Exact: `core`'s forbidden set is three-ish framework names; one small TOML file next to the member it guards, plus the check every contributor already runs. No install, no pin, no CI minutes.

##### Recommendation

The dominant choice. Wire the gate as `cargo clippy --workspace --all-targets -- -D warnings` (warn-by-default must be escalated — observed: `#[warn(clippy::disallowed_types)] on by default`) or the equivalent `[workspace.lints.clippy]` table; R28 owns the clippy configuration surface and R37 the hook wiring, so this item recommends the tier and leaves the exact lines to them.

##### Ranked runner-up

`cargo check` alone. Loses only the re-export backstop; costs literally nothing and is already universal.

##### Tradeoffs

Two-layer mirror (covers re-exports; one config file to keep in sync with `deny.toml` by review) versus check-only (zero files, misses the re-export case). Either is strictly faster than the authoritative tier and needs no network.

##### Parameters

- assumes rust-edition = 2024
- assumes linter-config-surface = R28's published value, unchanged (R28 owns clippy configuration; this item only requires that a per-member `clippy.toml` be permitted)
- assumes web-extra-surface = R69's published value **with the amendment in the top-level `CONFLICT:` line** (the banned-name list tracks the framework set)

##### Migration implications

New file `crates/core/clippy.toml` (`disallowed-types` / `disallowed-methods` + `reason` per entry). No manifest change, no new job — the mirror rides the existing `cargo check` / `cargo clippy` invocations.

##### Validation strategy

Executed in this run (criterion 5): package-root config flags both layers (4 diagnostics), nested `src/clippy.toml` ignored (0), member config flags only `core` (2 warnings, `cli`/`web` untouched) — clippy 0.1.98. Planned for P03: substitute the real framework paths once R60/R69 land and re-run the scoping triple against the template.

##### Confidence & re-verify trigger

High for the scoping claim (executed on current stable clippy). Medium for the banned-name list, which cannot be written until R60/R69 land. Re-verify if: clippy changes `clippy.toml` discovery (nested-file behavior) or the default level of `disallowed_types`; R28 standardizes lint configuration in a way that forbids per-member files.

##### Sources

`cargo clippy --version` → `clippy 0.1.98` and executed scoping runs C1–C3 (2026-09-26); clippy lint help text emitted in-run (`rust-1.98.0/index.html#disallowed_types`); R28/R60/R69 published decisions (framework names pending).

#### Boundary-check hook and CI tier placement (F116)

Pattern member: no crate is selected, so crate figures are `inapplicable` — the member places checks in tiers, and its evidence is measured check cost plus the precedent's tier map.

##### Landscape

The category is *where* each boundary check runs: edit loop, pre-commit, pre-push, CI. Bin 1 supplies the cost facts: `cargo check` on the fixture workspace finishes in ~0.2s warm, `cargo metadata --no-deps` in 0.05s, `cargo clippy --workspace` in seconds, `cargo test` for the edges file in seconds; `cargo deny check bans --offline` against an existing lockfile likewise in seconds (all executed 2026-09-26). The precedent (py `lefthook.yml:170-177`) runs `import-linter` and `tach check` at pre-push and in CI, with the `ruff` mirror faster. No bin 2/3 candidate changes tier economics: deny needs no network with `--offline` and a warm lockfile.

##### Principles and implementation

F116 agrees at capability level (the check has a defined tier). The tier map follows from cost, mirroring py's shape: free/instant checks (`cargo check`, edges test via `cargo test`) run everywhere tests run, including pre-commit if R37 wires it; the seconds-scale authoritative check (`cargo deny check bans`) runs at pre-push (as py does) and in CI (authoritative — hooks can be skipped, CI cannot); the clippy mirror runs in the edit loop and anywhere `cargo clippy` runs. Nothing here needs a slower tier than py's: Rust's authoritative manifest check is *faster* than py's import-graph build, so pre-push (not "CI only") is affordable — and matching py's pre-push placement keeps the three repos' contributor experience aligned at the capability level.

##### Dominant choice

Authoritative `cargo deny check bans` at pre-push + CI; `tests/workspace_edges.rs` with `cargo test` (every tier tests run); clippy mirror in the edit loop / `cargo clippy` invocations. Job-versus-step layout and path filtering are R11's; hook file wiring is R37's — this item names tiers, not files.

##### Qualified shortlist

Deny check in CI only (no pre-push job). Qualified because CI is the only unskippable tier, so enforcement is preserved; not the choice because it surrenders py's fast-feedback shape for no measured reason — the offline check takes seconds.

##### Excluded by gate

No gate applies (no crate selected; gate 1 struck). A "pre-commit deny check" is excluded on **cost prudence**, not on a gate: seconds per commit with a cold lockfile fetch risk adds friction to the highest-frequency tier for feedback pre-push already gives in time.

##### Up-and-comers

None. Tier placement is a judgement over measured costs, not a tooling category.

##### Fit for this template

Four members, seconds-scale checks, one pre-push job. The map adds exactly one hook job (`cargo deny check bans`) and zero new CI jobs beyond what R11 already shapes (the check joins an existing job; the edges test is already inside `cargo test`).

##### Recommendation

The dominant choice. Pre-push `cargo deny check bans` (offline-capable; CI installs the pinned `cargo-deny 0.20.2`); edges pin inside `cargo test`; clippy mirror wherever clippy runs.

##### Ranked runner-up

CI-only deny check. Loses only contributor fast-feedback; enforcement-identical. Adopt if R37 measures pre-push friction the fixture costs do not predict.

##### Tradeoffs

Pre-push + CI (feedback before review, one hook to install/skip) versus CI-only (zero hook friction, feedback after push). Either enforces; the difference is contributor experience, where matching py's pre-push shape has cross-repo value.

##### Parameters

- assumes ci-job-structure = unresolved (R11 owns job-versus-step and path filtering; this item only requires the check run in CI)
- assumes hook-wiring = R37's scope (R37 wires the pre-push job; this item only names the tier)

##### Migration implications

`lefthook.yml`: one new pre-push job running `cargo deny check bans`. `.github/workflows/ci.yml`: the pinned `cargo-deny` install plus the check inside the job R11 shapes. No other tier file changes; the edges test and clippy mirror ride existing invocations.

##### Validation strategy

Executed: wall-time basis for every tier claim (`check` ~0.2s, `metadata` 0.05s, clippy seconds, deny offline seconds, all 2026-09-26). Planned for P03: time the real template's `cargo deny check bans` cold (no cache) and warm, and confirm pre-push latency stays in seconds; if cold runs exceed ~2 minutes, revisit the pre-push recommendation toward CI-only.

##### Confidence & re-verify trigger

Medium-high. Costs were measured on a fixture, not the template, and cold-cache deny runs were not timed (gap recorded). Re-verify if: R11/R37 measure hook/CI friction contradicting the fixture costs; the template's dependency tree makes cold deny runs slow; R11 shapes jobs such that no natural home exists.

##### Sources

Executed wall times (2026-09-26, cargo 1.98.1 / clippy 0.1.98 / cargo-deny 0.20.2, warm caches); py `lefthook.yml:170-177` (pre-push precedent); R11/R37 scopes (unresolved at this run).

### Compatibility

Proof the members are tested together. The executed fixture workspace in this run *is* the composition: the root-package layout (member 1) carried the `[workspace.lints]` table, the `crates/core/clippy.toml` scoping runs (member 5), the `deny.toml [bans]` + `wrappers` red/green/exit-code runs (member 4) and the `cargo metadata --no-deps` edge-set renders (member 3) — all against the same four members, with `required-features` gating verified on the same tree (member 6's cost basis). Shared-adopter corroboration: `jj-vcs/jj` ships the CLI-separate-from-library workspace shape; `MystenLabs/walrus` ships `wrappers` confinement in a workspace; `rust-lang/crates.io` ships both a multi-crate workspace and a root `deny.toml`. No version matrix is needed: members 1–3 and 5–6 are first-party toolchain behavior on stable 1.98.1 (no pins), and member 4 pins exactly one binary (`cargo-deny 0.20.2`, MSRV 1.88.0, inside the policy). One composition limit is recorded honestly: the `tests/workspace_edges.rs` assertion (member 3) and the real-framework `deny.toml` entries (member 4) are specified but unwritten — P03 writes them against the template, using the stand-in-verified shapes from results 5–6.

### Parameters

This item's `- owns:` line in the prompt is empty, so there are no `owns` lines.

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes license = MIT OR Apache-2.0
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes build-tool-output-shape = R49's published value, unchanged. The root-package workspace preserves it clause by clause: one `[lib]` at `src/lib.rs`; one `[[bin]]` at `src/main.rs`; `autobins = false`; `default-run` unset while one binary exists (`rslbp-serve` is feature-gated and skipped unless `web` is on — verified, result 7); no `build.rs` and no build-orchestration crate (which is why the F010 guard is an ordinary `tests/` file); artifacts in the workspace-root `target/`; and the `include` allow-list, whose paths are package-relative to the repository root and which needs no `crates/` exclusion because sub-packages are always skipped.
- assumes web-extra-surface = R69's published value **with the amendment in the `CONFLICT:` line below**. The deferral R69 left open is answered: the `web` feature is declared on **the root package `rs-launch-blueprint`**, which is the crate that hosts the binary targets.
- assumes http-transport-injection-seam = R01's published value, unchanged. One clarification this stack forces, which changes no clause of the value: the port trait, service, blanket `Arc<T>` impl and `InMemoryProjectsPort` live in `rs-launch-blueprint-core`; the composition root and the production adapter live in the root package.
- assumes package-manager-invocation = R42's published value, unchanged: `cargo deny check bans` (a crates.io-installed executable named `cargo-deny`), `cargo clippy` and `cargo metadata` (toolchain).
- assumes ci-job-structure = unresolved (R11). This item names the *tier* for each check and leaves job-versus-step and path-filtering to R11.
- assumes public-api-surface-shape = R04's published value, unchanged (the root barrel carries the in-crate half of F006; `[workspace.lints]` carries the denials — verified, result 3).
- assumes linter-config-surface = R28's scope (R28 owns clippy configuration; this item only requires that a per-member `clippy.toml` be permitted).
- assumes hook-wiring = R37's scope (R37 wires the pre-push tier; this item only names it).

**One `CONFLICT:` line is raised, for R69.** R69 pre-declared R02 as the item that decides which crate hosts the feature, so the host answer is expected — but R69's published value (revision 9) also fixes the feature's *body* (`web = ["dep:axum", "dep:tokio"]`, "the library module `src/web/`", "the web integration tests, gated file-level with `#![cfg(feature = "web")]`") in terms that assume the frameworks are dependencies of the declaring package. Under a workspace they are dependencies of `crates/web`. That is a consumed value needing to change, so it is surfaced in the required form:

CONFLICT: R69 web-extra-surface — `web = ["dep:rs-launch-blueprint-web"]` declared on the root package `rs-launch-blueprint`, with `axum` 0.8.9 and `tokio` 1.53.1 declared non-optionally in `crates/web/Cargo.toml` (feature list unchanged), the gated tree reading `crates/web/src/` rather than `src/web/`, the web integration tests living in `crates/web/tests/` with no file-level `#![cfg(feature = "web")]` needed because the whole member is optional, and `tower` 0.5.3 as `crates/web`'s dev-dependency — reason: the recommended multi-crate topology moves `axum` and `tokio` out of the declaring package, so the feature can only name the optional member; every other clause of R69's value (the four gated things, the `[[bin]] <app>-serve required-features = ["web"]` shape, the exit integers, the `otel`/`metrics` nesting, the skip-gating keys, `bacon` as a non-dependency) is preserved verbatim, with the skip-gating paths reading `crates/web/**` instead of `src/web/**`.

Three further items are recorded as **re-verify** rather than conflict, because their *values* do not change but their reasoning was written assuming one crate:

- **R67 (`error-taxonomy-exit-codes`)**: "thiserror in the library crate, anyhow in binary crates only" needs a topology-aware reading — `core`, `cli` and `web` are all library crates and none may depend on `anyhow`; the root package declares it for use only inside `src/main.rs` and `src/bin/serve.rs`, since Cargo has no per-target dependency table.
- **R04 (`public-api-surface-enforcement`)**: already lists "R02 selects a multi-crate topology" as a re-verify trigger. Two published crates now carry a public surface (`core` and the facade), so the root-barrel rule applies to both; `[workspace.lints]` carries the denials (executed).
- **R49 (`build-target-declaration`)**: pre-authorized this outcome ("if R02 chooses a workspace, every field above moves to the member manifests unchanged") and records R02-as-workspace as its own re-verify trigger. The root-package shape means nothing has to move at all.

### Migration implications

File-level changes in the template, all proposed (no template exists; P03 builds it):

| Path | Change |
|---|---|
| `Cargo.toml` | Gains `[workspace] members = ["crates/*"]`, `resolver = "3"`, `[workspace.package]`, `[workspace.lints]`, three path+version dependencies. Keeps `[package]`, `[lib]`, `[[bin]] rslbp`, `autobins = false`, the `include` allow-list. Gains `[[bin]] rslbp-serve` with `required-features = ["web"]` and `[features] web = ["dep:rs-launch-blueprint-web"]` per the R69 conflict resolution |
| `src/lib.rs` | The facade: R04's root barrel, `mod composition;`, `mod adapters;` (production adapter), `#[cfg(feature = "web")]` re-exports |
| `src/main.rs` | Calls `composition::production_service()`, hands the service to `rs_launch_blueprint_cli`, returns `ExitCode` per R67 |
| `src/bin/serve.rs` | Same for `rs_launch_blueprint_web` (new; R69's `<app>-serve`) |
| `crates/core/Cargo.toml` + `src/` | New. `rs-launch-blueprint-core`; inherits `[workspace.package]`; `[lints] workspace = true`; depends only on what R01 allows. **No `clap`, `axum`, `tokio`, HTTP client or `anyhow`** |
| `crates/core/clippy.toml` | New. `disallowed-types` / `disallowed-methods` scoped to core (F009) |
| `crates/cli/` | New. `rs-launch-blueprint-cli`; depends on `core` and R60's parser. Never on `web` |
| `crates/web/` | New. `rs-launch-blueprint-web`; depends on `core`, `axum`, `tokio` per R69. Never on `cli`. Optional at the facade |
| `deny.toml` | New at root. `[bans]` with one `deny` entry per framework carrying `wrappers` + `reason` (F008). Other sections are R13's |
| `tests/workspace_edges.rs` | New in the root package. Asserts the `cargo metadata --no-deps` edge set equals a literal table (F010) |
| `lefthook.yml` | New pre-push job `cargo deny check bans` (F116). No pre-commit entry for it |
| `.github/workflows/ci.yml` | Pinned `cargo-deny` install; the boundary check joins the job R11 shapes |
| `CONTRIBUTING.md` / `README.md` | The four-crate map, the `core`-may-not-depend-upward rule, the `cargo-deny` install line |
| **Not added** | `tach.toml` or analogue; `import-linter`-style config; an `xtask` member (R49 forbids it); a nested `src/rs_launch_blueprint/` directory (F020: namespaced by `Cargo.toml` `name`); `publish = false` on any member |

### Validation strategy

Commands that prove the principle holds, with expected behavior; executed vs. planned labeled per command. All executed commands ran 2026-09-26 on rustc/cargo 1.98.1, clippy 0.1.98, cargo-deny 0.20.2, in `/tmp/r02muse` (retained for review).

| # | Command (from the workspace root) | Expected | Status |
|---|---|---|---|
| 1 | Add `rs_launch_blueprint_cli::run()` to `crates/core/src/lib.rs`; `cargo check -p rs-launch-blueprint-core`; revert | `error[E0433]`, then clean | **Executed** (C1) |
| 2 | Add the cli path-dep to `crates/core/Cargo.toml`; `cargo check`; revert | `error: cyclic package dependency` | **Executed** (C2) |
| 3 | Add `rs_launch_blueprint_web::router()` to `crates/cli/src/lib.rs`; `cargo check -p rs-launch-blueprint-cli`; revert | `error[E0433]` | **Executed** (C3) |
| 4 | Add `rs_launch_blueprint::composition::production_service()` to `crates/core/src/lib.rs`; `cargo check -p rs-launch-blueprint-core`; revert | `error[E0433]` | **Executed** (C4) |
| 5 | `cargo clippy --workspace --all-targets` with a banned type used in both `core` and `cli` | 2 warnings, both in `crates/core`, none in `cli` | **Executed** (C3) |
| 6 | `cargo deny --offline check bans` clean / wrapper-uses-banned / core-uses-banned | `bans ok` exit 0 / `bans ok` exit 0 / `bans FAILED` exit 2 | **Executed** with `itoa` stand-in (D0–D2); **planned** re-run with real framework names once R60/R69 land |
| 7 | `cargo metadata --offline --format-version 1 --no-deps` | 4-package edge set with `[opt]` on web, ~0.05s | **Executed** (B8) |
| 8 | `cargo test --test workspace_edges` after adding a forbidden edge; revert | Test fails naming the edge, then passes | **Planned** — P03 writes the test; command shape and JSON fields verified (B8) |
| 9 | `cargo build` then `cargo build --features web`; `ls target/debug/rslbp*` | Only `rslbp` by default; `rslbp-serve` appears with the feature | **Executed** (B7) |
| 10 | `pub struct Leaked;` in a private `core` module; `cargo check -p rs-launch-blueprint-core`; revert | `error: unreachable pub item` | **Executed** (B6) |

### Confidence & re-verify trigger

Overall confidence: **high** for the topology and enforcement claims (compiler behavior, executed seven ways), **high** for the authoritative guard (exit codes executed on the recommended version), **medium-high** for tier placement (fixture-measured costs) and for the "no layering tool" census (dated 2026-09-26 by nature). Gaps recorded in this run, none blocking: (a) `cargo-deny unsafe` posture not audited; (b) cold-cache `cargo deny check bans` wall time not measured (warm/offline only); (c) `cargo-machete`/`cargo-udeps` declare no `rust-version` (unstated, not failed — both excluded on capability anyway); (d) `cargo-deny` issue responsiveness: no maintainer reply observed in the 10-issue window, median not measurable; (e) `cargo modules structure` not executed (tool not installed; review aid only); (f) the `workspace_edges` assertion test and real-framework `deny.toml` entries are specified, not written (P03). Re-verify triggers: Cargo changes cycle/`required-features`/metadata-shape behavior; `cargo-deny` 0.21+ changes `wrappers` semantics or issue #891 lands; a layer checker reaches credible maintenance; R01/R04/R11/R28/R37/R42/R49/R60/R67/R69 revise their values (R69's conflict resolution in particular re-opens the feature-body clauses assumed here).

### Sources

Every URL below retrieved 2026-09-26 unless noted. Named-endpoint figures: `GET https://crates.io/api/v1/crates/cargo-deny|guppy|cargo-hakari|cargo-machete|cargo-udeps|cargo-shear|cargo-modules|cackle|cargo-bylaw|archunit_rs` (+`/versions` and +`/<version>` detail for each); `GET https://api.github.com/repos/EmbarkStudios/cargo-deny|guppy-rs/guppy|bnjbvr/cargo-machete|est31/cargo-udeps|Boshen/cargo-shear|regexident/cargo-modules|cackle-rs/cackle|danielgerlag/cargo-bylaw|LukasNiessen/ArchUnitRust|oknozor/archunit_rs|modernizing/guarding|astral-sh/uv|astral-sh/ruff|jj-vcs/jj|rust-lang/rust-analyzer|rust-lang/crates.io|MystenLabs/walrus`; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for cargo-deny (81), guppy (14), cargo-modules (16), cargo-machete (25); `GET https://api.github.com/repos/EmbarkStudios/cargo-deny/issues?state=all&sort=created&direction=desc&per_page=40` plus per-issue `/comments` windows; `GET https://api.github.com/repos/EmbarkStudios/cargo-deny/issues/891`; contents API (`Accept: application/vnd.github.raw`) for `EmbarkStudios/cargo-deny` `docs/src/checks/bans/cfg.md` and `.github/workflows/ci.yaml`, `jj-vcs/jj` `Cargo.toml`, `MystenLabs/walrus` `deny.toml`; `https://rustsec.org/packages/<name>.html` → HTTP 404 (no advisory page) for all nine queried crates. Normative references (each cited rule re-verified empirically in-run): Cargo Book `https://doc.rust-lang.org/cargo/reference/` (workspaces, manifest format, cargo targets, specifying dependencies); Rust Reference `https://doc.rust-lang.org/reference/visibility-and-privacy.html`. In-repo: `docs/port/DIVERGENCE-ANALYSIS.md:77-79,240-241`, `docs/port/COMMONALITY.md:F021`, `docs/port/OWNER-REVIEW.md:47-62` (Q7.B), R01/R04/R42/R49/R69-rev9 published decisions, py precedent files at pin. Executed: fixtures A/B/C/D on rustc/cargo 1.98.1, clippy 0.1.98, cargo-deny 0.20.2 (`/tmp/r02muse`, retained for review).
