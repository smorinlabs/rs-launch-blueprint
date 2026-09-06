### Landscape

R41, pattern; actor `research-codex-2026-09-05T160304Z-1e904d50d29e`. Revision after the Terra evidence review, 2026-09-05. Decision: adopt a conditional pre-commit check using `cargo metadata --locked --format-version=1`, with an explicitly new prototype that guards the Git index against unstaged Cargo inputs. The measured evidence and its limits are below.

The category is **manifest/lockfile consistency at the commit boundary**. “Fresh” means that Cargo can use the existing resolution for the current manifests; it does not mean every dependency is the newest release. The landscape was mapped before selecting a mechanism:

| Bin | Alternatives found | Authority and limits |
|---|---|---|
| Built-in / first-party toolchain | Metadata resolution with `--locked`; locked `check` or `build`; conservative `update --workspace --locked`; regeneration with `generate-lockfile --locked`; `update --locked --dry-run` | Cargo owns these semantics. The resolver and command manuals distinguish consistency from dependency upgrading. [Cargo resolver][RES], [update][UPD], [generate-lockfile][GEN] (retrieved 2026-09-05). |
| Established production practices | Dedicated CI lockfile checks; locked compilation; staged-file hook triggers | Warp uses metadata; clap uses conservative workspace update; Cargo uses a package-targeted update. Git supplies the hook lifecycle. Python supplies the staged-trigger precedent. This survey does **not** establish that the combined Rust hook and parity guard is an industry standard. [Warp workflow][WARP], [clap workflow][CLAP], [Cargo workflow][CARGO], [Python snapshot][PY] (retrieved 2026-09-05). |
| Up-and-comers | New repository-local wrappers or staged-snapshot checks | No maintained external implementation of the exact proposed trigger plus parity guard was established. The retained [hook prototype][HOOK] is newly authored research code, not evidence of external adoption (2026-09-05). |

Authority is established through Cargo's command reference and resolver documentation, the Cargo team's dated [lockfile-guidance article][GUIDE] of 2023-08-29, Git's [hook][GIT] and [diff][DIFF] manuals, and maintainers' actual workflows. These sources cover language semantics, version-control semantics, and practice independently. Current pages were retrieved on 2026-09-05.

The practice sample deliberately includes a newer application codebase alongside toolchain infrastructure. Warp's [README snapshot][WREADME] documents a distributed application, an active contribution process, and OpenAI's founding sponsorship of its open-source repository. That establishes application relevance and institutional backing without inventing popularity figures. Cargo's [README snapshot][CREADME] identifies the Cargo team as the toolchain binary's maintainer. clap's standing is evidenced by Cargo itself declaring clap dependencies in [its manifest snapshot][CMANIFEST], rather than by an unsupported popularity adjective. The workflows show different consistency mechanisms; none proves pre-commit latency. All three projects are assessed as `active` from their maintained documentation/workflows; this is a qualitative rubric assessment, not an issue-responsiveness measurement (retrieved 2026-09-05).

Source precedent was re-read from both pinned Git trees. Python's [retained `lefthook.yml`][PY], lines 126–131, runs `uv lock --check` when `pyproject.toml` or `uv.lock` is staged. TypeScript's [retained `lefthook.yml`][TS] contains format, size, lint, typecheck, commit-message and optional pre-push test jobs, with no dedicated lockfile check. The [retained decisions document][TSDEC] discusses lockfile/CI policy but does not establish this hook. The previously inaccessible TypeScript GitHub citation is replaced by locally retrieved immutable Git content; the exact retrieval command is under Validation strategy (retrieved 2026-09-05).

### Principles and implementation

F171 is the ledger feature “dependency-manifest lockfile-freshness check hook.” The required agreement is at the capability and policy levels: catch a resolution-changing manifest edit before committing it, preserve the intended commit contents, and keep routine local feedback inexpensive. The Python/TypeScript disagreement leaves adoption open; it does not select a Cargo subcommand. The hook manager remains R37's responsibility. [Binding prompt](../inputs/prompt.md), [Python][PY], [TypeScript][TS] (read 2026-09-05).

The proposed pattern is **conditional Cargo resolution with an index-parity guard**. The Git index is the content Git will commit. Cargo reads files in the working directory. The prototype first detects staged Cargo resolution inputs; it then refuses relevant unstaged or untracked inputs before invoking the Cargo resolver. In a repository-contained workspace this prevents a repaired but unstaged lockfile from making the check pass for a broken commit. This specific failure was reproduced and prevented on both tested toolchains. [Executed records][E], labels `unstaged-lock-false-pass-control` and `unstaged-lock-commit` (2026-09-05).

Observable acceptance criteria:

- A staged manifest that requires a different lockfile fails without writing the lockfile.
- Staging its repaired lockfile makes the commit succeed.
- Relevant worktree/index mismatches fail before Cargo is invoked.
- A member manifest triggers the root workspace check; the root manifest and lockfile are covered too.
- Unrelated commits skip Cargo. A manifest comment that requires no new resolution is valid.
- Failure keeps Cargo's diagnostic and distinguishes a required lock update from a network or cache failure.
- The command works at the required minimum supported Rust version, abbreviated MSRV. The guard was also executed in the Linux leg on both the floor and stable toolchains; the Lima VM's `aarch64` architecture is not the `x86_64` architecture of `ubuntu-latest`.

The realistic retained [workspace manifest][MANIFEST] and [lockfile][LOCK] contain three members: a clap CLI, a serde/thiserror library, and an axum/Tokio HTTP service with tracing and a tower-based route test. The resolved metadata contains **88 packages: 85 registry packages and 3 workspace members**. Registry versions and declared Rust requirements are retained in [the package inventory][PACKAGES]. This is a representative workload for R41, not a selection of application libraries for other research items. [Measured workload summary][S] (2026-09-05).

The implementation composes Git's conditional trigger, the [Bash prototype][HOOK], and Cargo's resolver. The command body is:

```sh
cargo metadata --locked --format-version=1 >/dev/null
```

Metadata returns JSON on success; the hook discards it and retains stderr. The stale-manifest case returned Cargo status `101`, while the actual blocked `git commit` returned `1`. The diagnostic begins `error: cannot update the lock file` and identifies the lockfile and `--locked`; the full paths and exact output are retained in [floor stderr][STALE] and [stable stderr][STALE98]. Neither failure changed the lockfile hash. [Executed records][E] (2026-09-05).

The architectural alternatives are materially different:

| Alternative | What it checks | Cost or limitation |
|---|---|---|
| Metadata plus conditional parity guard | Cargo resolution and whether relevant worktree files match the intended commit | No application compilation; can fetch registry data and crate sources. Guard is new research code. |
| Conservative `cargo update --workspace --locked` plus the same guard | Workspace lock consistency while retaining existing non-workspace entries where possible | Maintained clap precedent; does not produce the resolved-package JSON or require the same source-fetch work as metadata. A credible runner-up. |
| Locked `check` or `build` | Resolution plus compilation; build also performs code generation/linking | Adds compiler, build-script and source failures; these can justify a later check tier. |
| Construct and check an isolated staged snapshot | Resolution of a copied index tree | Supports partial staging more naturally, but needs a policy for workspace paths, Cargo config, symlinks and snapshot cost. No maintained complete implementation was established. |
| CI/pre-push only | Consistency at a later boundary | Avoids local hook latency but loses the early failure that F171 is intended to provide. |

Command distinctions follow [Cargo check][CHECK], [build][BUILD] and [update][UPD] (retrieved 2026-09-05). The retained experiments independently test the first three classes' stale-lock behavior; [supplemental records][O] show locked check, build and workspace update all returning `101` without a lockfile write (2026-09-05).

**Reference-implementation gap:** Warp establishes the metadata command and remediation-message practice at CI tier. It does not establish the staged trigger, the index-parity guard, or the complete proposed hook. No maintained external reference for that composition was found. [`hook.sh`][HOOK] and [`measure.rb`][HARNESS] now make the proposed composition executable and reviewable, but do not substitute for external maintenance evidence. R37's final manager integration remains untested (2026-09-05).

The prototype is deliberately conservative: it matches repository Cargo manifests, locks and `.cargo/config` or `.cargo/config.toml`, and may reject unrelated untracked fixture manifests. It assumes workspace/path dependencies are contained in the repository. It does not isolate concurrent edits, symlink targets, external path dependencies or user Cargo configuration. These limits are explicit in [fixture documentation][FREADME]; an implementation with those inputs needs a corresponding scope policy and tests (2026-09-05).

Fitness review, before weighing practice:

| Candidate | Gate 1: license | Gate 2: MSRV | Gate 3: RustSec / unsafe | Gate 4: platforms | Gate 5: features / runtime | Gate 6: size / compilation |
|---|---|---|---|---|---|---|
| Metadata command | No crate is added; invoking installed Cargo adds no library licensing requirement | Recommended command passes with Cargo/Rust 1.96.0; host dependency graph also passes floor compilation | Crate advisory metric is `inapplicable`; no new runtime dependency or authored unsafe Rust in the hook; Cargo itself is not asserted unsafe-free or independently security-audited | Executed on macOS arm64 and Lima Ubuntu `aarch64` at floor and stable; the `ubuntu-latest` `x86_64` runner is not reproduced | No new crate defaults or async coupling; metadata does resolve the application's selected/default features | No delivered binary growth or application compilation; cache downloads and process cost measured |
| `update --workspace --locked` | Same invocation-only scope | Consistent and stale cases run with Cargo 1.96.0 and 1.98.0 | Same toolchain scope | macOS cases executed; Ubuntu precedent in clap | No new crate defaults or async coupling | No application compilation; registry access still possible |
| `check --locked` | Same invocation-only scope | Entire fixture checked with floor 1.96.0; stale case tested | Same toolchain scope; compiling the application additionally executes applicable build scripts/proc macros | macOS check executed; Linux fixture build unrun | Application feature/build settings apply | Builds compiler artifacts; higher CPU/disk work |
| `build --locked` | Same invocation-only scope | Stale failure tested at floor; a successful full build was not run | Same toolchain scope and build-script caveat | macOS failure path only; successful OS matrix unverified | Application feature/build settings apply | Code generation/linking beyond check; not benchmarked |
| `generate-lockfile --locked` and `update --locked --dry-run` | Same invocation-only scope | Stale cases run at both versions | Same toolchain scope | macOS cases executed; Linux exact probes unrun | No introduced crate defaults or async coupling | Resolver work without application compilation; fail the semantic suitability tests below |
| Repository Bash guard | Newly authored repository code under `MIT OR Apache-2.0` | No Rust compilation; tested while invoking the actual floor toolchain | No Rust dependency tree; correctness of Git/shell handling is the relevant risk | Executed inside macOS and Lima Ubuntu Git commits; the Lima VM is `aarch64`, while `ubuntu-latest` is `x86_64`. Windows shell port is not promised | No new runtime beyond Git, Bash and the installed Cargo | Process overhead included in commit measurements |

Evidence: [main records][E], [supplemental records][O], [floor compilation output][COMPILE], and the retained [Linux leg][LINUX], plus [Warp workflow][WARP] and [clap workflow][CLAP], all retrieved/executed 2026-09-05. There is no blanket “all gates pass” claim. macOS and Lima Ubuntu evidence are direct; the exact GitHub `ubuntu-latest` `x86_64` runner remains unverified. Gate 2 establishes this fixture's graph, not every future template dependency or every target-specific transitive crate.

### Dominant choice

Use the conditional metadata check with an explicit policy for staged/worktree parity. On this realistic workspace, warm full commits were short enough to support the pre-commit tier, while stale dependency changes and partially staged repairs were rejected. This is a fit judgment from the measured workload, not a claim of ecosystem dominance or universally bounded latency. The externally maintained reference covers only the Cargo command; the combined guard remains a tested new prototype. [Measured summary][S], [behavioral records][E], [Warp workflow][WARP] (2026-09-05).

### Options

The command manuals and workflows are living documents without a verified publication/update date. Their retrieval date is supplied below rather than mislabelled as the latest authoritative write-up.

| Name | Where documented | Verified practice | Authoritative date |
|---|---|---|---|
| Conditional metadata resolution | [Cargo metadata][META]; [new guard][HOOK] | Warp CI demonstrates command/message only | Living source undated; retrieved 2026-09-05 |
| Conservative workspace lock check | [Cargo update][UPD] | [clap lockfile job][CLAP]; Cargo's related [package-targeted job][CARGO] | Living sources undated; retrieved 2026-09-05 |
| Locked compilation, `check` / `build` | [check][CHECK], [build][BUILD] | clap uses locked check in its minimal-versions lane; [retained workflow][CLAPSNAP]. No rustls/macOS claim retained | Living sources undated; retrieved 2026-09-05 |
| Regeneration or broad update dry run | [generate-lockfile][GEN], [update][UPD] | No exact maintained freshness-hook adopter established | Living sources undated; retrieved 2026-09-05 |
| Staged snapshot plus Cargo | Git's [index/diff semantics][DIFF]; proposed alternative | No maintained full implementation established | Research proposal, 2026-09-05 |
| Later-tier-only consistency | [Cargo team's guidance][GUIDE], [Cargo CI][CARGO] | Dedicated Cargo/clap CI jobs exist; their existence does not prove absence of local hooks | Team article 2023-08-29; workflow undated, retrieved 2026-09-05 |

### Excluded by gate

`cargo metadata --locked --no-deps --format-version=1` fails the freshness acceptance criterion: it returned `0` on the exact stale manifest for which full metadata returned `101`. `cargo update --locked --dry-run` also returned `0` with the stale lockfile, printing a dry-run warning and leaving the bytes unchanged. An unchanged file and success exit from a dry run do not prove consistency. Both false-pass controls were observed at the floor and stable versions. [Main records][E], [supplemental records][O] (2026-09-05).

`cargo generate-lockfile --locked` rejected the stale fixture, but its documented operation re-resolves to latest permitted versions. It can therefore reject an otherwise compatible existing lockfile merely because newer allowed versions exist. That is a semantic mismatch, not a license/MSRV failure; the second scenario is documented behavior, not a performed probe. [Cargo generation manual][GEN] (retrieved 2026-09-05).

Locked check/build are valid consistency mechanisms but are not selected as the dedicated hook because they add compilation work. Conservative workspace update is **not excluded**: the previous report overstated its update risk. `--workspace` intentionally limits updates, and `--locked` protects writes on that command too. [Cargo update][UPD], [floor compilation][COMPILE], [supplemental probes][O] (2026-09-05).

### Up-and-comers

No dedicated third-party crate was shortlisted for this exact consistency check. Adding a tool solely to wrap Cargo lacks demonstrated benefit over a small helper. The new [guard prototype][HOOK] supplies reproducible evidence for one composition; its maintenance state is `inapplicable` under the external-project rubric because it has no external release/adoption history. A mature, independently maintained implementation that handles partial staging and workspace boundaries would merit re-evaluation (research assessment, 2026-09-05).

### Fit for this template

For the **CLI**, the fixture exercises clap argument parsing and serializes a result from the shared library. A synchronized application lockfile supports repeatable development and release builds. The CLI source and its real dependencies participate in the floor compilation. [CLI manifest](fixture-r41/crates/cli/Cargo.toml), [CLI source](fixture-r41/crates/cli/src/main.rs), [compilation][COMPILE] (2026-09-05).

For the **library**, the shared root lockfile supports the repository's tests. It does not impose this lockfile on downstream library consumers or replace testing dependency compatibility. The Cargo team's guidance permits committed library lockfiles and recommends deliberate dependency-update testing. [Library source](fixture-r41/crates/core/src/lib.rs), [Cargo team guidance][GUIDE] (retrieved 2026-09-05).

For the **web service**, axum routing, Tokio execution, structured tracing and a tower route-test target supply a realistic HTTP dependency graph. Metadata performs no server startup; the floor check compiles all workspace targets, including the test target. No live server or HTTP test was run for this lockfile study. [Web manifest](fixture-r41/crates/web/Cargo.toml), [web source](fixture-r41/crates/web/src/main.rs), [compilation][COMPILE] (2026-09-05).

The following macOS figures come from the retained [summary endpoint][S] and its [raw command records][E], recorded 2026-09-05 on **macOS 26.4, arm64**. Hardware model/RAM and peak memory were unavailable because sandboxed `sysctl` access was denied. The Linux acceptance outcomes and its short guard timings are reported separately below.

| Operation | Cargo 1.96.0 floor: wall seconds | Cargo 1.98.0: wall seconds | Samples per toolchain |
|---|---:|---:|---:|
| Metadata with empty Cargo home | 2.246 | 2.020 | 1 cold invocation |
| Metadata with warmed Cargo home | median 0.136; range 0.126–0.153 | median 0.125; range 0.094–0.157 | 10 warm invocations |
| Actual staged-manifest `git commit` with guard, empty Cargo home | 3.581 | 2.169 | 1 cold commit |
| Actual staged-manifest `git commit` with guard, warmed Cargo home | median 0.277; range 0.257–0.297 | median 0.210; range 0.197–0.218 | 5 warm commits |
| Commit of repaired dependency edge and lockfile | 0.206 | 0.153 | 1 warm commit |
| Unrelated commit, Cargo deliberately unavailable | 0.054 | 0.150 | 1 skip-control commit |
| Linux Lima acceptance: clean staged-manifest commit / stale direct guard / stale guarded commit | 0.05 / 0.03 / 0.03; exits 0 / 101 / 1 | 0.05 / 0.03 / 0.03; exits 0 / 101 / 1 | 1 case each; `aarch64` |

The Linux acceptance leg used the same retained fixture contents in temporary Git repositories. Its `uname -a` was `Linux lima-ubuntu 6.17.0-40-generic #40-Ubuntu SMP PREEMPT_DYNAMIC Fri Jun 19 16:24:16 UTC 2026 aarch64 GNU/Linux`. The clean staged-manifest commit returned `0` for both `rustc 1.96.0` and `rustc 1.98.1`; the stale direct guard returned `101`, the corresponding guarded `git commit` returned `1`, and the lockfile hash remained `6205ba2b2fd07b45bec580c8ac91ddea63cf74182b93840bfe1c1bf614c972d0` before and after for each. Timed observations were floor: clean commit **0.05 seconds**, stale direct guard **0.03 seconds**, stale guarded commit **0.03 seconds**; stable: **0.05**, **0.03**, and **0.03 seconds**, respectively. The floor clean case populated the VM Cargo cache; stable then used that cache, so these are acceptance evidence rather than a controlled Linux performance comparison. [Linux leg][LINUX] (2026-09-05).

Cold means a newly created empty `CARGO_HOME`, including no registry index, crate archives or unpacked sources. It does not mean cold OS/DNS/CDN caches. Each command and commit series uses a separate Cargo home; the full workload and downloaded sources remain retained. Staged-manifest timing commits append a harmless member-manifest comment, which triggers full graph resolution. The separate repaired-dependency case adds `serde_json` to the library and stages its new lockfile. Git staging happens outside the measured interval. Signing is disabled. No other hooks are installed in these isolated fixture repositories. [Harness][HARNESS], [fixture notes][FREADME], [records][E] (2026-09-05).

Instrumentation uses Ruby's monotonic clock around the child process plus `/usr/bin/time -p` for CPU seconds. The measured interval includes process startup and the timing wrapper. Median warm CPU consumption was **0.11 seconds** for metadata on either toolchain, and **0.20 / 0.18 seconds** for the full commit on floor/stable respectively. Sequential warm metadata throughput, computed as sample count divided by summed wall time, was **7.26 / 8.13 invocations per second**. This is harness throughput, not an application benchmark. The floor cold-target compile check took **10.067 wall seconds**, with **32.21 user plus 5.39 system CPU seconds**; build parallelism means CPU time can exceed elapsed time. Peak RSS was not measured. [Summary][S], [raw records][E], [compiler output][COMPILE] (2026-09-05).

**Tier conclusion:** for this representative graph, the measured warm commit cost supports a conditional pre-commit check. The cold path visibly incurs dependency downloads and took several seconds on this connection. A slow registry or cold larger graph can take longer. Keep it conditional, prefetch during ordinary project setup, and retain the later authoritative gate. Re-evaluate the tier on the actual template if its measured local cost is unacceptable. This is the report's recommendation from the workload above, not a promised latency bound (2026-09-05).

### Recommendation

Adopt `cargo metadata --locked --format-version=1` at pre-commit for staged workspace manifests or the lockfile. The proposed helper also covers Cargo config changes because they can affect resolution. Preserve default Cargo resolution settings; omit `--no-deps`, `--dry-run` and an automatic `--offline` fallback. A cold offline failure means validation could not finish, not necessarily that the lockfile is stale. [Prototype][HOOK], [metadata manual][META], [Cargo resolver][RES], [false-pass probes][O] (2026-09-05).

Choose a documented parity policy for the implementation. The retained prototype rejects relevant partial staging and untracked manifests. If partial staging must be supported, implement and validate a staged snapshot with explicit path/config handling. State clearly that the external reference covers the Cargo command only; neither Warp nor this new fixture establishes an externally maintained full guard.

The prototype preserves Cargo's stderr/status and adds:

```text
FAIL: Cargo lockfile validation could not complete; see Cargo diagnostics above.
If Cargo requires a lockfile update, run cargo metadata --format-version=1, review Cargo.lock, and stage it with the intended manifests. For cache/network errors, fetch dependencies and retry.
```

This avoids labelling every Cargo failure “out of date.” The repair command was executed successfully in the fixture; the commit remained blocked until its new lockfile was staged. [Hook implementation][HOOK], [repair and partial-staging records][E] (2026-09-05).

### Ranked runner-up

First runner-up: `cargo update --workspace --locked` with the same trigger and parity policy. clap maintains this exact command in a dedicated lockfile job, and the fixture verifies its consistent success and stale rejection at both toolchains. It wins if cold metadata source fetching is an unacceptable local cost and measured workspace-update behavior meets the final workspace's consistency contract. Its warm measurements here are insufficient to rank cold performance. [clap CI][CLAP], [Cargo update][UPD], [records][E], [option probes][O] (2026-09-05).

Second runner-up: locked `cargo check --workspace --all-targets` if compilation already belongs in the selected hook tier and sharing that check avoids redundant work. Its measured floor run validates the graph but incurs compiler work beyond the freshness requirement. [Floor compilation][COMPILE] (2026-09-05).

### Tradeoffs

Metadata costs source downloads and produces JSON that a pure freshness hook discards. Conservative workspace update offers a stronger external dedicated-lock-job precedent and potentially lower cold source-fetch cost. Metadata is selected because its complete resolution path is documented, independently exercised here, and inexpensive when warm for this workload. It does not replace a compile check, dependency security scan, latest-dependency canary or downstream-library compatibility check. [Measured evidence][E], [Cargo team guidance][GUIDE], [Cargo update][UPD] (2026-09-05).

Rejecting partial staging simplifies the implementation at a usability cost. An isolated staged snapshot could preserve partial-staging workflows, but needs broader path and configuration handling. A later-tier-only gate avoids local latency and sacrifices immediate commit feedback. The prototype is a reviewable proposal with documented scope; the full manager integration and exact `ubuntu-latest` `x86_64` reproduction remain outstanding. [Prototype documentation][FREADME], [source precedent][PY] (2026-09-05).

### Parameters

`owns` none; `consumes` none in R41's registry coupling. The following fixed owner values remain binding:

- `assumes rust-edition = 2024`.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.
- `assumes license = MIT OR Apache-2.0`.
- `assumes target-os-matrix = ubuntu-latest, macos-latest`.

For this requested stable **1.98** baseline, subtracting **2 minor versions** yields floor **1.96**, tested here using **1.96.0**. Every fixture member inherits `rust-version = "1.96"` and edition `2024`. Homebrew supplied Cargo/Rust **1.98.0**. The installed rustup alias `stable` actually resolved to Cargo **1.94.0**, so the harness used explicit binaries and compiler paths instead of that alias. This is environment drift, not a request to change the fixed policy. [Input parameters](../inputs/parameters.json), [manifest][MANIFEST], [toolchain records][E] (2026-09-05).

No `CONFLICT:` or `BASELINE-REVIEW:` line is emitted. F171 remains an open divergent feature whose recommendation is now backed by revised evidence. No ledger, owner parameter, or R37 manager decision was changed.

### Migration implications

Proposed template changes, not applied to template source in this run:

| File / integration surface | Required change |
|---|---|
| `scripts/check-cargo-lock.sh` | Adapt the retained prototype; establish its repository/workspace scope and partial-staging policy. |
| R37-selected hook configuration | Run the helper at pre-commit; include root/member manifests, lockfile and relevant Cargo config triggers, including deleted paths. |
| `Cargo.toml` and `Cargo.lock` | Keep the root lockfile tracked, declare the owner-fixed MSRV and use the workspace's chosen resolver. |
| Contributor documentation | Explain partial-staging refusals, normal lockfile repair, and cold-cache/network failures. |
| Focused integration tests | Carry the stale/repair, partial-staging, member-trigger, unrelated-skip and full-tree cases to both CI operating systems. |
| Existing full-tree verification entry point | Provide an explicit unconditional mode such as the prototype's `--all` so a clean CI index does not skip verification; R37 owns orchestration. |

These are proposed adaptations of [the retained helper][HOOK] and [acceptance harness][HARNESS], not claims of a completed template integration (2026-09-05).

### Validation strategy

The retained experiment can be reproduced from this run directory. These are the executed harness commands; each new run receives its own output directory:

```sh
ruby raw/fixture-r41/measure.rb
ruby raw/fixture-r41/summarize.rb raw/fixture-r41/run-20260905-38559-1er1lv7
ruby raw/fixture-r41/probe-options.rb raw/fixture-r41/run-20260905-38559-1er1lv7
```

For a fresh reproduction, pass the new directory printed by `measure.rb` to the other scripts. The first command runs the real Cargo and Git probes. The other commands derive statistics and exercise alternative Cargo commands. [Harness][HARNESS], [summary generator](fixture-r41/summarize.rb), [option harness](fixture-r41/probe-options.rb) (2026-09-05).

A representative directly executed MSRV-boundary invocation, with the same cache and compiler used in the accepted run, is:

```sh
cd raw/fixture-r41
CARGO_HOME="$PWD/run-20260905-38559-1er1lv7/floor-1.96.0-cold-home" \
RUSTC=/Users/stevemorin/.rustup/toolchains/1.96.0-aarch64-apple-darwin/bin/rustc \
/usr/bin/time -p \
/Users/stevemorin/.rustup/toolchains/1.96.0-aarch64-apple-darwin/bin/cargo \
metadata --locked --format-version=1 >/dev/null
```

The floor graph build used the same explicit Cargo/compiler pair and `cargo check --workspace --all-targets --locked`. Successful metadata is not itself proof that code compiles; this separate successful check supplies that evidence for the macOS fixture. The full command arrays, actual environment overrides and working directories are retained for every sample. [Executed records][E], [floor compiler output][COMPILE] (2026-09-05).

| Executed case, both Cargo versions unless noted | Observed result |
|---|---|
| Synchronized cold and warm metadata | Cargo exit 0 |
| Real staged member-manifest commits with guard | Git exit 0; timings above |
| Added `serde_json` edge in staged library manifest, stale lock | Metadata exit 101, Git commit exit 1; lock bytes preserved |
| Same stale manifest with `--no-deps` | Cargo exit 0: negative control exposes false assurance |
| Lock regenerated but not staged | Bare metadata exit 0; guarded commit exit 1 |
| Repaired manifest and lockfile both staged | Commit exit 0 |
| Staged lockfile with unstaged member manifest | Commit exit 1 |
| Unrelated staged file with `R41_CARGO=/nonexistent/r41-cargo` | Commit exit 0 with skip diagnostic, proving Cargo was not needed |
| `check`, `build`, workspace update and regeneration with `--locked` against stale graph | Cargo exit 101, lock bytes unchanged |
| Broad update with `--locked --dry-run` against stale graph | Cargo exit 0, lock bytes unchanged: false-pass control |
| All fixture targets checked at MSRV floor on macOS | Cargo exit 0 |
| Linux Lima acceptance leg: clean staged-manifest guard at floor and stable; stale-lock direct guard and guarded commit | Clean Git commits exit 0; stale direct guards exit 101; stale guarded commits exit 1; lockfile bytes unchanged |

Evidence endpoints: [main results][E], [supplemental results][O], and [Linux leg][LINUX], executed 2026-09-05. The mandatory stale-manifest inverse and staged-commit timing checks are now executed and retained on macOS; the Linux leg adds the clean staged trigger and stale-lock rejection at both toolchains. Remaining integration work is the actual R37 manager, the exact GitHub `ubuntu-latest` `x86_64` environment, and boundary cases outside the prototype's stated repository-contained scope.

The Linux command was run through the mounted fixture directory with the requested VM entry point:

```sh
limactl shell ubuntu -- bash -lc 'source $HOME/.cargo/env; cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R41/2026-09-05T160304Z-1e904d50d29e/raw/fixture-r41 && <the recorded guard loop>'
```

For each `1.96.0` and `stable` toolchain, the recorded loop copied the fixture into a temporary Git repository, installed `hook.sh` as `.git/hooks/pre-commit`, staged a harmless member-manifest trigger, and ran `/usr/bin/time -p git commit -qm linux-positive`. It then staged `serde_json.workspace = true` in the library without changing `Cargo.lock`, ran `/usr/bin/time -p env R41_CARGO="$cargo_bin" bash "$fixture/hook.sh"`, and ran `/usr/bin/time -p git commit -qm linux-stale`. The resulting output and statuses are retained in [Linux leg log][LINUX].

The retained [Linux leg log][LINUX] records `uname -a` as `Linux lima-ubuntu 6.17.0-40-generic #40-Ubuntu SMP PREEMPT_DYNAMIC Fri Jun 19 16:24:16 UTC 2026 aarch64 GNU/Linux`, `rustc 1.96.0 (ac68faa20 2026-05-25)` and `rustc 1.98.1 (48a229cea 2026-09-01)`, the clean commit exit `0` for each, stale direct-guard exit `101` for each, stale guarded-commit exit `1` for each, and unchanged lockfile hashes. The temporary Git repositories copied the retained three-member, 88-package fixture; the floor populated the VM Cargo cache, so those Linux times are not a cross-toolchain benchmark.

The pinned TypeScript evidence was retrieved without relying on its inaccessible web URL:

```sh
git -C /Users/stevemorin/c/ts-launch-blueprint show \
  cb1cbcb2e88b898e8c081b0abbfabc1630079c00:lefthook.yml
git -C /Users/stevemorin/c/ts-launch-blueprint show \
  cb1cbcb2e88b898e8c081b0abbfabc1630079c00:docs/port/TS_PORT_DECISIONS.md
```

The exact stdout is retained as [TypeScript hooks][TS] and [TypeScript decisions][TSDEC], and the command/exit records are in [the evidence log][E] (2026-09-05). All rustls citations and platform-practice claims have been removed.

### Confidence & re-verify trigger

High confidence in the tested Cargo consistency behavior, the MSRV-floor macOS command, and the reproduced staged-repair hazard. Moderate confidence in the pre-commit tier for the eventual template: this is a realistic but bounded dependency graph, with single cold samples, one host, and no full hook suite. The measured version difference should not be interpreted as a Cargo release speed comparison because the host workload and cache history were not controlled for that purpose. [Measured summary][S], [records][E] (2026-09-05).

Linux applicability is now directly evidenced by the retained Lima Ubuntu leg: the clean staged trigger and stale-lock negative control passed their expected statuses at `rustc 1.96.0` and `rustc 1.98.1`. The VM is `aarch64`, so the exact `ubuntu-latest` `x86_64` runner and its GitHub-hosted environment remain unverified; the local host is macOS, not a claim of an executed `macos-latest` GitHub Actions job. Warp is only a command/message reference, and no maintained external full-guard reference was established. [Linux leg][LINUX], [Warp source][WARP], [retained workflow][WARPSNAP], [Cargo workflow][CARGO], [clap workflow][CLAP] (retrieved 2026-09-05).

Re-verify at a policy-authorized MSRV bump, Cargo resolver/lockfile change, new workspace or external path layout, private registry/configuration change, manager integration, or observed unacceptable commit latency. The acceptance target remains actual commit contents and an unchanged lockfile, not merely a zero status from some Cargo command.

### Sources

Reference keys identify exact external endpoints or retained local evidence. All retrievals and experiments in this revision are dated **2026-09-05**. Local measured figures use the retained JSON endpoints rather than linking to documentation as if it measured latency.

[E]: fixture-r41/run-20260905-38559-1er1lv7/results.json
[S]: fixture-r41/run-20260905-38559-1er1lv7/summary.json
[O]: fixture-r41/run-20260905-38559-1er1lv7/options-20260905-80719-vb0l9h/results.json
[FREADME]: fixture-r41/README.md
[HARNESS]: fixture-r41/measure.rb
[HOOK]: fixture-r41/hook.sh
[MANIFEST]: fixture-r41/Cargo.toml
[LOCK]: fixture-r41/Cargo.lock
[PACKAGES]: fixture-r41/run-20260905-38559-1er1lv7/floor-1.96.0-packages.json
[COMPILE]: fixture-r41/run-20260905-38559-1er1lv7/077-floor-1.96.0-compile-boundary.stderr
[STALE]: fixture-r41/run-20260905-38559-1er1lv7/062-floor-1.96.0-stale-command.stderr
[STALE98]: fixture-r41/run-20260905-38559-1er1lv7/110-stable-1.98.0-stale-command.stderr
[PY]: fixture-r41/run-20260905-38559-1er1lv7/010-py-lefthook.stdout
[TS]: fixture-r41/run-20260905-38559-1er1lv7/011-ts-lefthook.stdout
[TSDEC]: fixture-r41/run-20260905-38559-1er1lv7/012-ts-decisions.stdout
[WREADME]: fixture-r41/run-20260905-38559-1er1lv7/018-warp-readme.stdout
[CREADME]: fixture-r41/run-20260905-38559-1er1lv7/017-cargo-readme.stdout
[CMANIFEST]: fixture-r41/run-20260905-38559-1er1lv7/016-cargo-manifest.stdout
[WARPSNAP]: fixture-r41/run-20260905-38559-1er1lv7/013-warp-ci.stdout
[CLAPSNAP]: fixture-r41/run-20260905-38559-1er1lv7/014-clap-ci.stdout
[META]: https://doc.rust-lang.org/cargo/commands/cargo-metadata.html
[RES]: https://doc.rust-lang.org/cargo/reference/resolver.html
[UPD]: https://doc.rust-lang.org/cargo/commands/cargo-update.html
[GEN]: https://doc.rust-lang.org/cargo/commands/cargo-generate-lockfile.html
[CHECK]: https://doc.rust-lang.org/cargo/commands/cargo-check.html
[BUILD]: https://doc.rust-lang.org/cargo/commands/cargo-build.html
[GUIDE]: https://blog.rust-lang.org/2023/08/29/committing-lockfiles/
[GIT]: https://git-scm.com/docs/githooks
[DIFF]: https://git-scm.com/docs/git-diff
[WARP]: https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L561-L606
[CLAP]: https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml#L195-L206
[CARGO]: https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L100-L106
[LINUX]: fixture-r41/linux-leg.log

Crate download totals, release figures, reverse dependencies, crate advisory counts and crate issue-response medians are `inapplicable` to this pattern selection because no separately installed crate is recommended. Fixture libraries are a retained workload, not researched winners for other items. No GitHub stars, issue counts or API maintenance figures are asserted. Default features and graph requirements for the workload are recoverable from its manifests and full metadata captures.

The fixture is retained locally under `raw/fixture-r41/`. The repository's existing `research/runs/*/*/raw/fixture-*/` ignore rule excludes it from ordinary Git staging; this worker has not committed or published the fixture. The local evidence endpoints above remain available for the fresh checker (verified 2026-09-05).

**Method notes:** `measure.rb` records each `curl -f -sS -L` request, User-Agent, source URL, timestamp, status and retained stdout for the Cargo metadata/update/resolver/build/check/generate/workspaces manuals, Git diff/hooks manuals, Cargo-team lockfile article, and Cargo/clap/Warp workflows and repository files. Source precedent uses `git show` from Python commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and TypeScript commit `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, with retained stdout and provenance in [E]. The original unretained warm numbers are withdrawn. Two setup attempts remain labelled in [fixture notes][FREADME]: blocked hardware `sysctl`, then blocked `/usr/bin/time -l` resource collection. Their timings are excluded; the accepted run uses `time -p`. The Linux guard leg is retained in [LINUX]; exact `ubuntu-latest` `x86_64` runner behavior, peak memory, full manager integration and an external maintained exact guard remain unverified, explicitly rather than being reported as passed.
