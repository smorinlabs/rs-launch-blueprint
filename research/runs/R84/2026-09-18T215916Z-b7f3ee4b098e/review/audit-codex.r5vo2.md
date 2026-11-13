actor: codex
model: GPT-6
family: openai
decision-sha256: 90cf41d91cde910e5bfb087131ec332697759e235ff41ea72ed90a371b12d2ab
verdict: disputed
checks: 8/11
unresolved-findings:
  - The public-network archive rerun has four probe FAILs and a substantive diff from the recorded log.

# R84 revision 5 archive re-verification

The repaired `review/DECISION.md` SHA-256 was recomputed before reading or running anything. It matches the target above. The read-only prerepair snapshot `review/R84-r5-prerepair.md` matches SHA-256 `4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b`.

## Checks

1. PASS — repaired decision hash matches the target.
2. PASS — prerepair snapshot hash matches the supplied value.
3. PASS — public network resolves and returns HTTP 200 for `static.crates.io` and `raw.githubusercontent.com`; the earlier sandbox attempt returned `curl: (6) Could not resolve host` inside the archive extraction.
4. PASS — current bytes of all five evidence scripts match the verifier-recorded SHA-256 values below.
5. PASS — all five script modification times precede the 2026-09-27T16:12:05-0700 repair snapshot.
6. PASS — source claims reproduce 60 PASS, 0 FAIL, 0 SKIP; archive log says `rc=0 IDENTICAL`.
7. FAIL — the loopback-host probe yields 25 PASS, 4 FAIL, 0 SKIP; `T11`, `T12`, `T14`, and the combined `R03-R10` check fail, with `rc=4 DIFFERS`.
8. PASS — progenitor reproduces 6 PASS, 0 FAIL, 0 SKIP; archive log says `rc=0 IDENTICAL`.
9. PASS — registry figures were collected: its only archive diff is the UTC retrieval date, and its recorded result is 31 PASS, 0 FAIL, 0 SKIP.
10. FAIL — after the authorized normalization, the probe diff remains substantive.
11. FAIL — the public-network archive rerun contains four `FAIL` lines, rather than zero.

The unchanged `review/evidence/r84-archive-rerun.sh` was run from the repository root with its four script arguments and a 1,100-second per-command timeout. `CARGO_HOME` and `CARGO_TARGET_DIR` were set in the invoking environment. Output went only to `/tmp/r84-codex-r5vo2-public-e0liu4rw/r84-archive-rerun.log`; the harness exited 1 because `diff` found a difference. The harness embeds the checkout HEAD in its output.

**Normalization, as owner briefed:** ignore the archive-HEAD line, UTC date lines, and temp-path lines. These are volatile by design. Do not ignore check outcomes, summaries, or any other log lines. Under this rule the source and progenitor legs match, and the registry leg matches after its UTC date is removed. The probe differs substantively and has four FAILs. Its generated-package compilation and section-12 probe did not reproduce the recorded green run; the harness suppresses the underlying Cargo diagnostics, so this audit does not assign a root cause.

## Script stability

| Evidence script | Current SHA-256, matching verifier record | Local modification time |
|---|---|---|
| `r84-archive-rerun.sh` | `3bba3e2b008c5dfa139cf4ff0c2b3c85082ca61a0716ef4c47593d6c603f40f7` | 2026-09-25T11:42:39-0700 |
| `r84-openapi-to-rust-probe.sh` | `8996655e48180e3ba35e3273c4a59bf6fdce9b6f05a09b9c919b04e727f6faa9` | 2026-09-26T19:40:53-0700 |
| `r84-progenitor-probe.sh` | `b89ff53371954617d7858628486e091b051f0d6fc0598a31f71db5d2fd273055` | 2026-09-25T09:10:40-0700 |
| `r84-registry-figures.sh` | `6552c64251063f6a339abf24b228a3c0afa35f2388cb2faea6722d813942ec25` | 2026-09-26T13:24:42-0700 |
| `r84-source-claims.sh` | `b4fb4abc1af8b6a0df762e6482a18cde9f0fe316b211fc6ea597d7b0742d8275` | 2026-09-26T19:41:23-0700 |

This establishes stability since the prior verification. Modification-time precedence supports, but does not prove, prerepair identity. The scripts were never committed; this audit makes no Git-history identity claim.

## Verbatim public-network archive rerun

The following is the complete harness output. Lines prefixed `<` come from the recorded evidence logs; lines prefixed `>` come from this rerun. The `archive HEAD` and UTC date lines are shown for provenance but excluded from the normalized comparison.

```text
archive HEAD: 7d5e25e721c9397df739b84f29d71fb293fc8ea3
r84-source-claims: rc=0 IDENTICAL
r84-openapi-to-rust-probe: rc=4 DIFFERS
37,38c37,38
< PASS  T11 the generated package compiles on the current stable toolchain (1.98.1)
< PASS  T12 the generated package compiles on the 1.96.0 floor (msrv-policy: stable 1.98 minus 2)
---
> FAIL  T11 the generated package compiles on current stable
> FAIL  T12 the generated package compiles on the 1.96.0 floor
40c40
< PASS  T14 tokio IS in the generated client's normal tree (reqwest -> hyper), which is why it stays outside the workspace
---
> FAIL  T14 tokio IS in the generated client's normal tree (reqwest -> hyper), which is why it stays outside the workspace
57,72c57
<       DEFAULT_UNKNOWN_FIELD=accepted
<       DEFAULT_UNKNOWN_STATE=rejected unknown variant `suspended`, expected `active` or `archived` at line 1 column 44
<       RECIPE_UNKNOWN_VALUES=accepted state=Custom("suspended") visibility=Custom("internal")
<       RT_200=typed id=p1 state=Custom("suspended") visibility=Custom("internal")
<       RT_404_PROBLEM=api status=404 typed_status404=true
<       RT_404_NON_PROBLEM=api status=404 typed_none=true parse_error_some=true body=upstream proxy says no
<       RT_ACCEPT_SENT=application/json
<       RT_CALLER_DEADLINE=elapsed
< PASS  R03 R12.4 unknown response FIELD: the default output ignores it
< PASS  R04 R12.4 unknown ENUM VALUE, default output: a plain 'enum' schema renders closed and rejects 'suspended'
< PASS  R05 R12.4 with the recipe's [extensible_enums] entry AND the anyOf-open Visibility, both unknown values are kept
< PASS  R06 end to end over HTTP: the 200 body with an unknown field and two unknown values deserializes into the typed Project
< PASS  R07 R12.7 a problem+json 404 is branched on status and parsed into the typed Status404(Problem)
< PASS  R08 R12.7 a text/plain 404 from 'infrastructure' still surfaces as status 404 with the raw body, typed=None, parse_error kept
< PASS  R09 R12.6 DEPARTS (SHOULD): even with a caller-supplied Accept, only 'application/json' reaches the server — OVERRIDE (OV-11)
< PASS  R10 R12.3 is met by the caller: tokio::time::timeout around a call to a never-answering listener elapses
---
> FAIL  R03-R10 the section-12 probe crate failed to build or run
75c60
< PASS=36 FAIL=0 SKIP=0 TOTAL=36
---
> PASS=25 FAIL=4 SKIP=0 TOTAL=29
r84-progenitor-probe: rc=0 IDENTICAL
r84-registry-figures: rc=0 DIFFERS
2c2
< retrieval date (UTC): 2026-09-26
---
> retrieval date (UTC): 2026-09-28
```
