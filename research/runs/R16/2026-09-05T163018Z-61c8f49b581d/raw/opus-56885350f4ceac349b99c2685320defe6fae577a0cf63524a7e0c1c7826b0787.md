# R16 — CodeQL config customization (pattern) — Opus raw report

All figures and quotations were retrieved 2026-09-09 (UTC) unless a different
date is stated beside the source. Endpoints are named inline and repeated under
`### Sources`.

### Landscape

**Category this item decides.** Analysis-scope and query-suite configuration for
a CodeQL *advanced setup* on a Rust repository: which queries the scan runs, and
which files in the checkout produce alerts. It does not decide the workflow's
trigger, its visibility gate, or the language matrix (F027, `COMMON → REUSE`).

**Three-bin map of the Rust field.**

*Bin 1 — built-in / first-party toolchain (GitHub and the CodeQL project).*

| Mechanism | What it controls | Where documented |
|---|---|---|
| `queries:` input on `github/codeql-action/init` | query-suite selection, inline, one line | `init/action.yml` at tag `v4.37.9`: "Comma-separated list of additional queries to run. By default, this overrides the same setting in a configuration file; prefix with \"+\" to use both sets of queries." (`https://raw.githubusercontent.com/github/codeql-action/v4.37.9/init/action.yml`) |
| `config-file:` input | path to a YAML config file | same file: "Path of the config file to use" |
| `config:` input (v4) | the same YAML passed inline as a string | same file: "Configuration passed as a YAML string in the same format as the config-file input. This takes precedence over the config-file input." |
| `packs:` input | CodeQL pack selection; single-language analyses only | same file |
| Config-file keys `queries`, `paths`, `paths-ignore`, `query-filters` | suite selection, scan scope, tag-based filtering | GitHub Docs, *Customizing your advanced setup for code scanning* (`https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning`) |
| First-party Rust suites in `codeql/rust-queries` | the actual query sets | `rust/ql/src/codeql-suites/` at tag `codeql-cli/v2.26.4`: `rust-code-scanning.qls`, `rust-security-extended.qls`, `rust-security-and-quality.qls`, `rust-security-experimental.qls`, `rust-code-quality.qls`, `rust-code-quality-extended.qls` (`https://api.github.com/repos/github/codeql/contents/rust/ql/src/codeql-suites?ref=codeql-cli/v2.26.4`) |
| Rust **extractor options** `cargo_cfg_overrides`, `cargo_features`, `cargo_target`, `extract_dependencies_as_source` | what source the extractor ingests at all | `rust/codeql-extractor.yml` at `codeql-cli/v2.26.4` (`https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/codeql-extractor.yml`) |

*Bin 2 — established industry standard (the shapes repositories actually ship).*
(a) GitHub **default setup** — no workflow file, no config, configured in repo
settings; (b) **advanced setup, bare defaults** — an `init` step with only
`languages:` (ts's shape); (c) **advanced setup + inline `queries:`** — extended
suite selected in the workflow, no config file; (d) **advanced setup + config
file** carrying `queries` and/or `paths-ignore` (py's shape).

*Bin 3 — up-and-comers.* `query-filters` (include/exclude by query metadata tag,
used in production by SurrealDB); the `config:` inline-YAML input (present in
`codeql-action` v4); custom `.qls` suite files committed to the repo; third-party
CodeQL packs via `packs:`.

**Authorities used, and why each is authoritative.**

1. **`github/codeql` source at the exact released CLI tag.** This is the ground
   truth for what a named suite selects: the suite files and the shared
   selector files are the program that computes the query set. Not a
   description of behaviour — the behaviour itself. MIT-licensed, 10,067 stars,
   not archived, `pushed_at` 2026-09-09T03:05:07Z (`https://api.github.com/repos/github/codeql`).
2. **`github/codeql-action` release metadata.** `src/defaults.json` at tag
   `v4.37.9` pins `"bundleVersion": "codeql-bundle-v2.26.4"`, `"cliVersion": "2.26.4"`
   (`https://raw.githubusercontent.com/github/codeql-action/v4.37.9/src/defaults.json`).
   This is what decides which queries a workflow *actually* runs, so every count
   below is taken at tag `codeql-cli/v2.26.4`, not at `main`.
3. **GitHub Docs (code scanning).** The platform owner's own specification of
   `paths`/`paths-ignore` semantics and their language applicability.
4. **codeql.github.com** — the CodeQL documentation and per-query help pages;
   each query-help page states the suites that include the query, giving an
   independent cross-check on the selector derivation.
5. **GitHub Changelog** — the dated release record for language-support status.
6. **Production Rust repositories' own workflow files** — practice evidence,
   below.

**Practice evidence — what mainstream Rust projects actually do.**

A negative sweep first. I probed 20 flagship Rust repositories for an advanced
CodeQL setup (`GET /repos/<o>/<r>/contents/.github/workflows` plus
`/.github/codeql`, all 2026-09-09): `rust-lang/cargo`, `rust-lang/rust-analyzer`,
`rust-lang/crates.io`, `tokio-rs/tokio`, `tokio-rs/axum`, `hyperium/hyper`,
`rustls/rustls`, `astral-sh/uv`, `astral-sh/ruff`, `denoland/deno`,
`bytecodealliance/wasmtime`, `firecracker-microvm/firecracker`, `aws/aws-lc-rs`,
`smithy-lang/smithy-rs`, `cloudflare/pingora`, `zed-industries/zed`,
`pola-rs/polars`, `oxc-project/oxc`, `biomejs/biome`, `sigstore/sigstore-rs`.
**None of the twenty ships a CodeQL workflow.** The security-sensitive ones
(`rustls`, `firecracker`, `aws-lc-rs`, `pingora`, `sigstore-rs`) run
`cargo-audit`/`cargo-deny`-style lanes and fuzzing instead.

*Blind spot, stated:* repositories using GitHub's **default setup** have no
workflow file, so absence of a file is not proof that no CodeQL scan runs. The
sweep is evidence about the *advanced-setup* population only.

Positives, found by authenticated GitHub code search
(`search/code?q="languages: rust" "codeql-action/init" path:.github/workflows`,
648 total hits, and `search/code?q="security-extended" "rust" path:.github/codeql`,
109 total hits, both 2026-09-09):

| Project | Stars | Shape | Evidence it is well regarded |
|---|---|---|---|
| `surrealdb/surrealdb` | 32,997 | `config-file:` **and** inline `queries: security-extended`; `paths-ignore` covers `**/tests/**`, `**/benches/**`, `fuzz/**`, `target/**`, `doc/**`, `pkg/**`; plus a `query-filters` exclude on `tags contain: experimental`; `build-mode: none` | Largest-by-stars Rust database project; SHA-pinned third-party actions and a `harden-runner` step indicate a maintained supply-chain posture |
| `wasmCloud/wasmCloud` | 2,435 | inline `queries: security-extended`, **no** config file; `codeql-action@cdf488f… # v4.37.9` (current release) | CNCF project; tracks the newest action release with SHA pinning |
| `open-telemetry/opentelemetry-rust` | 2,700 | `languages: rust` with **no** `queries:` and **no** `config-file:` — bare default suite (ts's shape) | CNCF; the reference OpenTelemetry SDK for Rust |
| `copper-project/copper-rs` | — | `build-mode: none`, `queries: security-extended,security-and-quality` | Smaller; included as a shape datapoint, not weighted as authority |

Stars/archived/pushed figures: `GET https://api.github.com/repos/<o>/<r>`,
2026-09-09. Among Rust repositories that run advanced-setup CodeQL at all, three
of the four sampled select `security-extended`; only one adds a config file.

### Principles and implementation

**The shared requirement.** py and ts agree on the principle that *the
repository runs GitHub's semantic code-scanning engine on every push, pull
request and weekly schedule, wherever the platform makes it available*
(F027, `COMMON → REUSE`). F045 is a narrower question inside that: **the scan's
findings must be worth a maintainer's attention — broad enough to cover the
vulnerability classes the codebase can actually exhibit, and narrow enough that
the alerts point at shipped code.**

**Agreement level: policy, not mechanism.** The observable requirement is a
signal-quality property of the scan. It cannot be met by copying py's file,
because the two levers py bundles into one file behave differently in Rust. The
*low-level values* (`security-extended`; `tests/**`, `docs/**`) are Python-shaped
and must be re-derived; the *policy* — select the broader suite when it adds
real coverage, exclude non-shipped code when the exclusion actually reaches it —
transfers unchanged. Per the research mandate, a shared low-level value is
recommended only on explicit owner requirement or same-tradeoff evidence in all
ecosystems; neither holds for the literal paths.

**Essential behaviors.**

- B1. The scan runs every query in the first-party Rust suite whose CWE classes
  the template's own code can exhibit (a logging pipeline, an HTTP service, and
  whatever `unsafe` R06 permits).
- B2. Alerts arriving in the Security tab describe code that ships to a
  consumer of the template, not fixture or benchmark code.
- B3. The selection is one reviewable artifact, versioned with the workflow, and
  does not silently lose a setting when another setting is added.

**Observable acceptance criteria.**

- A1. `codeql resolve queries <suite>` for the configured suite lists
  `rust/log-injection` and `rust/access-after-lifetime-ended`; the default suite
  does not.
- A2. A deliberately vulnerable snippet placed under an ignored path produces no
  alert; the same snippet under `src/` does.
- A3. The `init` step's effective query set equals the config file's, i.e. no
  inline `queries:` input silently overrides it.

**What must agree across the three repositories; what may vary.** *Must agree:*
the policy (B1–B3) and the fact that the selection lives in a reviewable file.
*May vary:* the suite name if an ecosystem's extended suite adds nothing, and
every path in `paths-ignore`, because the file layout that separates test code
from shipped code is language-specific.

**Architectural alternatives, compared before choosing a mechanism.**

*Alt-A — no config, bare defaults (ts's shape).* Cheapest. Loses B1 (see the
delta below) and B2 entirely.

*Alt-B — inline `queries: security-extended` on the `init` step, no file.*
Satisfies B1 in one line and is the most common Rust practice (wasmCloud,
copper-rs). Cannot express `paths-ignore` — the config file is the only place
that key exists — so it cannot satisfy B2. It also carries the documented
override footgun in B3: the input "overrides the same setting in a configuration
file; prefix with \"+\" to use both sets of queries"
(`init/action.yml`, `v4.37.9`). SurrealDB currently sets both an inline
`queries:` and a `config-file:`; that is safe only because their file happens to
declare no `queries` key.

*Alt-C — config file carrying `queries` **and** `paths-ignore` (py's shape).*
Satisfies B1, B2 and B3 in one artifact.

*Alt-D — `security-and-quality`.* Superset of `security-extended`. At
`codeql-cli/v2.26.4` the Rust quality delta is exactly three queries —
`rust/dead-code` (`@precision medium`, `@problem.severity recommendation`),
`rust/unused-value` (medium, recommendation) and `rust/unused-variable` (high,
recommendation), all `@tags maintainability`
(`rust/ql/src/queries/unusedentities/*.ql` at that tag). `rustc`'s own
`dead_code` and `unused_variables` lints and Clippy already report these at
compile time, in the lane R28 owns, at a fraction of the latency. Rejected as
duplicated coverage routed to the wrong surface.

*Alt-E — `security-experimental`.* `rust-security-experimental.qls` exists, but
the recursive tree of `rust/ql/src` at `codeql-cli/v2.26.4` (tree sha
`a5bf0eb902d6abc7d58b7dc22174fe946d510879`, 54 `.ql` files) contains **no**
`experimental/` directory — the only path matching "experimental" is the suite
file itself. The suite therefore resolves to the same query set as
`security-extended` today, so it buys nothing and would silently widen if
experimental Rust queries land later.

*Alt-F — extractor option `cargo_cfg_overrides=-test`.* The Rust-native way to
stop unit-test code being analysed at all (see the cfg(test) finding). Recorded
as an option, **not recommended**, because its delivery from a workflow is
unverified (below).

**Finding 1 — the `security-extended` delta for Rust, derived at the pinned CLI.**

Method: the suites `apply` shared selector files from `codeql/suite-helpers`
(`rust-code-scanning.qls` → `code-scanning-selectors.yml`;
`rust-security-extended.qls` → `security-extended-selectors.yml`). The
code-scanning selector includes `kind: problem|path-problem|alert|path-alert`
with `precision: high|very-high`, `problem.severity: error|warning`, and
`tags contain: security`. The security-extended selector differs in **two**
ways: its first include block drops the `problem.severity: error|warning`
restriction, so a high-precision security query marked `recommendation` would be
selected by it and not by the default suite; and it adds a second include block
for `precision: medium` with `problem.severity: error|warning` and
`tags contain: security`. Only the second difference bites for Rust today — no
Rust security query carries `@problem.severity recommendation` at
`codeql-cli/v2.26.4` — but both are recorded, because the first could start to
bite without any suite file changing. I read the `@precision`, `@problem.severity` and
`@tags` metadata of all 19 `rust/ql/src/queries/security/*.ql` files at
`codeql-cli/v2.26.4` and applied the selectors.

| Suite | Rust security-alert queries at CLI 2.26.4 |
|---|---|
| `rust-code-scanning.qls` (default) | **16** |
| `rust-security-extended.qls` | **18** |

The delta is exactly two queries, both `@precision medium`:

- `rust/log-injection` (CWE-117, `@security-severity 6.1`, `@problem.severity error`)
- `rust/access-after-lifetime-ended` (CWE-825, `@security-severity 9.8`, `@problem.severity error`)

`rust/ctor-initialization` carries `@tags reliability, correctness` with no
`security` tag and is in neither security suite. Independent cross-check: the
CodeQL query-help page for `rust/log-injection` states its query suites as
"rust-security-extended.qls" and "rust-security-and-quality.qls" — i.e. not the
default suite — which confirms the derivation
(`https://codeql.github.com/codeql-query-help/rust/rust-log-injection/`).

Stated honestly: this is **+12.5 % more security queries, not a doubling**, and
only *one* CWE class is newly covered end-to-end. CWE-825 already has a
default-suite query (`rust/access-invalid-pointer`, high precision, tagged
cwe-476 and cwe-825); `rust/access-after-lifetime-ended` deepens that class with
a medium-precision use-after-lifetime analysis rather than opening it.

For contrast at `main` (2026-09-09), a twentieth security query has landed
(`rust/command-line-injection`, CWE-078, high precision), moving the counts to
17 and 19 — the delta stays at the same two queries.

*Why the delta matters for **this** template specifically.* Both added queries
land on surfaces the template is being built to have. `rust/log-injection`
targets user-controlled data reaching a logging sink — precisely the pipeline
R58/R59 are designing, on a template whose web shape logs request-derived data.
`rust/access-after-lifetime-ended` targets pointer-lifetime undefined behaviour,
reachable only through `unsafe`, which is the exact class R06's `unsafe`-code
policy governs; a template that permits any `unsafe` should scan for it, and one
that forbids `unsafe` outright pays nothing for the query.

**Finding 2 — `#[cfg(test)]` unit tests are extracted by default, and
`paths-ignore` cannot reach them.**

`rust/extractor/src/config.rs` at `codeql-cli/v2.26.4` seeds the extractor's cfg
set unconditionally before applying any user override:

```rust
fn to_cfg_overrides(specs: &Vec<String>) -> CfgOverrides {
    let mut enabled_cfgs = HashSet::new();
    enabled_cfgs.insert(to_cfg_override("test"));
```

So `cfg(test)` is **on by default**; it can only be turned off by passing `-test`
through the `cargo_cfg_overrides` extractor option, documented in
`rust/codeql-extractor.yml` as "Comma-separated list of cfg settings to enable,
or disable if prefixed with `-`". This is the decisive Rust-versus-Python
difference for the `paths-ignore` question:

- Python puts its tests in a separate `tests/` tree, so `paths-ignore: tests/**`
  excludes **all** of them — py's exclusion is complete.
- Rust convention puts unit tests in `#[cfg(test)] mod tests` **inside**
  `src/*.rs` (`https://doc.rust-lang.org/book/ch11-03-test-organization.html`),
  and only integration tests in `tests/`. No path glob can reach a unit test
  without excluding the module that contains the production code. `tests/**`
  therefore delivers a **partial** exclusion in Rust.

The honest conclusion: B2 is only partially achievable through `paths-ignore` in
Rust. It is still worth achieving — integration tests, benches and fuzz targets
are exactly the places that hold deliberately malformed inputs and hand-rolled
`unsafe` — but the answer must not claim py's completeness.

**Finding 3 — `paths-ignore` is explicitly supported for Rust.** GitHub Docs,
*Specifying directories to scan*: "You can use this option when you run the
CodeQL actions on an interpreted language (Python, Ruby, and
JavaScript/TypeScript) or when you analyze a compiled language without building
the code (currently supported for C/C++, C#, Java and Rust)." Rust always
qualifies, because `rust/codeql-extractor.yml` at `codeql-cli/v2.26.4` declares
`build_modes:` with the single value `none` — the only mode the Rust extractor
declares. A workflow may still *contain* a `codeql-action/autobuild` step, as
`open-telemetry/opentelemetry-rust` does, but that step is a no-op for such a
language: `src/autobuild.ts` at `codeql-action` v4.37.9 short-circuits when
`config.buildMode === BuildMode.None || config.buildMode === BuildMode.Manual`,
logging "nothing to autobuild"
(`https://raw.githubusercontent.com/github/codeql-action/v4.37.9/src/autobuild.ts`).
Confirmed in practice by SurrealDB's and copper-rs's workflows, both of which set
`build-mode: none` for `languages: rust`.

**Finding 4 — `docs/**` and `target/**` are inert in a Rust repository.** The
Rust extractor's `file_types` in `rust/codeql-extractor.yml` is a single entry:
`extensions: [.rs]`. A Markdown `docs/` tree contains nothing the Rust extractor
ingests, so py's `docs/**` line has no Rust counterpart unless the docs tree
contains a crate. `target/` is Cargo's build directory and is `.gitignore`d by
`cargo new` (`https://doc.rust-lang.org/cargo/guide/project-layout.html`), so it
is absent from the Actions checkout. SurrealDB lists `target/**` defensively;
that is harmless but redundant for a template whose `target/` is ignored.

**Cross-repository comparison (HIGH question 3).** The suite selectors are
language-independent: every language's `*-security-extended.qls` applies the
same `security-extended-selectors.yml` from `codeql/suite-helpers`. The
principle "select the broader suite where it adds coverage" therefore argues
identically for all three repositories, and py already practices it. ts's
omission is, as `## Context` records, an unexamined gap in D-022(4) rather than a
considered rejection — the ported workflow even carries the upstream template's
commented-out `# queries: security-extended,security-and-quality` line
(ts `.github/workflows/codeql.yml`, pinned clone at `cb1cbcb`), which is the
starter template's placeholder left untouched. Recommended follow-on for the
py/ts project, not changed here: add `queries: security-extended` to ts.
Distinguish the two divergences: the **query-suite** divergence is accidental
drift and should be harmonised; the **`paths-ignore` contents** divergence is a
justified ecosystem difference and must stay different (py's complete
`tests/**` exclusion versus Rust's partial one, and `docs/**` being inert in
Rust).

**Minimal realistic example.** `.github/codeql/codeql-config.yml` in the template
(see `### Migration implications` for the exact file), referenced from the
inherited `codeql.yml` `init` step by `config-file:`, with **no** inline
`queries:` input on that step. A `src/lib.rs` that logs a request-derived string
through the R58 pipeline gives the acceptance check a positive; the same
construct under `tests/` gives it a negative.

BASELINE-REVIEW: F027 — the CodeQL scan runs where the platform supports it, with a language and build-mode matrix that the implementation must state — resolve the open "CodeQL Rust language/build-mode matrix" question recorded in `docs/port/BASELINE-REVIEW.md` (B3) as `languages: rust` with `build-mode: none`, mechanically determined rather than an owner choice — `rust/codeql-extractor.yml` at tag `codeql-cli/v2.26.4` declares `build_modes:` with the single value `none` (https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/codeql-extractor.yml, 2026-09-09), GitHub Docs lists Rust among the languages analyzed "without building the code", `codeql-action` v4.37.9 `src/autobuild.ts` treats `BuildMode.None` as "nothing to autobuild", and SurrealDB and copper-rs both run `languages: rust` with `build-mode: none` in production.

That resolves the recorded finding as its option (b), a mechanical implementation detail derived from CodeQL's own documentation. It needs no widening of R16's scope and no new parameter.

### Dominant choice

There is no dominant *Rust* choice, and saying otherwise would misreport the
field. The dominant behaviour among flagship Rust projects is **not to run
CodeQL at all**: 0 of the 20 surveyed repositories ships an advanced-setup
CodeQL workflow (2026-09-09). Rust's mainstream security lane is
`cargo-audit`/`cargo-deny` plus fuzzing, which R13 and R31 own.

Among the Rust repositories that *do* run advanced-setup CodeQL, the dominant
shape is **Alt-B: inline `queries: security-extended` on the `init` step with no
config file** — wasmCloud and copper-rs directly, SurrealDB also (it sets the
inline input in addition to its file). Three of the four sampled adopters select
`security-extended`; only SurrealDB adds `paths-ignore`. Note this population is
small enough that it is a signal, not a consensus, and it is weighted here below
the mechanism evidence in `### Principles and implementation`.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **Alt-A** — bare default suite, no `config-file:`, no `queries:` (ts's shape) | GitHub Docs, *Configuring advanced setup for code scanning*; `init/action.yml` (all inputs optional) | `open-telemetry/opentelemetry-rust` (`.github/workflows/codeql-analysis.yml`); ts-launch-blueprint `.github/workflows/codeql.yml` at `cb1cbcb` | `github/codeql-action` v4.37.9, published 2026-08-26T14:41:23Z |
| **Alt-B** — inline `queries: security-extended`, no config file | `init/action.yml` `queries:` input, tag `v4.37.9` | `wasmCloud/wasmCloud`; `copper-project/copper-rs`; `surrealdb/surrealdb` (in addition to its file) | same, 2026-08-26 |
| **Alt-C** — config file with `queries` + `paths-ignore` (py's shape, Rust-native contents) | GitHub Docs, *Customizing your advanced setup for code scanning* (`queries`, `paths`, `paths-ignore`, `query-filters`) | `surrealdb/surrealdb` `.github/codeql/codeql-config.yml`; py-launch-blueprint `.github/codeql/codeql-config.yml` at `b08bccf` | GitHub Docs page as retrieved 2026-09-09 |
| **Alt-D** — `security-and-quality` | same GitHub Docs page: "Queries from `security-extended`, plus maintainability and reliability queries" | `copper-project/copper-rs` | same |
| **Alt-E** — `security-experimental` | `rust/ql/src/codeql-suites/rust-security-experimental.qls` at `codeql-cli/v2.26.4` | none found in the Rust sweep | CodeQL CLI 2.26.4 bundle, pinned by action v4.37.9 (2026-08-26) |
| **Alt-F** — extractor option `cargo_cfg_overrides=-test` | `rust/codeql-extractor.yml` at `codeql-cli/v2.26.4`; `--extractor-option` in GitHub Docs, *Extractor options* | none found | CodeQL CLI 2.26.4 |
| **Alt-G** — `config:` inline-YAML input instead of a file | `init/action.yml` `config:` input, tag `v4.37.9` | none found in the Rust sweep | action v4.37.9 (2026-08-26) |

### Excluded by gate

*Gate applied per option before popularity was weighed. The six numbered fitness
gates in `## Required evidence` are crate-shaped; each is answered for this
`pattern` item under `### Fit for this template`, with `inapplicable` and a
reason where it does not bind. The exclusions below are the item's own
suitability gates.*

- **Alt-D (`security-and-quality`) — excluded, duplicated coverage.** Its entire
  Rust delta over `security-extended` is `rust/dead-code`, `rust/unused-value`
  and `rust/unused-variable`, all `@tags maintainability` with
  `@problem.severity recommendation` (verified at `codeql-cli/v2.26.4`). `rustc`
  and Clippy report these in the R28 lane at compile time; routing them through
  the Security tab misfiles maintainability findings as security alerts.
- **Alt-E (`security-experimental`) — excluded, currently empty and unbounded.**
  No `experimental/` directory exists under `rust/ql/src` at
  `codeql-cli/v2.26.4`, so it adds nothing today, and it would silently widen the
  scan to unreviewed experimental queries the moment any land upstream. A
  template must not carry a setting whose future content is unknown.
- **Alt-F (`cargo_cfg_overrides=-test`) — excluded, delivery unverified.** The
  option is real and documented for the CodeQL **CLI**
  (`--extractor-option extractor.option=value`, GitHub Docs *Extractor
  options*). `github/codeql-action/init` at v4.37.9 exposes **no**
  extractor-option input (its inputs are `tools`, `languages`, `build-mode`,
  `analysis-kinds`, `token`, `registries`, `matrix`, `config-file`, `db-location`,
  `config`, `queries`, `quality-queries`, `packs`, `external-repository-token`,
  `setup-python-dependencies`, `source-root`, `ram`, `threads`, `debug`,
  `debug-artifact-name`, `debug-database-name`, `trap-caching`,
  `dependency-caching`, `check-run-id`, `codeql-path`, `codeql-version`). A
  `CODEQL_EXTRACTOR_<LANG>_OPTION_<NAME>` environment form is referenced in
  secondary discussion but I could **not** confirm it on any first-party page I
  retrieved. Excluded rather than guessed.
- **Alt-G (inline `config:` string) — excluded, worse review ergonomics.** It is
  functionally equivalent to Alt-C and takes precedence over `config-file:`, but
  it buries a multi-key YAML document inside a workflow step, defeating B3's
  "one reviewable artifact". No adopter found. Keep it in reserve only if the
  template ever needs to compute the config at runtime.
- **Alt-A — excluded on the merits, not by gate.** It is a valid, cheap, shipping
  configuration (opentelemetry-rust) and remains the fallback if the
  recommendation's premises fail. It fails B1 and B2, which is a merits judgment
  recorded in `### Tradeoffs`, not a gate failure.

### Up-and-comers

- **`query-filters`** — metadata-tag include/exclude applied after suite
  selection, e.g. SurrealDB's `exclude: tags contain: experimental`. It is the
  precise instrument for trimming a suite without abandoning it, and it composes
  with `queries:`. Worth adopting **only if** the `security-extended` delta ever
  proves noisy on this codebase; adding it pre-emptively filters nothing (the two
  delta queries carry no `experimental` tag) and would be cargo-culted config.
- **The `config:` inline-YAML input** — new enough in `codeql-action` v4 that no
  Rust adopter appeared in a 648-hit code search. Useful for reusable workflows
  that template the config; not useful here.
- **Rust query growth.** `rust/command-line-injection` (CWE-078) exists on
  `github/codeql@main` at 2026-09-09 but is not in the 2.26.4 bundle; the
  changelog record shows Rust queries landing steadily since the 2025-06-30
  public preview through the 2025-10-14 GA and beyond
  (`https://github.blog/changelog/2025-10-14-codeql-scanning-rust-and-c-c-without-builds-is-now-generally-available/`).
  A template's config should name a *suite*, not individual queries, so that this
  growth arrives automatically.

### Fit for this template

**Fitness gates, answered per the rubric.**

1. *License compatible with `MIT OR Apache-2.0`* — **passes, partly
   inapplicable.** The artifact added is a YAML file in this repository, carried
   under the repository's own `MIT OR Apache-2.0` (`docs/port/PARAMETERS.md`,
   fixed). No dependency is added. `github/codeql` itself is MIT
   (`license.spdx_id: "MIT"`, `https://api.github.com/repos/github/codeql`). The
   CodeQL CLI's own terms restrict where the analysis may run; that restriction
   is what F027's visibility gate already encodes and is inherited, not decided
   here.
2. *Crate and dependency-tree MSRV within the policy* — **inapplicable: no crate
   is added.** The adjacent binding constraint is the analysis toolchain: CodeQL
   supports "Rust editions 2021 and 2024" and "Requires `rustup` and `cargo` to
   be installed. Features from nightly toolchains are not supported"
   (`https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/`).
   The fixed `rust-edition = 2024` and the stable-only `msrv-policy` are both
   inside that set, so the recommendation is compatible with them and requires no
   change to either.
3. *No open RustSec advisory; `unsafe` posture stated* — **inapplicable: no crate,
   so no RustSec package page exists to query.** `unsafe` posture of the change
   itself: the config file contains no code and cannot introduce `unsafe`. Worth
   recording in the other direction — the extended suite's
   `rust/access-after-lifetime-ended` is a detector *for* the `unsafe`
   pointer-lifetime class R06 governs.
4. *Builds and is tested on every OS in `ubuntu-latest, macos-latest`* —
   **inapplicable to the artifact; noted for the lane.** The CodeQL job is
   single-runner `ubuntu-latest` in both source repositories (py
   `.github/workflows/codeql.yml`, ts same file at `cb1cbcb`) and in every Rust
   adopter surveyed. A YAML config file is OS-independent. The fixed
   `target-os-matrix` governs the build/test matrix, not this scan; no macOS
   runner is required and Windows is not in scope.
5. *Default features and async-runtime coupling* — **inapplicable: no crate, no
   Cargo features, no runtime.** The analysis-configuration analogue is worth
   recording: the Rust extractor's own defaults are **all Cargo features enabled**
   ("By default all features are enabled") and **`cfg(test)` enabled**
   (`rust/extractor/src/config.rs`), i.e. the scan sees a maximal build
   configuration unless told otherwise.
6. *Binary-size and compile-time cost, qualitatively* — **binary size:
   inapplicable** (nothing is linked). *CI cost:* the extended suite adds two
   taint-tracking queries to sixteen, a marginal increase against the dominant
   cost, which is Rust extraction via rust-analyzer under `build-mode: none`.
   SurrealDB budgets `timeout-minutes: 120` and cleans disk space before the job,
   and its config comments claim `paths-ignore` reduces analysis time. **The
   mechanism behind that claim is unverified:** GitHub Docs says these keys
   restrict which files are *scanned*, but I found no first-party statement on
   whether Rust extraction is skipped for ignored paths or the results are
   filtered afterwards. Treat the alert-volume reduction as certain and the
   wall-clock reduction as unproven.

**Per target shape.**

*CLI.* The strongest concrete fit. A CLI reads argv, environment and files and
writes to a terminal and to logs. `rust/log-injection` — the extended suite's
one genuinely new class — is exactly the argv-to-log-sink flow, and it is
`@problem.severity error` at `@security-severity 6.1`. `rust/path-injection`
(CWE-022) is already in the default suite and is the other canonical CLI class.
On layout: a CLI crate's integration tests under `tests/` typically shell out
with adversarial argument strings, which is precisely the fixture noise B2 wants
suppressed — and those *are* reachable by `paths-ignore`.

*Library.* The weakest fit for `paths-ignore` and the strongest for `unsafe`
coverage. A library's tests are overwhelmingly `#[cfg(test)]` units inside
`src/`, which no path glob reaches (Finding 2), so B2 delivers least here. But a
library is where `unsafe` appears in a Rust template, and
`rust/access-after-lifetime-ended` (`@security-severity 9.8`) is the extended
suite's detector for it. If R06 forbids `unsafe` workspace-wide, the query costs
nothing and finds nothing; if R06 permits it anywhere, the query is the single
best reason on this list to select the extended suite.

*Web service.* The best fit overall, because the default suite's HTTP-shaped
queries (`rust/request-forgery` CWE-918, `rust/xss`, `rust/sql-injection`,
`rust/insecure-cookie`, `rust/cleartext-transmission`) are already active and the
extended suite closes the logging gap on the request path — a web handler that
logs a header or a path segment is the textbook CWE-117 sink. `paths-ignore`
also has the most to exclude here, since a web service ships integration tests
that construct hostile requests on purpose.

*Fit against the py and ts precedent.* py's *intent* transfers; py's *values* do
not. `security-extended` transfers (the selector is language-independent, and the
Rust delta is real, if smaller than Python's). `tests/**` transfers with a stated
partial-coverage caveat. `docs/**` does **not** transfer — it is inert for a Rust
extractor whose `file_types` is `.rs` alone. ts's shape (Alt-A) is not a
considered rejection to inherit; `## Context` and the ported file's untouched
commented-out `# queries: security-extended,security-and-quality` line both show
it as an unexamined gap.

### Recommendation

**Adopt Alt-C: ship `.github/codeql/codeql-config.yml`, referenced from the
inherited CodeQL workflow's `init` step by `config-file:`, with Rust-derived
contents — and with no inline `queries:` input on that step.**

```yaml
name: "rs-launch-blueprint codeql"

queries:
  - uses: security-extended

paths-ignore:
  - tests/**
  - benches/**
  - fuzz/**
```

The four decisions inside that file, each with its own reason:

1. **`security-extended`, in the file rather than inline.** It adds
   `rust/log-injection` and `rust/access-after-lifetime-ended` — the CWE-117
   class the template's logging pipeline (R58/R59) creates, and the CWE-825
   pointer-lifetime depth that R06's `unsafe` policy makes relevant. Placing it
   in the file keeps one reviewable artifact (B3) and removes the documented
   override hazard: an inline `queries:` input "overrides the same setting in a
   configuration file" unless `+`-prefixed. Where the shapes differ, follow the
   mechanism evidence over the 3-of-4 inline-input practice.
2. **`tests/**` — with the caveat recorded in the file's comments.** It excludes
   integration tests, which is where a Rust template's adversarial fixtures live.
   It does **not** reach `#[cfg(test)]` unit tests inside `src/`, and the
   extractor enables `cfg(test)` by default (Finding 2). Record this so a future
   maintainer does not read the line as py's complete exclusion.
3. **`benches/**` and `fuzz/**` — conditional, include the line only when the
   directory exists.** Both are Cargo-standard locations for code that is
   deliberately pathological, and both are excluded by SurrealDB. Their presence
   depends on R32 (`test-harness-and-execution`) and R33
   (`property-and-snapshot-testing`); a `paths-ignore` entry for a directory that
   does not exist is inert but misleading. **This is the integration prerequisite
   for this item:** reconcile the final path list against R32's chosen layout
   before the file is written.
4. **`examples/**` is deliberately *not* excluded, and neither are `docs/**` nor
   `target/**`.** Examples are shipped code that a template consumer copies into
   their own project, so a vulnerability in an example propagates and must be
   scanned — this is a substantive departure from the reflex of excluding
   everything non-`src`. `docs/**` is inert because the Rust extractor's
   `file_types` is `.rs` only. `target/**` is `.gitignore`d by `cargo new` and
   therefore absent from the Actions checkout.

Because the CodeQL scan is advisory rather than merge-blocking in both source
repositories, the residual risk of the extended suite is a false positive in the
Security tab, not a blocked pull request — which is why the two medium-precision
queries are worth taking.

### Ranked runner-up

**Alt-B — inline `queries: security-extended` on the `init` step, no config
file.** It preserves B1 (the whole `security-extended` delta) and B3's
"no silent loss" property trivially, since with no file there is nothing to
override. It is the dominant Rust practice (wasmCloud, copper-rs, and SurrealDB's
own inline line). It sacrifices only B2, which Finding 2 shows is partial in Rust
anyway.

**The condition under which it wins:** if R32 settles on a layout with **no**
`tests/`, `benches/` or `fuzz/` directories — a template whose tests are
entirely `#[cfg(test)]` modules inside `src/` — then `paths-ignore` has nothing
left to exclude, the config file would carry a single `queries` key, and a
one-line workflow input expresses that better than a separate file. It also wins
outright if the owner decides the template must add no new files to `.github/`.

*Second runner-up, for completeness:* **Alt-A** (ts's shape, change nothing). It
wins only if the owner rules that CodeQL on Rust must stay at whatever GitHub
ships by default — a defensible position given that 0 of 20 flagship Rust
projects run advanced-setup CodeQL at all.

### Tradeoffs

**Versus Alt-B (inline `queries:`).** The recommendation gives up one line of
workflow YAML in exchange for a new file, and it gives up the majority Rust
practice. Accepted because `paths-ignore` exists nowhere else, because the config
file is the only place both levers can be reviewed together, and because the
inline input's override semantics are a live footgun for the next person who
adds a second query source. The cost is one extra file in `.github/codeql/`,
which py already carries and which the template's users will recognise.

**Versus Alt-A (change nothing).** The recommendation gives up the simplest
possible configuration and accepts a modest false-positive risk from two
medium-precision queries. Accepted because those two queries cover the template's
own logging and `unsafe` surfaces, because the scan is advisory rather than
blocking, and because a **template** is judged on the defaults it teaches: a
template that ships CodeQL wired to its narrowest setting teaches the wrong
default. The concrete cost if wrong is noise in the Security tab, remediable
without touching code by adding a `query-filters` exclude.

**Versus Alt-D (`security-and-quality`).** The recommendation gives up three
maintainability queries. Accepted with confidence: `rustc` and Clippy report the
same conditions at compile time in R28's lane, so this trades zero real coverage
for a cleaner separation between the security surface and the lint surface.

**Versus Alt-F (extractor option `-test`).** The recommendation gives up the only
mechanism that would fully match py's "tests are not scanned" property, leaving
`#[cfg(test)]` unit tests inside `src/` in scope. Accepted because the option's
delivery from a GitHub Actions workflow is unverified on first-party
documentation, and shipping an unverified mechanism in a template is worse than
shipping a documented partial one. Recorded as the re-verify trigger below.

**What the recommendation costs unconditionally.** One `paths-ignore` list that
must be kept in step with R32's layout — a list that silently stops matching if a
directory is renamed. The acceptance check A2 is what makes that drift visible.

### Parameters

`owns` — none. R16 owns no parameter (`## Couplings`, `owns:` is empty).

`assumes rust-edition = 2024` — CodeQL supports "Rust editions 2021 and 2024",
so the fixed value is inside the supported set and needs no change
(`https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/`, 2026-09-09).

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` —
compatible: the CodeQL Rust extractor requires stable `rustup` and `cargo` and
does not support nightly-toolchain features; a stable-only MSRV policy satisfies
that.

`assumes license = MIT OR Apache-2.0` — the added file carries the repository
licence; no dependency licence is introduced.

`assumes target-os-matrix = ubuntu-latest, macos-latest` — not exercised by this
item. The CodeQL job runs on `ubuntu-latest` alone in both source repositories
and in every Rust adopter surveyed; a YAML config file is OS-independent.

No `CONFLICT:` lines. No consumed parameter needs to change.

*Integration prerequisite, not a parameter conflict:* the final `paths-ignore`
entries depend on the directory layout R32 (`test-harness-and-execution`)
chooses, and on whether R33 introduces `fuzz/`. R32 is not a registry dependency
of R16 (`## Couplings` records `consumes:` empty and `related: none`), so this is
recorded as a reconciliation step at implementation time rather than as a
coupling change.

### Migration implications

**New file — `.github/codeql/codeql-config.yml`.** The document shown in
`### Recommendation`, plus comments recording (a) that `cfg(test)` unit tests
inside `src/` are extracted by default and are *not* excluded by the `tests/**`
line, (b) that `examples/**` is deliberately scanned, and (c) that `docs/**` and
`target/**` are omitted because they are inert for the Rust extractor.

**Edited file — `.github/workflows/codeql.yml`** (inherited under F027; this is
the only change this item makes to it). Add one input to the `init` step:

```yaml
      - name: Init CodeQL
        uses: github/codeql-action/init@v4.37.0
        with:
          languages: rust
          build-mode: none
          config-file: ./.github/codeql/codeql-config.yml
```

Do **not** add a `queries:` input to that step — it would override the config
file's `queries` key unless `+`-prefixed. The `languages: rust` and
`build-mode: none` values are the mechanically-determined matrix from the
`BASELINE-REVIEW:` line above, not choices made here.

**Edited file — `SECURITY.md` (or the repository's code-scanning section).** py's
config carries a prominent note that advanced setup and GitHub's "default setup"
are mutually exclusive: with a workflow-supplied config in place, the repository
setting under *Settings → Code security → Code scanning* must stay disabled or
the SARIF upload is rejected. This applies identically to forks of a template and
should be stated where a template user will find it. Carry the note across.

**No changes to** `Cargo.toml` (no dependency), the CI workflow, the release
lane, or any parameter in `docs/port/PARAMETERS.md`.

**Ledger effect.** F045 moves from `DIVERGENT` to a Rust-specific adoption: the
*policy* is adopted from py, the *values* are re-derived for Rust
(`docs/port/COMMONALITY.md:44`). The recommended follow-on for the py/ts
harmonisation project is to add `queries: security-extended` to ts's `init` step,
while leaving each repository's `paths-ignore` contents different by design.

### Validation strategy

**Executed in this run (static, no CodeQL database required).**

The suite-delta derivation was carried out and is reproducible:

```bash
# 1. Which CLI bundle does the pinned action actually run?
curl -sS -H "User-Agent: <ua>" \
  https://raw.githubusercontent.com/github/codeql-action/v4.37.9/src/defaults.json
# -> {"bundleVersion":"codeql-bundle-v2.26.4","cliVersion":"2.26.4", ...}

# 2. Read the two selector files the Rust suites apply.
curl -sS https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/misc/suite-helpers/code-scanning-selectors.yml
curl -sS https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/misc/suite-helpers/security-extended-selectors.yml
# (all four files verified byte-identical to the same paths at `main`, 2026-09-09)

# 3. Read every Rust security query's metadata at the pinned tag and apply them.
curl -sS https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/ql/src/queries/security/<CWE>/<Q>.ql \
  | grep -E '@(kind|precision|problem.severity|id|tags)'
```

*Result obtained:* default 16 security-alert queries, `security-extended` 18;
delta `rust/log-injection` and `rust/access-after-lifetime-ended`.
*Independently cross-checked* against
`https://codeql.github.com/codeql-query-help/rust/rust-log-injection/`, which
lists that query's suites as `rust-security-extended.qls` and
`rust-security-and-quality.qls` — the derivation and GitHub's own query help
agree. This satisfies acceptance criterion **A1** by static derivation.

**Proposed, not yet run — the CLI-resolved query set (A1, dynamic).** Requires
downloading the CodeQL bundle (hundreds of MB), which was out of budget here:

```bash
codeql resolve queries codeql/rust-queries:codeql-suites/rust-code-scanning.qls    > default.txt
codeql resolve queries codeql/rust-queries:codeql-suites/rust-security-extended.qls > extended.txt
diff default.txt extended.txt
```

*Expected:* exactly two additional entries, `LogInjection.ql` and
`AccessAfterLifetime.ql`, at bundle 2.26.4.

**Proposed, not yet run — the path-exclusion behaviour test (A2).** Requires
building a CodeQL database, so it belongs to the implementation task:

```bash
codeql database create /tmp/rsdb --language=rust --build-mode=none --source-root=.
codeql database analyze /tmp/rsdb \
  codeql/rust-queries:codeql-suites/rust-security-extended.qls \
  --format=sarif-latest --output=/tmp/out.sarif
```

*Expected:* with an intentional `rust/log-injection` sink placed in `src/`, the
SARIF contains a `rust/log-injection` result; with the same construct placed
under `tests/`, it does not. **The same run is the empirical test of Finding 2:**
place a `#[cfg(test)] mod tests` sink inside `src/lib.rs` and confirm it *is*
reported despite `paths-ignore: tests/**` — that is the observation which proves
the partial-exclusion caveat rather than merely arguing it from the extractor
source.

**Proposed, not yet run — the override guard (A3).** In the template's CI, assert
that `.github/workflows/codeql.yml` sets `config-file:` and does **not** set
`queries:` on the same step:

```bash
yq -e '.jobs.analyze.steps[] | select(.uses | test("codeql-action/init")) |
       (.with."config-file" != null) and (.with.queries == null)' \
  .github/workflows/codeql.yml
```

*Expected:* exit 0. This is a cheap regression guard against the documented
override semantics and fits the R12/R15 guard lane.

**Proposed — first-run calibration.** After the first scheduled scan on a public
repository, read the Security tab and confirm that no alert originates from an
excluded path and that the two extended-suite queries produce no false positives
on the template's own code. If they do, add a `query-filters` exclude rather
than reverting to the default suite.

### Confidence & re-verify trigger

**High confidence** in the mechanism findings, because they come from the
program text at the exact released tag the pinned action runs, not from
documentation prose: the 16-versus-18 suite delta, the `cfg(test)`-enabled-by-
default extractor behaviour, `build_modes: [none]`, and `file_types: [.rs]`.

**Medium confidence** in the *value* judgment that the two added queries justify
the file. It rests on the template having a logging pipeline that touches
user-controlled data (R58/R59, not yet decided) and on R06 permitting some
`unsafe` (not yet decided). If R58 lands a pipeline that never logs
request-derived data *and* R06 forbids `unsafe` workspace-wide, the extended
suite's delta collapses to near-zero value and Alt-B or Alt-A becomes correct.

**Low confidence** in the CI wall-clock claim. That `paths-ignore` reduces
*analysis time* for a `build-mode: none` Rust extraction is asserted in
SurrealDB's config comments but is not stated on any first-party page I
retrieved. The alert-volume reduction is certain; the time reduction is not.

**Explicitly unverified, recorded rather than guessed:** (1) whether a
`CODEQL_EXTRACTOR_RUST_OPTION_CARGO_CFG_OVERRIDES` environment variable delivers
extractor options from a workflow — no first-party page I retrieved documents an
environment-variable form, and `init/action.yml` at v4.37.9 exposes no
extractor-option input; (2) whether `paths-ignore` skips Rust extraction or
filters results afterwards; (3) issue-responsiveness for `github/codeql` itself
(only `github/codeql-action` was sampled).

**Re-verify when any of these changes.**

- `github/codeql-action`'s pinned `bundleVersion` advances past
  `codeql-bundle-v2.26.4` — re-run the delta derivation at the new
  `codeql-cli/vX.Y.Z` tag. `rust/command-line-injection` is already on `main` and
  will land in a future bundle, moving the counts to 17 and 19.
- An `experimental/` directory appears under `rust/ql/src` — Alt-E stops being
  empty and its exclusion needs restating.
- A Rust security query ships with `@precision high` and
  `@problem.severity recommendation` — the extended selector's *first* include
  block would then widen the delta too, which no Rust query triggers today.
- `rust/extractor/src/config.rs` stops seeding `cfg(test)`, or the CodeQL Action
  gains a first-class extractor-option input — Alt-F becomes viable and the
  partial-exclusion caveat may be closeable.
- R32 or R33 settles the test/bench/fuzz layout — reconcile the `paths-ignore`
  list before the file is written.
- R06 forbids `unsafe` workspace-wide and R58 rules out logging user-controlled
  data — re-weigh the extended suite against Alt-B.

**Suggested cadence:** re-verify at each `codeql-action` major release, and
before the template's first public release.

### Sources

**Primary program text, pinned (all retrieved 2026-09-09).**

- `https://raw.githubusercontent.com/github/codeql-action/v4.37.9/src/defaults.json` — `bundleVersion: codeql-bundle-v2.26.4`, `cliVersion: 2.26.4`.
- `https://raw.githubusercontent.com/github/codeql-action/v4.37.9/init/action.yml` — the `queries`, `config-file`, `config`, `packs` input descriptions and the full input list.
- `https://api.github.com/repos/github/codeql/contents/rust/ql/src/codeql-suites?ref=codeql-cli/v2.26.4` — the six Rust suite files.
- `https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/ql/src/codeql-suites/rust-code-scanning.qls` and `.../rust-security-extended.qls` — each applies a shared selector file from `codeql/suite-helpers`.
- `https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/misc/suite-helpers/code-scanning-selectors.yml` and `.../security-extended-selectors.yml` — the precision/severity/tag selectors.
- `https://api.github.com/repos/github/codeql/git/trees/a5bf0eb902d6abc7d58b7dc22174fe946d510879?recursive=1` — recursive tree of `rust/ql/src` at `codeql-cli/v2.26.4`; 54 `.ql` files, 19 under `queries/security/`, no `experimental/` directory.
- `https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/ql/src/queries/security/**/*.ql` — the 19 security queries' `@kind`/`@precision`/`@problem.severity`/`@tags` metadata.
- `https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/ql/src/queries/unusedentities/*.ql` — the three maintainability queries `security-and-quality` adds.
- `https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/extractor/src/config.rs` — `to_cfg_overrides` seeds `enabled_cfgs` with `test`.
- `https://raw.githubusercontent.com/github/codeql/codeql-cli/v2.26.4/rust/codeql-extractor.yml` — `build_modes: [none]`, `file_types: [.rs]`, and the `cargo_cfg_overrides` / `cargo_features` option definitions.

**Documentation.**

- `https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning` — `config-file`, the suite descriptions, and *Specifying directories to scan*: "You can use this option when you run the CodeQL actions on an interpreted language (Python, Ruby, and JavaScript/TypeScript) or when you analyze a compiled language without building the code (currently supported for C/C++, C#, Java and Rust)."
- `https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/` — "Rust editions 2021 and 2024"; "Requires `rustup` and `cargo` to be installed. Features from nightly toolchains are not supported."
- `https://codeql.github.com/codeql-query-help/rust/rust-log-injection/` — query suites: `rust-security-extended.qls`, `rust-security-and-quality.qls`.
- `https://docs.github.com/en/code-security/reference/code-scanning/codeql/codeql-cli/extractor-options` — `--extractor-option extractor_option_name=extractor_option_value`.
- `https://github.blog/changelog/2025-10-14-codeql-scanning-rust-and-c-c-without-builds-is-now-generally-available/` — Rust GA on 2025-10-14 at CodeQL CLI 2.23.3, GHES 3.20; "We now identify issues for all OWASP Top 10 categories, except *A06:2021-Vulnerable and Outdated Components*."
- `https://github.blog/changelog/2025-06-30-codeql-support-for-rust-now-in-public-preview/` — the preceding public-preview milestone.
- `https://doc.rust-lang.org/book/ch11-03-test-organization.html` — unit tests in `#[cfg(test)] mod tests` inside `src/`; integration tests in `tests/`.
- `https://doc.rust-lang.org/cargo/guide/project-layout.html` — `target/` is generated and git-ignored; `benches/`, `examples/`, `tests/` are Cargo-standard.

**Practice evidence (all retrieved 2026-09-09).**

- `https://raw.githubusercontent.com/surrealdb/surrealdb/main/.github/codeql/codeql-config.yml` and `.../.github/workflows/codeql.yml` — 32,997 stars.
- `https://raw.githubusercontent.com/wasmCloud/wasmCloud/main/.github/workflows/codeql.yml` — 2,435 stars; `queries: security-extended` with no config file.
- `https://raw.githubusercontent.com/open-telemetry/opentelemetry-rust/main/.github/workflows/codeql-analysis.yml` — 2,700 stars; bare default suite.
- `https://raw.githubusercontent.com/copper-project/copper-rs/master/.github/workflows/codeql.yml` — `build-mode: none`, `security-extended,security-and-quality`.
- `https://api.github.com/search/code?q=...` — two authenticated code searches, 648 and 109 total hits.
- `https://api.github.com/repos/<o>/<r>/contents/.github/workflows` — the 20-repository negative sweep.

**Maintenance figures and rubric.**

| Subject | Figure | Endpoint |
|---|---|---|
| `github/codeql-action` last release | `v4.37.9`, published 2026-08-26T14:41:23Z | `GET https://api.github.com/repos/github/codeql-action/releases?per_page=3` |
| `github/codeql-action` stars / archived / pushed | 1,638 / `false` / 2026-09-08T23:07:40Z | `GET https://api.github.com/repos/github/codeql-action` |
| `github/codeql-action` open issues | 158 | `GET https://api.github.com/search/issues?q=repo:github/codeql-action+is:issue+is:open` (`total_count`) |
| `github/codeql-action` issue responsiveness | median 0.04 days to first maintainer response (n=7 of the 10 most recently opened issues); 3 unanswered | 10 most recent issues via `search/issues`, then `/issues/<n>/comments` |
| `github/codeql` stars / archived / pushed / licence | 10,067 / `false` / 2026-09-09T03:05:07Z / MIT | `GET https://api.github.com/repos/github/codeql` |
| `github/codeql` open issues | 995 | `GET https://api.github.com/search/issues?q=repo:github/codeql+is:issue+is:open` |

**Maintenance state: `active`** for both `github/codeql-action` and
`github/codeql` — released within the last 14 days, pushed within 24 hours,
neither archived, sub-day median maintainer response. No `at-risk` or `dormant`
signal: no unpatched advisory, no broken build on current stable, no maintainer
notice.

**Source-repository evidence.**

- py-launch-blueprint at pinned commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read via `git -C ~/c/py-launch-blueprint show b08bccf:<path>`: `.github/codeql/codeql-config.yml` (`queries: - uses: security-extended`; `paths-ignore: tests/**, docs/**`) and `.github/workflows/codeql.yml` (`config-file: ./.github/codeql/codeql-config.yml`).
- ts-launch-blueprint at pinned commit `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, read via `git -C ~/c/ts-launch-blueprint show cb1cbcb:<path>`: `.github/workflows/codeql.yml` — the `init` step sets only `languages` and `build-mode`, and carries the upstream starter template's untouched commented-out line `# queries: security-extended,security-and-quality`. `git ls-tree` confirms no `.github/codeql/` directory exists.
- `docs/port/COMMONALITY.md:44` (F045), `:33` (F027); `docs/port/areas/ci-workflows.md:44`; `docs/port/BASELINE-REVIEW.md:189` (the open Rust matrix question, B3) and `:43` (F027's row); `docs/port/PARAMETERS.md` (the four fixed parameters).

**Method notes.** Every figure above was collected with `curl -sS` and a
`User-Agent: rs-launch-blueprint-research/1.0 (steve@conceptm.com)` header
against the endpoints named in each row, on 2026-09-09 (UTC). Three disclosures.
*First*, unauthenticated GitHub REST exhausted its 60-request hourly quota partway
through the survey (`GET https://api.github.com/rate_limit` showed 14 remaining);
the remaining GitHub REST and code-search calls were made against the identical
endpoints with an added `Authorization: Bearer $(gh auth token)` header, and
GitHub code search requires authentication in any case. No figure changes between
the authenticated and unauthenticated paths. *Second*, neither
`https://crates.io/api/v1/crates/<name>` nor `https://rustsec.org/packages/<name>.html`
was queried: this is a `pattern` item that adds a YAML configuration file and no
crate, so the 90-day-downloads, all-time-downloads, last-release, and advisories
rows of the figure table have no subject — each is marked `inapplicable` with its
reason under `### Fit for this template`, and the maintenance rubric is instead
applied to the two GitHub repositories that supply the mechanism. *Third*, the
two shared selector files and the two Rust suite files were fetched at **both**
`main` and `codeql-cli/v2.26.4` and diffed: all four are byte-identical, so the
16-versus-18 derivation holds at the pinned bundle and the Sources list cites the
pinned URLs. *Fourth*, neither source repository was fetched over HTTP: py-launch-blueprint and
ts-launch-blueprint were read from the local pinned clones at the commits named
in the task (`b08bccf` and `cb1cbcb`) via `git show`, per the task's instruction
for the private ts repository; py's local `HEAD` is `c1216c6`, so the pinned
`b08bccf` was addressed explicitly on every read.

*What I could not verify.* (1) No first-party page I retrieved documents a
`CODEQL_EXTRACTOR_<LANG>_OPTION_<NAME>` environment-variable form for delivering
extractor options from a GitHub Actions workflow; `docs.github.com/.../extractor-options`
documents only the CLI `--extractor-option` flag and file-based configuration,
and `init/action.yml` at v4.37.9 exposes no such input. Alt-F is excluded on that
basis rather than recommended on an assumption. (2) Whether `paths-ignore` causes
the Rust extractor to skip files or filters results after extraction is not
stated on any page I retrieved; the CI wall-clock benefit is therefore reported as
unproven while the alert-volume benefit is reported as certain. (3) Issue
responsiveness was sampled for `github/codeql-action` only, not `github/codeql`.
(4) The 20-repository negative sweep detects advanced-setup workflows only and
cannot see repositories using GitHub's default setup; that blind spot is stated
in `### Landscape`. (5) `codeql resolve queries` was not executed — it needs the
multi-hundred-megabyte CLI bundle — so the suite delta rests on the static
selector derivation plus the query-help cross-check, and the dynamic check is
listed as proposed.
