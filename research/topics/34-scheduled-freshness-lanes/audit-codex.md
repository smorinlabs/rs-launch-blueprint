decision-sha256: 14d3526106bb7e670fe648fe3bad9e858a92ddb196603fb49d9090bdc08fee4e
actor: audit-codex-2026-09-05T165440Z-d2e35904dc88-r1
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

`limactl shell ubuntu -- bash -lc '<probe>'` was callable, but the named VM could
not start: Lima failed to unlink `~/.lima/ubuntu/ha.stdout.log` with `operation not
permitted`. The probe therefore ran on macOS from a new two-file fixture, as the
task's fallback permits. The full argv and output are in
`review/evidence/audit-scheduled-freshness-lanes-r1.log`.

The executed Cargo argv were `cargo generate-lockfile`,
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow cargo generate-lockfile`, `cargo
update --breaking`, `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow cargo update
--workspace --dry-run`, and the same command without `--workspace` but with
`--verbose`. Cwd: a new `.r34-audit` fixture under this run directory, moved to
`/private/tmp` after the run. Toolchain: Homebrew `rustc 1.98.0` and `cargo 1.98.0`
on macOS arm64; the resolver documentation came from the installed rustup stable
book. Exit codes were 0, 0, 101, 0, and 0 respectively. The observed outcomes
match the decision's empirical results; the output is not byte-identical because
the host, toolchain, timestamp, and Cargo cache warnings differ.

## Findings

1. The load-bearing resolver claim reproduces. Default edition-2024 resolution
   with `rust-version = "1.85"` locked nine packages and selected
   `icu_locale_core 2.1.1`, reporting that 2.3.0 requires Rust 1.88. The override
   exited 0 and selected 2.3.0. The installed Cargo book also states that resolver
   version 3 is the edition-2024 default and changes the incompatible-Rust-version
   default from `allow` to `fallback`.
2. The narrowing is accurate. A lockfile diff between the fallback and override
   runs changes only `icu_locale_core`; the other eight of Cargo's reported nine
   locked packages are unaffected. `review/DECISION.md` makes no unqualified
   wider assertion. Its sole occurrence of “entire lane into a no-op” attributes
   that wording to the Opus raw and immediately rejects it as wider than the
   evidence.
3. The two independent runner-up checks reproduce. Stable `cargo update
   --breaking` exited 101 and reported that the flag is nightly-only.
   `cargo update --workspace --dry-run` with the override locked zero packages and
   named one unchanged dependency behind latest; plain `cargo update --verbose
   --dry-run` moved `icu_locale_core` from 2.1.1 to 2.3.0, both at exit 0.
4. The pinned TypeScript evidence is correct. At `cb1cbcb2`,
   `.github/workflows/ci.yml:141-188` contains `bun-lane`, its advisory name,
   `continue-on-error: true`, read-only permissions, the stated full-SHA Bun
   action pin, `bun-version: 1.3.14`, and the named Vitest command.
5. All four decision `assumes` values match the current
   `docs/port/PARAMETERS.md` value bytes exactly: `msrv-policy`, `rust-edition`,
   `target-os-matrix`, and `license`. No saved executable R34 empirical-check
   script exists; `resolver-fallback-chain.log` is recorded output, so there was
   no unrun script claim to reject. Five cited endpoints completed a successful
   curl spot-check; two slower Cargo documentation bodies timed out after an HTTP
   200 response and are retained in the evidence log, with successful replacement
   spot-checks for the pinned py workflow and the crates.io index.

## Assessment

Approve. The decision's recommendation depends on a real, reproduced resolver
split and its scope is limited to dependencies whose newer in-bounds versions
declare a Rust floor above the template's. The narrowing prevents the unsupported
claim that the fallback makes every freshness run inert. No workflow was written,
no schedule was created, and no issue was opened.
