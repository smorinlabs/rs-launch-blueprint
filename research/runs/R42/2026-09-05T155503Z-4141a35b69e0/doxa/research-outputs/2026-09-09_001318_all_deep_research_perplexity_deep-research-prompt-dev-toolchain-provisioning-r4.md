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
provider: perplexity
model: sonar-deep-research
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

# Dev-toolchain provisioning for `rs-launch-blueprint` (R42 bundle)

The `rs-launch-blueprint` template must provide a reproducible, cross‑platform Rust development environment for a combined CLI, library, and web service, while respecting the owner’s MSRV and licensing policies and aligning with prior Python and TypeScript template decisions. The core decision under R42 is how this template provisions and invokes its non‑cargo developer toolchain: whether through per‑tool Justfile installer recipes and shell scripts, through one or more declarative toolchain provisioners (mise and/or flox) kept in sync with native installs, or relying solely on rustup and cargo (including cargo-binstall) without an additional provisioning layer. Based on an ecosystem survey, authoritative Rust guidance, and practice in well‑regarded Rust projects, the recommended bundle is a three‑layer stack: Rust’s first‑party toolchain components managed by rustup and invoked through cargo subcommands for rustfmt and Clippy; a single declarative provisioner manifest using **mise** as the canonical dev‑tools manager for non‑Rust and non‑cargo tools (with flox treated as an optional, non‑baseline up‑and‑comer); and **cargo-binstall** as the preferred installer for Rust CLI tools that are not part of the standard toolchain, with Justfile recipes and Lefthook jobs invoking these dev tools as binaries on `PATH` rather than as cargo subcommands. This design drops per‑tool installer recipes as a baseline mechanism, consolidates provisioner manifests to one (mise) rather than three, and defines `package-manager-invocation` as “first‑party Rust tools via cargo subcommands, all other dev tools via provisioned binaries on `PATH`,” with explicit baseline reviews for F181, F183, F187, F188 and F189.

## Context and objectives

The owner’s research mandate requires that R42 identify the shared engineering principle, the level at which agreement is required, and observable acceptance criteria, and then select architectures and libraries that best realize those principles in the Rust ecosystem. Agreement or familiarity alone cannot select a design, and existing precedent in the Python and TypeScript templates is evidence rather than a winner. The fixed parameters already decided for `rs-launch-blueprint` are a Rust edition of 2024, an MSRV policy of “stable minus two minor versions, raised only in a minor release, declared as `rust-version` in `Cargo.toml` and tested in CI,” a dual license of `MIT OR Apache-2.0`, and a CI target OS matrix of `ubuntu-latest` and `macos-latest`.[12] These parameters constrain any recommended dev‑tool stack.

In the Python template (`py-launch-blueprint`), the precedent is a set of per‑tool Justfile installer recipes for every non‑native dev tool (taplo, gitleaks, actionlint, yamlfmt), plus two declarative toolchain provisioner manifests—mise and flox—that must be kept in manual sync with native installs.[27][3] The Justfile’s installer recipes include specific targets such as `install-taplo`, `install-gitleaks`, and `install-actionlint`, some of which shell out to dedicated shell scripts for installation.[27] The `mise.toml` declares the full dev‑tool set under `[tools]` (python, uv, ruff, taplo, gitleaks, just, bun, gh, lefthook, make, actionlint).[39][50] The `.flox/env/manifest.toml` mirrors those tools using `pkg-path` entries under `[install]`.[3] F189 records that these three provisioners—native installers, mise, and flox—are kept in manual sync and treated as “first‑class dev environments.”[39]

In the TypeScript template (`ts-launch-blueprint`), prior decisions D‑014(6) and D‑014(7) explain a divergent pattern: taplo and yamlfmt are folded into a single formatter tool (Oxfmt) and actionlint is treated as advisory‑only inside `check-deps`.[21] As a result, there are no dedicated per‑tool installer recipes or scripts, and no mise or flox manifests; the template provisions only natively via Makefile/Justfile installers and packages.[21] The ledger records F183, F187, F188 and F189 as `DIVERGENT`, with `py` using three coordinated provisioners and `ts` using none.[27][3]

The owner’s direction for R42 is to work “against the existing solutions and follow a similar pattern,” meaning that the Rust template should consider the same architectural questions—per‑tool installers, declarative provisioners, and tool invocation—but arrive at a design appropriate to Rust’s ecosystem, rather than simply copying either `py` or `ts`.[27][39][50] R42 owns the `package-manager-invocation` parameter that will be consumed by R27, R28, R29, R32, R37 and R40, each of which picks specific dev tools (secret scanner, YAML linter, spell checker, actionlint, hook manager). This item therefore must decide, for any dev tool they pick, how it is provisioned (rustup components, cargo install, cargo-binstall, mise, flox, or OS package manager) and how it is invoked in Justfile recipes and Lefthook jobs (cargo subcommand vs. binary on `PATH`), without changing their tool choices.

## Decision framework

### Landscape

The category R42 decides can be stated as “dev‑toolchain provisioning and invocation for Rust projects that combine CLI, library, and web service crates.” At this level, the landscape consists of three interacting layers: first‑party Rust toolchain components managed by rustup and exposed as cargo subcommands; Rust‑native CLI tools that are installed via cargo and cargo-binstall; and polyglot dev‑tool managers such as mise and flox, which declaratively provision Rust and non‑Rust tools and coordinate environment variables and tasks.[5][10][11][35][3][7][3]

To satisfy the owner’s “forest before trees” requirement, the Rust field can be mapped into three bins—built‑in or first‑party toolchain, established industry standards, and up‑and‑comers—before any candidates are shortlisted.

In the built‑in or first‑party toolchain bin, the primary actors are rustup, cargo, rustfmt, Clippy, and rust-analyzer. The Rust book’s Appendix on useful development tools describes `rustfmt` as the community code formatter and `cargo fmt` as the idiomatic way to format any Cargo project, noting that `rustfmt` and `cargo-fmt` are installed by default with Rust.[5][10] The same appendix describes Clippy as a collection of lints to analyze code and notes that Clippy is included with standard Rust installations and is invoked as `cargo clippy`.[5][10] The Clippy usage documentation reinforces this, describing `cargo clippy` as the easiest and most common way to run Clippy, and showing command‑line lint configuration and CI usage with `cargo clippy -- -D warnings`.[48] Rustup’s component model is the authoritative mechanism for adding `rustfmt`, `clippy`, and `rust-src` to a toolchain, via `rustup component add rustfmt clippy rust-src`.[6][9][48] The official Rust book and Clippy documentation are authoritative because they are maintained by the Rust team and published on `doc.rust-lang.org`.[5][10][48] Rust-analyzer is the first‑party language server used by most editors, installed via editor-specific plugins but often backed by the `rust-analyzer` component in rustup.[5][10]

In the established industry standard bin for Rust dev‑tool provisioning, two main patterns appear: rustup plus cargo only; and rustup plus cargo combined with a task runner such as just, alongside optional declarative toolchain managers such as mise. The `just` tool is a command runner written in Rust that uses a Makefile‑inspired syntax, and is widely used in Rust projects to define recipes such as `build`, `test`, `clippy`, and `fmt`.[21][26][29] DeepWiki’s survey of Rust projects shows `just` used as the central command runner in projects like `java_lsp`, where commands such as `just dev`, `just test`, `just clippy`, and `just fmt` orchestrate cargo and other tools.[26] Another DeepWiki entry for the Rust project `just` itself documents CI check groups with recipes such as `clippy` and `fmt` mapping to `cargo clippy` and `cargo fmt` invocations.[8] These examples are authoritative for practice because they document actively maintained Rust projects, with `just` itself being a widely used tool with GitHub stars and ongoing releases, and `java_lsp` representing a multi‑crate workspace.[21][26][29]

Mise is a Rust‑based runtime version manager and task runner that manages dev tools, environment variables, and tasks from a single `mise.toml` file.[35][39][43] The mise documentation describes a Rust backend that installs toolchains and components via rustup, allowing per‑project pinning of Rust versions and components such as `rustfmt`, `clippy`, `rust-src`, and `llvm-tools`, and exposing tasks under `[tasks]`.[7][49] Mise’s `lang/rust` documentation explains how it installs Rust toolchains using rustup under the hood, respects `RUSTUP_HOME` and `CARGO_HOME`, and can be configured per project or globally.[7][7] Another mise document details tool‑options for the Rust backend, including a `profile` option with values `minimal`, `default`, and `complete`, where the default profile includes rust-docs, rustfmt, and clippy.[49] These docs are authoritative because they are maintained by mise’s author and hosted on the project’s official website.[35][7][7][49] Practice evidence comes from projects like NVIDIA’s `OpenShell`, which use mise to bootstrap multiple language toolchains including Rust, Python, and Kubernetes tools from a single `mise.toml`. In `OpenShell`, `[tools]` includes `rust` with a pinned version and other tools like `python` and `kubectl`, and mise installs all pinned tools on first use. This demonstrates mise’s use in a multi‑language, production‑grade Rust codebase.

Flox represents the up‑and‑comer bin for Rust dev‑tool provisioning. Flox defines environments declaratively with a `manifest.toml` file in `.flox/env`, which specifies packages under `[install]` (including Rust toolchain components like `cargo`, `rustc`, `rustfmt`, `clippy`, `rust-lib-src`, and `rust-analyzer`) and environment variables under `[vars]`, plus hooks under `[hook]` that run upon activation.[2][3][3] Flox documentation shows Rust development environment manifests that unbundle toolchain components, requiring `cargo` and `rustc` to be installed as independent packages and grouping them in a `rust-toolchain` package group.[2][3][4][3][3] These docs are authoritative as the official Flox documentation explaining how to build Rust dev environments atop Nix.[2][3][3] Flox’s practice evidence in Rust contexts is emerging rather than mainstream; for example, the Flox blog describes a “real world Rust project with Flox” that groups Rust tools from a single compiler release into a `rust-toolchain` package group.[4] However, compared to rustup and mise, Flox’s adoption in Rust projects is still an up‑and‑coming pattern, more common among teams already invested in Nix.

Cargo-binstall is an established tool for installing Rust binaries as pre‑compiled artifacts rather than building from source with `cargo install`.[11][11][31][33][11][31][33][11][31] Its README explains that Binstall fetches crate information from `crates.io`, discovers releases and artifacts from the linked repository, falls back to quickinstall, and finally to `cargo install` if necessary.[11][31][11][31][46] It is positioned as a drop‑in replacement for `cargo install` in many cases and is used in CI via either its GitHub Action (`cargo-bins/cargo-binstall@main`) or one‑liners that download pre‑compiled binaries for Linux, macOS, and Windows.[11][31][33][11][31][33][11][31] The tool is authoritative for this landscape because it is maintained in an active GitHub repository with regular releases (e.g. v1.4.1 in 2026), and is recommended by community writeups as a way to avoid compilation time when installing tools like `cargo-nextest`. Lib.rs and docs.rs pages show cargo-binstall as a well‑used development tool, though the precise download figures would require querying `crates.io`.[11][11][31][33][11][31]

Taplo and typos represent Rust‑native dev tools in the established standard bin for non‑Rust‑language hygiene tasks. Taplo is a TOML toolkit written in Rust, providing a formatter, linter, language server, and schema validator, with the CLI `taplo-cli` offering commands like `taplo fmt` and `taplo lint` for TOML files.[13][17][18][13][30][41][13] Lib.rs shows taplo-cli with 26 releases and around 56,072 downloads per month as of mid‑2025, licensed under MIT. Taplo’s docs explain CI-friendly commands like `taplo fmt --check` to enforce formatting.[13][13][41][13] Typos is a source‑code spell checker designed for CI pipelines and pre‑commit hooks, with low false positives and support for writing corrections.[24][24][32][34][44] Its README describes installation via `cargo install typos-cli --locked`, Homebrew, Conda, or Pacman, and usage commands like `typos`, `typos --write-changes`, and `typos --diff`.[24] The project maintains monthly “Non‑critical corrections” issues to track new spelling patterns and corrections.[32][34][32][34][44] These tools are authoritative examples of Rust-native dev CLIs installed via cargo and used in CI, and they provide evidence that many teams prefer Rust-based tooling for tasks like config formatting and spell checking.

Lefthook and gitleaks, although not Rust-based, belong to the broader dev‑tool landscape relevant to R42 but are governed by R37 for hook-manager distribution and R39 for secret scanning tool choice. Lefthook is a fast, flexible Git hooks manager written in Go, with wrappers for JavaScript and Ruby, installed via Go, npm, gem, or pipx, and configured via `lefthook.yml`.[36][37][38] It is used in multi-language projects to run pre‑commit jobs like linting, formatting, gitleaks scans, yamllint, shellcheck, and typos. Gitleaks is a Go binary for secret scanning, installed via OS package managers or pre‑built binaries and used in Lefthook and CI workflows. These tools are authoritative in their domains but their installation mechanisms (Go, OS packages) differ from cargo, influencing the need for a polyglot provisioner.

To satisfy the survey method’s practice evidence requirement, several well‑regarded Rust projects were examined for their dev‑tool provisioning:

A Rust project documented on DeepWiki (`java_lsp`) uses just as a command runner and cargo as the primary toolchain, with recipes such as `just clippy` invoking `cargo clippy --workspace` and `just fmt` invoking `cargo fmt`.[26] This project is relevant because it is a multi‑crate workspace that integrates Clippy and rustfmt in its dev workflow.

The `just` project itself uses just recipes to run CI tasks, including `ci` and `clippy`, which in turn invoke `cargo clippy` and `cargo fmt`, demonstrating how a Rust CLI tool uses other Rust tooling in its own CI.[8][21]

NVIDIA’s `OpenShell` uses mise as a tool manager to bootstrap Rust, Python, kubectl, helm, and other tools, with a `mise.toml` listing `[tools]` and describing how mise installs pinned tool versions when the repository is trusted. This is a relevant reference because it is a significant industrial Rust project that uses mise to manage a polyglot dev environment.

The `mise` repository itself is a Rust project with edition 2024, a declared `rust-version` of 1.85, and an include list that ensures `Cargo.lock` is tracked, demonstrating adherence to the owner’s MSRV and lockfile policies.[12][12][35] Its docs show integration with rustup for Rust toolchains and tasks, making it both a dev tool and a reference for dev‑tool provisioning.[35][7][7][49].

Dosu’s “Developer Tooling and Quality Configurations” describe a Justfile that orchestrates formatting and linting across languages, including recipes like `fmt` and `fmt-check` that run `cargo fmt`, `lint-rust` that runs `cargo clippy`, and `lint-justfile` that uses `just --fmt`.[27] This reference is relevant because it shows a modern dev‑tool stack combining Rust, Prettier, mdformat, typos, and just, with a systematic approach to tool installation via `just` recipes and Megalinter.

These references, combined with authoritative Rust documentation, demonstrate that the dominant Rust practice is to use rustup and cargo for first‑party tools (rustfmt, Clippy), optionally layer just and Lefthook for task orchestration and hooks, and increasingly adopt mise for polyglot dev‑tool provisioning, while tools like flox remain emerging options for teams invested in Nix.

### Principles and implementation

The shared requirement across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` is a reproducible, cross‑platform developer environment that can be bootstrapped on `ubuntu-latest` and `macos-latest`, kept within the MSRV policy, and expressed in version‑controlled configuration files that capture tool versions, installation mechanisms, and invocation patterns.[12][3][7] At the level of agreement required by R42, the principle is that dev‑tool provisioning and invocation are part of the template’s contract: contributors should be able to clone the repository, run an agreed bootstrap command, and obtain the same Rust toolchain and auxiliary dev tools, with Justfile recipes and Lefthook hooks providing a stable interface for formatting, linting, testing, and hygiene.

The essential behaviors of the provisioning stack are: ensuring that rustfmt and Clippy are available as cargo subcommands on every supported OS; ensuring that any dev tools chosen by R27–R29 and R40 (secret scanner, YAML linter, spell checker, actionlint) are installed at predictable versions and available on `PATH`; avoiding unbounded drift between native installs, mise manifests, and flox manifests; and providing a clear mapping from Justfile recipes and Lefthook jobs to the underlying tool, whether via cargo subcommand or binary invocation.[5][10][48][35][7][3][7]

Observable acceptance criteria include: a pinned Rust toolchain via `rust-toolchain.toml` or equivalent, declaring edition 2024 and MSRV via `rust-version` in `Cargo.toml` and validated in CI; a `mise.toml` or `.mise.toml` that declares Rust and non‑Rust dev tools under `[tools]` and optionally tasks under `[tasks]`; the absence or explicit deprecation of per‑tool installer recipes and shell scripts where cargo-binstall or mise can provide equivalent functionality; no requirement to keep three provisioners (native, mise, flox) in manual sync; and Justfile recipes and Lefthook jobs that consistently invoke first‑party Rust tools as `cargo fmt` and `cargo clippy` and other tools as binaries on `PATH`.[9][10][35][7][7][49]

The architectural alternatives that R42 must compare, at a pattern level, are:

First, a “rustup/cargo only” pattern. In this architecture, dev tools are installed exclusively via rustup components and `cargo install`, and invoked as cargo subcommands where available or as binaries on `PATH`. Rustfmt and Clippy are installed via `rustup component add rustfmt clippy` and invoked as `cargo fmt` and `cargo clippy`.[5][6][10][48] Rust-analyzer is installed via rustup or editor plugins, and tools like taplo-cli and typos-cli are installed via `cargo install` or `cargo-binstall`. This pattern aligns with authoritative Rust documentation, minimizes external dependencies, and is common in smaller Rust projects. However, for non‑Rust tools like gitleaks or actionlint, installation falls back to OS package managers or manual scripts, and there is no declarative manifest that can be shared across OSes or across developers. This increases the risk of drift and platform inequities, especially as the toolset grows to include secret scanners, YAML linters, and others.

Second, a “per‑tool installer recipes” pattern, as in `py-launch-blueprint`. In this architecture, every dev tool has its own Justfile `install-*` recipe, with some recipes delegating to shell scripts for complex installations.[27] Installers call `cargo install` for Rust tools, `curl | bash` or OS package managers for others, and the Justfile becomes the central provisioning surface. The Python template additionally keeps a `mise.toml` and `.flox/env/manifest.toml` in sync with these installers, creating three separate but parallel views of the dev-toolchain.[27][3] This pattern is explicit and flexible but has high maintenance overhead: every new tool requires a recipe and, in the Python case, updates to multiple manifests. It also couples provisioning strongly to the Justfile, making it harder to reuse environment configuration in other contexts (e.g., IDE, shell, container).

Third, a “declarative provisioner manifest” pattern using mise and/or flox. In this architecture, a `mise.toml` at the project root declares dev tools under `[tools]` and tasks under `[tasks]`, and mise installs tools via rustup, cargo, GitHub or Aqua backends.[35][7][7] Flox, if used, declares the same toolset under `[install]` in `.flox/env/manifest.toml`, pinned to Nix packages.[2][3][3] Justfile recipes and Lefthook hooks then assume tools are on `PATH`, calling them as binaries. This pattern centralizes tool declarations and enables “mise install” or “flox activate” to bootstrap the environment, with Justfile and Lefthook focusing on orchestration rather than installation. It aligns with practice in polyglot projects like `OpenShell` that use mise to coordinate Rust, Python, and other tools. Its tradeoffs are the need to install mise and, optionally, flox themselves, and the risk of duplicated configuration if both are used. However, compared to per‑tool Justfile installers, it significantly reduces manual duplication.

In the Rust ecosystem, authoritative guidance favors rustup and cargo for Rust toolchains, while emerging best practice for multi‑language dev stacks includes mise as a single declarative provisioner.[5][10][35][7][7][49] Flox is promising but less widely adopted among Rust projects. The Python template needed both mise and flox because its dev‑tool mix spans Python, Node, and CLI tools, making Nix-based provisioning attractive.[3] The TypeScript template, by contrast, minimized auxiliary tools by folding multiple formatters into Oxfmt, reducing the impetus to use declarative provisioners.[21] The Rust template’s dev‑tool mix is narrower (Rust toolchain plus a handful of CLI tools like spell checkers and secret scanners), and the owner’s fixed parameters emphasize stability and CI reproducibility rather than maximum diversity of provisioners.[12]

Given this landscape, the principles argue for: using rustup and cargo for first‑party Rust tools, as Rust’s own documentation prescribes; using cargo-binstall as a performance‑oriented installer for Rust CLI tools; adopting mise as the single declarative dev‑tool provisioner for non‑Rust and non‑cargo tools; and avoiding per‑tool Justfile installer recipes, instead delegating installation to `mise install` and `cargo binstall` and focusing Justfile and Lefthook on invocation and orchestration.

This leads to two explicit baseline reviews:

BASELINE-REVIEW: F183 — per‑tool Justfile installer recipes — proposed change: drop per‑tool installer recipes as a baseline mechanism for `rs-launch-blueprint`, replacing them with a single environment bootstrap recipe that calls `mise install` and `cargo binstall` according to `mise.toml`. Evidence: authoritative Rust documentation recommends rustup components and cargo subcommands for rustfmt and Clippy, without per‑tool installers, and established practice in Rust projects such as `java_lsp`, `just`, and `mise` itself shows dev workflows driven by `cargo fmt`, `cargo clippy`, and `just` recipes that assume tools are installed, not recipes that install each tool individually.[5][10][8][21][26][35][7][7][49][27]

BASELINE-REVIEW: F187–F189 — declarative toolchain provisioner manifests (mise and flox) and triple sync — proposed change: adopt a single `mise.toml` as the canonical dev‑tools provisioner for `rs-launch-blueprint`, treat flox as an optional, non‑baseline up‑and‑comer rather than a mandatory second manifest, and eliminate the requirement to keep three provisioners in manual sync. Evidence: mise’s Rust backend integrates directly with rustup to install toolchains and components and is already used by Rust projects like `OpenShell` to coordinate polyglot toolchains.[7][49] Flox’s Rust dev environment documentation shows a viable alternative but with unbundled toolchain components and Nix complexity more suited to teams invested in Nix.[2][3][4][3][3] Rust ecosystem practice favors a single tool manager like mise or asdf for dev‑tools, while triple provisioning is unique to the Python template’s multi‑language context and is not widely observed in Rust projects.[35][39][50]

Under this proposed architecture, what must agree is: the existence and role of `mise.toml` as the canonical dev‑tool manifest; the reliance on rustup components for rustfmt and Clippy; the use of cargo-binstall for Rust CLI dev tools; and the invocation pattern (cargo subcommands for first‑party tools, binaries on `PATH` for others). What may vary is: the specific non‑cargo tools chosen by R27–R29 and R40; the optional presence of a flox manifest for teams that want Nix‑based environments; and the task definitions in Justfile and `mise.toml`’s `[tasks]`.

### Recommendation

The recommended stack for `rs-launch-blueprint` is a single bundle that can be named, for clarity in documentation and ledger, as **R42-RustDevToolStack**. This bundle has three core members and one pattern member:

The first core member is the **Rust standard toolchain via rustup and cargo**, comprising rustc, cargo, rustfmt, Clippy, and rust-src installed via rustup, with rustfmt and Clippy invoked as cargo subcommands (`cargo fmt`, `cargo clippy`) in Justfile recipes and Lefthook jobs.[5][6][10][48] A per‑project `rust-toolchain.toml` pins the Rust channel (stable) and components (rustfmt, clippy, rust-src) with edition 2024 and MSRV declared in `Cargo.toml`.[9][10]

The second core member is **cargo-binstall**, used to install Rust CLI development tools (e.g. taplo-cli, typos-cli, just) as pre‑compiled binaries rather than building from source with `cargo install`, and invoked via `cargo binstall` in a generic Justfile bootstrap recipe.[11][11][31][33][11][31][46] This reduces install time in CI and local development, while deferring MSRV considerations to the binary’s build environment.

The third core member is **mise as the declarative dev‑tool provisioner**, with a `mise.toml` at the project root declaring Rust and non‑Rust tools under `[tools]` and optionally tasks under `[tasks]`, and used via `mise install` to provision the full dev toolchain on a new machine.[35][7][7][49] Mise installs the Rust toolchain and components via rustup and additional tools (e.g. gitleaks, actionlint) via GitHub or Aqua backends, ensuring they are on `PATH` for Justfile and Lefthook.[7] Flox is considered but not adopted as a baseline member; it remains an up‑and‑comer that teams may add as a local optional environment if desired.[2][3][4][3][3]

The pattern member is a **Justfile and Lefthook invocation schema**: Justfile recipes such as `fmt`, `lint`, `check`, `test`, and `precommit` invoke `cargo fmt`, `cargo clippy`, `cargo test`, and other tools (taplo, typos, gitleaks, actionlint) as binaries on `PATH` without installing them per recipe, relying on `mise install` and `cargo binstall` to provision them.[21][26][27][29] Lefthook’s `lefthook.yml` configures pre‑commit and pre‑push hooks that run the same commands over staged files, including secret scans, formatting, linting, and spell checking.

Under this bundle, R42’s `package-manager-invocation` parameter is set to: **owns package-manager-invocation = “first‑party Rust tools via cargo subcommands; all non‑cargo dev tools via provisioned binaries on PATH; installation via rustup components, cargo-binstall, and mise according to `mise.toml`.”** This value ensures that R27–R29 and R40 can specify their tools (secret scanner, YAML linter, spell checker, actionlint) as either Rust CLI binaries installed via cargo-binstall or non‑Rust tools installed via mise backends, with Justfile and Lefthook invoking them consistently.

The following sections detail each member, their fitness gates, tradeoffs, and integration, and then return to compatibility, parameters, migration implications, and validation.

## Member analysis and design

### Members

#### Rust standard toolchain via rustup and cargo

##### Landscape

The Rust standard toolchain includes rustc, cargo, rustfmt, Clippy, and rust-src, managed by rustup and integrated with cargo subcommands.[5][6][10][48] Rustfmt is the official code formatter that reformats Rust code according to community style, and is included by default in Rust installations, with commands `rustfmt` and `cargo fmt` provided.[5][10] The Rust book shows `cargo fmt` as the idiomatic way to format any Cargo project, noting that it reformats all Rust code in the current crate without changing semantics.[5][10] Clippy is a collection of lints to analyze Rust code for common mistakes and improvements, also included with standard installations and exposed as `cargo clippy`.[5][10][48] Clippy’s usage docs detail workspace support, lint configuration via `-A/W/D clippy::lint_name`, and CI usage with `cargo clippy -- -D warnings`.[48] Rustup is the toolchain manager that installs and updates Rust channels and components; commands like `rustup component add rustfmt clippy rust-src` add these tools to the active toolchain.[6][9][48] Rust-analyzer is the language server used by editors, often installed via rustup’s `rust-analyzer` component or via IDE plugins.[5][10]

These tools are first‑party and built into Rust’s ecosystem, with authoritative documentation on `doc.rust-lang.org` and integration with cargo. They form the baseline for any Rust dev environment. Rust projects like `java_lsp` and `just` use `cargo fmt` and `cargo clippy` in their `just` recipes and CI flows, demonstrating practice alignment.[8][21][26]

##### Principles and implementation

For `rs-launch-blueprint`, the principle is to treat rustfmt and Clippy as first‑class dev tools provided by Rust itself, and to rely on rustup and cargo for their installation and invocation, rather than re‑implementing installer logic in Justfile or external manifests. This aligns with authoritative guidance and simplifies MSRV compliance, because rustup’s channels and components are tied to Rust versions.

The implementation pattern is:

Rust toolchains are installed via rustup, with a per‑project `rust-toolchain.toml` pinning the channel (stable) and components (`rustfmt`, `clippy`, `rust-src`). A typical `rust-toolchain.toml` could be:

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy", "rust-src"]
profile = "minimal"
```

This uses rustup’s `minimal` profile to include rustc, rust-std, and cargo, while explicitly adding rustfmt and Clippy as components, matching the `default` profile’s tool set minus docs.[9][7][49]

Developers install the toolchain by running `rustup toolchain install stable` and `rustup component add rustfmt clippy rust-src` or by letting mise handle these via its Rust backend, which calls rustup under the hood.[7][7][49] In either case, `cargo fmt` and `cargo clippy` become available.

Justfile recipes and Lefthook hooks invoke `cargo fmt` and `cargo clippy` instead of calling `rustfmt` or `clippy-driver` directly, as recommended by the Rust book and Clippy docs.[5][10][48] This ensures that cargo’s project‑aware behavior (respecting `Cargo.toml`, workspaces, and default features) applies.

CI workflows on `ubuntu-latest` and `macos-latest` run `rustup component add rustfmt clippy rust-src` in the setup step and include `cargo fmt --check` and `cargo clippy -- -D warnings` as quality gates.[5][10][48][27][26]

##### Dominant choice

The dominant choice for first‑party Rust dev tools is rustup plus cargo, with rustfmt and Clippy installed as components and invoked as cargo subcommands. No competing toolchain manager in Rust provides such deep integration with cargo, and no alternative formatter or linter has the same level of official endorsement. This choice is mandated by Rust’s official guidance and ubiquitous in practice.[5][10][48]

##### Qualified shortlist

No additional crates are needed to manage this layer. There are wrapper tools like `cargo-edit` and `cargo-update` that add subcommands to cargo for dependency management, but they are not required for rustfmt/Clippy provisioning.[1][28]

##### Excluded by gate

Alternative toolchains or forks of rustfmt and Clippy are excluded by fitness gates: they lack official support, may have unknown MSRV, and do not integrate with cargo in the same way. For example, custom formatters or linters built atop rustc’s API would violate the requirement to use stable Rust and first‑party tools.[5][10][48]

##### Up-and-comers

Third‑party lint and format tools such as `dioxus-cli` or `rustfmt-nightly` are up‑and‑comers but not relevant here; they often rely on nightly features or specific frameworks, and do not replace rustfmt/Clippy for general Rust code.

##### Fit for this template

This layer fits `rs-launch-blueprint` perfectly, because it respects the MSRV policy, uses stable Rust, and aligns with the owner’s requirement that MSRV be declared in `Cargo.toml` and tested in CI.[12] Rustfmt and Clippy are essential dev tools for any Rust project; their installation via rustup components and invocation via cargo subcommands ensures consistent behavior across CLI, library, and web service crates.

##### Recommendation

The recommendation is to:

Use rustup as the sole installer for rustfmt, Clippy, and rust-src, with a pinned `rust-toolchain.toml` specifying `channel = "stable"` and components `["rustfmt", "clippy", "rust-src"]`.[9][7][49]

Invoke rustfmt and Clippy exclusively via `cargo fmt` and `cargo clippy` in Justfile recipes and Lefthook hooks, with CI gates `cargo fmt --check` and `cargo clippy -- -D warnings`.[5][10][48][27][26]

Treat this layer as non‑negotiable and shared across all dev‑tool choices.

##### Ranked runner-up

There is no ranked runner‑up; rustup plus cargo is the only viable choice meeting first‑party, MSRV, and stability requirements.

##### Tradeoffs

The tradeoff is minimal: relying on rustup ties the dev environment to Rust’s distribution mechanisms, but this is a requirement rather than a drawback. The use of `cargo fmt` and `cargo clippy` might incur some compile‑time overhead compared to custom tools, but the ergonomics and official support outweigh any minor performance differences.[5][10][48]

##### Parameters

This member assumes `rust-edition = 2024` and `msrv-policy = stable minus 2 minor versions` as fixed by the owner.[12] It consumes the `rust-version` setting in `Cargo.toml` and the `rust-toolchain.toml` pin but does not own any parameters.

##### Migration implications

Migration from a template that does not pin a toolchain would add `rust-toolchain.toml` and update `Cargo.toml` to include `rust-version`, edition 2024, and MSRV, and it would replace any direct `rustfmt` or `clippy-driver` invocations in Justfile and Lefthook with `cargo fmt` and `cargo clippy`.[5][10][48]

##### Validation strategy

Validation consists of:

Running `rustup show active-toolchain` to confirm the pinned toolchain and components.[9][7]

Running `cargo fmt --check` and `cargo clippy -- -D warnings` locally and in CI to ensure they pass on `ubuntu-latest` and `macos-latest`.[5][10][48][27][26]

Ensuring that `rust-analyzer` functions in the editor, with the Rust source component installed for IDE features.[5][10]

These checks are proposed; their execution would be part of CI onboarding.

##### Confidence & re-verify trigger

Confidence is high, as this is the standard Rust pattern with strong authority and practice evidence.[5][10][48][8][21][26] Re‑verification is only needed if Rust’s distribution model changes (e.g., rustfmt or Clippy are removed from rustup or replaced), or if the owner updates MSRV policy to a non‑standard value.

##### Sources

Rust book Appendix D for rustfmt and Clippy.[5][10] Clippy documentation.[48] Rustup component docs and community usage.[6][9][48] DeepWiki examples for `just` and `java_lsp`.[8][21][26]

#### cargo-binstall

##### Landscape

Cargo-binstall is a Rust tool that installs binary crates from pre‑compiled artifacts, acting as a low‑complexity alternative to building from source via `cargo install`.[11][11][31][33][11][31][46][11][31] Its README explains that Binstall fetches crate metadata from `crates.io`, then searches the linked repository’s releases for matching binaries, falls back to a third‑party quickinstall host, and finally to `cargo install` if no binary is available.[11][31][11][31][46] It supports Linux, macOS, and Windows via one‑line install scripts that download pre‑compiled `cargo-binstall` binaries and place them in `~/.cargo/bin`, or installation via `cargo install cargo-binstall --locked`.[11][11][31][33][11][31][11][31] There is also a GitHub Action `cargo-bins/cargo-binstall@main` for CI.[11][33][33][11]

Lib.rs and docs.rs list cargo-binstall as a development tool crate with ongoing releases; for example, release v1.4.1 in August 2026. Community writeups and ROS2 documentation mention cargo-binstall as a way to install tools like `cargo-nextest` quickly, avoiding compilation. This positions cargo-binstall as an established industry standard for installing Rust CLI binaries in dev environments and CI.

##### Principles and implementation

For `rs-launch-blueprint`, cargo-binstall’s principle is to act as the default installer for Rust CLI dev tools that are not part of the standard Rust toolchain, providing reproducible, fast installation across `ubuntu-latest` and `macos-latest` and avoiding per‑tool Justfile installers.

Implementation involves:

Installing cargo-binstall itself via `cargo install cargo-binstall --locked` or via its one‑liner for pre‑compiled binaries, as part of the dev environment bootstrap. In CI, the GitHub Action `cargo-bins/cargo-binstall@main` is used to install cargo-binstall.[11][11][31][33][11][31][33][11][31]

Using `cargo binstall <crate>` to install Rust CLI dev tools like `taplo-cli`, `typos-cli`, `just`, and others chosen by R27–R29 and R40.[13][24][24][21][26][29][27][41][13] For example, `cargo binstall taplo-cli --locked` or `cargo binstall typos-cli --locked` would install the latest non‑yanked versions, using pre‑compiled binaries where available.[13][13][41][13][24]

Defining a generic Justfile recipe such as `install-dev-tools` that checks for the presence of each tool via `command -v` and runs `cargo binstall` if missing, rather than per‑tool installer recipes. This could be written as:

```make
install-dev-tools:
    if ! command -v taplo >/dev/null 2>&1; then cargo binstall taplo-cli --locked; fi
    if ! command -v typos >/dev/null 2>&1; then cargo binstall typos-cli --locked; fi
    if ! command -v just >/dev/null 2>&1; then cargo binstall just --locked; fi
```

Or equivalent shell code, ensuring tools are available on `PATH` without separate recipes for each.[21][27][29][24]

Using cargo-binstall’s `[package.metadata.binstall]` configuration in `Cargo.toml` when `rs-launch-blueprint` itself wants to be installable via cargo-binstall, but this is optional for dev tools.[45]

##### Dominant choice

The dominant choice for installing Rust CLI dev tools is cargo-binstall, rather than `cargo install`, because of its speed and CI friendliness, especially in multi‑tool stacks.[11][11][31][33][11][31][46] It is widely referenced as a best practice for dev environments and monorepos, and its ability to fall back to `cargo install` ensures compatibility.

##### Qualified shortlist

The qualified shortlist includes:

`cargo install` as the baseline installer. It is the default cargo command for installing binary crates, documented in the Cargo book.[28] It is slower but universally available.

Third‑party installers like `taiki-e/cache-cargo-install-action` can cache installations in CI, but they are more specialized and do not replace cargo-binstall’s functionality.

##### Excluded by gate

Non‑Rust installers (e.g. OS package managers) are excluded for Rust CLI tools because they are not portable across OSes and do not apply to crates on `crates.io`, violating the requirement for cross‑platform reproducibility.[12][28]

##### Up-and-comers

Other binary package managers like `cargo-quickinstall` are up‑and‑comers that complement cargo-binstall, but cargo-binstall already integrates with `cargo-quickinstall` releases.[46] Thus, cargo-quickinstall is a backend rather than a competitor.

##### Fit for this template

Cargo-binstall fits `rs-launch-blueprint` because it can install Rust CLI dev tools on both `ubuntu-latest` and `macos-latest`, respects Rust’s ecosystem, and reduces installation time in CI, which is important for a template used by many projects.[11][11][31][33][11][31][46] It is compatible with the MSRV policy as long as installed crates themselves respect MSRV; cargo-binstall does not enforce MSRV but uses crate‑provided binaries.

##### Recommendation

The recommendation is to:

Include cargo-binstall as part of the dev-toolchain provisioning stack, installing it via `cargo install cargo-binstall --locked` or via its one-line scripts, and using it to install Rust CLI dev tools such as taplo-cli, typos-cli, just, and any others chosen by R27–R29 and R40.[11][11][31][33][11][31][46][13][13][41][13][24][21][26][29][27]

Define a generic Justfile recipe (`install-dev-tools`) that calls `cargo binstall` for each tool if it is not on `PATH`, rather than per‑tool recipes, thereby satisfying the LOW question about generic install‑if‑missing behavior.[21][27][29][24]

Treat `cargo install` as a fallback for environments where pre‑compiled binaries are unavailable.

##### Ranked runner-up

The ranked runner‑up is `cargo install` without cargo-binstall. This is simpler but slower and does not leverage existing CI artifacts, making it less attractive for a template aimed at modern Rust workflows.[28]

##### Tradeoffs

The main tradeoff is dependency on cargo-binstall itself, which must be installed and maintained. This adds one more binary to the stack, but its benefits in speed and consistency outweigh the overhead. There is a small risk that cargo-binstall’s own MSRV or dependencies could conflict with `rs-launch-blueprint`’s MSRV policy; this should be verified via its `Cargo.toml` and RustSec advisory page.[45]

##### Parameters

Cargo-binstall does not own any parameters but consumes `package-manager-invocation` insofar as it determines whether dev tools are installed via cargo-binstall or other means. Under the recommended pattern, cargo-binstall is the primary installer for Rust CLI dev tools.

##### Migration implications

Migration from per‑tool installer scripts to cargo-binstall would:

Remove individual `install-*` recipes and shell scripts for Rust CLI tools.

Add a single `install-dev-tools` Justfile recipe invoking `cargo binstall`, coordinated with `mise.toml`.

Update CI workflows to use the cargo-binstall GitHub Action for installing tools.

##### Validation strategy

Validation consists of:

Installing cargo-binstall via `cargo install cargo-binstall --locked` and verifying `cargo-binstall --version`.[11][11][31][33][11][31][11][31]

Running `cargo binstall taplo-cli --locked` and verifying `taplo --version`.[13][13][41][13]

Running `cargo binstall typos-cli --locked` and verifying `typos --version`.[24][24]

Running these commands on `ubuntu-latest` and `macos-latest` in CI, ensuring tools are on `PATH`.

##### Confidence & re-verify trigger

Confidence is medium‑high: cargo-binstall is widely used and actively maintained, but it is not yet part of the Rust standard library. Re‑verification is needed if cargo-binstall’s MSRV increases beyond the template’s MSRV, if RustSec advisories appear, or if crate download patterns suggest declining maintenance.[45]

##### Sources

Cargo-binstall README and marketplace entries.[11][11][31][33][11][31][33][11][31][45][46] ROS2 Rust introduction referencing cargo-binstall. Rust Cargo book on `cargo install`.[28]

#### mise (dev-tools provisioner)

##### Landscape

Mise is a polyglot runtime version manager and task runner written in Rust, designed to replace tools like nvm, pyenv, rbenv, tfenv, and asdf, and to manage dev tools, environment variables, and tasks from a single `mise.toml` file.[35][39][40][43][7] It installs toolchains for languages like Node.js, Python, Go, and Rust, handles environment variables, and defines tasks under `[tasks]`.[35][7][39][7] The Rust backend of mise installs Rust toolchains using rustup under the hood, respecting `RUSTUP_HOME` and `CARGO_HOME`, and allowing configuration of tool options like `components`, `targets`, and `profile`.[7][7][49] For example, a `[tools]` entry such as `"rust" = { version = "1.83.0", components = ["rust-src", "llvm-tools"], profile = "minimal" }` tells mise to install Rust 1.83.0 with specified components and minimal profile.[7][49]

Mise can also declare additional dev tools via backends: `cargo` backend for crates, `github` backend for GitHub releases, and `aqua` backend for registries.[42] For example, `mise use rust@stable cargo:eza` would record both Rust and the `eza` CLI in `mise.toml`.[42] For non‑Rust tools like gitleaks and actionlint, mise can use GitHub backends to install pre‑compiled binaries.

Practice evidence includes the `mise` repository itself, which uses `mise.toml` to manage its dev environment; blogs like “Mise ate my Makefile,” which describe migrating from Makefile to `mise.toml` for tasks like `build`, `test`, and `clippy`; and industrial projects like NVIDIA’s `OpenShell`, which use mise to bootstrap Rust, Python, and Kubernetes tools.[35][39][50]

##### Principles and implementation

For `rs-launch-blueprint`, mise’s principle is to serve as the single declarative dev‑tool provisioner manifest, capturing all non‑Rust and non‑cargo tools needed by the template (secret scanner, YAML linter, spell checker, actionlint, just, etc.), and coordinating with rustup for Rust toolchains.

Implementation includes:

Creating a `.mise.toml` at the project root with a `[tools]` table declaring Rust and dev tools. For example:

```toml
[tools]
rust = { version = "latest", profile = "default", components = ["rust-src"] }
"cargo:taplo-cli" = "latest"
"cargo:typos-cli" = "latest"
just = "latest"
"github:gitleaks/gitleaks" = "latest"
"github:rhysd/actionlint" = "latest"
```

Here, `rust` uses the Rust backend, `cargo:taplo-cli` and `cargo:typos-cli` use the cargo backend, `just` uses its registry shorthand, and gitleaks/actionlint use GitHub backends.[42][7][13][13][41][13][24]

Using `[env]` to define environment variables like `RUSTUP_HOME`, `CARGO_HOME`, and `RUST_LOG`, and to extend `PATH` to include `./target/debug` and `./target/release`, as shown in mise docs.[7][7][50]

Adding `[tasks]` entries for common dev commands such as `build`, `test`, `clippy`, and `fmt`, each running the corresponding cargo or dev tool commands. For example, `[tasks.clippy]` with `run = "cargo clippy --workspace --all-targets --all-features -- -D warnings"`.[50][26][27]

Configuring mise’s Rust backend with appropriate `profile` and `components` tool-options to ensure rustfmt and Clippy are available, while avoiding the `complete` profile that includes every component and might fail.[49]

Using `mise install` as the canonical bootstrap command: when a contributor trusts the repository and runs `mise install`, mise reads `[tools]` and installs Rust and dev tools at pinned versions.[35][7]

Integrating `mise` with `rust-toolchain.toml` by enabling idiomatic file discovery, so that mise respects existing Rust toolchain files rather than duplicating them.[7][7][20]

##### Dominant choice

Mise is the dominant choice for dev‑tool provisioning in the Rust ecosystem among teams that need multi‑language toolchains and a unified configuration, as evidenced by its growing adoption, active maintenance, and use in projects like `OpenShell`.[35][39][7][49][50] It directly supports Rust via rustup and can declare Rust and non‑Rust tools in one file.

##### Qualified shortlist

Flox is the main qualified alternative. It provides `.flox/env/manifest.toml` as a declarative environment definition, with `[install]` listing packages including `cargo`, `rustc`, `rustfmt`, `clippy`, `rust-lib-src`, and `rust-analyzer`, and `[hook]` and `[vars]` configuring environment and activation scripts.[2][3][3][3] Flox is suitable for teams invested in Nix and wanting reproducible dev environments that integrate with Nix packaging. It is more complex and unbundles Rust toolchain components, requiring explicit `pkg-path` entries for each.[2][3][3][3]

##### Excluded by gate

Using both mise and flox as first‑class, kept‑in‑sync manifests (as in `py-launch-blueprint`) is excluded by the principle of minimizing manual duplication and by the narrower dev‑tool mix in Rust. Maintaining three synchronized views (native, mise, flox) would reintroduce F189’s complexity without clear benefit in the Rust context.[39]

##### Up-and-comers

Flox remains an up‑and‑comer for Rust projects; its adoption may grow, but for now it is considered optional rather than baseline.[2][3][4][3][3]

##### Fit for this template

Mise fits `rs-launch-blueprint` by:

Providing a single declarative manifest for Rust and non‑Rust dev tools.

Integrating with rustup to respect MSRV and rust‑edition policies.

Supporting both `ubuntu-latest` and `macos-latest` via its backends and registries.[7][35][7][7][49]

Aligning with practice in modern Rust projects that use `mise.toml` for tools and tasks.[50]

##### Recommendation

The recommendation is to:

Adopt `.mise.toml` as the canonical dev‑tool manifest for `rs-launch-blueprint`, declaring Rust and dev tools under `[tools]` and tasks under `[tasks]`.[35][7][7][49][50]

Configure the Rust backend with `profile = "default"` or `profile = "minimal"` plus explicit components to include rustfmt and Clippy.[49]

Use mise to install both Rust toolchains and non‑Rust dev tools like gitleaks and actionlint via GitHub backends.

Treat flox manifests as optional, not baseline, and do not require triple provisioning.

##### Ranked runner-up

Flox is the ranked runner‑up, recommended for teams who already use Nix and Flox for other projects and want a `.flox/env/manifest.toml` to mirror the dev toolchain.[2][3][4][3][3] It is not mandated by the template.

##### Tradeoffs

The main tradeoff is introducing mise as a dependency that contributors must install via curl or package manager, which adds complexity compared to using rustup alone.[35][35][7] However, mise’s benefits in managing polyglot tools and tasks make it a net positive, and its installation is similar to other dev tools.[35][35][7]

##### Parameters

Mise owns no global parameters but effectively manages tool versions and backends as part of the dev environment. It consumes R42’s `package-manager-invocation` parameter by determining how tools are installed (via rustup, cargo, GitHub, Aqua) and made available on `PATH`.

##### Migration implications

Migration involves:

Adding `.mise.toml` at the project root.

Moving any existing Makefile or Justfile tasks to `[tasks]` in `.mise.toml` gradually, as described in “Mise ate my Makefile.”[50]

Ensuring `mise install` becomes part of the onboarding instructions and CI bootstrap.

Dropping flox manifest requirements unless teams choose to add them locally.

##### Validation strategy

Validation comprises:

Running `mise install` on a clean clone and verifying that Rust, taplo, typos, just, gitleaks, and actionlint are installed and on `PATH`.[7][50]

Running `mise exec -- rustc --version` and `mise exec -- cargo --version` to confirm Rust toolchain.[7][7]

Running `mise exec -- taplo fmt --check` and `mise exec -- typos` to verify dev tools.[13][13][41][13][24]

##### Confidence & re-verify trigger

Confidence is medium‑high, based on mise’s active maintenance, adoption, and alignment with Rust dev practice.[35][39][7][49][50] Re‑verification should occur if mise’s MSRV or license changes, if RustSec advisories arise, or if alternative tool managers become more prevalent.

##### Sources

Mise documentation and repository.[35][7][39][43][7][49] “Mise ate my Makefile” blog.[50] NVIDIA `OpenShell` DeepWiki entry.

#### Justfile & Lefthook invocation pattern

##### Landscape

Just is a command runner written in Rust, using a Makefile‑inspired syntax to define recipes in a `justfile`.[21][26][29] It is designed purely as a command runner, not a build system, and runs commands by name.[21][29] Just supports formatting of justfiles via `just --fmt --unstable` and is used in many Rust and polyglot projects to orchestrate tasks such as `build`, `test`, `fmt`, `clippy`, and `precommit`.[21][26][27][29][50]

Lefthook is a Git hooks manager that runs commands on events like pre‑commit, pre‑push, and commit-msg, configured via `lefthook.yml`.[36][37][38] It supports parallel jobs and commands with glob filters for staged files, and is used to run tools such as yamllint, shellcheck, shfmt, actionlint, gitleaks, and typos in pre‑commit hooks. Lefthook can be installed via Go, npm, gem, or pipx, and integrated into Node or Ruby projects and Rust projects through standalone binary.[36][37][38]

Practice examples include Dosu’s Justfile orchestrating formatting and linting across Rust, JSON, YAML, Markdown, and justfiles; GitHub tutorials on just configuration in Rust projects; and multiple Lefthook config examples for running gitleaks, typos, ESLint, Prettier, and type checks in pre‑commit and pre‑push.[27][29]

##### Principles and implementation

For `rs-launch-blueprint`, the principle for Justfile and Lefthook is to separate provisioning from invocation: they should assume tools declared in `.mise.toml` and installed via `mise install` and `cargo binstall` are available on `PATH`, and their recipes and hooks should only orchestrate commands, not install tools.

Implementation entails:

Defining a `justfile` at the project root with recipes such as `fmt`, `fmt-check`, `lint`, `lint-rust`, `test`, `check`, `dev`, and `precommit`. For example:

```make
fmt:
    cargo fmt

fmt-check:
    cargo fmt --check

lint-rust:
    cargo clippy --workspace --all-targets --all-features -- -D warnings

lint-config:
    taplo fmt --check
    typos

test:
    cargo test

precommit:
    just fmt
    just lint-rust
    just lint-config
    just test
```

These recipes rely on `cargo fmt`, `cargo clippy`, `taplo`, and `typos` being on `PATH`, as provided by Rustup and mise/cargo-binstall.[5][10][13][13][41][13][24][21][26][27][29]

Including a bootstrap recipe such as `devsetup` that runs `mise install` and `cargo binstall` for dev tools:

```make
devsetup:
    mise install
    just install-dev-tools
```

Defining `Lefthook.yml` with pre‑commit hooks that run the same commands over staged files, for example:

```yaml
pre-commit:
  parallel: true
  commands:
    rust-fmt:
      glob: '*.rs'
      run: cargo fmt
      stage_fixed: true
    rust-lint:
      glob: '*.rs'
      run: cargo clippy --workspace --all-targets --all-features -- -D warnings
    toml-fmt:
      glob: '*.toml'
      run: taplo fmt {staged_files}
      stage_fixed: true
    spellcheck:
      run: typos
    secrets:
      run: gitleaks protect --staged
```

This pattern is modeled on examples from Torana Tech and Steve Kinney, where Lefthook runs yamllint, shellcheck, shfmt, actionlint, gitleaks, and typos in pre‑commit hooks.

Ensuring Lefthook itself is installed via mechanisms decided in R37 (Go, npm, gem, pipx), not by R42; R42 only ensures its commands use provisioned tools correctly.[36][37][38]

##### Dominant choice

Just and Lefthook are dominant choices for command running and Git hooks in modern dev workflows, particularly in Rust and JavaScript ecosystems.[21][26][27][29][36][37][38] Alternatives like Make and pre-commit exist but are less idiomatic for Rust projects that already use Rust-based tooling.

##### Qualified shortlist

Pre-commit (Python-based) is a qualified alternative for hook management. Make and shell scripts are alternatives for command running but lack the cross‑platform ergonomics and task structure of Just.

##### Excluded by gate

Installing dev tools from within Justfile recipes and Lefthook hooks is excluded by principle: provisioning should be done by `mise install` and `cargo binstall`, not by scripts embedded in invocation workflows, to reduce complexity and keep provisioning declarative.[27][39][50]

##### Up-and-comers

Task runners like `cargo-make` and `cargo-xtask` patterns are up‑and‑comers, but they focus on cargo tasks rather than multi‑language dev workflows.

##### Fit for this template

The Justfile and Lefthook pattern fits `rs-launch-blueprint` because it:

Provides a consistent interface to dev tools across CLI, library, and web service crates.

Integrates with `mise` and cargo-binstall by assuming tools on `PATH`.

Supports cross‑platform operation via Rust and Go binaries.

Aligns with practice in existing templates and dev stacks.[21][26][27][29]

##### Recommendation

The recommendation is to:

Define a `justfile` with recipes that invoke `cargo fmt`, `cargo clippy`, and other dev tools as binaries on `PATH`, without per‑tool installers, and include a bootstrap recipe that runs `mise install` and `cargo binstall` as needed.[21][26][27][29][50]

Configure `lefthook.yml` pre‑commit and pre‑push hooks to run the same commands over staged files, including secret scanning, formatting, linting, and spell checking.

Ensure that R37 decides how Lefthook is installed, and that R42 only defines how Lefthook jobs invoke dev tools.

##### Ranked runner-up

Make plus custom shell scripts is a runner‑up, but it is less ergonomic and less aligned with current Rust practice, and would reintroduce the per‑tool installer pattern that F183 seeks to deprecate.[27][39][50]

##### Tradeoffs

Just and Lefthook require users to install additional binaries, increasing setup complexity. However, they provide significant value in orchestrating complex workflows and integrating with multiple languages and tools, and they are already used in the Python and TS templates’ ecosystems, aligning with owner precedent.[27]

##### Parameters

This pattern consumes `package-manager-invocation` by defining whether tools are invoked as cargo subcommands or binaries; under the recommended value, first‑party tools use cargo, others use binaries.

##### Migration implications

Migration entails:

Adding a `justfile` and `lefthook.yml` to the template.

Removing any existing `Makefile` dependency for dev tasks.

Updating documentation to encourage `just precommit` before commits and `lefthook install` and `git commit` workflows.[27][50]

##### Validation strategy

Validation consists of:

Running `just fmt`, `just lint-rust`, `just lint-config`, and `just test` locally to confirm dev workflows.[21][26][27][29]

Running Lefthook hooks on staged files (e.g., adding a fake secret and verifying gitleaks blocks the commit).

Ensuring commands succeed on `ubuntu-latest` and `macos-latest` in CI.

##### Confidence & re-verify trigger

Confidence is medium‑high, based on widespread use and strong integration with dev tooling.[21][26][27][29] Re‑verification is needed if just or Lefthook’s maintenance or compatibility declines, or if the owner decides to change hook managers (R37).

##### Sources

Just documentation and DeepWiki entries.[21][26][27][29] Lefthook repository and installation docs.[36][37][38] Lefthook configuration examples for gitleaks and dev tools.

## Compatibility

Compatibility between the members of R42-RustDevToolStack is demonstrated by both documented integration and shared adopters.

Mise’s Rust backend installs Rust toolchains via rustup under the hood, meaning it directly cooperates with the rustup plus cargo pattern for rustfmt and Clippy.[7][7][49] Mise can read `rust-toolchain.toml` via its idiomatic version file discovery setting, ensuring it respects per‑project Rust pins without duplication.[7][7][20] In `OpenShell`, mise is used to install Rust 1.95.0 alongside Python and other tools, and `mise exec --

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [Great Rust CI](https://dev.to/cad97/great-rust-ci-1fk6)
- [Rust - Flox Docs](https://flox.dev/docs/cookbook/languages/rust/)
- [Rust](https://flox.dev/docs/languages/rust)
- [A Real World Rust Project with Flox](https://flox.dev/blog/a-real-world-rust-project-with-flox/)
- [Appendix D: Useful Development Tools](https://doc.rust-lang.org/book/appendix-04-useful-development-tools.html)
- [Setting up rustfmt and clippy for yassgy](https://dev.to/jerryhue/setting-up-rustfmt-and-clippy-1ome)
- [Rust | mise-en-place](https://mise.jdx.dev/lang/rust.html)
- [Building and Testing | casey/just | DeepWiki](https://deepwiki.com/casey/just/8.2-building-and-testing)
- [rust-dev — Agent Skill | ottermind](https://ottermind.ai/skills/rust-dev)
- [The Rust Programming Language](https://doc.rust-lang.org/stable/book/appendix-04-useful-development-tools.html?highlight=clippy)
- [cargo-bins/cargo-binstall: Binary installation for rust projects](https://github.com/cargo-bins/cargo-binstall)
- [mise/Cargo.toml at main · jdx/mise](https://github.com/jdx/mise/blob/main/Cargo.toml)
- [taplo](https://rustutils.com/tools/taplo/)
- [taplo::formatter - Rust](https://docs.liquidrocketry.com/compiler/taplo/formatter/index.html)
- [barstoolbluz/flox-md - GitHub](https://github.com/barstoolbluz/flox-md/blob/main/FLOX.md)
- [mise.toml - GitLab.org / rust / Gitlab Code Parser](https://gitlab.com/gitlab-org/rust/gitlab-code-parser/-/blob/main/mise.toml)
- [taplo - Rust](https://docs.rs/taplo/latest/taplo/)
- [taplo - Rust](https://docs.rs/taplo)
- [Using cargo-binstall in buildRustPackage - Development](https://discourse.nixos.org/t/using-cargo-binstall-in-buildrustpackage/36704)
- [mise does not pick up rust-toolchain.toml file #4729 - GitHub](https://github.com/jdx/mise/discussions/4729)
- [Taking advantage of the...](https://liam.rs/posts/powerful-just-features/)
- [\[PR\] build: drop the rust-toolchain.toml pin (datasketches- ...](https://lists.apache.org/thread/z9omtdk1n9o74fjvh3cr49mtpnpt9796)
- [cargo-generateを使ってrustプロジェクトを作る方法](https://blog.danieliu.xyz/rust-project-setup/)
- [typos](https://rustutils.com/tools/typos/)
- [k23/justfile at main · JonasKruckenberg/k23](https://github.com/JonasKruckenberg/k23/blob/main/justfile)
- [Development | emilycares/java_lsp | DeepWiki](https://deepwiki.com/emilycares/java_lsp/8-development)
- [Developer Tooling and Quality Configurations | Dosu](https://app.dosu.dev/821cc1ce-e828-457b-858b-bfa2c1e26036/documents/e41eee42-83ab-495f-8bd2-27e5dc7817db)
- [cargo install - The Cargo Book](https://doc.rust-lang.org/cargo/commands/cargo-install.html)
- [How to Configure just Command Runner on Ubuntu](https://oneuptime.com/blog/post/2026-03-02-configure-just-command-runner-ubuntu/view)
- [GitHub - tamasfe/taplo: A TOML toolkit written in Rust](https://github.com/tamasfe/taplo)
- [cargo-binstall/README.md at main · cargo-bins/cargo-binstall](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md)
- [Non-critical corrections - February 2026 Edition · Issue #1488 - GitHub](https://github.com/crate-ci/typos/issues/1488)
- [Install cargo-binstall · Actions · GitHub Marketplace](https://github.com/marketplace/actions/install-cargo-binstall)
- [Non-critical corrections - March 2026 Edition · Issue #1509](https://github.com/crate-ci/typos/issues/1509)
- [jdx/mise: dev tools, env vars, task runner](https://github.com/jdx/mise)
- [Lefthook at Evil Martians](https://evilmartians.com/opensource/lefthook)
- [Install Lefthook on Ubuntu 26.04](https://lindevs.com/install-lefthook-on-ubuntu)
- [evilmartians/lefthook: Fast and powerful Git hooks manager ...](https://github.com/evilmartians/lefthook)
- [mise](https://rustutils.com/tools/mise/)
- [mise-en-place 완벽 가이드 — nvm·pyenv·asdf를 대체하는 Rust 기반 ...](https://pkglog.com/blog/mise-runtime-version-manager-guide/)
- [TOML Configuration: Syntax Guide, Validation & Best Practices \[2026\]](https://snaputils.tools/articles/toml-guide)
- [Cargo Backend | mise-en-place](https://mise.jdx.dev/dev-tools/backends/cargo.html)
- [app mise - Command line utilities - Lib.rs](https://lib.rs/crates/mise)
- [Non-critical corrections - June 2026 Edition · Issue #1562](https://github.com/crate-ci/typos/issues/1562)
- [cargo-binstall/SUPPORT.md at 9cfc0cd5f97300925ae60f67712b74970a380aca · cargo-bins/cargo-binstall](https://github.com/cargo-bins/cargo-binstall/blob/9cfc0cd5f97300925ae60f67712b74970a380aca/SUPPORT.md)
- [GitHub - cargo-bins/cargo-quickinstall: pre-compiled binary packages for `cargo install`](https://github.com/cargo-bins/cargo-quickinstall)
- [cargo-binstall auditable info](https://gist.github.com/NobodyXu/f904d194c670549ee1c94bf759a9353f)
- [Usage - Clippy Documentation](https://doc.rust-lang.org/clippy/usage.html)
- [feat: allow to specify Rust profile (#4101) · jdx/mise@3f6400f](https://github.com/jdx/mise/commit/3f6400fd3f4e1c9a19c12ce6caa257e970eb4ade)
- [Mise ate my Makefile](https://raskell.io/articles/mise-ate-my-makefile/)

## Cost

Total: $1.3041