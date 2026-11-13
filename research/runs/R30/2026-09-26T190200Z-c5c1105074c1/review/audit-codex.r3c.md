# R30 revision 3 empirical re-run addendum r3c — Codex

SUPERSEDES review/audit-codex.r3b.md (blocked on B-1/B-2, evidence sufficiency only, no contradiction observed). r3c runs the two wiring scripts, `r30-wiring-cost.sh` and `r30-wiring-severity.sh`, unmodified under the /tmp-fixture-git ruling (S1 ruling, ledger 2026-09-28: fixture git repositories created by evidence scripts under /tmp scratch are permitted; the ban on git writes to the working checkout stands). Same DECISION revision; the decision is cited, not re-decided.

actor: Codex
model: claude-opus-5-5
family: openai
decision-sha256: 163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve-with-observations
unresolved-findings: none

Seat disclosure: the executing model was `claude-opus-5-5` (Anthropic), dispatched into the Codex seat. `actor` and `family` carry the dispatched seat labels unchanged; `model` records the model that actually ran. The controller decides whether this seat record needs a §7.6 amendment or a re-dispatch.

## Re-run record

Pre-checks, in order: `review/DECISION.md` sha256 recomputed as `163ba833…6eb6cf5`, equal to the target; `review/audit-codex.r3b.md` sha256 prefix recomputed as `f3c0a9b677d3`, equal to the expected prefix, and read only. `research/EXECUTION.json` sha256 recomputed live on 2026-09-28 as `fd746cb8…5a3545c`, equal to the coordinator's point-in-time pin. The pin is cited point-in-time; drift would not be a finding (RUNBOOK §7.7).

Environment: `CARGO_HOME=/tmp/cargo-s85-r30` (private, coordinator-set), cargo/rustc 1.98.1, clippy 0.1.98, just 1.57.0, lefthook 2.1.14, git 2.50.1, Darwin arm64, 14 CPUs. The tool versions match the committed log header. Each script creates its own `mktemp -d` scratch root under `/tmp`, including its fixture git repository, and removes it on exit. After the runs, no `r30-wiring.*` scratch directory remained, and neither script nor any committed `review/evidence/*.log` was written.

Invocation, from `review/evidence/`, with no added flags:

```text
bash r30-wiring-cost.sh > /tmp/r30-r3c-wiring-cost.log 2>&1        # exit 0
bash r30-wiring-severity.sh > /tmp/r30-r3c-wiring-severity.log 2>&1 # exit 0
```

| Evidence script | Exit | Re-run log | Re-run totals | Committed totals | Outcome comparison with committed log | Comparison with DECISION |
|---|---|---|---|---|---|---|
| `r30-wiring-cost.sh` | 0 | `/tmp/r30-r3c-wiring-cost.log` | 17 PASS, 0 FAIL, `# summary: failures=0` (`:222`) | 17 PASS, 0 FAIL | every `== <case>` label and every `exit=` line identical, in the same order | confirms `:281` H1–H4 |
| `r30-wiring-severity.sh` | 0 | `/tmp/r30-r3c-wiring-severity.log` | 8 PASS, 0 FAIL, `# summary: failures=0` (`:97`) | 8 PASS, 0 FAIL | every `== <case>` label and every `exit=` line identical, in the same order | confirms `:282` V1–V3 |

Byte-level differences are drift only: run timestamps, `CARGO_HOME` (`/tmp/cargo-s34-R30-r3` in the committed log, `/tmp/cargo-s85-r30` here), wall-clock values, and the order in which parallel cargo units print their `generated 1 warning` / `could not compile` lines in V1a, V1c, and V2b. None of these changes an outcome.

### Key cases, `/tmp/r30-r3c-wiring-cost.log`, compared with `review/DECISION.md:281`

- **H1 identity of recipe, hook, and CI commands.** `H1a Justfile vs lefthook.yml` → `exit=0 (expected 0) PASS` (`:9`, `:12`). `H1b Justfile vs CI steps` → `exit=0 (expected 0) PASS` (`:14`, `:17`). `H1c the check detects drift (a hook job missing --all-targets)` → `exit=1 (expected 1) PASS` (`:19`, `:22`). The three places carry byte-identical cargo commands, and the identity check detects drift.
- **H2 measured cost.** `H2a cold: just typecheck (both configurations)` → `units re-checked: 29  wall-clock: 6.05 s`, `exit=0 (expected 0) PASS` (`:26`, `:35-36`). Warm no-op `H2b`/`H2c`: 0.09 s and 0.11 s (`:42`, `:49`). Incremental `H2d`–`H2f`: 0.27 s, 0.42 s, 0.30 s, with 5, 2, and 5 units re-checked, the same unit counts as the committed log (`:61`, `:70`, `:82`). All six H2 cases pass. Timing differences are drift, not contradiction; see OBS-1.
- **H3 real just recipe and real lefthook hook, including a refused commit.** `H3a` skips both jobs when nothing is staged, `exit=0` (`:87-95`). `H3b` runs both jobs green on a harmless staged change (`:97-108`). `H3c` staged `error[E0308]: mismatched types` in `crates/cli` → `exit=1 (expected 1) PASS` (`:110-131`). `H3d` staged E0308 behind the `web` feature: `✔️ typecheck (default features)` and `🥊 typecheck (all features)` → `exit=1 (expected 1) PASS` (`:133-151`).
  - `H3e the same through a real commit with the hook installed — commit refused` → `wall-clock: 0.53 s`, `exit=1 (expected 1) PASS`, then `HEAD subject after H3e (must still be the H2 commit): H2 edits` (`:153`, `:168-170`). The installed hook rejected the commit.
  - `H3f green again after restoring — commit accepted through the hook` → `wall-clock: 0.29 s`, `exit=0 (expected 0) PASS`, then `HEAD subject after H3f: readme note` (`:172`, `:184-186`).
- **H4 clippy after the gate and clippy's E0308.** `H4a` re-checks the four workspace members only (`units re-checked: 4`), `exit=0 (expected 0) PASS` (`:190-201`). `H4b` reports `error[E0308]: mismatched types` → `exit=101 (expected 101) PASS` (`:203-216`).

### Key cases, `/tmp/r30-r3c-wiring-severity.log`, compared with `review/DECISION.md:282`

- **V1 a lint warning fails the real wiring while plain `cargo check` stays green.**
  - `V1a plain cargo check — lax, exit 0` shows `warning: unused variable: \`unused\`` → `exit=0 (expected 0) PASS` (`:8-14`).
  - `V1b just typecheck — the line-prefix variable reaches cargo, recipe fails` shows `error: warnings are denied by \`build.warnings\` configuration` and `error: recipe \`typecheck\` failed on line 4 with exit code 101` → `exit=101 (expected 101) PASS` (`:16-24`).
  - `V1c lefthook run pre-commit — the per-job env: key reaches cargo, hook fails` shows the same denial in both jobs, `🥊 typecheck (default features)` and `🥊 typecheck (all features)` → `exit=1 (expected 1) PASS` (`:26-42`).
  - `V1d`/`V1e` restored tree green through just and lefthook, both `exit=0 (expected 0) PASS` (`:44-54`).
- **V2 just stops at its first failing line; lefthook runs both jobs.** `V2a` shows only the default-configuration `unused_off` denial and `recipe \`typecheck\` failed on line 4` → `exit=101 (expected 101) PASS` (`:58-66`). `V2b` shows both the `unused_off` denial and the all-features `error[E0308]: mismatched types` → `exit=1 (expected 1) PASS` (`:68-83`).
- **V3 `--locked` at the hook refuses an un-updated lockfile.** Both jobs print `error: cannot update the lock file <ws>/Cargo.lock because --locked was passed to prevent this` → `exit=1 (expected 1) PASS` (`:87-95`).

## Findings

- **B-1: RESOLVED.** The r3b finding was that `review/DECISION.md:281` (H1 identity, H2 cost, H3 real hook including a refused commit, H4 clippy) could not be reproduced because the script's /tmp fixture git writes were then out of bounds. Under the S1 ruling, the unmodified script ran to `exit 0` with 17 PASS, 0 FAIL. Every case outcome equals the committed log. No case inverts: the hook still refuses the E0308 commit (H3e, HEAD unchanged) and accepts the restored one (H3f).
- **B-2: RESOLVED.** The r3b finding was that `review/DECISION.md:282` (V1 warning fails the real Justfile and lefthook commands, V3 hook rejects a stale lockfile) could not be reproduced for the same reason. Under the S1 ruling, the unmodified script ran to `exit 0` with 8 PASS, 0 FAIL. Every case outcome equals the committed log. The warning passes plain `cargo check` (V1a) and fails both `just typecheck` (V1b) and `lefthook run pre-commit` (V1c); the hook rejects the un-updated lockfile (V3).
- **OBS-1 (OBS): timing drift, not a contradiction.** The re-run H2a cold figure is 6.05 s against the 16.01 s quoted at `review/DECISION.md:193`, `:318`, and `:381`. The DECISION discloses the host-load dependence and a cross-pass cold range of 5.53–16.01 s at `:414`; 6.05 s falls inside that range. For the re-run hook commits, H3e 0.53 s falls inside the quoted 0.49–0.69 s range and H3f 0.29 s is below it; both are under the 1 s bound stated at `:381`. Warm no-op, 0.09–0.11 s, is slightly below the quoted 0.12–0.14 s. Every drift is toward lower cost, so it cannot move the F106 pre-commit-tier recommendation at `:124`. Per RUNBOOK §7.1 this is recorded, not rounded; no re-quote of timing figures is requested.
- **OBS-2 (OBS): parallel output ordering.** In the severity log, cargo's per-unit `generated 1 warning` and `could not compile` lines print in a different order than in the committed log for V1a, V1c, and V2b (`/tmp/r30-r3c-wiring-severity.log:12-13`, `:31-32`, `:73-74`, `:79-80`). V1a's summary line also names `--tests` on the `lib test` unit rather than on `lib`. This is nondeterministic job scheduling; exit codes and diagnostic content are unchanged.

## Verdict

approve-with-observations. Both wiring scripts, run unmodified with /tmp-only fixtures, reproduce the committed outcomes. They confirm the load-bearing claims at `review/DECISION.md:281` and `:282`. The STOP trigger did not fire: no case outcome changed and no load-bearing behavior inverted. B-1 and B-2 are resolved. No BLOCKING finding remains. OBS-1 and OBS-2 are observations only; nothing was fixed.
