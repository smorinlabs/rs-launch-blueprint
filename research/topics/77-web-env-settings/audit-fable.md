actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: a3c2dc6ca904b80f8e565f9ad0999cb3a0ab3f78f5d0f9e8d53c1b9d97765b55
verdict: approve
unresolved-findings: none

# R77 revision 5 — directed verification of the round-2 repairs (fable, judgment side)

Target: `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md`, revision 5.
The first step was `shasum -a 256`, which returned
`a3c2dc6ca904b80f8e565f9ad0999cb3a0ab3f78f5d0f9e8d53c1b9d97765b55`. That equals the expected
value. Date: 2026-09-27 (UTC).

**Scope.** This audit is directed. It confirms or disputes each enumerated repair and does
not search for new findings. Anything outside the enumerated repairs is recorded as an
observation, never as a finding.

**Read.** `review/audit-claude.r4.md` and `review/audit-fable.r4.md` (the enumerated
repairs); `review/R77-r4-snapshot.md`, diffed against the new `DECISION.md`;
`review/evidence/r4-checks.sh` and `r4-checks.log`; `rest-conformance-r2.log`;
`ov-allocation-r3.log`; `probes.log`, `probes-r4.log` and `probes-rerun-r4.log` at the loci
E1 names; and the live R74 file
`research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md`.
**Not read, as forbidden:** `audit-claude.md`, `audit-fable.md`, `audit-fable.r1.md` and
`R77-r3-snapshot.md`. No script was run. No git command, runner command or paid API was
used.

## Diff review: the recommendation is unmoved

`diff R77-r4-snapshot.md DECISION.md` gives exactly these hunks:
- the H1 and the new top note with its table (lines 1–25);
- the revision-history roll (97–101);
- the field-count paragraph (796–800);
- Move 2 item 1 (975–977);
- AC14 (1078);
- the re-verify line (1124);
- the evidence-table row (1218);
- the counts paragraphs (1320–1326 and 1330–1332);
- the reproducibility-rule lead-in (1363–1366) and item 2 (1370–1378).

No hunk touches the recommendation, the Parameters values, the gates or the Engines
adjudication. The recommendation is unchanged: no crate, with template code over
`std::env::vars_os` and `str::FromStr`.

## Per-repair confirmation

| Repair | Result | Evidence |
|---|---|---|
| **E1** (claude r4) | **confirmed** | Item 2 at lines 1370–1378 names `probes.log`, `probes-r4.log` and `probes-rerun-r4.log`. It lists the inherited `CARGO_TARGET_DIR` path at all three loci: the `# inherited CARGO_TARGET_DIR:` header, the `## run 1` header and cargo's `Running …` line. It also lists the order of cargo's `test … ok` lines under parallel execution. The loci exist as described: `probes-r4.log:3` is `# inherited CARGO_TARGET_DIR: /tmp/cargo-s27-R77-r4-target`; `probes-rerun-r4.log:4` is `## run 1 — as written, CARGO_TARGET_DIR=/tmp/cargo-s27-R77-r4b-target`; `probes-rerun-r4.log:72` is the `Running tests/settings.rs (/tmp/cargo-s27-R77-r4b-target/…)` line. The lead-in at 1363–1366 says "as revision 5 states it" and credits `review/audit-claude.r4.md`, E1. Per the diff, no script or figure changed for E1. |
| **F1** (fable r4 1) | **confirmed** | The field-count paragraph (796–800) reads "revision 2" and gives sha256 `68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246`, members `:511-513`, the argument at `:515` and the hand-off at `:560`. Move 2 item 1 (975–977), AC14 (1078) and the re-verify line (1124) all say revision 2. `r4-checks.sh` lines 289–296 hold group C's R74 block: a pin to `68e19cf3…`, members at lines 511, 512 and 513, OV-17 at 515, and the three-field hand-off at 560. That is six checks. The revision-1 floor check is gone, and there is no title check. **Live R74 has not drifted.** It recomputes to `68e19cf3…`. Its H1 says revision 2. Lines 511–513 hold `RSLBP_WEB_RATE_LIMIT_PER_IP`, `_PER_IP_BURST` and `_MAX_ENTRIES`, which match AC14's member list. Line 515 contains "`OVERRIDE (OV-17)` ships one dimension". Line 560 contains "Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family". `r4-checks.log:168-173` records the same six checks as PASS. |
| **F2** (fable r4 2) | **confirmed** | The counts block (1320–1326) says `rest-conformance-r2.sh` **PASS=91 FAIL=0 SKIP=0**, and the total is **373 checks, 373 PASS, 0 FAIL, 0 SKIP**, which is 239 + 91 + 43 = 373. It attributes the 90/1/0 rerun to `ov-allocation-r3.log`. The committed `rest-conformance-r2.log` ends `PASS=91 FAIL=0 SKIP=0 TOTAL=91`. `ov-allocation-r3.log:41` reads "now 90/1/0 against a revision-3 title (PASS=90 FAIL=1 SKIP=0 TOTAL=91)". The evidence-table row for this script, which was line 1181 in revision 4, still says "(the revision-2 run, 91/0/0)". All three sources agree. |
| **Revision roll and knock-on figures** | **confirmed** | Line 1 says "revision 5". The top note lines explain the three repairs and the `r4-checks.sh` rerun, and line 22 gives **PASS=184 FAIL=1 SKIP=0**, exit **1**. The revision-history paragraph (97–101) calls revision 5 "this file" and demotes revision 4 with sha256 `7e0cc569…`. Row 1218 and counts line 1332 both say 184/1/0 at revision 5 and 186/0/0 at revision 4. The committed `r4-checks.log` agrees. Its header records decision sha256 `a3c2dc6c…`, which is this file. Its totals line is `PASS=184 FAIL=1 SKIP=0 TOTAL=185`, which is 186 minus the dropped floor check. The only FAIL is `H1 names revision 4 (line 1)`, the title check that fails by design. The F5 checks at `r4-checks.log:71-72` pass: "only revision 5 is called 'this file'" and "the one 'this file' label is revision 5's". |

## Observations (not findings)

- **O1: the top note runs to line 25, not line 23.** The paragraph about `r4-checks.sh`
  ends at line 25 ("No other script was edited or rerun."). The line range in the
  controller's brief is off by two lines. The content is as described.
- **O2: the script still labels itself as revision 4.** The `r4-checks.sh` header comment
  (line 4) and its printed header line (line 70) still say "revision 4". This matches the
  script's name and role and is cosmetic.
- **O3: R74's reverse pin is now stale.** R74 revision 2 pins R77 revision 4 by sha256
  `7e0cc569…` at R74 `:315-317`. R77 revision 5 has a different sha, so that citation in
  R74 needs a re-pin. That repair belongs to R74, and the audit of R74 revision 4 already
  flagged it for the controller to sequence.
