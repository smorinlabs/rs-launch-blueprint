decision-sha256: 0d4f2e60e994439d9261f5169c3fd28e5e76077dacd089d999a51fb67a5f6c5d
actor: audit-fable-2026-09-05T162359Z-3c50443de1e8
model: claude-fable-5-1
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Judgment auditor for R04 (`public-api-surface-enforcement`, kind `pattern`, Focused tier, owns nothing), run `2026-09-05T162359Z-3c50443de1e8`. I produced none of the inputs. Read: `inputs/prompt.md`, `raw/codex.md` (sha256 `581d44c5…d60ae4`, identical to the hashed copy), `raw/opus.md` (sha256 `16ffb548…423481`, identical to the hashed copy), `review/DECISION.md` (revision 1; the sha256 above was taken before and re-taken after the review, unchanged), `review/audit-codex.md` (present when I finished, sha256 `3ac9351dea53420714535bc1ca2ad67f90d2f9e78c866837a0f107dc126cfe74`), `docs/port/PARAMETERS.md`, spec §2, `docs/port/BASELINE-REVIEW.md` row F014, `docs/port/COMMONALITY.md` rows F014, F015, F021, F075, F214, and `research/RUNBOOK.md` §4–§5. Focused tier: the two raw reports are the complete required input; no Doxa report is required and none exists.

The decision states the shared requirement at the levels the prompt and the baseline review bind:

- F014 (one curated public surface exists) is an `architectural pattern`, `retained` in `docs/port/BASELINE-REVIEW.md:38` and `COMMON → REUSE` in `COMMONALITY.md:20`. The decision consumes it unchanged and explicitly declines to re-decide it, as the prompt's `## Context` requires.
- F015 (whether that surface is enforced or only documented) is the `policy/mechanism` level, `DIVERGENT` in `COMMONALITY.md:21`, and is the only thing this item decides. The decision names the two source positions with pinned evidence (py HEX-34 "documents, it does not enforce"; ts D-012(3) hand-authored root-only `exports` map) and carries forward ts's level, mechanical and non-bypassable, as the requirement. That is the correct reading of spec §2: the level of agreement was recorded before alternatives were compared, not inferred from either implementation.
- No `OVERRIDE (OV-nn)` is needed and none is claimed: F015 is `DIVERGENT`, so selecting one precedent's principle realized by a native mechanism departs from no recorded common pattern. Correct.
- `BASELINE-REVIEW:` handling. Codex emitted `BASELINE-REVIEW: F014 — … — retain …`; Opus emitted none. The decision records Codex's line in `## Decision` and forwards nothing for adjudication because the proposed change is retention, which matches the ledger. Runbook §4 assigns adjudication to the controller; a retention finding needs no ledger, prompt or dependency change, and the decision makes the line visible to the controller rather than dropping it. Handled as required.
- `CONFLICT:` handling. Neither raw emitted one; the decision states none and needs no registered value changed. The dependency note for R02 is correctly not a `CONFLICT:` line: F021 is `RUST-ONLY` (`COMMONALITY.md:27`, verified) and no registered parameter is involved.

## Design and evidence

Architecture alternatives were genuinely compared before any tool was weighed (A convention-only, B visibility-only, C plus denied lints and doctests, D plus a CI drift detector, E physical crate split), each with an executed case as evidence, and the tool selection inside D follows from the prompt's stable-Rust-only constraint, not from popularity or repository agreement: `cargo-semver-checks` sets `RUSTC_BOOTSTRAP=1` itself and ran here with no nightly installed, while `cargo-public-api` requires an installed nightly by its own README and by Opus's executed failure. The 1,144-workflow adoption count and the tokio/hyper/ratatui usage are practice evidence for the CI-gate half; they are not what decides the pick.

I re-verified the load-bearing citations on 2026-09-05. Every one matched the decision exactly.

| Claim in the decision | Source I fetched | Result |
|---|---|---|
| Reference rule "If an item is public, then it can be accessed externally from some module `m` if you can access all the item's ancestor modules from `m`" | `doc.rust-lang.org/reference/visibility-and-privacy.html` | Verbatim match; the "privacy chain … short-circuited through the reexport" sentence is also present |
| `unreachable_pub` and `missing_docs` allow-by-default; `private_interfaces` and `private_bounds` warn-by-default | rustc lint listings, allowed-by-default and warn-by-default pages | All four on the pages stated; `unreachable_pub` is absent from the warn-by-default page, so Codex's citation was wrong and the decision's case-05 resolution in Opus's favor is right |
| `cmd.env("RUSTC_BOOTSTRAP", "1")` at `src/data_generation/generate.rs:544`, commit `b778c28f` | raw file at that commit, `grep -n` | Exactly line 544 (a second occurrence at 733) |
| `cargo-public-api` "nightly toolchain must be installed"; `0.52.x` needs `nightly-2025-11-22` or later | README on `main` | Verbatim match, including the compatibility table rows |
| tokio `ci.yml:498-515` `semver` job, `rust-toolchain: ${{ env.rust_stable }}`, `feature-group: only-explicit-features` | raw file on `master`, `grep -n` | Job starts at 498; action at 505 and 515; toolchain at 507; feature group at 510 |
| hyper `CI.yml:32,347-355`; ratatui `check-semver.yml` SHA-pinned with `permissions: {}` | raw files | Lines 32, 347, 353, 355 match; ratatui pins `@6b69fcf…` and sets `permissions: {}` |
| axum `axum/src/lib.rs:553-602` private `mod boxed; …`, `pub mod extract …`, root `pub use self::routing::Router;` | raw file on `main` | Private mods at 553–560, `pub mod` at 562–575, `pub use self::json::Json` at 584, `Router` at 586 |
| `cargo-semver-checks` `src/lib.rs:1` `#![forbid(unsafe_code)]` | raw file on `main` | Line 1 matches |
| `action.yml` inputs `rust-toolchain` (default `stable`), `baseline-version`, `baseline-rev`, `baseline-root`, `package`, `exclude`, `feature-group`, `features` | raw `action.yml` on `main` | All present; `rust-toolchain` defaults to `'stable'` |
| Rust Project Goal 2026 "Continue resolving `cargo-semver-checks` blockers for merging into cargo", status Accepted | `goals.rust-lang.org/2026/cargo-semver-checks.html` | Title and `Accepted` match; teams cargo and rustdoc |
| `cargo-semver-checks` `0.50.0`, `2026-08-01T17:02:07Z`, `Apache-2.0 OR MIT`, `rust-version = 1.93`, edition 2024 | `GET https://crates.io/api/v1/crates/cargo-semver-checks/versions` | Identical |
| `cargo-public-api` `0.52.0`, `2026-05-25`, `MIT`, no `rust-version` | `GET https://crates.io/api/v1/crates/cargo-public-api/versions` | Identical |
| 1,675 stars, `archived: false`, `pushed_at 2026-08-29T20:34:57Z`; runner-up 573 stars, `pushed_at 2026-09-04T04:43:39Z` | `gh api repos/<o>/<r>` (authenticated REST; the unauthenticated call was rate-limited) | Identical |
| Release assets 7,549,820 bytes (`aarch64-apple-darwin`) and 7,866,573 bytes (`aarch64-unknown-linux-gnu`) | `gh api repos/obi1kenobi/cargo-semver-checks/releases/tags/v0.50.0` | Identical; an `x86_64-unknown-linux-gnu` asset (8,376,931 bytes) also exists |
| RustSec: `https://rustsec.org/packages/cargo-semver-checks.html` returns 404, read as no advisory page | the same URL; `https://rustsec.org/packages/` index; a control page | 404 reproduced; none of the three tools appears in the packages index; the control page `packages/openssl.html` returns 200, so the 404 reading is now independently confirmed (the decision had marked it unconfirmed) |
| Rust Book ch. 14.2 "Exporting a Convenient Public API with `pub use`" | `doc.rust-lang.org/book/ch14-02-publishing-to-crates-io.html` | Heading present |
| `rustls/src/lib.rs` private modules with selected root re-exports (Codex; the decision marks it unverified) | raw file on `main` | Private `mod msgs; mod conn; …` at 360–373 and 14 root `pub use crate::…` lines at 393–414; the decision's "not independently verified" caveat can be lifted |

The reference implementations are maintained and the decision cites file paths and line numbers that resolve today. The library selection carries the six fitness gates for the one tool it adds, with sources; the language mechanisms are declared inapplicable to crate figures with the reason stated, as the prompt's tier guidance requires.

## Completeness

Runbook §5 decision fields, each checked against the file:

| Required | Present | Note |
|---|---|---|
| `## Decision` with recommendation and version | yes | pattern named; `cargo-semver-checks 0.50.0`; no dependency added |
| settled `F###` rows | yes | F015 settled value in a table; F014 consumed as retained |
| `### Principles and implementation` | yes | requirement, source, two agreement levels, behaviors B1–B6 mapped to executed cases, must-agree versus may-vary, alternatives A–E, gates, reference implementations, file-level changes, runner-up, tradeoffs, fit per shape |
| `re-verify: <date or event>` | yes | `2027-03-05` plus six event triggers |
| `## Parameters` with exact owned and assumed values | yes | no owned parameter (prompt `- owns:` empty, `research/CLAUDE.md` `—`); four `assumes` lines whose values match `docs/port/PARAMETERS.md` character for character; fixture `rust-version = "1.96"` equals stable 1.98 minus two minors and passed on 1.96.0 |
| `## Empirical check` with toolchain, OS, command, working directory, observed output | yes | three legs (macOS stable, macOS 1.96.0, Linux stable), exact commands, exits, per-case observed diagnostics quoted from the logs; planned versus executed distinguished |
| `## Engines` with all reports, disagreements and resolving evidence, uncertainty | yes | both engines with actual models; seven disagreements each settled by an executed case or a fetched document; four uncertainties stated |
| `## Supersedes` | correctly absent | first revision |

Source dates: every external claim carries `retrieved 2026-09-05`. Fitness gates for the adopted tool: license, MSRV (compile `1.93`, runtime current stable and beta), advisory and `unsafe` posture, OS by execution on both legs, features and async coupling inapplicable with reason, size and compile cost stated with measured figures. Excluded by gate: `cargo-check-external-types` with the failing gates; `cargo-public-api` excluded from the required set by the stable-only constraint and kept as the ranked runner-up with its winning condition.

The prompt's five questions are each answered with executed evidence: visibility suffices for reachability (case 03, doctests in case 01); what else is needed against drift (cases 04–06, 09); one root `pub use` block versus scattered re-exports (Rust Book ch. 14.2, axum shape, case 07); a CI-checkable drift tool on stable (cases 09–10 and the runner-up); an internal crate under a published one (case 11).

Empirical sufficiency: the check is not a startup or import test. It has positive controls (02, and the passing doctest in 01), negative controls that name the exact diagnostic (03 `E0603`, 04 `unreachable pub item`, 06 `more private than`, 07 `E0364`), an inverse control isolating the lint's default level (05), a demonstration of the two escape hatches the contributor rules exist for (08), a positive and a negative run of the CI gate on stable with no nightly (09 exit 100, 10 exit 0), and the topology refusal (11).

Consistency with `review/audit-codex.md`: same `decision-sha256`; family `openai`, model `gpt-5.6-terra`, a different family from the synthesizer and from me; the rerun from a fresh `review/empirical-audit/` fixture reproduced `PASS=11`, `PASS=8`, `PASS=11` with all aggregate exits 0 (`review/evidence/audit-public-api-surface-enforcement.log`, 623 lines, toolchains identical to the decision's); it spot-checked six citations and found them supported; verdict approve, no unresolved findings. Nothing in it contradicts the decision or this audit.

## Findings

Unresolved findings: none.

Observations, recorded for the controller; none requires the decision to change before acceptance, and I state for each why I did not promote it:

1. Runner-up gate restatement is partial. The decision restates gates 1, 3 (advisory half), and the maintenance figures for `cargo-public-api`, and gives its exclusion reason (nightly must be installed), but gates 2, 3 (`unsafe` posture: `scripts/lint.sh:14` `--forbid unsafe_code`), 4 (macOS job commented out behind a FIXME; ran on macOS by execution), 5 and 6 are in `raw/opus.md` only. Not promoted because no numbered gate fails in the raw, the decision cites the raw for the figures, and runbook §5 does not require per-candidate gate restatement in the decision. A stricter reading of the role could promote this; if so the fix is a one-row addition, not a change of outcome.
2. The Linux leg ran on `aarch64` (Lima on Apple Silicon) while `ubuntu-latest` runners are `x86_64`. The decision's "executed here on both legs" is accurate for the OS and silent on the architecture. Not promoted because the tool's own CI runs on `ubuntu-latest` and the `x86_64-unknown-linux-gnu` release asset exists (verified above), so gate 4 holds for the CI matrix by the tool's evidence plus execution here.
3. The recommended CI input `baseline-rev` was not exercised; the executed gate used `--baseline-root`. The inputs are verified from `action.yml`, and the decision labels the in-Actions run as planned with the expected pass and fail behavior. Not promoted because the runbook's "must execute" rule is met for the command and the version pin, and no CI exists yet for the template.
4. Ledger housekeeping for the publisher: spec §2 keeps a tool row separate from its pattern row. F015's settled value names `cargo-semver-checks` inside the mechanism description; whether a tool row with `parent: F015` is added is a publication choice, not a decision defect.
5. Runbook §2 asks that actor IDs, resolved models and model families be recorded. `## Engines` gives the actual models and points at `manifest.json`; the raw actors' IDs and families are in `manifest.json` and `operations/*.json` rather than inline. Not promoted because the record exists in the run directory the checker reads.

Not findings, for the record: Codex's `unreachable_pub` warn-by-default citation was wrong and the decision resolved it by an inverse control plus the correct listing; the decision's "map the same three bins" wording glosses over Codex placing `cargo-public-api` in bin 3 and Opus in bin 2, which changes nothing downstream; the decision's caveat that the `rustls` reference was not independently verified can be lifted, since I verified it.

## Assessment

The decision states the shared principle at the right agreement level and honors the binding of F014 as retained and F015 as the open mechanism. It preserves ts's non-bypassable requirement with a justified native design, Rust module privacy plus a single root `pub use` block, and is candid that this is stronger than the ts resolver check in kind while naming the two explicit export mechanisms that can still widen the surface and turning them into contributor rules backed by an executed demonstration. The architecture comparison is real, the tool choice is decided by the stable-only constraint on verified evidence, the runner-up and its winning condition are stated, and the one residual gap (method-level additions on an exported type) is proven rather than hidden. Every required decision field, parameter, gate and source date is present and, where I could re-fetch it, exactly correct. The empirical check demonstrates the principle with positive, negative and inverse controls on three toolchain legs, and the independent Codex rerun reproduced it from a fresh fixture. Approve, with no unresolved findings.
