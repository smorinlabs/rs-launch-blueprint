# R59 — file-log-sink — judgment audit of DECISION.md revision 1

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 15211fc070b2a29943b7a4cda6de6bdfae6b58a684dfca78a4c4c5f62c966d79
verdict: reject
unresolved-findings:
1. JF-4 — the member-1 workload is misstated, so the directory-removed rows over-generalise. (Severity: moderate. It does not overturn D1.)
2. JF-8 — the member-2 package count is "17"; `r59-deps.log` shows 15 unique packages. (Severity: low.)
3. JF-2 — member 2 (`tracing-subscriber`) has no crate figures, no maintenance state and no `inapplicable` statement. (Severity: low. This is the weakest of the three findings.)

## Scope and method

- **Target.** `research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/review/DECISION.md`, revision 1.
- **Hash.** The expected sha256 was `15211fc0…66d79`. Running `shasum -a 256` before any other step printed the same value.
- **Read set.**
  - the decision;
  - `inputs/prompt.md`, `inputs/PARAMETERS.md`, `inputs/prerequisites.json` and `manifest.json`;
  - `research/RUNBOOK.md` §2 and §5, which hold the actor and decision-shape contract;
  - `raw/muse.md` and `raw/opus.md`, spot-checked at every line the decision cites in `## Engines`;
  - every `review/evidence/*.log`, plus `r59-check/src/lib.rs`, `src/main.rs` and `Cargo.toml`;
  - the live `docs/port/PARAMETERS.md`;
  - the upstream `DECISION.md` files: R53 (`:45-49`, `:495-540`), R57 (`:86-95`, `:245-295`), R64 (`:21`) and R67, through its registry row;
  - R57's `acceptance.json`, read for its status only.
- **Not opened.** No `review/audit-*.md` of any seat or revision, and no `Rxx-r*-snapshot.md`.
- **Nothing run beyond reads.** No `git` write, no `scripts/research_runner.py` call, no paid API call. No check script was rerun; the empirical audit reruns them.

## Checks

### JF-1 — internal consistency: PASS, with one exception carried under finding 1

These parts agree with each other:

- the status block (`:9-14`), `## Parameters` (`:464-490`) and gap 1 (`:745`);
- the runner-up statements at `:73-76`, `:184` and `:219-221`: a constructor wrapper fences W12 and W15, and W20 and W24 remain;
- the package counts: `:170` gives "10 beyond itself; 9 not already in `tracing-subscriber`'s set", and `:563` gives "10 packages, `file-rotate` itself included". Both match `r59-deps.log:77`, which lists `adler2,chrono,core-foundation-sys,crc32fast,file-rotate,flate2,iana-time-zone,miniz_oxide,num-traits,simd-adler32`;
- the "61 lines" figure (`:56-57`) and "about 60 lines" (`:226`). The 61 reproduces as `src/lib.rs` lines 5–78 with blank lines, comment lines and the 3 `use` lines removed. No check asserts it.

The exception is the workload statement at `:155-156`. The rows it heads contradict it; see finding 1.

### JF-2 — every prompt question answered, every constraint honored: FAIL (finding 3)

**Questions.** The table at `:81-91` maps all seven prompt questions (`prompt.md:31-37`) to an answer and its evidence. Each answer is substantive:

- the size-rotation gap in `tracing-appender` (S15, S16, L13, L14);
- the size-plus-count survey;
- the principles, the agreement levels, and B1–B9 with AC1–AC9;
- the initialization order;
- the floor (A01–A09);
- the default numbers.

The R57 fallback that `prompt.md:15` requires is stated (P8, `:309-313`). The R58 dependency is handled as the prompt directs: an `assumes` line plus a fallback branch.

**Constraints.** The fitness gates are applied to every member-1 candidate. The licence gate is reported as inapplicable, citing R53's owner ruling. I verified that ruling at `research/topics/53-config-schema-validation/DECISION.md:45-49`.

**Gap.** `prompt.md:73` says "bundle members require the crate figures for each crate member" and "do not omit silently". Member 2 is a crate member: `tracing-subscriber` `=0.3.23`. It has none of the following:

- 90-day or all-time downloads;
- stars or open issues;
- a responsiveness sample;
- a rubric maintenance state.

It also has no `inapplicable` statement. By contrast, member 1's shortlist (`:193-198`) gives a rubric state to each of its three crates, so member 2's treatment is inconsistent. A search of the decision for "download" finds no match at all. The figures were available: `raw/opus.md:486-489` has them, and `r59-live-figures.log` has the crates.io and repository figures, though not a tokio-rs/tracing responsiveness sample.

### JF-3 — `## Engines` represents each engine faithfully and adjudicates every disagreement: PASS

**Spot-checks against the raws.** The decision's account matches each cited line:

| Claim in the decision | Raw line |
|---|---|
| Muse picks `file-rotate` wrapped in `non_blocking` | `muse.md:41`, `:82` |
| Muse puts the sink on the CLI and the web service | `muse.md:17` |
| Muse's runner-up is `flexi_logger` | `muse.md:86` |
| Muse raises no BASELINE-REVIEW | `muse.md:37` |
| Muse executed no code | `muse.md:37`, `:202` |
| Muse's config-error stance, used in D6 | `muse.md:78`, `:125` |
| Muse's "second pass" and `reload` alternative, used in D4 | `muse.md:31`, `:134` |
| Muse's global-`max_level` condition, used in D5 | `muse.md:33` |
| Muse's responsiveness sample, "5 of the last 7, median 6.8 days" | `muse.md:61` |
| Opus is CLI only | `opus.md:98-102` |
| Opus's `.transpose()?` contradicts its own AC8 | `opus.md:200` |
| Opus's performance figures, 420–576 ms against 209–239 ms | `opus.md:241-243` |
| Opus's BASELINE-REVIEW F260 | `opus.md:268` |
| Opus's claim that the `fmt` layer reports writer errors | `opus.md:329-331` |
| Opus's responsiveness, "median 2.6 days" | `opus.md:351` |
| Opus's "26 `unsafe` tokens" | `opus.md:496` |
| Opus's `non_blocking` result | `opus.md:517-520` |

**D7.** Muse's 17 matches for "rolling-file" are all "tracing-rolling-file". Muse has 0 matches each for `logroller`, `logforth` and `spdlog`, so the omissions D7 lists are real.

**D10.** Neither raw mentions `log_internal_errors`: `grep -c` printed 0 for each. The claim that neither leg found it holds.

**Adjudications.** Each of D1–D10 is settled on re-derived evidence (W, C, A and L checks), on an accepted registered value (D2, from R69), or explicitly as a judgment (D6). Two points against the synthesis's own preferred choices are recorded rather than hidden: the self-heal in W19, and the performance figures that did not reproduce (D8).

**Raw metadata.** The hashes and line counts at `:23-24` match `shasum` and `wc -l`: 214 lines and 814 lines.

### JF-4 — load-bearing claims trace to a cited log line, figure or source: FAIL (finding 1)

**Figures that trace.** I spot-checked each of these against its log line:

- W03 and W09: 4,056 B and 4,134 B (`r59-writer-contract.log:14-18`, `:40-44`);
- C03: 48, 0 and 182 (`r59-exit-durability.log:15`);
- E01: 12 escape bytes;
- S10–S12: `fmt_layer.rs:752`, `:362` and `:1051` (`r59-source-reads.log`);
- S15–S16: the five `Rotation` kinds;
- S18–S20: 26 lines and 28 tokens in 6 files;
- L08 and L09: the CI matrices;
- L12: the README says "based on rolling-file";
- the median of 1.9 days. I recomputed it from the 7 answered delays in `r59-live-figures.log:55-65` (0, 0.1, 0.3, 1.9, 2.6, 10.4 and 32 days). The median is 1.9;
- the bench figures (`r59-bench.log:8-19`).

**Upstream citations that trace:**

- R69's clauses "and nothing beyond it" and "log format … stays an environment variable named by R77";
- R67's clauses on flushing every stream, `ExitCode` with no `process::exit`, the library writing to no stream or file, `RSLB101`→1 and `RSLB203`→2;
- R64's `RSLB_PAGER`.

The R67 and R69 rows in `inputs/PARAMETERS.md` are byte-identical to the live registry.

**The exception.** The member-1 table and the account of the owned writer's weakness rest on a workload the checks did not use. Finding 1 gives the details.

### JF-5 — couplings hand other items their owned choices without deciding them: PASS

- **R58.** The constraint that the console level be a per-layer filter is framed as a working assumption the controller must check, not as a decision (`:476-490`).
- **Env prefix.** Left to the controller (`:513-517`).
- **R60 and R54.** Named as the owners of the parser and the loader (`:286-287`).
- **R77.** Owns any web file sink configured by env (D2).
- **BASELINE-REVIEW F260.** Forwarded without adjudication (`:442-452`).

The observation below about kebab-case keys is covered by the R54 re-verify trigger. It is therefore not a decided choice.

### JF-6 — `assumes` lines byte-identical to the live registry: PASS

I compared the five `assumes` lines (`:467-471`) with the live `docs/port/PARAMETERS.md`:

- lines 7-10 hold the four fixed rows;
- line 18 holds `logging-pipeline-contract`, whose value is `—`.

All five values are byte-identical.

### JF-7 — no conflict with accepted or published prerequisite values: PASS

- **R58.** The only registry prerequisite. It is unpublished, and the decision declares itself conditional on it.
- **R57.** Accepted: `research/topics/57-xdg-directory-set/acceptance.json` exists. Its `DECISION.md:90-92` and `:290` give R59's default as `paths.state_dir().join("rslbp.log")`, which is the path the decision carries. R57's `state_dir()` is total (`-> &Path`, `:284`), and `from_process_env()` is fallible (`:278-280`), so P8's `None` corresponds to `HomeDirError`. There is no conflict.
- **R67, R69 and R53.** The clauses the decision uses are quoted correctly.
- **D6.** The warn-and-continue choice conflicts with no registered value; see the observations.

### JF-8 — evidence scripts exist for every cited log, and claimed counts match the files: FAIL (finding 2)

- **Scripts.** Each of the 11 logs has a matching `.sh` file, and `r59-common.sh` is the shared helper, for 12 scripts in total.
- **Assertion totals.** The `SUMMARY:` lines add up as follows:

  | Check | T | S | P | W | A | E | C | G | H | D | L | Total |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Assertions | 4 | 22 | 5 | 29 | 11 | 3 | 4 | 3 | 4 | 3 | 22 | 110 |

  All 110 pass, matching `:557`.
- **Cross-checks.** P02 (11), P04 and G02 (8 tests) match their logs.
- **Mismatch.** "17 packages" (`:250`) does not match its log; see finding 2.

### JF-9 — decision shape follows the published contract: PASS

`RUNBOOK.md` §5 requires these parts; each is present:

- `## Decision`, with the recommendation, exact version pins, the settled F255–F261 rows, `### Principles and implementation` (`:324`), and `re-verify:` (`:454`);
- `## Parameters`;
- `## Empirical check`, with toolchain, OS, working directory, command and observed output;
- `## Engines`.

There is correctly no `## Supersedes`, because this is revision 1.

### JF-10 — the recommendation follows from the assembled evidence: PASS

- **Member 1.** The owned writer is chosen on B8. The limit-independent evidence supports that choice even after finding 1 is repaired:
  - W12 is a constructor panic;
  - W15 and W16 are an `Ok(10)` for bytes that were never written;
  - W20 and W24 are panics, reached at rotation time at any limit.

  The decision labels its confidence honestly: medium that owned code beats a dependency.
- **Member 2.** Blocking rather than `non_blocking` follows from C01–C04 and R67's flush clause.
- **The floor.** The per-layer-filter rule follows from A01–A09.
- **Surface.** CLI only follows from R69's accepted value.

## Findings (unresolved)

**1. JF-4 / JF-1 — the member-1 workload is misstated, so the directory-removed rows over-generalise.**

- *Claim.* `:155-156`: "The workload is 400 fixed-length 78-byte records, a 4,096-byte limit and 5 backups." `:166`: "Directory removed mid-run, recreatable | `Err(NotFound)` on every write, no panic (W17)". `:185-186`: "once its directory is removed, it keeps returning `Err(NotFound)` until the process restarts, where `file-rotate` recreates the directory (W17 versus W19)".
- *Evidence.* The limits differ by row:

  | Rows | Probe mode | Limit | Write size |
  |---|---|---|---|
  | W01–W10 | `rotate` | 4,096 B (the stated workload) | 78-byte records |
  | W17–W21 | `dirgone` (`src/main.rs:235-251`, `writer(kind, &p, 64)`) | 64 B | 80 B |
  | W22–W25 | `shared` (`r59-writer-contract.log:107`, header "400-byte limit") | 400 B | one record |
  | W26–W29 | `report` | 64 B | one event |

  At 64 B with 80-byte writes, every write forces a rotation. In the owned writer, `RotatingFile::rotate`'s `fs::rename` is what returns `NotFound`. At the recommended 10 MiB limit, a write after the directory is removed is below the trigger (`src/lib.rs:63`). It therefore goes to the still-open descriptor of the unlinked file and returns `Ok`. Both writers diverge only at the next rotation: the owned writer then errors, and `file-rotate` recreates the directory. So "Err on every write" and the self-heal contrast describe rotation time, not every write. The same limit governs whether W28 and W29 print a stderr diagnostic at the recommended size.
- *Repair.*
  - State the limit per row group, or per row.
  - Qualify `:166` and `:185-186`: at realistic limits, writes after the directory is removed return `Ok` into the unlinked file until the next rotation, for both writers.
  - Add one sentence stating that D1 still holds: W12 and W15 are limit-independent, and W20 and W24 panic at rotation.
  - Optionally, add one probe run of `dirgone` at 4,096 B.

**2. JF-8 — the member-2 package count does not match its log.**

- *Claim.* `:250`: "Gate 6: 17 packages with those features (`r59-deps.log`)".
- *Evidence.* The section of `r59-deps.log` headed `tracing-subscriber 0.3.23 (features fmt,std,registry,ansi,json) normal package set:` has 17 lines. Two of those lines are `cargo tree` `(*)` markers for packages already listed: `serde v1.0.229 (*)` and `tracing-core v0.1.36 (*)`. That leaves **15 unique packages**. The `file-rotate` count of "11 packages including itself" counts unique packages, so the decision uses two counting methods.
- *Repair.* Write "15 packages" (or "17 lines, 15 unique"), counted the same way as the `file-rotate` figure.

**3. JF-2 — member 2 has no crate figures and no maintenance state, and no `inapplicable` statement.**

- *Claim.* Member 2's gate list (`:239-250`) ends at gate 6. It gives no downloads, stars, open issues, responsiveness or rubric maintenance state for `tracing-subscriber` `=0.3.23`.
- *Evidence.* `prompt.md:73` requires "the crate figures for each crate member" and forbids silent omission. Member 1's shortlist gives a rubric state to each of its three crates (`:196-198`), which is inconsistent with member 2's treatment. The figures exist in `raw/opus.md:486-489` (90-day 147,886,240; 6,891 stars; 628 open issues) and in `r59-live-figures.log:13`, `:28`.
- *Repair.* Take one of two routes:
  - carry or re-derive the figures and assign a rubric state, adding a responsiveness sample or marking that sample as a gap; or
  - state `inapplicable — the crate is R58's selection, and its figures belong to R58's decision`.

  Either is a one-paragraph change. This is the weakest of the three findings, and it does not affect the recommendation.

## Observations (not findings)

- **(a) Engine seat.** `inputs/prompt.md:23` and `manifest.json:27-30` say `engines: codex, opus`, and `inputs/EXECUTION.json` assigns R59 `codex, opus`. Owner decision Q17.A (`RUNBOOK.md:73-77`) authorizes the Muse leg that was actually used. The decision discloses this at `:605-618`. Per controller note (a), this is not a synthesis failure. Repair: the controller re-freezes the inputs and cites Q17.A.
- **(b) Conditional on R58.** `logging-pipeline-contract` is `—` in both the frozen and the live registry, and `prerequisites.json` records R58 as `missing`. The decision is explicitly not acceptable until R58 lands (`:9-14`, `:745`). Its five-part working assumption and its `log`-facade fallback (`:476-490`) must be re-checked against R58's accepted decision. That is controller business.
- **(c) The tower-http 0.6.11 versus 0.7.x tension (R75, R78).** Not applicable. R59 selects no HTTP middleware and does not touch `tower-http`.
- **R57 verified, not merely carried.** R57 is accepted, and its default path matches the carried claim (JF-7). A later revision could cite `research/topics/57-xdg-directory-set/DECISION.md:90-92, 290` directly.
- **Support D6 did not cite.** D6 calls warn-and-continue an "exception" to R67. R67's registered value itself describes its crash record as "an injected best-effort sink", which is precedent for a diagnostics sink that does not fail the command. R67's code table maps reported errors to codes; it does not require an unopenable diagnostics file to abort. The choice is therefore better supported than the decision says.
- **Kebab-case keys.** `[logging] file-level` and `file-format` depart from py's `file_level` (`prompt.md:8`, F255). The departure is adopted from `raw/opus.md:672, 737` without an argument. The R54 key-naming re-verify trigger (`:455-456`) covers it, but the F255 row could say so.
- **Not executed, and disclosed.** The `flexi_logger 0.31.10` fallback pin was not executed (`:77-79`, gap 10). Neither was the combined composition block at `:385-405`, which the decision labels "proposed, not executed as one piece".
- **File mode.** The log file's mode is left to the umask. R67's crash record, in the same State directory, is written `0600`. The directory's `0o700` mode mitigates the difference, but that mode is set and not asserted (`:588`). P03 should assert both modes.
- **Carried claims.** These are labelled carried and cited to raw lines: py behavior, the org CLI Design Standard rules, the adopters, the `logroller` exit defect and the `max_level_*` cap. That labelling is consistent with the stated read set.
