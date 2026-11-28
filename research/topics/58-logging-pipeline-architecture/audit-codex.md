decision-sha256: e88caffbb011db651b40a50c066e5e8a67d155a34fd2253b4c02c9058bedeb91
actor: audit-codex-r58-r3-2026-11-27
model: gpt-6-sol
family: openai
verdict: approve
unresolved-findings: none

# R58 revision 3 empirical audit

- The draft’s SHA-256 matches the expected hash.
- Before the real `## Supersedes` heading, the H2 headings are `Decision`, `Parameters`, `Empirical check`, and `Engines`, in that order. There is one `### Principles and implementation`, one `re-verify:` line, and no earlier `## Supersedes` occurrence.
- The draft’s `- assumes web-extra-surface = ...` line matches R69 revision 11 line 1885 byte-for-byte after the required prefix replacement. Its `- owns logging-pipeline-contract = ...` value matches `docs/port/PARAMETERS.md` byte-for-byte.
- `cmp` confirms that every byte after the supersession separator matches the prior published R58 decision. Both have SHA-256 `8dc8ce955c58abd508d45bd74a6b2c3f9eb96bde5c43ae20538f2439c8867aae`.
- The recommendation and logging crate versions are unchanged. The R69 assumption retains `axum` 0.8.9, `tokio` 1.53.1, and `tower` 0.5.3. Recorded empirical results are unchanged.

**Non-blocking carryover:** Two prose passages still describe R69 revision 10 as unpublished and revision 9 registry bytes as current. The current checkout also retains the older web registry row pending the stated flag-day co-publication. The draft’s operative assumption matches R69 revision 11; these status statements do not change the recommendation or its evidence sufficiency under `research/RUNBOOK.md` §7 and Q23.