decision-sha256: 66d566a55330e2417a2e5227bcac64e3312fc56280db09d7b74a13425aa346c1
actor: audit-codex-2026-09-05T163616Z-1ab131aed82d-r2
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `LC_ALL=C bash run-checks.sh`; this is the decision's recorded `bash run-checks.sh` with the revision-2 collation explicitly selected.
- cwd: `research/runs/R21/2026-09-05T163616Z-1ab131aed82d/review/empirical`
- toolchain: macOS Darwin 25.4.0 arm64, `rustc 1.98.0`, `cargo 1.98.0`, `git 2.50.1`, `curl 8.7.1`, and `python3 3.14.7`. `limactl` is callable, but its `ubuntu` instance is stopped; I did not start it for this read-only audit.
- exit code: `0`; the saved rerun reports `summary: PASS=27 FAIL=0` and `RESULT: PASS`.
- log path: `review/evidence/audit-contributors-bot-credential-source-r2.log` (sha256 `01caad623e34e486b36d30eaacaf015c823cb22b3782f0bb99e5671e52f93219`).
- output matches the decision's historical revision-2 log: not byte-for-byte. Case 07 now reports `644053 bytes`, not `642032 bytes`, for the live GitHub Docs page. The endpoint set, all 27 assertions, and every other checked source result remain the same. `review/DECISION.md:175` expressly identifies a changed fetched byte count as substantive live-page drift that its normalizer must not erase.

## Findings

### No finding — the ordering difference is shell collation, not page reordering

The saved script's case-07 pipeline is `grep -oE ... | sort -u` at `review/empirical/run-checks.sh:148`. On macOS, the three relevant strings place `GET /user/{account_id}` before the package paths under `LC_ALL=en_US.UTF-8`, and after them under `LC_ALL=C`; the C result also matches the host's inherited `C.UTF-8` ordering. This proves the stated moving-line mechanism. The stopped Linux VM did not affect that result.

### No finding — the historical comparison claims reproduce exactly

The decision's counted `diff` between `contributors-bot-credential-source.log` and `contributors-bot-credential-source.r2.log` reports four changed lines. They are the two UTC `date:` lines and one byte-identical endpoint line removed and inserted at its locale-dependent position. The decision's normalizer returns `0` for the revision-1 saved log versus the revision-2 rerun, and `0` for the revision-1 saved log versus the predecessor audit log. It returns `2` for this fresh audit log versus the revision-2 rerun: the old and new case-07 byte-count lines. That difference is correctly outside the normalizer's stated scope.

### No finding — the script, parameters, and carried corrections were not changed

`review/empirical/run-checks.sh` has sha256 `3b8fd8ab6beec0e745ce2252d81fb2ca82343fd2531a8caa90850171419c6cc3` in revision 1, revision 2, and the working copy. Diffing revision-1 commit `b80e157` and revision-2 commit `2534ab7` changes only the revision title, the empirical-check text, and the case-07 table row, plus the inserted revision note. The four `assumes` lines are byte-identical between revisions and equal the `msrv-policy`, `rust-edition`, `target-os-matrix`, and `license` values in `inputs/PARAMETERS.md:7-10`. The eleven selected lines that carry the two baseline-review corrections are also byte-identical between revisions: their shared baseline line and annotation frame, clauses (3) and (4), B3, the O4 ground, the personal-account qualification, case rows 08 and 10, and disagreement rows 1 and 3.

### No finding — the decision attributes only checks the saved script emits

The fresh log contains exactly 27 `[ok]` labels. A one-to-one comparison against the 27 labels that support the decision's case table found no missing or extra labels, followed by the recorded passing summary and result. The four public GitHub Docs citations were fetched by that script without an Authorization header. A fifth unauthenticated curl spot-check of the cited `peter-evans/create-pull-request` concepts guide returned HTTP 200 and contains its stated PAT workaround and GitHub recommendation. Local pinned-source checks reproduce py's `CONTRIBUTORS_PLEASE_PAT` and ts's `GITHUB_TOKEN` workflow lines.

### No finding — the predicted 403 remains a prediction

The fresh case-11 output records that no credential or App was created, no App was registered or installed, no repository, branch, or pull request was created, no endpoint was called with a token, and the action was not run. `review/DECISION.md:45`, `:113`, `:192`, and `:214` consistently label the `GET /user` 403 mechanism as `(Q1, predicted)` or unproven and name the P03 check that would observe it. The carried-through baseline-review quotation is explicitly framed as unedited source material, and the decision separately states that its authenticated-run-history claim was not re-verified.

## Assessment

Approve. Revision 2 fixes the rejected overbroad reproducibility claim with a tested, bounded comparison rule. It distinguishes historical equivalence caused by timestamp and collation from the fresh live-page byte-count change, which the decision already says is substantive rather than normalized noise. The recommendation does not rely on the unexecuted 403 prediction, and no claim tested here exceeds the evidence that the saved script or explicitly identified source provides.
