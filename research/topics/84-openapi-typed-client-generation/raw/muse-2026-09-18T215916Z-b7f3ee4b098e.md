# Raw research report — R84 openapi-typed-client-generation (Muse engine)

Actor: `research-muse-2026-09-18T215916Z-b7f3ee4b098e`. Retrieval date for all
figures: 2026-09-19. Item kind: `crate`. Probe host: macOS 15 aarch64,
rustc 1.98.0 (Homebrew), plus rustup toolchains incl. 1.96.0 (the MSRV floor:
stable is 1.98.1 per `https://static.rust-lang.org/dist/channel-rust-stable.toml`,
so stable-minus-2 = 1.96).

Binding HTTP-surface input: org REST API Design Standard v2.0.0
(smorinlabs/rest-standards commit `0850d43e`), read read-only via `git show`.
The rule that decides this item is **R4.1** (`rest-api-standard.md:742-747`):
"Every API MUST publish an OpenAPI document as the contract source of truth —
version 3.1, or 3.2 only where the team's full toolchain (parser, linter,
generator, docs renderer) is verified against it." Related: **R4.2**
(`:754-755`): "The description document is authoritative: changes to it MUST be
gated on an automated compatibility check against the previous version."
Consequence: the committed snapshot this item generates from WILL be OpenAPI
3.1 (R71 must comply too), and the client generator is explicitly part of the
toolchain R4.1 requires to be verified against 3.1. Any candidate that cannot
parse 3.1 fails fitness for this template regardless of maturity.

### Landscape

Category: ahead-of-time typed HTTP-client generation from an OpenAPI document
for Rust consumers. Rust has no first-party generator, so bin 1 is empty by
evidence, not by omission.

- Bin 1 — built-in or first-party toolchain: none. The Rust project ships no
  OpenAPI tooling; `cargo` has no client-generation subcommand. The annual
  Rust survey does not track this niche (stated as a limit, not used as
  evidence either way).
- Bin 2 — established industry standard:
  - `openapi-generator` (OpenAPITools, JVM, Apache-2.0) with its STABLE `rust`
    (reqwest) client generator — the multi-language incumbent, 26,753 stars.
  - `progenitor` 0.15.0 (Oxide Computer, MPL-2.0) — the established Rust-native
    generator: macro, `build.rs`, and static-crate (`cargo-progenitor`) modes;
    OpenAPI **3.0.x only** (README line 3-4; hard error proven in probes).
- Bin 3 — up-and-comer (3.1-native, young):
  - `openapi-to-rust` 0.17.0 (gpu-cli, MIT) — OpenAPI 3.0/3.1, experimental
    3.2; standalone CLI writing committed source files plus `--check` for CI.
  - `spargen` 0.4.0 (getkono, MIT OR Apache-2.0, self-labelled Alpha) —
    OpenAPI 3.1.x/3.2.x only, rejects 3.0; `build.rs`/macro modes.
- Surveyed but not shortlisted (map completeness): `openapi-codegen` 0.1.0
  (2,850 all-time downloads, no repository URL — negligible adoption, single
  0.x release); `openapi-nexus` 0.2.3 (1,107 downloads — same); `paperclip`
  0.9.7 (actix-bound schema-side tooling, not a client generator — wrong
  scope); `oas3` 0.22.0 / `openapiv3` 2.2.0 (parsers, not generators —
  evaluated only as the substrate of the hand-rolled alternative);
  `openapi31to30` 0.0.1 (a 3.1→3.0 downconverter; evidence the ecosystem feels
  the 3.1 gap, and the workaround this report rejects in Principles).
  No `utoipa`-adjacent client-generation story exists: crates.io search for
  "utoipa client" (2026-09-19) returns no client generator, and utoipa is
  server-side schema emission only.

Authority (why each counts): (1) W2-REST R4.1/R4.2 — binding owner standard,
  quoted above; it sets the 3.1 floor. (2) Maintainers' own documentation —
  progenitor README (usage modes, 3.0.x scope), openapi-generator `rust`
  generator docs (STABLE, reqwest, async), openapi-to-rust README + CI
  (56-spec corpus, compile-checked OpenAI/Anthropic specs), spargen README
  (3.1-native rationale, alpha label). (3) utoipa 5.4.0 source
  (`src/openapi.rs`, `OpenApiVersion::Version31` is `#[default]`,
  "Will serialize to `3.1.0`") — proves the likely R71 schema is 3.1 even
  before R71 lands. (4) Oxide's production use of progenitor/dropshot and the
  crates.io reverse-dependency graph (adoption, not assertion). A single blog
  post was used for nothing.

Practice evidence (well-regarded = adoption + maintainer standing):
- progenitor (72 reverse deps): `zerotier-one-api` / `zerotier-central-api`
  (ZeroTier, widely deployed networking vendor), `feldera-rest-api`
  (github.com/feldera/feldera, streaming-SQL vendor), `edgee-api-client`
  (github.com/edgee-cloud/edgee, open-source analytics), `photon-api`,
  `api-bones-progenitor`. Oxide itself generates clients for its own
  Dropshot APIs (README: "The primary target is OpenAPI documents emitted by
  Dropshot-generated APIs").
- `openapiv3` (183 reverse deps, incl. `dropshot`, `progenitor-impl`,
  `specta`) — de-facto 3.0 parser, stable-quiet.
- `oas3` (36 reverse deps, incl. `slumber_import` — Slumber is a popular
  open-source API client) — active 3.1-era parser.
- openapi-to-rust (0 reverse deps) and spargen (1, its own macro): no
  third-party adoption yet — the central risk of the recommendation, stated
  plainly.
- openapi-generator `rust`: industry-standard distribution (26,753 stars,
  v7.25.0 released 2026-08-24); per-language adopter lists are not published,
  so no Rust-specific adopter is claimed (gap).

Fit framing (used in Principles): the template needs py's shape — a standalone
recipe against the committed snapshot file (`Justfile:322`: `uvx
openapi-python-client generate --path docs/api/openapi.json --output-path
{{out}} --overwrite`), committed reviewable output, drift caught in CI — but
consuming an OpenAPI **3.1** snapshot per R4.1.

### Principles and implementation

Shared requirement (source: py precedent + owner direction 2026-09-04 +
W2-REST): a typed API client is GENERATED from the committed OpenAPI snapshot
by a recipe, never hand-written; regeneration is reproducible; drift between
snapshot and generated code fails CI. Agreement level: architectural pattern
(generate-don't-handwrite, snapshot-is-input) plus policy (CI drift gate).
What must agree across py/ts/rs: the pattern, the snapshot-as-input rule, and
the observable acceptance criteria below. What may vary: the generator tool
per ecosystem (justified: no single generator is idiomatic Rust AND 3.1-native
AND dependency-light; see alternatives).

Essential behaviors: (1) input is the committed snapshot file, unmodified
(R4.2's authoritative document); (2) output is typed (request/response structs
match the schema; per-operation methods); (3) output is committed and
reviewable; (4) `just <recipe> --check` (or regenerate-and-diff) fails CI on
drift; (5) operation-id curation (F312, R71) flows through to stable generated
method names.

Observable acceptance criteria: AC1 — deleting the generated directory and
re-running the recipe reproduces it byte-identical; AC2 — editing the snapshot
then running `--check`/diff fails; AC3 — the generated crate compiles on the
MSRV floor (1.96) and passes `cargo audit`; AC4 — a mock-server round trip
against one operation returns typed values (planned; see Validation).

Cross-repo comparison (HIGH question): py realizes the pattern with
`openapi-python-client` + `Justfile:client-python` (evidence:
`/Users/stevemorin/c/py-launch-blueprint/Justfile:321-323`; operation-id
curation at `src/py_launch_blueprint/web/app.py:77-80`,
`generate_unique_id_function=_operation_id`, `<tag>-<function>`). ts has no
web service (F303) so the capability is inapplicable there — justified
absence, not drift; if ts ever gains a service, its generator pick is a new
decision, and this report's rationale (recipe shape + drift gate + operation-id
dependence) transfers. rs realizes it with `openapi-to-rust generate` +
`--check` (this report). No shared low-level tool is recommended: py's tool
cannot emit Rust, and the one cross-language candidate (openapi-generator)
fails fit (JVM toolchain + incomplete 3.1 per open meta-issue #14943). The
divergence is in mechanism only; the pattern and criteria agree.

Architectural alternatives compared before libraries: (A) standalone recipe
(openapi-to-rust CLI, cargo-progenitor static crate, openapi-generator CLI) —
matches py exactly; generated code is committed, diffable, and adds zero
codegen to every `cargo build`. (B) `build.rs`/proc-macro embedding
(progenitor macro/`Generator`, spargen) — generated code is invisible at
review time (OUT_DIR) or inflates every compile (macro re-expansion); drift
gating needs extra harness; worse fit for a template whose contract emphasizes
reviewable artifacts (F332). (C) hand-rolled codegen on `openapiv3`/`oas3` —
rejected: the template would own a parser+emitter forever to save one tool
pin; violates the spirit of "never hand-written" by owning the writer; no
reference implementation exists. (D) 3.1→3.0 downconversion
(`openapi31to30`-style `sed`/convert step) feeding progenitor — rejected: it
generates from a DERIVED document, not the committed snapshot (breaks R4.2's
authoritative-document rule and behavior (1)); spargen's README documents the
silent-miscompile hazard ("silently miscompiles any schema that uses 3.1
semantics"), and my probe shows progenitor's failure on real 3.1 input is a
confusing serde error, not a clean gate. (E) JVM sidecar (openapi-generator) —
rejected on fit: contributors/CI need Java (proven absent on this macOS host:
`/usr/bin/java` shim, "Unable to locate a Java Runtime"), 3.1 support is
incomplete (meta-issue #14943 open), and the `rust` generator's idiomaticity
could not be verified here (no run possible).

The recommended design preserves each principle: input = snapshot file;
typed async reqwest output (proven compiling); committed files;
`--check` drift gate (proven RC=0 clean); operationIds become method names
(`pets-list` → `pets_list`, proven), degrading to stable `method_path` names
(`get_pets_pet_id`) when curation is absent (proven) rather than hard-failing
like progenitor (`progenitor-impl-0.15.0/src/lib.rs:725-744` returns
`UnexpectedFormat("path {} is missing operation ID")`).

Maturity/dependability/performance/integration-cost summary: progenitor is the
most mature Rust-native pick (Oxide-backed, full CI matrix, 5.2M downloads)
but cannot parse the binding schema version — a disqualifying fitness failure,
not a tradeoff. openapi-to-rust is immature (pre-1.0, single vendor, 36 stars,
ubuntu-only CI) but is the ONLY surveyed Rust tool that is 3.1-native AND
standalone-recipe shaped; its maintenance velocity is high (0.15.0→0.17.0 in
17 days; 10/10 recent issues closed, ages 5–43d). Performance: openapi-to-rust
claims -26.5% median clean `cargo check` vs progenitor's macro workflow in one
version-specific benchmark (README; methodology in-repo) — cited as a lead,
not verified here; no absolute claim is made. Integration cost: one
`cargo install --locked` pin + a just recipe + generated-tree deps
(reqwest/rustls, reqwest-middleware, thiserror — all MIT/Apache, all
audit-clean here).

No `BASELINE-REVIEW:` finding: F335 stays `DIVERGENT` (mechanism differs by
ecosystem, pattern agrees); no ledger row or inherited mechanism is challenged.

### Dominant choice

`openapi-to-rust`, version range `0.17` (caret: `>=0.17.0, <0.18.0`), consumed
as a pinned recipe tool (`cargo install --locked openapi-to-rust
--version 0.17.0`), NOT as a Cargo dependency. It is the only surveyed
candidate that satisfies the binding constraint (parses OpenAPI 3.1 per R4.1)
in the required shape (standalone recipe against the snapshot file, committed
output, CI drift check). Proven on 2026-09-19: generates from a 3.1 fixture,
`--check` verifies clean output RC=0, generated crate `cargo check`s on stable
1.98 AND the 1.96.0 floor, both probe trees `cargo audit`-clean.

### Qualified shortlist

Up to five that passed every gate (three is a finding: the niche is thin).

- `openapi-to-rust` · 3.1-native standalone CLI generator · 90-day 41,934 ·
  all-time 42,528 · stars 36 · last release 0.17.0 (2026-09-14) · maintenance
  `active` (0.15.0→0.17.0 in 17 days; pushed 2026-09-14; 10/10 recent issues
  closed) · notable adopters: none yet (0 reverse deps — the risk) · trade-off:
  only recipe-shaped 3.1-native Rust tool, but pre-1.0 single-vendor with no
  third-party adoption.
- `progenitor` (+ `cargo-progenitor` static-crate mode) · established
  Rust-native generator, 3.0.x only · 90-day 1,321,770 · all-time 5,214,529 ·
  stars 1,007 · last release 0.15.0 (2026-09-10) · maintenance `active`
  (pushed 2026-09-19; 93 open issues; first-maintainer-response median 26 days
  over 6 measured, 2 of 10 unanswered, 2 latency-unknown on fetch timeout) ·
  adopters: ZeroTier (`zerotier-central-api`), Feldera (`feldera-rest-api`,
  github.com/feldera/feldera), Edgee (`edgee-api-client`,
  github.com/edgee-cloud/edgee) · trade-off: most mature and best-tested, but
  hard-errors on 3.1 input (`UnexpectedFormat("invalid version: 3.1.0")`,
  proven) so it cannot consume an R4.1-compliant snapshot.
- `openapi-generator` `rust` (reqwest) generator · multi-language JVM incumbent
  · crate figures `inapplicable` (not a crate; distributed as jar/docker/npm;
  reason recorded, not omitted) · stars 26,753 · last release v7.25.0
  (2026-08-24) · maintenance `active` (pushed 2026-09-17; 5,128 open issues) ·
  adopters: per-language adopter list not published (gap — none claimed) ·
  trade-off: industry standard with a STABLE reqwest generator, but needs a
  JVM in the contributor/CI toolchain and 3.1 support is incomplete (open
  meta-issue #14943); Rust output idiomaticity unverifiable here (no Java on
  probe host).

Fitness gates per shortlisted candidate (floor: rust 1.96; gate 1 for all:
`inapplicable — owner ruling 2026-09-12 (Q7.B)`; licenses recorded as fact:
openapi-to-rust MIT; progenitor family MPL-2.0; openapi-generator Apache-2.0;
generated trees all MIT OR Apache-2.0):

1. license: inapplicable (Q7.B) for all — values above.
2. MSRV: progenitor PASS (declares 1.88; CI tests 1.88 × {ubuntu, windows,
   macos}; probe tree also builds on 1.96.0). openapi-to-rust PASS (tool
   declares 1.88.0; tool-MSRV-untested-in-CI gap immaterial — the tool runs on
   dev/CI stable, never on the floor; generated tree PROVEN building on
   1.96.0 incl. `reqwest-middleware` 0.5.2 which declares no rust-version).
   openapi-generator: Rust-MSRV concept inapplicable (JVM tool; reason
   recorded); Java floor not verified here (gap).
3. advisories/unsafe: all PASS. OSV `POST api.osv.dev/v1/query` 2026-09-19: 0
   vulns for progenitor, progenitor-client, openapiv3, oas3, openapi-to-rust,
   spargen. rustsec.org direct fetch failed (timeouts; oas3 page HTTP 404) —
   recorded as gap, covered by OSV (ingests RustSec) plus executed `cargo
   audit` (1,251 advisories): progenitor probe tree (203 deps) RC=0 clean;
   openapi-to-rust generated tree (168 deps) RC=0 clean. `unsafe` blocks: 0 in
   progenitor-client-0.15.0, openapiv3-2.2.0, oas3-0.22.0, progenitor-0.15.0,
   progenitor-impl-0.15.0, cargo-progenitor-0.15.0, openapi-to-rust-0.17.0
   sources (pinned-source grep) and 0 in either generated output.
4. OS matrix: progenitor PASS (CI ubuntu+windows+macos). openapi-to-rust PASS
   on combined evidence: project CI is ubuntu-only (letter-of-gate gap
   disclosed), but the tool was compiled from source, executed, and its output
   compile-checked on macOS aarch64 in this session — the gate's intent (works
   on both) is directly evidenced. openapi-generator PASS with cost (JVM runs
   on both OSes; Java is NOT present by default on macOS — proven).
5. default features/async: progenitor generated: reqwest
   `default-features=false` (json/query/stream) + progenitor-client; async via
   reqwest/tokio. openapi-to-rust generated: reqwest `default-features=false`
   (query/rustls/stream) + reqwest-middleware + thiserror; async via
   reqwest/tokio. openapi-generator rust/reqwest: `supportAsync` default true,
   `reqwestDefaultFeatures` default `native-tls` (per generator docs).
6. size/compile cost (qualitative): ahead-of-time tools (openapi-to-rust,
   cargo-progenitor static, openapi-generator) add zero codegen to `cargo
   build`; cost is the generated deps (reqwest TLS stack dominates; rustls vs
   native-tls is the one size-relevant choice). progenitor macro/`Generator`
   modes add typify/syn/quote/proc-macro2 to the build graph on every build.
   Tool binaries on disk: cargo-progenitor 10M, openapi-to-rust 18M
   (release, local stammen — informational only).

### Excluded by gate

None. Every crate candidate passes (or is inapplicable-with-reason on) every
applicable gate; the 3.0-only candidates fail fitness-for-purpose under binding
R4.1, which is recorded under runner-up/tradeoffs rather than as a gate
exclusion, and the immature candidates sit in Up-and-comers on maturity, not
on a failed numbered gate.

### Up-and-comers

- `spargen` 0.4.0 · OpenAPI 3.1.x/3.2.x-only strict generator (rejects 3.0 with
  diagnostics) · 90-day 4,318 · all-time 4,318 · stars 4 · last release 0.4.0
  (2026-08-29) · maintenance `active` but self-labelled Alpha ("Status
  (Alpha)"; author: "Currently being adopted by a few projects by author") ·
  133 open issues, all recent ones filed by the single maintainer
  (justin13888) as a task tracker — bus factor 1 · adopters: none (1 reverse
  dep: its own macro) · why not now: alpha, unprobed here (not in offline
  cache; build.rs/macro-only integration fits worse than a recipe), CI
  ubuntu-only. Re-verify trigger: 1.0 or multi-adopter evidence. Runtime-dep
  hygiene is exemplary (exactly reqwest-no-defaults/serde/serde_json/bytes/
  secrecy + conditional stream support; reqwest injection supported) — the
  design to watch.

### Fit for this template

CLI: the generator is a dev-time recipe, not shipped code — no CLI surface
impact. The generated client could serve a future `--against-staging`
conformance probe, but nothing requires it; fit is neutral-good.

Library: the generated client is a new leaf module/crate (typed `Client` +
types) behind the existing feature discipline; it adds reqwest (+middleware)
to the tree — acceptable, audit-clean, floor-compatible. No wrapper layer
needed: output is directly usable async typed methods (MEDIUM question —
proven compiling and calling-shaped; only a mock round-trip remains planned).

Web: the recipe consumes R71's committed snapshot generically
(`docs/api/openapi.json` path by convention); no framework coupling (works
with any R69 stack serving a 3.1 schema). R4.1's "(parser, linter, generator)
verified against it" clause is satisfied by the executed 3.1 probes. Integrated
acceptance must rerun against R71's accepted schema (acceptance-after R71).

### Recommendation

Recommend `openapi-to-rust` version range `0.17` (pin `=0.17.0` in the recipe
via `cargo install --locked`; accept `0.17.x` patches), invoked as a `just`
recipe (`generate <snapshot>` writing committed files; `generate --check` as
the CI drift gate), regenerating from the R71-owned committed OpenAPI 3.1
snapshot. This is the only surveyed tool that meets the binding input (3.1)
in the mandated shape (standalone recipe, never hand-written). The
pre-1.0/single-vendor risk is contained by the pin + `--check` + the
re-verify triggers below — and by the fact that generated output is committed
source, so a future tool swap rewrites the recipe, not consumers' hand-written
code (consumers depend on generated module paths, which a swap preserves by
convention).

### Ranked runner-up

`progenitor` 0.15 — wins if and when Oxide ships OpenAPI 3.1 support (open
issues #762 and #1268, the latter filed 2025-12-29 with a utoipa-produced 3.1
spec failing exactly as my probe reproduces). On that event it is strictly
stronger: Oxide-maintained, full CI matrix, 72-adopter ecosystem, three
integration modes. Second conditional: `openapi-generator` wins only if the
template accepts a JVM in the contributor/CI toolchain AND its 3.1 gaps
(meta-issue #14943) close for the `rust` generator.

### Tradeoffs

What `openapi-to-rust` gives up vs `progenitor`: ~5M downloads of battle
testing, Oxide maintenance, full OS×MSRV CI matrix, pagination `Stream`s,
generated CLI + httpmock helpers, and positional/builder style choice —
accepted because progenitor cannot parse the binding 3.1 input at all (proven
hard error, two modes), and the 3.1→3.0 workaround breaks R4.2's
authoritative-document rule. Vs `openapi-generator`: cross-language uniformity
and 26k-star incumbency — accepted because of the JVM toolchain tax on every
contributor/CI runner plus its own incomplete 3.1. Vs `spargen`: stricter
3.1/3.2 diagnostics and a tighter runtime-dep contract — accepted because
spargen is alpha/bus-factor-1 with no recipe-shaped file emission story
proven here; it is the named re-verify alternative. Vs hand-rolled: full
control — accepted because owning a parser+emitter costs more than a tool pin
forever. Cross-cutting cost accepted: pinning a 36-star pre-1.0 tool —
mitigated by exact pin, committed output, `--check`, and triggers.

### Parameters

`assumes web-extra-surface` = the full R69 value from
`inputs/parameters.json` (one additive off-by-default `web` feature on
axum 0.8.9 / tokio 1.53.1; tower 0.5.3 dev-only; four gated things; heavier
opt-ins nest on top). The recipe consumes the snapshot R71 produces inside
that gated `src/web/` tree generically; no owned parameter exists for R84.

CONFLICT: none.

### Migration implications

File-level changes in the template (template tree does not exist yet; paths
are conventional, keyed to py's layout):

- `justfile` (or `Justfile`): new `client-rust` recipe — `cargo install
  --locked openapi-to-rust --version 0.17.0` (pinned; contributor/CI bootstrap
  step) then `openapi-to-rust generate docs/api/openapi.json` writing the
  committed client tree; mirrors py `Justfile:client-python`.
- Generated client tree (committed, e.g. `clients/rust/` or a workspace member
  `crates/api-client/`): `types.rs`, `client.rs`, `mod.rs` + a merged copy of
  the `REQUIRED_DEPS.toml` fragment (reqwest/rustls, reqwest-middleware,
  serde, thiserror) into the owning crate's `Cargo.toml`. Exact member layout
  is R02's; this item only requires the output be committed and path-stable.
- CI workflow: drift job running `openapi-to-rust generate --check
  docs/api/openapi.json` (RC=0 clean proven; non-zero on drift — semantics
  from maintainer docs, failure-path output not exercised here, see
  Validation). Alternatively regenerate-and-`git diff --exit-code`.
- `docs/api/openapi.json`: no change — consumed read-only (R71 owns it).
- No `build.rs`, proc-macro, or JVM is added to the template by this pick.

### Validation strategy

EXECUTED on 2026-09-19 (macOS aarch64, rustc 1.98.0; fixtures
`/tmp/r84probe/pet-30.json` 3.0.3 / `pet-31.json` 3.1.0 with `type:["string",
"null"]` + `$defs`, both with `pets-list/create/get` operationIds; tools
installed `--offline --locked` from the local cargo cache):

- `cargo install --locked cargo-progenitor --version 0.15.0` → installed OK.
  `cargo progenitor -i pet-30.json ...` → PANIC on stable:
  `main.rs:95: unwrap() on Err Unstable("wrap_comments,
  normalize_doc_attributes")` — static-crate mode requires nightly rustfmt
  (rustfmt-wrapper passes `--unstable-features`, rejected by stable rustfmt
  1.9.0 even under `RUSTC_BOOTSTRAP=1`); only `Cargo.toml` (+empty `src/`) is
  written. Finding: progenitor's recipe-shaped mode is broken on stable
  as of 0.15.0.
- progenitor `Generator` (via `progenitor-impl =0.15.0`, README `build.rs`
  pattern) on `pet-30.json` → 239-line `codegen.rs` with `Client` +
  `pets_list/create/get` + typed structs; compiled with
  progenitor-client/reqwest-0.13/serde (`cargo build --offline` exit 0) and
  on the floor (`rustup run 1.96.0 cargo check --offline` exit 0).
- Same probe on version-only-3.1 doc → `UnexpectedFormat("invalid version:
  3.1.0")`; on real 3.1 doc → serde `invalid type: sequence, expected a
  string` at the type array. Both hard failures, matching issue #1268.
- `cargo install --locked openapi-to-rust --version 0.17.0` → installed OK.
  `openapi-to-rust generate ../pet-31.json` → RC=0, 4 files (692 lines):
  async `pets_create/get/list`, typed structs incl. per-op errors,
  `REQUIRED_DEPS.toml` (reqwest 0.13 rustls, reqwest-middleware 0.5, serde,
  thiserror). Mounted as a crate lib: `cargo check --offline` exit 0 on
  1.98 AND on 1.96.0 (reqwest-middleware 0.5.2 vendored from static.crates.io
  via `[patch]` — the only dep missing from the offline cache).
- `openapi-to-rust generate --check ../pet-31.json` on clean output →
  `Verified 4 file(s)`, RC=0. Drift-failure output (edited snapshot) NOT
  exercised — planned.
- operationId-absent probe (ids stripped): generates `get_pets`,
  `post_pets`, `get_pets_pet_id` — stable fallback, no hard error.
- `cargo audit` (1,251 advisories): progenitor probe tree (203 deps) RC=0;
  openapi-to-rust generated tree (168 deps) RC=0. (Sandbox blocks the default
  advisory-db lock; reran with `CARGO_HOME=/tmp/r84probe/cargo-home`.)
- openapi-generator run: NOT executed — no Java on host (gap).

PLANNED (not run): AC4 mock round-trip (wiremock + generated client asserting
typed deserialization); `--check` failure-path output; integrated acceptance
regenerating from R71's accepted 3.1 schema (acceptance-after R71) with
`--check` in CI.

### Confidence & re-verify trigger

Confidence: high that 3.1-native-ness is mandatory (binding R4.1) and that
progenitor fails it (executed proof); high that openapi-to-rust 0.17.0 meets
the recipe mechanically (executed proof incl. floor build + audits); MODERATE
that openapi-to-rust is dependable long-term (pre-1.0, single vendor, zero
adopters, ubuntu-only CI) — the pin + committed output + `--check` contain
that risk, and the triggers below bound it in time.

Re-verify on the earliest of: (1) R71 publishes its accepted schema/version —
rerun integrated acceptance against it; (2) `openapi-to-rust` 0.18 or 1.0
(mind the 0.x churn: 3 minors in 17 days); (3) progenitor closes #762/#1268
(3.1 support) — re-crown the runner-up; (4) `spargen` 1.0 or second-adopter
evidence; (5) 2027-03-19 (6 months) if none fire — recheck maintenance state
of a pre-1.0 pick.

### Sources

All retrieved 2026-09-19. crates.io figures via
`GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `.../versions` (newest non-yanked `num`,
`created_at`, `rust_version`, `license`) with UA
`rs-launch-blueprint-research (R84 raw report)` (crates.io returns HTTP 403
without a User-Agent — recorded pitfall); GitHub via
`GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`,
`pushed_at`) and `GET .../search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`); reverse deps via
`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies`
(`meta.total`, `versions[].crate`).

- progenitor family: crates.io `progenitor` (0.15.0, 2026-09-10, MPL-2.0,
  rust 1.88; 1,321,770 / 5,214,529), `progenitor-client` (1,609,599 /
  6,165,420), `progenitor-impl`, `progenitor-macro`, `cargo-progenitor`
  (2,534 / 17,142); github oxidecomputer/progenitor (1,007 stars, pushed
  2026-09-19T11:12:40Z, 93 open issues); README (3.0.x scope, three modes);
  `progenitor-impl-0.15.0/src/lib.rs:725-744` (missing/duplicate operationId
  hard error), `src/method.rs:294` (unwrap); `.github/workflows/rust.yml`
  (os × rust-version 1.88/stable matrix); issues #1268 (3.1 support, open,
  2025-12-29), #762 (3.1, open); 10 recent issues +
  first-comment latencies (median 26d, 2 unanswered).
- openapi-to-rust: crates.io (0.17.0, 2026-09-14, MIT, rust 1.88.0; 41,934 /
  42,528; 0 reverse deps); github gpu-cli/openapi-to-rust (36 stars, pushed
  2026-09-14, 3 open issues; 10 recent all closed); README (3.0/3.1/exp-3.2,
  CLI + `--check`, 56-spec corpus, progenitor comparison + benchmark);
  `.github/workflows/ci.yml` (12 jobs, all ubuntu-latest, stable only).
- spargen: crates.io (0.4.0, 2026-08-29, MIT OR Apache-2.0, rust 1.88; 4,318
  / 4,318; 1 reverse dep); github getkono/spargen, branch `master` (4 stars,
  pushed 2026-09-16, 133 open issues — author-filed tracker, sampled #231–240
  all justin13888 2026-09-16); README (3.1/3.2-only, Alpha label, `build.rs`/
  macro modes, runtime-dep contract); `.github/workflows/ci.yml`
  (ubuntu-only).
- openapi-generator: github OpenAPITools/openapi-generator (26,753 stars,
  pushed 2026-09-17, 5,128 open issues; latest release v7.25.0, 2026-08-24);
  `https://openapi-generator.tech/docs/generators/rust` (`rust` STABLE,
  CLIENT, reqwest default, `supportAsync` default true); meta-issue #14943
  (OpenAPI 3.1 Support, open) + #18911 (prefixItems, open).
- Parsers/context: crates.io `openapiv3` (2.2.0, 2025-06-02, MIT/Apache-2.0,
  rust None; 2,983,715 / 13,006,467; 183 reverse deps), `oas3` (0.22.0,
  2026-05-06, MIT, rust 1.87; 806,767 / 2,022,260; 36 reverse deps),
  `reqwest` (0.13.5, 2026-09-08, MIT OR Apache-2.0, rust 1.85.0),
  `reqwest-middleware` (0.5.2, 2026-05-19, MIT OR Apache-2.0, rust None),
  `openapi-codegen` (0.1.0, 52 / 2,850, no repo), `openapi-nexus` (0.2.3, 609
  / 1,107); github glademiller/openapiv3 (205 stars, pushed 2025-06-02),
  x52dev/oas3-rs (79 stars, pushed 2026-09-09); utoipa 5.4.0
  `src/openapi.rs` via docs.rs (`OpenApiVersion::Version31 #[default]`,
  serializes `3.1.0`); adopters via crates.io (`feldera-rest-api` →
  github.com/feldera/feldera; `edgee-api-client` →
  github.com/edgee-cloud/edgee; `zerotier-central-api`, repo None).
- Standards/inputs: smorinlabs/rest-standards @ `0850d43e`
  (`rest-api-standard.md:742-747` R4.1, `:754-755` R4.2, `:2681` R4.2 index —
  via `git show`, no checkout); rust stable 1.98.1
  (`static.rust-lang.org/dist/channel-rust-stable.toml`); owner ruling Q7.B
  (`docs/planning/p02/owner-decisions.md:157-159`); R69 DECISION (web stack);
  py evidence (`Justfile:321-323`, `web/app.py:77-80,119`); F335
  (`docs/port/COMMONALITY.md:339`); OSV `POST api.osv.dev/v1/query` (0 vulns
  × 6 crates; rustsec.org direct fetch timed out — gap).
- Probes (all `/tmp/r84probe`, macOS aarch64): fixtures `pet-30.json`,
  `pet-31.json`, `pet-31ver.json`, `pet-31-noids.json`; install logs,
  `codegen.rs` (239 lines), `src/generated/*` (692 lines),
  `REQUIRED_DEPS.toml`, `audit-*.log`, floor `cargo check` logs — scratch,
  retained under `/tmp` per instructions, not committed.
