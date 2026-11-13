# R32 test-harness-and-execution — raw engine report (muse)

Engine: muse (Meta). Model family: meta. Run: `research/runs/R32/2026-09-26T190208Z-55160c36e3d0`.
Item kind: bundle. Retrieval date for all figures: 2026-09-27 (UTC), via the topic's named
endpoints only (`crates.io/api/v1`, `api.github.com`, `rustsec.org/packages`), plus the local
cargo registry sources already on disk (no network) for `unsafe`/feature inspection.
Independent reading: no other engine report was opened for this item.

### Landscape

Category decided: the Rust test-execution stack for a CLI + library + optional-web-service
template — base runner, CLI test tiers, ordering, per-test timeouts, shared fixtures, file
organization, slow/live markers, parallelism control, doc-test policy, and the pre-push hook.

Three-bin map of the Rust field:

- Built-in / first-party toolchain: `cargo test` + libtest (unit, integration, doc tests;
  `#[ignore]`/`--ignored`; `--test-threads`; filters), `CARGO_BIN_EXE_<name>` env for
  locating built binaries from integration tests, `#[cfg(feature)]`-gated test files.
- Established industry standard: `cargo-nextest` (alternate runner: process-per-test
  isolation, JUnit output, retries, partitioning, filter expressions, `slow-timeout` /
  `terminate-after`), `assert_cmd` + `predicates` + `predicates-tree` (built-binary CLI
  assertions), `tempfile` (scratch dirs), `serial_test` (`#[serial]` / `#[parallel]`
  execution control), `rstest` / `test-case` (fixture injection, case tables).
- Up-and-comer: `libtest-mimic` (custom-harness escape hatch, e.g. trybuild-style suites);
  `escargot` (build-artifact discovery, largely superseded for this use by
  `CARGO_BIN_EXE_<name>` + `assert_cmd::cargo`).

Every shortlisted candidate below comes from this map.

Authoritative sources used and why each counts: (1) the Rust project toolchain itself
(`cargo test`, libtest options) — first-party behavior, normative; (2) maintainer-owned
documentation and repositories (nextest-rs/nextest, assert-rs/*, palfrey/serial_test,
Stebalien/tempfile, la10736/rstest) — authoritative for each tool's own capabilities;
(3) crates.io API records (`crate.downloads`, `recent_downloads`, version `rust_version`,
dependency and reverse-dependency edges) — authoritative for adoption volume and stated
MSRV; (4) GitHub API records (stars, push recency, open-issue counts, comment threads) —
authoritative for maintenance activity; (5) rustsec.org package pages (404 = no advisory
page) — authoritative for known-advisory absence. No blog post is used as authority.

Practice evidence (well-regarded projects, verified via `api.github.com` file reads on
2026-09-27): tokio (`tokio-rs/tokio`, the dominant async runtime; `.github/workflows/ci.yml`
installs cargo-nextest and runs `cargo nextest run --features full` plus a workspace run,
with the comment "Cargo nextest does not support doctest, so we run them separately") —
establishes nextest as CI-authoritative with doctests as a separate `cargo test` step;
cargo-watch (`watchexec/cargo-watch`, the standard file-watching dev tool; root `Cargo.toml`
contains `assert_cmd = "1.0.8"`) and rav1e (`crates.io reverse_dependencies` top edge for
assert_cmd, 55.7M edge downloads) — establish assert_cmd as the standard built-binary CLI
harness; bat (`sharkdp/bat`, the standard `cat` replacement; root `Cargo.toml` contains
`serial_test = { version = "2.0.0", default-features = false }`), crossterm and axum-server
(top `reverse_dependencies` edges for serial_test) — establish serial_test for execution
control. Download volume corroborates: serial_test 155.1M all-time / 31.5M recent-90d,
assert_cmd 86.4M / 18.1M, tempfile 838.2M / 190.4M, rstest 124.7M / 28.1M,
cargo-nextest 13.0M / 1.9M (a binary, installed rather than depended on, so lower volume
is expected). Retrieval: `GET https://crates.io/api/v1/crates/<name>`, 2026-09-27.

Fit framing: the template is CLI-first with a library core and an off-by-default `web`
feature (R69), one `[[bin]]` named `rslbp` plus a `web`-gated serve binary, `CARGO_BIN_EXE_`
resolution (R49), edition 2024, MSRV floor ≈ stable-minus-2 (≈1.96 given locally observed
rustc 1.98.1 on 2026-09-27 — approximate, not endpoint-verified), CI on ubuntu + macOS.
py precedent supplies the execution-behavior checklist (shuffle, timeout, markers,
parallel flag, autouse fixture); ts precedent supplies the two-tier CLI shape, flat layout,
local factories, and the opt-in pre-push hook. Neither is assumed the winner; each
mechanism is re-derived against Rust toolchain behavior below.

### Principles and implementation

Shared principles (scoped to this item's rows in `docs/port/DIVERGENCE-ANALYSIS.md`, item
table lines for R32/F117–F132/F173):

1. P-exec (class D/B, capability level): the suite executes deterministically and its
   failure signals are reproducible and attributable. Must agree: hermetic per-test
   execution, stable pass/fail attribution, replayable runs. May vary: the runner binary
   and config surface (`cargo test` vs nextest vs pytest vs Vitest).
2. P-tiers (F118, class D, architectural-pattern level, harmonize yes): CLI behavior is
   verified at two tiers — fast in-process tests against the composed entry function and a
   built-artifact subprocess tier. Must agree: both tiers exist with a staleness-safe
   rebuild story. May vary: the in-process seam shape (follows R01's port) and the
   subprocess assertion library.
3. P-budget (F124/F125, class D, capability level, harmonize yes): order-independence is
   enforced structurally and every test has a bounded execution budget. Must agree: no
   test can hang the suite silently; order coupling is detected or impossible. May vary:
   shuffle-vs-isolation as the order mechanism, timeout mechanism and default seconds.
4. P-scope (F129/F130, class F/C, policy level): layout and markers make "what runs by
   default" obvious and cheap to slice. Must agree: default suite is fast and hermetic;
   slow/live work is opt-in and labeled. May vary: file layout and marker mechanism.
5. P-parity-cost (F131, class E): parallelism is a default, not a prize. Must agree:
   nothing in the template serializes the suite except declared shared-state tests.
   No mechanism needed in Rust beyond the toolchain default.
6. P-doctest (F132, class G, Rust-only): doc examples are executed in CI. Rust-only; no
   cross-repo agreement applies.
7. P-hook (F173, class D, policy level, harmonize yes): a full-suite pre-push hook exists
   but is opt-in and default-skip, env-gated. Must agree: the gate exists and defaults
   off. May vary: hook manager and env-var name (manager mechanics belong to R37).

Observable acceptance criteria: (a) `cargo nextest run` executes unit + integration tiers
with per-test process isolation; (b) a deliberately hung test is terminated and reported
within the configured budget; (c) `#[ignore]`d slow/live tests are skipped by default and
runnable via one documented opt-in command; (d) `cargo test --doc` runs in the CI gate;
(e) the pre-push hook is a no-op unless its env var is set; (f) default CI legs stay green
on ubuntu-latest and macOS.

Architectural alternatives compared before libraries: (A) libtest-only (`cargo test` for
everything): zero new tools, doctests unify, but no per-test timeout enforcement (a hung
test hangs the binary until the CI job timeout), no retries/partitioning/JUnit, threads
share one process per binary; (B) nextest-primary with `cargo test --doc` alongside
(tokio's shape): isolation, budgets, retries, sharding, at the cost of one more CI tool
install and two test commands; (C) custom libtest-mimic harness: full control incl. true
shuffling, but a bespoke runner to maintain for a template — rejected, disproportionate
integration cost. (B) wins: it preserves P-exec/P-budget natively while (A) cannot meet
the bounded-budget criterion at all. Ordering: neither Rust runner shuffles like
pytest-randomly; nextest's per-test process isolation plus libtest's multi-threaded
scheduling gives the stronger guarantee (shared-state coupling fails loudly instead of
order-dependently), so the justified difference is isolation-instead-of-shuffle, preserving
P-budget's intent without copying py's mechanism.

`BASELINE-REVIEW:` none — no inherited baseline row is challenged by this answer; all
DIVERGENT rows are resolved as designed differences with rationale, not ledger changes.

Minimal realistic example (proposed, not executed this run): `tests/cli_in_process.rs`
calls the library's `run(argv, &InMemoryProjectsPort)` entry; `tests/cli_binary.rs` uses
`assert_cmd::cargo::cargo_bin!("rslbp")` + `predicates::str::contains` + a `tempfile::TempDir`
as cwd; `.config/nextest.toml` sets `slow-timeout` 60s with `terminate-after`;
`#[ignore = "slow: ..."]` marks the live tier; CI runs nextest then `cargo test --doc`.
Executable acceptance check: `cargo nextest run --workspace --all-features` green,
`cargo nextest run --run-ignored all` green, `cargo test --doc` green, and a 1s-timeout
canary test red — planned, not run (no execution was performed in this leg).

### Recommendation

One stack: `cargo-nextest 0.9.146` as the CI-authoritative and `just test` default runner
(P-exec, P-budget, P-parity-cost); `cargo test --doc` retained as the doctest step (P-doctest,
nextest cannot run doctests — tokio CI comment, verified 2026-09-27); two CLI tiers with
the built-binary tier on `assert_cmd 2.2.2` + `predicates 3.1.4` + `tempfile 3.27.0`
dev-dependencies (P-tiers); local factory helpers plus `serial_test 3.5.0`
(`default-features = false`) for shared-state serialization, no global setup file (P-scope,
ts D-019(5) precedent); order-independence via process isolation rather than shuffling,
per-test budget via nextest `slow-timeout`/`terminate-after` at 60s echoing py (P-budget);
`#[ignore]` + nextest `--run-ignored`/profiles for the slow/live taxonomy (P-scope);
default parallelism with `--partition` for sharding, no opt-in flag (P-parity-cost);
flat tier-named `tests/` files + `tests/common/mod.rs` (P-scope); opt-in default-skip
pre-push hook running the nextest default profile behind an env var, manager mechanics
deferred to R37 (P-hook).

### Members

#### test-runner

##### Landscape

Sub-category: base test-execution tool (F117 core; carries F124/F125/F131 behavior).
Bins: built-in — `cargo test`/libtest (ships with every toolchain; unit + integration +
doc tests; `--test-threads`, filters, `#[ignore]`); established — `cargo-nextest 0.9.146`
(`https://github.com/nextest-rs/nextest`, dual Apache-2.0 OR MIT per crates.io versions
record); up-and-comer — `libtest-mimic 0.8.2` (31.5M all-time / 5.1M recent downloads,
custom-harness kit). Figures (retrieved 2026-09-27): nextest 12,951,672 all-time /
1,888,286 recent-90d (`GET https://crates.io/api/v1/crates/cargo-nextest`); last release
0.9.146 on 2026-09-21, rust-version 1.91
(`GET https://crates.io/api/v1/crates/cargo-nextest/versions`); GitHub 3303 stars, not
archived, pushed 2026-09-26T06:14:54Z
(`GET https://api.github.com/repos/nextest-rs/nextest`); 76 open issues
(`GET https://api.github.com/search/issues?q=repo:nextest-rs/nextest+is:issue+is:open`);
rustsec page 404 = no advisories (`https://rustsec.org/packages/cargo-nextest.html`).
Maintenance state: `active` (weekly releases, push within 1 day).

##### Principles and implementation

Carries P-exec (isolation, attribution) and P-budget (bounded time) at capability level.
nextest runs each test in its own process, several concurrently: a hung or crashing test
cannot wedge its neighbors, and failures attribute to one test id. `slow-timeout`
(period + `terminate-after`) terminates over-budget tests — the native answer to HIGH
question 1's timeout half, no extra crate. Ordering half: nextest has no seeded shuffle;
its answer is structural — per-test processes plus concurrent scheduling make
order-coupling fail loudly rather than pass accidentally, which preserves P-budget's
intent (detect order dependence) more strongly than py's shuffle-then-hope. Partitioning
(`--partition count:M/N`) and `--retries` serve CI sharding and flake quarantine.
Known limit, verified in practice: nextest does not execute doctests (tokio pins a
separate doctest step for exactly this reason), so P-doctest needs `cargo test --doc`
alongside. Fitness gates: (1) Apache-2.0 OR MIT, compatible; (2) rust-version 1.91 is an
install-time requirement for the runner binary only — it never enters the template's
`rust-version` floor, and 1.91 <≈1.96 floor regardless; (3) no rustsec page; the runner
is not linked into shipped artifacts so `unsafe` posture is out of scope for the template
audit surface; (4) repo has `.github/workflows` (contents API 200, 2026-09-27) and ships
multi-platform binaries; per-OS leg proof is an acceptance-check item, not a gate fail;
(5) n/a (binary, no features); (6) zero template compile cost (not a dependency), one CI
install step (~1 min via prebuilt binary).

##### Dominant choice

`cargo-nextest 0.9.146`: the only established Rust runner beyond libtest; 1.9M
downloads/90d, 3303 stars, tokio-verified CI pattern, native timeout/partition/retry.

##### Qualified shortlist

`cargo test`/libtest (built-in; kept for `--doc` and as the zero-tool fallback):
authoritative by definition, zero cost, but no per-test timeout, no retries, no JUnit,
thread-shared process per binary. No other established runner exists in the ecosystem.

##### Excluded by gate

None. Both candidates pass all six gates (libtest trivially — it is the toolchain).

##### Up-and-comers

`libtest-mimic 0.8.2` (rust 1.65, MIT/Apache-2.0, last release 2026-03-16): powers
trybuild-style custom harnesses; could implement true shuffling, but a bespoke harness
is unjustifiable maintenance for a template. Watch only.

##### Fit for this template

CLI + lib + gated-web needs tier slicing (nextest filter expressions and profiles),
bounded CLI-subprocess tests (timeouts), and CI sharding headroom (partition) — all
native. The `web` feature composes via `--features web` on the same command R69's
consumers already use. MSRV/edition constraints are untouched (binary, not a dep).

##### Recommendation

`cargo-nextest 0.9.146`, CI-authoritative and the `just test` default; `cargo test` kept
for `cargo test --doc` and documented fallback. `.config/nextest.toml` pins
`slow-timeout = { period = "60s", terminate-after = 2 }` (60s echoes py's
`timeout = 60`; terminate-after-2 bounds a hung test at ~3 min worst case).

##### Ranked runner-up

`cargo test`-only (option A): acceptable if the owner rejects a second test tool, at the
price of losing per-test budgets (P-budget unmet) — rank 2, material capability loss.

##### Tradeoffs

nextest-primary costs one CI install step and a doctest sidecar command; it buys
isolation, budgets, retries, sharding, and JUnit. libtest-only costs nothing and unifies
doctests but cannot bound a hung test below the CI job timeout. No throughput claim is
made: no benchmark was run (per the evidence rules, unlike-benchmark comparison is
refused).

##### Parameters

Assumes `rust-edition = 2024`, `msrv-policy`, `target-os-matrix`, `license` (fixed, no
effect — binary tool). No owned or consumed researched parameter is set by this member.

##### Migration implications

Add `.config/nextest.toml` (profiles + slow-timeout); `just test` invokes
`cargo nextest run` (+ `cargo test --doc` step); CI installs nextest via prebuilt binary
before the test step; document `cargo test` fallback. No `Cargo.toml` dependency change.

##### Validation strategy

Planned (not executed): `cargo nextest run --workspace --all-features` green;
canary `#[test] fn hangs(){ loop{} }` is terminated and reported after ~3 min;
`cargo nextest list` shows unit + integration tiers; doctest sidecar green. Expected:
per-test attribution, bounded hang, doctests separate.

##### Confidence & re-verify trigger

High. Re-verify if nextest 0.10 changes config schema or doctest support, or if
rust-version floor drops below 1.91 (install-time MSRV).

##### Sources

`GET https://crates.io/api/v1/crates/cargo-nextest` (downloads, repo link);
`GET https://crates.io/api/v1/crates/cargo-nextest/versions` (0.9.146, 2026-09-21,
rust 1.91, Apache-2.0 OR MIT); `GET https://api.github.com/repos/nextest-rs/nextest`
(3303 stars, pushed 2026-09-26); search-issues open count 76; 5-issue response sample
(#3556 +0.0d, #3533 +1.2d, #3512 +0.1d, #3511 +0.6d maintainer replies, #3542 reporter-only —
median ≈0.4d over answered sample, 1/5 unanswered); `https://rustsec.org/packages/cargo-nextest.html`
404; tokio `.github/workflows/ci.yml` nextest usage + doctest comment (contents API);
all retrieved 2026-09-27.

#### cli-blackbox

##### Landscape

Sub-category: built-binary subprocess CLI test tier (F118 second tier; F128-adjacent cwd
isolation). Bins: built-in — `std::process::Command` + `CARGO_BIN_EXE_<name>` (R49's
resolution contract; zero deps, maximal boilerplate); established — `assert_cmd 2.2.2`
(binary discovery via `assert_cmd::cargo`, fluent assertions) with `predicates 3.1.4`
(composable output matchers) and `tempfile 3.27.0` (scratch cwd); up-and-comer — none
credible (`escargot` overlaps the discovery half only). Figures (2026-09-27):
assert_cmd 86,407,572 / 18,054,857, release 2.2.2 on 2026-05-11, rust 1.85, MIT OR
Apache-2.0; predicates 230,472,028 / 41,756,139, 3.1.4 on 2026-02-11, rust 1.74;
tempfile 838,197,147 / 190,443,618, 3.27.0 on 2026-03-11, rust 1.63
(`GET https://crates.io/api/v1/crates/<name>` + `/versions`). GitHub: assert_cmd 563
stars pushed 2026-09-01, predicates-rs 213 stars pushed 2026-09-14, tempfile 1468 stars
pushed 2026-09-18, none archived; assert_cmd 24 open issues; all three rustsec 404.
States: assert_cmd `active`, predicates `stable-quiet` (7-month release gap with
fortnight-old pushes — trigger investigated, still maintained), tempfile `active`.

##### Principles and implementation

Carries P-tiers' subprocess half at pattern level: spawn the real `rslbp` binary built by
Cargo (staleness-safe by construction — Cargo rebuilds before `cargo test`), assert on
exit code / stdout / stderr with composable predicates, isolate filesystem effects in a
tempdir cwd. In-process tier (pattern, no crate): call the library entry with R01's
`InMemoryProjectsPort` — fastest, hermetic, covers CLI wiring below the process boundary.
Fitness gates (assert_cmd 2.2.2, verified against local registry source + crates.io):
(1) MIT OR Apache-2.0 ✓; (2) rust-version 1.85 ≤ ≈1.96 floor ✓; direct deps all ancient
and compatible (bstr 1.65, libc 0.2.189/1.65, predicates-core 1.74, anstyle 1.66,
wait-timeout 0.2.1 undeclared-but-trivially-old, predicates 1.74) ✓; (3) rustsec 404;
`unsafe` audit of vendored source: assert_cmd zero `unsafe` items, predicates only
`unsafe impl Send/Sync` marker impls (no `unsafe` blocks), dev-dependency-only anyway ✓;
(4) `.github/workflows` present (200); pure-Rust + libc, ubuntu + macos per-OS proof is
acceptance-check ✓/pending; (5) default features EMPTY (only opt-in `color`/`color-auto`),
no async runtime ✓; (6) dev-only, zero shipped-binary cost; small proc-macro-free graph,
fast to compile ✓. predicates/tempfile gates: same license family, MSRV 1.74/1.63 ✓,
rustsec 404, tempfile default = ["getrandom"] (no async) ✓.

##### Dominant choice

`assert_cmd 2.2.2` + `predicates 3.1.4` + `tempfile 3.27.0`: 86M/230M/838M all-time
downloads; cargo-watch and rav1e reverse-dependency adoption; edition-2024-native
assert_cmd (verified in vendored `Cargo.toml`).

##### Qualified shortlist

Hand-rolled `std::process::Command` + `CARGO_BIN_EXE_rslbp` + `std::env::temp_dir`:
zero deps, but every assertion and cleanup is bespoke — acceptable for ≤3 smoke tests,
rejected as the template default because templates are copied, and copied boilerplate
rots. `escargot 0.5.15` (11.1M / 2.5M, rust 1.70, 58 stars): artifact-builder API;
overlaps only discovery, adds no assertions — rejected, narrower than assert_cmd.

##### Excluded by gate

None — all shortlisted candidates pass; the std-only option passes trivially.

##### Up-and-comers

None in this sub-category; the discovery half is stable technology and the assertion half
is owned by predicates. No watch item.

##### Fit for this template

R49 fixes `[[bin]] name = "rslbp"` + `CARGO_BIN_EXE_rslbp`; `assert_cmd::cargo::cargo_bin!`
consumes exactly that contract, and the `web`-gated serve binary gets the same treatment
when R69's binary exists. ts D-019(4)'s staleness-aware-rebuild requirement is satisfied
by Cargo's own rebuild-before-test. In-process tier follows R01's port seam
(`ProjectsService<Arc<dyn ProjectsPort>>` + shipped in-memory fake).

##### Recommendation

Dev-dependencies `assert_cmd 2`, `predicates 3`, `tempfile 3` (pinned `2.2.2` / `3.1.4` /
`3.27.0` at adoption); `tests/cli_binary.rs` uses `cargo_bin!("rslbp")`, predicate
assertions, per-test tempdir cwd; `tests/cli_in_process.rs` calls the library entry with
the in-memory fake. No `color` feature (keeps graph minimal; CI logs stay plain).

##### Ranked runner-up

Hand-rolled std-only subprocess tests: rank 2, zero-dep purity at the cost of bespoke
assertions in every copied template. Revisit only if the owner caps dev-dependencies.

##### Tradeoffs

assert_cmd buys readable one-liner assertions (`assert().success().stdout(predicate)`)
and correct binary discovery for ~7 small deps, dev-only. Cost: a third-party API in the
template's most-copied files (mitigated: assert-rs is the clap-adjacent house style,
epage-maintained, and the API has been 2.x-stable for years).

##### Parameters

Assumes `rust-edition = 2024` (assert_cmd 2.2.2 is itself edition 2024),
`target-os-matrix`, `license`, `msrv-policy` (all satisfied per gates above).
No parameter owned or changed.

##### Migration implications

`Cargo.toml [dev-dependencies]`: `assert_cmd = "2"`, `predicates = "3"`,
`tempfile = "3"`; new `tests/cli_binary.rs` (+ `tests/cli_in_process.rs` with no new
deps); `tests/common/mod.rs` hosts the argv builders and tempdir helper.

##### Validation strategy

Planned: `tests/cli_binary.rs` asserts `rslbp --help` exits 0 with stdout containing the
binary name; a negative test asserts nonzero exit + stderr predicate on bad argv; run the
file under both runners. Expected: green on ubuntu + macos, binary auto-rebuilt when
`src/` changes (touch-src-then-test shows rebuild).

##### Confidence & re-verify trigger

High. Re-verify if assert_cmd 3.x releases with breaking discovery API, or if R49's
binary name/resolution contract changes (discovery call sites move with it).

##### Sources

crates.io `/crates/{assert_cmd,predicates,tempfile}` + `/versions` (downloads, releases,
rust_version, licenses); `/crates/assert_cmd/2.2.2/dependencies` (dep list) and
`/versions` feature maps (assert_cmd no default features; tempfile default getrandom);
reverse_dependencies top edges (cargo-watch `assert_cmd = "1.0.8"`, rav1e 55.7M-edge,
notify/tokio-native-tls for tempfile); `api.github.com/repos/{assert-rs/assert_cmd,
assert-rs/predicates-rs,Stebalien/tempfile}` (stars/push); assert_cmd open-issue count
24 + 5-issue sample (#310 +0.2d, #269 +0.6d, #268 +0.0d maintainer replies; #266
reporter-only; #285 answered +147.8d by a non-maintainer — median ≈0.4d over maintainer
answers, 1/5 maintainer-unanswered); rustsec 404 ×3; vendored sources
`~/.cargo/registry/.../{assert_cmd-2.2.2,predicates-3.1.4}` (`unsafe` grep, edition,
features); all retrieved 2026-09-27.

#### fixture-isolation

##### Landscape

Sub-category: cross-test shared-state control (F128) and parallelism guardrails (F131
overflow). Bins: built-in — `std::sync::OnceLock` + racy-test discipline (zero deps;
covers one-time setup, not mutual exclusion), nextest process isolation (covers
process-global state, not file/port contention); established — `serial_test 3.5.0`
(`#[serial]` / `#[parallel]`, file locks optional); up-and-comer — `rstest 0.27.0`
(fixture injection + case tables, DI-flavored). Figures (2026-09-27): serial_test
155,139,513 / 31,500,096; 3.5.0 on 2026-05-30 rust 1.68 MIT (4.0.1 exists since
2026-07-25, rust 1.93.1 — see Tradeoffs); rstest 124,726,954 / 28,127,593, 0.27.0 on
2026-09-06 rust 1.85. GitHub: palfrey/serial_test 296 stars pushed 2026-09-05, 0 open
issues (`has_issues: true`, `open_issues_count: 0`); la10736/rstest 1588 stars pushed
2026-09-06. rustsec 404 both. States: serial_test `active`, rstest `active`.

##### Principles and implementation

Carries P-scope's hermetic-default half and P-parity-cost's exception path: the default
stays fully parallel; only tests that touch genuinely shared mutable state (cwd, env
vars, ports, a fixed-path socket) declare `#[serial]`, and nextest still isolates them
per-process. There is deliberately NO global autouse setup file: ts D-019(5) rejected
implicit global state for DI-first hermetic tests, and R01's seam (injected `Arc<dyn
ProjectsPort>` + shipped in-memory fake) makes Rust tests hermetic by construction —
py's `conftest.py` logger reset has no Rust analogue because Rust has no global test
runner state to reset; per-test setup lives in local factory helpers in
`tests/common/mod.rs`. serial_test is the narrow mutual-exclusion tool, not a fixture
framework. Fitness gates (serial_test 3.5.0): (1) MIT ✓; (2) rust-version 1.68 ✓ with
deep headroom; deps once_cell 1.65, parking_lot 0.12.5/1.71 ✓ (fslock/file_locks
opt-out); (3) rustsec 404; `unsafe` posture not source-verified this run (not in local
registry; no download permitted beyond named endpoints) — mitigated: dev-only,
synchronization primitives delegate to parking_lot/once_cell, evidence gap recorded;
(4) workflows present (200); pure-Rust, ubuntu + macos acceptance-check; (5) default =
["logging","async"] — RECOMMEND `default-features = false` (bat precedent) to drop the
futures/log coupling unless async tests need it; (6) dev-only, small graph (derive
macro + parking_lot) ✓.

##### Dominant choice

`serial_test 3.5.0` with `default-features = false`: 155M downloads, bat/crossterm/
axum-server adoption, MSRV 1.68, zero open issues.

##### Qualified shortlist

`rstest 0.27.0` (fixture injection, `#[fixture]`, case tables; 1588 stars, MIT OR
Apache-2.0, rust 1.85): the DI-flavored alternative matching ts's factory-helper spirit
mechanically. Rejected as default: proc-macro framework for what local `fn` helpers do
in ~10 lines, and case-table parametrization borders R33's owned territory (F122/F123) —
do not pre-empt R33. Pure-`OnceLock` discipline: viable for setup-once, cannot express
mutual exclusion — rejected as insufficient for port/cwd tests.

##### Excluded by gate

None. (`test-case 3.4.0`, 64.6M downloads, was considered for case tables and set aside
as R33-adjacent, not gate-failed.)

##### Up-and-comers

None; mutual exclusion is solved technology. `rstest` 0.2x→0.27 churn is watched only
as a potential future fixture idiom if factories grow unwieldy.

##### Fit for this template

CLI tests that chdir into tempdirs are hermetic by construction (tempfile); the residual
shared-state surface is tiny (env-var tests, a fixed-port web smoke test if R69's serve
binary binds one) — exactly the `#[serial]`-on-a-few-tests shape. Works identically
under libtest and nextest. No interaction with R05's sync/async call when
`default-features = false` (enable `async` later only if async tests need it).

##### Recommendation

Dev-dependency `serial_test = { version = "3", default-features = false }`; local
factory helpers in `tests/common/mod.rs` for fixtures; `#[serial]` only on tests that
touch process- or machine-global state, each with a comment naming the shared resource.

##### Ranked runner-up

`rstest 0.27.0`: rank 2 — richer fixtures at the cost of a proc-macro framework and R33
adjacency. Adopt only if factory helpers demonstrably rot (duplication across 3+ files).

##### Tradeoffs

serial_test 3.x vs 4.x: 4.0.1 (2026-07-25, MSRV 1.93.1) is two months old with unknown
(to this leg) breaking changes; 3.5.0 (2026-05-30, MSRV 1.68) is proven at bat-scale
adoption. Pin 3.x now, re-verify 4.x at the next quarterly trigger. `default-features =
false` avoids futures/log coupling (bat precedent) at the cost of re-enabling `async`
if async tests arrive — a one-line change.

##### Parameters

Assumes `msrv-policy` (1.68 satisfies), `rust-edition`, `target-os-matrix`, `license`
(all satisfied). No parameter owned or changed.

##### Migration implications

`Cargo.toml [dev-dependencies]`: `serial_test = { version = "3", default-features =
false }`; `tests/common/mod.rs` factory helpers; `#[serial]` annotations on the
enumerated shared-state tests only.

##### Validation strategy

Planned: two `#[serial]` tests that would race on one env var pass consistently under
`--test-threads=16` and under nextest; removing one `#[serial]` makes the pair flaky
(demonstrates the guard is load-bearing, then restore). Expected: green with, flaky
without.

##### Confidence & re-verify trigger

High on the pattern (local factories + narrow `#[serial]`), medium-high on the 3.x pin.
Re-verify: serial_test 4.x changelog at next quarterly check; `unsafe`-posture source
read when the crate enters the local registry; R05 async decision may add the `async`
feature.

##### Sources

crates.io `/crates/serial_test` + `/versions` (155.1M/31.5M; 3.5.0 2026-05-30 rust 1.68
MIT; 4.0.1 2026-07-25 rust 1.93.1); `/crates/serial_test/3.5.0` feature map (default
logging+async; file_locks optional); `/crates/serial_test/4.0.1/dependencies` direct-dep
list (once_cell, parking_lot, serial_test_derive); dep MSRVs (once_cell 1.65,
parking_lot 0.12.5/1.71, anstyle 1.66, serial_test_derive 4.0.1/1.93.1);
reverse_dependencies top edges (bat `serial_test = { version = "2.0.0",
default-features = false }` verified in root Cargo.toml, crossterm, axum-server);
`api.github.com/repos/palfrey/serial_test` (296 stars, pushed 2026-09-05, 0 open
issues); `/repos/la10736/rstest` (1588 stars, pushed 2026-09-06); rstest versions
(0.27.0 2026-09-06 rust 1.85); rustsec 404 ×2; all retrieved 2026-09-27.

#### layout-markers-hooks

##### Landscape

Sub-category: test file organization (F129), slow/live marker taxonomy (F130),
parallelism control surface (F131), doc-test policy (F132), pre-push hook (F173).
This member is a PATTERN member: no crate is recommended, so per-prompt crate figures
are `inapplicable` — stated per figure with reason instead of silently omitted:
downloads/releases/stars/issues/advisories/adopters do not exist for `#[ignore]`,
file layout, or hook wiring; authority here is the Rust toolchain (libtest semantics),
the R49/R11/R69/R42 accepted decisions, and the ts precedent (D-019(2), lefthook.yml:78).
Bins: built-in — `tests/*.rs` integration binaries, `#[ignore]` + `--ignored` /
`--run-ignored`, `--test-threads`, `cargo test --doc`, nextest profiles; established —
tier-named files + `tests/common/mod.rs` (Rust community standard layout); rejected
leads — `cfg`-gated features for slow/live (conflates build surface with test slicing),
third-party tag crates (no standard exists; rstest/test-case are case tools, not tag
systems).

##### Principles and implementation

Carries P-scope (layout + markers) and P-hook at policy level, P-parity-cost as default,
P-doctest as Rust-only rule. F129 layout: flat tier-named files —
`tests/cli_in_process.rs`, `tests/cli_binary.rs`, `tests/web.rs` (`#![cfg(feature =
"web")]` per R69's file-level gating), `tests/common/mod.rs` (helpers; `mod common;`
per file) — mirroring ts's flat D-019(2) shape. Justified difference from py's
`tests/{cli,core,meta,web}/` mirroring: each Rust integration file is a separately
compiled crate, so deep mirroring multiplies compile cost with zero execution benefit;
tier-named flat files preserve the navigability principle at Rust's compile granularity.
F130 markers: `#[ignore]` (+ reason string, e.g. `#[ignore = "live: needs network"]`)
with default runs skipping them under BOTH runners; opt-in via `cargo test -- --ignored`
or nextest `--run-ignored all` / a `[profile.live]` in `.config/nextest.toml`. No crate:
libtest `#[ignore]` semantics are stable toolchain behavior, and nextest honors them —
a `cfg`-feature would fork the build graph for a test slice (rejected: wrong layer), and
no tag crate is standard. F131: NO flag — `cargo test` and nextest parallelize by
default; sharding uses nextest `--partition` (CI concern, not template default). F132:
CI gate includes `cargo test --doc` as its own step (nextest cannot run doctests; tokio
precedent). F173: opt-in default-skip pre-push hook running the nextest default profile,
env-gated in ts's `TS_PROJECTS_PREPUSH_TESTS=1` pattern (Rust-side var name is R37's
hook-content call to ratify; mechanics/distribution are R37's, this member scopes only
which suite the hook runs). Fitness gates: inapplicable as crate gates (no crate, no
MSRV/license/advisory/unsafe surface, no compile cost beyond test binaries themselves);
toolchain features used (`#[ignore]`, `--doc`, env-gated hooks) are stable on every
supported toolchain and OS by definition.

##### Dominant choice

The toolchain-native pattern above: flat tier files + `tests/common`, `#[ignore]`
taxonomy, default parallelism, doctest sidecar step, env-gated pre-push hook. Dominant
by standardization, not by download count (inapplicable metric, reason stated).

##### Qualified shortlist

`cfg`-feature-gated slow/live (`--features live-tests`): explicit and discoverable, but
conflates Cargo's build-feature graph (which R69 already uses for `web`) with test
slicing; every slice doubles feature-combination CI legs. Rejected: wrong layer.
Directory-mirrored layout (`tests/cli/…` with `#[path]` roots): preserves py's shape
literally, but each subdir still needs a root binary and `#[path]` wiring is
unidiomatic. Rejected: pays compile + complexity cost for familiarity alone.

##### Excluded by gate

None (pattern member; no crate reached a gate).

##### Up-and-comers

Nextest filter-expression profiles (`-E`, `default-filter`) as the machine-readable
expression of the `#[ignore]` taxonomy: already usable in 0.9.x for CI slicing; watch
for suffered-schema changes at 0.10. No crate watch item.

##### Fit for this template

The layout maps 1:1 onto R49's targets (`rslbp` binary tier, lib unit tests, `web`-gated
serve tier) and R69's file-level `#![cfg(feature = "web")]` rule; the hook's suite
(nextest default profile) matches R11's `cargo test`-scoped check steps in shape while
leaving job-graph placement to R11; env-gating matches R42's bare-executable invocation
style (no runner prefix in the hook command).

##### Recommendation

Adopt the pattern exactly as in Principles: flat tier-named `tests/` + `tests/common`,
`#[ignore]`-with-reason taxonomy + nextest profiles, no parallel flag, `cargo test --doc`
in the gate, env-gated default-skip pre-push hook running the default profile.

##### Ranked runner-up

`cfg`-feature test slicing: rank 2 — adopt only if `#[ignore]` reasons prove
undiscoverable in practice (no evidence for that today) or R11 needs feature-shaped
skip keys (it keys on paths, so no).

##### Tradeoffs

`#[ignore]` is slightly less discoverable than named markers (`-- --ignored` is
tribal knowledge) — mitigated by documenting the two commands in the template README
and the Justfile recipe. Flat files scale poorly past ~10 integration binaries
(compile time) — mitigated: this template has 3–4 by construction; revisit if the
suite grows past 8 files.

##### Parameters

Assumes `rust-edition`, `msrv-policy`, `target-os-matrix`, `license` (fixed; toolchain
features used are stable everywhere). Assumes R69 `web-extra-surface` file-gating rule
and R49 binary-name contract as the layout's anchors. No parameter owned or changed.

##### Migration implications

`tests/cli_in_process.rs`, `tests/cli_binary.rs`, `tests/web.rs` (web-gated),
`tests/common/mod.rs`; `#[ignore = "<slow|live>: <reason>"]` annotations;
`[profile.live]` (+ optional `default-filter`) in `.config/nextest.toml`; pre-push hook
entry (content: default-profile nextest run; wiring per R37); README + Justfile document
the two opt-in commands.

##### Validation strategy

Planned: default `cargo nextest run` skips annotated tests (count visible in summary);
`cargo nextest run --run-ignored all` executes them; `cargo test --doc` green;
pre-push hook with env unset is a no-op (exit 0, suite not started — assert via hook
trace), with env set runs the suite. Expected: skip/run/skip-run matrix green.

##### Confidence & re-verify trigger

High on layout + `#[ignore]` + doctest step (stable toolchain behavior); medium on
nextest profile/filter spellings (verify against nextest 0.9 docs at synthesis time —
not re-verified via named endpoints this run). Re-verify on R37 hook-manager decision
(env-var name + install mechanics) and nextest 0.10.

##### Sources

Pattern member: no crates.io/GitHub/rustsec figures apply (reasons stated in Landscape).
Sources are the run's own inputs (R49 binary-name/`CARGO_BIN_EXE` contract, R69
file-level web gating, R11 check-step shape, R42 invocation style — all in
`inputs/parameters.json`, accepted decisions), the item prompt's ts precedent
(D-019(2) flat layout, `lefthook.yml:78` env-gated pre-push), the DIVERGENCE-ANALYSIS
R32 rows (F129 class F, F130 class C, F131 class E, F132 class G, F173 class D), and
tokio's doctest-sidecar CI shape (verified via contents API 2026-09-27). Nextest
`--run-ignored`/profile spellings are maintainer-documented behavior not re-fetched
this run — flagged for synthesis-time confirmation.

### Compatibility

Proof the members compose: (1) shared-adopter composition — tokio runs nextest for
unit+integration tiers with a `cargo test --doc` sidecar (member 1 + member 4's F132
rule, verified in tokio `.github/workflows/ci.yml` 2026-09-27); cargo-watch composes
assert_cmd-based CLI tests under the standard runners (member 2 under member 1);
bat composes serial_test execution control inside a suite that also runs CLI
black-box tests (members 2+3 under member 1); (2) contract composition — member 2's
`cargo_bin!("rslbp")` consumes R49's `CARGO_BIN_EXE_rslbp` contract which both runners
set identically; member 3's `#[serial]` is runner-agnostic (works under libtest threads
and nextest processes); member 4's `#[ignore]` is honored by both runners and its
`tests/web.rs` gating keys on R69's `web` feature flag passed identically to both
runners; (3) version matrix (all 2026-09-27): cargo-nextest 0.9.146 + assert_cmd 2.2.2
+ predicates 3.1.4 + tempfile 3.27.0 + serial_test 3.5.0 (default-features=false) —
no shared-dependency version conflicts (dependency lists pulled per member show disjoint
graphs except predicates-core/predicates-tree inside member 2's own tree). No two
members prescribe conflicting commands: the doctest sidecar is the only second command,
and it is required by member 1's own documented limit.

### Parameters

This item owns no parameters.

- assumes `rust-edition = 2024`
- assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- assumes `target-os-matrix = ubuntu-latest, macos-latest`
- assumes `license = MIT OR Apache-2.0`
- assumes `http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92` (R01; shapes the in-process test tier only)
- assumes `ci-job-structure = <accepted R11 value in inputs/parameters.json: detector + check/matrix + msrv-floor + install-smoke; test commands in this answer are step content scoped for check's cargo steps, job placement stays R11's>` (R11; full value echoed verbatim in run inputs, not repeated here to avoid transcription drift)
- assumes `package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component` (R42; `cargo nextest` spelling follows the cargo-subcommand rule)
- assumes `build-tool-output-shape = <accepted R49 value in inputs/parameters.json: single [lib] + single [[bin]] rslbp + CARGO_BIN_EXE_rslbp resolution + include allow-list>` (R49; binary discovery in this answer keys on the rslbp name and CARGO_BIN_EXE contract; full value echoed verbatim in run inputs)
- assumes `web-extra-surface = <accepted R69 value in inputs/parameters.json: additive off-by-default web feature gating src/web/, the serve binary, and the web integration tests file-level>` (R69; tests/web.rs gating follows it; full value echoed verbatim in run inputs)

No `CONFLICT:` lines — this answer fits every consumed value as accepted.

### Migration implications

Template file changes: (1) `Cargo.toml`: add `[dev-dependencies]` `assert_cmd = "2"`,
`predicates = "3"`, `tempfile = "3"`, `serial_test = { version = "3", default-features =
false }`; no `[dependencies]` change; no nextest dependency (CI/local tool install).
(2) `.config/nextest.toml`: new; default profile (`slow-timeout` 60s + `terminate-after`),
`[profile.live]` opt-in slice. (3) `tests/`: new `cli_in_process.rs`, `cli_binary.rs`,
`web.rs` (`#![cfg(feature = "web")]`), `common/mod.rs` (factories, argv builders, tempdir
helper). (4) `Justfile`: `test` recipe runs `cargo nextest run` (+ doctest sidecar /
live opt-in recipes). (5) CI `check` job: install-nextest step + nextest command +
`cargo test --doc` step (placement per R11). (6) Pre-push hook content: default-profile
nextest run behind env gate (wiring per R37). (7) README: the two opt-in commands
(`--run-ignored all`, live profile) and the hook env var.

### Validation strategy

Commands proving the principles in a realistic example (all PLANNED — no execution was
performed in this leg; "observed" results: none): (a) `cargo nextest run --workspace`
green = P-exec/P-tiers default path; (b) `cargo nextest run --workspace --all-features`
green = web tier composes (R69); (c) canary hang test terminated ≈3 min with per-test
attribution = P-budget; (d) `cargo nextest run --run-ignored all` runs exactly the
`#[ignore]`d slow/live set while the default run skips them = P-scope; (e) `cargo test
--doc` green in the gate = P-doctest; (f) `#[serial]` pair green at `--test-threads=16`,
flaky with one annotation removed (then restored) = fixture-isolation load-bearing;
(g) pre-push hook exit-0-noop unset / suite-run set = P-hook; (h) full matrix on
ubuntu-latest + macos-latest = target-os-matrix. Expected behavior: (a)(b)(d)(e)(g-set)
green, (c) red-with-attribution-inside-budget, (f) green-then-flaky-then-green,
(g-unset) immediate exit 0. Empirical execution belongs to the synthesis/acceptance
check, not this raw report.

### Confidence & re-verify trigger

Confidence: high on runner pick (nextest-primary + doctest sidecar, tokio-verified),
CLI-tier crates (assert_cmd/predicates/tempfile, deep adoption + clean gates),
fixture pattern (local factories + narrow `#[serial]`), layout + `#[ignore]` taxonomy
(stable toolchain behavior), and the env-gated hook shape. Medium on: nextest
profile/filter exact spellings (not re-fetched; confirm at synthesis), serial_test 3.x
vs 4.x longevity, per-OS CI-leg proof for each crate (presence of workflows verified,
leg contents not). Re-verify triggers: nextest 0.10 (schema/doctest support), assert_cmd
3.x, serial_test 4.x changelog review (next quarterly), R37 hook-manager decision
(env-var name + mechanics), R05 async decision (may add serial_test `async`), any
rust-version floor change crossing 1.85/1.91, or quarterly cadence per the runbook.

### Sources

Named-endpoint sources (all retrieved 2026-09-27, `User-Agent: rs-launch-blueprint-research
(p02-r32)`): `GET https://crates.io/api/v1/crates/{cargo-nextest,assert_cmd,serial_test,
predicates,tempfile,rstest,escargot,test-case,libtest-mimic}` (downloads, repos);
`/versions` for each (releases, dates, rust_version, licenses) + `wait-timeout`,
`bstr`, `libc`, `predicates-core`, `parking_lot`, `once_cell`, `fslock`,
`serial_test_derive`, `anstyle` (dependency MSRVs); `/crates/<name>/<version>` feature
maps (serial_test 3.5.0, assert_cmd 2.2.2, tempfile 3.27.0); `/dependencies` edge lists
(cargo-nextest 0.9.146, assert_cmd 2.2.2, serial_test 4.0.1); `/reverse_dependencies`
adopter edges (all primaries); `GET https://api.github.com/repos/{nextest-rs/nextest,
assert-rs/assert_cmd,palfrey/serial_test,assert-rs/predicates-rs,Stebalien/tempfile,
la10736/rstest,crate-ci/escargot}` (stars, archived, pushed_at); search-issues open
counts (76/24/0); 5-issue first-response samples (nextest, assert_cmd — comment-level);
contents-API file reads (tokio `.github/workflows/ci.yml` nextest + doctest comment,
cargo-watch `Cargo.toml` assert_cmd pin, bat `Cargo.toml` serial_test pin, workflows-dir
presence ×3, tokio/clap nextest.toml 404s); `https://rustsec.org/packages/<name>.html`
(404 = no advisories, ×7). Local-only (no network): vendored registry sources for
assert_cmd 2.2.2 / predicates 3.1.4 / rstest 0.26.1 (`unsafe` grep, edition, features),
`rustc 1.98.1` floor approximation. In-repo: item prompt, `inputs/parameters.json`
(R01/R11/R42/R49/R69), `docs/port/DIVERGENCE-ANALYSIS.md` R32 rows, ts D-019/D-020
precedent as cited in the prompt. Deliberately not fetched (out-of-scope endpoints):
maintainer doc sites, changelogs, CI badge SVGs — flagged as synthesis-time confirmations
where load-bearing.
