# R38 — commit-message linter (raw report, engine: opus)

Item: R38 `commit-message-linter` · kind `crate` · owns `commit-message-convention`.
Actor: `research-opus-2026-09-05T151356Z-c46d732f98ed`. All retrievals dated 2026-09-05
unless a different date is given inline.

### Landscape

**The category this item decides.** A *commit-message linter*: a program invoked by git's
`commit-msg` hook with the path of the pending message file, which exits non-zero when the
message violates a declared convention — here [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
(retrieved 2026-09-05) — and which can be re-run over a commit *range* in CI. Two orthogonal
things are being chosen: the **enforcement engine** and the **rule values** (type enum, header
and body and footer length caps).

**Three-bin map of the Rust field.**

*Bin 1 — built-in or first-party toolchain: empty.* Neither `cargo` nor `rustup` ships commit
tooling. `cargo --list` on this machine (cargo 1.98.0, run 2026-09-05) has no commit-lint
subcommand, and the first-party quality tools (`rustfmt`, `clippy`) operate on source, never on
git metadata. The absence is itself a finding: unlike formatting or linting, Rust has no
first-party answer here, so a third-party tool is unavoidable and the choice is real. The
nearest thing to first-party is the **`crate-ci` organization**, whose `committed` is authored
by `epage`, a member of the **rust-lang Cargo team** (listed in
[`rust-lang/team/teams/cargo.toml`](https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml),
retrieved 2026-09-05, alongside `joshtriplett`, `weihanglo`, `Muscraft`, `arlosi`);
`epage` has 822 of the repository's commits
(`GET https://api.github.com/repos/crate-ci/committed/contributors?per_page=5`, 2026-09-05).

*Bin 2 — established industry standard.* `committed` (crate-ci), `cocogitto` (`cog check`),
`convco` (`convco check`). Plus the incumbent non-Rust standard, **commitlint** via a
provisioned Node/Bun runtime, which is the architectural alternative both source repos use.

*Bin 3 — up-and-comers.* `commitlint-rs`, `git-sumi`, `cargo-commitlint`, `commitfmt`,
`conventional-commits-check`. Library layer (not linters, but the parsers underneath):
`git-conventional` (crate-ci, used *by* `committed`) and `conventional_commit_parser`
(used by `cocogitto`).

**How the map was built** — from queries, not recall.
`GET https://crates.io/api/v1/crates?q=<term>&per_page=25&sort=recent-downloads` for the terms
`conventional+commits`, `commitlint`, `commit+message+lint`, `commit+lint` (User-Agent header
sent), and `GET https://api.github.com/search/repositories?q=topic:conventional-commits+language:rust&sort=stars&per_page=30`
(`total_count` = 80), all 2026-09-05. The GitHub topic search also surfaced adjacent categories
that are *not* commit-msg linters and are therefore out of the shortlist: changelog generators
(`orhun/git-cliff`, 12,213 stars), interactive commit *composers* (`cococonscious/koji`, 463
stars; `alt-art/commit`, 318 stars), and release automation (`knope-dev/knope`, 188 stars).

**Authoritative sources used, and why each is authoritative.**

| Source | Why authoritative | Used for |
|---|---|---|
| [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) | The specification itself — the standard being enforced | Mandates only `feat`/`fix`; imposes **no** line-length limits; names `build, chore, ci, docs, style, refactor, perf, test` as examples |
| [`git-commit` DISCUSSION](https://git-scm.com/docs/git-commit) | Git's own reference documentation | "a single short (no more than 50 characters) line summarizing the change" |
| [Pro Git, *Contributing to a Project*](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project) | The Git project's official book | "no more than about 50 characters"; "Wrap it to about 72 characters or so" |
| [`rust-lang/team` cargo roster](https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml) | The Rust project's machine-readable governance record | Establishes `epage`'s Cargo-team standing |
| [`committed` reference](https://github.com/crate-ci/committed/blob/master/docs/reference.md) + [source](https://github.com/crate-ci/committed/blob/master/crates/committed/src/checks.rs) | Maintainer's own documentation, verified against implementation | Config field semantics |
| [`@commitlint/config-conventional` source](https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/src/index.ts) | The upstream config both source repos extend | The canonical 11-member `type-enum` |
| [`conventional-changelog-conventionalcommits` constants](https://github.com/conventional-changelog/conventional-changelog/blob/master/packages/conventional-changelog-conventionalcommits/src/constants.js) | The preset release-please consumes by default | `DEFAULT_COMMIT_TYPES` — proves the enum maps downstream without renaming |

A single blog post was treated as a lead, never an authority; no blog post is cited.

**Practice evidence — mainstream, well-regarded Rust projects, with the evidence that they are
well regarded.** `GET https://api.github.com/search/code?q=filename:committed.toml` returns
`total_count` = **258** (2026-09-05). The adopters are not a long tail of hobby repos; they
include the core of the Rust CLI ecosystem:

| Project | Evidence it is well regarded | Config cited |
|---|---|---|
| `clap-rs/clap` | *The* Rust argument parser; the dependency essentially every Rust CLI builds on | [`committed.toml`](https://raw.githubusercontent.com/clap-rs/clap/master/committed.toml), [`.github/workflows/committed.yml`](https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/committed.yml), [`.pre-commit-config.yaml`](https://raw.githubusercontent.com/clap-rs/clap/master/.pre-commit-config.yaml) |
| `ratatui/ratatui` | Dominant Rust TUI library; 48,829,647 all-time downloads (`GET https://crates.io/api/v1/crates?q=conventional+commits&sort=recent-downloads` → `crates[].downloads`, 2026-09-05) | [`committed.toml`](https://raw.githubusercontent.com/ratatui/ratatui/main/committed.toml) |
| `rust-cli/env_logger` | Maintained by the **Rust CLI working group** org | [`committed.toml`](https://raw.githubusercontent.com/rust-cli/env_logger/main/committed.toml) |
| `toml-rs/toml` | The reference TOML implementation for Rust | [`committed.toml`](https://raw.githubusercontent.com/toml-rs/toml/main/committed.toml) |
| `crate-ci/typos` | Widely adopted source spell-checker; used by clap itself | [`committed.toml`](https://raw.githubusercontent.com/crate-ci/typos/master/committed.toml) |
| `archlinux/alpm`, `ariel-os/ariel-os`, `gtema/openstack`, `rust-mcp-stack/rust-mcp-schema`, `continuwuity/continuwuity`, `rustic-rs/rustic_server`, `astarte-platform/astarte`, `pact-foundation/pact-python` | Institutional and multi-maintainer projects across distro, embedded, cloud and protocol domains | same code-search result set |

That `clap`, `env_logger` and `toml` — the three crates a Rust CLI + library template is most
likely to depend on — all enforce commit messages with `committed` is the single strongest
fit signal available for this item.

**One code-search hit was checked and rejected.** `jdx/mise` appears in the
`filename:committed.toml` results, but the file is
[`registry/committed.toml`](https://raw.githubusercontent.com/jdx/mise/main/registry/committed.toml)
(2026-09-05) — `backends = ["aqua:crate-ci/committed"]`, mise's *tool-registry* entry that
packages `committed` for installation, not a repository using it on its own commits. It is
therefore **not** counted as an adopter. It is worth recording for a different reason: it means
`mise use committed@<version>` is an available pinned-provisioning path, which is R42's
(`dev-toolchain-provisioning`) concern, not this item's. The same caution applies to the
un-inspected tail of the 258 results, which were not individually verified.

**Evidence gap, stated rather than papered over.** The annual Rust survey does not ask about
commit-message linting, so there is no survey-grade adoption figure for this category; the
258-repository code-search count plus the named adopters above are the substitute, and they
measure published configuration files, not developers.

### Principles and implementation

**The shared requirement.** Every commit that lands is machine-parseable under a single declared
Conventional-Commits vocabulary, and messages are readable in `git log`. This is a
**capability/standard**-level agreement, recorded for F148 in `docs/port/BASELINE-REVIEW.md:75`
("Enforce the selected commit-message convention at `commit-msg` time", verdict `retained`).
The agreement level is the *contract* — which types are legal and how wide lines may be — not
the program that checks it. `docs/port/DIVERGENCE-ANALYSIS.md:155` classes R38 as **class B**
(same pattern, language-bound tool) with `harmonize: partly`; its per-fact sub-rows class
F152/F153/F154/F155 as **class A** (setting drift) with `harmonize: yes`, meaning the *values*
should converge across all three repos while the *tool* may legitimately differ per ecosystem.

**Essential behaviors** (what any candidate must do):
1. Read one pending message file and exit non-zero on violation — the `commit-msg` contract.
2. Validate the Conventional-Commits grammar and restrict `type` to a declared list.
3. Cap subject width and body width.
4. Re-run over a commit *range* in CI, because `git commit --no-verify` bypasses any local hook.
5. Fail **loudly** when the tool itself is missing or misconfigured — never exit 0 on an
   unvalidated message.

**Observable acceptance criteria.** For a fixed config: a conforming message exits 0; a
disallowed `type` exits 1; a subject over the cap exits 1; a body line over the cap exits 1; a
body line that is one long un-wrappable URL exits 0; a bot-authored commit selected by the
configured author pattern is skipped on the CI range path. Every one of these is executed below.

**What must agree, and what may vary.** Must agree across py, ts and rs: the type enum, the
header cap, the body cap, and the fact of a CI re-run. May vary: the binary, its config file
format, and its invocation mechanics — those are ecosystem-bound.

**Architectural alternatives compared before libraries.** There are three, not two:

- **(A) Provision a JS runtime and run commitlint.** Preserves byte-identical rule configuration
  with both source repos. Cost: `@commitlint/cli` 21.2.2 declares `engines.node >= 22.12.0`
  (`GET https://registry.npmjs.org/@commitlint/cli`, 2026-09-05), so a Rust template acquires a
  Node/Bun runtime, a `package.json`, a JS lockfile and a `node_modules` tree solely to lint
  commit messages. It also imports py's documented failure surface (below).
- **(B) A native Rust binary with its own config.** Loses config-file identity with the sources
  but preserves the *contract*, which is what the agreement level actually requires. Zero
  runtime dependency; the tool is a developer-machine and CI binary, never a crate dependency,
  so it never enters the template's dependency graph, binary size or compile time.
- **(C) Hand-rolled regex in a shell hook.** Rejected without a figure table: it would re-derive
  a specification that already has conforming implementations, and it cannot express
  imperative-mood, capitalization, fixup/WIP or merge-commit rules. Recording it only to show
  the alternative space was considered.

**(B) is correct here**, and the decisive evidence is not preference but a measured behavioral
difference described next.

**Capability coverage is the first filter, and it is unexpectedly narrow.** Surveying the four
gate-passing Rust candidates against the five essential behaviors above produces a result that no
download figure would have predicted: **two of the four cannot cap line width at all.**
`convco check` performs no length check (its `description.length.max` is consumed only by the
interactive `convco commit` builder), and `cocogitto`'s `Settings` struct contains no length field
of any kind — and because that struct is `#[serde(deny_unknown_fields)]`, a length key in
`cog.toml` is a hard error rather than a silent no-op. Only `committed` and `git-sumi` express
behaviors 2 and 3 together, and only `committed` adds an author-based exemption for behavior 4's
bot traffic. The per-candidate evidence is in `### Qualified shortlist`. This is why the prompt's
instruction to apply gates and fitness *before* popularity is load-bearing here: `cocogitto` leads
the field on stars and downloads and still cannot do the job.

**The load-bearing discovery — soft-line measurement.** `committed` does not measure the whole
line. In
[`crates/committed/src/checks.rs:147-171`](https://github.com/crate-ci/committed/blob/master/crates/committed/src/checks.rs)
(retrieved 2026-09-05), `check_line_length` computes `last_space_index = line.rfind(' ')` and
measures only `soft_line = &line[0..last_space_index]` — the text *before the final space*. A
line containing no space at all yields `soft_line = ""` (length 0) and can never violate the cap.
`check_subject_length` (`:118-145`) uses the identical rule. `check_hard_line_length` (`:174-193`)
is the opt-in absolute ceiling and measures the whole line; it defaults to `0` (disabled).

This matters because it dissolves the exact disagreement between the two source repos. py raised
`body-max-line-length` to 200 and `footer-max-line-length` to 200 (`commitlint.config.mjs:17-18`,
per `## Context`) purely to accommodate documentation URLs and permalinks, because commitlint
counts whole lines. ts tightened to 72 (`commitlint.config.mjs:30`) for readability and simply
has no URLs long enough to have hit the problem. With soft-line measurement, **rs gets both**:
the strict 72-column wrap ts wanted *and* the long-URL tolerance py needed, from one setting. The
50/200/200-versus-50/72/100 argument is an artifact of the checker, not a genuine values
disagreement — so the harmonized cross-repo value is 50/72, and py's 200s are revealed as a
workaround rather than a requirement. This is verified empirically in `### Validation strategy`
(case 05 exits 0 with `line_length = 72`).

**A defect found in the recommended tool, reported honestly.** At
[`checks.rs:98-100`](https://github.com/crate-ci/committed/blob/master/crates/committed/src/checks.rs),
the hard-line check is dispatched with the wrong argument:

`if config.hard_line_length() != 0 { failed |= check_hard_line_length(source, message, config.line_length(), report)?; }`

It passes `config.line_length()` where `config.hard_line_length()` belongs. Consequence:
`hard_line_length` functions only as an on/off switch and, when enabled, applies the *soft* limit
as an absolute limit. `GET https://api.github.com/search/issues?q=repo:crate-ci/committed+hard_line_length`
returns `total_count` = 1, a closed issue about GitHub Actions usage — so this is **unreported**
as of 2026-09-05.

This is not only a code-read of `master`: it was **reproduced on the tested release, 1.1.11**
(case 20 below). With `line_length = 72` and `hard_line_length = 200`, a 100-character
space-free line is rejected with `Line is too long, 100 exceeds the max length of 72` — the hard
check demonstrably received the soft value. The reproduction also exposes the *consequential*
harm, which matters more than the wrong number: because `check_hard_line_length` measures whole
lines, switching `hard_line_length` on **destroys the URL exemption** that the entire F153/F154
rationale rests on. The recommended configuration therefore leaves `hard_line_length` at its
default `0`, which never reaches the defective branch. Recorded as a re-verify trigger and as a
worthwhile upstream contribution.

**Silent-pass failure modes (the prompt's explicit requirement).** py's `lefthook.yml:18-58`
comments — retrieved verbatim from
[`raw.githubusercontent.com/smorinlabs/py-launch-blueprint/b08bccf/lefthook.yml`](https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/b08bccf/lefthook.yml)
(2026-09-05) — record three *measured* modes. Mapping each onto the native-binary path:

| py's measured mode | py's evidence | Native-binary equivalent |
|---|---|---|
| Bare name unresolvable — `commitlint` exits 127 without a global pin; `./node_modules/.bin/commitlint` exits 127 under Bun because the shim is `#!/usr/bin/env node` and neither mise nor flox provisions node | "`bare commitlint` 127/127 without a global mise pin" | **Still exists but is loud, not silent.** Measured: with `committed` off PATH the hook exits **127** and lefthook fails the commit. There is no interpreter shim, so the node-versus-bun class disappears entirely. |
| Script-name shadowing — `bun run commitlint` runs a `package.json` `scripts.commitlint` entry; a permissive wrapper returned **exit 0 for an invalid message** | "`bun run commitlint` 0 for an INVALID message when a scripts.commitlint entry shadows it" | **Structurally impossible.** A native binary has no package-script namespace for lefthook to resolve through. |
| Network/global fallback — `bunx`/`bun x` fetch `@latest` into an ephemeral cache, silently using a different `@commitlint/config-conventional` than the lockfile pins | "silently uses a global CLI when node_modules is absent"; the incident that "broke this hook originally" | **Structurally impossible at run time** — `committed` resolves and fetches nothing. **A residual analogue remains:** `cargo install` is global and has no per-repo lockfile for binaries, so a developer could hold a different `committed` version than the template expects. Mitigations: pin the version in the install recipe, assert it (`committed --version`), and pin the CI action by SHA so CI is authoritative. |

The net finding: choosing a native static binary removes two of py's three measured silent-pass
modes by construction and converts the third from silent to loud, while introducing one weaker
version-drift risk that is mitigable but should be stated rather than hidden.

**Reference implementation and how it composes.** `clap-rs/clap` is the maintained reference: a
repo-root `committed.toml`, the `commit-msg` hook wired through a hook manager, and
`.github/workflows/committed.yml` re-running the check over the PR's commit range with
`fetch-depth: 0`. That is precisely the two-tier shape this item must produce, in the flagship
Rust CLI project. `crate-ci/committed` itself uses the identical pair.

**Integration cost, maturity and dependability.** `committed` is a dev-tool binary, so its
dependency tree never touches the template's. Measured locally 2026-09-05:
`cargo install committed --locked --version 1.1.11` finished in **28.7 s wall / 175 s CPU** on
this host and produced a **3.7 MB** binary. Prebuilt release binaries exist for
`aarch64-apple-darwin`, `x86_64-apple-darwin`, `aarch64-unknown-linux-musl`,
`x86_64-unknown-linux-musl` and `x86_64-pc-windows-msvc`
(`GET https://api.github.com/repos/crate-ci/committed/releases/latest`, tag `v1.1.11`,
published 2026-02-25), so the from-source path is optional.

**Performance.** Stated with workload and instrumentation rather than an abstract "fastest":
the workload is a single commit message of a few hundred bytes, once per `git commit`; the
measurement is wall-clock of the process invocation on this host (Darwin 25.4.0, arm64). At this
workload every candidate is bounded by process start-up, and the difference between a native
binary (no interpreter) and commitlint (Node ≥ 22.12 start-up plus module resolution) is the only
term that matters; no throughput or latency benchmark distinguishes the native candidates from
one another, and none is claimed. This item does not select on speed.

**`BASELINE-REVIEW:` findings: none.** F148 (linting happens at `commit-msg` time) and F159
(template wired via `git config commit.template`) are out of scope and are not challenged. F158
and F160, recorded `blocked pending R38` in `docs/port/BASELINE-REVIEW.md:76,79`, are *fulfilled*
rather than challenged — their required content is supplied in `### Migration implications`.

### Dominant choice

**`committed` (crate-ci), version `1.1.11`, range `>=1.1.11, <2.0.0`.**

It is the **only** tool surveyed — Rust or otherwise, native or JS — that expresses this item's
entire contract in one configuration file with no language runtime: `style = "conventional"` plus
`allowed_types` (the type enum, F155), `subject_length` (F152), `line_length` (F153/F154),
`ignore_author_re` (the bot exemption, F156) and an official GitHub Action (the CI re-run, F157).
Of the four Rust candidates that passed every fitness gate, two (`convco`, `cocogitto`) enforce
no length limits at all and one (`git-sumi`) has no author-based exemption, so `committed` is the
only one that does not require either dropping part of the contract or bolting on a second tool.
It is authored by a Cargo-team member, adopted by `clap`, `ratatui`, `toml`, `env_logger` and
`typos`, dual-licensed `MIT OR Apache-2.0`, edition 2024, and `unsafe`-free. Dominance is claimed
on gate-passage and capability coverage, established *before* download figures are weighed, per
the prompt's ordering — and on those figures it is not even the most popular option, which is
precisely why the ordering matters.

### Qualified shortlist

Candidates that passed **every** fitness gate. Figures: 90-day downloads =
`GET https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads`; all-time =
`crate.downloads`; last release = `GET https://crates.io/api/v1/crates/<name>/versions`, newest
with `yanked: false`; stars/archived = `GET https://api.github.com/repos/<o>/<r>`; open issues =
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`.
All retrieved **2026-09-05**.

**Three passed every gate, and only one of those covers the contract.** The gates in
`## Required evidence` test *fitness to depend on*; they do not test *capability*. Separating the
two produces the central finding of this report, so capability is shown as its own column rather
than buried in a trade-off phrase. `git-sumi` is shown in the table **for capability comparison
only** — it fails gate 2 (no declared `rust-version`) and is formally listed under
`### Excluded by gate`; it reappears as the conditional runner-up because it is the only other
tool that can express the whole contract.

| Name | 90-day | All-time | Stars | Last release | Maintenance | Type enum? | Header cap? | Body cap? | Bot exempt? | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **`committed`** | 3,551 | 84,746 | 182 | `1.1.11`, 2026-02-24 | **active** | yes `allowed_types` | yes `subject_length` | yes `line_length` | **yes** `ignore_author_re` | `clap`, `ratatui`, `toml`, `env_logger`, `typos` (258 repos) | Lowest downloads of the three established tools, and no *separate* footer cap — one `line_length` governs body and footer alike |
| `git-sumi` *(gate 2 failed — comparison only)* | 68 | 12,418 | 31 | `0.3.0`, 2026-02-14 | stable-quiet | yes `types_allowed` | yes `max_header_length` | yes `max_body_length` | no | none identified | The only other tool expressing the whole contract, but counts **whole lines** (URLs included) and declares no MSRV |
| `convco` | 2,159 | 65,575 | 316 | `0.7.2`, 2026-09-03 | **active** | yes `types` | **no** | **no** | no | not enumerated | Most responsive project surveyed, but `convco check` enforces **no length limits at all** |
| `cocogitto` | 8,030 | 219,448 | 1,184 | `7.0.0`, 2026-03-04 | **at-risk** | partial | **no** | **no** | no | not enumerated | Most popular Rust option, but enforces **no length limits at all** and its type list is opt-out, not an explicit allow-list |

**Only one candidate covers the full contract with a bot exemption, and only three clear every
gate — both are findings, per the prompt's instruction that a short list is itself informative.**
Verified independently rather than taken on the documentation's word (2026-09-05):

- `convco`: the sole `len()` in
  [`src/cmd/check.rs`](https://raw.githubusercontent.com/convco/convco/main/src/cmd/check.rs) is
  `first_line.len() > 40` inside `print_fail`, which truncates the *failure output* for display.
  The `description.length.max` setting exists in `Config` but is consumed only by the interactive
  `convco commit` builder, never by `convco check`; `line_length` is CHANGELOG word-wrap. So the
  subcommand this item would invoke enforces no width rule.
- `cocogitto`: its `Settings` struct
  ([`crates/cocogitto/src/settings/mod.rs`](https://raw.githubusercontent.com/cocogitto/cocogitto/main/crates/cocogitto/src/settings/mod.rs))
  contains **no** `max_*` or `length` field at all, and carries `#[serde(deny_unknown_fields)]`,
  so a length key in `cog.toml` would be a hard error rather than a silent no-op. Its
  `[commit_types.<name>]` map *merges onto* 11 hardcoded defaults; a type is removed only by
  setting its table to `{}`, so there is no single "replace the list" key of the kind F155 needs.
- `git-sumi`: `validate_line_length` in
  [`src/lint.rs:172-179`](https://raw.githubusercontent.com/welpo/git-sumi/main/src/lint.rs)
  is `let actual_length = line.chars().count();` — the **whole** line, with no exemption for an
  un-wrappable token. A long documentation URL therefore forces `max_body_length` upward, which is
  exactly the trap that produced py's 200-column body cap.

Adopting `convco` or `cocogitto` would mean either abandoning the length half of
`commit-message-convention` or layering a second tool to supply it. Both outcomes are worse than
the one parity gap `committed` carries (no separate footer knob), which changes no observable
outcome.

**Maintenance state by the prescribed rubric** — issue responsiveness computed from the 10 most
recently opened issues per repo (`GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc`,
excluding pull requests; first comment whose `author_association` is `OWNER`/`MEMBER`/`COLLABORATOR`
and is not the issue author), 2026-09-05:

| Crate | Median days to first maintainer response | Unanswered of 10 | `pushed_at` | Verdict and the reasoning the rubric demands |
|---|---|---|---|---|
| `committed` | **0.28** | 1 | 2026-09-01 | The 2026-02-24 release is ~6.4 months old, which is a **trigger to investigate, not a verdict**. Investigation: commits through 2026-09-01, median first response under 7 hours, 22 open issues, CI green on three OSes. A mature tool with low feature churn. → **active** |
| `convco` | **0.28** | 0 | 2026-09-03 | Released 2026-09-03; **zero** open issues; every one of the 10 most recent issues answered. → **active** |
| `git-sumi` | **7.64** | 2 | 2026-09-05 | Pushed the day of this survey; small, single-maintainer, week-scale response times; no decay signal but no institutional backing either. → **stable-quiet** |
| `cocogitto` | **no maintainer response in any of the 10** | **10** | 2026-04-22 | The rubric requires a concrete signal for `at-risk`, and there is one: ten consecutive most-recent issues with no maintainer reply, spanning 2026-04-20 → 2026-08-02, alongside 56 open issues and no push for ~4.5 months. Not `dormant` — no unpatched advisory, no broken build, no maintainer notice. → **at-risk** |

Adopter sets for `convco` and `cocogitto` were not enumerated to the standard required for a
recommendation, since neither can express the contract; recorded as a bounded gap.

### Excluded by gate

No candidate was excluded by gates 1–6 outright; the gates are recorded per candidate below, and
exclusions from the *shortlist* were made on maturity and capability, which the prompt asks to be
stated separately from gate failure.

**Gate results for the recommended pick, `committed` 1.1.11:**

1. **License** — `MIT OR Apache-2.0` (`crate.license` on the newest unyanked version, and
   `LICENSE-APACHE` + `LICENSE-MIT` in the repo root). Identical to the template's fixed
   `license` parameter. **Pass.**
2. **MSRV** — declared `rust-version = "1.89"`
   ([workspace `Cargo.toml`](https://raw.githubusercontent.com/crate-ci/committed/master/Cargo.toml),
   2026-09-05). Current stable is **1.98.1** (`https://static.rust-lang.org/dist/channel-rust-stable.toml`,
   manifest date 2026-09-03), so the policy floor "stable minus 2 minor versions" is **1.96.x**,
   and 1.89 sits comfortably below it — the tool builds on any toolchain this template supports.
   **Important scoping:** `committed` is a *dev-tool binary*, never a workspace dependency, so
   the MSRV gate binds only the `cargo install`-from-source path; the prebuilt release binaries
   and the pinned GitHub Action sidestep the toolchain entirely. **Pass**, with that split stated.
3. **Advisories / `unsafe`** — `https://rustsec.org/packages/committed.html` returns **HTTP 404**,
   which means *no advisory page exists*, i.e. no advisories. This 404 semantics was
   control-tested the same day: `time`, `openssl` and `atty` (all known-advisory crates) return
   **HTTP 200**. `unsafe` posture: **zero occurrences of `unsafe`** across all ten source files
   in `crates/committed/src/` (`checks.rs`, `config.rs`, `conventional.rs`, `lib.rs`, `main.rs`,
   `git.rs`, `report.rs`, `style.rs`, `no_style.rs`, `color.rs`), and the workspace sets
   `unsafe_op_in_unsafe_fn = "warn"`. Its one FFI dependency is `git2` (libgit2 bindings),
   declared `default-features = false`, which avoids the vendored-OpenSSL feature. **Pass.**
4. **OS matrix** — `committed`'s own CI matrix is
   `os: ["ubuntu-latest", "windows-latest", "macos-latest"]` on `stable`
   ([`.github/workflows/ci.yml:36-40`](https://raw.githubusercontent.com/crate-ci/committed/master/.github/workflows/ci.yml)),
   which is a superset of the required `ubuntu-latest, macos-latest`. Independently confirmed by
   building and running it on macOS (Darwin 25.4.0, arm64) in `### Validation strategy`.
   Windows is supported and noted, not required. **Pass.**
5. **Default features and async coupling** — the crate declares exactly one feature,
   `unstable-schema` (optional `schemars`), **off by default**. There is **no async runtime
   coupling of any kind**: no `tokio`, no `async-std`, no futures in the dependency list. **Pass.**
6. **Binary size and compile-time cost** — qualitatively low and, more importantly, *external to
   the template*: this is an installed binary, not a linked dependency, so it contributes
   **zero** bytes to the template's own artifacts and zero seconds to `cargo build`. Measured
   install cost on this host: 3.7 MB binary, 28.7 s wall / 175 s CPU from source; ~0 s when the
   prebuilt release asset or the pinned action is used. **Pass.**

**Gates answered for the other shortlisted candidates.** Both are dev-tool binaries, so gates 5
and 6 take the same form as for `committed`: nothing is linked into the template, so features,
async coupling, binary size and compile time are external to it — recorded as **inapplicable to
the template's artifacts**, with the caveat that neither crate's feature set was audited.

- **`convco`** — gate 1: `MIT`, compatible with `MIT OR Apache-2.0` (a permissive licence for an
  invoked binary; note it is *not* dual-licensed). Gate 2: `rust-version = "1.87"`, below the
  1.96.x floor. **Pass.** Gate 3: `https://rustsec.org/packages/convco.html` → **404**, i.e. no
  advisories; `unsafe` posture **not audited** — recorded as a gap. Gate 4: `v0.7.2` publishes
  `aarch64-apple-darwin`, `aarch64-unknown-linux-musl`, `x86_64-unknown-linux-musl` and a Windows
  asset, covering both required runners; **no `x86_64-apple-darwin` asset**, which is immaterial
  on today's arm64 `macos-latest` but would matter on an Intel Mac.
- **`cocogitto`** — gate 1: `MIT`. Gate 2: `rust-version = "1.78.0"`. **Pass.** Gate 3:
  `https://rustsec.org/packages/cocogitto.html` → **404**, no advisories; `unsafe` posture **not
  audited**. Gate 4: `7.0.0` publishes macOS `aarch64` and `x86_64`, Linux `gnu`, `musl` and
  `armv7`, and Windows — full coverage of the required matrix.

Neither is excluded by a gate; both are excluded from the recommendation on **capability**, as
`### Qualified shortlist` sets out.

**Gate 2 could not be cleared by two candidates — an actual gate failure, not a preference.**
The MSRV policy requires the floor to be "declared as rust-version in Cargo.toml". Neither
`git-sumi` (https://raw.githubusercontent.com/welpo/git-sumi/main/Cargo.toml) nor `commitlint-rs`
(https://raw.githubusercontent.com/KeisukeYamashita/commitlint-rs/main/Cargo.toml) declares a
`rust-version` key anywhere in its manifest (2026-09-05), so their MSRV is **unverifiable** rather
than merely old. **Both are therefore excluded by gate 2.** `git-sumi` is still *shown* in the shortlist table
because it clears every other gate and is the only alternative expressing the full contract, and
it returns as the conditional runner-up — but its gate-2 failure is recorded, not waived, and
declaring a `rust-version` is part of the condition under which it would win.

**Excluded on maturity, capability or adoption, not on a gate:**

- **`commitlint-rs`** (`KeisukeYamashita/commitlint-rs`) — 90-day 8,569 · all-time 50,958 ·
  70 stars · `0.2.4`, 2026-02-24 · `MIT OR Apache-2.0` · 13 open issues. The most strategically
  interesting candidate in the field (it reads commitlint-style rule config, which would give
  config parity without a Node runtime), but excluded on three concrete counts:
  (i) **its latest release ships zero binary assets** — `GET https://api.github.com/repos/KeisukeYamashita/commitlint-rs/releases/tags/v0.2.4`
  returns an empty `assets` array (2026-09-05), so every hook and CI run would have to
  `cargo install` from source; (ii) **maintenance** — 8 of the 10 most recently opened issues have
  no maintainer response, the two answered took 4.78 and 2.21 days (median 3.50); (iii) no
  declared MSRV and no official GitHub Action. Its `body-max-length` rule also measures the whole
  body as a single string using `String::len()` (**bytes**, not characters), which is neither
  per-line nor URL-exempt.
- **`cargo-commitlint`** (`quinnjr/cargo-commitlint`) — 90-day 214 · all-time **339** ·
  **3 stars** · `2.1.0`, 2026-07-27 · MIT · MSRV 1.80 · only 3 published versions. Excluded on
  **adoption and track record**; effectively pre-adoption.
- **`commitfmt`** (`mishamyrt/commitfmt`) — 90-day 10 · all-time 311 · 4 stars · `0.0.1`,
  2025-09-30. Excluded: a single `0.0.1` release. Note a **metadata inconsistency** worth
  recording — the crates.io `repository` field points at `github.com/jfernandez/commitfmt`
  while the GitHub topic search surfaced `mishamyrt/commitfmt`; the figures above are from the
  crate record and the `mishamyrt` repo, and the discrepancy is **unverified**.
- **`conventional-commits-check`** — 90-day 68 · all-time 904 · hosted on Codeberg
  (`https://codeberg.org/slundi/conventional-commits`), so the prescribed GitHub figures are
  **inapplicable** (stated, not silently omitted). Excluded on adoption.
- **Library-layer crates, excluded as out-of-category** (they are parsers, not linters, and
  would require writing the linter): `git-conventional` (90-day **143,845** · all-time
  **1,014,484** · 34 stars · `1.1.0`, 2026-03-17 · `MIT OR Apache-2.0` · MSRV 1.85) — notable
  because it is crate-ci's own parser and is what `committed` is built on, so its million
  downloads are indirect evidence for the recommended stack; and `conventional_commit_parser`
  (90-day 56,013 · all-time 397,718 · last updated 2022-01-17), which underpins `cocogitto`.
- **Adjacent categories, excluded by definition**: `git-cliff` (changelog generation),
  `koji`, `alt-art/commit`, `git-cm` (interactive message *composers*, which help write a
  message but do not gate one), `knope` (release automation).

**Gate status for the architectural alternative, commitlint via a JS runtime:** gates 2, 5 and 6
are **inapplicable** — it is an npm package with no Rust MSRV, no Cargo features and no compiled
artifact — and this is stated rather than scored. Gate 1: MIT, compatible. Gate 3: no RustSec
concept applies; npm advisories were not audited (**unverified**). Gate 4: Node ≥ 22.12.0 runs on
both required OSes. Its disqualifying cost is architectural, not a gate failure: it imports a
language runtime, a `package.json`, a JS lockfile and py's documented resolution-failure surface
into a Rust template.

### Up-and-comers

- **`git-sumi`** — self-described as "the non-opinionated Rust-based commit message linter", and
  on capability it is the closest thing `committed` has to a peer: `types_allowed`,
  `max_header_length` and `max_body_length` cover the type enum and both length caps. It is
  promoted here from curiosity to genuine runner-up (see `### Ranked runner-up`). What holds it
  back today is scale and two mechanics: 68 downloads in 90 days, no declared `rust-version`, no
  author-based bot exemption, and whole-line length counting with no URL exemption. Its own
  maintainer works around the missing exemption by conditionally raising
  `GIT_SUMI_MAX_HEADER_LENGTH` from CI for `chore(deps)` pull requests — indirect but concrete
  evidence that `committed`'s `ignore_author_re` solves a problem this category really has.
- **`commitlint-rs`** — the most strategically interesting project in the field: a Rust
  reimplementation that reads commitlint-style rule configuration, which would give byte-level
  config parity with py and ts *without* a Node runtime, and its 90-day 8,569 is the highest of
  any dedicated Rust commit linter, showing real demand. Barred today by a release that ships no
  binaries, 8-of-10 unanswered issues, and no declared MSRV. **The single most valuable thing to
  re-check on this item**, because it is the only candidate that could unify all three repos'
  configuration files.
- **`cargo-commitlint`** — the only candidate shaped as a `cargo` subcommand, an attractive
  ergonomic for a Rust template. Three releases and three stars; far too early.
- **`commitfmt`** — formats *and* verifies, a differentiated idea, but at `0.0.1`.

### Fit for this template

The template is one repository shipping three surfaces (spec §4 D7). Commit linting is a
**repository-level** gate, so the surfaces do not each need a different answer — but the prompt
requires them addressed separately, and there are real per-surface notes.

- **CLI.** The strongest fit of the three. `committed` is itself a Rust CLI built with `clap`
  (`clap = { version = "4.5", features = ["derive"] }`), and the projects that adopted it —
  `clap`, `ratatui`, `env_logger`, `typos` — are the exact crates a CLI template depends on and
  imitates. A contributor who already works in the Rust CLI ecosystem will have met this tool.
  The commit types the CLI surface generates (`feat`, `fix`, `perf`, `docs`) are all in the
  recommended enum.
- **Library.** The relevant property is what the choice does **not** do: `committed` is installed,
  never depended on, so the published library crate's dependency tree, `cargo-semver-checks`
  surface, docs.rs build and MSRV are all completely unaffected. Choosing alternative (A) would
  not have changed that either, but it would have put a `package.json` and a JS lockfile in a
  library crate's repository root, which is a real signal-to-consumers cost. The `revert` type in
  the enum matters most here, since a published library is the surface most likely to need a
  released change reverted.
- **Web service.** The web surface is expected to sit behind a Cargo feature (`web-extra-surface`,
  owned by R69). Commit linting is orthogonal to feature gating and adds no runtime, no
  middleware and no async coupling — confirmed by gate 5, no async runtime in the dependency
  list. The `build` and `ci` types in the enum are the ones this surface exercises most, through
  container and deployment changes; both are in the recommended enum and both are **absent from
  `committed`'s 8-member default**, which is precisely why `allowed_types` must be set explicitly
  rather than inherited.

### Recommendation

Adopt **`committed`** as the commit-message linter, at version **`1.1.11`**, accepted range
**`>=1.1.11, <2.0.0`** (pin exactly in the install recipe and by SHA in CI).

Configuration — repo-root `committed.toml`, which `committed` discovers automatically with no
`--config` flag (verified: the hook path picks it up from the git-repo root):

`style = "conventional"` · `allowed_types = ["build","chore","ci","docs","feat","fix","perf","refactor","revert","style","test"]` ·
`subject_length = 50` · `line_length = 72` · `subject_capitalized = false` ·
`subject_not_punctuated = true` · `imperative_subject = false` · `merge_commit = false` ·
`ignore_author_re = "(dependabot|renovate)"` · `hard_line_length` left at its default `0`

Two settings need their reasoning stated rather than left to inference.
**`subject_capitalized = false`** is required, not cosmetic: `committed` defaults it to `true`,
which rejects every lower-case Conventional-Commits subject, so leaving it out breaks the
convention outright (verified — case 14 below). **`imperative_subject = false`** is a deliberate
departure from `clap` and `ratatui`, which leave it enabled: neither source repo enforces
imperative mood (commitlint has no such rule, so nothing in py or ts checks it), and turning it on
in rs would impose a *new* constraint this port never agreed to, failing messages that both source
repos accept. It can be enabled later as a separate, explicit decision.

Rule-by-rule justification against the ledger rows this item decides:

- **F149 (tool)** — `committed`, for the gate, adoption and maintainer-standing evidence above,
  and because it removes two of py's three measured silent-pass modes by construction.
- **F150 (invocation)** — `committed --fixup --wip --commit-file {1}` from the hook manager's
  `commit-msg` stage. `{1}` is the lefthook placeholder for the message-file path; the *stage
  wiring* belongs to R37, only the command is decided here. The two flags are **not optional
  decoration** — they are crate-ci's own canonical hook arguments
  ([`.pre-commit-hooks.yaml`](https://raw.githubusercontent.com/crate-ci/committed/master/.pre-commit-hooks.yaml):
  `args: [--fixup, --wip, --commit-file]`), and omitting them breaks a normal Rust workflow.
  Verified empirically (cases 15–16 below): without them, `git commit --fixup HEAD` is rejected at
  the hook with `Fixup commits must be squashed`, making `git rebase --autosquash` unusable. The
  flags relax those two rules **only at commit time**; the CI range check runs without them
  (`committed`'s action defaults to `-vv --no-merge-commit`, leaving `no_fixup`/`no_wip` at
  `true`), so a `fixup!` or WIP commit that survives to a pull request is still caught. That
  split — permissive locally, strict on the branch — is the correct division of labour between
  the hook and CI. No explicit-path gymnastics are needed because the npm resolution hazards that
  forced py's `bun ./node_modules/@commitlint/cli/cli.js` form do not exist for a static binary.
- **F151 (base config)** — `style = "conventional"`, `committed`'s built-in Conventional-Commits
  grammar, which is the structural analogue of `extends: ['@commitlint/config-conventional']`.
- **F152 (header cap) = 50.** Adopts ts's value and rejects py's inherited 100. Authority: Git's
  own documentation ("no more than 50 characters", `git-commit` DISCUSSION) and Pro Git. It is
  also `committed`'s default and the value `clap`, `toml`, `typos` and `env_logger` all run on.
  Class A / harmonize-yes, so this is proposed as the value for **all three repos**.
- **F153 (body cap) = 72.** Adopts ts's value and rejects py's 200. Authority: Pro Git, "Wrap it
  to about 72 characters or so". py's 200 was a workaround for whole-line counting; soft-line
  measurement removes the need, as case 05 proves. Proposed for all three repos.
- **A second parity gap, named rather than discovered later: `committed` cannot *require*
  lower-case subjects.** `@commitlint/config-conventional` ships
  `subject-case: [2, 'never', [sentence-case, start-case, pascal-case, upper-case]]`, so py and ts
  both **reject** `feat(cli): Add a thing`. `committed` offers only `subject_capitalized`, a
  require-capitals switch; setting it to `false` stops *requiring* capitals but does not *forbid*
  them. Verified (case 19 below): `feat(cli): Add a capitalised subject` exits **0** under the
  recommended config. Consequence: rs will accept a small set of messages py and ts reject. This
  is accepted as cosmetic — it affects neither machine parsing, the type enum, nor changelog
  generation, and no surveyed Rust tool offers the rule — but it is a real, stated divergence
  rather than an oversight, and the `.gitmessage` template should show lower-case subjects so the
  documented convention stays unambiguous.
- **F154 (footer cap) = 72, via the same `line_length` rule.** `committed` has **no separate
  footer setting** — a real parity gap with commitlint, stated plainly. It is an acceptable one:
  `line_length` applies to every line including footers, so footers are capped at the same 72;
  and the footers that motivated py's 200 (long permalink URLs and trailers such as
  `Claude-Session: <url>`) are exactly the un-wrappable single tokens that soft-line measurement
  exempts. The observable outcome py wanted is preserved; only the second knob is lost.
- **F155 (type enum) = the 11 members.** Both sources already converge here: py inherits
  `@commitlint/config-conventional`'s `type-enum`, whose source lists exactly
  `build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test`, and ts spells out an
  11-entry array. `committed`'s default is only **8** (`fix, feat, chore, docs, style, refactor,
  perf, test` — missing `build`, `ci`, `revert`), so `allowed_types` **must** be set explicitly.
  Independent confirmation that this is the right list for a Rust project:
  `ratatui/ratatui`'s `committed.toml` sets exactly these 11 and annotates the 8-member default.
- **F156 (bot exemption) = `ignore_author_re = "(dependabot|renovate)"`.** This is a **strict
  improvement** over py's approach. py needs a whole second config file
  (`commitlint.dependabot.config.mjs`) selected in CI by PR-author login; `committed` expresses it
  as one regex in the single config, and — verified empirically — it applies on the CI
  commit-range path (where the author is known) and *not* on the `--commit-file` hook path (where
  there is no author), which is exactly the desired split. No CI-side config swap is required.
  The identical line appears in `clap`, `toml`, `typos`, `env_logger` and `committed`'s own config.
- **F157 (CI re-run) = yes.** Justification is the one ts's absence demonstrates: `git commit
  --no-verify` bypasses any local hook, and ts has nothing in CI to catch it. `committed` ships an
  **official GitHub Action** — an `action.yml` at the repository root, a composite action with
  `args` (default `-vv --no-merge-commit`) and `commits` (default `HEAD~..HEAD^2`) inputs — so
  CI does not have to shell out to a separately installed binary. Use the `clap` recipe
  (`on: [pull_request]`, `actions/checkout` with `fetch-depth: 0`, then the action), but **pin the
  action to a commit SHA** rather than the `@master` that both `clap` and `committed` use, to
  satisfy R20 (`third-party-action-pinning-policy`).

### Ranked runner-up

**1. `git-sumi`** — the only other tool surveyed that can express this item's whole contract
(`types_allowed`, `max_header_length`, `max_body_length`). **The condition under which it wins:**
`committed` stops being maintained — no release beyond `1.1.11` by roughly 2027-03 *and* issue
responsiveness degrading toward `cocogitto`'s pattern — while `git-sumi` keeps its current
activity and grows an adoption base. Adopting it would cost three things that must be accepted
knowingly: the body cap would have to be **raised above 72** (its `validate_line_length` counts
whole lines including URLs, so py's 200-column workaround would return), F156's bot exemption
would move from one config line to a CI-side environment-variable override, and gate 2 would stay
unmet until it declares a `rust-version`.

**2. commitlint via a provisioned Node/Bun runtime** — the *architectural* runner-up. **The
condition under which it wins:** R37 (`hook-manager-distribution`) or R42
(`dev-toolchain-provisioning`) independently decide to provision a JS runtime for other reasons.
If a Node/Bun runtime is already present and lockfile-managed for some other tool, commitlint's
marginal cost collapses to one devDependency and its advantages become real — byte-identical rule
configuration with both source repos, a genuine separate footer cap (closing the F154 parity gap),
and the `wagoid/commitlint-github-action` CI path py already uses (402 stars, `pushed_at`
2026-02-14). This report does **not** decide R37 or R42; it records the dependency in that
direction only, and notes that adopting commitlint would also re-import the three measured
silent-pass modes catalogued above.

**3. `commitlint-rs`** — wins if it reaches 1.0 with restored releases and issue triage, because
it alone could give all three repos one rule-configuration format with no runtime.

**4. `convco` / `cocogitto`** — win **only** if the owner drops the length half of
`commit-message-convention`, since neither enforces any width rule. On popularity `cocogitto`
leads the whole field (1,184 stars, 219,448 all-time downloads); it is ranked last here because
the prompt's ordering puts gates and capability ahead of popularity, and on capability it cannot
do the job. If the length caps were ever dropped, `convco` would be preferred over `cocogitto`
on the maintenance rubric (0 open issues and a 0.28-day median, against ten consecutive
unanswered issues).

### Tradeoffs

**What the pick gives up versus `git-sumi` (the capability peer).** `git-sumi` was pushed the day
of this survey, against `committed`'s six-month-old release, and it offers a *separate* header and
body knob with per-line body semantics that some reviewers find easier to reason about. Accepted
because the exchange is lopsided: `committed` brings 1.0+ stability, dual licensing that exactly
matches the `license` parameter, a declared MSRV, `clap`/`ratatui`/`toml`/`env_logger`/`typos`
adoption against none identified for `git-sumi`, an author-based bot exemption `git-sumi` lacks
entirely, and — decisively — soft-line measurement, without which the body cap must rise above 72
and py's URL workaround returns.

**What the pick gives up versus `convco` and `cocogitto` (the popular options).** Responsiveness
in `convco`'s case (0 open issues against 22) and raw popularity in `cocogitto`'s (1,184 stars
against 182). Accepted because neither can enforce a length limit at all, so choosing either means
either abandoning half of the parameter this item owns or running a second tool beside it. A
6.4-month release gap on a mature tool, investigated and found to have commits through 2026-09-01
and a 0.28-day median response, is a far smaller cost than a missing capability.

**What the pick gives up versus commitlint.** Three things, all named. (i) **Config-file identity
with py and ts** — `committed.toml` is not `commitlint.config.mjs`, so the three repos will hold
the same contract in different syntax. Accepted because `docs/port/BASELINE-REVIEW.md:75` sets the
agreement level at capability/standard, and `DIVERGENCE-ANALYSIS.md:155` classes the tool as
class B (language-bound); the *values* still converge, which is what harmonize-yes on F152–F155
actually asks for. (ii) **A separate footer cap** — accepted, with the reasoning in F154 above:
the outcome survives, only the knob is lost, and no surveyed Rust tool has a separate footer cap
either, so this is a property of the whole native field rather than of this pick. (iii) **A rule
ecosystem** — commitlint has many more rules and a plugin API. Accepted because this template
needs seven rules, all of which `committed` has, and an unused plugin API is not a benefit. In
exchange the template gives up a Node/Bun runtime requirement (`engines.node >= 22.12.0`), a
`package.json`, a JS lockfile in a Rust repository, and two of py's three measured silent-pass
failure modes.

**The residual risk the pick introduces, and its mitigation.** Binary version drift: `cargo
install` is global with no per-repo lockfile, so a developer can hold a different `committed`
version than the template expects — the one py failure mode that survives, in weakened form.
Mitigated by pinning the version in the install recipe, asserting `committed --version`, and
pinning the CI action by SHA so CI remains the authority. Also carried: the unreported
`hard_line_length` defect, neutralized by leaving that setting at its default `0`.

### Parameters

`owns commit-message-convention = { type-enum: ["build","chore","ci","docs","feat","fix","perf","refactor","revert","style","test"], header-max-length: 50, body-max-line-length: 72, footer-max-line-length: 72, length-semantics: "soft-line — the un-wrappable trailing token of a line is exempt from the cap, so a bare URL never violates it" }`

The `length-semantics` clause is part of the parameter value, not commentary: a consumer that
re-implements these caps with whole-line counting would reject messages this template accepts,
so the semantics travel with the numbers.

Downstream compatibility, verified rather than asserted: every one of the 11 types is present in
`DEFAULT_COMMIT_TYPES` in
[`conventional-changelog-conventionalcommits/src/constants.js`](https://raw.githubusercontent.com/conventional-changelog/conventional-changelog/master/packages/conventional-changelog-conventionalcommits/src/constants.js)
(retrieved 2026-09-05) — the preset release-please consumes by default — each already carrying a
`section` name and a `bump`/`hidden` effect (`feat`→Features/bump, `fix`→Bug Fixes/bump,
`perf`→Performance Improvements/bump, `revert`→Reverts/bump, and `docs`, `style`, `chore`,
`refactor`, `test`, `build`, `ci` as hidden sections). So the enum maps to changelog sections
**with no renaming**, which is what R38 owes R24. Choosing *which* sections are visible remains
R24's decision and is not made here.

`assumes` — none. This item's `- consumes:` list in `## Couplings` is empty; it depends on no
researched parameter.

**No `CONFLICT:` lines.** No recommendation here requires a consumed parameter to change, and all
four fixed owner parameters (`rust-edition` 2024, the MSRV policy, `target-os-matrix`,
`license`) are satisfied by the pick rather than strained by it.

**No `BASELINE-REVIEW:` lines.** F148 and F159 are not challenged; F158 and F160 are fulfilled.

### Migration implications

File-level changes in `rs-launch-blueprint`. R37 owns the hook-manager file itself; the rows below
name the *content* this item contributes.

1. **`committed.toml`** (new, repository root — the location `committed` auto-discovers). Holds
   the nine settings listed in `### Recommendation`. This file is the machine-readable home of
   the `commit-message-convention` parameter, and it is load-bearing: verified empirically that
   *without* it `committed` falls back to `style = "none"` and `subject_capitalized = true`, under
   which a plain `ci(deps): bump actions/checkout to v6` **fails**. A published JSON Schema
   ([`config.schema.json`](https://raw.githubusercontent.com/crate-ci/committed/master/config.schema.json))
   is available for editor validation.
2. **Hook manager config** (`lefthook.yml`, owned by R37) — a `commit-msg` stage job running
   `committed --fixup --wip --commit-file {1}`. This item supplies only the command string; the
   two flags are load-bearing, per F150 above.
3. **`.github/workflows/commit-lint.yml`** (new) — `on: [pull_request]`,
   `permissions: contents: read`, `actions/checkout` with `fetch-depth: 0`, then
   `uses: crate-ci/committed@<commit-sha>` pinned per R20. Modeled on
   `clap-rs/clap/.github/workflows/committed.yml`. Whether this is its own workflow or a job
   inside an existing one is R11's (`ci-job-structure`) call, not this item's.
4. **`.gitmessage`** (new — this is the content F158 was blocked on). It must document exactly
   the 11 types and the two length caps, so that the template and the linter state one
   convention. Required content: a comment-only template (every line prefixed `#`, so an
   unedited template produces an empty message that git aborts) carrying (a) the
   `<type>(<scope>): <subject>` form, (b) the subject rule — imperative, lower-case, no trailing
   period, **≤ 50 characters**, (c) the body rule — blank line first, **wrap at 72**, (d) the
   footer rule — `BREAKING CHANGE:` and issue trailers, and (e) the literal 11-item type list
   with one-line glosses: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`,
   `revert`, `style`, `test`. F159 wires it with `git config commit.template .gitmessage` and
   is unchanged by this item.
5. **Repo-hygiene meta-test** (this is the adapter F160 was blocked on). A Rust integration test
   that parses `committed.toml` with the `toml` crate, extracts `allowed_types`, extracts the
   type list from `.gitmessage`, and asserts set equality — the direct analogue of ts's
   `tests/repo-hygiene.test.ts:19-34`, which imports commitlint's configuration for the same
   purpose. It should additionally assert `subject_length == 50` and `line_length == 72` against
   the values quoted in `.gitmessage`, so a change to either file without the other fails. The
   file locates the repo root from `CARGO_MANIFEST_DIR`; **where** the meta-suite lives follows
   R02's crate topology, per `docs/port/BASELINE-REVIEW.md:70`.
6. **Contributor documentation and install recipe** — `CONTRIBUTING.md` states the convention;
   the toolchain recipe installs `committed` at the pinned version, preferring the prebuilt
   release binary and falling back to `cargo install committed --locked --version <pin>`. The
   invocation form (`cargo` subcommand versus provisioned binary on PATH) is R42's
   `package-manager-invocation` decision; this item only requires that the resulting command be
   `committed`.
7. **No `package.json`, no JS lockfile, no `node_modules`, no `commitlint.config.mjs`, and no
   `commitlint.dependabot.config.mjs`** — the four artifacts py carries for this capability, and
   the second config file py needs for F156, all disappear.

### Validation strategy

**Executed 2026-09-05** on this host (Darwin 25.4.0, arm64; rustc 1.98.0). Twenty checks were
run; these are results, not proposals. Setup: `cargo install committed --locked --root ./tools --version 1.1.11`
(28.7 s wall, 175 s CPU, 3.7 MB binary), a throwaway `git init` repository, and the recommended
`committed.toml`.

Message-file path (`committed --commit-file <path>`), the `commit-msg` hook contract:

| # | Message under test | Expected | Observed exit | Observed message |
|---|---|---|---|---|
| 01 | `feat(cli): add --json output flag` + conforming 2-line body | 0 | **0** | — |
| 02 | `wibble(cli): ...` (type not in the enum) | 1 | **1** | ``Disallowed type `wibble` used, please use one of ["feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore", "revert"]`` |
| 03 | 71-character subject | 1 | **1** | `Commit subject is too long, 71 exceeds the max length of 50` |
| 04 | body line of 89 columns | 1 | **1** | `Line is too long, 89 exceeds the max length of 72` |
| 05 | **body line = one 150-char documentation permalink** | **0** | **0** | — (the decisive case: strict `line_length = 72` still accepts an un-wrappable URL) |
| 06 | subject ending in `.` | 1 | **1** | ``Subject should not be punctuated but found `.` `` |

Commit-range path (`committed HEAD` / `committed HEAD~..HEAD`), the CI contract:

| # | Scenario | Expected | Observed exit |
|---|---|---|---|
| 07 | conforming commit, `committed HEAD` | 0 | **0** |
| 08 | `wibble:` commit authored by a human | 1 | **1** (type rejected) |
| 09 | the **same** bad commit re-authored as `dependabot[bot]` | 0 (exempt) | **0** — `ignore_author_re` works on the range path |
| 10 | range form `committed HEAD~..HEAD` | 0 | **0** |
| 11 | a dependabot-style bad message through `--commit-file` | 1 (no author in a message file) | **1** — exemption correctly does *not* leak into the hook path |

Hook-ergonomics, subject-case and defect-reproduction checks (all executed):

| # | Scenario | Expected | Observed |
|---|---|---|---|
| 15 | `fixup! feat(cli): ...` **without** `--fixup --wip` | rejected | exit **1**, `Fixup commits must be squashed` — proves the bare `--commit-file` form would break `git commit --fixup` + `git rebase --autosquash` |
| 16 | the same message **with** `--fixup --wip` (crate-ci's canonical hook args) | accepted at commit time | exit **0** |
| 17 | `WIP: still working` without the flags | rejected | exit **1**, `Work-in-progress commits must be cleaned up` |
| 18 | the same WIP message with the flags | still rejected, but for the *conventional-format* rule rather than the WIP rule | exit **1**, `Missing type in the commit summary` — the flags relax only the fixup/WIP rules, they do not disable the grammar |
| 19 | `feat(cli): Add a capitalised subject` | **0** — `committed` has no `subject-case` rule | **0**, confirming the second parity gap against `@commitlint/config-conventional` |
| 20 | `line_length = 72`, `hard_line_length = 200`, a 100-char space-free line | should pass at 200 | exit **1**, `Line is too long, 100 exceeds the max length of 72` — **reproduces the `checks.rs:98-100` defect on 1.1.11** and shows it also voids the URL exemption |

Failure-mode and configuration checks:

| # | Scenario | Expected | Observed |
|---|---|---|---|
| 12 | binary absent from `PATH` | loud failure, never a silent pass | exit **127** — the hook fails, matching py's mode 1 but with no interpreter-shim ambiguity |
| 13 | config auto-discovery with no `--config` flag | repo-root `committed.toml` is found | **found** (case 02 reproduced without `--config`) |
| 14 | **no** `committed.toml` present | defaults differ materially | `ci(deps): bump actions/checkout to v6` **fails** with `Subject should be capitalized` — proving the config file is load-bearing and giving the F160 meta-test a real oracle |

**Planned, not yet executed** (stated separately as the prompt requires):
- The same 20 checks on `ubuntu-latest` and `macos-latest` GitHub runners. Confidence is high but
  the evidence here is indirect: `committed`'s own CI already runs `ubuntu-latest`,
  `macos-latest` and `windows-latest`, and cases 01–20 were executed on macOS locally; Linux was
  not exercised by me.
- End-to-end wiring through the hook manager's `commit-msg` stage with the `{1}` placeholder and
  the `--fixup --wip` flags —
  blocked on R37's choice of manager, and correctly out of this item's scope.
- The `crate-ci/committed` action pinned by SHA in a live pull request.
- The F160 meta-test asserting `committed.toml` ↔ `.gitmessage` equality — specified above,
  not written, since no Rust crate exists in the template yet.

### Confidence & re-verify trigger

**Confidence: high** on the tool choice; **high** on the type enum; **medium-high** on the length
values.

The tool choice rests on executed behavior rather than documentation alone, on gates that all
passed with primary-source citations, and on adoption by the exact projects this template
resembles. The enum is corroborated three independent ways: `@commitlint/config-conventional`'s
source (what py inherits), ts's explicit array, and `ratatui`'s `committed.toml` (an independent
Rust project reaching the same 11) — and it is verified to map onto release-please's preset
without renaming. The lengths are one notch lower because 50/72 is a *convention* with authority
(Git's documentation and Pro Git) rather than a measurement, and because F152–F154 are class-A
harmonize-yes rows whose final values are an owner call across three repos; what this report
settles is that the technical objection to 72 (long URLs) is dissolved by soft-line measurement,
which removes py's reason for 200.

Re-verify if any of the following occurs:

1. **`committed` releases nothing beyond `1.1.11` by roughly 2027-03** (one year after the current
   release) **or** its issue responsiveness degrades toward the `cocogitto` pattern — re-run the
   maintenance rubric and reconsider `git-sumi`, accepting the body-cap and bot-exemption costs
   recorded in `### Ranked runner-up`. Do **not** fall back to `convco` or `cocogitto` without
   first re-checking whether they have gained length enforcement, which they lack today.
2. **The `hard_line_length` defect at `checks.rs:98-100` is fixed** — then `hard_line_length`
   becomes usable as a genuine absolute ceiling and is worth reconsidering as an anti-abuse cap.
   Conversely, if a future release changes the **soft-line measurement** itself, the F153/F154
   rationale collapses and the 72 value must be revisited immediately — this is the single most
   important thing to re-check on any `committed` upgrade.
3. **R37 or R42 decides to provision a Node/Bun runtime** for another tool — re-weigh commitlint,
   whose marginal cost would then be one devDependency.
4. **`commitlint-rs` reaches 1.0 with restored release binaries and recovered issue triage** — it
   would offer commitlint config parity without a runtime, the best available answer for
   cross-repo config unification. Check whether
   `GET https://api.github.com/repos/KeisukeYamashita/commitlint-rs/releases/latest` has a
   non-empty `assets` array; it was empty on 2026-09-05.
5. **`git-sumi` declares a `rust-version` and gains adoption** — it would then clear gate 2 and
   become a fully qualified alternative rather than a conditional one.
6. **A major-version `committed` 2.x appears** — the recommended range `<2.0.0` deliberately
   excludes it pending a config-compatibility review.
7. **A RustSec advisory is published for `committed` or `git2`** — `https://rustsec.org/packages/committed.html`
   returns 404 today; a 200 there is a re-verify trigger.

### Sources

Primary specifications and authorities
- Conventional Commits v1.0.0 — https://www.conventionalcommits.org/en/v1.0.0/ (2026-09-05)
- `git-commit` documentation, DISCUSSION — https://git-scm.com/docs/git-commit (2026-09-05)
- Pro Git, *Distributed Git — Contributing to a Project*, Commit Guidelines — https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project (2026-09-05)
- Git hooks reference — https://git-scm.com/docs/githooks (2026-09-05)
- Rust stable channel manifest (current stable 1.98.1, manifest date 2026-09-03) — https://static.rust-lang.org/dist/channel-rust-stable.toml (2026-09-05)
- rust-lang Cargo team roster — https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml (2026-09-05)

`committed` (recommended)
- Reference documentation — https://github.com/crate-ci/committed/blob/master/docs/reference.md (2026-09-05)
- README, install and CI usage — https://raw.githubusercontent.com/crate-ci/committed/master/README.md (2026-09-05)
- `checks.rs` (soft-line measurement at `:147-171`; `hard_line_length` dispatch defect at `:98-100`) — https://raw.githubusercontent.com/crate-ci/committed/master/crates/committed/src/checks.rs (2026-09-05)
- Workspace `Cargo.toml` (edition 2024, `rust-version = "1.89"`, `license = "MIT OR Apache-2.0"`) — https://raw.githubusercontent.com/crate-ci/committed/master/Cargo.toml (2026-09-05)
- Crate `Cargo.toml` (dependencies, single `unstable-schema` feature) — https://raw.githubusercontent.com/crate-ci/committed/master/crates/committed/Cargo.toml (2026-09-05)
- `action.yml` (official composite GitHub Action) — https://raw.githubusercontent.com/crate-ci/committed/master/action.yml (2026-09-05)
- `.github/workflows/ci.yml` (OS matrix ubuntu/windows/macos) — https://raw.githubusercontent.com/crate-ci/committed/master/.github/workflows/ci.yml (2026-09-05)
- `.pre-commit-hooks.yaml` (canonical `commit-msg` args) — https://raw.githubusercontent.com/crate-ci/committed/master/.pre-commit-hooks.yaml (2026-09-05)
- `config.schema.json` — https://raw.githubusercontent.com/crate-ci/committed/master/config.schema.json (2026-09-05)
- Own `committed.toml` — https://raw.githubusercontent.com/crate-ci/committed/master/committed.toml (2026-09-05)

Adoption evidence
- `clap-rs/clap` — https://raw.githubusercontent.com/clap-rs/clap/master/committed.toml · https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/committed.yml · https://raw.githubusercontent.com/clap-rs/clap/master/.pre-commit-config.yaml (2026-09-05)
- `ratatui/ratatui` (the 11-member `allowed_types`) — https://raw.githubusercontent.com/ratatui/ratatui/main/committed.toml (2026-09-05)
- `rust-cli/env_logger` — https://raw.githubusercontent.com/rust-cli/env_logger/main/committed.toml (2026-09-05)
- `toml-rs/toml` — https://raw.githubusercontent.com/toml-rs/toml/main/committed.toml (2026-09-05)
- `crate-ci/typos` — https://raw.githubusercontent.com/crate-ci/typos/master/committed.toml (2026-09-05)

Downstream and source-repo evidence
- `@commitlint/config-conventional` `type-enum` — https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/config-conventional/src/index.ts (2026-09-05)
- `conventional-changelog-conventionalcommits` `DEFAULT_COMMIT_TYPES` — https://raw.githubusercontent.com/conventional-changelog/conventional-changelog/master/packages/conventional-changelog-conventionalcommits/src/constants.js (2026-09-05)
- py-launch-blueprint `lefthook.yml` at pinned `b08bccf` (the three measured silent-pass modes, lines 18-58) — https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/b08bccf/lefthook.yml (2026-09-05)
- `@commitlint/cli` 21.2.2, `engines.node >= 22.12.0` — https://registry.npmjs.org/@commitlint/cli (2026-09-05)

Runner-up and excluded-candidate evidence (all 2026-09-05)
- `convco` — `src/cmd/check.rs` (the only `len()` is display truncation in `print_fail`) — https://raw.githubusercontent.com/convco/convco/main/src/cmd/check.rs · `src/conventional/config.rs` — https://raw.githubusercontent.com/convco/convco/main/src/conventional/config.rs · `Cargo.toml` (MSRV 1.87, MIT) — https://raw.githubusercontent.com/convco/convco/main/Cargo.toml · docs — https://convco.github.io/check/
- `cocogitto` — `crates/cocogitto/src/settings/mod.rs` (`Settings` has no length field; `deny_unknown_fields`) — https://raw.githubusercontent.com/cocogitto/cocogitto/main/crates/cocogitto/src/settings/mod.rs · `Cargo.toml` (MSRV 1.78.0, MIT) — https://raw.githubusercontent.com/cocogitto/cocogitto/main/Cargo.toml · official action — https://github.com/cocogitto/cocogitto-action
- `git-sumi` — `src/lint.rs` `validate_line_length` (whole-line `chars().count()`) — https://raw.githubusercontent.com/welpo/git-sumi/main/src/lint.rs · `src/config.rs` — https://raw.githubusercontent.com/welpo/git-sumi/main/src/config.rs · `Cargo.toml` (no `rust-version`) — https://raw.githubusercontent.com/welpo/git-sumi/main/Cargo.toml · official action — https://github.com/welpo/git-sumi-action
- `commitlint-rs` — `cli/src/rule/body_max_length.rs` (whole-body `String::len()` in bytes) — https://raw.githubusercontent.com/KeisukeYamashita/commitlint-rs/main/cli/src/rule/body_max_length.rs · `cli/src/config.rs` — https://raw.githubusercontent.com/KeisukeYamashita/commitlint-rs/main/cli/src/config.rs · `Cargo.toml` (no `rust-version`) — https://raw.githubusercontent.com/KeisukeYamashita/commitlint-rs/main/Cargo.toml · empty release assets — `GET https://api.github.com/repos/KeisukeYamashita/commitlint-rs/releases/tags/v0.2.4`
- `wagoid/commitlint-github-action` — `GET https://api.github.com/repos/wagoid/commitlint-github-action`

Repository context consulted (not modified)
- `docs/port/COMMONALITY.md:152-164` (F148-F160) · `docs/port/DIVERGENCE-ANALYSIS.md:155-162` (R38 rows and cause classes) · `docs/port/BASELINE-REVIEW.md:70,75-78` (F141, F148, F158-F160) · `docs/port/PARAMETERS.md` (fixed parameters) · `research/RUNBOOK.md` · `research/CLAUDE.md`

**Method notes.** Figures were taken from the endpoints the prompt's evidence table prescribes,
all on 2026-09-05: `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `/versions` (newest `yanked: false`) with a User-Agent header;
`GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`);
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`, never
`open_issues_count` — the two differ materially, e.g. `cocogitto` reports 70 versus 56 and
`commitlint-rs` 48 versus 13, because the raw field counts pull requests);
`GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus each
issue's `/comments` for responsiveness; `https://rustsec.org/packages/<name>.html` for advisories;
`GET https://api.github.com/search/code?q=filename:committed.toml` for adopters; and
`https://registry.npmjs.org/@commitlint/cli` for the npm alternative. The landscape was built from
`GET https://crates.io/api/v1/crates?q=<term>` over four query terms and
`GET https://api.github.com/search/repositories?q=topic:conventional-commits+language:rust`, not
from recall. RustSec 404s were **control-tested** the same day against `time`, `openssl` and
`atty`, which return 200 — so a 404 here means "no advisories", not a failed endpoint. The
empirical checks in `### Validation strategy` were executed locally on macOS against
`committed 1.1.11` installed from crates.io. The competitor configuration-parity cells
(type enum, header cap, body cap, footer cap, bot exemption, single-file invocation, official
action, prebuilt binaries, MSRV/licence/edition, and length semantics) were read from each
project's own manifest, configuration struct and check implementation on the default branch; the
three discriminating claims — that `convco check` and `cog check` enforce no length limit and that
`git-sumi` counts whole lines — were then re-verified directly against
`convco/src/cmd/check.rs`, `cocogitto/crates/cocogitto/src/settings/mod.rs` and
`git-sumi/src/lint.rs` rather than accepted from documentation.

Not verified, and recorded as such: (i) the 20 empirical cases were run only on macOS — Linux
behavior is inferred from `committed`'s own three-OS CI matrix, not observed by me; (ii) npm
advisory status for `@commitlint/cli` was not audited, since the RustSec endpoint does not cover
npm; (iii) adopter sets for `convco`, `cocogitto` and `git-sumi` were not enumerated to recommendation
standard, since none of them is the pick — `git-sumi` in particular is recommended as a
conditional runner-up on capability grounds with **no** identified adopters, which is part of why
it is not the pick; (iii-b) the MSRV of `git-sumi` and `commitlint-rs` is not merely old but
**undeclared**, so gate 2 is unmet rather than passed for both; (iv) `commitfmt`'s crates.io `repository` field points at
`jfernandez/commitfmt` while the GitHub topic search surfaced `mishamyrt/commitfmt`, and that
discrepancy was not resolved; (v) `conventional-commits-check` is hosted on Codeberg, so the
prescribed GitHub figures are inapplicable rather than collected; (vi) issue-responsiveness
medians use the 10 most recently opened issues per the prompt, which is a small sample and is
reported with its unanswered count rather than as a point estimate alone.
