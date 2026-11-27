# P11 — Release automation binary distribution and packaging

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P10
- **Prior art:** [R23 lockfile-version-sync](../research/topics/23-lockfile-version-sync/DECISION.md)
- **Prior art:** [R24 changelog-section-mapping](../research/topics/24-changelog-section-mapping/DECISION.md)
- **Prior art:** [R26 packed-artifact-content-guard](../research/topics/26-packed-artifact-content-guard/DECISION.md)
- **Prior art:** [R68 release-binary-artifacts](../research/topics/68-release-binary-artifacts/DECISION.md)

**Status:** `[ ]` scoped, not started.

### Scope
Implement automated semantic releases, crates.io packaging guards, `cargo-dist` binary distribution, and GHCR container publishing:
- `release-please-config.json` (`release-type: "rust"` syncing `Cargo.lock` per `R23`, ordered 11-type changelog sections `feat`/`fix`/`perf`/`revert`/`docs` visible and 6 hidden per `R24`, `0.1.0` pre-major dampening per `R25`) + `.release-please-manifest.json` + `.github/workflows/release-please.yml`.
- `.github/workflows/publish.yml`: 4 first-party packed `.crate` content guards (`R26`), `cargo-semver-checks` (`R04`), and crates.io publish (credential/environment gated so missing token never breaks PRs).
- `cargo-dist 0.33.0` follower-mode binary releases (`create-release = false`, targets `x86_64-unknown-linux-gnu`, `x86_64-apple-darwin`, `aarch64-apple-darwin`, `installers = ["shell"]`, no `binstall`) and `[profile.release]` (`lto = "fat"`, `codegen-units = 1`) (`R68`).
- `.github/workflows/publish-container.yml`: publish `linux/amd64` container to `ghcr.io/smorinlabs/rs-launch-blueprint` on stable GitHub releases (`X.Y.Z` + `latest` + recorded `sha256` digest), formally recording the owner review-gate **OVERRIDE of `R51` (`1a-A`, 2026-11-27)** for full `py-launch-blueprint` `v4.2.0` parity.
- `docs/RELEASE.md` documenting the end-to-end release, crates.io, `cargo-dist`, and GHCR publishing flow.

### Out of scope
- Publishing an actual live release to crates.io or GHCR before `P13` completes
- `template-press` rebranding rules (`P12`)

### Tests & Tasks
- [ ] [P11-TS01] Add release & packaging meta-tests covering `release-please-config.json` 11-type section order (`R24`), packed `.crate` allow-list content checks (`R26`), `[profile.release]` settings (`R68`), `publish-container.yml` digest/tag wiring, and version consistency across workspace manifests
- [ ] [P11-T01] Add `release-please-config.json`, `.release-please-manifest.json`, and `.github/workflows/release-please.yml` (`R23`, `R24`, `R25`)
- [ ] [P11-T02] Add `[profile.release]` (`lto = "fat"`, `codegen-units = 1`), `cargo-dist 0.33.0` follower-mode configuration (`dist-workspace.toml`), and `.github/workflows/publish.yml` with the 4 packed-artifact guards and `cargo-semver-checks` (`R04`, `R26`, `R68`)
- [ ] [P11-T03] Add `.github/workflows/publish-container.yml` (recording owner review-gate OVERRIDE of `R51` for GHCR parity with `py-launch-blueprint`)
- [ ] [P11-T04] Write `docs/RELEASE.md` and verify `cargo package --locked --list`, `dist plan`, `actionlint`, `zizmor`, and release meta-tests all pass

### Deliverable
```bash
cargo package --locked --no-verify
actionlint && zizmor .github/workflows/
just check
```

### Automated Verification
- All 4 packed `.crate` content checks pass against `cargo package --locked`
- Release meta-tests, `actionlint`, `zizmor`, and `just check` exit 0
- Live GitHub Actions PR `ci-ok` passes green

### Manual Verification
- Review `docs/RELEASE.md` to confirm crates.io, `cargo-dist`, and GHCR release steps and required secrets/environments are documented accurately
