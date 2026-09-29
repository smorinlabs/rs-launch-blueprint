# R27 revision 3 empirical audit

actor: codex
model: gpt-6
family: openai
decision-sha256: f1007676a8deb58f32b2d8a47f50a424ba5562c357618b072ae2cf66e54155c6
verdict: approve
unresolved-findings: none

## Re-execution

I verified the decision SHA-256 before reading or running evidence. I ran all six `review/evidence/*.sh` scripts from the repository root with `CARGO_HOME=/tmp/cargo-s73-R27-evr`, `CARGO_TARGET_DIR=/tmp/cargo-s73-R27-evr-target`, and `TMPDIR=/tmp/codex-r27-r3`. Captured output and script scratch files stayed in `/tmp`. Each script exited 0. The four assertion scripts reported 101 checks, 101 pass, 0 fail. The two figure scripts contain observations and no assertions. I compared each complete captured output against its committed `.log` with `cmp`, then inspected each complete difference with `diff`.

| Script | Complete log comparison | Result |
|---|---|---|
| `r27-config-surface.sh` | byte-identical | 65/65 pass |
| `r27-workspace-scope.sh` | differs as detailed below | 14/14 pass |
| `r27-hook.sh` | byte-identical | 13/13 pass |
| `r27-channel-pin.sh` | byte-identical | 9/9 pass |
| `r27-figures.sh` | differs as detailed below | observations only |
| `r27-husky-defaults.sh` | retrieval timestamp alone differs | observations only |

The first runs of the two remote observation scripts returned `NO DATA` under the restricted network. I reran both with network access; the comparison above uses those complete final outputs.

## Findings

- **OBS — C2.8 timing and host diagnostic drift.** `r27-workspace-scope.log` records three `cargo fmt` runs at 0.08/0.07/0.07 seconds and `just format-check` at 0.54 seconds. The rerun records 0.06/0.06/0.06 and 0.24 seconds. Its under-5-second assertion passes, as revision 3 discloses for timing drift. The rerun also prints two Xcode file-event/cache diagnostics before the toolchain line; the committed log has no such lines. All other output, including reachability and guard results, matches.
- **OBS — live F figures drift.** `r27-figures.log` and the rerun differ in the retrieval timestamp and live stars, open-issue count and membership, reference-repository stars/push times, and crates.io download counts. In particular, the rerun has rustfmt 6,975 stars and 2 answered / 8 unanswered issues, the values revision 3 explicitly disclosed from its scratch rerun; the current sample's median is 0.845 days. F1 release, F5 toolchain channels, F6 config contents, F7 CI command, F8 Dependabot directory, F9 newest versions, and F10 HTTP statuses match. These changes do not contradict the decision's dated figures or its recommendation.
- **OBS — F11 retrieval timestamp drift.** The final `r27-husky-defaults` rerun differs from the committed log only at line 1. Its feature and hook source lines match byte for byte.

## Revision 3 repairs

- `DECISION.md:188` says Rust **hook templates**, identifies `run-cargo-fmt` as opt-in, and states that cargo-husky defaults to a pre-push `cargo test` hook. Committed F11 lines 5, 12, 20-21, 29-30 and 40 support those exact facts; the rerun reproduces them.
- `DECISION.md:146` cites **C1 header and C4.1** for the version row. The C1 log header names 1.94.0, 1.96.0, 1.96.1 and Homebrew 1.98.1; `r27-channel-pin.log:4-8` supplies the 1.93.0 build and the exact pin behavior.

No BLOCKING finding changed a load-bearing claim, the recommendation, or the sufficiency of its recorded empirical checks. The disclosed macOS-only and unexercised rustup 1.98.1/CI limits remain explicit in the decision.
