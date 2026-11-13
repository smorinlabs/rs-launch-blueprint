actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b
verdict: reject
unresolved-findings:
  1. EF-r5-1 — the probe logs do not reproduce on a host that allows loopback binds (see below)

# R84 — empirical audit of DECISION.md revision 5

Seat: empirical auditor (fresh context; independent of the synthesizer and the judgment
auditor). Scope: execution truth and evidence support only. No `review/audit-*.md`, no
`review/R84-r*-snapshot.md` and no topic `raw/` file was read. No git write, no runner
command, and no paid or submitting API was used. Nothing under `review/evidence/` was written.

## 1. Target identity

```
$ shasum -a 256 research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/DECISION.md
4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b
```

This matches the expected revision-5 hash. Repository HEAD was `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`,
the same commit the decision's archive leg names.

## 2. Host and toolchain

`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`,
`Darwin arm64`. The environment set a private `CARGO_HOME=/tmp/cargo-s31-r84-emp` and
`CARGO_TARGET_DIR=/tmp/cargo-s31-r84-emp-target`. `TMPDIR=/tmp/r84-emp-r5`, and all output
went there. The tool cache was fresh (`R84_CACHE=/tmp/r84-emp-r5/cache`, and
`/tmp/r84-emp-r5/cache-0.19.0` for the `0.19.0` leg). No binary was reused from the
synthesizer. **Unlike the synthesizer's shell, this shell allows loopback TCP binds.**

## 3. Commands (the decision's own rerun block, with a fresh cache)

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
E=research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/evidence
O=/tmp/r84-emp-r5; export TMPDIR=$O
for s in r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures; do
  shellcheck "$E/$s.sh"
  R84_CACHE="$O/cache" R84_TIMINGS="$O/timings.txt" R84_SNAPSHOT="$O/registry-figures.json" "$E/$s.sh" > "$O/$s.log" 2>&1
done
shellcheck "$E/r84-archive-rerun.sh"
"$E/r84-archive-rerun.sh" r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures > "$O/r84-archive-rerun.log" 2>&1
TOOL_VERSION=0.19.0 R84_CACHE="$O/cache-0.19.0" R84_TIMINGS="$O/probe-0.19.0-timings.txt" "$E/r84-openapi-to-rust-probe.sh" > "$O/r84-openapi-to-rust-probe-0.19.0.log" 2>&1
# then: cmp "$E/<name>.log" "$O/<name>.log"; diff on mismatch
```

`shellcheck` exited 0 on all five scripts. Every script exited 0.

## 4. Results

| Script (paired log) | Exit | Fresh Pass / Fail / Skip | Committed P/F/S | `cmp` against the committed log |
|---|---:|---|---|---|
| `r84-source-claims.sh` (`r84-source-claims.log`) | 0 | 60 / 0 / 0 | 60 / 0 / 0 | **IDENTICAL** |
| `r84-openapi-to-rust-probe.sh` (`r84-openapi-to-rust-probe.log`) | 0 | **36 / 0 / 0** | 31 / 0 / 5 | **DIFFERS** at line 60 (EF-r5-1) |
| `r84-progenitor-probe.sh` (`r84-progenitor-probe.log`) | 0 | 6 / 0 / 0 | 6 / 0 / 0 | **IDENTICAL** |
| `r84-registry-figures.sh` (`r84-registry-figures.log`) | 0 | 31 / 0 / 0 | 31 / 0 / 0 | Differs in line 2 only. The decision discloses this line. |
| `r84-archive-rerun.sh` (`r84-archive-rerun.log`) | 0 | n/a | n/a | **DIFFERS** at line 11 (EF-r5-1) |
| probe with `TOOL_VERSION=0.19.0` (non-paired `r84-openapi-to-rust-probe-0.19.0.log`) | 0 | **36 / 0 / 0** | 31 / 0 / 5 | **DIFFERS**. It has the same three hunks as the `0.17.0` log (EF-r5-1) |

The registry difference is the retrieval-date line:

```
2c2
< retrieval date (UTC): 2026-09-26
---
> retrieval date (UTC): 2026-09-27
```

The decision states that the registry rerun "differs only in its UTC-date line." That statement is true, so this line is not a finding.

My archive leg (extracted from HEAD `e0b0d1c1`) reproduced these parts of the committed archive log exactly:

- the `r84-source-claims` hunk, where `A13` reads `PASS` in the working tree and `SKIP` in the extraction, with the summary line `PASS=59 FAIL=0 SKIP=1`;
- `r84-progenitor-probe: rc=0 IDENTICAL`;
- the registry date-only hunk.

It did not reproduce the line `r84-openapi-to-rust-probe: rc=0 IDENTICAL`. See EF-r5-1.

The canonical paired probe log and the extra `r84-openapi-to-rust-probe-0.19.0.log` are both
4,927 bytes. The committed pair differs only in `T01` (`0.17.0` versus `0.19.0`). My fresh
`0.17.0` and `0.19.0` logs also differ from each other only in `T01`. The decision's claim that
`0.19.0` is "behavior-identical" apart from `T01` therefore holds on both hosts.

The section-12 deserialization lines quoted in `## Empirical check` reproduced verbatim:
`DEFAULT_UNKNOWN_FIELD=accepted`, `DEFAULT_UNKNOWN_STATE=rejected unknown variant`
`` `suspended`, expected `active` or `archived` at line 1 column 44 `` and
`RECIPE_UNKNOWN_VALUES=accepted state=Custom("suspended") visibility=Custom("internal")`.

Measured durations (`/tmp/r84-emp-r5/timings.txt`):

- `cargo install openapi-to-rust 0.17.0`: 247 s, with a cold cache;
- clean `cargo check` of the generated client on stable: 36 s;
- clean `cargo check` on 1.96.0: 30 s;
- clean build and run of the section-12 probe on stable: 37 s;
- advisory-db HEAD: `e2111519ba6d14a5da59a7b2e5c8083ae8a37c01`.

Wall-clock times: source-claims took 18 s, the probe 360 s, progenitor 117 s and registry 551 s.

## 5. Figures re-derived at source (public read-only queries, 2026-09-27)

- **`openapi-to-rust` on crates.io** (`/api/v1/crates/openapi-to-rust`):
  - `max_version` is `0.19.0`, created `2026-09-26T14:29:43Z`;
  - `0.18.0` was created `2026-09-25T20:29:21Z`, and `0.17.0` was created `2026-09-14T17:28:43Z`;
  - no version is yanked, and none is later than `0.19.0`, so trigger 3 has not re-opened;
  - the crate has 0 reverse dependencies, which matches `F03`;
  - there are 46,667 all-time downloads. The snapshot of 2026-09-26 cites 46,601. The difference is dated growth, not an error.
- **Snapshot equality.** `snapshots/registry-figures.json` carries the figures the decision cites:
  - 46,601 all-time downloads and 45,945 downloads in 90 days;
  - 37 stars and 0 reverse dependencies;
  - 35 non-yanked versions, the newest being `0.19.0` from `2026-09-26T14:29:43Z`.

  My fresh snapshot had the same stars (37), reverse dependencies (0) and version count (35).
- **GitHub.** `gpu-cli/openapi-to-rust` has `stargazers_count` 37.
- **`progenitor-impl`.** The newest version is `0.15.0`.
- **Re-verify date.** `0.19.0` was created on 2026-09-26. Six months later is 2027-03-26, the date on the
  revision-5 `re-verify:` line and trigger 8's anchor. This arithmetic is correct. Only this
  line changed in revision 5, and no script reads it.

## 6. Finding

### EF-r5-1 — the probe logs are host-dependent, so the committed counts and the "does not prove" item are wrong on a loopback-capable host

**Failed claims (quoted from revision 5):**

- `## Empirical check`: "the log is byte-identical either way".
- Table rows for `r84-openapi-to-rust-probe.sh` and its `TOOL_VERSION=0.19.0` leg: `36 | 31 | 0 | 5`.
- Revision header, lines 16 and 25–26: "pass/fail/skip counts (60/0/0, 31/0/5, 6/0/0, 31/0/0, 31/0/5)".
- Trigger 3 and revision-3 note: "31 PASS, 0 FAIL, 5 SKIP" and "31/0/5, behavior-identical".
- Archive paragraph: "**Two of the four logs are byte-identical**: `r84-openapi-to-rust-probe.log` and `r84-progenitor-probe.log`".
- "What this check does not prove … (2) **The HTTP half** of section 12 (`R06`–`R10`, AC8)".

**Evidence.** On this host both probe legs printed `PASS=36 FAIL=0 SKIP=0 TOTAL=36`. The diff against
`evidence/r84-openapi-to-rust-probe.log` was as follows:

```
60c60,64
<       RT_BIND=refused PermissionDenied
---
>       RT_200=typed id=p1 state=Custom("suspended") visibility=Custom("internal")
>       RT_404_PROBLEM=api status=404 typed_status404=true
>       RT_404_NON_PROBLEM=api status=404 typed_none=true parse_error_some=true body=upstream proxy says no
>       RT_ACCEPT_SENT=application/json
>       RT_CALLER_DEADLINE=elapsed
64,68c68,72
< SKIP  R06 end-to-end typed 200 — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run
  ... (R07–R10 SKIP likewise)
---
> PASS  R06 end to end over HTTP: the 200 body with an unknown field and two unknown values deserializes into the typed Project
> PASS  R07 R12.7 a problem+json 404 is branched on status and parsed into the typed Status404(Problem)
> PASS  R08 R12.7 a text/plain 404 from 'infrastructure' still surfaces as status 404 with the raw body, typed=None, parse_error kept
> PASS  R09 R12.6 DEPARTS (SHOULD): even with a caller-supplied Accept, only 'application/json' reaches the server — OVERRIDE (OV-11)
> PASS  R10 R12.3 is met by the caller: tokio::time::timeout around a call to a never-answering listener elapses
71c75
< PASS=31 FAIL=0 SKIP=5 TOTAL=36
---
> PASS=36 FAIL=0 SKIP=0 TOTAL=36
```

The `0.19.0` log has the same three hunks. My archive run printed
`r84-openapi-to-rust-probe: rc=0 DIFFERS` with the same diff. The committed
`r84-archive-rerun.log` says `IDENTICAL`, so that log does not reproduce either.

**Cause.** The synthesizer's shell refused loopback binds, and this host allows them. The decision
predicted the difference ("They run unchanged wherever loopback binds are allowed"). However, its
counts, its byte-identity claim and its "does not prove" item all describe only the refusing host.

**Effect on the recommendation.** None. The drift is favorable:

- all five HTTP checks pass;
- `RT_ACCEPT_SENT=application/json` is the first executed on-the-wire confirmation of the `OV-11`
  departure, which `R12` had shown only statically;
- `R10` confirms that callers can meet R12.3 with `tokio::time::timeout`.

The reject stands because the committed logs and counts do not reproduce, and execution truth is this seat's scope.

**Repair.**

1. On a loopback-capable host, rerun both probe legs and the archive harness through the documented
   block. Install the 36/0/0 logs as `r84-openapi-to-rust-probe.log` and
   `r84-openapi-to-rust-probe-0.19.0.log`, and install the matching `r84-archive-rerun.log`.
   Alternatively, keep the refused-host logs and add labelled loopback-host logs beside them.
2. Update the table rows, the revision header count lists and trigger 3's "31 PASS, 0 FAIL, 5 SKIP" to state both
   outcomes by host: 31/0/5 where binds are refused and 36/0/0 where they are allowed.
3. Replace "the log is byte-identical either way" with a sentence stating the host dependency.
4. Narrow "does not prove (2)" to Linux. Cite `R06`–`R10` as executed on macOS arm64, and cite `R09`'s
   `RT_ACCEPT_SENT=application/json` as executed evidence for `OV-11`.

## 7. Evidence-tree integrity

After the reruns, `ls -la review/evidence review/evidence/snapshots` showed the same
modification times as before. The four logs were unchanged: `r84-archive-rerun.log` (Sep 26 20:36),
`r84-openapi-to-rust-probe.log` (20:17), `r84-openapi-to-rust-probe-0.19.0.log` (20:20) and
`r84-source-claims.log` (20:17). The progenitor and registry logs and both snapshots were
unchanged at Sep 26 13:49. Every volatile output went to `/tmp/r84-emp-r5`.
