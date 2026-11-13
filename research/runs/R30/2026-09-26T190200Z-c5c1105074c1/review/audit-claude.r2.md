actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: d15d4cee636494fac69c6996017c9c099860dad8b1c205d1b45fbde7ac86d687
verdict: reject
unresolved-findings:
1. **The frozen policy snapshot is no longer byte-identical to the live policy, so `r30-inputs.sh` fails `I-policy`.**
   - **Failed claim.** The inputs table says: "`inputs/EXECUTION.json`, re-frozen in revision 2; byte-identical to the live `research/EXECUTION.json` (`I-policy`)", with sha256 `c670184d822b47daa337a88be52454bd18e5a79ccda46f65e062d271959f3ce3`. The `## Empirical check` table says `r30-inputs.sh` gives "37 | 37 PASS, 0 FAIL".
   - **Evidence.** My rerun (`bash r30-inputs.sh > /tmp/r30-emp-r2/r30-inputs.log 2>&1`) exited 1. Line 5 of the fresh log reads `FAIL I-policy -- policy drift`, and the summary reads `# summary: PASS=36 FAIL=1 failures=1`. The committed log has `PASS I-policy run policy snapshot is byte-identical to the live research/EXECUTION.json` and `PASS=37 FAIL=0`. Current hashes:

     | File | sha256 |
     |---|---|
     | `inputs/EXECUTION.json` (frozen) | `c670184d822b47daa337a88be52454bd18e5a79ccda46f65e062d271959f3ce3` |
     | live `research/EXECUTION.json` (working tree) | `acdcbfff5fa46a68cd0999147b294e41fa6c4d6c88428c9fc7c46cdedfabf137` |
     | `HEAD:research/EXECUTION.json` | `ac4561fe28cc219a5a8ded5a53607bddb3ab84a7c42b87edcf38bf0043d27f2b` |

     The frozen snapshot and the live file therefore both differ from the file at `HEAD`, which was last changed in `c2e06e81`.
   - **Cause.** The drift was not made by the synthesis. The live file's mtime is `2026-09-26T23:30:19-0700` (06:30Z). That is after the committed `r30-inputs.log` header (`run 2026-09-27T04:54:35Z`). The file shows as `M` (modified, uncommitted) in `git status`. A structural JSON diff shows one change only. The existing map `empirical_auditor_overrides` has grown from 6 entries in the frozen copy (R11, R55, R57, R61, R62 and R72) to 50 in the live file. The 44 added entries are all set to `"claude"`, and R30 is among them. No entry was changed or removed. `engine_overrides.R30` and `items.R30.engines` are still `["muse", "opus"]`. The other Q17.A checks still pass: `I-override`, `I-prompt-engines` and `I-runbook-q17a` all PASS in my rerun. Every seat and engine claim in `## Engines` therefore still holds.
   - **Why this blocks acceptance.** RUNBOOK §5 says the checker verifies "content hashes, and current inputs" and refuses "stale inputs". The decision states byte identity in the present tense, and that statement is currently false.
   - **Repair.**
     1. The controller commits or otherwise stabilises its `empirical_auditor_overrides` edit first. Freezing against an uncommitted working-tree file would repeat this exposure.
     2. Re-freeze `inputs/EXECUTION.json` to that file.
     3. Replace the `c670184d…` hash in the inputs table with the new hash.
     4. Rerun `r30-inputs.sh` and confirm `PASS=37 FAIL=0`.
     5. Re-audit the resulting revision.

     No other part of the decision needs to change.

## Rerun record

**Host.** macOS Darwin 25.4.0, arm64. `CARGO_HOME=/tmp/cargo-s28-R30-emp` and `CARGO_TARGET_DIR=/tmp/cargo-s28-R30-emp-target` (private to this seat). All six cargo-running scripts printed `# CARGO_TARGET_DIR=<ws>/target` in my fresh logs, which confirms that each one pinned its target directory inside its own `mktemp -d` workspace.

**Host load.** `uptime` printed 1-minute load averages of 269.23 before the pass and 250.45 after it. The decision's pass recorded 4.65 and 5.36.

**Method.**
- The seven scripts ran sequentially in the decision's order: lints, scope, severity, suppression, upstream-docs, wiring-cost, wiring-severity. `r30-inputs.sh` ran last.
- The working directory was `review/evidence/`. Each command had the form `bash r30-<name>.sh > /tmp/r30-emp-r2/r30-<name>.log 2>&1`.
- `git status --porcelain` of `review/evidence/` was unchanged before and after, so no committed log was overwritten.

| Script | Exit | Fresh result | Committed result | `cmp` |
|---|---|---|---|---|
| `r30-lints.sh` | 0 | 14 PASS, 0 FAIL, `failures=0` | same | differ: char 33, line 1 |
| `r30-scope.sh` | 0 | 20 PASS, 0 FAIL, `failures=0` | same | differ: char 33, line 1 |
| `r30-severity.sh` | 0 | 17 PASS, 0 FAIL, `failures=0` | same | differ: char 36, line 1 |
| `r30-suppression.sh` | 0 | 16 PASS, 0 FAIL, `failures=0` | same | differ: char 39, line 1 |
| `r30-upstream-docs.sh` | 0 | 22 patterns in 6 files, 0 `MISSING`, `failures=0`; all six blob shas identical | same | differ: char 41, line 1 |
| `r30-wiring-cost.sh` | 0 | 17 PASS, 0 FAIL, `failures=0` | same | differ: char 39, line 1 |
| `r30-wiring-severity.sh` | 0 | 8 PASS, 0 FAIL, `failures=0` | same | differ: char 43, line 1 |
| `r30-inputs.sh` | **1** | **36 PASS, 1 FAIL (`I-policy`)** | 37 PASS, 0 FAIL | differ: char 34, line 1 |

Totals over the eight scripts: 128 PASS, 1 FAIL, 0 skip, plus 22/22 upstream patterns found.

**`cmp` mismatches.** All eight logs differ from their committed copies. Every first difference is the line-1 run timestamp:

| Log | Committed line 1 | Fresh line 1 |
|---|---|---|
| lints | `run 2026-09-27T04:48:55Z` | `run 2026-09-27T06:59:25Z` |
| scope | `run 2026-09-27T04:48:58Z` | `run 2026-09-27T06:59:29Z` |
| severity | `run 2026-09-27T04:49:00Z` | `run 2026-09-27T06:59:37Z` |
| suppression | `run 2026-09-27T04:49:02Z` | `run 2026-09-27T06:59:43Z` |
| upstream-docs | `run 2026-09-27T04:49:03Z` | `run 2026-09-27T06:59:45Z` |
| wiring-cost | `run 2026-09-27T04:49:10Z` | `run 2026-09-27T06:59:55Z` |
| wiring-severity | `run 2026-09-27T04:49:23Z` | `run 2026-09-27T07:00:30Z` |
| inputs | `run 2026-09-27T04:54:35Z` | `run 2026-09-27T07:00:42Z` |

I checked every `diff` hunk. Apart from the `I-policy` line in `r30-inputs.log`, each difference falls into one of these classes:
- line 1: the run timestamp;
- line 2: `CARGO_HOME` (`/tmp/cargo-s20-R30-r2` versus mine);
- cargo's `Finished … in N s` durations;
- `wall-clock:` values;
- lefthook `done in` and per-job durations;
- the order of lines from parallel jobs, for example `` `inherits` (lib) `` swapping with `` `inherits` (lib test) ``, `(1 duplicate)` moving between those two lines, and `could not compile` swapping with `build failed, waiting`.

After I dropped the `wall-clock` numbers, all of the following were identical between each fresh log and its committed log, across all seven evidence logs:
- every `== case` header;
- every `exit=N (expected N) PASS` line;
- every `units re-checked:` count;
- every summary line;
- the upstream blob and line lines.

The toolchain identities resolved identically in the fresh and committed logs: cargo/rustc 1.96.0 (`30a34c682`/`ac68faa20`), 1.97.1 (`c980f4866`/`8bab26f4f`) and 1.98.1 (`797e8a9bc`/`48a229cea`).

## Figures and inputs re-derived at source

- **Timing figures match the committed log.** Every timing figure quoted in the prose equals the committed `r30-wiring-cost.log`:

  | Case | Log line | Committed value |
  |---|---|---|
  | `H2a` (cold) | `:35` | 5.53 s |
  | `H2b` (warm no-op) | `:42` | 0.24 s |
  | `H2c` (warm no-op) | `:49` | 0.12 s |
  | `H2d` (after an edit) | `:61` | 0.44 s |
  | `H2e` (after an edit) | `:70` | 0.25 s |
  | `H2f` (after an edit) | `:82` | 0.48 s |
  | `H3e` (hook commit) | `:168` | 0.50 s |
  | `H3f` (hook commit) | `:184` | 0.26 s |
  | lefthook summaries | `:165`, `:181` | `done in 0.11 seconds`, `done in 0.20 seconds` |

  The r2 log headers also match the prose: the first is `04:48:55Z` in `r30-lints.log`, the last is `04:49:23Z` in `r30-wiring-severity.log`, and `CARGO_HOME=/tmp/cargo-s20-R30-r2` appears on line 2 of the five logs named.
- **My fresh timings are slower, which I attribute to host load.** Under the load average of about 250:

  | Case | Fresh value |
  |---|---|
  | `H2a` (cold) | 11.36 s |
  | `H2b`–`H2f` | 0.17–0.49 s |
  | `H3a`–`H3f` | 0.56–2.41 s |

  So the revision note's "every one stays sub-second warm" did not hold for hook commits on this overloaded host. The quoted figures are explicitly "this run's only", and gap 10 already records that no run-to-run distribution was measured. My data supports that gap and does not contradict any quoted figure. This is an observation, not a finding.
- **Input hashes match the inputs table.** Each hash below equals the table value:

  | File | sha256 prefix | Other check |
  |---|---|---|
  | `raw/muse.md` | `7661d2e3…` | 301 lines, matches the table |
  | `raw/opus.md` | `bbda3eff…` | 1130 lines, matches the table |
  | `inputs/parameters.json` | `15e7e98e…` | — |
  | `inputs/prerequisites.json` | `63a5620c…` | — |
  | R11 `DECISION.md` | `410e88e5…` | — |
  | R11 `acceptance.json` | `774f7649…` | — |
- **Prompt re-freeze confirmed.** `inputs/prompt.md` and the live `research/topics/30-type-check-gate/prompts/type-check-gate.prompt.md` both hash to `2c83ee19a44b571265d1ab29db7470ed90eaad4f704a9b036ed9badbf85250de`, and `I-prompt` PASSes on rerun. The difference from rev1's `a883b22d…` is expected, and I did not count it against the decision.
- **Upstream count confirmed.** `r30-upstream-docs.sh` has 6 `show` calls carrying 22 patterns, which matches "22 patterns in 6 files". Cargo 1.97's stabilisation line is at `CHANGELOG.md:399`, as cited.

## Not verified by this seat

- The figure "6.69 s in the empirical auditor's rerun" cites `review/audit-claude.md`, which this seat may not read. It is not load-bearing.
- The "three passes, 5.53–6.69 s" wording in gap 10 depends on that same citation.
