actor: audit-claude-2026-09-18T215916Z-b7f3ee4b098e
model: claude-opus-5-5
family: anthropic
decision-sha256: 8c8620a217430589d92576edf4bcf217da37e2487ee86bbf9bd1099c6130c2ab
verdict: approve
unresolved-findings: none

# R84 empirical audit — DECISION.md revision 1

Seat: the Claude seat. I am running as the approved fallback while the OpenAI provider
is quota-paused (method amendment Q8.B). This is not a Codex audit. Scope: execution
truth and evidence support only. The recommendation's wisdom is out of scope. I did not
read any `review/audit-fable*.md` file or `research/topics/84-*/raw/`.

## Target identity

`shasum -a 256 research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/DECISION.md` gave
`8c8620a217430589d92576edf4bcf217da37e2487ee86bbf9bd1099c6130c2ab` before and after the
reruns. This matches the expected revision-1 hash.

## Host

`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)
(Homebrew)`, rustup toolchain `1.96.0-aarch64-apple-darwin` present, ShellCheck 0.11.0,
Darwin arm64. The host is the same machine class as the synthesizer's. It is a separate,
fresh agent context.

## Method: why the reruns used a mirror

The decision's documented command redirects each script into its committed `.log`.
`r84-openapi-to-rust-probe.sh` appends to `snapshots/openapi-to-rust-timings.txt`, and
`r84-registry-figures.sh` overwrites `snapshots/registry-figures.json`. An in-place run would
therefore have modified evidence files. To keep this audit to one written file, I mirrored the
working tree to `/tmp/r84-audit-claude/wt` with `rsync -a`. The mirror excluded `.git`,
`target/`, and five large run directories that the scripts do not reference (`R01`, `R16`,
`R17`, `R23`, `R41`). The scripts reference only `research/runs/R02`, `R05` and `R84`. Before
running anything, `diff -r` showed the mirror's evidence directory identical to the repo's.
Each script ran from the mirror root with a **fresh, empty** cache,
`R84_CACHE=/tmp/r84-audit-claude/cache`, instead of the synthesizer's
`/tmp/r84-synth-cache`. Tools were therefore re-installed from crates.io, not reused.

## Reruns

| # | Command (cwd = mirror root, `E=research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/evidence`) | Observed | vs committed log | Claimed |
|---|---|---|---|---|
| 1 | `shellcheck` on each of the five `$E/*.sh` | rc=0, no output, all five | — | clean on all five |
| 2 | `./$E/r84-source-claims.sh > /tmp/…/source-claims.log 2>&1` (7 s) | rc=0, `PASS=60 FAIL=0 SKIP=0 TOTAL=60` | `diff`: IDENTICAL | 60/0/0 |
| 3 | `./$E/r84-openapi-to-rust-probe.sh > /tmp/…/o2r.log 2>&1` (4m08s, fresh `cargo install`) | rc=0, `PASS=31 FAIL=0 SKIP=5 TOTAL=36` | `diff`: IDENTICAL | 31 pass of 36, 5 skip |
| 4 | `./$E/r84-progenitor-probe.sh > /tmp/…/prog.log 2>&1` (1m42s) | rc=0, `PASS=6 FAIL=0 SKIP=0 TOTAL=6` | `diff`: IDENTICAL | 6/0/0 |
| 5 | `./$E/r84-registry-figures.sh > /tmp/…/reg.log 2>&1` (9m37s) | rc=0, `PASS=30 FAIL=0 SKIP=1 TOTAL=31` | `diff`: IDENTICAL | 30 pass of 31, 1 skip |
| 6 | From the repo root, `$E/r84-archive-rerun.sh r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures` (10m57s) | `archive HEAD: e0b0d1c1…`; source-claims `rc=0 DIFFERS` only at line 21 (`A13` `PASS`→`SKIP`) and line 91 (`PASS=60 … SKIP=0`→`PASS=59 … SKIP=1`); the other three `rc=0 IDENTICAL` | output byte-identical to committed `r84-archive-rerun.log` | exactly this |

Rerun 6 runs the scripts inside a `mktemp` extraction. It reads the repo only through
`git archive` and `cp`. Afterwards, `git status --porcelain research/runs/R84` showed only the
untracked `review/` directory, and every evidence file kept its prior mtime. Reruns 5 and 6
exceeded the 600-second foreground limit of the tool. I ran them as background shell jobs and
waited on them before proceeding. No other work depended on their partial output.

**SKIP lines, verified by name.** The five probe skips are exactly `R06`–`R10`. Each says the
shell refused a loopback TCP bind. The single registry skip is `M01`, Maven Central
unreachable. There are no other `SKIP` or `FAIL` lines in any log.

**Section-12 output.** Lines 57–60 of the probe log match the four verbatim lines quoted in
the decision (`DEFAULT_UNKNOWN_FIELD=accepted` … `RT_BIND=refused PermissionDenied`). My fresh
run reproduced them byte for byte.

**Check-identifier uniqueness.** Across the four logs, the full leading tokens contain no
duplicate. Examples are `F01-openapi-to-rust`, `P02` versus `P02b`, and `G05-762`. The claim
holds.

## Host-limit claims, independently confirmed

- **Loopback bind.** `python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0))"`
  in this audit shell failed with `PermissionError: [Errno 1] Operation not permitted`. The
  `R06`–`R10` skip reason is therefore a real host limit. This audit also could not run the
  HTTP half, so it remains unproven here, as the decision's "does not prove" item (2) states.
- **Maven Central (M01).** `curl --max-time 20
  https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.25.0/openapi-generator-cli-7.25.0.jar.sha1`
  failed with `curl: (28) Connection timed out after 20011 milliseconds`.

## Load-bearing figures re-derived at source

| Claim | Evidence here | Result |
|---|---|---|
| `A13`: HEAD's `execution-ledger.md` has 0 occurrences of the OV-11 allocation line; the working tree has it | `git show HEAD:docs/planning/p02/execution-ledger.md \| grep -cF 'OV allocation: OV-10 to R72, OV-11 to R84'` returned `0`. The working tree has it at line 1114. | confirmed |
| `E01`: OpenAPI Generator hard-codes `edition = "2021"` and declares no `rust-version` | raw `modules/openapi-generator/src/main/resources/rust/Cargo.mustache` at tag `v7.25.0`, line 20 `edition = "2021"`; no `rust-version` line | confirmed |
| `E03`: the `rust` template declares no `time` crate (refutes Gemini) | the same file has no `time` dependency line | confirmed |
| `E04`: string enums derive a closed `Deserialize` with no `#[serde(other)]` | `model.mustache` at `v7.25.0`: enum derives at lines 49 and 231 are plain `Serialize, Deserialize`, and there is no `serde(other)` anywhere | confirmed |
| `openapi-to-rust`: 46,127 all-time downloads and 37 stars (snapshot) | crates.io API now: `0.17.0 46396` all-time. The fresh `registry-figures.json` has 37 stars unchanged. | consistent: +269 downloads is monotone drift over the interval |
| Volatile snapshot as a whole | A key-by-key diff of the committed and fresh `registry-figures.json` shows only download counters rising and `OpenAPITools/openapi-generator` stars going from 26,762 to 26,761. No non-volatile field changed. | consistent |
| msrv floor 1.96 = stable 1.98.1 minus 2 | the host `rustc` is 1.98.1; `G08` PASS reads the stable tag | confirmed |

My unauthenticated `api.github.com` query for `gpu-cli/openapi-to-rust` hit the rate limit
(`API rate limit exceeded`). The star figure above therefore comes from the script's fresh
snapshot, not from an independent query.

## Findings

None. Every command in `## Empirical check` executes. Every claimed count reproduces. All
four logs are byte-identical on a fresh-cache rerun. The clean-extraction difference is
exactly the stated `A13` SKIP and its summary line. The spot-checked figures hold at source.

**Observation (not a finding).** The documented command writes logs and `snapshots/` in
place, so a rerun as written mutates evidence files. This does not make any claim false. A
future auditor should rerun from a copy, as this audit did.
