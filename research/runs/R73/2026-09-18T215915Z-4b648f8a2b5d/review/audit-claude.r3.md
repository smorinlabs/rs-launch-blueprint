actor: claude
model: gpt-6-astra
family: openai
decision-sha256: 96f388d12f267956fb57db29ae52801ef0e614dc0cfba7da36300ea54324845d
verdict: reject
unresolved-findings:

1. **EF-1 — A store failure during completion returns 201, contradicting the general 503 claim.** Failed claim: `DECISION.md:384-385`, “A poisoned lock is `PortError::Unavailable`, surfaced as 503”, citing `s10` and `w15`. Evidence: an independent test against an unchanged copy of the probe lets `begin()` succeed, then poisons the store inside a handler that returns 201. Its output is `AUDIT expected=503 observed=201`, followed by `test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s`; Cargo exits 101. `evidence/probe/src/layer.rs:215-224` discards the result of `complete()` with `let _ =`, disarms the guard, and returns the handler response. The other completion branches at lines 197 and 203 also discard that result. `w15` poisons the store before `begin()`, so its pass establishes only the earlier failure path. **Repair:** explicitly define and test the response to a post-handler completion failure. Either implement the stated 503 behavior with its side-effect/retry consequences addressed, or narrow the claim to failures from `begin()` and disclose the observed completion-failure behavior. Do not claim that the general failure contract was executed by `w15`. The independent test and both attempted commands are reproduced below.

2. **EF-2 — `s10` does not execute the `RSLB101` mapping.** Failed claim: `DECISION.md:575-577`, “R03 rule 5's mapping of the poisoned-`Mutex` `PortError::Unavailable` to `RSLB101`, which check `s10` executes.” Evidence: `evidence/probe/tests/store.rs:272-296` invokes the three port methods after poisoning and asserts only `PortError::Unavailable` and a detail containing `poisoned`. Searching every Rust file in the probe finds `RSLB101` only in the comment at `src/adapter.rs:135`. There is no executable catalogue-code mapping or assertion. The rerun does pass `s10`; that proves the enum/error-detail behavior, not this mapping. **Repair:** state that `s10` executes the `PortError::Unavailable` return and mark the catalogue mapping as a P03 obligation, or add and execute the actual mapping and its assertion before claiming it was tested.

3. **EF-3 — The eviction test does not execute the stated 1,025-key workload.** Failed claim: `DECISION.md:156-158`, “`max_entries` is 1,024, so the 1,025th distinct key evicts the least-recently-used entry before its TTL expires (`s06` executes exactly that eviction)”. Evidence: `evidence/probe/tests/store.rs:165` constructs `InMemoryIdempotencyStore::new(60_000, 1_000, 3, clock)`. Lines 167-176 insert `a`, `b`, `c`, touch `a`, then insert `d` and assert length 3. The 1,024-entry fixture belongs to benchmark `s08`, which never inserts a 1,025th key. **Repair:** describe `s06` as an executed three-entry demonstration of the eviction rule, and label the 1,024-to-1,025 example as an inference from that rule; alternatively execute the exact larger workload. The general eviction behavior itself passed.

4. **EF-4 — Two reconciliation counts are stale.** Failed claims: `DECISION.md:404`, “all four of its outcomes are *success*”, and `DECISION.md:409`, “the nine store checks”. Evidence: `evidence/probe/src/port.rs:38-52` defines five successful `Begin` variants: `Fresh`, `InFlight`, `Replay`, `Completed`, and `Mismatch`. `tests/store.rs` contains ten `#[test]` attributes, and the rerun reports `10 passed; 0 failed`. **Repair:** change these counts to five outcomes and ten store checks. The main 28-test tally elsewhere in the decision is correct.

## Scope and identity

This is the independent empirical audit of R73 revision 3. The operator is Codex, the assigned actor label is `claude`, and the actual model ID is `gpt-6-astra` from this session's `turn_context` metadata. The model family is OpenAI. This audit judges execution and evidence support, not architectural preference or owner disposition.

The first shell command was executed from `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`:

```sh
shasum -a 256 research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md
```

Observed, exit 0:

```text
96f388d12f267956fb57db29ae52801ef0e614dc0cfba7da36300ea54324845d  research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md
```

The hash matched the requested target and matched again after the checks. I read the repository entry documents in their required order, the complete decision including `## Empirical check` and `## Engines`, and `research/RUNBOOK.md` section 5. I did not consult another auditor's narrative. The six requested scripts were executed unmodified; their internal snapshot hashes/citation checks are reported as script results, not as an independent review of prior revision snapshots. No provider operation was submitted and no research-runner command or Git write was performed.

## Six required reruns

All six scripts exited 0. The five evidence scripts report **158 PASS, 0 FAIL, 0 SKIP**. The decision-shape script, run last, reports **41 PASS, 0 FAIL, 0 SKIP**. Combined: **199 PASS, 0 FAIL, 0 SKIP**. The separate counterexample below is not included in those script totals.

Environment: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, `Darwin 25.4.0 arm64`. `CARGO_HOME=/tmp/cargo-s43-R73-emp` and `CARGO_TARGET_DIR=/tmp/cargo-s43-R73-emp-target` were inherited. `R73_REFRESH=0` prevented evidence refreshes; `TMPDIR=/tmp` kept scratch files there; `PYTHONDONTWRITEBYTECODE=1` suppressed Python cache writes.

Working directory for every command in this section:

```text
/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/evidence
```

Each command redirected both stdout and stderr to its fresh log:

```sh
R73_REFRESH=0 TMPDIR=/tmp PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0 /opt/homebrew/bin/bash ./r73-decision-shape.sh > /tmp/r73-claude-r3-j44bn93i/r73-decision-shape.log 2>&1
```

Observed, exit 0, 2026-09-27T16:22:32.289938+00:00 through 2026-09-27T16:22:59.754121+00:00:

```text
CHECKS RUN: 41 PASS: 41 FAIL: 0 SKIP: 0
```

```sh
R73_REFRESH=0 TMPDIR=/tmp PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0 /opt/homebrew/bin/bash ./r73-muse-currency.sh > /tmp/r73-claude-r3-j44bn93i/r73-muse-currency.log 2>&1
```

Observed, exit 0, 2026-09-27T16:21:45.691773+00:00 through 2026-09-27T16:21:46.301443+00:00:

```text
CHECKS RUN: 46 PASS: 46 FAIL: 0 SKIP: 0
```

```sh
R73_REFRESH=0 TMPDIR=/tmp PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0 /opt/homebrew/bin/bash ./r73-probe.sh > /tmp/r73-claude-r3-j44bn93i/r73-probe.log 2>&1
```

Observed, exit 0, 2026-09-27T16:21:45.692089+00:00 through 2026-09-27T16:22:23.431531+00:00:

```text
CHECKS RUN: 27 PASS: 27 FAIL: 0 SKIP: 0
```

```sh
R73_REFRESH=0 TMPDIR=/tmp PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0 /opt/homebrew/bin/bash ./r73-registry.sh > /tmp/r73-claude-r3-j44bn93i/r73-registry.log 2>&1
```

Observed, exit 0, 2026-09-27T16:21:45.697008+00:00 through 2026-09-27T16:21:51.416450+00:00:

```text
CHECKS RUN: 17 PASS: 17 FAIL: 0 SKIP: 0
```

```sh
R73_REFRESH=0 TMPDIR=/tmp PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0 /opt/homebrew/bin/bash ./r73-sources.sh > /tmp/r73-claude-r3-j44bn93i/r73-sources.log 2>&1
```

Observed, exit 0, 2026-09-27T16:21:45.699326+00:00 through 2026-09-27T16:21:45.866550+00:00:

```text
CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0
```

```sh
R73_REFRESH=0 TMPDIR=/tmp PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0 /opt/homebrew/bin/bash ./r73-standard-conformance.sh > /tmp/r73-claude-r3-j44bn93i/r73-standard-conformance.log 2>&1
```

Observed, exit 0, 2026-09-27T16:21:45.704938+00:00 through 2026-09-27T16:21:45.957380+00:00:

```text
CHECKS RUN: 45 PASS: 45 FAIL: 0 SKIP: 0
```

The counts were also independently counted from the `PASS`, `FAIL`, and `SKIP` log lines, and all match the reported summaries. The probe separately executes **10 store tests and 18 router tests**, all passing, plus a filtered release rerun of `s08`. Build and `cargo clippy --all-targets -- -D warnings` passed. The fresh shape log records:

```text
PASS D6-labels-control — 151 distinct check labels scanned, so the resolution result below is not vacuous
PASS D7-tree — scripts/check-research-tree.sh passes on git archive HEAD with this run directory overlaid (OK: research tree structure valid)
PASS D7-tree-live — scripts/check-research-tree.sh also passes in the live checkout
```

All eight revision-3 `D8-*` checks passed, including Gemini's two cited statements, the accepted R02 revision-2 hash and citations, and the pinned standard's `dry_run` row at line 338.

## Byte comparisons

Each fresh log was compared with its supplied paired log using `/usr/bin/cmp`. On every mismatch, `/usr/bin/diff -u` was executed and saved under the scratch directory. Each raw comparison returned 1 because the clock line differs. Exact commands follow; `$paired` and `$fresh` are shell variables set to the actual absolute paths for each iteration.

```sh
for stem in decision-shape muse-currency probe registry sources standard-conformance; do
  paired="/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/evidence/r73-$stem.log"
  fresh="/tmp/r73-claude-r3-j44bn93i/r73-$stem.log"
  /usr/bin/cmp "$paired" "$fresh"
  /usr/bin/diff -u "$paired" "$fresh" > "/tmp/r73-claude-r3-j44bn93i/r73-$stem.diff"
done
```

The tool execution used the equivalent fully expanded argument vectors separately for each pair. These are the first differing lines, quoted verbatim:

| Script | `cmp` first difference | Paired line | Fresh line |
|---|---|---|---|
| `r73-decision-shape` | char 100, line 3 | `date_utc: 2026-09-27T15:44:27Z` | `date_utc: 2026-09-27T16:22:32Z` |
| `r73-muse-currency` | char 121, line 3 | `run_date_utc: 2026-09-27T06:28:55Z` | `run_date_utc: 2026-09-27T16:21:45Z` |
| `r73-probe` | char 90, line 3 | `date_utc: 2026-09-27T06:28:56Z` | `date_utc: 2026-09-27T16:21:45Z` |
| `r73-registry` | char 105, line 3 | `run_date_utc: 2026-09-27T06:28:50Z` | `run_date_utc: 2026-09-27T16:21:45Z` |
| `r73-sources` | char 104, line 3 | `run_date_utc: 2026-09-27T06:28:50Z` | `run_date_utc: 2026-09-27T16:21:45Z` |
| `r73-standard-conformance` | char 105, line 3 | `date_utc: 2026-09-27T06:28:50Z` | `date_utc: 2026-09-27T16:21:45Z` |

For `standard-conformance`, `registry`, `sources`, and `muse-currency`, the clock line is the entire diff, exactly as the decision requires. The same is true for `decision-shape`.

For `probe`, I inspected the complete diff. Additional changes are confined to the permitted temporary work path, test execution order, test duration, and benchmark values. Debug `s08` changes from 1,113 to 1,472 ns/op. Release `s08` changes from 184 to 368 ns/op, including the interpolated number in `PASS P5-bench` and its explanatory note. The benchmark PASS outcome and wording otherwise match. This is the decision's explicitly permitted measurement variability, not drift in an asserted result.

For a second comparison, I removed only clock lines. For `probe` I additionally normalized temporary paths, elapsed durations and measured ns/op values, and sorted only the individual test-result lines. `/usr/bin/cmp` returned **0 for all six normalized pairs**. Every other PASS/FAIL field, check count, resolved-version field, all nine dependency totals, and `Locking 62 packages to latest Rust 1.96 compatible versions` reproduce. Normalized files and full diffs remain under `/tmp/r73-claude-r3-j44bn93i/`.

Reference provenance limitation: the supplied paired logs exist on disk, but none is present at `HEAD`. A read-only `git show HEAD:research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/evidence/r73-probe.log` returned exit 128 with `fatal: path 'research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/evidence/r73-probe.log' exists on disk, but not in 'HEAD'`; the same lookup failed for the other five. Therefore these comparisons bind the supplied paired files, not an asserted Git-committed copy. Exact digests make the reference bytes explicit:

| Log | Paired SHA-256 | Fresh SHA-256 |
|---|---|---|
| `r73-decision-shape.log` | `eb5530ef59913888b806665999f8a324a050a23e772f5f34896b454a210e463b` | `5993fee1f9c7e605ade8a7f79b6b44edbf5aae4bdd69a6146cf71257cb1c1df7` |
| `r73-muse-currency.log` | `840af6d75e8d43febaca0f1d328446875d709d397c9e7fb72f9b3e7f3336a8eb` | `64f42bf5227d93d3874a8c1822985358c4670785c5593cc657f2b587d6d9130d` |
| `r73-probe.log` | `77735f4f2099a7798484cafcd76b4448a78e74bb323e8351facfa515a8b0e04c` | `599074d9182e5ff6522e8724d6a4feb3722d1788b820ecd9afd38955401c0dd0` |
| `r73-registry.log` | `c798456afa2c1ccc8c3188a8eb65bf446c736c3f7dfdfdd963bd3d72ece11991` | `d01e770fc683b4e7cf9c72fae41b005ba3e51bfa6727d70613bac9c28d653638` |
| `r73-sources.log` | `1f56abb1210b4cd30046a12966854259a4670c6357778afec61fb7c7513f6ab4` | `ad1376acf65d9aab4f6bbd5bc0ca44783fc05b4b5d7fd1747e154a72896b80e6` |
| `r73-standard-conformance.log` | `623514ebdde055969b37f26391c9b05b75f648b5e8b1efeb10d41adf00f0292b` | `40df4c529f5f295d4a466fc7639e37d493905ece92acc111a4119afcb5b11499` |

## Figures re-derived at source

The executed normal dependency graph counts unique name/version pairs, including the root package:

| Exact selection | Total packages | Increase over baseline |
|---|---:|---:|
| axum 0.8.9 + tokio 1.53.1 baseline | 51 | 0 |
| sha2 0.11.0, defaults off, alloc on | 59 | 8 |
| hashlink 0.12.2 | 54 | 3 |
| lru 0.18.4 | 56 | 5 |
| lru 0.18.5 | 54 | 3 |
| quick_cache 0.7.0 | 60 | 9 |
| mini-moka 0.10.3 | 62 | 11 |
| moka 0.12.16, sync feature | 65 | 14 |
| axum-idempotent 0.3.0 + ruts 0.10.1 + tower-cookies 0.11.0 | 88 | 37 |

These match the paired probe log, including the correction from the raw report's +48 to +37. I also read the downloaded published Cargo manifests directly under `/tmp/cargo-s43-R73-emp/registry/src/index.crates.io-1949cf8c6b5b557f/`, using `python3` with `tomllib`, independently of the snapshot assertions:

- `sha2-0.11.0/Cargo.toml` declares `rust-version = "1.85"`, licence `MIT OR Apache-2.0`, default features `alloc` and `oid`, `alloc = ["digest/alloc"]`, and `oid = ["digest/oid"]`. This supports the stated pin, minimum Rust declaration and feature choice.
- `lru-0.18.4/Cargo.toml` enables the optional `hashbrown` dependency with its defaults. `lru-0.18.5/Cargo.toml` sets `default-features = false` and requests `default-hasher` and `inline-more`. This supports the feature-level cause of the two-package reduction, rather than merely repeating the +5/+3 figures.
- `axum-idempotent-0.3.0/Cargo.toml` declares version 0.3.0, Rust 1.85.0 and MIT.

Source inspection of `tests/store.rs:220-246` confirms the benchmark's 1,024 entries, 1,000 warm-up calls and 10,000 measured calls. The fresh release result is 368 ns/op, or 0.368 microseconds per operation. It does not measure request throughput, lock contention or end-to-end latency.

The command `git -C /Users/stevemorin/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:src/py_launch_blueprint/web/settings.py` independently confirms `idempotency_ttl_seconds: int = 86400` and `idempotency_max_entries: int = 1024`. The standard script independently reads the pinned Git blob and verifies its 24-hour retention floor; 24 × 60 × 60 = 86,400 seconds.

The registry/source scripts establish the recorded historical snapshots, not fresh 2026-09-27 download counters or a new advisory search. I did not refresh or rewrite them. Linux execution, the actual R70 response envelope, full OpenTelemetry integration, and the other implementation-phase gaps remain unproven, as scoped by the decision and RUNBOOK section 5. No approving empirical claim is made for those gaps.

## Independent completion-failure experiment

Only scratch files were created. The seven original probe files copied to `/tmp/r73-claude-r3-j44bn93i/boundary-probe/` remained byte-identical to `evidence/probe/`. I added one integration test there, `tests/audit_boundary.rs`, shown in full below. Its deliberate poison uses the probe's existing `poison()` helper; that helper catches the spawned thread's panic, just as `s10` does. The failure is the HTTP assertion, not an uncaught panic in the request handler.

```rust
use std::sync::Arc;
use axum::{Router, body::Body, http::{Request, StatusCode}, routing::post};
use tower::ServiceExt;
use r73_probe::{adapter::InMemoryIdempotencyStore, layer::{IdempotencyState, idempotency}, port::Clock};

struct ZeroClock;
impl Clock for ZeroClock { fn now_millis(&self) -> u64 { 0 } }

#[tokio::test]
async fn poisoned_completion_must_surface_as_503() {
    let store = Arc::new(InMemoryIdempotencyStore::new(86_400_000, 30_000, 1_024, Arc::new(ZeroClock)));
    let handler_store = Arc::clone(&store);
    let state = IdempotencyState { store, max_request_bytes: 64, max_response_bytes: 1_024 };
    let app = Router::new().route("/things", post(move || {
        let store = Arc::clone(&handler_store);
        async move {
            // begin() has succeeded before this handler executes. Poison the
            // store now so complete() returns the error that s10 already proves.
            store.poison();
            (StatusCode::CREATED, "created")
        }
    })).layer(axum::middleware::from_fn_with_state(state, idempotency));
    let response = app.oneshot(Request::builder().method("POST").uri("/things")
        .header("idempotency-key", "k1").body(Body::from("{}")).unwrap()).await.unwrap();
    println!("AUDIT expected=503 observed={}", response.status().as_u16());
    assert_eq!(response.status(), StatusCode::SERVICE_UNAVAILABLE,
        "DECISION clause 13 says a poisoned lock surfaces as 503; complete() failed after begin() succeeded");
}
```

Working directory for both attempts: `/tmp/r73-claude-r3-j44bn93i/boundary-probe`.

First attempt:

```sh
CARGO_HOME=/tmp/cargo-s43-R73-emp CARGO_TARGET_DIR=/tmp/cargo-s43-R73-emp-target /opt/homebrew/bin/cargo test --offline --test audit_boundary -- --nocapture > /tmp/r73-claude-r3-j44bn93i/audit-boundary.log 2>&1
```

Observed exit 101 before any test executed:

```text
error: no matching package named `axum` found
location searched: crates.io index
```

This was an offline registry-resolution failure, not behavioral evidence. Test totals: **0 executed, 0 passed, 0 failed, 0 ignored**. I retried with normal public Cargo resolution:

```sh
CARGO_HOME=/tmp/cargo-s43-R73-emp CARGO_TARGET_DIR=/tmp/cargo-s43-R73-emp-target /opt/homebrew/bin/cargo test --test audit_boundary -- --nocapture > /tmp/r73-claude-r3-j44bn93i/audit-boundary-online.log 2>&1
```

The second attempt resolved the same exact direct pins and locked 62 packages under the declared Rust 1.96 floor. It built successfully, ran the test, and exited **101**:

```text
AUDIT expected=503 observed=201
assertion `left == right` failed: DECISION clause 13 says a poisoned lock surfaces as 503; complete() failed after begin() succeeded
  left: 201
 right: 503
test poisoned_completion_must_surface_as_503 ... FAILED
test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

Observed totals: **1 executed, 0 passed, 1 failed, 0 ignored/skipped**. This counterexample is EF-1. It does not invalidate the six scripts' recorded successes; it demonstrates a path those successes do not cover.

| Scratch artifact | SHA-256 |
|---|---|
| `/tmp/r73-claude-r3-j44bn93i/boundary-probe/tests/audit_boundary.rs` | `32786a4e83e89cb348e51b395612b4ffa23550b20c75b27cdc62c1375c80af59` |
| `/tmp/r73-claude-r3-j44bn93i/audit-boundary.log` | `604ec16064ea4cb47fbf3fa211ca207733c778f80a6e1b496e4f91e25c0859d0` |
| `/tmp/r73-claude-r3-j44bn93i/audit-boundary-online.log` | `4c94f53f72871018c83bbf39fa1fac1c520f8d0d08b71354ad73284707cdf04f` |

## Preservation and disposition

A before/after SHA-256 inventory covers all **118 files** under `evidence/`; the path sets and every digest are identical. The boundary experiment changed none of the copied original probe files. The decision hash remains the requested revision-3 hash. The only repository file written by this audit is `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/audit-claude.r3.md`; all generated logs, comparison files, the added test, and Cargo artifacts are under `/tmp`.

Reject revision 3 until EF-1 through EF-4 are repaired. The required reruns themselves reproduce successfully; the rejection concerns a demonstrated completion-failure mismatch and unsupported or stale execution claims.
