decision-sha256: 7e4e27e6d26577a6c1180cff7efea7bf9d755cdb247023aafd7a4b1f622eab19
actor: audit-codex-2026-09-05T163018Z-d7ade3a111f8-r3
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: the revision's byte-preservation claim is false for named approved content; the Part 2 recommendation, ranked runner-up, and validity-filter finding differ from revision 2

## Rerun

argv: `PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin XDG_CACHE_HOME=<mode-0500 temporary directory> bash /private/tmp/r17-audit-r3.*/run-checks.sh`, where the script was an unmodified copy of `review/empirical/run-checks.sh` with sha256 `4471f964f2936fc6e41b7885d85f87c793e6d8a5af3ca43135777b49171a1163`.

cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R17/2026-09-05T163018Z-d7ade3a111f8`.

toolchain: macOS arm64; `gh 2.98.0`; `curl 8.7.1`; the script's own section 00 records `rustc` and `cargo`. I attempted the supplied Linux VM first. `limactl` was callable, but `limactl start ubuntu` failed before boot with `unlinkat /Users/stevemorin/.lima/ubuntu/ha.stdout.log: operation not permitted`; the recorded script downloads and executes the macOS arm64 release, so this macOS run is the applicable rerun.

exit code: `0`.

log path: `review/evidence/audit-secret-scanning-ci-workflow-r3.log` (280 lines, sha256 `9b49450d01ae793446e8f3610169474fb9260e3517ad7a56a86d6984c27350b1`).

output matches the decision: the empirical execution does. It ends `summary: PASS=36 FAIL=0 SKIP=0` and `RESULT: PASS`, exactly as the decision specifies. All 27 revision-2 `RESULT` labels remain, with the nine new `10a` through `10i` labels. The document's separate claim that named already-approved prose is byte-identical does not match the diff; that is F1.

## Findings

### Confirmed — the fail-open evidence is reachable and the repaired rule is complete

Section 10 of the independent rerun extracted the whole documented table from `docs/USAGE.md` at `v2.2.0`, including its digest `28cbe0cabac3c4f0ad69ed25d882ca33bae3ed699cce1a1d7d2df4634d0a0b84`. It asserted the only documented codes are `0`, `200`, and `205`. The top-level rejected-flag probe exited `2`; the missing scan-target probe exited `1`; and `10g` proved neither is in the documented set. The pinned `github/docs` source also made `10h` and `10i` pass: the default `run:` shell is `bash -e {0}`, while explicit `shell: bash` includes `-e` and `pipefail`.

The full gate rule appears once at `review/DECISION.md:23`. Its later references in essential behavior 3, acceptance criterion 1, the per-principle paragraph, migration implications, the section-08 finding, and the P03 test list consistently preserve the same allow-list: `0` and `200` pass, `205` fails, and every undocumented exit fails as a tool error. Acceptance criterion 5 explicitly requires both a replaced scanner and a rejected flag to fail the job. The ranked runner-up explicitly says its allow-list must be re-derived from its own pin rather than inherit Kingfisher's values.

### Confirmed — the prior table-capture defect is repaired

The rerun log prints the heading, blank line, header, separator, and all three table rows, not only the heading. The file digest is printed immediately before that table. This closes the revision-2 `sed` range defect.

### Confirmed — citation and secret-shape checks

Six representative cited endpoints returned HTTP `200`: GitHub's secret-scanning documentation, TruffleHog `v3.95.9` `action.yml`, MongoDB Kingfisher's repository API, Kingfisher `v2.2.0` `docs/USAGE.md`, the Gitleaks Action README, and the crates.io Kingfisher API with the recorded User-Agent. The decision's ten secret-shape patterns each returned zero matches against this audit log. No secret-shaped value was added by this audit.

### F1 — reject: the stated byte-preservation claim is false

`review/DECISION.md:9` says that the recommendation and validity-filter finding "stand as revision 2 wrote them." A direct diff against revision-2 decision sha256 `e2c3d588eaf1a098027b4c9ced4fa01ef1341fd27ef4cfdfa012bfc44a8321ec` shows the Part 2 recommendation line is not byte-identical, the ranked-runner-up line is not byte-identical, and the section-08 validity-filter finding line is not byte-identical. Each now includes necessary allow-list wording. In contrast, the Part 1 recommendation, F050 table row, `BASELINE-REVIEW: F050` line, equal-base-and-head narrowing, provenance diagnosis, and all four `assumes` lines are byte-identical.

This does not undermine the gate repair. It does make the revision's preservation assurance inaccurate, including the requested confirmation of both recommendations and the validity-filter finding. Correct the revision note to distinguish unchanged tool-selection conclusions from changed wording, or enumerate only byte-identical anchors. No further scanner evidence is needed.

## Assessment

Reject revision 3 on F1 only. The fail-open defect is actually repaired: documented successful outcomes are allow-listed, two reachable unexpected outcomes are proven, the shell behavior is pinned and reproduced, and P03 has a concrete fail-the-job acceptance test. The decision must accurately describe what the diff preserved before it can be accepted.
