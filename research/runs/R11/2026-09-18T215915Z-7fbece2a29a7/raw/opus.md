# R11 — ci-workflow-job-structure (bundle) — Opus raw research report

Engine: claude-opus-5. Retrieval dates are UTC. Source repositories are read at
the programme pins: `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. Every claim
labelled **executed** was run on this host on 2026-09-18; everything else is
labelled **proposed**, **read** or **carried**.

Host for every executed check: macOS 26.4 `arm64`; `actionlint` **1.7.12**
(`/opt/homebrew/bin/actionlint`, "built with go1.26.1 compiler for darwin/arm64");
`gh` 2.98.0 for GitHub REST; `curl` for crates.io, rustsec.org and
`raw.githubusercontent.com`. Scratch lived under a directory this run created
inside `$TMPDIR` and nothing was written outside the one output path.

### Landscape

**The category this item decides.** Not a crate. It is the *shape of a CI job
graph* and the *mechanism by which a run scopes itself to what changed*: which
GitHub Actions jobs exist in `.github/workflows/ci.yml`, what `needs:` edges join
them, and how a detector job makes heavy jobs skip on a pull request that cannot
affect them. Everything inside a step — which formatter, which linter, which test
runner — belongs to another item and is treated here as a *slot*, a named job or
step position with a stated rule for filling it.

**Bin 1 — built-in or first-party toolchain.** These are the primitives the
decision is built from, and all of them are GitHub's own or Cargo's own.

| Primitive | What it gives this item | Source |
|---|---|---|
| `jobs.<job_id>.needs` | ordering plus the `needs` context that carries a detector's outputs | GitHub Docs, workflow syntax, read at `github/docs` commit `1fa3a6df3560daedd7c8a69e8eff1a730b58c1af` (2026-09-18) |
| `jobs.<job_id>.if` | per-job skip, evaluated **before** `strategy.matrix` is applied | same commit, `section-using-conditions-to-control-job-execution.md` |
| `jobs.<job_id>.outputs` | the string map a detector publishes | same commit, `section-defining-outputs-for-jobs.md` |
| `on.<push\|pull_request>.paths` / `paths-ignore` | whole-**workflow** path filtering | same commit, `triggering-a-workflow-paths1.md` |
| `concurrency` + `cancel-in-progress` | superseded-run cancellation | same commit, `section-using-concurrency.md` |
| `strategy.matrix` | the `target-os-matrix` fan-out | same commit |
| Cargo scoping — `-p`, `--workspace`, `--features`, `--locked` | which members and which feature configuration a step compiles | Cargo Book |
| `git diff --name-only <base>...HEAD` in a `run:` step | a first-party, dependency-free change detector | git, plus `actions/checkout` `fetch-depth: 0` |

**Bin 2 — established industry standard.** Four patterns are standard enough that
a reader of mainstream Rust CI meets them immediately.

1. **A hand-rolled detector job publishing literal `true`/`false` outputs**, consumed
   by dependents through `needs` and a positive `if` predicate. This is what both
   of the most relevant precedents do: `py-launch-blueprint` at the pin
   (`.github/workflows/ci.yml:32-77`, whose own comment reads
   "Shell-based (same pattern as large-file-guard) - no third-party action") and
   `astral-sh/uv` (`.github/workflows/plan.yml`, a 249-line reusable workflow
   emitting eighteen such outputs, retrieved 2026-09-18).
2. **`dorny/paths-filter`**, the long-standing third-party detector action.
3. **A dedicated always-run cheap job per non-compiling check** — `rustfmt` as its
   own job is near-universal (`ripgrep`, `clap`).
4. **One aggregate job that all others feed** — `bat`'s `all-jobs`, `clap`'s `ci`,
   py's `ci-ok`. **That one is R12's, not this item's**, and is named here only
   because its correctness constrains what this item may emit.

**Bin 3 — up-and-comers.**

- **`tj-actions/changed-files`**, the newer detector action. It carries a
  disqualifying history: **GHSA-mrrh-fwg8-r2c3 / CVE-2025-30066**, severity
  `high`, published `2025-03-15T06:30:34Z`, summary "tj-actions changed-files
  through 45.0.7 allows remote attackers to discover secrets by reading actions
  logs", vulnerable range `<= 45.0.7`, first patched `46.0.1`
  (`GET https://api.github.com/advisories/GHSA-mrrh-fwg8-r2c3`, retrieved
  2026-09-18T22:16:11Z).
- **Third-party hosted runners** substituted for GitHub's — `astral-sh/uv` runs its
  plan job on `depot-ubuntu-24.04`. Out of scope: `target-os-matrix` is owner-fixed.
- **Merge-queue-aware gating** via the `merge_group` event, which py added at the pin
  with the comment "the merge queue emits merge_group (not pull_request) for its
  speculative merge — without this trigger the ci-ok required check never reports
  and every queue entry deadlocks at 'Expected'" (`ci.yml:14-19`).

**Authorities used, and why each is authoritative.**

| Source | Why it counts | Retrieved |
|---|---|---|
| GitHub Docs content read from `github/docs` at commit `1fa3a6df3560daedd7c8a69e8eff1a730b58c1af` | the platform vendor's own documentation, read at a pinned commit rather than from a rendered page, so the quotations are reproducible | 2026-09-18 |
| The Cargo Book, *Continuous Integration* (`https://doc.rust-lang.org/cargo/guide/continuous-integration.html`) | a Rust **project** publication — the language team's own guidance on what a Rust CI workflow should contain | 2026-09-18 |
| `rustsec.org` package pages | the Rust Security Response WG's advisory database | 2026-09-18 |
| `actionlint` 1.7.12, the maintainer's own linter (`rhysd/actionlint`, 4,240 stars, not archived, `pushed_at` 2026-07-16T06:05:57Z; `GET https://api.github.com/repos/rhysd/actionlint`, 2026-09-18T22:16:34Z) | it type-checks `needs` relays and context availability, so it converts several design claims here from assertion into an executed result | executed 2026-09-18 |
| This programme's own executed checks — R02 check `B3`, R10 assertions `A3.6`/`A3.8`, R86 checks `G01`–`G04` | results already run against this template's own design, cited rather than re-run | as dated in those runs |

A single blog post was not used as an authority anywhere in this report.

**Practice evidence — well-regarded Rust projects surveyed.** Workflow files were
fetched from `raw.githubusercontent.com` on each project's default branch on
2026-09-18; star, archive and `pushed_at` figures come from
`GET https://api.github.com/repos/<o>/<r>` at 2026-09-18T22:10:09Z.

| Project | Stars | Archived | `pushed_at` | CI job ids | Change detector? | Workflow `concurrency`? | Why it is a relevant, well-regarded reference |
|---|---|---|---|---|---|---|---|
| `astral-sh/uv` | 89,957 | false | 2026-09-18T20:07:44Z | 22 in `ci.yml`, all but one calling a reusable workflow | **yes** — a `plan` job, hand-rolled `git diff`, 18 literal outputs | yes, `${{ github.workflow }}-${{ github.ref_name }}-${{ github.event.pull_request.number \|\| github.sha }}` | the highest-adoption new Rust CLI in the ecosystem, and a workspace-of-crates CLI shipping release binaries — the closest structural analogue to this template |
| `BurntSushi/ripgrep` | 68,414 | false | 2026-08-04T13:59:44Z | 5 (`test`, `wasm`, `rustfmt`, `docs`, `fuzz_testing`) | no | no | the canonical Rust CLI; its split is exactly compile-tier versus no-compile tier |
| `sharkdp/bat` | 60,499 | false | 2026-09-04T19:10:30Z | 10, including `all-jobs`, `lint`, `min_version`, `license_checks` | no | not in `CICD.yml` | a Rust CLI that ships binaries and keeps an explicit MSRV job (`min_version`) |
| `tokio-rs/tokio` | 33,173 | false | 2026-09-18T02:53:10Z | 30+ | no | yes | the ecosystem's most-depended-on runtime; the far end of per-check job splitting |
| `tokio-rs/axum` | 27,176 | false | 2026-09-18T19:05:20Z | 13 (`check`, `check-docs`, `cargo-hack`, `test-msrv`, `deny-check`, …) | no | not in `CI.yml` | the framework R69 selected, so its CI is the closest web-surface precedent |
| `clap-rs/clap` | 16,712 | false | 2026-09-18T15:42:38Z | 12, including `ci`, `rustfmt`, `clippy`, `docs`, `lockfile`, `minimal-versions` | no | yes | the CLI-parser crate R60 selected; a workspace with an aggregate `ci` job |

**The reading of that table that matters.** Five of six surveyed projects split by
check and have **no** change detector at all — and every one of them is a *library or
tool repository whose entire content is code*. The one project whose repository also
carries a large prose-and-docs tree, `astral-sh/uv`, is the one that built a
detector. `py-launch-blueprint`, a template with `docs/`, is the other. That is the
fit signal, not the raw count: the detector earns its keep in proportion to how much
of the repository is not code, and a *template* is mostly not code.

### Principles and implementation

**The shared requirement, its source, and the agreement level.** Ledger rows F038 and
F040 (`docs/port/COMMONALITY.md:44,46`, both `py-only`, both `DIVERGENT`, both
`Item: R11`) state the capability: *every quality gate reports as a check a branch
protection rule can require, and a pull request pays only for the gates its change
can affect.* The level at which py, ts and rs must agree is **capability plus
policy**, not mechanism. What may vary is everything the ecosystem decides: how many
processes the gates are spread across, what those processes are named, and what makes
a gate skippable.

| Must agree — capability and policy | May vary — ecosystem-local |
|---|---|
| Every gate reports a check that branch protection can require | How many jobs the gates occupy, and their names |
| A pull request that cannot affect a gate does not pay for it | Which paths make a gate skippable, and how they are detected |
| A skipped gate still **reports**, and reports success | Whether the skip is a job `if:` or something else — but see the constraint below, which makes this a policy in practice |
| The floor language version is proven in CI (`msrv-policy`) | Whether the floor is a matrix leg or its own job — **this item** |
| Every runner in `target-os-matrix` runs the gates that are OS-sensitive | Which gates are OS-sensitive |

**The constraint that turns one "may vary" row into policy, quoted rather than
summarised.** GitHub's own troubleshooting page for required status checks, read at
`github/docs` commit `1fa3a6df3560daedd7c8a69e8eff1a730b58c1af`
(`content/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks.md`,
retrieved 2026-09-18), tabulates the two skips as **different outcomes**:

> | A workflow is skipped by path filtering, branch filtering, or a commit message | Associated checks stay in a "Pending" state and block merging | Avoid requiring workflows that can be skipped. |
> | A job is skipped by a conditional | The job reports "Success" | |

and the same page states, at its top, "Successful check statuses are `success`,
`skipped`, and `neutral`", while the reusable it embeds
(`data/reusables/pull_requests/path-filtering-required-workflows.md`, same commit)
says outright:

> You should not use path or branch filtering to skip workflow runs if the workflow
> is required to pass before merging.

That is the whole answer to the prompt's LOW question and it is not a preference: a
`on.pull_request.paths` filter on `ci.yml` would make a docs-only pull request
unmergeable the moment R12 makes any check in that file required. py records the
same finding in its own words at the pin (`lint.yml:8-12`): "a workflow-level
`paths:` filter can't be applied per-job … A skipped job satisfies a required status
check — strictly better than the old design, where a docs-only PR never reported the
context at all (which would hang a PR if the check were required)."

**Two further platform facts, both read at the same pinned commit, that fix the
detector's shape.** First, `jobs.<job_id>.needs`: "If a job fails or is skipped, all
jobs that need it are skipped unless the jobs use a conditional expression that
causes the job to continue." Second, the `needs` context carries `outputs` per
dependency, and the documentation's own worked example shows a non-successful job
with `"outputs": {}` — an empty map. Together those make the **positive-predicate
rule** mandatory: a gate must read `== 'true'`, never `!= 'false'`, because a skipped
or failed detector publishes the empty string, and the empty string is not equal to
`'false'`, so the negated form runs the heavy job in exactly the case the gate exists
to prevent. R18 revision 6 found this bug in its own draft and R86 carries the same
rule; **what is new here is that `actionlint` cannot catch it** (executed, negative
control NC2 below).

**Architectural alternatives, compared before any library.**

| Alternative | What it is | Compile cost per pull request | Cache cost | Required-check behaviour | Verdict |
|---|---|---|---|---|---|
| **A. One job, all checks as steps** (ts's shape, `ts .github/workflows/ci.yml:40-106`) | a single `ci` job, `just`-recipe steps in sequence | one dependency compile per OS; every check pays the *previous* check's wall clock even when unrelated | 1 entry per OS — minimal | one check per OS; a docs-only PR pays the whole compile | **Rejected.** Sound on cost, but it cannot express any skip at all, and a single failing step hides every later check's result |
| **B. One job per check** (py's shape; `tokio`, `axum`) | `fmt`, `clippy`, `test`, `doc`, `build` each their own job | **N dependency compiles per OS.** In Rust this is the dominant cost, not the startup cost it is in Python or Node | N entries per OS against a documented 10 GB per-repository budget | maximal parallelism, finest-grained reporting | **Rejected as the default.** The parallelism is real, but it is bought by recompiling the same dependency graph in every job |
| **C. Compile-tier partition** (recommended) | jobs are partitioned by *whether the check compiles*, not by which check it is | one dependency compile per OS, plus one for the floor toolchain | 3 cache-bearing job ids → 4 entries across the matrix | each tier reports its own check; cheap checks still report when the compile tier is skipped | **Selected** |
| **D. Native `on.<event>.paths` filtering** | put the path filter on the workflow trigger | zero when it fires | none | **breaks required checks** — the quotation above | **Rejected on the vendor's own instruction** |

**Why C rather than B, on measured ground rather than taste.** The prompt's HIGH
question asks whether R10's cache erases the parallelism benefit. It does not erase
it; it *prices* it, and the price is documented. R10's accepted decision configures
`Swatinem/rust-cache` v2.9.2 with `add-job-id-key` left at its default `"true"`,
which R10 established reads `process.env.GITHUB_JOB` (assertion `A3.6`), so **each
job id gets its own `target/` cache entry per OS**; R10 records the budget as
"GitHub's documented 10 GB per repository with eviction of entries unused for 7 days
and, on overflow, deletion by oldest last-accessed", and hands this item two explicit
configuration facts: "the entry count against the storage budget is two times the
number of job ids, and a build-graph-changing matrix leg needs one extra `key`
segment" (R10 `review/DECISION.md`, accepted-but-unpublished run
`research/runs/R10/2026-09-17T020715Z-b3b67fdb5328`). R10's own re-verify line names
the threshold: it re-opens `save-if` on "R11 resolving with a job count materially
above six per OS". Alternative B, filled out for this template's real check list
(fmt, clippy, test-feature-off, test-feature-on, doc, build-serve, install-smoke,
msrv, coverage, deny, docs-gate, openapi-snapshot) is **twelve** job ids; alternative
C is **six**, of which three compile. So B does not merely cost more runner minutes,
it violates a constraint an already-accepted item wrote down in advance.

**Why the web surface does not get its own compile gate, and this is the prompt's
MEDIUM question answered against an executed result.** R02's accepted decision
(run `research/runs/R02/2026-09-17T033527Z-40929a603f91`) recommends a four-package
workspace — `rs-launch-blueprint` at the root, `rs-launch-blueprint-core`,
`rs-launch-blueprint-cli`, and the optional `rs-launch-blueprint-web` at
`crates/web/` — and its check `B3` **executed** the fact that governs this item's job
shape: "a **workspace-scoped** build compiles the web member with the feature off,
because workspace membership, not the root package's feature, decides which members
are built." R02 names this to R11 in its own re-verify line ("R11 must also account
for check `B3`"). The consequence is that on a pull request touching only the CLI,
any `--workspace` command already compiles `axum` and `tokio`. Splitting the web
checks into their own job would therefore *duplicate* that compile rather than avoid
it. The correct shape is the opposite of a split: run the feature-off and feature-on
commands as **ordered steps of the same job**, sharing one `target/` directory, where
Cargo's fingerprinting makes the second configuration an incremental cost rather than
a fresh graph. Two corollaries follow and both are in the recommendation: the
feature-off *test* command is **root-scoped** (`-p` per non-web package) so that the
"the default build carries no web" property is actually proven rather than assumed,
and a Cargo-feature **matrix dimension is forbidden**, because R10's assertion `A3.6`
makes `features: [default, web]` legs collide on one cache key unless a
`key:` segment is added — a complication that buys nothing once the configurations
are steps.

**Where the web skip-gating genuinely belongs.** R69 revision 10's owned value ends
"path-based skip-gating keys on `crates/web/**`, the serve binary's source file and
the web test files". This item honours that by emitting a `web` output and spending
it on the jobs that are *purely* web — R71's OpenAPI snapshot, R84's typed-client
drift — not on the compile tier. There is no symmetric "core-only" key, because
`crates/web` depends on `crates/core`, so a web change must re-run the core tests
anyway, and once the job's `target/` is warm those tests are the cheap part.

**The floor version: a job, not a matrix leg, and the reason is the cache.** F033 as
restated by the baseline review reads "floor plus current stable", and its note
assigns the mechanism here: "whether the floor is a matrix leg or a separate job
falls under `ci-job-structure` (R11)". Two facts decide it. Cargo's own CI guide
shows the floor verified in a **separate single-runner job**:

```yaml
jobs:
  msrv:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v6
    - uses: taiki-e/install-action@cargo-hack
    - run: cargo hack check --rust-version --workspace --all-targets --ignore-private
```

introduced by "When publishing packages that specify `rust-version`, it is important
to verify the correctness of that field"
(`https://doc.rust-lang.org/cargo/guide/continuous-integration.html`, retrieved
2026-09-18). And R10's acceptance criterion `A3` already anticipated it: "A toolchain
change — including the MSRV floor job beside the stable job — produces distinct cache
entries and restores no `target/` across" them. A matrix leg over toolchain inside
the `check` job would therefore give the two legs the *same* job id and the same
cache key while their compilers differ, which is the collision R10 warned about; a
separate job gives them distinct keys for free. `axum` (`test-msrv`) and `bat`
(`min_version`) both do it as a separate job.

**What this item must NOT decide, stated so the open questions stay open.** Whether
the floor is verified on **every** OS in `target-os-matrix` is an explicit open owner
question recorded in `docs/port/BASELINE-REVIEW.md` ("MSRV leg versus the OS matrix
(raised by F033) … nothing records whether the floor is verified on every runner or
on Linux only … I am not proposing a new research item", and the reconciliation row
"OS cross-product stays an owner question; R11 not widened"). The recommendation
therefore places the floor job on `ubuntu-latest` as the **default that matches
Cargo's guide**, and expresses it as a one-line change (`runs-on: ${{ matrix.os }}`
plus the same two-entry `os` matrix) if the owner widens it. That is an accommodation,
not a widening.

**Minimal realistic example and what was actually run.** A complete candidate
`.github/workflows/ci.yml` was written under a `$TMPDIR` subdirectory and linted. It
is 164 lines, six job ids (`plan`, `hygiene`, `workflow-lint`, `check`, `msrv`,
`install-smoke`), sha256
`862295bfba9c06bff6f4dc1fe81a484263b73cc9a98781fd6fb1933e80813252`.
`actionlint` 1.7.12 **exits 0** on it. Four negative controls were then run against
the same file, and one of them is the finding of this report:

| # | Mutation | `actionlint` | What it establishes |
|---|---|---|---|
| NC1 | `needs.plan.outputs.code` → `codee` | **exit 1** on 3 sites: `property "codee" is not defined in object type {code: string; docs: string; web: string; workflows: string}` | the detector relay is type-checked against the producing job's declared `outputs:`, so a renamed key cannot silently disable a gate |
| NC2 | `== 'true'` → `!= 'false'` | **exit 0** | **the linter cannot catch the fail-open gate.** The positive-predicate rule is a design rule the tool-chain does not enforce, so it must be written into this item's value and into R12's and R13's inherited shape, not left to lint |
| NC3 | job-level `if:` reading `secrets.SOME_TOKEN` | **exit 1**: `context "secrets" is not allowed here. available contexts are "github", "inputs", "needs", "vars"` | re-confirms, independently of R18 and R86, why a credential gate must be a preflight job rather than a job condition — and therefore why this item's detector job and those items' preflight jobs are the *same* structural device |
| NC4 | the first `needs: plan` → `needs: planx` | **exit 1**: `job "workflow-lint" needs job "planx" which does not exist in this workflow` | the `needs` graph itself is checked, so a job renamed out from under a gate fails the lint |

The detector's shell body was additionally **executed** against nine synthetic diffs
(D1–D9 under `### Validation strategy`), each producing the four literal outputs.

**Observable acceptance criteria**, each labelled by what has actually been run.

| # | Criterion | Status |
|---|---|---|
| 1 | The candidate workflow is type-correct: `actionlint` exits 0, and it exits 1 on a misspelled output key, a `needs` edge to a missing job, and a job-level `if` touching `secrets` | **Executed** (NC1, NC3, NC4, control) |
| 2 | The linter does **not** reject the fail-open `!= 'false'` gate, so the rule must be carried in prose | **Executed** (NC2) |
| 3 | A docs-only diff yields `code=false` and a README-only diff yields `code=true` | **Executed** (D1, D2) |
| 4 | A change under `crates/web/` yields `web=true`, and a change to the serve binary's source file yields `web=true` | **Executed** (D4, D5) |
| 5 | On a real docs-only pull request the compile jobs report **skipped**, and a required check on any of them is satisfied | **Proposed** for P03 — no workflow has run on a runner |
| 6 | After a full matrix run, the repository's `active_caches_size_in_bytes` holds 4 entries and stays well inside 10 GB | **Proposed** for P03; it is R10's criterion `A5` measured against this job count |
| 7 | `cargo test -p …` (feature off) leaves `crates/web` uncompiled while `cargo test --workspace` compiles it | **Carried**, executed by R02 as check `B3`; not re-run here |
| 8 | The floor job and the stable job restore different `target/` caches | **Proposed** for P03; it is R10's criterion `A3` |

**BASELINE-REVIEW.** None is raised. F038 and F040 are `DIVERGENT` rows this item is
appointed to settle rather than inherited baselines, and the two `COMMON → REUSE`
rows in reach have already been adjudicated by other items — F033 by the 2026-09-04
baseline review, which left exactly the leg-versus-job mechanism to this item, and
F035 by R10.

**Reconciliation with the owner's reference architecture** (`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`,
a standing input, not a standard). Six rows overlap this item.

| Row | What it says | This item |
|---|---|---|
| C12 *Testing*, the CI sentence | "CI runs: `cargo fmt --check` → `cargo clippy -D warnings` → `cargo sqlx prepare --check` → `cargo test` → `cargo deny check` … → OpenAPI export + diff" | **Agree on the order, differ on the packaging.** The order is preserved exactly — and it is worth saying plainly that a strict reading of it is ts's single-job shape, since a `→` chain is a step sequence. The difference is that `cargo fmt --check` is lifted out of the chain into a no-compile job, because it is the one item in the list that compiles nothing and therefore need not wait for, or pay for, the others. `cargo sqlx prepare --check` is **inapplicable**: this template has no database and R69 revision 10's feature adds `axum` and `tokio` only |
| C14 *Developer experience & build* | "pin the toolchain with `rust-toolchain.toml`; enable clippy `-D warnings`" | **Agree.** R42's accepted decision already commits `rust-toolchain.toml` with `profile = "minimal"`, `components = ["rustfmt", "clippy"]`, which is what lets the compile job need no toolchain-install action for the stable leg; `-D warnings` is written into the clippy steps |
| C3 *OpenAPI* | "Run generation in CI and `git diff --exit-code` so drift fails the build" | **Agree as a slot.** The `openapi-snap` slot is gated on the `web` output and `needs: plan`; the command inside it is R71's and R84's |
| C15 *Container & Cloud Run* | build the image with cargo-chef, deploy to Cloud Run | **Differ — hand-off, not disagreement.** No container or deploy job enters `ci.yml`; R51 owns the image and R68 owns the release workflow, whose `cargo-dist` 0.33.0 follower mode behind release-please is a separate file |
| *Recommendations* 7 | "Gate CI on `cargo deny`, sqlx offline check, OpenAPI/TS-client drift, and clippy `-D warnings` from day one" | **Agree on three of four, and each becomes a named slot** — `deny` (R02's F008 mechanism and R13's scanning), `openapi-snap` (R71/R84), and clippy inside the compile job. The sqlx clause is inapplicable for the same reason as above |
| Reference `Cargo.toml` — `edition = "2021"`, `rust-version = "1.85"` | the document's own pins | **Differ, by the owner's own precedence rule.** `rust-edition` is `2024` and the floor follows `msrv-policy`; the reference file states that owner-fixed parameters override it |

Tally: **four agree** (one of them with a stated scope limit), **two differ**, both
differences on recorded ground rather than preference.

**What this item deliberately leaves open, and what each consumer inherits.** Every
row below is a *slot*: a job id, a `needs` edge and a gating predicate this item
fixes, with the contents left to the named item.

| Item | What it fills | The rule it inherits from this item |
|---|---|---|
| R32 test-harness-and-execution | the tier names inside the `check` job's test steps, and whether a slow tier earns its own job | a tier becomes its own job **only** if it needs a different toolchain, a different runner, or a `target/` it must not share; otherwise it is a step |
| R08 workflow-permission-hardening | the `permissions:` values | workflow-level `permissions: {}` with a per-job re-grant is the *placement*; the scopes are R08's |
| R12 aggregate-required-status-check | whether `ci-ok` exists, and its `needs:` list | if it exists it must carry `if: ${{ always() }}` and `needs:` every job id, per the platform's own instruction "Use `always()` with `needs` for required checks that depend on other jobs"; it must treat `skipped` as a pass and `failure`/`cancelled` as a fail |
| R13 dependency-vulnerability-scanning | the SCA gate (F049) | it compiles nothing that the compile tier has not already compiled, so it is a **step** unless it needs `cargo metadata` on a graph the compile job does not build; if it becomes a job it takes `needs: plan` and `if: code == 'true'` and counts against R10's six-per-OS |
| R27, R28, R29, R30, R31 | fmt, lint, non-code formatting, typecheck, standalone analyzer | non-compiling → the `hygiene` or `workflow-lint` job; compiling → an ordered step of `check` |
| R35 coverage-tooling | the `coverage` slot | it instruments differently from a plain build, so it is expected to need its own `target/`, which makes it a **job**, `needs: plan`, `if: code == 'true'` |
| R37, R39, R40 | hook manager, secret hooks, hygiene hooks | if CI re-runs the hook suite (ts does, at `ci.yml:105-106`), it is a step of `hygiene` when it compiles nothing |
| R71, R82 | OpenAPI generation, docs-correctness gate | `openapi-snap` gated on `web`; `docs-gate` gated on `docs == 'true' \|\| code == 'true'` |
| R17 secret-scanning-ci-workflow | which runner OS its single scan job lands on — a question R17's decision explicitly hands here ("Which runner OS the single scan job lands on (R11 owns this)") | **`ubuntu-latest`**, by the tier-1 rule: the scan compiles no Rust, so it neither shares nor claims a `target/` cache entry and gains nothing from a second runner. The same answer covers every single-job non-compiling workflow file, R18's and R86's preflight jobs included |
| R42 dev-toolchain-provisioning | whether a CI toolchain-install **action** is named | this item installs nothing beyond what `rust-toolchain.toml` triggers; the floor job needs a second toolchain and the mechanism is R42's, which R10's re-verify (5) already flags as undecided |

### Recommendation

**One stack: the named pattern `plan-gated compile-tier CI`, implemented entirely in
GitHub Actions' own syntax plus `git`, adding no third-party action to
`.github/workflows/ci.yml` beyond the one R10 already selected.**

`.github/workflows/ci.yml` carries six job ids, in three tiers, joined by `needs` to
one always-run detector:

```
plan  (always, ubuntu-latest, no toolchain, no cache, 4 literal outputs)
 |
 |-- hygiene        (always, ubuntu-latest, no cache)        cargo fmt --check
 |-- workflow-lint  (if workflows == 'true', no cache)       R29's slot
 |-- check          (if code == 'true', matrix os)           clippy / test off / test web / build serve / doc
 |-- msrv-floor     (if code == 'true', ubuntu-latest)       the rust-version floor, its own toolchain
 `-- install-smoke  (if code == 'true', ubuntu-latest)       R50's recipe
```

Triggers are `pull_request` and `push` to `main` plus `merge_group`; the workflow
carries `permissions: {}` re-granted per job and a `concurrency` group keyed to the
pull-request number on pull requests and to the commit sha otherwise, with
`cancel-in-progress: true`; every gated job reads the detector through a **positive**
`== 'true'` predicate; and `ci.yml` carries no `on.<event>.paths` filter of any kind.

### Members

#### plan-job change detector

##### Landscape
The mechanism that decides which jobs a run pays for. Bin 1 offers `on.<event>.paths`
and a `git diff` step; bin 2 offers the hand-rolled detector job (py at the pin
`ci.yml:32-77` and `lint.yml:30-64`; `astral-sh/uv` `plan.yml`) and
`dorny/paths-filter`; bin 3 offers `tj-actions/changed-files`. All four were evaluated.

##### Principles and implementation
The principle is that a skip must still **report**. GitHub's own documentation makes
this a policy rather than a preference: a workflow skipped by path filtering leaves
its checks "Pending" and blocks merging, while a job skipped by a conditional
"reports Success" (`troubleshooting-required-status-checks.md`, `github/docs`
@`1fa3a6df3560daedd7c8a69e8eff1a730b58c1af`, 2026-09-18). The detector is therefore a
**job**, and the gate is a job `if:`. Its outputs must be the literal strings `true`
and `false`, and dependants must test `== 'true'`: a skipped or failed producer
publishes an empty output map (the platform's own `needs`-context example shows
`"outputs": {}` for a non-successful job), so `!= 'false'` fails open — and negative
control NC2 **executed** here shows `actionlint` 1.7.12 accepts that mistake silently.
`astral-sh/uv` implements exactly this: `out() { [[ "$2" ]] && echo "$1=true" || echo "$1=false"; }`
feeding eighteen outputs consumed as `needs.plan.outputs.<key> == 'true'`.

##### Dominant choice
A hand-rolled `git diff --name-only "${BASE_SHA}...HEAD"` step inside an always-run
`plan` job, after `actions/checkout` with `fetch-depth: 0`, under `set -euo pipefail`,
publishing `code`, `web`, `workflows` and `docs`. It is what both directly relevant
precedents do — py at the pin, whose comment says "Shell-based (same pattern as
large-file-guard) - no third-party action", and `astral-sh/uv`, the
highest-adoption new Rust CLI in the field (89,957 stars, 2026-09-18T22:10:09Z).

##### Qualified shortlist
`dorny/paths-filter` — **MIT**, not archived, `pushed_at` 2026-08-05T12:20:34Z,
3,337 stars, 20 open issues
(`GET https://api.github.com/search/issues?q=repo:dorny/paths-filter+is:issue+is:open`,
2026-09-18T22:10:09Z), latest release `v4.0.3` published 2026-08-05T12:17:06Z
resolving to commit `ceb8a2b8f2d89434be7ff52d3de7ec3738c5cc9d`
(`GET https://api.github.com/repos/dorny/paths-filter/git/ref/tags/v4.0.3`, 2026-09-18).
Responsiveness over the 10 most recently opened issues
(`GET https://api.github.com/search/issues?q=repo:dorny/paths-filter+is:issue&sort=created&order=desc&per_page=10`,
2026-09-18T22:14:56Z): **all 10 carry at least one comment; 0 unanswered**; 8 of 10
are closed, with a **median 1.5 days** from open to close (0, 0, 1, 1, 2, 4, 8, 13).
First-maintainer-response timestamps were not fetched, so the median reported is
days-to-close, and that limit is stated rather than papered over. Maintenance state:
**active**.

**Its fitness-gate walk, done before popularity is weighed.** **Gate 1 (licence)**:
`MIT`, compatible with `MIT OR Apache-2.0` — recorded, not tested, since the owner
ruled on 2026-09-12 (Q7.B) that licence compatibility is not evaluated for a tool.
**Gate 2 (MSRV)**: **inapplicable** — it is a JavaScript action; it declares no
`rust-version`, enters no `Cargo.toml` and no dependency tree. **Gate 3 (advisories)**:
**passes, with a control.** `GET https://api.github.com/advisories?ecosystem=actions&affects=dorny/paths-filter`
returns **0** advisories, while the same endpoint with
`affects=tj-actions/changed-files` returns **2**, both `high`
(`GHSA-mrrh-fwg8-r2c3`, `GHSA-mcph-m25j-8j63`) — so the zero is a real zero and not a
broken query (both retrieved 2026-09-18T22:30:50Z and 22:31:11Z). `unsafe` posture:
**inapplicable**, no Rust. **Gate 4 (both runners)**: it runs on the Node runtime every
GitHub-hosted runner ships, so it is runner-agnostic by construction; Windows likewise.
**Gate 5 (default features, async coupling)**: **inapplicable** — an action has neither.
**Gate 6 (binary size, compile time)**: **inapplicable** — it contributes nothing to the
template's artifacts or build.

##### Excluded by gate
`tj-actions/changed-files` — **excluded by gate 3** (no open advisory). It carries
GHSA-mrrh-fwg8-r2c3 / CVE-2025-30066, severity `high`, published 2025-03-15,
"allows remote attackers to discover secrets by reading actions logs", vulnerable
`<= 45.0.7`, first patched `46.0.1`
(`GET https://api.github.com/advisories/GHSA-mrrh-fwg8-r2c3`, 2026-09-18T22:16:11Z).
The advisory is patched rather than open today, so the exclusion is stated on its
true ground: a supply-chain compromise of the action's own tags is disqualifying for
a *template* whose adopters inherit the reference verbatim, not because the current
release is vulnerable. Native `on.<event>.paths` — **excluded on fit**, not on a
fitness gate, by the vendor's own instruction quoted above.

##### Up-and-comers
None with adoption. The field's movement is toward richer detectors rather than new
mechanisms: `astral-sh/uv`'s plan job mixes path detection with pull-request **labels**
(`test:skip`, `test:extended`, `build:release`), a contributor-facing override this
template does not need at its size but which is the natural growth path.

##### Fit for this template
The template is CLI + library + optional web service with a `docs/` tree, a `README.md`
that is a packaging input, and `.github/workflows/` the template itself teaches. Four
keys cover it exactly. A third-party action would add a `uses:` clause that R20's
`enforced-owner-prefix-pinning` requires be SHA-pinned and Dependabot-tracked, for
roughly fifteen lines of shell the template already demonstrates elsewhere.

##### Recommendation
The hand-rolled `plan` job, four outputs, no third-party action. Gate every dependant
with `needs: plan` and `if: ${{ needs.plan.outputs.<key> == 'true' }}`.

##### Ranked runner-up
`dorny/paths-filter@ceb8a2b8f2d89434be7ff52d3de7ec3738c5cc9d # v4.0.3`. Its winning
condition is concrete and testable: adopt it if the key set grows past roughly eight
and the shell becomes the thing reviewers get wrong, or if a filter needs
`base:`/`ref:` semantics on `push` events that the three-dot diff cannot express.

##### Tradeoffs
The shell detector costs one always-run `ubuntu-latest` job (a few seconds, no
toolchain, no cache entry) and a `fetch-depth: 0` checkout, which on a large history
is the detector's real cost. It gains: no third-party code in a credentialed graph,
no pin to maintain, and a filter a reviewer reads in place. The action gains a
declarative filter syntax and loses the first three.

##### Parameters
Contributes the detector clause of `ci-job-structure`. Consumes `web-extra-surface`
for the `web` key's paths. No `CONFLICT:`.

##### Migration implications
New job `plan` at the top of `.github/workflows/ci.yml`. No other file.

##### Validation strategy
Executed here: the detector body run against nine synthetic diffs (D1–D9), and
`actionlint` NC1/NC2/NC4. Proposed for P03: a real docs-only pull request whose
compile jobs report `skipped` and whose required check is satisfied.

##### Confidence & re-verify trigger
**High** for the mechanism (two precedents plus a vendor instruction), **medium** for
the exact key set, which no repository has yet exercised. re-verify: when R69 revision
10 publishes and the registry's skip-gating paths move to `crates/web/**`; when R32,
R71 or R82 asks for a fifth key; if GitHub changes the required-status behaviour of a
conditionally skipped job; or by 2027-03-18.

##### Sources
`github/docs` @`1fa3a6df3560daedd7c8a69e8eff1a730b58c1af`:
`content/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks.md`,
`data/reusables/pull_requests/path-filtering-required-workflows.md`,
`data/reusables/actions/jobs/section-using-jobs-in-a-workflow-needs.md`,
`data/reusables/actions/jobs/section-defining-outputs-for-jobs.md`,
`content/actions/reference/workflows-and-actions/contexts.md` (all 2026-09-18).
`py .github/workflows/ci.yml:32-77` and `lint.yml:30-64` at `b08bccfb`.
`https://raw.githubusercontent.com/astral-sh/uv/main/.github/workflows/plan.yml` and
`ci.yml` (2026-09-18). `https://api.github.com/repos/dorny/paths-filter`,
`/git/ref/tags/v4.0.3`, `/releases/latest`,
`https://api.github.com/search/issues?q=repo:dorny/paths-filter+is:issue+is:open`,
`https://api.github.com/advisories/GHSA-mrrh-fwg8-r2c3` (2026-09-18).

#### compile-tier job partition

##### Landscape
The topology itself. Bin 1 supplies `strategy.matrix`, `needs`, and Cargo's own
`-p`/`--workspace`/`--features` scoping. Bin 2 supplies the two live precedents — one
job with every check as a step (`ts .github/workflows/ci.yml:40-106`) and one job per
check (`py`, `tokio` with 30+ jobs, `axum` with 13). Bin 3 supplies nothing new;
nobody is inventing a third topology.

##### Principles and implementation
The principle this member protects is that **a Rust CI job's dominant cost is its
dependency compile, and a job boundary duplicates it**. R10's accepted configuration
makes that cost legible rather than rhetorical: `add-job-id-key` defaults to `"true"`
and reads `GITHUB_JOB` (assertion `A3.6`), so every job id that runs `cargo` claims
its own `target/` cache entry against GitHub's documented 10 GB per-repository budget;
R10 hands this item the arithmetic ("two times the number of job ids") and the
threshold ("a job count materially above six per OS" re-opens `save-if`). The
partition rule that follows is: **a check that compiles is a step of the one compiling
job for its OS; a check that does not compile is its own cheap job carrying no
`rust-cache` step.** `cargo fmt` parses and never writes `target/`, which is why
`ripgrep` and `clap` both keep `rustfmt` as its own job and why this design does too.
R02 check `B3` then fixes the Cargo scoping inside the compiling job: because
`--workspace` compiles the optional `crates/web` member with the feature off, the
feature-off *proof* must be root-scoped (`-p rs-launch-blueprint -p …-core -p …-cli`)
while the feature-on test stays `--workspace --features web`, and the two run as
consecutive steps sharing one `target/`.

##### Dominant choice
There is no dominant choice in the field: the two precedents are the two poles, and
the survey splits 5–1 toward per-check jobs — but every one of those five is a
code-only repository with no docs tree and no skip-gating at all, which is the fit
distinction drawn in `### Landscape`. The recommendation is therefore a *synthesis*,
and it is named as such rather than dressed as a consensus.

##### Qualified shortlist
(a) one job, all steps — ts's shape; (b) one job per check — py's, `tokio`'s,
`axum`'s; (c) the compile-tier partition; (d) a hybrid with a per-check job for the
slowest check only. All four clear gates 1 and 3 trivially and gate 4 by
construction. Crate figures are **inapplicable**: no member of this bundle is a crate,
so `recent_downloads`, `downloads`, last release and RustSec pages have no subject —
the one exception is the floor member below, which does name a crate.

##### Excluded by gate
None by a fitness gate. (d) is excluded on fit: it re-introduces the duplicate
dependency compile for exactly the check whose compile is largest, which is the
opposite of the intended saving.

##### Up-and-comers
Reusable workflows (`uses: ./.github/workflows/<file>.yml` per job) as the unit of
composition, which `astral-sh/uv` now uses for 21 of its 22 top-level jobs. It is a
packaging change, not a topology change, and it costs a reader one file hop per job;
at six jobs this template does not need it.

##### Fit for this template
Six job ids of which three compile: `check` × 2 OS, `msrv-floor`, `install-smoke` —
**four cache entries**, comfortably inside the threshold R10 wrote down before this
item existed. The same design absorbs R02's boundary check, R13's SCA and R35's
coverage as slots without crossing it.

##### Recommendation
`plan` and `hygiene` and `workflow-lint` carry no cache; `check` runs
`strategy.matrix.os: [ubuntu-latest, macos-latest]` — **over `os` only, never over
Cargo features** — with clippy (feature off), clippy (feature on), test (root-scoped,
feature off), test (`--workspace --features web`), `cargo build --features web --bin
<app>-serve` and `cargo doc` as ordered steps; `msrv-floor` and `install-smoke` are
their own single-runner jobs.

##### Ranked runner-up
Alternative (b), one job per check, with `save-if` set to the default-branch
expression R10 pre-wrote for exactly this case. Its winning condition: P03 measures
the `check` job's wall clock long enough that serialising clippy behind the tests
dominates the duplicate-compile cost, **and** criterion A5 shows the cache footprint
has headroom. Both halves must hold; either alone does not reopen it.

##### Tradeoffs
The partition trades parallelism for compile reuse and for a smaller cache claim. A
failure in an early step of `check` hides the later steps' results on that OS — the
genuine cost of ts's shape, inherited here and bounded by the fact that the two OS
legs run independently with `fail-fast: false`, so a macOS-only failure never masks
the Linux result.

##### Parameters
Contributes the topology clause of `ci-job-structure`. Reads R02's four-package
recommendation and check `B3`, and R10's cache arithmetic, as prose rather than as
registry parameters — neither appears on this prompt's `- consumes:` line.

##### Migration implications
`.github/workflows/ci.yml` gains `hygiene`, `workflow-lint`, `check` and
`install-smoke`; no source file changes.

##### Validation strategy
Executed: `actionlint` 1.7.12 exit 0 on the six-job candidate. Carried: R02 check
`B3`. Proposed for P03: the per-OS wall clock of `check`, and R10's criterion A5.

##### Confidence & re-verify trigger
**High** on the partition rule, **medium** on the step order inside `check`, which no
run has timed. re-verify: when R02 publishes and its topology or F116 placement
moves; when R32, R35 or R13 adds a compiling job that takes the cache-bearing job
count per OS past six; when R10's `save-if` is changed; or by 2027-03-18.

##### Sources
`ts .github/workflows/ci.yml:40-106` and `:141-188` at `cb1cbcb2`; `py
.github/workflows/ci.yml:32-295` at `b08bccfb`; R02 run
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (checks `B1`,
`B3`, `B4`); R10 run `research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/DECISION.md`
(assertions `A3.6`, `A3.8`, criteria `A3`, `A5`, `A7`); workflow files of `tokio`,
`axum`, `ripgrep`, `clap`, `bat`, `uv` from `raw.githubusercontent.com` (2026-09-18);
`https://api.github.com/repos/<o>/<r>` for each (2026-09-18T22:10:09Z).

#### rust-version floor placement

##### Landscape
The `msrv-policy` floor must be "tested in CI" by the owner-fixed parameter's own
words. Bin 1 offers a `strategy.matrix` toolchain leg and a plain
`cargo +<floor> check`. Bin 2 offers a dedicated job, which is what Cargo's own CI
guide shows and what `axum` (`test-msrv`) and `bat` (`min_version`) ship. Bin 3
offers nothing new.

##### Principles and implementation
F033, as restated by the 2026-09-04 baseline review, is "floor plus current stable",
and its ledger note assigns the mechanism here. Two facts decide it for a job. Cargo's
guide verifies `rust-version` in a separate `msrv` job on `ubuntu-latest` with
`cargo hack check --rust-version --workspace --all-targets --ignore-private`, framed
by "When publishing packages that specify `rust-version`, it is important to verify
the correctness of that field". And R10's criterion `A3` states the cache consequence
directly: a toolchain change "including the MSRV floor job beside the stable job"
must produce distinct cache entries — which a separate job id gets for free and a
matrix leg inside `check` does not, because `add-job-id-key` reads the job id and not
the matrix value.

##### Dominant choice
A separate single-runner job. `cargo-hack` is the tool Cargo's guide names, and its
figures are: `recent_downloads` **219,720**, `downloads` **1,893,214**
(`GET https://crates.io/api/v1/crates/cargo-hack`, 2026-09-18T22:16:21Z); newest
non-yanked version **0.6.45**, `created_at` 2026-05-30T14:50:51Z, license
`Apache-2.0 OR MIT`, declared `rust_version` `1.85`
(`GET https://crates.io/api/v1/crates/cargo-hack/versions`, same retrieval);
`taiki-e/cargo-hack` 862 stars, not archived, `pushed_at` 2026-09-02T12:45:59Z,
35 open issues (`GET https://api.github.com/repos/taiki-e/cargo-hack` and
`search/issues?q=repo:taiki-e/cargo-hack+is:issue+is:open`, 2026-09-18T22:16:34Z).
Maintenance state **active**. Advisories: `https://rustsec.org/packages/cargo-hack.html`
returns **404** where the control `https://rustsec.org/packages/atty.html` returns
**200**, so the absence is a real absence and not a broken fetch (2026-09-18).

##### Qualified shortlist
(a) `cargo hack check --rust-version …` in an `msrv-floor` job — Cargo's guide's
shape; (b) `cargo +<floor> check --locked --workspace --all-targets` in the same job,
no extra crate, which trades `cargo-hack`'s per-package `rust-version` resolution for
zero added tooling; (c) a toolchain matrix leg inside `check`.

##### Excluded by gate
(c) is excluded on fit rather than by a fitness gate: R10's assertion `A3.6` makes a
non-OS matrix dimension collide on one cache key, which is the specific failure R10
handed to this item. `cargo-hack` itself clears every applicable gate: **gate 1**
licence `Apache-2.0 OR MIT`, compatible with `MIT OR Apache-2.0` — and recorded only,
since the owner ruled 2026-09-12 (Q7.B) that licence compatibility is not evaluated
for a tool; **gate 2** declared `rust-version` `1.85`, inside the floor, with the
standing caveat that whether the MSRV gate reaches a non-linked developer tool at all
is an open owner question R69 also records; **gate 3** no RustSec page, `unsafe`
posture not audited here and stated as unverified; **gate 4** its own CI is not
inspected here, so ubuntu+macOS support is **unverified** and named as a P03 check
rather than asserted; **gate 5** no async-runtime coupling — it is a `cargo`
subcommand, not a dependency; **gate 6** binary-size and compile-time cost do not
reach the template's artifacts at all, because it never enters `Cargo.toml`.

##### Up-and-comers
`cargo-msrv` as a floor *discoverer* rather than verifier. It solves a different
problem — finding the floor — and this template's floor is fixed by `msrv-policy`, so
it is a lead and not a candidate.

##### Fit for this template
One extra job id, `ubuntu-latest`, one extra cache entry, and a `--locked` flag so the
committed `Cargo.lock` is what the floor is proven against. R02's four-package
workspace makes the `--workspace` scope meaningful: the floor is the floor of every
member, and check `B3` means `crates/web` is inside that computation whether or not
the feature is on — which is the honest answer, since a consumer enabling `web` gets
that floor.

##### Recommendation
An `msrv-floor` job, `needs: plan`, `if: code == 'true'`, `runs-on: ubuntu-latest`,
one `rust-cache` step, and `cargo hack check --locked --rust-version --workspace
--all-targets --ignore-private`. **The OS reach of this job is not decided here**: the
baseline review records it as an open owner question and the recommendation is written
so that widening it is the one-line substitution `runs-on: ${{ matrix.os }}` with the
same two-entry `os` matrix.

##### Ranked runner-up
(b), plain `cargo +<floor> check --locked --workspace --all-targets`, which adds no
crate at all. Its winning condition: P03 finds the `cargo-hack` install step
(whichever mechanism R42 lands on) costs more than the per-package `rust-version`
resolution is worth for a four-package workspace that inherits one
`[workspace.package] rust-version`.

##### Tradeoffs
A separate job pays one more dependency compile at the floor toolchain and one more
cache entry, and buys a clean cache partition, a check name a reader can require
independently, and Cargo's own shape. Installing the floor toolchain is a second
toolchain download the `check` job does not pay.

##### Parameters
Contributes the floor clause of `ci-job-structure`; reads the owner-fixed
`msrv-policy` and `target-os-matrix`. No `CONFLICT:`.

##### Migration implications
`.github/workflows/ci.yml` gains `msrv-floor`. The floor value itself lives in
`Cargo.toml`'s `[workspace.package] rust-version` per R02, and the toolchain channel
in `rust-toolchain.toml` per R42 — neither is written here.

##### Validation strategy
Executed: `actionlint` exit 0 with the job present; the crates.io and RustSec figures
above. Proposed for P03: the job green at the declared floor on a runner, and R10's
criterion `A3` showing it restores no `target/` from the stable job.

##### Confidence & re-verify trigger
**High** that it is a job rather than a leg; **medium** on `cargo-hack` versus plain
`cargo +<floor>`, which turns on an install cost nobody has measured. re-verify: on
the owner answering the F033 OS-cross-product question; when `msrv-policy`'s floor
advances; when `cargo-hack`'s newest non-yanked version ceases to be `0.6.45` **in a
release that changes `--rust-version` or `--ignore-private` semantics**; when R42
names a CI toolchain-install action; or by 2027-03-18.

##### Sources
`https://doc.rust-lang.org/cargo/guide/continuous-integration.html` (2026-09-18);
`docs/port/BASELINE-REVIEW.md` lines 46, 141, 188, 256, 308;
`docs/port/COMMONALITY.md:39` (F033); `https://crates.io/api/v1/crates/cargo-hack`
and `/versions`, `https://api.github.com/repos/taiki-e/cargo-hack`,
`https://api.github.com/search/issues?q=repo:taiki-e/cargo-hack+is:issue+is:open`,
`https://rustsec.org/packages/cargo-hack.html` with the `atty` control (2026-09-18);
`https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml:123`
and `https://raw.githubusercontent.com/sharkdp/bat/master/.github/workflows/CICD.yml:65`
(2026-09-18); R10 criterion `A3`.

#### run scoping — triggers and concurrency

##### Landscape
What starts a run and what cancels it. Bin 1: `on.push.branches`,
`on.pull_request.branches`, `merge_group`, and workflow-level `concurrency` with
`cancel-in-progress`. Bin 2: the keyed-group idiom
`${{ github.workflow }}-${{ github.event.pull_request.number || github.sha }}`, shared
by `tokio`, `clap` and `uv`. Bin 3: nothing.

##### Principles and implementation
Two principles. First, **every event that a required check must report on has to
trigger the workflow** — which is why py added `merge_group` at the pin, recording
that without it "the ci-ok required check never reports and every queue entry
deadlocks at 'Expected'" (`ci.yml:14-19`). Second, **a superseded run should be
cancelled, but a `main` build should not cancel its predecessor**, because the
predecessor is what populates the cache every later pull request restores from — the
reuse R10's design depends on. Keying the group on
`github.event.pull_request.number || github.sha` gets both: on a pull request the
group is the PR, so a force-push cancels the old run; on a push the group is the
commit, so nothing is ever cancelled. py keys on `github.ref` alone (`ci.yml:24-25`),
which does cancel consecutive `main` builds; `tokio` and `uv` key on the
number-or-sha form. ts has no `concurrency` block at all.

##### Dominant choice
Workflow-level `concurrency` with `cancel-in-progress: true`, present in four of the
six surveyed Rust projects and in py, absent in ts.

##### Qualified shortlist
(a) group `${{ github.workflow }}-${{ github.event.pull_request.number || github.sha }}`
— `tokio`/`uv`'s form; (b) group `ci-${{ github.ref }}` — py's form; (c) no
`concurrency` — ts's form.

##### Excluded by gate
None by a fitness gate; these are workflow keywords, not dependencies, so gates 1–6
are **inapplicable** for the stated reason that there is no crate, no licence, no
`unsafe`, no runtime coupling and no compile cost to record. (c) is excluded on fit:
it lets a force-pushed branch keep two full matrix runs alive, which doubles the
cache write contention R10's `add-job-id-key` partitioning assumes.

##### Up-and-comers
Merge queues themselves. py already carries the `merge_group` trigger; GitHub's own
guidance is that a queue's speculative merge emits it instead of `pull_request`, so a
template that omits it forecloses the feature.

##### Fit for this template
`pull_request` and `push` to `main` are the two events every gate in this file must
report on; `merge_group` is the third the moment R12 makes anything required and the
repository enables a queue. Including it costs nothing when no queue exists.

##### Recommendation
`on: {push: {branches: [main]}, pull_request: {branches: [main]}, merge_group: }`;
`permissions: {}` at workflow level with a per-job re-grant (values are R08's);
`concurrency: {group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.sha }}, cancel-in-progress: true}`.

##### Ranked runner-up
(b), py's `ci-${{ github.ref }}`. Its winning condition: the owner prefers that a
rapid series of `main` merges leaves only the last run alive, accepting that the
cancelled run writes no cache.

##### Tradeoffs
The number-or-sha key never cancels a `main` run, so a burst of merges runs a full
matrix each — more runner minutes, in exchange for the cache warming every later pull
request restores from. `merge_group` adds a third trigger whose runs cost the same as
a pull request's.

##### Parameters
Contributes the trigger and concurrency clauses of `ci-job-structure`. The
`permissions:` **values** are explicitly not contributed; R08 owns them.

##### Migration implications
The `on:`, `permissions:` and `concurrency:` blocks of
`.github/workflows/ci.yml`. R17's, R18's and R86's workflow files set their own and
are untouched.

##### Validation strategy
Executed: `actionlint` 1.7.12 exit 0 on the candidate carrying all three blocks.
Proposed for P03: a force-push that cancels the prior pull-request run, and two
consecutive `main` merges that both complete.

##### Confidence & re-verify trigger
**High** on the triggers, **medium** on the group key, which is a cost judgement no
measurement here settles. re-verify: when R12 publishes and names its required check;
when R08 publishes the permission values; if the repository enables a merge queue; or
by 2027-03-18.

##### Sources
`data/reusables/actions/jobs/section-using-concurrency.md` and
`content/actions/reference/workflows-and-actions/workflow-syntax.md` at `github/docs`
@`1fa3a6df3560daedd7c8a69e8eff1a730b58c1af` (2026-09-18); `py
.github/workflows/ci.yml:11-25` and `lint.yml:17-27` at `b08bccfb`; `ts
.github/workflows/ci.yml:30-37` at `cb1cbcb2`;
`https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/workflows/ci.yml:9-11`,
`https://raw.githubusercontent.com/astral-sh/uv/main/.github/workflows/ci.yml:12-14`,
`https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/ci.yml:19-21`
(2026-09-18).

### Compatibility

The four members are not four independent choices; they are one file, and the proof
that they compose is that the file exists and passes the platform's own type-checker.

1. **One artifact, linted.** All four members were written into a single candidate
   `.github/workflows/ci.yml` (164 lines, six job ids) under a `$TMPDIR` subdirectory
   and `actionlint` **1.7.12** exits **0** on it; the final file's sha256 is
   `862295bfba9c06bff6f4dc1fe81a484263b73cc9a98781fd6fb1933e80813252`. The four
   negative controls (NC1–NC4) each mutate one
   member's contract and three of the four are rejected, which is what shows the
   members are actually wired to one another rather than merely co-located: NC1 and
   NC4 break the detector-to-topology relay and fail; NC3 breaks the contexts
   available to a gate and fails.
2. **A shared adopter for three of the four.** `astral-sh/uv` runs a hand-rolled
   plan-job detector (member 1), positive-predicate `== 'true'` gates, the
   number-or-sha concurrency key (member 4), and — in the same plan job — a
   `save_rust_cache` output that gates whether the Rust cache is written at all, which
   is member 2's cache-budget concern solved by member 1's mechanism. It does not
   adopt member 3's separate floor job, so the compatibility claim stops there rather
   than being stretched.
3. **A version matrix where one applies.** Only member 3 names a crate. `cargo-hack`
   0.6.45 declares `rust_version` `1.85` and is invoked as a `cargo` subcommand, so
   its compatibility surface with the other members is a single row: it must be
   installable on `ubuntu-latest`, which is the P03 check named in that member and is
   **not** claimed as proven here.
4. **Compatibility with the accepted-but-unpublished inputs**, each checked rather
   than assumed: R10's action reference and inputs appear verbatim in every
   cache-bearing job of the candidate; R50's `install-smoke` appears as one
   `ubuntu-latest` job gated by this item's `code` key, which is exactly the shape
   R50's decision asked for; R02's `B3` is honoured by the root-scoped feature-off
   test step; R69 revision 10's skip-gating keys are the `web` key's paths; R17's,
   R18's and R86's jobs are **not** in this file, which is the compatibility claim
   for them — they are separate workflow files whose preflight pattern this item's
   detector mirrors structurally (NC3 shows why both must be jobs).

### Parameters

The owned value is one line; the five assumed lines follow it, each reproduced
byte-for-byte from the live `docs/port/PARAMETERS.md` rows.

- owns ci-job-structure = checks are partitioned into GitHub Actions jobs by whether they compile Rust, not by which check they are, inside one `.github/workflows/ci.yml` carrying exactly six job ids. Tier 0 is one always-run `plan` job on ubuntu-latest with no toolchain, no `Swatinem/rust-cache` step and no `target/` directory, which after `actions/checkout` with `fetch-depth: 0` and `persist-credentials: false` runs one `shell: bash` step under `set -euo pipefail` that computes `git diff --no-ext-diff --no-textconv --name-only "${BASE_SHA}...HEAD"` with `BASE_SHA` read from `github.event.pull_request.base.sha` through the step `env:` block, and writes exactly four job outputs - `code`, `web`, `workflows`, `docs` - as the literal strings `true` or `false` and never as any other value, publishing `true` on all four for every event whose name is not `pull_request` so that pushes to main and merge-queue runs are never skip-gated; `code` is the negation of a skip-list of paths that cannot affect a compile, with `README.md` excluded from the skip-list because it is a packaging input, `web` keys on the paths R69 names, `workflows` keys on `.github/workflows/**` and `docs` keys on the prose tree, and a fifth key is added only when some job would be skipped by it that `code` does not already skip. Tier 1 is the non-compiling checks, each its own cheap job with no cache step: `hygiene`, which has no `needs` edge at all so that a formatter failure still reports when the compile tier is skipped, and `workflow-lint`, gated on `workflows`. Tier 2 is the compiling checks: ONE `check` job per entry in `target-os-matrix` through a `strategy.matrix` over `os` alone with `fail-fast: false` - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, `cargo test` with the feature off scoped by `-p` to the non-web packages so the feature-off property is proven rather than assumed, `cargo test --workspace --features web`, `cargo build --features web --bin <app>-serve` and `cargo doc`, as ordered steps sharing one `target/`, every command carrying `--locked`; plus `msrv-floor`, a separate single-runner job because a second toolchain must not share the stable job's cache key, verifying the declared `rust-version` on ubuntu-latest, which is the default that Cargo's own CI guide shows and which widens to every runner by substituting `runs-on: ${{ matrix.os }}` if the owner answers the open F033 cross-product question that way; plus `install-smoke`, R50's one ubuntu-latest job. Every gated job consumes the detector through `needs: plan` and a POSITIVE predicate `if: ${{ needs.plan.outputs.<key> == 'true' }}`, never a negated one, because a skipped or failed producer publishes an empty output map that a negated test reads as a reason to run; `actionlint` type-checks the output name and the `needs` edge but does NOT reject the negated form, so the rule is carried in prose. `ci.yml` carries no `on.<push|pull_request>.paths` or `paths-ignore` filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are `pull_request` and `push` restricted to `main`, plus `merge_group` so a queue's speculative merge still reports; it declares `permissions: {}` at workflow level with a per-job re-grant whose scopes are R08's; and it declares workflow-level `concurrency` with `cancel-in-progress: true` on a group keyed `ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.sha }}`, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and therefore keep populating the cache. This file holds no aggregate required-status job (R12's), no release, secret-scanning or AI-review job (separate workflow files), and every further check arrives as a named slot: a check that compiles nothing is a step of `hygiene`, a check that compiles what `check` already compiles is a step of `check`, and a check needing its own toolchain, its own runner or a `target/` it must not share becomes its own job with `needs: plan` and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**No `CONFLICT:` line is raised.** This prompt's `- consumes:` line names exactly one
researched parameter, `R69: web-extra-surface`, and nothing in this recommendation
needs its value changed: the design spends R69's skip-gating keys exactly as R69
states them, on a `web` output that gates web-exclusive jobs.

**A note the `assumes web-extra-surface` line above requires.** Those bytes are the
live registry row, which is revision 9's value and reads
`path-based skip-gating keys on src/web/**`. **R69 revision 10 is owner-accepted and
not yet published** (run `research/runs/R69/2026-09-18T020601Z-f304731ab06f`,
`review/DECISION.md` line 1791, sha256
`d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a`, owner rulings
`W1-R02` and `W0-R69c`): it declares the `web` feature on the root package naming the
optional member `crates/web`, puts the web integration tests in `crates/web/tests/`
with no file-level `#![cfg(feature = "web")]`, and reads
`path-based skip-gating keys on crates/web/**, the serve binary's source file and the
web test files`. **The design in this report uses revision 10's paths**, which is why
the candidate workflow's `web` key matches `^crates/web/` and the serve binary's
source file rather than `^src/web/`. R69 revision 10's **republication** is therefore
a re-verify trigger on this item, recorded as such in
`### Confidence & re-verify trigger`. This is a pending publication, not a
disagreement, so it is not a `CONFLICT:`.

**Three accepted decisions read as prose rather than as registry parameters**, because
none appears on this prompt's `- consumes:` line and an `assumes` line may not be
invented: R02's four-package workspace and its check `B3`; R10's
`Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` reference with
`env-vars: "ImageOS"`, `cache-on-failure: "true"` and `prefix-key: "v1-rslbp"`, and its
job-count arithmetic; and R50's single `install-smoke` job on `ubuntu-latest`.

### Migration implications

`rs-launch-blueprint` has no `.github/` tree today, so every row below is a creation.

| File | Change |
|---|---|
| `.github/workflows/ci.yml` | **New.** The whole subject of this item: `on` (`pull_request`, `push` to `main`, `merge_group`), `permissions: {}`, `concurrency`, and six jobs — `plan`, `hygiene`, `workflow-lint`, `check` (matrix over `os`), `msrv-floor`, `install-smoke` |
| `.github/workflows/ci.yml`, every cache-bearing job | R10's step verbatim, between the toolchain step and the first `cargo` command, plus its `- run: echo "ImageOS=$ImageOS"` observability line |
| `rust-toolchain.toml` | **Not created here.** R42 owns it; this item depends on it existing, because it is what lets the compile job need no toolchain-install action for the stable leg |
| `Cargo.toml` `[workspace.package] rust-version` | **Not written here.** R02 and `msrv-policy` own the value; `msrv-floor` only proves it |
| `justfile` | **Not written here.** `install-smoke` invokes R50's `install-check` recipe; R42's `package-manager-invocation` governs how recipes name tools |
| `.github/workflows/secret-scan.yml`, `claude-*.yml`, `codex-*.yml`, `release-please.yml`, `publish.yml` | **Untouched by this item.** R17, R18, R86, R25 and R68 own those files and set their own triggers, permissions and concurrency |
| Branch-protection configuration | **Untouched by this item.** R12 decides which check is required. This item only guarantees that whatever it requires can report on a docs-only pull request |

### Validation strategy

**Executed here.** Host: macOS 26.4 `arm64`; `actionlint` 1.7.12 at
`/opt/homebrew/bin/actionlint`; `bash` as the script interpreter; scratch under a
`$TMPDIR` subdirectory created and removed by this run. The candidate file's sha256 is
`862295bfba9c06bff6f4dc1fe81a484263b73cc9a98781fd6fb1933e80813252`, 164 lines.

**The candidate file, verbatim.** It is reproduced in full here because the scratch
directory that held it was deleted at the end of this run, and a sha256 of a file
nobody can open is not evidence. Everything below is the exact content whose hash is
recorded above; a reader can save it and re-run `actionlint` on it.

```yaml
# R11 candidate: plan-gated compile-tier CI. Tool choices inside each step are
# other items' (R27/R28/R30/R32/R35/R71/R82); this file is the job graph only.
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  merge_group:

permissions: {}

concurrency:
  group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.sha }}
  cancel-in-progress: true

jobs:
  # Tier 0 - always runs, no toolchain, no cache, no target/ directory.
  plan:
    name: plan
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      code: ${{ steps.detect.outputs.code }}
      web: ${{ steps.detect.outputs.web }}
      workflows: ${{ steps.detect.outputs.workflows }}
      docs: ${{ steps.detect.outputs.docs }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
          persist-credentials: false
      - name: Detect changed paths
        id: detect
        shell: bash
        env:
          EVENT_NAME: ${{ github.event_name }}
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
        run: |
          set -euo pipefail
          out() { printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"; }
          if [ "${EVENT_NAME}" != "pull_request" ]; then
            out code true; out web true; out workflows true; out docs true
            echo "INFO: ${EVENT_NAME} event - every job runs"
            exit 0
          fi
          changed="$(git diff --no-ext-diff --no-textconv --name-only "${BASE_SHA}...HEAD")"
          code=false; web=false; workflows=false; docs=false
          skip='^docs/|^\.vscode/|\.md$|^LICENSE-MIT$|^LICENSE-APACHE$|^\.github/ISSUE_TEMPLATE/'
          if printf '%s\n' "$changed" | grep -qx 'README\.md'; then code=true; fi
          if printf '%s\n' "$changed" | grep -vE "$skip" | grep -q .; then code=true; fi
          if printf '%s\n' "$changed" | grep -qE '^crates/web/|^src/bin/rslbp-serve\.rs$'; then web=true; fi
          if printf '%s\n' "$changed" | grep -qE '^\.github/workflows/'; then workflows=true; fi
          if printf '%s\n' "$changed" | grep -qE '^docs/|\.md$'; then docs=true; fi
          out code "$code"; out web "$web"; out workflows "$workflows"; out docs "$docs"
          echo "INFO: code=$code web=$web workflows=$workflows docs=$docs"

  # Tier 1 - always runs, toolchain but no compilation, so no rust-cache entry.
  hygiene:
    name: hygiene
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - name: Formatter check
        run: cargo fmt --all --check

  # Tier 1 - path-gated, no compilation. R29 owns the tools inside it.
  workflow-lint:
    name: workflow-lint
    needs: plan
    if: ${{ needs.plan.outputs.workflows == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - run: echo "actionlint slot"

  # Tier 2 - the one compiling job per OS. One target/ cache entry per OS.
  check:
    name: check (${{ matrix.os }})
    needs: plan
    if: ${{ needs.plan.outputs.code == 'true' }}
    runs-on: ${{ matrix.os }}
    permissions:
      contents: read
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
        with:
          env-vars: "ImageOS"
          cache-on-failure: "true"
          prefix-key: "v1-rslbp"
      - run: echo "ImageOS=$ImageOS"
      - name: Lint (default features; --workspace still compiles the optional web member, R02 check B3)
        run: cargo clippy --locked --workspace --all-targets -- -D warnings
      - name: Lint (web feature on)
        run: cargo clippy --locked --workspace --all-targets --features web -- -D warnings
      - name: Test (default features, root-scoped so the feature-off property is proven)
        run: cargo test --locked -p rs-launch-blueprint -p rs-launch-blueprint-core -p rs-launch-blueprint-cli
      - name: Test (web feature on, workspace-scoped)
        run: cargo test --locked --workspace --features web
      - name: Build the serve binary
        run: cargo build --locked --features web --bin rslbp-serve
      - name: Doc build
        run: cargo doc --locked --workspace --no-deps --features web

  # Tier 2 - the rust-version floor, its own job because it is its own toolchain.
  msrv:
    name: msrv-floor
    needs: plan
    if: ${{ needs.plan.outputs.code == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
        with:
          env-vars: "ImageOS"
          prefix-key: "v1-rslbp"
      - name: Verify the declared rust-version floor
        run: cargo hack check --locked --rust-version --workspace --all-targets --ignore-private

  # Tier 2 - R50's job, ubuntu only, gated on this file's code output.
  install-smoke:
    name: install-smoke
    needs: plan
    if: ${{ needs.plan.outputs.code == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
        with:
          env-vars: "ImageOS"
          prefix-key: "v1-rslbp"
      - run: just install-check

  # Slots this file leaves open, each a job id other items fill:
  #   coverage       (R35)  needs: plan; if code == 'true'; compiling -> its own cache entry
  #   deny / bans    (R02 F008, R13)  needs: plan; if code == 'true'
  #   docs-gate      (R82)  needs: plan; if docs == 'true' || code == 'true'
  #   openapi-snap   (R71, R84)  needs: plan; if web == 'true'
  #   ci-ok          (R12)  needs: [every job above]; if always()
```

**The lint run and its four negative controls.** Each control asserts that its
mutation actually changed the file **before** linting, because an earlier attempt in
this run produced a false pass: a `sed` using GNU's `0,/re/` address range is a no-op
under the BSD `sed` on this host, so the "control" linted an unmodified file and
reported exit 0. That failure mode is recorded rather than hidden, and the harness
now refuses to lint a mutation that did not apply.

```
=== candidate 164 lines, sha256 862295bfba9c06bff6f4dc1fe81a484263b73cc9a98781fd6fb1933e80813252
--- CONTROL (unmodified)
EXIT=0
  stdout: ''
--- NC1 misspell the relayed output name (code -> codee)
MUTATION APPLIED: yes
EXIT=1
  nc.yml:91:13: property "codee" is not defined in object type
  {code: string; docs: string; web: string; workflows: string} [expression]
  (3 diagnostic line(s) total)
--- NC2 negate the predicate (== 'true' -> != 'false')
MUTATION APPLIED: yes
EXIT=0
  (0 diagnostic line(s) total)
--- NC3 job-level if reads secrets.SOME_TOKEN
MUTATION APPLIED: yes
EXIT=1
  nc.yml:91:13: context "secrets" is not allowed here. available contexts are
  "github", "inputs", "needs", "vars". see https://docs.github.com/en/actions/
  learn-github-actions/contexts#context-availability for more details [expression]
  (3 diagnostic line(s) total)
--- NC4 first needs edge points at a job that does not exist
MUTATION APPLIED: yes
EXIT=1
  nc.yml:74:3: job "workflow-lint" needs job "planx" which does not exist in this
  workflow [job-needs]
  (2 diagnostic line(s) total)
```

The detector's shell body, extracted verbatim **from the file above** with only the
non-`pull_request` early-exit branch removed and `changed` driven from an argument,
run against nine synthetic changed-file lists:

| # | Changed files | `code` | `web` | `workflows` | `docs` |
|---|---|---|---|---|---|
| D1 | `docs/guide.md`, `CHANGELOG.md` | false | false | false | true |
| D2 | `README.md` | **true** | false | false | true |
| D3 | `crates/core/src/lib.rs` | true | false | false | false |
| D4 | `crates/web/src/routes.rs`, `crates/web/tests/web_api.rs` | true | **true** | false | false |
| D5 | `src/bin/rslbp-serve.rs` | true | **true** | false | false |
| D6 | `.github/workflows/ci.yml` | true | false | **true** | false |
| D7 | `Cargo.lock` | true | false | false | false |
| D8 | *(empty diff)* | false | false | false | false |
| D9 | `docs/a.md`, `crates/cli/src/main.rs` | true | false | false | true |

D2 is the case py's own comment calls out — `README.md` is a packaging input, so it is
deliberately **not** skippable. D8 is the degenerate case and is recorded rather than
hidden: an empty diff skips every gated job, all of which then report Success.

**Proposed for P03, not run here.** Nothing in this report has executed on a GitHub
runner; no workflow has been dispatched, no cache has been written, no check has been
required. The list is exhaustive so nothing here reads as proven:

| # | Check | Command or observation | Expected |
|---|---|---|---|
| V1 | A docs-only pull request | open one touching `docs/**` only | `check`, `msrv-floor`, `install-smoke` report **skipped**; `hygiene` reports success; total billable minutes under two |
| V2 | The required check is satisfied by the skip | with R12's check required, V1's pull request | mergeable, not "Expected" |
| V3 | The fail-open control | temporarily gate `check` on `!= 'false'` and skip `plan` | `check` **runs**, proving NC2's warning on a real runner; revert immediately |
| V4 | Cache partition | `GET /repos/<o>/<r>/actions/cache/usage` after a full matrix run | 4 entries, `active_caches_size_in_bytes` well inside 10 GB (R10 criterion A5) |
| V5 | Floor isolation | `msrv-floor` and `check (ubuntu-latest)` in the same run | distinct cache keys, no `target/` restored across (R10 criterion A3) |
| V6 | `ImageOS` observable | the `echo "ImageOS=$ImageOS"` step on both runners | non-empty on both (R10 criterion A7) |
| V7 | Feature-off purity | `cargo test -p rs-launch-blueprint -p …-core -p …-cli` | `crates/web` not compiled; contrast with `--workspace`, which compiles it (R02 check B3) |
| V8 | Web-exclusive gating | a pull request touching `crates/web/**` only | `web=true`; the future `openapi-snap` slot runs; `check` still runs both feature configurations |
| V9 | Concurrency | force-push a branch; then merge twice to `main` in quick succession | the superseded PR run is cancelled; both `main` runs complete |
| V10 | `merge_group` | enable a queue and enqueue a pull request | the workflow runs on `merge_group` and reports |

### Confidence & re-verify trigger

**Confidence, split because the halves are not equally supported.** The *topology
rule* — partition by compile, not by check — is **high**: it rests on an executed
result from another item (R02's `B3`), on an accepted item's written arithmetic and
threshold (R10), and on a vendor instruction that removes one alternative outright.
The *detector mechanism* is **high**: two directly relevant precedents implement it
identically and the platform's own documentation makes the job-versus-workflow choice
a policy. The *positive-predicate rule* is **high and now better supported than when
R18 and R86 stated it**, because NC2 executed here shows the linter will not catch its
violation. The *specific key set, step order inside `check`, and the concurrency group
key* are **medium**: they are judgements no measurement in this report settles, and
each is named as a P03 measurement rather than asserted.

**What this report does not claim.** No workflow ran on a GitHub-hosted runner. No
cache was written or measured. `cargo-hack`'s support for `macos-latest` was not
verified. The per-OS wall clock of the `check` job, which is the whole basis for
preferring step order over job parallelism, is **unmeasured**; the argument rests on
cache-entry count and duplicate compiles, which are structural, not on a timing.

re-verify on any of — R69 revision 10 **publishing**, at which point the registry's
skip-gating keys become `crates/web/**` and the `assumes` line above must be
re-derived; R02 publishing, or its F116 manifest-guard placement moving on P03's
measurement; R10's `save-if` changing, or P03's criterion-A5 measurement approaching
10 GB; R12 publishing and naming its required check, since its `always()` and `needs`
shape is constrained by this file's job ids; R13, R32 or R35 adding a compiling job
that takes the cache-bearing job count per runner past six; R42 naming a CI
toolchain-install action, which changes both the `check` and `msrv-floor` jobs' first
steps; the owner answering the open F033 question of whether the `rust-version` floor
is verified on every runner in `target-os-matrix`; GitHub changing the required-status
behaviour of a conditionally skipped job, which would invalidate the whole
job-versus-workflow argument; `actionlint` publishing a check that rejects a negated
`needs`-output predicate, which would let NC2's rule move from prose into lint;
`dorny/paths-filter` ceasing to be at `v4.0.3`/`ceb8a2b8f2d89434be7ff52d3de7ec3738c5cc9d`
**in a release that changes its filter or `base:` semantics**; or 2027-03-18, six
months from this report.

### Sources

**Platform documentation, read from `github/docs` at commit
`1fa3a6df3560daedd7c8a69e8eff1a730b58c1af` (`GET https://api.github.com/repos/github/docs/commits/main`,
committed 2026-09-18T20:31:56Z), all retrieved 2026-09-18.**
`content/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks.md`;
`data/reusables/pull_requests/path-filtering-required-workflows.md`;
`data/reusables/actions/jobs/section-using-jobs-in-a-workflow-needs.md`;
`data/reusables/actions/jobs/section-defining-outputs-for-jobs.md`;
`data/reusables/actions/jobs/section-using-conditions-to-control-job-execution.md`;
`data/reusables/actions/jobs/section-using-concurrency.md`;
`data/reusables/actions/workflows/triggering-a-workflow-paths1.md` and `…paths5.md`;
`content/actions/reference/workflows-and-actions/workflow-syntax.md`;
`content/actions/reference/workflows-and-actions/contexts.md`.

**Rust project publication.**
`https://doc.rust-lang.org/cargo/guide/continuous-integration.html` (2026-09-18).

**Source repositories at the programme pins.** `py-launch-blueprint` at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`: `.github/workflows/ci.yml` (lines 11-25
triggers and concurrency, 32-77 the `changes` job, 79-94 `lint`, 96-134 `typecheck`
and `import-boundaries`, 136-198 `test`, 200-262 `build-smoke`/`docs`/`toml-format`,
264-295 `ci-ok`), `.github/workflows/lint.yml` (lines 8-13 the path-filter comment,
30-64 `lint-changes`, 66-98 `actionlint` and `yamllint`), and the 19-file workflow
inventory from `git ls-tree -r --name-only b08bccfb .github/workflows/`.
`ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`:
`.github/workflows/ci.yml` (lines 30-37 triggers and `permissions: {}`, 40-106 the
single `ci` job, 141-188 the advisory `bun-lane` job) and its 8-file inventory.
**A correction to this prompt's `## Context`, offered because it is load-bearing for
the comparison**: ts's `ci.yml` at the pin has **two** jobs, not one — `ci` and
`bun-lane`, the latter `continue-on-error: true` and explicitly non-gating. The
prompt's characterisation that every check folds into one job holds for the *gating*
checks and is otherwise right; the second job is advisory and detects nothing.

**Ledger and programme records.** `docs/port/COMMONALITY.md` lines 39 (F033), 41
(F035), 44 (F038), 46 (F040), 47 (F041), 55 (F049), 56 (F050), 122 (F116);
`docs/port/BASELINE-REVIEW.md` lines 46, 141, 188, 256, 308;
`docs/port/PARAMETERS.md` (all five `assumes` values, byte-checked against the live
file); `docs/planning/p02/execution-ledger.md` (the owner's 2026-09-11 option-B
preflight choice, and the 2026-09-12 finding that a job-level condition cannot read
secrets); `docs/planning/p02/owner-decisions.md` section 11;
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` rows C3, C12,
C13, C14, C15 and Recommendation 7.

**Accepted-but-unpublished decisions, read at their run paths.**
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (four-package
workspace; checks `B1`, `B3`, `B4`; F116 tier);
`research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/DECISION.md` (the pinned
action reference, assertions `A3.6`/`A3.8`, criteria `A3`/`A5`/`A7`, the job-count
arithmetic and the six-per-OS threshold);
`research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md` (one
`install-smoke` job on `ubuntu-latest`, gated by this item's path filter);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` revision 10
(line 1791 `- owns web-extra-surface`, and lines 1613 and 1693 handing the `--features
web` axis and the two-runner test commands to R11);
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` criterion 9
(`cargo test` and `cargo test --features web` on both runners, "R11 owns the job
shape");
`research/runs/R86/2026-09-17T033528Z-db9e2a74f9a0/review/DECISION.md` (three jobs per
file, `credential-preflight` publishing a literal consumed by a positive predicate);
`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` (`dist` 0.33.0
in follower mode behind release-please, a separate workflow);
`research/runs/R44/2026-09-17T020715Z-ff8c50edbd69/review/DECISION.md`.
**Published decisions.** `research/topics/17-secret-scanning-ci-workflow/DECISION.md`
(one job on `pull_request` and `push` to `main`; "Which runner OS the single scan job
lands on (R11 owns this)");
`research/topics/18-ai-assisted-review-workflows/DECISION.md` (the preflight-job
pattern and the `!= 'none'` fail-open bug it found in itself);
`research/topics/20-third-party-action-pinning-policy/DECISION.md` (the
`enforced-owner-prefix-pinning` rule: full-SHA pins for every owner but `actions` and
`github`, with a trailing version comment);
`research/topics/42-dev-toolchain-provisioning/DECISION.md` (`rust-toolchain.toml`
with `profile = "minimal"`, `components = ["rustfmt", "clippy"]`);
`research/topics/49-build-target-declaration/DECISION.md` (the `rslbp` and
`<app>-serve` binary names and `target/` layout);
`research/topics/25-semver-bump-strategy/DECISION.md` and
`research/topics/26-packed-artifact-content-guard/DECISION.md` (release mechanics, in
their own workflow files).

**Figures, each with its endpoint and UTC retrieval.** `GET https://api.github.com/repos/<o>/<r>`
at 2026-09-18T22:10:09Z for `dorny/paths-filter`, `tj-actions/changed-files`,
`astral-sh/uv`, `tokio-rs/tokio`, `tokio-rs/axum`, `BurntSushi/ripgrep`,
`clap-rs/clap`, `sharkdp/bat`; at 2026-09-18T22:16:34Z for `taiki-e/cargo-hack` and
`rhysd/actionlint`.
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` at
2026-09-18T22:10:09Z (dorny 20, tj-actions 13) and 2026-09-18T22:16:34Z (cargo-hack 35).
`GET https://api.github.com/search/issues?q=repo:dorny/paths-filter+is:issue&sort=created&order=desc&per_page=10`
at 2026-09-18T22:14:56Z. `GET https://api.github.com/repos/dorny/paths-filter/releases/latest`
and `/git/ref/tags/v4.0.3` at 2026-09-18. `GET https://api.github.com/advisories/GHSA-mrrh-fwg8-r2c3`
at 2026-09-18T22:16:11Z. `GET https://crates.io/api/v1/crates/cargo-hack` and
`/versions` at 2026-09-18T22:16:21Z with a `User-Agent` header.
`https://rustsec.org/packages/cargo-hack.html` → **404** with
`https://rustsec.org/packages/atty.html` → **200** as the control, at 2026-09-18.
Workflow files from `https://raw.githubusercontent.com/<o>/<r>/<default-branch>/.github/workflows/…`
for `tokio` (`ci.yml`), `axum` (`CI.yml`), `ripgrep` (`ci.yml`), `clap` (`ci.yml`),
`bat` (`CICD.yml`), `uv` (`ci.yml`, `plan.yml`), all 2026-09-18; these are
branch-tip reads, not pinned commits, and that limit is stated rather than glossed.

**A correction this run made to itself, recorded because it is the kind of thing that
silently passes.** An earlier pass of the negative controls ran three of the four
against an intermediate draft rather than the final file, and one `sed`-driven
mutation did not apply at all (GNU's `0,/re/` address range is a no-op under the BSD
`sed` on this host), so a "control" linted an unmodified file and reported exit 0. All
four controls in `### Validation strategy` were re-run against the final file, whose
sha256 is stated there and whose full text is embedded, and each now asserts that its
mutation changed the file before linting.

**Method notes.** Endpoints queried: `api.github.com` (`repos/<o>/<r>`,
`search/issues`, `advisories/<ghsa>`, `repos/<o>/<r>/git/ref/tags/<tag>`,
`repos/<o>/<r>/releases/latest`, `repos/github/docs/commits/main`,
`repos/github/docs/contents/<path>?ref=<sha>`, `search/code`,
`advisories?ecosystem=actions&affects=<action>`), spaced at least 21
seconds apart; `crates.io/api/v1/crates/cargo-hack` and `/versions` with a `User-Agent`
header; `rustsec.org/packages/<name>.html` with a control package; `doc.rust-lang.org`;
`raw.githubusercontent.com` for `github/docs` reusables at the pinned commit and for
the six surveyed projects' workflow files. Source repositories were read only through
`git -C <repo> show <pin>:<path>`, never from a working tree. **What could not be
verified.** No GitHub Actions job was run, so every runtime claim about a real
runner — skip reporting, cache size, `ImageOS`, wall clock — is proposed and labelled
so. `cargo-hack`'s own CI platform coverage (fitness gate 4) was not inspected and is
recorded as unverified rather than assumed. Issue *responsiveness* for
`dorny/paths-filter` is reported as median days-to-close over the 10 most recently
opened issues, because first-maintainer-response timestamps would need one API call
per issue and were not fetched; all 10 carry at least one comment, so the unanswered
count is 0 on that weaker reading. The six surveyed projects' workflow files were read
at their default-branch tip rather than at a pinned commit, so their job counts are
reproducible only by date. Crate figures are `inapplicable` for three of the four
members and for the bundle as a whole, because those members are GitHub Actions and
Cargo invocation patterns rather than crates; the one crate named, `cargo-hack`,
carries the full figure set. The Codex research leg for this item was not run (owner
ruling `W1-CODEX3`, 2026-09-18), so nothing here has a second model family's
independent reading.
