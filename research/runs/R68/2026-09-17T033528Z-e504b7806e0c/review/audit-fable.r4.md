actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: d07d74abb54cc9fe516b41edbc3e5b163e467808fb6314740537cf9c0f017da8
verdict: reject
unresolved-findings:
1. JF-1 (also weakens JF-10's stated ground). The fat-LTO cost weighing says the build-time cost falls only on once-per-release builds. That contradicts the decision's own statement that `cargo install` builds under this profile.
2. JF-4. The `--debug` fact about R50 is asserted three times with no citation, and R50 is an open, unaccepted item.

# R68 revision 4 — judgment audit (fable)

Target: `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`, revision 4.
Its sha256 was recomputed before reading and again before writing:
`d07d74abb54cc9fe516b41edbc3e5b163e467808fb6314740537cf9c0f017da8`. That value matches the
expected hash. The audit was run on 2026-09-27 as a fresh, independent context.

This audit read:

- the decision;
- `inputs/prompt.md`;
- `research/RUNBOOK.md` §5 (the decision-shape contract);
- `raw/codex.md`, `raw/opus.md` and `raw/doxa-{gemini,openai,perplexity}.normalized.md`;
- `review/evidence/*.log` and the script headers;
- `docs/port/PARAMETERS.md` and `docs/port/COMMONALITY.md`;
- R49's published decision (`research/topics/49-build-target-declaration/DECISION.md`, sha256
  `86b7f925…`, which matches `inputs/prerequisites.json`);
- R67's published decision;
- R50's in-flight run decision, read only to trace one claim.

No `review/audit-*.md` or `review/R68-r*-snapshot.md` file was read. No script was re-run. No
git command or runner command was issued.

## Verdict summary

The recommendation is internally coherent and well evidenced. Every figure spot-checked
re-derives from its cited log or raw report. Two reasoning and traceability defects remain,
and both need prose-only repairs. Neither finding changes a measured direction. Fat LTO still
buys 8.5 percentage points (pp) of binary size on the same stand-in. So the recommendation can
stand once the stated ground is corrected, and W1-R68 would not need re-asking on that
account. Under RUNBOOK §5, acceptance requires approval with no unresolved findings, so the
verdict is **reject**.

## Checks

### JF-1 — internal consistency: **FAIL** (finding 1)

**What is consistent.** Subject A's table, the minimal example, the file-level changes and AC1–AC6
agree with each other. The conditional `[profile.dist]` treatment agrees everywhere: the
"custom profile" row, AC6, the file-level changes and Disagreement 4 all say to trim the stub
only if `dist init` writes one.

**What is inconsistent.** The fat-LTO build-cost argument states that the cost lands only on
once-per-release builds. The decision's own text says otherwise; see finding 1.

### JF-2 — prompt questions and constraints: **PASS, with a note**

Every question is answered:

- Subject A: HIGH ×2, MEDIUM ×2 and LOW.
- Subject B: profile questions 1–6.
- Owner-reference reconciliation: agreement on the record or a stated ground, with the file
  cited by section.

The constraints are honored:

- The Cargo Book is cited with a retrieval date, the defaults, the permitted values, the
  inheritance rule and the override precedence.
- Fitness gate 1 is recorded as `inapplicable` under Q7.B.
- The baseline row is present in the size table.
- The stand-in's composition and how it differs from the template are stated.

**Note.** Profile question 2 asks for measurement "on each OS in the fixed `target-os-matrix`".
Only `aarch64-apple-darwin` was measured. The gap is disclosed under *What is unproven*, with a
proof path for P03. The owner accepted revision 1 with the same gap (`docs/port/OWNER-ACCEPTANCES.md:74`),
under the 2026-09-10 ruling that decisions are "proposals validated in implementation". I
record the gap and do not block on it.

### JF-3 — `## Engines` fidelity and adjudication: **PASS**

The Codex positions were checked against `raw/codex.md` and are faithful:

| Position the decision attributes to Codex | Location in `raw/codex.md` |
|---|---|
| pin line `>=0.32.0, <0.33.0` | line 282 |
| four targets, including `aarch64-unknown-linux-gnu` | line 275 |
| `thin` + one unit + `strip = "symbols"` | lines 311–313 |
| `[profile.dist]` "always builds with profile dist" | line 317 |
| crates.io-only runner-up | line 340 |
| `active` with a backlog caveat; 2 of 10 issues answered, median 0.335 days | lines 180–184 |
| cannot substantiate `0.33.0` | lines 156–158 |
| mention cargo-binstall only after the smoke proves it | line 398 |
| no backtrace measured | lines 315 and 599: no backtrace or frame measurement anywhere |

The Doxa positions were checked against the normalized provider files and are also faithful:

- **Gemini:** `rustc 1.81.0`, a 36.2 MB baseline and "approximately 120 transitive
  dependencies" (lines 103–110). It claims `strip = "debuginfo"` "drops the massive DWARF
  tables … retains function line numbers" (line 122) and cross-compilation "via
  `cargo-zigbuild`" (line 92).
- **OpenAI:** a "settings-free `[profile.dist]` adapter" that dist "generally refuses to run
  without" (line 105), an explicit binstall block (line 231), `strip`/`panic` written
  (lines 247–248), and no build executed (line 13).
- **Perplexity:** the "0.32.0 changelog recommends deleting `[profile.dist]`" claim (line 103).

All thirteen disagreements are adjudicated with evidence, or are explicitly marked unsettled
(Disagreements 4 and 9). Disagreement 1's revision-4 relabelling is correct. Codex's 28.22 s →
47.39 s and 7.35 s → 18.99 s figures are the marginal step from `thin` + one unit to `fat` + one
unit (lines 588–589; restated at line 311 and at line 355). The same disagreement's cost
*weighing* is defective; that defect belongs to JF-1 and JF-10.

### JF-4 — load-bearing claims trace to sources: **FAIL** (finding 2)

These claims were spot-checked and all hold:

**Profile-probe figures**

| Claim | Evidence |
|---|---|
| Size table deltas: −1.3 / −19.8 / −14.9 / −16.0 / −24.5 / +12.9 / +21.8 / −22.9 / 0.0 / −20.2 / +12.5 | `profile-probe.r2.log` lines 59–70 |
| Backtrace table: 4 / 4 / 0 / 2 (exit 134) / 5 frames | `profile-probe.r2.log` lines 86–90 |
| `at ./src/` lines: 2 inside the build tree, 0 after copying out | `profile-probe.r2.log` line 98 |
| Marginal clean build 18 s → 25 s | `profile-probe.r2.log` lines 42 and 44 |
| Every cell of the six-run build-time table | the five kept logs, all matched |
| Clean-build ratio 1.3–1.9× and marginal ratio 1.2–1.6× | recomputed from those logs |
| 171 200 B (−16.0% → −24.5%) | 1 675 728 − 1 504 528 |

**Codex arithmetic**

| Claim | Recomputation |
|---|---|
| 486 592 B, 13.4% | 3 642 912 − 3 156 320, as a share of 3 642 912 |
| `thin` alone −1.7% | 4 452 240 → 4 378 048 |
| 29.04 s → 47.39 s ≈ 1.6× | Codex's figures, `raw/codex.md` lines 584 and 589 |

**Opus figures:** −18.8% for `lto = "fat"` and −24.4% for the recommended row (`raw/opus.md`
lines 463–476). Every row agrees with this item's figures to within 1.0 pp.

**`artifact-sources.log` citations**

| Claim | Location |
|---|---|
| `create-release = false` sentence at config.md line 1277 | log line 30 |
| `ubuntu-latest` count 0 | log line 42 |
| stub at concepts.md line 60 | log line 48 |
| CHANGELOG line 2274 falls under `# Version 0.0.3` | log lines 63–64 |
| SUPPORT.md lines 124 and 148 | log lines 131 and 134 |
| release-please line 217 | log line 159 |
| 23 release assets | log line 91 |
| `cargo install cargo-dist` count 0 | log line 85 |
| registry-gap figures | log lines 179–181 |
| RustSec control | log lines 186–192 |
| `rust_version` values 1.74 and 1.79.0 | log lines 195–196 |

**R49 citations:** R49 lines 889–891 (the A4 winning condition) and 1042–1047 (the re-verify
trigger) say what the decision attributes to them.

**COMMONALITY rows:** lines 78, 218 and 224 are the F072, F214 and F220 rows.

**The failing claim.** The R50 `--debug` fact is cited nowhere; see finding 2.

### JF-5 — couplings hand over owned choices without deciding them: **PASS**

- **R51:** receives a profile-coupling fact (cargo-chef cook layer and final build share one
  profile). R51's container decision is not made here.
- **R50:** receives the observation that its smoke test does not exercise the release profile.
  The decision does not choose R50's mechanism. The unsourced premise of that hand-off is
  finding 2.
- **R22:** receives the version-encoding coupling.
- **R49:** receives its fired A4 re-verify trigger. The decision says explicitly that R49's
  re-check "is R49's to run".
- **F301:** stays open; it appears only as re-verify trigger (6).
- **R69's web binary:** kept out of the archives through dist's `features` default. That is
  this item's own artifact-type question, and R69's feature shape is not re-decided.

### JF-6 — `assumes` lines byte-identical to the registry: **PASS**

All five lines were compared with `docs/port/PARAMETERS.md` column 4 by script:

| Parameter | Characters | Byte-identical |
|---|---|---|
| `build-tool-output-shape` | 1818 | yes |
| `msrv-policy` | 118 | yes |
| `rust-edition` | 4 | yes |
| `target-os-matrix` | 27 | yes |
| `license` | 17 | yes |

The prompt's `- owns:` line is empty, the registry records no R68-owned parameter, and the
decision writes no `- owns` line. All three facts are correct.

### JF-7 — no conflict with accepted or published prerequisite values: **PASS, with a note**

**The tension.** The assumed `build-tool-output-shape` says "Cargo's own manifest is the entire
declaration surface". The decision concedes that `dist-workspace.toml` is "a second
declaration surface in R49's own terms".

**Why this is not a conflict.** R49 itself classified this exact event, "R68 resolves F214 to
cross-compiled release binaries", as a re-verify trigger that makes its runner-up A4 win.
R49 did not classify it as a value change (R49 lines 889–891 and 1042–1047). Handing R49 the
fired trigger is therefore the faithful route, and `CONFLICT: none` is defensible.

**Other prerequisites.** Nothing conflicts with R69's `web-extra-surface` or with R67's
published contract. The decision takes no symbol requirement from R67 and evidences its own.

### JF-8 — evidence scripts exist and claimed counts match: **PASS**

- `artifact-sources.sh`, `profile-probe.sh` and `decision-self-check.sh` all exist and are
  executable.
- Assertion counts match the claims: `artifact-sources.log` and `.r4.log` have 26 each,
  `profile-probe.r2.log` has 21, and `decision-self-check.r4.log` has 28. Every assertion is
  `ok`, and every log ends `RESULT: PASS`.
- `decision-self-check.r4.log` prints `DECISION.md (75710 bytes)`, which equals the audited
  file's size.
- `artifact-sources.r2.log` and `artifact-sources.r4.log` differ only in their `date(UTC):`
  line, as claimed.
- Between `profile-probe.r2.log` and `profile-probe.r4.log`, every `DELTA`, `BACKTRACE` and
  `ASSERT` line is byte-identical. The only `SIZE` difference is `debug = "line-tables-only"`,
  which is +96 bytes, as claimed.
- The r4 build-time row (16 s → 25 s, 18 s → 25 s, 0 s → 12 s) matches `profile-probe.r4.log`
  lines 34, 42, 44 and 103–104.
- cargo-binstall `1.24.0` drift is present in `artifact-sources.r2.log` line 196.

### JF-9 — decision shape follows the published contract: **PASS**

- The H2 headings are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`,
  in that order, and there is correctly no `## Supersedes`.
- `## Decision` carries the recommendation, the version pin `0.33.0`, the settled F214 and
  F220 rows, `### Principles and implementation` and a `re-verify:` line.
- `## Empirical check` states the toolchain, OS, commands, working directory and observed
  output.

### JF-10 — the recommendation follows from the assembled evidence: **PASS on direction; the stated ground is incomplete** (finding 1)

**Subject A** follows from the evidence:

- The follower-mode hand-off was read at both maintainers' sources.
- Archives named after the package, combined with binstall's defaults based on `{ name }` and
  `{ bin }`, justify writing no metadata block.
- The runner-label override is required by dist's source.

**Subject B's key choices** follow from the measurements:

- `opt-level`: both size levels made the binary larger.
- `strip`: `symbols` leaves zero frames, and `debuginfo` is a no-op.
- `panic`: `abort` exits 134 and loses frames.
- `debug`: line tables do not travel with the copied binary.

**`lto = "fat"` over `"thin"`:** the size gain is measured on two stand-ins. The build-time
side of that trade is argued from an incomplete population; see finding 1.

**Minor, not a finding:** "The −20.2% size gain is largely supplied by `lto = "fat"`
already" (the `panic` row) is unmeasured, because no `fat` + one-unit + `abort` row exists. It
does not bear load, because abort is refused on exit-status and frame evidence.

## Findings

### Finding 1 — JF-1 / JF-10: the fat-LTO cost weighing leaves out a population the decision itself names

**The failed claim appears in three places:**

- `## Empirical check`, build-time paragraph: "fat LTO is accepted because the build happens
  once per release while the download happens once per user, and because the incremental
  penalty lands only on `--release` rebuilds, which neither the contributor loop (dev profile)
  nor R50's install smoke test (`--debug`) performs."
- `## Engines`, Disagreement 1: "the extra build time falls on a release build that runs once
  per release and on `--release` rebuilds, which neither the contributor loop (dev profile)
  nor R50's install smoke test (`--debug`) performs, while the size gain lands on every
  download."
- The owner-reference reconciliation row for `lto = "thin"`: "falls on a build that runs once
  per release".

**The contradicting evidence is in the same file:**

- The S1 row of the architectural-alternatives table says "every user pays a full optimised
  compile — and this item's own profile recommendation makes that compile *more* expensive,
  since `cargo install` builds under the package's `release` profile".
- The README change under *File-level changes* says the profile "governs this repository's
  builds and `cargo install`".
- README install path (3), `cargo install --locked rs-launch-blueprint`, is a documented,
  supported channel.
- A second affected population follows from the decision's own design. Users on any target
  outside the three shipped triples get no pre-built archive. That includes Windows,
  ARM Linux and musl, which the decision excludes. Binstall falls back to its `compile`
  strategy for these users, and they also compile under `lto = "fat"` + `codegen-units = 1`.

**Why this fails.** The trade-off is argued as a release-time cost against a gain on every
download. But the decision's own text establishes a per-user compile cost for every source
installer. That cost is measured here as a clean-build marginal of about 1.2× to 1.6× over the
owner reference's row (the `thin` + cu1 column of the build-time table), and about 1.3× to 1.9×
over Cargo's defaults. The weighing never states this cost or accepts it, so the ground given
for rejecting the owner reference's `lto = "thin"` is incomplete.

**Repair (prose only):**

1. In all three locations, name the source-install population on the cost side: `cargo install`
   users and binstall `compile`-fallback users on unshipped targets.
2. Attach the measured marginal clean-build figure (1.2×–1.6×; 18 s → 25 s in
   `profile-probe.r2.log`).
3. State why that cost is accepted, for example: the three shipped triples cover the default
   audience, and source installers pay a one-time compile per version.

The size direction is not affected, since `fat` still buys 8.5 pp over `thin` + one unit. I
therefore judge that the recommendation stands, and this repair alone does not require
re-asking W1-R68.

### Finding 2 — JF-4: R50's `--debug` is asserted three times with no source, and R50 is unaccepted

**The failed claim:**

- `## Decision`, the hand-off to R50: "its install smoke test builds with `--debug` and
  therefore does not exercise this profile at all".
- The build-time paragraph: "R50's install smoke test (`--debug`)".
- Disagreement 1: the same parenthetical.

**Evidence.** None of the three statements cites a file. `research/CLAUDE.md` line 55 lists R50
as `open`, and no `research/topics/50-install-smoke-test/DECISION.md` exists. The fact traces
only to R50's in-flight run decision:
`research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md`, revision 5. Lines 7,
100, 301 and 399 of that file choose `--debug`, and that value is not accepted and can still
change. Two statements are premised on it:

- the claim that the incremental penalty lands on no CI path;
- the hand-off's claim that "nothing in pull-request CI proves the release profile links".

**Repair.** Cite R50's run decision by path, revision and line. Label the value as R50's current
unaccepted proposal. Make the hand-off conditional on R50 keeping `--debug`, and add R50's
acceptance or a change of its build profile as a re-verify trigger or coupling note. This
repair shares its sites with finding 1, so both can be made in one edit.
