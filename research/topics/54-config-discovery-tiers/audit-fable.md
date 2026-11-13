# Judgment audit — R54 config-discovery-tiers — revision 5

actor: audit-fable-s32-r54r5
model: claude-opus-5-5
family: anthropic
decision-sha256: 7b5074c18b8d42d99458c73e4dfd5ed060993a1f18f56fa9f32e733b7ecaa9fe
verdict: approve
unresolved-findings: none

## Scope and method

Target: `research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md`,
revision 5. Before reading anything else, I recomputed its hash with `shasum -a 256`
on 2026-09-27. It equals the expected value above, so this audit covers exactly that
file.

Read in full or at the cited lines:

- the decision (1,071 lines);
- `inputs/prompt.md` and `inputs/prerequisites.json`;
- `research/RUNBOOK.md` §4–§5 (the decision-shape and audit contract);
- `docs/planning/p02/acceptance-schema.md`, `revision-rules.md` and
  `judgment-revision-addendum.md`;
- the raw reports `raw/muse.md`, `raw/opus.md`, `raw/doxa-openai.normalized.md`,
  `raw/doxa-perplexity.normalized.md` and `raw/doxa-gemini.normalized.md`, at the
  lines the decision cites;
- the prerequisite and sibling decisions under `research/topics/`: R67, R55, R57,
  R53, R52 and R60;
- `docs/port/PARAMETERS.md`, `COMMONALITY.md`, `BASELINE-REVIEW.md` and `README.md`;
- the evidence logs, scripts and snapshots under `review/evidence/`, spot-checked
  and not rerun.

Per my brief, I did not read any `review/audit-*.md` file or any
`review/R54-r*-snapshot.md` file. I made no git writes, ran no
`scripts/research_runner.py` command and called no paid API. Every scratch script
was written under `/tmp`.

This audit judges reasoning and fidelity. A separate empirical audit reruns the
scripts.

## Results

| Check | Result |
|---|---|
| JF-1 internal consistency | pass |
| JF-2 prompt coverage and constraints | pass |
| JF-3 engine fidelity and adjudication | pass |
| JF-4 load-bearing claims trace to sources | pass |
| JF-5 couplings hand over owned choices | pass |
| JF-6 `- assumes` lines byte-identical to the registry | pass |
| JF-7 no conflict with prerequisite values | pass |
| JF-8 evidence scripts exist and counts match | pass |
| JF-9 decision shape follows the contract | pass |
| JF-10 recommendation follows from the evidence | pass |

### JF-1 — internal consistency: pass

- **The rung table agrees with the rest of the decision.** The six-rung table
  (`:158-165`) matches J1–J4, C1–C6, A2′, AC1–AC12 and the coupling bullets.
- **The system-tier order is stated the same way throughout.** "First entry highest"
  in the table, the last-to-first fold (`:340-345`) and AC2 all agree.
- **The `--config` collapse is stated the same way throughout.** Rungs 3–5 collapse
  to one file while rungs 1, 2 and 6 stay (`:178-182`). AC4 and AC5 say the same.
- **The group counts in `check-r5.sh` add up.** The groups are `B`=18, `T`=22,
  `N`=5, `R`=4, `Q`=1, `U04r5`=1, `P`=5 and `E`=7. Their sum is 63, which equals
  the stated "63 checks, 63 PASS".
- **The `B` group accounts for every carried file.** It covers fifteen files by
  sha256 (5 from revision 1, 5 from revision 2 and 5 from revision 3), the
  snapshot digest and the two revision snapshots, for 18 checks.
- **The MSRV arithmetic is right.** The floor is 1.96, from stable 1.98 minus two
  minor versions. `etcetera` declares 1.87.0, so it clears the floor by nine minor
  versions.
- **The revision history agrees with git.** Revisions 2 and 3 are dated 2026-09-18.
  Git records `0bce85f7`, `3ee43ee5` and `5c9abc97` on 2026-09-18 at -07:00.

### JF-2 — every prompt question answered and every constraint honoured: pass

- **HIGH, a crate that enumerates system directories.** The decision answers no for
  `etcetera`, `directories` and `dirs` (`E01`, `E05`), and yes for `xdg` 3.0.0
  (`X02`–`X04`). Rung 5 is hand-rolled on `std`, and J3 labels that choice a
  judgement.
- **HIGH, the principle, the scopes and the precedence.** `R5.1` and `R5.2` are
  quoted verbatim, and the order is evaluated against them. The comparison of a
  library against custom code is A1–A5.
- **HIGH, the tests.** AC1–AC11 cover discovery, merging, precedence, missing files
  and XDG handling. AC12 (`:421`) covers invalid values and corrupt files with all
  three tiers populated.
- **AC12 matches R55.** I read R55's criteria 4 and 5 at
  `research/topics/55-config-error-tolerance/DECISION.md:398-403`. AC12's fallback
  to the user tier is criterion 5's "falls back to the next valid lower-precedence
  value". AC12(b) is criterion 4's "leaves the other layers active". AC12 adds no
  behaviour, so R55's ownership (named in the prompt's out-of-scope list) is kept.
- **HIGH, cross-repo agreement levels.** The C1–C6 table separates what must agree
  from what may vary. A5 labels the ts single-tier shape as drift. The C6 paragraph
  names the one justified ecosystem difference, the merge implementation.
- **MEDIUM, the walk-up.** `Path::ancestors`, hand-rolled. J4 sets the boundary
  rule, and the probe executes it.
- **MEDIUM, the env alias.** The alias is the `clap` `env` attribute plus one
  emptiness filter. `C01`–`C03` support this.
- **LOW, published templates.** None was found (`:395-402`).
- **Constraints.** The stack is stable Rust and edition 2024. Gate 1 is recorded as
  `inapplicable` under Q7.B, as the standing rules require.
- **Figures.** They carry endpoints and retrieval dates. For `etcetera`, the
  decision defers the gates and the remaining figures to R57, which selected the
  crate. I checked that R57 records them: 2 open issues and the median response
  time are at R57 `:372`. Opus also records `total_count=2` at `raw/opus.md:625-626`.

### JF-3 — `## Engines` represents each engine and adjudicates every disagreement: pass

- **All seven report hashes in the engine table match the files.** The files are
  `muse.md`, `opus.md`, `doxa.md`, `doxa.normalized.md` and the three twins.
- **Muse positions match their citations.** Spot-checked:
  - `:125-127`, the rejection of "two crates where one plus ten lines suffices";
  - `:180-184`, the LOW answer naming Cargo and ruff;
  - `:195-197`, no `BASELINE-REVIEW:` line;
  - `:199-211`, the stack agreement;
  - `:312-315` and `:634-636`, `etcetera` in the library crate (Disagreement 9);
  - `:501-513`, the unqualified `.git`/`Cargo.toml` stop (Disagreement 8);
  - `:192`, `:420` and `:455`, `--show-origin` (Disagreement 10);
  - `:626-630`, cross-item assumptions that omit R57;
  - `:328-330`, the "align, do not fork" trigger.
- **Opus positions match their citations.** The "recursively partial" constraint is
  at `:1017`, the disposition "(a)" at `:1019`, R55 cited at revision 1 at `:1219`,
  "No `CONFLICT:` line" at `:597` and elsewhere, and the "future R5.7" mention at
  `:919-920`.
- **Doxa/OpenAI positions match their citations.**
  - The "Do not add `directories`, `etcetera`, or `xdg`" quotation is at `:285`.
  - "No `CONFLICT:` identified" is at `:775`.
  - `:27` holds the claim that no template was found.
  - Its answer-level `owns` lines run `:745-759`, eight in total, named as the
    decision says.
  - Its member-level `owns` lines are exactly `398-401`, `536-539` and `678-681`,
    twelve in total.
  - "toward the filesystem root" is at `:63`.
- **Doxa/Perplexity positions match their citations.** `ConfigTier::Local` and
  `system < local < user < project < env < CLI` are at `:87` and `:145`. "reaches
  the filesystem root" is at `:93`. "no `CONFLICT:` lines are required" is at
  `:481`.
- **Doxa/Gemini positions match their citations.** Both phrases of the
  self-contradiction are present: "until a project marker is identified" at `:32`
  and "terminating only when the root of the filesystem is reached" at `:199`. The
  twin contains no `CONFLICT` string, and it recommends `etcetera` "0.12" at
  `:149` and elsewhere.
- **Every disagreement is settled on cited evidence.** There are ten:
  1. R55's published loader and R53's per-key loop (`D01`–`D08`);
  2. scope, plus `A01`/`A02` against `R5.4`'s curated-subset rule (`S08`);
  3. R57 and the `F03`/`F06` download figures;
  4. the registry (`F01`, `F02`);
  5. the standard (`S02`, `S06`);
  6. `R5.1` and the empty `- owns:` line;
  7. three placement grounds;
  8. probe cases `P1` and `P2`;
  9. R57's `D05`;
  10. deferral under `R5.7`, whose `SHOULD` text I confirmed in the standard
     snapshot at `:335-336`.
- **The `BASELINE-REVIEW:` dispositions for the Doxa-raised lines rest on the
  ledger's own rules.** `docs/port/README.md:67-69` restricts `COMMON → *` to
  origin `same`. F230, F231, F232 and F234 are `py-only` at `COMMONALITY.md:234-238`.

### JF-4 — load-bearing claims trace to sources: pass

Spot-checked, all holding:

- **Both carried `BASELINE-REVIEW:` lines are byte-identical to their sources.**
  Decision `:201` equals `raw/opus.md:201`, and decision `:210` equals
  `raw/opus.md:232`. I compared them in Python.
- **The R55 quotations are present.** "the merge over sanitized tables in R54's
  order" is at `:483`, "owns merge depth and precedence order" at `:560`, and the
  F238 "validate each layer's leaves before precedence merge" at `:420`.
- **The R57 quotations are present.** "This item supplies `config_dir()` as the
  single resolver so R54 does not resolve it a second time" is at `:66`. "exposes
  no runtime-directory accessor and no free-function surface" is at `:49-50`,
  wrapped across the line break, and `check.sh` `D04` matches on the second half.
- **The R53 claim holds.** The per-key loop over R52's `toml::Table` is at `:79`.
- **The `docs/port/BASELINE-REVIEW.md` citations hold.**
  - `:113` is the F247 row, with status `blocked pending R54`.
  - `:193` holds "Also needing a disposition: whether py's absoluteness check …"
    verbatim.
  - `:354-356` recommends "include it as an acceptance criterion in R54".
- **The `docs/port/COMMONALITY.md` citations hold.** The rows at `:234-238`,
  `:246` and `:251` are F230–F234, F242 and F247, with the verdicts and origins
  stated. F232's parenthetical "(`./<tool>_config.toml`, dotfile preferred)" is
  quoted exactly.
- **The adopter claim holds.** `snapshots-r5/ruff-Cargo.toml:108` reads
  `etcetera = { version = "0.11.0", default-features = false }`.

The revision note quotes the two round-4 audits, for example "Both audits say
so…". Those quotations are **unverifiable under this auditor's read constraint**,
because I may not read `review/audit-*.md`. I record them as untraced, not as
passed. No part of the recommendation rests on them.

### JF-5 — couplings hand other items their owned choices without deciding them: pass

- **R55.** Its ownership of error handling is preserved. AC8 and AC12 reuse R55's
  criteria instead of inventing behaviour.
- **R57.** Its accessor set is left unopened. Disagreement 7 states that the owner
  may choose placement (a) with no change to the mechanism.
- **R53.** No constraint is added, a deliberate departure from Opus.
- **R60.** Its `env` feature is already present: R60 `:414` reads
  `features = ["derive", "env", "wrap_help"]`.
- **The two owner questions stay open.** The F247 absoluteness question is offered
  as a proposal and is explicitly "the owner's ruling to make". The F232 ledger
  edit is left to the owner, and `COMMONALITY.md` is untouched.

### JF-6 — `- assumes` lines byte-identical to the live registry: pass

I parsed `docs/port/PARAMETERS.md` column 4 and compared each value byte-for-byte:

| Parameter | Length (characters) | Result |
|---|---|---|
| `msrv-policy` | 118 | match |
| `rust-edition` | 4 | match |
| `target-os-matrix` | 27 | match |
| `license` | 17 | match |
| `error-taxonomy-exit-codes` | 4,057 | match |

The set is complete: four fixed parameters plus the one consumed on the prompt's
`- consumes:` line. `- owns:` is empty, so there are no `owns` lines. There is no
`CONFLICT:` line.

The drift claim also holds. `diff inputs/PARAMETERS.md docs/port/PARAMETERS.md`
shows exactly one differing row, `ci-job-structure`.

### JF-7 — no conflict with accepted or published prerequisite values: pass

- **R67 matches its pin.** Its current hash `16947ab1…` equals
  `inputs/prerequisites.json`.
- **R55, R57 and R53 match the pins the decision cites.** Their published hashes are
  `5d358c1f…` (R55, revision 3), `44e94504…` (R57, revision 2) and `be59d65b…`
  (R53, revision 2). Each equals the corresponding `D00b`, `D00c` or `D00a` pin
  that `check-on-r5-mirror.log` reproduced.
- **R52 matches.** It publishes `toml` 1.1.6+spec-1.1.0.
- **R60 matches.** It publishes `clap` 4.6.6.
- **No prerequisite value is contradicted.**

### JF-8 — evidence scripts exist and claimed counts match: pass

Every cited script and log exists. The counts match:

| Log | `PASS` | `FAIL` | `SKIP` | Notes |
|---|---|---|---|---|
| `check.log` | 64 | 0 | 0 | |
| `check-r5.log` | 63 | 0 | 0 | ends `failures=0 skipped=0` |
| `check-r2-on-r5.log` | 40 | 1 | 0 | the one `FAIL` is `V30` |
| `check-r3-on-r5.log` | 31 | 1 | 0 | the one `FAIL` is `E01` |
| `check-on-r5-mirror.log` | 62 | 2 | 0 | the `FAIL`s are `U04` and `P06` |

- **The mirror diff holds exactly the changes the decision tables.** They are the
  repository-root header, the toolchain line, `F03`/`F04`/`F06` with the stated
  900 / 69,943 / 113,173,002, `U04`, `P06` and the totals line.
- **The reproducibility and lint records are empty, as claimed.** `r5-rerun.diff`
  and `shellcheck-r5.log` are 0 bytes.
- **The snapshots are as claimed.** `snapshots/` holds 13 files.
- **`set -o pipefail` is present in all four scripts.** It is at `check.sh:25`,
  `check-r2.sh:21`, `check-r3.sh:26` and `check-r5.sh:25`.

### JF-9 — decision shape follows the published contract: pass

The H2 headings are `## Decision`, `## Parameters`, `## Empirical check` and
`## Engines`. There is no `## Supersedes`, which is correct for an unpublished item.

`## Decision` contains a nonempty `### Principles and implementation` and a single
`re-verify:` line at `:489`. The title is dated first and names revision 5. The
`## Parameters` lines use the `- assumes <param> = <value>` form with bare values.

### JF-10 — the recommendation follows from the assembled evidence: pass

- **J1 is forced by `R5.1`/`R5.2`**, which bind as the org standard (`S01`–`S09`).
- **J2 follows from owner-accepted R57** and the `macos-latest` requirement of
  F247 (`E03`).
- **J3 is supported by `E01` and `E05`.** The honest counterweight, `xdg` 3.0.0
  (`X01`–`X04`), is disclosed, and the choice is labelled a judgement. Opus, Muse
  and Doxa/OpenAI all hand-roll this tier.
- **J4 is measured by the probe.** `P2` reproduces the naive rule's defect.
- **A2′ is the loader R55 already published**, and AC12 is its observable test.
- **Every rejected alternative is rejected on scope, contract or execution.** None
  is rejected on popularity. None of the ten disagreements, if resolved the other
  way, would change the tier set or the precedence order.

## Observations (not findings)

1. **An R57 handoff was left at R57's default rather than taken by name.** R57
   (`research/topics/57-xdg-directory-set/DECISION.md:346`, `:840`) says R54 "may
   instead claim" `RSLB104` for a user-tier config location that cannot be
   resolved, instead of R57's proposed `RSLB101`. The decision never names this.
   Its sentence "R54 routes to no row of its own and defines none" (`:539-540`) is
   the implicit answer, so R57's `RSLB101` proposal stands. Both codes exit `1`, and
   R57 phrased the handoff as optional. P03 should know the choice was not
   overlooked.
2. **"All four engine positions" is correctly scoped.** Disagreement 3 says "All
   four engine positions agree … `directories` 6.0.0 is out". It counts the four
   engines in that disagreement: Opus and the three Doxa twins. Muse also classes
   `directories` as a "legacy tier" (`raw/muse.md:24`), so the claim holds for all
   five engines.
3. **The title date is the UTC date.** The title reads 2026-09-27, while the
   revision-5 files have local modification times of 2026-09-26 around 23:16 at
   -07:00. The decision records the re-fetch as `2026-09-27T06:16:12Z`, which is
   the UTC date. This is consistent, and nothing depends on it.
4. **Publication must stage the untracked Muse files.** `raw/muse.md`,
   `raw/muse-7ce9c81e….md` and `operations/muse.json` are untracked. The decision
   itself notes this at `:30-32`. Staging them is a runner step, not a judgment
   defect.
