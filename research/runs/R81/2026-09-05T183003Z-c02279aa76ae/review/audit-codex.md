decision-sha256: 4329ce48b428b70cab0bea32e71bb725471faac2c88356f3b0fa9b005fc5772e
actor: audit-codex-2026-09-05T183003Z-c02279aa76ae-r5
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash review/evidence/docs-delivery-claims.sh`; `bash review/evidence/docs-delivery-claims-r4.sh`; `bash review/evidence/docs-delivery-claims-r5.sh` three times
- cwd: isolated clone `/private/tmp/r81-audit.ClOOU4/repo/research/runs/R81/2026-09-05T183003Z-c02279aa76ae`
- toolchain: `rustc 1.98.0`; `cargo 1.98.0`; `gh 2.98.0`; Darwin 25.4.0 arm64
- exit code: original `1`; r4 `1`; r5 reruns `0`, `0`, `0`
- log path: `review/evidence/audit-docs-delivery-model-r5.log`
- output matches the decision: yes. The original script produced 152 `PASS`, 2 `FAIL`, and `failed assertions: 1`; r4 produced 99 `PASS`, 2 `FAIL`, and `failed assertions: 1`; r5 produced 126 `PASS`, 0 `FAIL`, and `failed assertions: 0`. The recorded r5 log and all three r5 reruns diffed empty.

## Findings

None. The original script failed on `unproven entry 3 (unsafe posture)` and `revision-3 untouched-region diff`, while retaining `ASSERT hunk_count_is_17=True`. The r4 script failed on its revision-4 title and changed-region assertions, also retaining that hunk assertion. The r5 script passed checks 19 and 20, including byte-identical preservation of the recommendation, shipped-site notice rule, six-gate block, confidence statement, corpus figures, four `- assumes` lines, r4 artifacts, and the re-anchored `4. **Wh` region. Gate 1 is correctly `inapplicable` under Q7.B. Five live `curl` spot checks supported the registry, GitHub, RustSec, and Zola citations.

## Assessment

Revision 5 accurately discloses the legacy failures and their mechanism. It does not overstate the checks, and its recommendation and evidence-bearing sections remain unchanged from revision 4.
