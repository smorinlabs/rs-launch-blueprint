# Deep-research prompt — Docs correctness gate (R82, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint` gates documentation correctness in CI — offline/internal relative-link checking, external URL link checking, and API-reference doc generator (rustdoc) correctness — replacing py's `sphinx-build -W` (autodoc/cross-reference errors) plus a weekly external-linkcheck job, and ts's `check-links.mjs` (internal-link resolution only, no external check). Item kind: `bundle`. Value test: if this answer is wrong, the CI docs-check job/step, the link-checker tool and its config, and the `cargo doc`/rustdoc CI-gating flags all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge on doc-correctness gating. py's CI runs `sphinx-build -W`, which fails the PR on any broken cross-reference or autodoc error, and separately runs a weekly `sphinx-build -b linkcheck` job for external URLs. ts's CI runs `just docs-check` (a dependency-free Node script, `scripts/check-links.mjs`) that fails the PR on any broken *relative* link only — no external-URL checking exists in ts. Evidence: py `.github/workflows/ci.yml:242` — `sphinx-build -W -b html docs/source docs/_build/html`; ts `.github/workflows/ci.yml:98` — `just docs-check` (`scripts/check-links.mjs`). Ledger rows: F348, F349, F350, F353 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F349 offline relative-link checker tool — py: none; ts `scripts/check-links.mjs:1` (dependency-free Node script walking `README.md` + `docs/` for unresolved relative-link targets, chosen over `lychee`/`markdown-link-check` per the script's own header comment because neither was installed on the CI image at port time). F350 external URL link-check — py `.github/workflows/dep-audit.yml:69` (weekly `sphinx-build -b linkcheck` job); ts: none (no decision entry addresses external-URL checking specifically). F353 API reference doc generator — py `docs/source/conf.py:27` (`sphinx.ext.autodoc`, wired but zero directives used, latent); ts `Justfile:203` (TypeDoc, wired as optional `just docs-api`, not CI-gated) — both repos match a "configured-but-unused" latent-investment posture; this row moved from R81 to R82 at the Task 10 reconciliation because rustdoc ships with every Rust toolchain and is not contingent on R81's docs-delivery-model pick.
- Already decided, do not re-open: what docs tree or site this gate checks (mdBook-style site vs. plain-markdown tree, markdown dialect, section navigation) is R81's decision (F341/F343/F344), still open — assume R81 resolves to *some* tree of markdown files, possibly built into a site, and design a correctness gate that works against either shape; `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-023(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — replaced Sphinx's build-time correctness gate with "a markdown link-checker (`just docs-check`)" as part of omitting the Sphinx machinery entirely; D-023(4) — ported the API-reference doc generator to "TypeDoc 0.28.20 + typedoc-plugin-markdown 4.12.0 wired as an optional `just docs-api` recipe... not gated in CI — mirroring the source's configured-but-unused autodoc," the same latent posture this item's rustdoc equivalent must decide whether to preserve or upgrade to CI-gated.

## Out of scope
- The docs delivery model itself — whether a generated hosted site or a plain-markdown tree exists, its markdown dialect, and its section-navigation mechanism; R81 (`docs-delivery-model`) owns F341/F343/F344 — this item only gates the correctness of whatever tree or site R81 produces, it does not design the tree or site.
- Whether the template ships an optional web/API surface at all, and what it contains; R69 (`web-framework-stack`) owns `web-extra-surface` — this item only needs to know that surface will eventually exist so `cargo doc` can be invoked with the right feature flags to include it, not decide the surface's contents.
- CI job/step topology and skip-gating mechanics beyond this check's own placement; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item states which check(s) it needs run and on what trigger, not how jobs and steps are structured or skip-gated in general.
- Whether external-link checking runs on every PR versus a scheduled cadence; R34 (`scheduled-freshness-lanes`) owns the general scheduled-lane mechanism — this item states the check's own rate-limit/flakiness posture (informing whether it belongs on a schedule), not the CI schedule that runs it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R82
- owns:
- consumes: R69: web-extra-surface; R11: ci-job-structure
- related (not a registry dependency): R81 (`docs-delivery-model`) decides the docs tree/site this item's link checker and rustdoc gate check; assume R81 resolves to *some* delivery model and design this item's gate to fit either a generated-site build output or a plain-markdown tree.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what tool/strategy gates doc content correctness in CI — internal/relative link checking (offline), external URL link checking, and rustdoc/API-reference-doc-generator correctness (broken intra-doc links) — and on what trigger each runs.
- HIGH: Is `lychee` the dominant current Rust-ecosystem link checker covering both internal/relative and external URLs in one tool, able to replace py's split approach (`sphinx-build -W` for internal, a weekly `sphinx-build -b linkcheck` job for external) and ts's split approach (`check-links.mjs` for internal, nothing for external) with a single unified check?
- HIGH: Does `cargo doc` with `RUSTDOCFLAGS="-D warnings"` (or an equivalent CI invocation) reliably fail the build on broken intra-doc links the way py's `sphinx-build -W` fails on autodoc/directive errors, and is this effectively free (ships with every Rust toolchain, per the ledger's F353 note) or does it need an additional crate/config to match py's strictness?
- MEDIUM: Does the chosen link-checker need to distinguish which docs surface it walks depending on R81's eventual delivery-model pick (a generated mdBook `book/` output directory vs. a plain `docs/` markdown tree), or is one invocation shape (e.g. pointed at the markdown source, not a build artifact) correct for either outcome?
- MEDIUM: Given py runs external-URL checking weekly (not on every PR) and ts runs no external-URL check at all, what does the current Rust-ecosystem tooling recommend for external-link check cadence and flakiness/rate-limit handling (retries, timeout, allowlist for known-flaky hosts)?
- LOW: What is the idiomatic way to scope `cargo doc`'s feature flags (`--all-features` vs. an explicit feature list) so the optional web-feature-gated API surface is included once `web-extra-surface` is enabled, without failing the build when it is not?

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
