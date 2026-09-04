# Deep-research prompt — Non-code file formatting (R29, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which tool(s) format and check TOML, YAML, JSON, and Markdown files, and how they wire into the hook/CI pipeline — given the template's own `Cargo.toml`, `rust-toolchain.toml`, `rustfmt.toml`, and GitHub Actions YAML make these formats directly relevant regardless of any other topic's decisions. Item kind: `bundle`. Value test: if this answer is wrong, the non-code-formatter config file(s), the Justfile recipe(s) that invoke them, the `lefthook.yml` job(s), and the CI step that runs them all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py runs one dedicated, enforced formatter for TOML (`taplo`) and configures but never wires up a YAML formatter (`yamlfmt`); ts runs its single JS/TS formatter (`oxfmt`) across YAML, JSON, and Markdown too, all enforced via the same hook glob, and carries zero TOML files at all. Evidence: py `.taplo.toml:23` — `taplo` formats/checks TOML, wired to hooks + CI; `.yamlfmt:1` — `yamlfmt` config exists, not wired to hooks/CI; ts `lefthook.yml:24` — `oxfmt` formats YAML, JSON, and Markdown, included in the hook glob. Ledger rows: F097, F098, F099 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F097 TOML formatter as a separate tool — origin `py-only`; confirmed ts's `.oxfmtrc.json` has no TOML-specific setting and the ts repo carries zero `.toml` files, so origin stays py-only even though Rust's own config files make TOML formatting directly relevant regardless. F098 YAML formatting ownership — py's `yamlfmt` is configured but unenforced (never wired to hooks/CI); ts's `oxfmt`-based YAML formatting is enforced via the hook glob. F099 JSON and Markdown formatting coverage — origin `ts-only`; py has no formatter for these formats in this repo at all.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Rust source-code formatting itself (`rustfmt`'s config surface) is R27's decision, not this item's — this item covers only non-Rust config/doc file formats.
- Prior decisions of the TypeScript port that explain the current shape: D-014(6) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — omit `taplo`/`.taplo.toml`; TOML presence in ts depends entirely on a separate release-tooling topic's `cog.toml` keep/drop decision, and `oxfmt` would format TOML anyway if any `.toml` file existed; D-014(7) — omit `yamlfmt`, `oxfmt` formats YAML (Prettier-compatible), validated at scaffold time, with `yamlfmt` documented as a fallback if `oxfmt`'s YAML support proves unstable.

## Out of scope
- Rust source-code formatting (`rustfmt`'s config surface, exclude-list scope, composite-recipe placement, version pinning, hook mode); R27 (`formatter-config-surface`) owns F084/F087/F089/F091/F092/F100/F102/F103/F104/F162.
- The linter's own config; R28 (`linter-and-editor-tooling`) owns F085/F086/F093/F094/F096/F101/F109/F195/F196.
- The shape of the CI job(s) that run these formatters; R11 (`ci-workflow-job-structure`) owns `ci-job-structure`.
- The Justfile/lefthook invocation syntax; R42 (`dev-toolchain-provisioning`) owns `package-manager-invocation`.
- Whether the template's release tooling keeps or drops a `cog.toml`-equivalent config file (which would affect how many TOML files exist beyond `Cargo.toml`/`rustfmt.toml`); that decision is settled — release-please is inherited (ledger rows F063 and F066, `COMMON → REUSE`), so no `cog.toml` exists — treat TOML formatting as needed regardless, since `Cargo.toml` and `rust-toolchain.toml` always exist.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R29
- owns:
- consumes: R11: ci-job-structure; R42: package-manager-invocation
- related (not a registry dependency): R27 (`formatter-config-surface`) decides whether the composite `just check`/`just all` recipe includes a Rust format-check step (F102). This item decides whether that same composite recipe, or a separate one, also runs the TOML/YAML/JSON/Markdown formatters chosen here — coordinate the recipe wiring recommendation with R27's answer, but do not re-decide F102 here.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which tool(s) format and check TOML, YAML, JSON, and Markdown files in `rs-launch-blueprint`, and how they wire into the hook/CI pipeline, given the template's own project files make these formats directly relevant regardless of any other repo's decisions.
- HIGH: Is there a single Rust-ecosystem-native tool that formats TOML, YAML, JSON, and Markdown together (an `oxfmt`-equivalent "one fast tool" for non-code formats), or does Rust idiom split this across per-format tools the way py did (`taplo` for TOML, `yamlfmt` for YAML, nothing for JSON/Markdown)?
- HIGH: Is `taplo` — py's TOML tool, and also widely used within the Rust ecosystem itself (e.g. cited by `rustfmt`'s own config-schema tooling) — the dominant Rust-native TOML formatter/checker, and is it available as a `cargo install`-able binary (a genuine Rust-ecosystem tool) or does its most-current distribution live only as an npm package (as `docs/port/areas/lint-format.md` notes for the ts port's own `@taplo/cli` evaluation)?
- MEDIUM: What formats YAML in the Rust ecosystem for files like GitHub Actions workflows and `lefthook.yml` — is there a maintained Rust-native YAML formatter, or does this item need to recommend a cross-ecosystem tool (accepting the same kind of non-Rust dependency py accepted with `yamlfmt`, a Go binary) or skip enforcement entirely, mirroring py's "configured but never wired up" outcome?
- MEDIUM: Does `rs-launch-blueprint` need JSON/Markdown formatting coverage at all (ts wired `oxfmt` for both; py had none) — what JSON/Markdown files does a Rust CLI+library+web template actually carry (`Cargo.lock`, `README.md`, `docs/`, `CHANGELOG.md`), and is a dedicated formatter worth the added dependency and hook/CI time?
- LOW: Should these non-code formatters run in the same pre-commit/pre-push hook tier as `rustfmt` (R27's decision), or a separate tier, given their scan scope (whole-repo config/doc files) differs from `rustfmt`'s (source tree only)?

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
