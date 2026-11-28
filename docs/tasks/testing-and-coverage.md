# Testing and Coverage

`rs-launch-blueprint` pairs `cargo-nextest` for fast isolated test execution
with property-based tests, golden snapshots, hand-written fakes, built-binary
CLI verification, OpenAPI contract fuzzing, and LLVM source-based coverage
gates (`R32`–`R35`, `R48`, `R83`).

## Test Suites & Commands

```bash
just test                 # Default fast suite: nextest (--features web + --all-features) + doctests
just test-slow            # Ignored slow tests (`slow::` filter)
just test-live            # Ignored live tests (`live::`, e.g. Template Press acceptance)
just test-contract        # R83 OpenAPI 3.1 proptest contract fuzzing (`contract_fuzz`)
just test-all             # Full suite including slow, live, and doc tests
```

Filter a single test file via `just test`, or invoke `cargo nextest` directly
for filter expressions containing parentheses (so the shell preserves quotes):

```bash
just test --test error_contract
cargo nextest run --locked --workspace --features web -E 'test(idempotency)'
```

## Test Tiers & Doubles (`R32`, `R33`, `R48`)

- **Unit & domain tests:** live alongside modules in `crates/core`, `crates/cli`,
  `crates/web`, and `src/`, using the shipped `InMemoryProjectsPort` and
  `RecordingPort<P>` spy rather than mocking HTTP clients.
- **Built-binary CLI integration tests (`tests/cli/`):** invoke the compiled
  `CARGO_BIN_EXE_rslbp` binary via `assert_cmd` and `predicates`, verifying
  real argv parsing, exit codes, stdout/stderr separation, and `insta` golden
  snapshots.
- **Property-based testing (`tests/properties.rs`):** exercises invariants across
  generated inputs with `proptest 1.11.0`.
- **HTTP transport boundary tests (`tests/http_adapter_boundary.rs`):** test
  `UreqProjectsAdapter` against a local `httpmock 0.8.3` server.
- **Optional trait mocking (`--features mock`):** enables `mockall 0.15.0`
  automock support on `ProjectsPort` without adding `mockall` to default builds.
- **Repository contract & hygiene meta-tests:** `tests/workspace_edges.rs`,
  `tests/justfile_contract.rs`, `tests/repo_hygiene.rs`, `tests/workflows_contract.rs`,
  `tests/release_contract.rs`, `tests/community_contract.rs`, `tests/press_source.rs`,
  and `tests/docs_contract.rs` keep configuration, hooks, workflows, and docs in
  lockstep.
- **Timeouts & CI profile:** `.config/nextest.toml` sets a 60-second per-test
  timeout and retries/junit settings for CI (`--profile ci`).

## Coverage (`cargo-llvm-cov`, `R35`)

Coverage thresholds live in exactly one place — `coverage_fail_under` in
`Justfile` (`95%` lines, `95%` functions, `90%` regions):

```bash
just coverage
```

`just coverage` cleans stale profraw files, runs one instrumented pass across
`--workspace --all-features`, generates HTML (`target/llvm-cov/html/index.html`)
and LCOV (`target/llvm-cov/lcov.info`) reports, and enforces the floors last so
reports are always written even when a threshold fails.

## Weekly Freshness Canary (`R34`)

`.github/workflows/canary.yml` runs every Tuesday (`05:17 UTC`) and on manual
`workflow_dispatch` with no cache and no PR trigger across three legs:

1. `latest-deps-linux` (`ubuntu-latest`, `stable` after `cargo update`)
2. `latest-deps-macos` (`macos-latest`, `stable` after `cargo update`)
3. `next-toolchain-linux` (`ubuntu-latest`, `beta` against locked `Cargo.lock`)

Scheduled failures open or update a single issue labeled `canary`.
