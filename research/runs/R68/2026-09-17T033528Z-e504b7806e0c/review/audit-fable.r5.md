actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 10a6a71bda644a93a8aa667e34a90b11b5c4f890b40366ba23b464ead0010b41
verdict: reject
unresolved-findings:
1. JF-5-1 — the `features` row states an outcome R51 owns as settled fact (DECISION.md line 139, restated as the only ground at lines 345–348).

# R68 release-binary-artifacts — judgment audit, revision 5

- Target: `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`, revision 5.
- Hash: recomputed with `shasum -a 256` before anything else was read or written. It equals the expected `10a6a71b…0b41`. The file is 81 401 bytes.
- Date: 2026-09-27.
- Scope: judgment and fidelity only. No evidence script was re-run. Scratch work used `/tmp` only.
- Read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §4–§6; `raw/codex.md`, `raw/opus.md` and the three `raw/doxa-*.normalized.md` files; the prerequisite `research/topics/49-build-target-declaration/DECISION.md`; the cited R67 and R69 topic decisions; the R50 run decision; the R51 prompt; `docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md`; the evidence logs under `review/evidence/`.
- Not read: no `review/audit-*.md` file of any seat or revision, and no `review/R68-r*-snapshot.md` file. The only exception is one `shasum` of `R68-r4-snapshot.md`, which checked the digest the revision note states without reading the content.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | See the JF-1 section below. |
| JF-2 every question answered, every constraint honored | pass | See the JF-2 section below. |
| JF-3 `## Engines` faithful, disagreements adjudicated | pass | See the JF-3 section below. |
| JF-4 load-bearing claims trace to sources | pass | See the JF-4 section below. |
| JF-5 couplings hand over owned choices without deciding them | **fail** | See finding JF-5-1. Every other hand-off (R49, R50, R22, and the R51 profile coupling) is compliant. |
| JF-6 `assumes` lines byte-identical to the live registry | pass | See the JF-6 section below. |
| JF-7 no conflict with accepted or published prerequisite values | pass | See the JF-7 section below. |
| JF-8 evidence scripts exist and claimed counts match | pass | See the JF-8 section below. |
| JF-9 decision shape follows the published contract | pass | See the JF-9 section below. |
| JF-10 the recommendation follows from the evidence | pass | See the JF-10 section below. |

### JF-1 — internal consistency (pass)

- **Size deltas.** I recomputed every row of the size table from its byte counts. All twelve deltas are correct, for example:
  - `fat+cu1`: 489 504 / 1 994 032 = −24.5%;
  - `thin+cu1`: −16.0%;
  - the difference between those two rows is 171 200 bytes.
- **Threshold margins.** The stated margins hold: 4.5 pp, 4.0 pp, 3.7 pp and 7.9 pp.
- **Build-time ratios.**
  - The six clean-build ratios fall in 1.33×–1.88×. The decision states "1.3× to 1.9×".
  - The five marginal `thin`→`fat` ratios fall in 1.20×–1.58×. The decision states "1.2× to 1.6×".
  - Codex's ratios are 1.68× (28.22 s → 47.39 s), 2.58× (7.35 s → 18.99 s) and 1.63× (29.04 s → 47.39 s).
  - Codex's `fat` + one-unit binary is 486 592 bytes smaller than its `thin` + one-unit binary, which is 13.4% of the latter.
- **The seven dist settings.** The count of "seven settings tabulated above" at line 350 matches the rows of the dist table.
- **Recommendation and weighing agree.** The recommendation and its fat-LTO cost weighing are stated identically in three places: the reconciliation row, the `## Empirical check` build-time paragraph, and Disagreement 1.
- **Non-blocking observation.** Disagreement 9 (line 826) says the decision "carries no numeric clean-build claim". Lines 201 and 597, however, do cite the marginal clean range, 1.2×–1.6×. I read line 826 as referring to the baseline→recommended ratio ("roughly doubles"). The marginal figure is reported as a range with its spread, as line 674 promises. No outcome turns on the figure, so this is not a finding. A one-word qualifier ("no single-ratio clean-build claim") would remove the ambiguity.

### JF-2 — every question answered, every constraint honored (pass)

- **Subject A.**
  - HIGH questions 1 and 2 are answered by the maturity paragraph, follower mode, and the binstall row.
  - MEDIUM question 3 is answered by the three triples and the ARM exclusion.
  - MEDIUM question 4 is answered by row S1 and the second runner-up.
  - LOW question 5 is answered, though thinly. Gate 6 says the cost is "N parallel build jobs added to the release path only". The S4 row lists the complexity costs. The decision implicitly ships by default rather than deferring to an opt-in.
- **Subject B.**
  - Profile questions 1–6 are answered by the key table and the statement of each Cargo default.
  - Measured size and time come with toolchain and date.
  - The missing `ubuntu-latest` measurement is disclosed under *What is unproven*, with a proof step assigned to P03.
  - The `strip`/`debug`/`panic` trade is answered and backed by backtrace measurements.
  - Splitting profiles is answered: no custom profile, with the cache-separation and divergence costs stated.
  - Inheritance for downstream crates is answered: "Profile settings defined in dependencies will be ignored".
  - MSRV is covered at lines 429–431.
- **Constraints.**
  - Licence gate 1 is recorded as `inapplicable` under Q7.B.
  - The owner reference is reconciled row by row and cited by section.
  - Fixed parameters override the reference's `rust-version` and `edition`.
- **Landscape and shortlist fields.** The Landscape, Qualified shortlist and Up-and-comers fields belong to the raw-answer template. RUNBOOK §5 does not require them in `DECISION.md`, and most published topic decisions omit them.

### JF-3 — `## Engines` is faithful and adjudicates every disagreement (pass)

Each engine's positions were checked against its raw report:

- **Codex.** The positions at lines 703–710 match `raw/codex.md`: 12 direct dependencies and 162 locked packages (lines 118 and 123); the 1.96.0 floor (lines 577–580); the approved line `>=0.32.0, <0.33.0` (line 282); four targets including `aarch64-unknown-linux-gnu` (line 275); `strip = "symbols"`; `[profile.dist] inherits = "release"` with the quote "always builds with profile dist" (line 317); runner-up crates.io-only (line 340); "active … not at-risk" with a median of 0.335 days (lines 183–184); and "cannot substantiate 0.33.0" (line 158).
- **Doxa/OpenAI** recommends `lto = "thin"` (line 245) and writes `strip = "none"` and `panic = "unwind"` (lines 247–248). It proposes four targets (line 215) and a settings-free `[profile.dist]` (line 263). It states that it executed no build (line 13).
- **Doxa/Perplexity** recommends `thin` (line 212). It attributes the "delete `[profile.dist]`" advice to 0.32.0 (line 103). It executed no build (line 170).
- **Doxa/Gemini** cites `rustc 1.81.0`, 36.2 MB and "approximately 120 transitive" (lines 103–110). It writes `strip = "debuginfo"` (line 122) and claims cross-compilation "via `cargo-zigbuild`" (line 92).
- **Opus.** Its census is "3 of 18" (line 94), its issue sample is "10 of 10" unanswered (line 221), and its size table is at lines 463–476. On every row, Opus's figures fall within 1.0 pp of the decision's.

All thirteen disagreements are adjudicated with cited evidence or labelled unresolved. Disagreement 4 records one question as unresolved: whether dist requires the `[profile.dist]` stub. Disagreement 9 labels the clean-build ratio "Not settled".

### JF-4 — load-bearing claims trace to sources (pass)

Every citation below resolved and supports its claim:

| Source | What was checked |
|---|---|
| R49 `DECISION.md` | Lines 889–891 hold the A4 winning condition. Lines 1042–1047 hold the re-verify trigger and the deprecation re-check. |
| R50 run decision, revision 6 | Lines 7, 116 and 335 cite `--debug`. Line 433 cites the dev profile. Line 564 is trigger (13), naming R68. Line 981 names R68's release build as the only release-profile compile the template performs. |
| `raw/codex.md` | Lines 311, 584 and 588–589. |
| `profile-probe.r2.log` | Lines 42, 44 and 102–104. |
| `COMMONALITY.md` | Line 78 is F072, `create-github-app-token v3.2.0`. Line 218 is F214. Line 224 is F220. |
| `artifact-sources.log` | Section C: the line-1277 undraft sentence, `ubuntu-latest` = 0, the `ubuntu-22.04-arm` label, `concepts.md` lines 60–62, CHANGELOG line 2274 under `# Version 0.0.3`, zigbuild 0 in the configuration reference and 1 guard in the CI backend, and `cargo install cargo-dist` = 0. Section D: 23 assets. Section E: `SUPPORT.md` lines 148–149 and 124. Section H: 2115 stars, 19 585 and 176 744 downloads, 297 open issues. Section I: the 0.33.0 error body. Section J: 404 against the 200 controls. Section K: `rust_version` 1.74 and 1.79.0. |
| R67 exit taxonomy | The taxonomy (`0–5`, `130`, `143`) excludes both 101 and 134. The R7.7 flush requirement is at R67 line 93. |

The R50 citations are path, revision and line with no digest pin. The brief says this is by design, and it was judged only on whether the citations resolve and support the claims. They do.

### JF-5 — couplings hand over owned choices without deciding them (fail)

This check fails on one sentence; see finding JF-5-1. The other hand-offs comply:

- **R49:** the fired A4 trigger. "That re-check … is R49's to run."
- **R50:** conditional on R50's unaccepted proposal, with trigger (7).
- **R22:** the version encoded in archive names.
- **R51:** the profile and cargo-chef coupling, stated only as a coupling.

### JF-6 — `assumes` lines byte-identical to the live registry (pass)

All five `- assumes` values were parsed from the decision. Each is byte-identical to column 4 of its `docs/port/PARAMETERS.md` row. They match both the working-tree registry and the `HEAD` registry.

### JF-7 — no conflict with accepted or published prerequisite values (pass)

- R49 `DECISION.md` hashes to `86b7f925…d948` and `acceptance.json` hashes to `3295e8a0…3157`. Both equal the values in `inputs/prerequisites.json`.
- R49's target names, allow-list and `target/` layout are consumed unchanged.
- The decision's reason for recording no `CONFLICT` line holds: dist is a host executable, not a build-orchestration crate.

### JF-8 — evidence scripts exist and claimed counts match (pass)

- `artifact-sources.sh` exists. `artifact-sources.log` shows 26 of 26 `ASSERT ok`.
- `profile-probe.sh` exists. `profile-probe.r2.log` shows 21 of 21 `ASSERT ok` and `RESULT: PASS`.
- The `TIME` lines of all five kept probe logs reproduce the build-time table exactly: 17/18/23 with 1/11; 17/18/25 with 1/12; 16/19/30 with 1/13; 18/20/24 with 1/12; 16/18/25 with 0/12.
- `decision-self-check.sh` exists. `decision-self-check.r5.log` shows 29 of 29 `ASSERT ok`, and its printed byte count (81 401) equals the live file.
- `R68-r4-snapshot.md` hashes to the stated revision-4 digest `d07d74ab…7da8`.

### JF-9 — decision shape follows the published contract (pass)

- The H2 set is `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in that order.
- `### Principles and implementation` sits under `## Decision`, along with the `re-verify:` line.
- There is no `## Supersedes` section, which is correct because no revision was ever published.
- This matches RUNBOOK §5.

### JF-10 — the recommendation follows from the evidence (pass)

- **Subject A.**
  - The two channels and dist in follower mode follow from the only shape that fills one release from both sides.
  - The three targets follow from the fixed runners.
  - Writing no binstall metadata follows from binstall's documented `{ name }`/`{ bin }` defaults.
- **Subject B.**
  - `fat` + `codegen-units = 1` follows from the measured −24.5% against −16.0%, with the cost weighed explicitly.
  - Leaving `strip`, `panic` and `debug` silent follows from the backtrace, exit-status and travel measurements.
  - Leaving `opt-level` silent follows from the measured size increases.
- The runner-up ranking follows from the `$bin-$target` naming mismatch.

## Finding JF-5-1

**The failed claim.** DECISION.md line 139, in the ground column of the `features` / `default-features` / `all-features` row, reads:

> "so the `web`-gated second binary R69 adds is **not** built into the release archives; the web surface's delivery vehicle is R51's container image"

The "Fit, per surface" *Web* paragraph (lines 345–348) repeats the disposition as "the right disposition". It gives no other ground.

**The evidence.**

- **R51 owns exactly this outcome, and has not decided it.**
  - The R51 prompt, line 30, states the decision as "*whether* `rs-launch-blueprint` ships a container image as a distribution artifact for its optional web-service build".
  - Its LOW question (line 35) asks whether an image is published at all, or "only documented as an optional Dockerfile a fork can build on demand".
  - F223 (`docs/port/COMMONALITY.md:227`) is `DIVERGENT`, assigned to item R51, and unsettled.
  - `research/CLAUDE.md` lists R51 as `open`. Its only material is an unpublished run under `research/runs/R51/`.
  - R68's own prompt makes the container question R51's (Out of scope, line 18).
- **The owner-review row is not a ruling.** The `docs/port/OWNER-REVIEW.md` R51 row (line 278) is the 2026-09-04 cross-repository harmonisation codesign. It does not rule on F223.
- **R69's wording is not authority.** R69's accepted decision uses the same presumption at line 1087 ("the shape R51's container image expects"). That is R69's wording and settles nothing about F223. This finding does not challenge R69.
- **The sentence is load-bearing.** It is the only stated reason for keeping the web binary out of the release archives.
- **No re-verify trigger notices R51's outcome.** Triggers (1)–(7) cover dist, R49, the MSRV, the matrix, F301 and R50. None fires when R51 resolves F223 to "no image" or "documented Dockerfile only". In that case the web surface would have no pre-built channel, and this decision would not notice.

**The repair.** The repair is prose only, and the recommendation does not move.

1. Reword the line-139 ground, and the matching *Web* paragraph, to be conditional. For example: "if R51 ships a published container image, that image is the web surface's pre-built delivery vehicle; otherwise the web binary is reachable only by a source install with `--features web`, and this row re-opens."
2. Add re-verify trigger (8): R51 resolving F223 to anything other than a published image.

The exclusion itself may stand on its own ground: the fixed CLI audience and archive scope. Stated that way, it would no longer depend on R51. Owner acceptance `W1-R68` would not need re-asking.
