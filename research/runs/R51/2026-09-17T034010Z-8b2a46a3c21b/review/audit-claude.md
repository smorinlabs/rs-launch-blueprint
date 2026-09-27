actor: audit-claude-r51r1-s3
model: claude-opus-5-5
family: anthropic
decision-sha256: 11b9150d1a4a8df336f17a8e96054eafcfd695f03ff693e5618d5f5610a95231
verdict: reject
unresolved-findings:
1. The sources script already failed when the decision was written, and the decision presents it as passing evidence (F1).
2. `S3b`: the decision has five H2 headings, not "the four H2 headings in order and nothing else" (F2).
3. `S4a`: the gate-1 string the decision cites as recorded is not matched by its own check (F3).
4. `S10e`/`S10f`: the decision cites R77 "revision 1" lines 606 and 723; R77 was at revision 3 at run time (F4).
5. `S9b`: the decision cites `OV-04` in "R80 revision 2"; R80 revision 3 no longer declares it (F5).
6. Four evidence files the decision cites do not exist: `shellcheck.log`, `reproduction.log`, `r51-*.archive.log`, `tree-check.log` (F6).
7. A fresh rerun fails 4 registry checks and 3 more source checks because inputs moved after the decision (F7).

# R51 revision 1 — empirical audit (seat s3)

## Scope and identity

- Target: `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/DECISION.md`.
- `shasum -a 256` returned
  `11b9150d1a4a8df336f17a8e96054eafcfd695f03ff693e5618d5f5610a95231`, which
  equals the expected hash.
- Audit date: 2026-09-26. Reruns began at 2026-09-26T22:29:57Z.
- Host: `Darwin 25.4.0 arm64`; `/usr/bin/grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`;
  `/opt/homebrew/bin/cargo`; `gh` logged in with a keyring token; `shellcheck` at
  `/opt/homebrew/bin/shellcheck`.
- Docker: **unreachable from this session.** Every `docker` call returned
  `permission denied while trying to connect to the docker API at unix:///Users/stevemorin/.docker/run/docker.sock`,
  including with the command sandbox disabled. Consequently the container
  checks `C1`–`C14` SKIP in this audit, and I could not re-execute any built-image
  figure. The container script is judged only on its static checks and on the
  committed log's internal consistency.
- Scope: execution truth and evidence support only. I did not read any other
  audit file, any `raw/` report, or any snapshot.

## Reruns

Working directory: `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence`.
Output went to `/tmp/r51-audit-s3/`. Nothing was written under `evidence/`.
After the runs, `git status` showed no change to `evidence/`.

| Command | Exit code | Fresh summary | Committed summary | `cmp` |
|---|---|---|---|---|
| `./r51-container.sh > /tmp/r51-audit-s3/r51-container.log 2>&1` | 0 | `PASS=14 FAIL=0 SKIP=14 TOTAL=28` | `PASS=54 FAIL=0 SKIP=0 TOTAL=54` | differ: char 44, line 2 |
| `./r51-registries.sh > /tmp/r51-audit-s3/r51-registries.log 2>&1` | 1 | `PASS=24 FAIL=4 SKIP=0 TOTAL=28` | `PASS=28 FAIL=0 SKIP=0 TOTAL=28` | differ: char 43, line 2 |
| `./r51-sources.sh > /tmp/r51-audit-s3/r51-sources.log 2>&1` | 1 | `PASS=98 FAIL=8 SKIP=0 TOTAL=106` | `PASS=101 FAIL=5 SKIP=0 TOTAL=106` | differ: char 51, line 2 |

The first difference in every log is line 2, the `date-utc:` stamp. The
decision allows that line to vary. The remaining differences are listed below.

### `r51-container.sh`

- The 14 PASS lines are `F-Dockerfile.candidate`, `F-dockerignore.candidate`
  and `C15a`–`C15l`. `diff` of the `C15` lines between the fresh and committed
  logs is empty.
- The 14 SKIP lines are `C1`–`C14`, each reading `no usable Docker daemon on this host`.
  This matches the decision's statement that "A host without a Docker daemon …
  skips `C1`–`C14` by name".
- Internal consistency of the committed log, re-derived by arithmetic:
  - `measured-size-main: 12312852` minus `measured-size-noprobe: 11499381`
    equals 813,471 B, which matches `measured-size-busybox-delta: 813471`.
  - 40,163,283 / 12,312,852 = 3.262, which is +226 %. This matches `C9b`.
  - (28 s − 15 s) / 28 s = 46 %. This matches the decision's "46 % of wall time".
  - `C4b` reports 0 and `C5b` reports 50. Both match the decision.
  - `measured-binary-size: 1271048` matches the decision.
- Not re-executed, because Docker was unreachable: every built-image claim
  (`C1`–`C14`). This limitation is not recorded as a finding against the decision.

### `r51-registries.sh`

The fresh run fails 4 checks. The committed log shows PASS for all 4.

```
FAIL  D1a — rust:1.98.1-slim-trixie index digest: expected [sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3], got [sha256:4cd829461bd5c4d511c32e269da9cb8929223b666519d8004e35fc8d1d771ab7]
FAIL  D1b — rust:1.98.1-slim resolves to the SAME digest as -slim-trixie: expected [sha256:ca5c572a…], got [sha256:4cd829461bd5…]
FAIL  D1c — bookworm digest moved: got [sha256:ff521445a372125ed4f76e1453a1f8098f2d05332d1601d30db1c1f62757e730]
FAIL  D2a — busybox:1.38.0-musl index digest: expected [sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37], got [sha256:ea2b9914a16a4ac1981994af97b318f7c7d4db76b580c56177f08bf76f4a0be8]
```

Other differences are live counters that the decision says may vary:
`D3c` 6044 → 6156 tags; `D5e` counters; `gh-call-N-utc` stamps.

Re-derived at source: the pinned digests in `Dockerfile.candidate` lines 11–12
still resolve. An anonymous `HEAD` on `registry-1.docker.io/v2/library/rust/manifests/sha256:ca5c572a…`
returned **200**. The same request for `library/busybox/manifests/sha256:32b5cdad…`
returned **200**. The tags were re-pushed. The pins were not broken.
In the fresh run, `slim` and `slim-trixie` still share one digest (`4cd82946…`),
so the substance of `D1b` still holds.

### `r51-sources.sh`

Fresh FAILs (8). The first 5 are identical in the committed log:

```
FAIL  S3b — H2 headings differ:  (> ## Conformance note — rs-launch-blueprint optional web surface (R51 rows only))
FAIL  S4a — gate 1's prescribed string is absent from the decision
FAIL  S9b — R80 revision 2 does not declare OV-04
FAIL  S10e — R77 assigns the container host variable to R51: DECISION.md:723 does not contain [sets `RSLBP_WEB_HOST=0.0.0.0` explicitly]
FAIL  S10f — R77's host and port defaults: DECISION.md:606 does not contain [`127.0.0.1`, `8000`]
FAIL  S10g — R11 keeps the image build out of ci.yml: DECISION.md:144 does not contain [No container or deploy job enters `ci.yml`]
FAIL  S13d — the prompt's declared engines: expected [- engines: codex, opus], got [- engines: muse, opus]
FAIL  S14b — registered research operations (the Codex leg is absent, not failed): expected [1], got [2]
```

Other differences are counters that grow as the tree grows:
`override-scan-files` 143 → 156, and `S9c`.

### Other claims rechecked

- `shellcheck -S warning` on all three scripts: exit code 0, no output. The claim
  holds, but the `shellcheck.log` it cites does not exist (see F6).
- "exits non-zero on any `FAIL`": confirmed. The registries and sources scripts
  both exited 1 on FAIL.

## Findings

**F1: the sources check failed at authoring time, and the decision does not report that.**
- Claim (Empirical check): `./r51-sources.sh > r51-sources.log 2>&1   # → see the summary line in that log`.
  The Engines section then cites `S3b`, `S4a`, `S9b`, `S10e` and `S10f` as
  confirmations.
- Evidence: the committed `r51-sources.log` ends `SUMMARY: PASS=101 FAIL=5 SKIP=0 TOTAL=106`.
  By the script's own contract, that means exit code 1. The decision states that
  the other two scripts ended with 0 FAIL and exit 0. It states no count for this
  script, and nothing in the decision acknowledges the five failures.
- Repair: fix F2–F5 in a new revision, rerun the script to `FAIL=0`, and state
  its summary line explicitly, as the decision already does for the other two scripts.

**F2: `S3b` — the decision has an extra H2 heading.**
- Claim: "`S3a`–`S3d` assert the title line, the four H2 headings in order and nothing else".
- Evidence: `grep '^## '` finds 5 H2 headings. `## Conformance note — rs-launch-blueprint optional web surface (R51 rows only)`
  sits at line 677, between `## Decision` and `## Parameters`. `S3b` fails on it.
  RUNBOOK §5 lists no such H2.
- Repair: demote the section to an H3 under `## Decision`, or change both the check
  and the claim. The first option keeps the RUNBOOK §5 heading set.

**F3: `S4a` — the gate-1 string is split across lines and not matched.**
- Claim (line 257): the gate-1 string is recorded, citing `S4a`.
- Evidence: the text is present but split across lines 257–258 inside `**…**`,
  so `grep -F` of the one-line string returns 0 matches. `S4a` therefore fails.
- Repair: put the prescribed string on one line, or normalise whitespace inside the check.

**F4: `S10e`/`S10f` — R77 is cited at a superseded revision and stale line numbers.**
- Claims (lines 998 and 1058, plus the Sources list): "R77's accepted revision 1 …
  (`S10e`, `S10f`)" and `R77 (…/DECISION.md:606,723)`.
- Evidence: the R77 file is now `decision (revision 3)`, committed in `1e3cdb5b`
  at 2026-09-18 18:41:42 -0700. That is before the sources log's
  `date-utc: 2026-09-19T01:43:50Z` (18:43:50 -0700). In revision 1 (`de952239`),
  the cited text is at lines 606 and 723. In revision 3, the same text is at
  lines 678 and 931. The substance is unchanged.
- Repair: cite R77 revision 3 at lines 678 and 931, and update the `S10e`/`S10f`
  line numbers. Alternatively, pin the citation to commit `de952239`.

**F5: `S9b` — `OV-04` is cited in R80 revision 2, which has been superseded.**
- Claim (lines 609–612): "`OV-04` (R80 revision 2, for its unversioned probe paths)
  are all found by that same scan … (`S9b`)".
- Evidence: the R80 file is now `decision (revision 3)`, committed in `53b13f45`
  at 18:35:22 -0700, before the sources run. It contains 0 occurrences of
  `OVERRIDE (OV-04)`. Revision 2 (`ce291fe1`) contained 9.
  `S9-04` still passes, because `OV-04` appears elsewhere in the tree.
  `S9b`'s specific claim about R80 fails.
- Repair: re-ground the `OV-04` control on a current record, or pin it to
  `ce291fe1`. Then update the prose and `S9b` to match.

**F6: four cited evidence artefacts are missing.**
- Claims: `shellcheck.log` (line 865); `reproduction.log` and `r51-*.archive.log`
  (lines 896, 907), which support the claim that reruns from a clean `git archive`
  differ only in three classes of line; `tree-check.log` (line 942).
- Evidence: `evidence/` contains only `Dockerfile.candidate`,
  `dockerignore.candidate`, and the three `.sh` scripts with their three `.log`
  files. `review/` contains only `DECISION.md` and `evidence/`. The
  reproducibility claim therefore cannot be audited. The `review/` directory is
  also untracked in git, so a `git archive HEAD` extraction could not have
  included these scripts at the current HEAD.
- Repair: commit the four logs, or remove the claims that rely on them.

**F7: inputs moved after the decision, so a fresh rerun fails.**
- Claims: "The three base-image digests | `D1a`, `D2a`, `D3a` | all three unchanged,
  byte for byte"; "R11 … (`S10g`)" at `DECISION.md:144`; "The run's `manifest.json`
  holds exactly one research operation (`S14b`)"; `codex` is absent (`S13d`).
- Evidence:
  - `D1a`, `D1b`, `D1c` and `D2a` FAIL today, quoted above. The tags moved; the
    pinned digests still return 200.
  - R11 is now `decision (revision 7)`, dated 2026-09-23. Line 144 no longer
    carries the quoted sentence; the sentence now appears at line 270.
  - The R51 run's `inputs/prompt.md` now declares `- engines: muse, opus`.
    `operations/muse.json` and `raw/muse.md` now exist, so there are 2 operations.
    These are working-tree changes made after the decision.
- Repair:
  - In a new revision, re-verify against current inputs: the R11 revision-7 line,
    the muse leg in `## Engines`, and the prompt and manifest counts.
  - Assert that each pinned digest resolves, rather than that the moving tag still
    maps to it. Alternatively, update the recorded tag digests with a date.

## Not verified

- `C1`–`C14` built-image behaviour. Docker was unreachable from this session.
  I checked the committed figures only for internal arithmetic consistency.
- The claim of a clean-extraction rerun. Its logs are missing (see F6).
