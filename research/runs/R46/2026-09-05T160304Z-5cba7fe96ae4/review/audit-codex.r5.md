decision-sha256: 5e0ffefc16c253046f7b23e9f8bdd09ea75fde8919b0c66ac1b5b504d159e6bb
actor: audit-codex-2026-09-05T160304Z-5cba7fe96ae4-r5
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1 target-directory descendant alias is scanned despite the stated exclusion

## Rerun

I ran `bash review/empirical/run-checks-v5.sh` from this run directory with a fresh `R46_WORK` directory for each leg. The matrix was macOS 26.4 arm64 with Homebrew Rust 1.98.0/BWK awk and Rust 1.96.0/BWK awk, plus the Ubuntu 25.10 aarch64 VM with Rust 1.98.1/gawk, Rust 1.96.0/gawk, and Rust 1.98.1/mawk. The macOS floor leg used `PATH="$(rustup run 1.96.0 rustc --print sysroot)/bin:$PATH`, because `cargo +1.96.0` resolves to Homebrew Cargo on this host. All five runs exited 0 with `summary: PASS=164 FAIL=0` and `RESULT: PASS`; their command/result summary is [audit-per-file-license-header-r5.log](evidence/audit-per-file-license-header-r5.log).

Those results match the decision's recorded standard controls. They also verify its platform-qualified loop behavior: BSD `find` prunes the loop and permits the sequence to continue, while GNU `find` reports the loop and the `pipefail` count pipeline stops the sequence before the header check. I independently repeated all required scan-set controls through the whole sequence: root `build.rs`, `xtask`, an outside-root member, the actual target directory and an ordinary directory named `target`, a source-file symlink, nested non-member package sources, `.git`, dangling symlink, and the loop.

I then added an inverse control that the decision's definition covers but `run-checks-v5.sh` does not: `src/generated-target` is a directory symlink to `target/debug/build/r46-generated/out`, which contains `generated.rs` with an SPDX line. `CARGO_TARGET_DIR` is the fixture's `target` directory. The full `acceptance-v5.sh` sequence exits 1 on both macOS and Linux, counts six files, and reports the generated file through the symlink. The decision says the Cargo target directory is excluded by file identity and that path spelling and symlinks do not matter. Therefore this generated file should be excluded, not rejected.

I also spot-checked the five primary citations named in the evidence log; each returned HTTP 200. The current decision is otherwise coherent with `raw/codex.md` and the fresh Terra evidence check within the Light-tier input boundary.

## Findings

F1 — `acceptance-v5.sh` rejects generated Rust reached through a symlink to a descendant of Cargo's target directory. The script prunes a directory only when that directory is `-samefile "$r46_target"`. A descendant of `r46_target` is not the same directory, so `find -L` follows `src/generated-target` and emits its `generated.rs`. The root-target control passes only because it walks the target root directly, where the prune applies. This contradicts `review/DECISION.md`'s stated set: generated sources under the Cargo target directory are excluded and symlink/path spelling does not change that result.

Repair the discovery stage before acceptance: retain link following, but exclude every discovered file whose resolved physical path lies within the resolved Cargo target directory, not only the target root. Add the descendant-directory-symlink case as a whole-sequence control on BSD and GNU find. Update the decision's scan-set definition and empirical table to say exactly what the repaired code enforces.

## Assessment

Revision 5 fixes the revision-4 fixed-directory defect for the documented root file, normal workspace member, outside-root member, ordinary symlink, and direct target-directory cases. It does not yet implement its own broader target exclusion under symlink traversal. The standard runner's 164 assertions are necessary evidence but do not cover this inverse. Reject revision 5 until F1 is repaired and both empirical and judgment audits rerun.
