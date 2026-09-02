# Shared parameters

Registry of every repo-wide parameter (spec §6.3). `fixed` rows are owner decisions made before research; `researched` rows are owned by exactly one `R##` and get their value from that item's `DECISION.md` during P02.

| param | kind | owner | value | description |
|---|---|---|---|---|
| msrv-policy | fixed | owner | stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI | minimum supported Rust version rule; every crate item is gated on it (§7.6) |
| rust-edition | fixed | owner | 2024 | Cargo edition for every workspace member |
| target-os-matrix | fixed | owner | ubuntu-latest, macos-latest | CI runners; every tool must run on all of them |
| license | fixed | owner | MIT OR Apache-2.0 | repository license; candidate crates must be compatible (§7.6) |

## Owner decisions (2026-09-02)

The four `fixed` values above were chosen by the owner from the options below. Two of them depart from what the source repos do; each departure is labeled with the evidence, the reason, and the cost if wrong. (Prose, not a table: the checker reads one table per file.)

- **msrv-policy** — chosen: (a) `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.
  - Options: (a) stable minus 2 minors, tested in CI; (b) latest stable only; (c) pinned N.NN for 12 months.
  - Source evidence: py declares a Python floor and ts a Node LTS floor, both tested in CI (`docs/port/areas/ci-workflows.md`).
  - Departure: no — (a) is the Rust analogue of both sources' floor policy.
- **rust-edition** — chosen: (a) `2024`.
  - Options: (a) 2024; (b) 2021.
  - Source evidence: no analogue in either source.
  - Departure: n/a — Rust-only parameter.
- **target-os-matrix** — chosen: (b) `ubuntu-latest, macos-latest`.
  - Options: (a) ubuntu, macos, windows; (b) ubuntu, macos; (c) ubuntu, macos, windows, ubuntu-24.04-arm.
  - Source evidence: the sources disagree. py tests on ubuntu/macos/windows (`py: .github/workflows/ci.yml:140`); ts tests on `ubuntu-latest` only (`ts: .github/workflows/ci.yml:42`).
  - Departure: **yes — owner override.** Narrower than py, wider than ts. Windows is not a supported target for this template, so a `windows-latest` runner would gate every tool on Windows support for no user. Cost if wrong: Windows contributors get no CI signal until the matrix is widened (a one-line workflow change).
- **license** — chosen: (b) `MIT OR Apache-2.0`.
  - Options: (a) MIT; (b) MIT OR Apache-2.0.
  - Source evidence: both sources and this repo's `LICENSE` are MIT (`py: LICENSE:1`, `ts: LICENSE:1`, origin `same`).
  - Departure: **yes — owner override.** Dual MIT OR Apache-2.0 is the Rust ecosystem default and adds Apache-2.0's explicit patent grant for any crate consumed as a library. Cost if wrong: none for crate compatibility (every MIT-compatible crate is also compatible with the dual license); the repo `LICENSE` file must be updated to match — tracked for the ship task (Task 18).
