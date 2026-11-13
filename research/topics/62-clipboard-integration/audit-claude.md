actor: audit-claude-2026-09-17T020715Z-7f97cd917c54
model: claude-opus-5-5
family: anthropic
decision-sha256: fb0a58c9556fdd19052e165d2f5a1d53e2766a84961ab86f9f2401500140d3c2
verdict: approve
unresolved-findings: none

# R62 clipboard-integration — empirical audit of DECISION.md revision 2

**Seat.** This audit runs on the Claude seat, as the approved fallback of
method amendment Q8.B while the OpenAI provider is quota-paused. It is not a
Codex audit. The auditor's context is fresh and independent of both the
synthesizer and the judgment auditor. No `review/audit-fable*.md` and nothing
under `research/topics/62-*/raw/` was read.

**Scope.** Execution truth and evidence support only: whether the commands run,
whether the logs match the claims, and whether the figures are right. The
auditor did not judge whether the recommendation is wise.

**Result.** All three evidence scripts rerun, and every claimed count
reproduces. Every load-bearing figure re-derives at source. One robustness
defect was found in `spike-build.sh` under a cold cargo cache. It falsifies no
sentence in the decision, so it is recorded below as a non-blocking observation
with a repair.

## Target identity

    shasum -a 256 research/runs/R62/2026-09-17T020715Z-7f97cd917c54/review/DECISION.md
    fb0a58c9556fdd19052e165d2f5a1d53e2766a84961ab86f9f2401500140d3c2

This equals the expected hash, and the heading reads "decision (revision 2)".
`git hash-object` equals `git rev-parse HEAD:<path>` for all six files under
`review/evidence/`, so the audit reran the committed bytes. `git diff --stat
25475061^ 25475061` (the revision-2 commit) touches only `DECISION.md`,
`verify-r2.sh` and `r62-clipboard-claims-r2.log`. That confirms the claim that
`verify.sh`, `spike-build.sh` and their two logs are byte-identical to
revision 1.

## Host

- Date: 2026-09-25.
- Working directory: `research/runs/R62/2026-09-17T020715Z-7f97cd917c54/review/evidence`.
- Toolchain: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and
  `cargo 1.98.1`. The decision recorded 1.98.0.
- `gh version 2.101.0`. The decision recorded 2.98.0.
- `ShellCheck 0.11.0`.
- Host: macOS 26.4, Darwin 25.4.0, arm64.
- All logs were written to `/tmp/r62-audit/`. The committed logs were not
  overwritten.

## Reruns

### ShellCheck

    shellcheck spike-build.sh verify.sh verify-r2.sh   # ShellCheck 0.11.0

Observed: no output, exit `0`. This confirms the claim "all three
ShellCheck-clean at 0.11.0".

### A. `verify.sh`

    bash verify.sh > /tmp/r62-audit/verify.log 2>&1

Observed: exit `0`, `assertions run : 120`, `skipped : 0`,
`exit status = failures = 0`. 120 lines match `^[<id> PASS]`: 113 have plain
ids and 7 have suffixed ids such as `A1clipboard-rs` and `A89msrv-policy`.
No line is FAIL or SKIP. A91 passes against the revision-2 `DECISION.md`
(`[A91 PASS] assumes lines missing from DECISION.md = 0`). The committed log
predates revision 2, so this pass confirms the check also holds for the current
text.

The decision states a filtered-diff rule. Applied here:

    diff <(/usr/bin/grep -v -e '^FIGURE ' -e '^Run started' -e '^Scratch ' r62-clipboard-claims.log) \
         <(/usr/bin/grep -v -e '^FIGURE ' -e '^Run started' -e '^Scratch ' /tmp/r62-audit/verify.log)

The only differing lines are the three toolchain header lines: `rustc`,
`cargo` and `gh` versions. Every assertion line and every section line
reproduces byte-for-byte.

### C. `verify-r2.sh`

    bash verify-r2.sh > /tmp/r62-audit/verify-r2.log 2>&1

Observed: exit `0`, `assertions run : 35`, `skipped : 0`,
`exit status = failures = 0`. There are 35 PASS lines: 34 plain ids plus
`R18clipboard-rs`. The filtered diff against `r62-clipboard-claims-r2.log`
differs only in the `gh` version header line.

### B. `spike-build.sh` — three runs

| Run | Command | Observed | Cause |
|---|---|---|---|
| 1 | `bash spike-build.sh` | exit `8`, 8 failures | Auditor sandbox. `cargo` could not write under `~/.cargo/registry` (`Operation not permitted (os error 1)`). This is an artifact of the audit environment, not of the evidence. |
| 2 | `CARGO_HOME=/tmp/r62-audit/cargo-home bash spike-build.sh` (cold cache) | exit `2`: `[S04 FAIL] … expected [1], observed [2]` and `[S05 FAIL] … expected [1], observed [2]` | Script defect under a cold cache; see the observation below. |
| 3 | same command, with the cache now warm | exit `0`, `assertions run : 21`, `exit status = failures = 0`, 21 PASS lines | — |

Run 3 reproduces every figure in the decision's section B table:

| Fact | Decision | Run 3 |
|---|---|---|
| Lock resolution | 70 packages | `Locking 70 packages to latest Rust 1.98.1 compatible versions` |
| macOS-leg distinct packages | 9 | 9 |
| Linux-leg distinct packages | 43 | 43 |
| `arboard` / `objc2-app-kit` / `image` / `x11rb` / `wl-clipboard-rs` on the macOS leg | S04–S08 pass | pass |
| Linux leg: `x11rb`, `wl-clipboard-rs`, no `image` | S10–S13 pass | pass |
| Duplicate resolutions | macOS none; Linux `hashbrown` twice | S14 = 0; S15 = 2 (`hashbrown v0.15.5`, `v0.17.1`) |
| Highest declared `rust-version` | macOS 1.71.0 (`arboard`), Linux 1.86 (`wayland-protocols`) | same (S17, S18) |
| `cargo check` | exit 0, no `error[`, no unused-dependency warning | S19–S21 pass |

Apart from host and scratch-path lines, the raw diff against
`r62-spike-build.log` is transitive patch drift only: `smallvec` 1.16.1 → 1.16.2,
`thiserror` 2.0.20 → 2.0.21 (its declared `rust-version` 1.71 → 1.77) and
`unicode-ident` 1.0.25 → 1.0.26. The decision predicts this kind of drift
("a property of the resolution on the run date and toolchain"). None of it
moves a floor or a count that the decision states.

## Figures re-derived

**Rerun `FIGURE` lines against the committed logs.** The following values are
identical:

- all `newest_unyanked` values: 3.6.1, 0.10.2, 0.3.5;
- all `pushed_at` values;
- all `open_issues` values: 19, 5, 5;
- `arboard.unsafe_lines_surveyed = 67`;
- every issue-responsiveness figure: `arboard` 1.68 days / 8 unanswered,
  `copypasta` 0.02 / 1, `clipboard-rs` 7.92 / 5, each over 10 issues sampled.

Only monotone counters moved. `arboard` 90-day downloads went from 12,957,229
to 13,814,494 and all-time from 46,174,781 to 47,995,419. `copypasta` went from
857,282 to 872,693 and from 5,559,318 to 5,643,362. `clipboard-rs` went from
284,058 to 337,474 and from 475,548 to 539,672. Stars went from 967 to 970
(`arboard`) and 180 to 181 (`clipboard-rs`). The decision marks every one of
these as a retrieval-dated snapshot.

**Independent spot-checks at source**, made without the scripts:

- `curl -w '%{http_code}' https://rustsec.org/packages/<name>.html` returned
  `arboard` 404, `copypasta` 404, `clipboard-rs` 404 and `anyhow` 200. This
  confirms the paired control behind checks A06–A09.
- `https://crates.io/api/v1/crates/arboard` returned
  `.crate.max_stable_version = 3.6.1`.
- `arboard` `v3.6.1` `Cargo.toml` declares `version = "3.6.1"` and
  `rust-version = "1.71.0"`. This confirms the macOS-leg floor.
- `arboard` `v3.6.1` `README.md` line 64 contains "the data will be lost".
  This confirms check A33.
- `copypasta` `v0.10.2` `.github/workflows/ci.yml` line 12 reads
  `os: [windows-latest, macos-latest]`, and no line matches `ubuntu`
  (case-insensitive). This confirms checks A46 and A47.
- The `unsafe` census: all six files returned HTTP 200. The per-file counts
  are `lib.rs` 0, `common.rs` 0, `linux/mod.rs` 0, `linux/x11.rs` 0,
  `osx.rs` 40 and `windows.rs` 27, for a total of 67. `common.rs` = 0 matches
  check R15.
- The `## Engines` hashes: `shasum -a 256` of `raw/codex.md` gives
  `db997f3e…908b` and of `raw/opus.md` gives `7ad84779…2814`. Both equal the
  hashes the decision states. These files live under the run directory, not
  the forbidden `research/topics/62-*/raw/` path, and only their hashes were
  taken.

## Non-blocking observation

This observation is not an unresolved finding. It falsifies no claim in the
decision, but the next auditor on a machine with a cold cache will hit it.

- **Claim affected:** section B of the empirical check says the spike exits
  `0` with "21 assertions, 0 failures". That is true for the committed run and
  for a warm-cache rerun.
- **Evidence:** `spike-build.sh` line 119 runs
  `cargo tree -e normal --target "$MAC_TARGET" 2>&1 | tee "$SP/mac.txt"`.
  Lines 122 and 123 then count `'arboard v3.6.1'` and `'objc2-app-kit v'` in
  that file with `grep -cF` and expect exactly `1`. On a cold cache, cargo's
  stderr progress lines (`Downloaded arboard v3.6.1`,
  `Downloaded objc2-app-kit v0.3.2`) enter the same file. Run 2 printed
  `count=2 needle=arboard v3.6.1 file=mac.txt` and failed S04 and S05.
- **Repair, for any future revision of the script:** run `cargo fetch` before
  the tree calls, or count over stdout only.

## Verdict

approve. All three scripts execute. Their observed counts (120/0/0, 21/0, and
35/0/0) match the decision. Every load-bearing figure reproduces at source or
drifts only where the decision says it will. No finding remains unresolved.
