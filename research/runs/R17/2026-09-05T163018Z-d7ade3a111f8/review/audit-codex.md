decision-sha256: e2c3d588eaf1a098027b4c9ced4fa01ef1341fd27ef4cfdfa012bfc44a8321ec
actor: audit-codex-2026-09-05T163018Z-d7ade3a111f8-r2
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

argv: `bash /private/tmp/r17-audit-r2-direct-gh.*/run-checks.sh`, an unmodified copy of `review/empirical/run-checks.sh` (sha256 `c2fb2c62a64256a0d68ff868bfd4f5d6f7ba3896e7894c5fadf2071b751fa73d`), launched with `PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin` and `XDG_CACHE_HOME` set to a mode-`0500` outer directory. The direct Homebrew `gh` binary is necessary because the normal `gh` resolution is a `mise` shim; the check's deliberate `env -i` unauthenticated control otherwise fails in that shim before it invokes GitHub CLI.

cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R17/2026-09-05T163018Z-d7ade3a111f8`.

toolchain: macOS arm64; `rustc 1.98.0`; `cargo 1.98.0`; `gh 2.98.0`; `curl 8.7.1`. The supplied Linux VM could not be started: `limactl start ubuntu` was denied while unlinking `/Users/stevemorin/.lima/ubuntu/ha.stdout.log`. The recorded check specifically downloads and executes the macOS arm64 binary, so this macOS rerun is the applicable execution.

exit code: `0`. The complete rerun in `review/evidence/audit-secret-scanning-ci-workflow-r2.log` ends `summary: PASS=27 FAIL=0 SKIP=0` and `RESULT: PASS`; its 27 assertion lines match the decision's comparison rule. A preliminary run through the normal `mise` shim reached `PASS=26 FAIL=1` only because the no-auth control did not reach `gh`, not because the repaired provenance command failed.

log path: `review/evidence/audit-secret-scanning-ci-workflow-r2.log`.

output matches the decision: yes, for the direct-`gh` controlled rerun. Assertion `07a` succeeds while `07f` reproduces exit `1` and `no valid Sigstore verifiers could be initialized` when the script's trusted-root cache is unwritable; `07g` separately reproduces unauthenticated exit `4`. This verifies the stated specific diagnosis rather than an environmental explanation in general.

## Findings

### Confirmed — cache diagnosis and repair

The outer cache is non-writable in the passing rerun, but the first provenance invocation redirects `XDG_CACHE_HOME` to its writable `$WORK/gh-cache` and passes. The identical invocation with `$WORK/ro-cache` at mode `0500` fails before artifact verification with the expected verifier-initialization message. The separate no-auth control reaches `gh`, exits `4`, and prints the login instruction. These controls establish the claimed cache-specific failure mode and distinguish it from missing authentication.

### Confirmed — provenance scope and flag semantics

`gh attestation verify --help` states that `--repo` or `--owner` is the minimum identity constraint, and that workflow identity is more precise when `--signer-workflow` or `--cert-identity` is supplied. It also documents `--deny-self-hosted-runners` separately. The decision accurately limits the executed command to repository identity and records `buildSignerURI` and `runnerEnvironment` as certificate observations; P03 is correctly required to add `--signer-workflow` or `--cert-identity`. No GitHub Actions runner was exercised.

### Confirmed — unchanged decision content

Against revision-1 blob `84d321b23200b91447ea6c1fe367fce5ee524aa0` (decision sha256 `6c0a240e6d12f34c106a44d6e7f5cdf02fe4b1825f048226d96297b618b9e18`), the Part 2 recommendation, F050 ledger row, `BASELINE-REVIEW: F050` line, equal-base-and-head narrowing, validity-filter exit-code finding, and all four `assumes` lines are byte-identical. Acceptance checks 1 through 3 and the gate rule are also byte-identical; revision 2 only qualifies the separate provenance-on-runner requirement.

### Confirmed — source and log checks

Six cited endpoints returned HTTP `200` by `curl`: GitHub Docs secret-scanning guidance, TruffleHog `v3.95.9` `action.yml`, the crates.io Kingfisher endpoint, the unrelated `mongrov/kingfisher` repository, MongoDB Kingfisher releases, and MongoDB Kingfisher's repository API endpoint. Ten credential-shaped patterns returned zero matches against the evidence log; matched values were never printed during this audit.

## Assessment

Approve revision 2. Its evidence now proves the developer-machine provenance claim under the condition that rejected revision 1, proves the two stated prerequisite failures as distinct controls, and limits the unexecuted CI-runner claim to P03. The `mise`-shim first-attempt result is a local command-resolution wrinkle documented above; it does not change the decision, and the direct GitHub CLI rerun reproduces the recorded pass set.
