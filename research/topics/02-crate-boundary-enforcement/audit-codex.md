actor: codex
model: gpt-6
family: openai
decision-sha256: d8c64f7c36663f0c92dcc83cc444a56f203f6c4f52d3fff2a64de9f611cfd2e7
verdict: approve
unresolved-findings: none

# Directed empirical verification — R02 revision 3

## Bound input and rerun method

The required `shasum -a 256` gate matched before I read the decision. I recomputed it before writing this audit. The revision-2 snapshot hashes to `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f`, matching both round-2 audits. I compared that snapshot with revision 3 and checked only the eight assigned repairs.

I extracted `git archive 542ad225` (`542ad22586b28cfc3a5c15bf2b7af7308e42f8bf`) into `/tmp/r02-codex-r3vo.xb9tyE/tree`, with no `.git` directory. I overlaid the worktree's revision-3 `DECISION.md`, the three edited scripts, their three recorded logs, and `evidence/snapshots/`. Every rerun used the extracted `review/evidence/` as its working directory, with `CARGO_HOME=/tmp/r02-codex-r3vo.xb9tyE/cargo-home`. The probe also inherited a foreign `CARGO_TARGET_DIR=/tmp/r02-codex-r3vo.xb9tyE/foreign-target`. Fresh outputs went under `/tmp/r02-codex-r3vo.xb9tyE/logs/`. No script ran against the live worktree. `shellcheck` exited 0 on all five evidence scripts.

| Script | Fresh result | Comparison with recorded revision-3 log |
|---|---|---|
| `r02-check-r2.sh` | exit 0; 66 checks, 0 failures, 0 skips | `cmp` exit 0: byte-identical |
| `r02-workspace-probe.sh` | exit 0; 26 checks, 0 failures, including both `B4` passes | All 26 verdict lines identical. `cmp` exit 1; the 284-line logs become identical after filtering only the `mktemp` suffix, Cargo `Finished` timing, and labelled toolchain version lines. |
| `r02-ecosystem-figures.sh` | exit 1; 35 checks, 1 failure, 0 skips; only `EF6a` fails | All 35 verdict lines identical. `cmp` exit 1; the only changed lines are four absolute extraction paths. Replacing each archive-root prefix makes the 86-line logs identical. No volatile counter changed on this rerun. |

## Repair confirmations

- **EA-1:** At `542ad225`, `R2-9a` classifies all four external `OV-03` files as owner records or acknowledgements, and `R2-9b` no longer claims a file count. `DECISION.md:248` names the four files and classification rule. `DECISION.md:241` quotes the superseded byte-identity claim as superseded wording. The check rerun is byte-identical to its log.
- **EA-2:** `r02-check-r2.sh:451` and `:458` use `^#+ .*OVERRIDE \(OV-03\)` and its `OV-02` twin. These match heading levels beyond H3 and tolerate a backtick before `OVERRIDE`. `R2-9d` reports zero competing declarations; `R2-9e` finds one `OV-02` declaration as its positive control.
- **EA-3:** `newest_asof` at `r02-ecosystem-figures.sh:107` reads each `/versions` snapshot and selects the newest non-yanked version dated no later than 2026-09-17. All five `EF4-*` assertions pass. The fetched `guppy` versions give 0.18.0 as of that date and 0.19.1 today, printed under `VOLATILE (not asserted)`. `DECISION.md:277` uses the time-bound wording.
- **EA-4:** `r02-workspace-probe.sh:22` unsets the caller's target directory, `:49` rejects empty input for every `absent` check, and `:293`–`:305` gate the `B4` absence assertion on successful `ls` and an exact `rslbp` listing. The foreign-target rerun passes 26/0. As a negative control, removing only the `unset` line in a `/tmp` copy makes both `B4` halves fail, yielding 26 checks and 2 failures. `DECISION.md:266` states that scope.
- **EA-5:** `DECISION.md:277` now says “about 13 times (one order of magnitude above) the 190.” The recorded figures give 2,426 / 190 = 12.77.
- **EA-6:** `r02-workspace-probe.sh:79`–`:81` labels the three toolchain lines `VOLATILE (not asserted)`. `DECISION.md:231` records the 1.98.1 rerun and `:259`–`:260` names toolchain version lines in the comparison filter. The probe comparison above leaves no other differences.
- **JF-5:** `DECISION.md:297` says “eight times across three lines” and cites both `R2-2f` and `R2-2f2`. I independently counted eight `R01` occurrences on three lines in `inputs/prompt.md`; both checks pass.
- **JF-6:** `DECISION.md:213` distinguishes the six positive checks from exhaustiveness and cites both supporting records. `docs/planning/p02/owner-decisions.md:398` says “the six W1-R02 substitutions only.” The R69 revision-10 approving judgment audit is bound to `d34ab6e8…`, which matches that decision's recomputed SHA-256, and its lines 264–274 state that no owned-value clause moved beyond the six substitutions.

## Observation for the controller — later R77 sequencing

The pinned archive's R77 decision has one allowed `OV-03` reference at line 1090, saying the number is taken. The later live worktree file `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md` has two additional references at lines 1353 and 1387 that name neither `R02` nor “taken.” Swapping only that live R77 file into the extraction makes `R2-9a` print `UNCLASSIFIED: 0 heading line(s), 2 line(s) naming neither R02 nor taken` and fail; the rerun ends at 66 checks, 1 failure, 0 skips. This is a sequencing observation outside the pinned `542ad225` verification, not a dispute of EA-1.

## S1 adjudication (2026-09-28, Q23)

- File verdict was approve and stays approve. `decision-sha256` re-bound 283c6dd0e9d2 -> d8c64f7c3666 across the S1-attested micro-repairs below (S60 OBS-LEFT: :166 now-false census claim, :315/:320 stale toolchain scope); S1 verified by diff that no other byte changed. Original approval transfers under the Q23 verdict-transfer rule.
- S1 repairs (three clauses):

```diff
- outside this item returns **0** files, and the same search
+ outside this item returns **0** files at pin `542ad225`, and the same search
(at :166; EF6a census was recorded at the pin, figures disclose live-tree growth)
- Every executed result here is macOS arm64 at 1.98.0 only.
+ Every executed result here is macOS arm64 at 1.98.0 (probe re-executed at 1.98.1, 26/0).
(at :315; S60 evidence: probe 26/0)
- - Every compile, clippy and metadata result is macOS 26.4 arm64 at `rustc`/`cargo` 1.98.0. Nothing [...]
+ - Every compile, clippy and metadata result is macOS 26.4 arm64 at `rustc`/`cargo` 1.98.0, except the probe re-execution at 1.98.1 (26/0). Nothing [...]
(at :320; same probe record)
(the only byte changes r3-prerepair -> r3-final)
```
