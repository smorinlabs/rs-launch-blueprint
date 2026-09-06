Actor: `evidence-terra-2026-09-05T160304Z-1e904d50d29e-r3`  
Checked: 2026-09-05

## Figures

The crates.io, GitHub REST, RustSec, and reverse-dependency endpoints in the prompt do not apply: R41 recommends an installed Cargo command and repository-local Bash helper, not a separately distributed crate. I independently read the retained local result endpoints and recomputed the warm medians, ranges, and integrity checks.

| Figure group in `raw/codex.md` | Result | Evidence |
|---|---|---|
| Fixture composition: 88 packages, comprising 85 registry packages and 3 workspace members | ok | `fixture-r41/run-20260905-38559-1er1lv7/summary.json` reports exactly `88`, `85`, and `3`. All 10 declared input digests in that run's `fixture-sha256.json` match the current retained fixture, including `Cargo.lock`, all manifests, `hook.sh`, and `measure.rb`. |
| macOS host/toolchain and behavioral statuses | ok | The retained `results.json` records the declared macOS arm64 host, Cargo/Rust 1.96.0 floor and 1.98.0 comparison binaries, and all 123 expected experimental outcomes. The sole non-successful setup record is the explicitly reported denied `sysctl` hardware probe, whose `expected` value is null rather than a failed experiment. |
| macOS metadata and commit latency, CPU, throughput, and floor compilation figures | ok | Recomputing retained records yields floor metadata warm median/range `0.136`/`0.126–0.153` seconds and commit median/range `0.277`/`0.257–0.297`; stable values are `0.125`/`0.094–0.157` and `0.210`/`0.197–0.218`. `summary.json` also matches the reported 7.26/8.13 warm-metadata invocations per second and 10.067-second floor compilation. |
| Stale, repair, parity, trigger, and skip controls | ok | Retained records show full stale metadata exits 101, blocked stale commits exit 1, repaired commits exit 0, parity-mismatch commits exit 1, and the deliberately Cargo-unavailable unrelated commits exit 0. The `--no-deps` and `update --locked --dry-run` controls return 0 on the stale fixture as reported. |
| Lockfile preservation and diagnostic | ok | The reported `6205ba...972d0` hash is the retained fixture lockfile hash. The floor and stable stale stderr records contain Cargo's `cannot update the lock file` diagnostic; the relevant retained commands record unchanged lock bytes. |
| Lima Ubuntu Linux leg | ok | `fixture-r41/linux-leg.log` records Ubuntu Linux `aarch64`, Cargo/Rust 1.96.0 and 1.98.1, and for each: clean guarded commit exit 0, stale direct guard exit 101, stale guarded commit exit 1, and unchanged lockfile hash. The reported 0.05/0.03/0.03-second observations match the log. The report correctly limits this to Lima Ubuntu `aarch64`, not GitHub-hosted `ubuntu-latest` `x86_64`. |

Figure counts: **ok 6; wrong 0; unverifiable 0**.

## Gates

| Fitness-gate claim in `raw/codex.md` | Result | Evidence |
|---|---|---|
| 1. License is inapplicable to the Cargo-command alternatives; the helper is repository code for the fixed `MIT OR Apache-2.0` template. | ok | The recommendation introduces no crate or dependency tree. The retained helper is source in the template, not a separately licensed package. |
| 2. The dominant `cargo metadata --locked --format-version=1` command works at the 1.96.0 MSRV floor. | ok | Retained macOS records show successful floor metadata and `cargo check --workspace --all-targets --locked`; the Linux leg also records the guard's clean and stale behavior under Cargo/Rust 1.96.0. |
| 3. RustSec, authored `unsafe`, crate features, and async-runtime coupling are inapplicable to the command and Bash helper. | ok | No new Rust crate, feature selection, runtime, or authored unsafe Rust is recommended. The report correctly does not extend this conclusion to Cargo or the fixture's application dependencies. |
| 4. The dominant command and helper have direct evidence on the required macOS and Ubuntu OS families. | ok | Retained macOS execution covers the first fixed operating system; the new Lima Ubuntu leg executes both direct and pre-commit guard paths at the floor and stable toolchains. The report does not overstate this as an exact GitHub `ubuntu-latest` `x86_64` reproduction. |
| 5. Default-feature and async-runtime effects are stated. | ok | The report identifies that the helper adds neither and that metadata resolves the application's selected/default features; it separately describes the fixture's Tokio web-service workload. |
| 6. Binary-size and compilation cost are stated qualitatively and measured where applicable. | ok | The recommendation adds no application binary or compilation dependency. The report separately provides measured resolver/commit cost and the optional floor compilation timing rather than treating the latter as the hook's cost. |

Gate counts: **ok 6; wrong 0; unverifiable 0**.

## References

| Cited implementation or source | Result | Evidence |
|---|---|---|
| Cargo command and resolver documentation | ok | The official `cargo metadata`, resolver, update, generate-lockfile, check, and build pages all resolve. They are the maintained authority for the command semantics; the report limits the recommendation to `metadata --locked --format-version=1`. |
| Git hook and diff documentation | ok | The official Git pages resolve and support the hook lifecycle and index/worktree distinction on which the parity guard is based. |
| Warp workflow | ok | The current maintained workflow exists and still runs `cargo metadata --locked --format-version=1` with a lockfile remediation message. The report correctly scopes Warp to a CI command/message precedent, not the complete staged-trigger guard. |
| clap and Cargo lockfile workflows | ok | Current maintained workflows exist. clap runs `cargo update --workspace --locked`; Cargo runs `cargo update -p cargo --locked`. The report does not represent either as a full pre-commit guard implementation. |
| Pinned Python and TypeScript precedents | ok | Fresh `git show` queries at the cited immutable commits reproduce Python's staged `uv lock --check` job and show no dedicated TypeScript lockfile-check job. |
| Complete staged-trigger plus index-parity reference implementation | ok | No maintained external implementation is claimed. The report explicitly states this evidence gap and identifies `hook.sh` as newly authored, executable research code rather than maintenance evidence, as the prompt permits. |

Reference counts: **ok 6; wrong 0; unverifiable 0**.

## Verdict

**sound**

The third revision repairs the sole open R2 condition: it retains direct Linux execution of the same guard's clean, stale-direct, and stale-commit paths at both the 1.96.0 floor and stable toolchains. Its architecture caveat is explicit, its retained figures recompute, and its maintained-reference claims remain limited to what those sources demonstrate.

Totals: **ok 18; wrong 0; unverifiable 0**.
