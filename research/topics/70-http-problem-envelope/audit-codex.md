actor: codex
model: gpt-6-sol
family: openai
decision-sha256: a8d4da0ba18bad9bb581aad51f6e11234b29f3db14e1bbb99d2cfeb5e14d4b85
execution-sha256-pin: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

# R70 revision 5 empirical re-run

The target hash matched before and after the re-runs. `research/EXECUTION.json` also matches the S79 point-in-time pin above. This audit reports execution and source-line checks only.

## Execution and byte comparison

Every stdout/stderr capture went to `/tmp/r70-codex-r5.nG884Z`. `registry.sh` ran from a `git archive HEAD` extraction under that directory because it writes `registry-figures.log` beside itself. `archive-check.sh` ran in the extraction with read-only `GIT_DIR` and `GIT_WORK_TREE` pointing to the archived tree. Its output files stayed under `/tmp`. `rerun-r4.sh` requires `git clone` and `git checkout`, which are forbidden git writes. I ran a `/tmp` copy with only that setup replaced by `git archive HEAD`, and directed its nested `archive-check.sh` through the same read-only git environment. The original evidence scripts and committed logs were not edited. The composite re-run confirmed all 13 earlier committed evidence files stayed byte-identical after execution.

| Script and committed log | Fresh result | Byte comparison |
|---|---|---|
| `registry.sh` / `registry.log` | PASS 64, FAIL 1, SKIP 0; exit 1 | Different date banner and one IANA verdict, with its summary. The other 64 verdicts agree. |
| `registry.sh` / `registry-figures.log` | Fresh point-in-time figures captured under `/tmp` | Different by design: the script labels this a moving snapshot (`registry.sh:9-10`, `:54-56`). |
| `probe.sh` / `probe.log` | PASS 33, FAIL 0, SKIP 0; exit 0 | Banner and scratch path differ; every verdict and captured body agrees. |
| `archive-check.sh` / `archive-check.log` | PASS 8, FAIL 3, SKIP 0; exit 1 | The two disclosed IANA consequences recur. The third failure is its `.git` marker assertion: `git archive` omits `.git` in the temporary root. |
| Nested `registry.sh` / `registry-archive.log` | PASS 64, FAIL 1, SKIP 0 | Same one IANA verdict and summary difference as the direct registry run. |
| Nested `probe.sh` / `probe-archive.log` | PASS 33, FAIL 0, SKIP 0 | Banner and scratch path differ; every verdict and captured body agrees. |
| `rest-r2.sh` / `rest-r2.log` | PASS 79, FAIL 0, SKIP 0; exit 0 | Banner differs. Two OVERRIDE claim-count lines changed from 1 to 2; the other verdicts agree. |
| `probe-r2.sh` / `probe-r2.log` | PASS 25, FAIL 0, SKIP 0; exit 0 | Banner and scratch path differ; every verdict, body, and catalog line agrees. |
| `engines-r4.sh` / `engines-r4.log` | PASS 87, FAIL 0, SKIP 0; exit 0 | Date and HEAD banner differ; all 87 verdicts agree. |
| Safe execution copy of `rerun-r4.sh` / `rerun-r4.log` | PASS 27, FAIL 3, SKIP 0; exit 1 | Moving banner and HEAD differ. Two failures follow from the temporary archive's missing `.git` marker; one follows from the changed OV-03 and OV-04 counts. Its nested IANA and compile checks reproduced. |

The first attempts at `registry.sh` and `probe.sh` could not resolve external hosts under the default sandbox. Both were rerun with read-only network access; the results above are from those completed reruns. Every shell invocation stayed below 1200 seconds.

## Revision 5 repair checks

- The carrier is `diagnostics` in the coupling (`DECISION.md:591-600`) and in the explicit choice (`DECISION.md:1255-1275`). R80 revision 6 assigns R70 the choice and names the three carriers (`research/topics/80-health-probe-endpoints/DECISION.md:859-865`); it shows py's `diagnostics` member at `:853`, redaction at `:1007`, and the executed T4 carrier at `:1155`. The published R80 file has `OVERRIDE (OV-05)` at `:790`. The pinned REST standard blob has zero occurrences of `diagnostics` in a case-insensitive read-only `git show` search.
- F-1 holds at the repaired citations. `DECISION.md:1069-1074` points to `R8`, which checks that `/upstream` omits both the token and host (`probe-r2.sh:979-990`), and to the whole-file token check (`probe-r2.sh:1309`). `R24` lists fourteen requests at `probe-r2.sh:1225-1243` and asserts twelve failures and two successes at `:1258`. The W5 server-error rule is attributed to `R3` in `DECISION.md:495-498` and asserted at `probe-r2.sh:914-919`.
- F-2 holds: `DECISION.md:1164-1170` attributes derive rejection to both reports and the runtime `HashMap<TypeId, StatusCode>` rejection to Muse alone. `raw/muse.md:136` contains both positions; `raw/opus.md:287-290` and `:868-872` reject a derive and do not discuss that runtime map.
- EA-1 holds: `engines-r4.sh:186-200` reads R80's published revision 6 and the R02 revision-2 snapshot. The snapshot recomputed to `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f`. All 87 assertions pass, including the R80 carrier lines and the R02 boundary citation.

## Findings

- **OBS — disclosed IANA drift confirmed.** `DECISION.md:943-952` says IANA changed `[RFC9457]` to `[RFC 9457]`. The direct registry run differed from its committed log on exactly that literal-match verdict and summary; the nested archive run did the same. The whitespace-tolerant checks in the safe composite re-run fetched both `problem+json` and `problem+xml` rows and passed.
- **OBS — point-in-time OVERRIDE claim counts changed.** The fresh `rest-r2.sh` log says OV-03 and OV-04 are each claimed by 2 decisions outside R70, versus 1 in the committed log. `rest-r2.sh` still passed 79/79, found OV-06 free, and found no R70 `OVERRIDE` heading. This is a live repository count, not a contradiction of the decision's claim that those numbers are claimed (`DECISION.md:941-942`).
- **OBS — `/tmp` archive setup adds one marker failure.** The safe `archive-check.sh` run reports `FAIL  no .git marker at the repository root` because `git archive` intentionally omits `.git`. Its remaining two failures are the disclosed IANA consequences. This setup difference also makes two of the three safe `rerun-r4.sh` assertions fail; the third is the OVERRIDE count difference. The compiled probes and the 87 revision-5 checks pass.

No BLOCKING findings were observed.
