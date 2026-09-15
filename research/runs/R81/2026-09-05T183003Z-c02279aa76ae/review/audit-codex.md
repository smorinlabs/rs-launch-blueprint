decision-sha256: 4647372666b7e94537d75fb684c6ca5ec5cca6929841330bab8832ddb6e7328e
actor: audit-codex-2026-09-05T183003Z-c02279aa76ae-r3
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash review/evidence/docs-delivery-claims.sh`
- cwd: isolated Git checkout `/private/tmp/r81-audit-r3.Der0e8/repo/research/runs/R81/2026-09-05T183003Z-c02279aa76ae`; it contains revision-2 blob `9f2bcb9ddf5266bf4face766e98b7cd1be3616ad`, so check 16 ran under its stated precondition.
- toolchain: macOS 26.4; Darwin 25.4.0 arm64; `rustc 1.98.0`; `cargo 1.98.0`; `gh 2.98.0`.
- exit: 0; 154 `PASS` lines, 8 gated `ASSERT ...=True` lines, 0 `FAIL` lines, and `failed assertions: 0`.
- log: `review/evidence/audit-docs-delivery-model-r3.log`.
- match: yes. The raw rerun output is byte-identical to `review/evidence/docs-delivery-claims.log`; both have SHA-256 `152ddb42429b3b72646cb24bf9fd6d5cd103adb099784a7865630a6fbeb0981c`.
- shared-run note: an earlier shared-directory rerun failed only after another writer removed `review/evidence/snapshots/.norm.py` during the run; the isolate avoids that documented shared-snapshot race. It is not a decision defect.

## Findings

None.

## Assessment

Revision 3 answers the structural finding rather than flipping revision 2's branch by implication. `## Decision` states the fit judgement and grounds it in raw-source fidelity, the measured six-category corpus, the practice-structure comparison, and default search; checks 5, 6, and 12--15 reproduce those claims. The practice sample is asymmetric (four flat README cases and one nested-tree case), but the decision states that limit and does not treat it as independent proof of broad Rust practice; grounds 1 and 4 do not depend on it.

The four shipping rows F341, F346, F351, and F352, F343's Mermaid exclusion, and F344's unconditional build-drift rule are all explicit; F357's placement question is live and the two `justfile` recipes are present. Check 16 also verifies the surviving fixed parameters, the own-source licence expression, the 218-package non-reach finding, the committed-`theme/` prohibition, and the conditional Font Awesome content-attribution duty. `zola` and `mdbook-mermaid` are re-evaluated on fit alone, not licence. The hosted Pages URL is correctly recorded as derived and unproven, not live.

The rerun spot-checked more than five cited endpoints with `curl`: RustSec, six mdBook guide pages, the published goals site, Mozilla's MPL FAQ, GitHub's Mermaid documentation, and Zola's configuration page. No book was built and no GitHub web UI Mermaid rendering was asserted, consistently with the P02 research-only contract.
