# R29 revision 2 empirical re-run audit

SUPERSEDES review/audit-codex.r2.md (blocked on evidence-sufficiency only, no contradiction — same DECISION rev, re-run under the standing evr rule).

- actor: codex-empirical-r29-r2b
- model: gpt-6
- family: openai
- decision-sha256: 4b8dac24ff10d60d5b7a692ac1d0cfc3050d931636b713f7220cc7d14893cd9b
- execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c (`research/EXECUTION.json`, S79 point-in-time pin)
- verdict: approve
- unresolved-findings: none

## Re-run and byte comparison

The target decision hash was checked before reading or running evidence and checked again before this file was written. Each script's output went to `/tmp/r29-codex-r2b-<name>.log`; the snapshot capture used a copy of its script under `/tmp/r29-codex-r2b-capture/`, so no committed snapshot was overwritten. The other scripts read the committed snapshots and run inputs. Fixture scripts created temporary repositories under `/tmp`; the source worktree and its Git metadata were not mutated. The first sandboxed network attempts could not resolve crates.io; the capture and provisioning succeeded with network permission. The first sandboxed Taplo run panicked in macOS system configuration; the repeat with network permission completed and is the compared re-run.

| Evidence script | Re-run result | Full output versus committed log |
|---|---|---|
| `r29-snapshots.sh` | 51 captures; exit 0 | byte-identical |
| `r29-provision.sh` | `dprint 0.57.4` and four source-built Wasm modules; exit 0 | differs: fresh cargo installation/build output, module sizes and digests, file dates |
| `r29-sources.sh` | PASS=25 FAIL=0; exit 0 against committed snapshots | byte-identical |
| `r29-dprint-stack.sh` | PASS=34 FAIL=0; exit 0 | differs: built-module sizes and `D0b` ratio; order of two file names in the unsorted display of the authored file list |
| `r29-lefthook.sh` | PASS=4 FAIL=2; exit 1 | differs only at `H3` and `H4` and their printed hook output; see OBS O2 |
| `r29-taplo-compare.sh` | PASS=12 FAIL=0; exit 0 | byte-identical |
| `r29-decision-checks.sh` | PASS=11 FAIL=0; exit 0 | byte-identical |

The separate `shellcheck.log` re-run of all seven scripts is byte-identical to the committed log (`shellcheck` 0.11.0, total exit 0). The full log comparison found no other changed lines in `r29-dprint-stack.log` or `r29-lefthook.log`.

## Findings

- **OBS O1 — Disclosed build and capture drift.** The fresh build changed module bytes: JSON 644001 versus committed 643865, Markdown 743368 versus 743253, TOML 514744 versus 514607, and pretty_yaml 594499 versus 594430. `D0b` still passes at worst ratio 0.0304, within the stated 3.1% limit; all 34 stack checks pass. `DECISION.md:11` explicitly says “the committed built-module digests do not reproduce elsewhere.” `DECISION.md:163` says “Rerunning the capture refreshes rolling figures, so `S8` and `S9` would then fail until re-read against the new values.” The fresh capture's log remains byte-identical, but a copy of `r29-sources.sh` against the refreshed snapshots yields PASS=22 FAIL=3: `S8` and `S9` reflect changed downloads, stars, pushes, and a new `dprint-plugin-json` 0.25.0 release; `S1f` also fails solely because taplo's star count moved from 2402 to 2401. The new plugin minor release meets the decision's explicit `re-verify:` trigger (`DECISION.md:125`); the pinned 0.24.0 fixture and its point-in-time source checks remain reproduced. The authored file list prints `README.md` and `docs/guide.md` in the opposite order, while `D4b` confirms the same 11-file set.
- **OBS O2 — Lefthook success-marker assertion drift.** `r29-lefthook.sh:61,75` requires the literal `✔️ format-files` in the hook output. The re-run prints `✓ format-files`; both `H3` and `H4` commits exit 0, and the output shows the `format-files` job ran successfully. The script therefore records FAIL=2 and exits 1, but the asserted behavior at `DECISION.md:194-195` holds. `H0`, `H1`, `H2`, and `H5` pass, including the expected exit 20 and exit 14 failures. This is an output-text assertion failure, not a contradiction of hook behavior.
- **OBS O3 — Revision-2 repair holds at the read lines.** `DECISION.md:63` assigns `check-files` to the checking composite and `format-files` to the writing composite; `DECISION.md:124` hands that membership to R27 while leaving F102's Rust step with R27. `DECISION.md:248-255` states the Muse/Opus disagreement and chooses option (a). The cited Muse proposal is present at `raw/muse.md:832-835`; Opus's deferral appears at `raw/opus.md:373,843-844,854`; R27's owner wording appears at `research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/DECISION.md:51`. The revision note describes these repairs at `DECISION.md:3,7,9`. `C1a`, `C1c`, and `C4` pass, and the full decision-check log is byte-identical. The composite itself remains unexecuted as disclosed at `DECISION.md:9,63`; `D14` and `D15c` reproduce the called recipe's success and drift exit 20.

No BLOCKING finding remains. This is the one Q23 empirical re-run worker's result for the same decision revision; controller triage follows the handoff.
