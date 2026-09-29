actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: dd4c07b66eb1dc6c405e6c52cdabaa4c1d4e2ce4905ff8ebd4b9f9c1937fe2e4
verdict: reject
unresolved-findings:
1. EF-1: `r28-inputs.sh` fails 40 of 148 cases against revision 2, but the decision reports it as passing.
   - **Failed claim.** `## Empirical check` table (DECISION.md:169) says: "`r28-inputs.sh` | **new** | 111 | PASS 111, FAIL 0 | input hashes, every `raw/*.md:N` citation, the `assumes` lines byte-for-byte, and this file's H2 shape". The revision-2 note (DECISION.md:3) says: "Every script and log under `review/evidence/` is carried into this revision **byte-identical** and no case was rerun, because no cited line moves."
   - **Evidence.** The rerun against the revision-2 bytes exits 1 and ends `== summary: 40 failing case(s)`. The committed log ends `== summary: 0 failing case(s)`. The failures fall into three groups:
     - (a) `FAIL I5-title — # 2026-09-26 — R28 — linter-and-editor-tooling (bundle, Focused) — decision (revision 2)` and `FAIL I5-note — revision-1 note present`. The script hard-codes `revision 1` at `r28-inputs.sh:71` and `:79`.
     - (b) Revision 2 raises the distinct raw citations from 39 to 76 (log line `76 distinct raw citations in DECISION.md`, previously `39`). The 37 new citations each fail with `citation has no fragment in this script's table`. They are `muse:195-197, 205-206, 222-223, 225, 225-226, 416-421, 577, 590, 591, 592-594, 594, 595-596, 692-693, 693-695, 697-698, 698-699` and `opus:265-266, 269-273, 274-275, 275-276, 276-278, 279-280, 280, 280-281, 617-622, 624-628, 627-628, 628, 629, 629-630, 630, 691-694, 697-699, 699, 700, 700-702, 704`. All of them sit in the new per-member gate table (DECISION.md:27-38) or the F100 paragraph (DECISION.md:113).
     - (c) `FAIL I1-canon` (see the observations below).
   - **Consequence.** The claim that every raw citation is verified by execution now covers 39 of 76 citations. The claim that this file's shape is verified is false for revision 2. "No cited line moves" is true of the revision-1 citations, but 37 cited lines were added. I checked those 37 by hand (see the re-derivations below), and they substantively resolve. The defect is therefore the evidence claim, not the content.
   - **Repair.** Revise `r28-inputs.sh` for revision 2. Accept `revision 2` in the I5 title regex and require the revision-2 note in I5-note. Add a quoted fragment for each of the 37 new citations to the I6 table. Give I1-canon an explicit disposition, either an expected-drift case keyed to the owner's Q17.A prompt edit or a comparison against the snapshot input. Rerun the script and commit the new `.log`. Then update the DECISION.md:169 row to the new case count and totals. Also amend the revision-2 note so it no longer says that no case was rerun.

# R28 empirical audit — revision 2

Scope: execution truth and evidence support for `review/DECISION.md` revision 2. The sha256 was recomputed with `shasum -a 256` before any other action and matches the expected value `dd4c07b6…e2fe4`. I read the decision (especially `## Empirical check` and `## Engines`) and `research/RUNBOOK.md` §5, and did not read any `review/audit-*.md`, `review/R28-r1-snapshot.md`, or `research/topics/*/raw/`. I hashed the revision-1 snapshot without opening it.

## Environment

macOS `Darwin 25.4.0 arm64`. `CARGO_HOME=/tmp/cargo-s29-R28-emp`, a private cargo home that differs from the synthesizer's `/tmp/cargo-s9-R28`. The toolchains are the ones the decision states: the `F0` gate in `r28-floor.log` asserts 1.96.x at the floor, and the stable versions appear in the log headers, identical to the committed logs apart from `CARGO_HOME`.

## Reruns

Each script was run from `review/evidence/` with this command:

```
bash r28-<name>.sh > /tmp/r28-audit-r2/r28-<name>.log 2>&1
cmp r28-<name>.log /tmp/r28-audit-r2/r28-<name>.log   # then diff on mismatch
```

No file under `evidence/` was written.

| Script | Exit | PASS | FAIL | SKIP | `cmp` | Every differing line |
|---|---|---|---|---|---|---|
| `r28-autofix.sh` | 0 | 5 | 0 | 0 | differ | `CARGO_HOME`, `mktemp` scratch path, scratch commit id (`cb98542`→`b65b6da`), `Finished … in 0.17s`→`0.12s` |
| `r28-editor-config.sh` | 0 | 6 | 0 | 0 | differ | line 2 only: `CARGO_HOME=/tmp/cargo-s9-R28` → `CARGO_HOME=/tmp/cargo-s29-R28-emp` |
| `r28-floor.sh` | 0 | 5 | 0 | 0 | differ | `CARGO_HOME`, scratch path, `Finished` timing |
| `r28-lint-table.sh` | 0 | 13 | 0 | 0 | differ | `CARGO_HOME`, scratch path (also inside `Checking …` and the L7 `failed to load manifest` path), timings |
| `r28-live-figures.sh` | 0 | 7 | 0 | 0 | differ | line 1 only: `== retrieved 2026-09-27T01:11:29Z` → `2026-09-27T06:16:37Z`; every figure is byte-identical, including 13536 stars and 2506 open issues for rust-clippy |
| `r28-ruff-fix-default.sh` | 0 | 2 | 0 | 0 | differ | line 3 only: scratch path |
| `r28-sources.sh` | 0 | 10 | 0 | 0 | differ | line 1 only: `== retrieved 2026-09-27T01:11:15Z` → `2026-09-27T06:16:42Z` |
| `r28-test-relaxation.sh` | 0 | 11 | 0 | 0 | differ | `CARGO_HOME`, scratch path, `finished in 0.01s`→`0.00s`, and the committed line 28 `warning: build failed, waiting for other jobs to finish...` is absent in the rerun |
| `r28-inputs.sh` | **1** | 108 | **40** | 0 | differ | see EF-1 |

Totals are 167 PASS, 40 FAIL and 0 SKIP across 207 cases. Eight scripts fail 0 cases, and `r28-inputs.sh` fails 40.

For the eight scripts that fail 0 cases, every difference is run-local noise. That noise consists of the cargo home, the `mktemp` path, the scratch commit id, the wall-clock timings and the retrieval timestamp. The `test-relaxation` warning line is emitted by cargo's parallel job scheduling after the first error in T3. It is not a result: `grep -E '^(PASS|FAIL)'` output is identical between the committed and fresh logs, and T3 still reports `PASS T3 — helper unwrap fires at tests/integration.rs:2 (exit 101)`. So the controller's premise that the logs are byte-stable holds only after these normalizations. No verdict line drifted in those eight scripts. `r28-inputs.sh` is the one real drift, recorded as EF-1.

`r28-inputs.sh` I9 confirms the counts in the decision's table for the other eight scripts. The table claims 13, 11, 5, 5, 6, 10, 7 and 2 cases, and I9 reports `PASS I9-r28-<name> — PASS n FAIL 0 (expected n)` for each. I10 confirms that every script is shellcheck-clean and that there is one `.log` per `.sh` (9 scripts).

## Re-derivations at source

- **The 37 citations that revision 2 adds.** I read each cited line range in `raw/muse.md` (946 lines) and `raw/opus.md` (943 lines). Every range lies inside its file and supports its gate-table cell or the F100 sentence. Examples:
  - The CodeLLDB G4 quotation "Linux with glibc 2.18+ for x86_64, aarch64 or armhf; MacOS 10.12+ for x86_64 and 11.0+ for arm64" is verbatim at `raw/opus.md:700-701`.
  - The F100 formatter-side sentence is at `raw/muse.md:416-421`.
  - The clippy `MIT OR Apache-2.0` statement with both licence files present is at `raw/opus.md:274-275`.
  - The rust-analyzer weekly releases and `pushed_at` 2026-09-26 are at `raw/opus.md:617-622`.
- **CodeLLDB releases.** Live `gh api repos/vadimcn/codelldb/releases` returns `v1.12.3 2026-08-23T23:40:44Z` and `v1.12.2 2026-04-21T03:20:56Z`. That matches the Maintenance cell.
- **Revision-1 snapshot hash.** `shasum -a 256 review/R28-r1-snapshot.md` returns `90cbe6ce44b7291afdeca2c3a373f6e2d6a584e204672fc8e6f098ff7511759b`. That matches the value in the revision-2 note.
- **Live figures.** The fresh `r28-live-figures.log` matches every figure quoted under `## Empirical check`. G1–G3 give licences Apache-2.0, Apache-2.0 and MIT, and `rustsec.org` returns 404 for `clippy` and `rust-analyzer`.

## Observations (not findings)

- **`I1-canon` drift.** The canonical prompt `research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md` (sha256 `f50ecd2a…985b`, uncommitted working-tree edit) differs from `inputs/prompt.md` (sha256 `d21a739c…3c38`). The difference is `- engines: codex, opus` → `- engines: muse, opus` plus one sentence about the Muse substitution. That edit is the owner's Q17.A engine decision, which revision 2 records as the controller's to resolve. It is folded into EF-1's repair only because the same script reports it.
- **Endpoint attribution.** The CodeLLDB Maintenance cell names `GET https://api.github.com/repos/vadimcn/codelldb/releases`, but the cited `raw/opus.md:691-694` does not contain that endpoint. The concentration signal the cell says is "noted there" is at line 695, one line outside the range. The fact itself is confirmed live, so this does not block acceptance. A repair could widen the range to `691-695` and attribute the endpoint to this rerun.
- **Evidence not under version control.** The run directory is untracked (`git status`: `?? research/runs/R28/2026-09-26T190151Z-059af1e15f51/`). As a result, "carried byte-identical" cannot be checked against a committed revision-1 tree. The mtimes are consistent with it: the evidence files run 17:58–18:19, before the revision-1 snapshot at 21:16.
- **Not verified here.** Revision 2 says that "the round-1 empirical (Claude) audit approves (169 PASS against 170 cases …)". I cannot verify that statement, because reading `audit-*.md` is outside my permitted reads.
