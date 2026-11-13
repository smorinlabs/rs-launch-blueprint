actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 7a4f06ca0cfc136e516da23e62374532e6d76a9c452119b0a2d1113a736873be
verdict: approve
unresolved-findings: none

# R56 — config-secret-policy — judgment audit of revision 5

**Seat.** Fresh judgment auditor, with no prior context on this item. The seat judges
reasoning and fidelity, not execution: a separate empirical audit reruns the checks.
Audited on 2026-09-27 from the repository root, `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.

**Target.** `review/DECISION.md`, revision 5. `shasum -a 256` gave
`7a4f06ca0cfc136e516da23e62374532e6d76a9c452119b0a2d1113a736873be` before reading and again
before writing. Both values equal the expected hash.

**Read.** `DECISION.md`; `inputs/prompt.md`; `inputs/prerequisites.json`; `research/RUNBOOK.md`
§2 and §5; `raw/muse.md`, `raw/opus.md` and `raw/doxa-{openai,gemini,perplexity}.normalized.md`
at the cited lines; `docs/port/PARAMETERS.md`; `docs/port/OWNER-ACCEPTANCES.md`;
`research/CLAUDE.md`; the published decisions under `research/topics/` for R52, R53, R55, R57,
R60 and R67; R54's current working decision under `research/runs/R54/`; and the org CLI Design
Standard blob `f9de0437…` from `/Users/stevemorin/c/cli-standards`.

**Not read (outside this seat).** No `review/audit-*.md` file of any seat or revision, and no
`review/R56-r*-snapshot.md`. So the decision's descriptions of earlier audits, including
`audit-claude.r4.md`'s approve verdict cited at `:7` and `:1017`, were **not verified here**.
JA4-1 is judged only on whether the current text is true at source.

**Commands run.** All output went to `/tmp`; nothing was written in the tree except this file.
- `check-r5-couplings.sh` rerun: exit `0`, 4 PASS / 0 FAIL. The output matches the committed
  log except for `date-utc:`.
- `check-parameters-r5.sh` rerun: exit `0`, 59 PASS / 0 FAIL. The output matches the committed
  log except for `date-utc:`.
- `check-r4-couplings.sh` rerun: exit `0`, 55 PASS / 0 FAIL. The output matches the committed
  log except for `date-utc:`.
- `check-siblings.sh` rerun: exit `0`, 30 PASS / 0 FAIL. Besides `date-utc:`, exactly two lines
  differ: R61's `X0-detail` sha256 and `X26` at `owner-decisions.md:486`. Those are the two
  lines the decision names at `:1022-1023`.
- `shellcheck` 0.11.0 over all 16 `.sh` files: exit `0`. Six files carry the `SC2016` waiver,
  which matches `:617-622`.
- No Cargo-building check was rerun, which is the empirical seat's job.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass** | See "JF-1" below. |
| JF-2 questions and constraints | **pass** | See "JF-2" below. |
| JF-3 engine representation | **pass** | See "JF-3" below. |
| JF-4 traceability | **pass** | See "JF-4" below. |
| JF-5 couplings | **pass** | See "JF-5" below. |
| JF-6 `assumes` lines | **pass** | See "JF-6" below. |
| JF-7 prerequisite values | **pass** | See "JF-7" below. |
| JF-8 evidence scripts and counts | **pass** | See "JF-8" below. |
| JF-9 decision shape | **pass** | See "JF-9" below. |
| JF-10 recommendation follows | **pass** | See "JF-10" below. |

### JF-1 — internal consistency: pass

Every R54 mention agrees with every other. The mentions are at `:11-24`, `:165`, `:184-185`,
`:323`, `:328-336`, `:509-514`, `:541`, `:642`, `:1035-1041` and `:1225`. No text still calls
R54 unresolved or in flight.

The revision note's four corrections are all present:

1. The recommendation's parenthesis at `:183-185` names R54's accepted file and tier set.
2. The composition paragraph at `:325-336` states an actual composition.
3. Alternative E's cost at `:323` follows from E's definition.
4. The `re-verify:` line at `:541` carries "R54 being revised to drop or rename the project tier".

The Couplings paragraph at `:509-514` gains an R54 entry.

**How `:323` was read.** Its phrase "refuse it in every other tier R54 defines" refers to "the
loader" and to "`token`" as a config key. The row heading, "B confined to the user tier, refused
in any project tier", fixes that reading: the sentence is about the file tiers where a `token`
key can appear. R54's flag and environment tiers are not locations for a config key, so the
sentence does not contradict E's own flag > env > file chain. It passes. The phrase could be
sharpened to "every other file tier".

The acceptance criteria labelled **executed** at `:262-305` each map to named assertions:

| Criterion | Assertions |
|---|---|
| 1 | `B1`–`B4`, `F2`, `F3` |
| 2 | `A2`, `A3`, `A5` |
| 3 | `A1` |
| 4 | `C1`, `C3`, `E0`–`E4` |
| 5 | `D1`, `D2`, and the leak census |

Criteria 6–10 are labelled **proposed**, and item 5 and Unproven 7 repeat that label. Every
count table agrees with its log.

### JF-2 — questions and constraints: pass

Each prompt question is answered:

| Prompt question | Where it is answered |
|---|---|
| HIGH 1: the principle and the policy | the principle table at `:249-256`; alternatives A–E at `:317-323`; the extension beyond the prompt's binary at `:219-225` |
| HIGH 2: the POSIX mechanism and the no-op fallback | `std::os::unix::fs::PermissionsExt` with a `#[cfg(not(unix))]` stub reporting *unchecked*, at `:205`; `0o077` as a mask, at `:272-274` |
| HIGH 3: agreement levels across the three repositories | the agreement-level column, and "What must agree" at `:306-313`, which states each repository's status against P1–P6 |
| MEDIUM: composition with R54 | the file is never a token source at any tier, so the merged-versus-per-layer question is moot; each layer's `token` key gets its own warning naming that file (`:185`, `:348-355`) |
| MEDIUM: warning mechanism and cardinality | item 5 at `:381-402`; criterion 10 |
| LOW: published Rust guidance | the null result, with a positive control, at `:451-463` |

Each constraint is honoured:

- **Out-of-scope items.** Discovery (R54), tolerance (R55) and the validation crate (R53) are
  not decided here. The `figment` and `config` crates are refused on that ground, in
  Disagreement 3.
- **Parameters.** The prompt's `CONFLICT:` rule is honoured with a stated "none" at `:571`.
- **Gates.** The fixed parameters and the fitness gates are stated at `:176-178`, `:556-569`
  and `:704-758`.

### JF-3 — engine representation: pass

All four legs are listed at `:1062-1065`: Opus, Doxa with three providers, Codex (superseded,
with the owner direction), and Muse. Eight disagreements are adjudicated against primary
sources.

These quotations were spot-checked at their cited lines:

| Source | Lines checked |
|---|---|
| `raw/muse.md` | `:204`, `:206`, `:209`, `:213`, `:241`, `:290`, `:292`, `:301` |
| `raw/doxa-openai.normalized.md` | `:74` ("Separate credentials file"), `:82` ("does have an optional `token` field"), `:88`, `:256`, `:323` |
| `raw/doxa-gemini.normalized.md` | `:181` (`24,105,992`) |
| `raw/doxa-perplexity.normalized.md` | `:45` ("should follow the TypeScript port's shape") |
| `raw/opus.md` | `:697-700` (the keyring-rs README) |

Every quotation matches its source. Muse's positions are shown fairly, including where Muse is
closer to this decision than its tier count suggests (Disagreement 6).

### JF-4 — traceability: pass

The org CLI Design Standard blob hashes to `9fb05d3d…`, the value at `:652`. Its lines match
every quotation:

| Line | Content checked |
|---|---|
| `:327-329` | `R5.5` and both examples |
| `:545` | `R10.1` |
| `:88` | row 26, marked `derived` |
| `:50` | the conformance clause |

Revision 5's new claim traces to its sources. `OWNER-ACCEPTANCES.md:78` carries R54 revision 3
(`1348f6b3…`), marked `accept` on 2026-09-18, and it quotes the project-tier sentence verbatim.
The working decision's project-tier row sits at line 162.

The inference "the file it finds lies inside the git working tree" follows from R54's stopping
rule. When the working directory is inside a repository, the walk stops inclusively at the
first ancestor that carries `.git` or a workspace `Cargo.toml`.

These R55 and R57 citations were checked at source:

- R55's published `:173`, "Unknown keys warn and never fail, in every layer".
- R55's `:264-270` carrier and its `:561` R58 hand-off.
- R57's published `pub fn state_dir(&self) -> &Path`, at `:284`.

### JF-5 — couplings: pass

Each coupling hands the other item its owned choice without making that choice here:

| Item | What this decision hands over |
|---|---|
| R58 | a rendering requirement, with its crate, subscriber and format left to R58 |
| R59 | the file-sink question |
| R60 | `--token-file` as a surface for R60 to carry |
| R61 | a masked-input gap, not a collision |
| R53 | a schema with no `token` field |
| R54 | "no token at any tier", with R54's tier set left as R54 decides it |

The `auth` command group and the masked prompt are recorded as ownership gaps, not absorbed
(`:574-581`).

### JF-6 — `assumes` lines: pass

For each of the five `assumes` parameters, I regenerated the line from its
`docs/port/PARAMETERS.md` row with `awk`. I then matched each line with
`/usr/bin/grep -qxF` against the decision. All five match byte for byte.
`check-parameters-r5.log` reports the same result as `PA2`. The decision has no `- owns` line,
which matches the empty `- owns:` line in the prompt.

### JF-7 — prerequisite values: pass

`inputs/prerequisites.json` pins R67's decision at `16947ab1…`. The published
`research/topics/67-*/DECISION.md` hashes to the same value, and it defines `RSLB101`,
`RSLB104`, `RSLB204`, `RSLB401` and `RSLB402` as the decision uses them.

The decision conflicts with no accepted or published value in R52, R53, R55, R57, R60 or R61.
`--token` occurs 0 times in R60's, R67's and R52's published decisions. The recommendation
matches the owner's acceptance of R56 revision 2 (`OWNER-ACCEPTANCES.md:76`), and the decision
states that no recommendation, crate, version or parameter moved after that revision.

### JF-8 — evidence scripts and counts: pass

Every log the decision cites has its script. The table at `:626-642` agrees with the reruns
listed above: 4, 59, 55 and 30 PASS, and 15 checks plus `refresh-snapshots.sh`. The pin
mechanism in `check-parameters-r5.sh` (`PA17.*`, `PA18`) is present and passes.

### JF-9 — decision shape: pass

The decision has the H2 headings that RUNBOOK §5 requires: `## Decision`, containing
`### Principles and implementation` and a single `re-verify:` line; `## Parameters`;
`## Empirical check`; and `## Engines`. It has no `## Supersedes` section, and it states the
reason at `:166-167`: the item is not published.

### JF-10 — recommendation follows from the evidence: pass

The standard's MUST clauses decide the policy:

- `R10.1` fixes the three-tier order and a stored-credential third tier.
- `R5.5` requires the top tier to name a file.

The standard's SHOULD clause supports the dedicated `0600` store. The Cargo and AWS file splits
support it too, and so does the composition with R54's accepted project tier. The confidence
table (`:1223-1234`) lowers each grade that engines contest, and it names which parts are
inferred rather than executed.

## Observations (not findings; recorded so they are not re-raised)

1. **`:644` has a stale ordinal.** It calls `refresh-snapshots.sh` "a sixth script". The tree
   holds 16 `.sh` files, and `:617` says "all fifteen" checks. The ordinal dates from revision
   1 and no claim depends on it.
2. **R53's status is incomplete, not false.** R53 was published on 2026-09-21 (commit
   `e0b0d1c1`). The published text hashes to `be59d65b…`, which is the accepted revision 2, and
   it carries no `token` field. The decision calls R53 "owner-accepted" (`:527`, `:1102`), and
   the `re-verify:` trigger reads "R53 publishing a schema that carries a `token` field".
   - Nothing stated is false. "Owner-accepted" is true, and the trigger still fires on any
     revision that adds the field.
   - The decision labels published R57 and R67 the same way.
   - This is unlike JA-2 and JA4-1, which both corrected false statements.
3. **Some fitness-gate answers appear only in the raw Opus report.** For `keyring-core` and the
   two store crates, the `unsafe` posture and the adopters row are answered in `raw/opus.md`,
   not in the decision. The `unsafe` posture is at `raw/opus.md:744-745`; the `secrecy`
   adopters are at `:567`. RUNBOOK §5 puts per-member fields in the raw answer, and `## Engines`
   covers that report.
