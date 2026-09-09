## Reasoning Summary
**Searching for repositories**

I'm thinking I might need to find repositories that aren’t directly accessible. It seems like searching for public repositories like "py-launch-blueprint" on GitHub could be a good approach. I don't necessarily require prior art from the owner of Rust repositories. I can use the context provided in Python/TypeScript as supporting evidence without browsing, but I need source URLs for every claim. So, searching for those public source URLs seems like the next step!

### Landscape

**Research date:** September 9, 2026.

**Category:** source-controlled, AI-assisted GitHub repository automation for code review and maintainer ChatOps. This is a repository-governance decision, not a Rust library decision. None of the candidates adds a Cargo dependency, so crates.io downloads, crate releases, RustSec, MSRV, `unsafe`, async-runtime coupling, and Rust binary-size metrics are **inapplicable**.

**Three-bin map**

| Bin | Candidates | Assessment for this template |
|---|---|---|
| **Built-in or first-party toolchain** | GitHub Actions events, permissions, fork protections, and native `GITHUB_TOKEN`; Anthropic’s hosted Claude Code Review | GitHub primitives are mandatory substrate. Hosted Claude Code Review covers automatic review but is not a successor for the general `@claude` assistant and is not version-pinned in repository source. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)) |
| **Established industry standard** | `anthropics/claude-code-action`; managed review apps such as CodeRabbit; `openai/codex-action` | The Anthropic action is the strongest fit if Claude workflows are deliberately enabled: it has one stable API for automation mode and mention-driven interactive mode. CodeRabbit supports automatic and manually requested PR reviews but is managed SaaS rather than an immutable Action dependency. Codex is maintained and security-conscious but would be a provider change without an owner requirement. ([github.com](https://github.com/anthropics/claude-code-action/releases)) |
| **Up-and-comer** | GitHub Agentic Workflows (`gh-aw`); `google-github-actions/run-gemini-cli@v0` | `gh-aw` offers provider-neutral compilation, sanitized command triggers, and validated “safe outputs,” but adds a compiler and generated lock workflows and remains an emerging architecture. Gemini supports PR review and `@gemini-cli` collaboration but its maintained example still uses a pre-1.0 `@v0` action. ([github.github.com](https://github.github.com/gh-aw/gallery/automated-pr-review/)) |

**Authority used**

- **GitHub documentation** is authoritative for event semantics, fork/Dependabot credential restrictions, `pull_request_target` risk, and immutable Action pinning. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows))
- **Anthropic’s documentation, Action repository, releases, and examples** are authoritative for the current action family, inputs, authentication, actor checks, permissions, and supported modes. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md))
- **Official Google, OpenAI, GitHub Agentic Workflows, and CodeRabbit sources** establish the alternatives rather than relying on familiarity with Claude. ([github.com](https://github.com/google-github-actions/run-gemini-cli/blob/main/README.md))
- **Maintained implementations and issue reports** are treated as practice evidence, not normative authority. The current Python blueprint and Semgrep’s workflow demonstrate real Action usage; Anthropic issues demonstrate bot-actor and automated-review failure modes. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml))

**Rust practice evidence**

The workflow directories of Tokio, Axum, Serde, Clap, uv, ripgrep, Zed, and CXX were surveyed because together they cover the template’s runtime/web, library, CLI, newer tooling, and large-application use cases. No `claude` reference appeared in any surveyed workflow directory as of September 9, 2026. This is not proof that maintainers never use AI tools, but it is evidence that there is no established Rust-specific Claude Actions convention to inherit. ([github.com](https://github.com/tokio-rs/tokio/tree/master/.github/workflows))

No Rust RFC, working-group standard, or compiler/toolchain facility governs third-party AI GitHub automation. Rust ecosystem differences may therefore affect prompts and permitted commands—such as `cargo test` or `cargo clippy`—but not event, credential, cost, or bot-loop policy.

**Current source precedent clarification**

The prompt’s summary of the Python baseline is stale relative to current `main`:

- `.github/workflows/claude-code-review.yml` currently listens to `opened`, `synchronize`, `ready_for_review`, and `reopened`, and skips fork PRs, bot-authored PRs, and runs whose event sender is a bot.
- `.github/workflows/claude.yml` currently also includes `issues: assigned` and `pull_request_review: submitted`, in addition to issue comments, inline review comments, and opened issues.
- Both currently use `anthropics/claude-code-action@v1.0.175` and `CLAUDE_CODE_OAUTH_TOKEN`. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml))

**Action status and version**

`anthropics/claude-code-action` remains the maintained first-party action for both use cases. The latest concrete patch tag retrieved was **v1.0.219**, released September 8, 2026 at 23:57, at full commit **`5ccc3a35a6367cdb8e6fbd0728287467540ecfe2`**. The mutable `v1` tag pointed to the same commit. That commit bundles Claude Code **2.1.266**, Agent SDK **0.3.266**, and the current action installs Bun **1.3.14**. ([github.com](https://github.com/anthropics/claude-code-action/releases))

Release cadence is unusually high: tags v1.0.211 through v1.0.219 were published between August 31 and September 8, 2026, including two releases on both September 1 and September 8. Therefore a full-SHA pin plus automated dependency updates is preferable to `@v1` or even a movable patch tag. ([github.com](https://github.com/anthropics/claude-code-action/releases))

**Required figure applicability and evidence gap**

- crates.io 90-day downloads, all-time downloads, last crate release, reverse dependencies, RustSec advisories: **inapplicable**, because neither bundle member is a crate.
- Exact GitHub REST figures for stars, `archived`, `pushed_at`, open-issue `total_count`, and the ten-issue response-time median were not successfully captured in this run. I do not substitute GitHub’s rendered UI counts for the required REST fields. Maintenance is nevertheless unambiguously **active** from a release and commit on September 8, 2026. Popularity figures were not used to select the recommendation.
- This metric gap lowers confidence in a comparative popularity/maintainer-responsiveness ranking, but not in the trigger, authentication, version, or fork-security findings.

### Principles and implementation

**Shared requirement and agreement level**

The owner clarification requires extracting and preserving the engineering principle rather than cloning a source repository mechanically. For this item, cross-blueprint agreement is required at the **repository policy** level:

1. A generated repository must be usable without installing a proprietary GitHub App, provisioning an AI credential, or accepting metered AI spend.
2. AI-generated review must not become an implicit merge-quality guarantee or required status check.
3. Any enabled agent must be intentionally invoked, restricted to trusted actors, bounded in cost, and prevented from reviewing or triggering itself.
4. Third-party Actions must be immutable-SHA pinned.
5. Fork and bot behavior must be safe and predictable.

The **exact AI provider is not a language capability**. Python, TypeScript, and Rust have no ecosystem-specific reason to disagree about credentials, billing, bot actors, or GitHub event trust. Ecosystems may legitimately vary in prompts, allowed commands, and project instructions.

**What must agree**

- AI automation is opt-in repository policy.
- No secret-dependent automatic jobs in an untouched template.
- No `pull_request_target` checkout/execution of untrusted code.
- No bot or non-write-user invocation by default.
- Immutable Action pins.
- Automatic review and write-capable assistant permissions remain separate.

**What may vary**

- `cargo test`, `cargo clippy`, Python, or Node commands permitted to the agent.
- `CLAUDE.md` content.
- API key, Anthropic WIF, Bedrock, Vertex, or custom GitHub App authentication chosen by an adopting repository.
- Review prompt and maximum-turn budget.

GitHub withholds normal repository secrets and grants a read-only token to fork PR workflows; Dependabot PRs are treated similarly. Anthropic’s supported high-level Action adds actor checks and restores trusted project configuration, whereas its lower-level base action is not the supported path for untrusted issues, comments, or fork PRs. These constraints apply identically to Rust, Python, and TypeScript. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows))

**Architectural alternatives**

1. **Active direct-action pair.** Simple and proven by the Python blueprint, but every downstream repository inherits vendor-specific event listeners, credential setup, permissions, update burden, and potential token spend.
2. **Active mention-only workflow.** Materially safer than automatic review because invocation is explicit and the Action defaults to write-authorized users, but still installs an inactive vendor integration into every generated repository and creates workflow activity for matching GitHub events. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md))
3. **Managed GitHub App.** Removes workflow YAML and runner setup, but loses immutable source pinning and moves behavior, pricing, and update policy outside the repository. Hosted Claude Code Review also does not replace the general issue/PR assistant. ([code.claude.com](https://code.claude.com/docs/en/code-review))
4. **GitHub Agentic Workflows.** Best emerging architecture for provider-neutral, compiled, sanitized, safe-output workflows. Its command-trigger design requires the command to be the first word and defaults to write-authorized users. It currently introduces more machinery than two optional examples justify. ([github.github.com](https://github.github.com/gh-aw/reference/command-triggers/))
5. **No active workflow, maintained opt-in examples.** Preserves a zero-credential, zero-metered-cost default while giving adopters reviewed, lintable examples with an exact Action pin. **Chosen.**

The two workflows should **not be treated as an indivisible bundle** merely because they share an Action. Automatic review is implicit, high-frequency, normally read-only analysis; the assistant is explicit, lower-frequency, and write-capable. Their adoption, permissions, acceptance tests, and risk budgets differ.

**Authentication architecture**

An adopting repository needs:

- One Claude-provider authentication method: `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, Anthropic Workload Identity Federation, Bedrock, Vertex, or Foundry.
- GitHub authentication. With the official Claude GitHub App, no stored GitHub App token is required; `id-token: write` lets the Action obtain a short-lived App token. A custom GitHub App instead requires an app ID/private key and a generated token passed as `github_token`. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md?plain=1))

Anthropic WIF can remove the static Claude credential, but it requires organization-level issuer, rule, and service-account setup. That is a strong enterprise option, not a reasonable untouched-template prerequisite. ([platform.claude.com](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation))

**Conditional trigger contract if later adopted**

- **Automatic review:** `pull_request` types `opened`, `synchronize`, `reopened`, `ready_for_review`; skip drafts; same-repository PR only; both `pull_request.user.type` and `sender.type` must not be `Bot`; cancel superseded runs for the same PR.
- **Mention assistant:** only `issue_comment: created`, `pull_request_review_comment: created`, and `issues: opened`; require `@claude` in the applicable comment or issue body; omit `pull_request_review`, `assigned`, `labeled`, `edited`, and issue-title triggers.
- Leave `allowed_bots` and `allowed_non_write_users` unset. The Action then rejects bot actors and users without write access. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/action.yml))

The automatic guard needs **no Rust-specific adjustment**. GitHub actor types and event senders are platform metadata. If adopted, port the Python guard’s same-repo plus author/sender checks unchanged; adding draft and concurrency checks is generic cost/noise control, not Rust adaptation. GitHub App bot accounts normally report `type: Bot`, covering Dependabot, Renovate, release apps, and Claude itself. ([github.com](https://github.com/anthropics/claude-code-action/discussions/493))

**Permissions if later adopted**

- Automatic review using the official Claude App: `contents: read`, `pull-requests: read`, `issues: read`, `id-token: write`.
- Mention assistant: `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write`; add `actions: read` and `additional_permissions: actions: read` only when reading CI results is an intended capability. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml))

**Performance and cost**

No comparable, workload-controlled benchmark was found for Claude Action versus Codex, Gemini, CodeRabbit, or `gh-aw`, so no candidate is selected as “fastest.” The relevant workload is event frequency:

- Automatic review scales with qualifying PR opens and updates.
- Mention assistance scales with explicit maintainer invocations.

Instrumentation should use GitHub run duration/queue time, Anthropic Console token and spend reporting, failure rate, comment count, and false-positive/accepted-finding counts. Anthropic documents token-based costs and workspace spend/rate limits, but not a representative per-PR price. The Action currently installs a roughly 35 MB Bun executable; total model latency and token cost dominate and depend on repository context and model choice. ([code.claude.com](https://code.claude.com/docs/en/costs))

**Observable acceptance criteria**

1. `.github/workflows/claude-code-review.yml` is absent.
2. `.github/workflows/claude.yml` is absent.
3. No active workflow references `anthropics/claude-code-action`, `ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN`.
4. Optional examples, if included, live outside `.github/workflows`, lint successfully, and pin `5ccc3a35a6367cdb8e6fbd0728287467540ecfe2`.
5. Documentation explicitly states that users must install/configure the App and provider authentication themselves.
6. The optional review and assistant examples remain independently copyable.
7. No AI check is named as a required branch-protection check.

**Baseline challenges**

BASELINE-REVIEW: F051 — credential-free and non-metered template defaults — do not port the active automatic Claude PR-review workflow; retain it only as an opt-in example and treat removal from py as a follow-on project — automatic runs consume provider capacity, fork and Dependabot events have restricted credentials, and the Rust practice survey found no ecosystem convention requiring it. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows))

BASELINE-REVIEW: F052 — AI ChatOps is repository-operator policy rather than a language capability — do not port an active `@claude` workflow; document it as a separately adoptable example and split its ledger decision from F051 — it has different triggers, write permissions, cost frequency, and actor controls from automatic review. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml))

**Execution status:** source research was performed; no repository checkout, workflow lint, credentialed Action run, or empirical sandbox invocation was executed. All acceptance commands below are proposed.

### Recommendation

**Stack: “GitHub-native, AI-opt-in.”**

- **Active workflow decision:** ship **neither** AI workflow in `.github/workflows`.
- **Bundle decision:** F051 and F052 are independent policy decisions, not an indivisible bundle. The current answer happens to reject both as active template defaults.
- **Documented optional implementation:** `anthropics/claude-code-action` **v1.0.219**, pinned to **`5ccc3a35a6367cdb8e6fbd0728287467540ecfe2`**, using the supported high-level Action—not `claude-code-base-action`.
- **Reference transitive stack:** Claude Code **2.1.266**, Agent SDK **0.3.266**, Bun **1.3.14**.
- **Preferred adoption order if an owner later authorizes AI:** mention assistant first; automatic review only after a measured pilot establishes cost, signal quality, and branch-protection behavior.

### Members

#### Automatic PR code-review workflow

##### Landscape

The viable architectures are direct Action automation, Anthropic’s hosted Code Review, managed apps such as CodeRabbit, provider-neutral `gh-aw`, and direct Codex/Gemini workflows. The Anthropic Action is the closest implementation match to Python; hosted review and managed apps alter the operational model; `gh-aw` is the strongest emerging architecture. ([code.claude.com](https://code.claude.com/docs/en/code-review))

##### Principles and implementation

Automatic review is an implicit, metered repository policy. It must not masquerade as a deterministic correctness gate, run against superseded commits, consume secrets on untrusted fork contexts, or enter bot review loops.

If adopted later, the behavior should be:

- `pull_request: [opened, synchronize, reopened, ready_for_review]`
- same-repository PR only
- `draft == false`
- PR author and event sender both non-bot
- per-PR concurrency with `cancel-in-progress: true`
- informative `COMMENT` behavior, never automatic approval or required-change status by default
- read-only repository tools unless an owner separately authorizes test execution.

##### Dominant choice

For a source-controlled Claude implementation, **`anthropics/claude-code-action` v1.0.219 at the full SHA** is the dominant choice. It is first-party, GA, supports automation mode when `prompt` is supplied, and is actively released. ([github.com](https://github.com/anthropics/claude-code-action/releases))

##### Qualified shortlist

1. `anthropics/claude-code-action`—best direct fit.
2. Anthropic hosted Claude Code Review—qualified for review only, not the whole bundle.
3. GitHub Agentic Workflows with Claude engine—better provider abstraction and safe outputs, higher integration cost.
4. CodeRabbit—mature managed review behavior, but not source-versioned as an Action.
5. OpenAI Codex Action—strong sandbox/security design, but changes provider and configuration surface.
6. Gemini CLI Action—capable, but maintained examples remain on `@v0`. ([github.github.com](https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/))

##### Excluded by gate

- **Excluded from the active template:** direct automatic review, because it fails the template-specific zero-credential/zero-metered-cost default gate—not because the Action itself is technically unfit.
- **Excluded:** `pull_request_target` plus checkout or execution of PR code. GitHub classifies this as an elevated-trust “pwn request” shape. ([docs.github.com](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target))
- **Excluded:** floating `@main`, `@v1`, or movable patch tags; GitHub recommends full-SHA pins.
- **Excluded:** the lower-level `claude-code-base-action` for untrusted event content.
- **Excluded:** all-bot or all-non-write-user allowlists.

Fitness gates:

1. **License:** pass for the direct Action; its source license is compatible, and no code is linked into the Rust deliverable.
2. **MSRV:** inapplicable; no Cargo dependency.
3. **RustSec/`unsafe`:** inapplicable; workflow security replaces Rust memory-safety analysis.
4. **OS:** no Rust target coupling. A review job must run once, normally on Ubuntu, rather than once per application OS and duplicate comments/cost.
5. **Features/runtime:** inapplicable; no Cargo features or async runtime.
6. **Compile/binary cost:** no Rust cost; additional runner setup, model latency, and API usage only.

##### Up-and-comers

`gh-aw` is the principal up-and-comer. Its review pattern keeps the model read-only and validates comments through safe outputs, including limits on summary and inline comments. Reconsider it after a stable release and evidence that its compiler/lockfile maintenance is acceptable for blueprint consumers. ([github.github.com](https://github.github.com/gh-aw/gallery/automated-pr-review/))

##### Fit for this template

The CLI/library/web shape does not justify different event or bot logic. Rust-specific instructions may ask the reviewer to consider Cargo features, `Send`/`Sync`, MSRV, clippy, error handling, and async cancellation, but the workflow architecture is language-neutral.

A default paths filter is not recommended: meaningful changes can occur in `Cargo.toml`, feature configuration, migrations, web-service routing, CLI snapshots, documentation, and workflows. Downstream repositories can add filters after observing their change patterns.

##### Recommendation

**Do not create `.github/workflows/claude-code-review.yml`.**

Preserve a lintable, reference-only example outside `.github/workflows` if the blueprint’s documentation policy permits optional vendor recipes.

##### Ranked runner-up

If the owner explicitly requires automatic review:

```yaml
uses: anthropics/claude-code-action@5ccc3a35a6367cdb8e6fbd0728287467540ecfe2 # v1.0.219
```

Use:

- triggers `opened`, `synchronize`, `reopened`, `ready_for_review`;
- guard:
  `head.repo.full_name == repository`
  and `draft == false`
  and `pull_request.user.type != 'Bot'`
  and `sender.type != 'Bot'`;
- `contents: read`, `pull-requests: read`, `issues: read`, `id-token: write`;
- one per-PR concurrency group with cancellation;
- explicit review prompt and bounded turns;
- official Claude GitHub App with provider API key or WIF;
- no `allowed_bots`.

The Python guard itself ports unchanged; draft/concurrency additions are generic refinements. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml))

##### Tradeoffs

Omission loses unsolicited AI feedback and may increase human review effort. It avoids automatic token spending, repeated reviews on every push, false confidence, bot loops, credential setup failures, and a rapidly changing Action dependency in every generated repository.

The optional example preserves discoverability without making that tradeoff on behalf of every consumer.

##### Parameters

- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- `assumes license = MIT OR Apache-2.0`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- No parameter conflict: this workflow would not affect the Rust dependency graph, MSRV, license expression, or application CI matrix.

##### Migration implications

- Keep `.github/workflows/claude-code-review.yml` absent.
- Optionally add `docs/examples/github-actions/claude-code-review.yml`.
- Explain authentication, cost, fork limitations, pin updates, and non-required-check status in `docs/recipes/claude-code-actions.md`.
- Record F051 as an active-default rejection, not as evidence that the Action is unusable.
- Any Python workflow removal is a follow-on project, not part of R18 implementation.

##### Validation strategy

Planned static checks:

```bash
test ! -e .github/workflows/claude-code-review.yml
! git grep -n 'anthropics/claude-code-action' -- .github/workflows

actionlint docs/examples/github-actions/claude-code-review.yml
grep -F '5ccc3a35a6367cdb8e6fbd0728287467540ecfe2' \
  docs/examples/github-actions/claude-code-review.yml
! grep -E 'pull_request_target|anthropics/claude-code-action@(main|v1)$' \
  docs/examples/github-actions/claude-code-review.yml
```

Planned sandbox acceptance if copied into an intentionally configured repository:

- human same-repo, non-draft PR open → exactly one review;
- second push before completion → prior run cancelled;
- draft PR → skipped;
- `ready_for_review` → runs;
- fork PR → skipped;
- Dependabot/release/Claude-authored PR → skipped;
- bot synchronization of a human PR → skipped;
- no review is submitted as `APPROVE` or made a required check.

##### Confidence & re-verify trigger

**Confidence: high (0.90)** in omission as the generic-template default; **medium-high (0.84)** in the proposed opt-in configuration.

Re-verify if:

- the owner explicitly requires automatic AI review as a shared capability;
- `claude-code-action` releases v2;
- hosted review gains source-pinned configuration and assistant parity;
- `gh-aw` reaches stable release and becomes a common Rust practice;
- public-template-specific cost or quality evidence becomes available.

##### Sources

- `https://github.com/anthropics/claude-code-action/releases` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/releases))
- `https://github.com/anthropics/claude-code-action/commit/5ccc3a35a6367cdb8e6fbd0728287467540ecfe2` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/commit/5ccc3a35a6367cdb8e6fbd0728287467540ecfe2))
- `https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml` — retrieved 2026-09-09. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml))
- `https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target` — retrieved 2026-09-09. ([docs.github.com](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target))
- `https://github.github.com/gh-aw/gallery/automated-pr-review/` — retrieved 2026-09-09. ([github.github.com](https://github.github.com/gh-aw/gallery/automated-pr-review/))

#### @mention-triggered assistant workflow

##### Landscape

Candidates include the direct Claude Action, `gh-aw` ChatOps commands, Gemini’s `@gemini-cli`, Codex mentions/cloud tasks, and managed PR assistants. The direct Claude Action best matches the requested `@claude` behavior; `gh-aw` offers a stronger provider-neutral command abstraction. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml))

##### Principles and implementation

This member is safer than automatic review because invocation is explicit, but it is also more privileged: it may edit code, push commits, update issues, and inspect CI. Therefore it requires:

- explicit trigger text;
- trusted human actor;
- no bots or non-write users by default;
- fork-PR preflight and skip behavior;
- bounded turns and timeout;
- write permissions only when code-changing assistance is part of the declared capability;
- per-repository provider and GitHub App setup.

##### Dominant choice

`anthropics/claude-code-action` remains the dominant direct implementation. Omitting `prompt` selects interactive mention behavior; the default trigger phrase is `@claude`. The Action performs write-permission checks, defaults to no allowed bots, and can use the official App without a custom stored GitHub token. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/experimental.md))

##### Qualified shortlist

1. Direct Claude Action—best semantic match.
2. `gh-aw` slash-command workflow with Claude engine—best provider-neutral architecture.
3. Gemini CLI Action—supports conversational mentions and similar repository tasks.
4. OpenAI Codex Action/cloud mention integration—maintained but different provider and trigger identity.
5. CodeRabbit—qualified for PR conversations, less suitable as a general issue implementation assistant. ([github.github.com](https://github.github.com/gh-aw/patterns/chatops/))

##### Excluded by gate

- **Excluded from active template:** the otherwise-qualified mention workflow, because activation requires a repository-specific App/provider decision.
- **Excluded:** `issues: assigned` and `issues: labeled`; they are not `@mention` semantics.
- **Excluded:** `pull_request_review: submitted`; it adds a fourth content surface not requested and makes quoted mentions in review summaries capable of triggering work.
- **Excluded:** `issues: edited`; an existing mention would re-trigger on unrelated edits.
- **Excluded:** issue-title matching; only issue bodies are in scope.
- **Excluded:** `allowed_bots: '*'` and `allowed_non_write_users: '*'`; the Action explicitly warns about public-repository exposure for broad bot access. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/action.yml))

Fitness gates:

1. **License:** pass for the direct Action.
2. **MSRV:** inapplicable; no crate.
3. **RustSec/`unsafe`:** inapplicable; actor trust, prompt injection, credentials, and write scopes are the applicable security posture.
4. **OS:** application target matrix unaffected; the assistant runs once on Ubuntu to avoid duplicate actions/comments.
5. **Features/runtime:** inapplicable.
6. **Compile/binary cost:** no Rust cost; runner and provider usage only.

##### Up-and-comers

`gh-aw` command triggers are particularly relevant. They can restrict commands to issue comments or PR comments, require the command as the first word, sanitize context, default to write-authorized actors, and route writes through safe outputs. It is the leading future replacement if the owner wants a vendor-neutral policy rather than a Claude-specific recipe. ([github.github.com](https://github.github.com/gh-aw/reference/command-triggers/))

##### Fit for this template

The recommended optional event set is exactly:

```yaml
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened]
```

Job filtering should require:

- `@claude` in `comment.body` for `issue_comment`;
- `@claude` in `comment.body` for `pull_request_review_comment`;
- `@claude` in `issue.body` for `issues`;
- `sender.type != 'Bot'`;
- a trusted association prefilter where practicable;
- Action-level write-access verification;
- a same-repository check before operating on a PR.

This cleanly covers issue/PR conversation comments, inline review comments, and newly opened issue bodies. A mention later added to an issue should be sent as a new comment instead of editing the body. GitHub defines `issue_comment` as the event for both issue and PR conversation comments and uses `pull_request_review_comment` for inline diff comments. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows))

##### Recommendation

**Do not create `.github/workflows/claude.yml`.**

Supply an independently copyable example outside the active workflow directory.

##### Ranked runner-up

If the owner authorizes one active AI workflow, choose this member before automatic review:

```yaml
uses: anthropics/claude-code-action@5ccc3a35a6367cdb8e6fbd0728287467540ecfe2 # v1.0.219
```

Configuration:

- exactly the three event types above;
- no fixed `prompt`, preserving interactive mode;
- `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write`;
- optional `actions: read` plus `additional_permissions: actions: read`;
- `ANTHROPIC_API_KEY` for the broadest simple setup, or Anthropic WIF for an organization-managed setup;
- official Claude GitHub App; do not pass `github_token` unless using a custom App;
- leave `allowed_bots` and `allowed_non_write_users` empty;
- `--max-turns 10` and a finite job timeout;
- skip fork PR contexts before invoking the model.

##### Tradeoffs

Omission sacrifices convenient issue-to-code and PR-fix assistance. It avoids choosing a paid provider for every consumer, write-capable automation in an untouched public template, credential failures, mention-trigger surprises, and Action update churn.

A documented example provides almost all setup convenience because users must visit repository settings and install/configure credentials regardless.

##### Parameters

- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- `assumes license = MIT OR Apache-2.0`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- No conflict. Rust commands must remain compatible with the declared MSRV if an adopter later allowlists them.

##### Migration implications

- Keep `.github/workflows/claude.yml` absent.
- Add an optional `docs/examples/github-actions/claude.yml`.
- Document the three trigger surfaces and explicitly document excluded surfaces.
- Document activation order: install App/authentication, review permissions, then copy the example.
- Record F052 separately from F051.
- Do not change Python or TypeScript in this R18 implementation.

##### Validation strategy

Planned static checks:

```bash
test ! -e .github/workflows/claude.yml
! git grep -n 'ANTHROPIC_API_KEY\|CLAUDE_CODE_OAUTH_TOKEN' -- .github/workflows

actionlint docs/examples/github-actions/claude.yml
grep -F '5ccc3a35a6367cdb8e6fbd0728287467540ecfe2' \
  docs/examples/github-actions/claude.yml
```

Planned structural checks with `yq`:

```bash
yq -e '.on.issue_comment.types == ["created"]' \
  docs/examples/github-actions/claude.yml
yq -e '.on.pull_request_review_comment.types == ["created"]' \
  docs/examples/github-actions/claude.yml
yq -e '.on.issues.types == ["opened"]' \
  docs/examples/github-actions/claude.yml
```

Planned sandbox behavior:

| Event | Expected |
|---|---|
| Maintainer issue comment containing `@claude` | One assistant run |
| Maintainer PR conversation comment containing `@claude` | One assistant run |
| Maintainer inline review comment containing `@claude` | One assistant run |
| New issue body containing `@claude` from authorized maintainer | One assistant run |
| Formal PR review body containing `@claude` | No run |
| Issue title only containing `@claude` | No run |
| Edited issue body | No run |
| Comment without mention | No run |
| Bot comment | No run |
| Non-write external user | No model invocation |
| Fork PR context | Skipped before provider invocation |

##### Confidence & re-verify trigger

**Confidence: high (0.88)** that it should remain inactive by default; **high (0.91)** in the three-event optional contract.

Re-verify if:

- the owner declares AI ChatOps a mandatory shared capability;
- Anthropic changes the default write-user check;
- GitHub changes fork-secret or OIDC rules;
- `gh-aw` becomes stable and widely adopted;
- the Action changes trigger detection in v2.

##### Sources

- `https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml))
- `https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md))
- `https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md?plain=1))
- `https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml` — retrieved 2026-09-09. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml))
- `https://github.github.com/gh-aw/reference/command-triggers/` — retrieved 2026-09-09. ([github.github.com](https://github.github.com/gh-aw/reference/command-triggers/))

### Compatibility

There is no active member-to-member runtime compatibility requirement because both workflows are omitted.

The optional pair is demonstrably from one supported family:

| Component | Reference version |
|---|---|
| `anthropics/claude-code-action` | v1.0.219 |
| Immutable Action commit | `5ccc3a35a6367cdb8e6fbd0728287467540ecfe2` |
| Bundled Claude Code | 2.1.266 |
| Bundled Agent SDK | 0.3.266 |
| Action-installed Bun | 1.3.14 |

The v1 Action automatically selects automation mode when a prompt is supplied and interactive mode when a mention-triggered event has no prompt. Anthropic maintains examples for both. The Python blueprint is a shared adopter of both workflows on the same earlier pin, v1.0.175, proving family-level composition, although the exact v1.0.219 pair was not executed during this research. ([github.com](https://github.com/anthropics/claude-code-action/releases))

No member links into the Rust binary or library, so edition 2024, MSRV, async runtime, Ubuntu application tests, and macOS application tests remain independent.

### Parameters

`owns ai-assisted-workflow-default = neither-active-workflow`

`owns automatic-ai-pr-review = absent`

`owns mention-triggered-ai-assistant = absent`

`owns ai-workflow-bundling = independent-decisions`

`owns claude-code-action-reference-version = v1.0.219`

`owns claude-code-action-reference-sha = 5ccc3a35a6367cdb8e6fbd0728287467540ecfe2`

`owns optional-auto-review-triggers = opened, synchronize, reopened, ready_for_review`

`owns optional-mention-triggers = issue_comment.created, pull_request_review_comment.created, issues.opened`

`owns automatic-review-bot-guard = same-repo AND non-draft AND pull_request.user.type != Bot AND sender.type != Bot`

`owns mention-bot-guard = sender.type != Bot AND allowed_bots empty AND allowed_non_write_users empty`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No `CONFLICT:` lines.

### Migration implications

1. **Do not add**
   - `.github/workflows/claude-code-review.yml`
   - `.github/workflows/claude.yml`

2. **Add optional, non-executable examples**
   - `docs/examples/github-actions/claude-code-review.yml`
   - `docs/examples/github-actions/claude.yml`
   - Both full-SHA pinned and individually lintable.

3. **Add documentation**
   - `docs/recipes/claude-code-actions.md`
   - Explain current version, activation, credentials, GitHub App installation, WIF option, trigger scope, bot/fork restrictions, permissions, cost controls, and how to remove the integration.

4. **Update the Rust port decision record**
   - Record R18 as “neither active.”
   - Record that F051 and F052 are semantically independent.
   - Include both `BASELINE-REVIEW` findings.
   - Do not silently rewrite Python or TypeScript classifications.

5. **No Rust project changes**
   - No `Cargo.toml`, workspace, feature, MSRV, source, test, or OS-matrix changes.

6. **Follow-on rationale**
   - Python: reconsider active workflows and the outdated v1.0.175 pin in a separate project.
   - TypeScript: no active-file change; optionally gain the same documented recipe in a separate project.

### Validation strategy

**Executed during research:** documentation/source inspection only.

**Planned implementation checks:**

```bash
set -euo pipefail

test ! -e .github/workflows/claude-code-review.yml
test ! -e .github/workflows/claude.yml

if git grep -n \
  'anthropics/claude-code-action\|ANTHROPIC_API_KEY\|CLAUDE_CODE_OAUTH_TOKEN' \
  -- .github/workflows; then
  echo "Active AI workflow dependency found" >&2
  exit 1
fi

actionlint docs/examples/github-actions/claude-code-review.yml
actionlint docs/examples/github-actions/claude.yml

git grep -F \
  'anthropics/claude-code-action@5ccc3a35a6367cdb8e6fbd0728287467540ecfe2' \
  -- docs/examples/github-actions
```

Check that examples do not use unsafe or floating references:

```bash
! grep -R -E \
  'pull_request_target|anthropics/claude-code-action@(main|v1|v1\.0\.219)$' \
  docs/examples/github-actions
```

Check the optional trigger contracts:

```bash
yq -e \
  '.on.pull_request.types ==
   ["opened", "synchronize", "reopened", "ready_for_review"]' \
  docs/examples/github-actions/claude-code-review.yml

yq -e '.on.issue_comment.types == ["created"]' \
  docs/examples/github-actions/claude.yml
yq -e '.on.pull_request_review_comment.types == ["created"]' \
  docs/examples/github-actions/claude.yml
yq -e '.on.issues.types == ["opened"]' \
  docs/examples/github-actions/claude.yml
```

Check ledger consistency:

```bash
git grep -n 'BASELINE-REVIEW: F051' docs
git grep -n 'BASELINE-REVIEW: F052' docs
git grep -n 'R18' docs/port docs 2>/dev/null
```

**Empirical acceptance, if an owner activates the examples:** copy each into an isolated public sandbox repository, configure a low-budget Anthropic workspace, install the Claude App, and execute the event matrices stated under each member. Capture:

- GitHub run URL and duration;
- action conclusion;
- whether a Claude API call occurred;
- token/cost record;
- actor and PR-origin classification;
- comment/review count;
- whether superseded review runs were cancelled;
- whether any bot/fork/non-write event reached the model.

The exact v1.0.219 pair should not be called “tested together” until that sandbox check passes.

### Confidence & re-verify trigger

**Overall confidence: 0.89.**

High-confidence findings:

- The maintained family remains `anthropics/claude-code-action`.
- The current concrete patch is v1.0.219 at the stated full SHA.
- The bot guard is GitHub-platform logic and needs no Rust-specific adjustment.
- The three requested mention event types can be scoped cleanly.
- Provider credentials and per-repository GitHub authentication are required.
- Fork and Dependabot credential restrictions make active defaults unsuitable for a generic public template.

Lower-confidence area:

- Exact GitHub API popularity and ten-issue responsiveness figures were not captured and were therefore not used.

Re-verify immediately before implementation because of the near-daily release cadence, and re-open R18 if any of these occurs:

1. a v2 Action release;
2. a security advisory or maintainer deprecation;
3. a GitHub fork/OIDC permission change;
4. `gh-aw` stable release and mainstream adoption;
5. an explicit owner requirement for AI automation by default;
6. credible public-template-specific cost/false-trigger evidence;
7. reconciliation work begins for Python and TypeScript.

### Sources

**Owner-supplied sources**

- R18 prompt, spec §2/A5, owner clarification dated September 4, 2026.
- `docs/port/COMMONALITY.md`, F051/F052—no public URL supplied.
- `docs/port/PARAMETERS.md`—no public URL supplied.

**Anthropic**

- `https://github.com/anthropics/claude-code-action/releases` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/releases))
- `https://github.com/anthropics/claude-code-action/releases/tag/v1.0.219` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/releases/tag/v1.0.219))
- `https://github.com/anthropics/claude-code-action/commit/5ccc3a35a6367cdb8e6fbd0728287467540ecfe2` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/commit/5ccc3a35a6367cdb8e6fbd0728287467540ecfe2))
- `https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md))
- `https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md?plain=1))
- `https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md))
- `https://github.com/anthropics/claude-code-action/blob/main/action.yml` — retrieved 2026-09-09. ([github.com](https://github.com/anthropics/claude-code-action/blob/main/action.yml))
- `https://code.claude.com/docs/en/github-actions` — retrieved 2026-09-09. ([code.claude.com](https://code.claude.com/docs/en/github-actions?asuniq=7b2efe36))
- `https://code.claude.com/docs/en/costs` — retrieved 2026-09-09. ([code.claude.com](https://code.claude.com/docs/en/costs))
- `https://platform.claude.com/docs/en/manage-claude/workload-identity-federation` — retrieved 2026-09-09. ([platform.claude.com](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation))
- `https://code.claude.com/docs/en/code-review` — retrieved 2026-09-09. ([code.claude.com](https://code.claude.com/docs/en/code-review))

**GitHub security and event semantics**

- `https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows` — retrieved 2026-09-09. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows))
- `https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions` — retrieved 2026-09-09. ([docs.github.com](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions))
- `https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target` — retrieved 2026-09-09. ([docs.github.com](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target))
- `https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats` — retrieved 2026-09-09. ([docs.github.com](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats))
- `https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions` — retrieved 2026-09-09. ([docs.github.com](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions))

**Alternatives**

- `https://github.github.com/gh-aw/introduction/overview/` — retrieved 2026-09-09. ([github.github.com](https://github.github.com/gh-aw/introduction/overview/))
- `https://github.github.com/gh-aw/reference/command-triggers/` — retrieved 2026-09-09. ([github.github.com](https://github.github.com/gh-aw/reference/command-triggers/))
- `https://github.github.com/gh-aw/gallery/automated-pr-review/` — retrieved 2026-09-09. ([github.github.com](https://github.github.com/gh-aw/gallery/automated-pr-review/))
- `https://github.com/google-github-actions/run-gemini-cli` — retrieved 2026-09-09. ([github.com](https://github.com/google-github-actions/run-gemini-cli))
- `https://github.com/openai/codex-action/blob/main/docs/security.md` — retrieved 2026-09-09. ([github.com](https://github.com/openai/codex-action/blob/main/docs/security.md))
- `https://docs.coderabbit.ai/configuration/auto-review` — retrieved 2026-09-09. ([docs.coderabbit.ai](https://docs.coderabbit.ai/configuration/auto-review))

**Source implementations and practice**

- `https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml` — retrieved 2026-09-09. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml))
- `https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml` — retrieved 2026-09-09. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml))
- `https://github.com/semgrep/skills/blob/main/.github/workflows/claude-code-review.yml` — retrieved 2026-09-09. ([github.com](https://github.com/semgrep/skills/blob/main/.github/workflows/claude-code-review.yml))

**Required metric endpoints requiring re-verification**

- `GET https://api.github.com/repos/anthropics/claude-code-action`
- `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open`
- Ten newest issues from the corresponding GitHub Issues API, followed by first-maintainer-response calculation.

Exact responses from those REST endpoints were not captured; no substitute values were used in the recommendation.

## Sources

- [https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [https://github.com/anthropics/claude-code-action/releases](https://github.com/anthropics/claude-code-action/releases)
- [https://github.github.com/gh-aw/gallery/automated-pr-review/](https://github.github.com/gh-aw/gallery/automated-pr-review/)
- [https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md](https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md)
- [https://github.com/google-github-actions/run-gemini-cli/blob/main/README.md](https://github.com/google-github-actions/run-gemini-cli/blob/main/README.md)
- [https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude-code-review.yml)
- [https://github.com/tokio-rs/tokio/tree/master/.github/workflows](https://github.com/tokio-rs/tokio/tree/master/.github/workflows)
- [https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md](https://github.com/anthropics/claude-code-action/blob/main/docs/faq.md)
- [https://code.claude.com/docs/en/code-review](https://code.claude.com/docs/en/code-review)
- [https://github.github.com/gh-aw/reference/command-triggers/](https://github.github.com/gh-aw/reference/command-triggers/)
- [https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md?plain=1](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md?plain=1)
- [https://platform.claude.com/docs/en/manage-claude/workload-identity-federation](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation)
- [https://github.com/anthropics/claude-code-action/blob/main/action.yml](https://github.com/anthropics/claude-code-action/blob/main/action.yml)
- [https://github.com/anthropics/claude-code-action/discussions/493](https://github.com/anthropics/claude-code-action/discussions/493)
- [https://code.claude.com/docs/en/costs](https://code.claude.com/docs/en/costs)
- [https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml](https://github.com/smorinlabs/py-launch-blueprint/blob/main/.github/workflows/claude.yml)
- [https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/](https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/)
- [https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
- [https://github.com/anthropics/claude-code-action/commit/5ccc3a35a6367cdb8e6fbd0728287467540ecfe2](https://github.com/anthropics/claude-code-action/commit/5ccc3a35a6367cdb8e6fbd0728287467540ecfe2)
- [https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml)
- [https://github.com/anthropics/claude-code-action/blob/main/docs/experimental.md](https://github.com/anthropics/claude-code-action/blob/main/docs/experimental.md)
- [https://github.github.com/gh-aw/patterns/chatops/](https://github.github.com/gh-aw/patterns/chatops/)
- [https://github.com/anthropics/claude-code-action/releases/tag/v1.0.219](https://github.com/anthropics/claude-code-action/releases/tag/v1.0.219)
- [https://code.claude.com/docs/en/github-actions?asuniq=7b2efe36](https://code.claude.com/docs/en/github-actions?asuniq=7b2efe36)
- [https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions)
- [https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats)
- [https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions)
- [https://github.github.com/gh-aw/introduction/overview/](https://github.github.com/gh-aw/introduction/overview/)
- [https://github.com/google-github-actions/run-gemini-cli](https://github.com/google-github-actions/run-gemini-cli)
- [https://github.com/openai/codex-action/blob/main/docs/security.md](https://github.com/openai/codex-action/blob/main/docs/security.md)
- [https://docs.coderabbit.ai/configuration/auto-review](https://docs.coderabbit.ai/configuration/auto-review)
- [https://github.com/semgrep/skills/blob/main/.github/workflows/claude-code-review.yml](https://github.com/semgrep/skills/blob/main/.github/workflows/claude-code-review.yml)
