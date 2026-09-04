# Deep-research prompt — Config discovery tiers (R54, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates or justified custom implementation and reference pattern for the shared layered-configuration principle. Establish which scopes and precedence belong to the shared contract, then research Rust discovery and composition mechanisms that satisfy it. Item kind: `bundle`. Value test: if this answer is wrong, configuration discovery, layer merging, override behavior and the CLI configuration contract all change.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2, evidence subject to A5 — origin `py-only`, so treat cautiously): py separates config discovery into a layered chain — system config dirs → user config dir → project-local file, later wins — each layer merged, with `--config` overriding discovery entirely rather than adding a layer; ts has only a single per-user default path, no system or project tier. Evidence: py `src/py_launch_blueprint/core/config.py:134` — `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]`; py `src/py_launch_blueprint/core/paths.py:108` — `def config_dirs() -> list[Path]:` (multi-dir, Windows `%PROGRAMDATA%` fallback); py `src/py_launch_blueprint/core/paths.py:184` — `def project_config_file(start: Path | None = None) -> Path:`; py `src/py_launch_blueprint/cli/options.py:107` — `envvar="PLBP_CONFIG",`; ts has none of these tiers or the env alias. Ledger rows F230, F231, F232, F234 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `--config` replaces discovery entirely rather than adding a layer (F233, `COMMON → REUSE`, inherited as-is — both repos already agree, this is not part of this item's decision); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-017(1) and D-017(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — D-017(1) records the *canonical* config precedence as "`TOML <tool>_config.toml` under `$XDG_CONFIG_HOME/<tool>` with cli-standards R5.1 precedence (flags > TOOL_* env > project > user > system > defaults)," but D-017(3) shows ts's shipped `xdg-paths` module is a hand-rolled ~30-line resolver of only the per-user `$XDG_CONFIG_HOME`/`~/.config/<tool>` directory — ts's own decision record names the full chain as the target while its implementation realizes only the user tier. Treat this gap as live context for this item, not as settled.

## Out of scope
- Whether an unparsable discovered layer degrades to a warning versus a crash, and whether invalid individual values are dropped; R55 (`config-error-tolerance`) owns F235/F236/F238 — this item decides how many tiers exist and where they live, not how parse/validation failures in any tier are handled.
- Whether the config file may carry a secret/token; R56 (`config-secret-policy`) owns F239/F240/F245 — this item's discovery tiers are secret-policy-agnostic.
- The separate XDG data/state/cache directory set beyond config; R57 (`xdg-directory-set`) owns F249 — this item only concerns the config-discovery search path, not data/state/cache dirs.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R54
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R55 (`config-error-tolerance`) decides how a missing/unparsable/invalid layer this item discovers is handled. R56 (`config-secret-policy`) decides whether any tier this item discovers may carry a token. R57 (`xdg-directory-set`) decides the broader XDG directory set beyond config.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how Rust realizes the shared layered-configuration principle, which scopes and precedence belong to the cross-repo contract, and which library or custom discovery/composition pattern best implements them.
- HIGH: Is there a Rust crate (e.g. `directories`, `etcetera`, `xdg`) that already enumerates a platform's system-wide config directories (`$XDG_CONFIG_DIRS` on Linux and its equivalents) the way py's `paths.config_dirs()` does, or does this need hand-rolled logic (as ts's own `xdg-paths` module is, per D-017(3))?
- HIGH: Capture the layered-configuration principle explicitly. Which scopes and override semantics are shared requirements, supported by the owner direction and the cited standard, and which are source implementation details? Evaluate the cited flags > env > project > user > system > defaults order against the intended behavior. Compare library-based layering and a small custom implementation; specify how tests prove discovery, merging, precedence, missing files and invalid values without silently reducing the example to a single configuration tier.
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What is the idiomatic Rust pattern for a project-local upward directory search (matching py's `project_config_file()` cwd-relative discovery) — a hand-rolled walk-up loop, or a crate?
- MEDIUM: Is the `--config` env-var alias (F234) a plain `clap` `env(...)` attribute, or does it need custom precedence logic interacting with the discovery layers?
- LOW: Do any published Rust CLI templates implement a multi-tier config discovery chain, for comparison?

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

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
The full `crate` field set for each member.
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
