actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: bf71fda79b6b51278c5c54f945f2154606b7ba762d1e49578e4dcc64b0cbb900
verdict: approve
unresolved-findings: JF6-1 (MECHANICAL, approve-with-repair) — stale R50 locators; exact repair below

# R68 — judgment audit, revision 6 (release-binary-artifacts, crate, Deep)

Audited file: `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`.
I recomputed its sha256 with `shasum -a 256` on 2026-09-27. The result is
`bf71fda79b6b51278c5c54f945f2154606b7ba762d1e49578e4dcc64b0cbb900`, which matches the expected
hash (86 775 bytes).

Severity rule applied: this is an r2+ audit, so the verdict is `reject` only for a BLOCKING
finding. No BLOCKING finding was found. There is one MECHANICAL finding, so the verdict is
approve-with-repair.

Sources read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §5, the decision
contract; `raw/codex.md`, `raw/opus.md` and `raw/doxa-{openai,perplexity,gemini}.normalized.md`;
the prerequisite decisions `research/topics/49-build-target-declaration/DECISION.md`,
`research/topics/69-web-framework-stack/DECISION.md` and
`research/topics/67-error-and-exit-code-contract/DECISION.md`; R50's in-flight run decision;
R51's prompt; `docs/port/COMMONALITY.md`; `research/CLAUDE.md`. I read no `audit-*.md` file and
no `R68-r*-snapshot.md` file.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | Every figure agrees across `## Decision`, `## Empirical check` and `## Engines`: −24.5%, −16.0%, −14.9%, 171 200 B, 8.5 pp, 18 s → 25 s and 1.2×–1.6×. The r6 edits agree with each other. The `features` row (line 163), the *Web* paragraph (lines 372–383), re-verify trigger (8) (line 432) and the R51 hand-off (lines 401–403) all state R51's image as conditional. The `install-updater` row (line 162) and the `axoupdater` exclusion (lines 354–358) describe the same separate `<package>-update` program. |
| JF-2 prompt questions answered, constraints honoured | pass | Both subjects are answered. Subject A covers the five artifact questions: dist maintenance and follower-mode integration; binstall inference; three triples against the fixed matrix; S1's cost; and release-path CI cost under gate 6 with shape S1. Subject B covers profile questions 1–6. Question 6, the MSRV and matrix effect, is answered in `## Parameters` prose. The profile row records one agreement and one difference with the owner reference, citing its *Reference `Cargo.toml`* section. Gate 1 is recorded as `inapplicable` under Q7.B. Profile question 2 asks for measurement on each OS; Linux was not measured. That gap is disclosed under *What is unproven* with a P03 proof path, so it is not blocking. |
| JF-3 `## Engines` fidelity and adjudication | pass | Engine positions were spot-checked in the raws. Doxa/OpenAI states `lto = "thin"` (line 245) and says its profile experiment was "not executed" (lines 13 and 271). Doxa/Gemini states `lto = "thin"` (line 119). Perplexity executed no build (line 170). Codex's rows at `raw/codex.md` lines 584, 588 and 589 match Disagreements 1 and 9 exactly: 29.04 → 47.39 s, 28.22 → 47.39 s and 7.35 → 18.99 s. Disagreement 1 represents Codex's `thin` recommendation and weighs it. The raw sha256 values `297219ed…` and `b75fa7ab…` match. All 13 disagreements are adjudicated with evidence or explicitly left unsettled (Disagreements 4 and 9). |
| JF-4 load-bearing claims trace to sources | pass | Every `SIZE`, `DELTA` and `BACKTRACE` figure matches `profile-probe.r2.log` (the 12 rows; frames 4/4/0/2/5; exit 101/134). `TIME` lines 42, 44 and 102–104 match. The r6 claims were checked live: `gh api … ?ref=v0.33.0` for `book/src/reference/config.md` and `book/src/installers/updater.md` hashed to `1b45ad79…` and `b63bd80f…`, the values the decision states. `config.md` lines 911–927 describe the `install-updater` standalone `yourpackage-update` program with default `false`. `updater.md` lines 7–24 say the same and separate it from the library crate. `config.md` line 1277 contains the undrafting sentence. R51 prompt lines 30 and 35 are the asked image question. `research/CLAUDE.md` lines 55 and 56 show R50 and R51 as `open`. `COMMONALITY.md:227` is F223. The R49 citations were checked: lines 889–891 hold the A4 winning condition and lines 1042–1047 hold the re-verify trigger. The R50 locators are stale; see JF6-1. |
| JF-5 couplings hand over owned choices without deciding them | pass | The r5 defect is repaired. The web binary's delivery is now stated as R51's open F223 decision, conditionally, with trigger (8). The R49 A4 re-check is "R49's to run". The R50 hand-off is conditional on R50's unaccepted `--debug`. The R22 hand-off is an observation. R67's taxonomy is consumed, not altered: its `owns` row lists 1, 2, 3, 4, 5, 130 and 143, and neither 101 nor 134. |
| JF-6 `- assumes` lines byte-identical to the live registry | pass | I re-ran `decision-self-check.sh` into `/tmp/r68-fable-r6-selfcheck.log`: exit 0 and 30/30 assertions. Section 3 asserts that all five `- assumes` lines are byte-identical to the working-tree `docs/port/PARAMETERS.md`. The run differs from the committed `decision-self-check.r6.log` only in its `date(UTC):` line. The empty `- owns:` line is respected. |
| JF-7 no conflict with accepted or published prerequisite values | pass | R49's `rslbp`/`rs-launch-blueprint` pair, `[package] include`, and `target/` layout are consumed unchanged. R69's `[[bin]] required-features = ["web"]` (R69 line 683) and `web = ["dep:axum","dep:tokio"]` (line 1586) match the stand-in and the `features` row. R67's contract is untouched. `CONFLICT: none` is argued rather than assumed. |
| JF-8 evidence scripts exist and counts match | pass | `profile-probe.sh`, `artifact-sources.sh`, `decision-self-check.sh` and every cited log exist. `decision-self-check.r6.log` has 30 `ASSERT ok` lines, matching the claimed 30. The lockfile sha256 assertion holds. |
| JF-9 decision shape follows the contract | pass | The H2s are exactly `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in that order. `### Principles and implementation` sits under `## Decision`. The `re-verify:` line is present. There is correctly no `## Supersedes` section, because no revision was ever published. This matches RUNBOOK §5. |
| JF-10 the recommendation follows from the evidence | pass | Subject A: dist is the only candidate that produces the full AC1 set from one configuration. The runner-up's `$bin-$target` naming breaks binstall's `{ name }` inference for this crate/binary name pair. Subject B: `fat` + cu1 beats the reference's `thin` + cu1 by 8.5 pp. The marginal build cost is weighed explicitly. `strip`, `panic` and `debug` are refused on measured backtrace and exit-status evidence. `opt-level` `s`/`z` lose on size. The r6 edits change prose only and move no setting. |

## Findings

### JF6-1 — MECHANICAL (approve-with-repair): stale R50 revision and line locators

**Failed claim.** Decision lines 404–415 say:
> "Its in-flight run decision, `research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md` (revision 6, read 2026-09-27; no digest is pinned, because that file's bytes changed while this revision was being written, with its revision header and the line numbers cited here unchanged), currently proposes an install smoke test that builds with `--debug` (lines 7, 116 and 335), a dev-profile compile (line 433). … (line 981) … (13) (line 564)"

Lines 662–663 and 800–801 repeat "R50 run decision revision 6, lines 7 and 433".

**Evidence.** On 2026-09-27 that file's title line reads
`# 2026-09-17 — R50 — install-smoke-test (bundle, Focused) — decision (revision 7)`.
Its revision header and line numbers therefore did not stay unchanged. The substance still
holds in revision 7:

| Cited content | Line cited by R68 | Line in R50 revision 7 |
|---|---|---|
| `--debug` in the install command | 7 | 7 |
| `--debug` in the recipe | 116 | 111 |
| `--debug` in AC3 | 335 | 331 |
| `dev-profile compile` | 433 | 429 |
| "R68's release build as the only release-profile compile the template is currently expected to perform" | 981 | 977 |
| re-verify trigger "(13) R68 (`release-binary-artifacts`) resolving" | 564 | 560 |

The hand-off is still correctly conditional, and trigger (7) still covers R50 moving. No
recommendation, coupling or figure depends on the stale numbers, so this finding is not
BLOCKING.

**Repair.** R50's run decision is uncommitted and still changing: `git diff --stat` shows 418
insertions since its last commit on 2026-09-17. Hardcoded line numbers will therefore stale
again. In all three places (lines 404–415, 662–663 and 800–801):
1. **Primary repair:** cite each R50 statement by its quoted text instead of by line number.
   Use the anchors `--locked --debug --no-track`, `dev-profile compile`, "R68's release build
   as the only release-profile compile the template is currently expected to perform" and
   "(13) R68 (`release-binary-artifacts`) resolving". The table above records where each
   anchor sits in revision 7 on 2026-09-27.
2. Change "revision 6" to "revision 7, read 2026-09-27".
3. Replace the false parenthetical "with its revision header and the line numbers cited here
   unchanged". State instead that the file is uncommitted and in flux, so its citations are
   anchored by quoted text.
4. If line numbers are kept anyway, use the revision-7 values: 7, 111, 331, 429, 977 and 560.

JF-3 note: Doxa/Perplexity also states `lto = "thin"` (`doxa-perplexity.normalized.md` lines
3, 15, 79, 91, 131, 137 and 166). The claim in Disagreement 1 that all three Doxa providers
recommend `thin` is therefore fully supported.
