decision-sha256: ebcbe236064e05558895d2acc2ee5f6b7f9a6c712f6527c76c9fb92fdeecbf51
actor: audit-codex-2026-09-05T183003Z-c02279aa76ae-r4
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash review/evidence/docs-delivery-claims-r4.sh > review/evidence/audit-docs-delivery-model-r4.log 2>&1`
- cwd: isolated Git clone `/private/tmp/r81-r4-audit.TIK9Et/repo/research/runs/R81/2026-09-05T183003Z-c02279aa76ae`; its object database contains revision-3 blob `460e6f9002663f7e00921406c3bd9bc2785328fe`, which is check 17's stated precondition.
- toolchain: GNU bash 3.2.57; Python 3.14.7; Git 2.50.1; Darwin 25.4.0 arm64.
- exit: 0; 101 `PASS` lines, 0 `FAIL` lines, and `failed assertions: 0`.
- log: `review/evidence/audit-docs-delivery-model-r4.log`.
- output match: yes. The rerun log is byte-identical to `review/evidence/docs-delivery-claims-r4.log`; both SHA-256 values are `2ca46e1812beb805e89c52db8e5d1b89c8fac1fdb23c9e3549b1948be1a75c4a`.

I also ran the preserved revision-3 command, `bash review/evidence/docs-delivery-claims.sh`, in that same isolated clone. It exited 1 exactly as revision 4 discloses. Checks 1--15 produced 119 `PASS` lines and 0 `FAIL` lines. Check 16 produced one failed assertion (reported as two `FAIL` lines: its changed-region message and the shell wrapper) and caused the exit 1. The old script's revision-2 hunk-count assertion still passes at 17; the changed-region assertion is the direct failure. No command wrote to the shared `review/evidence/snapshots/` directory.

## Findings

None.

## Assessment

Checks 17 and 18 reproduce the stated revision-4 evidence: 26 preservation regions are byte-identical to revision 3, all eight required repair regions changed with their required markers, and the seven preserved artifacts retain their recorded hashes. Check 18 also reads the three claimed async-runtime versions and the two notice-rule packages from the committed lock, with an absent-package control.

The decision does not hide the legacy script failure, and the rerun confirms its narrower claim that checks 1--15 still pass. It records the shipped-site notice scope as unproven pending a P03 build, records the default-feature `mdbook serve` statement as unproven pending execution, and does not treat either as an implemented result. Gate 1 is verbatim `inapplicable` for the owner ruling; gates 2--6 are recorded rather than silently omitted.

Five current cited endpoints were independently fetched with `curl` and content-checked: mdBook Markdown conversion, `SUMMARY.md` requirement, default search, GitHub Mermaid guidance, and Mozilla's MPL FAQ. All five matched the decision's cited content. The audit did not build, install, or deploy the proposed template, consistent with the research-only contract.
