decision-sha256: d7946ed6a687834ee19530f49c27dad033f06eebd571aa77d30d0f2b7a3b9ca2
actor: audit-codex-2026-09-05T163018Z-61c8f49b581d-r4
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

Revision 4 is documentary under the owner's 2026-09-10 P02 ruling. `argv`:
no CodeQL command; `cwd`:
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R16/2026-09-05T163018Z-61c8f49b581d`;
`toolchain`: not applicable. I did not enumerate or download the ignored
CodeQL bundle, and did not run Lima. The read-only citation audit exited 0 and
is recorded in `review/evidence/audit-codex-r4.log`; its local pinned-source
and live `curl` output matches the decision's stated revision-4 correction.

## Findings

No unresolved finding.

1. `review/DECISION.md:102` now describes SurrealDB accurately. Live retrieval
   shows its configuration has `paths-ignore` and `query-filters`, with no
   `queries` key; its workflow sets `config-file:` and inline
   `queries: security-extended` on the same Init step. The decision therefore
   correctly classifies it as the hybrid that its A3 guard forbids, retains it
   only as `paths-ignore`/`**/` evidence, and names the selected shape's
   practice gap.
2. `review/DECISION.md:104-108` bounds each remaining adopter correctly.
   wasmCloud alone matches Alt-B exactly: inline `security-extended` and no
   configuration file. copper-rs selects
   `security-extended,security-and-quality`; xelis selects
   `+security-extended,security-and-quality`; both are the stated broader
   inline mechanism. OpenTelemetry selects neither suite input nor a config
   file. Direct HTTP inverse checks found no configuration file for those four
   repositories.
3. `review/DECISION.md:110` and `:133` correctly narrow the source-runner
   claim. At pinned py commit `b08bccf`, the CodeQL job uses
   `runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`; it is not a bare
   literal runner. Pinned ts and all five adopter Rust CodeQL jobs use a
   literal `ubuntu-latest`, so Ubuntu-only is the supported common statement.
4. The twenty named flagship repositories remain negative for an
   advanced-setup CodeQL scan. Each workflow file was retrieved and checked.
   `rust-lang/crates.io` uses `upload-sarif` for zizmor results but no CodeQL
   Init/Analyze/Autobuild step, so it does not contradict the decision's
   explicitly scoped "advanced-setup CodeQL workflow" statement. The source
   set is disjoint from the five adopters.
5. No implementation claim outruns the evidence. The decision calls P02 a
   proposal, leaves GitHub-runner, Action-upload, CI-guard, and
   queries-in-file end-to-end behavior as U1-U9 for P03, and does not treat
   its local CLI evidence as an Action run or a template implementation.

## Assessment

Approve. Revision 4 corrects the former practitioner error without expanding
the evidence claim: it now states the absence of a Rust queries-in-file adopter
as a gap and ties the remaining end-to-end proof to P03. Its recommendation is
supported only to the degree the recorded mechanism evidence establishes, and
the documentary scope properly avoids implementation or another CodeQL run.
