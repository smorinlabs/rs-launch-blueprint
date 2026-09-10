# R25 — Pre-1.0 semver bump strategy (pattern, Deep) — raw report (engine: opus)

Item: R25 · kind `pattern` · ledger row F070 (`docs/port/COMMONALITY.md:76`), verdict `DIVERGENT`, origin `ts-only`.
All figures and quotations were retrieved 2026-09-09 (local clock; the `curl` calls ran 2026-09-09 19:50–20:00 US/Pacific = 2026-09-10 02:50–03:00 UTC). Every date below is the 2026-09-09 local retrieval date.

### Landscape

**The category this item decides.** Not "which release tool", and not "where the version field lives". The category is *pre-1.0 version-bump semantics under conventional-commit release automation for a crates.io-published Rust package*: given a Conventional-Commits history and an automated bumper, which digit each commit type moves while the major digit is `0`, and what the first published version is. The decision surface is exactly three artifacts: `Cargo.toml`'s `[package] version`, `.release-please-manifest.json`'s seed entry, and the `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` keys in `release-please-config.json`.

**Three-bin map of the Rust field.**

| Bin | Members found | What each contributes to this decision |
|---|---|---|
| Built-in / first-party toolchain | Cargo's SemVer compatibility reference; Cargo's default (caret) version-requirement resolver; `cargo new`'s emitted manifest; Cargo's `initial-version`-free manifest schema | Defines what a `0.y.z` number *means* to the resolver and to every consumer, and what version a brand-new crate starts at |
| Established industry standard | Semantic Versioning 2.0.0 (semver.org); Conventional Commits; release-please v17.11.2 (`release-type: rust`) driven by `googleapis/release-please-action` v5.0.0 (the tool already fixed for this repo by ledger rows F063/F066/F073, `COMMON → REUSE`) | Supplies the automation whose flags this item sets, and the versioning grammar those flags implement |
| Up-and-comer | release-plz 0.3.164 (Rust-native conventional-commit release automation, `release-plz/release-plz`); cargo-semver-checks 0.50.0 (`obi1kenobi/cargo-semver-checks`) | An independent Rust-native implementation of the same decision — used here as corroborating evidence about what Rust considers correct — plus the tool that makes the chosen policy *checkable* rather than merely declared |

Every candidate in `### Options` comes from this map. No candidate was admitted on familiarity.

**Authoritative sources used, and why each counts as authority.**

| Source | Why authoritative | Retrieved |
|---|---|---|
| The Cargo Book, *SemVer Compatibility* — `https://doc.rust-lang.org/cargo/reference/semver.html` | The Rust project's own normative statement of what constitutes a breaking change and how `0.y.z` maps onto major/minor. Published by the Cargo team, shipped with the toolchain. | 2026-09-09 |
| The Cargo Book, *Specifying Dependencies* — `https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html` | Normative description of the resolver rule every consumer of this crate will be subject to. | 2026-09-09 |
| Rust API Guidelines, *Necessities* (C-STABLE) — `https://raw.githubusercontent.com/rust-lang/api-guidelines/master/src/necessities.md` | Rust library-team working-group output; the ecosystem's checklist for what a crate must satisfy to call itself stable. | 2026-09-09 |
| Semantic Versioning 2.0.0 — `https://semver.org/` | The specification both release-please and Cargo cite as their grammar. | 2026-09-09 |
| release-please source at tag `v17.11.2` — `src/versioning-strategies/default.ts`, `src/strategies/rust.ts`, `src/strategies/base.ts`, `src/strategies/python.ts`, `src/manifest.ts`, `schemas/config.json`, `docs/manifest-releaser.md` (all under `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/`) | The maintainers' own implementation and schema — the only authority on what the two flags actually do. A blog post about them would be a lead; this is the behaviour. | 2026-09-09 |
| release-plz documentation — `https://raw.githubusercontent.com/release-plz/release-plz/main/website/docs/config.md` and `.../semver-check.md` | Maintainers' documentation for an independent, Rust-native implementation of this exact decision; it states a Cargo-SemVer-conformance rule in its own words. | 2026-09-09 |
| `npm/node-semver` README, *Caret Ranges* — `https://raw.githubusercontent.com/npm/node-semver/main/README.md` | The reference implementation of npm's range semantics; required to answer the HIGH question comparing Rust's `0.x` interpretation against the one ts's choice was made under. | 2026-09-09 |

**Well-regarded Rust projects surveyed, with the evidence that they are well regarded.** Twenty-one widely-used crates were queried for their current stable version. Adoption is evidenced by `crate.downloads` and `crate.recent_downloads` from `GET https://crates.io/api/v1/crates/<name>` and by `stargazers_count` from `GET https://api.github.com/repos/<o>/<r>`, all retrieved 2026-09-09 — not asserted. This is a hand-picked panel of crates a CLI + library + web-service template would plausibly depend on, not a census of crates.io.

| Crate | Current stable | 90-day downloads | All-time downloads | GitHub stars (repo) |
|---|---|---|---|---|
| `rand` | **0.10.2** | 417,978,614 | 1,676,774,028 | 2,075 (`rust-random/rand`) |
| `thiserror` | 2.0.20 | 350,390,985 | 1,436,032,398 | — |
| `serde` | 1.0.229 | 297,704,333 | 1,373,386,943 | 10,809 (`serde-rs/serde`) |
| `regex` | 1.13.1 | 240,607,879 | 1,138,490,825 | — |
| `clap` | 4.6.6 | 224,892,790 | 1,118,375,802 | 16,695 (`clap-rs/clap`) |
| `tokio` | 1.53.1 | 218,334,421 | 952,090,463 | 33,101 (`tokio-rs/tokio`) |
| `anyhow` | 1.0.104 | 206,068,310 | 942,920,266 | — |
| `hyper` | 1.11.1 | 196,326,297 | 904,456,736 | — |
| `toml` | 1.1.5+spec-1.1.0 | 209,913,032 | 891,178,308 | — |
| `tracing` | **0.1.44** | 184,984,766 | 834,126,366 | 6,867 (`tokio-rs/tracing`) |
| `reqwest` | **0.13.5** | 176,974,511 | 703,012,641 | 11,815 (`seanmonstar/reqwest`) |
| `tower` | **0.5.3** | 166,590,898 | 649,418,467 | — |
| `tracing-subscriber` | **0.3.23** | 138,624,068 | 595,767,173 | 6,867 (same repo as `tracing`) |
| `axum` | **0.8.9** | 112,813,910 | 461,946,996 | 27,070 (`tokio-rs/axum`) |
| `indicatif` | **0.18.6** | 46,831,488 | 214,013,632 | — |
| `sqlx` | **0.9.0** | 35,504,192 | 143,538,794 | 17,460 (`transact-rs/sqlx`) |
| `clap_complete` | 4.6.9 | 27,155,443 | 111,378,210 | 16,695 (same repo as `clap`) |
| `config` | **0.15.25** | 17,700,610 | 112,009,454 | — |
| `ratatui` | **0.30.2** | 17,661,058 | 49,899,089 | 22,537 (`ratatui/ratatui`) |
| `utoipa` | 5.5.0 | 13,942,235 | 45,130,351 | — |
| `figment` | **0.10.19** | 9,360,973 | 37,379,529 | — |

Bolded rows are pre-1.0. Eleven of the twenty-one — including `axum` (27,070 stars, 461.9M downloads, still `0.8.x` four years after its 2021-07-22 crates.io debut) and `tracing` (834.1M downloads, still `0.1.x` since 2017-11-27) — are pre-1.0 while carrying nine-figure download counts. Two further data points: `cargo-semver-checks`, the ecosystem's standard API-compatibility checker, is itself `0.50.0` (616,353 all-time downloads, `GET https://crates.io/api/v1/crates/cargo-semver-checks`, retrieved 2026-09-09); `release-plz`, the Rust-native release automation tool, is `0.3.164` (63,381 90-day and 349,173 all-time downloads, `GET https://crates.io/api/v1/crates/release-plz`, retrieved 2026-09-09). **Fit-relevant conclusion: in Rust, a `0.x` version carries no maturity stigma and does not suppress adoption.** That is a materially different social fact from the one that governs, say, a Python application.

### Principles and implementation

**Correction to this prompt's description of the flags — stated once, applied throughout.** `## Questions` (prompt line 28) glosses the flags as "feat commits bump the minor digit, not major; fix commits bump patch even under a `0.x` minor". The maintainers' source and schema say something different, and this report uses the source semantics:

- `bump-minor-pre-major` — schema description: *"Breaking changes only bump semver minor if version < 1.0.0"* (`schemas/config.json`, `definitions/ReleaserConfigOptions/properties/bump-minor-pre-major`, tag `v17.11.2`, retrieved 2026-09-09). Docs prose: *"BREAKING CHANGE only bumps semver minor if version < 1.0.0"* (`docs/manifest-releaser.md:173-175`).
- `bump-patch-for-minor-pre-major` — schema description: *"Feature changes only bump semver patch if version < 1.0.0"*. Docs prose: *"feat commits bump semver patch instead of minor if version < 1.0.0"* (`docs/manifest-releaser.md:177-179`).

The implementation confirms both. `DefaultVersioningStrategy.determineReleaseType` (`src/versioning-strategies/default.ts`, v17.11.2, retrieved 2026-09-09) branches: `if (breaking > 0) { if (version.isPreMajor && this.bumpMinorPreMajor) return new MinorVersionUpdate(); else return new MajorVersionUpdate(); } else if (features > 0) { if (version.isPreMajor && this.bumpPatchForMinorPreMajor) return new PatchVersionUpdate(); else return new MinorVersionUpdate(); } return new PatchVersionUpdate();`, with `isPreMajor` defined as `this.major < 1` (`src/version.ts:86-88`). So `fix` always moves the patch digit; the two flags govern `feat` and breaking commits respectively, and both are inert once the major digit reaches 1. The prompt's gloss would in fact describe option (D) below, which this report rejects.

**The shared requirement, its source, and its agreement level.**

- *Principle*: **the published version number must tell the consuming package manager's resolver the truth about compatibility, so that a routine dependency update never silently pulls a breaking change and a compatible release is never withheld.**
- *Source*: F063/F066/F073 (`COMMON → REUSE`) fix release-please as the sole bumper across py, ts and rs; D-021(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md:253`, read from the pinned clone at `cb1cbcb`) records the ts instantiation. `docs/port/areas/release-versioning.md:F070` records ts-only origin.
- *Agreement level*: **capability/standard.** What must agree across the three repos is the capability — *an automated bumper whose output is correct under the host ecosystem's own compatibility rule*. What may vary is the low-level flag setting, because the compatibility rule itself differs per ecosystem, and because the flags are no-ops above 1.0.0.

**Essential behaviours (what "correct" means here).** For every release the automation cuts:
1. A commit that breaks the public API must move whichever digit the host resolver treats as the incompatibility boundary.
2. A commit that only adds API must move a digit the resolver treats as compatible, so existing consumers receive it without editing their manifests.
3. A `fix` must move the smallest digit.
4. The first published version must be one the ecosystem reads as an accurate stability claim.

**Observable acceptance criteria.**
- A0. `cargo new` parity: the template's initial `[package] version` equals the version a fresh Rust package starts at.
- A1. Given history `fix:` only, the next version differs from the current only in the patch digit.
- A2. Given a non-breaking `feat:`, the next version is within the current caret band — i.e. a consumer whose `Cargo.toml` says `rs-launch-blueprint = "<current>"` resolves to it with no manifest edit.
- A3. Given a `feat!:` / `BREAKING CHANGE:`, the next version leaves the current caret band, so no consumer receives it automatically.
- A4. No release promotes the crate across the `0.x → 1.x` boundary without an explicit human act.

**What Cargo's compatibility rule actually is, and why it settles the Rust case.** The Cargo Book's SemVer reference states: *"This guide uses the terms 'major' and 'minor' assuming this relates to a '1.0.0' release or later. Initial development releases starting with '0.y.z' can treat changes in 'y' as a major release, and 'z' as a minor release. '0.0.z' releases are always major changes. This is because Cargo uses the convention that only changes in the left-most non-zero component are considered incompatible."* (`https://doc.rust-lang.org/cargo/reference/semver.html`, retrieved 2026-09-09.) The resolver enforces it: *"Versions are considered compatible if their left-most non-zero major/minor/patch component is the same. This is different from SemVer which considers all pre-1.0.0 packages to be incompatible."* — with the worked table `0.2.3 := >=0.2.3, <0.3.0`, `0.0.3 := >=0.0.3, <0.0.4`, and the note that *"Caret requirements are the default version requirement strategy… Leaving off the caret is a simplified equivalent syntax"* (`https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html`, retrieved 2026-09-09).

Map the four essential behaviours onto that rule at a `0.y.z` version, and the required bump table is: `fix → z`, non-breaking `feat → z`, breaking `→ y`. That is *exactly* `bump-minor-pre-major: true` **and** `bump-patch-for-minor-pre-major: true`. The correspondence is arithmetic, not stylistic.

**HIGH question — does Cargo's `0.x` interpretation differ from the npm interpretation ts's choice was made under? Arithmetically, no; normatively, yes.** Set the two resolvers' worked examples side by side. Cargo: `0.2.3 := >=0.2.3, <0.3.0` and `0.0.3 := >=0.0.3, <0.0.4` (*Specifying Dependencies*, retrieved 2026-09-09). npm: `^0.2.3 := >=0.2.3 <0.3.0-0` and `^0.0.3 := >=0.0.3 <0.0.4-0`, described as *"Allows changes that do not modify the left-most non-zero element in the `[major, minor, patch]` tuple"* (`npm/node-semver` README, *Caret Ranges*, retrieved 2026-09-09). **The compatibility band is identical**, modulo npm's prerelease-exclusion suffix. Both flags are therefore equally correct arithmetic under both resolvers, and ts's choice does not need re-deriving on that ground. Three differences are real, and all three push Rust harder toward the pre-major dampening rather than away from it:

- *Cargo's SemVer reference makes `0.y`-as-major normative, and says so while departing from the strict specification*: *"Versions are considered compatible if their left-most non-zero major/minor/patch component is the same. This is different from SemVer which considers all pre-1.0.0 packages to be incompatible."* semver.org's own item 4 says only that under `0.y.z` *"Anything MAY change at any time"* — it grants no compatibility band at all. Cargo grants one and defines it.
- *Caret is Cargo's only default; there is no exact-pin default.* *"Caret requirements are the default version requirement strategy… Leaving off the caret is a simplified equivalent syntax to using caret requirements"*, and the Cargo Book recommends the bare form. So a consumer who writes `rs-launch-blueprint = "0.1"` — the idiomatic spelling — is inside the `>=0.1.0, <0.2.0` band whether or not they thought about ranges. In npm the bare `"0.2.3"` in a hand-written `package.json` is an exact pin, and the caret arrives because `npm install` writes one; the npm README's own framing is that *"Many authors treat a `0.x` version as if the `x` were the major 'breaking-change' indicator"* — an author-side reading of a resolver rule, where Cargo's is the toolchain's stated convention.
- *Rust's own guidelines and tooling build on the rule*: C-STABLE conditions stability on public dependencies (below), and release-plz labels the contrary setting a violation of Cargo's SemVer rules (above). npm has no equivalent published rule tying a `0.x` number to a guideline or a tool's warning.

Practical consequence for this item: the flags ts set are correct in Rust for the same arithmetic reason, and additionally supported by normative Rust documentation that has no npm counterpart. Nothing about Cargo's interpretation argues for the *opposite* setting.

**Architectural alternatives compared, not just flag settings.** Three genuinely different architectures answer this requirement, and they were compared before any flag was chosen.

1. *Commit-derived automated bump with ecosystem-aware pre-major dampening* (release-please with both flags; release-plz 0.3.164's default). The version is a pure function of commit history plus a policy declared in configuration. Integration cost: two JSON keys. Dependability: the policy is machine-enforced on every release, so it cannot drift with maintainer attention.
2. *Commit-derived automated bump with no dampening, launched at 1.0.0*. The same machine, with the pre-major branch never taken. Correct by construction — but only because it asserts a stable public API from the first commit, which is a claim about the code, not about the tooling.
3. *API-diff-derived bump* (release-plz + `cargo-semver-checks`): the tool inspects the compiled public API against the previous release and bumps on what actually changed rather than on what the commit message said. Strictly more accurate; strictly more machinery, a second release tool, and a per-release compile of two revisions. Out of scope to adopt here (the release tool is fixed by F063/F066/F073), but its *policy* is admissible evidence and its checker is adoptable as a CI gate without changing the release tool — see `### Validation strategy`.

Architecture 1 is chosen. Architecture 3's checker is added as a gate, which recovers most of its accuracy benefit at CI cost only.

**Corroboration from an independent Rust-native implementation.** release-plz reaches the identical policy from first principles and says so in its own documentation. Its `features_always_increment_minor` field: *"If `true`, feature commits will always bump the minor version, even in 0.x releases. If `false` (default), feature commits will only bump the minor version starting with 1.x releases."* — followed by a warning attached to the `true` setting: *"This option violates the Cargo SemVer rules because the transition from `0.x` to `0.(x+1)` is used for breaking changes. Instead, new features for `0.x` should bump the version from `0.x.y` to `0.x.(y+1)`."* (`https://raw.githubusercontent.com/release-plz/release-plz/main/website/docs/config.md`, §*The `features_always_increment_minor` field*, retrieved 2026-09-09.) release-plz's default equals `bump-patch-for-minor-pre-major: true`; and its breaking-change behaviour — *"When release-plz detects API breaking changes, it updates the version of the package with a 'major semver Bump'. For example… `release_plz_core` version from `0.4.21` to `0.5.0`"* (`.../semver-check.md`, retrieved 2026-09-09) — equals `bump-minor-pre-major: true`. Two independently built tools, one conclusion. Note also that release-plz *documents the opposite setting as a rules violation*; this is the strongest available statement that the setting is not a matter of taste in Rust.

**Rust-specific fact that removes ts's main implementation cost.** release-please's `Rust` strategy overrides the initial version: `protected initialReleaseVersion(): Version { return Version.parse('0.1.0'); }` (`src/strategies/rust.ts`, v17.11.2 — and identically at v17.6.0, the floor of the action's `"release-please": "^17.6.0"` dependency in `googleapis/release-please-action` v5.0.0's `package.json`; both retrieved 2026-09-09). The base class returns `1.0.0` unless the `initial-version` config key is set (`src/strategies/base.ts:756-761`). `python.ts:200-202` also returns `0.1.0`; `node.ts` has no override and therefore inherits `1.0.0`. **`release-type: rust` starts a brand-new crate at `0.1.0` with no seeding, no `initial-version` key and no hand-written manifest entry.** ts had to seed by hand precisely because `node` is the outlier: its first release-please commit `19ff9b5` ("feat: add release-please + npm publish pipeline") set `package.json` to `0.1.0` and `.release-please-manifest.json` to `{".": "0.1.0"}` in the same commit (read from the pinned ts clone).

**Flag support is release-type-agnostic — the MEDIUM question answered directly.** The two flags are plumbed identically for every release type. `src/manifest.ts:1395-1396` maps `config['bump-minor-pre-major']` → `bumpMinorPreMajor` and `config['bump-patch-for-minor-pre-major']` → `bumpPatchForMinorPreMajor`; lines 1748-1752 apply per-package overrides falling back to the top-level defaults; `src/factories/versioning-strategy-factory.ts:41` builds `new DefaultVersioningStrategy(options)` for the `default` versioning type. `Rust extends BaseStrategy` and does not override `versioningStrategy`, so `BaseStrategy`'s `this.versioningStrategy = options.versioningStrategy || new DefaultVersioningStrategy(...)` (`base.ts:138-140`) applies. **Both flags are supported identically for `rust` and for `node`; nothing about them is Node-specific.** (All files at tag `v17.11.2`, retrieved 2026-09-09.)

**HIGH question — which principles must be preserved across py, ts and rs; what is drift and what is justified difference.** The principle above (truthful compatibility signalling) is preserved in all three, at capability/standard level. The apparent divergence recorded in F070 is not drift:

- **py has no flags because they cannot fire.** py adopted release-please already post-1.0: the first commit adding `release-please-config.json` and `.release-please-manifest.json` is `1bd0344` (2026-05-24, "feat: release-please cluster"), and that commit's manifest reads `{".": "1.0.0"}` (read from the pinned py clone at `b08bccf`). Every branch the two flags guard is gated on `version.isPreMajor` (`major < 1`), so setting them in py would have changed nothing. py's absence of the keys is **inherited state, not a design decision, and not accidental drift.**
- **ts has both flags because it launched pre-1.0 in an ecosystem with the same `0.x` caret band.** ts's config sets both (`release-please-config.json:6-7`, pinned clone at `cb1cbcb`); its manifest reads `{".": "0.1.3"}`.
- **rs is in ts's starting position, in an ecosystem where the pre-major rule is stronger, not weaker.** the two resolvers enforce the same `0.x` compatibility band, but Cargo additionally makes `0.y`-as-major normative in its own reference and reachable through the default, bare version-requirement syntax, and Rust's guidelines and release tooling build on that rule (see the HIGH-question paragraph above). So the same low-level value is recommended for rs, and it is recommended on Rust's own evidence rather than by inheritance.

Recommending the same low-level value for ts and rs is therefore justified under the owner's A5 test: the evidence supports the same tradeoff in both ecosystems independently. py needs no change; it is already correct, and would remain correct if the keys were added.

**A defect in the recorded ts rationale, worth flagging for the follow-on project.** D-021(1)'s decision text names only `bump-minor-pre-major` (`TS_PORT_DECISIONS.md:253`), while ts's shipped config sets both flags. The one-flag configuration is a real and materially different policy — see option (D) — so the decision record understates what ts actually does. This is a documentation gap in ts, not a fitness finding about rs.

**No `BASELINE-REVIEW:` finding is emitted.** F070 is `DIVERGENT`, not `COMMON → REUSE` or `ADOPT`, so it is not a baseline row; and the analysis above confirms rather than challenges the recorded principle behind F063/F066/F073. Nothing in the `docs/port/BASELINE-REVIEW.md` REUSE/ADOPT set is contradicted by this answer.

**Cross-item note (not a conflict).** release-please's `Rust` strategy unconditionally appends a `CargoLock` updater for `Cargo.lock` with `createIfMissing: false`, alongside the `CargoToml` updater (`src/strategies/rust.ts`, v17.11.2, retrieved 2026-09-09). That is directly relevant to **R23 / F065 (lockfile version sync in the release commit)**, whose py analogue needs an explicit `extra-files` jsonpath entry (`py: release-please-config.json`, pinned clone). R23 is already marked `resolved` in `research/CLAUDE.md`; R25 consumes no parameter from it and does not decide it. R23 should simply confirm its decision matches release-please's built-in lock updater rather than duplicating it. This is a note, not a `CONFLICT:` line.

**Minimal realistic example.** A single-crate workspace at `Cargo.toml` `[package] version = "0.1.0"`, `.release-please-manifest.json` `{".": "0.1.0"}`, `release-please-config.json` with `"release-type": "rust"`, `"include-v-in-tag": true`, `"bump-minor-pre-major": true`, `"bump-patch-for-minor-pre-major": true`. Three commits are pushed to `main` in turn — `fix: correct exit code`, `feat: add --json output`, `feat!: rename the ProjectsPort trait` — and the Release PR's proposed version is read after each. Expected: `0.1.1`, then `0.1.2`, then `0.2.0`. The executable form of this check, and what was actually run, is in `### Validation strategy`.

### Dominant choice

**Launch pre-1.0 at `0.1.0` under `release-type: rust`, with `bump-minor-pre-major: true` and `bump-patch-for-minor-pre-major: true`** — option (A) below.

It is dominant on three independent grounds, each evidenced above rather than asserted:

1. **Arithmetic conformance.** Under Cargo's "left-most non-zero component" rule, that flag pair is the unique setting that makes each commit type move the digit Cargo's resolver actually treats as its compatibility class. Any other setting mis-signals at least one commit type.
2. **Toolchain default.** `cargo new` emits `version = "0.1.0"` and release-please's own Rust strategy starts a new crate at `0.1.0`. The recommendation requires no override of anything; the alternatives all require one.
3. **Independent convergence.** release-plz — a different tool, different authors, Rust-native — defaults to the same policy and documents the opposite as a violation of Cargo's SemVer rules.

Adoption evidence that the resulting version shape is normal rather than a signal of immaturity: eleven of twenty-one surveyed high-traffic crates are pre-1.0, including `axum` at `0.8.9` with 27,070 stars and 461,946,996 all-time downloads (`crates.io` and GitHub REST, retrieved 2026-09-09).

### Options

Pattern item — per the answer template, no download columns. Every option is a way of instantiating the automated-bump architecture for a brand-new crate.

| # | Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|---|
| A | **Start `0.1.0`; `bump-minor-pre-major: true` + `bump-patch-for-minor-pre-major: true`** → `fix→z`, `feat→z`, breaking→`y` | release-please `schemas/config.json` and `docs/manifest-releaser.md:173-179` (v17.11.2); the resulting arithmetic is the Cargo Book's SemVer reference | Every pre-1.0 crate that keeps breaking changes on the `y` digit: `axum` 0.8.9, `tracing` 0.1.44, `tower` 0.5.3, `reqwest` 0.13.5, `sqlx` 0.9.0, `ratatui` 0.30.2, `config` 0.15.25, `figment` 0.10.19 (versions from `GET https://crates.io/api/v1/crates/<name>`, retrieved 2026-09-09). release-plz ships this as its default policy. ts-launch-blueprint practices the npm equivalent (`release-please-config.json:6-7`, pinned clone `cb1cbcb`). | release-please `v17.11.2`, published 2026-08-24 (`GET https://api.github.com/repos/googleapis/release-please/releases/latest`, retrieved 2026-09-09); release-plz `config.md` §`features_always_increment_minor`, retrieved 2026-09-09 |
| B | **Start `1.0.0`; no pre-major flags** (py's present shape) | release-please `src/strategies/base.ts:756-761` (`initial-version`, else `1.0.0`); Cargo Book SemVer reference for post-1.0 semantics | `serde` 1.0.229, `tokio` 1.53.1, `clap` 4.6.6, `anyhow` 1.0.104, `regex` 1.13.1, `hyper` 1.11.1, `thiserror` 2.0.20 — all long past their first release. py-launch-blueprint (manifest `{".": "2.4.2"}`, pinned clone `b08bccf`) | Cargo Book SemVer reference, retrieved 2026-09-09 |
| C | **Start `0.1.0`; neither flag set** (release-please's raw defaults under `release-type: rust`) | release-please `src/versioning-strategies/default.ts` — both option fields default to `false` via `options.bumpMinorPreMajor === true` | No surveyed crate practices this deliberately; it is the accidental outcome of adopting `release-type: rust` without reading the flags | release-please `v17.11.2` source, retrieved 2026-09-09 |
| D | **Start `0.1.0`; `bump-minor-pre-major: true` only** — the configuration D-021(1)'s decision text literally describes, and the one the wording in this prompt's `## Questions` would produce | release-please `schemas/config.json`; `TS_PORT_DECISIONS.md:253` (pinned ts clone) names only this flag | None found. ts's *documentation* describes it; ts's *config* does not implement it | `TS_PORT_DECISIONS.md` D-021, pinned clone `cb1cbcb` |
| E | **Start `0.1.0`, graduate to `1.0.0` on a fixed calendar or milestone via `initial-version` / `release-as` / a `Release-As:` commit footer** | release-please `schemas/config.json` (`initial-version`: *"Releases the initial library with a specified version"*; `release-as` marked `[DEPRECATED]`); `docs/manifest-releaser.md:165-171`; `RELEASE AS` note handling in `default.ts` | This is the standard graduation mechanism rather than a launch policy; it composes with (A) | release-please `v17.11.2`, retrieved 2026-09-09 |

**Empirical separation of A, B, C and D.** Executed 2026-09-09 against `release-please@17.11.2` installed from npm into a scratch directory, driving `DefaultVersioningStrategy` directly (see `### Validation strategy` for the exact command). Cell format is `commit → resulting version`.

| Configuration | From `0.1.3`: `fix` | `feat` | `feat!` | From `1.0.0`: `fix` | `feat` | `feat!` |
|---|---|---|---|---|---|---|
| A — both flags `true` | 0.1.4 | 0.1.4 | **0.2.0** | 1.0.1 | 1.1.0 | 2.0.0 |
| C — no flags (defaults) | 0.1.4 | **0.2.0** | **1.0.0** | 1.0.1 | 1.1.0 | 2.0.0 |
| D — `bump-minor-pre-major` only | 0.1.4 | **0.2.0** | 0.2.0 | 1.0.1 | 1.1.0 | 2.0.0 |

Reading the bolded cells against Cargo's rule: under (C) the *first breaking change ever merged silently promotes the crate to `1.0.0`*, an irreversible stability claim made by a bot. Under (C) and (D) a *non-breaking* `feat` produces `0.2.0`, which every Cargo consumer of `"0.1"` reads as incompatible — the crate withholds a compatible release and forces a manifest edit across its consumers for no reason. Only (A) satisfies acceptance criteria A1–A4. Option (B) is correct at `1.0.0` and above (right-hand columns, identical for every configuration) — its cost is not arithmetic but the claim it makes.

### Excluded by gate

The six fitness gates in `## Required evidence` are written for crate candidates. This is a `pattern` item whose candidates are configuration policies, not dependencies: adopting any option adds **zero** entries to `Cargo.toml`'s `[dependencies]` or `[dev-dependencies]`, and the tool that implements them (release-please) runs as a GitHub Action in Node, never in the built artifact or its dependency tree. Each gate is therefore recorded as `inapplicable` with its reason, per the tier guidance — none is omitted, and **no candidate is excluded by any gate.**

1. **License compatible with `MIT OR Apache-2.0`** — `inapplicable`. No crate is added, so no license enters the dependency tree. For completeness on the tooling: `googleapis/release-please` is Apache-2.0 and `release-plz/release-plz` is Apache-2.0 (`GET https://api.github.com/repos/<o>/<r>`, `license.spdx_id`, retrieved 2026-09-09); both are CI-side tools, not linked code.
2. **Crate and dependency-tree MSRV within `stable minus 2 minor versions…`** — `inapplicable`. A version string in `[package] version` has no MSRV. The policy does not constrain, and is not constrained by, `rust-version`. Verified independently of this item: `cargo new` on cargo 1.98.0 emits no `rust-version` key at all (executed 2026-09-09).
3. **No open RustSec advisory; `unsafe` posture stated** — `inapplicable` for the pattern itself: a version-number policy has no code and no `unsafe`. For the one tool this report proposes adding to CI, `cargo-semver-checks`: `GET https://rustsec.org/packages/cargo-semver-checks.html` returned **HTTP 404** on 2026-09-09. RustSec publishes a package page only where advisories exist, so 404 is read here as *no published advisory*, not as a failed check — the interpretation is stated because a 404 is not itself a positive assertion. `cargo-semver-checks` is a developer tool invoked from CI, never a dependency of the published crate, so its `unsafe` posture does not enter the template's tree.
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — `inapplicable` as written (nothing is built). The relevant OS question is where the *release automation* runs, and release-please executes on the GitHub-hosted runner chosen by the workflow; version arithmetic is platform-independent. The proposed CI gate `cargo-semver-checks` release `v0.50.0` publishes prebuilt archives covering both required runners — `cargo-semver-checks-x86_64-unknown-linux-gnu.tar.gz`, `cargo-semver-checks-aarch64-unknown-linux-gnu.tar.gz`, `cargo-semver-checks-x86_64-apple-darwin.tar.gz`, `cargo-semver-checks-aarch64-apple-darwin.tar.gz` (`GET https://api.github.com/repos/obi1kenobi/cargo-semver-checks/releases/latest`, `assets[].name`, retrieved 2026-09-09) — and it also installs via `cargo install`. **This report did not execute it on either runner** — recorded as an evidence gap, not a claim.
5. **Default features and any async-runtime coupling** — `inapplicable`. A version policy declares no Cargo features and couples to no async runtime. `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` are JSON booleans in `release-please-config.json` and default to `false` when absent (`default.ts`: `options.bumpMinorPreMajor === true`).
6. **Binary-size and compile-time cost** — `inapplicable`, and measurably zero: the decision changes only the string in `[package] version`, which reaches the binary at most through `CARGO_PKG_VERSION`, a compile-time environment variable whose length differs by at most a character or two between `0.1.0` and `1.0.0`. No dependency, no codegen, no build script.

### Up-and-comers

- **release-plz 0.3.164** (`GET https://crates.io/api/v1/crates/release-plz`, `crate.max_stable_version`, 63,381 90-day and 349,173 all-time downloads; `release-plz/release-plz`, 1,474 stars, `pushed_at` 2026-09-10, Apache-2.0; `GET https://api.github.com/repos/release-plz/release-plz`, retrieved 2026-09-09) — the Rust-native alternative to release-please: a Cargo-aware bumper that reads Conventional Commits *and* the actual API diff. **Not proposed for adoption** — the release tool is fixed by ledger rows F063/F066/F073 and the choice is out of scope per this prompt's `## Out of scope`. It appears here because it is the strongest independent evidence for the recommended policy: its default `features_always_increment_minor = false` is `bump-patch-for-minor-pre-major: true` by another name, and its documentation labels the opposite a violation of Cargo's SemVer rules (retrieved 2026-09-09). Watch it as the migration target if release-please's Rust support ever stalls.
- **cargo-semver-checks 0.50.0** (`obi1kenobi/cargo-semver-checks`, 1,676 stars, `pushed_at` 2026-08-29, Apache-2.0, 162 open issues via `GET https://api.github.com/search/issues?q=repo:obi1kenobi/cargo-semver-checks+is:issue+is:open`; 159,160 90-day and 616,353 all-time downloads via `GET https://crates.io/api/v1/crates/cargo-semver-checks`; all retrieved 2026-09-09) — **proposed for adoption as a CI gate**, not as a dependency. It is the piece that turns the chosen policy from a declaration into an enforced invariant: it compares the crate's public API against a baseline revision and reports whether the change is compatible, catching the case where a `feat:`-labelled commit is in fact breaking and would otherwise ship as a patch bump. Maintenance state: **active** — released within the last six weeks, repository pushed 2026-08-29, and it is the checker release-plz itself delegates to. Its own honest limitation is documented by that consumer: *"Will `cargo-semver-checks` catch every semver violation? No, it won't — not yet!"* (release-plz `semver-check.md`, retrieved 2026-09-09), so it is a strong net, not a proof.
- **Maintenance state of the incumbent, by the rubric** — `googleapis/release-please`: **active**. Latest release `v17.11.2` published 2026-08-24, repository `pushed_at` 2026-09-03, `archived: false`, 297 open issues (`GET https://api.github.com/repos/googleapis/release-please`, `GET https://api.github.com/search/issues?q=repo:googleapis/release-please+is:issue+is:open`, retrieved 2026-09-09). No release-drought trigger fires: the newest release is roughly two weeks old. **Issue responsiveness — median days to first maintainer response over the 10 most recently opened issues was not measured; recorded as an unmet evidence requirement, not estimated.**

### Fit for this template

The template ships three shapes from one repository under one version number. The recommendation must fit the *strictest* of the three, because they cannot be versioned separately.

**Library (crates.io-published) — the binding case, and the decisive one.** A published library's version is a machine-readable promise to code the maintainer will never see. Two Rust-specific facts make `0.1.0` the honest opening claim:

- *C-STABLE forbids the alternative if any public dependency is pre-1.0.* The Rust API Guidelines state: *"A crate cannot be stable (>=1.0.0) without all of its public dependencies being stable. Public dependencies are crates from which types are used in the public API of the current crate."* (`rust-lang/api-guidelines`, `src/necessities.md`, retrieved 2026-09-09.) The guideline warns that such dependencies *"can sneak in at unexpected places"* — its worked example is a `From<other_crate::Error>` impl on a crate's own error type, precisely the shape an error-taxonomy item (R67) would produce. The template's plausible surface includes `tracing` 0.1.44, `tower` 0.5.3, `axum` 0.8.9, `config` 0.15.25 and `figment` 0.10.19 — all pre-1.0 (versions retrieved 2026-09-09). A `1.0.0` launch would therefore be a stability claim the guidelines say the crate is not entitled to make, and one that no single-item decision here can guarantee, because R53/R55/R58/R67/R69 have not yet chosen the crates whose types may appear in the public surface.
- *A wrong `1.0.0` is unwindable only at cost.* Retreating from `1.0.0` requires yanking or an ugly `2.0.0` that means "we were not ready"; graduating from `0.x` is a one-line commit footer. Under the recorded API-surface enforcement work (R04, resolved) the public surface is curated deliberately, which is exactly the process that should conclude with a 1.0 graduation — after it has run, not before.

**CLI (installed binary).** Weakest constraint. `cargo install rs-launch-blueprint` resolves the newest version regardless of digits, and end users read release notes, not version arithmetic. Neither option harms this shape. One small point in `0.1.0`'s favour: the CLI's `--version` output and the library's version are the same string in a single-version workspace, so the CLI inherits whatever claim the library makes — and it should not be the one making a stability promise on the library's behalf.

**Web service (optional feature-gated surface).** F017's principle is that the web surface ships as an optional capability behind a Cargo feature (`docs/port/BASELINE-REVIEW.md`, F017, `retained`). A feature-gated HTTP surface built on `axum` 0.8.9 and `tower` 0.5.3 inherits its dependencies' pre-1.0 churn: an `axum` `0.8 → 0.9` bump is, by Cargo's rule, a breaking change, and where any of those types reach the template's public API it is a breaking change for the template too. Under option (A) that propagates as `0.1.z → 0.2.0` — accurate, cheap, unremarkable. Under option (B) the same routine upstream bump forces `1.x → 2.0.0`, and repeated upstream churn drives the major digit up for reasons that have nothing to do with the template's own design. This is the strongest *practical* argument against (B) and it is specific to a Rust web stack; ts faced nothing equivalent.

**Across all three shapes: the template's own nature.** `rs-launch-blueprint` is a template that consumers copy. Whatever it ships is read as the recommended shape. Shipping the configuration that is arithmetically correct under Cargo's own rule — and that release-please's Rust strategy already defaults toward — teaches the right pattern; shipping `1.0.0` teaches downstream template users to assert stability on day one.

### Recommendation

Adopt **option (A)**. Concretely, three artifacts:

```
Cargo.toml                      [package] version = "0.1.0"
.release-please-manifest.json   { ".": "0.1.0" }
release-please-config.json      "release-type": "rust",
                                "bump-minor-pre-major": true,
                                "bump-patch-for-minor-pre-major": true
```

Rationale, in the order the evidence carries it:

1. **It is the only configuration that satisfies all four acceptance criteria** (A1–A4), demonstrated by the executed bump table in `### Options`, against the rule stated in the Cargo Book's SemVer reference and enforced by the resolver rule in *Specifying Dependencies* (both retrieved 2026-09-09).
2. **It costs nothing to reach.** `cargo new` emits `version = "0.1.0"` (executed on cargo 1.98.0, 2026-09-09) and `release-type: rust` starts a fresh crate at `0.1.0` with no seed (`src/strategies/rust.ts`, v17.11.2). The two booleans are the entire change. Option (B) would require an override of both defaults.
3. **An independent Rust-native tool reached the same policy and documents the opposite as a rules violation** (release-plz `config.md`, retrieved 2026-09-09).
4. **The Rust API Guidelines' C-STABLE rule makes `1.0.0` a claim this template cannot yet substantiate**, since its public dependencies are not yet chosen and several likely candidates are pre-1.0.
5. **Pre-1.0 is the reversible choice.** Graduation is a `Release-As: 1.0.0` commit footer, handled by `default.ts`'s `RELEASE AS` note branch, needing no config change; the reverse direction does not exist.
6. **`0.x` carries no adoption penalty in Rust** — eleven of twenty-one surveyed crates, several with nine-figure download counts, are pre-1.0 (crates.io, retrieved 2026-09-09).

Both flags must be set. Setting only `bump-minor-pre-major` — the configuration D-021(1)'s prose describes, and the one this prompt's `## Questions` wording would produce — is option (D) and is measurably wrong: it turns every non-breaking feature into a `0.2.0`-style incompatibility signal.

**Preserving the principle across repos.** rs matches ts's low-level value on Rust's own evidence, not by inheritance. py stays as it is: post-1.0 since it adopted release-please (manifest `{".": "1.0.0"}` at `1bd0344`), where both flags are unreachable code. The follow-on project should correct D-021(1)'s decision text to name both flags, since ts's config sets both while its record names one.

### Ranked runner-up

**Option (B) — launch at `1.0.0` with standard semver semantics** (py's present shape; requires `"initial-version": "1.0.0"` in `release-please-config.json`, or hand-seeding `Cargo.toml` and the manifest, because `release-type: rust` otherwise starts at `0.1.0`).

It is the runner-up rather than a rejected option because it is *not wrong* — above `1.0.0` the bump table is identical for every configuration (right-hand columns of the executed table), so (B) satisfies A1–A3 by construction. Its cost is entirely in the claim it makes on day one.

**The condition under which (B) wins:** when the public API surface is genuinely settled and free of pre-1.0 public dependencies at first publication. Operationally, all of the following would have to hold before the first release:

- R04's public-API enforcement (resolved) is wired and the curated `lib.rs` surface is final;
- no crate appearing in that public surface is itself pre-1.0, satisfying C-STABLE — which today would exclude any public use of `axum` 0.8.9, `tower` 0.5.3, `tracing` 0.1.44, `config` 0.15.25 or `figment` 0.10.19 types;
- the web surface's dependency churn is walled off behind private types so an upstream `0.8 → 0.9` bump cannot force a major bump;
- the owner accepts that every subsequent breaking change costs a whole major digit.

Option (E) is the practical reconciliation: take (A) now, and reach (B)'s position later by a `Release-As: 1.0.0` footer once those conditions are met. That path is strictly better than starting at (B), because it makes the stability claim *after* the evidence for it exists.

Options (C) and (D) are ranked below (B) and are not runners-up: both are measurably incorrect under Cargo's rule per the executed table.

### Tradeoffs

**What (A) gives up versus (B).**
- *The minor digit stops announcing features.* Under (A), `feat` moves the patch digit, so a run of feature releases reads `0.1.1, 0.1.2, 0.1.3` — visually indistinguishable from bug fixes. ts demonstrates the shape: three releases, all patch, ending at `0.1.3` (pinned clone `cb1cbcb`). Accepted because the changelog, not the version string, is where humans read what changed, and F066 (`COMMON → REUSE`) already guarantees a generated `CHANGELOG.md`. The version string's job is to talk to the resolver, and under (A) it does that correctly.
- *Some readers still equate `0.x` with "not production-ready".* Accepted on evidence: `axum` at `0.8.9` with 461,946,996 downloads and 27,070 stars, and `tracing` at `0.1.44` with 834,126,366 downloads, show the Rust ecosystem does not apply that reading (crates.io and GitHub REST, retrieved 2026-09-09).
- *A future 1.0 graduation is a deliberate act someone must remember to perform.* Accepted, and cheap: one commit footer, no config change. The reverse mistake under (B) is not cheap.

**What (A) gives up versus (C) — release-please's raw defaults.**
- Nothing but two lines of configuration. (C) costs less to type and is measurably wrong: the first `feat!` merged silently publishes `1.0.0`, and a routine `feat` publishes `0.2.0`, which Cargo consumers read as incompatible. The two booleans buy correctness on both counts.

**What (A) gives up versus (D) — `bump-minor-pre-major` alone.**
- Nothing. (D) is strictly worse: `feat → 0.2.0` withholds a compatible release from every consumer pinned to `"0.1"`, requiring a coordinated manifest edit downstream for a purely additive change. (D)'s only merit is matching D-021(1)'s prose — which the evidence shows is a documentation error, since ts's shipped config sets both flags.

**What (A) gives up versus (E) as a launch policy.**
- (E) is not an alternative launch policy; it is (A) plus a graduation mechanism, and is folded into the recommendation. Setting `initial-version` at launch would be (B) in disguise and carries (B)'s costs.

**Residual risk carried by (A), stated plainly.** The policy is only as accurate as the commit messages. A breaking change committed as `feat:` ships as a patch bump under (A) — the same failure mode (C) and (D) have, and one that neither the flags nor release-please can detect. This is exactly why `cargo-semver-checks` is proposed as a CI gate in `### Validation strategy`, and it is the reason the residual risk is judged acceptable rather than merely tolerated.

### Parameters

`owns` — none. R25 owns no entry in `docs/port/PARAMETERS.md`; the `owns` column of `research/CLAUDE.md` row R25 is `—`, and this prompt's `## Couplings` `owns:` line is empty. This item's output is consumed as ledger row F070's verdict, not as a registry parameter.

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — owner-fixed. Unaffected: the recommendation adds no crate and touches no `rust-version` key.
`assumes rust-edition = 2024` — owner-fixed. Unaffected; independent of the version field. (`cargo new` on cargo 1.98.0 emitted `edition = "2024"`, executed 2026-09-09.)
`assumes license = MIT OR Apache-2.0` — owner-fixed. Unaffected: no dependency is introduced, so no license compatibility question arises.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — owner-fixed. Unaffected: version arithmetic is platform-independent. The one proposed CI addition (`cargo-semver-checks`) must run on both runners; this report did not execute it on either, and that is recorded as an evidence gap.

Assumed from the ledger, not from `PARAMETERS.md`: release-please is the release tool and `Cargo.toml`'s `[package] version` is the version source of truth (F063, F066, F073, all `COMMON → REUSE`), per this prompt's `## Out of scope`.

No `CONFLICT:` lines. The `## Couplings` block lists no `consumes:` entries, so there is no consumed parameter this recommendation needs changed, and none of the four owner-fixed parameters is contradicted.

### Migration implications

File-level changes in the template, all at repository creation — there is no existing Rust code or published crate to migrate.

| File | Change | Note |
|---|---|---|
| `Cargo.toml` | `[package] version = "0.1.0"` | Matches what `cargo new` emits (executed, cargo 1.98.0, 2026-09-09); for a workspace, the version lives wherever F063 places it and this item does not move it |
| `.release-please-manifest.json` | create as `{ ".": "0.1.0" }` | Strictly optional under `release-type: rust`, whose `initialReleaseVersion()` already returns `0.1.0` (`src/strategies/rust.ts`, v17.11.2). Seeding it explicitly is still recommended: it makes the intent legible, and it is what F074's tag/version consistency guard compares against |
| `release-please-config.json` | add `"release-type": "rust"`, `"bump-minor-pre-major": true`, `"bump-patch-for-minor-pre-major": true` | Both flags at the top level, mirroring ts's placement (`release-please-config.json:6-7`, pinned clone). Per-package overrides are supported and unnecessary for a single package (`src/manifest.ts:1748-1752`) |
| `release-please-config.json` | do **not** add `initial-version` | It exists only to override the strategy's initial version (`src/strategies/base.ts:756-761`); the Rust strategy's `0.1.0` is already the wanted value |
| CI workflow (job structure per R11) | add a `cargo-semver-checks` gate on pull requests | Enforces the policy rather than declaring it; see `### Validation strategy`. Placement and job shape belong to R11, not to this item |
| `docs/` release/versioning reference | document the policy and the graduation path | The analogue of ts's `docs/reference/versioning.md`, whose "Semantic Versioning" section names both flags (pinned clone). Must state the flags' *actual* semantics — breaking→minor, feat→patch — and not this prompt's gloss |

**Graduation to 1.0.0, when the time comes.** Land a commit whose body carries the footer `Release-As: 1.0.0`. The maintainers document the syntax: *"When a commit to the main branch has `Release-As: x.x.x` (case insensitive) in the **commit body**, Release Please will open a new pull request for the specified version"*, with the worked example `git commit --allow-empty -m "chore: release 2.0.0" -m "Release-As: 2.0.0"` (`README.md:106-115`, v17.11.2, retrieved 2026-09-09). The implementation matches: `DefaultVersioningStrategy` looks for a `RELEASE AS` note before any other decision and returns a `CustomVersionUpdate` (`src/versioning-strategies/default.ts`, v17.11.2). No configuration change is needed, and the two flags become inert automatically once `major >= 1` (`Version.isPreMajor` is `this.major < 1`, `src/version.ts:86-88`). The deprecated `release-as` **config key** is the inferior route — the schema itself marks it `[DEPRECATED] … Consider using a Release-As commit instead`, and `docs/manifest-releaser.md:165-171` warns that leaving it in place makes subsequent runs keep proposing the same version.

**Interaction with already-decided rows.** No change is required to F063 (version source of truth), F072 (auth), F073 (release trigger), F074 (tag/version guard) or F075 (OIDC publishing) — all `COMMON → REUSE` and all orthogonal to bump arithmetic. F074's guard compares tag against manifest and `Cargo.toml`, which the recommendation keeps mutually consistent because release-please writes all three. R23/F065 should confirm its lockfile decision against release-please's built-in `CargoLock` updater (cross-item note in `### Principles and implementation`); no change is proposed here.

### Validation strategy

**Executed — results above are from these runs, all on 2026-09-09.**

1. *Toolchain default for a new crate.* Run in the scratch directory, not the repository:
   ```
   cargo new --lib --vcs none <scratch>/probe-lib && cat <scratch>/probe-lib/Cargo.toml
   cargo new --bin --vcs none <scratch>/probe-bin && cat <scratch>/probe-bin/Cargo.toml
   ```
   Expected: `version = "0.1.0"`. **Observed: `version = "0.1.0"` and `edition = "2024"` for both the library and the binary template, on `cargo 1.98.0 (797e8a9bc 2026-08-05)`.** Establishes acceptance criterion A0 and answers the HIGH question about the ecosystem's initial-version convention with an executed result rather than a recollection.

2. *Bump arithmetic under each candidate configuration.* Install the exact tool and drive its versioning strategy directly:
   ```
   npm --prefix <scratch>/rp-probe install release-please@17.11.2
   node <scratch>/rp-probe/probe.cjs
   ```
   The probe requires `release-please/build/src/versioning-strategies/default` and `release-please/build/src/version` — **package-internal build paths, not a public API**; a future release may relocate them, which is a durability caveat on the method, not on the result. It constructs `DefaultVersioningStrategy` with each flag combination and calls `.bump(Version.parse(start), [commit])` for a `fix`, a `feat`, and a breaking `feat` at starting versions `0.1.0`, `0.1.3` and `1.0.0`. Expected under both flags true from `0.1.3`: `0.1.4`, `0.1.4`, `0.2.0`. **Observed exactly that; the full 9-row output is reproduced as the table in `### Options`.** Establishes A1–A4 for option (A) and falsifies (C) and (D).

3. *Flag semantics and Rust-strategy behaviour, read from the pinned tool source.* `curl -sS` with a User-Agent header against `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/<path>` for `src/versioning-strategies/default.ts`, `src/version.ts`, `src/strategies/rust.ts`, `src/strategies/base.ts`, `src/strategies/python.ts`, `src/strategies/node.ts`, `src/manifest.ts`, `src/factories/versioning-strategy-factory.ts`, `schemas/config.json`, `docs/manifest-releaser.md`, `README.md`; and against `.../v17.6.0/src/strategies/rust.ts` to confirm the behaviour at the floor of the action's dependency range. **All fetched successfully; quotations above are verbatim.**

**Planned — proposed, not run. Each is written so a reviewer can execute it.**

4. *End-to-end proposal check against a scratch repository.* Create a throwaway GitHub repository containing only `Cargo.toml` (`version = "0.1.0"`), `.release-please-manifest.json`, and the recommended `release-please-config.json`; push `fix: …`, then `feat: …`, then `feat!: …`; after each push read the version release-please proposes:
   ```
   npx release-please@17.11.2 release-pr --repo-url=<owner>/<repo> --token=$GITHUB_TOKEN --dry-run
   ```
   Expected: `0.1.1`, `0.1.2`, `0.2.0`. This is the only check that exercises the real strategy end to end including `Cargo.toml` and `Cargo.lock` rewriting; step 2 exercises the arithmetic only. **Not run: it requires a GitHub token and a scratch repository, neither of which is in scope for a research pass.**

5. *Enforcement gate that makes the policy true rather than merely declared.* In CI, on every pull request:
   ```
   cargo install cargo-semver-checks --locked
   cargo semver-checks check-release --baseline-rev <latest v* tag>
   ```
   Expected behaviour: the job fails when the branch changes the public API incompatibly, prompting the author to write `feat!:`/`BREAKING CHANGE:` so release-please moves the `y` digit. This closes the residual risk named in `### Tradeoffs` — a breaking change mislabelled `feat:` shipping as a patch bump. Two stated limits: the checker's own documentation, via release-plz, says it does not yet catch every violation; and its behaviour on `ubuntu-latest` and `macos-latest` was **not** verified here. Placement in the CI job graph belongs to R11.

6. *Publication smoke check.* `cargo publish --dry-run` on the release branch, asserting the packaged version equals the tag — the crates.io analogue of F074's existing tag/version guard, listed for completeness because it is where a mis-seeded manifest would surface. Owned by F074, not by this item.

7. *Regression test for the version surface.* F133 (`COMMON → REUSE`) already requires a test asserting the version stays single-sourced across manifests. No new test is proposed here; the recommendation keeps `Cargo.toml`, `.release-please-manifest.json` and `Cargo.lock` mutually consistent because release-please writes all three in one commit (`src/strategies/rust.ts`).

### Confidence & re-verify trigger

**Confidence: high** on the flag semantics and on the recommended configuration; **medium-high** on the launch-at-`0.1.0` judgement.

The high-confidence part rests on triangulated primary evidence, not inference: the maintainers' implementation (`default.ts`), their JSON schema, and their prose documentation all agree on what the flags do, and an executed probe against the pinned tool reproduces the table. The mapping from Cargo's "left-most non-zero component" rule to that flag pair is arithmetic. An independent Rust-native tool (release-plz) defaults to the same policy and calls the opposite a violation of Cargo's rules.

The medium-high part is the launch-version judgement, which turns on two things a research pass cannot fully settle: whether the template's eventual public API is stable enough to warrant `1.0.0` (it depends on R53/R55/R58/R67/R69, none resolved), and whether pre-1.0 dependencies will appear in the public surface, which C-STABLE makes decisive. Both currently point to `0.1.0`, and `0.1.0` is the recoverable direction.

**Known evidence gaps, stated rather than papered over.**
- ts's flags have **never fired**: there are zero `feat` commits between its releases (`bdc7567..1ec682f` and `1ec682f..0e6a3d7`, pinned clone), so all three of its releases were patch bumps driven by `fix` commits alone. ts is stated intent, not observed behaviour. The executed probe in step 2 is what supplies the observed behaviour.
- The crates panel is 21 hand-picked crates chosen for relevance to a CLI + library + web template, **not a census** of crates.io. "11 of 21 are pre-1.0" is illustrative of the ecosystem's tolerance for `0.x`, not a population statistic.
- **Issue responsiveness (median days to first maintainer response over the 10 most recently opened issues) was not measured** for release-please or cargo-semver-checks. Open-issue totals were retrieved via the required `search/issues` endpoint; the responsiveness metric is simply missing.
- The end-to-end release-please dry run (step 4) and the `cargo-semver-checks` CI gate on both required runners (step 5) were not executed.
- `GET https://rustsec.org/packages/cargo-semver-checks.html` returned HTTP 404; that is read as "no advisory page published", an interpretation, not a positive all-clear from RustSec.

**Re-verify triggers.**
1. **Before the first release is cut** — run step 4 (the end-to-end dry run) against a scratch repository. It is the only check that proves the real strategy behaves as the probe predicts.
2. **On any release-please major bump past v17** — re-read `src/versioning-strategies/default.ts` and `src/strategies/rust.ts`. Both the flag semantics and the Rust strategy's `0.1.0` initial version are implementation details that a major version may change; note that `googleapis/release-please-action` v5.0.0 declares `"release-please": "^17.6.0"`, so a v18 would require an action bump before it could reach this repository.
3. **When R53, R55, R58, R67 or R69 selects a crate whose types enter the public API** — re-check C-STABLE. If every such crate is post-1.0 and the surface is settled, the graduation condition in `### Ranked runner-up` is met and a `Release-As: 1.0.0` footer becomes appropriate.
4. **If the template gains a real consumer base while still at `0.1.z`** — semver.org's own guidance applies: *"If your software is being used in production, it should probably already be 1.0.0."* (`https://semver.org/`, retrieved 2026-09-09). That is the moment to schedule graduation, not to revisit the flags, which stay correct either way.
5. **If R23/F065's lockfile decision diverges from release-please's built-in `CargoLock` updater** — re-check that the two do not fight over `Cargo.lock` in the release commit.

### Sources

Primary tooling sources — release-please, all at tag `v17.11.2`, retrieved 2026-09-09 via `curl -sS` with a User-Agent header:
- `https://api.github.com/repos/googleapis/release-please/releases/latest` — `tag_name: v17.11.2`, `published_at: 2026-08-24T21:20:30Z`
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/versioning-strategies/default.ts` — `DefaultVersioningStrategy.determineReleaseType`; the `breaking`/`features` branches; the `RELEASE AS` note handling
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/version.ts` — `get isPreMajor(): boolean { return this.major < 1; }` (lines 86-88)
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/strategies/rust.ts` — `initialReleaseVersion() → 0.1.0`; the `CargoToml` and `CargoLock` updaters
- `https://raw.githubusercontent.com/googleapis/release-please/v17.6.0/src/strategies/rust.ts` — same `0.1.0` initial version at the floor of the action's dependency range
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/strategies/base.ts` — `initialReleaseVersion()` default `1.0.0` and `initial-version` override (lines 756-761); `versioningStrategy` default (lines 138-140)
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/strategies/python.ts` — `initialReleaseVersion() → 0.1.0` (lines 200-202)
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/strategies/node.ts` — no `initialReleaseVersion` override (grep returned no match)
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/manifest.ts` — config-key to strategy-option mapping (lines 1395-1396, 1428, 1748-1752, 1793)
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/src/factories/versioning-strategy-factory.ts` — `default: options => new DefaultVersioningStrategy(options)`
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/schemas/config.json` — the two flags' descriptions; `initial-version`; `release-as` marked `[DEPRECATED]`
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/docs/manifest-releaser.md` — flag prose (lines 173-179), `release-as` caveat (lines 165-171), `cargo-workspace` plugin note (lines 560-573)
- `https://raw.githubusercontent.com/googleapis/release-please/v17.11.2/README.md` — the `rust` release-type row (line 200); the `Release-As:` commit-footer syntax and worked example (lines 106-115)
- `https://raw.githubusercontent.com/googleapis/release-please-action/v5.0.0/package.json` — `"release-please": "^17.6.0"`
- `https://api.github.com/repos/googleapis/release-please-action/releases/latest` — `v5.0.0`, `2026-04-22T18:03:34Z`

Rust project and working-group sources, retrieved 2026-09-09:
- `https://doc.rust-lang.org/cargo/reference/semver.html` — the `0.y.z`/left-most-non-zero passage
- `https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html` — default and caret requirement tables; *"This is different from SemVer which considers all pre-1.0.0 packages to be incompatible."*
- `https://raw.githubusercontent.com/rust-lang/api-guidelines/master/src/necessities.md` — C-STABLE and C-PERMISSIVE
- `https://semver.org/` — item 4 (major version zero), item 5 (1.0.0 defines the public API), FAQ *"How do I know when to release 1.0.0?"*

Other-ecosystem and independent-implementation sources, retrieved 2026-09-09:
- `https://raw.githubusercontent.com/npm/node-semver/main/README.md` — *Caret Ranges*: `^0.2.3 := >=0.2.3 <0.3.0-0`, `^0.0.3 := >=0.0.3 <0.0.4-0`
- `https://raw.githubusercontent.com/release-plz/release-plz/main/website/docs/config.md` — `features_always_increment_minor` field and its Cargo-SemVer warning
- `https://raw.githubusercontent.com/release-plz/release-plz/main/website/docs/semver-check.md` — breaking-change bump behaviour; the cargo-semver-checks coverage caveat

Figure endpoints, all retrieved 2026-09-09:
- `GET https://crates.io/api/v1/crates/<name>` for `serde`, `tokio`, `clap`, `anyhow`, `thiserror`, `regex`, `hyper`, `axum`, `reqwest`, `tracing`, `tower`, `ratatui`, `sqlx`, `indicatif`, `rand`, `toml`, `config`, `figment`, `tracing-subscriber`, `utoipa`, `clap_complete`, `cargo-semver-checks`, `release-plz` — fields `crate.max_stable_version`, `crate.newest_version`, `crate.recent_downloads`, `crate.downloads`, `crate.updated_at`, `crate.created_at`
- `GET https://api.github.com/repos/<o>/<r>` for `tokio-rs/tokio`, `tokio-rs/axum`, `tokio-rs/tracing`, `rust-random/rand`, `ratatui/ratatui`, `transact-rs/sqlx` (reached by following the redirect from `launchbadge/sqlx`), `seanmonstar/reqwest`, `clap-rs/clap`, `serde-rs/serde`, `obi1kenobi/cargo-semver-checks`, `release-plz/release-plz`, `googleapis/release-please` — fields `stargazers_count`, `archived`, `pushed_at`, `license.spdx_id`
- `GET https://api.github.com/search/issues?q=repo:googleapis/release-please+is:issue+is:open` — `total_count: 297`
- `GET https://api.github.com/search/issues?q=repo:obi1kenobi/cargo-semver-checks+is:issue+is:open` — `total_count: 162`
- `GET https://api.github.com/repos/obi1kenobi/cargo-semver-checks/releases/latest` — `tag_name: v0.50.0`; `assets[].name` (prebuilt archives for linux-gnu and apple-darwin on both x86_64 and aarch64, plus musl and windows-msvc)
- `https://rustsec.org/packages/cargo-semver-checks.html` — HTTP 404

Repository and pinned-source-tree evidence:
- `docs/port/COMMONALITY.md:76` (F070), `:69` (F063), `:72` (F066), `:78-81` (F072, F073, F074, F075), `:139` (F133)
- `docs/port/areas/release-versioning.md` — the F063–F082 feature table
- `docs/port/PARAMETERS.md` — the four owner-fixed parameters and the 2026-09-02 owner decisions
- `docs/port/BASELINE-REVIEW.md` — F014, F017, F019 rows consulted for agreement-level vocabulary and the web-as-optional-capability principle
- `research/CLAUDE.md` — R25 row (`pattern`, `ts-only`, `DIVERGENT`, `owns: —`); R04, R23 status
- ts-launch-blueprint @ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `release-please-config.json:6-7`, `.release-please-manifest.json`, `package.json:3`, `docs/reference/versioning.md`, `docs/port/TS_PORT_DECISIONS.md:249-266` (D-021), commit `19ff9b5` (release-please seeding at `0.1.0`), commits `bdc7567`/`1ec682f`/`0e6a3d7` (the three releases and their intervening commit types)
- py-launch-blueprint @ `b08bccfb55d05f15e46a83b52c5660b1881d19f5`: `release-please-config.json` (no pre-major keys; `extra-files` lockfile jsonpath), `.release-please-manifest.json` (`{".": "2.4.2"}`), commit `1bd0344` (2026-05-24, release-please adopted with manifest `{".": "1.0.0"}`)

**Method notes.** Endpoints queried, all on 2026-09-09 (local retrievals ran 19:50–20:00 US/Pacific, i.e. 2026-09-10 02:50–03:00 UTC; every citation above uses the single date 2026-09-09): `api.github.com` (repository metadata, `search/issues` open-issue counts, latest-release tags), `raw.githubusercontent.com` (release-please at tags `v17.11.2` and `v17.6.0`, release-please-action at `v5.0.0`, release-plz `main` website docs, rust-lang/api-guidelines `master`, npm/node-semver `main`), `crates.io/api/v1/crates/<name>` (22 crates), `doc.rust-lang.org/cargo/reference/*` (rendered HTML, text-extracted locally), `semver.org` (rendered HTML, text-extracted locally), and `rustsec.org/packages/cargo-semver-checks.html`. All `curl -sS` calls sent a User-Agent header identifying this research run. Requests were issued sequentially, one URL per `curl` invocation — the crates.io panel was 21 requests over roughly 60 seconds. (`--rate` was passed on some invocations but throttles only *within* a single `curl` process, so it had no effect on a one-URL-per-call loop; the pacing above is what actually happened.) Two commands were executed locally in the session scratchpad, never in the repository worktree: `cargo new --lib/--bin` on `cargo 1.98.0 (797e8a9bc 2026-08-05)`, and a Node probe against `release-please@17.11.2` installed from npm, which imports the package-internal paths `release-please/build/src/versioning-strategies/default` and `.../version` (not a public API — a durability caveat on the method). **Source repositories were read from local pinned clones, not over the network: `ts-launch-blueprint` is private and returns HTTP 404 remotely, so every ts citation comes from `git -C ~/c/ts-launch-blueprint show cb1cbcb:<path>` (plus `git log`/`git show` for the seeding and release history); py citations come from `git -C ~/c/py-launch-blueprint show b08bccf:<path>` and that clone's `git log`.** Per this prompt's `## Out of scope`, prior art in the owner's other Rust repositories was neither sought nor cited. **Could not verify:** issue responsiveness (median days to first maintainer response across the 10 most recently opened issues) for release-please and cargo-semver-checks — the metric was not collected; the end-to-end `release-please release-pr --dry-run` against a scratch repository (needs a GitHub token and a throwaway repo); `cargo-semver-checks` execution on `ubuntu-latest` and `macos-latest`; and RustSec's position on `cargo-semver-checks` beyond the HTTP 404 from its package page, which is interpreted here as "no advisory published" rather than an affirmative clearance.
