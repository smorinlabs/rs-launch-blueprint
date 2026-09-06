Actor: `evidence-terra-2026-09-05T160304Z-5cba7fe96ae4-r4`
Item: `R46` (`per-file-license-header`)
Checked: 2026-09-05

## Figures

No endpoint-derived figure appears in `raw/codex.md`. R46 recommends a
repository pattern and no crate dependency, so the prompt's crates.io, GitHub
figure, RustSec, issue-responsiveness, and adopter figure endpoints do not
apply. Result: **ok** — 0 figures re-queried.

## Gates

| Claim | Result | Independent check |
|---|---|---|
| The fixed `MIT OR Apache-2.0` expression and root `LICENSE-APACHE` plus `LICENSE-MIT` pair are valid Cargo/Rust guidance. | ok | Cargo documents `license = "MIT OR Apache-2.0"` as an SPDX expression. The Rust API Guidelines prescribe that expression and the two root files. <https://doc.rust-lang.org/cargo/reference/manifest.html>; <https://rust-lang.github.io/api-guidelines/necessities.html> |
| A standalone SPDX identifier can carry the dual expression, while a REUSE comment header also needs copyright notice(s). | ok | The REUSE specification requires one or more copyright notices and one or more `SPDX-License-Identifier` pairs in a comment header, and requires a valid SPDX expression. <https://reuse.software/spec-3.3/> |
| The revised `r46_check_headers` function rejects all five exactly enumerated forms and converts checker errors to exit 1. | ok | I loaded `raw/codex.md:428-482` verbatim with Bash. `bash -n` passed. Fresh controls returned 0 for a clean `//!` file and 1 for forms (a) through (e), each with the expected form diagnostic. A missing path returned 1. The detector returned 0 for an SPDX marker at line 41 and for title pairs outside their stated three-line/two-line windows, matching the explicit policy boundary. |
| The checker has one retained fixture for the clean case and each enumerated prohibited form. | ok | I ran the hidden fixtures `raw/.r46-evidence-r4-clean.rs` and `raw/.r46-evidence-r4-{a,b,c,d,e}.rs` through the verbatim checker. The clean fixture returned 0; forms (a) through (e) each returned 1 with their expected diagnostic. The retained boundary fixtures also returned 0 for a line-41 SPDX marker and for title pairs outside the permitted windows. |
| Root-only metadata, plain SPDX, and REUSE have been exercised on both required CI runners. | unverifiable | The report correctly marks `ubuntu-latest` and `macos-latest` execution unverified. Cargo, SPDX, and REUSE references establish syntax or conformance, not those CI executions. |

## References

The dominant-choice examples exist and are currently maintained. Direct GitHub
repository queries on 2026-09-05 returned HTTP 200 and `archived: false` for
Serde (pushed 2026-08-25), Tokio (pushed 2026-09-05), Axum (pushed
2026-09-04), and OpenZeppelin's Rust template (pushed 2026-09-05):
<https://api.github.com/repos/serde-rs/serde>,
<https://api.github.com/repos/tokio-rs/tokio>,
<https://api.github.com/repos/tokio-rs/axum>, and
<https://api.github.com/repos/OpenZeppelin/rust-project-template>.

The report conservatively labels its earlier rate-limited maintenance probe
unverified. That disclosure is not a false maintenance claim; the independent
queries above now satisfy the evidence-check requirement for the cited
reference implementations.

## Verdict

**sound**

No defect found in the fourth revision. The previously defective broad
full-header assertion has been replaced by an explicit five-form prohibition
set, and the actual detector implements that set within the declared first-40-
line scope. The retained fixtures confirm every specified form.

Counts: **ok 4, wrong 0, unverifiable 1**.
