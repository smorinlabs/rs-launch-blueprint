actor: audit-fable-r84r3-s4w2
model: claude-opus-5-5
family: anthropic
decision-sha256: 9422d1d10c8a534c43b62d615d8a17f065bd889f1eb04244ca5d61d2b9b636d9
verdict: reject
unresolved-findings:
  - JF-8-A: the documented reproduction command for the 0.19.0 log cannot reproduce it
  - JF-1-A: trigger 8's release-free date is stale against trigger 3's own record
  - JF-4-A: the TypeScript-client row is attributed to owner-decisions section 11 without reconciling R69's published hand-off

# Judgment audit — R84 openapi-typed-client-generation, DECISION.md revision 3

**Target.** `research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/DECISION.md`, 738 lines.
`shasum -a 256` recomputed on 2026-09-26: `9422d1d1…b636d9`, equal to the expected hash.

**Scope and blindness.** This audit judges reasoning and fidelity, not execution. It read the
decision, `inputs/prompt.md`, `research/RUNBOOK.md`, the three pinned raw reports under `raw/`
(sampled at the lines cited below), the evidence scripts, logs and snapshots under
`review/evidence/`, the live `docs/port/PARAMETERS.md`, the published decisions for R42 and R69
under `research/topics/`, `docs/planning/p02/owner-decisions.md` section 11, and the REST API
Design Standard at the pinned commit. It read no `review/audit-*.md` file of any seat or
revision and no `review/R84-r*-snapshot.md`. It ran no evidence script, no git write and no
`scripts/research_runner.py` command.

**Public queries.** One read-only `GET https://crates.io/api/v1/crates/openapi-to-rust/versions`
on 2026-09-26 returned: `0.19.0` created `2026-09-26T14:29:43Z`, `0.18.0` created
`2026-09-25T20:29:21Z`, `0.17.0` created `2026-09-14T17:28:43Z`, all non-yanked; 35 non-yanked
versions; oldest `0.1.0` created `2026-02-13T22:25:37Z`.

## Verdict

**Reject.** Three findings, listed below. None moves the recommendation (`openapi-to-rust`
pinned at `0.17.0`, on-demand `just client-rust` recipe, uncommitted out-of-workspace output,
`OVERRIDE (OV-11)` on R12.6). Finding JF-8-A is load-bearing: trigger 3's "EXECUTED" status
and the claim that every section-12 disposition holds at `0.19.0` rest on a log whose stated
reproduction path produces a different result.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **Fail** (JF-1-A) | Otherwise consistent. The count sentences agree with each other and with the snapshot: 35 live versions, 33 dated 2026-02-13..2026-09-14, plus `0.18.0` and `0.19.0`. The pin, the range `>= 0.17.0, < 0.18.0` and trigger 3's hold reason agree across lines 101–107, 297–307, 322 and 426. |
| JF-2 prompt questions and constraints | Pass | All six prompt questions are answered in the table at lines 175–182. The three survey bins, fitness gates per candidate, shortlist fields, runner-up with its win conditions, tradeoffs, file-level migration, and the executed-versus-planned split (AC1–AC10) are all present. The Linux gap under "CI on ubuntu-latest, macos-latest" is disclosed (AC9, `G09`) rather than hidden. The empty `owns:` line is honoured (`A01`). |
| JF-3 engines represented and disagreements adjudicated | Pass | Sampled positions match the raw reports. Muse recommends a committed output with `generate --check` (raw `muse-…md:302-313`), names progenitor as runner-up only "if and when Oxide ships OpenAPI 3.1 support" (`:316-324`), and lists "None" under Excluded by gate (`:261-267`). Opus recommends OpenAPI Generator with `supportAsync=false` (`opus-…md:417-435`) and root `exclude = ["clients"]` (`:445`). Opus's 3.1 issue search "returns `total_count: 0`" (`:313`). Doxa-OpenAI proposes a committed `crates/api-client` (`doxa-…md:530-533`), states "zero candidates are fully evidence-complete" (`:378`) and emits `BASELINE-REVIEW: F335` (`:304`). Perplexity declares `owns` lines (`:1188-1196`). Each of the four disagreements is settled on checks (`E04`/`E05`, `A06`/`A07`, `E01`, `E06`/`E07`, `B04`–`B06`, `D01`–`D03`, `P02`), not on engine counts. Opus's root-`exclude` mechanism is superseded by the nested empty `[workspace]` table. Cargo documents both mechanisms (quoted at `opus-…md:403`), and `T11`/`T13` show the nested table works under a root workspace. |
| JF-4 load-bearing claims trace to sources | **Fail** (JF-4-A) | Spot-checks that passed: the standard at `0850d43e` states R4.1 at `:742-747`, R5.12's "when the client requests it" at `:1019-1021`, R12.6 at `:1815-1817`, R12.7 at `:1819-1822` and R1.7 at `:272-273`, each as quoted. Snapshot figures match the decision: 37 stars; 45,945 / 46,601 downloads; 0 reverse dependencies; 26,764 stars for OpenAPI Generator; LanceDB 1,718,864 90-day downloads; `meteora-api` 20 downloads; issue-close median 1.445 days recomputed from the ten `closed_after_days` values; 10 of 10 issues with no maintainer comment; the pushed dates. R42's `cargo binstall --locked --no-confirm` recipe matches `research/topics/42-*/DECISION.md:27`. Trigger 3's dates match the crates.io query above. |
| JF-5 couplings hand over owned choices | Pass | R71 receives requirements N1–N4 and no decision. R70's server behaviour is left open (coupling 7, option (a)). R11 is asked for no job. R83 is not constrained. R02 and R05 are cited by criterion (`A09`, `A10`), not re-decided. |
| JF-6 `assumes` lines equal the live registry | Pass | Each of the five `- assumes` values equals column 3 of its row in the live `docs/port/PARAMETERS.md` exactly, by whole-cell comparison, and also appears in `inputs/PARAMETERS.md`. R69 revision 10 appears only in the prose note at lines 529–535. |
| JF-7 no conflict with accepted or published prerequisite values | Pass | No consumed value is contradicted, and no `CONFLICT:` line is needed. R49's "no build.rs" (`A08`) and R42's bare-on-`PATH` rule are honoured. The R69 routing question is a prose hand-off, not a value; it is recorded under JF-4-A. |
| JF-8 evidence scripts exist and counts match | **Fail** (JF-8-A) | All five scripts exist. Log summaries match the decision's table: `source-claims` 60/0/0; `openapi-to-rust-probe` 31/0/5; `progenitor-probe` 6/0/0; `registry-figures` 31/0/0; `probe-0.19.0` 31/0/5. `diff` of the two probe logs shows only `T01`. `r84-archive-rerun.log` shows the single `A13` PASS→SKIP difference exactly as described. The timings file carries 116 s, 44 s and 16 s, as cited. |
| JF-9 decision shape | Pass | H2s `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in RUNBOOK §5 order. `### Principles and implementation` sits inside `## Decision`. F335 is settled and a `re-verify:` line is present. There is correctly no `## Supersedes`, because nothing is published for R84. |
| JF-10 recommendation follows from the evidence | Pass | The choice rests on four checks that were assembled before the verdict (Disagreement 1, (a)–(d)). The runner-up's win conditions are stated as testable events. The main risk, thin adoption, is carried as a stated cost rather than argued away. |

## Findings

### JF-8-A — the documented reproduction command for the 0.19.0 log cannot reproduce it

**Claim.** Lines 626–627: "The supplementary `r84-openapi-to-rust-probe-0.19.0.log` is not an
archive leg; it reproduces from the last command in the block above and differs from the
committed `0.17.0` log only in `T01`." Lines 105–107, 297–302 and 588 rely on that log
("EXECUTED", "31 PASS, 0 FAIL, 5 SKIP", "every section-12 disposition still holds").

**Evidence.** The block's last command (line 573) is
`TOOL_VERSION=0.19.0 R84_TIMINGS="$O/probe-0.19.0-timings.txt" "$E/r84-openapi-to-rust-probe.sh"`.
It runs directly after the loop at lines 568–570, which runs the same script at the default
`TOOL_VERSION=0.17.0`. Neither command sets `R84_CACHE` or `TMPDIR`. In
`r84-openapi-to-rust-probe.sh`, the relevant lines are:

- Line 51: `CACHE=${R84_CACHE:-${TMPDIR:-/tmp}/r84-synth-cache}`, so both runs share one cache.
- Line 78: `BIN="$CACHE/o2r/bin/openapi-to-rust"`. The path is not version-qualified.
- Lines 79–83: `if [ ! -x "$BIN" ]`. Installation is skipped whenever any binary is already present.
- Line 85: the script puts that directory first on `PATH`.
- Lines 87–88: `T01` requires `openapi-to-rust --version` to equal `openapi-to-rust $TOOL_VERSION`.
- Line 161: `T10` requires the header `Generated by openapi-to-rust v$TOOL_VERSION`.

After the loop has installed `0.17.0`, the documented `0.19.0` command finds that binary and
skips installation. It then generates with `0.17.0`, so `T01` and `T10` FAIL. The committed
`0.19.0` log (whose `T01` reports `0.19.0`) must therefore have come from a different cache
than the one the documented block uses. This is the same class of defect that revision 3's
header says it repaired: a rerun harness that does not reproduce the cited files. Here the
defect is in the version-switch leg, not the output paths.

**Repair.**
1. Give the `0.19.0` command its own cache in line 573, for example `R84_CACHE="$O/cache-0.19.0"`.
   Alternatively, make `BIN` version-qualified in the script.
2. State in lines 626–627 which cache produced the committed `0.19.0` log.
3. Keep the claim "differs only in `T01`" only once a run through the corrected command has
   confirmed it.

### JF-1-A — trigger 8's release-free date is stale against trigger 3's own record

**Claim.** Lines 319–320: "`openapi-to-rust` goes 6 months without a release (after
2027-03-14) and shows a concrete maintenance-risk signal."

**Evidence.** The decision itself records `0.18.0` on 2026-09-25 and `0.19.0` on
2026-09-26T14:29Z (lines 297–299, 426). The snapshot's newest non-yanked `created_at` is
`2026-09-26T14:29:43Z`, and the crates.io query above confirms it. The earliest date on which
six release-free months can have elapsed is therefore 2027-03-26. The value 2027-03-14 was
computed from `0.17.0`'s 2026-09-14 release and was not updated when trigger 3 fired. The
summary `re-verify:` line (322) does not restate the date, so the stale value lives only in
trigger 8.

**Repair.** Change "after 2027-03-14" to "after 2027-03-26", or state the rule relative to
the newest release, for example "six months after the newest non-yanked release".

### JF-4-A — the TypeScript-client row is attributed to section 11 without reconciling R69's published hand-off

**Claim.** Lines 255–256: "Any TypeScript client: the owner reference's `openapi-typescript`
row belongs to the unscoped SPA head (`owner-decisions.md` section 11)". Line 498 repeats
this: "The SPA head is unscoped (`owner-decisions.md` section 11)".

**Evidence.**
- `docs/planning/p02/owner-decisions.md` section 11 (lines 426–429) lists the
  "HTMX-versus-SPA head" among the rows with no P02 item. It does not mention the
  TypeScript-client row or assign it anywhere. The attribution is therefore the
  synthesizer's inference, but the decision presents it as the section's ruling.
- R69's published decision (`research/topics/69-web-framework-stack/DECISION.md:2188`, in
  its owner-reference overlap map) routes that row explicitly: "C3 | TypeScript client
  generation (`openapi-typescript`, `openapi-fetch`, `ts-rs`) | **R84**".
- R84 consumes R69. Yet the decision never mentions this hand-off from R69, so a reader
  cannot see that a prerequisite routed the row here and that R84 declined it.

This finding does not dispute the disposition. Declining the row as outside F335's Rust
scope is defensible. The finding concerns the trace: the decision cites a source that does
not say what is attributed to it, and it omits the source that says the opposite.

**Repair.** Add one sentence at line 255 or line 498. It should:
- acknowledge R69's routing of the C3 TypeScript-client row to R84 (`DECISION.md:2188`);
- state that R84 dispositions the row as outside this item's Rust-client scope (F335);
- state that the row is pending owner scoping, alongside the SPA head that section 11 leaves
  unscoped;
- describe the link to section 11 as R84's reading, not as that section's text.
