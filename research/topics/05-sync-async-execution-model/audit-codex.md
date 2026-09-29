actor: codex
model: gpt-6-sol
family: openai
decision-sha256: 3ae15853b0b613ff537ef647ff26be8260143a761328b8537e041a287c858b03
verdict: approve
unresolved-findings: none
session-id: 01a0e3b2-d306-7952-9615-8b3fbf183b3b

# R05 revision 6 — empirical audit

I verified the decision digest with `shasum -a 256` before reading or running anything, then verified it again before writing this file. I read `README.md`, `docs/port/README.md`, `research/CLAUDE.md`, the bound decision, and `research/RUNBOOK.md` section 5. This verdict addresses execution truth and evidence support. The template implementation and its Linux, handler, and concurrency checks remain P03 work as the decision states.

All commands below ran from `research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/evidence`. Fresh output went only to `/tmp/r05-codex-r6.qRJroz/`; no paired evidence log was overwritten. The three complete runs used permitted read-only public network access.

## Reruns and observed output

1. The first revision-5 attempt ran in the default sandbox:

   ```sh
   ./r05-check-r5.sh > /tmp/r05-codex-r6.qRJroz/r05-check-r5.rerun.log 2>&1
   ```

   Cargo could not resolve its public index. The partial log printed `FAIL V05 — at least one configuration moved` and `Could not resolve host: index.crates.io`; its four dependency counts were zero because the Cargo queries produced no tree. Through V06, it printed 6 passes, 1 failure, and 0 skips. I interrupted this incomplete attempt (exit 130), enabled the authorized network access, and reran the unchanged script to completion. There is no final summary in the interrupted log; the network-enabled run below resolves this environment failure.

2. Revision-5 script:

   ```sh
   ./r05-check-r5.sh > /tmp/r05-codex-r6.qRJroz/r05-check-r5.network.log 2>&1
   ```

   Exit 0; `passed=12 failed=0 skipped=0`; `RESULT: PASS`. V05 reproduced decision-method counts of 28, 88, 104, and 85 for its four client configurations, with `tokio v1.53.1` in the three `reqwest` trees. V07 found 106 default dependencies and `tokio` in Muse's revision-10 async core. V08 observed the expected revision-9 manifest error. V09 and V10 passed their pinned source checks; V11 matched all ten earlier evidence digests. `cmp r05-check-r5.log /tmp/r05-codex-r6.qRJroz/r05-check-r5.network.log` exited 0: the paired and fresh logs are byte-identical.

3. Original script:

   ```sh
   ./r05-check.sh > /tmp/r05-codex-r6.qRJroz/r05-check.network.log 2>&1
   ```

   Exit 0; `passed=21 failed=0 skipped=0`; `RESULT: PASS`. C10 printed 38 default and 71 feature-on dependencies with no default `tokio`; C11 printed 93 and 101 with default `tokio`. C13 built both probes and printed 13 seconds versus 33 seconds, preserving its asserted ordering. C14 printed `direct_blocking_len=559, spawn_blocking_len=559`; C19 printed 109 and 116 for `reqwest` with defaults.

4. Revision-3 script:

   ```sh
   ./r05-check-r3.sh > /tmp/r05-codex-r6.qRJroz/r05-check-r3.network.log 2>&1
   ```

   Exit 0; `passed=8 failed=0 skipped=0`; `RESULT: PASS`. T01 matched R69 revision 10's decision SHA-256. T06 printed 38 default and 72 feature-on dependencies, `cargo tree -i tokio` exit 101 by default and exit 0 with `--features web`. T07 matched the six revision-1 and revision-2 evidence digests.

## Byte-comparison findings

I ran `cmp` on each fresh log against its paired `.log`, then `diff -u` on each mismatch. These are findings under the requested byte-comparison rule. The decision and script headers explicitly identify the changed fields as variable; no check verdict, dependency count, version, source assertion, or bridge result changed.

- **D1 — `r05-check.log` differs.** `cmp` exited 1 at byte 268, line 4. The first differing lines from `diff -u` are:

  ```diff
  -toolchain:       rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
  +toolchain:       rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
  ```

  The remaining changed fields are Cargo 1.98.0 → 1.98.1, `retrieved-on` 2026-09-17 → 2026-09-27, C00 `HEAD` `9267dcb1dbc7461401bad269cc1d1fe7a6204212` → `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`, and C13's informational build seconds 12/32 → 13/33. The decision's reproducibility paragraph explicitly allows the date, HEAD, and timing to move; the toolchain also changed between recorded runs. The claim that the other lines remain stable is supported. No evidence repair is required for execution truth.

- **D2 — `r05-check-r3.log` differs.** `cmp` exited 1 at byte 279, line 4. The first differing lines from `diff -u` are:

  ```diff
  -toolchain:       rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
  +toolchain:       rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
  ```

  The remaining changed fields are Cargo 1.98.0 → 1.98.1, `retrieved-on` 2026-09-18 → 2026-09-27, and T00 `HEAD` `5c1da7a22b302f6713d414c76e5244b26c576611` → `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`. All T01–T07 output after the header is byte-identical. The decision and script explicitly allow the date and HEAD to move. No evidence repair is required for execution truth.

These comparisons test fresh output against paired logs. They do not establish whether all seventeen stored evidence files were byte-identical between decision revisions; seven revision-5 files are currently untracked, and the forbidden revision snapshot was not read. The ten earlier artifacts were checked by V11, and the current revision-5 log matches its fresh rerun byte for byte.

## Independent checks of load-bearing claims

I transcribed the manifests from the three scripts into fresh `/tmp` workspaces, copied their paired lockfiles, and ran `cargo tree --offline --locked --prefix none -e normal`. I counted unique normal-dependency lines after removing Cargo's ` (*)` repeat marker. This was separate from the scripts' temporary workspaces and did not query the network.

| Probe | Default packages | Web-on packages | `tokio` in default tree |
|---|---:|---:|---|
| Synchronous, R69 revision-9 feature | 38 | 71 | no |
| Asynchronous, R69 revision-9 feature | 93 | 101 | yes |
| Synchronous, R69 revision-10 optional member | 38 | 72 | no |
| Muse async core, R69 revision-10 optional member | 106 | not rechecked | yes |

Thus the stated differences are 71 − 38 = 33 web-only packages and 93 − 38 = 55 additional default packages for the compared async shape. A separate offline `reqwest` `blocking,rustls` probe, with no direct `tokio` declaration, resolved 85 normal dependencies including `tokio v1.53.1`. This supports revision 6's corrected alternative-E ground: criterion 1 fails; the direct-dependency optionality tested by criterion 2 is not engaged. The synchronous feature-on tree contained `ring v0.17.14` and no `aws-lc-rs`, `openssl`, or `native-tls`; the async feature-on tree contained `aws-lc-rs v1.18.1` and no `ring`, `openssl`, or `native-tls`.

I also rechecked R69 revision 10's run decision digest (`d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a`) and its current owned line 1791: the feature names `rs-launch-blueprint-web`, and the member declares `axum 0.8.9` and `tokio 1.53.1`. The registry still carries the older direct-crate feature. The new revision-6 paragraph about `clap` and `cargo-generate` accurately attributes the four-example reading and survey gap to `raw/muse.md` lines 70–76 and 161–164, and the negative search result to `raw/doxa-openai.normalized.md` line 147. It does not present that unrun template survey as execution evidence.

The complete scripts pass, the independent dependency figures agree, and the two byte mismatches are confined to recorded environmental fields. The initial DNS failure was repaired by rerunning with permitted network access. No execution or evidence-support finding remains unresolved.
