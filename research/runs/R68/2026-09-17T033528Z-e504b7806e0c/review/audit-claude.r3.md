# R68 — release-binary-artifacts — empirical audit of DECISION.md revision 3

actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: bb55cf4acbc9ce3ab4fb9ea7b0d969c2a86a77253640b52df1690a792155d4c2
verdict: reject
unresolved-findings:
1. EA3-1: the `## Empirical check` section misstates what `decision-self-check.sh` asserts about the title line. See §4.

## 0. Scope and identity

- Seat: empirical auditor, fresh context. I am independent of the synthesizer and the judgment auditor.
  I read no `review/audit-*.md` file, no `review/R68-r*-snapshot.md` file, and nothing under
  `research/topics/68-*/raw/`. I made no git writes, ran no `scripts/research_runner.py` command,
  and made no paid or submitting API call.
- Target: `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`, revision 3.
  `shasum -a 256` gave `bb55cf4acbc9ce3ab4fb9ea7b0d969c2a86a77253640b52df1690a792155d4c2` before
  the work and again at write time. It matches the expected hash.
- Host and tools, on 2026-09-27 UTC (2026-09-26 Pacific):
  `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`,
  `gh version 2.101.0 (2026-09-15)` (already authenticated), `shellcheck` 0.11.0, macOS on an Apple
  M4 Pro. `CARGO_HOME=/tmp/cargo-s19-r68-emp` is private to this session. `TMPDIR` was the default
  macOS per-user directory.
- Working directory for every script: `review/evidence/`. Every fresh log went to `/tmp/r68-audit-r3/`.
  Nothing under `evidence/` was written.
- Evidence state: every evidence log and `profile-probe.Cargo.lock` is untracked working-tree
  content, and `decision-self-check.sh` and `profile-probe.sh` are modified relative to `HEAD`. "The
  committed log" therefore means the file on disk beside the script.
  - The r2 logs have these mtimes: `profile-probe.r2.log` 18:05, `…r2-rerun-same-env.log` 18:10,
    `…r2-rerun-alt-paths.log` 18:14, `artifact-sources.r2.log` 18:15, `decision-self-check.r2.log`
    18:20, all on 2026-09-26 local time.
  - All of those predate the revision-3 edit (`DECISION.md` 21:10, `decision-self-check.r3.log`
    21:11). The r2 logs were therefore not regenerated under revision 3.
  - The decision claims all three scripts run from a clean `git archive HEAD` extraction. That claim
    cannot be tested before publication, because the evidence is not yet at `HEAD`. It was not
    tested.

## 1. Reruns

### 1a. `decision-self-check.sh` — baseline `decision-self-check.r3.log`, which the decision cites as current

```
./decision-self-check.sh > /tmp/r68-audit-r3/decision-self-check.log 2>&1   # exit 0
```

- Result: `RESULT: PASS — every assertion held`. Totals: 27 `ASSERT`, 27 ok, 0 fail, 0 skip.
- `cmp` against `decision-self-check.r3.log` reported `differ: char 58, line 2`.
- `diff` shows exactly one differing line, the clock:

  ```
  < date(UTC): 2026-09-27T04:11:30Z
  > date(UTC): 2026-09-27T04:38:10Z
  ```

- The `decision: DECISION.md (69711 bytes)` line is identical. The decision says a byte-count
  mismatch would signal an edit after the self-check ran, so no such edit happened.
- The fresh log also prints these snapshot digests:
  - `R68-r1-snapshot.md sha256 = 070b7ae1…`
  - `R68-r2-snapshot.md sha256 = 72bd7972…`

  Both are asserted byte-identical to the audited revisions.
- `profile-probe.Cargo.lock sha256 = 2756d45c…` matches my own `shasum`. The lockfile holds 85
  `[[package]]` entries, which matches the decision.
- `docs/port/COMMONALITY.md` lines 78, 218 and 224 are the F072, F214 and F220 rows, which matches the
  decision.

### 1b. `artifact-sources.sh` — baselines `artifact-sources.r2.log` (latest rerun) and `artifact-sources.log` (the cited home of the figures)

```
./artifact-sources.sh > /tmp/r68-audit-r3/artifact-sources.log 2>&1   # exit 0
```

- Result: `RESULT: PASS — every assertion held`. Totals: 26 `ASSERT`, 26 ok, 0 fail, 0 skip.
- The decision says the figures it cites "keep their 2026-09-17 retrieval date and their home in
  `artifact-sources.log`", and that revision 2 re-ran the script into `artifact-sources.r2.log`. I
  compared the fresh log with both.
- Against `artifact-sources.r2.log`, `cmp` reported `differ: char 59, line 2`. `diff` shows only the
  clock line:

  ```
  < date(UTC): 2026-09-27T01:15:28Z
  > date(UTC): 2026-09-27T04:38:26Z
  ```

  Every `ASSERT`, `PINNED`, `HEAD` and `FIGURE` line is byte-identical, including the live counters.
  This run was about 3 hours 23 minutes after the r2 run.
- Against `artifact-sources.log` (r1, 2026-09-17), `cmp` reported `differ: char 55, line 2`. The diff
  is confined to lines the decision declares drift-prone:
  - line 2 (`date(UTC):`);
  - line 3 (`gh:` 2.98.0 → 2.101.0);
  - line 122 (the `HEAD` commit of `cargo-binstall/SUPPORT.md`, `94dc7fe4…` → `422f3094…`);
  - lines 169–175 (the live `FIGURE` counters);
  - line 196 (the newest `cargo-binstall` is now `1.24.0`, `created_at=2026-09-26T12:38:43Z`,
    `rust_version=1.79.0`).

  The decision already discloses the `1.24.0` drift and says it does not move the `1.23.0` floor.
  All 26 `ASSERT` lines are identical across r1, r2 and this run.
- `registry-gap-present=1` still holds (line 182). This supports the decision's statement that dist's
  newest GitHub release still has no crates.io version.

### 1c. `profile-probe.sh` — baseline `profile-probe.r2.log`, which the decision's table cites

```
./profile-probe.sh > /tmp/r68-audit-r3/profile-probe.log 2>&1   # exit 0
```

- Result: `RESULT: PASS — every assertion held`. Totals: 21 `ASSERT`, 21 ok, 0 fail, 0 skip.
- `cmp` against `profile-probe.r2.log` reported `differ: char 50, line 2`. `diff` shows three kinds of
  differing line:
  - the `date(UTC):` line;
  - every `TIME` line, which the script itself labels `(wall clock, does not reproduce)`;
  - one `SIZE` line:

    ```
    < SIZE debug=line-tables-only                    2242552 bytes  (after external strip -S -x:    1628280)
    > SIZE debug=line-tables-only                    2242728 bytes  (after external strip -S -x:    1628280)
    ```

- This rerun differs from the r2 run in one environment variable, `CARGO_HOME`:
  `/tmp/cargo-s19-r68-emp` here, `/tmp/cargo-s8-R68-r2` in the r2 run. That is the path sensitivity
  the decision measured and disclosed. `TMPDIR` was the default in both runs.
- Against the decision's stated reproduction rule:

  | Line kind | Rule | Observed |
  |---|---|---|
  | `ASSERT` outcomes | identical | all 21 identical, and byte-identical as text |
  | `BACKTRACE` lines | identical | all identical |
  | `DELTA` lines | within ±2.5 pp | all 12 byte-identical (0.0 pp difference) |
  | `SIZE` lines | not expected to match | 11 of 12 byte-identical; `debug=line-tables-only` is +176 bytes and its `DELTA` is unchanged at +12.5% |

  **The rule is met.**
- Build times in this run, baseline → recommended:
  - clean build 16 s → 30 s (1.9×), inside the decision's stated 1.3×–1.9× spread;
  - bin-only rebuild 0 s → 12 s, the order-of-magnitude separation the decision claims.

## 2. Re-derived figures

- The size table in `## Empirical check` matches the `SIZE`/`DELTA` lines of `profile-probe.r2.log`
  exactly on all 12 rows. This covers the byte counts, the external-strip counts and the deltas.
- The revision-1 Δ column matches `profile-probe.log`, including `opt-level=s` +13.0% and
  `panic=abort` −20.3%.
- The `BACKTRACE` table (frames 4, 4, 0, 2, 5; exits 101, 101, 101, 134, 101) and the `at ./src/`
  counts (2 in the build tree, 0 after copying out) match the r2 log and my rerun.
- Same-environment claim: I extracted the `SIZE`/`DELTA`/`BACKTRACE`/`ASSERT` lines of
  `profile-probe.r2.log` and `profile-probe.r2-rerun-same-env.log`. `cmp` finds them byte-identical.
- Alternative-paths claim: `profile-probe.r2-rerun-alt-paths.log` has `lto=fat` at −19.0% against
  −19.8% in the r2 log, a 0.8 pp difference. Its `debug=line-tables-only` is 2 243 128 bytes against
  2 242 552 bytes, 576 bytes more, with the same +12.5% delta. Both figures match the decision.
- Opus comparison: `raw/opus.md` lines 463–476 give `lto=fat` −18.8% (1.0 pp from −19.8%), the
  recommended row −24.4% (0.1 pp from −24.5%), and `thin+cu1` −16.7% (0.7 pp). The largest gap is
  1.0 pp, which supports the "within one percentage point" claim.
- Engines, Codex, which revision 3 adds:
  - `raw/codex.md` hashes to `297219ed…`, is 48 183 bytes, and is identical to its content-addressed
    twin.
  - `operations/codex.json` has `state: succeeded`, `model: gpt-5.6-terra`,
    `actual_provider: codex-cli-0.155.1`, `at: 2026-09-20T07:02:42Z` and
    `collected_at: 2026-09-21T03:00:44Z`.
  - In `raw/codex.md`: 12 direct dependencies and 162 locked packages (lines 118 and 123); host Apple
    M4 Pro, rustc 1.98.0 (lines 572–574); a floor check at 1.96.0 (lines 577–580).
  - Measurements (lines 588–590): thin+cu1 3 642 912 bytes; fat+cu1 3 156 320 bytes, which is
    486 592 bytes smaller; thin+cu1+`strip = "symbols"` 2 923 344 bytes.
  - Timings: clean 28.22 s → 47.39 s is 1.68×, and edit rebuild 7.35 s → 18.99 s is 2.58×.
  - `lto = "thin"` alone: 4 378 048 / 4 452 240 bytes is −1.67%.
  - Codex records no backtrace measurement: `backtrace` and `frames` do not occur in the file. This
    supports "Codex measured no backtrace".
  - Codex's four targets include `aarch64-unknown-linux-gnu` (line 275), and it writes
    `inherits = "release"` for the dist profile (lines 307 and 317).
  - Every figure the decision attributes to Codex re-derives.
- `shellcheck decision-self-check.sh profile-probe.sh` exits 0 with no output. This supports the
  decision's shellcheck claim for the revision-3 script.
- Not independently checked: the decision says `profile-probe.sh` and `artifact-sources.sh` were not
  re-run in revision 3 because "the revision-2 empirical audit re-ran both". That audit
  (`review/audit-claude.r2.md`) is outside my permitted reading. My own reruns in §1b and §1c cover
  the same ground.

## 3. Totals

| Script | Exit | ASSERT ok / fail / skip | Baseline compared | Result |
|---|---|---|---|---|
| `decision-self-check.sh` | 0 | 27 / 0 / 0 | `decision-self-check.r3.log` | pass; only `date(UTC):` differs |
| `artifact-sources.sh` | 0 | 26 / 0 / 0 | `artifact-sources.r2.log`; also `artifact-sources.log` | pass; r2: only `date(UTC):`; r1: declared-drift lines only |
| `profile-probe.sh` | 0 | 21 / 0 / 0 | `profile-probe.r2.log` | pass under the stated rule; `date`/`TIME` lines plus one `SIZE` line (+176 B) differ |

Execution truth holds. Every script passes, every load-bearing figure re-derives, and no revision-2 evidence log
changed under revision 3.

## 4. Finding

**EA3-1 — the description of the self-check's title assertion is stale.**

- **Failed claim.** `DECISION.md` lines 428–429, in `## Empirical check`, say of
  `decision-self-check.sh`:

  > it asserts the H2 set and its order, the absence of a `## Supersedes` section, that the title
  > names revision 2, that `review/R68-r1-snapshot.md` hashes to the audited revision-1 digest, …

- **Evidence.** The script and its logs contradict this in two ways:
  - `decision-self-check.sh` line 63 is `assert "$(has "$N")" "the title line names revision 3"`.
    Both `decision-self-check.r3.log` and my fresh rerun print
    `ASSERT ok   the title line names revision 3`.
  - The same enumeration omits an assertion the script now runs and both logs print:
    `ASSERT ok   the revision-2 snapshot is byte-identical to the audited revision 2`.

  Three paragraphs earlier, the decision itself states that "The title assertion was updated to
  revision 3 and a revision-2 snapshot assertion added". The section therefore contradicts itself.
  The misstated object is the primary evidence script, which the decision names as "the check an
  auditor should run first". A reader who relies on the list is told the wrong thing about what it
  verifies.
- **Repair.**
  1. In that sentence, replace "that the title names revision 2" with "that the title names
     revision 3".
  2. After the revision-1 snapshot clause, add "that `review/R68-r2-snapshot.md` hashes to the
     audited revision-2 digest".
  3. Re-run `./decision-self-check.sh > decision-self-check.r3.log 2>&1` (or into a new `.r4.log`),
     and cite that log. The byte count of `DECISION.md` will change, so the current r3 log will no
     longer reproduce.

  No script, figure or other log needs to change.
