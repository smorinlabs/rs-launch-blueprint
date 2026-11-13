### Landscape

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

### Principles and implementation

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

### Dominant choice

**`@commitlint/cli >=21.0.0 <22.0.0` with `@commitlint/config-conventional` on the same range, run under a provisioned and patch-pinned Node 24.x runtime.**

It wins because it is the only established candidate that exactly represents the owned enum and all three independent length rules while using one configuration locally and in CI. The Node dependency is repository-development infrastructure only; it is not linked into, compiled with or deployed beside the Rust CLI, library or web service.

### Qualified shortlist

Only one candidate passed the functional and applicable evidence gates. Fewer than five is a substantive finding.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | Trade-off |
|---|---|---:|---:|---:|---|---|---|---|
| `@commitlint/cli` 21.x + `@commitlint/config-conventional` 21.x | Configurable commit-message linter | **Inapplicable:** npm tool, not a crate | **Inapplicable:** npm tool, not a crate | Not used in selection; exact API figure not collected | Current 21.x line is owner-fixed evidence dated September 4, 2026; exact patch must be lockfile-pinned | **active** | Owner-supplied py and ts implementations; official CI and hook documentation | Exact behavior and established configuration at the cost of an isolated Node runtime and npm dependency tree. |

### Excluded by gate

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

### Up-and-comers

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

### Fit for this template

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

### Recommendation

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

### Ranked runner-up

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

### Tradeoffs

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

### Parameters

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

### Migration implications

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

### Validation strategy

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

### Confidence & re-verify trigger

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

### Sources

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

## Sources

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