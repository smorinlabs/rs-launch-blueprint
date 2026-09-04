# Deep-research prompt — Rich terminal row niceties (R85, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint`'s text-mode table renderer adds terminal-only presentation niceties — OSC-8 hyperlinks and relative timestamps — on top of the plain row data every other output format uses, and how that hook composes with JSON/CSV output staying plain. Item kind: `pattern`. Value test: if this answer is wrong, the row-model hook that supplies terminal-only markup, the relative-time and hyperlink-escaping helpers, and the text renderer's fallback to plain rows all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): this row is py-only — ts ships no terminal-only row presentation to compare against. py's result models expose a `table_rows_rich()` hook that defaults to the plain `table_rows()` implementation; models that override it add terminal-only markup (OSC-8 hyperlinks, relative timestamps) consumed only by the text renderer — JSON and Markdown output always render the plain row data. Evidence: py `src/py_launch_blueprint/core/models.py:59` — `def table_rows_rich(self) -> list[list[str]]:` — docstring: "Row cells for the *text* renderer only — may carry rich markup. Override to add terminal niceties (OSC-8 hyperlinks via..."; py `src/py_launch_blueprint/core/format.py:46` — `def relative_time(moment: datetime, *, now: datetime | None = None) -> str:` — renders a coarse human delta ("2 days ago" / "in 3 hours"), with anything under a minute rendered as "just now"; py `src/py_launch_blueprint/core/format.py:73` — `def rich_link(text: str, url: str) -> str:` — OSC-8 hyperlink markup, escaping `text` so a path containing `[` renders literally rather than being parsed as markup, while the URL needs no escaping; py `src/py_launch_blueprint/cli/output.py:237` — `for row in result.table_rows_rich():` — the text renderer's consumption point, with a comment noting Rich strips styling itself for non-terminal destinations (pipes, files). Ledger row: F359 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; ADR `docs/adr/0010-rich-row-variant-on-result-models.md`. This row was found late, during the Task 11 coverage sweep, because no earlier surveyor had read `core/models.py`/`core/format.py` — the evidence above is the full extent of what has been read; there may be other rich-only presentation methods on py's result models not yet cited.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision on OSC-8 hyperlinks, relative timestamps, or any terminal-only row presentation; ts's table rendering has no rich/plain distinction to have made a choice about.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, this is a more mature version for Python. We should find the equivalencies and best practices for TypeScript and Rust.

## Out of scope
- Which output formats exist (text/json/csv) and the base row-rendering machinery each format uses; R66 (`output-format-surface`) owns F291/F293 — this item decides only the additive terminal-only markup layered on top of the text format's rows, not the underlying row or format machinery itself.
- The color-enablement precedence chain and TTY-detection mechanism that gates whether ANSI/OSC-8 escape codes render at all; R65 (`color-enablement-chain`) owns F287-F290 — this item's hyperlink and relative-time helpers must respect whatever gate R65 selects, not redecide it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R85
- owns:
- consumes:
- related (not a registry dependency): R66 (`output-format-surface`) decides which output formats exist and the base text-mode row shape; this item's terminal-only row variant is layered on top of whatever row-rendering shape R66's answer produces. R65 (`color-enablement-chain`) decides the TTY-detection and color-gating mechanism; this item's hyperlink escape codes must only render when R65's gate allows it, and R65 registers no parameter this item formally consumes.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s text-mode table renderer adds terminal-only presentation niceties (OSC-8 hyperlinks, relative timestamps) on top of plain row data, and if so, what Rust pattern implements the per-model opt-in hook, the relative-time formatter, and the hyperlink-escaping helper.
- HIGH: What is the idiomatic Rust equivalent of py's `table_rows_rich()` hook — a trait method with a default implementation that falls back to the plain row-rendering method, or a separate wrapper/newtype the CLI layer applies conditionally to models that opt in?
- HIGH: Is there a Rust crate that already implements OSC-8 terminal hyperlinks with graceful non-terminal fallback (matching Rich's "emits escape codes only on terminals that support them, falls back to plain text everywhere else"), or does the template need to hand-roll the escape sequence and its own terminal-support detection?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).
- MEDIUM: Is a relative-time formatter ("2 days ago" / "in 3 hours", floor "just now" under a minute) available as a maintained crate, or does it need a small hand-rolled helper matching py's coarse day/hour/minute bucket list?
- MEDIUM: How should the hyperlink helper escape link text so it cannot be misinterpreted as markup/formatting syntax by whatever text-table-rendering crate the template uses, avoiding the injection risk py's `rich_link()` explicitly guards against?
- LOW: Given this row was found late in the coverage sweep with no full read of `core/models.py`/`core/format.py` by any earlier surveyor, are there other rich-only presentation methods on py's result models worth surfacing during the deep-research pass, even though this item's decision is scoped to the hook, hyperlink, and relative-time methods cited here?

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
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
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
