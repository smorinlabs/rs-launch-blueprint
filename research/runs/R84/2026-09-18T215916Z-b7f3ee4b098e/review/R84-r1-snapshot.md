# 2026-09-25 — R84 — openapi-typed-client-generation (crate, Deep) — decision (revision 1)

**Revision 1 — first write.** Actor `synth-opus-2026-09-18T215916Z-b7f3ee4b098e`, model
`claude-opus-5-5` (Claude Opus family), item kind `crate`, effort tier `deep`, engines
`muse, opus, doxa` under the `engine_overrides` pilot (Muse substitutes for Codex). This
synthesizer produced none of the three raw reports. Nothing has been published for R84, so
there is no `## Supersedes`.

**What this revision rests on.** Three collected, hash-pinned engine reports, each read in
full; the binding prompt `inputs/prompt.md`; four executed checks under `review/evidence/`,
each a rerunnable script with its committed log; and the binding inputs below. Every
load-bearing claim a raw report makes was re-derived at its source; where re-derivation was
impossible, the claim is carried under its engine's name and listed under `## Engines` as not
re-derived.

| Report | Engine, model | sha256 | Written |
|---|---|---|---|
| `raw/muse-caecee02….md` | Muse, `muse-spark` (Meta) | `caecee029378d7df9f8096e3552847ea9f5bcb1933dbbde2fb1623ed31aae48e` | 2026-09-19 |
| `raw/opus-76781e70….md` | Opus, `claude-opus-5` | `76781e70f079a8aa1eda39d3de00832798af732d0aeddef436e51afed7e4ba2f` | 2026-09-18 |
| `raw/doxa-9f01d68b….md` | Doxa 3.3.0 `all_deep_research`, operation `research-20260918-152036-285cea386b6f444c`: OpenAI `gpt-5.6-sol`, Perplexity `sonar-deep-research`, Gemini `deep-research-preview-04-2026` | `9f01d68be5eca4d7a74e1f58386435c15499be410e18fe1137a8bbb279f7d7e3` | 2026-09-18 |

**Retrieval dates.** **2026-09-25 (UTC)** for everything this decision checked itself; each
raw report's own date (table above) for anything carried from it.

**Binding inputs.**

- **The org REST API Design Standard v2.0.0 binds this template's HTTP surface** (owner
  ruling W2-REST, `docs/port/OWNER-REVIEW.md`, "2026-09-18 — the REST API Design Standard
  binds the HTTP surface (W2-REST)"; commit `0850d43e45d919ef5e37f7174c4212b46013c49f`,
  blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, verified by check `C01`). The ruling
  names R84: "Every web item (… and the later R71 R83 R84) designs to the standard, quotes
  the rules it relies on at their lines, and records any departure as an `OVERRIDE (OV-nn)`".
  Two parts of the standard decide this item. **R4.1** (`rest-api-standard.md:742-747`)
  makes OpenAPI **3.1** the contract version, and names the **generator** as part of the
  toolchain that must be verified against the document. **Section 12, "Client obligations"**
  (`:1767-1823`) binds every consumer of a conforming API, which is what a generated client
  is.
- **Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
  candidate (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check for anything the
  template uses"). Licence strings appear below as recorded facts only; nothing is admitted,
  ranked or excluded on one.
- **The owner reference architecture** (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`)
  is a research input, not a pre-decision (`docs/planning/p02/owner-decisions.md`
  section 11). Its three rows that touch R84 are dispositioned under
  `### Principles and implementation`.
- **R69 revision 10** is owner-accepted and unpublished. It moves the web tree from
  `src/web/` into an optional workspace member `crates/web/`. It is a design input noted in
  prose beside the `web-extra-surface` line in `## Parameters`. The `- assumes` line itself
  carries the live registry value, which is still revision 9's form.

**A prior draft was not used.** An earlier synthesis attempt for this run died on the
2026-09-18 session limit and left an untracked `review/evidence/` directory with no
`DECISION.md` (ledger entry "RATE-LIMIT STOP, 2026-09-18"). It used the override number
`OV-12`, R84's reservation in the 2026-09-18 table; the 2026-09-21 allocation gave R84
`OV-11` instead (check `A13`).
This revision moved that directory, unchanged, to
`/tmp/r84-prior-evidence-backup-2026-09-25/` before writing, and cites none of its logs.
Every check below was written and run by this synthesizer.

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). P02 is research only; P03 builds the template, and P03's CI is what proves the
recommendation. The generated clients built here were throwaway probes under `$TMPDIR`,
deleted by each script's `EXIT` trap. No template file was written into the repository.

### The recommended mechanism

**Yes — a Rust-ecosystem equivalent of `openapi-python-client` exists. It is
`openapi-to-rust`, version range `>= 0.17.0, < 0.18.0`, pinned exactly to `0.17.0`.** It is
used as a **developer tool invoked by one `just` recipe against the committed snapshot**. It
is never a Cargo dependency of any template crate.

| Piece | Exact form | What it supplies |
|---|---|---|
| The tool | `openapi-to-rust@0.17.0` as one row in R42's declared tool table, installed by R42's generic `install-tool` recipe (`cargo binstall --locked --no-confirm <name>@<version>`, check `A06`) and invoked as the bare executable `openapi-to-rust` on `PATH` | A crates.io-published generator, which is the channel R42's standing rule prefers ("prefer a crates.io-published tool; a release-only tool must justify itself", check `A07`). Presence test: `command -v openapi-to-rust`, per `package-manager-invocation` |
| The generator input | A committed `openapi-to-rust.toml` at the repository root (text below) | `spec_path` names R71's committed snapshot; `[extensible_enums]` lists every enum the contract documents as open; tracing middleware is switched off |
| The recipe | `just client-rust`, in `[group('build')]` (text below) | Deletes and regenerates `clients/rust/`, then writes that directory's `Cargo.toml` from a fixed six-key package header plus the generator's own `REQUIRED_DEPS.toml` dependency table |
| The output | `clients/rust/` — generated, **not committed** (`/clients/` added to `.gitignore`), **outside the workspace** (an empty `[workspace]` table in its manifest) | A standalone async Rust package: `HttpClient`, one `pub async fn` per operation, typed request and response structs, a typed error enum per operation |

The recipe, as executed by check `T08` (`review/evidence/r84-openapi-to-rust-probe.sh`):

```just
# Generate a typed Rust client from the OpenAPI snapshot (F335) — never hand-write one
[group('build')]
client-rust:
    rm -rf clients/rust
    openapi-to-rust generate --config openapi-to-rust.toml --quiet
    printf '%s\n' '[package]' 'name = "rs-launch-blueprint-client"' 'version = "0.0.0"' 'edition = "2024"' 'rust-version = "1.96"' 'license = "MIT OR Apache-2.0"' 'publish = false' '' '[lib]' 'path = "src/mod.rs"' '' '[workspace]' '' > clients/rust/Cargo.toml
    sed -n '/^\[dependencies\]/,$p' clients/rust/src/REQUIRED_DEPS.toml >> clients/rust/Cargo.toml
    echo "client written to clients/rust"
```

The generator input, as executed by the same check:

```toml
# Generator input for `just client-rust` (F335). The snapshot is R71's; the
# output directory is never committed.
[generator]
spec_path = "docs/api/openapi.json"
output_dir = "clients/rust/src"
module_name = "api"

[features]
enable_async_client = true

# Outbound-request tracing is R58's and R78's concern, not this recipe's:
# switched off so the generated tree carries no reqwest-tracing.
[http_client.tracing]
enabled = false

# REST API Design Standard R12.4 / R4.9: every enum the contract documents as
# open is listed here, so an unknown value becomes `Custom(String)`.
[extensible_enums]
ProjectState = true
```

`ProjectState` is the probe fixture's enum. In the template, this table lists R71's
open enums by schema name. `docs/api/openapi.json` is py's snapshot path, used as the
default until R71 names its own.

**Why the manifest is written by the recipe.** `openapi-to-rust` emits a **module tree**
(`mod.rs`, `client.rs`, `types.rs`) plus a `REQUIRED_DEPS.toml` fragment, and no
`Cargo.toml` (check `T04`). Opus named this as the pick's main cost: a consumer must supply a
manifest, which risks a hand-written file in a "never hand-written" item. The recipe closes
that gap mechanically. The six package keys are fixed text that does not vary with the API.
The dependency table is copied from the generator's own output. `[lib] path = "src/mod.rs"`
mounts the generated module as the crate root, so no `lib.rs` is written. Every `.rs` file in
the output carries the generator's own header (check `T10`). The manifest also declares
what the OpenAPI Generator alternative cannot: `edition = "2024"` and a `rust-version`
(checks `T09`, `E01`).

**Ledger row this settles.** **F335** (`docs/port/COMMONALITY.md:339`, `py-only`,
`DIVERGENT`, item R84, check `A05`): "typed client generation from the committed snapshot,
never hand-written". The answer is that the Rust equivalent is `openapi-to-rust` behind a
`just client-rust` recipe. The principle agrees with py; the mechanism differs.

**The prompt's six questions, answered.**

| Question | Answer | Evidence |
|---|---|---|
| HIGH — which Rust tools generate a typed client from OpenAPI 3.x? | Bin 2 (established): OpenAPI Generator's `rust` generator (Java) and `progenitor` (Oxide). Bin 3 (young): `openapi-to-rust`, `spargen`, `ploidy`, `openapi-nexus`, `oas3-gen`. Hand-rolled codegen over `openapiv3`/`oas3` is an architecture, not a tool. No `utoipa`-adjacent client generator exists. | `### Principles and implementation`, landscape |
| HIGH — standalone recipe, or `build.rs`/proc-macro? | **Standalone recipe.** R49's live `build-tool-output-shape` value says "no build.rs and no build-orchestration crate" (check `A08`). A proc-macro compiles `reqwest` and `tokio` into whichever member expands it. | Checks `T08`, `T13`–`T15` |
| HIGH — principles and agreement levels across py, ts, rs | Agreement at the **policy** level: generated from the committed contract, never hand-written, one named recipe. The tool, language and output shape vary by ecosystem. | `### Principles and implementation` |
| MEDIUM — idiomatic enough to use directly? | **Yes, with one caller-side duty.** Async `reqwest` methods with typed bodies and typed per-operation errors need no wrapper. The generated client sets **no request timeout** and offers no way to inject one, so a caller wraps each call in `tokio::time::timeout` to meet R12.3. | Checks `T06`, `T07`, `R01`, `R02` |
| MEDIUM — does it depend on operationId curation (F312)? | **Yes, and it degrades rather than fails.** Curated ids become method names (`projects-list_projects` → `projects_list_projects`). Without ids, names are method-plus-path (`get_v1_projects_project_id`), which change whenever a path changes. | Checks `T06`, `T20`, `T21` |
| LOW — maturity and adoption | **Thin, and this is the pick's main risk.** 37 stars, 0 reverse dependencies, one located adopter with 20 downloads, and 33 releases in seven months. None of its 10 most recent issues carries a maintainer comment. Contained by the exact pin, uncommitted output and the re-verify triggers. | `snapshots/registry-figures.json` |

**`OVERRIDE (OV-11)` — REST API Design Standard R12.6 (SHOULD): the generated client never
sends `Accept: application/problem+json`.**

Deviation note, in the shape of the standard's section 1.9 template:
`- R12.6 · SHOULD · the generated client sends only Accept: application/json and drops any caller-supplied Accept header · openapi-to-rust 0.17.0 derives Accept from the success media type and exposes no override · owner (pending) · 2026-09-25`.

**Argument:** R12.6 (`rest-api-standard.md:1815-1817`, check `C08`) says "Clients SHOULD send
`Accept: application/problem+json` explicitly when they want problem documents". The
generated client wants them: it types the fixture's 404 as `Problem`. But
`src/client_generator.rs:1436-1447` in `openapi-to-rust` 0.17.0 sets `Accept` to the
operation's success media type and skips any custom header named `accept` (check `D14`).
The recipe's own output does the same in each of its 3 operations (check `R12`). No
configuration key changes it, and editing generated code is what this item forbids. The
hazard R12.6 guards against is a library that treats a problem document as a non-JSON
body. That hazard does not bite this client. It branches on the status code first and parses
the body as `Problem` whatever the media type (check `R11`), which is exactly what R12.7
requires. The deviation is recorded rather than silent, as R1.7 requires of a SHOULD
(`:272-273`, check `C11`).

**Options:**

- **(a) Accept the SHOULD deviation and record it in the template's conformance note.**
  *Recommended.* It costs nothing at runtime against a server that honours R5.12's
  problem-document obligation. The only failure mode is a server that negotiates strictly
  and answers an error with `406`. The client still surfaces that as an `ApiError` with
  status and body intact (R12.7 behaviour, check `R11`).
- **(b) Post-process `client.rs` in the recipe with `sed`** to rewrite the `Accept` value to
  `application/json, application/problem+json`. This conforms to the letter. It turns a
  generator's output into a patched artifact, which the "never hand-written" principle is
  meant to prevent, and the patch breaks silently when the generator's template changes.
- **(c) Ask upstream** for an `Accept` that includes `application/problem+json` whenever an
  operation declares a problem response, and drop this override when a release ships it.
  This is a re-verify trigger below, not a dependency of the decision.
- **(d) Take the runner-up instead.** OpenAPI Generator's `reqwest` template sets no `Accept`
  header, and its `Configuration.client` is public (check `E08`). A caller could therefore
  satisfy R12.6 with default headers. The price is R12.4 (MUST), which that generator cannot
  meet at all (checks `E04`, `E05`). A MUST departure is worse than a SHOULD departure.

**Section 12 of the standard against the recommended output, rule by rule.**

| Rule | Strength | Disposition | Evidence |
|---|---|---|---|
| R12.1 retry only documented-retryable failures; R12.2 honour `Retry-After` | MUST | **Conforms.** The recipe's client installs no retry middleware and never retries on its own. The recipe must not set `[http_client.retry]`: that installs a middleware which retries 429/500/502/503/504 regardless of method, which would break R12.1's idempotency-key clause. | `R13` |
| R12.3 explicit request timeouts; never disable TLS verification | MUST | **Conforms only through the caller.** The generated client uses `reqwest::Client::new()` with no timeout. The `[http_client] timeout_seconds` key is accepted, validated and then ignored: output for 30 s and for 1 s is byte-identical. The template's usage example therefore wraps every call in `tokio::time::timeout`. TLS verification is never disabled (`reqwest` with `rustls`). No upstream issue reports the inert key (`G07`). | `R01`, `R02`, `D13`, `G07`; runtime half `R10` not run on this host |
| R12.4 tolerate unknown fields and unknown enum values | MUST | **Conforms, by configuration.** Unknown fields are ignored. A plain `enum` schema renders closed and rejects `suspended`. The recipe's `[extensible_enums]` entry, or an `anyOf: [enum, open string]` schema, renders `Custom(String)` and keeps the value. R4.9 exempts enums the contract documents as closed. | `R03`, `R04`, `R05`, `D11`, `D12` |
| R12.5 cursors are opaque | MUST | **Conforms.** `cursor` is an optional string query parameter the client passes through unchanged; the client neither builds nor parses it. | generated `projects_list_projects` signature (fixture) |
| R12.6 send `Accept: application/problem+json` | SHOULD | **Departs — `OVERRIDE (OV-11)`** | `R12`, `D14` |
| R12.7 branch on status first; never rely on every error being a problem document | MUST | **Conforms.** The `Problem` parse sits inside the `404u16` arm of a `match` on the status code; an unparseable body keeps its status and raw bytes with `typed: None`. | `R11`; runtime `R07`, `R08` not run on this host |
| R12.8–R12.10 webhooks, streams | — | Not reached: the fixture and py's contract have no webhook or streaming operation. | — |

**What R71 must supply.** These are requirements on R71 (`openapi-generation-pipeline`), not
decisions made for it.

| # | Requirement on R71's snapshot | Consequence if unmet | Evidence |
|---|---|---|---|
| N1 | OpenAPI **3.1** (R4.1) | None for this pick, which reads 3.1 (and 3.0). It is why progenitor is excluded | `T03`, `P02` |
| N2 | An `operationId` on **every** operation, curated as py's `tag-function` (F312) | Method names fall back to method-plus-path and change when a path changes | `T20`, `T21` |
| N3 | Every enum documented as **open** or **closed** (R4.9); open ones listed in `[extensible_enums]` or written as `anyOf` with an open string | A plain `enum` renders closed, and the client then breaks R12.4 on the first new value | `R04`, `R05` |
| N4 | A stable committed path (py: `docs/api/openapi.json`) | One line of `openapi-to-rust.toml` changes | `B02` |

**What this decision does not decide.** Which crate generates the schema, and whether its
enums are open (R71, F307/F312/F332/F333). Contract fuzzing (R83, F334). Whether and how the
web service exists (R69). Any TypeScript client: the owner reference's `openapi-typescript`
row belongs to the unscoped SPA head (`owner-decisions.md` section 11). Outbound-request
tracing (R58, R78).

**Couplings, stated rather than re-decided.**

1. **R42 (`package-manager-invocation`, published).** The tool is one row in R42's tool table;
   the recipe invokes it bare on `PATH` with no runner prefix. The recipe's `rm`, `printf`,
   `sed` and `echo` are shell built-ins or POSIX utilities, not provisioners.
2. **R49 (`build-tool-output-shape`, published).** No `build.rs` is added. The generated
   package is not the root package, so R49's `[lib]`/`[[bin]]`/`include` clauses do not reach
   it; `/clients/` is outside R49's `include` allow-list, so it can never enter the `.crate`.
3. **R02 (accepted, unpublished).** A fifth workspace member is admitted only for "a second
   bounded context, a second production adapter or a second installable binary" (check
   `A09`). A client of the template's own served API is none of these. The empty
   `[workspace]` table keeps it out of the workspace without touching the root manifest (check
   `T13`).
4. **R05 (accepted, unpublished).** R05's criterion 1 keeps `tokio` out of the default build
   (check `A10`). The generated client pulls in `tokio` through `reqwest` (check `T14`), which
   is why it stays outside the workspace; the template root's tree has no `tokio` after the
   recipe runs (check `T15`). The client is async while R05's CLI is synchronous. They never
   meet: the CLI reaches the upstream API, and the generated client reaches the template's own
   service.
5. **R11 (`ci-workflow-job-structure`).** **No CI job is requested.** py runs its recipe in no
   workflow (check `B06`).
6. **R83.** It consumes the same snapshot, so it shares N1, N2 and N4. Nothing here constrains
   its tool.

**Re-verification triggers**, each checkable without judgment:

1. R71 publishes: rerun `just client-rust` against the real snapshot and confirm N1–N4.
   If R71 opts into OpenAPI 3.2 (utoipa 6.0.0, published 2026-09-22, adds an opt-in
   `Version32`, check `D17`), R4.1 requires the generator to be verified against 3.2
   first; `openapi-to-rust` calls its 3.2 support experimental (Muse).
2. R69 republishes `web-extra-surface` at revision 10: re-read the `- assumes` line.
3. `GET https://crates.io/api/v1/crates/openapi-to-rust/versions` shows a newest non-yanked
   `num` of `0.18.0` or later. Rerun `r84-openapi-to-rust-probe.sh` with `TOOL_VERSION` moved;
   the tool's pre-1.0 minors may change generated APIs.
4. An `openapi-to-rust` release makes `timeout_seconds` reach generated code (check `R01`
   turns FAIL), or sends `application/problem+json` in `Accept` (check `R12` turns FAIL). The
   first simplifies R12.3; the second retires `OV-11`.
5. `progenitor` releases a `progenitor-impl` whose `validate_openapi_spec_version` accepts
   `3.1.` (check `D02` turns FAIL), or closes issue #762 or #1268. That reopens the
   Rust-native incumbent.
6. The owner scopes an **in-repo Rust consumer** of the generated client. Then commit the
   output and request a CI job from R11 that runs `openapi-to-rust generate --check`
   (checks `T17`–`T19` show it detects drift).
7. A RustSec advisory is published against `openapi-to-rust`, `reqwest` or
   `reqwest-middleware` (checks `RS02`, `RS05`, `RS06` turn FAIL).
8. `openapi-to-rust` goes 6 months without a release (after 2027-03-14) and shows a concrete
   maintenance-risk signal.

re-verify: **2027-03-25**, or earlier on any of the eight triggers listed immediately above — R71's publication; R69's revision-10 republication; `openapi-to-rust` 0.18.0 or later; an `openapi-to-rust` release that makes `timeout_seconds` effective or sends `application/problem+json`; a `progenitor-impl` release accepting OpenAPI 3.1; the owner scoping an in-repo Rust consumer; a RustSec advisory against `openapi-to-rust`, `reqwest` or `reqwest-middleware`; six release-free months for `openapi-to-rust` with a concrete risk signal

### Principles and implementation

**The shared requirement, its source, and its agreement level.** py states it twice at the
programme pin `b08bccfb`: `docs/design/0002-web-api-conventions.md:86`, "WEB-60 — typed
clients are generated, never hand-written: `just client-python` (openapi-python-client) from
the committed snapshot", and `EXAMPLEWEB.md:138`, "Generate a typed client with
`just client-python` — never hand-write one" (both listed by check `B06`). ts has no web
service and so no entry (F303). The owner's 2026-09-04 direction asks that py's pattern be
carried to ts and rs as principles, not as tools.

| Level | Clause | Must agree across py / ts / rs? |
|---|---|---|
| Policy | A typed client is generated from the committed OpenAPI document, never hand-written, and never hand-edited | **Yes** |
| Policy | The committed snapshot is the contract. The generated client is a derived artifact | **Yes** |
| Capability | One named recipe regenerates the client with one command | **Yes** |
| Capability | Curated operationIds make method names stable and readable | **Yes** — R71 owns the curation (F312) |
| Mechanism | The tool, its language, crate versus module output, sync versus async, committed or not | **No** — each ecosystem chooses natively |

**Observable acceptance criteria.** Each criterion names the check that executed it or says
that it is planned.

| # | Criterion | Status |
|---|---|---|
| AC1 | `just client-rust` exits 0 and writes a compilable package | **Executed**: `T08`, `T11` (stable 1.98.1), `T12` (floor 1.96.0) |
| AC2 | Curated operationIds become the method names | **Executed**: `T06` |
| AC3 | No hand-written Rust file exists in the output | **Executed**: `T10` |
| AC4 | Regeneration is deterministic | **Executed**: `T16` |
| AC5 | The template root gains no member and no `tokio` | **Executed**: `T13`, `T15` |
| AC6 | Drift between the snapshot and the output is detectable in one command | **Executed**: `T17`–`T19` |
| AC7 | Unknown fields and documented-open enum values are tolerated (R12.4) | **Executed**: `R03`–`R05` |
| AC8 | Over HTTP: a typed 200, a typed problem 404, a non-problem 404 kept by status, and a caller deadline that elapses | **Written, not run on this host** (`R06`–`R10`); this shell refuses even a loopback TCP bind. Planned for P03 and for the empirical auditor |
| AC9 | The same on `ubuntu-latest` | **Planned** (P03); this synthesis ran on one macOS host |
| AC10 | R71's real snapshot satisfies N1–N4 | **Planned**, after R71 publishes (`acceptance-after: R71`) |

**Cross-repository reading.** **py** realizes the policy with `openapi-python-client` behind
`just client-python`. At the pin, its output is **not committed** (0 paths under `clients/`,
check `B04`), **not ignored** (check `B05`) and **run by no CI job** (5 mentions, none under
`.github/`, check `B06`). py's snapshot is OpenAPI 3.1.0 with curated ids (checks `B07`,
`B08`). **ts** has no web service. That is a justified absence, not drift: a ts service would
need its own generator decision, and this item's rationale transfers to it. **rs** realizes
the policy with `openapi-to-rust` behind `just client-rust`, in py's on-demand, uncommitted
shape. No shared low-level tool is recommended. py's tool emits only Python, and the one
cross-language candidate fails R12.4 in Rust (below).

**`BASELINE-REVIEW:` — none emitted by this decision; two engines' findings are forwarded.**
Doxa's OpenAI and Gemini legs each emit `BASELINE-REVIEW: F335`, proposing to relabel F335
as harmonized at the policy level. This decision states that policy-level agreement in the
table above. F335's `DIVERGENT` verdict describes the mechanism and remains accurate. The
controller adjudicates the two engine findings (RUNBOOK §4); this decision changes no ledger
row.

**The landscape — three bins, from the prompt's survey method.** Category: ahead-of-time
generation of a typed Rust HTTP client from an OpenAPI 3.x document.

| Bin | Members | Authority for the placement |
|---|---|---|
| Built-in / first-party | **Empty.** Cargo has no OpenAPI subcommand, and the Rust Project publishes none. The Cargo Book does give first-party guidance on the *shape*: a checked-in generated file "shouldn't be generated from build.rs", and CI should compare it with a fresh generation (check `CB01`) | The Cargo Book, doc.rust-lang.org |
| Established standard | **OpenAPI Generator 7.25.0**, `rust` generator (Java, cross-language). **progenitor 0.15.0** (Oxide Computer, Rust-native) | Maintainers' sources at the release tag (checks `E01`–`E08`, `D01`–`D06`); registry and GitHub figures below |
| Up-and-comer | **`openapi-to-rust` 0.17.0**, `spargen` 0.4.0, `ploidy`, `openapi-nexus`, `oas3-gen` | crates.io records (checks `F01`, `F02`) |

Out of category: `paperclip` (spec hosting for actix-web; no `rust_version`, check `F04`),
`openapi-model-generator` (models only, no client; no `rust_version`, check `F04`),
`openapi-generator-cli` the crate (a wrapper that downloads the Java jar), `openapiv3` and
`oas3` (parsers), `openapi-gen` and `toac-build` (compile-time only), `openapi-rs` (an
unrelated vendor SDK).

**Architectural alternatives, compared before tools.**

| # | Architecture | Verdict | Ground |
|---|---|---|---|
| A | **On-demand recipe → uncommitted package outside the workspace** | **Chosen** | py's exact shape (checks `B01`–`B06`). It keeps `reqwest`/`tokio` out of every workspace member (`T14`, `T15`), needs no `build.rs` (R49), and asks R11 for no job |
| B | Committed output, CI drift gate (`--check` or `git diff --exit-code`) | Rejected **for now**; flip condition stated | Muse, Doxa's OpenAI and Gemini legs, and the owner reference (line 90, check `A11`) prefer it. It guards an artifact **no build in this template consumes**: the CLI reaches the upstream API, not this service. It adds a CI job py does not have. It becomes right the moment an in-repo Rust consumer exists (trigger 6). The tool's `--check` makes the move one job (`T17`–`T19`) |
| C | `build.rs` or proc-macro (`progenitor::generate_api!`) | Rejected | R49's live value forbids `build.rs` (`A08`). A macro compiles the client and `tokio` into the consuming member (R05 criterion 1, `A10`) |
| D | Hand-rolled codegen over `openapiv3` / `oas3` | Rejected | The template would own a parser and an emitter to save one tool pin |
| E | Export types only (`ts-rs`/`specta`, owner reference line 90) | Rejected | F335 asks for a client, and the request plumbing would still be hand-written |
| F | Downconvert 3.1 → 3.0 and feed progenitor | Rejected | It generates from a derived document, not the committed contract (R4.2, `:754-755`) |

**Fitness gates, per candidate, before popularity.** Floor for gate 2: **1.96** (stable
1.98.1 minus two minors; `rust-lang/rust` latest release `1.98.1`, published 2026-09-03, check `G08`).

| Candidate | G1 licence | G2 MSRV | G3 advisory / `unsafe` | G4 ubuntu + macOS | G5 defaults / async | G6 size / compile cost |
|---|---|---|---|---|---|---|
| **openapi-to-rust 0.17.0** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; declares `MIT` | **Pass.** Declares `rust-version = "1.88.0"`, edition 2024 (`D10`, `F01`). Upstream CI runs an MSRV job on 1.88.0 (`G10`). The generated package compiles on 1.96.0 (`T12`) | **Pass.** No RustSec page (`RS02`, against the `atty` control `RS01`). `cargo audit` over the generated lockfile is clean (`AU01`). Tool sources: 2 string literals, no `unsafe` block (`D15`). Generated code: 0 `unsafe` (`T22`) | **Pass on evidence, gap on the letter.** Upstream CI is `ubuntu-latest` only (`G09`). Executed here on macOS arm64 (`T08`–`T12`). Linux not executed here (AC9) | Tool default feature `cli` (`D10`). Output is async `reqwest` 0.13 with `default-features = false`, `rustls`; `tokio` via `reqwest` (`T05`, `T14`) | Tool: a dev-only binary (about 75 s for a first from-source `cargo install --locked` on this host; cached afterwards). Output: clean `cargo check` 17–18 s in the committed `snapshots/openapi-to-rust-timings.txt` (22 s on an earlier run). Zero cost to the template's own build |
| **OpenAPI Generator 7.25.0 `rust`** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; Apache-2.0 | **Pass for its output** (Opus built it at 1.96.0, not re-run here). Its manifest hard-codes `edition = "2021"` with no `rust-version` (`E01`) | No `time` crate in the template (`E03`, refuting Gemini's exclusion). Java tool | Portable jar. **Not executed here**: Maven Central was unreachable (`M01`) | `supportAsync` defaults to `true`; `reqwest` `native-tls` by default (`rust.md`) | A JVM plus a roughly 30 MB jar (Opus) |
| **progenitor 0.15.0** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; MPL-2.0 | Pass: 1.88 (`F01`) | No RustSec page (`RS03`, `RS04`) | Fails the prompt's "Stable Rust only" in CLI mode (`P03`) | Async `reqwest` + `progenitor-client` | Macro and `build.rs` modes add codegen to every build |

**Maintenance state by rubric.** `openapi-to-rust`: **active** — 33 live versions
between 2026-02-13 and 2026-09-14 (`F02`), pushed 2026-09-25; of its 10 most recently opened issues, 6 closed after a median 0.49 days and 4, filed by one user on 2026-09-19, are open six days later; none of the 10 carries a comment from an owner, member or collaborator, so issues are closed by commit rather than by conversation (`G06`, snapshot). OpenAPI
Generator: **active** — 7.25.0 on 2026-08-24 (Opus, Maven `last-modified`; not re-fetched,
`M01`), pushed 2026-09-25. progenitor: **active** — 0.15.0 on 2026-09-10 (`F01`), pushed
2026-09-19. Its exclusion is functional, not a maintenance verdict.

**Qualified shortlist — two candidates, and the shortness is a finding.** Only two surveyed
tools can read the 3.1 document R4.1 requires and clear every applicable gate.

| Name · role | 90-day downloads | All-time | Stars | Last release | State | Notable adopters | Trade-off |
|---|---:|---:|---:|---|---|---|---|
| `openapi-to-rust` · crates.io CLI that emits a typed async module | 45,469 | 46,127 | 37 | 0.17.0, 2026-09-14 | active | `meteora-api` 0.1.0, generated by v0.12.2 (`F06`; 20 all-time downloads — real use, not a well-regarded reference). 0 reverse dependencies (`F03`) | The only Rust-native, 3.1-capable, recipe-shaped tool that meets R12.4, but young and single-vendor |
| OpenAPI Generator `rust` · Java CLI that emits a standalone crate | `inapplicable` — not a crate (Maven, Docker, npm, Homebrew) | `inapplicable` | 26,762 | 7.25.0, 2026-08-24 (Opus) | active | LanceDB `lance-namespace-reqwest-client` (1,669,641 90-day downloads; Opus traced it to this generator through its manifest's `authors` line) | Mature and widely used, but a JVM, a self-described "(beta)" 3.1 path, and **no way to meet R12.4** |

**Excluded by gate.**

- **progenitor 0.15.0 / cargo-progenitor 0.15.0.** It cannot read the OpenAPI 3.1 document
  R4.1 requires, in any mode. `progenitor-impl` `src/lib.rs:702-710` admits only versions that
  `starts_with("3.0.")`, and its own unit test expects the 3.1.0 refusal (checks `D01`–`D03`).
  Executed: the real 3.1 fixture fails while parsing, because a 3.1 type array is
  "invalid type: sequence, expected a string" (`P02`). The same document in 3.0 syntax but
  labelled 3.1.0 fails the version check (`P02b`). utoipa, the owner reference's schema
  generator, can emit only 3.1.0 at 5.5.0 (`D07`, `D08`); 6.0.0 keeps 3.1.0 as the default
  and adds an opt-in 3.2.0 (`D16`, `D17`). Neither is a version progenitor reads. On a 3.0 document the recipe-shaped CLI
  panics on stable rustfmt (`P03`, `P04`, source `D05`, `D06`), which fails the prompt's
  "Stable Rust only". A missing operationId is a hard error (`P05`, `D04`).
- **paperclip 0.9.7** and **openapi-model-generator 0.6.3** — gate 2: no live version
  declares `rust_version` (`F04`). Both are also out of category.
- **openapi_gen 0.3.1** and **toac-build** — compile-time only (a proc-macro and a `build.rs`
  generator), excluded by R49's clause (`A08`).

**Up-and-comers.** `spargen` (0.4.0: rust 1.88, MIT OR Apache-2.0, 2026-08-29, `F01`;
0.5.0 followed on 2026-09-24, snapshot) is 3.1/3.2 only, self-labelled alpha, and has one maintainer. It is the design to watch: strict
diagnostics, a `--check` mode, and a minimal runtime dependency set (Muse, Doxa-OpenAI; not
probed here). `ploidy`, `openapi-nexus` and `oas3-gen` have no located adopter (figures in
the snapshot). None has enough adoption or independent verification to carry a template.

**Fit for this template.** **CLI:** no interaction. The CLI reaches the upstream API, and the
generated client reaches this template's own service. The CLI's tree is unchanged.
**Library:** the core library never depends on the client. The client package is outside
the workspace (`T13`). **Web:** the recipe consumes the web member's output, the committed
snapshot, and adds no dependency, module, feature or binary to it. The client is how a reader
calls the example service, and it demonstrates that the served contract is machine-consumable.

**Ranked runner-up: OpenAPI Generator 7.25.0 `rust` (library `reqwest`).** It wins under two
conditions together. First, **R71 documents every enum as closed**, so that R4.9's exception
removes R12.4's obligation and the generator's closed enums stop being a departure. Second,
the owner accepts a **JVM as an on-demand contributor prerequisite outside R42's channels**.
It also wins if `openapi-to-rust` becomes dormant or stalls on 3.1 constructs R71's real
snapshot uses. Its advantages are real: a complete crate per run, a sync option
(`supportAsync=false`, which matches R05's synchronous model), an injectable `reqwest` client
(`E08`, which meets R12.3 without caller code), and a decade of cross-language use.

**Tradeoffs — what the pick gives up, and why each cost is accepted.**

| Versus | Given up | Why accepted |
|---|---|---|
| OpenAPI Generator | Maturity and adoption; a sync API; a crate per run; an injectable client for timeouts | It cannot meet R12.4 (MUST) without maintaining forked templates (`E04`, `E05`). It needs a JVM from a channel R42 does not sanction (`A06`, `A07`). It calls its own 3.1 path beta (`E06`, `E07`). The crate gap is closed by the recipe (`T08`–`T10`); the timeout gap by one caller line (R12.3 row) |
| progenitor | Oxide's maintenance, pagination streams, typed mocks, 72 reverse dependencies (Muse) | It cannot read 3.1 (`D01`–`D03`, `P02`) |
| Committed output (architecture B) | An early warning that the snapshot and the client have diverged | Nothing in the template consumes the client. py does not commit its client either. `--check` makes the switch one CI job (trigger 6) |
| `spargen` | Stricter 3.1 diagnostics | Alpha, one maintainer, not probed |

**Minimal realistic example.** `review/evidence/fixtures/api-3.1.json` (sha256
`d0837b98…`) mirrors py's snapshot shape. It declares `openapi: 3.1.0`; `GET /healthz` as
`ops-healthz`; `GET /v1/projects` as `projects-list_projects` with R72's opaque `cursor`
and `limit`; `GET /v1/projects/{project_id}` as `projects-get_project` with a
`application/problem+json` 404; a closed `ProjectState` enum; an `anyOf`-open `Visibility`;
and 3.1 nullable type arrays. Generated signatures (check `T06`):
`pub async fn ops_healthz`, `pub async fn projects_list_projects`,
`pub async fn projects_get_project`. The usage the template documents:

```rust
use std::time::Duration;
let client = rs_launch_blueprint_client::HttpClient::new().with_base_url(base_url);
// R12.3: the generated client sets no timeout, so the caller does.
let project = tokio::time::timeout(Duration::from_secs(10), client.projects_get_project("p1")).await??;
```

**Owner reference, row by row (the rows that touch R84).**

| Row | Reference says | R84 |
|---|---|---|
| C3 OpenAPI (`:50`) — utoipa 5 + utoipa-axum | R71's row | **Agree and compatible.** utoipa 5.5.0 emits only 3.1.0 (`D07`, `D08`), which the pick reads (`T03`) and progenitor cannot (`P02`). utoipa 6.0.0 keeps that default (`D16`) |
| C3 TS client (`:51`) — openapi-typescript + openapi-fetch | A TS client for an SPA head | **Differ, on scope.** The SPA head is unscoped (`owner-decisions.md` section 11); F335 asks for this repository's language |
| C3 prose (`:90`) and step 7 (`:426`) — "Run generation in CI and `git diff --exit-code`"; gate CI on "OpenAPI/TS-client drift" | A committed, drift-gated client | **Differ, on sourced ground, with a flip condition.** py gates no client (`B04`–`B06`); no in-repo consumer exists. Trigger 6 adopts it (`A11`, `A12`) |

**Migration implications — file-level changes in the template.**

| File | Change | Owner |
|---|---|---|
| `Justfile` | One recipe, `client-rust`, exactly as quoted above | R84 |
| R42's tool table in the `Justfile` | One row: `openapi-to-rust@0.17.0` | R84, through R42's mechanism |
| `openapi-to-rust.toml` (root) | New: the generator input quoted above, with R71's open enums under `[extensible_enums]` | R84; enum names from R71 |
| `.gitignore` | `/clients/` — a deliberate improvement over py, whose output is neither committed nor ignored (`B05`) | R84 |
| Web docs (the analogues of py's `0002-web-api-conventions.md:86` and `EXAMPLEWEB.md:138`) | "Typed clients are generated, never hand-written — run `just client-rust`", with the timeout example | R84 |
| The template's REST conformance note | The `OV-11` deviation line quoted above | R84; the note's owner |

Not created: no workspace member, Cargo dependency, feature, `build.rs`, CI job or published
artifact. P03 should bind the recipe's `rust-version = "1.96"` literal to the root
manifest's value when it writes the `Justfile`.

## Parameters

R84 owns no registry parameter. The prompt's couplings carry an empty `- owns:` line (check
`A01`). The one consumed parameter is R69's `web-extra-surface` (check `A02`). The five lines
below are byte-identical to `inputs/parameters.json` and to the live
`docs/port/PARAMETERS.md` (check `A04`).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**Prose note on `web-extra-surface`.** The line above is the live registry value, which is
R69 revision 9's form. R69 revision 10 is owner-accepted and unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`). It moves the
web tree into the optional member `crates/web/`, with the feature reading
`web = ["dep:rs-launch-blueprint-web"]`. **Nothing in this recommendation depends on which
form is live.** R84 adds no module, dependency, feature or binary to the web surface. It only
consumes the snapshot that surface produces. Republication is re-verify trigger 2.

**No `CONFLICT:` line.** No engine raised one, and nothing here needs a consumed value
changed.

**How the parameters bear on the decision.** `msrv-policy`: the floor is **1.96**, stable
1.98.1 minus two minors. The tool declares 1.88.0 (`D10`) and the generated package builds on
1.96.0 (`T12`). The recipe's manifest declares `rust-version`, which OpenAPI Generator's
template cannot (`E01`). `rust-edition = 2024`: the recipe's manifest declares it (`T09`),
while OpenAPI Generator hard-codes 2021 (`E01`). `target-os-matrix`: macOS was executed here
and Linux was not. The tool's CI is `ubuntu-latest` only (`G09`), so the two halves come
from different sources, and P03's matrix closes both (AC9). `license`: recorded, not
evaluated (Q7.B); the recipe writes `MIT OR Apache-2.0` into the generated manifest.
`web-extra-surface`: see the prose note. Two further published values shape the recipe
without being consumed by this prompt, so they are cited in prose rather than as `- assumes`
lines. R42's `package-manager-invocation` fixes the bare invocation and the `command -v`
presence test. R49's `build-tool-output-shape` rules out `build.rs` (check `A08`).

## Empirical check

**Toolchain and host.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, rustup toolchain `1.96.0` for the floor,
`rustfmt 1.9.0`, `just 1.57.0`, `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` at
`/usr/bin/grep`, `Darwin arm64` (macOS). One developer host, not the CI matrix.

**Commands and working directory.** Run from the repository root:

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
E=research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/evidence
for s in r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures; do
  shellcheck "$E/$s.sh" && "$E/$s.sh" > "$E/$s.log" 2>&1
done
shellcheck "$E/r84-archive-rerun.sh" &&
  "$E/r84-archive-rerun.sh" r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures
```

**Observed result.** `shellcheck` exits 0 with no finding on all five scripts.

| Script | What it proves | Run | Pass | Fail | Skip |
|---|---|---:|---:|---:|---:|
| `r84-source-claims.sh` | Couplings, registry equality, py at its pin, the REST standard at its blob, crate sources at exact versions, OpenAPI Generator at `v7.25.0` | 60 | 60 | 0 | 0 |
| `r84-openapi-to-rust-probe.sh` | The recommended recipe, executed end to end; section 12 of the standard | 36 | 31 | 0 | 5 |
| `r84-progenitor-probe.sh` | progenitor's refusals and panic, executed | 6 | 6 | 0 | 0 |
| `r84-registry-figures.sh` | Registry, RustSec, GitHub and Cargo Book facts; volatile figures to `snapshots/registry-figures.json` | 31 | 30 | 0 | 1 |

**Check identifiers are unique across the four scripts**, so a bare identifier in this
decision names one check. `A`, `B`, `C`, `D` and `E` prefixes belong to
`r84-source-claims.sh`; `T`, `R` and `AU` to `r84-openapi-to-rust-probe.sh`; `P` to
`r84-progenitor-probe.sh`; `F`, `RS`, `M`, `CB` and `G` to `r84-registry-figures.sh`.

**The recipe, observed.** `just client-rust` on the fixture writes
`clients/rust/{Cargo.toml, src/mod.rs, src/client.rs, src/types.rs, src/REQUIRED_DEPS.toml}`.
The package compiles on 1.98.1 and on 1.96.0. `cargo metadata` at the root still lists one
member. `--check` exits 0 on fresh output and 1 after either a snapshot change or a
hand-edit. The section-12 probe's deserialization half printed, verbatim:

```text
DEFAULT_UNKNOWN_FIELD=accepted
DEFAULT_UNKNOWN_STATE=rejected unknown variant `suspended`, expected `active` or `archived` at line 1 column 44
RECIPE_UNKNOWN_VALUES=accepted state=Custom("suspended") visibility=Custom("internal")
RT_BIND=refused PermissionDenied
```

The last line is the host, not the code: this agent shell refuses every TCP bind, including
loopback, even with its command sandbox disabled (a Python `socket.bind(('127.0.0.1', 0))`
failed the same way). Checks `R06`–`R10` therefore print `SKIP` by name. They run unchanged
wherever loopback binds are allowed. Their static counterparts `R11`–`R13` ran and passed.

**Reproducibility, from a clean `git archive HEAD` extraction.** The scripts and fixture
are untracked, so the procedure was as follows. Extract `git archive HEAD` into a fresh
`$TMPDIR` directory. Copy `review/evidence/*.sh` and `review/evidence/fixtures/` into the
same relative path. Run each script there. `diff` each log against the committed one.
Extraction from HEAD `e0b0d1c1`, by the harness
`review/evidence/r84-archive-rerun.sh`, whose output, with each differing log's full `diff`, is committed as `r84-archive-rerun.log`. **Three of the four logs are
byte-identical**: `r84-openapi-to-rust-probe.log`, `r84-progenitor-probe.log` and
`r84-registry-figures.log`. `r84-source-claims.log` differs in **exactly one check** and its
summary line. `A13` reads `PASS` in the working tree and `SKIP` in the extraction, because the
2026-09-21 ledger line that allocates `OV-11` to R84 is uncommitted working-tree content: HEAD's
`execution-ledger.md` has 0 occurrences of it. Every other line, including every figure, probe
output and quotation, reproduced byte for byte. Volatile figures are kept out of the logs and in
`snapshots/`, so they are not part of this comparison.

**What this check does not prove.** (1) **Linux**: nothing ran on `ubuntu-latest` (AC9).
(2) **The HTTP half** of section 12 (`R06`–`R10`, AC8), for the host reason above.
(3) **OpenAPI Generator's behaviour**: Maven Central was unreachable (`M01`), so its
dispositions rest on its sources at `v7.25.0` (`E01`–`E08`) plus Opus's executed runs, which
are carried under Opus's name. (4) **The transitive `unsafe` posture** of `reqwest` and its
tree; `cargo geiger` against a resolved lockfile is P03's. (5) **R71's real snapshot**, which
does not exist yet (AC10).

## Engines

- **Muse** (`muse-spark`, Meta) — 499 lines, crate shape. Recommends `openapi-to-rust` 0.17
  in a `just` recipe, with **committed** output and `generate --check` as a CI drift gate.
  Runner-up progenitor (if 3.1 lands), then OpenAPI Generator. No `CONFLICT:`, no
  `BASELINE-REVIEW:`. Its `### Sources` list is complete; it ends with the probe-scratch
  entry.
- **Opus** (`claude-opus-5`) — 735 lines. Recommends **OpenAPI Generator 7.25.0**
  (`library=reqwest, supportAsync=false`) as an on-demand recipe writing an **uncommitted,
  out-of-workspace** crate, with root `[workspace] exclude = ["clients"]`. Runner-up
  `openapi-to-rust`. Excludes progenitor under both R71 branches. No `CONFLICT:`, no
  `BASELINE-REVIEW:`.
- **Doxa** — three provider legs in one combined report:
  - **OpenAI** (`gpt-5.6-sol`): `openapi-to-rust` `>=0.17.0,<0.18.0` into a **committed**
    workspace member `crates/api-client` with a CI check. Runner-up progenitor. Excludes
    OpenAPI Generator as "not a Rust crate". Emits `BASELINE-REVIEW: F335`. Records every
    mandated figure honestly as `N/R` and says "zero candidates are fully evidence-complete".
  - **Perplexity** (`sonar-deep-research`): `openapi-to-rust`; runner-up progenitor. No
    figures, no executed checks. Declares three `owns` parameters against an empty `owns:`
    line.
  - **Gemini** (`deep-research-preview-04-2026`): `openapi-to-rust`; runner-up progenitor.
    Excludes OpenAPI Generator on gate 3 through `time` 0.1 / RUSTSEC-2020-0071. Emits
    `BASELINE-REVIEW: F335` ("HARMONIZED"). Declares two `owns` parameters.

**Disagreement 1 — which tool: `openapi-to-rust` (Muse and all three Doxa legs) or OpenAPI
Generator (Opus)? Settled for `openapi-to-rust`, on four grounds none of the engines used
together.** Agreement between five reports is not the ground; the four checks are.
**(a) R12.4, a MUST of the binding standard.** OpenAPI Generator's string enums derive a
closed `Deserialize` with no `#[serde(other)]` or catch-all arm (`E04`), and none of its
documented `rust` options concerns unknown values (`E05`). `openapi-to-rust` keeps unknown
values through `[extensible_enums]` or an `anyOf`-open schema (`R05`, `D11`, `D12`). No engine
applied section 12 of the standard to either tool. **(b) R42's published channel.** A
crates.io tool is one tool-table row (`A06`, `A07`). A Java jar is neither crates.io nor a
single-binary release, and Opus's Homebrew route is not one of R42's channels. **(c) The
owner-fixed edition.** OpenAPI Generator hard-codes `edition = "2021"` and no `rust-version`
(`E01`). The recipe's manifest declares 2024 and 1.96 (`T09`). **(d) The generator's own
words.** Its help text says "(beta)" (`E06`), and it warns "OpenAPI 3.1 support is still in
beta" (`E07`). Opus's strongest objections were checked, not dismissed. The module-not-crate
gap is closed mechanically (`T04`, `T08`–`T10`). The async-only API (`T07`) meets no
synchronous caller, because the client is outside the workspace (`T13`–`T15`). The thin
adoption is real (`F03`, snapshot) and is accepted as the stated risk.

**Disagreement 2 — commit the output and gate it in CI (Muse, Doxa's OpenAI and Gemini legs,
owner reference) or generate on demand (Opus)? Settled for on demand, with a flip
condition.** Opus's reading of py is confirmed at the pin: no `clients/` path, no ignore
entry, and no workflow mention (`B04`–`B06`). The Cargo Book's guidance, cited by Doxa, is
conditional on checking a file in (`CB01`). No engine named an in-repo consumer
that exists. Doxa's CLI dependency presumes a CLI that calls the service, which R05 does not
have. Gemini's proposal that "the web service can import these models" inverts the contract
direction R71 owns. Trigger 6 carries the condition under which the others are right.

**Disagreement 3 — progenitor as runner-up (all three Doxa legs) or excluded (Opus, Muse)?
Settled: excluded.** The Doxa legs ranked it on production maturity and never ran it. The
executed and source evidence is in `### Principles and implementation` (`D01`–`D08`,
`P02`–`P05`), and R4.1 makes 3.1 binding (`C02`, `C03`). **One nuance corrects Opus.** On a
real 3.1 document, progenitor fails in parsing, before the version check Opus quoted (`P02`).
Opus's fixture had no 3.1-only construct. Muse reported the parse failure correctly.

**Disagreement 4 — `BASELINE-REVIEW: F335` (Doxa's OpenAI and Gemini legs) or none (Opus,
Muse)?** Forwarded to the controller, not adopted; see `### Principles and implementation`.
Opus's reason for emitting none is scope-based and is noted here, not adjudicated. It reads
`docs/port/README.md` item 11 as scoping the baseline review to `COMMON → REUSE` and `ADOPT`
rows, and F335 is `DIVERGENT`.

**Errors in the raw reports, corrected at source.**

| Report | Claim | Finding | Check |
|---|---|---|---|
| Gemini | OpenAPI Generator excluded on gate 3 via `time` 0.1 (RUSTSEC-2020-0071) | **Refuted.** The `rust` template declares no `time` crate | `E03` |
| Gemini | `openapi-to-rust` ">120" stars, "~16,000" all-time downloads; `oas3-gen` `stable-quiet` | **Wrong.** 37 stars, 46,127 all-time downloads | snapshot |
| Gemini | "The generated code is entirely free of `unsafe` … zero open RustSec advisories" | Asserted without a check; now executed | `T22`, `RS02`, `AU01` |
| Perplexity, Gemini | `owns client-generator-crate` and similar | **Rejected.** The prompt's `owns:` is empty | `A01` |
| Perplexity | "openapi-generator … relies on npm" | The npm package is a wrapper around the Java jar | `E07` (Java source) |
| Muse | openapi-to-rust CI is "stable only" | **Wrong.** It has an MSRV job on 1.88.0; ubuntu-only is right | `G09`, `G10` |
| Muse | py's recipe at `Justfile:322` / `:321-323` | **Not the pin** (`:311-312`); it matches a later py commit (`aa5d7015`) | `B01`, `B02`, `B10` |
| Opus | progenitor 3.1 search "returns `total_count: 0`" | Issues #762 and #1268 are open and concern 3.1; Opus's title search missed them | `G05-762`, `G05-1268` |
| Doxa-OpenAI | `meteora-api` is an adopter | **Confirmed but negligible**: generated by v0.12.2, 20 downloads | `F05`, `F06` |
| Doxa-OpenAI | Recipe installs into `target/tools` and invokes by path | Conflicts with R42's bare-on-`PATH` rule; replaced by R42's tool table | `A06` |

**What was carried, not re-derived.** Opus's OpenAPI Generator executions (E1–E8 in its
report: generation, the blocking API, the 1.96.0 build, determinism, the `info.license`
behaviour, the missing-id `WARN`), because Maven Central was unreachable here (`M01`). Their
source-level counterparts were re-read (`E01`–`E08`). Opus's partial issue-latency samples for
OpenAPI Generator and progenitor. LanceDB's and Langfuse's use of OpenAPI Generator. Muse's
`spargen` description. Muse's figure of 72 reverse dependencies for progenitor. None of these is load-bearing for the pick. Each would matter only if
the runner-up were adopted.

**What P03 must validate.** AC8–AC10; the recipe on `ubuntu-latest`; the `rust-version`
literal bound to the root manifest; the `OV-11` line in the conformance note; and the
`[extensible_enums]` list checked against R71's snapshot. Doxa-OpenAI's `jq` preflight, which
rejects a missing or duplicate operationId before generation, is recommended as that check's
first step.
