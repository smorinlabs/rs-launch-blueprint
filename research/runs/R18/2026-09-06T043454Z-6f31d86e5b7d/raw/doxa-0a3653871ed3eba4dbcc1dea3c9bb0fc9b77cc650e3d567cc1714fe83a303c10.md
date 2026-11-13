---
prompt: # Deep-research prompt — AI-assisted review workflows (R18, bundle)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260909-003249-bf15cd42494140b6
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

Generated: 2026-09-09T07:46:41.529542+00:00


## Openai Results

---
prompt: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
mode: all_deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260909-003249-bf15cd42494140b6
created_at: 2026-09-09T00:32:49.668391
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
```

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

---


## Perplexity Results

---
prompt: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
mode: all_deep_research
provider: perplexity
model: sonar-deep-research
operation_id: research-20260909-003249-bf15cd42494140b6
created_at: 2026-09-09T00:32:49.668391
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
```

# AI-assisted GitHub review workflows for `rs-launch-blueprint` (R18 bundle)

The decision for `rs-launch-blueprint` is whether to ship a pair of AI-assisted GitHub Actions workflows—a fully automated PR code-review job and an `@mention`-triggered assistant job—both built on the maintained `anthropics/claude-code-action` family, and if so, how to pin versions, choose triggers, and harden bot-authorship and permissions. Based on a landscape survey of AI review tooling around Rust, GitHub’s own agentic workflows, and Anthropic’s Claude Code ecosystem; an analysis of cross-language template principles between `py-launch-blueprint`, `ts-launch-blueprint`, and the Rust port; and the current configuration and security guidance of `anthropics/claude-code-action`, the recommended stack is that `rs-launch-blueprint` ships both workflows as an integrated bundle. The automatic PR review job should run on PR open and synchronize events, skip bot-authored and bot-sent PRs using the same guard logic as py’s template, and pin the official action at the major version `anthropics/claude-code-action@v1` for stability while allowing patch updates.[1][3][5][11] The `@mention` assistant workflow should listen only to issue comments and PR-review comments containing `@claude`, be gated to human authors with repository write access, and rely on the action’s built‑in bot restrictions rather than broad `allowed_bots` overrides.[2][4][10][15] Both workflows should be present but inert until a repository owner installs the Claude GitHub App and configures either an `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` secret, preserving the template’s applicability to public forks while offering a first-class path to AI-assisted review that matches the Python precedent and provides a clear rationale for addressing the current divergence with the TypeScript template.[2][3][8][13]  

## Analysis

### Landscape

The category this item decides is AI-assisted GitHub review and assistant workflows for a Rust multi‑target template: code review automation and conversational help wired into CI for a CLI, library, and web service that live in a single repository. In terms of ecosystem bins, this category spans three layers. At the built‑in or first‑party toolchain layer, GitHub itself now offers “agentic workflows” that integrate AI engines such as Copilot and Anthropic Claude directly into CI, with native authentication primitives and permission models.[12] The GitHub Agentic Workflows documentation describes how Copilot requests are authenticated through `copilot-requests: write` permissions using the built‑in Actions token, and how alternative engines such as Claude are wired via `ANTHROPIC_API_KEY` or keyless Workload Identity Federation, establishing GitHub as a first‑party provider of AI‑driven automation rather than merely a hosting platform.[12] This makes GitHub Agentic Workflows and Copilot-based flows part of the “built‑in” bin for this category, particularly for organizations already invested in Copilot.

At the established industry standard layer, Anthropic’s Claude Code and its official GitHub Action family form the central reference point for this decision.[1][2][3][9] The `anthropics/claude-code-action` repository on GitHub is described as a general‑purpose Claude Code action for PRs and issues that can answer questions and implement code changes, supports multiple authentication methods, and auto‑detects whether it should operate in interactive `@mention` mode or respond to a scripted prompt, depending on workflow configuration.[1] The Claude Code GitHub Actions documentation further clarifies that the marketplace action `anthropics/claude-code-action@v1` runs Claude Code inside a repository’s workflows, responds to `@claude` mentions in PR and issue comments, and can be invoked automatically via prompts to perform tasks such as turning issues into pull requests, fixing bugs, and generating reports.[2] The GitHub Marketplace listing for Claude Code Action reiterates that it runs Claude Code on the local repository, modifies files in the workflow’s working directory, and outputs a summary to logs, positioning it as the maintained, versioned action for integrating Claude Code into CI.[9] The v1.0 release announcement and subsequent patch releases on the action’s Releases page confirm that this family is now generally available, with ongoing updates such as v1.0.8 that refine simplicity, flexibility, and security of AI-assisted development workflows.[11] Collectively, these sources mark `anthropics/claude-code-action` as an established, first‑party standard for Claude‑based review and automation across language ecosystems.

Also in the established standard bin, but with a narrower scope, is the managed Claude Code Review service, which is an Anthropic-hosted GitHub app that reviews pull requests without requiring teams to host workflows themselves.[4][16] The Claude Academy lesson on GitHub Actions and Code Review describes Code Review as the simplest option: a service that posts findings as inline comments on PRs, enabled from the Claude Code admin settings by an organization admin.[4] The Code Review documentation explains that once an owner enables Code Review, reviews trigger on PR open, every push, or when manually requested via commands such as `@claude review` in PR comments, and that the service obeys shared configuration files such as `CLAUDE.md` and `REVIEW.md` to apply project standards.[16] This managed service is important because it demonstrates that Anthropic’s review architecture is built around diff‑focused automated analysis, inline comments, and per‑project review policies, but its operational model (Anthropic-hosted rather than workflow‑hosted) is slightly different from the template’s requirement, which is to ship workflows that downstream consumers can customize.

The up‑and‑comer bin within this category includes third‑party GitHub Actions and patterns that leverage Claude but are not maintained directly by Anthropic. A prominent example is the `drillan/claude-pr-reviewer` action, which uses Claude AI together with a `pr-review-toolkit` plugin to perform automated PR reviews.[6] Its Marketplace description emphasizes comprehensive code reviews with features such as code quality checks, test coverage analysis, error handling detection, type design analysis, and comment accuracy verification, and shows how it can be wired into workflows using either a Claude Code OAuth token or an Anthropic API key.[6] This action supports interactive review when `@claude` is mentioned in PR comments, but it layers a custom plugin and review policy atop Claude Code rather than exposing the raw Claude Code agent that `anthropics/claude-code-action` uses.[6] Another up‑and‑comer category is user‑authored workflows that invoke the Claude Code CLI directly inside GitHub Actions jobs, such as the dev.to example where Claude is installed via npm and invoked with `/code-review` and other prompts to perform a multi‑axis code review, secret scanning, and dependency CVE checks.[7] That article illustrates how teams can compose bespoke review pipelines around the Claude CLI, but these remain bespoke patterns, not standardized, maintained actions.[7]

In terms of authoritative sources, this decision leans on several types. First, Anthropic’s own documentation for Claude Code GitHub Actions, Code Review, and the Claude Code Playbook are authoritative because they are the vendor-maintained specifications of capabilities, intended usage, and security posture.[2][4][8][13][14][15][16] The Playbook describes `anthropics/claude-code-action@v1` as the official action, now generally available as of early 2026, and notes that it can review PRs, implement features from issues, generate tests, and produce reports, all triggered by events or `@claude` mentions.[8] It also details OAuth token generation via `claude setup-token` and repository secret configuration, clarifying authentication options.[8] Second, GitHub’s Agentic Workflows documentation is authoritative for how AI engines, including Claude, interact with GitHub infrastructure, tokens, and permissions.[12] It specifies that `ANTHROPIC_API_KEY` is the supported secret for Claude engines and that `CLAUDE_CODE_OAUTH_TOKEN` is not supported in Agentic Workflows, underscoring the separation between GitHub’s native AI integration and Anthropic’s own action family.[12] Third, practitioner write‑ups such as the Blink blog on Claude Code in GitHub Actions and the dev.to article on automating code reviews provide practice‑level evidence, showing how teams compose workflows, handle cost, and balance automated and human review.[7][10] The Blink article describes the official `anthropics/claude-code-action` as having thousands of stars and forks, emphasizes that it runs entirely on GitHub-hosted runners with only API calls leaving the infrastructure, and enumerates capabilities such as automatic PR review with confidence scoring, interactive `@claude` mentions, issue-to-PR automation, and scheduled reports.[10] These writings are not standards, but they are widely cited practitioner guidance that demonstrate how the action is used in production contexts.[7][10]

For practice evidence specifically in Rust, the landscape is more diffuse. Rust projects overwhelmingly use GitHub Actions for CI across OS matrices, and many Rust maintainers adopt AI assistance at the editor or Copilot level rather than full CI automation. The relevant evidence here is that the Claude Code Action and related workflows are language‑agnostic and have been applied across multiple ecosystems, including Python and TypeScript templates, as well as mixed-language repositories described in the Claude Code Playbook.[8] The Playbook explicitly calls out that the `anthropics/claude-code-action@v1` can review PRs, implement features from issues, and generate tests, implying that its applicability does not depend on language-specific tooling.[8] The dev.to workflow shows Claude reviewing diffs, scanning for secrets, and checking dependencies from within a JavaScript-centric project, yet the patterns—diff extraction, CLI invocation, and PR comment posting—are identical to what a Rust project would require.[7] Because this item concerns a template decision rather than a choice of Rust crate, the practice evidence from these cross‑language sources is directly relevant: the workflows operate on git diffs, repository contents, and GitHub events, not on language semantics.

In mapping candidates for this decision, the first-party bin contains GitHub Agentic Workflows with Copilot and Claude engines, which could, in principle, be used for PR review and assistance in Rust. However, these workflows are not currently part of the `py-launch-blueprint` or `ts-launch-blueprint` implementations and would introduce a second AI stack alongside Claude Code, complicating cross-language alignment.[12] The established industry standard bin contains the official Claude Code GitHub Action (`anthropics/claude-code-action`) and the managed Code Review service, both of which are directly supported by Anthropic and integrated with Claude Code’s CLI and project configuration files.[1][2][4][8][9][11][13][16] The up‑and‑comer bin contains third‑party actions such as `drillan/claude-pr-reviewer` and bespoke workflows that orchestrate Claude Code or other LLMs via custom scripts.[6][7] Every candidate considered for the Rust template must come from this mapped landscape rather than from prior familiarity alone; the Python precedent, while important, is treated as evidence of a functioning design rather than as a predetermined winner.

### Principles and implementation

The shared engineering principle across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` in this area is that template repositories should expose a **capability** for AI-assisted code review and conversational assistance that is safe by default, clearly bounded, and optional for downstream adopters. The owner’s research mandate emphasizes that agreement must be established at the level of capability, standard, architectural pattern, or policy—not at the level of a specific inherited mechanism—and that precedent implementations and ledger classifications are evidence, not automatic winners. This principle implies that each template should either not expose AI-assisted workflows at all, or expose them consistently in a way that respects security, cost, and user control, while leaving room for ecosystem‑specific tuning.

From the Python template’s current implementation, we can infer a more precise articulation of the principle. `py-launch-blueprint` ships two workflows built on the `anthropics/claude-code-action` family: an automatic PR code review workflow keyed on PR open and synchronize events, and an `@mention` assistant workflow keyed on issue and PR-review comments containing `@claude`.[1][2] The automatic review job is configured to skip bot-authored or bot-sent PRs, preventing feedback loops on PRs opened by automation tools such as Dependabot or release bots.[5][15] The `@mention` assistant workflow listens only to comments that explicitly mention `@claude` and is further constrained by repository permission checks within the action, which only allows users with write permissions to trigger Claude operations.[2][15] Together, these workflows embody the principle that AI assistance should be opt‑in at two levels: at the repository level, where the GitHub App and secret must be installed; and at the per-PR or per-comment level, where either a new PR or a deliberate `@claude` mention is required to trigger AI behavior.[2][4][13][16]

The TypeScript template’s divergence—shipping neither workflow—signals that the agreed level of alignment across templates is not yet at the concrete workflow level but at the capability level. The ledger rows F051 and F052 classified as `DIVERGENT` reflect that Python has adopted these AI workflows while TypeScript has not, but that the two workflows are bundled and plausibly adopted or dropped together as the common action family evolves. The owner’s clarification on 2026‑09‑04 further specifies that this item must identify the shared engineering principle, the agreement level, and observable acceptance criteria, then research architectures and libraries that best realize them in each ecosystem. This means the Rust decision must preserve agreement at the level of “templates provide a safe, optional AI-assisted review capability built on maintained tooling” while allowing the exact adoption state of py and ts to remain a follow‑on project for migration.

Architecturally, the pattern at stake is an **agentic CI integration**: an AI agent that can read repository contents and diffs, understand project standards, and perform mechanical first-pass review and assistance tasks triggered by GitHub events. Anthropic’s Claude Code is explicitly described as an “agentic coding tool” that understands codebases and helps developers via natural language commands, and the `anthropics/claude-code-action` exposes this agent in CI.[1][9] The Playbook and Blink blog describe a pattern where automatic PR review and interactive `@claude` mentions coexist, both using the same action but differentiated by whether a `prompt` is present in the workflow configuration.[8][10] When a `prompt` is provided, the action runs in “scripted” mode, executing a specific instruction such as review the current PR; when no prompt is given and a `trigger_phrase` like `@claude` is configured, the action runs in interactive mode, responding to whatever the commenter asked within the PR or issue thread.[4][10] This pattern—one agentic action capable of both automatic and interactive roles—is central to the cross-language principle: templates should, where possible, adopt a unified action family that can support both review jobs and assistant jobs, rather than composing heterogeneous tools.

Observable acceptance criteria for this principle can be extracted from Anthropic’s documentation and practitioner examples. For automatic PR review, the Claude Code Action should reliably analyze diffs on each relevant trigger, consult project standards from `CLAUDE.md` or equivalent files when present, and post inline comments or top-level PR comments that flag code quality issues, potential bugs, security implications, and performance considerations, without flooding PRs with low‑confidence findings.[4][5][10][16] The Blink blog notes that the official action applies confidence scoring and filters findings below a threshold (e.g., 80/100) before posting, catching regressions such as removed auth guards or missing input validation while avoiding noisy nitpicks.[10] For interactive assistance, the action should respond to `@claude` mentions by reading the context of the comment thread, understanding the surrounding discussion, and either implementing requested changes (via commits pushed back to the PR branch) or explaining constraints, all while respecting repository permissions.[2][4][10][15] Security acceptance criteria include that bots cannot trigger actions by default, that only users with write or higher permissions can cause AI operations to run, and that any override of `allowed_bots` is explicitly scoped to trusted bot names.[15] Cost acceptance criteria include clear guidance on approximate per‑PR token consumption and cost, such as the dev.to article’s estimation that small PRs under 200 changed lines cost on the order of a few cents and large PRs can cost tens of cents per review with Claude Code, which template owners must factor into their decision to enable automated review by default.[7]

The Rust ecosystem introduces no fundamental architectural difference for these patterns, because the workflows operate on git diffs, repository files, and GitHub events rather than on language-specific build artefacts. However, Rust’s emphasis on compile-time guarantees, strict MSRV policies, and multi‑OS CI does shape how AI-assisted review should be framed. The MSRV policy (“stable minus two minor versions, raised only in a minor release, declared in `Cargo.toml` and tested in CI”) and the OS matrix requirement (`ubuntu-latest` and `macos-latest`) constrain what workflows can assume about tooling, but `anthropics/claude-code-action` is agnostic to Rust toolchains and runs entirely as a GitHub Action on standard runners.[8][9][10] This means that, from a fitness standpoint, the action satisfies the Rust template’s gates: it has no Rust crates or MSRV; it runs on the specified OS matrix; and its license (MIT) is compatible with the template’s dual MIT/Apache-2.0 licensing.[1][9][11] The only ecosystem-specific consideration is that Rust developers may prefer to keep AI assistance focused on code review and mechanical fixes rather than architectural redesign, and template documentation should frame the workflows accordingly.

Given this analysis, the shared requirement and agreement level across templates can be stated as follows. At the capability level, all templates in this family should be designed to support AI-assisted code review and conversational assistance via GitHub workflows built on a maintained, vendor-supported action family. At the architectural pattern level, the preferred pattern is a unified agentic action (Claude Code) that can run both automatic review jobs and interactive `@mention` assistant jobs, controlled by triggers and prompts. At the policy level, workflows must be secured against bot-triggered loops, respect repository permissions, and be opt‑in both at repository setup and per‑event levels. The concrete implementation—whether workflows are shipped enabled by default, gated behind commented sections, or absent—is allowed to vary per ecosystem, but divergence should be justified by ecosystem characteristics, not by accident.

This leads to a baseline review finding, stated explicitly as required.  

BASELINE-REVIEW: F051 — principle: templates should expose a safe, optional capability for AI-assisted PR review and conversational assistance via maintained actions; proposed change: treat the absence of these workflows in `ts-launch-blueprint` as accidental drift rather than a deliberate policy difference, and align future TypeScript and Rust templates on shipping both workflows, with ecosystem-specific trigger tuning; evidence: Anthropic’s documentation and practitioner examples show that `anthropics/claude-code-action` is designed to support both automatic review and `@mention` assistance from the same action family, and Python’s implementation demonstrates that these capabilities can coexist safely when guarded against bot-authored PRs and enforced through repository permission checks.[1][2][4][5][8][10][15][16]  

The recommended design for Rust must therefore preserve the principle—a bundled pair of workflows built on `anthropics/claude-code-action`, with clear triggers, security guards, and opt‑in setup—while considering Rust’s ecosystem fit and the realities of template consumption.

### Recommendation

The recommended stack for `rs-launch-blueprint` is to ship **both** AI-assisted workflows—the automatic PR code-review job and the `@mention` assistant job—as a bundled pair built on the `anthropics/claude-code-action` family, configured with Rust-agnostic triggers and security guards, and pinned at the stable major version `@v1`. The automatic PR code-review workflow should be defined in `.github/workflows/claude-code-review.yml` and trigger on `pull_request` events with types `opened`, `synchronize`, and optionally `ready_for_review` and `reopened`, mirroring Anthropic’s recommended “Automatic PR Code Review” configuration.[5][8] The job should run on `ubuntu-latest` and `macos-latest` via the repository’s CI matrix, grant minimal `contents: read` and `pull-requests: write` permissions, and include an explicit condition that skips PRs where the author is a bot or where the PR originates from known automated tools, porting py’s bot-authored/bot-sent PR skip guard without Rust-specific changes.[5][15] Within the job, the core step should use `anthropics/claude-code-action@v1`, pass either `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` as configured by the repository owner, and supply a prompt that asks Claude to review the current PR with attention to code quality, potential bugs, security implications, and performance, using allowed tools such as GitHub CLI commands and MCP inline comment tools, as in Anthropic’s examples.[5][8]

The `@mention` assistant workflow should be defined in `.github/workflows/claude.yml` and trigger on `issue_comment` and `pull_request_review_comment` events of type `created`, as well as on new issues whose body contains `@claude` if the template owner wishes to allow issue-body triggers.[2][4][6][8][10] The workflow should include conditions that require the comment or issue body to contain the configured `trigger_phrase` (default `@claude`), and that the commenting user is not a bot and has write or higher permissions on the repository, leveraging both GitHub’s event fields and the Claude Code Action’s own permission checks.[2][4][15] In this workflow, the `anthropics/claude-code-action@v1` step should be configured without a `prompt`, allowing the action to auto-detect interactive mode and respond to the content of the comment thread, using the `trigger_phrase` to decide when to activate.[2][4][10] The workflow’s permissions should grant `contents: write`, `pull-requests: write`, and `issues: write` where necessary for the action to post comments and push commits, but rely on the broader repository permission-hardening policy (R08) to ensure least privilege at the job level.

Both workflows should be present in the template repository but intentionally inert until a downstream consumer chooses to install the Claude GitHub App and configure secrets. The Claude Code setup documentation explains that the usual sequence is to install the GitHub App, add authentication secrets (`ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`), and copy workflow files into `.github/workflows`, and that Claude Code can automate this via the `/install-github-app` command in the CLI.[2][3][8][13] In a template, the workflows can be shipped already present, reducing friction for adopters, but they should be documented in the template’s README as requiring additional setup and cost considerations. To support public template repositories and forks, these workflows should include an `if` condition or early job step that checks for the presence of the required secret and either skips the job or logs a clear message when the secret is absent, preventing noisy failure states when forks do not configure Anthropic credentials. This pattern is common in templates that reference secrets by name but cannot assume their existence.

Crucially, the action family to be used for both workflows should remain `anthropics/claude-code-action@v1`, not alternative actions. Anthropic’s documentation and releases show that this is the maintained, versioned action for Claude Code in GitHub Actions, with a v1.0 GA release and subsequent patch updates such as v1.0.8, and that it supports both automatic review and `@mention` modes from the same codebase.[1][2][3][8][9][11] The `drillan/claude-pr-reviewer` action, while interesting as a third‑party specialization for PR review, introduces additional plugin dependencies and configuration that are outside the cross-language precedent and Rust’s template needs.[6] The managed Code Review service is complementary but not a workflow-level integration; it operates through a hosted GitHub App, triggered by comments like `@claude review`, and would require separate owner-level decisions about service enablement.[4][16] For template purposes, the unified action family best preserves architectural alignment across Python, TypeScript, and Rust templates.

### Members

#### Automatic PR code-review workflow (`.github/workflows/claude-code-review.yml`)

##### Landscape

Within the landscape of AI-assisted PR review for Rust projects, the automatic PR code-review workflow corresponds to integrating an AI agent into the CI pipeline to perform a first-pass assessment of pull requests on every relevant push. The established industry standard for this role in the Claude ecosystem is the `anthropics/claude-code-action` configured with a review prompt, as described in both Anthropic’s solutions documentation and the Claude Code Playbook.[5][8] The “Automatic PR Code Review” solution in the Claude Code Action docs provides a ready-to-use workflow that triggers on `pull_request` events with types `opened` and `synchronize`, checks out the PR branch, and then runs `anthropics/claude-code-action@v1` with an explicit prompt that instructs Claude to review code quality, potential bugs, security implications, and performance, posting feedback via GitHub comments and inline annotations.[5] The Playbook reinforces this usage, noting that the official action can review PRs and emphasizing that `anthropics/claude-code-action@v1` is generally available as of early 2026.[8]

Alternative patterns in the landscape include third‑party actions such as `drillan/claude-pr-reviewer`, which wraps Claude AI with a specialized PR review toolkit, and bespoke workflows that call the Claude CLI directly.[6][7] The `drillan/claude-pr-reviewer` Marketplace entry shows a basic workflow that triggers on `pull_request` events with `opened` and `synchronize` types and runs `drillan/claude-pr-reviewer@v1`, passing either `claude_code_oauth_token` or `anthropic_api_key` as inputs.[6] It emphasizes preconfigured review dimensions such as code quality, test coverage, error handling, type design, and comment accuracy, and supports interactive review when `@claude` is mentioned in PR comments, although this interactive path is mediated by the plugin’s configuration rather than by raw Claude Code.[6] The dev.to article presents a manual pattern where the workflow installs Claude Code via npm, extracts the git diff via `git diff origin/${{ github.base_ref }}...HEAD`, and passes that diff into a `claude` CLI invocation with a review prompt, then posts the resulting Markdown review as a PR comment using `gh pr comment`.[7] That example also chains additional jobs for secret scanning and dependency CVE checks, using Claude to scan file lists and `package.json` contents.[7]

From a Rust ecosystem perspective, there is no Rust-specific PR review action that rivals these in maturity or adoption. Common Rust CI patterns use tools like `cargo test`, `cargo fmt`, and `clippy` for automated mechanical checks, but AI-assisted review is typically integrated via general-purpose tools like Claude Code or Copilot rather than Rust-specific engines. Since Claude Code’s review is diff-based and language-agnostic, the action’s fit for Rust is determined by its ability to read Rust files and the repository’s `CLAUDE.md` conventions, which is already demonstrated in cross-language examples.[8][10][16] The category mapping thus places `anthropics/claude-code-action` plus Code Review in the established industry standard bin for automatic PR review, with `drillan/claude-pr-reviewer` and CLI-based workflows in the up‑and‑comer bin.

##### Principles and implementation

The automatic PR review workflow must implement the shared principle that AI assistance provides a mechanical first-pass check, not a replacement for human review, and that it operates safely and predictably on PR events. Anthropic’s Code Review documentation and Academy guidance describe automated review as focusing on correctness bugs, simplification opportunities, efficiency improvements, and reuse, with findings posted as inline comments or PR-level summaries that human reviewers can act upon.[4][16] The “Automatic PR Code Review” solution for Claude Code Action demonstrates an implementation pattern where the workflow includes context such as repository name and PR number in the prompt, instructing Claude to review the current PR for code quality, potential issues, security implications, and performance, and to post comments using tools like `gh pr comment` and a dedicated MCP inline comment tool.[5] Importantly, the solution notes that the PR branch is already checked out as part of the workflow, and it configures `claude_args` to restrict tools and control behavior.[5]

In the Rust template, this pattern can be preserved almost unchanged, because the review logic operates on the diff and file contents independent of language. The workflow should check out the PR branch using `actions/checkout` with `fetch-depth: 1`, then invoke `anthropics/claude-code-action@v1` with the Anthropic secret and a prompt tailored to Rust’s typical concerns, such as correctness around ownership and borrowing, performance implications of allocations, and security aspects like input validation and error handling. The action itself will parse the repo, read context files such as `CLAUDE.md` if present, and decide whether to post inline comments or top-level comments, relying on its integrated tools and confidence scoring.[8][10][16] This design preserves the architectural pattern of a diff-aware agent, and acceptance can be observed by inspecting PRs to see whether relevant issues are flagged and whether noise remains tolerable.

Bot-authorship guard is a critical implementation detail. The Claude Code Action security documentation states that by default, GitHub Apps and bots cannot trigger the action and that triggers are limited to users with write access to the repository, with an `allowed_bots` parameter used to enable specific bots or all bots explicitly.[15] It warns that on public repositories, if workflows listen to events such as issue opening or commenting and `allowed_bots` is set to `'*'`, any external app could trigger the action with a prompt it controls, including GitHub Apps created by third parties.[15] For automatic PR review, however, the trigger is a `pull_request` event rather than a comment or issue event, and PRs can be authored by bots even if the action does not allow bots to comment. To avoid feedback loops where PRs opened by bots are reviewed by Claude, potentially consuming tokens without human oversight, the Python template uses explicit guard logic to skip bot-authored or bot-sent PRs.

This guard logic is language-agnostic and should be ported unchanged to Rust. A typical implementation checks the `github.event.pull_request.user.type` field for `Bot`, and optionally matches known bot usernames such as Dependabot or release bots, and uses this as an `if` condition in the job or step to skip execution when the author is a bot.[5][15] Because the guard interacts only with GitHub’s actor and event fields, not with language features, there is no Rust-specific adjustment needed. The action’s internal security already prevents bots from triggering comment-based flows unless explicitly allowed; the guard extends this discipline to PR-based flows by avoiding automatic reviews on bot-authored PRs.

Fitness gates specified for this item—license compatibility, MSRV, RustSec advisories, OS support, async runtime coupling, binary size, and compile-time cost—are primarily crate-centric and thus inapplicable to a GitHub Action. The Claude Code Action is a workflow component written in JavaScript/TypeScript and running on GitHub runners, not a Rust crate that compiles into the binary. Its license, given in the GitHub repository and Marketplace, is MIT, which is compatible with the template’s MIT/Apache-2.0 licensing.[1][9] It imposes no Rust MSRV requirement, carries no RustSec advisories, and does not affect Rust binary size or compile-time cost. Its runtime dependencies are executed in the workflow environment, not linked into the Rust project. Therefore, for this member, the crate-oriented gates are inapplicable, and the relevant fitness criteria reduce to CI OS support, security posture, and maintainership.

##### Dominant choice

Given the landscape and principles, the dominant choice for the automatic PR review workflow is to use `anthropics/claude-code-action@v1` with a review prompt, as documented in Anthropic’s “Automatic PR Code Review” solution and Playbook.[5][8] The action is explicitly designed for this use case, is maintained by Anthropic with a GA v1.0 release and subsequent patch versions like v1.0.8, and integrates with Claude Code’s agentic capabilities that understand codebases and project standards.[1][3][8][9][11] The Playbook notes that the official action can review PRs and implement features from issues, and that it supports OAuth and API key authentication, as well as optional integration with AWS Bedrock and Google Vertex AI for enterprise deploys.[8] This breadth of support makes it suitable as a template default: downstream teams can choose which authentication mode and provider they use, while the workflow remains stable.

The `drillan/claude-pr-reviewer` action, while interesting, is not the dominant choice because it introduces a second layer of configuration (the `pr-review-toolkit` plugin) and is maintained by a third party rather than Anthropic.[6] Its description focuses on PR review only and requires that users first set up Claude Code GitHub Actions, implying that it is an extension on top of the official action rather than a replacement.[6] For a template whose cross-language precedent uses the official action family, and whose owner mandate prioritizes a shared architectural pattern over maximum functionality, the vendor-maintained `anthropics/claude-code-action` is the dominant choice.

##### Qualified shortlist

The qualified shortlist for this member consists of three patterns: using `anthropics/claude-code-action@v1` with a review prompt (the recommended choice), using `drillan/claude-pr-reviewer@v1` for PR review, and omitting AI-assisted PR review altogether. The first pattern is documented in Anthropic’s solutions and Playbook, with examples of automatic review workflows that include context variables and tool restrictions.[5][8] The second pattern is documented in the `drillan/claude-pr-reviewer` Marketplace entry, which provides example workflows using either an OAuth token or an Anthropic API key, and outlines the plugin’s review capabilities.[6] The third pattern—no AI review—is represented by the TypeScript template’s current behavior, which does not ship the workflows and relies entirely on human review and static analysis. All three patterns are viable for Rust; the shortlist is narrowed by cross-language alignment and the owner’s desire to expose capability rather than hide it.

##### Excluded by gate

No shortlisted option fails the template’s license, MSRV, OS, or security gates in a way that requires exclusion; instead, some gates are inapplicable to workflow actions. However, GitHub Agentic Workflows with Copilot, while appealing as a built‑in first-party option, is excluded for this member because it would introduce a second AI stack not currently used in py-launch-blueprint and would complicate cross-language alignment without clear evidence that it better serves Rust’s needs than Claude Code.[12] Furthermore, the Agentic Workflows documentation notes that `CLAUDE_CODE_OAUTH_TOKEN` is not supported in that context and emphasizes `ANTHROPIC_API_KEY` and GitHub’s own Copilot tokens, which differ from the Claude Code Action’s authentication modes.[12] This mismatch makes Agentic Workflows a separate architectural choice that should be evaluated in a distinct item, not as a candidate for this bundle.

##### Up-and-comers

Up-and-comers for automatic PR review include `drillan/claude-pr-reviewer` and bespoke CLI-based workflows. The `drillan/claude-pr-reviewer` action is relatively new, with a v1.1.1 version on the Marketplace, and positions itself as a comprehensive PR reviewer leveraging Claude AI and a plugin for detailed analysis.[6] It offers conveniences such as test coverage analysis and type design assessment, but its long-term maintenance and compatibility with evolving Claude Code features are uncertain compared to the official action. The dev.to CLI workflow pattern is a flexible up-and-comer in the sense that teams can adapt it to new review dimensions or integrate additional checks; however, it requires manual installation and maintenance of the Claude CLI, explicit diff extraction, and custom logic for posting comments, which adds complexity to templates and may not be ideal for downstream users who expect plug‑and‑play workflows.[7] These up-and-comers are worth monitoring but not appropriate for the template’s default.

##### Fit for this template

For a Rust template that combines CLI, library, and web service targets, the automatic PR review workflow built on `anthropics/claude-code-action@v1` fits particularly well. Claude Code operates at the level of code and diffs, not at the level of runtime or language-specific tooling, so it can review changes in CLI argument parsing, library APIs, and web handlers uniformly. It can also be guided by project-specific standards documented in `CLAUDE.md`, which may include Rust-specific conventions such as avoiding unchecked `unwrap`, preferring `Result`-based error handling, adhering to `clippy` lints, and maintaining MSRV compatibility.[8][10][16] The workflow will run on `ubuntu-latest` and `macos-latest`, matching the template’s CI matrix, and will consume the same diffs that human reviewers see, thereby augmenting but not replacing human review.

Because the template is intended to be forked and adapted by diverse users, the workflow must be safe and optional. Shipping the workflow file but requiring Anthropic credentials and GitHub App installation ensures that forks do not see failures unless they choose to enable AI review. Users who do enable the workflow gain an immediate benefit: every PR opened or synchronized will receive a mechanical review that catches common issues before human reviewers engage. The dev.to article’s cost estimates—small PRs costing on the order of pennies and larger PRs tens of cents per review—indicate that for typical open-source Rust contributions, the token cost per PR is modest, especially when using a mid-tier Claude model.[7] The workflow can tune model and `claude_args` to control cost by limiting review rounds and selecting the appropriate model, as demonstrated in Anthropic’s examples where `--max-turns 5` and `--model claude-sonnet-5` are used.[4] This tunability allows template owners to balance depth of review against cost.

##### Recommendation

The recommendation for this member is that `rs-launch-blueprint` ships `.github/workflows/claude-code-review.yml` implementing automatic PR review with `anthropics/claude-code-action@v1`. The workflow should:

1. Trigger on `pull_request` events with types `opened`, `synchronize`, and optionally `ready_for_review` and `reopened`, to review new PRs and updated commits.[5][8]  
2. Run on `ubuntu-latest` and `macos-latest`, aligning with the template’s OS matrix.  
3. Grant minimal permissions: `contents: read`, `pull-requests: write`, and `id-token: write` if Workload Identity Federation is used.[5][8][12]  
4. Include an `if` condition that skips execution when `github.event.pull_request.user.type == 'Bot'` or when `github.actor` matches known bots such as Dependabot, porting py’s skip guard unchanged.[5][15]  
5. Use `actions/checkout` to fetch the PR branch and `anthropics/claude-code-action@v1` with either `anthropic_api_key` or `claude_code_oauth_token` wired from secrets.[2][3][8][13]  
6. Provide a prompt that instructs Claude to review the current PR for code quality, potential bugs, security implications, and performance, referencing the repository name and PR number via `github` context variables, as in Anthropic’s examples.[5]  
7. Configure `claude_args` to restrict tools to GitHub CLI commands and inline comment MCP tools, and to limit review rounds for cost control (e.g., `--max-turns 5`).[4][5][8]  

A minimal example, adapted from Anthropic’s solutions and playbook, would look like:

```yaml
name: Claude Auto Review
on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      id-token: write
    if: github.event.pull_request.user.type != 'Bot'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 1
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            REPO: ${{ github.repository }}
            PR NUMBER: ${{ github.event.pull_request.number }}
            Please review this pull request with a focus on:
            - Code quality and best practices
            - Potential bugs or issues
            - Security implications
            - Performance considerations
          claude_args: |
            --max-turns 5
```

This example illustrates the pattern; the actual template should adjust `claude_args` and prompt text to Rust-specific standards and may add more sophisticated bot guards.

##### Ranked runner-up

The ranked runner-up for this member is to ship no automatic AI-assisted PR review workflow and rely solely on human review and static analysis tools such as `cargo fmt` and `clippy`. This option has the advantage of zero token cost and zero additional complexity in CI, and it mirrors the current behavior of `ts-launch-blueprint`. However, it fails to expose the capability that the owner’s mandate seeks to align across templates and misses the opportunity to offer Rust adopters a vetted path to AI-assisted review.

Another runner-up is to adopt `drillan/claude-pr-reviewer@v1` instead of the official action for PR review. While this action is attractive for its specialized review features and preconfigured dimensions, its third-party maintenance and reliance on a plugin add risk for a template intended to be stable and broadly applicable.[6] It might be appropriate for certain downstream adopters who specifically want its review style, but not as a template default.

##### Tradeoffs

The main tradeoff between the recommended and runner-up options is between capability alignment and minimalism. Using `anthropics/claude-code-action@v1` for automatic PR review aligns Rust with Python’s implementation and gives future TypeScript migrations a clear target, while offering downstream users an out-of-the-box AI review capability. It introduces token cost and dependency on Anthropic’s service, but these are bounded by model choice and `claude_args`, and they are opt‑in via secret configuration.[4][7][8][10] Omitting the workflow keeps CI simpler but preserves the current divergence and fails to honor the owner’s desire for capability-level alignment.

Choosing `drillan/claude-pr-reviewer` would trade vendor-maintained stability for specialized review features. Its plugin could provide richer analysis for certain languages, but it may not track Claude Code updates as closely, and it does not support the interactive `@mention` pattern in the same unified way as the official action.[6] For a template, the additional complexity and third-party dependency are unnecessary tradeoffs; advanced adopters can always add this action later.

##### Parameters

For this member, the template should own a parameter representing the presence and shape of the automatic AI-assisted PR review workflow. This can be expressed as:

`owns ai_pr_auto_review = enabled (anthropics/claude-code-action@v1, triggers: pull_request opened/synchronize/ready_for_review/reopened, bot-authorship skip guard: github.event.pull_request.user.type != 'Bot')`

It assumes existing parameters such as `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions`, and `target-os-matrix = ubuntu-latest, macos-latest`, but does not require any change to them. There is no `CONFLICT` line for this member.

##### Migration implications

For the automatic PR review workflow, migration implications for the template are limited to adding `.github/workflows/claude-code-review.yml` and documenting its behavior. Because ts-launch-blueprint currently lacks this workflow, a future migration project would need to add the file and configure it analogously, but that is out of scope here. For `rs-launch-blueprint`, the migration is from no AI workflows to a pair of optional ones.

##### Validation strategy

Validation for this member involves running the workflow in a realistic example. After configuring `ANTHROPIC_API_KEY` and installing the Claude GitHub App using `claude /install-github-app`, a template maintainer would open a PR with Rust code changes that include both obvious issues (e.g., an unchecked `unwrap` on user input) and subtle performance concerns (e.g., unnecessary allocations in hot paths).[2][4][8][13] When the PR is opened, the workflow should trigger, run `anthropics/claude-code-action@v1`, and post comments highlighting these issues. Acceptance behavior is that the workflow reliably runs on human-authored PRs, skips bot-authored PRs, and produces useful findings at a tolerable noise level. These checks are planned; actual execution would be part of the template’s integration process.

##### Confidence & re-verify trigger

Confidence in this member’s recommendation is high, because it aligns directly with Anthropic’s documented patterns and Python’s implementation, and because no Rust-specific constraints alter the workflow’s behavior.[4][5][8][10][16] Re-verify triggers include a major version bump of `anthropics/claude-code-action` (e.g., v2.0), changes in Anthropic’s guidance for bot guards or triggers, shifts in GitHub’s security model for Actions, or new evidence of cost, rate-limit, or false-trigger issues for public template repositories. If such changes occur, the workflow’s version pin, triggers, and guards should be revisited.

##### Sources

This member’s analysis draws primarily on Anthropic’s Claude Code Action documentation, including the “Automatic PR Code Review” solution and setup guide, which specify workflow structure, prompts, and permissions; on the Claude Code Playbook describing `anthropics/claude-code-action@v1` as the official action with GA status; on the GitHub Marketplace entry and Releases page that confirm its maintained, versioned nature; on Claude Academy and Code Review docs that contextualize automated review; on the security documentation for bot guards; and on practitioner write-ups like the dev.to and Blink blog articles that show real-world automatic review workflows and cost considerations.[1][2][3][4][5][7][8][9][10][11][13][15][16]

#### `@mention` assistant workflow (`.github/workflows/claude.yml`)

##### Landscape

The `@mention` assistant workflow corresponds to an interactive AI agent that responds to explicit mentions in PR or issue comments, offering explanations, code changes, or other assistance in context. In the Claude ecosystem, the established pattern is to use `anthropics/claude-code-action@v1` configured with a `trigger_phrase` (default `@claude`) and no explicit `prompt`, allowing the action to auto-detect interactive mode.[2][4][8][10] The Claude Code GitHub Actions documentation explains that mentioning `@claude` in a pull request or issue comment triggers the action to analyze code, implement changes, and push commits, and that workflows can also be configured with a `prompt` to run automatically on any GitHub event.[2] The Claude Academy lesson describes a workflow where the action listens for `@claude` on PR comments and issue comments, with inputs such as `trigger_phrase` and `prompt`, and shows a core step using `anthropics/claude-code-action@v1` with `trigger_phrase: "@claude"` and `prompt: "Your instructions here"`.[4]

The Playbook and Blink blog further elaborate on the interactive pattern. The Playbook notes that the action can implement features from issues and respond to `@claude` mentions, turning issues into pull requests and executing tasks requested in comments.[8] The Blink article describes interactive `@claude` mentions as a mode where tagging `@claude` anywhere in a PR or issue comment causes Claude to read the thread, understand context, and either implement the requested change or explain why it cannot, with no terminal session required.[10] These descriptions position the `@mention` workflow as a conversational agent integrated into GitHub discussions, distinct from but complementary to automatic review.

Third-party alternatives, such as `drillan/claude-pr-reviewer`, also support interactive review when `@claude` is mentioned in PR comments, but this is mediated by a plugin rather than by the raw Claude Code Action.[6] Bespoke workflows outlined in the dev.to article use CLI invocations with prompts and manual posting but do not support natural `@mention` triggers in comments; they require explicit job runs.[7] GitHub Agentic Workflows with Copilot could, in principle, support interactive assistance via comments or actions, but they are not currently configured in the template family and would introduce a separate AI stack.[12]

##### Principles and implementation

The `@mention` assistant workflow must embody the principle that AI assistance is explicitly requested, contextual, and bounded by repository permissions. Unlike automatic review, which triggers on PR events without direct user request, the assistant workflow should only run when a human user intentionally invokes `@claude` in a comment or issue description. The Claude Code GitHub Actions documentation states that mentioning `@claude` in PR or issue comments causes the action to respond in context, and the Claude Academy lesson shows how workflows can listen for `@claude` on PR comments and issue comments using `issue_comment` triggers and filters on the comment body.[2][4] The Playbook and Blink blog emphasize that the same action can be used for `@mention` assistance by configuring `trigger_phrase` and leaving `prompt` unspecified, allowing the action to parse the conversation and decide what to do.[8][10]

Security considerations are central here. The Claude Code Action security documentation notes that the action can only be triggered by users with write access to the repository by default, and that bots cannot trigger it unless explicitly allowed via the `allowed_bots` parameter.[15] It cautions that on public repositories, if `allowed_bots` is set to `'*'` and workflows listen to events such as issue commenting, external GitHub Apps could invoke the action with prompts they control, potentially leading to unauthorized or malicious AI activity.[15] Therefore, the assistant workflow must avoid broad `allowed_bots` overrides and rely on the default behavior where only human users with appropriate permissions can invoke Claude via comments.

Implementation in the Rust template should follow Anthropic’s pattern. The workflow should trigger on `issue_comment` and `pull_request_review_comment` events of type `created`, with conditions that check whether the comment body contains `@claude` and that the comment’s author is not a bot (`github.event.comment.user.type != 'Bot'`). The workflow can optionally support issue-body triggers by listening to `issues` events and checking the initial issue body for `@claude`, but this should be considered carefully because it may blur the line between comment-based and description-based requests. The core step should use `anthropics/claude-code-action@v1` with `trigger_phrase: "@claude"` and omit `prompt`, unleashing the action’s interactive mode. Authentication inputs follow the same pattern as the automatic workflow: either `anthropic_api_key` or `claude_code_oauth_token` from repository secrets.[2][3][8][13]

As with the automatic workflow, crate-centric fitness gates are inapplicable here. The action is not a Rust crate; it runs in CI. Its license and OS support are appropriate; it imposes no MSRV, RustSec, or runtime coupling on the Rust project.[1][8][9

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action)
- [Claude Code GitHub Actions - Claude Code Docs](https://code.claude.com/docs/en/github-actions)
- [Claude Code Action Official - GitHub Marketplace](https://github.com/marketplace/actions/claude-code-action-official)
- [GitHub Actions and Code Review - Claude Academy](https://academy.claude.com/courses/claude-code-in-action/github-actions-and-code-review)
- [Custom Pr Review Checklist](https://github.com/anthropics/claude-code-action/blob/main/docs/solutions.md)
- [Claude PR Reviewer · Actions · GitHub Marketplace](https://github.com/marketplace/actions/claude-pr-reviewer)
- [Automate Code Reviews on Every PR with Claude ...](https://dev.to/myougatheaxo/automate-code-reviews-on-every-pr-with-claude-code-github-actions-599p)
- [GitHub Actions | Claude Code Playbook](https://ao92265.github.io/claude-code-playbook/docs/github-actions/)
- [Claude Code Action - GitHub Marketplace](https://github.com/marketplace/actions/claude-code-action)
- [Claude Code in GitHub Actions: Automate PR Reviews and Bug Fixes](https://blink.new/blog/claude-code-github-actions)
- [Releases · anthropics/claude-code-action](https://github.com/anthropics/claude-code-action/releases)
- [Authentication | GitHub Agentic Workflows](https://github.github.com/gh-aw/reference/auth/)
- [claude-code-action/docs/setup.md at main - GitHub](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md)
- [claude-code-action/docs/configuration.md at main · anthropics/claude-code-action](https://github.com/anthropics/claude-code-action/blob/main/docs/configuration.md)
- [security.md - anthropics/claude-code-action](https://github.com/anthropics/claude-code-action/blob/main/docs/security.md)
- [Code Review - Claude Code Docs](https://code.claude.com/docs/en/code-review)

## Cost

Total: $0.6702

---


## Gemini Results

---
prompt: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
mode: all_deep_research
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260909-003249-bf15cd42494140b6
created_at: 2026-09-09T00:32:49.668391
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
```

# Implementation Plan for AI-Assisted Review Workflows in rs-launch-blueprint

### Landscape

The AI-assisted repository automation category governs how large language models interact directly with continuous integration pipelines, specifically concerning the review of code changes and the contextual triage of issues. The survey method mandates mapping the current ecosystem into three distinct bins to ensure a comprehensive evaluation of available solutions, preventing reliance on prior familiarity alone. The first bin represents the built-in or first-party toolchain, predominantly occupied by GitHub Copilot Code Review, which integrates as a native, assignable reviewer directly within the GitHub pull request user interface. The second bin comprises established industry standards, characterized by dedicated external vendors such as CodeRabbit and Qodo (formerly CodiumAI), which operate via hosted GitHub Apps and manage the review lifecycle entirely on their proprietary infrastructure. The third bin encapsulates up-and-comers, most notably the `anthropics/claude-code-action` family and open-source equivalents like OpenCode, which function as command-line interface (CLI) backed agentic integrations that execute directly within the repository's own continuous integration runners rather than relying on external hosted platforms.

Authority for evaluating these candidates is established through a diverse synthesis of cybersecurity analyses, ecosystem documentation, and independent security research. Security posture and operational boundaries are rigorously defined by Microsoft Threat Intelligence reports detailing how AI agents process untrusted GitHub content and the inherent risks of credential exfiltration during continuous integration [cite: 1]. Further authority is drawn from independent security researchers, such as RyotaK at GMO Flatt Security, whose published vulnerabilities and subsequent patches define the contemporary threat model for repository-integrated large language models [cite: 2, 3]. Ecosystem behavior and standard practices within the Rust language community are grounded in the documentation maintained by the authors of dominant release automation tools, most notably Marco Ieni's `release-plz` project, which represents the current standard for Rust crate distribution and versioning automation [cite: 4]. Official GitHub documentation regarding the security models of `pull_request` versus `pull_request_target` events provides the foundational constraints for evaluating public template safety [cite: 5, 6].

Practice evidence demonstrates that mainstream, well-regarded Rust projects overwhelmingly rely on automated bots for dependency management and release engineering, creating a highly specific environment that an AI reviewer must navigate. Projects such as `tokio-console` and `systeroid` heavily adopt a combination of `dependabot[bot]` and `renovate[bot]` for dependencies, alongside `release-plz[bot]` for publishing and changelog generation [cite: 4, 7, 8]. This creates an environment where a significant percentage of pull requests are entirely bot-authored. Furthermore, Anthropic explicitly utilizes `claude-code-action` internally to deduplicate and triage issues on its own production repositories, demonstrating high confidence in its agentic workflow capabilities and providing robust evidence of its dependability in active development environments [cite: 9]. The transition toward AI-assisted code review is driven by systemic bottlenecks; industry data indicates that teams lose substantial hours weekly on pull request review latency, a problem exacerbated as AI coding assistants generate code faster than human maintainers can evaluate it [cite: 10, 11].

| Category Bin | Candidate Tooling | Architectural Paradigm | Primary Execution Environment |
| :--- | :--- | :--- | :--- |
| Built-in / First-Party | GitHub Copilot Code Review | Native platform feature, assignable UI reviewer | GitHub-hosted infrastructure (closed state) |
| Established Standard | CodeRabbit, Qodo, Greptile | Hosted SaaS via OAuth GitHub App installation | Vendor-managed cloud infrastructure |
| Up-and-Comer | `claude-code-action`, OpenCode | Containerized GitHub Action calling LLM SDKs | Repository's own CI runner (e.g., `ubuntu-latest`) |

Judging for fit over abstract best, `rs-launch-blueprint` operates as a public template repository intended to stamp out command-line interfaces, libraries, and web services. Template repositories face unique operational constraints: they are widely forked, rely heavily on community contributions, and must minimize setup friction for the downstream consumer. Third-party GitHub Apps, such as CodeRabbit or Qodo, require downstream consumers to undergo organizational OAuth installations, manage external vendor subscriptions, and route their proprietary code through third-party servers [cite: 11, 12]. Conversely, a GitHub Action triggered by a standard workflow file only requires a single API key secret, providing a superior fit for a standalone, portable blueprint designed for immediate out-of-the-box utility [cite: 13]. The evaluation of these candidates is strictly against this template's use case and the precedent set by `py-launch-blueprint`, prioritizing zero-friction portability and explicit security over proprietary dashboards.

### Principles and implementation

The implementation of AI-assisted code review and on-demand agentic workflows across the organization's template blueprints must represent an agreed-upon Policy. This shared engineering principle requires that downstream consumers of any `*-launch-blueprint` template encounter a consistent AI automation experience, identical security guardrails against prompt injection, and equivalent operational capabilities, regardless of whether they are working in Python, TypeScript, or Rust. The essential behaviors dictate that the automated pull request review mechanism acts as a human-in-the-loop assistant, providing rapid feedback on logic and security without assuming the authority to unilaterally approve merges [cite: 14, 15]. Simultaneously, the `@mention` assistant must execute on-demand issue triage and code modifications safely within the bounds of least-privilege continuous integration runners.

The most critical observable acceptance criterion for both workflows is absolute public-fork safety. Because template repositories are designed to be forked by untrusted external users, the implementation must completely isolate repository secrets from malicious pull requests and external issue comments. An attacker opening a pull request from a fork must not be able to execute code that accesses the Anthropic API key or the repository's GitHub token [cite: 13, 16].

`BASELINE-REVIEW: F051, F052 — Policy — Adopt bundled AI workflows across templates — The TypeScript template's omission of these workflows represents accidental drift or a missing capability rather than a justified architectural departure. Adopting the bundled workflows in rs-launch-blueprint strictly aligns with py-launch-blueprint, reinforcing the shared engineering principle of baseline AI automation across the organization's foundational templates. The Python implementation serves as the definitive reference architecture.`

While the architectural pattern of utilizing the containerized `anthropics/claude-code-action` is shared with `py-launch-blueprint`, the bot-authorship skip guard logic represents a justified and necessary ecosystem difference. The Python ecosystem predominantly utilizes GitHub's native Dependabot for dependency updates. Consequently, the Python template's guard logic exclusively filters out `dependabot[bot]` to prevent the AI from reviewing mechanical dependency bumps. The Rust ecosystem operates differently, relying heavily on `release-plz` for semantic versioning, changelog generation via `git-cliff`, and automated publishing to `crates.io`, alongside `renovate` for complex workspace dependency management [cite: 4, 17, 18]. If an AI review workflow evaluates the automated `Cargo.toml` version bumps and release pull requests generated by `release-plz`, it creates recursive review loops, wastes API rate limits on mathematically proven version changes, and dilutes the signal-to-noise ratio for maintainers. Therefore, the Rust template's skip guard must explicitly exclude `release-plz[bot]` and `renovate[bot]` in addition to `dependabot[bot]`.

When comparing architectural alternatives, utilizing a standard `pull_request` event trigger is vastly superior to the `pull_request_target` event for this specific capability. While `pull_request_target` is often improperly used to grant fork pull requests access to repository secrets, it inherently executes within the context of the base repository, allowing untrusted code to potentially exfiltrate credentials [cite: 6, 16]. By strictly relying on the standard `pull_request` event, the architecture ensures that forks operate with read-only tokens and are denied access to the `ANTHROPIC_API_KEY`. For the `@mention` workflow, relying on Anthropic's built-in actor checks ensures that even if a malicious user opens an issue containing a prompt injection payload, the action halts execution immediately upon detecting that the actor lacks repository write access, preserving the security principle [cite: 19].



### Recommendation

The `rs-launch-blueprint` template will ship an automatic AI-assisted PR code-review workflow and an `@mention`-triggered AI assistant workflow combined as a single, cohesive bundle. This stack directly fulfills the requirement to match the `py-launch-blueprint` precedent while introducing necessary Rust-specific bot-authorship skip guards. Both workflows are powered by `anthropics/claude-code-action`, utilizing the identical version pin to guarantee deterministic behavior across the organization's templates.

### Members

#### PR Code Review Workflow

##### Landscape
The landscape for automated pull request review has evolved rapidly from rudimentary static analysis linters into sophisticated semantic reasoning engines. The market is currently bifurcated into fully managed hosted applications and self-hosted action runners. Hosted applications analyze the codebase asynchronously and post comments via the GitHub API, assuming control over the entire review interface [cite: 10, 12]. Conversely, action runners embed the large language model runtime directly within the execution environment of the continuous integration pipeline, affording the agent direct, localized access to the file system, dependency graphs, and test execution results. For a public template repository where downstream users demand full sovereignty over their continuous integration infrastructure, action runners represent the most viable path.

##### Principles and implementation
The implementation acts as a synchronous review filter that evaluates the logic and security implications of code modifications prior to human intervention [cite: 15]. In the Rust ecosystem, this workflow must strictly avoid evaluating the voluminous, automated boilerplate generated by release engineering tools. A typical continuous integration pipeline in Rust executes `cargo fmt` for styling, `cargo clippy` for linting, and `cargo semver-checks` for application programming interface compatibility [cite: 4, 7]. Permitting an AI agent to expend token context limits reviewing a pull request authored by `release-plz`—which exclusively contains mechanical `Cargo.toml` version increments and markdown changelog updates—is an inefficient allocation of resources [cite: 20]. The implementation guarantees public-fork safety by relying on the inherent restrictions of the `pull_request` event trigger; when a fork initiates the workflow, GitHub provisions a read-only token and securely redacts the `ANTHROPIC_API_KEY`, causing the action to gracefully fail closed without executing untrusted code [cite: 13, 16].

##### Dominant choice
CodeRabbit is widely recognized as the dominant industry standard for automated pull request reviews, largely due to its broad platform compatibility and zero-configuration OAuth installation process that appeals to enterprise organizations seeking immediate deployment [cite: 10, 12].

##### Qualified shortlist
- `anthropics/claude-code-action`
- `qodo-ai/pr-agent`

##### Excluded by gate
The standard Rust crate fitness gates—including minimum supported Rust version (MSRV) policies, RustSec advisory checks, and binary size evaluations—are strictly inapplicable to this candidate. The item being evaluated is a GitHub Action executed via a containerized Node.js runner, defined entirely by YAML configuration, rather than a compiled Rust library or binary crate published to crates.io.
GitHub Copilot Code Review is excluded by the open-source compatibility gate; its reliance on proprietary, seat-based Enterprise licensing prevents it from being seamlessly integrated into a public template intended for frictionless community adoption [cite: 10, 21].

##### Up-and-comers
OpenCode is an emerging, model-agnostic command-line coding agent that offers significant flexibility by decoupling the workflow from a specific proprietary vendor, though it currently lacks the turnkey GitHub Actions integration maturity of established competitors [cite: 22].

##### Fit for this template
The `anthropics/claude-code-action` demonstrates a superior fit for this specific template architecture. It operates entirely on the repository's own infrastructure, requiring only the provisioning of a single repository secret (`ANTHROPIC_API_KEY`) rather than a complex organizational OAuth application installation [cite: 12, 13]. This aligns perfectly with the fork-and-build distribution model of template repositories, ensuring that downstream consumers can activate the feature immediately upon cloning the blueprint. 

| Metric | Value | Source Interpretation |
| :--- | :--- | :--- |
| **Stars** | 8,813 | Indicates strong community adoption and visibility [cite: 23]. |
| **Forks** | 2,131 | Demonstrates extensive usage in custom CI pipelines [cite: 23]. |
| **Open Issues** | 776 | Reflects active usage and continuous feedback loops [cite: 23]. |
| **Last Release** | `v1.0.218` (Active) | Shows ongoing maintenance and rapid patch deployment [cite: 24, 25]. |
| **License** | MIT | Fully compatible with the template's dual-license requirement [cite: 23]. |

##### Recommendation
Implement `.github/workflows/claude-code-review.yml` utilizing `anthropics/claude-code-action@v1.0.175`. The workflow must be configured to trigger on `pull_request: types: [opened, synchronize]` and incorporate a robust conditional block (`if:`) that explicitly checks the `github.actor` against a denylist containing `dependabot[bot]`, `renovate[bot]`, and `release-plz[bot]`.

##### Ranked runner-up
The `qodo-ai/pr-agent` serves as the primary runner-up, offering analogous open-source flexibility and robust analysis, but adopting it would fundamentally diverge from the established `py-launch-blueprint` precedent, breaking the organizational policy of unified tooling [cite: 10, 12].

##### Tradeoffs
Deploying the agent directly within GitHub Actions presents specific operational tradeoffs. The workflow concurrently consumes GitHub Actions compute minutes and Anthropic application programming interface credits, linking operational costs directly to pipeline execution frequency [cite: 26]. Furthermore, massive monolithic repositories present a risk of exceeding maximum context limits or token budgets during the diff analysis phase; mitigating this requires administrators to aggressively apply path filters within the workflow configuration to exclude non-essential directories from the review scope [cite: 13].

##### Parameters
- `assumes rust-edition = 2024`
- `assumes msrv-policy = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI"`
- `assumes target-os-matrix = "ubuntu-latest, macos-latest"`

##### Migration implications
The integration introduces a new file, `.github/workflows/claude-code-review.yml`, to the template structure. Downstream repository administrators will be required to securely generate and store an `ANTHROPIC_API_KEY` as an Actions repository secret to activate the review capabilities.

##### Validation strategy
- **Check 1 (Planned):** Initiate a pull request with the author signature spoofed to `release-plz[bot]` containing a mechanical `Cargo.toml` version increment. Verify that the GitHub Actions workflow triggers but safely skips the execution job due to the explicit actor guard logic, preventing a recursive API call [cite: 4].
- **Check 2 (Planned):** Open a standard, human-authored pull request introducing a deliberate, subtle logic flaw in the Rust source code. Verify that the workflow completes execution and successfully posts an inline, context-aware code review comment on the pull request thread.

##### Confidence & re-verify trigger
Confidence in this component is High. The underlying action is actively maintained and deployed in high-visibility production environments. The primary trigger to re-verify this decision is the issuance of a major security advisory for the `v1` lineage by Anthropic, or the deprecation of the current endpoint in favor of a distinct `v2` action family.

##### Sources
The analysis of candidate alternatives and their respective architectures relies on comprehensive industry benchmarking reports evaluating AI code review tools [cite: 10, 14, 27]. Security boundaries and event trigger protocols are derived from GitHub's official documentation regarding continuous integration protection mechanisms [cite: 6, 13, 16].

#### Mention Assistant Workflow

##### Landscape
The landscape for on-demand agentic workflows encompasses both local developer environment integrations, such as chatbot panels in integrated development environments, and remote, repository-integrated triggers. The `@mention` architectural pattern allows developers and maintainers to summon artificial intelligence contextually within specific GitHub issues or pull request discussion threads, enabling the agent to explain complex code architectures, triage incoming bug reports, or author targeted fixes directly on a branch [cite: 27, 28]. 

##### Principles and implementation
A zero-trust architecture is absolutely non-negotiable when implementing `@mention` triggers on public repositories. In an open-source template environment, any unauthenticated user on the internet possesses the ability to open an issue and type the trigger phrase `@claude`. If the continuous integration workflow is improperly configured to process this untrusted input indiscriminately, it exposes the repository to severe prompt injection attacks. Security research has demonstrated exploits where a malicious actor embedded instructions within an issue comment to read sensitive environment variables, such as `/proc/self/environ`, resulting in the catastrophic exfiltration of OpenID Connect tokens and API keys [cite: 1, 2, 3]. To preserve the fundamental principle of repository security, the implementation must rely on Anthropic's hardened, built-in actor verification checks. This mechanism dynamically validates that the external user initiating the comment possesses explicit write access to the repository before loading sensitive secrets or executing the language model SDK [cite: 19].

##### Dominant choice
The `anthropics/claude-code-action` stands as the dominant mechanism for direct, in-repository GitHub issue and pull request `@mention` integrations. Its dominance was further solidified after integrating rigorous threat mitigations in mid-2026, which effectively neutralized the primary prompt injection vectors that previously plagued autonomous agents [cite: 3, 28, 29].

##### Qualified shortlist
- `anthropics/claude-code-action`

##### Excluded by gate
Standard Rust crate fitness gates, encompassing metrics such as unsafe code posture and compile-time evaluations, are entirely inapplicable to this candidate, as the workflow is executed via a declarative GitHub Actions YAML file utilizing a JavaScript-based action runner rather than a native Rust compilation process.

##### Up-and-comers
Git AutoReview represents an alternative, local-first approach utilizing a Visual Studio Code extension. While it mitigates the risks associated with cloud-hosted prompt injections by keeping execution local and preventing the auto-publishing of comments, it fundamentally shifts the architecture away from continuous integration, making it unsuitable for a centralized, repository-level template requirement [cite: 11].

##### Fit for this template
This on-demand workflow provides exceptional utility for maintainers of template-derived projects, empowering them to rapidly convert abstract bug report issues into actionable, code-backed pull requests with minimal context switching. By meticulously restricting the GitHub Actions event triggers specifically to `issue_comment`, `pull_request_review_comment`, and `issues`, the configuration ensures that the agent ignores extraneous repository activity, conserving compute resources and preventing accidental activations [cite: 30, 31]. The active maintenance of the underlying action, demonstrated by the resolution of 776 open issues [cite: 23] and the rapid deployment of critical security patches within four days of vulnerability disclosure [cite: 29, 32], further solidifies its fitness for production templates.

##### Recommendation
Implement `.github/workflows/claude.yml` utilizing `anthropics/claude-code-action@v1.0.175`. 
- **Trigger Gate:** The workflow must be explicitly scoped to trigger exclusively on `issue_comment: types: [created]`, `pull_request_review_comment: types: [created]`, and `issues: types: [opened, assigned]`. 
- **Security Guard:** The workflow configuration must never define or enable the `allowed_non_write_users` parameter, ensuring the built-in write-access actor verification remains strictly enforced [cite: 19].

##### Ranked runner-up
No viable runner-up exists that preserves the required engineering principle. Discarding this workflow from the bundle breaks the mandated parity with `py-launch-blueprint`.

##### Tradeoffs
Deploying `@mention` listeners on public repositories exposes the continuous integration pipeline to nuisance triggers. Although the action gracefully halts execution when an unauthorized, non-write user attempts an `@mention` invocation, the GitHub Actions infrastructure is still forced to allocate and spin up an `ubuntu-latest` runner for several seconds to perform the authorization evaluation, consuming marginal, yet cumulative, continuous integration minutes over time [cite: 13, 25].

##### Parameters
- `assumes rust-edition = 2024`

##### Migration implications
The integration introduces a new file, `.github/workflows/claude.yml`, establishing the event listeners and permission scopes necessary to operate the on-demand assistant.

##### Validation strategy
- **Check 1 (Planned):** Operating from an external GitHub account devoid of repository write access, open a new issue containing the specific trigger phrase `@claude`. Verify that the GitHub Action provisions a runner, evaluates the actor's permissions, and halts execution gracefully (exit code 0) without exposing the API key to the environment or initiating an outbound LLM API call.
- **Check 2 (Planned):** Operating from an authorized maintainer account, post a comment stating `@claude fix this typo` on an active pull request. Verify that the action interprets the context, executes the code modification, and successfully pushes a fix commit to the branch.

##### Confidence & re-verify trigger
Confidence in this integration is High. The continuous monitoring of GitHub's default token permission models is required; any upstream modification by GitHub to the default `GITHUB_TOKEN` capabilities for `issue_comment` events across public templates must trigger an immediate re-verification of the workflow's security boundaries.

##### Sources
The structural configuration and precise event triggers for the on-demand workflow are sourced from comprehensive implementation guides and Anthropic's technical documentation [cite: 28, 30, 31]. The rigorous security posture and threat models mitigating prompt injection attacks rely heavily on disclosed vulnerability reports and documented platform safeguards [cite: 3, 19, 32].

### Compatibility

The two core workflows—the PR Code Review job and the `@mention` Assistant job—are engineered to be deployed concurrently as an integrated bundle. They demonstrate flawless compatibility by utilizing the identical version of the GitHub Action (`anthropics/claude-code-action@v1.0.175`) and consuming the exact same repository secret (`ANTHROPIC_API_KEY`). Because they operate via mutually exclusive GitHub event triggers (with the review job bound to `pull_request` and the assistant bound to `issue_comment` and `issues`), they inherently prevent execution collisions, workflow race conditions, or lock contention on the underlying continuous integration runners, ensuring stable, parallel operation [cite: 13, 30, 31].

### Parameters

- `assumes rust-edition = 2024`
- `assumes msrv-policy = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI"`
- `assumes target-os-matrix = "ubuntu-latest, macos-latest"`
- `assumes license = "MIT OR Apache-2.0"`

### Migration implications

The implementation requires the injection of two distinct, highly configured YAML files into the template's `.github/workflows/` directory:
1.  `.github/workflows/claude-code-review.yml`
2.  `.github/workflows/claude.yml`

Because the underlying tool functions as an autonomous agent that reads and interprets repository state, its effectiveness is intrinsically linked to the repository's structural clarity. Therefore, it is strongly recommended that downstream consumers provide explicit structural context within the repository. Establishing an architecture document, utilizing an `ADR` (Architecture Decision Record) directory, or maintaining a dedicated `CLAUDE.md` instruction file provides critical guardrails, guiding the AI's behavior and drastically reducing the likelihood of the model hallucinating non-idiomatic Rust patterns or violating established project conventions [cite: 33, 34].

### Validation strategy

To prove the security principles and operational requirements hold within a realistic execution environment, the following command sequences and verifiable outcomes will be executed against a staging fork of `rs-launch-blueprint`:

1.  **Fork Security Validation:**
    - Execute `gh repo fork --clone` to simulate an external contributor.
    - Create a malicious pull request containing a prompt injection payload attempting to print the `ANTHROPIC_API_KEY` to the runner console.
    - *Expected Behavior (Planned check):* The `pull_request` trigger correctly initiates the action. However, because the event originates from an untrusted fork, GitHub natively strips the sensitive repository secrets from the execution context. The action receives an empty key payload and halts immediately, definitively preventing credential exfiltration [cite: 13, 16, 35].
2.  **Bot Guard Validation:**
    - Simulate a mechanical release pull request by executing `git checkout -b release-plz-v1.0.1`, followed by `git commit --author="release-plz[bot] <...>" -m "chore: release"`, and finally `gh pr create`.
    - *Expected Behavior (Planned check):* The GitHub Action evaluates the specific conditional block `if: github.actor != 'release-plz[bot]'`. The evaluation returns false, and the continuous integration pipeline skips the job entirely, successfully avoiding a recursive API execution loop on an automated changelog [cite: 4].
3.  **Mention Authorization Validation:**
    - Utilizing a secondary GitHub account entirely devoid of repository write privileges, create a new issue comment containing the explicit phrase `@claude`.
    - *Expected Behavior (Planned check):* The action initiates the run sequence, performs a real-time actor validation check against the repository's collaborator matrix, formally denies authorization, and exits cleanly with code 0 without executing the vulnerable language model SDK [cite: 19].

### Confidence & re-verify trigger

Overall confidence in this selected stack and its configurations is High. The most severe vulnerability identified in early 2026—where sophisticated bot accounts could successfully spoof authorization mechanisms and execute arbitrary prompt injections to steal OpenID Connect tokens—was patched definitively in `v1.0.94` [cite: 3, 29]. By rigidly setting the version pin to `v1.0.175`, the architecture guarantees execution within a hardened runtime environment. The primary operational re-verify trigger is the continuous monitoring of Anthropic's specific security bulletins for the `claude-code-action` repository; any newly published Common Vulnerabilities and Exposures (CVE) regarding prompt-injection sandbox escapes must mandate an immediate, synchronized version bump across the `rs`, `py`, and `ts` templates to maintain cross-ecosystem security parity.

### Sources

All source citations utilized to formulate the architectural decisions, establish security boundaries, and evaluate ecosystem constraints are integrated directly inline throughout the body of this report.

**Sources:**
1. [microsoft.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEwfcyHSZJd4dh4YVAt9buYHWLzPR1FzQ8N04JD4GJbOO9WtTNZpxEYamdlZp24kPbAu1jaCx_C1V1N6HX_0mr9CiFNJghUVJBLDX5ZDMbNjxgK47_CjbkaEkT1tuS5gaQ4J_bJusDDuqR325Tuy88Z3fPlotLg79d96Iq7_OMpqosDArB7Iz4sffgaI3utS8aJU39KcMCtOwe12XKnqHaZI6Y8wqwO0_rwkN7Ztbs=)
2. [flatt.tech](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHj945qqfl2mAJ6PoOvZVedXV3CMRME3A5-AJDxMAfypUOYQ8kb9P__MopvRi62-j6RFcF44fTftMdEk4t-ESkTi2dSoqLvR5_ZFvKhYrsFmb4V9VN213YgiKUyckVe1pqT9JoFNXNJipt--22B3nNgqUiCuCBUCzeKJ2vZqpQqc1_XWQHnZNU11_l55jPekGykEvpoYBktapU=)
3. [thehackernews.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHumbjuwzu0iSO1qMynvt3FqY00cDZwtP3LRAKb3ycZ6UDqn1uNSLVYbjymWJ_ksrFtmpThY0XxDb377LuRXrzTao2AnD3cqUmlv6kePOxj8afAmYGcBlvYslQevKSnmlHRFMNioY6Zol-7FoDWz4mfvJqKEZ8G7VLXsPQzASUBtCO6Dg==)
4. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHeZBiR1QL2Va1WZZM_XYnqmbwa1FYlNtDLi2hIirfyloubp5vsuUFxoaoKuR9MzzP4dOqQPbPB2gTiaBFECgIWwGBXpEU6dvBwkPAfs7LP5B-qPNs5qXpcSkC4cOS8Y2I=)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF87iZLoZk1RXnJHMzvhzVuV8jBZ3ghwNMFwSHF1HvOHFumel2q05lrE69veYCAJJjwGIOJ01SORcPEbXxQF5Yu1VI2eIU5o9jBqVSFiU-NniE4LPxZCwfPPdD4kKVIQoiPz_p4lnZ19-unDzzqcgiwKByk9bgrxL09dbFEsT3ox5kD-DwpcMbFKswYNt6s-3Op8IpF)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHNxnuHj7dWMzb9JvL5FPHd2fHpW4gtjbA8PNqjtDxlHaKq2NAmXDnlkrnOz5qemgF5i-ayDM5WzzMHEYWjOlGbsD3E4BM_1lM4AWDX1aabXkC6YiZrWGpcjYlpiDumeO5zGI9fOGThQoYtOMZ6OpSdE8Vcfy8LImuywTzUp3vo9lpmWOizZ7RF8AUR4IEW)
7. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHjZoov6SbOlkpKtNCQ-SmujMcLPw_F5L-9b2nvyLogplR1fgOJ_nPWMMijrtAeLMJynv52mJvv8dcHCQ4AG0KrDWHROVR4_q9XCbZ3_7M=)
8. [orhun.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGYu7e9xqXlNcTJdey84zkqkBKHHl8b4pTbj_bYt38uBFhHENrSi_Nt88gJXWkSy7O_xBE93Ytlgb_i1UEnAb92-cUzH_6nspUXIxXiT9ysxUTPMXvdCrIGZ2ry94zOrPD1B6i2tQ==)
9. [augmentcode.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEfvK8zYlAOLqGzyDX5evJ4jcy40Xl4cNuLPB1UV6kbEeGRVlBEyFULR3KBWnWfRcv2I2Rm5BDLQj63ChjeGKra5CY6xhImTMEtpASCBcktJMWb-DWhQNqVlClfoi_3KwSl5EfeREz1k1jBdxLU3A==)
10. [composio.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFrYDouAcQgdOydOr81wUzB44sI9Y5ySIDYXiFqeAPnQbDKoRsTttr3OAylDdIeHij0hlDW19AwalTUA_SPTU77NOOOH62MPNn35eAzhuQVfvYJKHK0I1Tgq_I2T2TN4DP_JoSbSqe2i1ck5IrK11Y4WSZByERs3LzDUKJC)
11. [gitautoreview.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGOIXrBs1tShmAjhKK00izhisYGYFQz5B9lOV-ym9LCqJJmwzyaCgwI2YH-daVaKg0I0ckvFQwtPfDKvuc5FAg47_Nec8WManY2bp9C3s-Mi3lYfzGZgD6jvd7NB_WLb-TLAo0aqs2ATui2gTfptA==)
12. [kunalganglani.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEk8dSwVN8jlPToVsWnAfPMC348IiHnYTX9fZhAJfdmBUaMVWbeZHHGtFqNUtoMFV7UEIBwiFoTMO4dEVTNcBIHh1Xj-ALWjIKnu7oyz-XdFzaQcEGzcz2vrJ6XTKNZeeHA7HVJi_6x9cWlrX3_IAWqKHl5NYsv)
13. [systemprompt.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIE86PRNNl_aHMAgn31JR_3qVH0aS8fo4PQ6uveRUXgBZcNfT80DLnp4-i7yD8CauUIKk-wLYgLTXcy1ZhXS5G7n52p5DXli3DW830fG8rGHmfs_ffoWzry7raPPnplPaUAmxRxK3QWe4nsPELq4c=)
14. [nimbalyst.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHjYM-uuSB_M-21vyp9vmWPQReJv1v-CzopzU7EM-aBhCRAjwF7efUdFU5O2yBqZh1oYdfS4lB7zppgIjAseg8dJXW-TuEnq4H7RvgXPO8tFqtNYirSQMX-VAJ5LiYgDte5q3y6CvYvuAhuXsmFIO27qygJC5K4UZVKt9bB9ZknXHE=)
15. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHDPk3_2uMCfYQqqqXmbFGjLwSEIU9w896w5N2Fk66jnAZf11Aw_7s4bBpcduE2tIxMKrNKCfv0Wc0VpULJ9xN9eVlUQ-fLbKG0Od_Rcl20ONuCwXd-QNJok6Pn8GHT9jcBeSYSCW-KxMN6qMPX6NSSDC9yTD1DpfMuvxJw8iapURvhuOxg)
16. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEr5SIwEypXIQVGv_fWK5hMsRfQOS7W1TT3xl_pSwUXDAoVlShiYoiuggh-LoMPxS2RXIHwZ4x5FHRpc0n3OVUNUil4zkuvBr3CvDHpNaQ1yp9AkOT9rW6hwAXJrH2XmEWmdLctjyF24sSO6PNx5jND2uYUnnY5II-kwXKZU6Tr5wFnd48BaltpWGiMLgHj-qsQpwJO2w==)
17. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFVVQ-KqOBUcFEVxUP2ACLHCy8sSPRmEzyLPZ1LeqrNkPtAxM8FZRjvy2A0Xa6lOYsJbDW1XosxkQe5uVsPL3Zbb3l8Qa6eam7vv1sVdgLkL0lK)
18. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGELXHbrMs_LcqV_YviOQFOGPDvO4rNhB1lj9ZXvAeUkhqwCk_c2RFIya2I-8mPc316BFv_dwLkt-vBWEgUtOJvI8uVvGzNxfDn3LWm9ugo2-HLKHDVWakLoWjLWv1qJw==)
19. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-d7qcgr7OIPASS9eNsG1lO2G6Kl4Ou3G1QZl9Usd_HY4z-59HoGHzAfrAqCjP8TC9ZhjofeHO1J1St6vP5gocUuPnkhnLKGXnMQdV73O2YqfVWZi0T9VA3oI4Cv1snmGJgFQ7TtaGUl5McUPFjVjS3P2l-cAER33Zz6G5tczKzCI=)
20. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHfQ62YXNnbiU-MxBGbhPDNEbJhEL5Tn8B43BWLyk7pt4eKbHz01ro_oWrO4VmJv9QHF_mz6_i2U7_Uyr6Eto6xhsK3x3tnaHUdyjL6w2cReQJJOtjBru3AzA==)
21. [sourcegraph.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFg9m3PxWOMYXiOO-36qWjL2RQYbKfdJq0sQHniab_Pzf6Goc8lffCefPLSU9ZNGyhQSRPy7zrYG_B2SJWYfm3QhE4dunYNrKj7w3N1kD4rUcZdFBtvqnl6h5r0zg9XA1bQGD1hFUT1ijvue93y9w==)
22. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHX4agnGNeOqzjks3ZbQnveFlJuNF9t9NpYfVOf94EEdGZETn9-F5y-JbMQYFACn9CajdkJMXZzSKN2lxZKRlVRXgVId-klisthX_40oQZz49jnPltu-fwwG0-NmR2dYsMa6YUKErJimPpA2JMzmXUCTJDELDJxRuIS4o-Rw7iaoiEzND6Crd-EerWsB5KJ3Euq3NwJ7kwxEyzt1w==)
23. [vercel.app](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGyNs-hT5FDNquaZSrXkH4DW5Pfh_eUeuRqU4fFoDynz9dujgD6pUdMi9QfXDZAoRcd00J1tRJQro53bvJi4p6xa2wc0Vk4syVm56kv6ZMbXEsX22pzR9acbTAU_88UX2ZuW6o3Tas8OtZhRPplD16Bn257LQ==)
24. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZQwgxv7-FXiWBVsKl_yFTpqRI_SP-YxQhxLJ89Scd2MNy1Qh08wVExtdMnX8ObCvppDKl8cmufN--CHT-okZnjm7QIjg9ocZIIPyu9XDNhfzpYig3DZKmY2xZj3ZugfVwIvi7PsEWpCdBUC5S)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5xHPMhXLjldWh3ReVS770h8K-2cGzC-yTX_-lsb0K4ZmC4E9bVTKHZ8SWebD8TXJ-rb2336Tmunn_wEMn93get2BQuKg4S_g0MxIjvtZn6J_dndGNroFiSzsE40RkYSrXuvKo632VmCnnEWxSwImsSA==)
26. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEFYWV4OK5ry139VHsvgPRTPunNYZaWLCeOnA0nnRcg9_9qmQ_rzeCj3jHfgVPil-jsfngoE8LRPH1ra7RKiTr0ZaFxCUxbGX2w9G1ttNT6booyCWjrnnDA6KYDLRh4aWKSQ_ELuCybcgABDx9iJ_qb7Lxtz7rjtPwhLSfvHSodrOuWRwctwHoLMOfQLMeD58A=)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHouoxFqv0QR0VMlS8V_Ivixzlu8RUQTzMbQtZmccfK_5y1tkCthSMUdN7aoVivIMjVFHnL89F4IO3WhJRTR8_CQASFNWpvJ73OFAmxTgcOak1TElf_UfDWomc_CECCYbRp-c0WFPo=)
28. [jannikreinhard.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHcD2YDzwFSsNwUfbsAEd4_pgdCZzIfaeP4ueI2JwvbR3TMVmHjsEDNl_Ch8K7Qwl_S1E8cDN_0s2iXAvQT3Ao47ZwxSX7vuDSXY3yZO-gteGcKWB22FIb2EvGSjhGhXYRYkhvaCBpkz2dwGs4=)
29. [thenextweb.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEkZHroqT2LhG0ZH8LFoDsczdFadcFEgKGOW3M2tMMFdepMRbklWFXrl-xzuRshDxC0r74KdlvMSV805hAPW8idO1HNdG9K7jZX4cXlfylcLxWV_Yni7pauUNWELxK3K7hITLkD10wVzXf0qQEtErb76OQOAvsA0PcGRFt_JLWwUB8=)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFyiLi-RdLYsobo8qsXIcOu3LggCQUyJ_mUBOXlG5id1AOgU14FN0xXMfXJzhQuq1J1D7SMlkxZ0nhVfLKk6dykGpzOcyqxq1Nt4EhU_nlGKtSmvpqcSH66aGrPWS1EFa9P8SjGNQ67Or5iCsbht3oFYc_IitZCmPlSZWfLcpEFUAI98c4=)
31. [bruniaux.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHkjjbkhJJxSE3xWt-sFRMLAxVlTY2PmF7VALDjLt38BfA-Y5hwN5fzA22iB9HTOAfmyUZwrTEn3vpUDvRkSCoM2PM1czVn9tkaG5uCUnaDppW0VIx5WwWcYe87V1MOohnRvuVOzgzntAVbIKYi)
32. [mallory.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHp-lrhOqdwSH5iOsf6O4JcSe6ta9Efrk1B2y87iyY3jcP-naMXH7OR0SGQEEKC2p47M_9k8J4biiylOQU3jj_mMpbt0bM_9p4ocgYwwE-I-kARCUyuqIRUTgwZW0eU_YjLvHsxlvT3aGu2X6qNezzocwLvOk4=)
33. [humanfirstengineering.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEuhjf2ku_kSXVP6PjKL0w3mMRaKin8qMZBEReviCaTOEkaY7DK73UgwGx6S3JxYKycKn3GzUM-yoBIb_Pe2AVlYh8eodlUd2naLJELR4XK1HcZMGKyuhlGJHpJ21btKVBzI80-0MonjhOA)
34. [suyogjoshi.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEJ0_nDO892DiOb7YKgp1Zpno5d8rSIF_Llod_NgWMvNXslYXm9yigtHotz3x7hV2_j1xShuPM6ySRNdIhqMDv1jARytlJBzAEA7o08zwp6HqTiq51F3s58ZZ7ic0vPiIvMzA3USHRCff405iJdypoXlXturSMZJIlm9dHJ6vTdz5-JZ9Bsh26l28lGHA==)
35. [2i2c.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE25LIeaY9J1xhTLzPiKus-azBSZ2eFoPKQzmIXuI08N313929-vgxFQYi5qjSfw4dPnpKFbVw36Y4CM7c-AejCzN5MuL59ML0YmBnIariz3By0ey4oAaWcviapQXKR4nuVf5SiZdwykK1K2GbAD6RqMM8Ug6FE)

## Sources

- [microsoft.com](https://www.microsoft.com/en-us/security/blog/2026/06/05/securing-ci-cd-in-agentic-world-claude-code-github-action-case/)
- [flatt.tech](https://flatt.tech/research/posts/poisoning-claude-code-one-github-issue-to-break-the-supply-chain/)
- [thehackernews.com](https://thehackernews.com/2026/06/claude-code-github-action-flaw-let-one.html)
- [github.com](https://github.com/release-plz/release-plz)
- [github.com](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-on-actions)
- [github.com](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
- [orhun.dev](https://blog.orhun.dev/automated-rust-releases/)
- [release-plz.dev](https://release-plz.dev/)
- [augmentcode.com](https://www.augmentcode.com/learn/claude-code-131k-stars)
- [composio.dev](https://composio.dev/content/best-ai-powered-code-review-tools-in-2026)
- [gitautoreview.com](https://gitautoreview.com/blog/ai-code-review-for-github)
- [kunalganglani.com](https://www.kunalganglani.com/blog/ai-code-review-github-actions)
- [systemprompt.io](https://systemprompt.io/guides/claude-code-github-actions)
- [dev.to](https://dev.to/dixitgurv/ai-assisted-code-review-opportunities-and-pitfalls-llp)
- [nimbalyst.com](https://nimbalyst.com/blog/ai-code-review-tools-for-engineering-teams-2026/)
- [dev.to](https://dev.to/ollieb89/pullrequesttarget-without-regret-secure-fork-prs-in-github-actions-1jpi)
- [release-plz.dev](https://release-plz.dev/docs)
- [release-plz.dev](https://release-plz.dev/docs/github/token)
- [github.com](https://github.com/anthropics/claude-code-action/blob/main/docs/security.md)
- [release-plz.dev](https://release-plz.dev/docs/config)
- [sourcegraph.com](https://sourcegraph.com/blog/automated-code-review-tools)
- [medium.com](https://medium.com/@moksh45/top-open-source-coding-agents-to-replace-claude-code-in-2026-6aaa3aa781fb)
- [vercel.app](https://githublb.vercel.app/repo/anthropics/claude-code-action)
- [github.com](https://github.com/anthropics/claude-code-action/issues)
- [github.com](https://github.com/anthropics/claude-code-action/issues/914)
- [medium.com](https://medium.com/@jaustinjr/setting-up-claude-code-review-in-github-actions-d7128067646c)
- [github.com](https://github.com/anthropics/claude-code-action)
- [jannikreinhard.com](https://jannikreinhard.com/claude-code-github-actions/)
- [thenextweb.com](https://thenextweb.com/news/claude-code-github-action-prompt-injection-flaw)
- [github.com](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml)
- [bruniaux.com](https://cc.bruniaux.com/guide/workflows/github-actions/)
- [mallory.ai](https://mallory.ai/stories/019e9363-2aa4-769c-8bc7-258d5518fb6b)
- [suyogjoshi.com](https://suyogjoshi.com/writing/how-i-structure-repositories-so-ai-can-understand-them/)
- [humanfirstengineering.dev](https://humanfirstengineering.dev/toolkit/templates/)
- [2i2c.org](https://2i2c.org/blog/github-action-secrets-forked-repositories/)

---
