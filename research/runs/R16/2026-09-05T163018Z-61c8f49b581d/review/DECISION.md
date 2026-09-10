# R16 codeql-config-customization — decision (revision 1, 2026-09-09)

Item R16 (`codeql-config-customization`, kind `pattern`, Focused tier, owns nothing). Run `research/runs/R16/2026-09-05T163018Z-61c8f49b581d`. Synthesizer: actor `synth-fable-2026-09-05T163018Z-61c8f49b581d`, model `claude-fable-5-1`, a fresh context that produced none of the raw reports. Inputs: `inputs/prompt.md`, `raw/codex.md`, `raw/opus.md`, `docs/port/PARAMETERS.md`; prerequisite decisions: none (`inputs/prerequisites.json` is empty). Assumption about open related items: the fixture is a Cargo workspace (a root package plus `crates/inner`) so that the decision holds whether R02/R49 settle on one package or several; R32 and R33 (test, bench and fuzz layout) are `open`, and the path list below is written to be inert for any directory that does not exist.

## Decision

**Ship a repository-local CodeQL configuration file, `.github/codeql/codeql-config.yml`, that selects the `security-extended` suite and excludes Cargo's non-shipped code directories at every workspace depth, referenced from the inherited CodeQL workflow's Init step through `config-file:` with no inline `queries:` input on that step.** Tool versions the decision was verified against: CodeQL CLI 2.26.4 (`codeql-bundle-v2.26.4`, the bundle pinned by `github/codeql-action` v4.37.9, published 2026-08-26), Rust query pack `codeql/rust-queries` 0.1.41. The file below is byte-identical to `review/empirical/fixture/.github/codeql/codeql-config.yml`, the file the empirical check executed.

```yaml
# rs-launch-blueprint CodeQL config (advanced setup; THIS file is the CodeQL config).
# NOTE: the repo's "default setup" (Settings > Code security > Code scanning)
# must stay DISABLED, or the workflow's SARIF upload fails with a configuration
# error. Applies to forks too.

name: "rs-launch-blueprint codeql"

# security-extended = the default code-scanning suite plus lower-precision
# security queries. At codeql-bundle-v2.26.4 the Rust delta is exactly
# rust/log-injection (CWE-117) and rust/access-after-lifetime-ended (CWE-825).
queries:
  - uses: security-extended

# Scan shipped code only. Cargo integration tests, benches and cargo-fuzz
# targets hold deliberately hostile inputs and unsafe fixtures; the `**/`
# prefix reaches them in every workspace member, not only at the root.
# This does NOT reach #[cfg(test)] unit tests inside src/ (the Rust extractor
# enables cfg(test) by default), and it deliberately keeps examples/ in scope
# (template users copy examples). docs/ and target/ are not listed: Markdown
# is never extracted, a .rs file under docs/ is copy-able example code (and is
# extracted), and target/ is git-ignored. An entry for an absent directory is
# inert.
paths-ignore:
  - "**/tests/**"
  - "**/benches/**"
  - "**/fuzz/**"
```

The workflow edit (the only change R16 makes to the F027-inherited file):

```yaml
      - name: Init CodeQL
        uses: github/codeql-action/init@v4.37.0
        with:
          languages: rust
          build-mode: none
          config-file: ./.github/codeql/codeql-config.yml
```

Integration reconciliation, not a parameter: when R32 (`test-harness-and-execution`) and R33 (`property-and-snapshot-testing`) settle the layout, confirm the three directory names still match what they chose. The empirical check ran with `**/fuzz/**` present and no `fuzz/` directory anywhere, so an entry for an absent directory is inert and harmless (`review/evidence/db-cfg-create-analyze.log`).

Ledger rows settled: **F045** (`docs/port/COMMONALITY.md:51`, `DIVERGENT`, py-only) — resolved as *policy adopted from py, values re-derived for Rust*: the `security-extended` selection transfers unchanged; the `paths-ignore` contents are Rust-specific (`**/tests/**`, `**/benches/**`, `**/fuzz/**`; py's `docs/**` is dropped). F027 is not changed by this decision; see the `BASELINE-REVIEW:` lines below.

### Principles and implementation

**Shared requirement.** The repository's CodeQL scan must be worth a maintainer's attention: broad enough to cover the vulnerability classes the codebase can exhibit, and pointed at code that ships. Source: py `.github/codeql/codeql-config.yml` at `b08bccf` (`queries: - uses: security-extended`; `paths-ignore: tests/**, docs/**`, with the comment "Scan shipped code only: test fixtures and docs config carry intentional patterns that are noise for a security scan"), referenced from py `.github/workflows/codeql.yml:63`; ts `.github/workflows/codeql.yml` at `cb1cbcb` has no `config-file:` and carries the upstream starter template's untouched commented-out `# queries: security-extended,security-and-quality` line, so ts's shape is an unexamined gap of D-022(4), not a considered rejection (both engines, read from the pinned local clones; opus 2026-09-09).

**Agreement level: policy, not low-level values.** The two levers py bundles into one file behave differently in Rust, so the literal paths cannot transfer; the policy — select the broader suite where it adds coverage, exclude non-shipped code where the exclusion actually reaches it, keep the selection in one reviewable artifact — transfers unchanged. Per the research mandate, a shared low-level value is recommended only on explicit owner requirement or same-tradeoff evidence in every ecosystem; that holds for `security-extended` (the suite selectors are language-independent: every `*-security-extended.qls` applies `misc/suite-helpers/security-extended-selectors.yml`, opus 2026-09-09; the selector file is byte-identical at `codeql-cli/v2.26.0` and `v2.26.4`, `evidence/doc-crosschecks.log`) and does not hold for the path list.

**Essential behaviors.**

- B1 — the scan runs every first-party Rust security query whose class the template can exhibit, including the two `security-extended` additions.
- B2 — alerts describe shipped code; Cargo integration tests, benches and fuzz targets are excluded in every workspace member; examples stay in scope.
- B3 — the selection lives in one reviewable, versioned file, and no workflow input silently overrides it.

**Observable acceptance criteria and their status.**

| Criterion | Check | Result |
|---|---|---|
| A1 — the configured suite adds `rust/log-injection` and `rust/access-after-lifetime-ended` over the default suite | `codeql resolve queries` on both `.qls` files, diffed | **Met.** Default 16 security queries, extended 18; delta exactly `CWE-117/LogInjection.ql` and `CWE-825/AccessAfterLifetime.ql` (`evidence/resolve-queries.log`) |
| A2 — a marker under an ignored path yields no alert at any workspace depth; the same marker under shipped code does | `codeql database create --codescanning-config=<file>` then `database analyze`, workspace fixture | **Met.** Without the config: 8 files scanned, 10 alerts. With it: 5 files scanned, 7 alerts — `tests/integration.rs`, `benches/bench.rs` and `crates/inner/tests/nested.rs` were not extracted; `src/lib.rs`, `crates/inner/src/lib.rs`, `examples/example.rs` and `docs/snippet.rs` kept their alerts (`evidence/db-bare-analyze.log`, `evidence/db-cfg-create-analyze.log`) |
| A3 — the Init step sets `config-file:` and no `queries:` | YAML parse of the fixture workflow | **Met.** `PASS` (`evidence/workflow-validation.log`); actionlint 1.7.12 exit 0 |
| A4 — the config's `queries` key is consumed without a query argument | `database analyze <db>` with no suite argument | **Met.** Both delta queries ran; 27 `rust/*` rules in the SARIF (`evidence/db-cfg-create-analyze.log`) |
| A5 — works at the MSRV floor | Same run at rustc 1.96.0 | **Met.** Identical 7 alerts; extractor archived `toolchains/1.96.0-aarch64-apple-darwin` sources (`evidence/db-cfg-msrv-1.96.0.log`) |

**What must agree versus what may vary across py, ts and rs.** Must agree: the policy (B1–B3) and the config-file mechanism. May vary: the `paths-ignore` list, because the layout that separates test code from shipped code is language-specific — py's `tests/**` exclusion is complete (all tests live there), Rust's is partial (unit tests live in `#[cfg(test)]` modules inside `src/`, and the extractor enables `cfg(test)` by default: `rust/extractor/src/config.rs` seeds `enabled_cfgs` with `test`, opus 2026-09-09; confirmed empirically — `src/lib.rs:47`, inside `#[cfg(test)] mod tests`, is reported with the config in force). The globs are `**/`-anchored because a Cargo workspace puts `tests/` and `benches/` under each member; py's root-anchored form would reach only the root package. Follow-on for the py/ts project (rationale only, not changed here): add `queries: security-extended` to ts's Init step; leave each repository's path list different by design.

**Architectural alternatives compared.**

| Alternative | Verdict | Why |
|---|---|---|
| Alt-A — bare defaults, no file (ts's shape) | rejected on the merits | Loses B1 (the two delta queries) and B2 entirely; cheapest; the fallback if the premises fail |
| Alt-B — inline `queries: security-extended`, no file | runner-up | Satisfies B1; cannot express `paths-ignore` (B2); carries the documented override hazard: `init/action.yml` v4.37.9 — "By default, this overrides the same setting in a configuration file; prefix with \"+\" to use both sets of queries" (retrieved 2026-09-09, `evidence/doc-crosschecks.log`) |
| **Alt-C — config file with `queries` + Rust-native `paths-ignore`** | **selected** | Satisfies B1, B2 and B3 in one artifact; both levers verified executing at CLI 2.26.4 on a workspace |
| Alt-D — `security-and-quality` | excluded | At 2.26.4 its delta over `security-extended` resolves to `rust/ctor-initialization` (CWE-696, `@tags reliability`) and `rust/unused-variable` (`@tags maintainability`, `@problem.severity recommendation`) — the latter duplicates `rustc`'s `unused_variables` lint in R28's lane, the former is a niche `#[ctor]` initialization-order check; neither justifies routing non-security findings to the Security tab (`evidence/resolve-queries.log`) |
| Alt-E — `security-experimental` | excluded | Resolves to exactly the `security-extended` set at 2.26.4 (diff empty) and would widen silently when experimental Rust queries land |
| Alt-F — extractor option `cargo_cfg_overrides=-test` | excluded | Would fully exclude unit tests, but `init/action.yml` v4.37.9 exposes no extractor-option input and no first-party page documents an environment-variable route (opus 2026-09-09); unverified delivery is not shipped in a template |
| Alt-G — inline `config:` YAML string | excluded | Functionally equivalent to Alt-C; buries a multi-key document inside a workflow step, defeating B3 |

**Why the selected design preserves each principle.** B1: the file names a suite, not queries, so upstream Rust query growth (e.g. `rust/command-line-injection` on `github/codeql@main`, opus 2026-09-09) arrives automatically. B2: `paths-ignore` is honoured for Rust at *extraction time* — with the config in force the source archive held 5 fixture files instead of 8 and CodeQL reported "scanned 5 out of 5 Rust files" — so ignored code is neither extracted nor analysed, and the `**/` prefix reached the nested member's `tests/`; GitHub Docs states the applicability: "You can use this option when you run the CodeQL actions on an interpreted language (Python, Ruby, and JavaScript/TypeScript) or when you analyze a compiled language without building the code (currently supported for C/C++, C#, Java and Rust)" (retrieved 2026-09-09). B3: `config-file:` is the only place both levers can be reviewed together, and the A3 guard is a one-line CI assertion. The default-setup NOTE at the top of the file is carried from py because advanced setup and GitHub's default setup are mutually exclusive and the failure mode (rejected SARIF upload) is invisible from the workflow file.

**Reference implementations.** `surrealdb/surrealdb` (`.github/codeql/codeql-config.yml`: `security-extended` plus `paths-ignore` over `**/tests/**`, `**/benches/**`, `fuzz/**`, `target/**`, `doc/**`, `pkg/**`; `build-mode: none`; 32,997 stars; opus 2026-09-09) is the maintained Rust reference for Alt-C and the origin of the `**/` form. `wasmCloud/wasmCloud` and `copper-project/copper-rs` practise Alt-B; `open-telemetry/opentelemetry-rust` practises Alt-A (opus 2026-09-09). `xelis-project/xelis-blockchain` practises Alt-B with `build-mode: none` (codex 2026-09-05). Practice caveat: 0 of 20 flagship Rust repositories probed by opus ship an advanced-setup CodeQL workflow at all; the population using CodeQL is small, so the mechanism evidence above outweighs the head-count.

**Fitness gates (pattern item; crate figures inapplicable, reasons recorded).** License: the artifact is a YAML file under the repository's own `MIT OR Apache-2.0`; `github/codeql` is MIT (`license.spdx_id`, opus 2026-09-09); CodeQL's own terms restrict where analysis may run, which F027's visibility gate encodes. MSRV: no crate added; the extractor requires stable `rustup` and `cargo` and "Features from nightly toolchains are not supported" (codeql.github.com supported languages, both engines) — verified executing at 1.96.0 and 1.98.0. Advisories / `unsafe`: no crate, no RustSec page; the file contains no code. OS matrix: the CodeQL job runs on `ubuntu-latest` alone in both source repositories; the YAML is OS-independent; the fixture builds and tests on macOS arm64 and Ubuntu aarch64 at both toolchains. Features / runtime: none. Binary size: none. Compile-time/CI cost: the extended suite adds two queries to sixteen; the dominant extraction cost observed locally was toolchain sources (5,831 standard-library `.rs` files archived versus 8 fixture files), which `paths-ignore` cannot touch — so the alert-volume reduction is proven and the wall-clock reduction is proportional only to the ignored user code.

**Fit per shape.** CLI: `rust/path-injection` (default suite) covers the canonical CLI class; `rust/log-injection` is the extended suite's CLI-shaped addition, but see the unverified note below. Library: `paths-ignore` reaches least here (unit tests are `#[cfg(test)]` in `src/`); `rust/access-after-lifetime-ended` (`@security-severity 9.8`) is the extended suite's detector for the pointer-lifetime class R06's `unsafe` policy governs, and it fired on the fixture in every placement including the nested crate. Web: the default suite's HTTP-shaped queries (`rust/request-forgery`, `rust/xss`, `rust/sql-injection`, `rust/insecure-cookie`, `rust/cleartext-transmission`) are active; the extended suite closes the CWE-117 logging gap on the request path *when the framework R69 selects has modeled remote sources* — GitHub lists `actix-web`, `clap`, `hyper`, `reqwest`, `sqlx`, `tokio` and `warp` as recognised libraries (codex 2026-09-05).

**Unverified value claim, recorded rather than asserted.** `rust/log-injection` did not fire on the qhelp-shaped fixture (`std::env::args()` → `log::info!`) under the default threat model nor with `--threat-model local` at 2.26.4 (`evidence/exploratory-threat-model-local.log`), while the default suite's `rust/cleartext-logging` fired on the same line. The CWE-117 half of the delta therefore depends on modeled sources and sinks in the template's real stack (R58/R59 logging, R69 web framework) and is not demonstrated here; the CWE-825 half is demonstrated.

**BASELINE-REVIEW lines carried from the raws (recorded; the ledger and `docs/port/BASELINE-REVIEW.md` are not changed by this decision — controller adjudication per RUNBOOK §4).**

- opus: `BASELINE-REVIEW: F027 — the CodeQL scan runs where the platform supports it, with a language and build-mode matrix that the implementation must state — resolve the open "CodeQL Rust language/build-mode matrix" question recorded in docs/port/BASELINE-REVIEW.md (B3) as languages: rust with build-mode: none, mechanically determined rather than an owner choice — rust/codeql-extractor.yml at tag codeql-cli/v2.26.4 declares build_modes: with the single value none (https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/codeql-extractor.yml, 2026-09-09), GitHub Docs lists Rust among the languages analyzed "without building the code", codeql-action v4.37.9 src/autobuild.ts treats BuildMode.None as "nothing to autobuild", and SurrealDB and copper-rs both run languages: rust with build-mode: none in production.`
- codex: `BASELINE-REVIEW: F027 — Rust analysis needs a CodeQL-supported language/build mode while preserving the runtime availability gate — do not describe the Python/TypeScript language/build-mode values as an inherited Rust matrix; R16 can choose the query policy, but any later paths-ignore proposal must first prove build-mode: none or change build steps — CodeQL Rust support and directory-filter rule, retrieved 2026-09-05.`

Synthesizer's finding on both: the bundle shipped to runners settles the question mechanically — `empirical/tools/codeql/rust/codeql-extractor.yml` in `codeql-bundle-v2.26.4` declares `build_modes:` with the single value `none` (`evidence/rust-extractor-yml.log`), and every database in this run was created with `--build-mode=none`. This supports resolving B3 as its option (b) (a mechanical implementation detail), which is what the recommended workflow snippet states. Codex's precondition for `paths-ignore` ("first prove `build-mode: none`") is thereby met by primary evidence. This decision is conditional on that resolution; if the controller instead records the matrix as an owner parameter, R16 consumes it and nothing else here changes.

**Observation for the implementation, outside R16's scope.** py pins `github/codeql-action/init@v4.37.0`, whose `src/defaults.json` resolves `codeql-bundle-v2.26.0`, while the current release v4.37.9 resolves 2.26.4 (`evidence/doc-crosschecks.log`, retrieved 2026-09-09). The action pin belongs to the inherited workflow (F027) and the pinning policy (R20). The dynamic suite resolution was verified at 2.26.4; at the `codeql-cli/v2.26.0` tag both delta queries exist with the same `@precision medium` / `@problem.severity error` metadata and the `security-extended` selector file is byte-identical, so the delta holds at the inherited pin by static derivation.

re-verify: when `github/codeql-action`'s pinned `bundleVersion` advances past `codeql-bundle-v2.26.4` (re-run `evidence/resolve-queries.log`; `rust/command-line-injection` is already on `main`); when an `experimental/` directory appears under `rust/ql/src` (Alt-E stops being empty); when the Rust extractor stops seeding `cfg(test)` or the Action gains an extractor-option input (Alt-F becomes viable); when R32/R33 settle the test, bench and fuzz layout (reconcile the path list); when R69 selects a web framework absent from GitHub's recognised-library list or R58 rules out logging request-derived data (re-weigh the CWE-117 half); and before the template's first public release.

## Parameters

- owns: none — the prompt's `- owns:` line is empty; R16 publishes no parameter.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
  Compatible: the CodeQL Rust extractor requires stable `rustup` and `cargo`; the recommended configuration executed at rustc 1.96.0 (the floor) and 1.98.0 (stable) with identical results.
- assumes rust-edition = 2024
  Compatible: CodeQL supports "Rust editions 2021 and 2024" (codeql.github.com supported languages, codex 2026-09-05, opus 2026-09-09); both fixture crates are edition 2024.
- assumes target-os-matrix = ubuntu-latest, macos-latest
  Not exercised by the scan itself, which runs on `ubuntu-latest` alone in both source repositories and in every Rust adopter surveyed; the YAML file is OS-independent; the fixture builds and tests on macOS arm64 and Ubuntu aarch64.
- assumes license = MIT OR Apache-2.0
  The added file carries the repository licence; no dependency is introduced.
- consumed parameters: none (`- consumes:` is empty). No `CONFLICT:` line was raised by either engine and none is raised here.

## Empirical check

Form used: **(a) — the pinned CodeQL bundle executed locally.** The CodeQL CLI was not installed; `codeql-bundle-osx64.tar.zst` from release `codeql-bundle-v2.26.4` (990,968,819 bytes) was downloaded into `review/empirical/tools/` (git-ignored) and verified against the published checksum (`shasum -a 256 -c`: `codeql-bundle-osx64.tar.zst: OK`). What this proves: the recommended file and workflow inputs are consumed by the exact CLI the pinned Action runs, the suite delta is real, `paths-ignore` works for Rust at extraction time and at workspace depth, and the whole path works at the MSRV floor. What it does not prove: behaviour on GitHub's x86_64 `ubuntu-latest` runners (this ran on macOS arm64; no Linux arm64 bundle exists, so the Lima VM leg is cargo-only), the SARIF upload and Security-tab rendering (no `github/codeql-action` execution), and any wall-clock effect at repository scale.

Toolchain and hosts:

- macOS 26.4 (Darwin 25.4.0) arm64; `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`; floor leg via `RUSTUP_TOOLCHAIN=1.96.0`: `rustc 1.96.0 (ac68faa20 2026-05-25)`, `cargo 1.96.0 (30a34c682 2026-05-25)`; CodeQL CLI 2.26.4 (`sha 6b1e4dee94adb20f90a671f3fc9e04be32eecf65`); actionlint 1.7.12.
- Lima VM `ubuntu`: Ubuntu 25.10, kernel 6.17.0-41-generic, **aarch64** (GitHub's `ubuntu-latest` is x86_64); `rustc 1.98.1` and `1.96.0`; CodeQL not available (`command -v codeql` → none; the linux64 bundle is x86_64-only).

Working directory: `research/runs/R16/2026-09-05T163018Z-61c8f49b581d/review/` (fixture at `empirical/fixture/`, databases under `empirical/tools/.work/`). The fixture is a Cargo workspace: a root package `rs_codeql_fixture` (edition 2024, `rust-version = "1.96"`, one dependency `log = "0.4"`) with `[workspace] members = ["crates/inner"]`, and the member `inner`. One `rust/access-after-lifetime-ended` marker (qhelp shape) sits in each placement — `src/lib.rs` (shipped), `src/lib.rs` inside `#[cfg(test)]`, `tests/integration.rs`, `examples/example.rs`, `benches/bench.rs`, `docs/snippet.rs` (not a Cargo target), `crates/inner/src/lib.rs` (nested shipped), `crates/inner/tests/nested.rs` (nested test) — plus a `rust/access-invalid-pointer` marker and an argv→`log::info!` line in `src/lib.rs`, the recommended config (verbatim, above) and the inherited workflow with the Rust Init step.

Commands and observed output (full logs in `review/evidence/`):

```text
$ codeql version --format=text                                   # evidence/codeql-version.log, exit 0
CodeQL command-line toolchain release 2.26.4.

$ grep -n -A4 '^build_modes' empirical/tools/codeql/rust/codeql-extractor.yml   # evidence/rust-extractor-yml.log, exit 0
6:build_modes:
7-  - none

$ codeql resolve queries codeql/rust-queries:codeql-suites/rust-code-scanning.qls      # exit 0 — 16 security queries
$ codeql resolve queries codeql/rust-queries:codeql-suites/rust-security-extended.qls  # exit 0 — 18 security queries
$ diff rust-code-scanning.txt rust-security-extended.txt         # evidence/resolve-queries.log
> queries/security/CWE-117/LogInjection.ql
> queries/security/CWE-825/AccessAfterLifetime.ql
$ diff rust-security-extended.txt rust-security-and-quality.txt
> queries/security/CWE-696/BadCtorInitialization.ql
> queries/unusedentities/UnusedVariable.ql
$ diff rust-security-extended.txt rust-security-experimental.txt   # exit 0 (identical)

$ cargo build --workspace --all-targets && cargo test --workspace   # evidence/fixture-build-stable.log, exit 0 / exit 0

$ codeql database create <W>/db-bare --language=rust --build-mode=none --source-root=. --overwrite   # evidence/db-bare-create.log, exit 0
  fixture files archived (8): benches/bench.rs crates/inner/src/lib.rs crates/inner/tests/nested.rs docs/snippet.rs
                              examples/example.rs src/lib.rs src/main.rs tests/integration.rs
$ codeql database analyze <W>/db-bare codeql/rust-queries:codeql-suites/rust-code-scanning.qls --format=sarif-latest ...     # exit 0
  CodeQL scanned 8 out of 8 Rust files in this invocation.
  results: 2 — rust/access-invalid-pointer src/lib.rs:25; rust/cleartext-logging src/lib.rs:33
$ codeql database analyze <W>/db-bare codeql/rust-queries:codeql-suites/rust-security-extended.qls --format=sarif-latest ... # exit 0
  results: 10 — rust/access-after-lifetime-ended at benches/bench.rs:12, crates/inner/src/lib.rs:12,
                crates/inner/tests/nested.rs:12, docs/snippet.rs:12, examples/example.rs:12, src/lib.rs:14,
                src/lib.rs:47 (#[cfg(test)]), tests/integration.rs:12; plus the 2 default-suite results

$ codeql database create <W>/db-cfg --language=rust --build-mode=none --source-root=. \
    --codescanning-config=.github/codeql/codeql-config.yml --overwrite               # evidence/db-cfg-create-analyze.log, exit 0
  fixture files archived (5): crates/inner/src/lib.rs docs/snippet.rs examples/example.rs src/lib.rs src/main.rs
                              (tests/, benches/ and crates/inner/tests/ not extracted)
$ codeql database analyze <W>/db-cfg --format=sarif-latest --output=<W>/cfg.sarif --rerun   # no suite argument; exit 0
  CodeQL scanned 5 out of 5 Rust files in this invocation.
  Starting evaluation of codeql/rust-queries/queries/security/CWE-117/LogInjection.ql.
  Starting evaluation of codeql/rust-queries/queries/security/CWE-825/AccessAfterLifetime.ql.
  results: 7 — rust/access-after-lifetime-ended at crates/inner/src/lib.rs:12, docs/snippet.rs:12,
               examples/example.rs:12, src/lib.rs:14, src/lib.rs:47;
               rust/access-invalid-pointer src/lib.rs:25; rust/cleartext-logging src/lib.rs:33

$ export PATH="$HOME/.cargo/bin:$PATH" RUSTUP_TOOLCHAIN=1.96.0; cargo --version   # evidence/db-cfg-msrv-1.96.0.log
cargo 1.96.0 (30a34c682 2026-05-25)
$ cargo build --workspace --all-targets && cargo test --workspace                  # exit 0 / exit 0
$ codeql database create <W>/db-cfg-196 ... --codescanning-config=.github/codeql/codeql-config.yml   # exit 0
  toolchain source roots seen: toolchains/1.96.0-aarch64-apple-darwin; fixture files archived (5): same five as above
$ codeql database analyze <W>/db-cfg-196 --format=sarif-latest ...                 # exit 0 — results: 7 (identical to stable)

$ actionlint .github/workflows/codeql.yml                        # evidence/workflow-validation.log, exit 0
$ python3 - (YAML parse; A3 guard)                               # exit 0
A3 guard (config-file set, queries unset, languages rust, build-mode none): PASS

$ limactl shell ubuntu -- bash -lc 'source $HOME/.cargo/env; cd ~/r16-fixture; cargo build --workspace --all-targets; cargo test --workspace'
  stable (rustc 1.98.1): build-exit=0 test-exit=0; 1.96.0: build-exit=0 test-exit=0   # evidence/linux-leg-cargo.log

$ codeql database analyze <W>/db-bare ...rust-security-extended.qls --threat-model local ...   # exploratory; exit 0
  results: 10 — rust/log-injection still absent                  # evidence/exploratory-threat-model-local.log
```

Reading of the results: the two extended-only queries exist and run through the config file (A1, A4); `paths-ignore` removes `tests/`, `benches/` and the nested `crates/inner/tests/` before extraction, so their alerts disappear while `src/`, the nested `crates/inner/src/`, `examples/` and a stray `.rs` under `docs/` keep theirs (A2; the "docs is inert" claim holds only for non-`.rs` content); `#[cfg(test)]` code inside `src/` is still scanned with the config in force (the partial-exclusion caveat is observed, not argued); the MSRV floor behaves identically (A5); the workflow parses, lints and satisfies the override guard (A3). The `rust/log-injection` marker did not fire in any configuration tried. A first-round run of the same fixture as a single root package with root-anchored `tests/**`/`benches/**` globs gave the same shape of result (6 files → 4, alerts from `tests/` and `benches/` removed); those logs were superseded by the workspace run and are not retained, so the root-anchored form's behaviour on a nested member is inferred from glob semantics and SurrealDB's `**/` practice, not observed.

Evidence logs: `review/evidence/codeql-version.log`, `rust-extractor-yml.log`, `resolve-queries.log`, `fixture-build-stable.log`, `db-bare-create.log`, `db-bare-analyze.log`, `db-cfg-create-analyze.log`, `db-cfg-msrv-1.96.0.log`, `workflow-validation.log`, `linux-leg-cargo.log`, `doc-crosschecks.log`, `exploratory-threat-model-local.log`. Reproduction helper: `review/empirical/sarif-summary.py`.

## Engines

- codex `raw/codex.md` (gpt-5.6-terra, sha256 `cc682e17606442b1311a5d93a4c6bfacab4068c94c6aaeb7106e81c3ecc40b32`, retrievals 2026-09-05)
- opus `raw/opus.md` (claude-opus-5[1m], sha256 `56885350f4ceac349b99c2685320defe6fae577a0cf63524a7e0c1c7826b0787`, retrievals 2026-09-09)

Agreement: both select `security-extended` in a repository-local config file referenced by `config-file:`, reject `security-and-quality`, rate `github/codeql-action` and `github/codeql` as `active`, mark the crate figure table `inapplicable` for a pattern item with reasons, raise no `CONFLICT:`, and each carries a `BASELINE-REVIEW: F027` line.

Disagreements and how the evidence settled each:

1. **`paths-ignore` — codex: none; opus: `tests/**`, `benches/**`, `fuzz/**` (conditional).** Codex's stated gate was that directory filters apply only to a no-build analysis and the build mode "is not an R16 decision". The bundle's `rust/codeql-extractor.yml` declares `build_modes: [none]` as the sole mode, GitHub Docs names Rust among the compiled languages filtered "without building the code" (retrieved 2026-09-09), and Run B shows the filter removing `tests/`, `benches/` and `crates/inner/tests/` at extraction time. Codex's second objection — no measured noise — is answered by Run A, where the non-taint marker fired in `tests/`, `benches/` and the nested `tests/` under the bare configuration. Settled for opus's Alt-C with one change to opus's values: the globs are `**/`-anchored (SurrealDB's form) so that a workspace member's `tests/` is reached, and `**/fuzz/**` ships now because an entry for an absent directory was shown to be inert.
2. **`docs/**` — both engines omit it; opus's reason ("inert because `file_types` is `.rs` only") is refined.** A `.rs` file under `docs/` that belongs to no Cargo target was extracted and produced an alert. The omission stands on a different ground: Markdown is never extracted, and a Rust snippet under `docs/` is copy-able example code that should be scanned like `examples/`.
3. **`security-and-quality` delta — opus: `rust/dead-code`, `rust/unused-value`, `rust/unused-variable`.** `codeql resolve queries` at the pinned bundle resolves the delta as `rust/ctor-initialization` (`CWE-696/BadCtorInitialization.ql`) and `rust/unused-variable` only. Opus's statement that `rust/ctor-initialization` is "in neither security suite" is correct for the two security suites but omits its presence in `security-and-quality`. The exclusion verdict is unchanged; the composition is corrected.
4. **`rust/log-injection` value — opus rates it the extended suite's key CLI/web addition.** Not demonstrated: the qhelp-shaped argv fixture produced no CWE-117 alert under the default or the `local` threat model at 2.26.4. Recorded as an unverified value claim that depends on the sources and sinks the real R58/R59/R69 stack exposes; the CWE-825 addition is demonstrated instead.
5. **Open-issue count for `github/codeql-action` — codex: search endpoint rate-limited, unverified; opus: 158.** Not decision-relevant; opus's figure is carried, codex's gap noted.
6. **Wall-clock effect of `paths-ignore` — opus: low confidence.** Refined: the filter skips extraction of ignored files (proven), but the extraction observed locally was dominated by 5,831 standard-library source files that no filter reaches; the alert-volume effect is certain, the time effect is proportional only to ignored user code and remains unmeasured at repository scale.

Uncertainty that remains: runner behaviour on x86_64 `ubuntu-latest` and the SARIF upload path were not exercised (no `github/codeql-action` run); whether GitHub-hosted runners extract standard-library sources as this host did is unknown; the inherited `@v4.37.0` action pin resolves bundle 2.26.0, which was checked statically (both delta queries present, selector byte-identical) but not executed.
