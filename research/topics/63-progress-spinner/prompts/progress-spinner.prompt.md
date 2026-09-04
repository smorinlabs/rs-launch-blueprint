# Deep-research prompt — Progress spinner (R63, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: which Rust crate renders a stderr progress spinner during `rs-launch-blueprint`'s network fetch, gated on stderr TTY-ness and the absence of a CI environment variable. Item kind: `crate`. Value test: if this answer is wrong, the spinner dependency, the call site wrapping the network fetch, and its TTY/CI gating logic all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): this row is ts-only — py ships no progress indicator during its fetch to compare against. ts shows a stderr spinner during the network fetch, gated on stderr TTY-ness and the absence of a `CI` environment variable. Evidence: ts `src/commands/projects.ts:129` — `const spinner = spinnerEnabled ? deps.spinner('Fetching projects...') : undefined;`; ts `src/commands/projects.ts:127` — `const ci = deps.env['CI'];` (gate input). Ledger row: F283 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — `yocto-spinner` on stderr (its default), additionally gated on `process.stderr.isTTY` and the `CI` env var; chosen because "stderr-by-default satisfies cli-standards R7.1 (progress=diagnostics) and fixes the source wart where progress text polluted stdout," and over `ora` specifically to avoid a `chalk`+`picocolors` double color-library stack. D-033 additionally notes the shipped implementation "guards the spinner against 0-column TTYs."

## Out of scope
- The TTY-detection mechanism used to gate the spinner; R65 (`color-enablement-chain`) owns F290's TTY-detection mechanism — this item reuses whatever R65 selects, it does not redecide how TTY-ness is checked.
- Color enablement precedence and NO_COLOR/FORCE_COLOR handling; R65 (`color-enablement-chain`) owns F287-F289 — this item's spinner is a plain progress indicator, not colored text.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R63
- owns:
- consumes:
- related (not a registry dependency): R65 (`color-enablement-chain`) decides F290's TTY-detection mechanism; this item's spinner-gating logic should reuse whatever check R65 lands on rather than implementing a second, divergent TTY check, but R65 registers no parameter this item formally consumes.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust crate renders a stderr progress spinner during the network fetch, gated on stderr TTY-ness and the absence of a `CI` environment variable.
- HIGH: Is `indicatif` — the dominant general-purpose Rust progress/spinner crate — the right fit, or does its progress-bar-and-multi-progress feature surface make a lighter, spinner-only crate a closer match to `yocto-spinner`'s minimal footprint?
- HIGH: Does the candidate crate default to writing on stderr, or does it need explicit configuration to avoid contaminating stdout — a hard requirement given the template's JSON output on stdout must stay pure?
- MEDIUM: What is the idiomatic way to gate the spinner on the absence of a `CI` environment variable in Rust — reading `std::env::var("CI")` directly, or is there a crate convention for this that composes with whatever TTY check R65 selects?
- MEDIUM: Does the candidate crate degrade gracefully on a 0-column-width terminal (the shipped ts implementation explicitly guards against this per D-033), and if not, what wrapping does the template need to add?
- LOW: Does the candidate crate support being disabled entirely via a runtime flag (composing with `--quiet`/`--no-input`), or does that gating have to live in the call site rather than the crate?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).

## Required evidence
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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

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

### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
