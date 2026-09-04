# Deep-research prompt — Config error tolerance (R55, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s config loading tolerates three distinct failure modes — an explicit `--config` path pointing at a missing file, an unparsable *discovered* (non-explicit) config layer, and an individually invalid config value in an otherwise-valid file — each with its own degrade-vs-fail behavior. Item kind: `bundle`. Value test: if this answer is wrong, the config-loading function's error branches for missing/unparsable/invalid-value cases, and whether a bad key is dropped-with-warning or fails the whole load, all get rewritten.

## Context
- Inherited pattern (spec §2): the repos diverge across three related-but-distinct tolerance questions. (1) An explicit `--config` path that doesn't exist: py tolerates it as an empty layer (a valid `config set` target); ts throws a usage error, exit 2. (2) An unparsable *discovered* (non-explicit) layer: py degrades to a warning and treats it as empty; ts has no discovered-and-tolerated tier to compare — its one discovered file, if present, is read the same strict way as `--config`. (3) An individually invalid config *value* in an otherwise-parseable file: py drops just the bad key with a warning; ts's zod `safeParse` failure raises `ConfigError` for the whole file. Evidence: F235 py `src/py_launch_blueprint/core/config.py:114` — `if not path.exists(): return {}`; ts `src/lib/config.ts:153` — `if (!fs.existsSync(options.configPathFlag)) { throw new UsageError(...)`, exit 2. F236 py `src/py_launch_blueprint/core/config.py:102` — `except (OSError, tomllib.TOMLDecodeError) as exc: return {}, f"ignoring unreadable config file {path}: {exc}"`; ts: none (py-only, no discovered-and-tolerated tier exists). F238 py `src/py_launch_blueprint/core/settings.py:169` — `warnings.append(f"ignoring invalid config value {section}.{key} = {bad!r}{suffix}")`; ts `src/lib/config.ts:129` — zod `safeParse` failure raises `ConfigError` for the whole file, no per-key drop. Ledger rows F235 (origin `different`), F236 (origin `py-only`), F238 (origin `py-only`) (`docs/port/COMMONALITY.md`), all verdict `DIVERGENT`.
- Already decided, do not re-open: an unparsable *explicit* config file raises loudly in both repos (F237, `COMMON → REUSE`, inherited as-is — py `src/py_launch_blueprint/core/config.py:118` — `raise ConfigError(...)`; ts `src/lib/config.ts:119` — `throw new ConfigError(...)`); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- The area file's own note on F238 is live context, not a settled conclusion: it was "considered as an OVERRIDE candidate (serde's typed deserialization makes per-key drop-and-continue awkward) but this row's origin is py-only, not same, so OVERRIDE is not legal here; stays DIVERGENT." Propose how (or whether) Rust achieves py's per-key-drop behavior despite serde's typed, whole-struct deserialization model.
- Prior decisions of the TypeScript port that explain the current shape: none for F235/F236/F238 specifically — `TS_PORT_DECISIONS.md`'s D-017(1) covers the overall precedence chain but records no dedicated decision on any of these three tolerance questions; ts's strict-fail behavior in each case is a byproduct of its schema-validation and file-existence checks, not a separately reasoned choice.

## Out of scope
- How many config-discovery tiers exist and where they search (system/user/project); R54 (`config-discovery-tiers`) owns F230/F231/F232/F234 — this item decides what happens when a layer that tier structure discovers is missing, unparsable, or contains a bad value, not how many tiers exist.
- Whether the config file may carry a secret/token, and permission warnings on it; R56 (`config-secret-policy`) owns F239/F240/F245 — this item's tolerance rules apply to config values generally, not to secret handling specifically.
- Which crate parses TOML and which crate/mechanism performs schema validation; R52 (`toml-crate`) and R53 (`config-schema-validation`) own those — this item decides what happens on failure, not which library produces the failure.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R55
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R54 (`config-discovery-tiers`) — F236's discovered-layer tolerance only applies if R54 adopts a discovered (non-explicit) tier; treat R54's answer as open. R53 (`config-schema-validation`) — F238's per-key-drop tolerance depends on whatever validation mechanism R53 selects.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint`'s config loading tolerate (a) an explicit `--config` path pointing at a missing file, (b) an unparsable discovered config layer, and (c) an individually invalid config value in an otherwise-valid file — degrade-with-warning versus hard failure, for each.
- HIGH: For (a), does Rust follow py's tolerant shape (missing explicit path = empty layer, valid `config set` target) or ts's strict shape (exit with a usage error)? What does each imply for a `config set`-style workflow that needs to write to a not-yet-existing explicit path?
- HIGH: For (c), can serde's typed `Deserialize` impl realistically drop one bad key and keep the rest (py's behavior), or does Rust's whole-struct deserialization model force an all-or-nothing outcome unless the schema first deserializes into an untyped `toml::Value`/similar and validates key-by-key?
- MEDIUM: For (b), assuming R54 adopts a discovered tier, is degrading an unreadable/unparsable discovered file to a warning-and-skip a few lines of `match` on the parse `Result`, or does it need a more structured "layer with provenance" abstraction to report which file the warning is about?
- MEDIUM: What warning-emission mechanism (matching R58/R59's eventual logging pipeline) surfaces these three degrade cases — a `Vec<String>` of warnings returned alongside the config (py's shape), or a `tracing::warn!` call at the point of degradation?
- LOW: Does this pattern's error type distinguish "expected, tolerated" outcomes from "unexpected, fatal" ones in the same style R03 (`port-absence-vs-failure-contract`) already establishes for the I/O seam — should this item reuse that pattern rather than invent a parallel one?
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
