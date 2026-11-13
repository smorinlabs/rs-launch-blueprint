decision-sha256: 20693ce171bcde1e4e0bbe1c8b03e3b11a5619d2824ed6578af8abf6305791ba
actor: audit-codex-2026-09-05T160304Z-99a3dd6456c0
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `NPM_CONFIG_CACHE=<isolated writable cache> bash run-checks.sh`
- cwd: disposable fresh copy of `review/empirical/` at `/private/tmp/R47-empirical-audit.sj6svc`; this avoided retaining any artifact beyond the two requested review files.
- toolchain: rustc 1.98.0; cargo 1.98.0; Node v26.5.0; npx 12.0.1; just 1.57.0; Git 2.50.1; Bun 1.4.0; macOS 26.4 arm64.
- exit code: 0.
- log path: `review/evidence/audit-terra.log`.
- output comparison: matches the decision's empirical result: all 51 assertions passed and the terminal lines are `summary: PASS=51 FAIL=0` and `RESULT: PASS`.

## Findings

No unresolved decision-changing finding.

The rerun proves the claimed state transition rather than merely starting the tool: an existing ledger selects offline `render` (cases 02–03), an absent ledger selects `init` and creates the ledger (case 04), and the guard then selects `render` without discovery (case 05). It also reproduces the inverse controls: missing owner, API failure, missing ledger for direct render, absent marked output, and shallow history all fail without fabricating a ledger (cases 06–10).

The exact `contributors-please@1.4.3` pin executed. The `npx` and `bun x` runners produced byte-identical output (case 11). Seven source URLs were requested with curl: five primary citations returned HTTP 200 and supported npm latest/version/license/Node engine, action `node24`, CLI bootstrap behavior, engine state/bootstrap behavior, and Python's `init` recipe. The two raw pinned TypeScript URLs returned HTTP 404; this limits that spot check only. It does not contradict the decision, whose local source evidence and executed fixture establish the selected recipe behavior.

## Assessment

Approve. The guarded `init`-when-missing / `render`-otherwise recipe is supported by an independent full behavioral rerun and the available citation checks. No decision revision is required.

