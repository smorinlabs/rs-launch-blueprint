---
prompt: # Deep-research prompt — Dev-toolchain provisioning (R42, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint` provisions the non-cargo developer-toolchain — whether it ships per-tool Justfile installer recipes, a declarative provisioner manifest (mise and/or flox) kept in sync with native installs, or relies on rustup/cargo alone — and how Justfile recipes and lefthook jobs then invoke each dev tool (a cargo subcommand vs. a provisioned binary on PATH). Item kind: `bundle`. Value test: if this answer is wrong, the Justfile's installer-recipe set, any `mise.toml`/`.flox/env/manifest.toml` equivalents (or their deliberate absence), and every Justfile recipe/lefthook job invocation line for a non-cargo-native tool all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships per-tool binary installer Justfile recipes for tools outside its primary package manager, plus two declarative toolchain-provisioner manifests (mise, flox) that must be kept in manual sync with the native install path. ts folds the tools those recipes installed into its single formatter and treats the remaining one as advisory-only, so it carries neither installer recipes nor a provisioner manifest. Evidence: py `Justfile:159`, `Justfile:476`, `Justfile:482`, `Justfile:713` — `install-taplo`/`install-gitleaks`/`install-actionlint`/`install-yamlfmt`, the latter two shelling out to `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh`; ts: none (folds taplo/yamlfmt into Oxfmt and treats actionlint as advisory-only inside `check-deps`, `Justfile:83`). Ledger rows: F183, F187, F188, F189 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F187 declarative toolchain-provisioner manifest, mise — py `mise.toml:23` (`[tools]` pins `python`, `uv`, `ruff`, `taplo`, `gitleaks`, `just`, `bun`, `gh`, `lefthook`, `make`, `actionlint`); ts: none. F188 declarative toolchain-provisioner manifest, flox — py `.flox/env/manifest.toml:14` (`[install]` declares the same 11-tool set via `pkg-path` entries); ts: none. F189 three provisioners kept in manual sync — py `mise.toml:1` (header: "one of the project's three first-class dev environments... keep them in sync"); ts: none (provisions only natively via Makefile/Justfile `install-*`, no mise/flox manifests exist).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-014(6) and D-014(7) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts omits a taplo installer because Oxfmt already formats TOML, and omits a yamlfmt installer because Oxfmt already formats YAML; both eliminate the dedicated per-tool installer recipe and script py needed, rather than replacing it with an equivalent.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Against the existing solutions and follow a similar pattern

### Baseline review (2026-09-04)
- F181 (`just check-deps`, `COMMON → REUSE`) is held pending this item: if rustup components plus `cargo install`/`cargo-binstall` remove the per-tool installer layer, F181 collapses into F180, and `package-manager-invocation` decides whether a `command -v` loop is the right presence test. F179 keeps the bootstrap-versus-task layering; Make as the entry mechanism is a choice this item justifies, not an ecosystem necessity. F190/F103's toolchain-file channel is decided by R27 in coordination with this item (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Which specific non-cargo dev tools this template needs beyond rustfmt/clippy (a secret scanner, a YAML linter, a spell checker, actionlint); R27–R29 (lint/format tool choices), R39 (`secret-scanning-hooks`), and R40 (`auxiliary-hygiene-hooks`) each own their own tool pick — this item decides how a chosen tool gets provisioned and invoked, not which tool is chosen.
- The hook manager's own distribution/install mechanism; R37 (`hook-manager-distribution`) owns F143/F144/F174 — lefthook's own install path is a separate provisioning question from the rest of the dev toolchain.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R42
- owns: package-manager-invocation
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R37 (`hook-manager-distribution`) decides how lefthook itself is installed (F143), a distribution question this item does not re-decide.
- related (not a registry dependency): R27, R28, R29, R32, R37, R40 each pick their own dev tool; this item's `package-manager-invocation` parameter tells their Justfile recipes and lefthook jobs how to invoke whatever tool they pick.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s dev-toolchain provisioning uses per-tool Justfile installer recipes (py's pattern) for non-cargo tools, a declarative provisioner manifest (mise and/or flox, kept in sync with native installs), or relies on rustup/cargo alone with no extra provisioning layer — and, whichever answer, whether Justfile recipes and lefthook jobs invoke a dev tool via a `cargo` subcommand or a provisioned binary on PATH.
- HIGH: Does rustup's component model (rustfmt, clippy) plus `cargo install`/`cargo-binstall` cover this template's toolchain needs well enough that no separate per-tool installer-recipe layer (F183) is needed, or does at least one non-cargo-native tool (e.g. a secret scanner, a spell checker) still require one?
- HIGH: Is a declarative provisioner (mise, flox, or both, F187/F188) common practice for Rust projects that also need non-Rust CLI tools, or does the Rust ecosystem's narrower non-cargo tool surface make a provisioner manifest unnecessary overhead compared to py's Python+Node+CLI tool mix?
- MEDIUM: If a provisioner is adopted, should the template keep two kept-in-sync manifests (mise and flox, py's three-provisioner pattern, F189) or converge on one, given Rust narrows the tool set that needs declaring?
- MEDIUM: What is the idiomatic Rust-template answer to `package-manager-invocation` — do Justfile recipes and lefthook jobs invoke rustfmt/clippy and any other tool via `cargo fmt`/`cargo clippy`-style subcommands, or via bare binaries expected on PATH?
- LOW: If per-tool installer recipes are kept for any tool, does each need its own shell script (as py's `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh` do) or can a single generic install-if-missing recipe serve every non-cargo tool?

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
operation_id: research-20260909-001318-a42cc10197234031
created_at: 2026-09-09T00:13:18.535776
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Dev-toolchain provisioning (R42, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint` provisions the non-cargo developer-toolchain — whether it ships per-tool Justfile installer recipes, a declarative provisioner manifest (mise and/or flox) kept in sync with native installs, or relies on rustup/cargo alone — and how Justfile recipes and lefthook jobs then invoke each dev tool (a cargo subcommand vs. a provisioned binary on PATH). Item kind: `bundle`. Value test: if this answer is wrong, the Justfile's installer-recipe set, any `mise.toml`/`.flox/env/manifest.toml` equivalents (or their deliberate absence), and every Justfile recipe/lefthook job invocation line for a non-cargo-native tool all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships per-tool binary installer Justfile recipes for tools outside its primary package manager, plus two declarative toolchain-provisioner manifests (mise, flox) that must be kept in manual sync with the native install path. ts folds the tools those recipes installed into its single formatter and treats the remaining one as advisory-only, so it carries neither installer recipes nor a provisioner manifest. Evidence: py `Justfile:159`, `Justfile:476`, `Justfile:482`, `Justfile:713` — `install-taplo`/`install-gitleaks`/`install-actionlint`/`install-yamlfmt`, the latter two shelling out to `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh`; ts: none (folds taplo/yamlfmt into Oxfmt and treats actionlint as advisory-only inside `check-deps`, `Justfile:83`). Ledger rows: F183, F187, F188, F189 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F187 declarative toolchain-provisioner manifest, mise — py `mise.toml:23` (`[tools]` pins `python`, `uv`, `ruff`, `taplo`, `gitleaks`, `just`, `bun`, `gh`, `lefthook`, `make`, `actionlint`); ts: none. F188 declarative toolchain-provisioner manifest, flox — py `.flox/env/manifest.toml:14` (`[install]` declares the same 11-tool set via `pkg-path` entries); ts: none. F189 three provisioners kept in manual sync — py `mise.toml:1` (header: "one of the project's three first-class dev environments... keep them in sync"); ts: none (provisions only natively via Makefile/Justfile `install-*`, no mise/flox manifests exist).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-014(6) and D-014(7) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts omits a taplo installer because Oxfmt already formats TOML, and omits a yamlfmt installer because Oxfmt already formats YAML; both eliminate the dedicated per-tool installer recipe and script py needed, rather than replacing it with an equivalent.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Against the existing solutions and follow a similar pattern

### Baseline review (2026-09-04)
- F181 (`just check-deps`, `COMMON → REUSE`) is held pending this item: if rustup components plus `cargo install`/`cargo-binstall` remove the per-tool installer layer, F181 collapses into F180, and `package-manager-invocation` decides whether a `command -v` loop is the right presence test. F179 keeps the bootstrap-versus-task layering; Make as the entry mechanism is a choice this item justifies, not an ecosystem necessity. F190/F103's toolchain-file channel is decided by R27 in coordination with this item (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Which specific non-cargo dev tools this template needs beyond rustfmt/clippy (a secret scanner, a YAML linter, a spell checker, actionlint); R27–R29 (lint/format tool choices), R39 (`secret-scanning-hooks`), and R40 (`auxiliary-hygiene-hooks`) each own their own tool pick — this item decides how a chosen tool gets provisioned and invoked, not which tool is chosen.
- The hook manager's own distribution/install mechanism; R37 (`hook-manager-distribution`) owns F143/F144/F174 — lefthook's own install path is a separate provisioning question from the rest of the dev toolchain.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R42
- owns: package-manager-invocation
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R37 (`hook-manager-distribution`) decides how lefthook itself is installed (F143), a distribution question this item does not re-decide.
- related (not a registry dependency): R27, R28, R29, R32, R37, R40 each pick their own dev tool; this item's `package-manager-invocation` parameter tells their Justfile recipes and lefthook jobs how to invoke whatever tool they pick.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s dev-toolchain provisioning uses per-tool Justfile installer recipes (py's pattern) for non-cargo tools, a declarative provisioner manifest (mise and/or flox, kept in sync with native installs), or relies on rustup/cargo alone with no extra provisioning layer — and, whichever answer, whether Justfile recipes and lefthook jobs invoke a dev tool via a `cargo` subcommand or a provisioned binary on PATH.
- HIGH: Does rustup's component model (rustfmt, clippy) plus `cargo install`/`cargo-binstall` cover this template's toolchain needs well enough that no separate per-tool installer-recipe layer (F183) is needed, or does at least one non-cargo-native tool (e.g. a secret scanner, a spell checker) still require one?
- HIGH: Is a declarative provisioner (mise, flox, or both, F187/F188) common practice for Rust projects that also need non-Rust CLI tools, or does the Rust ecosystem's narrower non-cargo tool surface make a provisioner manifest unnecessary overhead compared to py's Python+Node+CLI tool mix?
- MEDIUM: If a provisioner is adopted, should the template keep two kept-in-sync manifests (mise and flox, py's three-provisioner pattern, F189) or converge on one, given Rust narrows the tool set that needs declaring?
- MEDIUM: What is the idiomatic Rust-template answer to `package-manager-invocation` — do Justfile recipes and lefthook jobs invoke rustfmt/clippy and any other tool via `cargo fmt`/`cargo clippy`-style subcommands, or via bare binaries expected on PATH?
- LOW: If per-tool installer recipes are kept for any tool, does each need its own shell script (as py's `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh` do) or can a single generic install-if-missing recipe serve every non-cargo tool?

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
**Evaluating bootstrap mechanism**

I’m considering whether to fix the bootstrap entry mechanism. It looks like we have R42 owning the package manager invocation and F181 pending. I need to align the principles of capability with the exact mechanism. Perhaps I should recommend not requiring a mandatory declarative provisioner, using rustup or cargo-binstall, along with binary-specific upstream mechanisms for non-Rust tools. However, there’s a high-quality demand for at least one non-cargo-native tool to still require an installer.

### Landscape

**Research date:** September 9, 2026. All web citations below link to the source URL and were retrieved on that date. Owner-provided repository paths are identified as local evidence. Where the required JSON endpoint could not be rendered, the figure is marked as an evidence gap rather than replaced with a secondary estimate.

**Category decided:** project-local developer-toolchain provisioning and execution policy for a Rust workspace that contains a CLI, library, and web service.

| Bin | Candidates found | Landscape finding |
|---|---|---|
| **Built-in or first-party toolchain** | `rustup`, `rust-toolchain.toml`, rustup components, Cargo, `cargo install` | This is the authoritative layer for the compiler, Cargo, rustfmt, Clippy, targets, and Rust-specific toolchain selection. Rustup is an official Rust project and the recommended Rust installer. `rust-toolchain.toml` can declare channel, profile, components, and targets. ([rust-lang.github.io](https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain)) |
| **Established industry standard** | System package managers; per-tool installers; Nix/Flox-style environments; `cargo-binstall`; mature multi-runtime managers such as mise | Cargo installation is ubiquitous for Rust binaries, but Cargo's own RFC explicitly says it does not replace system package managers. Flox supplies a manifest and lockfile for a full Nix-backed environment. Mise supplies one project manifest, a lockfile, Cargo/GitHub/Aqua backends, and a non-activating `exec` boundary. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1200-cargo-install.html)) |
| **Up-and-comer** | Aqua as a standalone manager; `cargo-run-bin`; mise's native Cargo binary installer; newer package-attestation mechanisms | Aqua emphasizes checksums, policy, Cosign/SLSA, attestations, and Minisign. Mise's native Cargo binary path is still explicitly experimental in 2026; its documented default changes are scheduled for 2027. ([aquaproj.github.io](https://aquaproj.github.io/)) |

#### Authority used

- **Rustup Book, Cargo Book, Rust RFCs, and release announcements** are normative first-party sources for Rust installation, components, and Cargo behavior. ([rust-lang.github.io](https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain))
- **The 2025 State of Rust Survey** is the latest Rust Project survey. It reports that respondents predominantly develop on stable and keep up with stable releases; it also continues to identify compile time and storage use as material productivity problems. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- **Mise, Flox, Aqua, and cargo-binstall maintainer documentation** is authoritative for each tool's supported backends, lock behavior, activation model, and security controls. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))
- **Repository manifests and workflows** are primary implementation evidence for versions, MSRV declarations, features, runtimes, and platform CI. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
- The independent *Zero to Production in Rust* material corroborates rustup as the expected installation path, but it is supporting evidence rather than the decision authority. ([zero2prod.com](https://www.zero2prod.com/assets/sample_zero2prod.pdf))

#### Practice evidence

The surveyed projects show strong agreement on the **Rust layer**, but not on a universal external-tool provisioner:

- **Zed** pins a minimal Rust toolchain and explicitly requests rustfmt, Clippy, rust-analyzer, and rust-src in `rust-toolchain.toml`. This is a current, maintained Rust product and a direct example of making rustup components declarative. ([github.com](https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml))
- **uv**, a newer high-adoption Rust CLI with roughly 3.5k forks in the retrieved GitHub view, uses edition 2024 and a declared Rust MSRV. Its contributor instructions use `cargo fmt` and `cargo clippy`, while requiring tools such as shellcheck, cargo-shear, and jq separately; its pre-commit configuration mixes Cargo commands and system binaries. ([github.com](https://github.com/astral-sh/uv?ref=malemburg.com))
- **Nextest**, with about 3k stars and hundreds of releases in the retrieved repository view, presents itself as a Cargo subcommand, maintains a Justfile, and recommends a prebuilt-binary action in CI rather than requiring every user to compile it. ([github.com](https://github.com/nextest-rs/nextest))
- **Ruff** also uses edition 2024 and a separate development toolchain above its published MSRV, reinforcing the distinction between a project's supported compiler floor and its development toolchain. ([github.com](https://github.com/astral-sh/ruff/blob/main/BREAKING_CHANGES.md))

**Inference:** a declarative polyglot provisioner is not a universal Rust-community convention. The observed dominant practice is rustup/Cargo plus project-specific handling for external tools. Nevertheless, this template's prospective secret, YAML, spelling, and GitHub-workflow tools mean Cargo coverage cannot be assumed. A single external-tool manifest is therefore justified by this template's fit, not by claiming ecosystem-wide dominance.

### Principles and implementation

#### Shared requirement and agreement level

The shared principle is:

> **Every required development capability must have one authoritative declaration, a reproducible installation path, and one local/CI/hook invocation contract; bootstrap may install tools, but normal tasks and hooks must not.**

Agreement is required at the following levels:

- **Capability:** a fresh Ubuntu or macOS checkout can obtain every required tool.
- **Architectural pattern:** Rust components and external CLIs have disjoint authorities rather than synchronized duplicate manifests.
- **Policy:** versions are exact or locked; normal tasks run the locked versions; installation never happens opportunistically inside a hook.
- **Invocation standard:** Cargo-aware tools use their Cargo interface; standalone tools use their executable interface.

The following may vary without breaking agreement:

- Which secret scanner, spelling tool, YAML tool, or action linter is selected by R27–R40.
- Whether a particular external tool uses mise's `aqua:`, `github:`, or `cargo:` backend.
- Hook stage and tool-specific arguments.
- Whether a developer activates mise interactively or uses only `mise exec`.

#### Significant alternatives

| Architecture | Advantages | Failure or cost for this template |
|---|---|---|
| **Rustup/Cargo only** | Smallest conceptual surface; fully idiomatic for rustfmt, Clippy, and Rust-published binaries. | Cannot provision an arbitrary non-Rust binary. Cargo's own RFC describes `cargo install` as Rust-specific and explicitly says it does not obsolete other package managers. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1200-cargo-install.html)) |
| **One installer recipe/script per tool** | Transparent; no provisioner prerequisite. | Multiplies OS/architecture branches, checksum logic, update locations, and hook/CI drift. It repeats the Python precedent even though mise now has direct Cargo, GitHub, Aqua, and HTTP backends. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo)) |
| **Mise + Flox + native installers kept synchronized** | Maximum contributor choice; Flox can also manage native libraries and whole environments. | Three authorities intentionally reproduce manual synchronization. Flox already has its own manifest and dependency lock, so it is not merely another frontend over the same state. ([flox.dev](https://flox.dev/docs/concepts/environments)) |
| **Flox only** | Strong full-environment and native-library reproducibility; committed manifest and lock. | More environment machinery than this tool-only decision needs. It is attractive if the web service later requires pinned native services or libraries, but that is not R42's current scope. |
| **Aqua only** | Narrow CLI focus and strong supply-chain controls. ([aquaproj.github.io](https://aquaproj.github.io/)) | Less natural coverage for source-only Cargo tools and Rust components. It remains a good backend or runner-up, not the whole stack. |
| **One mise manifest plus rustup** | One external-tool manifest, Cargo/GitHub/Aqua backends, lock/checksum support, and deterministic `exec`; rustup remains authoritative for first-party Rust components. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo)) | Adds one bootstrap prerequisite and requires an explicit guard against a user's global mise configuration shadowing rustup's Cargo. |

#### Recommended composition

1. **`rust-toolchain.toml` owns Rust itself.**
   - R27 owns the final channel.
   - Use `profile = "minimal"` with explicit `rustfmt` and `clippy`.
   - Do not repeat the Rust version in `mise.toml`.

2. **`mise.toml` plus committed `mise.lock` owns all other project development binaries.**
   - Pin mise itself to **2026.9.3** through top-level `min_version` and the bootstrap path.
   - Prefer an `aqua:` or `github:` backend for an official prebuilt release.
   - Fall back to `cargo:` for source-only Rust tools.
   - Set `cargo.binstall = false` so ambient installation of cargo-binstall cannot change installation semantics between contributors.
   - Deliberately omit Flox.

3. **Bootstrap is one generic operation, not one recipe per selected tool.**
   - `make bootstrap` installs/checks rustup and mise, triggers the Rust toolchain, and runs `mise --locked install`.
   - No `install-gitleaks`, `install-actionlint`, `install-taplo`, or equivalent recipes.
   - No tool-specific installer scripts.

4. **Execution is interface-oriented.**
   - `cargo fmt`, not `rustfmt`.
   - `cargo clippy`, not `clippy-driver`.
   - `cargo foo` for a Cargo extension published as `cargo-foo`.
   - Bare executable for a standalone CLI, regardless of whether it was implemented in Rust, Go, or another language.
   - External tools run within `mise --locked exec -- …`.
   - Lefthook calls a Just recipe instead of duplicating tool arguments.

#### Minimal realistic example

The following versions are **integration fixtures**, not R42 selections for nextest or actionlint:

```toml
# rust-toolchain.toml
[toolchain]
channel = "1.98.1" # fixture; R27 owns the final development channel
profile = "minimal"
components = ["rustfmt", "clippy"]
```

Rust 1.98.1 was the current stable patch release on September 9, 2026; under the fixed stable-minus-two policy, the current `rust-version` floor is 1.96. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

```toml
# mise.toml
min_version = "2026.9.3"

[settings]
lockfile = true
cargo.binstall = false

[tools]
# Smoke fixtures only. R27–R40 replace these with their selected tools.
"cargo:cargo-nextest" = "0.9.137"
"aqua:rhysd/actionlint" = "1.7.7"
```

```makefile
# Makefile
.PHONY: bootstrap

bootstrap:
	@./scripts/bootstrap-dev.sh
	@cargo --version
	@mise --locked install
```

```just
# Justfile
mise := "mise --locked exec --"

fmt-check:
    cargo fmt --all -- --check

clippy:
    cargo clippy --workspace --all-targets --all-features --locked -- -D warnings

test-nextest:
    {{ mise }} cargo nextest run --workspace

workflow-lint:
    {{ mise }} actionlint

check-deps:
    @missing="$$(mise ls --missing --no-header)"; \
      test -z "$$missing" || { printf '%s\n' "$$missing"; exit 1; }
    @rustup component list --installed | grep -q '^rustfmt'
    @rustup component list --installed | grep -q '^clippy'
```

```yaml
# lefthook.yml — lefthook installation itself remains owned by R37
pre-commit:
  parallel: true
  commands:
    rust-format:
      run: mise --locked exec -- just fmt-check
    workflow-lint:
      run: mise --locked exec -- just workflow-lint
```

A required acceptance guard must prove that mise has not shadowed rustup's Cargo:

```sh
mise --locked exec -- sh -eu -c \
  'test "$(command -v cargo)" = "$(rustup which cargo)"'
```

If that fails because of inherited global mise configuration, the implementation must isolate project configuration or disable the inherited Rust tool before merge. It must not solve the problem by duplicating the Rust pin in `mise.toml`.

#### Observable acceptance criteria

- A fresh Ubuntu and macOS runner succeeds with `make bootstrap`.
- `mise ls --missing --no-header` is empty afterward. Mise documents this command specifically for finding configured versions that are not installed. ([mise.jdx.dev](https://mise.jdx.dev/cli/ls.html))
- `mise lock` followed by `git diff --exit-code -- mise.lock` is clean.
- `mise --locked install` succeeds without unresolved URLs; locked mode requires pre-resolved lockfile URLs. ([mise.jdx.dev](https://mise.jdx.dev/cli/))
- Removing one installed external tool makes `just check-deps` fail without a `command -v` inventory.
- Normal Just recipes and hooks do not install or update tools.
- No per-tool `install-*` recipes or installer scripts exist.
- No `.flox/env/manifest.toml` exists.
- Rust commands resolve to the rustup-selected toolchain.
- Cargo components/extensions and standalone tools use the prescribed invocation forms.

#### Baseline review

`BASELINE-REVIEW: F183 — one declarative authority per capability — remove per-tool Justfile installers and tool-specific shell installers; retain only one provisioner bootstrap — mise's Cargo/GitHub/Aqua/HTTP backends replace repeated OS-specific installers.`

`BASELINE-REVIEW: F187 — reproducible external CLI set — add one mise.toml plus committed mise.lock — mise supports project declarations, lock resolution, checksums, and locked execution.`

`BASELINE-REVIEW: F188 — minimize parallel environment authorities — deliberately omit Flox — Flox would add a second independent manifest and lock for a tool-only problem already covered by mise.`

`BASELINE-REVIEW: F189 — eliminate manual synchronization — replace the Python three-provisioner pattern with disjoint ownership: rust-toolchain.toml for first-party Rust and mise.toml for external binaries — no tool version is declared in both.`

`BASELINE-REVIEW: F181 — verify declarative state rather than search ambient PATH — keep check-deps distinct from F180/bootstrap, implementing it with mise ls --missing and rustup component state rather than a command -v loop — this item therefore does not collapse F181 into F180.`

F179 remains unchanged: Make is justified as the bootstrap entry because Just may itself be provisioned by mise; it is not claimed as a Rust ecosystem requirement. F190/F103's exact toolchain-file channel remains coordinated with R27.

### Recommendation

Adopt the **partitioned single-source toolchain stack**:

- **Rust 1.98.1 reference fixture / R27-selected final channel**, through rustup and `rust-toolchain.toml`.
- **mise 2026.9.3**, with exactly one `mise.toml` and committed `mise.lock`.
- **No Flox manifest.**
- **No per-tool Justfile installer recipes or per-tool shell installers.**
- **No normative cargo-binstall dependency:** prefer locked official binaries through mise's Aqua/GitHub backends; use mise's Cargo backend for source-only Rust tools.
- **Invocation contract:** Cargo interfaces for rustfmt, Clippy, and Cargo extensions; bare executables for standalone tools; external resolution through `mise --locked exec`.
- **Lefthook jobs call Just recipes**, so tool arguments have one owner.

This follows the Python precedent's reproducible-environment principle, but not its duplicated implementation; it follows the TypeScript precedent's elimination of unnecessary per-tool installers, without assuming that all Rust-template hygiene capabilities can be folded into one formatter.

### Members

#### rustup + Cargo toolchain contract

##### Landscape

Rustup is the official and recommended Rust installation and toolchain manager. Its checked-in toolchain file can declare channel, profile, components, and targets. Rustfmt and Clippy are first-party rustup components, and the default profile includes both; an explicit minimal profile is preferable here because it makes the required set observable. ([rust-lang.github.io](https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain))

Crates.io and GitHub popularity figures are **inapplicable**: this member is a first-party distribution pattern, not an application dependency or shortlisted third-party crate.

##### Principles and implementation

Rustup owns the compiler and components; Cargo owns workspace-aware execution. `rust-toolchain.toml` is the single Rust version source. `Cargo.toml` owns the compatibility floor through `rust-version`, while CI proves stable and MSRV independently.

##### Dominant choice

`rust-toolchain.toml` plus Cargo frontends is the dominant and authoritative choice. Zed provides a maintained example with `profile = "minimal"` and explicit rustfmt/Clippy components. ([github.com](https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml))

##### Qualified shortlist

- A distribution-provided stable Rust toolchain can work for casual builds.
- Mise can manage Rust directly.
- Flox can put Rust and Cargo inside a full environment.

Neither alternative improves this template's first-party component semantics enough to displace rustup.

##### Excluded by gate

- **Duplicate Rust declarations in rust-toolchain and mise/Flox:** excluded by the one-authority architectural gate.
- **Direct `rustfmt` or `clippy-driver` task commands:** excluded because they bypass Cargo's workspace/package interface.
- **Nightly-only development toolchain:** excluded by the stable-Rust constraint.
- License, RustSec crate, default-feature, async-runtime, and dependency-tree gates are inapplicable to the external first-party distribution itself. The generated workspace remains bound by the fixed `MIT OR Apache-2.0` and MSRV policies.

##### Up-and-comers

Mise recently added richer Rust-component and target reconciliation, but this does not justify replacing rustup's native project file in R42. ([github.com](https://github.com/jdx/mise/releases))

##### Fit for this template

All three products—CLI, library, and web service—reside in a Cargo workspace and benefit from identical formatter, linter, feature, and target selection. Cargo commands preserve that workspace context.

##### Recommendation

Use:

```toml
[toolchain]
channel = "<R27-selected-channel>"
profile = "minimal"
components = ["rustfmt", "clippy"]
```

Do not declare `rust` in `mise.toml`.

##### Ranked runner-up

Mise-managed Rust sourced from the same `rust-toolchain.toml`, but only if R27 establishes and tests a no-duplication import mechanism. It is not the default recommendation.

##### Tradeoffs

Rustup does not install arbitrary non-Rust binaries, system libraries, or services. That limitation is the reason for—not an argument against—the separate mise layer.

##### Parameters

- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- Current reference values on September 9, 2026: stable `1.98.1`; MSRV floor `1.96`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

##### Migration implications

- Add or update `rust-toolchain.toml`.
- Remove rustfmt/Clippy installation logic from Justfile and shell scripts.
- Make CI consume the checked-in file rather than repeating the development channel.
- Keep explicit MSRV CI at `1.96` while the development toolchain follows R27.

##### Validation strategy

Planned:

```sh
rustup show active-toolchain
rustup component list --installed | grep '^rustfmt'
rustup component list --installed | grep '^clippy'
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo +1.96 check --workspace --all-targets --locked
```

Expected: all commands succeed on `ubuntu-latest` and `macos-latest`; the MSRV job does not depend on the development-channel override.

##### Confidence & re-verify trigger

**Confidence: high.** Re-verify only if R27 rejects `rust-toolchain.toml`, rustup changes component-file semantics, or the template moves away from a Cargo workspace.

##### Sources

- Rustup overrides/toolchain file. ([rust-lang.github.io](https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain))
- Rustup component model. ([rust-lang.github.io](https://rust-lang.github.io/rustup/concepts/components.html))
- Rustup profiles. ([rust-lang.github.io](https://rust-lang.github.io/rustup/concepts/profiles.html))
- Rustup official status. ([rust-lang.github.io](https://rust-lang.github.io/rustup/faq.html))
- Current Rust releases. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- Zed reference toolchain. ([github.com](https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml))

#### mise 2026.9.3 + mise.lock

##### Landscape

Mise is the strongest fit among single-manifest, cross-ecosystem provisioners because it supports Cargo packages, GitHub releases, Aqua packages, direct HTTP artifacts, project manifests, lockfiles, and non-activating command execution. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))

**Mandated figure audit**

The research runner did not return JSON bodies from the required crates.io and GitHub API endpoints. No figures below are fabricated or silently replaced:

| Figure | Result | Required endpoint |
|---|---:|---|
| 90-day downloads | **Not retrieved; pre-merge evidence blocker** | `GET https://crates.io/api/v1/crates/mise` → `crate.recent_downloads` |
| All-time downloads | **Not retrieved; pre-merge evidence blocker** | Same → `crate.downloads` |
| Last non-yanked release | Secondary confirmation: `2026.9.3`, published `2026-09-08`; exact versions-endpoint recheck required | `GET https://crates.io/api/v1/crates/mise/versions` |
| Stars | Secondary docs.rs snapshot: `33,628`; exact API recheck required | `GET https://api.github.com/repos/jdx/mise` |
| Archived, pushed_at | **Not retrieved** | Same |
| Open issues | Conventional Issues are disabled in favor of Discussions; exact search total still must be recorded | GitHub Search Issues endpoint |
| Issue responsiveness | **Inapplicable:** the project no longer accepts normal GitHub Issues, so the required ten-issue sample does not exist in the prescribed form | Maintainer README documents the switch. ([github.com](https://github.com/jdx/mise/blob/main/README.md?plain=1)) |
| Advisories | No package-specific result was obtained; run the mandatory RustSec recheck before merge | `https://rustsec.org/packages/mise.html` |
| Adopters | Reverse dependencies are not a meaningful adoption measure for an installed executable; maintained integration evidence is used instead | Official Cargo backend and self-hosted mise tasks |

The current source manifest confirms version `2026.9.3`, edition 2024, MIT licensing, and `rust-version = "1.95"`. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))

##### Principles and implementation

`mise.toml` is the sole declaration of external development binaries; `mise.lock` records exact resolution and checksums where supported. `mise --locked` prevents normal operations from resolving missing artifact URLs through remote APIs. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/mise-lock.html))

The manifest must use explicit backend identifiers instead of relying on mutable shorthand resolution:

1. `aqua:owner/repo` for registry-covered official release binaries.
2. `github:owner/repo` for official releases not represented in Aqua.
3. `cargo:crate` for source-only Rust tools.
4. `http:` with an expected checksum only as a final generic escape hatch.
5. No custom installer script without an explicit owner exception.

##### Dominant choice

Rust projects do not have a single dominant polyglot provisioner. Within the shortlisted one-manifest approaches, mise is the dominant **fit** because it covers Cargo and external binaries without introducing a full Nix environment.

Maintenance state: **active**. Version 2026.9.3 was published one day before the research date, and the current source manifest matches it. ([docs.rs](https://docs.rs/crate/mise/latest))

##### Qualified shortlist

- **Flox:** strongest runner-up where native libraries, services, or full environment closure become requirements. Its committed manifest and lock capture packages and transitive outputs, and `flox activate -- CMD` provides a command boundary. ([flox.dev](https://flox.dev/docs/concepts/environments))
- **Aqua:** strongest runner-up where every selected tool has an official release artifact. Its security model is more specialized, but source-only Cargo coverage is weaker. ([aquaproj.github.io](https://aquaproj.github.io/))
- **Nix/devenv:** qualified for teams already standardized on Nix, but not the portable default for this template.

##### Excluded by gate

- **Mise + Flox kept in sync:** fails the single-authority acceptance criterion.
- **asdf as the normative manifest:** lacks the lock/checksum and direct multi-backend behavior required here; mise can consume legacy asdf metadata without making it the source of truth.
- **Per-tool installers:** fail the maintainability and observable-drift gate.
- **Source-building mise during bootstrap:** excluded. Mise's package has a large dependency surface, full Tokio coupling, and a 16.64 MB published source package; use its prebuilt distribution. ([docs.rs](https://docs.rs/crate/mise/latest))

Fitness gates for the selected prebuilt mise member:

1. **License:** pass—MIT. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
2. **MSRV:** the source crate declares 1.95, within the current 1.96 stable-minus-two floor; full dependency-tree verification remains required only if source installation is enabled. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
3. **RustSec/unsafe:** advisory endpoint recheck is pending. Mise is an external process and makes no no-unsafe guarantee used by this recommendation; it is not linked into application artifacts.
4. **OS:** official installation documentation supports Linux, macOS, and Windows; only Ubuntu and macOS are required here. ([mise.jdx.dev](https://mise.jdx.dev/installing-mise.html))
5. **Features/runtime:** source defaults are native TLS, vendored Lua, and self-update; it uses Tokio with `full`. These are operational facts about the prebuilt CLI, not application runtime coupling. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
6. **Binary/compile cost:** binary footprint is material and source compile cost is high; prebuilt installation confines that cost to download and extraction.

##### Up-and-comers

Mise's native Cargo binary installer is promising but was still experimental in 2026. Its documented transition starts warning in 2027.1.0 and changes defaults in 2027.7.0, so it should be reconsidered after that transition rather than adopted early. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))

##### Fit for this template

The template is Rust-centric but not Rust-only: repository YAML, secrets, spelling, and automation checks can be implemented by tools from several ecosystems. Mise covers that surface while allowing the application itself to remain a normal Cargo workspace.

##### Recommendation

Pin **mise 2026.9.3**, commit `mise.toml` and `mise.lock`, and use no second provisioner manifest.

Do not put Rust in `[tools]`. Add a CI guard proving that `mise exec` still resolves Cargo through rustup.

##### Ranked runner-up

**Flox**, but only if another item establishes a requirement for pinned native libraries, services, or full environment closure that mise cannot satisfy.

##### Tradeoffs

- Adds one bootstrap binary.
- Rapid release cadence requires exact pins and controlled updates.
- Lock quality varies by backend.
- Contributors using global mise declarations can accidentally shadow project commands unless identity checks are enforced.
- Source-only Cargo tools still incur compile time.

##### Parameters

- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes license = MIT OR Apache-2.0`
- `assumes no selected R27–R40 tool may bypass its own fitness gates merely because mise can install it`

##### Migration implications

- Add `mise.toml`.
- Add and commit `mise.lock`.
- Add one pinned mise bootstrap path in `scripts/bootstrap-dev.sh`.
- Remove `.flox/` if inherited.
- Remove all selected-tool installation recipes and scripts.
- Add a documented controlled update flow: edit pin, run `mise lock`, run both OS jobs, commit lock change.

##### Validation strategy

Planned:

```sh
mise version
mise lock
git diff --exit-code -- mise.lock
mise --locked install
test -z "$(mise ls --missing --no-header)"
mise --locked exec -- sh -c \
  'test "$(command -v cargo)" = "$(rustup which cargo)"'
mise --locked exec -- cargo nextest --version
mise --locked exec -- actionlint -version
```

Cold/warm installation performance should be measured on both target OSes with:

- Empty `MISE_DATA_DIR` and Cargo cache for the cold run.
- Wall time and peak RSS via `/usr/bin/time`.
- Installed disk growth via `du`.
- A second no-op `mise --locked install` for warm latency.
- Verbose logs recording which backend and artifact were used.

No such benchmark was executed during this documentation-only research, and no absolute speed claim is made.

##### Confidence & re-verify trigger

**Confidence: medium-high on architecture; medium on the exact release pin.**

Do not merge until the mandated API figures and RustSec result are retrieved. Revisit after mise 2027.7.0, if a selected tool lacks a lockable Ubuntu/macOS backend, or if the external tool set becomes empty.

##### Sources

- Mise Cargo backend. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))
- Mise lockfile. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/mise-lock.html))
- Mise CLI and locked mode. ([mise.jdx.dev](https://mise.jdx.dev/cli/))
- Mise installation. ([mise.jdx.dev](https://mise.jdx.dev/installing-mise.html))
- Current manifest/MSRV/license. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
- Features and Tokio coupling. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
- Issue-policy evidence. ([github.com](https://github.com/jdx/mise/blob/main/README.md?plain=1))

#### external Cargo-tool installer policy

##### Landscape

The Rust field has three material choices:

- First-party `cargo install`.
- cargo-binstall as a prebuilt-binary accelerator.
- Project-scoped wrappers such as cargo-run-bin.

Cargo installation accepts exact versions and `--locked`, installs binaries into a Cargo bin directory, and is deliberately Rust-specific. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-install.html))

Cargo-binstall looks for upstream binary artifacts and can fall back to `cargo install`; it supports Linux and macOS artifacts and CI. ([github.com](https://github.com/cargo-bins/cargo-binstall))

This member is a **policy pattern**, not a crate linked into the generated application. Crate download and reverse-dependency figures are therefore inapplicable to the recommendation itself.

##### Principles and implementation

Installation behavior must not depend on whether a contributor happens to have cargo-binstall globally installed. Two contributors with the same committed files should not silently consume different artifact sources.

##### Dominant choice

`cargo install` remains the authoritative built-in fallback for Rust binaries. Prebuilt binaries are preferable for bootstrap performance when they are official, versioned, and checksum-lockable.

##### Qualified shortlist

- Mise `aqua:` or `github:` backend for official prebuilt releases.
- Mise `cargo:` backend for source-only tools.
- Cargo-binstall if the project later adopts and pins it explicitly as a first-class component.

##### Excluded by gate

- **Rustup/Cargo as the entire provisioning stack:** fails functional coverage for non-Rust tools.
- **Ambient cargo-binstall:** fails deterministic-installation policy because its presence changes mise's Cargo behavior.
- **Cargo-binstall as normative today:** its mandated crates.io/GitHub figures, package-level MSRV declaration, license, and RustSec evidence were not fully established in this run. The root workspace manifest did not contain a `rust-version`; package-specific submanifest verification is required before reconsideration. ([raw.githubusercontent.com](https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/Cargo.toml))
- **cargo-run-bin as the whole solution:** fails capability coverage for non-Rust standalone binaries.
- **QuickInstall artifacts:** excluded from the normative supply chain. Cargo-binstall documents that this is a third-party artifact host with optional telemetry; mise already disables that strategy by default when using external cargo-binstall. ([github.com](https://github.com/cargo-bins/cargo-binstall))

##### Up-and-comers

Mise's native Cargo binary download path could eventually remove the cargo-binstall prerequisite while retaining prebuilt speed. It remains experimental and is not selected for this version. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))

##### Fit for this template

The expected set of Cargo-installed development CLIs is small. Paying a one-time source-build cost for the minority that lack official binaries is preferable to introducing a second installer whose presence can vary by workstation.

##### Recommendation

Set:

```toml
[settings]
cargo.binstall = false
```

Backend policy:

1. Official locked Aqua/GitHub binary.
2. Exact Cargo version with locked source installation.
3. Generic checksummed HTTP artifact.
4. Reject the selected tool or obtain an explicit owner exception before adding a custom installer.

##### Ranked runner-up

A pinned cargo-binstall release, declared in the same mise manifest and configured as `binstall_only`, once its license, MSRV, advisory status, and both-OS behavior have been reverified.

##### Tradeoffs

The selected baseline has higher cold bootstrap latency and disk use for source-only Cargo tools. It has lower architectural and supply-chain variability. Compile-time cost is bounded to bootstrap and CI image preparation, never a normal hook.

##### Parameters

- Cargo installation affects provisioning only.
- Runtime invocation remains determined by the tool's interface: `cargo foo` for a Cargo extension, bare `foo` for a standalone executable.

##### Migration implications

- Remove direct `cargo binstall` calls from Make, Just, and CI.
- Remove cargo-binstall bootstrap logic.
- Encode every selected Cargo tool as an exact mise entry.
- Prefer a release-binary backend when the owning item verifies official artifacts for both target OSes.

##### Validation strategy

Planned:

```sh
MISE_DEBUG=1 mise --locked install 2>&1 | tee install.log
! grep -q 'quick-install' install.log
! grep -q 'cargo binstall' install.log
```

For every `cargo:` tool, verify the verbose installation log uses the intended exact version and locked dependency resolution. If the current mise backend cannot provide locked source installation for a selected crate, use its official release backend or reopen this member.

##### Confidence & re-verify trigger

**Confidence: medium-high.** Revisit when mise's native binary installer becomes non-experimental, or if cold source compilation breaches the integration budget established by measured Ubuntu/macOS runs.

##### Sources

- Cargo install documentation. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-install.html))
- Cargo-install RFC and package-manager boundary. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1200-cargo-install.html))
- Mise Cargo backend semantics. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))
- Cargo-binstall architecture and security notes. ([github.com](https://github.com/cargo-bins/cargo-binstall))
- Cargo-binstall OS CI. ([raw.githubusercontent.com](https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/.github/workflows/ci.yml))

#### Justfile and lefthook invocation contract

##### Landscape

The field distinguishes:

- First-party Cargo commands such as `cargo fmt` and `cargo clippy`.
- Cargo extensions installed as `cargo-foo` but invoked as `cargo foo`.
- Standalone executables invoked by binary name.
- Direct driver binaries such as `rustfmt` or `clippy-driver`.

Clippy's official documentation presents `cargo clippy` as the normal project interface and reserves `clippy-driver` for projects that do not use Cargo. ([github.com](https://github.com/rust-lang/rust-clippy))

##### Principles and implementation

Installation mechanism does not determine runtime syntax. A Rust implementation may still expose a standalone executable, while a prebuilt binary may implement a Cargo extension.

All actual arguments should live in Justfile. Lefthook supplies event/file context and calls the corresponding Just recipe.

##### Dominant choice

- rustfmt: `cargo fmt`.
- Clippy: `cargo clippy`.
- Cargo extension: `cargo <extension>`.
- Standalone tool: `<binary>`.
- External execution boundary: `mise --locked exec --`.
- Hook orchestration: `mise --locked exec -- just <hook-recipe>`.

The uv and nextest repositories provide maintained examples of these interface categories: uv documents Cargo formatter/linter commands and standalone system tools, while nextest is explicitly a Cargo subcommand. ([github.com](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1))

##### Qualified shortlist

- Hooks directly invoking tools are acceptable only for extremely small repositories.
- Mise tasks could replace Just entirely.
- A repository-local wrapper script could centralize execution.

Those alternatives are unnecessary because Just and lefthook are already selected architectural roles.

##### Excluded by gate

- `rustfmt` directly in Justfile/lefthook: fails workspace-interface policy.
- `clippy-driver`: fails Cargo-workspace fit.
- Bare external tool names without a provisioned execution boundary: fails reproducibility.
- Hooks containing their own full tool arguments: fails single-command-owner policy.
- Installer calls inside task or hook recipes: fails bootstrap/task separation.

##### Up-and-comers

Mise tasks can attach exact tool requirements to individual tasks and automatically install them, but automatic installation at task execution conflicts with the required no-install normal-task policy. ([github.com](https://github.com/jdx/mise/blob/main/docs/tasks/task-configuration.md))

##### Fit for this template

A CLI/library/web-service workspace needs Cargo's package, target, feature, and workspace interpretation. Repository-only tools do not, so their standalone interfaces remain clearer.

##### Recommendation

Set the owned parameter to:

> **Cargo frontends for rustup components and Cargo extensions; provisioned bare binaries for standalone tools; all external tool resolution under a locked mise boundary; lefthook delegates to Just.**

Examples:

```just
fmt-check:
    cargo fmt --all -- --check

clippy:
    cargo clippy --workspace --all-targets --all-features --locked -- -D warnings

cargo-extension:
    mise --locked exec -- cargo example run

standalone-tool:
    mise --locked exec -- example-tool
```

```yaml
commands:
  example:
    run: mise --locked exec -- just standalone-tool
```

##### Ranked runner-up

Direct hook invocation under `mise --locked exec`, but only if there is no reusable Just recipe. It is ranked lower because it duplicates command ownership.

##### Tradeoffs

Delegating through Just adds one process boundary. In return, local commands, CI, and hooks share arguments and exit behavior. For lint/format workloads the process-launch overhead is negligible relative to Cargo metadata loading or tool execution; this should still be checked rather than asserted for sub-10 ms tools.

##### Parameters

- `owns package-manager-invocation = cargo fmt / cargo clippy / cargo <extension> for Cargo-integrated tools; mise --locked exec -- <binary> for standalone tools; lefthook uses mise --locked exec -- just <recipe>`

##### Migration implications

- Replace direct `rustfmt` and Clippy-driver calls.
- Move duplicated lefthook arguments into private/public Just recipes.
- Prefix standalone tools with the locked mise execution boundary.
- Add a Cargo-path identity check.
- Keep lefthook's own installation out of this change; R37 owns it.

##### Validation strategy

Planned static checks:

```sh
! rg -n '\b(clippy-driver|rustfmt)\b' Justfile lefthook.yml
rg -n 'cargo fmt\b' Justfile
rg -n 'cargo clippy\b' Justfile

# Hooks should delegate to Just.
! rg -n 'run:\s+(cargo|actionlint|gitleaks|typos|yamlfmt|taplo)\b' lefthook.yml

# No installer behavior in normal tasks.
! rg -n '(cargo install|cargo binstall|mise install|curl .*\|.*sh)' \
  Justfile lefthook.yml
```

Runtime checks:

```sh
just fmt-check
just clippy
mise --locked exec -- just workflow-lint
```

Expected: identical exit status locally and in both CI operating systems.

##### Confidence & re-verify trigger

**Confidence: high.** Revisit only if Just or lefthook is replaced, or a selected tool's officially documented CLI contradicts its assigned category.

##### Sources

- Official Clippy invocation guidance. ([github.com](https://github.com/rust-lang/rust-clippy))
- Cargo command model. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo.html))
- uv contributor commands and hooks. ([github.com](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1))
- Nextest Cargo-subcommand reference. ([github.com](https://github.com/nextest-rs/nextest))
- Mise execution boundary. ([mise.jdx.dev](https://mise.jdx.dev/cli/))

### Compatibility

The maintained compatibility proof is mise's official Cargo-backend example: it installs a Rust toolchain and a Cargo-published CLI, then executes the resulting binary through `mise exec`. The same backend documentation defines its cargo-binstall and Cargo fallback behavior. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))

The recommended version matrix is:

| Member | Version/interface | Compatibility evidence |
|---|---|---|
| Rust development toolchain | `1.98.1` reference fixture | Current stable patch on September 9, 2026. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/)) |
| Workspace MSRV | `1.96` | Current stable minus two minor versions. |
| mise | `2026.9.3` | Edition 2024; source `rust-version = 1.95`, therefore source-compatible with the current development compiler. ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml)) |
| Rust components | rustfmt, Clippy | Distributed by rustup for the selected toolchain. ([rust-lang.github.io](https://rust-lang.github.io/rustup/concepts/components.html)) |
| External tools | Exact R27–R40 pins | Installed through locked mise backends and invoked by their published interface. |
| Target OSes | Ubuntu and macOS | Rustup and mise both publish/support these platforms. ([github.com](https://github.com/cargo-bins/cargo-binstall)) |

No public adopter was found that exactly combines this partition—rustup-owned Rust, mise-owned external tools, Just orchestration, and lefthook delegation. The compatibility evidence is therefore the maintained mise integration plus the proposed two-OS executable fixture. That fixture was **not run during this research** and is a pre-implementation requirement.

### Parameters

`owns package-manager-invocation = cargo fmt / cargo clippy / cargo <extension> for Cargo-integrated tools; mise --locked exec -- <standalone-binary> for standalone tools; lefthook jobs invoke mise --locked exec -- just <recipe>`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No `CONFLICT:` is required.

### Migration implications

| File | Change |
|---|---|
| `rust-toolchain.toml` | Declare the R27-owned channel, minimal profile, rustfmt, and Clippy. |
| `mise.toml` | Add mise minimum version, lockfile setting, `cargo.binstall = false`, and exact external-tool declarations supplied by R27–R40. Do not declare Rust. |
| `mise.lock` | Add and commit generated resolution/checksum state. |
| `Makefile` | Keep one bootstrap target. Install/check only rustup and mise, trigger the Rust toolchain, then run `mise --locked install`. |
| `Justfile` | Delete all per-tool installers. Add `check-deps`; use Cargo interfaces for Cargo-aware tools and the locked mise boundary for standalone tools. |
| `lefthook.yml` | Replace direct tool commands with calls to corresponding Just recipes. Do not decide lefthook's own installation path. |
| `scripts/bootstrap-dev.sh` | One manager-bootstrap script, with pinned mise and rustup installation; no selected-tool branches. |
| `scripts/install-*.sh` | Delete tool-specific installer scripts. |
| `.flox/` | Deliberately absent; delete if inherited. |
| `.github/workflows/*.yml` | Run the same bootstrap and Just recipes on Ubuntu and macOS; avoid separate CI-only tool installers. |
| `CONTRIBUTING.md` | Document the single supported provisioner, update flow, activation-optional usage, and why Flox/per-tool installers are absent. |
| `docs/port/COMMONALITY.md` | Record F183/F187/F188/F189 and the F181 implementation change. |
| `docs/port/BASELINE-REVIEW.md` | Add the five explicit `BASELINE-REVIEW` findings above. |

### Validation strategy

**Executed during research:** documentation, repository-manifest, workflow, and reference-implementation inspection.

**Not executed:** cloning a fixture, installation, builds, hooks, benchmarks, or CI. All commands below are planned acceptance checks.

#### Required evidence completion

Before merge, collect the missing mandated figures exactly as specified:

```sh
curl -fsS https://crates.io/api/v1/crates/mise |
  jq '{recent_downloads: .crate.recent_downloads,
       downloads: .crate.downloads}'

curl -fsS https://crates.io/api/v1/crates/mise/versions |
  jq '[.versions[] | select(.yanked == false)]
      | sort_by(.created_at) | last
      | {num, created_at}'

gh api repos/jdx/mise \
  --jq '{stars: .stargazers_count,
         archived: .archived,
         pushed_at: .pushed_at}'

gh api search/issues \
  -f q='repo:jdx/mise is:issue is:open' \
  --jq '{open_issues: .total_count}'

curl -fsS https://rustsec.org/packages/mise.html
```

Because mise uses Discussions rather than Issues, record issue responsiveness as `inapplicable — GitHub Issues disabled` unless normal Issues have been re-enabled.

#### Integration fixture

```sh
make bootstrap
mise version
rustc --version
cargo --version
mise --locked install
test -z "$(mise ls --missing --no-header)"

mise --locked exec -- sh -eu -c \
  'test "$(command -v cargo)" = "$(rustup which cargo)"'

just fmt-check
just clippy
mise --locked exec -- cargo nextest --version
mise --locked exec -- actionlint -version
```

Expected behavior:

- Bootstrap is idempotent.
- A second bootstrap performs no tool upgrades.
- Cargo resolves through rustup.
- Every external binary resolves from the committed mise configuration.
- No normal recipe performs installation.

#### Lock and drift tests

```sh
mise lock
git diff --exit-code -- mise.lock

cp mise.toml /tmp/mise.toml.before
# Deliberately change one fixture version.
mise lock
! git diff --quiet -- mise.lock
mv /tmp/mise.toml.before mise.toml
git restore mise.lock
```

#### Structural tests

```sh
! find . -path './.git' -prune -o \
  \( -name '.flox' -o -name 'manifest.toml' \) -print |
  grep '/.flox/'

! rg -n '^[[:space:]]*install-[A-Za-z0-9_-]+:' Justfile

! find scripts -maxdepth 1 -type f -name 'install-*.sh' -print |
  grep .

! rg -n '\b(clippy-driver|rustfmt)\b' Justfile lefthook.yml

! rg -n '(cargo install|cargo binstall|mise install)' \
  Justfile lefthook.yml
```

#### OS matrix

Run the complete fixture on:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
```

#### Representative performance check

For a cold and warm bootstrap on each OS, record:

- Tool set and exact versions.
- Backend used by each tool.
- Wall-clock latency.
- Peak RSS.
- Network bytes if available from runner instrumentation.
- Added disk use in Cargo and mise data directories.
- Warm no-op latency.

Do not compare a source-built Cargo tool with a downloaded release binary and label either globally “fastest”; report the workload and artifact path.

### Confidence & re-verify trigger

**Overall confidence: 0.84 on the architecture and invocation policy; 0.68 on the exact mise release pin pending the required endpoint and advisory checks.**

Re-verify when any of the following occurs:

1. Before implementation, because the required crates.io/GitHub/RustSec endpoint results remain incomplete.
2. R27–R40 select all-Rustup/Cargo tools, leaving no external binary; at that point mise may become removable.
3. A selected tool lacks a locked backend and official Ubuntu/macOS artifact.
4. Mise's native Cargo binary installation becomes the stable default—documented for reconsideration around 2027.7.0. ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))
5. R27 changes the toolchain-file channel or mise shadows rustup's Cargo in the integration test.
6. Native libraries or services become first-class development dependencies, making Flox/Nix materially more appropriate.
7. Mise changes lockfile or backend semantics, its license changes, an open advisory appears, or maintenance state becomes at-risk.

### Sources

All URLs retrieved September 9, 2026.

- Rustup toolchain files: `https://rust-lang.github.io/rustup/overrides.html` ([rust-lang.github.io](https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain))
- Rustup components: `https://rust-lang.github.io/rustup/concepts/components.html` ([rust-lang.github.io](https://rust-lang.github.io/rustup/concepts/components.html))
- Rustup profiles: `https://rust-lang.github.io/rustup/concepts/profiles.html` ([rust-lang.github.io](https://rust-lang.github.io/rustup/concepts/profiles.html))
- Rustup official status: `https://rust-lang.github.io/rustup/faq.html` ([rust-lang.github.io](https://rust-lang.github.io/rustup/faq.html))
- Cargo install command: `https://doc.rust-lang.org/cargo/commands/cargo-install.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-install.html))
- Cargo-install RFC: `https://rust-lang.github.io/rfcs/1200-cargo-install.html` ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1200-cargo-install.html))
- Rust release list: `https://blog.rust-lang.org/releases/` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- 2025 State of Rust Survey: `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- Mise Cargo backend: `https://mise.jdx.dev/dev-tools/backends/cargo` ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/backends/cargo))
- Mise lockfile: `https://mise.jdx.dev/dev-tools/mise-lock.html` ([mise.jdx.dev](https://mise.jdx.dev/dev-tools/mise-lock.html))
- Mise CLI/locked mode: `https://mise.jdx.dev/cli/` ([mise.jdx.dev](https://mise.jdx.dev/cli/))
- Mise installation: `https://mise.jdx.dev/installing-mise.html` ([mise.jdx.dev](https://mise.jdx.dev/installing-mise.html))
- Mise current Cargo manifest: `https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml))
- Mise crate documentation: `https://docs.rs/crate/mise/latest` ([docs.rs](https://docs.rs/crate/mise/latest))
- Flox environment model: `https://flox.dev/docs/concepts/environments` ([flox.dev](https://flox.dev/docs/concepts/environments))
- Flox activation model: `https://flox.dev/docs/man/flox-activate` ([flox.dev](https://flox.dev/docs/man/flox-activate))
- Aqua security overview: `https://aquaproj.github.io/` ([aquaproj.github.io](https://aquaproj.github.io/))
- Aqua checksum verification: `https://aquaproj.github.io/docs/reference/security/checksum/` ([aquaproj.github.io](https://aquaproj.github.io/docs/reference/security/checksum/))
- Cargo-binstall implementation: `https://github.com/cargo-bins/cargo-binstall` ([github.com](https://github.com/cargo-bins/cargo-binstall))
- Cargo-binstall artifact metadata: `https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md))
- Zed toolchain reference: `https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml` ([github.com](https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml))
- uv contributor workflow: `https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md` ([github.com](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1))
- uv pre-commit invocation evidence: `https://github.com/astral-sh/uv/blob/main/.pre-commit-config.yaml` ([github.com](https://github.com/astral-sh/uv/blob/main/.pre-commit-config.yaml))
- Nextest repository: `https://github.com/nextest-rs/nextest` ([github.com](https://github.com/nextest-rs/nextest))
- Nextest prebuilt installation guidance: `https://github.com/nextest-rs/nextest/blob/main/site/src/docs/installation/pre-built-binaries.md` ([github.com](https://github.com/nextest-rs/nextest/blob/main/site/src/docs/installation/pre-built-binaries.md))

## Sources

- [https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain](https://rust-lang.github.io/rustup/overrides.html?highlight=toolchain)
- [https://rust-lang.github.io/rfcs/1200-cargo-install.html](https://rust-lang.github.io/rfcs/1200-cargo-install.html)
- [https://aquaproj.github.io/](https://aquaproj.github.io/)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://mise.jdx.dev/dev-tools/backends/cargo](https://mise.jdx.dev/dev-tools/backends/cargo)
- [https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml](https://raw.githubusercontent.com/jdx/mise/main/Cargo.toml)
- [https://www.zero2prod.com/assets/sample_zero2prod.pdf](https://www.zero2prod.com/assets/sample_zero2prod.pdf)
- [https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml](https://github.com/zed-industries/zed/blob/main/rust-toolchain.toml)
- [https://github.com/astral-sh/uv?ref=malemburg.com](https://github.com/astral-sh/uv?ref=malemburg.com)
- [https://github.com/nextest-rs/nextest](https://github.com/nextest-rs/nextest)
- [https://github.com/astral-sh/ruff/blob/main/BREAKING_CHANGES.md](https://github.com/astral-sh/ruff/blob/main/BREAKING_CHANGES.md)
- [https://flox.dev/docs/concepts/environments](https://flox.dev/docs/concepts/environments)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://mise.jdx.dev/cli/ls.html](https://mise.jdx.dev/cli/ls.html)
- [https://mise.jdx.dev/cli/](https://mise.jdx.dev/cli/)
- [https://github.com/jdx/mise/releases](https://github.com/jdx/mise/releases)
- [https://rust-lang.github.io/rustup/concepts/components.html](https://rust-lang.github.io/rustup/concepts/components.html)
- [https://rust-lang.github.io/rustup/concepts/profiles.html](https://rust-lang.github.io/rustup/concepts/profiles.html)
- [https://rust-lang.github.io/rustup/faq.html](https://rust-lang.github.io/rustup/faq.html)
- [https://github.com/jdx/mise/blob/main/README.md?plain=1](https://github.com/jdx/mise/blob/main/README.md?plain=1)
- [https://mise.jdx.dev/dev-tools/mise-lock.html](https://mise.jdx.dev/dev-tools/mise-lock.html)
- [https://docs.rs/crate/mise/latest](https://docs.rs/crate/mise/latest)
- [https://mise.jdx.dev/installing-mise.html](https://mise.jdx.dev/installing-mise.html)
- [https://doc.rust-lang.org/cargo/commands/cargo-install.html](https://doc.rust-lang.org/cargo/commands/cargo-install.html)
- [https://github.com/cargo-bins/cargo-binstall](https://github.com/cargo-bins/cargo-binstall)
- [https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/Cargo.toml](https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/Cargo.toml)
- [https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/.github/workflows/ci.yml](https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/.github/workflows/ci.yml)
- [https://github.com/rust-lang/rust-clippy](https://github.com/rust-lang/rust-clippy)
- [https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1)
- [https://github.com/jdx/mise/blob/main/docs/tasks/task-configuration.md](https://github.com/jdx/mise/blob/main/docs/tasks/task-configuration.md)
- [https://doc.rust-lang.org/cargo/commands/cargo.html](https://doc.rust-lang.org/cargo/commands/cargo.html)
- [https://flox.dev/docs/man/flox-activate](https://flox.dev/docs/man/flox-activate)
- [https://aquaproj.github.io/docs/reference/security/checksum/](https://aquaproj.github.io/docs/reference/security/checksum/)
- [https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md)
- [https://github.com/astral-sh/uv/blob/main/.pre-commit-config.yaml](https://github.com/astral-sh/uv/blob/main/.pre-commit-config.yaml)
- [https://github.com/nextest-rs/nextest/blob/main/site/src/docs/installation/pre-built-binaries.md](https://github.com/nextest-rs/nextest/blob/main/site/src/docs/installation/pre-built-binaries.md)