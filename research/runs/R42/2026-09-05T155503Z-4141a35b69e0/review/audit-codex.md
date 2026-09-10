decision-sha256: 5935af16e9b1ba082099b20fa8ca84ee7aea49965feab702eb97477f484d6239
actor: audit-codex-2026-09-05T155503Z-4141a35b69e0
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

I ran the decision's network and mechanism checks in the supplied Ubuntu Lima
VM at `2026-09-10T05:29:45Z`, from this run directory, after sourcing
`$HOME/.cargo/env`. The VM used `rustc 1.98.1`, `cargo 1.98.1`, and `rustup
1.29.1` on Linux arm64. The aggregate rerun exit code was 0. The deliberate
negative control, `command -v cargo-demo` without the stub directory on
`PATH`, exited 1 as expected. Complete command output is in
`review/evidence/audit-dev-toolchain-provisioning.log`.

The root survey reproduced all claimed counts: 0 of 17 for `mise.toml`,
`.mise.toml`, `.tool-versions`, and `.flox`; 5 for `flake.nix`; 9 for
`rust-toolchain.toml`; and 0 root `Makefile`. The reference, RustSec, and
crates.io results match the decision's cited values. The host-specific macOS
version strings do not match because this audit intentionally also ran on
Linux; the Linux run directly resolves the decision's stated rustup-proxy
hazard because `cargo` is the rustup proxy and the selected components run.

The first unauthenticated crates.io request from the VM returned HTTP 403.
The identical endpoints then returned 200 with the explicit descriptive
User-Agent recorded in the evidence log. This is an access-condition retry,
not a changed claim or a missing verification.

## Findings

- `review/evidence/repo-survey.log` supports the decision's 17-repository
  root-file counts. The Linux REST rerun independently produced the same
  counts, including the omitted-in-prose `Makefile = 0` control.
- `review/evidence/invocation-mechanism.log` supports Cargo dispatching
  `cargo demo --flag 1` to a PATH-resolved `cargo-demo`, passing
  `demo --flag 1`; it also records the off-PATH negative control exiting 1.
  The Linux rerun reproduced both results and showed rustup's active selected
  toolchain has `rustfmt` and `clippy` installed.
- `review/evidence/crates-io.log` supports the seven displayed registry
  figures. In particular, its newest unyanked `cargo-binstall` record is
  `1.23.0`, created `2026-09-05T16:59:01.959145Z`, with
  `license: GPL-3.0-only`; the Linux rerun returned the same record.
- `review/evidence/github-rustsec.log` supports the eight GitHub metadata and
  open-issue figures, and its RustSec status controls support interpreting the
  five 404s as absent package pages rather than a transport failure: `time`
  and `atty` both return 200. The Linux rerun matched every displayed value.
- `review/evidence/reference-impls.log` supports the four toolchain-file
  reads and the four justfile wrapper-prefix probes. It shows the exact
  minimal-plus-components shape in `cargo-binstall`, generic acquisition
  recipes in `oxc` and `biome`, and zero prefix matches in the four justfiles.
  The Linux source rereads matched.
- `doxa/normalization.json` correctly records that Perplexity lacks exactly
  `Parameters`, `Migration implications`, `Validation strategy`, and
  `Confidence & re-verify trigger`. The decision limits that report to the
  recommendation prose it actually contains. Gemini's bare citation markers
  and conflicting owned-parameter lines are also accurately treated as
  non-load-bearing assertions.
- The decision does not impose `cargo-binstall`'s exclusion as a settled
  decision. It records the GPL-3.0-only registry fact and Codex's conditional
  gate-1 reading, then explicitly reserves whether a separate-process tool is
  within the fixed license gate for the owner. Its selected `cargo install
  --locked` backend is valid under either reading.
- All ten P03 items are explicitly labelled unproven with a named proof path.
  No template or recommended configuration is claimed to have been built or
  exercised, which is correct under the P02 research-only ruling.

## Assessment

Approve. The cited logs support the claims for which the decision uses them,
the Linux rerun reproduced the material observations, and the decision keeps
implementation proof and the license-gate interpretation outside its asserted
research conclusions.
