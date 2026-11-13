actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: ea3fb15b674185126831ecb03870b236da7c4829a0a1b170e2a7320b452570f5
verdict: approve
unresolved-findings: none

# R14 large-file-guard-strategy — empirical audit of DECISION.md revision 1

Seat: empirical auditor, fresh context, independent of the synthesizer and the
judgment auditor. Scope: execution truth and evidence support only. No other
seat's audit, no topic `raw/`, and no revision snapshot was read.

## Identity of the audited revision

```
$ shasum -a 256 research/runs/R14/2026-09-26T190144Z-53ff8e94fbd8/review/DECISION.md
ea3fb15b674185126831ecb03870b236da7c4829a0a1b170e2a7320b452570f5
```

This matches the expected revision-1 digest.

## Evidence integrity

`(cd review/evidence && shasum -a 256 -c SHA256SUMS)` reports `OK` for all
14 entries: `check-large-files.sh`, `ci.hygiene-with-guard.yml`, the six
`r14-rev1-*.sh` scripts and their six `.log` files.

- **Reference artifact under test.** `check-large-files.sh` has sha256
  `3492598cec9e46474064f988bc7d2ed2f8d3cfb168ff056fe9ce68ac7ea045f1`. That
  matches `SHA256SUMS` and the `3492598c…` cited in `## Decision` and
  `## Empirical check`. It is 46 lines, as claimed. It has no paired `.log`,
  so no rerun pair was invented for it. It is exercised by the guard, merge,
  pybody and lefthook scripts below.
- **Composed CI file.** `ci.hygiene-with-guard.yml` has sha256 `aa37e31a…`,
  matching the cited digest.

## Reruns

Host: Darwin 25.4.0 arm64, `git version 2.50.1 (Apple Git-155)`, `/bin/sh` =
GNU bash 3.2.57, `/bin/dash` present, `actionlint` 1.7.12, `shellcheck`
0.11.0, `lefthook` 2.1.14, `git-lfs` 3.8.0. These match the host line in
`## Empirical check`.

Method: the working directory was `review/evidence/`. `TMPDIR` was set to
`/tmp/r14-audit-claude/tmp`, so every scratch repository lived outside the
repository. Each fresh log went to `/tmp/r14-audit-claude/`. The committed
logs carry a 3-line header (`UTC now:`, `host:`, `cmd:`) and an `exit=`
trailer that the scripts do not print themselves. The rerun wrapper
reproduced that format:

```sh
{ echo "UTC now: $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "host: $(uname -srm) $(git --version)"
  echo "cmd: sh r14-rev1-$s.sh"; sh r14-rev1-$s.sh 2>&1; echo "exit=$?"; } > /tmp/r14-audit-claude/r14-rev1-$s.log
cmp /tmp/r14-audit-claude/r14-rev1-$s.log r14-rev1-$s.log
```

None of the six scripts writes to `evidence/`. `r14-rev1-workflow.sh` only
reads `ci.hygiene-with-guard.yml`.

| Script | Exit | Final line | PASS / FAIL / SKIP | `cmp` against committed log |
|---|---|---|---|---|
| `r14-rev1-inputs.sh` | 0 | `inputs failures: 0` | 27 / 0 / 0 | line 1 only |
| `r14-rev1-guard.sh` | 0 | `guard checks: 29 failures: 0` | 29 / 0 / 0 | line 1 only |
| `r14-rev1-merge.sh` | 0 | `merge failures: 0` | 4 / 0 / 0 | line 1 only |
| `r14-rev1-pybody.sh` | 0 | `pybody checks: 4 failures: 0` | 5 / 0 / 0 (`BODY` + `P1`–`P4`) | line 1 only |
| `r14-rev1-workflow.sh` | 0 | `workflow failures: 0` | 9 / 0 / 0 | line 1 only |
| `r14-rev1-lefthook.sh` | 0 | `lefthook failures: 0` | 4 / 0 / 0 | line 1 only |

Every `cmp` reported its first difference at `char 19, line 1`, the
timestamp. For example, from `diff`:

```
1c1
< UTC now: 2026-09-27T03:49:27Z
---
> UTC now: 2026-09-26T21:46:12Z
```

For all six pairs, lines 2 to the end are byte-identical to the committed
logs: `cmp <(tail -n +2 fresh) <(tail -n +2 committed)` reports no difference.
The committed evidence therefore reproduces exactly on this host, except for
the unavoidable run instant. No test was skipped. The `H8 SKIP` branch did not
fire because `git-lfs` is installed.

The total is 78 `PASS` lines and 0 `FAIL` lines. This matches the "78 checks
pass, 0 fail" claim in `## Empirical check`.

## Load-bearing figures re-derived at source

| Claim in DECISION | Source read | Result |
|---|---|---|
| Py CI guard is 1048576 bytes with the `docs/assets/` allowlist, skips on an empty base, and checks added files only | `git show b08bccfb:.github/workflows/large-file-guard.yml` in the py repository, lines 33, 34, 39 and 42 | confirmed |
| Py `docs/assets` holds 0 entries at the pin (`I9e`) | `git ls-tree -r b08bccfb -- docs/assets \| wc -l` returns `0` | confirmed |
| Ts hook compares with `-gt 512000` (`I10a`) | `git show cb1cbcb2:lefthook.yml` in the ts repository, line 42 | confirmed |
| "at least 2.08× headroom" over `Cargo.lock` at 503922 bytes | `1048576/503922 = 2.0808` | arithmetic confirmed. The 503922 input is carried from the Opus leg, and the DECISION labels it as carried. |
| The composed CI file adds 7 lines and removes 0 relative to R11's fixture (`W2a`) | `diff` against `R11/.../ci.candidate.r2.yml` | confirmed: 2 lines add `fetch-depth: 0`; 5 lines add the guard step with the three-way `BASE_SHA` |
| Push rulesets are limited to internal and private repositories on paid plans | `gh api repos/github/docs/contents/data/reusables/gated-features/repo-rules.md?ref=18945a31`, a read-only public query | confirmed: "Push rulesets are available for the Team plan in internal and private repositories…" |
| R11 slot rule and secret-scanning carve-out text (`I7`, `I7b`) | `docs/port/PARAMETERS.md` and this run's `inputs/PARAMETERS.md` | confirmed (see note 1) |

## Observations (non-blocking, no repair required)

1. **The R11 prerequisite is published in the working tree but not committed
   at HEAD.** `I7` and `I7b` grep the working-tree `docs/port/PARAMETERS.md`.
   At `HEAD`, both strings are absent: the `ci-job-structure` row there still
   has an empty value. However, this run's own input snapshot,
   `inputs/PARAMETERS.md`, is byte-identical to the working tree and contains
   the text. The working-tree `research/topics/11-…/DECISION.md` hashes to
   `410e88e5…`, and its `acceptance.json` hashes to `774f7649…`. Both digests
   match `inputs/prerequisites.json`, and that `acceptance.json` records two
   approving audits of `410e88e5…`. The checks are therefore true for the
   pinned prerequisite. The controller should commit R11's publication before
   or together with R14, so that `I7`/`I7b` also hold at a clean checkout.
2. **The per-script table undercounts one pybody check.** In
   `## Empirical check`, the pybody row reads "4 pass", and the six rows sum
   to 77. The stated total of 78 counts pybody's `BODY PASS` line, a signature
   check that the verbatim extraction is intact. The 78 total is correct; only
   the row label omits `BODY`.
3. **The log header and trailer come from an uncommitted wrapper.** The
   `UTC now` / `host` / `cmd` / `exit=` lines are not printed by the
   committed scripts. The wrapper is trivially reconstructible, as shown
   above. The scripts' own output lines are fully reproducible.

## Verdict

**approve.** Every cited rerun pair executes with exit 0 and 0 failures. The
committed logs reproduce byte-for-byte apart from the timestamp line. The
reference script's digest and line count match the DECISION. The load-bearing
source figures re-derive as stated. No unresolved findings.
