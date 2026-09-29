actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: f1007676a8deb58f32b2d8a47f50a424ba5562c357618b072ae2cf66e54155c6
verdict: approve
unresolved-findings: none

# R27 formatter-config-surface — empirical audit, revision 3

Seat: empirical auditor, a fresh Claude context (`claude-opus-5-5`), independent of the
synthesizer and the judgment auditor. Run 2026-09-27 (UTC ≈ 08:13Z). Scope: execution truth
and evidence support of `review/DECISION.md` revision 3 only. No `review/audit-*.md`, no
`review/Rxx-r*-snapshot.md` and no `research/topics/[NN]-*/raw/` file was read. No git
write, no `scripts/research_runner.py` command, no paid or submitting API.

## 1. Target identity

```
$ shasum -a 256 research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/DECISION.md
f1007676a8deb58f32b2d8a47f50a424ba5562c357618b072ae2cf66e54155c6
```

Matches the expected hash. H1 reads "decision (revision 3)".

## 2. Environment

macOS, Darwin 25.4.0 arm64. `CARGO_HOME=/tmp/cargo-s38-R27-emp` (private). ShellCheck from
`PATH`. Scratch output directory `/tmp/r27-r3-emp-claude/`. The scripts' own scratch trees
went under `$TMPDIR/r27s/`. `git status --porcelain` on `review/evidence/` was the same
before and after the reruns (the directory is untracked; no committed log was overwritten).

## 3. Reruns

Command, run from the repository root:

```bash
E=research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/evidence
O=/tmp/r27-r3-emp-claude
for c in r27-config-surface r27-workspace-scope r27-hook r27-channel-pin r27-figures r27-husky-defaults; do
  shellcheck "$E/$c.sh"; sc=$?; "$E/$c.sh" > "$O/$c.log" 2>&1; echo "$c shellcheck=$sc exit=$?"
done
# then, for the five paired logs: cmp "$E/$c.log" "$O/$c.log" || diff "$E/$c.log" "$O/$c.log"
# totals: grep -cE '^\s*(PASS|FAIL|SKIP)' "$O/$c.log"
```

| Script | shellcheck | exit | PASS | FAIL | SKIP | Summary line | `cmp` against committed log |
|---|---|---|---|---|---|---|---|
| `r27-config-surface.sh` | 0 | 0 | 65 | 0 | 0 | `== summary: 65 checks, 65 pass, 0 fail` | **identical** |
| `r27-workspace-scope.sh` | 0 | 0 | 14 | 0 | 0 | `== summary: 14 checks, 14 pass, 0 fail` | differs, timing only (below) |
| `r27-hook.sh` | 0 | 0 | 13 | 0 | 0 | `== summary: 13 checks, 13 pass, 0 fail` | **identical** |
| `r27-channel-pin.sh` | 0 | 0 | 9 | 0 | 0 | `== summary: 9 checks, 9 pass, 0 fail` | **identical** |
| `r27-figures.sh` | 0 | 0 | — | — | — | `== done (figures are observations, not assertions; no pass/fail count)` | differs, live data only (below) |
| `r27-husky-defaults.sh` (observation only, not byte-compared as instructed) | 0 | 0 | — | — | — | — | not compared |

**Total: 101 assertions, 101 pass, 0 fail, 0 skipped**, matching the claimed 101.

### 3.1 `r27-workspace-scope` difference

`cmp`: `differ: char 3373, line 52`. The only `diff` hunk is the C2.8 wall-clock block:

```
52,56c52,56
<     run 1 real=0.08s
<     run 2 real=0.07s
<     run 3 real=0.07s
<     just format-check real=0.54s
<   PASS format-check measured at 0.54s, under 5 s on this host
---
>     run 1 real=0.05s
>     run 2 real=0.05s
>     run 3 real=0.05s
>     just format-check real=0.25s
>   PASS format-check measured at 0.25s, under 5 s on this host
```

Wall-clock timing is non-deterministic; the assertion ("under 5 s") passes. This is the same
class of difference the decision discloses for its own r3 rerun (0.28 s against 0.54 s).
Not a finding.

### 3.2 `r27-figures` difference

`cmp`: `differ: char 26, line 1`. Every differing line is live data bound to the retrieval
stamp: line 1 stamp (`2026-09-27T01:15:13Z` → `2026-09-27T08:13:16Z`); rustfmt stars
`6974` → `6975`; issue `#7138` now "first qualifying comment after 1.09 days", so F4 moves
from `answered=1 unanswered=9 median_days_answered=0.6` to `answered=2 unanswered=8
median_days_answered=0.845`; star counts and `pushed_at` of clap, serde and
rust-lang/crates.io; crates.io download counters for rustfmt-nightly, genemichaels and
prettyplease. `newest=1.4.20 at 2020-09-06T02:12:50.817623Z` for rustfmt-nightly is
unchanged. The decision's revision-3 paragraph already discloses the stars and #7138
drift and quotes F2/F4 "as of `evidence/r27-figures.log:1`", which is accurate against the
committed log. Not a finding.

### 3.3 `r27-husky-defaults` (F11), observation only

Exit 0, `NO DATA` nowhere. Observed (this run, stamp `2026-09-27T08:13:35Z`):

```
   28: default = ["prepush-hook", "run-cargo-test", "run-for-all"]
   35: run-cargo-fmt = []
   132:         if cfg!(feature = "run-cargo-test") {
   133:             s += cmd!("cargo test");
   141:         if cfg!(feature = "run-cargo-fmt") {
   142:             s += cmd!("cargo fmt", "--check");
   301:     if cfg!(feature = "prepush-hook") {
```

For information only: apart from line 1 (the retrieval stamp), the fresh output is identical
to the committed `r27-husky-defaults.log` (`diff <(tail -n +2 …) <(tail -n +2 …)` empty).
The decision's citations `evidence/r27-husky-defaults.log:5`, `:20-21`, `:29-30` and `:40`
resolve in the committed log to exactly the `default = …` line, `build.rs:132-133`,
`build.rs:141-142` and `build.rs:301`. The F11 row of `## Empirical check` and the
hook-mode paragraph (cargo-husky's default is a pre-push `cargo test`; `cargo fmt --check`
only under opt-in `run-cargo-fmt`) are supported.

## 4. Load-bearing figures re-derived at source

| Claim in DECISION.md | Source checked | Result |
|---|---|---|
| `rustfmt.toml` sha256 `a714037d…bea8`, `r27-config-surface.log:9-17` | extracted the first TOML fence from DECISION.md and hashed it; read log lines 9-17 | fence hashes to `a714037d3cb8919614f9b8619ff9a940ac858e5da22b25298abb7f68c310bea8`; log line 16 prints the same; lines 9-15 are the five keys byte for byte |
| C4.6: 806/811/819 lints, 410/408/414 warn-by-default, six new incl. `manual-take`, `manual-pop-if` | `r27-channel-pin.log:31-35` (reproduced byte-identical in this rerun) | matches |
| F1: `1.98.1` published 2026-09-03T13:14:07Z | `r27-figures.log:4`, fresh rerun | matches in both |
| F5: uv and zed `1.98.1` | `r27-figures.log:29`, `:31` | matches |
| R11 citations `:93`, `:259`, `:268`, `:286`, `:383` | `research/topics/11-ci-workflow-job-structure/DECISION.md` | each line says what the decision attributes to it (hygiene always runs; single-runner by design; `-D warnings` on clippy; R27 non-compiling → step of `hygiene`; runner cost unmeasured) |
| R42 `:26` (profile/components, channel is R27's) and `:302-305` (8 of 9 pin exact) | `research/topics/42-dev-toolchain-provisioning/DECISION.md` | matches |
| `inputs/prompt.md:25` empty `- owns:`, `:26` consumes R11 and R42, `:14` F190 channel no longer from MSRV | run `inputs/prompt.md` | matches |
| cargo-husky "3,630,801 crates.io downloads" | `raw/opus.md:124` (the run's raw leg, within scope) | matches the Opus leg's figure; carried, not re-fetched (see note) |

## 5. Assessment

Every executed claim in `## Empirical check` reproduces: four assertion scripts, 101/101
pass, three logs byte-identical, and the two differences confined to wall-clock timing and
live public counters, both disclosed by the decision. The revision-3 change (F11) is
supported line for line by its evidence log. No claim in the decision rests on a value the
rerun contradicts.

Non-blocking note (not a finding): in the hook-mode paragraph the cargo-husky download
figure, 3,630,801, comes from the Opus leg (`raw/opus.md:124`), while that sentence's
citation points only at F11. The figure is correct against its source; the sentence could
add `raw/opus.md:124` for the number.
