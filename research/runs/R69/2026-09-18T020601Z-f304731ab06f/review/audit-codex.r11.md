actor: audit-codex-r69-r11-2026-09-27
model: gpt-6
family: openai
decision-sha256: 2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815
verdict: approve
unresolved-findings: none

# R69 revision 11 empirical re-run

The target `review/DECISION.md` hash was recomputed with `shasum -a 256` before review and again after the reruns. Both results equal `decision-sha256` above. The point-in-time `research/EXECUTION.json` hash is `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c`. The audit applies `research/RUNBOOK.md` §7 and Q23: only outcome-changing contradictions are BLOCKING. All fresh output is under `/tmp/r69-codex-r11.vtOqWW/`. No repository input, snapshot, or script was edited.

## Re-execution and byte comparison

The table names the script, its observed exit code, and the comparison with its committed log. `cmp` exit 0 means byte-identical. All commands ran from the repository root unless the row says scratch copy.

| Script | Exit | Committed-log comparison |
|---|---:|---|
| `review/evidence/supersession-check-r11.sh` | 0, twice | `cmp` 0 on both runs; `CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0` |
| `review/evidence/owned-value-check-r10.sh` | 1 | `cmp` 1; only `V1a` and the summary differ |
| `review/evidence/supersession-check-r10.sh` | 1 | `cmp` 1; superseded revision-10 script also counts revision-11 files and the fresh audit |
| `review/evidence/owner-reference-check-r6.sh` | 0 | `cmp` 0 |
| `review/evidence/owner-reference-check-r9.sh` | 1 | `cmp` 1; its prompt census now reports one match |
| `review/empirical/assert-figures.sh` | 0 | `cmp` 0; 75 assertions pass and the one deliberate control fails as recorded |
| `review/empirical/issue-responsiveness.sh` | 0 | `cmp` 0 |
| `review/empirical/parameters-check.sh` | 0 | `cmp` 0 against `parameters-check-r2.log` |
| `review/empirical/state-bound-check.sh` | 0 | `cmp` 1; only the Rust/Cargo version line differs |
| `review/empirical/bacon-install-check.sh`, copied into `/tmp` and run offline | 1 | `cmp` 1; the private Cargo cache lacks `bacon` 3.25.0, so installation could not rerun |

The five `review/empirical/` paths in this table resolve in the carried source run `research/runs/R69/2026-09-12T204004Z-d02022bf6f42`, as the decision says at lines 1949–1953. The revision-11 note says those evidence bytes are carried unchanged. Fetchers were not run: the decision at lines 2161–2167 excludes them from an audit, and they write snapshots. `feature-shape-check-r4.sh` and `yanked-control-r5.sh` require internal `git` fetches and replace `CARGO_HOME`; they were not run under this brief's `git` and private-Cargo-home prohibitions. The retired `feature-shape-check-r3.sh` is a retained earlier-revision script, not the current check. These limits do not contradict a revision-11 repair claim; the carried checks' committed results remain historical evidence.

## Revision-11 repair checks

The note's successor claim at `DECISION.md:23–49` holds in the current tree: `supersession-check-r11.sh` exits 0 with 23/23 checks, and its output is byte-identical to `supersession-check-r11.log` on two reruns. Its shellcheck 0.11.0 run exits 0 with empty output. The script diff shows the announced title, `S8` row set, `S9` fresh-audit comparison, `S10` revision-11 exclusion, and missing-`CARRIED-FROM.md` exit 2. Its `S8a` reports 309 rows; `S8b` and `S8c` report zero missing and differing files; `S9-audit-fable.md` reports a present file different from the published round-9 copy; `S10a`–`S10c` pass.

The reproducibility claim at `DECISION.md:52–61` also holds. A copy of the two run directories and topic under `/tmp` with no `.git` yielded `CHECKS RUN: 23 PASS: 20 FAIL: 0 SKIP: 3`. The unified diff against the committed in-place log is byte-identical to `supersession-check-r11-archive.diff`; only `S10a`–`S10c` skip, their progress line disappears, and the summary changes. The committed `supersession-check-r11-rerun.diff` has zero bytes.

The retained-note edits reported at `DECISION.md:69–80` are present: the revision-10 heading preserves its original heading text after “Its own heading recorded it as”; the `S8c` sentence at lines 218–220 names `supersession-check-r11.sh`, the 309 `CARRIED-FROM.md` rows, and the identities-file qualification; the revision-10 results row at line 228 scopes its 23/23 result to commit `c6b7d2b1` and names the successor. These are line checks of the current decision, not a judgment review.

## Findings

**[OBS] O1 — disclosed `V1a` revision drift reproduced.** `DECISION.md:82–88` says the retained `owned-value-check-r10.sh` pins the supersession heading at line 2685, that revision 11 moves it to line 2779, and that only `V1a` fails with `CHECKS RUN: 53 PASS: 52 FAIL: 1 SKIP: 0`. The rerun prints `FAIL V1a: supersession heading line number: expected 2685, got 2779` and exactly that summary. Every other output line matches the committed log. The disclosure holds.

**[OBS] O2 — disclosed future `S8c` limit reproduced in scratch.** `DECISION.md:63–68` says `review/identities.json` is one of the 309 rows and that replacing its `audits.*` entries makes `S8c` fail. The unmodified archive-style copy passes `S8c`. Changing only `audits.empirical.actor` in the `/tmp` copy yields `DIFFERS review/identities.json`, `FAIL S8c: carried files differing from the publishing run: expected 0, got 1`, and exit 1. The repository copy was not changed. The note qualifies the retained “on every run” sentence at lines 218–220. The disclosure holds.

**[OBS] O3 — historical checks observe later state.** `supersession-check-r10.sh` now exits 1 with `CHECKS RUN: 23 PASS: 16 FAIL: 7 SKIP: 0`: its old directory walk sees the fresh audit and seven revision-11 files, and its `S10` scan sees the new script. Its supersession by revision 11 is explicit at `DECISION.md:23–49,228`. `owner-reference-check-r9.sh` reports one prompt naming a release-profile key, instead of the committed zero: `research/topics/68-release-binary-artifacts/prompts/release-binary-artifacts.prompt.md` now names `[profile.release]` under owner ruling W0-R69p. This is point-in-time input drift; Q23 §7.7 bars re-pinning it. Neither result contradicts the current recommendation.

**[OBS] O4 — environment limits historical byte reproduction.** `state-bound-check.sh` still exits 0 and differs only because the recorded `rustc`/`cargo` 1.98.0 line is now 1.98.1. The `/tmp` offline `bacon-install-check.sh` copy cannot install `bacon` 3.25.0 because the provided private `CARGO_HOME` has no cached package. The prior committed install result is not disproved by that cache miss. The current revision-11 successor and its archived-copy control reproduced without these dependencies.
