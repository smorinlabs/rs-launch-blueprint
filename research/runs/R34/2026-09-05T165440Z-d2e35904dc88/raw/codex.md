### Landscape

**Category and map.** R34 decides *early compatibility detection in CI*: detect (1) a dependency release that still satisfies the manifest but breaks this template, and (2) a compiler release that will soon become stable. It does not decide the normal test harness (R32) or security-advisory scanning (R13). The Rust field, surveyed before selecting a tool, is:

| Bin | Candidate | What it decides | Evidence and retrieval date |
|---|---|---|---|
| Built-in / first-party toolchain | `cargo update --workspace` followed by the selected `cargo test` command; `rustup` `beta` | Re-resolve `Cargo.lock` within `Cargo.toml` constraints; select the pre-release compiler | Cargo documents that `cargo update` writes the newest available dependency versions to `Cargo.lock`, and that default/caret requirements admit SemVer-compatible updates. rustup documents `stable`, `beta`, and `nightly` as official channels. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html and https://rust-lang.github.io/rustup/concepts/toolchains.html (retrieved 2026-09-05). |
| Established industry standard | GitHub Actions `schedule`, job-level `continue-on-error`, `actions/checkout@v7`, and `dtolnay/rust-toolchain@beta` | Schedule the canary, make the beta check advisory, check out source, and install the channel | GitHub owns the workflow syntax; the two action maintainers document the current action interfaces. https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax and https://github.com/actions/checkout and https://github.com/dtolnay/rust-toolchain (retrieved 2026-09-05). |
| Up-and-comer / supplementary tool | `cargo-edit` `cargo upgrade`; `cargo-outdated`; `actions/github-script@v9` | Rewrite manifest bounds across breaking releases; report available updates; create or update an issue | These add policy or write access beyond the canary's question. `cargo-edit` is an MIT/Apache-2.0 crate; `cargo-outdated` is MIT. https://crates.io/crates/cargo-edit and https://crates.io/crates/cargo-outdated and https://github.com/actions/github-script (retrieved 2026-09-05). |

**Authority.** Cargo and rustup documentation are first-party specifications of the resolver and release channels. GitHub Actions documentation is the platform authority for scheduled triggers, permissions, and advisory jobs. The `dtolnay/rust-toolchain` maintainer documentation is authoritative for that action's channel-selection interface. Production workflow files are practice evidence, not standards: Serde runs a scheduled CI workflow and tests `[stable, beta]`; ripgrep schedules CI and includes stable, beta, and nightly; clap installs stable and nightly for its minimal-version job. These are well-regarded Rust references because Serde is a foundational serialization library, ripgrep is a widely used CLI maintained by Rust's regex author, and clap is the established CLI parser; the maintained workflows themselves show the practice. https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml and https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml and https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05).

The source precedents establish the problem, not the selected mechanics. py's canary deliberately discards its lock pins, resolves newest allowed dependencies weekly, and never gates a pull request; ts's Bun check is a non-gating forward-compatibility signal. The ledger records F126 as the portable scheduled-freshness capability and F127 as a JavaScript-runtime-specific choice whose Rust analogue needs evaluation. https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md (retrieved 2026-09-05).

### Principles and implementation

**Shared requirement and agreement level.** The common principle is *surface impending compatibility breakage before an unrelated contributor change is blocked or merged*. Agreement is at the **capability and CI-policy** level: each blueprint needs a non-merge-gating signal for upstream drift. It is not agreement on a shared low-level runtime, package manager, or action. F126's weekly latest-allowed dependency check is portable; F127's Bun mechanism is not, because Rust's official `beta` channel—not another runtime installer—is the relevant pre-stable signal. This conclusion follows the R34 divergence analysis and the official Rust channel model. https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md and https://rust-lang.github.io/rustup/concepts/toolchains.html (retrieved 2026-09-05).

**Essential behaviors and acceptance criteria.** The scheduled lane must run only on `schedule` and `workflow_dispatch`, re-resolve the checked-out `Cargo.lock` with ordinary manifest bounds, test that ephemeral lockfile, and not become a required pull-request status. It must test `ubuntu-latest` and `macos-latest`, the owner-fixed support matrix. The compiler lane must install the moving `beta` channel, invoke the same R32-selected core test command on Ubuntu, set job-level `continue-on-error: true`, and visibly retain a warning on failure. A beta result is advisory; the normal stable-minus-two MSRV job remains the compatibility gate. Cargo's resolver and `rust-version` support make testing an updated lockfile meaningful, while GitHub defines `continue-on-error` at job scope. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

**Architectural alternatives.** `cargo update --workspace` is preferred over `cargo-edit cargo upgrade`: the former tests the newest versions allowed by today's public compatibility contract without editing that contract; the latter changes `Cargo.toml` bounds, including potentially SemVer-incompatible major releases, which is a dependency-maintenance proposal rather than a canary. `cargo-outdated` is a report, not a resolution-and-test proof. A `nightly` lane is a noisier alternative to `beta`; it detects unstable-regression risk, but this template is stable-only and beta is the compiler about to become stable. No alternate compiler lane would save cost but loses the F127-derived early-warning capability. Cargo's documented default requirements admit compatible updates; clap's workflow demonstrates a separate nightly-only minimal-version procedure rather than conflating it with ordinary stable testing. https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html and https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml and https://crates.io/crates/cargo-edit and https://crates.io/crates/cargo-outdated (retrieved 2026-09-05).

**Failure reporting and cost.** Fail the scheduled job loudly in GitHub Actions, but do not grant `issues: write` or add issue-opening automation in the initial template. An automatic issue creates a second state machine (deduplication, close/reopen policy, and a write-capable token) without improving detection; GitHub's security guidance says to grant the minimum `GITHUB_TOKEN` permissions. `actions/github-script@v9` can make authenticated API calls and is a viable future escalation mechanism, but is not required for the capability. Set `permissions: { contents: read }`, a 30-minute timeout, a weekly off-peak cron, and workflow concurrency keyed by workflow name. GitHub schedules use the default branch's workflow file, so a manual `workflow_dispatch` is included for prompt confirmation after a manifest change. https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication and https://github.com/actions/github-script and https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows (retrieved 2026-09-05).

**Minimal realistic example and acceptance check.** Proposed, not executed: create a workspace with a CLI crate, a library crate, and a web-service crate; give one dependency a permissive compatible bound; run `cargo update --workspace`, then the R32-owned test command with `--locked`. The lockfile must change to a newer allowed release and the tests must exercise that resolved graph. In a pull-request workflow run, deliberately make the beta job's test command return nonzero: its job must be marked allowed-to-fail and the overall required stable gate must remain passing. These checks evaluate the full composition, rather than assuming an action's successful installation proves compatibility. Cargo documents `--locked` as rejecting a further lockfile change. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax (retrieved 2026-09-05).

BASELINE-REVIEW: F127 — impending-runtime compatibility principle is portable, but an alternate JavaScript runtime is not — use the official Rust `beta` compiler as an advisory lane, not Bun-style alternate-installer parity — Rust's official stable/beta/nightly channels and production beta practice support the native substitute; affected item R34. https://rust-lang.github.io/rustup/concepts/toolchains.html and https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05).

### Recommendation

Adopt one `scheduled-freshness.yml` workflow with two independent patterns:

1. A Tuesday 06:00 UTC, manually dispatchable `fresh-dependencies` matrix on `ubuntu-latest` and `macos-latest`: `actions/checkout@v7`, stable Rust, `cargo update --workspace`, then the R32-selected full test command with `--locked`. It has `permissions: { contents: read }`, `timeout-minutes: 30`, and is never a pull-request trigger or required status.
2. A `beta` job on ordinary `push` and `pull_request` CI, Ubuntu only, using `dtolnay/rust-toolchain@beta`, the same R32-selected core test command, and job-level `continue-on-error: true`. Ubuntu is sufficient for compiler-forward warning because the required stable CI and the weekly freshness matrix already cover both owner-required operating systems; it reduces every-push cost without reducing the platform support contract. The action itself is portable: its maintained composite action has explicit macOS handling, and the maintained Serde/ripgrep examples use the same action across runner matrices. https://github.com/dtolnay/rust-toolchain/blob/master/action.yml and https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml and https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05).

Use the action tags above as readable versions in the plan, then replace every third-party action reference with the immutable full commit SHA required by R20's eventual policy. Do not use `cargo-edit`, `cargo-outdated`, `nightly`, or issue filing in this first stack. `actions/checkout@v7` is the maintainer-documented current major; `dtolnay/rust-toolchain` documents channel-selected revisions such as `@nightly`, so `@beta` is the corresponding moving beta selector. https://github.com/actions/checkout and https://github.com/dtolnay/rust-toolchain (retrieved 2026-09-05).

### Members

#### scheduled Cargo dependency-freshness canary

##### Landscape

This member is a built-in Cargo plus GitHub Actions pattern, not a Rust crate. The shortlisted implementations are `cargo update --workspace`, `cargo-edit cargo upgrade`, and `cargo-outdated`; only the first re-resolves the existing manifest contract without mutating it. Cargo documents the distinction between updating `Cargo.lock` and version requirements. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html (retrieved 2026-09-05).

##### Principles and implementation

The member preserves reproducible ordinary CI while deliberately proving that the current semver bounds still work when the lockfile is refreshed. `cargo update --workspace` updates workspace dependencies in the checked-out ephemeral lockfile; the subsequent `--locked` test proves no additional resolver movement is needed. This is the Cargo analogue of py's `uv sync --upgrade`, not a policy to widen dependency constraints. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml (retrieved 2026-09-05).

##### Dominant choice

Use Cargo 1.98.0 or later's built-in `cargo update --workspace`; the local stable toolchain and the Rust distribution channel both identified stable as 1.98.0 on 2026-09-05. There is no external Cargo crate, action-specific crate, or additional async runtime. https://static.rust-lang.org/dist/channel-rust-stable.toml and https://doc.rust-lang.org/cargo/commands/cargo-update.html (retrieved 2026-09-05).

##### Qualified shortlist

`cargo-edit` 0.13.13 is compatible in license (`Apache-2.0 OR MIT`) and declares Rust 1.92, which is within the present stable-minus-two floor of Rust 1.96. Its crates.io figures are 505,345 recent downloads and 3,524,290 all-time downloads; its newest non-yanked release is 0.13.13 from 2026-07-15. It is qualified as a human-invoked manifest-maintenance tool, not as this canary. Endpoint: `GET https://crates.io/api/v1/crates/cargo-edit` and `GET https://crates.io/api/v1/crates/cargo-edit/versions` (retrieved 2026-09-05).

`cargo-outdated` 0.19.0 is MIT and declares Rust 1.88.0. Its figures are 69,874 recent downloads and 966,464 all-time downloads; its newest non-yanked release is 0.19.0 from 2026-04-14. It is qualified only as optional diagnosis after a failure, because it reports outdated packages rather than proving a new resolved graph builds. Endpoint: `GET https://crates.io/api/v1/crates/cargo-outdated` and `GET https://crates.io/api/v1/crates/cargo-outdated/versions` (retrieved 2026-09-05).

##### Excluded by gate

No shortlisted crate failed a license, declared-MSRV, RustSec, OS, feature, or build-cost gate. RustSec pages for `cargo-edit` and `cargo-outdated` returned no advisory entries on 2026-09-05; endpoint: https://rustsec.org/packages/cargo-edit.html and https://rustsec.org/packages/cargo-outdated.html. `cargo-edit` and `cargo-outdated` are excluded from the recommended stack by **fitness**, not a failed gate: they introduce an installed binary and either mutate bounds or merely report, neither of which implements the required newest-allowed resolution test. Their full dependency-tree MSRV, `unsafe` posture, and cross-platform CI badge were not independently verified; that gap is acceptable because neither is adopted. https://crates.io/crates/cargo-edit and https://crates.io/crates/cargo-outdated (retrieved 2026-09-05).

##### Up-and-comers

`cargo-outdated` is the relevant supplementary reporter, not an upgrade engine. Its default features, async-runtime coupling, and binary-size/compile-time cost are inapplicable to the recommended built-in-Cargo member; if adopted later, those properties and its dependency-tree MSRV need a fresh gate evaluation. https://crates.io/crates/cargo-outdated (retrieved 2026-09-05).

##### Fit for this template

`cargo update --workspace` has no crate license, crate downloads, crate release date, RustSec package page, dependency tree, `unsafe` posture, Cargo features, async runtime, binary-size, or compile-time cost to assess: each is **inapplicable** because Cargo is the Rust toolchain already required to build the CLI, library, and web service. It runs on both `ubuntu-latest` and `macos-latest` in the proposed matrix; Windows is intentionally not required by the owner parameter. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

##### Recommendation

Create `.github/workflows/scheduled-freshness.yml` with `on.schedule` Tuesday 06:00 UTC and `workflow_dispatch`; matrix `os: [ubuntu-latest, macos-latest]`; `permissions: { contents: read }`; `timeout-minutes: 30`; `actions/checkout@v7`; stable toolchain; `cargo update --workspace`; and the R32-selected full test command plus `--locked`. The workflow must not have `pull_request` or `push` triggers. GitHub schedule support and the py reference both support this cadence and non-gating role. https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows and https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml (retrieved 2026-09-05).

##### Ranked runner-up

Runner-up: a scheduled `cargo outdated --workspace --exit-code 1` report. Serde uses `cargo outdated --workspace --exit-code 1` in CI, demonstrating maintained production use, but this detects an available update rather than executing the selected latest graph, so it is weaker for F126. https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml and https://crates.io/crates/cargo-outdated (retrieved 2026-09-05).

##### Tradeoffs

The chosen canary may fail for a transient registry/network problem or a release that is compatible by declared SemVer but incompatible in practice. That is precisely why it is scheduled and non-gating. It costs two full test jobs each week; the 30-minute cap bounds stalled jobs. `cargo upgrade` would find major-version opportunities, but it would blur an upstream-breakage signal with a template-maintainer change proposal. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml (retrieved 2026-09-05).

##### Parameters

assumes `rust-edition = 2024`.

assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

assumes `license = MIT OR Apache-2.0`.

No `CONFLICT:` line: this member consumes no researched parameter and requires no fixed-parameter change. https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

##### Migration implications

Add `.github/workflows/scheduled-freshness.yml`. The eventual `Cargo.lock` remains committed and unchanged by CI because the scheduled runner's checkout is ephemeral. Add a short contributor-documentation note that red scheduled runs are maintenance signals, not merge blockers. No `Cargo.toml` dependency, source crate, or test-harness change belongs to R34. https://doc.rust-lang.org/cargo/commands/cargo-update.html (retrieved 2026-09-05).

##### Validation strategy

Planned command sequence in a template checkout: `cargo update --workspace`; `git diff --exit-code Cargo.lock` must fail when a compatible newer dependency is available; then run R32's full test command with `--locked`, which must pass and must not further alter `Cargo.lock`. On both proposed runner operating systems, manually dispatch the workflow and confirm the same job names, resolved lockfile behavior, and non-required status. These checks were not executed because the Rust template and R32 command do not yet exist. Cargo defines the `--locked` failure condition. https://doc.rust-lang.org/cargo/commands/cargo-update.html (retrieved 2026-09-05).

##### Confidence & re-verify trigger

High confidence in the built-in mechanism; re-verify when Cargo changes resolver/MSRV behavior, when the R32 test command is settled, or when R20 chooses action pinning. Re-run crate figures, release data, RustSec, and GitHub endpoint figures before any later decision to adopt `cargo-edit` or `cargo-outdated`. https://doc.rust-lang.org/cargo/commands/cargo-update.html (retrieved 2026-09-05).

##### Sources

Cargo command and dependency-reference documentation: https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html (retrieved 2026-09-05). Practice references: https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml and https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05). Crate figures: `GET https://crates.io/api/v1/crates/cargo-edit`, `GET https://crates.io/api/v1/crates/cargo-edit/versions`, `GET https://crates.io/api/v1/crates/cargo-outdated`, and `GET https://crates.io/api/v1/crates/cargo-outdated/versions` (retrieved 2026-09-05).

#### advisory Rust beta lane

##### Landscape

This member is a GitHub Actions pattern composed with the official Rust beta channel. The choices are beta, nightly, no alternate compiler, and a full beta matrix; current practice spans the spectrum: Serde includes beta in a stable/beta matrix, while ripgrep includes beta and nightly in a broad matrix. https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml and https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05).

##### Principles and implementation

Use `dtolnay/rust-toolchain@beta` to install Rust beta, then run the R32-selected core test command in a job with `continue-on-error: true`. The `beta` channel is the relevant pre-release because it is the next stable candidate; nightly is intended for unstable feature development, which the stable-only template does not promise. `continue-on-error` makes a failed beta check visible without turning it into the merge gate. https://rust-lang.github.io/rustup/concepts/toolchains.html and https://github.com/dtolnay/rust-toolchain and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax (retrieved 2026-09-05).

##### Dominant choice

Use `dtolnay/rust-toolchain@beta` with `actions/checkout@v7`; these are Actions patterns, not crates. The rust-toolchain README documents channel selection by action revision and the action uses rustup with `--profile minimal`; the current checkout README documents v7. https://github.com/dtolnay/rust-toolchain and https://github.com/dtolnay/rust-toolchain/blob/master/action.yml and https://github.com/actions/checkout (retrieved 2026-09-05).

##### Qualified shortlist

`dtolnay/rust-toolchain` is MIT-licensed and has no Rust crate figures, dependency tree, RustSec package page, Cargo features, async-runtime coupling, or Rust binary compile cost: each is **inapplicable** because it is a composite GitHub Action that installs rustup toolchains. Its source explicitly handles macOS and uses a minimal toolchain profile, so it is suitable for both required runner OSes; Windows support exists but is not required. The required GitHub REST repository endpoint for stars, archive state, and `pushed_at` failed with a shared unauthenticated rate-limit response, so those figures and the median first-maintainer-response calculation are unverified. The open-issues search endpoint returned 7 before the core limit was exhausted: `GET https://api.github.com/search/issues?q=repo:dtolnay/rust-toolchain+is:issue+is:open` (retrieved 2026-09-05). https://github.com/dtolnay/rust-toolchain/blob/master/action.yml and `GET https://api.github.com/repos/dtolnay/rust-toolchain` (rate-limited, retrieved 2026-09-05).

`actions/checkout@v7` is MIT-licensed, composite/JavaScript action infrastructure rather than a crate; its crate figures, RustSec, Cargo MSRV, Rust `unsafe`, features, runtime coupling, and Rust binary compile cost are **inapplicable**. Its README identifies v7, Node 24, and its MIT license. The required repository REST endpoint was rate-limited, so stars, archive status, `pushed_at`, and responsiveness are unverified; its issue-search endpoint returned 546 open issues before rate-limit exhaustion. https://github.com/actions/checkout and `GET https://api.github.com/repos/actions/checkout` and `GET https://api.github.com/search/issues?q=repo:actions/checkout+is:issue+is:open` (retrieved 2026-09-05; repository endpoint rate-limited).

##### Excluded by gate

No pattern candidate failed an applicable gate. `nightly` is excluded from the recommendation by fit: it has a larger, less release-imminent instability surface for a stable-only template. A no-lane option is excluded by the F127 capability requirement. The GitHub REST rate limit prevented archive, push-date, and 10-issue responsiveness verification for the action candidates; do not treat that blocked evidence as a passing metric. https://rust-lang.github.io/rustup/concepts/toolchains.html and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md (retrieved 2026-09-05).

##### Up-and-comers

`actions/github-script@v9` is a supplementary issue-filing option, not a toolchain installer. Its README describes a pre-authenticated GitHub client and Node 24 runtime; it is intentionally deferred because the recommended lane has no write need. Its GitHub repository endpoint was rate-limited; its issue-search endpoint returned 58 open issues before the limit. Crate figures and Rust-specific gates are **inapplicable**. https://github.com/actions/github-script and `GET https://api.github.com/repos/actions/github-script` and `GET https://api.github.com/search/issues?q=repo:actions/github-script+is:issue+is:open` (retrieved 2026-09-05; repository endpoint rate-limited).

##### Fit for this template

The beta lane runs a core cross-crate test command on `ubuntu-latest` for every ordinary CI event. It is intentionally not a second OS-support gate: stable CI and the weekly canary cover `ubuntu-latest, macos-latest`; the beta lane provides one economical compiler-forward signal. The action's maintained implementation includes runner-specific macOS behavior, so it can be widened to macOS without a tool substitution. https://github.com/dtolnay/rust-toolchain/blob/master/action.yml and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

##### Recommendation

Add an `advisory-beta` job to the ordinary test workflow: Ubuntu runner; 30-minute timeout; `actions/checkout@v7`; `dtolnay/rust-toolchain@beta`; the R32-selected core test command; and job-level `continue-on-error: true`. Do not install cargo components or add an async runtime. Retain explicit stable/MSRV jobs as the required compatibility checks. https://github.com/dtolnay/rust-toolchain and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax (retrieved 2026-09-05).

##### Ranked runner-up

Runner-up: an advisory `nightly` job on Ubuntu. Tokio, Serde, and ripgrep all use nightly for selected work, demonstrating its maturity; it is ranked below beta because their nightly jobs also exercise unstable features, Miri, sanitizers, or wide target matrices that R34 does not own. https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml and https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml and https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05).

##### Tradeoffs

Beta can be temporarily broken and therefore generates advisory noise; job-level `continue-on-error` keeps that noise from blocking contributors but risks it being ignored. Nightly would detect more changes earlier but increases false-positive and maintenance cost. Running beta on macOS too would improve platform/compiler coverage but doubles the per-push beta cost; the weekly two-OS canary is the proportionate initial counterbalance. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax and https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml (retrieved 2026-09-05).

##### Parameters

assumes `rust-edition = 2024`.

assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

assumes `license = MIT OR Apache-2.0`.

No `CONFLICT:` line: beta is advisory and does not change the owner-fixed MSRV floor or OS support matrix. https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

##### Migration implications

Modify the ordinary CI workflow chosen by R11/R32 to add `advisory-beta`; add no new Rust dependency. The test command must be a named R32-owned command so beta cannot silently become a different test tier. When R20 specifies action pinning, replace both action tags with full immutable SHAs while retaining readable comments naming `v7` and `beta`. https://github.com/dtolnay/rust-toolchain and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md (retrieved 2026-09-05).

##### Validation strategy

Planned check: on a branch, make the beta job's final command `false`; confirm it has an allowed-failure conclusion while required stable jobs remain successful. Restore the R32 command, dispatch a workflow after a beta release, and confirm the installed compiler reports beta and the same tests execute. Repeat with a deliberately stable-incompatible syntax or dependency only in an isolated fixture to prove stable remains separately enforced. These checks are not executed because no Rust CI or R32 command exists yet. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax and https://github.com/dtolnay/rust-toolchain/blob/master/action.yml (retrieved 2026-09-05).

##### Confidence & re-verify trigger

Medium-high confidence. Re-verify when GitHub changes `continue-on-error` semantics, rustup changes channel naming, `dtolnay/rust-toolchain` releases a breaking action version, the normal CI topology is chosen by R11, or the beta lane becomes routinely noisy enough to justify removal or a scheduled-only cadence. Re-query GitHub REST maintenance figures after rate-limit availability. https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax and https://rust-lang.github.io/rustup/concepts/toolchains.html (retrieved 2026-09-05).

##### Sources

Toolchain and action references: https://rust-lang.github.io/rustup/concepts/toolchains.html, https://github.com/dtolnay/rust-toolchain, https://github.com/dtolnay/rust-toolchain/blob/master/action.yml, and https://github.com/actions/checkout (retrieved 2026-09-05). Production examples: https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml, https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml, and https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05). GitHub figures attempted: `GET https://api.github.com/repos/dtolnay/rust-toolchain`, `GET https://api.github.com/repos/actions/checkout`, and `GET https://api.github.com/repos/actions/github-script` (all rate-limited on 2026-09-05); search endpoints are named in the relevant fields above.

### Compatibility

The members compose without a crate version matrix: both invoke Cargo against the same checked-out workspace and lockfile, but at different times and toolchains. The weekly member first changes the ephemeral lockfile under stable Rust and tests it on both supported OSes. The beta member leaves the committed lockfile intact and tests the ordinary graph with the next compiler on Ubuntu. Serde is a maintained shared reference for both patterns: its workflow schedules CI and has a stable/beta matrix; ripgrep independently demonstrates scheduled CI plus beta/nightly toolchains. https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml and https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05).

The expected composition is: normal CI proves the locked graph and MSRV floor; advisory beta proves compiler-forward compatibility without gating; scheduled freshness proves newest allowed dependency compatibility on both owner-required OSes. The R32 command must be injected consistently into both R34 lanes, but R34 neither selects nor changes that command. https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md (retrieved 2026-09-05).

### Parameters

assumes `rust-edition = 2024`.

assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes `license = MIT OR Apache-2.0`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

owns no registry parameter. No `CONFLICT:` line: the scheduled and advisory lanes preserve every fixed parameter. https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

### Migration implications

Add `.github/workflows/scheduled-freshness.yml` for the weekly two-OS canary. Modify the ordinary CI workflow selected by R11/R32 to add the Ubuntu advisory-beta job. Add a contributor-facing explanation that scheduled red means triage an upstream dependency or compiler change and that advisory beta is not a merge blocker. Do not add `cargo-edit`, `cargo-outdated`, `actions/github-script`, a second lockfile, or an issue-writing token. The corresponding source precedent is py's separate canary workflow, while ts's advisory runtime precedent is translated to beta rather than copied mechanically. https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md (retrieved 2026-09-05).

### Validation strategy

Planned integration checks, after R11 and R32 name the base workflow and test command:

```text
# Freshness workflow, on ubuntu-latest and macos-latest
cargo update --workspace
<R32-full-test-command> --locked

# Advisory beta job, on ubuntu-latest
rustc --version                 # expected: beta channel
<R32-core-test-command>         # expected: same tests as normal CI
```

Expected results: the first pair validates an ephemeral newest-allowed `Cargo.lock`; normal locked CI remains reproducible; a deliberately failing beta command is visible but cannot fail the required merge gate; and no job writes an issue. These are proposed checks, not executed results, because this repository has no Rust code, lockfile, or R32-selected test command. Cargo documents the lockfile behavior; GitHub documents job-level allowed failure. https://doc.rust-lang.org/cargo/commands/cargo-update.html and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax (retrieved 2026-09-05).

### Confidence & re-verify trigger

Confidence is high for `cargo update --workspace` as the latest-allowed canary mechanism and medium-high for a beta-only advisory lane. Re-verify before implementation if R32 selects a test command that cannot accept `--locked`, if R11's workflow topology makes a separate job impossible, if the MSRV/OS parameters change, or if GitHub's action pinning policy from R20 requires a different immutable reference form. Re-run GitHub REST repository, search, and responsiveness queries when rate limit is available; the core repository endpoints were blocked on 2026-09-05, so no maintenance verdict relies on guessed stars, archive state, pushed date, or 10-issue response medians. https://api.github.com/repos/dtolnay/rust-toolchain and https://api.github.com/repos/actions/checkout and https://api.github.com/repos/actions/github-script (retrieved 2026-09-05; rate-limited).

### Sources

Primary Rust sources: https://doc.rust-lang.org/cargo/commands/cargo-update.html, https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html, https://rust-lang.github.io/rustup/concepts/toolchains.html, and https://static.rust-lang.org/dist/channel-rust-stable.toml (retrieved 2026-09-05). Primary Actions sources: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows, https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax, and https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication (retrieved 2026-09-05). Action references: https://github.com/dtolnay/rust-toolchain, https://github.com/actions/checkout, and https://github.com/actions/github-script (retrieved 2026-09-05). Production references: https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml, https://github.com/BurntSushi/ripgrep/blob/master/.github/workflows/ci.yml, https://github.com/clap-rs/clap/blob/master/.github/workflows/ci.yml, and https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml (retrieved 2026-09-05). Source-precedent and ledger references: https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/canary.yml, https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md, https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md, and https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md (retrieved 2026-09-05).

Method notes: queried `GET https://crates.io/api/v1/crates/cargo-edit`, `GET https://crates.io/api/v1/crates/cargo-edit/versions`, `GET https://crates.io/api/v1/crates/cargo-outdated`, and `GET https://crates.io/api/v1/crates/cargo-outdated/versions` on 2026-09-05; the reported figures use the required `crate.recent_downloads`, `crate.downloads`, and first non-yanked version fields. Queried RustSec package pages for both crates; neither presented an advisory entry. Queried GitHub search issue endpoints for the three action repositories, but `GET https://api.github.com/repos/dtolnay/rust-toolchain`, `GET https://api.github.com/repos/actions/checkout`, and `GET https://api.github.com/repos/actions/github-script` returned an unauthenticated core-rate-limit error, preventing the required stars/archive/pushed-at fields and the 10-most-recent-open-issues responsiveness sample from being verified. No figures were invented; action-pattern crate figures are explicitly inapplicable.
