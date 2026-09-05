## Figures

No figures from the prompt's endpoint table were asserted in `raw/codex.md`. R23 evaluates release-process patterns, not a crate candidate; the report explicitly marks crates.io downloads, GitHub popularity and issue metrics, RustSec advisories, and issue responsiveness as inapplicable. No endpoint figure required re-querying.

| Result | Count |
|---|---:|
| ok | 0 |
| wrong | 0 |
| unverifiable | 0 |

## Gates

| Gate claim | Check | Result |
|---|---|---|
| Crate-specific license, MSRV, advisory, `unsafe`, feature/runtime, binary-size, compile-time, and crate-figure gates are inapplicable. | R23 selects a release-update pattern, not a crate or dependency tree. The prompt permits inapplicable metrics when their reason is stated, and the report states that reason. | ok |
| The applicable integration gate requires locked Cargo commands on `ubuntu-latest` and `macos-latest`. | Cargo's current `cargo build` documentation says `--locked` errors if Cargo would change `Cargo.lock` and identifies deterministic CI as its use case. This supports the proposed guard; the two-OS repository run remains planned, as the report says. | ok |
| A root workspace has one shared `Cargo.lock`. | The current Cargo workspace reference states that all workspace packages share the `Cargo.lock` file at the workspace root. | ok |

## References

| Recommendation or cited implementation | Check | Result |
|---|---|---|
| Native `release-type: rust` with `CargoLock` | The current `googleapis/release-please` HEAD exists (`c65408d9f68b2772e61dcdc4a8b6f5969bb4e1`). Its Rust strategy schedules `Cargo.lock` with `new CargoLock(versionsMap)`, and the updater matches package names and replaces their `version` fields. | ok |
| `cargo-workspace` for a manifest-mode Rust monorepo | The current release-please manifest guide documents the plugin, says it updates the Cargo lockfile, and calls it the recommended way to manage a Rust monorepo with release-please. | ok |
| Generic TOML `extra-files` as runner-up | The current release-please schema still accepts `extra-files`, including the TOML updater, and `GenericToml` still applies JSONPath-selected TOML version replacements. | ok |
| `release-plz` as an alternative | The `release-plz/release-plz` repository has a current reachable HEAD (`6ed9c1c6e5aa7b6005ff288cf7904f51e3c4a8e4`). It is an existing maintained reference, but the report correctly leaves it unselected because R23 fixes release-please as the release mechanism. | ok |

## Verdict

sound

Defects: none. The evidence supports the report's decision: commit the root `Cargo.lock` and let release-please's native Rust strategy update it in the release PR; do not add a redundant Cargo.lock JSONPath `extra-files` entry. The report appropriately distinguishes planned two-OS and end-to-end release-PR checks from executed evidence.
