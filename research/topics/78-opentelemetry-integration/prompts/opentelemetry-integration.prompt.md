# Deep-research prompt — OpenTelemetry integration (R78, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s web service integrates OpenTelemetry tracing as an opt-in capability whose absence never breaks the service. Item kind: `crate`. Value test: if this answer is wrong, the `otel` Cargo feature's dependency set, the tracing-export code path, and how the service behaves when tracing is unconfigured all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py's web layer imports its OpenTelemetry integration at runtime and degrades to a warning (not a crash) when the `otel` install extra is absent; ts has no web service to compare against. Evidence: py `src/py_launch_blueprint/web/telemetry.py:71` — `except ModuleNotFoundError:` degrades to a warning, not a crash; ts: none (no web service exists in ts; F303). Ledger rows: F325 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); tracing dependencies already ship as a further, separate optional Cargo feature layered beyond the base `web` feature (F304, `ADOPT` — Cargo's native feature layering makes this a nothing-to-choose mechanism, do not redesign it, just pick what lives behind it); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing OpenTelemetry integration.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Take the principles of using Otel and find the best Otel libraries and equivalents for TypeScript and Rust. Implement them there.

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the OTel crate(s) that live behind the `otel` feature.
- Whether Prometheus/RED metrics are adopted and how; R79 (`prometheus-metrics`) owns F326 — this item is tracing-only, not metrics.
- The shared structured-logging pipeline's base architecture (subscriber layering, sinks, log-record shape); R58 (`logging-pipeline-architecture`) owns that — this item is scoped to OTel trace/span export and its integration point with that pipeline, not the pipeline itself.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R78
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework this item's tracing spans instrument; treat the framework choice as open.
- related (not a registry dependency): R58 (`logging-pipeline-architecture`) decides the base `tracing`-crate subscriber pipeline this item's OTel layer plugs into; assume some `tracing`-based pipeline exists and describe how an OTel exporter layers onto it, without redesigning the pipeline.
- related (not a registry dependency): R79 (`prometheus-metrics`) is the sibling metrics decision for the same web service; a shared observability posture is a valid finding but not a requirement.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust crate(s), gated behind an `otel` Cargo feature layered beyond `web`, provide OpenTelemetry tracing integration for the web service, and what happens when tracing is unconfigured or the feature is disabled.
- HIGH: What are the current, standard OpenTelemetry Rust SDK/exporter crates and the `tracing`-integration bridge crate (candidates: `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `tracing-opentelemetry`), and what is their version-compatibility matrix with each other and with the `tracing`/`tracing-subscriber` ecosystem?
- HIGH: Given Cargo feature-absence is compile-time (code behind an unenabled `otel` feature simply does not exist in the binary), what replaces py's runtime soft-degrade (F325) — is there still a runtime failure mode to guard (e.g. the feature is compiled in but no collector endpoint is configured), and how should that degrade instead of crash the service?
- MEDIUM: How does `tracing-opentelemetry` compose as a layer atop a `tracing_subscriber::Registry`, and does adding it require restructuring how the base logging pipeline (owned by R58) is assembled, or is it a pure addition?
- MEDIUM: What exporter transport does the current ecosystem default to (OTLP over gRPC vs. HTTP), and what does that imply for the crate's async-runtime coupling and dependency footprint?
- LOW: What is the binary-size and compile-time cost of the OTel crate set, given they are feature-gated and only paid for when `otel` is enabled?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). The divergence analysis marked this item harmonize: no; the owner asked for the cross-repo answer anyway, so answer it in full.

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
