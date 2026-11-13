decision-sha256: 0309754689dc338010858e46a59f7b6f52ed8859464b9ac1dfc564d5a537ed5f
actor: audit-codex-2026-09-17T020714Z-f9e4f950ea82-r1
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash review/evidence/r48-claims-check.sh`
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R48/2026-09-17T020714Z-f9e4f950ea82`
- toolchain: Darwin arm64; `rustc 1.98.0 (88d9e12ae 2026-08-18)`; `cargo 1.98.0 (797e8a9bc 2026-08-05)`; `/usr/bin/grep` BSD grep 2.6.0-FreeBSD.
- exit code: 0. Complete output: `review/evidence/audit-codex.log`.
- result: 20 PASS, 0 FAIL, 0 SKIP. The stable `PASS`/`FAIL`/`SKIP`/`RESULT:` lines match `review/evidence/r48-claims-check.log` exactly.
- clean archive rerun: extracted `git archive HEAD` to an isolated `/private/tmp/r48-audit-archive.*` directory and ran its copied script. Exit code: 0. Complete output: `review/evidence/audit-codex-archive.log`. Its stable lines match both `review/evidence/r48-archive-rerun.log` and the in-place auditor rerun exactly; it emitted no SKIP.

## Findings

No unresolved findings.

1. The check asserts content, not merely an exit status: it uses `set -uo pipefail`, records failures in `FAILED`, checks each HTTP status and parsed value, and exits with `FAILED`. The observed reruns therefore establish the stated 20 passes.
2. Direct `curl -A 'R48-empirical-audit/1.0'` reads re-derived the crates.io claims from `GET https://crates.io/api/v1/crates/<name>/versions`: `mockall` 0.15.0 / 1.77.0, `httpmock` 0.8.3 / 1.88.0, `wiremock` 0.6.5 / no declaration, and `mockito` 1.7.2 / 1.70. From `GET https://crates.io/api/v1/crates/<name>/<version>/dependencies`, the parsed required-normal counts are `mockall` 6, `wiremock` 15, `mockito` 16, and `httpmock` 25. `GET https://crates.io/api/v1/crates/httpmock/0.8.3` reports the sole default feature `cookies`.
3. Direct primary-source reads confirm the RustSec control (`lock_api` HTTP 200; all four candidates HTTP 404), wiremock-rs `archived: false` and `pushed_at: 2025-08-24T12:26:20Z`, its README table (`wiremock` Async; `httpmock` and `mockito` Async/Sync), and issue 173's recorded title, 2025-08-27 date, and closed state. The released `httpmock` v0.8.3 manifest is edition 2021 with no `unsafe_code` entry; master is edition 2024 with `unsafe_code = "forbid"`.
4. The owner-reference C12 input is present and reconciled rather than adopted on authority. The factual grounds for differing from it are primary-source checked above; `contentauth/c2pa-rs` directly contains exact `mockall = "0.15.0"` and `httpmock = "0.8.3"` lines, and httpmock's own platform workflow contains the Ubuntu/macOS/Windows matrix.
5. The five active `- assumes` lines are byte-identical to the five matching `docs/port/PARAMETERS.md` values. `review/DECISION.md` has exactly the required H2 set (`Decision`, `Parameters`, `Empirical check`, `Engines`), one `### Principles and implementation`, and one `re-verify:` line; both raw reports have the required ten top-level H3 answer sections in order.
6. The decision does not overclaim implementation proof: it labels the `MockProjectsPort: Send + Sync` erasure, ephemeral-port parallelism, F121 invocation, and compile-time/binary-size costs as P03 validation or unproven work. No licence finding is raised because gate 1 is correctly marked inapplicable under owner ruling Q7.B.

## Assessment

Approve. The recorded check reproduces in both required environments, its stable output matches both committed logs, the material external facts were independently re-read from their primary endpoints, and unbuilt-template claims remain explicitly unproven.
