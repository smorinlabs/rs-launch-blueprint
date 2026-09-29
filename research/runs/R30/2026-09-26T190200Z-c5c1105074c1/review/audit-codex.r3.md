# R30 revision 3 empirical audit — Codex retry

actor: Codex
model: gpt-6
family: openai
decision-sha256: 163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5
verdict: blocked

## Verification

- The target `review/DECISION.md` SHA-256 was recomputed before inspection and again before this audit: `163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5`.
- Prior permitted reruns in `/tmp/r30-{lints,scope,severity,suppression,upstream-docs}.evr.log` were compared byte for byte against the corresponding complete committed logs with `cmp`, then inspected with whole-file `diff`. All five differ. Their PASS/FAIL and summary lines match exactly: lints 14 PASS, scope 20 PASS, severity 17 PASS, suppression 16 PASS; upstream docs reports 22 found and 0 missing. No rerun contradicts a load-bearing claim.
- The revision 3 channel repair is present: R42 `DECISION.md:26` assigns the `channel` value to R27; R27 prompt `:14` claims that value under F103; this decision routes Cargo ≥ 1.97 to R27 at `:43`, `:51`, `:226-229`, `:247`, and `:369`. The committed `r30-wiring-cost.log` has `H2a` 16.01 s at `:35` and `H3e`/`H3f` 0.69/0.49 s at `:168`/`:184`, matching the revised figures at decision `:6`, `:124`, and `:380-381`. The committed `r30-inputs.log:15-16`, `:36-44`, and `:59` records the corresponding checks. Policy and frozen-input assertions were not independently rerun under the prohibitions below.
- The supplied point-in-time `research/EXECUTION.json` SHA-256 is `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c`. The live file was not read; live-policy drift is not a finding.

## Findings

- **OBS-1 (OBS):** Whole-output comparisons for the five permitted reruns differ from the committed logs. The diff includes run timestamps, `CARGO_HOME`, scratch-workspace paths, Cargo elapsed times, and diagnostic ordering. These are disclosed as run-dependent in decision `:6`, `:260-263`, and `:414`. PASS/FAIL and summary lines are unchanged.
- **B-1 (BLOCKING):** `r30-wiring-cost.sh` cannot be rerun. Decision `:281` claims “identity of recipe, hook and CI commands (`H1`); cost (`H2`); the real `just` recipe and the real lefthook pre-commit hook, including a refused commit (`H3`); clippy after the gate and clippy's `E0308` (`H4`)”. The user prohibits “no git subcommand”. The script invokes `git --version` at `:20`, `git init`, `git add`, and `git commit` at `:145`, and further Git commands at `:170-190`. The committed log can be inspected, but this audit cannot independently rerun the claimed evidence.
- **B-2 (BLOCKING):** `r30-wiring-severity.sh` cannot be rerun. Decision `:282` claims “a lint warning fails `just typecheck` (line-prefix variable) and `lefthook run pre-commit` (per-job `env:` key), while plain `cargo check` stays green (`V1`)” and that `--locked` at the hook refuses an un-updated lockfile (`V3`). The user prohibits “no git subcommand”. The script defines a `git ... commit` helper at `:36`, invokes `git init` and `git add` at `:73`, and uses additional `git add`, `git reset`, and `git checkout` at `:77-106`. The committed log can be inspected, but this audit cannot independently rerun the claimed evidence.
- **B-3 (BLOCKING):** `r30-inputs.sh` cannot be rerun. Decision `:284` claims “the re-frozen prompt and policy are byte-identical to the live files (`I-prompt`, `I-policy`)” and checks the R27/R42 revision repair, snapshots, and quoted figures. The user prohibits “no `inputs/` reads, no EXECUTION.json reads” and “snapshots”. The script reads `inputs/prompt.md` at `:26-33`, `inputs/EXECUTION.json` and live `research/EXECUTION.json` at `:34-46`, and revision snapshots at `:69-74`. The committed log can be inspected, but this audit cannot independently rerun the claimed evidence.

unresolved-findings: B-1, B-2, B-3
