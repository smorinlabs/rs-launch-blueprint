# R28 revision 3 — empirical audit

actor: codex-empirical-r28-r3
model: gpt-6
family: openai
decision-sha256: c607a34e01f36673d0be729a826ee10fdd5ed77c94a31dcde3726ab2cd7e8519
verdict: blocked
unresolved-findings:
- BLOCKING E1 — `r28-autofix.sh` could not be rerun under this dispatch's prohibition on Git subcommands; the decision's A4 claim remains independently unverified.
- BLOCKING E2 — `r28-inputs.sh` could not be rerun under this dispatch's prohibition on reading `inputs/`; the revision-3 EF-1 repair remains independently unverified.

## Method and findings

The decision SHA-256 matched before any other read and matched again immediately before this audit was written. The rerun set `CARGO_HOME=/tmp/cargo-s73-R28-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s73-R28-evr-target`. Outputs and complete unified diffs were written under `/tmp`. No Git command, `inputs/` read, or live `research/EXECUTION.json` read was made by this worker.

- **BLOCKING E1 — autofix evidence cannot be re-executed.** The decision says, “`lint-fix` refuses a dirty tree, then applies a machine-applicable fix on a clean one, after which the gate passes” (A4, line 125), citing F2–F5. `r28-autofix.sh` lines 104–128 invoke `git init`, `git add`, `git commit`, `git rev-parse`, `git checkout`, and `git diff`. Running that script would breach the dispatch's “git (any subcommand)” prohibition. Its five committed PASS results were read but not reproduced. This leaves a load-bearing part of the selected opt-in autofix recipe without the required independent rerun; it is an evidence-sufficiency finding, not a demonstrated contradiction.
- **BLOCKING E2 — revision-3 input repair cannot be re-executed.** The revision note says `r28-inputs.sh` was revised and rerun to cure EF-1 (line 3), and the empirical table reports 157 PASS and zero FAIL (line 173). The script reads `inputs/prompt.md`, `inputs/EXECUTION.json`, `inputs/prerequisites.json`, and `inputs/parameters.json` at lines 36–69 and 221. Running it would breach the dispatch's “inputs/” prohibition. Its committed log reports 157 PASS, including `I1-canon` and I11, but the claimed repair and citation coverage remain without the required independent rerun. This is an evidence-sufficiency finding, not a demonstrated contradiction.
- **OBS O1 — seven permitted scripts passed.** `r28-lint-table.sh` 13/13, `r28-test-relaxation.sh` 11/11, `r28-floor.sh` 5/5, `r28-editor-config.sh` 6/6, `r28-ruff-fix-default.sh` 2/2, `r28-sources.sh` 10/10, and `r28-live-figures.sh` 7/7: 54 PASS, zero FAIL. Every script exited zero on its successful rerun. For each script, a full-file `cmp` found differing bytes, and a full-file `diff -u` was inspected. The complete PASS/FAIL lines match the committed logs byte-for-byte.
- **OBS O2 — complete-output drift is disclosed and does not change a conclusion.** The local diffs contain the specified Cargo home, random scratch paths, elapsed build or test times, one Cargo scheduling warning, and an L11 compiler-target label that varies between `bin "r28-cli"` and `bin "r28-cli" test`; L11 remains PASS in both. `r28-sources.sh` differs only in retrieval timestamp, and its pinned-source payload and case output match. `r28-live-figures.sh` differs in retrieval timestamp, current stars, push times, one issue count, and the `clippy` shim's download counts; the licence, archive, advisory, and shim-version outcomes match. This confirms the decision's run-local and retrieval-drift disclosure for the portions re-executed, though the current live figures have moved beyond the particular counts quoted at line 175.
- **OBS O3 — network retry.** The first source and live-figure runs could not reach public endpoints from the default sandbox and exited one. Both succeeded when rerun with network permission for their read-only requests; O1 and O2 use those successful outputs.
- **OBS O4 — revision-note prose repairs appear at the quoted lines.** The R30 hand-off and its conditional settings-key ownership appear at decision lines 101 and 117; the R30 re-verification trigger appears at line 140, and the joint-leg R30 statement appears at line 207. The CodeLLDB maintenance cell cites `raw/opus.md:691-695` and the `/releases` source at `raw/opus.md:916` on line 39. The revised input script and committed log contain the named `I1-canon`, snapshot-hash, and I11 cases, but their truth was not independently checked because of E2.

The two BLOCKING findings concern required reruns that this dispatch forbids. The seven completed reruns show no outcome-changing contradiction in their executed cases.
