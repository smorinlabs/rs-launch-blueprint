decision-sha256: 039ef6db8b54659991c50eae1ff473c3ece5674cdf13e7a276212c8b545ac2c3
actor: audit-codex-r84-r6-2026-11-27
model: gpt-6-sol
family: openai
verdict: approve
unresolved-findings: none

## Empirical audit

- `shasum -a 256` matches the expected digest.
- Before the sole `## Supersedes` heading, the H2 headings are `Decision`, `Parameters`, `Empirical check`, and `Engines`, in that order. There is one `### Principles and implementation` heading and one `re-verify:` line.
- The `web-extra-surface` value matches R69 revision 11, line 1885, byte-for-byte after the required `- assumes` and `- owns` prefixes.
- All 71,014 bytes after the supersession marker match the prior published R84 decision.
- The `openapi-to-rust` 0.17.0 recommendation, `OVERRIDE (OV-11)`, versions, and carried empirical results are unchanged.

**Nonblocking provenance note:** The draft still says its five parameter lines match the frozen run input and current registry. Those files retain the older `web-extra-surface` value. Check `A04` compares those files with each other; the direct R69 comparison above verifies the revised value.