# R32 — test-harness-and-execution (bundle) — Opus raw report

Engine: Claude Opus 5.5 (`claude-opus-5-5`), Opus seat, CLI run, 2026-09-26.
Run directory: `research/runs/R32/2026-09-26T190208Z-55160c36e3d0`. Prompt read from
`inputs/prompt.md`, byte-identical to
`research/topics/32-test-harness-and-execution/prompts/test-harness-and-execution.prompt.md`
(checked with `diff`, no output).

**Retrieval date.** Every endpoint figure, GitHub file and documentation quotation in this
report was retrieved on **2026-09-26** unless another date is stated inline.

**Source-repository pins.** Evidence from the two source repositories is read at their
current local heads: py `~/c/py-launch-blueprint` at `b55b8c2` (committed 2026-09-22),
written `py@b55b8c2`; ts `~/c/ts-launch-blueprint` at `e5100b4` (committed 2026-09-15),
written `ts@e5100b4`. Several line numbers quoted in the prompt's `## Context` have
drifted at these heads; the corrected lines are used below and each drift is noted where
it matters.

**Third-party files.** Files cited as `<owner>/<repo>:<path>` were read through
`GET https://api.github.com/repos/<owner>/<repo>/contents/<path>` (default branch, raw
media type) on 2026-09-26. Line numbers refer to that retrieved file.

**Consumed parameters are no longer open.** The prompt's `## Context` says the five
consumed parameters have "no `DECISION.md` yet". That sentence predates this run: the
run's `inputs/prerequisites.json` records accepted decisions for R01, R11, R42, R49 and R69,
and `inputs/parameters.json` carries their registered values. This report designs against
those registered values and says so under `### Parameters`.

**What was executed versus proposed.** Section `### Validation strategy` separates the two.
In short: a dependency-light scratch crate under `/tmp/r32-probe` (outside the repository)
was built and run offline with `rustc 1.98.1 (48a229cea 2026-09-01)` on
`aarch64-apple-darwin`, exercising the in-process tier, the built-binary tier with and
without `assert_cmd` 2.2.2, `#[ignore = "…"]` taxonomy selection, doc-test execution, the
stable rejection of `--shuffle` and `--ensure-time`, and serial execution of separate test
binaries under `cargo test`. `cargo-nextest` was **not** installed and **not** executed:
its download paths are not among this topic's named endpoints. Every nextest configuration
line below is therefore **proposed and documentation-backed, not executed**.

### Landscape

**Category decided.** This item decides the *test-execution layer* of a Cargo workspace:
the program that discovers and runs test binaries, and the configuration and conventions
that govern ordering, time limits, isolation, selection, parallelism and tiering. It does
not decide assertion libraries for snapshots or properties (R33), test doubles (R48),
coverage (R35), CI job topology (R11) or scheduled lanes (R34).

**Three-bin map.**

| Bin | Candidate | What it is | Evidence it belongs in the bin |
|---|---|---|---|
| Built-in / first-party | `cargo test` + libtest | Cargo's built-in runner and the standard library's default test harness | Cargo book `cargo-test.md`; rustc book `tests/index.md` (both first-party) |
| Built-in / first-party | rustdoc doc-tests (`cargo test --doc`) | doc-comment examples compiled and run by rustdoc | Cargo book `cargo-test.md:54-59` |
| Built-in / first-party | `#[ignore = "reason"]` + `--ignored` / `--include-ignored` | libtest's built-in opt-out/opt-in selector | rustc book `tests/index.md:139-146` |
| Built-in / first-party | `CARGO_BIN_EXE_<name>` | Cargo-provided path to a built binary inside integration tests | Cargo book `environment-variables.md:289-295` and `cargo-targets.md:135-139` |
| Established industry standard | `cargo-nextest` 0.9.146 | alternative runner: process-per-test, timeouts, filtersets, profiles, test groups | 1,867,747 90-day downloads; `.config/nextest.toml` committed in `gfx-rs/wgpu`, `astral-sh/uv`, `astral-sh/ruff`, `zed-industries/zed`, `rust-lang/rust-analyzer`, `oxidecomputer/omicron`; `tokio-rs/tokio` CI runs it |
| Established industry standard | `assert_cmd` 2.2.2 | spawn-and-assert helper for built binaries | 17,910,361 90-day downloads; 5,237 reverse dependencies; used by `astral-sh/uv` |
| Established industry standard | `serial_test` 4.0.1 | in-process (and file-lock) mutual exclusion attributes | 31,246,816 90-day downloads |
| Established industry standard | `rstest` 0.27.0, `test-case` 3.4.0 | fixture injection and parameterised cases | 27,849,882 and 12,063,089 90-day downloads |
| Established industry standard | `ctor` 1.0.13 | life-before-main constructors (a way to fake a global setup hook) | 52,519,995 90-day downloads (mostly transitive) |
| Established industry standard | `escargot` 0.5.15 | builds and locates Cargo binaries outside `CARGO_BIN_EXE_` | 2,480,335 90-day downloads |
| Established industry standard | `ntest` 0.9.5 | `#[timeout(ms)]` attribute per test | 1,065,746 90-day downloads |
| Up-and-comer | `test-r` 3.0.12 | replacement harness (`harness = false`) with stable `--shuffle`, tags, per-test timeout, dependency injection | 64,405 90-day downloads; 20 GitHub stars |
| Up-and-comer | `libtest2-mimic` 0.0.4 | "An experimental replacement for libtest-mimic" (assert-rs) | 26,518 90-day downloads; 65 stars on `assert-rs/libtest2` |
| Up-and-comer (unstable, first-party) | libtest `--shuffle` / `--shuffle-seed`, `--ensure-time` / `--report-time` | nightly-only libtest flags | rustc book `tests/index.md:190-230,287-292`: "requires the `-Z unstable-options` flag"; tracking issue rust-lang/rust#89583 is `open` (created 2021-10-06) |

**Authoritative sources used, and why each counts.**

- *The Cargo book* (`rust-lang/cargo:doc/book/src/…`) — the Cargo team's own normative
  documentation of test targets, `cargo test` behaviour and the environment Cargo sets.
- *The rustc book, "Tests" chapter* (`rust-lang/rust:src/doc/rustc/src/tests/index.md`) —
  the compiler team's reference for libtest's command-line flags and their stability.
- *The nextest book* (`nextest-rs/nextest:site/src/docs/…`) and its shipped
  `nextest-runner/default-config.toml` — the maintainers' own specification of behaviour and
  defaults; nextest declares its non-experimental configuration append-only
  (`configuration/reference.md` via `repo-config-reference.md:31`).
- *assert_cmd source* (`assert-rs/assert_cmd:src/{cargo.rs,macros.rs,cmd.rs}`) — the
  implementation, maintained by Ed Page, who is also a Cargo team member (visible as the
  committer of the two most recent commits, 2026-09-01).
- *serial_test README* (`palfrey/serial_test`) — maintainer documentation of its locking
  model.
- *Production configuration files* of the well-regarded projects below — practice evidence,
  not opinion.
- *crates.io, GitHub REST and RustSec* endpoints named by the prompt — the figures.

The annual Rust survey was not consulted: this run's network scope is limited to the
topic's named endpoints, and the survey is not hosted on any of them. That is a recorded
gap, not a finding; it does not change a recommendation because runner adoption is measured
here directly from project configuration files.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**
Stars from `GET https://api.github.com/repos/<o>/<r>` field `stargazers_count`; runner
evidence from the named file.

| Project | Stars | Runner evidence | Relevance |
|---|---:|---|---|
| `astral-sh/uv` | 90,201 | `.config/nextest.toml` (1,210 bytes): `slow-timeout = { period = "10s", terminate-after = 12 }`, `[profile.ci]` `fail-fast = false`, `[test-groups] serial = { max-threads = 1 }`; `.github/workflows/test.yml:120` `cargo nextest run`; `Cargo.toml:369` `assert_cmd`, `:382` `insta` | CLI; newest widely used Rust CLI; uses all three of nextest, assert_cmd and R33's insta together |
| `astral-sh/ruff` | 49,804 | `.config/nextest.toml` (756 bytes): `[profile.ci] slow-timeout = { period = "1s", terminate-after = 60 }`, `serial` test group; `.github/workflows/ci.yaml:419` `cargo insta test … --test-runner nextest --disable-nextest-doctest` then `:421` `cargo test --doc --all-features` | CLI + library; shows the nextest-plus-separate-doctest split |
| `tokio-rs/tokio` | 33,247 | `.github/workflows/ci.yml` "test tokio full" job: matrix `windows-latest, ubuntu-latest, macos-latest`; `taiki-e/install-action@v2` with `tool: cargo-nextest`; `cargo nextest run --features full` then `cargo test --doc --features full` | the async runtime this template's web surface uses (R69 pins tokio 1.53.1) |
| `zed-industries/zed` | 90,935 | `.config/nextest.toml`: `slow-timeout = { period = "60s", terminate-after = 1 }`, per-test overrides to 300 s, a `sequential-db-tests` test group | large application workspace |
| `gfx-rs/wgpu` | 18,129 | `.config/nextest.toml`: `default-filter = "!test(~oom_test)"`, `slow-timeout = { period = "45s", terminate-after = 2 }` | named in nextest's own design doc as needing process-per-test |
| `rust-lang/rust-analyzer` | 16,877 | `.config/nextest.toml` present (73 bytes) | Rust-project-owned tool |
| `oxidecomputer/omicron` | 571 | `.config/nextest.toml` present (3,685 bytes) | nextest's maintainer's employer; production control plane |
| `tokio-rs/axum` | 27,259 | `.github/workflows/CI.yml:100` `cargo test --locked --workspace --all-features --all-targets` | the web framework R69 selects; uses plain `cargo test` |
| `BurntSushi/ripgrep`, `sharkdp/bat`, `bevyengine/bevy`, `denoland/deno`, `helix-editor/helix`, `nushell/nushell`, `tauri-apps/tauri`, `pola-rs/polars`, `rust-lang/cargo` | 15,521–111,415 | no `.config/nextest.toml` at the repository root (HTTP 404) | the counter-sample: plain `cargo test` (or nextest without committed config) remains common |

**Reading of the landscape.** Six of the seventeen probed high-profile repositories commit
a nextest configuration, and a seventh (tokio) runs nextest in CI without one. The projects
that adopted nextest are the ones with the problems this item must solve: hung tests
(uv, ruff, zed, wgpu all set `terminate-after`), global-state tests (wgpu, uv and ruff
test groups), and mixed fast/slow suites. Plain `cargo test` remains the majority default.
Neither fact alone selects a design; the principles below do.

### Principles and implementation

**Shared requirement and its source.** The ledger rows F117, F118, F124, F125, F128–F132
and F173 (`docs/port/COMMONALITY.md`; classified in `docs/port/DIVERGENCE-ANALYSIS.md:132-142`)
express one principle, stated here at the **policy** agreement level:

> **P — The default test run is fast, hermetic, order-independent and bounded in time;
> anything slower, networked or environment-dependent is opt-in; the CLI is tested both as
> a function and as the artifact a user installs; the full suite is the CI gate, and a
> local pre-push run is available but never forced.**

The divergence analysis scopes the cross-repo comparison to that principle
(`DIVERGENCE-ANALYSIS.md:132`, "mixed — runner swap is a tool pick (D-019)…"). Its
sub-behaviours, each with an observable acceptance criterion, are:

| # | Behaviour | Row | Observable acceptance criterion |
|---|---|---|---|
| P1 | One named command runs the suite | F117 | `just test` (or the CI step) exits 0 on a green tree and non-zero on any failing test |
| P2 | CLI tested in-process **and** as the built binary | F118 | a test calls the CLI entry function with an injected port and asserts exit code and stdout; a second test spawns the built `rslbp` executable and asserts the same contract |
| P3 | Hidden inter-test coupling is surfaced or made impossible | F124 | two tests that share mutable process-global state cannot observe each other's writes in the default run |
| P4 | A hung test fails loudly and bounded | F125 | a test that never returns is reported as failed (not passed, not hung) within a stated cap, default 60 s, matching py `timeout = 60` |
| P5 | Setup that must precede every test is explicit or unnecessary | F128 | no test depends on state left by another; no global constructor runs before `main` |
| P6 | Test files are organised by tier so a tier can be run alone | F129 | a single command selects the CLI tier, the web tier or the unit tier |
| P7 | Slow and live tests are excluded by default and selectable by class | F130 | the default run reports live/slow tests as skipped; one documented command runs only `live`, one runs only `slow`, one runs everything |
| P8 | Parallelism is the default; serial is an opt-out | F131 | the default run uses all cores across test binaries; one flag forces serial execution |
| P9 | Documentation examples are executed | F132 | a broken doc example fails the CI gate |
| P10 | A pre-push full-suite hook exists, opt-in, default skip | F173 | with the opt-in variable unset the hook prints a skip notice and exits 0; with it set to `1` the hook runs the suite and propagates its exit code |

**What must agree across repositories, and what may vary.** P1–P10 must agree as
*behaviours*. The mechanism may vary per ecosystem and does: py realises P3 with
`pytest-randomly`, P4 with `pytest-timeout`, P5 with an autouse fixture, P7 with markers,
P8 with `pytest-xdist` (`py@b55b8c2` `pyproject.toml:96-98,276-278,283-284`,
`tests/conftest.py:16-31`); ts realises P2 with `runCli` plus a spawned `dist/cli.js`
(`ts@e5100b4` `tests/cli-core.test.ts:11`, `tests/e2e.test.ts:93-94`) and P10 with a lefthook
job (`ts@e5100b4` `lefthook.yml:79-87`), and **does not** realise P3, P4 or P7 at all.
The Rust design below realises every behaviour; where it cannot realise the *capability*
py uses (random order), it says so and realises the *principle* by a different means.

**Where the source repos stand against P, with cause.**

| Behaviour | py | ts | Classification (this report) |
|---|---|---|---|
| P2 two tiers | in-process only (`tests/cli/test_pylb.py:9`) | both | py missing capability; ts D-019(4) is the model |
| P3 random order | `pytest-randomly` | none (Vitest `sequence.shuffle` unconfigured) | ts accidental drift (no recorded reason, `DIVERGENCE-ANALYSIS.md:135`) |
| P4 timeout | `timeout = 60`, thread method | none | ts accidental drift (`DIVERGENCE-ANALYSIS.md:136`) |
| P5 global setup | autouse root-logger reset | local factories by design (D-019(5)) | justified ecosystem/design difference; the Rust answer follows ts |
| P7 slow/live | markers + `addopts` exclusion | tiering by file only | ts partial: file split gives selection but no default exclusion of live tests |
| P10 pre-push | none | opt-in `TS_PROJECTS_PREPUSH_TESTS=1` | py missing capability |

**Architectural alternatives compared before libraries.**

| Alt | Architecture | P3 | P4 | P7 | P8 | P9 | Cost |
|---|---|---|---|---|---|---|---|
| A | libtest only: `cargo test` everywhere, attributes for the rest | ✗ (shuffle nightly-only) | ✗ natively; only per-test opt-in `ntest` `#[timeout]`, which fails the test but leaves the hung thread running (or aborts the whole binary) | ✓ `#[ignore]` | partial: threads within a binary, **binaries run serially** | ✓ | zero tools |
| B | **nextest for unit + integration tests, libtest for doc-tests** | structural ✓ (process-per-test), shuffle ✗ | ✓ `slow-timeout` + `terminate-after`, SIGTERM then SIGKILL to the process group | ✓ `#[ignore]` + `--run-ignored`, filtersets | ✓ across binaries | ✓ via separate `cargo test --doc` step | one binary tool |
| C | custom harness (`test-r`, `harness = false` per target) | ✓ `--shuffle` on stable | ✓ `#[timeout]` per test | ✓ tags | ✓ | ✗ doc-tests stay libtest | every target rewritten to a non-standard harness; 20-star project |
| D | nextest locally, `cargo test` in CI | — | ✗ in CI, where it matters most | ✓ | partial | ✓ | two behaviours |

**Evidence behind the table.**

- libtest has no stable per-test timeout and no stable shuffle: rustc book
  `tests/index.md:190-195` (`--ensure-time`: "This option is unstable, and requires the
  `-Z unstable-options` flag"), `:197-213` (`--shuffle`, same), `:215-230`
  (`--shuffle-seed`, same). Executed on stable 1.98.1 in the probe: `cargo test -- --shuffle`
  exits 101 with `The "shuffle" flag is only accepted on the nightly compiler with
  -Z unstable-options`, and `-- -Z unstable-options --ensure-time` exits 101 with
  `the option 'Z' is only accepted on the nightly compiler`.
- `cargo test` runs separate test binaries **serially**: Cargo book `cargo-targets.md:126-127`
  ("Each integration test results in a separate executable binary, and `cargo test` will
  run them serially") and `cargo-test.md:33-34`. Executed: two test binaries each holding
  one 1,000 ms sleeping test took `real 2.52` s wall-clock under
  `cargo test --test sleep_a --test sleep_b` (each binary reports `finished in 1.01s`),
  i.e. sequential, not concurrent.
- nextest terminates hung tests: `features/slow-tests.md` — "`slow-timeout = { period =
  "30s", terminate-after = 4 }`"; "On Unix platforms, nextest creates a process group for
  each test. On timing out, nextest attempts a graceful shutdown: it first sends the SIGTERM
  signal to the process group, then waits for a grace period (by default 10 seconds) …
  then sends SIGKILL"; default `on-timeout = "fail"`. Shipped default:
  `nextest-runner/default-config.toml` `slow-timeout = { period = "60s", on-timeout = "fail" }`
  — i.e. *marked slow* at 60 s but **not terminated** unless `terminate-after` is set.
- nextest does not shuffle: no configuration key or flag in `default-config.toml` or
  `repo-config-reference.md` mentions order, shuffle or random; `GET
  https://api.github.com/search/issues?q=repo:nextest-rs/nextest+shuffle` returns 2 results,
  both dependency bumps of the `rand` crate (#3464, #2103). It offers *partitioning*
  (`ci-features/partitioning.md`: "sliced" and "hashed" sharding across CI machines), which
  splits a run but does not randomise order and does not address P3.
- nextest does not run doc-tests: `running.md:58` — "Doctests are currently not supported
  because of limitations in stable Rust. For now, run doctests in a separate step with
  `cargo test --doc`."
- Process-per-test is permanent: `design/why-process-per-test.md` — "the default execution
  model is now, and will always be, process-per-test", and "Tests that require altering
  environment variables or other global context" are listed among the use cases it isolates.

**Choice: Alternative B.** The discriminating behaviour is P4. py's comment states the
purpose: "a hung test fails loudly instead of burning a CI slot" (`py@b55b8c2`
`pyproject.toml:279-282`). Under libtest that behaviour is unavailable on stable Rust as
a suite-wide default. The nearest add-on, `ntest`'s `#[timeout(ms)]`, must be written on
every test (no global default, so py's `timeout = 60` parity means annotating the whole
suite), and its mechanism is a spawned thread plus `recv_timeout`: on expiry it panics the
test thread, reporting the test failed, while the hung thread keeps running until the test
binary exits; its `abort` option instead calls `std::process::abort()`, killing every other
test in that binary (`becheran/ntest:ntest_timeout/src/lib.rs:80-104`). Under nextest a
suite-wide terminating timeout is a one-line configuration with process-group termination. Alternative D defeats P4 exactly where it matters (CI);
Alternative C buys stable shuffle at the price of replacing libtest in every target with a
harness that has 20 stars, and still leaves doc-tests on libtest.

**How B realises P3 without shuffle — and what it does not do.** pytest-randomly exists
to surface tests that pass only because an earlier test left state behind. Under
process-per-test each test starts in a fresh process, so process-global state
(statics, `std::env`, the global `tracing` subscriber, a root logger analogue) *cannot*
leak between tests; the coupling pytest-randomly detects cannot occur within the process.
Coupling through the **file system or network** (a shared temp path, a fixed port) is
not prevented by processes, and random order would not reliably detect it either under a
parallel runner. The template's rule for that residue is structural: every test that
touches the file system uses its own temporary directory and every in-process web test
uses `tower::ServiceExt::oneshot` (R69) or binds port 0. **Honest status of F124:** the
*capability* (seeded random order) is **not available on stable Rust in any maintained
first-party or established tool**; the *principle* is preserved structurally. Re-verify
when rust-lang/rust#89583 closes.

**How B realises the remaining behaviours.**

- P1: `just test` runs `cargo nextest run --locked` then `cargo test --doc --locked`
  (R42's `cargo <sub>` form; no runner prefix; no Cargo alias).
- P2: see member M3 (`assert_cmd`) and member M4 (in-process tier and layout).
- P5: no global setup. Process-per-test makes py's autouse root-logger reset structurally
  unnecessary; shared construction lives in `tests/<tier>/support.rs` factory functions,
  matching ts D-019(5). `ctor` and nextest setup scripts are excluded (member M4).
- P6: one integration-test binary per tier, `tests/cli/main.rs` and `tests/web/main.rs`,
  with submodules (member M4). Rationale: the Cargo book recommends consolidating
  (`cargo-targets.md:128-133`: "you may want to consider creating a single integration test,
  and split the tests into multiple modules").
- P7: `#[ignore = "live: …"]` / `#[ignore = "slow: …"]` inside `mod live` / `mod slow`
  (member M5). Works identically under `cargo test` and nextest, so a contributor without
  nextest never runs live tests by accident.
- P8: nextest runs tests from all binaries concurrently with `test-threads = "num-cpus"`
  by default (`default-config.toml`); `-j 1` forces serial. No crate.
- P9: `cargo test --doc` as its own step (member M2).
- P10: lefthook `pre-push` job gated by `RS_PROJECTS_PREPUSH_TESTS=1` (member M6).

**Representative performance.** No benchmark was executed with nextest (not installed).
The only measured figure is the serial-binary effect under `cargo test` above: workload two
test binaries × one 1,000 ms test, configuration debug profile, `--offline --locked`,
instrumentation `/usr/bin/time -p`, result 2.52 s wall-clock versus the ≈1.0 s lower bound
a cross-binary parallel runner could reach. nextest's own design page attributes its speed
advantage to scheduling across binaries ("handles long-pole tests better",
`design/why-process-per-test.md`) and names a cost: process creation "is quite slow on
Windows … and it can be slow on macOS if anti-malware protections are interfering". For a
template whose suite is small, correctness (P4) — not throughput — is the selecting
argument; throughput is not claimed.

**Integration cost.** One binary tool (`cargo-nextest`) to provision, one configuration
file (`.config/nextest.toml`), one extra CI step for doc-tests, one dev-dependency
(`assert_cmd`). No change to how tests are written: nextest runs ordinary libtest
`#[test]` functions.

**Compatibility with adjacent decisions.**

- R33 (accepted): proptest and insta run inside ordinary `#[test]` functions and therefore
  run under nextest unchanged; ruff's CI demonstrates insta under nextest
  (`astral-sh/ruff:.github/workflows/ci.yaml:419`). Neither suite is placed outside the
  default run: they carry no `#[ignore]` and no filter excludes them, so R33's re-verify
  trigger "R32 placing either suite outside the default `cargo test` run" does **not** fire.
  Its wording names `cargo test`; the default run becomes `cargo nextest run` plus
  `cargo test --doc`, which still includes both suites.
- R35 (open): nextest's coverage page states "cargo-llvm-cov supports nextest"
  (`integrations/test-coverage.md:13-17`, `cargo llvm-cov nextest`) and documents merging
  doc-test coverage (`:35-53`). Whatever R35 picks must support nextest or fall back to
  `cargo test`; this report does not pick.
- R48 (open): the harness expects test doubles as `ProjectsPort` implementors
  (`InMemoryProjectsPort`), per R01's registered value; it does not require a mocking crate.

**Minimal realistic example (executed, scratch crate `/tmp/r32-probe`).** Package
`rs-launch-blueprint`, `edition = "2024"`, `rust-version = "1.96"`, `autobins = false`,
`[lib] path = "src/lib.rs"`, `[[bin]] name = "rslbp"`, `[[test]] name = "cli" path =
"tests/cli/main.rs"`, `[dev-dependencies] assert_cmd = "2.2.2"`. `src/lib.rs` exposes a
`ProjectsPort` trait and `pub fn run(args, port: &dyn ProjectsPort, out: &mut dyn Write)
-> ExitCode` with a doc-test; `src/main.rs` is `fn main() -> ExitCode { run(env::args(),
&EnvPort, &mut stdout()) }`. `tests/cli/` holds `main.rs` (module list), `support.rs`
(`InMemoryProjectsPort`), `in_process.rs` (2 tests), `binary.rs` (2 `std::process::Command`
tests via `env!("CARGO_BIN_EXE_rslbp")`, one `#[ignore = "live: requires external
services"]`, one `#[ignore = "slow: takes >1s"]`) and `assert_tier.rs` (2 `assert_cmd`
tests). Results are under `### Validation strategy`. The probe is a stand-in: it does not
use clap (R60), the real `ProjectsService` (R01) or the error envelope (R67), so it proves
the harness mechanics, not the template's behaviour.

**Executable acceptance check (proposed for P03, not executed here).**

```bash
cargo nextest run --locked --profile ci                  # P1, P2, P4, P7 default exclusion, P8
cargo nextest run --locked --run-ignored only -E 'test(/(^|::)slow::/)'   # P7 slow-only
cargo nextest run --locked --run-ignored all             # P7 everything (live needs credentials)
cargo test --doc --locked                                # P9
RS_PROJECTS_PREPUSH_TESTS=1 lefthook run pre-push        # P10 enabled
lefthook run pre-push                                    # P10 default skip, exit 0
```

A P4 negative control: add a temporary test `fn hangs() { loop { std::thread::park(); } }`
and run `cargo nextest run --locked -E 'test(hangs)'`; expected: the test is reported
`TIMEOUT` and the run exits non-zero at ≈60 s. This check was **not executed** (no nextest
binary); it is the first thing P03 must run.

**BASELINE-REVIEW findings.**

- `BASELINE-REVIEW: F131 — parallel by default — correct the ledger's resolution text
  "none — cargo test already parallelizes test binaries by default" to "cargo test runs
  tests within one binary in parallel but runs test binaries serially; cross-binary
  parallelism comes from the chosen runner (cargo-nextest) or from consolidating each tier
  into one test binary" — evidence: Cargo book cargo-targets.md:126-127 and
  cargo-test.md:33-34; probe: two 1,000 ms binaries took 2.52 s wall-clock under cargo
  test.` Affected: `docs/port/DIVERGENCE-ANALYSIS.md:140` (row text), R32 only. The
  conclusion "no opt-in flag or crate is needed" survives; the stated reason does not.
- `BASELINE-REVIEW: F129 — tier-organised tests — replace the inherited "flat
  tests/*.test.ts" precedent (D-019(2)) for Rust with one integration-test binary per tier
  (tests/cli/main.rs, tests/web/main.rs) plus submodules — evidence: each tests/*.rs file is
  a separate crate and binary (cargo-targets.md:114-116,126-133), so a flat layout
  multiplies link steps and serialises under cargo test; the analyst note at
  DIVERGENCE-ANALYSIS.md:277 already flagged F129 as possibly mechanic-constrained (class C
  rather than F).` Affected: R32; R69's "web integration tests, gated file-level with
  `#![cfg(feature = "web")]`" — satisfied by putting that attribute at the top of
  `tests/web/main.rs`.

### Recommendation

One stack: **`cargo-nextest` 0.9.146 as the runner for unit and integration tests,
configured by a committed `.config/nextest.toml` with a 60 s terminating per-test timeout;
`cargo test --doc` as a separate doc-test step; `assert_cmd` 2.2.2 as the only test
dev-dependency this item adds, for the built-binary CLI tier; an in-process CLI tier that
calls the library's `run` entry with an injected `ProjectsPort`; one integration-test binary
per tier under `tests/<tier>/main.rs`; `#[ignore = "live: …"]` / `#[ignore = "slow: …"]`
inside `mod live` / `mod slow` as the opt-in taxonomy; no global-setup crate, no
serialisation crate, no shuffle; and an opt-in, default-skip lefthook `pre-push` job gated
by `RS_PROJECTS_PREPUSH_TESTS=1`.**

Adopting this needs one registered value changed: R11's `ci-job-structure` names
`cargo test` for the two test steps (see the `CONFLICT:` line under `### Parameters`).

### Members

#### M1 — `cargo-nextest` 0.9.146 (runner) with `.config/nextest.toml`

##### Landscape

Runners that execute Rust `#[test]` functions: libtest via `cargo test` (first-party);
`cargo-nextest` (established; 1,867,747 90-day downloads, `GET
https://crates.io/api/v1/crates/cargo-nextest` `crate.recent_downloads`); replacement
harnesses `test-r` 3.0.12 and `libtest2-mimic` 0.0.4 (up-and-comers). Per-test timeout
add-ons for libtest: `ntest` 0.9.5 (`#[timeout]`). No other maintained Cargo-compatible
runner was found in the landscape map.

##### Principles and implementation

Realises P1, P3 (structurally), P4, P7 (selection layer) and P8. Proposed
`.config/nextest.toml`:

```toml
nextest-version = { recommended = "0.9.146" }

[profile.default]
# P4: marked SLOW at 30 s, terminated at 60 s (2 periods) — py's `timeout = 60`.
slow-timeout = { period = "30s", terminate-after = 2 }
retries = 0

[profile.ci]
fail-fast = false
failure-output = "immediate-final"

# A test that is legitimately slow raises its own cap, like @pytest.mark.timeout(N).
[[profile.default.overrides]]
filter = 'test(/(^|::)slow::/)'
slow-timeout = { period = "60s", terminate-after = 5 }
```

Every key is from the shipped reference (`nextest-runner/repo-config-reference.md`,
`default-config.toml`): `nextest-version` (`configuration/minimum-versions.md:24-28`),
`slow-timeout` object fields `period`, `terminate-after`, `grace-period`, `on-timeout`
(`repo-config-reference.md:178-188`), `fail-fast`, `failure-output`, `retries`, and
`[[profile.<name>.overrides]]` with `filter` (`configuration/per-test-overrides.md`).
`profile.ci` inherits unspecified keys from `default` (`configuration/index.md:75-84`).
`retries = 0` is the shipped default, written explicitly so flaky tests are never masked.
No `default-filter` is set: the live/slow exclusion comes from `#[ignore]` (member M5), which
nextest honours by default ("By default, all discovered, non-ignored tests are run",
`selecting.md:92`). No experimental feature is enabled.

##### Dominant choice

`cargo test` remains the most common runner among the surveyed well-regarded projects
(11 of 17 probed repositories commit no nextest config). Among projects that configure
timeouts or isolation, nextest is dominant: uv, ruff, zed, wgpu, rust-analyzer and omicron
commit `.config/nextest.toml`; tokio runs it in CI.

##### Qualified shortlist

Fitness gates, answered before popularity. Figures from `GET
https://crates.io/api/v1/crates/<name>`, `…/versions`, `GET
https://api.github.com/repos/<o>/<r>`, `GET
https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, and
`https://rustsec.org/packages/<name>.html` (HTTP 404 = no advisory page; method validated
by `time` and `chrono` returning 200).

| Gate / figure | `cargo-nextest` | `cargo test` (libtest) |
|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declared `Apache-2.0 OR MIT` | inapplicable (same ruling); toolchain `MIT OR Apache-2.0` |
| 2 MSRV | `rust_version` 1.91 on 0.9.146; template floor is 1.96 (stable 1.98 − 2); a binary tool, not in the template's dependency tree | ships with the toolchain |
| 3 advisories / `unsafe` | RustSec 404 for `cargo-nextest` and `nextest-runner`; separate process, never linked into the template, so its `unsafe` posture does not reach the template | none |
| 4 OS | `nextest-rs/nextest:.github/workflows/ci.yml:169-173` test matrix `ubuntu-latest, ubuntu-24.04-arm, macos-latest, windows-latest` | first-party tier-1 |
| 5 features / async | installed binary; no Cargo features selected by the template; no runtime coupling for tests | n/a |
| 6 size / compile cost | no effect on the template's binary; `cargo install` compiles a large tool (qualitative), prebuilt binaries avoid it (`installation/pre-built-binaries.md`) | none |
| 90-day / all-time downloads | 1,867,747 / 12,951,672 | n/a |
| Last release | 0.9.146, 2026-09-21 | toolchain 1.98.1 |
| Stars / archived / pushed | 3,303 / false / 2026-09-26 | n/a |
| Open issues | 76 | n/a |
| Responsiveness (10 newest issues, 2026-05-01…2026-09-10) | 2 maintainer-filed; 7 external answered, median 0.18 days to first OWNER/MEMBER/COLLABORATOR comment; 1 unanswered | n/a |
| Maintenance | `active` | `active` |
| Adopters | uv, ruff, zed, wgpu, rust-analyzer, omicron (config files above); tokio CI | axum CI and the counter-sample |

##### Excluded by gate

- libtest `--shuffle`, `--shuffle-seed`, `--ensure-time`, `--report-time`: fail the
  constraint "Stable Rust only" (rustc book `tests/index.md:190-230,287-292`; executed
  rejection on 1.98.1, see `### Validation strategy` checks 4–6).
- Alternative D (nextest only locally): not a gate failure but a principle failure — P4 would
  not hold in CI.
- `serial_test` 4.0.1 (the prompt's MEDIUM lead for F128/F131): passes every numbered gate —
  licence `inapplicable — owner ruling 2026-09-12 (Q7.B)` (declared `MIT`); `rust_version`
  1.93.1 ≤ floor 1.96; RustSec 404 — and is healthy (31,246,816 90-day / 155,139,546
  all-time downloads; last release 2026-07-25; `palfrey/serial_test` 296 stars, not archived,
  pushed 2026-09-05; 0 open issues; 10 newest issues 2025-03-19…2026-08-23: 2
  maintainer-filed, 8 external answered, median 0.12 days, 0 unanswered). Excluded by
  **principle and runner compatibility**, not by gate: its `#[serial]` is an in-process lock,
  and its README says that "for cases like doctests and integration tests where the tests are
  run as separate processes, we also support `file_serial`" (`README.md:34-36`); nextest
  states that in-process mutexes are not supported under process-per-test and are emulated
  with test groups (`configuration/test-groups.md:21`). Under M1, `#[serial]` would silently
  stop serialising. The template has no test needing mutual exclusion; if one appears, it
  uses a nextest `[test-groups]` entry (uv and ruff both define `serial = { max-threads = 1 }`).

##### Up-and-comers

- `test-r` 3.0.12 (2026-08-24; 64,405 90-day; `vigoo/test-r` 20 stars, pushed 2026-09-14;
  licence `Apache-2.0`; no declared `rust_version`): stable `--shuffle`/`--shuffle-seed`
  (`book/src/core_features/running_tests.md:78-79`) and `#[timeout(ms)]`
  (`book/src/advanced_features/per_test_configuration.md:46-53`), but requires
  `harness = false` on every target and `test_r::enable!()` in each
  (`book/src/getting_started.md:16-43`). Watch: it is the only stable path to F124's
  capability.
- `libtest2-mimic` 0.0.4 (2025-09-18; 26,518 90-day; `assert-rs/libtest2` 65 stars):
  self-described "experimental replacement for libtest-mimic"; relevant only if the Cargo
  team's harness work stabilises a JSON protocol.

##### Fit for this template

CLI: timeouts and process isolation protect the spawned-binary tier, which is the tier most
likely to hang (a child waiting on stdin). Library: unchanged `#[test]` authoring. Web
service: in-process axum tests (R69's `oneshot` idiom) run as ordinary tests; any future
test needing a shared resource uses a nextest test group instead of an in-process mutex
(`configuration/test-groups.md:21`: in-process mutexes are not supported under
process-per-test; "you can emulate them by using test groups").

##### Recommendation

Adopt `cargo-nextest` 0.9.146 (`nextest-version = { recommended = "0.9.146" }`, a warning rather than a hard failure for contributors a few releases behind; P03 may raise it to `required` once its CI pins the install) as the runner
for unit and integration tests locally and in CI, with the configuration above. Provision it
through whatever channel R42's `dev-toolchain-provisioning` decision names; test its presence
with `command -v cargo-nextest` (R42's rule for crates.io/release tools).

##### Ranked runner-up

`cargo test` alone (Alternative A) plus nothing: loses P4 (no stable terminating timeout)
and cross-binary parallelism; keeps zero tool installs. It is the fallback if nextest
becomes unavailable; the taxonomy (M5) and layout (M4) are designed to work unchanged under
it.

##### Tradeoffs

Gains: terminating timeout, process isolation, cross-binary parallelism, filtersets,
profiles, test groups, JUnit when needed. Costs: one more tool to provision on every
contributor machine and CI runner; doc-tests need a second command; per-test process
creation is slower on macOS under anti-malware scanning (`installation/macos.md` is
referenced from `design/why-process-per-test.md`); no random order.

##### Parameters

Owns none. Assumes `package-manager-invocation` (R42): written `cargo nextest run`, never
`cargo-nextest nextest run`, no alias. Assumes `ci-job-structure` (R11) with the
`CONFLICT:` recorded under `### Parameters`: the test steps' command changes.
Assumes `msrv-policy`: nextest is a tool, not a dependency, so its `rust_version` (1.91)
does not constrain the template's declared floor.

##### Migration implications

Add `.config/nextest.toml`. `Justfile` `test` recipe becomes
`cargo nextest run --locked {{options}}` followed by `cargo test --doc --locked`. CI `check`
job: a tool-install step (channel per R42) before the test steps; test steps switch from
`cargo test` to `cargo nextest run --profile ci`, keeping R11's `-p`/`--workspace` scoping,
feature selection, `--locked` and `!cancelled()`.

##### Validation strategy

Proposed (not executed — nextest not installed): `cargo nextest show-config version`
reports the requirement satisfied; `cargo nextest list --locked` lists the same tests
`cargo test -- --list` lists; the hang negative control times out at ≈60 s with a
non-zero exit; `cargo nextest run --locked -j 1` runs serially. Executed: the libtest
behaviour nextest replaces (checks 4–7 and 9 in `### Validation strategy`).

##### Confidence & re-verify trigger

High that nextest provides P4 and P8 as documented (maintainer documentation plus six
independent production configurations that set `terminate-after`). Medium on the exact
timeout numbers, which P03 should tune from measured suite times. Re-verify when:
rust-lang/rust#89583 (shuffle) or #64888 (test time) stabilises; nextest's issue #16
(doc-tests) closes; a nextest release changes `slow-timeout` semantics; RustSec publishes an
advisory for `cargo-nextest`.

##### Sources

- `https://crates.io/api/v1/crates/cargo-nextest`, `…/versions`, `…/nextest-runner` (2026-09-26)
- `https://api.github.com/repos/nextest-rs/nextest`; search issues endpoints (2026-09-26)
- `nextest-rs/nextest:site/src/docs/{features/slow-tests.md, running.md, selecting.md, design/why-process-per-test.md, configuration/{test-groups.md, minimum-versions.md, index.md, per-test-overrides.md, env-vars.md}, ci-features/partitioning.md, integrations/test-coverage.md}`, `nextest-runner/{default-config.toml, repo-config-reference.md}`, `.github/workflows/ci.yml`, `cargo-nextest/src/cargo_cli.rs:317-319,505-506` (`--locked` accepted and forwarded) (2026-09-26)
- `rust-lang/rust:src/doc/rustc/src/tests/index.md`; `https://api.github.com/repos/rust-lang/rust/issues/89583` (2026-09-26)
- Adopter configs: `astral-sh/uv:.config/nextest.toml`, `astral-sh/ruff:.config/nextest.toml`, `zed-industries/zed:.config/nextest.toml`, `gfx-rs/wgpu:.config/nextest.toml`, `tokio-rs/tokio:.github/workflows/ci.yml` (2026-09-26)
- `https://rustsec.org/packages/cargo-nextest.html`, `…/nextest-runner.html` (404, 2026-09-26)

#### M2 — libtest doc-test step (`cargo test --doc`)

##### Landscape

Doc-comment examples are compiled and run only by rustdoc through `cargo test` (first
party). nextest does not run them (`running.md:58`). No third-party runner executes
doc-tests. There is no up-and-comer in this bin. Crate figures are **inapplicable**: this
member is a built-in command, not a crate.

##### Principles and implementation

Realises P9. Edition 2024 merges doc-tests into one compiled binary where possible; the
probe printed `all doctests ran in 0.45s; merged doctests compilation took 0.21s`, and the
Cargo book notes the execution model "is not guaranteed and may change" (`cargo-test.md:54-59`).
The step runs `cargo test --doc --locked` with the same feature selection as the
feature-on test step, so doc examples inside the web module are also compiled.

##### Dominant choice

A separate `cargo test --doc` step next to nextest is the documented and practised pattern:
nextest's own docs prescribe it (`running.md:58`); tokio (`ci.yml`, "test tokio full":
`cargo nextest run --features full` then `cargo test --doc --features full`) and ruff
(`ci.yaml:419-421`) do it.

##### Qualified shortlist

Gates: licence `inapplicable — owner ruling 2026-09-12 (Q7.B)`; MSRV: first-party, present
at every toolchain in the floor window; advisories: none (toolchain); OS: tier-1 on both
matrix OSes; features: none; cost: one extra compile of doc examples. Alternatives: (a)
include doc-tests via plain `cargo test` in the same step (only possible if the runner is
`cargo test`); (b) `cargo llvm-cov` doc-test merging, which is R35's concern.

##### Excluded by gate

None fail a gate. Disabling doc-tests (`[lib] doctest = false`) is excluded by principle P9,
not by a gate; and whether `doctest` is set at all in `[lib]` is R82's per R49's registered
value ("doctest is not set here and is R82's").

##### Up-and-comers

None. Stabilised merged doc-tests in edition 2024 are the recent first-party change.

##### Fit for this template

The library crate's public API (`run`, `ProjectsPort`, error codes from R67) is the part
most likely to carry examples; executing them keeps README-level examples truthful.

##### Recommendation

Run `cargo test --doc --locked` as its own CI step and as the second command of
`just test`. It is part of the CI-authoritative gate.

##### Ranked runner-up

Relying on R82's docs-correctness gate to run doc-tests. Rejected as the primary place
because P9 is a test-suite behaviour and must run wherever the suite runs, including the
pre-push hook; R82 may add further checks on top.

##### Tradeoffs

A second command and a second compile; doc-tests do not get nextest's timeout (they run
under libtest). Acceptable: doc examples rarely block.

##### Parameters

Assumes `build-tool-output-shape` (R49): exactly one `[lib]`, so there is one doc-test
target. Assumes `web-extra-surface` (R69): run with the feature on so gated modules'
examples compile.

##### Migration implications

`Justfile` `test` recipe gains `cargo test --doc --locked`; CI gains one step (see the
`CONFLICT:` line). No manifest change from this item.

##### Validation strategy

Executed: `cargo test --offline --locked --doc` → `test src/lib.rs - run (line 12) ... ok`,
exit 0 (check 7). Proposed: introduce a wrong assertion in a doc example; expect exit 101.

##### Confidence & re-verify trigger

High. Re-verify when nextest issue #16 closes (doc-tests supported natively) or when R82
publishes and claims doc-test execution.

##### Sources

- `rust-lang/cargo:doc/book/src/commands/cargo-test.md:54-59,151-158` (2026-09-26)
- `nextest-rs/nextest:site/src/docs/running.md:58`; `integrations/test-coverage.md:35-53` (2026-09-26)
- `tokio-rs/tokio:.github/workflows/ci.yml`; `astral-sh/ruff:.github/workflows/ci.yaml:419-421` (2026-09-26)

#### M3 — `assert_cmd` 2.2.2 (built-binary CLI tier)

##### Landscape

Ways to run the built binary from a test: `std::process::Command` with
`env!("CARGO_BIN_EXE_rslbp")` (first-party, Cargo book `environment-variables.md:289-295`);
`assert_cmd` (established; 17,910,361 90-day downloads, 5,237 reverse dependencies from
`GET https://crates.io/api/v1/crates/assert_cmd/reverse_dependencies` `meta.total`);
`escargot` (builds binaries itself; 2,480,335 90-day). Snapshot-style CLI runners
(`trycmd`, `insta-cmd`) are R33's territory and not considered here.

##### Principles and implementation

Realises P2's second tier: "the CLI is tested as the artifact a user installs". Cargo
builds every binary target before integration tests are built, "unless the binary has
required features that are not enabled" (`cargo-targets.md:135-139`,
`environment-variables.md:294-295`). That removes the need for ts's staleness-aware rebuild
(`ts@e5100b4` `tests/e2e.test.ts:33-49`, `buildIfStale`): Cargo's own dependency tracking
guarantees the binary is current. `assert_cmd::cargo::cargo_bin_cmd!("rslbp")` expands to
`Command::new(Path::new(env!(concat!("CARGO_BIN_EXE_", "rslbp"))))`
(`assert-rs/assert_cmd:src/macros.rs:56-63,85-91`), a compile-time lookup. nextest sets
`CARGO_BIN_EXE_<name>` at runtime too ("matching `cargo test` in Rust 1.94 and above
(though nextest sets this variable on all Rust versions)", `configuration/env-vars.md:234-235`).
`Command::timeout` (`src/cmd.rs:108`) bounds each spawned child independently of the
runner. For the serve binary, `CARGO_BIN_EXE_rslbp-serve` exists only when the `web`
feature is on, which is exactly when `tests/web/main.rs` compiles (R69's
`#![cfg(feature = "web")]`).

Executed tier test (from the probe, passed):

```rust
use assert_cmd::cargo::cargo_bin_cmd;
use std::time::Duration;

#[test]
fn assert_cmd_lists_projects() {
    cargo_bin_cmd!("rslbp")
        .arg("projects")
        .env("RSLBP_FAKE_PROJECTS", "Alpha,Beta")
        .timeout(Duration::from_secs(10))
        .assert()
        .success()
        .stdout("Alpha\nBeta\n");
}
```

The environment-variable seam in the probe stands in for the real adapter's configuration
(an endpoint URL pointing at a local fake server, as ts's e2e tier does); the choice of
HTTP fake is R48's.

##### Dominant choice

`assert_cmd` is the dominant spawn-and-assert crate (5,237 reverse dependencies; used by
`astral-sh/uv`, `Cargo.toml:369`). Plain `std::process::Command` is the dominant
zero-dependency alternative.

##### Qualified shortlist

| Gate / figure | `assert_cmd` 2.2.2 | `std::process::Command` | `escargot` 0.5.15 |
|---|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declared `MIT OR Apache-2.0` | inapplicable; toolchain | inapplicable; `MIT OR Apache-2.0` |
| 2 MSRV | 1.85 ≤ floor 1.96; resolver locked 18 packages "to latest Rust 1.96 compatible versions" in the probe | n/a | 1.70 |
| 3 advisories / `unsafe` | RustSec 404 (also `predicates` 404); depends on `libc` (normal), `wait-timeout` — both small FFI/process crates; no `#![forbid(unsafe_code)]` found in `src/lib.rs` | none | RustSec 404 |
| 4 OS | `assert-rs/assert_cmd:.github/workflows/ci.yml:39` matrix `ubuntu-latest, windows-latest, macos-latest` | tier-1 | not checked (not shortlisted as primary) |
| 5 features / async | default features: none (`color`, `color-auto` optional → `anstream`); no async runtime | n/a | n/a |
| 6 size / compile cost | dev-dependency only; normal deps `anstyle`, `bstr`, `libc`, `predicates`, `predicates-core`, `predicates-tree`, `wait-timeout`; small | zero | builds binaries itself (slower) |
| 90-day / all-time | 17,910,361 / 86,407,589 | n/a | 2,480,335 / 11,081,487 |
| Last release | 2.2.2, 2026-05-11 | n/a | 0.5.15, 2025-08-11 |
| Stars / archived / pushed | 563 / false / 2026-09-01 | n/a | 58 / false / 2026-09-18 |
| Open issues | 24 | n/a | 8 |
| Responsiveness | 10 newest issues (2025-11-14…2026-07-06): maintainer `epage` answered 9 (GitHub labels him `CONTRIBUTOR` on this repo, so the association filter undercounted until checked by login); median 0 days to first response; 1 unanswered (#266); two long tails (#285 148 days, #258 119 days) | n/a | 10 newest (2020-08-13…2025-04-14): 7 answered same day by `epage`, 3 unanswered (one a bot) |
| Maintenance | `active` | `active` | `stable-quiet` |

##### Excluded by gate

None fails a gate. `escargot` is not excluded but is unnecessary: it exists to build and
locate binaries, which `CARGO_BIN_EXE_` already does for same-package integration tests.

##### Up-and-comers

None identified for spawn-and-assert. The Cargo-side change is `CARGO_BIN_EXE_<name>` being
set at runtime since Rust 1.94 (per nextest's `env-vars.md:235`), which removes the last
reason for runtime path discovery helpers.

##### Fit for this template

CLI: exercises argv parsing (R60), exit codes returned from `main` (R67: 0/1/2/3/4/5/130/143),
the stderr JSON envelope and stdout-empty-on-error (R67), all of which the in-process tier
cannot prove because they live in `main`. Web: `rslbp-serve` start-up and the
SIGTERM→143 / SIGINT→130 contract (R69) can only be asserted against the real process.

##### Recommendation

`[dev-dependencies] assert_cmd = "2.2.2"`, default features. Built-binary tests live in
`tests/cli/binary.rs` (and `tests/web/serve.rs` under the `web` feature) and always set
`.timeout(...)` on spawned commands.

##### Ranked runner-up

`std::process::Command` with `env!("CARGO_BIN_EXE_rslbp")` — executed in the probe and
passing; zero dependencies, but every test hand-rolls exit-code/stdout assertions and there
is no child timeout without writing one.

##### Tradeoffs

A small dev-dependency tree and one more crate to keep current, in exchange for readable
assertions, predicate diffs on failure and a per-child timeout.

##### Parameters

Assumes `build-tool-output-shape` (R49): binary name `rslbp`, resolved through
`CARGO_BIN_EXE_rslbp`; `autobins = false`. Assumes `web-extra-surface` (R69): serve binary
`<app>-serve` with `required-features = ["web"]`. Assumes `http-transport-injection-seam`
(R01) for how the binary's adapter is pointed at a fake.

##### Migration implications

`Cargo.toml` `[dev-dependencies]` gains `assert_cmd`. New `tests/cli/binary.rs`; under the
web feature, `tests/web/serve.rs`.

##### Validation strategy

Executed: `cargo test --offline --locked --test cli` → `assert_tier::assert_cmd_lists_projects
... ok`, `assert_tier::assert_cmd_usage_error_exits_2 ... ok`; `test result: ok. 6 passed; 0
failed; 2 ignored`; exit 0 (check 3). Proposed: the same tests under
`cargo nextest run --locked`.

##### Confidence & re-verify trigger

High (executed). Re-verify on an `assert_cmd` 3.x release, a RustSec advisory for
`assert_cmd`/`predicates`/`wait-timeout`, or a Cargo change to `CARGO_BIN_EXE_` semantics.

##### Sources

- `https://crates.io/api/v1/crates/assert_cmd`, `…/versions`, `…/2.2.2/dependencies`, `…/reverse_dependencies` (2026-09-26)
- `https://api.github.com/repos/assert-rs/assert_cmd`; issue and comment endpoints for #258–#310 (2026-09-26)
- `assert-rs/assert_cmd:src/{macros.rs:56-63,85-91, cargo.rs:225-258, cmd.rs:108}`, `.github/workflows/ci.yml:39` (2026-09-26)
- `rust-lang/cargo:doc/book/src/reference/{environment-variables.md:289-295, cargo-targets.md:135-139}` (2026-09-26)
- `nextest-rs/nextest:site/src/docs/configuration/env-vars.md:234-235` (2026-09-26)
- `astral-sh/uv:Cargo.toml:369` (2026-09-26)

#### M4 — In-process CLI tier, tier-per-binary test layout and local fixtures (pattern)

##### Landscape

Pattern member; crate figures are **inapplicable** because the member is a code-organisation
convention with no dependency. Options mapped: in-process tier by (a) a library `run`
function taking argv, injected port and output sinks, or (b) no in-process tier (spawn
only). Layout: (a) flat `tests/*.rs`, (b) one binary per tier `tests/<tier>/main.rs`,
(c) a single `tests/integration/main.rs`. Shared setup: (a) local factory functions in a
`support` module, (b) `rstest` fixtures, (c) `ctor` global constructors, (d) nextest
setup scripts (experimental).

##### Principles and implementation

Realises P2 (first tier), P5 and P6.

- *In-process tier.* The library exposes `pub fn run<I, S>(args: I, service: …, out: &mut
  dyn Write, err: &mut dyn Write) -> ExitCode`. `main` is a thin adapter that builds the
  production composition (R01: `Arc<dyn ProjectsPort>` erased at the composition root),
  calls `run` and returns its `ExitCode` (R67). Tests pass R01's shipped
  `InMemoryProjectsPort` and `Vec<u8>` sinks. This is ts's `runCli(argv, deps)`
  (`ts@e5100b4` `tests/cli-core.test.ts:11`) and py's `CliRunner` in Rust form.
- *Layout.* `tests/cli/main.rs` declares `mod in_process; mod binary; mod support;` (and
  `mod live;`/`mod slow;` when needed); `tests/web/main.rs` begins with
  `#![cfg(feature = "web")]`; each is registered as `[[test]] name = "cli"` / `name = "web"`
  or discovered by Cargo's `tests/<name>/main.rs` rule. Unit tests stay in `#[cfg(test)]`
  modules next to the code. One binary per tier keeps tier selection a single flag
  (`--test cli`, or nextest `-E 'binary(cli)'`) and avoids one link per file.
- *Fixtures.* Construction helpers are plain functions in `tests/<tier>/support.rs`
  returning owned values; nothing runs implicitly. Process-per-test under nextest means
  process-global state cannot leak between tests, so py's autouse logger reset
  (`py@b55b8c2` `tests/conftest.py:16-31`) has no job to do.

##### Dominant choice

In-process `run(args, …)` testing is how clap-based CLIs are commonly unit-tested
(`Command::try_get_matches_from` style); consolidated integration binaries follow the
Cargo book's own advice (`cargo-targets.md:128-133`). Local helpers are the zero-dependency
default.

##### Qualified shortlist

For shared setup, the crate candidates' gates and figures (endpoints as in M1):

| Gate / figure | `rstest` 0.27.0 | `ctor` 1.0.13 |
|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; `MIT OR Apache-2.0` | inapplicable; `Apache-2.0 OR MIT` |
| 2 MSRV | 1.85.0 | 1.60 |
| 3 advisories | RustSec 404 | RustSec 404; runs code before `main` (link-section constructors) |
| 4 OS | not checked (not recommended) | not checked (not recommended) |
| 5 features | proc-macro; optional async support | proc-macro |
| 6 cost | proc-macro compile time | small |
| 90-day / all-time | 27,849,882 / 124,726,976 | 52,519,995 / 202,338,212 |
| Last release | 2026-09-06 | 2026-08-09 |
| Stars / archived / pushed | 1,588 / false / 2026-09-06 | `mmastrac/linktime` 1,088 / false / 2026-09-12 |
| Open issues | 68 | 11 |
| Responsiveness (10 newest issues via `repos/<o>/<r>/issues`) | median 0.51 days; 2 unanswered | median 0.23 days; 0 unanswered; 1 maintainer-filed |

##### Excluded by gate

None by the numbered gates. Excluded by principle: `ctor` (implicit global setup contradicts
P5 and ts D-019(5)); nextest setup scripts (experimental, require
`experimental = ["setup-scripts"]`, `configuration/setup-scripts.md:9-14`, tracking issue
nextest-rs/nextest#978).

##### Up-and-comers

`test-r`'s dependency injection (`book/src/advanced_features/dependency_injection.md`) is
the only harness-level fixture system seen; it requires the custom harness (see M1).

##### Fit for this template

CLI: the in-process tier covers argument handling and output formatting fast; the binary
tier covers `main`. Library: unit tests beside code. Web: `tests/web/` uses R69's
`tower::ServiceExt::oneshot` against `build_router`, in-process.

##### Recommendation

Adopt the in-process `run` tier, `tests/cli/main.rs` and `tests/web/main.rs` as the two
integration binaries with submodules, and local `support.rs` helpers. Add no fixture crate.
`rstest` is not rejected for parameterised cases in future, but this item adds no reason
for it.

##### Ranked runner-up

Flat `tests/*.rs` (ts's D-019(2) shape): works, but every file is a separate binary, which
under `cargo test` runs serially and links repeatedly (see BASELINE-REVIEW F129).

##### Tradeoffs

Submodule layout means one failing compile breaks the whole tier's binary; accepted for fewer
links and single-flag tier selection.

##### Parameters

Assumes `http-transport-injection-seam` (R01): doubles are `ProjectsPort` implementors, the
shipped `InMemoryProjectsPort`, never patched transports. Assumes `web-extra-surface` (R69):
web tests gated at file level. Assumes `build-tool-output-shape` (R49): one `[lib]`, one
`[[bin]] rslbp`.

##### Migration implications

New `tests/cli/{main,support,in_process,binary}.rs`, `tests/web/{main,…}.rs`; library gains
`pub fn run(...)`; `src/main.rs` reduced to composition + `run`.

##### Validation strategy

Executed: `in_process::projects_lists_names_in_process ... ok` and
`in_process::unknown_command_is_usage_error_in_process ... ok` in the `cli` binary built from
`tests/cli/main.rs` (check 1). Proposed: `cargo nextest run --locked -E 'binary(cli)'` runs
only the CLI tier.

##### Confidence & re-verify trigger

High for layout and in-process tier. Re-verify if R60's accepted clap wiring cannot be
driven from an argv iterator, or if R01's seam changes shape.

##### Sources

- `rust-lang/cargo:doc/book/src/reference/cargo-targets.md:112-139` (2026-09-26)
- `ts@e5100b4` `tests/cli-core.test.ts:11`, `tests/e2e.test.ts:1-49,93-94`; `py@b55b8c2` `tests/conftest.py:16-31`, `tests/cli/test_pylb.py:9`
- `nextest-rs/nextest:site/src/docs/configuration/setup-scripts.md:1-14` (2026-09-26)
- `https://crates.io/api/v1/crates/{rstest,ctor}`; `https://api.github.com/repos/{la10736/rstest,mmastrac/linktime}` (2026-09-26)

#### M5 — Opt-in slow/live taxonomy via `#[ignore = "<class>: …"]` (pattern)

##### Landscape

Pattern member; crate figures **inapplicable** except for the compared crates below.
Mechanisms: libtest `#[ignore = "reason"]` with `--ignored` / `--include-ignored`
(first-party, `tests/index.md:139-146`); nextest `default-filter` and `--run-ignored`
(`selecting.md:90-113`, `running.md:129-133`); a Cargo feature such as `live-tests`;
parameterisation crates `rstest` / `test-case` (no tag system); `test-r` tags (custom
harness).

##### Principles and implementation

Realises P7. Each class lives in a module named for it so name filters select it:

```rust
mod live {
    #[test]
    #[ignore = "live: requires external services"]
    fn projects_api_round_trip() { /* … */ }
}
mod slow {
    #[test]
    #[ignore = "slow: takes >1s"]
    fn large_config_round_trip() { /* … */ }
}
```

The reason strings copy py's marker descriptions (`py@b55b8c2` `pyproject.toml:276`).
Commands: default run skips both; `cargo nextest run --run-ignored only -E 'test(/(^|::)slow::/)'`
(or `cargo test -- --ignored slow::`) runs slow only; the same with `live` runs live only;
`--run-ignored all` / `-- --include-ignored` runs everything, py's `pytest -m ""`.

##### Dominant choice

`#[ignore]` is the first-party, universally understood mechanism; it is the only one honoured
identically by `cargo test`, nextest and IDE runners.

##### Qualified shortlist

| Gate / figure | `test-case` 3.4.0 | `ntest` 0.9.5 (for per-test time caps) |
|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; `MIT` | inapplicable; `MIT` |
| 2 MSRV | 1.85 | none declared |
| 3 advisories | RustSec 404 | RustSec 404 |
| 90-day / all-time | 12,063,089 / 64,643,322 | 1,065,746 / 10,133,754 |
| Last release | 2026-09-23 | 2025-12-17 |
| Stars / archived / pushed | 633 / false / 2026-09-23 | 75 / false / 2026-09-22 |
| Open issues | 24 | 6 |
| Responsiveness (10 newest via `repos/<o>/<r>/issues`) | median 6.69 days; 8 of 10 unanswered | median 4.39 days; 5 unanswered |
| Maintenance | `active` (release 3 days ago) but slow issue response | `stable-quiet` |

Neither provides tags. `ntest`'s `#[timeout]` is per-test opt-in with no suite-wide default
and leaves a hung thread running after failing the test (`ntest_timeout/src/lib.rs:80-104`),
so it does not satisfy P4 globally and is superseded by M1.

##### Excluded by gate

A `live-tests` Cargo feature fails no numbered gate but is excluded by principle: it
changes compilation (clippy and the feature matrix in R11's `check` job would need another
leg) and hides live tests from default builds, so they rot.

##### Up-and-comers

`test-r` tags (`book/src/advanced_features/tags.md`) — custom harness; see M1.

##### Fit for this template

Live tests (against a real projects API) need credentials a contributor may lack; slow tests
(large property runs if R33 adds any) must not tax the inner loop. Both remain compiled and
linted.

##### Recommendation

Use `#[ignore = "live: …"]` / `#[ignore = "slow: …"]` inside `mod live` / `mod slow`.
Document the three commands in the `Justfile` as `test-slow`, `test-live`, `test-all`
recipes passing through to the runner. Set no nextest `default-filter` for this purpose.

##### Ranked runner-up

nextest `default-filter = 'not test(/(^|::)(live|slow)::/)'` with `--ignore-default-filter` to
opt in — clean under nextest but not honoured by `cargo test`, so a contributor without
nextest would run live tests by default.

##### Tradeoffs

The class is carried by a module path and a reason string, not a typed marker; a misspelled
module name silently leaves a test in the wrong class. Mitigation (proposed): a CI grep that
every `#[ignore` reason starts with `live:` or `slow:`.

##### Parameters

None consumed beyond the fixed parameters.

##### Migration implications

`Justfile` recipes `test-slow`, `test-live`, `test-all`. No manifest change.

##### Validation strategy

Executed: default run printed `binary::live_projects_api ... ignored, live: requires external
services` and `binary::slow_roundtrip ... ignored, slow: takes >1s` (check 1);
`cargo test --test cli -- --ignored slow_` ran only the slow test, `1 passed … 5 filtered
out` (check 2); `-- --ignored live_` ran only the live test, which panicked by design, exit
101 (check 3b). Both executed selections matched a substring of the **function name**
(`slow_roundtrip`, `live_projects_api`). Module-path selection was then executed under
libtest: after appending `mod slow { #[test] #[ignore = "slow: takes >1s"] fn
large_config_round_trip() {} }` to `tests/cli/main.rs`, `cargo test --offline --locked
--test cli -- --list --ignored` listed `slow::large_config_round_trip: test`, and
`-- --ignored slow::` ran exactly that test (`1 passed; … 8 filtered out`, exit 0), not
`binary::slow_roundtrip`. The nextest form `-E 'test(/(^|::)slow::/)'` remains
**unexecuted**. The regex anchors on start-of-name or `::` because a module declared directly
in `tests/cli/main.rs` yields names such as `slow::large_config_round_trip` with no leading
`::`. Proposed: the nextest `--run-ignored` equivalents.

##### Confidence & re-verify trigger

High. Re-verify if libtest stabilises test attributes/tags or nextest adds tag metadata.

##### Sources

- `rust-lang/rust:src/doc/rustc/src/tests/index.md:139-146` (2026-09-26)
- `nextest-rs/nextest:site/src/docs/{selecting.md:8,90-113, running.md:129-133}` (2026-09-26)
- `https://crates.io/api/v1/crates/{test-case,ntest}`; `https://api.github.com/repos/{frondeus/test-case,becheran/ntest}` (2026-09-26)
- `py@b55b8c2` `pyproject.toml:275-278`

#### M6 — Opt-in, default-skip pre-push full-suite hook (pattern)

##### Landscape

Pattern member; crate figures **inapplicable** (the hook runner is R37's pick and is a
tool, not a crate). Options: no hook (py); an opt-in env-gated `pre-push` job (ts
`lefthook.yml:79-87`); a mandatory hook.

##### Principles and implementation

Realises P10. ts's comment states the reasoning: "Tests run at the push boundary, NOT per
commit (D-020(3)): per-commit full suites tax contributor DX and train --no-verify; CI is
the backstop" (`ts@e5100b4` `lefthook.yml:75-78`). Proposed job, written for lefthook
because lefthook is the manager present in both source repos; the file and syntax follow
R37's decision:

```yaml
pre-push:
  jobs:
    - name: test
      run: |
        if [ "${RS_PROJECTS_PREPUSH_TESTS:-0}" = "1" ]; then
          just test
        else
          echo "pre-push tests skipped (opt-in: RS_PROJECTS_PREPUSH_TESTS=1)"
        fi
```

`just test` runs both M1 and M2 commands, so the hook runs the same suite CI runs.

##### Dominant choice

Among the two source repos, ts's env-gated opt-in is the only precedent. No external survey
of Rust projects' pre-push hooks was performed (gap).

##### Qualified shortlist

Opt-in env gate (recommended) versus none. Gates: licence inapplicable (owner ruling
2026-09-12, Q7.B); MSRV/advisories/features inapplicable (shell text); OS: POSIX `sh`
syntax runs on both matrix OSes.

##### Excluded by gate

A mandatory hook is excluded by principle (P10 "never forced"), not by a gate.

##### Up-and-comers

None.

##### Fit for this template

A full Rust suite with a cold `target/` is slow enough that forcing it would train
`--no-verify`, which is ts's recorded concern.

##### Recommendation

Add the opt-in `pre-push` job with variable `RS_PROJECTS_PREPUSH_TESTS`, default skip,
running `just test`. The variable name mirrors ts's `TS_PROJECTS_PREPUSH_TESTS`; P03 may
align the prefix with the final project name.

##### Ranked runner-up

No hook (py's state). Loses nothing in CI but removes a local safety net a contributor can
choose.

##### Tradeoffs

One more environment variable to document; none when unset.

##### Parameters

Assumes `package-manager-invocation` (R42): the hook calls `just test`, with no runner
prefix. The hook manager itself is R37's decision.

##### Migration implications

The hook configuration file gains one `pre-push` job; `CONTRIBUTING`/README documents the
variable.

##### Validation strategy

Proposed (not executed; this run makes no git writes and the probe has no repository):
`lefthook run pre-push` with the variable unset prints the skip line and exits 0; with
`RS_PROJECTS_PREPUSH_TESTS=1` it runs the suite and exits with its status.

##### Confidence & re-verify trigger

Medium: the pattern is simple, but its file and syntax depend on R37. Re-verify when R37
publishes.

##### Sources

- `ts@e5100b4` `lefthook.yml:75-87`
- `docs/port/DIVERGENCE-ANALYSIS.md:142`

### Compatibility

- **Shared adopter.** `astral-sh/uv` uses `cargo-nextest` (`.config/nextest.toml`;
  `.github/workflows/test.yml:120` `cargo nextest run`), `assert_cmd`
  (`Cargo.toml:369`) and R33's `insta` (`Cargo.toml:382`) together, on Linux and macOS
  CI jobs (`test.yml:33` "cargo test on linux", `:156` "cargo test on macos").
- **Doc-test split.** `tokio-rs/tokio` ("test tokio full": `cargo nextest run` then
  `cargo test --doc`, on `ubuntu-latest` and `macos-latest`) and `astral-sh/ruff`
  (`ci.yaml:419-421`) run exactly M1 + M2.
- **Executed together here.** The probe ran the in-process tier (M4), the
  `std::process::Command` and `assert_cmd` built-binary tiers (M3), the `#[ignore]`
  taxonomy (M5) and doc-tests (M2) in one package on rustc 1.98.1 / macOS arm64. M1 was not
  executed.
- **Version matrix (proposed):** rustc floor 1.96 (msrv-policy) ≥ `assert_cmd` 1.85,
  `predicates` 1.74; `cargo-nextest` 0.9.146 declares 1.91 and is a tool, not a dependency.

### Parameters

Owned: none (`- owns:` is empty in the prompt's `## Couplings`).

Assumed values, copied from the run's `inputs/parameters.json` snapshot:

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

`CONFLICT: R11 ci-job-structure — in the check job, the two test steps run cargo nextest run --locked --profile ci (feature off scoped by -p to the non-web packages; feature on over the workspace) instead of cargo test, a cargo test --doc --locked step with the feature on is added after them, and a cargo-nextest install step (channel per R42) precedes them, all under !cancelled() and sharing check's target/ — the registered value names cargo test for both test steps, but stable libtest has no terminating per-test timeout (rustc book tests/index.md:190-195; executed rejection of --ensure-time on 1.98.1), so F125's hung-test-fails-loudly behaviour requires cargo-nextest slow-timeout/terminate-after, and nextest does not run doc-tests (nextest running.md:58), so they need their own step; R11's own table row for R32 delegates the tier commands inside check's test steps to this item, which the controller may judge makes this a non-conflict`

### Migration implications

| File | Change |
|---|---|
| `.config/nextest.toml` | new — M1 configuration |
| `Cargo.toml` | `[dev-dependencies] assert_cmd = "2.2.2"`; optionally `[[test]] name = "cli"`/`"web"` entries (discovery of `tests/<name>/main.rs` also works) |
| `src/lib.rs` (or the CLI module R02 places) | `pub fn run(args, service, out, err) -> ExitCode` |
| `src/main.rs` | composition root + `run`; returns `ExitCode` |
| `tests/cli/{main,support,in_process,binary}.rs` | new CLI tiers |
| `tests/web/main.rs` (+ submodules) | `#![cfg(feature = "web")]`; in-process router tests and the serve-binary tier |
| `Justfile` | `test` = `cargo nextest run --locked {{options}}` then `cargo test --doc --locked`; `test-slow`, `test-live`, `test-all` |
| hook config (R37's file) | opt-in `pre-push` job |
| `.github/workflows/ci.yml` | per the `CONFLICT:` line; R11 owns the edit |

### Validation strategy

**Executed** (scratch crate `/tmp/r32-probe`, outside the repository; `rustc 1.98.1
(48a229cea 2026-09-01)`, `cargo 1.98.1`, host `aarch64-apple-darwin`, macOS; offline,
`--locked`; file hashes (sha256 prefix): `Cargo.toml fcfc4ff87e35fc9d`, `Cargo.lock
2dd6dd8487587d2d`, `src/lib.rs a55deab96ec2ea64`, `src/main.rs 2a71b04c4aaeece3`,
`tests/cli/main.rs dfd0e11f1be1c8cb`, `tests/cli/in_process.rs a5f9f97d1381bc59`,
`tests/cli/binary.rs f47a00705c5d1a02`, `tests/cli/assert_tier.rs b23d261604ea94fe`,
`tests/cli/support.rs 4a7cca487e126223`):

| # | Command | Observed |
|---|---|---|
| 1 | `cargo test --offline --locked` (before `assert_cmd` was added) | `cli` binary: 4 passed, 2 ignored (`ignored, live: requires external services`; `ignored, slow: takes >1s`); doc-test `src/lib.rs - run (line 12) ... ok`; `all doctests ran in 0.45s; merged doctests compilation took 0.21s`; exit 0 |
| 2 | `cargo test --offline --locked --test cli -- --ignored slow_` | `binary::slow_roundtrip ... ok`; `1 passed; … 5 filtered out; finished in 1.51s`; exit 0 |
| 3 | `cargo test --offline --locked --test cli` (after adding `assert_cmd = "2.2.2"`, lock resolved offline "to latest Rust 1.96 compatible versions") | `assert_tier::assert_cmd_lists_projects ... ok`, `assert_tier::assert_cmd_usage_error_exits_2 ... ok`; `6 passed; 0 failed; 2 ignored`; exit 0 |
| 3b | `cargo test --offline --locked --test cli -- --ignored live_` | `binary::live_projects_api ... FAILED` (panics by design); exit 101 |
| 4 | `cargo test --offline --locked --test cli -- --shuffle` | `error: The "shuffle" flag is only accepted on the nightly compiler with -Z unstable-options`; exit 101 |
| 5 | `cargo test … -- -Z unstable-options --shuffle` | `error: the option 'Z' is only accepted on the nightly compiler`; exit 101 |
| 6 | `cargo test … -- -Z unstable-options --ensure-time` | same error; exit 101 |
| 7 | `cargo test --offline --locked --doc` | `test src/lib.rs - run (line 12) ... ok`; exit 0 |
| 8 | `cargo test --offline --locked --test cli -- --ignored slow::` (after adding `mod slow { … fn large_config_round_trip() }` to `tests/cli/main.rs`) | listed name `slow::large_config_round_trip`; `1 passed; … 8 filtered out`; exit 0 |
| 9 | `/usr/bin/time -p cargo test --offline --locked --test sleep_a --test sleep_b` (each one 1,000 ms test) | each `finished in 1.01s`; `real 2.52` → binaries run serially |

**Planned for P03** (not executed here): the six commands under `### Principles and
implementation` → "Executable acceptance check", including the hang negative control under
nextest; the same suite on `ubuntu-latest` and `macos-latest` via R11's `check` matrix; the
MSRV floor build at 1.96 (only 1.98.1 was available locally, so the floor was exercised only
through the resolver's `rust-version`-aware lock, not by compiling on 1.96).

### Confidence & re-verify trigger

**Confidence.** High for M2, M3, M4 and M5 (executed on stable). High that M1 provides the
documented timeout and isolation (maintainer documentation plus six production
configurations), medium on its exact numbers and on the unexecuted configuration file. F124's
capability gap is certain on stable Rust today.

**Re-verify triggers.** rust-lang/rust#89583 (`--shuffle`) or #64888 (`--ensure-time`)
stabilising; nextest issue #16 (doc-tests) closing; a nextest release changing
`slow-timeout` or `CARGO_BIN_EXE_` behaviour; R37 publishing its hook manager; R35 picking a
coverage tool that cannot drive nextest; R11 disposing of the `CONFLICT:` line; R60's clap
wiring or R01's seam changing the `run` signature; a RustSec advisory for `cargo-nextest`,
`assert_cmd`, `predicates` or `wait-timeout`; `nextest-rs/nextest` becoming archived.

**Gaps recorded.** (1) nextest not executed (install endpoints not named by the topic).
(2) Rust survey not consulted (not on a named endpoint). (3) MSRV floor 1.96 not compiled.
(4) No survey of pre-push-hook practice beyond the two source repos. (5) GitHub
responsiveness for `libtest-mimic`, `test-log`, `serial_test`'s OS matrix and `rstest`/`ctor`
OS matrices not collected (not recommended members). (6) nextest's macOS-specific
process-spawn cost not measured. (7) The nextest filterset `test(/(^|::)slow::/)` for module-path
class selection is unexecuted (the libtest `slow::` form was executed and works).

### Sources

All retrieved 2026-09-26.

- crates.io API: `https://crates.io/api/v1/crates/<name>` and `/versions` for `cargo-nextest`,
  `nextest-runner`, `assert_cmd`, `predicates`, `serial_test`, `rstest`, `test-case`, `ntest`,
  `ctor`, `escargot`, `libtest-mimic`, `test-log`, `libtest2-mimic`, `test-r`,
  `cargo-llvm-cov`; `…/assert_cmd/2.2.2/dependencies`; `…/assert_cmd/2.2.2`;
  `…/assert_cmd/reverse_dependencies`.
- GitHub REST: `https://api.github.com/repos/<o>/<r>` for `nextest-rs/nextest`,
  `assert-rs/assert_cmd`, `palfrey/serial_test`, `la10736/rstest`, `frondeus/test-case`,
  `becheran/ntest`, `mmastrac/linktime`, `crate-ci/escargot`, `vigoo/test-r`,
  `assert-rs/libtest2`, and the seventeen surveyed projects; `search/issues` open counts and
  newest-issue lists; issue comment endpoints; contents endpoints for every file cited.
- RustSec: `https://rustsec.org/packages/<name>.html` for `cargo-nextest`, `nextest-runner`,
  `assert_cmd`, `predicates`, `serial_test`, `rstest`, `test-case`, `ntest`, `ctor`,
  `escargot` (all 404); control pages `time`, `chrono` (200).
- First-party documentation: `rust-lang/cargo:doc/book/src/reference/cargo-targets.md`,
  `…/reference/environment-variables.md`, `…/commands/cargo-test.md`;
  `rust-lang/rust:src/doc/rustc/src/tests/index.md`; rust-lang/rust#89583.
- Maintainer documentation: `nextest-rs/nextest:site/src/docs/**` as cited,
  `nextest-runner/default-config.toml`, `nextest-runner/repo-config-reference.md`;
  `palfrey/serial_test` README (`:34-36`, `file_serial` for separate processes);
  `vigoo/test-r:book/src/**`.
- Source repositories: `py@b55b8c2` `Justfile:267,313`, `pyproject.toml:96-98,275-289`,
  `tests/conftest.py:16-31`, `tests/cli/test_pylb.py:9`; `ts@e5100b4` `Justfile:146-147`,
  `lefthook.yml:75-87`, `tests/cli-core.test.ts:11`, `tests/e2e.test.ts:1-49,93-94`,
  `vitest.config.ts`. The prompt's `Justfile:260`, `Justfile:144`, `Justfile:301`,
  `pyproject.toml:97,99,277,278,284` and `lefthook.yml:78` are each one to seven lines off at
  these heads.
- Repository records: `docs/port/DIVERGENCE-ANALYSIS.md:132-142,277-280`;
  `docs/planning/p02/owner-decisions.md:157-160` (licence ruling);
  `research/topics/11-ci-workflow-job-structure/DECISION.md:282`;
  `research/topics/33-property-and-snapshot-testing/DECISION.md` (re-verify trigger);
  run inputs `prerequisites.json`, `parameters.json`.
