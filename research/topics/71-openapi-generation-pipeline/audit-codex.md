decision-sha256: 30d9f60c0091cfba6bccf356000e19e36ba2e572d0a437170eb1f7859e73a00a
actor: audit-codex-r71-r4b-2026-11-27
model: gpt-6-sol
family: openai
verdict: approve
unresolved-findings: none

## Empirical audit

- The draft’s SHA-256 matches the expected digest. Before the real `## Supersedes` heading, its H2 headings are exactly `Decision`, `Parameters`, `Empirical check`, and `Engines` in order. It has one `### Principles and implementation`, one `re-verify:` line, and no earlier `## Supersedes`.
- The `web-extra-surface` value matches R69 revision 11 line 1885 byte for byte after changing the required `- owns` prefix to `- assumes`. Every byte after the `## Supersedes` delimiter matches the prior published R71 decision.
- The JF-1 repair is consistent across the member table, A5, A13, example paths, test code, regeneration recipe, and R37 note. The test is placed at `crates/web/tests/openapi.rs` without a file-level feature gate; `SNAPSHOT` uses `CARGO_MANIFEST_DIR` to reach the root contract. The selected `expectorate` version is 1.3.0.
- The probe log’s digest matches the draft’s citation. It records the old command failing with exit 101 and the workspace command passing with exit 0 and one test passed. The log does not include the probe test source; the draft states that limit.
- The `CONFLICT: R69` line matches the prior decision byte for byte, and the new `**RESOLVED` paragraph explains its disposition under R69 revision 11.

No outcome-changing contradiction was found under RUNBOOK §7 and Q23.