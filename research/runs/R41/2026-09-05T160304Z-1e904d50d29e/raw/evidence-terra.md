Actor: `evidence-terra-2026-09-05T160304Z-1e904d50d29e`  
Checked: 2026-09-05

## Figures

No crates.io, GitHub REST, RustSec, or reverse-dependency figure applies: the report recommends a Cargo command and a shell-hook pattern, not a crate. The report nevertheless supplies four quantitative results that must be checked.

| Figure in `raw/codex.md` | Result | Evidence |
|---|---|---|
| Cargo version `1.98.0` | ok | The checker host reports `cargo 1.98.0 (797e8a9bc 2026-08-05)`. |
| `cargo metadata --locked --format-version=1`: `0.02` seconds warm-cache wall time | unverifiable | No retained synthetic workspace, command transcript, timing harness, or endpoint identifies the claimed run. The Cargo documentation defines the command, not this measurement. |
| `cargo check --locked`: `0.01` seconds warm-cache wall time | unverifiable | No retained synthetic workspace, command transcript, timing harness, or endpoint identifies the claimed run. The Cargo documentation defines the command, not this measurement. |
| `cargo metadata` failure exit status `101` | ok | The official Cargo metadata reference states that `0` is success and `101` is failure: [cargo-metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html#exit-status), retrieved 2026-09-05. |

Figure counts: **ok 2; wrong 0; unverifiable 2**.

## Gates

| Fitness-gate claim in `raw/codex.md` | Result | Evidence |
|---|---|---|
| 1. License is inapplicable because the recommendation adds no crate. | ok | The recommendation is the Rust toolchain command `cargo metadata` plus a repository shell wrapper; it names no separately distributed crate. |
| 2. The Cargo command satisfies the fixed stable-minus-two MSRV policy. | unverifiable | The cited Cargo command and CI pages do not establish the oldest supported Cargo/Rust version on which `metadata --locked --format-version=1` must work. The report supplies no historical-version test. |
| 3. RustSec and `unsafe` posture are inapplicable because no crate is added. | ok | No third-party crate or dependency tree is recommended. |
| 4. The recommendation is tested on both `ubuntu-latest` and `macos-latest`. | unverifiable | The cited Cargo lockfile job is explicitly `runs-on: ubuntu-latest`; it does not demonstrate the recommended `cargo metadata --locked` check on macOS. [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L101-L106), retrieved 2026-09-05. |
| 5. Default features and async-runtime coupling are inapplicable. | ok | The proposed command and shell wrapper introduce neither a Rust crate feature set nor an async runtime. |
| 6. The recommendation adds no compiled binary or compile-time dependency cost. | ok | It uses the already-selected Cargo toolchain and a repository-local shell wrapper. This does not establish the command's runtime latency. |

The command's core freshness claim is supported: Cargo says `--locked` errors if the lockfile is missing or a changed resolution would modify it. [cargo-metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html#manifest-options) and [Cargo resolver](https://doc.rust-lang.org/cargo/reference/resolver.html#dependency-updates), retrieved 2026-09-05. Git also supports the asserted blocking-hook behavior: a non-zero `pre-commit` exit aborts `git commit`. [Git hooks](https://git-scm.com/docs/githooks#_pre_commit), retrieved 2026-09-05.

Gate counts: **ok 4; wrong 0; unverifiable 2**.

## References

| Cited implementation or source | Result | Evidence |
|---|---|---|
| Cargo Book / Cargo | ok | The official, current Cargo documentation supports the `--locked` failure semantics, `--format-version=1`, and the distinction from `check`, `build`, `update`, and `generate-lockfile`. Cargo's live `master` ref also resolves. Retrieved 2026-09-05. |
| Warp CI as a reference for `cargo metadata --locked --format-version=1` and remediation text | wrong | The live `master` workflow exists and has the command and remediation at [ci.yml](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L604-L607) and [ci.yml](https://github.com/warpdotdev/warp/blob/master/.github/workflows/ci.yml#L722-L724), retrieved 2026-09-05. It is an Ubuntu CI job, however, not a staged-path `pre-commit` hook and not a staged/worktree-parity wrapper. It therefore cannot be called the report's “exact maintained reference” for the dominant combined design. The report must either cite such a reference or state this evidence gap. |
| clap lockfile CI | ok | The live `master` workflow exists and runs `cargo update --workspace --locked` in its `lockfile` job. [clap CI](https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml#L195-L206), retrieved 2026-09-05. |
| Cargo lockfile CI | ok | The live `master` workflow exists and runs `cargo update -p cargo --locked` on Ubuntu. [Cargo CI](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml#L101-L106), retrieved 2026-09-05. |
| rustls daily-tests as evidence of locked commands on Linux and macOS | wrong | The cited live file contains locked commands, but no `runs-on: macos` entry. It does not support the report's Linux-and-macOS claim. [rustls daily tests](https://github.com/rustls/rustls/blob/main/.github/workflows/daily-tests.yml), retrieved 2026-09-05. |
| Pinned Python `uv-lock-check` precedent | ok | The pinned `lefthook.yml` is retrievable and defines `uv-lock-check` for `pyproject.toml` and `uv.lock`. [Python source](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/lefthook.yml#L126-L131), retrieved 2026-09-05. |
| Pinned TypeScript source used to assert no equivalent hook | unverifiable | The cited raw GitHub URL returned HTTP 404 to this check, so the asserted absence cannot be independently verified from the cited source. |

Reference counts: **ok 4; wrong 2; unverifiable 1**.

## Verdict

**defective**

Defects:

1. The performance conclusion needed for the pre-commit tier rests on two unverifiable warm-cache figures from an unretained, dependency-free synthetic workspace. This does not answer the prompt's required realistic staged-commit latency question.
2. The report states that every applicable fitness gate passes, but provides neither an MSRV-boundary check nor macOS evidence for the recommended command. The cited Cargo lockfile workflow is Ubuntu-only.
3. Warp is a maintained example of the Cargo command and error message, not of the recommended staged-manifest hook plus staged/worktree-parity guard. Calling it the exact maintained reference is false; the required reference implementation or explicit evidence-gap statement is missing.
4. The cited rustls workflow does not establish the claimed macOS practice, and the pinned TypeScript source is not retrievable from the report's URL.

Totals: **ok 10; wrong 2; unverifiable 5**.
