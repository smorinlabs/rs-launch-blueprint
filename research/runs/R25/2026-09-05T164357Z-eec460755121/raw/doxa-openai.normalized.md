### Landscape

**Decision category:** public-compatibility maturity policy and automated SemVer projection for a new Rust package that exposes three surfaces: library API, CLI contract, and HTTP service.

#### Three-bin map

| Bin | Field map | Candidates found |
|---|---|---|
| **Built-in / first-party Rust toolchain** | `cargo new` initializes packages at `0.1.0`. Cargo’s default dependency requirements treat the left-most non-zero component as the compatibility boundary: `0.1.3` means `>=0.1.3,<0.2.0`, while `0.0.3` means `>=0.0.3,<0.0.4`. | **Cargo-Compatible Incubation Lane**: start at `0.1.0`; use the minor digit as the pre-1.0 breaking boundary and patch as the compatible-update lane. [S1–S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html)) |
| **Established industry standard** | SemVer defines `0.y.z` as initial development and `1.0.0` as the point where the public API is defined. Release Please implements standard, pre-major-dampened, and prerelease strategies. | (1) Cargo-Compatible Incubation Lane; (2) **Declared-Stable First Release** at `1.0.0`; (3) a `1.0.0-alpha.N` prerelease train; (4) pre-1.0 with only `bump-minor-pre-major`, leaving features as minor bumps. [S4–S8; retrieved 2026-09-09] ([semver.org](https://semver.org/)) |
| **Up-and-comer** | Effort Versioning maps numbers to expected migration effort and has visible adoption proposals outside Rust. ZeroVer catalogs long-lived `0.x` projects but explicitly identifies itself as satire and warns that indefinite prerelease status can hurt adoption. | EffVer was evaluated but is not compatible with Cargo’s resolver-visible SemVer contract or the fixed Release Please architecture. ZeroVer is treated as an anti-pattern warning, not a candidate. [S23–S24; retrieved 2026-09-09] ([docs.jax.dev](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai)) |

#### Authority used

- **Cargo and Rust project documentation** are first-party descriptions of generated manifests, dependency resolution, SemVer compatibility, application compatibility, editions, and MSRV declarations. These are controlling for how Rust consumers interpret `0.x` versions. [S1–S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html))
- **SemVer 2.0.0** is the normative cross-ecosystem standard. Its FAQ calls `0.1.0` the simplest initial-development starting point, but that FAQ is non-normative and does not override Cargo’s more specific pre-1.0 compatibility ranges. [S4; retrieved 2026-09-09] ([semver.org](https://semver.org/))
- **Release Please’s schema, design document, CLI documentation, and implementation source** are maintainer-owned primary evidence for the exact flags. Its design explicitly separates language strategies—such as Rust’s `Cargo.toml` updater—from the versioning strategy. [S5–S10; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai))
- **Rust API Guidelines and RFC 1105** describe the ecosystem’s interpretation of API stability. The guidelines are recommendations rather than mandates, but are authored largely from Rust library-team experience. RFC 1105 is authoritative historical policy for Rust SemVer compatibility. [S11–S12; retrieved 2026-09-09] ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/?utm_source=openai))
- **RFC 1242’s nursery model** is useful architectural evidence: incubation precedes a deliberate 1.0 stabilization decision. It is not a universal crate-release mandate. [S13; retrieved 2026-09-09] ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html?utm_source=openai))
- **The 2025 State of Rust Survey and compiler-performance survey** were used only to constrain integration cost: compile time and storage remain meaningful ecosystem concerns, favoring a policy and CI check that add no runtime dependency. They do not select the versioning policy by popularity. [S14; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai))
- **Effective Rust** supplies an independent caution: remaining `0.x` indefinitely collapses SemVer’s three impact classes into two resolver-visible classes. This is supporting commentary, not controlling authority. [S22; retrieved 2026-09-09] ([rustprojectprimer.com](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai))

#### Practice evidence

| Reference project | Observed practice | Why it is relevant |
|---|---|---|
| **Axum** | Maintained a `0.8.x` compatibility line while developing breaking work for `0.9`; its changelog labels breaking changes in the new minor line and records that an accidental breaking patch was yanked. | Direct web-framework analogue demonstrating that a Rust `0.x` minor can function as an effective major boundary while patches are expected to remain compatible. [S15; retrieved 2026-09-09] ([github.com](https://github.com/tokio-rs/axum?utm_source=openai)) |
| **Reqwest** | Remains on a `0.x` line despite substantial production use; its changelog places redesigns such as the async-default transition in a new minor line while compatible additions and fixes appear in patch releases. | Library and HTTP-client evidence for Cargo-aligned pre-1.0 compatibility lines. [S16; retrieved 2026-09-09] ([github.com](https://github.com/seanmonstar/reqwest/releases?utm_source=openai)) |
| **cargo-nextest** | A substantial CLI remains pre-1.0 while publishing an explicit stability and MSRV policy. | Shows that a production-quality CLI can legitimately incubate at `0.x`, provided its compatibility policy is explicit. [S19; retrieved 2026-09-09] ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai)) |
| **Tokio** | Used pre-1.0 releases, then announced 1.0 together with explicit stability guarantees. | Strong model for deliberate graduation: 1.0 represents a support promise, not elapsed time or a release counter. [S17; retrieved 2026-09-09] ([tokio.rs](https://tokio.rs/blog/2020-12-tokio-1-0?utm_source=openai)) |
| **Serde** | Reached 1.0 after being described as battle-tested in production and ready for a stable release. Rust’s API Guidelines also cite Serde release notes as examples. | Library evidence for graduating after the public contract is proven rather than assigning 1.0 automatically to a first publication. [S11, S18; retrieved 2026-09-09] ([users.rust-lang.org](https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466?utm_source=openai)) |
| **Rust itself** | Rust 1.0 explicitly began the project’s commitment to stability after an alpha phase. | High-level evidence for the meaning of 1.0 as a declared compatibility commitment. [S25; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2015/05/15/Rust-1.0/?utm_source=openai)) |

No popularity figure selected the result. These examples were weighted for direct architectural relevance to CLI, library, or web surfaces and for having documented stability behavior.

### Principles and implementation

#### Shared requirement and agreement level

The shared engineering principle is:

> **A version number is a consumer-facing compatibility contract whose numeric projection must match the package ecosystem’s resolver semantics and the project’s actual stability commitment.**

Agreement is required at four levels:

| Level | Required agreement across py, ts, and rs | May vary by ecosystem or history |
|---|---|---|
| **Capability** | Release Please derives releases from categorized changes and updates the canonical version source. | The canonical file and language updater. |
| **Standard** | Versions communicate compatibility using SemVer-compatible concepts. | Package-manager treatment of pre-1.0 ranges. |
| **Policy** | `1.0.0` means the maintainers are deliberately declaring the supported public contract stable. | Whether a repository has already crossed that boundary. |
| **Architectural pattern** | Language-specific file updating is separated from impact-to-version calculation. | Exact Release Please flags and validation tools. |

Therefore, literal equality of current version numbers or flags is **not** the required cross-language agreement level:

- The owner-supplied Python baseline at `2.4.2` can correctly retain ordinary post-1.0 semantics because it has an established post-1.0 history.
- The owner-supplied TypeScript baseline at `0.1.3` can correctly retain a dampened pre-major policy.
- Rust should select its value independently from Cargo semantics. Those semantics happen to support the same two boolean values as TypeScript, but for a Rust-specific reason: Cargo exposes `0.minor` as the compatibility line. No py or ts code change is part of R25.

The local py/ts facts and F070 classification came from owner-supplied repository paths for which no public URL was provided.

#### What Release Please’s two flags actually do

With the default versioning strategy:

| Current version | Commit impact | Both flags `true` | Cargo meaning |
|---|---:|---:|---|
| `0.1.3` | fix/other releasable change | `0.1.4` | Compatible update |
| `0.1.3` | `feat` | `0.1.4` | Compatible feature within the same Cargo range |
| `0.1.3` | breaking change | `0.2.0` | New incompatible Cargo range |
| `1.2.3` | fix | `1.2.4` | Standard SemVer patch |
| `1.2.3` | `feat` | `1.3.0` | Standard SemVer minor |
| `1.2.3` | breaking change | `2.0.0` | Standard SemVer major |

Specifically:

- `bump-minor-pre-major: true` changes a **breaking** pre-1.0 release from a major bump to a minor bump.
- `bump-patch-for-minor-pre-major: true` changes a pre-1.0 **feature** release from a minor bump to a patch bump.
- Fixes are patches with or without these flags.

This behavior is implemented in the generic default versioning strategy, not in the Node or Rust language updater. Release Please’s design and factory make versioning strategies independent of language strategies, so both flags apply identically to `release-type: rust`, `node`, or another language strategy when `versioning` remains `default`. [S5–S8; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai))

**BASELINE-REVIEW: F070 — resolver-aligned impact tiers must be described using Release Please’s actual algorithm — retain the pre-1.0 dampening pattern for rs, but correct any wording that says “feat bumps minor” when both flags are true to “breaking bumps minor; feat and fix bump patch” — Release Please schema, manifest documentation, and `DefaultVersioningStrategy` implementation.**

Affected items: R25 implementation and any F070 explanatory prose containing the incorrect mapping. The F070 `DIVERGENT` verdict need not change because Python remains post-1.0; no py or ts code change is authorized here. [S5–S7; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai))

#### Why this mapping is specifically appropriate for Cargo

Cargo considers a dependency declaration of `0.1.3` compatible with later `0.1.x` versions but not `0.2.0`. This differs from strict SemVer’s statement that all pre-1.0 APIs may change. Thus, for a Rust crate:

- numeric **minor** under `0.x` is the resolver-visible breaking boundary;
- numeric **patch** is the resolver-visible compatible-update channel;
- using a numeric minor for every feature would unnecessarily prevent automatic adoption of compatible additions;
- starting at `0.0.x` would be worse because Cargo treats each patch as a new incompatible line.

Cargo’s SemVer guide acknowledges that projects sometimes publish compatible “minor changes” as numeric patch releases and explicitly does not impose a universal minor-versus-patch convention for such changes. [S2–S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

This means `bump-patch-for-minor-pre-major` should not be understood as merely “dampening” npm behavior. In Rust it projects Conventional Commit categories onto Cargo’s two resolver-visible pre-1.0 compatibility classes.

#### Architectural alternatives

1. **Cargo-Compatible Incubation Lane — recommended.**  
   Start at `0.1.0`; breaking changes move to `0.(n+1).0`; compatible features and fixes advance `0.n.patch`; graduate manually to 1.0.

2. **Pre-1.0, features also bump minor.**  
   Set only `bump-minor-pre-major: true`. Both features and breaking changes then move from `0.1.x` to `0.2.0`. This is safe but overstates incompatibility and discards Cargo’s compatible patch lane for additive changes.

3. **Declared-Stable First Release.**  
   Publish `1.0.0` immediately and use ordinary SemVer. This preserves all three impact digits but represents an immediate stability promise over the library, CLI, and HTTP contracts.

4. **`1.0.0-alpha.N` prerelease train.**  
   This explicitly signals instability, but Cargo excludes prereleases unless consumers opt in and warns about prerelease dependencies in libraries. It introduces more resolver and release-automation complexity than `0.1.0` without improving this template’s compatibility model. [S2, S4, S26; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

#### Minimal reference implementation

`Cargo.toml`:

```toml
[package]
name = "rs-launch-blueprint"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"
```

Rust’s stable minor line is `1.98` as of September 9, 2026, so the fixed “stable minus two minor versions” policy currently derives `rust-version = "1.96"`. R25 consumes rather than owns that policy. [S21; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))

Bootstrap `release-please-config.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "rust",
      "versioning": "default",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true,
      "release-as": "0.1.0"
    }
  }
}
```

Before the first release:

```json
{}
```

After the first `0.1.0` release, remove the bootstrap-only `release-as` key. The steady-state package configuration is:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "rust",
      "versioning": "default",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true
    }
  }
}
```

Release Please documents `release-as` as an exact next-version override that must be removed or advanced after the Release PR is merged. Its manifest may be empty before the first release and then records the released version. Using this bootstrap avoids treating an unpublished `0.1.0` manifest entry as though it were already the last release. [S5, S10; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai))

#### Observable acceptance criteria

1. The first crates.io publication, Git tag, GitHub release, and `Cargo.toml` release value are all `0.1.0`.
2. From `0.1.0`, a `fix:` produces `0.1.1`.
3. From `0.1.0`, a `feat:` also produces `0.1.1`.
4. From `0.1.x`, a breaking commit produces `0.2.0`, never an automatic `1.0.0`.
5. A consumer requirement of `0.1.0` can resolve `0.1.1` but not `0.2.0`.
6. After an explicit graduation to `1.0.0`, ordinary SemVer resumes: fix → patch, feature → minor, breaking → major.
7. A library API break in a patch release is rejected by `cargo-semver-checks`.
8. CLI flag/config/output compatibility and HTTP route/schema compatibility have separate executable tests because Rust API tooling cannot inspect those surfaces.
9. An MSRV increase must reset patch and increase the numeric minor, satisfying the owner-fixed MSRV policy. Before 1.0 this can be represented by a breaking-marked commit or an explicit `Release-As`; CI should verify the resulting number rather than relying only on commit spelling.
10. All checks pass on `ubuntu-latest` and `macos-latest`.

#### Performance and integration cost

This policy adds **no runtime dependency, unsafe code, async-runtime coupling, binary-size cost, request latency, throughput cost, or production memory cost**. The Release Please flags alter only release-version selection.

The proposed `cargo-semver-checks` validation adds CI-only compilation and rustdoc/API-analysis work. The planned workload is the complete public library surface with all stable public features, measured under clean and warm caches on both required operating systems. Record wall-clock job duration, peak resident memory where available, and `target` directory size. No performance benchmark was executed in this research, and no “fastest” claim is made. [S14, S20; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/?utm_source=openai))

### Dominant choice

**Cargo-Compatible Incubation Lane**

A new published Rust package starts at `0.1.0`, treats `0.x` minor increments as compatibility breaks, treats patch increments as compatible releases, and reaches `1.0.0` only through an explicit stability-graduation decision.

Reference implementation: Release Please `release-type: rust`, `versioning: default`, both pre-major flags `true`, plus a bootstrap-only exact `release-as: 0.1.0`. Release Please is actively maintained; its current core release at retrieval was `v17.11.1`, published July 31, 2026. [S5–S10; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/releases?utm_source=openai))

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **Cargo-Compatible Incubation Lane** | Cargo default requirements and SemVer compatibility reference; Release Please pre-major flags | Axum for web APIs, Reqwest for an HTTP library, cargo-nextest for a CLI | Living Cargo docs retrieved 2026-09-09; Release Please `v17.11.1`, 2026-07-31. [S2–S3, S9, S15–S16, S19] |
| **Declared-Stable First Release** | SemVer 2.0; Rust API-stability guidance | Rust, Tokio, Serde each tied 1.0 to an explicit stability milestone | Living SemVer retrieved 2026-09-09; Tokio 1.0 write-up 2020-12-23. [S4, S11–S12, S17–S18, S25] |
| **Pre-1.0 with feature-minor releases** | SemVer FAQ’s simple pre-1.0 sequence; Release Please with only `bump-minor-pre-major` | Common outside Cargo; no stronger resolver-aligned Rust reference found than the alternatives above | Living SemVer and Release Please docs retrieved 2026-09-09. [S4–S7] |
| **`1.0.0-alpha.N` prerelease train** | SemVer prerelease clause; Cargo prerelease requirement rules | Rust’s 1.0 alpha process is a historical reference | Living Cargo docs retrieved 2026-09-09; Rust 1.0 alpha announcement 2015-01-09. [S2, S4, S25–S26] |

No download columns are included, as required.

### Excluded by gate

This item selects a **pattern**, not a runtime crate or bundle. Consequently the required crate figures—90-day downloads, all-time downloads, newest non-yanked release, repository stars, open-issue count, issue-response median, RustSec count, and reverse-dependency adopter enumeration—are **inapplicable**. Release Please is a fixed dependency from the supplied baseline and evidence for the reference implementation, not an alternative Rust crate selected by R25.

| Candidate | License | MSRV/dependency tree | RustSec/unsafe | OS matrix | Features/runtime | Size/compile cost |
|---|---|---|---|---|---|---|
| Cargo-Compatible Incubation | Pass/inapplicable: policy contains no code; Release Please source is Apache-2.0 | Pass: no Rust dependency added | Inapplicable; no Rust code or `unsafe` added | Pass subject to planned Ubuntu/macOS integration check | None | Zero production cost; CI check only |
| Declared-Stable First Release | Same | Same | Same | Same | None | Same |
| `1.0.0-alpha.N` | Same | Same | Same | Same | None | Same, but higher release/resolver complexity |
| EffVer | Same | Same | Same | Same | None | Same |

No shortlisted pattern failed the six dependency-oriented fitness gates before popularity was considered.

**Excluded after architectural fit:**

- **EffVer:** excluded because Cargo resolves dependencies using SemVer compatibility ranges, while the fixed Release Please configuration computes SemVer impact categories. EffVer would require a separately documented translation policy and would make dependency ranges less predictable. [S2, S23; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))
- **`1.0.0-alpha.N`:** excluded because prereleases require explicit Cargo opt-in and are awkward for library dependencies; this template gains no corresponding benefit over `0.1.0`. [S2, S26; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))
- **Indefinite ZeroVer:** excluded as a policy. Pre-1.0 must have explicit graduation criteria rather than becoming a permanent maturity disclaimer. ZeroVer itself identifies that adoption problem. [S22, S24; retrieved 2026-09-09] ([rustprojectprimer.com](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai))

Windows has no known numeric-versioning difference and is not blocked by the pattern, but remains outside the owner-fixed CI matrix.

### Up-and-comers

**Effort Versioning** is the credible up-and-comer. Its useful insight is that consumers care about migration effort, not merely syntactic API changes; JAX and Zarr have published concrete adoption rationales. That idea can inform release notes—especially for CLI migrations and HTTP changes—but it should not replace Cargo-compatible SemVer for a crates.io library. [S23; retrieved 2026-09-09] ([docs.jax.dev](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai))

**ZeroVer** is not an up-and-coming recommendation: it is intentionally satirical. Its real value here is the warning that a project should not remain `0.x` after it has a dependable, production-used contract. [S24; retrieved 2026-09-09] ([0ver.org](https://0ver.org/?utm_source=openai))

Alternative Rust release tools such as `release-plz` were not compared because whether to use Release Please is explicitly out of scope and owner-fixed.

### Fit for this template

#### CLI

Pre-1.0 provides room to revise flags, exit statuses, configuration precedence, generated text, and scripting behavior after real use. Cargo’s SemVer guide notes that executable interfaces require an explicit project policy because library API rules alone are insufficient. [S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html))

Acceptance must define which CLI behavior is contractual. At minimum: option names, required arguments, exit-status meanings, machine-readable output, config keys, and environment-variable precedence. A breaking change to any declared CLI contract should carry `!` and therefore move `0.n` to `0.(n+1)`.

#### Library

This is the strongest reason for the recommendation. Downstream Cargo consumers automatically interpret `0.1.x` as one compatibility line. Both flags align Release Please directly with that resolver behavior. The library’s public API should be checked with `cargo-semver-checks`, while public dependency types should be reviewed before 1.0 because the Rust API Guidelines advise that a stable crate’s public dependencies also be stable. [S2, S11, S20; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

#### Web service

The package version does not replace an HTTP API-versioning or migration policy. Nevertheless, starting pre-1.0 avoids claiming that routes, JSON schemas, authentication behavior, and error envelopes are already permanently supported before the service has real consumers.

HTTP compatibility should be verified with route/schema fixtures or generated OpenAPI diffs. A breaking HTTP contract change must trigger the same effective-major transition as a Rust library break: `0.n.x` → `0.(n+1).0`.

### Recommendation

Adopt **Cargo-Compatible Incubation Lane**:

- **Initial `Cargo.toml` version:** `0.1.0`
- **First published version:** `0.1.0`
- **Release type:** `rust`
- **Versioning strategy:** `default`
- **`bump-minor-pre-major`:** `true`
- **`bump-patch-for-minor-pre-major`:** `true`
- **1.0 behavior:** explicit graduation, never an incidental result of the first breaking commit
- **Bootstrap:** one-release-only `release-as: 0.1.0`, then remove it

This choice follows independently from Rust evidence:

1. Cargo itself initializes new packages at `0.1.0`. [S1; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html))
2. Cargo interprets `0.1.x` patches as compatible and `0.2.0` as incompatible. [S2; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))
3. The template has no published history or consumers requiring an immediate stability promise.
4. It exposes three independently evolving public surfaces, making a short, explicitly governed incubation period more credible than declaring all three stable on day one.
5. Release Please implements the necessary behavior without a custom strategy and identically supports it with `release-type: rust`. [S5–S8; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai))

The library nature pushes more strongly toward an initial `0.1.0` compatibility line than an application-only repository would. It does **not** justify staying pre-1.0 indefinitely.

Recommended 1.0 graduation criteria:

- no known planned redesign of the public Rust API;
- documented CLI and HTTP compatibility contracts;
- public dependencies reviewed for stability and exposure;
- library SemVer CI passing against the latest published baseline;
- representative consumer fixtures for library, CLI, and HTTP use;
- migration notes for any deprecated pre-1.0 interfaces;
- explicit owner approval to support compatible evolution without routine breaking releases.

### Ranked runner-up

**Declared-Stable First Release: `1.0.0` with ordinary SemVer.**

It wins if, before the first crates.io publication:

1. the Rust library API, CLI contract, and HTTP contract are intentionally declared stable;
2. no material breaking redesign is expected;
3. public dependencies exposed in the API are considered sufficiently stable;
4. compatibility tests cover all three surfaces;
5. the owner is prepared to treat future incompatibilities as `2.0.0`, not as routine early iteration.

Under those conditions, `Cargo.toml` should begin at `1.0.0` and both pre-major flags should be omitted. SemVer permits this; absence of earlier consumers does not prohibit a well-considered 1.0. [S4, S11–S12, S17–S18, S25; retrieved 2026-09-09] ([semver.org](https://semver.org/))

### Tradeoffs

| Alternative | What the recommendation gives up | Why accepted |
|---|---|---|
| **Immediate `1.0.0`** | Full three-digit impact expressivity from the first release; stronger maturity signal; fewer organizational objections to adopting a `0.x` library | The template has no published compatibility history and has three public surfaces likely to benefit from real-consumer feedback |
| **Pre-1.0 with feature-minor bumps** | Numeric distinction between compatible features and fixes | Cargo cannot preserve that distinction while also keeping compatible features in the consumer’s current `0.n` range; the changelog still distinguishes them |
| **`1.0.0-alpha.N`** | Explicit `alpha` label and an obvious path toward final 1.0 | Cargo prereleases require explicit opt-in and add resolver/release complexity for library consumers |
| **EffVer** | Numbers that attempt to predict migration effort | Cargo and Release Please consume SemVer impact categories; release notes can communicate effort without replacing resolver semantics |
| **Indefinite `0.x`** | Freedom to break forever without a clear graduation event | Accepted only temporarily; explicit graduation criteria prevent the ZeroVer trap |

A notable cost is that under `0.x`, compatible features and bug fixes both advance the patch digit. This is the unavoidable price of mapping three Conventional Commit categories onto Cargo’s two pre-1.0 compatibility classes. Changelog sections and commit types retain the lost distinction.

### Parameters

`owns release-version-regime = pre-1.0 Cargo-compatible incubation`

`owns initial-package-version = 0.1.0`

`owns first-published-version = 0.1.0`

`owns bump-minor-pre-major = true`

`owns bump-patch-for-minor-pre-major = true`

`owns pre-1.0-graduation = explicit/manual release to 1.0.0`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes version-source-of-truth = Cargo.toml [package].version`

No `CONFLICT:` applies.

As of September 9, 2026, the fixed MSRV formula evaluates to Rust `1.96`, based on the current stable `1.98` minor line. This derived value must be recalculated if implementation occurs after the next stable minor release. [S21; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))

### Migration implications

1. **`Cargo.toml`**
   - Set `[package].version = "0.1.0"`.
   - Preserve edition `2024` and dual license.
   - Set or verify `rust-version = "1.96"` when implementing on September 9, 2026; do not treat R25 as ownership of the MSRV policy.

2. **`release-please-config.json`**
   - Use `release-type: rust`.
   - Set `versioning: default` explicitly.
   - Add both pre-major flags as `true`.
   - Add bootstrap-only `release-as: "0.1.0"` if Release Please owns the first publication.
   - Remove `release-as` immediately after the first Release PR is merged.
   - On graduation to 1.0, remove both flags for clarity, although current implementation makes them inert at versions `>=1.0.0`.

3. **`.release-please-manifest.json`**
   - Keep `{}` before the first Release Please-managed publication.
   - Expect Release Please to record `"." : "0.1.0"` after the first release.
   - Do not seed an unpublished `0.1.0` as though it were already the last released version without an integration test.

4. **`Cargo.lock`**
   - If committed, verify that the Release PR leaves the root package version consistent with `Cargo.toml`; do not assume this without a fixture test.

5. **Release-policy documentation**
   - Document that, before 1.0, minor means incompatible and patch means compatible.
   - Document that both `feat` and `fix` normally produce a patch before 1.0.
   - Define CLI, Rust API, and HTTP compatibility surfaces.
   - Add the 1.0 graduation checklist.

6. **CI**
   - Add a version-policy test for the Release Please matrix.
   - Add `cargo-semver-checks` for the published library surface.
   - Add CLI and HTTP compatibility tests.
   - Add a guard that an MSRV change is accompanied by a numeric minor increase.

7. **`docs/port/COMMONALITY.md`**
   - Append R25 evidence to F070 and correct any inaccurate feature-bump wording.
   - Do not silently change F070’s `DIVERGENT` verdict or modify py/ts implementation.

8. **py and ts**
   - No file changes in this item.
   - Follow-on rationale: Python’s post-1.0 state is justified by release history; TypeScript and Rust may share pre-major flags while retaining ecosystem-specific explanations and explicit graduation criteria.

### Validation strategy

**Executed during this research:** documentary verification of Cargo, SemVer, Release Please schema/design/source, and representative project policies. No repository checkout, GitHub release fixture, Rust build, or publication command was executed.

**Planned executable checks:**

#### 1. Manifest and fixed-parameter check

```bash
cargo metadata --no-deps --format-version 1 |
  jq -e '
    .packages[]
    | select(.name == "rs-launch-blueprint")
    | .version == "0.1.0"
      and .edition == "2024"
      and .rust_version == "1.96"
  '
```

Expected: exit status zero.

```bash
cargo +1.96.0 check --all-targets --all-features
cargo +stable test --workspace --all-targets --all-features
cargo +stable publish --dry-run
```

Expected: all pass on both required operating systems.

#### 2. Release Please schema validation

```bash
npx --yes ajv-cli@5 validate \
  -s https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json \
  -d release-please-config.json
```

Expected: configuration validates, including both flags and `release-type: rust`.

#### 3. First-release fixture

In a throwaway GitHub repository using the exact pinned Release Please version:

```bash
npx release-please@17.11.1 release-pr \
  --repo-url="$FIXTURE_REPO" \
  --target-branch=bootstrap \
  --token="$RP_TOKEN" \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json
```

Expected Release PR:

- version `0.1.0`;
- `Cargo.toml` remains or becomes `0.1.0`;
- manifest becomes `0.1.0`;
- tag produced after merge is `v0.1.0` under the separately owned tag policy.

Repeat with isolated branches and manifests to prove:

| Base | Commit | Expected |
|---|---|---|
| `0.1.0` | `fix: correct parser` | `0.1.1` |
| `0.1.0` | `feat: add library helper` | `0.1.1` |
| `0.1.3` | `feat(api)!: replace response type` | `0.2.0` |
| `0.9.4` | breaking commit | `0.10.0`, not `1.0.0` |
| `1.0.0` | fix | `1.0.1` |
| `1.0.0` | feat | `1.1.0` |
| `1.0.0` | breaking commit | `2.0.0` |

#### 4. Cargo resolver acceptance

Publish fixture versions to a disposable Cargo registry, then:

```bash
cargo new /tmp/r25-consumer
cd /tmp/r25-consumer
cargo add rs-launch-blueprint@0.1.0 --registry acceptance

cargo update \
  -p rs-launch-blueprint \
  --precise 0.1.1
```

Expected: succeeds.

```bash
cargo update \
  -p rs-launch-blueprint \
  --precise 0.2.0
```

Expected: fails because the consumer’s default `0.1.0` requirement excludes `0.2.0`.

#### 5. Library API compatibility

For a compatible feature fixture:

```bash
cargo semver-checks --baseline-rev v0.1.0
```

Expected: passes when current version is `0.1.1`.

For an API-removal fixture:

- at `0.1.1`: expected failure;
- after changing the package version to `0.2.0`: expected success as an intentionally incompatible release.

`cargo-semver-checks` uses crates.io or an explicit revision/version as its baseline and supports a GitHub Action with configurable baseline and release type. [S20; retrieved 2026-09-09] ([github.com](https://github.com/obi1kenobi/cargo-semver-checks?utm_source=openai))

#### 6. CLI and web compatibility

```bash
cargo test --test cli_contract
cargo test --test http_contract
```

The fixtures should assert:

- documented flags and exit statuses;
- stable machine-readable output;
- config and environment precedence;
- route/method inventory;
- request/response schema compatibility;
- error status and error-envelope compatibility.

A deliberately breaking CLI or HTTP fixture must require a breaking Conventional Commit and produce `0.(n+1).0`.

#### 7. MSRV-release coupling

Add a CI script comparing the merge base with the Release PR:

```bash
./scripts/check-msrv-version-coupling.sh \
  --base "$BASE_SHA" \
  --head "$HEAD_SHA"
```

Expected: if `package.rust-version` changes, the package’s minor digit must increase and patch reset to zero. A patch-only proposed version must fail.

#### 8. Performance instrumentation

For the SemVer job, record:

```bash
/usr/bin/time -v cargo semver-checks --baseline-rev "$BASELINE_TAG"
du -sh target
```

Run once with a clean cache and once with a warm cache on Ubuntu and macOS. These measurements are CI-cost evidence only; no product request-path benchmark is applicable.

### Confidence & re-verify trigger

**Confidence: high** that Rust should begin at `0.1.0` with both flags enabled. Cargo’s resolver semantics and Release Please’s implementation align directly.

**Confidence: medium-high** in the exact first-release bootstrap composition until the pinned Release Please version is run against a fixture. The bootstrap-only `release-as` is chosen because its documented semantics are an exact next-version override.

Re-verify if any of the following occurs:

- Release Please changes or deprecates either pre-major flag;
- the project selects a non-default Release Please versioning strategy;
- Cargo changes its left-most-non-zero compatibility rules;
- `rs-launch-blueprint` stops publishing a library crate and becomes application-only;
- the owners can demonstrate that all three public contracts are stable before first publication;
- a public dependency prevents satisfying the proposed 1.0 graduation criteria;
- the current Rust stable minor changes before implementation, requiring the derived `rust-version` to be recalculated;
- the project approaches 1.0 or remains `0.x` despite production adoption and no planned breaking work.

### Sources

All web sources were retrieved **2026-09-09**.

| ID | Source URL | Authority/relevance |
|---|---|---|
| S1 | https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html | First-party `cargo new` output showing `0.1.0` and edition 2024. ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html)) |
| S2 | https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html | First-party Cargo compatibility ranges and prerelease behavior. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)) |
| S3 | https://doc.rust-lang.org/cargo/reference/semver.html | First-party Cargo SemVer and application-compatibility guidance. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html)) |
| S4 | https://semver.org/ | Normative SemVer 2.0.0 specification and FAQ. ([semver.org](https://semver.org/)) |
| S5 | https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md | Maintainer documentation for manifests, initial releases, `release-as`, and pre-major flags. ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai)) |
| S6 | https://github.com/googleapis/release-please/blob/main/schemas/config.json | Maintainer schema defining both flags generically. ([github.com](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai)) |
| S7 | https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts | Primary implementation of the exact bump matrix. ([github.com](https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts?utm_source=openai)) |
| S8 | https://github.com/googleapis/release-please/blob/main/docs/design.md | Maintainer architecture separating language and versioning strategies. ([github.com](https://github.com/googleapis/release-please/blob/main/docs/design.md?utm_source=openai)) |
| S9 | https://github.com/googleapis/release-please/releases | Current Release Please release history; `v17.11.1` dated 2026-07-31. ([github.com](https://github.com/googleapis/release-please/releases?utm_source=openai)) |
| S10 | https://github.com/googleapis/release-please/blob/main/docs/cli.md | Maintainer CLI options for initial version and pre-major flags. ([github.com](https://github.com/googleapis/release-please/blob/main/docs/cli.md?utm_source=openai)) |
| S10a | https://github.com/googleapis/release-please-action | Maintainer action documentation and configuration mapping. ([github.com](https://github.com/googleapis/release-please-action?utm_source=openai)) |
| S11 | https://rust-lang.github.io/api-guidelines/necessities.html | Rust library-team-derived stable-public-dependency guidance. ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/necessities.html)) |
| S12 | https://rust-lang.github.io/rfcs/1105-api-evolution.html | Rust RFC defining API-evolution/SemVer principles. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1105-api-evolution.html?utm_source=openai)) |
| S13 | https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html | Historical Rust incubation-to-1.0 architectural precedent. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html?utm_source=openai)) |
| S14 | https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/ | Current annual Rust survey context. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai)) |
| S14a | https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/ | Compile-time and resource-cost evidence. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/?utm_source=openai)) |
| S15 | https://github.com/tokio-rs/axum | Maintained web-framework reference. ([github.com](https://github.com/tokio-rs/axum?utm_source=openai)) |
| S15a | https://github.com/tokio-rs/axum/blob/main/axum/CHANGELOG.md | Axum compatibility-line and accidental-breaking-patch evidence. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/CHANGELOG.md?utm_source=openai)) |
| S16 | https://github.com/seanmonstar/reqwest/releases | Maintained pre-1.0 HTTP-library reference. ([github.com](https://github.com/seanmonstar/reqwest/releases?utm_source=openai)) |
| S16a | https://github.com/seanmonstar/reqwest/blob/master/CHANGELOG.md | Reqwest breaking-minor and compatible-patch practice. ([github.com](https://github.com/seanmonstar/reqwest/blob/master/CHANGELOG.md?utm_source=openai)) |
| S17 | https://tokio.rs/blog/2020-12-tokio-1-0 | Maintainer 1.0 stability announcement. ([tokio.rs](https://tokio.rs/blog/2020-12-tokio-1-0?utm_source=openai)) |
| S17a | https://tokio.rs/blog/2020-10-tokio-0-3 | Maintainer description of the path and guarantees required for 1.0. ([tokio.rs](https://tokio.rs/blog/2020-10-tokio-0-3?utm_source=openai)) |
| S18 | https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466 | Serde 1.0 readiness announcement. ([users.rust-lang.org](https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466?utm_source=openai)) |
| S19 | https://github.com/nextest-rs/nextest | Maintained pre-1.0 CLI with explicit stability/MSRV policy. ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai)) |
| S19a | https://www.nexte.st/changelog/ | Current nextest release practice. ([nexte.st](https://www.nexte.st/changelog/?utm_source=openai)) |
| S20 | https://github.com/obi1kenobi/cargo-semver-checks | Maintainer documentation for library API compatibility validation. ([github.com](https://github.com/obi1kenobi/cargo-semver-checks?utm_source=openai)) |
| S20a | https://github.com/obi1kenobi/cargo-semver-checks-action | Maintainer Action inputs and baseline/release-type support. ([github.com](https://github.com/obi1kenobi/cargo-semver-checks-action?utm_source=openai)) |
| S21 | https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/ | Rust Release Team announcement for the current stable minor line. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)) |
| S21a | https://blog.rust-lang.org/ | Rust Blog index showing the subsequent `1.98.1` patch announcement on 2026-09-03. ([blog.rust-lang.org](https://blog.rust-lang.org/?utm_source=openai)) |
| S22 | https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf | Independent warning about indefinite `0.x` reducing SemVer expressivity. ([rustprojectprimer.com](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai)) |
| S23 | https://jacobtomlinson.dev/effver/ | Original EffVer proposal. ([jacobtomlinson.dev](https://jacobtomlinson.dev/effver/?utm_source=openai)) |
| S23a | https://docs.jax.dev/en/latest/jep/25516-effver.html | Concrete maintained EffVer adoption proposal. ([docs.jax.dev](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai)) |
| S23b | https://zarr.dev/blog/versioning-with-effver/ | Production-project EffVer rationale. ([zarr.dev](https://zarr.dev/blog/versioning-with-effver/?utm_source=openai)) |
| S24 | https://0ver.org/ | ZeroVer catalogue. ([0ver.org](https://0ver.org/?utm_source=openai)) |
| S24a | https://0ver.org/about.html | Explicit satire notice and real-world warning about indefinite prerelease status. ([0ver.org](https://0ver.org/about.html?utm_source=openai)) |
| S25 | https://blog.rust-lang.org/2015/05/15/Rust-1.0/ | Rust Core Team explanation that 1.0 begins the stability commitment. ([blog.rust-lang.org](https://blog.rust-lang.org/2015/05/15/Rust-1.0/?utm_source=openai)) |
| S25a | https://blog.rust-lang.org/2015/01/09/Rust-1.0-alpha/ | Historical prerelease architecture reference. ([blog.rust-lang.org](https://blog.rust-lang.org/2015/01/09/Rust-1.0-alpha/?utm_source=openai)) |
| S26 | https://rust-lang.github.io/rfcs/3493-precise-pre-release-cargo-update.html | First-party Cargo prerelease resolver analysis. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/3493-precise-pre-release-cargo-update.html?utm_source=openai)) |

## Sources

- [Creating a new project - The Rust Edition Guide](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html)
- [Semantic Versioning 2.0.0 | Semantic Versioning](https://semver.org/)
- [JEP 25516: Effort-based versioning for JAX — JAX documentation](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai)
- [release-please/schemas/config.json at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai)
- [About - Rust API Guidelines](https://rust-lang.github.io/api-guidelines/?utm_source=openai)
- [1242-rust-lang-crates - The Rust RFC Book](https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html?utm_source=openai)
- [2025 State of Rust Survey Results | Rust Blog](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai)
- [up a CI check (Item 32) that detects changes, using tooling (e.g., `cargo-deny`; see Item 25) as needed.](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai)
- [GitHub - tokio-rs/axum: HTTP routing and request-handling library for Rust that focuses on ergonomics and modularity · GitHub](https://github.com/tokio-rs/axum?utm_source=openai)
- [Releases · seanmonstar/reqwest · GitHub](https://github.com/seanmonstar/reqwest/releases?utm_source=openai)
- [GitHub - nextest-rs/nextest: A next-generation test runner for Rust. · GitHub](https://github.com/nextest-rs/nextest?utm_source=openai)
- [Announcing Tokio 1.0 | Tokio - An asynchronous Rust runtime](https://tokio.rs/blog/2020-12-tokio-1-0?utm_source=openai)
- [Serde and serde_json 1.0.0 released - announcements - The Rust Programming Language Forum](https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466?utm_source=openai)
- [Announcing Rust 1.0 | Rust Blog](https://blog.rust-lang.org/2015/05/15/Rust-1.0/?utm_source=openai)
- [release-please/docs/manifest-releaser.md at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai)
- [Specifying Dependencies - The Cargo Book](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [Announcing Rust 1.98.0 | Rust Blog](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)
- [Rust compiler performance survey 2025 results | Rust Blog](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/?utm_source=openai)
- [Releases · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/releases?utm_source=openai)
- [ZeroVer: 0-based Versioning — zer0ver](https://0ver.org/?utm_source=openai)
- [SemVer Compatibility - The Cargo Book](https://doc.rust-lang.org/cargo/reference/semver.html)
- [GitHub - obi1kenobi/cargo-semver-checks: Scan your Rust crate for semver violations. · GitHub](https://github.com/obi1kenobi/cargo-semver-checks?utm_source=openai)
- [release-please/src/versioning-strategies/default.ts at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts?utm_source=openai)
- [release-please/docs/design.md at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/docs/design.md?utm_source=openai)
- [release-please/docs/cli.md at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/docs/cli.md?utm_source=openai)
- [GitHub - googleapis/release-please-action: automated releases based on conventional commits · GitHub](https://github.com/googleapis/release-please-action?utm_source=openai)
- [Necessities - Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html)
- [1105-api-evolution - The Rust RFC Book](https://rust-lang.github.io/rfcs/1105-api-evolution.html?utm_source=openai)
- [axum/axum/CHANGELOG.md at main · tokio-rs/axum · GitHub](https://github.com/tokio-rs/axum/blob/main/axum/CHANGELOG.md?utm_source=openai)
- [reqwest/CHANGELOG.md at master · seanmonstar/reqwest · GitHub](https://github.com/seanmonstar/reqwest/blob/master/CHANGELOG.md?utm_source=openai)
- [Announcing Tokio 0.3 and the path to 1.0 | Tokio - An asynchronous Rust runtime](https://tokio.rs/blog/2020-10-tokio-0-3?utm_source=openai)
- [Changelog - cargo-nextest](https://www.nexte.st/changelog/?utm_source=openai)
- [GitHub - obi1kenobi/cargo-semver-checks-action: A GitHub Action for running cargo-semver-checks · GitHub](https://github.com/obi1kenobi/cargo-semver-checks-action?utm_source=openai)
- [The Rust Programming Language Blog](https://blog.rust-lang.org/?utm_source=openai)
- [EffVer: Version your code by the effort required to upgrade - Jacob Tomlinson](https://jacobtomlinson.dev/effver/?utm_source=openai)
- [Versioning Zarr with EffVer | Zarr Blog](https://zarr.dev/blog/versioning-with-effver/?utm_source=openai)
- [About — zer0ver](https://0ver.org/about.html?utm_source=openai)
- [Announcing Rust 1.0 Alpha | Rust Blog](https://blog.rust-lang.org/2015/01/09/Rust-1.0-alpha/?utm_source=openai)
- [3493-precise-pre-release-cargo-update - The Rust RFC Book](https://rust-lang.github.io/rfcs/3493-precise-pre-release-cargo-update.html?utm_source=openai)
