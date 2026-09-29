# R29 revision 2 empirical re-run audit (r2c)

Companion to review/audit-codex.r2b.md, with the same verdict and a parseable header. r2b's header used `- key: value` list items, which the packager cannot parse. This re-run is independent, and its content agrees with r2b except where noted. Controller triage decides how the two audits relate.

decision-sha256: 4b8dac24ff10d60d5b7a692ac1d0cfc3050d931636b713f7220cc7d14893cd9b
actor: codex-empirical-r29-r2c
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
seat: codex (filename denotes the seat; the engine is Anthropic Claude Opus 5.5, not an OpenAI model)
rerun-date-utc: 2026-09-29

## Method

- The decision hash was verified before anything else was read, and again immediately before this file was written. Both reads gave the `decision-sha256` above.
- All seven evidence scripts ran unmodified from `review/evidence/`, except `r29-snapshots.sh`. That script writes to its own directory, so a byte-identical copy (`cmp` confirmed) ran from `/tmp/s87-r29-rerun/capture/`. No committed snapshot was overwritten.
- Environment switches are the scripts' own documented variables: `CARGO_HOME=/tmp/cargo-s87-r29`, `R29_WORK=/tmp/s87-r29-rerun/plugins`, and `PLUGIN_OUT=/tmp/s87-r29-rerun/plugins/out`. The private `CARGO_HOME` started empty. `cargo install dprint --version 0.57.4 --locked` (the script's own install line) therefore ran once as a separate foreground step. `r29-provision.sh` then took its skip branch, which is the same path as the committed log. The script ran in one invocation.
- Fixture repositories were created only under `/tmp` by the scripts themselves. All logs are in `/tmp/s87-r29-rerun/`.
- Network access was live and went only to the scripts' own endpoints: crates.io, `gh api`, and rustsec.org. No offline registry fallback was needed.
- Byte-identity of the run directory: a SHA-256 manifest of all 95 files under the run directory was taken before the first script and compared after the last. The manifests were identical. This file is the only addition.

## Re-run results

| Evidence script | Exit | Result | Full output compared with the committed log |
|---|---|---|---|
| `r29-snapshots.sh` (via `/tmp` copy) | 0 | 51 entries, OK | byte-identical |
| `r29-provision.sh` | 0 | `dprint 0.57.4`; four Wasm modules built from source | differs: cargo download/compile lines (fresh `R29_WORK`), module digests, sizes, and file dates (OBS-1) |
| `r29-dprint-stack.sh` | 0 | PASS=34 FAIL=0 | differs on one line only: the `built/published bytes` figures (OBS-1). `D0b` still reports worst ratio 0.0302 |
| `r29-lefthook.sh` | 0 | PASS=6 FAIL=0 | byte-identical |
| `r29-taplo-compare.sh` | 0 | PASS=12 FAIL=0 | byte-identical |
| `r29-sources.sh` (committed snapshots) | 0 | PASS=25 FAIL=0 | byte-identical |
| `r29-decision-checks.sh` | 0 | PASS=11 FAIL=0 | byte-identical |
| `shellcheck` over the seven `r29-*.sh` | 0 | version 0.11.0; all seven clean; `shellcheck-total-exit=0` | byte-identical to `shellcheck.log` |

Host tools match the committed host line: `dprint 0.57.4`, Python 3.14.7, actionlint 1.7.12, lefthook 2.1.14, just 1.57.0, and `cargo 1.98.1 (Homebrew)`. The Wasm toolchain is rustup 1.93.0, and `taplo` is 0.10.0.

No rerun contradicts a decision claim. Every PASS/FAIL outcome equals the committed outcome.

## Findings

No BLOCKING finding.

## Observations (not fixed; rerun only)

- **OBS-1 — Built-module bytes differ, as the decision discloses.** The fresh builds produced these sizes (rerun versus committed): json 643875 versus 643865; markdown 743239 versus 743253; toml 514614 versus 514607; pretty_yaml 594430 versus 594430. All four SHA-256 digests differ from the committed `SHA256SUMS`, including pretty_yaml, whose size is unchanged. `D0b` passes with the same worst ratio of 0.0302 against the 3.1% limit. `DECISION.md:11` states that "the committed built-module digests do not reproduce elsewhere". This is disclosed drift.
- **OBS-2 — Lefthook marker drift seen by r2b did not recur.** r2b's OBS O2 reported `H3` and `H4` failing on `✓` versus `✔️`. In this rerun, lefthook 2.1.14 printed the committed marker, and the log is byte-identical (PASS=6). The earlier drift was host-state or run-specific. No action is needed.
- **OBS-3 — Rolling figures in the fresh capture; two `re-verify:` triggers have fired.** The fresh snapshots were retrieved 2026-09-29T18:16:47Z–18:17:09Z. A copy of `r29-sources.sh` ran from the `/tmp` capture directory against them and gave PASS=20 FAIL=5:
  - `S8` fails on moved figures. crates.io now shows `dprint` 0.58.0 (2026-09-29) and `dprint-plugin-json` 0.25.0 (2026-09-27).
  - `S9` fails on moved figures: stars and pushed dates.
  - `S1f` fails only because taplo's star count moved from 2402 to 2403. The taplo-cli release (0.10.0) and the `pushed_at` value (2026-07-28) are unchanged.
  - `S6` and `S7` fail only because of where the copy ran: it looks for `../fixtures/tree/` next to the copy, and that directory does not exist there. These two failures are not drift. Both checks pass in the in-place run.

  `DECISION.md:163` anticipates that a recapture makes `S8`/`S9` fail. `DECISION.md:126` names "dprint 0.58 or any plugin's next minor release" as early `re-verify:` triggers. Both have now occurred: dprint 0.58.0 and json plugin 0.25.0. The recorded point-in-time claims still reproduce against the committed snapshots.
- **OBS-4 — Live `research/EXECUTION.json` differs from the S87 pin.** The live SHA-256 is `644fc3e7…e9a8`, and the pin is `fd746cb8…a545c`. Under the no-repin rule this is never a finding. The pin is cited as given.
- **OBS-5 — The run directory is untracked in git.** `git status` shows the whole run directory as `??`. Therefore, byte-identity was established by the SHA-256 manifest described under Method, not by `git diff`.

## End summary

- Verdict: approve. Unresolved findings: none.
- Rerun totals: snapshots OK, 51 entries, identical. Provision OK; differs per OBS-1. dprint-stack 34/0; differs on one line, OBS-1. lefthook 6/0, identical. taplo-compare 12/0, identical. sources 25/0, identical. decision-checks 11/0, identical. shellcheck 0.11.0, exit 0, identical.
- The audit file's own SHA-256 cannot be recorded inside the file without changing it. It is printed to stdout and the progress log after writing.
