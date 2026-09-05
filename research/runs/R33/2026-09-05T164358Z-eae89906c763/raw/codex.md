### Landscape

**Category and field map.** This item selects two test-design capabilities, not the base test runner: generated inputs with failure shrinking for algebraic/round-trip properties, and reviewed, version-controlled output snapshots for a command-line interface (CLI). The Rust field is:

| Bin | Candidates found | Fit to this decision |
|---|---|---|
| Built-in or first-party toolchain | `#[test]`, `assert_eq!`, `std::process::Command`, Cargo test targets | These execute and capture ordinary tests, but they do not generate/shrink values or manage reviewed snapshots. They are composition points, not replacements. Source: [Rust test attribute](https://doc.rust-lang.org/reference/attributes/testing.html), retrieved 2026-09-05. |
| Established industry standard | `proptest` 1.11.0; `quickcheck` 1.1.0; `insta` 1.48.0; `snapbox` 1.2.2 | `proptest` and `quickcheck` provide generated values plus shrinking. `insta` stores/reviews snapshots; `snapbox` is specifically oriented to command output. Sources: [proptest](https://docs.rs/proptest/1.11.0/proptest/), [quickcheck](https://docs.rs/quickcheck/1.1.0/quickcheck/), [insta](https://insta.rs/docs/), and [snapbox](https://docs.rs/snapbox/1.2.2/snapbox/), retrieved 2026-09-05. |
| Up-and-comer / narrower alternative | hand-written random loops; hand-rolled checked-in `*.txt` files; `snapbox` for command-centric fixtures | These are viable narrow techniques, but manual generation has no generic shrinking and hand-rolled fixtures have no pending-snapshot review protocol. `snapbox` remains a qualified CLI-specialist runner-up, not an additional stack member. Sources: [Rust `rand` crate](https://crates.io/crates/rand), [snapbox design](https://docs.rs/snapbox/1.2.2/snapbox/), retrieved 2026-09-05. |

**Authorities and practice evidence.** The Cargo Book is first-party Rust project guidance for `rust-version`, resolver behavior, and CI MSRV verification; it establishes that an edition-2024 package uses a Rust-version-aware resolver but still needs actual MSRV tests. Sources: [Cargo rust-version](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html), [Cargo resolver](https://doc.rust-lang.org/stable/cargo/reference/resolver.html), and [Cargo CI guide](https://doc.rust-lang.org/stable/cargo/guide/continuous-integration.html), retrieved 2026-09-05. The crates' own documentation is authoritative for their APIs and review workflows. Crates.io is the registry authority for release, declared MSRV, license, and download figures; RustSec is the named advisory authority. Sources: [proptest registry](https://crates.io/api/v1/crates/proptest), [quickcheck registry](https://crates.io/api/v1/crates/quickcheck), [insta registry](https://crates.io/api/v1/crates/insta), and [snapbox registry](https://crates.io/api/v1/crates/snapbox), retrieved 2026-09-05.

Practice is not treated as selection proof. It does establish that the candidates compose in current, well-regarded Rust work: Tokio declares `proptest = "1"`; Deno declares `proptest = "1"`; Helix and Nushell declare `quickcheck`; the Rust compiler's Cargo repository declares `proptest = "1.11.0"` and `snapbox = "1.2.0"`; Clap declares `snapbox = "1.2.0"`; and Ruff declares `insta`, `quickcheck`, and `snapbox`. Tokio, Deno, Cargo, Clap, Helix, Nushell, and Ruff are maintained, public projects with their dependency declarations directly inspectable. Sources: [Tokio manifest](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml), [Deno manifest](https://raw.githubusercontent.com/denoland/deno/main/Cargo.toml), [Helix manifest](https://raw.githubusercontent.com/helix-editor/helix/master/Cargo.toml), [Nushell manifest](https://raw.githubusercontent.com/nushell/nushell/main/Cargo.toml), [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), [Clap manifest](https://raw.githubusercontent.com/clap-rs/clap/master/Cargo.toml), and [Ruff manifest](https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml), retrieved 2026-09-05.

### Principles and implementation

**Shared requirement and agreement level.** The source pattern behind F122 is “test semantic round trips over representative generated inputs, then reduce a failure to a useful counterexample.” The source pattern behind F123 is “make the public CLI contract reviewable by comparing deterministic `--help` output with a committed golden artifact.” Both are **capabilities/policies**, not a mandate to share Hypothesis, syrupy, fixture extension, or test-runner plumbing. The py evidence is Hypothesis `@given` at `tests/core/test_properties.py:24` and syrupy help assertions at `tests/cli/test_help_snapshots.py:36`; the ts absence has no recorded justification and is therefore evidence of unadopted portable capability, not a justified language difference. Sources: `docs/port/areas/testing-coverage.md:12-13` and `docs/port/DIVERGENCE-ANALYSIS.md:143`, retrieved locally 2026-09-05.

**Acceptance criteria.** A selected serializable domain value must satisfy `decode(encode(value)) == normalize(value)` across generated valid values, and a deliberately broken codec must produce a shrunk counterexample. Every public command and subcommand must have a deterministic `--help` test whose changed output fails in CI until a reviewer updates the committed snapshot. Those are observable behavior requirements; number of generated cases, test targeting, subprocess/in-process tiering, parallelism, and timeout policy remain R32 decisions.

**Architectural comparison.** Ordinary example tests are retained for named boundary cases but cannot search an input space or minimize a counterexample. Hand-written random loops can search values but leave generation, replay, shrinking, persistence, and diagnostics to the template. `quickcheck` gives a compact `Arbitrary` trait and shrink mechanism, whereas `proptest` exposes composable strategies, `proptest!`, persistence, and configurable runner behavior; the latter maps more directly to constrained domain values and Hypothesis-style round trips. Sources: [quickcheck API](https://docs.rs/quickcheck/1.1.0/quickcheck/trait.Arbitrary.html), [proptest API](https://docs.rs/proptest/1.11.0/proptest/), and [proptest strategy module](https://docs.rs/proptest/1.11.0/proptest/strategy/index.html), retrieved 2026-09-05.

For help text, a direct equality assertion against a hand-maintained text file can work, but it provides no pending-artifact review workflow. `snapbox` is strong when a test must launch a command and assert output; its documented `cmd` module is a process-spawning assertion layer. `insta` instead accepts any string, produces `.snap.new` files during local review, keeps CI from writing new snapshots, and provides `cargo insta review` for accepting/rejecting a displayed diff. That review flow fits all help-text assertions while leaving process capture to the standard library or R32's chosen CLI tier. Sources: [snapbox command module](https://docs.rs/snapbox/1.2.2/snapbox/cmd/index.html), [Insta quickstart](https://insta.rs/docs/quickstart/), and [cargo-insta CLI](https://insta.rs/docs/cli/), retrieved 2026-09-05.

The recommended minimal composition is one `proptest!` test around a pure encoder/decoder pair and one integration test that runs the built CLI with `--help`, decodes stdout as UTF-8, and calls `insta::assert_snapshot!`. Static help output needs no redaction feature. If a command intentionally emits a dynamic version, path, ANSI sequence, or environment-dependent field, normalize it before asserting; use Insta's optional `redactions` feature only when normalization would hide relevant behavior. Sources: [Insta redactions](https://insta.rs/docs/redactions/), [Insta quickstart](https://insta.rs/docs/quickstart/), retrieved 2026-09-05.

No comparable performance benchmark was found or run. The relevant cost is test-time and contributor integration rather than production latency: `proptest`'s generated cases can make tests slower than examples, while `insta` documents a one-time development-profile optimization tradeoff for faster diffing. Neither crate enters the released binary because both are dev-dependencies. Source: [Insta quickstart performance note](https://insta.rs/docs/quickstart/), retrieved 2026-09-05.

BASELINE-REVIEW: F122 — generated invariant testing — adopt `proptest` rather than treating py Hypothesis as a required tool — `docs/port/areas/testing-coverage.md:12`, Cargo's manifest and Tokio/Deno practice evidence, retrieved 2026-09-05.

BASELINE-REVIEW: F123 — reviewed CLI contract snapshots — adopt `insta` rather than treating py syrupy fixture mechanics as a required tool — `docs/port/areas/testing-coverage.md:13`, [Insta review workflow](https://insta.rs/docs/cli/), retrieved 2026-09-05.

### Recommendation

Adopt this unconditional dev-dependency stack, subject to the MSRV/advisory validation below:

```toml
[dev-dependencies]
proptest = "1.11.0"
insta = "1.48.0"
```

Use `proptest` 1.11.0 only for pure round-trip/invariant tests. Use `insta` 1.48.0 only for text snapshots, including captured CLI `--help` stdout. Do not add `quickcheck`, `snapbox`, a Cargo feature, or a second test runner. The latest non-yanked releases declare Rust 1.85 for `proptest` and Rust 1.66 for `insta`, below the current policy floor of Rust 1.96 (latest stable 1.98.1 minus two minor releases); the full resolved dependency trees still require CI proof. Sources: [Rust releases](https://blog.rust-lang.org/releases/), [proptest versions endpoint](https://crates.io/api/v1/crates/proptest/versions), [insta versions endpoint](https://crates.io/api/v1/crates/insta/versions), retrieved 2026-09-05.

### Members

#### proptest

##### Landscape

`proptest` is the established, strategy-oriented property-testing candidate. `quickcheck` is the established compact-trait alternative. Both have current 2026 releases, so neither is classified as dormant from release recency alone. Sources: [proptest documentation](https://docs.rs/proptest/1.11.0/proptest/), [quickcheck documentation](https://docs.rs/quickcheck/1.1.0/quickcheck/), retrieved 2026-09-05.

| Candidate | 90-day downloads | All-time downloads | Latest non-yanked release | Maintenance rubric | Registry endpoint and retrieval |
|---|---:|---:|---|---|---|
| `proptest` | 46,498,486 | 181,221,925 | 1.11.0, 2026-03-24 | active: recent release; repository activity and maintainer response not verified | [crate](https://crates.io/api/v1/crates/proptest), [versions](https://crates.io/api/v1/crates/proptest/versions), retrieved 2026-09-05 |
| `quickcheck` | 10,421,547 | 66,816,530 | 1.1.0, 2026-02-10 | active: recent release; repository activity and maintainer response not verified | [crate](https://crates.io/api/v1/crates/quickcheck), [versions](https://crates.io/api/v1/crates/quickcheck/versions), retrieved 2026-09-05 |

GitHub's required repository endpoints returned HTTP 403 rate-limit responses in this run, so stars, archived state, and `pushed_at` are **unverified**, not zero. The issue-search endpoints did return 124 open issues for `proptest` and 19 for `quickcheck`; the required ten-recent-issues response-time calculation could not be queried because the GitHub core endpoint was rate-limited. Sources: [proptest repo endpoint](https://api.github.com/repos/proptest-rs/proptest), [quickcheck repo endpoint](https://api.github.com/repos/BurntSushi/quickcheck), [proptest issue search](https://api.github.com/search/issues?q=repo:proptest-rs/proptest+is:issue+is:open), and [quickcheck issue search](https://api.github.com/search/issues?q=repo:BurntSushi/quickcheck+is:issue+is:open), retrieved 2026-09-05.

RustSec's required package pages returned HTTP 404 for both names, so the open-advisory count is **unverified** rather than reported as zero. Sources: [proptest RustSec endpoint](https://rustsec.org/packages/proptest.html) and [quickcheck RustSec endpoint](https://rustsec.org/packages/quickcheck.html), retrieved 2026-09-05.

##### Principles and implementation

`proptest` supplies composable `Strategy` values, property-test macros, shrinking, and a test-runner module. That lets a template generate only valid domain values rather than rely on a blanket trait implementation. `quickcheck` centers on `Arbitrary` and its shrinker; it is concise for uncomplicated data types but pushes custom constrained generation into trait implementations. Sources: [proptest strategy API](https://docs.rs/proptest/1.11.0/proptest/strategy/index.html), [proptest macro](https://docs.rs/proptest/1.11.0/proptest/macro.proptest.html), [quickcheck `Arbitrary`](https://docs.rs/quickcheck/1.1.0/quickcheck/trait.Arbitrary.html), retrieved 2026-09-05.

##### Dominant choice

`proptest` 1.11.0 is the dominant choice for this template because strategy composition and shrinkable constrained input express encoder/decoder invariants without exporting random-test machinery into the library API. Tokio and Deno currently declare it, which is relevant production practice but not the decision rule. Sources: [Tokio manifest](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml), [Deno manifest](https://raw.githubusercontent.com/denoland/deno/main/Cargo.toml), [proptest crate metadata](https://crates.io/api/v1/crates/proptest), retrieved 2026-09-05.

##### Qualified shortlist

`quickcheck` 1.1.0 is the qualified alternative: it meets the direct release/MSRV/license evidence and is used by Helix, Nushell, and Ruff. It is not selected because its `Arbitrary`-first model is less direct for composable valid-domain strategies. Sources: [quickcheck versions](https://crates.io/api/v1/crates/quickcheck/versions), [Helix manifest](https://raw.githubusercontent.com/helix-editor/helix/master/Cargo.toml), [Nushell manifest](https://raw.githubusercontent.com/nushell/nushell/main/Cargo.toml), [Ruff manifest](https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml), retrieved 2026-09-05.

##### Excluded by gate

None is excluded by a demonstrated failed gate. Both candidates have direct-release MSRV and license evidence. Their full dependency-tree MSRV, advisory state, repository CI platform evidence, and upstream `unsafe` posture are unverified in this run; implementation must not call those gates passed until the validation strategy completes. Sources: [proptest versions](https://crates.io/api/v1/crates/proptest/versions), [quickcheck versions](https://crates.io/api/v1/crates/quickcheck/versions), retrieved 2026-09-05.

##### Up-and-comers

Hand-written random loops are an inapplicable substitute for the selected capability: they are not a maintained crate and do not provide generic shrinking or replay artifacts. Source: [Rust `rand` crate](https://crates.io/crates/rand), retrieved 2026-09-05.

##### Fit for this template

`proptest` is library-safe because it tests pure domain transformations; it has no async-runtime coupling. Its 1.11.0 default features are `std`, `fork`, `timeout`, and `bit-set`, which adds test-only process/timeout support and dependencies; disable no defaults until a measured need exists because the template needs ordinary host tests. The crate's declared package size is 207,859 bytes, versus 31,932 bytes for `quickcheck`; this indicates higher development compile/dependency cost, not released-binary cost. Sources: [proptest versions](https://crates.io/api/v1/crates/proptest/versions), [quickcheck versions](https://crates.io/api/v1/crates/quickcheck/versions), retrieved 2026-09-05.

##### Recommendation

Add `proptest = "1.11.0"` under `[dev-dependencies]`; write property modules only for stable, pure round-trip/invariant boundaries. Run them in the default test command, with R32 retaining ownership of timing and target selection. Source: [proptest documentation](https://docs.rs/proptest/1.11.0/proptest/), retrieved 2026-09-05.

##### Ranked runner-up

`quickcheck = "1.1.0"` is runner-up. It is preferable only if the eventual domain model naturally has simple `Arbitrary` implementations and maintaining bespoke `Strategy` composition proves disproportionate. Sources: [quickcheck API](https://docs.rs/quickcheck/1.1.0/quickcheck/), [quickcheck versions](https://crates.io/api/v1/crates/quickcheck/versions), retrieved 2026-09-05.

##### Tradeoffs

`proptest` costs more configuration and test execution than examples or `quickcheck`, but buys explicit valid-input construction and failure reduction. `quickcheck` is smaller and simpler, but its compatibility documentation warns that supplied `Arbitrary` strategies are implementation details that may change in semver-compatible releases; generated test distribution is therefore less explicit. Sources: [quickcheck compatibility note](https://docs.rs/quickcheck/1.1.0/quickcheck/), [proptest documentation](https://docs.rs/proptest/1.11.0/proptest/), retrieved 2026-09-05.

##### Parameters

assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes `rust-edition = 2024`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

assumes `license = MIT OR Apache-2.0`.

No owned parameters and no `CONFLICT:` line: R33 consumes only fixed parameters and requires no change to them.

##### Migration implications

Add the dev-dependency in root `Cargo.toml`; add a pure-domain property test such as `tests/properties.rs` or a colocated `#[cfg(test)]` module; do not change production public APIs merely to make values generatable. The exact test layout is R32-owned. Source: [Cargo dev-dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies), retrieved 2026-09-05.

##### Validation strategy

Planned, not executed: resolve the actual lockfile with `rust-version = "1.96"`, run `cargo +1.96.0 test --locked` on Ubuntu and macOS, run a property whose intentionally faulty decoder fails with a shrunk input, then restore the correct decoder and require the property to pass. Inspect `cargo tree -e normal,build,dev` and run the project advisory scanner selected by its security item before accepting the dependency tree. Cargo identifies a declared `rust-version` as a support contract and recommends automated verification. Source: [Cargo rust-version](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html), retrieved 2026-09-05.

##### Confidence & re-verify trigger

Medium confidence. Re-verify before implementation or any version update; immediately re-verify if the resolved graph raises the Rust 1.96 floor, the RustSec package endpoint becomes available with an advisory, a current test on either required OS fails, or R32 imposes a test mode incompatible with `proptest` defaults. Sources: [proptest versions](https://crates.io/api/v1/crates/proptest/versions), [Cargo CI guide](https://doc.rust-lang.org/stable/cargo/guide/continuous-integration.html), retrieved 2026-09-05.

##### Sources

Registry figures: [proptest crate](https://crates.io/api/v1/crates/proptest) and [versions](https://crates.io/api/v1/crates/proptest/versions); [quickcheck crate](https://crates.io/api/v1/crates/quickcheck) and [versions](https://crates.io/api/v1/crates/quickcheck/versions), retrieved 2026-09-05. Repository/issue figures: [proptest repository](https://api.github.com/repos/proptest-rs/proptest), [quickcheck repository](https://api.github.com/repos/BurntSushi/quickcheck), [proptest issues](https://api.github.com/search/issues?q=repo:proptest-rs/proptest+is:issue+is:open), [quickcheck issues](https://api.github.com/search/issues?q=repo:BurntSushi/quickcheck+is:issue+is:open), retrieved 2026-09-05. Advisory endpoints: [proptest](https://rustsec.org/packages/proptest.html), [quickcheck](https://rustsec.org/packages/quickcheck.html), retrieved 2026-09-05; both returned 404. Method notes: queried the required crates.io crate and versions endpoints, GitHub repository and issue-search endpoints, RustSec package pages, docs.rs, maintainer documentation, and public adopter manifests on 2026-09-05. GitHub core endpoints were rate-limited, and RustSec package pages returned 404; stars, archived/push state, response median, and advisory count remain unverified.

#### insta

##### Landscape

`insta` is the established general-purpose Rust snapshot candidate. `snapbox` is the qualified CLI/output-oriented alternative. Both make fixture changes visible, but `insta` adds a dedicated pending-snapshot review workflow. Sources: [Insta overview](https://insta.rs/docs/), [snapbox documentation](https://docs.rs/snapbox/1.2.2/snapbox/), retrieved 2026-09-05.

| Candidate | 90-day downloads | All-time downloads | Latest non-yanked release | Maintenance rubric | Registry endpoint and retrieval |
|---|---:|---:|---|---|---|
| `insta` | 26,175,871 | 96,167,643 | 1.48.0, 2026-06-11 | active: recent release; repository activity and maintainer response not verified | [crate](https://crates.io/api/v1/crates/insta), [versions](https://crates.io/api/v1/crates/insta/versions), retrieved 2026-09-05 |
| `snapbox` | 3,181,711 | 11,912,944 | 1.2.2, 2026-05-26 | active: recent release; repository activity and maintainer response not verified | [crate](https://crates.io/api/v1/crates/snapbox), [versions](https://crates.io/api/v1/crates/snapbox/versions), retrieved 2026-09-05 |

GitHub repository endpoints were rate-limited, so stars, archived state, and `pushed_at` are **unverified**. Issue search returned 55 open issues for `insta` and 44 for `snapbox`; the ten-recent-issues median first-maintainer-response and unanswered count are **unverified** because the core issues endpoint was rate-limited. Sources: [insta repository endpoint](https://api.github.com/repos/mitsuhiko/insta), [snapbox repository endpoint](https://api.github.com/repos/assert-rs/snapbox), [insta issue search](https://api.github.com/search/issues?q=repo:mitsuhiko/insta+is:issue+is:open), [snapbox issue search](https://api.github.com/search/issues?q=repo:assert-rs/snapbox+is:issue+is:open), retrieved 2026-09-05.

RustSec's named package pages returned HTTP 404 for `insta` and `snapbox`, so their open-advisory counts are **unverified**, not zero. Sources: [insta RustSec endpoint](https://rustsec.org/packages/insta.html), [snapbox RustSec endpoint](https://rustsec.org/packages/snapbox.html), retrieved 2026-09-05.

##### Principles and implementation

`insta::assert_snapshot!` compares a caller-provided string with a committed snapshot; it does not capture stdout itself. The test owns process execution and decoding, which makes it compatible with either a standard-library subprocess test or whatever R32 selects. New local snapshots are written alongside the reference as `.snap.new`; `cargo insta review` shows each diff and accepts, rejects, or leaves it pending. CI does not write new snapshots when `CI=true`, so a changed help contract fails rather than self-approving. Sources: [Insta quickstart](https://insta.rs/docs/quickstart/), [cargo-insta commands](https://insta.rs/docs/cli/), retrieved 2026-09-05.

##### Dominant choice

`insta` 1.48.0 is the dominant choice because this item needs reviewed golden **text**, not a command-launching assertion framework. It directly covers captured `--help` stdout, supplies optional redactions, and has a documented review/CI workflow. Ruff's current manifest uses it, providing a maintained reference adopter. Sources: [Insta quickstart](https://insta.rs/docs/quickstart/), [Insta redactions](https://insta.rs/docs/redactions/), [Ruff manifest](https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml), retrieved 2026-09-05.

##### Qualified shortlist

`snapbox` 1.2.2 is qualified for CLI snapshots: its `cmd` module spawns non-interactive commands and asserts their output, and both Cargo and Clap declare it. It is not selected because its command fixture focus would duplicate capture concerns that R32 may already settle, while `insta` supplies the more explicit review workflow needed by this item. Sources: [snapbox command docs](https://docs.rs/snapbox/1.2.2/snapbox/cmd/index.html), [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), [Clap manifest](https://raw.githubusercontent.com/clap-rs/clap/master/Cargo.toml), retrieved 2026-09-05.

##### Excluded by gate

None is excluded by a demonstrated failed gate. `insta` has Apache-2.0 and declares Rust 1.66; `snapbox` has MIT OR Apache-2.0 and declares Rust 1.85, both directly below the current Rust 1.96 policy floor. Full dependency-tree MSRV, advisory state, upstream unsafe posture, and Ubuntu/macOS CI evidence remain unverified and are required before adding either crate. Sources: [insta versions](https://crates.io/api/v1/crates/insta/versions), [snapbox versions](https://crates.io/api/v1/crates/snapbox/versions), retrieved 2026-09-05.

##### Up-and-comers

Hand-rolled text fixtures are inapplicable as a full replacement because they are a pattern, not a crate, and cannot provide an artifact-review workflow. `snapbox` is the only narrower tool retained as a runner-up. Source: [snapbox documentation](https://docs.rs/snapbox/1.2.2/snapbox/), retrieved 2026-09-05.

##### Fit for this template

Use `insta` with default `colors`; defaults are only `colors`, so no serializer, glob, or redaction dependency is pulled in solely for help text. It has no async-runtime coupling. Enable `redactions` only if a legitimately nondeterministic help field cannot be made deterministic before capture. Its declared crate archive is 121,313 bytes; `snapbox` is 56,925 bytes, but `snapbox` with command support requires optional `cmd` dependencies. These are qualitative development compile-time/binary-size costs only; dev-dependencies do not ship in the template binary. Sources: [insta versions](https://crates.io/api/v1/crates/insta/versions), [snapbox versions](https://crates.io/api/v1/crates/snapbox/versions), [Insta redactions](https://insta.rs/docs/redactions/), retrieved 2026-09-05.

##### Recommendation

Add `insta = "1.48.0"` under `[dev-dependencies]`. For each supported CLI help surface, capture deterministic stdout and assert it with a separately named external snapshot. Run the normal test command unconditionally. Do not install `cargo-insta` in CI; it is a contributor review tool, while CI's role is to fail on an unreviewed change. Sources: [Insta quickstart](https://insta.rs/docs/quickstart/), [cargo-insta CLI](https://insta.rs/docs/cli/), retrieved 2026-09-05.

##### Ranked runner-up

`snapbox = { version = "1.2.2", features = ["cmd"] }` is runner-up if R32 explicitly standardizes built-binary command execution and the implementation benefits from Snapbox's command fixture ergonomics more than Insta's dedicated review flow. Sources: [snapbox features](https://crates.io/api/v1/crates/snapbox/versions), [snapbox command docs](https://docs.rs/snapbox/1.2.2/snapbox/cmd/index.html), retrieved 2026-09-05.

##### Tradeoffs

Insta's review workflow requires a human to inspect fixture diffs, which is desirable for a public CLI contract but adds a contributor step. `cargo insta test` can force snapshot tests to pass to collect multiple changes, and `cargo insta review` then reviews them; ordinary `cargo test` keeps failures visible and is adequate for CI. Snapbox has more direct process fixtures but would make R33 choose a command-execution layer that belongs to R32. Sources: [cargo-insta CLI](https://insta.rs/docs/cli/), [Insta quickstart](https://insta.rs/docs/quickstart/), retrieved 2026-09-05.

##### Parameters

assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes `rust-edition = 2024`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

assumes `license = MIT OR Apache-2.0`.

No owned parameters and no `CONFLICT:` line: R33 needs no parameter change.

##### Migration implications

Add the dev-dependency to root `Cargo.toml`; add a help-snapshot integration-test module; commit its generated `tests/snapshots/*.snap` files; document `cargo insta review` for contributors. Do not add a snapshot Cargo feature, a CI self-update command, or `snapbox` unless a later R32 decision explicitly changes the execution architecture. Sources: [Insta snapshot files](https://insta.rs/docs/), [Insta quickstart](https://insta.rs/docs/quickstart/), retrieved 2026-09-05.

##### Validation strategy

Planned, not executed: run the built binary for root and subcommand `--help` on Ubuntu and macOS; set deterministic environment variables; decode stdout; use `insta::assert_snapshot!`; prove an altered help string creates a failing diff with `CI=true cargo test`; restore the fixture; then locally run `cargo insta review` and inspect the displayed diff before committing. Also resolve and test with Rust 1.96 and inspect the resolved dev dependency tree/advisory scan. Sources: [Insta CI behavior](https://insta.rs/docs/quickstart/), [cargo-insta review](https://insta.rs/docs/cli/), [Cargo CI guide](https://doc.rust-lang.org/stable/cargo/guide/continuous-integration.html), retrieved 2026-09-05.

##### Confidence & re-verify trigger

Medium confidence. Re-verify immediately before implementation, after an Insta major/minor update, if any snapshot contains dynamic output, if MSRV resolution fails on Rust 1.96, if required OS tests fail, or if RustSec yields an advisory. Sources: [insta versions](https://crates.io/api/v1/crates/insta/versions), [Cargo rust-version](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html), retrieved 2026-09-05.

##### Sources

Registry figures: [insta crate](https://crates.io/api/v1/crates/insta) and [versions](https://crates.io/api/v1/crates/insta/versions); [snapbox crate](https://crates.io/api/v1/crates/snapbox) and [versions](https://crates.io/api/v1/crates/snapbox/versions), retrieved 2026-09-05. Repository/issue figures: [insta repository](https://api.github.com/repos/mitsuhiko/insta), [snapbox repository](https://api.github.com/repos/assert-rs/snapbox), [insta issues](https://api.github.com/search/issues?q=repo:mitsuhiko/insta+is:issue+is:open), [snapbox issues](https://api.github.com/search/issues?q=repo:assert-rs/snapbox+is:issue+is:open), retrieved 2026-09-05. Advisory endpoints: [insta](https://rustsec.org/packages/insta.html), [snapbox](https://rustsec.org/packages/snapbox.html), retrieved 2026-09-05; both returned 404. Method notes: queried the required crates.io crate and versions endpoints, GitHub repository and issue-search endpoints, RustSec package pages, docs.rs, Insta maintainer documentation, and adopter manifests on 2026-09-05. GitHub core endpoints were rate-limited, and RustSec package pages returned 404; stars, archived/push state, response median, and advisory count remain unverified.

### Compatibility

The two selected members are compatible as independent dev-dependencies: neither declares an async-runtime coupling, and their APIs meet at ordinary Rust test code (`proptest!` tests pure values; `insta::assert_snapshot!` accepts the separately captured help string). Ruff's current workspace demonstrates use of both `insta` and `quickcheck`/`snapbox`, while the recommended pair has no direct version coupling; this is practice evidence, not a resolved-pair build proof. The required proof is therefore a planned version matrix: resolve `proptest = "1.11.0"` plus `insta = "1.48.0"` with `rust-version = "1.96"`, then run the resulting lockfile on Ubuntu and macOS. Sources: [Ruff manifest](https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml), [proptest versions](https://crates.io/api/v1/crates/proptest/versions), [insta versions](https://crates.io/api/v1/crates/insta/versions), retrieved 2026-09-05.

### Parameters

assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes `rust-edition = 2024`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

assumes `license = MIT OR Apache-2.0`.

R33 owns no parameter. No `CONFLICT:` line is emitted because the recommendation requires no fixed or researched parameter to change. Source: `docs/port/PARAMETERS.md`, retrieved locally 2026-09-05.

### Migration implications

Planned file-level implementation, not executed: add `proptest = "1.11.0"` and `insta = "1.48.0"` to root `Cargo.toml`; add one pure property-test module for selected round trips; add one CLI-help integration test module; and commit external `.snap` fixtures below that test module's snapshot directory. Do not add a Cargo feature, a custom test runner, `quickcheck`, `snapbox`, or production dependency. R32 decides the test invocation and layout details; R33 only supplies the capability and crates. Sources: [Cargo dev-dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#development-dependencies), `inputs/prompt.md`, retrieved 2026-09-05.

### Validation strategy

Planned commands, not executed because this repository has no Rust implementation yet:

```sh
cargo +1.96.0 test --locked
CI=true cargo test --test help_snapshots
cargo insta review
cargo tree -e normal,build,dev
```

On both `ubuntu-latest` and `macos-latest`, the first command must compile and pass the resolved graph at the policy floor; the second must fail if a committed help string differs and must not create an approved replacement; the third is the local human review step for an intentional change; and the fourth is inspected before the advisory/MSRV gate is accepted. A deliberately defective decoder must fail a `proptest` round-trip test with a reduced counterexample, while the correct decoder passes. The commands are acceptance checks proposed for implementation, not evidence already run. Sources: [Cargo CI guide](https://doc.rust-lang.org/stable/cargo/guide/continuous-integration.html), [Insta quickstart](https://insta.rs/docs/quickstart/), [cargo-insta CLI](https://insta.rs/docs/cli/), [proptest docs](https://docs.rs/proptest/1.11.0/proptest/), retrieved 2026-09-05.

### Confidence & re-verify trigger

Medium confidence in architecture and crate selection; conditional confidence in release readiness. Re-query every registry/repository/advisory figure immediately before a `Cargo.toml` change, then re-run the resolved lockfile at Rust 1.96 on both required OSes. Reconsider `snapbox` only if R32 requires an integrated command-fixture layer; reconsider `quickcheck` only if the eventual domain needs no constrained strategies. Sources: [Rust releases](https://blog.rust-lang.org/releases/), [Cargo rust-version](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html), [R32/R33 boundary](https://github.com/smorinlabs/rs-launch-blueprint), retrieved 2026-09-05.

### Sources

Local decision evidence: `inputs/prompt.md`; `docs/port/areas/testing-coverage.md:12-13`; `docs/port/COMMONALITY.md:128-129`; `docs/port/DIVERGENCE-ANALYSIS.md:143`; `docs/port/PARAMETERS.md`, retrieved locally 2026-09-05. Ecosystem authorities: [Cargo Book](https://doc.rust-lang.org/stable/cargo/), [Rust release announcements](https://blog.rust-lang.org/releases/), [proptest docs](https://docs.rs/proptest/1.11.0/proptest/), [quickcheck docs](https://docs.rs/quickcheck/1.1.0/quickcheck/), [Insta docs](https://insta.rs/docs/), and [snapbox docs](https://docs.rs/snapbox/1.2.2/snapbox/), retrieved 2026-09-05.

Method notes: queried `GET https://crates.io/api/v1/crates/{proptest,quickcheck,insta,snapbox}` and `/versions`, `GET https://api.github.com/repos/{owner}/{repo}`, `GET https://api.github.com/search/issues?q=repo:{owner}/{repo}+is:issue+is:open`, the named `https://rustsec.org/packages/{name}.html` pages, docs.rs, maintainer documentation, and public adopter `Cargo.toml` files on 2026-09-05. Crates.io supplied release/download/MSRV/license/default-feature figures. GitHub core repository and issue-list endpoints returned a rate-limit response, so stars, archived/push state, and ten-issue responsiveness are explicitly unverified; issue-search totals were available. All four named RustSec package pages returned HTTP 404, so open-advisory counts are explicitly unverified. No code, dependency resolution, benchmark, or platform test was run because the Rust template does not yet exist.
