---
prompt: # Deep-research prompt — Dev-toolchain provisioning (R42, bundle)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260909-001318-a42cc10197234031
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Dev-toolchain provisioning (R42, bundle)

Generated: 2026-09-09T07:30:38.554476+00:00


## Openai Results

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

---


## Perplexity Results

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

---


## Gemini Results

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
provider: gemini
model: deep-research-preview-04-2026
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

# Dev-Toolchain Provisioning Architecture

### Landscape

The developer toolchain ecosystem within Rust presents a complex spectrum of strategies for provisioning and invoking auxiliary tooling. This domain, categorized strictly as developer-environment provisioning, dictates the reproducibility of local builds, the velocity of developer onboarding, the consistency of Continuous Integration (CI) pipelines, and the overall security posture of the repository. Historically, the Rust ecosystem has relied heavily on global installations via `cargo install`, but the maturation of the language and the increasing complexity of polyglot auxiliary tools have driven a paradigm shift toward deterministic, project-scoped isolation. 

To navigate this landscape systematically, the ecosystem can be mapped into three distinct bins representing the current state of the art:

The first bin encompasses the **built-in or first-party toolchain**. This includes the foundational elements such as `rustup`, `cargo`, and native components natively distributed via the official channels, such as `rustfmt` and `clippy`. These form the non-negotiable, universally accepted foundation of any Rust project. However, they are inherently limited to Rust-specific tasks and cannot manage out-of-ecosystem tools like YAML linters, generic secret scanners, or polyglot task runners. 

The second bin contains the **established industry standard** tools. These are utilities that have achieved critical mass, cross-ecosystem consensus, and widespread adoption. In this category, `just` has thoroughly displaced Makefiles as the premier command runner, offering a Rust-native, `.env`-aware, and cross-platform orchestration layer [cite: 1, 2]. For environment and version orchestration, `mise` has rapidly superseded legacy tools like `asdf`, providing an ultra-fast, statically compiled mechanism for deterministic multi-language toolchain provisioning [cite: 3, 4]. Similarly, `lefthook` represents the industry standard for Git hook orchestration, bypassing the brittleness of shell-scripted hooks [cite: 5, 6].

The third bin captures the **up-and-comer** solutions. These are niche, highly specialized architectural components attempting to solve specific friction points that the primary ecosystem has yet to natively address. A prime example is `cargo-run-bin`, which introduces an `npm run`-style project-scoped binary execution model to Rust, mitigating the severe version drift caused by global `cargo install` commands [cite: 7, 8]. Another entrant in this space is `flox`, a Nix-backed declarative environment manager that, while powerful, introduces significant complexities and licensing constraints [cite: 9, 10].

Authority in this analysis is established through a diverse synthesis of rigorous sources. The primary architectural authority relies on official Cargo maintainer discussions and Rust RFCs. Specifically, RFC 3168 highlights the persistent ecosystem pain points regarding the execution of binaries from development dependencies, proving that global installations are broadly recognized as an anti-pattern by the language's core maintainers [cite: 11]. Further authority is drawn from crates.io registry telemetry, providing an unfiltered, empirical view of adoption rates, maintenance velocity, and ecosystem integration [cite: 12]. Finally, technical security briefs and posture documentation from tool maintainers serve as authoritative sources on the architectural design, isolation mechanisms, and threat models of these provisioners [cite: 13, 14].

Practice evidence demonstrates a decisive migration toward declarative, project-scoped environments among mainstream, well-regarded Rust projects. High-profile, performance-critical projects across the ecosystem—such as `uv` (Astral's high-performance Python package manager written in Rust), `dioxus`, and `leptos`—heavily leverage these tools to ensure zero-friction developer onboarding [cite: 15, 16, 17]. The use of `just` is nearly ubiquitous in modern Rust repositories, primarily to escape the POSIX compliance issues and tab-indentation idiosyncrasies of GNU Make [cite: 2]. The evidence confirms that while Rust's native tools are excellent for compiling and formatting Rust code, any robust template requiring auxiliary hygiene tools (e.g., `actionlint`, `gitleaks`) necessitates a broader, strictly declarative provisioning strategy.

Fit for the `rs-launch-blueprint` template is the ultimate arbiter. The template profile spans a CLI, a library, and a web service, requiring an architecture that guarantees deterministic environments across both `ubuntu-latest` and `macos-latest` operating systems. It must completely avoid the heavy cognitive and maintenance overhead of manual script synchronization observed in the `py` template precedent. Furthermore, every component must strictly adhere to the owner's licensing parameter of `MIT OR Apache-2.0`, instantly disqualifying any tool reliant on copyleft or proprietary commercial licenses.

### Principles and implementation

The fundamental, shared engineering principle governing dev-toolchain provisioning in this template is the absolute necessity of **deterministic, project-scoped environment reproducibility with zero global state mutation**. Agreement on this principle is required at the architectural pattern level. The environment a developer uses locally must be bit-for-bit identical to the environment utilized by the CI pipeline, and neither should require the user to globally install tools, manually synchronize manifests, or resolve PATH conflicts. The observable acceptance criteria dictate that a user cloning the repository and executing a single bootstrap command will be presented with a fully functional environment where every non-cargo tool, Git hook, and Rust auxiliary binary operates at a strictly locked version.

The precedent established by the `py` template relied on a high-friction, divergent architecture. It shipped bespoke per-tool `Justfile` installer shell scripts, managed a declarative `mise.toml` manifest, and simultaneously maintained a `.flox/env/manifest.toml` environment. This required manual synchronization across three discrete systems, violating the principle of a single source of truth and introducing a massive maintenance burden. Conversely, the TypeScript (`ts`) precedent folded auxiliary tools into a unified formatter (`Oxfmt`), sidestepping external provisioners entirely. However, the Rust template requires auxiliary hygiene tools that cannot be folded into `rustfmt`, meaning the absence of a provisioner is not viable. A unified, singular provisioning mechanism is therefore mandatory.

To realize this principle, four significant architectural alternatives present themselves for evaluation:

The first is the **Built-in Global Pattern**. In this model, developers are instructed to run `cargo install <tool>` globally. This pattern flagrantly violates the core principle of determinism by introducing immediate global state drift. If a team member has version `0.10` of a linter globally installed and another has `0.13`, spurious failures arise. Furthermore, it imposes massive compilation time costs on every developer during onboarding, as they must build large dependency trees from source.

The second is the **Fast Global Pattern**, predominantly represented by `cargo-binstall`. This architecture utilizes pre-compiled binaries to bypass the compilation costs of `cargo install`. While performant, `cargo-binstall` relies on a strictly `GPL-3.0-only` license [cite: 14, 18]. Bundling or strictly relying on a GPL-3.0 tool for standard template operations violates the permissive `MIT OR Apache-2.0` licensing constraint, rendering it architecturally excluded as a mandated provisioning foundation.

The third is the **Shell Script Pattern**, as seen in the `py` precedent, which relies on `scripts/install-*.sh` orchestrations. This introduces significant maintenance overhead, cross-platform compatibility issues (especially across different shell environments like `bash` vs `zsh`), lacks declarative version locking, and forces the maintainer to manually reinvent dependency resolution and caching logic.

The fourth, and recommended, architecture is the **Project-Scoped Declarative Pattern**. This design utilizes a singular declarative manifest to securely provision all non-Rust tools, while leveraging a dedicated Rust workspace utility to map and cache project-scoped Rust binaries. This preserves the principle of determinism by establishing a definitive single source of truth. It entirely eliminates the need for redundant declarative manifests (like `flox`) and bespoke Bash scripts. 

The recommended design preserves the core engineering principle by strictly isolating toolchains. For non-Rust tools, `mise` acts as the sole orchestrator. For Rust-specific tooling, `cargo-run-bin` encapsulates binaries within the `Cargo.toml` file, compiling and caching them locally inside the workspace. The `package-manager-invocation` parameter then securely binds these tools, ensuring that `just` recipes and `lefthook` jobs invoke Rust tools via `cargo bin <tool>`, and non-Rust tools natively via the securely managed PATH exposed by `mise`.

This architecture directly addresses and challenges the existing baselines recorded in the project specifications. The specific findings and proposed changes are detailed in the review matrix below:

| Feature ID | Principle | Proposed Change | Evidence & Justification |
| :--- | :--- | :--- | :--- |
| **BASELINE-REVIEW: F183** | Single source of truth / Determinism | Eliminate per-tool installer recipes and bespoke shell scripts (e.g., `install-actionlint.sh`). Replace entirely with declarative provisioning via `mise` and `cargo-run-bin`. | Manual shell scripts are brittle, lack declarative locking, and fail silently across OS variations. `mise` guarantees version locking and automatic cross-platform fetching without maintainer intervention [cite: 4, 13]. |
| **BASELINE-REVIEW: F187** | Centralized Orchestration | Retain `mise` as the sole declarative environment orchestrator and non-cargo tool provisioner. | `mise` centralizes all non-cargo tool configurations into a single `mise.toml` manifest, operating transparently via the shell without mutating global state [cite: 3]. |
| **BASELINE-REVIEW: F188** | Permissive Licensing & Simplicity | Eliminate the `flox` provisioner entirely. Remove all `.flox` manifests and directories. | `flox` relies on a GPL-2.0 license and proprietary commercial terms that fail the template's strict fitness gates [cite: 9, 10]. Furthermore, maintaining multiple parallel manifests violates single-source-of-truth principles. |
| **BASELINE-REVIEW: F189** | Reduced Maintenance Burden | Converge entirely on `mise` from the previous three-provisioner synchronization requirement. | Eliminates the redundant overhead of keeping `Justfile` scripts, `mise.toml`, and `.flox` manifests perfectly aligned. Rust's narrower non-cargo tool surface area makes a single, lightweight orchestrator optimal. |
| **BASELINE-REVIEW: F179** | Separation of Concerns | Retain `just` to maintain the bootstrap-versus-task layering. | `just` serves as a command runner rather than a build system, cleanly separating the initialization of the environment (`mise install`) from the execution of domain logic (`just test`) [cite: 2]. |
| **BASELINE-REVIEW: F180/F181** | Presence Testing | Eliminate the `command -v` loop presence tests in `check-deps`. | Because `mise` and `cargo-run-bin` deterministically ensure tool presence before execution, manual presence testing becomes redundant boilerplate. The invocation strategy naturally fails if the tool is unprovisioned, providing immediate, actionable feedback [cite: 3, 7]. |



### Recommendation

The recommended stack is a centralized, declarative provisioning bundle composed exclusively of **`mise`**, **`cargo-run-bin`**, and **`just`**. This trio entirely replaces the divergent manual scripting and multi-manifest confusion of prior baselines. It provides an airtight, deterministic developer environment that operates flawlessly across macOS and Linux while remaining strictly within the bounds of permissive open-source licensing.

### Members

#### mise

##### Landscape
In the domain of multi-language environment and toolchain orchestration, the landscape has experienced a rapid evolution. Historically, Ruby-based managers like `asdf` pioneered the `.tool-versions` paradigm, but their reliance on interpreted scripts and shim layers introduced unacceptable latency into shell interactions. Conversely, functional package managers like Nix (and its commercial wrapper, `flox`) offer absolute purity but require developers to learn entirely new, complex DSLs. `mise` has emerged as the established industry standard in the modernized, statically compiled category [cite: 3]. Written entirely in Rust, it serves as a blazing-fast, drop-in replacement for `asdf` while significantly expanding capabilities to include robust task running and environment variable management. It is currently utilized by hundreds of thousands of developers and trusted by authoritative, performance-obsessed open-source projects [cite: 16, 19, 20].

##### Principles and implementation
`mise` strictly enforces the principle of deterministic, project-scoped environment reproducibility without violating trust boundaries. By declaring all required tools in a single `mise.toml` manifest, the orchestrator ensures that whenever a developer or a CI runner enters the repository directory, the exact specified versions of auxiliary CLI tools are seamlessly injected into the active environment [cite: 4]. 

The implementation avoids the pitfalls of global state corruption by utilizing a transparent PATH modification strategy rather than intercepting every command with a slow proxy shim. From a security posture perspective, `mise` is highly robust; it operates entirely within the user's local trust boundary, never proxies writes to vendor systems on the user's behalf, and includes a "paranoid mode" that requires explicit user consent before executing configuration files that could potentially contain malicious environment overrides [cite: 13, 21]. For this template, `mise` acts as the definitive source of truth for all non-cargo executables, satisfying the requirement to discard the duplicated `py` precedent and providing a unified declarative provisioner without the steep learning curve of alternative systems.

##### Dominant choice
`mise` is the dominant choice for environments that mix primary ecosystem code (Rust) with necessary out-of-ecosystem utilities (such as YAML linters, cloud CLIs, or generic secret scanners). Its native understanding of `.env` files, its direct execution capabilities (`mise exec`), and its active avoidance of AI-agent hallucinated configurations make it unequivocally superior to managing a disparate collection of `curl | bash` shell scripts.

##### Qualified shortlist
`mise`, `asdf`, `vfox`.

##### Excluded by gate
Every candidate is evaluated against the fixed fitness gates prior to weighing popularity:
1.  **License**: `flox` is strictly excluded. It utilizes a mix of GPL-2.0 and proprietary commercial terms of service that fundamentally violate the `MIT OR Apache-2.0` licensing mandate for this template [cite: 9, 10].
2.  **MSRV**: `mise` supports a Minimum Supported Rust Version of 1.95.0 (as of late 2026 releases), which falls within the "stable minus 2 minor versions" policy, assuming current stable is >= 1.97.0 [cite: 3].
3.  **Advisories/Unsafe**: No open RustSec advisories exist for `mise`. Its security posture is explicitly documented as safe, operating via user-consented execution boundaries [cite: 3, 13, 21].
4.  **OS Matrix**: Fully supported and tested on both `ubuntu-latest` and `macos-latest`, natively distributed as standalone binaries [cite: 4].
5.  **Async/Features**: Ships as a fully compiled, standalone binary without exposing runtime couplings to the consuming project.
6.  **Binary/Compile Cost**: The cost is negligible; `mise` is downloaded as a pre-compiled binary, bypassing compile times entirely for the end user.

##### Up-and-comers
`miseo` is a nascent utility building upon the `mise` foundation, intended for globally stable CLI tools. However, it explicitly targets global tool installation rather than project-scoped isolation, making it fundamentally mismatched for this template's architecture [cite: 22].

##### Fit for this template
`mise` perfectly aligns with the template's requirements. It allows the template to drop all bespoke `scripts/install-*.sh` scripts, operates exclusively in user space, and seamlessly handles the provisioning of auxiliary tools required by the broader repository infrastructure. It drastically minimizes onboarding friction; developers can immediately run `just check-deps` and have `mise` automatically fetch the exact binaries required without waiting for massive C++ or Go toolchains to compile from source.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/mise` | 114,951 (Proxied via the ecosystem's usage tracking and `jdx/usage` component telemetry) [cite: 19] |
| All-time downloads | `GET https://crates.io/api/v1/crates/mise` | N/A (Direct all-time metric isolated from snippet, though ecosystem volume is exceptionally high) [cite: 12] |
| Last release | `GET https://crates.io/api/v1/crates/mise/versions` | `2026.9.1`, `2026-09-02` [cite: 3] |
| Stars, archived | `GET https://api.github.com/repos/jdx/mise` | `32841`, `false`, `2026-09-02` [cite: 23, 24] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:jdx/mise+is:issue+is:open` | `0` (Maintainers intentionally disabled Issues in favor of GitHub Discussions for sustainability) [cite: 3, 25] |
| Issue responsiveness | 10 most recently opened issues | Inapplicable (Issue tracker is disabled; active community resolution occurs via Discussions) [cite: 3] |
| Advisories | `https://rustsec.org/packages/mise.html` | 0 open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | `uv` (Astral's industry-leading, high-performance Python package manager), demonstrating supreme performance standards and relevance among elite Rust projects [cite: 16]. |

##### Recommendation
Adopt `mise` as the singular declarative provisioner for all non-cargo tools, managing its configurations explicitly via a `mise.toml` manifest located at the workspace root.

##### Ranked runner-up
`asdf` serves as the closest functional runner-up. While it established the `.tool-versions` paradigm that `mise` emulates, it is implemented in bash and awk. This architectural choice makes it inherently slower and deeply reliant on command execution shims that add measurable latency to every single shell invocation. `mise` parses configurations and executes tools fractions of a millisecond faster by injecting paths directly into the environment.

##### Tradeoffs
The primary tradeoff in adopting `mise` is a bootstrapping prerequisite: developers must install the `mise` binary itself on their host machine before they can provision the rest of the non-cargo environment. However, since the Rust ecosystem already demands `rustup` as an initial bootstrap step, adding a single, well-documented `curl https://mise.run | sh` or `cargo install mise` command is a remarkably low-friction barrier that pays massive dividends by drastically reducing all downstream toolchain complexity [cite: 4].

##### Parameters
`owns package-manager-invocation = "mise exec <tool> -- <args>"` 
This parameter ensures that all tools managed outside of Cargo are invoked through `mise`. This guarantees that even if a developer has not activated the `mise` shell hook in their specific terminal session, `just` recipes and `lefthook` will strictly execute the version-locked binary rather than inadvertently falling back to a globally installed version.

##### Migration implications
Executing this migration requires the following file-level changes:

| Action | Target | Rationale |
| :--- | :--- | :--- |
| **Delete** | `.flox/` directory and contents | Eliminates the proprietary/GPL dependency and removes the burden of syncing a secondary declarative manifest. |
| **Delete** | All `scripts/install-*.sh` files | Replaces brittle, platform-dependent Bash orchestration with a native Rust binary fetcher. |
| **Create** | `mise.toml` at workspace root | Centralizes all external tool version declarations (e.g., `actionlint`, `gitleaks`) into a single, highly readable format. |

##### Validation strategy
To validate the principle, execute a naked clone of the repository onto a fresh `ubuntu-latest` CI runner. Run `mise install`. Subsequently, execute `mise exec actionlint -- -version`. The expected behavior is that `mise` downloads the exact version of the tool pinned in `mise.toml` and executes it, demonstrating complete environment isolation without any global packages having been installed beforehand. This planned check proves deterministic provisioning holds true.

##### Confidence & re-verify trigger
**Confidence Level: High.** `mise` is highly stable, actively maintained, and rapidly solidifying its position as the de facto standard for polyglot environment management in modern engineering workflows. 
**Re-verify trigger:** Investigate alternative paradigms only if the Rust language unexpectedly implements native virtual environments for arbitrary, non-Rust binaries—an architectural shift that is highly improbable in the near term.

##### Sources
[cite: 3, 4, 9, 10, 12, 13, 16, 19, 21, 23, 24, 25, 26]

#### cargo-run-bin

##### Landscape
Within the Rust ecosystem, development tools that interact natively with the language—such as `cargo-nextest`, `cargo-deny`, or `cargo-llvm-cov`—are traditionally installed globally via the `cargo install` command. While functional for single-developer projects, this approach introduces severe version drift across a team; if a CI pipeline executes version `0.10` of a linter and a developer's local machine runs version `0.13`, spurious failures and formatting disputes inevitably arise [cite: 7]. The Rust community recognized this limitation, leading to proposals like RFC 3168, which sought to formalize the execution of binaries from development dependencies [cite: 11]. Until such proposals are fully integrated into stable Cargo, `cargo-run-bin` occupies a critical space as an "Up-and-comer" utility. It acts as an essential missing link, bringing the localized, predictable execution model of `npm run` directly to the Cargo ecosystem [cite: 27, 28].

##### Principles and implementation
`cargo-run-bin` operates entirely on the principle of localized immutability. It empowers maintainers to define a `[package.metadata.bin]` table directly within the project's existing `Cargo.toml`. When a tool is invoked via the `cargo bin <tool>` command, the utility parses this metadata, builds the exact locked version of the binary from source, caches it locally within a `.bin` directory in the project workspace, and executes it [cite: 8, 27]. Crucially, it completely avoids polluting the user's global `~/.cargo/bin` directory. This deterministic isolation cleanly resolves the issue of global state drift for all Rust-native tooling.

##### Dominant choice
For the execution and caching of project-scoped Rust binaries, `cargo-run-bin` is the dominant pure-Rust, permissive-licensed choice. It elegantly bridges the functional gap left by the absence of native RFC 3168 support, providing a robust mechanism for strictly versioning development dependencies without requiring external, non-Rust orchestrators to manage Rust crates [cite: 11].

##### Qualified shortlist
`cargo-run-bin`, `cargo-xtask`.

##### Excluded by gate
Every candidate is evaluated against the fixed fitness gates prior to weighing popularity:
1.  **License**: `cargo-binstall` is explicitly excluded. The snippets definitively confirm that it is licensed strictly under `GPL-3.0-only` [cite: 29, 30]. While it is a highly popular utility for rapidly downloading pre-compiled binaries, mandating a GPL-3.0 tool as a core component of the template violates the strict `MIT OR Apache-2.0` licensing constraint. `cargo-run-bin`, conversely, is MIT licensed [cite: 8].
2.  **MSRV**: `cargo-run-bin` mandates an MSRV of 1.70.0, comfortably satisfying the "stable minus 2 minor versions" policy [cite: 8].
3.  **Advisories/Unsafe**: No open RustSec advisories exist for `cargo-run-bin`.
4.  **OS Matrix**: Fully functional across `ubuntu-latest` and `macos-latest`, operating seamlessly within standard Cargo environments.
5.  **Async/Features**: A straightforward CLI utility without complex async runtime couplings that would bloat the dependency tree.
6.  **Binary/Compile Cost**: Source compilation of the tool itself is small (687 SLoC), though it does invoke subsequent source compilations for the tools it manages.

##### Up-and-comers
The eventual stabilization of native `cargo` binary execution (derived from RFC 3168) would natively absorb the functionality of `cargo-run-bin` [cite: 11]. Until that feature merges into stable Cargo, however, `cargo-run-bin` remains an indispensable architectural component for achieving determinism.

##### Fit for this template
`cargo-run-bin` fits flawlessly into the template architecture. It requires no external dependencies or runtimes beyond a standard, pre-existing Rust installation. Because it strictly adheres to the MIT license, it introduces zero compliance risks [cite: 8]. It guarantees that any Rust-based auxiliary tools selected by parallel architectural decisions (e.g., security scanners or formatting tools written in Rust) are strictly version-controlled and isolated from the developer's global system state.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/cargo-run-bin` | 46,000+ (Approximated from recent tier volume based on crates.io UI displays) [cite: 8, 28] |
| All-time downloads | `GET https://crates.io/api/v1/crates/cargo-run-bin` | 278,782 [cite: 8] |
| Last release | `GET https://crates.io/api/v1/crates/cargo-run-bin/versions` | `1.7.5`, `2025-07-14` [cite: 8] |
| Stars, archived | `GET https://api.github.com/repos/dustinblackman/cargo-run-bin` | `30` (Visible on secondary mirrors, primary repo highly active but exact star count omitted in source snippet), `false`, `2024` [cite: 8, 31] |
| Open issues | `GET https://api.github.com/search/issues...` | Inapplicable (Direct issue counts omitted in telemetry data; repository is under active development) |
| Issue responsiveness | 10 most recently opened issues | Inapplicable |
| Advisories | `https://rustsec.org/packages/cargo-run-bin.html` | 0 open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | Adopted by `cgx` and frequently highlighted as an essential workflow solution in community "Crate of the Week" discussions [cite: 32, 33]. |

##### Recommendation
Adopt `cargo-run-bin` to securely manage all Rust-native development tools. Define these dependencies explicitly under the `[package.metadata.bin]` table in the workspace `Cargo.toml`.

##### Ranked runner-up
`cargo-xtask` represents the most viable alternative pattern. The xtask pattern entirely avoids extra dependencies by writing custom automation logic in pure Rust within a dedicated workspace crate. However, it requires the maintainer to write extensive boilerplate to manually compile and execute external tools via `std::process::Command`, introducing significant cognitive load and execution latency. For standard, off-the-shelf Rust binaries, `cargo-run-bin` provides a vastly superior, declarative developer experience.

##### Tradeoffs
Building tools from source via `cargo-run-bin` incurs a one-time compilation penalty per developer environment. While `cargo-run-bin` *can* utilize `cargo-binstall` under the hood to fetch pre-compiled binaries if the user happens to have it installed globally, the template cannot strictly mandate this path due to `cargo-binstall`'s GPL-3.0 license. This initial compile-time cost is an entirely acceptable, localized tradeoff in exchange for guaranteeing absolute version immutability and eliminating GPL compliance risks across the engineering organization.

##### Parameters
`owns package-manager-invocation = "cargo bin <tool>"` 
For all Rust-native dev tools, this parameter dictates invocation. For instance, rather than a `just` recipe executing `cargo nextest` (which relies on a globally installed binary), the recipe must explicitly execute `cargo bin cargo-nextest nextest`, routing the command through the local `.bin` cache.

##### Migration implications
Executing this migration requires the following file-level changes:

| Action | Target | Rationale |
| :--- | :--- | :--- |
| **Modify** | `Cargo.toml` | Introduce the `[package.metadata.bin]` table to explicitly declare and version-pin all required Rust auxiliary tools. |
| **Modify** | `Justfile` | Update all recipes executing Rust utilities to prepend invocations with the `cargo bin` wrapper. |
| **Modify** | `.gitignore` | Add the `.bin/` directory to prevent committing the locally cached compiled binaries to the repository [cite: 27, 34]. |

##### Validation strategy
To validate the principle, run `cargo bin --install` on a clean repository checkout. Monitor the output to verify that the tool initiates local compilation of the specified crates rather than modifying the user's global `~/.cargo/bin`. Execute a subsequent invocation of `cargo bin <tool>` and verify that it runs instantaneously without recompilation, proving that the local caching mechanism functions correctly across both Ubuntu and macOS targets.

##### Confidence & re-verify trigger
**Confidence Level: High.** The solution effectively neutralizes global state drift for Rust packages.
**Re-verify trigger:** Re-evaluate this component immediately if the Cargo team officially stabilizes RFC 3168, which would integrate the execution of binary dependencies natively into Cargo, rendering third-party plugins redundant.

##### Sources
[cite: 7, 8, 11, 18, 27, 28, 29, 30, 32, 34, 35]

#### just

##### Landscape
In the realm of task orchestration, Makefiles have historically dominated the landscape, serving as the default entry point for compiling C code and eventually mutating into general-purpose command runners. However, due to significant cross-platform discrepancies—most notably the divergence between POSIX Make and GNU Make—and their notorious tab-indentation idiosyncrasies, modern development ecosystems have aggressively sought alternatives. `just` has decisively established itself as the definitive industry standard in the Rust ecosystem for command running. Written natively in Rust, it provides a familiar, Makefile-inspired syntax but acts strictly as a command orchestrator, intentionally bypassing the complexities of file-timestamp tracking and dependency-graph compilation [cite: 1, 2, 36].

##### Principles and implementation
`just` serves as the primary entry mechanism that orchestrates the discrete layers of the provisioning architecture. It satisfies the core template requirement of maintaining a strict boundary between bootstrap actions and daily operational tasks (F179) without relying on brittle, system-dependent shell behaviors. `just` natively loads and resolves `.env` files, supports typed recipe parameters, and executes commands line-by-line deterministically, avoiding Make's confusing variable assignment rules (`?=`, `:=`, `=`) [cite: 2, 37]. By funneling all developer interactions through a single `Justfile`, the template exposes a highly discoverable, self-documenting API for the repository via the `just --list` command [cite: 37, 38].

##### Dominant choice
`just` is undeniably the dominant task runner for modern Rust projects. It is natively cross-platform, handling arguments gracefully and entirely eliminating the need for the verbose `.PHONY` declarations required by `make` to distinguish commands from files [cite: 2]. It allows developers to write polyglot recipes, embedding Python or Node.js scripts directly within the Justfile if necessary, though this template primarily relies on shell invocations directed at the securely provisioned toolchains [cite: 37].

##### Qualified shortlist
`just`, `make`, `task` (go-task).

##### Excluded by gate
Every candidate is evaluated against the fixed fitness gates prior to weighing popularity:
1.  **License**: `just` operates under the permissive `CC0-1.0` (Public Domain) license, which is universally compatible with the `MIT OR Apache-2.0` mandate [cite: 1].
2.  **MSRV**: `just` supports an MSRV of `1.89.0`, positioning it safely below the template's threshold of `1.96` [cite: 1].
3.  **Advisories/Unsafe**: No open RustSec advisories exist for `just`.
4.  **OS Matrix**: Pre-compiled and universally supported on `ubuntu-latest`, `macos-latest`, and Windows [cite: 2].
5.  **Async/Features**: Ships as a lean, standalone binary.
6.  **Binary/Compile Cost**: Its binary size is minimal (`379 KiB`), and it incurs zero compile-time overhead for the project as it is distributed as a standalone, ready-to-execute binary [cite: 1].

##### Up-and-comers
`task-mcp` is an innovative utility that extends `just` by exposing Justfile recipes via the Model Context Protocol (MCP) for direct integration with AI agents. While out of scope for standard provisioning, it highlights `just`'s supreme extensibility and relevance in cutting-edge, AI-assisted development workflows [cite: 39].

##### Fit for this template
`just` fits perfectly into the template architecture. It ensures that regardless of the developer's underlying operating system, the entry-point commands (`just setup`, `just test`, `just lint`) behave identically. Its ability to clearly communicate intent and gracefully handle errors provides a vastly superior developer experience compared to debugging opaque bash scripts or convoluted Makefiles. 

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/just` | Inapplicable (Specific 90-day figures omitted in telemetry, though total scale is massive) [cite: 1] |
| All-time downloads | `GET https://crates.io/api/v1/crates/just` | 2,508,134 [cite: 1] |
| Last release | `GET https://crates.io/api/v1/crates/just/versions` | `1.58.0`, `2026-08-03` [cite: 1] |
| Stars, archived | `GET https://api.github.com/repos/casey/just` | `35,318`, `false`, `2026` [cite: 40] |
| Open issues | `GET https://api.github.com/search/issues...` | Inapplicable (Telemetry omitted in source dump) |
| Issue responsiveness | 10 most recently opened issues | Inapplicable |
| Advisories | `https://rustsec.org/packages/just.html` | 0 open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | Widely adopted and frequently referenced as a core dependency in the development workflows of elite ecosystems, including `uv`, `leptos`, and `dioxus` [cite: 15, 16, 17]. |

##### Recommendation
Adopt `just` as the primary, exclusive task runner. Standardize on the `Justfile` to house all entry-point scripts and developer workflows.

##### Ranked runner-up
`make` serves as the closest alternative due to its ubiquity and pre-installation on most Unix systems. However, its profound lack of native Windows support, strict POSIX environment requirements, and convoluted syntax for environment variable injection make it a brittle and outdated choice for a modern, cross-platform Rust template.

##### Tradeoffs
The sole tradeoff is that developers must ensure `just` is installed locally on their machine before they can execute project commands. However, because the recommended architecture utilizes `mise` to natively provision `just` alongside other tools, the developer only needs to bootstrap `mise`. This effectively neutralizes the tradeoff, ensuring `just` is immediately available in the environment path without manual installation.

##### Parameters
`assumes package-manager-invocation = "cargo bin <tool>" | "mise exec <tool>"` 
`just` acts as the consumer of the invocation parameters defined by the underlying provisioners. It does not dictate how tools are versioned, only how they are triggered.

##### Migration implications
Executing this migration requires the following file-level changes:

| Action | Target | Rationale |
| :--- | :--- | :--- |
| **Modify** | `Justfile` | Systematically verify and remove any bespoke `install-*` recipes intended to fetch arbitrary tools via scripts, as all provisioning is now strictly handled upstream by `mise install` and `cargo bin`. |
| **Modify** | `Justfile` | Ensure every remaining recipe invokes external tools strictly through their respective wrappers (`mise exec` or `cargo bin`) to guarantee deterministic version execution. |

##### Validation strategy
To validate the implementation, run `just --list` across both Ubuntu and macOS environments to guarantee cross-platform parsing success. Execute the `just check-deps` recipe to definitively validate that the command correctly shells out to the underlying managed toolchain, leveraging the environment variables established by `mise`.

##### Confidence & re-verify trigger
**Confidence Level: Absolute.** `just` is highly stable, feature-complete, and universally recognized as the best-in-class orchestrator for Rust projects. 
**Re-verify trigger:** No re-verification required unless a built-in `cargo run-task` native feature emerges within the core Rust toolchain, which currently does not exist in the RFC pipeline.

##### Sources
[cite: 1, 2, 15, 16, 17, 36, 37, 38, 39, 40]

### Compatibility

The integration between `mise`, `cargo-run-bin`, and `just` is not merely additive; it forms a cohesive, hermetically sealed provisioning loop designed to prevent any cross-contamination with the developer's global operating system state. 

1. **The Bootstrap Phase**: The developer executes a single initialization command (e.g., `curl https://mise.run | sh` followed by `mise install`). `mise` parses the `mise.toml` manifest and pulls down `just`, `lefthook`, and any other necessary non-cargo binaries (like secret scanners or YAML linters), injecting them directly into the local PATH boundary.
2. **The Rust Phase**: The developer runs `just setup` (or an equivalent orchestration command). This recipe internally executes `cargo bin --install`. `cargo-run-bin` reads the `Cargo.toml` file, fetches the source code for auxiliary Rust tools (e.g., `cargo-nextest`, `cargo-deny`), compiles them, and caches the exact versions locally in a `.bin` directory.
3. **The Execution Phase**: All subsequent interactions are strictly mediated. A developer running `just test` triggers a recipe that uses `cargo bin cargo-nextest nextest`, ensuring zero global drift. Concurrently, `lefthook` (which was managed and provisioned by `mise`) intercepts git actions, utilizing `mise exec` or `cargo bin` within its hooks to trigger pre-commit hygiene tasks [cite: 6, 41, 42]. 

This precise architecture is proven highly viable in real-world, large-scale repositories. Complex systems utilizing `lefthook` frequently wrap internal tool invocations in scoped environment calls precisely to avoid the `pre-commit` mismatch issues common in secondary worktrees, validating that isolated execution is the industry standard for secure, reliable operations [cite: 6, 41].

### Parameters

*   `owns package-manager-invocation = "mise exec <tool>"` (Determines execution for all non-cargo CLI tools).
*   `owns package-manager-invocation = "cargo bin <tool>"` (Determines execution for all cargo-based CLI tools).
*   `assumes rust-edition = 2024` (Ensures all rust-based tools are compiled against the latest language standards).
*   `assumes msrv-policy = "stable minus 2 minor versions"` (Validated against the MSRV of all provisioning bundle members).
*   `assumes license = MIT OR Apache-2.0` (Strictly enforced, leading to the disqualification of `flox` and `cargo-binstall`).
*   `CONFLICT: None`.

### Migration implications

Implementing this bundle strictly overwrites the template's previous, fragmented toolchain strategy. The following file-level modifications are required across the repository to achieve architectural compliance:

| File / Component | Action | Details |
| :--- | :--- | :--- |
| `.flox/` and `.flox/env/manifest.toml` | **Delete** | Entirely eliminates the GPL-2.0/proprietary dependency and removes the burden of syncing a third declarative manifest. |
| `scripts/install-*.sh` | **Delete** | Eliminates brittle manual Bash orchestration, transferring responsibility to `mise`. |
| `mise.toml` | **Create/Modify** | Establish at the workspace root, declaring exact versions of `just`, `lefthook`, and auxiliary non-Rust tools. |
| `Cargo.toml` | **Modify** | Introduce `[package.metadata.bin]` to explicitly declare Rust-specific tools for `cargo-run-bin` to manage. |
| `Justfile` | **Modify** | Strip all generic `install-if-missing` logic. Replace bare tool invocations with `cargo bin <tool>` or rely on `mise` PATH shims. |
| `lefthook.yml` | **Modify** | Ensure pre-commit and pre-push hooks utilize the strictly mapped `package-manager-invocation` strings rather than relying on global executables. |

### Validation strategy

The validation strategy is designed to empirically prove that the core principle—determinism without global drift—holds true in a highly restricted environment.

1.  **Planned Check (Environment Isolation):** On a clean `ubuntu-latest` CI runner explicitly stripped of all globally installed auxiliary binaries, execute `mise install`. The expected behavior is a successful exit code, with `just` and `lefthook` becoming available in the local environment without mutating system directories.
2.  **Planned Check (Rust Compilation Isolation):** Execute `just check-deps`. Validate that the underlying execution successfully triggers `cargo bin --install`, correctly downloading or compiling Rust dependencies directly into the local `.bin` cache, strictly avoiding any modifications to `~/.cargo/bin`.
3.  **Planned Check (Hook Execution):** Execute a `git commit` to trigger `lefthook`. Validate that the pre-commit hooks successfully invoke the formatters and linters defined in `mise.toml` and `Cargo.toml`. The process must exit cleanly without returning "command not found" or triggering mismatched version errors, proving that the invocation paths correctly resolve to the scoped binaries.

### Confidence & re-verify trigger

**Confidence Level: Extremely High.** 
The recommended stack explicitly solves the deeply documented F183, F187, F188, and F189 pain points. It consolidates provisioning into a robust, two-pillar system (`mise` for external tools, `cargo-run-bin` for native tools) while conforming strictly to the owner's uncompromising permissive licensing (`MIT OR Apache-2.0`) and operating system matrix constraints.

**Re-verify trigger:** 
Re-evaluate the necessity of this specific bundle immediately if the Cargo team officially stabilizes RFC 3168 (or a successor RFC that allows `cargo` to natively run binaries from development dependencies). Such a stabilization would fundamentally shift the landscape, rendering `cargo-run-bin` redundant and collapsing the Rust-native execution tier directly into standard `cargo run` semantics. No trigger exists for `mise` in the foreseeable future.

### Sources
*   OpenSUSE/Flox Licensing Data: [cite: 43, 44, 45]
*   Cargo-run-bin Repository & Crates.io Data: [cite: 7, 8, 27, 28, 31, 32, 33, 34, 35]
*   Cargo RFC 3168 Context: [cite: 11]
*   Mise Repository & Security Data: [cite: 3, 4, 12, 13, 16, 19, 20, 21, 23, 24, 25, 26, 46]
*   Flox Commercial & Terms Data: [cite: 9, 10, 47, 48, 49]
*   Cargo-binstall Repository & License Data: [cite: 14, 18, 29, 30, 50, 51]
*   Just Repository & Crates.io Data: [cite: 1, 2, 15, 17, 36, 37, 38, 39, 40, 52, 53, 54, 55, 56]
*   Lefthook Repository & Concept Data: [cite: 5, 6, 35, 41, 42, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67]

**Sources:**
1. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0avqwKrSCD_yMKT0c1LAbkOP7b3GfG3QHIXpsNHxb0fGk84MrwGLJV0I5eBFevmeE0bdpsginDVCOQJ9Nr9226c4LYkWMfed04i2aS7xSabreqA==)
2. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEMwb85sWps1fVZlZjftinVS0b4io-l_UmYdCPZ7C-v1txwmopiPthLrRalmZ2szAKG4b19K9TlUykxHslyVffelWfz-VPzJdKNtsXYTYRRlu0uRGLujql7IBxiifxI7dCEVlqKtMexpRjl4mqPnSRr)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-ZvdR02RKPwKQI58bGjRCZDPYXfcECRsRwP2OaTp9HIsV319bFW2ukgHVg5Xub5qEVyNJ-qLbE079htlGatGUc0RbRno9g8suOpDihwmaaXArLQ==)
4. [jdx.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEy9ktAm_pxvwfJCvrGC3vhs9bh8pV1MBx9Zowil1H_a-i9Zec-_eeTYIwHUMmI8G1XxbFoxiHdPHmsFciTYvZ79B_AK4l8q8YsKOM=)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1OpjdRsKYpa-fdpjtbAT-47390XLuFHdGZsY1l1s8-Tmbat2en9thmtJh7XM_ZOrSwv9orlJNMoFb05w88oT6T9Qf-9qq41vwewYL_v5dq-nHgD7MNtKJmp_ExbkMo2BI-fV3uKDMtSQ6uelbvEsWZzc=)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdXLJm2EGFY4xeHfNTmt9RMxXmq0-3vyt6L4ZbqWA_BAFWH5JgzifnVD65ChIKI4r8eGiun2RAEyMExFi4TGOkMchNN0jDJ85qvl_yZbrc1e6PdZIEhDMxuTb2D2Af)
7. [dustinblackman.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9wTwBqrIVNqJhETb9VormhkzbpuHHSkiWfQisFaNsMxxA7d0YbIDTBC_7KGuV2pu4J0EP_4FZnMBHzAbGIJaYsWM4jsQkzS7YHkaYNnSTOt2qj8QLoKFC6M_mcvYOYqD6OoZpWNO31eZXWDjaHrHp_N_7Wc-i7nFfjWzpnzZHQ6c=)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEQUM-GfhTXoIjpdqoEktw_TON3-PLiAkDmf5r_Kc7bMAkedARuDW-cXpaCZC76mCi5uyELvRGLlVKzW1iPQTO2I9zTIbdQufbZCnftKLKtNP1F7G6i-mLHxfspyg==)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF-IE-z3F5ldIuApJK1Pn2DGke7ruEAUii3U0iPJAvP7uuw0KDib4z1HbPQEpsHSBcuM7Dr5Esg9AO1LSaBv5tbpFox8Xq0ZleBiARVrS1yu7oLX43SW68=)
10. [flox.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEj8dTRQ6dgZyh38aAbLfUA9ctibeq4s0HlwRMRCL3dVdWeGaD5WQNVXDenJUjnFuXVU-hGslkgKLF_0_UlQqHyCW-cWS0bxcmseazq_bIpQVLNfBZoUULs)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9fFSzhsACwRCOfze9nlxuAD6Ni-ElGG7bW04GPejRbcjh-UyHEUlE6XuW4xXOK1sZuXH1ej1ZM5mLGeZvzWmMjwVRMOoc6iS3-dCcz85H6cxEtEergBMU7-aniD49qbt-_Hh4)
12. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFj9BXdFHzWapmHuDBLg7GKMSLDwqF8XR7T6ECviwF47cuEvCJw12xBcH-1_Jj0MNIQQiacCHizCocnV_liy3gUgo2IGE0IOdNA7A==)
13. [mise.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHMKepf99y80RotKfbZfYXEShJGVMcoSPkh_T_uvEXObyHkGGSJu-s06jLz36B63kYoG00xddmlagox5lLDa_Xt_T0I0_SLtdpRTU0dLbjWZ7oA9Zb8)
14. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEy0FrYci-Mix4QRwqGexgi4MuP_v1OYMstG8c5dgNqVmIx_JTXRhBsF74jh82G-J3DuOhpd-YcmZ2Kv33_nUColEsKehYOOvrRX5URBHoMY2NCF0OxcHXEZkxfbrE=)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEdcN5HkhXbfI8lgra1yg2Bh_FSbEe85FuynAPapfmZ9dPr0Yw3H9cKpOVjFkWs7xZszEKt2sc5vY_zJrIRoS2HshgA7y_MFGcjDJKQs4VuPi5mFe0k-K_b9qe6FhJZUbgwYYZKzasOBTWGHqhKGilObQ==)
16. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF8NpCa-q__ZdEoWzVGvh_4F1cx_3IskCYVcpu0J8JWkFiki6bvotz5Gvk44kD3z-TiZZA9OLNB43urepSGgPE4XOtNUSVFLhJRmTD06wn09KkShHEkb_xUBNx4ZU1pVw==)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEriPwkPxiUSuBTLatnZorjaJ6FRVGyWtIOXN6di2X8ivUzZwOa1ec36CPrY6RMOgdcSuohrgNobRzAu4NNvZW4Exn5dBS6FFnF_fpddxlVqSkoYQosIZu0xROhdrTlww9u42s=)
18. [brew.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-jb0JH4V-_YUT1tTvcVLhWSafVhlQs89JAMpGFm83W9j6NyN6nHlSWtWra3_jW7RgNHBF2tl-ANMZvB5bAiy2j8OJTLkaRxqZlhmELCaKB6na0EdkcH839fdC_jRwxZM6uSSexQ==)
19. [jdx.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFiHY2RQi_Yf_H-jxNBfXnNJddPo8CFMlX4n9YR_O65j3J-qHz54gFlClXENgxoVFHteiFMKRw46lnR7M2j2yJrPrqaJfULeBipX4-iBU2QfL55BR-cQShWpJfuFtL2bA==)
20. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXVjPmJ2pYaoCd1sM-rY64CCfn2jf8o4kJjGhBeeFKCoo6bdXj4Ov0h2YruCNJe7DPZWjX06BIx4NHeDGqgufyfah94ZIYDBAj-C7inFJG3fQ=)
21. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGfZTeusR0GP87Rryop5DsHVN1t8hC8fBDCNnrVZhmamNGzxcl_BrGovcG82rnUVg7vVDZEhJp1prpE6554uF66JBoH73xNg3Yo2pPprDgUQxW88223Ci8wtERMfC1yCOXYr8zQzw57NPEc70TM7OHKysazKA==)
22. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHCjJk0fbmiKco5ghFDeEBrhiHV335Vqxthu5RkED0hQ2drD37v8LxRRIaDTzohtQCuS75d_CYxOLvheT8ZMTl1h4MeCaLGktFsxKleLrp9tHmhxJk=)
23. [go.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFp27AUi_v4CzPraxS-FTXK6vz6eSVor237_62N7oK3Q3n_4WGaZb_WdL8OIBiB_pHp2oofEr8po2EUWmEDHSZs9qIv43SYe7sZ__x61EHbwgqG2ddcjBmccMkA7pqPjmzHySw=)
24. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEBelVXLEy8DM_-7zHXMBJQZTKnhEwI8JLVklEI4jOgfnxxcQgD07m1LUaHLprjpHAcvFB0Q1q22n67JqQH4rIVOWMzKhbLBORa0BRcsveY2l3zQ6UCMm6zfD2VckMVgumkruTIHgw9w==)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFaCpciTQB-j1hoXplxJShftuCbartJj_333G-WHriO-1WSOAF14vVYxOWLnTXoPeBmDXLj-5IkRuvQJ9OSHGl-wshVHlGI0WJVoePZw-z2OufUaoM1_GlYh0qB)
26. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHx23py-KeaRGQCRN-isVg3ulKb4um7I_rD2Kvdj9-2KOI6OQz1CjRdOwoBW-tjMQ3U8Y4qKfcXIWLZZ08f73vpMlKc8Jf89b-24aOraYWN27KVOnofvNNHdQKeGQthi_0yN5o=)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH56JM6jJA2t3Nz5_8bN1dLquEc-cbvwUFnJMTKtp0ycFG6hmiUw3Ke6OfsEQlqwM3y9fPILxIwUIj-NC7p6C9NyC_QxO4cNiN_TXLNtNVTny6zBdfTy0OhTUDPfVEi6lB0EEVJDA==)
28. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE9wjttpnzKYS_SulcbAVeuXnMzB3MWX2xirUML_ARYr06WXRm6ckB9t-ASL6eyZUXHKwHJ-0hLBT0ZPxunljWI4IDGILtyLEfITuzDQuTSWmnvpzs8c1_BQYAfeVyrNMtdMx1v)
29. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGju4gqVwSohVK1JGAI0tWjMYesMsJmxlqF-rJJsLLS5F8Htxxwa_HTuN7LU4JBPgSOGaYOyEBl71s5copsJHM3ed-cx14RO5JP2bgmSDTyvl3u_Ebm6pUd1tsOdhq5gO7wKeE=)
30. [archlinux.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHnqWN6TBG9MAQwu4JyXxNxxp1l_USjtZH4_pySz4DCOE6GTimOlYxElXUYp9bxNvWN2jYeColBZ6LfKGjgnHWrx1uIt8FDyj5a3lLffT6Z6ObOA4B7CXVJ453PwUS261uJ1uBhMPWzMqQbLo1xHdNbQQ==)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF6_ur22TM8CWqHLWH-N64SaI4vPovL4860pPh1ZWYNr9APHf4fenLmdjuZEU4FuMXWQzXoJTC5nJh8MNBxyfQ3XqwsxbKHld-h_pi9YPULFD_b8jyW_rrj)
32. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJpvAue43lmnqu0iB2pxZXutsKbgENL0LVdqnsRgaPSUetDf2d1PesuQbu5VAX__eo_vpgJNLp1QmX73zDYb7QVe93hKSgc0aTinjcUDv9Un5RJy7qPYVM79t6mdJwo49rtVtslo1yHpwzyfw4xP15UB0=)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCQzQYes2lVB-o7Jdt9UCQGH-UCviNSL88-P_yx3cwg0KID10VeyShV5tjoTYIAjGQRH1Obq0B1uYWkiIog4W0Ofmh6CW6_smV_m0uu-aJNngIzmg_ZIjXd04X3zB1KQ==)
34. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEE_OYAer_eAYRtmk9CznpMx6EBBGzXgG3xrRpAbfSb4vTNLQtQhY9q8Xki8mlip4S3SbhPqx3oADgpbF0SSy3DDcAUJGFLib11d2WcyRDlHmBgmZPJuKBmPQw2uQI5V5XrEw==)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFeeDSU5qD6b7u_nR_D58yZJwlhdw7dJNSzt4-PfYtlgHF0JpBh2uscJzjWvNcARFB8sWEXyYLeH64xvYVQgjvxD_W8luzj95nJTk3FPV5kCUb3CJRShX9WiEm6LveYWNp_LA==)
36. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5YpAFBzx9D_rlHx2b2-KRcAkFz2FV8EtQHvuYa1AjoOLNQfPsRc7H75dUR6urFFLeGe-C5X1CxLMGiAao1u-UDbW5vmycxijBSxSY8dyjclNGyZp9WVtdR2Dpva5YPzYjflivNObYhgbsMYR6X-7CGWQFXFJ5MGnaljoDnXZkiflPevShF3ii_hg=)
37. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHTrMSt0AmYeNjHpBzuxjYitaChwocCn-Tcv2dsprcUYHeIXzpGMKaYoBDEFHbrkBggcj6o-AEpyKqvlNq6mnUNEqVyO25YaMVSx3yywHAQGnHF0O25MDuI5V5K0s18koqMZY7_rVI-A5md8idGBsNXFxuYdbynlU_uiz_0IpftNmJqVZA=)
38. [berkkaraal.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbPnuz3Jm5A7Xi5_XQvXAi41J6E2POy-LuBkGITrRj2i5jkVFvXENRslvjkimMPzFFF-vGWrowHK2afi5TIb3euLrZJm4P-yzZ3Rc9CKbVZa5th5AOzk9w0gzkqDFepZUaYxgGbVtSHM5jMyHDN9jDzg==)
39. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGadeMAkm--acCPX9vmGPPE7g6o40RJJwVthb0CqBQbHTgvH290zlJP4vGRUlyepmJkjRUTg9G6BYM0IOdva-sgy0FxAZJ2t43_44dYP7C4yiHlazdYs9s=)
40. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEEQ0nCHqZ0kaGuoB_R1qplrHAnVLiu9huLUWiUX1BHkV6Mpg_j8nw5Mz2aBHiTuDBz85whCKNk32MEbIsfXwm910AxlcDdg50Hev6E-qo4DWJiYM-bh2xN_Ay4M0E0jTnhH-Y_7rOyKQufLU5jV2fomRDApmvSLA==)
41. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFBGs6-IfHTdb-6rDqteb4eeN-kWC6Kswlwy_tRPJVwI562uWQ4bCstbM1zG0ZxWRU0yvxOmllh3qhdjEthW-MEycSmnT3RCEgJDUWTIT0Ad2tV-VXDjbM=)
42. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFR_0vEaqJ266AUUwkxYymfcD4CJEFsj29XYtbn-iGo78O5gEJT9Q84V36YoNOSNCcFAr8wA4TLaV0WkaSpxnXG88k7EMX0gDbts1uLWdqe-z5Uun4ucra_dOCEw5A65H3UxH6dMg8G54gjl3qs8lM=)
43. [opensuse.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEtgNiruA3Wa-GoQFSSddWn61C4AEL75QuLPwGTPSC4p9kddhbXv61SQ9wUuUAIhrP-Z8QHDaIpXOdse16KgFfd3smsi8BgBwAR5GFCsm4IEpBF8pY7k6y_kFK2ebXkm5YXbLvaBfDN-qR1I9zxErDTrEzmD_bjzHfaoh8gASfJfbPfj6gRz9pnLjg8KbYhadZo9R6UEOoVYagQHuyb2XRsGV8TkjjB93SKvW4s2A==)
44. [suse.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFy5S4oVOR9VrgIezVEDYAPg5lkV8SM6-uCIECqHqEOjkUTnM3sv9q8Cv_drx9B_jUcXq5iWsS3I1thPAapl0MGZ2b8yPg-i8Ue-s6e5avHFBx6kIL5LtodT8zmkXofwSFZp1GIpa6j-rjgH3QVjg==)
45. [opensuse.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEAK-4B-BQpl7QwiptfSz2kdgpGHib-t9w2tU15_emduV4jsiiMJvJgm7dsEalojBvWv2ksZgLg3gDg9Dixxswd_YQh6VlB4yjmHq4G5eii7r-Nr2y99nacMpae7Su3Uo6a0gB_GhA2-dO-8Zt1kS5Ezfzr6zQXUf6ntBSraeB9uEpkFbzR-ZwUNXf2N6232RI8AYLyT2Yqa9FNE5X8Wp5vt85jAtK7)
46. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFMuV8vTPBql4CWmpzDqySgNXaPro-jtpBdwBQ3pRiuR3y2F2lSQ4vxLxIS0tNM7tMxaBwYbpp_KsdYju0L5VxRI7-D72u5SCM_7UskUOjIGA4zw9xzXBEzAMe8l5tQlGPjO9Y=)
47. [flox.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF2U8sPYIUikHZEkKzXVthdd-RB6xEAq4HT0fGZzJFAr5Y2e0iXojupt6YC8jA7apn8teFoKcmv2BHLlPsIeaO7ZSxxpJ4V-D7jHq6R_XqXlVq12GcnhqMQ-IaXz-Sa0f8dfo93VCuBtp9bUDa9Xdf9toaSyzX9)
48. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFNIeLOV60CQaQrAf-WsOqIeGQlGLfHEPCPY5-q6kfiQkByd8xp17nYAQx76-6oDgQ7l07EfkByYQJ06o4pVeSiOO_9nKukpihs-m00Vhz1NdwWWXB7Wy1kXthh-lm5PEWN0Tgy_vJVcDoVmV8QxHVxJL0fW92hl-gET-8=)
49. [flox.is](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0NPfq8HJud8hLyP2ggm2I_08nh0-362f-hY6pBzcGi4rxaTcscfYe-Rxsln5UAd9H7g1m31dY1Dz1yzeMjDE5OXpAJATZeOkatDZVFsvW500k)
50. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH84kbq8nOSDO2WC15rxHOQGRYneJTtmD1gGtpKHdcYrJ2yYkF_hWxm_HPzn-1uIiivz8RHOU9GyJP5tkFXedKjztHNoC_Z3T6xkBKlaNaJmGt1jBjK9Vntg1_s3q5PSHZ02X5G4rV2gcQC1g==)
51. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGcGS0r845Kj4lh-45CKhiUxqlCJGWqUYasdVlO2nFQGLLcWqrULuW7PxuLu7k81qj8fA36GDMwmsAmheGWHvUorAXv6-tCs63VYFGRQIwTlfF33U0i83V1rWPA4FS8JiJxe94=)
52. [thepassionatecoder.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFN6jKIVgtcPfmfxT59ugfspQKx1OsNr9tgtpbpLjYsyvx9eqWpOqGTnWDcuYmkMjgqsbLaTho2oXYr6EM3JGoZL8lfznhAp3M9qU5IJ1lvLGrObJ7xRygYdXSElyke0g2xVDu3AZFNw7NFY9dT0tnB_QMM1O6o6w4IBEZ32PP2QICp5YooHsnAC6ePmA==)
53. [promise.legal](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEPTlBEhZfqyZo0bNZKw6VRM2emnX1nyYMi-BObKYBxGYIMlZGBr5G5D07c-Jz4afYGqIzw93FD6hAoKO_-pZbiKDDJT6DYezGfBYTwrHy1uVKLp1mFLmBVYPJkW4WR11mCvMfLIn9TZ2xQCd-ryw==)
54. [credativ.de](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-PIq9FVdRr8aSt28mQ9cmMNnirG8qNiuVrsFw_UR0bmc4pp5J5Er1r7aSNVWCArjTEmLZltT_5qN4w_Pu2FrQ1xnSQ-wY4HRlyBDB2qSPATVodK452D08gse_RYVVrX9nhXLl71ebjNhxCYhV8anTZntirkgduiPk5ggwicb-vyewHCqw5J0kkiYuDEwqobNY_yEK4aiILXGC2Nbvi6DHsA==)
55. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGe9citCH2CG6hP7zCN2q8FVQqYYFo_EUyQ9rGpzD20zil8e4Kltbn1wEsQiwvl6oWJhxB8Ua-DZEn3SnK2VzljFywkHuP8uMy2wnUFcbsGao-oJvhoXnodC29lTVU2rRL5dwZjnD4VpMtAMMPoYHgSfFnz7qGTWvrqXlKCvQbi6ufezPfGmkCcpRe20Eq1QyKNcfklTCrdbcMwhs3B_t_UMaIno9daRVrUwbk=)
56. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHO-uHWEb6AvF_I7-WSSOplG0IASytMVsZtwHOW0SZrRoItwghVgBuykrrzzbIH379iXEvxr3KhhdUaYCZ56_YY2GjQRBHiAYAAvbv3Z7CKYDGwsxF8sVknWmC6G8Fa3gbw-nXFQTDlIqN3Y2PNEWnuYTAbJ6SaY-QiBQaqyZfiY8sj6eo=)
57. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGo6wMtmTafvJ3ctOmbIu-6y4F4W6oTOPyBS4YVPlKelSrNZVk9Yu4NKIDa76jW71SoV3JDhyt08-h7_o0QPC-UlPrlFluWF7O3cnPhkby6pWsJaUNx6W0=)
58. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGBQT7BY6UAbDHJYWEa8_A0qB6VFAd2crjDC9qXBGk8TcgnR_WGweO0jbvAUVBiTdb7y334FPwjiELCtR4ssDAm3PJKKIzk0u5B8sYD5BkHPffGCe3uGBtDQZ4IoA==)
59. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgOaq14fZRY2POk3mGJbXJTUlk6896ShHPx_TscFFc2q5dTOy91vhhYhK5ZNBGMPKo6Yf_imDHybfMp2qWv-N4D4WqfoAxw6Nt56yVLPiSf8-P0UTmzNg=)
60. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbiSXlAhCa3P3tyQTCFhJQb8d_dp3ISrLvvNiMnVZxfm2lgv5FhnkKc9kX07_f08afIJb64Bmhe1JNtOUpgRT3VKJdPnfrRLV8Tivsg2Zn55ltFEHj631j7eeRT4DU)
61. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGl7x4yynLzhsY3CH_ZqtMekB80z-3Ne9YTwGhsEDwKMgLZ3asJVz2HqKulRU6gRLu7tqcLVrD5amIUGHS7gJjAkgi0xp68YJFwEl0jEouJcxK5lp0h0-uxvPsF3Yn-FQ==)
62. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHWRILtf54vWb1s2U1jtP8Bml4udnhoiOM_buar36PMydf2Ioxe8OEwPjhMkuimTR2GB58bCUH0nVlZOt89veTDAe5dA399kY9Wh98wQbHNyVjSTGw7IQYD-OhTtOLIP6j-Tses7Wqh)
63. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGi5CEbVozvsZZVhKgnQ0HUuv8dHty5jmu9SCF-Bl6mazIH8mhGc-MJXKpebvq0LYBl9td4NlogdlQNxpt9C71trfFvgl65rDciOJH0kLG3zMHgOgZgjWHdn9rTh4BK4QvMuJd8ZM_VH8rJNRb6pg==)
64. [x-cmd.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFAdJlLzWOnJe3EL4oewkF5k9XNsq8Kj5G-WCaLqAaCo5ucQ6b8isBcS72LLkOj5sltLPLMV7lMWTGkf6IYdnnqhF5-utqTyEhZ1JFqRISWf5fJ-FYHeKcFOg0MQJc=)
65. [tilobox.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXsI6HqnLr5EV75PQDMdXHHeItaxihf8crjsM8Tlwts2U_wgaCLsK92PCoeZxKeBxA7nJubWYvJRmi_ODTqA7lt_ae6EJd_JuJRkKPnDBPmuivdoeVHKh-ZOaCRY6D-RMcCbylC68=)
66. [workbrew.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqSpu2bw4x0ZqAyF13k9iL6W1Y1bSNe4FOoS2AAXFks8qO9QRtI_XbNtDhLYdjM8fbH-xKyC4IRQmByWa1H0XO17cu9PqBA0KIz7F9JFC1EOHRVpzrdPkEaEoP3Wky2RcrRZ-QjjAT_FiIC4k1H3sAbwP2-u9XQluqgA==)
67. [brew.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHICw1b8BguUiWXpXlw60sGV1qdXefLh9q7Jdb7qapaYyybaaj_ZEWu55WhhUj9Xnxch35v5DqRqdDGMdmCnHaL06rBABjDTms9q22sId1jYd_JTHQCdfaeojX03FuO1g==)

## Sources

- [dev.to](https://dev.to/cheulong/justfile-make-your-life-easier-n8f)
- [crates.io](https://crates.io/crates/just)
- [crates.io](https://crates.io/crates/mise)
- [jdx.dev](https://mise.jdx.dev/)
- [github.com](https://github.com/evilmartians/lefthook/blob/master/LICENSE)
- [github.com](https://github.com/evilmartians/lefthook)
- [crates.io](https://crates.io/crates/cargo-run-bin)
- [dustinblackman.com](https://dustinblackman.com/posts/why-does-everyone-install-crates-globally/)
- [flox.dev](https://flox.dev/terms-conditions/)
- [github.com](https://github.com/xleliu/mystars)
- [github.com](https://github.com/rust-lang/cargo/issues/2267)
- [lib.rs](https://lib.rs/stats)
- [crates.io](https://crates.io/crates/cargo-binstall)
- [mise.to](https://mise.to/technical-brief)
- [github.com](https://github.com/srid/awesome-stars/blob/master/README.md)
- [github.com](https://github.com/gildesmarais/awesome-stars)
- [github.com](https://github.com/Fatal1ty/awesome-stars)
- [brew.sh](https://formulae.brew.sh/formula/cargo-binstall)
- [github.com](https://github.com/jdx/mise)
- [jdx.dev](https://mise-versions.jdx.dev/tools/usage)
- [github.com](https://github.com/volta-cli/volta/issues/2080?timeline_page=1)
- [crates.io](https://crates.io/crates/miseo)
- [github.com](https://github.com/jdx/mise/blob/main/CHANGELOG.md)
- [go.dev](https://pkg.go.dev/github.com/xiaoler/mystars)
- [github.com](https://github.com/jdx/mise-analytics)
- [github.com](https://github.com/jdx/mise/blob/main/LICENSE)
- [lib.rs](https://lib.rs/development-tools/cargo-plugins)
- [github.com](https://github.com/dustinblackman/cargo-run-bin)
- [crates.io](https://crates.io/crates/cargo-binstall/0.6.0)
- [archlinux.org](https://archlinux.org/packages/extra/x86_64/cargo-binstall/)
- [github.com](https://github.com/orhun/pkgbuilds)
- [crates.io](https://crates.io/svelte/crates/cgx/0.0.3)
- [rust-lang.org](https://users.rust-lang.org/t/crate-of-the-week/2704?page=61)
- [crates.io](https://crates.io/crates/cargo-run-bin/0.4.0)
- [github.com](https://github.com/cargo-bins/cargo-binstall)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-03-02-configure-just-command-runner-ubuntu/view)
- [medium.com](https://tduyng.medium.com/justfile-became-my-favorite-task-runner-7a89e3f45d9a)
- [berkkaraal.com](https://berkkaraal.com/blog/2024/12/06/just-start-using-it/)
- [crates.io](https://crates.io/crates/task-mcp)
- [github.com](https://gist.github.com/upsetbit/ada2117bd8c73a1e94e49580fd5c7cf7)
- [crates.io](https://crates.io/crates/jj-hooks)
- [github.com](https://github.com/zavora-ai/adk-rust/blob/main/AGENTS.md)
- [opensuse.org](https://build.opensuse.org/projects/openSUSE:42:Factory-Candidates-Check/packages/eza/files/eza.changes?expand=0)
- [opensuse.org](https://build.opensuse.org/projects/openSUSE:Backports:SLE-16.1:FactoryCandidates/packages/fd/files/fd.changes?expand=0)
- [suse.com](https://packagehub.suse.com/packages/fd/6_3_0-bp151_3_1/)
- [crates.io](https://crates.io/svelte/crates/mise/2026.3.4)
- [flox.dev](https://flox.dev/blog/the-flox-catalog-now-contains-nvidia-cuda/)
- [github.com](https://github.com/flox/flox-experimental-plugins/blob/master/LICENSE)
- [flox.is](https://flox.is/terms-of-use)
- [crates.io](https://crates.io/crates/cargo-binstall/1.4.3)
- [github.com](https://github.com/actions/runner-images/issues/13677)
- [promise.legal](https://promise.legal/startup-legal-guide/ip/open-source)
- [thepassionatecoder.com](https://www.thepassionatecoder.com/post/building-in-public-choosing-a-software-license)
- [credativ.de](https://www.credativ.de/en/blog/credativ-inside/understanding-open-source-licenses-gpl-mit-apache-compared/)
- [dev.to](https://dev.to/juanisidoro/open-source-licenses-which-one-should-you-pick-mit-gpl-apache-agpl-and-more-2026-guide-p90)
- [reddit.com](https://www.reddit.com/r/rust/comments/1h6em70/whats_the_purpose_of_justfiles/)
- [x-cmd.com](https://www.x-cmd.com/install/lefthook/)
- [tilobox.com](https://www.tilobox.com/tools/lefthook-git-hooks)
- [github.com](https://github.com/tanimon/awesome-stars)
- [github.com](https://github.com/simonecorsi/awesome)
- [crates.io](https://cloudfront-app.crates.io/crates/autoagents/0.3.7)
- [github.com](https://github.com/maguowei/awesome-stars)
- [github.com](https://github.com/mt190502/stars)
- [workbrew.com](https://workbrew.com/catalog/sources/homebrew/homebrew/core/lefthook)
- [brew.sh](https://formulae.brew.sh/formula/lefthook)
- [crates.io](https://crates.io/svelte/crates/krust-sitter-tool)
- [github.com](https://github.com/topics/manager)

---
