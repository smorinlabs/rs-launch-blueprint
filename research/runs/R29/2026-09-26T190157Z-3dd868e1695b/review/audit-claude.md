actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: fb003aecddf145c2fd8ad3bca2c6f3aa2367201f8ed563d11b82c2884b6ec5c2
verdict: approve
unresolved-findings: none

# R29 — non-code-file-formatting — empirical audit of DECISION.md revision 1

**Scope.** Execution truth and evidence support of `review/DECISION.md` revision 1 for run `2026-09-26T190157Z-3dd868e1695b`. This audit covers `## Empirical check`, `## Engines` and RUNBOOK §5. The decision hash was recomputed with `shasum -a 256` before any other step. It equals the expected `fb003aec…6c5c2`.

This context is fresh and independent of the synthesizer and of the judgment auditor. It read no `review/audit-*.md`, no `raw/` report and no `review/Rxx-r*-snapshot.md`. It made no git write and ran no `scripts/research_runner.py` command.

**Host.** macOS, `Darwin 25.4.0 arm64`. Private `CARGO_HOME=/tmp/cargo-s22-R29-emp`. Working directory: the repository root, `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.

## Reruns

Every fresh log went to `/tmp/r29-audit-claude/out/`. `E` stands for `research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence`, and `O` stands for `/tmp/r29-audit-claude/out`. Each fresh log was compared with its committed pair using `cmp`. A mismatch was followed by `diff`.

After the reruns, every mtime under `evidence/` still falls between 19:44 and 20:02 local on 2026-09-26. `find review -newer <first rerun log>` lists only the new directory entry and another seat's audit file, which this audit did not open. The reruns wrote nothing into `evidence/`.

| Script | Command as run | Exit | Totals | `cmp` against the committed log |
|---|---|---|---|---|
| `r29-decision-checks.sh` | `bash $E/r29-decision-checks.sh >$O/r29-decision-checks.log 2>&1` | 0 | PASS=11 FAIL=0 | **identical** |
| `r29-sources.sh` | `bash $E/r29-sources.sh >$O/r29-sources.log 2>&1` | 0 | PASS=25 FAIL=0 | **identical** |
| `r29-snapshots.sh` | run on a copy: `cp -R $E /tmp/r29-audit-claude/evcopy; bash /tmp/r29-audit-claude/evcopy/r29-snapshots.sh >$O/r29-snapshots.log 2>&1`. The script writes into `$here/snapshots`, so running it in place would overwrite evidence. | 0 | 51 captures, `r29-snapshots: OK` | **identical** (`snapshots: 51 entries` / `r29-snapshots: OK`). Eleven data files and `PROVENANCE.tsv` differ from the committed ones in rolling fields; see "Re-derivations" below. |
| `r29-provision.sh` | `R29_WORK=/tmp/r29-audit-claude/plugins bash $E/r29-provision.sh >$O/r29-provision.log 2>&1` | 0 | no assertions; `r29-provision: OK` | **differs, as expected.** My `CARGO_HOME` held no `dprint`, so the script compiled it (`Finished … in 2m 30s`, `Installed package dprint v0.57.4`). The committed log is a warm rerun. The version lines match: `dprint 0.57.4`, `cargo 1.93.0 (083ac5135 2025-12-15)`, `rustc 1.93.0 (254b59607 2026-01-19)`. The plugin digests differ (see observation O2). |
| `r29-dprint-stack.sh` | `PLUGIN_OUT=/tmp/r29-audit-claude/plugins/out bash $E/r29-dprint-stack.sh >$O/r29-dprint-stack.log 2>&1` | 0 | PASS=34 FAIL=0 | **differs at lines 8–9 only.** These are D0b's size line and its worst-case ratio (see observation O2). Every other line is byte-identical. |
| `r29-lefthook.sh` | `PLUGIN_OUT=… bash $E/r29-lefthook.sh >$O/r29-lefthook.log 2>&1` | 0 | PASS=6 FAIL=0 | **identical** |
| `r29-taplo-compare.sh` | `PLUGIN_OUT=… bash $E/r29-taplo-compare.sh >$O/r29-taplo-compare.log 2>&1` | 0 | PASS=12 FAIL=0 | **identical** |

Here is the `diff` for `r29-dprint-stack.log`, with the committed log first and the fresh log second:

```
8,9c8,9
<     built/published bytes: json 643865/636736; markdown 743253/761907; toml 514607/510627; pretty_yaml 594430/576981
< PASS D0b — every built module is within 3.1% of the published plugin.wasm size (worst 0.0302)
---
>     built/published bytes: json 643998/636736; markdown 743361/761907; toml 514729/510627; pretty_yaml 594505/576981
> PASS D0b — every built module is within 3.1% of the published plugin.wasm size (worst 0.0304)
```

**Aggregate.** Seven of seven scripts exit 0, with 88 PASS and 0 FAIL across the asserting scripts (11 + 25 + 34 + 6 + 12). No check was skipped. `shellcheck` 0.11.0 on all seven scripts exits 0. That agrees with the committed `shellcheck.log`.

**Supplementary run.** `r29-sources.sh` was also run against the freshly captured snapshots in `/tmp/r29-audit-claude/evcopy`. Result: PASS=25 FAIL=0, including S6, S8 and S9. The decision's warning that a recapture could fail S8 or S9 did not materialise on 2026-09-26/27.

## Re-derivations at source

- **Pins.** I re-read the four `plugin.wasm` digests from freshly captured GitHub release JSON. Each digest equals the `@sha256` in `fixtures/tree/dprint.json`: toml `69cb40cb…976945d`, json `07316f98…28bc48f1`, markdown `cf7e6567…81217764`, pretty_yaml `40a2fdda…eba01ae`. The published sizes are 510,627, 636,736, 761,907 and 576,981 bytes, as quoted.
- **The configuration block.** The fenced `dprint.json` in `## Decision` is byte-identical to `evidence/fixtures/tree/dprint.json`, which is the file that was executed.
- **Figures table.** Fresh crates.io JSON reproduces every quoted download count, all-time count and newest version to the digit. Examples: `dprint` 11,573 / 239,963 / 0.57.4; `dprint-plugin-toml` 2,223 / 19,633 / 0.8.0; `taplo-cli` 194,730 / 2,224,667 / 0.10.0; `pretty_yaml` 241,855 / 840,275 / 0.6.0. The quoted ratio "about 88 times" checks out: 194,730 / 2,223 = 87.6.
- **taplo#715 quotes (Disagreement A, ground 1).** The comments snapshot holds each quote at the stated date and role:
  - "Whatever plans I had": `tamasfe`, `OWNER`, 2025-11-10.
  - "destined to eventually die": `OWNER`, 2025-11-11.
  - "I don't want to be involved anymore": `OWNER`, 2025-11-13.
  - "just keep merging": `panekj`, `COLLABORATOR`, 2026-03-22.
- **Style Guide citations.** In `snapshots/style-guide-cargo.md`, line 5 is "Use the same line width and indentation as Rust code." Lines 11–15 carry the `[package]` rule: `name`, then `version`, then the remaining keys in sorted order, with `description` last. D8's observed order `name,version,edition,include,license,rust-version,description` complies with that rule.
- **Prerequisite citations.**
  - R42 `DECISION.md:91-93` records `taplo-cli@0.10.0` falling through to a source build.
  - R42 `DECISION.md:12-17` holds the 2026-09-12 licence ruling.
  - R11 `DECISION.md:188` names R29's slot as a step of `hygiene`.
- **Compile-fallback cost.** The decision's item 2 under "What no check establishes" estimates the fallback at "about two minutes". My fresh `cargo install dprint --version 0.57.4 --locked` took 2m 30s on this host. That independently confirms the scale of the estimate.
- **Committed install log.** `build/cargo-install-dprint.log` spans 02:37:39Z–02:39:46Z with `EXIT=0`, as the decision states.

## Observations (non-blocking)

None of the observations below changes a check's truth or the recommendation. None of them blocks acceptance.

- **O1 — the log-capture sentence is inaccurate.** The claim at `DECISION.md:153` reads: "Each writes `<name>.log` beside itself and exits non-zero on any `FAIL`." In fact, no script contains `tee` or a `.log` redirect. The committed logs are captured stdout and stderr, and every observed line reproduces. **Suggested repair for a later revision:** "Each prints to stdout and exits non-zero on any `FAIL`; the committed `<name>.log` is `bash … >evidence/<name>.log 2>&1`."
- **O2 — D0b depends on the environment, and the built-module digests are not reproducible.**
  - D0b's worst size ratio was 0.0302 for the synthesizer and 0.0304 for me, against a ceiling of 0.031. The binding module is pretty_yaml: 594,505 built bytes against 576,981 published.
  - I rebuilt with a work path of the same length (`R29_WORK=/tmp/r29-auditcl`). The digests stayed at my first build's values (`eb4567e5…`, `d9142989…`, `4959228a…`, `a52dc91f…`).
  - I rebuilt again with a `CARGO_HOME` whose path has the same length as the synthesizer's (`/tmp/cargo-s99-R29`). The sizes then landed within 1–4 bytes of the synthesizer's: 643,869, 743,249, 514,604 and 594,431.
  - The drift is therefore the embedded registry path, not the source. The digests in the committed `r29-provision.log` belong to the synthesizer's build and are not reproducible elsewhere. This is consistent with the decision, which already says they are not the pins.
  - **Suggested repair:** state the path dependence in the "One deviation" paragraph, or widen D0b's tolerance, so that a rerun under a longer `CARGO_HOME` does not fail spuriously.
- **O3 — controller note (a), the engine swap.** `C3c` and `C5` pass today against the live prompt's current uncommitted edit (`engines: muse, opus`) and the run's pre-Q17.A snapshot (`codex, opus`). If the controller re-freezes inputs under Q17.A, those two checks' expected values will need updating. **Repair:** the controller re-freezes inputs and cites Q17.A. This is not a synthesis defect. The decision's header already flags the staffing facts and the synthesizer-equals-Opus-leg model overlap for the controller.
- **O4 — declared gaps are honestly bounded.** Three things remain unverified, and the decision's "What no check establishes" list declares each one:
  - that `plugins.dprint.dev` serves bytes matching the four pins;
  - that `cargo binstall` fetches a prebuilt on each runner;
  - any behaviour on `ubuntu-latest`.

  D18 shows why the first gap matters. D18d shows that a warm cache does not re-verify a pin. The decision correctly routes all three gaps to P03 and to `re-verify:`.
- **O5 — controller notes (b) and (c) do not apply to R29.** R29 raises no `CONFLICT:`, and C2b confirms that. It is not conditional on R58, and it does not touch tower-http.
