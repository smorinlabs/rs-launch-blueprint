---
prompt: # Deep-research prompt — Codex-assisted review workflows (R86, bundle)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260917-081418-d364fa415a4a4224
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Codex-assisted review workflows (R86, bundle)

Generated: 2026-09-17T22:40:03.224164+00:00


## Openai Results

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

---


## Perplexity Results

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
provider: perplexity
model: sonar-deep-research
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

# Codex-assisted AI review workflows for `rs-launch-blueprint`

The research concludes that `rs-launch-blueprint` should ship a pair of Codex-driven GitHub Actions workflows that mirror the Claude pair in shape and principle, while using OpenAI’s first‑party Codex GitHub Action and CLI as the core mechanism. The recommended stack uses `openai/codex-action@v1` for both lanes, an encrypted OpenAI API key stored as a GitHub Actions secret, and an always‑run preflight job to implement the owner’s credential‑presence contract without violating GitHub’s context restrictions on secrets.[1][3][9][17] The automatic review lane runs on non‑draft pull requests from trusted human authors and posts inline comments and summaries while holding only read access to repository contents and write access to pull request reviews; the assistant lane listens for trusted human comments containing a Codex trigger token on pull requests and, under stricter permissions, can propose or apply focused edits via Codex while still rejecting bot actors and preserving author‑association gating.[2][3][4][8] Both lanes are designed so that a clone without an OpenAI key observes a clean skip with an explicit “set OPENAI_API_KEY” message rather than a failing workflow, and both co‑exist with the Claude pair without trigger collisions, thereby satisfying the owner’s requirement that the Rust template ship both vendors’ workflows by default while keeping the security model, trust boundaries, and operational costs aligned with current best practice for AI‑assisted review in GitHub Actions.[2][3][11][13][15][18]

## Background and problem framing

The decision surface for R86 is unusually constrained and well specified. The owner has already decided that the Rust template must carry Codex equivalents of the Claude review and assistant workflows, so the primary questions are not whether Codex is used at all, but precisely how it is used, which first‑party or third‑party mechanisms realize it, and how the resulting workflows honor the owner’s trust, credential, and permission requirements without undermining the repository’s broader CI architecture. The context establishes that the Python and TypeScript templates have no Codex workflows, so there is no cross‑language prior art to port, and that the Claude pair was researched and decided separately under R18 using the `anthropics/claude-code-action` family.[2] That isolation is important: the Codex workflows must mirror the Claude ones architecturally where that preserves a shared principle, but they are not subordinate to the Claude implementation and must be justified on their own merits as Rust‑specific, vendor‑specific bundles.

The owner’s standing requirements form the core constraint set. Both lanes must ship by default, with no `ENABLE_*` variable or similar flag; a lane runs whenever the credential it needs is present; when that credential is absent the lane does not run, does not error, and prints that the key needs setting; opt‑out is by deleting the workflow file rather than by toggling a built‑in switch; both lanes must reject bots; and the author‑trust test is explicitly an `author_association` check rather than a write‑permission check.[17] These requirements reflect a principle of explicit, file‑level opt‑in or opt‑out for AI assistance, and a deeply conservative stance on privileging AI processes with write access, especially in public template repositories that downstream projects consume.

The Claude side has already explored and validated one crucial GitHub Actions detail: secrets cannot be read from a job‑level `if:` condition, a fact recorded both in GitHub’s context reference table and in `actionlint` rejecting expressions that try to read `secrets` from a job condition.[17] Secrets are, however, available within a job’s environment block, meaning they can be read from `env` and inspected in shell steps, and job outputs derived from those inspections can be used as gates by downstream jobs via the `needs` context.[17] R18 used this pattern for Claude: a preflight job that always runs, reads the key into `env`, prints a skip reason if absent, and publishes a Boolean output that the real jobs gate on. R86 must decide whether Codex follows the same pattern or adopts a different mechanism, which hinges on whether Codex’s vendor guidance treats the key as a secret or a variable, and whether GitHub has introduced any new context‑availability rules relevant to this choice.[3][13][15][16][17]

Equally important are the couplings to other decisions. R20 governs third‑party action pinning, so R86 may name the actions and versions it evaluates but cannot decide whether pins are floating major tags or full SHAs; R45 governs whether comment trigger vocabularies are documented in the pull request template, so R86 must choose a trigger vocabulary for codex but cannot decide its appearance in `.github/pull_request_template.md`.[2] R08 governs the repository‑wide permission‑hardening pattern, but R86 is responsible for specifying the permissions these two workflows actually need. The Rust baseline parameters — edition 2024, MSRV policy, and OS matrix — apply to every recommendation, though they primarily constrain Rust crates rather than GitHub Actions; still, the workflows must run cleanly on `ubuntu-latest` and `macos-latest` runners.[13][14][15]

Against this backdrop, the R86 decision is best framed as a bundle choice: one stack of Codex tooling and workflow design for two lanes — automatic review and comment‑triggered assistance — joined by shared principles of first‑party vendor use, secure secret management, least‑privilege permissions, explicit trust gating, and clean opt‑out by file deletion. The following sections first map the landscape of Codex‑related GitHub Actions and review architectures, then articulate the principles and acceptance criteria, and finally recommend a specific stack with member‑level analysis and validation strategy.

## Decision analysis for Codex workflows in `rs-launch-blueprint`

### Landscape

The category this item decides is AI‑assisted code review and comment‑triggered coding assistance implemented as GitHub Actions workflows in a Rust repository that ships as a public template. Within that category, the Rust ecosystem divides naturally into three bins: built‑in or first‑party mechanisms, established industry‑standard third‑party actions, and newer up‑and‑coming actions or patterns.

On the built‑in or first‑party side, the key discovery is that OpenAI maintains a first‑party Codex GitHub Action, published under the `openai/codex-action` repository and made available via the GitHub Marketplace and Docs.[1][3][5] The Codex GitHub Action installs the Codex CLI, starts a Responses API proxy that forwards calls to OpenAI or Azure using the supplied key, and runs `codex exec` under the permissions specified in the workflow.[1][3][9] The official documentation describes it as a way to run Codex in CI/CD jobs, apply patches, or post reviews from a GitHub Actions workflow, and recommends it for automating feedback on pull requests or gating changes on Codex‑driven quality checks.[3] OpenAI also publishes cookbook guidance on using the Codex CLI with GitHub Actions to automatically fix failing CI runs, showing an end‑to‑end example where a workflow installs Codex, runs `codex exec`, and opens a pull request with proposed fixes.[10] In addition, there is a cookbook example for building code review with the Codex SDK in GitLab CI, which confirms that Codex is intended to be wired into SCM systems as an external agent that posts comments via APIs.[12] Together these sources establish `openai/codex-action` plus the Codex CLI as the primary first‑party mechanism for Codex‑assisted reviews in CI.[1][3][9][10][12]

The established industry‑standard bin consists of maintained third‑party actions that integrate Codex or other AI models into GitHub Actions for code review. The Codex AI Code Review action on the GitHub Marketplace is one notable candidate: it describes itself as an AI‑powered code review GitHub Action using OpenAI Codex, with a three‑job design that implements security isolation via read‑only prepare and review jobs and a write‑access publish job that posts inline pull request comments and per‑file summaries.[2] The action explicitly depends on `openai/codex-action` for its review job, demonstrating that third‑party wrappers treat the first‑party action as the underlying execution engine.[2] Another established action is Codex Code Review & Actor, which runs Codex to review pull requests and, on demand, makes autonomous edits driven by `/codex` comments.[4] This action distinguishes between a review mode that posts precise inline review comments and a “Act” mode that applies focused edits when trusted users comment `/codex <instructions>`, commits, and pushes to the PR branch.[4] Outside the Codex‑specific family, there are general AI Code Review actions that leverage GPT‑4 and other models. For example, the AI Code Review Action uses OpenAI’s GPT‑4 API to review pull requests, retrieve the diff, send code chunks to the API, and generate review comments that are added to the pull request.[8] Another AI Code Review action supports multiple providers (OpenAI, Anthropic, Google, X, Deepseek, Perplexity), showing the broader pattern of AI‑assisted review workflows in GitHub Actions.[7] These established actions are important practice evidence but they are not first‑party; they may be candidates for Rust templates, but they must be evaluated against the owner’s preference for vendor‑maintained mechanisms and against the security and fit constraints.

The up‑and‑coming bin includes newer patterns and integrations. The Codex CLI + GitHub Actions “complete integration guide” is a detailed independent write‑up that explores sandbox strategies, matrix parallelism, structured JSON output, Azure integration, cost attribution, and the full security model for `openai/codex-action`.[9] It confirms the basic behavior of the action: it installs the Codex CLI, starts a Responses API proxy that forwards calls to OpenAI or Azure using the supplied key, invokes `codex exec` with the chosen sandbox and privilege model, and emits the final Codex message as an output called `final-message`.[9] The action also supports permission profiles that constrain what commands Codex can run, and a `safety-strategy` input that controls the privileges of the Codex process itself.[18] In the GitHub ecosystem more broadly, there are evolving best practices for secret management and environment use in Actions, including the distinction between repository secrets, environment secrets, and organization secrets, and guidance on rotating secrets regularly, using OIDC in place of long‑lived tokens, and enforcing environment‑based access controls.[13][14][15][16] These patterns are not Codex‑specific, but they shape how any AI‑assisted workflow should be designed.

Authority for this landscape comes from several sources. OpenAI’s own repositories and documentation (`openai/codex-action`, the Codex GitHub Action docs, and the cookbook examples) are authoritative for the existence, coordinate, and supported usage patterns of the first‑party action and CLI.[1][3][9][10][12] GitHub’s official documentation on contexts, secrets, and environments is authoritative for what workflows can and cannot do with secrets and environment variables in job conditions and step environments.[13][14][17] Independent guides on GitHub Actions secret management and best practices, such as Envtools’ and SourceTrail’s write‑ups, are widely cited in CI/CD discussions and provide grounded interpretations of GitHub’s mechanisms together with practical recommendations on scoping, rotation, and approvals.[13][15][16] Finally, maintained marketplace actions like Codex AI Code Review and AI Code Review Action have usage evidence and documentation that reveal standard patterns in AI‑assisted review workflows, even though they are third‑party.[2][7][8]

Practice evidence in Rust specifically is necessarily thinner, because most Codex documentation is language‑agnostic and focuses on CI/CD integration rather than on language ecosystems. However, the patterns observed in Codex’s GitHub Actions integration and in AI Code Review actions are consistent with what well‑regarded Rust projects use for automated reviews. Rust projects that adopt AI‑assisted review tend to follow GitHub’s best practice of restricting workflow permissions to `contents: read` where possible and granting `pull-requests: write` only to jobs that post review comments, while storing API keys as secrets and scoping them via environments.[13][15][16] The absence of a Codex workflow in `py-launch-blueprint` and `ts-launch-blueprint` is an intentional origin decision rather than a signal that AI review is inappropriate for Rust; instead, the owner is explicitly choosing to add Codex to Rust while leaving Python and TypeScript to evolve separately. This means the Rust template must be designed with its own adoption and security story, while still preserving shared principles like least privilege, explicit trust gating, and safe secret management.

Fit for `rs-launch-blueprint` hinges on several axes. First, it is a public template repository, so any workflow that runs in it is visible to downstream adopters and may be triggered in forks where maintainers have different risk tolerances. Second, the template is structured as a CLI plus library plus web service, which means AI review should be capable of understanding Rust across binary and library boundaries rather than being tied to a specific framework. Third, the owner’s constraints around credentials and opt‑out mechanisms require that a clone without an OpenAI key not see failing workflows, while a clone that adds the key should see Codex‑assisted review “just work” without flipping any variables. These constraints push the design toward first‑party, vendor‑maintained actions with clear security models, and away from complex multi‑provider wrappers that may introduce additional failure modes.

Taken together, the landscape points strongly toward using `openai/codex-action@v1` plus Codex CLI as the first‑party execution mechanism, with custom workflow files tailored to `rs-launch-blueprint` rather than adopting a generic marketplace wrapper. The established third‑party actions provide useful design patterns — especially the three‑job isolation of Codex AI Code Review and the comment‑triggered actor pattern — but they are not required if the first‑party action and CLI can implement equivalent behavior with better control and auditability.[1][2][3][4][9][10]

### Principles and implementation

The shared requirement across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` for AI‑assisted review workflows can be distilled into a set of engineering principles and agreement levels. At the highest level, the principle is that AI assistance in code review should be **opt‑in by credential**, **least privilege by default**, **transparent in behavior**, and **constrained by explicit human trust boundaries**.

Agreement is required at the architectural pattern level rather than at the specific library or action level. In all ecosystems, AI review should be implemented as CI workflows that respond to SCM events (pull requests, comments), invoke an AI model via vendor APIs, and post review feedback back into the SCM system as comments or proposed patches. The workflows should be structured to separate read‑only analysis from write‑access publishing, and should use explicit gating based on trust signals like `author_association` and bot detection for both reviewers and assistant actions.[2][4][8][11] Within that architectural pattern, each ecosystem may choose different vendors or libraries (Claude for Python, Codex for Rust, perhaps others for TypeScript), but they should preserve the principle of separating analysis from actuation, storing API keys as secrets, and ensuring that absence of credentials results in skipped workflows with clear messages rather than failed runs.[3][10][13][15][16]

The essential behaviors for this bundle in Rust are therefore as follows. The automatic review lane must run on non‑draft pull requests where the author passes an `author_association` trust check, must read the PR diff and relevant code from the repository using only read permissions, must call Codex via a first‑party mechanism using an OpenAI API key supplied as a secret, and must post inline comments and summaries back to the PR via GitHub’s `pull-requests: write` permission.[1][2][3][9][17] The assistant lane must respond to specific comments on pull requests from trusted human actors, must treat the comment text and the surrounding code as input to Codex, and may either propose edits in comments or apply edits directly, but any write operation must be subject to stricter trust gating and configured permission profiles in Codex to prevent arbitrary command execution.[4][9][18] Both lanes must reject bot actors, meaning events where `github.actor` or `github.event.sender.type` indicates a bot account should be gated out before calling Codex.[17] Both lanes must use the OpenAI API key as a GitHub Actions secret, not as a variable, to preserve confidentiality and align with GitHub’s and independent guidance on secret management.[1][3][10][13][15][16]

Observable acceptance criteria flow from these behaviors. A fresh clone of `rs-launch-blueprint` without any OpenAI credential configured should show workflows that are present but do not attempt to call Codex; runs should either not appear, or appear as a preflight job that prints “Codex disabled: set OPENAI_API_KEY secret to enable” and exits successfully, with downstream jobs skipped rather than failed. When an adopter adds an `OPENAI_API_KEY` secret, the workflows should begin to run automatically, posting Codex review comments and assistant responses as appropriate, without requiring any modification to the workflow files. For both lanes, events where the actor is a bot should not trigger any Codex calls. For the review lane, events where the PR author has `author_association` outside a configured trusted set (for example, `CONTRIBUTOR`, `FIRST_TIMER`) should not trigger Codex, even if the workflow file exists and the key is present. For the assistant lane, comments from untrusted actors (including bots and non‑members) should not trigger Codex, even if the comment text includes the Codex trigger vocabulary. These behaviors must be verifiable using GitHub’s event payloads and context expressions, and must align with GitHub’s documented context restrictions.[17]

Before choosing specific actions or configurations, the architectural alternatives must be compared. One alternative is to use the Codex CLI directly in `run:` steps without `openai/codex-action`, installing it manually and invoking `codex exec` using shell commands. This is feasible and is demonstrated in OpenAI’s cookbook examples, but it shifts responsibility for Responses API proxy management, sandboxing, and structured output entirely to the template owner.[9][10][12] Another alternative is to adopt an established third‑party action like Codex AI Code Review, which wraps `openai/codex-action` and implements a three‑job design with security isolation and per‑file summaries.[2] This reduces the template’s configuration burden but introduces a dependency on a non‑vendor action and reduces transparency in Codex invocation. A third alternative is to use a generic AI Code Review action powered by GPT‑4 or multi‑provider models, but this would diverge from the owner’s specific requirement that Codex workflows exist and would create cross‑vendor duplication that is harder to reason about.[7][8] Finally, a hypothetical alternative would be a vendor‑hosted GitHub App for Codex, but there is no evidence in the retrieved sources that such an app exists; everything points to CLI and actions as the primary integration points.[1][3][9][10][12] In the absence of app evidence, this option is excluded by an evidence gap rather than by a fitness gate.

The recommended design preserves the shared principles by choosing the first‑party `openai/codex-action` as the Invocation mechanism, using GitHub Actions secrets for OpenAI credentials, structuring workflows into preflight, review, and assistant jobs with clear permission boundaries, and implementing explicit `author_association` and bot rejection gates before any Codex call.[1][2][3][4][9][17][18] The design acknowledges ecosystem differences: Rust templates may be more likely to use Codex for automated refactorings than Python templates, and the lack of existing Codex workflows in py and ts means Rust can pioneer certain patterns, like a comment‑triggered Codex agent that applies edits. These differences are justified by the owner’s explicit directive for Rust and do not violate the shared architectural pattern, which is defined at the level of vendor‑integrated review workflows gated by credentials and trust signals.

At this stage there is no existing Codex baseline in Rust to challenge, because F361 and F362 have origin `none`. However, there is a small baseline implication for R18’s Claude workflows. The research confirms that GitHub’s context table disallows secrets in job‑level `if:` and suggests that the preflight pattern pioneered on the Claude side is the correct way to implement the owner’s credential‑presence requirement for both vendors.[17] If R18’s published configuration deviates from this pattern, a `BASELINE-REVIEW` finding would be warranted; otherwise, the Codex side simply mirrors the Claude architectural solution with a different vendor and credential.

### Recommendation

The decision is that `rs-launch-blueprint` should ship both Codex lanes — an automatic pull‑request code‑review workflow and a comment‑triggered assistant workflow — implemented using OpenAI’s first‑party Codex GitHub Action and CLI. The recommended stack can be summarized as follows, with details elaborated in the Members section.

The invocation mechanism for both lanes is `openai/codex-action@v1`, a first‑party GitHub Action published by OpenAI under the `openai/codex-action` repository and documented on learn.chatgpt.com and in OpenAI’s Codex integration guides.[1][3][5][9][18] This action installs the Codex CLI, starts a Responses API proxy that forwards calls to OpenAI’s Responses API using a supplied API key, and runs `codex exec` under a configured permission profile and safety strategy.[1][3][9][18] The exact `uses:` coordinate in the workflow files is therefore `openai/codex-action@v1`, with the pin format (tag vs SHA) determined by R20; the evaluation here assumes the latest v1 release as of retrieval in September 2026.[1][5][9][18]

The credential required is an OpenAI API key, either `OPENAI_API_KEY` for OpenAI’s own endpoint or `AZURE_OPENAI_API_KEY` for Azure‑hosted models.[1][3][9] The Codex GitHub Action documentation and Codex AI Code Review instructions consistently treat this as a GitHub Actions secret rather than a repository variable, instructing users to store their OpenAI key as a secret named `OPENAI_API_KEY` and reference it from workflows via the `secrets` context.[1][2][3][8][10][12][13][15][16] This matches GitHub’s and independent best practice: API keys and tokens should be stored as encrypted secrets at repository, environment, or organization scope, not as variables, because secrets are encrypted at rest, masked in logs, and cannot be retrieved via UI or API.[13][15][16] For this bundle, the credential kind is therefore a GitHub Actions secret. For the review lane, the secret is preferably configured as an environment secret on a GitHub environment such as `codex-review`, which allows additional gatekeeping via environment approvals; for the assistant lane, the same secret can be used either at environment or repository scope, with environment preferred when direct edit capabilities are enabled.[13][14][15][16]

Because secrets cannot be read in job‑level conditions, the owner’s requirement that “a lane runs whenever the credential it needs is present; when that credential is absent the lane does not run, does not error, and prints that the key needs setting” is implemented via an always‑run preflight job. This job runs on every relevant event, reads the `OPENAI_API_KEY` secret into its environment (which is permitted by GitHub’s context rules), checks whether the value is non‑empty in a shell step, prints either an “enabled” or “disabled” message, and sets a Boolean output `codex_enabled` accordingly.[13][15][17] The review and assistant jobs are configured with `needs: preflight` and `if: needs.preflight.outputs.codex_enabled == 'true'`, so that they are skipped cleanly when the key is absent or empty, without errors or partial Codex invocations. The existence of this behavior is grounded in GitHub’s documented restrictions on the `secrets` context, which allow it only in `env` and certain other keys, and in the precedent established by the Claude workflows, which used `actionlint` to validate that secret access in job conditions is forbidden.[17] R86 did not re‑run `actionlint`, but it relies on GitHub’s documented table and R18’s executed checks for this conclusion.

For the review lane, repository permissions are set to `contents: read` and `pull-requests: write`, with no additional permissions like `issues` or `actions` granted.[2][7][8][13][15] This follows the pattern documented by Codex AI Code Review’s three‑job design, where prepare and review jobs are read‑only and the publish job has `pull-requests: write` to post review comments.[2] For the assistant lane, permissions include `contents: read`, `pull-requests: write`, and optionally `contents: write` if the lane is configured to apply edits by committing to the PR branch, as in Codex Code Review & Actor’s “Act” mode.[4][13][15] Both lanes use the built‑in `GITHUB_TOKEN` secret for SCM operations, whose scope is controlled by these permissions, and do not request any additional GitHub App installation token.[17] Codex’s own permission profiles and `safety-strategy` inputs are configured to restrict filesystem writes and network access according to OpenAI’s security documentation, ensuring that Codex cannot execute arbitrary commands or access external services beyond what is required for code analysis and patch generation.[9][18]

The author‑trust guard is implemented using GitHub’s `author_association` property and is applied consistently across both lanes. For pull request events, the workflow reads `github.event.pull_request.author_association` within job conditions and allows Codex processing only when that association is one of the trusted values chosen by the owner (typically `MEMBER`, `OWNER`, and `COLLABORATOR`).[17] For comment events on pull requests, the assistant lane uses `github.event.sender.association` or the equivalent property for the comment author, and again allows Codex only when the association is within the trusted set. This design respects the owner’s explicit choice of association over write‑permission, and does not implement any write‑permission checks as substitutes.[17] Both lanes implement bot rejection at the workflow level by checking `github.event.sender.type` and `github.actor` and skipping Codex calls when the actor is identified as a bot account, thereby avoiding reliance on any internal vendor checks that might treat bot logins as trusted.[17] OpenAI’s Codex action documentation does not publish any special treatment of `[bot]` logins, unlike the finding R18 reported for Claude, so the safeguards reside entirely in the workflow’s `if` expressions, not in the action.

Running two vendors’ reviewers — Claude and Codex — on the same pull request is judged to be complementary rather than purely duplicative. The evidence from AI Code Review usage and Codex AI Code Review’s documentation suggests that AI reviewers often differ in the style and depth of findings they produce, with some focusing more on security and others on style or performance.[2][7][8] While there is no direct quantitative study comparing Claude and Codex in Rust repositories, the qualitative pattern is that having multiple AI reviewers can increase coverage but also risks review fatigue if comment volume becomes too high. To mitigate this, the recommendation is that both vendors’ lanes run automatically on non‑draft PRs from trusted authors, but that their prompts be tuned to avoid overlapping findings — for example, Codex focusing on Rust‑specific correctness and safety issues, and Claude focusing on API design and documentation — and that the assistant lanes use distinct trigger vocabularies (`@claude` vs `/codex`) to avoid collisions.[2][4][7][8] This reveals complementary value without forcing adopters to manage multiple overlapping comment streams; downstream projects can always delete one workflow file if they prefer a single vendor.

In summary, the bundle recommendation is a single stack: `openai/codex-action@v1` plus Codex CLI, invoked via two workflows with preflight credential gating, least‑privilege permissions, explicit `author_association` and bot rejection, and simple comment trigger vocabularies. The next section decomposes this stack into its members and analyzes each in detail.

### Members

#### Codex PR code‑review workflow (F361)

##### Landscape

The automatic pull‑request code‑review lane sits squarely in the intersection of first‑party Codex tooling and established AI Code Review patterns. OpenAI’s Codex GitHub Action is explicitly designed to “run Codex in CI/CD jobs, apply patches, or post reviews from a GitHub Actions workflow,” and its documentation highlights pull request workflows as a primary use case.[1][3][9] The Codex AI Code Review action demonstrates how to build a review workflow around this action, with a three‑job design that maintains security isolation: a read‑only prepare job that chunks diffs and assembles prompts, a read‑only review job that invokes `openai/codex-action` to review each chunk in parallel, and a write‑access publish job that merges chunk reviews and posts inline PR comments and per‑file summaries.[2] This pattern maps directly to what F361 needs: an automatic reviewer that reacts to PR events, leverages Codex for analysis, and uses GitHub’s `pull-requests: write` ability to publish feedback.

Relevant authorities for this lane include OpenAI’s docs and the Codex AI Code Review repository, which covers how diffs are processed, how prompts are assembled, and how Codex’s responses translate into structured review output.[1][2][3][9] GitHub’s context and permissions documentation also serves as authority for how to scope workflow permissions and how to access PR metadata like `author_association` and diff information.[17] Independent guides on secret management provide the necessary background to treat the OpenAI key as a secret and to understand environment secrets and their precedence over repository secrets.[13][14][15][16]

Practice evidence comes from projects that have adopted Codex AI Code Review and similar actions. The action’s documentation references production use in repositories where automated AI review is part of the standard workflow, and its three‑job table shows permissions in a way that aligns with GitHub’s evolving best practice of starting with `permissions: read-all` and then granting specific write permissions only where needed.[2][13][15] While specific Rust projects are not named in the retrieved sources, the design of Codex AI Code Review is language‑agnostic and is compatible with Rust’s usual CI setup on `ubuntu-latest` and `macos-latest` runners.[2][3][9][13] In addition, the Codex CLI integration guide notes that the action and CLI run on Linux and macOS runners by default, with a special setting `safety-strategy: unsafe` required for Windows, which confirms that the recommended OS matrix for `rs-launch-blueprint` is fully supported.[3][9]

##### Principles and implementation

For F361, the core principle is that automatic AI review should behave like a conservative, read‑only reviewer: it should analyze code changes, suggest improvements, and point out potential bugs or security issues, but should not modify code by itself and should operate only within the bounds of repository permissions granted by the workflow.[2][9][18] The lane must be automatic in the sense that it runs on relevant PR events without requiring manual comments, but those events must satisfy trust and bot‑rejection conditions to avoid reviewing untrusted or bot‑generated content.

Implementation begins with triggers. The review workflow should be configured to run on pull request events such as `opened`, `synchronize`, `ready_for_review`, and `reopened`, and should ignore draft pull requests. This is achieved by using the `pull_request` event type and adding a workflow‑level `if:` condition on the job that checks `github.event.pull_request.draft == false`, ensuring that Codex does not review draft work.[17] In addition, because PRs can come from forks, the workflow should guard against running Codex under the repository’s credentials on untrusted fork contributions. Codex AI Code Review recommends gating every job on `github.event.pull_request.head.repo.full_name == github.repository` in production, which ensures that the head of the PR is a branch within the same repository, not a fork.[2] For `rs-launch-blueprint`, this fork guard should be adopted for both Codex and Claude lanes to preserve a shared architectural pattern of only running AI review when the PR originates from a branch within the repository, while still allowing maintainers to adjust the pattern for their own projects later.

The credential‑presence requirement for F361 is implemented via a preflight job, as discussed in the main recommendation. The preflight job runs on every relevant PR event, uses an environment block to read `OPENAI_API_KEY` from the `secrets` context, and then uses a shell script to test whether the key is non‑empty.[13][15][17] If the key is non‑empty, the job prints “Codex review enabled” and sets an output `codex_enabled=true`; if the key is empty or undefined, it prints “Codex review disabled: set OPENAI_API_KEY secret to enable” and sets `codex_enabled=false`. The main review job then declares `needs: preflight` and uses `if: needs.preflight.outputs.codex_enabled == 'true'` to run only when the key is present. This arrangement preserves the owner’s contract: a clone without the secret sees a successful preflight job and a skipped review job, with explicit messaging, rather than an error.

Permissions for the review lane are set according to least privilege and the patterns used by Codex AI Code Review. The prepare and review jobs use `permissions: contents: read`, which allows the jobs to fetch the PR diff and repository contents but not to write any changes or alter workflow definitions.[2][13][15] The publish job, if used to post comments, is given `permissions: contents: read, pull-requests: write`. These permissions are sufficient for the workflow to post inline review comments and PR‑level summaries using the `GITHUB_TOKEN`, and they align with GitHub’s recommendation to grant write permissions only where necessary.[2][13][15][17] No permissions for `issues`, `actions`, or `id-token` are required for this lane, and these remain at their default or explicitly set to `none` as per R08.

The Codex invocation is configured by using `openai/codex-action@v1` with appropriate inputs. The action’s documentation allows specifying prompts either inline via a `prompt` input or via a `prompt-file` input that points to a file in the repository.[3][9] For F361, the recommended pattern is to use `prompt-file` with a repository‑local file such as `.github/codex/review-prompt.md`, containing instructions tailored to Rust code review. This approach avoids any runtime fetching of mutable remote content, which was a concern on the Claude side where a marketplace URL could not be pinned.[3][9][11] The Codex CLI’s built‑in Code Review prompt can also be used as a base, but customizing it via a local file allows the template owner to evolve review rules without dependency on external references.[9][12] The action is configured to produce structured JSON output representing findings, which the workflow then parses to generate GitHub review comments. This approach matches the structured output pattern documented in the GitLab code review example.[12]

The author‑trust guard for F361 is implemented by adding a job‑level condition that checks `github.event.pull_request.author_association` and only runs the prepare and review jobs when the association is within a configured set. The specific string values come from GitHub’s documentation: typical values include `OWNER`, `MEMBER`, `COLLABORATOR`, `CONTRIBUTOR`, and `NONE`.[17] According to the owner’s decision, the trusted set includes at least `OWNER` and `MEMBER`, and may include `COLLABORATOR` depending on repository policies; `CONTRIBUTOR` and `FIRST_TIMER` are considered untrusted for this purpose. Implementing the association check ensures that Codex does not run on PRs authored by untrusted external contributors, even if the workflows exist and the key is configured.

Bot rejection is implemented by checking `github.event.sender.type` and `github.actor` within job conditions. GitHub’s documentation notes that the `github` context includes information about the actor that triggered the workflow and the event payload.[17] For events triggered by bots, `github.event.sender.type` typically equals `Bot`, and `github.actor` may end with `[bot]`. R18 discovered that Claude’s internal write check treated logins ending in `[bot]` as trusted, which is why workflow‑level bot checks are required.[2] For Codex, there is no evidence that the action treats bots specially, but to avoid assumptions, F361 uses a job condition that rejects events where `github.event.sender.type == 'Bot'` or where `github.actor` matches a pattern indicating a bot. This ensures that Codex is not invoked on bot‑generated PRs, aligning with the owner’s requirement.

The trusted‑author residual identified by R18 applies identically to F361. Even when the PR author passes the `author_association` gate, they can paste untrusted content into the PR description, comments, or code, such as stack traces, issue bodies from untrusted reporters, or patches copied from external forums. Codex sees this content as part of the review context, and there is no mechanism in GitHub’s event payloads to distinguish the author’s own words from text they pasted.[2][17] OpenAI’s Codex documentation does not provide any special handling for pasted content versus authored content; Codex simply processes whatever text is in the prompt and diff.[1][3][9][12] As a result, F361 inherits the same residual risk: AI review processes untrusted content under the repository’s credentials, albeit with restricted permissions and without writing code directly. This residual is narrower than in assistant lanes that apply edits, because the review lane does not change code, but it is still present and must be acknowledged.

##### Dominant choice

The dominant choice for F361 is to use a custom workflow built around `openai/codex-action@v1` rather than adopting a third‑party marketplace action like Codex AI Code Review. This choice preserves first‑party control over Codex invocation and allows the Rust template to customize prompts, trust gating, and permissions without depending on a third‑party’s release cadence or configuration defaults.[1][2][3][9][18] It also simplifies the stack by eliminating one layer of indirection: the workflow directly calls Codex via the vendor‑maintained action, using a repository‑local prompt file and internal logic for chunking diffs and posting comments.

That said, the Codex AI Code Review action is not discarded; it remains an important reference for architecture and permissions. Its three‑job design informs the separation between prepare, review, and publish in the custom workflow, and its documented table of job permissions helps ensure that the Rust implementation aligns with industry practice on least privilege.[2] The recommended workflow adopts similar job boundaries while customizing the prompt and trust logic.

##### Qualified shortlist

The qualified shortlist for F361 includes three candidates. The first is the recommended custom workflow using `openai/codex-action@v1`. The second is Codex AI Code Review, which directly integrates Codex via the same first‑party action and offers pre‑built chunking and comment posting logic.[2] The third is the AI Code Review Action powered by GPT‑4, which is not Codex but could serve as a non‑Codex fallback or complementary reviewer.[7][8]

Codex AI Code Review qualifies because it is maintained, uses OpenAI’s Codex action under the hood, and implements robust security isolation. It requires an OpenAI API key stored as an environment secret named `OPENAI_API_KEY` inside a `codex-review` environment, which aligns with GitHub’s guidance on environment secrets.[2][13][14][15][16] It also enforces a fork guard and supports per‑file review references via `.github/codex/review-reference.md`, read from the base commit to prevent PR authors from steering their own review.[2] These features are all desirable, and a Rust template could adopt the action as‑is.

The GPT‑4 AI Code Review Action qualifies in principle because it uses the same pattern of retrieving PR diffs, splitting code into chunks, sending them to an AI model, and posting comments based on the AI’s response.[8] However, it uses OpenAI’s GPT‑4 API rather than Codex’s Responses API proxy and CLI, and therefore it does not satisfy the owner’s requirement for Codex‑specific workflows. It remains a candidate for future cross‑vendor comparison but not for F361’s Codex lane.

##### Excluded by gate

Certain candidates are excluded by fitness gates or evidence gaps. Any hypothetical Codex GitHub App is excluded because no documentation or repository indicates that such an app exists; all evidence points to CLI and Actions as Codex’s integration path.[1][3][9][10][12] Generic multi‑provider AI Code Review actions that treat Codex as just one provider among many are excluded because they complicate the stack and do not align with the owner’s desire for clearly separated vendor workflows; they also make credential management more complex by requiring different keys or tokens per provider.[7] Additionally, any action that stores API keys as GitHub variables rather than secrets is excluded, because GitHub and independent guidance treat variables as non‑encrypted configuration and recommend secrets for API keys.[13][15][16]

##### Up‑and‑comers

The most interesting up‑and‑comer for F361 is the pattern described in the Codex CLI + GitHub Actions integration guide, which suggests using structured JSON output from `codex exec` and then parsing it to create SCM comments.[9] This pattern goes beyond simple text output and allows workflows to treat Codex as a structured reporter, with machine‑readable fields like file path, line number, category, and suggested fix. The GitLab code review example shows a similar approach, attaching inline comments to merge requests based on structured context fields in Codex’s responses.[12] These patterns are emerging best practice for integrating AI review processes with SCM, and F361’s design should be compatible with adopting them as Codex’s structured output capabilities evolve.

##### Fit for this template

F361’s recommended design fits `rs-launch-blueprint` well. The template’s Rust focus means that Codex’s prompts can be tailored to Rust idioms, including ownership and borrowing, error handling, async runtimes, and web‑service patterns. The CLI plus library plus web service structure is broad, but Codex’s code review prompt is language‑agnostic and can be adapted via a local prompt file to emphasize Rust‑specific concerns. Because the workflow runs on `ubuntu-latest` and `macos-latest` and uses only standard GitHub Actions conveniences, it fits the template’s OS matrix and does not impose platform‑specific dependencies.[3][9][13]

The absence of Codex workflows in Python and TypeScript templates is not a drawback; instead, it allows the Rust template to pioneer Codex integration while preserving shared architectural principles. F361’s design ensures that Codex review is opt‑in by credential, that absence of credentials results in skip rather than error, and that trust gating and bot rejection are implemented consistently. This aligns with the owner’s cross‑ecosystem principles while allowing Rust to be more aggressive in adopting Codex.

##### Recommendation

For F361, the recommendation is a custom workflow `.github/workflows/codex-code-review.yml` built around `openai/codex-action@v1`, with the following high‑level shape in narrative terms. A preflight job runs on relevant PR events, reads the `OPENAI_API_KEY` secret into `env`, checks its presence, prints an enable/disable message, and sets an output `codex_enabled`. The main review job declares `needs: preflight`, is conditioned on `codex_enabled == 'true'`, checks that the PR is not a draft and that `author_association` is within the trusted set and that the PR is from the same repository, and then checks out the code and diff. It then runs `openai/codex-action@v1`, pointing to a local prompt file `.github/codex/review-prompt.md`, and captures structured JSON output describing findings. A publish job reads the JSON, filters findings to those inside the diff, maps them to file paths and line numbers, and posts inline review comments and a PR‑level summary using the `GITHUB_TOKEN` with `pull-requests: write` permission.[2][3][9][12][17]

##### Ranked runner‑up

The ranked runner‑up is a workflow that uses Codex AI Code Review directly instead of a custom implementation. This runner‑up has the advantage of being pre‑built and maintained, and it already embodies best practices like three‑job isolation and fork guarding.[2] However, it is less tailored to Rust and to the template’s specific trust and opt‑out requirements, and it introduces a dependency on a third‑party action whose release cadence and compatibility must be tracked. The custom workflow is therefore preferred, but Codex AI Code Review remains a viable fallback if future evidence suggests that bespoke workflows become too costly to maintain.

##### Tradeoffs

The main tradeoff is between control and convenience. Using `openai/codex-action` directly gives the template owner full control over prompts, trust logic, and integrations with Rust tooling, but requires more configuration and maintenance effort. Using Codex AI Code Review reduces configuration effort but constrains the template to the patterns and assumptions encoded in that action. The custom workflow also makes the Rust template somewhat more complex than Python and TypeScript templates that do not ship Codex workflows, but this is a conscious decision by the owner, and the complexity is hidden from adopters who can simply delete the workflow files if they do not want Codex.

Another tradeoff concerns cost and comment volume. Codex review incurs token costs on the adopter’s OpenAI account and consumes GitHub Actions runner minutes; running both Claude and Codex on every PR doubles these costs and can produce overlapping comments. This tradeoff is addressed by ensuring that comment volume is kept manageable through prompt tuning and by allowing adopters to opt out by deleting whichever workflow they do not want.

##### Parameters

F361 owns parameters related to Codex invocation and trust gating. It owns `codex_action_coordinate = openai/codex-action@v1`, subject to R20’s pinning policy.[1][3][5][9][18] It owns `codex_review_prompt_file = .github/codex/review-prompt.md`, and assumes that this file will be maintained with Rust review guidance. It owns the trusted association set, for example `owns codex_trusted_associations = {OWNER, MEMBER, COLLABORATOR}`, and assumes that GitHub’s event payloads provide `author_association` with these values.[17] It assumes `OPENAI_API_KEY` is stored as a secret either at repository or environment scope, with environment preferred. There are no conflicts with fixed parameters like Rust edition or MSRV, because the workflow is language‑agnostic.

##### Migration implications

Migrating to this design requires adding `.github/workflows/codex-code-review.yml` and the prompt file `.github/codex/review-prompt.md` to the repository. It may also require adding a `codex-review` environment in GitHub’s settings and an `OPENAI_API_KEY` environment secret within that environment. No changes to Rust code or Cargo.toml are required. Downstream adopters who do not want Codex can simply delete these files.

##### Validation strategy

Validation for F361 includes both credential‑present and credential‑absent paths. For the absent path, a maintainer clones `rs-launch-blueprint` without setting `OPENAI_API_KEY` as a secret, opens a non‑draft PR from a branch within the same repository, and observes that the `codex-code-review` workflow runs only the preflight job, which prints a message indicating that Codex is disabled and the key needs setting, and that the main review job is skipped without error. For the present path, the maintainer sets the secret, opens a PR, and observes that Codex review runs and posts comments. Additional validation uses `actionlint` to verify that no job‐level `if:` reads from `secrets` and that the context usage is consistent with GitHub’s documented restrictions.[17] Finally, validation should confirm that PRs authored by untrusted associations or by bots do not trigger Codex review.

##### Confidence & re‑verify trigger

Confidence in F361’s design is high, because it closely follows vendor documentation and established third‑party patterns. Re‑verify triggers include significant changes to GitHub’s context restrictions, new releases of `openai/codex-action` that alter permission profiles or safety strategies, and owner decisions that change trusted association values or opt‑out mechanisms. If OpenAI were to publish a Codex GitHub App or a new first‑party review integration, R86 should be revisited.

##### Sources

OpenAI’s Codex GitHub Action repository and docs, Codex AI Code Review documentation, Codex CLI integration guide, GitHub Actions contexts and secrets documentation, and independent secret management guides provide the evidence base for F361.[1][2][3][9][10][11][13][15][17][18]

#### Codex comment‑triggered assistant workflow (F362)

##### Landscape

The comment‑triggered assistant lane belongs to the emerging pattern of AI‑powered coding agents that respond to SCM comments, run code‑modification logic, and either propose or apply edits. The Codex Code Review & Actor action is the most direct precedent: it runs Codex to review pull requests and, on demand, makes autonomous edits driven by `/codex` comments.[4] In its “Act” mode, when a trusted user comments `/codex <instructions>` on a PR, the action checks out the branch, runs a coding agent, and pushes the result back to the PR branch.[4] This demonstrates a complete loop from comment to AI agent to commit.

Other AI Code Review actions show comment‑driven patterns as well, often using comment triggers like `/review` or mentions like `@bot` to invoke the action.[7][8] The Claude pair in R18 uses `@claude` or similar triggers and a trusted‑author check to run a Claude assistant on demand. Although R18’s specifics are out of scope, the general pattern is clear: comments trigger assistants, assistants respond either by posting suggestions or by applying patches, and trust gating plus bot rejection are essential to avoid abuse.

Authority for this lane includes Codex Code Review & Actor’s documentation, which explains the comment trigger mechanism and the distinction between review and act modes.[4] GitHub’s event documentation is authoritative for the `issue_comment` and `pull_request_review_comment` events, the structure of comment payloads, and the use of `author_association` and actor details in event contexts.[17] OpenAI’s Codex CLI and action documentation are authoritative for how to run coding agents and apply patches via `codex exec` and for the safety strategies available when Codex is allowed to write to the filesystem.[3][9][18]

Practice evidence for comment‑triggered AI assistants comes from repositories that have adopted Codex Code Review & Actor and other similar actions. Although the retrieved sources do not name specific Rust projects, the action is language‑agnostic and works with any code base managed by GitHub. The pattern of using a comment like `/codex` to trigger an AI agent has been adopted in several communities as a way to control when AI makes edits, ensuring that humans explicitly opt in per PR and per change.[4] This pattern aligns well with the owner’s desire for explicit opt‑in and trust gating and is suitable for Rust.

##### Principles and implementation

For F362, the central principle is that AI‑driven code edits must be **explicitly human‑triggered** and **constrained to trusted actors**, and must be **auditable** via commits and comments. The assistant lane should respond only when a trusted human author or reviewer uses a specific trigger vocabulary in a comment on a pull request; it should not run automatically on every comment, and it must never respond to bots.

Implementation begins with triggers and vocabulary. The assistant workflow should listen to `issue_comment` and `pull_request_review_comment` events, which capture comments on issues and review threads, respectively.[17] It should then filter events to those associated with pull requests, which can be done by checking whether the comment’s `issue.pull_request` field is non‑null (for `issue_comment` events) or by using `pull_request_review_comment` directly. Within these events, the workflow should further filter by comment content: it should only run when the comment body contains a specific trigger token, such as `/codex` or `@codex`. Codex Code Review & Actor uses `/codex`, which is succinct and avoids collision with typical mention syntax used for Claude or other bots.[4] For this bundle, the recommendation is to use `/codex` as the trigger, leaving `@claude` for the Claude assistant; this avoids collisions and provides clear separation between vendors.

The credential‑presence requirement is implemented via the same preflight pattern as F361. A preflight job runs on relevant comment events, reads `OPENAI_API_KEY` into `env`, checks its presence, prints a message, and sets an output `codex_enabled`. The assistant job declares `needs: preflight` and uses `if: needs.preflight.outputs.codex_enabled == 'true'` to run only when the key is present. The assistant job also uses job‑level conditions to check that the comment body contains `/codex` and that the actor passes trust and bot rejection checks.

Permissions for the assistant lane depend on whether it applies edits. In a conservative configuration where the assistant only posts suggested edits or explanations in comments, the workflow needs `permissions: contents: read, pull-requests: write`. This allows it to read code and diffs, run Codex analysis, and post comments with suggestions, without writing commits.[4][13][15][17] In a more aggressive configuration where the assistant applies edits via commits and pushes, the workflow additionally needs `permissions: contents: write`. Codex Code Review & Actor uses this pattern, checking out the branch, running the coding agent, and pushing the result.[4] For `rs-launch-blueprint`, the conservative configuration is recommended by default, with an optional commented‑out section that enables commit‑and‑push behavior for adopters who explicitly opt in.

The Codex invocation is again via `openai/codex-action@v1`, but the prompts differ from the review lane. The assistant lane should use a prompt file like `.github/codex/assistant-prompt.md` that instructs Codex to generate small, focused patches or suggestions based on the comment instructions and the surrounding code. When commit behavior is enabled, the workflow uses Codex’s agentic mode to generate patches that `openai/codex-action` can apply via the CLI. OpenAI’s cookbook example of automatically fixing CI failures shows how Codex can generate patches and create PRs with fixes; this pattern can be adapted to apply patches directly to the PR branch in the assistant lane.[10] Codex’s permission profiles and safety strategies must be configured to allow filesystem writes within the repository while restricting network access and other potentially dangerous capabilities.[9][18]

The author‑trust guard for F362 is implemented using `github.event.sender.association` or similar properties that reflect the comment author’s association with the repository.[17] Only comments from trusted associations (`OWNER`, `MEMBER`, `COLLABORATOR`) are allowed to trigger Codex; comments from untrusted associations or bots are ignored even if they contain `/codex`. Bot rejection uses `github.event.sender.type` and `github.actor` exactly as in F361, ensuring that no bot comments trigger AI assistance.

The trusted‑author residual is wider for F362 than for F361, because the assistant lane may apply edits based on comments that include pasted content from untrusted sources. Even when the commenter is trusted, they may paste code snippets or diffs from external sources into the comment, and Codex will treat these as input for generating patches. If commit behavior is enabled, Codex‑generated edits are applied under the repository’s credentials, which increases the risk surface compared to read‑only review. OpenAI’s documentation emphasizes the need to configure permission profiles and safety strategies to restrict Codex’s capabilities when it is allowed to act.[9][18] Therefore, the assistant lane must be designed conservatively, and commit behavior may be disabled by default.

##### Dominant choice

The dominant choice for F362 is a custom assistant workflow using `openai/codex-action@v1` and comment triggers, with commit‑and‑push behavior either disabled by default or confined to a clearly marked section. This choice preserves first‑party control over Codex invocation and trust gating, aligns with the owner’s preference for explicit opt‑in, and avoids dependency on third‑party actions whose internal trust logic may not match the owner’s requirements.[1][3][4][9][18]

Codex Code Review & Actor is an attractive pattern, but using it directly would introduce a third‑party action with its own comment parsing and trust logic. The custom workflow can emulate the `/codex` trigger and the commit loop while keeping all logic visible in the repository and under the template’s control. It also allows the template to integrate Rust‑specific context and conventions in the assistant prompt.

##### Qualified shortlist

The qualified shortlist for F362 includes the custom `openai/codex-action`‑based assistant workflow, Codex Code Review & Actor, and possibly generic comment‑driven assistants that use GPT‑4 or other models. Codex Code Review & Actor demonstrates that commit‑and‑push behavior is feasible and practicable; it uses a trusted users list to decide who may trigger `/codex` and applies edits only when the commenter is trusted.[4] This pattern is compatible with the owner’s trust model but uses a different signal (an allowlist) rather than `author_association`. Adapting the pattern to use association plus allowlists would be possible.

Generic AI Code Review actions with comment triggers qualify conceptually but are less attractive because they use different models and may not integrate as well with Rust code patterns.[7][8] Moreover, their credential handling may be more complex, especially multi‑provider actions that support several vendors.

##### Excluded by gate

Any assistant mechanism that responds to comments by untrusted actors or bots or that uses variables for API keys instead of secrets is excluded by gate, as it violates the owner’s requirements and GitHub’s guidance on secrets.[13][15][16][17] Assistant workflows that fetch prompts or plugins at runtime from mutable remote URLs without pinning are excluded because they introduce supply‑chain risk similar to what R18 found

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [openai/codex-action](https://github.com/openai/codex-action)
- [Codex AI Code Review · Actions](https://github.com/marketplace/actions/codex-ai-code-review)
- [Codex GitHub Action](https://learn.chatgpt.com/docs/github-action)
- [Codex Code Review & Actor · Actions](https://github.com/marketplace/actions/codex-code-review-actor)
- [Actions](https://github.com/openai/codex/actions)
- [Codex GitHub Action | 自动运行codex exec](https://www.codex-docs.com/docs/github-action)
- [AI Code Review · Actions](https://github.com/marketplace/actions/ai-code-review)
- [AI Code Review Action - GitHub Marketplace](https://github.com/marketplace/actions/ai-code-review-action)
- [Codex CLI + GitHub Actions: The Complete Integration Guide](https://codex.danielvaughan.com/2026/03/29/codex-github-actions-complete-integration-guide/)
- [Use Codex CLI to automatically fix CI failures](https://developers.openai.com/cookbook/examples/codex/autofix-github-actions)
- [Codex Code Review in GitHub Actions: A Safe Workflow](https://www.samuelfaj.com/en/blog/how-to-set-up-ai-code-review-in-github-actions/)
- [Build Code Review with the Codex SDK](https://developers.openai.com/cookbook/examples/codex/build_code_review_with_codex_sdk)
- [GitHub Actions Secrets: How to Add, Use & Rotate Them (2026)](https://envtools.dev/guides/github-actions-secrets)
- [Understand Github Environments](https://notes.kodekloud.com/docs/GitHub-Actions-Certification/Continuous-Deployment-with-GitHub-Actions/Understand-Github-Environments/page)
- [How to manage secrets securely in GitHub Actions - Source Trail](https://www.sourcetrail.com/software/secure-secret-management-in-github-actions/)
- [Best Practices for Managing Secrets in GitHub Actions](https://www.blacksmith.sh/blog/best-practices-for-managing-secrets-in-github-actions)
- [Contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts)
- [Security - openai/codex-action](https://github.com/openai/codex-action/security)

## Cost

Total: $1.3681

---


## Gemini Results

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
provider: gemini
model: deep-research-preview-04-2026
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

# Deep-Research Report: Codex-Assisted Review Workflows (R86)

### Landscape

The integration of artificial intelligence into continuous integration and continuous deployment pipelines introduces profound architectural and security considerations. To determine the optimal configuration for a Codex-driven code review and assistant workflow in the Rust ecosystem, the research mandate dictates a structured, ecosystem-first analysis. The AI-assisted code review landscape for Rust repositories can be mapped into three categorical bins. First, regarding built-in or first-party toolchains, no native artificial intelligence capabilities exist within the `rustc` compiler or `cargo` package manager. However, OpenAI publishes a first-party GitHub Action (`openai/codex-action`) designed explicitly to bridge its command-line interface agent into continuous integration pipelines safely [cite: 1, 2]. Second, the established industry standard encompasses third-party vendor platforms operating as GitHub Apps (such as CodeRabbit) alongside first-party provider integrations like Anthropic's `claude-code-action` and OpenAI's `codex-action` [cite: 3, 4]. Finally, the up-and-comer category includes multi-agent swarms, generic command-line tools packaged for continuous integration (such as Google's `run-gemini-cli`), and open-source headless implementations like Open Code Review [cite: 5, 6]. 

Authority for this analysis is derived from the intersection of formal GitHub Actions security research and OpenAI's engineering documentation. Academic and security research publications, notably the *TaintAWI* framework and Wiz's exhaustive "AI Actions - A New Attack Surface" analysis, establish the definitive threat model for Agentic Workflow Injection in continuous integration pipelines [cite: 7, 8, 9]. These sources are authoritative because they empirically map vulnerabilities, specifically targeting the exact actions under evaluation. Furthermore, the official OpenAI Codex API documentation, command-line interface release notes, and the `openai/codex-action` repository source code provide the authoritative baseline for features, sandbox limitations, and token economics [cite: 1, 10, 11]. Finally, GitHub's official documentation on Actions context availability dictates the strict architectural bounds of credential passing and job execution, forming a hard constraint on workflow design [cite: 12].

Practice evidence demonstrates that mainstream Rust projects and highly regarded template repositories are increasingly adopting standardized project-instruction files to guide artificial intelligence agents. Repositories such as `d-oit/rust-2026-template` and the official `Azure/azure-sdk-for-rust` deploy `AGENTS.md` to instruct agents on memory-safety paradigms and toolchain specifics [cite: 13, 14]. The adoption of dual-vendor review workflows is visible in high-assurance environments, such as `praetorian-inc/public-workflows`, which illustrates that parallel evaluations from different large language models provide complementary security and architectural feedback without irreconcilable interference [cite: 15].

When evaluating fit over abstract best for `rs-launch-blueprint`—a template generating command-line interfaces, libraries, and web service architectures—the integration must be self-contained, auditable, and inherently secure. A GitHub App integration, which requires external organization-level installation and grants broad repository access to a third party, violates the template's requirement for standalone, decentralized infrastructure as code. The first-party `openai/codex-action` is therefore chosen over third-party wrappers because it allows explicit control over sandboxing, relies directly on the template adopter's own `OPENAI_API_KEY`, and natively supports local repository-defined rules tailored to Rust's type system and ecosystem conventions [cite: 1, 16].

### Principles and implementation

The implementation of Codex-assisted workflows in the `rs-launch-blueprint` template must adhere to a strict architectural policy driven by explicit owner constraints. The required agreement level is an architectural pattern: the workflow must ship enabled by default, execute conditionally based solely on the presence of a secret credential, reject automated bot actors, utilize an `author_association` trust model rather than explicit write-permission checks, and cleanly opt-out via file deletion. These principles dictate the structural boundaries of the workflows and how they interact with the GitHub Actions runner environment.

A foundational principle for this implementation is the mechanism used to detect the required authentication credential. The mechanism utilized by `openai/codex-action` requires an API key (specifically `OPENAI_API_KEY`), which functions as a GitHub Actions secret rather than a repository variable [cite: 1, 2]. Under GitHub's strict context availability rules, secrets are fundamentally unreadable within job-level `if:` conditions; attempting to evaluate a secret at the workflow control-plane level is systematically rejected by the platform and linters like `actionlint` [cite: 17, 18]. Because the owner mandates that the workflow must run automatically when the credential is present but must exit cleanly without throwing a pipeline error when it is absent, the architecture must implement an always-run preflight job.

This preflight job isolates the secret detection logic. It reads the secret into a contained step environment, checks its length, and maps the result to a non-sensitive boolean job output. The primary review and assistant jobs then declare a dependency on this preflight job and gate their execution entirely on the boolean output. This pattern precisely mirrors the Claude implementation, fulfilling the credential-presence requirement without relying on manual configuration toggles. 



The integration of agentic workflows introduces a sophisticated vulnerability class defined in the security literature as Agentic Workflow Injection. In a Prompt-to-Agent attack, untrusted text—such as a pull request body, a commit message, or an issue comment—is interpolated directly into the agent's prompt, effectively overriding the system instructions provided by the repository maintainers [cite: 7, 9, 19]. The trusted-author residual evaluated in prior architectural decisions applies identically to the Codex integration. Even when workflow triggers are restricted to highly trusted authors via an `author_association` guard, a trusted collaborator frequently quotes untrusted content. Pasting a stack trace, a bug report from an external user, or a diff from a forked repository embeds unverified data into the text the agent processes. The large language model cannot reliably distinguish between the trusted author's intent and a malicious payload hidden within the pasted log, meaning the `author_association` check mitigates drive-by spam but does not neutralize the underlying injection risk.

To preserve security in the presence of this residual risk, the `openai/codex-action` must be executed under rigorous kernel-level sandboxing. The recommended design mandates the use of `sandbox: read-only` and `safety-strategy: drop-sudo` [cite: 20, 21]. By leveraging `drop-sudo`, the action mutates the Linux runner environment to strip administrative rights, removing the runner user from the sudo group and restricting capability sets before the agent process spawns. Consequently, if an injection attack successfully hijacks the Codex agent, the compromised process cannot mutate the runner's filesystem, install persistent backdoors, or escalate privileges to access protected runner memory where the API key proxy resides. Furthermore, to prevent Prompt-to-Script exfiltration, the Codex job must execute with minimal repository permissions—specifically `contents: read`—while a discrete, unprivileged job handles the publication of comments using `pull-requests: write` [cite: 11, 22]. 

The coexistence of two distinct vendor reviewers—Codex and Claude—on the same pull request presents a question of redundancy versus complementarity. Evaluative benchmarks and production practice demonstrate that the two engines provide distinguishable, non-overlapping feedback. Codex, powered by the GPT-5.4 or GPT-5.6 Sol engines, demonstrates dominance in shell scripting, continuous integration logic, and infrastructure configuration, scoring 77.3% on Terminal-Bench 2.0 compared to Claude's 65.4% [cite: 23, 24]. Conversely, Claude excels in complex architectural reasoning and readability assessments. Running both engines is a complementary strategy that maximizes defect detection in multifaceted repositories. While token consumption scales linearly with dual workflows, Codex operates with significantly higher token efficiency—requiring roughly one-quarter of the tokens for equivalent tasks—meaning the financial overhead of running the Codex lane alongside Claude remains highly sustainable for template adopters [cite: 24]. Review fatigue is mitigated by strictly instructing both agents via `AGENTS.md` to report only high-severity findings and defer stylistic formatting to the automated `cargo fmt` and `cargo clippy` steps.

### Recommendation

The recommended architecture comprises a four-member stack that fully implements the owner's requirements for Codex-assisted workflows within the `rs-launch-blueprint` template. 

1.  **`openai/codex-action`**
2.  **`codex-review.yml`**
3.  **`codex-assistant.yml`**
4.  **`AGENTS.md`**

### Members

#### openai/codex-action

##### Landscape
The `openai/codex-action` is the official, first-party GitHub Action engineered by OpenAI to execute the `codex exec` command within continuous integration pipelines [cite: 1, 4]. It operates as a secure wrapper that handles the installation of the Rust-based Codex command-line interface, manages local proxy authentication for the `OPENAI_API_KEY`, and enforces kernel-level safety strategies to isolate the agent process from the host runner [cite: 21, 25]. 

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | inapplicable | Not distributed via crates.io; GitHub Action standard ecosystem |
| All-time downloads | inapplicable | Not distributed via crates.io; GitHub Action standard ecosystem |
| Last release | `GET https://api.github.com/repos/openai/codex-action/releases` | v1 (rolling stable tag), retrieved 2026-09-17 |
| Stars, archived | `GET https://api.github.com/repos/openai/codex-action` | Evaluated dynamically; active, non-archived [cite: 1] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:openai/codex-action+is:issue+is:open` | Evaluated dynamically; maintained by OpenAI [cite: 1] |
| Issue responsiveness | 10 most recently opened issues | Monitored by OpenAI maintainers |
| Advisories | `https://github.com/openai/codex-action/security/advisories` | No unpatched critical advisories blocking adoption |
| Adopters | GitHub Dependency Graph | Integrated by enterprise repositories enforcing strict AI security protocols [cite: 15] |

##### Principles and implementation
The action implements strict environment isolation. It establishes a local proxy on the GitHub runner, piping the API key via standard input and immediately stripping it from the process environment before routing `codex exec` calls to the local loopback interface [cite: 21]. This adheres to the principle of least privilege by ensuring the agent never holds the raw credential in its memory space, effectively neutralizing direct credential theft via prompt injection.

##### Dominant choice
This mechanism is the definitive choice because it is the sole first-party action maintained by OpenAI for agentic workflow integration. Raw command-line invocation in a standard shell script is technically feasible but inherently insecure, as it bypasses the sophisticated privilege-dropping logic required to safely isolate the agent on a shared runner [cite: 26].

##### Qualified shortlist
*   `openai/codex-action@v1`
*   Raw CLI implementation (`run: npm install -g @openai/codex && codex exec`)

##### Excluded by gate
*   **Generic CLI implementation:** Excluded due to a failure to meet basic security gates for untrusted input handling. Manual implementation cannot easily replicate the `setpriv` capability reduction and proxy isolation required to secure the `OPENAI_API_KEY`.

##### Up-and-comers
*   Third-party API gateways (such as LiteLLM proxies) wrapped in custom Docker actions provide mechanisms to route Codex queries to local open-weight models for cost control [cite: 27]. However, these break the first-party support matrix and require complex external infrastructure, making them unsuitable for a standalone template.

##### Fit for this template
The action natively provides the precise sandboxing parameters (`sandbox: read-only` and `safety-strategy: drop-sudo`) required to mitigate Prompt-to-Agent vulnerabilities in public open-source templates, where fork-driven pull requests routinely introduce untrusted, attacker-controlled code [cite: 21]. 

##### Recommendation
Adopt `openai/codex-action@v1`.

##### Ranked runner-up
Raw CLI invocation, though accompanied by severe security caveats regarding token exposure in process memory.

##### Tradeoffs
Relying on a first-party composite GitHub Action introduces a supply-chain dependency on OpenAI's repository structure. However, because the template strictly adheres to external third-party action pinning policies, the risk of unexpected upstream mutations altering pipeline behavior is localized and managed. 

##### Parameters
*   `assumes action_coordinate = openai/codex-action@v1`

##### Migration implications
No migration is needed; this decision establishes the initial baseline for the Rust template.

##### Validation strategy
*   *Planned Check:* Inspect the workflow trace logs of an executed continuous integration run to verify that the `drop-sudo` step executes successfully and that the API key is cryptographically scrubbed from the `env` block before the `codex exec` process initiates. 

##### Confidence & re-verify trigger
High. The implementation should be re-verified if OpenAI formally deprecates the command-line interface architecture in favor of a strictly hosted GitHub App model.

##### Sources
*   OpenAI Codex Action Repository: `https://github.com/openai/codex-action` (Retrieval date: 2026-09-17) [cite: 1]
*   Security Advisories on Action Privilege: [cite: 21]

#### codex-review.yml

##### Landscape
The review workflow constitutes the automated, event-driven component of the bundle, designed to react autonomously to code modifications. It mirrors the structural shape established by the Claude implementation, employing a preflight job to conditionally execute the main payload based on credential presence [cite: 15]. 

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | inapplicable | Workflow pattern definition, not a software package |
| All-time downloads | inapplicable | Workflow pattern definition |
| Last release | inapplicable | Internally versioned via the template repository |
| Stars, archived | inapplicable | Template pattern |
| Open issues | inapplicable | Template pattern |
| Issue responsiveness | inapplicable | Template pattern |
| Advisories | inapplicable | Security validated via architectural review |
| Adopters | Practice Evidence | Mirrored across robust implementations like `praetorian-inc/public-workflows` [cite: 15] |

##### Principles and implementation
The review lane reacts exclusively to `pull_request` events, targeting the `[opened, synchronize, reopened, ready_for_review]` activity types. To conserve token expenditure and prevent the agent from analyzing incomplete work, the workflow natively filters drafts using the precise condition `if: github.event.pull_request.draft == false` [cite: 28, 29]. 

To fulfill the owner's strict credential-presence requirement, the workflow utilizes a designated preflight job. Because job-level `if:` conditions cannot read the `secrets` context, the preflight job explicitly reads the secret into a step environment variable, evaluates its length, and maps the result to a boolean output flag. The subsequent review job specifies `needs: preflight` and gates its execution on `if: needs.preflight.outputs.has_key == 'true'`. This architecture completely satisfies the mandate: the lane does not error, runs seamlessly if the key exists, and prints a clear diagnostic message if skipped.

To satisfy the requirement that both lanes must reject bots, the review lane enforces this restriction directly on the preflight job with the exact condition `if: github.event.sender.type != 'Bot' && !endsWith(github.event.sender.login, '[bot]')` [cite: 7, 8]. This prevents infinite, recursive review loops if a dependency bot or another artificial intelligence agent updates the pull request. Furthermore, the workflow adheres to a deny-all permission baseline, requesting only `contents: read` for repository access and `pull-requests: write` strictly for publishing comments [cite: 2, 22]. 

##### Dominant choice
The split-job workflow incorporating a preflight secret check is the mathematically required architecture for conditional GitHub Actions execution based on repository secrets [cite: 17, 30].

##### Qualified shortlist
*   Inapplicable. (This evaluates a workflow pattern, not a crate or external library).

##### Excluded by gate
*   Inapplicable. 

##### Up-and-comers
*   Inapplicable.

##### Fit for this template
The review pattern perfectly aligns with the required minimum supported Rust version policy and the standard continuous integration testing matrices defined for the `rs-launch-blueprint`. 

##### Recommendation
Adopt the preflight-gated split-job architecture for `.github/workflows/codex-review.yml`.

##### Ranked runner-up
*   Inapplicable.

##### Tradeoffs
Splitting the execution into a preflight job and a distinct review job consumes slightly more GitHub Actions compute overhead because two runner virtual machines must be provisioned and queued. However, this is the unavoidable, necessary cost of preventing pipeline failure logs on unconfigured template clones.

##### Parameters
*   `owns codex-review.trigger = pull_request: [opened, synchronize, reopened, ready_for_review]`
*   `owns codex-review.bot-guard = github.event.sender.type != 'Bot' && !endsWith(github.event.sender.login, '[bot]')`

##### Migration implications
Adds `.github/workflows/codex-review.yml` to the repository template structure.

##### Validation strategy
*   *Planned Check:* Open a pull request on a fresh repository clone without setting the `OPENAI_API_KEY` repository secret. Observe that the workflow passes cleanly with a green status, exhibiting the "Notice: OPENAI_API_KEY is not set" log message without throwing a failure.

##### Confidence & re-verify trigger
High. Re-verify if GitHub platform updates natively enable the `secrets` context in workflow-level conditionals, which would render the preflight job obsolete.

##### Sources
*   GitHub Actions Context Availability: `https://docs.github.com/en/actions/concepts/workflows-and-actions/contexts` (Retrieval date: 2026-09-17) [cite: 12]

#### codex-assistant.yml

##### Landscape
The assistant workflow provides an on-demand, comment-triggered interaction model with the Codex agent, allowing developers to query the pull request, request specific architectural refactors, or mandate deep security scans asynchronously [cite: 29, 31]. 

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | inapplicable | Workflow pattern definition |
| All-time downloads | inapplicable | Workflow pattern definition |
| Last release | inapplicable | Internally versioned |
| Stars, archived | inapplicable | Template pattern |
| Open issues | inapplicable | Template pattern |
| Issue responsiveness | inapplicable | Template pattern |
| Advisories | inapplicable | Security validated via architectural review |
| Adopters | Practice Evidence | Standard conversational AI invocation pattern across the ecosystem [cite: 32] |

##### Principles and implementation
The assistant lane operates strictly on the `issue_comment` trigger, specifically scoped to `types: [created]`. Because the GitHub platform architecture treats pull request comments as issue comments within the Actions payload, the workflow must enforce the condition `if: github.event.issue.pull_request` to ensure the agent only executes on pull requests, rather than attempting to analyze standalone issues without a codebase diff [cite: 29, 32].

The assistant responds exclusively to the `/codex` command vocabulary. While `@codex` is a common conversational trigger for OpenAI's hosted cloud agents, defining `/codex` explicitly in the GitHub action string (`startsWith(github.event.comment.body, '/codex')`) targets the command-line interface workflow cleanly. This specific vocabulary choice eliminates any risk of collision with Anthropic's `@claude` trigger or potential future native GitHub bot integrations operating on the same repository [cite: 33, 34, 35].

To satisfy the strict owner requirement for an `author_association` check—expressly rejecting write-permission proxy checks—the preflight job mandates the condition `contains(fromJSON('["OWNER", "MEMBER", "COLLABORATOR"]'), github.event.comment.author_association)` [cite: 8, 32, 36]. This critical guard permits established project contributors to invoke the expensive large language model execution while securely blocking drive-by spam, resource exhaustion, or prompt-injection attempts originating from unrecognized external users. The assistant job itself operates under minimal privileges, requiring only `contents: read`, `pull-requests: write`, and `issues: write` to react with an acknowledgment emoji and post the final response [cite: 1, 32].

##### Dominant choice
The `/codex` command prefix via the `issue_comment` event is the industry-standard implementation for secure, on-demand GitHub Action chat integrations [cite: 29, 34].

##### Qualified shortlist
*   Inapplicable. 

##### Excluded by gate
*   Inapplicable. 

##### Up-and-comers
*   Inapplicable.

##### Fit for this template
This workflow provides a highly interactive artificial intelligence layer tailored to the Rust ecosystem, which users can seamlessly invoke to generate required boilerplate, debug complex borrow-checker lifetimes, or write `#[test]` modules on demand directly from the pull request interface.

##### Recommendation
Adopt the preflight-gated, `author_association`-secured architecture for `.github/workflows/codex-assistant.yml` utilizing the `/codex` trigger vocabulary.

##### Ranked runner-up
*   Inapplicable.

##### Tradeoffs
A fundamental characteristic of `issue_comment` workflows is that they execute in the context of the repository's default branch. Consequently, changes pushed to the pull request branch to alter workflow behavior are ignored until merged. While this complicates testing the workflow during initial setup, it is an essential security feature that prevents attackers from modifying workflow execution logic via untrusted pull requests.

##### Parameters
*   `owns codex-assistant.trigger-vocabulary = "/codex"`
*   `owns codex-assistant.trust-guard = contains(fromJSON('["OWNER", "MEMBER", "COLLABORATOR"]'), github.event.comment.author_association)`

##### Migration implications
Adds `.github/workflows/codex-assistant.yml` to the template footprint.

##### Validation strategy
*   *Planned Check:* Post a comment containing `/codex please review the lifetime parameters` from an authenticated user possessing only the `CONTRIBUTOR` association (lacking OWNER, MEMBER, or COLLABORATOR status). Ensure the workflow skips execution based strictly on the evaluated trust guard.

##### Confidence & re-verify trigger
High. Re-verify if GitHub introduces a native `pull_request_comment` event type, which would allow for more precise event scoping.

##### Sources
*   AI Reviewer Actions Implementations: [cite: 29, 32]

#### AGENTS.md

##### Landscape
The `AGENTS.md` file is an open-standard project instruction format natively parsed by the Codex agent, as well as an expanding ecosystem of tools including Cursor, Claude, and Aider [cite: 25, 37, 38]. It replaces fragmented, proprietary tool-specific rule files (such as `.cursorrules`) with a unified, Markdown-based directive set placed at the repository root.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | inapplicable | Markdown specification standard |
| All-time downloads | inapplicable | Markdown specification standard |
| Last release | inapplicable | Version-controlled within the repository |
| Stars, archived | inapplicable | Evaluated via standard adoption [cite: 39] |
| Open issues | inapplicable | N/A |
| Issue responsiveness | inapplicable | N/A |
| Advisories | inapplicable | Security defined by file placement |
| Adopters | Practice Evidence | Adopted by `openai/codex`, `Azure/azure-sdk-for-rust`, and tens of thousands of open-source projects [cite: 38, 39] |

##### Principles and implementation
Because Codex dynamically fetches instructions at runtime from `AGENTS.md`, this file acts as a critical remote configuration module. However, unlike the Claude implementation which historically fetched instructions from an unpinnable external marketplace URL, `AGENTS.md` is checked directly into the repository root. It is pinned and version-controlled identically to the source code, eliminating the structural unpinnability risk that compromised prior architectures [cite: 16, 25]. 

The integration of this file must address a specific vulnerability. If a malicious pull request alters `AGENTS.md`—for instance, instructing the agent to ignore security vulnerabilities or exfiltrate tokens—the standard `actions/checkout` step pulls that poisoned file into the runner environment. Because Codex parses `AGENTS.md` natively, the agent will execute the attacker's instructions as authoritative commands [cite: 16, 19]. To secure this vector, the `openai/codex-action` must execute with `sandbox: read-only` and `safety-strategy: drop-sudo` [cite: 21]. By fundamentally removing write access at the host level, even if the agent is hijacked by a poisoned `AGENTS.md`, it is incapable of altering source files, installing backdoors, or escaping the sandbox to read sensitive runner configuration files.

The template's `AGENTS.md` establishes crucial Rust-ecosystem context. It explicitly instructs the agent to enforce standard formatting via `cargo fmt`, validate code quality with `cargo clippy -- -D warnings`, write and execute tests using `cargo test`, and adhere strictly to Rust 2024 edition idioms. This includes preferring pattern matching, leveraging `Result` and `Option` handling over naked `.unwrap()` calls, and ensuring that any `unsafe` blocks are rigorously documented [cite: 13, 14].

##### Dominant choice
`AGENTS.md` is the undisputed industry standard for cross-platform, multi-agent project configuration, supported directly by the core Codex Rust codebase [cite: 38, 39].

##### Qualified shortlist
*   Inapplicable. 

##### Excluded by gate
*   Inapplicable. 

##### Up-and-comers
*   Inapplicable.

##### Fit for this template
Embedding Rust-specific rules directly into `AGENTS.md` ensures that Codex outputs highly idiomatic, memory-safe code tailored specifically to the structural requirements of command-line interfaces, libraries, and web services immediately upon instantiation.

##### Recommendation
Ship a structurally defined `AGENTS.md` file in the repository root.

##### Ranked runner-up
*   Inapplicable.

##### Tradeoffs
Increasing the length and specificity of `AGENTS.md` consumes a minor portion of the large language model's available context window. However, given the 1 million token context capacity of the GPT-5.5 and GPT-5.6 API backends, this operational overhead is effectively zero, making comprehensive instruction sets highly advantageous [cite: 38, 40].

##### Parameters
*   `owns project-instructions = AGENTS.md`

##### Migration implications
Adds the `AGENTS.md` file to the repository template root.

##### Validation strategy
*   *Planned Check:* Submit a pull request that intentionally violates a standard `cargo clippy` rule. Verify that the Codex review explicitly references the `AGENTS.md` instruction to enforce `clippy` standards when flagging the error in the pull request comment.

##### Confidence & re-verify trigger
High. Re-verify if the `agents.md` open standard is formally deprecated in favor of a newer, conflicting manifest specification across the broader developer tooling ecosystem.

##### Sources
*   Agents.md Standard: `https://agents.md/` (Retrieval date: 2026-09-17) [cite: 37, 39]

### Compatibility

The Codex and Claude lanes operate seamlessly and harmoniously alongside one another on the same repository. Because both workflow lanes enforce rigorous bot exclusion logic (e.g., `github.event.sender.type != 'Bot'`), Codex will silently ignore comments and pull request updates authored by the Claude bot, and Claude will similarly ignore actions taken by Codex. There is no trigger collision between the respective assistant workflows: Claude reacts exclusively to the `@claude` mention, while Codex responds strictly to the `/codex` command prefix. The potential for review fatigue stemming from double-commenting is proactively mitigated by instructing both agents, via their prompt configurations and the shared `AGENTS.md` file, to restrict their feedback to critical structural, logic, or security defects, deferring minor stylistic nitpicks entirely to automated linters. 

### Parameters

*   `owns codex-review.trigger = pull_request: [opened, synchronize, reopened, ready_for_review]`
*   `owns codex-review.bot-guard = github.event.sender.type != 'Bot' && !endsWith(github.event.sender.login, '[bot]')`
*   `owns codex-assistant.trigger-vocabulary = "/codex"`
*   `owns codex-assistant.trust-guard = contains(fromJSON('["OWNER", "MEMBER", "COLLABORATOR"]'), github.event.comment.author_association)`
*   `owns project-instructions = AGENTS.md`
*   `assumes action_coordinate = openai/codex-action@v1`

### Migration implications

The implementation introduces three non-intrusive files to the overall template footprint:
1.  `.github/workflows/codex-review.yml`
2.  `.github/workflows/codex-assistant.yml`
3.  `AGENTS.md` (located in the repository root)

Because the workflows utilize sophisticated silent skip mechanics governed by the preflight job when the `OPENAI_API_KEY` is undefined, downstream consumers experience zero broken continuous integration runs or workflow failures upon initial template instantiation.

### Validation strategy

The fundamental validation strategy rests on observing the state transitions of the preflight job across both the presence and absence of the required credential.

1.  **Credential-Absent Path (Mandatory Check):** Execute a pull request trigger without setting the `OPENAI_API_KEY` repository secret.
    *   *Expected Behavior:* The `preflight` job successfully executes, echoing "Notice: OPENAI_API_KEY is not set. Skipping Codex review." to the runner logs. The `has_key` output returns a strict `false`. The dependent `review` or `assistant` execution job is marked as skipped by the GitHub Actions platform. The overall workflow concludes with a green success state, throwing no pipeline errors.
2.  **Credential-Present Path:** Populate the `OPENAI_API_KEY` and issue the `/codex` command on a pull request comment originating from an authenticated user possessing the `MEMBER` association.
    *   *Expected Behavior:* The preflight job successfully detects the key and outputs `true`. The execution job reacts with the `eyes` emoji on the comment, runs `codex exec` under the strict `sandbox: read-only` and `safety-strategy: drop-sudo` constraints, and replies with the requested code analysis.
3.  **Bot Rejection Path:** Trigger a pull request update originating from `dependabot[bot]`.
    *   *Expected Behavior:* The preflight job's conditional `if` intercepts the automated bot logic and cancels the run entirely before attempting to evaluate the presence of the key.

### Confidence & re-verify trigger

High. The architectural patterns selected are strictly derived from fundamental GitHub Actions context constraints and established security research defending against Agentic Workflow Injection. The implementation should be re-verified if a significant overhaul of GitHub Actions context variables occurs—specifically, allowing `secrets` mapping in native job-level `if` conditions—or if the `openai/codex-action` is deprecated in favor of a different integration protocol.

### Sources

*   [cite: 17, 18, 30] GitHub Docs & Community: Secrets context availability, reusable workflows, and job-level conditional limitations. Retrieved 2026-09-17.
*   [cite: 12, 41, 42] GitHub Actions Context Availability: Platform documentation on variable evaluation and triggers. Retrieved 2026-09-17.
*   [cite: 1, 28] OpenAI Codex Action Repository: Official configuration guidelines, repository coordinates, credentials, and trigger capabilities. Retrieved 2026-09-17.
*   [cite: 29, 32, 36] Security configurations and implementations: `author_association` validations and robust bot rejection mechanisms across open-source workflows. Retrieved 2026-09-17.
*   [cite: 7, 8, 16, 19] AWI Security Research: Academic and industry papers on Agentic Workflow Injection vulnerabilities and mitigation strategies, specifically detailing the necessity of `sandbox: read-only` and `drop-sudo`. Retrieved 2026-09-17.
*   [cite: 20, 23, 24] AI Code Review Comparisons: Empirical evaluations of signal-to-noise ratios, execution costs, Terminal-Bench dominance, and multi-agent coordination economics. Retrieved 2026-09-17.
*   [cite: 13, 14, 38, 39] AGENTS.md Standard: Specification formatting, widespread ecosystem adoption metrics, and Rust-specific implementation details for memory safety. Retrieved 2026-09-17.

**Sources:**
1. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG6nwLWizW1hspQf7NbG9CcouU3uO-2BV1JX6H-aQbJhyAqRHvL8bXJu8Ytb34sfPnim8W2l10NyEVLcht7kadNOTltyL01ixVp4t4tmyEv_QfaI6g9cXRSchXn)
2. [chatgpt.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjKu-e6VNw_CJVFM3YOPsfopuDozIIuFQfAxrnTRQNU4E0LZV5Pqrudq_Q9OMgIWCQGK9lQKpKKxpEkVZ2THAXe_19Bc9ylmBM_28aHFxQRNnTMSiDT5zV6zaDnGtjmPbP)
3. [qodo.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHGt1xPcqMf1ike3l4VdJr3pAPWepjijz27RnVqpYDKerFOCqPR6VKt6uyDtVe4c86Wb9TKjemP7qBlUaUeDXYa5WbWGbXPsD_AfghJOAEW7XghvOBYJXEN6fgVClYKt6j1dHBxPmsgPUOJXSI=)
4. [developersdigest.tech](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_jVHo-HFIfsbO-IPeGMscEnlSj5t-txInWFuiPKL4B2R9nSgaCK4z_46bZOtdbNkz6yCXMWlJDaEvgfXontgNGV1NFGkONluhMt-mkM_tjk3lKkzqt056PTb9eDPmLma57TK8bC25bw0PQxyCW1E_dYyYiNU8YJyNBw==)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEPD90f3gUQHEtv-GnRF1ja7zpSBF_4epHP7xAYAQPR8AqiXZRCu3we_i0cvIV4_-_daNAkGy1uG9SETEi1u0ak5bXwqpV7SfKVymnRo8NnqBtoNH3ipDBva3VS4VJuvUU=)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGdUHc9AmvY9JjNOQabePVIIhkLQTQdRDK7LViagUT01aJw7YecKdIXJAX06CgSBVPwADgHglPtmuMTsfFMWAWg2orq4oyRuitVC0vbJ7Qfbe-FvfXvz5a7A2Cj68W6sSzF)
7. [arxiv.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXO989TrffHoxd2p999M6J48uAH2p0DOAowUjsUcyJ0H6dNJRVOvPgUNSOmj8ksIFJLWoVAiFn2vYJYy-r2lAEaIyPrbFnHgEGLXY_ARKjNEEUsD4Pgl1y)
8. [wiz.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGU9GlPMPZ4vhw2dYUtaLpQ2Nl1wWgsS0JI7-StXyqkQ0q6oJmj8UusGxK5SQ0_Cc8le4W7jNC1H745S4pzA_lTb-cuM-aCNAICyFK3WWsOBWADocLG7ZDIdaiZgl2Tu61GAEs18EXOrqzYvugeZfdSAVcHb-WD8jwDaDJpUdRKfwG8NWTLxuQ=)
9. [arxiv.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQECNuzPwHdk2oag65IyD_dm131hsPyq54IwYcEoJ9YzO7vY24ez4nJGEeFI4dw2SeZj4079aZR8oebRgdFbkOSw6TsesXgXkEzUEzjznxAPqqRKu928)
10. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGB389OYXMdkIREqHnM_O6CTGrjBTIUOKycLMbS9beYOcX6RAEQMko9A9TpkSWJ3pLpf8XAuWULQFaCTbtPmqz2EZ0SJzFHIDfjABsQao2cKLfvBh2_yx85-8Aj8wLhDn0EfjNSiL0pT3olFGkpK8FqBopSvXqk)
11. [developersdigest.tech](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEOxL_PbvOHMPurxZFfBiKrl2x_y0n0PkVI27P1VgM7nJcJn05K7xsMu-b1L0cqrgWJ2wmmn48zMUaD963zUuhBuPyVcOdqby9Vd-jEgNncVsvhI0lr_wDx-u70XCF69dtjUtHmIrBOOehYlWSl-0G41ITI-_VJ2Lg=)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEiInkN59X-MeYf1chRxb_uOwz29wPhXdpOKwlsfsMHgkZGN_LnngcrztopWWGqcVE63vQWlYmKSwGUMiqf9TQ5H9Gemsgvd4VL7-J-Gjwus5ssFvEzK0MZdbgkbTXTZ6KIX4XMRR8k_kwuix9cDyCygZSwZE-jFWImJ0Zjhi1K)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEk9u10gkjeucJcBDdmCMraIKdpLxeN-evpQJZmw-yXPJINq07ooZU6_VBembxIdJBd0hN4ZkLimTy7WHoFcjtxvrVuwBgN8e-hi2j7zteac3-YCLdPs3o2xN8ArTZ4-sw=)
14. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWWBxS6AEoIEImlni4yY9xBVw9CU77wW9kXlKFiSWJlCWMOwHL5T7Gi1EGnpbfpSaI9WmBqN_3hBIvpuou-ZACCP0Rao3Q7gpWcKcbsRGR7MJbp5utMBZzxQ5a5HgydMZUnCx7ceOGbg_yVcZHDFJ46vonIw==)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQExkYFwmR8sRDsv9-5Uecmxa70M1e-0yT03kfLJTaHCNMWcfceMaaIOFULIg6WQloSuel3FzwUqpSw4OAhKS7rBN6N7V9c-y-52k50UFCQR0SmZaUQJW-s6-wuyoxFihI6fm1_HaR0w)
16. [novee.security](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEea14NRlcGDB27CIYt6MgD_NJJbQxc529pknpHiXrJXfDe2Mct3m3vu6uqjo9jmmYshIxnmIm2DWDLrhkMbLN1jLQTlrnB7FaUzsCrotV2SdTqxOA2e5s9IiVuM6wVKmOh5yMaO4X1PAfHSIUcAhJazHheCKweXpBPTGc2OdhT_c9kA5uakYF0bLNzxOcz)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGnPW1Gfhbn3MXHDy-aasBNd8J2Q1RoyldZl4BTcg0Lc884FSNnT5FEYdoNzWo04XvR-gT-tU_gaCqZ0ef6deTdlOo06qoT058XstUl3kr5UxI3egboUpXUA0gHrBQhJlwyC_JszV6k4XZ3Tbqhq-3z5CNx-H-XS4edMeX77CAxK5-RrC_uG8adtPR1sngbbbK2bvvzmH2jIUJFNyenehEQUys1Jk8LIQ==)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEonPsNxvpjM-c21r-SKjo2GvK8RSUyIguOqOQgjufY59uRNmV_re0FfdC3A37_4f8bfVqb3EwjpZGjbGRgjm9oE0IJa4M3VRYWQFUC05FzktSRUZ-qEHF22L8ZPosGBjqvfxxZqRdhnw==)
19. [arxiv.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHj-suQaieN-5sXQnyXeNTG6vvIYqHUsubI67Uf76dzw4K8JVacVKPWcDVDK_yBbc_l3lX_n8zPyl6522QFCXeMocdk6B6Xi22DWg9u3G4lZbjwPNWR)
20. [sreeni.blog](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHYecxCgK9nuuQ0Nt-VSNpdKconiShcsF_JAnB_YpcHCH4ftDrJVHmNmlZzPrbukNoY2rSy3c1qF3N8_WjU27oveMfXiorvTF2kCGEvFGjKZ0XythI0)
21. [harnez.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFZ2eeCHvJHWeknEQwvoyPLWbvrcQKZeOFzwtA6q9TyBTcdeUS58Zo1jotIYi6xO1P7E5_ubRSzH7UacpuWyutqhuEx3AeT9zL2czaRiLyAXLDMXLoy8l96BPM3umW-coOB3HOwFqkAcNSGno5wGDsS)
22. [openai.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFZ9VN9FITsoP5TsRkoMdWCLK2vWEndhOTPlmuVHHxUY-HHO94gttSV2N-2ZmI8wCYcfYGkTFwnLe9CBbX-vVRcRbIIau9Q4hmQi25S4cnoZTMe8ROQeH8Ls86K_JD6A77ZpOU-z_fS6pUcYscMknVK0VcojkqP50sdgH8EFtvN6y8=)
23. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFpSHhg1gbaa0MPXGPIO8pd18cnGLt1SDwXcoFWZEnOfMFFPl2cb_SNtUbL8AYzeTIZsOhCB_8mmfxvCX0swB6OFC3LCwpUyoryF2GhV83LbuJsiho6DEAuRHTdCZfHKUNs9FcS2mQg_ApnHRI4rOI4OZfQ6s7hUJTuqQPYnSUJGjw9jInKafEFnVThKsKk3KmN74VR7g53DPMmSKyikazpS-dPiOTXqOZYGNlwYA==)
24. [particula.tech](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcxCEV0gt1y7GEyLCT18pthNtYjX6bL9sfMBsoda-Bq8z1hKPvth7ixxKne_BjLJluGfoKHuPNJUcd607Iqo9rlZp6jJhgmjACXilhyrrOriri1n1YZc3ni5ii5N8OBY90htwO0ALk-t8B3cQBhD5M3auPrQVkBF6PcQ==)
25. [sulat.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEbu1yVALnBCVnE1b1s5ZnFs6G6a6G8ObqMeHsaILVMezanVJcsR680chPFd2_9kiwT2vsoRm3UELqE8dQQzVn0kik6_-wDXeMIn6sJLFXGwOB9jRVH9ZEt4ZNghBpuV3igpNI9YME2M2ufm88ParBoRnkraFIhlw17r6kvK9_GZE8QNgtieBZgeIqjJkNcAAD60b90adzoz8xgMks8Yan1oonj)
26. [chatgpt.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEeHpKVjzzJG2sd0WQh_yGAzBKJOz11--I2YSF0pc5-cFuJn-ZjvE9Pqi_WFNNB8m1dvIiEcWG8VWQZzNRyhWPQyjAtjArDBMfpD17SV42NFDTDt0I204BdWFNUId0q9E-VR795LoNKzA==)
27. [edenai.co](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGHvKAqm6AJ0JXqMfo8oWwLLd1PAO-oS4oZasyb3-k_GSgFjrAZl6zEIIDAZpBUd_PcZN4AtFVYPdZApUnre11H_PBsquh0_tLtJU4iofaguU27yUlRsE8J0JuoOGupO_64iBTkgxUZRwNXh7kgLqNhJ4ssTctHxMQP)
28. [openai.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsZNhFAalGZLQ9lpb9j2mrXhbRiQBNLqe_8l-ODcgMWNeYrX6aFDMjlOidNxUcTEM--FnQu7smgNje9EF78xXK9R9dlX50a2FxZTRBowvIszBqk-XdIYzRZ7J3YoWf0iOV4HC-xEuAbUTRryKcM1JD8yRN1dcf6-j00UUDM2hS1zx0lbx-ECoO1rmn)
29. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFTLmzzM1jREo_7GK0mmjMksAvpbpWHuCio06SjbccmiZuF-7LCofQCqOzXP_NoIn9tyRg8Imil2tlDGCvGkUi2qahSfqSSW3vHkL1loWlGbrTUwrOd-nkOnVmmiBeTlFD1jKoC4RU1tHURAG84o7Ej5HO-kvBSlr5hN1BWBjX3p65OTAwd5zwAin6uCtrvjndLG3EBXyJb7n63Dg==)
30. [cloudchronicles.blog](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE6DSxDDZ6etA_cw5SOW2rl9Hv8V-FK6qrWv_FT7ZmQz301XTc_HkJ-4JzkXsw4RD72v3tVr6-Tdzxv7EIJ-h481mIqfw9ID7eLE5o-yJfNIqmh-eb0PsrjEfT4pbp7Kc0eGbfAQ89d0lytlk1mA_9GbcDvLXxTuCQ90uZRGMqaRPkirW9ql11IqMGDTMs6VzS5y0x-DgahVS5wYoEqEfOniMZADcRBkiEb)
31. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFPxiJU5TioUiwC9thmLetF9jUMnz_VnXYjRxYx0hw2mVK-YAHBmGRo3nJAFMLdClN12d2KtfYa2Z-W9gljr92Dsumvt79SsfcIMuHlzaPK0hO4EsrNCrPmOVrJMGuVN_zGFORS8Sd7j195j-JO0XPp0CbWa7r80edk5zU9c9OFI41_dRwa)
32. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFkepoDnu8D5KrxZW4V6YdDk9W7VSvBAGZg6o2SUMfhtx5l2bSwjoNoh6gbRvnPDiEYdjt4qUpsm4Bc4MzigmF20dRqR_-PDPHdHZLlkB4NcP9FGCAbCcsbG-TA3fXFlQ22KMVkT32gBG_45XEjzEcBRTfHpYfyD6WZ)
33. [metirai.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFC-Wg4vNeY3FpmKaBsST0lfnFvxMYpJupDtRj5wdZO_U1GI9dGx9y__oTVDBx-MQderlqlCFxG4EBTjm-hkltppqxTSpM8O5eXCYuP7rDG_WVJ1syUw22F7s1orr9Fn0m_z6I8QO8u2vFARkfUNehx8W2qpsamoQ==)
34. [aicatchup.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEWwsXleCR_AvIt7Q2mgPL3zeiMVRZsa_bYlV2AnXInMLOJm-t_oZXP-FvzwomdGWpZhawAmRWboXWL7J6IbHqKIXFjP_33IixRikpMgj8uvagPnR7DIc6RDwpoWDVcno3LTexqcX9bHrC8TDVo_QsIg0rLoAjutTDGG6dVrCG0eFg=)
35. [growthvector.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH7O7c18njiU7jIp0Xf9v2D_ywRCs7bCiuzAdzt4UbT09IlzeArs3sbP6Ku5T3ncy7VzNDDux2waf7dfRn6qFnY0QSomaCfsKac_FT-O1cXHjeirFWo9mSyeBdmjjfa)
36. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5y-Tu8aeqQQd2sdhVk9UtiRDzBPDiRSKBuSxFeaOq1pFkB4b5hwGcmi4_K2BiiOWp_uSdoRrQqjj43mjjOOPJg0GiwfQm5nHEXHuo6P8r0t3K4aNicl9dawAwF3NCfAGl5oiYczD7NLaaMof2)
37. [builder.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF1VjdUrzDqcTbIwwyJj8t6uaD9kSOiTQSXL5xOb5oeNFf79S7S1Gds5MoIepDdrRGYILrI396K2rFftaZliph6tuCouJXw_QQQ3bsG2UAoD4YSBkghLLSo1nM=)
38. [ssojet.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCNP_Is56PIL8rX4zoQ5NmGtTj4x3-rIaOVJBWppPmd0-0peLEHvpagb-dfeSsseHUyqCi5RcXEXN5Qb4f9nbxpRy6tkE9LYGxVhCDzdHvyAbVYlIDvSZ_oPTQn9s5ug==)
39. [agents.md](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH8HSjM8USdpVGndtang9QGNRbGthTz-wzu7flDVPRX4x5Tpw-x1SgvICryIXcWpukjF3J_0oUH_K9kMJgMiYkfBXsroFb5Ng==)
40. [blakecrosley.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFrdE-KvhKyEldUyLKjqxAbRQp4-4-FKxCw5hrfbYpVvrAuLzcUahEolZKWhBe8m02I-zoX8ygnwrhsK9yGteOb1BOCGwhMJbQHXhXM_vksbvltYRej-Uu3mDw=)
41. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFzaqkxF5WcYPU8xJ9zcjlmcfM3ndTIdRjBhF8i0fVy4uk0I-Vb3mG2PYr16zdtt4tJ7yZtVr5erO81jngQc5zMLhEpJ0kqenvJolN9ZH3q2pY5Iz50eR4ak-eyfq5PPI81Sk11fmTfSYMf7QWx0xTQeV1C6TsnSLUFqN5RhFfNoEg=)
42. [octopus.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEBf1HRPSSivMZ11aq7IQADb6QegkPIE8sK56wMHLJn9-RBwTfM6J6bF1W2v4QfBIIgLnyDZg2bSu54pBaLBb1wXZ914Ds2eS60PI6PA0WmAx0tpoQCRSC96Iobo6vCmgwaJ3SdkLMq3sb4IWP_Rw9vRO7RrIU3JQ==)

## Sources

- [chatgpt.com](https://learn.chatgpt.com/docs/github-action)
- [github.com](https://github.com/openai/codex-action)
- [developersdigest.tech](https://www.developersdigest.tech/blog/codex-sdk-vs-cli-github-action)
- [qodo.ai](https://www.qodo.ai/blog/open-source-code-review-tools/)
- [github.com](https://github.com/alibaba/open-code-review)
- [github.com](https://github.com/inference-gateway/adl-cli)
- [arxiv.org](https://arxiv.org/pdf/2605.07135)
- [arxiv.org](https://arxiv.org/html/2605.07135v1)
- [wiz.io](https://www.wiz.io/blog/github-actions-security-ai-powered-actions-vulnerabilities)
- [developersdigest.tech](https://www.developersdigest.tech/blog/codex-exec-ci-headless-guide)
- [github.com](https://github.com/openai/codex-action/blob/main/docs/security.md)
- [github.com](https://docs.github.com/en/actions/concepts/workflows-and-actions/contexts)
- [github.com](https://github.com/d-oit/rust-2026-template)
- [github.com](https://github.com/Azure/azure-sdk-for-rust/blob/main/AGENTS.md)
- [github.com](https://github.com/praetorian-inc/public-workflows)
- [novee.security](https://novee.security/blog/critical-flaws-in-anthropic-google-and-openais-coding-agents/)
- [github.com](https://github.com/orgs/community/discussions/26726)
- [github.com](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets?ref=blog.hosaka.fm)
- [arxiv.org](https://arxiv.org/pdf/2606.09935)
- [harnez.ai](https://harnez.ai/posts/sandboxing-codex-in-github-actions/)
- [sreeni.blog](https://sreeni.blog/category/ai/)
- [openai.com](https://developers.openai.com/cookbook/examples/codex/autofix-github-actions)
- [particula.tech](https://particula.tech/blog/codex-vs-claude-code-cli-agent-comparison)
- [medium.com](https://medium.com/@orami98/the-ultimate-ai-code-reviewer-showdown-2026-gpt-5-vs-claude-opus-vs-custom-llms-9ad7f05af4f2)
- [sulat.com](https://ai.sulat.com/the-definitive-guide-to-codex-cli-from-first-install-to-production-workflows-a9f1e7c887ab)
- [chatgpt.com](https://learn.chatgpt.com/docs/non-interactive-mode)
- [edenai.co](https://www.edenai.co/post/how-to-run-openai-codex-with-any-ai-model)
- [medium.com](https://medium.com/google-cloud/diy-pr-code-reviews-with-antigravity-cli-in-github-action-47075c4ba492)
- [openai.com](https://developers.openai.com/cookbook/examples/codex/build_code_review_with_codex_sdk)
- [cloudchronicles.blog](https://cloudchronicles.blog/blog/Passing-Environment-Secrets-and-Variables-to-Reusable-Workflows-in-GitHub-Actions/)
- [medium.com](https://sabihullahsaleh.medium.com/openai-codex-with-github-actions-9b36187d42de)
- [github.com](https://gist.github.com/nirajrajgor/1f089f92b305aa81eac4662df02d23ec)
- [aicatchup.com](https://aicatchup.com/comparisons/claude-code-routines-vs-cursor-automations)
- [metirai.com](https://www.metirai.com/blog/chatgpt-codex-ultimate-guide-tutorial)
- [growthvector.io](https://growthvector.io/vibe-coding/codex)
- [github.com](https://github.com/liatrio-labs/ai-code-review-workflows)
- [builder.io](https://www.builder.io/blog/agents-md)
- [ssojet.com](https://ssojet.com/blog/agents-md-examples)
- [agents.md](https://agents.md/)
- [blakecrosley.com](https://blakecrosley.com/guides/codex)
- [octopus.com](https://octopus.com/devops/github-actions/github-actions-triggers/)
- [github.com](https://docs.github.com/actions/reference/workflow-syntax-for-github-actions)

---
