actor: codex
model: gpt-6
family: openai
decision-sha256: 90cf41d91cde910e5bfb087131ec332697759e235ff41ea72ed90a371b12d2ab
verdict: approve
checks: 6/6
unresolved-findings: none

# R84 r5vo3 micro-verification

The unchanged `r84-openapi-to-rust-probe.sh` reproduced the committed 36/0/0 result with public network access and an isolated `/tmp` cache. Its complete output was byte-identical to `review/evidence/r84-openapi-to-rust-probe.log`. All five evidence scripts retain the hashes recorded in r5vo and r5vo2 and have modification times before the repair snapshot.

## Checks and binding

1. Decision guard: `sha256sum review/DECISION.md` returned `90cf41d91cde910e5bfb087131ec332697759e235ff41ea72ed90a371b12d2ab`, matching the required repaired-decision hash. Recomputed immediately before writing this audit.
2. Prerepair snapshot: `sha256sum review/R84-r5-prerepair.md` returned `4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b`, matching the required snapshot hash.
3. Registry reachability: the exact requested curl check succeeded, and Cargo itself reached the registry with public network access, as documented below.
4. Probe rerun: the final, unchanged script invocation exited 0 with `PASS=36 FAIL=0 SKIP=0 TOTAL=36`.
5. Log comparison: `cmp -s` and `diff -u` against the committed probe log both exited 0; the normalized diff is empty.
6. Script stability: all five current SHA-256 hashes match the r5vo/r5vo2 table, and all five modification times precede `2026-09-27T16:12:05-0700`.

## Network evidence and rerun method

The first network check was run before the probe or any other network call. Command, exit, and output are reproduced verbatim. The output has no trailing newline.

```text
$ curl -sS -o /dev/null -w '%{http_code}' --head https://index.crates.io/config.json
exit=0
200
```

**OBS — different network behavior by process.** In the default sandbox, `cargo search openapi-to-rust --limit 1` exited 101 with this registry error:

```text
    Updating crates.io index
warning: spurious network error (3 tries remaining): [6] Couldn't resolve host name (Could not resolve host: index.crates.io)
warning: spurious network error (2 tries remaining): [6] Couldn't resolve host name (Could not resolve host: index.crates.io)
warning: spurious network error (1 try remaining): [6] Couldn't resolve host name (Could not resolve host: index.crates.io)
error: failed to update registry `crates-io`

Caused by:
  download of config.json failed

Caused by:
  [6] Couldn't resolve host name (Could not resolve host: index.crates.io)
```

I retried read-only Cargo registry access using `sandbox_permissions: "with_additional_permissions"` and `additional_permissions: {"network":{"enabled":true}}`. `cargo search openapi-to-rust --limit 1` then exited 0 and returned `openapi-to-rust = "0.19.0"`. The final probe invocation used that same public-network permission on the entire shell command, so Cargo ran with the successful network posture; the curl result alone was not used as proof of Cargo access.

**OBS — shared scratch cache was incomplete.** The first default-sandbox probe rerun, with `R84_TIMINGS=/tmp/r84-r5vo3-timings.txt`, exited 5 and recorded `PASS=24 FAIL=5 SKIP=0 TOTAL=29` in `/tmp/r84-r5vo3-probe.log`. A public-network rerun using the same shared cache exited 4 and recorded `PASS=25 FAIL=4 SKIP=0 TOTAL=29` in `/tmp/r84-r5vo3-probe-public.log`. A diagnostic rerun with a `/tmp` Cargo wrapper exposed this Cargo error verbatim:

```text
error: failed to download `anyhow v1.0.104`

Caused by:
  unable to get packages from source

Caused by:
  failed to read `/var/folders/23/311glm5s6f918wv29gx_0xzm0000gn/T//r84-synth-cache/cargo-home/registry/src/index.crates.io-1949cf8c6b5b557f/anyhow-1.0.104/Cargo.toml`

Caused by:
  No such file or directory (os error 2)
```

The final binding rerun called the original script at `review/evidence/r84-openapi-to-rust-probe.sh` without editing or copying it. It set `R84_CACHE=/tmp/r84-r5vo3-isolated-cache` and `R84_TIMINGS=/tmp/r84-r5vo3-isolated-timings.txt`, ran under the public-network permission above, and redirected all script output to `/tmp/r84-r5vo3-probe-isolated.log`. A Python `subprocess.run` wrapper capped the invocation at 1,100 seconds; the script exited 0. The script's own `CARGO_HOME` was therefore `/tmp/r84-r5vo3-isolated-cache/cargo-home`. Its final line was:

```text
PASS=36 FAIL=0 SKIP=0 TOTAL=36
```

**Normalization rule:** ignore archive-HEAD lines, UTC-date lines, and temp-path lines — volatile by design. Do NOT ignore check outcomes, summaries, or any other line.

No line required normalization for this probe comparison. `cmp -s review/evidence/r84-openapi-to-rust-probe.log /tmp/r84-r5vo3-probe-isolated.log` exited 0; `diff -u` also exited 0 and printed no difference. The committed log's tail is `PASS=36 FAIL=0 SKIP=0 TOTAL=36`.

## Evidence-script stability

The current values below equal the r5vo and r5vo2 recorded values. The repair snapshot time is `2026-09-27T16:12:05-0700`.

| Script in `review/evidence/` | Current SHA-256 | Current mtime | Baseline match and before repair |
|---|---|---|---|
| `r84-archive-rerun.sh` | `3bba3e2b008c5dfa139cf4ff0c2b3c85082ca61a0716ef4c47593d6c603f40f7` | `2026-09-25T11:42:39-0700` | yes |
| `r84-openapi-to-rust-probe.sh` | `8996655e48180e3ba35e3273c4a59bf6fdce9b6f05a09b9c919b04e727f6faa9` | `2026-09-26T19:40:53-0700` | yes |
| `r84-progenitor-probe.sh` | `b89ff53371954617d7858628486e091b051f0d6fc0598a31f71db5d2fd273055` | `2026-09-25T09:10:40-0700` | yes |
| `r84-registry-figures.sh` | `6552c64251063f6a339abf24b228a3c0afa35f2388cb2faea6722d813942ec25` | `2026-09-26T13:24:42-0700` | yes |
| `r84-source-claims.sh` | `b4fb4abc1af8b6a0df762e6482a18cde9f0fe316b211fc6ea597d7b0742d8275` | `2026-09-26T19:41:23-0700` | yes |

No BLOCKING finding remains. The two OBS findings above describe failed preliminary postures and do not change the final green binding.
