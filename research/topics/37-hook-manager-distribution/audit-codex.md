decision-sha256: b224198fb3f430a577aad5de13ba8657719a71c02499f0b4a5a57b91eb9f1775
actor: audit-codex-r37-r5-2026-11-27
model: gpt-6-sol
family: openai
verdict: approve
unresolved-findings: none

## Audit

- The draft’s SHA-256 matches the expected value. Before the `## Supersedes` heading, its H2 headings are `Decision`, `Parameters`, `Empirical check`, and `Engines`, in that order. It has one `### Principles and implementation` heading, one `re-verify:` line, and no earlier `## Supersedes` heading.
- The draft’s `web-extra-surface` assumption matches R69 revision 11, line 1885, byte for byte after replacing `- owns` with `- assumes`. R69’s file hash also matches the hash cited in the draft.
- `cmp` confirms that every byte after the supersession separator matches the prior published decision. Both portions hash to `b172133d641c90157f3fb562281981e118cfd7397a382d23f209a56aec520c73`.
- A line comparison found no change to the lefthook recommendation, acquisition route, crate or version choices, candidate configuration, or carried evidence results. The archived logs still report 17, 9, and 26 passing checks, respectively, with zero failures.

This audit verified the flag-day changes and archived results. The original evidence scripts were unavailable in this checkout, so they were not rerun. No outcome-changing contradiction was found under RUNBOOK §7 and Q23.