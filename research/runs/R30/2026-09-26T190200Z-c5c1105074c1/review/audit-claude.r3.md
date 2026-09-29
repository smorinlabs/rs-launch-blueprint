actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5
verdict: approve
unresolved-findings: none

# R30 type-check-gate — empirical audit of DECISION.md revision 3

Auditor: a fresh Claude Opus context (`claude-opus-5-5`, CLI), seated under the
item's `empirical_auditor_overrides` entry (`R30 -> "claude"`). It is independent
of the synthesizer and of the judgment auditor, and it read no `review/audit-*.md`,
no `review/R30-r*-snapshot.md`, and no `research/topics/*/raw/` file. Date: 2026-09-27
(Pacific).

## Scope and verdict

This audit judges execution truth and evidence support only. The target hash was
verified first: `shasum -a 256 review/DECISION.md` printed
`163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5`, equal to the
expected revision-3 hash. All eight evidence scripts reran green. Every case
outcome and exit code in the fresh logs equals the committed logs. The only byte
differences are fields that change on every run. The one claim the controller
flagged, the withdrawn "hook < 0.6 s" and its replacement "0.49–0.69 s, under 1 s",
holds on this host at a far higher load. **Verdict: approve, no unresolved findings.**

## Environment of the rerun

- Host: macOS Darwin 25.4.0, arm64, 14 CPUs (`sysctl -n hw.ncpu` = 14).
- `CARGO_HOME=/tmp/cargo-s38-R30-emp`, `CARGO_TARGET_DIR=/tmp/cargo-s38-R30-emp-target`
  (the auditor's private set; each cargo script still pins its own target directory
  inside its `mktemp -d` workspace).
- Toolchains, re-derived: `cargo 1.98.1 (797e8a9bc 2026-08-05)`, `rustc 1.98.1
  (48a229cea 2026-09-01)`; `rustup which --toolchain 1.97.1 cargo` → `cargo 1.97.1
  (c980f4866 2026-06-30)`; `rustup which --toolchain 1.96.0 cargo` → `cargo 1.96.0
  (30a34c682 2026-05-25)`; `just 1.57.0`; `lefthook 2.1.14`. These match the
  decision's toolchain table.
- Host load, from `uptime`: 1-minute load 318.92 at the start of the audit, 375.62
  immediately before the seven-script pass, and 485.26 immediately after it
  (15-minute averages 63.08 and 101.17). This is 4–5 times the load of the
  synthesizer's pass (75.62 → 102.40) and higher than the revision-2 audit's
  "about 250" as quoted in the decision.

## Reruns

Working directory `research/runs/R30/2026-09-26T190200Z-c5c1105074c1/review/evidence/`.
The seven scripts ran once, sequentially, in the decision's order; then
`r30-inputs.sh` ran. Command for each: `bash r30-<name>.sh > /tmp/r30-r3-emp/r30-<name>.log 2>&1`.
Nothing under `evidence/` was written.

| Script | Exit | Fresh totals | Committed totals | `cmp` result |
|---|---|---|---|---|
| `r30-lints.sh` | 0 | 14 PASS, 0 FAIL, 0 SKIP; `# summary: failures=0` | 14 PASS | differ at line 1, char 33 |
| `r30-scope.sh` | 0 | 20 PASS, 0 FAIL, 0 SKIP; `failures=0` | 20 PASS | differ at line 1, char 33 |
| `r30-severity.sh` | 0 | 17 PASS, 0 FAIL, 0 SKIP; `failures=0` | 17 PASS | differ at line 1, char 36 |
| `r30-suppression.sh` | 0 | 16 PASS, 0 FAIL, 0 SKIP; `failures=0` | 16 PASS | differ at line 1, char 39 |
| `r30-upstream-docs.sh` | 0 | 6 files, 29 matched lines for the 22 patterns, `failures=0` | same | differ at line 1, char 41 (header only) |
| `r30-wiring-cost.sh` | 0 | 17 PASS, 0 FAIL; `failures=0` (the 3 "skip" matches are H3a's case text and lefthook's own skip output, not skipped cases) | 17 PASS | differ at line 1, char 39 |
| `r30-wiring-severity.sh` | 0 | 8 PASS, 0 FAIL, 0 SKIP; `failures=0` | 8 PASS | differ at line 1, char 43 |
| `r30-inputs.sh` | 0 | `# summary: PASS=43 FAIL=0 failures=0` | `PASS=43 FAIL=0` | differ at line 1, char 34 (header only) |

**Classification of every byte difference** (full `diff` inspected for all eight):

1. Line-1 run timestamps, for example `< # r30-inputs.sh  run 2026-09-27T07:32:12Z` versus
   `> # r30-inputs.sh  run 2026-09-27T08:29:05Z`.
2. Line-2 `CARGO_HOME`: `< # CARGO_HOME=/tmp/cargo-s34-R30-r3` versus
   `> # CARGO_HOME=/tmp/cargo-s38-R30-emp`. This is expected, because the auditor's
   environment differs.
3. Elapsed times in cargo's `Finished … in N.NNs` lines, lefthook's `(N.NN seconds)`
   lines, and the scripts' `wall-clock:` values.
4. The order of lines that cargo prints from parallel jobs, for example
   `error: could not compile \`facade\` (lib test)` and
   `warning: build failed, waiting for other jobs to finish...` swapping places, or
   which of `(lib)` / `(lib test)` receives the `(1 duplicate)` suffix.
5. `target dir size: 163M` versus `162M` in `r30-wiring-cost.log`.

A normalized comparison confirmed that nothing else differs. It kept only the `== `
case headers, `exit=` lines, `units re-checked` counts, found/missing lines, blob
lines, `HEAD subject` lines and summaries, with timings and timestamps stripped. The
result was identical for all eight logs, except that `r30-wiring-cost.log`'s
lefthook `summary: (done in …)` durations differ. In particular, every `units
re-checked` count is unchanged. These counts are the W3 fingerprint evidence (`W3b`
0 units, `W3d` 2 units) and the H2 incremental scope (`H2a` 29, `H2d` 5, `H2e` 2). Both
`HEAD subject` lines are unchanged: after `H3e` the subject is still `H2 edits`
(the commit was refused), and after `H3f` it is `readme note`. The upstream-docs
blob shas and line numbers are byte-identical, so no quoted upstream sentence has
drifted.

## Timing claims against this rerun

The decision's figures are the synthesizer's own pass, and the committed
`r30-wiring-cost.log` contains them exactly. For example,
`units re-checked: 29  wall-clock: 16.01 s` (H2a), H3e 0.69 s and H3f 0.49 s.
`r30-inputs.sh` (`I-fig-*`) re-confirms the match between prose and log. Fresh
values at a 1-minute load of 375–485:

| Case | Committed (load 75–102) | Fresh (load 375–485) |
|---|---|---|
| H2a cold | 16.01 s | 11.98 s |
| H2b / H2c warm no-op | 0.14 / 0.12 s | 0.31 / 0.21 s |
| H2d / H2e / H2f incremental | 0.29 / 0.22 / 0.49 s | 0.77 / 0.42 / 0.74 s |
| H3a–H3d hook cases | 0.15–0.69 s | 0.45–0.64 s |
| H3e refused commit / H3f accepted commit | 0.69 / 0.49 s | 0.89 / 0.65 s |

The following claims hold:
- "0.49–0.69 s wall-clock, under 1 s" is exactly the committed log's H3e and H3f
  values. On this host, at 4–5 times that load, the same two cases took 0.65–0.89 s,
  which is still under 1 s. Every H3 case is under 1 s in this rerun.
- The withdrawal of revision 2's "every hook commit stayed under 0.6 s" is warranted.
  The fresh H3e is 0.89 s.
- Gap 10 states a spread across passes of 5.53–16.01 s cold and 0.15–2.41 s for the
  hook cases. The fresh 11.98 s cold figure and the fresh 0.45–0.89 s hook figures
  both fall inside that stated spread. The disclosure that timings rise with
  contention and that no pass ran on an idle host is accurate.
- The D5 statement "warm cost rises with host contention" is borne out by the fresh
  warm and incremental figures, which run roughly 1.5–3 times the committed ones.
  The hook-tier resolution therefore rests, as the decision says, on the order of
  magnitude and on criterion 8's `ubuntu-latest` re-verify trigger at 2 s. It does
  not rest on any single figure.

## Figures and inputs re-derived at source

- `inputs/prompt.md` and the live `research/topics/30-type-check-gate/prompts/type-check-gate.prompt.md`
  both hash to `2c83ee19…50de`.
- `inputs/EXECUTION.json` and the live `research/EXECUTION.json` both hash to
  `acdcbfff…f137`. `git show HEAD:research/EXECUTION.json | shasum -a 256` gives
  `ac4561fe28cc219a…2f2b`, as gap 11 states. That committed file has no
  `empirical_auditor_overrides` key at all, which is consistent with "a working-tree
  edit … not yet committed".
- The live policy has 50 `empirical_auditor_overrides` entries, every value `"claude"`,
  with `R30 -> "claude"`. `engine_overrides.R30` and `items.R30.engines` are both
  `["muse", "opus"]`.
- `manifest.json` has `required_engines` `["codex", "opus"]`, an
  `input_hashes.prompt` beginning `a883b22d`, and `operations` `{}`. This matches
  `I-manifest-dispatch` and gap 8.
- `raw/muse.md` is 301 lines, hash `7661d2e3…4665`. `raw/opus.md` is 1130 lines,
  hash `bbda3eff…40cc`. `inputs/parameters.json` hashes to `15e7e98e…231cd`, and
  `inputs/prerequisites.json` to `63a5620c…64b8`. R11 `DECISION.md` hashes to
  `410e88e5…418c`, and R11 `acceptance.json` to `774f7649…eac1`. All of these match
  the decision's input table.
- RUNBOOK `:73-76` names Q17.A (2026-09-27) and lists R30 in the wave. RUNBOOK
  `:98-104` defines `empirical_auditor_overrides` as the decision paraphrases it.
- R42 `DECISION.md:26` contains "The `channel` **value** is R27's through F103/F190
  and is not set here". R27's prompt line 14 contains "The file's `channel` and
  `components` are decided here (F103)". These support the JF-5 re-routing.
- `inputs/PARAMETERS.md:14` contains the verbatim R42 text quoted under D6.
- `inputs/prompt.md:25` is `- engines: muse, opus`. `:74` carries the Muse
  substitution sentence.
- Load-bearing D1 facts in the fresh `r30-severity.log`:
  - `W1 1.96.0 CARGO_BUILD_WARNINGS=deny` exits 0; the variable is inert on the floor.
  - `W1 1.97.1` exits 101.
  - `W3b` re-checks 0 units and exits 101.
  - `W3d` re-checks 2 units and exits 101.

## Unverifiable from here (recorded, not findings)

- The synthesizer's `uptime` values (75.62 before, 102.40 after) are historical and
  cannot be re-observed. Nothing in the logs contradicts them.
- The revision-2 audit's figures quoted in the decision (about 250 load, 0.56–2.41 s,
  11.36 s) were not checked, because that audit is outside this auditor's read set.
  They are not load-bearing for any claim this audit verifies.
- Opus's dependency-bearing timings (`opus.md:293`) were not rerun. The decision
  already records this as gap 1.
