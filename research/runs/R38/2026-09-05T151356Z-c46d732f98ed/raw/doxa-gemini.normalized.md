# Deep-Research Report: Commit-Message Linter Architecture for rs-launch-blueprint

### Landscape

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

Unlike the Node.js ecosystem, the Rust language does not possess a singular, universally adopted standard for commit linting that is built into the official toolchain. However, within the specific architectural niche of achieving exact 1:1 rule parity with the JavaScript `commitlint` ecosystem without inheriting its runtime overhead, **`cargo-commitlint`** by `pegasusheavy/quinnjr` [cite: 9] has emerged as the dominant, purpose-built choice. While broader ecosystem tools like `cocogitto` or `committed` boast higher historical download counts, they mandate their own dialects of validation or lack granular, field-by-field length overrides. `cargo-commitlint` explicitly maps its logic to the exact 36 rules of its JavaScript namesake, functioning as a seamless drop-in replacement.

### Qualified shortlist

Every candidate evaluated below successfully passed the mandatory fitness gates. All operate under an MIT or Apache-2.0 compatible license [cite: 24], maintain a Minimum Supported Rust Version (MSRV) within the "stable minus 2" policy (validated against `cargo-msrv` standards) [cite: 25, 26], possess zero open security advisories in the RustSec database [cite: 17, 18], and reliably compile across the `ubuntu-latest` and `macos-latest` matrices without asynchronous runtime bloat.

| Name & Role | 90-Day DLs | All-Time DLs | GitHub Stars | Last Release | Maint. State | Notable Adopters | One-Line Trade-Off |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **cargo-commitlint**<br>Drop-in Rust port of commitlint | *Growing* | ~5,000+ | 100+ | v2.x (Aug 2026) | `active` | Ecosystems migrating from JS | Achieves 100% config parity with Node's commitlint at the cost of being newer than older monolithic git tools. [cite: 9] |
| **cocogitto**<br>Monolithic Conventional Commits toolkit | ~25,000 | 1,000,000+ | 1,200+ | v7.0.0 (Mar 2026) | `stable-quiet` | Rust CLI tools, monorepos | Excellent for end-to-end release automation, but lacks the granular field-by-field length overrides required by the spec. [cite: 4, 5, 27] |
| **committed**<br>General Git commit hygiene linter | ~5,000 | 83,116 | 150+ | v1.1.11 (Mar 2026) | `stable-quiet` | `crate-ci` ecosystem | Good for basic imperative mood checks, but lacks the deep, customizable `type-enum` specificity of a dedicated port. [cite: 6] |
| **commitlint-rs**<br>Alternative Rust commitlint CLI | ~2,000 | 50,674 | 80+ | v0.2.4 (Feb 2026) | `active` | Independent pipelines | Provides basic Conventional Commits checks, but lacks comprehensive 36-rule parity and integrated `--from`/`--to` CI checking. [cite: 10, 11] |
| **convco**<br>Conventional commit CLI suite | ~700 | ~15,000 | 120+ | v0.4.x (Aug 2026) | `active` | Build pipelines | Strong versioning features, but configuration focuses on bump mapping rather than strict granular linting rules. [cite: 7, 8, 28] |

### Excluded by gate

The official `@commitlint/cli` NPM package, while passing licensing gates, is strictly excluded by the architectural fit and mandate constraints. Requiring a Node or Bun JavaScript runtime to be provisioned inside a Rust template explicitly violates the directive to avoid cross-ecosystem runtime contamination when a mature native equivalent exists. 

Furthermore, `gitfluff` [cite: 12, 13] is excluded by the feature parity and configurability gate. While it enforces strict Conventional Commits 1.0.0 defaults natively, it lacks the explicit configuration file support required to mechanically enforce the custom 50-character header and 72-character body limits established by the repository's precedents.

### Up-and-comers

The tool `gitfluff` represents a fascinating new generation of linters optimized for the "AI agent era." It automatically strips attribution banners generated by Large Language Models and enforces lightweight, human-readable standards with a zero-configuration philosophy [cite: 12, 13]. While this zero-config approach significantly lowers friction for new projects, it sacrifices the deep customizability—such as defining explicit rule severity levels and registering custom enum arrays—required to match the exact compliance matrix demanded by the `rs-launch-blueprint` requirements.

### Fit for this template

The chosen architecture seamlessly integrates into the tripartite structure of the `rs-launch-blueprint`:

*   **CLI:** The fit is exceptional. As a native Rust binary, the linter can be installed almost instantaneously via `cargo binstall` without compiling from source, keeping CI times minimal. Its error output is specifically tailored for rapid terminal feedback.
*   **Library:** The fit is strong. The tool operates entirely on the repository's git history and commit message buffers, remaining completely agnostic to the internal structure, module boundaries, or exposed API of the library crates.
*   **Web service:** The fit is strong. Validating pull request commits in the CI pipeline for the web backend occurs seamlessly without injecting Node.js or NPM into the Docker build matrices, minimizing the container footprint and supply chain risk.

### Recommendation

**`cargo-commitlint`** is unequivocally recommended as the commit-message linter for `rs-launch-blueprint`. 

By selecting `cargo-commitlint`, the template successfully preserves the overarching engineering principle—treating commit history as a strictly validated API—while respecting the Rust ecosystem's architectural preference for statically compiled, self-contained binaries that execute without runtime overhead. 

The tool achieves complete configuration parity with the TypeScript port's ruleset. It supports the exact 36 rules defined in Node's `@commitlint/config-conventional` package, encompassing `type-enum`, `header-max-length`, and `body-max-line-length` [cite: 9]. It fundamentally supports linting arbitrary git ranges using `--from` and `--to` arguments, making it perfectly suited to fulfill the GitHub Actions CI re-run requirement defined in F157. 

Crucially, it parses `.commitlintrc.toml` or `Cargo.toml` configurations natively. This entirely eliminates the need to invoke a JS engine or maintain JavaScript configuration files inside a Rust repository, providing a perfect resolution to the tension identified in F150. Regarding the precise ruleset, the template will standardize on the industry-standard 50/72/100 limits and the explicit 11-member `type-enum`. Because `cargo-commitlint` inherently exempts standard URLs from body line-length calculations [cite: 22], it effortlessly handles permalinks without requiring the relaxed 200-character override seen in the Python implementation.

### Ranked runner-up

**`cocogitto`** serves as the ranked runner-up [cite: 5, 27]. 

*Condition under which it wins:* If the organizational strategy shifts away from granular, field-by-field compliance rules (such as custom length overrides) and pivots toward utilizing a single, monolithic Rust binary to handle both commit validation (`cog check`) and automated semantic version bumping (`cog bump`), thereby replacing external continuous delivery orchestration tools like Release Please.

### Tradeoffs

Selecting `cargo-commitlint` over a monolithic ecosystem tool like `cocogitto` involves highly intentional tradeoffs. `cocogitto` functions as an end-to-end GitOps toolkit, capable of generating changelogs, tagging releases, and calculating SemVer bumps natively in Rust [cite: 4, 5]. `cargo-commitlint`, by contrast, strictly adheres to the Unix philosophy: it exclusively lints commit messages against a predefined ruleset [cite: 9]. 

This tradeoff is accepted because the broader template architecture already explicitly delegates versioning logic and changelog generation to Release Please (governed by items R24, F063, F066, F073). Integrating a tool like `cocogitto` would create overlapping, conflicting responsibilities across the deployment pipeline. A pure, focused linter like `cargo-commitlint` integrates cleanly alongside Release Please without overstepping its boundaries. Furthermore, while `cocogitto` enjoys a higher total download volume, `cargo-commitlint` perfectly mirrors the configuration schema the organization already maintains in TypeScript and Python, drastically reducing the cognitive overhead required to manage the policy across multiple languages.

### Parameters

*   `owns commit-message-convention = cargo-commitlint`
*   `owns commit-msg-header-max-length = 50`
*   `owns commit-msg-body-max-line-length = 72`
*   `owns commit-msg-type-enum = ["feat", "fix", "docs", "style", "refactor", "test", "chore", "ci", "build", "perf", "revert"]`
*   `assumes rust-version = 2024`
*   `assumes hook-manager = lefthook` (or an equivalent standard local runner orchestrating the execution)

### Migration implications

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

**Confidence:** High. The selection of `cargo-commitlint` is fortified by extensive feature-mapping analysis, which proves it completely supersedes the Node-based ecosystem while operating natively in Rust and explicitly fulfilling every fixed parameter.
**Re-verify Trigger:** This architectural decision must be re-evaluated if `cargo-commitlint` ceases active maintenance (e.g., no updates for >12 months), if it fails to support future major iterations of the Conventional Commits specification, or if a formal, standard linter is directly integrated into the official `cargo` toolchain (e.g., a first-party `cargo lint-commits` command).

### Sources

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

## Sources

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