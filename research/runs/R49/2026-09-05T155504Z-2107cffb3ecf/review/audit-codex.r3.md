decision-sha256: 85eddc5806c820229f9ad84b82fdc5d9c8e8098c9562105707a6584011794770
actor: audit-codex-2026-09-05T155504Z-2107cffb3ecf-r3
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: false claim that no raw report excluded cargo-binstall on a licence ground

## Rerun

argv: `bash review/evidence/check-lockfile-inclusion.sh`

cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R49/2026-09-05T155504Z-2107cffb3ecf`

toolchain: `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`.

exit code: 0

log path: `review/evidence/audit-build-target-declaration-r3.log`

output matches the decision's cited `review/evidence/lockfile-inclusion-conditions.log`: yes, except the expected UTC `retrieved:` timestamp; all 13 content assertions passed. Five cited upstream sources were also fetched and content-checked at their pinned tags; log: `review/evidence/audit-citations-r3.log`.

## Findings

1. **The revision-3 provenance assertion is false and must be corrected.** `review/DECISION.md:28-30` says, “No raw report excluded `cargo-binstall` on a licence ground.” The canonical Opus raw report, `raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md:353-356`, says that `cargo-binstall` “fails **gate 1**” because its licence is `GPL-3.0-only`, then says it is excluded regardless by scope at `:359-362`. The correction should retain the owner ruling and the decision's independent scope exclusion, but acknowledge that the pre-ruling Opus report did state a licence ground. This is a decision-history/evidence claim, not a request to reinstate fitness gate 1.

2. **The two specific revision-3 repair claims otherwise hold.** The surviving scope exclusion is in the decision's own `### Principles and implementation` section at `review/DECISION.md:228-239`, with the pertinent R68/F214 wording quoted verbatim from `inputs/prompt.md:14`; it is not confined to a provider-report column. The required gate-1 statement appears wholly on one line at `review/DECISION.md:200`: `(1) *License* — \`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool\`.` This correctly applies the owner ruling and is not a finding.

## Assessment

The empirical lockfile condition, source-pin semantics, and cited-source spot checks reproduce. The recommendation need not move, and gate 1 must remain inapplicable. However, a decision cannot claim raw-report provenance that its canonical evidence contradicts. Correct that one assertion before acceptance.
