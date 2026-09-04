# Deep-research prompt — Pager integration (R64, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` pages long text-mode output through the user's pager, and, if adopted, what Rust crate/pattern resolves the pager command (an app-specific env var taking precedence over the generic `PAGER`, falling back to `less -FRX`) and invokes it. Item kind: `bundle`. Value test: if this answer is wrong, whether a paging dependency exists at all, and the output-rendering function's paging gate plus the pager-command resolution precedence, get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): this bundle is py-only — ts ships no pager integration to compare against. py pages long text-mode output through the user's pager when output is a terminal, resolving the pager command through an app-specific env var before the generic `PAGER`, falling back to `less -FRX`. Evidence: py `src/py_launch_blueprint/cli/output.py:177` — `if not (self.paging and self.out.is_terminal and _isatty(self.out)):` (the paging gate); py `src/py_launch_blueprint/cli/output.py:88` — `for var in ("PLBP_PAGER", "PAGER"):` (resolution precedence), falling back to `less -FRX` (`src/py_launch_blueprint/cli/output.py:56`). Ledger rows: F284, F285 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; ADR 0008.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision on pager integration; ts's CLI has no long-form text output mode to page in the first place, so the absence was never a considered-and-rejected choice.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Looking at architectural pattern, not the exact library. We'd like a similar pager pattern for TypeScript and Rust.

## Out of scope
- Which output formats exist (text/json/csv and any file-redirection flag); R66 (`output-format-surface`) owns F291/F293 — this item decides only whether/how the text-mode format gets paged, not which formats exist.
- The TTY-detection mechanism used to gate paging; R65 (`color-enablement-chain`) owns F290's TTY-detection mechanism — this item reuses whatever check R65 selects for "is this stream a terminal," it does not redecide that check.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R64
- owns:
- consumes:
- related (not a registry dependency): R65 (`color-enablement-chain`) decides F290's TTY-detection mechanism; this item's paging gate ("is stdout a terminal") should reuse whatever check R65 lands on rather than implementing a second, divergent TTY check, but R65 registers no parameter this item formally consumes.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` pages long text-mode output through the user's pager, and if so, what Rust crate/pattern resolves and invokes the pager command with the app-specific-env-var-then-`PAGER`-then-`less -FRX` precedence.
- HIGH: Is paging worth adopting for a Rust CLI template at all, given ts ships no equivalent and no ts decision record even considered it — does the template's typical text-mode output length justify a pager, or should this row be recommended for omission?
- HIGH: If adopted, what Rust crate or pattern spawns and pipes output to an external pager subprocess while preserving ANSI color codes through the pipe (matching `less -FRX`'s `-R` "raw control chars" flag) — is there a maintained `pager`-invocation crate, or does the template hand-roll `std::process::Command` plumbing?
- MEDIUM: What env-var precedence should the pager lookup follow — an app-specific override (renamed from py's `PLBP_PAGER`) before the generic `PAGER`, matching py's two-tier chain — and what happens when neither is set and `less` itself is not installed (some minimal Linux images, and Windows, ship no `less`)?
- MEDIUM: Does paging need the same "is this stream a terminal" gate R65 selects for color (F290), or does the paging gate need to check a different stream (py checks `self.out`, the primary output stream) than whatever stream R65's color gate checks?
- LOW: Given `target-os-matrix` excludes Windows from CI, should paging be conditionally compiled or documented as POSIX-only, or does a maintained cross-platform pager crate make that unnecessary?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.

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
