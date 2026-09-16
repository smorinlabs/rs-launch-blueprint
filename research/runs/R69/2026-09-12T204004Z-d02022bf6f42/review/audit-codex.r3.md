decision-sha256: a9eec9bd3cc3631d61f395f470e0b15a389746f9e26e26a5b2b32a9fc9a7e98f
actor: audit-codex-2026-09-12T204004Z-d02022bf6f42-r3
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: check 2's byte-identical reproduction conditions omit cargo-audit's cached crates.io index lock state

## Rerun

- argv: `bash review/empirical/{state-bound-check,assert-figures,issue-responsiveness,bacon-install-check,parameters-check}.sh`; `bash /private/tmp/r69-audit-r3/inplace/evidence/feature-shape-check-r3.sh`; the latter was copied with its two probe inputs before execution. It was then run twice more, once from a clean `git archive HEAD` extraction, once with the advisory remote unavailable, once with the recorded failed-shape mutation, and once with a forced pinned-hash mismatch.
- cwd: the run directory for the five unchanged checks; `/private/tmp/r69-audit-r3/inplace` for the three normal check-2 runs; and `/private/tmp/r69-audit-r3/archive` for the archive run. Toolchain: `rustc 1.98.0`, `cargo 1.98.0`, `cargo-audit-audit 0.22.1`, Darwin arm64 / macOS 26.4.
- exit code: all six normal checks were `0`; the three normal check-2 runs and the archive run were byte-identical to one another; unavailable pinned DB gave the named SKIP and `0`; the recorded bad-shape mutation printed the SKIP and exited `1`; the forced pinned-hash mismatch printed `FAIL`, set `rc_audit=1`, and exited `1`.
- log path: `review/evidence/audit-{state-bound-check,assert-figures,issue-responsiveness,bacon-install-check,parameters-check,feature-shape-check-r3-*}.log`.
- output matches the decision: no. The normal and archive check-2 logs have SHA-256 `e46c8b4a2df92daaec54bfd8a0c3e56cf045f830f7b57f0a9ff4321885ccf65a`, not the cited log's `ab19d0cb482bc52bc0ab929c952320d245401080ca546139ce01d4746b34ecdd`.

## Findings

1. **Reject — the repaired check is still not byte-reproducible under the decision's stated conditions.** Each successful rerun inserted `warning: couldn't open crates.io index: I/O operation failed: failed to obtain lock file '/Users/stevemorin/.cargo/.package-cache'` after `Loaded 1243 security advisories`; `diff -u review/evidence/feature-shape-check-r3.log review/evidence/audit-feature-shape-check-r3-inplace-1.log` shows this sole difference. The decision names a *missing* cached index as the warning condition, but the observed cause is an unavailable package-cache lock on a machine that has the cache. Cargo-audit 0.22.1's `src/auditor.rs:115-167` takes the same `CachedIndex::open` branch for `--no-fetch` and warns on any open failure, including a lock failure. Its stated conditions for cited-log identity must include a readable, unlocked cached crates.io index (or the claim must be narrowed to the deterministic feature-shape sections); otherwise its claim that the two named variations are exhaustive is false.
2. The advisory-database repair itself works. The script fetched and asserted `b50980aad8b8f14f77e25a97b32dd94bf008b0af` outside the run, used `cargo audit --db <clone> --no-fetch --stale`, loaded exactly 1,243 advisories, scanned exactly 55 crate dependencies, and exercised a count assertion that rejects 99,999. It leaves no gitlink: `git ls-files -s | /usr/bin/grep 160000` produced no matches. The 52 count remains correctly confined to section 9's other probe.
3. The scoped controls hold: unreachable DB plus `R69_NO_LOCAL_MIRROR=1` emitted `SKIP: advisory-scan-skipped-pinned-db-unavailable` with `rc_shape=0` and exit `0`; the bad `axum v9.9.9` assertion emitted that same SKIP with `rc_shape=1` and exit `1`; the local-mirror fallback exited `0`; and the forced hash mismatch exited `1`, not SKIP.
4. The five unchanged checks reran with exit `0` and byte-identical logs: state bound, figures, issue responsiveness, bacon install, and parameters. `parameters-check-r2.log` matches its rerun exactly; the revision-2-to-HEAD diff of the five scripts/logs, retained revision-1 feature-shape script/log, and the five `- assumes` plus one `- owns` lines is empty. Five cited upstream URLs also returned HTTP 200 by curl.

## Assessment

Revision 3 fixes the mutable advisory-database input, separates SKIP from feature-shape failure, and accurately retains the other evidence. It nevertheless asserts byte-identical cited-log reproduction under conditions that do not cover the cached-index lock which its own cargo-audit source branch can emit. This is a decision-changing empirical overclaim; add that condition or stop claiming full-log byte identity before acceptance.
