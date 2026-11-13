# R18 — AI-assisted review workflows (bundle, Deep)

### Landscape

**The category this item decides.** Not a Rust-language or crate question at all: it decides whether the template ships *repository automation files* — GitHub Actions workflow YAML that invokes a hosted large-language-model agent on pull requests and on `@mention` comments. Nothing in the decision touches `Cargo.toml`, the dependency tree, or compiled code. That framing is load-bearing for the rest of this report, because the crate figure table in `## Required evidence` (crates.io downloads, RustSec, docs.rs) has no subject here; each such metric is marked `inapplicable` with its reason in every member's gate list, and the GitHub REST figures carry the evidentiary weight instead.

**Three-bin map of the field.** The bins are read for the *ecosystem this decision lives in* — GitHub Actions on a Rust repository — because no Rust-specific candidate exists in any bin.

| Bin | Candidates found | Why it lands in this bin |
|---|---|---|
| Built-in / first-party toolchain | GitHub Copilot code review (first-party to GitHub, the CI host, not to Rust); no Rust-project or `rust-lang` first-party candidate exists | Copilot code review is a platform feature configured through repository rulesets, documented in `github/docs` at `content/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review.md` (retrieved 2026-09-09). The Rust project publishes no CI review agent and none is in the toolchain. |
| Established industry standard | `anthropics/claude-code-action` (8,832 stars; 20,480 code-search hits in `.github/workflows` paths); `The-PR-Agent/pr-agent`, formerly `qodo-ai/pr-agent` (12,923 stars) | Both predate 2026, are broadly adopted, and are the two review agents with five-figure star counts and a released version series. Figures below and per member. |
| Up-and-comers | `google-github-actions/run-gemini-cli` (2,072 stars, first commit 2025-07-11); `openai/codex-action` (1,231 stars, first commit 2025-10-01) | Both are vendor-published, both are under two years old, both are still on a pre-1.0 or unreleased tag series. |

Excluded from the map on state, not on fitness: `coderabbitai/ai-pr-reviewer`, the widely-cited 2023-era open-source reviewer action, returns HTTP 404 from `GET https://api.github.com/repos/coderabbitai/ai-pr-reviewer` (retrieved 2026-09-09) — the repository is gone, so it cannot be evaluated or adopted.

**Authorities used, and why each is authoritative.**

| Source | Why it counts as an authority here |
|---|---|
| `anthropics/claude-code-action` repository at tag `v1.0.220` — `action.yml`, `docs/security.md`, `docs/setup.md`, `docs/faq.md`, `examples/*.yml`, and its own `.github/workflows/*.yml` | Maintainer's own documentation *and* the maintainer's own production use of the thing being decided. The `.github/workflows/` files are the strongest single class of evidence available: they show what the people who wrote the action actually run against their own pull requests. |
| GitHub Actions reference documentation, `github/docs` at `content/actions/reference/workflows-and-actions/contexts.md` | The platform vendor's normative reference for what an expression may read. Its context-availability table settles, as fact rather than folklore, which guards a workflow can express. |
| GitHub Copilot documentation, `github/docs` at `content/copilot/how-tos/use-copilot-agents/request-a-code-review/` | Vendor documentation for the first-party bin candidate. |
| 2025 State of Rust Survey results, `blog.rust-lang.org` (7,156 responses, 30-day field period Nov 17 – Dec 17 2025, published 2026-03-02) | The Rust project's own annual instrument, the closest thing to a community-wide authority on Rust practice. Relevant here for what it does *not* contain (below). |
| The pinned source repositories: `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` | The two prior ports are the direct precedent this item ports from. `ts-launch-blueprint` is a private repository and was read from the local pinned clone (see Method notes). |

A single blog post was not treated as an authority anywhere in this report; every design claim resolves to vendor documentation, a maintainer's own workflow file, an open issue in the maintainer's tracker, or a REST endpoint.

**Practice evidence: what well-regarded Rust projects actually do.** Twelve projects were surveyed by listing `GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows` and matching filenames against `claude|gemini|codex|copilot|coderabbit|ai-` (retrieved 2026-09-09). Each is well regarded on observable grounds — top-tier star counts, first-party or foundation stewardship, or status as the reference implementation of its category — not on assertion.

| Project | Workflow files | AI-review workflow found | Why the project is a relevant, well-regarded reference |
|---|---|---|---|
| `astral-sh/uv` | 43 | none | The Python packaging tool this template family's `py` sibling uses; the most-cited recent Rust CLI success. |
| `astral-sh/ruff` | 20 | none | Same maintainer, same "Rust CLI shipped to a non-Rust audience" shape as this template. |
| `BurntSushi/ripgrep` | 2 | none | The canonical Rust CLI; its CI is the shape most Rust CLI templates copy. |
| `tokio-rs/tokio` | 7 | none | The async runtime the web-service member of this template will most likely sit on. |
| `zed-industries/zed` | 47 | none | A large, current, commercially staffed Rust codebase whose own product is AI-assisted editing — the strongest possible counter-example if it had adopted one. |
| `helix-editor/helix` | 4 | none | Large community-run Rust application. |
| `nushell/nushell` | 15 | none | Large community-run Rust application with heavy contributor churn. |
| `tauri-apps/tauri` | 21 | none | Foundation-governed Rust framework (Commons Conservancy). |
| `bevyengine/bevy` | 13 | none | Foundation-governed Rust engine with very high external-contributor volume. |
| `casey/just` | 2 | none | The command runner this template's own `justfile` convention derives from. |
| `rust-lang/cargo` | 4 | none | First-party Rust tooling. |
| `denoland/deno` | 22 | none | Large Rust codebase shipping to a JavaScript audience — the closest structural analogue to a Rust template with a non-Rust user base. |

Result: **0 of 12**. Widening from projects to the whole first-party organization, `GET https://api.github.com/search/code?q=org:rust-lang+"claude-code-action"` returns `total_count: 0` (retrieved 2026-09-09). The 2025 State of Rust Survey mentions large-language-model tooling exactly once, and only as a hypothesis about where beginners now ask questions ("This hints at some people moving their questions to LLM tooling"); it contains no question about AI code review in CI. There is therefore **no Rust-ecosystem practice norm to conform to, in either direction** — this is a genuine finding, not an evidence gap, and it means the decision must be argued from the template's own goals and from cross-ecosystem practice.

Cross-ecosystem practice is where the adoption evidence lives: `GET https://api.github.com/search/code?q="anthropics/claude-code-action"+path:.github/workflows` returns `total_count: 20480` (retrieved 2026-09-09), with named adopters including `milvus-io/milvus` (`.github/workflows/claude.yml`), `workadventure/workadventure`, and `mxpv/podsync`. The same result page also surfaces `wvlet/airframe` and `EvotecIT/PSWriteHTML` carrying `claude-code-review.yml.disabled` and `taikoxyz/taiko-mono` carrying `claude-layout-review.yml.bkup` — adopters who installed the workflow and then turned it off. That disabling signal is qualitative (the search API does not give a reliable disabled-to-enabled ratio) but it is direct evidence that the auto-review lane is the one adopters most often regret, and it shapes the trigger recommendation below.

**Fit lens.** This template is a CLI plus library plus web service that is consumed by forking ("Use this template"). Two consequences drive the whole design and are treated as first-class in every member: a downstream fork receives the *files* but receives neither the GitHub App installation nor the credentials, and a template's workflow files are read as exemplars by people who will copy them into unrelated repositories. Both push toward a configuration that is correct-by-default when unconfigured, rather than one that is merely correct in the origin repository.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

The principle behind `py-launch-blueprint`'s two files is: *every pull request receives a first-pass automated review before a human reads it, and maintainers can summon an agent into an issue or review thread without leaving GitHub.* Its source is the `py` implementation itself — `py .github/workflows/claude-code-review.yml` and `py .github/workflows/claude.yml` at the pinned commit `b08bccfb` — plus ledger rows F051 and F052 (`docs/port/COMMONALITY.md:57-58`), both `py-only`, both `DIVERGENT`, both bundled to R18.

The agreement level is **policy/mechanism**, not capability/standard and not architectural pattern, and establishing that is the most consequential judgment in this report. Three independent observations force it:

1. `ts-launch-blueprint` ships neither workflow (`git ls-tree -r cb1cbcb -- .github/` lists nine workflow files, none of them AI-related), and `docs/port/COMMONALITY.md` records no TypeScript port decision to carry forward. Two of the three sibling repositories therefore currently disagree, which is only tolerable if the thing they disagree about is a policy choice.
2. Nothing in the capability is ecosystem-shaped. The action reads a diff and posts comments; the diff being Rust changes nothing about the mechanism. There is no Rust analogue to select, no Rust design to preserve, and no Rust idiom to honor.
3. The reviewing entity is a paid third-party service reached with an organization-level credential. Whether to spend that credential on this repository is an owner policy question, not an engineering-fitness question — which is precisely why it cannot be settled by "py does it".

**What must agree across py, ts and rs, and what may vary.** What must agree is the *guard contract*, because it is a security property and a correctness property, and both are ecosystem-neutral: (a) the job never runs on a pull request from a fork, because fork runs receive neither repository secrets nor `id-token: write`, so the job can only fail; (b) the job never runs when either the pull-request author or the run's initiator is a bot; (c) the credential is never interpolated into a place an untrusted contributor's text can reach. What may vary per repository is everything else — whether the capability is enabled at all, which events are listened to, which model, and which prompt.

**Verifying the shared pattern still fits the target ecosystem.** It fits, with one adjustment that comes from the *template* shape rather than from Rust. The Rust-specific question in `## Questions` ("does py's guard logic port unchanged?") resolves to: **yes, unchanged — there is no Rust-specific adjustment to make.** The guard reads `github.event.pull_request.head.repo.full_name`, `github.event.pull_request.user.type` and `github.event.sender.type`, all of which are language-independent GitHub webhook fields, and the bot actors it exists to exclude are the same two in a Rust repository as in a Python one (`release-please-*[bot]` and `dependabot[bot]`; `py` at `b08bccfb` carries both `.github/workflows/release-please.yml` and `.github/dependabot.yml`, and `rs-launch-blueprint` is planned to carry the analogues under R19 and the release items).

The guard's motivating incident is verifiable rather than anecdotal: `GET https://api.github.com/repos/smorinlabs/py-launch-blueprint/pulls/470` returns title `chore(release): publish v2.4.1 — review and merge to ship to PyPI`, author `release-please-smorinlabs[bot]` of `"type": "Bot"`, merged `2026-07-19T04:29:41Z` (retrieved 2026-09-09) — the release pull request whose false red check the `py` comment describes.

**Architectural alternatives, compared before libraries.** Four distinct architectures can deliver "pull requests get an automated first-pass review", and the choice among them is prior to the choice of vendor.

| Architecture | How it is expressed | Travels through "Use this template"? | Credential model | Verdict for this template |
|---|---|---|---|---|
| A. Workflow-file agent (py's shape; `claude-code-action`, `run-gemini-cli`, `codex-action`) | YAML in `.github/workflows/`, versioned and reviewed like code | Yes — the file is part of the tree | Repository secret, or OIDC workload-identity federation with only non-secret identifiers in `vars` | **Chosen.** Only architecture that is itself a template artifact. |
| B. Platform-configured reviewer (GitHub Copilot code review) | Repository ruleset plus organization settings; no file in the repository | No — rulesets and settings are repository state, not tree content | Copilot licence attached to the account | Rejected on fit: a template that ships nothing cannot teach or transfer the capability, and the value test in `## Objective` is about files. |
| C. Hosted third-party review app (Qodo/PR-Agent as a service, CodeRabbit as an app) | GitHub App installed on the repository | No | Vendor account | Rejected on the same fit ground as B, plus a second vendor relationship. |
| D. Self-hosted agent in a generic job (call a model API from a hand-written script) | Bespoke YAML plus a script in the repository | Yes | Repository secret | Rejected on maintenance cost: reimplements diff assembly, comment threading, deduplication and prompt-injection sanitization that A gets from a maintained action. |

Architecture A is the only one that satisfies the template's own delivery mechanism, so the vendor comparison proceeds inside A. That comparison is per member below; its short form is that `claude-code-action` is the only candidate in bin two or three that (i) covers *both* use cases with one action and one credential, (ii) is on a stable major version series, and (iii) has the maintainer running it against its own repository in a form we can read.

**The three implementation facts that decide the configuration.** Each is a verified platform or maintainer fact, not a preference.

1. **A workflow cannot ask whether its credential exists.** `github/docs` `content/actions/reference/workflows-and-actions/contexts.md` (retrieved 2026-09-09) gives `jobs.<job_id>.if` the contexts `github, needs, vars, inputs` and `jobs.<job_id>.steps.if` the contexts `github, needs, strategy, matrix, job, runner, env, vars, steps, inputs`. **`secrets` appears in neither.** It does appear in `jobs.<job_id>.env` and `jobs.<job_id>.steps.with`. Consequence for a public template: `if: secrets.X != ''` is not expressible, but `if: vars.X == 'true'` is, and `vars` on an unconfigured fork evaluates to the empty string. A repository-variable enable flag is therefore the one guard that makes both workflows inert-by-default in every downstream fork while remaining a single-line switch in the origin repository. This is the design point `py` does not address, and it is the only substantive departure this report recommends from the `py` shape.
2. **The action already refuses bots; the workflow guard converts that refusal into a skip.** `action.yml` at `v1.0.220` declares `allowed_bots` with `default: ""` and the description "Empty string (default) allows no bots", and `docs/security.md` states "By default, GitHub Apps and bots cannot trigger this action for security reasons." So the `py` condition `github.event.sender.type != 'Bot'` is not the primary bot gate — it is the mechanism that turns an in-action abort (a red check, as on `py` PR #470) into a *skipped job*, which GitHub renders as neutral. Both layers are wanted, and the `py` logic ports byte-for-byte.
3. **Static credentials are now optional.** `docs/setup.md#workload-identity-federation` (retrieved 2026-09-09) documents exchanging the workflow's GitHub OIDC token for a short-lived Anthropic access token via `anthropic_federation_rule_id`, `anthropic_organization_id` and `anthropic_service_account_id` — values the documentation explicitly calls "identifiers, not credentials, so they can live directly in the workflow file (or in repository variables)". Anthropic's own `.github/workflows/claude-review.yml` and `.github/workflows/claude.yml` at `v1.0.220` both use exactly this, reading the three identifiers from `vars.*`, with no `secrets.` reference anywhere in either file. Federation requires `id-token: write`, which the default GitHub App path already requires, so it costs no additional permission.

**Production usage and maintained reference implementations.** The reference implementations for both members are in the action repository itself and were read at `v1.0.220`: `.github/workflows/claude-review.yml` and `.github/workflows/claude.yml` (the maintainer's own production configuration), plus `examples/pr-review-comprehensive.yml`, `examples/pr-review-filtered-authors.yml`, `examples/claude.yml` and `examples/claude-wif.yml`. Maturity, dependability and integration cost are quantified per member. Representative performance: **no per-run latency, token or cost figure is published by the maintainer, and none could be measured from a public endpoint** — `anthropics/claude-code-action` issue #1482, "Feature request: expose per-run cost and token usage as Action outputs", is open, which is itself the evidence that the figure is not currently obtainable. Cost is therefore reasoned about structurally (one full agent session per triggering event) and stated as an evidence gap, not estimated.

**Minimal realistic example and acceptance check.** The minimal example is the pair of files in `### Migration implications` plus one repository variable. The executable acceptance check is in `### Validation strategy`; every command there is **proposed**, because `rs-launch-blueprint` has no `.github/workflows/` tree and no Rust code yet — nothing in this report was executed against a live workflow run.

**Baseline findings.**

BASELINE-REVIEW: F051 — a least-privilege grant must never silently disable the workflow's only output — raise the review job's `pull-requests: read` to `pull-requests: write` — evidence: `py .github/workflows/claude-code-review.yml` at pinned commit `b08bccfb` grants `pull-requests: read` while instructing the `code-review` plugin to post with `--comment`, whereas both maintainer references grant `pull-requests: write` (`anthropics/claude-code-action` `.github/workflows/claude-review.yml` and `examples/pr-review-comprehensive.yml`, both at `v1.0.220`, retrieved 2026-09-09), and open issue `anthropics/claude-code-action#1121` ("claude-code-review workflow template generates insufficient permissions; action silently swallows write failure", opened 2026-03-24, independently reproduced in-thread 2026-05-09) reports that the `read` variant produces a green job that posts nothing. Affected items: R18 (this item), and R08, which owns the repository-wide permission-hardening convention this row must not be read as overriding. `ts-launch-blueprint` has no counterpart file at `cb1cbcb`, so no TypeScript evidence bears on the row.

BASELINE-REVIEW: F051 and F052 — minimize long-lived credentials in a public template — prefer workload identity federation over a static `CLAUDE_CODE_OAUTH_TOKEN` repository secret — evidence: `py .github/workflows/claude-code-review.yml` and `py .github/workflows/claude.yml` at `b08bccfb` both pass `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}`, a static token; `anthropics/claude-code-action` `docs/setup.md#workload-identity-federation` and both of the maintainer's own workflows at `v1.0.220` instead pass three non-secret identifiers from `vars.*` and mint a short-lived token from the run's OIDC identity, with no secret to create, store or rotate. Affected items: R18, and R21, which owns bot-credential sourcing for the contributors bot and should not be read as constrained by this row. `ts-launch-blueprint` has no counterpart file at `cb1cbcb`. Recorded as a challenge to the recorded baseline, not as a change to another item or to the ledger.

### Recommendation

**Ship both workflows, as one bundle, from `anthropics/claude-code-action` at `v1.0.220`, gated off by default behind a repository variable.**

One stack, seven decisions:

1. **Adopt both members together** (F051 and F052), for the reasons argued in `### Compatibility`: they share one action, one credential, one GitHub App installation, one version pin and one enable flag, and — decisively — the recommended narrowing of the auto-review trigger is only safe *because* the `@mention` workflow exists to re-request a review on demand.
2. **Action and version:** `anthropics/claude-code-action`, current stable `v1.0.220` (published 2026-09-09T20:12:09Z). The *form* of the pin (exact tag versus commit SHA versus floating `v1`) is R20's to decide; this item supplies the figures R20 needs, including a release cadence of roughly one patch per day.
3. **Auto-review triggers:** `pull_request: types: [opened, ready_for_review, reopened]` — that is `py`'s list **minus `synchronize`**. Every retained event fires at most once per pull request per state change; `synchronize` fires on every push and is the only unbounded one.
4. **Assistant triggers:** `py`'s four events unchanged — `issue_comment: [created]`, `pull_request_review_comment: [created]`, `issues: [opened, assigned]`, `pull_request_review: [submitted]` — each guarded by a `contains(..., '@claude')` test on the corresponding body field. This matches `examples/claude.yml` and the maintainer's own `claude.yml` exactly.
5. **Guards:** `py`'s fork guard and both bot guards, unchanged, on the review job; the `@claude` content tests on the assistant job; **plus** a `vars`-based enable flag on both, which is the one addition to `py`'s shape.
6. **Credential:** workload identity federation (`anthropic_federation_rule_id`, `anthropic_organization_id`, `anthropic_service_account_id` read from `vars.*`) as the recommended path, with the static `CLAUDE_CODE_OAUTH_TOKEN` secret documented as the fallback for anyone who has not configured federation.
7. **Permissions:** review job `contents: read`, `pull-requests: write`, `issues: read`, `id-token: write`; assistant job `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write`, `actions: read` with `additional_permissions: actions: read`. The repository-wide hardening convention these sit inside is R08's.

If the owner declines the spend, the correct alternative is **neither** workflow, not one — see `### Compatibility` for why splitting the bundle is the worst of the three outcomes.

### Members

Two members, one per ledger row: F051 (`docs/port/COMMONALITY.md:57`) and F052 (`docs/port/COMMONALITY.md:58`). The action itself is not a third member — it is the single component both members instantiate, so its figures appear in both and its evaluation is not duplicated as a separate crate field set.

Every member states the crate figure table in full. Because both members are GitHub Actions workflows rather than Rust crates, the crates.io, RustSec and docs.rs rows are `inapplicable` with the reason stated, and the GitHub REST figures carry the evidence. All figures were retrieved 2026-09-09.

#### F051 — automatic AI-assisted PR code-review workflow (.github/workflows/claude-code-review.yml)

##### Landscape

The category for this member is "an agent that reviews every pull request without being asked". Bin one (first-party to the CI host): **GitHub Copilot code review**, which can be set to review all pull requests automatically, and to re-review on new pushes, through a repository ruleset — `github/docs` `content/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review.md` §"Enabling automatic reviews" and §"Reviewing new pushes" (retrieved 2026-09-09). Bin two (established): **`anthropics/claude-code-action`** and **`The-PR-Agent/pr-agent`**. Bin three (up-and-comers): **`google-github-actions/run-gemini-cli`** and **`openai/codex-action`**. `coderabbitai/ai-pr-reviewer` was in bin two historically and is now absent (HTTP 404 on its repository endpoint, retrieved 2026-09-09).

Practice evidence for this member is the twelve-project Rust survey in the top-level `### Landscape`: none of the twelve runs any automatic AI review workflow, and `org:rust-lang` code search returns zero uses of the action. The adoption evidence is cross-ecosystem — 20,480 code-search hits for the action in `.github/workflows` paths — together with the maintainer's own use of it on its own repository, which is the single most probative artifact for this member and is quoted under `Fit for this template`.

##### Principles and implementation

The principle is: *a human reviewer's first read should not be spent on defects a machine can find, and the reviewing configuration should be a reviewable file rather than hidden account state.* Agreement level: policy/mechanism (argued in the top-level field).

Essential behaviors, each observable: (1) on a qualifying pull-request event the job starts; (2) on a fork pull request, a bot-authored pull request, or a bot-initiated run, the job is **skipped**, not failed; (3) when it runs, review comments appear on the pull request; (4) no credential is readable by a workflow run whose content an untrusted contributor controls.

Behavior (3) is where `py`'s configuration is challenged. `py .github/workflows/claude-code-review.yml` at `b08bccfb` grants `pull-requests: read` and passes `prompt: '/code-review:code-review <repo>/pull/<n> --comment'` using the `code-review@claude-code-plugins` plugin from the `https://github.com/anthropics/claude-code.git` marketplace. That plugin exists — `GET https://api.github.com/repos/anthropics/claude-code/contents/plugins/code-review` returns `.claude-plugin`, `README.md`, `commands` (retrieved 2026-09-09) — so the plugin reference is sound. The permission is the problem: both maintainer references grant `pull-requests: write`, and open issue #1121 reports the `read` variant producing a green job that posts nothing, with a second reporter confirming on 2026-05-08/09. The `BASELINE-REVIEW:` line in the top-level `### Principles and implementation` records this.

The maintainer's own configuration, read verbatim at `v1.0.220`, is the reference implementation and differs from `py` in three visible ways — trigger list, permissions, and credential:

```yaml
# anthropics/claude-code-action .github/workflows/claude-review.yml @ v1.0.220
name: PR Review
on:
  pull_request:
    types: [opened]
jobs:
  review:
    # Skip on fork PRs since they can't mint the OIDC token used for Claude API auth
    if: github.event.pull_request.head.repo.full_name == github.repository
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      id-token: write
```

Acceptance criteria for this member: a fork pull request produces a *skipped* job; a `release-please` pull request produces a *skipped* job; a human pull request in the configured origin repository produces at least one posted review comment; a repository created from the template with no variable set produces a *skipped* job on every pull request.

##### Dominant choice

`anthropics/claude-code-action`, pinned at `v1.0.220`, invoked from a `pull_request`-triggered job. It is dominant on three measurable grounds and one structural one.

| Figure | Value | Endpoint / rule |
|---|---|---|
| 90-day downloads | `inapplicable` — not a crate; crates.io has no record of a GitHub Action | `GET https://crates.io/api/v1/crates/<name>` not queried; no such crate exists |
| All-time downloads | `inapplicable` — same reason | same |
| Last release | `v1.0.220`, published `2026-09-09T20:12:09Z`; not a prerelease | `GET https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=30`, newest non-prerelease entry |
| Stars, archived | `stargazers_count: 8832`; `archived: false`; `pushed_at: 2026-09-09T20:12:20Z`; `license.spdx_id: MIT`; `created_at: 2025-05-19T15:26:50Z` | `GET https://api.github.com/repos/anthropics/claude-code-action` |
| Open issues | `457` | `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open`, `total_count` |
| Issue responsiveness | 10 most recently opened issues (`#1818, #1817, #1798, #1796, #1795, #1788, #1781, #1779, #1777, #1776`, created 2026-09-02 through 2026-09-09): **0 received a first comment from an OWNER, MEMBER or COLLABORATOR; unanswered = 10; median days to first maintainer response = not computable from a sample with no responses.** One issue (#1817) accumulated 12 community comments with no maintainer reply. | `GET .../issues?state=all&sort=created&direction=desc`, filtered to non-pull-request items, then each `comments_url`, matching `author_association` |
| Advisories | `inapplicable` — RustSec indexes crates.io packages; a GitHub Action has no RustSec page | `https://rustsec.org/packages/<name>.html` has no applicable subject |
| Adopters | 20,480 files reference the action under `.github/workflows`; named: `milvus-io/milvus`, `workadventure/workadventure`, `mxpv/podsync`. Most probative adopter: **the maintainer**, running it on its own pull requests (`.github/workflows/claude-review.yml` at `v1.0.220`). | `GET https://api.github.com/search/code?q="anthropics/claude-code-action"+path:.github/workflows`; file reads at the pinned tag |

Release cadence: of the 30 most recent release entries, 29 fall within 90 days of retrieval; the oldest of the 30 is `v1.0.192` (2026-08-13T23:31:59Z), giving 28 patch releases in the 27 days to `v1.0.220` — approximately one per day. The tag list contains 287 tags including the two floating majors `v0` and `v1`; **no `v2` tag exists**, so `v1` is the current major and there is no successor action to migrate to. `py`'s pin `v1.0.175` is present in the tag list and is 45 patch releases behind current.

Maintenance state by rubric: **active**. The release-cadence and `pushed_at` evidence is unambiguous (a release on the retrieval date itself), so the six-month trigger is not reached and no `at-risk` verdict is warranted. The concrete negative signal is confined to *issue triage*, not to the code: 457 open issues and zero maintainer responses across the ten most recent. That combination — daily shipping, unattended tracker — is the relevant risk to record for a consumer, because it predicts that a defect this template hits will be fixed only if it is also a defect the maintainer hits.

##### Qualified shortlist

| Candidate | Stars | License | Last tagged version | Open issues | Covers this member | Covers the F052 member with the same action |
|---|---|---|---|---|---|---|
| `anthropics/claude-code-action` | 8,832 | MIT | `v1.0.220` (2026-09-09) | 457 | Yes | **Yes** |
| `The-PR-Agent/pr-agent` (301-redirect target of `qodo-ai/pr-agent`) | 12,923 | MIT | `v0.45.0`; `pushed_at: 2026-09-09T23:20:26Z` | 58 | Yes | Partly — command-driven, but a different product surface |
| `google-github-actions/run-gemini-cli` | 2,072 | Apache-2.0 | `v0.1.22` (2026-04-24); `pushed_at: 2026-08-21T16:03:24Z` | 62 | Yes | Yes |
| `openai/codex-action` | 1,231 | Apache-2.0 | tag `v1.12`; **no GitHub releases published**; `pushed_at: 2026-08-26T00:12:45Z` | 36 | Yes | Yes |
| GitHub Copilot code review | `inapplicable` — a platform feature, not a repository | Proprietary (GitHub) | `inapplicable` — continuously deployed | `inapplicable` | Yes, via ruleset | No |

All figures from `GET https://api.github.com/repos/<o>/<r>`, `/tags?per_page=5`, `/releases?per_page=1`, and `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, retrieved 2026-09-09. Note that `qodo-ai/pr-agent` now returns HTTP 301 to repository id `662766482`, whose current `full_name` is `The-PR-Agent/pr-agent` — a rename that any prompt citing the old path should record.

`The-PR-Agent/pr-agent` is the strongest single-purpose alternative: more stars, an order of magnitude fewer open issues, a tracker that looks attended, MIT licence, and pushed on the retrieval date. It loses on two grounds specific to this decision — it does not cover the F052 use case with the same component and credential, and its release series is still `v0.x`, which is a weaker compatibility promise than `v1`.

`run-gemini-cli` shows a nearly four-month gap between its newest tag (`v0.1.22`, 2026-04-24) and its newest push (2026-08-21). Under the rubric that is a **trigger to investigate, not a verdict**: the repository is being worked on and is not archived, so the finding recorded here is "release cadence has stalled while development continues", state `stable-quiet`, and a consumer would be pinning a four-month-old tag. `openai/codex-action` publishes no GitHub releases at all, only tags — a consumer can pin `v1.12` but gets no release notes, which raises the cost of the version-bump review R19 and R20 will own.

##### Excluded by gate

**No candidate fails gates 1 through 6.** The gates are applied here in full, with each inapplicable metric named and reasoned rather than skipped, for the dominant choice:

1. **License compatible with `MIT OR Apache-2.0`** — **pass**. `license.spdx_id: MIT` from `GET https://api.github.com/repos/anthropics/claude-code-action` (retrieved 2026-09-09). MIT imposes only attribution and is compatible with a dual-licensed consumer. Note also that a workflow *invokes* an action rather than linking it, so no license term propagates into the template's own distributed artifacts.
2. **MSRV within `stable minus 2 minor versions, ...`** — **inapplicable**. The action is a composite GitHub Action whose implementation is TypeScript run under Bun (`action.yml` `runs.using: composite`, steps `oven-sh/setup-bun` at bun-version `1.3.14` then `bun run src/entrypoints/run.ts`). It declares no `rust-version`, never enters `Cargo.toml`, and never enters the dependency tree, so there is no MSRV to satisfy and the policy is not engaged.
3. **No open RustSec advisory; `unsafe` posture** — **inapplicable** in both halves: RustSec advisories are indexed per crates.io package and this is not a crate, and there is no Rust code and therefore no `unsafe`. The equivalent supply-chain posture, stated rather than omitted: the action ships as a repository reference resolved at run time, so its trust boundary is whatever the `uses:` line pins; it installs Bun from `oven-sh/setup-bun` pinned inside the action to commit `0c5077e51419868618aeaa5fe8019c62421857d6`; it runs the model in a session whose repository token is either the short-lived Claude App installation token or the job's own `GITHUB_TOKEN`; `docs/security.md` documents prompt-injection sanitization (HTML comments, invisible characters, image alt text, hidden attributes, HTML entities are stripped) and states plainly that "new bypass techniques may emerge".
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — **inapplicable as a matrix gate, with the fact stated**: this workflow is a single non-matrix job, and both maintainer references and both `py` files run it on one Linux runner (`py` uses `runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`, an indirection that belongs to R09). The action is not part of the `ubuntu-latest, macos-latest` build matrix that gates crates, and adding a macOS runner to it would double the cost for no signal. Windows, per the gate's "noted, not required": partial — `action.yml` guards three steps with `runner.os != 'Windows'`.
5. **Default features and async-runtime coupling** — **inapplicable** (no Cargo features, no Rust async runtime). The defaults that do matter, read from `action.yml` at `v1.0.220` and stated in their place: `allowed_bots: ""` (no bot may trigger the action), `allowed_non_write_users: ""` (write access required), `trigger_phrase: "@claude"`, `label_trigger: "claude"`, `classify_inline_comments: "true"`, `include_fix_links: "true"`, `display_report: "false"`, `show_full_output: "false"`, `use_commit_signing: "false"`, `bot_name: "claude[bot]"`. The mode is implicit: `docs/faq.md` §"How does automatic mode detection work?" states that supplying `prompt` selects automation mode and omitting it selects interactive `@claude` mode — which is exactly the distinction between this member and F052.
6. **Binary size and compile time** — **inapplicable**; the analogue, stated qualitatively: the job adds no compile time to the Rust build because it never invokes `cargo`; its fixed overhead is a checkout plus a Bun install that `action.yml` comments describe as a 35 MB download taking 2-3 seconds, and its variable cost is one full agent session per triggering event. **Per-run wall-clock, token and monetary cost are an evidence gap**: no figure is published, and issue #1482 ("Feature request: expose per-run cost and token usage as Action outputs", open) is the evidence that the figure is not currently obtainable from the action itself.

Candidates set aside for reasons that are *not* gate failures, recorded here so the exclusion is not silent: **GitHub Copilot code review** — excluded on fit, because it is configured through repository rulesets and organization settings, which are repository state rather than tree content, so it cannot travel through "Use this template" and cannot satisfy the value test in `## Objective` (which is about the presence and configuration of two files). **`coderabbitai/ai-pr-reviewer`** — excluded on state: repository endpoint returns HTTP 404 (retrieved 2026-09-09).

##### Up-and-comers

`google-github-actions/run-gemini-cli` (2,072 stars, Apache-2.0, created 2025-07-11) and `openai/codex-action` (1,231 stars, Apache-2.0, created 2025-10-01) are the two vendor-published newcomers. Both are credible and both are on the same architecture (A). Neither is recommended yet, for reasons that are figures rather than impressions: `run-gemini-cli`'s newest tag is `v0.1.22` from 2026-04-24 against a `pushed_at` of 2026-08-21, so a consumer pins a stale tag against a moving codebase; `codex-action` publishes zero GitHub releases, so version bumps arrive with no notes. Both would become serious candidates on a `v1` release series with published notes — that is a concrete re-verify condition, recorded in `Confidence & re-verify trigger`.

##### Fit for this template

The template is CLI plus library plus web service, distributed by forking. Three fit facts decide the configuration, and only the third is about Rust.

**Fit fact 1 — the downstream fork is the primary failure mode, and one platform rule bounds the fix.** A repository created from this template receives both YAML files, and receives neither the Claude GitHub App installation nor any credential. Under `py`'s shape the review job would then run on the fork owner's first pull request and fail. The workflow cannot test for the missing credential: `github/docs` `content/actions/reference/workflows-and-actions/contexts.md` (retrieved 2026-09-09) lists the contexts available to `jobs.<job_id>.if` as `github, needs, vars, inputs` and to `jobs.<job_id>.steps.if` as `github, needs, strategy, matrix, job, runner, env, vars, steps, inputs` — `secrets` is in neither. It *is* available to `jobs.<job_id>.env` and `jobs.<job_id>.steps.with`. Two mechanisms therefore exist, and the simpler one is preferred: gate the job on `vars.ENABLE_CLAUDE_REVIEW == 'true'`, which is unset and thus false in every fresh fork, and is one repository-variable write in the origin repository. (The alternative — a job-level `env: HAS_CRED: ${{ secrets.X != '' }}` read by a step-level `if: env.HAS_CRED == 'true'` — works, is legal under the same table, and is worth documenting, but it puts a skipped *step* inside a green *job*, which reads as a passing review that never happened.)

**Fit fact 2 — `synchronize` is the one unbounded trigger, and the maintainer does not use it.** `py` listens on `[opened, synchronize, ready_for_review, reopened]`; every event but `synchronize` fires at most once per state change, while `synchronize` fires on every push to the branch. The maintainer's own repository — a repository with far more pull-request traffic than this template will ever see, and no cost constraint — listens on `types: [opened]` alone. The recommended list is `[opened, ready_for_review, reopened]`: it keeps the one-shot events that represent genuine review moments and drops the per-push one. The cost of dropping it is that a contributor who pushes fixes gets no automatic re-review — which is precisely the gap the F052 member fills with a one-line `@claude please re-review`, and is the sharpest argument for keeping the two members bundled. Supporting signal, qualitative and labelled as such: the same code search that finds 20,480 adopters also surfaces `wvlet/airframe` and `EvotecIT/PSWriteHTML` carrying `claude-code-review.yml.disabled` and `taikoxyz/taiko-mono` carrying `claude-layout-review.yml.bkup`; a disabled-to-enabled ratio cannot be computed from the search API, so this is treated as a direction, not a rate.

**Fit fact 3 — nothing about the Rust shape changes the guard.** The guard reads three language-independent webhook fields. The bot actors it excludes are `release-please-*[bot]` and `dependabot[bot]`, which are the same actors in a Rust repository (`py` at `b08bccfb` carries `.github/workflows/release-please.yml` and `.github/dependabot.yml`; the Rust template plans the analogues). The HIGH question "does `py`'s guard logic port unchanged?" answers **yes**.

##### Recommendation

Ship `.github/workflows/claude-code-review.yml` using `anthropics/claude-code-action` at `v1.0.220`, on `pull_request: types: [opened, ready_for_review, reopened]`, with `py`'s fork and dual-bot guard **plus** a repository-variable enable flag, `pull-requests: write` rather than `read`, and workload identity federation as the credential path.

```yaml
name: Claude Code Review
on:
  pull_request:
    types: [opened, ready_for_review, reopened]
jobs:
  claude-review:
    # vars is one of the four contexts available to jobs.<job_id>.if; secrets is not.
    # Unset in a fresh fork of the template, so the job skips rather than fails.
    if: >-
      vars.ENABLE_CLAUDE_REVIEW == 'true'
      && github.event.pull_request.head.repo.full_name == github.repository
      && github.event.pull_request.user.type != 'Bot'
      && github.event.sender.type != 'Bot'
    runs-on: ubuntu-latest          # runner indirection is R09's to decide
    permissions:                    # repo-wide hardening convention is R08's to decide
      contents: read
      pull-requests: write          # was `read` in py; see BASELINE-REVIEW on F051
      issues: read
      id-token: write
    steps:
      - uses: actions/checkout@v7   # action pin form is R20's to decide
        with:
          fetch-depth: 1
      - uses: anthropics/claude-code-action@v1.0.220
        with:
          anthropic_federation_rule_id: ${{ vars.ANTHROPIC_FEDERATION_RULE_ID }}
          anthropic_organization_id: ${{ vars.ANTHROPIC_ORGANIZATION_ID }}
          anthropic_service_account_id: ${{ vars.ANTHROPIC_SERVICE_ACCOUNT_ID }}
          plugin_marketplaces: 'https://github.com/anthropics/claude-code.git'
          plugins: 'code-review@claude-code-plugins'
          prompt: '/code-review:code-review ${{ github.repository }}/pull/${{ github.event.pull_request.number }} --comment'
```

##### Ranked runner-up

1. **`The-PR-Agent/pr-agent`** (12,923 stars, MIT, `v0.45.0`, 58 open issues, pushed 2026-09-09). Take it if the deciding criterion becomes tracker health rather than single-vendor coverage: it has one eighth the open-issue count of the dominant choice and a visibly attended tracker. It costs a second vendor relationship, because it does not serve the F052 member with the same component and credential, and its `v0.x` series is a weaker compatibility promise.
2. **`google-github-actions/run-gemini-cli`** (2,072 stars, Apache-2.0). Take it if the owner's model credential is Google's. Same architecture, covers both members, but pins a tag four months older than its newest push.
3. **`openai/codex-action`** (1,231 stars, Apache-2.0). Same shape, smallest tracker, no published releases.
4. **GitHub Copilot code review**. Take it only if the decision is reframed from "what does the template ship" to "what does the origin repository have configured"; it cannot satisfy the file-level value test in `## Objective`.

##### Tradeoffs

| Axis | What the recommendation buys | What it costs |
|---|---|---|
| Trigger scope (`[opened, ready_for_review, reopened]` vs adding `synchronize`) | Bounded, predictable spend: at most a small fixed number of sessions per pull request | No automatic re-review after a fix-up push; the contributor must type `@claude` — which only works because F052 ships |
| Enable flag defaulting to off | Every downstream fork is inert and green out of the box; no fork owner sees a red check they cannot fix | One extra setup step in the origin repository, and a documentation obligation: an owner who forgets the variable silently gets no reviews |
| Workload identity federation over a static token | No long-lived secret in a public repository; nothing to rotate | One-time Anthropic Console setup (issuer, service account, federation rule) that a fork owner must repeat; `docs/setup.md` also notes that inline-comment classification currently requires `anthropic_api_key` and is skipped under federation |
| `pull-requests: write` | The review is actually posted | A broader grant than the repo-wide hardening default R08 will set; must be justified per job rather than inherited |
| Single-vendor coverage of both members | One action, one credential, one App install, one pin | Concentration risk: an unattended tracker (457 open, 0 of 10 recent issues answered) means a defect this template hits may sit |
| Adopting the bundle at all | Faster first-pass review; a worked example downstream users can copy | Recurring third-party spend with no per-run cost telemetry (issue #1482 open); a review whose quality is not gated by any test in this repository |

##### Parameters

This member owns no parameter — the research index row for R18 lists `owns` as `—` (`research/CLAUDE.md`). It assumes the four owner-fixed values from `docs/port/PARAMETERS.md`: `assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `assumes license = MIT OR Apache-2.0`; `assumes target-os-matrix = ubuntu-latest, macos-latest`. The first three are not engaged by a workflow file that never invokes `cargo`; the fourth is engaged only in the negative sense recorded under gate 4 — this job is a single Linux job and does not join the OS matrix. The `## Couplings` block for R18 lists an empty `consumes:`, so no consumed parameter can conflict, and **no `CONFLICT:` line is emitted**.

##### Migration implications

New file `.github/workflows/claude-code-review.yml` (46 lines as drafted above). No existing file changes, because `rs-launch-blueprint` has no `.github/workflows/` tree yet. Three coordination obligations, none of which this item may decide: the `uses:` pin form belongs to R20 (third-party action pinning policy); the `permissions:` block sits inside R08's repository-wide deny-all-plus-grant convention; the `runs-on:` value interacts with R09's self-hosted-runner indirection (`py` writes `${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`). Two documentation obligations follow from the enable flag: `README.md` or `CONTRIBUTING.md` must state that the capability is off until `ENABLE_CLAUDE_REVIEW` is set, and must record the one-time Anthropic Console federation setup a fork owner repeats. R19 (Dependabot config shape) inherits a new update surface: `github-actions` ecosystem updates against an action releasing roughly daily.

##### Validation strategy

All checks below are **proposed**; none was executed, because the repository has no workflows directory and no Rust code at the time of writing.

```bash
# 1. Static validity of the workflow file, before any run exists.
actionlint .github/workflows/claude-code-review.yml
# expect: exit 0, no output

# 2. The recommended pin exists and is the current stable major.
curl -sS -A 'rs-launch-blueprint/R18' \
  https://api.github.com/repos/anthropics/claude-code-action/releases/tags/v1.0.220 \
  | jq -r '.tag_name, .prerelease'
# expect: v1.0.220 / false

# 3. Fork-PR guard: a PR from a fork must produce a *skipped* job, not a failure.
gh api repos/<owner>/rs-launch-blueprint/actions/workflows/claude-code-review.yml/runs \
  --jq '.workflow_runs[0] | {event, conclusion}'
# expect on a fork PR: conclusion "skipped" (never "failure")

# 4. Bot guard: the release-please PR must produce a skipped job.
#    Re-run after the first release PR opens and assert the same shape as (3).

# 5. Template-consumer guard: in a repo created from the template with no
#    ENABLE_CLAUDE_REVIEW variable set, open a PR and assert the job skipped.

# 6. Permission proof (the BASELINE-REVIEW claim): with pull-requests: write,
#    a human PR in the origin repo must yield at least one posted comment.
gh api repos/<owner>/rs-launch-blueprint/issues/<pr>/comments --jq 'length'
# expect: >= 1 ; a result of 0 alongside a green job reproduces issue #1121
```

Check 6 is the one that distinguishes this recommendation from `py`'s configuration, and it is the check `py` currently has no evidence of passing.

##### Confidence & re-verify trigger

**Confidence: high** on the mechanism facts, **medium** on the recommendation. High on mechanism because every load-bearing claim resolves to a file read at a pinned tag or to a vendor reference table: the context-availability table, the `allowed_bots` default, the federation inputs, the maintainer's own trigger list, the plugin's existence, and `py` PR #470's bot authorship were each verified directly. Medium on the recommendation because two inputs are genuinely absent: no per-run cost figure is obtainable (issue #1482), and there is no Rust-ecosystem precedent in either direction to corroborate the choice — 0 of 12 surveyed Rust projects and 0 uses across `org:rust-lang`.

Re-verify when any of these occurs: a `v2` tag appears on `anthropics/claude-code-action` (none exists as of 2026-09-09; the tag list holds 287 tags with floating majors `v0` and `v1` only); issue #1121 closes with a change to the recommended permissions; issue #1482 closes, making per-run cost measurable and the `synchronize` question quantitative rather than structural; `run-gemini-cli` or `openai/codex-action` publishes a `v1` release series with notes; the maintainer's own `.github/workflows/claude-review.yml` adds `synchronize`; or the issue tracker's zero-response streak reverses or hardens (re-run the ten-issue responsiveness probe). Unconditionally re-verify the version pin at implementation time: at roughly one patch release per day, `v1.0.220` will be stale within days.

##### Sources

- `anthropics/claude-code-action` `action.yml` at tag `v1.0.220` — `https://raw.githubusercontent.com/anthropics/claude-code-action/v1.0.220/action.yml` (retrieved 2026-09-09): `allowed_bots` default `""`, federation inputs, plugin inputs, composite/Bun implementation, Windows-guarded steps.
- `anthropics/claude-code-action` `.github/workflows/claude-review.yml` at `v1.0.220` (retrieved 2026-09-09): maintainer's own review lane — `types: [opened]`, `pull-requests: write`, federation via `vars.*`.
- `anthropics/claude-code-action` `examples/pr-review-comprehensive.yml`, `examples/pr-review-filtered-authors.yml` at `v1.0.220` (retrieved 2026-09-09): both grant `pull-requests: write` / `read` respectively for posting vs non-posting flows.
- `anthropics/claude-code-action` `docs/security.md`, `docs/setup.md`, `docs/faq.md`, `docs/capabilities-and-limitations.md` at `v1.0.220` (retrieved 2026-09-09): bot policy, write-access requirement, workload identity federation, automatic mode detection, "cannot approve PRs".
- `anthropics/claude-code-action` issues `#1121` (permissions + silent failure, open), `#1068` (missing author trust gate in the shipped template, open), `#1482` (per-run cost not exposed, open), `#939` (fork-PR support design discussion, open) — `https://github.com/anthropics/claude-code-action/issues/<n>` (retrieved 2026-09-09).
- `GET https://api.github.com/repos/anthropics/claude-code-action`, `/releases?per_page=30`, `/git/refs/tags`, `/issues?state=all&sort=created&direction=desc`, and `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open` (all retrieved 2026-09-09): stars 8832, archived false, pushed 2026-09-09T20:12:20Z, MIT, latest `v1.0.220`, 287 tags, 457 open issues, ten-issue responsiveness sample.
- `GET https://api.github.com/search/code?q="anthropics/claude-code-action"+path:.github/workflows` (retrieved 2026-09-09): `total_count` 20480, plus the named adopters and the `.disabled`/`.bkup` observations.
- `GET https://api.github.com/repos/anthropics/claude-code/contents/plugins/code-review` (retrieved 2026-09-09): the plugin `py` invokes exists.
- `github/docs` `content/actions/reference/workflows-and-actions/contexts.md` §"Context availability" — `https://raw.githubusercontent.com/github/docs/main/content/actions/reference/workflows-and-actions/contexts.md` (retrieved 2026-09-09): `jobs.<job_id>.if` → `github, needs, vars, inputs`; `jobs.<job_id>.steps.if` → no `secrets`.
- `github/docs` `content/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review.md` (retrieved 2026-09-09): Copilot automatic review and "Review new pushes" are ruleset settings.
- Alternatives, all via `GET https://api.github.com/repos/<o>/<r>` plus `/tags?per_page=5`, `/releases?per_page=1`, and the open-issue search (retrieved 2026-09-09): `The-PR-Agent/pr-agent` (12923, MIT, `v0.45.0`, 58 open; reached by HTTP 301 from `qodo-ai/pr-agent`), `google-github-actions/run-gemini-cli` (2072, Apache-2.0, `v0.1.22` 2026-04-24, 62 open), `openai/codex-action` (1231, Apache-2.0, tag `v1.12`, zero releases, 36 open), `coderabbitai/ai-pr-reviewer` (HTTP 404).
- Rust practice survey: `GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows` for the twelve projects tabulated in the top-level `### Landscape`, and `GET https://api.github.com/search/code?q=org:rust-lang+"claude-code-action"` → `total_count: 0` (retrieved 2026-09-09).
- 2025 State of Rust Survey results, `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` (source read from `rust-lang/blog.rust-lang.org` `content/2025-state-of-rust-survey-results/index.md`, retrieved 2026-09-09): 7,156 responses; one passing mention of LLM tooling; no CI-review question.
- `py-launch-blueprint` at pinned commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read with `git -C ~/c/py-launch-blueprint show b08bccfb:.github/workflows/claude-code-review.yml` (retrieved 2026-09-09): triggers `[opened, synchronize, ready_for_review, reopened]`; fork and dual-bot guard; `permissions: contents: read / pull-requests: read / issues: read / id-token: write`; `anthropics/claude-code-action@v1.0.175`; `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}`.
- `ts-launch-blueprint` at pinned commit `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, read with `git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb -- .github/` (retrieved 2026-09-09): nine workflow files, none AI-related — the absence F051 records is confirmed at the pin.
- `GET https://api.github.com/repos/smorinlabs/py-launch-blueprint/pulls/470` (retrieved 2026-09-09): the incident the `py` guard comment cites, authored by `release-please-smorinlabs[bot]`, `"type": "Bot"`, merged 2026-07-19.

#### F052 — @mention-triggered AI assistant workflow (.github/workflows/claude.yml)

##### Landscape

The category for this member is "an agent a maintainer can summon into a GitHub thread by name, which can then read the repository, answer, and push commits". This is a materially different category from F051 — it is on-demand rather than automatic, conversational rather than one-shot, and it needs write access to `contents` where F051 does not. Bin one (first-party to the CI host): **GitHub Copilot coding agent**, summoned by assigning an issue to Copilot rather than by mention, and configured through account and organization settings rather than a workflow file (`github/docs` `content/copilot/how-tos/use-copilot-agents/`, retrieved 2026-09-09). Bin two (established): **`anthropics/claude-code-action`**, whose interactive mode *is* this category's reference implementation. Bin three (up-and-comers): **`google-github-actions/run-gemini-cli`** and **`openai/codex-action`**, both of which also support a mention-triggered mode.

`The-PR-Agent/pr-agent` is a partial member of this category only — it responds to slash commands on pull requests rather than acting as a general repository assistant on issues, so it covers less of the F052 surface than it does of F051's.

Practice evidence is the same twelve-project Rust survey as F051 and produces the same result: **0 of 12**, and `org:rust-lang` code search `total_count: 0` (retrieved 2026-09-09). The adoption evidence is again cross-ecosystem, and for this member it is somewhat stronger than for F051 in one specific respect: of the ten code-search results sampled, the enabled files found (`milvus-io/milvus`, `fxsound2/fxsound-app`, `workadventure/workadventure`, `mxpv/podsync`, `mattzcarey/shippie`) were all named `claude.yml` — the F052 shape — while all three disabled or backed-up files (`.disabled`, `.disabled`, `.bkup`) were review workflows. This is a small, non-random sample from a search-relevance ordering and cannot support a rate; it is recorded as a direction consistent with the trigger reasoning in F051's `Fit for this template`.

##### Principles and implementation

The principle is: *a maintainer should be able to bring an agent into an existing GitHub conversation with its full context, without leaving the thread and without granting standing automation.* Agreement level: policy/mechanism, for the same three reasons argued in the top-level field.

Essential behaviors: (1) the job starts only when the trigger phrase appears in one of the four listened-to event bodies; (2) only a user with repository write access can cause it to run; (3) bots cannot cause it to run; (4) the agent can read CI results on the pull request it is summoned into; (5) in an unconfigured downstream fork, a stray `@claude` produces no red check.

Behaviors (2) and (3) are enforced by the action itself, not by the workflow, and this is the fact most likely to be got wrong by anyone reading `py`'s `if:` condition as the whole security story. `docs/security.md` at `v1.0.220` states: "The action can only be triggered by users with write access to the repository. This is checked for issue, pull request, comment, and review events", and "By default, GitHub Apps and bots cannot trigger this action for security reasons. Use the `allowed_bots` parameter to enable specific bots or all bots." `action.yml` corroborates with `allowed_bots` `default: ""` and `allowed_non_write_users` `default: ""`. `docs/faq.md` adds the operational corollary — "Only users with **write permissions** to the repository can trigger Claude" — and a second one worth recording for a template: the `github-actions` user cannot trigger subsequent workflows, so an `@claude` posted by another workflow will not start this one.

Open issue `#1068` ("Default workflow template missing author trust gate — secrets exposed on public repos", opened 2026-03-18, still open) argues that the shipped `examples/claude.yml` `if:` condition tests only for the trigger phrase and no `author_association`, so on a public repository any commenter can start a run that touches `secrets` and requests an OIDC token. The action's in-action write-access check is the answer to the *trigger* half of that concern; the issue's residual point is about the run starting at all. Two mitigations follow directly and are folded into the recommendation: the repository-variable enable flag (which makes the whole question moot downstream), and workload identity federation (which removes the static secret the issue is about).

The reference implementation, read verbatim at `v1.0.220`, is the maintainer's own `.github/workflows/claude.yml`; its `if:` condition is character-identical to `py`'s, which is itself character-identical to `examples/claude.yml`. That three-way identity is the single strongest piece of evidence that this member's trigger configuration needs no change:

```yaml
# anthropics/claude-code-action .github/workflows/claude.yml @ v1.0.220 (trigger block)
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]
jobs:
  claude:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
      (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude')))
```

Acceptance criteria: a comment containing `@claude` from a write-access user starts a run and produces a reply comment; the same comment from a non-write user produces no agent action; a comment without the phrase starts nothing; in a template-derived repository with no variable set, `@claude` produces a skipped job.

##### Dominant choice

`anthropics/claude-code-action` at `v1.0.220`, in interactive mode — that is, with the `prompt` input **omitted**, which `docs/faq.md` §"How does automatic mode detection work?" states is exactly what selects interactive mode ("Without `prompt` input: Runs in interactive mode - waits for @claude mentions in comments"). This is the same component as F051 with a different input set, which is the whole basis of the bundle argument.

| Figure | Value | Endpoint / rule |
|---|---|---|
| 90-day downloads | `inapplicable` — a GitHub Action is not published to crates.io | no crates.io record exists for this subject |
| All-time downloads | `inapplicable` — same reason | same |
| Last release | `v1.0.220`, `2026-09-09T20:12:09Z`, not a prerelease | `GET https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=30` |
| Stars, archived | `stargazers_count: 8832`; `archived: false`; `pushed_at: 2026-09-09T20:12:20Z`; `license.spdx_id: MIT` | `GET https://api.github.com/repos/anthropics/claude-code-action` |
| Open issues | `457` | `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open`, `total_count` |
| Issue responsiveness | Same probe as F051 (one repository, one figure): 10 most recently opened issues, **0 with a first maintainer response, 10 unanswered, median not computable** | `GET .../issues?state=all&sort=created&direction=desc` plus each `comments_url` |
| Advisories | `inapplicable` — no RustSec page exists for a GitHub Action | `https://rustsec.org/packages/<name>.html` has no applicable subject |
| Adopters | 20,480 workflow files reference the action; the enabled files in the sampled results are predominantly `claude.yml`, this member's shape (`milvus-io/milvus`, `fxsound2/fxsound-app`, `workadventure/workadventure`, `mxpv/podsync`, `mattzcarey/shippie`). Most probative: the maintainer runs this exact workflow on its own repository. | `GET https://api.github.com/search/code?q="anthropics/claude-code-action"+path:.github/workflows`; file read at the pinned tag |

Maintenance state by rubric: **active** — identical evidence and identical reasoning to F051 (a release published on the retrieval date; 28 patch releases in the 27 days to `v1.0.220`; no `v2` tag among 287 tags). The same concrete negative signal applies and is confined to issue triage, not to shipping.

One detail specific to this member: the maintainer's own `claude.yml` pins `anthropics/claude-code-action@main`, not a tag. That is a maintainer dogfooding their own default branch and is **not** a pattern to copy into a template; it is recorded because it shows the reference file is a live configuration rather than a frozen sample.

##### Qualified shortlist

| Candidate | Stars | License | Last tagged version | Open issues | Mention-triggered mode | Same component as F051 |
|---|---|---|---|---|---|---|
| `anthropics/claude-code-action` | 8,832 | MIT | `v1.0.220` (2026-09-09) | 457 | Yes — default when `prompt` is omitted | **Yes** |
| `google-github-actions/run-gemini-cli` | 2,072 | Apache-2.0 | `v0.1.22` (2026-04-24); pushed 2026-08-21 | 62 | Yes | Yes |
| `openai/codex-action` | 1,231 | Apache-2.0 | `v1.12`; no releases published | 36 | Yes | Yes |
| GitHub Copilot coding agent | `inapplicable` — platform feature | Proprietary (GitHub) | `inapplicable` | `inapplicable` | Assignment-triggered rather than mention-triggered | No |
| `The-PR-Agent/pr-agent` | 12,923 | MIT | `v0.45.0`; pushed 2026-09-09 | 58 | Partial — slash commands on pull requests, not a general issue assistant | Yes, but covers less of this member |

Figures from `GET https://api.github.com/repos/<o>/<r>` plus `/tags?per_page=5`, `/releases?per_page=1` and the open-issue search, all retrieved 2026-09-09.

The shortlist ordering differs from F051's in one place that matters: `The-PR-Agent/pr-agent`, F051's strongest runner-up on tracker health, drops here because it is a pull-request review tool rather than a repository assistant, so choosing it would mean two vendors, two credentials and two mental models — the exact outcome the bundle exists to avoid.

##### Excluded by gate

**No candidate fails gates 1 through 6.** Applied in full to the dominant choice, with each inapplicable metric named:

1. **License** — **pass**: `license.spdx_id: MIT` (`GET https://api.github.com/repos/anthropics/claude-code-action`, retrieved 2026-09-09), compatible with `MIT OR Apache-2.0`; invoking an action propagates no license term into the template's artifacts.
2. **MSRV** — **inapplicable**: a composite action implemented in TypeScript on Bun; no `rust-version`, no presence in `Cargo.toml`, no presence in the dependency tree, so the MSRV policy is not engaged.
3. **RustSec advisory and `unsafe` posture** — **inapplicable** in both halves (not a crates.io package; no Rust code). Stated equivalent, which for this member is *more* consequential than for F051 because the job holds `contents: write`: the action requires repository write access of the triggering user and refuses bots by default; it sanitizes untrusted content (HTML comments, invisible characters, image alt text, hidden attributes, HTML entities) while `docs/security.md` warns that "new bypass techniques may emerge"; `include_comments_by_actor` and `exclude_comments_by_actor` exist to allowlist or filter whose comments reach the model; `docs/capabilities-and-limitations.md` records that the agent cannot approve pull requests or submit formal reviews, which bounds the damage a successful injection could do to the merge gate.
4. **`ubuntu-latest, macos-latest`** — **inapplicable as a matrix gate**: a single non-matrix job on one Linux runner in `py`, in `examples/claude.yml` and in the maintainer's own file. It does not join the crate OS matrix. Windows, noted not required: partial, per the `runner.os != 'Windows'` guards in `action.yml`.
5. **Default features / async-runtime coupling** — **inapplicable** (no Cargo features, no Rust async runtime). The defaults that matter for this member, from `action.yml` at `v1.0.220`: `trigger_phrase: "@claude"`, `assignee_trigger` unset, `label_trigger: "claude"`, `allowed_bots: ""`, `allowed_non_write_users: ""`, `branch_prefix: "claude/"`, `use_sticky_comment: "false"`, `use_commit_signing: "false"`, `bot_name: "claude[bot]"`. Note `label_trigger` defaults to `"claude"`, so a repository that later adds a `claude` label acquires a second trigger path it did not configure — worth knowing before adopting.
6. **Binary size / compile time** — **inapplicable**; equivalent stated: no `cargo` invocation and therefore no compile-time cost; fixed overhead is a checkout plus the Bun install (`action.yml` comments: 35 MB, 2-3 seconds); variable cost is one agent session per summons, which is bounded by human action rather than by repository traffic. Per-run cost telemetry is an evidence gap (issue #1482, open).

Set aside for non-gate reasons: **GitHub Copilot coding agent** — excluded on fit (assignment-triggered, configured in account and organization settings, ships no file, so it cannot travel through "Use this template"). **`The-PR-Agent/pr-agent`** — excluded on scope (covers pull-request commands, not the issue-assistant surface this member requires).

##### Up-and-comers

The same two vendor-published newcomers occupy this bin as in F051, and for this member their relevance is slightly higher, because a mention-triggered assistant is a thinner integration than a plugin-driven reviewer and therefore easier to substitute later. `google-github-actions/run-gemini-cli` — 2,072 stars, Apache-2.0, created 2025-07-11, newest tag `v0.1.22` (2026-04-24) against `pushed_at` 2026-08-21T16:03:24Z, 62 open issues. `openai/codex-action` — 1,231 stars, Apache-2.0, created 2025-10-01, newest tag `v1.12`, **zero GitHub releases published**, `pushed_at` 2026-08-26T00:12:45Z, 36 open issues. All figures from `GET https://api.github.com/repos/<o>/<r>`, `/tags?per_page=5`, `/releases?per_page=1` and `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, retrieved 2026-09-09.

Neither is recommended yet, on figures rather than impressions: a four-month-old newest tag against an actively pushed branch in the first case, and no release notes at all in the second. Both would become serious candidates on a `v1` release series with published notes — recorded as a re-verify condition below. A third newcomer worth naming for completeness is the **GitHub Copilot coding agent**, which is new in the same period but is not in this bin because it is a platform feature rather than a versioned action, and so cannot be shipped in a template tree.

##### Fit for this template

Three fit observations, in decreasing order of consequence.

**Fit 1 — this member is what makes F051's narrowed trigger safe.** Dropping `synchronize` from the review lane removes automatic re-review after a fix-up push. The replacement is a maintainer or contributor with write access typing `@claude please re-review the last two commits`, which this workflow serves. Without F052 the narrowing would be a straight capability loss; with it, the pair delivers "review on the moments that matter, plus review on demand" for strictly less spend than "review on every push". This is the strongest argument in the report for treating F051 and F052 as one bundle, and it is an argument about *design*, not about the shared action family.

**Fit 2 — the failure mode downstream is narrower than F051's but has the same fix.** F051 would fire on the first pull request in any fork; F052 fires only when someone types `@claude`, which in an unconfigured fork of a Rust template is rare but not impossible — and when it happens, the run is red and the fork owner has no idea why. The same `vars`-gated flag fixes it, subject to the same platform rule: `secrets` is unavailable in `jobs.<job_id>.if` while `vars` is available (`github/docs` `content/actions/reference/workflows-and-actions/contexts.md`, retrieved 2026-09-09). A single shared variable name for both workflows is preferable to two, because the two capabilities are enabled by the same act of installing the App and configuring the credential.

**Fit 3 — the CLI plus library plus web-service shape argues for `actions: read`, and Rust argues nothing.** The template will run a multi-job CI matrix (R11 owns its structure). An assistant that cannot read why a job went red is much less useful in that setting, so `actions: read` in `permissions:` together with `additional_permissions: actions: read` — the pairing `py` already uses, and which `docs/capabilities-and-limitations.md` names as the requirement for "View GitHub Actions Results" — is retained rather than trimmed. Nothing else about the Rust shape changes this member: the trigger events, the phrase, the guards and the permissions are all language-independent, and the answer to the HIGH portability question is again **ports unchanged**.

##### Recommendation

Ship `.github/workflows/claude.yml` using `anthropics/claude-code-action` at `v1.0.220`, with `py`'s four events and four-clause `@claude` condition unchanged, plus the shared enable flag, plus federation-based credentials.

```yaml
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]
jobs:
  claude:
    # First clause is the template-fork guard; the rest is py's condition verbatim,
    # which is itself identical to examples/claude.yml and to the maintainer's own file.
    if: |
      vars.ENABLE_CLAUDE_ASSISTANT == 'true' &&
      ((github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
       (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
       (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
       (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude'))))
    runs-on: ubuntu-latest          # runner indirection is R09's to decide
    permissions:                    # repo-wide hardening convention is R08's to decide
      contents: write
      pull-requests: write
      issues: write
      id-token: write
      actions: read                 # lets the agent read CI results on the PR
    steps:
      - uses: actions/checkout@v7   # action pin form is R20's to decide
        with:
          fetch-depth: 1
      - uses: anthropics/claude-code-action@v1.0.220
        with:
          anthropic_federation_rule_id: ${{ vars.ANTHROPIC_FEDERATION_RULE_ID }}
          anthropic_organization_id: ${{ vars.ANTHROPIC_ORGANIZATION_ID }}
          anthropic_service_account_id: ${{ vars.ANTHROPIC_SERVICE_ACCOUNT_ID }}
          additional_permissions: |
            actions: read
          # No `prompt:` input — omitting it is what selects interactive @claude mode.
```

The MEDIUM question in `## Questions` — can the action be scoped cleanly to just issue comments, pull-request review comments and issue bodies? — answers **yes, and `py` already does it, with one addition worth knowing about**: the four `on:` blocks plus the four-clause `if:` are the documented and maintainer-used way to scope it, and `contains()` on the specific body field is what keeps unrelated comments from starting a job. The addition is that `label_trigger` defaults to `"claude"`, so scoping by event does not by itself preclude a label-based trigger later.

##### Ranked runner-up

1. **`google-github-actions/run-gemini-cli`** (2,072 stars, Apache-2.0, `v0.1.22`). The best like-for-like substitute if the owner's model relationship is Google's: same architecture, same mention-trigger shape, and it also covers F051, so the bundle property survives. Costs: a four-month-old newest tag against an actively pushed default branch, and a much smaller adopter base.
2. **`openai/codex-action`** (1,231 stars, Apache-2.0, tag `v1.12`). Same substitution logic for an OpenAI credential; publishes no GitHub releases, so every bump is an unannotated diff.
3. **GitHub Copilot coding agent**. Take it only if the owner already pays for Copilot across the organization and accepts that the capability ships as account configuration rather than as template files; it also changes the interaction from mention to assignment.
4. **Do without this member and keep only F051.** Ranked last deliberately: it is strictly worse than adopting both or neither, because it removes the on-demand re-review that makes F051's bounded trigger list acceptable, while still paying every fixed cost (App install, credential, pin maintenance, Dependabot surface).

##### Tradeoffs

| Axis | What the recommendation buys | What it costs |
|---|---|---|
| Four events plus phrase test (unchanged from `py`) | Exactly the surface the maintainer and the shipped example use — the lowest-surprise configuration available | Broad `on:` blocks mean the workflow is *evaluated* on every comment in the repository, even though it runs on almost none; noisy in the Actions tab of a busy repository |
| `contents: write`, `issues: write`, `pull-requests: write` | The agent can actually do the work it is summoned for — push a fix, edit a comment, update an issue | The widest permission grant of any workflow this item touches, on a job reachable from user-authored text; mitigated by the action's write-access requirement and bot refusal, not eliminated (issue #1068) |
| `actions: read` plus `additional_permissions` | The agent can explain a red CI job — the highest-value use in a multi-job Rust matrix | One more grant, and a coupling to R11's job structure |
| Shared enable flag with F051 | One switch, one mental model, inert in every fork | If the owner ever wants one member without the other, the shared flag must be split into two |
| Interactive mode (no `prompt`) | Zero prompt maintenance; the summoning comment *is* the instruction | Output quality is not controlled by anything in this repository and cannot be regression-tested |
| Federation over a static token | Nothing long-lived to leak from a public repository | Console setup a fork owner must repeat; `docs/setup.md` notes inline-comment classification is skipped under federation |

##### Parameters

This member owns no parameter (`research/CLAUDE.md` lists R18's `owns` as `—`). It assumes the four owner-fixed values from `docs/port/PARAMETERS.md`: `assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `assumes license = MIT OR Apache-2.0`; `assumes target-os-matrix = ubuntu-latest, macos-latest`. None is engaged by a workflow file that never invokes `cargo`, except `target-os-matrix` in the negative sense recorded under gate 4. R18's `## Couplings` block lists an empty `consumes:`, so **no `CONFLICT:` line is emitted**.

##### Migration implications

New file `.github/workflows/claude.yml` (about 40 lines as drafted). No existing file changes. Same three coordination obligations as F051 — pin form to R20, `permissions:` shape to R08, `runs-on:` to R09 — plus one that is specific to this member: R45 owns the pull-request-comment bot-trigger block, and this workflow's four `on:` blocks overlap the same event space, so the two must be read together at implementation time to avoid a repository where two workflows both wake on every `issue_comment`. Documentation obligation: `CONTRIBUTING.md` should state that only users with write access can summon the agent (an outside contributor typing `@claude` will get silence, and the reason is not visible to them), and that a comment posted by another workflow cannot trigger it (`docs/faq.md`).

##### Validation strategy

All checks are **proposed**; none was executed, because the repository has no `.github/workflows/` tree and no Rust code yet.

```bash
# 1. Static validity.
actionlint .github/workflows/claude.yml
# expect: exit 0

# 2. Negative trigger: a comment with no trigger phrase starts nothing.
gh issue comment <n> --body 'plain comment, no mention'
gh api repos/<owner>/rs-launch-blueprint/actions/workflows/claude.yml/runs --jq '.total_count'
# expect: unchanged from the pre-comment value

# 3. Positive trigger from a write-access user: a run starts and replies.
gh issue comment <n> --body '@claude summarize this issue'
gh api repos/<owner>/rs-launch-blueprint/actions/workflows/claude.yml/runs \
  --jq '.workflow_runs[0].conclusion'
# expect: success, and a new comment authored by claude[bot] on the issue

# 4. Non-write user: the action must stop before running the model.
#    Requires a second account; assert no agent comment appears.

# 5. Template-consumer guard: in a repo created from the template with no
#    ENABLE_CLAUDE_ASSISTANT variable, an @claude comment must yield a
#    skipped job, never a failed one.

# 6. CI-reading capability (the reason for actions: read):
#    comment '@claude why did the clippy job fail?' on a PR with a red job and
#    assert the reply names the failing job.
```

Checks 3, 4 and 6 require a live credential and a configured GitHub App, so they belong to the integration step rather than to research; check 5 is the one that validates the departure from `py`'s shape.

##### Confidence & re-verify trigger

**Confidence: high** on configuration, **medium** on adoption. High on configuration for an unusually direct reason: `py`'s `if:` block, `examples/claude.yml` and the maintainer's own `.github/workflows/claude.yml` at `v1.0.220` are character-identical, so the recommended trigger configuration is corroborated three ways from independent files. High also on the security model, which is quoted from `docs/security.md` and corroborated by `action.yml` defaults. Medium on adoption because there is no Rust-ecosystem corroboration in either direction (0 of 12 projects; 0 across `org:rust-lang`), and because the value of a repository assistant on a template repository with low issue traffic is asserted by analogy rather than measured.

Re-verify when: a `v2` tag appears; issue `#1068` closes with a change to the shipped template's `if:` condition; `label_trigger`'s default changes from `"claude"`; the maintainer's own `claude.yml` changes its event list; `run-gemini-cli` or `codex-action` reaches a `v1` release series with notes; or the ten-issue responsiveness probe changes character. Unconditionally re-verify the pin at implementation time — roughly one patch release per day makes `v1.0.220` stale within days.

##### Sources

- `anthropics/claude-code-action` `.github/workflows/claude.yml` at tag `v1.0.220` (retrieved 2026-09-09): the maintainer's own assistant lane — four events, the four-clause `@claude` condition, `contents: write`/`pull-requests: write`/`issues: write`/`id-token: write`, federation via `vars.*`, and `uses: ...@main`.
- `anthropics/claude-code-action` `examples/claude.yml` and `examples/claude-wif.yml` at `v1.0.220` (retrieved 2026-09-09): shipped reference configurations, the second showing the federation variant with `id-token: write` annotated as required.
- `anthropics/claude-code-action` `action.yml` at `v1.0.220` (retrieved 2026-09-09): `trigger_phrase`, `assignee_trigger`, `label_trigger` default `"claude"`, `allowed_bots` default `""`, `allowed_non_write_users` default `""`, `include_comments_by_actor`, `exclude_comments_by_actor`, `additional_permissions`, `branch_prefix`, `bot_name`.
- `anthropics/claude-code-action` `docs/security.md` §"Access Control", `docs/faq.md` §"Triggering and Authentication" and §"How does automatic mode detection work?", `docs/capabilities-and-limitations.md`, `docs/setup.md` at `v1.0.220` (retrieved 2026-09-09): write-access requirement, bot refusal, prompt-injection sanitization and its stated limits, "cannot approve PRs", interactive-vs-automation mode selection, `github-actions` user cannot trigger workflows, federation setup.
- `anthropics/claude-code-action` issue `#1068` (author trust gate missing from the shipped template, open, opened 2026-03-18) and `#1482` (per-run cost not exposed, open) — `https://github.com/anthropics/claude-code-action/issues/<n>` (retrieved 2026-09-09).
- `GET https://api.github.com/repos/anthropics/claude-code-action`, `/releases?per_page=30`, `/git/refs/tags`, `/issues?state=all&sort=created&direction=desc`, and `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open` (retrieved 2026-09-09): the figure table above.
- `GET https://api.github.com/search/code?q="anthropics/claude-code-action"+path:.github/workflows` (retrieved 2026-09-09): `total_count` 20480; the sampled enabled `claude.yml` adopters and the disabled review-workflow observations.
- Alternatives via `GET https://api.github.com/repos/<o>/<r>` plus `/tags?per_page=5`, `/releases?per_page=1` and the open-issue search (retrieved 2026-09-09): `google-github-actions/run-gemini-cli`, `openai/codex-action`, `The-PR-Agent/pr-agent`.
- `github/docs` `content/actions/reference/workflows-and-actions/contexts.md` §"Context availability" (retrieved 2026-09-09): `vars` available to `jobs.<job_id>.if`, `secrets` not.
- `github/docs` `content/copilot/how-tos/use-copilot-agents/` (retrieved 2026-09-09): Copilot agents are configured through settings, not workflow files.
- Rust practice survey: the twelve `GET .../contents/.github/workflows` listings tabulated in the top-level `### Landscape`, and `GET https://api.github.com/search/code?q=org:rust-lang+"claude-code-action"` → `total_count: 0` (retrieved 2026-09-09).
- `py-launch-blueprint` at pinned commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read with `git -C ~/c/py-launch-blueprint show b08bccfb:.github/workflows/claude.yml` (retrieved 2026-09-09): four events; four-clause `@claude` condition; `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write`, `actions: read`; `additional_permissions: actions: read`; `anthropics/claude-code-action@v1.0.175`; `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}`; no `prompt:` input.
- `ts-launch-blueprint` at pinned commit `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, read with `git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb -- .github/` (retrieved 2026-09-09): no `claude.yml` and no AI-assisted workflow of any kind — F052's `py-only` origin confirmed at the pin.

### Compatibility

The two members are not merely compatible — they are the **same component, at the same version, sharing one credential and one GitHub App installation**, differing only in trigger and input set. Three independent proofs of joint testing:

1. **A shared adopter that is also the maintainer.** `anthropics/claude-code-action` runs both members against its own repository: `.github/workflows/claude-review.yml` (automatic review) and `.github/workflows/claude.yml` (`@mention` assistant), both present in the tree at tag `v1.0.220` (retrieved 2026-09-09). The pair is exercised together on every pull request the maintainer opens.
2. **A shared example set in one repository.** The `examples/` directory at `v1.0.220` ships both shapes side by side — `pr-review-comprehensive.yml`, `pr-review-filtered-authors.yml`, `pr-review-filtered-paths.yml` for the review member and `claude.yml`, `claude-wif.yml` for the assistant member — from one `action.yml`, so the input surface is jointly versioned by construction.
3. **A version matrix that is a single cell.** There is no cross-version matrix to test, because there is only one artifact: both members pin `anthropics/claude-code-action@v1.0.220`. `action.yml` at that tag defines every input both members use (`allowed_bots`, `trigger_phrase`, `plugins`, `plugin_marketplaces`, `additional_permissions`, the three federation identifiers), and mode selection between them is internal to the action (`docs/faq.md`: supplying `prompt` selects automation mode, omitting it selects interactive mode). A version bump moves both members together or neither.

**The bundling question, argued rather than assumed.** `## Out of scope` explicitly forbids treating "bundled together" as pre-decided, so here is the argument in both directions.

*Evidence for coupling.* Identical component, identical pin, identical credential, identical GitHub App installation, identical enable-flag semantics, and one Dependabot update surface. The marginal cost of the second file, given the first, is one YAML file and zero new secrets. And the decisive one, which is a design coupling rather than a packaging coincidence: **F051's recommended trigger list is only defensible because F052 exists.** Dropping `synchronize` removes automatic re-review after a push; the replacement is `@claude please re-review`, which is F052. Adopt F051 alone and either the spend is unbounded (keep `synchronize`) or the capability is incomplete (drop it with no fallback).

*Evidence for decoupling.* Two genuine asymmetries exist and should be recorded rather than waved away. F051 additionally depends on the `code-review@claude-code-plugins` plugin fetched at run time from an external marketplace Git URL, which F052 does not — one more moving part and one more trust edge. And their cost profiles differ in kind: F051 spends automatically on repository traffic, F052 spends only when a human asks, so an owner sensitive to unbounded spend has a real reason to want the second without the first.

*Verdict.* Adopt as one bundle. The decoupling asymmetries argue for *configuring* the members differently — which the recommendation does, with different triggers, different permission sets and different plugin use — not for shipping one and not the other. The one split worth honoring is the reverse of the usual one: if the owner will fund only one, F052 alone (on-demand, bounded, no plugin dependency) is more defensible than F051 alone, because F051 alone is the configuration whose spend cannot be predicted from the file.

### Parameters

`owns`: none. The research index (`research/CLAUDE.md`) records R18's `owns` column as `—`, and R18's `## Couplings` block lists no `owns:` entry, so this item contributes no row to `docs/port/PARAMETERS.md`.

`assumes rust-edition = 2024` — not engaged; no workflow file in this item references a Rust edition.
`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — not engaged; neither member adds a crate to the dependency tree, so no MSRV is constrained.
`assumes license = MIT OR Apache-2.0` — engaged and satisfied: the single recommended component is MIT (`license.spdx_id` from `GET https://api.github.com/repos/anthropics/claude-code-action`, retrieved 2026-09-09), and invoking a GitHub Action propagates no license term into the template's distributed artifacts.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — engaged only in the negative: both members are single non-matrix jobs on one Linux runner and deliberately do **not** join the OS matrix. Running an AI review on a second runner would double the cost and produce no additional signal, since the reviewed artifact is a diff, not a build.

**No `CONFLICT:` line is emitted.** R18's `## Couplings` block has an empty `consumes:` field, so there is no consumed parameter whose value this recommendation could need changed; the four values above are owner-fixed and none is challenged.

Two `BASELINE-REVIEW:` findings were raised, and both appear in full in `### Principles and implementation`: one against F051 on the review job's `pull-requests: read` grant, and one against F051 and F052 jointly on the static `CLAUDE_CODE_OAUTH_TOKEN` secret. Neither changes another item or the ledger; both are recorded as challenges with feature ID, affected items and evidence, per `## Context`.

### Migration implications

Two new files, no modified files, because `rs-launch-blueprint` currently has no `.github/workflows/` tree.

| Path | Change | Notes |
|---|---|---|
| `.github/workflows/claude-code-review.yml` | **new**, ~46 lines | `pull_request: [opened, ready_for_review, reopened]`; enable flag, fork guard, dual bot guard; `contents: read`, `pull-requests: write`, `issues: read`, `id-token: write`; `anthropics/claude-code-action@v1.0.220` with the `code-review` plugin and `--comment` |
| `.github/workflows/claude.yml` | **new**, ~40 lines | four events with the four-clause `@claude` condition plus the enable flag; `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write`, `actions: read`; no `prompt:` input |
| `README.md` or `CONTRIBUTING.md` | **new section** | State that both workflows are inert until the repository variables are set; state that only write-access users can summon the agent; record the one-time Anthropic Console federation setup |
| `.github/dependabot.yml` | **coordination only** | The `github-actions` ecosystem gains a dependency that releases roughly daily; R19 owns whether and how that is grouped or throttled |

Repository configuration outside the tree (recorded so the file diff is not mistaken for the whole change): install the Claude GitHub App on the repository; create the Anthropic Console issuer, service account and federation rule; set repository variables `ANTHROPIC_FEDERATION_RULE_ID`, `ANTHROPIC_ORGANIZATION_ID`, `ANTHROPIC_SERVICE_ACCOUNT_ID`, `ENABLE_CLAUDE_REVIEW`, `ENABLE_CLAUDE_ASSISTANT`. Under the fallback static-token path, one secret `CLAUDE_CODE_OAUTH_TOKEN` replaces the three federation variables.

Ownership boundaries this item must not cross, each named with its owner: **R20** decides the `uses:` pin form (exact tag as drafted, commit SHA, or floating `v1`); **R08** decides the repository-wide permission-hardening convention these two `permissions:` blocks sit inside — this item states only what these two jobs need; **R09** decides the `runs-on:` indirection (`py` writes `${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`); **R11** decides the CI job structure the assistant reads through `actions: read`; **R45** owns the pull-request-comment bot-trigger block, which shares the `issue_comment` event space with F052 and must be read alongside it; **R19** decides the Dependabot grouping for the new action dependency.

### Validation strategy

Every command below is **proposed**. None was executed: `rs-launch-blueprint` has no `.github/workflows/` tree, no Rust code and no configured credential at the time of writing, so no workflow run exists to observe. What *was* executed is evidence gathering — REST and raw-content reads against `api.github.com`, `raw.githubusercontent.com`, `blog.rust-lang.org` and the two pinned local clones — and those results are reported as figures throughout, distinct from the checks below.

```bash
# A. Shape and syntax — runnable the moment the files exist, no credential needed.
actionlint .github/workflows/claude-code-review.yml .github/workflows/claude.yml
# expect: exit 0

# B. The recommended pin resolves and is a non-prerelease on the current major.
curl -sS -A 'rs-launch-blueprint/R18' \
  https://api.github.com/repos/anthropics/claude-code-action/releases/tags/v1.0.220 \
  | jq -r '.tag_name, .prerelease'
# expect: v1.0.220 / false
curl -sS -A 'rs-launch-blueprint/R18' \
  https://api.github.com/repos/anthropics/claude-code-action/git/refs/tags/v2
# expect: 404 — confirms v1 is still the current major

# C. Guard behaviour: each of these must yield a SKIPPED job, never a failed one.
#    C1 fork PR · C2 release-please PR · C3 dependabot PR
#    C4 any PR in a repo created from the template with no ENABLE_* variable set
gh api repos/<owner>/<repo>/actions/workflows/claude-code-review.yml/runs \
  --jq '.workflow_runs[0] | {event, conclusion}'
# expect: conclusion == "skipped"

# D. The principle actually holds — the review is posted (this is the check that
#    distinguishes the recommendation from py's pull-requests: read configuration).
gh api repos/<owner>/<repo>/issues/<pr>/comments --jq 'length'
# expect: >= 1 on a human PR in the configured origin repository.
# A green job with 0 comments reproduces anthropics/claude-code-action#1121.

# E. Assistant reachability and scoping.
#    E1 comment without '@claude'  -> run count unchanged
#    E2 comment with '@claude' from a write-access user -> run succeeds, reply posted
#    E3 same comment from a non-write user -> no agent action (action-side gate)
#    E4 '@claude why did the clippy job fail?' on a red PR -> reply names the job
#       (proves actions: read + additional_permissions are wired)

# F. Cost observation, since no per-run figure is published upstream.
#    After 20 pull requests, compare Anthropic Console usage against the run count
#    for claude-code-review.yml to derive a local per-review cost. This is the
#    measurement that would let the dropped `synchronize` trigger be re-decided
#    on numbers rather than on structure.
```

Expected behaviour in one sentence per group: A proves the files are well-formed; B proves the pin and the major version; C proves the guard contract (the security and correctness property that must agree across all three sibling repositories); D proves the capability is actually delivered rather than silently swallowed; E proves the assistant is reachable, scoped and CI-aware; F closes the one evidence gap this report could not close from public endpoints.

### Confidence & re-verify trigger

**Confidence: high on mechanism, medium on the adopt-or-not judgment.**

High on mechanism, because every load-bearing claim in this report resolves to a primary artifact read at a pinned reference, not to recollection: the GitHub context-availability table (`secrets` absent from `jobs.<job_id>.if`); the `allowed_bots: ""` default and the "bots cannot trigger this action" statement; the federation input set and its `id-token: write` requirement; the maintainer's own two workflow files and their trigger, permission and credential choices; the three-way character-identity of the `@claude` condition across `py`, `examples/claude.yml` and the maintainer's own file; the existence of the `code-review` plugin; the bot authorship of `py` PR #470; and the absence of any `v2` tag among 287 tags.

Medium on the adopt-or-not judgment, for three stated reasons rather than as hedging. First, **no Rust-ecosystem signal exists in either direction**: 0 of 12 well-regarded Rust projects ship such a workflow and `org:rust-lang` shows zero uses, so the decision cannot be corroborated by Rust practice and rests on the template's own goals plus cross-ecosystem adoption. Second, **per-run cost is unmeasurable from public endpoints** (issue #1482 open), so the `synchronize` recommendation is argued structurally — one unbounded trigger versus three one-shot ones, plus the maintainer's own `[opened]`-only choice — rather than numerically. Third, **the tracker is unattended**: 457 open issues and 0 of the 10 most recently opened receiving any maintainer response, which is a real dependability risk for a consumer even though the code ships daily.

Re-verify on any of: a `v2` tag appearing on `anthropics/claude-code-action`, or the repository becoming archived; `#1121` closing with a change to the recommended permissions; `#1068` closing with a change to the shipped template's trust gate; `#1482` closing, which would make the `synchronize` decision quantitative; the maintainer's own `claude-review.yml` adding `synchronize`; `google-github-actions/run-gemini-cli` or `openai/codex-action` publishing a `v1` release series with notes; `The-PR-Agent/pr-agent` adding a first-class issue-assistant mode, which would make a two-vendor split competitive; or the ten-issue responsiveness probe changing character in either direction. Re-verify the version pin unconditionally at implementation time: at roughly one patch release per day, `v1.0.220` is stale within days, and R20's pin-form decision should be made against the figure current then.

### Sources

Every figure and quotation below was retrieved on **2026-09-09** (local date; GitHub REST timestamps quoted in the report are UTC, and one of them — `anthropics/claude-code` `pushed_at: 2026-09-10T02:23:10Z` — falls on the following UTC day, which is expected and is noted rather than adjusted).

Live endpoints queried with `curl -sS` and the header `User-Agent: rs-launch-blueprint-research/R18` (GitHub REST calls additionally sent `Authorization: Bearer <gh auth token>` to obtain the 5,000/hour rate limit and access to code search):

- `GET https://api.github.com/repos/anthropics/claude-code-action` — stars 8832, `archived: false`, `pushed_at` 2026-09-09T20:12:20Z, `license.spdx_id: MIT`, `created_at` 2025-05-19T15:26:50Z.
- `GET https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=30` — newest non-prerelease `v1.0.220` (2026-09-09T20:12:09Z); 29 of 30 within 90 days; oldest of the 30 is `v1.0.192` (2026-08-13T23:31:59Z).
- `GET https://api.github.com/repos/anthropics/claude-code-action/git/refs/tags` — 287 tags; floating majors `v0` and `v1`; no `v2`; `v1.0.175` (py's pin) present.
- `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open` — `total_count: 457`.
- `GET https://api.github.com/repos/anthropics/claude-code-action/issues?state=all&sort=created&direction=desc` plus each item's `comments_url` — ten most recently opened issues (#1818, #1817, #1798, #1796, #1795, #1788, #1781, #1779, #1777, #1776): zero first responses from OWNER/MEMBER/COLLABORATOR; unanswered 10; median not computable.
- `GET https://api.github.com/search/code?q="anthropics/claude-code-action"+path:.github/workflows` — `total_count: 20480`; adopters `milvus-io/milvus`, `fxsound2/fxsound-app`, `workadventure/workadventure`, `mxpv/podsync`, `mattzcarey/shippie`; disabled or backed-up review workflows in `wvlet/airframe`, `EvotecIT/PSWriteHTML`, `taikoxyz/taiko-mono`.
- `GET https://api.github.com/search/code?q=org:rust-lang+"claude-code-action"` — `total_count: 0`.
- `GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows` for `astral-sh/uv`, `astral-sh/ruff`, `BurntSushi/ripgrep`, `tokio-rs/tokio`, `zed-industries/zed`, `helix-editor/helix`, `nushell/nushell`, `tauri-apps/tauri`, `bevyengine/bevy`, `casey/just`, `rust-lang/cargo`, `denoland/deno` — no AI-review workflow in any of the twelve.
- `GET https://api.github.com/repos/<o>/<r>` (plus `/tags`, `/releases`, open-issue search) for `google-github-actions/run-gemini-cli`, `openai/codex-action`, `qodo-ai/pr-agent` (HTTP 301 → `The-PR-Agent/pr-agent`, repository id 662766482), `coderabbitai/ai-pr-reviewer` (**HTTP 404 — repository absent**), `anthropics/claude-code`.
- `GET https://api.github.com/repos/anthropics/claude-code/contents/plugins/code-review` — `.claude-plugin`, `README.md`, `commands`.
- `GET https://api.github.com/repos/smorinlabs/py-launch-blueprint/pulls/470` — `chore(release): publish v2.4.1`, author `release-please-smorinlabs[bot]` (`"type": "Bot"`), merged 2026-07-19T04:29:41Z.
- `https://raw.githubusercontent.com/anthropics/claude-code-action/v1.0.220/{action.yml, docs/security.md, docs/setup.md, docs/faq.md, docs/usage.md, docs/configuration.md, docs/capabilities-and-limitations.md, examples/*.yml, .github/workflows/claude-review.yml, .github/workflows/claude.yml}`.
- `https://raw.githubusercontent.com/github/docs/main/content/actions/reference/workflows-and-actions/contexts.md` and `.../content/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review.md`.
- `https://raw.githubusercontent.com/rust-lang/blog.rust-lang.org/main/content/2025-state-of-rust-survey-results/index.md` — the 2025 State of Rust Survey results (7,156 responses; published at `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`).

Pinned local clones (both repositories read at the commits named in the task, not at their working tips):

- `git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/workflows/claude-code-review.yml` and `:.github/workflows/claude.yml`; `git ls-tree -r --name-only b08bccfb -- .github/workflows .github/dependabot.yml`.
- `git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb2e88b898e8c081b0abbfabc1630079c00 -- .github/`.

Repository context read for this item: `docs/port/COMMONALITY.md` (rows F051, F052), `docs/port/areas/ci-workflows.md` (rows F051, F052), `docs/port/PARAMETERS.md`, `docs/port/BASELINE-REVIEW.md`, `research/CLAUDE.md`, and the run's own `inputs/prompt.md`.

**Method notes.** Endpoints queried: `api.github.com` (`/repos/<o>/<r>`, `/releases`, `/tags`, `/git/refs/tags`, `/issues`, `/issues/<n>/comments`, `/contents/<path>`, `/pulls/<n>`, `/search/issues`, `/search/code`), `raw.githubusercontent.com` (action source, action docs, action examples, the action's own workflows, `github/docs` reference pages, the Rust survey source), and `blog.rust-lang.org/feed.xml`. All GitHub calls carried a `User-Agent` header and a bearer token from the local `gh` CLI; search calls were spaced to stay inside the search rate limit. `ts-launch-blueprint` is private and its GitHub endpoints return HTTP 404, so **all TypeScript evidence in this report was read from the local pinned clone at `~/c/ts-launch-blueprint` at commit `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`** via `git ls-tree`, as the task directs; Python evidence likewise comes from `~/c/py-launch-blueprint` at commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5` via `git show`, which is one commit series behind that clone's current tip (`c1216c6`) — the pinned tree was used throughout. Crate-shaped endpoints (`crates.io/api/v1/crates/...`, `rustsec.org/packages/...`, `docs.rs`) were **not** queried, because neither member is a Rust crate and those services have no record of a GitHub Action; each such metric is marked `inapplicable` with that reason in both members' gate lists rather than omitted. What could **not** be verified, stated plainly: (1) per-run cost, token usage and wall-clock latency for either workflow — no figure is published and `anthropics/claude-code-action#1482` (open) is the evidence that the action does not expose one, so the `synchronize` recommendation is argued structurally rather than numerically; (2) the proportion of adopters who disable the review workflow — the code-search API returns a relevance-ordered sample, not a census, so the `.disabled`/`.bkup` observations are reported as a direction and not as a rate; (3) whether `py`'s `pull-requests: read` grant actually suppresses review comments in `py`'s repository — the failure mode is documented and reproduced by third parties in issue #1121, but no run of `py`'s own workflow was inspected; (4) median days to first maintainer response for `anthropics/claude-code-action` — the ten-issue sample contained zero maintainer responses, so the median is undefined rather than large, and the unanswered count (10) is reported instead; (5) the two `run-gemini-cli` and `codex-action` alternatives were evaluated on repository metadata and release state only, not by reading their action definitions in the depth applied to the dominant choice; (6) no command in `### Validation strategy` was executed — `rs-launch-blueprint` has no `.github/workflows/` tree, no Rust code and no configured credential, so every check there is proposed, and the only executed work was the evidence gathering listed above.
