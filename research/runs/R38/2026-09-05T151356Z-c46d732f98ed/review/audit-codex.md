decision-sha256: 7e88ba81e5ce0ea7ae997cba7da199ece85acde3573fed2fcea9f039629a7a58
actor: audit-codex-2026-09-05T151356Z-c46d732f98ed-r8
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: The revision-7 cross-run comparator cannot reproduce from a clean git archive HEAD extraction: it requires the revision-6 Git blob a6e6641ea13c7e4b173cf7e0932fd682f794b28d, which an archive deliberately lacks, and exits 1 with three failed assertions

## Rerun

- argv: `bash run-checks.sh`
- cwd: `/private/tmp/r38-r8-archive.3B5pjy/review/empirical`, a clean `git archive HEAD` extraction.
- toolchain: Darwin 25.4.0 arm64; rustc/cargo 1.98.0; Git 2.50.1.
- exit code: 0; complete log: `review/evidence/audit-codex-r8.log`.
- output matches the decision's asserted result: yes — `summary: PASS=35 FAIL=0 RECORD=5` and `RESULT: PASS`. The saved-log bytes differ only in ordinary rerun material: timestamp, archive paths, cold-install preamble, and throwaway Git object IDs.
- required revision-7 cross-run rerun: `bash review/evidence/r38-crossrun-compare.sh`, from `/private/tmp/r38-r8-archive.3B5pjy`; exit 1; complete log: `review/evidence/audit-r8-crossrun-compare.log`.

## Findings

1. **Blocking — the asserted cross-run evidence is not self-contained in the required clean archive.** The comparator's phase E says it recovers revision 6's `evaluate.sh` with `git show` of blob `a6e6641ea13c7e4b173cf7e0932fd682f794b28d`. A `git archive` extraction has the committed files but no `.git` object database, so that command exits 128. The comparator then fails `r6/blob-recovered`, `r6/blob-is-the-evaluation-script`, and `r6/used-the-absolute-path`; its terminal lines are `failed assertions: 3` and `RESULT: FAIL`. Revision 8 says the revision-7 comparator exits 0 with `failed assertions: 0`, and the audit instruction specifically requires this clean-archive rerun. The decision must either ship the needed historical source as an archive-contained input or narrow/correct that reproducibility claim.

2. **Verified non-findings.** `git diff c65327f 08f1a9c -- review/DECISION.md` changes exactly lines 1, 3, and 259; `## Decision` (46,599 UTF-8 bytes), `## Parameters` (2,483 bytes), and `## Empirical check` (23,766 bytes) are each byte-identical to revision 7. The `## Supersedes` payload is 82,801 bytes, hashes to `97da7f169f26fce8f9b43c3d6c2eb0971b991f45b0d00ae2a91c5ddc3cbe4437`, and is byte-identical to the published revision-5 file. The owned `commit-message-convention` value is byte-identical to `docs/port/PARAMETERS.md:13`; no evidence script or pre-existing log changed between `c65327f` and `08f1a9c`. Gate 1 is correctly `inapplicable` under Q7.B, and `committed` is pinned to 1.1.11. Five source spot checks passed with curl; log: `review/evidence/audit-r8-citation-checks.log`.

## Assessment

Reject. The decision's selected-tool acceptance result reproduces, and the revision-8 provenance, section-identity, published-payload, parameter, and gate-1 claims are correct. Its inherited cross-run evidence does not reproduce from the explicitly required clean archive, so the decision cannot be accepted until that claim is repaired.
