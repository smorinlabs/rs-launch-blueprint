actor: audit-claude-2026-09-18T215916Z-b7f3ee4b098e-r2
model: claude-opus-5-5
family: anthropic
decision-sha256: f762b4fc7bd7a809ada27bf61fa474b32c968551a78d8be631453ab89e5e6551
verdict: reject
unresolved-findings:
- EA-1 (failed claim: revision-2 header, "The recommendation, the version pin, every check identifier, and the evidence scripts, logs and snapshots are unchanged." Evidence: `review/evidence/r84-registry-figures.sh` Maven Central block carries the comment "Timeout 60, not the 25 this line carried at r1: the endpoint answers in 10-16 s (measured 2026-09-26) … Three attempts"; the committed `r84-registry-figures.log` reads `retrieval date (UTC): 2026-09-26`; `snapshots/registry-figures.json` has `"retrieved": "2026-09-26"`; the script, the log and both snapshot files have 2026-09-26 mtimes, after revision 1. So the script changed, and the log and snapshots were regenerated after r1. Repair: have the header name the regenerated script, log and snapshots and say what changed (the M01 timeout and retries; figures re-retrieved 2026-09-26), or restore the r1 artifacts.)
- EA-2 (failed claim: three passages say Maven Central was unreachable: the G4 cell "Not executed here: Maven Central was unreachable (`M01`)"; the maintenance line "(Opus, Maven `last-modified`; not re-fetched, `M01`)"; and `## Engines`, "because Maven Central was unreachable here (`M01`)". Evidence: the committed log and this audit's rerun both print `PASS  M01 Maven Central is reachable from this host (openapi-generator-cli maven-metadata.xml)`. The decision's own "What this check does not prove" item (3) says `M01` verifies reachability, so the document contradicts itself. Repair: restate all three passages to match M01 = reachable. Say that the generator was still not downloaded or executed here and give the actual reason; the Opus runs remain carried.)
- EA-3 (failed claim: "**Retrieval dates.** **2026-09-25 (UTC)** for everything this decision checked itself". Evidence: the registry, RustSec, GitHub and Cargo Book figures in the committed log and snapshot were retrieved 2026-09-26 (EA-1). Repair: state 2026-09-26 for the `r84-registry-figures.sh` facts, or give per-script dates.)
- EA-4 (failed claim: several figures attributed to `snapshots/registry-figures.json` / "snapshot" do not match the committed snapshot. (i) G6/maintenance: "4, filed by one user on 2026-09-19, are open six days later"; the committed snapshot has `"closed": 10`, and #77–#80 are closed after 6.71–6.72 days; the median 0.49 days for the other 6 still reproduces (0.13, 0.22, 0.46, 0.51, 1.04, 1.85). (ii) "pushed 2026-09-25" for openapi-to-rust; snapshot `2026-09-26T14:33:40Z`. (iii) progenitor "pushed 2026-09-19"; snapshot `2026-09-26T15:17:43Z`. (iv) Shortlist "Last release 0.17.0, 2026-09-14"; snapshot `newest_non_yanked` = `0.19.0`, `2026-09-26T14:29:43Z`. (v) Downloads 45,469 / 46,127; snapshot 45,927 / 46,592. OpenAPI Generator stars 26,762; snapshot 26,763. Volatile drift alone would not be a finding. Here the decision's cited evidence file was regenerated and now contradicts the text. Repair: re-quote every snapshot-attributed figure from the committed snapshot, with its retrieval date, or restore the snapshot the text was written from.)
- EA-5 (failed claim: the pin is presented as current, "version range `>= 0.17.0, < 0.18.0`", and re-verify trigger 3 is treated as a future event: "shows a newest non-yanked `num` of `0.18.0` or later". Evidence: crates.io `/api/v1/crates/openapi-to-rust/versions`, queried 2026-09-26 by this audit, lists `0.18.0` created `2026-09-25T20:29:21Z` and `0.19.0` created `2026-09-26T14:29:43Z`, both non-yanked. The committed snapshot records `0.19.0` as newest. Trigger 3 had therefore fired before revision 2 was written, and the decision does not acknowledge it. Repair: record trigger 3 as fired and rerun `r84-openapi-to-rust-probe.sh` with `TOOL_VERSION` at the newest release, or state explicitly why the 0.17.0 evidence still stands and when the rerun happens. This audit does not judge whether the pin itself should move.)

# R84 empirical audit, revision 2

## Scope and mode

- Scope: execution truth and evidence support only. The recommendation's merit is not judged.
- Seat: Claude seat, used as the approved empirical fallback while the OpenAI provider is quota-paused (method amendment Q8.B). This is not a Codex audit.
- Blindness: `review/audit-fable.md`, `review/audit-claude.md`, `review/R84-r1-snapshot.md` and `research/topics/84-*/raw/` were not opened.
- Evidence snapshots: `review/evidence/snapshots/*` were read. They are the decision's own cited evidence, not prior decisions or prior audits. Every figure taken from them was also re-derived at source.
- Writes: none to git. The only file written in the repository tree is this audit file.
- Host: Darwin arm64; `rustc 1.98.1`, `cargo 1.98.1`, rustup `1.96.0`, `just 1.57.0`, `shellcheck 0.11.0`.
- Run time: 2026-09-26, 19:25–20:10 UTC.

## Integrity

- Measured sha256 of `DECISION.md`: `f762b4fc7bd7a809ada27bf61fa474b32c968551a78d8be631453ab89e5e6551`.
  - It equals the expected value. It was measured before the file was read, and again at the end with the same result.
- Evidence files: the sha256 of all 13 files under `review/evidence/` was recorded before and after all runs.
  - Every hash is identical before and after, so no evidence file was modified.

## Deviation from the literal "run in place"

The scripts were not executed inside the repository tree. Running them there would overwrite committed evidence, for two reasons:

- `r84-openapi-to-rust-probe.sh` runs `: > "$SNAP"`, which truncates `snapshots/openapi-to-rust-timings.txt`.
- `r84-registry-figures.sh` runs `json.dump(snap, open(os.environ["R84_SNAPSHOT"], "w"))`, which overwrites `snapshots/registry-figures.json`.

Instead, the four evidence scripts ran from `/tmp/r84-audit-r2/mirror`.
- The mirror is an `rsync -a --exclude .git --max-size=1m` copy of the working tree.
- It keeps the same relative layout, so `ROOT`, `RUN` and `HERE` resolve exactly as they do in place.
- Environment: `R84_CACHE=/tmp/r84-audit-r2/cache` and `CARGO_HOME=/tmp/r84-audit-r2/cache/cargo-home`. Both were fresh, so the tool was installed from scratch.
- A14 census cross-check: the census was also run read-only against the real worktree, with `rg -uuu -l -F 'OVERRIDE (OV-11)' research/topics research/runs` excluding `research/runs/R84/`. It found no other holder, which matches the mirror's result.

`r84-archive-rerun.sh` ran from the real evidence directory, because it needs `git archive HEAD`.
- It writes only inside its own `mktemp -d` directory, with `TMPDIR=/tmp/r84-audit-r2`.
- Its stdout went to `/tmp`.

## shellcheck

All five scripts exit 0 with no finding under `shellcheck 0.11.0`. This confirms the decision's claim.

## Rerun table

| Script | Run | Pass | Fail | Skip | Exit code | `cmp` against the committed log |
|---|---:|---:|---:|---:|---:|---|
| `r84-source-claims.sh` | 60 | 60 | 0 | 0 | 0 | IDENTICAL |
| `r84-openapi-to-rust-probe.sh` | 36 | 31 | 0 | 5 | 0 | IDENTICAL |
| `r84-progenitor-probe.sh` | 6 | 6 | 0 | 0 | 0 | IDENTICAL |
| `r84-registry-figures.sh` | 31 | 31 | 0 | 0 | 0 | IDENTICAL (both logs dated 2026-09-26) |
| `r84-archive-rerun.sh` with the four script names | 4 legs | — | — | — | 0 | IDENTICAL to the committed `r84-archive-rerun.log` |

Total: 133 checks; 128 PASS, 0 FAIL, 5 SKIP. All five logs are byte-identical to the committed logs.

The 5 SKIPs are `R06`–`R10`, the HTTP half of the probe. This host also refused the loopback bind (`RT_BIND=refused PermissionDenied`), so those checks could not run here either. AC8 therefore stays unexecuted.

## Clean-extraction procedure

`git archive HEAD` was extracted at `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`, and the untracked scripts and fixture were copied in at their relative paths.

- `r84-openapi-to-rust-probe`, `r84-progenitor-probe` and `r84-registry-figures` produced logs IDENTICAL to the committed ones.
- `r84-source-claims` DIFFERS only at `A13`, which is PASS in the worktree and SKIP in the extraction, and at the summary line, which reads `PASS=59 … SKIP=1`.
  - This is exactly what the decision describes.
  - Cause: HEAD's `execution-ledger.md` lacks the 2026-09-21 OV-11 allocation line, which is uncommitted working-tree content.
- The committed `r84-archive-rerun.log` has an earlier mtime than the regenerated registry log. Even so, a fresh run today reproduces it byte for byte.
  - The "three of four identical" claim therefore holds for the committed artifacts, so this is not a finding.

## Figures re-derived at source (2026-09-26)

| Claim in the decision | Source queried | Re-derived value | Status |
|---|---|---|---|
| openapi-to-rust 0.17.0: rust_version 1.88.0, MIT, 2026-09-14; sha256 `ab34bc79…` | crates.io; static.crates.io `.crate` | same; sha256 `ab34bc7990a6…e252f1` | supported |
| 33 live versions 2026-02-13 → 2026-09-14 | crates.io `/versions` | 33 in the window; 35 live in total | supported |
| 0 reverse dependencies; 37 stars | crates.io; GitHub | 0; 37 | supported |
| Last release 0.17.0 (2026-09-14); trigger 3 not yet fired | crates.io `/versions` | 0.18.0 at 2026-09-25T20:29Z; 0.19.0 at 2026-09-26T14:29Z | **contradicted** (EA-4, EA-5) |
| 90-day / all-time downloads 45,469 / 46,127 | crates.io | 45,945 / 46,601 | drifted, and the committed snapshot disagrees (EA-4) |
| G6: 6 closed, median 0.49 days; 4 open; 0 maintainer comments | GitHub search plus comments | 10 closed; the median of the 6 is 0.485; 0 maintainer comments | partly contradicted (EA-4) |
| pushed_at: openapi-to-rust 09-25, progenitor 09-19, OpenAPI Generator 09-25 | GitHub | 09-26, 09-26, 09-25 | 2 of 3 contradicted (EA-4) |
| progenitor #762 and #1268 open and about 3.1 | GitHub | open; titles match | supported |
| Rust stable 1.98.1, published 2026-09-03 (G08) | GitHub releases | `1.98.1`, `2026-09-03T13:14:07Z` | supported |
| utoipa 6.0.0, published 2026-09-22; spargen 0.5.0 on 2026-09-24 | crates.io | same | supported |
| meteora-api: 20 downloads; generated by v0.12.2 | crates.io; `.crate` | 20; 20 files carry the marker | supported |
| RustSec: no page for openapi-to-rust, reqwest or reqwest-middleware | rustsec.org, checked against the atty control | 404 for each, 200 for the control | supported |
| M01: Maven Central unreachable (three passages) | repo1.maven.org | reachable (PASS) | **contradicted** (EA-2) |
| R4.1 `:742-747`, R4.2 `:754-755`, R5.12 `:1019-1021`, R1.7 `:272-273`, §12 `:1767`, R12.6 `:1815-1817`, R12.7 `:1819-1823` | `rest-api-standard.md` at `0850d43e` | each line range holds the quoted text | supported |
| `client_generator.rs:1436-1447` skips a caller-supplied `accept` header and sets `ACCEPT` | the 0.17.0 `.crate` | lines 1436–1446 show exactly that | supported |
| COMMONALITY:339 F335; py WEB-60 `0002-web-api-conventions.md:86`, `EXAMPLEWEB.md:138`; R69 r10 `DECISION.md:1791` | the files and the py pin `b08bccfb` | quoted text present | supported |
| G6 timings: 21 s stable, 16 s on 1.96.0, from the committed timings file | `snapshots/openapi-to-rust-timings.txt` | the file says 21 s and 16 s; this audit's fresh run measured 18 s and 17 s | quote supported |
| About 75 s for a first from-source install | fresh-cache rerun | 76 s | supported by rerun; the committed timings file has no install line |

## Summary

- Execution truth: all five scripts reproduce byte for byte. The recipe, the section-12 static checks, the progenitor refusals and the source claims are all supported.
- Evidence support: five unresolved findings, EA-1 through EA-5. Each is a prose claim contradicted by the committed regenerated evidence or by the registry.
- EA-1 through EA-4 are prose repairs. EA-5 needs either a probe rerun at the newest openapi-to-rust release or an explicit statement of why the 0.17.0 evidence still stands.
