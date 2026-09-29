actor: audit-claude-R27-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: 89824ad9c99c6de6b1594456e15f17235118ae22f2208860f2a84de2e50ae2ad
verdict: approve
unresolved-findings: none

# R27 — empirical audit of DECISION.md revision 1

**Scope.** Execution truth and evidence support only, for `research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/DECISION.md`, revision 1. The recomputed sha256 matched the expected value before anything else was read (`shasum -a 256`). Read: the decision, `research/RUNBOOK.md` section 5, the five evidence scripts and their committed logs, `inputs/prompt.md`, and the R11 and R42 decision lines the decision cites. Not read: any `review/audit-*.md`, any `research/topics/*/raw/`, any snapshot, and neither `raw/` report of this run.

**Host.** macOS 26.4, Darwin 25.4.0 arm64; rustup 1.29.1; lefthook 2.1.14; just 1.51.0; git 2.50.1; gh 2.101.0; jq-1.8.2; ShellCheck at `/opt/homebrew/bin/shellcheck`. `CARGO_HOME=/tmp/cargo-s14-R27-emp` (private). Audit run on 2026-09-26 Pacific (figures fetched 2026-09-27T03:34:58Z UTC).

## Reruns

Command, from the repository root. Fresh logs went to `/tmp/audit-r27/`; nothing in `review/evidence/` was written.

```bash
E=research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/evidence
for c in r27-config-surface r27-workspace-scope r27-hook r27-channel-pin r27-figures; do
  /opt/homebrew/bin/shellcheck "$E/$c.sh"; echo "$c shellcheck=$?"
  "$E/$c.sh" > /tmp/audit-r27/$c.log 2>&1; echo "$c exit=$?"
done
cmp "$E/$c.log" /tmp/audit-r27/$c.log || diff "$E/$c.log" /tmp/audit-r27/$c.log   # per script
```

| Script | shellcheck | exit | Fresh summary line | `cmp` against committed log |
|---|---|---|---|---|
| `r27-config-surface.sh` | 0 | 0 | `65 checks, 65 pass, 0 fail` | identical |
| `r27-workspace-scope.sh` | 0 | 0 | `14 checks, 14 pass, 0 fail` | differs at line 52: timings only (below) |
| `r27-hook.sh` | 0 | 0 | `13 checks, 13 pass, 0 fail` | identical |
| `r27-channel-pin.sh` | 0 | 0 | `9 checks, 9 pass, 0 fail` | identical |
| `r27-figures.sh` | 0 | 0 | no assertions (observations) | differs at line 1: timestamp and two live counters (below) |

**Totals: 101 assertions, 101 pass, 0 fail, 0 skipped.** This equals the decision's `101 assertions, 101 pass, 0 fail, 0 skipped`.

**The two byte mismatches, quoted, and why neither is a finding.**

- `r27-workspace-scope.log`, lines 52–56 (C2.8, wall-clock timing):
  ```
  <     run 1 real=0.08s          >     run 1 real=0.10s
  <     run 2 real=0.07s          >     run 2 real=0.08s
  <     run 3 real=0.07s          >     run 3 real=0.06s
  <     just format-check real=0.54s   >     just format-check real=0.28s
  ```
  Timings vary by run. The assertion (`under 5 s`) passed in both. The decision's cost claim — `cargo fmt --all --check` at roughly 0.08 s per commit — holds within the rerun's 0.06–0.10 s range.
- `r27-figures.log`: line 1 is the retrieval stamp (`2026-09-27T01:15:13Z` versus `2026-09-27T03:34:58Z`). Lines 45–46 are live counters: tokio stars 33247 → 33248; clap stars 16726 → 16727 and `pushed_at` 2026-09-21T18:47:13Z → 2026-09-27T01:58:33Z. The decision cites neither counter. Every figure it does cite reproduced exactly: F1 `1.98.1` published 2026-09-03T13:14:07Z; F2 6974 stars, `archived=false`, `pushed_at=2026-09-24T13:36:12Z`, `license=Apache-2.0`; F3 718; F4 `answered=1 unanswered=9 median_days_answered=0.6`; F5 uv/zed `1.98.1`, ruff `1.98.0`, cargo-binstall `stable`, nushell `1.96.1`; F6 absences in tokio, clap, serde, crates.io; F7 tokio `ci.yml:846`; F8 `rust_toolchain/` present; F9 rustfmt-nightly newest `1.4.20` at 2020-09-06T02:12:50Z, genemichaels 4317 recent downloads, topiary-cli 153; F10 HTTP 404 for all four.

## Recommended bytes are the executed bytes

- `rustfmt.toml`: the decision's `toml` block hashes to `a714037d3cb8919614f9b8619ff9a940ac858e5da22b25298abb7f68c310bea8`. So do the bytes `r27-workspace-scope.sh:53-58` writes, and the fresh `r27-config-surface.log` prints the same sha256 for the file it wrote (C1.1).
- `Justfile`: the decision's `just` block diffed against `r27-workspace-scope.sh:68-89` with `diff`: no difference.
- `lefthook.yml`: the decision's `yaml` block is `JOB_A` in `r27-hook.sh:22-26`, the variant whose H1–H6 cases passed.
- `rust-toolchain.toml`: the scripts use the recommended shape at channels `1.93.0`, `1.96` and `stable`. The decision says plainly that `1.98.1` itself was never selected through rustup; the fresh C4.3 line reproduces `error: toolchain '1.98.1-aarch64-apple-darwin' is not installed`, exit 1.

## Figures re-derived at source

- **C1.4, the `edition` key**, run by hand outside the script with Homebrew's rustfmt 1.9.0 on the let-chain sample. With `edition = "2024"` the file parsed and produced a layout diff, exit 1. Without a config it printed `error: let chains are only allowed in Rust 2024 or later`. This confirms the script's `parsed` verdict is a real parse and not a missed error string.
- **F6, "stable-only files in uv, ripgrep, just, tauri and cargo"**: the log records these files' keys but makes no stability assertion. I wrote each of the five files as logged and ran `rustfmt --check` under Homebrew 1.9.0 and rustup `1.96`. All ten runs gave exit 0 and zero `can't set` warnings, so the claim holds.
- **Toolchain table**: the fresh C1 and C4 headers reproduce each rustc, rustfmt and clippy version string in the decision's table (1.93.0 / 1.94.0 / 1.96.0 / 1.96.1 / Homebrew 1.98.1).
- **C4.5 and C4.6**: the fresh log reproduces sha256 `a251383e89c8906f` on all four builds. It also reproduces clippy lint counts 806 / 811 / 819 and warn-by-default counts 410 / 408 / 414, and six new warn-by-default lints including `clippy::manual-take` and `clippy::manual-pop-if`.
- **Cited repository lines**: R42 `DECISION.md:12-16` (owner licence ruling), `:26` (profile and components; channel is R27's) and `:302-305` (8 of 9 pin exactly) say what the decision says. R11 `DECISION.md:93`, `:259`, `:268`, `:286` and `:383` do too. So do `inputs/prompt.md:4` (`format`/`check` recipe names), `:14`, `:25` (empty `owns:`), `:26` and `:38` (py/ts changes are a follow-on project), and `RUNBOOK.md:18-22`.

## Inputs the decision asserts about itself

- **Prerequisites.** `inputs/prerequisites.json` records R11 decision `410e88e5…418c` and R42 decision `a2504aa7…5e1c`. `shasum -a 256` of `research/topics/11-ci-workflow-job-structure/DECISION.md` and `research/topics/42-dev-toolchain-provisioning/DECISION.md` gives the same two hashes, so the decision's "both prerequisite decisions match" claim holds.
- **Parameters.** I rendered every entry of `inputs/parameters.json` as `- assumes <param> = <value>` (6 lines). `diff` against the decision's six `- assumes` lines found no difference.
- **Raw reports.** `raw/muse.md` has sha256 `cef378c1a4d836b923b9f420a05a146b06a44f5d87f0b4b2908f820cebfc326c` and 1186 lines. `raw/opus.md` has sha256 `1f99cfaf16b6145972f2a0bdc0eb4c9c06468573c48f27b57adb50491b40f4bd` and 1097 lines. Both match `## Engines`. I hashed and line-counted these files only; I did not read their contents.

## RUNBOOK §5 "version-pin recommendations must execute" — ruling, closed empirically

**The issue.** `RUNBOOK.md` §5 requires that "Configuration, command and version-pin recommendations must execute." The decision's own run never selected the recommended value `channel = "1.98.1"` through rustup (C4.3). It inferred "That channel supplies rustfmt 1.9.0" from Homebrew's build.

**The test.** I closed the gap with a public, read-only toolchain download into a private rustup home. Nothing was installed outside `/tmp`:

```bash
export RUSTUP_HOME=/tmp/audit-r27/rustup PATH="$HOME/.cargo/bin:/usr/bin:/bin"
rustup toolchain install 1.98.1 --profile minimal -c rustfmt -c clippy --no-self-update
# → 1.98.1-aarch64-apple-darwin installed - rustc 1.98.1 (48a229cea 2026-09-01); rc=0
# then, with RUSTUP_AUTO_INSTALL=0, in a scratch crate carrying the decision's rust-toolchain.toml at channel "1.98.1":
rustup show active-toolchain   # 1.98.1-aarch64-apple-darwin (overridden by '/private/tmp/audit-r27/pin1981/rust-toolchain.toml')
cargo fmt --version            # rustfmt 1.9.0-stable (48a229ceae 2026-09-01)
cargo clippy --version         # clippy 0.1.98 (48a229ceae 2026-09-01)
rustup component list --installed | grep -E '^(rustfmt|clippy)-'   # clippy-aarch64-apple-darwin, rustfmt-aarch64-apple-darwin
cargo fmt --all --check        # rc=0
```

The scratch crate then received the recommended `rustfmt.toml`, taken from `r27-workspace-scope.sh:53-58` (sha256 prefix `a714037d3cb89196`). Under it, `cargo fmt --all --check` gave `rc=0`, zero `can't set` warnings and empty output: C1.1 on the real pin value. I also took the C4.5 formatted sample from the rerun's scratch tree (`$TMPDIR/r27s/pin/out-1.93.0/lib.rs`, sha256 prefix `a251383e89c8906f`, with its `rustfmt.toml`). `rustup run 1.98.1 rustfmt --check lib.rs` gave `rc=0`, so the rustup 1.98.1 build agrees byte for byte with the four builds C4.5 compared.

**Ruling.** §5 is now satisfied for the pin value, not only for the pin mechanism. The sentence "That channel supplies rustfmt 1.9.0" is confirmed at source: the version string is `1.9.0-stable (48a229ceae 2026-09-01)`, and its commit hash matches Homebrew's rustc `48a229cea`. This observation is the auditor's and was made after the decision was written. The decision's "medium" uncertainty on the channel value is honest as written; the audit does not require any change to it.

## Non-blocking observations (no repair required for acceptance)

1. **`research/RUNBOOK.md` line numbers have drifted.** The file is modified in the working tree (mtime 19:56 local, after the decision's 18:24), and it differs from `HEAD`.
   - `RUNBOOK.md:83` is cited for the Fable synthesizer row. In the current file that row is line 87 and line 83 is the table header. At `HEAD`, line 83 is the empirical-auditor row.
   - `RUNBOOK.md:178` is cited for the controller lifting `BASELINE-REVIEW:` items. The current adjudication sentence is at line 183.
   Both claims are true in substance, and the section 1 citation `:18-22` is exact. A future revision could cite by section heading instead of line number.
2. **Only the one host was exercised.** macOS arm64 was the only OS, and no CI job ran. The decision states both gaps itself, in `## Empirical check` under "What no check here establishes". They are disclosed limits, not unsupported claims. The third gap it disclosed, the unexercised `1.98.1` value, is closed above.
3. **Two installed toolchains are not in the decision's table.** The host also has rustup toolchains `1.91.1` and `1.97.1` installed. The decision's toolchain table lists only the builds its checks used. This does not change any claim, and C4.2's `stable` → 1.94.0 resolution reproduced.

## Verdict

**approve.** All five scripts rerun cleanly. The three assertion logs that do not depend on time or the network are byte-identical to the committed logs. The remaining differences are timings and live counters that the decision does not cite. The recommended file bytes are the executed bytes, and every load-bearing figure I re-derived matched. The decision's claims about its own inputs are true: prerequisite hashes, parameter values and raw-report hashes. The recommended pin value `1.98.1` also executed under rustup in this audit.
