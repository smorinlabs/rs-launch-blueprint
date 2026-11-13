actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 950f53664fe727d3fc7f2ce4790ad62ef2e1eb626a0b9fc97d9f5404c55eafae
verdict: reject
unresolved-findings:
1. EA-1 — OVERRIDE (OV-08) option 2 is claimed to conform literally to R4.17, but its measurement (check `X10`) shows a preflight that emits `allow` without naming it in `Access-Control-Expose-Headers`.
   - Failed claims:
     - DECISION.md:374–375 (Option 2): "check `X10` shows the preflight then lists the headers and still carries `allow` and `request-id`".
     - DECISION.md:872 (X10 row): "OV-08 option 2 conforms literally, measured".
     - DECISION.md:388: "Refusal means P03 adopts option 2, which is already measured, with no re-research."
     - DECISION.md:432–433 (criterion 8): "a preflight from the allowed origin carries the same expose list (check `X10`)".
     - `evidence/rest-conformance-r2.sh:393`, the message of the X10 assertion: "so the preflight then lists allow and request-id literally".
   - Evidence:
     - Fresh rerun, `/tmp/r76a/rest-conformance-r2.log:119`, byte-identical to the committed log: `CHECK X10 status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, access-control-expose-headers=request-id,retry-after,ratelimit, access-control-max-age=600, allow=GET,HEAD, content-length=0, request-id=req_probe, vary=origin}`. The preflight carries `allow`, but the expose list does not name `allow`.
     - R4.17 (blob `71bd813c…`, lines 864–868) requires the list to name "any other §1.10 response header in use".
     - Blob line 351 makes `Allow` a §1.10 reserved response header. DECISION.md:334 itself grounds OV-08 on exactly that fact.
     - Why the assertion still passes: it matches the header dump, not the claim in its own message.
     - The "three-name stand-in" caveat (DECISION.md:1149) does not cover this gap. That caveat is about headers from items that have not landed yet. `allow` is present in the probe, and it is the header that motivated OV-08.
     - Consequence if the owner refuses OV-08: following "no re-research", P03 would ship a stamp that still deviates from R4.17 on preflights.
   - Repair (the synthesizer's choice; this audit does not decide it):
     - Make option 2's preflight list name `allow`, then re-record `X10`. `X11` is unaffected, because the stamp fires only on preflights.
     - One alternative is to add `allow` to the single `exposed_headers` floor beside `request-id`. `405` responses also emit `Allow` under R5.11, so that change would make criterion 8's "same expose list" literally true.
     - Then correct the X10 assertion message, DECISION.md:872 and DECISION.md:374–375.
     - While editing, align Option 2's prose ("any `OPTIONS` response that carries `access-control-allow-origin`", DECISION.md:372–373) with the code in `expose_on_preflight`. The code also requires the `access-control-request-method` request header, which is the correct definition of a preflight. This is a wording fix and does not block on its own.

# R76 revision 3 — empirical audit (claude)

## Identity check

`shasum -a 256 research/runs/R76/2026-09-17T034010Z-d958540e8834/review/DECISION.md`
printed `950f53664fe727d3fc7f2ce4790ad62ef2e1eb626a0b9fc97d9f5404c55eafae`, which equals
the expected hash. Both scripts that read the decision print the same hash in their
headers: `rest-conformance-r2.log:9` and the `decision sha256:` line of
`decision-self-check.log`.

## Reruns

- **Working directory:** `research/runs/R76/2026-09-17T034010Z-d958540e8834/review/evidence/`.
- **Output location:** `/tmp/r76a/`. The committed logs were not touched.
- **Environment:** `rustc 1.98.1` on macOS `arm64`, date 2026-09-27. `CARGO_HOME=/tmp/cargo-s37-R76-emp`.
- **F3 check:** `CARGO_TARGET_DIR=/tmp/cargo-s37-R76-emp-target` was **exported**, and `probe-checks.sh` still passed. That confirms the F3 repair in the condition that exposed it.
- **Order:** the four scripts below ran in sequence, and `rest-conformance-r2.sh` ran last.
- **Comparison:** each fresh log was compared with `cmp` against the committed paired log, then with `diff`.

| # | Command | Exit | PASS / FAIL / SKIP (total) | `cmp` | Differing lines (all of them) |
|---|---|---|---|---|---|
| 1 | `./registry-figures.sh > /tmp/r76a/registry-figures.log` | 0 | 56 / 0 / 0 (56) | differ at line 2 | 1 line: `date(UTC)` header |
| 2 | `./probe-checks.sh > /tmp/r76a/probe-checks.log` | 0 | 29 / 0 / 0 (29) | differ at line 2 | 6 lines: `date(UTC)`; `mktemp` path in the `cargo tree` line (`r76-probe.WeIGVk` → `r76-probe.YLFn7v`); four build-second FIGUREs (see below) |
| 3 | `./muse-adjudication.sh > /tmp/r76a/muse-adjudication.log` | 0 | 27 / 0 / 0 (27) | differ at line 2 | 2 lines: `date(UTC)`; `loco-rs/loco stargazers_count = 9267` → `9268` |
| 4 | `./decision-self-check.sh > /tmp/r76a/decision-self-check.log` | 0 | 73 / 0 / 0 (73) | differ at line 2 | 1 line: `date(UTC)` header |
| 5 | `./rest-conformance-r2.sh > /tmp/r76a/rest-conformance-r2.log` (last) | 0 | 66 / 0 / 0 (66) | differ at line 2 | 18 lines: `date(UTC)`; the 17-line section F OV-namespace snapshot. Every count rose by 2–8, for example `2766 OV-01` → `2769 OV-01` and `84 OV-08` → `92 OV-08` |

**What stayed identical.** Across all five logs:

- Every `ASSERT` line is identical in text and verdict. This was verified with a `diff` of the `^ASSERT` lines only.
- Every `CHECK` line is identical.
- Every stripped-size FIGURE is identical: 502,264 → 668,728 bytes, a delta of +166,464 B.

In section E, `rest-conformance-r2.sh` re-ran the self-check with this result:
`decision-self-check.sh exit=0; ASSERT FAIL lines=0; PASS=73`.

**Why the differences are expected.** Every differing line belongs to a class that
DECISION.md:990–997 declares variable: date headers, a `mktemp` path, build seconds,
point-in-time counters, and the section F snapshot. The loco star count (9,267) is quoted
dated. No differing line is load-bearing.

**Build seconds, reported honestly.** This run recorded 16.5 s and 14.9 s without the
dependency, and 25.8 s and 21.3 s with it. The decision's run recorded 11.5/11.8 s and
11.4/11.7 s. Here the two arms did separate. The decision asserts no compile-time figure,
and it explicitly withdraws any compile-time claim (DECISION.md:217–223), so nothing is
contradicted. The figures only confirm that this host's timing is too noisy to support a
claim in either direction.

## Figures re-derived at source

These checks were run independently of the scripts.

- **REST standard blob** `71bd813c…` in `/Users/stevemorin/c/rest-standards`:
  - The object is a `blob` of 190,161 bytes.
  - R4.17 reads as quoted at lines 864–870.
  - The §1.10 `request-id` row is at line 348, and the `Allow` row ("Mandatory on every `405`") is at line 351.
  - R5.11 is at line 1008 and R11.7 at line 1752.
  - R1.7's "approved exception" clause is at lines 271–275.
- **Repository citations:**
  - `docs/port/COMMONALITY.md:326` is the F322 row: `py-only`, `DIVERGENT`, R76.
  - `docs/port/README.md:71` holds the `DIVERGENT` definition as quoted.
  - `docs/port/OWNER-REVIEW.md:187` carries the W2-REST heading.
- **OV-08 allocation:** commit `69a635ec` (2026-09-18) contains the allocation table with the entry "OV-08 R76". The decision's account of how it got the number is accurate.
- **Engine artifacts:**
  - `raw/muse.md` hashes to `31be2e15…` and is 20,628 bytes.
  - `raw/opus.md` hashes to `c2792a69…`.
  - `inputs/prompt.md` has the same sha256 as the live prompt: `99e9acac…`.
  - The Muse collection gap is confirmed exactly as disclosed: `operations/muse.json` has `state: "submitting"` and `raw_sha256: null`, and the manifest `state` is `"partial"`. The decision names registering the leg as the controller's step, so this is not an unresolved finding against the decision.
- **Upstream sources:**
  - `tower-http` `mod.rs:715` and `:728`–`729` were read from the published `.crate` in section G. Line 728 carries the upstream comment "This header is applied only to non-preflight requests".
  - `rust-lang/crates.io` `Cargo.toml@765bbf47…:168` reads `tower-http = { version = "=0.7.1", …`.
  - The locked tree's maximum `rust-version` is 1.85 (`hyper-util`), which is within the 1.96 floor.

## Controller note (a): sibling pins

Every sibling pin checked resolves now, and none is stale:

- `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` is revision 10. Its line 1791 is the `- owns web-extra-surface` line in the revision-10 `crates/web` form.
- `docs/port/PARAMETERS.md:17` still carries the revision-9 form. That matches the account in DECISION.md:739–753 and the byte-diff in self-check section B.
- The R69 index row reads `resolved`.

## Controller note (b): OV-08's Argument and Options

- **Argument: complete and evidenced.** The three Fetch Standard sentences reproduced live in section G (`FIGURE Living Standard — Last Updated 21 September 2026`), and all three assertions passed. The structural ground was also confirmed at source: `CorsLayer` applies the expose list only on the non-preflight branch.
- **Options: complete in number (three), but option 2 is not evidenced as stated.** See EA-1.
- **Option 3:** correctly rejected on R1.7's own text.
- This audit does not rule on the exception itself.

## Verdict

**Reject.** All five scripts reproduce: exit 0, FAIL=0, SKIP=0, and ASSERT and CHECK lines
identical. Every load-bearing figure re-derived at source matches. The one blocking defect
is EA-1: the measurement offered to the owner as the literal-conformance fallback for
OV-08 does not show literal conformance. The repair is a one-token change to the list,
a re-record of `X10`, and three corrected sentences.
