actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 56bb55f9830c61c9cec9838203f5a60135de96cb6706fdf3a7a6ac8fa45907dd
verdict: reject
unresolved-findings:
- E1 — `I-policy` fails on rerun; the frozen run policy is no longer byte-identical to live `research/EXECUTION.json`.
  - Failed claim (`DECISION.md:223`): "`review/evidence/r12-inputs.sh` | 45 | PASS=45 FAIL=0 SKIP=0 | run prompt and policy byte-identical to the live published files (`I-prompt`, `I-policy`)". Also `DECISION.md:258`: "This revision re-freezes `inputs/prompt.md` and `inputs/EXECUTION.json` to those live files (`I-prompt`, `I-policy`)."
  - Evidence: a rerun of `r12-inputs.sh` exits 1 with `FAIL I-policy -- policy drift` and `RESULT PASS=44 FAIL=1 SKIP=0`. The committed log shows `PASS I-policy …` and `RESULT PASS=45 FAIL=0 SKIP=0`. Frozen `inputs/EXECUTION.json` has sha256 `c670184d…` (mtime 2026-09-26T21:33:44 local). Live `research/EXECUTION.json` has sha256 `acdcbfff5fa46a68cd0999147b294e41fa6c4d6c88428c9fc7c46cdedfabf137` (mtime 23:30:19 local, about 1 h 48 min after the decision's 21:42 mtime). A structural JSON diff shows one change only: 44 new keys under `empirical_auditor_overrides`, including `"R12": "claude"`. `engine_overrides["R12"]` and `items["R12"].engines` are `["muse", "opus"]` in both files. `I-override`, `I-prompt-engines` and `I-runbook-q17a` still pass.
  - Assessment: this is controller-side policy drift after the decision was written, not a synthesis error. The recommendation and every other check are unaffected. RUNBOOK §5 still requires current consumed inputs for acceptance. The byte-equality claim does not hold at audit time, and the committed log no longer reproduces.
  - Repair: the controller re-freezes `inputs/EXECUTION.json` from the live `research/EXECUTION.json`. Then it reruns `r12-inputs.sh` last, recommits `r12-inputs.log` (expected `PASS=45 FAIL=0 SKIP=0`), and updates the revision-2 note's policy hash (`c670184d…` → the new sha256). Forward risk: `empirical_auditor_overrides` grows each time an audit seat is dispatched. Freeze immediately before publication, or this check will break again.

# R12 revision 2 — empirical audit (claude)

Scope: execution truth and evidence support only. Target `review/DECISION.md` revision 2. Before any other step, `shasum -a 256` returned `56bb55f9830c61c9cec9838203f5a60135de96cb6706fdf3a7a6ac8fa45907dd`, which matches the expected value.

## Environment

- Host: Darwin 25.4.0 arm64. `actionlint` 1.7.12 at `/opt/homebrew/bin/actionlint`; `shellcheck` 0.11.0; `jq` at `/opt/homebrew/bin/jq`; `gh` authenticated for read-only public API calls. Each script prepends `/Users/stevemorin/.local/bin:/opt/homebrew/bin` to PATH itself.
- Working directory: the repository root `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Private `CARGO_HOME` under `/tmp`; no script invokes cargo.
- Before the reruns, a sha256 manifest of all 66 files under `review/evidence/` was taken (`/tmp/r12-audit/evidence-before.sha`). After all reruns it matched exactly, so nothing under `evidence/` was written.

## Reruns

`E=research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/evidence`. Each fresh log went to `/tmp/r12-audit/<name>.log` and was compared with `cmp` against the committed `$E/<name>.log`.

| Command | Exit | Observed totals | `cmp` vs committed log | Result |
|---|---|---|---|---|
| `bash $E/r12-lint.sh` | 0 | `RESULT PASS=18 FAIL=0 SKIP=0` | identical | pass |
| `bash $E/r12-verdict.sh` | 0 | `RESULT PASS=43 FAIL=0 SKIP=0` | identical | pass |
| `bash $E/r12-ts.sh` | 0 | `RESULT PASS=8 FAIL=0 SKIP=0` | identical | pass |
| `bash $E/r12-citations.sh` | 0 | `RESULT PASS=39 FAIL=0 SKIP=0` | identical | pass |
| `bash /tmp/r12-audit/copy/evidence/r12-sources.sh` (see note 1) | 0 | `RESULT PASS=59 FAIL=0 SKIP=0` | identical | pass |
| `bash $E/r12-inputs.sh` (run last; see note 2) | **1** | `RESULT PASS=44 FAIL=1 SKIP=0` | **differs** | **fail (E1)** |
| **total** | | **PASS=211 FAIL=1 SKIP=0 of 212** | | |

The `r12-inputs.sh` diff against the committed log is two lines:

```
3c3
< PASS I-policy run policy snapshot is byte-identical to the live research/EXECUTION.json
---
> FAIL I-policy -- policy drift
51c51
< RESULT PASS=45 FAIL=0 SKIP=0
---
> RESULT PASS=44 FAIL=1 SKIP=0
```

Note 1 — `r12-sources.sh` writes into `evidence/snapshots/`, `PROVENANCE.md` and `SHA256SUMS` in place. It resolves `EV` from `$0`. It was therefore run from a copy (`cp -Rp $E /tmp/r12-audit/copy/evidence`), and the committed evidence stayed untouched. The copy's live refetch changed 7 snapshot files and `SHA256SUMS`: `PROVENANCE.md`, `r12-cancelled-cargo-{1,2,3}.json`, `r12-cargo-repo.json`, `r12-tokio-repo.json` and `r12-uv-repo.json`. The decision's "Reproduction" paragraph predicts this movement: rotating samples, stars and `pushed_at`. The assertion log was still byte-identical, so no structural or quoted-sentence assertion moved.

Note 2 — `r12-inputs.sh` resolves `ROOT` six directories up from `$0` and reads the committed sibling logs. It was run in place. This is equivalent to running it over the fresh logs, because all five fresh logs `cmp` identical to the committed ones.

`shellcheck` 0.11.0 over `$E/r12-*.sh`: exit 0 with no output. This agrees with the empty committed `shellcheck.log`.

## Re-freeze consistency (Q17.A)

These revision-1 → revision-2 differences are expected and were not treated as failures:

- `inputs/prompt.md` has sha256 `999cde07…`, byte-equal to live `research/topics/12-aggregate-required-status-check/prompts/aggregate-required-status-check.prompt.md`. The prompt's line 22 reads `- engines: muse, opus`. `I-prompt` passes.
- `HEAD`'s committed prompt is `3da9f7d2…`. `manifest.json` `input_hashes.prompt` is also `3da9f7d2…`, with `required_engines` `codex, opus`. The decision says this outright: it leaves the manifest as the pre-amendment dispatch record for the controller to re-snapshot (`I-manifest-dispatch`). This matches the revision note's `3da9f7d2… → 999cde07…`.
- Frozen `inputs/EXECUTION.json` has sha256 `c670184d…`, which matches the revision note's `2a3ca155… → c670184d…`. The re-freeze landed as described. Live policy moved afterwards; see E1.

## At-source re-derivations

These were computed from the fresh `/tmp` snapshots and with `jq` directly:

- `jq -n '{} | all(.[]; .result=="success")'` returns `true`. The recommended rule `length > 0 and all(.[]; .result=="success" or .result=="skipped")` over `{}` returns `false`. This supports the `V0` claim and the T9 claim.
- An unknown result (`{a:{result:"neutral"}}`) under the recommended rule returns `false`, so the rule fails closed. This supports T8.
- tokio's `main` requires 46 contexts. This supports the "46 contexts" claim.
- The `github-actions` app id is `15368`. cargo's ruleset pins `conclusion` to `integration_id` `[15368]`. This supports the P4 source-pinning claims.
- ts `main` protection returns `gh: Branch not protected (HTTP 404)`. This supports `S-ts-unprotected` and the Disagreement 7 premise.
- There are 9 `r12-cancelled-*.json` samples. This supports the "9 runs" claim.
- Script check counts are 18 + 43 + 59 + 8 + 39 + 45 = 212. This matches the decision's total.

## Conclusion

Five of the six scripts reproduce byte-for-byte, and every re-derived figure holds. The rerun of `r12-inputs.sh` fails `I-policy` because live `research/EXECUTION.json` changed after the decision was written: only `empirical_auditor_overrides` changed, and R12's engine fields did not. The verdict is reject until E1's re-freeze and log refresh land. No substantive repair to the recommendation is needed.
