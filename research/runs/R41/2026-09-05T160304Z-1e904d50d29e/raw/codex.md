### Landscape

This item decides the lockfile-freshness pattern: a pre-commit check that rejects a dependency-manifest change unless Cargo can resolve it without changing the committed `Cargo.lock`.

| Bin | Candidates found | Survey result |
|---|---|---|
| Built-in or first-party toolchain | `cargo metadata --locked --format-version=1`; `cargo check --locked`; `cargo build --locked`; `cargo update --workspace --locked`; `cargo generate-lockfile --locked` | Stable Cargo commands documented by the Cargo team. `--locked` errors when the lockfile is missing or Cargo would change its dependency resolution. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) and [Cargo command reference](https://doc.rust-lang.org/cargo/commands/cargo.html) (retrieved 2026-09-05). |
| Established industry standard | A conditional Git `pre-commit` job triggered by staged `Cargo.toml` or `Cargo.lock` paths | Git defines a blocking `pre-commit` lifecycle. The Python source uses this condition for `pyproject.toml` and `uv.lock`; the TypeScript source has no equivalent. [Git hooks](https://git-scm.com/docs/githooks), [Python source](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/lefthook.yml#L131-L133), and [TypeScript source](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/lefthook.yml) (retrieved 2026-09-05). |
| Up-and-comer | No exact third-party crate or script found | `cargo-deny` and `cargo-semver-checks` solve dependency policy and API-compatibility problems, not manifest-to-lockfile freshness. [cargo-deny](https://github.com/EmbarkStudios/cargo-deny) and [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks) (retrieved 2026-09-05). |

Authority comes from four sources. The Cargo Book is the Rust toolchain team’s command reference. Git’s manual defines hook timing and failure behavior. Cargo’s own repository demonstrates a lockfile job. Maintained projects demonstrate production usage. The survey covered [Cargo](https://github.com/rust-lang/cargo), [Warp](https://github.com/warpdotdev/warp), [clap](https://github.com/clap-rs/clap), [rustls](https://github.com/rustls/rustls), and [Tokio](https://github.com/tokio-rs/tokio), all retrieved 2026-09-05. Cargo is maintained by the Cargo team; Warp has an exact metadata freshness check; clap has a dedicated lockfile job; rustls runs locked commands on Linux and macOS; and Tokio is a major maintained asynchronous runtime. These establish standing and practice, not fitness by popularity.

### Principles and implementation

The shared requirement is a capability: dependency-manifest changes must not enter a commit unless the committed lockfile matches Cargo’s resolution. The agreement level is capability plus hook pattern; the command may vary by ecosystem. Observable criteria are: synchronized staged files pass; a staged dependency or feature change without the regenerated lockfile fails; commits staging neither Cargo manifest nor lockfile skip this check; every workspace member manifest is covered; and the diagnostic says how to repair the failure. F171 is the Python source precedent, not a predetermined Rust implementation. [Python F171](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/lefthook.yml#L131-L133) (retrieved 2026-09-05).

`--locked` is the native assertion. Cargo documents that it requires the exact dependencies and versions from the existing lockfile and exits non-zero when the lockfile is missing or a different resolution would change it. The resolver documentation says a manifest change can select a new resolution and that `--locked` or `--frozen` turns that update into an error. [Cargo metadata options](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html#manifest-options) and [Cargo resolver](https://doc.rust-lang.org/cargo/reference/resolver.html#lock-file) (retrieved 2026-09-05).

Choose `cargo metadata --locked --format-version=1`. It resolves the workspace metadata without compiling application targets, emits JSON that the hook can discard, and uses a stable output-format declaration. Do not use `--no-deps`: Cargo documents that it suppresses dependency fetching and makes the resolved graph null, which weakens this freshness proof. [Cargo metadata output options](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html#output-options) (retrieved 2026-09-05).

`cargo check --locked` is a valid runner-up, but Cargo says it compiles packages and dependencies without final code generation. It can therefore fail for source, compiler, feature, or dependency-build reasons unrelated to lockfile freshness. `cargo build --locked` adds final code generation and linking. [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html) and [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html) (retrieved 2026-09-05).

`cargo update --workspace --locked` and `cargo generate-lockfile --locked` are less suitable. Cargo documents their primary operations as updating or rebuilding the lockfile. Their `--locked` forms can expose a needed change, but they encode update or regeneration semantics rather than a narrow read-only check. clap uses the former in CI, and Cargo uses `cargo update -p cargo --locked` in its own CI. [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html), [Cargo generate-lockfile](https://doc.rust-lang.org/cargo/commands/cargo-generate-lockfile.html), [clap CI](https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml#L195-L206), and [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L100-L106) (retrieved 2026-09-05).

There is a staged-content hazard. Cargo reads worktree files, while Git records the index. A hook that runs Cargo without checking relevant staged/worktree parity can validate files different from those being committed. This is an inference from Git’s hook model and Cargo’s filesystem-based manifest resolution. The wrapper must reject relevant unstaged changes or validate an isolated staged snapshot before invoking Cargo. [Git hooks](https://git-scm.com/docs/githooks) and [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) (retrieved 2026-09-05).

A minimal Cargo command body is:

```sh
cargo metadata --locked --format-version=1 >/dev/null || {
  echo "FAIL: Cargo.lock is out of date with Cargo.toml. Run cargo check, then stage Cargo.toml and Cargo.lock." >&2
  exit 1
}
```

Warp uses this Cargo command and the same remediation shape in CI. [Warp reference implementation](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L2970-L2974) (retrieved 2026-09-05).

Fitness gates were applied before practice was weighed. These are commands and shell patterns, not Rust crates, so crate license, dependency-tree MSRV, RustSec, reverse-dependency, feature, and binary-download figures are `inapplicable`. Cargo built-ins have no separately distributed crate license or dependency tree; they run on the owner-fixed Ubuntu and macOS toolchain matrix, have no async coupling, and do not add compiled binary cost. The shell wrapper is covered by the repository license, has no Rust dependency tree or RustSec surface, and has no compilation cost. All applicable gates pass. The application’s own dependency graph remains subject to the fixed edition, MSRV, license, and OS parameters. [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L100-L106) and [Cargo lockfile guidance](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) (retrieved 2026-09-05).

### Dominant choice

Adopt the conditional staged-manifest hook pattern with `cargo metadata --locked --format-version=1`, preceded by staged/worktree parity protection for all workspace `Cargo.toml` files and the shared `Cargo.lock`. It directly tests the invariant, avoids application compilation, adds no Rust dependency, and has an exact maintained reference in Warp. R37 still owns the hook manager, distribution, and full-suite tiering. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html), [Warp CI](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L2970-L2974), and [Git hooks](https://git-scm.com/docs/githooks) (retrieved 2026-09-05).

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
|---|---|---|---|
| `cargo metadata --locked --format-version=1` | [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) | Warp CI uses it as an explicit freshness check | 2026-09-05 |
| `cargo check --locked` | [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html) | rustls uses locked Cargo commands in maintained multi-OS tests | 2026-09-05 |
| `cargo build --locked` | [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html) | rustls uses locked builds in maintained tests | 2026-09-05 |
| `cargo update --workspace --locked` | [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html) | clap has a dedicated lockfile CI job | 2026-09-05 |
| `cargo generate-lockfile --locked` | [Cargo generate-lockfile](https://doc.rust-lang.org/cargo/commands/cargo-generate-lockfile.html) | No exact maintained adopter found | 2026-09-05 |
| Conditional shell wrapper around Cargo | [Git hooks](https://git-scm.com/docs/githooks) | Python’s staged-file trigger and Warp’s error wrapper | 2026-09-05 |

### Excluded by gate

No candidate failed a mandatory license, MSRV, security, or platform fitness gate. The semantic use-case gate excludes `cargo build --locked` because it compiles and links; `cargo check --locked` because it compiles the dependency graph; `cargo update --workspace --locked` because it expresses update policy; `cargo generate-lockfile --locked` because it expresses regeneration; and `cargo-deny`/`cargo-semver-checks` because their documented purposes are different. [cargo-deny](https://github.com/EmbarkStudios/cargo-deny), [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks), and [Cargo generate-lockfile](https://doc.rust-lang.org/cargo/commands/cargo-generate-lockfile.html) (retrieved 2026-09-05).

### Up-and-comers

No up-and-comer has exact-use evidence sufficient to displace Cargo. The useful open design space is a repository-local wrapper that validates staged/worktree parity and delegates resolution and failure status to Cargo. It is an implementation of the pattern, not a new dependency. [Cargo extensibility](https://github.com/rust-lang/cargo#adding-new-subcommands-to-cargo) and [Warp wrapper](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L2970-L2974) (retrieved 2026-09-05).

### Fit for this template

For the CLI, this check is appropriate because the binary-containing target should commit a reproducible workspace lockfile. Metadata resolution catches dependency additions without compiling the executable. [Cargo lockfile guidance](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) (retrieved 2026-09-05).

For the library, the check is appropriate because the target is a workspace, not a library-only package. Cargo documents that workspace members share a root lockfile, so the workspace-root invocation covers library dependency changes. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html) (retrieved 2026-09-05).

For the web service, the check is neutral across synchronous and asynchronous implementations. It resolves dependency metadata without starting the service or coupling the hook to an async runtime. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) (retrieved 2026-09-05).

Performance evidence is bounded. On macOS with Cargo 1.98.0, a warm-cache synthetic workspace containing one binary and two local path libraries took 0.02 seconds wall time for `cargo metadata --locked --format-version=1` and 0.01 seconds for `cargo check --locked`. This has no registry graph and does not establish an absolute project-wide speed ranking. Production validation must instrument wall time, CPU time, cold cache, and warm cache for the complete three-member workspace on Ubuntu and macOS. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) and [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html) (retrieved 2026-09-05).

### Recommendation

Adopt the conditional hook. Trigger it when staged paths contain any workspace `Cargo.toml` or `Cargo.lock`. Validate staged/worktree parity for those files first, then run:

```sh
cargo metadata --locked --format-version=1 >/dev/null
```

On failure, preserve Cargo’s stderr and print: `FAIL: Cargo.lock is out of date with Cargo.toml. Run cargo check, then stage Cargo.toml and Cargo.lock.` The repair is to run normal Cargo resolution, review the generated lockfile, and stage every changed manifest together with `Cargo.lock`. Cargo says the lockfile is maintained by Cargo and should not be manually edited. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html), [Warp CI](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L2970-L2974), and [Cargo lockfile guidance](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) (retrieved 2026-09-05).

### Ranked runner-up

Runner-up: `cargo check --locked` with the same conditional trigger. It wins if the owner explicitly wants the hook to add compile validity, or if measurement shows metadata resolution is not materially cheaper than the already-required project check. Cargo says `check` is faster than `build`, but it still compiles dependencies and reports failures beyond freshness. [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html) (retrieved 2026-09-05).

### Tradeoffs

Metadata gives the narrowest semantic check and avoids application compilation. It gives less human-readable output, and Cargo may still need registry/index access. The wrapper supplies remediation text. `cargo check --locked` offers a compile-validity signal but costs more and mixes unrelated failures into the freshness gate. `cargo build --locked` adds linking without more freshness evidence. Update and regeneration commands have strong CI precedent, but their primary semantics are broader than this read-only invariant. [Cargo command references](https://doc.rust-lang.org/cargo/commands/cargo.html), [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L100-L106), and [clap CI](https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml#L195-L206) (retrieved 2026-09-05).

The parity guard increases wrapper complexity and can reject relevant unstaged edits. That cost is accepted because otherwise the hook may inspect worktree contents while the commit records different index contents. This is a commit-boundary requirement, not a claim that Cargo reads Git’s index. [Git hooks](https://git-scm.com/docs/githooks) (retrieved 2026-09-05).

### Parameters

`owns` none. R41 owns the pattern, not a registered parameter.

`assumes` `rust-edition` = `2024`; `msrv-policy` = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `license` = `MIT OR Apache-2.0`; `target-os-matrix` = `ubuntu-latest, macos-latest`. These fixed owner parameters require no change. [Repository parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-05).

No `CONFLICT:` line is emitted. No `BASELINE-REVIEW:` line is emitted because F171’s capability and trigger principle are retained; only the Cargo-native mechanism and staged-snapshot safeguard are chosen.

### Migration implications

When R37 integrates the hook manager, make these file-level changes:

- Add one conditional pre-commit job covering every workspace `Cargo.toml` and the shared `Cargo.lock`.
- Add a repository-local helper if the manager cannot safely validate staged/worktree parity.
- Invoke `cargo metadata --locked --format-version=1` from the workspace root.
- Add the failure message and repair instruction.
- Exercise the same check in the full-hook-suite integration tier owned by R37.
- Add fixtures for synchronized files, stale lockfile, unrelated commit, staged manifest with unstaged lockfile, staged lockfile with unstaged manifest, and member-manifest changes.

This preserves the Python capability with Cargo-native resolution and does not adopt the TypeScript absence as a Rust default. [Python source](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/lefthook.yml#L131-L133), [TypeScript source](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/lefthook.yml), and [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html) (retrieved 2026-09-05).

### Validation strategy

The planned acceptance fixture is a temporary Git workspace with CLI, library, and web-service members. It must run:

```text
1. Synchronized staged manifest and lockfile: exit 0.
2. Staged dependency or feature change without staged regenerated lockfile: non-zero and actionable diagnostic.
3. Relevant unstaged manifest or lockfile counterpart: non-zero before Cargo runs.
4. No staged Cargo manifest or lockfile: skip and exit 0.
5. Member manifest change: invoke Cargo at the workspace root and check the shared lockfile.
6. Positive and inverse cases on Ubuntu and macOS.
```

Executed evidence: the warm-cache synthetic Cargo 1.98.0 workspace returned exit 0 for `cargo metadata --locked --format-version=1` in 0.02 seconds wall time and for `cargo check --locked` in 0.01 seconds wall time. The stale-manifest inverse and staged-index parity fixture were not run in this no-Rust-code research checkout. The expected inverse is supported by Cargo’s documented exit-101 failure contract and Warp’s maintained wrapper. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html), [Cargo check](https://doc.rust-lang.org/cargo/commands/cargo-check.html), and [Warp CI](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L2970-L2974) (retrieved 2026-09-05).

### Confidence & re-verify trigger

Confidence is high for the Cargo command and medium for the wrapper. Cargo directly documents `--locked`; Warp supplies exact-use evidence; Cargo and clap supply independent lockfile CI precedents; and Git documents blocking pre-commit behavior. Performance confidence is medium because the executed workload was tiny and warm-cache. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html), [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L100-L106), and [Git hooks](https://git-scm.com/docs/githooks) (retrieved 2026-09-05).

Re-verify when Cargo changes `--locked` semantics, the workspace membership changes, the hook manager changes staged-file or working-directory behavior, the OS matrix changes, or measured hook latency causes bypasses. Re-run stale-manifest, staged-parity, and both-OS fixtures then. [Cargo changelog](https://doc.rust-lang.org/cargo/CHANGELOG.html), [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), and [Git hooks](https://git-scm.com/docs/githooks) (retrieved 2026-09-05).

### Sources

Method notes: queried the Cargo Book endpoints [cargo-metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html), [cargo-check](https://doc.rust-lang.org/cargo/commands/cargo-check.html), [cargo-build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), [cargo-update](https://doc.rust-lang.org/cargo/commands/cargo-update.html), [cargo-generate-lockfile](https://doc.rust-lang.org/cargo/commands/cargo-generate-lockfile.html), [resolver](https://doc.rust-lang.org/cargo/reference/resolver.html), [workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), and [Cargo lockfile guidance](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html); the [Git hooks](https://git-scm.com/docs/githooks) endpoint; and maintained references in [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml), [Warp CI](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml), [clap CI](https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml), [rustls tests](https://github.com/rustls/rustls/blob/main/.github/workflows/daily-tests.yml), [Tokio](https://github.com/tokio-rs/tokio), and the pinned [Python](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/lefthook.yml) and [TypeScript](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/lefthook.yml) sources, all retrieved 2026-09-05. Crate registry, RustSec, reverse-dependency, crate MSRV, crate license, crate feature, and crate binary-size figures are `inapplicable` because this is a `pattern` item and no Rust crate is recommended. GitHub REST star, archive, pushed-at, open-issue, and issue-response figures are `inapplicable` to command/pattern candidates. The executed latency control used local Cargo 1.98.0 and a warm-cache synthetic workspace; the stale-lock inverse and staged-index parity fixture remain unverified.
