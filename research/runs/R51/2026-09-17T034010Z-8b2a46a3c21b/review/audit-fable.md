# R51 container-image — judgment audit of decision revision 1

actor: audit-fable-r51r1-s4
model: claude-opus-5-5
family: anthropic
decision: research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/DECISION.md (revision 1)
decision-sha256: 11b9150d1a4a8df336f17a8e96054eafcfd695f03ff693e5618d5f5610a95231
verdict: reject
unresolved-findings:
1. JF-3/JF-10: `## Engines` omits the collected Muse report and adjudicates none of its disagreements.
2. JF-8/JF-1: the decision conceals five FAILs in its own `r51-sources.log` and claims that every script exits non-zero on a FAIL.
3. JF-8: four evidence files that the decision cites do not exist.
4. JF-4/JF-5/JF-7: `OV-04` is attributed to the wrong item, and `OV-14` duplicates R77's owned R8.1 override without reconciling with it.
5. JF-4: the decision cites R77 as "accepted revision 1" at line numbers that no longer hold the quoted text.

Audit date 2026-09-26. Before reading, I recomputed the hash with `shasum -a 256`. It matches the expected value. This audit judges reasoning and fidelity only. The separate empirical audit reruns the scripts. I read no other audit and no snapshot. I made no git writes and ran no runner command. I reran no evidence script into `evidence/`, and I used no scratch files.

## Provenance context (needed to read the findings)

- The decision file was last written on 2026-09-18 at 18:37 PDT, and `review/` is untracked.
- Ledger line 1086 (`docs/planning/p02/execution-ledger.md`) records that the R51 synthesis agent "died on the Claude session limit" at about 18:46 PDT. That line also says: "On-disk drafts left behind: R51/… DECISION.md revision 1 untracked (R51 still needs its OV-14 renumber)".
- After the decision was written, `manifest.json` gained a migration event on 2026-09-21T23:06:19Z (`from: codex`, `previous_required_engines: ["codex","opus"]`). It now carries `required_engines: ["muse","opus"]`, two `succeeded` operations and `state: collected`.
- The Muse leg was collected on 2026-09-22T01:34:43Z. Its `raw_sha256` is `a60d11907445c99889150f41233bf5f8f31608465bff0ba4bf3069402164fecf`, and I recomputed that value from `raw/muse.md`.
- The live `inputs/prompt.md` reads `- engines: muse, opus`.

Most of the findings below follow from one cause: this is a draft whose author was killed mid-run, and it predates the second engine. They are defects of the revision, not accusations of bad faith.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | Line 858 reports the sources script's outcome as "see the summary line in that log". Lines 861–865 say each script "exits non-zero on any `FAIL`". The log's summary line is `SUMMARY: PASS=101 FAIL=5 SKIP=0 TOTAL=106`. Lines 937–940 claim `S3a`–`S3d` assert "the four H2 headings in order and nothing else", but `S3b` FAILs in that log. Finding 2. |
| JF-2 prompt questions and constraints | pass | The decision question is answered: ship a recipe and do not publish. Both HIGH questions are answered: cargo-chef versus cache mounts, and chef's maintenance. Both MEDIUM questions are answered: the HEALTHCHECK on a shell-less base, and non-root through the built-in `nonroot` user. The LOW question is answered: build-only CI and no publication. Each fitness gate is applied or declared `inapplicable` with a reason (lines 256–266, 313, 349–351, 470–475, 793–807). Out-of-scope items (F328 endpoint behavior, R69's surface content, owner prior art) are handed on, not decided. |
| JF-3 `## Engines` fidelity | **fail** | Only `opus` is listed. Lines 950–955 call the second engine "`codex` — absent … not failed" and say the manifest "holds exactly one research operation (`S14b`) and its state is `partial`". Line 957 says "There are therefore no inter-engine disagreements to settle". All of this is false against the current manifest and `raw/muse.md`. Finding 1. |
| JF-4 load-bearing claims trace | **fail** (partly) | Spot-checks that passed: `r51-container.log` carries `measured-size-main: 12312852`, `measured-size-noprobe: 11499381`, `measured-size-busybox-delta: 813471`, `measured-size-debian-slim: 40163283` and `measured-binary-size: 1271048`. It also shows `C4b` 0, `C5b` 50, `C3a` 65532, `C6a` 143, `C11a` GLIBC_2.34 and `C12a` healthy. `r51-registries.log` shows `D4b` 1.98.1 with floor 1.96; `D5a`–`D5e` 0.1.78, `null`, 997338 and 4249535; `G1b` 0 with `G1c` 1; `G2b` 6 of 6 at 0 comments; `G3a` 35; and `D6a`/`D6b` 404 and 200. `Dockerfile.candidate` matches the inline block apart from indentation. Failures: the attributions of R77 and `OV-04` (Findings 4 and 5). |
| JF-5 couplings hand over owned choices | **fail** | The hand-offs to R80 (path), R11 and R12 (job slot and required status), R19 (the `docker` ecosystem), R68 (the "two doors") and R27 (`mold`) are handled properly: each is stated as a requirement or hand-off, not decided here. The R8.1 plaintext-listener deviation, however, is already R77's `OVERRIDE (OV-04)`, and R51 re-records it as its own `OV-14` without citing R77. Finding 4. |
| JF-6 `assumes` lines match the live registry | pass | I diffed each of the five `- assumes` values (lines 761–765) against the cells of `docs/port/PARAMETERS.md`, and each is an exact cell match. The working-tree diff to `PARAMETERS.md` touches only the `ci-job-structure` row. R69 revision 10 appears in prose only (lines 776–791), and the registry row is still revision 9 (`research/topics/69-web-framework-stack/DECISION.md` heading "revision 9", `- owns` at line 1586). |
| JF-7 no conflict with accepted or published prerequisite values | **fail** (on the override record) | The design is consistent with the published R69 `web-extra-surface` and with R11's published `ci-job-structure` ("No container or deploy job enters `ci.yml`"). The misattribution of `OV-04` and the unreconciled duplicate of R77's R8.1 override conflict with the controller's allocation table (ledger line 1073). Finding 4. |
| JF-8 evidence scripts and counts | **fail** | The claimed `r51-container.log` result "54 PASS, 0 FAIL" and `r51-registries.log` result "28 PASS, 0 FAIL" both match the files. `r51-sources.log` records 5 FAILs, which the decision does not disclose. The files `shellcheck.log`, `reproduction.log`, `r51-*.archive.log` and `tree-check.log` are absent. Findings 2 and 3. |
| JF-9 decision shape | pass, with a note | The title line, the H2s `## Decision`, `## Parameters`, `## Empirical check` and `## Engines` in order, no `## Supersedes`, and exactly one `re-verify:` line (line 750) are all present. `S3b` fails only because the `## Conformance note …` line sits inside a fenced block (line 677). That is not a rendered heading, but the decision's own claim at lines 937–940 is contradicted by its log. The repair is under Finding 2. |
| JF-10 recommendation follows from the evidence | **fail** | For the Opus-only evidence, the chain holds. Cache mounts are selected because gate 2 is read strictly and the rebuild counts are 0 against 50. Distroless is selected on measured size and non-root identity. The busybox probe is selected because `C13` detects a dead listener. The evidence now also includes a second engine that reaches a different stack on every member. The recommendation therefore precedes half of the evidence that must support it. Finding 1. |

## Findings (unresolved)

### Finding 1 — JF-3 / JF-10: the Muse report is unrepresented and unadjudicated

**Failed claims.**
- Line 950: "`codex` — **absent by the controller's deferral, not failed.**"
- Lines 954–955: "The run's `manifest.json` holds exactly one research operation (`S14b`) and its state is `partial`."
- Line 957: "**There are therefore no inter-engine disagreements to settle**".

**Evidence.** `manifest.json` currently records `required_engines: ["muse","opus"]`, two `succeeded` operations and `state: collected`. The prompt line is `- engines: muse, opus`. RUNBOOK §5 requires `## Engines` to cover "all reports and evidence checks, disagreements, and the evidence that resolved each disagreement". `raw/muse.md` (sha `a60d1190…`) disagrees with the decision on every member:

| Topic | Muse position | Decision position |
|---|---|---|
| Dependency caching (raw lines 27, 150, 170) | Selects **cargo-chef** as the required mechanism, with cache mounts an optional supplement. Reads gate 2 as not binding because "chef ships no code into the template". | Cache mounts only; cargo-chef excluded by gate 2 |
| Runtime base (line 27) | **`debian:trixie-slim`**, with installed `curl` and `ca-certificates`. Distroless is the ranked runner-up (line 174). | Distroless `cc-debian13` |
| Non-root identity (lines 146, 170) | `groupadd`/`useradd`, uid **10001**, `USER app` | The built-in uid 65532 `nonroot` user |
| HEALTHCHECK (line 232) | **Shell-form** `CMD curl -f http://localhost:${PORT:-8080}/healthz \|\| exit 1`. Line 220 records "no surveyed reference or maintained implementation" for a static probe binary on distroless. | Exec-form busybox probe |
| cargo-chef maintenance (line 31) | **`active`**, reporting "10/10 most recent issues unanswered" | `at-risk`, reporting 6 of 6 |
| CI placement (line 284) | Deferred to R11, R50 and R68 | Its own workflow file, per R11 |

Muse's adopter survey (Qdrant, Lemmy, Meilisearch, Depot and the chef README) is also broader than the Opus survey, and the decision's comparison does not engage it. The decision predates the second engine, so this is a staleness failure, not a misstatement at writing time. It still cannot be approved at this revision.

**Repair.** Write revision 2 with a rewritten `## Engines` that lists both registered reports with their hashes and removes the Codex-deferral text and the `S14b` "exactly one operation" claim. Adjudicate each disagreement above with evidence. The existing measurements already support most of the adjudication:
- `C9b` measures the size of the debian-slim + curl runtime.
- `C13` shows the probe detects a dead listener.
- `C4b`/`C5b` show 0 against 50 recompiled crates.
- `S12c` records the strict gate-2 ruling, and R69 revision 10 applies it to `watchexec-cli`.
- The 6-versus-10 issue sample must be reconciled against Muse's 10/10 figure.

Then re-state the recommendation from the combined evidence.

### Finding 2 — JF-8 / JF-1: five FAILs in the sources log are concealed

**Failed claims.**
- Line 858: `./r51-sources.sh > r51-sources.log 2>&1   # → see the summary line in that log`
- Lines 861–865: every script "exits non-zero on any `FAIL`"
- Lines 937–940: `S3a`–`S3d` assert "the four H2 headings in order and nothing else"
- Engines table rows citing `S2c` and `S8a`–`S8e` as "confirmed"

**Evidence.** `r51-sources.log` begins with `date-utc: 2026-09-19T01:43:50Z`. That is after the decision's last write (01:37Z), so the log checks this exact revision. It ends `SUMMARY: PASS=101 FAIL=5 SKIP=0 TOTAL=106`. The five failures:

| Check | Log line | What failed |
|---|---|---|
| `S3b` | 18 | "H2 headings differ", caused by the fenced `## Conformance note — …` line at decision line 677 |
| `S4a` | 25 | "gate 1's prescribed string is absent". The script greps with `-F` for `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`. The decision carries that text, but line-wrapped at 257–258 and 806–807, so the check cannot match it. |
| `S9b` | 65 | "R80 revision 2 does not declare OV-04". See Finding 4. |
| `S10e` | 80 | R77 `DECISION.md:723` does not contain "sets `RSLBP_WEB_HOST=0.0.0.0` explicitly" |
| `S10f` | 81 | R77 `DECISION.md:606` does not contain "`127.0.0.1`, `8000`" |

`S10e` and `S10f` are load-bearing. Lines 88–90, 714–716 and 994–999 rely on them for the `ENV RSLBP_WEB_HOST=0.0.0.0` line and for the `8000` literal in `HEALTHCHECK` and `EXPOSE`. The underlying facts do hold at other lines of R77 revision 3:
- line 678: "`127.0.0.1`, `8000` — … a container must opt into `0.0.0.0`"
- line 931: "`Dockerfile` (R51) | sets `RSLBP_WEB_HOST=0.0.0.0` explicitly"

The substance survives. The citations and the disclosure do not.

**Repair.**
1. Re-anchor `S10e`/`S10f` to the R77 revision and lines that the decision actually relies on.
2. Fix `S9b` per Finding 4.
3. Unwrap the gate-1 string, or make `S4a` whitespace-tolerant.
4. Move the fenced conformance note so that `S3b` passes, or make `S3b` fence-aware.
5. Rerun `r51-sources.sh`, state its actual `SUMMARY` line in `## Empirical check`, and remove the "see the summary line" deflection.

### Finding 3 — JF-8: cited evidence artifacts do not exist

**Failed claims.**
- Line 865: "All three are `shellcheck -S warning` clean (`shellcheck.log`)."
- Lines 895–896 and 907–908: "the summary lines are recorded in `reproduction.log` beside `r51-*.archive.log`", followed by "`reproduction.log` records the diff of the in-place re-run against the first log".
- Lines 941–942: "`bash scripts/check-research-tree.sh .` was run before the commit and its output is recorded in `tree-check.log`."

**Evidence.** `review/evidence/` contains exactly eight files: `Dockerfile.candidate`, `dockerignore.candidate`, and `r51-{container,registries,sources}.{sh,log}`. A `find` across `research/runs/R51` locates none of `shellcheck.log`, `reproduction.log`, `*archive.log` or `tree-check.log`. The reproducibility claim (lines 893–908: "Every other line … is identical across runs … checked by diffing, not assumed") therefore has no record behind it. Ledger line 1086 is consistent with the agent dying before producing these files.

**Repair.** Produce the four artifacts by actually running the stated commands and committing their output. Otherwise, strike the shellcheck, reproduction/extracted-tree and tree-check claims, and restate the reproducibility claim as not yet checked.

### Finding 4 — JF-4 / JF-5 / JF-7: `OV-04` misattributed; `OV-14` duplicates R77's R8.1 override

**Failed claims.**
- Lines 609–611: "`OV-04` (R80 revision 2, for its unversioned probe paths) are all found by that same scan".
- The `OVERRIDE (OV-14)` section (lines 598–667) and its conformance-note deviation line (690–695) present the R8.1 plaintext-listener deviation as this item's own. They do not mention that R77 already records it.

**Evidence.** Ledger line 1073 contains the allocation table: "OV-04 R77 revision 2 (R8.1 plaintext listener; committed first, keeps the number); OV-05 R80 (renumbered from OV-04 in a revision 3) … OV-14 R51". R77 revision 3 carries `OVERRIDE (OV-04) — R8.1, TLS` with "The template's listener is plaintext and this surface ships no TLS setting" (line 44). Its line 13 states that "R80 has since published its revision 3 carrying `OVERRIDE (OV-05)` and no longer names `OV-04` at all". `S9b` fails for exactly this reason.

The two overrides therefore overlap:
- R77 owns the plaintext listener and the `0.0.0.0` opt-in model.
- R51 re-argues the same R8.1 MUST, including options b–d, as if it were deciding them.

In the decision's own terms, option (b), TLS termination inside `rslbp-serve`, is a question for R69 and R77. R51 does not own it.

**Repair.**
1. Correct the `OV-04` attribution to R77, and record that R80 moved to `OV-05`.
2. Re-scope `OV-14` to what is container-specific: the image's `ENV RSLBP_WEB_HOST=0.0.0.0` (which puts R77's opt-in into effect by default), `EXPOSE 8000`, and the `http://` loopback self-probe. Cross-reference R77's `OV-04` as the owning record of the listener deviation. Alternatively, state `OV-14` explicitly as the container-side record of R77's deviation, and do not re-decide options that belong to R77 or R69.
3. Update the conformance-note deviation line to match.

### Finding 5 — JF-4: R77 is cited as "accepted revision 1"

**Failed claims.**
- Line 89: "R77 revision 1 assigns exactly this line to this item".
- Lines 714–716: "reads `RSLBP_WEB_HOST` and the `8000` default from R77's accepted revision 1 (`S10e`, `S10f`)".
- Lines 996–998: "R77's accepted revision 1 names the variables … and assigns *this item* the line `ENV RSLBP_WEB_HOST=0.0.0.0`".
- The source list at line 1105: `…R77…/DECISION.md:606,723`.

**Evidence.**
- The R77 run's `DECISION.md` is revision 3. Its title reads "decision (revision 3)", and ledger line 1082 records "R77 REVISION 3 LANDED". It was modified on 2026-09-18 at 18:39, after this decision was written.
- `research/CLAUDE.md` lists R77 as `open`.
- Ledger line 1083 records that the approving audit binds revision 2 and that "revision 3 … needs a fresh judgment audit".
- The cited lines 606 and 723 no longer contain the quoted text (`S10e`/`S10f` FAIL).

I found no record that any R77 revision is accepted. If an acceptance exists elsewhere, the revision is still wrong.

**Repair.** Cite R77 by its current revision, file hash and lines (678 and 931 in revision 3), and state its acceptance status accurately. Add R77's revision movement to the `re-verify:` triggers. That line already lists R77's publication.

## Non-blocking notes (no repair required for approval)

- **`C13` ran a variant, not the fixture.** Lines 39–40 say "every check below was executed against **that** file". `r51-container.log` line 51 reads "FailingStreak reached 2 (>= the 2 retries configured for this run)", while `Dockerfile.candidate` carries `--retries=3`. The unhealthy-path check therefore ran a modified variant, with a changed port binding and 2 retries. That is a legitimate test design, but lines 134–141 and 886–889 should say so.
- **`-T 2` versus the 3-second timeout.** The margin argument (lines 81–85) is sound. However, no check exercises a slow endpoint to show that busybox's own timeout fires first. `C15e`/`C15f` assert the literal only. That is acceptable, but it is a proposed property, not an executed one.
- **Rebuild figures.** The 15 s / 28 s wall-time comparison is correctly marked non-load-bearing. The decisive evidence is the 0-versus-50 count.

## What passes and should carry forward into revision 2

The architecture comparison (A–D), the measured size and non-root evidence, the dead-listener detection in `C13`, the glibc-pairing falsification in `C12a`, the gate-2 exclusion record with its strongest counter-argument stated, the unraised-`CONFLICT:` reasoning for option C, and the R68 "two doors" hand-off are all well-built. Where I spot-checked them, they trace to the logs. The rejection concerns revision staleness and evidence disclosure, not the engineering design.
