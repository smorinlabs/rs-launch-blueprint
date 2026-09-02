# Deep-research prompt — Hook manager distribution and wiring (R37, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates/tools and reference pattern (with versions) for: how `rs-launch-blueprint` installs and distributes its git hook manager (lefthook, kept per `docs/port/README.md`'s presumption of reuse — both source repos already agree on the tool itself), what triggers hooks to actually get wired into a fresh clone, and how a CI job re-runs the full hook suite against the whole tree for dual local/CI enforcement. Item kind: `bundle`. Value test: if this answer is wrong, the lefthook install/version-pin mechanism, the `just setup`-equivalent hook-wiring step, and the CI job that re-runs the hook suite all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos use lefthook itself (`F142`, verdict `COMMON → REUSE`, out of scope here) but diverge on how it is *distributed* and *wired*. py installs lefthook globally through a separate Bun-based installer script, entirely outside its main package manager (uv); wiring requires explicitly running the project's setup command. ts lists lefthook as a package-manager devDependency and wires it automatically via the package manager's own lifecycle hook. Neither pattern has a literal Cargo analogue, since Cargo does not manage non-crate binaries the way `bun install -g`/`pnpm install` does. Evidence: py `scripts/install-lefthook.sh:13` (version pin), `scripts/install-lefthook.sh:35` — global `bun install -g lefthook@2.1.8`, pinned outside the package manager; ts `package.json:54` — `lefthook` listed as a `^2.1.10` devDependency, installed by `pnpm install`. Ledger rows: F143, F144, F174 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F144 hook-wiring trigger mechanism — py `scripts/install-lefthook.sh:46` (`lefthook install` run explicitly inside `just setup`'s hook-toolchain step); ts `package.json:36` (`"prepare": "lefthook install"` auto-runs on every `pnpm install`) — ts wires hooks into the package manager's own lifecycle, py requires running the project's setup command. F174 CI job aggregating the full hook suite — ts `.github/workflows/ci.yml:106` (`pnpm exec lefthook run pre-commit --all-files` step inside the `ci` job, decision D-022(1)); py: none (py's hook↔CI parity is per-check instead — ADR 0018 maps each tool to its own CI job rather than re-running the literal hook suite as one step); this row is the resolution target for ci-workflows' and lint-format's forward-referenced "full hook suite re-run against all files" primary-assignment rows.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). lefthook itself is the hook manager tool (F142, `COMMON → REUSE`, not open for reconsideration). Three researched parameters this item consumes are still open (no `DECISION.md` yet): `ci-job-structure` (R11), `package-manager-invocation` (R42), `web-extra-surface` (R69) — design to fit whichever value each eventually takes; do not block on them.
- Prior decisions of the TypeScript port that explain the current shape: D-020(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — lefthook 2.x kept as a devDependency, activated via `package.json`'s `"prepare": "lefthook install"`, chosen because it is the only hook manager with positive org precedent and is actively maintained versus a dormant husky or a Python-runtime-imposing pre-commit framework; D-022(1) — the CI workflow's dual-enforcement structure (checkout, setup, named just-recipe steps, plus a hook-suite run-all parity step).

## Out of scope
- The commit-message linter tool itself and its config (base config, header/body/footer length overrides, type-enum, bot-PR relaxed ruleset, CI re-run); R38 (`commit-message-linter`) owns `commit-message-convention` and F149-F157 — this item wires the hook *manager*, not the commit-msg linter's own tooling.
- The secret-scanning hooks (staged and pre-push-range) and their allowlist/suppression files; R39 (`secret-scanning-hooks`) owns F163-F166.
- The auxiliary hygiene hooks (whitespace/EOL validity, YAML lint, spell-check, Actions workflow syntax lint) and the cross-editor `.editorconfig` baseline; R40 (`auxiliary-hygiene-hooks`) owns F167-F170, F191, F192.
- The dependency-manifest lockfile-freshness check hook; R41 (`lockfile-freshness-check`) owns F171.
- Whether the full test suite additionally runs as an opt-in pre-push hook; R32 (`test-harness-and-execution`) owns F173 — this item wires the hook *manager* and its stage tiers, not which test-suite hook runs inside the push tier.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R37
- owns:
- consumes: R11: ci-job-structure; R42: package-manager-invocation; R69: web-extra-surface
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R38 (`commit-message-linter`), R39 (`secret-scanning-hooks`), R40 (`auxiliary-hygiene-hooks`), and R41 (`lockfile-freshness-check`) each own a specific hook *job's* tool and config; this item owns the hook *manager*'s distribution, install trigger, and full-suite CI re-run — the container those jobs run inside, not their contents. R32 (`test-harness-and-execution`) owns F173 (the opt-in pre-push test-suite hook) — coordinate on where in the stage tiering it lands but do not re-decide it.

## Questions
Decision: how `rs-launch-blueprint` distributes and installs lefthook (a non-crate binary Cargo does not manage), what triggers `lefthook install` on a fresh clone, and how a CI job re-runs the full hook suite against the whole tree.
- HIGH: Since Cargo has no devDependency-lifecycle equivalent to `pnpm install`'s `prepare` script, what is the idiomatic Rust-ecosystem mechanism for auto-wiring hooks on setup — a `cargo-make`/`just` recipe run manually (py's pattern), a `build.rs` script (generally discouraged for side effects like this), or a documented one-time `cargo install lefthook && lefthook install` step?
- HIGH: How should lefthook itself be distributed and version-pinned given Cargo cannot install it as a crate dependency — a prebuilt binary via `cargo-binstall`, a version-pinned shell installer script (py's pattern), or a `mise`/`asdf`-style toolchain-version file, and how does the choice interact with `package-manager-invocation` (R42)'s pick of how dev tools are invoked?
- MEDIUM: What is the idiomatic Rust CI pattern for F174 (re-running the full pre-commit hook suite against all files) — a dedicated `lefthook run pre-commit --all-files`-equivalent step inside the main CI job (ts's pattern), or per-tool CI jobs mirroring py's ADR-0018 per-check parity table — and how does that choice depend on `ci-job-structure` (R11)?
- MEDIUM: Does `web-extra-surface` (R69) change anything about hook-manager wiring itself, given the only cross-area coupling identified is a narrow web-specific pre-push job (owned elsewhere), not the manager's install/wiring mechanism?
- LOW: Should `rs-launch-blueprint` also expose an explicit `just hooks-install`/`just setup-hooks`-style recipe as a fallback to the automatic wiring, matching both source repos' F145 pattern (out of scope to decide the recipe name, but worth noting as a migration implication)?

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
