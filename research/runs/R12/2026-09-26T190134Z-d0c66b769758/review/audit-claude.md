actor: audit-claude-R12-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: a27c0e056bc4d6ed94bf01a54e30fb6e85a66c7b61f3567922a217e491e84137
verdict: reject
unresolved-findings:
1. `r12-inputs.sh` now exits 1 on `I-prompt`, and the decision does not record the authority under which Muse replaced the frozen `codex` engine (details below under "Finding 1").

# R12 revision 1 — empirical audit (Claude seat)

Scope: execution truth and evidence support for
`research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/DECISION.md`,
revision 1. The hash was verified before any other action:
`shasum -a 256` printed `a27c0e056bc4d6ed94bf01a54e30fb6e85a66c7b61f3567922a217e491e84137`,
which equals the expected hash.

## Environment

- Host: macOS 26, `Darwin 25.4.0 arm64`. Working directory: the repository root
  `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.
- `PATH` prefix: each script exports `/Users/stevemorin/.local/bin:/opt/homebrew/bin` itself.
- `shellcheck` 0.11.0. `actionlint` 1.7.12 at `/opt/homebrew/bin/actionlint` (asserted by `L0`).
- Private cargo home: `CARGO_HOME=/tmp/cargo-s14-R12-emp`. No script invokes cargo.
- Audit time: 2026-09-27 ≈03:29 UTC (2026-09-26 20:29 PDT).

## Reruns

`r12-lint.sh`, `r12-verdict.sh` and `r12-inputs.sh` write only to a `mktemp -d`
directory, so they ran in place. Their stdout+stderr went to `/tmp/r12-audit/`.

`r12-sources.sh` writes into `$EV/snapshots/` and `$EV/SHA256SUMS`. It therefore
ran on a copy: `cp -Rp …/review/evidence /tmp/r12-audit/ev`, then
`bash /tmp/r12-audit/ev/r12-sources.sh`. The script resolves `EV` from `$0`, so every write
landed in the copy.

After all reruns, the sha256 of every file under `review/evidence/` (including
`snapshots/`) was identical to the pre-run listing. `git status --porcelain research/runs/R12` was also unchanged.

| Command | Exit | Fresh result | Committed log | `cmp` |
|---|---|---|---|---|
| `bash research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/evidence/r12-lint.sh > /tmp/r12-audit/r12-lint.log 2>&1` | 0 | `RESULT PASS=18 FAIL=0 SKIP=0` | PASS=18 FAIL=0 SKIP=0 | identical |
| `bash research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/evidence/r12-verdict.sh > /tmp/r12-audit/r12-verdict.log 2>&1` | 0 | `RESULT PASS=43 FAIL=0 SKIP=0` | PASS=43 FAIL=0 SKIP=0 | identical |
| `bash /tmp/r12-audit/ev/r12-sources.sh > /tmp/r12-audit/r12-sources.log 2>&1` | 0 | `RESULT PASS=59 FAIL=0 SKIP=0` | PASS=59 FAIL=0 SKIP=0 | differ at line 63 (moving figures only; see below) |
| `bash research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/evidence/r12-inputs.sh > /tmp/r12-audit/r12-inputs.log 2>&1` | **1** | `RESULT PASS=37 FAIL=1 SKIP=0` | PASS=38 FAIL=0 SKIP=0 | **differ at line 1** |
| **Total** | | **PASS=157 FAIL=1 SKIP=0** | claimed PASS=158 FAIL=0 SKIP=0 | |

### `r12-inputs.sh` diff (fresh versus committed)

```
1c1
< PASS I-prompt run prompt is byte-identical to the published prompt
---
> FAIL I-prompt -- prompt drift
42c42
< RESULT PASS=38 FAIL=0 SKIP=0
---
> RESULT PASS=37 FAIL=1 SKIP=0
```

The other 37 checks pass. These include `I-muse-id`, `I-opus-id`, every cited raw-line and prerequisite check, and `I-dec-checks`.

### `r12-sources.sh` diff (fresh versus committed)

```
63c63
< PASS S-cancelled-r12-cancelled-uv-1 ran to success
---
> PASS S-cancelled-r12-cancelled-uv-1 ran to failure
65c65
< PASS S-cancelled-r12-cancelled-uv-3 ran to success
---
> PASS S-cancelled-r12-cancelled-uv-3 ran to failure
```

These are the only differences. The decision says the script refetches live
sources and that its assertions compare structure, not moving figures. This rerun
supports that claim. The latest-cancelled samples rotated as follows:

| Sample | Committed run ID | Fresh run ID |
|---|---|---|
| cargo-1..3 | 36211359945, 36186119787, 36183904844 | 36290639916, 36211359945, 36186119787 |
| ra-1..3 | 36287176390, 36102953267, 36071821206 | 35702376247, 35658045721, 34984923005 |
| uv-1..3 | 36286463258, 36286001142, 36270435524 | 35393114604, 35380941418, 35368302336 |

The fresh `SHA256SUMS` differs from the committed one only in the
`r12-cancelled-*` and the `r12-{cargo,ra,tokio,uv}-repo.json` rows.

Every other row is unchanged. This includes all 15 documentation snapshots at the freshly
resolved `github/docs@main`, the rulesets, py/ts pins, and tokio's
PR #8458 contexts. The fresh `S0` reported `SHA256SUMS verifies (51 files)`.

### Other checks

- The committed `SHA256SUMS` verifies against the committed snapshots.
  `sha256sum -c` exited 0 with no non-OK line.
- `shellcheck` 0.11.0 ran over `review/evidence/r12-*.sh`, exited 0, and printed 0 bytes. This matches the empty committed `shellcheck.log`.
- `wc -l` on the raw reports: `raw/muse.md` has 214 lines and `raw/opus.md` has 572 lines. Both match `## Engines`.
- PASS-line counts in the committed logs are lint 18, verdict 43, sources 59, and inputs 38. They sum to 158, which matches the decision's total row.

## Figures re-derived at source

- **Cancelled-run claim in `### Principles` / Disagreement 3.** The claim is
  "3 of 3 `always()` aggregates (uv) ran to `success`/`failure`".
  - In all three committed uv snapshots, `all required jobs passed` concluded `success`.
    I checked whether that `success` is a false green. It is not. Parsing the
    committed `r12-uv-ci.yml` shows the `required-checks-passed` job with
    `if: ${{ always() && github.ref != 'refs/heads/main' }}`.
  - Its `needs:` list is `plan, check-fmt, check-lint, check-docs, check-crates-policies,
    check-generated-files, test, test-system, build-dev-binaries`.
  - The cancelled jobs in uv-1 have the prefixes `bench`, `build-docker`, `build-release-artifacts` and `review`.
    None of them is a member of that list.
  - The claim is therefore literally true.
  - The sample does not exercise a cancelled member of `needs:`. The decision already states the small sample and marks
    criterion 6 as proposed for P03. **Not a finding.**
- **Fresh uv samples.** uv-1 and uv-3 concluded `failure`, still accepted by the
  `success|failure` assertion. uv-3 shows failed `test / cargo test on linux`
  and `… windows 1 of 3`, `… 3 of 3` jobs, and the aggregate turned red as described.
- **py and tokio figures.** The py 21-revision zero-drift history, tokio's 46 contexts on PR #8458, and the py live
  app-pinned `ci-ok` came from fresh fetches and local `git` reads. Their log lines are
  byte-identical to the committed log.

## Finding 1 — `I-prompt` fails; the decision's engine provenance is unreconciled with the frozen run inputs

**Failed claims (quoted from `## Empirical check`).**

- Table row: "`review/evidence/r12-inputs.sh` | 38 | PASS=38 FAIL=0 SKIP=0 | run prompt byte-identical to the published prompt; …"
- Total row: "**total** | **158** | **PASS=158 FAIL=0 SKIP=0**"
- "Each exits **0** and fails the process on any `FAIL`."

**Evidence.**

1. The fresh rerun exits 1. Its log has `FAIL I-prompt -- prompt drift` and
   `RESULT PASS=37 FAIL=1 SKIP=0`.
2. Running `diff` on `inputs/prompt.md` against
   `research/topics/12-aggregate-required-status-check/prompts/aggregate-required-status-check.prompt.md`
   gives two hunks:
   - line 22: `- engines: codex, opus` becomes `- engines: muse, opus`;
   - line 69 appends "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
3. The cause is a working-tree edit made after the synthesis. `git status` shows the topic prompt as
   `M`, and its mtime is `Sep 26 19:57:56 2026`. The committed `r12-inputs.log` has mtime `19:35:33`.
   `git show HEAD:<topic prompt> | shasum -a 256` gives
   `3da9f7d26af89f1406eb86f608d1add3b0f31e6876a4328998fb16de154dabe8`. That value equals both the run's
   `inputs/prompt.md` and `manifest.json` `input_hashes.prompt`. The synthesis-time PASS
   was therefore genuine. The check fails now only because of the uncommitted edit.
4. The edit reveals a provenance gap that the decision does not address:
   - The run's frozen `inputs/prompt.md` says `- engines: codex, opus`.
   - `manifest.json` has `"required_engines": ["codex", "opus"]` and `"operations": {}`.
   - HEAD's `research/EXECUTION.json` `engine_overrides` has entries only for R72 and R84. The R12 entry `["muse", "opus"]` exists only in the uncommitted working tree.
   - Yet `raw/muse.md` exists, and `## Engines` reports a Muse leg. A search of the decision for `override`, `substitut` and `engines:` finds no mention of the substitution in `## Engines`.

   The decision thus certifies the run inputs as verified, and it also reports an engine that those inputs do not name. It gives no authority for that difference.

   This finding makes no ruling on whether the substitution was permitted. It finds only that the decision does not record the substitution or its authority.
5. RUNBOOK §5 requires "current consumed values" for acceptance. Against the tree
   the controller publishes from, the consumed prompt is no longer current.

**Repair.** Do not weaken `I-prompt`. For example, do not compare against HEAD or against
the manifest hash instead of the live published prompt. That change would hide
exactly the staleness this check exists to catch. Take one of two branches:

- **(a) Revert.** Revert the uncommitted edit to the topic prompt. Revision 1's
  byte-identity claim then holds again. Rerun `r12-inputs.sh` and expect
  `RESULT PASS=38 FAIL=0 SKIP=0`. The Muse-for-Codex substitution still needs
  a recorded authority in `## Engines`, because the frozen inputs name `codex`.
- **(b) Adopt the override (consistent with what actually ran).**
  1. Commit the `engine_overrides` wave, including `"R12": ["muse", "opus"]`.
  2. Re-freeze this run's `inputs/prompt.md`, `manifest.json` `required_engines`, and
     `input_hashes.prompt` so that they match the executed engine set.
  3. Have the synthesizer rerun `r12-inputs.sh` and issue revision 2. The decision
     hard-codes `PASS=38` and the byte-identity claim, so those lines must change too.
  4. In `## Engines`, cite the `engine_overrides["R12"]` entry as the authority for Muse
     replacing Codex.

After either branch, rerun all four scripts and confirm the total
`PASS=158 FAIL=0 SKIP=0`, or the revised total.
