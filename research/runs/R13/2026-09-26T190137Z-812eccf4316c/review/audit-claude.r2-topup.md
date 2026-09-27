actor: claude-topup
model: claude-opus-5-5
family: anthropic
decision-sha256: 4a7b28dcf177941be63bfa3ed69ec71f0db50fe7c26508573c9465087079b942
verdict: approve
unresolved-findings: none

# R13 revision 2 — empirical top-up audit (re-frozen evidence)

**Scope.** This audit judges only the execution truth of the re-frozen R13 evidence against `review/DECISION.md` revision 2. It does not re-judge the recommendation. It did not read any `review/audit-*.md` or `review/Rxx-r*-snapshot.md` file. Audit date: 2026-09-27. Host: `Darwin 25.4.0 arm64`. Working directory: the repository root `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.

## Target identity

`shasum -a 256 review/DECISION.md` returned `4a7b28dcf177941be63bfa3ed69ec71f0db50fe7c26508573c9465087079b942`. This equals the expected hash, so the audit proceeded.

## Results

| Script | Fresh output | Exit | Byte-compare against the committed log | Totals |
|---|---|---|---|---|
| `r13-inputs.sh` | `/tmp/r13topup2-inputs.log` | 0 | `cmp` identical to `r13-inputs.log` (sha256 `f99ca7430eab75165ca1f86fd0456d7054f0e66e981a8bb706bba407f8d6b38f`) | PASS=30 FAIL=0 SKIP=0 |
| `r13-gap.sh` | `/tmp/r13topup2-gap.log` | 0 | `cmp` identical to `r13-gap.log` | PASS=13 FAIL=0 SKIP=0 |
| `r13-sources.sh` | `/tmp/r13topup2-sources.log` | 0 | `cmp` identical to `r13-sources.log`; this run includes the live re-fetches `L01`–`L15` | PASS=73 FAIL=0 SKIP=0 |
| `r13-tools.sh` | not run (see Limitation) | — | — | committed log states PASS=30 FAIL=0 SKIP=0 |

The totals for inputs, gap and sources match the `## Empirical check` table in the decision (30, 13 and 73 checks).

## I01 pinned hash against the live freeze

- The `I01` line in the committed and fresh logs: `PASS I01: prompt sha256 de076d46d1f8ad670158ee85664f50049d0f630836469f2d151b39f5a26ed5bb`.
- `shasum -a 256 inputs/prompt.md` returned `de076d46d1f8ad670158ee85664f50049d0f630836469f2d151b39f5a26ed5bb`.
- `manifest.json` `input_hashes.prompt` (line 45) holds the same value.

The script checks three values: the live prompt hash, the manifest hash and the hard-coded pin. All three agree.

## Prior scratch logs

`/tmp/r13topup-gap.log` and `/tmp/r13topup-sources.log` are byte-identical (`cmp`) to this audit's fresh reruns. They are therefore corroborating evidence only. The verdict rests on the fresh reruns.

## Limitation: tools not rerun

As instructed, this audit did not run `r13-tools.sh`. That script is network-dependent: it downloads pinned release binaries and runs the tools live. The prior partial scratch log `/tmp/r13topup-tools.log` (11 lines: an `INFO T0` toolchain line plus `PASS` for `T0`, `T1a`–`T1d`, `T2a`, `T2`, `T3`, `T4` and `T5`) is byte-identical to the first 11 lines of the committed `r13-tools.log`. Checks `T6`–`T15` were not re-executed in this top-up. For them, the revision-2 tools approval stands unchanged. This audit neither confirms nor weakens it.

## Side-effect check

`r13-inputs.sh` writes a transient file, `evidence/.assumes.out`, and removes it before exit. A sha256 listing of all 84 files under the run directory, taken before and after the three reruns, was identical (`/tmp/r13topup2-before.sha` compared with `/tmp/r13topup2-after.sha`). No committed evidence file changed.

## Observation (not a finding)

The file times show that `r13-inputs.sh` and `r13-inputs.log` (2026-09-27 00:51) were re-frozen after `DECISION.md` (2026-09-26 21:00). Revision 2's note says "every evidence script, log … is untouched". That statement describes the revision-1 → revision-2 step. The re-frozen inputs log still reproduces byte-for-byte, and it still matches the decision's `30 | PASS=30 FAIL=0 SKIP=0` row. The re-freeze therefore changes no claim this audit is scoped to judge.
