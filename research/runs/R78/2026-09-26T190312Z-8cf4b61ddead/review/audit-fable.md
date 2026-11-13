actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: ba104e3c2891b076d93c938c1ebc1c36a749315addce76ea5f37d28062fcf440
verdict: reject
unresolved-findings:
1. JF-8 / JF-1 — gate-table count does not match the census, and a shortlisted candidate has no gate answers.
   - Failed claim (DECISION.md:378, :383): column `OTel core 0.33.0 (5 crates)`, gate-3 `unsafe` cell "**0** lines in `src/` of all five (`S18`)"; and DECISION.md:354 "Four candidates passed every applicable gate", which includes `opentelemetry-appender-tracing` (DECISION.md:363).
   - Evidence: `r78-source-census.log` §8 (lines 95-106) censuses four OTel crates (`opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `opentelemetry-http` 0.33.0), not five. The bridge has its own column. The advisory checks `R04-*` in `r78-figures.log` §7 query the same four crates plus `tracing-opentelemetry`. No check covers `opentelemetry-appender-tracing`. No row of the gate table answers any gate for it. Its only gate evidence is `rust_version` 1.75.0 in the figures table (`r78-figures.log` §1). The "5 crates" label follows the shape of Opus's table (`raw/opus.md:509`), where the fifth crate is `-appender-tracing`. The decision cites the four-crate census for five crates.
   - Repair: change the column to four crates, "all four". Then give `opentelemetry-appender-tracing` its gate answers (advisories, `unsafe`, OS, default features and runtime, cost). Either carry them with a label from `raw/opus.md:509-516`, or extend `r78-figures.sh` R04 and `r78-source-census.sh` §8 to cover it and rerun. Otherwise, move it out of the shortlist.
2. JF-4 — the probe's `web` baseline is misdescribed, and a cited size figure and one citation rest on it.
   - Failed claims: DECISION.md:572 "`svc` is an axum 0.8.9 / tokio 1.53.1 service built with the exact dependency block in `## Decision`". DECISION.md:342-343 and :386 "+4.37 MB debug unstripped over `web`". DECISION.md:247-248 "(the probe used `reqwest` 0.13.5 because it is already in the `otel` tree)". DECISION.md:236-239 cite `r78-probe.log` §2 for `tower-http` 0.6.11 entering "through the exporter's blocking client".
   - Evidence: `r78-probe.sh:78` declares `web = ["dep:axum", "dep:tokio", "dep:reqwest"]`, and `:95` makes `reqwest` 0.13 optional under `web`. R69's registered `web-extra-surface` is `web = ["dep:axum", "dep:tokio"]`, with no `reqwest`. The decision quotes that value byte-identically at DECISION.md:512 but never discloses the departure. `r78-probe.log` §2 prints "tower-http in the web-only tree: tower-http v0.6.11". In the probe, therefore, `reqwest` and `tower-http` are already present without `otel`. As a result:
     - the 16,960,824 − 12,592,488 byte delta is measured over web+reqwest. It understates the `otel` increment over R69's `web`.
     - §2 does not show that `otel` brings `tower-http`. Only `V07`, the registry edge `opentelemetry-otlp` → `reqwest` 0.13.5 → `tower-http ^0.6.8`, supports that causal claim, and it does support it.
   - Repair:
     - Under "What the probe is", disclose that the probe's `web` feature adds `dep:reqwest` as the example's outbound client. This departs from R69's registered value.
     - Restate the size figure as web+reqwest → web+reqwest+otel, and note that the increment over R69's `web` is larger because it also adds `reqwest` and `tower-http`.
     - Cite `V07` alone for the `tower-http` cause, or rerun the probe with R69's exact `web`.
     - Correct the DECISION.md:248 parenthetical.

## Scope and reads

Judgment audit of `research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/review/DECISION.md`, revision 1. The recomputed sha256 matches the expected hash.

I read:
- the decision;
- `inputs/prompt.md` (sha256 `e3ef88cf…`, matching `manifest.json`), `inputs/parameters.json`, `inputs/prerequisites.json`, `inputs/EXECUTION.json` (the R78 entry) and `manifest.json`;
- `research/RUNBOOK.md` in full;
- the cited line ranges of all four pinned reports. I recomputed their hashes and all four match the decision's table.
- the three evidence logs, plus the probe script's manifest section;
- `docs/port/PARAMETERS.md`, which is the live registry;
- the prerequisite `research/topics/69-web-framework-stack/DECISION.md`. Its sha256 `d4507f5b…` matches `prerequisites.json`. I checked its cited lines 694, 1586 and 2349.
- `research/topics/53-config-schema-validation/DECISION.md:45,54-57`, which is cited for owner rulings.

R58 has no decision, so there was nothing to read for it. I read no `audit-*.md` file and no snapshot. I made no git writes, ran no runner commands and made no paid calls.

## Checks

- **JF-1 internal consistency — fail (finding 1).** The decision is otherwise consistent:
  - The date convention is explained: UTC 2026-09-27 is Pacific 2026-09-26.
  - The totals of 33 + 26 + 41 = 100 checks match the log trailers.
  - The degrade table, the Principles table and the Empirical-check prose cite the same check IDs with the same values: `D05` 12 spans, `D06` 9, 1,705/1,729 ms, 442/454 ms, exit 143 in 11 ms.
  - The runner-up and fallback are distinguished consistently.
  - The one defect is the "(5 crates)" / "all five" label against a four-crate census, with a shortlisted candidate left ungated.
- **JF-2 prompt questions and constraints — pass.**
  - All five HIGH questions are answered:
    - the shared requirement and its agreement level (capability and standard);
    - the runnable acceptance check, with executed and planned checks separated;
    - the crate set and its compatibility matrix, including `tracing-subscriber ^0.3.22` (`V03`);
    - the runtime degrade after compile-time absence (three gates plus the `OTEL_SDK_DISABLED` guard);
    - the py/ts/rs comparison.
  - Both MEDIUM questions are answered: the pure `Option<L>` addition (`S15`), and HTTP/protobuf as the default transport with no Tokio coupling (`F01`, `S07`, `S13`).
  - The LOW question is answered: qualitative cost plus a measured debug size, which is subject to finding 2.
  - Constraints are honored:
    - Figures carry their endpoints and the retrieval date 2026-09-27 UTC.
    - Maintenance follows the rubric.
    - The three-bin landscape is present.
    - Architectural alternatives A–E are compared before libraries.
    - Gate 1 is recorded as `inapplicable` with the Q7.B ruling.
    - Stable-only, edition 2024 and the 1.96 floor are respected (`M01`).
    - Gaps are stated, for example ubuntu not executed.
  - Two gaps within this check are carried into finding 1: the shortlist's appender-tracing gate answers, and fastrace responsiveness, which is openly marked as not re-sampled.
- **JF-3 `## Engines` fidelity — pass.** I spot-checked every quoted raw line against the pinned reports:
  - Muse: `:60`, `:73`, `:77`, `:90`, `:96-98`, `:102`.
  - Opus: `:157-180`, `:199-202`, `:244-246`, `:269-270`, `:424-434`, `:505-516`, `:526`, `:639-655`.
  - Doxa-OpenAI: `:16`, `:35`, `:73`, `:82-92`, `:124`, `:140`, `:160-168`, `:192-193`, `:212-214`, `:331-337`, `:353-361`, `:579`, `:768`.
  - Doxa-Gemini: `:33`, `:54-55`, `:69`, `:73`, `:78-82`, `:88`, `:92`, `:98`, `:102`, `:110`, `:120`, `:128`.
  
  Each position is represented faithfully. All 12 disagreements are adjudicated with registry, source or probe evidence. Two examples: Disagreement 1 by `C01`/`V01`/`V02`, and Disagreement 5 by the 0.33.0 CHANGELOG (`S04`). Both `BASELINE-REVIEW:` lines are carried verbatim with a disposition. Gemini's F304 line is dispositioned for lacking the required shape. Doxa-OpenAI's `owns R78.*` lines are correctly rejected against the empty `- owns:` line at `inputs/prompt.md:24`.
- **JF-4 load-bearing claims trace to evidence — fail (finding 2).** Spot-checks that pass:
  - `S01` `exporter/mod.rs:55` localhost:4318;
  - `S19` `unsafe` at `layer.rs:1557` and `filtered.rs:172,176`;
  - `S06`/CHANGELOG line 130 for the removal of `shutdown_tracer_provider`;
  - the `D05`/`D06`/`D08` log lines;
  - the E2E span graph, which matches the collector JSON line for line: four spans on trace `4bf92f35…` plus one readiness root trace;
  - issue-sample arithmetic: tracing-opentelemetry has 6 answered issues with a median of 0.5 d (0, 0.1, 0.2, 0.8, 1, 124.1). opentelemetry-rust has 4 of 7 unanswered issues under 4 days old at 04:27Z.
  
  The failure is the misdescribed probe baseline in finding 2.
- **JF-5 couplings — pass.** Each coupled item keeps its own choice:
  - The flag name and type stay with R77.
  - The request-span middleware and `tower-http` stay with R75. The `set_parent` call folds into R75's span if R75 picks one.
  - The subscriber, format and log export stay with R58. The decision states five explicit assumptions for R58 and says it "must be re-run rather than patched" if the substrate changes.
  - Metrics stay with R79.
  - The outbound client stays with R01's adapter.
  
  Observation (controller note c): the `tower-http` 0.6.11 vs R75 0.7.x tension is recorded as a coupling for R75 and a re-verify trigger. The decision does not decide it. That handling is correct. Its causal citation is covered by finding 2.
- **JF-6 assumes lines byte-identical — pass.** A scripted comparison against the value column of `docs/port/PARAMETERS.md` gives a byte match for all five `assumes` lines: `msrv-policy`, `rust-edition`, `target-os-matrix`, `license` and `logging-pipeline-contract = —`. The R69 `web-extra-surface` value quoted at DECISION.md:512 is also byte-identical to the registry.
- **JF-7 no conflict with published prerequisite values — pass.** The decision is consistent with R69:
  - `otel = ["web", ...]` nests on `web`, as R69 names it.
  - The module lives under `src/web/`.
  - axum 0.8.9 keeps `matched-path`.
  - tokio 1.53.1 runs multi-thread.
  - Exit codes are 143/130, and the probe observed 143 (`E03`).
  
  The recommended TOML does not alter `web`. The probe's own `web` departure is an evidence defect (finding 2), not a registry conflict. No `CONFLICT:` line is raised or needed. Observation (controller note b): R78 is CONDITIONAL on the unpublished R58 `logging-pipeline-contract`. The decision says so at its head and under `## Parameters`, and it lists the checkable conditions.
- **JF-8 evidence scripts exist and counts match — fail (finding 1).** All three scripts and logs exist. The trailers read 33/33, 26/26 and 41/41 with `fail=0`. The RustSec checks query hyphenated crate names (`r78-figures.sh:200`), and the `atty` control validates reading a 404 as "no advisory". Every shortlist figure I checked matches `r78-figures.log` §1, §4 and §5. The one mismatch is "all five" in `S18`, which covers four crates.
- **JF-9 decision shape — pass.** The H2s are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in RUNBOOK §5 order. There is no `## Supersedes`, which is correct for a first revision. `### Principles and implementation` is present. Settled rows are F325 (plus F304, deferred to R58). A `re-verify:` line with events is present. The Empirical check states the toolchain, OS, commands, working directory and observed output.
- **JF-10 recommendation follows from the evidence — pass.** Three lines of evidence support the recommendation: architecture A is agreed by all four engines; the single-generation resolution is measured (`T02`–`T04`); and the flag gate follows from `D05` and `D06`. The 0.33/0.34 choice over 0.32 is argued with dated registry facts and with the 0.33 behaviors `S02` and `S04`. The glue runner-up's winning condition is observable (`V04`, `V06`).

## Observations (not findings)

- Controller note (a): the engines lines in `inputs/prompt.md`, `inputs/EXECUTION.json` and `manifest.json` (`required_engines`) still read `codex, opus, doxa`, while the run used Muse under Q17.A. Canonical-prompt drift is limited to those two lines, as I confirmed with `diff`. `manifest.json` also records `operations: {}`. Repair: the controller re-freezes the inputs and cites Q17.A. This does not fail the synthesis, which flags the drift itself.
- The Muse leg records no resolved model ID. The decision records this gap for the controller.
- The synthesizer is the same model as the Opus seat, which the decision discloses. I am also a Claude Opus-family context, so this audit adds no cross-family check on the Opus leg's claims.
- Carried and uncorroborated claims are labelled as such: the adopter manifests, upstream CI matrices, the SIG maturity table, and the `axum-tracing-opentelemetry` gate-4 exclusion. Gate 4 is executed on macOS only.
