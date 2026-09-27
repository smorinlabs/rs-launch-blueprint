actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 7a4f06ca0cfc136e516da23e62374532e6d76a9c452119b0a2d1113a736873be
verdict: approve
unresolved-findings: none

# R56 config-secret-policy — empirical audit of revision 5

Seat: empirical auditor, fresh context, independent of the synthesizer and of the judgment
auditor. Scope: execution truth and evidence support only (RUNBOOK §5, "The empirical
auditor reruns the check").

## Target

`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md`, revision 5.
`shasum -a 256` before any other action: `7a4f06ca0cfc136e516da23e62374532e6d76a9c452119b0a2d1113a736873be`,
equal to the expected value. The fresh `check-parameters-r5.log` line 3 recomputes the same
value.

## Environment

- Working directory: repository root, `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.
- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`,
  `shellcheck` 0.11.0, host `aarch64-apple-darwin`.
- Private `CARGO_HOME=/tmp/cargo-s36-R56-emp` (fresh) and exported
  `CARGO_TARGET_DIR=/tmp/cargo-s36-R56-emp-target`; "unset" runs use `env -u CARGO_TARGET_DIR`.
- Run 2026-09-27, fresh-log stamps `2026-09-27T08:47:57Z`–`08:48:19Z`.
- All output went to `/tmp/r56-emp-r5/`. No file under `review/` was written:
  a sha256 listing of every file under `review/` (auditor files and snapshots excluded)
  was taken before and after all reruns, and `cmp before.sha after.sha` reports them equal.

## Script classification

The classification follows the decision's own table (`## Empirical check`, lines 626–642),
not script-name suffixes.

| Class | Scripts |
|---|---|
| Current, rerun | `check-standard.sh`, `check-siblings.sh`, `check-registry.sh`, `check-probe.sh` (un-revved, revision 1); `check-probe-r3.sh` (supersedes `check-probe-r2.sh`; the table does not mark it superseded); `check-r4-couplings.sh` (no later script supersedes it; `check-r5-couplings.sh` continues its K numbering); `check-parameters-r5.sh`, `check-r5-couplings.sh` (added by revision 5) |
| Superseded: not rerun, not failed | `check-parameters.sh`, `check-parameters-r2.sh`, `check-parameters-r3.sh`, `check-parameters-r4.sh`, `check-probe-r2.sh`, `check-r3-mutation.sh`, `check-r4-mutation.sh` |
| Not a check | `refresh-snapshots.sh` (the only network fetcher; not run) |

## Reruns

Each command has the form
`./research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/evidence/<name>.sh > /tmp/r56-emp-r5/<name>.log 2>&1`.
The comparison is `cmp` against the committed paired log, with `diff` shown on mismatch.

| Script | Env | Exit | PASS / FAIL / SKIP | Difference from the committed log | Matches the decision? |
|---|---|---|---|---|---|
| `check-standard.sh` | — | `0` | 32 / 0 / 0 | line 1 `date-utc:` only | yes (32 / 0) |
| `check-siblings.sh` | — | `0` | 30 / 0 / 0 | `date-utc:`; line 10 `X0-detail` R61 sha256 `3131e895…` → `680d9c09…`; line 40 `X26` `owner-decisions.md:485` → `:486` | yes: these are exactly the two lines named at revisions 3, 4 and 5 |
| `check-registry.sh` | — | `0` | 38 / 0 / 0 | `date-utc:` only | yes (38 / 0) |
| `check-r4-couplings.sh` | — | `0` | 55 / 0 / 0 | `date-utc:` only | yes (55 / 0) |
| `check-parameters-r5.sh` | — | `0` | 59 / 0 / 0 | `date-utc:` only | yes (59 PASS; `sort -u` gives 59 distinct IDs with 0 duplicates; `CHECK_FAILURES=0`) |
| `check-r5-couplings.sh` | — | `0` | 4 / 0 / 0 | `date-utc:` only | yes (`K56`–`K59` plus the `K59-detail` line) |
| `check-probe-r3.sh` | exported | `0` | 24 / 0 / 0 | line 4 `date-utc:` only, against `check-probe-r3.log` | yes (24 / 0) |
| `check-probe-r3.sh` | unset | `0` | 24 / 0 / 0 | line 4 `date-utc:` only, against `check-probe-r3.unset.log` | yes (24 / 0) |
| `check-probe.sh` | unset | `1` | 34 / 1 / 0 | toolchain lines `1.98.0` → `1.98.1`; `date-utc:`; `PASS P0` → `FAIL P0 lockfile-is-current — expected [0], got [1]`; Cargo `Downloading crates …` / `Downloaded …` lines; `CHECK_FAILURES=0` → `1` | yes: this is the revision-3/4 table row (34 / 1, `P0` only, download lines from a fresh `CARGO_HOME`) |
| `check-probe.sh` | exported | `1` | 16 / 4 / 0 | FAILs are `P0`, `P3 probe-exit — expected [0], got [127]`, `P4`, `P5` | yes: this is the revision-3/4 table row (16 / 4) |

In both `check-probe.sh` runs, every measured figure is unchanged: `P7` 10, `P8` 13,
`P9` 89, `P12` `1.85.0`, `P13` `1.88`.

`check-probe.sh` is not a finding. The committed `check-probe.log` is revision 1's record
(`1.98.0`, `CHECK_FAILURES=0`). The main table's "all PASS" row describes that log
accurately. The decision records the later drift (lines 951–963 and 1003–1004), its cause,
and that no claim depends on the live index. It also states that revision 5 did not rerun
the Cargo checks (line 1024). I verified the stated cause independently. I copied `probe/`
to `/tmp` and ran `cargo generate-lockfile` without `--locked`. Diffing the result against
the committed lockfile shows exactly four `0.2.128` → `0.2.129` changes (the wasm-bindgen
family) and one `0.3.105` → `0.3.106` change (`js-sys`). The fresh lockfile still has
106 `name =` entries.

## Load-bearing figures re-derived at source

- **Standard blob.** `git -C /Users/stevemorin/c/cli-standards cat-file -p f9de0437…`
  produces 773 lines with sha256 `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f`.
  Line 327 is the `R5.5` secrets sentence. Line 545 is the `auth` group / credential-order
  sentence. All of this is as quoted in the decision.
- **Revision-4 pins (`PA17.1`–`PA17.6`).** I ran `shasum -a 256` directly on the six
  revision-4 artifacts. The prefixes `c8bb4f2d…`, `91349c87…`, `bd3a3ca7…`, `c4417d03…`,
  `36493c9f…` and `a6a3f774…` equal the values the script asserts.
- **`PA18`.** `R56-r4-snapshot.md` hashes to `145ac5d7c64819a8…`, as the decision states.
  I computed the hash only and did not read the file.
- **R54 status (JA4-1, `K56`–`K59`).** `docs/port/OWNER-ACCEPTANCES.md:78` carries
  `| R54 | 3 | \`1348f6b3…\` | accept | 2026-09-18 |` and the project-tier wording.
  `research/CLAUDE.md:59` lists R54 as `open`. R54's working decision carries the
  project-tier row at line 162, matching the "reported at line 162" claim. The prose at
  DECISION.md lines 14–18 and 326–334 states the same revision, hash, date and tier text
  that these checks assert.
- **Line citation.** DECISION.md contains no stale `owner-decisions.md:485`. Every
  occurrence reads `:486`, and the fresh `X26` line agrees.
- **`## Engines`.** The raw-report hashes (`X24`, `X25`) and the Muse / OpenAI line citations
  (`K24`–`K50`) cited in `## Engines` pass in the fresh `check-siblings.log` and
  `check-r4-couplings.log`.
- **Script hygiene.** `ls check-*.sh` lists 15 scripts, and `shellcheck` 0.11.0 on all 15
  exits `0`. Exactly 6 carry `disable=SC2016`, matching "all fifteen are `shellcheck` 0.11.0
  clean … Six carry a file-scoped `SC2016` waiver".

## Note

This file matches the census exclusion pattern `^(audit-[^/]*\.md|R56-r[0-9]+-snapshot\.md)$`
used by `check-parameters-r5.sh`, so writing it does not change that check's result.

## Findings

None. Every current check reproduces the exit code, the PASS/FAIL counts and the differing
lines that revision 5 records or inherits from its revision-3/4 tables. The superseded
checks were not rerun, as the brief instructs.
