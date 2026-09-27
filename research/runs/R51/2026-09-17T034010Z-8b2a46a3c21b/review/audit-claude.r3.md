actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 938c8db852769655d6f13ce1f0161173251009015ab77e07a0d464da7f72edd6
verdict: approve
unresolved-findings: none

# R51 — empirical audit of DECISION.md revision 3

Target: `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/DECISION.md`,
revision 3. The first action was `shasum -a 256 DECISION.md`, which returned
`938c8db852769655d6f13ce1f0161173251009015ab77e07a0d464da7f72edd6`. That equals
the expected hash, so the audit proceeded.

Scope: execution truth and evidence support only. This auditor did not read any
`review/audit-*.md`, any `R51-r*-snapshot.md`, or any `research/topics/*/raw/`.
It made no git writes, ran no `scripts/research_runner.py` command, and called
no paid API. Nothing was pushed. All scratch output went to `/tmp/r51-audit-r3/`.

## Host

| Component | Value |
|---|---|
| OS | macOS, Darwin 25.4.0 arm64 |
| Docker server | 29.8.0 (the same version the carried revision-2 container log records) |
| BuildKit | v0.32.2 on a `docker-container` builder that the script created and removed |
| Other tools | `cargo` on PATH; `shellcheck` 0.11.0; `gh` authenticated |
| grep | `/usr/bin/grep`, BSD grep 2.6.0-FreeBSD |
| Network | `https://index.crates.io/config.json` returned HTTP 200 |

This host had Docker and network access. Revision 3's synthesis sandbox had
neither. So the two scripts that revision 3 could not rerun were rerun here in
full, not only attempted.

Working directory for every script:
`research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence`.
Before the runs, every file in `evidence/` was hashed. After all runs,
`shasum -a 256 *` in `evidence/` matched the earlier list exactly. No script
wrote into `evidence/`. After the container run, `docker ps -a --filter name=r51`
and `docker buildx ls` showed no leftover `r51` containers or builders.

## Reruns

| # | Command (output to `/tmp/r51-audit-r3/`) | Exit | SUMMARY or result | Compared against | Result |
|---|---|---|---|---|---|
| 1 | `./r51-sources.sh > r51-sources.fresh.log 2>&1` | 0 | `PASS=147 FAIL=0 SKIP=0 TOTAL=147` | `r51-sources.log` | Differs only on volatile lines |
| 2 | `./r51-registries.sh > r51-registries.r4-attempt.log 2>&1` | 0 | `PASS=32 FAIL=0 SKIP=0 TOTAL=32` | `r51-registries.log` (carried from revision 2) | Differs only on timestamp lines |
| 3 | `./r51-container.sh > r51-container.r4-attempt.log 2>&1` | 0 | `PASS=54 FAIL=0 SKIP=0 TOTAL=54` | `r51-container.log` (carried from revision 2) | Differs only on declared volatile classes 1, 2 and 4 |
| 4 | `./r51-reproduce.sh r51-sources > reproduction.fresh-sources.log 2>&1` | 0 | `reproduction-exit: 0` | `reproduction.log` | Differs only on timestamps and the R68 live title |
| 5 | `./r51-reproduce.sh > reproduction.fresh-full.log 2>&1` (no arguments, so both check scripts) | 0 | `RESULT r51-registries: identical outside the volatile classes`; `RESULT r51-sources: identical outside the volatile classes`; `RESULT container: the same check ids carry the same verdicts in both runs`; `reproduction-exit: 0` | none committed | Pass |
| 6 | `shellcheck -S warning r51-container.sh r51-registries.sh r51-sources.sh r51-reproduce.sh` | 0 | no findings | `shellcheck.log` (`shellcheck-exit: 0`) | Pass |

Across the three check scripts: **233 PASS, 0 FAIL, 0 SKIP** (147 + 32 + 54).

### Byte comparison details

Every comparison ran `cmp`, then `diff` because `cmp` reported a difference.

**Rerun 1, sources.** `cmp`: `differ: char 55, line 2`. `diff` showed exactly
two lines:

```
2c2
< date-utc: 2026-09-27T04:29:36Z
> date-utc: 2026-09-27T06:17:22Z
111c111
< observed-r68-live-title: … — decision (revision 3)
> observed-r68-live-title: … — decision (revision 4)
```

Both lines are in the declared volatile classes. `date-utc` is class 1, and
`observed-r68-live-*` is class 3. The second line matters. R68's working file has
moved to revision 4 since revision 3 of this decision was written. `S10h` and its
neighbours still pass because they read the preserved, hash-asserted
`R68-r1-snapshot.md` and not the live file. This is the failure mode of
revision-2 emp finding 1. The repair has now held against a real upstream change.

**Rerun 2, registries.** `cmp`: `differ: char 47, line 2`. `diff` showed only
`date-utc` and the four `gh-call-*-utc` lines (00:48–00:49Z committed, 06:17–06:18Z
fresh). Every verdict line matched byte for byte, including all 22 HTTP checks
(`D1a`–`D6b`) and the ten GitHub checks. The `D3c` tag-count lines and the
`D5e` download-counter lines were also byte-identical this time.

**Rerun 3, container.** `cmp`: `differ: char 48, line 2`. The differing lines,
grouped by the decision's volatile classes:

| Class | Lines that differed |
|---|---|
| 1, timestamps and scratch names | `date-utc`, `scratch:`, the buildx `#1 …` builder-creation lines, `builder:` |
| 2, wall-clock figures | `C1b` (70 s committed → 45 s fresh); `measured-wall-incremental-with-mounts` (10s → 8s); `measured-wall-incremental-no-mounts` (17s → 16s); `C5c` message `(10s < 17s)` → `(8s < 16s)` |
| 4, re-exported layer sizes | `measured-disk-usage-main` (57769769 → 57769762); `measured-size-noprobe` (11489706 → 11489707); `measured-size-busybox-delta` and `C9a` (812604 → 812603); `measured-size-debian-slim` and `C9b` (36869229 → 36869253, still `+199%`); `measured-disk-usage-debian-slim` (166539349 → 166543469) |

No line outside those classes differed. In particular, these reproduced exactly:

- `measured-size-main: 12302310`
- `measured-binary-size: 1271368`
- the `docker image inspect` fields
- the uid 65532 identity lines
- the `healthy` and `unhealthy` health-check results (`C13`)
- the `--entrypoint /bin/sh` failure (`C14`)
- `ExitCode=143`
- all 54 verdicts

**Rerun 4, reproduction with `r51-sources` only.** `cmp`: `differ: char 51, line 2`.
`diff` showed three lines:

- the record's `date-utc`
- the fresh-run `f: date-utc` line
- the fresh-run `f: observed-r68-live-title` line (revision 3 → revision 4)

All other lines were identical: the `RESULT` lines, the container id/verdict
comparison, the `measured-` join table, and `reproduction-exit: 0`.

## The logs carried from revision 2

The question is whether `r51-container.log` and `r51-registries.log`, both
revision 2's runs carried unchanged, are acceptable evidence for revision 3.

**Verdict: acceptable.** The reasons follow.

1. **The disclosure is accurate.** The decision says the two logs are carried.
   It names the sandbox limits and keeps the failed attempts. Each claim was
   checked:

   | Claim in the decision | Check | Result |
   |---|---|---|
   | The container log is revision 2's run | `cmp r51-container.log r51-container.r2.log` | identical |
   | The container attempt summary | `r51-container.r3-nodocker.log` | `PASS=14 FAIL=0 SKIP=14 TOTAL=28` |
   | The registries attempt summary | `r51-registries.r3-nonetwork.log` | `PASS=10 FAIL=0 SKIP=22 TOTAL=32` |
   | The ten `G` verdict lines match the committed log | `diff` over lines beginning `PASS  G` or `FAIL  G` | identical |
   | The registries log's run time and its gh-call spacing | the log's `date-utc` and `gh-call-*-utc` lines | 00:48Z, calls about 21 s apart |

   The decision does not claim a separate `r51-registries.r2.log`, and none
   exists. The carried file itself is the revision-2 run.
2. **Revision 3 did not change what these scripts test.** `r51-container.sh`
   (mtime 17:55) and `r51-registries.sh` (mtime 17:48) predate revision 3.
   `Dockerfile.candidate` also predates it. Revision 3's edits were to
   `r51-sources.sh` and `r51-reproduce.sh`, both of which were rerun here.
3. **Both carried logs reproduced independently.** This audit reran both scripts
   on the same Docker 29.8.0 and BuildKit v0.32.2 as the carried logs record.
   Each run gave full PASS counts and differed only on declared volatile lines
   (reruns 2, 3 and 5). The three pinned digests in the Dockerfile are the same
   three digests in `DECISION.md`. `D1a`, `D2a` and `D3a` resolved each of them
   with HTTP 200 today, and the all-zero control `D1e` returned 404.

The r4 attempt logs are full successful runs, not SKIP records. They are kept
at `/tmp/r51-audit-r3/r51-container.r4-attempt.log` and
`/tmp/r51-audit-r3/r51-registries.r4-attempt.log`, not in `evidence/`.

## Load-bearing figures re-derived at source

| Figure | Independent check | Result |
|---|---|---|
| R68 is bound to accepted revision 1, sha256 `070b7ae1…` (`S10w`, `S10x`) | `shasum -a 256 research/runs/R68/…/review/R68-r1-snapshot.md` | `070b7ae10b4a3de48d8b1a1d7cb4799c18d4bfec92713f7d30776128e4578fd7` |
| The owner acceptance is at `execution-ledger.md:981` | `sed -n 981p` on the ledger | contains `R68 ACCEPTED at revision 1 (070b7ae1)` |
| Pinned digests: builder `ca5c572a…`, probe `32b5cdad…`, runtime `54df941e…` | `sha256:` strings in `DECISION.md` and in `evidence/Dockerfile.candidate` | the same three digests in both; all three resolve (rerun 2) |
| Image 12,302,310 B and binary 1,271,368 B | rerun 3 | exact match |
| The selected image is non-root (uid 65532) | rerun 3 | exact match |
| History summaries: sources r1 `PASS=101 FAIL=5`; sources r2 `PASS=132`; `r2-inspect-size` `PASS=52 FAIL=2` | `SUMMARY` lines in the preserved logs | all three match the decision's text |
| Gate ledgers `S4c`/`S4d` (5 members); `S17a`–`S17e` at the engines' lines | fresh sources log | PASS |

## Non-blocking observations

These are recorded for the record. None is a finding.

- **Wall-clock figures.** The decision states the rebuild times as "10 s with
  cache mounts against 17 s without" (lines 383, 385 and 1144). This rerun
  observed 8 s and 16 s. The decision declares both figures volatile in class 2,
  and `C5c` asserts only their order, which held. A reader should treat those
  figures as one run's observation.
- **Class-4 byte drift.** Three class-4 figures drifted, by +1 B, −1 B and +24 B.
  The largest is +24 B on the `debian-slim` comparison, which is built from an
  unpinned tag with a live `apt-get`. This is the run-to-run drift that
  revision 3 now describes accurately, in place of the withdrawn
  BuildKit-exporter explanation.
- **Scope of `r51-reproduce.sh`.** The script filters only classes 1 and 3. It
  does not rerun the container script, and its header says so. Container
  reproduction therefore relies on an auditor rerun such as rerun 3. That rerun
  was done here.
