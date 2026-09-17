# Addendum for revisions answering a JUDGMENT audit (read after revision-rules.md)

- The item's `review/audit-codex.md` (empirical, family openai) APPROVED the current
  revision; `review/audit-fable.md` (judgment, family anthropic) REJECTED it. Your
  revision answers EVERY finding in `review/audit-fable.md`. Read both audits in full.
- The judgment auditor stated that the recommendation still follows. Do not change
  the recommendation, crate, version or owned-parameter VALUE unless a finding
  requires it; if a finding does require it, say so in the revision note in the
  first paragraph.
- Everything the empirical audit reproduced - scripts, cited logs, evidence
  artifacts - stays byte-identical unless a finding requires a new check. A new
  check is a NEW file (r<N> suffix); never edit a cited script or log in place.
- Prose corrections: keep the wrong sentence where it is a preservation target and
  correct it in place (revision-4-of-R60 precedent); otherwise replace it.
- Published items keep `## Supersedes` byte-identical to the published file.
  Unpublished items do not add one.
- Retitle to the new revision; add a revision note that quotes each finding by its
  label and names the repair in one line each; extend the revision history.
- Owner rulings are settled: 2026-09-12 Q7.B (gate 1 `inapplicable`), 2026-09-14
  (CLI Design Standard v1.4.14 binds; OV-01 refused; R60 option (b)), and TODAY
  2026-09-14 W0-R67: the owner ACCEPTED R67 at sha256 16947ab1... - its exit-code
  taxonomy (0/1/2/3/4/5/130/143, SIGTERM -> 143, SIGINT -> 130) binds every item.
- Git: `git add research/runs/<ITEM>/<RUN>/...` then
  `git commit -F - -- research/runs/<ITEM>/<RUN>` with a Conventional Commits heredoc
  ending `Claude-Session: https://claude.ai/code/session_01ULEUr6b17aZ6iTpWjPGtWM`.
  Never a bare `git commit`, never `-a`, never `--amend`. Touch no other path.
- Report in at most 8 lines: new sha256, commit hash, one line per finding saying
  what changed, whether any recommendation/parameter value moved, anything not done.
