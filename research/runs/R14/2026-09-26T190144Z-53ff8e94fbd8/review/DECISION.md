# 2026-09-26 — R14 — large-file-guard-strategy (bundle, Focused) — decision (revision 3)

**Revision note, revision 3.** This is fix round 2, against revision 2 (sha256 `9c7e39804f80396bad9affe77020c148957cc0fa4535438bb5fc6f702b4daf86`, preserved byte-identical at `review/R14-r2-snapshot.md`). Revision 3 was written by the R14 revision-3 repair worker (Opus seat), which applied only the repairs below. Both revision-2 audits rejected: the judgment audit (`review/audit-fable.r2.md`) with JF4-1, JF4-2 and JF2-1, and the empirical audit (`review/audit-claude.r2.md`) with EA-1. The empirical audit reproduced all 78 checks. No finding moves the recommendation, the 1 MiB value, the blob scope, the fail-closed bases or the hygiene placement, and revision 3 moves none of them.

| Finding | What the audit found | Disposition in revision 3 |
|---|---|---|
| **JF4-1** | the headroom sentence dropped the Opus leg's scope ("template-shaped", "growing generated"), so "2.08× over every legitimate file" contradicted the carried table (bat `syntaxes.bin` 1,012,454 B; cargo, typos, uv, ruff, bevy and zed above 1 MiB); the pointer named `### Sources` instead of `### Landscape` | **Fixed with the audit's wording (text only).** The threshold paragraph now names the seven template-shaped repositories, scopes the 2.08× claim to them and to growing generated files, calls the intentional assets the `large-file-ok` or LFS case, and points to `### Landscape` |
| **JF4-2** | the "one value" acceptance criterion cited `H3` and `R1`, which do not test it; the "one-file `grep` can prove" claim had no check behind it | **Fixed with the audit's first option.** The criterion now cites `check-large-files.sh:10` (`max=1048576`) and the grep result (2 lines in the script, 0 in `ci.hygiene-with-guard.yml`), run by this repair and quoted under `## Engines`; `H3` stays as evidence for the hook half only. The grep is not a committed harness check, so it and a range-mode 1048576/1048577 boundary case are added to the P03 proposal |
| **JF2-1** | the decision never said why no Codex report exists although the originally pinned prompt read `- engines: codex, opus` | **Fixed.** The actor paragraph now states that Muse replaced Codex under the `engine_overrides` pilot, on owner decision Q17.A |
| **EA-1** | the recorded inputs predated Q17.A, and `I1` still pinned the old prompt hash `2b501625…` | **Fixed within this directory.** The controller (S1) has re-frozen `inputs/`; this revision cites the re-frozen prompt hash `8ea107a4…` and Q17.A. `I1`'s `want` in `r14-rev1-inputs.sh` now reads `8ea107a4…` |

**Evidence moved in revision 3: three files.** `r14-rev1-inputs.sh` (the `I1` `want` line), `r14-rev1-inputs.log` (re-recorded) and `SHA256SUMS` (the two inputs lines). The re-recorded inputs log differs from revision 2's only in its `UTC now:` line and its `I1` hash; it still records 27 pass. The other five harnesses were rerun to `/tmp`: each output was byte-identical to its committed log except the `UTC now:` line, so those logs were not re-recorded. Total: 78 pass, 0 fail. `SHA256SUMS` verifies 14/14. The revision-2 note below is kept as written; its statement that no evidence was rerun held for revision 2 only.

**Revision note, revision 2.** This is fix round 1, against revision 1 (sha256 `ea3fb15b674185126831ecb03870b236da7c4829a0a1b170e2a7320b452570f5`, preserved byte-identical at `review/R14-r1-snapshot.md`). The revision-1 judgment audit (`review/audit-fable.md`) rejected it with findings JF-9, JF-1/JF-8 and JF-4/JF-8. The concurrent empirical audit (`review/audit-claude.md`) approved revision 1 (78 pass, 0 fail, `SHA256SUMS` 14/14); that approval binds revision 1 only, so revision 2 needs both audits afresh. No finding reopens the recommendation, the 1 MiB value, the blob scope, the fail-closed bases, the hygiene placement or any evidence file, and revision 2 moves none of them. **Three prose claims move**, all text edits inside this file.

| Finding | What the audit found | Disposition in revision 2 |
|---|---|---|
| **JF-9** | the `re-verify` line was bold and wrapped over four lines, so the packager's `re-verify:` rule found zero triggers and refused the decision | **Fixed with the audit's repair.** One unbolded single line starting at column 0, same trigger set, same wording |
| **JF-1 / JF-8** | the total "78 checks pass" contradicted the table rows summing to 77, because the pybody row said 4 while `r14-rev1-pybody.log` holds 5 PASS lines (`BODY` + `P1`–`P4`) | **Fixed by correcting the row.** The 78 total is right (both audits agree); the pybody row now reads 5 pass, naming `BODY` alongside `P1`–`P4`. Lines 141, 184, 226 and 248 of revision 1 already said 78 and are unchanged |
| **JF-4 / JF-8** | `H1`–`H10` were claimed under both shells, but `H8` and `H9` ran under macOS `/bin/sh` only (`r14-rev1-guard.sh:69`, `:80`) | **Fixed with the audit's first option (prose).** The claim now reads "`H1`–`H7b` and `H10` under both shells; `H8` and `H9` under macOS `/bin/sh` only". No `[dash]` runs were added, so no script or log moves |

Every `r14-rev1-*` script and log keeps revision 1's bytes and `SHA256SUMS` still verifies 14/14, so no evidence was rerun: no cited log line moves.

Actor `synth-r14-2026-09-26T190144Z-53ff8e94fbd8-r2` (revision 1 was written by `…-r1`): a fresh context that
produced neither raw report. Item kind `bundle`, effort tier `focused` (two
engines). Inputs read: `inputs/prompt.md` (sha256 `8ea107a4…`, `I1`),
`inputs/prerequisites.json` (R11 decision `410e88e5…`, `I2`), `raw/muse.md`,
`raw/opus.md`, `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md`,
`docs/port/DIVERGENCE-ANALYSIS.md`, the R11/R17/R81 decisions, and both source
repositories at their programme pins. **Engine set.** The run's original freeze
(prompt sha256 `2b501625…`) named `- engines: codex, opus`. Muse replaced
Codex under the `engine_overrides` pilot, on owner decision Q17.A
(2026-09-27, `research/RUNBOOK.md` §2), which postdates this run's 2026-09-26
start. The controller then re-froze the inputs: `inputs/prompt.md` is now
`8ea107a4…` (line 22 `- engines: muse, opus`), and `inputs/EXECUTION.json`
gives R14 `engines` and `engine_overrides.R14` both `["muse", "opus"]`,
matching the live `research/EXECUTION.json`. Nothing has been published for R14, so
there is no `## Supersedes`.

## Decision

**Status.** This decision is a **proposal validated in the implementation
phase** (owner ruling, 2026-09-10). `rs-launch-blueprint` has no CI tree and
no hook configuration today. P02 is research; P03 builds the template and its
CI proves or disproves what is recorded here. Nothing below has run on a
GitHub-hosted runner. A recommendation that does not survive implementation is
**revised against this recorded research**, not researched again from scratch.

**Recommendation — one stack: the named pattern `single-rule blob-size guard,
two tiers`.** A 46-line POSIX-`sh` script `scripts/check-large-files.sh`
fails any blob larger than **1048576 bytes** (comparison `>`) entering
history, unless `.gitattributes` marks its path **`large-file-ok`**. It runs
in two places: (1) at **pre-commit** in `--staged` mode through whichever
hook manager R37 selects, and (2) as a step of R11's always-run **`hygiene`**
job in `ci.yml`, in `--range BASE HEAD` mode over every commit of the change,
with `fetch-depth: 0` added to that job's checkout. No crate, no third-party
action, no dedicated workflow file. The template ships **no path exemption**;
intentional large files go to Git LFS or get a per-path `large-file-ok` line.
The reference script is committed as
`review/evidence/check-large-files.sh` (sha256 `3492598c…`, 46 lines); the
composed CI file as `review/evidence/ci.hygiene-with-guard.yml` (sha256
`aa37e31a…`, R11's fixture plus 7 lines, `W2a`).

**Ledger rows this decision settles: F043 and F172**
(`docs/port/COMMONALITY.md`, both `DIVERGENT`, both `Item: R14`; `I3`, `I4`).
F043 is the CI-tier guard row; F172 is the hook-tier guard row. Both
divergence sub-rows are `harmonize: yes` (`I5a`, `I5b`), so one threshold and
one exemption rule hold for all three repositories.

**No `BASELINE-REVIEW:` finding is raised by this decision.** F043 and F172
are `DIVERGENT` rows this item is appointed to decide, not inherited
baselines; both raw legs agree. One provenance correction to the F172
sub-row's note is flagged for the controller under `## Engines`
(Disagreement D6); the ledger is not edited here.

### Principles and implementation

**The shared requirement.** *A blob larger than a declared size cannot enter
the default branch's history by accident; an intentional one enters only
through a reviewable, declared exception; and the repository states the rule
once.* Source: ledger rows F043/F172, realized in py by
`.github/workflows/large-file-guard.yml` and the `large-files` hook at pin
`b08bccfb` (`I9a`–`I9d`), half-realized in ts (`I10a`–`I10c`).

| Principle | Agreement level | Essential behavior | Observable acceptance criterion |
|---|---|---|---|
| Early catch is cheap, late catch is certain | Capability | A hook-tier check rejects oversize staged blobs locally; a CI-tier check rejects oversize introduced blobs on the server. | A 2 MiB staged file fails the hook (`L1a`); the same file committed with `--no-verify` fails the CI range check (`L2`, `L3`). |
| One value, both tiers, all repos | Standard | Threshold, comparison and exemption are defined once and read by both tiers. | The byte value exists in exactly one file: `max=1048576` at `check-large-files.sh:10`, which both modes compare against (line 37); `grep -c 1048576` gives 2 lines in that script and 0 in `ci.hygiene-with-guard.yml`. The hook half enforces the limit at the boundary (`H3`); a range-mode boundary case is proposed for P03. |
| Intentional large files are declared | Policy | Exemption is a per-path `large-file-ok` attribute or LFS tracking, both visible in review. | A 2 MiB attribute-marked file passes with an `ALLOW:` line (`H6`); an LFS-tracked 2 MiB file passes as a pointer (`H8`). |
| Every introduced blob is gated | Policy | Both tiers measure blobs entering history — added, modified or type-changed, in any commit — never the final tree alone. | A blob added and deleted inside one change fails (`R1`); a modified file grown past the limit fails (`H5`, `R4`). |
| Unknown input fails closed | Policy | An empty, all-zero or unknown base, or a git error, never passes silently. | All-zero and empty bases check all history (`R3`, `R3e`); an unknown base is exit 2 (`R7`). |

**Architectural alternatives, compared before any value.** Hook tier only
(ts status quo) is bypassable by construction (`L2`) — rejected as
sufficient. CI tier only is certain but late: every accident costs a
push–CI–rewrite round-trip — rejected as sufficient. Hook + CI with
independent definitions is py's shape plus ts's drift risk — rejected; the
drift is the exact failure the LOW question describes. Hook + CI with one
script, blob scope, fail-closed — **selected** (`H1`–`R9`, `L1`–`L3`,
`M1a`–`M1d`). A forge push ruleset ("Restrict file size") rejects the push
itself but is available only for internal and private repositories on paid
plans (verified 2026-09-26 at `github/docs` pin `18945a31`,
`data/reusables/gated-features/repo-rules.md`), so it cannot serve this
public template — excluded as the mechanism, documented as an optional layer
for private adopters. GitHub's 100 MiB block alone is two orders of magnitude
above any threshold this principle needs — rejected as sufficient.

**Threshold: `> 1048576` bytes, both tiers, all three repos.** Both engines
agree on the value; the evidence for it is carried from the Opus leg's
committed-blob size profile (14 repositories, `### Landscape` in
`raw/opus.md`): the seven repositories the Opus leg classes as
template-shaped (tokio, axum, clap, ripgrep, prek, pydantic-core, crates.io)
have zero blobs over 512000 bytes, while legitimately growing generated files
reach 503922 bytes (zed `Cargo.lock`) and 449255 bytes (cargo
`CHANGELOG.md`), so a 512000-byte limit at blob scope would start failing
ordinary lockfile growth. 1048576 bytes gives at least 2.08× headroom over
every blob in those seven repositories and over every growing generated file
in the 14-repository profile. Intentional assets near or above the limit (bat
`syntaxes.bin` 1,012,454 B; cargo, typos, uv, ruff, bevy and zed above 1 MiB)
are the `large-file-ok` or LFS case, not headroom. The boundary is
pinned by execution: 1048576 passes, 1048577 fails, under both shells
(`H2`, `H3`). What it concedes, measured by the Opus leg and not re-run here:
sub-1-MiB release binaries copied out of `target/` pass it.

**Exemption: per-path `large-file-ok`, none shipped.** Py's `docs/assets/`
prefix holds **0 entries** at the pin (`I9e`) — it has never exempted
anything — and R81's accepted docs model names no assets subdirectory
(`I12`), so the prefix has no natural home in this template. A directory
prefix also cannot express "this one fixture is intentional" without moving
files. The attribute is declared in the diff, read by both tiers from the
same file, and needs no LFS special case because the committed blob of an
LFS-tracked file is a small pointer (`H6`, `H8`).

**Single source of truth (LOW question).** Independent per-tier tuning is not
acceptable: it is how the siblings' values diverged with no recorded joint
rationale. The threshold constant lives in the script; the exemption lives in
`.gitattributes`; neither call site carries a value. The hook entry needs
only "run a command at pre-commit" (`sh scripts/check-large-files.sh
--staged`), so R37 can select any manager without reopening R14.

**Placement (the engines' main disagreement, decided here).** The CI half is
a **step of `hygiene`**, not a dedicated workflow file. R11's accepted value
— the binding registry text, not either leg's reading — says "a check that
compiles nothing is a step of `hygiene`, or its own cheap job behind a path
gate only when that gate's key contains the whole input of every check in the
job" (`I7`), and it carves out secret-scanning as a separate workflow file by
name (`I7b`), which is why R17's dedicated file (`I13`) is not a transferable
precedent. The large-file guard compiles nothing and its input is every
changed path, so no detector key contains it: the slot rule fires. `hygiene`
runs on all three `ci.yml` events with no `needs:` edge (`I8a`, `W4a`,
`W4b`), so coverage equals a dedicated file's. The one cost is a separately
requireable check identity; R12 owns required-check aggregation and `hygiene`
is itself a required-check surface. The composed file passes `actionlint`
with zero diagnostics (`W5`).

**Migration implications (P03 builds these; none exist yet).** Add
`scripts/check-large-files.sh` (the reference, executable bit set); add a
commented `large-file-ok` example to `.gitattributes` (no active entry); add
one pre-commit entry to R37's hook configuration; add `fetch-depth: 0` to
`hygiene`'s checkout plus the "Large-file guard (R14)" step (the 7 lines in
`ci.hygiene-with-guard.yml`); add one paragraph to the contributor docs (the
1 MiB rule, LFS, `large-file-ok`). Do **not** create
`.github/workflows/large-file-guard.yml`; do not add a `macos-latest` CI leg.

**Follow-on for the source repositories, with rationale (not this
template).** Py keeps 1 MiB and fixes four executed defects in
`large-file-guard.yml` (final-tree-only `P1`, fail-open base `P2`,
added-only `P3`, word-split names `P4`) and drops the dead `docs/assets/`
prefix. Ts adds the CI tier and moves to blob scope at 1 MiB, since its
current hook checks modified files too and will start rejecting ordinary
lockfile growth.

**Confidence: medium-high.** High on the two-tier shape, blob scope,
fail-closed bases and the hygiene placement (registry text plus 78 executed
checks). Medium on the 1 MiB value, which rests on a 14-repository sample
carried from one leg.

re-verify: when R37 selects the hook manager; when R11's hygiene job or R12's required-check set changes; when the template's Cargo.lock or CHANGELOG.md passes 700000 bytes; if GitHub makes push rulesets available to public repositories; otherwise by 2027-03-26.

## Parameters

The prompt's `- owns:` line is empty, so this decision has no `owns` lines;
its `- consumes:` line is empty, so there is no consumed parameter. The four
`assumes` lines below are byte-identical to `docs/port/PARAMETERS.md`
(`I6`):

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

How each bears on the decision. **msrv-policy** is `inapplicable`: no Rust
code is added, so there is no `rust-version` to declare. **rust-edition** is
inert for the same reason. **license**: the script and workflow step are
template source under the repository's own `MIT OR Apache-2.0` expression;
fitness gate 1 is satisfied trivially, with no dependency to evaluate.
**target-os-matrix** governs the shell the script is written in: POSIX `sh`
with `git`, `awk`, `sed` and `mktemp` only, executed under macOS `/bin/sh`
(bash 3.2) and `/bin/dash` (Ubuntu's `/bin/sh`) (`H1`–`H7b` and `H10` under both shells; `H8` and `H9` under macOS `/bin/sh` only);
the `ubuntu-latest` and `macos-latest` hosted runs are proposed for P03.
Fitness gates 2, 3, 5 and 6 are `inapplicable` (no crate, no dependency tree,
no `unsafe`, no features or async runtime, no binary or compile-time cost);
gate 4 is satisfied as stated in this paragraph. No `CONFLICT:` lines: R14
places its step per R11's `ci-job-structure` without consuming that value,
and the `fetch-depth: 0` addition is a slot note to R11's owner, not a
parameter change.

## Empirical check

Host: macOS 15/26 arm64, `git version 2.50.1 (Apple Git-155)`,
`actionlint` 1.7.12, `shellcheck` 0.11.0, `lefthook` 2.1.14, `git-lfs` 3.8.0,
`/bin/sh` = bash 3.2.57, `/bin/dash` present. Working directory: the run's
`review/evidence/`. Every cited check is a committed script there; each log
records its UTC instant, host, command and exit code. 78 checks pass, 0 fail.

| Script | What it executes | Result |
|---|---|---|
| `r14-rev1-inputs.sh` | prompt/prerequisite hashes, ledger and divergence rows, registry values, R11 slot rule and fixture shape, py/ts pin reads, ADR and pre-commit provenance, R81/R17 records (`I1`–`I13`) | 27 pass (`r14-rev1-inputs.log`) |
| `r14-rev1-guard.sh` | reference-script matrix: boundary, spaced names, modified growth, attribute exemption, staged-vs-worktree, LFS, gitlink, unborn branch, add-then-delete, fail-closed bases, unknown base, usage, clean range (`H1`–`H10`, `R1`–`R9`) | 29 pass (`r14-rev1-guard.log`) |
| `r14-rev1-merge.sh` | add-then-delete blob unreachable before `merge --no-ff`, reachable after, absent from tree, caught by range mode (`M1a`–`M1d`) | 4 pass (`r14-rev1-merge.log`) |
| `r14-rev1-pybody.sh` | py's pinned CI body verbatim against four fixtures, contrasted with the reference guard (`BODY`, `P1`–`P4`) | 5 pass (`BODY` verbatim-extraction check plus `P1`–`P4`; `r14-rev1-pybody.log`) |
| `r14-rev1-workflow.sh` | `shellcheck -s sh -S warning` on the script; R11-fixture diff (7 added, 0 removed); three-way `BASE_SHA`; always-run hygiene; `actionlint` (`W1`–`W5`) | 9 pass (`r14-rev1-workflow.log`) |
| `r14-rev1-lefthook.sh` | hook rejects, `--no-verify` bypasses, range mode catches (`L1a`–`L3`) | 4 pass (`r14-rev1-lefthook.log`) |

Commands (from the repository root; `E` is the run's `review/evidence/`):

```sh
sh $E/r14-rev1-inputs.sh    # exit 0; inputs failures: 0
sh $E/r14-rev1-guard.sh     # exit 0; guard checks: 29 failures: 0
sh $E/r14-rev1-merge.sh     # exit 0; merge failures: 0
sh $E/r14-rev1-pybody.sh    # exit 0; pybody checks: 4 failures: 0
sh $E/r14-rev1-workflow.sh  # exit 0; workflow failures: 0
sh $E/r14-rev1-lefthook.sh  # exit 0; lefthook failures: 0
```

Digests are in `review/evidence/SHA256SUMS`: `check-large-files.sh`
`3492598c…`, `ci.hygiene-with-guard.yml` `aa37e31a…`. `PY_REPO` and
`TS_REPO` default to the sibling checkouts and are overridable. Scratch
repositories live under `$TMPDIR` and are rebuilt by every run.

**Proposed for P03 (not executed):** the composed `ci.yml` on
`ubuntu-latest` over a pull request that adds then deletes a 2 MiB blob
(`hygiene` must fail at the guard step); a `merge_group` run and a direct
push to `main` on a clean change (must pass); the hook entry through R37's
selected manager; a committed check that `1048576` occurs in
`check-large-files.sh` only; and a range-mode boundary case (a 1048576-byte
blob passes `--range`, a 1048577-byte blob fails it).

## Engines

**Reports.** `raw/muse.md` (actor `research-muse-…`, Muse/Meta) and
`raw/opus.md` (actor `claude-opus-5-5`, Opus seat) — both pass
`scripts/check-answer-shape.sh … bundle`. Both recommend two tiers, 1 MiB,
and one shared script definition. The Opus leg additionally executed a
26-repository practice survey, a 14-repository size profile, three local
binary builds, and 42 fixture checks; the Muse leg executed a 7-case script
matrix, a `git diff -z` pipeline probe, `shellcheck` and `actionlint`. This
synthesis re-executed the load-bearing behavior independently (78 checks
above) and carried the survey/profile/build figures from the Opus leg, each
labeled below.

**Agreements adopted without adjudication:** keep both tiers (HIGH-1); one
shared threshold/exemption definition (LOW); 1 MiB over 500 KB (HIGH-2
value); POSIX shell over `git`, no crate; no `BASELINE-REVIEW:` line; no
owned or consumed parameter; hook-manager mechanism stays with R37.

| # | Disagreement | Verdict and resolving evidence |
|---|---|---|
| D1 | CI placement: dedicated `large-file-guard.yml` (Muse, citing R17) vs step of R11's `hygiene` (Opus, citing R11's slot rule) | **Hygiene step.** R11's accepted registry text decides it: a check that compiles nothing is a `hygiene` step (`I7`), and secret-scanning is carved out as a separate file by name (`I7b`) — R17's dedicated file (`I13`) is that named carve-out, not a precedent a new slot can cite. The guard compiles nothing and no detector key contains its input. Composed fixture passes `actionlint` (`W5`); hygiene stays always-run (`W4a`, `W4b`). Muse's separately-requireable-check point is real but belongs to R12. |
| D2 | Scope: added-files-only via `--diff-filter=A` (Muse) vs every introduced blob via `rev-list --objects` (Opus) | **Blob scope.** An add-then-delete blob is unreachable before `merge --no-ff`, reachable from `main` after, and absent from its tree (`M1a`–`M1c`) — permanent bloat a final-tree check cannot see — and py's body passes it (`P1`) while the reference fails it (`R1`, `M1d`). Py's body also passes modified-file growth (`P3`) and word-splits spaced names (`P4`). The org merges with merge commits, so every commit lands. |
| D3 | Base handling: skip-with-success on empty/all-zero base (Muse, inheriting py) vs check-all-history fail-closed (Opus) | **Fail closed.** Py's skip passes a range containing a 2 MiB blob (`P2`); the reference checks all history instead (`R3`, `R3e`) and errors on an unknown base (`R7`). A wrong `BASE_SHA` expression therefore degrades to a full-history check, never a silent pass. |
| D4 | Exemption: `docs/assets/` prefix (Muse) vs `.gitattributes large-file-ok`, none shipped (Opus) | **Attribute.** The prefix holds 0 entries at the py pin (`I9e`) and R81 names no assets subdirectory (`I12`): the exemption Muse adopts has never exempted anything and has no home in this template. The attribute passes with an `ALLOW:` line (`H6`) and covers LFS-tracked files through their pointer blobs (`H8`). Stated limit (carried from the Opus leg, not re-executed): C-quoted or trailing-space paths cannot be exempted by attribute and fail closed. |
| D5 | Hook call shape: `{staged_files}` argv (Muse) vs `--staged` self-query (Opus) | **`--staged`.** It reduces the R37 contract to "run a command at pre-commit", needs no argv-substitution feature from any manager, and sizes the staged blob rather than the worktree file (`H7a`, `H7b`). End-to-end through `lefthook` 2.1.14: reject, bypass, catch (`L1a`–`L3`). |
| D6 | Provenance of ts's 500 KB: accidental drift (Muse, matching the ledger note) vs retained pre-commit default while py deliberately raised its hook (Opus) | **Opus, verified.** Py ran a bare `check-added-large-files` (the 500 KB default) before lefthook (`I11b`); ts's comment cites that intent (`raw/opus.md`, ts `lefthook.yml:34-35`); py's ADR 0018 raised its hook to 1 MB to mirror its CI guard (`I11a`). **Controller note:** the F172 sub-row note ("no recorded reason for the value difference") should read "py raised deliberately (ADR 0018); ts retained the pre-commit default". Not a `BASELINE-REVIEW:` line: the row is `DIVERGENT` and decided here. The verdict does not move the 1 MiB recommendation. |
| D7 | Threshold evidence: precedent coherence plus fixture headroom (Muse, medium) vs size profile plus binary builds (Opus, medium-high) | **Both adopt 1 MiB; the value rests on carried evidence.** The 14-repository profile and three binary builds were executed in the Opus leg and are cited from `raw/opus.md`, not re-run here. The boundary itself is re-executed (`H2`, `H3`). Re-verify trigger (700000-byte lockfile/changelog) is on the `re-verify:` line. |

**Reference-script provenance.** `review/evidence/check-large-files.sh` is
the Opus leg's 46-line reference with one line changed: the `trap` now
removes `$tmp.sizes` and `$tmp.objs` as well as `$tmp`, closing the cosmetic
exit-2 leak the Opus leg disclosed. All 78 checks run against the committed
bytes. Muse's env-overridable threshold was considered and declined: a
constant keeps the "defined once" property a one-file `grep` can prove. The
revision-3 repair ran that grep from `review/evidence/` on 2026-09-27:
`/usr/bin/grep -c 1048576 check-large-files.sh ci.hygiene-with-guard.yml`
printed `check-large-files.sh:2` (line 6, a comment; line 10, `max=1048576`)
and `ci.hygiene-with-guard.yml:0`. It is not a committed harness check; one is
proposed for P03 above.

**What was carried, not re-executed:** the 26-repository practice survey, the
14-repository size profile, the three binary builds, and the prek/pre-commit
figures (all `raw/opus.md`, retrieved 2026-09-26); the `merge_group.base_sha`
payload field and the push-ruleset plan gating were re-verified by this
synthesis on 2026-09-26 (`github/docs` main and pin `18945a31`) rather than
carried. **Uncertainty:** no GitHub-hosted runner has run either half; no
Linux binary sizes were built; no third-party Rust repository ships this
exact two-tier shape, so there is no production adopter of the combination —
each part has a maintained precedent (pre-commit-hooks, the Rust project's
own tidy principle, git primitives). The P03 hosted runs above close the
runner gap before this decision can be relied on beyond research.
