# Commonality ledger

Authoritative verdicts for every atomic feature of `py-launch-blueprint` (b08bccf) and `ts-launch-blueprint` (cb1cbcb), per `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` §2–§3. Evidence for each row is the matching `id` in `areas/<Area>.md`. A tool row names its pattern row with `parent: F###`; `REUSE` rows carry `rust-ok: yes` and `live: YYYY-MM`.

| ID | Feature | Area | Origin | Verdict | Item | Notes |
|---|---|---|---|---|---|---|
| F001 | Ports abstraction for the driven I/O seam | workspace-architecture | different | DIVERGENT | R01 | bundle; whether Rust adopts a port/adapter split at all — decides F002, F013, F018 |
| F002 | Composition root wiring a port to a concrete adapter | workspace-architecture | different | DIVERGENT | R01 | bundle; only exists if F001 adopts the port split |
| F003 | Composition root importable only by front-ends, never by core | workspace-architecture | py-only | DIVERGENT | R02 | bundle; boundary-enforcement mechanism for a Rust workspace |
| F004 | Core forbidden from importing the front-ends (inward-only dependency direction) | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F005 | Front-ends (CLI, web) forbidden from importing each other | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F006 | Core internal layering (domain models below services below adapters) | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F007 | Architectural boundaries enforced mechanically rather than by convention | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F008 | Framework-bleed guard, authoritative (core may not import CLI/web frameworks) | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F009 | Framework-bleed guard, fast local mirror | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F010 | Bounded-context module dependency graph, declared and checked | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F011 | Adapter satisfies a port structurally, verified by the type checker | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F012 | Port absence-vs-failure contract | workspace-architecture | different | DIVERGENT | R03 | error-signaling convention at the port seam; feeds error-taxonomy-exit-codes owned elsewhere |
| F013 | First-class in-memory/fake adapter shipped in the package (not test-only) | workspace-architecture | py-only | DIVERGENT | R01 | bundle |
| F014 | Public library API surface, curated re-export list | workspace-architecture | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free convention, maps to `pub use` re-exports in `lib.rs` |
| F015 | Public-surface enforcement mechanism | workspace-architecture | different | DIVERGENT | R04 | whether Rust mechanically enforces the single-surface import contract (e.g. `pub(crate)` visibility) |
| F016 | Sync/async execution model for the I/O boundary | workspace-architecture | different | DIVERGENT | R05 | bundle; decides F022 |
| F017 | Web service as an optional, separately installed capability | workspace-architecture | py-only | ADOPT | — | direct Cargo-optional-feature analogue of py's optional-dependencies extra; nothing to choose |
| F018 | Web layer as a thin adapter reusing the CLI's data contract | workspace-architecture | py-only | DIVERGENT | R01 | bundle; follows from F001's ports decision |
| F019 | Source code lives under a top-level `src/` directory | workspace-architecture | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free convention, matches Cargo's default `src/` layout |
| F020 | Package namespacing within `src/` | workspace-architecture | different | DIVERGENT | R02 | bundle; resolved by whatever crate/module layout R02 picks |
| F021 | Cargo workspace crate topology (single crate vs. multi-crate members enforcing layer boundaries) | workspace-architecture | none | RUST-ONLY | R02 | bundle; the Rust enforcement mechanism for F003-F011, F020 is likely the workspace crate split itself |
| F022 | Async runtime selection for the async I/O boundary | workspace-architecture | none | RUST-ONLY | R05 | bundle; moot if F016 resolves sync |
| F023 | `unsafe` code policy (forbidden vs. permitted-with-justification) | workspace-architecture | none | RUST-ONLY | R06 | repo-wide safety-boundary decision, no precedent in either source |

## Override arguments
