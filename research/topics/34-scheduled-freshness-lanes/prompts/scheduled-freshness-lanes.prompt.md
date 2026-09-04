# Deep-research prompt — Scheduled freshness lanes (R34, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and GitHub Actions patterns (with versions) for: whether `rs-launch-blueprint` runs a scheduled workflow that tests against upgraded/newest dependencies to catch breakage early, and whether it runs a non-blocking advisory test lane against an alternate toolchain (e.g. a beta or nightly Rust). Item kind: `bundle`. Value test: if this answer is wrong, the repository's scheduled-workflow file(s), any `--upgrade`-equivalent dependency-resolution step, and any advisory alternate-toolchain CI job all get added, removed, or rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge in opposite directions. py runs a weekly scheduled canary workflow that upgrades dependencies and re-runs the suite; ts has no such workflow but instead runs an advisory, non-gating test lane under an alternate JS runtime (Bun) on every regular run, not on a schedule. Evidence: py `.github/workflows/canary.yml:16` — weekly cron; `.github/workflows/canary.yml:47` — `uv sync --upgrade` (WL-012); ts: no `canary.yml` or equivalent scheduled workflow exists. Ledger rows: F126, F127 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `py-only` (F126) and `ts-only` (F127).
- Per-row evidence: F126 scheduled dependency-freshness canary — py `.github/workflows/canary.yml:16` (weekly cron trigger), `.github/workflows/canary.yml:47` (`uv sync --upgrade` resolves to the newest allowed versions before running tests, work label WL-012); ts: none. F127 advisory alternate JS runtime test lane — ts `Justfile:169` (`bun run vitest run --exclude tests/e2e.test.ts`, non-gating, decision D-036); py: none. Rust's plausible analogue of F127 is a non-blocking alternate-toolchain (e.g. Rust `beta` or `nightly`) test lane rather than an alternate package manager, since Rust has no second competing toolchain-installer ecosystem the way JS has Bun vs. Node.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-036 (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — Bun 1.3.14 as an optional, advisory dev/test runtime lane (`bun run vitest run` for in-process tiers, Node-only for the e2e subprocess tier), non-required CI job via `oven-sh/setup-bun`; installs stay pnpm-only, `bun install` is never run so no `bun.lock` forms; chosen because Bun tracks Node parity roughly one major behind, hence advisory rather than gating.

## Out of scope
- The base test runner and its execution-behavior configuration; R32 (`test-harness-and-execution`) owns F117/F118/F124/F125/F128-F132/F173 — this item decides only whether a scheduled or advisory-lane workflow exists, not the harness those workflows invoke.
- Dependency-vulnerability scanning workflows; R13 (`dependency-vulnerability-scanning`) owns that — do not conflate a freshness canary with a security-advisory scan.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R34
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base test runner and tiers this item's scheduled/advisory workflows would invoke; this item does not re-decide the runner.

## Questions
Decision: whether `rs-launch-blueprint` runs a scheduled dependency-freshness canary (Rust analogue of `uv sync --upgrade` on a weekly cron) and/or a non-blocking advisory alternate-toolchain test lane (Rust analogue of the Bun lane), and if so, how each is implemented.
- HIGH: What is the idiomatic Rust equivalent of `uv sync --upgrade` for a freshness canary — `cargo update` against the loosest `Cargo.toml` version bounds followed by `cargo test`, run on a weekly `schedule:` trigger, non-blocking to the default branch's merge gate?
- HIGH: Is there a meaningful Rust analogue to ts's advisory Bun lane — e.g. an advisory `nightly` or `beta` Rust toolchain job via `dtolnay/rust-toolchain`, run non-gating (`continue-on-error: true`) to give early warning of upcoming stable-Rust breakage — or does Rust's own stable/beta/nightly cadence make this lower-value than the JS-runtime case it mirrors?
- MEDIUM: Should the freshness canary open an issue or fail loudly on breakage, matching py's `canary.yml` intent, and what is the current idiomatic GitHub Actions pattern for that (e.g. `actions/github-script`, a dedicated issue-filing action)?
- MEDIUM: What crates or actions handle the dependency-upgrade step itself — plain `cargo update`, or a crate like `cargo-edit`'s `cargo upgrade` for bumping semver-incompatible ranges too?
- LOW: What CI concurrency/cost guardrails (schedule frequency, job timeout) keep a weekly canary from becoming noisy or expensive on a public template repo?
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
