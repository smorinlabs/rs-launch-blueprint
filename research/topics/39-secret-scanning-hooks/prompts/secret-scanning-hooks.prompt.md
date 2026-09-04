# Deep-research prompt — Secret-scanning hooks (R39, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of tools and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a staged pre-commit secret scanner and a pre-push range secret scanner (py's gitleaks pair), and if so, how its allowlist and per-finding fingerprint-suppression file are configured. Item kind: `bundle`. Value test: if this answer is wrong, the pre-commit and pre-push hook jobs, the scanner's allowlist config file, and its fingerprint-suppression file all get added, removed, or rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py runs gitleaks at two git-hook tiers — a staged-diff scan on every commit and a push-range scan covering the about-to-be-pushed commit range — backed by a path/pattern allowlist and a separate per-finding fingerprint-suppression file. ts has no secret-scanning tool at any git-hook tier. Evidence: py `lefthook.yml:73` — `gitleaks` job runs `scripts/check-gitleaks.sh --staged` on every commit; ts: none. Ledger rows: F163, F164, F165, F166 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `py-only` for all four.
- Per-row evidence: F163 staged secret-scanning hook — py `lefthook.yml:73` (`gitleaks` job runs `scripts/check-gitleaks.sh --staged` on every commit); ts: none. F164 pre-push range secret-scanning hook — py `lefthook.yml:156` (`gitleaks-range` job runs `scripts/check-gitleaks.sh --range`, scanning the about-to-be-pushed commit range, catching secrets in commits that bypassed the staged hook — imported history, `--no-verify`); ts: none. F165 secret-scanner allowlist configuration — py `.gitleaks.toml:10` (`[allowlist]` narrows by path — docs/Markdown — and two named AWS example-key regexes); ts: none. F166 secret-scanner fingerprint suppression file — py `.gitleaksignore:1` (per-finding fingerprint allowlist, empty at this pinned commit, distinct from the pattern/path allowlist in `.gitleaks.toml`); ts: none.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). One researched parameter this item consumes is still open (no `DECISION.md` yet): `ci-job-structure` (R11) — design any CI-side re-run to fit whichever job structure R11 eventually picks; do not block on it.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing secret scanning at any git-hook tier; ts simply never adopted gitleaks or an equivalent.

## Out of scope
- The git hook manager itself — its distribution/install mechanism and the full-hook-suite CI re-run; R37 (`hook-manager-distribution`) owns F143/F144/F174 — this item picks the secret-scanning tool and its config, not the manager wrapping the pre-commit/pre-push stages it runs inside.
- Any dependency-vulnerability-scanning workflow; R13 (`dependency-vulnerability-scanning`) owns that concern — do not conflate the two.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R39
- owns:
- consumes: R11: ci-job-structure
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R37 (`hook-manager-distribution`) owns the hook manager and its stage tiering this item's scanner jobs would run inside; this item does not re-decide the manager.

## Questions
Decision: whether `rs-launch-blueprint` adopts gitleaks (or an alternative) as a staged pre-commit secret scanner and a pre-push range scanner, and how its allowlist and fingerprint-suppression file are configured.
- HIGH: Is gitleaks itself (a standalone Go binary, language-agnostic, already used by py) the right tool to keep as-is for a Rust template, or does the Rust ecosystem have a native alternative worth comparing (e.g. a `git-secrets`-style approach, or a Rust-native scanner)? What are the maintenance-state and installation-footprint trade-offs of pulling in a Go binary versus staying tool-agnostic?
- HIGH: How should the two-tier scan (staged diff at pre-commit, commit-range at pre-push) be invoked in a Rust template's hook config — a direct `gitleaks protect --staged`/`gitleaks detect --log-opts=<range>` invocation, or a wrapper script mirroring py's `scripts/check-gitleaks.sh`?
- MEDIUM: What allowlist configuration (path exemptions, named regex exemptions for known example/test secrets) is appropriate for a Rust CLI + library + web template, and should it start from py's `.gitleaks.toml` narrowed-by-path pattern or be built fresh?
- MEDIUM: Should the fingerprint-suppression file (`.gitleaksignore`-equivalent) ship pre-populated or empty, matching py's empty-at-baseline precedent?
- LOW: Does the chosen scanner need any CI-side re-run beyond the local hooks (a `gitleaks detect` full-history scan job), and if so, where would it sit given `ci-job-structure` (R11) is still undecided?
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
