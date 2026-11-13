decision-sha256: 248ee192ce441523759266f5a24b76507947c514dfe0e7141af931d245c908e7
actor: audit-codex-2026-09-05T163615Z-417f07db9a2c-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1 enforcement does not enforce the required version-comment format; F2 the saved verification script does not reproduce the claimed whole evidence log

## Rerun

I ran the recorded verification script from `/Users/stevemorin/c/rs-launch-blueprint-p02-plan` with this argv, redirecting its complete output to the required auditor log:

```sh
bash research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/action-pin-verification.sh > research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/audit-codex-r1.log 2>&1
```

The rerun exited `0`. Its toolchain was `rustc 1.98.0`, `cargo 1.98.0`, macOS 26.4 arm64, and `gh` 2.98.0. The Linux rerun could not be performed: `limactl` was callable, but the stopped `ubuntu` instance could not start because the sandbox denied `unlinkat /Users/stevemorin/.lima/ubuntu/ha.stdout.log`. The macOS rerun was therefore used.

Log: `review/evidence/audit-codex-r1.log`.

The output does not match the decision's claim that the saved script reproduces the whole original log. It matches the substantive source results, including the pin counts and the exact `v5` tag and branch lookups, but a `diff -u` against `action-pin-verification.log` has changes beyond the dynamic UTC timestamp and normalized Addendum headings. The missing and rewritten addendum output is detailed in F2.

## Findings

### F1 — the recommended CI gate does not enforce the stated version-comment contract

`review/DECISION.md:24` requires every third-party clause to use `owner/repo@<40-hex> # vX.Y.Z`. `review/DECISION.md:32-35` makes a `zizmor` policy map and a CI invocation of `zizmor .github/` the complete enforcement mechanism. The same decision makes the comment grammar an observable acceptance criterion at `review/DECISION.md:118-119`.

The cited `zizmor` documentation does not support that enforcement claim. Its default persona is `regular` (`docs/usage.md:625-632`), while a missing version comment is reported only by the `pedantic` persona (`docs/audits.md:1435-1451`). Further, zizmor's own `ref-version-mismatch` test data accepts a matching comment without the required `v` prefix. Thus the documented `zizmor .github/` invocation accepts a SHA-pinned clause with no comment, and `--persona=pedantic` alone still does not establish the decision's exact `# v…` grammar.

The decision acknowledges a separate CI assertion only as a possible future guard at `review/DECISION.md:416-420`; it is not part of the recommended enforcement. The format, acceptance criterion, and gate therefore disagree. Before acceptance, either add a CI check that enforces the exact comment grammar and pair it with a pass/fail P03 test, or narrow the stated format and criterion to the behavior the declared command actually checks. If the comment must also resolve to the pinned SHA, retain `zizmor`'s `ref-version-mismatch` audit and run it in the appropriate persona in addition to the grammar check.

### F2 — the recorded script does not reproduce the whole recorded evidence log

`review/DECISION.md:230-235` says the appended follow-up commands are now in `action-pin-verification.sh`, so a rerun reproduces the whole log apart from normalized Addendum headings. The auditor reran that exact script successfully, but the outputs differ materially:

- The original Addendum 1 records the `matching-refs/tags/v5` interpretation, the py dependency-review source heading, the Scorecard heading and byte count, and the zizmor ignore and policy-grammar headings. The current script emits only selected command output.
- The original Addendum 3 prints the full distinct py values, the commented-out TypeScript clause, and the prefix-match branch probe. The current script replaces them with two compact count lines and the one non-SHA value.
- The original Addendum 4 records the prefix-match result before the exact tag/head lookups. The current script records only the exact lookups.

The important conclusions remain independently reproducible: the audit's pinned-tree enumeration gives Python `30` occurrences, `14` distinct values, `13` distinct repositories, and `0` SHA pins; it gives TypeScript `12` live third-party clauses and `11` SHA pins; and the exact GitHub API lookups return HTTP 404 for `refs/tags/v5` and `refs/heads/v5` at `a1d282b36b6f3519aa1f3fc636f609c47dddb294`. However, the decision's broader preservation claim is false. Amend it to say the current script reproduces the listed conclusions, or restore the omitted commands and output framing before asserting whole-log reproduction.

## Assessment

The audited source facts are supported. I independently enumerated the pinned Git objects using `git ls-tree` and `git show`, not either working tree. This confirms the Python `30/14/13/0` result and the TypeScript `12/11` result. The separate exact-reference requests also confirm both halves of the dependency-review observation: `refs/tags/v5` is absent, while `refs/heads/v5` exists at the SHA pinned by TypeScript. A byte-for-byte `diff` of the four `assumes` lines against `docs/port/PARAMETERS.md` produced no output.

I spot-checked six cited primary URLs with `curl`; GitHub Secure Use, the Dependabot comment-update changelog, zizmor's audit and usage documentation, OpenSSF Scorecard's checks, and the immutable-releases changelog each returned HTTP 200. The reference-pin policy map itself correctly gives `actions/*` and `github/*` `ref-pin` treatment and all other repository patterns `hash-pin`; the failure is the unexpressed version-comment requirement, not the owner-prefix SHA rule.

The decision correctly labels the real-template execution tests as unproven rather than treating them as completed. That restraint does not cure F1, because the recommendation presently promises an enforcement behavior its declared command cannot supply. F1 and F2 require edits to `review/DECISION.md`; the audit verdict is therefore reject.
