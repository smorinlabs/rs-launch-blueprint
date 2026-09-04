# Deep-research prompt — XDG directory set (R57, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint` resolves a full XDG-style directory set (separate config/data/state/cache directories) or only a config directory, matching py's four-directory shape versus ts's config-only shape. Item kind: `pattern`. Value test: if this answer is wrong, the paths module's public directory-accessor functions — how many exist, and which one a file-log sink or crash log points at — get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse; origin `py-only`, so treated as `DIVERGENT` rather than a straight inheritance): py resolves four separate XDG-style directories (config, data, state, cache); ts resolves only a config directory, because it has no log file or local database that would need a data/state/cache path. Evidence: py `src/py_launch_blueprint/core/paths.py:130` — `def data_home()`, `def state_home()`, `def cache_home()` (alongside the existing config-dir accessor); ts `src/lib/xdg-paths.ts:21` resolves only a config directory — no data/state/cache dirs exist in ts because there is no log file or local database to place in them. Ledger row F249 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item was deliberately kept standalone rather than folded into R59 (`file-log-sink`) at the Task 10 reconciliation, because the directory set this item resolves is consumed by both R59 (a file-sink default path) and R67 (a crash-log path) — folding it into R59 would hide the R67 dependency inside another item.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built data/state/cache directory accessors (only config), so `TS_PORT_DECISIONS.md`'s D-017(3) (which covers only the config-dir XDG override mechanism) has no data/state/cache entry to carry forward.

## Out of scope
- The config directory itself and its override mechanism (`$XDG_CONFIG_HOME`, absoluteness check); F231 is covered by R54 (`config-discovery-tiers`, system-wide config dir) and F247 is `COMMON → REUSE`, already inherited — this item decides only whether *additional* data/state/cache directories exist, not the config directory's own resolution.
- Whether a file log sink actually uses a state-directory default path, and its rotation/precedence rules; R59 (`file-log-sink`) owns F256-F261 — this item only decides whether the directory-accessor functions exist and where they point, not who consumes them.
- The crash-log file's own existence, format, and write-failure handling; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` and the crash-log path is cross-referenced there — this item supplies the directory the crash log would live under, if any, not the crash-log mechanism itself.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R57
- owns:
- consumes:
- related (not a registry dependency): R59 (`file-log-sink`) — F258's default file-sink path is the state directory this item would resolve, if adopted; R59 does not require this item to land first, since it may default to a hardcoded/relative path if this item concludes no data/state/cache set is needed. R67 (`error-and-exit-code-contract`) — the crash-log path would also consume this item's state directory, if adopted.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does `rs-launch-blueprint` resolve a full XDG-style directory set (config, data, state, cache) as separate accessor functions, or only a config directory, given nothing in the template yet definitely needs a data/state/cache path.
- HIGH: Is there a Rust crate (e.g. `directories`, `etcetera`, `xdg`) that already resolves the full XDG Base Directory Specification (config/data/state/cache) the way py's `paths.py` module does by hand, and does adopting one now (ahead of R59/R67 confirming they need it) cost anything if the answer turns out to be "config-only, like ts"?
- HIGH: Should this item's recommendation be contingent — resolve the full set now because R59 (file-log sink) and R67 (crash log) are both open items in this same batch/program that plausibly need a state path — or should it default to ts's minimal shape and let R59/R67 add directory accessors only if their own research concludes they're needed?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).
- MEDIUM: Does the candidate crate handle the Windows-analogue directories (`%LOCALAPPDATA%`, `%PROGRAMDATA%`) even though `target-os-matrix` excludes Windows from CI — is carrying that capability free, or does it add meaningful complexity/dependencies for an unused path?
- MEDIUM: What is the idiomatic Rust surface for these accessors — free functions (matching py's `data_home()`/`state_home()`/`cache_home()`), or a struct with methods?
- LOW: Do any published Rust CLI templates or style guides document a full XDG directory-set pattern, for comparison?

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
