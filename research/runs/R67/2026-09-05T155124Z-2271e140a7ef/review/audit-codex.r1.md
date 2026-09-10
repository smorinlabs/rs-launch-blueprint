decision-sha256: 4c7ea6e604bd899a47cf75a3a9e05ef752fd694f6ed9c4446ccc1b391346f97d
actor: audit-codex-2026-09-05T155124Z-2271e140a7ef
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: E13/E14 fixture-result mismatch: the reviewed three-manifest workspace locks 20 packages and scans 22 crate dependencies, has no etcetera dependency, but DECISION.md claims 22 locked packages, etcetera at Rust 1.87.0 as the highest dependency, and 23 crates scanned

## Rerun

I reran E1--E14 from the run directory on the supplied Linux VM with `limactl shell ubuntu -- bash -s`, after `source "$HOME/.cargo/env"`. The complete argv, stdout, stderr, exit codes, and the temporary-copy boundary are in `review/evidence/audit-error-and-exit-code-contract.log`.

The VM had no `gh` executable and no `cargo audit` subcommand. The log preserves those exact-command failures (`127` and `101`), then records equivalent public GitHub REST reads for E2--E4 and E9 and a temporary, VM-local `cargo-audit 0.22.1` installation for E14. Those substitutions verify the cited public data but are not presented as exact `gh` reruns.

The original `review/empirical/rslb-contract` contains exactly its three `Cargo.toml` files and `.gitignore`; it has no Rust source. Cargo cannot load a package with no target, so E13/E14 use a copied workspace in `/tmp` with two empty target stubs solely to parse the manifests. No template source was added, built, or run. The Linux toolchain and all rerun exits are logged. Source and API checks E1--E12 support their respective, limited claims: current registry figures, repository state, issue counts, package/advisory state, published-tarball APIs, Rust 1.96.0 source behavior, standards text, and reference-source reads. They do not establish any P03 runtime acceptance criterion.

## Findings

1. **Decision evidence must change — E13/E14 numeric and dependency claims are not reproducible from the reviewed fixture.** `review/DECISION.md:434-435` says the recommended pins locked 22 packages, had `etcetera` 1.87.0 as the highest dependency, and audited 23 crates. The copied three-manifest workspace instead reports `Locking 20 packages to latest Rust 1.96 compatible versions`; its resolved normal tree contains `anyhow`, `thiserror`, `serde_json`, and Unix `signal-hook`, but no `etcetera`; `cargo audit` reports `Scanning Cargo.lock for vulnerabilities (22 crate dependencies)`. The decision's result came from the different one-package manifest recorded in `review/evidence/dependency-resolution.log`, which added `etcetera = "0.11.0"`; that manifest is not the reviewed fixture. The MSRV and license gates still pass for the reviewed graph, and `cargo tree -d` remains empty, but the reported figures and `etcetera` conclusion must be corrected or the fixture changed to match before approval.

2. **The RustSec page 404 is valid zero-advisory evidence only with its paired controls.** For `thiserror`, `signal-hook`, `ctrlc`, and `inquire`, `https://rustsec.org/packages/<name>.html` returned 404; the same endpoint returned 200 for `anyhow`, whose page is backed by `RUSTSEC-2026-0190`. The RustSec advisory-db API independently returns 404 for each absent `crates/<name>` directory and 200 with `RUSTSEC-2026-0190.md` for `anyhow`. Thus the decision's claim is supported: this is an intentional no-advisory route, not a broken endpoint. The 404 alone would not prove that.

3. **E6--E7 support the crate-selection claims and no runtime claim.** The published `ctrlc 3.5.2` tarball defines `set_handler<F>` with `F: FnMut()` and documents one handler for SIGINT/SIGTERM/SIGHUP with `termination`; it cannot distinguish 130 from 143 at callback dispatch. The published `signal-hook 0.4.4` tarball exposes `flag::register(signal: c_int, flag: Arc<AtomicBool>)`, and `inquire 0.9.4` exposes `OperationCanceled` and `OperationInterrupted`. These are source-interface findings only; they do not demonstrate signal, prompt, EPIPE, flushing, or destructor behavior in a template.

4. **The decision correctly leaves the eight P03 items unproven.** It expressly states that it executed no template runtime behavior on any platform and limits AC1--AC8, signal cleanup, prompt reachability, web shutdown, crash-record behavior, append-only enforcement, and real build-size measurements to P03. This is not a finding against the decision.

## Assessment

The decision is appropriately research-only and the raw-engine accounting is accurate: codex and opus are present, OpenAI and Gemini normalized reports have the required fields, and Perplexity lacks exactly `Parameters`, `Migration implications`, `Validation strategy`, and `Confidence & re-verify trigger`, as `doxa/normalization.json` records. E1--E12 and the E14 advisory control substantiate the source-level and dependency-version conclusions within their stated limits. However, E13/E14 claim results for a manifest that is not the reviewed three-manifest fixture. Update the empirical table, gate discussion, and re-verify trigger to the fixture's 20-package lock / 22 scanned dependencies and remove the `etcetera` claim, or make the fixture intentionally include it and rerun. Until then, `unresolved-findings` is not `none`.
