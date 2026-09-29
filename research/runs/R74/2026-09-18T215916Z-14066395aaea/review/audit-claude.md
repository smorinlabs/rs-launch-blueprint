actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 84c01ec019f9ba68b731b56ad846dece449ddecdf8fb6d548530f2dc1b4b3056
verdict: reject
unresolved-findings:
1. EA-1 — `r74-decision-shape.sh` fails against this revision, and the log the decision cites for it does not exist.
   - Claim (`## Empirical check`, table row): "`r74-decision-shape.sh` | see its own summary line | run last, against this file as committed | `review/evidence/r74-decision-shape.log`".
   - Evidence: no `r74-decision-shape.log` exists in `review/evidence/`. My rerun exits 1 with `CHECKS RUN: 54  PASS: 50  FAILURES: 4  SKIPPED: 0`. The four failures are:
     `FAIL  S1g gate 1 is recorded as inapplicable with the owner ruling, not deleted: expected [1] got [0]`
     `FAIL  S2g exactly one BASELINE-REVIEW finding, for F323: expected [1] got [3]`
     `FAIL  S4d 'standards-compliant' is never claimed for the RateLimit draft fields: expected [0] got [1]`
     `FAIL  S4f 'crates/web' is the layout used: expected [1] got [2]`
     I checked each failure against the decision text. Each is a brittle matcher; the content itself is present and correct. S1g: the phrase is wrapped across lines 225–227. S2g: line 239 files the finding, and lines 17 and 456 are prose mentions. S4d: line 321 says "neither is described as standards-compliant", which is a negation. S4f: line 181 is prose and line 447 is the table row.
   - Repair: fix the four matchers. S1g: join the wrapped lines before matching, or match `inapplicable — owner ruling 2026-09-12 (Q7.B)`. S2g: anchor on the filing line, `^\*\*\`BASELINE-REVIEW: F323`. S4d: exclude the negated form. S4f: expect 2, or anchor on the table row. Then rerun the script last, commit `r74-decision-shape.log` showing `FAILURES: 0`, and state the real totals in the table.
2. EA-2 — `r74-probe.sh` has an undeclared precondition, a warm Cargo cache, and it reads a different registry than the one cargo uses.
   - Claim: the probe "exit[s] non-zero on any failure", and the listed subset is "byte-identical across reruns". The decision does not mention a cache precondition.
   - Evidence: every cargo call uses `--offline`. Section D/E reads the hard-coded path `REG="$HOME/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f"`, while cargo itself honours `$CARGO_HOME`. I ran the probe unmodified under a clean private `CARGO_HOME=/tmp/cargo-s15-R74-emp`. It printed `error: no matching package named \`axum\` found` and 12 FAIL lines (all 7 A tests, A-total, A-clippy, both B tests, B-total). It then aborted with `INTERNAL: removing the root package from probe-baseline removed 0 lines, not 1`, exit 1, and never printed a summary line.
   - Repair: add a `cargo fetch` step before the offline calls, or state the warm-cache precondition in `## Empirical check`. Derive `REG` from `${CARGO_HOME:-$HOME/.cargo}`.
3. EA-3 — the C-section package counts are not pinned by any lockfile.
   - Claim: C0–C4 and E5 (50, +0, +0, +37, +49, +18) "reproduce the Opus report's three figures exactly".
   - Evidence: `mk_manifest` pins only the direct crates (`=0.8.9`, `=1.53.1`, `=0.8.0`, `=0.1.6`, and `tracing = "0.1"` unpinned). No `Cargo.lock` is committed, so every run re-resolves the transitive set. Today's fresh resolution still gives `baseline=50 design=50 tracing=50 tg_nodefault=87 tg_default=99` and 54/54 PASS. The figures hold, but only because nothing has moved yet.
   - Repair: commit the probe crates' `Cargo.lock` files as evidence (outside any `src/`), or use `-Z minimal-versions`/`--locked` with a recorded lock. Alternatively, label the counts as "resolution of <date>".
4. EA-4 — toolchain drift breaks the stated byte-identity subset of `r74-probe.log`.
   - Claim: "the four toolchain lines are byte-identical across reruns".
   - Evidence: the diff of the stated subset (60 lines each) differs only in these lines: `< toolchain: rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)` vs `> toolchain: rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, and the matching `cargo` line (1.98.0 vs 1.98.1). The decision's own snapshot `channel-rust-stable-pkg-rust.txt` already recorded stable as `1.98.1 (48a229cea 2026-09-01)`, so the probe ran on a superseded patch release.
   - Repair: pin the toolchain for the probe (`rustup run 1.98.1` or a `rust-toolchain.toml` in the temp workdir), or restate the rule as "identical modulo the toolchain lines". Re-record the log on the current stable.
5. EA-5 — registry drift since 2026-09-19: 23 of 88 figure checks fail on a fresh fetch, including one new release and two reverse-dependency totals the decision says "did not move".
   - Claim: "the figures that decide anything — `rust_version`, reverse-dependency totals, `archived`, `pushed_at` and release dates — did not move". The decision also names `axum-governor` 2.1.0 as the newest release.
   - Evidence: I re-fetched into a /tmp mirror (37 of 37 payloads saved, exit 0), and 22 payloads changed. Running `r74-registry-figures.sh` on the fresh snapshots gives `CHECKS RUN: 88  PASS: 65  FAILURES: 23`. Most failures are download counters. Four are decision-adjacent:
     - `FAIL  F2-num   axum-governor newest non-yanked num: expected [2.1.0] got [2.1.2]`
     - `FAIL  F2-date  axum-governor newest non-yanked created_at: expected [2026-09-05] got [2026-09-26]`
     - `FAIL  F3 governor reverse_dependencies meta.total: expected [483] got [489]`
     - `FAIL  F3 tower_governor reverse_dependencies meta.total: expected [81] got [82]`
     `canmi21/axum-governor` `pushed_at` also moved, from 2026-09-08T22:46:01Z to 2026-09-26T08:06:45Z. No conclusion flips. 2.1.1 and 2.1.2 still declare `rust_version` 1.95, so the one-minor-headroom exclusion stands. `tower_governor` 0.8.0, `governor` 0.10.4 and `axum_gcra` 0.1.1 still declare `null`. All six RustSec 404s and the `dashmap` 200 control are unchanged. `archived` is false and `open_issues_count` is 24 for `benwis/tower-governor`, both unchanged.
   - Repair: rerun `r74-fetch-snapshots.sh` and re-record the snapshots, `r74-registry-figures.log` and the cited figures. Alternatively, keep the 2026-09-19 figures and add an explicit "as of 2026-09-19; axum-governor 2.1.2 (2026-09-26, rust_version 1.95) postdates it" qualifier to the `axum-governor` row and the drift paragraph. Replace "reverse-dependency totals … did not move" with a dated statement.

## Audit record

- Auditor: claude (`claude-opus-5-5`), a fresh context, independent of the synthesizer and the judgment auditor. Run on 2026-09-26.
- Target: `research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md`, revision 1. `shasum -a 256` gives `84c01ec019f9ba68b731b56ad846dece449ddecdf8fb6d548530f2dc1b4b3056`, which matches the expected hash. Note: at audit time the whole `review/` directory is untracked (`?? …/review/` in `git status`), so "as committed" means as written on disk.
- Environment: macOS 26.4 on Darwin arm64. Toolchain: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, `shellcheck 0.11.0`, `jq-1.8.2` (the decision recorded 1.8.1), and `/usr/bin/grep` BSD 2.6.0-FreeBSD. `CARGO_HOME=/tmp/cargo-s15-R74-emp` (private and initially empty). All output went to `/tmp/r74audit/out/`. Scripts that write next to themselves ran in a byte-identical `/tmp/r74audit/root` mirror (`diff -r` empty before the runs). Nothing under `evidence/` was written.
- Currency: `## Empirical check` names the current set for revision 1. It lists four assertion scripts (probe 54, registry-figures 88, rest-conformance 40, decision-shape "run last") plus the non-reproducible fetcher. It also defines the comparison rule for each log. I followed those rules. The logs on disk are the ones that section cites, except `r74-decision-shape.log`, which is absent (EA-1).

### Reruns

| Script | Command (cwd) | Exit | Totals | Comparison with the committed log |
|---|---|---|---|---|
| `r74-registry-figures.sh` | `bash ./r74-registry-figures.sh > /tmp/r74audit/out/r74-registry-figures.inplace.log` (evidence/, read-only script) | 0 | 88 PASS / 0 FAIL / 0 SKIP | `cmp`: **byte-identical** |
| `r74-rest-conformance.sh` | same pattern (evidence/) | 0 | 40 PASS / 0 FAIL / 0 SKIP | `cmp`: **byte-identical**. P0a–P0d re-verified the pinned blob `71bd813c…` in the local `rest-standards` clone. |
| `r74-decision-shape.sh` | `bash ./r74-decision-shape.sh` (mirror evidence/) | **1** | 50 PASS / **4 FAIL** / 0 SKIP (54) | No committed log exists to compare against. Full output is in `/tmp/r74audit/out/r74-decision-shape.log`; the failures are listed in EA-1. S3a passed against the working-tree `docs/port/PARAMETERS.md`, which is modified in the working tree. |
| `r74-probe.sh` (as-is, empty private `CARGO_HOME`) | `bash ./r74-probe.sh` (evidence/; writes only to `mktemp -d`) | **1** | 12 FAIL printed, then an INTERNAL abort in C with no summary line | See EA-2 |
| `r74-probe.sh` with only `--offline` removed (4 lines), which fills the private cache | `bash /tmp/r74audit/r74-probe.online.sh` | 0 | 54 PASS / 0 FAIL / 0 SKIP; `baseline=50 design=50 tracing=50 tg_nodefault=87 tg_default=99` | — |
| `r74-probe.sh` (as-is, cache now warm) | `bash ./r74-probe.sh` (evidence/) | 0 | 54 PASS / 0 FAIL / 0 SKIP | `cmp` differs at line 1, which the decision expects. Stated subset (PASS/FAIL/SKIP lines, `CHECKS RUN`, `baseline=`, toolchain lines; 60 lines each): identical except `rustc`/`cargo` 1.98.0 → 1.98.1 (EA-4) |
| `r74-fetch-snapshots.sh` | `bash ./r74-fetch-snapshots.sh` (mirror; overwrites only the mirror's snapshots) | 0 | 37/37 `SAVED` (the committed log also has 37). No assertions by design. | `cmp` differs at line 48 (manifest timestamps), which the decision expects as non-reproducible. 22 of 37 payloads changed and 15 are identical, including `rustsec-status.txt` and `gh-issues-open-tower-governor.json` |
| `r74-registry-figures.sh` on the fresh snapshots | mirror evidence/ | 1 | 65 PASS / 23 FAIL / 0 SKIP | Drift quantified in EA-5 |

`shellcheck` is clean on all five scripts. The decision says "all four"; there are five, and all five are clean.

### Load-bearing figures re-derived at source

- Gate-2 reads re-derived at source. The probe's D section reads the unpacked published manifests: `tower_governor` 0.8.0 and `governor` 0.10.4 have no `rust-version`; `axum-governor` 2.1.0 has 1.95, `gcra` 0.6.0 has 1.80.0, and `axum` 0.8.9 has 1.80 (control). The fresh crates.io payloads agree, including `axum_gcra` 0.1.1 = `null` and `tower-rate-limiter` 0.1.6 = 1.96.0. `axum-governor` 2.1.1 and 2.1.2 still declare 1.95. These results hold.
- `tower_governor` defects (B): today's rerun confirms both. Without `ConnectInfo` the response is 500. With it, the third request is 429 with `retry-after: 29` for a true wait of 29.99… s. The D2 source facts also pass. These results hold.
- Recommended design (A): 7/7 tests pass on the current toolchain, and clippy is clean under `-D warnings`. This holds.
- Dependency deltas (C): +0/+0/+37/+49 and E5 +18 reproduce under today's resolution. They hold for now but are unpinned (EA-3).
- REST standard quotations and line numbers: 40/40 checks pass, and the snapshot is byte-identical to the pinned blob. This holds.
- RustSec: six 404s plus the `dashmap` 200 control, unchanged on 2026-09-26. This holds.
- Not re-derived, because the decision itself labels them carried: the throughput table and the per-issue responsiveness medians.
