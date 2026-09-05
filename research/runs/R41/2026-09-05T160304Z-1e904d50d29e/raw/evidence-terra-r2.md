Actor: `evidence-terra-2026-09-05T160304Z-1e904d50d29e-r2`  
Checked: 2026-09-05

## Figures

The prompt's crates.io, GitHub REST, RustSec, and reverse-dependency endpoints do not apply. R41 recommends a Cargo command and a repository-local Bash guard, not a distributed crate.

| Figure group in `raw/codex.md` | Result | Evidence |
|---|---|---|
| Fixture composition: 88 packages, comprising 85 registry packages and 3 workspace members | ok | `raw/fixture-r41/run-20260905-38559-1er1lv7/summary.json` records those values. The package inventory is retained, and the measured `Cargo.toml`, `Cargo.lock`, source files, `hook.sh`, and `measure.rb` all still match `fixture-sha256.json`. |
| Host and toolchain values: macOS 26.4, arm64, Cargo/Rust 1.96.0 floor, Cargo/Rust 1.98.0 comparison, and the 1.94.0 `stable` alias | ok | Records `001` through `009` retain the literal system and toolchain output. The report correctly says that the alias was not used for the 1.98.0 comparison. |
| Freshness and commit statuses: stale full metadata returns 101; the pre-commit hook blocks the commit with status 1; repaired and unrelated cases return 0 | ok | The 124-command `results.json` has no unexpected expected-status result. Its stale, repaired, parity, and skip-control records support the stated outcomes. Supplemental records also support the `check`, `build`, workspace-update, generate-lockfile, `--no-deps`, and `--dry-run` controls. |
| Latency table, CPU figures, throughput, and 10.067-second floor compilation | ok | The six timing rows, their sample counts, median/range values, CPU medians, 7.26/8.13 sequential warm metadata rates, and 10.066598-second compilation record round correctly from the retained `summary.json` and timed result records. The report labels the values as one macOS workload rather than a general latency guarantee. |
| Lockfile hash preservation and the exact stale-lock diagnostic | ok | The harness checks the lock hash before and after each locked stale command. Records `062-floor-1.96.0-stale-command.stderr` and `110-stable-1.98.0-stale-command.stderr` contain the reported `cannot update the lock file` diagnostic and `--locked` explanation. |

Figure counts: **ok 5; wrong 0; unverifiable 0**.

## Gates

| Fitness-gate claim in `raw/codex.md` | Result | Evidence |
|---|---|---|
| License is inapplicable to Cargo-command alternatives; the new repository helper is intended for the fixed `MIT OR Apache-2.0` template | ok | The recommendation adds neither a crate nor a dependency tree. The helper is retained repository code, not a separately licensed dependency. |
| The selected `cargo metadata --locked --format-version=1` command works at the 1.96.0 MSRV floor for the retained workspace | ok | The fixture declares `rust-version = "1.96"`; record `floor-1.96.0-metadata-cold` and ten warm records return 0, and the floor `cargo check --workspace --all-targets --locked` returns 0 on macOS. |
| RustSec, unsafe-Rust, crate features, and async-runtime coupling are inapplicable to the command and Bash helper | ok | The recommendation introduces no Rust crate, feature selection, runtime, or authored unsafe Rust. The report does not extend that conclusion to Cargo itself or the fixture's application dependencies. |
| The dominant recommendation has been tested on both fixed CI operating systems, `ubuntu-latest` and `macos-latest` | unverifiable | macOS arm64 execution is retained. The cited Warp, clap, and Cargo workflows demonstrate upstream Ubuntu use of related Cargo commands, but none executes this repository-local index-parity guard on Linux. `raw/codex.md` itself says Linux execution remains outstanding. |
| The command adds no application binary-size growth or application compilation cost; its resolver/process cost is measured separately | ok | The command uses the installed Cargo toolchain, and the report separates metadata/commit timings from the optional floor compilation check. |
| The helper's staged/worktree scope is bounded rather than presented as generally safe for external paths, symlinks, user configuration, or concurrent edits | ok | `hook.sh` and `fixture-r41/README.md` match the stated repository-contained scope and limitations. The retained partial-staging and unrelated-commit controls support the claims within that scope. |

Gate counts: **ok 5; wrong 0; unverifiable 1**.

## References

| Cited implementation or source | Result | Evidence |
|---|---|---|
| Cargo metadata, update, resolver, build, check, and generate-lockfile documentation | ok | The report's Cargo documentation URLs resolve on 2026-09-05. The metadata documentation supports `--locked` as the mode that refuses a lockfile-changing resolution. |
| Git hook and diff documentation | ok | The cited Git pages resolve. They support the non-zero pre-commit refusal behavior and the index/worktree distinction used by the proposed guard. |
| Warp CI as a reference for `cargo metadata --locked --format-version=1` and remediation text | ok | The live workflow URL resolves and the retained `013-warp-ci.stdout` contains the command and remediation. The revision correctly limits this reference to the command and CI-tier message; it no longer represents Warp as a reference for the staged-trigger/parity-guard composition. |
| clap and Cargo workflows as lockfile-check practice | ok | Both live workflow URLs resolve. The retained clap workflow runs `cargo update --workspace --locked`; the Cargo workflow runs `cargo update -p cargo --locked`. |
| Pinned Python and TypeScript precedents | ok | Retained immutable `git show` output and successful command records establish Python's staged `uv lock --check` hook and the absence of an equivalent dedicated TypeScript hook at the cited commits. |
| Complete staged-trigger plus index-parity guard reference implementation | ok | The report explicitly states the evidence gap: no maintained external implementation was found. It labels `hook.sh` as newly authored, executable research code rather than external maintenance evidence, which satisfies the prompt's required gap disclosure. |

Reference counts: **ok 6; wrong 0; unverifiable 0**.

## Verdict

**defective**

The earlier evidence defects are repaired: the timing claims have retained workload, harness, raw command, and integrity evidence; the macOS/MSRV evidence is direct; the Warp and TypeScript limitations are accurately stated; and the report discloses the missing maintained full-guard reference.

One required acceptance condition remains unresolved. The fixed `target-os-matrix` is `ubuntu-latest, macos-latest`, and the prompt makes an empirical acceptance check mandatory. The report executed the guard only in macOS fixture repositories. Upstream Ubuntu workflows establish that related Cargo commands run there, but they do not test `hook.sh`, its Git pathspecs, or its index/worktree-parity behavior on Linux. The recommendation can remain a bounded proposal, but it cannot pass the operating-system fitness gate until the retained stale, repair, parity, member-trigger, and skip controls run on Linux as well.

Totals: **ok 16; wrong 0; unverifiable 1**.
