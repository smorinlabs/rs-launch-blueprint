decision-sha256: 1a03361d22fa6f98c21a056e77835ad2287914e21530c021fcb5ea93fe0130cc
actor: audit-codex-2026-09-05T155503Z-4141a35b69e0-r2
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: `## Parameters` says alias shadowing is silent although the recorded and rerun Cargo output emits an explicit warning

## Rerun

`argv`: copied the three recorded `rust-toolchain.toml` fixtures and the alias fixture to `/private/tmp/r42-audit-r2.uO3ytz`, then ran the nine commands in decision check 9 in each fixture: `rustup show active-toolchain`; `command -v cargo-fmt`; `cargo fmt --version`; `command -v cargo-clippy`; `cargo clippy --version`; `rustup component list --installed | grep -q '^rustfmt-'`; `rustup component list --installed | grep -q '^clippy-'`; `rustup which cargo-fmt`; and `rustup which cargo-clippy`. The audit also reran the bare-name, built-in, alias-precedence, and `casey/just` checks required by the task.

`cwd`: `/private/tmp/r42-audit-r2.uO3ytz/{neg,pos,c196,alias}`; each fixture was an independent copy. `PATH` was `/Users/stevemorin/.cargo/bin:/usr/bin:/bin`, excluding Homebrew Rust.

`toolchain`: on macOS, rustup selected `1.97.1-aarch64-apple-darwin`, `stable-aarch64-apple-darwin`, and `1.96.0-aarch64-apple-darwin` from the respective copied `rust-toolchain.toml` files without installation. The same Linux VM matrix selected the corresponding `aarch64-unknown-linux-gnu` channels and matched the results. Selecting Linux `1.97.1` automatically installed that missing toolchain; no component, crate, or release tool was installed.

`exit code`: the macOS and Linux matrices matched the decision: both proxy lookups exited 0 in all three cells; component-state and `rustup which` results were rustfmt `1/0/0` and clippy `1/0/1` for neg/pos/c196; executable behavior agreed with those six results. The auxiliary alias and reference checks also exited as stated, except that the live crates.io version endpoint returned HTTP 403 (rate limit), which does not contradict the dated evidence log.

`log path`: `review/evidence/audit-dev-toolchain-provisioning-r2.log`.

`matches the decision`: Yes for the correction to rustup-component presence testing; bare proxy names; built-in subcommands; Cargo alias precedence; and `casey/just`'s `cargo-limit` binaries. No for the word "silently" in the alias rationale.

## Findings

### F1 — `## Parameters` misstates the observed alias behavior

At `review/DECISION.md:278`, the decision says that an alias "silently shadows a same-named external subcommand". Both the decision's own check 11 and this rerun show Cargo printing `warning: user-defined alias 'demo' is shadowing an external subcommand found at .../cargo-demo`, followed by the issue URL. The alias does take precedence, but the shadowing is explicitly warned about. Replace "silently shadows" with wording such as "takes precedence over and shadows"; retain the warning and future-hard-error evidence. This is a textual correction to the owned parameter, not a change to the recommendation or a request to implement P03 work.

## Assessment

Revision 2 fixes the revision-1 empirical defect. On a proxy-only `PATH`, `command -v cargo-fmt` and `command -v cargo-clippy` are vacuous because both names resolve to `rustup` in every cell. `rustup component list --installed` and `rustup which` accurately distinguish absent and installed components while honoring the directory toolchain override. The decision also correctly treats bare proxy names as the same hazard, recognizes built-in subcommands as executable-free, and corrects the earlier `casey/just` mistake: its `cargo lclippy` line dispatches to the `cargo-limit` binary installed by the same `justfile`, not a Cargo alias. The remaining explicit-warning wording must be corrected before approval.
