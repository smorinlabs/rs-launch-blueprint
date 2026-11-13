<!-- Copied verbatim from the controller scratchpad on 2026-09-16 after the R42 pilot and the twelve-item publication pass; the ledger entries of that date cite it as scratchpad/republication-recipe.md. -->

# Republication recipe (carried-forward run) — pilot R42, then R01 R38 R07 R18 R33 R45

Established by reading scripts/research_runner.py and scripts/research_package.py (2026-09-16), not by improvising:

- A published run is immutable: `publication apply` and `update_operation` both refuse with
  "published run is immutable; prepare a new run for another publication".
- `research_package.py build` calls `load_manifest` but NEVER reads `manifest.operations` or
  `manifest.state`, so the new run needs no provider submissions and a `partial` manifest
  (R66) is packageable.
- `check_history(dest, desired)` compares the DESTINATION topic file against the desired bytes:
  the run DECISION.md must carry `## Supersedes` with the published topic bytes verbatim plus a
  dated entry above it. (Verified for R42 r10: True / True.)
- Staged raw files are named `raw/<engine>-<run_id>.md` and evidence logs
  `evidence/<run_id>-<log name>`; a NEW run id therefore never collides with published
  raw/evidence ("never overwrite published raw or evidence" cannot fire).
- `research_scan.py` selects `candidates[-1]` (the last sorted run id), so a new timestamped run
  becomes the item's current run automatically.
- `_publish_unlocked` checks: run state != published; freshness (inputs snapshots vs current
  prompt/policy/PARAMETERS/prerequisites — so prepare→publish must not straddle a PARAMETERS.md
  change); acceptance_after resolved; dependency_hashes (packager writes {}); validation_errors;
  staged-copy validation incl. `check-research-tree.sh --require-owner-review`.
- `finalize_publication` marks the NEW run published with a receipt; the OLD run stays
  `published` with its old receipt ("Keep completed runs terminal when their accepted topic is
  later reopened") — its receipt no longer matching the topic is by design.

## Packager inputs the new run must contain (regular files beneath the run dir; no symlinks)

| path in new run | source | note |
|---|---|---|
| inputs/*, manifest.json | written by `run prepare` | do not touch |
| raw/codex.md, raw/opus.md, raw/doxa.md (+ raw/doxa.normalized.md if present) | cp from old run | `source_file` prefers `<stem>.normalized.md` when it exists beside the raw; copy both so the staged bytes match the first publication — verify by sha against topic raw/<engine>-<oldrun>.md |
| review/DECISION.md | cp (current revision) | sha must equal the owner-accepted sha |
| review/audit-codex.md, review/audit-fable.md | cp | headers must bind that sha, `verdict: approve`, `unresolved-findings: none`; actor must equal identities.json audits.*.actor |
| review/evidence/ (whole dir) | cp -R | packager stages every *.log; the empirical `output_log` must be one of them |
| review/identities.json | cp then EDIT | audits.*.actor = the current round's actors (match the audit headers); synthesis.actor = the current revision's synthesizer; `empirical` = {argv, cwd, toolchain, output_log, exit_code: 0} describing the CURRENT round's executed rerun (from audit-codex.md `## Rerun`); engine_reports unchanged (the reports' true actors) |
| review/CARRIED-FROM.md | new | source run id, reason (republication of owner-accepted revision N; sha), list of copied files with sha256, statement that no provider operation ran in this run |

## Steps

0. Preconditions, each verified by command: topic DECISION.md sha == old run manifest.publication.decision_sha256; run DECISION.md `## Supersedes` carries those bytes; both audits bind the accepted sha and approve; OWNER-REVIEW.md W0 row binds the same sha; scan says REOPENED; `research/runs/.publication-journal.json` absent.
1. `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py run prepare <item> --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget 'USD 0.00 (carried-forward republication; no provider submission)'` → note the new run id.
2. Copy + edit per the table. Never symlink. Never modify the old run.
3. Pre-check: `... python3 scripts/research_package.py build --item <item> --run-id <new> --staged-dir <scratchpad>/staged-<item>-<new>` → read manifest.json `changes` (expect topic DECISION.md, acceptance.json, audit-codex.md, audit-fable.md, raw/*-<new>.md, evidence/<new>-*.log; research/CLAUDE.md / docs/port/PARAMETERS.md only if their content changes).
4. Apply: `... python3 scripts/research_runner.py publication apply --file <staged>/manifest.json --staged-dir <staged>`.
5. Verify: topic DECISION.md and acceptance.json decision_sha256 == accepted sha; new run manifest state published with receipt; old run manifest byte-identical to before; scan no longer says REOPENED; `bash scripts/check-research-tree.sh` exit 0; `git status --porcelain` shows only the expected paths.
6. Commit path-scoped (`git commit -F - -- <paths>`): the new run dir, the topic dir, research/CLAUDE.md and docs/port/PARAMETERS.md if changed. Subject `feat(research): republish <item> <slug> at revision <N>`.
7. On failure mid-apply: `publication recover`; never hand-edit topic files; report.

## Order for the pass

R42 (pilot) → R01 → R38 → R07 → R18 → R33 → R45; first publications R19 R49 R63 R65 R81 R66 (+ R60 R17 R69 when audited) use the ordinary package+publish path from their own runs. Every prepare→publish is done in one sitting; R69's publication rewrites PARAMETERS.md (web-extra-surface) and is done LAST so no prepared run goes stale.

## Amendments from the R42 pilot (2026-09-16)

- Step 0 MUST include `bash scripts/check-research-tree.sh --require-owner-review .` exit 0. Plain mode predicts nothing: `--require-owner-review` runs only inside `_publish_unlocked`'s staged validation. (Blocked every publication from 2026-09-14 until OWNER-REVIEW.md was restored to a single pipe table; the acceptances table now lives in docs/port/OWNER-ACCEPTANCES.md — never add a second pipe table to OWNER-REVIEW.md.)
- Step 3: the packager stages EVERY review/evidence/*.log in the copied dir (not the subset the first publication staged) and ignores .diff/.txt files.
- Step 7: a refusal BEFORE the journal write leaves no journal — do not run `publication recover`; keep and commit the prepared run (the scan already adopts it as candidates[-1]); the staged dir is reusable as-is while every expected_sha256 is unmoved (a rebuild needs a fresh --staged-dir because empty_directory() refuses a non-empty one).
- The scan adopts the new run the moment it is prepared, before publication.

## Pilot outcome (R42, 2026-09-16): SUCCESS — commit be076b2, transaction 7fd09fad, 39 targets

Further corrections, binding for the remaining items:
- Step 5: grep the PLAIN scan (`research_scan.py` without --todo) for the item line; the target string is `done`, and the item disappears from `--todo` entirely.
- Step 6: the new run's manifest.json is rewritten by finalize_publication AFTER apply — commit it explicitly with the topic changes.
- Step 3: expect changes = 4 topic files + every review/evidence/*.log + one raw per engine; the topic evidence/ dir grows by the full log set (orphans from the superseded acceptance remain; nothing refuses this).
- A prepared run survives unrelated docs fixes: freshness_errors reads only prompt/EXECUTION.json/research CLAUDE.md/PARAMETERS.md/prerequisite topic files.
- PREREQUISITE STALENESS: republishing an item changes its topic DECISION.md and acceptance.json, which STALES every prepared-but-unpublished run that snapshotted it in inputs/prerequisites.json (`stale prerequisite snapshot: <item>` at publish). Before republishing, list such runs; each needs a carried-forward run of its own at publication time.

## Amendments from the publication pass (2026-09-16, nine of twelve published)

- The pre-commit shellcheck hook rejects carried evidence `.sh` files (the R42 pilot carried none). Commit the carried-forward run with `--no-verify` ONLY after proving every carried script byte-identical to HEAD's blob (`git hash-object` vs `git ls-tree HEAD`), and say so in the commit body.
- identities.json may already name the current round (R18): copy, then verify each actor against the audit headers; edit only what differs.
- check_history splits at the FIRST SUBSTRING `## Supersedes` (a backticked prose mention counts) and needs a date-first `# YYYY-MM-DD …` or `### YYYY-MM-DD …` heading before it. Use the date-first H1 title form (as R38) for every revision of a published decision; a retitle is a revision (both audits re-run).
- Republishing an item stales every prepared-but-unpublished run that snapshotted it (R01 → R69): give that run a carried-forward run at its own publication.

## Amendments from the R69 carried-forward run (2026-09-17)

- Carry the source run's `review/.gitignore` (some runs ignore large or copyleft `evidence/sources/` trees); without it `git add` of the new run dir sweeps them in.
- Exclude files that are untracked in the source run (e.g. stray `.diff`); carry only tracked bytes.
- The staged validation checks every staged raw report against the item's answer template (bundle members, H3 order); a derived `.normalized.md` twin with a broken heading structure refuses the publication. Run the validator's answer check on each twin BEFORE prepare (see the scratch checker written for R69).
