actor: codex
model: gpt-6
family: openai
decision-sha256: 6ee8ad17642a847856766e914b45eac8727525f64a9f6f7159f6e1e7be97a6d9
verdict: reject
unresolved-findings:
1. **The current engine-seat claim fails its own check.** Failed claims: `## Engines` says the live policy lists R80 with "the `claude` empirical seat," and `## Empirical check` says `check-standard-r4.sh` returns "14 PASS, 0 FAIL, 0 SKIP." Evidence: `research/EXECUTION.json` has `engine_overrides.R80 = ["muse", "opus"]` but has no `empirical_auditor_overrides.R80`. The policy validator in `scripts/research_validation.py` uses `seat_overrides.get(item, "codex")`, so the current seat is Codex. `V3` indexes the missing key, prints `KeyError: 'R80'`, and returns `FAIL V3 — the engine substitution is not recorded as the decision states`; the fresh script exits 1 with **13 PASS, 1 FAIL, 0 SKIP**, while the paired log says 14/0/0. Repair: reconcile the decision and `V3` with the current Codex default (or restore an explicitly authorized Claude override), rerun `check-standard-r4.sh`, re-pin its evidence, and obtain audits of the new decision hash. The Muse and Opus *research-engine* set itself still matches the manifest and policy.
2. **The stated count of six historical grep errors lacks its permitted record.** Failed evidence claim: the revision-5 note says the former `V8` emitted `empty (sub)expression` "six times" in revision 4 and says its former log was replaced. Evidence: the sole historical record allowed for this audit, `review/audit-codex.r4.md`, is absent; the old `check-standard-r4.log` was re-recorded. I independently ran the former expression against one script and got grep status 2 and `grep: empty (sub)expression`, but that does not establish six prior occurrences. Repair: preserve the original revision-4 log or provide the named permitted audit record, then bind the historical count to it. This gap does not negate the independently successful revision-5 `V8` test below.

## Scope and commands

I verified the decision hash with `shasum -a 256` before reading it, and verified the same hash again before writing this audit. `research/RUNBOOK.md` section 5 requires the empirical auditor to rerun the check. The revision-5 `## Empirical check` table names all six scripts below as current. I ran each from a separate copy of `review/evidence/` under `$T`, so nested logs and fetched snapshots could not overwrite the source evidence. The repository root was the working directory for every command. `$ROOT` and `$T` were:

```bash
ROOT=/Users/stevemorin/c/rs-launch-blueprint-p02-plan
T=/tmp/r80-r5-audit-01a0e3c1-c747-7bc2-9ee4-bc0687a046ac
```

The first live and probe runs used the restricted network sandbox. I reran those same scripts with public network access because the first probe could not resolve the Cargo registry. Each command redirected both stdout and stderr to its fresh log under `$T`; all totals below are the script's observed final line.

| Rerun | Command | Observed final output and exit |
|---|---|---|
| Live, restricted | `bash "$T/live/evidence/check-live.sh" > "$T/live/fresh.log" 2>&1` | `=== 9 PASS, 0 FAIL, 0 SKIP ===`; exit 0. `curl: (6) Could not resolve host: crates.io`; snapshots used. |
| Live, public network | `bash "$T/live-net/evidence/check-live.sh" > "$T/live-net/fresh.log" 2>&1` | `=== 9 PASS, 0 FAIL, 0 SKIP ===`; exit 0. Fresh public counters and GitHub rows printed. |
| Offline | `bash "$T/offline/evidence/check-offline.sh" "$ROOT" > "$T/offline/fresh.log" 2>&1` | `=== 28 PASS, 0 FAIL, 0 SKIP ===`; exit 0. |
| Probe, restricted | `bash "$T/probe/evidence/check-probe.sh" > "$T/probe/fresh.log" 2>&1` | `=== 0 PASS, 13 FAIL, 0 SKIP ===`; exit 1. First failure: `FAIL A — variant a test run exited 101`; Cargo says `Could not resolve host: index.crates.io`. This environmental failure is repaired by the public-network rerun in the next row. |
| Probe, public network | `bash "$T/probe-net/evidence/check-probe.sh" > "$T/probe-net/fresh.log" 2>&1` | `=== 13 PASS, 0 FAIL, 0 SKIP ===`; exit 0. The locked crates were downloaded into the private Cargo home and the tests ran. |
| Standard r2 | `bash "$T/standard-r2/evidence/check-standard-r2.sh" "$ROOT" > "$T/standard-r2/fresh.log" 2>&1` | `=== 42 PASS, 0 FAIL, 0 SKIP ===`; exit 0. |
| Standard r3 | `bash "$T/standard-r3/evidence/check-standard-r3.sh" "$ROOT" > "$T/standard-r3/fresh.log" 2>&1` | `=== 7 PASS, 0 FAIL, 0 SKIP ===`; exit 0. |
| Standard r4 | `bash "$T/standard-r4/evidence/check-standard-r4.sh" "$ROOT" > "$T/standard-r4/fresh.log" 2>&1` | `=== 13 PASS, 1 FAIL, 0 SKIP ===`; exit 1. `V3` fails as quoted above; `V8` passes. |

The nested commands also executed in the isolated copies: r2 invoked `bash "$HERE/check-offline.sh" "$ROOT"` and got **28/0/0**; r3 invoked `bash "$HERE/check-standard-r2.sh" "$ROOT"` and got **42/0/0**, with another offline **28/0/0**; r4 invoked `bash "$HERE/check-standard-r3.sh" "$ROOT"` and got **7/0/0**, with nested r2 **42/0/0** and offline **28/0/0**. Here and below, each triple means PASS/FAIL/SKIP.

## Byte-comparison findings

For each public-network or offline fresh log, I ran `cmp -s` against its named `review/evidence/check-*.log` pair and, when it differed, saved `diff -u` as `$T/<copy>/diff.txt`. **All six raw byte comparisons differ.** The first changed log line in each diff is quoted here; these are findings even where the decision already explains the changing field. The revision-5 logs are working-tree files (modified or untracked), so "paired log" here means the file present at the decision hash, not a committed revision-5 Git object.

| Paired log / fresh copy | First differing log line, recorded → fresh | Other observed drift; disposition |
|---|---|---|
| `check-live.log` / `live-net` | `date(UTC): 2026-09-18T23:00:57Z` → `date(UTC): 2026-09-27T16:50:37Z` | Public counters moved: `q=liveness: meta.total=28347` → `29718`; the nine assertion lines and totals are byte-identical. This is the moving-source limitation the decision states. Keep the dated fetch log and compare assertions or saved snapshots for reproducibility. |
| `check-offline.log` / `offline` | `date(UTC): 2026-09-27T07:34:34Z` → `date(UTC): 2026-09-27T16:47:42Z` | The timestamp is the only raw difference; all 28 assertions and totals match. Normalizing the documented timestamp yields the claimed comparison. |
| `check-probe.log` / `probe-net` | `date(UTC): 2026-09-27T07:33:54Z` → `date(UTC): 2026-09-27T16:51:46Z` | The temporary workspace, cold Cargo downloads, target directory and timing also differ; all 13 assertions and totals match. Keep the locked inputs and compare assertion output after excluding machine-dependent build text. |
| `check-standard-r2.log` / `standard-r2` | `date(UTC): 2026-09-27T15:57:59Z` → `date(UTC): 2026-09-27T16:54:03Z` | The temporary workspace, Cargo target directory and timing also differ; all 42 assertions and totals match. Compare assertions and normalize the documented variable fields. |
| `check-standard-r3.log` / `standard-r3` | `date(UTC): 2026-09-27T15:58:20Z` → `date(UTC): 2026-09-27T16:54:14Z` | Timestamp only; all seven assertions and totals match. Normalizing it yields the claimed comparison. |
| `check-standard-r4.log` / `standard-r4` | `date(UTC): 2026-09-27T15:58:55Z` → `date(UTC): 2026-09-27T16:54:26Z` | The substantive diff is `policy_empirical_auditor_R80=claude` and `PASS V3` → `KeyError: 'R80'` and `FAIL V3`; totals change 14/0/0 → 13/1/0. Finding 1 requires a decision and evidence repair. |

The restricted live rerun has an additional `curl: (6)` and snapshot-fallback banner. The restricted probe rerun differs materially because its Cargo commands could not fetch `serde`; I retained both raw logs under `$T` and used the successful public-network rerun for the current execution check. The public-network assertion lines and totals match their paired logs for five scripts. They differ for r4 only at `V3` and its totals.

## Independent source checks

- **`V8` repair:** `/usr/bin/grep -cE` with the revision-5 pattern returned count **1**, status **0** on `x | grep -q y`; it returned count **0**, status **1**, no stderr on each of the six scripts. `check-standard-r4.sh` printed the same seven observations and `PASS V8`. The former unescaped-leading-pipe pattern returned status **2** and `grep: empty (sub)expression` in a separate one-script control. Thus the revised check can distinguish a hit, no hit and syntax error.
- **Figures:** Directly counting `OVERRIDE (OV-05)` in `DECISION.md` gives **11** occurrences. `snapshots/cratesio-search-liveness.json` has `meta.total = 28347`, the paired `check-live.log` value. The public fetch printed **29718**, consistent with a moving census rather than a pinned figure.
- **Locked dependencies:** Parsing both `probe/manifests-{a,b}/Cargo.lock` files yields `axum 0.8.9`, `tokio 1.53.1`, `serde 1.0.229`, `serde_json 1.0.151`, `tower 0.5.3`, `hyper-util 0.1.20` and `smallvec 1.16.1` in each. The public-network probe and r2 tests both passed with `--locked`.
- **Recorded counts:** Independent counts of `PASS` lines in the six paired logs give **9, 28, 13, 42, 7, 14**, with distinct check IDs and zero recorded FAIL or SKIP lines. The fresh direct runs give **9, 28, 13, 42, 7, 13**, with one fresh `FAIL V3`.
- **ShellCheck:** `shellcheck` on all six current scripts exited **0** and produced **0 bytes**; its output byte-matches `shellcheck-r4.log`.

These checks support the repaired grep test, the locked probe behavior and the nested pass counts. They do not support accepting revision 5 while `V3` fails against the live policy.
