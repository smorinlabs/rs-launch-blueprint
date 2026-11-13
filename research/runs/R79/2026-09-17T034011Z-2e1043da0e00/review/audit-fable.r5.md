# R79 — prometheus-metrics — judgment audit of revision 5

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: d1f4460e36a5a7c14e74cac8b8ecfc070bc40ffb1ef1c258841f277c33e27079
verdict: approve
unresolved-findings:
- JF5-1 (MECHANICAL, approve-with-repair) — the "shutdown" row now contradicts the corrected row above it.
  - Failed claim (DECISION.md:400, the `shutdown` row of the RUNBOOK §5 table): "the registry is in memory with nothing buffered to flush, so observations after the last scrape are lost".
  - Evidence: revision 5's own corrected text says the opposite about buffering. The "exporter failure" row at :399 and the upkeep paragraph at :450–:453 state that histogram samples stay pending until a scrape or an upkeep tick drains them. The published source agrees: `metrics-exporter-prometheus` 0.18.3 `src/recorder.rs:312`–`:315` (`run_upkeep` calls `drain_histograms_to_distributions`) and `:91` (called by `get_recent_metrics` inside `render_to_write` at `:142`–`:143`). So at shutdown, up to one upkeep interval of samples can still be pending. They are lost because a pull exporter has no sink to flush to, not because nothing is buffered. The row's conclusion (loss after the last scrape is ordinary pull semantics) and the "design statement, not executed" status stay correct. Only the middle clause is wrong. It is a wording inconsistency and changes no design.
  - Repair: in DECISION.md:400, replace "the registry is in memory with nothing buffered to flush, so observations after the last scrape are lost" with "the registry is in memory and a pull exporter has no sink to flush to, so any histogram samples not yet drained, and every observation after the last scrape, are lost". Fold this into the same round; no evidence file changes.

## Scope and method

This audit is independent. It read these files:
- the decision at the hash above, verified with `shasum -a 256` before anything else was done;
- `inputs/prompt.md` (sha256 `206b3fad…7de`, equal to the live topic prompt and to `manifest.json` `input_hashes.prompt`);
- `inputs/prerequisites.json`, `inputs/parameters.json` and `research/RUNBOOK.md` §2 and §5 (lines 60–80 and 197–215);
- `raw/opus.md` (its Landscape section) and `raw/muse.md` at the lines the decision cites;
- R69's published `research/topics/69-web-framework-stack/DECISION.md`;
- the evidence logs' summary lines.

Scratch work used only `/tmp/r79fa`. The audit made no git writes and no runner calls, and it read no prior audit or snapshot file.

**Not verified here, and stated so that the evidence below is not read as covering more than it does:**
- `decision-self-check-r3.sh` was not rerun. The claim that it gives "315 / 1 / 0 against revision 5" (DECISION.md:1066–:1071) belongs to the empirical audit.
- The revision note says revision 5 edits nothing else. That could not be diffed, because the r4 snapshot is forbidden reading. Instead, the two edited passages were judged against source.
- The decision already discloses two figures as carried on an engine's word: the compile-time estimate (about +8 s) and the issue-responsiveness medians. This audit did not re-collect them either.

## Checks

**JF-1 internal consistency: fail (MECHANICAL only; JF5-1).** Everything else is consistent, including every passage revision 5 touched:
- the "exporter failure" row (:399);
- the upkeep paragraph (:444–:467);
- unproven item 6 (its unscraped or rarely scraped scenario);
- the migration row for the serve binary's ticker;
- the revision-history row 5.

The recommendation, the upkeep ticker and the evidence are all unchanged, and the revision note says so.

**JF-2 every prompt question answered, every constraint honored: pass.** The table below maps each prompt question to where the decision answers it.

| Prompt question | Where the decision answers it |
|---|---|
| HIGH principle and agreement level | the capability-plus-policy table (:301–:311) |
| Architecture comparison A–D, with R78 coherence | :333–:372 |
| Runnable acceptance check | 10 criteria (:313–:331), executed as E6, E8, F1, F3 and F4 |
| Crate pair | :174–:182 |
| Self-exclusion | :410–:430, with a direct answer for both candidates |
| Cross-repo principle | :301–:311 and the `BASELINE-REVIEW: F326` line |
| MEDIUM on-by-default | :633–:657 |
| MEDIUM OpenAPI exclusion | :659–:669, handed to R71 as a requirement |
| LOW cost | E2, E3 and gate 6 |

Constraint and gate coverage:
- All six fitness gates are answered per candidate. Gate 1 is recorded as `inapplicable — owner ruling 2026-09-12 (Q7.B)`, which matches `docs/planning/p02/owner-decisions.md:157`–`:159`.
- The shortlist carries the prompt's figure columns.
- Observation, not a finding: the decision does not restate a three-bin `### Landscape` map. RUNBOOK:197–:205 defines the decision's shape, and that shape does not include the answer template's H3s. The map exists in `raw/opus.md` ("Bin 1 … empty, and that emptiness is documented", then bins 2 and 3). The decision's shortlist, exclusions and up-and-comer (`measured`) are drawn from it.

**JF-3 `## Engines` faithful, every disagreement adjudicated: pass.** Both reports are named with their hashes. Recomputed: `raw/opus.md` = `c1d02b81…45ac` and `raw/muse.md` = `15529e48…c378`. The Muse citations were spot-checked against the file, and every one matches the position the decision attributes to it. Muse line → claim:
- `:34`: "on by default with no env gate";
- `:41`: metric names under "May vary";
- `:73`: RustSec pages "retired (HTTP 404 GitHub Pages shell)";
- `:80`: "None of the five shortlisted candidates fails a fitness gate";
- `:99`: "grouped-pattern fallback" and status class;
- `:126`: "unconditional (non-optional) dependencies";
- `:148`: fallback conditioned on the framework.

Each of the 14 disagreements is settled with a log line, a source line or an explicit argument. The seven synthesizer-versus-Opus corrections are also recorded. The Muse registration gap is disclosed: `manifest.json` records operation `d4a2338f77114baba83a7670688fe894` as `submitting`, and `raw/muse.md` is untracked. It is handed to the runner and backed by re-verify trigger 17.

**JF-4 load-bearing claims trace to source: pass.** Revision 5's new claims were re-read from the published `metrics-exporter-prometheus-0.18.3.crate` (sha256 `1db0d8f1…9108`), and every cited line holds:

| Cited line | What it contains |
|---|---|
| `src/recorder.rs:413` | `pub fn render` |
| `:142` / `:143` | `render_to_write` opens with `self.get_recent_metrics()` |
| `:91` | `self.drain_histograms_to_distributions()` |
| `:125`–`:139` | the drain function, which folds samples via `clear_with(... entry.record_samples(samples))` into persistent `distributions`, so a failed scrape loses nothing |
| `:312`–`:315` | `run_upkeep` = drain + `commit_outstanding_description_writes` |
| `src/lib.rs:108`–`:110` | the "is _not_ spawned" upkeep contract |
| `src/exporter/builder.rs:88` | `upkeep_timeout = Duration::from_secs(5)` |
| `:443` / `:531` | the `#[cfg(any(...))]` gates |
| `:506` / `:605` | ungated `install_recorder` / `build_recorder` |

axum's `examples/prometheus-metrics/src/main.rs` at `axum-v0.8.9` calls `install_recorder` (line 90) and has no `run_upkeep` or `describe_*`. That supports "an omission that matters only between scrapes".

The py pin `b08bccfb` also matches: `settings.py:38`, `:44`, `:63`–`:64`; `app.py:148`–`:149`; `telemetry.py:46`–`:48`; `pyproject.toml:56`, `:62`, `:64`; and `core/paths.py:58` (`APP_NAME = "plbp"`). Three more citations match:
- `docs/port/COMMONALITY.md:330` (F326), verbatim;
- `docs/port/OWNER-REVIEW.md:187` and `:198`;
- `research/RUNBOOK.md:208` (the §5 example contract).

**JF-5 couplings hand choices to their owners without deciding them: pass.** Each coupling is a stated requirement or an explicit semantics handoff:

| Item | What the decision hands over |
|---|---|
| R80 | probe placement relative to `route_layer`; R80 keeps the paths |
| R77 | semantics only; R77 owns the name and the parsing. R77 at `1e3cdb5b` :663 lists `RSLBP_WEB_METRICS_ENABLED`, and :684 reads "`METRICS_ENABLED` \| not decided \| R79", both verified |
| R71 | a one-sentence excludability requirement plus trigger 4 |
| R75 | R2.6 308, R11.7 and R11.8 placement, and F320 left to R75 |
| R78 | the interface is fixed without designing against its unpublished run; `research/topics/78-opentelemetry-integration/` holds only `prompts/` |
| R69 | a `BASELINE-REVIEW: F326` rather than an edit of the owned value |

**JF-6 assumes lines byte-identical to the live registry: pass.** The four `- assumes` lines at :938–:941 equal `docs/port/PARAMETERS.md` rows 7–10 and `inputs/parameters.json`. No fifth line was added, and the reason is argued (empty `- consumes:`). The quoted `web-extra-surface` clause and the `tower 0.5.3 … dev-dependency only` clause match registry row 17 byte for byte.

**JF-7 no conflict with accepted or published prerequisite values: pass.** R69's `research/topics/69-web-framework-stack/DECISION.md` hashes to `d4507f5b…c10d`, and its `acceptance.json` hashes to `48a7dce8…7338`. Both equal `inputs/prerequisites.json`. The decision's feature table (`web = ["dep:axum", "dep:tokio"]`, `metrics = ["web", …]`) and its `src/web/` tree follow R69's owned value at :1586. R69's tokio features include `time`, which the upkeep `interval` needs. The OV-07 ruling is cited correctly: `docs/planning/p02/execution-ledger.md:1088` reads "Ruling: OV-07 may carry R79's two departures under the one number", both live and at `6a0cae7d`.

**JF-8 evidence scripts exist and cited counts match (spot-check): pass.** Every script the decision cites exists under `review/evidence/`. Log summary lines match the table at :1020–:1031:

| Log | PASS / FAIL / SKIP |
|---|---|
| `cargo-probes-r3.log` | 54/0/0 |
| `cargo-probes-r3.run2.log` | 54/0/0 |
| `crate-sources-r3.log` | 66/0/0 |
| `github-api-r3.log` | 5/0/0 |
| `rustsec-method-r3.log` | 9/0/0 |
| `decision-self-check-r3.log` | 316/0/0 |
| `cargo-probes.log` | 34/0/0 |
| `crate-sources.log` | 66/0/0 |
| `github-api.log` | 5/0/0 |
| `decision-self-check.log` | 70/0/0 |
| `rest-conformance-r2.log` | 122/0/0 |

Cited figures found in `cargo-probes-r3.log`:
- 37 versus 81 crates (lines 15–16);
- 79 crates with `--features metrics`, and `tower-http` absent (67–68);
- `JOINED 78 of 78`, `HIGHEST 1.85.0 hashbrown 0.17.1` and `UNDECLARED 12` (187–189);
- runner-up 82 crates, with `tower-http` added (204–206);
- the E8 `promtool` acceptance (171).

The quoted module at DECISION.md:481–585 is byte-identical to `review/evidence/r3-obs-metrics.rs` (checked with `diff`).

**JF-9 decision shape follows the published contract: pass.**
- The H2s `## Decision` (with `### Principles and implementation` and one `re-verify:` line), `## Parameters`, `## Empirical check` and `## Engines` are present, as RUNBOOK:197–:205 requires.
- `## Supersedes` is correctly absent, because nothing is published.
- The override uses `**Argument:**` and `**Options:**`.
- `BASELINE-REVIEW: F326` uses the prompt's form.

**JF-10 the recommendation follows from the assembled evidence: pass.** The recommendation is `metrics` `^0.24.6` plus `metrics-exporter-prometheus` `^0.18.3` with `default-features = false`, a template-owned `from_fn` middleware, a structural `/metrics` exclusion, and a default-true `RSLBP_WEB_METRICS_ENABLED`. Each part rests on evidence:

| Part of the recommendation | Evidence |
|---|---|
| the crate pair | both clear every gate |
| `default-features = false` | removes 44 crates, including `aws-lc-sys` (E2) |
| structural exclusion | proven by E6; `axum-prometheus` does not exclude `/metrics` by default (`src/lib.rs:73`) |
| runner-up ranking | `axum-prometheus` pulls `tower-http` 0.7.1 into the runtime graph ahead of R75 (82 versus 79 crates) |
| rejection of D | the maintainers steer new projects to OTLP |
| upkeep ticker | required by the exporter's own contract; revision 5's correction narrows the stated risk and leaves the requirement intact |
| off switch | mirrors py at its pin |

Revision 5's correction therefore strengthens the evidence without moving the recommendation.

## Summary

Verdict **approve**. No BLOCKING finding exists. One MECHANICAL finding, JF5-1, is to be folded into the same round with the exact repair given above.
