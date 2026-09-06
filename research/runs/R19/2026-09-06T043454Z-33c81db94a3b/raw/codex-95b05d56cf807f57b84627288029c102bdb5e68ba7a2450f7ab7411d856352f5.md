### Landscape

This item decides a **dependency-update configuration policy**, not a Rust library. The field map is: built-in or first-party toolchain — GitHub Dependabot’s `cargo` and `github-actions` package ecosystems; established industry standard — a committed `.github/dependabot.yml` using Dependabot’s documented per-ecosystem schedule and groups; up-and-comer — multi-ecosystem groups, which are unnecessary for the two independent manifest families here. Dependabot is fixed by scope, so Renovate and other bots were not shortlisted. GitHub’s option reference is the controlling implementation authority because it defines the service’s accepted keys and supported ecosystems; Rust documentation is not the authority for this server-side configuration. [GitHub Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), retrieved 2026-09-05.

The authority set is deliberately diverse but not inflated: GitHub’s current documentation establishes the schema; the Rust project’s Cargo repository and well-maintained Rust projects establish practice. `cargo-llvm-cov` is a relevant maintained Rust tooling project: the GitHub repository API reported 1,458 stars, `archived: false`, and push activity on 2026-09-02; its committed configuration has both `cargo` and `github-actions` entries, each with a 14-day cooldown. Tokio is an established asynchronous Rust ecosystem project: the API reported 33,078 stars, `archived: false`, and push activity on 2026-09-05; it configures Dependabot for GitHub Actions. These are evidence that the two package families are normal Rust-repository concerns, not evidence that either project’s exact grouping policy is universally optimal. [cargo-llvm-cov API endpoint](https://api.github.com/repos/taiki-e/cargo-llvm-cov), [cargo-llvm-cov configuration](https://raw.githubusercontent.com/taiki-e/cargo-llvm-cov/main/.github/dependabot.yml), [Tokio API endpoint](https://api.github.com/repos/tokio-rs/tokio), and [Tokio configuration](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/dependabot.yml), all retrieved 2026-09-05.

The source comparison has one shared capability — automated, GitHub-native updates from a committed file — and a deliberately different policy shape. The pinned Python configuration declares `uv`, `github-actions`, and `npm`, and uses named dependency patterns, a five-day cooldown, labels, and a Conventional-Commit-compatible prefix; the pinned TypeScript configuration declares `github-actions` and `npm` and groups only minor and patch updates. The TypeScript decision records the reason for the common bot choice as GitHub-native, zero-infrastructure automation for template consumers. [Python pinned configuration](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/dependabot.yml#L12-L80), [TypeScript pinned configuration](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/dependabot.yml#L20-L50), and [D-022(8)](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/docs/port/TS_PORT_DECISIONS.md#L267-L292), all retrieved 2026-09-05.

### Principles and implementation

The shared requirement is **reviewable, low-operational-burden dependency freshness**. Agreement is required at the capability and policy level: each template needs declared update coverage for the dependency manifests it actually ships, a predictable weekly cadence, fewer routine update PRs, and separately reviewable major upgrades. Low-level ecosystem names and category rules may vary because they follow actual manifest formats and Dependabot support. The R19 divergence analysis classifies this as partly harmonized: grouping policy may be an organization-level policy, while Cargo’s ecosystem key is Rust-specific. [R19 divergence analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md#L103), retrieved 2026-09-05.

The current Cargo option surface supports the recommended shape: `cargo` is a supported ecosystem; `groups` accept `patterns`, `exclude-patterns`, `applies-to`, and `update-types`; Cargo supports `cooldown.default-days` and SemVer-specific cooldown days; `commit-message` and `labels` apply per package manager. Crucially, `groups.dependency-type` is supported only by Bundler, Composer, Mix, Maven, npm, and pip — not Cargo — so Python’s runtime/dev-tools/lint/test structure cannot be reproduced truthfully through dependency type. A Cargo group may use package-name patterns, but that duplicates a changing dependency inventory and provides no semantic guarantee. [GitHub package-ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem), [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), and [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

The architectural alternatives are: (1) Python-style named package-pattern groups, explicit five-day cooldown, labels, and message prefix; (2) one `minor-and-patch` group per ecosystem with no custom presentation keys; or (3) no grouping. Option 1 creates category names that drift as a template’s Rust dependencies evolve and loses its `dependency-type` basis on Cargo. Option 3 preserves the default one-PR-per-dependency behavior, which is needless review fragmentation for routine compatible releases. Option 2 keeps routine updates reviewable while exposing major changes individually, uses only portable documented group keys, and has the lowest future configuration-maintenance cost. The proposal does not claim a performance advantage: Dependabot is a hosted service and no comparable workload, latency, throughput, or resource benchmark applies. [GitHub groups behavior](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

An observable acceptance criterion is a checked-in file with exactly one `cargo` and one `github-actions` update entry, both weekly and rooted at `/`, each containing a `minor-and-patch` group with `minor` and `patch`; it contains no `npm`, `labels`, `commit-message`, or explicit `cooldown` key unless a matching manifest or a separately owned policy is later added. Major updates remain outside the group and therefore separate. GitHub’s documented default now applies a three-day cooldown to version updates when no explicit cooldown is set; security updates are not delayed. [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

BASELINE-REVIEW: F054 — reduce dependency-update review noise without hiding major changes — replace the Python named-category-plus-explicit-five-day presentation shape with a single minor/patch group per actual Rust ecosystem and documented default cooldown — Cargo lacks `groups.dependency-type`, while GitHub documents `update-types` and a three-day default cooldown; evidence: https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups-- and https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown- (retrieved 2026-09-05).

### Recommendation

Adopt the **two-ecosystem, weekly, single-semver-group Dependabot stack**: `cargo` for root Cargo manifests and lockfiles, plus `github-actions` for workflow and root action manifests; each entry uses a `minor-and-patch` group with `update-types: [minor, patch]`. Omit `npm`, because this Rust template has no JavaScript manifest or lockfile; omit named Cargo category groups, explicit `cooldown`, `labels`, and `commit-message`. This preserves the shared freshness capability and TypeScript’s low-noise policy without copying Python-only dependency categories or overriding the current documented three-day default cooldown. [GitHub ecosystem rule](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem), [GitHub grouping rule](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), and [pinned TypeScript configuration](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/dependabot.yml#L27-L50), retrieved 2026-09-05.

### Members

#### Cargo dependency manifests

##### Landscape

Candidate category: Dependabot’s first-party `cargo` ecosystem. No third-party crate is selected. Crate figures — 90-day downloads, all-time downloads, release, stars, issues, responsiveness, RustSec advisories, and adopters — are **inapplicable** because this member is hosted configuration rather than a crate or a transitive dependency tree. Cargo is a documented Dependabot ecosystem; `cargo-llvm-cov` provides a maintained Rust reference that declares it. [GitHub ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem) and [cargo-llvm-cov configuration](https://raw.githubusercontent.com/taiki-e/cargo-llvm-cov/main/.github/dependabot.yml), retrieved 2026-09-05.

##### Principles and implementation

Cargo updates must keep `Cargo.toml` and `Cargo.lock` fresh without making compatible-change review unbounded. `groups.minor-and-patch.update-types` is supported for groups, while Cargo cannot use `groups.dependency-type`; therefore one SemVer group is a real capability match and Python-style runtime/dev categories are not. [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Dominant choice

Use `package-ecosystem: cargo`, `directory: /`, a weekly schedule, and one `minor-and-patch` group that includes `minor` and `patch`. This is the minimal native shape that groups routine SemVer updates while leaving majors separate. [GitHub ecosystem and group references](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem), retrieved 2026-09-05.

##### Qualified shortlist

Qualified alternatives are a single all-update Cargo group and manually maintained package-pattern groups. Both are schema-valid through `groups`, but the former hides majors and the latter has no Cargo dependency-type semantics. [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Excluded by gate

Python-style `development` and `production` group categories are excluded by a schema fitness gate: Dependabot lists `groups.dependency-type` support for Bundler, Composer, Mix, Maven, npm, and pip only. License compatibility, MSRV, RustSec advisories, unsafe posture, feature/runtime coupling, binary size, compile time, and crate-platform testing are **inapplicable** to a hosted configuration pattern; the configuration has no crate, dependency tree, executable, or Rust code. The resulting template must still test its own Cargo project on the fixed Ubuntu and macOS matrix. [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Up-and-comers

Multi-ecosystem groups are not selected: this member’s Cargo manifest family and the workflow member’s action references have separate review domains, and a template with one root Cargo directory gains no demonstrated benefit from cross-ecosystem batching. The current group mechanism already supplies the required per-ecosystem control. [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Fit for this template

The CLI, library, and optional web service share one Rust dependency graph, so one root Cargo entry covers their common manifest. The shape is smaller and more maintainable than Python’s named patterns while retaining a weekly, low-noise upgrade lane. [R19 prompt source precedent](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/topics/19-dependabot-config-shape/prompts/dependabot-config-shape.prompt.md), retrieved 2026-09-05.

##### Recommendation

Declare the Cargo entry with a weekly schedule and `minor-and-patch: { update-types: [minor, patch] }`; do not declare explicit cooldown, labels, or a commit-message prefix. The documented implicit three-day cooldown applies to version updates. [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

##### Ranked runner-up

Runner-up: the same group plus `cooldown.default-days: 5`. Cargo supports the key, and cargo-llvm-cov demonstrates it in practice, but it is not preferred because it adds a policy override beyond Dependabot’s documented default without template-specific evidence that five days improves review outcomes. [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-) and [cargo-llvm-cov configuration](https://raw.githubusercontent.com/taiki-e/cargo-llvm-cov/main/.github/dependabot.yml), retrieved 2026-09-05.

##### Tradeoffs

Minor and patch releases share one PR, reducing review count but coupling their test result; major releases remain individual, preserving an explicit compatibility review. Omitting Python-like category labels sacrifices category-specific triage but avoids stale name-pattern maintenance and an unsupported dependency-type distinction. [GitHub groups behavior](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Parameters

owns: none. assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`; none changes Dependabot’s Cargo schema. No `CONFLICT:` applies. [Fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L20-L33), retrieved 2026-09-05.

##### Migration implications

Create `.github/dependabot.yml` with one Cargo update block. Do not copy Python’s `uv` or `npm` entries or its Cargo-inapplicable `prefix-development` convention. [Python pinned configuration](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/dependabot.yml#L14-L45) and [GitHub commit-message reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#commit-message), retrieved 2026-09-05.

##### Validation strategy

Planned, not executed: add a root `Cargo.toml` and `Cargo.lock`, commit the recommended update block, then observe Dependabot creating a grouped minor/patch version-update PR after its weekly check; update a dependency across a major version and confirm it is not absorbed by that group. Run the template’s existing `cargo test` matrix on `ubuntu-latest` and `macos-latest` for each generated PR. GitHub documents that groups combine matching updates and leave unmatched updates individual. [GitHub groups behavior](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Confidence & re-verify trigger

Confidence: high for the schema and medium for the resulting review-noise tradeoff, because the latter requires real template PR volume. Re-verify when GitHub changes Cargo group support or default cooldown behavior, when the repository gains multiple Cargo directories, or when measured Dependabot PR volume shows the group is too broad. [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--) and [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

##### Sources

Primary schema: [GitHub Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), retrieved 2026-09-05. Practice reference: [cargo-llvm-cov configuration](https://raw.githubusercontent.com/taiki-e/cargo-llvm-cov/main/.github/dependabot.yml), retrieved 2026-09-05.

#### GitHub Actions workflows

##### Landscape

Candidate category: Dependabot’s first-party `github-actions` ecosystem. Crate figures — downloads, releases, crate advisories, crate MSRV, and Rust-specific build costs — are **inapplicable** because workflow actions are not Rust crates selected by this item. Dependabot requires an update entry for each package manager to monitor and documents `github-actions` as the ecosystem value; Tokio provides a maintained Rust-project example. [GitHub ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem) and [Tokio configuration](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/dependabot.yml), retrieved 2026-09-05.

##### Principles and implementation

Workflow action references need automated freshness independently from Cargo packages, particularly when action versions are pinned under the repository’s separate action-pinning policy. A group with minor and patch `update-types` retains major-action upgrades as explicit reviews. GitHub Actions does not support SemVer-specific cooldown days, but it does support default cooldown days; the recommendation needs neither explicit setting. [GitHub cooldown support table](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

##### Dominant choice

Use `package-ecosystem: github-actions`, `directory: /`, weekly scheduling, and one `minor-and-patch` group with `minor` and `patch`. For this ecosystem, `/` makes Dependabot search `/.github/workflows` and root `action.yml` or `action.yaml` files. [GitHub directories reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#directories-or-directory--), retrieved 2026-09-05.

##### Qualified shortlist

Qualified alternatives are one all-action group, one minor/patch group, and individual action updates. The selected SemVer group is the only alternative that simultaneously reduces routine PR count and retains major action changes for separate review. [GitHub groups behavior](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Excluded by gate

No Rust crate candidate exists, so license compatibility, MSRV/dependency-tree compliance, RustSec status, unsafe posture, Rust default features/runtime coupling, binary size, and compile time are **inapplicable**. OS build testing is also inapplicable to Dependabot’s hosted workflow-reference parser; the generated action-update PR still has to pass the template’s Ubuntu and macOS CI. A SemVer-specific cooldown is excluded because GitHub documents it as unsupported for GitHub Actions. [GitHub cooldown support table](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

##### Up-and-comers

Multi-ecosystem grouping is not selected because combining Cargo and action updates would make CI/toolchain changes inseparable from library dependency updates without evidence of a review benefit. Per-ecosystem groups are the documented established configuration mechanism. [GitHub groups reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Fit for this template

The template will ship workflows on both fixed operating systems and likely reference official and third-party GitHub Actions. A dedicated action updater matches both source repositories and lets the existing action-pinning decision remain independently enforceable. [Python pinned configuration](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/dependabot.yml#L47-L62) and [TypeScript pinned configuration](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/dependabot.yml#L27-L38), retrieved 2026-09-05.

##### Recommendation

Declare the GitHub Actions entry with the same weekly `minor-and-patch` group and omit `cooldown`, `labels`, and `commit-message`. Default Dependabot labels retain ecosystem information; custom labels would replace defaults and silently do nothing for labels absent from a consumer repository. [GitHub labels reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#labels--), retrieved 2026-09-05.

##### Ranked runner-up

Runner-up: add `cooldown.default-days: 5` to align visually with Python. It is schema-supported for GitHub Actions but offers no demonstrated Rust-template benefit over the documented default and cannot express separate minor and patch holds for this ecosystem. [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

##### Tradeoffs

Grouping routine action updates lowers PR noise but means one bad minor or patch action release can block the group until edited or retried. Keeping majors separate gives action version and permission changes their own review. Omitting a prefix avoids adding a conventional-commit contract that this item does not own; custom commit-message settings affect PR titles as well as commits. [GitHub commit-message reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#commit-message), retrieved 2026-09-05.

##### Parameters

owns: none. assumes `target-os-matrix = ubuntu-latest, macos-latest`; this member refreshes workflow references but does not alter the runner matrix or the separate action-pinning policy. No `CONFLICT:` applies. [Fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L20-L33), retrieved 2026-09-05.

##### Migration implications

Add the second update block to `.github/dependabot.yml`; no Rust source or Cargo manifest changes are required. Do not add an `npm` block unless a committed JavaScript manifest or lockfile later exists, because GitHub requires a manifest or lockfile for each monitored package manager. [GitHub ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem), retrieved 2026-09-05.

##### Validation strategy

Planned, not executed: commit workflows containing a versioned action and the recommended update block, allow the weekly Dependabot check, then verify that a minor or patch action update arrives in the group and a major action update does not. Run the resulting PR through the Ubuntu and macOS workflow matrix and the action-pinning checker owned by R20. [GitHub groups behavior](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

##### Confidence & re-verify trigger

Confidence: high for the documented ecosystem and group syntax; medium for the selected review batching until real action-update PRs are observed. Re-verify if action references stop using SemVer-like versions, GitHub changes group semantics, or R20 selects a pinning style that Dependabot cannot update. [GitHub package-ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem), retrieved 2026-09-05.

##### Sources

Primary schema: [GitHub Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), retrieved 2026-09-05. Practice reference: [Tokio configuration](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/dependabot.yml) and [Tokio repository API](https://api.github.com/repos/tokio-rs/tokio), retrieved 2026-09-05.

### Compatibility

The members are proven compatible by `cargo-llvm-cov`’s single committed configuration: it declares both `cargo` and `github-actions`, each rooted at `/`, with independent cooldown and presentation options. The recommendation is a smaller subset of that documented, deployed two-ecosystem composition, replacing only its custom cooldown/labels/prefix with the shared minor/patch group policy. [cargo-llvm-cov configuration](https://raw.githubusercontent.com/taiki-e/cargo-llvm-cov/main/.github/dependabot.yml), retrieved 2026-09-05.

### Parameters

owns none. assumes `rust-edition = 2024`; `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `license = MIT OR Apache-2.0`; and `target-os-matrix = ubuntu-latest, macos-latest`. No consumed parameter needs alteration; therefore no `CONFLICT:` line is emitted. [Fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md#L20-L33), retrieved 2026-09-05.

### Migration implications

Add `.github/dependabot.yml` with version `2` and exactly the two update entries below. This is proposed configuration, not an executed change.

```yaml
version: 2
updates:
  - package-ecosystem: cargo
    directory: /
    schedule:
      interval: weekly
    groups:
      minor-and-patch:
        update-types: [minor, patch]
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    groups:
      minor-and-patch:
        update-types: [minor, patch]
```

The file intentionally omits `npm`, `labels`, `commit-message`, and `cooldown`. GitHub requires a manifest or lockfile for each declared ecosystem; labels and commit-message keys change otherwise-default PR presentation; and the current default cooldown is three days for version updates. [GitHub ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem), [GitHub labels reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#labels--), [GitHub commit-message reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#commit-message), and [GitHub cooldown reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#cooldown-), retrieved 2026-09-05.

### Validation strategy

Planned acceptance check, not executed: (1) inspect the committed file to confirm only `cargo` and `github-actions` blocks exist; (2) seed one patch/minor and one major candidate in each ecosystem; (3) allow Dependabot’s scheduled version-update check to create PRs; (4) confirm every minor/patch candidate is grouped by ecosystem and every major remains individual; and (5) run the template’s Cargo and workflow checks on `ubuntu-latest` and `macos-latest` for the generated PRs. The expected result follows from GitHub’s rule that matching groups combine updates and unmatched dependencies get individual PRs. [GitHub groups behavior](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--), retrieved 2026-09-05.

### Confidence & re-verify trigger

High confidence: both required ecosystems and the selected group/cooldown capabilities are documented by GitHub. Medium confidence: a single minor/patch group is the best review-noise policy until the template receives real update PRs. Re-verify before implementation if GitHub changes the Cargo support table or default cooldown, if the template adds a JavaScript manifest, or after ten Dependabot PRs demonstrate that grouping is too broad or too narrow. [GitHub Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), retrieved 2026-09-05.

### Sources

- [GitHub Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), retrieved 2026-09-05 — primary schema authority for `cargo`, `github-actions`, groups, cooldown, labels, and commit messages.
- [Python pinned Dependabot configuration](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/dependabot.yml) and [TypeScript pinned Dependabot configuration](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/dependabot.yml), retrieved 2026-09-05 — immutable source precedent.
- [TypeScript D-022](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/docs/port/TS_PORT_DECISIONS.md#L267-L292), retrieved 2026-09-05 — recorded rationale for Dependabot rather than Renovate and low-noise grouping.
- [cargo-llvm-cov configuration](https://raw.githubusercontent.com/taiki-e/cargo-llvm-cov/main/.github/dependabot.yml), [cargo-llvm-cov repository API](https://api.github.com/repos/taiki-e/cargo-llvm-cov), [Tokio configuration](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/dependabot.yml), and [Tokio repository API](https://api.github.com/repos/tokio-rs/tokio), retrieved 2026-09-05 — Rust practice and maintenance signals.

Method notes: queried GitHub’s current Dependabot documentation and source, plus `GET https://api.github.com/repos/taiki-e/cargo-llvm-cov` and `GET https://api.github.com/repos/tokio-rs/tokio`, with raw committed configurations retrieved on 2026-09-05. No crates.io `/api/v1/crates/<name>` or `/versions` endpoints and no RustSec package pages were queried because R19 selects no crate; every crate-specific figure and fitness metric is explicitly inapplicable above. No live Dependabot PR was created, so scheduled-service behavior remains proposed validation rather than executed evidence.
