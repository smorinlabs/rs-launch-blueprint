actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: bc5dcafa1ac0a864ce458bdc45dee92f02385cb28ebde7e8af364a5b04683a52
verdict: approve
unresolved-findings: none

# R24 changelog-section-mapping — empirical audit (revision 1)

Audit date: 2026-09-26 (Pacific); toolchain stamp of the rerun 2026-09-27T03:27:27Z (UTC).
Scope: execution truth and evidence support only. The argument's merits were not judged.

## Target hash

`shasum -a 256 research/runs/R24/2026-09-17T020716Z-071e3bac38a0/review/DECISION.md`
printed `bc5dcafa1ac0a864ce458bdc45dee92f02385cb28ebde7e8af364a5b04683a52`. That equals the
expected revision-1 hash, so the audit proceeded. `DECISION.md` and every file under
`review/evidence/` are committed and clean in the working tree. The last commit touching the
decision is `ef4139e0`.

## Currency determination

`## Empirical check` names one current script and two paired logs for revision 1:

- `evidence/r24-checks.sh` paired with `evidence/r24-checks.log`, the primary run. The decision
  states "exit 0 — 125 assertions, 125 `PASS`, 0 `FAIL`, 0 `SKIP`".
- The same script run with `PATH=/usr/bin:/bin:/usr/sbin:/sbin`, paired with
  `evidence/r24-checks-skip-control.log`. The decision states "109 `PASS`, 3 named `SKIP`s and
  0 `FAIL` at exit 0".

Both pairs were rerun. No other script exists under `review/evidence/`.

## Rerun method

The script writes `./toolchain.txt` beside itself on every run. Running it in place would
overwrite committed evidence. So the review directory was copied to a scratch tree under `/tmp`
at the same relative depth, because the script locates the repository root as
`$EVID/../../../../../..`:

```bash
T=/tmp/r24audit-claude
R=research/runs/R24/2026-09-17T020716Z-071e3bac38a0/review
mkdir -p $T/$R $T/docs/port
cp -Rp $R/evidence $T/$R/ && cp -p $R/DECISION.md $T/$R/ && cp -p docs/port/PARAMETERS.md $T/docs/port/
cd $T/$R/evidence
```

The sibling checkouts `~/c/py-launch-blueprint` and `~/c/ts-launch-blueprint` were read
unchanged through `git show` at the pins, as the script does. The committed evidence directory
was not written.

## Reruns

| # | Command (cwd = scratch `evidence/`) | Exit | Totals | `cmp` against committed log |
|---|---|---|---|---|
| 1 | `bash r24-checks.sh > /tmp/r24-claude-fresh.log 2>&1` (registry = working-tree `docs/port/PARAMETERS.md`) | 0 | `PASS 125  FAIL 0  SKIP 0  TOTAL 125`, `RESULT: PASS` | byte-identical to `r24-checks.log` |
| 2 | `PATH=/usr/bin:/bin:/usr/sbin:/sbin bash r24-checks.sh > /tmp/r24-claude-skip.log 2>&1` | 0 | `PASS 109  FAIL 0  SKIP 3  TOTAL 112`, `RESULT: PASS` | byte-identical to `r24-checks-skip-control.log` |
| 3 | `bash r24-checks.sh > /tmp/r24-claude-headreg.log 2>&1` (registry = `git show HEAD:docs/port/PARAMETERS.md`) | 0 | `PASS 125  FAIL 0  SKIP 0  TOTAL 125` | byte-identical to `r24-checks.log` |

Rerun 3 exists because `docs/port/PARAMETERS.md` has an uncommitted one-line change in this
checkout. Section 2 reads that file. Both the committed and the working-tree registry produce
the same log, so the uncommitted change does not touch R24's five `- assumes` rows.

The three `SKIP` lines in rerun 2 are named exactly as the decision says:
`SKIP 7a-install - node is not on PATH`, `SKIP 7b-upstream-bytes - node is not on PATH`,
`SKIP 7c-rendered-bytes - node is not on PATH`.

Rerun 1 exercised section 7 live. It ran a fresh `npm install release-please@17.11.2` from the
registry, compared eight upstream files against `./snap`, and re-rendered seven outputs through
`./probe/render.cjs`. All 16 section-7 assertions passed (7a ×1, 7b ×8, 7c ×7). So the npm
tarball and its resolved transitive versions have not drifted in the 9 days since recording.

## Per-section assertion counts versus the decision's table

The counts were taken from rerun 1 with `/usr/bin/grep -o '^PASS [0-9][a-z]*' | sort | uniq -c`.
The summary line `PASS 125` is the only non-assertion line that begins with `PASS`, and it was
excluded.

| § | Decision says | Rerun count |
|---|---|---|
| 1a–1c | ×5 | 2+1+2 = 5 |
| 2 | ×10 | 10 |
| 3a / 3b / 3c / 3d / 3e / 3f / 3g / 3h | 4 / 3 / 3 / 11 / 6 / 2 / 5 / 4 | 4 / 3 / 3 / 11 / 6 / 2 / 5 / 4 |
| 4a–4b | ×5 | 3+2 = 5 |
| 4c–4e | ×7 | 3+3+1 = 7 |
| 4f / 4g / 4h–4i / 4j | 6 / 5 / 4 / 3 | 6 / 5 / 2+2 / 3 |
| 5a–5c | ×7 | 1+4+2 = 7 |
| 6a–6c | ×13 | 5+6+2 = 13 |
| 7a–7c | ×16 | 1+8+7 = 16 |
| 8a–8b | ×6 | 4+2 = 6 |

Every row matches. The sum is 125.

## Load-bearing figures re-derived at source

These queries were read-only and public or keyring-authenticated. Calls to GitHub were spaced
more than 20 seconds apart.

- **Release pin (claim 8a).** `gh api repos/googleapis/release-please/releases/latest` returned
  `v17.11.2 2026-08-24T21:20:30Z draft=false pre=false`. `npm view release-please
  dist-tags.latest` returned `17.11.2`. So the decision's statement that "`v17.11.2` is
  release-please's latest published release" still holds on 2026-09-26. There is no drift.
- **Action dependency range (claim 8b).**
  `gh api "repos/googleapis/release-please-action/contents/package.json?ref=v5.0.0"`, decoded,
  contains `"release-please": "^17.6.0"`. This matches the decision, and `17.11.2` satisfies it.
- **py pin (claim 6a).**
  `git -C ~/c/py-launch-blueprint show b08bccfb…:release-please-config.json` has
  `"changelog-sections": [` at line 22, followed by 12 `{"type": …}` entries on lines 23–34.
  The entries include `deps`, a visible `refactor` and a hidden `docs`. The two other `"type"`
  lines in that file (12 and 17, `"toml"`) are `extra-files` entries, not sections. This
  matches the decision's "12 entries, array opening at line 22".
- **ts pin (claim 6b).** `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:release-please-config.json`
  has 7 `"type"` lines. This matches "7 entries".

## Drift observed (none load-bearing)

The only machine-dependent difference from the recorded run is in `toolchain.txt`. That file is
kept off the log by design, and the decision says a rerun rewrites it.

| Field | Recorded | Rerun |
|---|---|---|
| `rustc` | `1.98.0 (88d9e12ae 2026-08-18)` | `1.98.1 (48a229cea 2026-09-01)` |
| `cargo` | `1.98.0 (797e8a9bc 2026-08-05)` | `1.98.1 (797e8a9bc 2026-08-05)` |

The decision states that no check uses `rustc` or `cargo`. The byte-identical log confirms that
this drift moves no assertion, so it is not a finding. `node v26.5.0`, `npm 12.0.1`,
`shellcheck 0.11.0` and `/usr/bin/grep` `2.6.0-FreeBSD` are unchanged.

## Verdict

**Approve.** Both current logs reproduce byte-for-byte on this host 9 days after recording. They
still do so with a fresh npm install of the pinned release. The stated totals and per-section
counts match the output. The two load-bearing external facts (the release-please latest release
and the action's dependency range) and the two sibling-repo pin figures re-derive unchanged at
source. There are no unresolved findings.
