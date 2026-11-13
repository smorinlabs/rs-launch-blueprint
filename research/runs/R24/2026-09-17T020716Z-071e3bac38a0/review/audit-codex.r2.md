decision-sha256: bdad4359d5eaeadf61f10a5f92ecb2f377c624773fd5ce7be3009edc7361fc0b
actor: codex-empirical-r24-r2
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
seat: codex (seat name only; the engine that performed this audit is Anthropic Claude Opus 5.5, not an OpenAI model)
box: Q23 rerun-only (RUNBOOK §7) — no judgment audit, no verifier pair, nothing fixed

# R24 empirical verification — revision 2 rerun

## Result

Every rerun reproduces the decision's recorded figures. The main suite and
the skip control both exit 0. Both logs are **byte-identical** to the committed
logs. Both loader-probe outputs and all seven render-probe outputs are
byte-identical to their snapshots. No rerun contradicts a decision claim, so
the verdict is `approve` and there are no BLOCKING findings. Five observations
(OBS-1 to OBS-5) are recorded below. None of them was fixed.

## Target binding

- `sha256sum review/DECISION.md` returned
  `bdad4359d5eaeadf61f10a5f92ecb2f377c624773fd5ce7be3009edc7361fc0b` before any
  other read. It matched the expected value. The value was recomputed
  immediately before this file was written and was unchanged.
- `research/EXECUTION.json` hashed to the S87 pin
  `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c`.
- `git status --porcelain -- research/runs/R24/` was empty before the reruns:
  the run directory matches `HEAD` (`491e47e6`).

## Expected counts, taken from the decision itself

| Suite | Decision line | Recorded figure |
|---|---|---|
| Main (`bash r24-checks.sh`) | `review/DECISION.md:527` | exit 0 — 146 assertions, 146 `PASS`, 0 `FAIL`, 0 `SKIP` |
| Skip control (`PATH=/usr/bin:/bin:/usr/sbin:/sbin`) | `review/DECISION.md:654-656` | exit 0 — 128 `PASS`, 4 named `SKIP`s (`7a-install`, `7b-upstream-bytes`, `7c-rendered-bytes`, `7d-loader-bytes`, each `node is not on PATH`), 0 `FAIL` |

These counts agree with the brief (146 main, 128/4 control).

## How the reruns were run, and why not in place

`r24-checks.sh` rewrites `review/evidence/toolchain.txt` on every run. The
decision discloses this at `review/DECISION.md:514-516`. An in-place rerun would
therefore modify a committed file, which this audit may not do. The unmodified
script was instead run from two byte-exact mirrors under `/tmp/s87-r24-rerun/`.
The script locates the repository from its own directory
(`REPO=$EVID/../../../../../..`), so each mirror keeps the same relative layout:

| Mirror | Contents |
|---|---|
| `wt/` | `cp -p` of the working-tree `docs/port/PARAMETERS.md`, `research/topics/19-dependabot-config-shape/DECISION.md`, and the whole run `review/` tree |
| `head/` | `git archive HEAD` of the same three paths (read-only git) |

`diff -rq` showed the two mirrors' run directories to be identical to each other.
The py and ts pins are read by the script itself through read-only
`git -C ~/c/{py,ts}-launch-blueprint show <pin>:…`.

Host: Darwin 25.4.0 arm64, `node v26.9.0`, `npm 12.0.1`, `/usr/bin/grep`
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`, `shellcheck 0.11.0`. This host
matches the decision's recorded toolchain (`review/DECISION.md:504-512`).

## Rerun totals per script

| Run | Exit | PASS | FAIL | SKIP | Summary line | `cmp` against committed log |
|---|---|---|---|---|---|---|
| Main, `wt/` mirror | 0 | 146 | 0 | 0 | `PASS 146  FAIL 0  SKIP 0  TOTAL 146` / `RESULT: PASS` | byte-identical to `r24-checks.log` |
| Main, `head/` mirror | 0 | 146 | 0 | 0 | same | byte-identical to `r24-checks.log` |
| Skip control, `wt/` mirror | 0 | 128 | 0 | 4 | `PASS 128  FAIL 0  SKIP 4  TOTAL 132` / `RESULT: PASS` | byte-identical to `r24-checks-skip-control.log` |

The four control `SKIP`s are exactly the four the decision names, each with the
reason `node is not on PATH`.

The `head/` run also supplies the reproduction that `review/DECISION.md:636-639`
says was not yet repeated for revision 2: a `git archive HEAD` extraction (of
the three paths the script reads, with no `.git`) reproduces the revision-2 log
byte for byte. Revision 2's files are now committed at `HEAD` `491e47e6`. Fresh logs are at `/tmp/s87-r24-rerun/main-wt.log`,
`main-head.log` and `ctl-wt.log`.

## Loader and render probe figures

A second, standalone run installed `release-please@17.11.2` into
`/tmp/s87-r24-rerun/probe-install/` and ran `probe/loader.cjs` and
`probe/render.cjs` directly (both exit 0). `npm ls` resolved
`release-please@17.11.2`, `conventional-changelog-conventionalcommits@6.1.0` and
`conventional-changelog-writer@6.0.1`, as check 7a claims.

Loader probe (`loader.txt`), compared figure by figure with the decision's
claims at `review/DECISION.md:309-335` and checks 9c–9d:

| Decision claim | Fresh probe output | Match |
|---|---|---|
| Recommended strategy holds 11 entries | `recommended loaded entries: 11`, `recommended strategy entries: 11` | yes |
| Recommended configuration has no scoped entry | `recommended … scoped entry: null` (loaded and strategy) | yes |
| Mechanism-5 push under the recommendation renders a one-line body and `changelogEmpty` is `true` | `recommended hidden-only lines: 1`, `recommended hidden-only changelogEmpty: true` | yes |
| Scope-routed strategy holds 12 entries with the scoped entry intact | `scope-routed loaded entries: 12`, `scope-routed strategy entries: 12`, both with `{"type":"chore","scope":"deps","section":"Dependencies"}` | yes |
| Under scope routing, a six-line body and `changelogEmpty` is `false` | `scope-routed hidden-only lines: 6`, `scope-routed hidden-only changelogEmpty: false` | yes |
| The bump renders under `### Dependencies` | `G-scope-routed-hidden-only.md` carries `### Dependencies` / `* **deps:** bump serde from 1.0.230 to 1.0.231 …` | yes |

Both loader outputs (`loader.txt`, `G-scope-routed-hidden-only.md`) are
byte-identical (`cmp`) to `snap/rendered/`.

Render probe: all seven outputs (`A-preset-default.md`, `B-py.md`, `C-ts.md`,
`D-recommended.md`, `E-hidden-only.md`, `F-hidden-plus-visible.md`,
`mech5.txt`) are byte-identical to `snap/rendered/`. The rendered `###` heading
sets for runs A–D equal the decision's table at `review/DECISION.md:577-582`
row for row, including run C's lowercase `style` above `Features`.
`mech5.txt` reports hidden-only 1 line / `true` and hidden-plus-one-visible
6 lines / `false`, matching checks 5a–5c.

## shellcheck

`review/evidence/` contains one shell script, `r24-checks.sh`.
`shellcheck r24-checks.sh` at ShellCheck `version: 0.11.0` exited **0** with no
output. The decision's claim at `review/DECISION.md:527-530` (clean at 0.11.0,
two documented disables) holds.

## Findings

BLOCKING: none. No rerun contradicts a decision claim.

Context from the priors (read only; not re-judged, per the Q23 box). The
revision-1 judgment audit `review/audit-fable.md.v2` (bound to the revision-1
bytes `bc5dcafa…`) rejected with JF-2/JF-3, JF-10/JF-2 and JF-4. The
empirical side of JF-10 — whether a scope-routed `Dependencies` section is
reachable — is what revision 2's checks 9a–9f and the loader probe address, and
this rerun reproduces all of them. Whether those checks dispose JF-10, and the
engine-account question in JF-2/JF-3, are judgment matters for controller
triage under RUNBOOK §7.3, not for this rerun.

Severity tags (RUNBOOK §7.1): every item below is `OBS` (recorded, never
rounded). There is no `BLOCKING` item.

## Observations (not fixed — rerun only)

- **OBS-1 — the documented in-place command modifies a committed file.**
  `bash r24-checks.sh > r24-checks.log 2>&1`, run from the evidence directory as
  `review/DECISION.md:524` shows, rewrites the committed
  `review/evidence/toolchain.txt` with a fresh timestamp and scratch path. The
  decision discloses this (`review/DECISION.md:514-516`). The consequence is
  that a read-only auditor cannot follow the recorded command literally; this
  audit used `/tmp` mirrors instead. Disclosure only.
- **OBS-2 — inputs drift, disclose-only (standing rule 1).** The working-tree
  `docs/port/PARAMETERS.md` differs from `HEAD` in the `ci-job-structure` and
  `logging-pipeline-contract` rows. Neither row is one R24 asserts on (section 2
  checks `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`,
  `commit-message-convention`). The main log is byte-identical from both the
  working-tree mirror and the `HEAD` mirror, so the drift does not reach any
  R24 figure.
- **OBS-3 — section 8 is snapshot-bound.** Checks 8a–8b assert on the two
  GitHub REST responses snapshotted on 2026-09-18 under `snap/github/`; the
  script makes no live GitHub call, as the decision states
  (`review/DECISION.md:617-625`). This rerun therefore reproduces those
  assertions against the snapshots only; it did not re-query GitHub, so it does
  not show that `v17.11.2` is still the latest release on 2026-09-29.
- **OBS-4 — carried figures not re-executed.** The crates.io landscape figures
  and repository metadata carried from `raw/opus.md`
  (`review/DECISION.md:670-690`) are, as the decision itself labels them, not
  exercised by the suite, and this rerun did not re-measure them.
- **OBS-5 — counting method note.** A bare `grep -c '^PASS'` over the main log
  returns 147, because the summary line `PASS 146  FAIL 0  SKIP 0  TOTAL 146`
  also starts with `PASS`. The assertion count is 146 (`grep -c '^PASS [0-9a-z]*-'`
  and the script's own summary). Similarly 129 for the control versus 128
  assertions. Not a defect in the decision; recorded so a future counter does
  not misread it.

## Integrity of the checkout

- Written: this file only. All rerun logs, mirrors and the npm scratch install
  live under `/tmp/s87-r24-rerun/`.
- `git status --porcelain -- research/runs/R24/` after the reruns showed no
  change other than this file. The committed `review/evidence/toolchain.txt`
  still hashes to
  `d7821080be0a1b55ef079b289faee55c17bdcab1d52de9f83507e6e3d14a4f63`.
- The priors `review/audit-claude.md`, `review/audit-codex.md`,
  `review/audit-fable.md`, `review/audit-fable.md.v2` and
  `review/R24-r1-snapshot.md` were read for context only and not modified.
  Their pre-run hashes are in `/tmp/s87-r24-rerun/pre-hashes.txt`, together
  with those of every other file under `review/`.
