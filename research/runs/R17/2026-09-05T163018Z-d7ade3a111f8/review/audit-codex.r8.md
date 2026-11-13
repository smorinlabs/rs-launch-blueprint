decision-sha256: b9af093191361e0fdd98a765daa077c100d0ec215efb0026621836bc0152713f
actor: audit-codex-2026-09-05T163018Z-d7ade3a111f8-r8
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F3: `review/empirical/mutations-r8.sh` does not reproduce under its recorded ordinary invocation because its `PY3=$(command -v python3)` accepts the host's failing `mise` shim; neither mutation is applied, so its claimed falsifiability evidence depends on an undeclared clean PATH.

## Rerun

I read the decision at the hash above, then ran `env -u GH_TOKEN -u GITHUB_TOKEN -u R17_GH_TOKEN -u GH_BIN HOME=<scratch> PY_REPO=/Users/stevemorin/c/py-launch-blueprint TS_REPO=/Users/stevemorin/c/ts-launch-blueprint bash review/empirical/run-checks-r8.sh` from this run directory. The helper toolchain resolved to `python3`, `curl`, `shasum`, `awk`, and `sed`; the exit code was `0`; the complete output is [audit-secret-scanning-ci-workflow-r8-repo.log](evidence/audit-secret-scanning-ci-workflow-r8-repo.log). It reported `PASS=68 FAIL=0 SKIP=2`. The named skips were `04g` (no declared GitHub token) and `04h` (no local `cosign`).

I also created a clean `git archive HEAD` extraction from `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`, verified the archive had no `.git` directory and that its `DECISION.md` has the bound hash, and ran the same command from the extracted run directory. Its exit code was `0`; the complete output is [audit-secret-scanning-ci-workflow-r8-archive.log](evidence/audit-secret-scanning-ci-workflow-r8-archive.log). It reported `PASS=67 FAIL=0 SKIP=3`: the two named skips above plus `13q` (no Git history in the archive). All non-token-conditioned `RESULT` lines match their committed counterparts byte-for-byte; the declared-token controls (`00b`, `04g`) and the resulting summaries differ only because this audit intentionally supplied no credential. The comparison, archive hash, Part 2 comparison, parameter comparison, and leakage scan are recorded in [audit-secret-scanning-ci-workflow-r8-integrity.log](evidence/audit-secret-scanning-ci-workflow-r8-integrity.log).

The reruns confirm `08e`: both `filesystem <dir>` and `git file://<fixture A>` exited `1` with `trufflehog: error: unknown long flag '--redact', try --help`; `08f` passed on both controls. They also confirm `08h`, `08i`, and `08j` separately at zero stdout/stderr occurrences, `08g` at exactly `2 AWS,Github`, and `08k` as undetected. The integrity scan found no fixture credential byte or email-shaped text in any revision-8 log. Part 2 and all four `- assumes` values are byte-identical to revision 7 and `docs/port/PARAMETERS.md`, respectively.

The clean-PATH rerun of `mutations-r8.sh` passed: mutation 1 made `08h`, `08i`, and `08j` fail, and mutation 2 made `08e` fail while `08f` passed; both mutated checks exited non-zero. Its complete record is [audit-secret-scanning-ci-workflow-r8-mutations.log](evidence/audit-secret-scanning-ci-workflow-r8-mutations.log). That does not cure F3: the ordinary invocation, with the same scratch `HOME`, exited `1` before either mutation ran because `command -v python3` selected the failing `mise` shim. Its complete record is [audit-secret-scanning-ci-workflow-r8-mutations-ambient-path.log](evidence/audit-secret-scanning-ci-workflow-r8-mutations-ambient-path.log).

I spot-checked five accessible cited endpoints with `curl`: TruffleHog repository metadata, the pinned release assets, the v3.95.9 Action, the Rust stable manifest, and GitHub secret-scanning documentation. The compact evidence is [audit-secret-scanning-ci-workflow-r8-citation-spotchecks.log](evidence/audit-secret-scanning-ci-workflow-r8-citation-spotchecks.log).

## Findings

### F3 — Mutation evidence has an undeclared PATH dependency

Evidence: [audit-secret-scanning-ci-workflow-r8-mutations-ambient-path.log](evidence/audit-secret-scanning-ci-workflow-r8-mutations-ambient-path.log) shows the ordinary `bash review/empirical/mutations-r8.sh` invocation resolving `python3` to a `mise` shim that fails under its untrusted configuration. The script prints `MUTATION mutation-1: COULD NOT BE APPLIED` and `MUTATION mutation-2: COULD NOT BE APPLIED`, then `mutation-harness failures: 2` and `RESULT: FAIL`. This occurs before either intended falsification is executed.

Why it matters: revision 8 uses this new harness as the evidence that `08e` and `08h` through `08j` can fail. A reader following its documented invocation can receive a harness failure caused by an ambient version manager rather than the stated mutations. The full check deliberately probes and bypasses this class of shim; the mutation harness claims the same environment discipline but does not implement it.

Required repair: resolve and probe `python3` as `run-checks-r8.sh` does, or state and enforce a clean PATH as an explicit invocation prerequisite; then rerun the mutation harness and update the decision/log record. Do not treat the clean-PATH audit workaround as proof that the committed ordinary invocation reproduces.

## Assessment

Round-7 F1 and F2 are repaired by executed, falsifiable checks. The unaddressed mutation-harness environment dependency means the newly claimed mutation evidence is not reproducible as recorded, so the decision needs the F3 repair before approval. Gate 1 is correctly inapplicable under Q7.B and is not a finding.
