actor: codex
model: gpt-6
family: openai
decision-sha256: f94148730f1a4d476de7f72a1cda265be2ccd64431ff33aa63ac53d32fd710b1
verdict: approve
unresolved-findings: none

# R86 revision 2 empirical re-run

The required `shasum -a 256` gate matched before any other work and again before this audit was written. The seat policy is cited at the supplied point in time: `research/EXECUTION.json` sha256 `fd746cb86e54`. This audit applies the Q23 outcome bar and reports execution truth only.

## Re-runs and byte comparisons

The committed-snapshot `check.sh` rerun wrote only `/tmp/r86-codex-r2-check.log`. It exited 0 with `passed=173 failures=0 skipped=0 total=173`. `cmp` found it byte-identical to both `review/evidence/check.log` and `review/evidence/check-rerun.log`; each hashes to `65613630a960f8546bed3256c4e0e3ffc77e5bbeda8110c354c12d9046b1fdb0`. The committed `check-archive.log` differs from `check.log` only at line 2, the `evidence dir:` extraction path, as the decision states at lines 1377–1384. The shim-first and Homebrew-first `PATH` reruns each exited 0 and were byte-identical to `check.log`. `shellcheck check.sh fetch.sh` exited 0 with no diagnostics; `shellcheck --version` reports 0.11.0.

I copied `review/evidence/` to `/tmp`, ran `fetch.sh` there, and kept every fetched output in that scratch copy. The script exited 0 and printed `snapshots refreshed at Sun Sep 27 22:54:26 UTC 2026`. It has no committed fetch log to byte-compare. Of 45 snapshot files, 29 remain byte-identical and 16 changed; none is missing or extra. I copied the run's `raw/` and `doxa/` directories into a scratch run layout so the `N` checks could execute without writing to the repository. `check.sh` against the freshly fetched snapshots exited 1 with `passed=167 failures=6 skipped=0 total=173`. Those six failures are exactly P03, P05, and A05–A08, which revision 2 names at lines 1413–1417.

## Findings and revision-note repairs

- **OBS 1 — P03/P05 retrieval-date drift; repair holds.** The fresh check says `expected '0.154.0', got '0.157.1'` for both npm `dist-tags.latest` assertions. The decision says at lines 1413–1419: “they are expected to FAIL on a refetch once the figures move” and “The CLI pin does not depend on `0.154.0` staying `latest`.” Its `### Compatibility` text at lines 1144–1151 and `## Engines` text at lines 1551–1561 date the `latest` observation to 2026-09-17. P04 still confirms `0.154.0` was published for the CLI, and P06 still confirms the proxy publishes `0.154.0`; the two current `latest` values remain equal. This is the revision note's finding 1, repaired as claimed at line 7.
- **OBS 2 — toolchain provenance; repair holds.** The decision now says at lines 1315–1319: “Four lines appear in no committed log. They were recorded by hand in revision 1 ... and cannot be re-checked against any artifact.” The five stated header lines match `check.log` lines 4–8; `rustc`, `cargo`, `gh`, and `shellcheck` do not occur in the committed check logs. The revision-2 ShellCheck version and clean execution match lines 1336–1337 and 1351–1352. This is the revision note's finding 2, repaired as claimed at line 8.
- **OBS 3 — A05–A08 retrieval-date drift; repair holds.** The fresh check reports 38 open issues versus 37, 44 open pull requests versus 43, `open_issues_count` 82 versus 80, and `pushed_at` `2026-09-19T01:29:33Z` versus `2026-09-11T00:26:35Z`. The decision dates the review-member table at lines 524–526 and the assistant-member figures at lines 880–887 to 2026-09-17. It says at lines 1420–1423 that the load-bearing relationships are the count sum and a push after the `v1.12` tag. Current values still satisfy `38 + 44 = 82`, and the push remains after `2026-08-20T23:40:26Z`. This is the revision note's finding 3, repaired as claimed at line 9.
- **OBS 4 — actionlint path; repair holds.** `check.sh:43` says `ACTIONLINT=/opt/homebrew/bin/actionlint`; lines 135–136 print that path, and lines 476 and 486 use it. The default, shim-first, and Homebrew-first `PATH` reruns all matched `check.log` byte for byte. The decision's line 10 and lines 1387–1401 accurately describe this repair and the retained archive-log comparison rule.

No observed delta contradicts a load-bearing claim. There are zero BLOCKING findings, so the Q23 verdict is `approve`.
