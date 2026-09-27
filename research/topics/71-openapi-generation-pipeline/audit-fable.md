actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 0743a12544a2ef9434bfd1fcff9b9fe80812396569eb3963e49581c2078400c6
verdict: approve
unresolved-findings: none

# R71 revision 3 — directed verification of the enumerated repairs (fable seat)

**Scope.** This seat checks only the five repairs listed in `review/audit-fable.r2.md` (findings 1–2) and `review/audit-codex.r2.md` (M1–M3). For each one, it confirms or disputes the repair. It did not look for new findings. It read `audit-fable.r2.md`, `audit-codex.r2.md`, `R71-r2-snapshot.md` and the new `DECISION.md` in full. It read no `.r3vo.md` file. The repair under verification is `diff R71-r2-snapshot.md DECISION.md`, which this seat ran itself. The seat made no git writes and no network calls, and every rerun wrote to `/tmp`.

## Hash check

- `shasum -a 256 review/DECISION.md` gives `0743a12544a2ef9434bfd1fcff9b9fe80812396569eb3963e49581c2078400c6`, which equals the expected value.
- `review/audit-fable.r3vo.md` did not exist before this write.

## The repair is confined to the decision text

- **The diff.** The diff touches the header and the revision notes (:1, :3, :7–:18) and blocker 2 (:29). It touches :82, :84, :87 and :91, the A10/A11 cells (:141–:142), the new download and snapshot block (:289–:299), and the evidence table (:353, :358–:359). It adds the replay and rerun notes (:361–:380) and changes :562 and :580. No change reaches the recommendation, a member, a version, an `assumes` line or a command.
- **The evidence files.** The latest modification time in `review/evidence/` is 2026-09-27 09:56 local. That is earlier than both revision-2 audits (10:59 and 11:03) and earlier than the new `DECISION.md` (11:48).
- **The citation logs.** My legacy replay reproduced the committed `r71-citations.log` byte for byte (below). My in-place run of `r71-r2-citations.sh` writes only to stdout, which I sent to `/tmp`.

## Per-repair confirmations

1. **fable-1 (JF-8) — CONFIRMED.**
   - **Where the reworded text appears.** The text is "cases `O1`–`O4` executed by `r71-oasdiff.sh`; `O5` and `O6` are manual follow-on steps whose expectations the log records". It appears in blocker 2 (:29), in the evidence-table row for `r71-oasdiff.sh` (:358) and in the first P03 item (:580). A10 (:141) now says that `O5` is a manual step that the script does not execute. A11 (:142) says that `O4` is one of the four executed cases and that `O6` is a manual step.
   - **Checked against the script.** In `review/evidence/r71-oasdiff.sh`, the `CASES` array (lines 19–24) holds `O1`–`O4`. When `oasdiff` is on PATH, the script loops over `CASES` only (lines 40–48). `O5` and `O6` appear only as `PLANNED` echoes in the branch that runs when `oasdiff` is absent (lines 32–33). The new wording is therefore accurate.

2. **fable-2 (JF-2) — CONFIRMED.**
   - **The figures match the log.** `r71-figures.log` gives these values:
     - line 5: `utoipa recent_downloads=15462313 downloads=48906319`
     - line 8: `utoipa-gen` 15468242 / 48938245
     - line 11: `utoipa-axum` 3181337 / 7552921
     - line 20: `expectorate` 278769 / 1683740

     All eight numbers equal the table at :291–:296.
   - **Placement.** The table opens *Maintenance state, by the rubric* (:287). Its lead-in (:289) states the retrieval time 2026-09-27T03:43:23Z, which matches `r71-figures.log` line 1, and labels the figures as dated snapshots.
   - **The requested rerun.** I reran `r71-r2-citations.sh` against the new decision, with output to `/tmp`. It exited 0. Its first line records the decision sha `0743a125…c400c6`, and its last line reads `resolved=159 unresolved=0`, which matches :353.

3. **codex M1 — CONFIRMED.**
   - **The script cannot take a path.** `r71-citations.sh` has no path argument. It computes `RUN` from its own location (line 11) and hashes and reads `$RUN/review/DECISION.md` (lines 13 and 18). This matches :361.
   - **My independent replay.** I built a symlink mirror at `/tmp/r71-r3vo-legacy` in which `review/DECISION.md` is a copy of `R71-r1-snapshot.md`. The script and both logs in the mirror are byte-identical copies, which I confirmed with `cmp`.
   - **Replay result.** The run exited 0. Line 1 is `# decision sha256=f0f9450f…e2a4fc`, and the last line is `# citations resolved=124 unresolved=0`. `cmp` against the committed `r71-citations.log` found no difference. Both files hash to `f1c97ccc…97d9c9`, the value stated at :367.
   - **Current-decision check.** The evidence row (:359) records the replay. :353 and :367 keep `r71-r2-citations.sh` as the current-decision check.

4. **codex M2 — CONFIRMED.**
   - **The five logs and their volatile fields.** The note at :369–:380 names the five non-identical comparisons: `r71-figures`, `r71-sources`, `r71-r2-gates`, `r71-oasdiff` and `r71-probe`. For each one it lists the volatile fields that the audit reported. For the probe, those fields are the private `CARGO_HOME`, the temporary atomic-write path, a thread ID, test durations and `P13` wall time (16 s → 9 s).
   - **Old timestamps match the committed logs.** The committed logs contain these values:
     - `r71-figures.log`: `03:43:23Z`
     - `r71-sources.log`: `03:42:30Z`
     - `r71-r2-gates.log`: `16:52:36Z`
     - `r71-oasdiff.log`: `16:53:04Z`
     - `r71-probe.log` P0: `03:39:01Z`
     - `r71-probe.log:103`: `wall_seconds=16`
   - **New timestamps.** The new-side timestamps equal the values in `audit-codex.r2.md`.
   - **Stable claims.** The note lists the stable claims that matched and says both raw logs are retained.

5. **codex M3 — CONFIRMED.**
   - **"today" is gone for the branch head.** `grep today` finds no remaining "py's `main` today" wording. :84 now reads "was also py's `main` at retrieval, 2026-09-27T03:42:30Z" and cites `r71-sources.log` line 5, which is `P main commit b55b8c26…`. :84 also records `d39f07fa…` at the 17:56Z rerun.
   - **Dated-snapshot labels.** Snapshot labels appear at :82, :87, :289 and :298, and at :562 ("as read at 2026-09-27T03:42:30Z").
   - **Rerun values match the audit.** :298 records reverse dependencies 1,810 (was 1,813), `utoipa` stars 4,107 (was 4,106), `oasdiff` stars 1,389 (was 1,387) and crates.io `main` `765bbf47…` (was `067b45e1…`). All of these equal the audit's report.
   - **Cited code bound to a commit.** :91 binds the Rust project's code to commit `067b45e1a15fc1b97f7321792b86bdf8d6371d7c`, which is recorded at `r71-sources.log:126`.

## Observations (noticed, not findings)

- **Manifest lines and the head commit.** The crates.io manifest lines are logged as `V rust-lang/crates.io@main:Cargo.toml:…` (`r71-sources.log:108–110`). The head commit comes from a separate `W` line in the same retrieval (`:126`). The binding at :91 is therefore indirect, as the repair reported.
- **Other `O1`–`O6` wording.** :416 and the round-1-audit sentence in :29 still say `O1`–`O6`. Both describe the case set or a past audit run, not what the script executes, so they do not contradict the repair.
- **"today" at :231.** "So the flag costs nothing today" at :231 is about the current contract, not a branch head. M3 does not cover it.
- **Where the audit's rerun logs live.** The audit's fresh rerun logs exist only in `/tmp` on the audit host. The `review/` directory is untracked, so "committed under `review/evidence/`" is wording written before publication.
