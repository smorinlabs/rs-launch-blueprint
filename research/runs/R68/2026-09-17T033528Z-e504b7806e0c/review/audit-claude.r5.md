actor: claude
model: gpt-6-astra
family: openai
decision-sha256: 10a6a71bda644a93a8aa667e34a90b11b5c4f890b40366ba23b464ead0010b41
verdict: reject
unresolved-findings:
1. EA5-1 — The explanation of `install-updater` attributes application-binary growth to an option that installs a separate executable.

   **Failed claim:** `DECISION.md:138` says that enabling the updater would add "a self-update surface, a network call and bytes to every shipped binary". The exclusion at lines 330–331 also describes `axoupdater` as "a runtime dependency" without distinguishing the standalone updater from the separately available library integration.

   **Evidence:** The primary documentation at the decision's exact `v0.33.0` tag describes `install-updater` as installing a "standalone updater program alongside your program". The [configuration reference, lines 911–927](https://github.com/axodotdev/cargo-dist/blob/v0.33.0/book/src/reference/config.md#L911-L927), names that executable `yourpackage-update`. The [updater guide, lines 7–24](https://github.com/axodotdev/cargo-dist/blob/v0.33.0/book/src/installers/updater.md#L7-L24), distinguishes this separately invoked executable from choosing to integrate the axoupdater library into an application's own code. Both files were retrieved successfully during this audit. The option adds an installed companion executable and its update behavior; these sources do not support the claimed addition of bytes to every application binary. The source script prints occurrences of `install-updater`, but does not test the asserted per-binary effect.

   **Repair:** Keep the proposed `install-updater = false` value if the scope rationale remains the same, but describe its actual effect: enabling it installs a separate `<package>-update` executable; leave it disabled because the additional self-update command is outside the requirements. In the exclusion paragraph, distinguish optional library integration from dist's standalone updater. Remove the unsupported per-application-binary growth claim. Rerun the self-check against the revised decision and preserve its new log. This finding concerns source support, not the ranking of release tools or the chosen release profile.

## Scope and revision binding

This is an independent empirical audit of P02 R68, revision 5. All three requested scripts passed, with 76 passing assertions, zero failing assertions and zero skips. Their output reproduces under the decision's stated rules. Approval is withheld for EA5-1, the source-description error above.

The first command executed was:

```sh
shasum -a 256 research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md
```

It returned the expected digest `10a6a71bda644a93a8aa667e34a90b11b5c4f890b40366ba23b464ead0010b41`. The decision contains 81,401 bytes and 925 lines. The digest was checked again after the reruns and immediately before writing this audit; it was unchanged.

I read the project charter inputs in their specified order, `research/RUNBOOK.md` §5, the decision, and the three evidence scripts. I did not open any prior audit, decision snapshot, or topic raw-answer file for review, and did not consult another auditor or synthesizer. As explicitly requested, the unmodified self-check executed its built-in snapshot-hash and review-directory email checks; it exposes digests and check results, not prior review prose. No Git writes, research-runner commands, paid APIs or submitting APIs were used. Scratch files and fresh output are under `/tmp`; this audit is the only repository file written.

`claude` is the assigned audit seat. The operator is Codex, and the current session's runtime `turn_context.model` identifies the model as `gpt-6-astra`, family `openai`.

## Current evidence and executed commands

The pairings come from `DECISION.md:460–497`, not from the oldest log or the greatest assertion count available elsewhere:

| Script | Current paired log for revision 5 | Historical evidence |
|---|---|---|
| `decision-self-check.sh` | `decision-self-check.r5.log` | r4 and older self-check logs |
| `artifact-sources.sh` | `artifact-sources.r4.log` | r2 and the original retrieval log |
| `profile-probe.sh` | `profile-probe.r4.log` | r2, its two reruns, and the original log |

Every primary command below ran from:

```text
/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/evidence
```

The inherited private Cargo cache was `CARGO_HOME=/tmp/cargo-s43-R68-emp`. I set `TMPDIR=/tmp/r68-claude-r5-3a4s136c/tmp` so scratch output stayed under `/tmp`. `R68_TOOLCHAIN`, `R68_TOOLCHAIN_OVERRIDE`, `R68_REGENERATE_LOCK`, `RUSTFLAGS`, `CARGO_ENCODED_RUSTFLAGS` and `RUSTC_WRAPPER` were unset. No graph regeneration or toolchain override was used.

```sh
TMPDIR=/tmp/r68-claude-r5-3a4s136c/tmp ./decision-self-check.sh > /tmp/r68-claude-r5-3a4s136c/decision-self-check.fresh.log 2>&1
TMPDIR=/tmp/r68-claude-r5-3a4s136c/tmp ./artifact-sources.sh > /tmp/r68-claude-r5-3a4s136c/artifact-sources.fresh.log 2>&1
TMPDIR=/tmp/r68-claude-r5-3a4s136c/tmp ./profile-probe.sh > /tmp/r68-claude-r5-3a4s136c/profile-probe.fresh.log 2>&1
```

The self-check ran first. The independent source query and profile build then ran concurrently. Each script ran once; no failed primary run was discarded or replaced.

| Script | Start, UTC on 2026-09-27 | Exit | Observed terminal result | Pass | Fail | Skip |
|---|---|---:|---|---:|---:|---:|
| Self-check | 16:37:25 | 0 | `RESULT: PASS — every assertion held` | 29 | 0 | 0 |
| Artifact sources | 16:37:40 | 0 | `RESULT: PASS — every assertion held` | 26 | 0 | 0 |
| Profile probe | 16:37:40 | 0 | `RESULT: PASS — every assertion held` | 21 | 0 | 0 |
| Total | | | 3 scripts passed | 76 | 0 | 0 |

The self-check printed `decision: DECISION.md (81401 bytes)`. Its heading locations were `110`, `398`, `438` and `681`, and all 29 assertion lines matched the current r5 log exactly.

The profile probe reported Homebrew `rustc 1.98.1 (48a229cea 2026-09-01)` and `cargo 1.98.1 (797e8a9bc 2026-08-05)`, rustc commit `48a229ceaefd4985c50990b14116b6d856af0985`, LLVM `22.1.8`, macOS `26.4 (25E246)`, `aarch64-apple-darwin`, and Apple M4 Pro. These match the paired r4 environment. The source script reported `gh version 2.101.0` and `curl 8.7.1`.

The complete fresh output remains in the three `/tmp` logs above:

| Fresh log | SHA-256 |
|---|---|
| `decision-self-check.fresh.log` | `d5841211cf61de2e3f58127605948831d766bfd0ede6cb4f43bf1e303de67b84` |
| `artifact-sources.fresh.log` | `36f22d6386450616bcd0551bd4c6ac9865e2be1f65924937f6b3a8f6fb485575` |
| `profile-probe.fresh.log` | `b0bcaa1ca6b20a3f8c09770ab5c5400693b973dc233e499450930c4ec6f68187` |

## Byte comparisons and permitted differences

From the evidence directory, I executed each literal comparison and then inspected the complete unified diff:

```sh
cmp decision-self-check.r5.log /tmp/r68-claude-r5-3a4s136c/decision-self-check.fresh.log
diff -u decision-self-check.r5.log /tmp/r68-claude-r5-3a4s136c/decision-self-check.fresh.log
cmp artifact-sources.r4.log /tmp/r68-claude-r5-3a4s136c/artifact-sources.fresh.log
diff -u artifact-sources.r4.log /tmp/r68-claude-r5-3a4s136c/artifact-sources.fresh.log
cmp profile-probe.r4.log /tmp/r68-claude-r5-3a4s136c/profile-probe.fresh.log
diff -u profile-probe.r4.log /tmp/r68-claude-r5-3a4s136c/profile-probe.fresh.log
```

Every raw `cmp` and `diff` exited 1 because a timestamp differs. These are comparison differences, not script execution failures. Full diffs are saved as `decision-self-check.diff`, `artifact-sources.diff` and `profile-probe.diff` under `/tmp/r68-claude-r5-3a4s136c/`.

**Self-check:** `cmp` reported `differ: char 56, line 2`. The only differing line was:

```diff
-date(UTC): 2026-09-27T15:51:35Z
+date(UTC): 2026-09-27T16:37:25Z
```

Removing only `date(UTC):` from both copies made `cmp` exit 0. The decision byte count did not differ; it was not normalized away.

**Artifact sources:** `cmp` reported `differ: char 58, line 2`. The first differing lines were:

```diff
-date(UTC): 2026-09-27T06:05:08Z
+date(UTC): 2026-09-27T16:37:40Z
```

The only other changes were these explicitly volatile `FIGURE` values:

| Field | Paired r4 | Fresh |
|---|---:|---:|
| cargo-dist downloads, previous 90 days | 19,281 | 19,312 |
| cargo-dist downloads, all time | 178,421 | 178,452 |
| cargo-binstall downloads, previous 90 days | 130,014 | 130,660 |
| cargo-binstall downloads, all time | 3,507,400 | 3,508,044 |
| cargo-binstall GitHub stars | 2,895 | 2,896 |

All 26 `ASSERT` lines, all `PINNED` lines, all resolved `HEAD` lines and their quoted source text matched byte-for-byte. Removing only the date and `FIGURE` lines made a second `cmp` exit 0. I inspected the actual changed `FIGURE` fields above; no changed assertion or source claim was concealed by that normalization.

**Profile probe:** `cmp` reported `differ: char 49, line 2`. The first differing lines were:

```diff
-date(UTC): 2026-09-27T06:05:22Z
+date(UTC): 2026-09-27T16:37:40Z
```

Wall-clock `TIME` lines changed, as permitted. The only changed size row and percentage were:

```diff
-SIZE debug=line-tables-only                    2242648 bytes  (after external strip -S -x:    1628280)
+SIZE debug=line-tables-only                    2240568 bytes  (after external strip -S -x:    1628280)
-DELTA debug=line-tables-only                    +12.5%
+DELTA debug=line-tables-only                    +12.4%
```

Its corresponding `ASSERT ok` text also changed from `+12.5%` to `+12.4%`; the outcome remained `ok`. All 21 assertion outcomes matched. All six `BACKTRACE` lines matched byte-for-byte. Across all 12 `DELTA` rows, the maximum difference was 0.1 percentage points, within the decision's ±2.5-percentage-point tolerance. The other 11 size rows matched exactly. Every line outside the expressly compared date, time, size, delta and assertion categories was identical. No asserted-field drift remains under the stated comparison rules.

The fresh clean times were baseline 16 seconds, owner-reference `thin+cu1` 18 seconds, and recommended `fat+cu1` 22 seconds. The two bin-only rebuilds were 1 and 12 seconds. These are this audit's observations, not reproducible timing requirements.

## Independent checks of figures and sources

**Sizes and arithmetic.** I parsed the committed lockfile independently: 85 packages, SHA-256 `2756d45c172e38e05192d18dfc98cb028ff112dd1164b1f6a58d3cfc21ec1082`. All nine named direct dependency versions match the decision. The fresh Cargo tree reproduced 52 unique lines at default features and 93 with all features.

Independent arithmetic from every `SIZE` row in the historical `profile-probe.r2.log` reproduces all 12 printed one-decimal percentages. The fresh baseline remains 1,994,032 bytes; `thin+cu1` remains 1,675,728 bytes; `fat+cu1` remains 1,504,528 bytes. Their reductions are 15.9628% and 24.5485%, respectively, printed as 16.0% and 24.5%. The marginal saving is exactly 171,200 bytes. The decision's 8.5-percentage-point comparison subtracts those displayed rounded percentages; dividing the byte difference by the baseline gives 8.5856 percentage points.

I also recalculated clean-build ratios from all five retained historical logs, rather than treating the unkept second revision-1 run as recoverable evidence. Baseline-to-recommended ratios span 1.3333–1.8750. Owner-reference-to-recommended ratios span 1.2000–1.5789. These support the rounded ranges of 1.3–1.9 and 1.2–1.6 in the decision. Full calculations are in `/tmp/r68-claude-r5-3a4s136c/independent-arithmetic.log`.

**Actual binary equality.** The script's `strip=debuginfo` assertion compares byte counts, not file contents. I checked the stronger prose claim separately. I extracted the four fixture heredocs unchanged from `profile-probe.sh` into `/tmp/r68-claude-r5-3a4s136c/bytecheck`, copied the committed lockfile, and ran the following commands from that directory:

```sh
CARGO_TARGET_DIR=/tmp/r68-claude-r5-3a4s136c/bytecheck/t-baseline cargo build --release --locked --offline --quiet --features web > /tmp/r68-claude-r5-3a4s136c/bytecheck.baseline-build.log 2>&1
CARGO_TARGET_DIR=/tmp/r68-claude-r5-3a4s136c/bytecheck/t-debuginfo cargo build --release --locked --offline --quiet --features web --config 'profile.release.strip="debuginfo"' > /tmp/r68-claude-r5-3a4s136c/bytecheck.debuginfo-build.log 2>&1
cmp t-baseline/release/rslbp t-debuginfo/release/rslbp
shasum -a 256 t-baseline/release/rslbp t-debuginfo/release/rslbp
```

Both builds exited 0 with empty build logs. Both binaries were 1,994,032 bytes; `cmp` exited 0. Both hashes were `073c4937e50598cb281c1e685f34496836e0cf1d09b3c73cbc46c6058eb36452`. Supplemental totals: two successful builds, one passing content-equality check, zero failures, zero skips. This independently supports byte identity for this fixture; it is not inferred merely from equal sizes. The receipt is `/tmp/r68-claude-r5-3a4s136c/bytecheck.result.log`.

**Backtraces.** The fresh built binaries reproduced baseline 4 frames/exit 101, recommended profile 4/101, `strip=symbols` 0/101, `panic=abort` 2/134, and line tables 5/101. The line-table check reproduced two `at ./src/` lines in the build tree and zero after copying the binary out and deleting its target directory.

**Public source checks.** The primary source rerun again returned 23 release assets for dist `v0.33.0`, zero `ubuntu-latest` occurrences in its pinned CI backend, the documented runner overrides and profile stub, and the versionless binstall filename rule. It reproduced the release-please draft/tag documentation and the installer-script bootstrap. The registry gap still exists: GitHub `v0.33.0`, crates.io stable `0.32.0`, and `registry-gap-present=1`. RustSec returned 200 for all three controls and 404 for both tool pages. These are observed source responses; they are not execution of dist or an actual binstall installation.

I additionally retrieved the following sources into `/tmp`, with all three GET commands exiting 0:

```sh
curl -fsS -A rs-launch-blueprint-r68-empirical-auditor https://doc.rust-lang.org/cargo/reference/profiles.html -o /tmp/r68-claude-r5-3a4s136c/cargo-profiles.html
gh api -H 'Accept: application/vnd.github.raw' 'repos/axodotdev/cargo-dist/contents/book/src/reference/config.md?ref=v0.33.0' > /tmp/r68-claude-r5-3a4s136c/dist-config.v0.33.0.md
gh api -H 'Accept: application/vnd.github.raw' 'repos/axodotdev/cargo-dist/contents/book/src/installers/updater.md?ref=v0.33.0' > /tmp/r68-claude-r5-3a4s136c/dist-updater.v0.33.0.md
```

The [Cargo profiles chapter](https://doc.rust-lang.org/cargo/reference/profiles.html#release), HTML lines 376–392 in the fetched copy, confirms the release defaults and that `cargo install` defaults to that profile. The pinned dist configuration confirms `all-features = false`, `default-features = true`, `features = []`, and `install-updater = false`. The last source check also establishes EA5-1. An initial heading lookup returned no matches because it searched H2 headings; the corrected H4 lookup resolved the settings. No public fetch failed.

**Both source repositories.** These read-only commands succeeded against existing local checkouts:

```sh
git -C /Users/stevemorin/c/py-launch-blueprint show b08bccfb:.github/workflows/ci.yml
git -C /Users/stevemorin/c/ts-launch-blueprint show cb1cbcb2:package.json
```

The Python workflow's lines 215–222 contain `uv build`, `uv run --no-sync twine check dist/*`, and the wheel-install version smoke command. The TypeScript manifest's lines 20–23 contain the `dist` allow-list and `"type": "module"`. These support the corresponding source facts in `DECISION.md:222–230`; no verdict was assigned from memory.

## R50 observations and limits

The deliberately unpinned R50 reference resolves at:

```text
research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md
```

Its current title still says revision 6. The referenced lines retain their stated meaning:

| Cited lines | Current observation |
|---|---|
| 7, 116, 335 | Install commands include `--debug` |
| 433 | The profile row explicitly describes a dev-profile compile |
| 564 | Re-verify trigger (13) names R68 resolving |
| 981 | The text identifies R68's release build as the expected release-profile compile and records the pull-request coverage limit |

No cited-line drift was observed. R50 remains `open` in the research index. No digest requirement was imposed and no finding was created from its deliberate lack of a digest pin. These statements describe an unaccepted proposal at audit time.

The published R49 decision also resolves at `research/topics/49-build-target-declaration/DECISION.md`: lines 889–891 contain the A4 winning condition, and lines 1042–1047 contain the dist-metadata re-verification requirement cited by R68.

The audit does not convert the decision's disclosed gaps into completed implementation tests. Dist, the composed release-please workflow, real-release binstall inference, Linux/x86_64 builds, and incremental timings for the other ten profile rows remain unproven as stated under `## Engines`. Engine-only measurements, adoption counts, issue-response surveys and previous-audit results were not independently verified because their source files were outside this audit's permitted reading scope. The decision attributes those claims rather than presenting them as this auditor's measurements.

Finally, `shasum -a 256 -c /tmp/r68-claude-r5-3a4s136c/evidence-before.sha256` reported `OK` for all three scripts, all three current paired logs, the historical r2 profile log, and the committed lockfile. None was overwritten. The remaining repair is EA5-1; no primary-script execution failure or reproducibility failure was observed.
