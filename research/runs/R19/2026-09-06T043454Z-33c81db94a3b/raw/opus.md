# R19 — dependabot-config-shape (bundle, Focused) — Opus raw report

Engine: opus (`claude-opus-5`). Item R19, kind `bundle`, ledger rows F053 (Dependabot
ecosystems configured) and F054 (Dependabot update grouping strategy), both
`DIVERGENT`. All retrieval dates in this report are **2026-09-10** unless a line says
otherwise. Every figure names the endpoint that produced it.

### Landscape

**The category this item decides.** Not a library choice. The category is *the
declarative configuration surface of a hosted dependency-update service* — the schema
of `.github/dependabot.yml` as GitHub implements it today, plus the conventions
mainstream Rust projects apply within that schema. Nothing is compiled into the
template, nothing is linked, and no crate is added to `Cargo.toml`. That fact governs
the fitness gates below (see `### Principles and implementation`).

**Three-bin map of the Rust field.**

| Bin | Candidates found | Note |
|---|---|---|
| Built-in / first-party toolchain | `package-ecosystem: cargo` (Dependabot's own Cargo updater); `package-ecosystem: rust-toolchain` (Dependabot's own `rust-toolchain.toml` updater); `package-ecosystem: github-actions` | All three are GitHub-operated ecosystems, not third-party crates. `cargo` is the only one that reads `Cargo.toml`/`Cargo.lock`. |
| Established industry standard | The `groups` + `patterns`/`update-types` grouping convention; `cooldown`; `labels`; `commit-message.prefix` + `include: scope`; `open-pull-requests-limit`; `schedule.interval` | Each is a documented `dependabot.yml` key with observable adoption in the surveyed Rust projects (table below). |
| Up-and-comer | `multi-ecosystem-groups` (one PR spanning several ecosystems); `schedule.interval: cron` + `cronjob`; `exclude-paths`; `groups.<id>.group-by: dependency-name`; the platform-wide **default 3-day cooldown** | All are recent additions to the schema. The default cooldown is live on github.com; `multi-ecosystem-groups`, `cron` scheduling and `exclude-paths` are documented but carry version gates in the docs source, and `servo/servo` is the only surveyed Rust project using `cron` + `exclude-paths`. |

Bin membership is settled from the schema itself, not from familiarity: the
`package-ecosystem` table at
`https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference`
lists `Cargo | cargo | v1` and, behind the `dependabot-rust-toolchain-support` version
gate, `Rust toolchain | rust-toolchain | Not applicable` (read from the docs source,
`GET https://api.github.com/repos/github/docs/contents/content/code-security/reference/supply-chain-security/dependabot-options-reference.md`
with `Accept: application/vnd.github.raw`, retrieved 2026-09-10; the rendered page
truncated under conversion, so the source file is the citation of record).

**Authorities used, and why each is authoritative.**

| Source | Why it is an authority here |
|---|---|
| `github/docs` content source for the Dependabot options reference and `data/reusables/dependabot/supported-package-managers.md` | The maintainer's own normative specification of the schema this item writes. It is the only text that can settle "does `cargo` support key X". |
| `github/docs` `data/features/*.yml` | The same repository's machine-readable statement of *where* a documented key is live (`fpt`, `ghec`, `ghes`). It separates "documented" from "available on github.com", which prose cannot. |
| `dependabot/dependabot-core` source (MIT) | The running implementation behind the schema. Where the prose is silent — whether Cargo has a "development dependency group" at all — the code is decisive. |
| The Cargo book (`doc.rust-lang.org/cargo`) — Rust project publication | Normative for Cargo's version semantics, which is what makes a SemVer-shaped grouping filter behave differently in Rust than in npm or PyPI. |
| GitHub Changelog and the GitHub security blog (`github.blog`) | The vendor's dated announcements and its own configuration guidance; used for capability dates and for GitHub's stated recommendation on group count and cadence, not as a substitute for the schema. |
| The `.github/dependabot.yml` files of well-regarded Rust projects, read at `HEAD` | Practice evidence. A single project is a lead; the pattern across the set is the signal. |

**Well-regarded Rust projects surveyed, with the evidence that they are well regarded.**
Stars, `archived` and `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`,
retrieved 2026-09-10; configuration from
`GET https://raw.githubusercontent.com/<o>/<r>/HEAD/.github/dependabot.yml`, retrieved
2026-09-10. None of the repositories below is archived, and every one had been pushed
to within the eight days before retrieval, so each is a live project rather than a
historical artifact.

| Project | Stars | Last push | `cargo` entry | Cargo group shape | `cooldown` | `labels` | `commit-message` |
|---|---:|---|---|---|---|---|---|
| `sharkdp/bat` | 60398 | 2026-09-04 | yes | none (ungrouped, monthly) | no | no | no |
| `helix-editor/helix` | 46163 | 2026-09-08 | yes | one group, `update-types: [minor, patch]` | no | no | no |
| `nushell/nushell` | 40471 | 2026-09-10 | yes | two family groups (`polars*`, `uu*`); patches ignored | no | no | no |
| `pola-rs/polars` | 39702 | 2026-09-10 | yes | one group `patterns: ["*"]`; patches ignored | no | `['skip changelog']` | `prefix: build`, `prefix-development: chore(rust)` |
| `servo/servo` | 37950 | 2026-09-10 | yes | ~10 family groups; `cron` schedule; `exclude-paths` | `default-days: 7`, `include: "*"` | no | no |
| `tokio-rs/tokio` | 33110 | 2026-09-10 | **no** | inapplicable — `github-actions` only | no | no | no |
| `tokio-rs/axum` | 27074 | 2026-09-09 | **no** | inapplicable — `github-actions` only | no | no | no |
| `ratatui/ratatui` | 22543 | 2026-09-07 | yes | one group `patterns: ["*"]` | `default-days: 7` | no | no |
| `apache/datafusion` | 9302 | 2026-09-10 | yes | 3 groups incl. a `patterns:["*"]` catch-all with `exclude-patterns` | no | `[auto-dependencies]` | no |
| `crossbeam-rs/crossbeam` | 8569 | 2026-09-07 | yes | none (ungrouped) | `default-days: 14` | `labels: []` | `prefix: ''` |
| `cargo-bins/cargo-binstall` | 2864 | 2026-09-10 | yes | one group `patterns: ["*"]` | no | no | no |
| `paritytech/polkadot-sdk` | 2805 | 2026-09-10 | yes | one named group, `update-types: [minor, patch]` | no | two workflow labels | no |
| `rust-lang/docs.rs` | 1172 | 2026-09-10 | **no** | inapplicable — `github-actions` only | no | no | no |
| `rust-lang/cargo-bisect-rustc` | 205 | 2026-09-01 | yes | none; patches ignored | no | no | no |

Bot-choice context, one line, since the bot itself is out of scope: five widely-cited
Rust projects in the same tier carry a Renovate configuration and no `dependabot.yml`
— `rust-lang/rust` (117997 stars), `astral-sh/uv` (89684), `astral-sh/ruff` (49573),
`clap-rs/clap` (16697), `rustls/rustls` (7610) — each returning HTTP 200 for a
`renovate.json`/`renovate.json5` probe and HTTP 404 for both `.github/dependabot.yml`
and `.github/dependabot.yaml` (`GET https://raw.githubusercontent.com/<o>/<r>/HEAD/<path>`,
retrieved 2026-09-10). This is recorded as landscape fact only; F053/F054 configure
Dependabot and D-022(8) already rejected Renovate for ts.

**What the practice evidence says.** Of the 11 surveyed projects that declare a `cargo`
entry, **4** group everything with `patterns: ["*"]` (polars, ratatui, cargo-binstall,
and datafusion's catch-all tier), **2** use a SemVer filter `update-types: [minor,
patch]` (helix, polkadot-sdk), **3** define crate-family groups by name (servo,
nushell, datafusion's `arrow*`/`prost*` tiers), and **3** define no group at all (bat,
crossbeam, cargo-bisect-rustc). Nobody in the set reproduces py's *role* taxonomy
(runtime / dev-tools / lint-and-format / test) for Cargo. The three family-group users
are large monorepos with versioned crate families that must move together; that
condition does not exist in a three-crate template.

### Principles and implementation

**The shared requirement, its source, and the agreement level.** The principle behind
both source configurations is: *a repository's dependency and workflow-action versions
are refreshed automatically, on a fixed cadence, in a small number of reviewable pull
requests that are themselves subject to the repository's own commit and review
contract.* Source: py `.github/dependabot.yml` at pin `b08bccfb` (three ecosystems,
four named groups, `cooldown.default-days: 5`, `labels`, `commit-message` prefix
contract) and ts `.github/dependabot.yml` at pin `cb1cbcb2` (two ecosystems, one
`update-types: [minor, patch]` group per ecosystem, no cooldown, no labels, no
commit-message key), both read through their pins with
`git -C <repo> show <pin>:.github/dependabot.yml` (retrieved 2026-09-10).
`docs/port/DIVERGENCE-ANALYSIS.md:103` classifies R19 as class **A** with
`harmonize: partly` — "grouping-strategy shape can be one org value; the `cargo`
ecosystem key itself is Rust-specific". So the agreement level is **policy**: the
*shape* of the answer (how many groups, whether a cooldown exists, whether PRs are
labelled, whether commit messages conform) is one org value; the *ecosystem keys* and
any key whose availability is ecosystem-bound are necessarily per-repository.

**Essential behaviors any answer must produce.**
1. Every dependency source the repository actually has is declared, and nothing else.
2. Routine version updates arrive batched, on a fixed cadence, in a bounded number of
   open PRs.
3. A newly published release is not proposed the instant it appears (supply-chain
   delay).
4. Every Dependabot commit satisfies the repository's own commit-message contract
   (`commit-message-convention`, owned by R38).
5. Security updates are never delayed or batched behind the routine cadence.
6. A batched PR cannot land a change that violates a fixed parameter (here: the MSRV
   policy) without CI catching it.

**Observable acceptance criteria** (each is checkable on the P03 template; see
`### Validation strategy` for the commands, and note that all of them are *proposed*,
none executed — the template does not exist):
- `.github/dependabot.yml` parses under `version: 2` and GitHub's own validator (the
  repository's **Insights → Dependency graph → Dependabot** tab reports "Last checked"
  per entry and no configuration error).
- Exactly two `updates:` entries exist, `cargo` and `github-actions`, each with
  `directory: "/"`.
- Every opened Dependabot PR title begins `chore(deps): ` and passes the F157 CI
  commit-message re-run under `committed.bot.toml`.
- At most 5 version-update PRs are open per ecosystem at any time.
- A crate published fewer than 5 days ago is not proposed.
- A grouped PR whose bump raises the required Rust version fails the MSRV job in CI
  rather than merging.

**What must agree across py, ts and rs, and what may vary.**

| Must agree (one org value) | May vary (justified ecosystem difference) |
|---|---|
| Weekly cadence, one day (`monday`) | Which ecosystem keys are declared |
| A cooldown exists and its length (5 days) | Whether `cooldown.semver-*-days` is even available |
| Bounded open PRs (`open-pull-requests-limit: 5`) | The grouping *predicate* (`patterns` vs `update-types`) |
| PRs carry a `dependencies` label plus an ecosystem label | The ecosystem label's literal string |
| Every commit conforms to the Conventional-Commits contract | Whether a separate development-dependency prefix exists |
| Routine updates are batched into few PRs | How many groups it takes to achieve that |

**The architectural alternatives, compared before any key was chosen.** Three shapes
can satisfy behaviors 1–6, and the choice between them is the substance of F054:

| Alternative | Mechanism | Evidence for | Why it is or is not chosen |
|---|---|---|---|
| **A. Role taxonomy (py's shape)** | Several named groups whose membership is a list of dependency *names* (`runtime`, `dev-tools`, `lint-and-format`, `test`) | py at pin `b08bccfb`; no Cargo user in the surveyed set | **Rejected for Cargo.** Two independent reasons, both measured below: Cargo has no development-dependency concept in Dependabot, so the split can only be expressed as name patterns; and in a *template* the dependency names are the first thing a consumer replaces, so a name-keyed group list is stale on day one. |
| **B. SemVer filter (ts's shape)** | One group per ecosystem, `update-types: [minor, patch]` | ts at pin `cb1cbcb2`; helix (46163 stars), polkadot-sdk (2805) | **Rejected for the `cargo` entry, retained in spirit for its simplicity.** Dependabot's `minor` is plain SemVer; Cargo's compatibility rule is not. A `0.1.0 → 0.2.0` bump is classified `minor` and lands inside a PR the config presents as low-risk, while Cargo treats it as incompatible. It also leaves every major bump ungrouped, so the noise the group was meant to remove reappears as individual PRs. |
| **C. Catch-all group (selected)** | One group per ecosystem, `patterns: ["*"]`, `applies-to: version-updates` | polars (39702), ratatui (22543), cargo-binstall (2864), datafusion's catch-all tier (9302); GitHub's own written advice | **Selected.** It makes no risk claim it cannot honour, covers majors as well as minors, contains zero repository-specific strings, and is the shape GitHub itself recommends as the starting point. |

**The measurement that decides A.** `dependabot-core` registers Cargo's production
check as a constant true:

```ruby
Dependabot::Dependency.register_production_check("cargo", ->(_) { true })
```

(`cargo/lib/dependabot/cargo.rb`, read at
`GET https://raw.githubusercontent.com/dependabot/dependabot-core/main/cargo/lib/dependabot/cargo.rb`,
retrieved 2026-09-10). Every Cargo dependency is therefore "production" to Dependabot,
whatever table it sits in. The parser confirms the tables are read but not
distinguished downstream: `DEPENDENCY_TYPES = %w(dependencies dev-dependencies
build-dependencies)` and `build_dependency(name, requirement, type, file)` records
`groups: [type]`
(`cargo/lib/dependabot/cargo/file_parser.rb`, same endpoint pattern, retrieved
2026-09-10), but the registered check ignores those groups. Three documented keys
follow from this and all three are **unavailable or inert for `cargo`**:
`groups.<id>.dependency-type` is "Supported by: `bundler`, `composer`, `mix`, `maven`,
`npm`, and `pip`"; `commit-message.prefix-development` is "Supported by: `bundler`,
`composer`, `mix`, `maven`, `npm`, `pip`, and `uv`"; and `commit-message.include:
scope`, which appends "`deps` or `deps-dev`", can only ever append `deps` for Cargo.
(Both support lists quoted verbatim from the options-reference source, retrieved
2026-09-10.) py's runtime-versus-dev-tools distinction is thus **a capability the
Cargo ecosystem does not have**, not drift and not a preference — the one place it
could be reconstructed is a hand-maintained name-pattern list.

**The measurement that decides B.** The Cargo book states the compatibility rule this
way: caret requirements "allow SemVer compatible updates ... versions are considered
compatible if their left-most non-zero major/minor/patch component is the same", with
`0.2.3 := >=0.2.3, <0.3.0` and `1.2.3 := >=1.2.3, <2.0.0`, and "`log = "^1.2.3"` is
exactly equivalent to `log = "1.2.3"`"
(`https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html`, retrieved
2026-09-10). Dependabot has no matching notion; the open feature request that asks for
one spells out the consequence: "a version upgrade from v0.1.0 to v0.2.0 is considered
'incompatible' even though, by typical SemVer standards, it is minor", requesting
`cargo-compatible`/`cargo-incompatible` values for `groups.*.update-types`
(`dependabot/dependabot-core` issue **#9681**, state `open`, created `2024-05-06`,
last updated `2026-08-04`, 2 comments —
`GET https://api.github.com/repos/dependabot/dependabot-core/issues/9681`, retrieved
2026-09-10). Pre-1.0 crates are ordinary in a Rust dependency tree, so this is not an
edge case; ts's filter would systematically mislabel the riskiest routine bumps in the
`cargo` entry. The same filter is harmless on `github-actions`, whose versions are tags
with no 0.x convention, but there is no reason to keep it there once the catch-all is
the house shape.

**GitHub's own guidance agrees with C.** "A single wildcard group is the simplest
starting point. If you later find you want, say, patch-level and major-version updates
handled differently, break the wildcard into more targeted named groups", and, on the
PR limit, that it "caps the flood at 10 open pull requests, but it doesn't stop the
flood"; the same post says "Don't fold security fixes into this cadence"
(`https://github.blog/security/supply-chain-security/tame-dependabot-group-your-updates-slow-the-cadence-keep-security-fast/`,
retrieved 2026-09-10).

**The Rust-specific risk that no Dependabot key addresses: MSRV.** The fixed parameter
`msrv-policy` requires `rust-version` in `Cargo.toml` and an MSRV job in CI.
Dependabot does not read `rust-version`: the request to do so,
"Take `rust-version` into account when updating lock file / manifest", is **open**,
created `2022-07-26`, last updated `2026-01-05`, 7 comments, 7 reactions
(`GET https://api.github.com/repos/dependabot/dependabot-core/issues/5423`, retrieved
2026-09-10). Cargo itself gained MSRV-aware resolution — resolver `"3"`, which requires
Rust 1.84+, changes `resolver.incompatible-rust-versions` from `allow` to `fallback`,
and edition `"2024"` defaults to resolver `"3"`
(`https://doc.rust-lang.org/cargo/reference/resolver.html`, retrieved 2026-09-10) — so
the template's fixed `rust-edition = 2024` does put the resolver in the MSRV-aware
mode. That does **not** make Dependabot MSRV-aware: Dependabot's Cargo update checker
selects a target version and then asks Cargo to resolve, so an MSRV-raising bump can
still be proposed. **The guard is the CI MSRV job, and this item does not weaken it.**
The operational consequence belongs in the template's documentation: a grouped PR that
fails the MSRV job is resolved by adding an `ignore` entry for the offending crate,
not by relaxing the job.

**The one key whose Cargo default is already correct.** `versioning-strategy` is
"Supported by: `bundler`, `cargo`, `composer`, `helm`, `mix`, `npm`, `pip`, `pub`, and
`uv`" (options-reference source, retrieved 2026-09-10), but Cargo accepts only three of
the five documented values —
`ALLOWED_UPDATE_STRATEGIES = [LockfileOnly, BumpVersions, BumpVersionsIfNecessary]`
(`cargo/lib/dependabot/cargo/update_checker/requirements_updater.rb`, retrieved
2026-09-10), i.e. `lockfile-only`, `increase`, `increase-if-necessary`; **`widen` is
not accepted for Cargo** despite the generic documentation. The default, when the key
is absent, is already the right one, and the implementation says why in a comment:

```ruby
# Cargo resolves to the newest compatible version and a bare version is a
# caret-equivalent (compatible) requirement, so only raise the requirement
# when it doesn't already allow the new version. Avoids needless churn and
# MSRV bumps.
RequirementsUpdateStrategy::BumpVersionsIfNecessary
```

(`cargo/lib/dependabot/cargo/update_checker.rb`, retrieved 2026-09-10.) So
`increase-if-necessary` is what a Cargo entry gets whether or not it says so, and
`ratatui`'s explicit declaration of it restates today's default.

**Maintained reference implementation, and how the whole example composes.** The
maintained implementation of the schema is `dependabot/dependabot-core` — MIT,
**5762** stars, `archived: false`, `pushed_at 2026-09-10T14:55:37Z`
(`GET https://api.github.com/repos/dependabot/dependabot-core`) with **1217** open
issues (`GET https://api.github.com/search/issues?q=repo:dependabot/dependabot-core+is:issue+is:open`,
`total_count`), both retrieved 2026-09-10; maintenance state **active** (same-day push,
not archived, a first-party GitHub repository backing a hosted service). The closest
maintained *configuration* reference for the recommended shape is
`ratatui/ratatui`'s `.github/dependabot.yml` (22543 stars, pushed 2026-09-07): two
entries, catch-all group per entry, a cooldown on both, a bounded PR limit. The full
composition in the template is: one file, `.github/dependabot.yml`; the `cargo` entry
reads the workspace-root `Cargo.toml` and `Cargo.lock`; the `github-actions` entry
reads `.github/workflows/*`; each opens at most 5 PRs a week whose commit subjects are
`chore(deps): …`; CI (R11's job structure, R38's F157 re-run, the MSRV job) is what
decides whether any of them merges. **Performance is not a meaningful axis for this
item** — nothing runs on a developer machine or in the template's build; the cost of a
wrong answer is measured in reviewer attention per week, not latency, and the
instrumentation for it is the count of open Dependabot PRs, observable on the
repository's pull-request list.

**One workspace fact that settles the ecosystem entry's `directory`.** The Cargo file
parser reads `[workspace.dependencies]` at the workspace root and *skips* members that
inherit (`next if requirement.is_a?(Hash) && requirement["workspace"] == true`), while
`check_rust_workspace_root` raises "This project is part of a Rust workspace but is not
the workspace root" when pointed at a member
(`cargo/lib/dependabot/cargo/file_parser.rb`, retrieved 2026-09-10). For a CLI +
library + web-service workspace this means one entry with `directory: "/"` covers all
three crates provided shared versions live in `[workspace.dependencies]` — and that a
per-crate entry would be an error, not merely redundant.

No `BASELINE-REVIEW:` finding is raised. F053 and F054 are `DIVERGENT` rows; neither
appears in `docs/port/BASELINE-REVIEW.md` (`grep -n "F053\|F054\|Dependabot"` over that
file returns nothing, run 2026-09-10), so there is no `COMMON → REUSE` or `ADOPT`
baseline for this item to challenge.

### Recommendation

**One stack: a two-entry `.github/dependabot.yml` — `cargo` and `github-actions` — each
with a single catch-all version-update group, a 5-day cooldown, a bounded PR limit,
default-valued labels, and one Conventional-Commits prefix contract; py's role
taxonomy and dev-dependency prefix are not ported, because the Cargo ecosystem cannot
express them; ts's `update-types` filter is not ported, because Dependabot's `minor`
does not mean Cargo's compatible.** The proposed file, in full:

```yaml
version: 2
updates:
  # Rust dependencies: workspace root Cargo.toml + Cargo.lock.
  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    cooldown:
      default-days: 5
    open-pull-requests-limit: 5
    labels: ["dependencies", "rust"]
    commit-message:
      prefix: "chore"
      include: "scope"
    versioning-strategy: "increase-if-necessary"
    groups:
      cargo:
        applies-to: version-updates
        patterns: ["*"]

  # Actions referenced by .github/workflows/*.
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    cooldown:
      default-days: 5
    open-pull-requests-limit: 5
    labels: ["dependencies", "github_actions"]
    commit-message:
      prefix: "chore"
      include: "scope"
    groups:
      github-actions:
        applies-to: version-updates
        patterns: ["*"]
```

Three keys are deliberately absent and their absence is load-bearing:
`prefix-development` (unsupported for `cargo`, inert if copied), `dependency-type`
inside `groups` (unsupported for `cargo`), and `versioning-strategy` on the
`github-actions` entry (not in that key's supported-ecosystem list).

### Members

#### Ecosystem declaration set (`package-ecosystem`)

##### Landscape
Built-in/first-party bin only: the candidate values are the ecosystem keys GitHub
operates. Three are in scope for this template — `cargo`, `github-actions`,
`rust-toolchain` — and two more become candidates only if other open items ship their
artifacts (`docker` for R51's container image, `devcontainers` for R44). The Rust field
splits cleanly: 11 of the 14 surveyed projects declare `cargo`, 14 of 14 declare
`github-actions`, and **0 of 14** declare `rust-toolchain`
(`GET https://raw.githubusercontent.com/<o>/<r>/HEAD/.github/dependabot.yml`, retrieved
2026-09-10).

##### Principles and implementation
Principle: every dependency source the repository actually has is declared, and nothing
else — a declared ecosystem with no file to read is noise, and an undeclared one is an
unpatched surface. py declares three (`uv`, `github-actions`, `npm`) because it has
three manifests; ts declares two. rs has exactly two manifest surfaces at P03:
`Cargo.toml`/`Cargo.lock` and `.github/workflows/*`. Acceptance: the Dependabot tab
lists two entries, each with a "Last checked" timestamp and no error.

##### Dominant choice
`cargo` + `github-actions`. Every surveyed project that has Rust code and GitHub
workflows declares exactly this pair or a superset; the three `github-actions`-only
projects (tokio 33110 stars, axum 27074, docs.rs 1172) are the only deviation and it is
a deliberate opt-out of Cargo updates, not a different ecosystem list.

##### Qualified shortlist
`cargo` (required — it is the only key that reads `Cargo.toml`/`Cargo.lock`);
`github-actions` (required by R20's pinning policy, which relies on Dependabot to
refresh SHA-pinned actions); `rust-toolchain` (available, evaluated, not adopted —
see below); `docker` and `devcontainers` (conditional on R51 and R44 shipping their
files; each would add one entry with the same body shape).

##### Excluded by gate
None. Gate 1 (licence) is satisfied by the only implementation involved,
`dependabot/dependabot-core`, MIT
(`GET https://api.github.com/repos/dependabot/dependabot-core`, `license.spdx_id`,
retrieved 2026-09-10), and it is a hosted service, never linked into the template.
Gates 2, 3, 4, 5 and 6 are **inapplicable**: no crate is added to `Cargo.toml`, so
there is no MSRV to satisfy, no RustSec page to read, no `unsafe` posture, no build on
`ubuntu-latest`/`macos-latest`, no feature flags or async-runtime coupling, and no
binary-size or compile-time cost. The runner OS matrix is untouched because Dependabot
runs on GitHub's infrastructure, not in the template's CI matrix.

##### Up-and-comers
`rust-toolchain`, live on github.com (`versions: fpt: '*'`, `ghec: '*'`,
`ghes: '>= 3.20'` —
`GET https://api.github.com/repos/github/docs/contents/data/features/dependabot-rust-toolchain-support.yml`,
retrieved 2026-09-10). It "supports automatic updates for Rust toolchain versions
defined in `rust-toolchain.toml` and `rust-toolchain` files" for "versioned toolchains
such as `channel = "1.xx.yy"` and `channel = "1.xx"`" and dated nightly/beta channels
(`data/reusables/dependabot/supported-package-managers.md`, retrieved 2026-09-10).
Also `multi-ecosystem-groups`, which could merge the two entries' PRs into one; not
adopted, because two PRs a week is already the target and merging them would couple a
workflow-action failure to a Rust dependency failure in one revert.

##### Fit for this template
`cargo` fits exactly once: the workspace root. The parser reads
`[workspace.dependencies]` and skips `workspace = true` members, and
`check_rust_workspace_root` errors on a member directory
(`cargo/lib/dependabot/cargo/file_parser.rb`, retrieved 2026-09-10) — so one
`directory: "/"` covers CLI, library and web-service crates, and a per-crate entry
would be wrong. `github-actions` fits because R20's pinning policy makes Dependabot the
mechanism that refreshes SHA-pinned actions; without this entry the pins rot silently.
`rust-toolchain` does **not** fit today: R42 recommends committing a
`rust-toolchain.toml` whose `channel` value is R27's to set and R27 is `open`; R42's own
scratch fixtures and its reference implementation (`cargo-binstall`) use
`channel = "stable"`, which Dependabot's rust-toolchain updater has nothing to update.

##### Recommendation
Declare exactly two entries, `cargo` and `github-actions`, both `directory: "/"`. Do
not declare `rust-toolchain`. Add `docker` and/or `devcontainers` only if and when R51
and R44 ship those files, using the same entry body.

##### Ranked runner-up
(1) The same two entries plus `rust-toolchain` — adopt only if R27 sets a numeric
`channel`; (2) `cargo` only, following tokio/axum/docs.rs — rejected, because it strands
R20's SHA pins; (3) three entries with `docker` pre-declared — rejected, because a
declared ecosystem with no manifest produces a configuration error, not a no-op.

##### Tradeoffs
Two entries mean two PR streams rather than one. `directory` rather than `directories`
forgoes globbing the template does not need. Declining `rust-toolchain` means a future
numeric toolchain pin ages unattended until the entry is added — a documented
re-verify trigger rather than a silent gap.

##### Parameters
Owns nothing. Assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor
versions, raised only in a minor release, declared as rust-version in Cargo.toml and
tested in CI`, `target-os-matrix = ubuntu-latest, macos-latest`,
`license = MIT OR Apache-2.0` (all fixed, `docs/port/PARAMETERS.md`). No `CONFLICT:`
line.

##### Migration implications
Creates `.github/dependabot.yml` with two `updates:` entries. Requires that shared
dependency versions live in the workspace-root `[workspace.dependencies]` table for
one entry to cover three crates — a constraint on P03's `Cargo.toml` layout, stated
here because it is invisible from the config file itself.

##### Validation strategy
Proposed, not executed: after P03 creates the file, confirm the repository's
**Insights → Dependency graph → Dependabot** tab lists exactly two entries with a
"Last checked" time and no error banner; and confirm that a PR opened by the `cargo`
entry touches the root `Cargo.toml`/`Cargo.lock` and no member manifest.

##### Confidence & re-verify trigger
High for the two-entry set. Re-verify when: R27 fixes a numeric `rust-toolchain.toml`
channel (then add `rust-toolchain`); R51 or R44 lands a Dockerfile or devcontainer
(then add that ecosystem); or GitHub adds a Cargo-workspace-aware `directories`
behavior.

##### Sources
`git -C ~/c/py-launch-blueprint show b08bccfb:.github/dependabot.yml`;
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:.github/dependabot.yml` (both retrieved
2026-09-10).
`https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference`
(`package-ecosystem` table), read from
`GET https://api.github.com/repos/github/docs/contents/content/code-security/reference/supply-chain-security/dependabot-options-reference.md`;
`.../contents/data/reusables/dependabot/supported-package-managers.md`;
`.../contents/data/features/dependabot-rust-toolchain-support.yml`;
`https://raw.githubusercontent.com/dependabot/dependabot-core/main/cargo/lib/dependabot/cargo/file_parser.rb`;
`GET https://api.github.com/repos/dependabot/dependabot-core`;
`GET https://raw.githubusercontent.com/<o>/<r>/HEAD/.github/dependabot.yml` for the 14
surveyed projects; `research/topics/42-dev-toolchain-provisioning/DECISION.md:18`. All
retrieved 2026-09-10.

#### Update grouping strategy (`groups`)

##### Landscape
Established-standard bin: `groups` with the sub-keys `IDENTIFIER`, `applies-to`,
`dependency-type`, `patterns`, `exclude-patterns`, `update-types`, and (behind the
`dependabot-updates-group-by` gate) `group-by`. The three grouping *predicates*
available to a Cargo entry are name patterns, SemVer `update-types`, and the pair of
`applies-to` values; `dependency-type` is not among them. Up-and-comer:
`group-by: dependency-name` for cross-directory grouping in a monorepo, which this
single-directory template cannot use.

##### Principles and implementation
Principle: routine version updates arrive batched, in a bounded number of PRs, and the
batching must not assert a risk level the ecosystem's own semantics contradict.
Dependabot's default is "a single pull request for each dependency"; when `groups` is
defined, "all updates for dependencies that match a rule are combined in a single pull
request" and "any outdated dependencies that do not match a rule are updated in
individual pull requests" (options-reference source, retrieved 2026-09-10). That last
sentence is the hinge: a *partial* predicate does not reduce PR count, it re-partitions
it. Acceptance: in a steady week the repository shows at most one open `cargo` PR and
one open `github-actions` PR from routine updates.

##### Dominant choice
A single catch-all group per ecosystem, `patterns: ["*"]`. Four of the 11 surveyed
Cargo entries use it (polars 39702 stars, ratatui 22543, cargo-binstall 2864, and
datafusion's `all-other-cargo-deps` tier 9302), and GitHub's own guidance names it the
starting point: "A single wildcard group is the simplest starting point"
(`https://github.blog/security/supply-chain-security/tame-dependabot-group-your-updates-slow-the-cadence-keep-security-fast/`,
retrieved 2026-09-10).

##### Qualified shortlist
(a) Catch-all `patterns: ["*"]`; (b) SemVer filter `update-types: [minor, patch]` (ts's
shape; helix, polkadot-sdk); (c) name-keyed family groups (servo, nushell, datafusion's
`arrow*`/`prost*` tiers); (d) no groups at all (bat, crossbeam, cargo-bisect-rustc);
(e) py's role taxonomy expressed as name patterns.

##### Excluded by gate
No candidate is excluded by a fitness gate — gates 2–6 are **inapplicable** to a YAML
key (no crate, no MSRV, no advisory page, no platform build, no features, no compile
cost), and gate 1 is satisfied once by MIT-licensed `dependabot-core`. Candidate (e) is
excluded by **capability**, which is a stronger exclusion than a gate:
`groups.<id>.dependency-type` is "Supported by: `bundler`, `composer`, `mix`, `maven`,
`npm`, and `pip`" (options-reference source, retrieved 2026-09-10), and Cargo's
production check is `->(_) { true }`
(`cargo/lib/dependabot/cargo.rb`, retrieved 2026-09-10), so no dev/runtime split exists
to group by. Candidate (b) is excluded by **semantics**: issue #9681 (open,
created 2024-05-06, updated 2026-08-04) records that Dependabot's `minor` classifies a
`0.1.0 → 0.2.0` bump that Cargo treats as incompatible
(`GET https://api.github.com/repos/dependabot/dependabot-core/issues/9681`, retrieved
2026-09-10; rule at
`https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html`, retrieved
2026-09-10).

##### Up-and-comers
`applies-to: security-updates` as a second group — deliberately not used: GitHub writes
"Don't fold security fixes into this cadence. Dependabot security updates are triggered
by vulnerability disclosures, not your version-update schedule" (same blog post,
retrieved 2026-09-10), and R13 owns vulnerability scanning. `group-by: dependency-name`
— inapplicable to a single-directory workspace.

##### Fit for this template
Decisive and template-specific: a template's dependency *names* are the first thing a
consumer changes. py's four groups name 20 concrete packages
(`click`, `pydantic`, `ruff`, `pytest*`, …) at py `.github/dependabot.yml` pin
`b08bccfb`; the Rust equivalent would name `clap`, `serde`, `tokio`, `axum` and so on,
and the day a consumer swaps `clap` for `argh` or drops the web crate, the group list
silently stops matching and the "ungrouped dependencies are updated in individual pull
requests" rule quietly restores the noise. A `patterns: ["*"]` group contains no
repository-specific string and therefore cannot rot. The three surveyed projects that
*do* keep name-keyed families (servo, nushell, datafusion) each have a versioned crate
family — `objc2*`, `polars-*`, `arrow*` — that must move in lockstep; a three-crate
template has none.

##### Recommendation
One group per entry, `patterns: ["*"]`, with `applies-to: version-updates` written
explicitly (it is the documented default — "When undefined, defaults to version
updates" — so the key is documentation, not behavior). Group identifiers `cargo` and
`github-actions`. No `update-types` filter, no `exclude-patterns`, no second group.

##### Ranked runner-up
(1) Two Cargo groups split by `update-types`: `[patch]` in one and `[minor, major]` in
the other — an honest split that does not misuse the word "minor", worth adopting only
if a single weekly PR proves too large to review; (2) ts's `[minor, patch]` filter —
rejected on the 0.x semantics above; (3) no groups — rejected, it is the noise this
item exists to remove.

##### Tradeoffs
One PR containing a major bump alongside patches is harder to bisect than one PR per
crate, and reverting it reverts everything in it. That cost is paid deliberately: CI is
the gate, the PR is weekly, and `open-pull-requests-limit: 5` leaves room for the
follow-up PRs Dependabot opens when part of a group is unmergeable. The grouped title
also carries the group identifier — `chore(deps): bump the cargo group with N updates`
is 48 columns for the `cargo` identifier and 57 for `github-actions`, against R38's
50-column `subject_length`; under F152's soft-line measurement (to the last space) the
longer one measures 49, and in CI F156 relaxes the width rules for `dependabot[bot]`
PRs anyway. Keep group identifiers short and the interaction stays invisible.

##### Parameters
Owns nothing. Assumes `commit-message-convention` (researched, R38) for the header
width interaction described above, and `ci-job-structure` (researched, R11) for which
job a grouped PR must pass. No `CONFLICT:` line.

##### Migration implications
Adds a `groups:` block of four lines to each of the two entries in
`.github/dependabot.yml`. Nothing else in the template changes. Not ported from py:
the four named groups and their 20 package patterns. Not ported from ts: the
`update-types` filter.

##### Validation strategy
Proposed, not executed: over the first four weeks after P03, count open Dependabot PRs
on Monday afternoon; expect ≤ 2 from routine updates. Deliberately falsifiable check —
introduce a dependency on a `0.x` crate, wait for a `0.x → 0.(x+1)` release, and
confirm the bump appears inside the catch-all group's PR (it would have been labelled
`minor` and silently batched under ts's filter).

##### Confidence & re-verify trigger
High. Re-verify if Dependabot ships the `cargo-compatible`/`cargo-incompatible`
`update-types` values requested in #9681 — that would make an honest SemVer-filtered
split possible and would reopen the choice between (a) and the runner-up (1).

##### Sources
Options-reference source (`groups`, `dependency-type` support list, "any outdated
dependencies that do not match a rule are updated in individual pull requests",
`applies-to` default) via
`GET https://api.github.com/repos/github/docs/contents/content/code-security/reference/supply-chain-security/dependabot-options-reference.md`;
`https://raw.githubusercontent.com/dependabot/dependabot-core/main/cargo/lib/dependabot/cargo.rb`;
`GET https://api.github.com/repos/dependabot/dependabot-core/issues/9681`;
`https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html`;
`https://github.blog/security/supply-chain-security/tame-dependabot-group-your-updates-slow-the-cadence-keep-security-fast/`;
the 14 surveyed `dependabot.yml` files; py and ts at their pins;
`research/topics/38-commit-message-linter/DECISION.md` (F152, F156). All retrieved
2026-09-10.

#### Cooldown (`cooldown`)

##### Landscape
Established-standard bin, recently promoted: `cooldown` with `default-days`,
`semver-major-days`, `semver-minor-days`, `semver-patch-days`, `include` and `exclude`
(each list up to 150 items, wildcards allowed). Up-and-comer within it: the
platform-wide **default** 3-day cooldown that now applies with no configuration at all.
Practice in the Rust field is thin but present: 3 of 11 surveyed Cargo entries set it —
servo (`default-days: 7`, `include: "*"`), ratatui (`7`), crossbeam (`14`, with the
maintainer's own caveat "Unless dependencies are pinned/locked, the effect is limited").

##### Principles and implementation
Principle: a newly published release is not proposed the instant it appears, because a
compromised or broken release is most likely to be caught in its first days. GitHub
states the mechanism and the exemption: the cooldown "applies only to version updates.
Security updates still open immediately, so critical fixes are never delayed"
(`https://github.blog/changelog/2026-07-14-dependabot-version-updates-introduce-default-package-cooldown/`,
retrieved 2026-09-10). Acceptance: a crate published fewer than 5 days ago does not
appear in a version-update PR; a security advisory published today still opens a PR
today.

##### Dominant choice
`cooldown.default-days`, and now the platform default: "Apply a **default cooldown
period of 3 days** to version updates, even when `cooldown` is not configured"
(options-reference source, retrieved 2026-09-10), live on github.com per
`versions: fpt: '*'`, `ghec: '*'`, `ghes: '>3.21'`
(`GET https://api.github.com/repos/github/docs/contents/data/features/dependabot-cooldown-default-days.yml`,
retrieved 2026-09-10). The key itself is GA with `fpt: '*'`, `ghec: '*'`, `ghes:
'>3.18'` (`.../dependabot-option-cooldown.yml`, retrieved 2026-09-10).

##### Qualified shortlist
(a) `default-days: 5` on both entries — py's recorded value; (b) omit the key and take
the platform's 3 days; (c) `default-days` plus per-level `semver-*-days`, e.g. a longer
window on majors; (d) `include`/`exclude` lists to exempt named crates.

##### Excluded by gate
None; gates 2–6 **inapplicable** for the reasons given under the first member, gate 1
satisfied by MIT `dependabot-core`. One candidate is constrained by capability rather
than excluded: the per-level knobs are available to Cargo but **not** to
`github-actions`. The support table marks Cargo "Default days supported ✓ / SemVer-bump
days supported ✓" and GitHub Actions "✓ / ✗" (options-reference source, retrieved
2026-09-10), so any `semver-*-days` value can only ever be set on one of the two
entries — an asymmetry that argues for keeping both entries on `default-days` alone.

##### Up-and-comers
`cooldown.include: "*"` (servo's shape) — redundant with `default-days`, which already
covers dependencies "without specific rules". The 3-day platform default is itself the
newest element and changes the meaning of omitting the key: omission is now a choice of
3 days, not a choice of none.

##### Fit for this template
A template is copied by people who will not read this file for months. An explicit
`default-days: 5` states the policy where a reader will find it and pins it against a
future change to the platform default; it also keeps one org value across py (which
already sets 5) and rs, with ts to follow. Five days over three is a deliberate,
modest margin, matching the org's recorded choice rather than inventing a new number;
crossbeam's caveat does not apply, because a Rust template commits `Cargo.lock`, so the
delay genuinely governs what a contributor resolves.

##### Recommendation
`cooldown: { default-days: 5 }` on both entries. No `semver-*-days`, no `include`, no
`exclude`.

##### Ranked runner-up
(1) Omit the key entirely and inherit 3 days — fewer lines, weaker documentation, and
it silently diverges from py's 5; (2) `default-days: 5` on `cargo` with
`semver-major-days: 14` — defensible once the template has real dependencies, rejected
now as tuning without evidence; (3) crossbeam's 14 days — rejected, it delays routine
patches beyond a weekly cadence's usefulness.

##### Tradeoffs
Five days delays a genuinely good release by up to five days and, combined with a
weekly Monday schedule, can push a Friday release into the following week's PR.
Security updates are unaffected by construction. The cost is bounded and the benefit —
not being the first repository to merge a compromised release — is exactly the risk
this key exists for.

##### Parameters
Owns nothing; assumes nothing. No `CONFLICT:` line.

##### Migration implications
Adds two lines to each entry. Cross-repo follow-on rationale: ts should gain the same
`cooldown: { default-days: 5 }` block on both its entries, which is the one place ts's
current file is missing a policy py already has.

##### Validation strategy
Proposed, not executed: pick a crate in the template's tree, note a release published
within the last 5 days on `https://crates.io/api/v1/crates/<name>/versions`, and
confirm no version-update PR proposes it until the sixth day. This check was **not
run** — no template and no live Dependabot installation exists at P02.

##### Confidence & re-verify trigger
High for the value; the mechanism is documented and dated. Re-verify if GitHub changes
the platform default again (the changelog entry is dated 2026-07-14), or if `ghes`
support matters to a consumer on an older Enterprise Server (`> 3.21` for the default,
`> 3.18` for the key).

##### Sources
Options-reference source (`cooldown` sub-keys, the support table, the default-days
paragraph);
`GET https://api.github.com/repos/github/docs/contents/data/features/dependabot-option-cooldown.yml`
and `.../dependabot-cooldown-default-days.yml`;
`https://github.blog/changelog/2026-07-14-dependabot-version-updates-introduce-default-package-cooldown/`;
`https://raw.githubusercontent.com/servo/servo/HEAD/.github/dependabot.yml`,
`.../ratatui/ratatui/...`, `.../crossbeam-rs/crossbeam/...`; py at pin `b08bccfb`. All
retrieved 2026-09-10.

#### Labels (`labels`)

##### Landscape
Established-standard bin, and the only key in this stack whose *default* is
ecosystem-specific rather than universal. `dependabot-core` registers a label per
ecosystem: `register_label_details("cargo", name: "rust", colour: "000000")`
(`cargo/lib/dependabot/cargo.rb`) and
`register_label_details("github_actions", name: "github_actions", description: "Pull
requests that update GitHub Actions code", colour: "000000")`
(`github_actions/lib/dependabot/github_actions.rb`), on top of
`DEFAULT_DEPENDENCIES_LABEL = "dependencies"`
(`common/lib/dependabot/pull_request_creator/labeler.rb`) — all three read at
`https://raw.githubusercontent.com/dependabot/dependabot-core/main/<path>`, retrieved
2026-09-10. Practice is sparse: 3 of 11 surveyed Cargo entries set `labels`
(datafusion `[auto-dependencies]`, polars `['skip changelog']`, crossbeam `labels: []`
to switch them off), and the remaining 8 take the defaults.

##### Principles and implementation
Principle: a Dependabot PR is identifiable as such, and by which surface it touches,
without opening it — so a reviewer, a filter, or a required-check rule can act on it.
Both source repos honour the principle differently: py declares
`["dependencies", "<ecosystem>"]` per entry, ts declares nothing and takes the
defaults, which produce the same two-label outcome. Acceptance: every Dependabot PR
carries `dependencies` plus exactly one ecosystem label, and both labels exist in the
repository.

##### Dominant choice
The defaults. "All pull requests have a `dependencies` label. If you define more than
one package manager, an additional label for the ecosystem or language is added",
and Dependabot "creates these default labels automatically, as necessary in your
repository" (options-reference source, retrieved 2026-09-10). Custom labels do not get
that treatment: "If any of these labels is not defined in the repository, it is
ignored."

##### Qualified shortlist
(a) Declare `["dependencies", "rust"]` / `["dependencies", "github_actions"]` — values
identical to the defaults; (b) omit `labels` entirely; (c) py's literal strings
`["dependencies", "python"|"github-actions"]` transposed to `"rust"`/`"github-actions"`;
(d) add a third, template-specific label.

##### Excluded by gate
None; gates 2–6 **inapplicable** (a YAML list adds no crate, no MSRV, no advisory, no
platform build, no features, no compile cost), gate 1 satisfied by MIT
`dependabot-core`. Candidate (c) is excluded by an observable defect rather than a
gate: the default GitHub Actions label is the **underscored** `github_actions`, so a
declared `github-actions` (hyphen) is a custom label that Dependabot will not create
and that "is ignored" if the repository lacks it. py's file at pin `b08bccfb` declares
exactly that hyphenated string; unless py's repository defines the label by hand, py's
GitHub Actions PRs carry only `dependencies`. Recorded as a cross-repo finding for the
follow-on py/ts project, not as a change to py.

##### Up-and-comers
None. `labels` is a stable key; the adjacent movement is that "SemVer labels (if
present in the repository) will still be applied in addition to any custom labels
defined" (options-reference source, retrieved 2026-09-10), which means a repository
that defines `major`/`minor`/`patch` labels gets update-type labelling for free — worth
noting for P03, not worth configuring here.

##### Fit for this template
A template must not depend on repository state a consumer's fork will not have. That
rules out any label string Dependabot does not create on its own. Choosing values that
are *identical to the defaults* makes the outcome the same whether the "must already
exist" rule bites or not — the failure mode becomes unobservable — while still stating
the taxonomy in the file where a consumer edits it. The ecosystem label also differs
from py's by necessity: the Rust default is `rust`, not `cargo`.

##### Recommendation
`labels: ["dependencies", "rust"]` on the `cargo` entry and
`labels: ["dependencies", "github_actions"]` on the `github-actions` entry — the
default values, written explicitly.

##### Ranked runner-up
(1) Omit `labels` entirely — identical observable result today, two fewer lines, and
immune to a future rename of a default; adopt this if P03 prefers a minimal file;
(2) add a `rust`-plus-`security` pair — rejected, R13 owns the security surface;
(3) py's hyphenated string — rejected on the evidence above.

##### Tradeoffs
Restating a default is redundancy, and if GitHub ever renames an ecosystem's default
label the explicit value becomes a custom one that silently drops. That is the exact
risk the runner-up avoids, and it is the reason the runner-up is ranked first rather
than dismissed.

##### Parameters
Owns nothing; assumes nothing. No `CONFLICT:` line. Note for R11/R12: a required-check
or auto-merge rule keyed on a label must key on `dependencies`, the one label that is
always present.

##### Migration implications
Adds one line per entry. No repository label definitions are required, by construction.

##### Validation strategy
Proposed, not executed: after the first Dependabot PR, confirm it carries exactly
`dependencies` and the ecosystem label, and confirm both labels exist under the
repository's **Issues → Labels** page having been created by Dependabot rather than by
hand.

##### Confidence & re-verify trigger
Medium-high — the values are read from the implementation, but the interaction between
"declared custom label" and "auto-created default label" is documented in two separate
sentences and was not executed against a live repository. Re-verify by observing the
first PR on the P03 template; re-verify also if `dependabot-core` changes either
`register_label_details` call.

##### Sources
`https://raw.githubusercontent.com/dependabot/dependabot-core/main/cargo/lib/dependabot/cargo.rb`;
`.../github_actions/lib/dependabot/github_actions.rb`;
`.../common/lib/dependabot/pull_request_creator/labeler.rb`; options-reference source
(`labels`); py at pin `b08bccfb`; ts at pin `cb1cbcb2`; the surveyed `dependabot.yml`
files. All retrieved 2026-09-10.

#### Commit-message prefix contract (`commit-message`)

##### Landscape
Established-standard bin: `commit-message` with `prefix`, `prefix-development` and
`include`. The Rust field barely uses it — 2 of 11 surveyed Cargo entries set it
(polars `prefix: build` with `prefix-development: chore(rust)`; crossbeam `prefix: ''`
to suppress prefixing) — because most projects do not lint commit messages. This
template does, which moves the key from optional to required.

##### Principles and implementation
Principle: every commit that lands satisfies the repository's declared
Conventional-Commits contract, bot commits included. R38 settles that contract:
type enum `build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test`,
header cap 50 columns over the whole `type(scope): description` line (F152), body and
footer 72 (F153, F154), and F157's CI re-run over every pull-request commit
(`docs/port/PARAMETERS.md:13`; `research/topics/38-commit-message-linter/DECISION.md`,
retrieved 2026-09-10). Dependabot's own default is "Commit messages follow similar
patterns to those detected in the repository" — a heuristic, not a guarantee.
Acceptance: every Dependabot commit subject begins `chore(deps): ` and F157's CI step
exits 0 under `committed.bot.toml`.

##### Dominant choice
`prefix` plus `include: scope`, which is what py uses and what any Conventional-Commits
repository needs: "When defined any prefix is followed by the type of dependencies
updated in the commit: `deps` or `deps-dev`", and Dependabot "inserts a colon after the
prefix" when the value ends with a letter (options-reference source, retrieved
2026-09-10). `prefix: "chore"` + `include: "scope"` therefore yields
`chore(deps): bump …`.

##### Qualified shortlist
(a) `prefix: "chore"` + `include: "scope"` — py's shape minus the unsupported key;
(b) py's exact block including `prefix-development: "chore"`; (c) `prefix: "build"`
(polars's choice, and a legitimate reading of Conventional Commits for dependency
bumps); (d) omit the key and rely on Dependabot's pattern detection.

##### Excluded by gate
None by fitness gate; gates 2–6 **inapplicable**, gate 1 satisfied by MIT
`dependabot-core`. Candidate (b) is excluded by capability, twice over:
`prefix-development` is "Supported by: `bundler`, `composer`, `mix`, `maven`, `npm`,
`pip`, and `uv`" — `cargo` is absent — and even if it were accepted it could never
fire, because Cargo's production check is `->(_) { true }`, so no Cargo dependency is
ever in the "Development dependency group". By the same fact `include: scope` emits
`deps` and never `deps-dev` for the `cargo` entry, which is a real behavioral
difference from py's `uv` entry and must not be described as equivalent. Candidate (d)
is excluded by the acceptance criterion: a heuristic that "follows similar patterns" is
not a contract, and F157 fails the PR when it guesses wrong.

##### Up-and-comers
None; `commit-message` is stable. The adjacent moving part is R38's F156 bot exemption,
which relaxes width rules in CI for PRs authored by `dependabot[bot]` while keeping the
grammar and the eleven types enforced — that is what makes a long grouped subject safe.

##### Fit for this template
Exactly one prefix is needed, and `chore` is in R38's eleven-type enum, so
`chore(deps): bump …` is grammatical under both `committed.toml` and
`committed.bot.toml`. `build` (polars's choice) is also in the enum and also
defensible, but `chore` is what py already emits, and this is precisely a key where the
org value should agree across repositories: F156 selects the bot config by author
login, not by prefix, so nothing else depends on the choice — which makes agreeing free.

##### Recommendation
`commit-message: { prefix: "chore", include: "scope" }` on both entries. Do **not**
write `prefix-development`. Document in the template that Cargo bumps always scope as
`(deps)`, never `(deps-dev)`.

##### Ranked runner-up
(1) `prefix: "build"` on the `cargo` entry only — arguably more accurate under
Conventional Commits and used by polars, rejected because it breaks agreement with py
for no observable gain; (2) `prefix: "chore"` without `include: "scope"` — yields
`chore: bump …`, valid but loses the `deps` scope that R24's changelog mapping may key
on; (3) py's full block — rejected on the capability evidence.

##### Tradeoffs
Fixing the prefix means Dependabot no longer adapts to a consumer's own commit
convention if they change it; that is the point. The lost `deps-dev` distinction is a
genuine loss of information relative to py, and it is not recoverable by any key — a
reviewer who wants it must read the diff.

##### Parameters
Owns nothing. Assumes `commit-message-convention` (researched, R38): specifically the
eleven-type enum (`chore` ∈ enum), F152's 50-column soft-line header cap, and F156's
`dependabot[bot]` bot config. No `CONFLICT:` line — every value this member needs is
already satisfied by R38's settled values.

##### Migration implications
Adds a three-line `commit-message` block to each entry. Couples to
`committed.bot.toml`, which R38 already specifies and which must exist for F157's
bot branch to select it. py's `prefix-development` line is **not** carried over.

##### Validation strategy
Proposed, not executed: take a representative grouped subject —
`chore(deps): bump the cargo group with 7 updates` — and run
`printf '%s\n' "<subject>" > /tmp/msg && committed --commit-file /tmp/msg` against both
`committed.toml` and `committed.bot.toml`, expecting exit 0 under the bot config for
every identifier length the two group names produce. Executed result: **none** —
`committed` was not run in this report, and R38's own executed evidence covers the
tool's behavior but not these two literal subjects.

##### Confidence & re-verify trigger
High on the unsupported-key finding (documentation and implementation agree); medium
on the subject-length interaction, which is arithmetic over an unexecuted string.
Re-verify when P03 first runs F157's CI step over a real Dependabot PR, and if
`dependabot-core` ever registers a non-trivial production check for `cargo`.

##### Sources
Options-reference source (`commit-message`, `prefix`, `prefix-development` support
list, `include`);
`https://raw.githubusercontent.com/dependabot/dependabot-core/main/cargo/lib/dependabot/cargo.rb`;
`docs/port/PARAMETERS.md:13`;
`research/topics/38-commit-message-linter/DECISION.md` (F152, F153, F154, F156, F157);
py at pin `b08bccfb`;
`https://raw.githubusercontent.com/pola-rs/polars/HEAD/.github/dependabot.yml`. All
retrieved 2026-09-10.
