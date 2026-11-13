Actor: `evidence-terra-2026-09-05T160304Z-5cba7fe96ae4-r3`
Item: `R46` (`per-file-license-header`)
Checked: 2026-09-05

## Figures

No endpoint-derived figures appear in `raw/codex.md`. R46 recommends a
repository policy and no crate dependency, so the crates.io, GitHub REST,
RustSec, issue-responsiveness, and adopter figures in the prompt do not apply.
Result: **ok** — 0 figures re-queried.

## Gates

| Claim | Result | Independent check |
|---|---|---|
| Cargo can express the fixed dual license; SPDX accepts the same expression; REUSE additionally requires copyright metadata. | ok | Cargo's manifest reference gives `license = "MIT OR Apache-2.0"` as an SPDX expression. REUSE specifies `SPDX-License-Identifier` and copyright tag-value pairs. Retrieved 2026-09-05: <https://doc.rust-lang.org/cargo/reference/manifest.html>, <https://reuse.software/spec-3.3/>. |
| The revised `r46_check_headers` control flow rejects each of its expressly listed SPDX, MIT, and Apache signatures within the first 40 lines. | ok | I executed the report's function with `/bin/bash`, `/usr/bin/awk`, and host `xargs`. A header-free `//!` input returned 0; the three listed Apache signatures and the MIT signature returned 1. A marker after line 40 returned 0, as the stated boundary requires. |
| The validation sequence proves the migration rule that generated Rust files have no full-text license block, SPDX line, or REUSE header. | wrong | The function has only a finite phrase detector, while `Migration implications` prohibits every full block. An Apache-2.0 full-text opening such as `// Apache License`, `// Version 2.0, January 2004`, `// TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION` contains none of the listed signatures in its first 40 lines; the function returned 0. This is a prohibited full-text header that the proposed acceptance check accepts. |
| The selected root-only pattern and header alternatives have been exercised on `ubuntu-latest` and `macos-latest`. | unverifiable | The report correctly labels this required fitness gate unverified. Its local Darwin controls and cited Cargo, SPDX, and REUSE documents do not establish both GitHub Actions runner executions. |

## References

The cited representative files exist and have the reported opening shape:
Serde and Axum begin with `//!` documentation, Tokio begins with attributes,
OpenZeppelin's template begins with module documentation, and clap retains its
MIT-only header. Result: **ok**. Retrieved 2026-09-05:
<https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs>,
<https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs>,
<https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs>,
<https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/src/lib.rs>,
<https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs>.

Current maintenance of the cited reference implementations is
**unverifiable** from this report. Independent requests to the four cited
GitHub repository API endpoints returned `API rate limit exceeded`; raw source
availability is not a release, recent-push, or maintainer-response signal. The
report discloses this gap rather than falsely asserting maintenance.

## Verdict

**defective**

1. `raw/codex.md:371-375` prohibits a full per-file license block, but
   `raw/codex.md:414-457` detects only selected literal signatures. The
   standard Apache-2.0 title-form full text passes the checker, so the planned
   acceptance sequence cannot prove the stated migration rule. Either narrow
   the rule to the explicit signature set or use a detector that rejects every
   prohibited full-text form and add this Apache title-form inverse control.

Counts: **ok 3, wrong 1, unverifiable 2**.
