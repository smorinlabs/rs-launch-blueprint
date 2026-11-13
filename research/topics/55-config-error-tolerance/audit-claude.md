actor: audit-claude-2026-09-17T020714Z-62a04ad8fee1
model: claude-opus-5-5
family: anthropic
decision-sha256: 5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b
verdict: approve
unresolved-findings: none

# R55 config-error-tolerance — empirical audit of DECISION.md revision 3

**Seat.** This audit ran on the Claude seat, as the approved fallback under
method amendment Q8.B while the OpenAI provider is quota-paused. It is not a
Codex audit. The auditor had a fresh context and did not read any
`review/audit-fable*.md` file or `research/topics/55-*/raw/`.

**Scope.** This audit judges execution truth and evidence support only: whether
the commands run, whether the logs match the claims, and whether the figures are
right. It does not judge whether the recommendation is wise.

**Result.** Every command in `## Empirical check` reran with the claimed exit
status and the claimed `PASS/FAIL/SKIP` totals. Every rerun log differs from its
committed log only in environment header lines. The negative control reproduced
in both directions. Every load-bearing figure I re-derived at source matched.

## Environment of this audit

- Date: 2026-09-25 (UTC header in rerun logs: `2026-09-25T15:22:43Z` onward).
- Host: Darwin arm64 (macOS).
- `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`,
  `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`.
- `ShellCheck` version `0.11.0` at `~/.local/bin/shellcheck`.
- Repository `HEAD`: `e0b0d1c1`. `git status --short` on the review directory was
  empty before and after the reruns, so the scripts wrote nothing into the tree.
- Scratch directory: `/tmp/r55audit/`.

The decision records `cargo 1.98.0` / `rustc 1.98.0`. The toolchain has since
moved to the 1.98.1 point release. This is not a finding: the decision reports
the toolchain it ran on, and the reruns on 1.98.1 produced identical assertions.

## Reruns

### 0. Decision hash

```
$ shasum -a 256 research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md
5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b
```

Matches the expected hash.

### 1. All three evidence scripts, in place

Working directory: `research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/`.

```
$ for s in check check-r2 check-r3; do ./evidence/$s.sh > /tmp/r55audit/$s.out 2>&1; echo "$s exit=$?"; tail -1 /tmp/r55audit/$s.out; done
check exit=0
PASS=25 FAIL=0 SKIP=0
check-r2 exit=0
PASS=18 FAIL=0 SKIP=0
check-r3 exit=0
PASS=29 FAIL=0 SKIP=0
```

| Script | Claimed | Observed |
|---|---|---|
| `evidence/check.sh` (revision 1) | `PASS=25 FAIL=0 SKIP=0`, exit `0` | same |
| `evidence/check-r2.sh` (revision 2) | printed `PASS=18 FAIL=0 SKIP=0`, exit `0` (the decision concedes this count was wrong under JF-7) | same |
| `evidence/check-r3.sh` (revision 3) | `PASS=29 FAIL=0 SKIP=0`, exit `0` | same |

### 2. Rerun output against the committed logs

```
$ for n in check check-r2 check-r3; do diff "$n.log" "/tmp/r55audit/$n.out"; done
```

For each of the three scripts, the diff contains exactly three changed lines,
all in the environment header: `date (UTC)`, `cargo:` and `rustc:`. No
assertion line, count, or summary differs. The `cargo`/`rustc` lines differ only
because of the 1.98.0 → 1.98.1 point release described above.

### 3. Rerun from a clean `git archive HEAD` extraction

```
$ d=$(mktemp -d /tmp/r55audit/arch.XXXX); git archive HEAD | tar -x -C "$d"
$ "$R/check.sh"    → exit=0  PASS=25 FAIL=0 SKIP=0
$ "$R/check-r3.sh" → exit=0  PASS=29 FAIL=0 SKIP=0
$ diff "$R/check-r3.log" /tmp/r55audit/arch-r3.out
```

(`$R` is `$d/research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/evidence`.)
The `check-r3` diff is limited to `date (UTC)`, `repository root`, `cargo:` and
`rustc:`. That confirms the claim that the script finds the repository root by
content and reruns outside the live checkout.

I also diffed the committed archive logs against the committed in-place logs:

- `check.log` vs `check-archive.log`: exactly the three lines the decision names —
  `date (UTC)`, `repository root`, and the `C05` line, which embeds the root path.
- `check-r3.log` vs `check-r3-archive.log`: exactly the two header lines the
  decision names — `date (UTC)` and `repository root`.

### 4. Negative control (JF-7), reproduced

I followed the procedure stated in `evidence/check-r3-negative-control.log`
inside the archive extraction. The `sed` substitution replaced JF5b's needle with
`'THIS NEEDLE IS NOT IN THE FILE - negative control'`. `diff` against a pristine
copy confirmed exactly one changed line per script.

```
== check-r2.sh
exit=0
FAIL JF5b: ts config.ts:154 is the click.Path(exists=True) parity comment, not :153 — /usr/bin/grep counted 0 occurrences of: THIS NEEDLE IS NOT IN THE FILE - negative control
PASS=18 FAIL=0 SKIP=0
== check-r3.sh
exit=1
FAIL JF5b: ts config.ts:154 is the click.Path(exists=True) parity comment, not :153 — /usr/bin/grep counted 0 occurrences of: THIS NEEDLE IS NOT IN THE FILE - negative control
PASS=28 FAIL=1 SKIP=0
```

This matches the committed control. Revision 2's script prints the `FAIL` line
but reports `FAIL=0` and exits `0`. Revision 3's script reports `FAIL=1` and
exits `1`. The repaired gate trips.

### 5. Shellcheck-cleanliness

```
$ shellcheck check.sh; shellcheck check-r2.sh; shellcheck check-r3.sh
check.sh rc=0
check-r2.sh rc=0
check-r3.sh rc=0
```

No output, exit `0` for all three. `check-r3.sh` carries one file-wide
`# shellcheck disable=SC2016` directive, with a written justification: the
single-quoted needles are literal Markdown or Rust text. That use is consistent
with the claim of being shellcheck-clean.

## Counts re-derived from the logs

| Claim in the decision | Command | Observed |
|---|---|---|
| "38 `PASS` lines in total" in `check-r3.log` | `/usr/bin/grep -c '^PASS ' check-r3.log` | `38` |
| 29 script checks + 9 nested probe assertions | IDs listed below | 38 − 9 (`R1`–`R8b`) = `29` |
| Revision 2's log carried "22 script-level `PASS` lines" | `/usr/bin/grep -cE '^PASS ' check-r2.log` → `31`; minus the nine `R1`–`R8b` lines | `22` |
| Seven new checks in revision 3 | set difference of IDs, r3 minus r2 | `JF7 JF7b JF8a JF8b JF9a JF9b JF9c` — seven |
| `JF7b`: four here-string-fed `assert_stream` calls | `/usr/bin/grep -n assert_stream check-r3.sh` | four call sites: `JF4a`, `JF4b`, `JF5a`, `JF5b` |

Script-check IDs observed in `check-r3.log`: `D01 D02 D03a D03b D03c D03d D04
JF7 JF7b JF2a JF2b JF3 JF4a JF4b JF5a JF5b JF8a JF8b JF9c JF9a JF9b D05 D05a D05b
D05c D05d D05e D05f D05g`, plus probe assertions `R1 R2 R3 R4 R5 R6 R7 R8a R8b`.
No `FAIL` or `SKIP` lines.

## Load-bearing figures re-derived at source

Each figure below was read directly from its source, independently of the
scripts' own assertions.

| Figure in the decision | Source read | Observed |
|---|---|---|
| Revision-1 files byte-identical: `check.sh` `ed0029f0…`, `check.log` `d83a1fea…`, `rerun.diff` `3dda6290…` | `shasum -a 256` | `ed0029f0…`, `d83a1fea…`, `3dda6290…` |
| Revision-1 and revision-2 evidence not edited after their revision | `git log --format=%h -- <file>` | revision-1 files last touched in `52e5525e` (revision 1's follow-up fix, before revision 2); `check-r2.sh`, `check-r2.log`, `r2-rerun.diff`, `check-archive.log` only in `de4183d3` (revision 2) |
| R53 pinned at sha256 `be59d65b…9af9` (`D01`) | `shasum -a 256` on R53's `DECISION.md` | `be59d65bfa7ee087766a315af09c0ba4c93a8fa211927091314c86222cbb9af9` |
| `R53 DECISION.md:184` must-agree row (`JF8a`) | `sed -n 184p` | "A value outside a key's allowed set is rejected, never silently coerced" |
| `R53 review/evidence/verify.sh:620` (`JF8b`) | `sed -n 620p` | `if let Some(t) = table.get("output").and_then(toml::Value::as_table) {` |
| Helper starts at `verify.sh:649`, range `:649-657` (`JF9c`) | `sed -n 649,657p` | `fn field<T: serde::de::DeserializeOwned>(` through the closing `}` on 657 |
| py `config.py:124-139` `_discovery_paths`; docstring at `:127-128`; body `if config_file: target = Path(config_file); return target, [target]` | `git show b08bccfb:src/py_launch_blueprint/core/config.py` | matches |
| py `config.py:148-150` `load_config` tolerance docstring | same | "Tolerant by design — with one exception: an *explicit* ``--config`` file that exists but cannot be parsed raises :class:`ConfigError`. Discovered layers and invalid values degrade to warnings" |
| py `config.py:103` returns the discovered-layer warning | same | `return {}, f"ignoring unreadable config file {path}: {exc}"` |
| three `model_config = {"extra": "ignore"}` in py `settings.py` at `b08bccfb` (`JF9a`) | `grep -c` on `core/settings.py` | `3` (and `0` in `web/settings.py`; the count belongs to `core/settings.py`) |
| ts `config.ts:37-41`: one `z.object`, zero `.strict()`/`.passthrough()` (`JF9b`) | `git show cb1cbcb2:src/lib/config.ts` | `z.object({ token, workspace, limit })`; `.strict()`/`.passthrough()` count `0` |
| ts `config.ts:154` parity comment (`JF5b`) | same | `// click.Path(exists=True) parity: a usage error, exit 2.` |
| 20-package graph (`JF2a`) | `grep -c '^\[\[package\]\]'` on both spike lockfiles | `spike/Cargo.lock: 20`, `spike-r2/Cargo.lock: 20` |
| Resolved versions `serde` 1.0.229, `toml` 1.1.6+spec-1.1.0, `serde_ignored` 0.1.14, `serde_path_to_error` 0.1.20 | `spike-r2/Cargo.lock` | same four versions |
| crates.io snapshots (`C07`) | `jq .crate` on `*-crate.json` | `serde_ignored` max stable `0.1.14`; `serde_path_to_error` max stable `0.1.20` |

The `D05` probe was rebuilt from `evidence/spike-r2/` in a temporary directory
by each rerun of `check-r2.sh` and `check-r3.sh`. All nine probe assertions
(`R1`–`R8b`) passed with output identical to the committed logs, including
R1/R2 `["output.colour", "verbose"]` and R8a (silent) versus R8b (one `Issue`
at path `output`).

## Observations (non-blocking, no repair required)

1. **Toolchain drift.** The decision's `**Toolchain.**` line records
   `1.98.0`. The machine now has `1.98.1`. The reruns show the evidence is
   insensitive to this point release. The decision correctly reports what it ran
   on.
2. **Script header comment.** The header comment of `check-r3.sh` (line 15) says
   the script "adds five" checks. The decision says seven, and the log confirms
   seven (`JF7 JF7b JF8a JF8b JF9a JF9b JF9c`). The decision's figure is the
   correct one. The stale count sits in a comment inside an executed, cited
   script that the revision rules keep byte-identical, and it supports no claim.
   It is recorded here, not raised as a finding.
3. **Scope limits stated by the decision.** The decision says the probe does not
   exercise the template's real schema, does not exercise merges of three or more
   layers, and ran on macOS arm64 only. This audit also ran on macOS arm64 only,
   so it adds no cross-platform evidence.

## Verdict

**approve.** The empirical check executes as written, reproduces its claimed
counts and exit statuses in place and from a clean archive, is shellcheck-clean,
and every load-bearing figure I re-derived at source matches. No unresolved
findings.
