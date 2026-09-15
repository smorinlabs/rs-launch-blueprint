decision-sha256: 2a665e73f5a5d93794fe49520615e204be294d156f1d537b7bafe1421c042c06
actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r5
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F2 — r60-preservation-diff-r5.sh reads an untracked audit-codex*.md duplicate, so its recorded in-place 133/0 result does not reproduce

## Rerun

argv: bash review/evidence/r60-standard-pin-r5.sh; bash review/evidence/r60-preservation-diff-r5.sh; bash review/evidence/r60-snapshot-provenance-r4.sh; bash review/evidence/r60-standard-pin-r4.sh; bash review/evidence/r60-preservation-diff-r4.sh
cwd: /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R60/2026-09-05T183002Z-09f93cfc507c
toolchain: GNU bash 3.2.57; rustc 1.98.0; cargo 1.98.0
exit-code: in-place r5 standard-pin=0, r5 preservation=1, r4 provenance=0; clean full-repository git archive r5 standard-pin=0, r5 preservation=0, r4 provenance=0; preserved r4 controls=2 and 1 in both trees
log-path: review/evidence/audit-cli-parsing-framework-r5.log
output-matches-decision: no — only the in-place r5 preservation result differs

The full-repository `git archive HEAD` extraction used the repository root, then
ran the commands from this run's archived path. Its offline r5 logs diffed
empty against their committed logs. The archived provenance script exited zero
with its expected no-history outcome: 14 checks, zero failures, and five
unverifiable-here entries.

The r5 standard-pin check passed in place and from the archive. Its owner-record
section extraction passed every C16h–C16o2 assertion, including C16m's scoped
extraction control. It does not print or assert file-wide `OV-01` or
`2026-09-14` counts. The corrected R4.6, R66, and dispositions checks passed.

The preserved r4 scripts have the same bytes as their revision-4 objects. In
both trees, the standard-pin control exited 2 only on C16h/C16i, and the
preservation control exited 1 only on C4h. Five external citations were
spot-checked by the provenance rerun with curl: the pinned standard, the
`clap_builder` tarball and two extracted sources, the `clap_derive` tarball and
two extracted sources, and both public Python sources. Each matched its
recorded hash; the live standard-history check still named the pinned commit.

## Findings

### F2 — the preservation script is not insulated from untracked audit files

`r60-preservation-diff-r5.sh` claims to read committed files only. Its C1o
instead searches `"$RUN_DIR"/review/audit-codex*.md`. The live run already
contained the untracked `review/audit-codex.r4.md`, a byte-for-byte r4-audit
copy beside the canonical `review/audit-codex.md`. Both files contain revision
4's decision hash. C1o therefore observed two matching reports, failed its
required one-report assertion, and made the in-place r5 preservation rerun exit
1 with 133 checks and one failure. The committed log and decision claim exit 0
with no failures.

The clean archive passes because it contains only the tracked canonical report;
that does not establish the claim that the script reads committed inputs only or
that its in-place result reproduces. Make C1o select an explicit canonical,
tracked report (or enumerate tracked paths), regenerate the preservation log,
and correct the decision's in-place reproducibility claim.

## Assessment

Reject. The owner ruling is correctly recorded and the revision-5 anchoring,
parameter preservation, retired OV-01 record, AC2/AC3/AC7 preservation, R66
classification, corrected R4.6 citations, and gate-1 `inapplicable` treatment
all pass in the clean archive. The unresolved failure is the in-place empirical
claim and its untracked-file dependency.
