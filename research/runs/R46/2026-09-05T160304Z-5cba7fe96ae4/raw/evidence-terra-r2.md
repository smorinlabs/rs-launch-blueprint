Actor: `evidence-terra-2026-09-05T160304Z-5cba7fe96ae4-r2`
Item: `R46` (`per-file-license-header`)
Checked: 2026-09-05

## Figures

No report figure uses any endpoint in the prompt's figure table. R46 selects a
repository pattern and recommends no crate dependency; the report therefore
makes no crates.io download/release, GitHub star/issue, RustSec, or adopter
figure claim to re-query. Result: **ok** — 0 endpoint figures.

## Gates

| Claim | Result | Independent check |
|---|---|---|
| Cargo metadata can express the fixed dual license and the root pair is the Rust convention. | ok | Cargo's manifest reference gives `license = "MIT OR Apache-2.0"` as an SPDX expression; Rust API Guidelines C-PERMISSIVE specifies `LICENSE-APACHE` and `LICENSE-MIT`. |
| A one-line SPDX expression is valid SPDX metadata, while REUSE additionally requires copyright metadata. | ok | The cited SPDX and REUSE specifications support this distinction. |
| The revised `r46_check_headers` function rejects the stated forbidden header forms and normalizes a checker error to failure. | ok | Executing the extracted function with Bash returned 0 for a clean `//!` input, 1 for a top-of-file SPDX line, and 1 for an unreadable descriptor. Its Bash syntax also passed `bash -n`. |
| The validation sequence proves the migration's rule that generated Rust files contain no full-text, SPDX, or REUSE per-file header. | wrong | The function returns 0 for a first-line Apache full-text header beginning `// Licensed under the Apache License, Version 2.0`. It searches only two SPDX markers and two MIT-specific phrases. That accepted input is a prohibited full-text per-file header under `Migration implications`; the probe therefore cannot prove the stated negative rule. It also ignores any marker after line 20. |
| Root-only metadata, plain SPDX, and REUSE have been exercised on both required CI runners. | unverifiable | The report correctly labels the `ubuntu-latest` and `macos-latest` gate unverified. The cited syntax/conformance sources do not establish those executions. |

## References

The normative Cargo, Rust API Guidelines, SPDX, and REUSE documents resolve and
support the reported syntax/policy claims. The cited Serde, Tokio, Axum, and
OpenZeppelin template source files resolve and have the described header-free
representative opening. Fresh GitHub repository queries for those references
returned non-archived repositories with recent pushes, so the recommendation's
reference implementations exist and are maintained at this check time.

## Verdict

**defective**

1. `raw/codex.md` lines 413-439 provide an acceptance checker that misses an
   Apache full-text header, although lines 371-375 prohibit a full-text header
   of either license. Broaden the policy or replace the heuristic with a
   complete, explicitly specified header detector and add the Apache inverse
   control before treating the migration check as evidence.

Counts: **ok 3, wrong 1, unverifiable 1**.
