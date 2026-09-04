# Deep-research prompt — Standalone security analyzer (R31, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a standalone, dedicated security-focused static analyzer beyond clippy's built-in security-adjacent lints — the Rust analogue of py's `bandit` — and, if so, its hook-tier placement and any exclude configuration. Item kind: `bundle`. Value test: if this answer is wrong, whichever config file (or absence of one), Justfile recipe, `lefthook.yml` job, and CI step the chosen tool needs all get added or removed from the template.

## Context
- Inherited pattern (spec §2, presumption of reuse): py runs a dedicated AST-based security scanner distinct from its linter's own security rule family; ts has no such tool, relying instead on its linter's built-in security-adjacent rules plus a separate CI CodeQL workflow. Evidence: py `.github/workflows/lint.yml:114` — `uv run --no-sync bandit -r src/py_launch_blueprint/ -c pyproject.toml`; `pyproject.toml:267` — `[tool.bandit]` `exclude_dirs`/`skips` config; ts: none (no bandit-equivalent tool in `package.json` or `Justfile`). Ledger rows: F114, F115 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `py-only` — the ledger's own note on F114 frames this as distinct from lint-format's F096 (the linter's own built-in security-rule coverage, owned by R28): this item is whether a *separate* scanner is added on top.
- Per-row evidence for the rest of this bundle: F115 hook-tier placement — py `lefthook.yml:160`, `:161` (`bandit` runs at pre-push, full-tree scan judged too slow per-commit — the same tier rationale ADR-0018 gives for `ty`); ts has no dedicated security scanner to place at any tier.
- Already decided, do not re-open: the linter's own built-in security-rule coverage (clippy's security-adjacent lints, analogous to py's ruff `"S"`/flake8-bandit rule family) is R28's decision (F096), not this item's — this item is only about whether a tool *beyond* that is added. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-014(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Neither Oxlint (no security plugin among its built-ins) nor Biome offers a node-security/bandit equivalent, so the intent is approximated via built-ins plus CodeQL, with the gap honestly documented." ts deliberately chose not to add a standalone scanner and documented the coverage gap rather than closing it.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Make sure there's a security scanner. I don't know if Bandit serves the TypeScript ecosystem, but if it does, we should add it across the board. Same thing with Rust

## Out of scope
- The linter's own built-in security-rule coverage; R28 (`linter-and-editor-tooling`) owns F096 — this item decides only whether a *separate*, dedicated scanner is adopted on top of clippy's built-ins.
- CodeQL's own configuration (query-pack selection, `paths-ignore`); R16 owns F045 (`docs/port/COMMONALITY.md`, area `ci-workflows`) — this item may note that a CI-level SAST workflow exists as complementary coverage, but does not decide its config.
- The shape of the CI job(s) that run the chosen scanner, if any; R11 (`ci-workflow-job-structure`) owns `ci-job-structure`.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R31
- owns:
- consumes: R11: ci-job-structure
- related (not a registry dependency): R28 (`linter-and-editor-tooling`) owns the linter's own built-in security-rule coverage (F096). This item decides only whether a separate, dedicated AST-based security scanner is added on top of whatever clippy config R28 lands on — assume R28's built-in coverage exists and evaluate the marginal case for adding more, do not re-decide clippy's rule selection here.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does `rs-launch-blueprint` adopt a standalone, dedicated security scanner beyond clippy's built-in security-adjacent lints (analogous to py's `bandit`), and if so, which tool and where it runs in the hook/CI pipeline.
- HIGH: What is the Rust ecosystem's `bandit` equivalent — a dedicated AST/pattern-based source-code security scanner distinct from clippy — or does Rust's security tooling instead concentrate on dependency-vulnerability scanning (`cargo-audit`, `cargo-deny`, RustSec-advisory-based) rather than first-party source-code AST scanning, with no direct bandit analogue existing at all?
- HIGH: Given ts explicitly chose NOT to add a standalone scanner and documented the gap (D-014(5)) rather than closing it — does Rust have a stronger or weaker case than ts for adding one, given clippy's own security-adjacent lint coverage and Rust's memory-safety guarantees already eliminate several vulnerability classes bandit targets (e.g. no `eval`/`exec`, no unsafe deserialization by default, no SQL-string-formatting injection without an explicit unsafe API)?
- MEDIUM: If a scanner is adopted, is `cargo-audit`/`cargo-deny` (dependency-vulnerability-focused, checking the dependency tree against RustSec advisories) actually a better-fitting analogue than a source-AST scanner, given bandit's own rule set (hardcoded passwords, shell injection, weak crypto, insecure temp files) maps only partially onto idiomatic Rust source code?
- MEDIUM: If adopted, at what hook tier does it run (F115) — py runs `bandit` at pre-push, on the argument that a full-tree scan is too slow for per-commit (the same rationale ADR-0018 gives for `ty`) — does the candidate tool's scan speed justify the same tier, or is it fast enough for pre-commit?
- LOW: Does the chosen tool (if any) need repo-specific exclude/skip configuration (py's `[tool.bandit]` `exclude_dirs`/`skips`), or does it run clean against this template's structure with no configuration needed?

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
