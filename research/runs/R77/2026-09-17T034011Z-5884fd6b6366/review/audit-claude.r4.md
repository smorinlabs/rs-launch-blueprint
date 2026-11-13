actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884
verdict: reject
unresolved-findings:
  1. The reproducibility rule claims to list every kind of line that varies by design, but it does not list three kinds that vary on a rerun (details under "Findings", E1).

# R77 revision 4 — empirical audit (claude)

Target: `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md`, revision 4.
I computed its sha256 with `shasum -a 256` before any other step. The result,
`7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`, equals the expected
value. Audit date: 2026-09-27 (UTC). Working directory: the repository root,
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Environment:
`CARGO_HOME=/tmp/cargo-s37-R77-emp` and `CARGO_TARGET_DIR=/tmp/cargo-s37-R77-emp-target`,
both inherited. All fresh output went to `/tmp/r77audit/`, and nothing was written under
`review/evidence/`.

Scope: this audit judges execution truth and evidence support only. Judgment of the
recommendation belongs to the judgment seat.

## Reruns

Each script ran as
`bash research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/evidence/<name> > /tmp/r77audit/<name-without-.sh>.log 2>&1`.
Each fresh log was compared with its committed log using `cmp`. On a mismatch, `diff`
(committed first, fresh second) was used to show the differing lines.

| Script | Exit | Fresh totals | Committed totals | Compared with committed log | Result |
|---|---|---|---|---|---|
| `sources.sh` | 0 | PASS=84 FAIL=0 SKIP=0 | 84/0/0 | differs only in the line-1 timestamp header | pass |
| `figures.sh` | 0 | PASS=121 FAIL=0 SKIP=0 | 121/0/0 | differs in the header and in 9 `DRIFT … crate.recent_downloads` lines, which are rolling-window counters and are never asserted (for example, `config` snapshot=18581807, live=18843480; `envious` snapshot=66319, live=63483, a decrease) | pass |
| `drift-r4.sh` | 0 | PASS=32 FAIL=0 SKIP=0 | 32/0/0 | differs only in the header | pass |
| `probes-r4.sh` | 0 | PASS=37 FAIL=0 SKIP=0 | 37/0/0 | differs in the header and in line 3, `# inherited CARGO_TARGET_DIR: /tmp/cargo-s27-R77-r4-target` → `/tmp/cargo-s37-R77-emp-target` (see E1) | pass |
| `probes-rerun-r4.sh` | 0 | PASS=6 FAIL=0 SKIP=0 | 6/0/0 | differs in the headers, scratch-directory names, `Finished … in N.NNs` lines, target-directory paths, and the order of one cargo test result line (see E1) | pass (the E1 finding concerns the rule's wording, not this script) |
| `ov-allocation-r4.sh` | 0 | PASS=10 FAIL=0 SKIP=0 | 10/0/0 | differs only in the header | pass |
| `r4-checks.sh` | **1** | PASS=179 **FAIL=7** SKIP=0 TOTAL=186 | 186/0/0 | all 7 failures are in the R74 pin group; line 185, `DRIFT R80 live file is still revision 3` → `has moved past 53b13f45` | failures are an expected pin trip, recorded as observation O1: re-pin due |
| `rest-conformance-r2.sh` | 1 | PASS=90 FAIL=1 SKIP=0 TOTAL=91 | 91/0/0 (revision-2 run) | the single failure is line 87, `FAIL H1 is the date-first revision-2 title`, with expected `…decision (revision 2)` and actual `# 2026-09-27 — R77 — web-env-settings (crate, Focused) — decision (revision 4)`; the `OV-01`/`OV-02`/`OV-03` census lines moved 13→19, 3→10, 7→8 (rule item 5) | expected by design, not a finding; no second failure |
| `fetch-snapshots-r4.sh` | 0 | retriever with no assertions | — | see "The snapshot fetcher" below | manifest matches |

### Details of the `r4-checks.sh` failures

These are the 7 fresh `FAIL` lines, verbatim:

```
FAIL R74 revision 1 (working tree) as read
     expected: 84c01ec019f9ba68b731b56ad846dece449ddecdf8fb6d548530f2dc1b4b3056
     actual:   68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246
FAIL R74 member 1 (line 410)
FAIL R74 member 2 (line 411)
FAIL R74 member 3 (line 412)
FAIL R74 answers the floor (line 414)
FAIL R74 cites OV-17 (line 415)
FAIL R74 hands R77 three fields (line 452)
```

All other groups pass, including every R58 pin and the R80 revision-3 reads from commit
`53b13f45`.

### The snapshot fetcher

`fetch-snapshots-r4.sh` was not run into `evidence/`. I copied it alone to
`/tmp/r77audit/fetch/`, and it ran from there. The script resolves its output directory
relative to its own location, so it wrote to `/tmp/r77audit/fetch/snapshots-r4/`. The run
took from 08:25:51Z to 08:31:02Z, and the script exited 0.

- **Log:** the fresh log is identical to the committed log except for the two
  `# fetch started` / `# fetch finished` timestamps. It has the same 27 `wrote` lines in
  the same order.
- **Manifest:** the file names match the committed `snapshots-r4/` exactly: 27 names.
- **Contents:**
  - `channel-rust-stable.toml` is byte-identical.
  - All 15 GitHub files (7 `gh-repo-*`, 7 `gh-openissues-*`, and the Figment commit list)
    are byte-identical.
  - The 11 `cratesio-*-versions.json` files differ in exactly one JSON path,
    `.versions[].downloads`, which is a per-version download counter. Every version's
    `num`, `yanked` and `rust_version` is identical, and no crate has a new release.

## Figures re-derived at source

Each value below was re-derived from its source and matches the decision:

- **Engine reports:**
  - `raw/muse.md` has sha256 `a2e9a208f6e8bb269ac396ea1f1bff605cb549c403ce676539cbb61dc2123426`
    and 204 lines.
  - `raw/opus.md` and `raw/opus-a81c6372….md` both have sha256
    `a81c6372fe084f805fa4058c68e60af7064b354de69a2a0da0360b9c2a0ac533`.
  - `raw/muse.md` contains `REST`, `R8.1`, `R9.1` and `R11.2` zero times each, counted
    with `/usr/bin/grep -cF`.
- **Prompt and engine policy:**
  - `inputs/prompt.md` and `research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md`
    have the same sha256, `48610c1a…`.
  - Line 24 of the topic prompt is `- engines: muse, opus`.
  - In `manifest.json`, `required_engines` is `["muse","opus"]`, and the migration event
    records `"from": "codex"`, `"to": "muse"`, `"previous_required_engines": ["codex", "opus"]`,
    `"reason": "muse bulk substitution (owner decision Q5.A 2026-09-21)"`. The Muse
    operation state is `submitting`, as the decision states.
  - `research/EXECUTION.json` `engine_overrides.R77` is `["muse", "opus"]`.
  - `RUNBOOK.md:69-75` lists R77 in the bulk set, and `execution-ledger.md:1173` is the
    quoted "R77 MUSE LEG COLLECTED" row.
- **Cited lines:** each line below contains the quoted text.

  | Citation | Content |
  |---|---|
  | `owner-decisions.md:460` | "The ruling is withdrawn" |
  | R57 `DECISION.md:254` | `pub const TOOL_NAME: &str = "rslbp";` |
  | R53 `DECISION.md:67-69`, `:81` | the `serde` sentence; "No dependency is added by this item." |
  | R54 `DECISION.md:303` | the layer-merging-engine alternative is rejected on fit |
  | R58 `DECISION.md:1405` | "first statement of `main`: `telemetry::init(Profile::Service { .. })`" |
  | `raw/muse.md` | `:45`, `:53`, `:71`, `:77`, `:88`, `:89`, `:93`, `:94`, `:102`, `:112`, `:113`, `:118`, `:125` (including "need `unsafe` blocks or an injection seam" and `--test-threads=1`), `:129` |

- **Probe results in my fresh `probes-r4.log`:**
  - P7 prints `p7-runner-up-shape | OK | Multi { port: 9000, graceful_shutdown_seconds: 3 }`
    and `p7-muse-shape | OK | Multi { port: 9000, graceful_shutdown_seconds: 8 }`. This
    reproduces the claim that the silent default is 8.
  - P3r4 prints ``… for key `port` in the environment``, both from the process environment
    and from the injected map.
  - P6r4 measures package count 11 and a delta of 83200 B for `config` 0.15.26 without
    default features. The `confique` delta is 16496 B.
- **`drift-r4.log`:**
  - `config` 0.15.26 was released 2026-09-21 and declares `rust-version` 1.88.0.
  - Figment's `pushed_at` is `2026-09-27T00:54:08Z`, and its default branch has 0 commits
    since 2024-09-14.

## Findings

**E1: the reproducibility rule is still incomplete.**

- **Failed claim** (`## Empirical check`): "The rule for comparing across a re-run, as
  revision 4 states it, lists every kind of line that may vary by design". Item 2 of that
  rule reads: "in `probes.log` only, three lines *inside* cargo's captured output — the
  `mktemp -d` scratch directory name, which is new on every run, and cargo's own
  `Finished … target(s) in N.NNs` wall-time line".
- **Evidence** (my rerun, `diff` of the committed log against the fresh one). No `PASS`,
  `FAIL` or `SNAPSHOT` line changed, so the rule's discriminating sentence still holds.
  Three kinds of varying line are missing from the rule's list:
  1. **Cargo's captured output outside `probes.log`.** The same cargo lines also vary
     inside `probes-rerun-r4.log`, which embeds the output of `probes.sh` twice. The
     phrase "in `probes.log` only" is therefore false.
  2. **The inherited `CARGO_TARGET_DIR` path.** `probes-r4.log` line 3
     (`# inherited CARGO_TARGET_DIR: /tmp/cargo-s27-R77-r4-target` →
     `/tmp/cargo-s37-R77-emp-target`) and `probes-rerun-r4.log` line 4
     (`## run 1 — as written, CARGO_TARGET_DIR=…`) depend on the environment. So does the
     `Running tests/settings.rs (/tmp/cargo-s27-R77-r4b-target/debug/deps/…)` line at
     `probes-rerun-r4.log:72`. No rule item covers them.
  3. **The order of cargo test result lines.** Cargo runs tests in parallel, so their
     result lines can appear in a different order. `test unprefixed_and_empty_are_ignored ... ok`
     moved from line 76 to line 77 of `probes-rerun-r4.log`. The committed order was
     `unprefixed…`, `malformed…`; the fresh order is `malformed…`, `unprefixed…`.
- **Why this is a finding:** revision 3 was rejected for this class of defect (claude
  audit finding 3), and revision 4 restates the rule as exhaustive.
- **Repair:** amend rule item 2 in three ways:
  1. Name `probes-rerun-r4.log` alongside `probes.log`.
  2. Add the inherited `CARGO_TARGET_DIR` path, which appears in the `# inherited` header,
     the `## run 1` header, and cargo's `Running …` line.
  3. Add the order of cargo test result lines under parallel execution.

  No script or figure needs to change.

## Observations (not findings)

- **O1: R74 re-pin due** (controller note b).
  - **Current state:** R74 revision 2 is the live working-tree file. It is untracked, and
    its H1 is `# 2026-09-27 — R74 — rate-limiting-middleware (bundle, Deep) — decision (revision 2)`,
    with sha256 `68e19cf3…`. This state tripped the pin in `r4-checks.sh` by design, which
    accounts for the 7 failures above.
  - **Content check:** the content R77 relies on is unchanged. There are still three
    members, and they are now at R74:511–513. `OVERRIDE (OV-17)` is declared at :323.
    "Three suffice **because** `OVERRIDE (OV-17)` ships one dimension" is at :515.
    "Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family" is at :560.
  - **Stale anchors:** the decision's citation `DECISION.md:410-414` and `:452` (at
    `DECISION.md` line 769 of R77) is stale in line numbers only. It is covered by the
    disclosure at R77 lines 1570–1572 that R74 line numbers may move.
  - **For the judgment seat, not judged here:** R74 revision 2, line 25, hands R77 a
    "never-`None` settings invariant".
- **O2: R80 revision 4 is in the working tree, and a re-pin is due.**
  - **Current state:** the live file's H1 is `… decision (revision 4)`, and it is modified
    and uncommitted. The decision's reads of R80 resolve through
    `git show 53b13f45:…`, and those checks pass.
  - **Content check:** R80 revision 4 keeps the hand-off unchanged in substance.
    "**hands R77 a requirement rather than citing a fact**" moved from :318 to :367. The
    heading `**R77 (\`web-env-settings\`) — the readiness-propagation pause.**` and "if R77
    declines it, the pause needs an owner" moved from :750–752 to :829–831. R77's
    re-verify trigger for R80 does not fire on this evidence.
- **O3: superseded predecessors were not rerun standalone.** Per the controller's
  instruction, `probes.sh`, `ov-allocation-r3.sh` and `fetch-snapshots.sh` were not rerun
  on their own. `probes.sh` is covered by `probes-rerun-r4.sh`, which gave 6/0/0 above.
  `ov-allocation-r3.sh` is covered by `ov-allocation-r4.sh`.

## Verdict

**Reject, with one finding (E1).** E1 concerns only the wording of the reproducibility
rule. It is a one-paragraph text repair with no change to scripts or figures. Every other
rerun, pin and figure reproduced as the decision states. The only exceptions are the
designed failure in `rest-conformance-r2.sh` and the R74 pin trip, which is recorded as
re-pin due.
