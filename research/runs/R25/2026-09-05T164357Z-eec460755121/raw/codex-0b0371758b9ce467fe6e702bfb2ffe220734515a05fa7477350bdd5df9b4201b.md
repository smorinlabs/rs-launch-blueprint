### Landscape

R25 selects a release policy, not a crate. Crate downloads/releases, dependency-tree MSRV, RustSec, `unsafe`, feature/runtime coupling, binary size, and compile time are therefore inapplicable to every candidate; no popularity ranking is used. Retrieved 2026-09-05.

| Field bin | Candidate | Evidence |
|---|---|---|
| Built-in / first-party | Cargo `0.y.z` convention | Cargo treats the left-most non-zero component as the incompatibility boundary; `0.1.0` admits updates below `0.2.0`, and `y` may serve as major during initial development. [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements); [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) (retrieved 2026-09-05). |
| Established | `0.1.0` plus both release-please pre-major flags | Maintainer docs and schema describe generic flags accepted with `release-type: rust`. [Manifest documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md); [schema](https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json) (retrieved 2026-09-05). |
| Established | `1.0.0` plus ordinary SemVer | Cargo's ordinary terminology applies at 1.0.0 and later. [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) (retrieved 2026-09-05). |
| Up-and-comer, complementary | `cargo-semver-checks` | It detects API SemVer violations but cannot select numeric bump policy. [README](https://github.com/obi1kenobi/cargo-semver-checks) (retrieved 2026-09-05). |

The Cargo Book is first-party authority, release-please docs/schema are authority for the flags, and the Rust API Guidelines reflect Library Team experience. [Cargo](https://doc.rust-lang.org/cargo/), [release-please](https://github.com/googleapis/release-please/tree/main/docs), and [API Guidelines](https://rust-lang.github.io/api-guidelines/) (retrieved 2026-09-05).

As practice references, Axum is currently `0.8.9` and Tokio `1.53.1`; their `crate.recent_downloads` values were 113,586,445 and 218,779,510. They demonstrate maintained, widely adopted examples on either side of 1.0, not a universal starting-version rule. [Axum manifest](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml), [Tokio manifest](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml), [Axum endpoint](https://crates.io/api/v1/crates/axum), and [Tokio endpoint](https://crates.io/api/v1/crates/tokio) (retrieved 2026-09-05).

### Principles and implementation

The shared requirement is an auditable release capability: manifest version, Conventional-Commit release PR, changelog, and publication tag. It is shared at the capability/pattern level in F063, F066, and F073. F070 is `ts-only` and `DIVERGENT`, so its starting-number policy is not a required shared value. [Ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/COMMONALITY.md#L69-L80) (retrieved 2026-09-05).

Cargo's default `0.1.12` requirement is `>=0.1.12, <0.2.0`; a `0.1.0` release therefore promises compatibility within `0.1.z`. [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements) (retrieved 2026-09-05). The selected flags produce that exact mapping: compatible `fix:` and `feat:` changes become a patch; a `BREAKING CHANGE` becomes a minor. Starting from `0.1.0`, expected releases are `0.1.1` and `0.2.0`. The prompt's shorthand reverses the flags: `bump-minor-pre-major` applies to breaking changes and `bump-patch-for-minor-pre-major` to features. [release-please CLI](https://github.com/googleapis/release-please/blob/main/docs/cli.md) (retrieved 2026-09-05).

Both are supported in Rust configuration: the schema has no release-type restriction and the customization guide lists `rust` for Cargo.toml repositories. A project dry-run is still required to prove integration. [Schema](https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json) and [customization guide](https://github.com/googleapis/release-please/blob/main/docs/customizing.md) (retrieved 2026-09-05). All six crate fitness gates and runtime performance metrics are inapplicable because this policy adds no crate or runtime code; it preserves the owner-fixed edition, MSRV, license, and Ubuntu/macOS requirements. [Parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/PARAMETERS.md#L5-L18) (retrieved 2026-09-05).

The TS config enables both flags while pre-1.0; the Python config is post-1.0 and omits them. Those configurations are evidence, not the winner. [TS config](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/release-please-config.json#L3-L7), [Python config](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/release-please-config.json), and [D-021](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/docs/port/TS_PORT_DECISIONS.md#L249-L257) (retrieved 2026-09-05).

No `BASELINE-REVIEW:` line is emitted: F070 is an open `DIVERGENT` decision, not a retained baseline being challenged.

### Dominant choice

Use Cargo-aligned pre-1.0 compatibility: publish `0.1.0`, use `release-type: rust`, and enable both flags.

```json
{"release-type":"rust","bump-minor-pre-major":true,"bump-patch-for-minor-pre-major":true}
```

It withholds a 1.0 stability promise until the new library and web contracts have earned it, while giving Cargo users a truthful compatibility signal now. [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) and [release-please configuration](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) (retrieved 2026-09-05).

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| `0.1.0` + both flags | [Cargo](https://doc.rust-lang.org/cargo/reference/semver.html); [release-please](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) (retrieved 2026-09-05). | TS blueprint uses the exact pair; Axum is an active `0.y` Rust reference, not release-tool evidence. [TS config](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/release-please-config.json#L3-L7); [Axum](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml) (retrieved 2026-09-05). | release-please `main`, retrieved 2026-09-05. |
| `0.1.0` defaults | [release-please](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) says both default false (retrieved 2026-09-05). | No Rust adopter of this exact setting was verified. | release-please `main`, retrieved 2026-09-05. |
| `1.0.0` standard SemVer | [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) (retrieved 2026-09-05). | Tokio's `1.53.1` is a mature reference, not proof a fresh template should start there. [Tokio](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml) (retrieved 2026-09-05). | Cargo Book, retrieved 2026-09-05. |

### Excluded by gate

None: policies cannot fail crate license, MSRV, RustSec, OS, feature/runtime, or build-cost gates. The unmodified pre-1.0 default is rejected on semantic fit, not a gate, because its normal feature-minor bump crosses Cargo's incompatible `0.y` boundary. [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements) and [release-please CLI](https://github.com/googleapis/release-please/blob/main/docs/cli.md) (retrieved 2026-09-05).

### Up-and-comers

`cargo-semver-checks` is a validation adjunct that locates public-API SemVer violations. It neither selects a release number nor replaces release-please, so it is outside R25's implementation scope. [README](https://github.com/obi1kenobi/cargo-semver-checks) (retrieved 2026-09-05).

### Fit for this template

**CLI:** incompatible command/flag changes get visible `0.y` bumps without runtime cost. **Library:** this is decisive because Cargo accepts `0.1.z` but rejects `0.2.0` for a `0.1.0` requirement. **Web:** release numbers cannot prove HTTP compatibility, but the same incompatible-change signal avoids a conflicting repository policy. The web conclusion is an inference from Cargo's resolver model, not a Cargo HTTP promise. [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements) and [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) (retrieved 2026-09-05).

### Recommendation

Start `rs-launch-blueprint` at `0.1.0`; use `release-type: rust`; enable both flags. Compatible fixes/features advance `z`, incompatible public changes advance `y`, and `1.0.0` remains a later explicit stability decision. [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) and [release-please schema](https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json) (retrieved 2026-09-05).

### Ranked runner-up

Start `1.0.0` with standard SemVer and omit both flags. It wins only if the owner accepts a documented long-term compatibility commitment for library, CLI, and public web contracts before first publication, supported by the other items' acceptance checks. [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) (retrieved 2026-09-05).

### Tradeoffs

Against post-1.0, the choice withholds a stability signal; that is accepted because the new three-surface template has not yet demonstrated it. Against default pre-1.0 behavior, compatible features receive patch rather than minor releases; that is accepted because Cargo treats `0.y` change as incompatible. [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements) and [release-please CLI](https://github.com/googleapis/release-please/blob/main/docs/cli.md) (retrieved 2026-09-05).

### Parameters

owns: none. assumes `rust-edition = 2024`; `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `license = MIT OR Apache-2.0`; `target-os-matrix = ubuntu-latest, macos-latest`. No fixed parameter changes. [Parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/PARAMETERS.md#L5-L18) (retrieved 2026-09-05).

No `CONFLICT:` line is emitted.

### Migration implications

Set `[package] version = "0.1.0"` in `Cargo.toml`; set `release-type: rust` and the two flags in `release-please-config.json`; initialize `.release-please-manifest.json` at `0.1.0` if manifest mode requires it, without creating a competing version source. [Release survey](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/areas/release-versioning.md#L7-L15) and [F063](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/COMMONALITY.md#L69-L76) (retrieved 2026-09-05). At a deliberate stability milestone, use release-please's `release-as` for `1.0.0` and remove inert pre-major flags. [Manifest configuration](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) (retrieved 2026-09-05).

### Validation strategy

**Planned, not executed.** In a disposable implemented-template fixture with baseline `0.1.0` and both flags true, dry-run release-please against `fix:` (expect `0.1.1`), `feat:` (expect `0.1.1`), and `feat!:` (expect `0.2.0`) histories. Then assert Cargo resolution for `version = "0.1.0"` admits `0.1.1` and rejects `0.2.0`; run the eventual `ubuntu-latest` and `macos-latest` matrix. [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements), [release-please CLI](https://github.com/googleapis/release-please/blob/main/docs/cli.md), and [parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/PARAMETERS.md#L5-L10) (retrieved 2026-09-05).

### Confidence & re-verify trigger

High confidence in the Cargo-to-flag semantic mapping; medium confidence in integration until the project dry-run. Re-verify if release-please changes the schema/flag behavior, Rust manifest-mode support changes, or the owner elects a first-release `1.0.0` promise. [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html) and [release-please schema](https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json) (retrieved 2026-09-05).

### Sources

- [Cargo requirements](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#default-requirements) and [Cargo SemVer](https://doc.rust-lang.org/cargo/reference/semver.html), first-party sources, retrieved 2026-09-05.
- [release-please manifest configuration](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md), [CLI options](https://github.com/googleapis/release-please/blob/main/docs/cli.md), [customization guide](https://github.com/googleapis/release-please/blob/main/docs/customizing.md), and [schema](https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json), maintainer sources, retrieved 2026-09-05.
- [Axum endpoint](https://crates.io/api/v1/crates/axum), [Tokio endpoint](https://crates.io/api/v1/crates/tokio), [TS config](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/release-please-config.json), and [R25 ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/5a99cd5c73c15d1a898b72acfb688ffffeaff581/docs/port/COMMONALITY.md#L69-L80), retrieved 2026-09-05.

Method notes: queried `https://crates.io/api/v1/crates/axum` and `https://crates.io/api/v1/crates/tokio` on 2026-09-05 for `crate.recent_downloads`. No crates.io `/versions`, GitHub repository, GitHub issue-search, or RustSec endpoints were queried because R25 selects a policy rather than a crate. A GitHub REST implementation-source probe returned HTTP 403, so this report relies on public maintainer documentation and schema, not an unverified internal-code path.
