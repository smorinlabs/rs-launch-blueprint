actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 844506614cbf6ff2a7ef4a816a7b3eea9e2d6804c34191d097e35209fb27b612
verdict: approve
unresolved-findings: none

# R10 — judgment audit of DECISION.md revision 6

**Target.** `research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/DECISION.md`.
`shasum -a 256` returned
`844506614cbf6ff2a7ef4a816a7b3eea9e2d6804c34191d097e35209fb27b612`. That equals
the expected hash, so the audit proceeded.

**Scope.** This audit judges reasoning and fidelity. It does not judge
execution: no evidence script was rerun. Figures and log lines were
spot-checked by reading the committed files.

**Read.** The decision; `inputs/prompt.md`; `inputs/prerequisites.json`;
`research/RUNBOOK.md` §2 and §5; both raw reports under `raw/`; the committed
`review/evidence/` logs and `figures/` snapshots; the R11, R42, R20 and R19
`DECISION.md` files; R11's and R42's `acceptance.json`;
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md:41–42`;
`docs/port/OWNER-REVIEW.md:40–47`; `docs/port/README.md:75–77`; and
`docs/planning/p02/execution-ledger.md:1176`.

**Not read (audit blindness).** No `review/audit-*.md` file of any seat or
revision was read, and no `review/R10-r*-snapshot.md` file was read or hashed.
As a result, two kinds of claim in the revision notes were not verified: which
findings the earlier audits raised, and the hashes of the earlier snapshots.
The substance of the revision-6 correction (JF5-1) was verified directly
against R11's published decision; see JF-1.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | The revision-6 correction is applied in all four places it names, and the four places agree. The places are trigger (6) at `:505`, `## Parameters` at `:544–550`, gate 6 at `:805–809`, and the `save-if` confidence clause at `:956–959`. Each place states two counts. R10's own step: 3 job ids and 4 entries (`check` ×2, `msrv-floor` ×1, `install-smoke` ×1). R11's published count: 4 cache-bearing ids on `ubuntu-latest` and 5 job-runner pairs, with R04's semver job as the fifth. The corrective rows in the revision-5 note (`:47–48`) state the same figures. The pin, the version range `>= 2.9.1, < 3`, the three inputs, the placement and the trigger dates agree everywhere in the document. Two phrasings are loose but not wrong. First, trigger (6) says "at or under" the six-per-OS threshold, while the revision note says "under"; with 4 ids, both hold. Second, `:771` says the last push was "within five weeks", but `pushed_at` 2026-09-07 is 10 days before retrieval; the statement is true, just imprecise |
| JF-2 prompt questions and constraints | pass | All four `## Questions` items are answered explicitly under `## Decision` (`:213–286`): HIGH derived vs hand-written key; HIGH the two-key split; MEDIUM the #341/`ImageOS` platform difference; LOW workspace plus the matrix caveat. Out-of-scope items are respected. The decision does not choose the toolchain-install action (R42) or the job topology (R11), and it cites no owner prior art. Every fitness gate is recorded with a reason, and none is silently omitted (`:789–812`). Crate figures are marked `inapplicable` with the reason, and `sccache` crate figures are given in full. The `BASELINE-REVIEW:` line follows the prompt's required form. The decision states that no `CONFLICT:` line is emitted |
| JF-3 `## Engines` fidelity | pass | The raw-report hashes match their filenames (`74afacbc…`, `49b673ae…`), and `codex.md` and `opus.md` are byte-identical to their hashed copies. Codex: it recommends `actions/cache@v6` (`raw/codex.md:43`); the quoted key and restore prefix are verbatim at `:43`; the LGPL gate-1 exclusion is at `:29`; the "would win only if…" and "maintained Cargo-aware keying…" quotations are both at `:47` under `### Ranked runner-up`; the retrieval date 2026-09-16 appears on line 3; 5,549 stars is at `:23`; "a failed job does not save a new cache" is at `:13`; 2.75 hours is at `:29`; the "no equivalent integrated toolchain action" claim is at `:3` and `:9`; and the report has no `CONFLICT:` line and no `BASELINE-REVIEW:` line. Opus: 5550 stars is at `raw/opus.md:247`; 0.11 d for #337 is at `:231`; the `BASELINE-REVIEW: F036` line is at `:191`. All five disagreements are adjudicated with evidence. In disagreement 2, Codex's key is fairly distinguished from GitHub's published recipe instead of being flattened into it |
| JF-4 load-bearing claims trace | pass | Spot-checked against `r10-pinned-sources.log`: A1.1–A1.4 (tag `63fed3e2…` resolves to commit `6323deb1…`), A2.2, A2.3, A2.6, the eight A2.7 defaults, A3.2–A3.8, A4.2, A4.5 (0), A4.6 (2), A5.1, A6.1–A6.3, A7.1–A7.3, A8.1, A8.2, A9.3 (4), A9.4–A9.7, and A12.py (6) / A12.ts (2). Spot-checked against the cited sources: the owner ruling heading is at `OWNER-REVIEW.md:47`; the F035 and F036 rows are at `COMMONALITY.md:41–42`; the OVERRIDE rule is at `README.md:77`; the R11 cache-budget table and arithmetic are at R11 `DECISION.md:212–219`; the R04 slot row is at `:290`; R11's re-verify line is at `:316`; the R42 `cargo binstall --locked --no-confirm` body is at R42 `:27`; and R42's integrity paragraph is at `:99` |
| JF-5 couplings hand off, do not decide | pass | R11 decides which job ids carry the step (`:164–168`, `:481–484`). The feature-matrix remedy is handed to R11's workflow. The `cache-bin` integrity posture is stated to be R42's (`:364`). Runner-up E is left as R42's option (trigger 5). The Dependabot obligation matches R19's published `github-actions` entry with `directory: "/"` (R19 `DECISION.md:43–44`). The docs note is placed on R81's surface. The F036 ledger edit is routed to the controller. The Node-24 runner requirement is noted as a coupling for R09 |
| JF-6 assumes lines byte-identical | pass | All four `- assumes` lines were compared programmatically with the value column of the live `docs/port/PARAMETERS.md`, and all four matched. This agrees with log assertion group A10 (4 PASS). The absence of `owns` and `consumes` lines is consistent with the prompt's empty `owns:` and `consumes:` fields |
| JF-7 no conflict with accepted or published prerequisites | pass | R42 `DECISION.md` hashes to `a2504aa7…` and R42's `acceptance.json` hashes to `a3732b42…`; both equal `inputs/prerequisites.json`. R11 is published: ledger `:1176` records transaction `09a0da6c` on 2026-09-25, and live row 12 carries the value. The decision's R11 statements match that value: `hygiene` has no cache step; `check` has feature-off and feature-on steps sharing one `target/`; a Cargo-feature matrix is forbidden, and the quoted reason is verbatim; the budget formula is the sum over cache-bearing job ids of each id's runner count. R20's full-SHA rule for non-`actions`/`github` owners is at R20 `:49–50`, and the recommended line complies with it |
| JF-8 evidence scripts exist and counts match | pass | Both scripts and both logs exist. The log ends with `checks: 60 passed, 0 failed, 0 skipped` / `VERDICT: PASS`, and it contains 60 `PASS` lines and 0 `FAIL` or `SKIP` lines. All 17 snapshots carry `retrieved: 2026-09-17 (UTC)`. Their values match the figure table: stars 1917 / 5550 / 403 / 206 / 133; open issues 69 / 163 / 3 / 16; the four releases and dates; the `sccache` crate figures (129817, 1335826, 0.18.0, 1.91.0); #341 (closed 2026-05-29, 5 comments, created 2026-05-13); responsiveness (#375 at 0.025 d, #370 at 1.171 d); and RustSec (404, 404, `atty` 200, `serde` 404) |
| JF-9 decision shape | pass | The document has the H2s `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in RUNBOOK §5 order. `### Principles and implementation` and a `re-verify:` line sit inside `## Decision`. There is no `## Supersedes`, which is correct because this revision is not a reversal. `## Empirical check` states the toolchain, OS, working directory, commands and observed output |
| JF-10 recommendation follows from evidence | pass | Once the 2026-09-12 ruling voids gate 1, both engines converge on `Swatinem/rust-cache`: Codex's own runner-up condition is met. The derived two-key split, pruning and per-job-id separation answer P1–P3 better than a hand-written key does for a template meant to be forked. The pin and range rest on A1 and A4.2. `env-vars: "ImageOS"` rests on A3.3–A3.5, A4.5 and #341. Its uncertainty on macOS is carried as a mandatory acceptance criterion (A7) and as row U5, rather than being asserted as resolved |

## Findings

None. The looser phrasings noted under JF-1 ("at or under", "within five weeks")
are accurate as written and change no conclusion, so they are not findings.
