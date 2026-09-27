actor: audit-fable-s32-r22r5
model: claude-opus-5-5
family: anthropic
decision-sha256: 6094af5a98bd4b18066be9431adfa91295683e0045fe86951f974c4b2c1f65bb
verdict: approve
unresolved-findings: none

# Judgment audit — R22 runtime-version-accessor — decision revision 5

Target: `research/runs/R22/2026-09-17T020715Z-d93731e7353c/review/DECISION.md`.
Its sha256 was recomputed with `shasum -a 256` before reading and again
immediately before writing. Both times it equalled the expected
`6094af5a98bd4b18066be9431adfa91295683e0045fe86951f974c4b2c1f65bb`.

Read: the decision; `inputs/prompt.md`; `inputs/prerequisites.json`;
`research/RUNBOOK.md` §2 and §5 (the auditor contract and the decision shape);
`raw/codex.md`; `raw/evidence-terra.md`; the four evidence logs, the header of
`r22-cargo-probe.sh`, `snapshots/MANIFEST.txt` and the cited snapshots;
`research/topics/49-build-target-declaration/DECISION.md` and its
`acceptance.json` (hashes only, compared with `prerequisites.json`);
`research/topics/60-cli-parsing-framework/DECISION.md`, from which the decision
quotes; the R69 and R01 lines that the decision quotes; `docs/port/PARAMETERS.md`;
`docs/port/COMMONALITY.md`; `docs/port/BASELINE-REVIEW.md`; and
`docs/port/OWNER-REVIEW.md`.

Not read, as the audit brief forbids: every `review/audit-*.md` and every
`review/R22-r*-snapshot.md`. No git write, no runner command and no paid API
was used. No script was rerun, because the empirical audit reruns them. The
logs, snapshot hashes and diffs were spot-checked read-only.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | The recommendation (`pub const VERSION: &str = env!("CARGO_PKG_VERSION")` in `src/lib.rs`) is stated identically in `## Decision`, in the reference snippet and in `## Parameters`. The gate verdicts in the candidate table (`:273-279`) agree with the maintenance paragraph, the `shadow-rs` paragraph, Engines findings 1–3 and the gap list: `built` and `vergen-gix` pass on the crate itself only, and `shadow-rs` is excluded by gate 3 on its dependency tree. The revision-5 note says the only residual gap for the crate figures is the missing snapshot and assertion. That matches the first gap bullet (`:893-896`). The check counts 24 + 75 + 10 = 109 match the E1–E3 rows and the `:553` total. The `:636` claim "line 95 pre-fix / line 102 now" is right: the probe's `OUT1=` read is at line 102, below the 7 added lines 13–19. |
| JF-2 prompt questions and constraints | pass | HIGH Q1: `env!` substitutes for the runtime lookup. The one capability it lacks, versioning a dynamically loaded plugin, is stated as a limit with a re-verify trigger (`:229-237`). "Installed on disk versus compiled in" is answered by principle 3 and C3/C4. HIGH Q2: web staleness and multiple binaries (`:251-263`). The decision labels that paragraph as reasoning and says no deployment experiment was run. MEDIUM Q3: no crate is needed, only a library constant (`:265-279`, `:328-355`). MEDIUM Q4: `tests/version_consistency.rs` covers the accessor half only (`:372-378`). LOW Q5: provenance is R60's (architecture B row `:206`, rav1e layering `:391-399`, `:860`). Survey steps 1–4 appear at `:172-197` and `:380-399`. Every fitness gate is answered, or marked inapplicable with its reason: gate 1 cites the Q7.B ruling (`OWNER-REVIEW.md:47`), and download columns are `inapplicable` for the built-in. Crate figures come from the required endpoints. The BASELINE-REVIEW and CONFLICT conventions are honoured. |
| JF-3 Engines represents each engine and adjudicates disagreements | pass | The codex report is characterised accurately. I checked the quoted gate-2 clause against `raw/codex.md:52`, the RustSec "not independently verified" wording against `:52-54` and `:115`, the `shadow-rs` "pending advisory verification" wording against `:53`, the line anchors against `:8`, `:44` and `:46`, and the OpenTelemetry claim against `:13`. Each of Terra's disagreements with the decision is adjudicated with evidence: (a) the rustc-env Note is accepted, and finding 4's Cargo Book bullet is withdrawn with the Note quoted verbatim; (b) "cannot prove an advisory-free dependency tree" leads to crate-only qualification of the gate-3 passes; (c) Terra's `built` gate-2 "Verified" (`evidence-terra.md:85`, `:93`) is overruled with the floor derivation and R60's corroboration. Terra's three defects agree with the corrections the decision made itself. I spot-checked the repository-figure table against Terra `:126-128` and `:144-146`: stars, `archived`, `pushed_at`, the `total_count` values 8/8/4, the medians 0.1515/3.915/0.2265 and the unanswered counts 0/5/2 all match. The re-derived `built` median, (0.120 + 0.183) / 2, is 0.1515. |
| JF-4 load-bearing claims trace to sources | pass | Snapshot reads: `arrow-lib.rs.txt:412` is `pub const ARROW_VERSION: &str = env!("CARGO_PKG_VERSION");`. `rav1e-lib.rs.txt:54` is the `built.rs` include and `:216` is `env!("CARGO_PKG_VERSION").to_string()`. `clap-builder-macros.rs.txt:14` is `#[cfg(feature = "cargo")]`, `:16` is `macro_rules! crate_version` and `:18` is `env!("CARGO_PKG_VERSION")`. The CLI Standard excerpt has R4.1 `--version`/`-V` in the required global core and the R4.6 SemVer-without-`v` wording. Live-document quotes: R60 `:1258` (`-V` reads `Command::version`); `:1262-1269` (`disable_version_flag = true`, plain boolean); `:1284` ("R22's decision … both satisfy the `MUST` identically"); `:1363` (the "eleven minors of headroom" sentence and the "R22 … resolving and changing where the version value comes from" trigger). Ledger rows are at `COMMONALITY.md:69/70/139/271`. The "Assertion retained" row is `BASELINE-REVIEW.md:250`. R01's `Arc<dyn ProjectsPort>` and R69's `[[bin]] … required-features = ["web"]` are present in the published text and the registry. |
| JF-5 couplings hand over owned choices | pass | F267 and the `--version` rendering go to R60. The reference snippet only feeds `Command::version` and keeps R60's `disable_version_flag = true`, which R60 leaves unspecified at the version-value slot (`:1284`, `:1395-1397`). The lockfile half of F133 goes to R23 and the manifest half to its own row. Workspace topology goes to R02 as a re-verify trigger. The web binary goes to R69. The R49-versus-R60 `build.rs` tension is recorded as outside this item's scope, with no `CONFLICT:` line and no ruling. |
| JF-6 assumes lines byte-identical to the live registry | pass | A Python byte-compare of each `- assumes <param> = <value>` line against column 4 of `docs/port/PARAMETERS.md` returned True for all 5 lines (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `build-tool-output-shape`; the last is 1818 characters). The working tree's uncommitted `PARAMETERS.md` diff touches only R11's `ci-job-structure` row. There is no `owns` line, which matches `owns:` being empty in the prompt, and no `CONFLICT:` line. |
| JF-7 no conflict with accepted or published prerequisite values | pass | `research/topics/49-build-target-declaration/DECISION.md` has sha256 `86b7f925…` and its `acceptance.json` has `3295e8a0…`. Both equal `inputs/prerequisites.json`. The recommendation needs no `build.rs`, one `[lib]` and one package, all consistent with R49's value. It is also consistent with R60's accepted clap feature set, because it avoids the `cargo` feature, and with R60's JSON path. It is consistent with R69's additive `web` feature as well. |
| JF-8 evidence scripts exist and counts match | pass | All three scripts and four logs are present. The summary lines read `CHECKS RUN: 24 PASS: 24`, `75/75` and `10/10`, and the archive log carries `75/75` and `24/24`. `shasum -a 256 -c snapshots/SHA256SUMS.txt` reported 25 files with 0 non-OK entries, which matches A1a's "25 snapshots". I diffed the archive log's sections against the committed logs with `run-started-utc` filtered out. The sources section differs on exactly `A0b`, `A6i`, `A6j` and `A11d`, and the probe section differs only on the two `rustc`/`cargo` 1.98.0→1.98.1 lines, as E4 and `:689-706` state. `raw/codex.md` hashes to `6ebf723a…`, the registered name. The manifest records `gpt-5.6-luna` and `codex-cli-0.154.0`. The probe's `unset CARGO_TARGET_DIR CARGO_BUILD_TARGET_DIR CARGO_BUILD_TARGET` is at line 18. `MANIFEST.txt` records the Cargo Book excerpt as completed on 2026-09-27. |
| JF-9 decision shape | pass | The H2s are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in that order. There is one H3, `### Principles and implementation`, inside Decision, and exactly one `re-verify:` line (`:448`). Decision names the settled row (F064) with its ledger line. There is no `## Supersedes`, which is correct for a revision that does not reverse the recommendation. Empirical check states toolchain, OS, working directory, commands and observed output (RUNBOOK §5). |
| JF-10 recommendation follows from the evidence | pass | Runtime lookup has no Rust implementation (C4b and the absence of any installed-package registry). Architecture B binds at compile time too (A6h) and needs a `build.rs`, which R49 forbids. Both clap paths reduce to `CARGO_PKG_VERSION` but bind the value inside the CLI crate, where the library and the web surface cannot read it (A6a–A6e). Feature invariance and a failing accessor-equality test were measured (C5 and C6/C7). A single library constant is the smallest design that satisfies every principle, and two pinned practice references (Arrow and rav1e) show the same shape. |

## Notes (non-blocking; not findings)

1. Principle 2 says that exactly one symbol evaluates to the version. The
   decision also says that R60's JSON version object "already sources its
   `version` field from `CARGO_PKG_VERSION`" and that this confirms R60. A
   direct `env!` in `main.rs` would be a second evaluation site. The same
   package produces the same bytes, so nothing can drift. P03 should still
   route that field through `rs_launch_blueprint::VERSION`, as the clap
   paragraph already does for `Command::version`.
2. The adopter entry for `built` cites A5f. A5f shows only rav1e including a
   generated file named `built.rs`; it does not show rav1e's `Cargo.toml`
   build-dependency on the `built` crate. The entry is non-load-bearing,
   because `built` is rejected on fit.
3. The prose at `:882-883` says each median "covers every open issue". For
   `shadow-rs` and `vergen-gix`, however, the median covers only the answered
   issues, and the unanswered ones are counted in their own column. It is
   non-load-bearing.
4. The decision says R4.6 "requires" SemVer without a leading `v`. In R4.6 the
   `MUST` sits on the JSON `version` field, and the line format is `SHOULD`.
   The accessor satisfies both, so nothing changes.
5. Gate 4's "Windows support noted" gets no Windows statement for the selected
   mechanism, which is a target-independent `rustc` macro. Windows is not
   required.
