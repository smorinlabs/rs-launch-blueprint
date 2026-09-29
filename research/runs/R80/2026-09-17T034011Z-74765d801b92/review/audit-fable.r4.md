actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8
verdict: approve
unresolved-findings: none

# R80 — health-probe-endpoints — judgment audit of revision 4

Target: `research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md`,
revision 4. `shasum -a 256` gave
`f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8`, which equals
the expected hash. This audit was performed on 2026-09-27 by a fresh context with
no prior involvement in the item. Scope: reasoning and fidelity only. Scripts
were not rerun. Every figure below was either read directly or recomputed as a
single spot-check.

Read: the decision (all 1,601 lines); `inputs/prompt.md`; `research/RUNBOOK.md`
sections 2, 4, 5 and 6; `raw/muse.md` (by anchor); `manifest.json` and
`operations/*.json`; and the prerequisite and sibling texts named below. No
`review/audit-*.md` file and no `review/R*-r*-snapshot.md` of R80 was read.
Other items' snapshots were hashed only to resolve their pins.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | Script and check totals agree: 28 + 13 + 9 + 42 + 7 + 14 = 113, which matches line 966. Counted in the file: `OVERRIDE (OV-05)` appears 11 times, `OVERRIDE (OV-04)` 0 times, and bare `OV-04` 11 times (lines 50–60, 721–726 and 1551–1558, with none in the revision-4 note). These counts match lines 1138–1143. The recommendation bullets, the members table, the migration table and the revision-4 "What did not change" list agree with each other. The `VERSION` bullet (line 139) defers the package choice, which matches the R22 hand-off at lines 525–536. |
| JF-2 prompt answered, constraints honoured | pass | The three HIGH questions are answered: the shared function's shape and placement (lines 402–456); the liveness fields and crates (lines 464–500, 538–549); and the principle and agreement level (table at lines 283–289). Both MEDIUM questions are answered: no extra crate is needed (line 191), and responses use structured `serde` types (line 551). The LOW question is answered by the census (`L8`). Fitness gates 2–6 are answered per candidate, and gate 1 carries the prescribed `inapplicable` wording. F308 is applied, not re-derived. Edition 2024 and the MSRV policy are honoured (probe `rust-version = "1.96"`). Performance is stated as unmeasured rather than inferred. Out-of-scope items (the R70 envelope, R75 F320, R51 `HEALTHCHECK`) are handed off, not designed. |
| JF-3 `## Engines` fidelity | pass | The engine set Muse + Opus matches the prompt (`- engines: muse, opus`, line 25), the manifest's migration event (`codex`→`muse`, 2026-09-21T23:06:21Z, Q5.A, `required_engines` `["muse","opus"]`), and `research/EXECUTION.json` `engine_overrides.R80` = `["muse","opus"]` (`empirical_auditor_overrides.R80` = `claude`). Every quote attributed to Muse was found verbatim in `raw/muse.md`: "No `CONFLICT:` lines — the recommendation fits all consumed values." (line 235); "`rustc --version` via `RUSTC_VERSION` is not built-in — it needs a build script" (line 11); "explicitly asks `/healthz` to re[port]" (line 59); "passes all six fitness gates" (line 63); `ok: bool` (line 33); `spawn_blocking` "only if a check blocks" (line 29); the figures 19003082/65076989, 9061345/53257922 and 324724704/1439926984; the open-issue counts 8/4/319; the reverse-dependency totals 124928/237/203; and the GitHub rate-limit gap (line 71). Muse has no latch and no `Cache-Control`, which I confirmed by 0 hits. All nine disagreements are adjudicated with evidence the decision holds (R49's no-`build.rs` clause, `T2`/`T3`/`T4`/`T5`, `O22`/`O27`, R02 revision 2, R05 revision 3, `P1`/`P2`). The eight corrections to Opus are specific and sourced. |
| JF-4 load-bearing claims trace | pass | Spot-checked at source. **Kubernetes:** "greater than or equal to 200 and less than 400" is in `snapshots/k8s-configure-probes.html`. **Apollo Router:** "hard to get k8s to parse payloads" is in `snapshots/apollo-healthcheck.rs`. **kubert:** `"alive\n"` is in `snapshots/kubert-admin.rs`. **py** at `b08bccfb`: `tests/web/test_app.py:248-262` is `test_readyz_failure_is_a_problem_with_diagnostics`, which asserts 503 through `monkeypatch.setattr(app_module, "run_diagnostics", …)`; `core/diagnostics.py` has `MIN_PYTHON = (3, 12)`, and only the `python` check can be `error` (the others are `ok` or `warn`); `web/app.py:153` is the `/healthz` decorator with the quoted docstring. **Ledger:** `COMMONALITY.md:332-333` holds F328 and F329 with owner R80. **REST standard** at blob `71bd813c`: lines 443, 1259 and 1752 carry R2.1, R7.1 and R11.7 as quoted. |
| JF-5 couplings hand over owned choices | pass | **R22/R02:** the `VERSION` package is handed over as options (a) and (b) with their consequences, and neither is chosen (lines 525–536). **R70:** three ways to carry the report are listed, and R70 owns the choice (lines 786–793). **R71:** only the R02-derived no-derive-in-core constraint is stated, with two options left to R71. **R77:** the pause is handed over as a requirement. **R75:** the obligation comes from the standard's R11.7, stated as an input. **R51:** no option is chosen. **R67:** `doctor`'s exit code is left unassigned. The decision raises no `- owns` line and no false `CONFLICT:`. |
| JF-6 assumes lines byte-identical | pass | A table parser compared each of the seven `- assumes` values with the live `docs/port/PARAMETERS.md` value cell. All seven match exactly: `rust-edition` (4 chars), `msrv-policy` (118), `target-os-matrix` (27), `license` (17), `build-tool-output-shape` (1,818), `http-transport-injection-seam` (763) and `web-extra-surface` (2,638). |
| JF-7 no conflict with accepted or published prerequisites | pass | Pins resolve now by sha256 against `docs/port/OWNER-ACCEPTANCES.md`. **R02** revision 2: `9e8f8e8c…` (row line 71) is the live `DECISION.md`. **R05** revision 3: `3ca4b81a…` (line 75) is `R05-r3-snapshot.md`; the live file is revision 5. **R03** revision 1: `610e3338…` (line 70). **R22** revision 1: `0e7ea78e…` (line 79) is `R22-r1-snapshot.md`, which carries `pub const VERSION` (line 13), the health reading of `rs_launch_blueprint::VERSION` (line 17), "one value, one symbol" (line 112) and the R02 multi-crate re-verify trigger (lines 387–388). **R69** revision 10: `d34ab6e8…` (line 60) is the live `DECISION.md`, whose `- owns web-extra-surface` is at line 1791 and whose file map reserves `crates/web/src/routes/ops.rs` "`/readyz` and its payload are R80's" (line 1607). **R55** revision 3 (`5d358c1f…`) and **R57** revision 2 (`44e94504…`) are published at their accepted bytes, with 0 hits for `run_diagnostics\|doctor\|readyz\|CheckStatus` in each. `owner-decisions.md:516` is W1-R22 and `:488` is W1-CODEX3. |
| JF-8 evidence exists and counts match | pass | All six scripts and their paired logs exist. Each log's totals line and its counted `^PASS`/`^FAIL`/`^SKIP` lines agree: offline 28/0/0; probe 13/0/0; live 9/0/0 in `check-live.log`, `r4-fetch` and `r4-snapshots`; r2 42/0/0; r3 7/0/0; r4 14/0/0; nested reruns 28, 42 and 7 PASS. The rerun diffs are 0 bytes where the decision says so. `check-probe.rerun.diff` holds 8 differing lines and `check-standard-r2.rerun.diff` holds 4, all of them `Finished` or `finished in` timings. `check-live.archive.assertions.diff` is 96 bytes. `check-probe.log` line 13 is `cargo network flags: '--locked'`, and its tree shows `hyper-util v0.1.20` and `smallvec v1.16.1`. Both lockfiles pin 0.1.20 and 1.16.1 and differ only in two local package versions. All 22 V13 digests recompute OK. `shellcheck-r4.log` is 0 bytes. |
| JF-9 decision shape | pass | The H2s are `## Decision`, `## Parameters`, `## Empirical check`, `## Engines` and `## Supersedes`, in RUNBOOK section 5 order. The sixth `^## ` line (line 679) is inside the conformance note's fence. There is exactly one `re-verify:` line, inside `## Decision`. `### Principles and implementation` is present. The single `OVERRIDE (OV-05)` carries `**Argument:**` and `**Options:**`. Prior revisions are recorded under `## Supersedes`. |
| JF-10 recommendation follows from the evidence | pass | Alternative C (latch + shared diagnostics) is supported on three grounds. First, the Kubernetes consequences (a)–(c). Second, the drain state that only a latch can report (`T4`, `T5`). Third, the unreachable diagnostic 503 (`O22`, `O27`). Zero added crates follows from the `std`/Cargo mechanisms (`A`, `B`, `T1`) together with the R49 clause that excludes `built`, `vergen` and `shadow-rs`, and from gate 2 excluding `shadow-rs` and `git-version`. The limits are stated rather than hidden: the latch does nothing unless the pause is nonzero, AC9 and AC11 are left to P03, and redaction is not checked here. |

## Observations (non-blocking, not findings)

1. **Muse leg unregistered (expected; controller note (a)).** The on-disk state is
   as described. `operations/muse.json` is `submitting` (request
   `9d63b9c66e354800a931ac35871f647d`). `raw/muse.md` is untracked and hashes to
   `395c1426…`, which is the digest the decision names. The manifest's
   `operations` map carries only `opus`. The decision's re-verify trigger covers a
   collected digest that differs from this one.
2. **R77 has moved since the evidence was taken (a sibling moving mid-flight).**
   R77 revision 4 (2026-09-27, not owner-accepted) now accepts R80's pause
   requirement as `RSLBP_WEB_READINESS_PAUSE_SECONDS`, with a default of **0**.
   R80's statement that "no item owns its value today" still holds for accepted
   and published text, and its re-verify trigger "when R77 publishes a
   readiness-propagation pause" covers this. However, R80's own analysis says the
   latch does nothing when the window is zero. When R77 is accepted, the
   controller should confirm that the two decisions agree on what a default of 0
   means for AC6 and AC11.
3. **R70 revision 4 (not owner-accepted) says a fifth extension member "is R80's
   to justify".** R80 leaves the choice with R70 and offers it two carriers that
   need no fifth member, so the hand-off is not circular. The re-verify trigger
   "when R70 publishes" covers it.
4. **Evidence label.** The `PASS V13` message in `check-standard-r4.log` says
   "all nine probe sources". The list actually pins 7 source files plus 2
   lockfiles, 22 artifacts in total. The decision's prose correctly says 22, and
   all 22 digests verify. This is a cosmetic error in a log message. The six
   `probe/manifests-*/*.toml` files are not pinned by any revision-4 check, and
   the empirical seat's rerun of the build is what exercises them.
5. **Gate 4 does not mention Windows.** The prompt says Windows support should be
   "noted, not required". The two members this item decides are `std` and Cargo
   mechanisms. The crates it consumes carry their gate answers in R66 and R69.
