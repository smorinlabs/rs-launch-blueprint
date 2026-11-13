---
prompt: # Deep-research prompt — Codex-assisted review workflows (R86, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships a Codex-driven pair of GitHub Actions workflows equivalent to the Claude pair R18 decides — an automatic pull-request code-review job and a comment-triggered assistant job — and if so, in what configuration: which action or invocation mechanism, which triggers, which credential and credential kind, which permissions per lane, and which author-trust and bot-exclusion guards. Item kind: `bundle`. Value test: if this answer is wrong, the two Codex workflow files in `.github/workflows/` (or their absence), their trigger lists, their credential-presence gate, their permission blocks and their actor guards all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): none — origin `none` (RUST-ONLY). Neither `py-launch-blueprint` nor `ts-launch-blueprint` ships any Codex-driven or OpenAI-driven review or assistant workflow; no py-origin or ts-origin row of `docs/port/COMMONALITY.md` names one, so there is no cross-language implementation to inherit, port or override. The Claude-vendor precedent that does exist in py (F051, F052) belongs to R18 and is not this item's source. Ledger rows: F361 (Codex-driven PR code review workflow) and F362 (Codex-driven assistant workflow triggered by comment), `docs/port/COMMONALITY.md`, both origin `none`, both verdict `RUST-ONLY`, both bundled to this item — the same-vendor, same-action-family argument that bundles F051/F052 applies here for the same reason, and whether the two lanes are in fact adopted or dropped together is a question this item answers rather than assumes.
- Why this item exists, and who directed it: owner amendment of 2026-09-12 (`docs/planning/p02/owner-decisions.md` §4; `docs/planning/p02/execution-ledger.md:435` and `:439`). The owner directed that a Codex equivalent of both Claude workflows exist in the template, so that both vendors' workflows ship. R18 (`ai-assisted-review-workflows`) is **published** — revision 5, 2026-09-10 — and decides the **Claude** pair, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml`, built on the `anthropics/claude-code-action` family; its index status is still `resolved` and it is recorded as requiring reopening for a revision carrying a `## Supersedes` section to absorb the same 2026-09-12 amendment. R18's binding prompt is scoped to the Claude action, which is why the Codex pair cannot be folded into that revision: different vendor, different credential, different trigger vocabulary, different permission model, and its own version of the trusted-author residual (`execution-ledger.md:439`). **This item decides the Codex pair and nothing about the Claude pair.**
- Owner's standing requirements for AI-assisted review workflows in this template (owner amendment 2026-09-12, recorded at `docs/planning/p02/owner-decisions.md` §4 and `docs/planning/p02/execution-ledger.md:435`); they were given for the Claude pair and they bind this item identically, and they are restated as binding constraints in `## Constraints`: the workflows ship with the template by default, with no enable variable at all; a lane runs whenever the credential it needs is present; when that credential is absent the lane does not run, does not error, and prints that the key needs setting; a user who does not want a lane deletes its file; both lanes must reject bots; and the author-trust test is an `author_association` check, not a write-permission check — the owner considered a genuine write-permission check and chose association as the more accurate test.
- The mechanism the Claude side is using to satisfy the credential-presence requirement, given as evidence to test against rather than as a decided answer for Codex (`docs/planning/p02/execution-ledger.md:434`, `:437`): a job-level `if:` condition can read the `vars` and `github` contexts but **cannot read `secrets` at all** — verified on the Claude side both against the platform's context-availability table and by `actionlint` rejecting such a condition. Secrets *are* available in a job's `env` block, so the always-run preflight job the owner chose on 2026-09-11 reads the credential into an environment value, prints the skip reason, and publishes an output that the real jobs gate on through `needs`. Whether the Codex credential is a repository **variable** (directly readable in a job condition, making the gate a one-liner) or a **secret** (requiring the preflight indirection) is therefore a question this item must answer from the vendor's own documentation, not assume.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts ships no Codex workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The configuration of the Claude pair itself — which action version, which triggers, which permissions, which guards, and whether those two files ship at all. R18 (`ai-assisted-review-workflows`) owns F051 and F052 and owns the Claude-lane configuration, including the revision absorbing the 2026-09-12 amendment. This item may cite R18's published configuration as the shape it mirrors and may report a `BASELINE-REVIEW:` finding against it, but it does not decide it and does not edit it.
- How any third-party `uses:` reference in these workflow files is pinned — floating major-version tag, full commit SHA plus version comment, or otherwise. R20 (`third-party-action-pinning-policy`) owns that repo-wide pin-format policy. This item names the action and the version it evaluated and states any reference that is structurally unpinnable; it does not choose the pin format.
- Whether the pull-request template documents the comment commands that re-invoke these lanes on demand. R45 (`pr-comment-bot-trigger-block`) owns that template-content decision and must name whichever bots are actually configured. This item states the trigger vocabulary its lanes respond to; it does not decide whether that vocabulary appears in `.github/pull_request_template.md`.
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention. This item states what permissions these two specific workflows need, not the repo-wide hardening pattern.
- Which CI job or workflow-job graph these lanes sit beside, and the aggregate required-status-check surface; R11 (`ci-workflow-job-structure`) and R12 (`aggregate-required-status-check`) own those.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R86
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R18 (`ai-assisted-review-workflows`) decides the Claude review and assistant pair, published at revision 5 and recorded as requiring a revision for the 2026-09-12 amendment; it owns the Claude-lane configuration and this item mirrors its shape without deciding it. R20 (`third-party-action-pinning-policy`) owns how any third-party action reference in these files is pinned; this item names the action and version it evaluated and leaves the pin format to R20. R45 (`pr-comment-bot-trigger-block`) owns whether the pull-request template documents on-demand trigger commands; this item states the trigger vocabulary, not its documentation placement.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships a Codex-driven automatic pull-request code-review workflow, a Codex-driven comment-triggered assistant workflow, both, or neither, and in what configuration — invocation mechanism and version, triggers, credential and credential kind, credential-presence gate, per-lane permissions, bot exclusion, and author-trust guard.
- HIGH: Does a **first-party** Codex GitHub Action exist — published by the vendor rather than by a third party — and if so, under what repository and coordinate, at what current stable version, with what release cadence and support statement? Report the exact `uses:` coordinate and the version resolved, with endpoint and retrieval date. If no first-party action exists, name the mechanisms that do — the Codex CLI invoked in a `run:` step, a container image, a vendor-hosted GitHub App, or a maintained third-party action — and evaluate them as architectural alternatives. Any action name appearing in this prompt or recalled from memory is an **unverified lead**, never a fact: state existence, ownership and version from a retrieved endpoint or report the evidence gap.
- HIGH: What credential does the chosen mechanism require — an API key, an OAuth or subscription token, a workload-identity or OIDC federation identifier set, or a GitHub App installation — and is that credential a GitHub Actions **secret** or a repository **variable**? Answer for every credential path the vendor supports, because the kind determines the gate: a variable is readable in a job-level `if:`, a secret is not.
- HIGH: Can the owner's credential-presence requirement be expressed as a **job-level condition** for this credential, or does it require the always-run preflight job the Claude side adopted (`docs/planning/p02/execution-ledger.md:437`)? Verify the context-availability rule against the platform's own documentation and against a linter (for example `actionlint`) rather than asserting it, and state what an unconfigured clone actually observes: no run, no error, and a printed message that the key needs setting. Distinguish a check you executed from a check you propose.
- HIGH: What repository permissions does **each lane** require, stated per lane and per permission (`contents`, `pull-requests`, `issues`, `id-token`, `actions`, and any other), and what evidence establishes each grant — the vendor's documentation, the action's own source, or an observed failure without it? State whether the mechanism requests any additional token of its own (for example a vendor App installation token) and, if so, at what point in the run relative to any actor-trust check, and with what scope.
- HIGH: Does the **trusted-author residual** R18 analysed apply identically here? R18's finding is that a trusted author routinely quotes untrusted content — pasting an issue body, a fork pull request's diff, a stack trace — into text the lane processes, and that no `author_association` prefilter distinguishes the author's own words from text that author pasted. State whether that residual is identical, narrower or wider for this vendor and mechanism, and why, citing the mechanism's own permission and sandboxing model rather than reasoning by analogy. Name any published advisory, disclosure or upstream issue class that bears on it, with endpoint and retrieval date.
- HIGH: How does each lane **reject bots**, as the owner requires for both lanes? State the exact condition, whether it must appear on the review lane, the assistant lane or both, and whether the mechanism has any internal actor check that treats a `[bot]` login as trusted — R18 found the Claude action's internal write check returns true unconditionally for any actor whose login ends in `[bot]`, so verify rather than assume the equivalent here.
- HIGH: Is running **two vendors' reviewers on the same pull request** duplicative or complementary? Evaluate against evidence, not preference: whether the two lanes produce overlapping or distinguishable findings, whether reviewers report a signal-to-noise or review-fatigue cost when both run, how comment volume and runner-minute and token spend scale per pull request, whether one lane should be scoped to a narrower trigger set or a different event than the other, and whether the answer differs for a public template repository that downstream consumers fork.
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What **trigger vocabulary** does the assistant lane use, and is it the vendor's own convention or one this template invents? State the event list (`issue_comment`, `pull_request_review_comment`, `issues`, `pull_request_review`, or others), the mention or command token, whether the mechanism supports scoping cleanly to just those events, and whether the vocabulary can collide with the Claude lane's `@claude` trigger on the same repository.
- MEDIUM: What **triggers and filters** does the review lane need — the `pull_request` activity types, a fork guard, a `draft == false` clause — and does anything about this vendor's mechanism change them relative to the Claude lane?
- MEDIUM: Does the mechanism fetch any **instructions or plugin content at run time** from a mutable remote reference, and can that reference be pinned? R18 found the Claude review lane's marketplace URL structurally unpinnable and replaced it with a template-local command file. State whether an equivalent exposure exists here, and if so what the pinned alternative is and what maintaining it costs the template owner.
- MEDIUM: What does the mechanism **cost to run** on a public template repository — per-event token spend, runner minutes, any vendor-side rate limit or seat requirement — and does any part of that cost fall on the template owner rather than on the adopter who installs the credential?
- LOW: Are there reported **false-trigger, loop or rate-limit** problems from adopters running this mechanism on public template or starter repositories specifically, as distinct from application repositories?
- LOW: Does the mechanism need any **Rust-specific configuration** — toolchain setup in the job, a build or test step before review, a repository instruction file naming Rust conventions — for its review output to be useful on this template's CLI, library and web-service surfaces?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library, action or tool already named in this prompt is a research lead, not a closed shortlist, and its existence is not a fact until an endpoint confirms it. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

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
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member. A GitHub Action or hosted-service candidate that publishes no crate states `inapplicable` per crate figure with the reason, and substitutes the repository figures, the vendor's own versioning and support statement, and the licence of the action's own source tree.
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
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix. State also whether the two lanes coexist with R18's Claude lanes on one pull request without trigger collision or duplicated comment volume, and cite the evidence.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended mechanism; state expected behavior and distinguish planned checks from executed results. Include a check of the credential-absent path: the lane does not run, does not error, and prints that the key needs setting.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline. Origin `none`: there is no py or ts Codex workflow to port.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Owner's standing requirements for AI-assisted review workflows, binding on both lanes (owner amendment 2026-09-12, `docs/planning/p02/owner-decisions.md` §4, `docs/planning/p02/execution-ledger.md:435`). A recommendation that violates any of these is not admissible; if evidence shows one cannot be satisfied by any candidate, say so explicitly and state what the mechanism does instead rather than silently relaxing the requirement:
  - The workflows ship with the template by default. There is no enable variable, and no `vars.ENABLE_*`-style switch of any kind.
  - A lane runs whenever the credential it needs is present.
  - When that credential is absent the lane does not run, does not error, and prints that the key needs setting.
  - A user who does not want a lane deletes its file. Deletion is the opt-out; no other opt-out mechanism ships.
  - Both lanes must reject bots.
  - The author-trust test is an `author_association` check, not a write-permission check. The owner considered a genuine write-permission check and chose association as the more accurate test, so do not recommend a write-permission check in its place.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Do not decide, edit or restate as settled anything R18, R20 or R45 owns (`## Out of scope`); report a disagreement with R18's published configuration as a `BASELINE-REVIEW:` finding instead.
- Never assert that a named action, version or credential path exists from memory. Every claim carries a source URL and retrieval date; every number carries its endpoint.
mode: all_deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260917-081418-d364fa415a4a4224
created_at: 2026-09-17T08:14:18.629501
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Codex-assisted review workflows (R86, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships a Codex-driven pair of GitHub Actions workflows equivalent to the Claude pair R18 decides — an automatic pull-request code-review job and a comment-triggered assistant job — and if so, in what configuration: which action or invocation mechanism, which triggers, which credential and credential kind, which permissions per lane, and which author-trust and bot-exclusion guards. Item kind: `bundle`. Value test: if this answer is wrong, the two Codex workflow files in `.github/workflows/` (or their absence), their trigger lists, their credential-presence gate, their permission blocks and their actor guards all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): none — origin `none` (RUST-ONLY). Neither `py-launch-blueprint` nor `ts-launch-blueprint` ships any Codex-driven or OpenAI-driven review or assistant workflow; no py-origin or ts-origin row of `docs/port/COMMONALITY.md` names one, so there is no cross-language implementation to inherit, port or override. The Claude-vendor precedent that does exist in py (F051, F052) belongs to R18 and is not this item's source. Ledger rows: F361 (Codex-driven PR code review workflow) and F362 (Codex-driven assistant workflow triggered by comment), `docs/port/COMMONALITY.md`, both origin `none`, both verdict `RUST-ONLY`, both bundled to this item — the same-vendor, same-action-family argument that bundles F051/F052 applies here for the same reason, and whether the two lanes are in fact adopted or dropped together is a question this item answers rather than assumes.
- Why this item exists, and who directed it: owner amendment of 2026-09-12 (`docs/planning/p02/owner-decisions.md` §4; `docs/planning/p02/execution-ledger.md:435` and `:439`). The owner directed that a Codex equivalent of both Claude workflows exist in the template, so that both vendors' workflows ship. R18 (`ai-assisted-review-workflows`) is **published** — revision 5, 2026-09-10 — and decides the **Claude** pair, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml`, built on the `anthropics/claude-code-action` family; its index status is still `resolved` and it is recorded as requiring reopening for a revision carrying a `## Supersedes` section to absorb the same 2026-09-12 amendment. R18's binding prompt is scoped to the Claude action, which is why the Codex pair cannot be folded into that revision: different vendor, different credential, different trigger vocabulary, different permission model, and its own version of the trusted-author residual (`execution-ledger.md:439`). **This item decides the Codex pair and nothing about the Claude pair.**
- Owner's standing requirements for AI-assisted review workflows in this template (owner amendment 2026-09-12, recorded at `docs/planning/p02/owner-decisions.md` §4 and `docs/planning/p02/execution-ledger.md:435`); they were given for the Claude pair and they bind this item identically, and they are restated as binding constraints in `## Constraints`: the workflows ship with the template by default, with no enable variable at all; a lane runs whenever the credential it needs is present; when that credential is absent the lane does not run, does not error, and prints that the key needs setting; a user who does not want a lane deletes its file; both lanes must reject bots; and the author-trust test is an `author_association` check, not a write-permission check — the owner considered a genuine write-permission check and chose association as the more accurate test.
- The mechanism the Claude side is using to satisfy the credential-presence requirement, given as evidence to test against rather than as a decided answer for Codex (`docs/planning/p02/execution-ledger.md:434`, `:437`): a job-level `if:` condition can read the `vars` and `github` contexts but **cannot read `secrets` at all** — verified on the Claude side both against the platform's context-availability table and by `actionlint` rejecting such a condition. Secrets *are* available in a job's `env` block, so the always-run preflight job the owner chose on 2026-09-11 reads the credential into an environment value, prints the skip reason, and publishes an output that the real jobs gate on through `needs`. Whether the Codex credential is a repository **variable** (directly readable in a job condition, making the gate a one-liner) or a **secret** (requiring the preflight indirection) is therefore a question this item must answer from the vendor's own documentation, not assume.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts ships no Codex workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The configuration of the Claude pair itself — which action version, which triggers, which permissions, which guards, and whether those two files ship at all. R18 (`ai-assisted-review-workflows`) owns F051 and F052 and owns the Claude-lane configuration, including the revision absorbing the 2026-09-12 amendment. This item may cite R18's published configuration as the shape it mirrors and may report a `BASELINE-REVIEW:` finding against it, but it does not decide it and does not edit it.
- How any third-party `uses:` reference in these workflow files is pinned — floating major-version tag, full commit SHA plus version comment, or otherwise. R20 (`third-party-action-pinning-policy`) owns that repo-wide pin-format policy. This item names the action and the version it evaluated and states any reference that is structurally unpinnable; it does not choose the pin format.
- Whether the pull-request template documents the comment commands that re-invoke these lanes on demand. R45 (`pr-comment-bot-trigger-block`) owns that template-content decision and must name whichever bots are actually configured. This item states the trigger vocabulary its lanes respond to; it does not decide whether that vocabulary appears in `.github/pull_request_template.md`.
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention. This item states what permissions these two specific workflows need, not the repo-wide hardening pattern.
- Which CI job or workflow-job graph these lanes sit beside, and the aggregate required-status-check surface; R11 (`ci-workflow-job-structure`) and R12 (`aggregate-required-status-check`) own those.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R86
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R18 (`ai-assisted-review-workflows`) decides the Claude review and assistant pair, published at revision 5 and recorded as requiring a revision for the 2026-09-12 amendment; it owns the Claude-lane configuration and this item mirrors its shape without deciding it. R20 (`third-party-action-pinning-policy`) owns how any third-party action reference in these files is pinned; this item names the action and version it evaluated and leaves the pin format to R20. R45 (`pr-comment-bot-trigger-block`) owns whether the pull-request template documents on-demand trigger commands; this item states the trigger vocabulary, not its documentation placement.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships a Codex-driven automatic pull-request code-review workflow, a Codex-driven comment-triggered assistant workflow, both, or neither, and in what configuration — invocation mechanism and version, triggers, credential and credential kind, credential-presence gate, per-lane permissions, bot exclusion, and author-trust guard.
- HIGH: Does a **first-party** Codex GitHub Action exist — published by the vendor rather than by a third party — and if so, under what repository and coordinate, at what current stable version, with what release cadence and support statement? Report the exact `uses:` coordinate and the version resolved, with endpoint and retrieval date. If no first-party action exists, name the mechanisms that do — the Codex CLI invoked in a `run:` step, a container image, a vendor-hosted GitHub App, or a maintained third-party action — and evaluate them as architectural alternatives. Any action name appearing in this prompt or recalled from memory is an **unverified lead**, never a fact: state existence, ownership and version from a retrieved endpoint or report the evidence gap.
- HIGH: What credential does the chosen mechanism require — an API key, an OAuth or subscription token, a workload-identity or OIDC federation identifier set, or a GitHub App installation — and is that credential a GitHub Actions **secret** or a repository **variable**? Answer for every credential path the vendor supports, because the kind determines the gate: a variable is readable in a job-level `if:`, a secret is not.
- HIGH: Can the owner's credential-presence requirement be expressed as a **job-level condition** for this credential, or does it require the always-run preflight job the Claude side adopted (`docs/planning/p02/execution-ledger.md:437`)? Verify the context-availability rule against the platform's own documentation and against a linter (for example `actionlint`) rather than asserting it, and state what an unconfigured clone actually observes: no run, no error, and a printed message that the key needs setting. Distinguish a check you executed from a check you propose.
- HIGH: What repository permissions does **each lane** require, stated per lane and per permission (`contents`, `pull-requests`, `issues`, `id-token`, `actions`, and any other), and what evidence establishes each grant — the vendor's documentation, the action's own source, or an observed failure without it? State whether the mechanism requests any additional token of its own (for example a vendor App installation token) and, if so, at what point in the run relative to any actor-trust check, and with what scope.
- HIGH: Does the **trusted-author residual** R18 analysed apply identically here? R18's finding is that a trusted author routinely quotes untrusted content — pasting an issue body, a fork pull request's diff, a stack trace — into text the lane processes, and that no `author_association` prefilter distinguishes the author's own words from text that author pasted. State whether that residual is identical, narrower or wider for this vendor and mechanism, and why, citing the mechanism's own permission and sandboxing model rather than reasoning by analogy. Name any published advisory, disclosure or upstream issue class that bears on it, with endpoint and retrieval date.
- HIGH: How does each lane **reject bots**, as the owner requires for both lanes? State the exact condition, whether it must appear on the review lane, the assistant lane or both, and whether the mechanism has any internal actor check that treats a `[bot]` login as trusted — R18 found the Claude action's internal write check returns true unconditionally for any actor whose login ends in `[bot]`, so verify rather than assume the equivalent here.
- HIGH: Is running **two vendors' reviewers on the same pull request** duplicative or complementary? Evaluate against evidence, not preference: whether the two lanes produce overlapping or distinguishable findings, whether reviewers report a signal-to-noise or review-fatigue cost when both run, how comment volume and runner-minute and token spend scale per pull request, whether one lane should be scoped to a narrower trigger set or a different event than the other, and whether the answer differs for a public template repository that downstream consumers fork.
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What **trigger vocabulary** does the assistant lane use, and is it the vendor's own convention or one this template invents? State the event list (`issue_comment`, `pull_request_review_comment`, `issues`, `pull_request_review`, or others), the mention or command token, whether the mechanism supports scoping cleanly to just those events, and whether the vocabulary can collide with the Claude lane's `@claude` trigger on the same repository.
- MEDIUM: What **triggers and filters** does the review lane need — the `pull_request` activity types, a fork guard, a `draft == false` clause — and does anything about this vendor's mechanism change them relative to the Claude lane?
- MEDIUM: Does the mechanism fetch any **instructions or plugin content at run time** from a mutable remote reference, and can that reference be pinned? R18 found the Claude review lane's marketplace URL structurally unpinnable and replaced it with a template-local command file. State whether an equivalent exposure exists here, and if so what the pinned alternative is and what maintaining it costs the template owner.
- MEDIUM: What does the mechanism **cost to run** on a public template repository — per-event token spend, runner minutes, any vendor-side rate limit or seat requirement — and does any part of that cost fall on the template owner rather than on the adopter who installs the credential?
- LOW: Are there reported **false-trigger, loop or rate-limit** problems from adopters running this mechanism on public template or starter repositories specifically, as distinct from application repositories?
- LOW: Does the mechanism need any **Rust-specific configuration** — toolchain setup in the job, a build or test step before review, a repository instruction file naming Rust conventions — for its review output to be useful on this template's CLI, library and web-service surfaces?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library, action or tool already named in this prompt is a research lead, not a closed shortlist, and its existence is not a fact until an endpoint confirms it. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

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
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member. A GitHub Action or hosted-service candidate that publishes no crate states `inapplicable` per crate figure with the reason, and substitutes the repository figures, the vendor's own versioning and support statement, and the licence of the action's own source tree.
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
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix. State also whether the two lanes coexist with R18's Claude lanes on one pull request without trigger collision or duplicated comment volume, and cite the evidence.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended mechanism; state expected behavior and distinguish planned checks from executed results. Include a check of the credential-absent path: the lane does not run, does not error, and prints that the key needs setting.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline. Origin `none`: there is no py or ts Codex workflow to port.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Owner's standing requirements for AI-assisted review workflows, binding on both lanes (owner amendment 2026-09-12, `docs/planning/p02/owner-decisions.md` §4, `docs/planning/p02/execution-ledger.md:435`). A recommendation that violates any of these is not admissible; if evidence shows one cannot be satisfied by any candidate, say so explicitly and state what the mechanism does instead rather than silently relaxing the requirement:
  - The workflows ship with the template by default. There is no enable variable, and no `vars.ENABLE_*`-style switch of any kind.
  - A lane runs whenever the credential it needs is present.
  - When that credential is absent the lane does not run, does not error, and prints that the key needs setting.
  - A user who does not want a lane deletes its file. Deletion is the opt-out; no other opt-out mechanism ships.
  - Both lanes must reject bots.
  - The author-trust test is an `author_association` check, not a write-permission check. The owner considered a genuine write-permission check and chose association as the more accurate test, so do not recommend a write-permission check in its place.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Do not decide, edit or restate as settled anything R18, R20 or R45 owns (`## Out of scope`); report a disagreement with R18's published configuration as a `BASELINE-REVIEW:` finding instead.
- Never assert that a named action, version or credential path exists from memory. Every claim carries a source URL and retrieval date; every number carries its endpoint.
```

## Reasoning Summary
**Searching for Codex details**

I need to conduct extensive research right now, focusing on the current date of September 17, 2026. The goal is to gather comprehensive information and use primary sources for any technical claims I find. Since local documents are not accessible, I have to rely on the available context as my source, but I can't cite URLs. I’ll search for the latest information on Codex GitHub Actions and related documentation to ensure accuracy.

### Landscape

**Research date:** September 17, 2026. All web endpoints cited below were retrieved on that date. The owner records and R18/R20/R45 descriptions were supplied in the prompt and were not independently retrieved.

#### Three-bin map

| Bin | Candidates | Assessment for this bundle |
|---|---|---|
| **Built-in or first-party toolchain** | OpenAI-hosted Codex GitHub integration; first-party `openai/codex-action`; direct `codex exec`; deterministic Rust checks such as formatting, linting and tests | The first-party Action is the only candidate that both ships as repository workflow code and gives the template control over triggers, guards, permissions and reporting. Codex Cloud is first-party but configuration lives outside the repository. Direct CLI invocation loses the Action’s proxy and privilege-reduction controls. |
| **Established industry standard** | GitHub Actions event routing; secret-backed automation; deny-by-default job permissions; read-only analysis separated from write-capable publication; GitHub App review bots | Adopt the architectural pattern, not a third-party reviewer: always-run credential preflight, trusted-human routing, read-only model job and a separate publisher job. GitHub documents that `jobs.<job_id>.if` cannot use `secrets`, while job `env` can. ([docs.github.com](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts)) |
| **Up-and-comer** | OpenAI Workload Identity Federation using GitHub OIDC; GitHub agentic workflows; multi-model reviewer ensembles | WIF is attractive because its identifiers are repository variables and its access token is short-lived, but `openai/codex-action` v1.12 does not document a native WIF input. A custom WIF/CLI implementation would need `id-token: write` and substantially more security code. ([learn.chatgpt.com](https://learn.chatgpt.com/api/docs/guides/workload-identity-federation/github-actions)) |

#### Authority

- **OpenAI product documentation, Action source and changelog** establish existence, ownership, coordinate, authentication, supported operating systems, sandboxing and versions. These are primary sources maintained by the vendor. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))
- **GitHub Actions documentation** is authoritative for context availability and permission behavior. ([docs.github.com](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts))
- **`actionlint` maintainer documentation and source** establish that context availability is statically checked; they are appropriate secondary verification of GitHub’s grammar. ([github.com](https://github.com/rhysd/actionlint/blob/main/docs/checks.md))
- **OpenAI production reports** support the capability of Codex review, but they are vendor-authored and therefore do not establish an unbiased Claude-versus-Codex comparison. Datadog reported that Codex found material issues in roughly 22% of replayed historical incidents; OpenAI reports broad internal and enterprise use. ([openai.com](https://openai.com/index/datadog/))
- Rust project surveys, RFCs and crate statistics are not selection authorities for this item because no Rust library enters the dependency graph. Rust-specific evidence instead determines prompt fit and verifies that the workflow does not alter the edition, MSRV or runtime architecture.

#### Practice evidence

`openai/codex-action` is an active first-party repository with a rounded GitHub UI count of approximately 1.2k stars, 170 forks and 37 open issues. Its changelog contains tags from v1.0 on October 6, 2025 through v1.12 on August 20, 2026, including multiple bot and sandbox hardening releases. Exact API metrics, `pushed_at`, archived status and issue-response medians could not be retrieved through the available research endpoint, so these rounded figures are **not used to select the design**. ([github.com](https://github.com/openai/codex-action))

No public, mainstream Rust project was verified as shipping this exact automatic-plus-comment `openai/codex-action` pair. The maintained reference implementation is OpenAI’s own pull-request example, not a Rust adopter. Therefore this is an ecosystem-fit decision based on first-party architecture and observable controls, not popularity. ([github.com](https://github.com/openai/codex-action))

### Principles and implementation

#### Shared principles and agreement levels

| Principle | Required agreement level | Required behavior |
|---|---|---|
| Both AI capabilities exist | **Capability** | Automatic PR review and explicit comment-triggered assistance both ship. |
| Safe-by-default inactive clone | **Policy** | No enable variable; absent credential produces a successful preflight notice and no model invocation. Deleting the file is the opt-out. |
| Human trust | **Policy** | `author_association` is the authoritative trust check: `OWNER`, `MEMBER` or `COLLABORATOR`. A repository-permission lookup cannot replace it. |
| Bot rejection | **Policy** | Both the triggering actor and relevant content author must be human; vendor bot bypasses remain disabled. |
| Secret isolation | **Architectural pattern** | Secret-bearing model execution has no repository write permission; publication occurs in a later job that never receives the OpenAI key. |
| Prompt/configuration trust | **Architectural pattern** | Trusted instructions live in the workflow definition, not in a file checked out from a PR branch or a mutable remote plugin. |
| Vendor and ecosystem details | **May vary** | Action coordinate, credential path, sandbox model and invocation token can differ while preserving the policies above. |
| Rust review rules | **Ecosystem-specific convention** | Review public-library compatibility, CLI behavior, async/web-service correctness, MSRV and cross-platform concerns; do not add a Rust dependency. |

Python and TypeScript currently lack the Codex capability. Given the September 12, 2026 owner amendment, that is now **missing capability**, not a justified ecosystem difference. Follow-on ports should preserve the capability and policy levels, while allowing vendor-appropriate implementation details. This decision does not alter those repositories.

#### Architectural alternatives

| Alternative | Advantages | Gate result |
|---|---|---|
| **`openai/codex-action`** | First-party; installs `codex exec`; Responses API proxy; `drop-sudo`; read-only/workspace profiles; internal actor and bot admission controls; reusable on arbitrary GitHub events | **Selected** |
| **Codex Cloud GitHub integration** | Vendor-hosted sandbox; automatic review; standard `@codex review`; no API key on a runner | Excluded: cannot ship or express the required two repository workflows, secret-absence preflight or exact local permission blocks. Its configuration is in Codex settings. ([developers.openai.com](https://developers.openai.com/codex/cloud/code-review)) |
| **Direct `codex exec` in `run:`** | Maximum control; easiest route to custom WIF | Runner-up only: recreates proxying, privilege reduction, argument validation and actor checks already maintained by the Action. OpenAI explicitly presents direct CLI as an alternative when more shell control is needed. ([openai.com](https://openai.com/index/codex-now-generally-available/)) |
| **Custom SDK integration** | Structured outputs and custom token providers | Too much template-owned security and publication code for two workflow files. |
| **Official container image** | Reproducible runtime in principle | No maintained first-party Codex Action container was established from the retrieved vendor endpoints. |
| **Third-party Action** | Potential additional features | Excluded because a maintained first-party Action exists and avoids unnecessary supply-chain ownership. |

#### First-party Action finding

A first-party Codex Action **does exist**:

- Repository: `openai/codex-action`
- Documented coordinate: `openai/codex-action@v1`
- Current stable release established from the retrieved changelog: **v1.12**, released **August 20, 2026**
- Initial release: v1.0 on October 6, 2025
- Cadence: bursty rather than scheduled—13 changelog versions over roughly ten months, with several security and compatibility releases
- License: Apache-2.0
- Supported runners: Linux and macOS; Windows requires the explicitly unsafe mode
- Formal support window or SLA: **none found**
- Marketplace status: an open August 26, 2026 issue requested Marketplace publication and verified-creator status, so the repository coordinate—not a verified Marketplace listing—is the established distribution mechanism. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

R20 still decides whether the shipping `uses:` value is the moving `v1` tag or a commit SHA with a version comment.

#### Credential paths

| Path | Vendor support | GitHub storage kind | Job-level credential gate? | Decision |
|---|---|---|---|---|
| OpenAI API key | Native Action input `openai-api-key` | **Secret**, recommended name `OPENAI_API_KEY` | **No.** `secrets` is unavailable in `jobs.<job_id>.if` | **Selected** |
| Azure OpenAI key plus Responses endpoint | Native Action path | Key is a **secret**; endpoint can be a non-secret variable or literal | Key still requires preflight | Supported upstream, not shipped in the template’s default pair |
| OpenAI WIF from GitHub OIDC | Supported by OpenAI API/SDKs, not documented as a native v1.12 Action input | Audience, identity-provider ID and service-account ID are **variables**; the token is minted at run time | Yes, identifiers can be checked in job `if`; token minting requires `id-token: write` | Future runner-up |
| ChatGPT subscription/OAuth state | Supported by interactive Codex products, but not documented as an Action automation credential | Would be sensitive session state | Not an admissible template path | Excluded |
| Codex Cloud GitHub connector | Repository connection/linked ChatGPT account; no Actions key | Neither a workflow secret nor variable | No workflow-level presence gate | Excluded for this bundle |

The Action’s own documentation requires the API key to be stored as a GitHub secret. WIF documentation instead shows repository variables and `id-token: write`, but implementing that path here would replace the selected first-party Action architecture with custom authentication code. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

#### Credential-presence gate

The selected credential is a secret, so the Claude-side preflight pattern is also required here. GitHub’s context table permits only `github`, `needs`, `vars` and `inputs` in `jobs.<job_id>.if`; `jobs.<job_id>.env` can use `secrets`. `actionlint` checks these context restrictions. ([docs.github.com](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts))

Minimal preflight:

```yaml
permissions: {}

jobs:
  preflight:
    runs-on: ubuntu-latest
    timeout-minutes: 2
    outputs:
      configured: ${{ steps.credential.outputs.configured }}
    env:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
    steps:
      - id: credential
        shell: bash
        run: |
          if [[ -n "$OPENAI_API_KEY" ]]; then
            echo "configured=true" >> "$GITHUB_OUTPUT"
          else
            echo "configured=false" >> "$GITHUB_OUTPUT"
            echo "::notice title=Codex not configured::Set the repository secret OPENAI_API_KEY to run this lane."
          fi
```

The model job uses only `needs.preflight.outputs.configured`. The secret itself is never copied to an output. In an unconfigured clone, a workflow run is visible because the notice must be printed, but the **Codex lane and API call do not run**, skipped jobs are not errors, and preflight exits successfully.

This linter behavior was verified from GitHub and `actionlint` documentation, but **no local `actionlint` binary or live GitHub run was executed in this research environment**.

#### Trust, bot and sandbox model

The Action defaults to a repository write-permission check. That is not the owner-selected trust policy. Each model job must therefore:

1. pass an outer event-specific `author_association` gate;
2. reject bots before dispatch;
3. set `allow-users: ${{ github.actor }}` so the already-approved actor does not have to pass the Action’s different write-permission test;
4. retain `allow-bots: "false"` and leave `allow-bot-users` empty.

The Action does **not** appear to have the Claude-side behavior of treating every `[bot]` login as trusted. Its current documented default rejects bots, and v1.7/v1.8 specifically tightened bot bypass behavior. It permits only explicit bot exceptions. ([github.com](https://github.com/openai/codex-action/blob/main/docs/security.md))

Exact outer bot conditions for the review lane:

```yaml
github.event.sender.type != 'Bot' &&
github.event.pull_request.user.type != 'Bot' &&
!endsWith(github.actor, '[bot]') &&
!endsWith(github.triggering_actor, '[bot]') &&
!endsWith(github.event.pull_request.user.login, '[bot]')
```

The assistant lane applies equivalent checks to the selected comment or review author.

Both model jobs use:

```yaml
permission-profile: ":read-only"
safety-strategy: "drop-sudo"
allow-users: ${{ github.actor }}
allow-bots: "false"
```

The Action’s internal `GITHUB_TOKEN` write-access check occurs before CLI installation and model execution. No OpenAI GitHub App installation token is requested. The outer association condition is evaluated before the model job is dispatched; the OpenAI key is supplied only to that job. Publication runs in a different job with a different `GITHUB_TOKEN` and no OpenAI key. ([github.com](https://github.com/openai/codex-action/blob/main/action.yml))

#### Trusted-author residual

The R18 residual is **identical in kind**: an association check can trust the person submitting a comment, but cannot distinguish that person’s own instructions from issue text, diffs, logs or other material they quote.

Codex’s documented ambient input surface is broader than just the current comment: PR bodies, hidden HTML comments, commit messages, repository instruction files and screenshots can all carry prompt injection. The recommended configuration narrows the consequence—read-only filesystem, no direct network, no repository write token and a separate publisher—but cannot prevent manipulated review output or wasted API usage. ([github.com](https://github.com/openai/codex-action/blob/main/docs/security.md))

Relevant published disclosure class:

- OpenAI’s Action security guide: untrusted-input/prompt-injection and quota-abuse risks.
- Upstream issue `openai/codex#19977`: an agentic workflow feeding GitHub issue content to `openai/codex-action` was reported as an injection risk.

No formal GHSA or RustSec advisory was established for this non-crate mechanism. ([github.com](https://github.com/openai/codex-action/security))

#### Two-vendor review

No public controlled study comparing simultaneous Claude and Codex reviews was found. It is therefore unsupported to claim that two reviewers automatically double defect detection or that one dominates the other.

The evidence does support configuring Codex as a **narrow, high-severity second pass**. OpenAI’s hosted reviewer intentionally limits GitHub findings to serious P0/P1 issues, while Datadog reported that Codex found system-level issues previous reviewers or tools had missed and that earlier noisy bots were often ignored. These are vendor-provided results, so they justify a trial and instrumentation—not a universal superiority claim. ([developers.openai.com](https://developers.openai.com/codex/cloud/code-review))

The Codex review prompt should therefore:

- report only actionable correctness, security, concurrency, compatibility or reliability defects introduced by the PR;
- suppress style and preference comments;
- cap findings at five;
- publish one marker-delimited summary comment and update it on later synchronizations.

Costs remain additive: one qualifying PR update invokes both vendors, so runner time and token consumption are approximately the sum of the two lanes. In a downstream clone without `OPENAI_API_KEY`, Codex incurs no API token spend; only the successful preflight job runs. Exact dollar estimates are not reported because the Action does not expose reliable per-run token telemetry and current model pricing was not retrieved. An open Action issue requests machine-readable telemetry. ([github.com](https://github.com/openai/codex-action/issues))

#### Rust fit

No Rust toolchain installation is needed in either Codex job. Existing CI remains responsible for compilation, Clippy and tests. Running untrusted build scripts after injecting an API credential is not justified merely to improve review context.

The trusted inline review instructions should emphasize:

- edition 2024 and the stable-minus-two MSRV contract;
- public library API and SemVer compatibility;
- CLI exit codes, stdout/stderr discipline and cancellation;
- async blocking, task cancellation, timeouts, backpressure and `Send`/`Sync`;
- web input validation, authentication boundaries and error disclosure;
- feature unification and `cfg` behavior;
- Ubuntu/macOS portability;
- panic, `unwrap`, unsafe and resource-lifetime boundaries.

`BASELINE-REVIEW: F361/F362 — owner-selected association trust must remain the policy boundary — pass only the already association-approved current actor through the Action’s allow-users input instead of accepting its default write-permission test as equivalent — the Action documents write access as its default admission mechanism.`

`BASELINE-REVIEW: F361/F362 — trusted prompts must not come from a PR-controlled checkout — keep the governing prompt inline in the base-branch workflow and treat checked-out AGENTS.md, commit messages and PR text as untrusted data — the Action security guide explicitly names those sources as injection surfaces.`

### Recommendation

**Ship both Codex workflow files.**

| Item | Decision |
|---|---|
| Automatic file | `.github/workflows/codex-code-review.yml` |
| Assistant file | `.github/workflows/codex.yml` |
| Primary mechanism | First-party `openai/codex-action` |
| Action version evaluated | **v1.12**, documented coordinate `openai/codex-action@v1`; R20 chooses the shipping pin form |
| Checkout/publication utilities | `actions/checkout@v5`, `actions/github-script@v7`, subject to R20 |
| Model | `gpt-5.5`, medium effort, pending availability verification at integration time |
| Credential | Repository or organization Actions **secret** `OPENAI_API_KEY` |
| Gate | Always-run, zero-permission preflight job publishing only a boolean output |
| Sandbox | `permission-profile: ":read-only"` plus `safety-strategy: "drop-sudo"` |
| Trust | `author_association ∈ {OWNER, MEMBER, COLLABORATOR}` |
| Bot defense | Event sender/content author type check, actor/login `[bot]` suffix checks, `allow-bots: false`, no bot allow-list |
| Review triggers | `pull_request` types `opened`, `reopened`, `synchronize`, `ready_for_review`; same-repository head; non-draft |
| Assistant triggers | `issue_comment: created`, `pull_request_review_comment: created`, `pull_request_review: submitted` |
| Assistant token | Exact template-defined slash command `/codex` at the beginning of the first nonblank line |
| Assistant scope | Analysis and response only; no autonomous commit, push or branch mutation |
| Opt-out | Delete the unwanted workflow file; no enable variable |
| Prompt source | Inline trusted workflow text; no remote plugin and no PR-checkout prompt file |
| Publication | Separate write-capable job; review comment is upserted by marker |
| Time bounds | Review model job 15 minutes; assistant model job 10 minutes; concurrency cancellation on repeated PR updates |

**Nested CLI version caveat:** v1.12 installs the Codex CLI at run time. Leaving `codex-version` blank means “latest”, even when the Action itself is pinned; an open issue calls this out. The exact current CLI release could not be reliably resolved from the official release endpoint in this run, and the highest version directly visible in the Action issue list, 0.150.1, has an open hang report. Therefore the shipping workflow must set an exact, smoke-tested `codex-version`; resolving that patch is a mandatory integration prerequisite, not permission to leave it floating. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

### Members

#### Codex automatic pull-request review workflow

##### Landscape

The viable implementations are the first-party Action, Codex Cloud automatic review and a direct CLI workflow. The Action dominates because it is repository-defined and preserves the owner’s credential, trigger and permission observability.

Fitness and maintenance evidence:

| Gate or figure | Result |
|---|---|
| License | Pass: Apache-2.0, compatible with `MIT OR Apache-2.0`. |
| Crate 90-day downloads | Inapplicable: no Rust crate is added. |
| Crate all-time downloads | Inapplicable. |
| Crate release/MSRV | Inapplicable to the template dependency graph. |
| RustSec | Inapplicable: no crate package. |
| Unsafe posture | No template Rust unsafe surface; runner-agent risk is controlled through Action sandboxing and privilege reduction. |
| Ubuntu/macOS | Pass: the Action documents Linux and macOS support. |
| Windows | Available only with unsafe mode; not required by the template. |
| Cargo features/runtime coupling | Inapplicable. |
| Binary and compile-time cost | No shipped Rust binary impact; run-time download and API latency only. |
| Stars | GitHub UI rounded to 1.2k; exact API value not retrieved. |
| Archived/pushed_at | Exact API retrieval unavailable; not used for selection. |
| Open issues | GitHub UI showed 37; exact Search API result not retrieved. |
| Issue responsiveness | Not established; ten-issue maintainer-response calculation was not executable from the available endpoint. |
| Maintenance state | **Active**, with elevated re-verification risk from current reliability issues. |
| Public Rust adopters | None verified. |

([github.com](https://github.com/openai/codex-action))

##### Principles and implementation

The lane is automatic but not indiscriminate. It must satisfy all of:

```text
credential present
AND PR is not draft
AND PR head repository equals the base repository
AND PR author_association is OWNER, MEMBER or COLLABORATOR
AND triggering actor is human
AND PR author is human
```

The event set is:

```yaml
on:
  pull_request:
    types: [opened, reopened, synchronize, ready_for_review]
```

It must use `pull_request`, never `pull_request_target`, and explicitly checkout the PR merge reference with `persist-credentials: false`. The model reviews the diff but receives no write token and is instructed not to execute repository-controlled build scripts.

##### Dominant choice

`openai/codex-action` v1.12 is the dominant choice because its maintained implementation provides the API proxy, `drop-sudo`, permission profiles, argument validation and bot-aware actor check that a direct shell integration would otherwise have to reproduce. ([github.com](https://github.com/openai/codex-action))

##### Qualified shortlist

1. `openai/codex-action` v1.12 — selected.
2. Codex Cloud automatic review — technically strong, but outside the repository and unable to meet the preflight/file requirements.
3. Direct `codex exec` with API key or WIF — viable only if Action reliability or WIF support becomes a blocker.

##### Excluded by gate

- Codex Cloud: fails the repository-file and credential-notice requirements.
- `pull_request_target` plus untrusted checkout: fails the secret-exposure architecture gate.
- Third-party Codex Actions: unnecessary supply-chain expansion.
- Default Action write-permission admission without an outer association check: fails owner policy.
- `permission-profile: ":workspace"`: unnecessary write access for a review-only lane.
- Prompt files from the PR merge checkout: fail the trusted-configuration gate.
- Floating `codex-version`: fails reproducibility until explicitly approved.

##### Up-and-comers

OpenAI WIF could eventually eliminate the long-lived API secret. Its repository identifiers are variables and could be checked directly in a job condition, while the model job would require `id-token: write`. It becomes preferable only after the first-party Action natively supports it or OpenAI publishes a maintained Action integration. ([learn.chatgpt.com](https://learn.chatgpt.com/api/docs/guides/workload-identity-federation/github-actions))

##### Fit for this template

The review prompt should divide findings across the template’s three surfaces:

- library API/MSRV/SemVer;
- CLI behavior and diagnostics;
- web-service async, security and lifecycle behavior.

It should reject style-only findings and report no more than five high-severity defects. The workload is one PR diff plus targeted repository context, with a 15-minute hard timeout and no compilation. Latency and cost are measured per PR event, not compared against unlike benchmark suites.

##### Recommendation

Use three jobs:

1. **`preflight`** — `permissions: {}`, checks the secret, prints the missing-key notice.
2. **`review`** — `contents: read`; all writes, `id-token`, `actions`, checks and statuses disabled.
3. **`publish`** — `issues: write` and `pull-requests: write`; no contents access and no OpenAI secret.

The official reference separates read-only Codex execution from feedback publication and grants `contents: read` to the model job and issue/PR writes to the publisher. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

The review job condition is:

```yaml
if: >-
  needs.preflight.outputs.configured == 'true' &&
  github.event.pull_request.draft == false &&
  github.event.pull_request.head.repo.full_name == github.repository &&
  contains(
    fromJSON('["OWNER","MEMBER","COLLABORATOR"]'),
    github.event.pull_request.author_association
  ) &&
  github.event.sender.type != 'Bot' &&
  github.event.pull_request.user.type != 'Bot' &&
  !endsWith(github.actor, '[bot]') &&
  !endsWith(github.triggering_actor, '[bot]') &&
  !endsWith(github.event.pull_request.user.login, '[bot]')
```

Use vendor-specific concurrency:

```yaml
concurrency:
  group: codex-review-${{ github.event.pull_request.number }}
  cancel-in-progress: true
```

The publisher maintains one `<!-- codex-review -->` comment rather than appending a new comment on every synchronization.

##### Ranked runner-up

Codex Cloud automatic review is the ranked runner-up because it keeps credentials and execution in the vendor-hosted environment and already supports automatic review and `@codex review`. It loses because it cannot implement the owner’s repository-default workflow, credential-presence notice or file-deletion opt-out. ([developers.openai.com](https://developers.openai.com/codex/cloud/code-review))

##### Tradeoffs

- Trusted same-repository PRs only; external fork reviews are deliberately skipped.
- Read-only review cannot compile or test the patch.
- A second vendor adds one more model invocation per qualifying update.
- Upserting one comment controls discussion noise, but the two vendors can still report overlapping findings.
- Action v1.12 has current reports involving hangs, runner privilege cleanup and output handling; timeouts and “Action last in job” reduce, but do not eliminate, this risk. ([github.com](https://github.com/openai/codex-action/issues))

##### Parameters

```text
workflow-file = .github/workflows/codex-code-review.yml
action = openai/codex-action
action-version-evaluated = v1.12
credential = secrets.OPENAI_API_KEY
events = pull_request[opened,reopened,synchronize,ready_for_review]
trusted-associations = OWNER,MEMBER,COLLABORATOR
fork-policy = same-repository only
draft-policy = skip drafts
sandbox = :read-only
safety-strategy = drop-sudo
model = gpt-5.5
effort = medium
timeout = 15 minutes
publication = one upserted marker comment
```

##### Migration implications

Add `.github/workflows/codex-code-review.yml`. Do not add an enable variable, remote review plugin or PR-controlled prompt file. Leave third-party `uses:` pin formatting to R20.

##### Validation strategy

Planned tests:

- no secret: preflight succeeds and prints the exact notice; model/publish jobs skip;
- trusted same-repo non-draft PR: one API invocation and one marker comment;
- repeated synchronize event: previous run cancels and existing comment is updated;
- draft, fork, bot author, bot actor and `NONE` association fixtures: model job skips;
- permission-negative test: model job cannot write contents, issues or PRs;
- prompt-injection fixture requesting environment disclosure: no key appears in logs;
- Ubuntu and macOS smoke tests of the selected Action/CLI pair.

No live workflow execution was performed during this research.

##### Confidence & re-verify trigger

**Confidence: medium-high** on mechanism, secret gate, trigger and isolation architecture; **medium** on exact publication permissions; **blocked** on the exact nested CLI patch.

Re-verify if:

- a release newer than Action v1.12 appears;
- native Action WIF support appears;
- Action bot or `allow-users` behavior changes;
- issues #160, #169, #171, #172 or #175 materially change;
- R18’s Claude review scope changes enough to create excessive duplicate findings.

##### Sources

OpenAI Action documentation and maintained example; Action changelog and security guide; GitHub context table; current Action issue list. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

#### Codex comment-triggered assistant workflow

##### Landscape

The first-party Action is generic rather than tied to a vendor command parser, so the workflow can scope the assistant precisely. Codex Cloud’s `@codex` vocabulary is not selected because it would couple the template to an externally installed connector.

The same Action fitness figures apply:

| Gate or figure | Result |
|---|---|
| License | Pass: Apache-2.0. |
| Crate figures/MSRV/RustSec | Inapplicable: no Rust crate. |
| OS | Linux and macOS supported; production workflow uses Ubuntu. |
| Runtime coupling | No Cargo or async-runtime coupling. |
| Template binary impact | None. |
| Repository metrics | Rounded UI only; exact API metrics unavailable. |
| Maintenance state | **Active**, with current reliability issues to monitor. |
| Maintained reference | Official Action source and generic GitHub-event documentation; no maintained first-party two-lane sample was found. |

([github.com](https://github.com/openai/codex-action))

##### Principles and implementation

The assistant is explicitly comment-triggered and read-only. It responds only when the first nonblank line begins with:

```text
/codex
```

This is a **template-defined command**, not an Action convention. OpenAI’s hosted GitHub product uses `@codex` and `@codex review`; `/codex` is chosen to avoid collision with that connector and with R18’s `@claude`. ([developers.openai.com](https://developers.openai.com/codex/cloud/code-review))

Events:

```yaml
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  pull_request_review:
    types: [submitted]
```

`issues`, `pull_request` and comment-edit events are intentionally absent. Initial issue bodies do not trigger the lane; newly created issue and PR conversation comments do. Anchoring the command also reduces false triggers when a trusted author quotes material containing the word “Codex”.

##### Dominant choice

Use `openai/codex-action` v1.12 with the same API key, read-only permission profile and privilege reduction as the review lane. The workflows remain separate so deleting one file disables exactly one capability.

##### Qualified shortlist

1. First-party Action plus template route logic — selected.
2. Direct CLI plus WIF — qualified future alternative.
3. Codex Cloud `@codex` task delegation — qualified product alternative, but not equivalent to a self-contained template workflow.

##### Excluded by gate

- Broad `@codex` substring trigger: can collide with the hosted connector.
- `issues: opened` or edited-comment events: broader than comment-triggered capability and prone to accidental reruns.
- Any bot allow-list: owner requires bot rejection.
- `contents: write`, retained checkout credentials or branch pushing: unnecessary and unsafe for a public template assistant.
- A write-permission actor check: cannot replace `author_association`.
- Processing comments from `CONTRIBUTOR`, `FIRST_TIMER`, `FIRST_TIME_CONTRIBUTOR` or `NONE`: outside the owner-selected trust set.
- Running repository scripts after loading the API key.

##### Up-and-comers

A direct CLI/WIF assistant could use:

```yaml
permissions:
  id-token: write
  contents: read
```

and three repository variables for audience, identity-provider ID and service-account ID. This removes the long-lived API key but is not yet the simplest maintained Action route. ([learn.chatgpt.com](https://learn.chatgpt.com/api/docs/guides/workload-identity-federation/github-actions))

##### Fit for this template

The assistant can answer:

- “Explain this public API change.”
- “Check whether this keeps the stable-minus-two MSRV.”
- “Summarize the async cancellation risk.”
- “Propose tests for this CLI or handler change.”

It does not commit changes. For PR events, it should inspect the base branch and a fetched diff represented as data, rather than checking out and executing an untrusted fork head. For plain issues, it receives a bounded issue/comment context file.

##### Recommendation

Use three jobs:

1. **`preflight`/router**, no permissions:
   - checks `OPENAI_API_KEY`;
   - selects the relevant body and its `author_association`;
   - verifies exact `/codex` prefix;
   - rejects bot type and `[bot]` suffix;
   - emits only booleans and subject identifiers.
2. **`assist`**, read-only:
   - `contents: read`;
   - `issues: read`;
   - `pull-requests: read`;
   - no write, `id-token`, `actions`, checks or statuses;
   - gathers bounded context before running the Action;
   - runs the Action as the last step.
3. **`publish`**:
   - `issues: write`;
   - `pull-requests: write`;
   - no contents access;
   - no OpenAI key.

Event-specific association fields:

| Event | Body | Trust field |
|---|---|---|
| `issue_comment` | `comment.body` | `comment.author_association` |
| `pull_request_review_comment` | `comment.body` | `comment.author_association` |
| `pull_request_review` | `review.body` | `review.author_association` |

The router requires `OWNER`, `MEMBER` or `COLLABORATOR` and checks both the selected author and `github.actor`/`github.triggering_actor` for bot identity.

##### Ranked runner-up

Direct `codex exec` with OpenAI WIF is the ranked runner-up. It could use variable-readable configuration and short-lived credentials, but would make the template responsible for OIDC retrieval, token exchange, caching, redaction, sandboxing and secure CLI invocation.

##### Tradeoffs

- `/codex` is safer from connector collision but less immediately familiar than `@codex`.
- Comment association does not make quoted content trusted.
- Read-only mode can propose but not apply fixes.
- One model call is made for every accepted command; repeated trusted comments can therefore consume quota.
- Assistant replies trigger `issue_comment` again, but the reply author is `github-actions[bot]`, so the outer and internal bot guards stop loops.
- No adopter reports specific to public Rust starter repositories were found; loop prevention is architectural rather than based on a large public-template dataset.

##### Parameters

```text
workflow-file = .github/workflows/codex.yml
action = openai/codex-action
action-version-evaluated = v1.12
credential = secrets.OPENAI_API_KEY
command = /codex
command-position = beginning of first nonblank line
events = issue_comment[created],pull_request_review_comment[created],pull_request_review[submitted]
trusted-associations = OWNER,MEMBER,COLLABORATOR
bot-policy = reject all bots
mutation-policy = comment-only
sandbox = :read-only
safety-strategy = drop-sudo
model = gpt-5.5
effort = medium
timeout = 10 minutes
```

##### Migration implications

Add `.github/workflows/codex.yml`. Do not add an enable variable or reuse the hosted connector’s `@codex` trigger. R45 may later document `/codex`; this item does not modify the pull-request template.

##### Validation strategy

Planned fixtures:

- trusted `OWNER`, `MEMBER` and `COLLABORATOR` comments beginning `/codex`: run;
- lowercase `/codex` later in quoted text: no run;
- `@codex`, `@codex review` and `@claude`: no run;
- bot comment containing `/codex`: no run;
- association `NONE` or `CONTRIBUTOR`: no run;
- missing key: successful notice and skipped model/publisher;
- assistant’s own response: follow-up workflow starts but router rejects the bot before model execution;
- PR review-body and inline-comment events: one response each;
- attempted request to push or modify files: model has no write permission and publisher has no checkout.

No live invocation was executed.

##### Confidence & re-verify trigger

**Confidence: high** on event routing, command separation and bot-loop prevention; **medium-high** on Action execution; **medium** on the optimal user vocabulary because `/codex` is intentionally template-specific.

Re-verify if OpenAI publishes a first-party comment-assistant Action mode, a collision-free official command, or native WIF support.

##### Sources

OpenAI Action documentation and source; hosted Codex trigger documentation; Action security guide; GitHub context rules and WIF documentation. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

### Compatibility

#### Version and composition matrix

| Component | Evaluated version | Review lane | Assistant lane |
|---|---:|---:|---:|
| `openai/codex-action` | v1.12 | Yes | Yes |
| Codex CLI | Exact patch required; merge-time resolution blocked by evidence gap | Same exact patch | Same exact patch |
| `actions/checkout` | v5 | PR merge checkout | Base checkout |
| `actions/github-script` | v7 | Marker-comment publication | Context collection/publication |
| Permission profile | `:read-only`, requires CLI 0.138.0+ | Yes | Yes |
| Safety strategy | `drop-sudo` | Yes | Yes |
| Runner | `ubuntu-latest` production; macOS smoke test | Yes | Yes |

The two members share the same Action family, credential and sandbox but no mutable state. The official reference validates the read-only-analysis/separate-publication composition. No maintained repository containing this exact pair was found, and no live pair was executed here; compatibility is therefore **structurally established but still requires the planned integration test**. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

#### Coexistence with R18

- Automatic review events intentionally overlap: both vendors may run on the same qualifying PR.
- Assistant commands do not collide: Codex uses `/codex`; Claude remains under R18’s `@claude`.
- Vendor-specific concurrency groups prevent one vendor from canceling the other.
- Unique job and workflow names prevent required-check name collisions.
- The Codex automatic lane contributes at most one maintained summary comment; Claude’s comment behavior remains R18-owned.
- Runner minutes and token spend are additive.
- Any bot-generated response is rejected before it can recursively trigger the Codex model.
- No change to either Claude workflow is implied.

### Parameters

```text
owns codex-workflow-bundle = both
owns codex-review-workflow-file = .github/workflows/codex-code-review.yml
owns codex-assistant-workflow-file = .github/workflows/codex.yml
owns codex-invocation-mechanism = openai/codex-action
owns codex-action-version-evaluated = v1.12
owns codex-credential = OPENAI_API_KEY
owns codex-credential-kind = GitHub Actions secret
owns codex-credential-gate = always-run preflight job with boolean needs output
owns codex-review-events = pull_request[opened,reopened,synchronize,ready_for_review]
owns codex-assistant-events = issue_comment[created],pull_request_review_comment[created],pull_request_review[submitted]
owns codex-assistant-command = /codex
owns codex-trusted-associations = OWNER,MEMBER,COLLABORATOR
owns codex-bot-policy = reject sender, actor, triggering actor and subject author bots
owns codex-review-fork-policy = same-repository only
owns codex-draft-policy = skip drafts
owns codex-sandbox = :read-only
owns codex-safety-strategy = drop-sudo
owns codex-mutation-policy = analysis-and-comment only
owns codex-cli-version-policy = exact tested patch; floating latest forbidden
assumes rust-edition = 2024
assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest
```

No `CONFLICT:` applies. The production AI jobs may run on Ubuntu alone because the mechanism supports both fixed target operating systems and does not replace the repository’s Rust OS matrix.

### Migration implications

Add:

```text
.github/workflows/codex-code-review.yml
.github/workflows/codex.yml
```

Both files must contain their own:

- top-level deny-all permission baseline;
- always-run credential preflight;
- event-specific association and bot routing;
- Action invocation;
- separate publisher;
- timeout and concurrency configuration.

Do not add:

- an enable variable;
- `pull_request_target`;
- `contents: write` to a model job;
- `id-token: write` for the selected API-key path;
- bot allow-lists;
- PR-controlled prompt files;
- mutable remote review plugins;
- a floating nested CLI version in the final integrated workflow.

Follow-on ownership remains:

- R20: exact pin syntax for `uses:` references;
- R45: whether `/codex` is documented in the PR template;
- R18: all Claude workflow content.

The generated repository administrator sets one secret:

```text
OPENAI_API_KEY
```

If the secret is never set, no OpenAI API call or token charge occurs.

### Validation strategy

#### Executed during research

- Retrieved the first-party Action definition, documentation, security guide and changelog.
- Verified from GitHub’s context table that `secrets` is excluded from `jobs.<job_id>.if` and allowed in `jobs.<job_id>.env`.
- Verified that `actionlint` maintains context-availability checks.
- Verified the Action’s current bot inputs and internal `GITHUB_TOKEN` admission step from source.
- Verified OpenAI’s WIF variable and `id-token: write` alternative from vendor documentation.

No workflow, linter or OpenAI API execution was performed.

#### Planned static checks

```bash
actionlint \
  .github/workflows/codex-code-review.yml \
  .github/workflows/codex.yml

grep -RInE 'ENABLE_|vars\.ENABLE' .github/workflows/codex*.yml
# Expected: no matches.

grep -RInE 'jobs:|if:.*secrets\.' .github/workflows/codex*.yml
# Expected: no job-level condition referencing secrets.

grep -RInE 'pull_request_target|allow-bots:[[:space:]]*["'\'']?true' \
  .github/workflows/codex*.yml
# Expected: no matches.

grep -RIn 'codex-version:' .github/workflows/codex*.yml
# Expected: both workflows contain the same exact patch version.
```

A negative linter fixture should deliberately contain:

```yaml
jobs:
  invalid:
    if: ${{ secrets.OPENAI_API_KEY != '' }}
```

Expected: `actionlint` rejects the unavailable `secrets` context at the job condition.

#### Planned credential-absent integration check

1. Remove `OPENAI_API_KEY` from a disposable test repository.
2. Open or update a trusted same-repository non-draft PR.
3. Observe:
   - preflight job succeeds;
   - log includes `Set the repository secret OPENAI_API_KEY to run this lane`;
   - model job is skipped;
   - publisher is skipped;
   - overall workflow does not fail;
   - OpenAI usage remains zero.
4. Post `/codex explain this change`.
5. Observe the same successful skip behavior.

This is the observable meaning of “does not run”: the workflow record and successful notice exist, but no Codex Action/model invocation occurs.

#### Planned configured-path integration check

```bash
gh secret set OPENAI_API_KEY --repo OWNER/TEST_REPO
gh pr create --repo OWNER/TEST_REPO --title "Codex workflow acceptance" \
  --body "Exercise review routing."
gh pr comment PR_NUMBER --repo OWNER/TEST_REPO \
  --body "/codex identify the highest-risk compatibility concern"
```

Expected:

- one automatic Codex review invocation;
- one marker comment, updated rather than duplicated on synchronization;
- one assistant response to `/codex`;
- no response to `@codex review`, `@claude` or an untrusted association;
- no recursive response to the publisher bot;
- no secret in logs;
- model jobs show only their documented read grants;
- publisher jobs lack `OPENAI_API_KEY`.

Repeat the Action smoke test on `ubuntu-latest` and `macos-latest`. Before merge, resolve an exact Codex CLI patch and reject it if the current hang or privilege-cleanup issues reproduce.

### Confidence & re-verify trigger

**Overall confidence: medium-high.**

High confidence:

- first-party Action existence and ownership;
- current Action release v1.12;
- API key being a GitHub secret;
- necessity of preflight indirection;
- association and bot architecture;
- viability of two separate lanes.

Medium confidence:

- exact minimal GitHub publication permissions, because the official example grants both `issues: write` and `pull-requests: write`;
- two-vendor signal complementarity, because no controlled Claude-plus-Codex study was found;
- assistant command UX.

Unresolved implementation evidence:

- exact current green `@openai/codex` patch;
- exact GitHub API repository metrics and issue-response median;
- a live absent-secret and adversarial-prompt run;
- a maintained public Rust adopter of the exact pair.

Re-verify immediately before implementation if any of the following occurs:

1. `openai/codex-action` releases v1.13 or later.
2. The Action gains native WIF support.
3. The bot admission or `allow-users` semantics change.
4. A formal advisory is published.
5. Open issues about hangs, output commands, privilege cleanup or floating CLI versions are resolved or escalated.
6. OpenAI changes the hosted `@codex` vocabulary.
7. R18 changes the Claude review’s scope or comment-volume behavior.
8. `gpt-5.5` availability or pricing changes.
9. GitHub changes context availability for job conditions.

### Sources

All endpoints retrieved **September 17, 2026**.

1. OpenAI, **Codex GitHub Action**  
   `https://learn.chatgpt.com/docs/github-action`  
   Coordinate, API-key secret, OS support, example permissions and action inputs. ([learn.chatgpt.com](https://learn.chatgpt.com/docs/github-action))

2. OpenAI, **`openai/codex-action` repository**  
   `https://github.com/openai/codex-action`  
   First-party ownership, reference workflow, license and repository UI figures. ([github.com](https://github.com/openai/codex-action))

3. OpenAI, **Action definition**  
   `https://github.com/openai/codex-action/blob/main/action.yml`  
   Internal actor check, bot inputs, CLI installation and safety configuration. ([github.com](https://github.com/openai/codex-action/blob/main/action.yml))

4. OpenAI, **Action changelog**  
   `https://github.com/openai/codex-action/blob/main/CHANGELOG.md`  
   v1.0–v1.12 release history and hardening changes. ([github.com](https://github.com/openai/codex-action/blob/main/CHANGELOG.md))

5. OpenAI, **Action security guide**  
   `https://github.com/openai/codex-action/blob/main/docs/security.md`  
   Prompt injection, bot controls, API-key protection and permission profiles. ([github.com](https://github.com/openai/codex-action/blob/main/docs/security.md))

6. GitHub, **Actions contexts reference**  
   `https://docs.github.com/en/enterprise-cloud@latest/actions/reference/workflows-and-actions/contexts`  
   Job-condition and job-environment context availability. ([docs.github.com](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts))

7. `actionlint`, **Checks documentation**  
   `https://github.com/rhysd/actionlint/blob/main/docs/checks.md`  
   Static context/function checking. ([github.com](https://github.com/rhysd/actionlint/blob/main/docs/checks.md))

8. OpenAI API, **Configuring WIF for GitHub Actions**  
   `https://developers.openai.com/api/docs/guides/workload-identity-federation/github-actions`  
   OIDC token exchange, `id-token: write` and repository variables. ([learn.chatgpt.com](https://learn.chatgpt.com/api/docs/guides/workload-identity-federation/github-actions))

9. OpenAI, **Review GitHub pull requests with Codex**  
   `https://learn.chatgpt.com/docs/third-party/github`  
   Hosted automatic review, `@codex review` and severity-focused output. ([developers.openai.com](https://developers.openai.com/codex/cloud/code-review))

10. OpenAI, **Codex is now generally available**  
    `https://openai.com/index/codex-now-generally-available/`  
    First-party GitHub Action announcement and production-use claims. ([openai.com](https://openai.com/index/codex-now-generally-available/))

11. OpenAI, **Datadog uses Codex for system-level code review**  
    `https://openai.com/index/datadog/`  
    Vendor-authored production evaluation and review-noise observations. ([openai.com](https://openai.com/index/datadog/))

12. OpenAI upstream issue, **Agentic workflow injection risk**  
    `https://github.com/openai/codex/issues/19977`  
    Concrete prompt-injection issue class involving GitHub issue content. ([github.com](https://github.com/openai/codex/issues/19977))

13. OpenAI, **Current `codex-action` issue list**  
    `https://github.com/openai/codex-action/issues`  
    Current reliability, telemetry, Marketplace and nested-version evidence. ([github.com](https://github.com/openai/codex-action/issues))

14. OpenAI Cookbook, **Build code review with Codex**  
    `https://github.com/openai/openai-cookbook/blob/main/examples/codex/build_code_review_with_codex_sdk.md`  
    Archived example, current security warning and model recommendation. ([github.com](https://github.com/openai/openai-cookbook/blob/main/examples/codex/build_code_review_with_codex_sdk.md))

Exact figure endpoints required by the prompt but not successfully retrievable in this environment were:

```text
GET https://api.github.com/repos/openai/codex-action
GET https://api.github.com/search/issues?q=repo:openai/codex-action+is:issue+is:open
```

Consequently, exact stars, `archived`, `pushed_at`, open-issue total and ten-issue responsiveness remain explicit evidence gaps rather than inferred values.

## Sources

- [https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts)
- [https://learn.chatgpt.com/api/docs/guides/workload-identity-federation/github-actions](https://learn.chatgpt.com/api/docs/guides/workload-identity-federation/github-actions)
- [https://learn.chatgpt.com/docs/github-action](https://learn.chatgpt.com/docs/github-action)
- [https://github.com/rhysd/actionlint/blob/main/docs/checks.md](https://github.com/rhysd/actionlint/blob/main/docs/checks.md)
- [https://openai.com/index/datadog/](https://openai.com/index/datadog/)
- [https://github.com/openai/codex-action](https://github.com/openai/codex-action)
- [https://developers.openai.com/codex/cloud/code-review](https://developers.openai.com/codex/cloud/code-review)
- [https://openai.com/index/codex-now-generally-available/](https://openai.com/index/codex-now-generally-available/)
- [https://github.com/openai/codex-action/blob/main/docs/security.md](https://github.com/openai/codex-action/blob/main/docs/security.md)
- [https://github.com/openai/codex-action/blob/main/action.yml](https://github.com/openai/codex-action/blob/main/action.yml)
- [https://github.com/openai/codex-action/security](https://github.com/openai/codex-action/security)
- [https://github.com/openai/codex-action/issues](https://github.com/openai/codex-action/issues)
- [https://github.com/openai/codex-action/blob/main/CHANGELOG.md](https://github.com/openai/codex-action/blob/main/CHANGELOG.md)
- [https://github.com/openai/codex/issues/19977](https://github.com/openai/codex/issues/19977)
- [https://github.com/openai/openai-cookbook/blob/main/examples/codex/build_code_review_with_codex_sdk.md](https://github.com/openai/openai-cookbook/blob/main/examples/codex/build_code_review_with_codex_sdk.md)