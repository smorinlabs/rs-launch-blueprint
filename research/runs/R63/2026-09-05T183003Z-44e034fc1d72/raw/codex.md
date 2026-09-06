# R63 — Progress spinner

Raw research report by `research-codex-2026-09-05T183003Z-44e034fc1d72`. Retrieved 2026-09-05. This report recommends a dependency range, but it does not claim that the proposed integration tests have run.

### Landscape

This item decides terminal progress rendering: a short-lived animated status indicator for a network fetch. Rust has no first-party spinner; `std::io::IsTerminal` only answers whether a stream is a terminal and has been stable since Rust 1.70.0 ([Rust standard-library documentation](https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html), retrieved 2026-09-05). R65 owns that TTY decision, so it is an input to R63 rather than a candidate dependency.

The field map is: (1) built-in/first-party: no renderer; use the Rust standard library only for the future R65 seam; (2) established general progress renderers: [`indicatif`](https://crates.io/crates/indicatif) and [`prodash`](https://crates.io/crates/prodash); (3) spinner-focused alternatives: [`spinoff`](https://crates.io/crates/spinoff), [`spinners`](https://crates.io/crates/spinners), and [`spinner`](https://crates.io/crates/spinner). crates.io is the authoritative registry for package release and download figures; each candidate's GitHub repository is authoritative for its manifest, CI, implementation, and maintenance activity.

Practice evidence favors `indicatif`: its registry endpoint records 47,687,953 recent downloads and 211,641,552 total downloads ([crates.io API](https://crates.io/api/v1/crates/indicatif), retrieved 2026-09-05). The maintained crate CI tests stable Rust on Ubuntu, macOS, and Windows ([`rust.yml`](https://raw.githubusercontent.com/console-rs/indicatif/main/.github/workflows/rust.yml), retrieved 2026-09-05). `prodash` is a maintained production reference in Gitoxide: the 11,921-star, active `gitoxide` repository declares optional `prodash = "31.0.0"` support ([Gitoxide repository API](https://api.github.com/repos/GitoxideLabs/gitoxide) and [`gix-features/Cargo.toml`](https://raw.githubusercontent.com/GitoxideLabs/gitoxide/main/gix-features/Cargo.toml), retrieved 2026-09-05). No comparably strong, directly verified production reference was found for the spinner-only alternatives.

### Principles and implementation

The shared principle is not a common three-repository spinner capability: Python has no cited spinner, while TypeScript has one. The agreement level is therefore a harmonized **CLI output policy**: optional human-progress feedback may appear only on an attended, non-CI terminal, and it must never contaminate machine-readable stdout. F283 records the TypeScript precedent as a stderr spinner gated by stderr TTY and absence of `CI` ([`COMMONALITY.md`](../../../../../docs/port/COMMONALITY.md), retrieved 2026-09-05); the divergence analysis records the missing Python rationale, so it must not be invented ([`DIVERGENCE-ANALYSIS.md`](../../../../../docs/port/DIVERGENCE-ANALYSIS.md), retrieved 2026-09-05).

Observable acceptance criteria are: a fetch on an enabled interactive stderr starts exactly one spinner; JSON stdout remains byte-for-byte valid; `CI` present, a non-TTY result from R65, `--quiet`, or `--no-input` creates no renderer; completion, error, and cancellation clear the line; and width zero neither panics nor writes an over-wide filler run. `indicatif::ProgressBar::new_spinner()` is specifically documented to draw to stderr, and `ProgressDrawTarget::term` hides unattended or dumb terminals ([API documentation](https://docs.rs/indicatif/0.18.6/indicatif/struct.ProgressBar.html) and [draw-target source](https://raw.githubusercontent.com/console-rs/indicatif/main/src/draw_target.rs), retrieved 2026-09-05). Its regression test covers width zero and asserts that drawing does not fail ([draw-target source, `draw_to_term_narrower_than_its_content`](https://raw.githubusercontent.com/console-rs/indicatif/main/src/draw_target.rs), retrieved 2026-09-05).

The viable architectures are: no dependency plus handwritten ANSI control sequences; a spinner-only crate; `indicatif` as a single spinner; or `prodash` with its line renderer. Handwritten ANSI owns cursor cleanup, width, and refresh lifecycle in template code. Spinner-only crates are lighter in purpose but fail the declared-MSRV evidence gate, and `spinoff` writes stdout unless explicitly given `Streams::Stderr` ([`spinoff` source](https://raw.githubusercontent.com/ad4mx/spinoff/main/src/lib.rs), retrieved 2026-09-05). `prodash` is designed for a progress hierarchy and requires a renderer/backend feature combination; its line renderer documents a width-overrun artifact limitation ([`prodash` README](https://raw.githubusercontent.com/GitoxideLabs/prodash/main/README.md), retrieved 2026-09-05). `indicatif` supplies the required lifecycle and stderr behavior without adding a second terminal backend.

No `BASELINE-REVIEW:` line is emitted: the reviewed baseline identifies F283 as a DIVERGENT research item and contains no F283 baseline-review finding ([`COMMONALITY.md`](../../../../../docs/port/COMMONALITY.md), retrieved 2026-09-05).

### Dominant choice

Choose `indicatif = "0.18"`, initially resolved and pinned through `Cargo.lock` to 0.18.6. Its default spinner writes stderr, uses a bounded 20 Hz draw target, supports a steady tick for slow fetches, clears on completion, automatically hides non-terminal/dumb targets, and has a zero-width source regression test ([`ProgressBar` API](https://docs.rs/indicatif/0.18.6/indicatif/struct.ProgressBar.html) and [source](https://raw.githubusercontent.com/console-rs/indicatif/main/src/progress_bar.rs), retrieved 2026-09-05). The crate is MIT licensed, declares `rust-version = "1.85"`, and tests its declared MSRV in CI ([published manifest](https://docs.rs/crate/indicatif/0.18.6/source/Cargo.toml) and [`rust.yml`](https://raw.githubusercontent.com/console-rs/indicatif/main/.github/workflows/rust.yml), retrieved 2026-09-05).

### Qualified shortlist

No candidate is fully qualified yet, because this raw run did not resolve and check each dependency tree on the policy floor. The following are the only provisional candidates that pass the direct manifest, license, RustSec-page, and stated-feature checks; the validation strategy closes the remaining resolved-tree gate.

| Candidate | Role | 90-day / total downloads | Stars | Last non-yanked release | Maintenance | Notable adopter | Trade-off |
|---|---|---:|---:|---|---|---|---|
| `indicatif` 0.18.6 | one spinner on stderr | 47,687,953 / 211,641,552 ([API](https://crates.io/api/v1/crates/indicatif), retrieved 2026-09-05) | 5,209 ([GitHub API](https://api.github.com/repos/console-rs/indicatif), retrieved 2026-09-05) | 0.18.6, 2026-07-01 ([versions API](https://crates.io/api/v1/crates/indicatif/versions), retrieved 2026-09-05) | active; pushed 2026-09-03 | broad downstream registry use; direct named adopter not independently verified | broader progress API than this call site needs |
| `prodash` 31.0.0 | hierarchy and optional line/TUI renderers | 12,809,634 / 52,704,486 ([API](https://crates.io/api/v1/crates/prodash), retrieved 2026-09-05) | 398 ([GitHub API](https://api.github.com/repos/GitoxideLabs/prodash), retrieved 2026-09-05) | 31.0.0, 2026-01-08 ([versions API](https://crates.io/api/v1/crates/prodash/versions), retrieved 2026-09-05) | active; pushed 2026-09-01 | Gitoxide | renderer/backend setup is disproportionate for one fetch |

Both manifests declare MIT and `rust-version = "1.85"` ([`indicatif` manifest](https://raw.githubusercontent.com/console-rs/indicatif/main/Cargo.toml) and [`prodash` manifest](https://raw.githubusercontent.com/GitoxideLabs/prodash/main/Cargo.toml), retrieved 2026-09-05), which is below the current Rust 1.98.1 stable channel and its stable-minus-two-minor policy floor ([stable channel manifest](https://static.rust-lang.org/dist/channel-rust-stable.toml), retrieved 2026-09-05). RustSec package-page URLs returned HTTP 404 for both, which is evidence that those pages could not be used to establish an advisory count; `cargo audit` remains required. `indicatif` directly documents Ubuntu/macOS/Windows CI. `prodash` documents Linux and Windows CI but no macOS job in its current workflow, so it cannot be adopted until the template independently verifies macOS ([`prodash` CI](https://raw.githubusercontent.com/GitoxideLabs/prodash/main/.github/workflows/ci.yml), retrieved 2026-09-05). `indicatif` defaults to `unicode-width` and `wasmbind`; it has no async-runtime coupling. Its cost is qualitatively a small rendering stack (`console`, atomic and width support), plus one ticker thread only when `enable_steady_tick` is called ([manifest](https://raw.githubusercontent.com/console-rs/indicatif/main/Cargo.toml) and [API](https://docs.rs/indicatif/0.18.6/indicatif/struct.ProgressBar.html), retrieved 2026-09-05). `prodash` defaults to a progress tree and requires optional render-line backend features; that is a larger compile and binary footprint ([manifest](https://raw.githubusercontent.com/GitoxideLabs/prodash/main/Cargo.toml), retrieved 2026-09-05).

For `indicatif`, the ten most-recent actual GitHub issues had a median first maintainer response of about 13.2 hours among the eight answered; two had no maintainer response at retrieval. This calculation excludes pull requests and uses `MEMBER`/`OWNER`/`COLLABORATOR` comments from the issue and comment endpoints ([issue search](https://api.github.com/search/issues?q=repo%3Aconsole-rs%2Findicatif+is%3Aissue&sort=created&order=desc&per_page=10), retrieved 2026-09-05). The corresponding per-issue comment inspection was not preserved as a durable artifact, so treat the responsiveness figure as raw-run evidence and repeat it during decision audit.

### Excluded by gate

`spinners` 4.2.0 is excluded because its published manifest has no `rust-version` declaration, so it cannot demonstrate the template's declared-and-CI-tested MSRV policy; it also has an unresolved history of stdout-to-stderr conversion requests ([manifest](https://raw.githubusercontent.com/FGRibreau/spinners/master/Cargo.toml) and [issue 33](https://github.com/FGRibreau/spinners/issues/33), retrieved 2026-09-05). Its figures are 668,986 recent downloads, 7,083,964 total downloads, 602 stars, and release 4.2.0 on 2026-03-04 ([crates.io API](https://crates.io/api/v1/crates/spinners), [versions API](https://crates.io/api/v1/crates/spinners/versions), and [GitHub API](https://api.github.com/repos/FGRibreau/spinners), retrieved 2026-09-05).

`spinoff` 0.8.0 is excluded because its manifest has no `rust-version` declaration, its 2023 release is stale, and its normal constructor writes stdout; it requires an explicit alternate stream ([manifest](https://raw.githubusercontent.com/ad4mx/spinoff/main/Cargo.toml) and [source](https://raw.githubusercontent.com/ad4mx/spinoff/main/src/lib.rs), retrieved 2026-09-05). It has 97,736 recent downloads, 727,543 total downloads, 577 stars, and an open report that dependency `paste` is unmaintained ([crates.io API](https://crates.io/api/v1/crates/spinoff), [GitHub API](https://api.github.com/repos/ad4mx/spinoff), and [issue 30](https://github.com/ad4mx/spinoff/issues/30), retrieved 2026-09-05).

`spinner` 0.5.0 is excluded by license and maintenance: the registry lists LGPL-3.0, and GitHub marks the repository archived ([versions API](https://crates.io/api/v1/crates/spinner/versions) and [GitHub API](https://api.github.com/repos/TheNeikos/spinner), retrieved 2026-09-05).

### Up-and-comers

There is no qualifying up-and-comer. `spinners` is the current spinner-focused lead but fails the MSRV-declaration gate. `spinoff` has a smaller feature-targeted surface but is at-risk because its last release was 2023-08-04 and its open issue reports an unmaintained dependency ([versions API](https://crates.io/api/v1/crates/spinoff/versions) and [issue 30](https://github.com/ad4mx/spinoff/issues/30), retrieved 2026-09-05). Neither should be promoted merely because it is lighter.

### Fit for this template

CLI: `indicatif` fits when the adapter receives R65's `stderr_is_tty = true`, `CI` is absent, and interaction is allowed. The call site owns those product-policy booleans; `indicatif` owns only terminal drawing. Library: keep `indicatif` out of the public library API and inject a no-op-or-spinner progress port so library consumers inherit neither terminal I/O nor a progress dependency. Web: do not use it; request progress belongs in HTTP status, tracing, or a later web-specific mechanism, not server stderr. This separation preserves the CLI feedback policy without inventing parity where the library and web contexts do not have terminal users.

### Recommendation

Adopt `indicatif = "0.18"` behind a CLI-only adapter. On the enabled path, create `ProgressBar::new_spinner()`, set `"Fetching projects…"`, call `enable_steady_tick` at a modest interval, await the fetch, then call `finish_and_clear` in a scope that also clears on error. On every disabled path, create no progress bar. Determine `CI` with `std::env::var_os("CI").is_none()` so an empty-but-present variable still counts as CI; pass the TTY verdict from R65 rather than testing a second way. `indicatif` already defaults to stderr, but retaining an explicit `ProgressDrawTarget::stderr()` in the adapter is a useful regression guard ([API](https://docs.rs/indicatif/0.18.6/indicatif/struct.ProgressBar.html), retrieved 2026-09-05).

### Ranked runner-up

`prodash` is the runner-up only if the template becomes a concurrent, multi-operation CLI that needs a shared progress hierarchy, not merely a single fetch spinner. It wins under that condition because Gitoxide demonstrates the architecture and `prodash` provides multiple renderers ([`prodash` README](https://raw.githubusercontent.com/GitoxideLabs/prodash/main/README.md) and [`gitoxide` manifest](https://raw.githubusercontent.com/GitoxideLabs/gitoxide/main/gix-features/Cargo.toml), retrieved 2026-09-05). Before it can win, add macOS validation because its own published CI does not demonstrate it.

### Tradeoffs

Against `prodash`, `indicatif` gives up a shared concurrent progress tree, detailed TUI, and advanced renderer configuration. That cost is accepted because R63 has one short fetch and needs no cross-task dashboard. Against `spinoff` and `spinners`, it gives up a spinner-only conceptual surface. That cost is accepted because `indicatif` meets stderr-by-default, maintenance, declared MSRV, platform-CI, and zero-width evidence requirements that those alternatives do not. The proposed steady tick starts a background thread, so the adapter must always clear and drop it after the fetch ([`enable_steady_tick` API](https://docs.rs/indicatif/0.18.6/indicatif/struct.ProgressBar.html), retrieved 2026-09-05).

### Parameters

No parameters are owned or formally consumed by R63. `assumes R65 tty-detection-result = stderr TTY boolean supplied by R65's selected seam`; this is an implementation dependency, not a new registry parameter. No `CONFLICT:` line is emitted: `indicatif` composes with R65 without changing R65's ownership.

### Migration implications

Add `indicatif = "0.18"` to the future CLI crate's `Cargo.toml`, lock the resolved version in `Cargo.lock`, and add a private progress adapter beside the command that performs the projects/network fetch. The adapter takes an R65-provided stderr-TTY verdict and policy inputs (`CI` presence, quiet, and no-input). The fetch command wraps only the network await; its JSON serializer continues to own stdout. Add CLI integration tests for the enabled pseudo-terminal case and disabled CI/non-TTY cases. No library or web crate should import `indicatif`.

### Validation strategy

These are planned checks, not executed results:

```sh
cargo +1.96.0 update -p indicatif --precise 0.18.6
cargo +1.96.0 check --workspace --all-targets
cargo test --workspace
cargo audit
CI=1 cargo run -p rs-launch-blueprint-cli -- projects --format json >stdout.txt 2>stderr.txt
python3 -m json.tool stdout.txt >/dev/null && test ! -s stderr.txt
```

The first two commands prove the resolved dependency graph builds on the current stable-minus-two floor; update the floor when stable changes. The test suite must use a fake or pseudo-terminal seam supplied by R65 to prove that the enabled branch writes progress only to stderr, then assert empty stderr with `CI`, non-TTY, `--quiet`, and `--no-input`. Add a width-zero `TermLike`-style regression or a terminal harness asserting no panic and no over-wide filler, matching the upstream regression. The final command proves JSON purity under CI; it does not prove interactive rendering.

### Confidence & re-verify trigger

Confidence is medium-high for the crate choice and medium for complete gate closure. Re-verify before implementation if `indicatif` 0.19 releases, its declared MSRV rises beyond the policy floor, `cargo audit` finds an advisory, R65 selects a seam that cannot be passed cleanly into the CLI adapter, or the fetch grows into concurrent multi-operation progress. Re-run the crate, versions, GitHub repository/issue, RustSec, CI, MSRV, and pseudo-terminal checks at that time.

### Sources

Method notes: queried the crates.io crate and versions endpoints for `indicatif`, `prodash`, `spinoff`, `spinners`, and `spinner`; GitHub repository, issue-search, workflow, manifest, and maintained-source URLs; the Rust stable-channel manifest and standard-library documentation; docs.rs; and the RustSec package URLs. All were retrieved 2026-09-05. The RustSec package URLs returned HTTP 404, so advisory absence was not verified and `cargo audit` is mandatory. The raw run did not resolve a fresh dependency tree, run a platform build, execute a pseudo-terminal fixture, or preserve per-issue comment JSON; those gaps are deliberately stated as planned validation rather than evidence of completion.
