decision-sha256: 7dd84b81f27b3d3fe20118958e71310b9f011e889372d8266ae4f161419dc45e
actor: audit-codex-2026-09-05T163018Z-6cb436162ac7
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

I ran the recorded `run-checks.sh host` driver from an isolated temporary copy
of `review/empirical/fixture`, with the required macOS floor toolchain:
`PATH="$(rustup run 1.96.0 rustc --print sysroot)/bin:$PATH"`. I set only
`UV_CACHE_DIR` and `EVID` to isolated temporary directories so the driver did
not write outside the two authorized review outputs; the command argv and all
per-case output are preserved in
`review/evidence/audit-template-drift-receipt-guard.log`. The driver exited
0, and all 16 recorded host outcomes matched their expected exit codes.

I then ran the copied `run-linux-leg.sh` driver. It copied the fixture and
driver to VM-local `~/r15-empirical`, as required by the read-only Lima mount.
The driver exited 0. On Ubuntu 25.10/aarch64 with `press 4.0.1`, all 16 Linux
outcomes also matched. The host rerun used macOS 26.4/arm64, Rust and Cargo
1.96.0, Python 3.13.14, `uv` 0.11.29, and `press` 4.0.1. The Linux leg used
Rust and Cargo 1.98.1 for its normal lane and 1.96.0 for its floor lane,
Python 3.13.7, `uv` 0.12.11, and `press` 4.0.1.

The full log includes the six required citation spot checks, all fetched with
`curl` and returning HTTP 200: the pinned `template-press` CLI reference,
the pinned py press workflow, receipt guard, and rules, `cargo-generate`
0.24.0's manifest, and the Cargo CI guide. The checked manifest has no
`rust-version`, as the decision states.

## Findings

No finding requires a decision change.

The positive and inverse controls establish the selected principle rather
than merely proving that `press` starts. A clean template verified with exit
0 and produced the recorded JSON result without changing Git status. A
source-identity token planted in an excluded file failed with exit 1 on both
operating systems. A stale `package_name` and a wrong origin-derived `owner`
each failed configuration validation with exit 2.

The real rebrand control exited 0, wrote `press/press-receipt.toml`, removed
the template-only receipt workflow from the pressed fork, found no source
identity outside the receipt, and passed `cargo test --workspace`. The same
receipt made the template-only guard fail with exit 1; the clean template made
that guard pass with exit 0. This proves the deliberately narrow
template-versus-fork receipt invariant.

The decision's correction of Codex's raw field schema is supported: adding
`crate_name` and `binary_name` produced the tool's unknown-key failure (exit
2), while omitting `display_name` produced a real leak failure (exit 1).
The compensating `tests/press_source.rs` check passed on the unmodified
fixture and failed with exit 101 after the binary target drifted from `rslbp`
to `rslb`, in both normal and 1.96.0 lanes. The workflow's literal `uv venv`,
`uv pip sync`, and `uv run press verify` commands also passed on both legs.

The known limits remain correctly disclosed by the decision: the Linux leg is
aarch64 rather than GitHub's x86_64 runner; neither a real binary asset nor a
multi-crate member-directory rename was exercised; and the workflow was run
outside GitHub Actions. They are bounded re-verification triggers, not
contradictions of the selected template-drift and receipt-guard pattern.

## Assessment

Approve. The empirical result matches the decision's exit-code table on both
available operating systems and contains successful and failing controls for
each material claim: hermetic verification, source-config validation,
identity closure after a real press, receipt scope, generated Rust viability,
and Cargo/press identity agreement. The checked primary sources also support
the pinned-tool, py-precedent, and `cargo-generate` gate claims.
