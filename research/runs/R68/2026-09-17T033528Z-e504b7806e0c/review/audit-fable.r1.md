actor: fable
model: claude-opus-5-5
family: anthropic
decision: research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md (revision 2)
decision-sha256: 72bd7972c748e529a1b226db5940e7ade4b5a2adf8e98588b137479bb6d3c5c8
verdict: reject
unresolved-findings:
  1. JF-3 — a collected Codex engine report is recorded as absent and none of its disagreements is adjudicated
  2. JF-5 — R49's published re-verify trigger, fired by this decision, is not handed to R49
  3. JF-2 — the Cargo Book profiles chapter is not cited for the key defaults

# R68 revision 2 — judgment audit (fable, round 1)

## Scope and method

This audit judges the reasoning and fidelity of revision 2. It does not re-run the
evidence scripts; a separate empirical audit owns that. The expected sha256 was
recomputed with `shasum -a 256` before any other step and matched.

Read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §4–§5; the pinned raws
`raw/opus.md`, `raw/codex.md`, `raw/doxa-{openai,perplexity,gemini}.normalized.md`;
`manifest.json`; `operations/codex.json`; the consumed prerequisite
`research/topics/49-build-target-declaration/DECISION.md`; the R67 and R69 rows of
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` lines 78, 218 and 224;
`docs/planning/p02/owner-decisions.md` §12–§13; R50's latest run decision; and the
committed evidence logs under `review/evidence/`. No `review/audit-*.md` file and no
`review/R68-r1-snapshot.md` was read.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass** | The Subject B table, the size table and `## Engines` item 1 all state −24.5% / −16.0% / −1.3%. The build-time table and `## Engines` item 9 carry the same five clean-build pairs. "Declare no custom profile" is reconciled with the conditional `[profile.dist]` stub by the table row "none of this item's own" and by AC6. Minor wording drift only: line 382 says 52/93 "unique `cargo tree` lines", while line 636 says "52 crates … 93". |
| JF-2 prompt questions and constraints | **fail** (finding 3) | All five Subject A questions and all six profile questions are answered. The Linux measurement gap is disclosed under "What is unproven", with a P03 proof. The licence gate is recorded as `inapplicable — owner ruling 2026-09-12 (Q7.B)`. The owner-reference `lto = "thin"` row is disposed of on the record. **Gap:** prompt line 59 requires the Cargo Book profiles chapter to be cited for every key's default, permitted values, inheritance rule and override precedence, with a retrieval date. `profiles.html` appears 0 times in the decision. Engine coverage is scored under JF-3. |
| JF-3 `## Engines` fidelity | **fail** (finding 1) | The decision says "Codex — **absent, by owner direction**" (line 525) and "No Codex lens ran" (line 646). The run record contradicts both statements: `manifest.json` `required_engines` = `['codex', 'opus', 'doxa']`, and its events show codex `submitting` at 2026-09-20T07:02:42Z and `succeeded` at 2026-09-21T03:00:44Z. `operations/codex.json` records `state: succeeded`, model `gpt-5.6-terra`, raw sha256 `297219ed…`, with the note "shape crate OK". Revision 2 is dated 2026-09-26. The Opus and Doxa representations were spot-checked and are faithful (details under JF-4). |
| JF-4 load-bearing claims trace | **pass**, with one claim not verifiable here | `profile-probe.r2.log` matches every SIZE, DELTA and BACKTRACE figure in the decision: 1994032 / 1504528 B; −24.5, −16.0, −1.3, −14.9, +12.9, +21.8, −22.9, 0.0, −20.2, +12.5 %; frames 4/4/0/2/5; exit 134; `at ./src/` 2 → 0. The alt-paths log shows `lto=fat` at −19.0%. `raw/opus.md` 463–476 is within 1.0 pp on every row (fat −18.8, thin+cu1 −16.7, recommended −24.4). `artifact-sources.log` confirms `ubuntu-latest` count 0, config.md:1277 "undrafting…", CHANGELOG 2274 under `# Version 0.0.3 (2023-02-27)`, 23 assets, `cargo install cargo-dist` count 0, SUPPORT.md 124/148, `$bin-$target`, and `force-tag-creation` at 217–221. COMMONALITY 78/218/224 are F072/F214/F220. R67's taxonomy (0,1,2,3,4,5,130,143) contains neither 101 nor 134. R50 builds with `--debug`. Gemini's `rustc 1.81.0` / 36.2 MB / "approximately 120 transitive" appear at `doxa-gemini.normalized.md`:103–110. **Not verifiable under this audit's read restrictions:** the 2.0 pp figure attributed to `review/audit-claude.r1.md` runs 3c/3d, which sets the ±2.5 pp tolerance. |
| JF-5 couplings handed, not decided | **fail** (finding 2) | The R51, R50 and R22 hand-offs are correct, and none of them decides the receiving item's choice. R49 is not handed the trigger that its own published decision says this item fires. |
| JF-6 assumes lines byte-identical | **pass** | A Python comparison against the `docs/port/PARAMETERS.md` value column returns True for all five lines: `build-tool-output-shape`, `msrv-policy`, `rust-edition`, `target-os-matrix` and `license`. No backticks appear. The empty `- owns:` line is honoured. |
| JF-7 no conflict with accepted/published prerequisite values | **pass**, qualified | The R49 prerequisite hashes match `inputs/prerequisites.json` (decision `86b7f925…`, acceptance `3295e8a0…`). The R49 values used are faithful: `rslbp` ≠ `rs-launch-blueprint`, `target/<triple>/release/`, and `autobins = false`. No hard conflict is demonstrated: "no build-orchestration crate" reads as a prohibition on Cargo dependencies, and dist is a host executable. The unexamined "CONFLICT: none" is scored under finding 2. |
| JF-8 evidence scripts exist; counts match | **pass** | `profile-probe.sh`, `artifact-sources.sh` and `decision-self-check.sh` exist. The three r2 probe logs each have 21 `ASSERT` lines and end `RESULT: PASS`. `artifact-sources.r2.log` and `decision-self-check.r2.log` each have 26 and end `RESULT: PASS`. `profile-probe.Cargo.lock` hashes to `2756d45c…1082`, has 85 `name =` entries, and that hash is printed in the log. The claimed "1 994 112 in revision 1's log" matches `profile-probe.log`. |
| JF-9 decision shape | **fail** (inherits finding 1) | The H2s appear in order: Decision, Parameters, Empirical check, Engines. There is no `## Supersedes`, which is correct because no revision was published. `### Principles and implementation` and `re-verify:` are present. RUNBOOK §5 requires `## Engines` to list "all reports", and one collected report is missing. |
| JF-10 recommendation follows from the assembled evidence | **pass**, caveated | The recommendation follows from the evidence the decision assembled. That evidence omits the one other engine that measured profiles, and that engine disagrees on `lto` and `strip` (finding 1). Whether the recommendation survives adjudication is for the next revision to show. This audit does not assert that the recommendation must move. |

## Unresolved findings

### 1. JF-3 (also JF-2, JF-9) — the Codex report is misrecorded as absent

**Failed claims (quoted):**

- line 513: "the only engine that measured anything"
- line 525: "Codex — **absent, by owner direction.** The Wave 1 Codex engine is skipped under `docs/planning/p02/owner-decisions.md` section 12, row `W1-CODEX`."
- line 646: "**No Codex lens ran** (owner direction, `W1-CODEX`)"

**Evidence:**

- `manifest.json`: `required_engines` = `['codex','opus','doxa']`. Its events show codex `submitting` 2026-09-20T07:02:42Z, then `succeeded` 2026-09-21T03:00:44Z.
- `operations/codex.json`: `state: succeeded`, `raw_sha256: 297219edca2cbdaf2ce69069cf5a9bd562796daa4da5376c1e5b9ead80ae699b`.
- `raw/codex.md`: 48 183 bytes, modified 2026-09-20. The decision was modified 2026-09-26.
- The cited authority is stale on its own terms. The same §12 table records `W1-CODEX3` (2026-09-18): "Test Codex if it's available now, and if it is, use it."

`raw/codex.md` takes measured positions that contradict the decision. None of them appears in `## Engines`:

| Codex position | Location in `raw/codex.md` | Decision's position |
|---|---|---|
| dist pin `0.32.0`, range `>=0.32.0, <0.33.0`; "cannot substantiate 0.33.0" | `### Dominant choice`; `### Recommendation` | `0.33.0` |
| four targets, including `aarch64-unknown-linux-gnu` | `### Recommendation` | three targets. `## Engines` item 5 attributes the four-target view only to Doxa/OpenAI |
| `lto = "thin"`, on measured build time. Fat + cu1 is 47.39 s clean and 18.99 s edit; thin + cu1 is 28.22 s and 7.35 s (rustc 1.98.0, same host model) | `### Recommendation` table; `### Tradeoffs` | `lto = "fat"`. `## Engines` item 1 attributes `"thin"` only to Doxa and the owner reference |
| `strip = "symbols"` written | `### Recommendation` table | `strip` silent. `## Engines` item 2 does not list Codex |
| `[profile.dist] inherits = "release"` written, "because cargo-dist always builds with profile dist" | `### Recommendation` table | "Unresolved … whether dist 0.33.0 requires the stub" |
| README: mention binstall only after the smoke test proves it | `### Migration implications` | binstall listed first |
| runner-up: crates.io-only | `### Ranked runner-up` | `taiki-e/upload-rust-binary-action` |

**Repair:**

- Add the Codex report to `## Engines` with its sha256, model and collection date.
- Delete the three quoted "absent / no lens / only engine that measured" statements.
- Adjudicate each disagreement in the table above with evidence. The decision already holds relevant evidence for several of them:
  - the 0-frame `strip = "symbols"` backtrace answers `strip`;
  - the 1.3–1.9× clean-build spread is consistent with Codex's 1.7×, and bears on `lto`;
  - the GitHub-installer-script bootstrap argument answers the `0.33.0` pin.
- Codex's 2.6× edit-rebuild penalty for fat LTO must be weighed explicitly.

This finding requires a fidelity repair. It does not by itself require the recommendation to change. If the recommendation does move, the owner acceptance `W1-R68`, bound to revision 1 `070b7ae1…`, needs re-asking under the §13 rule.

### 2. JF-5 — R49's fired re-verify trigger is not handed to R49

**Failed claims (quoted):**

- line 309: "`CONFLICT:` lines: **none** — no consumed parameter has to change."
- lines 281–286 list the hand-offs as "to **R51** … to **R50** … to **R22**". R49 is not among them.

**Evidence:** R49's published decision (sha `86b7f925…`, lines 889–890 and 1041–1046) names **A4** as its ranked runner-up. A4 is "Cargo plus an orchestration layer, `dist` specifically". R49 says A4 "wins if **R68 resolves F214 to cross-compiled release binaries**". It lists that event as a re-verify trigger, "which requires re-checking whether `dist`'s `[workspace.metadata.dist]` deprecation has become a removal at the version R68 would adopt". Its lines 877–885 also record that adopting dist moves away "from the one-file declaration that behavior B1 names".

R68 selects dist `0.33.0` with a new `dist-workspace.toml`. A search of the decision for `A4`, `orchestration`, `declaration surface` and `workspace.metadata.dist` finds 0 matches.

**Repair:**

- Add an R49 hand-off stating that this decision fires R49's A4 trigger.
- State that the `[workspace.metadata.dist]` deprecation-versus-removal re-check at `ref=v0.33.0` is R49's to run.
- State, with reasoning, whether `dist-workspace.toml` is a "declaration surface" under the consumed value "Cargo's own manifest is the entire declaration surface … no build-orchestration crate". The "CONFLICT: none" line must then be the result of that examination, not an unexamined assertion.
- Do not decide R49's re-verification.

### 3. JF-2 (minor) — the Cargo Book profiles chapter is uncited for key defaults

**Failed claim:** the Subject B table's "Cargo's documented default" column states defaults for `lto`, `codegen-units`, `opt-level`, `strip`, `panic` and `debug` with no URL and no retrieval date.

**Evidence:**

- Prompt line 59 requires: "Cite the Cargo Book's profiles chapter (`https://doc.rust-lang.org/cargo/reference/profiles.html`) for every key's documented default, permitted values, inheritance rule and override precedence, with its retrieval date."
- Prompt line 123 requires that "Every claim carries a source URL and retrieval date".
- `profiles.html` occurs 0 times in the decision.
- `artifact-sources.log` fetches the page (line 12), but for the six keys it records only key-name counts (lines 13–17), not the default values the table states.
- The decision does not state permitted values or override precedence.

**Repair:** cite the profiles chapter URL with its retrieval date in the Subject B table or a footnote. Quote, or have `artifact-sources.sh` assert, each stated default. Add one line each on the inheritance rule and the override precedence (for example, `--config` over the manifest), which the probe itself relies on.
