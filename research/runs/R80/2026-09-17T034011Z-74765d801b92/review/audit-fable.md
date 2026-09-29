actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8
verdict: reject
unresolved-findings:
1. JF-2/JF-3/JF-9 — `## Engines` describes a codex+opus run that no longer exists; the Muse leg and its material disagreements are unrepresented.
2. JF-5/JF-7 — R22 is cited as open with no decision; R22 revision 1 is owner-accepted, and its accessor placement is not reachable from `crates/web` under R69 revision 10.
3. JF-1/JF-8 — three miscounts in `## Empirical check`.
4. JF-7 (drift, low) — R55 and R57 are described as unpublished; both are now published.

# R80 health-probe-endpoints — judgment audit (fable), decision revision 3

Scope: the reasoning and fidelity of `review/DECISION.md` revision 3, judged
against the current registry, prompt, manifest and prerequisites on 2026-09-26.
The hash was verified first:
`shasum -a 256` → `184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`,
which equals the expected value. The scripts were not rerun here; that is the
empirical audit's job. No `review/audit-*.md` file of any seat and no
`R80-r*-snapshot.md` file was read.

## Check results

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (low) | Three counts in `## Empirical check` contradict the decision's own text or its logs. See finding 3. The design itself is consistent: alternative C, the latch, the `spawn_blocking` bridge, the core placement and the R5.17 redaction are stated the same way in `## Decision`, the migration table and `## Engines`. |
| JF-2 prompt questions and constraints | **fail** | All six questions are answered: the shared function and its signature; the liveness fields with `built`/`vergen`/`env!` weighed; the cross-repo agreement table; zero added crates for `/readyz`; `serde`-typed bodies; and the probe-crate census `L8` plus kubert and Apollo Router. The failure is one constraint. The current prompt (`inputs/prompt.md` equals `research/topics/80-health-probe-endpoints/prompts/health-probe-endpoints.prompt.md`) now reads `- engines: muse, opus` and says *"its mirrored `- engines:` line is authoritative"*. The decision synthesizes against `codex, opus`. See finding 1. |
| JF-3 `## Engines` fidelity | **fail** | Opus is represented faithfully. The decision corrects eight of the report's claims, and I confirmed correction 1 at source: `raw/opus.md:201` reads *"there is no test in that file for the 503 branch"*, while `check-offline.log` `PASS O22` shows that `test_readyz_failure_is_a_problem_with_diagnostics` exists. Muse is not represented at all, and its report disagrees on five material points. See finding 1. |
| JF-4 load-bearing claims trace | **pass** | Spot-checked at source: `docs/port/COMMONALITY.md:332-333` (F328/F329, `DIVERGENT`, owner R80); the R69 revision-10 H1 and `- owns web-extra-surface` at line 1791 (`web = ["dep:rs-launch-bluepri…` on the root package); the W2-REST heading at `docs/port/OWNER-REVIEW.md:187`; W1-CODEX3 at `docs/planning/p02/owner-decisions.md:488`. The rest-standards blob `71bd813c…` has R7.1 at line 1259, R5.17 at 1120, R5.13 at 1049, R9.1 at 1435, R11.7 at 1752, R2.6 at 499 and R4.10 at 846, all matching the rule table. The py citations resolve to log lines `PASS O20`, `O22` and `O27`. |
| JF-5 couplings hand over without deciding | **fail** | The couplings to R70, R51, R79, R77, R75 and R71 are stated as requirements and decide nothing for those items. That part is good. The R22 coupling rests on a false premise ("open … holds no `DECISION.md`"), and it misses a real placement tension with R22's accepted text. See finding 2. |
| JF-6 `assumes` lines byte-identical | **pass** | I parsed the table cells of `docs/port/PARAMETERS.md` and compared them exactly. All 7 of 7 `- assumes` values are EXACT: `rust-edition`, `msrv-policy`, `target-os-matrix`, `license`, `build-tool-output-shape`, `http-transport-injection-seam` and `web-extra-surface`. The registry still carries R69 revision 9's `web-extra-surface`, so the decision's publication-lag note remains accurate. The working-tree change to `PARAMETERS.md` touches only the `ci-job-structure` row. There is no `- owns` line, and none is owed, because the R80 index row shows `—`. |
| JF-7 no conflict with accepted or published prerequisite values | **fail** | The registered prerequisite is current: `inputs/prerequisites.json` pins R69 at decision `d4507f5b…` and acceptance `48a7dce8…`, and both equal the published `research/topics/69-web-framework-stack/` files. The acceptance rows for R02 (revision 2), R03 (revision 1) and R05 (revision 3) match the decision's citations. The failures are drift. R22 is accepted (finding 2). R55 and R57 are published (finding 4). |
| JF-8 evidence scripts exist and counts match | **fail** (low) | All five scripts and their logs exist. The totals match the prose: offline 28/0/0, probe 13/0/0, live 9/0/0, standard-r2 42/0/0 and standard-r3 7/0/0. `check-offline.r2-rerun.log` shows 27/1, and its single failure is `O25`. `check-standard-r2.r3-rerun.log` shows 40/2, and its failures are exactly `C2` and `C4`. The rerun assertion diffs are 0 bytes, and `snapshots/` holds 92 files, as claimed. Three prose counts are wrong. See finding 3. |
| JF-9 decision shape follows the contract | **fail** | The H2 sections outside fences are Decision, Parameters, Empirical check, Engines and Supersedes; the `## Conformance note` at line 600 sits inside a fence. There is exactly one `re-verify:` line, and `### Principles and implementation` sits under `## Decision`. Using `## Supersedes` for pre-audit revisions follows the programme's practice under W2-REST, so I do not raise it. The failure is RUNBOOK §5, which requires `## Engines` to cover *"all reports … disagreements, and the evidence that resolved each"*. See finding 1. |
| JF-10 recommendation follows from the evidence | **pass** | `probe-contract/v1` follows from the evidence as assembled. The Kubernetes semantics (`L5`) force a dependency-free liveness probe and a conditional readiness probe. R02 revision 2 forces the `crates/core` placement. R05 revision 3 forces the `spawn_blocking` bridge. R49's no-`build.rs` clause (`O6`, `L6`) excludes `built`, `vergen` and `shadow-rs` on fit. The uptime refusal is argued from AC2 and R33. The Muse alternative (finding 1) is already answered by this evidence, so the repair is to represent and adjudicate it, not to research again. |

## Findings

### 1. `## Engines` describes a superseded engine set; the Muse leg is unrepresented (JF-2, JF-3, JF-9) — blocking

**Failed claim** (`## Engines`, lines 1129–1136): *"**codex** — **absent.** The
Focused tier's Codex research leg was **deferred by the controller under owner
ruling W1-CODEX3** … The run's `manifest.json` still lists `required_engines:
["codex", "opus"]` … **This is therefore a single-engine synthesis, and there is
no second engine to disagree with.**"*

**Evidence.**
- `manifest.json` records a migration event at 2026-09-21T23:06:21Z:
  `"from": "codex"`, `"to": "muse"`, reason *"muse bulk substitution (owner
  decision Q5.A 2026-09-21)"*. The same manifest now reads
  `"required_engines": ["muse", "opus"]` with `"state": "partial"`.
- RUNBOOK §2 lists R80 in the Muse bulk set. It also says that Q9.B retired Codex
  from P02.
- The current prompt reads `- engines: muse, opus` and says the line is
  authoritative.
- `raw/muse.md` exists on disk: sha256
  `395c1426cd8db1e2d46588dcd364caac86a0beca6ca3119d5b7a56333672b012`, retrieval
  date 2026-09-25. The file is untracked, and `operations/muse.json` is still in
  state `submitting` with no `raw_sha256`. The report is therefore present but
  not yet collected or registered.
- The Muse report disagrees with the decision on five material points, and the
  decision adjudicates none of them:
  1. **Stack.** Muse's `### Recommendation` selects `built` 0.8.1 as a
     build-dependency with a `build.rs`. The decision excludes `built` on fit
     under R49's registered *"no build.rs and no build-orchestration crate"*.
     Muse raises no `CONFLICT:` line even though it needs that value changed.
  2. **Liveness fields.** Muse's `HealthzBody` carries `rustc_version`,
     `git_sha` and `uptime_seconds`. The decision reports
     `{status, version, os, arch}` and declines uptime.
  3. **Check status.** Muse's `Check { ok: bool }` has two states. The decision
     uses the three-state `CheckStatus { Ok, Warn, Error }`, which AC4 depends
     on: warnings must not remove traffic.
  4. **Lifecycle.** Muse has no readiness latch and no drain state; it proposes
     alternative A alone. The decision selects alternative C.
  5. **Gates.** Muse states that `built` *"passes all six fitness gates"* and
     answers gate 1 per candidate. The decision records gate 1 as
     `inapplicable` under Q7.B.

**Repair.**
1. The controller collects and registers the Muse operation.
2. A revision lists Muse in `## Engines` with its digest.
3. That revision replaces the Codex paragraph with the Q5.A/Q9.B substitution.
4. It adjudicates each of the five disagreements with evidence the decision
   already holds: `O6`/`L6` and R22's accepted "no `build.rs`" for points 1 and
   2; AC2, R33 and the uptime paragraph for point 2; AC4/`T3` for point 3; the
   alternative-C argument and `T4`/`T5` for point 4; and `O26` for point 5.
5. It records which Muse claims it carries and which it corrects.

The recommendation need not move.

### 2. R22 is cited as open; it is accepted, and its accessor placement conflicts with R80's design (JF-5, JF-7) — blocking

**Failed claim** (lines 450–457): *"**The accessor's mechanism is R22's**
(`runtime-version-accessor`, open; `research/runs/R22/2026-09-17T020715Z-d93731e7353c/review/`
holds no `DECISION.md`). … the accessor is evaluated in `crates/core` — or in a
package that inherits `[workspace.package] version` — never at the web member's
own call site. R22's own MEDIUM question asks for exactly that, so this is a
hand-off with a stated requirement, not a conflict."* The same premise appears at
line 91 (*"a version accessor defined once in `crates/core` (the mechanism is
R22's)"*) and in the `re-verify:` line (*"when R22 publishes the version
accessor, which must be core-defined"*).

**Evidence.**
- `docs/port/OWNER-ACCEPTANCES.md:79` accepts R22 revision 1 on 2026-09-18 with
  sha256 `0e7ea78e64f6…`.
- `docs/planning/p02/owner-decisions.md:516` records W1-R22 option A.
- Commit `ffbd47b4` (2026-09-18 15:29 PT) holds exactly that digest, three hours
  before R80 revision 3 (`53b13f45`, 18:35 PT).
- R22 revision 1, lines 13–26, places `pub const VERSION: &str =
  env!("CARGO_PKG_VERSION");` in `src/lib.rs` of the single `[lib]`
  `rs_launch_blueprint`. It states that *"the optional web surface's
  health/status response"* reads `rs_launch_blueprint::VERSION`, and its AC3
  requires *"one value, one symbol"*.
- R69 revision 10 (line 1791, accepted and unpublished, and the revision this
  decision designs against) declares `web = ["dep:rs-launch-blueprint-web"]` on
  the root package. The facade therefore depends on `crates/web`, so
  `crates/web` cannot import `rs_launch_blueprint::VERSION` without a dependency
  cycle.
- R22 names one package for the accessor and R80 names another, and one of them
  must yield.
- R22 revision 1's `re-verify:` line (line 387) already names *"R02 selecting a
  multi-crate workspace"* as its trigger. R02 revision 2's acceptance (four
  packages, `OWNER-ACCEPTANCES.md:71`) has fired that trigger.

**Repair.**
1. Cite R22's accepted revision (`0e7ea78e…`) in place of "open".
2. State that R02 revision 2 has fired R22's own re-verify trigger.
3. Hand R22 and R02 the placement question as a coupling, without deciding it:
   - Option (a): the constant moves to `crates/core`, and the facade re-exports
     it.
   - Option (b): the members inherit `[workspace.package] version`, which
     satisfies "one value", as check `B` shows, but not R22's "one symbol".
4. Update the `re-verify:` clause to match.

This is not a `CONFLICT:` line, because R22 owns no registry parameter.

### 3. Three miscounts in `## Empirical check` (JF-1, JF-8) — low

- **Line 1083–1084:** *"The three `*.archive.assertions.diff` files — every
  `PASS`/`FAIL`/`SKIP` line and every totals line of all three scripts — are **0
  bytes**."* In fact `check-live.archive.assertions.diff` is 96 bytes; it holds
  the one `mode: fetch`/`mode: snapshots` banner line that the same paragraph
  correctly describes three sentences earlier. The offline and probe diffs are
  0 bytes.
- **Line 1022:** *"`OVERRIDE (OV-05)` appears 10, its own H4 included."* In fact
  `check-standard-r3.log` `PASS R2` reports *"11 times, including its own H4
  heading"*, and a count of the file gives 11.
- **Line 884:** *"Revisions 1 and 2's five scripts are unchanged."* In fact
  revision 1 has three scripts and revision 2 has one, which makes four.

**Repair:** make the three sentences say "two of the three … are 0 bytes; the
live diff differs only on the mode banner", "11" and "four".

### 4. R55 and R57 are described as unpublished; both are published (JF-7 drift) — low

**Failed claim** (lines 342–344 and 1191–1193): R55 is *"accepted at revision 3,
unpublished"* and R57 is *"accepted at revision 2, unpublished"*.

**Evidence.** `research/topics/55-config-error-tolerance/DECISION.md` (revision 3)
and `research/topics/57-xdg-directory-set/DECISION.md` (revision 2) now exist, and
`research/CLAUDE.md` marks both items `resolved`. The substance holds: the
published texts contain 0 matches each for
`run_diagnostics|doctor|readyz|CheckStatus`, so the check list is still unowned.

**Repair:** change the status wording to "published". No other change is needed.

## Observation (not a finding)

The ledger entry *"R70 REVISION 2 LANDED, 2026-09-18"* records that R70's
candidate `errors` member became R5.15's array of `{pointer, code, detail}`. The
decision's option "the report folded into the existing `errors` map" (line 710)
is therefore phrased against R70's older draft. R70 is not accepted, and the
decision correctly leaves the choice to R70. A future revision should phrase
this option generically.
