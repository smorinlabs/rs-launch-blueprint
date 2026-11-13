actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: e755e0b2cd138ba5e304609fca005744888071bda2b7eb7ebe049c9e2d65258c
verdict: approve
unresolved-findings: none

# R12 aggregate-required-status-check — empirical audit, revision 3

Seat: empirical auditor, Claude seat under `empirical_auditor_overrides["R12"]` = `"claude"` (live `research/EXECUTION.json`; `research/RUNBOOK.md:98-103`). Fresh context, independent of the synthesizer and the judgment auditor. No `review/audit-*.md`, `research/topics/[NN]-*/raw/` or `review/Rxx-r*-snapshot.md` file was read.

## Target

`research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/DECISION.md`, revision 3. `shasum -a 256` before any other step: `e755e0b2cd138ba5e304609fca005744888071bda2b7eb7ebe049c9e2d65258c`, equal to the expected hash. Recomputed after the reruns: unchanged.

## Environment

- Host: `Darwin 25.4.0 arm64`, zsh session; scripts run with `bash` 5.3.20 at `/opt/homebrew/bin/bash`.
- PATH: `/Users/stevemorin/.local/bin:/opt/homebrew/bin` prepended, as `## Empirical check` specifies.
- Tools read from the tools: `actionlint` 1.7.12 (`/opt/homebrew/bin/actionlint`), `shellcheck` 0.11.0, `jq-1.8.2`, `gh` 2.101.0, `python3` at `/opt/homebrew/bin/python3`.
- Private cargo home: `CARGO_HOME=/tmp/cargo-claude-R12-r3-audit`, `CARGO_TARGET_DIR=/tmp/cargo-claude-R12-r3-audit-target`. No script invokes cargo.
- Working directory: repository root `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Scratch: `/tmp/r12-audit-r3/`.

**Evidence isolation.** `r12-sources.sh` writes `snapshots/`, `snapshots/PROVENANCE.md` and `SHA256SUMS` beside itself (`EV="$(dirname "$0")"`). To avoid overwriting committed evidence it was run from a copy at `/tmp/r12-audit-r3/evcopy/`. The other five scripts write only to `mktemp` directories and were run in place. A sha256 manifest of all 66 files under `review/evidence/` was taken before and after the reruns; the two manifests are byte-identical (`cmp` exit 0).

## Reruns

Each command's stdout+stderr went to `/tmp/r12-audit-r3/<name>.log`, then `cmp` against the committed `review/evidence/<name>.log`. `E` = `research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/evidence`.

| # | Command | Exit | Observed result line | `cmp` vs committed log |
|---|---|---|---|---|
| 1 | `bash $E/r12-citations.sh` | 0 | `RESULT PASS=47 FAIL=0 SKIP=0` | byte-identical |
| 2 | `bash $E/r12-lint.sh` | 0 | `RESULT PASS=18 FAIL=0 SKIP=0` | byte-identical |
| 3 | `bash $E/r12-ts.sh` | 0 | `RESULT PASS=8 FAIL=0 SKIP=0` | byte-identical |
| 4 | `bash $E/r12-verdict.sh` | 0 | `RESULT PASS=43 FAIL=0 SKIP=0` | byte-identical |
| 5 | `bash /tmp/r12-audit-r3/evcopy/r12-sources.sh` (live refetch) | 0 | `RESULT PASS=59 FAIL=0 SKIP=0` | differs at line 3 only (below) |
| 6 | `bash $E/r12-inputs.sh` (run last; reads the committed logs) | 0 | `RESULT PASS=50 FAIL=0 SKIP=0` | byte-identical |
| | **total** | | **PASS=225 FAIL=0 SKIP=0** | 5 of 6 identical |

The total equals the decision's claimed `PASS=225 FAIL=0 SKIP=0`, and each per-script count equals its row in the `## Empirical check` table.

**The one log difference.** `cmp` reports `differ: char 425, line 3`. `diff` shows a 4-line hunk; the first and only differing line is the `INFO pins:` line, where the clippy default-branch sha moved:

```
< ... clippy=072f108d4de4b8874e81faac05c4cdc88fc51537     (committed)
> ... clippy=57785c2b475d0e0998ba6a933de491ec0b342473     (this rerun)
```

The cargo, rust-analyzer, uv, ruff, clap and tokio pins, the docs pin `18945a31…` and the runner-image pin `ede07f8e…` re-resolved to the same commits. This is an `INFO` line, not an assertion. The decision's **Reproduction** paragraph states that `r12-sources.sh` re-resolves pins on every run and "may legitimately differ on figures that move", and that every cross-run assertion compares structure. The clippy assertion that depends on this fetch, `S-clippy-multi` ("clippy requires 4 aggregate contexts (per-workflow)"), still passes. The difference is therefore expected live drift, not a finding.

## Load-bearing figures re-derived at source

| Claim in the decision | Independent check | Result |
|---|---|---|
| Frozen policy sha256 `acdcbfff5fa46a68cd0999147b294e41fa6c4d6c88428c9fc7c46cdedfabf137` equals live policy (`I-policy`, `I-policy-hash-stated`) | `shasum -a 256 research/EXECUTION.json …/inputs/EXECUTION.json` | both `acdcbfff…f137` — holds |
| Frozen prompt is `999cde07…`, equal to live (`I-prompt`) | `shasum -a 256` of `inputs/prompt.md` and `research/topics/12-aggregate-required-status-check/prompts/aggregate-required-status-check.prompt.md` | both `999cde0721211613…cbaa` — holds |
| `engine_overrides["R12"]` = `["muse","opus"]`, `items["R12"].engines` = `["muse","opus"]`, `empirical_auditor_overrides["R12"]` = `"claude"` | `jq` over live `research/EXECUTION.json` | `{"eo":["muse","opus"],"eng":["muse","opus"],"eao":"claude"}` — holds |
| `research/RUNBOOK.md:73-76` names Q17.A and lists R12; `:98-103` is the empirical-auditor override rule | `sed -n` of those ranges | both match — holds |
| Recommended verdict is the `jq` allow-list with a length guard; it fails an unknown result (T8) and an empty `needs` (T9) | ran the fixture's exact program `length > 0 and all(.[]; .result == "success" or .result == "skipped")` over five inputs | success+skipped → exit 0; failure, cancelled, `weird`, `{}` → exit 1 — holds |
| `all()` over an empty set is true, so the length guard is load-bearing | `jq -n '[] \| all(.[]; false)'` | `true` — holds |
| py's real loop at `b55b8c2` is a deny-list that fails only on `failure`/`cancelled` | `git -C ~/c/py-launch-blueprint show b55b8c2:.github/workflows/ci.yml`, lines 322-334 | loop tests `"$r" = "failure" \|\| "$r" = "cancelled"` only, so an unknown result or an empty `RESULTS` passes — holds |
| `ci-ok` in the candidate needs all six R11 ids including `plan`, uses `if: ${{ always() }}`, `timeout-minutes: 5`, `permissions: {}`, explicit `name: ci-ok` | read `ci.candidate.yml:84-98` | all present — holds |
| All six scripts are `shellcheck` 0.11.0 clean; `shellcheck.log` is empty | `shellcheck $E/r12-*.sh` with both the PATH-resolved and the Homebrew binary | exit 0, 0 bytes of output each — holds |
| ts `main` unprotected (live 404) | asserted fresh by `S-ts-unprotected` in rerun 5 | PASS — holds |

## Non-blocking observation

`## Empirical check` gives `shellcheck` 0.11.0 "at `/opt/homebrew/bin/shellcheck`". With the stated PATH prefix, `shellcheck` resolves to `/Users/stevemorin/.local/bin/shellcheck`, a separate standalone binary. That binary also reports `version: 0.11.0`, and `/opt/homebrew/bin/shellcheck` (symlink into `Cellar/shellcheck/0.11.0`) gives the same clean result on all six scripts. The version, which is what the claim rests on, is correct; only the path is misattributed. No outcome depends on it, so it is not raised as a finding. A future revision may correct the path.

## Verdict

approve. All six scripts execute with exit 0 and reproduce the claimed `PASS=225 FAIL=0 SKIP=0`. Five logs are byte-identical to the committed logs. The sixth, the live refetch, differs only in one moving `INFO` pin that the decision's reproduction limits anticipate. Every load-bearing figure re-derived at source holds. The committed evidence tree was not modified.
