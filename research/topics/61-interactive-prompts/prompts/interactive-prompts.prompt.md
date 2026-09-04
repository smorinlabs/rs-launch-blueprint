# Deep-research prompt — Interactive prompts (R61, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts an interactive-prompt crate for a yes/no confirmation prompt before destructive actions, a guided free-value prompt during `config init`, and a multi-select prompt over fetched results — and, if so, which crate and what shape each of the three prompt types takes. Item kind: `bundle`. Value test: if this answer is wrong, whether an interactive-prompt dependency exists at all, and the call sites and types backing the confirm/guided-value/multi-select prompts, all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py and ts each ship a different half of this bundle, with no overlap. py ships a yes/no confirm gate and a guided value prompt; ts ships a multi-select checkbox over fetched results. Evidence: py `src/py_launch_blueprint/cli/options.py:278` — `return click.confirm(prompt, default=False, err=True)`; py `src/py_launch_blueprint/cli/commands/config.py:94` — `chosen[dotted] = click.prompt(`; ts `src/commands/projects.ts:157` — `selected = await deps.prompter(`, `src/lib/adapters.ts:41` — `realPrompter`. Ledger rows: F276, F279, F280 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `--dry-run` (F277) and `-y`/`--yes` (F278) are plain mutation-safety flags, `ADOPT` verdict, attached via `mutation_options` to `config init`/`config set` — they exist independently of whatever this item decides about a prompt crate; do not redesign them here, only ensure the confirm prompt composes with them. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(6) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — `@inquirer/prompts` checkbox with context `{ output: process.stderr }`, questionary-parity `Choice{name,value}` objects, empty-selection exit 0, plus a documented non-TTY/`--no-input` path behind one injectable seam; chosen over `@clack/prompts` for its documented stderr output-stream context and first-party testing package.
- Behavioral fork under the shared `--no-input` flag (F360, split from F275 at the Phase 4 review): py refuses to proceed with a `ConfigError` unless `--yes` was passed (`src/py_launch_blueprint/cli/options.py:273`); ts skips the prompt and selects every fetched result (`src/commands/projects.ts:146`, D-016(6)). Ledger row F360 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.

## Out of scope
- Which CLI-parsing framework hosts the commands these prompts attach to; R60 (`cli-parsing-framework`) owns that bundle — this item's crate choice only needs to compose with whatever R60 selects.
- The exit-code contract for a prompt cancelled mid-interaction (^C during a multi-select); R67 (`error-and-exit-code-contract`) owns F299 — this item decides only whether/which interactive-prompt crate is adopted and how each prompt type is shaped, not the cancellation exit code.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R61
- owns:
- consumes:
- related (not a registry dependency): R67 (`error-and-exit-code-contract`) owns F299 (interactive-prompt cancellation), which is contingent on this item adopting an interactive-prompt crate at all — R67 needs to know only whether a crate exists, not any registered parameter value from this item.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts an interactive-prompt crate, and if so, which crate, and what shape the confirm, guided-value, and multi-select prompt types take.
- HIGH: Is there a single Rust crate that covers all three interactive-prompt shapes py and ts use — a yes/no confirm (F276), a guided free-value prompt (F279), and a multi-select checkbox over a list (F280) — e.g. `dialoguer`, `inquire`, or does the template need to combine crates to cover all three?
- HIGH: For the multi-select prompt, does the candidate crate render `Choice`-style name/value pairs the way ts's `@inquirer/prompts` checkbox does (D-016(6)), and does it support an explicit output-stream override so prompts render on stderr, not stdout?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.
- MEDIUM: What happens to each prompt type when stdin/stdout is not a TTY, or when `--no-input` is set — does the candidate crate detect a non-interactive context itself, or does the template need to gate calls behind its own TTY check before invoking the crate?
- MEDIUM: Does the confirm and guided-value prompt need default-value support and input validation/retry, matching `click.prompt`/`click.confirm`'s behavior, and does the candidate crate provide that natively or does the template have to build it?
- LOW: Do `--dry-run` and `-y`/`--yes` (F277/F278, already-decided plain flags) compose cleanly by skipping the confirm-prompt call entirely, or does the confirm-prompt crate need its own explicit bypass mechanism?
- MEDIUM: Under `--no-input`, does rs refuse the action unless `--yes` (py, F360) or proceed with the non-interactive default such as select-all (ts)? Name one behavior for all three repos as part of the cross-repo answer.

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
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
