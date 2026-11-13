# R06 — `unsafe` code policy (pattern) — DECISION

Run `2026-09-05T162400Z-31f07a2b91b6` · item kind `pattern` · tier focused · engines codex + opus · synthesized 2026-09-08 by a fresh context that produced neither raw report.

## Decision

**Pattern: safe-authoring hard boundary, workspace-inherited.** `rs-launch-blueprint` forbids `unsafe` in its own code outright. The mechanism is the rustc `unsafe_code` lint at level `forbid`, declared once in the root `Cargo.toml` `[workspace.lints.rust]` table and inherited by every workspace member through `[lints] workspace = true`. No `// SAFETY:` convention applies to the shipped template because no `unsafe` can exist in it; the convention and the clippy lints that mechanize it (`undocumented_unsafe_blocks`, `multiple_unsafe_ops_per_block`, `unnecessary_safety_comment`) are shipped pre-configured at `deny` in `[workspace.lints.clippy]` so that a fork which genuinely needs `unsafe` reaches a complete permitted-with-justification regime by changing one token (`forbid` → `deny`) and then annotating each site with `#[expect(unsafe_code, reason = "…")]` plus a `// SAFETY:` comment. The policy governs first-party crates only: Cargo compiles dependencies with `--cap-lints allow`, so the template makes no claim about `unsafe` inside its dependency tree (verified: `memchr` 2.8.3 builds under the policy on all four legs below).

Ledger row settled: **F023** (`docs/port/COMMONALITY.md`, origin `none`, verdict `RUST-ONLY`). No `BASELINE-REVIEW:` finding: F023 has no inherited mechanism to challenge.

Reference implementation (executed under `review/empirical/`, see `## Empirical check`):

```toml
# root Cargo.toml
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.package]
edition = "2024"
rust-version = "1.96"   # illustrative: the concrete floor is set by the fixed msrv-policy, not by R06

[workspace.lints.rust]
unsafe_code = "forbid"

# Shipped armed so that a fork's downgrade of `unsafe_code` to `deny` is a
# one-token edit rather than a design exercise. While `forbid` holds, the first
# two cannot fire (there are no `unsafe` blocks to lint); the third is live and
# rejects a `// SAFETY:` comment on safe code, which under `forbid` is all code.
[workspace.lints.clippy]
undocumented_unsafe_blocks    = "deny"
multiple_unsafe_ops_per_block = "deny"
unnecessary_safety_comment    = "deny"
```

```toml
# every member Cargo.toml
[lints]
workspace = true
```

No `#![forbid(unsafe_code)]` attribute is added to any crate root: the manifest table is the single source of truth, and duplicating it in source creates two places to keep in sync (both raws agree). No `clippy.toml` is needed: the two `undocumented_unsafe_blocks` configuration keys (`accept-comment-above-statement`, `accept-comment-above-attributes`) default to `true` (Clippy Book, lint configuration, https://doc.rust-lang.org/clippy/lint_configuration.html, retrieved 2026-09-06). `clippy::missing_safety_doc` (the `# Safety` rustdoc-section lint) is deliberately not listed: it is in clippy's `style` group, on by default at `warn` since clippy 1.39.0 (https://raw.githubusercontent.com/rust-lang/rust-clippy/master/clippy_lints/src/doc/mod.rs, retrieved 2026-09-06), so any `cargo clippy -- -D warnings` run already fails on it.

Policy text for the template's contributor documentation, to be carried verbatim: *"Code in this repository must not use `unsafe`. This is enforced by the compiler through `unsafe_code = "forbid"` in the workspace lint table; a per-site `#[allow]` or `#[expect]` cannot override it. The rule governs this repository's own crates only: Cargo compiles dependencies with `--cap-lints allow`, so it makes no claim about `unsafe` inside the dependency tree. A fork that genuinely needs `unsafe` changes `forbid` to `deny` in the root `Cargo.toml`, marks each site `#[expect(unsafe_code, reason = "…")]`, and writes a `// SAFETY:` comment on the line above each `unsafe` block; the clippy lints that enforce those comments are already configured."*

Answers to the prompt's questions, in its order:

| Question | Answer | Settled by |
|---|---|---|
| HIGH: `forbid` or `deny` at the root by default | `forbid`. The template has no `unsafe` requirement; its expected stack (`clap`, `axum`, `tower-http`) forbids or denies `unsafe` in its own code; `forbid` moves the escape from a per-site attribute a reviewer can miss to a root-manifest line every reviewer reads. | Both raws; practice table below; empirical N1–N3 |
| HIGH: what comparable templates set | Nothing. The most-starred general-purpose `cargo-generate` templates (`rust-github/template`, `ratatui/templates`) set no `unsafe` policy, and the Rust CLI working group's book contains zero occurrences of `unsafe` across 69 indexed documents. Among 18 well-regarded projects that took a position, `forbid` is the plurality (4 forbid · 2 deny · 2 warn · 10 unset). | Opus Landscape (retrieved 2026-09-06); Codex agrees the CLI book is silent |
| MEDIUM: if `deny`, which convention | Both together, and they are one mechanism: the `// SAFETY:` comment (origin: the standard library's Safety comments policy) mechanized by `clippy::undocumented_unsafe_blocks`, with `#[expect(unsafe_code, reason = "…")]` rather than `#[allow]` as the per-site hatch because it self-expires. The prompt's "Rust API Guidelines C-SAFETY" does not exist; the real item is `C-FAILURE`, which governs the `# Safety` rustdoc section, a different artifact. | Empirical R1a–R1c; WebFetch 2026-09-08 (see `## Engines`) |
| MEDIUM: dependency-tree distinction | Yes, in prose, not tooling: state that `forbid` is crate-local because Cargo passes `--cap-lints allow` to dependencies. `cargo-geiger` is out of scope (R13) and unfit for this mechanism: open issue #539 reports it does not recognize the `[lints]`-table form and prints `No unsafe usage found, missing #![forbid(unsafe_code)]`. | Cargo manifest reference (retrieved 2026-09-06); empirical P1 on every leg; https://github.com/geiger-rs/cargo-geiger/issues/539 (retrieved 2026-09-06) |
| LOW: per-crate or uniform | Uniform, once, in `[workspace.lints.rust]`. All three shapes (library, CLI, web) want the same level for the same reason; the mechanism is independent of whatever topology R02 chooses. | Opus "Fit for this template"; Codex agrees |

### Principles and implementation

**Shared requirement.** Code this template ships must not be able to introduce undefined behavior silently, and any future decision to take on that risk must be explicit, reviewable, and documented at the point of risk. Source: ledger row F023, origin `none`, verdict `RUST-ONLY`. Python's memory safety is enforced by the CPython runtime and TypeScript's by the JavaScript engine, so neither source repository could record a decision here; there is no inherited baseline and no `TS_PORT_DECISIONS.md` entry. **Agreement level: policy plus its enforcing mechanism**, not a capability and not an architectural pattern that shapes module boundaries. Both engines identify the same requirement and the same level.

**Essential behaviors** (B1–B5) and the **observable acceptance criteria** that check them; every criterion was executed (`## Empirical check`):

| Behavior | Acceptance criterion | Evidence |
|---|---|---|
| B1. Reject `unsafe` blocks in every member at compile time, with no extra tool | A1. `cargo check` on a member containing `unsafe { … }` fails with `error: usage of an `unsafe` block` and the note `requested on the command line with -F unsafe-code` (which proves the level came from the manifest, not from source) | N1, all four legs |
| B2. Reject the other constructs the lint covers (`no_mangle`, `export_name`, `link_section`), including the edition-2024 `#[unsafe(...)]` spelling | A4. `#[unsafe(no_mangle)]` on an `extern "C"` fn is rejected by the same lint | N4, all four legs (diagnostic wording differs by compiler version, see below) |
| B3. Declared in exactly one place; a new member inherits it with a two-line stanza | A3. A member declaring only `[lints] workspace = true` is covered, with no crate-root attribute | N1–N4 on a member whose only lint configuration is that stanza |
| B4. The escape is a deliberate, diff-visible act, not a scattered per-site suppression | A2. `#[allow(unsafe_code)]` next to the block does not rescue it (`E0453 … incompatible with previous forbid`); neither does `#[expect(unsafe_code, reason = …)]` | N2, N3, all four legs |
| B5. State honestly that the dependency tree is not covered | A5. A registry crate whose own source uses `unsafe` heavily (`memchr` 2.8.3) builds and tests cleanly under the policy | P1, P2, all four legs |

**What must agree versus what may vary.** Must agree: the level (`forbid`, workspace-wide), the single declaration site, the written first-party-only caveat, and the shape of the downgrade path (one token, then `#[expect]` + `// SAFETY:`). May vary: whether a fork downgrades; the exact clippy configuration keys; and which CI job or hook runs `cargo clippy`, which is R28's decision (lint wiring) shaped by R11 (job structure). `cargo check`, `cargo build` and `cargo test` enforce `unsafe_code = "forbid"` with no CI step added by this item, because the level is read from the manifest by every Cargo invocation (P2 runs the doctest `rustdoc` pass under the same table without complaint; Cargo forwards the table to rustdoc as `--forbid=unsafe_code`, a command line seen during fixture development but not retained in the saved logs).

**Architecture alternatives compared.** The alternatives differ in *where the policy lives*, not in which lint fires.

| | Alt-1: crate-root attribute `#![forbid(unsafe_code)]` | Alt-2: per-package `[lints.rust]` | **Alt-3: `[workspace.lints.rust]` + `[lints] workspace = true`** |
|---|---|---|---|
| Sites to edit for N crates | N source files, 2N when a crate has both a lib and a bin root (`sharkdp/bat` does exactly this: `src/lib.rs:22` and `src/bin/bat/main.rs:1`) | N manifests | 1 manifest + a 2-line stanza per member |
| A crate R02 adds later | Unprotected until someone remembers the attribute | Same | Protected by the stanza `cargo new` generates automatically inside the workspace (observed on cargo 1.98.0: `cargo new --lib` produced `[lints] workspace = true` and `edition.workspace = true` unprompted) |
| MSRV floor | none | Cargo 1.74 | Cargo 1.74 ("MSRV: Respected as of 1.74", Cargo Book workspaces reference, retrieved 2026-09-06); executed here on 1.96.0 |
| Recognized by `cargo-geiger` | yes | no (issue #539) | no (issue #539) |
| Practiced by | clap, rustls, ureq, bat, tower-http | reqwest, hyper (for other lints) | axum (this exact lint), uv, ruff, clap, actix-web, tokio, rustls (for other lints) |
| First-party illustration | rustc book `unsafe_code` example | Cargo Book `[lints]` example uses `unsafe_code = "forbid"` | Cargo Book workspaces "lints table" example is literally this pair |

Alt-3 is selected because it is the only alternative whose cost does not scale with a crate count R02 has not yet fixed (B3), and because it is the Cargo team's own worked example. Alt-1's single countervailing advantage (`cargo-geiger` recognition) is accepted as a loss: the tool is out of scope (R13), the misreporting is an open, acknowledged bug, and a fork wanting it can add the attribute *in addition to* the table at any time.

Level alternatives: `deny` (bat, tower-http) keeps a per-site hatch open, but whole-repository code search found the hatch essentially unused by its adopters (bat: 0 `allow(unsafe_code)`; tower-http: 1, in `#[cfg(windows)]` test scaffolding at `tower-http/src/services/fs/serve_dir/tests.rs:1233`; retrieved 2026-09-06). `warn` (uv, ruff) is a preference, not a policy: it keeps the build green, and under a `-D warnings` CI shape it becomes a de-facto `deny` in CI but not locally. Setting nothing (ripgrep, fd, serde) leaves only the edition-2024 `unsafe_op_in_unsafe_fn` warning, which improves the hygiene of `unsafe` that already exists and prevents none.

**Why the selected design preserves each principle.** The first clause (no silent UB) is met by `forbid` at compile time on every Cargo invocation (A1, A2, A4). The second clause (an explicit, reviewable, documented escape) is met by making the escape a one-token root-manifest edit, after which `#[expect(unsafe_code, reason = "…")]` carries the reason at the site and warns when it goes stale, and the pre-armed clippy lints require one `// SAFETY:` comment per unsafe operation (R1a–R1c executed). The first-party-only caveat (B5) is a stated part of the policy text, not a footnote, because A5 shows the boundary is real.

**Cost of the selection, measured.** `forbid` forecloses the good hatch along with the bad one: `#[expect(unsafe_code, reason = …)]` is rejected with the same `E0453` as `#[allow]` (N3). For a fork that needs exactly one `unsafe` block, the cost is one token in one line, made once, landing on a configuration this decision already specifies in full. The pre-armed clippy table is not entirely free: `unnecessary_safety_comment` is live under `forbid` and fails `cargo clippy -- -D warnings` on a `// SAFETY:` comment placed above safe code (P4). That is the desired behavior (under `forbid` every such comment is misleading, and the diagnostic says `consider removing the safety comment`), but authors should know the match is textual: any `//` comment line containing `SAFETY:` directly above a statement or item counts, including prose that merely mentions the convention. The synthesizer hit exactly this while building the fixture.

**Reference implementations.** Maintained, read at `HEAD` on 2026-09-06: `tokio-rs/axum` implements the recommended pair line-for-line (`Cargo.toml:8-9`, `axum/Cargo.toml:246-247`; 27,029 stars; `axum` 112,742,897 downloads/90d, 456,207,013 all-time, `GET https://crates.io/api/v1/crates/axum`); `clap-rs/clap` forbids the lint at the crate root (`clap_builder/src/lib.rs:9`; 16,686 stars; 1,107,038,264 all-time downloads); `rustls/rustls` (`rustls/src/lib.rs:305`) and `algesten/ureq` (`src/lib.rs:524`) likewise. For the downgrade regime: `astral-sh/ruff` pairs `#[expect(unsafe_code)]` with an adjacent `// SAFETY:` comment at `crates/ruff_index/src/vec.rs:182-188` (10 such sites repo-wide); `casey/just` ships `clippy::undocumented_unsafe_blocks = "deny"` (`Cargo.toml:84`); the Rust standard library's Safety comments policy is the convention's origin (https://std-dev-guide.rust-lang.org/policy/safety-comments.html, retrieved 2026-09-06). Performance: zero runtime and binary-size cost (the mechanism emits no code); compile-time cost limited to diagnostic emission for a lint rustc already evaluates; the clippy lints run only under `cargo clippy`. Measured on the one-member fixture: `cargo clippy --workspace --all-targets -- -D warnings` finished in 0.21 s warm on macOS 1.98.0; not extrapolated to a larger workspace.

**Excluded by gate.** All toolchain-native options pass or are `inapplicable` for every gate: license (inapplicable: rustc, Cargo and clippy ship with the `MIT OR Apache-2.0` toolchain, no crate is added), MSRV (Cargo 1.74 for the table, 1.81 for `#[expect]`, 1.85 for edition 2024, all below the 1.96 floor; executed on 1.96.0), RustSec (inapplicable, no crate), OS matrix (executed on macOS and Linux, see below), default features and async coupling (inapplicable), binary-size and compile-time cost (zero and negligible, stated above). `cargo-geiger` (excluded on scope, R13, and on fitness, issue #539; full crate figures in `raw/opus.md` `### Excluded by gate`, retrieved 2026-09-06: 50,882 downloads/90d, 233,043 all-time, 0.13.0 released 2025-08-31, 1,645 stars, 45 open issues, no RustSec page, rubric `stable-quiet`) and `cargo-vet` (excluded on scope, R13; 97,641 downloads/90d, 0.10.2 released 2026-01-13, 987 stars, rubric `stable-quiet`) are the only crate candidates.

**Migration implications** (file-level, all additions since the template has no Rust code yet): root `Cargo.toml` gains the two tables above with the comment; every member `Cargo.toml` gains `[lints] workspace = true` (generated by `cargo new` inside the workspace, but the new-crate checklist should still name it); `CONTRIBUTING.md` gains the policy text above; `README.md` optionally states that the repository forbids `unsafe` in its own code, never that the dependency tree is `unsafe`-free; no `clippy.toml`, no `src/**` attribute, no CI change from this item. Two operational notes for the items that will run these checks (R28, R42), recorded because the synthesizer hit them: a rustup `cargo +<toolchain>` proxy does not put that toolchain's `bin` first on `PATH`, so a foreign `rustc`/`rustdoc` earlier on `PATH` (Homebrew's, on this machine) is silently used unless Cargo's `RUSTC`/`RUSTDOC` variables are set or the toolchain `bin` is prepended; and the `unsafe_code` diagnostic for `no_mangle` changed wording between 1.96.0 (`declaration of a `no_mangle` function`) and 1.98.x (`usage of the unsafe `#[no_mangle]` attribute`), so a snapshot test must match the `-F unsafe-code` note, not the message.

**Ranked runner-up.** `unsafe_code = "deny"` in the same table, with `#[expect(unsafe_code, reason = "…")]` plus a mandatory `// SAFETY:` comment per site; identical in every other respect. It wins if the owner positions the template toward forks that routinely write `unsafe` (systems, FFI, performance-critical consumers), if the template itself acquires an exported-symbol or FFI requirement before shipping (R68 or a future C-ABI surface; N4 shows `forbid` rejects `#[unsafe(no_mangle)]`), or if a dependency in the settled stack is found to expand `unsafe` into consuming crates through a macro. In each case the change is one token and nothing else in this decision changes.

re-verify: when R02 fixes the workspace topology (run P1–N4 over every member); when R60/R69/R05 settle the real dependency set (re-run P1–P3 against it in place of `memchr`); before adding FFI, exported symbols, SIMD intrinsics or custom allocation; when `cargo-geiger` issue #539 closes; at each Rust edition boundary (the rustc lint-levels and allowed-by-default pages); and no later than 2027-03-08 for figure freshness.

## Parameters

R06 owns no parameter: the prompt's `- owns:` line is empty and the registry row (`research/CLAUDE.md`, R06) shows `—`. Codex's raw wrote `owns unsafe-code-policy = forbid-authored-unsafe-workspace-wide`; that parameter does not exist in `docs/port/PARAMETERS.md` and is not created here.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

R06 consumes no researched parameter. No `CONFLICT:` line: neither raw raised one, and no fixed parameter needs to change. Edition 2024 supports the recommendation (it makes `unsafe_op_in_unsafe_fn` warn by default and introduces the `#[unsafe(...)]` spellings the lint also rejects); the MSRV floor (1.96 at run time) is far above every requirement (Cargo 1.74, `#[expect]` 1.81, edition 2024 1.85); the license gate is inapplicable; lint levels are OS-independent and were executed on both OS families.

## Empirical check

**Fixture.** `review/empirical/` in this run directory: a workspace root `Cargo.toml` carrying exactly the recommended configuration, one member `crates/demo` created with `/opt/homebrew/bin/cargo new --lib --vcs none` (which generated `[lints] workspace = true`, `edition.workspace = true` and `rust-version.workspace = true` unprompted), a real registry dependency `memchr = "2"` (resolved to 2.8.3, `Cargo.lock` retained in the fixture), and eight source variants under `variants/` applied by `run-checks.sh`. Resting state is `variants/safe.rs` (safe code calling `memchr::memchr`, one unit test); the script restores it and the root manifest through a `trap`, and each log ends with `lib.rs == variants/safe.rs: yes` and `unsafe_code = "forbid"`. Build artifacts went to the session scratchpad (`CARGO_TARGET_DIR`), never into the repository.

**Driver.** `review/empirical/run-checks.sh` (bash, no `set -e`; prints every command and its `exit=` code). Environment per leg: `R06_CARGO`, `R06_RUSTC`, `R06_CLIPPY`, plus Cargo's own `RUSTC` and `RUSTDOC` pinned to the leg's toolchain and that toolchain's `bin` first on `PATH`. Each log self-attests the compiler cargo actually invoked via `cargo rustc -p demo --lib -- -vV` (a separate probe target dir, so P1 still shows `memchr` being checked). This probe exists because the first attempt at the 1.96.0 leg silently used Homebrew's `rustc` 1.98.0 through `cargo +1.96.0`; that log was discarded and the leg re-run.

**Legs.** Runs executed 2026-09-09 05:50–05:57 UTC (2026-09-08 local time, the date used elsewhere in this decision). Working directory: the fixture (macOS) or a VM-local copy `/tmp/r06-empirical` streamed in by `tar` over stdin with the script's sha256 verified equal to the host copy (`8966b77ebe52a36a10cf0554aad138033ff96108dbf0f97e72f5aae4975f69c2`), because the Lima home mount is read-only in the VM and served a stale view of the script. The VM is **Ubuntu 25.10 on aarch64** (`Linux lima-ubuntu 6.17.0-41-generic … aarch64`), whereas GitHub's `ubuntu-latest` runners are x86_64; lint levels have no architecture dependence, but the x86_64 leg is not executed here.

| Leg | rustc / cargo (self-attested) | clippy | Log |
|---|---|---|---|
| macOS (Darwin 25.4.0), aarch64-apple-darwin, stable | `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`, `clippy 0.1.98` | yes | `review/evidence/macos-stable-1.98.0.log` (263 lines) |
| macOS, floor | `rustc 1.96.0 (ac68faa20 2026-05-25)`, `cargo 1.96.0 (30a34c682 2026-05-25)` via `~/.rustup/toolchains/1.96.0-aarch64-apple-darwin/bin` | no (component not installed) | `review/evidence/macos-floor-1.96.0.log` (207 lines) |
| Ubuntu 25.10, aarch64-unknown-linux-gnu, stable | `rustc 1.98.1 (48a229cea 2026-09-01)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)` | no (component not installed) | `review/evidence/linux-vm-stable-1.98.1.log` (210 lines) |
| Ubuntu 25.10, floor | `rustc 1.96.0 (ac68faa20 2026-05-25)`, `cargo 1.96.0 (30a34c682 2026-05-25)` | no (component not installed) | `review/evidence/linux-vm-floor-1.96.0.log` (210 lines) |

**Clippy coverage gap, stated.** The `clippy` component is not installed for 1.96.0 on the host nor for either VM toolchain, and installing components was outside this run's authorization. `cargo +1.96.0 clippy` on the host falls through to Homebrew's `cargo-clippy` 0.1.98 (a mismatched driver), so it was never run in that form. Clippy legs P3, P4, R1b, R1c therefore ran on macOS 1.98.0 only; the `cargo check`/`cargo test` legs, which are the enforcement path, ran on all four. On the three no-clippy legs the presence of the `[workspace.lints.clippy]` table caused no diagnostic from `cargo check`, `cargo test` or the doctest `rustdoc` run.

**Results, identical across all four legs unless noted** (exit codes from the logs):

| Step | Command (from the fixture root) | Expected | Observed |
|---|---|---|---|
| P1 | `cargo check --workspace` on `safe.rs` | exit 0; `memchr` builds under `forbid` | `Checking memchr v2.8.3` … `Finished`, `exit=0` |
| P2 | `cargo test --workspace` | exit 0 | `test tests::finds_comma ... ok`, doc-tests `0 passed; 0 failed`, `exit=0` |
| P3 (1.98.0 only) | `cargo clippy --workspace --all-targets -- -D warnings` | exit 0 | `Finished … in 0.21s`, `exit=0` |
| P4 (1.98.0 only) | `safe-stray-safety-comment.rs`: `cargo check`, then clippy `-D warnings` | check 0; clippy fails | check `exit=0`; clippy `error: expression has unnecessary safety comment … help: consider removing the safety comment … -D clippy::unnecessary-safety-comment`, `exit=101` |
| N1 | `unsafe-block.rs`: `cargo check --workspace` | fails, inherited level | `error: usage of an `unsafe` block` … `= note: requested on the command line with `-F unsafe-code``, `exit=101` |
| N2 | `allow-override.rs` | fails, E0453 | `error[E0453]: allow(unsafe_code) incompatible with previous forbid` … `overruled by previous forbid` … `= note: `forbid` lint level was set on command line (`-F unsafe_code`)`, plus the N1 error; `exit=101` |
| N3 | `expect-override.rs` | fails, E0453 | `error[E0453]: expect(unsafe_code) incompatible with previous forbid`, plus the N1 error; `exit=101` |
| N4 | `no-mangle.rs` (`#[unsafe(no_mangle)] pub extern "C" fn`) | fails, same lint | 1.98.x: `error: usage of the unsafe `#[no_mangle]` attribute`; 1.96.0: `error: declaration of a `no_mangle` function`; both carry `= note: requested on the command line with `-F unsafe-code``; `exit=101` |
| R1a | root `sed` `forbid` → `deny`; `deny-with-safety-comment.rs` (`#[expect]` + `// SAFETY:`): `cargo check` | exit 0 | `Finished`, `exit=0` |
| R1b (1.98.0 only) | same, clippy `-D warnings` | exit 0 | `Finished … in 0.10s`, `exit=0` |
| R1c (1.98.0 only) | `deny-without-safety-comment.rs`, clippy `-D warnings` | fails | `error: unsafe block missing a safety comment … help: consider adding a safety comment on the preceding line … -D clippy::undocumented-unsafe-blocks`, `exit=101` |
| restore | trap | resting state | `lib.rs == variants/safe.rs: yes`; `17:unsafe_code = "forbid"` |

Verbatim N1 from `macos-stable-1.98.0.log`:

```
$ /opt/homebrew/bin/cargo check --workspace
    Checking demo v0.1.0 (/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R06/2026-09-05T162400Z-31f07a2b91b6/review/empirical/crates/demo)
error: usage of an `unsafe` block
 --> crates/demo/src/lib.rs:3:5
  |
3 |     unsafe { *x.get_unchecked(0) }
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  |
  = note: requested on the command line with `-F unsafe-code`

error: could not compile `demo` (lib) due to 1 previous error
exit=101
```

Verbatim P4 clippy diagnostic (the finding that corrects the raws' "dormant" claim), same log:

```
error: expression has unnecessary safety comment
 --> crates/demo/src/lib.rs:8:5
  |
8 |     x.first().copied()
  |     ^^^^^^^^^^^^^^^^^^
  |
help: consider removing the safety comment
 --> crates/demo/src/lib.rs:7:8
  |
7 |     // SAFETY: nothing here is unsafe; this comment is the thing under test.
  |        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  = note: requested on the command line with `-D clippy::unnecessary-safety-comment`
```

**Reproduce.** macOS stable: `R06_CARGO=/opt/homebrew/bin/cargo R06_RUSTC=/opt/homebrew/bin/rustc RUSTC=/opt/homebrew/bin/rustc RUSTDOC=/opt/homebrew/bin/rustdoc R06_CLIPPY=yes CARGO_TARGET_DIR=<scratch> review/empirical/run-checks.sh > review/evidence/macos-stable-1.98.0.log 2>&1` (script exit 0). Floor: `TCBIN=$HOME/.rustup/toolchains/1.96.0-aarch64-apple-darwin/bin; PATH="$TCBIN:$PATH" R06_CARGO=$TCBIN/cargo R06_RUSTC=$TCBIN/rustc RUSTC=$TCBIN/rustc RUSTDOC=$TCBIN/rustdoc R06_CLIPPY=no CARGO_TARGET_DIR=<scratch> review/empirical/run-checks.sh` (script exit 0). Linux: `tar -C review -cf - empirical | limactl shell ubuntu -- bash -lc '…extract to /tmp/r06-empirical…'`, then the same invocation with `TCBIN=$HOME/.rustup/toolchains/<stable|1.96.0>-aarch64-unknown-linux-gnu/bin` and `CARGO_TARGET_DIR=/tmp/…`, stdout captured on the host (script exit 0 on both). VM temporary copies were removed afterwards.

**Not executed.** Clippy on 1.96.0 and on Linux (component absent, see above); an x86_64 Linux leg; `cargo-geiger`'s misreporting of the table form (out of scope, reported from issue #539 only); the auto-generated `[lints] workspace = true` stanza was observed from `cargo new` on cargo 1.98.0 only.

## Engines

- codex `raw/codex.md` (gpt-5.6-terra, retrievals dated 2026-09-05; executed no checks: "these checks are proposed and were not executed").
- opus `raw/opus.md` (claude-opus-5[1m], retrievals dated 2026-09-06; executed checks A–K on macOS rustc 1.98.0 only, in a throwaway workspace not retained).

Both engines recommend the same level (`forbid`), the same declaration site (`[workspace.lints.rust]` inherited via `[lints] workspace = true`), the same runner-up (`deny` with `// SAFETY:` enforced by `clippy::undocumented_unsafe_blocks`), the same first-party-only caveat, the same exclusion of `cargo-geiger` on scope, no crate-root attribute duplication, and no `CONFLICT:`. Disagreements and how each was settled:

1. **Ship the clippy safety-comment lints pre-armed (Opus) or omit them because "a documentation rule for forbidden code creates a misleading implied exception path" (Codex).** Settled for Opus's position by execution, with a correction to Opus. P3 shows the table costs nothing on clean safe code under `forbid` and `-D warnings`; R1a–R1c show it is functional the moment `forbid` becomes `deny`; the manifest comment states plainly why the table is there, which answers Codex's legibility concern; `casey/just` ships `undocumented_unsafe_blocks = "deny"` as a standalone policy (`Cargo.toml:84`, retrieved 2026-09-06), so the lint is used in production independently of a `deny` level. The correction: Opus's claim that the three lints "cannot fire" under `forbid` is false for `unnecessary_safety_comment` (P4), and the recommended comment now says so. This remains a design judgement; the empirical facts constrain but do not decide it.
2. **`clippy::missing_safety_doc` in the runner-up (Codex) or not (Opus).** Settled by the clippy source Opus retrieved (group `style`, `#[clippy::version = "1.39.0"]`, retrieved 2026-09-06): it is on by default at `warn` and therefore already fails a `-D warnings` run; listing it would be redundant. Codex's inclusion is harmless but unnecessary.
3. **Workspace-lints MSRV: "Cargo documents MSRV 1.64" (Codex) versus "Respected as of 1.74" (Opus).** Opus quotes the Cargo Book workspaces reference verbatim (retrieved 2026-09-06); Codex's 1.64 is not supported by the section it cites (the same page, https://doc.rust-lang.org/cargo/reference/workspaces.html, retrieved 2026-09-06, carries the per-section MSRV notes, and the lints table's note reads 1.74). Empirically moot: the mechanism ran on 1.96.0 on both OS families.
4. **Citation of the Rust API Guidelines.** Codex cites https://rust-lang.github.io/api-guidelines/unsafety.html and the prompt's `C-SAFETY`; Opus states neither exists and the real item is `C-FAILURE`. Settled by WebFetch on 2026-09-08: `unsafety.html` returns HTTP 404, and the checklist (https://rust-lang.github.io/api-guidelines/checklist.html) contains no `C-SAFETY`; its only safety-related item is `C-FAILURE`, "Function docs include error, panic, and safety considerations". Codex's citation is unverifiable and is not carried; Opus's correction is.
5. **Codex's `owns unsafe-code-policy = …` line.** Not a registry parameter; the prompt's `owns:` line is empty. Dropped (see `## Parameters`).
6. **Practice-evidence depth.** Codex read two projects (clap, axum) and could not verify any adopter of the `deny` regime; Opus surveyed 18 projects, two templates, the CLI book's search index and the 2024 survey, and searched four repositories for hatch usage. Opus's table is the practice evidence relied on above; Codex's two data points are consistent with it (star counts differ by 1–4 between retrieval dates, which is drift, not disagreement).
7. **Execution coverage.** Codex executed nothing; Opus executed on macOS stable only. This synthesis adds the 1.96.0 floor on both OS families and Linux stable, and adds P4 (live `unnecessary_safety_comment`), N3 (`#[expect]` rejected under `forbid`, matching Opus's check J) and the `cargo new` inheritance observation.

Residual uncertainty, stated: the forbid-versus-deny choice for a *template* rests on the judgement that most forks of a CLI + library + web-service template never write `unsafe`; no external authority ratifies that for templates specifically (the template layer sets nothing, the CLI book and the annual survey are silent), which is why the cost of being wrong was engineered to one token. The Linux evidence is aarch64, not the x86_64 of `ubuntu-latest`. Clippy behaviour on the 1.96.0 floor is inferred from the lints' availability since clippy 1.58/1.67/1.69 and from the table causing no diagnostic under `cargo check`/`cargo test` on 1.96.0, not from a clippy run on 1.96.0.
