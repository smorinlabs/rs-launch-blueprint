actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 6ee8ad17642a847856766e914b45eac8727525f64a9f6f7159f6e1e7be97a6d9
verdict: approve
unresolved-findings: none

# R80 health-probe-endpoints — judgment audit of revision 5

Audited 2026-09-27 by a fresh judgment-auditor context. This context produced
none of R80's raw reports and did not synthesize any revision. The target is
`review/DECISION.md` revision 5. Before any other read, `shasum -a 256` gave
`6ee8ad17642a847856766e914b45eac8727525f64a9f6f7159f6e1e7be97a6d9`, which
equals the expected digest.

**Scope.** This audit judges reasoning and fidelity. It reran no evidence script;
the separate empirical audit does that. Every command below was read-only, ran
from the repository root, and used `/usr/bin/grep`, `shasum` and `python3`.

**Inputs read.**
- `review/DECISION.md`, in full.
- `inputs/prompt.md`, `inputs/prerequisites.json` and `inputs/parameters.json`.
- `research/RUNBOOK.md` section 5, the auditor contract.
- `raw/muse.md` and `raw/opus.md`, by heading scan and targeted lines.
- `operations/muse.json` and `manifest.json`.
- The live `docs/port/PARAMETERS.md` and `docs/port/OWNER-ACCEPTANCES.md`.
- `research/topics/69-web-framework-stack/DECISION.md`, the prerequisite.
- R69 revision 10's run `DECISION.md`, at its line 1791.
- R22's accepted revision-1 bytes, located by sha256.
- The `review/evidence/` logs, diffs, snapshots and `check-standard-r4.sh`.

**Disclosure.** One command ran `head -1` on `review/R80-r4-snapshot.md` and
hashed that file. The purpose was to confirm check `V1`'s pin. The only line
read is the H1, which the decision itself quotes. No other snapshot and no
`review/audit-*.md` file was opened.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | The six check counts sum to 113 (28+13+9+42+7+14), and the log totals match every table row. `OVERRIDE (OV-05)` occurs 11 times and the bare string `OV-04` occurs 11 times; both equal the prose. The form `OVERRIDE (OV-04` occurs 0 times. The rerun-diff sizes match the prose. `check-probe.rerun.diff` has 8 changed lines and `check-standard-r2.rerun.diff` has 4; all of them are `Finished`/`finished in` timings. The diffs for offline, r3, r4 and live-snapshots are 0 bytes, and `check-live.archive.assertions.diff` is 96 bytes. The revision-5 note agrees with the Empirical-check prose on what was re-recorded: the r2, r3 and r4 logs plus `shellcheck`. |
| JF-2 prompt questions and constraints | pass | All six questions are answered. HIGH shared function: `run_diagnostics` in `crates/core`, infallible, three-state. HIGH liveness info and crates: `version`, `os` and `arch`; `built`, `vergen`, `shadow-rs` and `git-version` are each excluded with a stated ground. HIGH cross-repo principles: the agreement-level table, the py precedent, and ts at 0 matches. MEDIUM extra crates: zero. MEDIUM structured types: `serde`-derived, with the R71 hand-off. LOW precedent: the census plus kubert and Apollo Router. The constraints are honored: F308 is applied, not re-derived; edition 2024; macOS-only execution is stated honestly; gate 1 is recorded as inapplicable under Q7.B. The three-bin landscape and the maintenance-state rubric live in `raw/opus.md` `### Landscape` and its per-member H5 fields, not in the decision. RUNBOOK §5's decision H2 contract does not require the decision to repeat them. |
| JF-3 `## Engines` fidelity | pass | The Muse + Opus engine set matches `manifest.json`. That file records one migration event, `codex`→`muse` at 2026-09-21T23:06:21Z. `operations/muse.json` is still `submitting` with no `raw_sha256`, as the decision states. `raw/muse.md` hashes to `395c1426…` and `raw/opus.md` to `dd3bdeae…`, both as cited. Muse quotes were spot-checked verbatim: "No `CONFLICT:` lines — the recommendation fits all consumed values." is at `raw/muse.md:235`; the `RUSTC_VERSION` concession is at `:11`; "explicitly asks" is at `:59`; "passes all six fitness gates" is at `:63`; "spawn_blocking only if a check blocks" is at `:29`. All nine disagreements are adjudicated with evidence. The eight corrections to `raw/opus.md` are stated with their checks. |
| JF-4 load-bearing claims traced | pass | Apollo's comment "It's hard to get k8s to parse payloads" is present in `evidence/snapshots/apollo-healthcheck.rs`. kubert's source is snapshotted in `evidence/snapshots/kubert-admin.rs`. The `check-offline.log` lines for `O6`, `O12`, `O15`, `O22`, `O27` and `O28` state the claims the prose relies on. R69 revision 10 line 1791 contains `web = ["dep:rs-launch-blueprint-web"]`, which supports the facade→web cycle argument. R22 revision 1's accepted bytes put `rs_launch_blueprint::VERSION` behind the web health response at line 17. Its AC3 is at line 112 and its `re-verify:` line naming R02's multi-crate outcome is at line 387. |
| JF-5 couplings | pass | Each owned choice is handed to its owner without being decided. The VERSION package goes to R22/R02 as options (a) and (b), undecided. The 503 carrier goes to R70 as three options. The schema derive goes to R71 under the no-derive-in-core constraint. The pre-drain pause goes to R77 as a requirement, with "needs an owner" if R77 declines it. Middleware order and `request-id` coverage go to R75. The probe client goes to R51, where this item states only that `/healthz` is `HEAD`-safe. `/metrics` goes to R79. The `doctor` exit code goes to R67's append-only catalog, and no code is assigned. |
| JF-6 `assumes` lines byte-identical to the live registry | pass | A table parse of the working-tree `docs/port/PARAMETERS.md` found all seven `- assumes` values equal to column `value` character for character. The working tree differs from `HEAD` on one row only, `ci-job-structure`, which this item does not assume. |
| JF-7 prerequisite values | pass | `inputs/prerequisites.json` pins R69 at decision `d4507f5b…`. `research/topics/69-web-framework-stack/DECISION.md` hashes to that value and is revision 9. The `web-extra-surface` line carries the registry's revision-9 bytes, and the prose explains the use of revision 10's accepted paths without asking any value to change. The accepted revisions of R02 (`9e8f8e8c…`, row 71), R05 (`3ca4b81a…`, row 75), R03 (`610e3338…`, row 70) and R22 (`0e7ea78e…`, row 79) match `OWNER-ACCEPTANCES.md`. No conflict with R49's no-`build.rs` clause exists, because the recommendation adds no build script. |
| JF-8 evidence scripts and counts | pass | Every cited log exists beside its script. The final totals lines read 28/0/0, 13/0/0, 9/0/0 (×3), 42/0/0, 7/0/0 and 14/0/0. The repaired `V8` is falsifiable. `PIPE_Q` and `PIPE_Q2` escape the leading pipe; a grep status ≥2 or a non-numeric count fails the check; and a positive control built from a variable is logged as "count 1, grep status 0". The six scans log "0 (grep status 1)", and `check-standard-r4.log` contains no grep error line. `V1`'s pin holds: `R80-r4-snapshot.md` hashes to `f0320a3a…`. |
| JF-9 decision shape | pass | The H2s are `## Decision` (with `### Principles and implementation` and exactly one `re-verify:` line), `## Parameters`, `## Empirical check`, `## Engines` and `## Supersedes`. The one fenced `##` belongs to the conformance note. The decision has no `- owns` line, which matches the empty `owns` cell in the index. It raises no `CONFLICT:`, and the reason is stated. |
| JF-10 recommendation follows from evidence | pass | Liveness can never fail for a reason a restart cannot fix: the handler is stateless (`T1`, `T5`). Readiness combines the drain latch with the shared diagnostics, because the diagnostics half alone cannot reach 503 in a real environment (`O22`, `O27`) and only a latch can report draining (`T4`). The decision states honestly that the latch is inert without a pre-drain pause. The version hazard and its repair are executed (`A`, `B`). The recommendation adds zero crates (`C9`–`C11`). The one-function placement is forced by Cargo's cycle rule. |

## Non-blocking observations (no repair required for acceptance)

1. **`## Supersedes` has no revision-4 entry.** The section records revisions 3, 2
   and 1, but not revision 4, which revision 5 supersedes. RUNBOOK §5 requires
   `## Supersedes` only for a reversal, and no revision reversed the
   recommendation. Revision 4 is also preserved as `review/R80-r4-snapshot.md`
   and described in the revision-5 note. This is a history gap, not a contract
   breach. A later revision may add the entry for symmetry.
2. **Engines point 1 calls Muse's "No `CONFLICT:` lines" statement "wrong".** R49's
   `build-tool-output-shape` is not in the prompt's `- consumes:` line, and Muse
   assumed only the four fixed parameters. So Muse's sentence is literally true of
   the values Muse declared. The decision's substantive point stands: a `build.rs`
   contradicts a published registry value that binds the template. The exclusion
   of `built` is correctly labelled as on fit, not on a gate. The wording is
   stronger than necessary, and nothing in the decision's reasoning turns on it.
