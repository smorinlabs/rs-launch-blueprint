# R38 commit-message-linter — decision (revision 1, 2026-09-05)

Item R38 (`commit-message-linter`, kind `crate`, owns `commit-message-convention`). Run `research/runs/R38/2026-09-05T151356Z-c46d732f98ed`. Synthesizer: actor `synth-fable-2026-09-05T151356Z-c46d732f98ed`, model `claude-fable-5-1` (family anthropic), a fresh context that produced none of the raw reports. Inputs: `inputs/prompt.md`, `raw/codex.md`, `raw/opus.md`, `docs/port/PARAMETERS.md`. No prerequisite decisions (the item consumes no parameter).

## Decision

**Adopt `committed` (crate-ci) at version `1.1.11`, accepted range `>=1.1.11, <2.0.0`, as the Conventional-Commits linter that runs at `commit-msg` time and again in CI**, configured by one repository-root `committed.toml`. The `commit-message-convention` it enforces is an explicit eleven-member type enum (`build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test`), a 50-column subject cap, and a 72-column cap on every body and footer line under soft-line measurement (the exact value is in `## Parameters`). commitlint through a provisioned Node/Bun runtime — both source repos' tool and the Codex report's pick — is the architectural runner-up and is not adopted.

Ledger rows this settles (all `docs/port/COMMONALITY.md:153-161`):

| Row | Settled value |
|---|---|
| F149 commit-msg linter tool | `committed` 1.1.11 (`>=1.1.11, <2.0.0`) |
| F150 hook invocation mechanism | `committed --fixup --wip --commit-file {1}` from the hook manager's `commit-msg` stage (`{1}` is the message-file path; R37 wires the stage) |
| F151 base config | `style = "conventional"` in `committed.toml` (the analogue of `extends: ['@commitlint/config-conventional']`) |
| F152 header cap | `subject_length = 50` |
| F153 body cap | `line_length = 72` |
| F154 footer cap | 72, through the same `line_length` (committed has no separate footer knob; stated gap below) |
| F155 type enum | explicit `allowed_types` with the eleven members (committed's default is only eight: no `build`, `ci`, `revert`) |
| F156 bot exemption | `ignore_author_re = "(dependabot\|renovate)"` — carried over in a laxer, one-line form (it skips the whole commit, not only the length rules) |
| F157 CI re-run | yes: the official `crate-ci/committed` composite action, pinned to the v1.1.11 commit `faeed42f2e10c244533a01525f13c4d8b6ce383f`, on `pull_request` over `HEAD~..HEAD^2` |

Derived values supplied to the two `ADOPT` rows the baseline review left "blocked pending R38" (`docs/port/BASELINE-REVIEW.md:76,78`): F158 — the `.gitmessage` content is stated verbatim below; F160 — the consistency-test adapter is a Rust integration test that parses `committed.toml` and `.gitmessage` and asserts one convention; both were executed in the fixture (`## Empirical check`, cases T1 and the hook cases).

### Principles and implementation

**Shared requirement and agreement level.** Every commit that lands is rejected before creation when its message violates one declared Conventional-Commits contract (type vocabulary and line widths), and every pull-request commit is checked again in CI so that `git commit --no-verify` cannot evade the contract. The agreement level is **capability/standard**: `docs/port/BASELINE-REVIEW.md:75` records F148 as "Enforce the selected commit-message convention at `commit-msg` time", retained; `docs/port/DIVERGENCE-ANALYSIS.md:155` classes the R38 tool row as class B (same pattern, language-bound tool, `harmonize: partly`) and the value rows F152-F155 as class A (`harmonize: yes`). So the *contract* must agree across py, ts and rs; the *program* that checks it may differ per ecosystem. Both raw reports read the level the same way (`raw/codex.md` "capability-level agreement, not a shared language runtime"; `raw/opus.md` "the agreement level is the contract ... not the program that checks it").

**Essential behaviors** (any candidate must do all five): (1) read one pending message file and exit non-zero on violation — the `commit-msg` contract; (2) validate the Conventional-Commits grammar and restrict `type` to a declared list; (3) cap subject width and body/footer width; (4) re-run over a commit range in CI; (5) fail loudly when the tool is missing or misconfigured, never exit 0 on an unvalidated message.

**Observable acceptance criteria**, each mapped to an executed fixture case (`review/evidence/committed-1.1.11-acceptance.log`):

| Criterion | Case | Observed |
|---|---|---|
| Conforming message exits 0 | 01, R1, H0 | 0 |
| Type outside the enum exits non-zero | 02, R2, H1 | 1; the hook left HEAD unchanged |
| Subject over 50 columns exits non-zero | 03 | 1 (`71 exceeds the max length of 50`) |
| Body line over 72 columns exits non-zero | 04 | 1 (`83 exceeds the max length of 72`) |
| Footer line over 72 columns exits non-zero | 08 | 1 (`96 exceeds the max length of 72`) |
| A bare URL line, or a trailer whose final token is a URL, exits 0 | 05 (116-col permalink), 07 (107-col `Claude-Session:` trailer) | 0 |
| Subject ending in a period exits non-zero | 06 | 1 |
| `git commit --no-verify` bypasses the hook, and the range check catches the commit | H2 then H3 | 0 then 1 |
| Bot-authored commit is exempt on the range path only | R3, R4 (dependabot[bot]) vs 19, R5 (hook path / human) | 0, 0 vs 1, 1 |
| Missing binary fails loudly | 16 | 127 |
| Missing `committed.toml` is not a silent pass | 15 | 1 (`Subject should be capitalized`) |
| `.gitmessage` and `committed.toml` express one convention | T1 (`cargo test`) | 3 tests pass |

**What must agree and what may vary.** Must agree across the three repos: the eleven types, the 50-column subject cap, the 72-column body cap, the footer cap, and the fact of a CI re-run. May vary: the binary, its configuration syntax, the invocation mechanics, and how the bot exemption is expressed. The values proposed here are the harmonized class-A values for all three repos; changing py and ts is a follow-on project and only its rationale is supplied (below).

**Architecture alternatives compared** (before libraries, per owner amendment A5):

- (A) *Provision a JS runtime and run commitlint.* Preserves byte-identical rule configuration with py and ts and offers a separate footer knob. Cost: `@commitlint/cli` 21.2.2 declares `engines.node >= 22.12.0` (`https://registry.npmjs.org/@commitlint/cli`, retrieved 2026-09-05 by both raws), so a Rust template acquires a Node/Bun runtime, a `package.json`, a JS lockfile and `node_modules` solely to lint messages, and it imports the three silent-pass modes py measured in `lefthook.yml:18-58` (bare-name 127s, script-name shadowing returning 0 for an invalid message, `bunx` fetching `@latest` behind the lockfile). R42 (`package-manager-invocation`) would also have to provision that runtime.
- (B) *A native binary with its own config file.* Loses config-file identity with the sources but preserves the contract, which is what the agreement level binds. The tool is a developer-machine and CI binary, never a crate dependency, so it never enters the template's dependency graph, binary size, MSRV or compile time. Two of py's three silent-pass modes disappear by construction (no package-script namespace, no network fallback) and the third becomes loud (case 16: exit 127).
- (C) *A hand-rolled regex in the hook.* Rejected: it re-derives a specification that has conforming implementations and cannot express fixup/WIP, punctuation or merge-commit rules.

(B) is selected. Within (B), capability was filtered before popularity, as `## Required evidence` orders it, and the field is narrower than download counts suggest: `convco check` enforces no length rule at all (its `description.length.max` serves the interactive `convco commit`; the only `len()` in `src/cmd/check.rs` truncates failure output) and `cocogitto`'s `Settings` struct has no length field and is `deny_unknown_fields` (`raw/opus.md`, source re-verified against `convco/src/cmd/check.rs` and `cocogitto/crates/cocogitto/src/settings/mod.rs`, 2026-09-05; `raw/codex.md` reaches the same exclusions from the projects' documentation). Only `committed` and `git-sumi` express types plus both caps; only `committed` adds an author exemption, declares an MSRV, and ships prebuilt binaries for both required runners.

**Fitness gates for `committed` 1.1.11** (all verified at the `v1.1.11` tag on 2026-09-05 unless noted):

| Gate | Result | Evidence |
|---|---|---|
| 1 license | pass: `MIT OR Apache-2.0` (identical to the fixed `license`) | `Cargo.toml` `[workspace.package] license` at v1.1.11 |
| 2 MSRV | pass: `rust-version = "1.89"`, edition 2024; stable is 1.98.x, so the policy floor is 1.96.x and 1.89 sits under it. Scope note: a dev-tool binary, so the gate binds only the `cargo install` path; prebuilt assets and the action need no toolchain | `Cargo.toml` at v1.1.11; `rustc 1.98.0` on this host |
| 3 advisories, unsafe | pass with one recorded uncertainty: `https://rustsec.org/packages/committed.html` returns 404, which `raw/opus.md` control-tested the same day against `time`, `openssl`, `atty` (200) and read as "no advisory page"; `raw/codex.md` read the same 404 as an evidence gap. Zero `unsafe` across the ten source files (`raw/opus.md` audit); the one FFI dependency is `git2` with `default-features = false` | RustSec page; `crates/committed/Cargo.toml` at v1.1.11 |
| 4 OS matrix | pass: upstream CI runs `ubuntu-latest, windows-latest, macos-latest`; release assets exist for `aarch64/x86_64-apple-darwin` and `aarch64/x86_64-unknown-linux-musl` (plus Windows, noted not required); executed here on macOS 26.4 arm64 | `.github/workflows/ci.yml:36-40` (`raw/opus.md`); `gh api repos/crate-ci/committed/releases/latest` |
| 5 features, async | pass: one optional feature `unstable-schema` (schemars), off by default; no async runtime in the dependency list | `crates/committed/Cargo.toml` at v1.1.11 |
| 6 size, compile cost | pass, external to the template: 3,868,064-byte binary; `cargo install --locked` took 22.8 s wall / 170.6 s user CPU on this host (arm64; `time` reported 793% CPU); ~0 s when the release asset or the action is used | this run's install log |

Figures (crates.io `GET /api/v1/crates/committed`, re-read 2026-09-05T16:00Z: `recent_downloads` 3,551; `downloads` 84,746; `max_stable_version` 1.1.11; GitHub per `raw/opus.md` 2026-09-05: 182 stars, 22 open issues, `pushed_at` 2026-09-01, median 0.28 days to first maintainer response over the ten most recent issues). Maintenance state: **active** — the 6.4-month-old release triggered investigation, which found commits through 2026-09-01 and sub-day issue response. Author `epage` is on the rust-lang Cargo team (`rust-lang/team/teams/cargo.toml`, `raw/opus.md`).

**Reference implementations.** `clap-rs/clap` (repo-root `committed.toml`, the hook through a hook manager, `.github/workflows/committed.yml` re-running the action over the PR range with `fetch-depth: 0`), `ratatui/ratatui` (whose `committed.toml` sets exactly these eleven `allowed_types`), `rust-cli/env_logger`, `toml-rs/toml`, `crate-ci/typos`, and `crate-ci/committed` itself; 258 repositories publish a `committed.toml` (`GET https://api.github.com/search/code?q=filename:committed.toml`, all `raw/opus.md`, 2026-09-05). That the three crates a CLI + library template most depends on (`clap`, `env_logger`, `toml`) enforce their commits with this tool is the strongest fit signal available.

**Selected design — the files the template carries.** Every snippet below is the content executed in `review/empirical/`.

`committed.toml` (repository root; discovered with no `--config` flag, verified by `--dump-config -` in the log):

```toml
style = "conventional"
allowed_types = ["build", "chore", "ci", "docs", "feat", "fix", "perf", "refactor", "revert", "style", "test"]
subject_length = 50
line_length = 72
subject_capitalized = false
subject_not_punctuated = true
imperative_subject = false
merge_commit = false
ignore_author_re = "(dependabot|renovate)"
```

Why each non-obvious setting: `subject_capitalized = false` is required, not cosmetic — the default `true` rejects every lower-case Conventional subject (case 15). `imperative_subject = false` because neither source enforces mood (commitlint has no such rule) and enabling it would reject this repository's own history (`docs: P01 port research tree (phases 1-5)`, case 10 passes). `hard_line_length` is left at its default 0 because 1.1.11 dispatches it with the soft limit (`crates/committed/src/checks.rs:98-100` at the tag reads `check_hard_line_length(source, message, config.line_length(), report)`; reproduced in case 17) and enabling it voids the un-wrappable-token exemption. `merge_commit = false` makes merge commits in a range fail with the explicit `Merge commits are disallowed` (case R8); with `true` they still fail the grammar (`Missing type`, case R9), so the field only controls the clarity of the failure.

Hook command (R37 wires the stage; this item fixes the command): `committed --fixup --wip --commit-file {1}`. The two flags are crate-ci's canonical `commit-msg` arguments (`.pre-commit-hooks.yaml` at v1.1.11: `args: [--fixup, --wip, --commit-file]`); without them `git commit --fixup` is rejected (case 11), with them it passes (cases 12, H4) while `WIP:` and grammar violations are still rejected (case 13). The CI range check runs without the flags, so a `fixup!` commit that survives to a PR is still caught. No explicit-path or runtime prefix is needed: py's `bun ./node_modules/@commitlint/cli/cli.js` form guards npm resolution hazards a static binary does not have.

CI re-run (illustrative; R11 decides whether it is its own workflow or a job in the shared one; R20 owns the pinning policy; R08 owns permission hardening):

```yaml
on:
  pull_request:
  merge_group:   # required-check no-op inside the merge queue (F025)
permissions: {}
jobs:
  commit-lint:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>   # pinned per R20
        with:
          fetch-depth: 0               # range scan needs history
      - if: github.event_name == 'pull_request'
        uses: crate-ci/committed@faeed42f2e10c244533a01525f13c4d8b6ce383f   # v1.1.11
        with:
          args: -vv --no-merge-commit
          commits: HEAD~..HEAD^2
```

`faeed42f…` is the commit the `v1.1.11` tag object `0a8b458c…` peels to (`gh api repos/crate-ci/committed/git/ref/tags/v1.1.11`, 2026-09-05). The action's `action/entrypoint.sh` hardcodes `VERSION=1.1.11` and downloads `committed-v1.1.11-<arch>-unknown-linux-musl.tar.gz` (or the apple-darwin asset) with `wget`, so the SHA pin fixes the binary version as well; the job therefore needs network egress to `github.com/crate-ci/committed/releases`. `HEAD~..HEAD^2` on the `pull_request` merge checkout is the PR's own commits (verified: case R7 exits 0 over a linear topic branch). The job runs on `pull_request` and not on `push` to `main`, because `main` carries `Merge pull request` commits by the org's merge policy and those fail the grammar under any setting (R8/R9); every commit reaches `main` through a PR, so the principle "every commit that lands is checked" is preserved. release-please's own `chore(main): release …` commits are conventional.

`.gitmessage` (F158; wired by F159's `git config commit.template .gitmessage`, unchanged):

```text
# <type>(<scope>): <subject>
# |<----  Using a maximum of 50 characters  ---->|
#
# Types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
#
# Example:
# feat: add user authentication
# fix(auth): resolve login timeout issue
#
# - Separate subject from body with a blank line
# - Limit the subject line to 50 characters
# - Use a lower-case subject line (documented convention; the linter
#   does not check subject case)
# - Do not end the subject line with a period
# - Prefer the imperative mood in the subject line (documented convention;
#   the linter does not check mood)
# - Wrap the body and footer at 72 characters; a bare URL or any other
#   un-wrappable final token on a line is exempt from the cap
# - Footers: BREAKING CHANGE: <description>, Refs: #<issue>
```

The template is comment-only, so an unedited template yields an empty message that git aborts. Unlike ts's `.gitmessage:12` ("commitlint rejects sentence-case"), it does not document a rule the selected linter does not enforce.

F160 adapter (executed as `review/empirical/repo-hygiene/tests/commit_convention.rs`): a Rust integration test with a `toml` dev-dependency that (a) parses `committed.toml`, reads `allowed_types`, parses the `# Types:` line of `.gitmessage`, and asserts **ordered, exact** equality of the two lists (the same strictness as ts `tests/repo-hygiene.test.ts:19-34`) and that the list has eleven members; (b) asserts `subject_length == 50` and `line_length == 72` and that the numbers quoted in `.gitmessage` ("maximum of 50", "Limit the subject line to 50", "Wrap the body and footer at 72") equal them; (c) asserts `style == "conventional"`, `subject_capitalized == false`, `imperative_subject == false`, `merge_commit == false`, `hard_line_length` absent or 0, and that `ignore_author_re` is present. In the template it resolves the repository root from `CARGO_MANIFEST_DIR`; where the meta-suite lives follows R02's crate topology (`docs/port/BASELINE-REVIEW.md:70`).

Installation and version pinning (R42 decides the mechanism; this item fixes the requirement): the command resolved on PATH must be `committed` at exactly 1.1.11, asserted by `committed --version` in the setup recipe, because `cargo install` is global and has no per-repo lockfile — the one weakened analogue of py's version-drift mode that survives. Available paths, in order of cost: the prebuilt release asset for `aarch64/x86_64-apple-darwin` and `*-unknown-linux-musl`; `cargo install committed --locked --version 1.1.11` (22.8 s wall here); `mise use committed@1.1.11` via the `aqua:crate-ci/committed` registry entry (`raw/opus.md`, `jdx/mise/registry/committed.toml`, 2026-09-05). CI is authoritative because the action pin fixes its own binary.

**Stated gaps and divergences** (each is a deliberate, recorded property, not an oversight):

1. *No separate footer cap.* `line_length` governs body and footer alike, so the footer cap is 72, not py's 200. The messages that motivated py's 200 (permalinks, `Claude-Session: <url>` trailers) pass because the URL is the un-wrappable final token (cases 05, 07). No surveyed native tool has a separate footer knob.
2. *No subject-case rule.* `committed` cannot forbid capitals; `feat(cli): Add a capitalised subject` passes (case 09) where py and ts reject it. The comparison run shows the same rule also rejects this repository's real `docs: P01 port research tree (phases 1-5)` (`commitlint-21.0.2-comparison.log`, case 10), so the gap is in practice a tolerance for identifier-leading subjects; the values still harmonize, and `.gitmessage` documents lower-case as the convention.
3. *Linear PR branches.* A merge commit inside a checked range fails under every setting (R8/R9), and git runs `commit-msg` for `git merge`, so merging `main` into a feature branch is rejected at the hook (case H5, `Not committing merge`). commitlint ignores `Merge branch` messages by default (comparison case 20). Contributors rebase (`git rebase main`, or `git config pull.rebase true`); `CONTRIBUTING.md` must say so. Upstream skipping of merge commits is a re-verify trigger.
4. *`ignore_author_re` skips the whole commit* (`main.rs:199-207` matches the regex against the author's `Name <email>`, and `main.rs:250-252` then skips every check for that commit), where py's dependabot config kept the format rules. Dependabot's subjects routinely exceed 50 columns (case 19: 71), so without the exemption every dependabot PR fails CI; the residual risk is that a bot commit's *type* is unchecked, which R19 (`dependabot-config-shape`) bounds through dependabot's own `commit-message` prefix setting.
5. *Unreported upstream defect.* `hard_line_length` receives the soft limit (case 17). The recommended config never reaches that branch; a fix upstream is a re-verify trigger and a worthwhile contribution.

**Cross-repo rationale** (follow-on project; no py or ts file is changed here). py: add `header-max-length` 50 (it inherits 100) and lower `body-max-line-length`/`footer-max-line-length` from 200 to 72 — commitlint 21.x already exempts any line containing `https?://` (`@commitlint/ensure/lib/max-line-length.js`, comparison cases 05 and 07), so permalinks were never the binding reason; the one class py cited that commitlint would still cap is a long non-URL identifier on a line (comparison case 17), which py should evaluate against its history before lowering. ts: add an explicit `footer-max-line-length` 72 (it silently inherits 100) and consider a CI re-run (F157), a gap that `docs/port/DIVERGENCE-ANALYSIS.md:162` reads as accidental rather than deliberate. Both keep the eleven types; py's inherited default already equals ts's explicit list.

**Ranked runner-ups and the condition under which each wins.** (1) commitlint via a provisioned runtime — wins if R37 or R42 independently provision a lockfile-managed Node/Bun runtime for another tool, at which point its marginal cost is one devDependency and it buys a separate footer knob and a subject-case rule; it would re-import py's three measured resolution modes and needs `bun ./node_modules/@commitlint/cli/cli.js --edit {1}` by explicit path. (2) `git-sumi` 0.3.0 — the only other native tool expressing types plus both caps; wins only if `committed` stops being maintained and `git-sumi` declares a `rust-version` (gate 2 unmet today), at the cost of whole-line counting (the 72 cap would have to rise) and a CI-side bot workaround. (3) `commitlint-rs` — wins if it ships release binaries again and reaches 1.0; it alone could unify all three repos' rule files. (4) `convco`/`cocogitto` — win only if the owner drops the length half of the parameter.

**Performance.** Workload: one message of a few hundred bytes per `git commit`, and a PR range in CI; every candidate is bounded by process start-up, and the only distinguishing term is native start-up versus Node ≥ 22.12 start-up plus module resolution. No throughput figure was measured or claimed; the tool is not selected on speed.

**Fit per surface.** CLI: strongest fit — `committed` is itself a `clap` CLI and its adopters are the crates a CLI template depends on. Library: nothing enters the published crate's dependency tree, docs.rs build, MSRV or semver surface, and no `package.json` appears in a library repository. Web service: orthogonal to the `web-extra-surface` feature gate; `build` and `ci` — the types container and deployment changes use most — are absent from `committed`'s eight-member default, which is why `allowed_types` is explicit.

**Validation that remains planned, not executed.** The same runner on `ubuntu-latest` (Linux behavior is inferred from upstream's three-OS CI and the musl release assets; this run exercised macOS 26.4 arm64 only); the action pinned by SHA on a live pull request; the hook wired through R37's chosen manager with the `{1}` placeholder (a raw `.git/hooks/commit-msg` stood in for it here).

re-verify: 2027-03-01, or earlier on any `committed` release beyond 1.1.11 (re-check soft-line measurement and the `hard_line_length` dispatch in `checks.rs`), a RustSec advisory for `committed` or `git2`, R37/R42 provisioning a Node/Bun runtime for another tool, or `commitlint-rs` shipping release binaries

## Parameters

- owns commit-message-convention = type-enum: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test; header-max-length: 50; body-max-line-length: 72; footer-max-line-length: 72; length-semantics: soft-line (the subject and every body/footer line are measured up to their last space, so a bare URL or any other un-wrappable final token never violates a cap)
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

Consumed parameters: none (`- consumes:` is empty in the prompt). Neither raw report raised a `CONFLICT:` line and none is raised here. Downstream note for R24 and the release-please rows F063/F066/F073: all eleven types are present in `conventional-changelog-conventionalcommits` `DEFAULT_COMMIT_TYPES` with a section and bump effect each (`raw/opus.md`, `packages/conventional-changelog-conventionalcommits/src/constants.js`, 2026-09-05), so the enum maps to changelog sections without renaming; which sections are visible remains R24's decision.

## Empirical check

Toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `git version 2.50.1 (Apple Git-155)`; OS `Darwin 25.4.0 arm64`, macOS 26.4 (build 25E246). Executed by the synthesizer on 2026-09-05.

Working directory: `research/runs/R38/2026-09-05T151356Z-c46d732f98ed/review/empirical` (fixture: `committed.toml`, `.gitmessage`, `messages/*.txt`, `run-checks.sh`, the `repo-hygiene` cargo project with `Cargo.lock`, and two `--config` variants used only by cases 17 and R9; `tools/`, `.work/` and `repo-hygiene/target/` are git-ignored and recreated by the runner).

Command: `bash run-checks.sh` — exit status **0**. Full output: `review/evidence/committed-1.1.11-acceptance.log`. The runner provisions the binary when absent (`cargo install committed --locked --version 1.1.11 --root tools`); in the logged run `tools/` was already present from the synthesizer's pre-run install with that identical command (22.8 s wall, 170.6 s user, binary 3,868,064 bytes), so the log shows only the version and size, and the auditor's fresh rerun will produce its own install output. The runner then asserts `committed --version` equals `committed 1.1.11`, builds throwaway git repositories under `.work/`, and exits 0 only when every asserted case matches. Summary line observed: `summary: PASS=32 FAIL=0 RECORD=4` then `RESULT: PASS`.

Observed exit codes (hook path = `committed --commit-file <file>` in a repository whose root holds `committed.toml`):

| Case | Scenario | Observed |
|---|---|---|
| 01 | conforming message | 0 |
| 02 | type `wibble` | 1 — ``Disallowed type `wibble` used, please use one of ["build", "chore", "ci", "docs", "feat", "fix", "perf", "refactor", "revert", "style", "test"]`` |
| 03 | 71-col subject with spaces | 1 — `Commit subject is too long, 71 exceeds the max length of 50` |
| 04 | 83-col body line with spaces | 1 — `Line is too long, 83 exceeds the max length of 72` |
| 05 | bare 116-col permalink URL body line | 0 |
| 06 | subject ends with `.` | 1 — ``Subject should not be punctuated but found `.` `` |
| 07 | 107-col `Claude-Session: <url>` footer | 0 |
| 08 | 96-col footer line with spaces | 1 — `Line is too long, 96 exceeds the max length of 72` |
| 09 | `feat(cli): Add a capitalised subject` | 0 (no subject-case rule) |
| 10 | `docs: P01 port research tree (phases 1-5)` | 0 |
| 11 / 12 | `fixup! …` without / with `--fixup --wip` | 1 (`Fixup commits must be squashed`) / 0 |
| 13 | `WIP: still working` with the flags | 1 — `Missing type in the commit summary` |
| 14 | no blank line after the subject (recorded) | 1 — `Incorrect body syntax` |
| 15 | no `committed.toml`, `ci(deps): bump actions/checkout to v6` | 1 — ``Subject should be capitalized but found `ci(deps):` `` |
| 16 | `PATH=/nonexistent` | 127 — `env: committed: No such file or directory` |
| 17 | `--config committed-hardline.toml` (`hard_line_length = 200`), 100-col space-free line | 1 — `Line is too long, 100 exceeds the max length of 72` (defect reproduced) |
| 18 | recommended config, same 100-col space-free line | 0 |
| 19 | dependabot-style message on the hook path | 1 — `Commit subject is too long, 71 exceeds the max length of 50` |
| 20 | `Merge branch 'main' into topic` via `--commit-file` (recorded) | 1 — `Missing type in the commit summary` |
| R1-R6 | range path: valid → 0; human `wibble` → 1; the same commit by `dependabot[bot]` → 0; realistic dependabot message by the bot → 0, by a human → 1; `base..HEAD` → 1 | as listed |
| R7 | `HEAD~..HEAD^2` on a `--no-ff` merge checkout (the action default) | 0 |
| R8 / R9 | `HEAD~..HEAD` including the merge commit, `merge_commit = false` / `= true` (R9 recorded) | 1 (`Merge commits are disallowed` plus `Missing type`) / 1 (`Missing type` only) |
| H0-H4 | raw `.git/hooks/commit-msg` running `committed --fixup --wip --commit-file "$1"`: conforming commit 0; bad type blocked (1, HEAD unchanged); `--no-verify` bypass 0 then `committed HEAD` 1; `git commit --fixup <good>` 0 (`fixup! feat(cli): add --json output flag`) | as listed |
| H5 | `git merge --no-ff topic` through that hook (recorded) | 1 — `.git/MERGE_MSG: … Missing type`, `Not committing merge` |
| T1 | `cargo test --manifest-path repo-hygiene/Cargo.toml --locked` (F160 adapter) | 0 — `running 3 tests … test result: ok. 3 passed` |

Supplementary comparison, not part of the acceptance argv: `bash commitlint-compare/compare.sh` (the installed `@commitlint/cli@21.0.2` on Node v26.5.0, same messages, same eleven types and 50/72/72 as explicit rules plus config-conventional's `subject-case` and `subject-full-stop`) — output `review/evidence/commitlint-21.0.2-comparison.log`. Agreement on cases 01-08 and 19; recorded divergences: 09 and 10 rejected by `subject-case` (committed accepts), 11 and 20 accepted by commitlint's default ignores (committed rejects the merge message and needs `--fixup`), 17 rejected by commitlint's whole-line count (committed's soft-line accepts).

## Engines

- codex `raw/codex.md` — actor `research-codex-2026-09-05T151356Z-c46d732f98ed`, model `gpt-5.6-terra` via `codex-cli-0.153.2` (family openai), sha256 `a018928b40ee1238d29c05911d08288b34cc06ee594be162892976b48dce08e2`; shape check passed; recommends commitlint `>=21.2.2 <22` via Bun with 50/72/200 and the eleven types; executed no commands.
- opus `raw/opus.md` — actor `research-opus-2026-09-05T151356Z-c46d732f98ed`, model `claude-opus-5[1m]` via `claude-agent-tool` (family anthropic), sha256 `a3f2978639bc460b15067242a41a45c812fad8b08789bd4657ef149690f3c491`; shape check passed; recommends `committed` 1.1.11 with 50/72/72 and the eleven types; executed 20 local cases on macOS.
- doxa: not yet available (billing blocked 2026-09-05); this revision synthesizes two engines and will be superseded when the third report arrives.

Disagreements and the evidence that settled each:

| # | Topic | Codex | Opus | Settled by | Outcome |
|---|---|---|---|---|---|
| 1 | The tool | commitlint via Bun; excludes `committed` because it "cannot set a 72-character body limit and a distinct 200-character footer limit" | `committed`; separate footer knob is a stated gap | Codex's exclusion depends on a footer cap that differs from the body cap — a value Codex chose, not an owner requirement; `docs/port/DIVERGENCE-ANALYSIS.md:159` (F154) asks to "pick one footer length cap (or accept config-conventional's default)"; the agreement level is capability/standard (`BASELINE-REVIEW.md:75`); the fixture shows the whole 50/72/72 contract enforced (cases 03, 04, 08) | `committed` |
| 2 | Footer cap | 200, to keep py's permalink rationale | 72, because soft-line measurement exempts un-wrappable tokens | Cases 05, 07, 18 (long URL and non-URL tokens pass at 72); Git's own 50/72 guidance (`git-commit` DISCUSSION, Pro Git, `raw/opus.md`) | 72 |
| 3 | Does commitlint exempt URL lines? | Yes ("commitlint's URL exception already permits a body line containing a URL") | Implies no ("commitlint counts whole lines"), calling soft-line the load-bearing discovery | The installed `@commitlint/ensure/lib/max-line-length.js` (21.0.2) skips any line matching `\bhttps?://\S+`; comparison cases 05/07 pass, case 17 (non-URL token) fails | Codex is right; Opus's finding is narrowed to non-URL un-wrappable tokens, and py's 200 was never binding for URLs under current commitlint |
| 4 | F156 bot exemption | Drop it; one invariant for every author | Carry via `ignore_author_re` | Case 19/R5: dependabot subjects exceed 50 columns, so without an exemption every dependabot PR fails CI; R3/R4 show the exemption applies on the range path only | Carried, with the whole-commit-skip caveat stated |
| 5 | `cocogitto` maintenance | stable-quiet | at-risk (10 of 10 recent issues unanswered, no push in ~4.5 months) | Opus applied the prescribed ten-issue sample; Codex did not compute responsiveness | Recorded as at-risk with the caveat of a one-day sample; immaterial to the pick (excluded on capability by both) |
| 6 | RustSec 404 | evidence gap | no advisory page, control-tested against known-advisory crates | The control test is the only evidence either side produced; I did not repeat it | No known advisory; a 200 at that URL is a re-verify trigger |
| 7 | `hard_line_length` defect | not examined | found in `checks.rs:98-100`, reproduced on 1.1.11 | Re-read at the `v1.1.11` tag and reproduced here (case 17) | Confirmed; config avoids it |
| 8 | Runner-up order | `committed` (wins only if the owner adopts one global line length) | `git-sumi`, then commitlint via runtime | Whether a JS runtime already exists is the only condition that changes the architecture; `git-sumi` fails gate 2 | commitlint-via-runtime first, `git-sumi` second |

Findings neither raw made: commitlint's `subject-case` rejects this repository's real subject `docs: P01 port research tree (phases 1-5)` (comparison case 10); git runs `commit-msg` for `git merge`, so the hook rejects local merges (case H5); merge commits in a range fail under both `merge_commit` values (R8/R9), which fixes the CI trigger to `pull_request` and the branch discipline to linear.

Remaining uncertainty: Linux was not exercised locally (inferred from upstream CI and the musl assets); adopter sets for `convco`, `cocogitto` and `git-sumi` were not enumerated to recommendation standard by either raw; the npm-side advisory status of commitlint was not audited; the third engine's report is pending and this revision will be superseded when it arrives.

Sources carried over from the raws (retrieved 2026-09-05 unless noted): Conventional Commits v1.0.0 `https://www.conventionalcommits.org/en/v1.0.0/`; `git-commit` DISCUSSION `https://git-scm.com/docs/git-commit`; Pro Git commit guidelines `https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project`; `committed` reference `https://github.com/crate-ci/committed/blob/master/docs/reference.md`; `committed` `checks.rs` `https://raw.githubusercontent.com/crate-ci/committed/master/crates/committed/src/checks.rs`; `committed` CI matrix `https://raw.githubusercontent.com/crate-ci/committed/master/.github/workflows/ci.yml`; `.pre-commit-hooks.yaml` `https://raw.githubusercontent.com/crate-ci/committed/master/.pre-commit-hooks.yaml`; adopters `https://raw.githubusercontent.com/clap-rs/clap/master/committed.toml`, `https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/committed.yml`, `https://raw.githubusercontent.com/ratatui/ratatui/main/committed.toml`, `https://raw.githubusercontent.com/rust-cli/env_logger/main/committed.toml`, `https://raw.githubusercontent.com/toml-rs/toml/main/committed.toml`, `https://raw.githubusercontent.com/crate-ci/typos/master/committed.toml`; Cargo team roster `https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml`; `@commitlint/config-conventional` source `https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/src/index.ts`; commitlint rules `https://commitlint.js.org/reference/rules.html`; `@commitlint/cli` registry metadata `https://registry.npmjs.org/@commitlint/cli/latest`; `conventional-changelog-conventionalcommits` constants `https://raw.githubusercontent.com/conventional-changelog/conventional-changelog/master/packages/conventional-changelog-conventionalcommits/src/constants.js`; competitor sources `https://raw.githubusercontent.com/convco/convco/main/src/cmd/check.rs`, `https://raw.githubusercontent.com/cocogitto/cocogitto/main/crates/cocogitto/src/settings/mod.rs`, `https://raw.githubusercontent.com/welpo/git-sumi/main/src/lint.rs`, `https://raw.githubusercontent.com/KeisukeYamashita/commitlint-rs/main/cli/src/rule/body_max_length.rs`; py hook analysis `https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/b08bccf/lefthook.yml`; crates.io and GitHub figure endpoints as prescribed in the prompt. Retrieved by the synthesizer on 2026-09-05: `https://raw.githubusercontent.com/crate-ci/committed/v1.1.11/{action.yml,action/entrypoint.sh,docs/reference.md,.pre-commit-hooks.yaml,Cargo.toml,crates/committed/Cargo.toml,crates/committed/src/{checks.rs,main.rs,config.rs}}`; `gh api repos/crate-ci/committed/git/ref/tags/v1.1.11` and `/git/tags/<sha>`; `gh api repos/crate-ci/committed/releases/latest`; `https://crates.io/api/v1/crates/committed`; local clones `~/c/py-launch-blueprint` at `b08bccf` (`lefthook.yml`, `commitlint.config.mjs`, `commitlint.dependabot.config.mjs`, `.github/workflows/commitlint.yml`) and `~/c/ts-launch-blueprint` at `cb1cbcb` (`.gitmessage`, `commitlint.config.mjs`, `tests/repo-hygiene.test.ts`); the installed `@commitlint/cli@21.0.2` (`~/.local/share/mise/installs/npm-commitlint-cli/21.0.2`, `@commitlint/ensure/lib/max-line-length.js`).
