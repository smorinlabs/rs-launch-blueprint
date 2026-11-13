## Figures

No endpoint-derived figures appear in `raw/codex.md`. The report explicitly treats crates.io, GitHub REST, RustSec, and issue-response figures as inapplicable because the selected result is a repository pattern with no crate dependency. Result: **ok** — 0 figures to re-query.

## Gates

| Candidate and claim | Result | Evidence check |
|---|---|---|
| Root-only Cargo metadata is license-compatible with `MIT OR Apache-2.0` | ok | Cargo defines `license` as an SPDX expression and gives that exact expression as an example: <https://doc.rust-lang.org/cargo/reference/manifest.html>. The Rust API Guidelines prescribe the matching `LICENSE-APACHE` and `LICENSE-MIT` root files: <https://rust-lang.github.io/api-guidelines/necessities.html>. |
| Root-only Cargo metadata is tested on `ubuntu-latest` and `macos-latest` | unverifiable | The cited Cargo reference defines manifest metadata but supplies no CI matrix or platform-test evidence. The report labels this gate `Pass` without the prompt-required OS evidence. |
| A one-line SPDX declaration accepts `MIT OR Apache-2.0`; a REUSE header also needs copyright metadata | ok | SPDX shows the dual expression in a single source comment: <https://spdx.dev/learn/handling-license-info/>. REUSE requires one or more copyright notices and SPDX expressions in a comment header: <https://reuse.software/spec-3.3/>. |
| The plain SPDX and REUSE candidates are tested on `ubuntu-latest` and `macos-latest`; `reuse lint` is cross-platform | unverifiable | Neither cited SPDX nor REUSE source establishes the required CI matrix. The REUSE specification describes the format, not supported operating systems. |
| `file_header` can add/check headers and has an SPDX feature | ok | Its repository describes a Rust library for adding/checking arbitrary headers and its SPDX feature: <https://github.com/google/file-header>. The raw report correctly leaves its composite-expression and OS-matrix evidence unverified. |
| `addlicense` requires Go and provides check-only and SPDX-only modes | ok | Its documented installation requires Go 1.16 or newer, and its flags include `-check`, `-l`, and `-s=only`: <https://github.com/google/addlicense>. |
| clap demonstrates an MIT-only file header despite a dual workspace license | ok | `clap_builder/src/lib.rs` contains the MIT-only notice: <https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs>. The workspace manifest declares `license = "MIT OR Apache-2.0"`: <https://raw.githubusercontent.com/clap-rs/clap/master/Cargo.toml>. |

## References

The recommendation's normative references exist and support the root-only mechanism: Cargo and the Rust API Guidelines are live first-party documents. The cited implementation examples also resolve and show header-free representative sources: Serde <https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs>, Tokio <https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs>, Axum <https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs>, and the OpenZeppelin template <https://raw.githubusercontent.com/openzeppelin/rust-project-template/master/src/lib.rs>.

The cited source files establish existence and the claimed source shape. They do not independently establish the raw report's repeated `maintained` status; its stated GitHub API rate-limit result leaves no release, recent-push, or maintainer-response evidence for that status. Result: **unverifiable** for maintenance, not for the existence or header observations.

## Verdict

**defective**

1. The planned negative-header check in `raw/codex.md` reverses success and failure. Its `awk` program exits 0 when no prohibited header exists and exits 1 when it finds one, but the enclosing `if ...; then` emits `unexpected per-file license header` and exits 1 on status 0. Thus a header-free tree fails and a tree containing a prohibited header passes. The required inverse control has the same reversed result.
2. The required `ubuntu-latest` and `macos-latest` fitness gate is unsupported for the root-only, plain-SPDX, and REUSE candidates. The cited standards establish metadata syntax and REUSE conformance, not CI execution on both required operating systems.
3. The report's cited reference sources establish their current content, but not the claimed maintenance state. Because its GitHub REST requests were rate-limited, it needs another authoritative maintenance signal or must label maintenance as unverified.

Counts: **ok 5, wrong 1, unverifiable 3**.
