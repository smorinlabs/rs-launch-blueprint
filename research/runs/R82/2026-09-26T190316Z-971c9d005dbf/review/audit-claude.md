actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 4853cae14d8a7affec4a3815386234f71ce4bd724f90accf13de99783a505d43
verdict: approve
unresolved-findings: none

# R82 docs-correctness-gate — empirical audit of DECISION.md revision 1

**Seat.** Empirical auditor, a fresh Claude Opus 5.5 context (`claude-opus-5-5`). This context
is independent of the synthesizer and of the judgment auditor. It read the decision,
`research/RUNBOOK.md` §5, the run's `inputs/`, `manifest.json`, `raw/muse.md` and `raw/opus.md` (at
the cited lines only), the three evidence scripts and their logs, the topic prompt, R11's
decision at the cited lines, and the `engine_overrides` entry in `research/EXECUTION.json`. It
read no `review/audit-*.md` of any seat or revision and no `research/topics/*/raw/`. It performed
no git writes, ran no runner commands and used no paid API.

**Hash first.** `shasum -a 256 review/DECISION.md` →
`4853cae14d8a7affec4a3815386234f71ce4bd724f90accf13de99783a505d43`, which equals the expected
hash. The committed `r82-decision-integrity.log` line 2 records the same hash
(`# DECISION sha256 4853cae1…3d43, 610 lines`), so the committed integrity check ran against
this exact revision.

**Scope of the verdict.** This audit judges execution truth and evidence support only.

## Reruns

**Environment.** Host: macOS `Darwin 25.4.0 arm64`. Toolchains as read by the script:
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)` / `rustdoc 1.98.1 (48a229cea 2026-09-01)`, and
`cargo 1.96.0 (30a34c682 2026-05-25)` / `rustdoc 1.96.0 (ac68faa20 2026-05-25)` via
`rustup run 1.96.0`. Private `CARGO_HOME=/tmp/cargo-s22-R82-emp`. `gh version 2.101.0`. Working
directory: the run directory `research/runs/R82/2026-09-26T190316Z-971c9d005dbf`. Fresh logs
went to `/tmp/r82-emp/`; nothing under `review/evidence/` was written. Reruns were made on
2026-09-27 between 05:54 and 05:55 UTC.

| Script | Command | Exit | `cmp` against committed log | Totals |
|---|---|---|---|---|
| `r82-decision-integrity.sh` | `bash review/evidence/r82-decision-integrity.sh > /tmp/r82-emp/r82-decision-integrity.log 2>&1` | 0 | differs at line 1 only | `RESULT: PASS (0 failures, 64 citations)`; 116 `ok` lines, 0 `FAIL`, 0 skipped |
| `r82-rustdoc-gate.sh` | `env -u CARGO_TARGET_DIR bash review/evidence/r82-rustdoc-gate.sh > /tmp/r82-emp/r82-rustdoc-gate.log 2>&1` | 0 | differs at line 1 only | 54 case lines (27 per toolchain, G0–G10); every exit code and key-output line matches the decision's table; 0 unexpected, 0 skipped |
| `r82-upstream-reads.sh` | `bash review/evidence/r82-upstream-reads.sh > /tmp/r82-emp/r82-upstream-reads.log 2>&1` | 0 | differs at line 1 only | 13 `## U` sections (U1–U10 with U1b, U6b, U8b); every value matches; 0 failures, 0 skipped |
| `lychee` (any form) | not run, by the controller's direction | — | — | skipped: 1 (see below) |

**The only differing line in each pair is the run timestamp**, which each script prints on
line 1:

```text
r82-decision-integrity.log
< # r82-decision-integrity — run 2026-09-27T05:54:38Z
> # r82-decision-integrity — run 2026-09-27T03:16:23Z
r82-rustdoc-gate.log
< # r82-rustdoc-gate — run 2026-09-27T05:54:38Z
> # r82-rustdoc-gate — run 2026-09-27T03:05:10Z
r82-upstream-reads.log
< # r82-upstream-reads — run 2026-09-27T05:54:42Z
> # r82-upstream-reads — run 2026-09-27T03:09:04Z
```

(`<` is the fresh log in `/tmp/r82-emp/`; `>` is the committed log.)

The upstream-reads script reads live GitHub, crates.io and rustsec.org data. It reproduced
byte-for-byte about 2 h 45 min after the synthesizer's run, including the U8 per-issue response
times.

**Integrity check I4 reads the committed logs, not the fresh ones.** The script hard-codes
`review/evidence/r82-rustdoc-gate.log` and `r82-upstream-reads.log`. The fresh logs equal the
committed logs apart from line 1, so the I4 result also holds for the fresh logs.

**`CARGO_TARGET_DIR`.** This auditor's environment sets
`CARGO_TARGET_DIR=/tmp/cargo-s22-R82-emp-target`. `r82-rustdoc-gate.sh` guards `CARGO_HOME` but
does not unset `CARGO_TARGET_DIR`. A shared target directory across the 54 fixture copies could
change the `Fresh`/`Documenting` counts in `G10`. The rerun therefore unset it with
`env -u CARGO_TARGET_DIR`, which gives every fixture its own `target/` as the script assumes. The
result matched the committed log exactly. This is an observation about script robustness, not a
finding.

## Load-bearing figures re-derived at source

| Claim in the decision | Check | Result |
|---|---|---|
| `G0`: 11 `rustdoc::` lints, 4 allow, 7 warn, on both toolchains | fresh log | `G0   rustdoc:: lints: 11 (allow: 4, warn: 7)` twice; matches |
| `G1c`, `G2d`, `G3b`, `G3c`, `G5b`, `G6b`, `G8a` exit 101; `G2a`–`G2c`, `G3a`, `G5a`, `G6a`, `G7a`, `G7b` exit 0; `G4a` 101, `G4b`/`G4c` 0; `G6c`/`G6d` 101/101 | fresh log, both toolchains | every exit code matches the decision's table |
| `G6c`/`G6d` key output | fresh log | ``error: public documentation for `exposed` links to private item `hidden` `` |
| `G7a`/`G7b`: unused import only warns | fresh log | ``warning: unused import: `std::collections::HashMap` ``, exit 0 |
| `G9c`: one `rustdoc --test` argv line carries `-D warnings` | fresh log | `rustdoc --test argv lines carrying -D warnings: 1` on both toolchains |
| `G10`: second run `Fresh=2`, `Documenting=0` | fresh log | matches on both toolchains |
| `U1`: tag `v2.9.0` → commit `e7477775783ea5526144ba13e8db5eec57747ce8` | fresh log | `object.type=commit object.sha=e7477775783ea5526144ba13e8db5eec57747ce8` |
| `U2`: `lycheeVersion` default `v0.24.2`; `token` default `${{ github.token }}`; `curl -sfLO` at line 89, `tar -xvzf` at line 92; no checksum line | fresh log | matches; the checksum grep returned only the two installer lines |
| `U3`/`U4`: offline mode restricts schemes to `file`; excluded schemes are filtered | fresh log | `client.rs` lines 22–27 and `filter/mod.rs` lines 172–177 and 221–222 as quoted |
| README flag lines 331, 394, 397, 613, 623, 683, 694, 719; exit-code line 752; config default at line 392; `.gitignore` text at lines 644–645 | fresh log | all present at those line numbers |
| `U8`: lychee 7/10, median 0.09 d; mlc 2/10, 4.67 d, under both counting methods; hyperlink 8/10 at 0.15 d (maintainer method) and 7/10 at 0.29 d (non-opener method); cargo-deadlinks 0/10 maintainer, 4 non-maintainer replies; mdbook-linkcheck 0/10 | fresh log | all match; mlc's 8 unanswered issues reach back to #99, opened 2025-02-04, as the decision states |
| `U8b`: mdbook-linkcheck #92 and #96 open; repository last pushed 2024-08-15 | fresh log | matches |
| `U9`: rustsec 404 for the six tools; 200 for the `time` control | fresh log | matches |
| `U10` practice lines (lychee `links.yml:3-7` and `ci.yml:19,68-70`, zebra `advisory.yml:4-6,38,44`, ripgrep `ci.yml:245-246`, axum `CI.yml:42-49`) | fresh log | matches |
| Engines table: `raw/muse.md` 819 lines, sha256 `d52ed105…49cc`; `raw/opus.md` 851 lines, sha256 `fcf8fdfd…01a9` | `wc -l`, `shasum -a 256` | matches |
| Both raws pass the shape check | `scripts/check-answer-shape.sh raw/{muse,opus}.md bundle` | `OK: validation passed` for each |
| Inputs gap: the topic prompt differs from `inputs/prompt.md` at exactly lines 25 and 71; `inputs/prompt.md` sha256 `3757ab1f…4932`; `engine_overrides` lists R82 as `muse, opus` | `diff`, `shasum`, `EXECUTION.json` | exactly two changed lines, 25 and 71, with the texts the decision quotes; hash matches; `{"R82": ["muse", "opus"]}` |
| Gap 6: the `operations/` directory is empty; `manifest.json` has `operations: {}` | `ls -A operations`, `manifest.json` | empty directory; `"operations": {}` |
| Prerequisite decisions R11 and R69 are current | integrity check I2 (fresh rerun) | both hashes match `inputs/prerequisites.json` |
| R11 slot row (`DECISION.md:294`) places the link check in `hygiene`, the rustdoc part in `check`'s doc build, and scheduled URL checks in R34's lane | direct read of line 294 | matches the four statements the decision relies on |

**The claim that lychee was never executed is verified.**

- `command -v lychee` on this host returns nothing.
- No evidence script invokes a `lychee` binary. Every `lychee` mention in the scripts is a
  `gh api` path, a repository name or an echo string.
- `raw/muse.md:432-433` reads "Planned (NOT executed — lychee binary unavailable in this offline
  leg …".
- `raw/opus.md:35-40` reads "`lychee` was not installed or run."
- The decision labels AC1, AC3 and AC4 as **proposed** and lists every `lychee` command under
  "Not executed".

The decision's lychee claims therefore rest on source and README reads at the release tag.
Those reads reproduce (U3, U4, U6, U6b), and the decision does not claim more than they show.

## Observations (not findings)

1. **Unmet execution clause for F349 and F350.** RUNBOOK §5 says "Configuration, command and
   version-pin recommendations must execute". The two `lychee` invocations have not executed.
   The decision states this itself as gap 1, and names RUNBOOK §3 supplementary research as the
   remedy. This observation does not change the empirical verdict, because the decision reports
   execution truthfully. Whether that supplementary execution is required before acceptance is
   the controller's decision.
2. **Controller note (a), engine swap.** `manifest.json` records `required_engines: codex, opus`,
   and `inputs/prompt.md` says `- engines: codex, opus`. The legs that ran were Muse and Opus,
   under Q17.A. No integrity check failed because of this, and the decision reports the mismatch
   in its "Inputs gap" paragraph. Repair: the controller re-freezes the inputs and cites Q17.A.
3. **Gap 6, missing operation records.** No operation record exists for either leg. The Muse
   leg's resolved model is therefore unrecorded, and the Opus leg's model rests on self-report.
   The decision states this accurately. Attaching the records is controller business.
4. **Controller note (b), conflicts and conditionals.** R82 raises no `CONFLICT:`. It consumes
   only R11 and R69, which are not parties to the conflicts named in the dispatch (R32 versus
   R11, R71 versus R69). R69 revision 10 is pending publication. The decision treats that as a
   re-verify trigger, and fixtures A and B cover both layouts; `G2`–`G5` reproduce on both.
5. **Controller note (c), the tower-http coupling.** It does not apply: R82 selects no
   `tower-http` version and no web dependency.
6. **Script robustness.** `r82-rustdoc-gate.sh` should `unset CARGO_TARGET_DIR` alongside
   `RUSTDOCFLAGS` and `RUSTFLAGS`, so that a future auditor's environment cannot share one
   target directory across fixtures. The rerun here controlled for it, and the output matched.

## Verdict

**approve.** All three evidence scripts rerun with exit 0. Each fresh log is byte-identical to
its committed log except for the timestamp on line 1. Every executed figure the decision cites
reproduces, as do the load-bearing upstream figures. Every non-executed claim is labelled as
not executed. No unresolved finding remains.
