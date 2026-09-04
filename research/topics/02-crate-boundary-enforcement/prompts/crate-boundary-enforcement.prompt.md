# Deep-research prompt — Crate-boundary enforcement (R02, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s Cargo workspace mechanically enforces the architectural boundaries py enforces with `import-linter`/`tach`/`ruff` — composition-root isolation, inward-only core dependencies, front-end independence, core internal layering, framework-bleed guards (authoritative and fast-mirror), a declared module dependency graph, package namespacing, and where in the hook/CI pipeline the check runs. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's `Cargo.toml` member layout, crate dependency declarations, any boundary-checking tool config, and the `lefthook`/CI job that runs it all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py enforces hexagonal boundaries mechanically — a composition root importable only by front-ends, core forbidden from importing front-ends, front-ends forbidden from importing each other, core internal layering, and framework-bleed guards at both an authoritative (CI) and a fast local-mirror tier — all declared and checked by `import-linter`/`tach`/`ruff`, not by review discipline. ts has none of this: no core/front-end split exists to enforce. Evidence: py `pyproject.toml:334` — import-linter `forbidden` contract, `core` may not import `py_launch_blueprint.composition` (HEX-04); ts: none (py-only). Ledger rows: F003, F004, F005, F006, F007, F008, F009, F010, F020, F021, F116 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F004 core forbidden from importing front-ends — py `pyproject.toml:323` (HEX-01); ts: none. F005 front-ends forbidden from importing each other — py `pyproject.toml:329` (`independence` contract); ts: none (ts ships only one front-end). F006 core internal layering — py `pyproject.toml:340` (`layers` contract, HEX-01); ts: none. F007 mechanical over conventional enforcement — py `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md:29-30`; ts: none (relies on review). F008 framework-bleed guard, authoritative — py `pyproject.toml:349` (HEX-32); ts: none. F009 framework-bleed guard, fast local mirror — py `src/py_launch_blueprint/core/ruff.toml:13` (`TID251` banned-api); ts: none. F010 bounded-context module dependency graph — py `tach.toml:19`; ts: none. F020 package namespacing — py `pyproject.toml:139` (`module-name = "py_launch_blueprint"`); ts `src/cli.ts` (path shape: no package-name subdirectory under `src/`), different. F021 Cargo workspace crate topology — origin `none`: neither repo has a compiled-workspace concept to inherit from; this row is `RUST-ONLY`. F116 boundary-check hook-tier placement — py `lefthook.yml:171`, `lefthook.yml:172` (`import-linter` at pre-push), `lefthook.yml:176`, `lefthook.yml:177` (`tach check` at pre-push); ts: none (`docs/port/areas/static-analysis.md`).
- Already decided, do not re-open: the port/adapter split itself and how an adapter is shown to satisfy a port (F001, F011) belong to R01, not this item — F011 moved from this item to R01 at the Task 10 reconciliation; assume R01 resolves to *some* port split and design the enforcement mechanism to fit either its answer. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a core/front-end split, so `TS_PORT_DECISIONS.md` has no boundary-enforcement entry to carry forward.

## Out of scope
- The shape of the ports-and-adapters seam itself (trait object vs. generic bound) and how an adapter is shown to satisfy a port; R01 (`ports-and-adapters-seam`) owns F001/F002/F011/F013/F018/F121 — this item enforces boundaries between crates, it does not decide what a port looks like.
- Async runtime selection and the sync/async execution model for the I/O boundary; R05 (`sync-async-execution-model`) owns F016/F022 — do not decide sync vs async here.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R02
- owns:
- consumes:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a port/adapter split exists and how an adapter satisfies a port (F011, moved from this item to R01 at the Task 10 reconciliation); assume R01's port split exists and design the crate topology (F021) to hold it, but do not re-decide F011 here. `http-transport-injection-seam` is R01's registered parameter; this item's crate-boundary decision does not need its value — nothing here depends on trait-object vs. generic-bound seam shape, only on how many crates the boundary needs and which way they may depend on each other.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Cargo workspace crate topology and enforcement tooling give `rs-launch-blueprint` the same mechanical guarantees py gets from `import-linter`/`tach`/`ruff` — composition-root isolation, inward-only core dependencies, front-end independence, internal layering, framework-bleed guards at both a CI and a pre-push tier, and a declared module dependency graph.
- HIGH: Does a single crate with module-visibility (`pub(crate)`, `pub(super)`) enforce these boundaries at compile time, or does only a genuine multi-crate Cargo workspace (separate `core`, `composition`, `cli`, `web` crates) make an illegal dependency a build-breaking error (F021)?
- HIGH: If multi-crate, is `cargo-deny`'s `bans` graph, a custom `cargo metadata`-driven lint, or a workspace-lint crate (e.g. `cargo-hakari`, `cargo-machete`) the Rust analogue of `tach`'s declared module dependency graph (F010) and `import-linter`'s `forbidden`/`layers`/`independence` contracts (F003-F006)?
- MEDIUM: What is the Rust analogue of py's framework-bleed guard — an authoritative CI check (F008) plus a fast local pre-commit mirror (F009) — that keeps the `core` crate from depending on CLI or web-framework crates (e.g. `clap`, `axum`)? Is a single `cargo check --no-default-features -p core` sufficient, or does it need a dependency-graph linter?
- MEDIUM: Where in the `lefthook`/CI pipeline does the chosen check run (F116) — pre-push only (as py does), or also at a faster pre-commit tier given Rust's compile times?
- LOW: What is the Rust equivalent of py's `src/py_launch_blueprint/` package-namespacing convention (F020) — a workspace member's crate name, or a `pub mod` re-export at the crate root — given Rust crates are already namespaced by `Cargo.toml` `name` with no directory-nesting requirement?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.

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
