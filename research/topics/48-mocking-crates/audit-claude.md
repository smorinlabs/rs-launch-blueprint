actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 95a06ce150d7cdde5c671470d872bebab23ed4696cc21c2dc39819a1be9fa5ef
verdict: approve
unresolved-findings: none

# R48 mocking-crates — empirical audit, revision 6

Seat: empirical auditor (Claude Opus family), fresh context, independent of the
synthesizer and of the judgment auditor. Audit date 2026-09-27. Scope: execution truth
and evidence support only.

## Identity

`shasum -a 256 research/runs/R48/2026-09-17T020714Z-f9e4f950ea82/review/DECISION.md`
printed `95a06ce150d7cdde5c671470d872bebab23ed4696cc21c2dc39819a1be9fa5ef`, matching the
expected revision-6 hash. It was verified before any other action.

## Script set

The `## Empirical check` table (DECISION.md lines 633–639) names five current scripts:
`r48-claims-check.sh`, `r48-r2-msrv-macos-spike.sh`, `r48-r2-citations-check.sh`,
`r48-r3-tree-msrv-relabel.sh` and `r48-r4-c14-narrow.sh`. That set matches the brief. The
`r48-*archive-rerun.log` files are carried history (lines 750–764). They were not rerun.
RUNBOOK §5 requires the empirical auditor to rerun the check. That requirement is met below.

## Reruns

Host: Darwin 26.4 arm64. `CARGO_HOME=/tmp/cargo-s43-R48-emp` (a private cargo home).
Each script ran from the run directory
`research/runs/R48/2026-09-17T020714Z-f9e4f950ea82/`. Output went to `/tmp/r48-audit-r6/`.
Command form: `bash review/evidence/<script>.sh > /tmp/r48-audit-r6/<script>.log`.
stderr went to a separate file, and every stderr file was 0 lines long.

| # | Script | Exit | PASS | FAIL | SKIP | RESULT line | Stable-line diff vs committed log |
|---|---|---|---|---|---|---|---|
| 1 | `r48-claims-check.sh` | 0 | 20 | 0 | 0 | `RESULT: all checks passed (0 FAIL)` | empty |
| 2 | `r48-r2-msrv-macos-spike.sh` | 0 | 6 | 0 | 0 | `RESULT: all checks passed (0 FAIL)` | empty |
| 3 | `r48-r2-citations-check.sh` | 0 | 5 | 0 | 0 | `RESULT: all checks passed (0 FAIL)` | empty |
| 4 | `r48-r3-tree-msrv-relabel.sh` | 0 | 4 | 0 | 0 | `RESULT: all checks passed (0 FAIL)` | empty |
| 5 | `r48-r4-c14-narrow.sh` | 0 | 3 | 0 | 0 | `RESULT: all checks passed (0 FAIL)` | empty |
| | **Total** | | **38** | **0** | **0** | 5 × all passed | 5 × empty |

Comparison rule, taken from the decision (lines 728–731) and applied to all five scripts:

```
diff <(/usr/bin/grep -v '^# ' /tmp/r48-audit-r6/<script>.log) <(/usr/bin/grep -v '^# ' review/evidence/<script>.log)
```

Every diff was empty, so no stable `PASS`/`FAIL`/`SKIP`/`RESULT` line drifted.

C18 printed `PASS` rather than `SKIP`, because this machine carries the
`~/c/py-launch-blueprint` clone. Observed line:
`PASS C18: py at pin b08bccfb: 1 pyproject.toml line pairing 'responses>=0.25' with 'HTTP mock for the port-contract suite' and 1 contract-suite docstring line naming 'the in-memory fake and the real HTTP adapter' …`.
This is the behaviour the decision predicts for a machine with the clone (lines 749–751).

After the reruns, `git status --porcelain` showed no modification to any committed file
under `review/evidence/`. `git diff --stat HEAD` over that directory was empty. The reruns
therefore wrote nothing into evidence.

## Independent re-derivation at source (2026-09-27, bypassing the scripts)

| Figure in the decision | Query | Observed | Agrees |
|---|---|---|---|
| Newest non-yanked version / `rust-version`: `mockall` 0.15.0 / 1.77.0, `httpmock` 0.8.3 / 1.88.0, `wiremock` 0.6.5 / none, `mockito` 1.7.2 / 1.70 (C01–C04) | `crates.io/api/v1/crates/<name>/versions`, first non-yanked entry | `0.15.0 rv=1.77.0`, `0.8.3 rv=1.88.0`, `0.6.5 rv=null`, `1.7.2 rv=1.70` | yes |
| `httpmock` 0.8.3 `default = ["cookies"]` (C05) | `crates.io/api/v1/crates/httpmock/0.8.3` | `["cookies"]` | yes |
| Required normal dependencies: `wiremock` 15, `mockito` 16, `httpmock` 25 (C19); `mockall` six named crates (C08) | `…/<name>/<version>/dependencies`, `kind=="normal"` and not optional | 15, 16, 25; `mockall` = `cfg-if downcast fragile mockall_derive predicates predicates-tree` | yes |
| RustSec: 404 for the four candidates, 200 for the `lock_api` control (C07) | `rustsec.org/packages/<name>.html` status | `mockall=404 httpmock=404 wiremock=404 mockito=404 lock_api=200` | yes |
| `wiremock-rs` `archived: false`, `pushed_at` 2025-08-24 (C13) | `gh api repos/LukeMathWalker/wiremock-rs` | `archived=false pushed_at=2025-08-24T12:26:20Z` | yes |
| Issue #173 title, opened 2025-08-27, closed (C20) | `gh api repos/LukeMathWalker/wiremock-rs/issues/173` | ``Error: `let` expressions in this position are unstable`` / `2025-08-27T12:27:34Z` / `closed` | yes |
| `c2pa-rs` `sdk/Cargo.toml` co-declares `mockall = "0.15.0"` and `httpmock = "0.8.3"` (C14, H01) | raw `main/sdk/Cargo.toml` | line 267 `mockall = "0.15.0"`, line 281 `httpmock = "0.8.3"` | yes |
| `c2pa-rs` commits no lockfile; tree not truncated (H02) | `gh api 'repos/contentauth/c2pa-rs/git/trees/main?recursive=1'` | `truncated=false lockfiles=0` | yes |

The compile claims D01–D05 and G01–G02 were re-established by rerunning script 2 and
script 4 on this host. Script 2 ran the probe at `cargo 1.96.0` and at `cargo 1.98.0`, and
all of its stable lines reproduced.

## Evidence-support observations (not findings)

- The prose claim that scripts 1–4 and their logs are unchanged since revision 3 (lines
  641–643) is consistent with git. Each of those four scripts and logs was last touched on
  2026-09-16 (commits `2d79de86`, `695f6731` and `894f9656`), and none differs from `HEAD`.
- `r48-r4-c14-narrow.sh` (sha256 `d3497572…`) and its log (sha256 `6273b9c9…`) are present
  in the working tree but are untracked in git. So is `r48-r4-archive-rerun.log`. They
  executed and reproduced here. Committing them is a publication-staging matter for the
  controller (RUNBOOK §5). It is not an execution-truth defect, because revision 6 does not
  claim that they are committed to git.
- The r6 change is prose-only in `## Engines`: the adjudication of the `mockall`
  responsiveness figure (lines 891–921). It introduces no new executable claim. Its cited
  figures (codex 4.98 days / opus 1.18 days) come from the engines' raw reports, which this
  seat is forbidden to read. That paragraph is therefore judgment-auditor territory. The
  stable facts it leans on (`mockall` not archived, 0.15.0 current) agree with C01 and with
  the re-derivation above.

## Verdict

approve. All five current scripts rerun green: 38 PASS, 0 FAIL, 0 SKIP, and 5 × exit 0.
Every stable line matches its committed log byte-for-byte. Every load-bearing figure
re-derived at source agrees with the decision.
