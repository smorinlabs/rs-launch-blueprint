### Landscape

This bundle decides **optional AI assistance in GitHub Actions**, not a Rust crate. The map is: (1) built-in or first-party toolchain: GitHub Actions event filters, job `if:` expressions, `GITHUB_TOKEN` permissions, and OIDC; (2) established industry standard: a repository-installed, vendor-operated coding agent invoked from a review or comment workflow; and (3) up-and-comer: `anthropics/claude-code-action`, an Anthropic-maintained action that supplies both automatic PR-review and `@claude` interaction modes. The action is cross-language; Rust supplies the reviewed repository rather than a competing action implementation. GitHub's event documentation is authoritative for trigger semantics and fork-secret behavior because GitHub operates the workflow platform; Anthropic's action repository and documentation are authoritative for its inputs, access-control behavior, authentication modes, and examples because Anthropic maintains the action. Retrieved 2026-09-06: <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>; <https://github.com/anthropics/claude-code-action>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>.

Practice survey: the action repository itself is a maintained reference implementation for both modes: `examples/pr-review-comprehensive.yml` uses `pull_request`, and `examples/claude.yml` uses issue comments, review comments, reviews, and issues. The maintained action repository has 8,801 stars, is not archived, and was pushed at 2026-09-06T02:56:54Z; its ten most recent releases span 2026-08-28 through 2026-09-06, including `v1.0.217`. These are adoption and maintenance signals, not fitness proof. Endpoint retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action>; <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/pr-review-comprehensive.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>.

No well-regarded Rust project was used as a precedent: the prompt expressly excludes the owner's Rust repositories, and no independent, maintained Rust-template adopter was verified in this run. That is an evidence gap, not evidence that Rust needs a different workflow. The relevant existing practice is language-neutral: the pinned py source has both workflows, while the pinned ts source has neither. Retrieved 2026-09-06: <https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/claude-code-review.yml>; <https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/claude.yml>; <https://github.com/smorinlabs/ts-launch-blueprint/tree/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/workflows>.

### Principles and implementation

The shared requirement is **useful review and maintainer-directed assistance must not create an unauthenticated, privileged, paid, or surprise-enabled path in a public template**. The agreement level is policy and observable capability, not the presence of a vendor-specific YAML file: py demonstrates the capability; ts demonstrates that a production template can intentionally omit it. The mandatory behaviors are: no static secret in version control, no secret-dependent run on a fork, least GitHub permissions, no bot-trigger loop, explicit maintainer authorization for a request that can write, and a reproducible action version. GitHub requires that fork PRs do not receive ordinary secrets and that their `GITHUB_TOKEN` is read-only; it also recommends minimum job permissions. Retrieved 2026-09-06: <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>; <https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication>.

The architectural alternatives are: ship both workflows enabled, ship only automatic review, ship only `@mention` assistance, or ship neither and document an opt-in integration. Enabled automatic review is read-oriented but still spends provider capacity on every eligible internal PR; enabled mention assistance is more capable but requires `contents`, `issues`, and `pull-requests` write permissions and processes user-controlled text. Neither capability depends on Rust edition, MSRV, runtime, unsafe code, or operating system, so no Rust-specific adjustment justifies inheriting py unchanged. Anthropic documents that the high-level `claude-code-action`, unlike the lower-level `claude-code-base-action`, performs actor-access checks and restores selected Claude configuration from the base ref. It therefore remains the maintained action family for both modes, rather than being replaced by the base action. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/action.yml>.

The appropriate template architecture is an absent-by-default integration plus a documented, two-workflow opt-in recipe. If a downstream repository enables it, keep the workflows separate because their triggers, costs, and permissions differ: automatic review uses `pull_request` and read-oriented permissions plus `id-token: write`; mention handling uses only `created` comments, submitted reviews, and opened issues whose supported field contains the trigger phrase, with writes only if the downstream consciously enables code-changing assistance. The upstream example scopes `issue_comment`, `pull_request_review_comment`, `pull_request_review`, and `issues` with an `@claude` condition; GitHub documents that `issue_comment` covers issue and PR timeline comments, while review events cover their separate surfaces. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>; <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>.

For a future automatic-review opt-in, port py's same-repository and dual bot guard unchanged: `head.repo.full_name == repository`, PR author is not `Bot`, and event sender is not `Bot`. It is language-neutral and prevents unavailable fork credentials and a bot `synchronize` event from leaving a false-red run. Do not enable `allowed_bots` or `allowed_non_write_users`; Anthropic states that an explicit bot allowlist is safer than `*`, and that bypassing write-access checks is risky on public repositories. Retrieved 2026-09-06: <https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/claude-code-review.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

Authentication is a deployment prerequisite, not template content. The action supports `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, and GitHub OIDC-to-Anthropic workload identity federation (WIF); WIF avoids a stored Anthropic credential but needs Anthropic organization setup and `id-token: write`. The official Claude GitHub App or a custom GitHub App supplies repository authority; a GitHub App token is distinct from the provider credential. A downstream public fork must install/configure these resources itself, and neither workflow can be assumed functional before that setup. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>.

BASELINE-REVIEW: F051/F052 — optional AI assistance must not impose a paid credential, privileged GitHub App, or provider run on every public-template consumer — change the baseline from enabled py-derived workflows to an absent-by-default, documented opt-in pair — Anthropic requires provider authentication and repository authority, while GitHub withholds ordinary secrets from fork PRs; retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>; <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>.

Minimal realistic example (proposed, not run): an edition-2024 CLI/library/web-service fixture has an internal PR changing its HTTP handler and an authorized maintainer comment containing `@claude`. A configured downstream installation receives one review on the internal PR, ignores a Dependabot PR and a bot-sent synchronization, and responds only to the authorized mention. The acceptance check is described under `Validation strategy`; no provider credentials or target repository were supplied, so no paid or privileged workflow execution occurred in this run.

### Recommendation

Ship neither `.github/workflows/claude-code-review.yml` nor `.github/workflows/claude.yml` in `rs-launch-blueprint` by default. Publish one concise opt-in guide that describes the two independent workflows, requires a downstream owner to configure WIF or a secret and the GitHub App, and uses `anthropics/claude-code-action@v1.0.217` as the verified release at enablement time. `v1.0.217` was the newest non-prerelease release on 2026-09-06; its fast cadence means re-verify the release and security documentation immediately before use. R20, not R18, owns whether the eventual reference is a full commit SHA or a version tag. Retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

### Members

#### Automatic PR code review

##### Landscape

This member is a GitHub Actions `pull_request` review workflow, not a Rust crate. Built-in components are the `pull_request` event, job condition, OIDC, and permission declaration; the up-and-comer action is `anthropics/claude-code-action`. The maintained comprehensive-review example uses this event and the same action. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/pr-review-comprehensive.yml>.

##### Principles and implementation

Automated feedback may be offered only when the repository can authenticate safely and the run cannot recurse through automation. The upstream action's own review workflow skips forks because it cannot mint its configured OIDC token there. This proves the fork guard is an authentication property, not a Rust property. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/.github/workflows/claude-review.yml>; <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>.

##### Dominant choice

No enabled review workflow in the template. A downstream opt-in uses `anthropics/claude-code-action@v1.0.217` with `pull_request` types `opened`, `synchronize`, `ready_for_review`, and `reopened`; use a final immutable reference only under R20's pinning decision. Retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/pr-review-comprehensive.yml>.

##### Qualified shortlist

`anthropics/claude-code-action` is qualified conditionally: license is MIT; Rust crate downloads, dependency-tree MSRV, RustSec advisories, `unsafe` posture, Cargo default features, async coupling, binary size, compile time, and Rust OS test matrix are inapplicable because this is a JavaScript GitHub Action rather than a linked Rust dependency. Its runner platform is GitHub-hosted Ubuntu in the maintained example; it need not build Rust on macOS because it is not shipped. A downstream must still test its repository on required `ubuntu-latest` and `macos-latest` CI lanes. Retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/pr-review-comprehensive.yml>.

##### Excluded by gate

Enabled-by-default review is excluded by the credential/readiness gate: a public template cannot supply each downstream user's Anthropic authentication or GitHub App installation, and fork PRs do not receive ordinary secrets. This is a deployment gate, not a popularity judgment. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>; <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>.

##### Up-and-comers

The maintained `claude-code-action` is the only action-family candidate selected for a future recipe. `claude-code-base-action` is excluded as a direct substitute because it omits the high-level action's actor checks and base-configuration restoration. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

##### Fit for this template

It can inspect Rust CLI, library, and web-service changes without Rust-specific configuration, but review frequency creates variable provider cost and no acceptance criterion requires vendor AI review. Therefore it is a documented option rather than template furniture. No quantitative cost or public-starter false-trigger study was verified in this run. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>.

##### Recommendation

Do not ship the file. In the opt-in recipe, use the same-repository guard plus both py bot checks, no `allowed_bots`, `contents: read`, `pull-requests: read` or `write` only when inline review posting requires it, and `id-token: write` only for WIF. Exact least privilege must be reconciled with R08. Retrieved 2026-09-06: <https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/claude-code-review.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

##### Ranked runner-up

Ship an enabled same-repository-only review workflow. It is second because it makes every adopter provision and fund a provider integration even when they do not want AI review. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>.

##### Tradeoffs

Opt-in adds setup work and loses automatic feedback for a newly generated repository. It avoids surprise spend, unavailable credentials on forks, and an extra non-required check. The action's 456 open-issue count is a maintenance signal to monitor, not a defect conclusion. Endpoint retrieved 2026-09-06: <https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open>.

##### Parameters

No owned or consumed research parameter. `rust-edition`, MSRV policy, license, and target OS matrix are inapplicable to this external workflow action; the downstream authentication choice is an opt-in deployment decision, not a template parameter. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>.

##### Migration implications

Do not add `.github/workflows/claude-code-review.yml`. Add an opt-in section to the template documentation that states prerequisite configuration, the R20 pinning dependency, the same-repository/bot condition, and expected non-required status. This is a proposed change; no template file was modified.

##### Validation strategy

Planned downstream check: run `actionlint .github/workflows/claude-code-review.yml`; open an internal PR against a disposable configured repository; verify one review comment; then open a bot PR and a fork PR and verify the job is skipped rather than red. Verify the Rust fixture itself with `cargo test --workspace` on `ubuntu-latest` and `macos-latest`. These commands and runs were not executed because no workflow was shipped and no authorized provider configuration exists.

##### Confidence & re-verify trigger

Medium confidence in omission; high confidence that current action documentation supports review mode. Re-verify before any adoption, on a new action major release, an authentication/security-model change, or R20's action-pinning conclusion. Endpoint and documents retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

##### Sources

Maintenance: active. The repository was pushed on 2026-09-06 and released `v1.0.217` the same day. Of the ten most recently opened non-PR issues, all had zero comments at retrieval, so median time to first maintainer response is undefined and unanswered count is 10; the newest issue was less than two days old, so this is not an at-risk conclusion. Endpoints retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action>; <https://api.github.com/repos/anthropics/claude-code-action/issues?state=open&sort=created&direction=desc&per_page=100>; <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>. Crates.io figures and RustSec advisories are inapplicable because no Rust crate is a member.

#### `@mention` assistant

##### Landscape

This member is an authorized-comment/issue interaction workflow, not a Rust crate. GitHub supplies `issue_comment`, `pull_request_review_comment`, `pull_request_review`, and `issues`; Anthropic's maintained example applies an `@claude` predicate over those event bodies. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>; <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>.

##### Principles and implementation

Because a mention can ask the agent to change code or post a response, it is more privileged than review. The action checks whether an actor has write access by default and rejects bots unless explicitly allowed; its documentation warns that a public repository plus `allowed_bots: '*'` can let an external App invoke a prompt it controls. This member must therefore remain off by default and must not bypass actor checks. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

##### Dominant choice

No enabled mention workflow in the template. A downstream opt-in uses `anthropics/claude-code-action@v1.0.217` and only `created` comment events, submitted reviews, and opened issues filtered for `@claude`; assignment is excluded because a template needs an explicit request, not a side effect of triage. Retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>.

##### Qualified shortlist

The high-level action qualifies conditionally under the same non-crate fitness assessment as the review member: license MIT; crate downloads, MSRV, RustSec, unsafe posture, Cargo features, async coupling, binary size, compile time, and Rust platform testing are inapplicable. The GitHub runner example is Ubuntu; Rust consumer CI retains the owner-fixed Ubuntu and macOS matrix. Retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>.

##### Excluded by gate

Enabled-by-default mention handling is excluded by the public-input and credential gates. The action warns about prompt injection through hidden content and describes `allowed_non_write_users` as risky; a template cannot know a downstream repository's trust boundary. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

##### Up-and-comers

The action's optional `assignee_trigger` and `label_trigger` are not selected. They are supported by the action but change a human's explicit prompt into a workflow-side convention, which is not justified for a starter template. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>.

##### Fit for this template

This mode is useful after a downstream has an Anthropic account, an installed App or custom App, and maintainer access policies. It is not required to demonstrate a Rust CLI, library, or service, and it needs no Rust-specific adaptation. The public template should document the capability without asserting that it works before configuration. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>.

##### Recommendation

Do not ship the file. In an opt-in recipe, use the four supported event surfaces but restrict types to `created`, `submitted`, and `opened`, condition each relevant field on the exact trigger phrase, keep `allowed_bots` empty, retain the action's write-access check, and grant `contents`, `issues`, and `pull-requests` write only if the documented downstream behavior actually edits or responds. Include `actions: read` only when the assistant must inspect CI results; reconcile the final permission set with R08. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>.

##### Ranked runner-up

Ship an enabled maintainer-only mention workflow. It is second because it still requires paid/provider authentication and gives a template a write-capable integration before the downstream has made a trust and cost decision. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>.

##### Tradeoffs

Omission removes a convenient maintainer command. It avoids inheriting high write permissions and prompt-injection exposure into every derived repository. The action's security documentation supplies mitigations, but mitigations do not remove the need for a repository-specific authorization decision. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

##### Parameters

No owned or consumed research parameter. All Rust crate fitness fields are inapplicable because this member is an external workflow action. The downstream's WIF, API-key, OAuth-token, or App choice is local deployment configuration. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>.

##### Migration implications

Do not add `.github/workflows/claude.yml`. The proposed opt-in documentation must describe the trigger filter, actor authorization, authentication configuration, R08 permissions boundary, and R20 action-reference decision. No template file was modified.

##### Validation strategy

Planned downstream check: run `actionlint .github/workflows/claude.yml`; on a configured disposable repository, post `@claude summarize this issue` as a maintainer and verify one response; post the phrase from an unauthorized user and from a bot and verify no agent work occurs; then run `cargo test --workspace` on `ubuntu-latest` and `macos-latest` to prove the fixture remains valid. These are planned checks, not executed results.

##### Confidence & re-verify trigger

Medium confidence in omission; high confidence that the maintained example supports the stated events. Re-verify before adoption, when the action changes access-control defaults, on a major action release, or when R08/R20 resolves permissions and pinning. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>; <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>.

##### Sources

Maintenance: active, using the same repository evidence as the review member. The response-time sample is shared: ten most-recent non-PR open issues had zero comments, making median first maintainer response undefined and unanswered count 10 at retrieval. This does not establish a latency defect because the sample is 0–2 days old. Endpoints retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action>; <https://api.github.com/repos/anthropics/claude-code-action/issues?state=open&sort=created&direction=desc&per_page=100>. Crates.io figures and RustSec advisories are inapplicable because no Rust crate is a member.

### Compatibility

The two prospective workflows are compatible at the action-family level: Anthropic maintains an automatic-review example and an `@claude` event example under the same `claude-code-action` repository, and the action metadata explicitly detects PR-review, mention, and automation modes. They should not be collapsed into one job because the review workflow can remain read-oriented while a mention workflow may write. No shared Rust adopter or end-to-end version matrix was verified; this compatibility conclusion is limited to the maintained examples and action interface. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/action.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/pr-review-comprehensive.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>.

### Parameters

R18 owns no parameter and consumes no parameter. No `CONFLICT:` is emitted: the recommendation does not require changing owner-fixed `rust-edition`, `msrv-policy`, `license`, or `target-os-matrix`. The external-action version is an evidence value (`v1.0.217` on 2026-09-06), not a shared Rust parameter; final action-reference policy belongs to R20. Retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>.

### Migration implications

For the current recommendation, add neither workflow file. The implementation plan should add a non-default documentation section that states: downstream owner configuration is required; WIF is preferred where available; direct API key and OAuth token are alternatives; automatic review needs the same-repository plus author-and-sender bot guard; mention assistance must retain write-access enforcement and must not set `allowed_bots: '*'`; R08 decides the final permission convention and R20 decides the final action reference. These are proposed file-level changes only; no repository file was modified. Retrieved 2026-09-06: <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

### Validation strategy

The recommended acceptance condition is absence: a generated `rs-launch-blueprint` repository contains neither AI workflow and has no required secret or GitHub App dependency. Planned opt-in validation is: (1) add the two documented files to a disposable configured repository, (2) run `actionlint .github/workflows/claude-code-review.yml .github/workflows/claude.yml`, (3) create an internal PR and assert one review response, (4) exercise bot author, bot sender, fork, unauthorized commenter, and authorized maintainer mention controls, and (5) run `cargo test --workspace` in GitHub Actions on `ubuntu-latest` and `macos-latest`. Expected behavior is a skipped non-required job for excluded actors and one response for the authorized maintainer; any run with an absent credential is a configuration failure, not a passing test. These checks were not executed because the template has no Rust code and this run received no authorized provider account, GitHub App, or paid-run approval. GitHub's documented fork and event behavior supports the proposed negative controls. Retrieved 2026-09-06: <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>.

### Confidence & re-verify trigger

Recommendation confidence is medium: the security and credential argument for an absent-by-default template is directly supported, while no independent Rust-template adopter or starter-repository cost study was verified. Re-open R18 before implementation if the owner requires a built-in AI workflow, Anthropic changes its action/authentication/access-control model, a major action version ships, a public Rust-template adoption study is found, or R08/R20 yields a conflicting permission/pinning requirement. The action is presently active, but its release cadence makes a stale version likely. Endpoint retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>.

### Sources

- Anthropic maintained action interface, setup, examples, and security guidance, retrieved 2026-09-06: <https://github.com/anthropics/claude-code-action>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/action.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/setup.md>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/pr-review-comprehensive.yml>; <https://raw.githubusercontent.com/anthropics/claude-code-action/main/examples/claude.yml>.
- GitHub Actions trigger and credential authority, retrieved 2026-09-06: <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>; <https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication>.
- Live action figures: stars, archived state, last push, license, releases, open-issue count, and recent-issue sample, endpoints retrieved 2026-09-06: <https://api.github.com/repos/anthropics/claude-code-action>; <https://api.github.com/repos/anthropics/claude-code-action/releases?per_page=10>; <https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open>; <https://api.github.com/repos/anthropics/claude-code-action/issues?state=open&sort=created&direction=desc&per_page=100>.
- Pinned source precedents, retrieved 2026-09-06: <https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/claude-code-review.yml>; <https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/claude.yml>; <https://github.com/smorinlabs/ts-launch-blueprint/tree/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/workflows>.

Method notes: queried GitHub REST repository, releases, issue-search, and open-issues endpoints for `anthropics/claude-code-action`; read Anthropic's maintained action metadata, setup, usage, security, and example files; and read GitHub's maintained Actions documentation. Crates.io version/download endpoints and RustSec package pages were not queried because the bundle has no Rust crate candidate; that inapplicability is stated for each member. No independent well-regarded Rust adopter, public-template-specific cost/rate-limit study, provider credential, GitHub App installation, or live workflow execution was verified.
