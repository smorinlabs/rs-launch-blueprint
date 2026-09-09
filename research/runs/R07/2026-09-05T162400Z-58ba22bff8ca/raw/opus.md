# R07 — Contributors-bot trigger cadence (pattern) — raw answer (engine: opus)

Item kind: `pattern`. Decision scope: the `on:` block of the template's
`.github/workflows/update-contributors.yml` only. All retrieval dates are UTC
(`date -u`, 2026-09-09) unless a cited page states its own date.

### Landscape

**Category this item decides.** The *event contract* of a repository-automation
workflow: which GitHub Actions event(s) cause an idempotent, PR-opening
contributors-list regenerator to run. The unit of choice is a GitHub Actions
`on:` key (`push`, `schedule`, `workflow_dispatch`, `pull_request`,
`issue_comment`, `workflow_run`), not a Rust crate. Nothing in this item is
language-specific: the tool it fires (`smorinlabs/contributors-please-action`,
inherited as-is under F060) reads git history and runs on `ubuntu-latest`, so
the same `on:` block would be correct for a Python, TypeScript or Rust
repository. That is why the Rust-crate figure table is `inapplicable` here (see
`### Excluded by gate`).

**Three-bin map of the field.**

| Bin | Candidates found | Evidence |
|---|---|---|
| Built-in / first-party toolchain | `on: push` (with `branches` + `paths-ignore`), `on: schedule` (POSIX cron), `on: workflow_dispatch`, `on: pull_request` (`types: [closed]`), `on: workflow_run` | GitHub's own events reference lists every one of these as a first-class workflow trigger (https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows, retrieved 2026-09-09) |
| Established industry standard | (a) **push-to-default-branch + path filter + manual dispatch** — the shape documented by the action this template actually uses, and by `akhilmhdh/contributors-readme-action`; (b) **cron + manual dispatch** — `BobAnkh/add-contributors`; (c) **cron + push hybrid** — `wow-actions/contributors-list`; (d) **human-comment-triggered** — the All Contributors bot (`@all-contributors please add …`) | READMEs cited under `### Options` |
| Up-and-comer | No new trigger mechanism has appeared for this problem. The only movement is *away* from event-shaped bots toward comment-driven curation (All Contributors app) — see `### Up-and-comers`. |

**Authorities used, and why each is authoritative.**

1. **GitHub's own Actions documentation** — the normative specification for what
   each trigger does and what its limits are. It is the only source that can
   settle whether `paths-ignore` applies to `schedule` or whether a cron is
   auto-disabled. Pages: the events reference and the workflow-syntax reference
   (https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
   and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax,
   both retrieved 2026-09-09), plus the workflow enable/disable how-to
   (https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows,
   retrieved 2026-09-09).
2. **The maintainer's own documentation for the inherited tool** —
   `smorinlabs/contributors-please-action`'s README is the tool author's stated
   correct usage, and it is the tool F060 fixes for this template. Retrieved
   from https://raw.githubusercontent.com/smorinlabs/contributors-please-action/main/README.md,
   2026-09-09.
3. **The two pinned source repositories**, read at the SHAs the port ledger
   pins, so the divergence is quoted rather than remembered (py
   `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, ts
   `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`).
4. **Competing contributors-list actions' READMEs**, as practice evidence for
   what the field recommends when it is not this owner's tool.

A single blog post was not used as an authority anywhere in this answer; every
behavioral claim below resolves to GitHub's documentation or to a file read at a
pinned or `main` revision.

**Practice evidence — mainstream, well-regarded Rust projects.** I listed
`.github/workflows` for twelve widely-adopted Rust projects through
`GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows`
(retrieved 2026-09-09) and searched each listing for a contributors-list
workflow:

| Project | Why it is a relevant, well-regarded reference | Contributors-list workflow? |
|---|---|---|
| `rust-lang/cargo` | Rust project's own package manager, maintained by the Cargo team | **No.** Its only `contrib*` workflow is `contrib.yml`, an mdBook *contributor-guide* deploy on `on: push: branches: [master]` (https://raw.githubusercontent.com/rust-lang/cargo/master/.github/workflows/contrib.yml, retrieved 2026-09-09) — a docs deploy, not a contributors list |
| `tokio-rs/tokio` | the de-facto async runtime; 7 workflows | No |
| `clap-rs/clap` | the de-facto CLI parser; 10 workflows | No |
| `BurntSushi/ripgrep` | canonical Rust CLI, maintainer is a widely-cited Rust author; 2 workflows | No |
| `sharkdp/bat` | canonical Rust CLI; 2 workflows | No |
| `astral-sh/ruff`, `astral-sh/uv` | newest high-adoption Rust tools (20 and 43 workflows — heavy CI users, so absence is a choice not an oversight) | No |
| `starship/starship`, `helix-editor/helix`, `nushell/nushell`, `tauri-apps/tauri`, `meilisearch/meilisearch` | large, active, community-contribution-heavy Rust projects | No |

**Reading of that result:** the mainstream Rust field supplies *no* precedent
for a contributors-list bot at all, in either cadence. Therefore Rust practice
cannot decide this item, and the decision must rest on (a) GitHub's documented
trigger semantics, (b) the inherited tool's documented usage, and (c) the
template's own operating profile. This is a genuine evidence gap, reported
rather than papered over. Adoption of the inherited action outside the owner's
own repositories is also effectively nil: GitHub code search for
`contributors-please-action path:.github/workflows` returns `total_count: 21`,
and with `-org:smorinlabs` returns `total_count: 1`, whose single hit is the
owner's own `smorin/toggle` repository (retrieved 2026-09-09). The prompt's
`## Out of scope` forbids citing prior art in the owner's other repositories, so
that hit is counted and then set aside, not inspected.

### Principles and implementation

**Shared requirement, source, and agreement level.** F060
(`docs/port/COMMONALITY.md`, `COMMON → REUSE`, classified *retained* in
`docs/port/BASELINE-REVIEW.md`) states the principle: *"The contributors list is
regenerated by a bot that opens a pull request rather than committing to
`main`."* Its agreement level is recorded as **policy/mechanism**. F026 (origin
`different`, verdict `DIVERGENT`, item R07) records the part that does *not*
agree: the trigger cadence.

**What must agree across py, ts and rs.** Three behaviors, all independent of
language:

1. Regeneration is automatic — no human must remember to run it.
2. The result reaches `main` only through a reviewable pull request (F060,
   `mode: pull-request`).
3. The workflow is loop-free: the bot's own merged output must not cause the bot
   to run again in a way that produces another PR.

**What may vary.** The event that fires it, because that choice is driven by
each repository's merge frequency and workflow-run budget, not by its language.
F026's very existence in the ledger as `different` records that the owner
already treats cadence as the varying part.

**Observable acceptance criteria** (these are the checks `### Validation
strategy` operationalizes):

- A1: merging a pull request from a first-time contributor to `main` causes
  exactly one `Update Contributors` workflow run, which opens or updates exactly
  one bot pull request containing that contributor.
- A2: merging that bot pull request causes **zero** further `Update
  Contributors` runs.
- A3: a maintainer can force a regeneration at any time with no code change
  (`workflow_dispatch`).
- A4: the recognition latency between "contributor's PR merges" and "bot PR
  exists" is bounded and stated.

**Architectural alternatives, compared before any library question.** Four
distinct architectures exist for triggering contributor recognition, and they
differ in *what kind of signal* they treat as authoritative:

| Architecture | Authoritative signal | Latency | Loop risk | Fails silently? |
|---|---|---|---|---|
| **Event-driven** (`push` to default branch) | the merge itself | seconds | real — needs `paths-ignore` on the generated files | no; a failure is attached to a visible merge |
| **Time-driven** (`schedule`) | the clock | up to one period | none — no event follows the merge | **yes** — see the two documented disable rules below |
| **Human-driven** (comment command, All Contributors) | a maintainer's comment | human | none | yes, silently unrecognized contributors |
| **Chained** (`workflow_run` after CI) | another workflow's completion | seconds after CI | inherits CI's | no, but adds a second failure surface |

The decisive, documented facts that separate them:

- **Path filters do not exist for `schedule`.** GitHub's workflow-syntax
  reference titles the section `on.<push|pull_request|pull_request_target>.<paths|paths-ignore>`
  and states: *"When using the push and pull_request events, you can configure a
  workflow to run based on what file paths are changed."*
  (https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax,
  retrieved 2026-09-09). This answers the MEDIUM question outright: a path
  filter is not merely redundant under a schedule, it is **not a valid key for
  that event**.
- **`paths-ignore` semantics make it a correct loop guard.** *"When all the path
  names match patterns in `paths-ignore`, the workflow will not run. If any path
  names do not match patterns in `paths-ignore`, even if some path names match
  the patterns, the workflow will run."* (same page, retrieved 2026-09-09).
  Because the bot PR touches only `CONTRIBUTORS.md` and `.contributors.jsonl`,
  merging it matches every path in the ignore list and produces no run — A2
  holds. A human PR that happens to touch `CONTRIBUTORS.md` alongside code still
  runs, which is the desired behavior.
- **The inherited tool's author documents `push` + `paths-ignore` and warns
  against the alternative loop guard.** The action README's canonical usage
  block is `on: push: branches: [main] / paths-ignore: [CONTRIBUTORS.md,
  .contributors.jsonl]` plus `workflow_dispatch:` (README lines 13–19), and it
  states: *"In `mode: pull-request`, a `[skip ci]` trailer … stays at 'Expected
  — waiting for status to be reported' forever. For loop protection in
  pull-request flows, use `paths-ignore` on the generated files … instead of
  `[skip ci]`."* (README lines 69–75, retrieved 2026-09-09). The action ships no
  scheduled example.
- **A schedule can be switched off without anyone noticing — twice over.**
  GitHub: *"In a public repository, scheduled workflows are automatically
  disabled when no repository activity has occurred in 60 days"* and *"When a
  public repository is forked, scheduled workflows are disabled by default"*
  (https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows,
  retrieved 2026-09-09; the 60-day rule is repeated verbatim on the events
  reference page). Additionally: *"The `schedule` event can be delayed during
  periods of high loads of GitHub Actions workflow runs. … If the load is
  sufficiently high enough, some queued jobs may be dropped."* and *"Scheduled
  workflows will only run on the default branch."* (events reference, retrieved
  2026-09-09).

That last bullet is the finding that reverses the naive reading of the prompt.
The prompt frames the tradeoff as "noise versus one week of latency", but for
**a template repository** — a low-commit-frequency artifact that other people
fork and instantiate — the time-driven architecture has a third, worse failure
mode: the recognition mechanism silently stops existing. A quiet template
crosses 60 days of no activity easily; every fork starts with the cron already
off. The event-driven architecture has no equivalent silent-off state.

**Verifying the shared pattern still fits the target ecosystem.** F060's pattern
(bot PR, not a push to `main`) remains appropriate in Rust for a reason
independent of the trigger: the template's `main` carries required status checks
(F024, F025), so a direct bot push would bypass review while a bot PR does not.
Nothing about Rust, Cargo, or edition 2024 interacts with the `on:` block. The
principle is preserved identically in all three ecosystems; only the cadence
value differs, and this answer argues it should differ *less* than it currently
does.

**Reference implementation.** The maintained reference implementation is the
action's own README usage block
(https://github.com/smorinlabs/contributors-please-action#readme, v1.3.9
published 2026-06-17T20:19:47Z, repo not archived, `pushed_at`
2026-09-01T22:51:20Z, MIT, 1 open issue via
`GET https://api.github.com/search/issues?q=repo:smorinlabs/contributors-please-action+is:issue+is:open`,
all retrieved 2026-09-09). py's pinned workflow is a faithful instance of it
(`.github/workflows/update-contributors.yml:3-9`). Maturity, dependability and
integration cost are identical across the candidate triggers — they are the same
16 lines of YAML with a different `on:` key — so the comparison is decided on
failure modes, not on cost. Representative performance: the job is one
`actions/checkout` with `fetch-depth: 0` plus one Node action step; its cost is
tens of seconds of `ubuntu-latest` time per run, free on public repositories and
billable on private ones under GitHub's Actions billing rules (quoted with its
URL in `### Excluded by gate`, gate 6).

**BASELINE-REVIEW findings:** none. F060 is retained unchanged by this item, and
this item does not challenge any `COMMON → REUSE` or `ADOPT` row.

### Dominant choice

**Push to the default branch, filtered by `paths-ignore` on the generated files,
plus `workflow_dispatch`.** It is dominant on all three of the survey's
authority tiers that have anything to say: it is the inherited tool's own
documented usage (README lines 13–19), it is what the higher-starred independent
competitor recommends (`akhilmhdh/contributors-readme-action`, 204 stars, README
`on: push: branches: [main]`), and it is what the pinned Python source ships
(py `.github/workflows/update-contributors.yml:3-9`). It is not dominant by
count of surveyed Rust projects, because the Rust field has no instances at all;
that gap is stated in `### Landscape` rather than filled by inference.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **A. `push` to default branch + `paths-ignore` on generated files + `workflow_dispatch`** | `smorinlabs/contributors-please-action` README lines 13–19 and 69–75 (https://raw.githubusercontent.com/smorinlabs/contributors-please-action/main/README.md) | py-launch-blueprint at `b08bccf`, `.github/workflows/update-contributors.yml:3-9` (`branches: [main]`, `paths-ignore: [CONTRIBUTORS.md, .contributors.jsonl]`, `workflow_dispatch:`) | action v1.3.9, published 2026-06-17; repo `pushed_at` 2026-09-01 (retrieved 2026-09-09) |
| **B. `push` to default branch, no path filter** | `akhilmhdh/contributors-readme-action` README lines 34–48 (`on: push: branches: [main]`) | that action's documented consumers; 204 stars, MIT, not archived, `pushed_at` 2025-07-27, 9 open issues (retrieved 2026-09-09) | README at `master`, repo last pushed 2025-07-27 |
| **C. `schedule` (weekly cron) + `workflow_dispatch`, no push** | ts-launch-blueprint at `cb1cbcb`, `.github/workflows/update-contributors.yml:49-52` (`cron: '17 6 * * 1'`, "weekly, Monday 06:17 UTC"), rationale in the file header at `:33-39` | ts-launch-blueprint only, among the repositories surveyed | the ts file header itself, which records that "neither the source file nor contributors-please-action's own documented usage example runs on a schedule" (read 2026-09-09 at the pinned SHA) |
| **D. `schedule` (daily cron), push commented out** | `BobAnkh/add-contributors` README lines 22–27 (`cron: '20 20 * * *'`, `# push:` commented) | that action's consumers; 42 stars, Apache-2.0, not archived, `pushed_at` 2023-02-20 (retrieved 2026-09-09) — the action is quiet | README at `master`; no release activity since 2023-02-20 |
| **E. Hybrid `schedule` + `push`** | `wow-actions/contributors-list` README lines 17–24 (`cron: '0 1 * * 0'` **and** `push: branches: [master]`) | that action's consumers; 59 stars, MIT, not archived, `pushed_at` 2024-10-18 (retrieved 2026-09-09) | README at `master`, repo last pushed 2024-10-18 |
| **F. Human comment command (no automatic trigger)** | All Contributors bot — `@all-contributors please add @user for code` | `all-contributors/app` (634 stars, MIT, not archived, `pushed_at` 2026-05-27) and `all-contributors/allcontributors.org` (8,098 stars, MIT, `pushed_at` 2026-09-03), retrieved 2026-09-09 | the app repository, last pushed 2026-05-27 |

No download columns are shown, per the template's instruction for `pattern`
items; the star, archive, push-date and open-issue figures above all come from
`GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`,
retrieved 2026-09-09.

**Maintenance state by rubric** (for the documentation sources, not for a
dependency this template takes on — the template depends on none of B, D, E or
F):

- `smorinlabs/contributors-please-action` — **active**: v1.3.9 released
  2026-06-17, `pushed_at` 2026-09-01, not archived, 1 open issue, 0 stars.
  Zero stars is reported rather than omitted; it reflects that the action is a
  new first-party tool with no external adoption, and it is not a selection
  signal here, because F060 fixes the tool and this item does not choose it.
- `akhilmhdh/contributors-readme-action` — **stable-quiet**: no push since
  2025-07-27 (over 6 months, which the rubric makes a trigger to investigate,
  not a verdict); not archived, no maintainer notice of abandonment found, 9
  open issues.
- `wow-actions/contributors-list` — **stable-quiet**: `pushed_at` 2024-10-18,
  not archived, no abandonment notice found.
- `BobAnkh/add-contributors` — **at-risk**: concrete signal is a push gap of
  more than three years (`pushed_at` 2023-02-20) on a repository that is not
  archived and carries no maintenance notice; its guidance is cited only as
  historical practice evidence, never as a recommendation.
- `all-contributors/app` — **active**: `pushed_at` 2026-05-27, not archived.

### Excluded by gate

**No candidate is excluded by a fitness gate.** Every option in `### Options` is
an `on:` key in a GitHub Actions workflow file, so five of the six gates have no
subject to attach to. Stated explicitly rather than omitted, per the tier
guidance:

1. **License compatible with `MIT OR Apache-2.0`** — `inapplicable`: a workflow
   trigger is GitHub Actions workflow syntax, not a redistributable artifact,
   so no license attaches to it. For completeness, the action the trigger fires
   (inherited under F060, not chosen here) is MIT (`spdx_id: MIT` from
   `GET https://api.github.com/repos/smorinlabs/contributors-please-action`,
   retrieved 2026-09-09), which is compatible with `MIT OR Apache-2.0`.
2. **Crate and dependency-tree MSRV** — `inapplicable`: no crate and no Rust
   dependency tree is involved. The workflow compiles no Rust; it checks out the
   repository and runs a JavaScript action. The owner-fixed `msrv-policy` is
   therefore untouched by every option.
3. **No open RustSec advisory; `unsafe` posture** — `inapplicable`: there is no
   crate to look up at `https://rustsec.org/packages/<name>.html`, and no Rust
   code, hence no `unsafe` posture. (The security-relevant question adjacent to
   this workflow — token scope and credential source — is owned by R08/F030 and
   R21/F061, not by this item.)
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — **satisfied
   identically by every option, and not discriminating.** The trigger determines
   *when* a job starts, not where it runs; the job itself is pinned to a single
   Linux runner in both sources (py `:18` `runs-on: ${{ vars.RUNNER_UBUNTU ||
   'ubuntu-latest' }}`; ts `:60` `runs-on: ubuntu-latest`). Windows: not
   required and not used.
5. **Default features and async-runtime coupling** — `inapplicable`: Cargo
   features and Rust async runtimes are not properties of a workflow trigger.
   The nearest real coupling is to the merge-queue and required-check
   configuration (F024, F025), and it is unaffected by any option here, because
   this workflow reports no required check.
6. **Binary-size and compile-time cost** — `inapplicable` as stated (no binary,
   no compilation). The analogous cost, stated qualitatively so the gate's
   intent is still served: option A adds at most one short `ubuntu-latest` job
   per push to `main` that touches a non-generated file; option C adds exactly
   52 such jobs per year regardless of activity; option E adds both. Each job is
   one shallow-history checkout plus one Node action step — tens of seconds,
   free on public repositories and billable on private ones: "GitHub Actions
   usage is free for self-hosted runners and for public repositories that use
   standard GitHub-hosted runners. For private repositories, each GitHub account
   receives a quota of free minutes … Any usage beyond the included amounts is
   billed to your account."
   (https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions,
   retrieved 2026-09-09).

Option D is set aside on maintenance evidence (its action is `at-risk`, see
`### Options`), not by a gate. Option C is rejected on documented reliability
evidence in `### Tradeoffs`, not by a gate.

### Up-and-comers

There is no emerging *trigger mechanism* for this problem: GitHub has added no
new event suited to it, and `schedule`, `push` and `workflow_dispatch` have been
stable for years. The one genuinely different and still-growing approach is
**human-curated, comment-driven recognition** — the All Contributors bot, where
a maintainer writes `@all-contributors please add @user for code` and the bot
opens the PR (`all-contributors/allcontributors.org`, 8,098 stars, `pushed_at`
2026-09-03; `all-contributors/app`, 634 stars, `pushed_at` 2026-05-27, both
retrieved 2026-09-09). It is an up-and-comer in the sense that matters here: it
is the only approach with materially more community adoption than any
git-history-driven action surveyed, and it deliberately trades automation for
attribution quality (it records *what kind* of contribution someone made,
including non-code work git history cannot see).

It is not recommended for this template, for two reasons that are decisions
already made elsewhere: it would replace the inherited tool
(`contributors-please-action`, fixed by F060 and explicitly out of scope), and
it violates acceptance criterion A1's "no human must remember" property. It is
recorded here as the live alternative architecture a future owner review might
reconsider, and as the reason a low absolute adoption count for either cadence
is not evidence that automated cadence is wrong.

A second, lower-profile emerging shape worth naming: **`workflow_run`-chained**
triggering, firing the bot after the CI workflow completes on `main` rather than
on the push itself. It is a real GitHub event (events reference, retrieved
2026-09-09) and it would serialize the bot behind CI, but it adds a second
failure surface and no benefit here, since the bot does not depend on CI's
result.

### Fit for this template

The `on:` block is a property of the **repository**, not of any compiled target,
so the honest answer per shape is that this decision is **shape-invariant** —
one workflow file serves all three shapes, and there is no per-shape variant to
design. Arguing each shape separately, as the template requires:

- **CLI.** No interaction. The CLI crate's build, test and release paths never
  read `CONTRIBUTORS.md` or `.contributors.jsonl`. The only indirect coupling is
  that a push-triggered run adds one job alongside the CLI's own per-push CI
  jobs; at the template's expected merge frequency that is a small fraction of
  the existing CI/CodeQL/dependency-review load already documented in F024,
  F027 and F046. Fit: option A is unproblematic.
- **Library.** No interaction with the public-API surface, `pub use` re-exports,
  semver checking or docs.rs publication. `CONTRIBUTORS.md` is not packaged
  content and not part of the crate's API. One consideration in the library
  direction actually *favors* the push shape: library releases are cut by
  release-please from pushes to `main` (F073), so `main` receives bot commits
  between human merges; `paths-ignore` correctly lets those through (they touch
  files other than the two ignored ones) so a release
  commit refreshes the contributors list too, at no extra configuration cost.
- **Web service** (optional, behind a Cargo feature per F017 / `web-extra-surface`).
  No interaction. The workflow never builds the web feature, never starts a
  server, and does not participate in the OpenAPI or container lanes. Fit is
  identical to the CLI case.

The one property that *is* specific to this repository — and it cuts across all
three shapes — is that it is a **template**. Two documented consequences follow,
and they are what actually decide the item: a template instance that goes quiet
for 60 days has its scheduled workflows automatically disabled if public, and
every fork of a public template starts with scheduled workflows disabled by
default (GitHub, disable-and-enable-workflows, retrieved 2026-09-09). A template
should ship the trigger that behaves correctly in a downstream repository the
owner will never see, which is the trigger with no silent-off state.

### Recommendation

Adopt **option A** — py's shape, which is also the inherited action's documented
usage:

```yaml
on:
  push:
    branches: [main]
    paths-ignore:
      - CONTRIBUTORS.md
      - .contributors.jsonl
  workflow_dispatch:
```

Answers to the prompt's questions, in order:

- **HIGH — push or schedule?** Push. The prompt's framing (immediate recognition
  versus stacked runs) is real but is not the deciding axis. The deciding axis is
  that `schedule` has two documented ways to become silently inert — 60 days of
  repository inactivity in a public repo, and forking — and a template repository
  is exactly the artifact most exposed to both. A push trigger has no equivalent
  state. Secondary support: it is the trigger the inherited tool's own README
  documents, and ts's own file header at `:33-39` concedes that "neither the
  source file nor contributors-please-action's own documented usage example runs
  on a schedule".
- **HIGH — if scheduled, what cadence?** Moot under this recommendation as the
  primary trigger. If a schedule is added as the backstop described in
  `### Ranked runner-up`, use **monthly** (`cron: '17 6 1 * *'`), not weekly:
  a backstop's job is to bound the damage of a missed push run, and monthly
  bounds it at 31 days for 12 runs per year instead of 52. Do not schedule on
  the hour — GitHub advises "schedule your workflow to run at a different time
  of the hour" because the top of the hour is its peak-load window (events
  reference, retrieved 2026-09-09); ts's `:17` minute offset is correct practice
  and should be carried over.
- **HIGH — principles and agreement level?** Covered in
  `### Principles and implementation`. The shared principle (F060,
  policy/mechanism) is automatic, PR-mediated, loop-free regeneration; the
  cadence is the part free to vary. Recommending option A for Rust makes rs
  agree with py rather than with ts. This is a justified convergence, not
  accidental copying: the argument rests on GitHub's documented `schedule`
  semantics and on the tool's own documentation, both of which apply verbatim to
  py and ts. The follow-on project for py and ts should therefore leave py
  unchanged and reconsider ts's schedule-only shape — the rationale is supplied
  here, and no change to another item or to the ledger is made by this answer.
- **MEDIUM — does a path filter still make sense under a schedule?** No, and
  more strongly than "moot": `paths`/`paths-ignore` are documented only for
  `push`, `pull_request` and `pull_request_target`, so they are not a valid key
  under `schedule` at all. Under option A the path filter is not optional
  decoration — it is the loop guard the action's README explicitly requires for
  `mode: pull-request`, in place of `[skip ci]`, which would strand the bot PR
  at "Expected — waiting for status to be reported" forever.
- **LOW — keep `workflow_dispatch`?** Yes, unconditionally. Both sources have
  it, the action's README documents it, it costs nothing when unused, and it is
  the only mechanism satisfying acceptance criterion A3 (force an out-of-cycle
  update without a code change). It also serves as the manual recovery path if a
  push-triggered run fails transiently.

### Ranked runner-up

**Option E — `push` + `paths-ignore` + a *monthly* `schedule` + `workflow_dispatch`.**
This is the recommendation plus a backstop, and it is the shape
`wow-actions/contributors-list` documents (README lines 17–24, retrieved
2026-09-09). It ranks second, not first, because it adds 12 runs per year and a
second failure surface for a benefit that only materializes in a narrow case.

**The condition under which it wins:** when a push-triggered run can fail
transiently and nobody will notice. Concretely, if the credential source R21
settles on App credentials or a PAT that can expire or be revoked (F061 is open
under R21), a push run failing on authentication produces one red run on a merge
nobody is watching, and the contributors list then stays stale until the next
merge — which, for a quiet template, may be months. A monthly cron retries
automatically and bounds that staleness at 31 days. If R21 instead settles on
`secrets.GITHUB_TOKEN`, which cannot expire or be revoked out from under the
workflow, this condition largely evaporates and option A stands alone.

**Second runner-up, for completeness: option C (ts's current schedule-only
weekly shape).** It wins only if the owner later decides that runs on `main`
must be minimized to a hard budget — for example, a private instantiation on a
metered minutes plan where every job is billable — and accepts both the up-to-
seven-day latency and the silent-disable exposure. That is a budget decision, not
an engineering one, and no evidence gathered here supports it for this template.

### Tradeoffs

**What option A gives up versus option E (the ranked runner-up).** It gives up
automatic retry. A push run that fails for a transient reason — credential
expiry, a GitHub API blip, a runner failure — is not retried until the next push
to `main` that touches a non-generated file. On a quiet template that can be a
long gap. This cost is accepted because (a) the failure is visible: it appears as
a red run attached to a merge commit on `main`, unlike a cron that simply stops
being scheduled, which produces *no* signal at all; (b) `workflow_dispatch` is
retained precisely as the manual recovery path; and (c) adding the cron is a
two-line change that can be made later if R21's credential decision creates the
expiry risk described above. Accepting a visible, recoverable failure in place
of an invisible one is the correct direction of trade.

**What option A gives up versus option C (ts's schedule-only shape).** It gives
up run-count minimalism: one extra `ubuntu-latest` job on each push to `main`
that touches something other than the two generated files, versus a fixed 52 per
year. Whether that is more or fewer runs depends entirely on merge frequency —
below one qualifying merge per week, option A is in fact the *cheaper* of the
two, and the prompt itself describes this template as having "presumably lower
commit frequency than either source's production repo". The cost is accepted
because the runs are short, free on public repositories under GitHub's Actions
billing rules (quoted in `### Excluded by gate`, gate 6), and additive to a
per-push load (CI, CodeQL, dependency-review) that is already several jobs
deep — one more short job is a small marginal change to a maintainer's Actions
tab, whereas the thing option C risks is the mechanism ceasing to exist.

**What option A gives up versus option B (push with no path filter).** Nothing
of value; it adds two lines. Option B is strictly worse: without `paths-ignore`,
merging the bot's own PR pushes `CONTRIBUTORS.md` and `.contributors.jsonl` to
`main`, which fires the workflow again, violating acceptance criterion A2. The
action's README rules out the obvious alternative guard (`[skip ci]`) for
`mode: pull-request` because it strands the PR on required checks.

**What option A gives up versus option F (comment-driven All Contributors).** It
gives up contribution-type attribution — recognition for documentation, design,
triage, and other non-code work that git history cannot see — and it gives up the
maintainer's editorial control over who appears. That is a real loss, and it is
accepted because F060 fixes the tool and explicitly places it out of scope for
this item; option F is not this item's to choose. It is recorded in
`### Up-and-comers` so a future owner review can weigh it deliberately.

### Parameters

- `owns` — none. R07 owns no entry in `docs/port/PARAMETERS.md` (the registry's
  `owner` column names no parameter for R07, and the prompt's `## Couplings`
  `owns:` field is empty).
- `assumes rust-edition = 2024` — consumed unchanged; a workflow trigger does
  not interact with the Cargo edition.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — consumed unchanged; the workflow compiles no Rust.
- `assumes license = MIT OR Apache-2.0` — consumed unchanged; the recommendation
  adds no dependency, and the inherited action is MIT.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — consumed unchanged;
  this workflow is a single-runner job on `ubuntu-latest` and does not
  participate in the OS matrix, which governs the test matrix (F032), not
  repository-automation workflows.
- No `CONFLICT:` lines. The recommendation needs no consumed parameter to change.

Note for the registry, not a parameter claim: R11 owns `ci-job-structure`, whose
description covers "how path-filtered skip-gating is applied" for CI checks. The
`paths-ignore` recommended here is a loop guard on a non-CI automation workflow
that reports no required status check, not a skip-gate on a required check, so
it does not consume or constrain `ci-job-structure`. Recorded so the two are not
conflated at integration.

### Migration implications

File-level changes in the template, all confined to one file:

1. **`.github/workflows/update-contributors.yml`** — write the `on:` block as
   the four keys shown in `### Recommendation`: `push.branches: [main]`,
   `push.paths-ignore: [CONTRIBUTORS.md, .contributors.jsonl]`, and
   `workflow_dispatch:`. No `schedule:` key. If the runner-up is later adopted,
   the change is adding `schedule: - cron: '17 6 1 * *'` to the same block.
2. **The two ignored paths must match the action's configured outputs.** They are
   `output-file: CONTRIBUTORS.md` and `state-file: .contributors.jsonl` in both
   sources (py `:35-36`, ts `:82-83`) and in `.contributors.yml` per F209. If
   R47 (`contributors-recipe-mode`, resolved) or any later decision renames
   either file, this `paths-ignore` list must be updated in the same change or
   the loop guard silently stops guarding. Add that coupling as a comment in the
   workflow file.
3. **`commit-message` must not carry `[skip ci]`.** py already overrides the
   action's default for this reason and documents it at `:39-43`; the action's
   README repeats the warning at lines 69–75. This is not part of the `on:`
   block, but it is the other half of the same loop-protection decision, and the
   template will be wrong if the trigger is ported without it.
4. **No other file changes.** No `Justfile` recipe, no `Cargo.toml`, no
   `.contributors.yml` key, no branch-protection or required-check change: this
   workflow reports no required status check, so no ruleset needs updating.

Adjacent decisions on the same file that this item does **not** make, listed so
the integration step does not attribute them here: the credential source
(`pat:` / `app-id:` / `private-key:`) is R21/F061; the permission declaration
style (top-level grants versus deny-all plus job re-grant) is R08/F030; the
action pinning style (floating major tag versus full SHA) is R20/F055; the
`runs-on` indirection through `vars.RUNNER_UBUNTU` is R09.

### Validation strategy

All four checks below are **proposed, not executed**: `rs-launch-blueprint`
contains no Rust code and no `.github/workflows/update-contributors.yml` yet, so
none of them could be run in this research pass. What *was* executed in this pass
is documentation and repository retrieval only, listed in `### Sources`.

**Static checks (proposed, runnable in CI before any behavioral test):**

```bash
# 1. The on: block is exactly the recommended four keys — no schedule.
yq '.on | keys' .github/workflows/update-contributors.yml
# expected: ["push", "workflow_dispatch"]

# 2. The loop guard lists exactly the action's two generated files.
yq '.on.push["paths-ignore"]' .github/workflows/update-contributors.yml
# expected: ["CONTRIBUTORS.md", ".contributors.jsonl"]

# 3. The guarded paths match the action's configured outputs (drift check).
diff <(yq -r '.on.push["paths-ignore"][]' .github/workflows/update-contributors.yml | sort) \
     <(yq -r '.jobs[].steps[] | select(.uses|test("contributors-please-action")) | (.with["output-file"], .with["state-file"])' \
        .github/workflows/update-contributors.yml | sort)
# expected: no output (exit 0); any diff means the loop guard has drifted

# 4. The commit message carries no [skip ci] trailer (README lines 69-75).
! yq -r '.jobs[].steps[].with["commit-message"] // ""' \
    .github/workflows/update-contributors.yml | grep -q 'skip ci'

# 5. The workflow file is valid to GitHub's own schema.
actionlint .github/workflows/update-contributors.yml
```

Check 3 is the one that earns its place: it is the executable form of the
migration risk in `### Migration implications` item 2, and it fails loudly if
someone renames `CONTRIBUTORS.md` without updating the ignore list.

**Behavioral acceptance check (proposed, run once against a real repository —
this is the item-specific empirical check the tier guidance requires):**

```bash
# A1 — a merge to main from a new contributor produces exactly one run and one bot PR.
gh api "repos/$O/$R/actions/workflows/update-contributors.yml/runs?per_page=10" \
  --jq '[.workflow_runs[] | {id, event, head_sha, conclusion, created_at}]'
# expected: exactly one run with .event == "push" whose head_sha is the merge commit,
# .conclusion == "success".
gh pr list --repo "$O/$R" --search 'head:contributors-please' --json number,files
# expected: exactly one open PR, touching only CONTRIBUTORS.md and .contributors.jsonl.

# A2 — merging that bot PR produces zero further runs (the loop guard works).
gh pr merge <bot-pr> --repo "$O/$R" --merge
sleep 60
gh api "repos/$O/$R/actions/workflows/update-contributors.yml/runs?per_page=5" \
  --jq '[.workflow_runs[] | select(.head_sha == "<bot merge sha>")] | length'
# expected: 0 — the merge matched every paths-ignore pattern, so no run was created.

# A3 — a maintainer can force an out-of-cycle regeneration.
gh workflow run update-contributors.yml --repo "$O/$R"
# expected: a new run with .event == "workflow_dispatch", conclusion "success".

# A4 — latency is bounded by the merge, not by a clock.
# expected: the A1 run's created_at is within seconds of the merge commit's timestamp.
```

Expected behavior in one sentence: merging a contributor's PR yields exactly one
successful push-event run and one bot PR within seconds; merging that bot PR
yields no run at all; `workflow_dispatch` always yields a run on demand. A2
returning a nonzero count is the single most important failure to catch, because
it means the loop guard is misconfigured and every bot merge will spawn another
bot PR.

### Confidence & re-verify trigger

**Confidence: high** on the mechanism facts, **medium-high** on the
recommendation.

High on mechanism, because every load-bearing claim is a direct quotation from
GitHub's normative documentation or from a file read at a pinned or `main`
revision, and the three that decide the item are unambiguous: path filters are
documented only for `push`/`pull_request`/`pull_request_target`; scheduled
workflows are auto-disabled after 60 days of public-repository inactivity and
are disabled by default in forks; `paths-ignore` skips a run only when *all*
changed paths match.

Medium-high rather than high on the recommendation, for two stated reasons.
First, the Rust practice evidence is empty: none of the twelve mainstream Rust
projects surveyed runs a contributors-list bot at all, so the recommendation
rests on GitHub's semantics and the tool author's documentation rather than on
observed Rust convention. Second, run-volume is a judgment about this template's
future merge frequency, which cannot be measured before the repository has
history; if merges to `main` turn out to be far more frequent than the prompt
assumes, the noise argument for option C strengthens.

**Re-verify when any of these changes:**

1. GitHub changes the `schedule` auto-disable rules or extends `paths`/
   `paths-ignore` to the `schedule` event — re-read the events and
   workflow-syntax references; the first fact is the load-bearing one.
2. `smorinlabs/contributors-please-action` publishes a release past v1.3.9 whose
   README changes the documented trigger example or the `mode: pull-request`
   loop-protection guidance — re-read the README and
   `GET https://api.github.com/repos/smorinlabs/contributors-please-action/releases/latest`.
3. R21 settles F061 on a credential that can expire or be revoked (App
   credentials or a PAT rather than `secrets.GITHUB_TOKEN`) — that is precisely
   the condition under which the ranked runner-up wins; revisit the monthly-cron
   backstop then.
4. R47 or any later decision renames `CONTRIBUTORS.md` or `.contributors.jsonl`
   — the `paths-ignore` list must change with it, and validation check 3 exists
   to catch that.
5. The template's own merge frequency to `main` turns out to exceed roughly one
   qualifying merge per week, at which point option A stops being the cheaper of
   the two in absolute run count and the tradeoff should be re-argued.

Absent any of these, re-verify in 12 months.

### Sources

**GitHub documentation (normative).**
- Events that trigger workflows — `schedule` auto-disable after 60 days of
  public-repository inactivity; "The `schedule` event can be delayed during
  periods of high loads … some queued jobs may be dropped"; "Scheduled workflows
  will only run on the default branch": https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
  (retrieved 2026-09-09).
- Workflow syntax — section `on.<push|pull_request|pull_request_target>.<paths|paths-ignore>`
  ("When using the push and pull_request events, you can configure a workflow to
  run based on what file paths are changed") and the `paths-ignore` all-match
  rule: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
  (retrieved 2026-09-09).
- Disable and enable workflows — "In a public repository, scheduled workflows are
  automatically disabled when no repository activity has occurred in 60 days";
  "When a public repository is forked, scheduled workflows are disabled by
  default": https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows
  (retrieved 2026-09-09).

- About billing for GitHub Actions — "GitHub Actions usage is free for
  self-hosted runners and for public repositories that use standard
  GitHub-hosted runners. For private repositories, each GitHub account receives
  a quota of free minutes … Any usage beyond the included amounts is billed to
  your account.": https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions
  (retrieved 2026-09-09).

**Inherited tool (maintainer documentation).**
- `smorinlabs/contributors-please-action` README, usage block at lines 13–19 and
  the `mode: pull-request` / `[skip ci]` warning at lines 59–75:
  https://raw.githubusercontent.com/smorinlabs/contributors-please-action/main/README.md
  (retrieved 2026-09-09).
- `GET https://api.github.com/repos/smorinlabs/contributors-please-action` —
  `stargazers_count: 0`, `archived: false`, `pushed_at: 2026-09-01T22:51:20Z`,
  `license.spdx_id: MIT` (retrieved 2026-09-09).
- `GET https://api.github.com/repos/smorinlabs/contributors-please-action/releases/latest`
  — `tag_name: v1.3.9`, `published_at: 2026-06-17T20:19:47Z` (retrieved 2026-09-09).
- `GET https://api.github.com/search/issues?q=repo:smorinlabs/contributors-please-action+is:issue+is:open`
  — `total_count: 1` (retrieved 2026-09-09).

**Pinned source repositories.**
- py-launch-blueprint @ `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
  `.github/workflows/update-contributors.yml:3-9` (`push: branches: [main]`,
  `paths-ignore: [CONTRIBUTORS.md, .contributors.jsonl]`, `workflow_dispatch:`),
  `:27` (`smorinlabs/contributors-please-action@v1.3.9`), `:35-38`
  (`output-file`, `state-file`, `config-file`, `mode: pull-request`), `:39-44`
  (the `[skip ci]` override comment). Read from
  `https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/update-contributors.yml`
  (retrieved 2026-09-09).
- ts-launch-blueprint @ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`,
  `.github/workflows/update-contributors.yml:49-52` (`schedule: - cron: '17 6 *
  * 1' # weekly, Monday 06:17 UTC`, `workflow_dispatch:`), `:33-39` (the header
  comment recording that "neither the source file nor
  contributors-please-action's own documented usage example runs on a schedule"),
  `:60` (`runs-on: ubuntu-latest`), `:74-85` (SHA-pinned action, `pat:
  ${{ secrets.GITHUB_TOKEN }}`, `bootstrap: 'true'`). The raw.githubusercontent
  fetch returned HTTP 404 (the repository is not publicly readable), so the file
  was read from the local clone at that exact pinned commit via
  `git -C /Users/stevemorin/c/ts-launch-blueprint show cb1cbcb…:.github/workflows/update-contributors.yml`
  (read 2026-09-09).

**Competing contributors-list actions (practice evidence).**
- `akhilmhdh/contributors-readme-action` — README `on: push: branches: [main]`
  (lines 34–48): https://raw.githubusercontent.com/akhilmhdh/contributors-readme-action/master/README.md;
  `GET https://api.github.com/repos/akhilmhdh/contributors-readme-action` —
  204 stars, `archived: false`, `pushed_at: 2025-07-27T09:55:29Z`, MIT;
  open issues `total_count: 9` via the search endpoint (all retrieved 2026-09-09).
- `wow-actions/contributors-list` — README `schedule: - cron: '0 1 * * 0'` **plus**
  `push: branches: [master]` (lines 17–24):
  https://raw.githubusercontent.com/wow-actions/contributors-list/master/README.md;
  59 stars, `archived: false`, `pushed_at: 2024-10-18T08:09:18Z`, MIT (retrieved 2026-09-09).
- `BobAnkh/add-contributors` — README `schedule: - cron: '20 20 * * *'` with
  `# push:` commented out (lines 22–27):
  https://raw.githubusercontent.com/BobAnkh/add-contributors/master/README.md;
  42 stars, `archived: false`, `pushed_at: 2023-02-20T06:56:45Z`, Apache-2.0
  (retrieved 2026-09-09).
- All Contributors — `GET https://api.github.com/repos/all-contributors/app`
  (634 stars, `pushed_at: 2026-05-27T06:49:39Z`, MIT) and
  `GET https://api.github.com/repos/all-contributors/all-contributors`, which
  redirects to `all-contributors/allcontributors.org` (8,098 stars,
  `pushed_at: 2026-09-03T12:11:08Z`, MIT), both retrieved 2026-09-09.

**Rust practice survey.** `GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows`
for `tokio-rs/tokio`, `clap-rs/clap`, `BurntSushi/ripgrep`, `sharkdp/bat`,
`astral-sh/ruff`, `astral-sh/uv`, `starship/starship`, `helix-editor/helix`,
`nushell/nushell`, `tauri-apps/tauri`, `meilisearch/meilisearch`,
`rust-lang/cargo` (retrieved 2026-09-09). Only `rust-lang/cargo` had a
`contrib*` workflow, and it is a contributor-*guide* mdBook deploy on
`on: push: branches: [master]`
(https://raw.githubusercontent.com/rust-lang/cargo/master/.github/workflows/contrib.yml,
retrieved 2026-09-09), not a contributors list.

**Repository context read (not modified).** `docs/port/COMMONALITY.md` rows
F026, F060, F061, F209; `docs/port/areas/ci-workflows.md` rows F026, F030,
F055, F060, F061; `docs/port/BASELINE-REVIEW.md` row F060 (classified
*retained*); `docs/port/PARAMETERS.md` (the four owner-fixed values and the
`researched` ownership table).

**Method notes.** Endpoints queried in this pass: `api.github.com/repos/<o>/<r>`
(twelve Rust projects' `.github/workflows` listings plus five action
repositories), `api.github.com/repos/smorinlabs/contributors-please-action/releases/latest`,
`api.github.com/search/issues` for open-issue counts on
`smorinlabs/contributors-please-action` and `akhilmhdh/contributors-readme-action`,
`api.github.com/search/code` for adopters of the inherited action,
`raw.githubusercontent.com` for four READMEs, `rust-lang/cargo`'s `contrib.yml`
and py's pinned workflow, and four `docs.github.com` pages. All requests sent a
`User-Agent` header; all retrieved 2026-09-09 UTC.

Could not verify: (1) **crates.io figures, RustSec advisories, and docs.rs pages
are absent from this answer by design** — this item selects a GitHub Actions
event, not a crate, so `https://crates.io/api/v1/crates/<name>` and
`https://rustsec.org/packages/<name>.html` have no subject; each affected
fitness gate is marked `inapplicable` with its reason in `### Excluded by gate`
rather than omitted. (2) **ts's workflow could not be fetched over HTTPS** —
`https://raw.githubusercontent.com/smorinlabs/ts-launch-blueprint/cb1cbcb…/.github/workflows/update-contributors.yml`
returned HTTP 404 because the repository is not publicly readable; the file was
read instead from the local clone at the identical pinned commit, so the content
is the pinned tree's, but a third party cannot reproduce that fetch from a URL.
(3) **Issue-responsiveness medians were not computed** for any surveyed action —
the rubric's "10 most recently opened issues, median days to first maintainer
response" was not run, because none of these actions is a dependency this
template takes on (the tool is fixed by F060 and out of scope), so the metric
would not inform the decision; it is recorded as not gathered rather than
estimated. (4) **Adopters of the inherited action outside the owner's
organizations could not be evidenced**: code search returned `total_count: 21`
overall and `total_count: 1` with `-org:smorinlabs`, whose single hit is the
owner's own `smorin/toggle`, which `## Out of scope` forbids citing; the file
was therefore not opened. (5) **Whether "Use this template" instantiation
behaves like a fork with respect to scheduled-workflow disabling was not
confirmed** — the GitHub page on creating a repository from a template did not
yield a statement either way in the retrieved HTML, so this answer relies only
on the two rules that *are* documented (public-repository 60-day inactivity, and
forks) and does not assert a template-instantiation rule. (6) **No behavioral
check was executed**: `rs-launch-blueprint` has no workflow file and no Rust
code yet, so every command in `### Validation strategy` is proposed, not run.
