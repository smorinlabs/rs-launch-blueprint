# Deep-research prompt — CodeQL config customization (R16, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint`'s CodeQL scan uses a custom configuration file selecting a broader query pack and excluding test/docs paths from analysis (py's shape), or runs with the tool's bare default configuration and no `config-file:` input (ts's shape). Item kind: `pattern`. Value test: if this answer is wrong, `.github/codeql/codeql-config.yml` either gets added with the wrong query-pack/paths-ignore settings or gets omitted, and the CodeQL scan either surfaces noisy findings from test fixtures and generated docs or misses vulnerability classes the default query pack does not cover.

## Context
- Inherited pattern (spec §2, presumption of reuse): py supplies a custom CodeQL configuration file that selects the broader `security-extended` query pack (beyond CodeQL's narrower default query set) and excludes `tests/**` and `docs/**` from analysis via `paths-ignore`, referenced from the CodeQL workflow's Init step. ts's CodeQL Init step has no `config-file:` input at all — it runs with CodeQL's bare default configuration, no extended query pack, and no path exclusions. Evidence: py `.github/codeql/codeql-config.yml:11` — `security-extended` queries, ignores `tests/**` and `docs/**`; referenced from `.github/workflows/codeql.yml:63`; ts `.github/workflows/codeql.yml:105` — CodeQL Init step has no `config-file:` input. Ledger row: F045 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: the CodeQL workflow itself — including its runtime-visibility gate that skips the scan on unlicensed private repos, and the language/build-mode matrix — is already inherited as-is (F027, `docs/port/COMMONALITY.md`, `COMMON → REUSE`; both repos use the same `repository-visibility` gating pattern) — this item decides only whether a custom `codeql-config.yml` is added on top of that shared workflow, not the workflow's trigger or gating mechanics. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none found — D-022(4) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) covers only "CodeQL workflow → Port near-verbatim with matrix {language: javascript-typescript, build-mode: none} and bump github/codeql-action v3 → v4," with no discussion of a custom `config-file:`/query-pack/paths-ignore decision; the config-file omission appears to be an unexamined gap in the port, not a considered rejection.

## Out of scope
- The CodeQL workflow's trigger, its runtime-visibility gate, and the language/build-mode matrix; already inherited as-is (F027, `COMMON → REUSE`) — this item decides only whether a custom config file is layered on top.
- The standalone AST-based security static analyzer beyond CodeQL/the linter's built-in security rules; R31 (`standalone-security-analyzer`) owns F114/F115 — a distinct tool from CodeQL, not this item's concern.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R16
- owns:
- consumes:
- related (not a registry dependency): none.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships a custom CodeQL configuration file selecting an extended query pack and excluding test/docs paths, or runs with CodeQL's bare default configuration.
- HIGH: Does CodeQL's Rust support (a newer analysis target than its Python/JavaScript-TypeScript extractors) offer a `security-extended`-equivalent query pack, and does that pack meaningfully broaden vulnerability-class coverage over CodeQL's default query set for Rust the way py's evidence shows it does for Python?
- HIGH: Does a Rust template's test/fixture layout (whatever shape R32's `test-harness-and-execution` decision produces) warrant a `paths-ignore` exclusion the way py excludes `tests/**` and `docs/**` — i.e., does CodeQL's default analysis surface noisy or irrelevant findings from Rust test code or generated `target/`/`docs/` output that a path exclusion would suppress?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). The divergence analysis marked this item harmonize: no; the owner asked for the cross-repo answer anyway, so answer it in full.
- MEDIUM: What is CodeQL's current (retrieval-date) support maturity for Rust specifically — is Rust a first-class, generally-available CodeQL language, or still in beta/experimental status, and does that maturity level change whether investing in a custom config (versus waiting on defaults to mature) is worth it now?
- LOW: If a custom config is adopted, does it need any Rust-specific `paths-ignore` beyond `tests/**` — e.g., `target/` (build output, though typically gitignored and thus already excluded from analysis) or any generated-code directories a Rust build produces?

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

### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
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
