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