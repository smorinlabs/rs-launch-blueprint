actor: codex
model: GPT-6
family: openai
decision-sha256: 90cf41d91cde910e5bfb087131ec332697759e235ff41ea72ed90a371b12d2ab
verdict: disputed
checks: 20/23
unresolved-findings: archive rerun differs outside the documented loopback host boundary; no prerepair script-byte listing was supplied

# R84 r5 single-verifier report

Prerepair sha256: `4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b`. The repaired decision sha256 above and this prerepair hash were recomputed before reading the files.

The unified diff from the prerepair snapshot to `DECISION.md` changes only the 13 numbered repair clauses below. No unlisted decision diff was found. These are line confirmations in the repaired file:

1. Both revision-header count lists give refused and allowed totals.
   - Line 16:

     ```text
pass/fail/skip counts (60/0/0, 31/0/5 refused / 36/0/0 allowed, 6/0/0, 31/0/0, 31/0/5 refused / 36/0/0 allowed). No script was rerun, because
     ```
   - Line 25:

     ```text
pin, every check identifier, and all pass/fail/skip counts (60/0/0, 31/0/5 refused / 36/0/0 allowed, 6/0/0, 31/0/0, 31/0/5 refused / 36/0/0 allowed). **Changed:** (a) the probe's tool cache is version-keyed
     ```

2. The 0.19.0 citation names both host totals and the T01-only behavior change.
   - Line 55:

     ```text
(`review/evidence/r84-openapi-to-rust-probe-0.19.0.log`, 31/0/5 refused-host / 36/0/0 loopback-host, behavior-identical apart from T01 on both) and the
     ```

3. Trigger 3 gives both host totals and same-host byte identity.
   - Line 346:

     ```text
   (`review/evidence/r84-openapi-to-rust-probe-0.19.0.log`): 31/0/5 refused-host / 36/0/0 loopback-host —
     ```
   - Line 347:

     ```text
   byte-identical to the `0.17.0` log on the same host except the `T01` version string, so every section-12
     ```

4. Both results-table rows give refused and allowed pass/skip cells.
   - Line 634:

     ```text
| `r84-openapi-to-rust-probe.sh` | The recommended recipe, executed end to end; section 12 of the standard | 36 | 31 refused / 36 allowed | 0 | 5 refused / 0 allowed |
     ```
   - Line 637:

     ```text
| `r84-openapi-to-rust-probe.sh` with `TOOL_VERSION=0.19.0` | Trigger-3 execution: the newest release through the same recipe; log `r84-openapi-to-rust-probe-0.19.0.log` | 36 | 31 refused / 36 allowed | 0 | 5 refused / 0 allowed |
     ```

5. The reproducibility sentence limits byte identity to one host class.
   - Line 607:

     ```text
place (the r2 audits' harness finding); logs reproduce byte-identically within a host class and differ across the refused/loopback boundary as the table records:
     ```

6. The archive paragraph says progenitor alone is identical across hosts and identifies the installed probe log.
   - Line 667:

     ```text
`review/evidence/r84-archive-rerun.sh`, whose output, with each differing log's full `diff`, is committed as `r84-archive-rerun.log`. **One** of the four logs is byte-identical across hosts: `r84-progenitor-probe.log`. `r84-openapi-to-rust-probe.log` is host-dependent (31/0/5 refused-host, 36/0/0 loopback-host; the committed log is the loopback-host rerun installed from the r5 audit's 2026-09-27 execution). `r84-source-claims.log` differs in **exactly one check** and its
     ```

7. The limitation is the HTTP half on Linux; macOS and RT_ACCEPT_SENT are stated.
   - Line 685:

     ```text
(2) **The HTTP half on Linux**: `R06`–`R10` are executed on macOS arm64 (loopback host; 36/0/0 log) and only non-macOS execution is unproven. `R09`'s `RT_ACCEPT_SENT=application/json` is executed on-the-wire evidence for `OV-11`.
     ```

8. The shortlist paragraph records the three gates, spargen exclusion, and adoption-only dispositions.
   - Line 471:

     ```text
**Qualified shortlist — two candidates, and the shortness is a finding.** Three surveyed tools clear every applicable gate on evidence. Of the other four young tools in the surveyed pool, one is excluded under R49 (`spargen`: build.rs/macro-only per its 0.5.0 README, read 2026-09-28) and three pass only adoption (`ploidy`, `openapi-nexus`, `oas3-gen`: no located adopter, fitness gates not evaluated); only `openapi-to-rust` joins the shortlist.
     ```

9. The four new gate-table rows are present.
   - Line 455:

     ```text
| **spargen 0.5.0** | MIT OR Apache-2.0 (`F01` on 0.4.0) | rust 1.88 (`F01` on 0.4.0) | Not evaluated (excluded below) | Not executed here | **Excluded under R49**: build.rs codegen + proc-macro expansion only (0.5.0 README mode table; no pre-generate CLI workflow, no --check mode) — induces codegen into every build, against CB01's checked-in-file guidance | n/a (excluded) |
     ```
   - Line 456:

     ```text
| **ploidy** | not evaluated | not evaluated | not evaluated | Not executed here | No located adopter; 3.1 capability and gates not evaluated — passes only adoption | n/a |
     ```
   - Line 457:

     ```text
| **openapi-nexus** | not evaluated | not evaluated | not evaluated | Not executed here | No located adopter; 3.1 capability and gates not evaluated — passes only adoption | n/a |
     ```
   - Line 458:

     ```text
| **oas3-gen 0.28.0** | MIT (crates.io record, read 2026-09-28) | rust 1.89 (crates.io 0.28.0 record) | Not evaluated (out of category) | Not executed here | Out of category: types only, no client (crates.io description "A rust type generator for OpenAPI v3.1.x specification.") | n/a |
     ```

10. Up-and-comers records the README finding, rejected --check claim, and oas3-gen category.
   - Line 495:

     ```text
**Up-and-comers.** `spargen` 0.5.0 (rust 1.88, MIT OR Apache-2.0) is 3.1/3.2 only, self-labelled alpha, one maintainer — and excluded under R49: its README mode table offers build.rs codegen and proc-macro expansion only, with no pre-generate CLI workflow and no --check mode (Muse's reading confirmed, Doxa-OpenAI's --check claim refuted, read 2026-09-28). `ploidy`, `openapi-nexus` and `oas3-gen` have no located adopter (figures in the snapshot); `oas3-gen` is out of category (types only, no client). None has enough adoption or evaluated gates to carry a template.
     ```

11. The runner-up row excludes spargen under R49.
   - Line 520:

     ```text
| `spargen` | Stricter 3.1 diagnostics | **Excluded under R49** (build.rs/macro-only per 0.5.0 README; no --check); no longer the design to watch |
     ```

12. The out-of-category list includes oas3-gen as types only.
   - Line 434:

     ```text
unrelated vendor SDK), `oas3-gen` (types only, no client; crates.io description, read 2026-09-28).
     ```

13. The engine split names the confirmed Muse reading and refuted Doxa-OpenAI claim.
   - Line 785:

     ```text
`spargen` description. Engine split settled 2026-09-28 (S1): build.rs/macro-only (Muse) vs --check mode (Doxa-OpenAI) — the 0.5.0 README mode table carries build.rs and Macro rows only, so Muse's reading stands and spargen is excluded under R49. Muse's figure of 72 reverse dependencies for progenitor. None of these is load-bearing for the pick. Each would matter only if
     ```

## Reruns and byte comparison

Each shell leg had an 1100-second process timeout and wrote its output to `/tmp/r84-codex-r5vo.nRkrCH`. `CARGO_NET_OFFLINE=true` was used after the first probe exposed `Could not resolve host: index.crates.io`; the private Cargo cache held the needed dependencies. The evidence scripts were executed without changes.

| Leg | Rerun result | Installed-log byte comparison |
|---|---|---|
| `r84-openapi-to-rust-probe.log` (0.17.0) | 31 PASS, 0 FAIL, 5 SKIP; refused-host outcome | Different only at `RT_BIND`, `R06`–`R10` PASS versus SKIP, and the summary; permitted host boundary |
| `r84-openapi-to-rust-probe-0.19.0.log` | 31 PASS, 0 FAIL, 5 SKIP; refused-host outcome | Same permitted host-boundary differences |
| `r84-archive-rerun.log` | Source claims 35/0/25; probe 31/0/5; progenitor 6/0/0; registry figures 0/0/5. Script exit 1 from `diff` | Different outside the host boundary: archive `HEAD`, source claims, registry figures, UTC date, and diagnostic stderr |

Installed archive log: `archive HEAD: e0b0d1c1762ee8aa4b28c62282a2225103e594eb`. Current archive rerun: `archive HEAD: 9b8c1a72d0e462bdfc52a0d0790638513ba5d3e2`.

The standalone probe differences are precisely the documented host boundary: the five HTTP checks `R06`–`R10` skipped after `RT_BIND=refused PermissionDenied`; all other probe lines matched.

The 20 passing checks are two hashes, one sole-change diff, 13 line clauses, two probe outcomes, and two probe byte comparisons. The three unmet checks are the archive rerun, the archive byte comparison, and the missing prerepair script-byte baseline.

## Evidence script comparison

The prerepair snapshot mtime is 2026-09-27T16:12:05-0700. All five evidence-script mtimes precede it. Sizes, mtimes, and SHA-256 hashes were identical before and after my reruns:

| Script | Size (bytes) | mtime (local) | SHA-256 |
|---|---:|---|---|
| `r84-archive-rerun.sh` | 1083 | 2026-09-25 11:42:39 | `3bba3e2b008c5dfa139cf4ff0c2b3c85082ca61a0716ef4c47593d6c603f40f7` |
| `r84-openapi-to-rust-probe.sh` | 23499 | 2026-09-26 19:40:53 | `8996655e48180e3ba35e3273c4a59bf6fdce9b6f05a09b9c919b04e727f6faa9` |
| `r84-progenitor-probe.sh` | 5162 | 2026-09-25 09:10:40 | `b89ff53371954617d7858628486e091b051f0d6fc0598a31f71db5d2fd273055` |
| `r84-registry-figures.sh` | 16181 | 2026-09-26 13:24:42 | `6552c64251063f6a339abf24b228a3c0afa35f2388cb2faea6722d813942ec25` |
| `r84-source-claims.sh` | 22116 | 2026-09-26 19:41:23 | `b4fb4abc1af8b6a0df762e6482a18cde9f0fe316b211fc6ea597d7b0742d8275` |

No prerepair listing with script byte hashes was present in the supplied snapshot or checklist. Thus the stronger byte-for-byte comparison against a prerepair listing cannot be completed. The earlier mtimes and stable hashes support, but do not prove, pre-repair byte identity. Because no changed script bytes were found during this verification, shellcheck was not rerun.

## Unresolved disputes: verbatim rerun output

The following lines are copied verbatim from my archive rerun. They are outside the permitted loopback-host change. The omitted archive diff lines include the corresponding installed PASS lines; the complete rerun is in `/tmp/r84-codex-r5vo.nRkrCH/r84-archive-rerun.log`.

```text
2026-09-27 19:29:55.318 xcodebuild[84751:1041068881]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-27 19:29:55.697 xcodebuild[84751:1041068879] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
archive HEAD: 9b8c1a72d0e462bdfc52a0d0790638513ba5d3e2
r84-source-claims: rc=0 DIFFERS
> curl: (6) Could not resolve host: static.crates.io
> SKIP  D01 progenitor-impl 0.15.0 could not be fetched from static.crates.io
> SKIP  D02 progenitor-impl 0.15.0 could not be fetched from static.crates.io
> SKIP  D03 progenitor-impl 0.15.0 could not be fetched from static.crates.io
> SKIP  D04 progenitor-impl 0.15.0 could not be fetched from static.crates.io
> curl: (6) Could not resolve host: static.crates.io
> SKIP  D05 cargo-progenitor 0.15.0 could not be fetched
> SKIP  D06 cargo-progenitor 0.15.0 could not be fetched
> curl: (6) Could not resolve host: static.crates.io
> SKIP  D07 utoipa 5.5.0 could not be fetched
> SKIP  D08 utoipa 5.5.0 could not be fetched
> curl: (6) Could not resolve host: static.crates.io
> SKIP  D16 utoipa 6.0.0 could not be fetched
> SKIP  D17 utoipa 6.0.0 could not be fetched
> curl: (6) Could not resolve host: static.crates.io
> SKIP  D09 openapi-to-rust 0.17.0 could not be fetched
> SKIP  D10 openapi-to-rust 0.17.0 could not be fetched
> SKIP  D11 openapi-to-rust 0.17.0 could not be fetched
> SKIP  D12 openapi-to-rust 0.17.0 could not be fetched
> SKIP  D13 openapi-to-rust 0.17.0 could not be fetched
> SKIP  D14 openapi-to-rust 0.17.0 could not be fetched
> SKIP  D15 openapi-to-rust 0.17.0 could not be fetched
> curl: (6) Could not resolve host: raw.githubusercontent.com
> SKIP  E01 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E02 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E03 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E04 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E05 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E06 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E07 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
> SKIP  E08 OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com
< PASS=60 FAIL=0 SKIP=0 TOTAL=60
> PASS=35 FAIL=0 SKIP=25 TOTAL=60
> SKIP  R06 end-to-end typed 200 — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run
> SKIP  R07 R12.7 problem+json 404 — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run
> SKIP  R08 R12.7 non-problem 404 — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run
> SKIP  R09 R12.6 Accept header — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run
> SKIP  R10 R12.3 caller deadline — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run
< PASS=36 FAIL=0 SKIP=0 TOTAL=36
> PASS=31 FAIL=0 SKIP=5 TOTAL=36
r84-registry-figures: rc=0 DIFFERS
> retrieval date (UTC): 2026-09-28
> SKIP  F01-F12 crates.io figures — crates.io API unreachable
> SKIP  RS01-RS06 rustsec.org unreachable (control atty.html answered None)
> SKIP  M01 Maven Central is unreachable from this host, so OpenAPI Generator 7.25.0 could not be downloaded or executed here
> SKIP  CB01 doc.rust-lang.org unreachable
> SKIP  G01-G09 gh is absent or unauthenticated, so api.github.com figures were not collected
< PASS=31 FAIL=0 SKIP=0 TOTAL=31
> PASS=0 FAIL=0 SKIP=5 TOTAL=5
```

The recorded `HEAD` changed from the installed archive log, and DNS failures caused source and registry checks to skip. The archive log therefore cannot transfer as a matching rerun under the stated host rule.
