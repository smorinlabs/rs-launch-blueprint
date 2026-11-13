# R28 — linter-and-editor-tooling (bundle) — Opus raw research report

Engine: `claude-opus-5-5` (Opus seat, CLI run 2026-09-26). Retrieval dates are UTC
2026-09-26 unless stated. Source repositories are read at the programme pins through
`git show <pin>:<path>`, never from the working tree: `py-launch-blueprint` at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. Every claim labelled **executed** was run
on this host on 2026-09-26; everything else is labelled **proposed**, **read** or
**carried** (carried = taken from an accepted in-repo decision, cited by path).

Host for every executed check: macOS 26.4 `arm64`. Two Rust toolchains exist on this
host and every executed command names which one it used:

| Toolchain | Path | Version |
|---|---|---|
| Homebrew (first on `PATH`) | `/opt/homebrew/bin/cargo`, `/opt/homebrew/bin/rustc` | rustc **1.98.1** (`48a229cea` 2026-09-01), clippy **0.1.98** |
| rustup `stable` (shadowed on `PATH`) | `~/.cargo/bin/cargo +stable` | rustc 1.94.0, clippy 0.1.94 |

1.98.1 is current stable: `GET https://api.github.com/repos/rust-lang/rust/releases/latest`
returned `tag_name` `1.98.1`, `published_at` 2026-09-03T13:14:07Z (S29). Under the fixed
`msrv-policy` the floor today is therefore **1.96**. The rustup toolchains 1.96.0 and
1.97.1 on this host carry no `clippy` component, and installing one is outside this
leg's permitted network, so **no clippy run at the floor was executed** (see gaps).
All scratch work lived in a directory created under `$TMPDIR`
(`r28-opus.VfJ3`); the only file written inside the repository is this report.

### Landscape

**Category decided.** The *static-lint layer* of a Rust workspace and its *editor
surface*: which tool lints Rust source, where its rule selection is declared, whether
autofix is a default, how test code is relaxed, what security-adjacent coverage the
linter itself contributes, and which VS Code extensions (lint/format, type-check,
debugger) plus which committed workspace settings a contributor receives.

**Three-bin map — linter tool.**

| Bin | Candidates found | Notes |
|---|---|---|
| Built-in / first-party toolchain | **`clippy`** (rustup component, `rust-lang/rust-clippy`); rustc's own lint set (`[lints.rust]`, e.g. `unsafe_code`, `unreachable_pub`) | clippy ships with rustup and is invoked as `cargo clippy` (S10, S15); rustc lints are configured through the same Cargo `[lints]` table (S13) |
| Established industry standard | none distinct from clippy | every surveyed project lints with clippy (S27); no second general-purpose Rust linter has comparable adoption |
| Up-and-comer / extension | `dylint` (Trail of Bits: custom lints as dynamic libraries), `marker` (`rust-marker/marker`: stable lint API experiment); structural search tools (`ast-grep`) are not Rust-semantic linters | both require **nightly** rustc internals (S24, S25) — see *Excluded by gate* |

**Three-bin map — editor surface (VS Code).**

| Bin | Candidates found |
|---|---|
| Built-in / first-party | **`rust-lang.rust-analyzer`** — the Rust project's LSP server and VS Code extension, "the recommended VS Code Rust extension by rust-lang.org" (S19); VS Code's own debugger UI (no Rust debug adapter is built into VS Code) |
| Established industry standard | **`vadimcn.vscode-lldb` (CodeLLDB)** — Rust-aware LLDB adapter recommended by VS Code docs for macOS/Linux (S19) and by rust-analyzer's own `.vscode/extensions.json` (S27); `ms-vscode.cpptools` — Microsoft C/C++ adapter, recommended by VS Code docs for Windows (S19) |
| Up-and-comer | **`llvm-vs-code-extensions.lldb-dap` (LLDB DAP)** — the LLVM project's official DAP extension; rust-analyzer's `debug.engine: "auto"` now tries it **first** (S18); `webfreak.debug` (Native Debug) is a long-tail option in the same enum |

**Authoritative sources used and why each counts.**

| Source | Why authoritative |
|---|---|
| Clippy Book — usage, configuration, lint configuration (S10–S12) | the clippy team's own documentation, versioned with the tool |
| Cargo Book — `[lints]` section, `cargo fix` (S13, S14) | the Cargo team's reference for manifest semantics |
| `cargo clippy --help` on clippy 0.1.98 (S15, executed) | the shipped binary's own contract for `--fix` |
| rust-analyzer book + `editors/code/package.json` at `86493cee` (S16–S18) | the maintainers' manual and the extension's machine-readable settings schema |
| VS Code "Rust in Visual Studio Code" (S19, page date 2026-09-16) | Microsoft's editor documentation; names the recommended extensions per OS |
| CodeLLDB `MANUAL.md`, `README.md`, `CHANGELOG.md` at `62def434` (S20) | the adapter maintainer's own documentation |
| 2025 State of Rust Survey (S21, published 2026-03-02) | the Rust project's annual survey; 7,967 responses on the editor question |
| Accepted in-repo decisions R06, R11, R16, R42 (S28) | binding programme decisions this bundle must compose with |

**Well-regarded projects surveyed (practice evidence), each read at a pinned commit (S27).**

| Project @ commit | Why well regarded (GitHub `stargazers_count`, 2026-09-26) | Lint shape observed |
|---|---|---|
| `astral-sh/uv` @ `136ef973` | 90,201 stars; widely adopted Python package manager written in Rust | `[workspace.lints.rust]` + `[workspace.lints.clippy]` with `pedantic = { level = "warn", priority = -2 }`, an allow-list, and restriction picks (`print_stdout`, `dbg_macro`, `exit`, `get_unwrap`) (`Cargo.toml:413-442`); `clippy.toml` holds `doc-valid-idents` |
| `zed-industries/zed` @ `bda9c0bd` | 90,933 stars; new, popular Rust editor | `[workspace.lints.clippy]` with `dbg_macro`/`todo` at `deny`, `style` allowed (`Cargo.toml:1126-1146`); `clippy.toml` bans `std::process::Command::*` methods via `disallowed-methods` |
| `astral-sh/ruff` @ `51f3437d` | 49,804 stars | same `pedantic` + allow-list shape as uv (`Cargo.toml:270-291`); commits `.vscode/extensions.json` = `["rust-lang.rust-analyzer"]` and `.vscode/settings.json` with `"rust-analyzer.check.command": "clippy"` |
| `bevyengine/bevy` @ `0f38358f` | 48,401 stars | named lints only, incl. `undocumented_unsafe_blocks`, `allow_attributes` (`Cargo.toml:52-81`); `clippy.toml` `disallowed-methods` for determinism |
| `tokio-rs/tokio` @ `facc6fc4` | 33,246 stars; the async runtime R69 builds on | `[workspace.lints.rust]` only (`unexpected_cfgs`) |
| `tokio-rs/axum` @ `bc8d4912` | 27,259 stars; web framework family of this template's web service | `[workspace.lints.rust] unsafe_code = "forbid"` + ~30 named clippy lints (`Cargo.toml:8-37`); `.clippy.toml` `disallowed-types` |
| `rust-lang/rust-analyzer` @ `86493cee` | 16,877 stars; Rust project | every group set explicitly at `priority = -1`, `correctness`/`perf` at `deny` (`Cargo.toml:182-189`); `clippy.toml` `disallowed-methods`; `.vscode/extensions.json` = `["vadimcn.vscode-lldb"]` |
| `rust-lang/cargo` @ `07b80494` | 15,521 stars; Rust project | `all = { level = "allow", priority = -2 }` then selective re-enables (`Cargo.toml:136-144`); `clippy.toml` sets **`allow-print-in-tests = true`, `allow-dbg-in-tests = true`** plus `disallowed-methods`/`disallowed-types` |
| `BurntSushi/ripgrep` @ `3fce3b5b` | 68,628 stars | no `[lints]` table and no `clippy.toml` — lints at defaults |

Editor-share evidence (S21, chart `what-ide-do-you-use.png`, read visually): in 2025,
VS Code 51.6 %, vi/vim/neovim 29.4 %, Zed 18.6 %, RustRover 14.4 %, Helix 12.7 % of
respondents (multiple answers). Every one of those except RustRover consumes
rust-analyzer as its Rust language server, so rust-analyzer is the dominant Rust
language service regardless of editor; VS Code is still the single largest editor.

### Principles and implementation

**Shared requirement and its source.** `docs/port/DIVERGENCE-ANALYSIS.md:117-122`
records R28 as class B (different tools, same intent). The principle both source
repos preserve is:

> *One dedicated, fast linter, configured in one committed, reviewable place, run
> identically from the Justfile, the pre-commit hook and CI; relaxations are explicit
> and scoped; security-adjacent rules are part of the lint gate and gaps are layered,
> not ignored; the editor shows the same diagnostics the gate enforces with the least
> number of extensions.*

**Agreement level.** *Policy and architectural pattern*, not tool: the three surfaces,
the single config location, explicit relaxation, and editor/gate parity must agree
across py, ts and rs. Tool names, config syntax and rule codes vary by ecosystem.

**Essential behaviors and observable acceptance criteria.**

| # | Behavior | Observable acceptance criterion | Status |
|---|---|---|---|
| A1 | One linter, one config location | lint levels exist only in root `Cargo.toml` `[workspace.lints.*]`; lint *values* only in root `clippy.toml`; members carry only `[lints] workspace = true` | **executed** in scratch (E2) |
| A2 | Gate fails on any lint | `cargo clippy --workspace --all-targets --locked -- -D warnings` exits 101 on a `dbg!`/`todo!` in shipped code and 0 on the clean fixture | **executed** (E2, E4) |
| A3 | Gate surfaces never mutate source | `just lint`, the lefthook job and CI run clippy without `--fix`; `--fix` exists only in an explicit `lint-fix` recipe | **executed** in part: dirty-tree `--fix` refusal observed (E5a); clean-tree fix application **not executed** (host blocks loopback bind) |
| A4 | Test relaxation is explicit and scoped | `.unwrap()` passes in `#[cfg(test)]` modules and `#[test]` fns, still fails in shipped code, and fails in an integration-test helper until a reasoned crate-level `#![allow(…, reason = …)]` is added | **executed** (E3a–E3c3) |
| A5 | Security-adjacent coverage is in the gate, gap layered | `unsafe_code = "forbid"` (R06) + clippy default `correctness`/`suspicious` groups + named restriction picks + CodeQL `security-extended` for Rust (R16) | **executed** for the clippy table (E2); CodeQL **carried** from R16 |
| A6 | Editor shows the gate's diagnostics | VS Code with only `rust-lang.rust-analyzer` shows clippy diagnostics on save when `rust-analyzer.check.command` is `clippy` | **proposed** (no VS Code on this host) |
| A7 | Debugger plugs into the inherited `launch.json` pattern (F194) | a committed `.vscode/launch.json` with `"type": "lldb"` entries launches the CLI binary under CodeLLDB on ubuntu-latest and macos-latest | **proposed** |

**What must agree vs what may vary.**

| Aspect | Must agree across py/ts/rs | Justified Rust difference |
|---|---|---|
| Three invocation surfaces | yes (Justfile, lefthook, CI) | invocation syntax is R42's (`cargo clippy`) |
| Config in one committed place | yes | Rust splits *levels* (`Cargo.toml`) from *values* (`clippy.toml`) because clippy itself refuses levels in `clippy.toml` (S11) — two files, one owner each, no overlap |
| Rule selection by group + named rules | yes (py `lint.select` codes, ts `categories`+`rules`) | clippy groups are coarser than ruff's plugin codes; the Rust idiom is *keep default groups, add named lints* (uv/ruff add `pedantic`) |
| Autofix default | should agree on "gates never mutate" | py deviates today — see `BASELINE-REVIEW` below |
| Test relaxation by path glob | agree on *explicit and scoped*; mechanism may vary | Rust has no per-path lint table in Cargo (S13, E6); `#[cfg(test)]`-awareness in clippy (S12) covers unit tests without globs; integration-test crates take a crate-level attribute |
| Bandit-class security rules | agree on *layering the gap* | no clippy security group exists; memory-safety classes bandit cannot see are closed by the compiler plus `unsafe_code = "forbid"`; injection-class dataflow is CodeQL's (R16) |
| Type-checker extension | py needs Pylance; ts needs none | Rust matches ts: rust-analyzer *is* the language service |
| Language-service version pin (F196) | agree on *editor and CI use the same engine* | rust-analyzer's server is bundled with the extension (S17) and cannot be pinned by a workspace file; compiler/clippy parity comes from R42's committed `rust-toolchain.toml` (S28) |

**Architectural alternatives compared before tools.**

| Alternative | Description | Verdict |
|---|---|---|
| **P1 — manifest lint table + value file** (recommended) | levels in `[workspace.lints.clippy]`/`[workspace.lints.rust]`, inherited by `[lints] workspace = true`; values in `clippy.toml`; CI adds `-D warnings` | Cargo-native since 1.74 (S13), below the 1.96 floor; already the shape R06 fixed (S28); used by uv, ruff, zed, bevy, axum, cargo, rust-analyzer (S27) |
| P2 — source attributes | `#![warn(clippy::…)]` in every crate root | duplicated per crate; R06 explicitly rejected attributes for `unsafe_code` for the same reason (S28); none of the surveyed projects uses it as the primary mechanism |
| P3 — command-line flags | `cargo clippy -- -W clippy::pedantic …` in the Justfile/CI | invisible to rust-analyzer unless duplicated into `check.extraArgs`; the editor and the gate diverge |
| P4 — `.cargo/config.toml` `RUSTFLAGS`/`[target] rustflags` | lints as rustflags | invalidates the build cache when flags change and applies to dependencies' compile units; rust-analyzer notes it must mirror RUSTFLAGS in CI manually (`rust-analyzer/Cargo.toml:169`, S27) |

**How the recommended design preserves each principle.** A1 and the "one place" rule
hold because Cargo *forbids* mixing `workspace = true` with member-local keys (E6,
executed: `cannot override workspace.lints in lints`), so drift into members is
structurally impossible. A2's gate is the R11 `check` job's clippy steps plus the
Justfile `lint` recipe. A3 follows ts's check-only policy. A4 uses clippy's own
`cfg(test)` awareness. A5 layers compiler, clippy and CodeQL. A6/A7 reduce the
contributor's install to two Rust extensions.

**Minimal realistic example (executed, scratch workspace, Homebrew clippy 0.1.98).**

Root `Cargo.toml` (lint part; R06's three entries are carried verbatim):

```toml
[workspace.package]
edition = "2024"
rust-version = "1.96"          # illustrative floor under msrv-policy on 2026-09-26
license = "MIT OR Apache-2.0"

[workspace.lints.rust]
unsafe_code = "forbid"         # R06

[workspace.lints.clippy]
# Default groups (correctness=deny; suspicious, style, complexity, perf=warn) are
# kept as shipped. Any group line added later MUST carry priority = -1.
# R06 (unsafe-code-policy) entries.
undocumented_unsafe_blocks    = "deny"
multiple_unsafe_ops_per_block = "deny"
unnecessary_safety_comment    = "deny"
# Curated restriction-group picks.
allow_attributes_without_reason = "warn"
dbg_macro     = "warn"
todo          = "warn"
unimplemented = "warn"
unwrap_used   = "warn"
```

Root `clippy.toml`:

```toml
# Lint *values* only; lint *levels* live in Cargo.toml [workspace.lints.clippy].
allow-unwrap-in-tests = true
allow-dbg-in-tests    = true
```

Every member: `[lints]` / `workspace = true`. Integration-test crates that call
`.unwrap()` outside a `#[test]` fn carry, as their first line:

```rust
#![allow(clippy::unwrap_used, reason = "integration-test crate: a panic is the test failure")]
```

**Executed checks** (scratch: members `crates/core` lib + `crates/cli` bin; command
`/opt/homebrew/bin/cargo clippy --workspace --all-targets --locked -- -D warnings`
unless stated):

| ID | Setup | Observed |
|---|---|---|
| E1 | group line `all = "warn"` without `priority` next to named lints | `error: lint group \`all\` has the same priority (0) as a lint` (`clippy::lint_groups_priority`), exit 101 |
| E2 | fixture as above | `Finished`, exit 0; also exit 0 with `--all-features` |
| E3a/b | `.unwrap()` in `#[cfg(test)] mod` in `src/`, and in a `#[test]` fn in `tests/integration.rs`, with `allow-unwrap-in-tests = true` | no diagnostic |
| E3c | `.unwrap()` in a **non-test helper fn** in `tests/integration.rs` | `error: used \`unwrap()\` on a \`Result\` value` at `tests/integration.rs:5:5`, exit 101 |
| E3c1 | E3c + crate-level `#![allow(clippy::unwrap_used, reason = "…")]` | exit 0 |
| E3c2 | E3c + `#[cfg(test)]` on the helper | exit 0 |
| E3c3 | E3c + crate-level `#![allow(clippy::unwrap_used)]` **without** reason | `error: \`allow\` attribute without specifying a reason`, exit 101 |
| E4 | `dbg!(1); todo!()` in a `pub fn` in `src/lib.rs` | `error: the \`dbg!\` macro is intended as a debugging tool`; `error: \`todo\` should not be present in production code`; exit 101 |
| E5a | `cargo clippy --fix --workspace --locked` with two uncommitted files (scratch `git init`) | `error: the working directory of this package has uncommitted changes, and \`cargo fix\` can potentially perform destructive changes; if you'd like to suppress this error pass \`--allow-dirty\`…`, exit 101 |
| E5b | same on a clean tree | **not executed**: `error: failed to bind TCP listener to manage locking … Operation not permitted (os error 1)`; a Python loopback `bind` fails identically, so the host sandbox, not clippy, blocked it |
| E6 | member `[lints] workspace = true` plus `[lints.clippy] unwrap_used = "allow"` | `cannot override \`workspace.lints\` in \`lints\`, either remove the overrides or \`lints.workspace = true\` and manually specify the lints`, exit 101 |
| E7 | `#![expect(clippy::unwrap_used, reason = "…")]` in a test crate with no unwrap | `error: this lint expectation is unfulfilled`, exit 101 |
| E8a/b | `x < 0` on `u32` (`clippy::absurd_extreme_comparisons`, correctness group) with/without `all = { level = "warn", priority = -1 }` | with the `all` line: **`warning`**; without it: **`error`** (`#[deny(…)] on by default`) — setting `all = "warn"` silently **downgrades** the deny-by-default correctness group |
| E9 | `cargo test --workspace --locked` on the fixture | 2 tests pass, exit 0 |
| E10 | py precedent: `ruff 0.15.15` (mise install) on a scratch `pyproject.toml` with `fix = true`, `select = ["F"]` and `import os` | `Found 1 error (1 fixed, 0 remaining).`, **exit 0**, file rewritten; `--no-fix` → exit 1 |

BASELINE-REVIEW: F093 — gate surfaces must be read-only, because a check that silently fixes can pass on violations — py should keep autofix out of its gates: remove `fix = true` from `pyproject.toml` (or pass `--no-fix` in the CI step and the lefthook job) and add a separate `lint-fix` recipe, matching ts's `Justfile:127-131` and this bundle's Rust recommendation — evidence: py pin `pyproject.toml:177` sets `fix = true`; py CI `.github/workflows/ci.yml:90-91` runs `uv run --no-sync ruff check .` with no `--no-fix`; py `lefthook.yml:109-111` runs `ruff check … {staged_files}` with no `--no-fix` and the file has no `stage_fixed` key anywhere at the pin; executed E10 shows that with `fix = true` ruff rewrites the file and exits 0 when every violation is fixable, so py's CI job passes on fixable lint violations and its hook fixes the working copy while the staged, unfixed content is committed.

Affected: F093 (this item); py follow-on project only. The `stage_fixed` absence was
checked with `git show b08bccfb:lefthook.yml | grep -n -i stage_fixed` (no match). E10
used ruff 0.15.15, while py's `uv.lock:2232-2233` pins 0.15.21; the `fix` setting's
semantics are long-standing, but re-run E10 at 0.15.21 before acting.

**Coordination notes (not decisions).** R27 (formatter) — rust-analyzer formats with
the toolchain's `rustfmt` and therefore honours whatever `rustfmt.toml` R27 chooses;
clippy has no exclude list of its own (it lints Cargo targets, not a file glob), so
R27's F100 exclude scope has no clippy counterpart to align with. R30 (type-check) —
if R30's gate is `cargo check`/clippy, rust-analyzer's `check.command` already runs
the same command, so no extra extension is needed. R31 — standalone scanner adoption
is not decided here.

### Recommendation

**One stack:** `clippy` (the rustup component named in R42's `rust-toolchain.toml`,
invoked as `cargo clippy`) configured by **levels in the root `Cargo.toml`
`[workspace.lints.clippy]`/`[workspace.lints.rust]` tables** (extending R06's table;
default groups kept, five named restriction lints added) and **values in a root
`clippy.toml`** (`allow-unwrap-in-tests`, `allow-dbg-in-tests`); gates run
`cargo clippy --workspace --all-targets --locked -- -D warnings` **check-only**, with
autofix **opt-in** through a separate `lint-fix` recipe (`cargo clippy --fix
--workspace --all-targets`, no `--allow-dirty`); test relaxation through clippy's
`cfg(test)`-aware configuration plus a reasoned crate-level `#![allow]` in
integration-test crates that need it; security-adjacent coverage layered as
`unsafe_code = "forbid"` + clippy default groups + named picks, with CodeQL
`security-extended` (R16) covering injection-class dataflow; editor set
**`rust-lang.rust-analyzer`** (lint via clippy, format via rustfmt, type diagnostics)
and **`vadimcn.vscode-lldb`** (CodeLLDB, `"type": "lldb"` with Cargo integration);
**no version-pin settings file** — `.vscode/settings.json` carries exactly one key,
`"rust-analyzer.check.command": "clippy"`, as a lint-visibility (not version) setting.

### Members

#### clippy (linter tool)

##### Landscape
Built-in: clippy, distributed as a rustup component and invoked as `cargo clippy`
(S10, S15); rustc's own lints share Cargo's `[lints]` table (S13). Established: no
distinct second linter exists; all nine surveyed projects lint with clippy or
rustc defaults (S27). Up-and-comers: `dylint`, `marker` (both nightly-only, S24, S25).

##### Principles and implementation
Matches the source principle "one dedicated linter" (py `Justfile:224-228` `ruff check`;
ts `Justfile:120-123` `oxlint`). Unlike py/ts, the tool is not a choice among peers:
it ships with the compiler toolchain, versioned with rustc, so R42's
`rust-toolchain.toml` (`components = ["rustfmt", "clippy"]`, S28) pins it with no
extra provisioning.

##### Dominant choice
`clippy`. GitHub `rust-lang/rust-clippy`: 13,536 stars, `archived: false`,
`pushed_at` 2026-09-24T14:26:18Z (`GET https://api.github.com/repos/rust-lang/rust-clippy`);
open issues `total_count` 2,506 (`GET https://api.github.com/search/issues?q=repo:rust-lang/rust-clippy+is:issue+is:open`).
Issue responsiveness (10 most recently opened issues, 2026-09-21..26): 2 received an
OWNER/MEMBER/COLLABORATOR comment (median 0.15 days); 8 had none in that window — see
method notes: rust-lang triage uses labels and CONTRIBUTOR-associated members, so this
undercounts. Release: ships every six weeks with rustc (current stable 1.98.1,
2026-09-03, S29). Maintenance: `active`.

##### Qualified shortlist
Only clippy passes every gate. Crate figures: **inapplicable** — clippy is not
distributed through crates.io. The crates.io crate named `clippy` is a 2018 shim
(`max_stable_version` 0.0.302, `created_at` 2018-10-05; `recent_downloads` 96,298,
`downloads` 2,066,929 from `GET https://crates.io/api/v1/crates/clippy`) pointing at
the retired `rust-lang-nursery/rust-clippy` URL; its downloads are legacy tooling, not
adoption. Gates: (1) license — `MIT OR Apache-2.0` (repository `LICENSE-MIT`/
`LICENSE-APACHE` both present via `GET /repos/rust-lang/rust-clippy/contents/<file>`; GitHub reports Apache-2.0 as primary); (2) MSRV — versioned with
rustc, so the floor toolchain's own clippy is used; (3) RustSec —
`https://rustsec.org/packages/clippy.html` returns 404 (no advisories; the shim is
not what runs), `unsafe` posture inapplicable (a developer tool, not a dependency);
(4) platforms — every rustup tier-1 host incl. `ubuntu-latest`, `macos-latest`,
Windows; (5) no default features, no async runtime; (6) zero binary-size cost (never
linked); compile time ≈ `cargo check` plus lint passes.

##### Excluded by gate
`dylint` (`cargo-dylint` 6.1.0, 2026-09-23; `recent_downloads` 173,742; GitHub
`trailofbits/dylint` 672 stars): fails the **stable Rust** constraint — its driver and
example lint libraries pin `channel = "nightly"` / `"nightly-2026-08-20"` with
`components = ["llvm-tools-preview", "rustc-dev"]` (`driver/rust-toolchain.toml`,
`examples/general/rust-toolchain.toml` @ `8aeea4b0`, S24). `marker` (`marker_api`
0.5.0, 2023-12-28; GitHub `rust-marker/marker` 154 stars, `pushed_at`
2023-12-31): README says "Internally, Marker has to rely on nightly versions of
rustc" (S25) — fails stable; 33 months without a push is an investigation trigger,
not by itself a `dormant` verdict.

##### Up-and-comers
`dylint` is the credible extension path when a fork needs project-specific semantic
lints clippy lacks; it complements clippy rather than replacing it. Watch whether it
ever runs on stable.

##### Fit for this template
CLI, library and web service all compile under one workspace; one `cargo clippy
--workspace --all-targets` covers bins, lib, tests, examples and benches (the
`--all-targets` flag is what `--fix` also implies, S15).

##### Recommendation
Adopt clippy as the sole linter. Confirm the prompt's HIGH question: **clippy is
uncontested**; no alternative is worth more than naming.

##### Ranked runner-up
None as a replacement. As an *addition*, `dylint` — excluded while it needs nightly.

##### Tradeoffs
Clippy's rule catalogue is fixed by upstream; project-specific bans go through
`disallowed-methods`/`-types`/`-macros` (S12) rather than custom rules. New clippy
releases can add warn-by-default lints, so a toolchain bump can turn `-D warnings`
red — mitigated because R42/R27 pin the channel in `rust-toolchain.toml`.

##### Parameters
Consumes `package-manager-invocation` (R42) = invoke as `cargo clippy`; presence
tested via `rustup component list --installed`, never `command -v`.

##### Migration implications
No new file for the tool itself; `rust-toolchain.toml` (R42) lists `clippy`.

##### Validation strategy
Executed: `/opt/homebrew/bin/cargo clippy --version` → `clippy 0.1.98`; E2 passes.
Planned (P03): the R11 `check` job's clippy steps on both runners and the
`msrv-floor` job at the floor toolchain.

##### Confidence & re-verify trigger
High. Re-verify if a stable-channel alternative linter appears or dylint drops its
nightly requirement.

##### Sources
S10, S13, S15, S22 (crates.io), S23 (GitHub), S24, S25, S26, S27, S28 (R42), S29.

#### Rule selection: [workspace.lints.clippy] plus clippy.toml

##### Landscape
Built-in mechanisms: Cargo `[lints]`/`[workspace.lints]` (respected since 1.74, S13),
`clippy.toml` (values only, S11), source attributes, command-line `-W/-D`. Practice:
seven of nine surveyed projects use `[workspace.lints.clippy]` and all seven also
ship a `clippy.toml` (S27).

##### Principles and implementation
Analogue of py `lint.select` (`pyproject.toml:150-165`) and ts `categories` +
`plugins`/`rules` (`.oxlintrc.json:15-46`): groups ≈ categories, named lints ≈
rules. Clippy's split is enforced by the tool: "Lint levels cannot be set in
clippy.toml" (S11). So the answer to the HIGH question is **both together, each for
its own kind of setting**. Groups must use `priority = -1` (E1); do **not** write
`all = "warn"` — it downgrades the deny-by-default `correctness` group (E8a/b).

##### Dominant choice
`[workspace.lints.clippy]` + root `clippy.toml`, inherited through
`[lints] workspace = true` — the shape R06 already fixed (S28).

##### Qualified shortlist
(a) Defaults + named picks (recommended; axum, bevy, zed shape). (b) Defaults +
`pedantic = { level = "warn", priority = -1 }` + allow-list (uv, ruff shape: 15–16
pedantic lints allowed, S27). (c) All groups explicit (rust-analyzer shape). Crate
figures **inapplicable**: a Cargo/clippy configuration pattern, not a crate. Gates:
license n/a; MSRV — `[lints]` needs 1.74, `reason =` on `allow` needs 1.81 (the
`lint_reasons` stabilization, S31), both below the 1.96 floor; no advisories; platform
independent; no features; no binary cost.

##### Excluded by gate
Source attributes as the primary mechanism (P2) and `RUSTFLAGS` (P4): not gate
failures, but rejected on principle (two sources of truth; cache invalidation) — see
`### Principles and implementation`.

##### Up-and-comers
None; Cargo's `[lints]` table is the settled mechanism. Watch for per-target lint
tables in Cargo (not available today, E6/S13).

##### Fit for this template
The workspace has several members (R11's `crates/core`, `crates/web`, CLI), so the
workspace-level table gives one place for all of them.

##### Recommendation
Keep clippy's default groups; add `allow_attributes_without_reason`, `dbg_macro`,
`todo`, `unimplemented`, `unwrap_used` at `warn` beside R06's three `deny` entries;
CI and `just lint` add `-D warnings`. `clippy.toml` holds only values.

##### Ranked runner-up
Option (b), `pedantic` + allow-list: more coverage, used by two highly regarded
projects, but it needs a curated allow-list that a template's forks inherit as noise.

##### Tradeoffs
`warn` + `-D warnings` keeps local iteration unblocked while the gate is strict; the
cost is that rustc warnings (e.g. `dead_code`) also fail the gate (S10) — intended.

##### Parameters
None owned. Uses fixed `rust-edition = 2024`, `msrv-policy` (clippy reads
`rust-version` as its `msrv`, S12).

##### Migration implications
Root `Cargo.toml` gains the lint entries above; new root `clippy.toml`; each member
`Cargo.toml` has `[lints] workspace = true` (already required by R06).

##### Validation strategy
Executed E1, E2, E4, E6, E8. Planned: the same command at the 1.96 floor toolchain.

##### Confidence & re-verify trigger
High for the mechanism; medium for the exact five named lints. Re-verify when the
template's real code first runs under the table (P03).

##### Sources
S11, S12, S13, S27, S28 (R06), S30 (E1, E2, E4, E6, E8).

#### Autofix policy: cargo clippy --fix stays opt-in

##### Landscape
Built-in: `cargo clippy --fix` (implies `--no-deps` and `--all-targets`, S15),
built on `cargo fix`, which refuses a dirty working directory unless `--allow-dirty`
/`--allow-staged` is passed (S14, E5a). Source precedent split: py autofixes by
default (`pyproject.toml:177`); ts is check-only with `lint-fix` (`Justfile:127-131`).

##### Principles and implementation
The principle is "gate surfaces are read-only". A pre-commit hook always runs on a
dirty or staged tree, so clippy `--fix` there would refuse (E5a) or, with
`--allow-dirty`, rewrite whole crates rather than the staged files. In CI a fix
lands in a discarded runner and hides violations — exactly the py defect recorded
as `BASELINE-REVIEW: F093` (E10).

##### Dominant choice
Check-only gates, explicit fix recipe — the ts shape.

##### Qualified shortlist
(a) opt-in `lint-fix` recipe (recommended); (b) default-on fix in the local `lint`
recipe only. Crate figures **inapplicable** (a policy). Gates n/a beyond clippy's own.

##### Excluded by gate
Default-on fix in hook or CI: violates the read-only principle and conflicts with
cargo's own dirty-tree guard (E5a).

##### Up-and-comers
None.

##### Fit for this template
Contributors get one command to apply machine-applicable suggestions; the gate
never changes code behind their back.

##### Recommendation
`lint`: `cargo clippy --workspace --all-targets --locked -- -D warnings`.
`lint-fix`: `cargo clippy --fix --workspace --all-targets` (no `--allow-dirty`, so
cargo's VCS guard protects uncommitted work). Answer to the HIGH question: **opt-in**.

##### Ranked runner-up
(b) is rejected because a recipe named `lint` that mutates code surprises users
and differs from the hook and CI.

##### Tradeoffs
Requires one extra command; in exchange no gate can pass by silently fixing.

##### Parameters
Consumes `package-manager-invocation` (R42).

##### Migration implications
Justfile `lint` and `lint-fix` recipes; lefthook job without `--fix`.

##### Validation strategy
Executed E5a (dirty refusal). **Not executed:** E5b (clean-tree fix application)
because this host blocks loopback `bind`; planned for P03 on a normal host:
introduce `return x * 2;` (`clippy::needless_return`), commit, run `just lint-fix`,
expect the diff `-    return x * 2;` / `+    x * 2`.

##### Confidence & re-verify trigger
High. Re-verify if cargo changes `--fix`'s VCS guard.

##### Sources
S14, S15, S05, S02, S30 (E5a, E10).

#### Test-code lint relaxation

##### Landscape
Built-in: clippy `allow-*-in-tests` configuration keys ("Whether `unwrap` should be
allowed in test functions or `#[cfg(test)]`", S12); rustc lint attributes with
`reason`; `#[expect]` (errors when unfulfilled, E7). Cargo has **no** per-path or
per-target lint table (S13; E6 shows members cannot even override workspace lints).
Practice: `rust-lang/cargo`'s `clippy.toml` sets `allow-print-in-tests` and
`allow-dbg-in-tests` (S27).

##### Principles and implementation
py `per-file-ignores` `"tests/*"` (`pyproject.toml:193-200`) and ts `overrides`
(`.oxlintrc.json:52-68`) scope relaxations by glob. In Rust, clippy recognises test
context semantically (E3a/b), so no glob is needed for unit tests or `#[test]` fns.
The one gap is helper functions in `tests/*.rs` integration crates (E3c); a reasoned
crate-level `#![allow]` closes it per file (E3c1). Answer: Rust's model makes globs
**unnecessary**; the per-file equivalent is a first-line attribute.

##### Dominant choice
`clippy.toml` `allow-unwrap-in-tests = true` and `allow-dbg-in-tests = true`.

##### Qualified shortlist
(a) config keys + crate-level `#![allow(…, reason)]` where needed (recommended);
(b) `#[cfg(test)]` on integration-test helpers (E3c2, works but reads oddly in a
crate that is test-only by construction); (c) `#![expect]` — fails when the lint
stops firing (E7), making routine refactors break the gate. Crate figures
**inapplicable** (pattern).

##### Excluded by gate
A path-scoped `[lints]` table: does not exist (S13, E6).

##### Up-and-comers
None.

##### Fit for this template
Web-service and CLI integration tests (`tests/`) commonly use helpers; the attribute
is one line per file and the `reason` is enforced by
`allow_attributes_without_reason` (E3c3).

##### Recommendation
Option (a). Prefer `allow` over `expect` for test-crate relaxations.

##### Ranked runner-up
Option (b).

##### Tradeoffs
Relaxation is per crate file rather than per directory glob; the upside is that each
relaxation is visible where it applies and carries its reason.

##### Parameters
None.

##### Migration implications
Root `clippy.toml`; first-line attribute in any `tests/*.rs` whose helpers unwrap.

##### Validation strategy
Executed E3a, E3b, E3c, E3c1, E3c2, E3c3, E7, E9.

##### Confidence & re-verify trigger
High. Re-verify if Cargo adds per-target lint tables.

##### Sources
S12, S13, S27, S30 (E3, E6, E7, E9), S02, S06.

#### Linter-level security coverage (layered)

##### Landscape
Built-in: rustc `unsafe_code` (R06: `forbid`); clippy `correctness` (deny) and
`suspicious` (warn) default groups; restriction lints such as `unwrap_used`,
`dbg_macro`; R06's `undocumented_unsafe_blocks` family; `disallowed-methods`/
`-types`/`-macros` ban lists (S12). Clippy has no security group and no bandit
analogue. Layered SAST: CodeQL for Rust, configured by R16 with `security-extended`
(S28).

##### Principles and implementation
py selects `"S"` (flake8-bandit, `pyproject.toml:161`) and relaxes `S101/S105/S106`
in tests; ts records that no bandit analogue exists and layers CodeQL (D-014(5);
`.oxlintrc.json:12-14,34-38`; `.github/workflows/codeql.yml` at the ts pin). Rust
follows the ts decision: many bandit classes are memory-safety or dynamic-evaluation
issues that safe Rust and `unsafe_code = "forbid"` already exclude; dataflow classes
(injection, path traversal, log injection) are CodeQL's.

##### Dominant choice
Compiler + clippy defaults + named picks, CodeQL layered.

##### Qualified shortlist
(a) as above (recommended); (b) additionally populate `disallowed-methods` with a
security ban list (zed bans `std::process::Command::*`, rust-analyzer bans
`Command::new`, S27 — both for architecture reasons, not security). Crate figures
**inapplicable**.

##### Excluded by gate
None evaluated here; any standalone AST scanner is R31's decision.

##### Up-and-comers
CodeQL's Rust pack is itself young: at `codeql-bundle-v2.26.4` the
`security-extended` delta over the default suite is two queries (R16, S28).

##### Fit for this template
The web service is where injection-class risk lives; CodeQL covers it. `unwrap_used`
matters for the web service, where a panic in a handler is a denial-of-service risk.

##### Recommendation
Option (a). The answer to the MEDIUM question: **yes**, a CI-level SAST workflow
(CodeQL per R16) covers the gap bandit filled for py; whether a standalone scanner
is also adopted is deferred to R31.

##### Ranked runner-up
Option (b) with an empty-by-default `disallowed-methods` list documented as the
fork's extension point.

##### Tradeoffs
No secret-string lint (bandit `S105/S106`); that class is secret scanning's (R17).

##### Parameters
None.

##### Migration implications
None beyond the lint table; CodeQL files are R16's.

##### Validation strategy
Executed E2/E4 (the named picks fire). CodeQL execution carried from R16.

##### Confidence & re-verify trigger
Medium-high. Re-verify if clippy adds a security group or CodeQL's Rust suite grows.

##### Sources
S12, S27, S28 (R06, R16), S02, S06, S08.

#### rust-lang.rust-analyzer (lint, format and type-check extension)

##### Landscape
Built-in/first-party: rust-analyzer (the deprecated `rust-lang.rust` extension is
superseded, S19). Alternatives outside VS Code: RustRover's own engine (14.4 % of 2025
survey respondents, S21). No separate clippy extension is needed.

##### Principles and implementation
Replaces py's `ms-python.vscode-pylance` + `charliermarsh.ruff` (`.vscode/extensions.json:4-5`
at py pin) and ts's `oxc.oxc-vscode` (`.vscode/extensions.json:3` at ts pin) with one
extension: formatting via rustfmt (`rust-analyzer.rustfmt.*`, S16), diagnostics from
`rust-analyzer.check.command` (default `"check"`; `"clippy"` runs clippy, S16, S18),
and type information from the language server itself — the ts pattern (F109: no
separate type-checker extension).

##### Dominant choice
`rust-lang.rust-analyzer`. GitHub `rust-lang/rust-analyzer`: 16,877 stars, not
archived, `pushed_at` 2026-09-26T10:35:50Z; open issues 1,696; weekly releases
(`2026-09-21`, `2026-09-14`, plus `nightly` 2026-09-26, from
`GET https://api.github.com/repos/rust-lang/rust-analyzer/releases`). Responsiveness
over the 10 newest issues: 1 OWNER/MEMBER/COLLABORATOR comment (1.56 days), 3 of the
unanswered are already closed — same undercount caveat as clippy. Maintenance: `active`.

##### Qualified shortlist
Only rust-analyzer. Crate figures **inapplicable** (distributed as a VS Code extension
with a bundled server binary, S17; the rustup `rust-analyzer` component exists but the
extension does not use it by default). Gates: (1) license MIT OR Apache-2.0 (the
`LICENSE-MIT` and `LICENSE-APACHE` both present via the GitHub contents API; GitHub reports Apache-2.0); (2) MSRV n/a (not a
dependency); (3) no RustSec entry (not a crate); (4) bundled binary for Linux, macOS,
Windows (S17); (5) n/a; (6) no binary cost.

##### Excluded by gate
None.

##### Up-and-comers
None within VS Code.

##### Fit for this template
Covers CLI, library and web-service crates in one workspace; `check.command =
"clippy"` makes the editor show the gate's lints.

##### Recommendation
Recommend `rust-lang.rust-analyzer` as the single lint/format/type-check extension.
Keep ts's cross-platform recommendations (`tamasfe.even-better-toml`,
`redhat.vscode-yaml`, `eamodio.gitlens`, `streetsidesoftware.code-spell-checker`,
`coderabbit.coderabbit-vscode`, `GitHub.vscode-pull-request-github`,
`GitHub.vscode-github-actions`, `Anthropic.claude-code`; ts `.vscode/extensions.json`).

##### Ranked runner-up
None.

##### Tradeoffs
Clippy-on-save is slower than `cargo check` on large workspaces (zed documents
disabling style lints partly for this reason, `Cargo.toml:1135-1146`, S27); for a
template-sized workspace this is acceptable.

##### Parameters
None.

##### Migration implications
`.vscode/extensions.json` lists rust-analyzer and CodeLLDB plus the eight shared
recommendations.

##### Validation strategy
Proposed (no VS Code here): open the template, confirm a `dbg!` in `src/` shows a
clippy diagnostic after save.

##### Confidence & re-verify trigger
High. Re-verify if the Rust project changes its recommended VS Code extension.

##### Sources
S16, S17, S18, S19, S21, S23, S27, S03, S07.

#### vadimcn.vscode-lldb (CodeLLDB debugger)

##### Landscape
Built-in: none in VS Code for native code. Established: CodeLLDB (VS Code docs'
macOS/Linux recommendation, S19; rust-analyzer's own recommended extension, S27);
`ms-vscode.cpptools` (Windows recommendation, S19). Up-and-comer: LLDB DAP, which
rust-analyzer's `debug.engine: "auto"` now tries first (S18).

##### Principles and implementation
F194 fixes the committed `launch.json` pattern (bare + with-args configs, py
`.vscode/launch.json:4-20`, ts `.vscode/launch.json:3-14`); only the tool changes.
CodeLLDB accepts `"cargo": ["run", …]` instead of `program` since 1.11.6 ("use
`cargo: [\"run\"]` instead of `cargo: [\"build\"]`", `CHANGELOG.md`, S20), so the
config names the Cargo target rather than a build path; it bundles its own LLDB and
loads Rust formatters with `"sourceLanguages": ["rust"]` (S20).

##### Dominant choice
CodeLLDB. GitHub `vadimcn/codelldb`: 3,309 stars, not archived, `pushed_at`
2026-08-23T22:32:49Z; open issues 166; latest release `v1.12.3` 2026-08-23 (previous
`v1.12.2` 2026-04-21). Responsiveness: 0 of the 10 newest issues (2026-06-24..09-17)
have an owner comment. Maintenance: `active` (release within 6 months), with a
concentration signal: `vadimcn` 1,390 commits vs 8 for the next contributor.

##### Qualified shortlist
(a) CodeLLDB; (b) LLDB DAP (GitHub `llvm/llvm-project`: 40,742 stars, not archived).
Crate figures **inapplicable** (VS Code extensions). Gates: (1) CodeLLDB MIT; LLDB DAP
Apache-2.0 WITH LLVM-exception (LLVM licence); (2)/(3) n/a; (4) CodeLLDB: "Linux with
glibc 2.18+ for x86_64, aarch64 or armhf; MacOS 10.12+ for x86_64 and 11.0+ for arm64;
Windows 10 and 11 for x86_64" (README, S20) — both target OSes; LLDB DAP needs a
system `lldb-dap` (Xcode on macOS; an LLVM package on Linux) — **unverified** here;
(5) n/a; (6) extension download only.

##### Excluded by gate
`ms-vscode.cpptools`: not excluded by gate, but its VS Code recommendation is for
Windows, which `target-os-matrix` does not include.

##### Up-and-comers
LLDB DAP: official LLVM, preferred by rust-analyzer's `auto` order; lacks CodeLLDB's
`cargo` launch property (a `preLaunchTask` build is needed) — **unverified detail**.

##### Fit for this template
One extension works on both target OSes with no system debugger install, and its
`cargo` property fits a multi-binary workspace.

##### Recommendation
`vadimcn.vscode-lldb`. **Proposed** `launch.json` (target names are placeholders
owned by other items):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CLI: Launch",
      "type": "lldb",
      "request": "launch",
      "cargo": { "args": ["run", "--package", "<cli-package>", "--bin", "<cli-bin>"] },
      "cwd": "${workspaceFolder}",
      "sourceLanguages": ["rust"]
    },
    {
      "name": "CLI: Launch (With Args)",
      "type": "lldb",
      "request": "launch",
      "cargo": { "args": ["run", "--package", "<cli-package>", "--bin", "<cli-bin>"] },
      "args": ["--help"],
      "cwd": "${workspaceFolder}",
      "sourceLanguages": ["rust"]
    }
  ]
}
```

##### Ranked runner-up
LLDB DAP.

##### Tradeoffs
Single-maintainer concentration and slow issue response (above) are the risk; the
fallback (LLDB DAP) uses the same LLDB engine, so a migration changes `"type"` and
the build step, not the pattern.

##### Parameters
None.

##### Migration implications
`.vscode/launch.json` (pattern per F194) with `"type": "lldb"`;
`vadimcn.vscode-lldb` in `extensions.json`.

##### Validation strategy
Proposed: on ubuntu-latest and macos-latest desktops, start each configuration and
hit a breakpoint in `main`. Executed: the JSON above was extracted and parsed with
`python3 -m json.tool` (parses); it was not executed in VS Code.

##### Confidence & re-verify trigger
Medium-high. Re-verify if CodeLLDB goes 6+ months without a release or VS Code docs
change their recommendation.

##### Sources
S18, S19, S20, S23, S27, S03, S07.

#### .vscode/settings.json (no version pin; one lint-visibility key)

##### Landscape
ts pins its language service with `"typescript.tsdk": "node_modules/typescript/lib"`
(`.vscode/settings.json:2` at ts pin; D-032); py has no `settings.json` (absent at
py pin). Rust options: no file; a server pin via `rust-analyzer.server.path`; a
lint-visibility key `rust-analyzer.check.command` (ruff commits exactly this, S27).

##### Principles and implementation
D-032's principle is "the editor and CI use the same engine". In Rust, compiler and
clippy parity comes from R42's committed `rust-toolchain.toml` (rustup honours it;
R42's executed check shows `rustup show active-toolchain` naming the file, S28),
because rust-analyzer runs `cargo` through the rustup proxy. The rust-analyzer
**server** itself is the extension's bundled binary ("points to bundled binary by
default", S18) and is not pinned by any workspace file; a `server.path` pin would be
a machine-specific path. So **F196 collapses to "no version pin needed"**.

##### Dominant choice
No version pin.

##### Qualified shortlist
(a) one-key `settings.json` with `"rust-analyzer.check.command": "clippy"`
(recommended); (b) no `settings.json` (py's principle); (c) pin the server with
`rust-analyzer.server.path`. Crate figures **inapplicable**.

##### Excluded by gate
(c): a machine-local path cannot be committed portably across ubuntu and macOS.

##### Up-and-comers
None.

##### Fit for this template
Without (a), the editor shows `cargo check` diagnostics while the gate runs clippy,
so contributors first see clippy failures in the hook or CI.

##### Recommendation
Option (a). This is a **departure** from the source's no-`settings.json` principle
and is *not* covered by D-032 (it is a lint-visibility key, not a version pin).
**Argument:** it applies D-032's engine-parity reason to lint diagnostics.
**Options:** (a) ship the key; (b) ship no file and document the setting in
CONTRIBUTING. Record as an override if the synthesizer accepts it.

##### Ranked runner-up
Option (b).

##### Tradeoffs
Slower on-save checks; one more committed editor file.

##### Parameters
None.

##### Migration implications
New `.vscode/settings.json` = `{ "rust-analyzer.check.command": "clippy" }`.

##### Validation strategy
Proposed: as for rust-analyzer. Carried: R42's toolchain-file check.

##### Confidence & re-verify trigger
High on "no version pin"; medium on shipping the key (owner judgement). Re-verify if
rust-analyzer starts using the toolchain's server component by default.

##### Sources
S16, S17, S18, S27, S28 (R42), S07.

### Compatibility

The members are tested together in production by `astral-sh/ruff` @ `51f3437d`:
`[workspace.lints.clippy]` (`Cargo.toml:270-291`) + `clippy.toml` +
`.vscode/extensions.json` = `["rust-lang.rust-analyzer"]` + `.vscode/settings.json`
with `"rust-analyzer.check.command": "clippy"` (S27). `rust-lang/rust-analyzer` @
`86493cee` pairs `[workspace.lints.clippy]` + `clippy.toml` with a recommendation of
`vadimcn.vscode-lldb` (S27). R06's workspace lint table composes with this bundle's
additions in one table (executed E2 with all eight entries). Version matrix: `[lints]`
≥ 1.74; `reason =` ≥ 1.81; both below the 1.96 floor; executed on clippy 0.1.98;
floor run not executed.

### Parameters

- owns: none (R28 registers no parameter).
- assumes `package-manager-invocation` = invoke `cargo clippy` / `cargo fmt` as `cargo <sub>`, no runner prefix, presence tested via `rustup component list --installed` (R42).
- assumes `ci-job-structure` = one `ci.yml`; clippy runs as ordered steps (feature off, feature on) of the per-OS `check` job with `--locked` and `-D warnings` (R11).
- assumes fixed `rust-edition` = `2024`; `msrv-policy` = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `license` = `MIT OR Apache-2.0`; `target-os-matrix` = `ubuntu-latest, macos-latest`.
- No `CONFLICT:` lines.

### Migration implications

| File | Change |
|---|---|
| root `Cargo.toml` | extend R06's `[workspace.lints.clippy]` with the five named lints; no group lines |
| every member `Cargo.toml` | `[lints] workspace = true` (already R06) |
| `clippy.toml` (new, root) | `allow-unwrap-in-tests = true`, `allow-dbg-in-tests = true` |
| `tests/*.rs` with unwrapping helpers | first line `#![allow(clippy::unwrap_used, reason = "…")]` |
| `Justfile` | `lint`: `cargo clippy --workspace --all-targets --locked -- -D warnings`; `lint-fix`: `cargo clippy --fix --workspace --all-targets` |
| `lefthook.yml` | clippy job, check-only (syntax per R42) |
| `.vscode/extensions.json` | `rust-lang.rust-analyzer`, `vadimcn.vscode-lldb` + eight shared |
| `.vscode/launch.json` | `"type": "lldb"` configs per F194 |
| `.vscode/settings.json` | one key: `"rust-analyzer.check.command": "clippy"` |

### Validation strategy

Executed (this run, Homebrew toolchain 1.98.1, scratch workspace): E1–E9 as tabled in
`### Principles and implementation`, all with the stated exit codes; E10 against ruff
0.15.15. Planned for P03: (1) the recommended table at the floor toolchain
(`cargo +1.96 clippy --workspace --all-targets --locked -- -D warnings`, expect exit 0
on clean code); (2) E5b on a host that permits loopback bind; (3) CI `check` job on
ubuntu-latest and macos-latest; (4) VS Code smoke: clippy diagnostic on save and a
breakpoint hit through CodeLLDB on both OSes; (5) re-run E10 at ruff 0.15.21 for the
py follow-on.

### Confidence & re-verify trigger

Overall high for clippy, the lint-table split, opt-in fix and rust-analyzer; medium
for the named-lint list, the one-key settings file and the CodeLLDB-vs-LLDB-DAP
ranking. Re-verify on: a clippy release changing group defaults; Cargo adding
per-target lint tables; CodeLLDB going six months without a release; rust-analyzer
changing its default debug engine or server source; re-verify date 2027-03-26.

### Sources

All retrieved 2026-09-26 unless stated.

- S01 py `Justfile:224-228` @ `b08bccfb` (`git show`).
- S02 py `pyproject.toml:150-200` @ `b08bccfb`; `uv.lock:2232-2233` (ruff 0.15.21).
- S03 py `.vscode/extensions.json`, `.vscode/launch.json` @ `b08bccfb`; `.vscode/settings.json` absent.
- S04 py `lefthook.yml:103-114`, `.github/workflows/ci.yml:77-93` @ `b08bccfb`.
- S05 ts `Justfile:118-131` @ `cb1cbcb2`; `package.json:56` (`"oxlint": "^1.74.0"`).
- S06 ts `.oxlintrc.json:1-70` @ `cb1cbcb2`.
- S07 ts `.vscode/extensions.json`, `.vscode/settings.json:2`, `.vscode/launch.json` @ `cb1cbcb2`.
- S08 ts `lefthook.yml:49-57`, `.github/workflows/ci.yml:88-89`, `.github/workflows/codeql.yml` @ `cb1cbcb2`.
- S10 https://doc.rust-lang.org/clippy/usage.html
- S11 https://doc.rust-lang.org/clippy/configuration.html
- S12 https://doc.rust-lang.org/clippy/lint_configuration.html
- S13 https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section
- S14 https://doc.rust-lang.org/cargo/commands/cargo-fix.html
- S15 `/opt/homebrew/bin/cargo clippy --help` (clippy 0.1.98), executed.
- S16 https://rust-analyzer.github.io/book/configuration.html
- S17 https://rust-analyzer.github.io/book/vs_code.html
- S18 https://github.com/rust-lang/rust-analyzer/blob/86493cee4d8902389c3217d8e95a3aae9368fd98/editors/code/package.json (via `GET https://api.github.com/repos/rust-lang/rust-analyzer/contents/editors/code/package.json?ref=86493cee…`)
- S19 https://code.visualstudio.com/docs/languages/rust (page date 2026-09-16)
- S20 https://github.com/vadimcn/codelldb/blob/62def434dc22c1d77d4837c4d99cddef7ac3338f/MANUAL.md , `README.md`, `CHANGELOG.md` at the same commit (raw.githubusercontent.com).
- S21 https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/ and its `what-ide-do-you-use.png` / `.svg`.
- S22 `GET https://crates.io/api/v1/crates/<name>` and `/versions` for `clippy`, `cargo-dylint`, `dylint_linting`, `marker_api`, `cargo-marker` (fields `crate.recent_downloads`, `crate.downloads`, newest non-yanked `num`/`created_at`).
- S23 `GET https://api.github.com/repos/<o>/<r>` and `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for `rust-lang/rust-clippy`, `rust-lang/rust-analyzer`, `vadimcn/codelldb`, `trailofbits/dylint`, `rust-marker/marker`, `microsoft/vscode-cpptools` (6,166 stars; 1,388 open issues), `llvm/llvm-project`; `/releases`, `/commits`, `/contributors` for codelldb and rust-analyzer; issue comments for responsiveness.
- S24 `trailofbits/dylint` @ `8aeea4b0c27722d46fcc8288330401418328e8fa`: `driver/rust-toolchain.toml`, `examples/general/rust-toolchain.toml`, `README.md`.
- S25 https://github.com/rust-marker/marker (README).
- S26 https://rustsec.org/packages/clippy.html , `/cargo-dylint.html` , `/dylint_linting.html` — all HTTP 404 (no advisories recorded).
- S27 project files via GitHub contents API at: `astral-sh/uv@136ef97330781a0f5f2be6613aac4382ebbcecea`, `tokio-rs/axum@bc8d4912435204a4a073cea70355ae0328d263fe`, `bevyengine/bevy@0f38358f573a7dc6ea961076f6151be662142010`, `rust-lang/rust-analyzer@86493cee4d8902389c3217d8e95a3aae9368fd98`, `rust-lang/cargo@07b80494920f3824e2515e536b76ff282e23993e`, `BurntSushi/ripgrep@3fce3b5bb0236da2df6d99672afb8a719642eca7`, `zed-industries/zed@bda9c0bd43a8d235d82adb01ea5bc875b861ecfc`, `tokio-rs/tokio@facc6fc47eb2ba13a465a3179f8e34db620561ec`, `astral-sh/ruff@51f3437d0344b1909007acf42fe6b124369f8439` (`Cargo.toml`, `clippy.toml`/`.clippy.toml`, `.vscode/*`).
- S28 in-repo accepted decisions: `research/topics/06-unsafe-code-policy/DECISION.md`, `research/topics/16-codeql-config-customization/DECISION.md`, `research/topics/11-ci-workflow-job-structure/DECISION.md`, `research/topics/42-dev-toolchain-provisioning/DECISION.md`; `docs/port/DIVERGENCE-ANALYSIS.md:117-122`.
- S29 `GET https://api.github.com/repos/rust-lang/rust/releases/latest` → `1.98.1`, 2026-09-03.
- S30 executed scratch checks E1–E10 (this run).
- S31 https://blog.rust-lang.org/2024/09/05/Rust-1.81.0/ — "1.81 stabilizes a new lint level, `expect`" and the "Lint reasons" `reason =` field.

**Method notes.** Endpoints queried: crates.io API (crate and versions), GitHub REST
(repos, search/issues, issues + comments, releases, commits, contributors, contents,
git trees), raw.githubusercontent.com, rustsec.org package pages, and maintainers'
documentation (Clippy/Cargo books, rust-analyzer book, VS Code docs, Rust blog).
Issue responsiveness counted only comments with `author_association` OWNER, MEMBER or
COLLABORATOR from someone other than the issue author; rust-lang org members often
appear as CONTRIBUTOR and triage by labels or linked PRs, so the clippy and
rust-analyzer figures undercount and are not evidence of unresponsiveness.
Not verified: VS Code Marketplace install counts (not a named endpoint); percentage
figures for rust-analyzer usage beyond the editor chart; the rustup overrides page
(https://rust-lang.github.io/rustup/overrides.html timed out twice; toolchain-file
behaviour is carried from R42's executed check); `lldb-dap` availability on
ubuntu-latest; clean-tree `cargo clippy --fix` (E5b, host blocks loopback bind); any
clippy run at the 1.96 floor (no clippy component for 1.96/1.97 on this host and no
permitted install route); any VS Code execution of the proposed `.vscode` files.
Independence disclosure: an orientation `ls` of the run directory printed the file
name `raw/muse.md`; that file was not opened, read or searched, and no other engine's
report was consulted.
