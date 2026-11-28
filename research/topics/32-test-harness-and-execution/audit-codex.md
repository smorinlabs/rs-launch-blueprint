decision-sha256: f85670a92cee8bc9777198cb4f6032cfe06460dba8e81df821c3b61a0fe740b9
actor: audit-codex-r32-r3b-2026-11-27
model: gpt-6-sol
family: openai
verdict: approve
unresolved-findings: none

## Verification

| Check | Result |
|---|---|
| Draft integrity | **PASS.** `shasum -a 256` matches the required digest. |
| Structure | **PASS.** Before the real supersession heading, the H2 headings are `Decision`, `Parameters`, `Empirical check`, `Engines`, in order. There is one `### Principles and implementation`, one `re-verify:` line, and no earlier `## Supersedes`. |
| R69 parameter | **PASS.** The [draft’s parameter value](/tmp/p02-flagday/drafts/R32-DECISION.md:261) matches [R69 revision 11, line 1885](/Users/smorin/wt/rs-launch-blueprint/docs-p02-research-closeout/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1885) byte for byte after the required `owns`-to-`assumes` key change. |
| Inherited decision | **PASS.** All 76,603 bytes after the `\n\n## Supersedes\n\n` separator equal the [published R32 decision](/Users/smorin/wt/rs-launch-blueprint/docs-p02-research-closeout/research/topics/32-test-harness-and-execution/DECISION.md). Both have SHA-256 `256ac65e50e69f8f6a09f7ae62fb8f4e7ac71bac46f494da5aa88c15ef01ad0b`. |

## F1 disposition

**PASS.** All six Cargo commands in the [four `Justfile` recipes](/tmp/p02-flagday/drafts/R32-DECISION.md:125) include `--workspace --features web`. F117, F132, F173, and **Local scope** describe that selection consistently. F129, `BASELINE-REVIEW: F129`, and **Layout** place the web tier under `crates/web/tests/` without a file-level `#![cfg(feature = "web")]`. The original `CONFLICT: R11` line is byte identical to the published decision; the following `**RESOLVED` paragraph records its disposition as a delegated R11 slot fill.

The [revision 3 empirical check](/tmp/p02-flagday/drafts/R32-DECISION.md:317) matches the [six-command probe log](/tmp/p02-flagday/r32-r3-workspace-probe.log): without `--workspace`, only root tests run; with it, the web integration test and web doc example run; explicit non-web package selection excludes the web member. The log’s SHA-256 is `5a6bd6b58f5301efd9d782fd5ed6b8107d997ee69ec1895087bb63557eaee658`. The draft accurately states the probe’s limit: `cargo-nextest` was unavailable locally, so nextest and the four-package hook were not executed in this probe. That remaining implementation check is assigned to P07 and does not overturn the package-selection evidence or the recommendation.