# R38 commit-message-linter — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260908-223857-c8861c11e5304bd4 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's fifteen template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label. Every line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory, and raw/doxa-<provider>.normalized.md hold the bodies individually). Two lossless heading adjustments: Perplexity's `## Sources` is treated as the `### Sources` field, and headings that precede a provider's first template field or follow its last one are demoted to bold text so no H2 or H3 outside the template remains.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI gpt-5.6-sol, job resp_01b63876d80acafe006aa0f0f1a5e887d0b730e20b3db8d09d, saved-file sha256 67639d29963a2096e7fe06bc64ba1e11730676d0d7f384f6123e6415df423c8a**



**Perplexity sonar-deep-research, job c8e6c06b-454c-4535-b68c-0a3f5afbbb6a, saved-file sha256 2566089454d27cce530cd48e2a1df1d2c098e4adab208e627baf4e4e7be86c02**

**R38 — Commit-message linter for `rs-launch-blueprint`**
The decision for R38 is to adopt **commitlint**, configured with `@commitlint/config-conventional` and Rust-specific rule overrides, as the tool that enforces Conventional Commits both at `commit-msg` hook time and in CI for `rs-launch-blueprint`. The chosen configuration preserves the shared principle across the Python, TypeScript and Rust blueprints—namely, that commit messages must be syntactically valid Conventional Commits and adhere to a clearly specified type-enum and readable length limits—while accepting an ecosystem-specific tradeoff: a lightweight Node/Bun runtime provisioned as developer tooling inside a Rust project. The recommended rule set for Rust aligns deliberately with the TypeScript port’s stricter editorial choices (explicit type-enum, `header-max-length` 50, `body-max-line-length` 72, `footer-max-line-length` 100) and uses commitlint’s own documented exemption for URL lines to avoid penalizing documentation-heavy commits.[7] This report finds that, as of the current survey, no native-Rust linter (including Cocogitto’s `cog check` and Conventional Commits Linter) offers the same combination of strict Conventional Commits enforcement, configurable type-enum, per-field length rules, and robust CI and hook integration under the template’s licensing and MSRV constraints.[3][5][9][11][13][19] Consequently, commitlint remains the dominant choice, with Cocogitto positioned as the ranked runner-up that becomes preferable if a future version adds configurable editorial rules and the owner later prioritizes avoiding any Node/Bun dependency in Rust repositories.

**Context and problem framing**
The `rs-launch-blueprint` template is specified as a three-part Rust project—a CLI, a library, and a web service—subject to owner-fixed parameters that constrain the technical choices for every registry item.[docs/port/PARAMETERS.md] For R38, the relevant parameters include `rust-edition = 2024`, an MSRV policy of “stable minus two minor versions, raised only in a minor release, declared as `rust-version` in `Cargo.toml` and tested in CI”, licensing as `MIT OR Apache-2.0`, and a CI operating-system matrix of `ubuntu-latest` and `macos-latest`. These parameters apply directly to any Rust crate or binary introduced into the template, and indirectly to dev tooling to the extent that it shapes the project’s reproducibility and contribution workflows.

The engineering question is narrow but structurally important. Prior decisions in the Python and TypeScript launch blueprints established a **shared pattern**: Conventional Commits are enforced at `commit-msg` hook time by a linter tool, commitlint, configured with `@commitlint/config-conventional`, and in the Python case re-run in CI via a dedicated GitHub Action.[7][8][10] This pattern is recorded as feature F148 (“commit-message linting enforced at commit-msg hook time”), classified `COMMON → REUSE`, and therefore explicitly out of scope for R38: the fact that linting happens at `commit-msg` time cannot be reopened here. Instead, R38 owns the **tool choice and its rule configuration** for the Rust template—what crate or tool enforces Conventional Commits, how its type-enum and length limits are defined, and whether those rules are mirrored in CI.

The context also includes a recorded divergence between the Python and TypeScript ports. Both use commitlint layered on `@commitlint/config-conventional`, but they differ in their overrides to the upstream configuration.[4][7][10] The Python blueprint raises `body-max-line-length` and `footer-max-line-length` to 200 characters to accommodate documentation URLs and relies on the default 100-character header limit, while leaving the type-enum at the upstream config’s eleven types.[4][7] The TypeScript blueprint tightens `header-max-length` to 50 characters, restricts `body-max-line-length` to 72 characters, leaves `footer-max-line-length` at 100, and defines an explicit eleven-element type-enum kept in lockstep with `.gitmessage` via a test of the commit-message template and configuration.[4][7][10] These choices are recorded in features F152–F155, with verdicts `DIVERGENT` and `COMMON → SUBSTITUTE` in the owner’s ledger, and therefore form evidence rather than a predetermined decision for Rust.

R38 is also coupled to related items. The `commit-message-convention` parameter defined here is consumed by R24 (changelog-section mapping) and by the release-please configuration that structures automated releases and changelog sections (ledger rows F063, F066, F073). These consumers depend on the **shape** of the type-enum—its names and intended semantic categories—but not on the exact linter tool or implementation language. R37, by contrast, owns the hook manager distribution and installation mechanism that wires the `commit-msg` stage (e.g., Lefthook job definitions). This division of responsibility means that R38 must pick a linter that can be invoked by the existing hook manager and CI workflows, but does not decide how Lefthook is installed or how other hooks are replayed.

Within this framing, the questions posed by the owner fall into three tiers. At the high-priority level, we must determine whether a native-Rust Conventional Commits linter exists that matches commitlint’s configurability for type-enum and header/body/footer length overrides, and if not, whether the template should accept a Node/Bun-based commitlint, with a robust provisioning path and explicit avoidance of past silent-pass failure modes. We must also identify the engineering principles that must remain shared across the Python, TypeScript and Rust templates, and ensure that any divergence we introduce in Rust can be justified as an ecosystem-appropriate difference rather than accidental drift. At medium priority, we must choose concrete header/body/footer length limits and a type-enum list for Rust in light of the disagreement between Python and TypeScript, and decide whether CI re-run of the linter is warranted given the possibility of bypassing local hooks with `--no-verify`. At low priority, we must consider whether to carry over a per-author relaxed ruleset for bot PRs (e.g., Dependabot), and whether the tool we choose supports such per-author configuration selection.

With this context in mind, the remainder of the report proceeds from landscape mapping to principle extraction, evaluates candidate architectures and libraries against fitness gates, and then arrives at a defensible recommendation with an explicit statement of parameters, tradeoffs, and validation strategy.

**Analytical core**

**Gemini deep-research-preview-04-2026, job v1_Chc4X0NnYXM2ckFfYWI5TW9QanN6eG1RcxIXOF9DZ2FzNnJBX2FiOU1vUGpzenhtUXM, saved-file sha256 62cd3e1134e295b0690bacc3e6337630951901933c771de0e35872a0e96e19e6**

**Deep-Research Report: Commit-Message Linter Architecture for rs-launch-blueprint**

### Landscape

**OpenAI gpt-5.6-sol**

**Research date:** September 9, 2026. Unless marked as owner-supplied repository evidence, every cited web source was retrieved on that date.

#### Three-bin map

| Bin | What exists in this category | Candidates carried forward |
|---|---|---|
| **Built-in or first-party toolchain** | Git supplies the `commit-msg` hook point, but the Rust toolchain has no first-party Conventional-Commits linter. A repository-owned Rust `xtask` could be built, but that would make the template the linter maintainer. Current stable Rust is 1.98.1, making the fixed “stable minus two” gate Rust 1.96.x. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/?utm_source=openai)) | Custom `xtask` architecture, rejected unless external tools cannot satisfy the contract. |
| **Established industry standard** | Conventional Commits 1.0.0 is the normative message format. The established configurable linter is Node-based `@commitlint/cli` layered on `@commitlint/config-conventional`. Established Rust tools include `committed`, Cocogitto and Convco. ([conventionalcommits.org](https://www.conventionalcommits.org/?utm_source=openai)) | `@commitlint/cli`, `committed`, `cocogitto`, `convco`. |
| **Up-and-comer** | `cargo-commitlint` implements a broad commitlint-compatible TOML/JSON/YAML rule model, including the required enum and independent header/body/footer rules. `conventional_commits_linter` is a smaller preset-oriented checker. A new Go tool also named `commitlint` implements similar rules but is neither the established Node tool nor Rust-native. ([github.com](https://github.com/quinnjr/cargo-commitlint)) | `cargo-commitlint`, `conventional_commits_linter`, Go `conventionalcommit/commitlint`. |

#### Why the sources are authoritative

- **Conventional Commits** is the normative specification. It defines structure and breaking-change semantics, but deliberately does not prescribe an eleven-type enum or line-length limits. Additional types are permitted. ([conventionalcommits.org](https://www.conventionalcommits.org/?utm_source=openai))
- **Commitlint’s official documentation and config-conventional source** define the actual rule semantics, configuration precedence, parser model and inherited defaults being considered. ([commitlint.js.org](https://commitlint.js.org/reference/rules.html?utm_source=openai))
- **Candidate-maintainer documentation and source repositories** are primary evidence for supported commands and configuration—not third-party feature summaries. ([github.com](https://github.com/crate-ci/committed/blob/master/docs/reference.md))
- **Rust Release Team publications** establish the current stable release used to evaluate the fixed MSRV policy. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))
- **Direct adopter repositories** are practice evidence. Homebrew is useful only as packaging/platform evidence, not as proof of architectural fitness. ([github.com](https://github.com/rust-cli/config-rs?utm_source=openai))

#### Practice evidence from well-regarded Rust projects

The strongest public Rust practice signal found was for **`committed`**:

- `rust-cli/config-rs` contains both `committed.toml` and pre-commit configuration. It is an established Rust configuration library under the `rust-cli` organization. ([github.com](https://github.com/rust-cli/config-rs?utm_source=openai))
- `toml-rs/toml`, the Rust TOML parser workspace, contains `committed.toml` and pre-commit configuration. ([github.com](https://github.com/toml-rs/toml?utm_source=openai))
- `rust-lang/annotate-snippets-rs` is maintained in the `rust-lang` organization and contains `committed.toml`. ([github.com](https://github.com/rust-lang/annotate-snippets-rs?utm_source=openai))
- `crate-ci/cargo-release` also carries `committed.toml`, demonstrating adoption in Rust release tooling. ([github.com](https://github.com/crate-ci/cargo-release?utm_source=openai))
- Ariel OS carries `committed.toml` and uses the pinned `crate-ci/committed` action in its workflow. ([github.com](https://github.com/ariel-os/ariel-os/issues/1244?utm_source=openai))

That evidence establishes `committed` as a real and maintained Rust practice—not as a fit winner. Its configuration model still lacks this item’s required independent field limits.

Cocogitto has substantial packaging support across macOS and Linux and a maintained GitHub Action, but the action itself is documented as x86 Linux-only. Its standalone binary remains usable outside the action. ([formulae.brew.sh](https://formulae.brew.sh/formula/cocogitto?utm_source=openai))

No external adopter of equivalent standing was established in this run for `cargo-commitlint`, Convco or `conventional_commits_linter`. That is an evidence gap, not proof of non-use.

#### Required-figure audit

The prescribed crates.io, GitHub API and RustSec endpoints were attempted, but the research gateway rejected direct API retrieval before receiving HTTP responses. I therefore **do not substitute rounded GitHub HTML counts, old lib.rs estimates or invented values**.

Affected native candidates:

- `committed`
- `cocogitto`
- `convco`
- `conventional_commits_linter`
- `cargo-commitlint`

The required endpoints remain:

```text
GET https://crates.io/api/v1/crates/<name>
GET https://crates.io/api/v1/crates/<name>/versions
GET https://api.github.com/repos/<owner>/<repo>
GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open
GET https://rustsec.org/packages/<name>.html
```

The crates.io response fields are indeed `crate.recent_downloads`, `crate.downloads`, and version records containing `num`, `created_at`, `yanked` and `rust_version`. ([tarka.ai](https://tarka.ai/playbook/fundamentals/registry-download-tracking?utm_source=openai))

Consequences:

1. Popularity and issue-response numbers were **not used to select a winner**.
2. No native crate is represented below as having completely passed the advisory, dependency-tree-MSRV and responsiveness evidence gates.
3. Re-running the exact endpoint collection is a mandatory pre-merge prerequisite.

**Perplexity sonar-deep-research**

The category decided by R38 is the **commit-message linter** that enforces a Conventional Commits-based `commit-message-convention` at `commit-msg` hook time and in CI for `rs-launch-blueprint`. It operates as developer tooling rather than part of the runtime code path, but its choice has architectural implications because it can introduce language runtimes (Node or Bun) or additional Rust binaries into the template, and it defines the semantics that downstream changelog tooling and release automation rely on.

Following the owner’s survey method, the Rust field for this category must be mapped into three bins: built-in or first-party toolchain, established industry standard, and up-and-comer. In the Rust ecosystem, there is no built-in or first-party toolchain component that enforces Conventional Commits; `cargo` and `git` provide hooks but not semantic commit linting. The conventionality of commit messages is therefore enforced by external tools. Among established industry standards, commitlint stands out as a widely adopted, language-agnostic linter implemented in Node that checks whether commit messages meet the Conventional Commits format and applies a configurable set of rules.[7][8][10] The `@commitlint/config-conventional` package enforces the Conventional Commits convention plus stylistic rules inherited from the Angular commit style, including `header-max-length`, `body-max-line-length`, `footer-max-line-length` and a restricted `type-enum` list.[4][7] These packages, though not Rust crates, are part of the broader developer tooling ecosystem and have already been adopted in the Python and TypeScript launch blueprints.

Within the Rust-specific ecosystem, two tools are closest to established status. The first is **Cocogitto**, a CLI and GitOps toolbox designed to help users adhere to Conventional Commits and semantic versioning.[3][11][12][17] Cocogitto provides the `cog commit` subcommand to create commits that respect the Conventional Commits specification, offering predefined commit types aligned with Angular conventions such as `feat`, `fix`, `style`, `build`, `refactor`, `ci`, `test`, `perf`, `chore`, `revert` and `docs`.[3] It also includes `cog check` to verify repository history against the Conventional Commits specification and `cog bump` to automatically calculate the next version based on commit types since the latest tag, update `CHANGELOG.md`, create a version commit and tag, and run pre- and post-bump hooks.[3][5] Cocogitto supports configuration via a `cog.toml` file at the repository root and exposes a GitHub Action, `cocogitto-action`, that can be used in CI to perform releases, check commits against the conventional commit specification, and create changelogs.[1][19] Because Cocogitto is written in Rust and distributed as binaries and crates, it fits the Rust ecosystem well.

The second Rust tool is **Conventional Commits Linter**, a tooling- and language-agnostic utility written in Rust that lints Git commits against the Conventional Commits specification.[9][15] The linter can operate on a range of Git commits in the repository’s history or on a single commit message provided via standard input, linting each message against the Conventional Commits v1.0.0 specification and exiting with a non-zero status if any commit fails, accompanied by error messages explaining why.[9] By default, it applies only strict specification compliance rules, but additional subjective linting rules can be enabled, and the tool is designed to offer “sensible defaults” and “configurable” behavior.[9] Conventional Commits Linter is available as both a Rust crate and prebuilt binaries, with installation supported via `cargo install` and a Docker image.[9][13][15] However, its companion library `conventional_commits_linter_lib` is licensed under AGPL-3.0, which has implications for its suitability under the template’s licensing constraints.[13]

In the up-and-comer bin, two Rust-oriented components merit attention. The first is the **standard_commit** library, which provides Conventional Commit parsing, validation and formatting as a pure Rust library with no I/O, git operations or terminal output.[20] It exposes `parse` to turn a message string into a `ConventionalCommit` struct, `lint` to validate a message against a configurable `LintConfig`, and `format` to render a `ConventionalCommit` back into a well-formed string, thereby encapsulating the core semantics of the Conventional Commits specification in a composable Rust API.[20] This library is designed for embedding into custom tools rather than operating as a CLI, but it opens the possibility of building a Rust-native linter tailored to the blueprint’s needs. The second up-and-comer is **committed**, a tool referenced in the env_logger project’s contributing guidelines, where all commits must follow the Conventional Commits specification enforced via committed.[18] The guidelines describe the conventional commit format, list common commit types such as `feat`, `fix`, `docs`, `refactor`, `test` and `chore`, and emphasize atomic commits, while noting that committed is integrated both as a local pre-commit hook and as a CI check.[18] Although the search results do not include committed’s own documentation or crate metadata, its adoption by env_logger—a widely used Rust logging crate—suggests that it is a serious entrant in the up-and-comer category.

Authority for the Conventional Commits specification itself can be anchored in the documentation of tools that implement it. Both commitlint and Cocogitto restate the specification’s core structure: a commit message consists of a `<type>[optional scope]: <description>` header line, followed by an optional body and optional footer(s).[3][8][10] Commitlint’s README explicitly presents this format, and its default configuration and rule reference reinforce the semantics of `type` as a required, lower-case token drawn from a known list, `scope` as an optional lower-case identifier, and `subject` as a required description constrained by case and length rules.[4][7][10] Cocogitto’s guide similarly treats Conventional Commits as the foundation for automatic versioning, with `cog bump` computing semantic version increments based on commit types since the last tag.[3] These tools thus serve as authoritative sources for both the specification and its typical enforcement in practice.

Practice evidence in the Rust ecosystem shows a mix of approaches. Cocogitto’s documentation and release cadence indicate active maintenance and a focus on production usage, and the existence of an official GitHub Action (`cocogitto-action`) for CI integration suggests that projects using Cocogitto do so both locally and in CI.[1][3][11][12][17] Conventional Commits Linter’s crate and GitHub repository emphasize strict correctness and performance, leveraging Rust’s speed and offering binaries for multiple architectures, making it attractive for CI pipelines where performance and strict adherence to the specification are desired.[9][13][15] Env_logger’s use of committed for Conventional Commits enforcement in both local hooks and CI demonstrates that some well-regarded Rust projects value native tooling that integrates cleanly with pre-commit frameworks and that enforce not only syntactic correctness but also atomicity of commits.[18] Outside Rust, commitlint is widely used across JavaScript and TypeScript projects, and its adoption in the Python and TypeScript launch blueprints provides evidence of cross-language suitability and organizational familiarity.[7][8][10]

However, the owner’s survey method requires that fitness be judged against the **use case of the Rust template** and the precedent in Python and TypeScript, not against abstract popularity. For `rs-launch-blueprint`, the commit-message linter must integrate with a hook manager (such as Lefthook), work across the `ubuntu-latest` and `macos-latest` CI matrix, be configurable with a custom type-enum and per-field length overrides, and ideally avoid licensing and MSRV conflicts with the project’s Rust code, though dev tooling may be exempt from some crate-specific constraints. It also must support re-running in CI to catch bypasses of local hooks. The landscape mapping therefore identifies commitlint as the established industry standard tool that already meets these requirements in other languages, Cocogitto and Conventional Commits Linter as Rust-native candidates with varying degrees of configurability, and standard_commit and committed as up-and-comer components that could be composed into a custom Rust solution.

**Gemini deep-research-preview-04-2026**

The domain of commit-message linting within the Rust ecosystem resides at the critical intersection of version control hygiene and automated release orchestration. For the `rs-launch-blueprint` template, the selection of a commit-message linter dictates not only the local developer experience via git hooks but also the downstream integrity of changelogs and semantic versioning automation. Following the rigorous research mandate, the current ecosystem of Rust-compatible commit-message linters is mapped into three distinct categories based on their architecture and adoption.

| Category | Description | Representative Candidates |
| :--- | :--- | :--- |
| **Built-in / First-Party Toolchain** | The official Rust toolchain (Cargo, rustc, rustfmt, clippy) strictly focuses on code semantics and formatting. It delegates commit convention enforcement entirely to third-party tooling, offering no native solution. | *None applicable* |
| **Established Industry Standard** | Historically, the broader open-source ecosystem has relied on the Node.js-based `commitlint` layered with `@commitlint/config-conventional` [cite: 1, 2, 3]. Within the Rust-specific ecosystem, monolithic native tools have emerged as standard release managers. | `cocogitto` [cite: 4, 5], `committed` [cite: 6], `convco` [cite: 7, 8] |
| **Up-and-Comer** | Tools explicitly designed to provide zero-overhead, direct parity with the Node.js `commitlint` configuration model without the JavaScript runtime dependency, alongside next-generation AI-aware linters. | `cargo-commitlint` [cite: 9], `commitlint-rs` [cite: 10, 11], `gitfluff` [cite: 12, 13] |

Authority in this analysis is derived from several foundational sources. The Conventional Commits 1.0.0 specification serves as the absolute source of truth for the structural grammar of semantic commits, dictating the presence of types, optional scopes, descriptions, and breaking change footers [cite: 14]. Furthermore, Tim Pope’s seminal 2008 Git commit guidelines establish the mechanical necessity of the 50/72 rule, optimizing messages for `git log` output and patch-based email workflows [cite: 14, 15]. Ecosystem adoption and stability metrics are sourced from `crates.io` API endpoints and `lib.rs` ecosystem statistics [cite: 16], while security postures are validated against the authoritative RustSec Advisory Database, which maintains the ledger of vulnerabilities across the Cargo dependency tree [cite: 17, 18, 19].

Practice evidence across mainstream, well-regarded Rust projects reveals a strong preference for minimal toolchain overhead. Projects heavily leverage native binaries like `rustfmt` and `clippy` for code quality [cite: 20], but commit-linting is frequently enforced via CI-only shell scripts or through statically compiled native binaries integrated into pre-commit managers. A recurring architectural pattern in the Rust ecosystem is the explicit avoidance of cross-language runtime dependencies. The resistance to introducing a Node.js (`package.json`, `node_modules`) or Python environment strictly for utility scripts pushes the ecosystem toward tools that can be distributed natively via `cargo install`, `cargo-binstall`, or pre-compiled GitHub releases [cite: 6, 13]. 

Judged against the specific use case of this template—a CLI, library, and web service—the ideal candidate must prioritize fit over abstract popularity. While monolithic tools like `cocogitto` excel in end-to-end release management for complex monorepos [cite: 5], the `rs-launch-blueprint` specifically requires granular configuration parity with the TypeScript and Python precedents. This necessitates a tool capable of enforcing custom `type-enum` lists and strict per-field length overrides, seamlessly integrating into a `commit-msg` hook and CI pipeline without imposing an alien runtime.

### Principles and implementation

**OpenAI gpt-5.6-sol**

#### Shared requirement and agreement levels

| Level | What must agree across py, ts and rs | What may vary |
|---|---|---|
| **Policy/capability** | Authored commit messages are rejected when they violate one declared Conventional-Commits contract. Enforcement occurs in `commit-msg` and is repeated in CI so `--no-verify` is not an escape hatch. | Hook manager and runtime bootstrap. |
| **Standard** | Conventional Commits 1.0.0 parsing and breaking-change semantics. The owned type names must remain machine-readable and stable for changelog/release consumers. ([conventionalcommits.org](https://www.conventionalcommits.org/?utm_source=openai)) | Additional policy rules not specified by Conventional Commits, including exact line limits. |
| **Architectural pattern** | A single declarative rule configuration drives both local and CI checks; missing runtimes or packages fail closed; `.gitmessage` is mechanically checked against the configuration. | npm versus a native executable, provided behavior is equivalent. |
| **Low-level values** | The eleven type names should agree because py already inherits them, ts explicitly represents them, and downstream release configuration consumes their shape. | Length limits need not match when repositories have genuinely different prose/URL workloads. |
| **Implementation** | The same linter version, configuration and ignore semantics must be used in the hook and CI within one repository. | py may invoke Bun, ts its package manager, and rs an isolated Node runtime. |

The important shared principle is therefore **deterministic, bypass-resistant enforcement of a stable machine-readable commit contract**, not “every repository must invoke npm in the same way.”

#### Architectural alternatives

1. **Provisioned Node + established commitlint**

   This is the only currently established option that directly expresses:

   - an explicit type allow-list;
   - whole-header maximum length;
   - body maximum line length;
   - footer maximum line length;
   - inherited Conventional-Commit parsing and other conventional rules;
   - message-file linting locally and revision-range linting in CI.

   Commitlint supports shareable configs and explicit rule overrides. Its body-line rule exempts lines containing URLs, which addresses much of the Python repository’s stated permalink concern without raising all prose to 200 characters. Footer lines do not have the same documented URL exemption. ([commitlint.js.org](https://commitlint.js.org/reference/rules.html?utm_source=openai))

2. **`committed`**

   `committed` is mature Rust practice and supports `style = "conventional"`, `allowed_types`, `subject_length`, `line_length`, and `hard_line_length`. Its defaults are a 50-column **subject** and 72-column lines. It can consume a commit-message file and check CI ranges. ([github.com](https://github.com/crate-ci/committed/blob/master/docs/reference.md))

   It does **not** expose independent header/body/footer line maxima. In particular, its 50-column rule applies to the description/subject rather than the complete `type(scope): subject` header. Reproducing the proposed `72/72/100` contract would therefore be approximate, not equivalent.

3. **Cocogitto**

   Cocogitto is a maintained Conventional-Commits and SemVer toolbox. It can check history, define or disable commit types, constrain scopes, and run in CI. Its current configuration reference has no line-length rule at all. ([docs.cocogitto.io](https://docs.cocogitto.io/guide/commit.html))

   It also overlaps release and changelog responsibilities already owned elsewhere in this blueprint. Adopting a broad toolbox solely for `cog check` would not buy the required lint policy.

4. **Convco**

   Convco provides `check`, `commit`, `changelog`, and `version`; it accepts a single message on stdin and revision ranges in CI. Its configurable `types` primarily control changelog grouping, while the documented `lineLength` controls generated changelog wrapping—not per-field commit linting. ([convco.github.io](https://convco.github.io/configuration/?utm_source=openai))

5. **`cargo-commitlint`**

   This is the closest technical match. Its documentation advertises a commitlint-compatible model with `type-enum`, `header-max-length`, `body-max-line-length`, `footer-max-line-length`, severity levels, ignore patterns and history linting. ([github.com](https://github.com/quinnjr/cargo-commitlint))

   The problem is not missing capability. It is insufficiently established maintenance, adoption, MSRV-tree, advisory and cross-platform evidence. Its documented dev-dependency integration also installs hooks from a build script, which would conflict with R37’s ownership of hook installation. If selected later, only its CLI should be used.

6. **Repository-owned Rust `xtask`**

   A custom parser-and-rules binary could exactly encode the contract and avoid Node. It would also make `rs-launch-blueprint` responsible for parser edge cases, Git cleanup behavior, trailers, revert/merge ignores, diagnostics and ongoing Conventional-Commits compatibility. That maintenance cost is disproportionate for repository hygiene.

#### Recommended rule values

**Type enum**

```text
build
chore
ci
docs
feat
fix
perf
refactor
revert
style
test
```

This is Conventional Commits 1.0.0 plus the established Angular/config-conventional eleven-type profile; the specification itself mandates only the structural role of `type` and gives `feat` and `fix` semantic significance. ([conventionalcommits.org](https://www.conventionalcommits.org/?utm_source=openai))

Do not add `deps`, `security`, `release` or Rust-specific variants. Dependency changes can use `build(deps)` or `chore(deps)` without changing the downstream enum shape.

**Limits**

| Field | Limit | Rule semantics | Rationale |
|---|---:|---|---|
| Header | **72** | Hard `header-max-length` | Fifty is defensible for a bare Git subject but unnecessarily constrains a complete Conventional-Commit header containing type and scope. One hundred is permissive. Seventy-two is the supported middle ground indicated by Rust’s established `committed` line convention. ([github.com](https://github.com/crate-ci/committed/blob/master/docs/reference.md)) |
| Body line | **72** | `body-max-line-length`; current commitlint semantics exempt lines containing URLs | Keeps prose readable without forcing permalink wrapping. ([commitlint.js.org](https://commitlint.js.org/reference/rules.html?utm_source=openai)) |
| Footer line | **100** | Hard `footer-max-line-length` | Leaves room for trailer tokens, identities and breaking-change text while retaining the config-conventional default rather than Python’s repository-specific 200-character exception. ([commitlint.js.org](https://commitlint.js.org/reference/rules.html?utm_source=openai)) |

All four owned rules are errors, not warnings.

#### Minimal composition

```js
// commitlint.config.mjs
export const commitTypes = Object.freeze([
  'build',
  'chore',
  'ci',
  'docs',
  'feat',
  'fix',
  'perf',
  'refactor',
  'revert',
  'style',
  'test',
]);

export const commitLimits = Object.freeze({
  header: 72,
  bodyLine: 72,
  footerLine: 100,
});

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', commitTypes],
    'header-max-length': [2, 'always', commitLimits.header],
    'body-max-line-length': [2, 'always', commitLimits.bodyLine],
    'footer-max-line-length': [2, 'always', commitLimits.footerLine],
  },
};
```

The local adapter must resolve the repository root and execute the exact runtime and JS entrypoint:

```sh
exec "$repo_root/.tools/node/current/bin/node" \
  "$repo_root/node_modules/@commitlint/cli/cli.js" \
  --config "$repo_root/commitlint.config.mjs" \
  --edit "$commit_message_file"
```

It must not invoke `npx`, `npm exec`, `pnpm exec`, `bunx`, a package script or an unqualified `commitlint` executable. This removes PATH/shim resolution, auto-install and package-script fallback from the enforcement path. The wrapper must test that both the runtime and CLI file exist and exit non-zero if either is absent.

#### Runtime provisioning

Use an isolated **Node 24.x LTS** runtime, with an exact patch and per-platform SHA-256 digests recorded in the bootstrap script. The script must support:

- Linux x86-64 and ARM64;
- macOS x86-64 and ARM64;
- an installation directory ignored by Git, such as `.tools/node/`;
- `npm ci` against a committed lockfile;
- no network installation during `git commit`.

The packages are:

```text
@commitlint/cli >=21.0.0 <22.0.0
@commitlint/config-conventional >=21.0.0 <22.0.0
```

`package-lock.json` selects exact patch versions and integrity hashes. The range defines the accepted update line; local and CI execution always use the lock.

Node is preferred over Bun because it is commitlint’s native upstream environment. Bun remains possible only after a parity test; bootstrap convenience or startup speed alone does not outweigh upstream runtime fidelity.

#### CI architecture

CI should **shell out to the same repository wrapper and locked CLI**, not use `wagoid/commitlint-github-action` or another action that may bundle a different version.

For pull requests:

```text
commitlint --from <pull_request.base.sha> --to <pull_request.head.sha> --verbose
```

For pushes:

```text
commitlint --from <before> --to <after> --verbose
```

The checkout must contain the required history. New-branch pushes, whose `before` SHA is all zeroes, need a documented merge-base/default-branch fallback.

Run the job on both `ubuntu-latest` and `macos-latest`. The work is small, and the duplicated job verifies the fixed target-OS requirement as well as policy enforcement.

#### Bot policy

Do **not** create a bot-specific relaxed configuration initially.

If a demonstrated bot-generated footer cannot meet 100 characters, a future exception may be selected by the trusted GitHub event field such as `github.event.pull_request.user.login`; it must never trust the mutable Git commit author string. Such an exception should disable only the demonstrated length rule and retain type/header enforcement.

#### Performance evidence

No comparable candidate benchmark was found or run. Published “fast” claims are not comparable because workloads and installation state differ.

The relevant workload is:

- hook: one already-written commit-message file;
- CI: approximately 1–200 commits;
- warm local installation;
- Linux and macOS;
- measured process latency, maximum RSS and on-disk runtime/package size.

The proposed acceptance budget is a warm hook p95 below one second and a 200-commit CI range below ten seconds. These are proposed UX budgets, not benchmark results.

#### Baseline findings

`BASELINE-REVIEW: F149 — agreement is the fail-closed enforcement capability and standard, not npm-package identity — proposed change: record rs as REUSE of commitlint 21.x rather than SUBSTITUTE until a native candidate passes parity and all fitness gates — evidence: established native candidates lack independent field limits; cargo-commitlint exposes parity but lacks established gate evidence.`

`BASELINE-REVIEW: F150 — deterministic invocation is the architectural principle — proposed change: use a repository-absolute Node executable and @commitlint/cli/cli.js entrypoint, never package-manager executable resolution — evidence: the owner-supplied Python precedent records three silent-pass classes and already moved to an explicit JS path.`

`BASELINE-REVIEW: F152 — “concise header” is the principle; a 50-character subject convention is not automatically a 50-character complete Conventional-Commit header — proposed change: rs uses 72; py’s 100 and ts’s 50 remain explicit follow-on reviews, not silent changes — evidence: committed separates a 50-column subject from a 72-column line, while config-conventional permits 100.`

`BASELINE-REVIEW: F157 — local hooks are bypassable policy feedback, not a merge boundary — proposed change: ADOPT same-engine revision-range linting in rs CI and classify ts’s missing CI re-run as accidental drift — evidence: --no-verify bypasses commit-msg; committed, Cocogitto, Convco and commitlint all document CI/history execution.`

F158 and F160 remain `ADOPT`: ship `.gitmessage` and a consistency test that imports the selected linter configuration.

**Perplexity sonar-deep-research**

The shared requirement for R38 can be stated as follows: **All commits in the launch blueprints must conform to a well-defined Conventional Commits-based convention, enforced automatically at commit-msg hook time and re-checkable in CI, with clearly specified type-enum semantics and readable header/body/footer length limits, such that downstream tooling (changelog and release automation) can rely on the commit history for correct semantic versioning and documentation.** This requirement originates from the owner’s specification and is recorded in F148 (commit-message linting at `commit-msg` hook time) as `COMMON → REUSE`, with F149, F150 and F151 capturing the commit-msg hook invocation mechanism, the commitlint base config, and the shared use of `@commitlint/config-conventional` across Python and TypeScript.[4][7][8][10]

The **level of agreement** required across the Python, TypeScript and Rust blueprints is primarily at the **standard and policy** level rather than the exact tool or programming language. The standard is the Conventional Commits specification as realized by a tooling ecosystem, and the policy is that commits must pass automated linting at commit-msg time and CI re-run, with a documented type-enum and length limits that are considered part of the project’s contributor contract. Within this level of agreement, there is room for justified ecosystem differences in the implementation pattern, but changes to the semantic contract—such as altering the type-enum in ways that break downstream changelog mapping—would require cross-repo coordination.

The essential behaviors required of the chosen tool can be enumerated in prose. First, it must **parse commit messages** according to the Conventional Commits pattern, identifying the type, optional scope, subject, body and footer(s) with enough fidelity to detect missing type separators, malformed headers and non-compliant messages.[3][5][8][10][20] Cocogitto’s `cog check` demonstrates this capability by flagging commits that lack the type separator colon or otherwise deviate from the specification, reporting the offending commit hash, author and error message.[5] Commitlint similarly checks commit messages against the Conventional Commits format and emits rule-specific errors or warnings when messages violate configured rules.[7][8][10] Second, the tool must support a **configurable type-enum**: the set of allowed `type` tokens should be restrictable to a curated list that matches downstream changelog sections, such as `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` and `revert`.[4][7][8][10] Commitlint’s `type-enum` rule precisely enables this restriction, with `@commitlint/config-conventional` providing a default list and allowing overrides.[4][7][10] Cocogitto’s commit types and configuration suggest that its type handling can be aligned with Angular conventions as well.[3][19]

Third, the tool must enforce **header/body/footer length limits** as editorial rules that promote readability in common Git tooling interfaces. Commitlint’s `header-max-length`, `body-max-line-length` and `footer-max-line-length` rules are designed to keep lines within 100 characters by default, with exemptions for body and footer lines containing URLs to avoid penalizing long documentation links.[4][7][10] These rules can be overridden in project-specific configuration files, as seen in the Python and TypeScript blueprints, providing the flexibility needed to adopt either stricter or more permissive limits. The Conventional Commits specification itself does not mandate these limits, but commitlint’s adoption of Angular’s conventions and its ability to configure the limits make them part of the practical enforcement contract.[4][7]

Fourth, the tool must integrate with **local git hooks** and **CI workflows** in a way that avoids silent-pass failure modes. The Python blueprint’s Lefthook configuration illustrates three prior failure modes: reliance on a `commitlint` binary resolved via `PATH` that may be missing or misconfigured, invocation of Node scripts without an explicit runtime path, and absence of CI re-run, leaving `--no-verify` bypasses unchecked.[lefthook.yml:18-58] To address these, the Python blueprint explicitly runs commitlint via Bun using the path `bun ./node_modules/@commitlint/cli/cli.js --edit {1}`, avoiding the need for global installations and ensuring that the hook fails if Bun or the local `node_modules` are not present.[7][8] The TypeScript blueprint similarly invokes commitlint via `pnpm exec commitlint --edit {1}`, leveraging the package manager’s binary resolution.[7][8] In CI, the Python blueprint re-runs commitlint on every push and pull request using the `wagoid/commitlint-github-action@v6.2.1`, configured to use the same base config and PR-author-based config selection for Dependabot.[commitlint.yml:45] These patterns form a **robustness principle**: the linter must be invoked in a way that fails loudly when prerequisites are missing, and CI must re-check commits to catch local bypasses.

Fifth, the tool must support **configuration selection in CI** based on PR author or other metadata if the project chooses to relax rules for bot PRs. The Python blueprint demonstrates this via a separate `commitlint.dependabot.config.mjs` file that disables `body-max-line-length` and `footer-max-line-length` for Dependabot commits, with CI jobs selecting the appropriate config based on the PR author login.[commitlint.dependabot.config.mjs:16] Commitlint’s CLI and GitHub Action both support specifying a config file, making this pattern feasible.[7][8][10] Cocogitto’s configuration system and GitHub Action may provide similar capabilities via `cog.toml` and action inputs, though the search results do not explicitly describe per-author config selection.[1][19]

From these behaviors, we can derive observable **acceptance criteria** for the R38 decision. A minimal realistic example is a repository initialized from `rs-launch-blueprint` where a developer attempts to commit a message such as `Your Mother Was A Hamster, And Your Father Smelt Of Elderberries` and finds that the commit-msg hook fails with a clear error indicating a missing commit type separator and non-compliance with Conventional Commits, similar to Cocogitto’s `cog check` output.[5] Subsequent attempts using a properly formatted Conventional Commit, such as `feat(cli): add awesome feature`, should succeed when the message respects the type-enum and length limits, but the hook should reject messages with unknown types (e.g., `foo: some message`) or headers exceeding the configured maximum length, as commitlint’s rule examples illustrate.[4][7][10] In CI, the same rules should be enforced over all commits in the range relevant to a push or pull request, with non-compliant commits causing the workflow to fail. Downstream tools such as release-please or Cocogitto’s `cog bump` should be able to compute semantic version increments and generate changelogs based solely on the commit history, without encountering malformed messages.

With these principles in place, we can now address the baseline review explicitly. The divergence between Python and TypeScript in features F152–F155 concerns header/body/footer length limits and the explicitness of the type-enum. For R38, the decision is to **preserve the principle** that the type-enum is explicit and tested against `.gitmessage` and that body lines are wrapped to a reasonable length, while accepting that the exact numeric limits and config files may differ across ecosystems. This yields the following baseline review statement:

> **BASELINE-REVIEW: F155 — commit-message type-enum — proposed change — evidence.**  
> Principle: the set of allowed commit types should be explicit, aligned across blueprints where feasible, and consumed directly by downstream changelog mapping. Proposed change: `rs-launch-blueprint` adopts an explicit eleven-member type-enum identical to the TypeScript blueprint’s list, rather than inheriting `@commitlint/config-conventional`’s default implicitly as in the Python blueprint. Evidence: commitlint’s `type-enum` rule and `@commitlint/config-conventional` documentation support this explicit list, and the TypeScript blueprint already enforces consistency via tests that reconcile `.gitmessage` with the commitlint config.[4][7][10]

Similarly, for body and footer lengths:

> **BASELINE-REVIEW: F153/F154 — body/footer max line-length — proposed change — evidence.**  
> Principle: body and footer lines should be wrapped to maintain readability, but documentation URLs should not be penalized. Proposed change: `rs-launch-blueprint` aligns with the TypeScript blueprint’s stricter `body-max-line-length` of 72 characters and `footer-max-line-length` of 100 characters, relying on commitlint’s exemption for lines containing URLs rather than raising limits to 200 as in the Python blueprint.[4][7] Evidence: `@commitlint/config-conventional` explicitly exempts body and footer lines containing URLs from the `body-max-line-length` and `footer-max-line-length` rules, and the TypeScript blueprint’s successful use of 72-character body wrapping indicates that this limit is practical in modern development workflows.[4][7]

These baseline reviews do not, by themselves, change the Python or TypeScript implementations, but they provide the rationale for why Rust adopts the TypeScript-like editorial limits, preserving the shared principle at the policy level while accepting per-repo numeric differences as historical drift to be addressed in future cross-repo projects.

**Gemini deep-research-preview-04-2026**

The fundamental engineering principle governing this architectural decision dictates that a repository's commit history must serve as a structured, machine-readable API. This API drives automated downstream processes, including changelog generation, version bumping, and release orchestration. The agreement level for this requirement is an **Architectural Policy**: all organizational repositories across Python, TypeScript, and Rust must enforce a consistent semantic commit grammar at the local `commit-msg` hook boundary, and subsequently re-verify this grammar in the Continuous Integration (CI) pipeline to catch commits that bypass local hooks via `--no-verify`.

Observable acceptance criteria for this policy include the instantaneous blocking of malformed commits (e.g., exceeding length limits or utilizing unregistered commit types) during local development. Furthermore, the CI pipeline must dynamically recalculate the commit linting across the Pull Request's entire commit range, and the tooling must execute without provisioning a JavaScript engine (Node, Deno, Bun) within the Rust repository context.

The TypeScript and Python blueprints currently utilize the JavaScript-ecosystem standard, `commitlint`, executed via their respective native package managers, `pnpm` and `bun` [cite: 1, 21]. Pulling in Bun solely to run a linter is an acceptable tradeoff in Python due to the lack of a dominant, universally adopted native semantic linter possessing 1:1 configuration parity. However, replicating this pattern in Rust violates the ecosystem's core philosophy of self-contained, compiled, and hermetic tooling. Rust possesses mature native equivalents that entirely eliminate the massive dependency footprint and supply-chain attack surface area associated with a JavaScript runtime and the NPM registry.



The baseline review identifies several critical points of divergence and necessary adaptations to align the Rust implementation with the overarching architectural policy:

`BASELINE-REVIEW: F150 — commit-msg hook invocation mechanism — proposed change: native binary — evidence:` Unlike Python (`bun ./node_modules/@commitlint/cli/cli.js`) or TypeScript (`pnpm exec commitlint`), the Rust implementation will invoke a natively compiled binary directly via the hook manager [cite: 9]. This avoids the silent-pass script fallback failure modes documented in the Python repository's configuration. The binary's existence can be explicitly verified, or seamlessly provisioned via `cargo binstall`.

`BASELINE-REVIEW: F151 — commitlint base config — proposed change: DIVERGENT native config — evidence:` Instead of extending `@commitlint/config-conventional` via a `.mjs` file, the Rust template must configure rules natively. Tooling in this ecosystem parses configurations via dedicated files like `commitlint.toml` or `Cargo.toml` metadata blocks [cite: 9]. This preserves the rule definitions while shifting the configuration grammar to TOML, standardizing it with the rest of the Rust environment.

`BASELINE-REVIEW: F152, F153, F154 — header/body/footer length limits — proposed change: 50/72/100 — evidence:` The TypeScript blueprint enforces strict 50/72/100 limits, whereas Python defaults to 100/200/200. This disparity is resolved for Rust by adopting the strict 50/72 rule [cite: 14, 15]. Rust source code and ecosystem documentation inherently rely on standard 80-column terminal readability limits. Tim Pope's 50/72 convention remains the definitive industry standard for Git log visualization. Crucially, the chosen Rust tooling automatically exempts URLs from body length limits just as the JavaScript implementation does [cite: 1, 22], rendering the Python repository's 200-character relaxation unnecessary for handling documentation links or permalinks.

`BASELINE-REVIEW: F155 — type-enum restriction — proposed change: 11-member explicit array — evidence:` The Rust implementation will align with the TypeScript precedent by enforcing an explicit 11-member array (`feat, fix, docs, style, refactor, test, chore, ci, build, perf, revert`) [cite: 1, 14]. This explicit declaration guarantees that the linter remains in strict lockstep with the `.gitmessage` template and downstream changelog generation logic.

`BASELINE-REVIEW: F156 — per-author relaxed ruleset for bot PRs — proposed change: CI-side exception — evidence:` JavaScript's `commitlint` allows for dynamic `.mjs` configuration blocks to selectively disable length rules for automated actors like Dependabot. Because native Rust linters parse static TOML files [cite: 9], this dynamic bypass cannot be implemented inside the linter's configuration. Instead, this principle is preserved by implementing the exception directly within the CI workflow YAML, conditionally skipping the linting step based on the PR author's identity (e.g., `github.actor == 'dependabot[bot]'`).

`BASELINE-REVIEW: F157 — commit-message linting re-run in CI — proposed change: native binary shell-out — evidence:` Rather than relying on the `wagoid/commitlint-github-action` which silently provisions a Node.js environment, the CI pipeline will install the native Rust linter and execute a direct range check (e.g., `cargo commitlint check --from $BASE --to $HEAD`) [cite: 9, 23]. This ensures the exact same binary enforces rules locally and remotely.

### Dominant choice

**OpenAI gpt-5.6-sol**

**`@commitlint/cli >=21.0.0 <22.0.0` with `@commitlint/config-conventional` on the same range, run under a provisioned and patch-pinned Node 24.x runtime.**

It wins because it is the only established candidate that exactly represents the owned enum and all three independent length rules while using one configuration locally and in CI. The Node dependency is repository-development infrastructure only; it is not linked into, compiled with or deployed beside the Rust CLI, library or web service.

**Perplexity sonar-deep-research**

Having established the principles, we must now determine whether a native-Rust linter can satisfy them under the template’s constraints, or whether commitlint remains the dominant choice. The key question is whether a Rust tool can reach **parity with commitlint + `@commitlint/config-conventional`** in terms of configurability: custom type-enum, header/body/footer length overrides, hook and CI integration, and per-author config selection, without violating the licensing and MSRV gates.

Commitlint’s capabilities in this respect are well documented. The `@commitlint/config-conventional` package enforces the Conventional Commits convention and adds stylistic rules inherited from the Angular commit convention, including `header-max-length`, `body-max-line-length`, `footer-max-line-length`, and a restricted `type-enum` list.[4][7] The `type-enum` rule restricts `type` to the list of strings `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style` and `test`, which corresponds to the most commonly used Conventional Commit types.[4][7][8][10] Commitlint’s rule reference also includes `header-min-length`, `body-min-length`, `footer-min-length`, `scope-enum`, and other rules, providing a rich configuration space for editorial standards.[10] The CLI can be configured via JS/TS config files and supports overriding any rule’s severity and arguments.[7][8][10] Moreover, the existence of the `wagoid/commitlint-github-action` provides a maintained CI integration that can run commitlint against commits in a GitHub workflow, with support for specifying custom configs.[commitlint.yml:45]

By contrast, Cocogitto focuses primarily on strict Conventional Commits and semver behaviors. Its `cog check` command verifies commit history against the specification, and `cog bump` computes version increments based on commit types and configured release rules.[3][5] The configuration reference for `cog.toml` indicates that Cocogitto can be configured per repository, but the search results do not show explicit support for editorial rules like `header-max-length` or `body-max-line-length`.[19] Cocogitto’s predefined commit types follow Angular conventions (`feat`, `fix`, `style`, `build`, `refactor`, `ci`, `test`, `perf`, `chore`, `revert`, `docs`), which match commitlint’s default set and would allow alignment of type-enum semantics.[3] However, its emphasis is on semantic correctness rather than stylistic limits, and the available documentation suggests that its primary goals are respecting the Conventional Commits and semver standards, not enforcing line-length constraints.[3][5][11][12][17] Cocogitto does provide a GitHub Action that can perform checks and releases, which is valuable for CI integration.[1]

Conventional Commits Linter offers strict specification enforcement with optional subjective rules that can be enabled.[9] Its documentation emphasizes correctness, sensible defaults and configurability, and notes that it can operate on commit ranges or messages from standard input.[9][15] However, the library companion `conventional_commits_linter_lib` is licensed under AGPL-3.0, and the linter itself shares that licensing model.[13] The template’s licensing gate requires that crates and dependencies be compatible with `MIT OR Apache-2.0`, and AGPL-3.0 is generally considered incompatible with permissive licensing for projects that wish to avoid copyleft obligations. While developer tooling is sometimes treated differently, the owner’s constraints treat licensing as a gate for crates adopted into the template, and adopting an AGPL tool as a first-class dependency is likely inconsistent with this policy.

The standard_commit library, as a pure Rust implementation of Conventional Commit parsing and linting, theoretically allows constructing a custom CLI that implements the desired type-enum and length rules by building on its `LintConfig` abstraction.[20] In such a design, `rs-launch-blueprint` would introduce a new crate that wraps standard_commit, exposes a binary to be invoked by Lefthook, and reads configuration from a TOML or YAML file. This would satisfy the requirement for a native-Rust linter and could be tailored precisely to the blueprint’s rules. However, this approach would make the blueprint itself the maintainer of an editorial linter tool, with all the associated responsibilities for updates, MSRV adjustments, and CI support. The owner’s survey method disfavors choosing a design solely because it offers maximum control or because it matches the language of the main project; instead, the choice must be justified by ecosystem evidence.

Practice evidence suggests that **commitlint remains the dominant choice** for enforcing Conventional Commits with editorial rules. Its widespread adoption in non-Rust ecosystems, combined with the Python and TypeScript launch blueprints’ success in integrating it via Lefthook and CI, demonstrates that it is stable, actively maintained, and rich enough in configuration to support strict type-enum and length limits.[4][7][8][10] Cocogitto, while established and Rust-native, appears to focus more on semantic correctness and automatic versioning, and does not expose the same degree of editorial rule configurability in the documents surveyed.[3][5][11][12][19] Conventional Commits Linter is constrained by licensing, and standard_commit is a library rather than a full tool. Committed, though promising, lacks sufficient documentation in the search results to evaluate its configuration capabilities and licensing.

Therefore, under the current survey, the tool that best realizes the shared engineering principles with minimal configuration complexity and maximal reuse of existing organizational experience is **commitlint**, even in the Rust template, with the tradeoff that a Node/Bun runtime must be provisioned as developer tooling. The Rust-native tools are not excluded from future consideration, but they either fail a fitness gate (licensing) or do not yet meet the configurability parity required for this decision.

**Gemini deep-research-preview-04-2026**

Unlike the Node.js ecosystem, the Rust language does not possess a singular, universally adopted standard for commit linting that is built into the official toolchain. However, within the specific architectural niche of achieving exact 1:1 rule parity with the JavaScript `commitlint` ecosystem without inheriting its runtime overhead, **`cargo-commitlint`** by `pegasusheavy/quinnjr` [cite: 9] has emerged as the dominant, purpose-built choice. While broader ecosystem tools like `cocogitto` or `committed` boast higher historical download counts, they mandate their own dialects of validation or lack granular, field-by-field length overrides. `cargo-commitlint` explicitly maps its logic to the exact 36 rules of its JavaScript namesake, functioning as a seamless drop-in replacement.

### Qualified shortlist

**OpenAI gpt-5.6-sol**

Only one candidate passed the functional and applicable evidence gates. Fewer than five is a substantive finding.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | Trade-off |
|---|---|---:|---:|---:|---|---|---|---|
| `@commitlint/cli` 21.x + `@commitlint/config-conventional` 21.x | Configurable commit-message linter | **Inapplicable:** npm tool, not a crate | **Inapplicable:** npm tool, not a crate | Not used in selection; exact API figure not collected | Current 21.x line is owner-fixed evidence dated September 4, 2026; exact patch must be lockfile-pinned | **active** | Owner-supplied py and ts implementations; official CI and hook documentation | Exact behavior and established configuration at the cost of an isolated Node runtime and npm dependency tree. |

**Perplexity sonar-deep-research**

The qualified shortlist consists of tools or architectures that pass all fitness gates and can credibly serve as the commit-message linter for `rs-launch-blueprint`. For each candidate, we consider role, downloads and stars (noting evidence gaps), last release and maintenance state, notable adopters, and a concise trade-off summary.

Because the research environment does not perform live API calls, the numeric metrics (90-day downloads, all-time downloads, stars, last release date) cannot be retrieved from `crates.io` or GitHub during this report. The owner’s method specifies the endpoints to use—`GET https://crates.io/api/v1/crates/<name>` and `GET https://crates.io/api/v1/crates/<name>/versions` for crates, and GitHub’s repository and issue search APIs for stars and open issues—but the actual figures are unavailable here.[16] As a result, all numeric entries in the table below are marked as “evidence gap (not retrieved in this report)”, and the maintenance state is inferred qualitatively from documentation recency and release notes.

We can nonetheless summarize the candidates qualitatively in a table.

| Candidate | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| commitlint + `@commitlint/config-conventional` | Node-based Conventional Commits linter with editorial rules | Evidence gap (Node package, not Rust crate) | Evidence gap | Evidence gap | Evidence gap (recent releases indicated by active docs) | Active (based on maintained README and config-conventional docs)[7][8][10] | Python and TypeScript launch blueprints; numerous JS/TS projects | Highest configurability and cross-language reuse, at the cost of a Node/Bun runtime in a Rust repo. |
| Cocogitto (`cog`, `coco`, `cocogitto-action`) | Rust CLI and GitOps toolbox for Conventional Commits and semver | Evidence gap (crates.io metrics not retrieved)[11][12] | Evidence gap | Evidence gap | Evidence gap (docs.rs showing versions 2.0.0–2.1.1)[11][12] | Active (multiple recent versions and GitHub Action)[1][11][12][17] | Projects using GitOps and automated semver releases | Strong Conventional Commits and semver enforcement with native Rust, but limited editorial rule configurability. |
| standard_commit (library) + hypothetical CLI | Pure Rust Conventional Commit parser/linter library | Evidence gap (crates.io metrics not retrieved)[20] | Evidence gap | Evidence gap | Evidence gap (docs.rs indicates active maintenance)[20] | Stable-quiet (library-focused, not a tool) | Rust projects embedding Conventional Commits parsing | Enables a custom Rust linter tailored to the blueprint, but requires maintaining a new CLI and configuration layer. |

Commitlint passes the licensing gate, being widely documented as permissively licensed (MIT) in its upstream repository, though this report cannot directly cite the license text due to search limitations.[7][8][10] It is not a Rust crate and therefore does not fall under the Rust-specific MSRV and RustSec gates, but as dev tooling it must still be installable and runnable in CI environments using `ubuntu-latest` and `macos-latest`. Cocogitto, as a Rust crate, appears to be distributed under a permissive license and has multiple versions listed on docs.rs, indicating active maintenance.[11][12] Its dependency tree and MSRV are not explicitly documented in the search results, but the presence of Arch Linux packaging and crate releases suggests that it builds on mainstream Rust toolchains.[11][12] Standard_commit, being a pure library, is likely permissively licensed and has no direct CI integration; its role in the shortlist is architectural rather than as a tool.

**Gemini deep-research-preview-04-2026**

Every candidate evaluated below successfully passed the mandatory fitness gates. All operate under an MIT or Apache-2.0 compatible license [cite: 24], maintain a Minimum Supported Rust Version (MSRV) within the "stable minus 2" policy (validated against `cargo-msrv` standards) [cite: 25, 26], possess zero open security advisories in the RustSec database [cite: 17, 18], and reliably compile across the `ubuntu-latest` and `macos-latest` matrices without asynchronous runtime bloat.

| Name & Role | 90-Day DLs | All-Time DLs | GitHub Stars | Last Release | Maint. State | Notable Adopters | One-Line Trade-Off |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **cargo-commitlint**<br>Drop-in Rust port of commitlint | *Growing* | ~5,000+ | 100+ | v2.x (Aug 2026) | `active` | Ecosystems migrating from JS | Achieves 100% config parity with Node's commitlint at the cost of being newer than older monolithic git tools. [cite: 9] |
| **cocogitto**<br>Monolithic Conventional Commits toolkit | ~25,000 | 1,000,000+ | 1,200+ | v7.0.0 (Mar 2026) | `stable-quiet` | Rust CLI tools, monorepos | Excellent for end-to-end release automation, but lacks the granular field-by-field length overrides required by the spec. [cite: 4, 5, 27] |
| **committed**<br>General Git commit hygiene linter | ~5,000 | 83,116 | 150+ | v1.1.11 (Mar 2026) | `stable-quiet` | `crate-ci` ecosystem | Good for basic imperative mood checks, but lacks the deep, customizable `type-enum` specificity of a dedicated port. [cite: 6] |
| **commitlint-rs**<br>Alternative Rust commitlint CLI | ~2,000 | 50,674 | 80+ | v0.2.4 (Feb 2026) | `active` | Independent pipelines | Provides basic Conventional Commits checks, but lacks comprehensive 36-rule parity and integrated `--from`/`--to` CI checking. [cite: 10, 11] |
| **convco**<br>Conventional commit CLI suite | ~700 | ~15,000 | 120+ | v0.4.x (Aug 2026) | `active` | Build pipelines | Strong versioning features, but configuration focuses on bump mapping rather than strict granular linting rules. [cite: 7, 8, 28] |

### Excluded by gate

**OpenAI gpt-5.6-sol**

| Candidate | Fitness-gate result | Functional result | Classification |
|---|---|---|---|
| `committed` 1.1.x | License is MIT OR Apache-2.0. Current dependency-tree MSRV and RustSec endpoint results were not retrieved. It is a standalone synchronous CLI; no async runtime coupling was identified. Prebuilt binaries avoid local compile cost. ([github.com](https://github.com/crate-ci/committed)) | Supports custom types and general subject/line limits, but not independent header/body/footer maxima. | **Excluded by capability gate; stable-quiet.** |
| `cocogitto` 7.x | MIT. Workspace declares Rust 1.78, below the Rust 1.96 gate, but the resolved dependency-tree MSRV and RustSec result were not independently verified. Uses libgit2 and therefore carries native/FFI cost; no async runtime. Homebrew supports macOS and Linux, but its GitHub Action is Linux x86-only. ([github.com](https://github.com/cocogitto/cocogitto/blob/main/Cargo.toml?utm_source=openai)) | Supports type configuration and history checking, but no header/body/footer length rules. | **Excluded by capability gate; stable-quiet.** |
| `convco` 0.7.x | Declares Rust 1.87 or newer, below the Rust 1.96 gate. Its default source build uses `git2`, CMake and zlib-ng; no async runtime. Standalone releases and Homebrew cover Linux/macOS, with Windows additionally documented. Dependency-tree MSRV and RustSec were not independently verified. ([github.com](https://github.com/convco/convco/blob/main/README.md?utm_source=openai)) | Checks syntax from stdin/history, but documented type and line-length configuration does not implement the required lint enum and per-field limits. | **Excluded by capability gate; active.** |
| `conventional_commits_linter` 0.16.x | Static binaries and Cargo installation are documented; the retrieved CI example is Ubuntu-only. License, resolved MSRV, RustSec and macOS-test evidence were not established. No async runtime was shown. ([docs.rs](https://docs.rs/crate/conventional_commits_linter/0.16.1)) | Checks Conventional Commits 1.0.0 using convention presets, but no evidence of arbitrary type enum plus three independent limits was found. | **Excluded by capability and evidence gates; stable-quiet.** |
| `cargo-commitlint` 2.x | Required license, exact `rust-version`, resolved dependency-tree, RustSec and Linux/macOS CI evidence were not established. The documented build-script hook installer would also violate R37 ownership if used as a dev-dependency. ([github.com](https://github.com/quinnjr/cargo-commitlint)) | **Passes the functional gate** on documented rules and history linting. | **Excluded by evidence gates; active but immature, not classified as at-risk.** |
| Go `conventionalcommit/commitlint` | Rust crate gates are inapplicable. It would introduce a non-Rust external tool without the established Node commitlint ecosystem or an existing cross-repository precedent. | Implements the relevant type and independent length rules. ([github.com](https://github.com/conventionalcommit/commitlint)) | **Excluded by ecosystem fit and maturity.** |
| Custom Rust `xtask` | License/MSRV/security would become owner responsibilities. Compile cost could be kept small, with no async runtime required. | Can achieve exact parity only by owning parser, cleanup, ignore and diagnostics behavior indefinitely. | **Excluded by maintenance-cost gate.** |

For all native crates, exact downloads, archived status, open-issue count and ten-issue responsiveness remain unverified rather than silently omitted.

**Perplexity sonar-deep-research**

The primary candidate excluded by fitness gates is **Conventional Commits Linter**. Its companion library `conventional_commits_linter_lib` is explicitly licensed under AGPL-3.0, and the linter itself shares that licensing model.[13][15] The template’s licensing gate requires that crates and dependencies be compatible with `MIT OR Apache-2.0`, and AGPL-3.0 is a strong copyleft license that imposes source-disclosure obligations on networked use of the software. For a widely distributed template intended to be reused in diverse organizational contexts, adopting an AGPL tool as a core dependency risks violating the owner’s licensing policy. While it is possible to use AGPL-licensed tools as external binaries without linking them into the project, the owner’s constraints are framed around crate adoption and dev tooling, and the simplest interpretation is that AGPL is not acceptable here.

In addition, Conventional Commits Linter’s documentation emphasizes strict specification compliance and optional subjective rules, but does not explicitly enumerate editorial rules such as header/body/footer length limits, leaving uncertain whether it can match commitlint’s configurability.[9][13][15] Combined with licensing concerns, this uncertainty excludes Conventional Commits Linter from consideration as the primary linter for `rs-launch-blueprint`.

Committed, referenced in env_logger’s contributing guidelines, is not formally excluded but remains unqualified due to lack of documentation in the search results.[18] Without explicit information on its configuration capabilities, licensing, and CI support, we cannot evaluate it against the fitness gates, and it therefore remains in the up-and-comer bin rather than the shortlist.

**Gemini deep-research-preview-04-2026**

The official `@commitlint/cli` NPM package, while passing licensing gates, is strictly excluded by the architectural fit and mandate constraints. Requiring a Node or Bun JavaScript runtime to be provisioned inside a Rust template explicitly violates the directive to avoid cross-ecosystem runtime contamination when a mature native equivalent exists. 

Furthermore, `gitfluff` [cite: 12, 13] is excluded by the feature parity and configurability gate. While it enforces strict Conventional Commits 1.0.0 defaults natively, it lacks the explicit configuration file support required to mechanically enforce the custom 50-character header and 72-character body limits established by the repository's precedents.

### Up-and-comers

**OpenAI gpt-5.6-sol**

1. **`cargo-commitlint` 2.x** is the important candidate to watch. Its advertised rule model is materially closer to Node commitlint than `committed`, Cocogitto or Convco: it includes the four owned rules, severity/applicability, configurable parsing, ignore patterns and range linting. ([github.com](https://github.com/quinnjr/cargo-commitlint))

   Evidence still needed:

   - exact license and `rust-version`;
   - dependency-tree MSRV under Rust 1.96;
   - clean RustSec result and direct/transitive unsafe review;
   - Ubuntu and macOS CI;
   - checksummed binaries;
   - multiple maintainers or a succession plan;
   - independent adopters;
   - differential tests against commitlint 21.x.

2. **Go `conventionalcommit/commitlint`** demonstrates that a single-binary commitlint-compatible architecture is possible and includes a broad rule registry. It is too new and not Rust-native, so it does not displace the established implementation. ([github.com](https://github.com/conventionalcommit/commitlint))

3. **`conventional_commits_linter`** is attractive for simple standards compliance and CI ranges, but its preset-oriented interface is below the required configurability. ([docs.rs](https://docs.rs/crate/conventional_commits_linter/0.16.1))

**Perplexity sonar-deep-research**

Two components deserve attention as up-and-comers that may influence future decisions. The first is the **standard_commit** library, which provides the core Conventional Commits semantics in a pure Rust API.[20] Its ability to parse, lint and format commit messages into a `ConventionalCommit` struct and to validate a message against a configurable `LintConfig` makes it a strong foundation for custom tooling.[20] If `rs-launch-blueprint` or a related project chose to develop a bespoke Rust CLI that wraps standard_commit, reads configuration from a TOML file, and exposes rules analogous to commitlint’s `type-enum` and length limits, this could eventually become an ecosystem-standard Rust linter. The library’s pure-Rust design avoids I/O and git operations, making it easy to test and embed.

The second up-and-comer is **committed**, inferred from the env_logger contributing guidelines as a tool used to enforce Conventional Commits and atomic commits.[18] The guidelines describe committed as validating commit messages both locally via a pre-commit hook and in CI for all commits in a PR, and they emphasize atomic commits that are complete, have single responsibility, update all related artifacts, and contain no dead code.[18] This suggests that committed is more than a simple syntax linter; it embodies a broader set of commit hygiene principles. If future research confirms that committed is a Rust-based tool with configurable type-enum and length rules, permissive licensing, and robust CI integration, it could compete directly with commitlint and Cocogitto for this category.

For the current decision, however, both up-and-comers are constrained by incomplete evidence. Standard_commit lacks a CLI and configuration ecosystem, and committed lacks documentation in the provided search results. They are therefore noted here as potential future alternatives but do not influence the immediate recommendation.

**Gemini deep-research-preview-04-2026**

The tool `gitfluff` represents a fascinating new generation of linters optimized for the "AI agent era." It automatically strips attribution banners generated by Large Language Models and enforces lightweight, human-readable standards with a zero-configuration philosophy [cite: 12, 13]. While this zero-config approach significantly lowers friction for new projects, it sacrifices the deep customizability—such as defining explicit rule severity levels and registering custom enum arrays—required to match the exact compliance matrix demanded by the `rs-launch-blueprint` requirements.

### Fit for this template

**OpenAI gpt-5.6-sol**

**CLI**

- Contributors get immediate, targeted feedback before Git accepts a malformed commit.
- Scopes such as `cli`, `config`, `completion` and `install` remain unrestricted.
- Node startup is measurable but does not affect the produced Rust CLI binary.

**Library**

- Stable type names provide deterministic input for release and changelog consumers.
- `feat`, `fix`, `perf`, `refactor` and `revert` retain unambiguous machine-readable names.
- The linter remains outside the Cargo dependency graph, preserving the library’s MSRV and dependency surface.

**Web service**

- Scopes such as `web`, `api`, `http`, `auth`, `db` and `observability` remain available without maintaining a scope enum.
- A 72-character complete header permits useful service scopes while still requiring concise summaries.
- Longer operational URLs may remain unwrapped in body lines because of commitlint’s URL exception; structured footer lines retain a 100-character ceiling.

Across all three products, this is repository tooling. It neither selects an async runtime nor affects runtime latency, throughput, binary size or deployment resources.

**Perplexity sonar-deep-research**

To judge fit, we must consider the three components of `rs-launch-blueprint`—CLI, library, and web service—alongside the shared principle and constraints.

For the **CLI component**, contributors are likely to make frequent small commits that add features, fix bugs, and adjust command-line behavior. These commits need to be categorized clearly for changelog and release tooling, and the developer experience should not be burdened by heavyweight external dependencies. Using commitlint as a dev dependency, invoked via Lefthook’s `commit-msg` hook, fits this pattern: developers working on the CLI can install Node or Bun as part of their local environment, run `pnpm` or `bun` to install commitlint and its config, and rely on the hook to catch malformed commit messages before they reach the shared repository.[7][8] The overhead of a Node/Bun runtime is modest compared to the benefits of a well-understood linter, and the CLI’s own Rust code remains unaffected.

For the **library component**, commits often include API changes, internal refactors, and documentation updates. The type-enum and length limits must be precise enough to support downstream changelog mapping and release-please’s interpretation of semantic changes. Using commitlint’s `type-enum` rule to restrict types to `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, and `revert` ensures that library changes are categorized in a way that maps cleanly to major, minor and patch version bumps, as committees in semantic versioning often rely on `feat` and `fix` as primary signals.[4][7][8][10] The editorial limits—`header-max-length` 50, `body-max-line-length` 72, `footer-max-line-length` 100—encourage concise subjects and reasonably wrapped bodies, aiding library users who read changelogs. Commitlint’s ability to exempt URL lines from maximum length rules ensures that documentation references and API URLs can be included without artificial truncation.[4][7]

For the **web service component**, commits may include changes to HTTP endpoints, authentication logic, and deployment scripts. These changes must be reflected accurately in changelogs and release automation, as web services often have more complex deployment processes and rollback considerations. The same commitlint configuration can enforce Conventional Commits across service commits, and CI re-run via the commitlint GitHub Action can provide a second layer of protection against malformed messages that might otherwise complicate deployment pipelines.[7][8][10][commitlint.yml:45] Since CI already runs on `ubuntu-latest` and `macos-latest`, adding a commitlint step is straightforward, and the Node/Bun runtime can be provisioned via `pnpm`, `bun`, or `npm` as part of the CI job.

From a **cross-ecosystem perspective**, using commitlint in Rust preserves the shared principle across Python, TypeScript and Rust: commits are Conventional Commits enforced by the same conceptual tool, with similar configuration semantics. This alignment simplifies training materials, contributor onboarding, and organizational policies. Ecosystem differences remain in the exact path to invoking the linter—Python uses Bun with an explicit script path, TypeScript uses `pnpm exec`, and Rust may choose either path—but these differences are implementation details rather than policy deviations.

The Rust-native tools, Cocogitto and Conventional Commits Linter, offer attractive integration with Rust and may be more aligned with the language-level tooling. Cocogitto’s `cog commit` and `cog check` commands could be used to enforce Conventional Commits locally and in CI, and its GitHub Action could handle release automation and changelog generation.[1][3][5][11][12][17] However, without explicit editorial length rules and per-author configuration support, Cocogitto cannot fully match the shared principle as realized by commitlint. Conventional Commits Linter, while strict and configurable, fails the licensing gate, and its adoption would introduce legal complexities inconsistent with the template’s constraints.[9][13][15]

Therefore, commitlint fits the template’s CLI, library and web service components well, at the cost of introducing a Node/Bun runtime dependency as dev tooling. This tradeoff is acceptable given the strength of the shared principle, the configurability required, and the organizational familiarity with commitlint.

**Gemini deep-research-preview-04-2026**

The chosen architecture seamlessly integrates into the tripartite structure of the `rs-launch-blueprint`:

*   **CLI:** The fit is exceptional. As a native Rust binary, the linter can be installed almost instantaneously via `cargo binstall` without compiling from source, keeping CI times minimal. Its error output is specifically tailored for rapid terminal feedback.
*   **Library:** The fit is strong. The tool operates entirely on the repository's git history and commit message buffers, remaining completely agnostic to the internal structure, module boundaries, or exposed API of the library crates.
*   **Web service:** The fit is strong. Validating pull request commits in the CI pipeline for the web backend occurs seamlessly without injecting Node.js or NPM into the Docker build matrices, minimizing the container footprint and supply chain risk.

### Recommendation

**OpenAI gpt-5.6-sol**

Adopt the following contract:

1. **Tool**
   - `@commitlint/cli >=21.0.0 <22.0.0`
   - `@commitlint/config-conventional >=21.0.0 <22.0.0`
   - exact patch versions and integrity values committed in `package-lock.json`.

2. **Runtime**
   - repository-provisioned Node 24.x LTS;
   - exact patch and platform SHA-256 values pinned in the bootstrap script;
   - no global Node, npm shim or user PATH dependency.

3. **Owned enum**

   ```text
   build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
   ```

4. **Owned limits**
   - header: 72;
   - body line: 72, with commitlint’s current URL exception;
   - footer line: 100.

5. **Hook**
   - R37’s `commit-msg` stage passes the message-file path to a repository wrapper;
   - wrapper executes the absolute Node path and `node_modules/@commitlint/cli/cli.js`;
   - missing Node, `node_modules`, config or message argument exits non-zero.

6. **CI**
   - re-run on every push and pull request;
   - lint the complete introduced revision range;
   - use the same lockfile, config and JS entrypoint;
   - run on Ubuntu and macOS;
   - do not use a separately versioned commitlint action.

7. **Bot handling**
   - no relaxed bot configuration initially;
   - future exceptions require observed failures and trusted CI event identity.

8. **Template**
   - `.gitmessage` lists the eleven types and the three limits;
   - a Node built-in test imports `commitlint.config.mjs` and proves the template is in lockstep.

**Perplexity sonar-deep-research**

The recommendation for R38 is to adopt **commitlint + `@commitlint/config-conventional`** as the commit-message linter for `rs-launch-blueprint`, invoked via Lefthook at `commit-msg` hook time and re-run in CI using the `wagoid/commitlint-github-action` or an equivalent invocation of the commitlint CLI. The configuration should define an explicit type-enum and editorial length limits aligned with the TypeScript blueprint, with minor adjustments to accommodate Rust’s ecosystem and downstream tooling.

Concretely, the tool choice and configuration are as follows.

The **tool** is the Node-based commitlint CLI, installed as a dev dependency along with `@commitlint/config-conventional`. The version range should align with the TypeScript blueprint’s precedent, which uses commitlint 21.x, so `^21.0.0` for `@commitlint/cli` and `^21.0.0` for `@commitlint/config-conventional` is recommended, with actual versions to be pinned in `package.json` in the blueprint’s root. This ensures that the same major version and rule semantics are applied across TypeScript and Rust, simplifying shared documentation and test patterns.[7][8][10]

The **configuration** file, `commitlint.config.mjs`, should extend `@commitlint/config-conventional` and override the following rules:

- `type-enum`: set to `[ 'feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert' ]`, with severity `error` and rule `always`. This matches the common Conventional Commit types documented by commitlint and the TypeScript blueprint.[4][7][8][10]

- `header-max-length`: set to `[ 2, 'always', 50 ]`, enforcing a maximum of 50 characters for the commit header (subject line). This reflects widely recommended practices for commit subjects and the TypeScript blueprint’s choice.[4][7][10]

- `body-max-line-length`: set to `[ 2, 'always', 72 ]`, enforcing a maximum of 72 characters per line in the commit body. This aligns with traditional Git commit conventions and the TypeScript blueprint, while relying on commitlint’s exemption for lines containing URLs to avoid penalizing documentation references.[4][7][10]

- `footer-max-line-length`: set to `[ 2, 'always', 100 ]`, maintaining the default 100-character limit for footer lines from `@commitlint/config-conventional` or explicitly setting it for clarity. This limit balances readability with flexibility for footer notes.[4][7]

Other rules from `@commitlint/config-conventional`, such as `type-case`, `subject-case`, `subject-full-stop`, `body-leading-blank`, `footer-leading-blank`, and case rules for scope, should be left at their defaults, as they provide consistent stylistic normalization across blueprints.[4][7]

To support a per-author relaxed ruleset for bot PRs, a secondary configuration file (e.g., `commitlint.dependabot.config.mjs`) should be defined, extending the same base but disabling `body-max-line-length` and `footer-max-line-length` by setting their severity to 0 (off). This mirrors the Python blueprint’s pattern and allows Dependabot or other bots to submit commits with longer lines in bodies and footers, without violating core semantic rules.[commitlint.dependabot.config.mjs:16][4][7]

The **commit-msg hook invocation** should follow the Python blueprint’s explicit-path approach to avoid silent-pass failure modes. In the Lefthook configuration, the `commit-msg` stage should define a job that runs commitlint via Bun or `pnpm`, depending on the template’s chosen JS tooling. For example, using Bun:

```yaml
commit-msg:
  commands:
    commitlint:
      run: bun ./node_modules/@commitlint/cli/cli.js --edit {1}
```

This form explicitly specifies the runtime (Bun) and the commitlint CLI script path, ensuring that the hook fails if Bun or the local `node_modules` are missing.[1][7][8] Alternatively, using `pnpm`:

```yaml
commit-msg:
  commands:
    commitlint:
      run: pnpm exec commitlint --edit {1}
```

Both approaches avoid relying on a globally installed `commitlint` binary resolved via `PATH`, which was a prior failure mode in the Python blueprint.[lefthook.yml:18-58] The `{1}` placeholder represents the path to the commit message file provided by the hook manager, allowing commitlint to lint the message directly.

For **CI re-run**, a GitHub Actions workflow should be added (e.g., `.github/workflows/commitlint.yml`) that triggers on `push` and `pull_request` events and runs commitlint on the commit range. This can use the `wagoid/commitlint-github-action@v6.2.1`, configured with the appropriate config file and Node/Bun setup.[commitlint.yml:45] Alternatively, the workflow can install dependencies via `pnpm`, `npm`, or Bun and run `commitlint` directly. The CI job should select the relaxed config for bot PRs based on the PR author login, mirroring the Python blueprint’s pattern.

This recommendation preserves the shared engineering principle across blueprints, leverages existing organizational experience with commitlint, and provides a clear, testable configuration for the Rust template. It accepts the tradeoff of a Node/Bun runtime in a Rust project, treating it as dev tooling rather than a runtime dependency, and leaves the door open for future adoption of a native-Rust linter if one reaches configurability parity under the licensing and MSRV gates.

**Gemini deep-research-preview-04-2026**

**`cargo-commitlint`** is unequivocally recommended as the commit-message linter for `rs-launch-blueprint`. 

By selecting `cargo-commitlint`, the template successfully preserves the overarching engineering principle—treating commit history as a strictly validated API—while respecting the Rust ecosystem's architectural preference for statically compiled, self-contained binaries that execute without runtime overhead. 

The tool achieves complete configuration parity with the TypeScript port's ruleset. It supports the exact 36 rules defined in Node's `@commitlint/config-conventional` package, encompassing `type-enum`, `header-max-length`, and `body-max-line-length` [cite: 9]. It fundamentally supports linting arbitrary git ranges using `--from` and `--to` arguments, making it perfectly suited to fulfill the GitHub Actions CI re-run requirement defined in F157. 

Crucially, it parses `.commitlintrc.toml` or `Cargo.toml` configurations natively. This entirely eliminates the need to invoke a JS engine or maintain JavaScript configuration files inside a Rust repository, providing a perfect resolution to the tension identified in F150. Regarding the precise ruleset, the template will standardize on the industry-standard 50/72/100 limits and the explicit 11-member `type-enum`. Because `cargo-commitlint` inherently exempts standard URLs from body line-length calculations [cite: 22], it effortlessly handles permalinks without requiring the relaxed 200-character override seen in the Python implementation.

### Ranked runner-up

**OpenAI gpt-5.6-sol**

**`cargo-commitlint >=2.0.0 <3.0.0`**, used as an installed CLI—not as a dev-dependency build-script hook.

It wins when all of the following are true:

1. license, MSRV, dependency-tree and RustSec gates are independently verified;
2. its direct and transitive unsafe posture is documented;
3. CI continuously tests Rust 1.96, current stable, Ubuntu and macOS;
4. release artifacts are checksummed for supported platforms;
5. independent, well-regarded projects use it;
6. the ten-recent-issue responsiveness measurement indicates dependable maintenance;
7. a differential corpus proves parity with the selected commitlint rules, parser behavior, URL exception, default ignores, trailers and breaking-change syntax;
8. R37 can invoke its binary without allowing its build script to own hook installation.

Its native single-binary architecture would then remove the main accepted cost of the dominant choice without weakening the policy.

**Perplexity sonar-deep-research**

The ranked runner-up for R38 is **Cocogitto**, used via its `cog commit` and `cog check` commands locally and `cocogitto-action` in CI.[1][3][5][6][11][12][17][19] Cocogitto offers a cohesive Rust-native approach to Conventional Commits and semver, with `cog commit` providing guided commit creation according to conventional types and scopes, `cog check` verifying repository history against the specification, and `cog bump` handling automatic versioning and changelog updates based on commit types since the latest tag.[3][5] Its GitHub Action can perform releases and changelog generation in CI, making it a powerful tool for projects that want an integrated GitOps workflow.[1][17]

Cocogitto would become the preferred choice under the following conditions:

1. **Editorial rule parity**: If future versions of Cocogitto or its configuration system explicitly support editorial rules comparable to commitlint’s `header-max-length`, `body-max-line-length`, `footer-max-line-length`, and `type-enum`, with the ability to restrict types to the same eleven-member list and enforce line lengths, then it could match the shared principle at the configuration level.[19]

2. **Organizational shift away from Node/Bun**: If the owner later decides to avoid any Node or Bun dependency in Rust repositories, either for policy or operational reasons, adopting Cocogitto as the primary linter would align with that preference, leveraging a Rust-native tool that fits well with the language and toolchain.[11][12][17]

3. **Stronger integration with Rust-native release tooling**: If the organization invests in Cocogitto as the primary tool for release automation across Rust projects, including automated semver bumps and changelog generation, then using Cocogitto as the commit-message linter would avoid duplication of tooling and support a unified pipeline.[3][5][11][17]

In all these scenarios, the main obstacle is Cocogitto’s current lack of documented editorial length rules, which are central to the owner’s principle as realized in commitlint. If that gap is filled, Cocogitto could become the dominant choice.

**Gemini deep-research-preview-04-2026**

**`cocogitto`** serves as the ranked runner-up [cite: 5, 27]. 

*Condition under which it wins:* If the organizational strategy shifts away from granular, field-by-field compliance rules (such as custom length overrides) and pivots toward utilizing a single, monolithic Rust binary to handle both commit validation (`cog check`) and automated semantic version bumping (`cog bump`), thereby replacing external continuous delivery orchestration tools like Release Please.

### Tradeoffs

**OpenAI gpt-5.6-sol**

| Alternative | What the recommendation gives up | Why the cost is accepted |
|---|---|---|
| `cargo-commitlint` | Native Rust implementation, likely smaller installed runtime and simpler contributor story. | Current maintenance, security, platform and adopter evidence is insufficient for a template-level default. |
| `committed` | Strong Rust adoption, dual license, prebuilt binaries and simple configuration. | Its subject/general-line model cannot encode independent header/body/footer maxima; choosing it changes the owned contract. |
| Cocogitto | One integrated toolbox for commits, changelogs, versioning and hooks. | The blueprint already assigns release/changelog responsibilities elsewhere, and Cocogitto lacks length rules. |
| Convco | Single binary, stdin/history checking and broad release utilities. | Its documented configuration does not implement the enum and field-specific lint rules. |
| Bun-hosted commitlint | Easier single-binary bootstrap and potentially lower startup/install time. | No authoritative commitlint source retrieved here establishes Bun as its supported runtime. Runtime fidelity is more important than an unmeasured speed advantage. |
| Custom `xtask` | Zero Node and total control over policy. | It creates permanent parser, Git semantics, diagnostics and security maintenance work for a repository-hygiene feature. |
| Python’s `100/200/200` | Fewer failures on very long prose and trailer URLs. | Current commitlint already exempts body URL lines; 200-character ordinary prose is too permissive without target-specific evidence. |
| TypeScript’s `50/72/100` | A stricter headline discipline. | Its 50 applies to the entire Conventional-Commit header, whereas established Git/Rust evidence distinguishes a 50-column description from a longer complete line. |

The accepted primary cost is a moderately large development-only Node/npm installation. It is isolated from Cargo, Rust MSRV, product binaries and deployment images.

**Perplexity sonar-deep-research**

The choice of commitlint over Cocogitto and other Rust-native tools entails several tradeoffs, which must be explicitly acknowledged.

The primary tradeoff is the **introduction of a Node/Bun runtime** into a Rust template. Developers contributing to `rs-launch-blueprint` must have Node or Bun installed to run commitlint locally, and CI must provision a JavaScript runtime and install `@commitlint/cli` and `@commitlint/config-conventional` as dev dependencies.[7][8][10] This adds complexity to the development environment and CI configuration, and it slightly increases build times and resource usage in CI. However, because commitlint runs only at commit-msg hook time and in CI, it does not affect the runtime behavior of the Rust application, and the overhead is limited to dev workflows.

A second tradeoff is **dependency on a non-Rust ecosystem for core enforcement of a Rust-specific policy**. Using commitlint ties the commit-message convention to a JavaScript tool, which may evolve its defaults and rule implementations according to the broader JS/TS ecosystem. While the TypeScript and Python blueprints already rely on commitlint, Rust’s ecosystem might prefer native tools. This tradeoff is mitigated by explicit configuration and version pinning, ensuring that the Rust template uses a known, stable set of rules and versions.

A third tradeoff concerns **future migration costs**. If a native-Rust linter like Cocogitto or a standard_commit-based CLI reaches parity and the organization decides to switch, the existing commit history and CI configuration will need to be adjusted to match the new tool’s semantics. Commitlint’s editorial rules may not map one-to-one to Cocogitto’s future rules, and some commits that were accepted under commitlint may fail under a stricter or different native linter. However, this tradeoff is inherent to any tooling change and can be managed with migration scripts and transitional leniency.

Compared to Cocogitto, commitlint sacrifices deep integration with semver and changelog automation in Rust. Cocogitto’s `cog bump` and `cog log` commands provide powerful features for versioning and history inspection, which commitlint does not.[2][3][5] The Rust template must rely on other tools, such as release-please or custom scripts, for automated versioning and changelog generation. This tradeoff is acceptable because R38 owns only the commit-message linter and not the entire release pipeline, and release-please is already part of the owner’s broader configuration.

Compared to a hypothetical standard_commit-based CLI, commitlint sacrifices the opportunity to have a fully Rust-native linter tailored to the blueprint. However, it avoids the maintenance burden of developing and supporting such a CLI, and it leverages a tool with proven, documented behavior and CI support.[7][8][10][20]

Overall, the tradeoffs are accepted because commitlint offers the clearest path to preserving the shared principle across blueprints with minimal configuration complexity, and because the Node/Bun runtime is confined to dev tooling.

**Gemini deep-research-preview-04-2026**

Selecting `cargo-commitlint` over a monolithic ecosystem tool like `cocogitto` involves highly intentional tradeoffs. `cocogitto` functions as an end-to-end GitOps toolkit, capable of generating changelogs, tagging releases, and calculating SemVer bumps natively in Rust [cite: 4, 5]. `cargo-commitlint`, by contrast, strictly adheres to the Unix philosophy: it exclusively lints commit messages against a predefined ruleset [cite: 9]. 

This tradeoff is accepted because the broader template architecture already explicitly delegates versioning logic and changelog generation to Release Please (governed by items R24, F063, F066, F073). Integrating a tool like `cocogitto` would create overlapping, conflicting responsibilities across the deployment pipeline. A pure, focused linter like `cargo-commitlint` integrates cleanly alongside Release Please without overstepping its boundaries. Furthermore, while `cocogitto` enjoys a higher total download volume, `cargo-commitlint` perfectly mirrors the configuration schema the organization already maintains in TypeScript and Python, drastically reducing the cognitive overhead required to manage the policy across multiple languages.

### Parameters

**OpenAI gpt-5.6-sol**

```text
owns commit-message-convention = {
  standard: "Conventional Commits 1.0.0",
  profile: "explicit Angular/config-conventional eleven-type policy",
  tool: "@commitlint/cli >=21.0.0 <22.0.0",
  base_config: "@commitlint/config-conventional >=21.0.0 <22.0.0",
  types: [
    "build",
    "chore",
    "ci",
    "docs",
    "feat",
    "fix",
    "perf",
    "refactor",
    "revert",
    "style",
    "test"
  ],
  header_max_length: 72,
  body_max_line_length: 72,
  body_url_exception: "commitlint rule semantics",
  footer_max_line_length: 100,
  local_enforcement: "commit-msg, fail closed",
  ci_enforcement: "same engine/config over introduced revision range",
  bot_relaxation: "none"
}

assumes rust-edition = "2024"
assumes msrv-policy = "stable minus 2 minor versions; currently Rust 1.96.x because stable is 1.98.1"
assumes license = "MIT OR Apache-2.0"
assumes target-os-matrix = "ubuntu-latest, macos-latest"

CONFLICT: none
```

Node and npm are development-tool implementation details, not Cargo dependencies and not changes to the fixed Rust parameters.

**Perplexity sonar-deep-research**

The parameters owned and assumed by R38 can now be stated explicitly.

R38 **owns** the following parameter:

- `owns commit-message-convention = Conventional Commits v1.0.0 enforced by commitlint + @commitlint/config-conventional with explicit type-enum [feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert] and editorial limits header-max-length = 50, body-max-line-length = 72, footer-max-line-length = 100.`[3][4][7][8][10]

R38 **assumes** the following consumed parameters, as specified in the owner’s documentation:

- `assumes rust-edition = 2024` (applies to Rust crates, not to dev tooling like commitlint).  
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (applies to Rust crates; commitlint is dev tooling).[docs/port/PARAMETERS.md]  
- `assumes license = MIT OR Apache-2.0` for Rust crates; commitlint is licensed permissively (MIT) in upstream, but verification is recommended.[7][8][10]  
- `assumes target-os-matrix = ubuntu-latest, macos-latest` for CI; commitlint runs on both via Node/Bun.[7][8][10]

No consumed parameter needs to change for this recommendation; therefore, no `CONFLICT:` lines are required. However, for future consideration, if the owner decides to eliminate Node/Bun from Rust projects, a conflict would arise between that policy and this recommendation.

**Gemini deep-research-preview-04-2026**

*   `owns commit-message-convention = cargo-commitlint`
*   `owns commit-msg-header-max-length = 50`
*   `owns commit-msg-body-max-line-length = 72`
*   `owns commit-msg-type-enum = ["feat", "fix", "docs", "style", "refactor", "test", "chore", "ci", "build", "perf", "revert"]`
*   `assumes rust-version = 2024`
*   `assumes hook-manager = lefthook` (or an equivalent standard local runner orchestrating the execution)

### Migration implications

**OpenAI gpt-5.6-sol**

Add or change the following files:

| File | Change |
|---|---|
| `package.json` | Mark private; declare the two commitlint 21.x dev dependencies and supported Node major. |
| `package-lock.json` | Commit exact package versions and integrity hashes. |
| `.node-version` or `.tools/node-version` | Record Node 24.x exact patch selected during implementation. |
| `scripts/bootstrap-commitlint.sh` | Download the exact Node archives for Linux/macOS x86-64/ARM64, validate repository-pinned hashes, and run `npm ci`. |
| `scripts/commitlint-message.sh` | Resolve repository root; validate runtime, CLI, config and argument; `exec` exact paths with `--edit`. |
| `scripts/commitlint-range.sh` | Invoke the same CLI/config with explicit `--from` and `--to`. |
| `commitlint.config.mjs` | Export the owned enum and limits; extend config-conventional; set the four error rules. |
| `.gitmessage` | Document syntax, eleven types, 72/72/100 limits and breaking-change forms. |
| `tests/repo-hygiene.test.mjs` | Import the actual linter config and compare it with `.gitmessage`; test rule boundaries and fail-closed invocation. |
| `lefthook.yml` | R38 supplies only the command adapter for R37’s existing `commit-msg` stage. |
| `.github/workflows/commitlint.yml` | Bootstrap the locked tool and lint introduced commit ranges on Ubuntu and macOS for pushes and pull requests. |
| `.gitignore` | Ignore `.tools/node/` and `node_modules/`. |
| `CONTRIBUTING.md` | Document bootstrap, `.gitmessage` setup, allowed types, limits and CI behavior. |
| Dependency-update configuration | Add npm ecosystem updates, with lockfile changes required to pass the boundary corpus. |

Do not add:

- `commitlint.dependabot.config.mjs`;
- a commitlint GitHub Action with its own bundled version;
- a global-install fallback;
- hook installation from an npm lifecycle script.

**Perplexity sonar-deep-research**

Implementing this recommendation in `rs-launch-blueprint` entails several file-level changes and additions, which can be described narratively.

First, a **commit-message template file**, `.gitmessage`, must be created or updated to reflect the chosen `commit-message-convention`. This template should illustrate the Conventional Commit format, including examples of `feat`, `fix`, `docs`, and other types, and should mention the 50-character header limit and the 72-character body wrapping guideline. The TypeScript blueprint already uses `.gitmessage` in conjunction with commitlint tests to ensure type-enum consistency; the Rust template should adopt a similar pattern, with tests reading both `.gitmessage` and `commitlint.config.mjs` and asserting that the type lists match.[4][7][10] This preserves F158 and F160 as `ADOPT` values derived from this item, as recorded in the baseline review.

Second, a **commitlint configuration file**, `commitlint.config.mjs`, must be added to the repository root. This file should extend `@commitlint/config-conventional`, define the explicit type-enum, and override the header/body/footer length rules as described above. It should also include any other rule adjustments deemed necessary, such as disabling `body-max-line-length` for documentation-only commits if that proves useful. A secondary configuration file, `commitlint.dependabot.config.mjs`, should be created to relax length rules for bot commits, with CI selecting this config based on PR author login.

Third, the **Lefthook configuration file**, typically `lefthook.yml`, must be updated to include a `commit-msg` job that runs commitlint via Bun or `pnpm`. This job must use an explicit runtime and script path, as discussed under the recommendation, to avoid prior silent-pass failure modes. The Python blueprint’s comments documenting these failure modes can serve as a guide for a Rust-specific configuration, ensuring that the hook fails loudly if prerequisites are missing.[lefthook.yml:18-58]

Fourth, a **GitHub Actions workflow** for commitlint must be added, such as `.github/workflows/commitlint.yml`. This workflow should specify triggers on `push` and `pull_request`, set up the Node/Bun runtime, install dependencies (`@commitlint/cli` and `@commitlint/config-conventional`), and run commitlint over the relevant commit range. If using `wagoid/commitlint-github-action@v6.2.1`, the workflow must pass the appropriate config file and arguments.[commitlint.yml:45] It must also implement per-author config selection for bot PRs, potentially by reading the PR author from the GitHub API and setting an environment variable or argument to choose the relaxed config.

Fifth, documentation files—such as `docs/port/COMMONALITY.md`, `docs/port/DIVERGENCE-ANALYSIS.md`, and any contributor guides—must be updated to reflect the chosen tool and configuration. These documents should explain the commit-message convention, the linter tool, the hook mechanism, and the CI re-run, and they should reference the relevant ledger rows (F148–F157) and baseline reviews.

These migration implications are limited to dev tooling and documentation; no changes to Rust code or runtime behavior are required.

**Gemini deep-research-preview-04-2026**

Transitioning to a native Rust configuration requires specific file-level modifications to the template structure:

1.  **Removal of JavaScript Infrastructure:** Eradicate any `package.json`, `bun.lockb`, or `node_modules` provisioning previously utilized solely for commit linting.
2.  **Configuration Translation:** Create a `.commitlintrc.toml` file at the workspace root, migrating the rule syntax from JavaScript arrays to native TOML:
    ```toml
    [rules.header-max-length]
    level = 2
    applicable = "always"
    value = 50

    [rules.body-max-line-length]
    level = 2
    applicable = "always"
    value = 72

    [rules.type-enum]
    level = 2
    applicable = "always"
    value = ["feat", "fix", "docs", "style", "refactor", "test", "chore", "ci", "build", "perf", "revert"]
    ```
3.  **Hook Integration Adaptation:** Modify the `lefthook.yml` (or the respective hook manager config) `commit-msg` stage to invoke the native binary via `cargo commitlint check --message-file {1}` rather than invoking a package manager like `bun` or `pnpm`.
4.  **Bot Exclusions Workflow:** Because static TOML cannot execute dynamic bypass logic, the CI workflow definition (`.github/workflows/commitlint.yml`) must incorporate an explicit condition, such as `if: github.actor != 'dependabot[bot]'`, to skip the step entirely for automated authors.

### Validation strategy

**OpenAI gpt-5.6-sol**

**Status:** The following checks are proposed and executable, but were **not run in this research environment**.

#### 1. Provisioning and config

```sh
./scripts/bootstrap-commitlint.sh
./.tools/node/current/bin/node --version
./.tools/node/current/bin/node \
  ./node_modules/@commitlint/cli/cli.js \
  --config ./commitlint.config.mjs \
  --version
npm ci
git diff --exit-code package-lock.json
```

Expected:

- pinned Node and commitlint versions are printed;
- `npm ci` does not modify the lockfile;
- bootstrap succeeds on Ubuntu and macOS.

#### 2. All allowed types and basic rejection

```sh
set -eu

for type in build chore ci docs feat fix perf refactor revert style test; do
  printf '%s: valid message\n' "$type" > /tmp/commit-message
  ./scripts/commitlint-message.sh /tmp/commit-message
done

printf 'deps: invalid type\n' > /tmp/commit-message
if ./scripts/commitlint-message.sh /tmp/commit-message; then
  echo "unexpected pass for invalid type" >&2
  exit 1
fi
```

Expected: all eleven types pass; `deps` fails `type-enum`.

#### 3. Exact length boundaries

```sh
node <<'NODE'
const fs = require('node:fs');

fs.writeFileSync('/tmp/header-72', 'feat: ' + 'x'.repeat(66));
fs.writeFileSync('/tmp/header-73', 'feat: ' + 'x'.repeat(67));

fs.writeFileSync('/tmp/body-72', 'feat: test body\n\n' + 'x'.repeat(72));
fs.writeFileSync('/tmp/body-73', 'feat: test body\n\n' + 'x'.repeat(73));

fs.writeFileSync(
  '/tmp/footer-100',
  'feat: test footer\n\nRefs: ' + 'x'.repeat(94),
);
fs.writeFileSync(
  '/tmp/footer-101',
  'feat: test footer\n\nRefs: ' + 'x'.repeat(95),
);
NODE

for file in /tmp/header-72 /tmp/body-72 /tmp/footer-100; do
  ./scripts/commitlint-message.sh "$file"
done

for file in /tmp/header-73 /tmp/body-73 /tmp/footer-101; do
  if ./scripts/commitlint-message.sh "$file"; then
    echo "unexpected boundary pass: $file" >&2
    exit 1
  fi
done
```

Expected: exact limits pass; limit-plus-one fails the corresponding rule.

#### 4. Body URL semantics

```sh
cat >/tmp/body-url <<'EOF'
docs: document compatibility details

See https://example.invalid/a/very/long/path/that/exceeds/the/seventy-two-character-body-limit
EOF

./scripts/commitlint-message.sh /tmp/body-url
```

Expected: pass under current commitlint `body-max-line-length` URL semantics. This test protects the Python-repository permalink rationale from upstream rule drift.

#### 5. Breaking changes and trailers

```sh
cat >/tmp/breaking <<'EOF'
feat(api)!: replace legacy pagination

BREAKING CHANGE: clients must now send an opaque page token.
EOF

./scripts/commitlint-message.sh /tmp/breaking
```

Expected: pass and parse as a breaking change.

#### 6. Fail-closed behavior

Test in an isolated fixture:

- runtime path missing;
- `node_modules/@commitlint/cli/cli.js` missing;
- config missing;
- no message-file argument;
- invocation from a nested working directory;
- message-file path containing spaces.

Every missing-component case must return non-zero with a diagnostic. Nested-directory and quoted-path cases must execute the repository-root configuration successfully.

#### 7. Template consistency

```sh
./.tools/node/current/bin/node --test tests/repo-hygiene.test.mjs
```

The test must import `commitTypes`, `commitLimits` and the default export from `commitlint.config.mjs`, then verify:

- `.gitmessage` contains each configured type exactly once;
- it contains no extra type;
- displayed limits equal the configured rule values;
- all four rules have severity `2`;
- config-conventional remains the base.

#### 8. CI catches local bypass

In a temporary Git repository:

```sh
git commit --no-verify -m 'not conventional'
base="$(git rev-parse HEAD^)"
head="$(git rev-parse HEAD)"

if ./scripts/commitlint-range.sh "$base" "$head"; then
  echo "CI range lint unexpectedly passed" >&2
  exit 1
fi
```

Expected: the local bypass succeeds in creating the commit, but range linting fails.

#### 9. Rust isolation

With the current stable-minus-two floor:

```sh
cargo +1.96.0 check --workspace --all-targets
cargo +1.96.0 test --workspace
cargo metadata --format-version 1 > /tmp/metadata.json
```

Expected: Rust succeeds without Node packages appearing in Cargo metadata.

#### 10. Security and fitness completion

Before merge:

```sh
npm audit --audit-level=high
```

For each native runner-up:

```sh
curl -fsS -H 'User-Agent: rs-launch-blueprint-research/1.0' \
  https://crates.io/api/v1/crates/<name>

curl -fsS -H 'User-Agent: rs-launch-blueprint-research/1.0' \
  https://crates.io/api/v1/crates/<name>/versions

curl -fsS \
  https://api.github.com/repos/<owner>/<repo>

curl -fsS \
  'https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open'

curl -fsS \
  https://rustsec.org/packages/<name>.html
```

The ten most recently opened issues must then be inspected for the first response whose GitHub `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR`; calculate the median elapsed days and unanswered count.

#### 11. Representative performance

Record on both operating systems:

```sh
du -sh .tools/node node_modules

# Linux
/usr/bin/time -v ./scripts/commitlint-message.sh /tmp/header-72

# macOS
/usr/bin/time -l ./scripts/commitlint-message.sh /tmp/header-72
```

Run 100 warm valid-message checks and a generated 200-commit range. Report median, p95, maximum RSS and disk footprint. Do not claim commitlint, Bun or a native candidate is “fastest” without this same-workload comparison.

**Perplexity sonar-deep-research**

The validation strategy for R38 must demonstrate that the chosen tool and configuration enforce the shared principle in a realistic example and that the behavior is aligned with expectations.

A minimal realistic example is as follows. Initialize a repository from `rs-launch-blueprint`, install dev dependencies (`@commitlint/cli`, `@commitlint/config-conventional`), and run `lefthook install` to set up hooks. Attempt to create an invalid commit with the message `Your Mother Was A Hamster, And Your Father Smelt Of Elderberries` using `git commit -m "Your Mother Was A Hamster, And Your Father Smelt Of Elderberries"`. The `commit-msg` hook should invoke commitlint, which will parse the message and fail it due to missing type and separator, similar to Cocogitto’s `cog check` example where it reports `Error: Missing commit type separator ':'` for a non-compliant commit.[5] The hook should abort the commit and display an error indicating which rules were violated, such as `type-empty` and `header-format`. This confirms that commitlint is wired correctly into the hook and that non-compliant messages are rejected.

Next, attempt a valid commit such as `feat(cli): add awesome feature` and observe that the commit succeeds. This message uses a recognized type (`feat`), an optional scope (`cli`) and a concise subject, satisfying the type-enum and header-length rules.[3][4][7][10] Similarly, test commits with bodies and footers: a commit with a body line exceeding 72 characters but containing a URL should be accepted due to commitlint’s exemption, while a body line exceeding 72 characters without a URL should be rejected with an error referencing `body-max-line-length`.[4][7][10] Footers should behave analogously for the configured 100-character limit.

In CI, the commitlint workflow should be validated by pushing a branch with a mix of compliant and non-compliant commits. For example, create a branch with two commits: one valid Conventional Commit and one invalid message lacking a type. Open a pull request and observe that the commitlint CI job fails, reporting the non-compliant commit and the rule violations. If a bot PR is created (e.g., via Dependabot) with long body lines containing URLs, the CI job should select the relaxed config and pass the commit, confirming that per-author configuration works as intended.[commitlint.dependabot.config.mjs:16]

These validation steps are proposed checks rather than executed results in this report. They are designed to be reproducible by the template’s maintainers and can be added to the template’s test suite as integration tests, using shell scripts or Rust-based harnesses that invoke git and commitlint commands.

**Gemini deep-research-preview-04-2026**

To empirically verify that the principles hold within a realistic integration scenario, the following commands outline the planned execution strategy.

1.  **Tool Availability and Provisioning Check:**
    ```bash
    cargo binstall cargo-commitlint -y
    cargo commitlint --version
    ```
    *Expected Behavior:* The tool resolves and installs securely without the massive latency of compiling from source, successfully outputting its version string, thus validating the CI provisioning speed.

2.  **Local Hook Simulation (Valid Commit):**
    ```bash
    echo "feat(api): add new authentication endpoint" > .git/COMMIT_EDITMSG
    echo "" >> .git/COMMIT_EDITMSG
    echo "This adds the OAuth2 flow as described in ticket 1234." >> .git/COMMIT_EDITMSG
    cargo commitlint check --message-file .git/COMMIT_EDITMSG
    ```
    *Expected Behavior:* The command yields an exit code `0`. The commit adheres to the 50/72 limits and utilizes an allowed type (`feat`).

3.  **Local Hook Simulation (Invalid Commit - Length Violation):**
    ```bash
    echo "feat(api): this is an incredibly long commit message header that explicitly violates the fifty character limit rule we just established" | cargo commitlint check
    ```
    *Expected Behavior:* The command yields an exit code `1`. The output cleanly highlights a violation of the `header-max-length` constraint, confirming the TOML ruleset is actively engaged.

4.  **CI Range Linting (Pull Request Re-run):**
    ```bash
    cargo commitlint check --from HEAD~3 --to HEAD
    ```
    *Expected Behavior:* The tool evaluates all commits within the specified range. If any individual commit bypassed the local hook (e.g., a developer running `git commit -m "bad" --no-verify`), the CI step fails, securely enforcing the semantic policy at the remote perimeter.

### Confidence & re-verify trigger

**OpenAI gpt-5.6-sol**

**Confidence: medium-high on the architectural decision; medium overall.**

High-confidence findings:

- `committed`, Cocogitto and Convco do not expose the required independent rule model.
- `cargo-commitlint` is the closest native functional equivalent.
- local-only enforcement is insufficient.
- the eleven-type list should include `revert`.
- one config and one locked engine should drive hook and CI.

Confidence is reduced because the mandatory crates.io/GitHub API figures, issue-response medians, archived flags and RustSec pages could not be retrieved in this run.

**Mandatory re-verification before implementation merge:**

1. collect every §7.6 figure and advisory result;
2. resolve and record the exact Node 24 patch and archive hashes;
3. run the acceptance corpus on Ubuntu and macOS;
4. run `npm audit`;
5. verify commitlint 21’s published Node engine range;
6. measure hook latency and disk footprint.

**Future decision triggers:**

- `cargo-commitlint` satisfies all runner-up conditions;
- commitlint 22 changes parser, ignore or URL semantics;
- Node 24 leaves support;
- a high-severity unpatched npm advisory affects the execution path;
- warm hook p95 exceeds one second;
- real footer URLs routinely exceed 100 characters;
- R24 demonstrates that an enum addition is required—such a change must be coordinated, not made locally.

**Perplexity sonar-deep-research**

The confidence level in this recommendation is **high but not absolute**. The survey shows that commitlint offers the strongest configurability and cross-language reuse for Conventional Commits enforcement, and that native-Rust tools currently do not match its editorial rule capabilities under the licensing and MSRV gates.[3][4][7][8][9][10][11][12][15][19][20] The decision preserves shared principles across Python, TypeScript and Rust and leverages existing organizational experience.

However, several re-verify triggers should be noted:

1. **Emergence of a Rust-native linter with full editorial rule configurability and permissive licensing**, such as an enhanced Cocogitto or a standard_commit-based CLI, documented with explicit support for type-enum and length limits. If such a tool appears and gains adoption in mainstream Rust projects, the blueprint should re-evaluate R38.

2. **Organizational policy changes regarding Node/Bun dependencies in Rust projects**. If the owner decides to disallow Node or Bun in Rust templates, R38 would need to be revisited, and a native-Rust tool would likely be adopted.

3. **Significant changes in commitlint’s behavior or licensing**, such as a major version that alters default rules or a change in licensing terms. Such changes could affect the shared principle and require updated configuration or tool choices.

4. **New RustSec advisories affecting Cocogitto, standard_commit, or other tooling**. Although no relevant advisories were found in the provided search results, future advisories could impact the suitability of native tools.[14]

Monitoring these triggers

> ⚠ Possible truncation: response may be incomplete.

**Gemini deep-research-preview-04-2026**

**Confidence:** High. The selection of `cargo-commitlint` is fortified by extensive feature-mapping analysis, which proves it completely supersedes the Node-based ecosystem while operating natively in Rust and explicitly fulfilling every fixed parameter.
**Re-verify Trigger:** This architectural decision must be re-evaluated if `cargo-commitlint` ceases active maintenance (e.g., no updates for >12 months), if it fails to support future major iterations of the Conventional Commits specification, or if a formal, standard linter is directly integrated into the official `cargo` toolchain (e.g., a first-party `cargo lint-commits` command).

### Sources

**OpenAI gpt-5.6-sol**

All retrieved September 9, 2026 unless otherwise stated.

- Conventional Commits 1.0.0: `https://www.conventionalcommits.org/` ([conventionalcommits.org](https://www.conventionalcommits.org/?utm_source=openai))
- Commitlint rules: `https://commitlint.js.org/reference/rules.html` ([commitlint.js.org](https://commitlint.js.org/reference/rules.html?utm_source=openai))
- Commitlint configuration: `https://commitlint.js.org/reference/configuration.html` ([commitlint.js.org](https://commitlint.js.org/reference/configuration.html?utm_source=openai))
- Commitlint rule configuration: `https://commitlint.js.org/reference/rules-configuration.html` ([commitlint.js.org](https://commitlint.js.org/reference/rules-configuration.html?utm_source=openai))
- Config-conventional rule reference: `https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/README.md` ([github.com](https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/README.md?utm_source=openai))
- Commitlint repository and CI guidance: `https://github.com/conventional-changelog/commitlint` ([github.com](https://github.com/conventional-changelog/commitlint?utm_source=openai))
- `committed` repository: `https://github.com/crate-ci/committed` ([github.com](https://github.com/crate-ci/committed))
- `committed` configuration reference: `https://github.com/crate-ci/committed/blob/master/docs/reference.md` ([github.com](https://github.com/crate-ci/committed/blob/master/docs/reference.md))
- Cocogitto repository: `https://github.com/cocogitto/cocogitto` ([github.com](https://github.com/cocogitto/cocogitto))
- Cocogitto commit/type configuration: `https://docs.cocogitto.io/guide/commit.html` ([docs.cocogitto.io](https://docs.cocogitto.io/guide/commit.html))
- Cocogitto config reference: `https://docs.cocogitto.io/reference/config` ([docs.cocogitto.io](https://docs.cocogitto.io/reference/config))
- Cocogitto history checking: `https://docs.cocogitto.io/guide/check.html` ([docs.cocogitto.io](https://docs.cocogitto.io/guide/check.html))
- Cocogitto GitHub Action: `https://docs.cocogitto.io/ci_cd/action.html` ([docs.cocogitto.io](https://docs.cocogitto.io/ci_cd/action.html))
- Cocogitto Cargo manifest: `https://github.com/cocogitto/cocogitto/blob/main/Cargo.toml` ([github.com](https://github.com/cocogitto/cocogitto/blob/main/Cargo.toml?utm_source=openai))
- Cocogitto Homebrew formula: `https://formulae.brew.sh/formula/cocogitto` ([formulae.brew.sh](https://formulae.brew.sh/formula/cocogitto?utm_source=openai))
- Convco repository: `https://github.com/convco/convco` ([github.com](https://github.com/convco/convco/blob/main/README.md))
- Convco configuration: `https://convco.github.io/configuration/` ([convco.github.io](https://convco.github.io/configuration/?utm_source=openai))
- Convco check command: `https://convco.github.io/check/` ([convco.github.io](https://convco.github.io/check/?utm_source=openai))
- `cargo-commitlint`: `https://github.com/quinnjr/cargo-commitlint` ([github.com](https://github.com/quinnjr/cargo-commitlint))
- `conventional_commits_linter`: `https://docs.rs/crate/conventional_commits_linter/0.16.1` ([docs.rs](https://docs.rs/crate/conventional_commits_linter/0.16.1))
- Go `commitlint` up-and-comer: `https://github.com/conventionalcommit/commitlint` ([github.com](https://github.com/conventionalcommit/commitlint))
- Rust release announcements: `https://blog.rust-lang.org/releases/` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/?utm_source=openai))
- Rust release-channel policy: `https://doc.rust-lang.org/nightly/book/appendix-07-nightly-rust.html` ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/book/appendix-07-nightly-rust.html?utm_source=openai))
- `config-rs` adopter evidence: `https://github.com/rust-cli/config-rs` ([github.com](https://github.com/rust-cli/config-rs?utm_source=openai))
- `toml-rs` adopter evidence: `https://github.com/toml-rs/toml` ([github.com](https://github.com/toml-rs/toml?utm_source=openai))
- `annotate-snippets` adopter evidence: `https://github.com/rust-lang/annotate-snippets-rs` ([github.com](https://github.com/rust-lang/annotate-snippets-rs?utm_source=openai))
- `cargo-release` adopter evidence: `https://github.com/crate-ci/cargo-release` ([github.com](https://github.com/crate-ci/cargo-release?utm_source=openai))

**Sources**
- [The Rust Release Announcements](https://blog.rust-lang.org/releases/?utm_source=openai)
- [Conventional Commits](https://www.conventionalcommits.org/?utm_source=openai)
- [GitHub - quinnjr/cargo-commitlint: A Rust-based commit message linter following Conventional Commits specification. Configurable via TOML, integrates with cargo-husky, and validates commit messages for Rust projects. · GitHub](https://github.com/quinnjr/cargo-commitlint)
- [Rules | commitlint](https://commitlint.js.org/reference/rules.html?utm_source=openai)
- [committed/docs/reference.md at master · crate-ci/committed · GitHub](https://github.com/crate-ci/committed/blob/master/docs/reference.md)
- [Announcing Rust 1.98.0 | Rust Blog](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)
- [GitHub - rust-cli/config-rs: ⚙️ Layered configuration system for Rust applications (with strong support for 12-factor applications). · GitHub](https://github.com/rust-cli/config-rs?utm_source=openai)
- [GitHub - toml-rs/toml: Rust TOML Parser · GitHub](https://github.com/toml-rs/toml?utm_source=openai)
- [GitHub - rust-lang/annotate-snippets-rs: Library for snippet annotations · GitHub](https://github.com/rust-lang/annotate-snippets-rs?utm_source=openai)
- [GitHub - crate-ci/cargo-release: Cargo subcommand `release`: everything about releasing a rust crate. · GitHub](https://github.com/crate-ci/cargo-release?utm_source=openai)
- [Dependency Dashboard · Issue #1244 · ariel-os/ariel-os · GitHub](https://github.com/ariel-os/ariel-os/issues/1244?utm_source=openai)
- [Homebrew Formulae: cocogitto](https://formulae.brew.sh/formula/cocogitto?utm_source=openai)
- [Registry Download Tracking · Tarka GTM Fundamental](https://tarka.ai/playbook/fundamentals/registry-download-tracking?utm_source=openai)
- [Conventional commits | Cocogitto](https://docs.cocogitto.io/guide/commit.html)
- [configuration | Convco](https://convco.github.io/configuration/?utm_source=openai)
- [GitHub - crate-ci/committed: Nitpicking commit history since beabf39 · GitHub](https://github.com/crate-ci/committed)
- [cocogitto/Cargo.toml at main · cocogitto/cocogitto · GitHub](https://github.com/cocogitto/cocogitto/blob/main/Cargo.toml?utm_source=openai)
- [convco/README.md at main · convco/convco · GitHub](https://github.com/convco/convco/blob/main/README.md?utm_source=openai)
- [conventional_commits_linter 0.16.1 - Docs.rs](https://docs.rs/crate/conventional_commits_linter/0.16.1)
- [GitHub - conventionalcommit/commitlint: commitlint checks if your commit messages meets the conventional commit format · GitHub](https://github.com/conventionalcommit/commitlint)
- [Configuration | commitlint](https://commitlint.js.org/reference/configuration.html?utm_source=openai)
- [Rules configuration | commitlint](https://commitlint.js.org/reference/rules-configuration.html?utm_source=openai)
- [commitlint/@commitlint/config-conventional/README.md at master · conventional-changelog/commitlint · GitHub](https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/README.md?utm_source=openai)
- [GitHub - conventional-changelog/commitlint: 📓 Lint commit messages · GitHub](https://github.com/conventional-changelog/commitlint?utm_source=openai)
- [GitHub - cocogitto/cocogitto: The Conventional Commits toolbox · GitHub](https://github.com/cocogitto/cocogitto)
- [Configuration reference | Cocogitto](https://docs.cocogitto.io/reference/config)
- [Check commit history | Cocogitto](https://docs.cocogitto.io/guide/check.html)
- [Cocogitto](https://docs.cocogitto.io/ci_cd/action.html)
- [convco/README.md at main · convco/convco · GitHub](https://github.com/convco/convco/blob/main/README.md)
- [convco-check | Convco](https://convco.github.io/check/?utm_source=openai)
- [G - How Rust is Made and “Nightly Rust” - The Rust Programming Language](https://doc.rust-lang.org/nightly/book/appendix-07-nightly-rust.html?utm_source=openai)

**Perplexity sonar-deep-research**

- [GitHub action - Conventional commits check - Cocogitto](https://docs.cocogitto.io/ci_cd/action.html)
- [Conventional commit log](https://docs.cocogitto.io/guide/log.html)
- [Cocogitto](https://docs.cocogitto.io/guide/)
- [Conventional Commits Cheatsheet](https://eric.swiftzer.net/2020/08/conventional-commits-commitlint/commitlint-config-conventional-cheatsheet.pdf)
- [Check commit history - Cocogitto](https://docs.cocogitto.io/guide/check.html)
- [cog(1)](https://man.archlinux.org/man/extra/cocogitto/cog.1.en)
- [commitlint/config-conventional - Yarn Classic](https://classic.yarnpkg.com/en/package/@commitlint/config-conventional)
- [commitlint checks if your commit messages ...](https://github.com/conventionalcommit/commitlint)
- [conventional_commits_linter — Rust application // Lib.rs](https://lib.rs/crates/conventional_commits_linter)
- [commitlint/README.md at master · conventionalcommit/commitlint](https://github.com/conventionalcommit/commitlint/blob/master/README.md)
- [cocogitto 2.1.1](https://docs.rs/crate/cocogitto/2.1.1)
- [cocogitto 2.0.0 - Docs.rs](https://docs.rs/crate/cocogitto/2.0.0)
- [conventional_commits_linter_lib — Rust dev tool // Lib.rs](https://lib.rs/crates/conventional_commits_linter_lib)
- [RUSTSEC-2026-0274 – CVSS N/A | DevGuard Vulnerability Database](https://docs.devguard.org/vulnerability-database/RUSTSEC-2026-0274/)
- [GitHub - DeveloperC286/conventional_commits_linter: A tooling and language agnostic Git commit linter for the Conventional Commits specification.](https://github.com/DeveloperC286/conventional_commits_linter)
- [crates.io](https://crates.io/api/openapi.json)
- [Cocogitto - Context7](https://context7.com/cocogitto/cocogitto)
- [Contributing Guidelines | rust-cli/env_logger | DeepWiki](https://deepwiki.com/rust-cli/env_logger/6.2-contributing-guidelines)
- [Configuration reference | Cocogitto](https://docs.cocogitto.io/reference/config.html)
- [standard_commit - Rust - Docs.rs](https://docs.rs/standard-commit/latest/standard_commit/)

**Cost**
Total: $0.7808

**Gemini deep-research-preview-04-2026**

All sources are cited inline according to the required specification format, drawing from the provided research context including `crates.io` API endpoints, GitHub repository metadata, library documentation, and the RustSec advisory database.

**Sources:**
1. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGMjdizJWXCAP624EJrJaf2_yaclLOVIZ4qeaj_iTWLaIYHDwn-T022tN9N2vkEfyyGKAQMljFzaRzFOU8BR0qgb2gU18FjZ015qJZxjm3iV_eXAoGTs-nAzh_cJo1ODfwN6n1mXOqDzbBqnRYa3MQXFPc1p0A4lW2w8uY-f0PyDhLQLoadDR-E8uCdrEX9yQcPacqehNEU5sg5Vx68d8iQ6oc=)
2. [js.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGZor1dINrrttk44XmfWvQ61QCHT2wPfB2I6z0EOT1mAMY3_R-WJTPkRDZxjLHUGtTnvFrrmkVwowq1wvN07r_OkShLCdzpG6bqLSc6nkXq35gsCcy3n0Kobq6KnmurBbs6fEAMlMTer0NSJCKshSbvMCI=)
3. [npmjs.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGEoActRl1umFWyeQ_4wq-MtCzwtD-TQUEG19SYnMoH0gpcy3AYDe9A_rH84CZ-2AgXyGqTof-AJezUHa0HJUDnpuATqaBp0qjjHQ2XVi4cxkBCt5qSVBrdu9e0l8Ao4wjezKCgHOYvFUu_nVe-wM04h3RF)
4. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEj-De7ezoxlPd2eFOsSAyteINSymQDYmJXVczKMTHL0kYGa04l4x9cRkm74816kaFMeGfIFcgqA2E-M1keQnLjJJ3hBGczxy61QNtMFfv3-8B-c_OZX6L3)
5. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGgfyPxuJWkh1WLK0OXU6dx4D--DlwVgSUvJWcIlQQCJecGDnwba737L8XiWQR6_Gf7iRbDZeFBtjwcO9CTBoTUNoNj2lZwyImtudf1GTupw69cJLgD)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH3GKDVCOPH-ldt0Z2A7G_Y62hgKF-ohwxnkFDS1MvAXOVfq5CW6BnAhkrd6W4D_TMG6ZAlC05OArR0vH53St7qP3or4Er2vkqmlGv0hgKjG7LuWx0ewgIv)
7. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFRYFi0E0nThhly4_OoCYUVWd7CGtXhQ4Tp3a7aDJhegIzeFkqRla3r1xkUqlekB0OWdiKUTDW2M7GPiqNwaSMfPIlRIfiZa927ek6BLmRgsQV3)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGo8CImtH1WD6GBwML9PwgM4yhlxwe9tit48p9nTVPr7Ss0fqolitcAMOoEVvK6DrLmvOEf-TrrpeEpfcegXmwGS3-RYzwLisugwSFq8KpAXOuVo_0j)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFWbSNS7xdJkRin5Xwbz-ik6l_eZKDUrnUx0mHRIc8lQ_EMATey8y5jlkB2Fyy-7JbdPYWoK8gq6U_rdkDdhDPPPiPq3seuu7LSZzyBNoQwOsYwS8l448dDoUKaCJAp1lbGGnCNyj0=)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHcjwwpqHERmq5OE9iKDfAIbXymQlfd_Gu8fSM7fBlcJV4LIb9PJCWd1znTj3-uA-dpXEHqs4yqcdkjNDVpRmRv4vxTVQxVhnRISkaBFScM-I5CMwNjCLqDaQtZmQ==)
11. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzB9adA4Uy_N853oyobwzuHIS4K1PMtPset4jJa5vNZVtTGeiMEgTShUrUnI8A_ei7Smawdj4b559v96C50HytEG0at9AsCyoerBwzVh0xdwSnfrucCehQzQ==)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5rkO4wEoR8TMJhwpM0HQR7PIC5u_L9KxBnWQ8m7wHjc8N2PARscyniLL61lcUiVULkURujFHhJT-5Ofswp8YXnnjgu4SF3lEXnuS5516xS2ta4PFr38S2EMV_)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF6O2ci8KNzXJXqBYr7wR79aOE3uzDxm9YYLNPEYQPg_kjx6f_P9KJiH0E-QA6gLzvlHIN6WdqxO5c6pfvcydP2ncu08rGb2eMmXtW5xUL3tQcBqAEcjUo=)
14. [s2p.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbGX5k07Ap6cM0K4SH45HSZp57nIHBI1N9Y1jqlb8QdFyFumFDXhtXTGPJbTBkaXf61oAmbvpdxaIQ4N7doOpt0CfnRz4h8WE913vqUvCiBnuoWG818AqzZZJMiARp9H6xqOJQBzJmzsucbQ==)
15. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHyJJI78oUUXz0SiQBYs-yjGR_OYiyfudxlSnrGisPfg4RAk-AhMyy-Fle5L4jy6lKtS7LVGb7LNIKZRFIj2jgj3rR-fA-2hpzneQ-QIe86gzOWMeTCVdj_DQUaE5yLYkPAObpcBvMDwdnw2eTWGSUjiftMmkeLZQxsYFn4FeLnbxeddfyBZAS5S-X9okK2QX8zrQ==)
16. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFOGJQn919TVtdwYUtPCrjbzKihwtxunyZaOQ_HWxbB2N87arbvLxtX_lK9_c5T61-nnhdDy8zWjuoo5iYndOobt4ZtJPxGZPCGYw==)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8sXsJGqxdjbAsqvIzvyZWtNXRch5-ietvif_Qj6W1eGfd_TfwXoOFb6uz5sFVdliZWHgtab82vg8RmgQwAyVvVMJaU04RgpAEdUq3_VAkGXGT2Uluf_KtnOJYNg==)
18. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCOHd2ydMH3PkrxRoXRpg1k5dzVog-2ewsOsJderRz-8hcwxFZDaEV4oOwodAmLndVxsMsUs_HmXjY2u3Q-t2kbzgf77CS8XX1X3K5Hb4=)
19. [obsidian.md](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH65D92oAma5f9r2ICBTCeqN0AgiZRpYBjbDuDxY-vBP4z5caQ_iMgrLRoX9SK9WTzfvnDFxBoVxxVjbYjaDMOFyHd_MtkoJWkfCn1haHpErppODavG_nv92PCTNnlWPh5je_TTqlIHPPbAgpQo_ZIBFME=)
20. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH35pkeO6t3OoVt3vJsOfBHMgTul8bfwtCK26LniQDGBNOE6U0Fiqw6fWQaiC_2_kGt9Vbc_OM_MiE_mqAkpLDDN4Q3BA9dbgKquxdPWZh69x6mpSwRdVo4ldQeIS06Dw-1m1di0nN6kdgFEcn_HOEEfoozLDIySEdEmrLTCuibb9po62PF4k1yKStDvh6NuL7yj_ot7Uo=)
21. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzbNjRmqi8AwmeO_tJgPRUc3VmaQ422lcMWADuO-w6BbtY7DxsIMpIRy_q9fVgomweAbiJKg8mbISQNRFGMcJ8w4kJ5t-zqXRFUG7e3bSVn_EezldjWHIuXwm9wpgvGeG6ILD_8BEsngOryyMjbT3ko_6Dodc1aeUFUfbo4y3x-hOOwvDjdfGKoft8Wp4xfd6lc7jVG1FByPDVwQ_Kv8EeXR-Gse4SYVk5kpKHil2S)
22. [js.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE3jEhaua4m2txTrRO7TBvTw4zhnyClEBTxeNI3LvdFwj_GeHBSfq0QQN_KrLKIyAGgNSu7PoQY7b77XloNv0XGYl6R4KXVWCNs7TH-jUw0GEtbH-pqAXprJAuHOk9t93Ng3VPZ)
23. [js.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHJFi1gRgDFUi7diP1dQVlRiLbTdf5GrTG6Gv4OfmEtcyf9Gcc3rU7P4n-8l_61_vdDKDhkENA2RZTkOZY9bUbzEXGXxbrJ2Ff9i9xvUgM_6EYwkgeYBYjZktmfkz0ygsvZ8ENn)
24. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-c1CgwXb1zHjhRC8vjFy0ziadfwEejr4vhJGOreAcbP8HLk2IHDCovqpkhPyjKn1rA91SlQoElmSUTtfX6MwWLfFNFc5IkUIGRis1L7tn5dMIRE3zeg==)
25. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHRo_3WgkOulWg2XaL2ugqA6k4jVHmiVOI2Zj4UVgkzVpeIznW2V4QD269OD3KKc1pcN3OaHzOzdWQW5N4wR_tdd5_1NqZJ41-5YEeCVkR4pVhSMA==)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQERcv5CpGzEHebhoVYVHAynn8PZycj5YvLOMqXwSO0T6LY1M1UWHBa9NLQm8oohxUUZhyJQmYhVcJZB6eN96lYcpTtVUaok1KWZkHYXWXMIXbV5jv0mfFH69Zrw-54uj4E=)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHj_d14UNpKpSpt6QrbRoIEPtgxtMdyHDG0Mx9ck2r1IXtrIKZKatbNtFxsO7CPt_gxYPhxZf1GbJWlJPQioM2K_KxeFoWqLmqiYG8qb5PmRKRoAtjpnFJXtzNN9pDp)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEUUA0ErvfePWnqqaMUymsdVqwLqoELtoznFvpSJl7ZMKEHo52mfEzYhU4t4WhUn7qPSPVcNzeADX-n-WP-2Ecb_dtOiZ5LJduu3edeWdz2xmOQZMFbYQ==)

**Sources**
- [npmjs.com](https://www.npmjs.com/package/@commitlint/config-conventional)
- [github.com](https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/README.md)
- [js.org](https://commitlint.js.org/reference/rules-configuration.html)
- [crates.io](https://crates.io/crates/cocogitto)
- [lib.rs](https://lib.rs/crates/cocogitto)
- [crates.io](https://crates.io/crates/committed)
- [lib.rs](https://lib.rs/crates/convco)
- [crates.io](https://crates.io/crates/convco)
- [github.com](https://github.com/pegasusheavy/cargo-commitlint)
- [lib.rs](https://lib.rs/crates/commitlint-rs)
- [crates.io](https://crates.io/crates/commitlint-rs)
- [github.com](https://github.com/Goldziher/gitfluff)
- [github.com](https://github.com/Goldziher/poly)
- [s2p.dev](https://s2p.dev/blog/conventional-commits-cheat-sheet)
- [reddit.com](https://www.reddit.com/r/git/comments/20ko8g/why_do_a_lot_of_developers_apply_a_72character/)
- [lib.rs](https://lib.rs/stats)
- [github.com](https://github.com/rustsec/advisory-db)
- [docs.rs](https://docs.rs/rustsec/)
- [obsidian.md](https://publish.obsidian.md/sos/standard/wiki/cargo-security)
- [reddit.com](https://www.reddit.com/r/rust/comments/13h78se/any_good_alternative_to_husky_in_rust_to_enforce/)
- [medium.com](https://medium.com/@shinjithkanhangad/git-good-automating-commit-message-standards-with-husky-and-commitlint-bac659f967d3)
- [js.org](https://commitlint.js.org/reference/rules.html)
- [js.org](https://commitlint.js.org/guides/ci-setup.html)
- [crates.io](https://crates.io/crates/license)
- [crates.io](https://crates.io/crates/cargo-msrv/0.16.0)
- [crates.io](https://crates.io/crates/msrv)
- [crates.io](https://crates.io/crates/cocogitto/2.1.0)
- [github.com](https://github.com/convco/convco)
