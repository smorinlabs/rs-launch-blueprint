# Deep-research prompt — CORS middleware (R76, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether `rs-launch-blueprint` adopts a CORS middleware crate that installs only when an origin allowlist is configured, leaving cross-origin calls opt-in and the default (empty allowlist) install-free. Item kind: `crate`. Value test: if this answer is wrong, the CORS-layer dependency, its conditional-install branch in the composition root, and the config value that gates it all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py installs CORS middleware only when a settings-provided origin allowlist is non-empty; cross-origin calls are opt-in, and the default (empty allowlist) means no CORS middleware is installed at all. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/app.py:136` — `if settings.cors_origins:` (cross-origin calls are opt-in; empty list, the default, means no CORS middleware at all); ts: none. Ledger row: F322 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no CORS shape to reconcile with.

## Out of scope
- Which web framework/server this CORS layer attaches to; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the CORS wiring to fit whichever framework's middleware model wins.
- This middleware's position relative to the id/security-header/access-log ordering contract; R75 (`http-middleware-stack`) owns F317 — this item decides only the CORS crate and its conditional-install trigger, not where it sits in the overall stack.
- The typed env-settings shape that supplies the allowlist value; R77 (`web-env-settings`) owns F324 — this item consumes "an allowlist value exists," not how that value is parsed from the environment.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R76
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/middleware-layer model this CORS layer must integrate with. R75 (`http-middleware-stack`) owns the overall ordering contract (F317) this layer must be positioned within. Treat both as open, do not block on them.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a Rust CORS middleware crate that installs only when an origin allowlist is configured, leaving cross-origin calls opt-in and the default (empty allowlist) install-free.
- HIGH: Which Rust CORS crate is idiomatic for a leading async web framework, and does it support a runtime-configured, possibly-empty origin allowlist, or does the allowlist need to be known at compile time?
- HIGH: What is the idiomatic way to install the layer only when the allowlist is non-empty (mirroring py's `if settings.cors_origins:`) — a conditional layer-registration branch in the composition root, or an optional-layer wrapper?
- MEDIUM: Does the crate's default behavior differ meaningfully from py's (e.g. default-deny vs. default-permissive), and what configuration is needed to match py's "empty list = no CORS middleware at all" semantics exactly?
- LOW: Do any published Rust web-service templates document conditional, allowlist-gated CORS installation as a named pattern, and where?

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
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
