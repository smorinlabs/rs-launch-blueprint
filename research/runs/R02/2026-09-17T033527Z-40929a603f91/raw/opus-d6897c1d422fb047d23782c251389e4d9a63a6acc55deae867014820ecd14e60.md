# R02 crate-boundary-enforcement — Opus raw report

Engine: Claude Opus 5, identity `research-opus-2026-09-17T033527Z-40929a603f91`.
Item kind: `bundle`. Tier: Deep. All retrieval dates are **2026-09-17** unless a
line says otherwise; the session clock read `2026-09-17T05:25:02Z` (`date -u`).
Local toolchain used for every executed check: `rustc 1.98.0 (88d9e12ae 2026-08-18)
(Homebrew)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`, `clippy 0.1.98`, macOS
(`darwin` arm64). Executed checks ran in a throwaway workspace under `$TMPDIR`,
created and deleted inside this run; no template code exists and none was scaffolded.

**Fitness gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`.** Licence
compatibility is not evaluated for any dependency or tool, and nothing below is admitted,
ranked, preferred or excluded on a licence. Declared licences are still reported as
recorded facts, because the figure table asks for the crates.io field.

### Landscape

**Category this item decides.** Not "which linter" — *where the boundary physically is*.
In Python the module graph is a runtime artifact with no compile-time direction, so a
boundary is whatever a graph checker says it is; `import-linter` and `tach` exist because
the language supplies nothing. In Rust the compilation unit is the **crate**, and a crate
may only name crates listed in its own `Cargo.toml`. So the category is: *do we place the
architectural boundary on a compiler-enforced edge (crate) or on a convention the compiler
ignores (module), and what tool, if any, guards the manifest that declares those edges?*

**Three-bin map of the Rust field.**

| Bin | Candidates found | What each can enforce |
|---|---|---|
| **Built-in / first-party toolchain** | Cargo workspace members and `[dependencies]` edges; Cargo's cyclic-package rejection; `cargo metadata --no-deps` (the machine-readable declared edge set); `cargo tree` / `cargo tree -i`; Cargo features and `dep:` syntax; `[workspace.package]` and `[workspace.lints]` inheritance; `[[bin]] required-features`; `[package] include`; module visibility (`pub`, `pub(crate)`, `pub(super)`, `pub(in path)`); rustc lints (`unreachable_pub`, `private_interfaces`); `clippy::disallowed_types` / `disallowed_methods` with a per-package `clippy.toml` | Crate-to-crate direction, cycles, optional surfaces, lint policy. **Not** module-to-module direction inside one crate |
| **Established industry standard** | `cargo-deny` 0.20.2 (`bans.deny[].wrappers`, `bans.features`); `guppy` 0.18.0 (a `cargo metadata` graph library, the basis for custom dependency lints); `cargo-hakari` 0.9.38; `cargo-machete` 0.9.2; `cargo-udeps` 0.1.61; `cargo-shear` 1.13.4; `cargo-modules` 0.27.0 | `cargo-deny` and `guppy` act on the *package* graph. The `machete`/`udeps`/`shear`/`hakari` group finds unused or duplicated dependencies and shrinks build times — **none of them is a boundary tool** and all four are named here only to be excluded from the shortlist |
| **Up-and-comer** | `cackle` (a.k.a. `cargo-acl`) 0.2.0 — per-crate API permissions (net, fs, process) rather than per-crate dependency direction; `danielgerlag/cargo-bylaw` (0 stars, first push 2026-08-14); `LukasNiessen/ArchUnitRust` (4 stars); `oknozor/archunit_rs` (1 star, last push 2023-11-29, **not published to crates.io**: `GET https://crates.io/api/v1/crates/archunit_rs` → `{"errors":[{"detail":"crate \`archunit_rs\` does not exist"}]}`); `modernizing/guarding` (75 stars, last push 2022-02-21) | An intra-crate, layer-contract checker — the direct `import-linter`/`tach` analogue — **does not exist in maintained form**. This is the single most decisive landscape finding |

Search method for the third bin: `GET https://crates.io/api/v1/crates?q=<terms>&per_page=10` for
`architecture+boundary`, `module+dependency+graph`, `layer+architecture+lint` and `import+linter`,
plus `GET https://api.github.com/search/repositories?q=archunit+language:rust&sort=stars`
(2026-09-17). The crates.io searches returned no architecture-boundary linter for Rust at any
adoption level; the GitHub search returned the four repositories above, the largest of which
has 75 stars and has not been pushed since 2022-02-21.

**Authoritative sources, and why each counts.**

| Source | Why authoritative | Used for |
|---|---|---|
| The Cargo Book, *Workspaces* (<https://doc.rust-lang.org/cargo/reference/workspaces.html>) | The Cargo team's own normative reference | "If the `[workspace]` section is added to a `Cargo.toml` that already defines a `[package]`, the package is the root package of the workspace" — the shape that keeps R49 intact |
| The Cargo Book, *The Manifest Format* (<https://doc.rust-lang.org/cargo/reference/manifest.html>) | same | `include`/`exclude` semantics: "Any sub-packages will be skipped (any subdirectory that contains a `Cargo.toml` file)" |
| The Cargo Book, *Cargo Targets* (<https://doc.rust-lang.org/cargo/reference/cargo-targets.html>) | same | "The `required-features` field specifies which features the target needs in order to be built. If any of the required features are not enabled, the target will be skipped. This is only relevant for the `[[bin]]`, `[[bench]]`, `[[test]]`, and `[[example]]` sections" |
| The Cargo Book, *Specifying Dependencies* (<https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html>) | same | "Crates that use dependencies specified with only a `path` are not permitted on crates.io" — the publish fan-out cost, quoted verbatim |
| The Rust Reference, *Visibility and Privacy* (<https://doc.rust-lang.org/reference/visibility-and-privacy.html>) | The language's normative reference | Visibility is about *who may name an item*, never about *which module may depend on which* — the reason a single crate cannot express F004 |
| `cargo-deny` book, *The `[bans]` section* (<https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/docs/src/checks/bans/cfg.md>) | The maintainer's own documentation | `deny = [{ crate = "…", wrappers = ["this-can-use-it"] }]` — "This field allows specific crates to have a direct dependency on the banned crate but denies all transitive dependencies on it" |
| `cargo-deny` source, `src/bans.rs:610-654` (<https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/src/bans.rs>) | The implementation itself, read because the prose above is loose | The check iterates `ctx.krates.direct_dependents(nid)` and requires *every direct dependent* to be a listed wrapper. Ancestors further up the graph are not flagged. This is the precise semantics the recommendation relies on |
| `EmbarkStudios/cargo-deny` issue #891, "Support per-layer (crate-group) dependency boundaries within a workspace", opened 2026-08-20, **open** (<https://github.com/EmbarkStudios/cargo-deny/issues/891>) | A filed, unanswered feature request against the recommended tool | Direct evidence of the tool's limit: "`bans` allows/denies crates workspace-wide, but there's no way to restrict specific crates within a workspace to a subset of dependencies" |
| py-launch-blueprint at pin `b08bccfb`: `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md`, `pyproject.toml:318-355`, `tach.toml`, `src/py_launch_blueprint/core/ruff.toml`, `lefthook.yml:170-177`, `.github/workflows/ci.yml:118-134` | The source precedent this port carries, read through the pin as the role file requires | Every contract py declares, and the tier each runs at |
| R01 `DECISION.md` (owner-accepted 2026-09-10, revision 3 2026-09-13), R04 `DECISION.md`, R49 and R69 `DECISION.md` | Published decisions of this programme | The seam this boundary must hold, the public-surface rule, the target declaration, the web feature |

A single blog post is a lead, not an authority: matklad's *Large Rust Workspaces*
(<https://matklad.github.io/2021/08/22/large-rust-workspaces.html>) is cited only as a
lead whose claim — flat `crates/*`, no nesting — is independently corroborated by the
four repository layouts below.

**Well-regarded projects surveyed, with the evidence that they are well regarded**
(`GET https://api.github.com/repos/<o>/<r>`, 2026-09-17; directory counts from
`GET https://api.github.com/repos/<o>/<r>/contents/crates`):

| Project | Stars | `pushed_at` | `archived` | Shape evidence |
|---|---:|---|---|---|
| `astral-sh/uv` | 89,891 | 2026-09-17T02:33:02Z | false | 74 entries under a flat `crates/` |
| `astral-sh/ruff` | 49,651 | 2026-09-17T05:21:09Z | false | 52 entries under a flat `crates/` |
| `jj-vcs/jj` | 31,623 | 2026-09-17T05:15:56Z | false | root `Cargo.toml` `[workspace] members = ["cli", "core", "core/proc-macros", "lib", "lib/gen-protos", "lib/testutils"]` — a *CLI package separate from its library package*, this template's exact question. Already R01's reference implementation |
| `rust-lang/rust-analyzer` | 16,857 | 2026-09-17T01:39:12Z | false | 35 entries under a flat `crates/`; its crate graph is its layering |
| `rust-lang/crates.io` | 3,699 | 2026-09-16T20:55:39Z | false | 29 entries under a flat `crates/`; R01 calls it "the only surveyed project with this template's shape" (web service + workers + library crates) |
| `MystenLabs/walrus` | 417 | 2026-09-17T04:57:46Z | false | `deny.toml:91-93` uses `wrappers` in production to confine heavy dependencies to one member: `{ name = "ssh2", wrappers = ["walrus-orchestrator"] }` |

Breadth of the recommended tool, both retrieved 2026-09-17:
`GET https://api.github.com/search/code?q=filename:deny.toml+path:/` → `total_count` **14,912**;
`GET https://api.github.com/search/code?q=wrappers+filename:deny.toml` → `total_count` **3,216**.
`rust-lang/crates.io` and `jj-vcs/jj` both ship a root `deny.toml` (`GET /repos/<o>/<r>/contents/deny.toml`
→ 11,979 and 11,197 bytes), each carrying the `wrappers` line commented out as the upstream
template default — evidence the file is standard furniture, not that those two projects use
`wrappers` today. `MystenLabs/walrus` is the live-usage example.

**Fit over abstract best.** The template is one small capability (`projects`) behind one
port, one production adapter, one CLI, one optional web surface, published as one
installable command. Every judgement below is against that, not against a monorepo.

### Principles and implementation

**Shared requirement.** Architectural boundaries are *enforced by a machine, not by review*.
Concretely: the composition root is reachable only from front ends and never from the core
(F003); the core never depends on a front end (F004); front ends never depend on each other
(F005); the core's own layers stay ordered (F006); no CLI or web framework enters the core,
guarded both authoritatively and in a fast local tier (F008, F009); the permitted edges are
*declared in one readable artifact* rather than inferred (F010); and the check runs at a
defined place in the hook and CI pipeline (F116).

**Source and agreement level.** `docs/port/DIVERGENCE-ANALYSIS.md:77-79,241` puts F003–F010
and F116 in one item-level bucket, cause class **C** ("no recorded reason for any row"),
`harmonize: partly`; F020 is class C with `harmonize: no`; F021 is class **G** ("no precedent
either side"), `harmonize: no`. py `docs/adr/0017-…:38-44` states the principle in the
source's own words: "**enforce the boundaries mechanically** rather than by convention". ts
has none of it, and `DIVERGENCE-ANALYSIS.md:77` records why: "ts's flat `src/` with one
front-end and no core/front-end split leaves nothing for these tools to check (consequence
of F001)".

So the agreement levels split cleanly:

| Rows | What must agree | What may vary |
|---|---|---|
| F007 (mechanical over conventional), F003, F004, F005, F008 | **Policy + capability**: a violation must fail a build or a check, in every repo that has a core/front-end split | The mechanism entirely |
| F006, F009, F010, F116 | **Capability**: internal layering is constrained; a fast tier exists; the permitted edges are declared; the check has a defined tier | Mechanism, granularity and tier, because they follow from how fast the ecosystem's authoritative check is |
| F020 | Nothing above "the public name is unambiguous" | Everything: Python needs an importable package directory, Node needs none, Rust namespaces by `Cargo.toml` `name` |
| F021 | — | Rust-only; no agreement to preserve |

No shared low-level value is recommended. There is no owner requirement for one, and the
evidence does not support the same tradeoff in all three ecosystems: Python's checker exists
because the language has no compile-time module direction, and Rust's compiler makes the same
guarantee stronger and free — at *crate* granularity only.

**Is the shared pattern still appropriate in Rust?** Yes, and it changes tier. py buys with
two dev tools what Rust gets from `cargo check`. But the guarantee arrives only if the
boundary is drawn on a crate edge. That is the whole of question 1, and it was settled
empirically, not by argument.

**Executed result 1 — a single crate cannot enforce F004, and `pub(crate)` makes it worse.**
A one-package crate with `pub mod core_layer;` and `pub(crate) mod cli_layer;`, where
`core_layer.rs` contains `use crate::cli_layer::CliThing;` — core reaching upward into the
front-end layer, exactly what F004 forbids — **compiles clean**:

```
   Compiling single-demo v0.1.0 (…/single)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.19s
```

This is not a gap in the lints; it is what visibility *means*. The Rust Reference defines
visibility as who may *name* an item, and `pub(crate)` grants naming rights to the entire
crate — including the module that must not have them. Module visibility is therefore not a
weaker form of boundary enforcement; for this requirement it points the wrong way.

**Executed result 2 — the crate edge enforces F003, F004 and F005 as build errors.**
A root-package workspace (`[package] rs-launch-blueprint` + `[workspace] members = ["crates/*"]`)
with members `rs-launch-blueprint-core`, `-cli`, `-web`, the facade holding
`pub mod composition`:

| Case | Violation introduced | Observed |
|---|---|---|
| C1 (F004) | `crates/core/src/lib.rs` calls `rs_launch_blueprint_cli::run()` | ``error[E0433]: cannot find module or crate `rs_launch_blueprint_cli` in this scope`` → `error: could not compile `rs-launch-blueprint-core` (lib) due to 1 previous error` |
| C2 (F004, manifest tier) | `crates/core/Cargo.toml` adds `rs-launch-blueprint-cli = { path = "../cli", version = "0.1.0" }` | ``error: cyclic package dependency: package `rs-launch-blueprint-cli v0.1.0 (…)` depends on itself. Cycle:`` followed by the three-edge cycle. Cargo refuses before rustc runs |
| C3 (F005) | `crates/cli/src/lib.rs` calls `rs_launch_blueprint_web::router()` | ``error[E0433]: cannot find module or crate `rs_launch_blueprint_web` in this scope`` |
| C4 (F003) | `crates/core/src/lib.rs` calls `rs_launch_blueprint::composition::production_service()` | ``error[E0433]: cannot find module or crate `rs_launch_blueprint` in this scope`` |
| C5 | baseline restored | `Finished `dev` profile … in 1.04s` |

C1/C3/C4 are the *code* tier and C2 is the *manifest* tier. Note what C2 shows: for a
boundary between two crates that already have an edge in one direction, adding the reverse
edge is not merely discouraged — Cargo rejects it as a cycle, so F004 and F005 are
self-enforcing for every pair on the spine. The one direction Cargo will happily accept is a
*new* edge that does not close a cycle, which is exactly what the manifest guard below covers.

**Executed result 3 — `[workspace.lints]` carries R04's lint policy to every member from one
place.** With `[workspace.lints.rust] unreachable_pub = "deny"` at the root and
`[lints] workspace = true` in each member, a `pub struct Leaked;` inside a private module of
`crates/core` produced ``error: unreachable `pub` item`` → `error: could not compile
`rs-launch-blueprint-core` (lib)`. The split therefore costs R04 nothing: its three `deny`
attributes become three workspace-inherited lines instead of three per-crate attributes.

**Executed result 4 — py's *subtree-scoped* fast mirror has no single-crate analogue, and a
package-scoped one is actively wrong without the split.** py's `src/py_launch_blueprint/core/ruff.toml`
works because ruff resolves configuration per directory subtree. Clippy does not:

- A `clippy.toml` at the **package root** banning `std::collections::HashMap` flagged
  `src/core_layer.rs` **and** `src/cli_layer.rs` — three `error: use of a disallowed type` sites
  across both layers. Package-wide is the only granularity it has, so a single-package
  template cannot ban `clap` in core without banning it in the CLI too, which is absurd.
- A `clippy.toml` placed at `src/clippy.toml` (a nested subtree, py's shape) was **ignored**:
  the same code produced zero `disallowed_types` diagnostics.
- A `clippy.toml` at `crates/core/clippy.toml` in the workspace, with
  `cargo clippy --workspace`, flagged **only** `crates/core/src/lib.rs` (three sites) and
  left the identical `HashMap` use in `crates/cli/src/lib.rs` untouched.

So F009's capability is available in Rust at *package* granularity and nowhere else. The fast
mirror is a second, independent reason for the split, not merely a consequence of it.

**Executed result 5 — the declared dependency graph (F010) is already a first-party artifact.**
`cargo metadata --offline --format-version 1 --no-deps`, `real 0.02` seconds, emitted the
complete intra-workspace edge set including optionality and dependency kind:

```
  rs-launch-blueprint          -> ['rs-launch-blueprint-cli', 'rs-launch-blueprint-core', 'rs-launch-blueprint-web[opt]']
  rs-launch-blueprint-cli      -> ['rs-launch-blueprint-core']
  rs-launch-blueprint-core     -> []
  rs-launch-blueprint-web      -> ['rs-launch-blueprint-core']
```

That is `tach.toml`'s `[[modules]] path / depends_on` table, generated rather than
hand-maintained. What Cargo does *not* give is the assertion that this set is the *intended*
one — which is the one job left for a checked-in artifact.

**Architectural alternatives compared, before any tool was weighed.**

| Alternative | Shape | Verdict |
|---|---|---|
| **A. Single package, module visibility + review** (the faithful F020 precedent) | `src/core/`, `src/cli/`, `src/web/` with `pub(crate)` | **Rejected.** Executed result 1: the violating code compiles. Fails F007 outright, and F003/F004/F005 with it. It is the ts position, which `DIVERGENCE-ANALYSIS.md:77` records as having no boundary tool at any tier |
| **B. Single package + an intra-crate layer-contract linter** (the literal `import-linter`/`tach` port) | a tool reading the module graph and failing on a forbidden edge | **Rejected for absence of a candidate.** No maintained Rust tool does this. `cargo-modules` 0.27.0 offers `structure`, `dependencies` and `orphans`, and its only failing mode is `--acyclic` ("If found it will search for cycles in the directed graph and return an error for any cycles it found" — README). A cycle check is not a *direction* check: `core → cli` with no `cli → core` edge is acyclic and forbidden. The ArchUnit ports are 1–4 stars; `modernizing/guarding` last moved 2022-02-21; `cargo-bylaw` has 0 stars. Adopting any of them would put a template's build gate on an unmaintained dependency |
| **C. Single package + `cargo-deny` on the external graph only** | keep one crate, ban `axum`/`clap` nowhere in particular | **Rejected.** `bans` acts on packages; with one package there is no sub-package to confine a framework to. It can say "this workspace may not use `axum`", which is false — the web surface must |
| **D. Multi-crate workspace, virtual manifest** (`[workspace]` with no `[package]`, jj's shape) | binaries live in `crates/cli` | **Rejected on R49 compatibility, ranked second.** It is a perfectly good shape and `jj-vcs/jj` ships it, but the published package would no longer be the repository root, so R49's `include = ["/src", …]` allow-list and its `[[bin]] path = "src/main.rs"` would both have to move, and R69's `[[bin]] required-features = ["web"]` would have to move to the package whose `[features]` table it names (that a target may name only its own package's features is an inference from Cargo's per-package feature namespacing, not a quoted Cargo Book rule) |
| **E. Multi-crate workspace with a root package** | `[package] rs-launch-blueprint` + `[workspace] members = ["crates/*"]`; the facade holds `[lib]`, both `[[bin]]`s, the composition root, the production adapter and the `web` feature | **Chosen.** Executed results 2–5. The Cargo Book names this exact shape: "If the `[workspace]` section is added to a `Cargo.toml` that already defines a `[package]`, the package is the root package of the workspace". Every R49 field stays byte-identical and every R69 field lands on the package that declares the feature |

**Why the chosen design preserves each principle.**

| Row | Preserved by | Tier |
|---|---|---|
| F003 composition-root isolation | `composition` is a module of the facade `[lib]`; `core`/`cli`/`web` do not depend on the facade | `cargo check` (C4) |
| F004 inward-only core | `crates/core/Cargo.toml` names no front end; the reverse edge is a Cargo cycle | `cargo check` (C1) + Cargo resolution (C2) |
| F005 front-end independence | `crates/cli` and `crates/web` name only `core` | `cargo check` (C3) |
| F006 core internal layering | The production adapter moves *out* of `core` into the facade, so "adapters above services above models" becomes a crate edge; `models` below `services` inside `core` stays module discipline plus R04's private-`mod` root barrel. **This is the one row the split does not fully compile-enforce** — see the `BASELINE-REVIEW` line and *Members → Core internal layering* |
| F007 mechanical over conventional | Every row above fails a build, not a review | — |
| F008 framework-bleed, authoritative | `cargo deny check bans` with `deny = [{ crate = "axum", wrappers = ["rs-launch-blueprint-web"] }]` etc.; guards the *manifest*, which is the only remaining way a framework could reach `core` | pre-push + CI |
| F009 framework-bleed, fast mirror | `crates/core/clippy.toml` with `disallowed-types`/`disallowed-methods`, plus `cargo check` itself, which already rejects `use axum::…` in `core` with `E0432` | `cargo check`/`cargo clippy`, i.e. the contributor's own edit loop |
| F010 declared graph | The member manifests are the declaration; a `cargo metadata --no-deps` assertion test pins the intended edge set | `cargo test` |
| F020 namespacing | The package name *is* the namespace; flat `crates/<name>/src/` with no directory nesting | — |
| F021 topology | This decision | — |

**Minimal realistic example.** Five directories, four packages:

```
Cargo.toml                    # [package] rs-launch-blueprint + [workspace] members = ["crates/*"]
                              # [lib] rs_launch_blueprint (src/lib.rs) — R04 root barrel + pub mod composition
                              # [[bin]] rslbp (src/main.rs); [[bin]] rslbp-serve (src/bin/serve.rs, required-features = ["web"])
                              # [features] web = ["dep:rs-launch-blueprint-web"]
crates/core/                  # rs-launch-blueprint-core: Project, ProjectQuery, ProjectsPort,
                              #   ProjectsService<P>, ErrorCode/Exit, InMemoryProjectsPort. No clap, axum, tokio.
crates/cli/                   # rs-launch-blueprint-cli: clap parsing + rendering over core's types
crates/web/                   # rs-launch-blueprint-web (optional): AppState, build_router, handlers
deny.toml                     # [bans] deny = [{ crate = "axum", wrappers = [...] }, ...]
crates/core/clippy.toml       # disallowed-types / disallowed-methods, scoped to core only
tests/workspace_edges.rs      # asserts the cargo metadata --no-deps edge set equals the declared one
```

The production HTTP adapter (`impl ProjectsPort for …`) lives in the facade `[lib]` beside
`composition`, not in `core`. That placement does three things at once: it makes F006's
adapters-above-services a crate edge, it keeps the HTTP client crate out of `core`'s
dependency tree, and it keeps R01's `production_service(..)` next to the only type it
constructs. `InMemoryProjectsPort` stays in `core` exactly as R01 requires — it has no I/O
dependency, and R01's criterion 3 ("a public, shipped library item") is satisfied by
`rs-launch-blueprint-core` being a published crate.

**Reference implementations.** `jj-vcs/jj` is the closest maintained match: a CLI package
(`cli/`) and a library package (`lib/`) as separate workspace members, with a first-class fake
in `lib/testutils`, already cited by R01 for the seam this boundary holds.
`rust-lang/crates.io` is the closest *shape* match (web service + library crates in one
workspace, 29 members). `MystenLabs/walrus` is the maintained example of the manifest guard
in production use. `astral-sh/uv`, `astral-sh/ruff` and `rust-lang/rust-analyzer` corroborate
the flat `crates/*` layout for F020.

**Cross-repo adjudication (HIGH question 3; changes to py and ts are a follow-on project).**

- **py** is the reference realization and needs no change. Its two-tier split
  (`ruff` TID251 at pre-commit, `import-linter` at pre-push and CI) is the right shape for a
  language whose authoritative check must build a whole import graph. `DIVERGENCE-ANALYSIS.md:77`
  records its mechanism accurately.
- **ts**'s absence is **contingent drift, not a missing capability**: there is no core/front-end
  split for a boundary tool to guard, so the rows are vacuous rather than violated
  (`DIVERGENCE-ANALYSIS.md:77`, "consequence of F001"). It is not *justified* — there is no
  `D-0nn` recording a decision — but it is not independently actionable either. The follow-on
  is conditional: **if** ts ever grows a second front end, the ecosystem's realizations of this
  principle are `eslint-plugin-boundaries` and `dependency-cruiser`, and the TypeScript compiler
  supplies no crate-equivalent, so ts would land on py's tool-based tier, not Rust's.
- **rs** preserves the principle at a *stronger* level than either source: py and ts both
  enforce with a checker that a contributor can skip, while Rust's enforcement is the build
  itself. That is a justified ecosystem difference in Rust's favour and needs no harmonization.
- The one genuinely shared low-level value worth naming across all three is the **declared-graph
  artifact** (F010): py has `tach.toml`, rs gets `cargo metadata` plus an assertion test, ts has
  nothing. Even here the recommendation is capability-level agreement, not a shared file format.

BASELINE-REVIEW: F006 — core internal layering is constrained by a machine, not by review —
restate the row so that its Rust acceptance criterion is "adapters sit above services and models
on a *crate* edge; the models-below-services ordering inside the core crate is carried by module
privacy and the R04 root barrel, not by a boundary tool", and record that Rust has no maintained
intra-crate layer-contract checker to select; affected items: R02 (this row) and R28
(`linter-and-editor-tooling`), which must not scope an intra-crate module-graph linter into its
gate — evidence: py's row rests on `pyproject.toml:340-347`, an `import-linter` `layers` contract
over `core.adapters`/`core.services`/`core.models` read at pin `b08bccfb`; the only Rust
candidates are `cargo-modules` 0.27.0, whose sole failing mode is `--acyclic` and therefore
cannot express direction (README, retrieved 2026-09-17), and three ArchUnit ports with 75, 4 and
1 stars whose most recent pushes are 2022-02-21, 2026-08-24 and 2023-11-29
(`GET https://api.github.com/search/repositories?q=archunit+language:rust&sort=stars`,
2026-09-17); this run observed that a single crate cannot enforce even the simpler F004
(executed result 1).

BASELINE-REVIEW: F009 — a fast local guard mirrors the authoritative framework-bleed check —
restate the row's mechanism as a per-package `clippy.toml` (`disallowed-types`,
`disallowed-methods`) in the core member, backed by `cargo check` itself, and record that the
subtree-scoped configuration py uses has no Rust analogue at any granularity finer than a
package; affected items: R02 (this row), R28 (`linter-and-editor-tooling`, which owns the clippy
configuration surface) and R37 (`hook-manager-distribution`, which wires the tier) — evidence:
py's row rests on `src/py_launch_blueprint/core/ruff.toml:13` (`extend-select = ["TID251"]` with a
nested `extend = "../../../pyproject.toml"`) read at pin `b08bccfb`; this run observed that a
`clippy.toml` at `src/clippy.toml` is ignored (zero diagnostics on code that a package-root
`clippy.toml` flags three times), and that a package-root `clippy.toml` flags every layer of the
package indiscriminately, while `crates/core/clippy.toml` in a workspace flags only that member.

**OVERRIDE (OV-nn) — multi-crate workspace instead of the single-package precedent (F021).**
`docs/port/COMMONALITY.md:F021` records that "the precedent is a single package with internal
layering (F020), so a multi-crate split would be a §2 pattern change that needs an `OV-nn` label
if R02 proposes it (Phase 4 review #4)". This report proposes it. The number is left as `nn` for
the synthesizer to assign.

> **Argument:** The recorded precedent is a *Python* package layout, and it carries the
> boundary-enforcement burden in a checker precisely because Python has no compile-time module
> direction. Porting the layout without the checker ports the weakest half. Porting the checker
> is not available: no maintained Rust tool enforces intra-crate layer contracts. The only
> mechanism in Rust that makes an illegal dependency a build-breaking error is the crate edge,
> and this run observed the single-package alternative compiling the violating code clean. The
> split additionally supplies the *only* granularity at which the F009 fast mirror can be scoped,
> and it costs R49 and R69 nothing because the facade stays the repository-root package.
>
> **Options:**
> 1. **Single package, module visibility + review discipline** — keeps F020's shape and the
>    simplest publish story (one crates.io name). Cost: F003, F004, F005, F006 and F007 all become
>    conventions; F009 cannot be scoped to core; `DIVERGENT` becomes "ts's position with more
>    documentation". Executed evidence that the violation compiles: result 1.
> 2. **Single package + an intra-crate layer linter** — would preserve the precedent *and* the
>    enforcement. Not available: the candidate set is `cargo-modules` (cycles only) and three
>    ArchUnit ports at 75, 4 and 1 stars.
> 3. **Multi-crate workspace, root package (recommended)** — F003/F004/F005 become build errors,
>    F006 becomes one crate edge plus module discipline, F009 becomes scopable, F010 becomes a
>    generated artifact plus an assertion. Cost: **four crates.io names must be published, in
>    dependency order, on every release**, because "Crates that use dependencies specified with
>    only a `path` are not permitted on crates.io" (Cargo Book). This is the real price and it is
>    paid at every release, not once.
> 4. **Multi-crate workspace, virtual manifest** — same enforcement, but the published package
>    stops being the repository root and R49's `include` allow-list and target paths move.

**Observable acceptance criteria** (criteria 1–5 were verified in this run against a throwaway
workspace; 6–8 are stated as requirements on the template and are **not** results):

1. A `use` of a front-end crate from `core` fails `cargo check` with `E0433`. *Verified, C1.*
2. Adding a front-end crate to `crates/core/Cargo.toml` fails Cargo resolution with
   `error: cyclic package dependency`. *Verified, C2.*
3. A `use` of the web crate from the CLI crate fails with `E0433`. *Verified, C3.*
4. A `use` of the facade's `composition` module from `core` fails with `E0433`. *Verified, C4.*
5. A banned type used in `core` fails `cargo clippy` while the same use in `cli` passes.
   *Verified, executed result 4, third bullet.*
6. `cargo deny check bans` exits non-zero when `axum` is added to any member other than
   `rs-launch-blueprint-web`. **Planned, not executed** — `cargo-deny` is not installed on this
   machine (`cargo deny --version` → ``error: no such command: `deny` ``) and this run did not
   install it.
7. `cargo test` fails when the `cargo metadata --no-deps` edge set differs from the checked-in
   one. **Planned, not executed** — the metadata command and its output shape were verified
   (executed result 5); the assertion test itself is P03's to write.
8. `cargo build` with default features does not compile the web member, and
   `cargo build --features web` does. *Verified*: the default build compiled three packages and
   `--features web` added `rs-launch-blueprint-web`; the `rslbp-serve` binary was silently skipped
   by default, matching the Cargo Book's `required-features` wording.

### Recommendation

**One stack: a Cargo *root-package* workspace of four members — `rs-launch-blueprint` (repository
root; `[lib] rs_launch_blueprint`, `[[bin]] rslbp`, `[[bin]] rslbp-serve`, the composition root and
the production adapter), `crates/core`, `crates/cli`, `crates/web` (optional) — with the crate
graph as the declared dependency graph, `cargo-deny` 0.20.2 `check bans` with
`deny[].wrappers` as the authoritative framework-bleed guard, a per-member `crates/core/clippy.toml`
plus `cargo check` itself as the fast mirror, and a dependency-free `cargo metadata --no-deps`
assertion test as the F010 declaration guard. No `import-linter`/`tach` analogue is adopted,
because the compiler is the analogue. Boundary checks run at the tiers Rust's own speeds dictate:
the compiler tier is continuous (every `cargo check`), the manifest tier is pre-push + CI.**

Settled rows: **F003, F004, F005, F006, F007, F008, F009, F010, F020, F021, F116.**

Not selected: a single-package layout (alternatives A and C), an intra-crate layer linter
(`cargo-modules` 0.27.0, `archunit_rs`, `ArchUnitRust`, `cargo-bylaw`, `modernizing/guarding`), a
virtual-manifest workspace, `guppy` 0.18.0 as a custom-lint substrate, `cackle` 0.2.0,
`cargo-hakari` 0.9.38, `cargo-machete` 0.9.2, `cargo-udeps` 0.1.61, `cargo-shear` 1.13.4,
`cargo-depgraph` 1.6.0, and an `xtask` crate (forbidden by R49's owned parameter: "no build.rs and
no build-orchestration crate").

### Members

Six members, each named by the ledger rows it settles. Four are first-party toolchain behavior and carry no crate figures for the reason each member's *Excluded by gate* field states; the two that name installed tools (`cargo-deny`, and `guppy`/`cargo-modules` as runners-up or exclusions) carry the full figure set.

#### Crate topology and package namespacing (F021, F003, F004, F005, F007, F020)

Settles where the boundary physically sits, and therefore whether F003, F004, F005 and F007 are enforced at all. F020 falls out of it.

##### Landscape
*Built-in/first-party*: Cargo workspace with a root package; Cargo workspace with a virtual
manifest; a single package with module visibility; `[workspace.package]`, `[workspace.lints]` and
`[workspace.dependencies]` inheritance; `[[bin]] required-features`; `[package] include`.
*Established standard*: nothing — topology is not a crate you install. *Up-and-comer*: none.
Practice: `astral-sh/uv` (89,891 stars, pushed 2026-09-17T02:33:02Z, 74 entries in `crates/`),
`astral-sh/ruff` (49,651 / 2026-09-17T05:21:09Z / 52), `jj-vcs/jj` (31,623 / 2026-09-17T05:15:56Z,
`members = ["cli", "core", "core/proc-macros", "lib", "lib/gen-protos", "lib/testutils"]`),
`rust-lang/rust-analyzer` (16,857 / 2026-09-17T01:39:12Z / 35), `rust-lang/crates.io`
(3,699 / 2026-09-16T20:55:39Z / 29). All five use a flat, unnested member directory; none nests a
package-name directory the way py's `src/py_launch_blueprint/` does, which is F020's answer.

##### Principles and implementation
The principle is F007: a boundary violation must fail a machine, not a review. In Rust the only
edge the machine checks is the crate edge (executed results 1 and 2). The topology is therefore
not a stylistic choice downstream of the enforcement decision — it *is* the enforcement decision.
Four packages is the minimum that separates the three things py separates: core, each front end,
and the composition root. Namespacing (F020) falls out for free: a crate is named by
`Cargo.toml` `name`, so `crates/core/src/lib.rs` needs no `rs_launch_blueprint/` directory under
it, and every surveyed project agrees.

##### Dominant choice
Multi-crate Cargo workspace. Of the six surveyed reference projects, five are workspaces with
separate library and front-end packages; the sixth (`walrus`) is too. No surveyed CLI-plus-library
Rust project of comparable size ships a single package with internal layering as its boundary.

##### Qualified shortlist
(1) **Root-package workspace** — `[package]` and `[workspace]` in the repository-root
`Cargo.toml`, members under `crates/*`. (2) **Virtual-manifest workspace** — `jj`'s shape, root
`Cargo.toml` with `[workspace]` only. Both give identical enforcement; they differ only in where
the published package sits.

##### Excluded by gate
Gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Gates 2–6 are `inapplicable` to
every candidate in this member: a Cargo workspace is a manifest shape shipped inside the
toolchain, with no crates.io entry, no release cadence, no RustSec page, no default features, no
async-runtime coupling and no binary-size or compile-time cost of its own. Excluded on *fit*, not
on a gate: **single package with module visibility** — executed result 1 shows the violating code
compiles, so it fails F007 and with it F003/F004/F005; and **virtual-manifest workspace** —
R49's `include = ["/src", …]` is package-relative and R69's `required-features` must name a
feature of the package that declares the binary, both of which break when the published package
moves out of the repository root.

##### Up-and-comers
None. Cargo workspaces have been stable since Rust 1.12 (2016) and the `[workspace.package]`,
`[workspace.dependencies]` and `[workspace.lints]` inheritance tables are the only recent
additions; all three are stable and all three were exercised in this run's probe.

##### Fit for this template
The template is CLI + library + optional web service. The split gives the *library* shape its
biggest win: a consumer writes `cargo add rs-launch-blueprint-core` and gets the domain, the port
and the shipped fake without `clap`, `axum` or `tokio` anywhere in the tree — a property the
single-package shape cannot offer, since R69 records that the CLI parser "is a non-optional
dependency of the package". The *CLI* shape is unaffected: `cargo install rs-launch-blueprint`
still installs `rslbp`, because the root package still carries the binary. The *web* shape is
strictly better: with `web` off, `cargo build` does not compile the web member at all (verified),
where a single package would still parse and type-check the `#[cfg]`-gated module's manifest
context.

##### Recommendation
Root-package workspace, four members:

```toml
# ./Cargo.toml — repository root, and the published package
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.96"          # msrv-policy computes the exact floor
license = "MIT OR Apache-2.0"

[workspace.lints.rust]
unreachable_pub = "deny"
missing_docs = "deny"

[package]
name = "rs-launch-blueprint"
version.workspace = true
edition.workspace = true
rust-version.workspace = true
license.workspace = true
autobins = false
include = ["/src", "/README.md", "/LICENSE-MIT", "/LICENSE-APACHE", "/CHANGELOG.md"]

[lib]
name = "rs_launch_blueprint"
path = "src/lib.rs"

[[bin]]
name = "rslbp"
path = "src/main.rs"

[[bin]]
name = "rslbp-serve"
path = "src/bin/serve.rs"
required-features = ["web"]

[features]
web = ["dep:rs-launch-blueprint-web"]

[dependencies]
rs-launch-blueprint-core = { path = "crates/core", version = "0.1.0" }
rs-launch-blueprint-cli  = { path = "crates/cli",  version = "0.1.0" }
rs-launch-blueprint-web  = { path = "crates/web",  version = "0.1.0", optional = true }
```

Each member carries `[lints] workspace = true` and inherits `version`, `edition`,
`rust-version` and `license` from `[workspace.package]`. Member directories are flat
(`crates/core`, `crates/cli`, `crates/web`) with no package-name nesting — F020's answer.

##### Ranked runner-up
Virtual-manifest workspace with the binaries in `crates/cli` (jj's shape). Adopt it only if the
owner later decides the repository root should not be a package — for example if a second
installable binary needs its own crates.io name. It costs an R49 amendment (the `include` list
and both `path` fields move to `crates/cli/`) and an R69 amendment (the `web` feature moves to
`crates/cli`'s `[features]`), which is exactly why it is second and not first.

##### Tradeoffs
**The cost is publish fan-out, and it is paid every release.** The Cargo Book: "Crates that use
dependencies specified with only a `path` are not permitted on crates.io… we would need to publish
a version of `hello_utils` to crates.io as a separate crate and specify its version". Four
packages therefore means four crates.io names to claim and four `cargo publish` runs in dependency
order (`core`, then `cli` and `web`, then the facade) on every release. R04's executed case 11
closes the obvious escape: `publish = false` on an internal member makes the facade unpublishable
(``no matching package named `rs_publish_demo_internal` found``). Mitigations exist — the
`path` + `version` pair written above is the supported form, `[workspace.package] version` keeps
the four versions in lockstep, and release-please's `linked-versions` plugin and `dist`'s
workspace support both target this shape — but every one of them is *other items'* territory
(R23, R24, R25, R68), so this report states the cost rather than discharging it. Second cost:
four `README`/docs.rs surfaces instead of one, and four packages for R04's public-surface rule to
cover (cheap: `[workspace.lints]` carries the lints, verified). Third: a contributor must learn
where a new file goes, which is the same tax py pays for `core/` vs `cli/` and is arguably the
point of a template.

##### Parameters
No parameter is owned by this member. `assumes build-tool-output-shape` (R49) — every field of it
holds unchanged under the root-package shape: `[lib] path = "src/lib.rs"`, `[[bin]] path =
"src/main.rs"` named `rslbp`, `autobins = false`, `default-run` unset, no `build.rs`, and the
`include` allow-list, whose paths are package-relative and whose sub-package exclusion rule
("Any sub-packages will be skipped (any subdirectory that contains a `Cargo.toml` file)") already
excludes `crates/` without an edit. `assumes web-extra-surface` (R69) — the `web` feature and the
`rslbp-serve` binary both land on the root package, answering R69's explicit deferral ("declared on
whichever crate hosts the binary targets (R02 decides which)"). `assumes http-transport-injection-seam`
(R01) — unchanged; the trait, its blanket `Arc` impl and the erasure all live in `crates/core`
except the production adapter and `production_service`, which live in the facade.
No `CONFLICT:` line.

##### Migration implications
`Cargo.toml` gains `[workspace]`, `[workspace.package]`, `[workspace.lints]` and three path
dependencies. New: `crates/core/`, `crates/cli/`, `crates/web/`, each with a `Cargo.toml` using
`*.workspace = true` inheritance and `[lints] workspace = true`. `src/lib.rs` becomes the facade:
R04's private-`mod` root barrel re-exporting `rs_launch_blueprint_core`'s sanctioned names, plus
`mod composition;` and the production adapter module. `src/main.rs` calls
`composition::production_service()` and hands the service to `rs_launch_blueprint_cli`.
`src/bin/serve.rs` does the same for `rs_launch_blueprint_web`. Members need
`license.workspace = true` (the SPDX string, not `license-file`), because `/LICENSE-MIT` and
`/LICENSE-APACHE` sit at the repository root and are not inside any member directory.

##### Validation strategy
Executed in this run (throwaway workspace, `cargo 1.98.0`, macOS, `--offline`):
`cargo build --offline` → three packages compiled, `Finished ... in 0.67s`;
`cargo build --offline --features web` → adds `rs-launch-blueprint-web`, `Finished ... in 0.83s`;
cases C1–C5 above. Planned for P03: the same four violations as `trybuild`-style or
`compile_fail` fixtures, or as a documented `just check-boundaries` recipe, plus
`cargo publish --dry-run` for each member in dependency order (not executed here — it requires
network access to the crates.io index).

##### Confidence & re-verify trigger
**High** on the mechanism (four executed compile failures, one executed clean build). **Medium**
on the member *count*: four is the minimum for this template's one capability, and a second
bounded context or a second production adapter should promote `crates/adapters` to a fifth member.
Re-verify when: R68 (`release-binary-artifacts`) or R23/R24/R25 publish and fix the multi-package
release mechanics; a second bounded context or adapter appears; the owner rules on the OV-nn
override; or by 2027-03-17.

##### Sources
Cargo Book *Workspaces* <https://doc.rust-lang.org/cargo/reference/workspaces.html> (2026-09-17);
Cargo Book *The Manifest Format* <https://doc.rust-lang.org/cargo/reference/manifest.html>
(2026-09-17); Cargo Book *Cargo Targets*
<https://doc.rust-lang.org/cargo/reference/cargo-targets.html> (2026-09-17); Cargo Book
*Specifying Dependencies* <https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html>
(2026-09-17); `GET https://api.github.com/repos/{astral-sh/uv,astral-sh/ruff,jj-vcs/jj,rust-lang/rust-analyzer,rust-lang/crates.io}`
and `/contents/crates` (2026-09-17); `https://raw.githubusercontent.com/jj-vcs/jj/main/Cargo.toml`
(2026-09-17); matklad, *Large Rust Workspaces*
<https://matklad.github.io/2021/08/22/large-rust-workspaces.html> (lead only, 2026-09-17);
R49 `research/topics/49-build-target-declaration/DECISION.md:885-886,1041,1059`; R69
`research/topics/69-web-framework-stack/DECISION.md:222,1406,1586`; R04
`research/topics/04-public-api-surface-enforcement/DECISION.md` (alternative E, case 11);
py at pin `b08bccfb`: `pyproject.toml:139-141`, `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md:38-44`.

#### Core internal layering (F006)

Settles how the core's own ordering — adapters above services above models — is constrained once the crate split exists. The one row where this stack is weaker than py's.

##### Landscape
*Built-in/first-party*: a further crate split (adapters as their own package); module privacy
(`pub(crate)`, `pub(super)`, `pub(in path)`); R04's private-`mod` root barrel; `#[deny(unreachable_pub)]`.
*Established standard*: none — no maintained crate enforces intra-crate layer contracts.
*Up-and-comer*: `cargo-modules` 0.27.0 (cycle detection only), `oknozor/archunit_rs`,
`LukasNiessen/ArchUnitRust`, `danielgerlag/cargo-bylaw`, `modernizing/guarding`.

##### Principles and implementation
py's contract is `layers = ["core.adapters", "core.services", "core.models"]`
(`pyproject.toml:340-347` at pin `b08bccfb`): infrastructure may depend on application logic and
on the domain, never the reverse. The capability that must agree is *the ordering is constrained
by a machine*; the mechanism may vary. In Rust the machine only sees crate edges, so the question
reduces to: which of the three layers is worth a crate of its own?

##### Dominant choice
Move the *adapters* layer up and out. Every surveyed workspace that separates a domain from its
I/O does so at the crate edge: `jj` keeps `lib/` (the domain and the `Backend` trait) separate
from `cli/`, and R01 records `lib/testutils` as a first-class fake shipped in a *library* crate;
`rust-lang/crates.io` keeps `crates/crates_io_github` (the adapter) separate from the application.
No surveyed project enforces a models/services ordering *inside* one crate with a tool.

##### Qualified shortlist
(1) **Adapter in the facade package** — the production adapter and `production_service` live in
`src/` beside `composition`, so `core` contains only models, ports and services.
(2) **Adapter in a fifth member `crates/adapters`** — same edge, one more crates.io name.
(3) **`cargo-modules dependencies --acyclic`** as a partial guard, catching only cycles.

##### Excluded by gate
Gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`. `cargo-modules` 0.27.0 is
excluded **on fit, not on a gate**: its failing mode is `--acyclic` ("Require graph to be
acyclic"), and a forbidden one-way edge is acyclic, so it cannot express the contract. For the
record its gate figures are: 90-day downloads **13,806**, all-time **249,931**
(`GET https://crates.io/api/v1/crates/cargo-modules`, 2026-09-17); newest non-yanked **0.27.0**,
`created_at` **2026-08-03T10:16:59.087696Z**; licence `MPL-2.0`; `rust_version` **1.95.0**, which
is *below* the `stable minus 2` floor computed from 1.98.0 (= 1.96), so **gate 2 passes**; it is
in any case `inapplicable` for an installed developer binary that never enters the template's MSRV
computation. Issue responsiveness (`GET https://api.github.com/repos/regexident/cargo-modules/issues?state=all&sort=created&direction=desc`,
2026-09-17): only **2** issues opened in the sampled window (2026-04-08 to 2026-07-19), median
**10.17 days** to first maintainer comment, **1 unanswered**. No
RustSec page (`https://rustsec.org/packages/cargo-modules.html` → HTTP **404**), `unsafe` posture
not stated by the crate; platform support not asserted by a CI badge in the README; it is a
developer binary, so default features and async coupling are `inapplicable`, and its binary-size
and compile-time cost to the template is nil. The three ArchUnit-style projects are excluded on
maintenance: `oknozor/archunit_rs` (1 star, `pushed_at` 2023-11-29T09:41:31Z, **not on crates.io**),
`LukasNiessen/ArchUnitRust` (4 stars, 2026-08-24T14:40:58Z), `danielgerlag/cargo-bylaw` (0 stars,
2026-08-14T02:05:36Z), `modernizing/guarding` (75 stars, 2022-02-21T01:49:40Z) — all `at-risk` or
worse by the rubric, three of them with no release at all.

##### Up-and-comers
`cargo-bylaw` (first push 2026-08-14, 0 stars) is the only one aimed squarely at this gap and is
worth a re-verify glance in six months. Watch, do not adopt.

##### Fit for this template
One capability, one production adapter, one fake. A fifth member for a single adapter file is
disproportionate; a facade module is not. The facade already holds `composition`, which is the
only place that adapter is constructed (R01), so the two travel together.

##### Recommendation
**Option 1: the production adapter lives in the facade `[lib]`, not in `crates/core`.** `core`
then contains models, ports, services, the error catalog and `InMemoryProjectsPort` and depends
on no HTTP client at all. "Adapters above services above models" becomes the facade → core crate
edge, compile-enforced. The residual models-below-services ordering *inside* `core` is carried by
module privacy plus R04's private-`mod` root barrel and is **not** compile-enforced as a
direction — recorded as the one honest gap, with `BASELINE-REVIEW: F006` above.

##### Ranked runner-up
Option 2, `crates/adapters` as a fifth member. Adopt it the moment a second production adapter
appears or a library consumer needs the real adapter without the facade's `clap` edge. The switch
is mechanical: move one module, add one manifest, add one `[dependencies]` line.

##### Tradeoffs
Option 1 puts the real adapter behind the facade, so a library consumer who wants it must depend
on `rs-launch-blueprint` (and therefore on `rs-launch-blueprint-cli` and `clap`). That is a real
cost, and it is the reason option 2 is ranked and not merely mentioned. Against it: one fewer
crates.io name, and the adapter sits next to the only code that constructs it. The gap on
models-vs-services is small at this size — `core` is a handful of modules — and R04's root barrel
already forces every cross-module name through one reviewed file.

##### Parameters
No owned parameter. `assumes http-transport-injection-seam` (R01): moving the production adapter
out of `core` is compatible with every clause of R01's value — the trait, the blanket `Arc<T>`
impl, `ProjectsService<P>`, the erasure at the root and the shipped `InMemoryProjectsPort` are all
unaffected, and R01 constrains only where the adapter is *constructed*. No `CONFLICT:` line;
R01 is recorded as a re-verify trigger because its `## Engines` list of what P03 must validate
assumed a single library crate.

##### Migration implications
`crates/core/src/` holds `models.rs`, `ports.rs`, `services/`, `errors.rs`, `in_memory.rs` and no
HTTP client dependency. The facade's `src/` gains `adapters/` (the `impl ProjectsPort for
HttpProjectsAdapter` item) beside `composition.rs`. The HTTP client crate moves from what would
have been `crates/core/Cargo.toml` to the root `[dependencies]`.

##### Validation strategy
Planned, not executed: a `compile_fail` doctest in `crates/core` naming the facade's adapter type
and expecting `E0433` — the same diagnostic case C4 produced for `composition`. Executed evidence
that the mechanism works: case C4. Also planned: `cargo tree -p rs-launch-blueprint-core -e normal`
printing a tree with no HTTP client in it; this run executed the command shape and it printed the
single line `rs-launch-blueprint-core v0.1.0 (…)` for a member with no dependencies.

##### Confidence & re-verify trigger
**Medium-high.** High that the adapters edge is right; medium that leaving models-vs-services to
module discipline is acceptable, because it is the only row where this stack is weaker than py's.
Re-verify when a second bounded context or a second adapter appears, when `cargo-bylaw` or another
intra-crate layer linter reaches meaningful adoption, when R28 publishes, or by 2027-03-17.

##### Sources
py at pin `b08bccfb`: `pyproject.toml:340-347`, `tach.toml`;
`https://raw.githubusercontent.com/regexident/cargo-modules/main/README.md` (2026-09-17, lines on
`--acyclic` and "Acyclic Mode"); `GET https://crates.io/api/v1/crates/cargo-modules` and
`/versions` (2026-09-17); `https://rustsec.org/packages/cargo-modules.html` → 404 (2026-09-17);
`GET https://api.github.com/search/repositories?q=archunit+language:rust&sort=stars` (2026-09-17);
`GET https://crates.io/api/v1/crates/archunit_rs` → `does not exist` (2026-09-17);
R01 `research/topics/01-ports-and-adapters-seam/DECISION.md` (`## Decision` table, F011/F013);
R04 `research/topics/04-public-api-surface-enforcement/DECISION.md` (`## Decision`).

#### Declared module/crate dependency graph (F010)

Settles what plays the part of `tach.toml`: the artifact that states which edges are permitted, and the check that fails when reality drifts from it.

##### Landscape
*Built-in/first-party*: the member `Cargo.toml` files themselves (the declaration);
`cargo metadata --format-version 1 --no-deps` (the machine-readable projection of it);
`cargo tree`. *Established standard*: `guppy` 0.18.0 (a `cargo metadata` graph library, the
substrate for custom dependency lints); `cargo-deny` `[bans]` (declares *forbidden* edges, not
permitted ones). *Up-and-comer*: none.

##### Principles and implementation
`tach.toml` declares, per module, the set it may depend on — an *allow-list*, checked. The
capability to preserve is "the permitted edges are written down in one artifact and drift from it
fails a check". Rust already has the artifact (the manifests) and a zero-cost projection of it
(`cargo metadata --no-deps`, `real 0.02` seconds, executed result 5). What it lacks is the
assertion that the projection equals the intent. `cargo-deny` cannot supply it: its
`[bans] deny`/`allow` lists are keyed on *crate names*, not on per-member permission sets, and
issue #891 ("Support per-layer (crate-group) dependency boundaries within a workspace", open since
2026-08-20) is that gap filed against the tool by a user with the same problem.

##### Dominant choice
None in the ecosystem: most workspaces treat the manifests as self-documenting and add no
assertion. The closest thing to a dominant *practice* is a repository-local check — `rust-analyzer`
runs an `xtask tidy` pass over manifests (`xtask/src/tidy.rs`, functions `check_cargo_toml`,
`check_licenses`, `check_test_attrs`, `check_trailing_ws`; **it does not check dependency
direction**, which this run verified by reading the file), and `guppy` exists because
Facebook/Diem needed exactly such a lint and had to build the substrate for it.

##### Qualified shortlist
(1) **A dependency-free `#[test]` in the facade's `tests/`** that shells out to
`env!("CARGO")` + `metadata --no-deps --format-version 1`, parses with `serde_json` (already in
the tree per R01's F018 selection of `serde_json` 1.0.151 at JSON boundaries), and asserts the
intra-workspace edge set equals a literal table. (2) **`guppy` 0.18.0** as the parsing substrate
instead of `serde_json`. (3) **No assertion at all**, relying on manifest review.

##### Excluded by gate
Gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`. **`guppy` 0.18.0 excluded on fit.** Figures: 90-day downloads **3,755,336**, all-time **16,373,986**
(`GET https://crates.io/api/v1/crates/guppy`, 2026-09-17); newest non-yanked **0.18.0**,
`created_at` **2026-08-25T23:55:19.890896Z**; licence `MIT OR Apache-2.0`; **`rust_version` 1.91**;
`guppy-rs/guppy` 288 stars, `archived: false`, `pushed_at` 2026-09-17T02:21:26Z, open issues **16**
(`GET https://api.github.com/search/issues?q=repo:guppy-rs/guppy+is:issue+is:open`); no RustSec page
(HTTP **404**); maintenance **active**. Gate 2 **passes**: 1.91 is below the current computed
floor of 1.96 — noted only because `guppy` would be a `[dev-dependencies]` entry that enters the
template's MSRV computation and moves on its own schedule. Gate 3: `unsafe` posture not asserted in the crate
root. Gate 4: no OS matrix asserted in the README. Gate 5: no default-feature or async coupling
declared for the parsing path used here. Gate 6: it is a substantial graph library, so it adds
measurable `cargo test` compile time for a job `serde_json` already does in twenty lines. **Fit**
is the deciding reason: the template's whole edge set is four rows.
`cargo-modules` is excluded here for the reason given under F006 (cycles, not direction).

##### Up-and-comers
None worth naming. `cargo-deny` issue #891 is the ecosystem's open request for a first-class
answer; if it ships, this member collapses into the F008 member.

##### Fit for this template
Four packages, four edge rows. A literal table in a test is more readable than any tool's config
would be, adds no dependency, runs inside `cargo test` (so it inherits whatever tier R32 sets),
and fails with a diff a contributor can act on.

##### Recommendation
A checked-in `tests/workspace_edges.rs` in the facade package asserting the exact intra-workspace
edge set produced by `cargo metadata --no-deps`, including dependency `kind` (so a
`[dev-dependencies]` back-edge cannot slip through) and `optional`. The expected table is the
declaration; `cargo metadata` is the observation; the test is the check. Shape:

```
rs-launch-blueprint       -> core, cli, web(optional)
rs-launch-blueprint-core  -> (none)
rs-launch-blueprint-cli   -> core
rs-launch-blueprint-web   -> core
```

The same test carries a second, external assertion: `crates/core`'s direct **external**
dependency set must equal an allow-list (`serde` today). This is not redundant with the F008
member — it is the mechanism for every framework `cargo-deny`'s `wrappers` cannot confine, because
`wrappers` is keyed on the banned crate and requires every direct dependent in the whole resolved
graph to be listed, which fails for a crate such as `tokio` that `axum`, `hyper`, `tower` and
`tokio-util` all depend on directly. An allow-list keyed on the *protected member* has no such
problem, and it also catches a framework nobody thought to ban.

##### Ranked runner-up
`guppy` 0.18.0 for the same test. Adopt if the workspace grows past roughly a dozen members, where
a hand-written table stops being the readable artifact and graph queries ("is anything reachable
from `core` outside this allow-list") start earning their dependency.

##### Tradeoffs
The test is bespoke code a template must carry and explain — about twenty lines plus the table.
It also runs against the *workspace*, so `cargo test -p rs-launch-blueprint-core` alone does not
exercise it; it must be in the facade's `tests/` and run by `cargo test --workspace`. Against
that: zero new dependencies, `real 0.02` seconds for the underlying command, and a failure message
that names the offending edge directly. The alternative — no assertion — is what most workspaces
do and is defensible, but it drops F010's declared-graph capability to "read the diff", which is
the convention tier F007 rejects.

##### Parameters
No owned parameter. `assumes http-transport-injection-seam` (R01) only in that `serde_json`
1.0.151 is already in the tree, so the test needs no new dependency. No `CONFLICT:` line.

##### Migration implications
New file `tests/workspace_edges.rs` (facade package), carrying both the intra-workspace edge table
and `crates/core`'s external dependency allow-list. No manifest change. Both tables are edited
whenever a member is added or an edge changes, which is the point.

##### Validation strategy
Executed: `cargo metadata --offline --format-version 1 --no-deps` on the probe workspace, `real
0.02`, output reproduced under executed result 5, including the `[opt]` marker on the web edge.
Planned, not executed: the assertion test itself, and its negative case (add
`rs-launch-blueprint-web` to `crates/cli/Cargo.toml` and observe the test fail rather than the
build — note that this particular violation *also* fails `cargo check`, so the test's unique value
is catching edges that compile, such as a new `[dev-dependencies]` back-edge).

##### Confidence & re-verify trigger
**High** that `cargo metadata --no-deps` is the right source (executed). **Medium** that a
bespoke test is the right container rather than a tool, because the ecosystem has no settled
answer. Re-verify when `cargo-deny` #891 ships, when the workspace passes a dozen members, when
R32 (`test-harness-and-execution`) publishes and fixes where this test runs, or by 2027-03-17.

##### Sources
`cargo metadata` output, executed 2026-09-17 (probe workspace);
`https://raw.githubusercontent.com/rust-lang/rust-analyzer/master/xtask/src/tidy.rs` (2026-09-17 —
read to confirm it contains no dependency-direction check);
`GET https://crates.io/api/v1/crates/guppy` and `/versions` (2026-09-17);
`GET https://api.github.com/repos/guppy-rs/guppy`, `GET https://api.github.com/search/issues?q=repo:guppy-rs/guppy+is:issue+is:open` (2026-09-17);
`https://rustsec.org/packages/guppy.html` → 404 (2026-09-17);
<https://github.com/EmbarkStudios/cargo-deny/issues/891> (2026-09-17);
py at pin `b08bccfb`: `tach.toml`;
R01 `research/topics/01-ports-and-adapters-seam/DECISION.md` (`serde_json` 1.0.151).

#### Framework-bleed guard, authoritative (F008)

Settles the one hole the compiler cannot close: a contributor adding a framework to the core member's `Cargo.toml`. This is the only member in the bundle that names an installed tool as its recommendation.

##### Landscape
*Built-in/first-party*: the dependency declaration itself — a crate that does not list `axum`
cannot `use` it (`E0432`/`E0433`, executed C1/C3/C4); `cargo tree -i <crate> -p <member>` as a
zero-install probe. *Established standard*: **`cargo-deny` 0.20.2** `check bans` with
`deny[].wrappers`. *Up-and-comer*: `cackle` 0.2.0 (per-crate API permissions — network, filesystem,
process — rather than per-crate dependency direction).

##### Principles and implementation
py's HEX-32 contract (`pyproject.toml:349-355` at pin `b08bccfb`) forbids `fastapi`, `click` and
`uvicorn` anywhere under `core`, with `include_external_packages = true` so `import-linter` can
name third-party modules. In the recommended topology the *code* half of that is already
impossible: `crates/core/Cargo.toml` names no framework, so `use axum::…` in `core` is `E0432`
before any tool runs. The only surviving hole is a contributor **adding the dependency to
`crates/core/Cargo.toml`** — a manifest edit, which no compiler diagnostic covers, since the
resulting code then compiles. That is precisely what this member guards, and it is the only job
left for a tool anywhere in this bundle.

##### Dominant choice
`cargo-deny`. `GET https://api.github.com/search/code?q=filename:deny.toml+path:/` → `total_count`
**14,912** (2026-09-17), and both `rust-lang/crates.io` (`deny.toml`, 11,979 bytes) and `jj-vcs/jj`
(11,197 bytes) ship one. It is the ecosystem's single dependency-policy tool; nothing else is
close.

##### Qualified shortlist
(1) **`cargo deny check bans`** with `deny = [{ crate = "axum", wrappers = ["rs-launch-blueprint-web"] }]`,
one entry per framework. (2) **A `cargo metadata`-driven assertion**, i.e. extend the F010 test to
assert `crates/core`'s *external* dependency set. (3) **`cargo tree -i <framework> -p rs-launch-blueprint-core`**
with the exit code inverted.

##### Excluded by gate
Gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`.
**`cackle` 0.2.0 — excluded on maintenance and fit.** 90-day downloads **39**, all-time **5,578**
(`GET https://crates.io/api/v1/crates/cackle`, 2026-09-17); newest non-yanked **0.2.0**,
`created_at` **2023-09-07T04:20:47.097079Z** — three years with no release; `cackle-rs/cackle`
285 stars, `archived: false`, `pushed_at` 2026-08-03T22:51:35Z, open issues **7**; licence recorded
as `MIT OR Apache-2.0` on crates.io while GitHub reports `NOASSERTION`; `rust_version` **1.67**;
no RustSec page (HTTP **404**); maintenance **at-risk** — the repository moves but the registry
does not, which is a concrete signal, not merely the six-month release trigger. Fit: it constrains
*what a crate may do* (net, fs, process), not *which crate a member may depend on*, so it does not
answer F008.
`cargo-machete` 0.9.2 (90-day **528,045**), `cargo-udeps` 0.1.61 (**140,740**), `cargo-shear`
1.13.4 (**52,419**) and `cargo-hakari` 0.9.38 (**91,575**) are **excluded on fit before any gate**:
they find unused or duplicated dependencies and shrink build times, and none can express "only
this member may depend on `axum`". `cargo-depgraph` 1.6.0 (**3,459**, last release
2023-12-07T17:35:58Z, `at-risk`) renders graphs and asserts nothing.

##### Up-and-comers
`cackle` is the only credible one and it answers a different question. Nothing else in the field.

##### Fit for this template
Three frameworks to confine at most — the CLI parser crate (R60: `clap`), `axum` and `tokio`
(R69) — so three `deny` entries. `cargo deny check bans` needs only a resolved `Cargo.lock`; the
advisory database, which is what makes `cargo deny check advisories` network-dependent, belongs to
a different subcommand and is R13's territory. The tool is a developer binary, never a template
dependency, so it adds nothing to the shipped artifact.

##### Recommendation
`cargo-deny` **0.20.2**, invoked as `cargo deny check bans`, configured in a repository-root
`deny.toml`:

```toml
[bans]
multiple-versions = "warn"
deny = [
  { crate = "axum", wrappers = ["rs-launch-blueprint-web"], reason = "core and the CLI are framework-agnostic (F008)" },
  { crate = "clap", wrappers = ["rs-launch-blueprint-cli", "rs-launch-blueprint"], reason = "argument parsing belongs to the CLI layer and to the serve binary's required global core (F008)" },
]
```

The semantics this relies on were read from the implementation, not only the prose: `src/bans.rs`
iterates `ctx.krates.direct_dependents(nid)` and requires **every direct dependent** of the banned
crate to appear in `wrappers`, emitting `BannedUnmatchedWrapper` plus `ExplicitlyBanned` otherwise.
So the entries above mean "only these packages may declare this crate directly"; the facade's
transitive reach through `rs-launch-blueprint-web` is not flagged. `clap` lists two wrappers
because R69 puts the `rslbp-serve` binary's required global core on the facade package.

**`tokio` deliberately has no row, and the reason generalizes.** "Every direct dependent" means
*every* direct dependent, workspace member or not — which is why `MystenLabs/walrus` needs three
chained entries (`openssl-sys` wrapped by `libssh2-sys`, `libssh2-sys` wrapped by `ssh2`, `ssh2`
wrapped by `walrus-orchestrator`) to confine one dependency. `axum` 0.8.9 depends on `tokio`
directly, and so do `hyper`, `hyper-util`, `tower` and `tokio-util`, so
`{ crate = "tokio", wrappers = ["rs-launch-blueprint-web"] }` would emit `BannedUnmatchedWrapper`
for each of them and fail a clean tree. `wrappers` is therefore usable only for a crate that
nothing else in the resolved graph depends on directly — true of `axum` here, false of `tokio`,
and **needing verification for `clap` once R60's selection resolves** (a companion such as
`clap_complete` would be a direct dependent and must be added to the wrapper list, or the row
dropped). The `tokio` case is the concrete reason the F010 member's assertion test should also
carry `crates/core`'s *external* dependency **allow-list**: an allow-list keyed on the protected
member handles `tokio` cleanly where `wrappers`, keyed on the banned crate, cannot.

##### Ranked runner-up
Shortlist option 2 — fold the external-dependency assertion into the F010 `cargo metadata` test.
It needs no tool, no `deny.toml` and no install step; it is the right answer if the owner decides
the template should add no developer binary for this; and it is **required regardless** for any
crate `wrappers` cannot express, `tokio` being the immediate example. What it gives up: `cargo-deny`'s
`reason` strings in the diagnostic, its `[bans.features]` table (which can additionally forbid a
feature, e.g. `tokio`'s `process`), and the `multiple-versions`/`wildcards` checks the same
invocation already performs. Option 3 (`cargo tree -i`) is third: this run observed that
`cargo tree -p rs-launch-blueprint-core -i axum` on a clean tree exits **101** with
`error: package ID specification `axum` did not match any packages`, so "clean" is a non-zero exit
and the check must invert it — workable, but a confusing thing to teach in a template.

##### Tradeoffs
Adds one contributor-installed binary and one config file. `wrappers` is keyed on the **banned
crate**, not on the protected member, so the list grows with the number of frameworks rather than
with the number of members, and a *new* framework added to `core` that nobody thought to ban is
not caught — the inverse (`[bans] allow` as a strict allow-list) exists but would have to
enumerate every transitive dependency of the whole workspace, which is not proportionate here.
`cargo-deny` issue #891 is the ecosystem's open request for the per-layer form that would close
this. The sharper limit is the one the `tokio` row exposes above: because `wrappers` is keyed on
the *banned* crate and demands that every direct dependent be listed, it cannot confine a crate
that other crates in the tree legitimately depend on. For those the F010 member's external
allow-list is the mechanism, so the two members are complementary rather than redundant. Cost of
the tool itself on the template: none; it compiles nothing into the artifact.

##### Parameters
No owned parameter. `assumes web-extra-surface` (R69) for the `axum`/`tokio` wrapper names and
`assumes` R60's CLI parser selection (`clap`) for the third entry. If R05 (`sync-async-execution-model`)
selects an async I/O boundary that puts `tokio` under `core`, the `tokio` row above must be dropped
or its wrapper list widened; that is a change to *this* recommendation, not to a consumed
parameter's value, so no `CONFLICT:` line is raised — it is recorded as a re-verify trigger.

##### Migration implications
New file `deny.toml` at the repository root with the `[bans]` section above (its `[licenses]`,
`[advisories]` and `[sources]` sections are R13's). New `lefthook` pre-push job and CI step
running `cargo deny check bans`. `CONTRIBUTING.md` gains the install line. Per R42's
`package-manager-invocation`, the tool is a crates.io-installed executable named `cargo-deny`, so
it is invoked as `cargo deny …` and its presence is tested with `command -v cargo-deny`.

##### Validation strategy
**Planned, not executed.** `cargo-deny` is not installed on this machine: `cargo deny --version`
→ ``error: no such command: `deny` ``, and this run did not install it, so no `cargo deny check
bans` result is reported. The check P03 must run: add `axum = "0.8.9"` to
`crates/core/Cargo.toml`, expect `cargo deny check bans` to exit non-zero naming
`rs-launch-blueprint-core` as an unmatched wrapper; remove it and expect exit 0. A second case
worth running: add it to `crates/core/[dev-dependencies]` instead, to establish whether the
default graph includes dev edges (it does unless `[graph] exclude-dev = true` is set) — this is
**unverified** here and P03 must confirm it. Also unmeasured: the wall-clock cost of
`cargo deny check bans` on a four-member workspace, which decides the F116 tier below; the F116
recommendation is written to be correct either way.

##### Confidence & re-verify trigger
**Medium-high.** High on the tool selection and on the `wrappers` semantics, which were read from
`src/bans.rs` rather than inferred from prose. Medium on the configuration, because it was not
executed. Maintenance **active**: newest non-yanked **0.20.2** `created_at`
**2026-07-09T17:58:09.303885Z**, `pushed_at` 2026-09-03T18:06:48Z, `archived: false`, 2,426 stars,
open issues **84**. Issue responsiveness, 10 most recently opened issues (#869 opened
2026-06-10T14:18:28Z through #898 opened 2026-09-16T16:58:47Z): **0 of 10 received a first
maintainer *comment***, but 5 of 10 were **closed**, with close lags of 0.01, 1.4, 5.0, 7.2 and
8.9 days (median **5.0 days**) — the maintainer fixes and closes rather than replying, so the
prompt's "unanswered" figure of 10 overstates the signal and both numbers are reported. Gate 2:
`rust_version` **1.88.0**, below the computed 1.96 floor, and it is an installed binary that never
enters the template's MSRV computation. Gate 3: no RustSec page
(`https://rustsec.org/packages/cargo-deny.html` → HTTP **404**); `unsafe` posture **not asserted**
— `src/lib.rs` carries no `#![forbid(unsafe_code)]`. Gate 4: its own
`.github/workflows/ci.yaml:61` runs the test matrix on `[ubuntu-24.04, macos-14]`, covering both
runners in `target-os-matrix`; the release job additionally builds `ubuntu-24.04-arm`,
`windows-2022` and `macos-14`. Gate 5: no async-runtime coupling reaches the template — it is
never a dependency. Gate 6: binary-size and compile-time cost to the template **nil**; CI cost is
one prebuilt-binary download plus one lockfile-only graph pass (unmeasured here).
Re-verify when: `cargo-deny` #891 ships a per-layer form; R05 places `tokio` under `core`; R13
(`dependency-vulnerability-scanning`) publishes and may already be installing `cargo-deny` for
`check advisories`, in which case this member costs zero extra install; R60's parser selection
changes; or by 2027-03-17.

##### Sources
`GET https://crates.io/api/v1/crates/cargo-deny` and `/versions?per_page=5` (2026-09-17);
`GET https://api.github.com/repos/EmbarkStudios/cargo-deny` and
`search/issues?q=repo:EmbarkStudios/cargo-deny+is:issue+is:open` (2026-09-17);
`GET https://api.github.com/repos/EmbarkStudios/cargo-deny/issues?state=all&sort=created&direction=desc`
plus per-issue `/comments` (2026-09-17);
`https://rustsec.org/packages/cargo-deny.html` → 404 (2026-09-17);
`https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/docs/src/checks/bans/cfg.md` (2026-09-17);
`https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/src/bans.rs` lines 248-280 and
600-660 (2026-09-17); `https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/.github/workflows/ci.yaml`
(2026-09-17); `https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/src/lib.rs` (2026-09-17);
`https://raw.githubusercontent.com/MystenLabs/walrus/main/deny.toml:91-93` (2026-09-17);
`GET https://api.github.com/search/code?q=filename:deny.toml+path:/` → 14,912 and
`?q=wrappers+filename:deny.toml` → 3,216 (2026-09-17);
`GET https://crates.io/api/v1/crates/{cackle,cargo-machete,cargo-udeps,cargo-shear,cargo-hakari,cargo-depgraph}` (2026-09-17);
py at pin `b08bccfb`: `pyproject.toml:318-355`.

#### Framework-bleed guard, fast local mirror (F009)

Settles the tier a contributor meets first. Two executed results decide it, one of which rules out a literal port of py's mechanism.

##### Landscape
*Built-in/first-party*: `cargo check` itself (a framework import in a member that does not declare
it is `E0432`/`E0433` in well under a second on an incremental tree); `clippy::disallowed_types`
and `clippy::disallowed_methods` configured by a **per-package** `clippy.toml`; `[workspace.lints]`
for the lint level. *Established standard*: none beyond clippy, which ships with rustup.
*Up-and-comer*: none.

##### Principles and implementation
py's fast tier is `src/py_launch_blueprint/core/ruff.toml` — a *subtree-scoped* config that
extends the root and adds `TID251` banned-api entries for `click`, `fastapi` and `uvicorn`, so a
stray import under `core/` is flagged at commit time while the authoritative `import-linter`
contract runs at pre-push. The capability to preserve is "a contributor learns about the violation
in seconds, not at push time". This run established two facts that decide the mechanism, and one
of them contradicts a naive port.

##### Dominant choice
Clippy, because it is the only per-package lint configuration Rust has and it ships with the
toolchain. There is no competing product.

##### Qualified shortlist
(1) **`crates/core/clippy.toml`** with `disallowed-types`/`disallowed-methods`, plus
`clippy::disallowed_types = "deny"` inherited from `[workspace.lints.clippy]`.
(2) **Nothing beyond `cargo check`**, on the argument that the crate split already makes the
import impossible.

##### Excluded by gate
Gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Gates 2–6 are `inapplicable`:
clippy is a rustup component, not a crates.io crate — it has no `recent_downloads`, no independent
release cadence, no RustSec page, no default features, no async coupling and no effect on the
shipped binary's size. Per R42's `package-manager-invocation` its presence is tested with
`rustup component list --installed`, never `command -v`.
**Excluded on evidence, not on a gate: a subtree-scoped clippy config.** A `clippy.toml` at
`src/clippy.toml` was **ignored** — the same `HashMap` uses that a package-root `clippy.toml`
flagged three times produced **zero** `disallowed_types` diagnostics. py's mechanism does not port.
**Excluded on correctness: a package-root `clippy.toml` in a single-package template.** It flagged
`src/core_layer.rs` *and* `src/cli_layer.rs`, so it cannot ban `clap` in the core without banning
it in the CLI.

##### Up-and-comers
None. `CLIPPY_CONF_DIR` exists as an override but is an environment variable, not a per-subtree
mechanism.

##### Fit for this template
With the recommended split, this tier is *mostly already free*: `cargo check` rejects a framework
`use` in `core` with `E0433` (executed C1/C3/C4), and every contributor runs `cargo check`
continuously. The `clippy.toml` adds the case the compiler cannot state — a *type* or *method*
that is reachable through an allowed dependency but does not belong in the core, for example
`std::process::Command` or a blocking call — and it gives the diagnostic a human `reason` string
pointing at the rule.

##### Recommendation
`crates/core/clippy.toml` scoped to the core member only:

```toml
disallowed-types = [
  { path = "std::process::Command", reason = "core is I/O-framework-agnostic; spawn from an adapter (F009)" },
]
disallowed-methods = [
  { path = "std::thread::sleep", reason = "core must not block; timing belongs to an adapter (F009)" },
]
```

with `[workspace.lints.clippy] disallowed_types = "deny"`, `disallowed_methods = "deny"` at the
root and `[lints] workspace = true` in each member, so the level is declared once. The file lives
beside `crates/core/Cargo.toml` because clippy resolves its configuration from `CLIPPY_CONF_DIR`
or the package's manifest directory. Framework *crates* need no entry here — they are unreachable
from `core` by construction and are guarded at the manifest tier by F008.

##### Ranked runner-up
Shortlist option 2: no `clippy.toml` at all, letting `cargo check` be the whole fast tier. It is
honest and costs nothing, and it is the right answer if the owner wants zero extra config files.
What it gives up is the ability to ban a *type* rather than a crate, which is the only part of
py's TID251 list that has no compiler equivalent.

##### Tradeoffs
One more config file, and one that only works because the split exists — which makes this member a
dependent of the topology decision rather than an independent choice. Clippy's `disallowed-types`
matches on path, so a re-export can evade it; that is a known and acceptable limit for a fast
mirror whose authoritative counterpart is the manifest guard. The rule list must be kept
non-empty to be worth its file; three or four entries is the right size.

##### Parameters
No owned parameter. `assumes package-manager-invocation` (R42): clippy is a rustup component, so
it is invoked as `cargo clippy` and probed with `rustup component list --installed`. No
`CONFLICT:` line. R28 (`linter-and-editor-tooling`, open) owns the clippy configuration surface
and must accommodate a per-member `clippy.toml` — recorded in the `BASELINE-REVIEW: F009` line.

##### Migration implications
New file `crates/core/clippy.toml`. Root `Cargo.toml` gains `[workspace.lints.clippy]` entries;
each member gains `[lints] workspace = true` (the same three lines the R04 lints need, so the cost
is shared).

##### Validation strategy
Executed in this run, three cases: package-root `clippy.toml` flags every layer of the package
(three `error: use of a disallowed type` sites across `core_layer.rs` and `cli_layer.rs`);
`src/clippy.toml` is ignored (zero diagnostics); `crates/core/clippy.toml` under
`cargo clippy --workspace` flags only `crates/core/src/lib.rs` (three sites, ending
`error: could not compile `rs-launch-blueprint-core` (lib) due to 3 previous errors`) and leaves
the identical use in `crates/cli/src/lib.rs` untouched. Also executed: `[workspace.lints.rust]
unreachable_pub = "deny"` inherited by `[lints] workspace = true` produced ``error: unreachable
`pub` item`` in a member. Planned for P03: the real rule list, and a fixture proving each entry
fires.

##### Confidence & re-verify trigger
**High** — three executed cases, including the negative one that rules out py's mechanism.
Re-verify when R28 publishes, when clippy gains subtree-scoped configuration (watch
<https://doc.rust-lang.org/clippy/configuration.html>), when R05 changes what "must not block"
means in `core`, or by 2027-03-17.

##### Sources
Executed probes, 2026-09-17, `clippy 0.1.98` on `rustc 1.98.0`;
Clippy book, *Configuration* <https://doc.rust-lang.org/clippy/configuration.html> (2026-09-17);
py at pin `b08bccfb`: `src/py_launch_blueprint/core/ruff.toml:1-20` (the header states its own
role: "import-linter is the authoritative framework-bleed check … This nested config is the fast
first line … scoped to this subtree because ruff's banned-api is otherwise global");
R42 `docs/port/PARAMETERS.md` (`package-manager-invocation`).

#### Boundary-check hook and CI tier placement (F116)

Settles where each of the checks above runs in the hook and CI pipeline, and deliberately does not settle job-versus-step shape, which is R11's.

##### Landscape
*Built-in/first-party*: the compiler tier — `cargo check` / `cargo clippy`, which every
contributor runs continuously and which already carries F003/F004/F005 and half of F009.
*Established standard*: `lefthook` pre-commit and pre-push stages; a GitHub Actions job.
*Up-and-comer*: none.

##### Principles and implementation
py splits the tiers because its authoritative check is slow: `import-linter` and `tach` build the
whole import graph and run at pre-push (`lefthook.yml:170-177` at pin `b08bccfb`, jobs
`import-boundaries` → `uv run lint-imports` and `module-boundaries` → `uv run tach check`, both
under the pre-push stage, with the comment "At pre-push (not pre-commit) since it builds the whole
import graph"), while `ruff` TID251 runs at pre-commit. CI carries the authoritative copy as a
dedicated `import-boundaries` job (`.github/workflows/ci.yml:118-134`, `needs: changes`,
`if: needs.changes.outputs.code == 'true'`, running both tools), which is also a member of the
aggregate required check (`ci.yml:275`). The capability to preserve is **two tiers plus an
authoritative CI copy**, not the specific stage names.

##### Dominant choice
In Rust the fast tier is the compiler, and no project tiers it anywhere else. What varies across
projects is where `cargo deny` sits; CI is the near-universal answer.

##### Qualified shortlist
(1) **Compiler tier continuous; `cargo deny check bans` + the F010 test at pre-push and CI**
(py's tier, translated). (2) **Everything at pre-commit**, on the argument that a four-member
workspace checks in under a second. (3) **CI only**, no hook.

##### Excluded by gate
Gate 1 (licence): `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Gates 2–6 are `inapplicable`:
a tier placement is a policy, not a crate — it has no registry entry, MSRV, advisory page,
platform matrix, feature set or build cost. Option 3 (CI only) is excluded on **fit**: it drops
the local tier py's F009/F116 pair exists to provide, so a contributor learns at push time what
the compiler could have told them at edit time. Option 2 is excluded on **evidence not gathered**:
`cargo deny check bans` was not timed in this run (the tool is not installed), so placing an
unmeasured command at pre-commit would be an unsupported estimate.

##### Up-and-comers
None.

##### Fit for this template
Rust inverts py's cost structure. py's *fast* tier is a linter and its *slow* tier is the graph
builder; here the fast tier is the compiler, which is faster and more authoritative than either py
tool, and the slow tier is a lockfile pass. The two-tier capability is preserved, and the tiers
are better than py's — a justified ecosystem difference, not a gap.

##### Recommendation
Three placements:

| Check | Tier | Why |
|---|---|---|
| `cargo check --workspace` / `cargo clippy --workspace` (carries F003, F004, F005, F006's crate edge, and the `clippy.toml` half of F009) | **Continuous** — the contributor's own edit loop, plus whatever pre-commit stage R28/R37 already give clippy | It is the build. `cargo check -p rs-launch-blueprint-core` measured `real 0.12` seconds from clean on the probe workspace |
| `cargo deny check bans` (F008) | **pre-push + CI**, mirroring py's `import-boundaries` placement exactly | It reads the resolved `Cargo.lock`, which is a repository-level artifact, not a per-file one; and its cost is unmeasured here, so the conservative tier is correct |
| `tests/workspace_edges.rs` (F010) | **wherever `cargo test --workspace` runs** — pre-push + CI on py's pattern | It is an ordinary test and should not need its own tier |

In CI these belong to one job, on the model of py's single `import-boundaries` job running both
tools. Whether that job is separate or a step inside a shared job, and how it is path-skip-gated,
is R11's `ci-job-structure` and is *not* decided here. Membership of the aggregate required check
is R12's.

##### Ranked runner-up
Move `cargo deny check bans` to pre-commit once P03 measures it under roughly one second on this
workspace. The reason to prefer it then: a manifest edit is exactly the kind of change a
contributor makes and forgets, and pre-commit is where the `Cargo.toml` diff is in front of them.
The reason not to do it now: no measurement exists.

##### Tradeoffs
Pre-push means a contributor can commit a `crates/core/Cargo.toml` edit that adds `axum` and only
learn at push. That window is the same one py accepts for `import-linter`, and it is narrower
here because the *code* that would use the new dependency still has to be written and will be
reviewed. Running `cargo deny` at pre-commit instead would close the window at the cost of an
unmeasured per-commit command. CI is non-negotiable in either case: it is the only tier a
contributor cannot skip with `--no-verify`.

##### Parameters
No owned parameter. `assumes ci-job-structure` (R11, unresolved — its `PARAMETERS.md` value is
`—`): this member names *which tier* the check runs at and deliberately does not decide whether it
is its own job or a step, nor the path-filter shape. That is a dependency on an unresolved
parameter, not a conflict with one, so no `CONFLICT:` line is raised. `assumes
package-manager-invocation` (R42) for the `cargo deny` invocation form. R37
(`hook-manager-distribution`, open) owns the lefthook wiring.

##### Migration implications
`lefthook.yml` gains a pre-push job running `cargo deny check bans`. `.github/workflows/ci.yml`
gains the same command in the boundary job R11 shapes. No pre-commit entry is added for it. The
compiler tier needs no new wiring — it rides whatever `cargo clippy` job R28 and R37 already
place.

##### Validation strategy
Executed: `cargo check --offline -p rs-launch-blueprint-core` from clean, `real 0.12` seconds
(`user 0.05`, `sys 0.04`) on a member with no dependencies — an unrepresentative floor, quoted
only to establish that the compiler tier is not the bottleneck. `cargo metadata --no-deps`,
`real 0.02` seconds. **Not executed and required before the tier is final:** `cargo deny check
bans` wall-clock on a four-member workspace with `axum`, `tokio` and `clap` resolved, on both
`ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger
**Medium-high.** High that the compiler tier is continuous and that CI must carry the manifest
guard; medium on pre-push versus pre-commit, which turns on a measurement this run could not take.
Re-verify when P03 measures `cargo deny check bans`; when R11 and R37 publish; when R13 publishes,
since it may already run `cargo deny` at some tier and the two invocations should share one
install and possibly one job; or by 2027-03-17.

##### Sources
py at pin `b08bccfb`: `lefthook.yml:170-177`, `.github/workflows/ci.yml:118-134,275-280`,
`docs/adr/0017-hexagonal-core-and-boundary-enforcement.md:38-44`; executed timings 2026-09-17
(`cargo 1.98.0`, macOS, probe workspace); `docs/port/PARAMETERS.md` (`ci-job-structure`,
`package-manager-invocation`); `docs/port/COMMONALITY.md` F116.

### Compatibility

The six members are not six independent products — four of them are first-party toolchain
behavior (workspace topology, `cargo metadata`, clippy, tier placement) and only one is an
installed tool (`cargo-deny`). "Tested together" therefore means three things:

**1. An executed version matrix, this run.** Every mechanism except `cargo deny check bans` was
exercised *in one workspace at one toolchain version*: `cargo 1.98.0 (797e8a9bc 2026-08-05)`,
`rustc 1.98.0 (88d9e12ae 2026-08-18)`, `clippy 0.1.98`, edition `2024` (whose default resolver is `3`; the probe manifest did not write
`resolver` explicitly, so the value was implied, not exercised as a written field), macOS arm64, `--offline`, zero external dependencies. In that single workspace the root-package shape,
`[workspace.package]` inheritance, `[workspace.lints]` inheritance, the optional-dependency `web`
feature, `[[bin]] required-features`, the four boundary compile failures, the per-member
`clippy.toml` scoping, and `cargo metadata --no-deps` all held simultaneously. Nothing in the set
required a version any other member did not already have.

**2. A shared adopter for the pair that is not first-party.** `MystenLabs/walrus` (417 stars,
`pushed_at` 2026-09-17T04:57:46Z, `archived: false`) runs `cargo-deny` `bans` `wrappers` over a
multi-member Cargo workspace — the exact combination of member 1 and member 4 —
`deny.toml:91-93`: `{ name = "ssh2", wrappers = ["walrus-orchestrator"] }` confining an I/O
dependency to one member. `rust-lang/crates.io` and `jj-vcs/jj` both pair a multi-member workspace
with a root `deny.toml` (11,979 and 11,197 bytes), though both keep the `wrappers` line commented
out as the upstream template default, so they evidence the pairing and not the usage.

**3. Version compatibility of the one installed tool.** `cargo-deny` 0.20.2 declares
`rust_version = 1.88.0` and its own CI matrix is `[ubuntu-24.04, macos-14]`
(`.github/workflows/ci.yaml:61`), covering both runners in `target-os-matrix`. It reads
`Cargo.lock` and `cargo metadata`, both of which this run produced at Cargo 1.98.0 under
edition 2024's implied resolver 3; **that specific pairing was not executed** because the tool is not installed
here, and it is listed under *Validation strategy* as a P03 check.

**4. Compatibility with the published decisions.** R49's every field and R69's every field land
on the root package unchanged (see *Parameters*); R04's three `deny` lints reach all four members
through `[workspace.lints]`, executed; R01's seam is unaffected except for where the production
adapter is defined. Nothing in this stack requires any of the four to change a value.

### Parameters

This item's `- owns:` line in the prompt is empty, so there are no `owns` lines.

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes license = MIT OR Apache-2.0
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes build-tool-output-shape = R49's published value, unchanged. The root-package workspace preserves it clause by clause: one `[lib]` at `src/lib.rs` named `rs_launch_blueprint`; one `[[bin]]` at `src/main.rs` named `rslbp` so `cargo install rs-launch-blueprint` installs `rslbp` and `CARGO_BIN_EXE_rslbp` resolves; `autobins = false`; `default-run` unset while one binary exists (R69's `rslbp-serve` is feature-gated and skipped unless `web` is on, which this run verified); no `build.rs` and no build-orchestration crate (which is why the F010 guard is an ordinary `tests/` file and not an `xtask` member); artifacts in the workspace-root `target/`, which is where a workspace puts them by definition; and the `include` allow-list `["/src", "/README.md", "/LICENSE-MIT", "/LICENSE-APACHE", "/CHANGELOG.md"]`, whose paths are package-relative to the repository root and which needs no `crates/` exclusion because the Cargo Book states sub-packages are always skipped.
- assumes web-extra-surface = R69's published value **with the amendment in the `CONFLICT:` line below**. The deferral R69 left open is answered: the `web` feature is declared on **the root package `rs-launch-blueprint`**, which is the crate that hosts the binary targets. R69's `[[bin]] required-features = ["web"]` and the feature it names are then on the same package. The Cargo Book's `required-features` passage states only that a target is skipped when its required features are not enabled; that a target's `required-features` can name only its own package's `[features]` keys is an **inference** from Cargo's per-package feature namespacing, corroborated by this run's probe, in which the root package declared both.
- assumes http-transport-injection-seam = R01's published value, unchanged. One clarification this stack forces, which changes no clause of the value: the port trait, `ProjectsService<P>`, the blanket `impl ProjectsPort for Arc<T>` and `InMemoryProjectsPort` live in `rs-launch-blueprint-core`; the composition root (`build_projects_service`, `production_service`) and the production adapter live in the root package.
- assumes package-manager-invocation = R42's published value, unchanged: `cargo deny check bans` (a crates.io-installed executable named `cargo-deny`, probed with `command -v cargo-deny`), `cargo clippy` and `cargo metadata` (toolchain, clippy probed with `rustup component list --installed`).
- assumes ci-job-structure = unresolved (R11). This item names the *tier* for each check and leaves job-versus-step and path-filtering to R11.
- assumes commit-message-convention, error-taxonomy-exit-codes, logging-pipeline-contract = not consumed by this item.

**One `CONFLICT:` line is raised, for R69.** R69 pre-declared R02 as the item that decides which
crate hosts the feature and recorded R02 as its own re-verify trigger, so this is the answer it
asked for rather than a departure — but R69's published value also fixes the feature's *body*
(`web = ["dep:axum", "dep:tokio"]`, "the library module `src/web/`", "the web integration tests,
gated file-level with `#![cfg(feature = "web")]`") in terms that assume the frameworks are
dependencies of the declaring package. Under a workspace they are dependencies of `crates/web`.
That is a consumed value needing to change, so it is surfaced in the required form:

CONFLICT: R69 web-extra-surface — `web = ["dep:rs-launch-blueprint-web"]` declared on the root package `rs-launch-blueprint`, with `axum` 0.8.9 and `tokio` 1.53.1 declared non-optionally in `crates/web/Cargo.toml` (feature list unchanged), the gated tree reading `crates/web/src/` rather than `src/web/`, the web integration tests living in `crates/web/tests/` with no file-level `#![cfg(feature = "web")]` needed because the whole member is optional, and `tower` 0.5.3 as `crates/web`'s dev-dependency — reason: the recommended multi-crate topology moves `axum` and `tokio` out of the declaring package, so the feature can only name the optional member; every other clause of R69's value (the four gated things, the `[[bin]] <app>-serve required-features = ["web"]` shape, the exit integers, the `otel`/`metrics` nesting, the skip-gating keys, `bacon` as a non-dependency) is preserved verbatim, with the skip-gating paths reading `crates/web/**` instead of `src/web/**`.

Three further items are recorded as **re-verify** rather than conflict, because their *values* do
not change but their reasoning was written assuming one crate:

- **R67 (`error-taxonomy-exit-codes`)** says "`thiserror` in the library crate, `anyhow` in binary
  crates only; the library crate must not depend on `anyhow`". Under this topology
  `rs-launch-blueprint-core`, `-cli` and `-web` are all library crates and none may depend on
  `anyhow`; the *root package* declares `anyhow` and uses it only inside `src/main.rs` and
  `src/bin/serve.rs`, because Cargo has no per-target dependency table. R67's rule is satisfiable
  in substance but its phrase "the library crate" needs a topology-aware reading, and the root
  package's `[lib]` must keep `anyhow` out of every public signature — which R04's
  `private_interfaces`/`private_bounds` denials already enforce.
- **R04 (`public-api-surface-enforcement`)** already lists "R02 selects a multi-crate topology" as
  one of its own re-verify triggers. Two published crates now carry a public surface
  (`rs-launch-blueprint-core` and `rs-launch-blueprint`), so the root-barrel rule and the
  `cargo-semver-checks` gate apply to both; `[workspace.lints]` carries the three `deny`
  attributes to every member from one place (executed).
- **R49 (`build-target-declaration`)** pre-authorized this outcome — "the selection is
  shape-neutral: if R02 chooses a workspace, every field above moves to the member manifests
  unchanged" — and records R02 resolving to a workspace as its own re-verify trigger. The
  root-package shape means nothing has to move at all.

### Migration implications

File-level changes in the template, all proposed (no template exists; P03 builds it):

| Path | Change |
|---|---|
| `Cargo.toml` | Gains `[workspace] members = ["crates/*"]`, `resolver = "3"`, `[workspace.package]` (version, edition, rust-version, license), `[workspace.lints.rust]` and `[workspace.lints.clippy]`, and three path+version dependencies. Keeps `[package] rs-launch-blueprint`, `[lib] src/lib.rs`, `[[bin]] rslbp src/main.rs`, `autobins = false` and the `include` allow-list exactly as R49 states them. Gains `[[bin]] rslbp-serve` with `required-features = ["web"]` and `[features] web = ["dep:rs-launch-blueprint-web"]` per R69 |
| `src/lib.rs` | The facade: R04's private-`mod` root barrel plus `pub use` of `rs_launch_blueprint_core`'s sanctioned names, `mod composition;`, `mod adapters;` and `#[cfg(feature = "web")]` re-exports |
| `src/main.rs` | Calls `composition::production_service()`, hands the erased service to `rs_launch_blueprint_cli`, returns `ExitCode` per R67 |
| `src/bin/serve.rs` | Same for `rs_launch_blueprint_web` (new; R69's `<app>-serve`) |
| `crates/core/Cargo.toml` | New. `rs-launch-blueprint-core`, all four `[workspace.package]` fields inherited, `[lints] workspace = true`, dependencies: `serde` only (per R01 F018). **No `clap`, `axum`, `tokio`, HTTP client or `anyhow`** |
| `crates/core/src/` | New. `lib.rs` (root barrel), `models.rs`, `ports.rs`, `services/`, `errors.rs`, `in_memory.rs` |
| `crates/core/clippy.toml` | New. `disallowed-types` / `disallowed-methods` scoped to the core member (F009) |
| `crates/cli/Cargo.toml`, `crates/cli/src/` | New. `rs-launch-blueprint-cli`; depends on `core` and on R60's parser crate. Never on `web` |
| `crates/web/Cargo.toml`, `crates/web/src/` | New. `rs-launch-blueprint-web`; depends on `core`, `axum` and `tokio` per R69. Never on `cli`. Optional at the facade, so it does not compile unless `--features web` |
| `deny.toml` | New at the repository root. `[bans]` section with one `deny` entry per framework carrying `wrappers` and `reason` (F008). Its `[licenses]`, `[advisories]` and `[sources]` sections are R13's |
| `tests/workspace_edges.rs` | New in the root package. Asserts the `cargo metadata --no-deps` intra-workspace edge set, with `kind` and `optional`, equals a literal table (F010) |
| `lefthook.yml` | New pre-push job `cargo deny check bans` (F116). No pre-commit entry for it |
| `.github/workflows/ci.yml` | The boundary check joins the job R11 shapes; the runner installs `cargo-deny` |
| `CONTRIBUTING.md` / `README.md` | The four-crate map, the rule that `core` may not depend on anything above it, and the `cargo-deny` install line |
| **Not added** | `tach.toml` or any analogue; `import-linter`-style config; an `xtask` member (R49 forbids a build-orchestration crate); a nested `src/rs_launch_blueprint/` package directory (F020: crates are namespaced by `Cargo.toml` `name`); `publish = false` on any member (R04 case 11 proves it makes the facade unpublishable) |

### Validation strategy

**Executed in this run** — throwaway workspace under `$TMPDIR`, created and deleted within the run,
`cargo 1.98.0` / `rustc 1.98.0` / `clippy 0.1.98`, macOS arm64, `--offline`, no external crates:

| # | Command | Expected | Observed |
|---|---|---|---|
| A | `cargo build --offline` on a single package where `core_layer` does `use crate::cli_layer::CliThing;` | should fail if module visibility enforced direction | **Compiled clean**, `Finished `dev` … in 0.19s`. Single-package enforcement disproved |
| B1 | `cargo build --offline` (workspace baseline) | 3 packages, web skipped | `Finished `dev` … in 0.67s`; `rs-launch-blueprint-web` absent |
| B2 | `cargo build --offline --features web` | web member added | `Compiling rs-launch-blueprint-web`, `Finished … in 0.83s` |
| C1 | `core` calls `rs_launch_blueprint_cli::run()` | build error | ``error[E0433]: cannot find module or crate `rs_launch_blueprint_cli` in this scope`` |
| C2 | `crates/core/Cargo.toml` adds the `cli` path dependency | resolution error | ``error: cyclic package dependency: package `rs-launch-blueprint-cli v0.1.0 (…)` depends on itself. Cycle:`` |
| C3 | `cli` calls `rs_launch_blueprint_web::router()` | build error | ``error[E0433]: cannot find module or crate `rs_launch_blueprint_web` in this scope`` |
| C4 | `core` calls `rs_launch_blueprint::composition::production_service()` | build error | ``error[E0433]: cannot find module or crate `rs_launch_blueprint` in this scope`` |
| C5 | restore baseline | clean build | `Finished `dev` … in 1.04s` |
| D1 | package-root `clippy.toml` banning `std::collections::HashMap` | flags core only? | flags **both** `src/core_layer.rs` and `src/cli_layer.rs`, 3 sites |
| D2 | `src/clippy.toml` (nested subtree, py's shape) | py-equivalent scoping | **0 diagnostics** — nested config ignored |
| D3 | `crates/core/clippy.toml` + `cargo clippy --workspace` | flags core only | 3 sites, all in `crates/core/src/lib.rs`; `crates/cli/src/lib.rs` untouched |
| E | `[workspace.lints.rust] unreachable_pub = "deny"` + `[lints] workspace = true` | member inherits | ``error: unreachable `pub` item`` in `crates/core/src/lib.rs` |
| F | `cargo metadata --offline --format-version 1 --no-deps` | full edge set | 4 rows including `rs-launch-blueprint-web[opt]`; `real 0.02` |
| G | `cargo check --offline -p rs-launch-blueprint-core` from clean | timing floor | `Finished … in 0.10s`; `real 0.12 user 0.05 sys 0.04` |
| H | `cargo tree --offline -p rs-launch-blueprint-core -i axum` | probe the fallback | exit **101**, `error: package ID specification `axum` did not match any packages` — "clean" is a non-zero exit, so the check must invert it |

**Planned, not executed** (P03's, and every one is a stated requirement rather than a result):

1. `cargo deny check bans` exits non-zero when `axum` is added to `crates/core/Cargo.toml`, and
   zero when it is not. **`cargo-deny` is not installed on this machine** (`cargo deny --version`
   → ``error: no such command: `deny` ``) and this run did not install it.
2. The same, with the dependency added to `crates/core/[dev-dependencies]` — establishes whether
   the default `cargo-deny` graph includes dev edges. **Unverified.**
3. Wall-clock cost of `cargo deny check bans` on the real four-member workspace, on
   `ubuntu-latest` and `macos-latest`. It decides whether F116's manifest tier can move from
   pre-push to pre-commit. **Unmeasured.**
4. `tests/workspace_edges.rs` fails on a changed edge set. The command it wraps is verified (F);
   the test is not written.
5. `cargo publish --dry-run` for `rs-launch-blueprint-core`, `-cli`, `-web` and the facade in
   dependency order. Requires the crates.io index; **not attempted**.
6. The four boundary violations as `compile_fail` doctests or `trybuild` fixtures, so
   `cargo test` — not just a contributor's memory — proves the boundary still holds.
7. A repeat of cases C1–C5 and D3 on `ubuntu-latest`, and at the MSRV floor. This run is macOS and
   1.98.0 only; nothing here is version-sensitive in an obvious way, but that is an expectation,
   not a measurement.

### Confidence & re-verify trigger

**High** on the central claim — question 1's answer is that only a genuine multi-crate workspace
makes an illegal dependency a build-breaking error, and it rests on five executed compile results
(A, C1–C4), not on argument. **High** on F009's mechanism, which rests on three executed clippy
cases including the negative one (D2) that rules out a literal port of py's config. **High** on
F010's source artifact (F). **Medium-high** on F008: the tool choice is well evidenced and its
`wrappers` semantics were read from `src/bans.rs` rather than from prose, but no `cargo deny`
invocation was executed. **Medium-high** on F006, the one row where this stack is weaker than py's
and where the recommendation (adapter in the facade, models-vs-services by module discipline) is a
judgement about proportionality rather than a measurement. **Medium** on F116's pre-push-versus-
pre-commit line, which turns on an unmeasured timing. **Medium** on the member *count*: four is
the minimum, and a second bounded context or adapter should promote `crates/adapters` to a fifth.

Re-verify when any of these happens, or by **2027-03-17**, whichever comes first:

- the owner rules on the `OVERRIDE (OV-nn)` for F021, or declines the split — in which case
  F003–F009 fall back to convention and this whole answer is rewritten;
- `cargo-deny` issue #891 (per-layer crate-group boundaries) ships, which would collapse members 3
  and 4 into one config;
- a maintained intra-crate layer-contract linter appears (watch `danielgerlag/cargo-bylaw`), which
  would reopen alternative B and with it F006;
- **R05** (`sync-async-execution-model`) places `tokio` under `core`, invalidating the `tokio`
  wrapper row in `deny.toml`;
- **R11** (`ci-job-structure`) or **R37** (`hook-manager-distribution`) publishes, fixing the job
  and hook wiring this item only names a tier for;
- **R13** (`dependency-vulnerability-scanning`) publishes — if it already installs `cargo-deny`
  for `check advisories`, member 4 costs zero extra install; if it selects `cargo-audit` instead,
  the install is this item's to justify. The two subcommands are independent, so neither choice
  conflicts;
- **R28** (`linter-and-editor-tooling`) publishes and must accommodate a per-member `clippy.toml`;
- **R60**'s CLI parser selection moves off `clap`, changing one `deny.toml` row;
- **R68** (`release-binary-artifacts`) or **R23**/**R24**/**R25** publishes and fixes the
  multi-package publish and version-lockstep mechanics that are this recommendation's main cost;
- a second bounded context, a second production adapter, or a second installable binary appears.

### Sources

**Normative Rust and Cargo references** (all retrieved 2026-09-17):
Cargo Book *Workspaces* <https://doc.rust-lang.org/cargo/reference/workspaces.html> —
root package vs. virtual manifest, `[workspace.package]`, `[workspace.lints]`, shared `Cargo.lock`
and `target/`.
Cargo Book *The Manifest Format* <https://doc.rust-lang.org/cargo/reference/manifest.html> —
`include`/`exclude`, "Any sub-packages will be skipped (any subdirectory that contains a
`Cargo.toml` file)".
Cargo Book *Cargo Targets* <https://doc.rust-lang.org/cargo/reference/cargo-targets.html> —
`required-features`.
Cargo Book *Specifying Dependencies*
<https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html> — "Crates that use
dependencies specified with only a `path` are not permitted on crates.io"; the `path` + `version`
pair; "crates.io does not allow packages to be published with dependencies on code outside of
crates.io, except for dev-dependencies".
The Rust Reference *Visibility and Privacy*
<https://doc.rust-lang.org/reference/visibility-and-privacy.html>.
Clippy book *Configuration* <https://doc.rust-lang.org/clippy/configuration.html>.

**Tool documentation and source** (2026-09-17):
`https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/docs/src/checks/bans/cfg.md`;
`https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/src/bans.rs` (lines 248-280,
600-660 — `direct_dependents`, `BannedUnmatchedWrapper`, `ExplicitlyBanned`);
`https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/.github/workflows/ci.yaml`;
`https://raw.githubusercontent.com/EmbarkStudios/cargo-deny/main/src/lib.rs`;
<https://github.com/EmbarkStudios/cargo-deny/issues/891>;
`https://raw.githubusercontent.com/regexident/cargo-modules/main/README.md`;
`https://raw.githubusercontent.com/jj-vcs/jj/main/Cargo.toml`;
`https://raw.githubusercontent.com/rust-lang/crates.io/main/deny.toml`;
`https://raw.githubusercontent.com/jj-vcs/jj/main/deny.toml`;
`https://raw.githubusercontent.com/MystenLabs/walrus/main/deny.toml`;
`https://raw.githubusercontent.com/rust-lang/rust-analyzer/master/xtask/src/tidy.rs`.

**Figure endpoints** (all 2026-09-17):
`GET https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads`, `crate.downloads` for
`cargo-deny`, `cargo-modules`, `guppy`, `cackle`, `cargo-machete`, `cargo-hakari`, `cargo-shear`,
`cargo-udeps`, `cargo-depgraph`, `archunit_rs`.
`GET https://crates.io/api/v1/crates/<name>/versions?per_page=5` → newest `yanked: false` `num`,
`created_at`, `license`, `rust_version`.
`GET https://api.github.com/repos/<o>/<r>` → `stargazers_count`, `archived`, `pushed_at`.
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`.
`GET https://api.github.com/repos/EmbarkStudios/cargo-deny/issues?state=all&sort=created&direction=desc&per_page=30`
plus per-issue `/comments` → issue responsiveness.
`GET https://api.github.com/repos/<o>/<r>/contents/crates` → member counts.
`GET https://api.github.com/search/code?q=filename:deny.toml+path:/` → 14,912;
`?q=wrappers+filename:deny.toml` → 3,216.
`GET https://api.github.com/search/repositories?q=archunit+language:rust&sort=stars`.
`GET https://crates.io/api/v1/crates?q=<terms>&per_page=10` for `architecture+boundary`,
`module+dependency+graph`, `layer+architecture+lint`, `import+linter`.
`https://rustsec.org/packages/<name>.html` → HTTP status, for `cargo-deny`, `cargo-modules`,
`guppy`, `cackle` (all **404**, which RustSec serves when a package has no advisory page).

**Figure table** (crates.io and GitHub, 2026-09-17; licences recorded as facts and **not**
evaluated, per the owner ruling):

| Crate | Role here | 90-day dl | All-time dl | Newest non-yanked | Stars / `pushed_at` | Open issues | Licence (recorded) | `rust_version` | RustSec | Maintenance |
|---|---|---:|---:|---|---|---:|---|---|---|---|
| `cargo-deny` | **recommended** (F008) | 1,621,744 | 5,742,431 | 0.20.2 (2026-07-09T17:58:09Z) | 2,426 / 2026-09-03T18:06:48Z | 84 | MIT OR Apache-2.0 | 1.88.0 | 404 | **active** |
| `guppy` | runner-up substrate (F010) | 3,755,336 | 16,373,986 | 0.18.0 (2026-08-25T23:55:19Z) | 288 / 2026-09-17T02:21:26Z | 16 | MIT OR Apache-2.0 | 1.91 | 404 | active |
| `cargo-modules` | excluded on fit (F006) | 13,806 | 249,931 | 0.27.0 (2026-08-03T10:16:59Z) | 1,262 / 2026-09-16T12:23:59Z | 16 | MPL-2.0 | 1.95.0 | 404 | active |
| `cackle` | excluded, F008 | 39 | 5,578 | 0.2.0 (2023-09-07T04:20:47Z) | 285 / 2026-08-03T22:51:35Z | 7 | MIT OR Apache-2.0 (crates.io) / `NOASSERTION` (GitHub) | 1.67 | 404 | **at-risk** — three years without a release while the repository still moves |
| `cargo-machete` | excluded on fit | 528,045 | 2,885,062 | 0.9.2 (2026-04-15T16:52:18Z) | — | — | MIT | none declared | not queried | not a boundary tool |
| `cargo-udeps` | excluded on fit | 140,740 | 1,471,245 | 0.1.61 (2026-04-29T00:07:13Z) | — | — | — | — | not queried | not a boundary tool |
| `cargo-shear` | excluded on fit | 52,419 | 491,005 | 1.13.4 (2026-08-11T16:06:19Z) | — | — | — | — | not queried | not a boundary tool |
| `cargo-hakari` | excluded on fit | 91,575 | 1,126,148 | 0.9.38 (2026-05-21T23:29:14Z) | — | — | — | — | not queried | build-time tool |
| `cargo-depgraph` | excluded on fit | 3,459 | 55,945 | 1.6.0 (2023-12-07T17:35:58Z) | — | — | — | — | not queried | **at-risk**; renders, asserts nothing |
| `archunit_rs` | excluded — **does not exist on crates.io** | — | — | — | `oknozor/archunit_rs` 1 / 2023-11-29T09:41:31Z | — | — | — | n/a | **dormant** |

**Adopters and reference implementations** (`GET https://api.github.com/repos/<o>/<r>`, 2026-09-17):
`astral-sh/uv` 89,891 / 2026-09-17T02:33:02Z / 74 members; `astral-sh/ruff` 49,651 /
2026-09-17T05:21:09Z / 52; `jj-vcs/jj` 31,623 / 2026-09-17T05:15:56Z / `members = ["cli", "core",
"core/proc-macros", "lib", "lib/gen-protos", "lib/testutils"]`; `rust-lang/rust-analyzer` 16,857 /
2026-09-17T01:39:12Z / 35; `rust-lang/crates.io` 3,699 / 2026-09-16T20:55:39Z / 29;
`MystenLabs/walrus` 417 / 2026-09-17T04:57:46Z / `deny.toml:91-93` live `wrappers` usage. All
`archived: false`.

**Programme documents read** (repository working tree, 2026-09-17):
`research/runs/R02/2026-09-17T033527Z-40929a603f91/inputs/prompt.md` (binding),
`inputs/PARAMETERS.md`, `research/topics/01-ports-and-adapters-seam/DECISION.md`,
`research/topics/04-public-api-surface-enforcement/DECISION.md`,
`research/topics/49-build-target-declaration/DECISION.md`,
`research/topics/69-web-framework-stack/DECISION.md`, `docs/port/COMMONALITY.md` (F003–F010,
F020, F021, F116), `docs/port/DIVERGENCE-ANALYSIS.md:77-79,240-241`,
`docs/superpowers/plans/p02-roles/research-worker.md`.

**Source repositories, read through their pins as the role file requires** — never from a working
tree. py-launch-blueprint at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, via
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>`: `pyproject.toml:130-141` (`module-name`,
`module-root`), `:318-355` (the five `[[tool.importlinter.contracts]]` blocks — `forbidden`
core→cli/web, `independence` cli/web, `forbidden` core→composition, `layers`
adapters/services/models, `forbidden` core→fastapi/click/uvicorn, with
`include_external_packages = true`), `tach.toml` (five `[[modules]]` blocks and their `depends_on`
lists), `src/py_launch_blueprint/core/ruff.toml` (`extend-select = ["TID251"]`, three banned-api
entries, and the header stating its fast-first-line role), `lefthook.yml:170-177`
(`import-boundaries`, `module-boundaries`, both pre-push),
`.github/workflows/ci.yml:118-134,275-280` (the `import-boundaries` job and its aggregate-gate
membership), `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md` (Context, Decision,
Consequences), and `git ls-tree -r --name-only b08bccfb -- src` (the 42-file `core`/`cli`/`web`/
`composition.py` layout). ts-launch-blueprint at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` was
**not read**: every R02 row records ts as `none`, `DIVERGENCE-ANALYSIS.md:77` states why ("ts's
flat `src/` with one front-end and no core/front-end split leaves nothing for these tools to
check"), and there is no boundary-enforcement artifact in it to cite. That is a deliberate
omission, recorded here rather than left silent.

**Method notes.** Endpoints queried: `https://crates.io/api/v1/crates/<name>`,
`/crates/<name>/versions`, `/crates?q=…` (User-Agent header sent on every call);
`https://api.github.com/repos/<o>/<r>`, `/repos/<o>/<r>/contents/<path>`,
`/repos/<o>/<r>/issues`, `/repos/<o>/<r>/issues/<n>/comments`, `/search/issues`,
`/search/code`, `/search/repositories` (via `gh api`, authenticated; no token was printed);
`https://rustsec.org/packages/<name>.html`; `https://doc.rust-lang.org/…` for the Cargo Book,
the Rust Reference and the Clippy book; `https://raw.githubusercontent.com/…` for tool sources,
READMEs, workflows and `deny.toml` files. **What could not be verified, stated plainly:**
(1) no `cargo deny check bans` result of any kind — the tool is not installed on this machine
(`cargo deny --version` → ``error: no such command: `deny` ``) and this run did not install one,
so the F008 recommendation rests on documentation plus a reading of `src/bans.rs`, not on an
execution; (2) whether `cargo-deny`'s default graph includes `[dev-dependencies]` edges, which
decides whether a dev-dependency on `axum` in `core` is caught — unverified; (3) the wall-clock
cost of `cargo deny check bans`, which is the input F116's pre-push-versus-pre-commit line turns
on — unmeasured; (4) `cargo publish --dry-run` for any member, which needs the crates.io index —
not attempted, though R04's executed case 11 already establishes the `publish = false` half of the
constraint; (5) every executed result is macOS arm64 at `rustc`/`cargo` 1.98.0 only — nothing was
run on `ubuntu-latest` or at the MSRV floor; (6) `cargo-deny`'s issue responsiveness is reported
two ways because the prompt's rubric ("median days to first maintainer response; unanswered
count") produced 0-of-10-answered while 5 of 10 were closed with a median lag of 5.0 days, and
reporting only the first number would misstate the project's health; (7) `cargo-machete`,
`cargo-udeps`, `cargo-shear`, `cargo-hakari` and `cargo-depgraph` have download figures only —
GitHub, RustSec and responsiveness figures were not gathered for them because they were excluded
on fit before any gate applied, and the prompt's figure table exists to rank candidates rather
than to document non-candidates; (8) `matklad`'s *Large Rust Workspaces* is cited as a lead whose
claim is corroborated by four repository layouts, not as an authority in its own right. The
throwaway probe workspace was created under `$TMPDIR` and deleted at the end of this run; no file
was written anywhere except this report.
