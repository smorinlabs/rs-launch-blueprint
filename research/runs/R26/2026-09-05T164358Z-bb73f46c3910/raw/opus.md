# R26 — packed-artifact-content-guard (bundle) — Opus raw report

All figures retrieved 2026-09-10 unless stated otherwise. Empirical results were produced on the verification host (macOS darwin 25.4.0) with `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)` and `rustc 1.98.0 (88d9e12ae 2026-08-18)`, in a throwaway workspace built for this item; no template repository was scaffolded. Source-code citations are `rust-lang/cargo` at `master`, read 2026-09-10; behavior citations are cargo 1.98.0 stable unless a changelog version is given.

### Landscape

**Category this item decides.** A *release-artifact integrity gate*: the checks a publish pipeline runs, before the irreversible upload, that (a) assert the exact file set inside the artifact and (b) assert that the packaging tool did not silently rewrite the package's declared metadata. The category is not "a crate to add"; the deliverable is a small set of commands plus checked-in expectation files. `cargo publish` is irreversible on crates.io (a version can be yanked but never replaced), which is what makes a *pre*-publish gate the right shape rather than a post-publish audit.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What it does for this item |
|---|---|---|
| Built-in / first-party toolchain | `cargo package --list`; `cargo package` (tarball + verify build, stderr diagnostics); the packed `Cargo.toml` inside the `.crate`; `cargo metadata --no-deps` pointed at that packed manifest; `cargo publish --dry-run`; the `package.include` / `package.exclude` manifest keys | Enumerates the shipped file set, produces the normalized manifest, and re-reads it as JSON |
| Established industry standard (third-party, widely used) | none for assertion. `cargo-release` (crate-ci) orchestrates releases; `cargo-diet` (the-lean-crate) *computes* `include` directives | Neither asserts packed content; see *Excluded by gate* per member |
| Up-and-comer | `cargo package --list --message-format json` (unstable, nightly-only; tracking issue rust-lang/cargo#15353, open, created 2025-03-26, last updated 2025-03-26 — https://github.com/rust-lang/cargo/issues/15353) | The exact structural analogue of ts's `npm pack --dry-run --json`; not usable under the stable-Rust constraint |

There is no maintained crate or GitHub Action that wraps packed-file-list diffing. A GitHub code search for `"cargo package --list" language:YAML` returned `total_count` 632 (https://api.github.com/search/code, 2026-09-10) and the sampled hits are all hand-rolled shell in individual projects, not a reusable action. That answers the LOW question: hand-rolled is the ecosystem norm, exactly as it is in ts.

**Authoritative sources used, and why each counts.**

1. *The Cargo Book*, `cargo package` command page and the Manifest reference — the Rust project's own normative documentation for the tool being gated. https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.rust-lang.org/cargo/reference/manifest.html, retrieved 2026-09-10.
2. *The Cargo Book*, Publishing guide — the Rust project's own instruction to verify contents: "You can check which files are included with the following command: `$ cargo package --list`" (`doc/book/src/reference/publishing.md:90-95`, `rust-lang/cargo` @ master, retrieved 2026-09-10).
3. *Cargo's source* — `src/workspace/parser/mod.rs` and `src/ops/cargo_package/mod.rs` at master. Primary evidence for exactly which manifest entries Cargo rewrites or drops, and at what severity.
4. *Cargo's own test suite* — `tests/testsuite/package.rs`. The project asserts the severity of these behaviors itself; a test that expects `[WARNING]` is stronger evidence than prose that the behavior is intentional and stable.
5. *The Cargo changelog* (`doc/book/src/CHANGELOG.md` @ master) — dates each behavior to a released Cargo version, which is what the MSRV gate needs.
6. *RustSec Advisory Database* — https://rustsec.org/packages/cargo.html, retrieved 2026-09-10.
7. Excluded as non-authoritative: individual blog posts. None were relied on.

**Well-regarded Rust projects surveyed, with the evidence that they are well regarded** (`GET https://api.github.com/repos/<o>/<r>`, `stargazers_count`, retrieved 2026-09-10):

| Project | Stars | `pushed_at` | Evidence relevant here |
|---|---|---|---|
| `clap-rs/clap` | 16697 | 2026-09-09T22:30:08Z | The de-facto Rust CLI argument parser. Declares a workspace-level `include = ["build.rs", "src/**/*", "Cargo.toml", "LICENSE*", "README.md", "examples/**/*"]` and inherits it per-crate with `include.workspace = true` (`Cargo.toml:18-25`, `:125`, HEAD 2026-09-10) |
| `GitoxideLabs/gitoxide` | 11930 | 2026-09-10T14:05:31Z | A pure-Rust Git implementation, widely depended on (Cargo itself uses `gix`). `gix/Cargo.toml:11` declares `include = ["/src/**/*", "/LICENSE-*"]` |
| `BurntSushi/ripgrep` | 68148 | 2026-08-04T13:59:44Z | The counter-example: a denylist, `exclude = ["HomebrewFormula", "/.github/", "/ci/", "/pkg/brew", "/benchsuite/", "/scripts/", "/crates/fuzz"]` (`Cargo.toml:16-24`) |
| `PyO3/maturin` | 5787 | 2026-09-09T11:33:39Z | Treats `cargo package --list` as the authoritative file set when it builds Python source distributions: `fn cargo_package_file_list(...)` runs `["package", "--list", "--allow-dirty", "--manifest-path"]` (`src/source_distribution/mod.rs:110-122`, HEAD 2026-09-10). Production evidence that `--list` output is stable enough to be parsed by a tool, not just eyeballed |
| `serde-rs/serde`, `tokio-rs/tokio` | — | — | Neither `serde/Cargo.toml` nor `tokio/Cargo.toml` (HEAD 2026-09-10) declares `include` or `exclude`; both rely on default gitignore-derived inclusion. Evidence that the allowlist is a deliberate practice, not a universal one |

### Principles and implementation

**Shared requirement, its source, and the level of agreement.** The principle both source repositories' checks serve — one expressed (ts), one absent (py) — is: *a publish pipeline must prove, before the irreversible upload, that the artifact it is about to ship contains exactly the intended files and declares exactly the intended package metadata; the packaging tool's own silent normalizations must be treated as changes requiring assertion, not as trustworthy cleanup*. Agreement is required at the level of **policy plus observable acceptance criteria**, not at the level of a specific command: ts's `npm pack --dry-run --json` parsing (F039, `ts-launch-blueprint/.github/workflows/publish.yml:112`) and its `bin`-field auto-correction guard (F078, same file `:199`) are two instances of one policy. Both ledger rows are `DIVERGENT`, origin `ts-only`, and are explicitly bundled as "one publish-content-verification item" (`docs/port/COMMONALITY.md:45`, `:84`).

**What must agree; what may vary.** Must agree: (1) the packed file set is asserted against a checked-in expectation, and a difference fails the job; (2) the packaging tool's rewrite of the package's declared targets/metadata is asserted, and a silent drop fails the job; (3) both run before the upload step, inside the same workflow, on the same commit that will be published. May vary: the file format of the expectation, whether the assertion is a `diff` or a set comparison, and whether an additional copy runs earlier as a pull-request gate.

**The essential behaviors, in Rust terms — and the load-bearing finding.**

*Question 1 (HIGH), file enumeration:* Yes. `cargo package --list` prints the exact shipped file set, one path per line, sorted, on **stdout**, with all diagnostics on stderr — a cleaner substrate for a CI diff than ts's JSON, which needs a parser. Verified on the probe workspace: stdout contained only paths; the dirty-tree error and every `warning:` went to stderr. The Cargo Book documents `--list` as "Print files included in a package without making one" (https://doc.rust-lang.org/cargo/commands/cargo-package.html, 2026-09-10). Since Cargo 1.94 (2026-03-05, PR #16341, "cargo-package: skip registry verification when using `--list`") the listing no longer needs the registry, so it runs offline: `cargo package -p rsdemo --list --no-verify --offline` exited 0 on the probe. The list always contains four synthesized entries that do not exist in the working tree — `.cargo_vcs_info.json`, `Cargo.lock`, `Cargo.toml` (the normalized one), `Cargo.toml.orig` — so the expectation file must include them.

*Question 2 (HIGH), silent metadata rewrite:* **Yes, Cargo has a direct analogue of npm's `bin` auto-correction, and its failure mode is quieter than npm's.** Cargo rewrites the manifest when packaging, documented as "The original `Cargo.toml` file is rewritten and normalized" with `[patch]`, `[replace]`, `[workspace]` removed and path dependencies rewritten to registry dependencies (Cargo Book, `cargo package`, 2026-09-10). Beyond that documented normalization, Cargo **materializes auto-discovered targets into explicit tables and silently prunes any target whose source file is not packed**. In `prepare_toml_for_publish` (`src/workspace/parser/mod.rs`, master, 2026-09-10) the pruning helper is called for `"library"` (`:3116`), `"binary"` (`:3120`), `"example"` (`:3122`), `"test"` (`:3123`) and `"benchmark"` (`:3125`), plus `package.build` entries (`:3015-3018`); the pruning itself emits `gctx.shell().warn(...)` — ``"ignoring {context} `{name}` as `{path}` is not included in the published package"`` (`:3327-3331`) — and returns `Ok(None)`, dropping the target. A second silent rewrite lives in `src/ops/cargo_package/mod.rs:483-488`: when both `package.include` and `package.exclude` are set, Cargo warns `"both package.include and package.exclude are specified; the exclude list will be ignored"` and proceeds.

This is warning-only *by design*, dated: Cargo 1.80 (2024-07-25), "cargo-package: Warn, rather than fail, if a Cargo target is excluded during packaging." (PR https://github.com/rust-lang/cargo/pull/13713). Cargo's own tests pin the severity: `discovery_inferred_lib_excluded` (`tests/testsuite/package.rs:4946`) and `discovery_inferred_other_excluded` (`:5313`) assert ``[WARNING] ignoring library `foo` as `src/lib.rs` is not included in the published package`` and the `binary`/`example`/`test`/`benchmark` variants.

Verified end to end on the probe. With `src/bin/rsdemo-serve.rs` outside the packed set, `cargo package --workspace --no-verify` printed ``warning: ignoring binary `rsdemo-serve` as `src/bin/rsdemo-serve.rs` is not included in the published package`` and **exited 0**, producing a `.crate` whose normalized `Cargo.toml` declared only one `[[bin]]`. That is precisely ts's F078 hazard ("ship the package WITHOUT its CLI") reproduced in Cargo, with no exit-code signal at all. So this half of the bundle is **an active check, not a documented non-issue**.

The same probe showed the rest of the rewrite surface concretely: `version.workspace = true` resolved to `version = "0.1.0"`; the path dependency became `[dependencies.rsdemo-core] version = "0.1.0"` with `path` gone; a path-only dev-dependency vanished entirely, leaving an empty `[dev-dependencies]`; `build = false`, `autolib = false`, `autobins = false`, `autoexamples = false`, `autotests = false`, `autobenches = false` were added; and explicit `[lib]`, `[[bin]]`, `[[test]]` tables were written. Cargo may also inject `package.resolver` when the workspace resolver differs from the package's implied one (`src/workspace/parser/mod.rs:3041-3047`).

*Question 3 (MEDIUM), are Cargo's defaults safer than npm's:* **No.** Cargo's default is "everything in the package root that VCS does not ignore" (Cargo Book, Manifest reference: "The default if neither field is specified is to include all files from the root of the package, except for the exclusions listed below"; only gitignored/hidden files are skipped). On the probe, a stray root file `STRAY.txt` and `tests/it.rs` shipped under default rules. Cargo's default is *differently* leaky from npm's, not less leaky: npm ships everything not excluded, Cargo ships everything git tracks. The guard therefore retains full value for a Rust template. What genuinely lowers the risk is declaring `package.include`, which makes the shipped set an allowlist in the manifest; that is why the `include` policy is a member of this stack rather than a footnote.

*Question 4 (MEDIUM), placement:* run the file-set assertion in **both** places and the metadata assertion in the publish workflow's verify job. The file-set check is cheap and offline (`--list --offline`, no registry, no build), so a pull-request copy costs seconds and turns "we shipped the wrong files" into a review-time diff on the expectation file — the change becomes visible in the PR that causes it. The metadata assertion needs a real `.crate` (and, at publish time, resolvable dependency versions), so it belongs in the verify job that already exists for tag/version consistency (F074/F075, out of scope here). This is stricter than either source repo; it is the answer to the placement question, not a change to a recorded baseline.

*Question 5 (LOW), wrapper:* none exists and none is worth writing. The stack is three commands, `diff`, `tar` and `jq`.

**Architectural alternatives compared, before libraries.**

| Alternative | How it works | Why not chosen as the primary |
|---|---|---|
| **Command + checked-in expectation, diffed in the workflow** (recommended) | `cargo package --list` vs `ci/expected-packed-files.txt`; packaged target set vs `ci/expected-packaged-targets.json` | Chosen. Mirrors ts's shape, keeps the expectation reviewable in the PR that changes it, and needs no dependency |
| **Snapshot test in the crate's own test suite** (e.g. `insta`, or `trycmd`/`snapbox`) | A `tests/packaging.rs` shells out to `cargo package --list` and snapshot-asserts | A real option, and it gets the PR gate for free. Rejected as primary because it couples an artifact-integrity gate to the test harness and to whatever R33 (`property-and-snapshot-testing`) selects, makes `cargo test` shell out to `cargo` (recursive invocation, slow under `--no-verify` removal), and puts the expectation in a snapshot file that `cargo insta accept` can rewrite in bulk — the opposite of what an integrity gate wants. Recorded as the ranked runner-up for member 1 |
| **Post-publish verification** (download the published `.crate`, inspect it) | Fetch from crates.io after upload and assert | Rejected: `cargo publish` is irreversible. Detecting the problem after the upload only enables a yank |
| **Rely on `cargo package`'s verify build alone** | The default extract-and-build step proves the tarball compiles | Insufficient and demonstrated so: the probe's verify build *passed* while the package silently lost a binary target. A package missing its CLI still compiles |
| **Rely on `--message-format json`** | Structural analogue of ts's JSON parsing | Fails the stable-Rust constraint; nightly-only, verified: ``error: the `--message-format` flag is unstable, and only available on the nightly channel of Cargo` |

**Where the Rust design must differ from ts's.** Three places. (1) ts parses JSON because `npm pack --json` offers it; Rust's stable output is a sorted plain-text list, so the assertion is a `diff` and is *simpler*, not a workaround. (2) ts greps `npm publish --dry-run` stderr for two known auto-correction strings; grepping Cargo's stderr is necessary but not sufficient, because a legitimate design also produces drop warnings — on the probe, excluding `tests/` from the package correctly emitted ``ignoring test `it` ...`. Scoping the grep to `library`/`binary`/`package.build` removes that false positive, but the authoritative check is a **diff of the packaged target set**, because the expectation file encodes which targets are meant to ship. (3) ts's workflow comments assert that `--dry-run` "never contacts the registry"; Cargo's `publish --dry-run` **does** contact the index (observed: `Updating crates.io index`), which is a network-egress fact the verify job's permissions and any network policy must accommodate — a note for R08 (`workflow-permission-hardening`), not a conflict here.

**Minimal realistic example and the executable acceptance check.** A workspace with a library target, a `src/main.rs` CLI binary and a second `src/bin/*.rs` web-service binary — the template's own shape. Two expectation files, `ci/expected-packed-files.txt` and `ci/expected-packaged-targets.json`, and one guard script. **Checks actually run** (on the probe, 2026-09-10, cargo 1.98.0): healthy state → `OK: packed content and packaged metadata match expectations`, exit 0; narrowed `include` dropping the second binary → all three sub-checks failed, exit 1, with the file-set diff showing `-src/bin/rsdemo-serve.rs`, the scoped grep printing ``warning: ignoring binary `rsdemo-serve` ...`, and the target-set diff showing the lost `{"kind":["bin"],"name":"rsdemo-serve"}`; reverting to a denylist manifest and adding a stray file → the file-set diff failed with `+LEAKED_SECRET.txt`, `+STRAY.txt`, `+tests/it.rs`, exit 1. **Proposed, not run:** the same script inside a GitHub Actions job on `ubuntu-latest` and `macos-latest`, and the publish-time `cargo publish --dry-run` invocation (which requires a real registry index and a publishable version).

No `BASELINE-REVIEW:` finding. F039's recorded placement ("runs at publish time, not in `ci.yml`") is a fact about the ts repository, not a rule this item is challenging; adding a pull-request copy of the cheap half is this item's answer to its own MEDIUM placement question.

### Recommendation

One stack, all first-party, no crate added to the template's dependency tree:

1. **`cargo package --list`** diffed against a checked-in `ci/expected-packed-files.txt` — the packed-file-set assertion (Rust's F039). Runs twice: as a pull-request CI step (`--offline --no-verify`, seconds) and inside the publish workflow's verify job.
2. **`cargo metadata --no-deps` read from the packaged manifest extracted out of the `.crate`**, diffed against `ci/expected-packaged-targets.json`, with a scoped grep of `cargo package`'s stderr as the early, human-readable signal — the metadata-integrity assertion (Rust's F078). Runs in the publish workflow's verify job.
3. **`cargo publish --dry-run`** as the final publish-time rehearsal in the verify job, immediately before the protected-environment upload.
4. **`package.include` declared in `Cargo.toml`** (never together with `package.exclude`) — the manifest-level policy that makes the file set an allowlist and keeps the expectation file short and stable.

### Members

#### cargo package --list (packed-file-set assertion)

##### Landscape
Built-in / first-party toolchain bin. The only stable Rust mechanism that enumerates the exact shipped file set. Its unstable JSON sibling (`--message-format json`) sits in the up-and-comer bin. No third-party tool competes: the field's practice is to call this command and compare its output.

##### Principles and implementation
Preserves the principle "assert the shipped file set against a reviewed expectation". Implementation: `cargo package -p <pkg> --list --no-verify` writes sorted paths to stdout; `diff -u ci/expected-packed-files.txt <(that output)` fails the job on any addition or removal. The expectation file must contain the four synthesized entries (`.cargo_vcs_info.json`, `Cargo.lock`, `Cargo.toml`, `Cargo.toml.orig`). Behavior is documented at https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-10) and recommended by the Cargo Book's publishing guide (`doc/book/src/reference/publishing.md:90-95`, master, 2026-09-10).

##### Dominant choice
`cargo package --list`, shipped with every Rust toolchain. Production reference implementation: `PyO3/maturin` (5787 stars, `pushed_at` 2026-09-09T11:33:39Z) invokes exactly `["package", "--list", "--allow-dirty", "--manifest-path"]` and parses the result as the authoritative file set for Python source distributions (`src/source_distribution/mod.rs:110-122`, HEAD, 2026-09-10).

##### Qualified shortlist
- `cargo package --list` (recommended).
- A snapshot test of the same output inside the crate's test suite (`insta` or `snapbox`) — the same command, a different assertion site.

##### Excluded by gate
- `cargo package --list --message-format json`: **fails the stable-Rust constraint**. Verified on the host: ``error: the `--message-format` flag is unstable, and only available on the nightly channel of Cargo`. Tracking issue rust-lang/cargo#15353 (open, created 2025-03-26, last updated 2025-03-26).
- `cargo-diet` 1.4.1: **not an assertion tool** — it computes and rewrites `include` directives in place ("Make your crate lean by computing size-optimal include directives for Cargo manifests", `Cargo.toml` description, HEAD 2026-09-10). A CI gate must not mutate the manifest it is checking. Figures for completeness: crates.io `crate.recent_downloads` 738, `crate.downloads` 25877, newest non-yanked `1.4.1` `created_at` 2026-08-31T02:11:38.566810Z (`GET https://crates.io/api/v1/crates/cargo-diet`, `/versions`); GitHub `stargazers_count` 193, `archived` false, `pushed_at` 2026-08-31T04:04:25Z, license MIT-only; open issues `total_count` 2 (`GET https://api.github.com/search/issues?q=repo:the-lean-crate/cargo-diet+is:issue+is:open`); https://rustsec.org/packages/cargo-diet.html returns HTTP 404 (no advisory page). Its MIT-only license is compatible for an external developer tool but it is not adopted here.
- `cargo-release` 1.1.5: **does not assert packed content**. Its reference documents only `verify`/`--no-verify`, which forwards Cargo's own build verification (`docs/reference.md:59`, `:414-420`, HEAD 2026-09-10). Figures: crates.io `recent_downloads` 16015, `downloads` 539961, newest non-yanked `1.1.5` `created_at` 2026-08-11T16:10:45.518823Z; GitHub `stargazers_count` 1587, `archived` false, `pushed_at` 2026-09-02T23:06:01Z, Apache-2.0; open issues `total_count` 58; RustSec page HTTP 404.

##### Up-and-comers
`--message-format json` (rust-lang/cargo#15353). If it stabilizes, the assertion could move from `diff` to a `jq` comparison, matching ts's shape exactly. Not needed: the plain-text list is already sorted and stable, which is why maturin parses it.

##### Fit for this template
Direct. The template ships a library plus at least two binaries (CLI, web service); the file set is small and the expectation file will be a dozen lines. Runs identically on `ubuntu-latest` and `macos-latest` — it is part of the toolchain those runners install. Costs no dependency, no binary size, no compile time. Two operational constraints matter for a workspace: `cargo package --workspace --list` concatenates every member's list with no per-package header (verified on the probe; open issue rust-lang/cargo#13953, created 2024-05-23, last updated 2025-12-11), so the guard must loop over packages with `-p`; and a dirty working tree makes the command exit 101 (verified), which is correct behavior for a release gate.

##### Recommendation
Adopt. Run `cargo package -p <pkg> --list --no-verify --offline --locked` per publishable package, diff against `ci/expected-packed-files.txt`, fail on any difference. Place it in the pull-request CI job *and* in the publish workflow's verify job.

##### Ranked runner-up
A snapshot test in `tests/packaging.rs` asserting the same output. It buys a PR gate for free and reuses whatever snapshot crate R33 selects, but it makes `cargo test` shell out to `cargo`, and `cargo insta accept`-style bulk re-recording can silently re-bless a leak. Second choice, not first.

##### Tradeoffs
The expectation file must be updated whenever a source file is legitimately added — which is the point: the change appears as a reviewable diff in the same pull request. With `package.include` declared, the churn is near zero because new files under `src/**/*.rs` are already covered by one line. Without `include`, every new root-level file forces an edit.

##### Parameters
`assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `assumes target-os-matrix = ubuntu-latest, macos-latest`; `assumes license = MIT OR Apache-2.0`. Toolchain floor for this member: cargo 1.94 (2026-03-05, PR #16341, "skip registry verification when using `--list`") for the offline/pre-publication behavior — comfortably below the 1.96 floor implied by stable 1.98 minus two minors. No `CONFLICT:`.

##### Migration implications
New file `ci/expected-packed-files.txt`. New step in the PR CI workflow and in the publish workflow's verify job. No change to `Cargo.toml` beyond the `include` member below.

##### Validation strategy
Executed on the probe: healthy list matched the expectation; adding a stray root file produced `+LEAKED_SECRET.txt`, `+STRAY.txt`, `+tests/it.rs` and exit 1; narrowing `include` produced `-src/bin/rsdemo-serve.rs` and exit 1. Planned: the same step on both runner OSes.

##### Confidence & re-verify trigger
High. Re-verify if `--message-format json` stabilizes (rust-lang/cargo#15353), if rust-lang/cargo#13953 changes `--workspace --list` output, or if a future Cargo release changes the synthesized-file set (as 1.81 did for `.cargo_vcs_info.json` and 1.84/1.87 did for `Cargo.lock`).

##### Sources
https://doc.rust-lang.org/cargo/commands/cargo-package.html (2026-09-10); `rust-lang/cargo` @ master `doc/book/src/reference/publishing.md:90-95` (2026-09-10); `PyO3/maturin` `src/source_distribution/mod.rs:110-122` HEAD (2026-09-10); https://github.com/rust-lang/cargo/issues/15353 (open, 2026-09-10); https://github.com/rust-lang/cargo/issues/13953 (open, 2026-09-10); `rust-lang/cargo` `doc/book/src/CHANGELOG.md` @ master, Cargo 1.94 (2026-03-05) PR #16341 (2026-09-10); `GET https://crates.io/api/v1/crates/cargo-diet`, `/versions`, `GET https://api.github.com/repos/the-lean-crate/cargo-diet`, `GET https://api.github.com/search/issues?q=repo:the-lean-crate/cargo-diet+is:issue+is:open`, https://rustsec.org/packages/cargo-diet.html (all 2026-09-10); `crate-ci/cargo-release` `docs/reference.md` HEAD and its crates.io/GitHub endpoints (2026-09-10).

#### cargo metadata --no-deps on the packaged manifest (metadata-integrity assertion)

##### Landscape
Built-in / first-party toolchain bin. This is the Rust answer to ts's `bin`-field auto-correction guard (F078). Two first-party substrates exist for it: the normalized `Cargo.toml` inside the `.crate` (raw TOML), and `cargo metadata --no-deps` pointed at that extracted manifest, which returns stable JSON on stable Rust. No third-party tool in any bin performs this check.

##### Principles and implementation
Preserves the principle "the packaging tool's silent rewrites are changes requiring assertion". Implementation, in three parts:
1. Capture `cargo package`'s stderr and fail on the drop warnings that can never be intentional for this template — `ignoring (library|binary) ... is not included in the published package`, ``ignoring `package.build``, and `both package.include and package.exclude are specified; the exclude list will be ignored`. This is the early, readable signal. It is deliberately **not** extended to `example`/`test`/`benchmark`, because excluding those from a package is a legitimate design: on the probe, a correct `include` produced ``warning: ignoring test `it` as `tests/it.rs` is not included in the published package``, and an unscoped grep failed the healthy build.
2. Extract the packaged manifest **from the tarball** — `tar -xzf target/package/<pkg>-<ver>.crate -C "$RUNNER_TEMP/pkg"` — and run `cargo metadata --no-deps --format-version 1 --manifest-path "$RUNNER_TEMP/pkg/<pkg>-<ver>/Cargo.toml"`, projecting `.packages[0].targets[] | {name, kind}` through `jq -S` and diffing against `ci/expected-packaged-targets.json`. This is authoritative: the expectation file states which targets are meant to ship, so a legitimate absence (tests) and an accidental one (a binary) are distinguishable.
3. Do **not** read `target/package/<pkg>-<ver>/`. Verified failure mode: with `--no-verify`, that directory is left over from an earlier run and is stale — on the probe it reported a target set that contradicted the tarball actually produced seconds earlier.

##### Dominant choice
`cargo metadata --no-deps --format-version 1` against the extracted packaged manifest. Verified on the probe (cargo 1.98.0, 2026-09-10): it returns `{"name":"rsdemo","version":"0.1.0","targets":[{"name":"rsdemo","kind":["lib"]},{"name":"rsdemo","kind":["bin"]},{"name":"rsdemo-serve","kind":["bin"]}],...}` for a package whose only dependency is unpublished — `--no-deps` avoids resolution, so this works before the dependency is on the registry.

##### Qualified shortlist
- `cargo metadata --no-deps` on the extracted manifest (recommended; stable JSON).
- A textual `diff` of the extracted normalized `Cargo.toml` against a checked-in copy. Rejected as primary: the file embeds `version = "x.y.z"`, so a byte-diff breaks on every release and would have to be de-versioned with `sed` before comparison. Useful as a *supplementary* check if the template ever needs to pin more than the target set.
- The scoped stderr grep (adopted alongside, not instead of, the target-set diff).

##### Excluded by gate
- Relying on `cargo package`'s verify build alone: **fails the acceptance criterion**, demonstrated. The probe's verify build compiled the package successfully while that package had silently lost a binary target.
- Relying on exit status: **fails**. `cargo package --workspace --no-verify` exited 0 with the drop warning present (verified). Cargo 1.80 (2024-07-25, PR https://github.com/rust-lang/cargo/pull/13713) changed this from a failure to a warning deliberately, so no future exit-code signal should be assumed.
- `cargo-release`, `cargo-diet`: excluded for the reasons recorded under member 1; neither inspects the normalized manifest.

##### Up-and-comers
None. No crate or action in the ecosystem asserts packaged-manifest integrity. The nearest adjacent tooling (`cargo-semver-checks`) compares public API across versions, which is R25/R04 territory, not packaged-metadata integrity.

##### Fit for this template
High, and higher than for a single-binary crate. The template ships a library and at least two binaries; the pruning behavior applies to `library` and every `binary` independently, so a template whose CLI and web service live in `src/bin/*.rs` has more surface for a silent drop than a one-target crate. Runs on `ubuntu-latest` and `macos-latest` with `tar` and `jq`, both present on GitHub-hosted runners for both OSes. Adds no dependency, no binary size, no compile time; the only cost is the `cargo package` run itself (with verification, one debug build of the packaged crate).

##### Recommendation
Adopt, in the publish workflow's verify job. Run `cargo package -p <pkg>` (verification on), fail on the scoped warnings, then extract the `.crate` and diff the projected target set against `ci/expected-packaged-targets.json`.

##### Ranked runner-up
De-versioned textual diff of the whole normalized `Cargo.toml`. It catches more than the target set — the injected `package.resolver`, dropped path-only dev-dependencies, resolved workspace inheritance — at the cost of a `sed` normalization step and more churn. Adopt it later if a metadata field other than the target set ever proves load-bearing.

##### Tradeoffs
Requires a real `.crate`, so it cannot run offline on every pull request the way member 1 can; a crate with unpublished path dependencies cannot be packaged individually (verified: `cargo package -p rsdemo` exited 101 with ``no matching package named `rsdemo-core` found`), so the workflow must use `--workspace` or publish in dependency order. The expectation file needs an edit whenever a target is legitimately added or removed — again, the point.

##### Parameters
`assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `assumes target-os-matrix = ubuntu-latest, macos-latest`; `assumes license = MIT OR Apache-2.0`. Toolchain floor: cargo 1.80 (2024-07-25) for the warning text this member greps; `cargo metadata --format-version 1` has been stable far longer. Both below the 1.96 floor. No `CONFLICT:`.

##### Migration implications
New file `ci/expected-packaged-targets.json`. New steps in the publish workflow's verify job. Requires `tar` and `jq` on the runner (both preinstalled on GitHub-hosted `ubuntu-latest` and `macos-latest`).

##### Validation strategy
Executed on the probe: healthy state produced `[{"kind":["bin"],"name":"rsdemo"},{"kind":["bin"],"name":"rsdemo-serve"},{"kind":["lib"],"name":"rsdemo"}]` and passed; excluding the second binary's source produced the diff `-{"kind":["bin"],"name":"rsdemo-serve"}` plus the scoped warning, exit 1; a manifest that packed the test file added `+{"kind":["test"],"name":"it"}` and failed, proving the check is bidirectional. Planned: the same steps inside the verify job on both runner OSes.

##### Confidence & re-verify trigger
High for the mechanism; the warning *strings* are the fragile part. Re-verify the grep patterns whenever the toolchain floor moves, and re-verify the whole member if Cargo changes the pruning severity (watch PRs touching `prepare_toml_for_publish` in `src/workspace/parser/mod.rs`) or adds fields to the normalized manifest. The target-set diff survives wording changes; the grep does not, which is why the grep is the secondary signal.

##### Sources
`rust-lang/cargo` @ master (2026-09-10): `src/workspace/parser/mod.rs:3015-3018` (`package.build` warning), `:3116`, `:3120`, `:3122`, `:3123`, `:3125` (pruning call sites for library/binary/example/test/benchmark), `:3327-3331` (warning format string), `:3041-3047` (`package.resolver` injection); `src/ops/cargo_package/mod.rs:483-488` (include+exclude warning), `:805-845` (`check_metadata` missing-field warnings); `tests/testsuite/package.rs:4946` `discovery_inferred_lib_excluded`, `:5313` `discovery_inferred_other_excluded`, `:3960` `normalize_case`. https://github.com/rust-lang/cargo/pull/13713 via `doc/book/src/CHANGELOG.md` Cargo 1.80 (2024-07-25) (2026-09-10). https://doc.rust-lang.org/cargo/commands/cargo-package.html (2026-09-10). Probe results, cargo 1.98.0, 2026-09-10.

#### cargo publish --dry-run (publish-time rehearsal)

##### Landscape
Built-in / first-party toolchain bin, and the direct structural counterpart of the command ts greps for its `bin` guard (`npm publish --dry-run`, `ts-launch-blueprint/.github/workflows/publish.yml:199`). No third-party analogue exists.

##### Principles and implementation
Preserves the principle "run every check the real upload would run, immediately before the upload, on the same commit". `cargo publish --dry-run` performs the full packaging path — manifest normalization, file selection, the extract-and-build verification, and registry-index resolution of every dependency — and uploads nothing (Cargo Book: "Perform all checks without uploading"). Implementation: one step in the verify job, `cargo publish -p <pkg> --dry-run --locked`, failing the job on nonzero exit.

##### Dominant choice
`cargo publish --dry-run`, shipped with the toolchain. Cargo's changelog shows the command is actively hardened for exactly this use: Cargo 1.83 era "cargo-publish: Now fails fast if the package version is already published" (`doc/book/src/CHANGELOG.md:2584`) and "cargo-publish: Downgrade version-exists error to warning on dry-run" (`:2624`).

##### Qualified shortlist
`cargo publish --dry-run` (recommended); `cargo package` alone (already run by member 2, but it does not exercise registry-index resolution of dependencies).

##### Excluded by gate
None. No candidate fails a fitness gate here; the alternatives are first-party commands with narrower coverage rather than gated-out tools.

##### Up-and-comers
None.

##### Fit for this template
Good, with one caveat the template's workflow must accommodate: unlike ts's `npm pack --dry-run` (whose workflow comment states it "never contacts the registry"), Cargo's dry run **does** reach the network — observed on the probe as `Updating crates.io index` — so the verify job needs outbound access to the crates.io index. That is a note for R08 (`workflow-permission-hardening`), not a conflict with any parameter owned here. Runs on both runner OSes.

##### Recommendation
Adopt as the last step of the verify job, after members 1 and 2, before the protected-environment publish step.

##### Ranked runner-up
`cargo package` with verification only. Cheaper and offline-capable, but it does not prove that every dependency version resolves against the registry, which is the failure this step is meant to surface before the upload.

##### Tradeoffs
Costs a full verification build (and a second one if member 2 already ran `cargo package`); can be reduced by running member 2 with `--no-verify` and letting this step do the single verifying build. Requires network egress in the verify job.

##### Parameters
`assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `assumes target-os-matrix = ubuntu-latest, macos-latest`; `assumes license = MIT OR Apache-2.0`. No `CONFLICT:`.

##### Migration implications
One step in `.github/workflows/publish.yml`'s verify job.

##### Validation strategy
Planned, not executed against a real registry: the probe's dry run reached the index and then failed on the deliberately unpublished path dependency (``no matching package named `rsdemo-core` found`), which confirms the command performs registry resolution but does not constitute a green-path result. A green path requires a publishable version and is only reproducible in the real publish workflow.

##### Confidence & re-verify trigger
Medium-high — the mechanism is documented and first-party, but this item did not observe a successful dry run end to end. Re-verify at the template's first real release, and whenever Cargo changes dry-run semantics (the changelog shows this area moves).

##### Sources
https://doc.rust-lang.org/cargo/commands/cargo-publish.html and `cargo publish --help` on the host (2026-09-10); `rust-lang/cargo` `doc/book/src/CHANGELOG.md` @ master `:2584`, `:2624` (2026-09-10); `ts-launch-blueprint` @ `cb1cbcb2` `.github/workflows/publish.yml` (the `Fail on any npm bin auto-correction` step); probe observation of `Updating crates.io index`, 2026-09-10.

#### package.include allowlist policy (manifest-level file selection)

##### Landscape
Built-in / first-party toolchain bin — a manifest key, not a tool. This member is a **pattern**, so the crate figure table (90-day downloads, all-time downloads, last release, stars, open issues, issue responsiveness, advisories) is `inapplicable`: a `Cargo.toml` key has no crates.io record, no repository of its own and no release cadence. Its stand-in evidence is adoption by well-regarded crates plus the Cargo Book's own reference, both given below. The generator `cargo-diet` sits in the established-third-party bin adjacent to this member and carries real crate figures, recorded under member 1's *Excluded by gate*.

##### Principles and implementation
Preserves the principle "the intended file set is declared, not inferred". Implementation: declare `include = ["src/**/*.rs", "Cargo.toml", "README.md", "LICENSE-MIT", "LICENSE-APACHE", "CHANGELOG.md"]` (adjusted to the template's real layout) in each publishable package, inheriting from `[workspace.package]` where the template has a workspace. Never declare `exclude` alongside it: Cargo warns `both package.include and package.exclude are specified; the exclude list will be ignored` and continues (`src/ops/cargo_package/mod.rs:483-488`), which member 2's grep treats as a failure. Note the interaction the Cargo Book states explicitly: "If `include` is specified, gitignore rules of the repository and global git configuration are not applied" — the allowlist replaces, rather than layers on, the VCS-derived default.

##### Dominant choice
`package.include`. Adoption by well-regarded projects (retrieved 2026-09-10): `clap-rs/clap` (16697 stars) declares it once at the workspace level and inherits it with `include.workspace = true` (`Cargo.toml:18-25`, `:125`) — the exact shape a workspace template should copy; `GitoxideLabs/gitoxide` (11930 stars) declares `include = ["/src/**/*", "/LICENSE-*"]` in `gix/Cargo.toml:11`. The counter-practice is real and worth stating: `BurntSushi/ripgrep` (68148 stars) uses `exclude`, and `serde-rs/serde` and `tokio-rs/tokio` declare neither.

##### Qualified shortlist
- `include` allowlist (recommended).
- `exclude` denylist (ripgrep's choice) — acceptable, but it leaves the shipped set open-ended, so every new root-level file changes the artifact until someone notices.
- Neither (serde, tokio) — relies entirely on `.gitignore`; the probe showed this ships stray tracked files.

##### Excluded by gate
- Declaring `include` **and** `exclude` together: excluded on evidence, not preference — Cargo silently ignores the `exclude` list (`src/ops/cargo_package/mod.rs:483-488`), so the manifest would state a constraint that has no effect.
- `cargo-diet` as an automated step: MIT-licensed, maintained (see member 1 figures), but it *edits* `Cargo.toml` in place. A manifest-mutating tool cannot be a CI gate. It is a reasonable one-off authoring aid when first writing the `include` list.

##### Up-and-comers
None. The `include`/`exclude` fields are long-stable manifest surface.

##### Fit for this template
Strong, and it is what makes member 1 low-maintenance. With `src/**/*.rs` in `include`, adding a new module or a third binary does not touch `ci/expected-packed-files.txt` beyond the one new path, and no non-source file can leak. It also removes the whole class of "we accidentally shipped the fixtures directory". OS-independent. No default features, no async-runtime coupling, no unsafe, no binary-size or compile-time cost — this member changes only which files enter the tarball.

##### Recommendation
Adopt. Declare `include` (not `exclude`) in `[workspace.package]` and inherit it per publishable package, following clap's shape.

##### Ranked runner-up
`exclude`, ripgrep's choice, if the template ever needs to ship a directory tree whose contents are not enumerable by glob. Second choice because it inverts the burden of proof.

##### Tradeoffs
An `include` list that is too tight silently drops a target — which is exactly the failure member 2 exists to catch, and which the probe reproduced. The two members are therefore complementary by construction: `include` narrows the artifact, the target-set diff proves the narrowing did not remove anything load-bearing. Also note the interaction with dirty-tree detection: rust-lang/cargo#16872 ("`cargo publish`: false-positive uncommitted error for `.gitignore`d files when `package.include` is specified", closed 2026-04-15) shows this area has had bugs; it is fixed, and the host toolchain (1.98.0) postdates the fix.

##### Parameters
`assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `assumes target-os-matrix = ubuntu-latest, macos-latest`; `assumes license = MIT OR Apache-2.0` — the last one is load-bearing here: both `LICENSE-MIT` and `LICENSE-APACHE` must appear in the `include` list, or the dual license ships without its texts. No `CONFLICT:`.

##### Migration implications
`Cargo.toml`: add `include` under `[workspace.package]` and `include.workspace = true` in each publishable package. Remove any `exclude`.

##### Validation strategy
Executed on the probe: with `include = ["src/**/*.rs", "README.md"]`, the stray root file and the tests directory disappeared from the packed list while both binaries and the library remained; reverting to `exclude = ["notes/"]` immediately re-admitted `STRAY.txt`, `LEAKED_SECRET.txt` and `tests/it.rs`, which member 1 caught. Planned: assert in the publish workflow that `cargo package --list` output still contains `LICENSE-MIT` and `LICENSE-APACHE`, via the same expectation file.

##### Confidence & re-verify trigger
High. Re-verify if Cargo changes `include`/`exclude` semantics (the changelog shows active work in this area as recently as Cargo 1.97, 2026-07-09, PR #16891 "cargo-package: Better highlight `--list` for include/exclude") or if the template gains a non-Rust asset tree that globs poorly.

##### Sources
https://doc.rust-lang.org/cargo/reference/manifest.html, section "The `exclude` and `include` fields" (2026-09-10); `rust-lang/cargo` @ master `src/ops/cargo_package/mod.rs:483-488` (2026-09-10); `clap-rs/clap` `Cargo.toml:18-25`, `:125` HEAD (2026-09-10); `GitoxideLabs/gitoxide` `gix/Cargo.toml:11` HEAD (2026-09-10); `BurntSushi/ripgrep` `Cargo.toml:16-24` HEAD (2026-09-10); `serde-rs/serde` `serde/Cargo.toml` and `tokio-rs/tokio` `tokio/Cargo.toml` HEAD (2026-09-10); `GET https://api.github.com/repos/<o>/<r>` for all star counts (2026-09-10); https://github.com/rust-lang/cargo/issues/16872 (closed 2026-04-15, retrieved 2026-09-10); `doc/book/src/CHANGELOG.md` Cargo 1.97 (2026-07-09) PR #16891 (2026-09-10).

### Compatibility

The four members are not independent packages that need a compatibility matrix; three are subcommands of one binary and the fourth is a key that binary reads. They ship together in every Rust toolchain, are versioned together, and are tested together by `rust-lang/cargo`'s own suite — `tests/testsuite/package.rs` exercises `cargo package`, its `--list` output, the packaged manifest normalization and the `include`/`exclude` interaction in one file (8355 lines at master, 2026-09-10).

Beyond that shared-suite argument, the composition was executed as a unit on this item's probe (cargo 1.98.0, macOS, 2026-09-10): one script ran member 1's `--list` diff, member 2's scoped stderr grep and target-set diff, against a manifest carrying member 4's `include` allowlist, and produced `OK: packed content and packaged metadata match expectations` (exit 0) in the healthy state and exit 1 in each of two injected-fault states. Member 3 was exercised far enough to confirm it performs registry resolution but was not run to a green path (no publishable version).

Version matrix for the toolchain floor: member 2's warning text requires cargo ≥ 1.80 (2024-07-25); member 1's offline, pre-publication `--list` requires cargo ≥ 1.94 (2026-03-05); members 3 and 4 have no floor above those. Against the fixed `msrv-policy`, stable minus two minors from the host's 1.98.0 gives 1.96, so every member clears the floor with margin. Shared adopter evidence for the pieces individually: `PyO3/maturin` for `--list` parsing, `clap-rs/clap` and `GitoxideLabs/gitoxide` for `include`.

### Parameters

- `assumes rust-edition = 2024` (fixed, `docs/port/PARAMETERS.md`). Verified compatible: the probe used `edition = "2024"` throughout, and the packaged manifest carried `edition = "2024"` unchanged.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed). Verified compatible: the stack's highest toolchain floor is cargo 1.94 (2026-03-05), below the 1.96 implied floor.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). Every member is a toolchain command plus `diff`, `tar` and `jq`, all present on GitHub-hosted runners for both OSes. The probe ran on macOS; the Linux path is asserted, not executed.
- `assumes license = MIT OR Apache-2.0` (fixed). No dependency is added, so no license is introduced. Cargo itself is dual-licensed — `rust-lang/cargo` carries both `LICENSE-MIT` and `LICENSE-APACHE` at the repository root (`GET https://api.github.com/repos/rust-lang/cargo/contents`, 2026-09-10), although the GitHub API's single `license.spdx_id` field reports only `Apache-2.0`.
- `owns` — none. This item owns no parameter (`## Couplings`, `owns:` empty).
- No `CONFLICT:` lines. No consumed parameter needs to change.

### Migration implications

File-level changes in the template:

| File | Change |
|---|---|
| `Cargo.toml` (workspace root) | Add `include = [...]` under `[workspace.package]`; ensure no `exclude` is declared anywhere |
| `Cargo.toml` (each publishable package) | Add `include.workspace = true` |
| `ci/expected-packed-files.txt` (new) | The sorted expected output of `cargo package --list`, including the four synthesized entries `.cargo_vcs_info.json`, `Cargo.lock`, `Cargo.toml`, `Cargo.toml.orig` |
| `ci/expected-packaged-targets.json` (new) | `jq -S`-normalized `[{name, kind}]` of the targets the published package must declare |
| `ci/check-packed-artifact.sh` (new) | The guard: `--list` diff, scoped stderr grep, extract-and-compare target set. ~25 lines of `bash`, `diff`, `tar`, `jq` |
| `.github/workflows/ci.yml` | New step running the file-set half only, with `--offline --no-verify --locked` (seconds, no network) |
| `.github/workflows/publish.yml` | New steps in the existing verify job: the full guard, then `cargo publish --dry-run`, before the protected-environment publish |

Three operational constraints the implementation must respect, each verified on the probe:
1. Read the packaged manifest from the `.crate` tarball, never from `target/package/<pkg>-<ver>/` — that directory is stale when `--no-verify` is used.
2. Derive the version for the tarball path from `cargo metadata --no-deps --format-version 1 | jq -r '.packages[]|select(.name==$p)|.version'`, not from `cargo pkgid` (which failed with `error: a Cargo.lock must exist for this command` in a lockfile-less checkout).
3. Loop over publishable packages with `-p <pkg>`; `cargo package --workspace --list` concatenates member lists with no separator (rust-lang/cargo#13953). Creating the tarball for a package with unpublished path dependencies requires `--workspace` or publishing in dependency order.

Use `$RUNNER_TEMP` for the extraction directory in the workflow, not `/tmp`.

### Validation strategy

The guard, as executed on the probe (`cargo 1.98.0`, macOS, 2026-09-10), reduced to its essentials:

```bash
cargo package -p "$PKG" --list --no-verify --offline --locked > "$RUNNER_TEMP/files.txt"
diff -u ci/expected-packed-files.txt "$RUNNER_TEMP/files.txt"

cargo package -p "$PKG" 2> "$RUNNER_TEMP/pack.err"
grep -Eq 'ignoring (library|binary) .*is not included in the published package|ignoring `package.build`|the exclude list will be ignored' "$RUNNER_TEMP/pack.err" && exit 1

tar -xzf "target/package/${PKG}-${VER}.crate" -C "$RUNNER_TEMP/x"
cargo metadata --no-deps --format-version 1 --manifest-path "$RUNNER_TEMP/x/${PKG}-${VER}/Cargo.toml" \
  | jq -S -c '[.packages[0].targets[] | {name, kind}] | sort_by(.kind[0], .name)' > "$RUNNER_TEMP/targets.json"
diff -u ci/expected-packaged-targets.json "$RUNNER_TEMP/targets.json"

cargo publish -p "$PKG" --dry-run --locked
```

**Executed results (2026-09-10, on the probe workspace, not on the template):**

| Scenario | Expected | Observed |
|---|---|---|
| Healthy: `include` covers lib + both bins | exit 0 | `OK: packed content and packaged metadata match expectations`, exit 0 |
| `include` narrowed so `src/bin/rsdemo-serve.rs` is not packed | exit 1, all three sub-checks fire | file diff `-src/bin/rsdemo-serve.rs`; grep matched ``warning: ignoring binary `rsdemo-serve` ...`; target diff `-{"kind":["bin"],"name":"rsdemo-serve"}`; exit 1 |
| Denylist manifest plus a stray file | exit 1 on the file set | `+LEAKED_SECRET.txt`, `+STRAY.txt`, `+tests/it.rs`; target diff also flagged `+{"kind":["test"],"name":"it"}`; exit 1 |
| Uncommitted working tree | command fails | `error: 1 files in the working directory contain changes that were not yet committed into git`, exit 101 |
| Unscoped grep (first iteration) | — | Failed a *healthy* build on ``ignoring test `it` ...`. Recorded as the reason the grep is scoped to library/binary/build and the target-set diff is authoritative |

**Planned, not executed:** the same guard as GitHub Actions steps on `ubuntu-latest` and `macos-latest`; a green-path `cargo publish --dry-run` (needs a publishable version and a real registry index); the pull-request placement of the file-set half.

Acceptance criteria for P03 to consider this item satisfied: (1) a deliberately narrowed `include` that drops a binary fails the publish workflow before the upload step; (2) a stray file added to the repository root fails the pull-request CI job; (3) the healthy repository passes both on both runner OSes.

### Confidence & re-verify trigger

**High** for the recommendation as a whole. Every load-bearing claim is either first-party documentation, Cargo's own source and test suite, or a result executed on this host, and the two failure modes the bundle exists to catch were both reproduced and both caught. The residual uncertainty is concentrated in three places, in decreasing order of concern:

1. *The warning strings member 2 greps* are not a stable interface. They are secondary to the target-set diff by design, but they will need re-checking whenever the toolchain floor moves. Watch pull requests touching `prepare_toml_for_publish` in `rust-lang/cargo` `src/workspace/parser/mod.rs`.
2. *`cargo publish --dry-run` was never observed on a green path.* Confirm at the template's first real release.
3. *Only macOS was exercised.* The Linux behavior is asserted from the toolchain's cross-platform guarantee, not observed.

Re-verify triggers: `--message-format json` stabilizing (rust-lang/cargo#15353) — it would let member 1 become a structural comparison and would exactly match ts's shape; rust-lang/cargo#13953 changing `--workspace --list` output; any Cargo release that changes the synthesized-file set (1.81, 1.84 and 1.87 each did); any Cargo release that changes the pruning severity away from warning-only; the template gaining a build script (`package.build` pruning would then apply) or a non-Rust asset tree.

Maintenance state of the stack's provider, `rust-lang/cargo`: **active**. `archived` false, `pushed_at` 2026-09-08T15:46:17Z, `stargazers_count` 15462 (`GET https://api.github.com/repos/rust-lang/cargo`, 2026-09-10); open issues `total_count` 1578 (`GET https://api.github.com/search/issues?q=repo:rust-lang/cargo+is:issue+is:open`, 2026-09-10) — a backlog figure appropriate to the Rust package manager, not an at-risk signal; releases are on the six-week train (changelog entries through Cargo 1.97, 2026-07-09, with the host running 1.98.0 dated 2026-08-05). Issue responsiveness over the 10 most recently opened issues (#17461, #17460, #17459, #17458, #17456, #17455, #17454, #17453, #17449, #17448; `GET https://api.github.com/repos/rust-lang/cargo/issues?state=all&sort=created&direction=desc`, 2026-09-10): 4 received a first comment from an `OWNER`/`MEMBER`/`COLLABORATOR` at 0.11, 0.24, 0.31 and 1.34 days, median 0.28 days over those answered; 6 had no maintainer-associated comment at retrieval, all opened within the preceding three days, so the unanswered count reflects a short window rather than neglect. Advisories: https://rustsec.org/packages/cargo.html (2026-09-10) lists exactly one, CVE-2019-16760 ("Cargo prior to Rust 1.26.0 may download the wrong dependency", dated October 1, 2020) — long patched and irrelevant to any toolchain meeting this template's MSRV floor, so **no open advisory**. Unsafe posture: `unsafe` inside the Cargo binary is out of the template's control and does not enter the template's dependency tree, because this stack adds no dependency — the whole stack's `unsafe` exposure for the shipped artifact is zero. Default features and async-runtime coupling: `inapplicable` — these are toolchain subcommands, not crates the template compiles against, so there are no Cargo features to select and no runtime to couple to. Binary size and compile time: zero added to the template's artifact; the CI cost is one debug verification build of the packaged crate per publish, which the publish workflow already performs.

### Sources

Primary documentation (all retrieved 2026-09-10): https://doc.rust-lang.org/cargo/commands/cargo-package.html · https://doc.rust-lang.org/cargo/commands/cargo-publish.html · https://doc.rust-lang.org/cargo/reference/manifest.html ("The `exclude` and `include` fields") · `rust-lang/cargo` @ master `doc/book/src/reference/publishing.md:90-95` · `rust-lang/cargo` @ master `doc/book/src/CHANGELOG.md`: Cargo 1.80 (2024-07-25) PR #13713, Cargo 1.81 (2024-09-05) PR #13960, Cargo 1.84 (2025-01-09), Cargo 1.86 (2025-04-03) PR #15067, Cargo 1.87 (2025-05-15) PR #15234 and the unstable `--message-format` entry, Cargo 1.94 (2026-03-05) PR #16341, Cargo 1.97 (2026-07-09) PR #16891.

Cargo source and tests, `rust-lang/cargo` @ master (2026-09-10): `src/workspace/parser/mod.rs:3015-3018`, `:3041-3047`, `:3116`, `:3120`, `:3122`, `:3123`, `:3125`, `:3327-3331`; `src/ops/cargo_package/mod.rs:483-488`, `:805-845`; `tests/testsuite/package.rs:3960` (`normalize_case`), `:4946` (`discovery_inferred_lib_excluded`), `:5313` (`discovery_inferred_other_excluded`).

Issues (2026-09-10): https://github.com/rust-lang/cargo/issues/15353 (open) · https://github.com/rust-lang/cargo/issues/13953 (open) · https://github.com/rust-lang/cargo/issues/11666 (closed) · https://github.com/rust-lang/cargo/issues/7938 (closed) · https://github.com/rust-lang/cargo/issues/16872 (closed 2026-04-15).

Figures (2026-09-10): `GET https://api.github.com/repos/rust-lang/cargo` · `GET https://api.github.com/search/issues?q=repo:rust-lang/cargo+is:issue+is:open` · `GET https://api.github.com/repos/rust-lang/cargo/issues?state=all&sort=created&direction=desc&per_page=20` and `/issues/<n>/comments` · `GET https://api.github.com/repos/rust-lang/cargo/contents` · `GET https://crates.io/api/v1/crates/cargo` (`crate.recent_downloads` 721453, `crate.downloads` 7752515, `max_stable_version` 0.99.0, `updated_at` 2026-08-20T17:10:57.036221Z — the library crate, not the shipped toolchain binary, so not representative of adoption) · `GET https://crates.io/api/v1/crates/cargo-diet` and `/versions` · `GET https://api.github.com/repos/the-lean-crate/cargo-diet` · `GET https://crates.io/api/v1/crates/cargo-release` and `/versions` · `GET https://api.github.com/repos/crate-ci/cargo-release` · `GET https://api.github.com/repos/{clap-rs/clap,GitoxideLabs/gitoxide,BurntSushi/ripgrep,PyO3/maturin}` · `GET https://api.github.com/search/code?q=...` · https://rustsec.org/packages/cargo.html, https://rustsec.org/packages/cargo-diet.html (HTTP 404), https://rustsec.org/packages/cargo-release.html (HTTP 404).

Adoption evidence (HEAD, 2026-09-10): `PyO3/maturin` `src/source_distribution/mod.rs:110-122` · `clap-rs/clap` `Cargo.toml:18-25`, `:125` · `GitoxideLabs/gitoxide` `gix/Cargo.toml:11` · `BurntSushi/ripgrep` `Cargo.toml:16-24` · `serde-rs/serde` `serde/Cargo.toml` · `tokio-rs/tokio` `tokio/Cargo.toml` · `crate-ci/cargo-release` `docs/reference.md:59`, `:414-420` · `the-lean-crate/cargo-diet` `README.md`, `Cargo.toml`.

Source repositories at their pins: `ts-launch-blueprint` @ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, `.github/workflows/publish.yml` — the `Assert packed file list (dist + package.json/README/LICENSE/CHANGELOG)` step (F039) and the `Fail on any npm bin auto-correction` step (F078), both read through the pin with `git show`. `py-launch-blueprint` @ `b08bccfb55d05f15e46a83b52c5660b1881d19f5` — not read for this item; the prompt records that py has neither check, and nothing in this item's evidence depends on py's contents. Programme documents: `docs/port/COMMONALITY.md:45` (F039), `:84` (F078), `:226` (F222/R50 boundary); `docs/port/PARAMETERS.md`.

**Method notes.** Endpoints queried: `https://crates.io/api/v1/crates/<name>` and `/versions` (for `cargo`, `cargo-diet`, `cargo-release`, plus three exploratory `?q=` searches that returned no relevant candidates); `https://api.github.com/repos/<o>/<r>`, `/contents`, `/issues`, `/issues/<n>/comments`, `https://api.github.com/search/issues`, `https://api.github.com/search/code`; `https://rustsec.org/packages/<name>.html`; `https://raw.githubusercontent.com/rust-lang/cargo/master/...` for Cargo's source, tests, changelog and book pages; `https://doc.rust-lang.org/cargo/...` for the Cargo Book. Empirical results come from a throwaway two-crate workspace built for this item on the verification host (`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS darwin 25.4.0), not from any template repository; no repository was scaffolded and nothing outside the run directory and a scratch directory was modified. **Could not verify:** (1) a green-path `cargo publish --dry-run` — the probe's dry run reached the crates.io index and then failed on a deliberately unpublished path dependency, so registry resolution is confirmed but a successful end-to-end dry run is not; (2) any behavior on `ubuntu-latest` — every empirical result is macOS-only, and the Linux claim rests on the toolchain's cross-platform guarantee; (3) issue responsiveness for `cargo-release` — not computed, since the crate was excluded before popularity weighing; for `cargo-diet` only one issue (#84, opened 2026-08-16) fell in the recent window and it carried no maintainer-associated comment, an insufficient sample for a median; (4) the first attempt at `https://api.github.com/repos/rust-lang/cargo` over plain `curl` returned null fields (unauthenticated rate limiting) and one `search/code` call returned an explicit rate-limit message — both were re-run successfully through `gh api`, and every figure reported above comes from a successful call; (5) an initial `WebFetch` summary of the Cargo changelog attributed PR #15371 and #15325 to `cargo package` behaviors, which the raw changelog contradicted — those attributions were discarded and every changelog citation above was read from `doc/book/src/CHANGELOG.md` directly.
