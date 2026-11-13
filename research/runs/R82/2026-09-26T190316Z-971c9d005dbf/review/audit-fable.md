actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 4853cae14d8a7affec4a3815386234f71ce4bd724f90accf13de99783a505d43
verdict: reject
unresolved-findings:
1. JF-2 — the lychee command recommendations for F349 and F350 were never executed. RUNBOOK §5 requires that they execute.
2. JF-2 — the answer to prompt question 5 omits the clause "without failing the build when it is not". Executed case G4a is never interpreted.

# R82 docs-correctness-gate — judgment audit (fable), decision revision 1

**Scope.** This audit judges the reasoning and fidelity of
`research/runs/R82/2026-09-26T190316Z-971c9d005dbf/review/DECISION.md`, revision 1. It does not
judge execution; a separate empirical audit reruns the scripts. The auditor is a fresh Claude
context (`claude-opus-5-5`). It produced neither raw report and no evidence script. It read no
`review/audit-*.md` and no snapshot file of any seat or revision.

**Hash check.** `shasum -a 256 review/DECISION.md` →
`4853cae14d8a7affec4a3815386234f71ce4bd724f90accf13de99783a505d43`. This equals the dispatch's
expected hash and the hash recorded in `review/evidence/r82-decision-integrity.log:2`.

**Read.** The auditor read these files:

- the decision (610 lines) and `inputs/prompt.md`;
- `inputs/parameters.json`, `inputs/prerequisites.json` and `manifest.json`;
- `research/RUNBOOK.md` §2–§6;
- both raw reports, at every line the decision cites in its Engines section and at other sampled lines;
- all three evidence scripts and their logs;
- the prerequisite decisions `research/topics/11-ci-workflow-job-structure/DECISION.md` and
  `research/topics/69-web-framework-stack/DECISION.md`;
- the shape model `research/topics/53-config-schema-validation/DECISION.md:45-47`;
- the live `docs/port/PARAMETERS.md` and `research/EXECUTION.json` (`engine_overrides`);
- the lines of `research/topics/81-docs-delivery-model/DECISION.md` and
  `research/topics/34-scheduled-freshness-lanes/DECISION.md` that the Opus leg cites.

No network query was made. No script was rerun.

## Checks

| Check | Result |
|---|---|
| JF-1 internal consistency | pass |
| JF-2 every question answered, every constraint honored | **fail**: findings 1 and 2 |
| JF-3 Engines faithful and every disagreement adjudicated | pass |
| JF-4 load-bearing claims trace to sources | pass |
| JF-5 couplings hand over owned choices | pass |
| JF-6 `assumes` lines byte-identical to the live registry | pass (one observation) |
| JF-7 no conflict with accepted prerequisite values | pass |
| JF-8 evidence scripts exist and counts match | pass |
| JF-9 decision shape follows the contract | pass |
| JF-10 recommendation follows from the evidence | pass |

### JF-1 — internal consistency: pass

These places agree on the recommendation: the recommendation table (`:46-50`), the answers
(`:57-88`), the implementation YAML (`:144-239`), Members (`:270-316`), Migration (`:330-337`) and
the Engines settlements (`:503-606`). All of them give the same three things:

- one pinned `lychee` 0.24.2 run twice, offline in `hygiene` and networked in R34's lane;
- `--include-fragments` excluded;
- `cargo doc --locked --workspace --no-deps --all-features --document-private-items` with a
  step-scoped `RUSTDOCFLAGS: -D warnings`.

The decision dates its own checks in UTC and states that choice (`:13-15`). Every case id that
the decision uses is present in the log (`r82-decision-integrity.log` section I4).

### JF-2 — every prompt question answered, every constraint honored: fail

Questions 1–4 are answered with evidence (`:57-82`). Question 5 is answered only in part; see
finding 2.

The prompt's answer-template fields map onto the RUNBOOK §5 decision shape. The bundle's three
members each carry these fields: dominant choice, shortlist, exclusions, up-and-comers, runner-up
and confidence. The fitness gates are answered for each member (`:259-266`), with gate 1 marked
`inapplicable` under Q7.B as R53 records it. The `BASELINE-REVIEW:` line is present (`:99`). The
Parameters section follows the required form.

One constraint fails. RUNBOOK §5 says "Configuration, command and version-pin recommendations
must execute", and the prompt says "The item-specific empirical acceptance check remains
mandatory". This fails for both lychee members; see finding 1. The decision admits the failure
itself (`:356-362`, `:488`).

### JF-3 — Engines faithfully represents each engine and adjudicates every disagreement: pass

Every raw-report citation in disagreements 1–15 was spot-checked against the raw files. Each one
represents the engine's position faithfully.

| Engine | Cited position | Verified at |
|---|---|---|
| Muse | the `cargo doc` command | `raw/muse.md:599-600` |
| Muse | the `--all-features` rationale | `:633-635` |
| Muse | claims unused imports are denied | `:626-628` |
| Muse | "floor toolchain's rustdoc IS the gate" | `:592-594` |
| Muse | "No `BASELINE-REVIEW:` finding" | `:210-211` |
| Muse | lychee 0.8 d, 5 answered / 5 unanswered | `:285-286` |
| Muse | mlc 1.9 d, 7 / 3 | `:296-297` |
| Muse | cargo-deadlinks 22.2 d, 1 / 9 | `:609` |
| Muse | hyperlink 15.6 d, 2 / 4 | `:333-334` |
| Muse | the offline-skip question left open | `:436-439` |
| Muse | a single-crate probe | `:662-665` |
| Muse | "No shared adopter" | `:718-719` |
| Opus | `--features web` | `raw/opus.md:625` and `:262-266` |
| Opus | `--include-fragments` in the blocking step | `:231` and `:318-322` |
| Opus | the flag's false-positive risk | `:402-406` |
| Opus | the maintainer-response table | `:299-304` |
| Opus | cargo-deadlinks `stable-quiet`, not sampled | `:304` |
| Opus | two BASELINE-REVIEW findings | `:218-219` |

The Muse report contains no mention of `--document-private-items` (checked by grep). That matches
disagreement 2, "Muse does not consider it".

Each disagreement is settled by evidence, not by preference:

| Disagreement | Evidence that settles it |
|---|---|
| 1 | `G2a`–`G2d` |
| 2 | `G6a`, `G6b` |
| 3 | `G5a`, `G5b`, `G10` |
| 6 | `U3`, `U4` |
| 7–9 | `U8`, recounted under both counting methods |
| 13 | `G7a`, `G7b` refute Muse's claim |
| 14 | `G9c` |

### JF-4 — every load-bearing claim traces to a cited source: pass

All citations below were spot-checked:

- **R11.** `:86` status as a proposal; `:294` the R82 slot row: the link checks are a `hygiene`
  step, never path-gated, the rustdoc part is `check`'s doc build step with R82's flags, and an
  external check belongs to R34's lane; `:320` the owns line; `:329` R69 revision 10 accepted but
  unpublished.
- **R53.** `:45-47` the Q7.B licence ruling.
- **Research index.** `research/CLAUDE.md` rows R34 and R81 read `resolved` (lines 40 and 86),
  which supports disagreement 11.
- **RUNBOOK.** `:73-78` Q17.A.
- **EXECUTION.json.** `engine_overrides` has `R82: ["muse","opus"]`.
- **Upstream reads.** `U3`: `client.rs:22-27` replaces the accepted schemes with `["file"]`. `U4`:
  `filter/mod.rs:172-177` and `:221-222`. `U6`: README `:752` reads "At least one non-excluded
  link failed the check", `:392` gives `[default: lychee.toml]`, and `:644-645` covers
  `.gitignore`. `U1`: tag commit `e7477775…`. `U10`: the practice workflow lines.

Nit, not a finding: the list "README lines `331`, `394`, … `719`" (`:220`) omits `--no-progress`.
`U6` shows that flag at README line 640, so the claim "every flag exists" still holds.

### JF-5 — couplings hand other items their owned choices: pass

The decision hands each owned choice to its owner:

| Owner | Choice handed over | Where |
|---|---|---|
| R11 | placement and job topology | `:332-333`, `:397-401` |
| R20 | action-pin format | `:158`, `:332` |
| R34 | the scheduled file and its cadence | `:49`, `:178-182`, `:334` |
| task-runner item | `Justfile` recipes | `:337` |
| R81 | contributor docs | `:338` |
| R32 | the doctest step keeps its own flags | `:99`, `:602` |
| R20, R08 | the installer checksum gap | `:367-369` |

R82 decides only its own tool, config and flags. The draft job's `permissions: contents: read`
is a minimal proposal inside R34's file, not a claim to R08's scope decisions.

### JF-6 — `assumes` lines byte-identical to the live registry: pass (observation)

The auditor compared all six `assumes` lines by script with the working-tree
`docs/port/PARAMETERS.md` table. All six are identical: `msrv-policy` 118 characters,
`rust-edition` 4, `target-os-matrix` 27, `license` 17, `web-extra-surface` 2638 and
`ci-job-structure` 8093. They also match `inputs/parameters.json`, which is integrity log section
I1. There is no `owns` line, which is correct because the prompt's `- owns:` line is empty.

**Observation.** At committed `HEAD`, the `ci-job-structure` row still reads `—`. R11's value
exists only as an uncommitted working-tree change. This is publication state for the controller
to settle; it is not a defect of the decision.

### JF-7 — no conflict with accepted or published prerequisite values: pass

The prerequisite decision hashes match `inputs/prerequisites.json`:

| Prerequisite | sha256 |
|---|---|
| R11 | `410e88e5…418c` |
| R69 | `d4507f5b…c10d` |

The recommendation respects each rule of R11's value:

- the link check is a non-compiling `hygiene` step with no path gate;
- the doc build is an ordered `check` step;
- the doc build carries `--locked`;
- the doc build runs under `!cancelled()`;
- nothing is added to `ci.yml` outside those slots.

`--all-features` is one of R69's two sanctioned selectors ("consumers select the surface with
--features web or --all-features"). The R69 revision 10 layout is handled as a pending
publication, and fixture B covers it. The decision states that there is no `CONFLICT:` line, and
that is justified.

### JF-8 — evidence scripts exist and claimed counts match the files: pass

All three scripts and their logs exist.

- **`r82-rustdoc-gate.log`.** The ids enumerate 27 cases per toolchain: G0, G1a–c, G2a–d, G3a–c,
  G4a–c, G5a–b, G6a–d, G7a–b, G8a, G9a–c and G10. That count matches the claim at `:427`. Every
  exit code in the table at `:445-469` matches the log, and the two toolchains produce identical
  results. G0 reports "11 (allow: 4, warn: 7)". G10 reports `Fresh=2 Documenting=0` on both
  toolchains.
- **`r82-upstream-reads.log` `U8`.** The log reproduces every figure the decision quotes:

  | Crate | Maintainer method | Any-non-opener method |
  |---|---|---|
  | lychee | 7/10, 0.09 d | 7/10, 0.09 d |
  | mlc | 2/10, 4.67 d | 2/10, 4.67 d |
  | cargo-deadlinks | 0/10 | 4/10 |
  | hyperlink | 8/10, 0.15 d | 7/10, 0.29 d |
  | mdbook-linkcheck | 0/10 | 4/10 |

- **`U8b`.** mdbook-linkcheck issues #92 and #96 are open, and the repository was last pushed
  2024-08-15.

### JF-9 — decision shape follows the published contract: pass

- The H2 headings are `Decision`, `Parameters`, `Empirical check` and `Engines`. There is
  correctly no `Supersedes` section, because nothing was published before.
- `## Decision` carries the recommendation with versions, the settled rows F348, F349, F350 and
  F353, `### Principles and implementation`, and one `re-verify:` line (`:380`).
- `## Empirical check` states the toolchains, the OS, the working directory, the commands and the
  observed output.
- Each engine has a shape-check result recorded.

### JF-10 — the recommendation follows from the assembled evidence: pass

For F353, the flag choices each follow from a pair of executed cases:

| Flag | Cases |
|---|---|
| `--workspace` | `G2` |
| `--all-features` | `G3`, `G5` |
| `--document-private-items` | `G6` |
| step-scoped env | `G9c` |
| blanket `-D warnings` | `G0`, `G8a` |

For F349 and F350, the evidence supports choosing lychee:

- source reads at the release tag;
- maintainer responsiveness measured in `U8`;
- lycheeverse/lychee itself runs the same pairing: `ci.yml:19,68-70` and a schedule-only
  `links.yml`;
- py's weekly precedent.

Keeping `--include-fragments` out of the blocking step follows from the flag being unexecuted and
having a known false-positive mode. Its confidence is correctly stated as unexecuted. The conclusion
follows from the evidence; the missing execution is a JF-2 constraint failure, not a reasoning
gap.

## Unresolved findings

### Finding 1 — JF-2: lychee commands never executed (RUNBOOK §5)

- **Failed claims.** The decision recommends the `hygiene` step `lychee --offline --no-progress
  --root-dir "$(pwd)" .` (`:144-155`), the scheduled-job invocation (`:199-211`) and `lychee.toml`
  (`:171-176`) as configuration and command recommendations. It then says: "**lychee was never
  executed** … RUNBOOK §5 requires command recommendations to execute, so the F349 and F350
  commands are unmet on that clause" (`:356-362`). It marks AC1 and AC3 as "**proposed**; lychee
  never executed" (`:347`, `:349`).
- **Evidence.** RUNBOOK §5 says "Configuration, command and version-pin recommendations must
  execute." The prompt says "The item-specific empirical acceptance check remains mandatory."
  `raw/muse.md:432-433` and `raw/opus.md:35-40` confirm that neither leg ran lychee either. Two of
  the three members therefore rest only on source and README reads. The empirical auditor cannot
  rerun a command that no one ran. Approving now would contradict the decision's own statement
  that execution is needed "before acceptance".
- **Repair.** The controller authorizes RUNBOOK §3 bounded supplementary execution:
  1. Fetch the pinned lychee 0.24.2 release asset for one environment.
  2. Run the exact `hygiene` arguments with the proposed `lychee.toml`. Use a fixture that holds
     one good relative link, one broken relative link and one external URL.
  3. Expect exit 2 naming only the broken relative link. The external URL is skipped, which
     confirms `U3` and `U4`. The config file parses, including `exclude_path`.
  4. Optionally, run the scheduled-job flags against a local dead-host URL.

  Revision 2 records the result under `## Empirical check`, adds the script and log to
  `review/evidence/`, and changes AC1 and AC3 from "proposed" to "executed".

### Finding 2 — JF-2: question 5 clause unanswered; G4a uninterpreted

- **Failed claim.** Answer 5 (`:83-88`) reads "`--all-features` … With today's single `web`
  feature the two forms resolve to the same feature set … `--features web` silently stops
  documenting the nested module". It argues `--all-features` against `--features web` using
  `G5` and `G10` only.
- **Evidence.** Prompt question 5 (prompt line 37) asks for scoping "so the optional
  web-feature-gated API surface is included once `web-extra-surface` is enabled, **without
  failing the build when it is not**". Neither answer 5 nor the flag table (`:241-249`)
  addresses that clause. Case `G4a` is the decision's own evidence on exactly this point:
  - in layout B, the facade's doc links to `web::serve`;
  - `DOC` with the feature off exits 101 with ``error: unresolved link to `web::serve` ``;
  - the decision lists it at `:458`, and the log shows it at `r82-rustdoc-gate.log:57-61` and
    `:174-178`.

  The decision's prose never interprets `G4a`. The log shows that a feature-off doc build under
  `-D warnings` can fail when ungated docs link into gated items. The prose does not say whether
  the recommendation prevents this, ignores it or accepts it. A related point also goes unstated:
  `--all-features` does not error before any feature is declared, whereas `--features web` would.
- **Repair.** Add one or two sentences to answer 5 covering three points:
  1. The gate always runs with `--all-features`, so the CI gate never builds feature-off docs.
     Unlike `--features web`, it also does not error before the `web` feature exists.
  2. `G4a` shows that a feature-off `cargo doc` is **not** protected. A contributor running plain
     `cargo doc` with `-D warnings` sees the failure whenever ungated docs link into the gated
     surface.
  3. State whether this is accepted, or name the mitigation, for example keeping such links in
     gated items or behind `cfg_attr`. Cite `G4a`–`G4c`.

## Observations (not findings)

- **Controller note (a).** `inputs/prompt.md` line 25 reads `engines: codex, opus`, and
  `manifest.json` `required_engines` is `["codex","opus"]`. Both predate Q17.A, and Muse is what
  actually ran. The decision flags this itself (`:27-35`). Repair: the controller re-freezes the
  inputs and cites Q17.A. This does not fail the synthesis.
- **Operation records (gap 6).** `operations/` is empty and `manifest.json` records
  `operations: {}`, so the Muse leg's resolved model is unrecorded. The decision states this
  honestly (`:374-378`, `:494`). Attaching the records is controller business before acceptance.
- **Carried R81 and R34 statements (gap 2).** The auditor spot-checked them, and they hold:
  - R81 `DECISION.md:146-157`: one `docs/` corpus plus mdBook 0.5.4; `{ #id }` forbidden;
    `docs/SUMMARY.md` as the single navigation source.
  - R81 `:655-657`: criterion (b), "R82 owns the checker".
  - R81 `:1274-1277`: "the link walk should treat `docs/SUMMARY.md` as the authoritative
    navigation artifact".
  - R34 `DECISION.md:31-35`: `.github/workflows/canary.yml`, weekly plus `workflow_dispatch`.

  The walk of `.` includes `docs/SUMMARY.md`, so the design meets R81's requirement. Revision 2
  may state this directly instead of carrying it as unverified.
- **Synthesizer seat.** The synthesizer is a fresh `claude-opus-5-5` context, the same family as
  the Opus leg. RUNBOOK §2's table names a "Claude Fable" synthesizer, and Q9.B says "synthesis …
  Claude". The decision discloses the family overlap (`:7-11`). The controller should confirm that
  the seat is acceptable.
- **Gate-4 wording.** `:264` attributes the scheduled job's `ubuntu-latest` runner to "R11's rule",
  but the job lives in R34's file. This is a nit.
- **Controller notes (b) and (c).** The R32/R11 and R71/R69 conflicts, the R58 conditionals, and
  the tower-http tension between R78 and R75 do not touch R82. They are not applicable here.
